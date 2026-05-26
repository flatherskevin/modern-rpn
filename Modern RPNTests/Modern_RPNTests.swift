import XCTest
@testable import Modern_RPN

final class RPNCalculatorTests: XCTestCase {
    func testCompactHexLayoutShrinksButtonsForSEHeight() {
        let metrics = CalculatorLayoutMetrics.make(screenSize: CGSize(width: 375, height: 667), safeAreaBottom: 0, rowCount: 7)

        XCTAssertEqual(metrics.buttonHeight, 57)
        XCTAssertEqual(metrics.buttonSpacing, 4)
        XCTAssertEqual(metrics.displayFontSize, 64)
        XCTAssertTrue(metrics.prefersScrollFallback)
    }

    func testStandardSELayoutFitsWithoutScrollFallback() {
        let standardMetrics = CalculatorLayoutMetrics.make(screenSize: CGSize(width: 375, height: 667), safeAreaBottom: 0, rowCount: 6)
        let hexMetrics = CalculatorLayoutMetrics.make(screenSize: CGSize(width: 375, height: 667), safeAreaBottom: 0, rowCount: 7)

        XCTAssertFalse(standardMetrics.prefersScrollFallback)
        XCTAssertTrue(hexMetrics.prefersScrollFallback)
        XCTAssertEqual(standardMetrics.buttonHeight, 60)
        XCTAssertEqual(standardMetrics.displayFontSize, 64)
        XCTAssertEqual(hexMetrics.buttonHeight, 57)
    }

    func testInitialState() {
        let calculator = RPNCalculator()

        XCTAssertEqual(calculator.displayText, "0")
        XCTAssertEqual(calculator.stack, [])
        XCTAssertEqual(calculator.stackLines, ["T:", "Z:", "Y:", "X:"])
        XCTAssertFalse(calculator.isTyping)
        XCTAssertNil(calculator.errorMessage)
    }

    func testTapDigitStartsAndAppendsInput() {
        let calculator = RPNCalculator()

        calculator.tapDigit("0")
        calculator.tapDigit("5")
        calculator.tapDigit("2")

        XCTAssertTrue(calculator.isTyping)
        XCTAssertEqual(calculator.inputBuffer, "52")
        XCTAssertEqual(calculator.displayText, "52")
    }

    func testStandardModeTypingShowsGroupedDigits() {
        let calculator = RPNCalculator()

        calculator.tapDigit("1")
        calculator.tapDigit("2")
        calculator.tapDigit("3")
        calculator.tapDigit("4")

        XCTAssertEqual(calculator.inputBuffer, "1234")
        XCTAssertEqual(calculator.displayText, "1,234")
    }

    func testTapDigitIgnoresInvalidInput() {
        let calculator = RPNCalculator()

        calculator.tapDigit("12")
        calculator.tapDigit("a")

        XCTAssertEqual(calculator.inputBuffer, "0")
        XCTAssertFalse(calculator.isTyping)
    }

    func testTapDecimalStartsFractionAndDoesNotDuplicate() {
        let calculator = RPNCalculator()

        calculator.tapDecimal()
        calculator.tapDigit("3")
        calculator.tapDecimal()
        calculator.tapDigit("1")

        XCTAssertEqual(calculator.inputBuffer, "0.31")
    }

    func testHexModeAcceptsHexDigitsAndFormatsStack() {
        let calculator = RPNCalculator(mode: .hex)

        calculator.tapDigit("A")
        calculator.tapDigit("f")
        _ = calculator.enter()

        XCTAssertEqual(calculator.displayText, "AF")
        XCTAssertEqual(calculator.stackLines, ["T:", "Z:", "Y:", "X: AF"])
    }

    func testBinaryModeRejectsNonBinaryDigits() {
        let calculator = RPNCalculator(mode: .binary)

        calculator.tapDigit("1")
        calculator.tapDigit("2")

        XCTAssertEqual(calculator.inputBuffer, "1")
    }

    func testFinancialModeSupportsDecimalInput() {
        let calculator = RPNCalculator(mode: .financial)

        calculator.tapDigit("1")
        calculator.tapDecimal()
        calculator.tapDigit("5")

        XCTAssertEqual(calculator.displayText, "1.5")
    }

