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
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: height)
            .background {
                Group {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(color)
                }
                .overlay {
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(borderColor, lineWidth: mode == .financial ? 1 : 0)
                }
            }
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(.spring(response: 0.16, dampingFraction: 0.72), value: configuration.isPressed)
    }

    private var pressedScale: CGFloat {
        span > 1 ? 1.06 : 1.2
    }

    private var cornerRadius: CGFloat {
        span == 1 ? 24 : 30
    }

    private var borderColor: Color {
        .clear
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = CalculatorViewModel()
    @State private var showingHistory = false
    @State private var showingPrivacyPolicy = false
    @State private var showingFinancialTools = false

    var body: some View {
        GeometryReader { geometry in
            let mode = viewModel.mode
            let topPadding: CGFloat = mode.layoutStyle == .financialLandscape ? 8 : 12
            let bottomPadding = max(8, geometry.safeAreaInsets.bottom + 4)

            ZStack {
                CalculatorColor.background
                    .ignoresSafeArea()

                calculatorLayout(in: geometry, topPadding: topPadding, bottomPadding: bottomPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 16)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
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
    private func calculatorLayout(in geometry: GeometryProxy, topPadding: CGFloat, bottomPadding: CGFloat) -> some View {
        switch viewModel.mode.layoutStyle {
        case .standard:
            let buttonHeight = keypadButtonHeight(
                screenHeight: geometry.size.height,
                topPadding: topPadding,
                bottomPadding: bottomPadding,
                rowCount: viewModel.mode.keypadRows.count
            )

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
        case .financialLandscape:
            let headerHeight: CGFloat = 54
            let bodyAvailableHeight = max(260, geometry.size.height - topPadding - bottomPadding - headerHeight)

            VStack(spacing: 10) {
                header
                financialCalculatorBody(
                    availableWidth: geometry.size.width - 32,
                    availableHeight: bodyAvailableHeight
                )
                    .frame(maxHeight: .infinity, alignment: .top)
            }
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

            Group {
                if viewModel.mode == .financial {
                    Button {
                        showingFinancialTools = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(CalculatorColor.displayText)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Financial Tools")
                    .accessibilityIdentifier("financial-tools-button")
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
        }
    }

    private var stackPanel: some View {
        Group {
            if viewModel.mode == .financial {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.stackLines, id: \.self) { line in
                            Text(line)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundStyle(CalculatorColor.stackText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.financialRegisterLines, id: \.self) { line in
                            Text(line)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundStyle(CalculatorColor.stackText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.stackLines, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .foregroundStyle(CalculatorColor.stackText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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

    private var display: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(viewModel.errorMessage ?? "")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.red.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)
                .frame(height: 16)

            Text(viewModel.displayText)
                .font(.system(size: viewModel.mode == .financial ? 72 : 96, weight: .light, design: .monospaced))
                .foregroundStyle(CalculatorColor.displayText)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.35)
                .frame(minHeight: 88, alignment: .bottomTrailing)
                .accessibilityIdentifier("display-value")
        }
        .padding(.horizontal, 6)
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
                display
                    .frame(width: 188)
            }

            buttonGrid(buttonHeight: buttonHeight)
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

    private func buttonGrid(buttonHeight: CGFloat) -> some View {
        Grid(
            horizontalSpacing: 6,
            verticalSpacing: 6
        ) {
            ForEach(Array(viewModel.mode.keypadRows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(row) { button in
                        if let kind = CalculatorButtonKind.make(for: button, mode: viewModel.mode) {
                            Button(action: action(for: button.role)) {
                                buttonLabelView(for: button, kind: kind)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(button.label)
                            .buttonStyle(
                                CalculatorPressStyle(
                                    mode: viewModel.mode,
                                    color: kind.fillColor(for: viewModel.mode),
                                    span: button.span,
                                    height: buttonHeight
                                )
                            )
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
    private func buttonLabelView(for button: CalculatorButtonSpec, kind: CalculatorButtonKind) -> some View {
        if let symbolName = operatorSymbolName(button.label) {
            Image(systemName: symbolName)
                .font(.system(size: buttonFontSize(button.label), weight: .semibold))
                .foregroundStyle(kind.textColor(for: viewModel.mode))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            Text(button.label)
                .font(.system(size: buttonFontSize(button.label), weight: .medium, design: .rounded))
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

    private func buttonFontSize(_ label: String) -> CGFloat {
        if viewModel.mode == .financial {
            if ["÷", "×", "−", "+"].contains(label) { return 30 }
            if label == "ENTER" { return 28 }
            if ["PV", "PMT", "FV", "AC", "POP", "CHS"].contains(label) { return 22 }
            if label == "x↔y" { return 18 }
            return 28
        }
        if ["÷", "×", "−", "+"].contains(label) { return 44 }
        if label == "ENTER" { return 28 }
        if ["PV", "PMT", "FV"].contains(label) { return 24 }
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
        bottomPadding: CGFloat,
        rowCount: Int
    ) -> CGFloat {
        let rowCount = CGFloat(rowCount)
        let reservedHeight = topPadding + bottomPadding + 44 + 84 + 120 + 24
        let availableHeight = screenHeight - reservedHeight - (max(0, rowCount - 1) * 6)
        let fittedHeight = floor(availableHeight / rowCount)

        return min(76, max(56, fittedHeight))
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
