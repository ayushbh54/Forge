import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/integrity/pipeline_pigging_screen.dart';

void main() {
  group('Pigging & ILI Domain Models Unit Tests', () {
    test('PigToolType extension attributes and speed envelopes', () {
      expect(PigToolType.foamSwab.displayName, 'Foam Swab & Batching Pig');
      expect(PigToolType.foamSwab.shortName, 'Foam Pig');
      expect(PigToolType.foamSwab.optimalMinSpeed, 1.5);
      expect(PigToolType.foamSwab.optimalMaxSpeed, 4.5);

      expect(PigToolType.mechanicalScraper.displayName, 'Wire Brush & Scraper Pig');
      expect(PigToolType.mechanicalScraper.shortName, 'Cleaning Pig');

      expect(PigToolType.caliperEgp.displayName, 'Geometric Caliper Tool (EGP)');
      expect(PigToolType.caliperEgp.shortName, 'Caliper Pig');

      expect(PigToolType.mflHighRes.displayName, 'Magnetic Flux Leakage (MFL)');
      expect(PigToolType.mflHighRes.shortName, 'MFL Tool');
      expect(PigToolType.mflHighRes.optimalMinSpeed, 1.5);
      expect(PigToolType.mflHighRes.optimalMaxSpeed, 3.0);

      expect(PigToolType.ultrasonicUt.displayName, 'Ultrasonic Phased Array (UT)');
      expect(PigToolType.ultrasonicUt.shortName, 'UT Tool');
      expect(PigToolType.ultrasonicUt.optimalMinSpeed, 0.5);
      expect(PigToolType.ultrasonicUt.optimalMaxSpeed, 1.5);
    });

    test('PigRunStatus labels and colors', () {
      expect(PigRunStatus.inRun.label, 'IN-LINE ACTIVE');
      expect(PigRunStatus.scheduled.label, 'SCHEDULED');
      expect(PigRunStatus.completed.label, 'COMPLETED');
      expect(PigRunStatus.standby.label, 'STANDBY');
      expect(PigRunStatus.aborted.label, 'ABORTED');
    });

    test('PofMorphology and WallSurface classifications', () {
      expect(PofMorphology.pinhole.code, contains('POF-PIN'));
      expect(PofMorphology.pitting.code, contains('POF-PIT'));
      expect(PofMorphology.generalMetalLoss.code, contains('POF-GEN'));
      expect(PofMorphology.plainDent.label, 'Plain Geometric Dent');
      expect(PofMorphology.gougedDent.label, 'Critical Dent with Gouge');

      expect(WallSurface.internal.label, 'INTERNAL (ID)');
      expect(WallSurface.external.label, 'EXTERNAL (OD)');
      expect(WallSurface.midWall.label, 'MID-WALL');
    });

    test('PofAnomalyRecord Modified B31G calculations & severity', () {
      // Mild defect: 15% depth, safe pressure high -> safe severity
      const mildAnomaly = PofAnomalyRecord(
        id: 'ANO-TEST-SAFE',
        chainageKm: 12.5,
        chainageStr: 'KP 12+500',
        spoolId: 'SP-100',
        upstreamGirthWeld: 'GW-100',
        distFromWeldMeters: 4.2,
        wallSurface: WallSurface.external,
        morphology: PofMorphology.pitting,
        depthMm: 1.42, // ~14.9% of 9.52
        nominalThicknessMm: 9.52,
        lengthMm: 45.0,
        widthMm: 22.0,
        clockHour: 3,
        clockMinute: 30,
        pipeOdMm: 457.2,
        designPressureBar: 98.0,
        maopBar: 88.2,
        jointDefectId: 'JD-01',
        repairRecommendation: 'No action required',
      );

      expect(mildAnomaly.clockOrientationStr, "03:30 o'clock");
      expect(mildAnomaly.depthPct, closeTo(14.91, 0.1));
      expect(mildAnomaly.foliasM, greaterThan(1.0));
      expect(mildAnomaly.safePressureBar, greaterThan(88.2));
      expect(mildAnomaly.erf, lessThan(1.0));
      expect(mildAnomaly.severity, ErfSeverity.safe);

      // Severe defect: 82% depth -> critical (>80% WT) -> actionRequired
      const severeAnomaly = PofAnomalyRecord(
        id: 'ANO-TEST-CRITICAL',
        chainageKm: 25.0,
        chainageStr: 'KP 25+000',
        spoolId: 'SP-200',
        upstreamGirthWeld: 'GW-200',
        distFromWeldMeters: 2.1,
        wallSurface: WallSurface.internal,
        morphology: PofMorphology.generalMetalLoss,
        depthMm: 7.80, // > 80% WT
        nominalThicknessMm: 9.52,
        lengthMm: 150.0,
        widthMm: 80.0,
        clockHour: 6,
        clockMinute: 0,
        pipeOdMm: 457.2,
        designPressureBar: 98.0,
        maopBar: 88.2,
        jointDefectId: 'JD-02',
        repairRecommendation: 'Immediate B-sleeve repair',
      );

      expect(severeAnomaly.depthPct, greaterThan(80.0));
      expect(severeAnomaly.safePressureBar, 0.0);
      expect(severeAnomaly.erf, 2.50);
      expect(severeAnomaly.severity, ErfSeverity.actionRequired);
    });
  });

  group('PipelinePiggingScreen Widget Tests', () {
    testWidgets('PipelinePiggingScreen mounts, renders tabs and interactive dialogs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: PipelinePiggingScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify AppBar Title & Subtitle
      expect(find.text('Intelligent Pipeline Pigging & ILI'), findsOneWidget);
      expect(
        find.textContaining('OIL 18" Trunkline | PL-01 Duliajan ➔ PR-01 Digboi'),
        findsOneWidget,
      );

      // 2. Verify 5 Tab Headers
      expect(find.text('Live Tracking & ETA'), findsOneWidget);
      expect(find.text('Barrels & Telemetry'), findsOneWidget);
      expect(find.text('Pig Fleet (5 Tools)'), findsOneWidget);
      expect(find.text('POF Anomaly Clock'), findsOneWidget);
      expect(find.text('ASME B31G Sizing'), findsOneWidget);

      // 3. Tab 1: Live Tracking & ETA widgets
      expect(find.text('Pig Tracking Velocity & Hydraulics Engine'), findsOneWidget);
      expect(find.text('v = Q / A (m/s)'), findsOneWidget);
      expect(find.text('Tool Velocity (v)'), findsOneWidget);
      expect(find.textContaining('Remaining:'), findsWidgets);

      // 4. Switch to Tab 2: Barrels & Telemetry
      await tester.tap(find.text('Barrels & Telemetry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.textContaining('PL-01 Duliajan'), findsWidgets);
      expect(find.textContaining('PR-01 Digboi'), findsWidgets);
      expect(find.text('Barrel Pressure'), findsWidgets);
      expect(find.text('Mainline Pressure'), findsWidgets);

      // 5. Switch to Tab 3: Pig Fleet (5 Tools)
      await tester.tap(find.text('Pig Fleet (5 Tools)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('AquaFoam Heavy Swab 18"'), findsOneWidget);
      expect(find.text('MagnoScrape HD Wire Brush 18"'), findsOneWidget);
      expect(find.text('GeoScan-36 High-Res Caliper EGP'), findsOneWidget);
      expect(find.text('MFL-Max Tri-Axial Ultra 18"'), findsOneWidget);
      expect(find.text('UltraScan Duo Phased Array UT'), findsOneWidget);

      // 6. Switch to Tab 4: POF Anomaly Clock
      await tester.tap(find.text('POF Anomaly Clock'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.textContaining('All Anomalies'), findsWidgets);
      expect(find.text('Action Required (ERF>1)'), findsWidgets);
      expect(find.text('Internal ID Flaws'), findsWidgets);
      expect(find.text('External OD Flaws'), findsWidgets);

      // 7. Switch to Tab 5: ASME B31G Sizing
      await tester.tap(find.text('ASME B31G Sizing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Interactive ASME B31G & Modified B31G Engine'), findsOneWidget);
      expect(find.text('DEFECT GEOMETRY & SIZING INPUTS'), findsOneWidget);
      expect(find.textContaining('Defect Depth (d):'), findsOneWidget);
      expect(find.textContaining('Defect Axial Length (L):'), findsOneWidget);

      // 8. Open Launch Sequence Protocol Dialog
      final launchButton = find.byTooltip('Launch Sequence Protocol');
      expect(launchButton, findsOneWidget);
      await tester.tap(launchButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pig Launcher Sequence (PL-01)'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 9. Open Export ILI Inspection Dossier Dialog
      final exportButton = find.byTooltip('Export ILI Inspection Dossier');
      expect(exportButton, findsOneWidget);
      await tester.tap(exportButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ILI Inspection Dossier'), findsOneWidget);
      expect(find.textContaining('SHA-256'), findsWidgets);
      expect(find.text('Dismiss'), findsOneWidget);
      await tester.tap(find.text('Dismiss'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Clean disposal to cancel periodic timer
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