    func testModeDescriptorsDeclareExpectedOrientationsAndOrder() {
        XCTAssertEqual(CalculatorMode.orderedModes, [.standard, .binary, .hex, .financial])
        XCTAssertEqual(CalculatorMode.standard.orientation, .portrait)
        XCTAssertEqual(CalculatorMode.binary.orientation, .portrait)
        XCTAssertEqual(CalculatorMode.hex.orientation, .portrait)
        XCTAssertEqual(CalculatorMode.financial.orientation, .portrait)
    }

    func testFinancialModeSolvesFutureValue() {
        let calculator = RPNCalculator(mode: .financial)

        enter("2", into: calculator)
        _ = calculator.performFinancialAction(.numberOfPeriods)
        enter("5", into: calculator)
        _ = calculator.performFinancialAction(.interestRate)
        enter("-1000", into: calculator)
        _ = calculator.performFinancialAction(.presentValue)
        enter("0", into: calculator)
        _ = calculator.performFinancialAction(.payment)

        let outcome = calculator.performFinancialAction(.futureValue)

        XCTAssertEqual(outcome?.result, 1_102.5, accuracy: 0.000_001)
        XCTAssertEqual(calculator.displayText, "1,102.5")
        XCTAssertEqual(calculator.financialRegisters.value(for: .futureValue), 1_102.5, accuracy: 0.000_001)
    }

    func testFinancialQuickActionsSupportRollDownClearXAndExponentEntry() {
        let calculator = RPNCalculator(mode: .financial)

        push(1, onto: calculator)
        push(2, onto: calculator)
        push(3, onto: calculator)
        calculator.rollDown()

        XCTAssertEqual(calculator.stack, [3, 1, 2])

        calculator.clearX()
        XCTAssertEqual(calculator.stack, [3, 1])

        calculator.tapDigit("1")
        calculator.enterExponent()
        calculator.tapDigit("2")
        _ = calculator.enter()

        XCTAssertEqual(calculator.displayText, "100")
    }

    func testFinancialPaymentModeMemoryAndCashFlowCalculations() throws {
        let calculator = RPNCalculator(mode: .financial)

        enter("5", into: calculator)
        try calculator.storeMemory(index: 3)
        let recall = try calculator.recallMemory(index: 3)
        XCTAssertEqual(recall?.resultText, "5")

        calculator.setPaymentMode(.begin)
        XCTAssertEqual(calculator.paymentMode, .begin)

        calculator.setCashFlowInitialAmount(-1000)
        try calculator.addCashFlowEntry(amount: 300, count: 4)

        let npv = try calculator.calculateNetPresentValue(ratePercent: 8)
        XCTAssertEqual(npv.result, -6.361947986700329, accuracy: 0.000_001)

        calculator.clearAll()
        calculator.setCashFlowInitialAmount(-1000)
        try calculator.addCashFlowEntry(amount: 400, count: 4)
        let irr = try calculator.calculateInternalRateOfReturn()
        XCTAssertEqual(irr.result, 21.862_269_609_834_23, accuracy: 0.001)
    }

    func testFinancialDateBondAndAmortizationFunctions() throws {
        let calculator = RPNCalculator(mode: .financial)
        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!

        let days = try calculator.calculateDaysBetween(from: startDate, to: endDate)
        XCTAssertEqual(days.resultText, "30")

        let futureDate = try calculator.calculateDateByAdding(days: 30, to: startDate)
        XCTAssertEqual(futureDate.resultText, "2026-01-31")

        let settlement = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let maturity = calendar.date(from: DateComponents(year: 2031, month: 1, day: 1))!
        let price = try calculator.calculateBondPrice(
            settlement: settlement,
            maturity: maturity,
            couponRatePercent: 5,
            yieldPercent: 4
        )
        XCTAssertEqual(price.result, 104.49129250312109, accuracy: 0.000_001)

        let yield = try calculator.calculateBondYield(
            settlement: settlement,
            maturity: maturity,
            couponRatePercent: 5,
            price: price.result
        )
        XCTAssertEqual(yield.result, 4, accuracy: 0.001)

        enter("12", into: calculator)
        _ = calculator.performFinancialAction(.numberOfPeriods)
        enter("1", into: calculator)
        _ = calculator.performFinancialAction(.interestRate)
        enter("-1000", into: calculator)
        _ = calculator.performFinancialAction(.presentValue)
        enter("0", into: calculator)
        _ = calculator.performFinancialAction(.futureValue)
        enter("88.84878867834168", into: calculator)
        _ = calculator.performFinancialAction(.payment)

        let amortization = try calculator.calculateAmortization(periods: 3)
        XCTAssertEqual(amortization.principalPaid, 238.91971457424313, accuracy: 0.000_001)
        XCTAssertEqual(amortization.interestPaid, 27.62665146078192, accuracy: 0.000_001)
        XCTAssertEqual(amortization.remainingBalance, 761.0802854257569, accuracy: 0.000_001)
    }

