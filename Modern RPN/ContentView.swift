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
        let cornerRadius = min(height * 0.24, 16)

        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: height)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(color)
                .overlay {
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.2))
                    }
                }
            }
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .zIndex(configuration.isPressed ? 1 : 0)
            .animation(.spring(response: 0.16, dampingFraction: 0.72), value: configuration.isPressed)
    }

    private var pressedScale: CGFloat {
        span > 1 ? 1.02 : 1.04
    }
}

private struct HistoryLayoutMetrics {
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let filterBarHeight: CGFloat
    let filterBarHorizontalPadding: CGFloat
    let toolbarButtonHeight: CGFloat
    let toolbarButtonHorizontalPadding: CGFloat
    let entryVerticalPadding: CGFloat

    static func make(screenSize: CGSize) -> HistoryLayoutMetrics {
        let compactWidth = screenSize.width <= 350
        let compactHeight = screenSize.height <= 700
        let compactLayout = compactWidth || compactHeight
        let horizontalPadding: CGFloat = compactWidth ? 14 : 20

        return HistoryLayoutMetrics(
            horizontalPadding: horizontalPadding,
            topPadding: compactHeight ? 6 : 8,
            bottomPadding: compactHeight ? 10 : 12,
            filterBarHeight: compactLayout ? 36 : 38,
            filterBarHorizontalPadding: compactLayout ? 12 : 14,
            toolbarButtonHeight: compactLayout ? 40 : 44,
            toolbarButtonHorizontalPadding: compactLayout ? 14 : 18,
            entryVerticalPadding: compactLayout ? 3 : 4
        )
    }
}

private struct PrivacyPolicyLayoutMetrics {
    let contentPadding: CGFloat
    let sectionSpacing: CGFloat
    let cardPadding: CGFloat
    let cardCornerRadius: CGFloat
    let cardInnerSpacing: CGFloat
    let bulletSpacing: CGFloat
    let prefaceFontSize: CGFloat
    let sectionTitleFontSize: CGFloat
    let bodyFontSize: CGFloat

    static func make(screenSize: CGSize) -> PrivacyPolicyLayoutMetrics {
        let compactWidth = screenSize.width <= 350
        let compactHeight = screenSize.height <= 700
        let compactLayout = compactWidth || compactHeight

        return PrivacyPolicyLayoutMetrics(
            contentPadding: compactWidth ? 12 : 16,
            sectionSpacing: compactLayout ? 16 : 20,
            cardPadding: compactWidth ? 14 : 16,
            cardCornerRadius: compactWidth ? 16 : 18,
            cardInnerSpacing: compactLayout ? 8 : 10,
            bulletSpacing: compactLayout ? 6 : 8,
            prefaceFontSize: compactLayout ? 15 : 16,
            sectionTitleFontSize: compactLayout ? 17 : 18,
            bodyFontSize: compactLayout ? 14 : 15
        )
    }
}

struct ContentView: View {
    @StateObject private var viewModel = CalculatorViewModel()
    @State private var showingHistory = false
    @State private var showingAbout = false
    @State private var showingPrivacyPolicy = false

