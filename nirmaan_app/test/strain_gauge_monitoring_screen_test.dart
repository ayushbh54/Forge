import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/screens/engineering/strain_gauge_monitoring_screen.dart';

void main() {
  group('Strain Gauge & Bending Stress Domain Model Tests', () {
    test('RosetteStation calculates bending strains, stresses, and von Mises correctly', () {
      final now = DateTime.now();
      // Setup rosette with known crown = 4000, invert = -4000, east = 0, west = 0
      // eps_bv = (4000 - (-4000)) / 2 = 4000 microstrain
      // eps_bh = 0
      // netBending = 4000 microstrain
      final station = RosetteStation(
        id: 'SG-TEST-1',
        chainage: 'Ch. 42+500',
        locationDescription: 'Test Scour Zone',
        chainageOffsetM: 500.0,
        pipeElevationRlm: 88.0,
        riverbedElevationRlm: 92.0,
        activeScourDepthM: 4.0,
        crownStrain: 4000.0,
        eastStrain: 0.0,
        invertStrain: -4000.0,
        westStrain: 0.0,
        temperatureC: 20.0,
        internalPressureMpa: 9.8,
        slopeSlipMm: 35.0,
        slopeSlipRateMmDay: 2.2,
        porePressureKpa: 100.0,
        lastPing: now,
        history: const [],
      );

      // Verify geometry & cover
      expect(station.depthOfCoverM, closeTo(4.0, 0.001));

      // Vertical bending: (4000 - (-4000)) / 2 = 4000
      expect(station.verticalBendingStrain, closeTo(4000.0, 0.01));
      expect(station.horizontalBendingStrain, closeTo(0.0, 0.01));
      expect(station.netBendingStrain, closeTo(4000.0, 0.01));

      // Axial strain: (4000 + 0 - 4000 + 0) / 4 = 0
      expect(station.axialStrain, closeTo(0.0, 0.01));

      // Longitudinal bending stress sigma_b = E * eps_b = 207,000 * 4000e-6 = 828.0 MPa
      expect(station.longitudinalBendingStressMpa, closeTo(828.0, 0.1));

      // Hoop stress: P * D / (2 * t) = (9.8 * 609.6) / (2 * 14.3) = 5974.08 / 28.6 = 208.88 MPa
      expect(station.hoopStressMpa, closeTo(208.88, 0.1));

      // Total longitudinal stress: nu * sigma_h + sigma_b = (0.30 * 208.88) + 828.0 = 62.66 + 828.0 = 890.66 MPa
      expect(station.totalLongitudinalStressMpa, closeTo(890.66, 0.2));

      // Peak microstrain: 4000
      expect(station.peakMicrostrain, closeTo(4000.0, 0.01));

      // Curvature radius: R = D / (2 * eps_b) = 0.6096 / (2 * 4000e-6) = 0.6096 / 0.008 = 76.2 m
      expect(station.radiusOfCurvatureM, closeTo(76.2, 0.1));
    });

    test('StrainAlertLevel thresholds adhere to 70% Yellow and 85% Red alerts', () {
      final now = DateTime.now();

      // Normal condition: Peak strain 2000 microstrain (40% allowable < 70%)
      final normalStation = RosetteStation(
        id: 'SG-NORMAL',
        chainage: 'Ch. 42+100',
        locationDescription: 'Stable',
        chainageOffsetM: 100.0,
        pipeElevationRlm: 95.0,
        riverbedElevationRlm: 100.0,
        activeScourDepthM: 0.5,
        crownStrain: 2000.0,
        eastStrain: 0.0,
        invertStrain: -2000.0,
        westStrain: 0.0,
        temperatureC: 22.0,
        internalPressureMpa: 9.8,
        slopeSlipMm: 2.0,
        slopeSlipRateMmDay: 0.1,
        porePressureKpa: 30.0,
        lastPing: now,
        history: const [],
      );
      expect(normalStation.strainUtilizationRatio, closeTo(0.40, 0.01));
      expect(normalStation.alertLevel, StrainAlertLevel.normal);

      // Yellow alert condition: Peak strain 3600 microstrain (72% allowable >= 70% and < 85%)
      final yellowStation = RosetteStation(
        id: 'SG-YELLOW',
        chainage: 'Ch. 42+300',
        locationDescription: 'Watch Scour',
        chainageOffsetM: 300.0,
        pipeElevationRlm: 90.0,
        riverbedElevationRlm: 95.0,
        activeScourDepthM: 2.5,
        crownStrain: 3600.0,
        eastStrain: 0.0,
        invertStrain: -3600.0,
        westStrain: 0.0,
        temperatureC: 22.0,
        internalPressureMpa: 9.8,
        slopeSlipMm: 25.0,
        slopeSlipRateMmDay: 1.5,
        porePressureKpa: 70.0,
        lastPing: now,
        history: const [],
      );
      expect(yellowStation.strainUtilizationRatio, closeTo(0.72, 0.01));
      expect(yellowStation.alertLevel, StrainAlertLevel.yellowAlert);

      // Red alert condition: Peak strain 4400 microstrain (88% allowable >= 85% and < 100%)
      final redStation = RosetteStation(
        id: 'SG-RED',
        chainage: 'Ch. 42+800',
        locationDescription: 'Critical Thalweg Scour',
        chainageOffsetM: 800.0,
        pipeElevationRlm: 85.0,
        riverbedElevationRlm: 90.0,
        activeScourDepthM: 5.0,
        crownStrain: 4400.0,
        eastStrain: 0.0,
        invertStrain: -4400.0,
        westStrain: 0.0,
        temperatureC: 22.0,
        internalPressureMpa: 9.8,
        slopeSlipMm: 65.0,
        slopeSlipRateMmDay: 4.5,
        porePressureKpa: 140.0,
        lastPing: now,
        history: const [],
      );
      expect(redStation.strainUtilizationRatio, closeTo(0.88, 0.01));
      expect(redStation.alertLevel, StrainAlertLevel.redAlert);

      // Exceeded condition: Peak strain 5200 microstrain (104% allowable >= 100%)
      final exceededStation = RosetteStation(
        id: 'SG-EXCEEDED',
        chainage: 'Ch. 42+900',
        locationDescription: 'Plastic Wrinkling Zone',
        chainageOffsetM: 900.0,
        pipeElevationRlm: 84.0,
        riverbedElevationRlm: 90.0,
        activeScourDepthM: 6.0,
        crownStrain: 5200.0,
        eastStrain: 0.0,
        invertStrain: -5200.0,
        westStrain: 0.0,
        temperatureC: 22.0,
        internalPressureMpa: 9.8,
        slopeSlipMm: 90.0,
        slopeSlipRateMmDay: 6.0,
        porePressureKpa: 180.0,
        lastPing: now,
        history: const [],
      );
      expect(exceededStation.strainUtilizationRatio, closeTo(1.04, 0.01));
      expect(exceededStation.alertLevel, StrainAlertLevel.exceeded);
    });

    test('MicrostrainHistoryPoint finds max microstrain across 4 clock positions', () {
      final pt = MicrostrainHistoryPoint(
        timestamp: DateTime.now(),
        crownMicrostrain: 3200.0,
        invertMicrostrain: -3850.0,
        eastMicrostrain: 1100.0,
        westMicrostrain: -950.0,
      );
      expect(pt.maxMicrostrain, closeTo(3850.0, 0.001));
    });
  });

  group('Strain Gauge Monitoring Screen Widget Tests', () {
    Widget createWidgetUnderTest() {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: const StrainGaugeMonitoringScreen(),
      );
    }

    testWidgets('Renders app bar, telemetry indicator, and system alert pills', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // App bar titles
      expect(find.text('Pipeline Strain & Bending Stress'), findsOneWidget);
      expect(find.textContaining('ASME B31.8 / PRCI SBD'), findsOneWidget);

      // System alert bar
      expect(find.text('8/8 Rosettes Live'), findsOneWidget);
      expect(find.textContaining('RED'), findsWidgets);
      expect(find.textContaining('YELLOW'), findsWidgets);
      expect(find.textContaining('NORMAL'), findsWidgets);

      // Tab bar items
      expect(find.text('ROSETTES'), findsOneWidget);
      expect(find.text('3D WIREFRAME'), findsOneWidget);
      expect(find.text('B31.8 CALCULATOR'), findsOneWidget);
      expect(find.text('TELEMETRY & LOGS'), findsOneWidget);
    });

    testWidgets('Renders overview metrics and rosette selector cards on Rosettes tab', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Metric cards
      expect(find.text('PEAK VON MISES'), findsOneWidget);
      expect(find.text('MAX MICROSTRAIN'), findsOneWidget);
      expect(find.text('MIN BENDING RADIUS'), findsOneWidget);
      expect(find.text('RIVERBANK SLIP RATE'), findsOneWidget);

      // Rosette selector cards
      expect(find.text('SG-01'), findsWidgets);
      expect(find.text('SG-02'), findsWidgets);
      expect(find.text('SG-03'), findsWidgets);
      expect(find.text('SG-04'), findsWidgets);

      // Cross-section clock positions
      expect(find.text('12:00 CROWN (TOP)'), findsOneWidget);
      expect(find.text('03:00 EAST SPRINGLINE'), findsOneWidget);
      expect(find.text('06:00 INVERT (BOTTOM)'), findsOneWidget);
      expect(find.text('09:00 WEST SPRINGLINE'), findsOneWidget);

      // Tap on SG-02 to change selection
      await tester.tap(find.text('SG-02'));
      await tester.pumpAndSettle();
      expect(find.text('Selected: SG-02'), findsOneWidget);
    });

    testWidgets('Switches to 3D Wireframe tab and displays 3D controls', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap 3D Wireframe Tab
      await tester.tap(find.text('3D WIREFRAME'));
      await tester.pumpAndSettle();

      expect(find.text('3D WIREFRAME DEFORMATION PLOT'), findsOneWidget);
      expect(find.textContaining('Drag to Orbit'), findsOneWidget);
      expect(find.text('Deflection Scale Multiplier'), findsOneWidget);
      expect(find.text('Camera Zoom Scale'), findsOneWidget);
      expect(find.text('Scour Trench Bathymetry'), findsOneWidget);
      expect(find.text('Burhi Dihing Water Surface'), findsOneWidget);
    });

    testWidgets('Switches to ASME B31.8 Calculator tab and displays calculations', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Calculator Tab
      await tester.tap(find.text('B31.8 CALCULATOR'));
      await tester.pumpAndSettle();

      expect(find.text('INPUT DESIGN & LOAD PARAMETERS'), findsOneWidget);
      expect(find.text('Pipeline Steel Grade'), findsOneWidget);
      expect(find.text('STRESS CALCULATION OUTPUT'), findsOneWidget);
      expect(find.textContaining('Hoop Stress: σ_h = P • D / (2t)'), findsOneWidget);
      expect(find.textContaining('Longitudinal Bending: σ_b = E • ε_b'), findsOneWidget);
      expect(find.textContaining('Total Longitudinal: σ_L = ν • σ_h + σ_b'), findsOneWidget);
      expect(find.textContaining('Equivalent von Mises: σ_eq'), findsOneWidget);
      expect(find.textContaining('Stress Utilization (σ_eq / 0.90 SMYS)'), findsOneWidget);
    });

    testWidgets('Switches to Telemetry & Logs tab and displays table and SOP triggers', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Telemetry & Logs Tab
      await tester.tap(find.text('TELEMETRY & LOGS'));
      await tester.pumpAndSettle();

      expect(find.textContaining('MICROSTRAIN HISTORY'), findsOneWidget);
      expect(find.text('24 Hours'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('RIVERBANK SLOPE SLIP & PIEZOMETER TELEMETRY'), findsOneWidget);
      expect(find.text('STANDARD OPERATING PROCEDURE (SOP) TRIGGERS'), findsOneWidget);
      expect(find.text('ESDV Pressure Drawdown (Advisory)'), findsOneWidget);

      // Tap an SOP ActionChip
      await tester.tap(find.text('ESDV Pressure Drawdown (Advisory)'));
      await tester.pump(); // Show snackbar
      expect(find.textContaining('ESDV Pressure Drawdown to 65 bar initiated'), findsOneWidget);
    });

    testWidgets('Emergency SOP Dialog opens on shield button tap and dispatches', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Shield IconButton
      await tester.tap(find.byIcon(Icons.shield_outlined));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.textContaining('SOP Actions:'), findsOneWidget);
      expect(find.textContaining('Mandatory ASME B31.8 Protocols:'), findsOneWidget);
      expect(find.text('DISPATCH ADVISORY'), findsOneWidget);

      // Tap DISPATCH ADVISORY
      await tester.tap(find.text('DISPATCH ADVISORY'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Emergency Geotechnical Alert dispatched'), findsOneWidget);
    });
  });
}
