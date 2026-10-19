import Foundation

DotEnv.load()

do {
  let session = try await login()
  print("Logged in as \(await session.did)")
} catch {
  print(error)
  exit(1)
}
