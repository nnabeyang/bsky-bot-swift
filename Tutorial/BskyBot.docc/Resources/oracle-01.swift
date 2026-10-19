/// Writes a reply to a mention.
func generateReply(to mentionText: String) async -> String {
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
