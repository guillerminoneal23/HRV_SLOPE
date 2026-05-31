# PROJECT_SPEC.md — HRV Slope App

## 1. Project Overview

**Name:** HRV Slope App  
**Purpose:** Local, private, multi-platform application for monitoring internal training load (ITL) through RMSSD-Slope analysis.  
**Platforms:** Windows (primary), iOS (secondary).  
**Privacy:** 100% offline — no backend, no cloud, no telemetry.

### Scientific Foundation
Based on:
- Naranjo Orellana, J. et al. (2019). *Recovery Slope of Heart Rate Variability as an Indicator of Internal Training Load.* Health, 11, 211–221.
- Ruso-Álvarez, J.F. et al. (2019). *Utility of the "RMSSD-Slope" to Assess the Internal Load in Different Sports Situations.* Health, 11, 683–691.
- Operational reference values from the "VALORACIÓN CARGA INTERNA.xlsx" workbook.

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| UI / App | Flutter 3.x + Dart |
| Local DB | SQLite via Drift (drift + sqlite3_flutter_libs) |
| State Mgmt | Riverpod 2.x |
| Charts | fl_chart |
| File I/O | file_picker, csv, spreadsheet_decoder |
| Math | dart:math, custom exponential fitting |
| Export | CSV generation; XLSX/PDF deferred |
| Testing | flutter_test, drift test utilities |

---

## 3. Architecture — Clean Architecture

```
lib/
├── core/                    # Cross-cutting: constants, errors, extensions
│   ├── constants/
│   ├── errors/
│   └── utils/
├── data/                    # Data layer: DB, DAOs, repositories impl
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── tables/
│   │   └── daos/
│   ├── datasources/
│   └── repositories/
├── domain/                  # Business logic: entities, repos (abstract), use cases
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── features/                # Feature modules
│   ├── athletes/
│   ├── import_wizard/
│   ├── individual_report/
│   ├── group_report/
│   ├── nomogram/
│   ├── longitudinal/
│   └── instructions/
├── presentation/            # Shared UI: theme, widgets, navigation
│   ├── theme/
│   ├── widgets/
│   └── navigation/
└── shared/                  # Shared services: calculation engine
    └── engine/
        ├── rmssd_calculator.dart
        ├── slope_calculator.dart
        ├── nomogram_engine.dart
        └── statistics.dart
```

---

## 4. Core Scientific Method

### RMSSD Calculation
```
RMSSD = sqrt( mean( (RR[i+1] - RR[i])² ) )
```

### RMSSD-Slope
```
RMSSD_Slope = (RMSSD_recovery − RMSSD_exercise) / t
```
Where:
- `RMSSD_recovery`: RMSSD from a 5-minute window during recovery (excluding first 5 min).
- `RMSSD_exercise`: RMSSD from the last 5 minutes of exercise. Fallback: 4 ms if not recorded.
- `t`: time in minutes from end of exercise to end of recovery measurement window.
- Minimum slope for graphical interpretation: 0.1 (raw value always preserved).
- **Lower slope → higher internal load; Higher slope → faster recovery / lower load.**
- Priority: Slope-10 (recovery window ending at 10 min post-exercise).
- Valid range: any 5-min window within 5–30 min post-exercise.

### Internal Training Load Index
```
ITL = 1 / slope_interpreted
```

---

## 5. Nomogram

### Population Nomogram (from papers + Excel)

| %Intensity | Slope-10 Min | Slope-10 Mean | Slope-10 Max |
|---|---|---|---|
| 60% (≈VT1 64%) | 0.64 | 1.51 | 2.49 |
| 80% (≈VT2 83%) | 0.10 | 0.34 | 0.72 |
| 100% (MAS/VAM) | 0.10 | 0.24 | 0.48 |

### Interpretation Ranges (from Excel INFORME INDIVIDUAL)

| %Intensity | Poor (MALO) | Good (BUENO) | Very Good (MUY BUENO) |
|---|---|---|---|
| <60% | <0.80 | 0.80–5.00 | >5.00 |
| 60–75% | <0.40 | 0.40–2.60 | >2.60 |
| 75–90% | <0.25 | 0.25–1.20 | >1.20 |
| >90% | <0.10 | 0.10–0.60 | >0.60 |