    func testHexModeRejectsFractionalResultsThatDoNotFitTheRadixRules() {
        let calculator = RPNCalculator(mode: .hex)
        push(3, onto: calculator)
        push(2, onto: calculator)

        let outcome = calculator.perform(.divide)

        XCTAssertNil(outcome)
        XCTAssertEqual(calculator.errorMessage, "Value exceeds hex limit")
        XCTAssertEqual(calculator.displayText, "2")
        XCTAssertEqual(calculator.stack, [3, 2])
    }

    func testHexModeRejectsInputLongerThanVisibleValueBudget() {
        let calculator = RPNCalculator(mode: .hex)

        "12345678".forEach { calculator.tapDigit(String($0)) }

        XCTAssertEqual(calculator.displayText, "1234567")
        XCTAssertEqual(calculator.inputBuffer, "1234567")
    }

    func testBinaryModeRejectsOversizedOperationResults() {
        let calculator = RPNCalculator()
        push(32_767, onto: calculator)
        push(1, onto: calculator)
        calculator.setMode(.binary)

        let outcome = calculator.perform(.add)

        XCTAssertNil(outcome)
        XCTAssertEqual(calculator.errorMessage, "Value exceeds binary limit")
        XCTAssertEqual(calculator.stack, [32_767, 1])
    }

    func testToggleSignForTypingValue() {
        let calculator = RPNCalculator()

        calculator.tapDigit("4")
        calculator.toggleSign()
        XCTAssertEqual(calculator.displayText, "-4")

        calculator.toggleSign()
        XCTAssertEqual(calculator.displayText, "4")
    }

    func testToggleSignForTopOfStack() {
        let calculator = RPNCalculator()
        push(8, onto: calculator)

        calculator.toggleSign()

        XCTAssertEqual(calculator.stack, [-8])
        XCTAssertEqual(calculator.displayText, "-8")
    }

    func testToggleSignOnTypingZeroKeepsZero() {
        let calculator = RPNCalculator()

        calculator.tapDigit("0")
        calculator.toggleSign()

        XCTAssertEqual(calculator.displayText, "0")
    }

    func testEnterPushesTypingValueAndResetsInput() {
        let calculator = RPNCalculator()

        calculator.tapDigit("9")
        let entered = calculator.enter()

        XCTAssertEqual(entered, 9)
        XCTAssertEqual(calculator.stack, [9])
        XCTAssertFalse(calculator.isTyping)
        XCTAssertEqual(calculator.inputBuffer, "0")
    }

    func testEnterDuplicatesTopWhenNotTyping() {
        let calculator = RPNCalculator()
        push(7, onto: calculator)

        let entered = calculator.enter()

        XCTAssertEqual(entered, 7)
        XCTAssertEqual(calculator.stack, [7, 7])
    }

    func testEnterOnEmptyStackReturnsNil() {
        let calculator = RPNCalculator()

        XCTAssertNil(calculator.enter())
        XCTAssertEqual(calculator.stack, [])
    }

    func testDropDuringTypingCancelsInput() {
        let calculator = RPNCalculator()

        calculator.tapDigit("4")
        calculator.drop()

        XCTAssertFalse(calculator.isTyping)
        XCTAssertEqual(calculator.inputBuffer, "0")
        XCTAssertEqual(calculator.displayText, "0")
    }

    func testDropRemovesTopOfStack() {
        let calculator = RPNCalculator()
        push(3, onto: calculator)
        push(6, onto: calculator)

        calculator.drop()

        XCTAssertEqual(calculator.stack, [3])
    }

