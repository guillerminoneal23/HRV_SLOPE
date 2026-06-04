# HRV Slope

HRV Slope is a local-first Flutter/Dart application for HRV RMSSD-Slope workflows.

The app supports athlete and session management, direct RMSSD input, advanced RR interval preprocessing, session reports, group reports, population and individual nomograms, longitudinal dashboards, CSV exports, and an in-app instructions book.

## Download

For normal use, download the latest Windows portable ZIP from the **Releases** section of this repository.

Go to:

```text
Releases → Latest release → Assets
```

Download the latest file similar to:

```text
Release_HRV_SLOPE.rar
```

Then:

1. Download the ZIP file.
2. Extract the ZIP to a folder on your computer.
3. Open the extracted folder.
4. Run the HRV Slope executable file.

No installation is required.

On Windows, you may see a security warning because the app is not digitally signed. If you trust the source, choose:

```text
More info → Run anyway
```

or the equivalent option in your Windows language.

## Updating the app

To update HRV Slope:

1. Go to the **Releases** section.
2. Download the latest ZIP.
3. Extract it to a new folder.
4. Use the new executable.

Do not overwrite or delete your existing data unless you know exactly where your app data is stored.

During the beta phase, updates are manual. Automatic updates are not currently implemented.

## Status

* Current phase: release readiness for local Windows beta testing.
* Schema version: 4.
* Direct RMSSD is the recommended/default workflow.
* RR interval input is advanced.
* RR correction is off by default.
* Raw RMSSD is preserved.
* CSV export is implemented.
* XLSX and PDF exports are deferred.

## Privacy

HRV Slope is designed to run locally and offline.

There is:

* No backend.
* No cloud login.
* No telemetry.
* No automatic data upload.

Your data remains on your computer unless you manually export or share it.

## Disclaimer

HRV Slope supports training-load and recovery monitoring workflows.

It is not a medical diagnostic tool. The app should not be used as a substitute for professional medical evaluation, diagnosis, or treatment.

## Project structure

Main Flutter project:

```text
hrv_slope_app/
```

## Requirements for developers

To run or modify the app from source, you need:

* Flutter SDK.
* Dart.
* Windows desktop support enabled in Flutter.
* Visual Studio Build Tools or Visual Studio with the required C++ desktop development components.
* Windows Developer Mode may be required for Flutter plugin symlink support.

## Developer commands

From the repository root, enter the main Flutter project:

```powershell
cd hrv_slope_app
```

Install dependencies:

```powershell
C:\flutter\bin\flutter.bat pub get
```

Analyze the project:

```powershell
C:\flutter\bin\flutter.bat analyze
```

Run tests:

```powershell
C:\flutter\bin\flutter.bat test
```

Run the app on Windows:

```powershell
C:\flutter\bin\flutter.bat run -d windows
```

Build the Windows release version:

```powershell
C:\flutter\bin\flutter.bat build windows
```

The generated Windows build will be located under:

```text
hrv_slope_app/build/windows/x64/runner/Release/
```

## Suggested release packaging

After building the Windows release, package the contents of the release folder into a ZIP file.

Recommended ZIP name format:

```text
HRV-Slope-App-vX.X.X-windows.zip
```

Upload this ZIP as an asset in a GitHub Release.

Recommended version format:

```text
v1.0.0
v1.0.1
v1.1.0
```

## Recommended release notes format

Each release should include a short summary, for example:

```text
v1.0.1

Changes:
- Improved import screen copy.
- Fixed CSV export naming.
- Updated instructions book.
- Minor UI improvements.
```

## Source code usage

Developers can clone the repository and run the project locally:

```powershell
git clone https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
cd YOUR-REPOSITORY/hrv_slope_app
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat run -d windows
```

Replace `YOUR-USERNAME` and `YOUR-REPOSITORY` with the actual GitHub repository path.

## License

Add your project license here.

For example:

```text
MIT License
```

or another license depending on how you want others to use, modify, or redistribute the app.
