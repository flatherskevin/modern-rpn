# APP_STORE.md

## App Review Notes

**1. Description of the app's purpose**

Modern RPN is a reverse polish notation (RPN) calculator for iPhone and iPad.

**2. Description of the app's purpose, including the problem it solves and the value it provides its intended audience**

Modern RPN helps users perform stack-based calculations quickly and accurately without relying on parentheses. It is intended for people who prefer RPN workflows for everyday math, repeated calculations, programmer-style number conversion, and core time-value-of-money calculations. The current version includes `Standard`, `Binary`, `Hex`, and `Financial` modes, along with local history and session restore.

**3. Instructions for accessing and reviewing the app's main features, including any required test or login credentials**

- Launch the app to access the calculator immediately.
- No sign-up, login, account, or demo credentials are required.
- Use the mode control at the top of the screen to switch between `Standard`, `Binary`, `Hex`, and `Financial`.
- Use the keypad to enter values and perform calculations.
- Tap `ENTER` to push the current value onto the stack.
- Tap `+`, `−`, `×`, or `÷` to perform arithmetic on the top stack values.
- Tap `POP` to remove the top value, `X/Y` to swap the top two values, `⌫` to backspace while typing, `+/−` to change sign, and `AC` to clear all.
- The stack display shows the current `T`, `Z`, `Y`, and `X` values.
- In `Hex` mode, the keypad includes `A-F`.
- In `Binary` mode, the keypad is limited to `0` and `1`.
- In `Financial` mode, the main keypad provides `n`, `i`, `PV`, `PMT`, and `FV` for core TVM storage and solving.
- In `Financial` mode, tap the top-right tools button to open the financial tools sheet. That sheet includes:
  - `CLx`, `R↓`, and `EEX`
  - `BEGIN` / `END` payment mode
  - `STO` / `RCL` memory registers
  - cash flow entry with `NPV` and `IRR`
  - amortization
  - percent tools
  - date math
  - bond price and bond yield tools
- Open the top-left menu to access:
  - `History`: shows saved calculation history, supports filtering by `All`, `Standard`, `Binary`, `Hex`, or `Financial`, and allows deleting entries or clearing the current filter.
  - `Privacy Policy`: shows the in-app privacy policy.

**4. External services, tools, or platforms the app uses to deliver its core functionality**

- None. The app runs entirely on-device.
- It does not use external data providers, authentication services, payment processors, analytics, advertising SDKs, AI services, or third-party APIs.
- Calculation history, calculator session state, and financial worksheet state are stored locally using `UserDefaults`.

**5. Regional differences in the app's features or content**

- Core functionality is consistent across all regions.
- There are no region-specific features, content restrictions, or service dependencies.
- History timestamps may appear in the user's local date/time format based on device locale settings.
- The current app content is in English.

**6. Relevant documentation or credentials for highly regulated industries**

Not applicable. This app is a calculator and does not provide financial, medical, legal, gambling, or other regulated services.

## Supporting Details

This is a self-contained SwiftUI app with one calculator interface, a financial tools sheet, a history screen, and an in-app privacy policy. It does not include login flows, accounts, subscriptions, in-app purchases, web views, network API calls, or third-party SDKs.

The app currently exposes four calculator modes in the UI: `Standard`, `Binary`, `Hex`, and `Financial`. Financial mode includes on-device TVM solving plus a tools sheet for advanced financial functions. History entries include the calculation mode, and the History screen supports mode filtering. The app stores only local calculation history and calculator session state on the device. It does not request sensitive permissions such as location, camera, microphone, contacts, photos, tracking, or health data.

The app does not implement custom encryption or third-party cryptography libraries.
