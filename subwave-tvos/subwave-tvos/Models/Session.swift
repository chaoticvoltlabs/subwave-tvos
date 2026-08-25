//
//  Session.swift
//  subwave-tvos
//
//  GET /session — the live DJ session feed that powers the web player's
//  "Booth" panel. Shapes and the display rules below mirror subwave's own
//  web/lib/sessionFeed.ts and BoothDrawer.tsx as closely as practical:
//  `role: "event"` turns are the literal prompts fed to the DJ agent
//  (internal prompt-engineering text, sometimes explicitly instructing the
//  model what NOT to say on air) and must never reach a listener — the web
//  player filters them out entirely, and so do we.

import Foundation

struct SessionResponse: Codable {
    var session: BoothSession?
    var messages: [SessionTurn]?
}

struct BoothSession: Codable {
    var id: String?
    var kind: String?
    var show: String?
    var startedAt: String?
}

struct SessionTurn: Codable {
    var t: String?
    var role: String?
    var kind: String?
    var text: String?
    var meta: SessionTurnMeta?
}

struct SessionTurnMeta: Codable {
    var personaId: String?
    var personaName: String?
    var airedAt: String?
    var trackId: String?
    var title: String?
    var artist: String?
    var say: String?
    var source: String?
    var requester: String?
    var requestedBy: String?
}

enum TurnDisplayClass {
    /// Spoken on-air verbatim (`role: "segment"`).
    case voice
    /// The agent's pick/request reasoning (`role: "dj"`).
    case dj
    /// A track that aired (`role: "track"`).
    case track
    /// Session-internal cues and raw agent prompts (`role: "event"`, or
    /// anything unrecognised) — never shown to listeners.
    case system
}

extension SessionTurn {
    var displayClass: TurnDisplayClass {
        switch role {
        case "segment": return .voice
        case "dj": return .dj
        case "track": return .track
        default: return .system
        }
    }

    /// `track` turns carry a "▶ " prefix in `text`; strip it so a row can
    /// supply its own marker.
    var displayText: String {
        let raw = text ?? ""
        guard displayClass == .track, raw.hasPrefix("▶") else { return raw }
        return raw.dropFirst().trimmingCharacters(in: .whitespaces)
    }

    var timestamp: Date? {
        guard let t else { return nil }
        return Self.isoFormatter.date(from: t)
    }

    // Timestamps carry fractional seconds ("...15.773Z"); the default
    // ISO8601DateFormatter options don't parse those and silently return nil.
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