    func testBackspaceRemovesSingleCharacterWhileTyping() {
        let calculator = RPNCalculator()

        calculator.tapDigit("1")
        calculator.tapDigit("2")
        calculator.tapDigit("3")
        calculator.backspace()

        XCTAssertTrue(calculator.isTyping)
        XCTAssertEqual(calculator.displayText, "12")
    }

    func testBackspaceClearsTypingStateWhenValueIsFullyDeleted() {
        let calculator = RPNCalculator()

        calculator.tapDigit("7")
        calculator.backspace()

        XCTAssertFalse(calculator.isTyping)
        XCTAssertEqual(calculator.displayText, "0")
    }

    func testBackspaceDoesNothingWhenNotTyping() {
        let calculator = RPNCalculator()
        push(9, onto: calculator)

        calculator.backspace()

        XCTAssertEqual(calculator.stack, [9])
        XCTAssertEqual(calculator.displayText, "9")
    }

    func testSwapExchangesTopTwoValues() {
        let calculator = RPNCalculator()
        push(4, onto: calculator)
        push(9, onto: calculator)

        calculator.swap()

        XCTAssertEqual(calculator.stack, [9, 4])
    }

    func testSwapWhileTypingCommitsValueFirst() {
        let calculator = RPNCalculator()
        push(2, onto: calculator)
        calculator.tapDigit("5")

        calculator.swap()

        XCTAssertEqual(calculator.stack, [5, 2])
    }

    func testPerformAllBinaryOperations() {
        let calculator = RPNCalculator()

        push(8, onto: calculator)
        push(2, onto: calculator)
        XCTAssertEqual(calculator.perform(.add)?.result, 10)

        push(3, onto: calculator)
        XCTAssertEqual(calculator.perform(.subtract)?.result, 7)

        push(4, onto: calculator)
        XCTAssertEqual(calculator.perform(.multiply)?.result, 28)

        push(7, onto: calculator)
        XCTAssertEqual(calculator.perform(.divide)?.result, 4)
        XCTAssertEqual(calculator.stack, [4])
    }

    func testPerformNeedsTwoValues() {
        let calculator = RPNCalculator()
        push(3, onto: calculator)

        let outcome = calculator.perform(.add)

        XCTAssertNil(outcome)
        XCTAssertEqual(calculator.errorMessage, "Need two values")
        XCTAssertEqual(calculator.stack, [3])
    }

    func testPerformWhileTypingCommitsInput() {
        let calculator = RPNCalculator()
        push(4, onto: calculator)
        calculator.tapDigit("6")

        let outcome = calculator.perform(.add)

        XCTAssertEqual(outcome?.result, 10)
        XCTAssertEqual(calculator.stack, [10])
    }

    func testDivisionByZeroShowsErrorAndRestoresStack() {
        let calculator = RPNCalculator()
        push(8, onto: calculator)
        push(0, onto: calculator)

        let outcome = calculator.perform(.divide)

        XCTAssertNil(outcome)
        XCTAssertEqual(calculator.errorMessage, "Cannot divide by zero")
        XCTAssertEqual(calculator.stack, [8, 0])
    }

    func testClearAllResetsStateAndError() {
        let calculator = RPNCalculator()
        push(1, onto: calculator)
        let _ = calculator.perform(.add)

        calculator.tapDigit("2")
        calculator.clearAll()

        XCTAssertEqual(calculator.stack, [])
        XCTAssertEqual(calculator.inputBuffer, "0")
        XCTAssertFalse(calculator.isTyping)
        XCTAssertNil(calculator.errorMessage)
        XCTAssertEqual(calculator.displayText, "0")
    }

    func testStackLinesShowTopFourValues() {
        let calculator = RPNCalculator()
        [1, 2, 3, 4, 5].forEach { push(Double($0), onto: calculator) }

        XCTAssertEqual(calculator.stackLines, ["T: 2", "Z: 3", "Y: 4", "X: 5"])
    }

    func testFormatHandlesSpecialAndRoundedValues() {
        XCTAssertEqual(RPNCalculator.format(.infinity), "∞")
        XCTAssertEqual(RPNCalculator.format(-.infinity), "-∞")
        XCTAssertEqual(RPNCalculator.format(5.0), "5")
        XCTAssertEqual(RPNCalculator.format(1.25), "1.25")
        XCTAssertEqual(RPNCalculator.format(1234.0), "1,234")
        XCTAssertEqual(RPNCalculator.format(12345.67), "12,345.67")
        XCTAssertEqual(RPNCalculator.format(.nan), "NaN")
    }

