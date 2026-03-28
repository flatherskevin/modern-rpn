import Foundation
import Combine

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published private(set) var mode: CalculatorMode
    @Published var historyFilter: HistoryModeFilter
    @Published private(set) var displayText = "0"
    @Published private(set) var stackLines = ["T:", "Z:", "Y:", "X:"]
    @Published private(set) var financialRegisterLines = FinancialVariable.allCases.map { "\($0.label): —" }
    @Published private(set) var paymentMode: PaymentMode = .end
    @Published private(set) var memoryRegisters: [Int: Double] = [:]
    @Published private(set) var cashFlowInitialAmount: Double = 0
    @Published private(set) var cashFlowEntries: [CashFlowEntry] = []
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

    func performFinancialAction(_ variable: FinancialVariable) {
        record(calculator.performFinancialAction(variable))
        refresh()
    }

    func rollDown() {
        calculator.rollDown()
        refresh()
    }

    func clearX() {
        calculator.clearX()
        refresh()
    }

    func enterExponent() {
        calculator.enterExponent()
        refresh()
    }

    func setPaymentMode(_ paymentMode: PaymentMode) {
        calculator.setPaymentMode(paymentMode)
        refresh()
    }

    func storeMemory(index: Int) {
        do {
            try calculator.storeMemory(index: index)
        } catch {
            calculator.setErrorMessage((error as? LocalizedError)?.errorDescription ?? "Memory error")
        }
        refresh()
    }

    func recallMemory(index: Int) {
        do {
            record(try calculator.recallMemory(index: index))
        } catch {
            calculator.setErrorMessage((error as? LocalizedError)?.errorDescription ?? "Memory error")
        }
        refresh()
    }

    func setCashFlowInitialAmount(_ amount: Double) {
        calculator.setCashFlowInitialAmount(amount)
        refresh()
    }

    func addCashFlowEntry(amount: Double, count: Int) {
        do {
            try calculator.addCashFlowEntry(amount: amount, count: count)
        } catch {
            calculator.setErrorMessage((error as? LocalizedError)?.errorDescription ?? "Cash flow error")
        }
        refresh()
    }

    func updateCashFlowEntry(id: UUID, amount: Double, count: Int) {
        do {
            try calculator.updateCashFlowEntry(id: id, amount: amount, count: count)
        } catch {
            calculator.setErrorMessage((error as? LocalizedError)?.errorDescription ?? "Cash flow error")
        }
        refresh()
    }

    func removeCashFlowEntry(id: UUID) {
        calculator.removeCashFlowEntry(id: id)
        refresh()
    }

    func calculatePercent(base: Double, percent: Double) {
        record(calculator.calculatePercent(base: base, percent: percent))
        refresh()
    }

    func calculatePercentOfTotal(part: Double, total: Double) {
        record(calculator.calculatePercentOfTotal(part: part, total: total))
        refresh()
    }

    func calculatePercentDifference(from original: Double, to updated: Double) {
        record(calculator.calculatePercentDifference(from: original, to: updated))
        refresh()
    }

    func calculateDaysBetween(from startDate: Date, to endDate: Date) {
        do {
            record(try calculator.calculateDaysBetween(from: startDate, to: endDate))
        } catch {
            calculator.setErrorMessage((error as? LocalizedError)?.errorDescription ?? "Date error")
        }
        refresh()
    }

    func calculateDateByAdding(days: Int, to startDate: Date) {
        do {
            record(try calculator.calculateDateByAdding(days: days, to: startDate))
        } catch {
            calculator.setErrorMessage((error as? LocalizedError)?.errorDescription ?? "Date error")
        }
        refresh()
    }

    func calculateBondPrice(settlement: Date, maturity: Date, couponRatePercent: Double, yieldPercent: Double) {
        do {
            record(try calculator.calculateBondPrice(
                settlement: settlement,
                maturity: maturity,
                couponRatePercent: couponRatePercent,
                yieldPercent: yieldPercent
            ))
        } catch {
            calculator.setErrorMessage((error as? LocalizedError)?.errorDescription ?? "Bond error")
        }
        refresh()
    }

    func calculateBondYield(settlement: Date, maturity: Date, couponRatePercent: Double, price: Double) {
        do {
            record(try calculator.calculateBondYield(
                settlement: settlement,
                maturity: maturity,
                couponRatePercent: couponRatePercent,
                price: price
            ))
        } catch {
            calculator.setErrorMessage((error as? LocalizedError)?.errorDescription ?? "Bond error")
        }
        refresh()
    }

    func calculateNetPresentValue(ratePercent: Double) {
        do {
            record(try calculator.calculateNetPresentValue(ratePercent: ratePercent))
        } catch {
            calculator.setErrorMessage((error as? LocalizedError)?.errorDescription ?? "NPV error")
        }
        refresh()
    }

    func calculateInternalRateOfReturn() {
        do {
            record(try calculator.calculateInternalRateOfReturn())
        } catch {
            calculator.setErrorMessage((error as? LocalizedError)?.errorDescription ?? "IRR error")
        }
        refresh()
    }

    func calculateAmortization(periods: Int) -> AmortizationSummary? {
        do {
            let summary = try calculator.calculateAmortization(periods: periods)
            refresh()
            return summary
        } catch {
            calculator.setErrorMessage((error as? LocalizedError)?.errorDescription ?? "Amortization error")
            refresh()
            return nil
        }
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
        financialRegisterLines = calculator.financialRegisterLines
        paymentMode = calculator.paymentMode
        memoryRegisters = calculator.memoryRegisters
        cashFlowInitialAmount = calculator.cashFlowInitialAmount
        cashFlowEntries = calculator.cashFlowEntries
        errorMessage = calculator.errorMessage
        sessionStore.saveSession(calculator.session)
    }

    private func record(_ outcome: OperationResult?) {
        guard let outcome else { return }
        let entry = HistoryEntry(
            mode: outcome.mode,
            expression: outcome.expression,
            result: outcome.result,
            resultText: outcome.resultText,
            stackSnapshot: outcome.stackSnapshot
        )
        historyStore.add(entry)
    }
}
