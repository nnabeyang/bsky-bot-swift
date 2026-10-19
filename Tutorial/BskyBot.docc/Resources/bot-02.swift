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

/// Posts 🙂.
func makePost(_ session: PasswordSession) async throws {
  let post = try App.Bsky.FeedPost.make(createdAt: .init(Date()), text: "🙂")
  try await createPost(post, session: session)
  print("Just posted!")
}

/// Writes an `app.bsky.feed.post` record to the bot's repository.
func createPost(_ post: App.Bsky.FeedPost, session: PasswordSession) async throws {
  _ = try await session.RepoCreateRecord(
    input: .init(
      collection: .init(rawValue: App.Bsky.FeedPost.nsId),
      record: .record(post),
      repo: .init(rawValue: await session.did)
    )
  )
}
