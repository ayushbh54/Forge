import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/screens/integrity/field_joint_coating_screen.dart';

void main() {
  group('Field Joint Coating (FJC) Domain Models & Physics Unit Tests', () {
    test('CoatingSystemType specifications & temperature windows', () {
      expect(CoatingSystemType.hssMastic.nominalTotalDftMm, 2.80);
      expect(CoatingSystemType.hssMastic.minOverlapMm, 50.0);
      expect(CoatingSystemType.hssMastic.targetPreheatMinC, 200.0);
      expect(CoatingSystemType.hssMastic.targetPreheatMaxC, 230.0);

      expect(CoatingSystemType.threeLpe.nominalTotalDftMm, 3.00);
      expect(CoatingSystemType.threeLpe.minOverlapMm, 50.0);
      expect(CoatingSystemType.threeLpe.targetPreheatMinC, 210.0);
      expect(CoatingSystemType.threeLpe.targetPreheatMaxC, 235.0);

      expect(CoatingSystemType.viscoElastic.minOverlapMm, 75.0);
      expect(CoatingSystemType.liquidEpoxy100.nominalTotalDftMm, 1.25);
    });

    test('SurfacePreparationStandard classifications', () {
      expect(SurfacePreparationStandard.iso8501Sa2_5.shortCode, 'Sa 2.5');
      expect(SurfacePreparationStandard.iso8501Sa2_5.isApprovedForBuriedPipe, isTrue);
      expect(SurfacePreparationStandard.iso8501Sa3.shortCode, 'Sa 3.0');
      expect(SurfacePreparationStandard.iso8501Sa3.isApprovedForBuriedPipe, isTrue);
      expect(SurfacePreparationStandard.iso8501St3.isApprovedForBuriedPipe, isFalse);
    });

    test('JointQaStatus labels, colors and pipeline step progression', () {
      expect(JointQaStatus.prepPending.stageStep, 1);
      expect(JointQaStatus.preheating.stageStep, 2);
      expect(JointQaStatus.coated.stageStep, 3);
      expect(JointQaStatus.holidayTesting.stageStep, 4);
      expect(JointQaStatus.peelTesting.stageStep, 5);
      expect(JointQaStatus.fullyCertified.stageStep, 6);

      expect(JointQaStatus.fullyCertified.label, contains('CERTIFIED'));
      expect(JointQaStatus.holidayDefect.label, contains('DEFECT'));
    });

    test('PeelFailureMode DIN 30670 acceptance criteria', () {
      expect(PeelFailureMode.cohesiveMastic.isAcceptable, isTrue);
      expect(PeelFailureMode.cohesivePrimer.isAcceptable, isTrue);
      expect(PeelFailureMode.adhesiveSteel.isAcceptable, isFalse);
      expect(PeelFailureMode.intercoatBacking.isAcceptable, isFalse);
    });

    test('FieldJointRecord surface prep, psychrometry & anchor profile compliance', () {
      final compliantJoint = kMockFieldJoints.first; // FJ-18-042

      expect(compliantJoint.meanProfileDepthUm, closeTo(64.12, 0.5));
      expect(compliantJoint.isProfileCompliant, isTrue); // 50 to 75 µm
      expect(compliantJoint.isBresleCompliant, isTrue); // < 2.0 µg/cm²
      expect(compliantJoint.isPsychrometryCompliant, isTrue); // Ts >= Td + 3°C, RH <= 85%

      // Test out-of-spec profile (e.g. 42 µm under-blasted)
      final underblastedJoint = FieldJointRecord(
        id: 'FJ-TEST-UNDERBLAST',
        weldNumber: 'GW-TEST',
        chainageKm: 1.0,
        chainageStr: 'KP 1+000',
        spoolAhead: 'SP-1',
        spoolBack: 'SP-0',
        pipeOdMm: 457.2,
        wallThicknessMm: 9.52,
        steelGrade: 'API 5L X70',
        coatingSystem: CoatingSystemType.hssMastic,
        contractor: 'Contractor',
        inspectorName: 'Inspector',
        tpiInspector: 'TPI',
        status: JointQaStatus.prepPending,
        blastStandard: SurfacePreparationStandard.iso8501Sa2_5,
        blastMedium: 'Grit',
        ambientTempC: 30.0,
        relativeHumidityPct: 90.0, // High RH
        dewPointC: 28.5,
        pipeSurfaceTempC: 30.0, // Only 1.5°C above dew point (requires >= 3°C)
        profileDepthUmClock: const {'12:00': 42.0, '3:00': 40.0, '6:00': 45.0, '9:00': 41.0},
        bresleConductivityInitialUs: 2.0,
        bresleConductivityFinalUs: 35.0,
        bresleSaltDensityUgCm2: 2.85, // > 2.0 µg/cm² (FAIL)
        dustTapeClass: 3,
        inductionCoilPowerKw: 80.0,
        inductionFrequencyKhz: 3.5,
        heatingDurationSec: 40,
        pyrometerTempClockC: const {'12:00': 180.0, '3:00': 190.0, '6:00': 175.0, '9:00': 185.0},
        preheatVerified: false,
        epoxyBatchNumber: 'EP-0',
        sleeveBatchNumber: 'HSS-0',
        primerWftUm: 150.0,
        primerDftUm: 80.0,
        sleeveOverlapMmAhead: 35.0, // < 50 mm (FAIL)
        sleeveOverlapMmBack: 40.0,
        totalDftMmClock: const {},
        masticExtrusionVisual: false,
        holidayTestVoltageKv: 20.0,
        sparkDetectorModel: 'Spy',
        holidaysDetected: 1,
        holidayRecords: const [],
        holidayTestedPassed: false,
        peelTested: false,
        peelTestTempC: 23.0,
        peelStripWidthMm: 25.0,
        peelRateMmPerMin: 10.0,
        peelMeanForceNPerCm: 75.0, // < 100 N/cm
        peelPeakForceNPerCm: 90.0,
        peelMinForceNPerCm: 60.0,
        peelFailureMode: PeelFailureMode.adhesiveSteel,
        peelDisplacementLoads: const [],
        tpiWitnessed: false,
        inspectionDate: DateTime.now(),
        dossierHashSha256: 'HASH',
        loweringReleasePermitNo: 'HOLD',
      );

      expect(underblastedJoint.isProfileCompliant, isFalse);
      expect(underblastedJoint.isBresleCompliant, isFalse);
      expect(underblastedJoint.isPsychrometryCompliant, isFalse);
      expect(underblastedJoint.isPreheatCompliant, isFalse);
      expect(underblastedJoint.isOverlapCompliant, isFalse);
      expect(underblastedJoint.isZeroDefectCertified, isFalse);
    });

    test('Induction preheating 200°C - 230°C and delta <= 15°C check', () {
      final j = kMockFieldJoints.first;
      expect(j.meanPreheatTempC, greaterThanOrEqualTo(200.0));
      expect(j.meanPreheatTempC, lessThanOrEqualTo(230.0));
      expect(j.preheatDeltaC, lessThanOrEqualTo(15.0));
      expect(j.isPreheatCompliant, isTrue);
    });

    test('HV Holiday 5 kV/mm rule and zero-defect rule', () {
      final j = kMockFieldJoints.first;
      expect(j.meanTotalDftMm, greaterThan(2.5));
      expect(j.calculatedHolidayVoltageKv, closeTo(14.1, 1.0));
      expect(j.isHolidayCompliant, isTrue);
      expect(j.hasActiveHolidays, isFalse);

      final defectiveJoint = kMockFieldJoints.firstWhere((item) => item.id == 'FJ-18-044');
      expect(defectiveJoint.holidaysDetected, 1);
      expect(defectiveJoint.holidayTestedPassed, isFalse);
      expect(defectiveJoint.isZeroDefectCertified, isFalse);
    });

    test('DIN 30670 peel strength > 100 N/cm adhesion validation', () {
      final j = kMockFieldJoints.first;
      expect(j.peelTested, isTrue);
      expect(j.peelMeanForceNPerCm, greaterThan(100.0));
      expect(j.peelFailureMode, PeelFailureMode.cohesiveMastic);
      expect(j.isPeelCompliant, isTrue);
    });

    test('SHA-256 QA certificate hash generation', () {
      final hash1 = FieldJointRecord.generateCertificateHash('FJ-01', 'GW-01', 12.5, 145.0, 0);
      final hash2 = FieldJointRecord.generateCertificateHash('FJ-01', 'GW-01', 12.5, 145.0, 0);
      final hash3 = FieldJointRecord.generateCertificateHash('FJ-02', 'GW-02', 12.8, 145.0, 0);

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hash3)));
      expect(hash1.length, 64); // SHA-256 hex length
    });
  });

  group('Field Joint Coating Screen Widget Tests', () {
    testWidgets('Renders Field Joint Coating screen with tabs, metrics and joint list',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const FieldJointCoatingScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify App Bar and Header Badges
      expect(find.text('Field Joint Coating & Holiday QA'), findsOneWidget);
      expect(find.textContaining('NACE SP0188'), findsWidgets);
      expect(find.textContaining('DIN 30670'), findsWidgets);
      expect(find.textContaining('ISO 21809-3'), findsWidgets);

      // 2. Verify KPI Metric Summary Cards
      expect(find.text('TOTAL JOINTS'), findsOneWidget);
      expect(find.text('ZERO-DEFECT PASS'), findsOneWidget);
      expect(find.text('ACTIVE DEFECTS'), findsOneWidget);
      expect(find.text('AVG PEEL STRENGTH'), findsOneWidget);

      // 3. Verify Joint Register Tab Content
      expect(find.text('FJ-18-042'), findsWidgets);
      expect(find.text('GW-42'), findsWidgets);
      expect(find.text('KP 14+850'), findsWidgets);
      expect(find.textContaining('Blast Profile'), findsWidgets);
      expect(find.textContaining('Bresle Salt'), findsWidgets);
      expect(find.textContaining('Induction Temp'), findsWidgets);
      expect(find.textContaining('HV Holiday'), findsWidgets);

      // 4. Switch to Tab 2: Surface Prep & Bresle
      await tester.tap(find.text('Surface Prep & Bresle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Psychrometric Environmental Conditions'), findsOneWidget);
      expect(find.text('Anchor Profile Depth Gauge (ASTM D4417)'), findsOneWidget);
      expect(find.text('Bresle Patch Soluble Salt Extraction (ISO 8502-6 / 8502-9)'), findsOneWidget);
      expect(find.text('Ambient Air Temp'), findsOneWidget);
      expect(find.text('Dew Point (Td)'), findsOneWidget);

      // 5. Switch to Tab 3: Induction Heating
      await tester.tap(find.text('Induction Heating'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Medium-Frequency (MF) Induction Heating Coil'), findsOneWidget);
      expect(find.textContaining('Target Temperature Window: 200.0°C - 230.0°C'), findsOneWidget);
      expect(find.text('Coil Generator Power'), findsOneWidget);
      expect(find.text('Pyrometer Peak'), findsOneWidget);
      expect(find.text('Simulate Coil Heat'), findsOneWidget);

      // 6. Switch to Tab 4: Coating & DFT
      await tester.tap(find.text('Coating & DFT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Liquid Epoxy Primer WFT'), findsOneWidget);
      expect(find.text('Primer DFT'), findsOneWidget);
      expect(find.text('Mean Total Joint DFT'), findsOneWidget);
      expect(find.textContaining('Sleeve Overlap & Circumferential Recovery'), findsOneWidget);
      expect(find.text('Circumferential Mastic Extrusion Bead'), findsOneWidget);

      // 7. Switch to Tab 5: HV Holiday Lab
      await tester.tap(find.text('HV Holiday Lab'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('High-Voltage Continuous DC Holiday Testing'), findsOneWidget);
      expect(find.textContaining('NACE SP0188 / DIN 30670 Section 5.3.3'), findsOneWidget);
      expect(find.text('Continuous DC Voltage'), findsOneWidget);
      expect(find.text('Electrode Apparatus'), findsOneWidget);
      expect(find.text('Continuous DC Test Voltage Calculator (5 kV/mm Rule)'), findsOneWidget);
      expect(find.text('Pinhole Discontinuity & Repair Register'), findsOneWidget);

      // 8. Switch to Tab 6: DIN 30670 Peel Bench
      await tester.tap(find.text('DIN 30670 Peel Bench'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('90-Degree Peel Strength Adhesion Test Bench'), findsOneWidget);
      expect(find.textContaining('Requirement: > 100 N/cm at 23°C'), findsOneWidget);
      expect(find.text('Mean Peel Force'), findsOneWidget);
      expect(find.text('Peak Peel Force'), findsOneWidget);
      expect(find.text('Adhesion Failure Mode Classification'), findsOneWidget);

      // 9. Switch to Tab 7: QA Dossier & Sign-Off
      await tester.tap(find.text('QA Dossier & Sign-Off'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('PIPELINE TRENCH LOWERING RELEASE PERMIT'), findsOneWidget);
      expect(find.text('Comprehensive 5-Gate QA/QC Clearance Matrix'), findsOneWidget);
      expect(find.text('Multi-Party Digital Sign-Off & Verification'), findsOneWidget);
      expect(find.text('NACE CIP LEVEL 3 INSPECTOR'), findsOneWidget);
      expect(find.text('THIRD-PARTY INSPECTION (TPI)'), findsOneWidget);
      expect(find.text('AUTHORIZE LOWERING & SEAL IMMUTABLE QA RECORD'), findsOneWidget);

      // 10. Open Standards Dialog
      final infoButton = find.byTooltip('Standards & Tolerance Specifications');
      expect(infoButton, findsOneWidget);
      await tester.tap(infoButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Pipeline FJC Engineering Standards'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
      await tester.tap(find.text('Dismiss'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 11. Open Export FJC Inspection Dossier Modal
      final exportButton = find.byTooltip('Export FJC Inspection Dossier');
      expect(exportButton, findsOneWidget);
      await tester.tap(exportButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('FJC Inspection Dossier:'), findsOneWidget);
      expect(find.text('Export Digital QA PDF'), findsOneWidget);
      await tester.tap(find.text('Export Digital QA PDF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Clean teardown
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
