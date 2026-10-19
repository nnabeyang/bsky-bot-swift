import Foundation

/// Reads `KEY=value` lines from a `.env` file, like the `dotenv` package.
enum DotEnv {
  /// Sets each variable in the file that is not already set in the environment.
  static func load(path: String = ".env") {
    guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
      return
    }
    for (key, value) in parse(text) where ProcessInfo.processInfo.environment[key] == nil {
      setenv(key, value, 0)
    }
  }

  static func parse(_ text: String) -> [(key: String, value: String)] {
    var variables: [(key: String, value: String)] = []
    for line in text.split(whereSeparator: \.isNewline) {
      let line = line.trimmingCharacters(in: .whitespaces)
      guard !line.hasPrefix("#"), let equals = line.firstIndex(of: "=") else {
        continue
      }
      let key = line[..<equals].trimmingCharacters(in: .whitespaces)
      var value = line[line.index(after: equals)...].trimmingCharacters(in: .whitespaces)
      if let quote = value.first, quote == "\"" || quote == "'", value.count > 1, value.last == quote {
        value = String(value.dropFirst().dropLast())
      } else if let comment = value.range(of: "#"),
        comment.lowerBound == value.startIndex || value[value.index(before: comment.lowerBound)] == " "
      {
        // An unquoted value ends at a comment, as in `BOT_PDS= # eg 'https://example.com'`.
        value = value[..<comment.lowerBound].trimmingCharacters(in: .whitespaces)
      }
      variables.append((key, value))
    }
    return variables
  }

  /// The value of a variable that must be set.
  static func require(_ key: String) throws -> String {
    guard let value = ProcessInfo.processInfo.environment[key], !value.isEmpty else {
      throw MissingVariable(key: key)
    }
    return value
  }

  struct MissingVariable: Error, CustomStringConvertible {
    let key: String
    var description: String { "\(key) is not set. Copy .env.example to .env and fill it in." }
  }
}
