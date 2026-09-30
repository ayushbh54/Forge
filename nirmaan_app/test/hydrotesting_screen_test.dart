import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/quality/hydrotesting_screen.dart';

void main() {
  group('Hydrotesting Domain Models Unit Tests', () {
    test('HydroSectionIdExt returns correct codes and names', () {
      expect(HydroSectionId.ts01.code, 'TS-01');
      expect(HydroSectionId.ts02.code, 'TS-02');
      expect(HydroSectionId.ts03.code, 'TS-03');
      expect(HydroSectionId.ts04.code, 'TS-04');
      expect(HydroSectionId.ts05.code, 'TS-05');
      expect(HydroSectionId.ts06.code, 'TS-06');

      expect(HydroSectionId.ts01.sectionName, contains('Duliajan Dispatch'));
      expect(HydroSectionId.ts02.sectionName, contains('Burhi Dihing Crossing'));
      expect(HydroSectionId.ts06.sectionName, contains('Numaligarh Terminal'));
    });

    test('SectionPhaseExt labels and colors', () {
      expect(SectionPhase.waterFillingSoaking.label, 'Filling & Soaking');
      expect(SectionPhase.pvPlottingAirCheck.label, 'P/V Air Check');
      expect(SectionPhase.strengthTestHold.label, 'Strength Test (112.5 Bar)');
      expect(SectionPhase.leaktightness24Hr.label, '24-Hr Leak Test (90 Bar)');
      expect(SectionPhase.certifiedApproved.label, 'Certified & Endorsed');

      expect(SectionPhase.strengthTestHold.color, isA<Color>());
      expect(SectionPhase.certifiedApproved.color, isA<Color>());
      expect(SectionPhase.waterFillingSoaking.icon, isA<IconData>());
    });

    test('PipelineHydroSection calculated properties and compliance', () {
      final now = DateTime.now();
      final sectionCompliant = PipelineHydroSection(
        sectionId: HydroSectionId.ts01,
        startChainage: 'Ch 00+000',
        endChainage: 'Ch 14+850',
        lengthKm: 14.85,
        totalFillVolumeM3: 2190.3,
        staticHeadDiffBar: 2.15,
        testHeadLocation: 'Ch 00+000',
        receiverLocation: 'Ch 14+850',
        highPointCh: 'Ch 06+400',
        lowPointCh: 'Ch 11+200',
        currentPhase: SectionPhase.certifiedApproved,
        currentPressureBar: 90.0,
        deadweightReadingBar: 90.0,
        quartzGaugeABar: 90.0,
        quartzGaugeBBar: 90.0,
        rtdHeadTempC: 22.0,
        rtdMidTempC: 24.0,
        rtdTailTempC: 26.0,
        ambientTempC: 28.0,
        airVolumePercent: 0.15,
        currentDewPointC: -42.5,
        lastUpdated: now,
      );

      // Mean soil temperature: (22 + 24 + 26) / 3 = 24.0
      expect(sectionCompliant.meanSoilRtdTempC, closeTo(24.0, 0.001));
      expect(sectionCompliant.isAirVolumeCompliant, isTrue); // <= 0.20%
      expect(sectionCompliant.isDewPointCompliant, isTrue); // <= -40.0°C

      final sectionNonCompliant = PipelineHydroSection(
        sectionId: HydroSectionId.ts06,
        startChainage: 'Ch 78+900',
        endChainage: 'Ch 94+500',
        lengthKm: 15.60,
        totalFillVolumeM3: 2301.0,
        staticHeadDiffBar: 2.40,
        testHeadLocation: 'Ch 78+900',
        receiverLocation: 'Ch 94+500',
        highPointCh: 'Ch 85+200',
        lowPointCh: 'Ch 91+700',
        currentPhase: SectionPhase.waterFillingSoaking,
        currentPressureBar: 12.5,
        deadweightReadingBar: 12.5,
        quartzGaugeABar: 12.5,
        quartzGaugeBBar: 12.5,
        rtdHeadTempC: 25.0,
        rtdMidTempC: 25.0,
        rtdTailTempC: 25.0,
        ambientTempC: 30.0,
        airVolumePercent: 0.35,
        currentDewPointC: -20.0,
        lastUpdated: now,
      );

      expect(sectionNonCompliant.isAirVolumeCompliant, isFalse);
      expect(sectionNonCompliant.isDewPointCompliant, isFalse);
    });

    test('PigTypeExt title and DewateringPigRun weightGainPercent', () {
      expect(PigType.mechanicalScraper.title, contains('Mechanical Scraper'));
      expect(PigType.desiccantDrying.title, contains('Super-Dry'));

      const pigRun = DewateringPigRun(
        runId: 'PIG-01',
        type: PigType.foamSwabHigh,
        launchTime: '08:00',
        receiveTime: '11:00',
        distanceKm: 16.35,
        speedMps: 1.5,
        drivingPressureBar: 2.5,
        preRunWeightKg: 100.0,
        postRunWeightKg: 108.0,
        waterAbsorbedLiters: 8.0,
        cupWearPercent: 1.2,
        transmitterStatus: '22Hz OK',
        isPassed: true,
      );

      expect(pigRun.weightGainPercent, closeTo(8.0, 0.001));
    });
  });

  group('HydrotestingScreen Widget Tests', () {
    testWidgets('mounts, displays header badges and all 6 tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: HydrotestingScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Header Title & Standard Specification Badge
      expect(find.text('Pipeline Hydrotesting & Dewatering'), findsOneWidget);
      expect(find.text('ASME B31.8 / OISD-141'), findsWidgets);

      // Verify Tab titles
      expect(find.text('Sections & Overview'), findsOneWidget);
      expect(find.text('Strength & Leak Test'), findsOneWidget);
      expect(find.text('Temp & DWT Stabilize'), findsOneWidget);
      expect(find.text('P/V Plot (0.2% Air)'), findsOneWidget);
      expect(find.text('Dewater & -40°C Dry'), findsOneWidget);
      expect(find.text('Tripartite Cert'), findsOneWidget);

      // Verify Section Selection Chips (TS-01 through TS-06)
      expect(find.text('TS-01'), findsWidgets);
      expect(find.text('TS-02'), findsWidgets);
      expect(find.text('TS-03'), findsWidgets);

      // Switch to Strength & Leak Test tab
      await tester.tap(find.text('Strength & Leak Test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('112.5 Bar'), findsWidgets);

      // Switch to Temp & DWT Stabilize tab
      await tester.tap(find.text('Temp & DWT Stabilize'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Stabilization'), findsWidgets);

      // Switch to P/V Plot tab
      await tester.tap(find.text('P/V Plot (0.2% Air)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Air'), findsWidgets);

      // Switch to Dewater & -40°C Dry tab
      await tester.tap(find.text('Dewater & -40°C Dry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Dewatering'), findsWidgets);

      // Switch to Tripartite Cert tab
      await tester.tap(find.text('Tripartite Cert'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Tripartite'), findsWidgets);
    });

    testWidgets('can tap section selector chip and toggle dialogs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: HydrotestingScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on TS-01 section chip
      final ts01Chip = find.text('TS-01').first;
      await tester.tap(ts01Chip);
      await tester.pumpAndSettle();

      // Tap Export Dossier action button
      final exportButton = find.byTooltip('Export Hydrotest Dossier');
      expect(exportButton, findsOneWidget);
      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      // Verify Dossier dialog is open
      expect(find.textContaining('Hydrotest Dossier'), findsWidgets);

      // Close dialog
      final closeButton = find.text('Close');
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }
    });
  });
}
