import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_builder.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_filter.dart';
import 'package:hrv_slope_app/ui/screens/reports/team_session_events_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/session_event_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/team_longitudinal_heatmap_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Team heatmap filter helper', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('filters by stored classification without recalculating it', () async {
      final seed = await _seed3c2Heatmap(db);
      final data = await _loadData(db, seed.teamId);

      final view = filterTeamHeatmap(
        data,
        const TeamHeatmapFilter(classificationOptionIds: {'expected_response'}),
      );
      final alpha = _filteredRow(view, 'Alpha');

      expect(_filteredCell(alpha, seed.eventIds['expected']!).matches, isTrue);
      expect(_filteredCell(alpha, seed.eventIds['fallback']!).matches, isFalse);
      expect(
        _filteredCell(alpha, seed.eventIds['incomplete']!).matches,
        isFalse,
      );
      expect(
        _filteredCell(alpha, seed.eventIds['measured4']!).matches,
        isFalse,
      );
      expect(
        _filteredCell(alpha, seed.eventIds['expected']!).cell.classification,
        'expected_response',
      );
    });

    test('separates fallback from measured 4 ms', () async {
      final seed = await _seed3c2Heatmap(db);
      final missingExercise = await _insertEvent(
        db,
        teamId: seed.teamId,
        date: '2026-05-05T10:00:00',
        taskName: 'Missing exercise',
      );
      await _insertSession(
        db,
        athleteId: seed.athleteIds['alpha']!,
        eventId: missingExercise,
        date: '2026-05-05T10:00:00',
        taskName: 'Missing exercise',
        loadValue: 87,
        rmssdExercise: null,
        rmssdExerciseIsDefault: false,
        rmssdExerciseSource: 'measured',
        rmssdRecovery: 23,
        slope: 0.44,
        classification: 'expected_response',
      );
      final data = await _loadData(db, seed.teamId);

      final fallbackView = filterTeamHeatmap(
        data,
        const TeamHeatmapFilter(
          fallbackFilter: TeamHeatmapFallbackFilter.fallbackOnly,
        ),
      );
      final fallbackAlpha = _filteredRow(fallbackView, 'Alpha');
      expect(
        _filteredCell(fallbackAlpha, seed.eventIds['fallback']!).matches,
        isTrue,
      );
      expect(
        _filteredCell(fallbackAlpha, seed.eventIds['measured4']!).matches,
        isFalse,
      );

      final measuredView = filterTeamHeatmap(
        data,
        const TeamHeatmapFilter(
          fallbackFilter: TeamHeatmapFallbackFilter.measuredOnly,
        ),
      );
      final measured4 = _filteredCell(
        _filteredRow(measuredView, 'Alpha'),
        seed.eventIds['measured4']!,
      );
      expect(measured4.matches, isTrue);
      expect(measured4.cell.rmssdExercise, 4);
      expect(measured4.cell.hasFallbackExercise, isFalse);
      final missingExerciseCell = _filteredCell(
        _filteredRow(measuredView, 'Alpha'),
        missingExercise,
      );
      expect(missingExerciseCell.cell.rmssdExercise, isNull);
      expect(missingExerciseCell.cell.hasFallbackExercise, isFalse);
      expect(missingExerciseCell.matches, isFalse);
    });

    test('filters valid and incomplete session states', () async {
      final seed = await _seed3c2Heatmap(db);
      final data = await _loadData(db, seed.teamId);

      final validView = filterTeamHeatmap(
        data,
        const TeamHeatmapFilter(
          stateFilter: TeamHeatmapSessionStateFilter.valid,
        ),
      );
      final validAlpha = _filteredRow(validView, 'Alpha');
      expect(
        _filteredCell(validAlpha, seed.eventIds['expected']!).matches,
        isTrue,
      );
      expect(
        _filteredCell(validAlpha, seed.eventIds['incomplete']!).matches,
        isFalse,
      );

      final incompleteView = filterTeamHeatmap(
        data,
        const TeamHeatmapFilter(
          stateFilter: TeamHeatmapSessionStateFilter.incomplete,
        ),
      );
      final incompleteAlpha = _filteredRow(incompleteView, 'Alpha');
      expect(
        _filteredCell(incompleteAlpha, seed.eventIds['incomplete']!).matches,
        isTrue,
      );
      expect(
        _filteredCell(incompleteAlpha, seed.eventIds['expected']!).matches,
        isFalse,
      );
    });

    test(
      'combined Expected and Measured stats exclude accidental slopes',
      () async {
        final seed = await _seed3c2Heatmap(db);
        final data = await _loadData(db, seed.teamId);

        final view = filterTeamHeatmap(
          data,
          const TeamHeatmapFilter(
            classificationOptionIds: {'expected_response'},
            fallbackFilter: TeamHeatmapFallbackFilter.measuredOnly,
          ),
        );
        final alpha = _filteredRow(view, 'Alpha');

        expect(alpha.stats.visibleSessionCount, 1);
        expect(alpha.stats.validSessionCount, 1);
        expect(alpha.stats.latestValidSlope, closeTo(0.2, 0.000001));
        expect(alpha.stats.medianValidSlope, closeTo(0.2, 0.000001));
        expect(alpha.stats.fallbackCount, 0);
        expect(
          _filteredCell(alpha, seed.eventIds['incomplete']!).cell.slope,
          9.9,
        );
        expect(
          _filteredCell(alpha, seed.eventIds['incomplete']!).matches,
          isFalse,
        );
      },
    );
  });

  group('TeamLongitudinalHeatmapScreen 3C-2 UX', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('applies filters and resets them', (tester) async {
      final seed = await _seed3c2Heatmap(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      expect(find.text('No filters active'), findsOneWidget);
      await tester.tap(
        find.byKey(
          const Key('team_heatmap_classification_filter_expected_response'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 filter active'), findsOneWidget);
      expect(find.text('Archived Player'), findsNothing);

      await tester.tap(find.byKey(const Key('team_heatmap_fallback_filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Measured only').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('team_heatmap_state_filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valid').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('team_heatmap_search')),
        'Alpha',
      );
      await tester.pumpAndSettle();
      expect(find.text('4 filters active'), findsOneWidget);

      await tester.tap(find.byKey(const Key('team_heatmap_reset_filters')));
      await tester.pumpAndSettle();

      expect(find.text('No filters active'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Archived Player'), findsOneWidget);
    });

    testWidgets('keeps selected classification visible after date reload', (
      tester,
    ) async {
      final seed = await _seed3c2Heatmap(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      final expectedChip = find.byKey(
        const Key('team_heatmap_classification_filter_expected_response'),
      );
      await tester.tap(expectedChip);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(expectedChip).selected, isTrue);

      await tester.enterText(
        find.byKey(const Key('team_heatmap_date_from')),
        '2026-05-02',
      );
      await tester.enterText(
        find.byKey(const Key('team_heatmap_date_to')),
        '2026-05-02',
      );
      await tester.tap(find.byKey(const Key('team_heatmap_apply_filters')));
      await tester.pumpAndSettle();

      expect(expectedChip, findsOneWidget);
      expect(tester.widget<FilterChip>(expectedChip).selected, isTrue);
      expect(find.text('3 filters active'), findsOneWidget);

      await tester.tap(find.byKey(const Key('team_heatmap_reset_filters')));
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(expectedChip).selected, isFalse);
      expect(find.text('No filters active'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Archived Player'), findsOneWidget);
    });

    testWidgets('invalid date keeps current data and can be reset', (
      tester,
    ) async {
      final seed = await _seed3c2Heatmap(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      expect(find.text('Period: 2026-05-01 to 2026-05-04'), findsOneWidget);
      expect(find.byKey(const Key('team_heatmap_grid')), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('team_heatmap_date_from')),
        '2026-99-99',
      );
      await tester.tap(find.byKey(const Key('team_heatmap_apply_filters')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('team_heatmap_inline_error')),
        findsOneWidget,
      );
      expect(find.text('Use YYYY-MM-DD for date filters.'), findsOneWidget);
      expect(find.byKey(const Key('team_heatmap_filters')), findsOneWidget);
      expect(find.byKey(const Key('team_heatmap_grid')), findsOneWidget);
      expect(find.text('Period: 2026-05-01 to 2026-05-04'), findsOneWidget);
      expect(find.text('No filters active'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);

      await tester.tap(find.byKey(const Key('team_heatmap_reset_filters')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('team_heatmap_inline_error')), findsNothing);
      expect(find.text('No filters active'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('team_heatmap_date_from')))
            .controller!
            .text,
        isEmpty,
      );
      expect(find.text('Archived Player'), findsOneWidget);
    });

    testWidgets('draft date text does not change period or active filters', (
      tester,
    ) async {
      final seed = await _seed3c2Heatmap(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      expect(find.text('Period: 2026-05-01 to 2026-05-04'), findsOneWidget);
      expect(find.text('No filters active'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('team_heatmap_date_from')),
        '2026-05-02',
      );
      await tester.enterText(
        find.byKey(const Key('team_heatmap_search')),
        'Alpha',
      );
      await tester.pumpAndSettle();

      expect(find.text('Period: 2026-05-01 to 2026-05-04'), findsOneWidget);
      expect(find.text('1 filter active'), findsOneWidget);
      expect(
        find.byKey(
          Key('team_heatmap_event_header_${seed.eventIds['expected']}'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('applied date updates period and active filters', (
      tester,
    ) async {
      final seed = await _seed3c2Heatmap(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      await tester.enterText(
        find.byKey(const Key('team_heatmap_date_from')),
        '2026-05-02',
      );
      await tester.tap(find.byKey(const Key('team_heatmap_apply_filters')));
      await tester.pumpAndSettle();

      expect(find.text('Period: 2026-05-02 to today'), findsOneWidget);
      expect(find.text('1 filter active'), findsOneWidget);
      expect(
        find.byKey(
          Key('team_heatmap_event_header_${seed.eventIds['expected']}'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          Key('team_heatmap_event_header_${seed.eventIds['fallback']}'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('invalid date after valid range keeps applied period', (
      tester,
    ) async {
      final seed = await _seed3c2Heatmap(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      await tester.enterText(
        find.byKey(const Key('team_heatmap_date_from')),
        '2026-05-02',
      );
      await tester.enterText(
        find.byKey(const Key('team_heatmap_date_to')),
        '2026-05-04',
      );
      await tester.tap(find.byKey(const Key('team_heatmap_apply_filters')));
      await tester.pumpAndSettle();

      expect(find.text('Period: 2026-05-02 to 2026-05-04'), findsOneWidget);
      expect(find.text('2 filters active'), findsOneWidget);
      expect(
        find.byKey(
          Key('team_heatmap_event_header_${seed.eventIds['expected']}'),
        ),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const Key('team_heatmap_date_from')),
        '2026-99-99',
      );
      await tester.tap(find.byKey(const Key('team_heatmap_apply_filters')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('team_heatmap_inline_error')),
        findsOneWidget,
      );
      expect(find.text('Use YYYY-MM-DD for date filters.'), findsOneWidget);
      expect(find.text('Period: 2026-05-02 to 2026-05-04'), findsOneWidget);
      expect(find.text('2 filters active'), findsOneWidget);
      expect(
        find.byKey(
          Key('team_heatmap_event_header_${seed.eventIds['expected']}'),
        ),
        findsNothing,
      );
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('reset clears date and all in-memory filters', (tester) async {
      final seed = await _seed3c2Heatmap(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      await tester.enterText(
        find.byKey(const Key('team_heatmap_date_from')),
        '2026-05-02',
      );
      await tester.enterText(
        find.byKey(const Key('team_heatmap_date_to')),
        '2026-05-02',
      );
      await tester.tap(find.byKey(const Key('team_heatmap_apply_filters')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const Key('team_heatmap_classification_filter_expected_response'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('team_heatmap_fallback_filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Measured only').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('team_heatmap_state_filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valid').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('team_heatmap_search')),
        'Alpha',
      );
      await tester.pumpAndSettle();

      expect(find.text('6 filters active'), findsOneWidget);
      expect(find.text('Period: 2026-05-02 to 2026-05-02'), findsOneWidget);

      await tester.tap(find.byKey(const Key('team_heatmap_reset_filters')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('team_heatmap_date_from')))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('team_heatmap_date_to')))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('team_heatmap_search')))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(
                const Key(
                  'team_heatmap_classification_filter_expected_response',
                ),
              ),
            )
            .selected,
        isFalse,
      );
      expect(find.text('No filters active'), findsOneWidget);
      expect(find.text('Period: 2026-05-01 to 2026-05-04'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Archived Player'), findsOneWidget);
      expect(
        find.byKey(
          Key('team_heatmap_event_header_${seed.eventIds['expected']}'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps athlete column visible during horizontal scroll', (
      tester,
    ) async {
      final seed = await _seedLargeHeatmap(
        db,
        athleteCount: 40,
        eventCount: 50,
      );

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
        size: const Size(1280, 720),
      );

      final athleteFinder = find.text('Player 40');
      await tester.ensureVisible(athleteFinder);
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(athleteFinder).dx;

      await tester.dragFrom(const Offset(1000, 640), const Offset(-700, 0));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('team_heatmap_fixed_athlete_column')),
        findsOneWidget,
      );
      expect(tester.getTopLeft(athleteFinder).dx, closeTo(before, 0.1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens SessionEvent detail from an event header', (
      tester,
    ) async {
      final seed = await _seed3c2Heatmap(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      await tester.tap(
        find.byKey(
          Key('team_heatmap_event_header_${seed.eventIds['expected']}'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SessionEventDetailScreen), findsOneWidget);
      expect(find.text('Expected measured'), findsWidgets);
    });

    testWidgets(
      'shows same-day event times in headers and keeps cells separate',
      (tester) async {
        final seed = await _seedSameDayEvents(db);
        final data = await _loadData(db, seed.teamId);

        expect(data.events.map((event) => event.id), [
          seed.morningEventId,
          seed.afternoonEventId,
        ]);
        for (final athleteName in ['Alpha', 'Bravo']) {
          final row = _heatmapRow(data, athleteName);
          final morningCell = _heatmapCell(row, seed.morningEventId);
          final afternoonCell = _heatmapCell(row, seed.afternoonEventId);
          expect(morningCell.state, TeamHeatmapCellState.valid);
          expect(afternoonCell.state, TeamHeatmapCellState.valid);
          expect(morningCell.state, isNot(TeamHeatmapCellState.duplicate));
          expect(afternoonCell.state, isNot(TeamHeatmapCellState.duplicate));
        }

        await _pump(
          tester,
          TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
        );

        final morningHeader = find.byKey(
          Key('team_heatmap_event_header_${seed.morningEventId}'),
        );
        final afternoonHeader = find.byKey(
          Key('team_heatmap_event_header_${seed.afternoonEventId}'),
        );
        expect(morningHeader, findsOneWidget);
        expect(afternoonHeader, findsOneWidget);
        expect(find.text('10:00'), findsOneWidget);
        expect(find.text('17:00'), findsOneWidget);
        expect(
          tester.getTopLeft(morningHeader).dx,
          lessThan(tester.getTopLeft(afternoonHeader).dx),
        );

        await tester.enterText(
          find.byKey(const Key('team_heatmap_date_from')),
          '2026-08-20',
        );
        await tester.enterText(
          find.byKey(const Key('team_heatmap_date_to')),
          '2026-08-20',
        );
        await tester.tap(find.byKey(const Key('team_heatmap_apply_filters')));
        await tester.pumpAndSettle();

        expect(morningHeader, findsOneWidget);
        expect(afternoonHeader, findsOneWidget);
        expect(find.text('10:00'), findsOneWidget);
        expect(find.text('17:00'), findsOneWidget);
      },
    );

    testWidgets('does not invent midnight for date-only event headers', (
      tester,
    ) async {
      final seed = await _seedDateOnlyEvent(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      expect(
        find.byKey(Key('team_heatmap_event_header_${seed.eventId}')),
        findsOneWidget,
      );
      expect(find.text('08/21'), findsOneWidget);
      expect(find.text('00:00'), findsNothing);
    });

    testWidgets('Team Sessions lists same-day events newest first with time', (
      tester,
    ) async {
      final seed = await _seedSameDayEvents(db);

      await _pump(
        tester,
        TeamSessionEventsScreen(database: db, teamId: seed.teamId),
      );

      final afternoon = find.textContaining('2026-08-20 17:00');
      final morning = find.textContaining('2026-08-20 10:00');
      expect(afternoon, findsOneWidget);
      expect(morning, findsOneWidget);
      expect(
        tester.getTopLeft(afternoon).dy,
        lessThan(tester.getTopLeft(morning).dy),
      );
    });

    testWidgets('opens valid and incomplete cell context but not missing or duplicate', (
      tester,
    ) async {
      final seed = await _seed3c2Heatmap(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      expect(
        find.byKey(
          Key(
            'team_heatmap_fallback_${seed.athleteIds['alpha']}_${seed.eventIds['fallback']}',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('arch'), findsOneWidget);

      await tester.tap(
        find.byKey(
          Key(
            'team_heatmap_cell_${seed.athleteIds['alpha']}_${seed.eventIds['expected']}',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('team_heatmap_cell_dialog')), findsOneWidget);
      expect(find.text('Session'), findsOneWidget);
      expect(find.text('RMSSD'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Load'), findsOneWidget);
      expect(find.text('Individual period context'), findsOneWidget);
      expect(find.text('Valid sessions'), findsOneWidget);
      expect(find.text('3'), findsWidgets);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          Key(
            'team_heatmap_cell_${seed.athleteIds['alpha']}_${seed.eventIds['incomplete']}',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('team_heatmap_cell_dialog')), findsOneWidget);
      expect(find.text('Incomplete'), findsWidgets);
      expect(find.text('RMSSD recovery missing'), findsOneWidget);
      expect(find.text('9.900'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.tap(
        await _visibleFinder(
          tester,
          Key(
            'team_heatmap_cell_${seed.athleteIds['archived']}_${seed.eventIds['fallback']}',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('team_heatmap_cell_dialog')), findsNothing);

      await tester.tap(
        await _visibleFinder(
          tester,
          Key(
            'team_heatmap_cell_${seed.athleteIds['archived']}_${seed.eventIds['measured4']}',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('team_heatmap_cell_dialog')), findsNothing);
    });

    testWidgets('handles 40 x 50 grid with filters, search and scrolls', (
      tester,
    ) async {
      final seed = await _seedLargeHeatmap(
        db,
        athleteCount: 40,
        eventCount: 50,
      );

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
        size: const Size(1280, 720),
      );

      expect(find.byKey(const Key('team_heatmap_grid')), findsOneWidget);
      await tester.tap(
        find.byKey(
          const Key('team_heatmap_classification_filter_expected_response'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 filter active'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('team_heatmap_search')),
        'Player 40',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(Key('team_heatmap_row_${seed.lastAthleteId}')),
        findsOneWidget,
      );

      await tester.dragFrom(const Offset(1000, 640), const Offset(-800, 0));
      await tester.dragFrom(const Offset(1000, 640), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('team_heatmap_event_header_${seed.lastEventId}')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1280, 720),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: child));
  await tester.pumpAndSettle();
}

Future<Finder> _visibleFinder(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  return finder;
}

Future<TeamHeatmapData> _loadData(AppDatabase db, int teamId) async {
  final bundle = await db.sessionEventsDao.getTeamLongitudinalBundle(
    teamId: teamId,
  );
  return buildTeamHeatmap(bundle);
}

TeamHeatmapFilteredRow _filteredRow(TeamHeatmapFilteredView view, String name) {
  return view.rows.singleWhere((row) => row.athlete.name == name);
}

TeamHeatmapFilteredCell _filteredCell(TeamHeatmapFilteredRow row, int eventId) {
  return row.cells.singleWhere((cell) => cell.cell.eventId == eventId);
}

TeamHeatmapRow _heatmapRow(TeamHeatmapData data, String name) {
  return data.rows.singleWhere((row) => row.athlete.name == name);
}

TeamHeatmapCell _heatmapCell(TeamHeatmapRow row, int eventId) {
  return row.cells.singleWhere((cell) => cell.eventId == eventId);
}

Future<_Seed3c2> _seed3c2Heatmap(AppDatabase db) async {
  final teamId = await db.teamsDao.createTeam(name: '3C2 Team');
  final alpha = await _insertAthlete(db, name: 'Alpha');
  final archived = await _insertAthlete(
    db,
    name: 'Archived Player',
    isArchived: true,
  );
  await db.teamsDao.assignAthleteToTeam(athleteId: alpha, teamId: teamId);
  await db.teamsDao.assignAthleteToTeam(athleteId: archived, teamId: teamId);

  final expected = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-05-01T10:00:00',
    taskName: 'Expected measured',
  );
  final fallback = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-05-02T10:00:00',
    taskName: 'Fallback load',
  );
  final incomplete = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-05-03T10:00:00',
    taskName: 'Incomplete load',
  );
  final measured4 = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-05-04T10:00:00',
    taskName: 'Measured four',
  );

  await _insertSession(
    db,
    athleteId: alpha,
    eventId: expected,
    date: '2026-05-01T10:00:00',
    taskName: 'Expected measured',
    loadValue: 80,
    rmssdExercise: 5,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 20,
    slope: 0.20,
    classification: 'expected_response',
  );
  await _insertSession(
    db,
    athleteId: alpha,
    eventId: fallback,
    date: '2026-05-02T10:00:00',
    taskName: 'Fallback load',
    loadValue: 82,
    rmssdExercise: 4,
    rmssdExerciseIsDefault: true,
    rmssdExerciseSource: 'fallback_4_ms',
    rmssdRecovery: 24,
    slope: 0.80,
    classification: 'low_internal_load_or_fast_recovery',
  );
  await _insertSession(
    db,
    athleteId: alpha,
    eventId: incomplete,
    date: '2026-05-03T10:00:00',
    taskName: 'Incomplete load',
    loadValue: 84,
    rmssdExercise: 6,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: null,
    slope: 9.9,
    classification: 'expected_response',
  );
  await _insertSession(
    db,
    athleteId: alpha,
    eventId: measured4,
    date: '2026-05-04T10:00:00',
    taskName: 'Measured four',
    loadValue: 86,
    rmssdExercise: 4,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 23,
    slope: 0.33,
    classification: 'low_internal_load_or_fast_recovery',
  );
  await _insertSession(
    db,
    athleteId: archived,
    eventId: expected,
    date: '2026-05-01T10:00:00',
    taskName: 'Expected measured',
    loadValue: 88,
    rmssdExercise: 7,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 27,
    slope: 0.40,
    classification: 'high_or_moderate_internal_load',
  );
  await _insertSession(
    db,
    athleteId: archived,
    eventId: measured4,
    date: '2026-05-04T10:00:00',
    taskName: 'Measured four duplicate A',
    loadValue: 90,
    rmssdExercise: 8,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 28,
    slope: 0.50,
    classification: 'expected_response',
  );
  await _insertSession(
    db,
    athleteId: archived,
    eventId: measured4,
    date: '2026-05-04T10:00:00',
    taskName: 'Measured four duplicate B',
    loadValue: 92,
    rmssdExercise: 9,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 29,
    slope: 0.60,
    classification: 'expected_response',
  );

  return _Seed3c2(
    teamId: teamId,
    athleteIds: {'alpha': alpha, 'archived': archived},
    eventIds: {
      'expected': expected,
      'fallback': fallback,
      'incomplete': incomplete,
      'measured4': measured4,
    },
  );
}

Future<_SameDaySeed> _seedSameDayEvents(AppDatabase db) async {
  final teamId = await db.teamsDao.createTeam(name: 'Same Day FC');
  final alpha = await _insertAthlete(db, name: 'Alpha');
  final bravo = await _insertAthlete(db, name: 'Bravo');
  await db.teamsDao.assignAthleteToTeam(athleteId: alpha, teamId: teamId);
  await db.teamsDao.assignAthleteToTeam(athleteId: bravo, teamId: teamId);

  final morning = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-08-20T10:00:00',
    taskName: 'Training',
  );
  final afternoon = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-08-20T17:00:00',
    taskName: 'Training',
  );

  await _insertSession(
    db,
    athleteId: alpha,
    eventId: morning,
    date: '2026-08-20T10:00:00',
    taskName: 'Training',
    loadValue: 80,
    rmssdExercise: 5,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 20,
    slope: 0.20,
    classification: 'expected_response',
  );
  await _insertSession(
    db,
    athleteId: bravo,
    eventId: morning,
    date: '2026-08-20T10:00:00',
    taskName: 'Training',
    loadValue: 82,
    rmssdExercise: 6,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 21,
    slope: 0.25,
    classification: 'expected_response',
  );
  await _insertSession(
    db,
    athleteId: alpha,
    eventId: afternoon,
    date: '2026-08-20T17:00:00',
    taskName: 'Training',
    loadValue: 84,
    rmssdExercise: 7,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 22,
    slope: 0.30,
    classification: 'expected_response',
  );
  await _insertSession(
    db,
    athleteId: bravo,
    eventId: afternoon,
    date: '2026-08-20T17:00:00',
    taskName: 'Training',
    loadValue: 86,
    rmssdExercise: 8,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 23,
    slope: 0.35,
    classification: 'expected_response',
  );

  return _SameDaySeed(
    teamId: teamId,
    athleteIds: {'alpha': alpha, 'bravo': bravo},
    morningEventId: morning,
    afternoonEventId: afternoon,
  );
}

Future<_DateOnlySeed> _seedDateOnlyEvent(AppDatabase db) async {
  final teamId = await db.teamsDao.createTeam(name: 'Historic Date Only FC');
  final alpha = await _insertAthlete(db, name: 'Alpha');
  await db.teamsDao.assignAthleteToTeam(athleteId: alpha, teamId: teamId);

  final eventId = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-08-21',
    taskName: 'Training',
  );
  await _insertSession(
    db,
    athleteId: alpha,
    eventId: eventId,
    date: '2026-08-21',
    taskName: 'Training',
    loadValue: 80,
    rmssdExercise: 5,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 20,
    slope: 0.20,
    classification: 'expected_response',
  );

  return _DateOnlySeed(teamId: teamId, eventId: eventId);
}

Future<_LargeSeed> _seedLargeHeatmap(
  AppDatabase db, {
  required int athleteCount,
  required int eventCount,
}) async {
  final teamId = await db.teamsDao.createTeam(name: 'Large 3C2 Team');
  final athleteIds = <int>[];
  for (var i = 1; i <= athleteCount; i++) {
    final athleteId = await _insertAthlete(
      db,
      name: 'Player ${i.toString().padLeft(2, '0')}',
    );
    athleteIds.add(athleteId);
    await db.teamsDao.assignAthleteToTeam(athleteId: athleteId, teamId: teamId);
  }

  var lastEventId = 0;
  for (var i = 1; i <= eventCount; i++) {
    final date = DateTime(2026, 6, 1 + i, 10).toIso8601String();
    final eventId = await _insertEvent(
      db,
      teamId: teamId,
      date: date,
      taskName: 'E$i',
    );
    lastEventId = eventId;
    final athleteId = athleteIds[(i - 1) % athleteIds.length];
    await _insertSession(
      db,
      athleteId: athleteId,
      eventId: eventId,
      date: date,
      taskName: 'E$i',
      loadValue: 70 + i.toDouble(),
      rmssdExercise: 5,
      rmssdExerciseIsDefault: false,
      rmssdExerciseSource: 'measured',
      rmssdRecovery: 20 + i.toDouble(),
      slope: 0.2 + i / 100,
      classification: 'expected_response',
    );
  }

  return _LargeSeed(
    teamId: teamId,
    lastEventId: lastEventId,
    lastAthleteId: athleteIds.last,
  );
}

Future<int> _insertAthlete(
  AppDatabase db, {
  required String name,
  bool isArchived = false,
}) {
  final now = DateTime.now().toIso8601String();
  return db.athletesDao.insertAthlete(
    AthletesCompanion.insert(
      name: name,
      sport: const drift.Value('Soccer'),
      isArchived: drift.Value(isArchived),
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<int> _insertEvent(
  AppDatabase db, {
  required int teamId,
  required String date,
  required String taskName,
}) {
  final now = DateTime.now().toIso8601String();
  return db.sessionEventsDao.createEvent(
    SessionEventsCompanion.insert(
      teamId: drift.Value(teamId),
      date: date,
      taskName: drift.Value(taskName),
      sport: const drift.Value('Soccer'),
      sessionType: const drift.Value('Training'),
      protocolName: const drift.Value('5-10'),
      contextEnvironment: const drift.Value('Field'),
      recoveryWindowStartMin: 5,
      recoveryWindowEndMin: 10,
      loadType: 'external',
      loadMetricName: 'percent_mas',
      loadUnit: const drift.Value('%'),
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<int> _insertSession(
  AppDatabase db, {
  required int athleteId,
  required int eventId,
  required String date,
  required String taskName,
  required double loadValue,
  required double? rmssdExercise,
  required bool rmssdExerciseIsDefault,
  required String rmssdExerciseSource,
  required double? rmssdRecovery,
  required double? slope,
  required String? classification,
}) async {
  final now = DateTime.now().toIso8601String();
  final sessionId = await db.sessionsDao.insertSession(
    SessionsCompanion.insert(
      athleteId: athleteId,
      eventId: drift.Value(eventId),
      date: date,
      taskName: drift.Value(taskName),
      sport: const drift.Value('Soccer'),
      sessionType: const drift.Value('Training'),
      protocolName: const drift.Value('5-10'),
      contextEnvironment: const drift.Value('Field'),
      isDraft: const drift.Value(false),
      intensityPercent: const drift.Value(80),
      intensitySource: const drift.Value('External'),
      recoveryTimeMin: const drift.Value(10),
      recoveryWindowStartMin: const drift.Value(5),
      recoveryWindowEndMin: const drift.Value(10),
      rmssdExercise: drift.Value(rmssdExercise),
      rmssdExerciseIsDefault: drift.Value(rmssdExerciseIsDefault),
      rmssdRecovery: drift.Value(rmssdRecovery),
      slopeRaw: drift.Value(slope),
      slopeInterpreted: drift.Value(slope),
      itlIndex: drift.Value(slope == null ? null : slope * 1.5),
      classification: drift.Value(classification),
      hrvInputMode: const drift.Value('direct_rmssd'),
      rmssdRecoverySource: const drift.Value('manual'),
      rmssdExerciseSource: drift.Value(rmssdExerciseSource),
      rrQualityFlag: const drift.Value(null),
      rrQualityDecision: const drift.Value(null),
      createdAt: now,
    ),
  );
  await db.sessionsDao.insertVariable(
    IntensityVariablesCompanion.insert(
      sessionId: sessionId,
      category: 'external',
      name: 'percent_mas',
      unit: const drift.Value('%'),
      value: loadValue,
      source: const drift.Value('manual'),
      isPrimaryForNomogram: const drift.Value(true),
      createdAt: now,
    ),
  );
  return sessionId;
}

class _Seed3c2 {
  final int teamId;
  final Map<String, int> athleteIds;
  final Map<String, int> eventIds;

  const _Seed3c2({
    required this.teamId,
    required this.athleteIds,
    required this.eventIds,
  });
}

class _SameDaySeed {
  final int teamId;
  final Map<String, int> athleteIds;
  final int morningEventId;
  final int afternoonEventId;

  const _SameDaySeed({
    required this.teamId,
    required this.athleteIds,
    required this.morningEventId,
    required this.afternoonEventId,
  });
}

class _DateOnlySeed {
  final int teamId;
  final int eventId;

  const _DateOnlySeed({required this.teamId, required this.eventId});
}

class _LargeSeed {
  final int teamId;
  final int lastEventId;
  final int lastAthleteId;

  const _LargeSeed({
    required this.teamId,
    required this.lastEventId,
    required this.lastAthleteId,
  });
}
