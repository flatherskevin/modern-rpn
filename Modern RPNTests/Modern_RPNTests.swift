import XCTest
@testable import Modern_RPN

final class RPNCalculatorTests: XCTestCase {
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

    func testHexModeShowsFractionalResultsInDecimal() {
        let calculator = RPNCalculator(mode: .hex)
        push(3, onto: calculator)
        push(2, onto: calculator)

        let outcome = calculator.perform(.divide)

        XCTAssertEqual(outcome?.resultText, "1.5")
        XCTAssertEqual(calculator.displayText, "1.5")
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
        for char in formatted {
            switch char {
            case "-":
                calculator.toggleSign()
            case ".":
                calculator.tapDecimal()
            default:
                calculator.tapDigit(String(char))
            }
        }
        _ = calculator.enter()
    }
}

@MainActor
final class HistoryStoreTests: XCTestCase {
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

        let viewModel = CalculatorViewModel(historyStore: historyStore, sessionStore: sessionStore)

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

        return CalculatorViewModel(historyStore: store, sessionStore: sessionStore)
    }
}
