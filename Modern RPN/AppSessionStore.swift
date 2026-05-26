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
    let modeStates: [CalculatorMode: CalculatorModeState]

    var stack: [Double] {
        state(for: mode).stack
    }

    var inputBuffer: String {
        state(for: mode).inputBuffer
    }

    var isTyping: Bool {
        state(for: mode).isTyping
    }

    var financialRegisters: FinancialRegisters {
        state(for: mode).financialRegisters
    }

    init(
        mode: CalculatorMode,
        stack: [Double],
        inputBuffer: String,
        isTyping: Bool,
        financialRegisters: FinancialRegisters = FinancialRegisters()
    ) {
        self.mode = mode
        self.modeStates = [
            mode: CalculatorModeState(
                stack: stack,
                inputBuffer: inputBuffer,
                isTyping: isTyping,
                financialRegisters: financialRegisters
            )
        ]
    }

    init(
        mode: CalculatorMode,
        modeStates: [CalculatorMode: CalculatorModeState]
    ) {
        self.mode = mode
        self.modeStates = modeStates
    }

    private enum CodingKeys: String, CodingKey {
        case mode
        case modeStates
        case stack
        case inputBuffer
        case isTyping
        case financialRegisters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decode(CalculatorMode.self, forKey: .mode)
        if let modeStates = try container.decodeIfPresent([CalculatorMode: CalculatorModeState].self, forKey: .modeStates) {
            self.modeStates = modeStates
        } else {
            let stack = try container.decode([Double].self, forKey: .stack)
            let inputBuffer = try container.decode(String.self, forKey: .inputBuffer)
            let isTyping = try container.decode(Bool.self, forKey: .isTyping)
            let financialRegisters = try container.decodeIfPresent(FinancialRegisters.self, forKey: .financialRegisters) ?? FinancialRegisters()
            self.modeStates = [
                mode: CalculatorModeState(
                    stack: stack,
                    inputBuffer: inputBuffer,
                    isTyping: isTyping,
                    financialRegisters: financialRegisters
                )
            ]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mode, forKey: .mode)
        try container.encode(modeStates, forKey: .modeStates)
        try container.encode(stack, forKey: .stack)
        try container.encode(inputBuffer, forKey: .inputBuffer)
        try container.encode(isTyping, forKey: .isTyping)
        try container.encode(financialRegisters, forKey: .financialRegisters)
    }

    func state(for mode: CalculatorMode) -> CalculatorModeState {
        modeStates[mode] ?? CalculatorModeState()
    }

    func withModeState(_ state: CalculatorModeState, for mode: CalculatorMode) -> CalculatorSession {
        var updated = modeStates
        updated[mode] = state
        return CalculatorSession(mode: self.mode, modeStates: updated)
    }

    func switchingCurrentMode(to mode: CalculatorMode) -> CalculatorSession {
        CalculatorSession(mode: mode, modeStates: modeStates)
    }
}

struct CalculatorModeState: Codable, Equatable {
    let stack: [Double]
    let inputBuffer: String
    let isTyping: Bool
    let financialRegisters: FinancialRegisters

    init(
        stack: [Double] = [],
        inputBuffer: String = "0",
        isTyping: Bool = false,
        financialRegisters: FinancialRegisters = FinancialRegisters()
    ) {
        self.stack = stack
        self.inputBuffer = inputBuffer
        self.isTyping = isTyping
        self.financialRegisters = financialRegisters
    }
}

struct AppSessionStore {
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