    func testModeSwitchReformatsExistingStack() {
        let calculator = RPNCalculator()
        push(15, onto: calculator)

        calculator.setMode(.hex)

        XCTAssertEqual(calculator.displayText, "F")
        XCTAssertEqual(calculator.stackLines, ["T:", "Z:", "Y:", "X: F"])
    }

    private func push(_ value: Double, onto calculator: RPNCalculator) {
        let formatted = RPNCalculator.format(value)
        let isNegative = formatted.hasPrefix("-")
        for char in formatted {
            switch char {
            case "-":
                continue
            case ".":
                calculator.tapDecimal()
            case ",":
                continue
            default:
                calculator.tapDigit(String(char))
            }
        }
        if isNegative {
            calculator.toggleSign()
        }
        _ = calculator.enter()
    }
}

@MainActor
final class HistoryStoreTests: XCTestCase {
    func testHistoryEntryDisplaysGroupedStandardValues() {
        let entry = HistoryEntry(
            mode: .standard,
            expression: "1234 + 5678",
            result: 6912,
            resultText: "6912",
            stackSnapshot: [6912]
        )

        XCTAssertEqual(entry.displayExpression, "1,234 + 5,678")
        XCTAssertEqual(entry.displayResultText, "6,912")
    }

    func testInitialStoreIsEmpty() {
        let defaults = makeDefaults()
        let store = makeStore(defaults: defaults)

        XCTAssertEqual(store.entries.count, 0)
    }

    func testAddInsertsNewestFirst() {
        let defaults = makeDefaults()
        let store = makeStore(defaults: defaults)

        store.add(HistoryEntry(mode: .standard, expression: "1 + 1", result: 2, resultText: "2", stackSnapshot: [2]))
        store.add(HistoryEntry(mode: .hex, expression: "2 + 2", result: 4, resultText: "4", stackSnapshot: [4]))

        XCTAssertEqual(store.entries.map(\.expression), ["2 + 2", "1 + 1"])
        XCTAssertEqual(store.entries.first?.mode, .hex)
    }

    func testMaxEntriesIsEnforced() {
        let defaults = makeDefaults()
        let store = makeStore(defaults: defaults, maxEntries: 2)

        store.add(HistoryEntry(mode: .standard, expression: "1", result: 1, resultText: "1", stackSnapshot: [1]))
        store.add(HistoryEntry(mode: .hex, expression: "2", result: 2, resultText: "2", stackSnapshot: [2]))
        store.add(HistoryEntry(mode: .binary, expression: "3", result: 3, resultText: "3", stackSnapshot: [3]))

        XCTAssertEqual(store.entries.count, 2)
        XCTAssertEqual(store.entries.map(\.expression), ["3", "2"])
    }

    func testPersistsAndReloadsEntries() {
        let defaults = makeDefaults()
        let key = uniqueKey()

        let store = HistoryStore(userDefaults: defaults, storageKey: key, maxEntries: 5)
        store.add(HistoryEntry(mode: .hex, expression: "1 + 1", result: 2, resultText: "2", stackSnapshot: [2]))

        let reloaded = HistoryStore(userDefaults: defaults, storageKey: key, maxEntries: 5)

        XCTAssertEqual(reloaded.entries.count, 1)
        XCTAssertEqual(reloaded.entries.first?.expression, "1 + 1")
        XCTAssertEqual(reloaded.entries.first?.result, 2)
        XCTAssertEqual(reloaded.entries.first?.displayResultText, "2")
        XCTAssertEqual(reloaded.entries.first?.mode, .hex)
    }

    func testClearRemovesInMemoryAndPersistedData() {
        let defaults = makeDefaults()
        let key = uniqueKey()

        let store = HistoryStore(userDefaults: defaults, storageKey: key, maxEntries: 5)
        store.add(HistoryEntry(mode: .standard, expression: "1", result: 1, resultText: "1", stackSnapshot: [1]))
        store.clear()

        XCTAssertEqual(store.entries.count, 0)

        let reloaded = HistoryStore(userDefaults: defaults, storageKey: key, maxEntries: 5)
        XCTAssertEqual(reloaded.entries.count, 0)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "ModernRPNTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        XCTAssertNotNil(defaults)
        return defaults!
    }

