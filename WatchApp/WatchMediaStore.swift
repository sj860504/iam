import Foundation

/// Persists the watch-side library index and exposes it to the UI.
@MainActor
final class WatchMediaStore: ObservableObject {
    static let shared = WatchMediaStore()

    @Published private(set) var items: [MediaItem] = []

    private let indexURL: URL = {
        let docs = try! FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return docs.appendingPathComponent("library.json")
    }()

    private init() { load() }

    /// Called when a file transfer arrives from the phone. Moves the received
    /// file into the Media directory and records the item.
    func ingest(receivedFile url: URL, item: MediaItem) {
        do {
            let dest = try MediaStorage.url(for: item)
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: url, to: dest)
            if !items.contains(where: { $0.id == item.id }) {
                items.append(item)
                save()
            }
        } catch {
            print("Ingest failed: \(error)")
        }
    }

    func delete(_ item: MediaItem) {
        items.removeAll { $0.id == item.id }
        if let url = try? MediaStorage.url(for: item) {
            try? FileManager.default.removeItem(at: url)
        }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL) else { return }
        items = (try? JSONDecoder().decode([MediaItem].self, from: data)) ?? []
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: indexURL, options: .atomic)
        }
    }
}