### Individual Nomogram
- Model: `slope = c + a * exp(b * intensity_percent)` with `c ≥ 0.1`, `b < 0`, `a > 0`.
- Valid inputs: sessions with `intensity_percent` and `slope_interpreted`; raw slope is preserved but not used for fitting.
- Confidence levels:
  - insufficient: fewer than 6 valid sessions or fewer than 2 intensity zones.
  - initial: 6–8 valid sessions and at least 2 intensity zones.
  - acceptable: 9–11 valid sessions with low, medium, and high zones.
  - robust: 12+ valid sessions with low, medium, and high zones.
- Hybrid mode when confidence is initial or acceptable: blends population and individual expected slopes.
- Individual-only interpretation is reserved for robust confidence.

---

## 6. Required Screens

| # | Screen | Key Features |
|---|---|---|
| 1 | **Home / Athletes** | CRUD athletes, sport, profile, quick stats |
| 2 | **Import Wizard** | Manual entry, CSV/XLSX upload, RR intervals, variable tagging |
| 3 | **Individual Report** | Full session report with slope, nomogram point, auto-interpretation |
| 4 | **Group Report** | Compare subjects in same task, ranking, alerts |
| 5 | **Nomogram** | Population / Individual / Hybrid modes with interactive chart |
| 6 | **Longitudinal Panel** | Time-series: slope, intensity, RPE, rolling avgs, fatigue flags |
| 7 | **Instructions Book** | Full in-app manual with protocols, examples, limitations |

---

## 7. Data Requirements

### Minimum per session:
- ≥1 external load variable
- ≥1 internal load variable
- ≥1 HRV variable (or raw RR intervals to compute it)
- `intensity_percent` for nomogram X-axis (imported or calculated)

### Variable Model
Each measurement variable carries:
- `category`: external | internal | hrv | derived | context
- `name`, `unit`, `value`, `source`
- `is_primary_for_nomogram`: bool
- `notes`: optional

---

## 8. Constraints

- **No network access** — all data stays on device.
- **No telemetry** — no analytics, no crash reporting to external services.
- **All calculations must be pure functions** — testable without side effects.
- **Minimum test coverage** for engine: 100% of calculation functions.
- **Phased delivery** — no phase advances without passing tests.

---

## 9. Delivery Phases

| Phase | Scope |
|---|---|
| 1 | Flutter setup + architecture + DB + calculation engine + tests |
| 2 | Import wizard + manual entry + validations |
| 3 | Individual report + Group report + Population nomogram |
| 4 | Individual nomogram + Longitudinal panel |
| 5 | Instructions book + Export + Packaging |

---

## Phase 1.5 Scientific Audit Gate

Note: phase sections below are chronological history. Limitations or deferred
items mentioned in an earlier phase may have been completed in a later phase.

Phase 1.5 was added before Phase 2 UI/import work to stabilize the scientific engine.

Confirmed implementation decisions:

- Standard immediate-recovery slope calculation uses an explicit 5-minute recovery window ending within 30 minutes post-exercise.
- The slope denominator `t` is the end of the recovery window, not the 5-minute window duration.
- The first 5 minutes of recovery are excluded from HRV quantification.
- Raw slope and interpreted slope are both preserved; only interpreted slope is clamped to 0.1.
- The default population nomogram preset is `excel_operational`, with `paper_original_2019` also available.
- Population bands use piecewise monotonic log-linear interpolation with explicit warnings outside source intensity ranges.
- Classification is based on observed interpreted slope versus expected lower/mean/upper bands, not fixed intensity buckets alone.
- Individual nomogram confidence requires adequate session count and low/medium/high intensity spread.
- RR interval quality control exists as pure Dart engine code for future Phase 2 import validation.

No Phase 2 import wizard or report UI was started during this gate.

---

## Phase 2.2 RR/NN Preprocessing

Direct RMSSD input remains the primary workflow for field use with Elite HRV, Kubios, HRV Logger, Polar, Garmin, or similar tools.

RR interval input is an advanced workflow. Phase 2.2 adds auditable RR/NN preprocessing without raw ECG/PPG processing:

- range outlier detection
- Malik, Kamath, Karlsson, and Acar ectopic detection
- Kubios-inspired local median threshold detection
- optional linear interpolation correction
- raw RMSSD preservation
- corrected NN-derived RMSSD when correction is enabled
- artifact table and preprocessing metadata in the session preview
- summary persistence for audit

Correction is off by default. Users must explicitly enable corrected NN-derived RMSSD.

---

## Phase 2.3 Session Edit/Delete and Build Readiness

