import Foundation

enum FinancialVariable: String, CaseIterable, Codable, Identifiable {
    case numberOfPeriods
    case interestRate
    case presentValue
    case payment
    case futureValue

    var id: String { rawValue }

    var label: String {
        switch self {
        case .numberOfPeriods:
            return "n"
        case .interestRate:
            return "i"
        case .presentValue:
            return "PV"
        case .payment:
            return "PMT"
        case .futureValue:
            return "FV"
        }
    }
}

enum PaymentMode: String, CaseIterable, Codable, Identifiable {
    case end
    case begin

    var id: String { rawValue }

    var title: String {
        rawValue.uppercased()
    }
}

struct CashFlowEntry: Codable, Equatable, Identifiable {
    let id: UUID
    var amount: Double
    var count: Int

    init(id: UUID = UUID(), amount: Double, count: Int) {
        self.id = id
        self.amount = amount
        self.count = count
    }
}

struct AmortizationSummary: Equatable {
    let periods: Int
    let principalPaid: Double
    let interestPaid: Double
    let remainingBalance: Double
}

struct FinancialRegisters: Codable, Equatable {
    private var values: [FinancialVariable: Double] = [:]
    var paymentMode: PaymentMode = .end
    var memoryRegisters: [Int: Double] = [:]
    var cashFlowInitialAmount: Double = 0
    var cashFlowEntries: [CashFlowEntry] = []

    subscript(variable: FinancialVariable) -> Double? {
        get { values[variable] }
        set { values[variable] = newValue }
    }

    func value(for variable: FinancialVariable) -> Double? {
        values[variable]
    }

    mutating func set(_ value: Double, for variable: FinancialVariable) {
        values[variable] = value
    }

    private enum CodingKeys: String, CodingKey {
        case values
        case paymentMode
        case memoryRegisters
        case cashFlowInitialAmount
        case cashFlowEntries
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        values = try container.decodeIfPresent([FinancialVariable: Double].self, forKey: .values) ?? [:]
        paymentMode = try container.decodeIfPresent(PaymentMode.self, forKey: .paymentMode) ?? .end
        memoryRegisters = try container.decodeIfPresent([Int: Double].self, forKey: .memoryRegisters) ?? [:]
        cashFlowInitialAmount = try container.decodeIfPresent(Double.self, forKey: .cashFlowInitialAmount) ?? 0
        cashFlowEntries = try container.decodeIfPresent([CashFlowEntry].self, forKey: .cashFlowEntries) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(values, forKey: .values)
        try container.encode(paymentMode, forKey: .paymentMode)
        try container.encode(memoryRegisters, forKey: .memoryRegisters)
        try container.encode(cashFlowInitialAmount, forKey: .cashFlowInitialAmount)
        try container.encode(cashFlowEntries, forKey: .cashFlowEntries)
    }

    func canSolve(_ target: FinancialVariable) -> Bool {
        FinancialVariable.allCases
            .filter { $0 != target }
            .allSatisfy { values[$0] != nil }
    }

    func lines(using mode: CalculatorMode) -> [String] {
        FinancialVariable.allCases.map { variable in
            let formattedValue = values[variable].map(mode.format) ?? "—"
            return "\(variable.label): \(formattedValue)"
        }
    }
}

private enum FinancialSolverError: LocalizedError {
    case missingInputs
    case enterValueFirst
    case invalidNumber
    case invalidPeriods
    case invalidRate
    case invalidMath
    case invalidRegister
    case invalidCashFlow
    case invalidDateOrder
    case invalidBondInput

    var errorDescription: String? {
        switch self {
        case .missingInputs:
            return "Need four financial values"
        case .enterValueFirst:
            return "Enter a value first"
        case .invalidNumber:
            return "Invalid number"
        case .invalidPeriods:
            return "n must be greater than zero"
        case .invalidRate:
            return "Unable to solve rate"
        case .invalidMath:
            return "Invalid financial inputs"
        case .invalidRegister:
            return "Register must be 0-9"
        case .invalidCashFlow:
            return "Invalid cash flow"
        case .invalidDateOrder:
            return "Invalid date range"
        case .invalidBondInput:
            return "Invalid bond inputs"
        }
    }
}