    private func makeStore(defaults: UserDefaults, maxEntries: Int = 5) -> HistoryStore {
        let key = uniqueKey()
        return HistoryStore(userDefaults: defaults, storageKey: key, maxEntries: maxEntries)
    }

    private func uniqueKey() -> String {
        "history-\(UUID().uuidString)"
    }
}

final class AppSessionStoreTests: XCTestCase {
    func testSessionPersistsAndReloads() {
        let defaults = makeDefaults()
        let store = AppSessionStore(
            userDefaults: defaults,
            sessionKey: "session-\(UUID().uuidString)",
            historyFilterKey: "filter-\(UUID().uuidString)"
        )

        let session = CalculatorSession(
            mode: .hex,
            stack: [10, 15],
            inputBuffer: "A",
            isTyping: true
        )
        store.saveSession(session)

        XCTAssertEqual(store.loadSession(), session)
    }

    func testHistoryFilterPersistsAndReloads() {
        let defaults = makeDefaults()
        let store = AppSessionStore(
            userDefaults: defaults,
            sessionKey: "session-\(UUID().uuidString)",
            historyFilterKey: "filter-\(UUID().uuidString)"
        )

        store.saveHistoryFilter(.binary)

        XCTAssertEqual(store.loadHistoryFilter(), .binary)
    }

    func testFinancialSessionPersistsAndReloadsRegisters() {
        let defaults = makeDefaults()
        let store = AppSessionStore(
            userDefaults: defaults,
            sessionKey: "session-\(UUID().uuidString)",
            historyFilterKey: "filter-\(UUID().uuidString)"
        )

        var registers = FinancialRegisters()
        registers.set(12, for: .numberOfPeriods)
        registers.set(5, for: .interestRate)
        let session = CalculatorSession(
            mode: .financial,
            stack: [42],
            inputBuffer: "0",
            isTyping: false,
            financialRegisters: registers
        )

        store.saveSession(session)

        XCTAssertEqual(store.loadSession(), session)
    }

