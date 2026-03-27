# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-03-21

### Added
- Added dedicated calculator modes for `Standard`, `Binary`, and `Hex`.
- Added mode-aware parsing and formatting so calculations can be entered and displayed in decimal, binary, or hexadecimal form.
- Added a centered mode selector in the calculator header for switching modes.
- Added mode-specific keypad layouts for binary and hexadecimal entry.
- Added persistent app session restoration for the selected mode, current stack, and in-progress input.
- Added history metadata showing which mode each calculation was performed in.
- Added history filtering for `All`, `Standard`, `Binary`, and `Hex`.
- Added per-entry history deletion with swipe actions.
- Added filtered history clearing with confirmation prompts.
- Added shared mode theme styling so `Standard`, `Binary`, and `Hex` chips and badges can be styled consistently across the UI.

### Changed
- Changed the calculator layout to better fill the full vertical height of the device.
- Changed the header interaction design to use a cleaner, more minimal mode control.
- Changed hexadecimal and binary behavior to support arithmetic while preserving decimal fallback for fractional results.
- Changed history presentation to keep filtering controls attached to the header instead of reading like content rows.
- Changed history filter presentation to use a controlled custom menu so option order remains stable as `All`, `Standard`, `Binary`, `Hex`.
- Changed history badges, filter controls, and mode chips to use consistent mode color themes: neutral for `Standard`, green for `Binary`, and blue for `Hex`.
- Changed text and control styling in the history UI to improve readability and contrast on dark backgrounds.
- Changed the shared project version settings to prepare the `1.1.0` App Store build as build `2`.

### Fixed
- Fixed vertical spacing issues that left the calculator feeling short on taller devices.
- Fixed keypad sizing so the `ENTER` key remains visible on shorter screens.
- Fixed top-area spacing so the header aligns correctly with the safe area.
- Fixed history toolbar controls that could render with unreadable dark text after filter changes.
- Fixed history clear behavior so it operates on the active filter instead of always clearing everything.

## [1.0.0]

- Baseline repository state currently on `main`.