final class RPNCalculator {
    enum BinaryOperation: String, CaseIterable, Hashable {
        case add = "+"
        case subtract = "-"
        case multiply = "*"
        case divide = "/"

        func apply(_ lhs: Double, _ rhs: Double) -> Double? {
            switch self {
            case .add:
                return lhs + rhs
            case .subtract:
                return lhs - rhs
            case .multiply:
                return lhs * rhs
            case .divide:
                guard rhs != 0 else { return nil }
                return lhs / rhs
            }
        }
    }

    private(set) var mode: CalculatorMode
    private(set) var stack: [Double] = []
    private(set) var inputBuffer: String = "0"
    private(set) var isTyping = false
    private(set) var errorMessage: String?
    private(set) var financialRegisters = FinancialRegisters()

    init(mode: CalculatorMode = .standard) {
        self.mode = mode
    }

    nonisolated deinit {}

    var displayText: String {
        if isTyping {
            return inputBuffer
        }
        guard let top = stack.last else { return "0" }
        return mode.format(top)
    }

    var stackLines: [String] {
        let labels = ["T", "Z", "Y", "X"]
        let slice = Array(stack.suffix(4))
        let padded = Array(repeating: Double?.none, count: max(0, 4 - slice.count)) + slice.map { Optional($0) }

        return zip(labels, padded).map { label, value in
            if let value {
                return "\(label): \(mode.format(value))"
            }
            return "\(label):"
        }
    }

    var financialRegisterLines: [String] {
        financialRegisters.lines(using: mode)
    }

    var paymentMode: PaymentMode {
        financialRegisters.paymentMode
    }

    var memoryRegisters: [Int: Double] {
        financialRegisters.memoryRegisters
    }

    var cashFlowInitialAmount: Double {
        financialRegisters.cashFlowInitialAmount
    }

    var cashFlowEntries: [CashFlowEntry] {
        financialRegisters.cashFlowEntries
    }

    func setMode(_ mode: CalculatorMode) {
        if isTyping, let value = self.mode.parse(inputBuffer) {
            inputBuffer = mode.format(value)
        }

        self.mode = mode
    }

    func restore(session: CalculatorSession) {
        mode = session.mode
        stack = session.stack
        inputBuffer = session.inputBuffer
        isTyping = session.isTyping
        financialRegisters = session.financialRegisters
        errorMessage = nil
    }

    var session: CalculatorSession {
        CalculatorSession(
            mode: mode,
            stack: stack,
            inputBuffer: inputBuffer,
            isTyping: isTyping,
            financialRegisters: financialRegisters
        )
    }

    func tapDigit(_ digit: String) {
        guard let normalizedDigit = mode.normalizeDigit(digit) else { return }
        errorMessage = nil

        if isTyping {
            if inputBuffer.hasSuffix("e") || inputBuffer.hasSuffix("e-") {
                inputBuffer.append(normalizedDigit)
                return
            }

            if !mode.canAppend(to: inputBuffer) {
                inputBuffer = normalizedDigit
                return
            }

            if inputBuffer == "0" {
                inputBuffer = normalizedDigit
            } else if inputBuffer == "-0" {
                inputBuffer = "-" + normalizedDigit
            } else {
                inputBuffer.append(normalizedDigit)
            }
        } else {
            inputBuffer = normalizedDigit
            isTyping = true
        }
    }

    func tapDecimal() {
        guard mode.supportsDecimalInput else { return }
        errorMessage = nil

        if isTyping {
            guard !inputBuffer.contains("."), !inputBuffer.lowercased().contains("e") else { return }
            inputBuffer.append(".")
        } else {
            inputBuffer = "0."
            isTyping = true
        }
    }

