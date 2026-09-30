import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/engineering/geohazard_monitoring_screen.dart';

void main() {
  group('Geohazard Domain Model Tests', () {
    test('InclinometerSensor threatLevel thresholds', () {
      final now = DateTime.now();

      final normalSensor = InclinometerSensor(
        id: 'IN-TEST-1',
        chainage: 'Ch. 10+000',
        locationDescription: 'Test Stable',
        depthM: 30,
        displacementRateMmDay: 0.3,
        cumulativeDispMm: 2.0,
        slipPlaneDepthM: -10,
        batteryPct: 95,
        loraSnrDb: -80,
        lastPing: now,
        displacementProfile: const [0.1, 0.2, 0.3],
      );
      expect(normalSensor.threatLevel, GeohazardThreatLevel.normal);

      final watchSensor = InclinometerSensor(
        id: 'IN-TEST-2',
        chainage: 'Ch. 10+100',
        locationDescription: 'Test Watch',
        depthM: 30,
        displacementRateMmDay: 0.8,
        cumulativeDispMm: 5.0,
        slipPlaneDepthM: -10,
        batteryPct: 95,
        loraSnrDb: -80,
        lastPing: now,
        displacementProfile: const [0.5, 0.8],
      );
      expect(watchSensor.threatLevel, GeohazardThreatLevel.watch);

      final warningSensor = InclinometerSensor(
        id: 'IN-TEST-3',
        chainage: 'Ch. 10+200',
        locationDescription: 'Test Warning',
        depthM: 30,
        displacementRateMmDay: 2.5,
        cumulativeDispMm: 15.0,
        slipPlaneDepthM: -10,
        batteryPct: 90,
        loraSnrDb: -75,
        lastPing: now,
        displacementProfile: const [1.0, 2.5],
      );
      expect(warningSensor.threatLevel, GeohazardThreatLevel.warning);

      final emergencySensor = InclinometerSensor(
        id: 'IN-TEST-4',
        chainage: 'Ch. 10+300',
        locationDescription: 'Test Emergency',
        depthM: 30,
        displacementRateMmDay: 5.5,
        cumulativeDispMm: 45.0,
        slipPlaneDepthM: -10,
        batteryPct: 85,
        loraSnrDb: -70,
        lastPing: now,
        displacementProfile: const [2.0, 5.5],
      );
      expect(emergencySensor.threatLevel, GeohazardThreatLevel.emergency);
    });

    test('BathymetricStation depthOfCoverM and threatLevel thresholds', () {
      const stationNormal = BathymetricStation(
        chainageM: 100,
        bedElevationRlm: 95.0,
        pipeTopElevationRlm: 91.0,
        baselineBedRlm: 96.0,
        zoneType: 'Channel Bed',
      );
      expect(stationNormal.depthOfCoverM, 4.0);
      expect(stationNormal.scourDeepeningM, 1.0);
      expect(stationNormal.threatLevel, GeohazardThreatLevel.normal);

      const stationWatch = BathymetricStation(
        chainageM: 150,
        bedElevationRlm: 93.3,
        pipeTopElevationRlm: 91.0,
        baselineBedRlm: 95.0,
        zoneType: 'Scour Transition',
      );
      expect(stationWatch.depthOfCoverM, closeTo(2.3, 0.001));
      expect(stationWatch.threatLevel, GeohazardThreatLevel.watch);

      const stationWarning = BathymetricStation(
        chainageM: 200,
        bedElevationRlm: 92.8,
        pipeTopElevationRlm: 91.0,
        baselineBedRlm: 95.0,
        zoneType: 'Scour Hole',
      );
      expect(stationWarning.depthOfCoverM, closeTo(1.8, 0.001));
      expect(stationWarning.threatLevel, GeohazardThreatLevel.warning);

      const stationEmergency = BathymetricStation(
        chainageM: 250,
        bedElevationRlm: 92.2,
        pipeTopElevationRlm: 91.0,
        baselineBedRlm: 95.0,
        zoneType: 'Critical Scour Deficit',
      );
      expect(stationEmergency.depthOfCoverM, closeTo(1.2, 0.001));
      expect(stationEmergency.threatLevel, GeohazardThreatLevel.emergency);
    });

    test('SeismicStation threatLevel evaluation', () {
      const safeStation = SeismicStation(
        id: 'SA-SAFE',
        stationName: 'Test Normal Station',
        geologicalSetting: 'Bedrock',
        pgaG: 0.03,
        accelX: 0.03,
        accelY: 0.02,
        accelZ: 0.01,
        ariasIntensityMs: 0.04,
        liquefactionRu: 0.2,
      );
      expect(safeStation.threatLevel, GeohazardThreatLevel.normal);

      const quakeStation = SeismicStation(
        id: 'SA-ALERT',
        stationName: 'High Motion Station',
        geologicalSetting: 'Silt',
        pgaG: 0.28,
        accelX: 0.28,
        accelY: 0.24,
        accelZ: 0.15,
        ariasIntensityMs: 0.45,
        liquefactionRu: 0.88,
      );
      expect(quakeStation.threatLevel, GeohazardThreatLevel.emergency);
    });

    test('StrainGaugeStation equivalent Von Mises strain & pctSmys evaluation', () {
      const station = StrainGaugeStation(
        id: 'SG-TEST',
        chainage: 'Ch. 42+820',
        locationSegment: 'Sagbend Test',
        axialMicrostrain: 650.0,
        bendingMicrostrain: 450.0,
        hoopMicrostrain: 890.0,
        temperatureC: 24.5,
      );

      expect(station.equivalentVonMisesStrain, greaterThan(0));
      expect(station.pctSmys, greaterThan(0));
      expect(station.threatLevel, isA<GeohazardThreatLevel>());
    });
  });

  group('GeohazardMonitoringScreen Widget Tests', () {
    testWidgets('mounts, verifies title, tabs, and navigates through all sections',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: GeohazardMonitoringScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify AppBar Title & Subtitle
      expect(find.text('Geohazard & River Scour'), findsOneWidget);
      expect(find.textContaining('Brahmaputra & Burhi Dihing'), findsOneWidget);

      // 2. Verify Tab headers
      expect(find.text('Overview & Matrix'), findsOneWidget);
      expect(find.text('Inclinometers (12)'), findsOneWidget);
      expect(find.text('Bathymetry & Scour'), findsOneWidget);
      expect(find.text('Seismic Zone V'), findsOneWidget);
      expect(find.text('Pipeline Strain'), findsOneWidget);

      // 3. Verify Overview Tab Content
      expect(find.text('Geohazard Threat Level Matrix'), findsOneWidget);
      expect(find.text('River Discharge'), findsOneWidget);
      expect(find.text('Mean Flow Velocity'), findsOneWidget);
      expect(find.text('Bluff Retreat Rate'), findsOneWidget);

      // 4. Switch to Inclinometers Tab
      await tester.tap(find.text('Inclinometers (12)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.textContaining('In-Place Inclinometer Array'), findsOneWidget);
      expect(find.text('IN-01'), findsWidgets);
      expect(find.text('IN-05'), findsWidgets);
      expect(find.textContaining('lateral displacement'), findsOneWidget);
      expect(find.textContaining('mm/d'), findsWidgets);

      // 5. Switch to Bathymetry & Scour Tab
      await tester.tap(find.text('Bathymetry & Scour'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Dual-Frequency Echo Sounding Survey'), findsOneWidget);
      expect(find.text('Min Design DOC'), findsOneWidget);
      expect(find.text('Worst Survey DOC'), findsOneWidget);
      expect(find.textContaining('Burhi Dihing Riverbed & Pipeline Cross-Section Profile'), findsOneWidget);

      // 6. Switch to Seismic Zone V Tab
      await tester.tap(find.text('Seismic Zone V'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.textContaining('Triaxial Seismogram Oscillogram'), findsOneWidget);
      expect(find.textContaining('Triaxial Accelerometer Array'), findsOneWidget);
      expect(find.text('SA-01'), findsWidgets);
      expect(find.text('SA-02'), findsWidgets);

      // 7. Toggle Seismic Simulation
      final quakeSimButton = find.text('Simulate M5.8 Kopili Quake');
      expect(quakeSimButton, findsOneWidget);
      await tester.tap(quakeSimButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Stop M5.8 Quake Sim'), findsOneWidget);

      // 8. Switch to Pipeline Strain Tab
      await tester.tap(find.text('Pipeline Strain'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.textContaining('18" API 5L X70 SMYS Yield Envelope'), findsOneWidget);
      expect(find.text('SMYS (100%)'), findsOneWidget);
      expect(find.text('85% Alarm Limit'), findsOneWidget);

      // 9. Test SOP Checklist Modal
      final sopButton = find.byTooltip('SOP-GEO-09 Protocol');
      expect(sopButton, findsOneWidget);
      await tester.tap(sopButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Standard Operating Procedure (SOP-GEO-09)'), findsOneWidget);
      expect(find.textContaining('Pipeline River Crossing Geohazard Action Matrix'), findsOneWidget);
      // Close SOP bottom sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // 10. Test Notification Broadcast Dialog
      final broadcastButton = find.byTooltip('Broadcast Safety Notification');
      expect(broadcastButton, findsOneWidget);
      await tester.tap(broadcastButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Broadcast Geohazard Alert'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });
  });
}
