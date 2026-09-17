import Foundation
import WatchConnectivity

/// Manages the WCSession on the phone and sends media files to the watch.
final class PhoneConnectivityManager: NSObject, ObservableObject {
    static let shared = PhoneConnectivityManager()

    @Published var isReachable = false
    @Published var pendingTransfers = 0

    private override init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Queues a file transfer to the watch. WCSession handles retry/resume even
    /// if the watch is not currently reachable.
    func send(_ item: MediaItem) {
        guard WCSession.isSupported() else { return }
        do {
            let url = try MediaStorage.url(for: item)
            let transfer = WCSession.default.transferFile(url, metadata: item.transferMetadata)
            _ = transfer
            DispatchQueue.main.async { self.pendingTransfers += 1 }
        } catch {
            print("Transfer failed to start: \(error)")
        }
    }
}

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        DispatchQueue.main.async {
            self.pendingTransfers = max(0, self.pendingTransfers - 1)
        }
        if let error { print("Transfer error: \(error)") }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
