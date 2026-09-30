import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/integrity/cips_dcvg_screen.dart';

void main() {
  group('DCVG %IR Defect Severity & Classification Tests (NACE SP0207 / ECDA)', () {
    test('%IR Defect calculation formula: %IR = (delta_V / total_IR) * 100', () {
      // Delta V = 24.0 mV, Total IR = 220.0 mV -> %IR = 10.909%
      final percentIr1 = DcvgDefectRecord.calculatePercentIr(24.0, 220.0);
      expect(percentIr1, closeTo(10.909, 0.01));

      // Delta V = 48.0 mV, Total IR = 210.0 mV -> %IR = 22.857%
      final percentIr2 = DcvgDefectRecord.calculatePercentIr(48.0, 210.0);
      expect(percentIr2, closeTo(22.857, 0.01));

      // Delta V = 145.0 mV, Total IR = 170.0 mV -> %IR = 85.294%
      final percentIr3 = DcvgDefectRecord.calculatePercentIr(145.0, 170.0);
      expect(percentIr3, closeTo(85.294, 0.01));

      // Edge case: total IR <= 0
      expect(DcvgDefectRecord.calculatePercentIr(50.0, 0.0), equals(0.0));
      expect(DcvgDefectRecord.calculatePercentIr(50.0, -10.0), equals(0.0));
    });

    test('NACE SP0207 Coating Defect Severity Category Classification', () {
      // Category 1: < 15% IR (Isolated minor holiday)
      expect(DcvgDefectCategoryExt.fromPercentIr(0.0), DcvgDefectCategory.category1);
      expect(DcvgDefectCategoryExt.fromPercentIr(8.5), DcvgDefectCategory.category1);
      expect(DcvgDefectCategoryExt.fromPercentIr(14.99), DcvgDefectCategory.category1);

      // Category 2: 15% - 35% IR (Moderate coating defect)
      expect(DcvgDefectCategoryExt.fromPercentIr(15.0), DcvgDefectCategory.category2);
      expect(DcvgDefectCategoryExt.fromPercentIr(25.0), DcvgDefectCategory.category2);
      expect(DcvgDefectCategoryExt.fromPercentIr(35.0), DcvgDefectCategory.category2);

      // Category 3: 35% - 70% IR (Severe coating defect)
      expect(DcvgDefectCategoryExt.fromPercentIr(35.01), DcvgDefectCategory.category3);
      expect(DcvgDefectCategoryExt.fromPercentIr(55.0), DcvgDefectCategory.category3);
      expect(DcvgDefectCategoryExt.fromPercentIr(70.0), DcvgDefectCategory.category3);

      // Category 4: > 70% IR (Critical holiday / bare pipe)
      expect(DcvgDefectCategoryExt.fromPercentIr(70.01), DcvgDefectCategory.category4);
      expect(DcvgDefectCategoryExt.fromPercentIr(85.3), DcvgDefectCategory.category4);
      expect(DcvgDefectCategoryExt.fromPercentIr(100.0), DcvgDefectCategory.category4);
    });

    test('DcvgDefectCategory properties & labels', () {
      expect(DcvgDefectCategory.category1.code, contains('<15%'));
      expect(DcvgDefectCategory.category2.code, contains('15-35%'));
      expect(DcvgDefectCategory.category3.code, contains('35-70%'));
      expect(DcvgDefectCategory.category4.code, contains('>70%'));

      expect(DcvgDefectCategory.category1.severityLabel, 'Low Priority');
      expect(DcvgDefectCategory.category4.severityLabel, 'Immediate Action');
    });

    test('DcvgDefectRecord priority scoring & polarity', () {
      final cathodicRecord = DcvgDefectRecord(
        id: 'DF-01',
        chainageKm: 2.0,
        chainageStr: 'KP 2+000',
        latitude: 27.28,
        longitude: 95.32,
        deltaVDefectMv: 20.0,
        totalIrDropMv: 200.0, // 10% IR -> Cat 1
        polarity: GradientPolarity.cathodic,
        orientationClock: '12 o\'clock (Crown)',
        estimatedDefectAreaCm2: 5.0,
        soilCondition: 'Sandy Silt',
        detectedDate: DateTime.now(),
        surveyorName: 'Tester',
        excavationStatus: ExcavationStatus.pendingReview,
        notes: 'Pinhole holiday',
      );

      expect(cathodicRecord.percentIr, equals(10.0));
      expect(cathodicRecord.category, DcvgDefectCategory.category1);
      expect(cathodicRecord.ecdaPriorityScore, equals(10.0));

      final anodicCriticalRecord = DcvgDefectRecord(
        id: 'DF-02',
        chainageKm: 3.45,
        chainageStr: 'KP 3+450',
        latitude: 27.29,
        longitude: 95.33,
        deltaVDefectMv: 140.0,
        totalIrDropMv: 175.0, // 80% IR -> Cat 4
        polarity: GradientPolarity.anodic, // +25 penalty
        orientationClock: '6 o\'clock (Invert)', // +10 penalty
        estimatedDefectAreaCm2: 60.0,
        soilCondition: 'Saline Clay',
        detectedDate: DateTime.now(),
        surveyorName: 'Tester',
        excavationStatus: ExcavationStatus.inExcavation,
        notes: 'Critical holiday',
      );

      expect(anodicCriticalRecord.percentIr, equals(80.0));
      expect(anodicCriticalRecord.category, DcvgDefectCategory.category4);
      // 80.0 + 25.0 + 10.0 = 115 clamped to 100.0
      expect(anodicCriticalRecord.ecdaPriorityScore, equals(100.0));
    });
  });

  group('CIPS Pipe-to-Soil & NACE SP0169 Polarized Criteria Tests', () {
    test('NACE SP0169 -850 mV CSE criterion check', () {
      // E_off <= -850 mV is compliant (e.g. -950 mV is more negative than -850 mV)
      expect(CipsSurveyPoint.isNace850Compliant(-950.0), isTrue);
      expect(CipsSurveyPoint.isNace850Compliant(-850.0), isTrue);
      expect(CipsSurveyPoint.isNace850Compliant(-1150.0), isTrue);

      // Under-protected: E_off > -850 mV (e.g. -810 mV, -750 mV)
      expect(CipsSurveyPoint.isNace850Compliant(-810.0), isFalse);
      expect(CipsSurveyPoint.isNace850Compliant(-700.0), isFalse);

      // Over-protected: E_off < -1200 mV (e.g. -1250 mV)
      expect(CipsSurveyPoint.isNace850Compliant(-1250.0), isFalse);
    });

    test('100 mV Cathodic Polarization Decay Criterion check', () {
      // Native = -560 mV, InstantOff = -780 mV -> Decay = 220 mV >= 100 mV
      final decay1 = CipsSurveyPoint.calculatePolarizationDecay(-780.0, -560.0);
      expect(decay1, equals(220.0));
      expect(CipsSurveyPoint.is100MvDecayCompliant(decay1), isTrue);

      // Native = -600 mV, InstantOff = -650 mV -> Decay = 50 mV < 100 mV
      final decay2 = CipsSurveyPoint.calculatePolarizationDecay(-650.0, -600.0);
      expect(decay2, equals(50.0));
      expect(CipsSurveyPoint.is100MvDecayCompliant(decay2), isFalse);
    });

    test('CipsSurveyPoint complianceStatus evaluation', () {
      final compliantPoint = CipsSurveyPoint(
        id: 'C-01',
        chainageKm: 1.0,
        chainageStr: 'KP 1+000',
        latitude: 27.28,
        longitude: 95.32,
        onPotentialMv: -1250,
        instantOffMv: -1050,
        nativePotentialMv: -560,
        polarizationDecayMv: 490,
        soilResistivityOhmM: 40.0,
        soilTerrain: 'Silt',
        landmark: 'TLP-01',
        timestamp: DateTime.now(),
      );

      expect(compliantPoint.irDropMv, equals(200.0));
      expect(compliantPoint.complianceStatus, CipsComplianceStatus.compliant);

      final underProtectedPoint = CipsSurveyPoint(
        id: 'C-02',
        chainageKm: 3.45,
        chainageStr: 'KP 3+450',
        latitude: 27.29,
        longitude: 95.33,
        onPotentialMv: -900,
        instantOffMv: -810, // Under -850 mV!
        nativePotentialMv: -750, // Only 60 mV decay
        polarizationDecayMv: 60,
        soilResistivityOhmM: 14.0,
        soilTerrain: 'Clay',
        landmark: 'Depression',
        timestamp: DateTime.now(),
      );

      expect(underProtectedPoint.irDropMv, equals(90.0));
      expect(underProtectedPoint.complianceStatus, CipsComplianceStatus.underProtected);

      final decayOnlyPoint = CipsSurveyPoint(
        id: 'C-03',
        chainageKm: 6.9,
        chainageStr: 'KP 6+900',
        latitude: 27.31,
        longitude: 95.35,
        onPotentialMv: -1020,
        instantOffMv: -835, // > -850 mV
        nativePotentialMv: -590, // decay = 245 mV >= 100 mV
        polarizationDecayMv: 245,
        soilResistivityOhmM: 18.0,
        soilTerrain: 'Swale',
        landmark: 'Anomalous swale',
        timestamp: DateTime.now(),
      );

      expect(decayOnlyPoint.complianceStatus, CipsComplianceStatus.decayCompliant);

      final overProtectedPoint = CipsSurveyPoint(
        id: 'C-04',
        chainageKm: 0.1,
        chainageStr: 'KP 0+100',
        latitude: 27.28,
        longitude: 95.31,
        onPotentialMv: -1450,
        instantOffMv: -1280, // < -1200 mV
        nativePotentialMv: -550,
        polarizationDecayMv: 730,
        soilResistivityOhmM: 30.0,
        soilTerrain: 'TRU yard',
        landmark: 'Header',
        timestamp: DateTime.now(),
      );

      expect(overProtectedPoint.complianceStatus, CipsComplianceStatus.overProtected);
    });

    test('BellHoleExamination wall loss percentage calculation', () {
      const bh = BellHoleExamination(
        defectId: 'DCVG-DF-03',
        chainageStr: 'KP 3+450',
        pitDepthMm: 2.1,
        nominalWallThicknessMm: 10.0,
        remainingWallThicknessMm: 7.9,
        soilPh: 5.8,
        coatingCondition: 'Torn 3LPE',
        microbesDetectedSrb: true,
        actionTaken: 'Patch applied',
      );

      // (10.0 - 7.9) / 10.0 * 100 = 21.0%
      expect(bh.wallLossPercentage, closeTo(21.0, 0.01));
    });
  });

  group('CipsDcvgScreen Flutter Widget Tests', () {
    testWidgets('Renders CipsDcvgScreen with AppBar, Telemetry banner & tabs', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CipsDcvgScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar and Header Badge
      expect(find.text('CIPS & DCVG Integrity Survey'), findsOneWidget);
      expect(find.text('NACE ECDA'), findsOneWidget);

      // Verify Telemetry top banner
      expect(find.textContaining('GPS SYNC 0.8s ON / 0.2s OFF'), findsOneWidget);
      expect(find.textContaining('Wire: 3450m'), findsOneWidget);

      // Verify Tab items
      expect(find.text('CIPS Profile'), findsOneWidget);
      expect(find.text('DCVG Defects (%IR)'), findsOneWidget);
      expect(find.text('ECDA Triangulation'), findsOneWidget);
      expect(find.text('%IR & Decay Solver'), findsOneWidget);
      expect(find.text('Compliance & Audit'), findsOneWidget);

      // Verify KPI Metric Cards on Tab 1
      expect(find.text('NACE SP0169 COMPLIANCE'), findsOneWidget);
      expect(find.text('INTERRUPTER CYCLE'), findsOneWidget);
      expect(find.text('CRITERIA THRESHOLD'), findsOneWidget);

      // Verify Potential Profile title
      expect(find.text('Pipe-to-Soil Potential Profile (CIPS)'), findsOneWidget);

      // Verify FAB
      expect(find.text('Log Survey Point'), findsOneWidget);
    });

    testWidgets('Switches to DCVG Defects (%IR) Tab and renders categories', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CipsDcvgScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on DCVG Defects tab
      final dcvgTab = find.text('DCVG Defects (%IR)');
      expect(dcvgTab, findsOneWidget);
      await tester.tap(dcvgTab);
      await tester.pumpAndSettle();

      // Verify DCVG Header & Categories
      expect(find.text('NACE SP0207 Coating Defect Severity Classification'), findsOneWidget);
      expect(find.text('Cat 1 (<15% IR)'), findsWidgets);
      expect(find.text('Cat 2 (15-35% IR)'), findsWidgets);
      expect(find.text('Cat 3 (35-70% IR)'), findsWidgets);
      expect(find.text('Cat 4 (>70% IR)'), findsWidgets);

      // Verify Defect IDs in list
      expect(find.text('DCVG-DF-01'), findsOneWidget);
      expect(find.text('DCVG-DF-03'), findsOneWidget);
    });

    testWidgets('Switches to ECDA Triangulation Tab and renders Bell-Hole NDT', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CipsDcvgScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on ECDA Triangulation tab
      final ecdaTab = find.text('ECDA Triangulation');
      await tester.tap(ecdaTab);
      await tester.pumpAndSettle();

      // Verify Triangulation & Bell-Hole
      expect(find.text('CIPS vs DCVG Triangulation Ranking'), findsOneWidget);
      expect(find.text('Zone 1: Active Cell'), findsOneWidget);
      expect(find.text('Bell-Hole Direct Examination Log (NDT)'), findsOneWidget);
      expect(find.textContaining('DCVG-DF-03 (KP 3+450)'), findsOneWidget);
    });

    testWidgets('Switches to %IR & Decay Solver Tab and verifies interactive tools', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CipsDcvgScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on %IR & Decay Solver tab
      final solverTab = find.text('%IR & Decay Solver');
      await tester.tap(solverTab);
      await tester.pumpAndSettle();

      expect(find.text('DCVG Defect %IR Calculator'), findsOneWidget);
      expect(find.text('100 mV Polarization Decay Evaluator'), findsOneWidget);
      expect(find.text('GPS Interrupter Switching Waveform'), findsOneWidget);
      expect(find.text('0.8s ON / 0.2s OFF'), findsOneWidget);
    });

    testWidgets('Switches to Compliance & Audit Tab and verifies standards checklist', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CipsDcvgScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Compliance & Audit tab
      final auditTab = find.text('Compliance & Audit');
      await tester.tap(auditTab);
      await tester.pumpAndSettle();

      expect(find.text('ECDA Indirect Inspection Certificate'), findsOneWidget);
      expect(find.text('NACE TM0497-2018'), findsOneWidget);
      expect(find.text('NACE SP0207-2007'), findsOneWidget);
      expect(find.text('NACE SP0169-2013'), findsOneWidget);
      expect(find.text('NACE SP0502-2010'), findsOneWidget);
      expect(find.text('OISD-STD-141'), findsOneWidget);
    });

    testWidgets('Tapping FAB opens Log Field Measurement modal sheet', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CipsDcvgScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap FAB
      final fab = find.text('Log Survey Point');
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify bottom sheet contents
      expect(find.text('Record Field Measurement'), findsOneWidget);
      expect(find.text('Log CIPS Potential Interval'), findsOneWidget);
      expect(find.text('Log DCVG Coating Holiday'), findsOneWidget);
    });
  });
}
