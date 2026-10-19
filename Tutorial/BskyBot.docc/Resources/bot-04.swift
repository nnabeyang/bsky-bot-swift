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

/// Adds the `bot` self-label to the bot's profile, keeping everything else in it.
func labelAsBot(_ session: PasswordSession) async throws {
  let did = await session.did

  // Get the current profile (if any) to preserve existing fields
  let existing: Com.Atproto.RepoGetRecord_Output?
  do {
    existing = try await session.RepoGetRecord(
      collection: .init(rawValue: App.Bsky.ActorProfile.nsId),
      repo: .init(rawValue: did),
      rkey: .init(rawValue: "self")
    )
  } catch Com.Atproto.RepoGetRecord.Error.recordnotfound {
    // Profile doesn't exist yet, that's fine
    existing = nil
  }
  let profile = existing?.value.val as? App.Bsky.ActorProfile

  // Update profile with bot self-label
  let labeled = App.Bsky.ActorProfile(
    avatar: profile?.avatar,
    banner: profile?.banner,
    createdAt: profile?.createdAt,
    description: profile?.description,
    displayName: profile?.displayName,
    joinedViaStarterPack: profile?.joinedViaStarterPack,
    labels: .comAtprotoLabelDefsSelfLabels(.init(values: [.init(val: "bot")])),
    links: profile?.links,
    pinnedPost: profile?.pinnedPost,
    pronouns: profile?.pronouns,
    website: profile?.website,
    _unknownValues: profile?._unknownValues ?? [:]
  )
  _ = try await session.RepoPutRecord(
    input: .init(
      collection: .init(rawValue: App.Bsky.ActorProfile.nsId),
      record: .record(labeled),
      repo: .init(rawValue: did),
      rkey: .init(rawValue: "self"),
      // Fail instead of overwriting a profile that changed after we read it.
      swapRecord: existing?.cid
    )
  )
  print("Labeled the profile as a bot.")
}

/// Replies to the mentions that have not been seen yet.
func checkMentions(_ session: PasswordSession) async throws {
  let seenAt = Date()
  let output = try await session.NotificationListNotifications(limit: 20)

  for notification in output.notifications {
    // Only process unread mentions
    guard notification.reason == .mention, !notification.isRead else {
      continue
    }
    print("Found a mention: \(notification.uri)")
  }

  // Mark the notifications as read, so the same mentions are not answered again.
  _ = try await session.NotificationUpdateSeen(input: .init(seenAt: .init(seenAt)))
}
