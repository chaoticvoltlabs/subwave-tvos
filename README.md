# subwave-tvos

A native tvOS listener client for [SUB/WAVE](https://github.com/perminder-klair/subwave)
stations. Standalone project — related to [ProbablyTV](../ProbableTV) only in
that it's a technical warm-up (AVPlayer + Siri Remote + polling patterns in
Swift/SwiftUI), not a shared codebase. The two are otherwise fully isolated.

See the feasibility note this project grew out of:
[`ProbableTV/docs/notes/tvos-subwave-player.md`](../ProbableTV/docs/notes/tvos-subwave-player.md).

## Why native, not a WebView wrapper

SUB/WAVE exposes a clean, mostly-unauthenticated JSON REST API purpose-built
for listener clients (see that project's `docs/api.md`), so this doesn't need
to embed a web player. It's an ordinary tvOS app shape: `AVPlayer` on a stream
URL, `URLSession`/`Codable` polling `/now-playing`, standard SwiftUI focusable
lists — the Siri Remote focus engine handles navigation for free.

## Planned v1 scope

- Station picker (address + optional name, stored locally)
- Playback via `AVPlayer` on the Icecast stream mount + Now Playing Info Center
- Now-playing display: track/artist/album, cover art (`/cover/:id`), on-air DJ persona, listener count
- Song requests: `POST /request` + poll `GET /request/:id`
- Private-station support: HTTP Basic Auth on the stream URL

Schedule/personas (EPG-style browsing) is a possible v1.1, not required for
a first working build.

## Development

Xcode project to be created on a Mac (`File > New > Project` targeting tvOS,
SwiftUI lifecycle) inside this cloned repo. This machine (a Linux dev VM) is
used for planning and non-Xcode-specific source editing; actual builds, the
simulator, and signing require Xcode on macOS.

**Signing:** use Xcode's "Automatically manage signing" tied to your Apple
Developer account/team, so it resolves correctly on any Mac you build from —
no certificates or provisioning profiles to move around or commit.
