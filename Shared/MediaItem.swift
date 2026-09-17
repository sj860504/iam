import Foundation

/// A single audio track that can live on the phone and be transferred to the watch.
/// Shared between the iOS companion and the watchOS app.
struct MediaItem: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var artist: String
    /// File name (not full path). The actual file lives in each device's
    /// documents directory under `Media/<fileName>`.
    var fileName: String
    /// Duration in seconds, if known.
    var duration: TimeInterval?

    init(id: UUID = UUID(), title: String, artist: String, fileName: String, duration: TimeInterval? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.fileName = fileName
        self.duration = duration
    }
}

extension MediaItem {
    /// Keys used in the WatchConnectivity file-transfer metadata dictionary.
    enum MetadataKey {
        static let id = "id"
        static let title = "title"
        static let artist = "artist"
        static let fileName = "fileName"
        static let duration = "duration"
    }

    /// A `[String: Any]` payload suitable for `WCSession.transferFile(_:metadata:)`.
    var transferMetadata: [String: Any] {
        var meta: [String: Any] = [
            MetadataKey.id: id.uuidString,
            MetadataKey.title: title,
            MetadataKey.artist: artist,
            MetadataKey.fileName: fileName
        ]
        if let duration { meta[MetadataKey.duration] = duration }
        return meta
    }

    /// Reconstructs a `MediaItem` from transfer metadata. Returns nil if required keys are missing.
    init?(metadata: [String: Any]) {
        guard
            let idString = metadata[MetadataKey.id] as? String,
            let id = UUID(uuidString: idString),
            let title = metadata[MetadataKey.title] as? String,
            let artist = metadata[MetadataKey.artist] as? String,
            let fileName = metadata[MetadataKey.fileName] as? String
        else { return nil }
        self.init(
            id: id,
            title: title,
            artist: artist,
            fileName: fileName,
            duration: metadata[MetadataKey.duration] as? TimeInterval
        )
    }
}

/// Shared filesystem helpers so both targets store media the same way.
enum MediaStorage {
    static let subdirectory = "Media"

    static func mediaDirectory() throws -> URL {
        let docs = try FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = docs.appendingPathComponent(subdirectory, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func url(for item: MediaItem) throws -> URL {
        try mediaDirectory().appendingPathComponent(item.fileName)
    }
}
