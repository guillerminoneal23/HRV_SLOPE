library;

enum RecoveryResponseZone { lowerThanExpected, expected, favorable }

const visibleRecoveryResponseZones = [
  RecoveryResponseZone.lowerThanExpected,
  RecoveryResponseZone.expected,
  RecoveryResponseZone.favorable,
];

extension RecoveryResponseZoneLabels on RecoveryResponseZone {
  String get id {
    switch (this) {
      case RecoveryResponseZone.lowerThanExpected:
        return 'lower_than_expected';
      case RecoveryResponseZone.expected:
        return 'expected';
      case RecoveryResponseZone.favorable:
        return 'favorable';
    }
  }

  String get shortLabel {
    switch (this) {
      case RecoveryResponseZone.lowerThanExpected:
        return 'Lower-than-expected';
      case RecoveryResponseZone.expected:
        return 'Expected';
      case RecoveryResponseZone.favorable:
        return 'Favorable';
    }
  }

  String get label {
    switch (this) {
      case RecoveryResponseZone.lowerThanExpected:
        return 'Lower-than-expected recovery response';
      case RecoveryResponseZone.expected:
        return 'Expected recovery response';
      case RecoveryResponseZone.favorable:
        return 'Favorable recovery response';
    }
  }
}

RecoveryResponseZone? recoveryResponseZoneForClassificationKey(String? value) {
  switch (_normalizeRecoveryResponseValue(value)) {
    case 'very_high_internal_load':
    case 'veryhighinternalload':
    case 'high_or_moderate_internal_load':
    case 'highormoderateinternalload':
    case 'lower-than-expected recovery response':
    case 'lower-than-expected':
      return RecoveryResponseZone.lowerThanExpected;
    case 'expected_response':
    case 'expectedresponse':
    case 'expected recovery response':
    case 'expected':
      return RecoveryResponseZone.expected;
    case 'low_internal_load_or_fast_recovery':
    case 'lowinternalloadorfastrecovery':
    case 'favorable recovery response':
    case 'favorable':
      return RecoveryResponseZone.favorable;
    default:
      return null;
  }
}

String recoveryResponseLabelForClassificationKey(String? value) {
  final zone = recoveryResponseZoneForClassificationKey(value);
  if (zone != null) return zone.label;
  return value ?? '-';
}

String recoveryResponseShortLabelForClassificationKey(String? value) {
  final zone = recoveryResponseZoneForClassificationKey(value);
  if (zone != null) return zone.shortLabel;
  return value ?? '-';
}

String recoveryResponseExportValueForClassificationKey(String? value) {
  return recoveryResponseLabelForClassificationKey(value);
}

String recoveryZoneLabel(String value) {
  switch (value) {
    case 'low':
      return 'Lower-than-expected recovery response';
    case 'normal':
      return 'Expected recovery response';
    case 'favorable':
      return 'Favorable recovery response';
    case 'unavailable':
      return 'Recovery reference unavailable';
    default:
      return value;
  }
}

String recoveryZoneShortLabel(String value) {
  switch (value) {
    case 'low':
      return 'Lower-than-expected';
    case 'normal':
      return 'Expected';
    case 'favorable':
      return 'Favorable';
    case 'unavailable':
      return 'Unavailable';
    default:
      return value;
  }
}

String intensitySourceForSlopeMessage(String source) {
  switch (source) {
    case 'External':
      return 'External intensity was used for slope interpretation.';
    case 'Internal':
      return 'Internal intensity such as RPE or fatigue was used for slope interpretation because no valid external intensity was available.';
    default:
      return 'Intensity source unavailable; recovery interpretation may be limited.';
  }
}

String _normalizeRecoveryResponseValue(String? value) {
  return value?.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase() ?? '';
}
