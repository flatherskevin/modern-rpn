import Foundation
import SwiftUI
import UIKit

enum LaunchPresentedSheet {
    case none
    case history
    case about
    case privacyPolicy
    case financialTools
}

enum ScreenshotScenario: String, CaseIterable {
    case standardModeDivision = "standard-mode-division"
    case hexModeColorConversion = "hex-mode-color-conversion"
    case binaryModeNumberConversion = "binary-mode-number-conversion"
    case historySheetRecentCalculations = "history-sheet-recent-calculations"
    case financialModeTvmWorkflow = "financial-mode-tvm-workflow"
    case financialToolsWorksheet = "financial-tools-worksheet"

    var definition: ScreenshotScenarioDefinition {
        switch self {
        case .standardModeDivision:
            return ScreenshotScenarioDefinition(
                session: CalculatorSession(
                    mode: .standard,
                    stack: [144],
                    inputBuffer: "12",
                    isTyping: true
                ),
                historyEntries: ScreenshotScenarioDefinition.demoHistoryEntries,
                historyFilter: .all,
                presentedSheet: .none
            )
        case .hexModeColorConversion:
            return ScreenshotScenarioDefinition(
                session: CalculatorSession(
                    mode: .hex,
                    stack: [255],
                    inputBuffer: "FFAA00",
                    isTyping: true
                ),
                historyEntries: ScreenshotScenarioDefinition.demoHistoryEntries,
                historyFilter: .all,
                presentedSheet: .none
            )
        case .binaryModeNumberConversion:
            return ScreenshotScenarioDefinition(
                session: CalculatorSession(
                    mode: .binary,
                    stack: [13_792],
                    inputBuffer: "1100111001000",
                    isTyping: true
                ),
                historyEntries: ScreenshotScenarioDefinition.demoHistoryEntries,
                historyFilter: .all,
                presentedSheet: .none
            )
        case .historySheetRecentCalculations:
            return ScreenshotScenarioDefinition(
                session: CalculatorSession(
                    mode: .standard,
                    stack: [42],
                    inputBuffer: "0",
                    isTyping: false
                ),
                historyEntries: ScreenshotScenarioDefinition.demoHistoryEntries,
                historyFilter: .all,
                presentedSheet: .history
            )
        case .financialModeTvmWorkflow:
            return ScreenshotScenarioDefinition(
                session: CalculatorSession(
                    mode: .financial,
                    stack: [12_500, -275, 60, 5.75],
                    inputBuffer: "8750",
                    isTyping: true,
                    financialRegisters: Self.demoFinancialRegisters
                ),
                historyEntries: ScreenshotScenarioDefinition.demoHistoryEntries,
                historyFilter: .all,
                presentedSheet: .none
            )
        case .financialToolsWorksheet:
            return ScreenshotScenarioDefinition(
                session: CalculatorSession(
                    mode: .financial,
                    stack: [24_000],
                    inputBuffer: "0",
                    isTyping: false,
                    financialRegisters: Self.demoFinancialRegisters
                ),
                historyEntries: ScreenshotScenarioDefinition.demoHistoryEntries,
                historyFilter: .financial,
                presentedSheet: .financialTools
            )
        }
    }

    private static var demoFinancialRegisters: FinancialRegisters {
        var registers = FinancialRegisters()
        registers.set(60, for: .numberOfPeriods)
        registers.set(5.75, for: .interestRate)
        registers.set(12_500, for: .presentValue)
        registers.set(-275, for: .payment)
        registers.set(8_750, for: .futureValue)
        registers.paymentMode = .begin
        registers.memoryRegisters = [
            0: 12_000,
            1: 5.75,
            2: 275
        ]
        registers.cashFlowInitialAmount = -10_000
        registers.cashFlowEntries = [
            CashFlowEntry(
                id: UUID(uuidString: "7A0C969D-9974-4AC3-89F4-6578C5D6B5D8") ?? UUID(),
                amount: 2_500,
                count: 2
            ),
            CashFlowEntry(
                id: UUID(uuidString: "9E5A0A12-6F17-4947-B1CB-D048A85E2A95") ?? UUID(),
                amount: 3_400,
                count: 3
            )
        ]
        return registers
    }
}

