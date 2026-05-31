/// Custom error types for the HRV calculation engine.
library;

/// Thrown when there are insufficient RR intervals to compute RMSSD.
class InsufficientDataError extends Error {
  final String message;
  InsufficientDataError(this.message);

  @override
  String toString() => 'InsufficientDataError: $message';
}

/// Thrown when input data contains invalid values (e.g., negative RR intervals).
class InvalidDataError extends Error {
  final String message;
  InvalidDataError(this.message);

  @override
  String toString() => 'InvalidDataError: $message';
}

/// Thrown when recovery time violates the 5-minute exclusion rule.
class InvalidRecoveryTimeError extends Error {
  final String message;
  InvalidRecoveryTimeError(this.message);

  @override
  String toString() => 'InvalidRecoveryTimeError: $message';
}

/// Thrown when nomogram fitting fails (insufficient data or convergence failure).
class NomogramFitError extends Error {
  final String message;
  NomogramFitError(this.message);

  @override
  String toString() => 'NomogramFitError: $message';
}

/// Thrown when required session variables are missing.
class MissingVariableError extends Error {
  final String message;
  MissingVariableError(this.message);

  @override
  String toString() => 'MissingVariableError: $message';
}
