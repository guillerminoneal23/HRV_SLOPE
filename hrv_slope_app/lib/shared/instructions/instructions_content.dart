library;

class InstructionSection {
  final String id;
  final String title;
  final String summary;
  final String body;
  final List<String> bullets;
  final List<String> warnings;
  final List<String> relatedScreens;

  const InstructionSection({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    this.bullets = const [],
    this.warnings = const [],
    this.relatedScreens = const [],
  });
}

class InstructionChapter {
  final String id;
  final String title;
  final List<InstructionSection> sections;

  const InstructionChapter({
    required this.id,
    required this.title,
    required this.sections,
  });
}

const String kInstructionsDisclaimer =
    'HRV Slope App supports training-load monitoring. It is not a medical '
    'diagnostic tool, and results should be interpreted with coaching, '
    'workload, recovery, sleep, travel, illness, and protocol context.';

const String kInstructionsRecommendedWorkflow =
    'Recommended workflow: Direct RMSSD -> session data -> preview -> report '
    '-> longitudinal dashboard and nomogram review.';

const List<InstructionChapter> instructionsChapters = [
  InstructionChapter(
    id: 'overview',
    title: 'Overview',
    sections: [
      InstructionSection(
        id: 'what_is_rmssd_slope',
        title: 'What is RMSSD-Slope?',
        summary: 'The core training-load recovery metric used by the app.',
        body:
            'RMSSD-Slope = (RMSSD_recovery - RMSSD_exercise) / t. Lower slope '
            'generally indicates higher internal load or slower '
            'parasympathetic recovery for the same external load. Higher slope '
            'generally indicates faster recovery or lower internal load. '
            'Always interpret the value with training context.',
      ),
      InstructionSection(
        id: 'question_answered',
        title: 'What question does the app answer?',
        summary: 'How did the athlete recover relative to the session demand?',
        body:
            'The app compares observed RMSSD-Slope with population, '
            'individual, and hybrid references when enough data are available. '
            'It helps review whether recovery was slower, expected, or faster '
            'than reference behavior for the recorded intensity.',
      ),
      InstructionSection(
        id: 'what_it_does_not_do',
        title: 'What it does not do',
        summary: 'The app is local and training-focused.',
        body:
            'The app does not provide clinical interpretation, raw ECG or PPG '
            'processing, login, or backend synchronization. It has no cloud '
            'storage and no telemetry. It does not replace coach, '
            'practitioner, or athlete judgment.',
        warnings: [kInstructionsDisclaimer],
      ),
      InstructionSection(
        id: 'recommended_workflow',
        title: 'Recommended workflow',
        summary: 'Use direct RMSSD first unless RR intervals are needed.',
        body: kInstructionsRecommendedWorkflow,
        bullets: [
          'Create or select an athlete.',
          'Enter session, external load, internal load, and HRV data.',
          'Prefer direct RMSSD from Elite HRV, Kubios, HRV Logger, Polar, Garmin, or similar tools.',
          'Review the calculation preview before saving.',
          'Use reports, longitudinal trends, and nomograms for context.',
        ],
      ),
    ],
  ),
  InstructionChapter(
    id: 'measurement_protocol',
    title: 'Measurement Protocol',
    sections: [
      InstructionSection(
        id: 'last_5_exercise',
        title: 'Last 5 minutes of exercise',
        summary: 'Exercise RMSSD should represent the end of the task.',
        body:
            'When measured, RMSSD_exercise should come from the last 5 minutes '
            'of exercise. If it was not recorded, the app can use the explicit '
            '4 ms fallback and marks that fallback in calculations and exports.',
      ),
      InstructionSection(
        id: 'recovery_window',
        title: 'Recovery measurement window',
        summary: 'Use a 5-minute recovery HRV window after the initial delay.',
        body:
            'The recovery window duration should be 5 minutes. Valid standard '
            'immediate-recovery windows start at 5 minutes or later and end at '
            '30 minutes or earlier after exercise.',
        bullets: [
          'Window 5-10 means t = 10.',
          'Window 10-15 means t = 15.',
          'Window 25-30 means t = 30.',
        ],
      ),
      InstructionSection(
        id: 'exclude_first_5',
        title: 'Why the first 5 minutes of recovery are excluded',
        summary:
            'The first minutes after exercise are not used for HRV quantification.',
        body:
            'The first 5 minutes post-exercise are not used for RMSSD recovery '
            'quantification in the standard protocol. This keeps the app '
            'aligned with the immediate-recovery RMSSD-Slope method.',
      ),
      InstructionSection(
        id: 'slope_10',
        title: 'Preferred Slope-10 protocol',
        summary:
            'The 5-10 minute recovery window is the simplest default protocol.',
        body:
            'For Slope-10, record the 5-10 minute recovery window. The window '
            'duration is 5 minutes, and t used for slope is 10 minutes.',
      ),
      InstructionSection(
        id: 'valid_windows',
        title: 'Valid recovery windows from 5 to 30 minutes',
        summary:
            'Standard interpretation expects a 5-minute window ending by 30 minutes.',
        body:
            'Use 5-minute windows such as 5-10, 10-15, 15-20, 20-25, or 25-30. '
            'A 0-5 window is invalid because the first 5 minutes are excluded.',
      ),
      InstructionSection(
        id: 'recording_conditions',
        title: 'Recording conditions',
        summary: 'Keep recovery posture and environment consistent.',
        body:
            'Use seated and relaxed recovery where applicable. Keep posture, '
            'breathing instructions, device placement, and environment as '
            'consistent as practical. Document protocol deviations.',
      ),
    ],
  ),
  InstructionChapter(
    id: 'data_entry',
    title: 'Data Entry',
    sections: [
      InstructionSection(
        id: 'creating_athletes',
        title: 'Creating athletes',
        summary:
            'Athlete profiles store context for sessions and intensity calculations.',
        body:
            'Create one athlete per person. Add sport and available reference '
            'values such as MAS, vVO2max, MAP, or FCmax when they are useful.',
      ),
      InstructionSection(
        id: 'creating_sessions',
        title: 'Creating sessions',
        summary: 'Sessions combine task context, load variables, and HRV data.',
        body:
            'Each session should include date, task name, sport or session '
            'type, external load, internal load, HRV/RMSSD data, and recovery '
            'window timing when available.',
      ),
      InstructionSection(
        id: 'external_load',
        title: 'External load variables',
        summary: 'External variables describe the work performed.',
        body:
            'Examples include speed_kmh, percent_mas, percent_vvo2max, '
            'power_w, percent_map, distance, and player load.',
      ),
      InstructionSection(
        id: 'internal_load',
        title: 'Internal load variables',
        summary: 'Internal variables describe the athlete response.',
        body:
            'Examples include RPE, sRPE, TRIMP, heart rate, lactate, and '
            'subjective fatigue.',
      ),
      InstructionSection(
        id: 'hrv_variables',
        title: 'HRV/RMSSD variables',
        summary: 'RMSSD recovery is required for slope calculation.',
        body:
            'RMSSD recovery is required. RMSSD exercise is optional because the '
            'app can use the explicitly marked 4 ms fallback when exercise '
            'RMSSD was not recorded.',
      ),
      InstructionSection(
        id: 'intensity_percent',
        title: 'intensity_percent requirements',
        summary:
            'Intensity percent is required for classification and nomograms.',
        body:
            'No classification is produced without intensity_percent. The app '
            'can use direct percent input or derive it from available external '
            'variables and athlete profile values.',
      ),
      InstructionSection(
        id: 'draft_sessions',
        title: 'Incomplete/draft sessions',
        summary: 'Draft sessions can store partial information.',
        body:
            'Incomplete or draft sessions should not show slope or '
            'classification until the required scientific inputs are present.',
      ),
    ],
  ),
  InstructionChapter(
    id: 'direct_rmssd',
    title: 'Direct RMSSD Workflow',
    sections: [
      InstructionSection(
        id: 'when_direct_rmssd',
        title: 'When to use direct RMSSD',
        summary: 'Direct RMSSD is the recommended/default workflow.',
        body:
            'Direct RMSSD is the recommended/default workflow because many '
            'field users already obtain RMSSD from validated HRV apps or '
            'analysis software.',
      ),
      InstructionSection(
        id: 'rmssd_sources',
        title: 'Elite HRV / Kubios / HRV Logger / Polar / Garmin sources',
        summary: 'Track where RMSSD values came from.',
        body:
            'Select the source that best describes the RMSSD value. Consistent '
            'source tracking makes longitudinal review easier.',
      ),
      InstructionSection(
        id: 'recovery_required',
        title: 'RMSSD recovery required',
        summary: 'Recovery RMSSD is the numerator endpoint for slope.',
        body:
            'RMSSD_recovery is required to calculate RMSSD-Slope. It should '
            'come from the selected valid recovery window.',
      ),
      InstructionSection(
        id: 'exercise_optional',
        title: 'RMSSD exercise optional',
        summary:
            'Exercise RMSSD improves traceability but is not always available.',
        body:
            'If RMSSD_exercise is measured, enter it. If RMSSD exercise is not '
            'available, the app can use the 4 ms fallback and marks it '
            'explicitly.',
      ),
      InstructionSection(
        id: 'fallback_4ms',
        title: '4 ms fallback',
        summary: 'Fallback use is always marked.',
        body:
            'The fallback RMSSD_exercise = 4 ms is only used when exercise '
            'RMSSD was not recorded. Reports and exports preserve the fallback '
            'flag.',
      ),
      InstructionSection(
        id: 'window_start_end',
        title: 'Recovery window start/end',
        summary: 'Enter both start and end times.',
        body:
            'The app stores recovery window start, recovery window end, window '
            'duration, and t used for slope. t equals the recovery window end.',
      ),
    ],
  ),
  InstructionChapter(
    id: 'rr_intervals',
    title: 'RR Interval Workflow',
    sections: [
      InstructionSection(
        id: 'when_rr',
        title: 'When to use RR intervals',
        summary: 'RR input is an advanced workflow.',
        body:
            'Use RR intervals when you need an auditable RR-derived RMSSD '
            'workflow or when direct RMSSD is not available.',
      ),
      InstructionSection(
        id: 'accepted_formats',
        title: 'Accepted formats',
        summary: 'Paste or import beat-to-beat intervals in milliseconds.',
        body:
            'RR interval input accepts common separators such as new lines, '
            'commas, semicolons, and tabs. Values are interpreted as '
            'milliseconds.',
      ),
      InstructionSection(
        id: 'rr_quality',
        title: 'RR quality report',
        summary: 'Quality control is shown before using RR-derived RMSSD.',
        body:
            'The quality report includes RR count, duration, min/max RR, '
            'artifact count, artifact percent, quality decision, and notes.',
      ),
      InstructionSection(
        id: 'raw_vs_corrected',
        title: 'Raw RMSSD vs corrected RMSSD',
        summary: 'Raw RMSSD is always preserved.',
        body:
            'Raw RMSSD is always preserved. Corrected NN-derived RMSSD is used '
            'for slope only when correction is explicitly enabled by the user.',
      ),
      InstructionSection(
        id: 'artifact_detection',
        title: 'Artifact detection',
        summary: 'RR/NN preprocessing detects outliers and ectopic candidates.',
        body:
            'The app detects range outliers, optional ectopic candidates, and '
            'local median outliers. These are RR/NN preprocessing steps, not '
            'raw signal filters.',
      ),
      InstructionSection(
        id: 'correction_default',
        title: 'Correction off by default',
        summary: 'Correction requires explicit user action.',
        body:
            'RR correction is off by default. If correction is enabled, the app '
            'stores raw RMSSD, corrected RMSSD, RMSSD used, correction method, '
            'artifact count, artifact percent, and quality notes.',
      ),
      InstructionSection(
        id: 'no_ecg_filtering',
        title: 'Why raw ECG/PPG filtering is not part of this app',
        summary: 'RR intervals are already beat-to-beat intervals.',
        body:
            'RR intervals are not raw ECG/PPG. Raw ECG/PPG would require '
            'signal filtering and peak detection, which is out of scope. This '
            'app performs RR/NN preprocessing only.',
      ),
    ],
  ),
  InstructionChapter(
    id: 'interpreting_results',
    title: 'Interpreting Results',
    sections: [
      InstructionSection(
        id: 'raw_vs_interpreted_slope',
        title: 'Raw slope vs interpreted slope',
        summary:
            'Both are preserved, but interpreted slope is used for classification.',
        body:
            'Raw slope is the direct calculation. Interpreted slope preserves '
            'the minimum interpretive value of 0.1 and is used for ITL and '
            'classification.',
      ),
      InstructionSection(
        id: 'itl_index',
        title: 'ITL index',
        summary: 'ITL is inverse to interpreted slope.',
        body:
            'ITL = 1 / interpreted_slope. Lower interpreted slope produces '
            'a higher ITL index.',
      ),
      InstructionSection(
        id: 'classification_language',
        title: 'Classification language',
        summary: 'Labels describe training-load response context.',
        body:
            'Classification compares observed interpreted slope with expected '
            'lower, mean, and upper bands at the session intensity. No '
            'classification is produced without intensity_percent.',
      ),
      InstructionSection(
        id: 'population_nomogram',
        title: 'Population nomogram',
        summary:
            'Population bands provide a reference when individual history is limited.',
        body:
            'The population nomogram shows lower, mean, and upper expected '
            'slope bands for the selected preset.',
      ),
      InstructionSection(
        id: 'individual_nomogram',
        title: 'Individual nomogram',
        summary: 'Athlete-specific references need enough data.',
        body:
            'Individual nomogram confidence levels are insufficient, initial, '
            'acceptable, and robust. Confidence depends on valid session count '
            'and low, medium, and high intensity spread.',
      ),
      InstructionSection(
        id: 'hybrid_mode',
        title: 'Hybrid mode',
        summary: 'Hybrid mode blends population and athlete history.',
        body:
            'Hybrid mode is used while individual data are accumulating but '
            'are not robust. It keeps population context while adding athlete '
            'history.',
      ),
      InstructionSection(
        id: 'residuals',
        title: 'Residuals',
        summary: 'Residuals show observed minus expected slope.',
        body:
            'Residual = observed interpreted slope - expected mean slope. '
            'Residual percent expresses that difference relative to expected '
            'mean slope.',
      ),
      InstructionSection(
        id: 'longitudinal_trends',
        title: 'Longitudinal trends',
        summary: 'Trends help review repeated-session patterns.',
        body:
            'The longitudinal dashboard shows slope, ITL, residuals, rolling '
            'averages, and load overlays across sessions.',
      ),
      InstructionSection(
        id: 'fatigue_flags',
        title: 'Fatigue/context flags',
        summary: 'Flags prompt context review.',
        body:
            'Flags mean review training context or monitor accumulated load. '
            'They are not diagnosis and should not be overinterpreted from one '
            'isolated session.',
      ),
    ],
  ),
  InstructionChapter(
    id: 'reports_exports',
    title: 'Reports and Exports',
    sections: [
      InstructionSection(
        id: 'individual_report',
        title: 'Individual report',
        summary: 'Review one session in detail.',
        body:
            'The individual report shows athlete, session, load variables, HRV '
            'data, raw slope, interpreted slope, ITL, classification, and '
            'population nomogram placement.',
      ),
      InstructionSection(
        id: 'group_report',
        title: 'Group report',
        summary: 'Compare matching sessions across athletes.',
        body:
            'The group report ranks complete sessions by interpreted slope '
            'ascending, where lower slope indicates higher internal load.',
      ),
      InstructionSection(
        id: 'population_screen',
        title: 'Population nomogram',
        summary: 'View population bands and eligible session points.',
        body:
            'The standalone population nomogram can show all eligible sessions '
            'or filter by athlete.',
      ),
      InstructionSection(
        id: 'longitudinal_dashboard',
        title: 'Longitudinal dashboard',
        summary: 'Review athlete trends over time.',
        body:
            'The dashboard shows slope, ITL, load overlays, residual trends, '
            'fatigue/context flags, and session links.',
      ),
      InstructionSection(
        id: 'individual_nomogram_screen',
        title: 'Individual nomogram',
        summary: 'Review population, individual, and hybrid references.',
        body:
            'The individual nomogram screen shows confidence, data needs, '
            'valid points, excluded sessions, and curve overlays.',
      ),
      InstructionSection(
        id: 'csv_exports',
        title: 'CSV exports',
        summary: 'CSV exports are available for analysis.',
        body:
            'CSV exports are available for individual reports, group reports, '
            'longitudinal dashboards, individual nomograms, and population '
            'nomogram curve points.',
      ),
      InstructionSection(
        id: 'xlsx_pdf_status',
        title: 'XLSX/PDF status',
        summary: 'XLSX and PDF are deferred.',
        body:
            'XLSX and PDF are not currently implemented. CSV is the supported '
            'export format unless later phases add more formats.',
      ),
    ],
  ),
  InstructionChapter(
    id: 'limitations_good_practice',
    title: 'Limitations and Good Practice',
    sections: [
      InstructionSection(
        id: 'not_medical',
        title: 'Not medical diagnosis',
        summary: 'Use the app for training-load monitoring only.',
        body: kInstructionsDisclaimer,
      ),
      InstructionSection(
        id: 'consistent_protocols',
        title: 'Need consistent protocols',
        summary: 'Protocol consistency improves comparison.',
        body:
            'Use consistent devices, posture, timing, recovery setting, and '
            'data sources whenever possible.',
      ),
      InstructionSection(
        id: 'enough_data',
        title: 'Need enough data for individual nomogram',
        summary:
            'Individual models require valid sessions and intensity spread.',
        body:
            'Individual references should not be treated as primary until '
            'confidence is robust.',
      ),
      InstructionSection(
        id: 'artifacts_corrections',
        title: 'Be cautious with artifacts and corrections',
        summary: 'Correction choices should remain auditable.',
        body:
            'Check artifact count, artifact percent, correction method, and '
            'RMSSD delta before using corrected NN-derived RMSSD.',
      ),
      InstructionSection(
        id: 'context',
        title:
            'Interpret with workload, recovery, sleep, illness, travel, and context',
        summary: 'No metric explains the whole athlete state.',
        body:
            'Review external load, internal load, recovery, sleep, illness, '
            'travel, environment, and notes before making training decisions.',
      ),
      InstructionSection(
        id: 'avoid_single_session',
        title: 'Avoid overinterpreting one isolated session',
        summary: 'Patterns are stronger than isolated points.',
        body:
            'Use repeated sessions, consistent protocols, and longitudinal '
            'context before changing training plans.',
      ),
    ],
  ),
];

String allInstructionText() {
  final buffer = StringBuffer()
    ..writeln(kInstructionsDisclaimer)
    ..writeln(kInstructionsRecommendedWorkflow);
  for (final chapter in instructionsChapters) {
    buffer.writeln(chapter.title);
    for (final section in chapter.sections) {
      buffer
        ..writeln(section.title)
        ..writeln(section.summary)
        ..writeln(section.body);
      for (final bullet in section.bullets) {
        buffer.writeln(bullet);
      }
      for (final warning in section.warnings) {
        buffer.writeln(warning);
      }
    }
  }
  return buffer.toString();
}
