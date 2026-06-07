// Phase 4.0A tests — Athlete Longitudinal Dashboard MVP.
import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/longitudinal_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_mode.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/shared/engine/statistics.dart';
import 'package:hrv_slope_app/ui/screens/athletes/athlete_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/longitudinal/athlete_longitudinal_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/widgets/longitudinal_chart.dart';
import 'package:hrv_slope_app/ui/widgets/nomogram_chart.dart';
import 'package:hrv_slope_app/ui/widgets/rpe_slope_quadrant_chart.dart';

void main() {
  group('Longitudinal builder', () {
    test('points sorted by date ascending', () {
      final series = _series([
        _detail(id: 1, date: '2026-05-03'),
        _detail(id: 2, date: '2026-05-01'),
        _detail(id: 3, date: '2026-05-02'),
      ]);

      expect(series.points.map((p) => p.date), [
        '2026-05-01',
        '2026-05-02',
        '2026-05-03',
      ]);
    });

    test('summary counts complete sessions', () {
      final series = _series([
        _detail(id: 1, slope: 0.5),
        _detail(id: 2, slope: null),
      ]);

      expect(series.summary.nSessions, 2);
      expect(series.summary.nComplete, 1);
    });

    test('latest slope ITL and classification', () {
      final series = _series([
        _detail(id: 1, slope: 0.5),
        _detail(id: 2, slope: 1.0),
      ]);

      expect(series.summary.latestSlope, 1.0);
      expect(series.summary.latestItl, 1.0);
      expect(series.summary.latestClassification, isNotNull);
    });

    test('mean min max slope', () {
      final series = _series([
        _detail(id: 1, slope: 0.5),
        _detail(id: 2, slope: 1.0),
        _detail(id: 3, slope: 1.5),
      ]);

      expect(series.summary.meanSlope, closeTo(1.0, 0.001));
      expect(series.summary.minSlope, 0.5);
      expect(series.summary.maxSlope, 1.5);
    });

    test('trendDirection insufficient with too few points', () {
      final series = _series([_detail(id: 1), _detail(id: 2)]);

      expect(
        series.summary.trendDirection,
        LongitudinalTrendDirection.insufficientData,
      );
    });

    test('trendDirection improving when slope rises', () {
      final series = _series([
        _detail(id: 1, slope: 0.5),
        _detail(id: 2, slope: 0.6),
        _detail(id: 3, slope: 0.7),
        _detail(id: 4, slope: 1.0),
        _detail(id: 5, slope: 1.1),
        _detail(id: 6, slope: 1.2),
      ]);

      expect(
        series.summary.trendDirection,
        LongitudinalTrendDirection.improving,
      );
    });

    test('trendDirection worsening when slope falls', () {
      final series = _series([
        _detail(id: 1, slope: 1.2),
        _detail(id: 2, slope: 1.1),
        _detail(id: 3, slope: 1.0),
        _detail(id: 4, slope: 0.7),
        _detail(id: 5, slope: 0.6),
        _detail(id: 6, slope: 0.5),
      ]);

      expect(
        series.summary.trendDirection,
        LongitudinalTrendDirection.worsening,
      );
    });

    test('extracts RPE sRPE TRIMP from internal variables', () {
      final series = _series([_detail(id: 1, rpe: 7, srpe: 420, trimp: 80)]);

      expect(series.points.single.rpe, 7);
      expect(series.points.single.srpe, 420);
      expect(series.points.single.trimp, 80);
    });

    test('extracts primary external load', () {
      final series = _series([_detail(id: 1, externalName: 'player_load')]);

      expect(series.points.single.primaryExternalLoadName, 'player_load');
      expect(series.points.single.primaryExternalLoadValue, 100);
    });

    test('residual values included', () {
      final series = _series([_detail(id: 1, intensity: 80, slope: 0.5)]);

      expect(series.points.single.residual, isNotNull);
      expect(series.points.single.residualPercent, isNotNull);
    });

    test('missing values generate warnings', () {
      final series = _series([_detail(id: 1, intensity: null, slope: null)]);

      expect(series.points.single.warnings, isNotEmpty);
    });

    test('filter by sport', () {
      final series = _series([
        _detail(id: 1, sport: 'Running'),
        _detail(id: 2, sport: 'Cycling'),
      ], filter: const LongitudinalDashboardFilter(sports: {'Running'}));

      expect(series.points.map((p) => p.sport), ['Running']);
    });

    test('filter by session task/name', () {
      final series = _series([
        _detail(id: 1, taskName: 'HIIT'),
        _detail(id: 2, taskName: 'Tempo'),
      ], filter: const LongitudinalDashboardFilter(sessionTasks: {'HIIT'}));

      expect(series.points.single.taskName, 'HIIT');
    });

    test('filter by session type', () {
      final series = _series([
        _detail(id: 1, sessionType: 'training'),
        _detail(id: 2, sessionType: 'test'),
      ], filter: const LongitudinalDashboardFilter(sessionTypes: {'test'}));

      expect(series.points.single.sessionType, 'test');
    });

    test('filter by protocol name', () {
      final series = _series([
        _detail(id: 1, protocolName: '5-10'),
        _detail(id: 2, protocolName: '10-15'),
      ], filter: const LongitudinalDashboardFilter(protocolNames: {'10-15'}));

      expect(series.points.single.protocolName, '10-15');
    });

    test('filter by context/environment', () {
      final series = _series(
        [
          _detail(id: 1, contextEnvironment: 'Indoor'),
          _detail(id: 2, contextEnvironment: 'Outdoor'),
        ],
        filter: const LongitudinalDashboardFilter(
          contextEnvironmentTags: {'Outdoor'},
        ),
      );

      expect(series.points.single.contextEnvironment, 'Outdoor');
    });

    test('filter by context tag split with semicolon', () {
      final series = _series(
        [
          _detail(id: 1, contextEnvironment: 'heat; humidity; indoor'),
          _detail(id: 2, contextEnvironment: 'cold; outdoor'),
        ],
        filter: const LongitudinalDashboardFilter(
          contextEnvironmentTags: {'heat'},
        ),
      );

      expect(series.points.single.sessionId, 1);
    });

    test('filter by context tag split with pipe preserves spaced tag', () {
      final series = _series(
        [
          _detail(id: 1, contextEnvironment: 'sea level | high humidity'),
          _detail(id: 2, contextEnvironment: 'altitude | dry'),
        ],
        filter: const LongitudinalDashboardFilter(
          contextEnvironmentTags: {'high humidity'},
        ),
      );

      expect(series.points.single.sessionId, 1);
    });

    test('filter by complete context value still works', () {
      final series = _series(
        [
          _detail(id: 1, contextEnvironment: 'sea level | high humidity'),
          _detail(id: 2, contextEnvironment: 'altitude | dry'),
        ],
        filter: const LongitudinalDashboardFilter(
          contextEnvironmentTags: {'sea level | high humidity'},
        ),
      );

      expect(series.points.single.sessionId, 1);
    });

    test('dateTo includes ISO datetime on same calendar day', () {
      final series = _series([
        _detail(id: 1, date: '2026-05-27T10:00:00'),
        _detail(id: 2, date: '2026-05-28T10:00:00'),
      ], filter: const LongitudinalDashboardFilter(dateTo: '2026-05-27'));

      expect(series.points.single.sessionId, 1);
    });

    test('dateFrom and dateTo work with YYYY-MM-DD dates', () {
      final series = _series(
        [
          _detail(id: 1, date: '2026-05-26'),
          _detail(id: 2, date: '2026-05-27'),
          _detail(id: 3, date: '2026-05-28'),
        ],
        filter: const LongitudinalDashboardFilter(
          dateFrom: '2026-05-27',
          dateTo: '2026-05-27',
        ),
      );

      expect(series.points.single.sessionId, 2);
    });

    test('filter by intensity source', () {
      final series = _series(
        [
          _detail(id: 1, intensitySource: 'direct_percent_mas'),
          _detail(id: 2, intensitySource: 'internal_rpe_1_10'),
        ],
        filter: const LongitudinalDashboardFilter(
          intensitySourcesForSlope: {'Internal'},
        ),
      );

      expect(series.points.single.intensitySourceForSlope, 'Internal');
    });

    test('filter by RPE range', () {
      final series = _series([
        _detail(id: 1, rpe: 4),
        _detail(id: 2, rpe: 8),
      ], filter: const LongitudinalDashboardFilter(rpeMin: 7, rpeMax: 9));

      expect(series.points.single.rpe, 8);
    });

    test('extracts session_rpe_1_10 alias as longitudinal RPE', () {
      final series = _series([
        _detail(id: 1, rpe: 6, rpeVariableName: 'session_rpe_1_10'),
      ]);

      expect(series.points.single.rpe, 6);
    });

    test('filter by fatigue range', () {
      final series = _series(
        [_detail(id: 1, fatigue: 3), _detail(id: 2, fatigue: 7)],
        filter: const LongitudinalDashboardFilter(fatigueMin: 6, fatigueMax: 8),
      );

      expect(series.points.single.fatigue, 7);
    });

    test('filter by slope range', () {
      final series = _series([
        _detail(id: 1, slope: 0.4),
        _detail(id: 2, slope: 1.2),
      ], filter: const LongitudinalDashboardFilter(slopeMin: 1));

      expect(series.points.single.interpretedSlope, 1.2);
    });

    test('combined filter', () {
      final series = _series(
        [
          _detail(id: 1, sport: 'Running', rpe: 8, slope: 1.1),
          _detail(id: 2, sport: 'Running', rpe: 4, slope: 1.2),
          _detail(id: 3, sport: 'Cycling', rpe: 8, slope: 1.3),
        ],
        filter: const LongitudinalDashboardFilter(
          sports: {'Running'},
          rpeMin: 7,
          slopeMin: 1,
        ),
      );

      expect(series.points.single.sessionId, 1);
    });

    test('filter can return no results', () {
      final series = _series([
        _detail(id: 1, sport: 'Running'),
      ], filter: const LongitudinalDashboardFilter(sports: {'Swimming'}));

      expect(series.points, isEmpty);
      expect(series.excludedPoints, hasLength(1));
    });

    test('activeFilterCount and activeFilterLabels', () {
      const filter = LongitudinalDashboardFilter(
        sports: {'Running'},
        rpeMin: 7,
        comparableSessionsOnly: true,
      );

      expect(filter.activeFilterCount, 3);
      expect(filter.activeFilterLabels(), contains('Sport: Running'));
      expect(filter.activeFilterLabels(), contains('Comparable sessions only'));
    });

    test('comparable sessions mode uses latest included session', () {
      final series = _series(
        [
          _detail(id: 1, taskName: 'Tempo', intensity: 70, rpe: 6),
          _detail(id: 2, taskName: 'HIIT', intensity: 90, rpe: 9),
          _detail(id: 3, taskName: 'Tempo', intensity: 78, rpe: 7),
        ],
        filter: const LongitudinalDashboardFilter(comparableSessionsOnly: true),
      );

      expect(series.points.map((p) => p.sessionId), [1, 3]);
      expect(series.comparableIncludedCount, 2);
      expect(series.comparableTotalCount, 3);
    });

    test('data completeness counts filtered sessions', () {
      final series = _series([
        _detail(id: 1, intensitySource: 'direct_percent_mas', fatigue: 4),
        _detail(id: 2, intensitySource: 'internal_rpe_1_10', slope: null),
      ]);

      expect(series.completeness.includedSessions, 2);
      expect(series.completeness.totalSessions, 2);
      expect(series.completeness.withExternalIntensity, 1);
      expect(series.completeness.withInternalFallback, 1);
      expect(series.completeness.withRpe, 2);
      expect(series.completeness.withFatigue, 1);
      expect(series.completeness.missingKeyData, 1);
    });

    test('tooltip data model includes session metadata', () {
      final series = _series([
        _detail(
          id: 1,
          taskName: 'Tempo',
          protocolName: '5-10',
          contextEnvironment: 'Indoor',
          fatigue: 5,
          notes: 'Good session',
        ),
      ]);
      final point = series.points.single;

      expect(point.protocolName, '5-10');
      expect(point.contextEnvironment, 'Indoor');
      expect(point.notes, contains('Good session'));
    });

    test('dashboard without filters shows all sessions', () {
      final series = _series([_detail(id: 1), _detail(id: 2)]);

      expect(series.points, hasLength(2));
      expect(series.filter.isEmpty, isTrue);
    });

    test('filter option values are alphabetically sorted', () {
      final series = _series([
        _detail(id: 1, sport: 'Cycling'),
        _detail(id: 2, sport: 'Running'),
        _detail(id: 3, sport: 'Athletics'),
      ]);

      expect(series.filterOptions.sports.toList(), [
        'Athletics',
        'Cycling',
        'Running',
      ]);
    });

    test('builds slope_Orellana_19 reference for session with intensity', () {
      final series = _series([_detail(id: 1, intensity: 80, slope: 0.5)]);
      final reference = series.points.single.nomogramReference;

      expect(reference.source, 'slope_Orellana_19');
      expect(reference.referenceSlope, isNotNull);
      expect(reference.lowerSlopeThreshold, isNotNull);
      expect(reference.upperSlopeThreshold, isNotNull);
      expect(
        reference.referenceItl,
        closeTo(1 / reference.referenceSlope!, 1e-9),
      );
      expect(reference.zone, isNot(LongitudinalRecoveryZone.unavailable));
      expect(series.nomogramReferenceSeries.availableCount, 1);
    });

    test('missing primary intensity makes reference unavailable', () {
      final series = _series([_detail(id: 1, intensity: null, slope: 0.5)]);
      final reference = series.points.single.nomogramReference;

      expect(reference.zone, LongitudinalRecoveryZone.unavailable);
      expect(reference.unavailableReason, 'missing primary intensity');
      expect(reference.referenceSlope, isNull);
    });

    test('missing slope makes reference unavailable without breaking', () {
      final series = _series([_detail(id: 1, intensity: 80, slope: null)]);
      final reference = series.points.single.nomogramReference;

      expect(reference.zone, LongitudinalRecoveryZone.unavailable);
      expect(reference.unavailableReason, 'missing slope');
      expect(series.points.single.interpretedSlope, isNull);
    });

    test('references respect active filters', () {
      final series = _series([
        _detail(id: 1, sport: 'Running', intensity: 80, slope: 0.5),
        _detail(id: 2, sport: 'Cycling', intensity: 80, slope: 0.5),
      ], filter: const LongitudinalDashboardFilter(sports: {'Running'}));

      expect(series.points, hasLength(1));
      expect(series.nomogramReferenceSeries.points, hasLength(1));
      expect(series.nomogramReferenceSeries.availableCount, 1);
      expect(series.points.single.sport, 'Running');
    });

    test('reference ITL is derived safely from reference slope', () {
      final reference = buildSlopeOrellana19LongitudinalReference(
        sessionId: 1,
        date: '2026-05-01',
        primaryIntensityValue: 80,
        primaryIntensityMetric: 'direct_percent_mas',
        intensitySourceForSlope: 'External',
        observedSlope: 0.5,
        observedItl: 2,
      );

      expect(reference.referenceSlope, isNotNull);
      expect(
        reference.referenceItl,
        closeTo(1 / reference.referenceSlope!, 1e-9),
      );
      expect(reference.lowerItlThreshold, isNotNull);
      expect(reference.upperItlThreshold, isNotNull);

      final unavailable = buildSlopeOrellana19LongitudinalReference(
        sessionId: 2,
        date: '2026-05-02',
        primaryIntensityValue: 80,
        primaryIntensityMetric: 'direct_percent_mas',
        intensitySourceForSlope: 'External',
        observedSlope: 0,
        observedItl: null,
      );
      expect(unavailable.referenceItl, isNull);
      expect(unavailable.zone, LongitudinalRecoveryZone.unavailable);
    });

    test('recovery zones follow slope_Orellana_19 bands', () {
      final bands = evaluatePopulationNomogramBands(
        80,
        source: PopulationNomogramSource.slopeOrellana19,
      );
      final low = buildSlopeOrellana19LongitudinalReference(
        sessionId: 1,
        date: '2026-05-01',
        primaryIntensityValue: 80,
        primaryIntensityMetric: 'direct_percent_mas',
        intensitySourceForSlope: 'External',
        observedSlope: bands.expectedLower / 2,
        observedItl: null,
      );
      final normal = buildSlopeOrellana19LongitudinalReference(
        sessionId: 2,
        date: '2026-05-02',
        primaryIntensityValue: 80,
        primaryIntensityMetric: 'direct_percent_mas',
        intensitySourceForSlope: 'External',
        observedSlope: bands.expectedMean,
        observedItl: null,
      );
      final favorable = buildSlopeOrellana19LongitudinalReference(
        sessionId: 3,
        date: '2026-05-03',
        primaryIntensityValue: 80,
        primaryIntensityMetric: 'direct_percent_mas',
        intensitySourceForSlope: 'External',
        observedSlope: bands.expectedUpper + 0.2,
        observedItl: null,
      );

      expect(low.zone, LongitudinalRecoveryZone.low);
      expect(normal.zone, LongitudinalRecoveryZone.normal);
      expect(favorable.zone, LongitudinalRecoveryZone.favorable);
    });

    test('data completeness counts reference availability and zones', () {
      final series = _series([
        _detail(id: 1, intensity: 80, slope: 0.1),
        _detail(id: 2, intensity: null, slope: 0.5),
        _detail(id: 3, intensity: 80, slope: 2.0),
      ]);

      expect(series.completeness.withSlopeOrellana19Reference, 2);
      expect(series.completeness.missingReferencePrimaryIntensity, 1);
      expect(series.completeness.referenceZoneLow, 1);
      expect(series.completeness.referenceZoneFavorable, 1);
    });

    test('builds RPE slope quadrant data with response indexes', () {
      final bands = evaluatePopulationNomogramBands(
        80,
        source: PopulationNomogramSource.slopeOrellana19,
      );
      final series = _series([
        _detail(id: 1, rpe: 6.9, intensity: 80, slope: bands.expectedMean),
        _detail(id: 2, rpe: 7.0, intensity: 80, slope: bands.expectedMean),
        _detail(id: 3, rpe: 8, intensity: 80, slope: bands.expectedMean / 2),
        _detail(id: 4, rpe: 4, intensity: 80, slope: bands.expectedMean / 2),
      ]);

      final data = series.rpeSlopeQuadrantData;

      expect(data.highRpeThreshold, 7.0);
      expect(data.summary.pointsShown, 4);
      expect(
        data.points.first.slopeResponseIndex,
        closeTo(
          data.points.first.observedSlope! / data.points.first.referenceSlope!,
          1e-9,
        ),
      );
      expect(data.points.map((point) => point.quadrant), [
        RpeSlopeQuadrant.lowRpeFavorableSlopeResponse,
        RpeSlopeQuadrant.highRpeFavorableSlopeResponse,
        RpeSlopeQuadrant.highRpeLowSlopeResponse,
        RpeSlopeQuadrant.lowRpeLowSlopeResponse,
      ]);
      expect(data.summary.lowRpeFavorableSlopeResponse, 1);
      expect(data.summary.highRpeFavorableSlopeResponse, 1);
      expect(data.summary.highRpeLowSlopeResponse, 1);
      expect(data.summary.lowRpeLowSlopeResponse, 1);
    });

    test('quadrant data marks unavailable and respects filters', () {
      final series = _series([
        _detail(id: 1, sport: 'Running', rpe: null, intensity: 80, slope: 0.5),
        _detail(id: 2, sport: 'Running', rpe: 8, intensity: null, slope: 0.5),
        _detail(id: 3, sport: 'Cycling', rpe: 6, intensity: 80, slope: 0.5),
      ], filter: const LongitudinalDashboardFilter(sports: {'Running'}));

      final data = series.rpeSlopeQuadrantData;

      expect(series.points.map((point) => point.sport), ['Running', 'Running']);
      expect(data.points, hasLength(2));
      expect(data.summary.pointsShown, 0);
      expect(data.summary.missingRpe, 1);
      expect(data.summary.missingReference, 1);
      expect(data.points.map((point) => point.quadrant), [
        RpeSlopeQuadrant.unavailable,
        RpeSlopeQuadrant.unavailable,
      ]);
      expect(data.points.first.unavailableReason, 'missing RPE');
      expect(data.points.last.unavailableReason, 'missing primary intensity');
    });

    test('quadrant data respects comparable sessions only', () {
      final series = _series(
        [
          _detail(
            id: 1,
            taskName: 'Tempo',
            protocolName: '5-10',
            contextEnvironment: 'Indoor',
            intensity: 80,
            slope: 0.5,
          ),
          _detail(
            id: 2,
            taskName: 'HIIT',
            protocolName: '5-10',
            contextEnvironment: 'Indoor',
            intensity: 80,
            slope: 0.5,
          ),
          _detail(
            id: 3,
            taskName: 'Tempo',
            protocolName: '5-10',
            contextEnvironment: 'Indoor',
            intensity: 80,
            slope: 0.5,
          ),
        ],
        filter: const LongitudinalDashboardFilter(comparableSessionsOnly: true),
      );

      expect(series.points.map((point) => point.taskName).toSet(), {'Tempo'});
      expect(
        series.rpeSlopeQuadrantData.points.map((point) => point.sessionId),
        series.points.map((point) => point.sessionId),
      );
    });
  });

  group('Longitudinal chart scaling', () {
    test('negative residual values produce a negative y-axis minimum', () {
      final scale = resolveLongitudinalYAxisScale([-0.7, -0.2, 0.3]);

      expect(scale.minY, lessThan(-0.7));
      expect(scale.maxY, greaterThan(0.3));
    });

    test('positive values can keep zero as y-axis minimum', () {
      final scale = resolveLongitudinalYAxisScale([0.4, 1.2]);

      expect(scale.minY, 0);
      expect(scale.maxY, greaterThan(1.2));
    });

    test('primary intensity overlay stays 0-100 when max is <= 100', () {
      final max = resolvePrimaryIntensityOverlayMax([80, 100]);

      expect(max, 100);
      expect(resolvePrimaryIntensityOverlayInterval(max), 25);
    });

    test('primary intensity overlay expands above 100 with clean ticks', () {
      final max = resolvePrimaryIntensityOverlayMax([80, 110, 120]);

      expect(max, 125);
      expect(resolvePrimaryIntensityOverlayInterval(max), 25);
    });
  });

  group('Longitudinal filter UI labels', () {
    test('maps direct_percent_mas to %MAS', () {
      expect(longitudinalIntensityMetricLabel('direct_percent_mas'), '%MAS');
    });

    test('maps rpe_1_10 to RPE 1-10', () {
      expect(longitudinalIntensityMetricLabel('rpe_1_10'), 'RPE 1-10');
    });

    test('maps session_rpe_1_10 to Session RPE 1-10', () {
      expect(
        longitudinalIntensityMetricLabel('session_rpe_1_10'),
        'Session RPE 1-10',
      );
    });

    test('humanizes unknown metric names without raw snake_case', () {
      final label = longitudinalIntensityMetricLabel('unknown_metric_name');

      expect(label, 'Unknown Metric Name');
      expect(label, isNot(contains('_')));
    });

    test('maps intensity source labels', () {
      expect(longitudinalIntensitySourceLabel('External'), 'External load');
      expect(longitudinalIntensitySourceLabel('Internal'), 'Internal load');
      expect(longitudinalIntensitySourceLabel('Unknown'), 'Unknown');
    });
  });

  group('Rolling and fatigue flags', () {
    test('rolling average calculation works', () {
      final result = rollingAverage([1, 2, 3, 4], 3);

      expect(result, [1, 1.5, 2, 3]);
    });

    test('3 negative residuals below threshold triggers flag', () {
      final series = _series([
        _detail(id: 1, intensity: 60, slope: 0.5),
        _detail(id: 2, intensity: 60, slope: 0.5),
        _detail(id: 3, intensity: 60, slope: 0.5),
      ]);

      expect(
        series.fatigueFlags.any(
          (f) => f.ruleName == 'three_negative_residuals',
        ),
        isTrue,
      );
    });

    test('slope 7 vs 28 drop triggers flag', () {
      final details = <SessionDetail>[
        for (var i = 0; i < 21; i++) _detail(id: i + 1, slope: 1.0),
        for (var i = 21; i < 28; i++) _detail(id: i + 1, slope: 0.4),
      ];
      final series = _series(details);

      expect(
        series.fatigueFlags.any((f) => f.ruleName == 'slope_7_vs_28_drop'),
        isTrue,
      );
    });

    test('ITL 7 vs 28 increase triggers flag', () {
      final details = <SessionDetail>[
        for (var i = 0; i < 21; i++) _detail(id: i + 1, slope: 2.0),
        for (var i = 21; i < 28; i++) _detail(id: i + 1, slope: 0.67),
      ];
      final series = _series(details);

      expect(
        series.fatigueFlags.any((f) => f.ruleName == 'itl_7_vs_28_increase'),
        isTrue,
      );
    });

    test('no false flag with insufficient data', () {
      final series = _series([_detail(id: 1), _detail(id: 2)]);

      expect(series.fatigueFlags, isEmpty);
    });
  });

  group('Longitudinal UI', () {
    late AppDatabase db;
    late int athleteId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      athleteId = await _seedAthlete(db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('athlete detail exposes Longitudinal button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AthleteDetailScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Longitudinal'), findsOneWidget);
    });

    testWidgets('longitudinal screen renders header and summary cards', (
      tester,
    ) async {
      await _seedSession(db, athleteId, slope: 0.5);
      await _seedSession(db, athleteId, slope: 1.0, day: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Runner One'), findsOneWidget);
      expect(find.textContaining('Latest slope'), findsOneWidget);
      expect(find.text('Data completeness'), findsOneWidget);
      expect(find.textContaining('Included / total'), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const Key('longitudinal_data_completeness_header')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('longitudinal_data_completeness_header')),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('Included / total'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Included / total'), findsOneWidget);
      await _dragUntilVisible(tester, find.text('Slope Trend'));
      expect(find.text('Slope Trend'), findsOneWidget);
    });

    testWidgets('slope chart renders with complete data', (tester) async {
      await _seedSession(db, athleteId, slope: 0.5);
      await _seedSession(db, athleteId, slope: 1.0, day: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: LongitudinalChart(
            title: 'Slope Trend',
            valueLabel: 'Slope',
            points: const [
              LongitudinalChartPoint(label: '1', value: 0.5),
              LongitudinalChartPoint(label: '2', value: 1.0),
            ],
          ),
        ),
      );

      expect(find.text('Slope Trend'), findsOneWidget);
      expect(find.textContaining('Line: session trend'), findsOneWidget);
    });

    testWidgets('chart segments reference null gaps and renders legend', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LongitudinalChart(
            title: 'Slope Trend',
            valueLabel: 'Slope',
            points: const [
              LongitudinalChartPoint(label: '1', value: 0.5),
              LongitudinalChartPoint(label: '2', value: null),
              LongitudinalChartPoint(label: '3', value: 0.6),
              LongitudinalChartPoint(label: '4', value: 0.7),
            ],
            referenceSeries: const [
              LongitudinalChartReferenceSeries(
                label: 'slope_Orellana_19 reference',
                color: Colors.teal,
                points: [
                  LongitudinalChartPoint(label: '1', value: 0.4),
                  LongitudinalChartPoint(label: '2', value: null),
                  LongitudinalChartPoint(label: '3', value: 0.45),
                  LongitudinalChartPoint(label: '4', value: 0.5),
                ],
              ),
            ],
          ),
        ),
      );

      expect(find.text('Observed Slope'), findsOneWidget);
      expect(find.text('slope_Orellana_19 reference'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final referenceBars = chart.data.lineBarsData
          .where((bar) => bar.color == Colors.teal)
          .toList();

      expect(referenceBars, hasLength(2));
      expect(referenceBars.first.spots.map((spot) => spot.x), [0]);
      expect(referenceBars.last.spots.map((spot) => spot.x), [2, 3]);
    });

    testWidgets('chart tooltip and tap use session index with null observed', (
      tester,
    ) async {
      int? selectedSessionId;

      await tester.pumpWidget(
        MaterialApp(
          home: LongitudinalChart(
            title: 'Slope Trend',
            valueLabel: 'Slope',
            onPointSelected: (sessionId) => selectedSessionId = sessionId,
            points: const [
              LongitudinalChartPoint(
                sessionId: 1,
                label: '1',
                value: 0.5,
                tooltip: 'Session 1 observed',
              ),
              LongitudinalChartPoint(
                sessionId: 2,
                label: '2',
                value: null,
                tooltip: 'Session 2 observed unavailable',
              ),
              LongitudinalChartPoint(
                sessionId: 3,
                label: '3',
                value: 0.7,
                tooltip: 'Session 3 observed',
              ),
            ],
            referenceSeries: const [
              LongitudinalChartReferenceSeries(
                label: 'slope_Orellana_19 reference',
                color: Colors.teal,
                points: [
                  LongitudinalChartPoint(label: '1', value: null),
                  LongitudinalChartPoint(label: '2', value: 0.45),
                  LongitudinalChartPoint(label: '3', value: 0.5),
                ],
              ),
            ],
          ),
        ),
      );

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final referenceBarIndex = chart.data.lineBarsData.indexWhere(
        (bar) => bar.color == Colors.teal,
      );
      final referenceBar = chart.data.lineBarsData[referenceBarIndex];
      final referenceSpot = referenceBar.spots.firstWhere(
        (spot) => spot.x == 1,
      );
      final touchedSpot = TouchLineBarSpot(
        referenceBar,
        referenceBarIndex,
        referenceSpot,
        0,
      );

      final tooltipItems = chart.data.lineTouchData.touchTooltipData
          .getTooltipItems([touchedSpot]);
      expect(
        tooltipItems.single!.text,
        contains('Session 2 observed unavailable'),
      );

      chart.data.lineTouchData.touchCallback?.call(
        FlTapUpEvent(
          TapUpDetails(
            kind: PointerDeviceKind.touch,
            globalPosition: Offset.zero,
            localPosition: Offset.zero,
          ),
        ),
        LineTouchResponse(
          touchLocation: Offset.zero,
          touchChartCoordinate: Offset.zero,
          lineBarSpots: [touchedSpot],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(selectedSessionId, 2);
    });

    testWidgets(
      'RPE slope quadrant chart shows thresholds tooltip and select',
      (tester) async {
        int? selectedSessionId;
        const data = RpeSlopeQuadrantData(
          highRpeThreshold: 7,
          points: [
            RpeSlopeQuadrantPoint(
              sessionId: 11,
              date: '2026-05-28',
              sessionTaskName: 'RSA',
              rpe: 6,
              observedSlope: 0.8,
              observedItl: 1.25,
              primaryIntensityValue: 60,
              primaryIntensityMetric: 'rpe_1_10',
              intensitySourceForSlope: 'Internal',
              referenceSlope: 2.2,
              slopeResponseIndex: 0.36,
              recoveryZone: LongitudinalRecoveryZone.low,
              quadrant: RpeSlopeQuadrant.lowRpeLowSlopeResponse,
              notesSummary: 'Notes should not appear in compact tooltip',
            ),
          ],
          summary: RpeSlopeQuadrantSummary(
            pointsShown: 1,
            missingRpe: 0,
            missingReference: 0,
            lowRpeFavorableSlopeResponse: 0,
            highRpeFavorableSlopeResponse: 0,
            highRpeLowSlopeResponse: 0,
            lowRpeLowSlopeResponse: 1,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RpeSlopeQuadrantChart(
                  data: data,
                  onPointSelected: (sessionId) => selectedSessionId = sessionId,
                ),
              ),
            ),
          ),
        );

        expect(find.text('RPE vs Slope response'), findsOneWidget);
        expect(find.text('How to read'), findsOneWidget);
        expect(find.text('X axis'), findsOneWidget);
        expect(find.text('RPE 1-10'), findsWidgets);
        expect(find.text('Y axis'), findsOneWidget);
        expect(
          find.text('Observed slope divided by reference slope'),
          findsOneWidget,
        );
        expect(find.text('Thresholds'), findsOneWidget);
        expect(find.text('RPE 7.0 and response 1.0'), findsOneWidget);
        expect(find.text('Quadrants'), findsOneWidget);
        expect(find.text('RPE threshold'), findsOneWidget);
        expect(find.text('Expected slope response = 1.0'), findsOneWidget);
        expect(find.textContaining('Lower-than-expected:'), findsOneWidget);
        expect(find.textContaining('Expected:'), findsOneWidget);
        expect(find.textContaining('Favorable:'), findsOneWidget);
        expect(find.textContaining('Unavailable:'), findsOneWidget);

        final chart = tester.widget<LineChart>(find.byType(LineChart));
        expect(chart.data.extraLinesData.verticalLines.single.x, 7);
        expect(chart.data.extraLinesData.horizontalLines.single.y, 1);

        final bar = chart.data.lineBarsData.single;
        final touchedSpot = TouchLineBarSpot(bar, 0, bar.spots.single, 0);
        final tooltip = chart.data.lineTouchData.touchTooltipData
            .getTooltipItems([touchedSpot])
            .single!;

        expect(tooltip.text, contains('2026-05-28'));
        expect(tooltip.text, contains('RSA'));
        expect(tooltip.text, contains('RPE: 6.0'));
        expect(tooltip.text, contains('Slope: 0.800'));
        expect(tooltip.text, contains('Response index: 0.36'));
        expect(tooltip.text, contains('Response: Lower-than-expected'));
        expect(tooltip.text, contains('Intensity: 60.0%'));
        expect(tooltip.text, isNot(contains('Notes should not appear')));
        expect(tooltip.text, isNot(contains('threshold')));

        chart.data.lineTouchData.touchCallback?.call(
          FlTapUpEvent(
            TapUpDetails(
              kind: PointerDeviceKind.touch,
              globalPosition: Offset.zero,
              localPosition: Offset.zero,
            ),
          ),
          LineTouchResponse(
            touchLocation: Offset.zero,
            touchChartCoordinate: Offset.zero,
            lineBarSpots: [touchedSpot],
          ),
        );

        expect(selectedSessionId, 11);
      },
    );

    testWidgets('empty state when no complete sessions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      await _dragUntilVisible(
        tester,
        find.textContaining('Not enough complete sessions'),
      );
      expect(
        find.textContaining('Not enough complete sessions'),
        findsOneWidget,
      );
    });

    testWidgets('session list includes Open Report action', (tester) async {
      await _seedSession(db, athleteId, slope: 0.5);

      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Open report'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Open report'), findsOneWidget);
      final sessionTile = find.widgetWithText(ListTile, 'Session 1');
      await tester.ensureVisible(sessionTile);
      await tester.pumpAndSettle();
      await tester.tap(sessionTile);
      await tester.pumpAndSettle();
      await _dragBackUntilVisible(tester, find.text('Selected session'));

      expect(find.text('Selected session'), findsOneWidget);
      expect(find.textContaining('Reference slope'), findsWidgets);
      expect(find.textContaining('Low threshold'), findsWidgets);
      expect(find.textContaining('Favorable threshold'), findsWidgets);
    });

    testWidgets('dashboard colors points by zone without reference lines', (
      tester,
    ) async {
      final bands = evaluatePopulationNomogramBands(
        80,
        source: PopulationNomogramSource.slopeOrellana19,
      );
      await _seedSession(
        db,
        athleteId,
        slope: bands.expectedLower / 2,
        notes: 'Full notes should stay out of compact chart tooltips',
      );
      await _seedSession(db, athleteId, slope: bands.expectedMean, day: 2);
      await _seedSession(
        db,
        athleteId,
        slope: bands.expectedUpper + 0.2,
        day: 3,
      );
      await _seedSession(db, athleteId, slope: 0.7, intensity: null, day: 4);

      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('longitudinal_data_completeness_header')),
      );
      await tester.pumpAndSettle();
      await _dragUntilVisible(
        tester,
        find.text('Color points by recovery status'),
      );
      expect(find.text('Color points by recovery status'), findsOneWidget);
      expect(find.text('Show slope_Orellana_19 reference'), findsNothing);

      await _dragUntilVisible(tester, find.text('Slope Trend'));

      final slopeChart = tester
          .widgetList<LongitudinalChart>(find.byType(LongitudinalChart))
          .firstWhere((chart) => chart.title == 'Slope Trend');
      expect(slopeChart.referenceSeries, isEmpty);
      expect(slopeChart.points.map((point) => point.color), [
        AppColors.warning,
        AppColors.primary,
        AppColors.success,
        AppColors.textHint,
      ]);
      expect(slopeChart.points.first.tooltip, contains('2026-05-01'));
      expect(slopeChart.points.first.tooltip, contains('Session 1'));
      expect(slopeChart.points.first.tooltip, contains('Slope:'));
      expect(
        slopeChart.points.first.tooltip,
        contains('Recovery status: Lower-than-expected'),
      );
      expect(slopeChart.points.first.tooltip, contains('Intensity:'));
      expect(
        slopeChart.points.first.tooltip,
        isNot(contains('Full notes should stay out')),
      );
      expect(
        slopeChart.points.first.tooltip,
        isNot(contains('Reference slope')),
      );
      expect(slopeChart.points.first.tooltip, isNot(contains('threshold')));

      final slopeChartFinder = find.byWidgetPredicate(
        (widget) =>
            widget is LongitudinalChart && widget.title == 'Slope Trend',
      );
      final lineChart = tester.widget<LineChart>(
        find.descendant(of: slopeChartFinder, matching: find.byType(LineChart)),
      );
      expect(lineChart.data.lineBarsData, hasLength(1));
      expect(lineChart.data.lineBarsData.single.color, AppColors.primary);
      expect(lineChart.data.maxY, lessThan(2));
      expect(
        find.textContaining('Lower-than-expected: below reference'),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.textContaining('Slope trend summarizes RMSSD-Slope changes'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Lower-than-expected: 1'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Lower-than-expected: 1'),
        findsAtLeastNWidgets(1),
      );
      expect(find.textContaining('Expected: 1'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Favorable: 1'), findsAtLeastNWidgets(1));
    });

    testWidgets('reference card shows nomogram model selector and metadata', (
      tester,
    ) async {
      await _seedSession(db, athleteId, slope: 0.5);
      await _seedSession(db, athleteId, slope: 1.0, day: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Model selection'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<NomogramMode>), findsOneWidget);
      expect(find.text('Study model'), findsWidgets);
      expect(find.text('Hybrid model'), findsOneWidget);
      expect(find.text('Individual model'), findsOneWidget);
      expect(find.text('Requested model'), findsOneWidget);
      expect(find.text('Active model'), findsOneWidget);
      expect(find.text('Blend'), findsOneWidget);
      expect(find.byTooltip('Model selected by the user.'), findsOneWidget);
      expect(
        find.byTooltip(
          'Model actually used after readiness and fallback rules.',
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip(
          'Percentage contribution from athlete history and study reference.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('longitudinal_nomogram_filters')),
        findsNothing,
      );
      expect(
        find.text('Date range follows the dashboard filters.'),
        findsNothing,
      );
      expect(find.text('Reset filters'), findsNothing);
      expect(find.textContaining('Showing 2 of 2 points'), findsNothing);
      expect(find.byType(NomogramChart), findsNothing);
      expect(find.text('Color points by recovery status'), findsOneWidget);
    });

    testWidgets('changing longitudinal model keeps reference area visible', (
      tester,
    ) async {
      await _seedSession(db, athleteId, slope: 0.5);
      await _seedSession(db, athleteId, slope: 1.0, day: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Hybrid model'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hybrid model'));
      await tester.pumpAndSettle();

      expect(find.text('Model selection'), findsOneWidget);
      expect(find.text('Color points by recovery status'), findsOneWidget);
      expect(find.text('Requested model'), findsOneWidget);
      expect(find.text('Hybrid model'), findsWidgets);
      expect(
        find.text(
          'Requested hybrid model is not available yet. Using study model.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('requested individual model shows fallback helper text', (
      tester,
    ) async {
      await _seedSession(db, athleteId, slope: 0.5);
      await _seedSession(db, athleteId, slope: 1.0, day: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Individual model'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Individual model'));
      await tester.pumpAndSettle();

      expect(find.text('Model selection'), findsOneWidget);
      expect(
        find.text(
          'Requested individual model is not available yet. Using study model.',
        ),
        findsOneWidget,
      );
      expect(find.text('Individual model not available yet:'), findsOneWidget);
      expect(find.textContaining('Valid sessions:'), findsOneWidget);
    });

    testWidgets('zone color toggle disables Slope and ITL zone colors', (
      tester,
    ) async {
      final bands = evaluatePopulationNomogramBands(
        80,
        source: PopulationNomogramSource.slopeOrellana19,
      );
      await _seedSession(db, athleteId, slope: bands.expectedLower / 2);
      await _seedSession(db, athleteId, slope: bands.expectedMean, day: 2);
      await _seedSession(
        db,
        athleteId,
        slope: bands.expectedUpper + 0.2,
        day: 3,
      );
      await _seedSession(db, athleteId, slope: 0.7, intensity: null, day: 4);

      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();
      await _dragUntilVisible(
        tester,
        find.text('Color points by recovery status'),
      );

      await _dragUntilVisible(tester, find.text('Slope Trend'));
      var charts = tester.widgetList<LongitudinalChart>(
        find.byType(LongitudinalChart),
      );
      var slopeChart = charts.firstWhere(
        (chart) => chart.title == 'Slope Trend',
      );
      expect(slopeChart.points.map((point) => point.color), [
        AppColors.warning,
        AppColors.primary,
        AppColors.success,
        AppColors.textHint,
      ]);
      await _dragUntilVisible(tester, find.text('ITL Trend'));
      charts = tester.widgetList<LongitudinalChart>(
        find.byType(LongitudinalChart),
      );
      var itlChart = charts.firstWhere((chart) => chart.title == 'ITL Trend');
      expect(itlChart.points.map((point) => point.color), [
        AppColors.warning,
        AppColors.primary,
        AppColors.success,
        AppColors.textHint,
      ]);

      await _dragBackUntilVisible(
        tester,
        find.text('Color points by recovery status'),
      );
      await tester.tap(find.text('Color points by recovery status'));
      await tester.pumpAndSettle();

      await _dragUntilVisible(tester, find.text('Slope Trend'));
      charts = tester.widgetList<LongitudinalChart>(
        find.byType(LongitudinalChart),
      );
      slopeChart = charts.firstWhere((chart) => chart.title == 'Slope Trend');
      expect(
        slopeChart.points.map((point) => point.color),
        List.filled(4, AppColors.primary),
      );
      await _dragUntilVisible(tester, find.text('ITL Trend'));
      charts = tester.widgetList<LongitudinalChart>(
        find.byType(LongitudinalChart),
      );
      itlChart = charts.firstWhere((chart) => chart.title == 'ITL Trend');
      expect(
        itlChart.points.map((point) => point.color),
        List.filled(4, AppColors.primary),
      );
      expect(
        find.textContaining('Slope trend summarizes RMSSD-Slope changes'),
        findsNothing,
      );

      await _dragUntilVisible(tester, find.text('RPE vs Slope response'));
      final quadrant = tester.widget<RpeSlopeQuadrantChart>(
        find.byType(RpeSlopeQuadrantChart),
      );
      expect(
        quadrant.data.points.first.recoveryZone,
        LongitudinalRecoveryZone.low,
      );
    });

    testWidgets('advanced charts are collapsed by default', (tester) async {
      await _seedSession(db, athleteId, slope: 0.5);
      await _seedSession(db, athleteId, slope: 1.0, day: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      await _dragUntilVisible(tester, find.text('Slope Trend'));
      expect(find.text('Slope Trend'), findsOneWidget);
      await _dragUntilVisible(tester, find.text('ITL Trend'));
      expect(find.text('ITL Trend'), findsOneWidget);
      await _dragUntilVisible(tester, find.text('RPE vs Slope response'));
      expect(find.text('RPE vs Slope response'), findsOneWidget);
      await _dragUntilVisible(tester, find.text('Advanced charts'));
      expect(find.text('Advanced charts'), findsOneWidget);
      expect(find.text('Intensity Overlay'), findsNothing);
      expect(find.text('Residual Trend'), findsNothing);

      await tester.tap(find.text('Advanced charts'));
      await tester.pumpAndSettle();

      expect(find.text('Intensity Overlay'), findsOneWidget);
      expect(find.text('Residual Trend'), findsOneWidget);
    });

    testWidgets('wide dashboard compacts trends and explains quadrant chart', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _seedSession(db, athleteId, slope: 0.5);
      await _seedSession(db, athleteId, slope: 1.0, day: 2);
      await _seedSession(db, athleteId, slope: 0.8, day: 3);

      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Model selection'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Model selection'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Slope Trend'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Slope Trend'), findsOneWidget);
      expect(find.text('ITL Trend'), findsOneWidget);
      expect(find.text('X: Session'), findsNWidgets(2));
      expect(
        find.byType(DropdownButtonFormField<LongitudinalXAxisMode>),
        findsNothing,
      );
      await tester.tap(find.byTooltip('Change X-axis').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(PopupMenuItem<LongitudinalXAxisMode>, 'Date'),
      );
      await tester.pumpAndSettle();
      expect(find.text('X: Date'), findsNWidgets(2));

      final slopeTop = tester.getTopLeft(find.text('Slope Trend')).dy;
      final itlTop = tester.getTopLeft(find.text('ITL Trend')).dy;
      expect((slopeTop - itlTop).abs(), lessThan(60));

      await tester.scrollUntilVisible(
        find.text('RPE vs Slope response'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('RPE vs Slope response'), findsOneWidget);
      expect(find.text('How to read'), findsOneWidget);
      expect(find.text('X axis'), findsOneWidget);
      expect(find.text('Y axis'), findsOneWidget);
    });

    testWidgets('dashboard explains ITL reference and zones', (tester) async {
      await _seedSession(db, athleteId, slope: 0.5);
      await _seedSession(db, athleteId, slope: 1.0, day: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      await _dragUntilVisible(
        tester,
        find.textContaining(
          'ITL trend contextualizes response against internal training load',
        ),
      );

      final itlChart = tester
          .widgetList<LongitudinalChart>(find.byType(LongitudinalChart))
          .firstWhere((chart) => chart.title == 'ITL Trend');
      expect(itlChart.referenceSeries, isEmpty);
      expect(itlChart.points.first.tooltip, contains('ITL:'));
      expect(itlChart.points.first.tooltip, contains('Recovery status:'));
      expect(itlChart.points.first.tooltip, contains('Intensity:'));
      expect(itlChart.points.first.tooltip, contains('Slope:'));
      expect(itlChart.points.first.tooltip, isNot(contains('Reference ITL')));
      expect(
        find.textContaining(
          'ITL trend contextualizes response against internal training load',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Colors show recovery status'), findsWidgets);
    });

    test('recovery response labels map zones and legacy classes', () {
      expect(
        recoveryZoneLabel(LongitudinalRecoveryZone.low.key),
        'Lower-than-expected recovery response',
      );
      expect(
        recoveryZoneLabel(LongitudinalRecoveryZone.normal.key),
        'Expected recovery response',
      );
      expect(
        recoveryZoneLabel(LongitudinalRecoveryZone.favorable.key),
        'Favorable recovery response',
      );
      expect(
        recoveryZoneLabel(LongitudinalRecoveryZone.unavailable.key),
        'Recovery reference unavailable',
      );
      expect(
        recoveryResponseLabelForClassificationKey(
          'high_or_moderate_internal_load',
        ),
        'Lower-than-expected recovery response',
      );
      expect(
        recoveryResponseLabelForClassificationKey(
          'low_internal_load_or_fast_recovery',
        ),
        'Favorable recovery response',
      );
    });

    test('quadrant interpretations use post-effort recovery language', () {
      expect(
        RpeSlopeQuadrant.highRpeFavorableSlopeResponse.interpretation,
        contains('demanding'),
      );
      expect(
        RpeSlopeQuadrant.highRpeFavorableSlopeResponse.interpretation,
        contains('adequate or favorable'),
      );
      expect(
        RpeSlopeQuadrant.highRpeLowSlopeResponse.interpretation,
        contains('lower than expected'),
      );
      expect(
        RpeSlopeQuadrant.lowRpeFavorableSlopeResponse.interpretation,
        contains('lower perceived effort'),
      );
      expect(
        RpeSlopeQuadrant.lowRpeLowSlopeResponse.interpretation,
        contains('sleep, stress, heat, humidity, travel'),
      );
    });

    test('intensity source messages avoid judging internal load alone', () {
      expect(
        intensitySourceForSlopeMessage('External'),
        contains('External intensity was used'),
      );
      expect(
        intensitySourceForSlopeMessage('Internal'),
        contains('because no valid external intensity was available'),
      );
      expect(
        intensitySourceForSlopeMessage('Unknown'),
        contains('recovery interpretation may be limited'),
      );
      expect(
        intensitySourceForSlopeMessage('Internal').toLowerCase(),
        isNot(contains('internal load is high')),
      );
    });

    testWidgets('dashboard works when no session has reference available', (
      tester,
    ) async {
      await _seedSession(db, athleteId, slope: 0.5, intensity: null);
      await _seedSession(db, athleteId, slope: 1.0, intensity: null, day: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await _dragUntilVisible(
        tester,
        find.text('Color points by recovery status'),
      );
      expect(find.text('Color points by recovery status'), findsOneWidget);
      expect(
        find.textContaining(
          'Recovery status requires primary intensity and slope data.',
        ),
        findsOneWidget,
      );
    });

    test('no medical diagnostic language', () {
      final text = File(
        'lib/ui/screens/longitudinal/athlete_longitudinal_screen.dart',
      ).readAsStringSync().toLowerCase();

      expect(text, isNot(contains('diagnosis')));
      expect(text, isNot(contains('disease')));
      expect(text, isNot(contains('pathological')));
    });
  });

  group('Phase 4.0A regression guards', () {
    test(
      'no legacy computeSlope() usage in UI/report/import/edit/longitudinal',
      () {
        final files = [
          File('lib/ui/screens/import/import_screen.dart'),
          File('lib/ui/screens/session/session_wizard_screen.dart'),
          File('lib/ui/screens/session/session_edit_screen.dart'),
          File('lib/ui/screens/reports/individual_report_screen.dart'),
          File('lib/ui/screens/reports/group_report_screen.dart'),
          File('lib/ui/screens/reports/population_nomogram_screen.dart'),
          File('lib/ui/screens/longitudinal/athlete_longitudinal_screen.dart'),
          File('lib/data/services/session_edit_service.dart'),
        ];

        for (final file in files) {
          expect(file.readAsStringSync().contains('computeSlope('), isFalse);
        }
      },
    );

    test('direct RMSSD remains default', () {
      expect(_detail(id: 1).session.hrvInputMode, 'direct_rmssd');
    });

    test('RR correction remains off by default', () {
      expect(_detail(id: 1).session.rrCorrectionEnabled, isFalse);
    });

    test('real RR fixtures remain mandatory', () {
      for (final name in [
        '2026-05-25_05-27-02.txt',
        '2026-05-22_05-39-13.txt',
        '2026-05-21_05-42-46.txt',
      ]) {
        expect(File('test/fixtures/rr_samples/$name').existsSync(), isTrue);
      }
    });
  });
}

LongitudinalSeries _series(
  List<SessionDetail> details, {
  LongitudinalDashboardFilter filter = const LongitudinalDashboardFilter(),
}) {
  return buildLongitudinalSeries(
    athlete: _athlete(),
    details: details,
    filter: filter,
  );
}

Athlete _athlete() {
  return const Athlete(
    id: 1,
    name: 'Runner One',
    sport: 'Running',
    birthDate: null,
    gender: null,
    positionOrEvent: null,
    masKmh: 20,
    vvo2maxKmh: null,
    mapW: null,
    fcMax: null,
    notes: null,
    isArchived: false,
    createdAt: '2026-05-26T00:00:00',
    updatedAt: '2026-05-26T00:00:00',
  );
}

SessionDetail _detail({
  required int id,
  String? date,
  String? taskName,
  String sport = 'Running',
  String sessionType = 'training',
  String? protocolName,
  String? contextEnvironment,
  double? intensity = 80,
  String? intensitySource,
  double? slope = 0.5,
  double? rpe = 7,
  String rpeVariableName = 'rpe_1_10',
  double? fatigue,
  double? srpe,
  double? trimp,
  String? notes,
  String externalName = 'speed_kmh',
}) {
  final sessionDate = date ?? '2026-05-${id.toString().padLeft(2, '0')}';
  return SessionDetail(
    athlete: _athlete(),
    session: Session(
      id: id,
      athleteId: 1,
      date: sessionDate,
      taskName: taskName ?? 'Session $id',
      sport: sport,
      sessionType: sessionType,
      protocolName: protocolName,
      contextEnvironment: contextEnvironment,
      isDraft: false,
      intensityPercent: intensity,
      intensitySource: intensity == null
          ? null
          : (intensitySource ?? 'direct_percent_mas'),
      recoveryTimeMin: slope == null ? null : 10,
      recoveryWindowStartMin: slope == null ? null : 5,
      recoveryWindowEndMin: slope == null ? null : 10,
      rmssdExercise: slope == null ? null : 4,
      rmssdExerciseIsDefault: false,
      rmssdRecovery: slope == null ? null : 24,
      slopeRaw: slope,
      slopeInterpreted: slope,
      itlIndex: slope == null ? null : 1 / slope,
      classification: null,
      hrvInputMode: 'direct_rmssd',
      rmssdRecoverySource: 'manual',
      rmssdExerciseSource: 'measured',
      rrQualityFlag: null,
      rrArtifactPercent: null,
      rrPreprocessingMode: null,
      rrCorrectionEnabled: false,
      rrCorrectionMethod: null,
      rrRawRmssd: null,
      rrCorrectedRmssd: null,
      rrRmssdUsed: null,
      rrArtifactCount: null,
      rrQualityDecision: null,
      rrQualityNotesJson: null,
      rrRmssdDeltaPercent: null,
      importBatchId: null,
      notes: notes,
      createdAt: '${sessionDate}T00:00:00',
    ),
    variables: [
      _variable(
        id: id * 10,
        sessionId: id,
        category: 'external',
        name: externalName,
        value: 100,
      ),
      if (rpe != null)
        _variable(
          id: id * 10 + 1,
          sessionId: id,
          category: 'internal',
          name: rpeVariableName,
          value: rpe,
        ),
      if (fatigue != null)
        _variable(
          id: id * 10 + 4,
          sessionId: id,
          category: 'internal',
          name: 'subjective_fatigue_1_10',
          value: fatigue,
        ),
      if (srpe != null)
        _variable(
          id: id * 10 + 2,
          sessionId: id,
          category: 'internal',
          name: 'srpe',
          value: srpe,
        ),
      if (trimp != null)
        _variable(
          id: id * 10 + 3,
          sessionId: id,
          category: 'internal',
          name: 'trimp',
          value: trimp,
        ),
    ],
    hrvMeasurements: const [],
    notes: const [],
  );
}

IntensityVariable _variable({
  required int id,
  required int sessionId,
  required String category,
  required String name,
  required double value,
}) {
  return IntensityVariable(
    id: id,
    sessionId: sessionId,
    category: category,
    name: name,
    unit: null,
    value: value,
    source: 'manual',
    isPrimaryForNomogram: category == 'external',
    notes: null,
    createdAt: '2026-05-26T00:00:00',
  );
}

Future<int> _seedAthlete(AppDatabase db) {
  final now = DateTime.now().toIso8601String();
  return db.athletesDao.insertAthlete(
    AthletesCompanion.insert(
      name: 'Runner One',
      sport: const drift.Value('Running'),
      masKmh: const drift.Value(20),
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<int> _seedSession(
  AppDatabase db,
  int athleteId, {
  double slope = 0.5,
  double? intensity = 80,
  int day = 1,
  String? notes,
}) async {
  final now = DateTime.now().toIso8601String();
  final date = '2026-05-${day.toString().padLeft(2, '0')}';
  final sessionId = await db.sessionsDao.insertSession(
    SessionsCompanion.insert(
      athleteId: athleteId,
      date: date,
      taskName: drift.Value('Session $day'),
      sport: const drift.Value('Running'),
      sessionType: const drift.Value('training'),
      intensityPercent: drift.Value(intensity),
      intensitySource: drift.Value(
        intensity == null ? null : 'direct_percent_mas',
      ),
      recoveryTimeMin: const drift.Value(10),
      recoveryWindowStartMin: const drift.Value(5),
      recoveryWindowEndMin: const drift.Value(10),
      rmssdExercise: const drift.Value(4),
      rmssdRecovery: const drift.Value(24),
      slopeRaw: drift.Value(slope),
      slopeInterpreted: drift.Value(slope),
      itlIndex: drift.Value(1 / slope),
      hrvInputMode: const drift.Value('direct_rmssd'),
      rmssdRecoverySource: const drift.Value('manual'),
      rmssdExerciseSource: const drift.Value('measured'),
      notes: drift.Value(notes),
      createdAt: now,
    ),
  );
  await db.sessionsDao.insertVariables([
    IntensityVariablesCompanion.insert(
      sessionId: sessionId,
      category: 'external',
      name: 'speed_kmh',
      value: 16,
      source: const drift.Value('manual'),
      createdAt: now,
    ),
    IntensityVariablesCompanion.insert(
      sessionId: sessionId,
      category: 'internal',
      name: 'rpe_1_10',
      value: 7,
      source: const drift.Value('manual'),
      createdAt: now,
    ),
  ]);
  return sessionId;
}

Future<void> _dragUntilVisible(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 8; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
  }
}

Future<void> _dragBackUntilVisible(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 8; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(find.byType(ListView), const Offset(0, 360));
    await tester.pumpAndSettle();
  }
}
