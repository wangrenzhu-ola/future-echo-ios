import Foundation
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
@Model
final class PersistedAppSnapshot {
    @Attribute(.unique) var key: String
    @Attribute(.externalStorage) var payload: Data

    init(key: String = "current", payload: Data) {
        self.key = key
        self.payload = payload
    }
}

@available(iOS 17.0, macOS 14.0, *)
public final class SwiftDataSnapshotRepository: SnapshotRepository {
    private let context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(inMemory: Bool = false) throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        let container = try ModelContainer(
            for: PersistedAppSnapshot.self,
            configurations: configuration
        )
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    public func load() throws -> AppSnapshot {
        var descriptor = FetchDescriptor<PersistedAppSnapshot>()
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else {
            return AppSnapshot()
        }
        return try decoder.decode(AppSnapshot.self, from: record.payload)
    }

    public func save(_ snapshot: AppSnapshot) throws {
        let payload = try encoder.encode(snapshot)
        var descriptor = FetchDescriptor<PersistedAppSnapshot>()
        descriptor.fetchLimit = 1
        if let record = try context.fetch(descriptor).first {
            record.payload = payload
        } else {
            context.insert(PersistedAppSnapshot(payload: payload))
        }
        try context.save()
    }

    public func reset() throws {
        try context.delete(model: PersistedAppSnapshot.self)
        try context.save()
    }
}
