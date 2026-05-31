# Release Readiness Checklist — HRV Slope App

**Date:** 2026-05-27  
**Phase:** 5.1 — Release Readiness + Windows Build  
**Target:** Local Windows beta testing  

---

## Verification Gate

| Item | Status | Notes |
|---|---|---|
| Tests pass | Complete | `340/340 passing` |
| Static analysis clean | Complete | `flutter analyze`: no issues found |
| Dart format run | Complete | `dart format .` completed |
| Schema version documented | Complete | Schema version remains `4` |
| build_runner status | Complete | Not run; no schema/generated changes |

---

## Product Readiness

| Item | Status | Notes |
|---|---|---|
| App is local/offline | Complete | No backend, cloud account, login, sync, or telemetry |
| No backend/cloud/telemetry dependencies | Complete | Dependency audit found no `http`, `dio`, Firebase, analytics, crash reporting, auth, or telemetry packages |
| Direct RMSSD default | Complete | Direct RMSSD remains the recommended/default workflow |
| RR correction off by default | Complete | RR interval input remains advanced; correction must be explicitly enabled |
| Raw RMSSD preserved | Complete | Raw RR-derived RMSSD is preserved in RR workflows |
| CSV exports available | Complete | CSV exports are available for reports, longitudinal data, nomograms, and population curves |
| Export folder behavior | Complete | Local `exports/` folder is created on demand and ignored by source control |
| XLSX deferred | Complete | XLSX writing is deferred; no stable writer dependency is included |
| PDF deferred | Complete | PDF export is not implemented in this phase |
| Instructions Book available | Complete | In-app Instructions navigation entry is visible |
| Known limitations documented | Complete | README and reports document diagnosis, XLSX/PDF, and raw ECG/PPG limitations |

---

## Windows Build Readiness

| Item | Status | Notes |
|---|---|---|
| Windows build attempted | Blocked by environment | Flutter reported that plugin builds require symlink support |
| Developer Mode requirement documented | Complete | Enable `Windows Settings -> System -> For developers -> Developer Mode -> ON` |
| Expected build command | Documented | `C:\flutter\bin\flutter.bat build windows` |
| Reliable command used in this environment | Documented | `C:\flutter\bin\cache\dart-sdk\bin\dart.exe C:\flutter\bin\cache\flutter_tools.snapshot build windows` |
| Expected output after successful build | Documented | `build\windows\x64\runner\Release\hrv_slope_app.exe` |

Exact build message:

```text
Building with plugins requires symlink support.

Please enable Developer Mode in your system settings. Run
  start ms-settings:developers
to open settings.
```

---

## Manual Beta Checklist

- Launch the Windows app after enabling Developer Mode and rebuilding.
- Create an athlete and a direct RMSSD session.
- Confirm direct RMSSD is the default HRV mode.
- Confirm RR correction is off by default in the RR workflow.
- Save a session and open the individual report.
- Open group report, population nomogram, longitudinal dashboard, individual nomogram, instructions, and settings.
- Export at least one CSV and confirm it appears under `exports/`.
- Restart the app and confirm local data persists.
- Review instructions and limitations with a beta user before data collection.
