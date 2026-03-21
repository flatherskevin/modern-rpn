import SwiftUI

private enum CalculatorColor {
    static let background = Color.black
    static let displayText = Color.white
    static let utilityButton = Color(red: 0.65, green: 0.65, blue: 0.65)
    static let numberButton = Color(red: 0.20, green: 0.20, blue: 0.20)
    static let operatorButton = Color.orange
    static let enterButton = Color(red: 0.24, green: 0.58, blue: 0.34)
    static let stackText = Color.white.opacity(0.68)
    static let historyBackground = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let historySecondaryText = Color.white.opacity(0.72)
    static let historyToolbarBackground = Color.white.opacity(0.04)
    static let historyToolbarText = Color.white.opacity(0.96)
    static let historyToolbarDisabledText = Color.white.opacity(0.34)
}

private enum CalculatorButtonKind {
    case utility
    case number
    case radixLetter
    case operation
    case enter

    var fillColor: Color {
        switch self {
        case .utility:
            return CalculatorColor.utilityButton
        case .number:
            return CalculatorColor.numberButton
        case .radixLetter:
            return CalculatorMode.hex.theme.accentBackground
        case .operation:
            return CalculatorColor.operatorButton
        case .enter:
            return CalculatorColor.enterButton
        }
    }

    var textColor: Color {
        switch self {
        case .utility:
            return .black
        case .number, .operation, .enter:
            return .white
        case .radixLetter:
            return CalculatorMode.hex.theme.accentText
        }
    }
}

private struct CalculatorButtonDefinition {
    let label: String
    let span: Int
    let kind: CalculatorButtonKind
    let action: () -> Void

    init(
        label: String,
        span: Int = 1,
        kind: CalculatorButtonKind,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.span = span
        self.kind = kind
        self.action = action
    }
}

private struct CalculatorPressStyle: ButtonStyle {
    let color: Color
    let span: Int
    let height: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: height)
            .background {
                Group {
                    if span == 1 {
                        RoundedRectangle(cornerRadius: 24, style: .continuous).fill(color)
                    } else {
                        RoundedRectangle(cornerRadius: 30, style: .continuous).fill(color)
                    }
                }
                .overlay {
                    if configuration.isPressed {
                        Group {
                            if span == 1 {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.white.opacity(0.2))
                            } else {
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .fill(Color.white.opacity(0.2))
                            }
                        }
                    }
                }
            }
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(.spring(response: 0.16, dampingFraction: 0.72), value: configuration.isPressed)
    }

    private var pressedScale: CGFloat {
        span > 1 ? 1.06 : 1.2
    }
}

struct ContentView: View {
    @StateObject private var viewModel = CalculatorViewModel()
    @State private var showingHistory = false
    @State private var showingPrivacyPolicy = false

