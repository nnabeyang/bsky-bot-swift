import Foundation
import SwiftAtproto

/// Logs in with the account in `.env`.
func login() async throws -> PasswordSession {
  let service = try DotEnv.require("BOT_PDS")  // eg 'https://example.com'
  let identifier = try DotEnv.require("BOT_HANDLE")  // eg 'alice.example.com'
  let password = try DotEnv.require("BOT_PASSWORD")
  guard let url = URL(string: service) else {
    throw URLError(.badURL)
  }
  return try await PasswordSession.login(service: url, identifier: identifier, password: password)
}
