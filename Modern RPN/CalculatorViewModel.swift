import Foundation
import Combine

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published private(set) var mode: CalculatorMode
    @Published var historyFilter: HistoryModeFilter
    @Published private(set) var displayText = "0"
    @Published private(set) var stackLines = ["T:", "Z:", "Y:", "X:"]
    @Published private(set) var errorMessage: String?

    let historyStore: HistoryStore
    let sessionStore: AppSessionStore
    private var calculator = RPNCalculator()

    init(
        historyStore: HistoryStore? = nil,
        sessionStore: AppSessionStore? = nil
    ) {
        self.historyStore = historyStore ?? HistoryStore()
        self.sessionStore = sessionStore ?? AppSessionStore()
        self.historyFilter = self.sessionStore.loadHistoryFilter()
        if let session = self.sessionStore.loadSession() {
            calculator.restore(session: session)
        }
        self.mode = calculator.mode
        refresh()
    }

    func setMode(_ mode: CalculatorMode) {
        calculator.setMode(mode)
        self.mode = calculator.mode
        refresh()
    }

    func tapDigit(_ digit: String) {
        calculator.tapDigit(digit)
        refresh()
    }

    func tapDecimal() {
        calculator.tapDecimal()
        refresh()
    }

    func toggleSign() {
        calculator.toggleSign()
        refresh()
    }

    func enter() {
        _ = calculator.enter()
        refresh()
    }

    func drop() {
        calculator.drop()
        refresh()
    }

    func backspace() {
        calculator.backspace()
        refresh()
    }

    func swap() {
        calculator.swap()
        refresh()
    }

    func clearAll() {
        calculator.clearAll()
        refresh()
    }

    func perform(_ operation: RPNCalculator.BinaryOperation) {
        if let outcome = calculator.perform(operation) {
            let entry = HistoryEntry(
                mode: outcome.mode,
                expression: outcome.expression,
                result: outcome.result,
                resultText: outcome.resultText,
                stackSnapshot: outcome.stackSnapshot
            )
            historyStore.add(entry)
        }
        refresh()
    }

    var filteredHistoryEntries: [HistoryEntry] {
        guard let selectedMode = historyFilter.mode else { return historyStore.entries }
        return historyStore.entries.filter { $0.mode == selectedMode }
    }

    func setHistoryFilter(_ filter: HistoryModeFilter) {
        historyFilter = filter
        sessionStore.saveHistoryFilter(filter)
    }

    private func refresh() {
        mode = calculator.mode
        displayText = calculator.displayText
        stackLines = calculator.stackLines
        errorMessage = calculator.errorMessage
        sessionStore.saveSession(calculator.session)
    }
}
