library;

String recoveryResponseLabelForClassificationKey(String? value) {
  switch (value) {
    case 'very_high_internal_load':
    case 'veryHighInternalLoad':
    case 'high_or_moderate_internal_load':
    case 'highOrModerateInternalLoad':
    case 'Lower-than-expected recovery response':
    case 'Lower-than-expected':
      return 'Lower-than-expected recovery response';
    case 'expected_response':
    case 'expectedResponse':
    case 'Expected recovery response':
    case 'Expected':
      return 'Expected recovery response';
    case 'low_internal_load_or_fast_recovery':
    case 'lowInternalLoadOrFastRecovery':
    case 'Favorable recovery response':
    case 'Favorable':
      return 'Favorable recovery response';
    case null:
      return '-';
    default:
      return value;
  }
}

String recoveryResponseShortLabelForClassificationKey(String? value) {
  switch (value) {
    case 'very_high_internal_load':
    case 'veryHighInternalLoad':
    case 'high_or_moderate_internal_load':
    case 'highOrModerateInternalLoad':
    case 'Lower-than-expected recovery response':
    case 'Lower-than-expected':
      return 'Lower-than-expected';
    case 'expected_response':
    case 'expectedResponse':
    case 'Expected recovery response':
    case 'Expected':
      return 'Expected';
    case 'low_internal_load_or_fast_recovery':
    case 'lowInternalLoadOrFastRecovery':
    case 'Favorable recovery response':
    case 'Favorable':
      return 'Favorable';
    case null:
      return '-';
    default:
      return value;
  }
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
