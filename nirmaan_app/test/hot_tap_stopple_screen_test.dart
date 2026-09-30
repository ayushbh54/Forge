import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/screens/operations/hot_tap_stopple_screen.dart';

void main() {
  group('ASME B31.8 / API RP 2201 Hot Tapping & Battelle Model Unit Tests', () {
    const testPipe = PipeSpec(
      tag: 'OIL-DUL-NUM-24-001',
      pipelineName: 'Duliajan-Numaligarh 24" Natural Gas Trunkline',
      chainageKp: 42.850,
      nominalDiaInch: 24.0,
      outerDiaMm: 610.0,
      wallThicknessMm: 11.91,
      steelGrade: 'API 5L Grade X65 (PSL2)',
      smysMpa: 448.0,
      designPressureBar: 98.0,
      operatingPressureBar: 68.5,
      gasVelocityMs: 4.2,
      gasTempC: 24.0,
    );

    test('WeldingParams calculates correct net heat input (kJ/mm)', () {
      const welding = WeldingParams(
        process: 'SMAW',
        electrode: 'E7018-H4R',
        currentAmps: 130.0,
        voltageVolts: 22.0,
        travelSpeedMmMin: 165.0,
        arcEfficiency: 0.80,
        preheatTempC: 115.0,
        interpassTempC: 155.0,
      );

      // H = (22 * 130 * 60 * 0.80) / (165 * 1000) = 137280 / 165000 = 0.832 kJ/mm
      final h = welding.netHeatInputKjPerMm;
      expect(h, closeTo(0.832, 0.005));
    });

    test('BattelleModelEngine evaluates safe window within qualified WPS limits', () {
      const qualifiedWelding = WeldingParams(
        process: 'SMAW',
        electrode: 'E7018-H4R',
        currentAmps: 130.0,
        voltageVolts: 22.0,
        travelSpeedMmMin: 165.0,
        arcEfficiency: 0.80,
        preheatTempC: 115.0,
        interpassTempC: 155.0,
      );

      final calc = BattelleModelEngine.evaluate(
        pipe: testPipe,
        welding: qualifiedWelding,
      );

      expect(calc.isSafe, isTrue);
      expect(calc.safetyStatus, contains('SAFE WINDOW'));
      expect(calc.peakInnerTempC, lessThan(580.0));
      expect(calc.coolingTimeT85Sec, greaterThanOrEqualTo(2.2));
      expect(calc.predictedHazHardnessHv, lessThanOrEqualTo(300.0));
    });

    test('BattelleModelEngine detects burn-through risk when heat input is excessively high', () {
      const highHeatWelding = WeldingParams(
        process: 'SMAW',
        electrode: 'E7018',
        currentAmps: 220.0,
        voltageVolts: 28.0,
        travelSpeedMmMin: 100.0,
        arcEfficiency: 0.85,
        preheatTempC: 150.0,
        interpassTempC: 200.0,
      );

      final calc = BattelleModelEngine.evaluate(
        pipe: testPipe,
        welding: highHeatWelding,
      );

      expect(calc.isSafe, isFalse);
      expect(calc.safetyStatus, contains('BURN-THROUGH DANGER'));
      expect(calc.heatInputKjPerMm, greaterThan(calc.maxSafeHeatInputKjMm));
    });

    test('BattelleModelEngine detects fast cooling & hydrogen cracking risk when heat input is too low', () {
      const lowHeatWelding = WeldingParams(
        process: 'SMAW',
        electrode: 'E7018',
        currentAmps: 80.0,
        voltageVolts: 18.0,
        travelSpeedMmMin: 300.0,
        arcEfficiency: 0.75,
        preheatTempC: 50.0,
        interpassTempC: 100.0,
      );

      final calc = BattelleModelEngine.evaluate(
        pipe: testPipe,
        welding: lowHeatWelding,
      );

      expect(calc.isSafe, isFalse);
      expect(calc.safetyStatus, contains('HYDROGEN CRACKING RISK'));
      expect(calc.heatInputKjPerMm, lessThan(calc.minSafeHeatInputKjMm));
    });
  });

  group('Tapping Machine & Dual Stopple Domain Telemetry Tests', () {
    test('TappingMachineTelemetry differential pressure and progress ratio', () {
      const tap = TappingMachineTelemetry(
        strokeDepthMm: 254.2,
        targetDepthMm: 310.0,
        phase: CutterPhase.trepanningCut,
        retentionState: CouponRetentionState.latched,
        retentionWireTensionKn: 2.85,
        gearboxHydraulicRpm: 19.4,
        feedRateMmMin: 0.38,
        hydraulicPressureBar: 115.0,
        cuttingTorqueNm: 865.0,
        housingPressureBar: 68.4,
        pipelinePressureBar: 68.5,
        bypassValveState: BypassValveState.openEqualized,
        sandwichValveState: SandwichValveState.openLocked,
        cutterMotorTempC: 48.6,
      );

      expect(tap.differentialPressureBar, closeTo(0.1, 0.01));
      expect(tap.progressRatio, closeTo(254.2 / 310.0, 0.01));
      expect(tap.phase, CutterPhase.trepanningCut);
      expect(tap.retentionState, CouponRetentionState.latched);
      expect(tap.retentionWireTensionKn, greaterThan(2.0));
    });

    test('DualStoppleTelemetry hydrocarbon sniffer < 1% LEL safety criteria', () {
      const safeStopple = DualStoppleTelemetry(
        stopple1CylinderPressureBar: 148.0,
        stopple2CylinderPressureBar: 150.0,
        stopple1Seated: true,
        stopple2Seated: true,
        stopple1SealBorePercent: 100.0,
        stopple2SealBorePercent: 100.0,
        isolatedChamberPressureBar: 0.02,
        n2PurgeFlowM3h: 380.0,
        n2TotalPurgedM3: 2450.0,
        sniffer1LelPercent: 0.14,
        sniffer2LelPercent: 0.08,
        sniffer3LelPercent: 0.11,
        oxygenLevelPercent: 0.16,
        temporaryBypassFlowMmscmd: 4.82,
        temporaryBypassDiffPressureBar: 0.74,
        temporaryBypassVelocityMs: 8.4,
        bypassActive: true,
      );

      expect(safeStopple.maxSnifferLel, 0.14);
      expect(safeStopple.isHotWorkSafe, isTrue);

      const unsafeStopple = DualStoppleTelemetry(
        stopple1CylinderPressureBar: 148.0,
        stopple2CylinderPressureBar: 150.0,
        stopple1Seated: true,
        stopple2Seated: true,
        stopple1SealBorePercent: 100.0,
        stopple2SealBorePercent: 100.0,
        isolatedChamberPressureBar: 0.02,
        n2PurgeFlowM3h: 380.0,
        n2TotalPurgedM3: 1500.0,
        sniffer1LelPercent: 1.45, // Exceeds 1.0% LEL
        sniffer2LelPercent: 0.08,
        sniffer3LelPercent: 0.11,
        oxygenLevelPercent: 0.16,
        temporaryBypassFlowMmscmd: 4.82,
        temporaryBypassDiffPressureBar: 0.74,
        temporaryBypassVelocityMs: 8.4,
        bypassActive: true,
      );

      expect(unsafeStopple.isHotWorkSafe, isFalse);
    });

    test('LorCompletionData segment locking and torque verification', () {
      const lorComplete = LorCompletionData(
        plugDepthMm: 310.0,
        lockedSegments: 6,
        totalSegments: 6,
        cavityBleedPressureBar: 0.0,
        isLorSealHolding: true,
        sandwichValveRecovered: true,
        rtjGasketType: 'Soft Iron Ring R-73',
        torqueTargetNm: 1450.0,
        torqueAppliedNm: 1450.0,
        torqueStarPassesCompleted: 4,
        n2TestPressureBar: 75.0,
        n2TestVerified: true,
      );

      expect(lorComplete.allSegmentsLocked, isTrue);
      expect(lorComplete.isTorqueComplete, isTrue);
      expect(lorComplete.sandwichValveRecovered, isTrue);
    });
  });

  group('HotTapStoppleScreen Widget Rendering & Navigation Tests', () {
    testWidgets('Renders AppBar, Status Banner, Metric Chips, and 4 Main Tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HotTapStoppleScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Hot Tapping & Stopple Ops'), findsOneWidget);
      expect(find.text('API RP 2201 / ASME B31.8'), findsOneWidget);
      expect(find.textContaining('Duliajan-Numaligarh 24" Natural Gas Trunkline'), findsOneWidget);
      expect(find.text('BATTELLE ENVELOPE: SAFE'), findsOneWidget);

      // Verify metric chips
      expect(find.text('PRESSURE'), findsOneWidget);
      expect(find.text('GAS VELOCITY'), findsOneWidget);
      expect(find.text('WALL THICKNESS'), findsOneWidget);
      expect(find.text('MAX LEL'), findsOneWidget);

      // Verify 4 Tab headers
      expect(find.text('Split Tee & Battelle'), findsOneWidget);
      expect(find.text('Tapping Telemetry'), findsOneWidget);
      expect(find.text('Dual Stopple & Purge'), findsOneWidget);
      expect(find.text('LOR & QA/QC'), findsOneWidget);

      // In Tab 1: Check Battelle Chart & Welding Calculator
      expect(find.text('Battelle Safe Operating Heat Input Envelope'), findsOneWidget);
      expect(find.text('Welding Parameters & Live Battelle Calculation'), findsOneWidget);
      expect(find.text('Full Encirclement Split Tee Specification'), findsOneWidget);
      expect(find.text('Circumferential Sleeve Temper Bead Layer Sequence'), findsOneWidget);
    });

    testWidgets('Tab 2: Switch to Tapping Telemetry & test stroke advance / retract',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HotTapStoppleScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Tab 2
      await tester.tap(find.text('Tapping Telemetry'));
      await tester.pumpAndSettle();

      expect(find.text('Hot Tap Machine Cutter Travel Depth'), findsOneWidget);
      expect(find.text('Pilot Drill Coupon Retention Telemetry'), findsOneWidget);
      expect(find.text('Pressure Equalizing Bypass Line & Valve'), findsOneWidget);
      expect(find.text('Hydraulic Power Unit & Gearbox Telemetry'), findsOneWidget);
      expect(find.text('Real-Time Cutting Telemetry Trends'), findsOneWidget);

      // Tap Advance Cutter button
      await tester.tap(find.text('Advance Cutter 5.0 mm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Emergency Retract button
      await tester.tap(find.text('Emergency Retract'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Hydraulic Retract Initiated'), findsOneWidget);
    });

    testWidgets('Tab 2: Test Pressure Equalizing Bypass Line valve balancing',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HotTapStoppleScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Tab 2
      await tester.tap(find.text('Tapping Telemetry'));
      await tester.pumpAndSettle();

      // Tap Equalize Bypass Line button
      await tester.tap(find.text('Equalize Bypass Line (2" Needle)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Bypass needle valve open'), findsOneWidget);
    });

    testWidgets('Tab 3: Switch to Dual Stopple & Purge, verify sniffer & bypass',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HotTapStoppleScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Tab 3
      await tester.tap(find.text('Dual Stopple & Purge'));
      await tester.pumpAndSettle();

      expect(find.text('Dual Stopple & Bypass Arrangement'), findsOneWidget);
      expect(find.text('100% ISOLATION ACTIVE'), findsOneWidget);
      expect(find.text('Stopple Sealing Elements & Hydraulic Actuators'), findsOneWidget);
      expect(find.text('Temporary 16" Bypass Line Flow Monitoring'), findsOneWidget);
      expect(find.text('Isolation Chamber Nitrogen Purge Cycle'), findsOneWidget);
      expect(find.text('Multi-Point Hydrocarbon Sniffer (LEL Monitor)'), findsOneWidget);
      expect(find.text('LEL SAFE (< 1.0%)'), findsOneWidget);

      // Tap Execute Gas Sniff Calibration
      await tester.tap(find.text('Execute Gas Sniff Calibration'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Optical IR Sniffer calibrated'), findsOneWidget);

      // Clear active snackbar
      ScaffoldMessenger.of(tester.element(find.byType(HotTapStoppleScreen))).clearSnackBars();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Permit Cold Cutting
      await tester.tap(find.text('Permit Cold Cutting'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('PTW-HOT-0428 Validated'), findsOneWidget);
    });

    testWidgets('Tab 4: Switch to LOR & QA/QC, toggle checklist & demount valve',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HotTapStoppleScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Tab 4
      await tester.tap(find.text('LOR & QA/QC'));
      await tester.pumpAndSettle();

      expect(find.text('Lock-O-Ring (LOR) Completion Plug Setting'), findsOneWidget);
      expect(find.text('6/6 SEGMENTS LOCKED'), findsOneWidget);
      expect(find.text('Blind Flange Installation & Hydraulic Torquing'), findsOneWidget);
      expect(find.text('ASME B31.8 / API RP 2201 Mandatory Checklist'), findsOneWidget);
      expect(find.text('Quality & Safety Authority Sign-Offs'), findsOneWidget);

      // Tap Confirm Valve Demount & Recovery button
      await tester.tap(find.text('Confirm Valve Demount & Recovery'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Sandwich Valve unbolted'), findsOneWidget);

      // Find an uncompleted checklist checkbox (CHK-07) and toggle it
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);
      await tester.tap(checkboxes.at(6));
      await tester.pumpAndSettle();

      expect(find.textContaining('Signed by A. Saikia (QC Lead)'), findsWidgets);
    });

    testWidgets('Triggers Emergency Protocol and Export Technical Dossier dialogs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HotTapStoppleScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Emergency icon in AppBar
      await tester.tap(find.byIcon(Icons.warning_amber_rounded));
      await tester.pumpAndSettle();

      expect(find.text('API RP 2201 Emergency Protocol'), findsOneWidget);
      expect(find.text('ACKNOWLEDGE PROTOCOL'), findsOneWidget);

      await tester.tap(find.text('ACKNOWLEDGE PROTOCOL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Safety Protocol Broadcasted'), findsOneWidget);

      // Wait for first snackbar to settle before opening next dialog
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Tap Export Dossier icon in AppBar
      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Export Hot Tap Technical Dossier'), findsOneWidget);
      expect(find.text('DOWNLOAD PDF DOSSIER'), findsOneWidget);

      await tester.tap(find.text('DOWNLOAD PDF DOSSIER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('OIL_HOT_TAP_KP42_DOSSIER.pdf'), findsOneWidget);
    });
  });
}
