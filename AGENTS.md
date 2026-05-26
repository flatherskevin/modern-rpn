# AGENTS.md

This repository is a small SwiftUI iOS app. The main UI surface lives in `Modern RPN/ContentView.swift`, with calculator sizing rules in `Modern RPN/CalculatorLayoutMetrics.swift` and calculator behavior in `Modern RPN/RPNCalculator.swift` plus `Modern RPN/CalculatorMode.swift`.

## Core UI Rules

Use math-first layout, not trial-and-error.

- Treat the calculator as a vertical budget problem:
  `availableHeight = screenHeight - safeAreas - outer paddings`
- Every visible section must have an explicit occupied height:
  `header + stackCard + display + keypad + inter-section spacing <= availableHeight`
- Do not rely on “leftover space” expansion such as unconstrained `Spacer()` or `maxHeight: .infinity` to make the calculator look right.
- Do not introduce fixed layout hacks that only happen to work on one mode or one screen.
- Only use the simulator after the height/width math is coherent.

## Calculator Layout Invariants

- The keypad must never clip off-screen in any mode.
- `ENTER` must always remain fully visible.
- The stack card must be top-justified and must not jump vertically between modes.
- The stack card height should be allocated deliberately by metrics, not by intrinsic text height alone.
- The display gap above the keypad should be minimized on dense screens; unused vertical budget should go to keypad height first.
- Standard and binary should share similar button sizing.
- Hex is the busiest screen and should be treated as the stress case for compact-height layout.

## Button Interaction Rules

- Press zoom must never render underneath neighboring buttons.
- If using scale on press, keep it small and raise the pressed button above siblings with `zIndex`.
- Button shape should stay in the rounded-rectangle family, not drift into pill/oval shapes.
- Button corner radius should be derived from button height, not hard-coded independently of size.

## Display Rules

- Value-row font parity matters more than nominal font constants.
- If one mode looks smaller, assume fit-based scaling is the cause before changing the base font.
- Prefer hard representational limits over letting the renderer shrink into unreadable text or ellipses.
- Never allow ellipses in calculator value display for radix modes.

## Mode-Specific Constraints

These are behavior constraints, not just visual preferences.

- Binary:
  - strict single-line display
  - hard limit of `15` characters
  - no wrap
  - no ellipsis
  - reject input, mode switches, restores, or operation results that exceed the limit
- Hex:
  - hard width limit exists to preserve value-row font parity
  - reject input, mode switches, restores, or operation results that exceed the current limit in `CalculatorMode`
- Standard:
  - may use more keypad space than before if available
  - should be the visual baseline for stack sizing and sparse-keypad button height

When changing radix limits, update both:

- input append rules in `CalculatorMode`
- value representability checks used by `RPNCalculator`

## State / Model Rules

- `CalculatorMode.canRepresent(_:)` is the source of truth for whether a value may exist in a mode.
- Mode switches must be blocked if current stack values cannot be represented in the target mode.
- `enter()` must reject values that violate current mode limits.
- Binary operations must reject results that violate current mode limits.
- Restored sessions must be sanitized so old invalid state cannot reopen into broken UI.

## Where To Change Things

- Layout math: `Modern RPN/CalculatorLayoutMetrics.swift`
- Calculator surface layout and interaction: `Modern RPN/ContentView.swift`
- Mode limits / formatting / representability: `Modern RPN/CalculatorMode.swift`
- Calculator state transitions and operation validation: `Modern RPN/RPNCalculator.swift`

## Preferred Change Strategy

When touching calculator layout:

1. Start with the vertical budget equation.
2. Compute the dense (`hex`) case first.
3. Verify sparse (`standard` / `binary`) cases do not diverge visually unless intended.
4. Avoid introducing mode-specific visual hacks in the view layer when the real issue is representability or fitting.
5. Rebuild after each coherent change:
   `xcodebuild build -project 'Modern RPN.xcodeproj' -scheme 'Modern RPN' -sdk iphonesimulator`

## Release / PR Rules

- When opening a PR, bump the app version in `Modern RPN.xcodeproj/project.pbxproj`.
- Update both version fields together:
  - `MARKETING_VERSION` for the user-facing app version
  - `CURRENT_PROJECT_VERSION` for the build number
- Version bumps belong on the same feature/fix PR by default.
- Only split version changes into a standalone branch/PR when the user explicitly asks for a standalone release/version PR.

## Avoid

- blind tuning via screenshots alone
- using `Spacer()` as a primary layout fix
- using unconstrained `.infinity` sizing inside stack or display sections
- allowing radix values to become unreadable and trusting `minimumScaleFactor` to rescue them
- hard-coding one-off sizes without checking how they affect the full height equation
