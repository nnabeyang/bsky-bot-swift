import Foundation

DotEnv.load()

let usage = """
  usage: swift run bot <command>

    post    Post 🙂 now and every three hours.
    label   Label the bot's profile as a bot.
    agent   Reply to mentions every minute.
  """

do {
  switch CommandLine.arguments.dropFirst().first {
  case "post":
    let session = try await login()
    while true {
      do {
        try await makePost(session)
      } catch {
        print("Could not post: \(error)")
      }
      try await Task.sleep(for: .seconds(3 * 60 * 60))
    }
  case "label":
    let session = try await login()
    try await labelAsBot(session)
  case "agent":
    let session = try await login()
    print("Agent is running...")
    while true {
      do {
        try await checkMentions(session)
      } catch {
        print("Could not check mentions: \(error)")
      }
      try await Task.sleep(for: .seconds(60))
    }
  default:
    print(usage)
    exit(1)
  }
} catch {
  print(error)
  exit(1)
}
