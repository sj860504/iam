import SwiftUI

@main
struct IamApp: App {
    @StateObject private var library = PhoneLibraryStore()
    @StateObject private var connectivity = PhoneConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(library)
                .environmentObject(connectivity)
                .onAppear { connectivity.activate() }
        }
    }
}
