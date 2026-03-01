import Foundation
import Combine

struct HistoryEntry: Codable, Identifiable {
    let id: UUID
    let expression: String
    let result: Double
    let timestamp: Date
    let stackSnapshot: [Double]

    init(
        id: UUID = UUID(),
        expression: String,
        result: Double,
        timestamp: Date = Date(),
        stackSnapshot: [Double]
    ) {
        self.id = id
        self.expression = expression
        self.result = result
        self.timestamp = timestamp
        self.stackSnapshot = stackSnapshot
    }
}

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []

    private let storageKey: String
    private let maxEntries: Int
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "rpn.history.entries",
        maxEntries: Int = 250
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.maxEntries = maxEntries
        load()
    }

    func add(_ entry: HistoryEntry) {
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        persist()
    }

    func clear() {
        entries.removeAll()
        userDefaults.removeObject(forKey: storageKey)
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        guard let decoded = try? decoder.decode([HistoryEntry].self, from: data) else { return }
        entries = decoded
    }

    private func persist() {
        guard let encoded = try? encoder.encode(entries) else { return }
        userDefaults.set(encoded, forKey: storageKey)
    }
}
