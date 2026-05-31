# ALGORITHM_SPEC.md — HRV Slope App

## Pure Functions Specification

All calculation functions are pure (no side effects, deterministic output for given input).
All units are in milliseconds (ms) for RMSSD/RR and minutes for time.

---

## 1. `computeRmssd(rrIntervalsMs)`

### Input
- `rrIntervalsMs`: `List<double>` — RR intervals in milliseconds.

### Preconditions
- List must have ≥2 elements.
- All values must be > 0.

### Algorithm
```
successive_diffs = [rr[i+1] - rr[i] for i in 0..n-2]
squared_diffs = [d² for d in successive_diffs]
mean_squared = sum(squared_diffs) / len(squared_diffs)
RMSSD = sqrt(mean_squared)
```

### Output
- `double` — RMSSD value in ms.

### Edge Cases
- If list has <2 elements → throw `InsufficientDataError`.
- If any RR ≤ 0 → throw `InvalidDataError`.

---

## 2. `computeSlope(rmssdRecovery, rmssdExercise, recoveryTimeMin)`

### Input
- `rmssdRecovery`: `double` — RMSSD during recovery window (ms).
- `rmssdExercise`: `double?` — RMSSD during last 5 min of exercise (ms). Null if not available.
- `recoveryTimeMin`: `double` — Time from end of exercise to end of recovery window (min).

### Algorithm
```
exercise = rmssdExercise ?? 4.0   // fallback
slope = (rmssdRecovery - exercise) / recoveryTimeMin
```

### Preconditions
- `recoveryTimeMin` must be > 5.0 (first 5 min excluded).
- `rmssdRecovery` must be ≥ 0.

### Output
- `SlopeResult` containing:
  - `rawSlope`: `double`
  - `usedFallback`: `bool` — true if rmssdExercise was null
  - `rmssdExerciseUsed`: `double` — actual value used (measured or 4.0)

### Edge Cases
- `recoveryTimeMin ≤ 5.0` → throw `InvalidRecoveryTimeError`.
- Negative slope is possible and preserved as raw value.

---

## 3. `clampSlopeForInterpretation(rawSlope)`

### Input
- `rawSlope`: `double`

### Algorithm
```
return max(0.1, rawSlope)
```

### Output
- `double` — Clamped slope (≥ 0.1).

### Note
The raw slope is always stored; this function is only used for nomogram placement and ITL calculation.

---

## 4. `computeItlIndex(slopeInterpreted)`

### Input
- `slopeInterpreted`: `double` — Clamped slope value (≥ 0.1).

### Algorithm
```
ITL = 1.0 / slopeInterpreted
```

### Output
- `double` — Internal Training Load index.

### Interpretation
| Slope | ITL | Meaning |
|---|---|---|
| 2.50 | 0.40 | Very low internal load |
| 1.51 | 0.66 | Low internal load |
| 0.34 | 2.94 | Moderate-high internal load |
| 0.10 | 10.0 | Very high internal load |

---

## 5. `classifySlopeByPopulationNomogram(intensityPercent, slope)`

### Input
- `intensityPercent`: `double` — Exercise intensity as % of MAS/VO₂max.
- `slope`: `double` — Interpreted slope (already clamped).

### Reference Table (from Excel INFORME INDIVIDUAL)

| Intensity Range | Poor (MALO) | Good (BUENO) | Very Good (MUY BUENO) |
|---|---|---|---|
| <60% | <0.80 | 0.80–5.00 | >5.00 |
| 60–75% | <0.40 | 0.40–2.60 | >2.60 |
| 75–90% | <0.25 | 0.25–1.20 | >1.20 |
| >90% | <0.10 | 0.10–0.60 | >0.60 |

### Algorithm
```
range = determineIntensityRange(intensityPercent)
if slope < range.poorThreshold:
    return "poor"      // High internal load, slow recovery
elif slope <= range.goodMaxThreshold:
    return "good"      // Acceptable recovery
else:
    return "very_good" // Excellent recovery, low internal load
```

### Output
- `SlopeClassification` enum: `poor`, `good`, `veryGood`
- Plus: `description` string explaining what this means for the athlete.

---

## 6. `fitIndividualNomogram(points)`

### Input
- `points`: `List<NomogramPoint>` — Each point has:
  - `intensityPercent`: `double`
  - `slope`: `double` (interpreted/clamped)

### Preconditions
- ≥6 points recommended (minimum 3 for fitting).
- ≥3 distinct intensity ranges required.

### Model
```
slope = c + a * exp(b * intensity_percent)
```
With constraints:
- `c ≥ 0.1` (floor value from paper)
- `b < 0` (exponential decay)
- `a > 0` (positive amplitude)

