//
//  ScheduleGuideView.swift
//  subwave-tvos
//
//  "Guide" panel — today's show lineup, collapsed from GET /schedule's
//  24 hourly slots into blocks (see Schedule.swift). Refetched occasionally
//  rather than polled like Booth/now-playing: a station's lineup for today
//  doesn't change minute to minute.

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
                ContentUnavailableView("Nothing left on today's schedule.", systemImage: "calendar")
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

    /// Today's blocks that haven't fully aired yet — the on-air one plus
    /// whatever's still ahead. A guide is for what's coming, not a log of
    /// what already played.
    private var blocks: [ScheduleBlock] {
        let currentHour = currentHour
        return (response?.blocksForToday(timeZone: stationTimeZone) ?? [])
            .filter { $0.endHour > currentHour }
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
            }

            if isNow {
                Spacer()
                Text("NOW")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    private var timeRange: String {
        String(format: "%02d:00–%02d:00", block.startHour, block.endHour)
    }
}
