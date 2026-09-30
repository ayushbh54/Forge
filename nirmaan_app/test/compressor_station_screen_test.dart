import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/operations/compressor_station_screen.dart';

void main() {
  group('Compressor Station Domain Models & Telemetry Calculations', () {
    test('IsoVibrationZone zones, colors and labels', () {
      final probeA = VibrationProbeReading(
        tag: 'VT-101A',
        location: 'DE Bearing Radial X',
        axis: 'X-Radial',
        amplitudeUmPkPk: 18.2,
        baselineUmPkPk: 15.0,
      );
      expect(probeA.isoZone, IsoVibrationZone.zoneA);
      expect(probeA.zoneLabel, 'Zone A (Good)');
      expect(probeA.zoneColor, const Color(0xFF4EDEA3));

      final probeB = VibrationProbeReading(
        tag: 'VT-101B',
        location: 'DE Bearing Radial Y',
        axis: 'Y-Radial',
        amplitudeUmPkPk: 32.5,
        baselineUmPkPk: 25.0,
      );
      expect(probeB.isoZone, IsoVibrationZone.zoneB);
      expect(probeB.zoneLabel, 'Zone B (Acceptable)');
      expect(probeB.zoneColor, const Color(0xFF38BDF8));

      final probeC = VibrationProbeReading(
        tag: 'VT-102A',
        location: 'NDE Bearing Radial X',
        axis: 'X-Radial',
        amplitudeUmPkPk: 52.0,
        baselineUmPkPk: 30.0,
      );
      expect(probeC.isoZone, IsoVibrationZone.zoneC);
      expect(probeC.zoneLabel, 'Zone C (Alert)');
      expect(probeC.zoneColor, const Color(0xFFFFB95F));

      final probeD = VibrationProbeReading(
        tag: 'VT-102B',
        location: 'Thrust Collar Axial',
        axis: 'Axial-Thrust',
        amplitudeUmPkPk: 71.4,
        baselineUmPkPk: 35.0,
      );
      expect(probeD.isoZone, IsoVibrationZone.zoneD);
      expect(probeD.zoneLabel, 'Zone D (Trip Danger)');
      expect(probeD.zoneColor, const Color(0xFFEF4444));
    });

    test('Babbitt metal temperature sensor alarm and trip logic', () {
      final normalRtd = BabbittTempSensor(
        tag: 'TE-201',
        location: 'DE Journal Bearing',
        temperatureC: 78.5,
        alarmThresholdC: 95.0,
        tripThresholdC: 105.0,
      );
      expect(normalRtd.isAlarm, isFalse);
      expect(normalRtd.isTrip, isFalse);
      expect(normalRtd.statusColor, const Color(0xFF4EDEA3));

      final alarmRtd = BabbittTempSensor(
        tag: 'TE-202',
        location: 'NDE Journal Bearing',
        temperatureC: 98.2,
        alarmThresholdC: 95.0,
        tripThresholdC: 105.0,
      );
      expect(alarmRtd.isAlarm, isTrue);
      expect(alarmRtd.isTrip, isFalse);
      expect(alarmRtd.statusColor, const Color(0xFFFFB95F));

      final tripRtd = BabbittTempSensor(
        tag: 'TE-203',
        location: 'Active Thrust Pad',
        temperatureC: 108.6,
        alarmThresholdC: 95.0,
        tripThresholdC: 105.0,
      );
      expect(tripRtd.isAlarm, isTrue);
      expect(tripRtd.isTrip, isTrue);
      expect(tripRtd.statusColor, const Color(0xFFEF4444));
    });

    test('Dry gas seal (DGS) API 692 safe operating limits', () {
      final healthySeal = DryGasSealTelemetry(
        sealEnd: 'Drive End (DE)',
        bufferGasDifferentialPressureBar: 4.2,
        primaryVentPressureBar: 0.28,
        secondaryVentPressureBar: 0.04,
        primaryLeakageFlowNm3h: 5.8,
        nitrogenBarrierGasPressureBar: 2.1,
        sealGasSupplyTempC: 45.0,
        coalescingFilterDpBar: 0.18,
      );
      expect(healthySeal.isBufferPressureSafe, isTrue);
      expect(healthySeal.isPrimaryVentNormal, isTrue);
      expect(healthySeal.isPrimaryVentAlarm, isFalse);
      expect(healthySeal.isPrimaryVentTrip, isFalse);
      expect(healthySeal.isSecondaryVentNormal, isTrue);

      final degradedSeal = DryGasSealTelemetry(
        sealEnd: 'Non-Drive End (NDE)',
        bufferGasDifferentialPressureBar: 1.4,
        primaryVentPressureBar: 1.45,
        secondaryVentPressureBar: 0.38,
        primaryLeakageFlowNm3h: 22.0,
        nitrogenBarrierGasPressureBar: 1.6,
        sealGasSupplyTempC: 38.0,
        coalescingFilterDpBar: 0.65,
      );
      expect(degradedSeal.isBufferPressureSafe, isFalse);
      expect(degradedSeal.isPrimaryVentNormal, isFalse);
      expect(degradedSeal.isPrimaryVentAlarm, isTrue);
      expect(degradedSeal.isPrimaryVentTrip, isFalse);
      expect(degradedSeal.isSecondaryVentNormal, isFalse);

      final blownSeal = DryGasSealTelemetry(
        sealEnd: 'Drive End (DE)',
        bufferGasDifferentialPressureBar: 0.8,
        primaryVentPressureBar: 2.6,
        secondaryVentPressureBar: 0.85,
        primaryLeakageFlowNm3h: 48.0,
        nitrogenBarrierGasPressureBar: 1.2,
        sealGasSupplyTempC: 32.0,
        coalescingFilterDpBar: 0.90,
      );
      expect(blownSeal.isPrimaryVentTrip, isTrue);
    });

    test('Anti-Surge Controller data safety states and thresholds', () {
      final safeAsc = AntiSurgeControllerData(
        surgeMarginPct: 22.5,
        recycleValvePositionPct: 0.0,
        distanceToSurgeLine: 0.25,
      );
      expect(safeAsc.safetyStatus, AscSafetyStatus.safeZone);
      expect(safeAsc.statusText, 'STABLE ENVELOPE');
      expect(safeAsc.statusColor, const Color(0xFF4EDEA3));

      final sclApproachAsc = AntiSurgeControllerData(
        surgeMarginPct: 12.0,
        recycleValvePositionPct: 15.0,
        distanceToSurgeLine: 0.12,
      );
      expect(sclApproachAsc.safetyStatus, AscSafetyStatus.controlApproach);
      expect(sclApproachAsc.statusText, 'SCL APPROACH');
      expect(sclApproachAsc.statusColor, const Color(0xFFFFB95F));

      final fastRecycleAsc = AntiSurgeControllerData(
        surgeMarginPct: 7.5,
        recycleValvePositionPct: 58.0,
        distanceToSurgeLine: 0.06,
      );
      expect(fastRecycleAsc.safetyStatus, AscSafetyStatus.fastActingRecycle);
      expect(fastRecycleAsc.statusText, 'FAST RECYCLE OPEN');
      expect(fastRecycleAsc.statusColor, const Color(0xFFFF8A00));

      final surgeTripAsc = AntiSurgeControllerData(
        surgeMarginPct: 2.8,
        recycleValvePositionPct: 100.0,
        distanceToSurgeLine: 0.01,
      );
      expect(surgeTripAsc.safetyStatus, AscSafetyStatus.surgeTripWarning);
      expect(surgeTripAsc.statusText, 'SURGE TRIP IMMINENT');
      expect(surgeTripAsc.statusColor, const Color(0xFFEF4444));
    });

    test('BoosterPumpTelemetry differential head and NPSH margin', () {
      final pump = BoosterPumpTelemetry(
        tag: 'BP-101A',
        name: 'Condensate Booster Pump A',
        isRunning: true,
        suctionPressureBar: 4.5,
        dischargePressureBar: 18.2,
        flowRateM3h: 85.0,
        motorCurrentAmps: 62.4,
        motorWindingTempC: 72.0,
        casingVibrationMmS: 2.1,
        sealPlan53BPressureBar: 12.5,
        npshAvailableM: 5.8,
        npshRequiredM: 3.2,
      );
      // differential head = (18.2 - 4.5) * 10.197 = 13.7 * 10.197 ≈ 139.6989
      expect(pump.differentialHeadM, closeTo(139.7, 0.2));
      // NPSH margin = 5.8 - 3.2 = 2.6
      expect(pump.npshMarginM, closeTo(2.6, 0.01));
      expect(pump.isNpshSafe, isTrue);

      final cavitationPump = BoosterPumpTelemetry(
        tag: 'BP-101B',
        name: 'Condensate Booster Pump B',
        isRunning: true,
        suctionPressureBar: 1.2,
        dischargePressureBar: 12.0,
        flowRateM3h: 90.0,
        motorCurrentAmps: 70.0,
        motorWindingTempC: 85.0,
        casingVibrationMmS: 4.8,
        sealPlan53BPressureBar: 10.0,
        npshAvailableM: 3.5,
        npshRequiredM: 2.8,
      );
      // NPSH margin = 3.5 - 2.8 = 0.7 (< 1.5)
      expect(cavitationPump.npshMarginM, closeTo(0.7, 0.01));
      expect(cavitationPump.isNpshSafe, isFalse);
    });

    test('CompressorTrainTelemetry calculations and alarm checks', () {
      final train = CompressorTrainTelemetry(
        id: 'C-101',
        name: 'Centrifugal Train 1',
        stationId: 'CS-DULIAJAN',
        driverDescription: 'Solar Mars 100 Gas Turbine',
        ratedPowerKw: 11200,
        ratedSpeedRpm: 12200,
        maxContinuousSpeedRpm: 12800,
        tripSpeedRpm: 13420,
        stageCount: 2,
        status: TrainOperationalStatus.runningBaseLoad,
        runningHours: 12000.0,
        suctionPressureBar: 25.0,
        suctionTemperatureC: 28.0,
        interstagePressureBar: 48.0,
        interstageTemperatureC: 36.0,
        dischargePressureBar: 80.0,
        dischargeTemperatureC: 102.0,
        massFlowRateKgH: 52000.0,
        volumetricSuctionFlowM3h: 1450.0,
        shaftSpeedRpm: 11834.0,
        polytropicHeadKjKg: 78.0,
        polytropicEfficiencyPct: 85.0,
        driverPowerKw: 9500.0,
        turbineExhaustGasTempC: 512.0,
        fuelGasFlowSm3h: 2150.0,
        lubeOilHeaderPressureBar: 2.8,
        lubeOilSupplyTempC: 46.0,
        antiSurge: AntiSurgeControllerData(
          surgeMarginPct: 22.0,
          recycleValvePositionPct: 0.0,
          distanceToSurgeLine: 0.22,
        ),
        vibrationProbes: [
          VibrationProbeReading(
            tag: 'VT-101',
            location: 'DE Radial X',
            axis: 'X-Radial',
            amplitudeUmPkPk: 18.0,
            baselineUmPkPk: 15.0,
          ),
          VibrationProbeReading(
            tag: 'VT-102',
            location: 'NDE Radial Y',
            axis: 'Y-Radial',
            amplitudeUmPkPk: 22.4,
            baselineUmPkPk: 16.0,
          ),
        ],
        babbittTemps: [
          BabbittTempSensor(
            tag: 'TE-101',
            location: 'DE Bearing',
            temperatureC: 78.0,
          ),
        ],
        dgsDriveEnd: DryGasSealTelemetry(
          sealEnd: 'DE',
          bufferGasDifferentialPressureBar: 4.2,
          primaryVentPressureBar: 0.25,
          secondaryVentPressureBar: 0.04,
          primaryLeakageFlowNm3h: 6.0,
          nitrogenBarrierGasPressureBar: 2.2,
          sealGasSupplyTempC: 45.0,
          coalescingFilterDpBar: 0.2,
        ),
        dgsNonDriveEnd: DryGasSealTelemetry(
          sealEnd: 'NDE',
          bufferGasDifferentialPressureBar: 4.1,
          primaryVentPressureBar: 0.28,
          secondaryVentPressureBar: 0.05,
          primaryLeakageFlowNm3h: 6.5,
          nitrogenBarrierGasPressureBar: 2.2,
          sealGasSupplyTempC: 45.0,
          coalescingFilterDpBar: 0.2,
        ),
        suctionPressureTrend: const [FlSpot(0, 25.0)],
        dischargePressureTrend: const [FlSpot(0, 80.0)],
        flowTrend: const [FlSpot(0, 52000.0)],
        speedTrend: const [FlSpot(0, 11834.0)],
        surgeMarginTrend: const [FlSpot(0, 22.0)],
        vibrationTrend: const [FlSpot(0, 22.4)],
      );

      // Compression ratio = 80.0 / 25.0 = 3.2
      expect(train.compressionRatio, closeTo(3.2, 0.01));
      // Speed percentage = 11834 / 12200 * 100 ≈ 97.0%
      expect(train.speedPercentage, closeTo(97.0, 0.1));
      // Max vibration = 22.4
      expect(train.maxVibrationUm, 22.4);
      expect(train.overallVibrationZone, IsoVibrationZone.zoneA);
      expect(train.hasActiveAlarm, isFalse);
    });

    test('CompressorStationData stationCompressionRatio and runningTrainsCount', () {
      final station = CompressorStationData(
        id: 'CS-TEST',
        code: 'CS-01',
        name: 'Duliajan Compressor Station',
        chainage: 'KP 0.00',
        location: 'Duliajan, Assam',
        pipelineSegment: 'DNNPL-18',
        headerSuctionPressureBar: 24.0,
        headerSuctionTempC: 28.0,
        headerDischargePressureBar: 84.0,
        headerDischargeTempC: 98.0,
        stationTotalFlowKgH: 150000.0,
        stationTotalPowerMw: 28.5,
        stationFuelGasSm3h: 6400.0,
        trains: [
          CompressorTrainTelemetry(
            id: 'T-1',
            name: 'Train 1',
            stationId: 'CS-TEST',
            driverDescription: 'Turbine',
            ratedPowerKw: 11000,
            ratedSpeedRpm: 12000,
            maxContinuousSpeedRpm: 12500,
            tripSpeedRpm: 13000,
            stageCount: 2,
            status: TrainOperationalStatus.runningBaseLoad,
            runningHours: 5000,
            suctionPressureBar: 24,
            suctionTemperatureC: 28,
            interstagePressureBar: 48,
            interstageTemperatureC: 35,
            dischargePressureBar: 84,
            dischargeTemperatureC: 98,
            massFlowRateKgH: 75000,
            volumetricSuctionFlowM3h: 1400,
            shaftSpeedRpm: 11800,
            polytropicHeadKjKg: 78,
            polytropicEfficiencyPct: 85,
            driverPowerKw: 9500,
            turbineExhaustGasTempC: 500,
            fuelGasFlowSm3h: 2100,
            lubeOilHeaderPressureBar: 2.8,
            lubeOilSupplyTempC: 45,
            antiSurge: AntiSurgeControllerData(
              surgeMarginPct: 20,
              recycleValvePositionPct: 0,
              distanceToSurgeLine: 0.2,
            ),
            vibrationProbes: [],
            babbittTemps: [],
            dgsDriveEnd: DryGasSealTelemetry(
              sealEnd: 'DE',
              bufferGasDifferentialPressureBar: 4.0,
              primaryVentPressureBar: 0.3,
              secondaryVentPressureBar: 0.04,
              primaryLeakageFlowNm3h: 5.0,
              nitrogenBarrierGasPressureBar: 2.0,
              sealGasSupplyTempC: 45,
              coalescingFilterDpBar: 0.2,
            ),
            dgsNonDriveEnd: DryGasSealTelemetry(
              sealEnd: 'NDE',
              bufferGasDifferentialPressureBar: 4.0,
              primaryVentPressureBar: 0.3,
              secondaryVentPressureBar: 0.04,
              primaryLeakageFlowNm3h: 5.0,
              nitrogenBarrierGasPressureBar: 2.0,
              sealGasSupplyTempC: 45,
              coalescingFilterDpBar: 0.2,
            ),
            suctionPressureTrend: const [],
            dischargePressureTrend: const [],
            flowTrend: const [],
            speedTrend: const [],
            surgeMarginTrend: const [],
            vibrationTrend: const [],
          ),
          CompressorTrainTelemetry(
            id: 'T-2',
            name: 'Train 2',
            stationId: 'CS-TEST',
            driverDescription: 'Turbine',
            ratedPowerKw: 11000,
            ratedSpeedRpm: 12000,
            maxContinuousSpeedRpm: 12500,
            tripSpeedRpm: 13000,
            stageCount: 2,
            status: TrainOperationalStatus.hotStandby,
            runningHours: 4200,
            suctionPressureBar: 24,
            suctionTemperatureC: 28,
            interstagePressureBar: 48,
            interstageTemperatureC: 35,
            dischargePressureBar: 84,
            dischargeTemperatureC: 98,
            massFlowRateKgH: 0,
            volumetricSuctionFlowM3h: 0,
            shaftSpeedRpm: 0,
            polytropicHeadKjKg: 0,
            polytropicEfficiencyPct: 0,
            driverPowerKw: 0,
            turbineExhaustGasTempC: 0,
            fuelGasFlowSm3h: 0,
            lubeOilHeaderPressureBar: 2.8,
            lubeOilSupplyTempC: 45,
            antiSurge: AntiSurgeControllerData(
              surgeMarginPct: 50,
              recycleValvePositionPct: 0,
              distanceToSurgeLine: 0.5,
            ),
            vibrationProbes: [],
            babbittTemps: [],
            dgsDriveEnd: DryGasSealTelemetry(
              sealEnd: 'DE',
              bufferGasDifferentialPressureBar: 4.0,
              primaryVentPressureBar: 0.3,
              secondaryVentPressureBar: 0.04,
              primaryLeakageFlowNm3h: 5.0,
              nitrogenBarrierGasPressureBar: 2.0,
              sealGasSupplyTempC: 45,
              coalescingFilterDpBar: 0.2,
            ),
            dgsNonDriveEnd: DryGasSealTelemetry(
              sealEnd: 'NDE',
              bufferGasDifferentialPressureBar: 4.0,
              primaryVentPressureBar: 0.3,
              secondaryVentPressureBar: 0.04,
              primaryLeakageFlowNm3h: 5.0,
              nitrogenBarrierGasPressureBar: 2.0,
              sealGasSupplyTempC: 45,
              coalescingFilterDpBar: 0.2,
            ),
            suctionPressureTrend: const [],
            dischargePressureTrend: const [],
            flowTrend: const [],
            speedTrend: const [],
            surgeMarginTrend: const [],
            vibrationTrend: const [],
          ),
        ],
        boosterPumps: [],
      );

      // Station compression ratio: 84.0 / 24.0 = 3.5
      expect(station.stationCompressionRatio, closeTo(3.5, 0.01));
      // Only 1 running train (T-1 runningBaseLoad, T-2 hotStandby)
      expect(station.runningTrainsCount, 1);
    });
  });

  group('CompressorStationScreen Widget & Tab Navigation Tests', () {
    testWidgets('CompressorStationScreen renders app bar, tabs, and switches views',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: CompressorStationScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify App Bar Title and Subtitle
      expect(find.text('Compressor & Booster Station'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);

      // 2. Verify Tab labels exist
      expect(find.text('Station & Process P&ID'), findsOneWidget);
      expect(find.textContaining('Anti-Surge Control'), findsOneWidget);
      expect(find.textContaining('Vibration & Bearings'), findsOneWidget);
      expect(find.text('Dry Gas Seal (DGS)'), findsOneWidget);
      expect(find.text('Booster Pumps & ESD'), findsOneWidget);

      // 3. Verify Train selector chips (C-101, C-102, C-103)
      expect(find.text('C-101'), findsWidgets);
      expect(find.text('C-102'), findsWidgets);
      expect(find.text('C-103'), findsWidgets);

      // 4. Verify Process Overview Tab contents (Tab 1 default)
      expect(
        find.text('REAL-TIME THERMODYNAMIC & OPERATING PARAMETERS'),
        findsOneWidget,
      );

      // 5. Switch to Tab 2: Anti-Surge Control (ASC)
      await tester.tap(find.textContaining('Anti-Surge Control'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('ANTI-SURGE RECYCLE VALVE (ASV-101)'),
        findsOneWidget,
      );

      // 6. Switch to Tab 3: Vibration & Bearings (ISO)
      await tester.tap(find.textContaining('Vibration & Bearings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('BENTLY NEVADA 3500 EDDY CURRENT PROXIMITY PROBES'),
        findsOneWidget,
      );
      expect(
        find.text('BABBITT METAL BEARING TEMPERATURES (Pt100 RTD)'),
        findsOneWidget,
      );

      // 7. Switch to Tab 4: Dry Gas Seal (DGS)
      await tester.tap(find.text('Dry Gas Seal (DGS)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('DRIVE END (DE) DRY GAS SEAL CONSOLE'),
        findsOneWidget,
      );
      expect(
        find.text('NON-DRIVE END (NDE) DRY GAS SEAL CONSOLE'),
        findsOneWidget,
      );

      // 8. Switch to Tab 5: Booster Pumps & ESD
      await tester.tap(find.text('Booster Pumps & ESD'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('ASSOCIATED CONDENSATE BOOSTER PUMP TRAINS (API 610 BB3)'),
        findsOneWidget,
      );

      // 9. Switch active train to C-102
      await tester.tap(find.text('C-102').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('CompressorStationScreen controls: live pause, popup menu, and station switch',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: CompressorStationScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Toggle live telemetry pause/resume
      final pauseButton = find.byTooltip('Pause Telemetry');
      expect(pauseButton, findsOneWidget);
      await tester.tap(pauseButton);
      await tester.pump();
      expect(find.text('PAUSED'), findsOneWidget);

      final resumeButton = find.byTooltip('Resume Telemetry');
      expect(resumeButton, findsOneWidget);
      await tester.tap(resumeButton);
      await tester.pump();
      expect(find.text('LIVE'), findsOneWidget);

      // 2. Open popup menu and launch ASC test modal
      final moreButton = find.byIcon(Icons.more_vert_rounded);
      expect(moreButton, findsOneWidget);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      expect(find.text('ASC Surge Test Stroke'), findsOneWidget);
      await tester.tap(find.text('ASC Surge Test Stroke'));
      await tester.pumpAndSettle();

      expect(find.text('ASC Recycle Stroke Test'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // 3. Switch station from CS-Duliajan to CS-Moran
      final dropdown = find.byType(DropdownButton<int>);
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('CS-Moran').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('CS-Moran'), findsWidgets);
    });
  });
}
