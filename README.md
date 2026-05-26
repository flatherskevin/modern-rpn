# modern-rpn
Modern RPN is an iPhone and iPad RPN calculator with four modes:

- `Standard` for everyday decimal calculation
- `Binary` for base-2 entry and conversion
- `Hex` for hexadecimal entry and conversion
- `Financial` for TVM workflows with additional financial tools

The app stores history and session state locally on device. Financial mode also includes a tools sheet for advanced functions such as `CLx`, `R↓`, `EEX`, `BEGIN/END`, `STO/RCL`, cash flows with `NPV` and `IRR`, amortization, percent tools, date math, and bond calculations.

## Screenshot Workflow

Use the scenario-driven capture scripts when you need to regenerate App Store screenshots or add a new one.

Capture the full manifest:

```bash
scripts/capture-screenshots.sh
```

Capture one scenario on one simulator:

```bash
scripts/capture-screenshot.sh \
  --scenario standard-mode-division \
  --device "iPhone SE (3rd generation)" \
  --output screenshots/iphone/standard-mode-division.png \
  --profile phone
```

How it works:

- The app reads `-modern-rpn-screenshot-scenario <name>` on launch.
- Screenshot launches use an isolated `UserDefaults` suite, so captures never depend on stale simulator state.
- `scripts/screenshot-manifest.tsv` is the batch source of truth for device/output combinations.
- Captures are resized in place to the App Store target size, so each scenario produces one canonical PNG.

To add a new screenshot:

1. Add a new `ScreenshotScenario` case and definition in [Modern_RPNApp.swift](Modern%20RPN/Modern_RPNApp.swift).
2. Add one or more lines to [scripts/screenshot-manifest.tsv](scripts/screenshot-manifest.tsv).
3. Run `scripts/capture-screenshots.sh` or capture the new scenario directly.
