import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var player: AudioPlaybackManager

    var body: some View {
        VStack(spacing: 12) {
            if let item = player.currentItem {
                Text(item.title).font(.headline).multilineTextAlignment(.center)
                Text(item.artist).font(.caption).foregroundStyle(.secondary)
            } else {
                Text("재생 중인 곡 없음").foregroundStyle(.secondary)
            }

            HStack(spacing: 24) {
                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                Button {
                    player.stop()
                } label: {
                    Image(systemName: "stop.fill").font(.title2)
                }
            }
        }
        .navigationTitle("재생")
    }
}