Phase 2.3 stabilizes practical session management before Phase 3 reports and nomogram visualizations.

Implemented:
- Session detail screen from athlete detail.
- Session edit flow for metadata, external/internal variables, direct RMSSD values, and recovery window.
- Recalculation on edit through the existing `RecoveryWindow` + `computeSlopeForRecoveryWindow()` preview path.
- Session delete confirmation with application-level cascade for HRV measurements, intensity variables, and session notes.
- Draft/incomplete session display rules: draft sessions are labeled and do not show slope/classification.
- Data-entry UX improvements for session cards, empty states, validation messages, and destructive actions.

No Phase 3 longitudinal charts, individual nomogram UI, or report/PDF export were started.

---

## Phase 2 Completion (2026-05-25)

Phase 2 delivered the MVP vertical slice with full manual session entry workflow.

Implemented:
- App shell with 4-tab navigation (Athletes, New Session, Import, Settings).
- Athlete CRUD with archive/unarchive, reference values (MAS, vVO₂max, MAP).
- 6-step session wizard: athlete → session info → external load → internal load → HRV → calculation preview + save.
- Intensity resolver with priority chain: %MAS → %vVO₂max → %MAP → speed/MAS → speed/vVO₂max → power/MAP.
- Calculation preview using RecoveryWindow + computeSlopeForRecoveryWindow() exclusively.
- CSV import with auto column mapping (including Spanish aliases), row validation, batch import.
- RR interval parser (pure Dart, multi-format).
- Settings screen with population nomogram preset selection.
- Database schema v2 (non-destructive migration).
- 104/104 tests passing.

Deferred: XLSX import, RR paste UI, session edit/delete, individual nomogram UI.

---

## Phase 2.1 Completion (2026-05-26)

Phase 2.1 implemented the dual HRV input system.

Implemented:
- Dual HRV input mode in Session Wizard: "Enter RMSSD directly" (default) and "Import/paste RR intervals".
- Direct RMSSD mode with source selector (Elite HRV, Kubios, HRV Logger, Polar, Garmin, Manual, Other).
- RR Intervals mode with paste text area, parse + quality assessment, RMSSD computation.
- Generic RMSSD CSV import mapper with auto column detection (date, RMSSD, exercise RMSSD, athlete, notes).
- Enhanced recovery window validation (0–5 rejected, duration must be 5 min, max end 30 min).
- Full HRV audit trail: hrv_input_mode, rmssd_recovery_source, rmssd_exercise_source, rr_quality_flag, rr_artifact_percent.
- Database schema v3 (non-destructive migration).
- 138/138 tests passing.

Deferred: XLSX import, session edit/delete, longitudinal charts, individual nomogram UI.

---

## Phase 3.0 Completion (2026-05-26)

Phase 3.0 delivered the individual report screen and population nomogram chart MVP.

Implemented:
- Individual report screen with 7 sections: header, data completeness/warnings, external load, internal load, HRV/RMSSD, slope result with interpretation, population nomogram chart.
- Population nomogram chart (fl_chart) with lower/mean/upper bands and session point overlay.
- Pure report builder function (IndividualReportData model).
- Classification interpretation text using neutral training-load language.
- Navigation: session detail → "Open Report" button.
- Preset from settings (excel_operational / paper_original_2019).
- Extrapolation warnings for out-of-range intensity.
- Draft session handling.
- 220/220 tests passing.
- Analyzer: no issues found.
- Schema unchanged (v4).

Deferred: longitudinal trend charts, individual nomogram fitting, PDF export, group analytics.

---

## Phase 3.1 Completion (2026-05-26)

Phase 3.1 completed the remaining original Phase 3 reporting scope.

Implemented:
- Reports tab in the app shell.
- Group report builder and screen.
- Group ranking by interpreted slope ascending, where lower slope indicates higher internal load.
- Group summary statistics: session count, athlete count, complete/ranked rows, mean/median/min/max slope, mean ITL, classification counts.
- Session warnings for missing intensity percent, missing HRV/slope data, draft rows, and preset range extrapolation.
- Standalone population nomogram screen.
- Multi-point nomogram chart support while preserving the individual report single-point API.
- Preset switching between `excel_operational` and `paper_original_2019`.
- Athlete filter on the standalone nomogram screen.

Schema remains version 4. No Phase 4 longitudinal dashboard, individual nomogram fitting UI, PDF/export report, backend, cloud, login, or telemetry was started.

