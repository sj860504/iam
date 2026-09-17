import SwiftUI

@main
struct IamWatchApp: App {
    @StateObject private var store = WatchMediaStore.shared
    @StateObject private var player = AudioPlaybackManager.shared

    init() {
        // Wire the connectivity receiver to the store as early as possible.
        WatchConnectivityManager.shared.store = WatchMediaStore.shared
        WatchConnectivityManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            WatchLibraryView()
                .environmentObject(store)
                .environmentObject(player)
        }
    }
}