    func testFinancialRegistersDecodeFromOlderSessionPayload() throws {
        let json = """
        {
          "mode": "financial",
          "stack": [42],
          "inputBuffer": "0",
          "isTyping": false,
          "financialRegisters": {
            "values": {
              "numberOfPeriods": 12,
              "interestRate": 5
            }
          }
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder().decode(CalculatorSession.self, from: json)

        XCTAssertEqual(session.financialRegisters.value(for: .numberOfPeriods), 12)
        XCTAssertEqual(session.financialRegisters.value(for: .interestRate), 5)
        XCTAssertEqual(session.financialRegisters.paymentMode, .end)
        XCTAssertTrue(session.financialRegisters.memoryRegisters.isEmpty)
        XCTAssertEqual(session.financialRegisters.cashFlowInitialAmount, 0)
        XCTAssertTrue(session.financialRegisters.cashFlowEntries.isEmpty)
    }

    func testMissingFinancialRegistersDecodeToDefaultSessionState() throws {
        let json = """
        {
          "mode": "standard",
          "stack": [42],
          "inputBuffer": "0",
          "isTyping": false
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder().decode(CalculatorSession.self, from: json)

        XCTAssertEqual(session.financialRegisters, FinancialRegisters())
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "ModernRPNTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        XCTAssertNotNil(defaults)
        return defaults!
    }
}

@MainActor
final class CalculatorViewModelTests: XCTestCase {
    func testInitialState() {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.mode, .standard)
        XCTAssertEqual(viewModel.displayText, "0")
        XCTAssertEqual(viewModel.stackLines, ["T:", "Z:", "Y:", "X:"])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.historyFilter, .all)
    }

    func testModeCanBeChanged() {
        let viewModel = makeViewModel()

        viewModel.setMode(.hex)

        XCTAssertEqual(viewModel.mode, .hex)
    }

    func testFinancialModeCanBeChanged() {
        let viewModel = makeViewModel()

        viewModel.setMode(.financial)

        XCTAssertEqual(viewModel.mode, .financial)
    }

    func testModeSwitchUpdatesFormatting() {
        let viewModel = makeViewModel()

        viewModel.tapDigit("1")
        viewModel.tapDigit("5")
        viewModel.enter()
        viewModel.setMode(.hex)

        XCTAssertEqual(viewModel.displayText, "F")
        XCTAssertEqual(viewModel.stackLines, ["T:", "Z:", "Y:", "X: F"])
    }

    func testSuccessfulOperationUpdatesDisplayStackAndHistory() {
        let viewModel = makeViewModel()

        viewModel.tapDigit("2")
        viewModel.enter()
        viewModel.tapDigit("3")
        viewModel.enter()
        viewModel.perform(.add)

        XCTAssertEqual(viewModel.displayText, "5")
        XCTAssertEqual(viewModel.stackLines, ["T:", "Z:", "Y:", "X: 5"])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.historyStore.entries.count, 1)
        XCTAssertEqual(viewModel.historyStore.entries.first?.expression, "2 + 3")
    }

    func testFailedOperationSetsErrorAndDoesNotAddHistory() {
        let viewModel = makeViewModel()

        viewModel.tapDigit("1")
        viewModel.enter()
        viewModel.perform(.add)

        XCTAssertEqual(viewModel.errorMessage, "Need two values")
        XCTAssertEqual(viewModel.historyStore.entries.count, 0)
    }

    func testDropSwapAndClearAffectState() {
        let viewModel = makeViewModel()

        viewModel.tapDigit("4")
        viewModel.enter()
        viewModel.tapDigit("9")
        viewModel.enter()
        viewModel.swap()

        XCTAssertEqual(viewModel.stackLines, ["T:", "Z:", "Y: 9", "X: 4"])

        viewModel.drop()
        XCTAssertEqual(viewModel.stackLines, ["T:", "Z:", "Y:", "X: 9"])

        viewModel.clearAll()
        XCTAssertEqual(viewModel.displayText, "0")
        XCTAssertEqual(viewModel.stackLines, ["T:", "Z:", "Y:", "X:"])
    }

    func testBackspaceUpdatesDisplayWhenTyping() {
        let viewModel = makeViewModel()

        viewModel.tapDigit("1")
        viewModel.tapDigit("2")
        viewModel.backspace()

        XCTAssertEqual(viewModel.displayText, "1")
    }

    func testHexModeOperationUsesHexHistoryFormatting() {
        let viewModel = makeViewModel()
        viewModel.setMode(.hex)

        viewModel.tapDigit("A")
        viewModel.enter()
        viewModel.tapDigit("5")
        viewModel.enter()
        viewModel.perform(.add)

        XCTAssertEqual(viewModel.displayText, "F")
        XCTAssertEqual(viewModel.historyStore.entries.first?.expression, "A + 5")
        XCTAssertEqual(viewModel.historyStore.entries.first?.displayResultText, "F")
        XCTAssertEqual(viewModel.historyStore.entries.first?.mode, .hex)
    }

    func testHistoryFilterCanBeChanged() {
        let viewModel = makeViewModel()

        viewModel.setHistoryFilter(.hex)

        XCTAssertEqual(viewModel.historyFilter, .hex)
    }

    func testFinancialActionUpdatesRegistersAndHistory() {
        let viewModel = makeViewModel()
        viewModel.setMode(.financial)

        enter("2", into: viewModel)
        viewModel.performFinancialAction(.numberOfPeriods)
        enter("5", into: viewModel)
        viewModel.performFinancialAction(.interestRate)
        enter("-1000", into: viewModel)
        viewModel.performFinancialAction(.presentValue)
        enter("0", into: viewModel)
        viewModel.performFinancialAction(.payment)
        viewModel.performFinancialAction(.futureValue)

        XCTAssertEqual(viewModel.displayText, "1102.5")
        XCTAssertEqual(viewModel.financialRegisterLines.last, "FV: 1102.5")
        XCTAssertEqual(viewModel.historyStore.entries.first?.expression, "Solve FV")
        XCTAssertEqual(viewModel.historyStore.entries.first?.mode, .financial)
    }

    func testFinancialToolsActionsUpdatePublishedState() {
        let viewModel = makeViewModel()
        viewModel.setMode(.financial)

        enter("9", into: viewModel)
        viewModel.storeMemory(index: 2)
        XCTAssertEqual(viewModel.memoryRegisters[2], 9)

        viewModel.recallMemory(index: 2)
        XCTAssertEqual(viewModel.displayText, "9")

        viewModel.setPaymentMode(.begin)
        XCTAssertEqual(viewModel.paymentMode, .begin)

        viewModel.setCashFlowInitialAmount(-1000)
        viewModel.addCashFlowEntry(amount: 300, count: 2)
        XCTAssertEqual(viewModel.cashFlowInitialAmount, -1000)
        XCTAssertEqual(viewModel.cashFlowEntries.count, 1)
    }

    func testViewModelRestoresPersistedSessionAndFilter() {
        let suiteName = "ModernRPNTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        XCTAssertNotNil(defaults)

        let historyStore = HistoryStore(
            userDefaults: defaults!,
            storageKey: "history-\(UUID().uuidString)",
            maxEntries: 25
        )
        let sessionStore = AppSessionStore(
            userDefaults: defaults!,
            sessionKey: "session-\(UUID().uuidString)",
            historyFilterKey: "filter-\(UUID().uuidString)"
        )

        sessionStore.saveSession(
            CalculatorSession(mode: .hex, stack: [15], inputBuffer: "A", isTyping: true)
        )
        sessionStore.saveHistoryFilter(.hex)

        let viewModel = CalculatorViewModel(
            historyStore: historyStore,
            sessionStore: sessionStore,
            launchConfiguration: AppLaunchConfiguration()
        )

        XCTAssertEqual(viewModel.mode, .hex)
        XCTAssertEqual(viewModel.displayText, "A")
        XCTAssertEqual(viewModel.historyFilter, .hex)
    }

    private func makeViewModel() -> CalculatorViewModel {
        let suiteName = "ModernRPNTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        XCTAssertNotNil(defaults)

        let store = HistoryStore(
            userDefaults: defaults!,
            storageKey: "history-\(UUID().uuidString)",
            maxEntries: 25
        )

        let sessionStore = AppSessionStore(
            userDefaults: defaults!,
            sessionKey: "session-\(UUID().uuidString)",
            historyFilterKey: "filter-\(UUID().uuidString)"
        )

        return CalculatorViewModel(
            historyStore: store,
            sessionStore: sessionStore,
            launchConfiguration: AppLaunchConfiguration()
        )
    }

    private func enter(_ value: String, into viewModel: CalculatorViewModel) {
        for char in value {
            switch char {
            case "-":
                viewModel.toggleSign()
            case ".":
                viewModel.tapDecimal()
            default:
                viewModel.tapDigit(String(char))
            }
        }
    }
}

