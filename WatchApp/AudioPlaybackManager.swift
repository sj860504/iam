import Foundation
import AVFoundation

/// Plays locally stored audio on the watch, including in the background and
/// through Bluetooth headphones when the phone is not nearby.
@MainActor
final class AudioPlaybackManager: NSObject, ObservableObject {
    static let shared = AudioPlaybackManager()

    @Published private(set) var currentItem: MediaItem?
    @Published private(set) var isPlaying = false

    private var player: AVAudioPlayer?

    private override init() { super.init() }

    func play(_ item: MediaItem) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, policy: .longFormAudio)
            try session.setActive(true)

            let url = try MediaStorage.url(for: item)
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.play()

            self.player = player
            self.currentItem = item
            self.isPlaying = true
        } catch {
            print("Playback failed: \(error)")
            isPlaying = false
        }
    }

    func togglePlayPause() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func stop() {
        player?.stop()
        player = nil
        currentItem = nil
        isPlaying = false
    }
}

extension AudioPlaybackManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
        }
    }
}
