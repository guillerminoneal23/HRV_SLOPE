# HRV Slope

Flutter/Dart local-first app for HRV RMSSD-Slope workflows.

The app supports athlete/session management, direct RMSSD input, advanced RR interval preprocessing, session reports, group reports, population and individual nomograms, longitudinal dashboards, CSV exports, and an in-app instructions book.

## Status

- Current phase: release readiness for local Windows beta testing.
- Schema version: 4.
- Direct RMSSD is the recommended/default workflow.
- RR interval input is advanced; correction is off by default and raw RMSSD is preserved.
- CSV export is implemented.
- XLSX and PDF exports are deferred.

## Project

Main Flutter project:

```text
hrv_slope_app/
```

Useful commands:

```powershell
cd hrv_slope_app
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat test
C:\flutter\bin\flutter.bat run -d windows
```

Windows release build:

```powershell
C:\flutter\bin\flutter.bat build windows
```

Windows Developer Mode may be required for Flutter plugin symlink support.

## Privacy

The app is designed to run locally/offline. There is no backend, cloud login, or telemetry.

## Disclaimer

HRV Slope supports training-load and recovery monitoring workflows. It is not a medical diagnostic tool.