struct ScreenshotScenarioDefinition {
    let session: CalculatorSession
    let historyEntries: [HistoryEntry]
    let historyFilter: HistoryModeFilter
    let presentedSheet: LaunchPresentedSheet

    static let demoHistoryEntries: [HistoryEntry] = [
        HistoryEntry(
            id: UUID(uuidString: "C56A4180-65AA-42EC-A945-5FD21DEC0538") ?? UUID(),
            mode: .standard,
            expression: "144 / 12",
            result: 12,
            resultText: "12",
            timestamp: Date(timeIntervalSince1970: 1_715_884_000),
            stackSnapshot: [12]
        ),
        HistoryEntry(
            id: UUID(uuidString: "16FD2706-8BAF-433B-82EB-8C7FADA847DA") ?? UUID(),
            mode: .hex,
            expression: "FF00 + AA",
            result: 65_450,
            resultText: "FFAA",
            timestamp: Date(timeIntervalSince1970: 1_715_880_400),
            stackSnapshot: [65_450]
        ),
        HistoryEntry(
            id: UUID(uuidString: "886313E1-3B8A-5372-9B90-0C9AEE199E5D") ?? UUID(),
            mode: .binary,
            expression: "101010 + 1111",
            result: 57,
            resultText: "111001",
            timestamp: Date(timeIntervalSince1970: 1_715_876_800),
            stackSnapshot: [57]
        ),
        HistoryEntry(
            id: UUID(uuidString: "0E984725-C51C-4BF4-9960-E1C80E27ABA0") ?? UUID(),
            mode: .financial,
            expression: "FV",
            result: 8_750,
            resultText: "8,750",
            timestamp: Date(timeIntervalSince1970: 1_715_873_200),
            stackSnapshot: [8_750]
        )
    ]
}

struct AppLaunchConfiguration {
    static let screenshotScenarioArgument = "-modern-rpn-screenshot-scenario"

    let userDefaults: UserDefaults?
    let seededSession: CalculatorSession?
    let seededHistoryEntries: [HistoryEntry]?
    let seededHistoryFilter: HistoryModeFilter?
    let presentedSheet: LaunchPresentedSheet

    static let currentProcess = AppLaunchConfiguration(processInfo: .processInfo)

    init(processInfo: ProcessInfo) {
        self.init(arguments: processInfo.arguments)
    }

    init(arguments: [String]) {
        guard let scenarioName = Self.value(for: Self.screenshotScenarioArgument, in: arguments),
              let scenario = ScreenshotScenario(rawValue: scenarioName) else {
            self = AppLaunchConfiguration()
            return
        }

        let suiteName = "comixmastertech.Modern-RPN.screenshots.\(scenario.rawValue)"
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.removePersistentDomain(forName: suiteName)

        let definition = scenario.definition
        self = AppLaunchConfiguration(
            userDefaults: defaults,
            seededSession: definition.session,
            seededHistoryEntries: definition.historyEntries,
            seededHistoryFilter: definition.historyFilter,
            presentedSheet: definition.presentedSheet
        )
    }

    init(
        userDefaults: UserDefaults? = nil,
        seededSession: CalculatorSession? = nil,
        seededHistoryEntries: [HistoryEntry]? = nil,
        seededHistoryFilter: HistoryModeFilter? = nil,
        presentedSheet: LaunchPresentedSheet = .none
    ) {
        self.userDefaults = userDefaults
        self.seededSession = seededSession
        self.seededHistoryEntries = seededHistoryEntries
        self.seededHistoryFilter = seededHistoryFilter
        self.presentedSheet = presentedSheet
    }

    private static func value(for argument: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: argument),
              arguments.indices.contains(index + 1) else {
            return nil
        }

        return arguments[index + 1]
    }
}

@main
struct Modern_RPNApp: App {
    @UIApplicationDelegateAdaptor(OrientationLockingAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(launchConfiguration: .currentProcess)
        }
    }
}

final class OrientationLockingAppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationCoordinator.shared.supportedOrientations
    }
}
