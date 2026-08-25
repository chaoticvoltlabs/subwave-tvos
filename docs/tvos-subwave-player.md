# Native tvOS player for SUB/WAVE — feasibility note

**Status:** exploratory note, not scoped/planned work.
**Date:** 2026-08-24
**Context:** ProbablyTV's vision doc already names a tvOS client as a primary
reference environment. This note evaluates two possible starting points for
getting *something* onto Apple TV, using the sibling SUB/WAVE radio project
(the "working radio system... research platform for several ProbablyTV
concepts") as the test case, before any of this is attempted for ProbablyTV
itself.

## Option A (rejected): port perminder-klair/Wave-TV to tvOS

[Wave-TV](https://github.com/perminder-klair/Wave-TV) is an Android TV / Fire TV
"shell, not a client" for SUB/WAVE stations: a native station picker, then a
`WebView` loading the station's own web player fullscreen. Read in full
(`README.md`, `app/java/com/wave/tv/MainActivity.java`, `app/assets/tvhelper.js`):

- Single ~103KB `MainActivity.java`. The trick that makes it usable on a TV is
  raw Android `KeyEvent` interception (`dispatchKeyEvent`/`onKeyDown` on
  `KEYCODE_DPAD_*`, `KEYCODE_MEDIA_*`, etc.) piped into
  `webView.evaluateJavascript(...)` calls against the injected `tvhelper.js`,
  which does DOM spatial-navigation and draws a custom focus ring.
- Zero shared code with iOS/tvOS: 100% Java/Android SDK (Leanback manifest,
  `WebView`, Android `SpeechRecognizer`).
- The core mechanism doesn't transfer. tvOS's Siri Remote is a touch/swipe
  surface, not discrete D-pad key events, and `WKWebView` on tvOS has a
  historically limited/fragile focus-engine integration with arbitrary custom
  web content (especially text fields and custom CSS focus rings like this
  app relies on). Reproducing the Android version's polish would be its own
  R&D effort, not a translation.
- Distribution is also harder on tvOS: Android sideloading is free and
  permanent; tvOS needs at minimum a paid Apple Developer account ($99/yr) to
  avoid re-signing a personal build every 7 days, and a bare-WebView app is a
  real App Store guideline-4.2 rejection risk if ever submitted (irrelevant
  for personal/sideloaded use).

**Verdict:** technically possible, but not a "port" — a from-scratch rebuild
that inherits the *hardest*, least certain part of the original (remote → DOM
focus bridging) with no code reuse. Not worth doing this way.

## Option B (viable): greenfield native tvOS app against SUB/WAVE's API

Much better framing: SUB/WAVE ([perminder-klair/subwave](https://github.com/perminder-klair/subwave))
exposes a clean, mostly-unauthenticated JSON REST API purpose-built for
listener clients (`docs/api.md`, `controller/src/connect/catalog.ts` in that
repo). A native player doesn't need a WebView at all.

### Relevant endpoints (all `auth: 'none'` unless noted)

| Endpoint | Use |
|---|---|
| `GET /now-playing` | current track, cover-art id, on-air DJ persona, active show, listener count, stream descriptor. **Poll-based** — no websocket/SSE in the public API. |
| `GET /cover/:id` | cover art image |
| `GET /schedule`, `GET /personas`, `GET /dj` | EPG-style browsing (optional for v1) |
| `GET /listen.pls`, `GET /listen.m3u` | ready-made stream playlist files |
| Icecast mounts (`/stream.mp3`, optional opus/aac/flac) | raw audio, playable directly by `AVPlayer` |
| `POST /request` + `GET /request/:id` | free-text song request, poll for resolution |

Private stations (`docs/private-station.md` in that repo): the now-playing
JSON stays public; only the *stream* gets an Icecast listener-auth gate, using
plain HTTP Basic Auth (`https://listener:PASSWORD@host/stream.mp3` or
`?auth=PASSWORD`) — no custom auth scheme to implement.

SUB/WAVE's existing "native" mobile apps (`app/` in that repo) are Expo/React
Native, not Swift — the one Swift file in that repo is a small native module
(`AirplayRoutePickerModule.swift`, AirPlay route picking). There is no
existing tvOS target to build on; this would be greenfield either way.

### Why this avoids Option A's risk entirely

A player built this way is a completely ordinary tvOS app shape: `AVPlayer`
pointed at a stream URL, `URLSession`/`Codable` polling a JSON endpoint,
standard SwiftUI focusable lists/buttons. The Siri Remote focus engine handles
navigation for free — no DOM, no custom key routing, no WebKit fragility.

### Rough effort estimate (v1: picker, playback, now-playing + cover art,
requests, private-station support)

| Piece | Estimate |
|---|---|
| Playback (`AVPlayer` + Now Playing Info Center) | ~0.5 day |
| Now-playing UI + polling + cover art | ~1 day |
| Station picker (native list, stored locally) | ~0.5 day |
| Song requests (text entry + poll) | ~1 day |
| Private-station auth (Basic auth + password prompt) | ~0.5 day |
| Schedule/personas (EPG-style, optional) | +~1 day |

**Total: ~3–5 focused days** for someone comfortable in Swift/SwiftUI. No
architectural risk comparable to Option A — this is standard tvOS engineering
against a well-documented REST API, not R&D.

### Caveats

- `http://` (non-TLS, LAN) stations need an App Transport Security exception
  in `Info.plist` (`NSAllowsLocalNetworking` or a targeted exception domain).
  iOS/tvOS require this explicitly; Android does not.
- Everything is poll-based (no push/websocket in the public API). Fine at
  radio-app scale.
- A paid Apple Developer account ($99/yr) is still needed to avoid the 7-day
  free-provisioning re-sign cycle, same as Option A.

### What this buys ProbablyTV

This would be a **SUB/WAVE (radio) player on tvOS**, not a ProbablyTV
(television) client. It's a useful technical precedent/warm-up for the actual
tvOS client the vision doc already names as the primary reference
environment — proving out AVPlayer + Siri Remote + polling patterns in Swift
— but it is a separate app/target, not a step that produces ProbablyTV's own
player.