    func toggleSign() {
        errorMessage = nil

        if isTyping {
            if let exponentRange = inputBuffer.range(of: "e", options: .caseInsensitive) {
                let exponent = inputBuffer[exponentRange.upperBound...]
                if exponent.hasPrefix("-") {
                    inputBuffer.removeSubrange(exponentRange.upperBound...inputBuffer.index(after: exponentRange.upperBound))
                } else {
                    inputBuffer.insert("-", at: exponentRange.upperBound)
                }
                return
            }

            if inputBuffer == "0" { return }
            if inputBuffer.hasPrefix("-") {
                inputBuffer.removeFirst()
            } else {
                inputBuffer = "-" + inputBuffer
            }
            return
        }

        guard let top = stack.popLast() else { return }
        stack.append(-top)
    }

    @discardableResult
    func enter() -> Double? {
        errorMessage = nil

        if isTyping {
            guard let value = mode.parse(inputBuffer) else {
                errorMessage = "Invalid number"
                return nil
            }
            stack.append(value)
            isTyping = false
            inputBuffer = "0"
            return value
        }

        guard let top = stack.last else { return nil }
        stack.append(top)
        return top
    }

    func drop() {
        errorMessage = nil

        if isTyping {
            inputBuffer = "0"
            isTyping = false
            return
        }

        _ = stack.popLast()
    }

    func rollDown() {
        errorMessage = nil
        if isTyping {
            _ = enter()
        }
        guard stack.count >= 2 else { return }
        let last = stack.removeLast()
        stack.insert(last, at: max(0, stack.count - 3))
    }

    func clearX() {
        errorMessage = nil
        if isTyping {
            inputBuffer = "0"
            isTyping = false
            return
        }
        guard !stack.isEmpty else { return }
        stack.removeLast()
    }

    func backspace() {
        errorMessage = nil

        guard isTyping else { return }

        _ = inputBuffer.popLast()
        if inputBuffer.isEmpty || inputBuffer == "-" || inputBuffer.lowercased() == "e" {
            inputBuffer = "0"
            isTyping = false
        }
    }

    func enterExponent() {
        errorMessage = nil

        if !isTyping {
            inputBuffer = displayText
            isTyping = true
        }

        guard !inputBuffer.lowercased().contains("e") else { return }
        inputBuffer.append("e")
    }

    func swap() {
        errorMessage = nil

        if isTyping {
            _ = enter()
        }

        guard stack.count >= 2 else { return }
        stack.swapAt(stack.count - 1, stack.count - 2)
    }

    func clearAll() {
        stack.removeAll()
        inputBuffer = "0"
        isTyping = false
        errorMessage = nil
        financialRegisters = FinancialRegisters()
    }

    func setPaymentMode(_ paymentMode: PaymentMode) {
        errorMessage = nil
        financialRegisters.paymentMode = paymentMode
    }

    func setErrorMessage(_ message: String) {
        errorMessage = message
    }

    func storeMemory(index: Int) throws {
        guard (0...9).contains(index) else { throw FinancialSolverError.invalidRegister }
        let value = try currentValueForStorage()
        financialRegisters.memoryRegisters[index] = value
        finishFinancialStore(with: value)
    }

    @discardableResult
    func recallMemory(index: Int) throws -> OperationResult? {
        guard (0...9).contains(index) else { throw FinancialSolverError.invalidRegister }
        guard let value = financialRegisters.memoryRegisters[index] else {
            throw FinancialSolverError.enterValueFirst
        }
        stack.append(value)
        return OperationResult(
            mode: mode,
            expression: "RCL \(index)",
            result: value,
            resultText: mode.format(value),
            stackSnapshot: stack
        )
    }

    func setCashFlowInitialAmount(_ amount: Double) {
        errorMessage = nil
        financialRegisters.cashFlowInitialAmount = amount
    }

    func addCashFlowEntry(amount: Double, count: Int) throws {
        guard count > 0, amount.isFinite else { throw FinancialSolverError.invalidCashFlow }
        financialRegisters.cashFlowEntries.append(CashFlowEntry(amount: amount, count: count))
    }

