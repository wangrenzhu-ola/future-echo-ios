import Foundation

public protocol SnapshotRepository {
    func load() throws -> AppSnapshot
    func save(_ snapshot: AppSnapshot) throws
    func reset() throws
}

public enum SnapshotRepositoryError: Error, Equatable {
    case simulatedWriteFailure
}

public final class JSONSnapshotRepository: SnapshotRepository {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let simulateWriteFailure: Bool

    public init(fileURL: URL, simulateWriteFailure: Bool = false) {
        self.fileURL = fileURL
        self.simulateWriteFailure = simulateWriteFailure

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        self.decoder = JSONDecoder()
    }

    public func load() throws -> AppSnapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return AppSnapshot()
        }
        return try decoder.decode(AppSnapshot.self, from: Data(contentsOf: fileURL))
    }

    public func save(_ snapshot: AppSnapshot) throws {
        if simulateWriteFailure {
            throw SnapshotRepositoryError.simulatedWriteFailure
        }
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try encoder.encode(snapshot).write(to: fileURL, options: .atomic)
    }

    public func reset() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}
