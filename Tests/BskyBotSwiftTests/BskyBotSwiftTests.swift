import Testing

@testable import BskyBotSwift

@Test func parsesDotEnv() {
  let variables = DotEnv.parse(
    """
    # The account
    BOT_PDS= # eg 'https://example.com'
    BOT_HANDLE=alice.example.com
    BOT_PASSWORD="abcd-efgh # not a comment"
    """)
  #expect(variables.map(\.key) == ["BOT_PDS", "BOT_HANDLE", "BOT_PASSWORD"])
  #expect(variables.map(\.value) == ["", "alice.example.com", "abcd-efgh # not a comment"])
}