    func updateCashFlowEntry(id: UUID, amount: Double, count: Int) throws {
        guard count > 0, amount.isFinite else { throw FinancialSolverError.invalidCashFlow }
        guard let index = financialRegisters.cashFlowEntries.firstIndex(where: { $0.id == id }) else { return }
        financialRegisters.cashFlowEntries[index].amount = amount
        financialRegisters.cashFlowEntries[index].count = count
    }

    func removeCashFlowEntry(id: UUID) {
        financialRegisters.cashFlowEntries.removeAll { $0.id == id }
    }

    @discardableResult
    func perform(_ operation: BinaryOperation) -> OperationResult? {
        errorMessage = nil

        if isTyping {
            _ = enter()
        }

        guard stack.count >= 2 else {
            errorMessage = "Need two values"
            return nil
        }

        let rhs = stack.removeLast()
        let lhs = stack.removeLast()

        guard let result = operation.apply(lhs, rhs) else {
            stack.append(lhs)
            stack.append(rhs)
            errorMessage = "Cannot divide by zero"
            return nil
        }

        stack.append(result)

        return OperationResult(
            mode: mode,
            expression: "\(mode.format(lhs)) \(operation.rawValue) \(mode.format(rhs))",
            result: result,
            resultText: mode.format(result),
            stackSnapshot: stack
        )
    }

