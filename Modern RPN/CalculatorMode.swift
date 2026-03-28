import Foundation
import SwiftUI
import UIKit

struct ModeTheme {
    let accentBackground: Color
    let accentBorder: Color
    let accentText: Color
}

enum CalculatorOrientationPolicy {
    case portrait
    case landscape

    var supportedOrientations: UIInterfaceOrientationMask {
        switch self {
        case .portrait:
            return .portrait
        case .landscape:
            return .landscape
        }
    }

    var targetOrientation: UIInterfaceOrientation {
        switch self {
        case .portrait:
            return .portrait
        case .landscape:
            return .landscapeRight
        }
    }
}

enum CalculatorLayoutStyle {
    case standard
    case financialLandscape
}

enum CalculatorUtilityAction: String, Hashable {
    case backspace
    case clearAll
    case drop
    case swap
    case toggleSign
}

enum CalculatorButtonRole: Hashable {
    case utility(CalculatorUtilityAction)
    case digit(String)
    case decimal
    case operation(RPNCalculator.BinaryOperation)
    case financial(FinancialVariable)
    case enter
    case spacer(String)
}

struct CalculatorButtonSpec: Identifiable, Hashable {
    let role: CalculatorButtonRole
    let label: String
    let span: Int

    init(role: CalculatorButtonRole, label: String, span: Int = 1) {
        self.role = role
        self.label = label
        self.span = span
    }

    var id: String {
        "\(label)-\(span)-\(String(describing: role))"
    }
}

struct CalculatorModeDescriptor {
    let mode: CalculatorMode
    let order: Int
    let title: String
    let supportsDecimalInput: Bool
    let theme: ModeTheme
    let orientation: CalculatorOrientationPolicy
    let layoutStyle: CalculatorLayoutStyle
    let keypadColumns: Int
    let keypadRows: [[CalculatorButtonSpec]]
}

enum CalculatorMode: String, CaseIterable, Codable, Identifiable {
    case standard
    case binary
    case hex
    case financial

    var id: String { rawValue }

    var title: String {
        descriptor.title
    }

    var order: Int {
        descriptor.order
    }

    var supportsDecimalInput: Bool {
        descriptor.supportsDecimalInput
    }

    var theme: ModeTheme {
        descriptor.theme
    }

    var layoutStyle: CalculatorLayoutStyle {
        descriptor.layoutStyle
    }

    var orientation: CalculatorOrientationPolicy {
        descriptor.orientation
    }

    var keypadColumns: Int {
        descriptor.keypadColumns
    }

    var keypadRows: [[CalculatorButtonSpec]] {
        descriptor.keypadRows
    }

    var descriptor: CalculatorModeDescriptor {
        Self.descriptorMap[self]!
    }

    static var orderedModes: [CalculatorMode] {
        validatedDescriptors.map(\.mode)
    }

    private static let descriptorMap: [CalculatorMode: CalculatorModeDescriptor] = {
        Dictionary(uniqueKeysWithValues: validatedDescriptors.map { ($0.mode, $0) })
    }()

    private static let validatedDescriptors: [CalculatorModeDescriptor] = {
        let descriptors = makeDescriptors()
        let orders = descriptors.map(\.order)
        precondition(Set(orders).count == orders.count, "Calculator mode order values must be unique")
        let modes = descriptors.map(\.mode)
        precondition(Set(modes).count == modes.count, "Calculator mode descriptors must be unique")
        return descriptors.sorted { $0.order < $1.order }
    }()

