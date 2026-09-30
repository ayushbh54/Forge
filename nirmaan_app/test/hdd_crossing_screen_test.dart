import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/screens/engineering/hdd_crossing_screen.dart';

void main() {
  group('ASME B31.8 / API RP 1111 HDD Domain Models & Calculations', () {
    test('Major Crossings Repository contains 3 engineered sites', () {
      final sites = HddCrossingRepository.majorCrossings;
      expect(sites.length, 3);

      final siteIds = sites.map((s) => s.id).toList();
      expect(siteIds, containsAll(['burhi_dihing', 'disang_river', 'nh37_crossing']));
    });

    test('Burhi Dihing River Crossing geometry & statutory tolerances', () {
      final site = HddCrossingRepository.majorCrossings
          .firstWhere((s) => s.id == 'burhi_dihing');

      expect(site.profileLengthM, 1250.0);
      expect(site.pipeDiameterInches, 24);
      expect(site.pipeOuterDiameterMm, 610.0);
      expect(site.pipeGrade, 'API 5L X70 PSL2');

      // Entry Angle corridor: 8° to 12°
      expect(site.entryAngleDeg, 10.5);
      expect(site.isEntryAngleCompliant, isTrue);

      // Exit Angle corridor: 5° to 8°
      expect(site.exitAngleDeg, 6.8);
      expect(site.isExitAngleCompliant, isTrue);

      // Statutory depth below scour line > 6.0 m
      expect(site.statutoryMinClearanceM, 6.0);
      expect(site.actualDepthBelowScourM, 18.5);
      expect(site.isScourClearanceCompliant, isTrue);
      expect(site.scourMarginAboveStatutoryM, 12.5);

      // Pullback rig specifications
      expect(site.maxRigCapacityTonnes, 350.0);
      expect(site.targetPullTensionTonnes, 180.0);

      // Minimum bending radius per ASME B31.8: R >= 1200 * D
      expect(site.minRadiusOfCurvatureM, 732.0);
      expect(site.designRadiusOfCurvatureM, 980.0);
      expect(site.designRadiusOfCurvatureM > site.minRadiusOfCurvatureM, isTrue);
    });

    test('Disang River Crossing profile & reaming passes', () {
      final site = HddCrossingRepository.majorCrossings
          .firstWhere((s) => s.id == 'disang_river');

      expect(site.profileLengthM, 890.0);
      expect(site.pipeDiameterInches, 18);
      expect(site.entryAngleDeg, 9.2);
      expect(site.isEntryAngleCompliant, isTrue);
      expect(site.exitAngleDeg, 6.0);
      expect(site.isExitAngleCompliant, isTrue);
      expect(site.actualDepthBelowScourM, 14.2);
      expect(site.isScourClearanceCompliant, isTrue);
      expect(site.minRadiusOfCurvatureM, closeTo(548.4, 0.01));
    });

    test('NH-37 Highway Crossing pavement subgrade clearance', () {
      final site = HddCrossingRepository.majorCrossings
          .firstWhere((s) => s.id == 'nh37_crossing');

      expect(site.profileLengthM, 180.0);
      expect(site.pipeDiameterInches, 30);
      expect(site.crossingType, HddCrossingType.highwayCrossing);
      expect(site.entryAngleDeg, 8.5);
      expect(site.isEntryAngleCompliant, isTrue);
      expect(site.exitAngleDeg, 5.5);
      expect(site.isExitAngleCompliant, isTrue);
      expect(site.actualDepthBelowScourM, 6.6);
      expect(site.isScourClearanceCompliant, isTrue);
      expect(site.minRadiusOfCurvatureM, closeTo(914.4, 0.01));
    });

    test('Reaming Passes Tracking: 16", 26", 36", 48" barrel reamer limits', () {
      final site = HddCrossingRepository.majorCrossings
          .firstWhere((s) => s.id == 'burhi_dihing');
      final passes = site.reamingPasses;

      expect(passes.length, 4);
      final diameters = passes.map((p) => p.diameterInches).toList();
      expect(diameters, [16, 26, 36, 48]);

      for (final pass in passes) {
        // Torque check: target limit 65 kN-m
        expect(pass.rotaryTorqueKnm <= pass.maxTorqueLimitKnm, isTrue,
            reason: '${pass.passTitle} torque exceeds 65 kN-m');
        // Pressure check: max 120 bar limit
        expect(pass.mudPumpPressureBar <= pass.maxMudPressureLimitBar, isTrue,
            reason: '${pass.passTitle} mud pressure exceeds 120 bar');
        // Slurry flow rate: 180–240 m³/hr
        expect(pass.bentoniteSlurryFlowRateM3h, inInclusiveRange(180.0, 240.0),
            reason: '${pass.passTitle} flow rate outside target');
      }
    });

    test('Buoyancy Control Water Filling Schedule stages', () {
      final site = HddCrossingRepository.majorCrossings
          .firstWhere((s) => s.id == 'burhi_dihing');
      final stages = site.buoyancyStages;

      expect(stages.length, 4);
      // All stages maintain near-neutral submerged weight (-12 to -15 kg/m)
      for (final stage in stages) {
        expect(stage.netSubmergedWeightKgM, lessThan(0.0));
        expect(stage.netSubmergedWeightKgM, greaterThan(-25.0));
      }
    });

    test('Steering Tool Modes verify guidance sensor properties', () {
      expect(SteeringToolMode.gyro.sensorType, contains('Fiber-Optic'));
      expect(SteeringToolMode.gyro.interferenceResistance, contains('100% Magnetic Immune'));

      expect(SteeringToolMode.paratrack.sensorType, contains('DC Surface Wire Loop'));
      expect(SteeringToolMode.paratrack.driftRate, contains('Zero Drift'));
    });
  });

  group('HddCrossingScreen Widget Tests', () {
    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: const HddCrossingScreen(),
      );
    }

    testWidgets('Renders HDD Crossing Engineering screen and elements',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('HDD Crossing'), findsOneWidget);
      expect(find.text('API RP 1111'), findsOneWidget);
      expect(find.textContaining('ASME B31.8 Ch. VIII'), findsOneWidget);

      // Verify 3 Crossing Selector Chips
      expect(find.text('Burhi Dihing River Crossing'), findsOneWidget);
      expect(find.text('Disang River Crossing'), findsOneWidget);
      expect(find.text('NH-37 Highway Crossing'), findsOneWidget);

      // Verify KPI Summary Bar
      expect(find.text('SCOUR CLEARANCE'), findsWidgets);
      expect(find.text('ENTRY ANGLE'), findsWidgets);
      expect(find.text('EXIT ANGLE'), findsWidgets);
      expect(find.text('PULL TENSION'), findsWidgets);

      // Verify Tab bar titles
      expect(find.text('Steering & Profile'), findsOneWidget);
      expect(find.text('Reaming Passes'), findsOneWidget);
      expect(find.text('Pullback & Buoyancy'), findsOneWidget);
      expect(find.text('ASME B31.8 Audit'), findsOneWidget);
    });

    testWidgets('Steering & Profile tab displays guidance tools and gauges',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tool mode selector
      expect(find.text('STEERING TOOL TELEMETRY MODE'), findsOneWidget);
      expect(find.text('Optical Gyro'), findsOneWidget);
      expect(find.text('ParaTrack-2'), findsOneWidget);

      // Tap ParaTrack-2
      await tester.tap(find.text('ParaTrack-2'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Active AC Cancellation'), findsOneWidget);

      // Scour check card
      expect(find.text('SCOUR LINE STATUTORY DEPTH CHECK'), findsOneWidget);
      expect(find.text('> 6.0 m MANDATORY'), findsOneWidget);
      expect(find.text('18.5 m'), findsWidgets);

      // Entry / Exit tolerance cards
      expect(find.text('10.5°'), findsWidgets);
      expect(find.text('6.8°'), findsWidgets);
      expect(find.text('IN TOLERANCE'), findsWidgets);
    });

    testWidgets('Switching crossing site updates specifications',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Disang River Crossing
      await tester.tap(find.text('Disang River Crossing'));
      await tester.pumpAndSettle();

      // Verify Disang specific metrics
      expect(find.text('Profile Length: 890 m'), findsOneWidget);
      expect(find.text('14.2 m'), findsWidgets); // actual depth below scour
      expect(find.text('9.2°'), findsWidgets); // entry angle
      expect(find.text('6.0°'), findsWidgets); // exit angle
    });

    testWidgets('Reaming Passes tab shows 16", 26", 36", 48" passes and metrics',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Tab 2: Reaming Passes
      await tester.tap(find.text('Reaming Passes'));
      await tester.pumpAndSettle();

      expect(find.text('MULTI-STAGE BARREL REAMING CONTROL'), findsOneWidget);
      expect(find.text('16" Barrel Reamer Pass (Pass 1)'), findsOneWidget);
      expect(find.text('26" Barrel Reamer Pass (Pass 2)'), findsOneWidget);
      expect(find.text('36" Barrel Reamer Pass (Pass 3)'), findsOneWidget);
      expect(find.text('48" Final Barrel Reamer Pass (Pass 4)'), findsOneWidget);

      // Verify torque, pressure and slurry metrics are labeled
      expect(find.text('ROTARY TORQUE'), findsWidgets);
      expect(find.text('PUMP PRESSURE'), findsWidgets);
      expect(find.text('BENTONITE FLOW'), findsWidgets);
      expect(find.text('BENTONITE SLURRY RHEOLOGY SPECIFICATIONS'), findsOneWidget);
    });

    testWidgets('Pullback & Buoyancy tab shows load cell tension & ballast schedule',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Tab 3: Pullback & Buoyancy
      await tester.tap(find.text('Pullback & Buoyancy'));
      await tester.pumpAndSettle();

      expect(find.text('PULLBACK RIG LOAD CELL TENSION'), findsOneWidget);
      expect(find.text('TARGET COMPLIANT'), findsOneWidget);
      expect(find.text('Target Limit: < 180 tonnes'), findsOneWidget);
      expect(find.text('Max Rig Pull Capacity: 350 tonnes'), findsOneWidget);
      expect(find.text('350 t Rig Max'), findsOneWidget);

      // Dual load cells
      expect(find.text('LOAD CELL A (HYDRAULIC)'), findsOneWidget);
      expect(find.text('LOAD CELL B (STRAIN GAUGE)'), findsOneWidget);

      // Buoyancy control water filling schedule
      expect(find.text('BUOYANCY CONTROL WATER FILLING SCHEDULE'), findsOneWidget);
      expect(find.text('BALLAST WATER INJECTION TELEMETRY'), findsOneWidget);
      expect(find.text('PIPE THRUSTER & ROLLER CRADLE SYSTEM'), findsOneWidget);

      // Test Inject +5 m³ button
      final injectBtn = find.text('Inject +5 m³');
      expect(injectBtn, findsOneWidget);
      await tester.tap(injectBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('113.5 m³'), findsOneWidget); // 108.5 + 5.0 = 113.5 m³
    });

    testWidgets('ASME B31.8 Audit tab shows stress checks and opens certificate',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Tab 4: ASME B31.8 Audit
      await tester.tap(find.text('ASME B31.8 Audit'));
      await tester.pumpAndSettle();

      expect(find.text('ASME B31.8 / API RP 1111 TRENCHLESS AUDIT'), findsOneWidget);
      expect(find.text('ASME B31.8 SECTION 844.4 STRESS VERIFICATION'), findsOneWidget);
      expect(find.text('API RP 1111 HYDROSTATIC COLLAPSE INTEGRITY'), findsOneWidget);
      expect(find.text('MANDATORY TRENCHLESS QA/QC SIGN-OFFS'), findsOneWidget);

      // Tap QA Certificate Button
      final certButton = find.text('VIEW ASME B31.8 QA/QC CERTIFICATE');
      expect(certButton, findsOneWidget);
      await tester.tap(certButton);
      await tester.pumpAndSettle();

      // Verify Certificate Sheet appears
      expect(find.text('TRENCHLESS CROSSING CERTIFICATE'), findsOneWidget);
      expect(find.text('CLOSE CERTIFICATE'), findsOneWidget);

      await tester.tap(find.text('CLOSE CERTIFICATE'));
      await tester.pumpAndSettle();
      expect(find.text('TRENCHLESS CROSSING CERTIFICATE'), findsNothing);
    });
  });
}
