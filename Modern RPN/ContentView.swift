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
    case financial

    func fillColor(for mode: CalculatorMode) -> Color {
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
        case .financial:
            return mode.theme.accentBackground
        }
    }

    func textColor(for mode: CalculatorMode) -> Color {
        switch self {
        case .utility:
            return .black
        case .number, .operation, .enter:
            return .white
        case .radixLetter:
            return CalculatorMode.hex.theme.accentText
        case .financial:
            return mode.theme.accentText
        }
    }
}

private extension CalculatorButtonKind {
    static func make(for spec: CalculatorButtonSpec, mode: CalculatorMode) -> CalculatorButtonKind? {
        switch spec.role {
        case .utility:
            return .utility
        case .digit(let digit):
            if mode == .hex, "ABCDEF".contains(digit) {
                return .radixLetter
            }
            return .number
        case .decimal:
            return .number
        case .operation:
            return .operation
        case .financial:
            return .financial
        case .enter:
            return .enter
        case .spacer:
            return nil
        }
    }
}

private struct CalculatorPressStyle: ButtonStyle {
    let mode: CalculatorMode
    let color: Color
    let span: Int
    let height: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        let cornerRadius = min(height * 0.24, 16)

        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: height)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(color)
                .overlay {
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.2))
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(borderColor, lineWidth: mode == .financial ? 1 : 0)
                }
            }
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .zIndex(configuration.isPressed ? 1 : 0)
            .animation(.spring(response: 0.16, dampingFraction: 0.72), value: configuration.isPressed)
    }

    private var pressedScale: CGFloat {
        span > 1 ? 1.02 : 1.04
    }

    private var borderColor: Color {
        mode == .financial ? mode.theme.accentBorder.opacity(0.45) : .clear
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
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: CalculatorViewModel
    @State private var showingHistory = false
    @State private var showingAbout = false
    @State private var showingPrivacyPolicy = false
    @State private var showingFinancialTools = false

    init(launchConfiguration: AppLaunchConfiguration = .currentProcess) {
        _viewModel = StateObject(
            wrappedValue: CalculatorViewModel(launchConfiguration: launchConfiguration)
        )
        _showingHistory = State(initialValue: launchConfiguration.presentedSheet == .history)
        _showingAbout = State(initialValue: launchConfiguration.presentedSheet == .about)
        _showingPrivacyPolicy = State(initialValue: launchConfiguration.presentedSheet == .privacyPolicy)
        _showingFinancialTools = State(initialValue: launchConfiguration.presentedSheet == .financialTools)
    }

    var body: some View {
        GeometryReader { geometry in
            let metrics = CalculatorLayoutMetrics.make(
                screenSize: geometry.size,
                safeAreaBottom: geometry.safeAreaInsets.bottom,
                rowCount: viewModel.mode.keypadRows.count
            )

            ZStack {
                CalculatorColor.background
                    .ignoresSafeArea()

                calculatorLayout(in: geometry, metrics: metrics)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.top, metrics.topPadding)
                    .padding(.bottom, metrics.bottomPadding)
            }
        }
        .onAppear {
            OrientationCoordinator.shared.apply(for: viewModel.mode)
        }
        .onChange(of: viewModel.mode) { _, newMode in
            OrientationCoordinator.shared.apply(for: newMode)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            OrientationCoordinator.shared.apply(for: viewModel.mode)
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
        .sheet(isPresented: $showingFinancialTools) {
            FinancialToolsView(viewModel: viewModel)
                .presentationDetents([.large])
        }
    }

    @ViewBuilder
    private func calculatorLayout(in geometry: GeometryProxy, metrics: CalculatorLayoutMetrics) -> some View {
        switch viewModel.mode.layoutStyle {
        case .standard:
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
        case .financialLandscape:
            let headerHeight: CGFloat = 54
            let bodyAvailableHeight = max(260, geometry.size.height - metrics.topPadding - metrics.bottomPadding - headerHeight)

            VStack(spacing: 10) {
                header(metrics: metrics)
                financialCalculatorBody(
                    availableWidth: geometry.size.width - (metrics.horizontalPadding * 2),
                    availableHeight: bodyAvailableHeight
                )
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
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
                ForEach(CalculatorMode.orderedModes) { mode in
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

            Group {
                if viewModel.mode == .financial {
                    Button {
                        showingFinancialTools = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(CalculatorColor.displayText)
                            .frame(width: metrics.headerButtonSize, height: metrics.headerButtonSize)
                    }
                    .accessibilityLabel("Financial Tools")
                    .accessibilityIdentifier("financial-tools-button")
                } else {
                    Color.clear
                        .frame(width: metrics.headerButtonSize, height: metrics.headerButtonSize)
                }
            }
        }
    }

    private func stackPanel(metrics: CalculatorLayoutMetrics) -> some View {
        GeometryReader { proxy in
            let contentHeight = max(0, proxy.size.height - (metrics.stackPanelPadding * 2))
            let rowHeight = max(
                metrics.stackFontSize * 1.3,
                (contentHeight - (metrics.stackSpacing * 3)) / 4
            )

            Group {
                if viewModel.mode == .financial {
                    HStack(alignment: .top, spacing: 18) {
                        stackColumn(lines: viewModel.stackLines, rowHeight: rowHeight, metrics: metrics)
                        stackColumn(lines: viewModel.financialRegisterLines, rowHeight: rowHeight, metrics: metrics)
                    }
                } else {
                    stackColumn(lines: viewModel.stackLines, rowHeight: rowHeight, metrics: metrics)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(metrics.stackPanelPadding)
        }
        .frame(maxWidth: .infinity)
        .frame(height: metrics.stackPanelHeight, alignment: .topLeading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func stackColumn(lines: [String], rowHeight: CGFloat, metrics: CalculatorLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.stackSpacing) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: metrics.stackFontSize, weight: .medium, design: .monospaced))
                    .foregroundStyle(CalculatorColor.stackText)
                    .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var financialRegisterPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Financial Registers")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(CalculatorColor.stackText)
                .textCase(.uppercase)

            ForEach(viewModel.financialRegisterLines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(CalculatorColor.displayText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var financialStatusPanel: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("STACK")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(CalculatorColor.stackText)
                    .tracking(1.1)
                    .padding(.bottom, 4)

                ForEach(viewModel.stackLines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(CalculatorColor.displayText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text("REGISTERS")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(CalculatorColor.stackText)
                    .tracking(1.1)
                    .padding(.bottom, 4)

                ForEach(viewModel.financialRegisterLines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(CalculatorColor.displayText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.24))
        )
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

    private func financialCalculatorBody(availableWidth: CGFloat, availableHeight: CGFloat) -> some View {
        let designWidth: CGFloat = 760
        let designHeight: CGFloat = 372
        let buttonHeight: CGFloat = 42
        let clampedWidth = max(320, availableWidth)
        let clampedHeight = max(240, availableHeight)
        let widthScale = clampedWidth / designWidth
        let heightScale = clampedHeight / designHeight
        let scale = min(1, widthScale, heightScale)

        return VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                financialStatusPanel
                display(metrics: metricsForLandscapeButtons(buttonHeight: buttonHeight))
                    .frame(width: 188)
            }

            buttonGrid(metrics: metricsForLandscapeButtons(buttonHeight: buttonHeight))
        }
        .padding(14)
        .frame(width: designWidth, height: designHeight, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.08, blue: 0.05),
                            Color(red: 0.09, green: 0.06, blue: 0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(red: 0.44, green: 0.28, blue: 0.15), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 18, y: 12)
        .scaleEffect(scale, anchor: .top)
        .frame(width: clampedWidth, height: clampedHeight, alignment: .top)
    }

    private func buttonGrid(metrics: CalculatorLayoutMetrics) -> some View {
        Grid(
            horizontalSpacing: metrics.buttonSpacing,
            verticalSpacing: metrics.buttonSpacing
        ) {
            ForEach(Array(viewModel.mode.keypadRows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(row) { button in
                        if let kind = CalculatorButtonKind.make(for: button, mode: viewModel.mode) {
                            Button(action: action(for: button.role)) {
                                buttonLabelView(for: button, kind: kind, metrics: metrics)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(button.label)
                            .buttonStyle(
                                CalculatorPressStyle(
                                    mode: viewModel.mode,
                                    color: kind.fillColor(for: viewModel.mode),
                                    span: button.span,
                                    height: metrics.buttonHeight
                                )
                            )
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
    private func buttonLabelView(for button: CalculatorButtonSpec, kind: CalculatorButtonKind, metrics: CalculatorLayoutMetrics? = nil) -> some View {
        let resolvedMetrics = metrics ?? CalculatorLayoutMetrics.make(
            screenSize: CGSize(width: 390, height: 844),
            safeAreaBottom: 34,
            rowCount: viewModel.mode.keypadRows.count
        )
        if let symbolName = operatorSymbolName(button.label) {
            Image(systemName: symbolName)
                .font(.system(size: buttonFontSize(button.label, metrics: resolvedMetrics), weight: .semibold))
                .foregroundStyle(kind.textColor(for: viewModel.mode))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            Text(button.label)
                .font(.system(size: buttonFontSize(button.label, metrics: resolvedMetrics), weight: .medium, design: .rounded))
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .foregroundStyle(kind.textColor(for: viewModel.mode))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func action(for role: CalculatorButtonRole) -> () -> Void {
        switch role {
        case .utility(let action):
            switch action {
            case .backspace:
                return viewModel.backspace
            case .clearAll:
                return viewModel.clearAll
            case .drop:
                return viewModel.drop
            case .swap:
                return viewModel.swap
            case .toggleSign:
                return viewModel.toggleSign
            }
        case .digit(let digit):
            return { viewModel.tapDigit(digit) }
        case .decimal:
            return viewModel.tapDecimal
        case .operation(let operation):
            return { viewModel.perform(operation) }
        case .financial(let variable):
            return { viewModel.performFinancialAction(variable) }
        case .enter:
            return viewModel.enter
        case .spacer:
            return {}
        }
    }

    private func buttonFontSize(_ label: String, metrics: CalculatorLayoutMetrics) -> CGFloat {
        if viewModel.mode == .financial {
            if ["÷", "×", "−", "+"].contains(label) { return metrics.operatorFontSize }
            if label == "ENTER" { return metrics.enterFontSize }
            if ["PV", "PMT", "FV", "AC", "POP", "CHS"].contains(label) { return 22 }
            if label == "x↔y" { return 18 }
            return max(22, metrics.buttonFontSize - 2)
        }
        if ["÷", "×", "−", "+"].contains(label) { return metrics.operatorFontSize }
        if label == "ENTER" { return metrics.enterFontSize }
        if ["PV", "PMT", "FV"].contains(label) { return 24 }
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

    private func metricsForLandscapeButtons(buttonHeight: CGFloat) -> CalculatorLayoutMetrics {
        CalculatorLayoutMetrics(
            topPadding: 8,
            bottomPadding: 8,
            horizontalPadding: 16,
            contentSpacing: 10,
            buttonSpacing: 6,
            headerHeight: 44,
            stackPanelHeight: 96,
            buttonHeight: buttonHeight,
            buttonGridHeight: (buttonHeight * CGFloat(viewModel.mode.keypadRows.count)) + (6 * CGFloat(max(0, viewModel.mode.keypadRows.count - 1))),
            displayAreaHeight: 96,
            headerButtonSize: 44,
            modeBadgeMinWidth: 112,
            modeBadgeMinHeight: 36,
            stackFontSize: 13,
            stackSpacing: 3,
            stackPanelPadding: 8,
            displayErrorFontSize: 13,
            displayErrorHeight: 14,
            displayFontSize: 72,
            displayMinHeight: 72,
            enterFontSize: 24,
            buttonFontSize: 30,
            operatorFontSize: 38,
            prefersScrollFallback: false
        )
    }

}

private struct FinancialToolsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CalculatorViewModel

    @State private var cashFlowInitialAmountText = ""
    @State private var newCashFlowAmountText = ""
    @State private var newCashFlowCountText = "1"
    @State private var npvRateText = ""
    @State private var amortizationPeriodsText = "12"
    @State private var percentBaseText = ""
    @State private var percentRateText = ""
    @State private var percentPartText = ""
    @State private var percentTotalText = ""
    @State private var percentOriginalText = ""
    @State private var percentUpdatedText = ""
    @State private var dateStart = Date()
    @State private var dateEnd = Date()
    @State private var dateOffsetDaysText = "30"
    @State private var bondSettlement = Date()
    @State private var bondMaturity = Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
    @State private var bondCouponText = "5"
    @State private var bondYieldText = "5"
    @State private var bondPriceText = "100"
    @State private var amortizationSummary: AmortizationSummary?

    var body: some View {
        NavigationStack {
            Form {
                quickActionsSection
                memorySection
                cashFlowSection
                percentSection
                dateSection
                bondSection
                amortizationSection
            }
            .scrollContentBackground(.hidden)
            .background(CalculatorColor.background)
            .navigationTitle("Financial Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            syncFieldsFromModel()
        }
    }

    private var quickActionsSection: some View {
        Section("Stack And Mode") {
            Picker("Payments", selection: paymentModeBinding) {
                ForEach(PaymentMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                financialActionButton("CLx") {
                    viewModel.clearX()
                }
                financialActionButton("R↓") {
                    viewModel.rollDown()
                }
                financialActionButton("EEX") {
                    viewModel.enterExponent()
                }
            }
        }
    }

    private var memorySection: some View {
        Section("Memory Registers") {
            ForEach(0..<10, id: \.self) { index in
                HStack {
                    Text("R\(index)")
                    Spacer()
                    if let value = viewModel.memoryRegisters[index] {
                        Text(RPNNumberFormatter.formatDecimal(value))
                            .foregroundStyle(CalculatorColor.stackText)
                    } else {
                        Text("—")
                            .foregroundStyle(CalculatorColor.stackText)
                    }
                    Button("STO") {
                        viewModel.storeMemory(index: index)
                    }
                    .buttonStyle(.bordered)
                    Button("RCL") {
                        viewModel.recallMemory(index: index)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var cashFlowSection: some View {
        Section("Cash Flow Worksheet") {
            TextField("Initial Cash Flow", text: $cashFlowInitialAmountText)
                .keyboardType(.decimalPad)
            Button("Save Initial Cash Flow") {
                guard let value = decimal(from: cashFlowInitialAmountText) else { return }
                viewModel.setCashFlowInitialAmount(value)
            }

            TextField("NPV Rate %", text: $npvRateText)
                .keyboardType(.decimalPad)

            HStack(spacing: 10) {
                financialActionButton("NPV") {
                    guard let rate = decimal(from: npvRateText) else { return }
                    viewModel.calculateNetPresentValue(ratePercent: rate)
                }
                financialActionButton("IRR") {
                    viewModel.calculateInternalRateOfReturn()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Add Cash Flow")
                    .font(.system(size: 14, weight: .semibold))
                TextField("Amount", text: $newCashFlowAmountText)
                    .keyboardType(.decimalPad)
                TextField("Count", text: $newCashFlowCountText)
                    .keyboardType(.numberPad)
                Button("Add Entry") {
                    guard let amount = decimal(from: newCashFlowAmountText),
                          let count = Int(newCashFlowCountText),
                          count > 0 else { return }
                    viewModel.addCashFlowEntry(amount: amount, count: count)
                    newCashFlowAmountText = ""
                    newCashFlowCountText = "1"
                }
            }

            ForEach(viewModel.cashFlowEntries) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("CF \(RPNNumberFormatter.formatDecimal(entry.amount))")
                        Spacer()
                        Text("N \(entry.count)")
                            .foregroundStyle(CalculatorColor.stackText)
                    }
                    Button("Delete Entry", role: .destructive) {
                        viewModel.removeCashFlowEntry(id: entry.id)
                    }
                }
            }
        }
    }

    private var percentSection: some View {
        Section("Percent") {
            TextField("Base", text: $percentBaseText)
                .keyboardType(.decimalPad)
            TextField("Percent", text: $percentRateText)
                .keyboardType(.decimalPad)
            financialActionButton("Base × %") {
                guard let base = decimal(from: percentBaseText),
                      let percent = decimal(from: percentRateText) else { return }
                viewModel.calculatePercent(base: base, percent: percent)
            }

            TextField("Part", text: $percentPartText)
                .keyboardType(.decimalPad)
            TextField("Total", text: $percentTotalText)
                .keyboardType(.decimalPad)
            financialActionButton("% Of Total") {
                guard let part = decimal(from: percentPartText),
                      let total = decimal(from: percentTotalText) else { return }
                viewModel.calculatePercentOfTotal(part: part, total: total)
            }

            TextField("Original", text: $percentOriginalText)
                .keyboardType(.decimalPad)
            TextField("Updated", text: $percentUpdatedText)
                .keyboardType(.decimalPad)
            financialActionButton("Δ%") {
                guard let original = decimal(from: percentOriginalText),
                      let updated = decimal(from: percentUpdatedText) else { return }
                viewModel.calculatePercentDifference(from: original, to: updated)
            }
        }
    }

    private var dateSection: some View {
        Section("Dates") {
            DatePicker("Start", selection: $dateStart, displayedComponents: .date)
            DatePicker("End", selection: $dateEnd, displayedComponents: .date)
            financialActionButton("Days Between") {
                viewModel.calculateDaysBetween(from: dateStart, to: dateEnd)
            }

            TextField("Days To Add", text: $dateOffsetDaysText)
                .keyboardType(.numberPad)
            financialActionButton("Add Days") {
                guard let days = Int(dateOffsetDaysText) else { return }
                viewModel.calculateDateByAdding(days: days, to: dateStart)
            }
        }
    }

    private var bondSection: some View {
        Section("Bonds") {
            DatePicker("Settlement", selection: $bondSettlement, displayedComponents: .date)
            DatePicker("Maturity", selection: $bondMaturity, displayedComponents: .date)
            TextField("Coupon %", text: $bondCouponText)
                .keyboardType(.decimalPad)
            TextField("Yield %", text: $bondYieldText)
                .keyboardType(.decimalPad)
            financialActionButton("Bond Price") {
                guard let coupon = decimal(from: bondCouponText),
                      let yieldValue = decimal(from: bondYieldText) else { return }
                viewModel.calculateBondPrice(
                    settlement: bondSettlement,
                    maturity: bondMaturity,
                    couponRatePercent: coupon,
                    yieldPercent: yieldValue
                )
            }

            TextField("Price", text: $bondPriceText)
                .keyboardType(.decimalPad)
            financialActionButton("Bond Yield") {
                guard let coupon = decimal(from: bondCouponText),
                      let price = decimal(from: bondPriceText) else { return }
                viewModel.calculateBondYield(
                    settlement: bondSettlement,
                    maturity: bondMaturity,
                    couponRatePercent: coupon,
                    price: price
                )
            }
        }
    }

    private var amortizationSection: some View {
        Section("Amortization") {
            TextField("Periods", text: $amortizationPeriodsText)
                .keyboardType(.numberPad)
            financialActionButton("Calculate Amortization") {
                guard let periods = Int(amortizationPeriodsText) else { return }
                amortizationSummary = viewModel.calculateAmortization(periods: periods)
            }

            if let amortizationSummary {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Principal: \(RPNNumberFormatter.formatDecimal(amortizationSummary.principalPaid))")
                    Text("Interest: \(RPNNumberFormatter.formatDecimal(amortizationSummary.interestPaid))")
                    Text("Balance: \(RPNNumberFormatter.formatDecimal(amortizationSummary.remainingBalance))")
                }
                .foregroundStyle(CalculatorColor.stackText)
            }
        }
    }

    private var paymentModeBinding: Binding<PaymentMode> {
        Binding(
            get: { viewModel.paymentMode },
            set: { viewModel.setPaymentMode($0) }
        )
    }

    private func decimal(from text: String) -> Double? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        return Double(normalized)
    }

    private func financialActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
            .tint(viewModel.mode.theme.accentBackground)
    }

    private func syncFieldsFromModel() {
        cashFlowInitialAmountText = RPNNumberFormatter.formatDecimal(viewModel.cashFlowInitialAmount)
        npvRateText = ""
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

                        aboutCard(title: "Developer", metrics: metrics) {
                            if let developerProfileURL {
                                Link("@flatherskevin", destination: developerProfileURL)
                                    .font(.system(size: metrics.bodyFontSize, weight: .semibold, design: .rounded))
                                    .tint(.white)
                            }
                        }

                        aboutCard(title: "Version", metrics: metrics) {
                            Text(versionText)
                                .font(.system(size: metrics.bodyFontSize, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.88))
                        }

                        aboutCard(title: "Links", metrics: metrics) {
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

            Text("Minimal reverse polish notation calculator for iPhone and iPad with Standard, Binary, Hex, and Financial modes.")
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

    private func aboutCard<Content: View>(title: String, metrics: PrivacyPolicyLayoutMetrics, @ViewBuilder content: () -> Content) -> some View {
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
