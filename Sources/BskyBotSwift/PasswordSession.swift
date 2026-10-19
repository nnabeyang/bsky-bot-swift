import Foundation
import SwiftAtproto

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// An XRPC client logged in to a PDS with an app password.
///
/// It refreshes the access token when the PDS says it has expired, and then
/// tries the call again.
actor PasswordSession: XRPCCallable {
  private var serviceEndpoint: URL
  private var accessJwt: String?
  private var refreshJwt: String?
  /// The DID of the logged-in account.
  private(set) var did = ""

  private init(service: URL) {
    serviceEndpoint = service
  }

  /// Logs in with `com.atproto.server.createSession`.
  ///
  /// - Parameters:
  ///   - service: The PDS, for example `https://example.com`.
  ///   - identifier: The handle or email address of the account.
  ///   - password: An app password.
  static func login(service: URL, identifier: String, password: String) async throws -> PasswordSession {
    let session = PasswordSession(service: service)
    let output = try await session.ServerCreateSession(input: .init(identifier: identifier, password: password))
    await session.update(
      accessJwt: output.accessJwt, refreshJwt: output.refreshJwt, did: output.did.rawValue, didDoc: output.didDoc)
    return session
  }

  private func update(accessJwt: String, refreshJwt: String, did: String, didDoc: UnknownATPValue?) {
    self.accessJwt = accessJwt
    self.refreshJwt = refreshJwt
    self.did = did
    // bsky.social is an entryway in front of many PDSes, so send later calls
    // to the PDS that the DID document names.
    if let document = didDoc?.val as? DIDDocument,
      let pds = document.service?.first(where: { $0.id == "#atproto_pds" }),
      let url = URL(string: pds.serviceEndpoint)
    {
      serviceEndpoint = url
    }
  }

  nonisolated func getProxy(nsid: String) -> String? { nil }

  func response(_ requestComponents: XRPCRequestComponents) async throws -> Data {
    do {
      return try await send(requestComponents)
    } catch let error as UnExpectedError
      where ["ExpiredToken", "InvalidToken"].contains(error.error)
      && requestComponents.nsId != Com.Atproto.ServerRefreshSession.id
    {
      try await refresh()
      return try await send(requestComponents)
    }
  }

  private func refresh() async throws {
    let output = try await ServerRefreshSession()
    update(accessJwt: output.accessJwt, refreshJwt: output.refreshJwt, did: output.did.rawValue, didDoc: output.didDoc)
  }

  private func send(_ requestComponents: XRPCRequestComponents) async throws -> Data {
    var components = URLComponents(
      url: serviceEndpoint.appending(path: requestComponents.relativePath), resolvingAgainstBaseURL: false)!
    if !requestComponents.queryItems.isEmpty {
      components.percentEncodedQueryItems = requestComponents.queryItems
    }
    var request = URLRequest(url: components.url!)
    request.httpMethod = requestComponents.method.rawValue
    request.httpBody = requestComponents.body
    for field in requestComponents.headers {
      request.setValue(field.value, forHTTPHeaderField: field.name.rawName)
    }
    // refreshSession takes the refresh token; every other call takes the access token.
    let token = requestComponents.nsId == Com.Atproto.ServerRefreshSession.id ? refreshJwt : accessJwt
    if let token {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let (data, response) = try await URLSession.shared.data(for: request)
    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
    guard 200..<300 ~= statusCode else {
      throw (try? JSONDecoder().decode(UnExpectedError.self, from: data))
        ?? UnExpectedError(error: nil, message: "HTTP \(statusCode): \(String(decoding: data, as: UTF8.self))")
    }
    return data
  }
}