    var body: some View {
        GeometryReader { geometry in
            let metrics = CalculatorLayoutMetrics.make(
                screenSize: geometry.size,
                safeAreaBottom: geometry.safeAreaInsets.bottom,
                rowCount: buttonRows().count
            )

            ZStack {
                CalculatorColor.background
                    .ignoresSafeArea()

                calculatorBody(metrics: metrics)
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.top, metrics.topPadding)
                    .padding(.bottom, metrics.bottomPadding)
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
        .sheet(isPresented: $showingAbout) {
            AboutView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
                .presentationDetents([.medium, .large])
        }
    }

    private func calculatorBody(metrics: CalculatorLayoutMetrics) -> some View {
        VStack(spacing: metrics.contentSpacing) {
            header(metrics: metrics)
                .frame(height: metrics.headerHeight)
            stackPanel(metrics: metrics)
            display(metrics: metrics)
                .frame(height: metrics.displayAreaHeight, alignment: .bottom)
            buttonGrid(metrics: metrics)
                .frame(height: metrics.buttonGridHeight, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func header(metrics: CalculatorLayoutMetrics) -> some View {
        HStack {
            Menu {
                Button("History") {
                    showingHistory = true
                }

                Button("About") {
                    showingAbout = true
                }

                Button("Privacy Policy") {
                    showingPrivacyPolicy = true
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(CalculatorColor.displayText)
                    .frame(width: metrics.headerButtonSize, height: metrics.headerButtonSize)
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
                    .frame(minWidth: metrics.modeBadgeMinWidth, minHeight: metrics.modeBadgeMinHeight)
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
                .frame(width: metrics.headerButtonSize, height: metrics.headerButtonSize)
        }
    }

    private func stackPanel(metrics: CalculatorLayoutMetrics) -> some View {
        GeometryReader { proxy in
            let contentHeight = max(0, proxy.size.height - (metrics.stackPanelPadding * 2))
            let rowHeight = max(
                metrics.stackFontSize * 1.3,
                (contentHeight - (metrics.stackSpacing * 3)) / 4
            )

            VStack(alignment: .leading, spacing: metrics.stackSpacing) {
                ForEach(viewModel.stackLines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: metrics.stackFontSize, weight: .medium, design: .monospaced))
                        .foregroundStyle(CalculatorColor.stackText)
                        .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .topLeading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(metrics.stackPanelPadding)
        }
        .frame(maxWidth: .infinity)
        .frame(height: metrics.stackPanelHeight, alignment: .topLeading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func display(metrics: CalculatorLayoutMetrics) -> some View {
        let minimumScaleFactor = viewModel.mode == .binary ? 0.55 : 0.35

        return VStack(alignment: .trailing, spacing: 4) {
            Text(viewModel.errorMessage ?? "")
                .font(.system(size: metrics.displayErrorFontSize, weight: .regular, design: .rounded))
                .foregroundStyle(.red.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)
                .frame(height: metrics.displayErrorHeight)

            Text(viewModel.displayText)
                .font(.system(size: metrics.displayFontSize, weight: .light, design: .rounded))
                .foregroundStyle(CalculatorColor.displayText)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(minimumScaleFactor)
                .frame(minHeight: metrics.displayMinHeight, alignment: .bottomTrailing)
                .accessibilityIdentifier("display-value")
        }
        .padding(.horizontal, 6)
        .layoutPriority(1)
    }

    private func buttonGrid(metrics: CalculatorLayoutMetrics) -> some View {
        Grid(horizontalSpacing: metrics.buttonSpacing, verticalSpacing: metrics.buttonSpacing) {
            ForEach(Array(buttonRows().enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, button in
                        if let button {
                            Button(action: button.action) {
                                buttonLabelView(for: button, metrics: metrics)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(button.label)
                            .buttonStyle(CalculatorPressStyle(color: button.kind.fillColor, span: button.span, height: metrics.buttonHeight))
                            .gridCellColumns(button.span)
                        } else {
                            Color.clear
                                .frame(height: metrics.buttonHeight)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func buttonLabelView(for button: CalculatorButtonDefinition, metrics: CalculatorLayoutMetrics) -> some View {
        if let symbolName = operatorSymbolName(button.label) {
            Image(systemName: symbolName)
                .font(.system(size: buttonFontSize(button.label, metrics: metrics), weight: .semibold))
                .foregroundStyle(button.kind.textColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            Text(button.label)
                .font(.system(size: buttonFontSize(button.label, metrics: metrics), weight: .medium, design: .rounded))
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

    private func buttonFontSize(_ label: String, metrics: CalculatorLayoutMetrics) -> CGFloat {
        if ["÷", "×", "−", "+"].contains(label) { return metrics.operatorFontSize }
        if label == "ENTER" { return metrics.enterFontSize }
        return metrics.buttonFontSize
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
}

private struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: HistoryStore
    @Binding var filter: HistoryModeFilter
    let onFilterChange: (HistoryModeFilter) -> Void
    @State private var showingClearConfirmation = false

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
        GeometryReader { geometry in
            let metrics = HistoryLayoutMetrics.make(screenSize: geometry.size)

            NavigationStack {
                VStack(spacing: 0) {
                    historyFilterBar(metrics: metrics)
                        .padding(.horizontal, metrics.horizontalPadding)
                        .padding(.top, metrics.topPadding)
                        .padding(.bottom, metrics.bottomPadding)

                    List {
                        if entries.isEmpty {
                            Text("No history yet")
                                .foregroundStyle(.white.opacity(0.75))
                                .listRowBackground(CalculatorColor.historyBackground)
                        }

                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(entry.displayExpression)
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
                            .padding(.vertical, metrics.entryVerticalPadding)
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
                .background(CalculatorColor.historyBackground)
                .foregroundStyle(.white)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        closeToolbarButton { dismiss() }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        toolbarButton("Clear", disabled: entries.isEmpty, metrics: metrics) {
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
    }

    private func historyFilterBar(metrics: HistoryLayoutMetrics) -> some View {
        HStack {
            Menu {
                ForEach(HistoryModeFilter.orderedCases) { option in
                    Button {
                        filter = option
                    } label: {
                        if option == filter {
                            Label(option.title, systemImage: "checkmark")
                        } else {
                            Text(option.title)
                        }
                    }
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
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CalculatorColor.historySecondaryText)
                }
                .padding(.horizontal, metrics.filterBarHorizontalPadding)
                .frame(height: metrics.filterBarHeight)
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

    private func toolbarButton(_ title: String, disabled: Bool, metrics: HistoryLayoutMetrics, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(
                    disabled
                    ? CalculatorColor.historyToolbarDisabledText
                    : CalculatorColor.historyToolbarText
                )
                .padding(.horizontal, metrics.toolbarButtonHorizontalPadding)
                .frame(minHeight: metrics.toolbarButtonHeight)
                .background(CalculatorColor.historyToolbarBackground, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func closeToolbarButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(CalculatorColor.historyToolbarText)
                .frame(width: 32, height: 32)
                .background(CalculatorColor.historyToolbarBackground, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
}

private struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private let document = PrivacyPolicyDocument.load()

    var body: some View {
        GeometryReader { geometry in
            let metrics = PrivacyPolicyLayoutMetrics.make(screenSize: geometry.size)

            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
                        ForEach(document.preface, id: \.self) { paragraph in
                            Text(paragraph)
                                .font(.system(size: metrics.prefaceFontSize, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        ForEach(document.sections) { section in
                            VStack(alignment: .leading, spacing: metrics.cardInnerSpacing) {
                                Text(section.title)
                                    .font(.system(size: metrics.sectionTitleFontSize, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)

                                ForEach(section.paragraphs, id: \.self) { paragraph in
                                    Text(paragraph)
                                        .font(.system(size: metrics.bodyFontSize, weight: .regular, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.88))
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                ForEach(section.bullets, id: \.self) { bullet in
                                    HStack(alignment: .top, spacing: metrics.bulletSpacing) {
                                        Text("•")
                                            .foregroundStyle(.white.opacity(0.88))
                                        Text(bullet)
                                            .font(.system(size: metrics.bodyFontSize, weight: .regular, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.88))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(metrics.cardPadding)
                            .background(
                                Color.white.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: metrics.cardCornerRadius, style: .continuous)
                            )
                        }
                    }
                    .padding(metrics.contentPadding)
                }
                .background(CalculatorColor.historyBackground)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        closeToolbarButton { dismiss() }
                    }
                }
                .navigationTitle(document.title)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func closeToolbarButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(CalculatorColor.historyToolbarText)
                .frame(width: 32, height: 32)
                .background(CalculatorColor.historyToolbarBackground, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
}

private struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let appStoreURL = URL(string: "https://apps.apple.com/us/app/modern-rpn/id6760340697")
    private let developerProfileURL = URL(string: "https://github.com/flatherskevin")
    private let issuesURL = URL(string: "https://github.com/flatherskevin/modern-rpn/issues")

    var body: some View {
        GeometryReader { geometry in
            let metrics = PrivacyPolicyLayoutMetrics.make(screenSize: geometry.size)

            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
                        aboutHero(metrics: metrics)

                        aboutCard(
                            title: "Developer",
                            metrics: metrics
                        ) {
                            if let developerProfileURL {
                                Link("@flatherskevin", destination: developerProfileURL)
                                    .font(.system(size: metrics.bodyFontSize, weight: .semibold, design: .rounded))
                                    .tint(.white)
                            }
                        }

                        aboutCard(
                            title: "Version",
                            metrics: metrics
                        ) {
                            Text(versionText)
                                .font(.system(size: metrics.bodyFontSize, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.88))
                        }

                        aboutCard(
                            title: "Links",
                            metrics: metrics
                        ) {
                            VStack(alignment: .leading, spacing: metrics.cardInnerSpacing) {
                                if let issuesURL {
                                    Link("GitHub Issues", destination: issuesURL)
                                        .font(.system(size: metrics.bodyFontSize, weight: .semibold, design: .rounded))
                                }

                                if let appStoreURL {
                                    Link("App Store Listing", destination: appStoreURL)
                                        .font(.system(size: metrics.bodyFontSize, weight: .semibold, design: .rounded))
                                }
                            }
                            .tint(.white)
                        }
                    }
                    .padding(metrics.contentPadding)
                }
                .background(CalculatorColor.historyBackground)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        closeToolbarButton { dismiss() }
                    }
                }
                .navigationTitle("About")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var versionText: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (shortVersion, buildNumber) {
        case let (.some(version), .some(build)):
            return "Version \(version) (\(build))"
        case let (.some(version), .none):
            return "Version \(version)"
        case let (.none, .some(build)):
            return "Build \(build)"
        default:
            return "Version unavailable"
        }
    }

    private func aboutHero(metrics: PrivacyPolicyLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.cardInnerSpacing) {
            Text("Modern RPN")
                .font(.system(size: metrics.sectionTitleFontSize + 6, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text("Minimal reverse polish notation calculator for iPhone and iPad with Standard, Binary, and Hex modes.")
                .font(.system(size: metrics.prefaceFontSize, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(metrics.cardPadding)
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: metrics.cardCornerRadius, style: .continuous)
        )
    }

    private func aboutCard<Content: View>(
        title: String,
        metrics: PrivacyPolicyLayoutMetrics,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: metrics.cardInnerSpacing) {
            Text(title)
                .font(.system(size: metrics.sectionTitleFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(metrics.cardPadding)
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: metrics.cardCornerRadius, style: .continuous)
        )
    }

    private func closeToolbarButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(CalculatorColor.historyToolbarText)
                .frame(width: 32, height: 32)
                .background(CalculatorColor.historyToolbarBackground, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
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
