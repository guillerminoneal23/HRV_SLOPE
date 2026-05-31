# PHASE_1_5_AUDIT_REPORT.md

## Summary

Phase 1.5 Scientific Audit Gate is complete. The calculation engine now has explicit recovery-window timing, stable population nomogram presets, band-based classification, revised individual nomogram confidence rules, and pure RR interval quality control foundations. No Phase 2 UI/import work was started.

## Files Inspected

- `hrv_slope_app/lib/shared/engine/slope_calculator.dart`
- `hrv_slope_app/lib/shared/engine/rmssd_calculator.dart`
- `hrv_slope_app/lib/shared/engine/nomogram_engine.dart`
- `hrv_slope_app/lib/shared/engine/statistics.dart`
- `hrv_slope_app/lib/core/constants/hrv_constants.dart`
- `hrv_slope_app/lib/core/errors/hrv_errors.dart`
- `hrv_slope_app/lib/data/database/tables/tables.dart`
- `hrv_slope_app/lib/data/database/app_database.dart`
- `hrv_slope_app/test/engine_test.dart`
- `hrv_slope_app/test/widget_test.dart`
- `ALGORITHM_SPEC.md`
- `DATA_MODEL.md`
- `PROJECT_SPEC.md`
- `IMPLEMENTATION_PLAN.md`

## Changes Made

- Added `RecoveryWindow` with start, end, duration, and slope-time validation.
- Added `computeSlopeForRecoveryWindow()` and expanded `SlopeResult` with interpreted slope and recovery-window metadata.
- Preserved fallback exercise RMSSD flag behavior.
- Added explicit population nomogram presets:
  - `paper_original_2019`
  - `excel_operational`
- Made `excel_operational` the explicit app default.
- Replaced population interpretation with piecewise monotonic log-linear interpolation between source points.
- Added explicit warnings for intensity values outside source preset ranges.
- Added full `NomogramClassificationResult` including model source, preset, expected bands, residuals, classification, and warnings.
- Revised classification to compare observed interpreted slope against expected lower/mean/upper bands.
- Added `IndividualNomogramConfidence` rules and hybrid weight helpers.
- Added `HybridNomogramResult` with both population and individual expected slope fields.
- Added `rr_quality.dart` with `RrQualityReport`, `RrQualityFlag`, and `assessRrQuality()`.
- Added `computeRmssdForValidatedWindow()` for quality-gated 5-minute RMSSD windows.
- Generated Drift files with `build_runner` so analyzer can inspect the project cleanly.
- Updated documentation for Phase 1.5 scientific behavior.

## Tests Added Or Updated

Tests now cover:

- Recovery windows 5-10, 10-15, and 25-30 using `t = 10`, `15`, and `30`.
- Invalid windows: 0-5, 5-9, 28-33, negative times, and end <= start.
- Fallback and measured exercise RMSSD flags.
- Raw slope and interpreted slope preservation.
- Population nomogram stability at 40, 50, 60, 64, 70, 75, 80, 83, 90, 100, 110, 120, 130.
- Population preset availability and default preset.
- Band-based classification and residual percent.
- Classification using interpreted slope when raw slope is below 0.1.
- Out-of-range intensity warnings.
- Individual confidence thresholds.
- Hybrid weights and source behavior.
- RR quality-control validity, warning, and invalid cases.
- Quality-gated RMSSD rejection for invalid RR windows.

## Final Test Count

- 68/68 tests passing.

## Verification Commands

Run from `C:\Users\Guillermo\Downloads\HRV Slope_App\hrv_slope_app`:

```powershell
C:\flutter\bin\cache\dart-sdk\bin\dart.exe format lib\shared\engine\slope_calculator.dart lib\shared\engine\nomogram_engine.dart lib\shared\engine\rmssd_calculator.dart lib\shared\engine\rr_quality.dart lib\core\constants\hrv_constants.dart test\engine_test.dart
C:\flutter\bin\cache\dart-sdk\bin\dart.exe run build_runner build --delete-conflicting-outputs
C:\flutter\bin\cache\dart-sdk\bin\dart.exe C:\flutter\bin\cache\flutter_tools.snapshot analyze
C:\flutter\bin\cache\dart-sdk\bin\dart.exe C:\flutter\bin\cache\flutter_tools.snapshot test
```

Result:

- `dart format`: completed.
- `build_runner`: completed; wrote generated Drift outputs.
- `flutter analyze`: no issues found.
- `flutter test`: 68/68 passing.

## Nomogram Stability Table

Default preset: `excel_operational`

Strategy: piecewise monotonic log-linear interpolation with explicit extrapolation warnings outside 60-100%.

| Intensity % | Expected lower | Expected mean | Expected upper | Warning |
|---:|---:|---:|---:|---|
| 40 | 4.096 | 6.706 | 8.611 | outside source range |
| 50 | 1.619 | 3.182 | 4.631 | outside source range |
| 60 | 0.640 | 1.510 | 2.490 | none |
| 64 | 0.442 | 1.121 | 1.943 | none |
| 70 | 0.253 | 0.717 | 1.339 | none |
| 75 | 0.159 | 0.494 | 0.982 | none |
| 80 | 0.100 | 0.340 | 0.720 | none |
| 83 | 0.100 | 0.323 | 0.678 | none |
| 90 | 0.100 | 0.286 | 0.588 | none |
| 100 | 0.100 | 0.240 | 0.480 | none |
| 110 | 0.100 | 0.202 | 0.392 | outside source range |
| 120 | 0.100 | 0.169 | 0.320 | outside source range |
| 130 | 0.100 | 0.142 | 0.261 | outside source range |

Validation:

- `upper >= mean >= lower` at every evaluated intensity.
- `lower >= 0.1` at every evaluated intensity.
- Lower, mean, and upper curves are monotonic non-increasing over the evaluated range.
- Values at 40-60 are high due extrapolation but not numerically explosive.
- Out-of-range intensities produce warnings and are not silently interpreted.

## Selected Population Nomogram Strategy

Selected strategy: piecewise monotonic log-linear interpolation.

Reason:

- The previous unconstrained lower exponential fit had `a` near 1,000,000, which is a stability warning even though clamping masked part of the behavior.
- The source data contains only three points per preset, so an exact exponential fit is fragile.
- Log-linear interpolation preserves positivity, monotonicity, and source-point fidelity.
- Explicit extrapolation warnings are clearer and more scientifically defensible than silently extending a fitted curve beyond sparse data.

## Slope Timing Audit Finding

A timing-model gap existed. The prior slope API accepted a single `recoveryTimeMin`, so it could compute with `t` but could not prove that the HRV quantification window was exactly 5 minutes, started after the first 5 minutes, and ended within 30 minutes. Phase 1.5 added `RecoveryWindow` validation to close that gap.

## Known Limitations

- Population bands outside each preset source range are extrapolated with warnings; they should be interpreted cautiously.
- Individual nomogram fitting still uses a simple constrained exponential optimizer; confidence rules now prevent individual-only use unless data support is robust.
- RR quality control estimates artifacts by threshold only and does not correct data.
- `computeRmssd()` remains the low-level mathematical function; `computeRmssdForValidatedWindow()` is the quality-gated entry point for 5-minute HRV windows.
- Database schema was not expanded for RR quality persistence in Phase 1.5; Phase 2 import design should decide where quality reports belong.

## Next Recommendation For Phase 2

Start the import/manual-entry workflow only after wiring these validation functions into the data-entry path. Phase 2 should require explicit recovery-window start/end fields, show the exercise RMSSD fallback state, run RR quality control before accepting RR-derived RMSSD, and surface nomogram range warnings in previews before saving sessions.
