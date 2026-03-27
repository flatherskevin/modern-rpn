import XCTest

final class Modern_RPNUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testKeypadButtonsExist() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["mode-picker"].exists)
        XCTAssertTrue(app.buttons["⌫"].exists)
        XCTAssertTrue(app.buttons["AC"].exists)
        XCTAssertTrue(app.buttons["POP"].exists)
        XCTAssertTrue(app.buttons["X/Y"].exists)
        XCTAssertTrue(app.buttons["ENTER"].exists)
        XCTAssertTrue(app.buttons["+/−"].exists)
        XCTAssertTrue(app.buttons["÷"].exists)
        XCTAssertTrue(app.buttons["×"].exists)
        XCTAssertTrue(app.buttons["+"].exists)
    }

    @MainActor
    func testAdditionFlowUpdatesDisplay() {
        let app = XCUIApplication()
        app.launch()

        tap(app, sequence: ["2", "ENTER", "3", "ENTER", "+"])

        XCTAssertEqual(displayValue(in: app).label, "5")
    }

    @MainActor
    func testBackspaceAndClearAll() {
        let app = XCUIApplication()
        app.launch()

        tap(app, sequence: ["1", "2", "3", "⌫"])
        XCTAssertEqual(displayValue(in: app).label, "12")

        tap(app, sequence: ["AC"])
        XCTAssertEqual(displayValue(in: app).label, "0")
    }

    @MainActor
    func testModeSwitchShowsHexAndBinaryKeypads() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["mode-picker"].tap()
        app.buttons["Hex"].tap()

        XCTAssertTrue(app.buttons["A"].exists)
        XCTAssertTrue(app.buttons["F"].exists)
        XCTAssertFalse(app.buttons["."].exists)

        app.buttons["mode-picker"].tap()
        app.buttons["Binary"].tap()

        XCTAssertTrue(app.buttons["1"].exists)
        XCTAssertTrue(app.buttons["0"].exists)
        XCTAssertFalse(app.buttons["A"].exists)
        XCTAssertFalse(app.buttons["."].exists)
    }

    @MainActor
    func testHexAdditionFlowUpdatesDisplay() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["mode-picker"].tap()
        app.buttons["Hex"].tap()

        tap(app, sequence: ["A", "ENTER", "5", "ENTER", "+"])

        XCTAssertEqual(displayValue(in: app).label, "F")
    }

    @MainActor
    func testHistoryShowsAndClearsEntries() {
        let app = XCUIApplication()
        app.launch()

        tap(app, sequence: ["2", "ENTER", "3", "ENTER", "+"])

        app.buttons["menu-button"].tap()
        app.buttons["History"].tap()

        let expression = app.staticTexts["2 + 3"]
        XCTAssertTrue(expression.waitForExistence(timeout: 2))

        app.buttons["Clear"].tap()
        XCTAssertTrue(app.staticTexts["No history yet"].waitForExistence(timeout: 2))

        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["menu-button"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    private func tap(_ app: XCUIApplication, sequence: [String]) {
        for label in sequence {
            app.buttons[label].tap()
        }
    }

    private func displayValue(in app: XCUIApplication) -> XCUIElement {
        app.staticTexts["display-value"]
    }
}
