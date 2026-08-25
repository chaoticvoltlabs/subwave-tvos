//
//  NowPlayingView.swift
//  subwave-tvos
//

import SwiftUI

struct NowPlayingView: View {
    let station: Station

    @State private var player = PlayerService()
    @State private var response: NowPlayingResponse?
    @State private var coverImage: UIImage?
    @State private var loadError: String?
    @State private var isPresentingRequest = false
    @State private var isPresentingBooth = false
    @State private var pollTask: Task<Void, Never>?

    private var client: SubwaveClient? { SubwaveClient(station: station) }

    /// The public API is poll-based, no websocket/SSE (docs/api.md).
    private static let pollInterval: Duration = .seconds(15)

    var body: some View {
        VStack(spacing: 32) {
            coverArt

            VStack(spacing: 8) {
                Text(response?.nowPlaying?.title ?? "—")
                    .font(.title)
                    .bold()
                Text(response?.nowPlaying?.artist ?? station.name)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                if let dj = response?.dj?.name {
                    Text("On air: \(dj)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                if let listeners = response?.listeners?.current {
                    Text("\(listeners) listening")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            if let loadError {
                Text(loadError)
                    .foregroundStyle(.red)
            }
            if let playerError = player.playerError {
                Text(playerError)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 24) {
                Button {
                    player.togglePlayPause()
                } label: {
                    Label(player.isPlaying ? "Pause" : "Play", systemImage: player.isPlaying ? "pause.fill" : "play.fill")
                }
                Button {
                    isPresentingRequest = true
                } label: {
                    Label("Request a Song", systemImage: "text.bubble")
                }
                Button {
                    isPresentingBooth = true
                } label: {
                    Label("Booth", systemImage: "mic")
                }
            }
        }
        .padding(60)
        .navigationTitle(station.name)
        .sheet(isPresented: $isPresentingRequest) {
            if let client {
                RequestSongView(client: client)
            }
        }
        .sheet(isPresented: $isPresentingBooth) {
            if let client {
                BoothView(client: client)
            }
        }
        .task {
            player.configure(station: station)
            startPolling()
        }
        .onDisappear {
            pollTask?.cancel()
            player.stop()
        }
    }

    @ViewBuilder
    private var coverArt: some View {
        Group {
            if let coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "waveform")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.secondary)
                    .padding(80)
            }
        }
        .frame(width: 400, height: 400)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func startPolling() {
        guard let client else {
            loadError = "Invalid station address."
            return
        }
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                await refresh(using: client)
                try? await Task.sleep(for: Self.pollInterval)
            }
        }
    }

    private func refresh(using client: SubwaveClient) async {
        do {
            let latest = try await client.fetchNowPlaying()
            let trackChanged = latest.nowPlaying?.coverID != response?.nowPlaying?.coverID
            response = latest
            loadError = nil

            if trackChanged {
                coverImage = nil
                if let coverID = latest.nowPlaying?.coverID,
                   let data = try? await client.fetchCoverImageData(id: coverID) {
                    coverImage = UIImage(data: data)
                }
            }
            player.updateNowPlayingInfo(track: latest.nowPlaying, coverImage: coverImage)
        } catch {
            loadError = "Couldn't reach \(station.name)."
        }
    }
}
