import Foundation

final class RPNCalculator {
    enum BinaryOperation: String, CaseIterable {
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

    init(mode: CalculatorMode = .standard) {
        self.mode = mode
    }

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
        errorMessage = nil
    }

    var session: CalculatorSession {
        CalculatorSession(
            mode: mode,
            stack: stack,
            inputBuffer: inputBuffer,
            isTyping: isTyping
        )
    }

    func tapDigit(_ digit: String) {
        guard let normalizedDigit = mode.normalizeDigit(digit) else { return }
        errorMessage = nil

        if isTyping {
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
            guard !inputBuffer.contains(".") else { return }
            inputBuffer.append(".")
        } else {
            inputBuffer = "0."
            isTyping = true
        }
    }

    func toggleSign() {
        errorMessage = nil

        if isTyping {
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

    func backspace() {
        errorMessage = nil

        guard isTyping else { return }

        _ = inputBuffer.popLast()
        if inputBuffer.isEmpty || inputBuffer == "-" {
            inputBuffer = "0"
            isTyping = false
        }
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

    static func format(_ value: Double) -> String {
        RPNNumberFormatter.formatDecimal(value)
    }
}

struct OperationResult {
    let mode: CalculatorMode
    let expression: String
    let result: Double
    let resultText: String
    let stackSnapshot: [Double]
}
