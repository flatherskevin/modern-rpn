import Foundation
import SwiftUI

struct ModeTheme {
    let accentBackground: Color
    let accentBorder: Color
    let accentText: Color
}

enum CalculatorMode: String, CaseIterable, Codable, Identifiable {
    case standard
    case binary
    case hex

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard:
            return "Standard"
        case .hex:
            return "Hex"
        case .binary:
            return "Binary"
        }
    }

    var supportsDecimalInput: Bool {
        self == .standard
    }

    var theme: ModeTheme {
        switch self {
        case .standard:
            return ModeTheme(
                accentBackground: Color.white.opacity(0.08),
                accentBorder: Color.white.opacity(0.10),
                accentText: Color.white.opacity(0.94)
            )
        case .hex:
            return ModeTheme(
                accentBackground: Color(red: 0.16, green: 0.24, blue: 0.35),
                accentBorder: Color(red: 0.28, green: 0.43, blue: 0.63),
                accentText: Color(red: 0.82, green: 0.92, blue: 1.0)
            )
        case .binary:
            return ModeTheme(
                accentBackground: Color(red: 0.13, green: 0.27, blue: 0.18),
                accentBorder: Color(red: 0.24, green: 0.53, blue: 0.33),
                accentText: Color(red: 0.82, green: 0.97, blue: 0.86)
            )
        }
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
    static let orderedCases: [HistoryModeFilter] = [.all, .standard, .binary, .hex]

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
        }
    }
}
