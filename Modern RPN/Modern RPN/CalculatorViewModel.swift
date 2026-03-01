import Foundation
import Combine

@MainActor
final class CalculatorViewModel: ObservableObject {
    enum Mode: Equatable {
        case basic
        case scientific
    }

    @Published private(set) var mode: Mode = .basic
    @Published private(set) var displayText = "0"
    @Published private(set) var stackLines = ["T:", "Z:", "Y:", "X:"]
    @Published private(set) var errorMessage: String?

    let historyStore: HistoryStore
    private var calculator = RPNCalculator()

    init(historyStore: HistoryStore? = nil) {
        self.historyStore = historyStore ?? HistoryStore()
        refresh()
    }

    func setMode(_ mode: Mode) {
        self.mode = mode
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
                expression: outcome.expression,
                result: outcome.result,
                stackSnapshot: outcome.stackSnapshot
            )
            historyStore.add(entry)
        }
        refresh()
    }

    private func refresh() {
        displayText = calculator.displayText
        stackLines = calculator.stackLines
        errorMessage = calculator.errorMessage
    }
}
