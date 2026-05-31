# HRV_RR_PREPROCESSING_SPEC.md

## Scope

Direct RMSSD input remains the recommended/default workflow. RR interval input is an advanced workflow for users who want the app to compute RMSSD from beat-to-beat intervals.

This phase does not process raw ECG or raw PPG. ECG/PPG signals require signal filtering and peak detection before RR intervals exist. RR interval files already contain beat-to-beat intervals, so this app applies RR/NN interval preprocessing only.

## Pipeline

Conceptual pipeline:

1. Parse RR intervals in milliseconds.
2. Compute raw RMSSD from raw RR intervals.
3. Detect range outliers.
4. If correction is enabled, linearly interpolate range outliers.
5. Detect ectopic/local outliers according to the selected method.
6. If correction is enabled, linearly interpolate marked intervals again.
7. Compute corrected RMSSD from cleaned NN intervals.
8. Preserve raw RMSSD, corrected RMSSD, RMSSD used for slope, artifacts, warnings, and quality decision.

No RR values are silently dropped. No correction is applied unless the user explicitly enables it.

## Supported Modes

| Mode | Behavior |
|---|---|
| `none` | No artifact method beyond basic duration/list checks |
| `rangeOnly` | Detect RR intervals outside low/high thresholds |
| `rangeAndEctopic` | Detect range outliers, then ectopic beats |
| `localMedianThreshold` | Detect range outliers, then local median outliers |

## Correction Methods

| Method | Phase 2.2 status |
|---|---|
| `none` | Default when correction is off |
| `rangeOutlierLinearInterpolation` | Implemented |
| `malikLinearInterpolation` | Implemented |
| `kamathLinearInterpolation` | Implemented |
| `karlssonLinearInterpolation` | Implemented |
| `acarLinearInterpolation` | Implemented |
| `localMedianLinearInterpolation` | Implemented |

All correction in Phase 2.2 is linear interpolation. Cubic interpolation and full Lipponen-Tarvainen automatic correction are future options.

## Default Settings

| Setting | Default |
|---|---:|
| Low RR threshold | 300 ms |
| High RR threshold | 2200 ms |
| Ectopic method | Karlsson |
| Local median window | 5 |
| Local median threshold | 250 ms |
| Artifact warning threshold | 5% |
| Artifact invalid threshold | 10% |
| Preserve raw RMSSD | true |
| Correction enabled | false |

Local median threshold presets:

| Preset | Threshold |
|---|---:|
| veryLow | 450 ms |
| low | 350 ms |
| medium | 250 ms |
| strong | 150 ms |
| veryStrong | 50 ms |

## Quality Decisions

Invalid if:

- RR list is empty.
- Fewer than 2 RR intervals are present.
- Total raw duration is below 300 seconds for a 5-minute RMSSD window.
- Artifact percent is greater than 10%.

Warning if:

- Artifact percent is greater than 5%.
- Correction changes RMSSD by more than 10%.
- Artifacts are detected while correction is off.

Valid if:

- Duration is at least 300 seconds.
- Artifact percent is at most 5%.
- No major warnings apply.

## UI Behavior

Correction is off by default. The RR widget always shows raw RMSSD. If correction is enabled, it also shows corrected RMSSD, delta, delta percent, artifact count, artifact percent, correction method, quality decision, and an artifact table.

The RMSSD used for slope is:

- raw RMSSD when correction is off.
- corrected RMSSD when correction is on.

## Persistence

The session table stores RR preprocessing summary metadata:

- preprocessing mode
- correction enabled
- correction method
- raw RMSSD
- corrected RMSSD
- RMSSD used
- artifact count
- artifact percent
- quality decision
- quality notes JSON
- RMSSD delta percent

Full raw RR storage remains optional future work.

## Real Fixture Validation

Phase 2.2b includes mandatory real RR fixture tests. The tests fail if `test/fixtures/rr_samples` or any required file is missing.

| Fixture | RR count | Duration sec | Raw RMSSD ms | Min RR ms | Max RR ms | Range artifacts |
|---|---:|---:|---:|---:|---:|---:|
| `2026-05-25_05-27-02.txt` | 226 | 301.920 | 201.249 | 350 | 1788 | 0 |
| `2026-05-22_05-39-13.txt` | 252 | 300.935 | 139.966 | 838 | 1665 | 0 |
| `2026-05-21_05-42-46.txt` | 263 | 302.200 | 112.875 | 267 | 1379 | 1 |

## Limitations

- This is not a medical diagnostic tool.
- Correction can materially change RMSSD; raw RMSSD is always preserved.
- Threshold-based preprocessing may not match Kubios automatic correction exactly.
- Full Lipponen-Tarvainen correction is not implemented in Phase 2.2.
- Raw ECG/PPG filtering and peak detection are out of scope.

## References

- hrv-analysis style RR pipeline: remove outliers, interpolate, remove ectopic beats, interpolate, compute NN intervals.
- Kubios / Lipponen-Tarvainen threshold-style correction concepts.
- NeuroKit2 HRV preprocessing concepts.
- HeartPy beat interval and artifact handling concepts.
- PhysioNet HRV Toolkit definition of rMSSD: square root of the mean squared successive differences of NN intervals.
