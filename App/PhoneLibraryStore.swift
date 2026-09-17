import Foundation
import AVFoundation
import UniformTypeIdentifiers

/// Holds the phone-side library and imports files the user picked (files they
/// already have the rights to). Persists an index as JSON in the documents dir.
@MainActor
final class PhoneLibraryStore: ObservableObject {
    @Published private(set) var items: [MediaItem] = []

    private let indexURL: URL = {
        let docs = try! FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return docs.appendingPathComponent("library.json")
    }()

    init() { load() }

    /// Imports a picked file: copies it into the Media directory and reads metadata.
    /// Returns the created item so the caller can queue a transfer to the watch.
    @discardableResult
    func importFile(from source: URL) throws -> MediaItem {
        let needsStop = source.startAccessingSecurityScopedResource()
        defer { if needsStop { source.stopAccessingSecurityScopedResource() } }

        let ext = source.pathExtension.isEmpty ? "m4a" : source.pathExtension
        let fileName = "\(UUID().uuidString).\(ext)"
        let dest = try MediaStorage.mediaDirectory().appendingPathComponent(fileName)
        try FileManager.default.copyItem(at: source, to: dest)

        let asset = AVURLAsset(url: dest)
        let title = Self.metadataString(asset, .commonKeyTitle)
            ?? source.deletingPathExtension().lastPathComponent
        let artist = Self.metadataString(asset, .commonKeyArtist) ?? "Unknown"
        let duration = CMTimeGetSeconds(asset.duration)

        let item = MediaItem(
            title: title, artist: artist, fileName: fileName,
            duration: duration.isFinite ? duration : nil)
        items.append(item)
        save()
        return item
    }

    func delete(_ item: MediaItem) {
        items.removeAll { $0.id == item.id }
        if let url = try? MediaStorage.url(for: item) {
            try? FileManager.default.removeItem(at: url)
        }
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: indexURL) else { return }
        items = (try? JSONDecoder().decode([MediaItem].self, from: data)) ?? []
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: indexURL, options: .atomic)
        }
    }

    private static func metadataString(_ asset: AVURLAsset, _ key: AVMetadataKey) -> String? {
        let items = AVMetadataItem.metadataItems(
            from: asset.commonMetadata, withKey: key, keySpace: .common)
        return items.first?.stringValue
    }
}
