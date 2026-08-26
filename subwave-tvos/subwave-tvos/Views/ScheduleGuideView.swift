//
//  ScheduleGuideView.swift
//  subwave-tvos
//
//  "Guide" panel — the rolling next-24-hours lineup, collapsed from GET
//  /schedule's hourly slots into blocks (see Schedule.swift). Refetched
//  occasionally rather than polled like Booth/now-playing: a station's
//  lineup doesn't change minute to minute.

import SwiftUI

struct ScheduleGuideView: View {
    let client: SubwaveClient
    /// So "now playing" highlighting and the day boundary use the station's
    /// own clock, not the viewer's.
    let stationTimeZone: TimeZone?

    @State private var response: ScheduleResponse?
    @State private var loadError: String?
    @State private var pollTask: Task<Void, Never>?

    private static let refreshInterval: Duration = .seconds(300)

    var body: some View {
        Group {
            if let loadError, response == nil {
                ContentUnavailableView(loadError, systemImage: "calendar.badge.exclamationmark")
            } else if blocks.isEmpty {
                ContentUnavailableView("Nothing on the schedule.", systemImage: "calendar")
            } else {
                List {
                    Section("Now & Next") {
                        ForEach(blocks) { block in
                            ScheduleBlockRow(block: block, isNow: isNow(block))
                        }
                    }
                }
            }
        }
        .task {
            startPolling()
        }
        .onDisappear {
            pollTask?.cancel()
        }
    }

    /// The rolling next 24 hours — the on-air block plus whatever's still
    /// ahead, spanning past midnight when needed. A guide is for what's
    /// coming, not a log of what already played.
    private var blocks: [ScheduleBlock] {
        response?.blocksForNext24Hours(timeZone: stationTimeZone) ?? []
    }

    private var currentHour: Int {
        var calendar = Calendar(identifier: .gregorian)
        if let stationTimeZone { calendar.timeZone = stationTimeZone }
        return calendar.component(.hour, from: Date())
    }

    private func isNow(_ block: ScheduleBlock) -> Bool {
        (block.startHour..<block.endHour).contains(currentHour)
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: Self.refreshInterval)
            }
        }
    }

    private func refresh() async {
        do {
            response = try await client.fetchSchedule()
            loadError = nil
        } catch {
            loadError = "Couldn't reach the guide."
        }
    }
}

private struct ScheduleBlockRow: View {
    let block: ScheduleBlock
    let isNow: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(timeRange)
                .font(.caption)
                .foregroundStyle(isNow ? .primary : .secondary)
                .frame(width: 90, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(block.show?.name ?? "Unscheduled")
                    .font(.body.weight(isNow ? .semibold : .regular))
                if let host = block.host?.name {
                    Text("with \(host)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if isTomorrow {
                    Text("Tomorrow")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if isNow {
                Spacer()
                Text("NOW")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
        // See BoothRow: plain-text rows need an explicit focus target for
        // the List to scroll row by row on tvOS.
        .focusable()
    }

    /// `startHour`/`endHour` are offsets from the start of today (0..<48),
    /// so a block that runs past midnight still prints plain hour-of-day.
    private var timeRange: String {
        String(format: "%02d:00–%02d:00", block.startHour % 24, block.endHour % 24 == 0 ? 24 : block.endHour % 24)
    }

    private var isTomorrow: Bool {
        block.startHour >= 24
    }
}