### Fitting Method
**Levenberg-Marquardt-style iterative least squares** (simplified for Dart):

1. Initial parameter estimates:
   - `c = 0.1`
   - `a = max(slopes) - 0.1`
   - `b = ln(0.1 / a) / 100` (approximation)

2. Iterative refinement using gradient descent with adaptive step size.

3. Convergence criterion: relative change in residual sum of squares < 1e-6 or max 1000 iterations.

### Output
- `NomogramModel` containing:
  - `a`, `b`, `c`: fitted parameters
  - `rSquared`: coefficient of determination
  - `nPoints`: number of data points
  - `nIntensityRanges`: number of distinct ranges
  - `confidenceLevel`: computed from data adequacy

### Confidence Level Logic
```
if nPoints < 3 || nIntensityRanges < 2:
    return "insufficient"
elif nPoints < 6 || nIntensityRanges < 3:
    return "initial"
elif nPoints < 9:
    return "acceptable"
else:
    return "robust"
```

---

## 7. `expectedSlopeAtIntensity(model, intensityPercent)`

### Input
- `model`: `NomogramModel` — Fitted model parameters.
- `intensityPercent`: `double`

### Algorithm
```
expected = model.c + model.a * exp(model.b * intensityPercent)
return max(0.1, expected)
```

### Output
- `double` — Expected slope at given intensity.

---

## 8. `computeResidual(observedSlope, expectedSlope)`

### Input
- `observedSlope`: `double` — Actual measured slope (interpreted).
- `expectedSlope`: `double` — From model prediction.

### Algorithm
```
residual = observedSlope - expectedSlope
```

### Output
- `double` — Residual value.

### Interpretation
- **residual > 0**: athlete recovered better than expected → lower internal load.
- **residual < 0**: athlete recovered worse than expected → higher internal load, possible fatigue.
- **|residual| > 1.0**: notable deviation, flag for review.

---

## Population Nomogram Curves (from Paper Table 3 + Excel)

The population nomogram uses three exponential curves fitted to reference data:

### Reference Data Points

| Intensity (%) | Slope Min | Slope Mean | Slope Max |
|---|---|---|---|
| 60 | 0.64 | 1.51 | 2.49 |
| 80 | 0.10 | 0.34 | 0.72 |
| 100 | 0.10 | 0.24 | 0.48 |

### Pre-fitted Curves

For each curve (min, mean, max), fit: `slope = c + a * exp(b * intensity)`

These curves are hardcoded as constants in the app:
```dart
// Population nomogram constants (pre-computed from reference data)
const populationCurveMean = NomogramParams(a: ..., b: ..., c: ...);
const populationCurveUpper = NomogramParams(a: ..., b: ..., c: ...);
const populationCurveLower = NomogramParams(a: ..., b: ..., c: ...);
```

The exact parameter values will be computed during Phase 1 implementation by fitting the three reference points to the exponential model.

---

## ITL Reference Table (from Excel "Calculos" sheet)

| %INT | Slope Max | Slope Mean | Slope Min | ITL Min | ITL Mean | ITL Max |
|---|---|---|---|---|---|---|
| 60 | 2.49 | 1.51 | 0.64 | 0.40 | 0.66 | 1.56 |
| 80 | 0.72 | 0.34 | 0.10 | 1.39 | 2.94 | 5.00* |
| 100 | 0.48 | 0.24 | 0.10 | 2.08 | 4.17 | 10.0 |

*ITL capped at 10.0 when slope = 0.1

---

## Hybrid Nomogram Logic

When an athlete has some data but not enough for full individual model:

```
if confidenceLevel == "insufficient":
    use population nomogram only
elif confidenceLevel == "initial":
    weight = 0.3  // 30% individual, 70% population
elif confidenceLevel == "acceptable":
    weight = 0.7  // 70% individual, 30% population
elif confidenceLevel == "robust":
    weight = 1.0  // 100% individual

hybridSlope = weight * individualExpected + (1 - weight) * populationExpected
```

---

## Longitudinal Analysis Functions

### Rolling Averages
```dart
List<double> rollingAverage(List<double> values, int windowDays)
// Windows: 7, 14, 28 days
```

### Fatigue Flag Detection
```dart
FatigueFlag detectFatigue(List<SessionSummary> recentSessions)
```

Flags triggered when:
- Slope residual < -0.5 for ≥3 consecutive sessions.
- Rolling 7-day slope average drops >30% vs 28-day average.
- ITL rolling 7-day average increases >50% vs 28-day average.

---

## Phase 1.5 Scientific Audit Amendments

### Recovery Window Timing

