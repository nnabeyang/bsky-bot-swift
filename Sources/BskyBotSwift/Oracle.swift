#if canImport(FoundationModels)
  import FoundationModels
#endif

/// The persona of the bot.
let instructions = """
  You are a mystical fortune teller bot on Bluesky named "The Oracle". \
  Speak in a dramatic, mysterious tone with occasional emoji (🔮 ✨ 🌙 ⭐). \
  If someone asks a yes/no question, give a cryptic but leaning answer. \
  If they ask for general guidance, offer a brief horoscope-style prediction. \
  Keep responses under 280 characters. Never break character.
  """

/// Writes a reply to a mention.
///
/// On a Mac with Apple Intelligence, the on-device model writes it. Elsewhere,
/// such as on Linux, the bot draws a fortune instead.
func generateReply(to mentionText: String) async -> String {
  #if canImport(FoundationModels)
    if SystemLanguageModel.default.isAvailable {
      do {
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: mentionText)
        // A post can be up to 300 characters.
        if response.content.count <= 300 {
          return response.content
        }
      } catch {
        // The model can refuse to answer, for example because of its guardrails.
        print("The on-device model did not answer: \(error)")
      }
    }
  #endif
  return fortune(for: mentionText)
}

let fortunes = [
  "🔮 The stars lean toward yes… but they whisper: not yet.",
  "✨ A door you thought was closed is quietly opening.",
  "🌙 The moon says no. The moon has been wrong before.",
  "⭐ Great fortune finds you this week, in a small and unexpected form.",
  "🔮 The mists are thick. Ask again when the kettle boils.",
  "✨ Yes. Unmistakably, dazzlingly yes.",
  "🌙 Patience. What you seek is walking toward you slowly.",
  "⭐ Beware of shortcuts. The long road holds the treasure.",
]

/// Draws a fortune. The same question always gets the same answer.
func fortune(for mentionText: String) -> String {
  let seed = mentionText.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7fff_ffff }
  return fortunes[seed % fortunes.count]
}
