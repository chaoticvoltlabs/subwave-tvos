# subwave-tvos

A native tvOS listener client for [SUB/WAVE](https://github.com/perminder-klair/subwave)
stations — an internet radio platform where an AI DJ hosts the show, picks
music, and takes listener song requests live.

Built as an ordinary tvOS app against SUB/WAVE's JSON REST API: `AVPlayer` on
the Icecast stream, `URLSession`/`Codable` polling for now-playing data, plain
SwiftUI focusable lists driven by the Siri Remote. No WebView, no third-party
dependencies.

## Features

- **Station picker** — add any number of stations by address, switch between
  them, edit or remove saved ones
- **Playback** — `AVPlayer` streaming with full Now Playing Info Center /
  remote-control integration (play, pause, skip from the remote or Control
  Center); the screen stays awake while audio is playing
- **Now Playing** — current track and artist, cover art, on-air DJ persona,
  live listener count
- **Song requests** — send a free-text request to the DJ and watch it resolve
- **Side panel**, switchable per station:
  - **Booth** — a live log of the DJ's on-air commentary and track picks
  - **Guide** — the rolling next-24-hours programme schedule
  - **Clock** — an analog clock set to the station's own timezone
- **Private stations** — stations gated with a listener password are fully
  supported (see below)

## Requirements

- tvOS 26 or later
- Xcode 26 or later, to build
- An Apple Developer account to run on a physical Apple TV (not required for
  the Simulator)

## Getting started

1. Clone the repo and open `subwave-tvos/subwave-tvos.xcodeproj` in Xcode.
2. Pick an Apple TV Simulator or a physical Apple TV as the run destination.
3. Build and run, then add a station by its address (e.g.
   `radio.example.com` or `https://radio.example.com`).

## Private stations

To add a station with the stream/private-player password on, type the
address as `username:password@host` — the username can be anything (e.g.
`dj:`), only the password after the colon is actually checked. Easy to miss:
typing just the password with no `user:` prefix isn't a valid address and
won't authenticate.

## Copyright & license

PolyForm Noncommercial License 1.0.0 with Commercial Use by Explicit
Permission Only. See [LICENSE.txt](LICENSE.txt).

Copyright (c) 2026 Robin Kluit / Chaoticvolt.