Slope calculation now supports an explicit `RecoveryWindow` model:

| Field | Meaning |
|---|---|
| `recoveryWindowStartMin` | Start of the recovery HRV window, minutes after exercise end |
| `recoveryWindowEndMin` | End of the recovery HRV window, minutes after exercise end |
| `recoveryWindowDurationMin` | Must be exactly 5 minutes for Phase 1.5 |
| `recoveryTimeForSlopeMin` | Denominator `t`, equal to `recoveryWindowEndMin` |

Valid standard immediate-recovery windows must start at or after 5 minutes, last exactly 5 minutes, and end at or before 30 minutes. Therefore 5-10 uses `t = 10`, 10-15 uses `t = 15`, and 25-30 uses `t = 30`. The first 0-5 minute window is invalid for HRV quantification.

`SlopeResult` preserves both `rawSlope` and `interpretedSlope`; values below 0.1 are clamped only for interpretation.

### Population Nomogram Strategy

The previous unconstrained exponential lower curve was retained only as an audit comparison constant because its `a` parameter was near 1,000,000. Population interpretation now uses piecewise monotonic log-linear interpolation between explicit source points, with warnings when intensity is outside the preset source range.

Supported presets:

| Preset | Source points |
|---|---|
| `paper_original_2019` | 64.39%, 83.11%, 100.00% |
| `excel_operational` | 60%, 80%, 100% |

The app default is `excel_operational`.

### Classification

Classification compares observed interpreted slope against expected lower, mean, and upper bands:

| Condition | Classification |
|---|---|
| `observed < expectedLower` | `veryHighInternalLoad` |
| `expectedLower <= observed < expectedMean` | `highOrModerateInternalLoad` |
| `expectedMean <= observed <= expectedUpper` | `expectedResponse` |
| `observed > expectedUpper` | `lowInternalLoadOrFastRecovery` |

Each classification result includes model source, preset name, intensity, observed slope, expected bands, residual, residual percent, classification, and warnings.

### Individual Nomogram Confidence

Individual confidence now uses low/medium/high intensity zones:

| Zone | Intensity |
|---|---|
| low | <70% |
| medium | 70-90% |
| high | >90% |

| Confidence | Rule | Individual weight |
|---|---|---|
| insufficient | Fewer than 6 valid sessions or insufficient spread | 0.0 |
| initial | 6-8 sessions and at least 2 zones | 0.3 |
| acceptable | 9-11 sessions and all 3 zones | 0.7 |
| robust | 12+ sessions, all 3 zones, no extreme distribution issue | 1.0 |

An individual model is used alone only when confidence is robust; otherwise hybrid mode keeps the population expected slope in the result.

### RR Quality Control

`rr_quality.dart` adds pure quality-control functions for Phase 2 input:

| Rule | Outcome |
|---|---|
| Empty RR list | invalid |
| Fewer than 2 RR intervals | invalid |
| Effective duration <300 seconds | invalid |
| RR <=300 ms or RR >=2200 ms | counted as artifact |
| Artifact estimate >5% | warning |
| Artifact estimate >10% | invalid |

No artifact correction is performed in Phase 1.5.

---

## Phase 2.2 RR/NN Preprocessing

RR interval input is an advanced workflow. Direct RMSSD entry remains the recommended/default workflow.

RR interval files are not raw ECG or raw PPG, so ECG bandpass filters are not applied. Phase 2.2 preprocesses RR intervals into NN intervals when correction is explicitly enabled.

Implemented functions:

- `computeRawRmssdFromRr(rrIntervals)`
- `preprocessRrIntervals(rrIntervals, options)`
- `detectRangeOutliers(rrIntervals, lowRriMs, highRriMs)`
- `detectMalikEctopics(rrIntervals)`
- `detectKamathEctopics(rrIntervals)`
- `detectKarlssonEctopics(rrIntervals)`
- `detectAcarEctopics(rrIntervals)`
- `detectLocalMedianOutliers(rrIntervals)`
- `interpolateMarkedIntervalsLinear(rrIntervals, invalidIndexes)`

Correction is off by default. In raw mode, the app computes raw RMSSD, detects/report artifacts, and uses raw RMSSD for slope. In correction mode, the app linearly interpolates marked intervals and computes corrected NN-derived RMSSD for slope while preserving raw RMSSD.

Quality decision rules:

| Rule | Decision |
|---|---|
| Empty RR list | invalid |
| Fewer than 2 RR intervals | invalid |
| Raw duration <300 sec | invalid |
| Artifact percent >10% | invalid |
| Artifact percent >5% | warning |
| Correction changes RMSSD by >10% | warning |
| Artifacts present while correction is off | warning |
