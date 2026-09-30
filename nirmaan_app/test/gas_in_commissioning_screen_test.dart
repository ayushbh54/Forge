import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/operations/gas_in_commissioning_screen.dart';

void main() {
  group('Gas-In Commissioning Domain Models & Logic Tests', () {
    test('CommissioningStage properties and metadata', () {
      expect(CommissioningStage.airDisplacement.stepNumber, 1);
      expect(CommissioningStage.airDisplacement.shortTitle, 'Air Displacement');
      expect(CommissioningStage.airDisplacement.standardCode, 'OISD-141 Cl. 8.2');

      expect(CommissioningStage.nitrogenPurging.stepNumber, 2);
      expect(CommissioningStage.nitrogenPurging.shortTitle, 'N₂ Purging & Inerting');
      expect(CommissioningStage.nitrogenPurging.standardCode, 'ASME B31.8 / API 521');

      expect(CommissioningStage.hydrocarbonGasIn.stepNumber, 3);
      expect(CommissioningStage.hydrocarbonGasIn.shortTitle, 'Natural Gas-In');
      expect(CommissioningStage.hydrocarbonGasIn.standardCode, 'PNGRB T4S / OISD-141');

      expect(CommissioningStage.linepackPressurization.stepNumber, 4);
      expect(CommissioningStage.linepackPressurization.shortTitle, 'Linepack Pressurization');
      expect(CommissioningStage.linepackPressurization.standardCode, 'ASME B31.8 Ch. VIII');
    });

    test('StationGasSample compliance calculations', () {
      final compliantStation = StationGasSample(
        stationId: 'VS-01',
        stationName: 'Test Compliant Station',
        chainage: 'KP 0+000',
        chainageKm: 0.0,
        n2PurityPct: 99.5,
        oxygenResidualPct: 0.25,
        lelCombustiblePct: 0.01,
        dewPointC: -45.0,
        pressureBar: 4.5,
        sampleTapPoint: 'Tap 1',
        analyzerTag: 'TAG-01',
        testedBy: 'Tester',
        lastTestedTime: DateTime.now(),
      );

      expect(compliantStation.isN2Compliant, isTrue);
      expect(compliantStation.isO2Compliant, isTrue);
      expect(compliantStation.isLelCompliant, isTrue);
      expect(compliantStation.isDewPointCompliant, isTrue);
      expect(compliantStation.isFullyCompliant, isTrue);
      expect(compliantStation.statusBadgeText, 'COMPLIANT');

      final nonCompliantStation = StationGasSample(
        stationId: 'VS-08',
        stationName: 'Test Active Purge Station',
        chainage: 'KP 142+800',
        chainageKm: 142.8,
        n2PurityPct: 96.5, // < 98%
        oxygenResidualPct: 1.8, // > 1.0%
        lelCombustiblePct: 0.05,
        dewPointC: -36.0, // > -40.0
        pressureBar: 3.2,
        sampleTapPoint: 'Tap 8',
        analyzerTag: 'TAG-08',
        testedBy: 'Tester',
        lastTestedTime: DateTime.now(),
      );

      expect(nonCompliantStation.isN2Compliant, isFalse);
      expect(nonCompliantStation.isO2Compliant, isFalse);
      expect(nonCompliantStation.isDewPointCompliant, isFalse);
      expect(nonCompliantStation.isFullyCompliant, isFalse);
      expect(nonCompliantStation.statusBadgeText, 'PURGING ACTIVE');
    });

    test('FlareStackTelemetry safety calculations', () {
      final safeFlare = FlareStackTelemetry(
        unitId: 'FS-TEST',
        location: 'Numaligarh Terminal',
        stackHeightM: 45.0,
        pilotIgnitionActive: true,
        thermocoupleAC: 680.0,
        thermocoupleBC: 675.0,
        coldVentVelocityMach: 0.12,
        ventMassFlowNm3h: 3500.0,
        soundLevelDba: 75.0,
        soundDistanceM: 50.0,
        exclusionZoneRadiusM: 150.0,
        exclusionZoneClear: true,
        radiationAtBoundaryKwM2: 1.2,
        radiationPeak50mKwM2: 4.0,
        windSpeedKmh: 10.0,
        windDirection: 'ENE',
        nitrogenAssistFlowNm3h: 900.0,
        headerPressureMbar: 120.0,
      );

      expect(safeFlare.isMachSafe, isTrue);
      expect(safeFlare.isSoundSafe, isTrue);
      expect(safeFlare.isRadiationSafe, isTrue);
      expect(safeFlare.isPilotHealthy, isTrue);

      final unsafeFlare = FlareStackTelemetry(
        unitId: 'FS-UNSAFE',
        location: 'Test Unsafe',
        stackHeightM: 45.0,
        pilotIgnitionActive: false,
        thermocoupleAC: 450.0,
        thermocoupleBC: 420.0,
        coldVentVelocityMach: 0.25,
        ventMassFlowNm3h: 6000.0,
        soundLevelDba: 92.0,
        soundDistanceM: 50.0,
        exclusionZoneRadiusM: 150.0,
        exclusionZoneClear: false,
        radiationAtBoundaryKwM2: 2.1,
        radiationPeak50mKwM2: 5.8,
        windSpeedKmh: 25.0,
        windDirection: 'WNW',
        nitrogenAssistFlowNm3h: 500.0,
        headerPressureMbar: 220.0,
      );

      expect(unsafeFlare.isMachSafe, isFalse);
      expect(unsafeFlare.isSoundSafe, isFalse);
      expect(unsafeFlare.isRadiationSafe, isFalse);
      expect(unsafeFlare.isPilotHealthy, isFalse);
    });

    test('PressurizationHoldStep hold progress and status', () {
      final stepHolding = PressurizationHoldStep(
        stepIndex: 2,
        targetPressureBar: 30.0,
        title: 'Tier 2: 30 Bar Hold',
        requiredHoldHours: 6,
        elapsedHoldHours: 3.0,
        status: 'HOLDING',
        rateOfPressureChangeBarHr: 0.01,
        inspectedJointsCount: 71,
        totalJointsCount: 142,
        flirOgiCameraPassed: true,
        acousticUltrasonicDbuv: 15.0,
        acousticVerdict: 'Normal',
        notes: 'In progress',
      );

      expect(stepHolding.isHoldComplete, isFalse);
      expect(stepHolding.holdProgressPct, closeTo(0.5, 0.01));

      final stepCompleted = PressurizationHoldStep(
        stepIndex: 1,
        targetPressureBar: 10.0,
        title: 'Tier 1: 10 Bar Hold',
        requiredHoldHours: 4,
        elapsedHoldHours: 4.0,
        status: 'COMPLETED',
        rateOfPressureChangeBarHr: 0.005,
        inspectedJointsCount: 142,
        totalJointsCount: 142,
        flirOgiCameraPassed: true,
        acousticUltrasonicDbuv: 14.0,
        acousticVerdict: 'Pass',
        notes: 'Done',
      );

      expect(stepCompleted.isHoldComplete, isTrue);
      expect(stepCompleted.holdProgressPct, 1.0);
    });
  });

  group('GasInCommissioningScreen Widget Tests', () {
    testWidgets('mounts, renders tabs, switches views, and interacts with dialogs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: GasInCommissioningScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify AppBar and Pipeline Overview
      expect(find.text('Gas-In Commissioning'), findsOneWidget);
      expect(find.text('OISD-141'), findsOneWidget);
      expect(find.textContaining('OIL-DUL-NUM-DN600'), findsOneWidget);

      // 2. Verify Tab Headers
      expect(find.text('GAS SAMPLING MATRIX'), findsOneWidget);
      expect(find.text('FLARE & THERMAL'), findsOneWidget);
      expect(find.text('PRESSURIZATION & LEAK'), findsOneWidget);
      expect(find.text('TRIPARTITE SIGN-OFF'), findsOneWidget);

      // 3. Verify Stage Stepper Ribbon
      expect(find.text('Air Displacement'), findsOneWidget);
      expect(find.text('N₂ Purging & Inerting'), findsOneWidget);
      expect(find.text('Natural Gas-In'), findsOneWidget);
      expect(find.text('Linepack Pressurization'), findsOneWidget);
      expect(find.textContaining('Purge Front:'), findsOneWidget);

      // 4. Verify Tab 1: Atmospheric Gas Sampling Matrix
      expect(find.text('AVG N₂ PURITY'), findsOneWidget);
      expect(find.text('PEAK O₂ RESIDUAL'), findsOneWidget);
      expect(find.text('MIN DEW POINT'), findsOneWidget);
      expect(find.text('VS-01'), findsWidgets);
      expect(find.text('Duliajan Dispatch Terminal'), findsOneWidget);
      expect(find.text('VS-08'), findsWidgets);
      expect(find.text('Numaligarh Terminal Receiver'), findsOneWidget);

      // 5. Test Filter Chips in Tab 1
      final compliantFilter = find.textContaining('Compliant');
      if (compliantFilter.evaluate().isNotEmpty) {
        await tester.tap(compliantFilter.first);
        await tester.pumpAndSettle();
      }

      // 6. Switch to Tab 2: Flare & Thermal
      await tester.tap(find.text('FLARE & THERMAL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Flare Tip & Pilot Igniter (FS-01)'), findsOneWidget);
      expect(find.text('Thermocouple TC-01'), findsOneWidget);
      expect(find.text('Thermocouple TC-02'), findsOneWidget);
      expect(find.text('PILOT IGNITED'), findsOneWidget);
      expect(find.text('COLD VENT VELOCITY'), findsOneWidget);
      expect(find.text('SOUND LEVEL (dBA)'), findsOneWidget);
      expect(find.textContaining('THERMAL RADIATION PROFILE'), findsOneWidget);

      // 7. Switch to Tab 3: Pressurization & Leak
      await tester.tap(find.text('PRESSURIZATION & LEAK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Pipeline Linepack Pressure'), findsOneWidget);
      expect(find.textContaining('Design MAOP: 98.0 Bar'), findsOneWidget);
      expect(find.text('SOAK IN PROGRESS'), findsOneWidget);
      expect(find.text('Tier 1: 10.0 Bar(g) Low Pressure Hold'), findsOneWidget);
      expect(find.text('Tier 2: 30.0 Bar(g) Intermediate Hold & Soak'), findsOneWidget);
      expect(find.text('Tier 3: 60.0 Bar(g) High Pressure Soak'), findsOneWidget);
      expect(find.text('Tier 4: 90.0 Bar(g) MAOP Linepack Hold'), findsOneWidget);

      // 8. Switch to Tab 4: Tripartite Sign-Off
      await tester.tap(find.text('TRIPARTITE SIGN-OFF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('FORM COMM-OISD-141'), findsOneWidget);
      expect(find.text('Tripartite Statutory Commissioning Authorization'), findsOneWidget);
      expect(find.textContaining('Oil India Limited'), findsWidgets);
      expect(find.textContaining('Engineers India Limited'), findsWidgets);
      expect(find.textContaining('Directorate General of Hydrocarbons'), findsWidgets);
      expect(find.text('Er. Bhaskar Jyoti Phukan'), findsOneWidget);
      expect(find.text('Dr. A. K. Sengupta'), findsOneWidget);
      expect(find.text('Smt. Priyanka Baruah'), findsOneWidget);

      // Authenticate & Execute Sign-Off for CSO
      final authButton = find.text('AUTHENTICATE & EXECUTE SIGN-OFF');
      expect(authButton, findsOneWidget);
      await tester.tap(authButton);
      await tester.pumpAndSettle();

      expect(find.text('Execute Digital Sign-Off'), findsOneWidget);
      await tester.tap(find.text('SIGN & ATTEST'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Cryptographic sign-off executed'), findsOneWidget);

      // 9. Test Dossier Export Dialog
      final exportButton = find.byTooltip('Export Commissioning Dossier');
      expect(exportButton, findsOneWidget);
      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      expect(find.text('Commissioning Dossier Export'), findsOneWidget);
      expect(find.textContaining('OIL-DUL-NUM-DN600'), findsWidgets);
      expect(find.text('CLOSE'), findsOneWidget);
      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();

      // 10. Test SCADA Simulation Toggle
      final simToggle = find.byTooltip('Pause SCADA Sim');
      expect(simToggle, findsOneWidget);
      await tester.tap(simToggle);
      await tester.pump();

      expect(find.byTooltip('Resume SCADA Sim'), findsOneWidget);
    });
  });
}