    private static func makeDescriptors() -> [CalculatorModeDescriptor] {
        [
            CalculatorModeDescriptor(
                mode: .standard,
                order: 0,
                title: "Standard",
                supportsDecimalInput: true,
                theme: ModeTheme(
                    accentBackground: Color.white.opacity(0.08),
                    accentBorder: Color.white.opacity(0.10),
                    accentText: Color.white.opacity(0.94)
                ),
                orientation: .portrait,
                layoutStyle: .standard,
                keypadColumns: 4,
                keypadRows: makeKeypadRows([
                    utilityRow,
                    [.digit("7"), .digit("8"), .digit("9"), .operation(.divide)],
                    [.digit("4"), .digit("5"), .digit("6"), .operation(.multiply)],
                    [.digit("1"), .digit("2"), .digit("3"), .operation(.subtract)],
                    [.utility(.toggleSign), .digit("0"), .decimal, .operation(.add)],
                    [.enter(span: 4)]
                ])
            ),
            CalculatorModeDescriptor(
                mode: .binary,
                order: 1,
                title: "Binary",
                supportsDecimalInput: false,
                theme: ModeTheme(
                    accentBackground: Color(red: 0.13, green: 0.27, blue: 0.18),
                    accentBorder: Color(red: 0.24, green: 0.53, blue: 0.33),
                    accentText: Color(red: 0.82, green: 0.97, blue: 0.86)
                ),
                orientation: .portrait,
                layoutStyle: .standard,
                keypadColumns: 4,
                keypadRows: makeKeypadRows([
                    utilityRow,
                    [.digit("1"), .digit("0"), .utility(.toggleSign), .spacer("binary-gap")],
                    [.operation(.add), .operation(.subtract), .operation(.multiply), .operation(.divide)],
                    [.enter(span: 4)]
                ])
            ),
            CalculatorModeDescriptor(
                mode: .hex,
                order: 2,
                title: "Hex",
                supportsDecimalInput: false,
                theme: ModeTheme(
                    accentBackground: Color(red: 0.16, green: 0.24, blue: 0.35),
                    accentBorder: Color(red: 0.28, green: 0.43, blue: 0.63),
                    accentText: Color(red: 0.82, green: 0.92, blue: 1.0)
                ),
                orientation: .portrait,
                layoutStyle: .standard,
                keypadColumns: 4,
                keypadRows: makeKeypadRows([
                    utilityRow,
                    [.digit("A"), .digit("B"), .digit("C"), .operation(.divide)],
                    [.digit("D"), .digit("E"), .digit("F"), .operation(.multiply)],
                    [.digit("7"), .digit("8"), .digit("9"), .operation(.subtract)],
                    [.digit("4"), .digit("5"), .digit("6"), .operation(.add)],
                    [.digit("1"), .digit("2"), .digit("3"), .digit("0")],
                    [.utility(.toggleSign), .enter(span: 3)]
                ])
            ),
            CalculatorModeDescriptor(
                mode: .financial,
                order: 3,
                title: "Financial",
                supportsDecimalInput: true,
                theme: ModeTheme(
                    accentBackground: Color(red: 0.38, green: 0.21, blue: 0.09),
                    accentBorder: Color(red: 0.79, green: 0.52, blue: 0.23),
                    accentText: Color(red: 0.98, green: 0.91, blue: 0.82)
                ),
                orientation: .portrait,
                layoutStyle: .standard,
                keypadColumns: 4,
                keypadRows: makeKeypadRows([
                    [.financial(.numberOfPeriods), .financial(.interestRate), .financial(.presentValue), .financial(.payment)],
                    [.financial(.futureValue), .utility(.clearAll, label: "AC"), .utility(.drop, label: "POP"), .utility(.swap, label: "x↔y")],
                    [.digit("7"), .digit("8"), .digit("9"), .operation(.divide)],
                    [.digit("4"), .digit("5"), .digit("6"), .operation(.multiply)],
                    [.digit("1"), .digit("2"), .digit("3"), .operation(.subtract)],
                    [.utility(.toggleSign, label: "CHS"), .digit("0"), .decimal, .operation(.add)],
                    [.enter(span: 4)]
                ])
            )
        ]
    }

    func normalizeDigit(_ digit: String) -> String? {
        guard digit.count == 1 else { return nil }

        let normalized = digit.uppercased()
        guard let character = normalized.first else { return nil }

        switch self {
        case .standard:
            return character.isNumber ? normalized : nil
        case .hex:
            return ("0123456789ABCDEF".contains(character)) ? normalized : nil
        case .binary:
            return ("01".contains(character)) ? normalized : nil
        case .financial:
            return character.isNumber ? normalized : nil
        }
    }

    func canAppend(to buffer: String) -> Bool {
        switch self {
        case .standard:
            return true
        case .hex:
            return isRadixBuffer(buffer, allowed: "0123456789ABCDEF")
        case .binary:
            return isRadixBuffer(buffer, allowed: "01")
        case .financial:
            return true
        }
    }

    func parse(_ text: String) -> Double? {
        switch self {
        case .standard:
            return Double(text)
        case .hex:
            return parseRadix(text, radix: 16) ?? Double(text)
        case .binary:
            return parseRadix(text, radix: 2) ?? Double(text)
        case .financial:
            return Double(text)
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .standard:
            return RPNNumberFormatter.formatDecimal(value)
        case .hex:
            return formatRadix(value, radix: 16) ?? RPNNumberFormatter.formatDecimal(value)
        case .binary:
            return formatRadix(value, radix: 2) ?? RPNNumberFormatter.formatDecimal(value)
        case .financial:
            return RPNNumberFormatter.formatDecimal(value)
        }
    }