    @discardableResult
    func performFinancialAction(_ variable: FinancialVariable) -> OperationResult? {
        errorMessage = nil

        do {
            if shouldStoreFinancialValue(for: variable) {
                let value = try currentValueForStorage()
                financialRegisters.set(value, for: variable)
                finishFinancialStore(with: value)
                return nil
            }

            let solvedValue = try solveFinancialVariable(variable)
            financialRegisters.set(solvedValue, for: variable)
            stack.append(solvedValue)

            return OperationResult(
                mode: mode,
                expression: "Solve \(variable.label)",
                result: solvedValue,
                resultText: mode.format(solvedValue),
                stackSnapshot: stack
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Financial error"
            return nil
        }
    }

    @discardableResult
    func calculatePercent(base: Double, percent: Double) -> OperationResult {
        let result = base * percent / 100
        stack.append(result)
        return OperationResult(
            mode: mode,
            expression: "\(mode.format(base)) % \(mode.format(percent))",
            result: result,
            resultText: mode.format(result),
            stackSnapshot: stack
        )
    }

    @discardableResult
    func calculatePercentOfTotal(part: Double, total: Double) -> OperationResult {
        let result = (part / total) * 100
        stack.append(result)
        return OperationResult(
            mode: mode,
            expression: "%T \(mode.format(part)) of \(mode.format(total))",
            result: result,
            resultText: mode.format(result),
            stackSnapshot: stack
        )
    }

    @discardableResult
    func calculatePercentDifference(from original: Double, to updated: Double) -> OperationResult {
        let result = ((updated - original) / original) * 100
        stack.append(result)
        return OperationResult(
            mode: mode,
            expression: "Δ% \(mode.format(original)) → \(mode.format(updated))",
            result: result,
            resultText: mode.format(result),
            stackSnapshot: stack
        )
    }

    @discardableResult
    func calculateDaysBetween(from startDate: Date, to endDate: Date) throws -> OperationResult {
        guard startDate <= endDate else { throw FinancialSolverError.invalidDateOrder }
        let calendar = Calendar(identifier: .gregorian)
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: endDate)).day ?? 0
        let result = Double(days)
        stack.append(result)
        return OperationResult(
            mode: mode,
            expression: "Days between \(Self.dateFormatter.string(from: startDate)) and \(Self.dateFormatter.string(from: endDate))",
            result: result,
            resultText: "\(days)",
            stackSnapshot: stack
        )
    }

    @discardableResult
    func calculateDateByAdding(days: Int, to startDate: Date) throws -> OperationResult {
        guard let newDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: startDate) else {
            throw FinancialSolverError.invalidMath
        }
        let numericDate = Double(Self.encodedDate(newDate))
        stack.append(numericDate)
        return OperationResult(
            mode: mode,
            expression: "\(days) days from \(Self.dateFormatter.string(from: startDate))",
            result: numericDate,
            resultText: Self.dateFormatter.string(from: newDate),
            stackSnapshot: stack
        )
    }

    @discardableResult
    func calculateBondPrice(
        settlement: Date,
        maturity: Date,
        couponRatePercent: Double,
        yieldPercent: Double,
        redemptionValue: Double = 100
    ) throws -> OperationResult {
        let price = try bondPrice(
            settlement: settlement,
            maturity: maturity,
            couponRatePercent: couponRatePercent,
            yieldPercent: yieldPercent,
            redemptionValue: redemptionValue
        )
        stack.append(price)
        return OperationResult(
            mode: mode,
            expression: "Bond price",
            result: price,
            resultText: mode.format(price),
            stackSnapshot: stack
        )
    }

    @discardableResult
    func calculateBondYield(
        settlement: Date,
        maturity: Date,
        couponRatePercent: Double,
        price: Double,
        redemptionValue: Double = 100
    ) throws -> OperationResult {
        let result = try bondYield(
            settlement: settlement,
            maturity: maturity,
            couponRatePercent: couponRatePercent,
            price: price,
            redemptionValue: redemptionValue
        )
        stack.append(result)
        return OperationResult(
            mode: mode,
            expression: "Bond yield",
            result: result,
            resultText: mode.format(result),
            stackSnapshot: stack
        )
    }

    @discardableResult
    func calculateNetPresentValue(ratePercent: Double) throws -> OperationResult {
        let result = try netPresentValue(ratePercent: ratePercent)
        stack.append(result)
        return OperationResult(
            mode: mode,
            expression: "NPV",
            result: result,
            resultText: mode.format(result),
            stackSnapshot: stack
        )
    }

    @discardableResult
    func calculateInternalRateOfReturn() throws -> OperationResult {
        let result = try internalRateOfReturn()
        stack.append(result)
        return OperationResult(
            mode: mode,
            expression: "IRR",
            result: result,
            resultText: mode.format(result),
            stackSnapshot: stack
        )
    }

    func calculateAmortization(periods: Int) throws -> AmortizationSummary {
        guard periods > 0 else { throw FinancialSolverError.invalidPeriods }
        guard
            let pv = financialRegisters[.presentValue],
            let pmt = financialRegisters[.payment],
            let ratePercent = financialRegisters[.interestRate]
        else {
            throw FinancialSolverError.missingInputs
        }

        let payment = abs(pmt)
        var balance = abs(pv)
        let rate = ratePercent / 100
        var totalInterest = 0.0
        var totalPrincipal = 0.0

        for period in 1...periods {
            let interest: Double
            if financialRegisters.paymentMode == .begin && period == 1 {
                interest = 0
            } else {
                interest = balance * rate
            }

            let principal = min(balance, max(0, payment - interest))
            balance = max(0, balance - principal)
            totalInterest += interest
            totalPrincipal += principal
        }

        return AmortizationSummary(
            periods: periods,
            principalPaid: totalPrincipal,
            interestPaid: totalInterest,
            remainingBalance: balance
        )
    }

    static func format(_ value: Double) -> String {
        RPNNumberFormatter.formatDecimal(value)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func encodedDate(_ date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return year * 10_000 + month * 100 + day
    }

    private func currentValueForStorage() throws -> Double {
        if isTyping {
            guard let value = mode.parse(inputBuffer) else {
                throw FinancialSolverError.invalidNumber
            }
            return value
        }

        guard let value = stack.last else {
            throw FinancialSolverError.enterValueFirst
        }
        return value
    }

    private func shouldStoreFinancialValue(for variable: FinancialVariable) -> Bool {
        if isTyping {
            return true
        }

        if financialRegisters.canSolve(variable) {
            return false
        }

        return stack.last != nil
    }

    private func finishFinancialStore(with value: Double) {
        if isTyping {
            stack.append(value)
            inputBuffer = "0"
            isTyping = false
        }
    }

    private func solveFinancialVariable(_ target: FinancialVariable) throws -> Double {
        guard financialRegisters.canSolve(target) else {
            throw FinancialSolverError.missingInputs
        }

        let requiredValues = FinancialVariable.allCases.reduce(into: [FinancialVariable: Double]()) { result, variable in
            if variable != target, let value = financialRegisters.value(for: variable) {
                result[variable] = value
            }
        }

        let n = requiredValues[.numberOfPeriods]
        let ratePercent = requiredValues[.interestRate]
        let presentValue = requiredValues[.presentValue]
        let payment = requiredValues[.payment]
        let futureValue = requiredValues[.futureValue]

        switch target {
        case .futureValue:
            return try solveFutureValue(
                periods: try unwrap(n),
                ratePercent: try unwrap(ratePercent),
                presentValue: try unwrap(presentValue),
                payment: try unwrap(payment)
            )
        case .presentValue:
            return try solvePresentValue(
                periods: try unwrap(n),
                ratePercent: try unwrap(ratePercent),
                payment: try unwrap(payment),
                futureValue: try unwrap(futureValue)
            )
        case .payment:
            return try solvePayment(
                periods: try unwrap(n),
                ratePercent: try unwrap(ratePercent),
                presentValue: try unwrap(presentValue),
                futureValue: try unwrap(futureValue)
            )
        case .numberOfPeriods:
            return try solveNumberOfPeriods(
                ratePercent: try unwrap(ratePercent),
                presentValue: try unwrap(presentValue),
                payment: try unwrap(payment),
                futureValue: try unwrap(futureValue)
            )
        case .interestRate:
            return try solveInterestRate(
                periods: try unwrap(n),
                presentValue: try unwrap(presentValue),
                payment: try unwrap(payment),
                futureValue: try unwrap(futureValue)
            )
        }
    }

    private func unwrap(_ value: Double?) throws -> Double {
        guard let value else { throw FinancialSolverError.missingInputs }
        return value
    }

    private func validatePeriods(_ periods: Double) throws {
        guard periods.isFinite, periods > 0 else {
            throw FinancialSolverError.invalidPeriods
        }
    }

    private func solveFutureValue(periods: Double, ratePercent: Double, presentValue: Double, payment: Double) throws -> Double {
        try validatePeriods(periods)
        let rate = ratePercent / 100
        return -futureValueExpression(periods: periods, rate: rate, presentValue: presentValue, payment: payment)
    }

    private func solvePresentValue(periods: Double, ratePercent: Double, payment: Double, futureValue: Double) throws -> Double {
        try validatePeriods(periods)
        let rate = ratePercent / 100

        if abs(rate) < 1e-12 {
            return -(futureValue + payment * periods)
        }

        let growth = pow(1 + rate, periods)
        let annuity = ((growth - 1) / rate) * paymentFactor(rate: rate)
        let value = -(futureValue + payment * annuity) / growth
        guard value.isFinite else { throw FinancialSolverError.invalidMath }
        return value
    }

    private func solvePayment(periods: Double, ratePercent: Double, presentValue: Double, futureValue: Double) throws -> Double {
        try validatePeriods(periods)
        let rate = ratePercent / 100

        if abs(rate) < 1e-12 {
            return -(futureValue + presentValue) / periods
        }

        let growth = pow(1 + rate, periods)
        let annuity = ((growth - 1) / rate) * paymentFactor(rate: rate)
        guard annuity != 0 else { throw FinancialSolverError.invalidMath }

        let value = -(futureValue + presentValue * growth) / annuity
        guard value.isFinite else { throw FinancialSolverError.invalidMath }
        return value
    }

    private func solveNumberOfPeriods(ratePercent: Double, presentValue: Double, payment: Double, futureValue: Double) throws -> Double {
        let rate = ratePercent / 100

        if abs(payment) < 1e-12 {
            if abs(rate) < 1e-12 {
                throw FinancialSolverError.invalidMath
            }
            let ratio = -futureValue / presentValue
            guard ratio > 0 else { throw FinancialSolverError.invalidMath }
            let periods = log(ratio) / log(1 + rate)
            guard periods.isFinite, periods > 0 else { throw FinancialSolverError.invalidMath }
            return periods
        }

        if abs(rate) < 1e-12 {
            let periods = -(futureValue + presentValue) / payment
            guard periods.isFinite, periods > 0 else { throw FinancialSolverError.invalidMath }
            return periods
        }

        let adjustedPayment = payment * paymentFactor(rate: rate)
        let numerator = adjustedPayment - futureValue * rate
        let denominator = adjustedPayment + presentValue * rate
        guard numerator > 0, denominator > 0 else {
            throw FinancialSolverError.invalidMath
        }

        let periods = log(numerator / denominator) / log(1 + rate)
        guard periods.isFinite, periods > 0 else { throw FinancialSolverError.invalidMath }
        return periods
    }

    private func solveInterestRate(periods: Double, presentValue: Double, payment: Double, futureValue: Double) throws -> Double {
        try validatePeriods(periods)

        let function: (Double) -> Double = { rate in
            self.futureValueExpression(periods: periods, rate: rate, presentValue: presentValue, payment: payment) + futureValue
        }

        var guess = 0.05
        for _ in 0..<40 {
            let value = function(guess)
            if abs(value) < 1e-10 {
                return guess * 100
            }

            let delta = max(1e-6, abs(guess) * 1e-5)
            let upper = guess + delta
            let lower = max(-0.999_999, guess - delta)
            let derivative = (function(upper) - function(lower)) / (upper - lower)
            guard derivative.isFinite, abs(derivative) > 1e-12 else { break }

            let next = guess - (value / derivative)
            guard next.isFinite, next > -0.999_999 else { break }
            guess = next
        }

        var previousRate = -0.99
        var previousValue = function(previousRate)

        let sampleRates = stride(from: -0.95, through: 10.0, by: 0.05).map { $0 }
        for rate in sampleRates {
            let currentValue = function(rate)
            if abs(currentValue) < 1e-8 {
                return rate * 100
            }

            if previousValue.sign != currentValue.sign {
                var lower = previousRate
                var upper = rate
                var lowerValue = previousValue

                for _ in 0..<80 {
                    let midpoint = (lower + upper) / 2
                    let midpointValue = function(midpoint)
                    if abs(midpointValue) < 1e-10 {
                        return midpoint * 100
                    }

                    if midpointValue.sign == lowerValue.sign {
                        lower = midpoint
                        lowerValue = midpointValue
                    } else {
                        upper = midpoint
                    }
                }

                return ((lower + upper) / 2) * 100
            }

            previousRate = rate
            previousValue = currentValue
        }

        throw FinancialSolverError.invalidRate
    }

    private func futureValueExpression(periods: Double, rate: Double, presentValue: Double, payment: Double) -> Double {
        if abs(rate) < 1e-12 {
            return presentValue + payment * periods
        }

        let growth = pow(1 + rate, periods)
        return presentValue * growth + payment * ((growth - 1) / rate) * paymentFactor(rate: rate)
    }

    private func paymentFactor(rate: Double) -> Double {
        financialRegisters.paymentMode == .begin ? (1 + rate) : 1
    }

    private func netPresentValue(ratePercent: Double) throws -> Double {
        let rate = ratePercent / 100
        guard rate > -1 else { throw FinancialSolverError.invalidRate }

        var result = financialRegisters.cashFlowInitialAmount
        var period = 1

        for entry in financialRegisters.cashFlowEntries {
            guard entry.count > 0 else { throw FinancialSolverError.invalidCashFlow }
            for _ in 0..<entry.count {
                result += entry.amount / pow(1 + rate, Double(period))
                period += 1
            }
        }

        return result
    }

    private func internalRateOfReturn() throws -> Double {
        guard !financialRegisters.cashFlowEntries.isEmpty else { throw FinancialSolverError.invalidCashFlow }

        let function: (Double) -> Double = { rate in
            var result = self.financialRegisters.cashFlowInitialAmount
            var period = 1
            for entry in self.financialRegisters.cashFlowEntries {
                for _ in 0..<entry.count {
                    result += entry.amount / pow(1 + rate, Double(period))
                    period += 1
                }
            }
            return result
        }

        var lower = -0.99
        var upper = 10.0
        var lowerValue = function(lower)
        let upperValue = function(upper)
        guard lowerValue.sign != upperValue.sign else { throw FinancialSolverError.invalidRate }

        for _ in 0..<120 {
            let midpoint = (lower + upper) / 2
            let midpointValue = function(midpoint)
            if abs(midpointValue) < 1e-10 {
                return midpoint * 100
            }
            if midpointValue.sign == lowerValue.sign {
                lower = midpoint
                lowerValue = midpointValue
            } else {
                upper = midpoint
            }
        }

        return ((lower + upper) / 2) * 100
    }

    private func bondPrice(
        settlement: Date,
        maturity: Date,
        couponRatePercent: Double,
        yieldPercent: Double,
        redemptionValue: Double
    ) throws -> Double {
        guard settlement < maturity, redemptionValue > 0 else { throw FinancialSolverError.invalidBondInput }
        let periods = try bondPeriods(settlement: settlement, maturity: maturity)
        let coupon = redemptionValue * (couponRatePercent / 100) / 2
        let yieldPerPeriod = yieldPercent / 100 / 2
        guard yieldPerPeriod > -1 else { throw FinancialSolverError.invalidBondInput }

        var price = 0.0
        for period in 1...periods {
            price += coupon / pow(1 + yieldPerPeriod, Double(period))
        }
        price += redemptionValue / pow(1 + yieldPerPeriod, Double(periods))
        return price
    }

    private func bondYield(
        settlement: Date,
        maturity: Date,
        couponRatePercent: Double,
        price: Double,
        redemptionValue: Double
    ) throws -> Double {
        guard price > 0 else { throw FinancialSolverError.invalidBondInput }
        let function: (Double) -> Double = { yieldPercent in
            (try? self.bondPrice(
                settlement: settlement,
                maturity: maturity,
                couponRatePercent: couponRatePercent,
                yieldPercent: yieldPercent,
                redemptionValue: redemptionValue
            )) ?? .nan - price
        }

        var lower = 0.0
        var upper = 100.0
        var lowerValue = function(lower)
        let upperValue = function(upper)
        guard lowerValue.isFinite, upperValue.isFinite, lowerValue.sign != upperValue.sign else {
            throw FinancialSolverError.invalidBondInput
        }

        for _ in 0..<120 {
            let midpoint = (lower + upper) / 2
            let midpointValue = function(midpoint)
            if abs(midpointValue) < 1e-10 {
                return midpoint
            }
            if midpointValue.sign == lowerValue.sign {
                lower = midpoint
                lowerValue = midpointValue
            } else {
                upper = midpoint
            }
        }

        return (lower + upper) / 2
    }

    private func bondPeriods(settlement: Date, maturity: Date) throws -> Int {
        let days = Calendar(identifier: .gregorian).dateComponents([.day], from: settlement, to: maturity).day ?? 0
        let halfYearDays = 365.0 / 2
        let periods = Int(ceil(Double(days) / halfYearDays))
        guard periods > 0 else { throw FinancialSolverError.invalidBondInput }
        return periods
    }
}

struct OperationResult {
    let mode: CalculatorMode
    let expression: String
    let result: Double
    let resultText: String
    let stackSnapshot: [Double]
}
