import Foundation
import Combine

struct HistoryEntry: Codable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case id
        case mode
        case expression
        case result
        case resultText
        case timestamp
        case stackSnapshot
    }

    let id: UUID
    let mode: CalculatorMode
    let expression: String
    let result: Double
    let resultText: String?
    let timestamp: Date
    let stackSnapshot: [Double]

    init(
        id: UUID = UUID(),
        mode: CalculatorMode,
        expression: String,
        result: Double,
        resultText: String? = nil,
        timestamp: Date = Date(),
        stackSnapshot: [Double]
    ) {
        self.id = id
        self.mode = mode
        self.expression = expression
        self.result = result
        self.resultText = resultText
        self.timestamp = timestamp
        self.stackSnapshot = stackSnapshot
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        mode = try container.decodeIfPresent(CalculatorMode.self, forKey: .mode) ?? .standard
        expression = try container.decode(String.self, forKey: .expression)
        result = try container.decode(Double.self, forKey: .result)
        resultText = try container.decodeIfPresent(String.self, forKey: .resultText)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        stackSnapshot = try container.decode([Double].self, forKey: .stackSnapshot)
    }

    var displayResultText: String {
        resultText ?? RPNCalculator.format(result)
    }

    var modeTitle: String {
        mode.title
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

    func clear(filter: HistoryModeFilter) {
        switch filter.mode {
        case .none:
            clear()
        case .some(let mode):
            entries.removeAll { $0.mode == mode }
            persist()
        }
    }

    func removeEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
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
