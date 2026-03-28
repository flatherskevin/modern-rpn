import Foundation

enum HistoryModeFilter: String, CaseIterable, Codable, Identifiable {
    case all
    case standard
    case binary
    case hex
    case financial

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
        case .financial:
            return "Financial"
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
        case .financial:
            return .financial
        }
    }

    init?(mode: CalculatorMode) {
        switch mode {
        case .standard:
            self = .standard
        case .binary:
            self = .binary
        case .hex:
            self = .hex
        case .financial:
            self = .financial
        }
    }
}

struct CalculatorSession: Codable, Equatable {
    let mode: CalculatorMode
    let stack: [Double]
    let inputBuffer: String
    let isTyping: Bool
    let financialRegisters: FinancialRegisters

    init(
        mode: CalculatorMode,
        stack: [Double],
        inputBuffer: String,
        isTyping: Bool,
        financialRegisters: FinancialRegisters = FinancialRegisters()
    ) {
        self.mode = mode
        self.stack = stack
        self.inputBuffer = inputBuffer
        self.isTyping = isTyping
        self.financialRegisters = financialRegisters
    }

    private enum CodingKeys: String, CodingKey {
        case mode
        case stack
        case inputBuffer
        case isTyping
        case financialRegisters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decode(CalculatorMode.self, forKey: .mode)
        stack = try container.decode([Double].self, forKey: .stack)
        inputBuffer = try container.decode(String.self, forKey: .inputBuffer)
        isTyping = try container.decode(Bool.self, forKey: .isTyping)
        financialRegisters = try container.decodeIfPresent(FinancialRegisters.self, forKey: .financialRegisters) ?? FinancialRegisters()
    }
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
