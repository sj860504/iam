import Foundation
import WatchConnectivity

/// Receives media files sent from the phone.
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()

    weak var store: WatchMediaStore?

    private override init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let metadata = file.metadata, let item = MediaItem(metadata: metadata) else { return }
        // WCSessionFile.fileURL is only valid inside this callback; hand it to the
        // store synchronously on the main actor to move it into place.
        let url = file.fileURL
        Task { @MainActor in
            self.store?.ingest(receivedFile: url, item: item)
        }
    }
}
