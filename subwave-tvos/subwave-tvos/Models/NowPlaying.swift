//
//  NowPlaying.swift
//  subwave-tvos
//
//  Shapes mirror docs/api.md's /now-playing and /dj examples in the subwave
//  repo (controller/src/connect/catalog.ts). Fields beyond title/artist are
//  only present once a track is analysed, so almost everything here is
//  optional rather than assumed present.

import Foundation

struct NowPlayingResponse: Codable {
    var nowPlaying: Track?
    var context: StationContext?
    var dj: DJSummary?
    var listeners: Int?
    var streamOnline: Bool?
    var stream: StreamDescriptor?
}

struct Track: Codable, Equatable {
    var title: String?
    var artist: String?
    var album: String?
    var subsonic_id: String?
    var genre: String?
    var bpm: Double?
    var musicalKey: String?
    var moods: [String]?

    /// `/cover/:id` proxies Subsonic art for this id, when present.
    var coverID: String? { subsonic_id }
}

struct StationContext: Codable {
    var time: String?
    var weather: String?
    var dominantMood: String?
}

struct DJSummary: Codable {
    var name: String?
    var tagline: String?
    var station: String?
}

struct StreamDescriptor: Codable {
    var mount: String?
    var format: String?
    var bitrate: Int?
    var opusEnabled: Bool?
    var flacEnabled: Bool?
    var aacEnabled: Bool?
}

/// GET /dj — the fuller persona read (now-playing's `dj` is a lighter echo of this).
struct DJPersona: Codable {
    var name: String?
    var tagline: String?
    var soul: String?
    var frequency: String?
    var djMode: Bool?
    var station: String?
    var location: String?
}
