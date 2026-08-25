//
//  PlayerService.swift
//  subwave-tvos
//

import AVFoundation
import MediaPlayer
import Observation
import UIKit

/// Owns the AVPlayer pointed at a station's Icecast MP3 mount, plus the Now
/// Playing Info Center / remote-command integration Siri Remote needs.
///
/// Credentials always ride as an explicit `Authorization: Basic` header
/// rather than `user:pass@` in the stream URL: AVPlayer silently drops
/// userinfo from media URLs (docs/private-station.md in the subwave repo,
/// issue #764), so this is required, not just tidier.
@Observable
final class PlayerService {
    private(set) var isPlaying = false
    private(set) var isBuffering = false
    private(set) var playerError: String?

    private var player: AVPlayer?
    private var statusObservation: NSKeyValueObservation?
    private var stationName: String = "SUB/WAVE"

    func configure(station: Station) {
        stop()
        playerError = nil

        guard let resolved = station.resolvedAddress else {
            playerError = "Invalid station address."
            return
        }
        stationName = station.name

        let streamURL = resolved.baseURL.appendingPathComponent("/stream.mp3")
        var headers: [String: String] = [:]
        if let credentials = resolved.credentials {
            let raw = "\(credentials.username):\(credentials.password)"
            if let token = raw.data(using: .utf8)?.base64EncodedString() {
                headers["Authorization"] = "Basic \(token)"
            }
        }

        // "AVURLAssetHTTPHeaderFieldsKey" — no longer declared in tvOS 26's
        // public AVFoundation headers, but still present in the linked binary
        // and still the documented way native SUB/WAVE clients attach the
        // stream Authorization header (docs/private-station.md).
        let asset = AVURLAsset(url: streamURL, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        self.player = player

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                switch item.status {
                case .failed:
                    self?.playerError = item.error?.localizedDescription ?? "Stream unreachable."
                    self?.isPlaying = false
                    UIApplication.shared.isIdleTimerDisabled = false
                default:
                    break
                }
            }
        }

        setUpRemoteCommands()
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func play() {
        guard let player else { return }
        player.play()
        isPlaying = true
        playerError = nil
        // tvOS's screensaver/sleep timer doesn't know audio is playing on
        // its own — a radio app is the exact case where that's wrong.
        // Re-enabled on pause/stop so the TV still sleeps normally the rest
        // of the time.
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        statusObservation = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }

    /// Called by the now-playing poller so the lock screen / Control Center
    /// (and tvOS's equivalent overlay) reflect the current track.
    func updateNowPlayingInfo(track: Track?, coverImage: UIImage?) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track?.title ?? stationName,
            MPMediaItemPropertyArtist: track?.artist ?? "",
            MPNowPlayingInfoPropertyIsLiveStream: true,
        ]
        if let album = track?.album {
            info[MPMediaItemPropertyAlbumTitle] = album
        }
        if let coverImage {
            let artwork = MPMediaItemArtwork(boundsSize: coverImage.size) { _ in coverImage }
            info[MPMediaItemPropertyArtwork] = artwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func setUpRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)

        center.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
    }
}
