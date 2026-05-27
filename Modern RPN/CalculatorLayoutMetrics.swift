import SwiftUI

struct CalculatorLayoutMetrics {
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let horizontalPadding: CGFloat
    let contentSpacing: CGFloat
    let buttonSpacing: CGFloat
    let headerHeight: CGFloat
    let stackPanelHeight: CGFloat
    let buttonHeight: CGFloat
    let buttonGridHeight: CGFloat
    let displayAreaHeight: CGFloat
    let headerButtonSize: CGFloat
    let modeBadgeMinWidth: CGFloat
    let modeBadgeMinHeight: CGFloat
    let stackFontSize: CGFloat
    let stackSpacing: CGFloat
    let stackPanelPadding: CGFloat
    let stackRowCount: Int
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
        rowCount: Int,
        stackRowCount: Int = 4
    ) -> CalculatorLayoutMetrics {
        let compactWidth = screenSize.width <= 350
        let compactHeight = screenSize.height <= 700
        let compactLayout = compactWidth || compactHeight || rowCount >= 7
        let denseKeypad = rowCount >= 7

        let horizontalPadding: CGFloat = compactWidth ? 12 : 16
        let buttonSpacing: CGFloat = compactLayout ? 4 : 6
        let contentSpacing: CGFloat = compactHeight ? 6 : (compactLayout ? 8 : 12)
        let headerButtonSize: CGFloat = compactLayout ? 40 : 44
        let headerHeight = headerButtonSize
        let stackFontSize: CGFloat = compactHeight ? 12 : (compactLayout ? 13 : 15)
        let stackSpacing: CGFloat = compactHeight ? 2 : (compactLayout ? 3 : 4)
        let stackPanelPadding: CGFloat = compactHeight ? 6 : (compactLayout ? 8 : 10)
        let visibleStackRows = max(1, stackRowCount)
        let minimumStackRowHeight = stackFontSize * 1.3
        let intrinsicStackPanelHeight = (minimumStackRowHeight * CGFloat(visibleStackRows)) + (stackSpacing * CGFloat(max(0, visibleStackRows - 1))) + (stackPanelPadding * 2)
        let displayErrorHeight: CGFloat = compactHeight ? 12 : (compactLayout ? 14 : 16)
        let displayErrorFontSize: CGFloat = compactHeight ? 12 : (compactLayout ? 13 : 14)

        let availableWidth = max(0, screenSize.width - (horizontalPadding * 2))
        let columnCount: CGFloat = 4
        let cellWidth = max(0, (availableWidth - (buttonSpacing * (columnCount - 1))) / columnCount)
        let widthBasedHeight = min(compactLayout ? 74 : 78, max(44, floor(cellWidth * 0.86)))

        let displayFontSize: CGFloat
        let displayMinHeight: CGFloat
        if compactHeight {
            displayFontSize = 64
            displayMinHeight = 48
        } else if compactLayout {
            displayFontSize = 84
            displayMinHeight = 72
        } else {
            displayFontSize = 96
            displayMinHeight = 88
        }

        let displayContentMinHeight = displayErrorHeight + displayMinHeight + 8
        let preferredStackRatio: CGFloat = compactHeight ? 0.14 : 0.16
        let stackPanelHeight = max(
            intrinsicStackPanelHeight,
            min(screenSize.height * preferredStackRatio, compactHeight ? 120 : 150)
        )
        let preferredDisplayRatio: CGFloat
        switch rowCount {
        case ...4:
            preferredDisplayRatio = compactHeight ? 0.16 : 0.18
        case 5...6:
            preferredDisplayRatio = compactHeight ? 0.16 : 0.18
        default:
            preferredDisplayRatio = compactHeight ? 0.11 : 0.13
        }
        let preferredDisplayHeight = max(
            displayContentMinHeight,
            min(screenSize.height * preferredDisplayRatio, compactHeight ? 144 : 200)
        )

        let topPadding: CGFloat = compactHeight ? 6 : (compactLayout ? 8 : 12)
        let bottomPadding = max(
            compactHeight ? 8 : (compactLayout ? 6 : 8),
            safeAreaBottom + (compactHeight ? 6 : (compactLayout ? 2 : 4))
        )
        let reservedHeight = topPadding + bottomPadding + headerHeight + stackPanelHeight + (contentSpacing * 3)
        // Solve the screen as a vertical budget first so the keypad can never push ENTER past the safe area.
        let verticalBudget = max(0, screenSize.height - reservedHeight)
        let gridSpacingHeight = buttonSpacing * CGFloat(max(0, rowCount - 1))
        let heightLimitedButton = floor(
            (verticalBudget - preferredDisplayHeight - gridSpacingHeight) / CGFloat(rowCount)
        )
        let minimumButtonHeight: CGFloat = denseKeypad ? 42 : 44
        let keypadHeightCap: CGFloat
        switch rowCount {
        case ...4:
            // Standard and binary share the same button family on short screens.
            keypadHeightCap = compactHeight ? 60 : 64
        case 5...6:
            keypadHeightCap = compactHeight ? 60 : 64
        default:
            // Hex is the busiest layout, so it gets its own cap tuning.
            keypadHeightCap = compactHeight ? 60 : 66
        }
        let buttonHeight = max(minimumButtonHeight, min(widthBasedHeight, heightLimitedButton, keypadHeightCap))
        let buttonGridHeight = (buttonHeight * CGFloat(rowCount)) + gridSpacingHeight
        // Any leftover height stays in the display area rather than becoming a dead gap above the keypad.
        let displayAreaHeight = max(displayContentMinHeight, verticalBudget - buttonGridHeight)

        return CalculatorLayoutMetrics(
            topPadding: topPadding,
            bottomPadding: bottomPadding,
            horizontalPadding: horizontalPadding,
            contentSpacing: contentSpacing,
            buttonSpacing: buttonSpacing,
            headerHeight: headerHeight,
            stackPanelHeight: stackPanelHeight,
            buttonHeight: buttonHeight,
            buttonGridHeight: buttonGridHeight,
            displayAreaHeight: displayAreaHeight,
            headerButtonSize: headerButtonSize,
            modeBadgeMinWidth: compactLayout ? 104 : 112,
            modeBadgeMinHeight: compactLayout ? 34 : 36,
            stackFontSize: stackFontSize,
            stackSpacing: stackSpacing,
            stackPanelPadding: stackPanelPadding,
            stackRowCount: visibleStackRows,
            displayErrorFontSize: displayErrorFontSize,
            displayErrorHeight: displayErrorHeight,
            displayFontSize: displayFontSize,
            displayMinHeight: displayMinHeight,
            enterFontSize: compactHeight ? 22 : (compactLayout ? 24 : 28),
            buttonFontSize: compactHeight ? 28 : (compactLayout ? 30 : 34),
            operatorFontSize: compactHeight ? 34 : (compactLayout ? 38 : 44),
            prefersScrollFallback: denseKeypad
        )
    }
}