    private func parseRadix(_ text: String, radix: Int) -> Double? {
        guard !text.isEmpty else { return nil }

        let isNegative = text.hasPrefix("-")
        let digits = isNegative ? String(text.dropFirst()) : text
        guard !digits.isEmpty, let value = Int64(digits, radix: radix) else { return nil }

        return Double(isNegative ? -value : value)
    }

    private func formatRadix(_ value: Double, radix: Int) -> String? {
        guard value.isFinite, value.rounded() == value else { return nil }
        guard let integer = Int64(exactly: value) else { return nil }

        let magnitude = integer.magnitude
        let digits = String(magnitude, radix: radix, uppercase: true)
        return integer < 0 ? "-\(digits)" : digits
    }

    private func isRadixBuffer(_ buffer: String, allowed: String) -> Bool {
        guard !buffer.contains(".") else { return false }

        let digits = buffer.hasPrefix("-") ? buffer.dropFirst() : Substring(buffer)
        guard !digits.isEmpty else { return false }

        return digits.allSatisfy { allowed.contains($0) }
    }
}

enum RPNNumberFormatter {
    static func formatDecimal(_ value: Double) -> String {
        if value == .infinity { return "∞" }
        if value == -.infinity { return "-∞" }
        if value.isNaN { return "NaN" }

        if value.rounded() == value {
            return String(format: "%.0f", value)
        }

        return String(format: "%.10g", value)
    }
}

extension HistoryModeFilter {
    static let orderedCases: [HistoryModeFilter] = [.all] + CalculatorMode.orderedModes.map(\.historyFilter)

    var theme: ModeTheme {
        switch self {
        case .all:
            return CalculatorMode.standard.theme
        case .standard:
            return CalculatorMode.standard.theme
        case .hex:
            return CalculatorMode.hex.theme
        case .binary:
            return CalculatorMode.binary.theme
        case .financial:
            return CalculatorMode.financial.theme
        }
    }
}

private extension CalculatorMode {
    var historyFilter: HistoryModeFilter {
        switch self {
        case .standard:
            return .standard
        case .binary:
            return .binary
        case .hex:
            return .hex
        case .financial:
            return .financial
        }
    }
}

private enum ModeButtonTemplate {
    case utility(CalculatorUtilityAction, label: String? = nil)
    case digit(String, span: Int = 1)
    case decimal
    case operation(RPNCalculator.BinaryOperation)
    case financial(FinancialVariable)
    case enter(span: Int = 1)
    case spacer(String)

    var buttonSpec: CalculatorButtonSpec {
        switch self {
        case .utility(let action, let label):
            return CalculatorButtonSpec(role: .utility(action), label: label ?? action.label)
        case .digit(let value, let span):
            return CalculatorButtonSpec(role: .digit(value), label: value, span: span)
        case .decimal:
            return CalculatorButtonSpec(role: .decimal, label: ".")
        case .operation(let operation):
            return CalculatorButtonSpec(role: .operation(operation), label: operation.displayLabel)
        case .financial(let variable):
            return CalculatorButtonSpec(role: .financial(variable), label: variable.label)
        case .enter(let span):
            return CalculatorButtonSpec(role: .enter, label: "ENTER", span: span)
        case .spacer(let identifier):
            return CalculatorButtonSpec(role: .spacer(identifier), label: "", span: 1)
        }
    }
}

private let utilityRow: [ModeButtonTemplate] = [
    .utility(.backspace),
    .utility(.clearAll),
    .utility(.drop),
    .utility(.swap)
]

private func makeKeypadRows(_ rows: [[ModeButtonTemplate]]) -> [[CalculatorButtonSpec]] {
    rows.map { row in
        row.map(\.buttonSpec)
    }
}

private extension CalculatorUtilityAction {
    var label: String {
        switch self {
        case .backspace:
            return "⌫"
        case .clearAll:
            return "AC"
        case .drop:
            return "POP"
        case .swap:
            return "X/Y"
        case .toggleSign:
            return "+/−"
        }
    }
}

private extension RPNCalculator.BinaryOperation {
    var displayLabel: String {
        switch self {
        case .add:
            return "+"
        case .subtract:
            return "−"
        case .multiply:
            return "×"
        case .divide:
            return "÷"
        }
    }
}