final class AppLaunchConfigurationTests: XCTestCase {
    func testDefaultsWhenNoScreenshotScenarioArgumentIsPresent() {
        let configuration = AppLaunchConfiguration(arguments: ["Modern RPN"])

        XCTAssertNil(configuration.userDefaults)
        XCTAssertNil(configuration.seededSession)
        XCTAssertNil(configuration.seededHistoryEntries)
        XCTAssertNil(configuration.seededHistoryFilter)
        if case .none = configuration.presentedSheet {
        } else {
            XCTFail("Expected no sheet to be pre-presented")
        }
    }

    func testScreenshotScenarioSeedsFinancialWorksheetState() {
        let configuration = AppLaunchConfiguration(
            arguments: [
                "Modern RPN",
                AppLaunchConfiguration.screenshotScenarioArgument,
                ScreenshotScenario.financialToolsWorksheet.rawValue
            ]
        )

        XCTAssertEqual(configuration.seededSession?.mode, .financial)
        XCTAssertEqual(configuration.seededHistoryFilter, .financial)
        if case .financialTools = configuration.presentedSheet {
        } else {
            XCTFail("Expected financial tools sheet to be pre-presented")
        }
        XCTAssertEqual(configuration.seededSession?.financialRegisters.paymentMode, .begin)
        XCTAssertEqual(configuration.seededHistoryEntries?.count, 4)
    }
}

private extension RPNCalculatorTests {
    func enter(_ value: String, into calculator: RPNCalculator) {
        let isNegative = value.hasPrefix("-")
        for char in value {
            switch char {
            case "-":
                continue
            case ".":
                calculator.tapDecimal()
            default:
                calculator.tapDigit(String(char))
            }
        }
        if isNegative {
            calculator.toggleSign()
        }
    }
}
