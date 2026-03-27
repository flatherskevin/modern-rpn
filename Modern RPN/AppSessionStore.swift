import Foundation

enum HistoryModeFilter: String, CaseIterable, Codable, Identifiable {
    case all
    case standard
    case binary
    case hex

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .standard:
            return "Standard"
        case .hex:
            return "Hex"
        case .binary:
            return "Binary"
        }
    }

    var mode: CalculatorMode? {
        switch self {
        case .all:
            return nil
        case .standard:
            return .standard
        case .hex:
            return .hex
        case .binary:
            return .binary
        }
    }
}

struct CalculatorSession: Codable, Equatable {
    let mode: CalculatorMode
    let stack: [Double]
    let inputBuffer: String
    let isTyping: Bool
}

final class AppSessionStore {
    private let userDefaults: UserDefaults
    private let sessionKey: String
    private let historyFilterKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        sessionKey: String = "rpn.calculator.session",
        historyFilterKey: String = "rpn.history.filter"
    ) {
        self.userDefaults = userDefaults
        self.sessionKey = sessionKey
        self.historyFilterKey = historyFilterKey
    }

    func loadSession() -> CalculatorSession? {
        guard let data = userDefaults.data(forKey: sessionKey) else { return nil }
        return try? decoder.decode(CalculatorSession.self, from: data)
    }

    func saveSession(_ session: CalculatorSession) {
        guard let data = try? encoder.encode(session) else { return }
        userDefaults.set(data, forKey: sessionKey)
    }

    func loadHistoryFilter() -> HistoryModeFilter {
        guard let rawValue = userDefaults.string(forKey: historyFilterKey),
              let filter = HistoryModeFilter(rawValue: rawValue) else {
            return .all
        }
        return filter
    }

    func saveHistoryFilter(_ filter: HistoryModeFilter) {
        userDefaults.set(filter.rawValue, forKey: historyFilterKey)
    }
}
