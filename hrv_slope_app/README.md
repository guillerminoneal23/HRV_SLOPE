# HRV Slope App

HRV Slope App is a local/offline Flutter application for Windows and iOS. It
supports internal training load monitoring using RMSSD-Slope analysis from
direct RMSSD values or advanced RR interval workflows.

This tool supports training analysis. It is not a medical diagnostic tool.

## Current Status

- Phase 5.1 release readiness pass complete.
- Latest gate: 411/411 tests passing.
- Database schema version: 4.
- Direct RMSSD input remains the recommended/default workflow.
- RR interval input is available as an advanced workflow.
- RR correction is off by default.
- HRV slope interpretation uses valid external intensity first; when external
  intensity is absent or invalid, internal intensity such as RPE or subjective
  fatigue can be used as a fallback.
- Reusable local tag catalog is available for session task, sport, protocol
  name, and context/environment.

Implemented:

- athlete and session management
- manual session entry
- direct RMSSD input
- RR interval parsing and preprocessing
- CSV import
- individual report
- group report
- population nomogram
- athlete longitudinal dashboard with comparable-session filters
- longitudinal Slope/ITL trends can show `slope_Orellana_19` references when
  primary intensity is available
- individual and hybrid nomogram overlay
- CSV export for individual reports, group reports, longitudinal dashboards,
  individual nomograms, and population nomogram curve points
- longitudinal CSV export uses the currently filtered dashboard session set
- Excel-openable CSV exports remain the supported export format; XLSX is still
  deferred.
- in-app Instructions Book covering collection, entry, interpretation, and
  export workflows
- reusable suggestions for session task, sport, protocol, and context fields
- updated new-session type/task options; Group Session and Post-match Recovery
  remain legacy values for historical sessions, not default new options
- paper reference preset is identified in new outputs as `slope_Orellana_19`;
  the legacy `paper_original_2019` identifier is accepted only as an alias.

## Setup

Install dependencies:

```powershell
flutter pub get
```

Run static analysis:

```powershell
flutter analyze
```

Run tests:

```powershell
flutter test
```

Run on Windows:

```powershell
flutter run -d windows
```

CSV exports are written to a local `exports/` folder by default. The folder is
created on demand and is ignored by source control.

## Windows Build

Windows builds that use Flutter plugins may require Developer Mode for symlink
support.

Enable it in Windows Settings:

```text
Windows Settings -> For developers -> Developer Mode ON
```

Build command:

```powershell
C:\flutter\bin\flutter.bat build windows
```

Release builds are expected under:

```text
build\windows\x64\runner\Release\
```

## Project Structure

- `lib/` — Flutter UI, data layer, and calculation engines.
- `test/` — engine, service, widget, integration, and regression tests.
- `test/fixtures/rr_samples/` — mandatory real RR interval fixture files.
- `docs/phase_reports/` — historical phase completion reports.
- `docs/references/` — scientific papers and operational workbook references.
- `docs/archive/` — extraction/scratch artifacts retained for traceability.

## Scientific Notes

Primary metric:

```text
RMSSD_Slope = (RMSSD_recovery - RMSSD_exercise) / t
```

Where `t` is the recovery window end time in minutes. For example, a 5-10 min
window uses `t = 10`.

Important guardrails:

- The first 5 minutes of recovery are excluded from HRV quantification.
- Raw slope and interpreted slope are both preserved.
- Interpreted slope is clamped to a minimum of 0.1 for graphical and
  interpretive use.
- ITL index is `1 / interpreted_slope`.
- No nomogram classification is produced without `intensity_percent`.
- `intensity_percent` is resolved from external intensity first. If no valid
  external intensity is available, RPE or subjective fatigue on a 0-10 scale can
  be converted to 0-100 for slope interpretation.
- Direct RMSSD input is the default workflow.
- RR correction is off by default.
- Raw RR-derived RMSSD is always preserved.
- Corrected NN-derived RMSSD is used for slope only when correction is
  explicitly enabled.
- Individual nomograms require enough valid sessions and intensity spread
  before they are used as the primary reference.
- Exports preserve raw slope, interpreted slope, recovery window timing,
  fallback flags, HRV input mode, and RR preprocessing metadata where
  available.

Current limitations:

- Not a medical diagnostic tool.
- XLSX and PDF export are deferred.
- Raw ECG/PPG filtering and peak detection are out of scope; RR interval input
  uses RR/NN preprocessing only.

## Privacy

The app is local-first:

- no backend
- no cloud account
- no telemetry
- no remote analytics

Data stays on the device unless the user manually exports or shares it.