    var body: some View {
        GeometryReader { geometry in
            let topPadding: CGFloat = 12
            let bottomPadding = max(8, geometry.safeAreaInsets.bottom + 4)
            let buttonHeight = keypadButtonHeight(
                screenHeight: geometry.size.height,
                topPadding: topPadding,
                bottomPadding: bottomPadding
            )

            ZStack {
                CalculatorColor.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    stackPanel
                        .padding(.top, 12)

                    display
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.top, 12)
                        .padding(.bottom, 12)

                    buttonGrid(buttonHeight: buttonHeight)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 16)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
            }
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(
                store: viewModel.historyStore,
                filter: $viewModel.historyFilter,
                onFilterChange: viewModel.setHistoryFilter
            )
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
                .presentationDetents([.medium, .large])
        }
    }

    private var header: some View {
        HStack {
            Menu {
                Button("History") {
                    showingHistory = true
                }

                Button("Privacy Policy") {
                    showingPrivacyPolicy = true
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(CalculatorColor.displayText)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Menu")
            .accessibilityIdentifier("menu-button")

            Spacer()

            Menu {
                ForEach(CalculatorMode.allCases) { mode in
                    Button {
                        viewModel.setMode(mode)
                    } label: {
                        Text(mode.title)
                    }
                }
            } label: {
                let theme = viewModel.mode.theme
                Text(viewModel.mode.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .tracking(0.1)
                    .lineLimit(1)
                .foregroundStyle(theme.accentText)
                .padding(.horizontal, 16)
                .frame(minWidth: 112, minHeight: 36)
                .background(theme.accentBackground, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(theme.accentBorder, lineWidth: 1)
                }
            }
            .accessibilityLabel("Mode")
            .accessibilityIdentifier("mode-picker")

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    private var stackPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(viewModel.stackLines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(CalculatorColor.stackText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var display: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(viewModel.errorMessage ?? "")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.red.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)
                .frame(height: 16)

            Text(viewModel.displayText)
                .font(.system(size: 96, weight: .light, design: .rounded))
                .foregroundStyle(CalculatorColor.displayText)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.35)
                .frame(minHeight: 88, alignment: .bottomTrailing)
                .accessibilityIdentifier("display-value")
        }
        .padding(.horizontal, 6)
    }

    private func buttonGrid(buttonHeight: CGFloat) -> some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(Array(buttonRows().enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, button in
                        if let button {
                            Button(action: button.action) {
                                buttonLabelView(for: button)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(button.label)
                            .buttonStyle(CalculatorPressStyle(color: button.kind.fillColor, span: button.span, height: buttonHeight))
                            .gridCellColumns(button.span)
                        } else {
                            Color.clear
                                .frame(height: buttonHeight)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func buttonLabelView(for button: CalculatorButtonDefinition) -> some View {
        if let symbolName = operatorSymbolName(button.label) {
            Image(systemName: symbolName)
                .font(.system(size: buttonFontSize(button.label), weight: .semibold))
                .foregroundStyle(button.kind.textColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            Text(button.label)
                .font(.system(size: buttonFontSize(button.label), weight: .medium, design: .rounded))
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .foregroundStyle(button.kind.textColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func buttonRows() -> [[CalculatorButtonDefinition?]] {
        switch viewModel.mode {
        case .standard:
            return [
                utilityRow(),
                [digitButton("7"), digitButton("8"), digitButton("9"), operationButton("÷", .divide)],
                [digitButton("4"), digitButton("5"), digitButton("6"), operationButton("×", .multiply)],
                [digitButton("1"), digitButton("2"), digitButton("3"), operationButton("−", .subtract)],
                [toggleSignButton(), digitButton("0"), decimalButton(), operationButton("+", .add)],
                [enterButton(span: 4)]
            ]
        case .hex:
            return [
                utilityRow(),
                [digitButton("A"), digitButton("B"), digitButton("C"), operationButton("÷", .divide)],
                [digitButton("D"), digitButton("E"), digitButton("F"), operationButton("×", .multiply)],
                [digitButton("7"), digitButton("8"), digitButton("9"), operationButton("−", .subtract)],
                [digitButton("4"), digitButton("5"), digitButton("6"), operationButton("+", .add)],
                [digitButton("1"), digitButton("2"), digitButton("3"), digitButton("0")],
                [toggleSignButton(), enterButton(span: 3)]
            ]
        case .binary:
            return [
                utilityRow(),
                [digitButton("1"), digitButton("0"), toggleSignButton(), nil],
                [operationButton("+", .add), operationButton("−", .subtract), operationButton("×", .multiply), operationButton("÷", .divide)],
                [enterButton(span: 4)]
            ]
        }
    }

    private func utilityRow() -> [CalculatorButtonDefinition?] {
        [
            utilityButton("⌫", action: viewModel.backspace),
            utilityButton("AC", action: viewModel.clearAll),
            utilityButton("POP", action: viewModel.drop),
            utilityButton("X/Y", action: viewModel.swap)
        ]
    }

    private func utilityButton(_ label: String, action: @escaping () -> Void) -> CalculatorButtonDefinition {
        CalculatorButtonDefinition(label: label, kind: .utility, action: action)
    }

    private func digitButton(_ digit: String) -> CalculatorButtonDefinition {
        let kind: CalculatorButtonKind
        if viewModel.mode == .hex, "ABCDEF".contains(digit) {
            kind = .radixLetter
        } else {
            kind = .number
        }

        return CalculatorButtonDefinition(label: digit, kind: kind) {
            viewModel.tapDigit(digit)
        }
    }

    private func decimalButton() -> CalculatorButtonDefinition {
        CalculatorButtonDefinition(label: ".", kind: .number, action: viewModel.tapDecimal)
    }

    private func toggleSignButton() -> CalculatorButtonDefinition {
        CalculatorButtonDefinition(label: "+/−", kind: .utility, action: viewModel.toggleSign)
    }

    private func enterButton(span: Int) -> CalculatorButtonDefinition {
        CalculatorButtonDefinition(label: "ENTER", span: span, kind: .enter, action: viewModel.enter)
    }

    private func operationButton(_ label: String, _ operation: RPNCalculator.BinaryOperation) -> CalculatorButtonDefinition {
        CalculatorButtonDefinition(label: label, kind: .operation) {
            viewModel.perform(operation)
        }
    }

    private func buttonFontSize(_ label: String) -> CGFloat {
        if ["÷", "×", "−", "+"].contains(label) { return 44 }
        if label == "ENTER" { return 28 }
        return 34
    }

    private func operatorSymbolName(_ label: String) -> String? {
        switch label {
        case "+":
            return "plus"
        case "−":
            return "minus"
        case "×":
            return "multiply"
        case "÷":
            return "divide"
        default:
            return nil
        }
    }

    private func keypadButtonHeight(
        screenHeight: CGFloat,
        topPadding: CGFloat,
        bottomPadding: CGFloat
    ) -> CGFloat {
        let rowCount = CGFloat(buttonRows().count)
        let reservedHeight = topPadding + bottomPadding + 44 + 84 + 120 + 24
        let availableHeight = screenHeight - reservedHeight - (max(0, rowCount - 1) * 6)
        let fittedHeight = floor(availableHeight / rowCount)

        return min(76, max(56, fittedHeight))
    }
}

private struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: HistoryStore
    @Binding var filter: HistoryModeFilter
    let onFilterChange: (HistoryModeFilter) -> Void
    @State private var showingClearConfirmation = false
    @State private var showingFilterOptions = false

    private var entries: [HistoryEntry] {
        guard let mode = filter.mode else { return store.entries }
        return store.entries.filter { $0.mode == mode }
    }

    private var clearConfirmationTitle: String {
        if filter == .all {
            return "Delete all history?"
        }
        return "Delete \(filter.title) history?"
    }

    private var clearConfirmationMessage: String {
        let count = entries.count
        if filter == .all {
            return "This will permanently delete \(count) history entr\(count == 1 ? "y" : "ies")."
        }
        return "This will permanently delete \(count) \(filter.title.lowercased()) entr\(count == 1 ? "y" : "ies")."
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    historyFilterBar
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    List {
                        if entries.isEmpty {
                            Text("No history yet")
                                .foregroundStyle(.white.opacity(0.75))
                                .listRowBackground(CalculatorColor.historyBackground)
                        }

                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(entry.expression)
                                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(CalculatorColor.displayText)

                                    Spacer(minLength: 12)

                                    Text(entry.modeTitle)
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(entry.mode.theme.accentText)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(entry.mode.theme.accentBackground, in: Capsule())
                                        .overlay {
                                            Capsule()
                                                .stroke(entry.mode.theme.accentBorder, lineWidth: 1)
                                        }
                                }
                                Text("= \(entry.displayResultText)")
                                    .font(.system(size: 17, weight: .regular, design: .rounded))
                                    .foregroundStyle(CalculatorColor.displayText)
                                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(CalculatorColor.historySecondaryText)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(CalculatorColor.historyBackground)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("Delete", role: .destructive) {
                                    store.removeEntry(id: entry.id)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(CalculatorColor.historyBackground)
                }

                if showingFilterOptions {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingFilterOptions = false
                        }

                    historyFilterMenu
                        .padding(.leading, 20)
                        .padding(.top, 58)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .topLeading)), removal: .opacity))
                        .zIndex(1)
                }
            }
            .background(CalculatorColor.historyBackground)
            .foregroundStyle(.white)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    toolbarButton("Done", disabled: false) { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    toolbarButton("Clear", disabled: entries.isEmpty) {
                        showingClearConfirmation = true
                    }
                    .disabled(entries.isEmpty)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: filter) { _, newValue in
                onFilterChange(newValue)
            }
            .confirmationDialog(
                clearConfirmationTitle,
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    store.clear(filter: filter)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(clearConfirmationMessage)
            }
        }
    }

    private var historyFilterBar: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.86)) {
                    showingFilterOptions.toggle()
                }
            } label: {
                let theme = filter.theme
                HStack(spacing: 8) {
                    Text("Filter")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(CalculatorColor.historySecondaryText)
                    Text(filter.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.accentText)
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CalculatorColor.historySecondaryText)
                }
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(theme.accentBackground, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(theme.accentBorder, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
    }

    private var historyFilterMenu: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(HistoryModeFilter.orderedCases) { option in
                Button {
                    filter = option
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.86)) {
                        showingFilterOptions = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(option.title)
                            .font(.system(size: 15, weight: option == filter ? .semibold : .medium, design: .rounded))
                            .foregroundStyle(option == filter ? option.theme.accentText : CalculatorColor.displayText)
                        Spacer(minLength: 12)
                        if option == filter {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(option.theme.accentText)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(width: 220, height: 42, alignment: .leading)
                    .background(
                        (option == filter ? option.theme.accentBackground : Color.clear),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.13))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
    }

    private func toolbarButton(_ title: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(
                    disabled
                    ? CalculatorColor.historyToolbarDisabledText
                    : CalculatorColor.historyToolbarText
                )
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(CalculatorColor.historyToolbarBackground, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private let document = PrivacyPolicyDocument.load()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(document.preface, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(document.sections) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.title)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)

                            ForEach(section.paragraphs, id: \.self) { paragraph in
                                Text(paragraph)
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.88))
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            ForEach(section.bullets, id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundStyle(.white.opacity(0.88))
                                    Text(bullet)
                                        .font(.system(size: 15, weight: .regular, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.88))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(16)
            }
            .background(CalculatorColor.historyBackground)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct PrivacyPolicyDocument {
    let title: String
    let preface: [String]
    let sections: [PrivacyPolicySection]

    static func load(bundle: Bundle = .main) -> PrivacyPolicyDocument {
        guard let url = bundle.url(forResource: "PrivacyPolicy", withExtension: "md"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return PrivacyPolicyDocument(
                title: "Privacy Policy",
                preface: ["Privacy policy content is currently unavailable in this build."],
                sections: []
            )
        }

        return parse(content)
    }

    private static func parse(_ content: String) -> PrivacyPolicyDocument {
        let lines = content.components(separatedBy: .newlines)
        var title = "Privacy Policy"
        var preface: [String] = []
        var sections: [PrivacyPolicySection] = []
        var currentSection: PrivacyPolicySection?
        var paragraphBuffer: [String] = []

        func flushParagraph() {
            guard !paragraphBuffer.isEmpty else { return }
            let paragraph = paragraphBuffer.joined(separator: " ")
            if var section = currentSection {
                section.paragraphs.append(paragraph)
                currentSection = section
                sections[sections.count - 1] = section
            } else {
                preface.append(paragraph)
            }
            paragraphBuffer.removeAll()
        }

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                flushParagraph()
                continue
            }

            if line.hasPrefix("# ") {
                flushParagraph()
                title = String(line.dropFirst(2))
                continue
            }

            if line.hasPrefix("## ") {
                flushParagraph()
                let section = PrivacyPolicySection(title: String(line.dropFirst(3)))
                sections.append(section)
                currentSection = section
                continue
            }

            if line.hasPrefix("- ") {
                flushParagraph()
                if var section = currentSection {
                    section.bullets.append(String(line.dropFirst(2)))
                    currentSection = section
                    sections[sections.count - 1] = section
                } else {
                    preface.append(String(line.dropFirst(2)))
                }
                continue
            }

            paragraphBuffer.append(line)
        }

        flushParagraph()

        return PrivacyPolicyDocument(title: title, preface: preface, sections: sections)
    }
}

private struct PrivacyPolicySection: Identifiable {
    let id = UUID()
    let title: String
    var paragraphs: [String] = []
    var bullets: [String] = []
}
