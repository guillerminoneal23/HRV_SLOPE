/// HRV-related constants derived from the Naranjo Orellana et al. (2019) papers
/// and the VALORACIÓN CARGA INTERNA.xlsx reference workbook.
library;

/// Default RMSSD during exercise when no measurement is available.
/// From Paper 1: "RMSSD values dropped substantially regardless of the
/// intensity and duration of exercise (average 4 ms)."
const double kDefaultRmssdExerciseMs = 4.0;

/// Minimum slope value for graphical interpretation.
/// From Paper 1: "0.1 is considered the minimum value of the slopes,
/// so that for any value less than 0.1, this value would be assigned."
const double kMinSlopeForInterpretation = 0.1;

/// Preferred recovery window: Slope-10 (10 minutes post-exercise).
const double kPreferredRecoveryWindowMin = 10.0;

/// Maximum valid recovery window (30 minutes).
const double kMaxRecoveryWindowMin = 30.0;

/// First 5 minutes of recovery are excluded due to time-series instability.
/// From Paper 1: "HRV was not quantified the first 5 minutes of recovery
/// because of the loss of time series stability derived from the sudden
/// change between the end of the exercise and the start of recovery."
const double kMinRecoveryExclusionMin = 5.0;

/// Recovery window duration for HRV measurement (5 minutes).
const double kRecoveryWindowDurationMin = 5.0;

/// Maximum ITL value (when slope = kMinSlopeForInterpretation).
const double kMaxItlIndex = 10.0;

/// Default population nomogram preset used by the app.
const String kDefaultPopulationNomogramPresetName = 'excel_operational';
