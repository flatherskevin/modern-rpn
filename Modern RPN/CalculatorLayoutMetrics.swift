import SwiftUI

struct CalculatorLayoutMetrics {
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let horizontalPadding: CGFloat
    let contentSpacing: CGFloat
    let buttonSpacing: CGFloat
    let buttonHeight: CGFloat
    let headerButtonSize: CGFloat
    let modeBadgeMinWidth: CGFloat
    let modeBadgeMinHeight: CGFloat
    let stackFontSize: CGFloat
    let stackSpacing: CGFloat
    let stackPanelPadding: CGFloat
    let displayErrorFontSize: CGFloat
    let displayErrorHeight: CGFloat
    let displayFontSize: CGFloat
    let displayMinHeight: CGFloat
    let enterFontSize: CGFloat
    let buttonFontSize: CGFloat
    let operatorFontSize: CGFloat
    let prefersScrollFallback: Bool

    static func make(
        screenSize: CGSize,
        safeAreaBottom: CGFloat,
        rowCount: Int
    ) -> CalculatorLayoutMetrics {
        let compactWidth = screenSize.width <= 350
        let compactHeight = screenSize.height <= 700
        let compactLayout = compactWidth || compactHeight || rowCount >= 7
        let denseKeypad = rowCount >= 7

        let horizontalPadding: CGFloat = compactWidth ? 12 : 16
        let buttonSpacing: CGFloat = compactLayout ? 4 : 6
        let availableWidth = max(0, screenSize.width - (horizontalPadding * 2))
        let columnCount: CGFloat = 4
        let cellWidth = max(0, (availableWidth - (buttonSpacing * (columnCount - 1))) / columnCount)
        let widthBasedHeight = min(compactLayout ? 72 : 76, max(44, floor(cellWidth * (compactLayout ? 0.78 : 0.84))))
        let compactButtonCap: CGFloat
        if compactHeight {
            compactButtonCap = denseKeypad ? 46 : 50
        } else {
            compactButtonCap = compactLayout ? 72 : 76
        }
        let buttonHeight = min(widthBasedHeight, compactButtonCap)

        let displayFontSize: CGFloat
        let displayMinHeight: CGFloat
        if compactHeight {
            displayFontSize = denseKeypad ? 56 : 64
            displayMinHeight = denseKeypad ? 44 : 48
        } else if compactLayout {
            displayFontSize = 84
            displayMinHeight = 72
        } else {
            displayFontSize = 96
            displayMinHeight = 88
        }

        return CalculatorLayoutMetrics(
            topPadding: compactHeight ? 6 : (compactLayout ? 8 : 12),
            bottomPadding: max(compactHeight ? 8 : (compactLayout ? 6 : 8), safeAreaBottom + (compactHeight ? 6 : (compactLayout ? 2 : 4))),
            horizontalPadding: horizontalPadding,
            contentSpacing: compactHeight ? 6 : (compactLayout ? 8 : 12),
            buttonSpacing: buttonSpacing,
            buttonHeight: buttonHeight,
            headerButtonSize: compactLayout ? 40 : 44,
            modeBadgeMinWidth: compactLayout ? 104 : 112,
            modeBadgeMinHeight: compactLayout ? 34 : 36,
            stackFontSize: compactHeight ? 12 : (compactLayout ? 13 : 15),
            stackSpacing: compactHeight ? 2 : (compactLayout ? 3 : 4),
            stackPanelPadding: compactHeight ? 6 : (compactLayout ? 8 : 10),
            displayErrorFontSize: compactHeight ? 12 : (compactLayout ? 13 : 14),
            displayErrorHeight: compactHeight ? 12 : (compactLayout ? 14 : 16),
            displayFontSize: displayFontSize,
            displayMinHeight: displayMinHeight,
            enterFontSize: compactHeight ? 22 : (compactLayout ? 24 : 28),
            buttonFontSize: compactHeight ? 28 : (compactLayout ? 30 : 34),
            operatorFontSize: compactHeight ? 34 : (compactLayout ? 38 : 44),
            prefersScrollFallback: denseKeypad
        )
    }
}
