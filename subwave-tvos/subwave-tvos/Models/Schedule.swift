//
//  Schedule.swift
//  subwave-tvos
//
//  GET /schedule — confirmed live against radio.kluit.se. Two surprises
//  versus docs/api.md's simplified example: days are keyed "0"–"6" (JS
//  `Date.getDay()`, 0 = Sunday), not "mon"/"tue", and each day is 24 hourly
//  slots holding a show id (or null) rather than any richer shape. A show's
//  `topic` is its multi-hundred-word creative brief for the DJ agent — the
//  same category of internal prompt text as /session's `event` turns — so
//  it's deliberately left unmodeled; only listener-facing fields are kept.

import Foundation

struct ScheduleResponse: Codable {
    var personas: [Persona]?
    var shows: [Show]?
    var schedule: [String: [String?]]?
    var timezone: String?
}

struct Persona: Codable {
    var id: String?
    var name: String?
    var tagline: String?
}

struct Show: Codable {
    var id: String?
    var name: String?
    var mood: String?
    var personaId: String?
    var guestPersonaIds: [String]?
}

/// One collapsed run of consecutive same-show hours on a single day.
struct ScheduleBlock: Identifiable {
    var id: String { "\(startHour)-\(showId ?? "gap")" }
    var startHour: Int
    var endHour: Int
    var showId: String?
    var show: Show?
    var host: Persona?
}

extension ScheduleResponse {
    /// Today's blocks in the station's own week (JS `Date.getDay()`
    /// indexing), collapsing consecutive hours that share a show id.
    func blocksForToday(referenceDate: Date = Date(), timeZone: TimeZone? = nil) -> [ScheduleBlock] {
        var calendar = Calendar(identifier: .gregorian)
        if let timeZone { calendar.timeZone = timeZone }
        // Foundation's `.weekday` is 1...7, Sunday-first — same origin as JS's
        // 0-indexed `getDay()`, just off by one.
        let jsWeekday = calendar.component(.weekday, from: referenceDate) - 1
        guard let hours = schedule?["\(jsWeekday)"] else { return [] }

        let showsByID = Dictionary(uniqueKeysWithValues: (shows ?? []).compactMap { show in
            show.id.map { ($0, show) }
        })
        let personasByID = Dictionary(uniqueKeysWithValues: (personas ?? []).compactMap { persona in
            persona.id.map { ($0, persona) }
        })

        var blocks: [ScheduleBlock] = []
        for (hour, showID) in hours.enumerated() {
            if var last = blocks.last, last.showId == showID {
                last.endHour = hour + 1
                blocks[blocks.count - 1] = last
            } else {
                let show = showID.flatMap { showsByID[$0] }
                let host = show?.personaId.flatMap { personasByID[$0] }
                blocks.append(ScheduleBlock(startHour: hour, endHour: hour + 1, showId: showID, show: show, host: host))
            }
        }
        return blocks
    }
}
