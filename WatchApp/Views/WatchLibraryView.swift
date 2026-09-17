import SwiftUI

struct WatchLibraryView: View {
    @EnvironmentObject var store: WatchMediaStore
    @EnvironmentObject var player: AudioPlaybackManager

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty {
                    ContentUnavailableView(
                        "곡 없음",
                        systemImage: "music.note",
                        description: Text("iPhone의 iam 앱에서 곡을 전송하세요."))
                } else {
                    List {
                        ForEach(store.items) { item in
                            Button {
                                player.play(item)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(item.title).lineLimit(1)
                                    Text(item.artist).font(.caption2)
                                        .foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.map { store.items[$0] }.forEach(store.delete)
                        }
                    }
                }
            }
            .navigationTitle("iam")
            .toolbar {
                if player.currentItem != nil {
                    ToolbarItem(placement: .bottomBar) {
                        NavigationLink {
                            NowPlayingView()
                        } label: {
                            Label("재생 중", systemImage: "waveform")
                        }
                    }
                }
            }
        }
    }
}
