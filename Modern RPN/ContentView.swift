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
}

private struct CalculatorButtonStyle {
    let label: String
    let span: Int
    let color: Color
    let textColor: Color
    let action: () -> Void

    init(
        label: String,
        span: Int = 1,
        color: Color,
        textColor: Color,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.span = span
        self.color = color
        self.textColor = textColor
        self.action = action
    }
}

private struct CalculatorPressStyle: ButtonStyle {
    let color: Color
    let span: Int

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: 76)
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
        ZStack {
            CalculatorColor.background
                .ignoresSafeArea()

            VStack(spacing: 4) {
                header
                stackPanel
                display
                    .padding(.top, -10)
                buttonGrid
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(store: viewModel.historyStore)
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
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(viewModel.mode == .basic ? "Modern RPN" : "Modern RPN Scientific")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(CalculatorColor.stackText)
                .frame(maxWidth: .infinity, alignment: .center)

            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 44)
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
                .minimumScaleFactor(0.4)
                .frame(height: 88, alignment: .bottomTrailing)
                .accessibilityIdentifier("display-value")
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 0)
    }

    private var buttonGrid: some View {
        let rows: [[CalculatorButtonStyle]] = [
            [
                .init(label: "⌫", color: CalculatorColor.utilityButton, textColor: .black, action: viewModel.backspace),
                .init(label: "AC", color: CalculatorColor.utilityButton, textColor: .black, action: viewModel.clearAll),
                .init(label: "POP", color: CalculatorColor.utilityButton, textColor: .black, action: viewModel.drop),
                .init(label: "X/Y", color: CalculatorColor.utilityButton, textColor: .black, action: viewModel.swap)
            ],
            [
                .init(label: "7", color: CalculatorColor.numberButton, textColor: .white, action: { viewModel.tapDigit("7") }),
                .init(label: "8", color: CalculatorColor.numberButton, textColor: .white, action: { viewModel.tapDigit("8") }),
                .init(label: "9", color: CalculatorColor.numberButton, textColor: .white, action: { viewModel.tapDigit("9") }),
                .init(label: "÷", color: CalculatorColor.operatorButton, textColor: .white, action: { viewModel.perform(.divide) })
            ],
            [
                .init(label: "4", color: CalculatorColor.numberButton, textColor: .white, action: { viewModel.tapDigit("4") }),
                .init(label: "5", color: CalculatorColor.numberButton, textColor: .white, action: { viewModel.tapDigit("5") }),
                .init(label: "6", color: CalculatorColor.numberButton, textColor: .white, action: { viewModel.tapDigit("6") }),
                .init(label: "×", color: CalculatorColor.operatorButton, textColor: .white, action: { viewModel.perform(.multiply) })
            ],
            [
                .init(label: "1", color: CalculatorColor.numberButton, textColor: .white, action: { viewModel.tapDigit("1") }),
                .init(label: "2", color: CalculatorColor.numberButton, textColor: .white, action: { viewModel.tapDigit("2") }),
                .init(label: "3", color: CalculatorColor.numberButton, textColor: .white, action: { viewModel.tapDigit("3") }),
                .init(label: "−", color: CalculatorColor.operatorButton, textColor: .white, action: { viewModel.perform(.subtract) })
            ],
            [
                .init(label: "+/−", color: CalculatorColor.utilityButton, textColor: .black, action: viewModel.toggleSign),
                .init(label: "0", color: CalculatorColor.numberButton, textColor: .white, action: { viewModel.tapDigit("0") }),
                .init(label: ".", color: CalculatorColor.numberButton, textColor: .white, action: viewModel.tapDecimal),
                .init(label: "+", color: CalculatorColor.operatorButton, textColor: .white, action: { viewModel.perform(.add) })
            ],
            [
                .init(label: "ENTER", span: 4, color: CalculatorColor.enterButton, textColor: .white, action: viewModel.enter)
            ]
        ]

        return Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, button in
                        Button(action: button.action) {
                            buttonLabelView(for: button)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(button.label)
                        .buttonStyle(CalculatorPressStyle(color: button.color, span: button.span))
                        .gridCellColumns(button.span)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func buttonLabelView(for button: CalculatorButtonStyle) -> some View {
        if let symbolName = operatorSymbolName(button.label) {
            Image(systemName: symbolName)
                .font(.system(size: buttonFontSize(button.label), weight: .semibold))
                .foregroundStyle(button.textColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            Text(button.label)
                .font(.system(size: buttonFontSize(button.label), weight: .medium, design: .rounded))
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .foregroundStyle(button.textColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func buttonFontSize(_ label: String) -> CGFloat {
        if ["÷", "×", "−", "+"].contains(label) { return 44 }
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
}

private struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: HistoryStore

    var body: some View {
        NavigationStack {
            List {
                if store.entries.isEmpty {
                    Text("No history yet")
                        .foregroundStyle(.white.opacity(0.75))
                        .listRowBackground(CalculatorColor.historyBackground)
                }

                ForEach(store.entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.expression)
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                        Text("= \(RPNCalculator.format(entry.result))")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(.white)
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(CalculatorColor.historyBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(CalculatorColor.historyBackground)
            .foregroundStyle(.white)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") { store.clear() }
                        .disabled(store.entries.isEmpty)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private let sections = PrivacyPolicyContent.sections

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(PrivacyPolicyContent.intro)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))

                    ForEach(sections) { section in
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
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private enum PrivacyPolicyContent {
    static let intro = "Effective date: March 11, 2026\n\nModern RPN is designed to work entirely on your device. It does not require an account and does not send your calculator activity to the developer or to third parties."

    static let sections: [PrivacyPolicySection] = [
        .init(
            title: "Information We Store",
            paragraphs: [
                "Modern RPN does not collect personal information through developer-operated servers, analytics systems, advertising SDKs, or third-party tracking tools.",
                "To provide the in-app History feature, the app stores limited information locally on your device."
            ],
            bullets: [
                "Calculation history, including expressions, results, timestamps, and stack snapshots."
            ]
        ),
        .init(
            title: "How Information Is Used",
            paragraphs: [
                "Locally stored calculation history is used only to show your history inside the app."
            ],
            bullets: [
                "No advertising use",
                "No marketing use",
                "No analytics or profiling",
                "No cross-app or cross-site tracking"
            ]
        ),
        .init(
            title: "Sharing",
            paragraphs: [
                "Modern RPN does not sell, rent, share, or otherwise disclose your data to the developer, advertisers, analytics providers, or other third parties through the app."
            ]
        ),
        .init(
            title: "Retention and Deletion",
            paragraphs: [
                "Your calculation history remains on your device until you delete it.",
                "You can clear stored history at any time from the History screen. Removing the app also removes the app's local data, subject to how your device and backups are managed by Apple.",
                "Because Modern RPN does not maintain developer-accessible user accounts or servers that store your app data, the developer cannot access, correct, export, or delete your local history remotely."
            ]
        ),
        .init(
            title: "Permissions and Sensitive Data",
            paragraphs: [
                "Modern RPN does not request access to location, contacts, photos, camera, microphone, health data, tracking, or similar sensitive device permissions."
            ]
        ),
        .init(
            title: "Children's Privacy",
            paragraphs: [
                "Modern RPN is not directed to children under 13, and the app does not knowingly collect personal information from children."
            ]
        ),
        .init(
            title: "Security",
            paragraphs: [
                "Modern RPN is designed to reduce privacy risk by keeping calculation history on device and not transmitting it to the developer or third parties through the app.",
                "No method of electronic storage is guaranteed to be completely secure, but the app is intentionally limited to local storage for its core functionality."
            ]
        ),
        .init(
            title: "Policy Changes",
            paragraphs: [
                "This privacy policy is intended to reflect Modern RPN's current privacy practices as accurately as reasonably possible based on the developer's knowledge of the app.",
                "If an inaccuracy, omission, or mismatch between this policy and the app's actual behavior is identified, the developer intends to correct the issue when reasonably possible, either by updating the app's behavior or by revising this privacy policy.",
                "Any policy updates will be reflected in the app with a revised effective date. If a future version of Modern RPN adds features that collect, transmit, or share data, this privacy policy will be updated before those changes are released."
            ]
        ),
        .init(
            title: "Contact",
            paragraphs: [
                "Privacy questions about Modern RPN can be directed to your published support or privacy contact."
            ]
        )
    ]
}

private struct PrivacyPolicySection: Identifiable {
    let id = UUID()
    let title: String
    var paragraphs: [String]
    var bullets: [String] = []
}

#Preview {
    ContentView()
}
