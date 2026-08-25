//
//  BoothView.swift
//  subwave-tvos
//
//  The live DJ session feed (GET /session), filtered and labelled the same
//  way subwave's own web player does (web/lib/sessionFeed.ts): `system`
//  turns — the raw prompts driving the DJ agent — are never shown.

import SwiftUI

struct BoothView: View {
    let client: SubwaveClient
    @Environment(\.dismiss) private var dismiss

    @State private var turns: [SessionTurn] = []
    @State private var showName: String?
    @State private var loadError: String?
    @State private var pollTask: Task<Void, Never>?

    private static let pollInterval: Duration = .seconds(10)

    var body: some View {
        NavigationStack {
            Group {
                if let loadError, turns.isEmpty {
                    ContentUnavailableView(loadError, systemImage: "mic.slash")
                } else if turns.isEmpty {
                    ContentUnavailableView("Booth is quiet.", systemImage: "mic")
                } else {
                    List {
                        Section {
                            ForEach(visibleTurns.indices, id: \.self) { index in
                                BoothRow(turn: visibleTurns[index])
                            }
                        } header: {
                            Text(showName ?? "Booth")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
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

    /// Newest first, session-internal turns dropped — the same rule as
    /// subwave's web BoothDrawer.
    private var visibleTurns: [SessionTurn] {
        turns.filter { $0.displayClass != .system }.reversed()
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: Self.pollInterval)
            }
        }
    }

    private func refresh() async {
        do {
            let response = try await client.fetchSession()
            turns = response.messages ?? []
            showName = response.session?.show
            loadError = nil
        } catch {
            loadError = "Couldn't reach the booth."
        }
    }
}

private struct BoothRow: View {
    let turn: SessionTurn

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if let timestamp = turn.timestamp {
                    Text(timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(labelColor)
            }

            Text(bodyText)
                .font(turn.displayClass == .voice ? .body.italic() : .body)

            if let meta = metaLine {
                Text(meta)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var label: String {
        if turn.displayClass == .voice, let persona = turn.meta?.personaName {
            return persona.uppercased()
        }
        return (turn.kind ?? "").uppercased()
    }

    private var labelColor: Color {
        switch turn.displayClass {
        case .voice: return .orange
        case .dj: return .primary
        case .track, .system: return .secondary
        }
    }

    private var bodyText: String {
        turn.displayClass == .voice ? "\u{201C}\(turn.displayText)\u{201D}" : turn.displayText
    }

    private var metaLine: String? {
        guard let meta = turn.meta else { return nil }
        var bits: [String] = []

        let requester = meta.requester ?? meta.requestedBy
        if let requester, !requester.isEmpty {
            bits.append("requested by \(requester)")
        }
        if turn.displayClass == .track, let source = meta.source {
            bits.append("source: \(source)")
        }
        let titleArtist = [meta.title, meta.artist].compactMap { $0 }.filter { !$0.isEmpty }
        if !titleArtist.isEmpty {
            bits.append(titleArtist.joined(separator: " — "))
        }

        return bits.isEmpty ? nil : bits.joined(separator: " · ")
    }
}