---

## Phase 4.0A Completion (2026-05-26)

Phase 4.0A delivered the first athlete longitudinal dashboard MVP.

Implemented:
- Pure longitudinal data builder for athlete session trends.
- Rolling slope and ITL averages over 7, 14, and 28 sessions.
- Trend direction summary: improving, worsening, stable, or insufficient data.
- Fatigue/training-context flags:
  - 3 consecutive residuals below -0.5
  - 7-session slope average dropping more than 30% versus 28-session average
  - 7-session ITL average increasing more than 50% versus 28-session average
- Athlete longitudinal dashboard accessible from Athlete Detail.
- Slope trend chart, ITL trend chart, load overlay chart, residual list, fatigue flags, and chronological session list with Open Report action.

No individual nomogram fitting UI, hybrid overlay, PDF/export, raw ECG/PPG processing, backend, cloud, login, or telemetry was started. Schema remains version 4.

---

## Phase 4.0B Completion (2026-05-26)

Phase 4.0B delivered the individual nomogram fitting UI and hybrid overlay.

Implemented:
- Pure individual nomogram data builder for athlete session history.
- Session exclusion reasons for draft sessions, missing intensity, missing interpreted slope, and invalid values.
- Confidence and recommended mode display:
  - population only for insufficient data
  - hybrid for initial/acceptable confidence
  - individual for robust confidence
- Population, individual, and hybrid curve data for chart overlays.
- Individual nomogram screen accessible from Athlete Detail.
- Nomogram shortcut from the longitudinal dashboard.
- Nomogram chart overlay support for individual fit and hybrid expected curves while preserving existing report and population nomogram chart APIs.

No PDF/export, raw ECG/PPG processing, backend, cloud, login, telemetry, schema changes, or RR preprocessing default changes were made. Schema remains version 4.

---

## Phase 4.1 Completion (2026-05-27)

Phase 4.1 delivered the first export layer for research and practical analysis.

Implemented:
- CSV export architecture with explicit export models and local file writer.
- Robust CSV formatting for commas, quotes, newlines, semicolons, blank values, numeric precision, and UTF-8 text.
- Individual report CSV export including identity, load variables, HRV/RMSSD fields, recovery window timing, raw/interpreted slope, ITL, fallback flag, nomogram bands, residuals, warnings, and RR preprocessing metadata when available.
- Group report CSV exports split into rows and summary datasets.
- Longitudinal athlete CSV exports for session trend rows and fatigue/training-context flags.
- Individual nomogram CSV exports for valid points, excluded sessions, model summary, and curve points.
- Population nomogram CSV export for `excel_operational` and `paper_original_2019`.
- Export CSV buttons on individual report, group report, population nomogram, longitudinal dashboard, and individual nomogram screens.

XLSX export remains deferred because the current dependency set supports spreadsheet reading but does not include a stable XLSX writer. No PDF export, packaging, backend, cloud, login, telemetry, schema changes, scientific-engine changes, or RR preprocessing default changes were made. Schema remains version 4.

---

## Phase 5.0 Completion (2026-05-27)

Phase 5.0 delivered the in-app Instructions Book MVP.

Implemented:
- Static offline instructions content model.
- Instructions Book screen with chapter selector, section list, and search/filter.
- Visible Instructions entry in the app shell navigation.
- Scientific disclaimer: the app supports training-load monitoring and is not a medical diagnostic tool.
- Recommended workflow callout: Direct RMSSD -> session data -> preview -> report -> longitudinal dashboard and nomogram review.
- Chapters covering overview, measurement protocol, data entry, direct RMSSD workflow, RR interval workflow, interpreting results, reports/exports, and limitations/good practice.
- Protocol guidance including first 5 minutes excluded, valid 5-minute recovery windows, and 5-10 window meaning `t = 10`.
- RR workflow guidance distinguishing RR/NN preprocessing from raw ECG/PPG filtering.
- Interpretation guidance for raw/interpreted slope, ITL, classification, population nomogram, individual nomogram, hybrid mode, residuals, longitudinal trends, and fatigue/context flags.
- Export guidance noting CSV availability and XLSX/PDF deferred status.

No PDF export, XLSX export, packaging, raw ECG/PPG processing, backend, cloud, login, telemetry, schema changes, scientific-engine changes, or RR preprocessing default changes were made. Schema remains version 4.
