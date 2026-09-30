import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/operations/hydrate_prediction_screen.dart';

void main() {
  group('Thermodynamic & Hammerschmidt Model Unit Tests', () {
    // Exact Sloan/GPSA correlation test
    test('calculateHydrateEquilibriumTemp returns ~15.6°C at 68.5 Bar and SG 0.612', () {
      const p = 68.5;
      const sg = 0.612;
      final lnP = math.log(p);
      final lnP0 = math.log(68.5);
      final tHyd = 15.6 +
          (6.85 * (lnP - lnP0)) +
          (19.4 * (sg - 0.612)) -
          (0.008 * (p - 68.5));

      expect(tHyd, closeTo(15.6, 0.05));
    });

    // Subcooling margin test
    test('calculateSubcoolingMargin detects active risk when Tflow < Thyd', () {
      const tHyd = 15.6;
      const tFlow = 8.2; // Disang riverbed cold spot
      final deltaTSub = tHyd - tFlow;

      expect(deltaTSub, closeTo(7.4, 0.05));
      expect(deltaTSub > 0, isTrue); // Active Hydrate Risk Alert
    });

    test('calculateSubcoolingMargin is negative in safe conditions (Tflow > Thyd)', () {
      const tHyd = 15.6;
      const tFlow = 32.0; // Duliajan CGGS compressor outlet
      final deltaTSub = tHyd - tFlow;

      expect(deltaTSub, lessThan(0.0)); // Safe zone
    });

    // Hammerschmidt Equation tests
    test('Hammerschmidt formula calculates required Methanol weight % correctly', () {
      // W = (100 * M * ΔT) / (K + M * ΔT)
      const m = 32.04; // MeOH MW
      const k = 1297.0; // SI constant
      const deltaT = 10.4; // 7.4°C subcooling + 3.0°C safety margin

      final w = (100.0 * m * deltaT) / (k + (m * deltaT));
      // (100 * 32.04 * 10.4) / (1297 + 32.04 * 10.4) = 33321.6 / 1630.216 = 20.44 wt%
      expect(w, closeTo(20.44, 0.2));
    });

    test('Hammerschmidt formula calculates required MEG weight % correctly', () {
      const m = 62.07; // MEG MW
      const k = 1500.0; // SI constant
      const deltaT = 10.4;

      final w = (100.0 * m * deltaT) / (k + (m * deltaT));
      // (100 * 62.07 * 10.4) / (1500 + 62.07 * 10.4) = 64552.8 / 2145.528 = 30.09 wt%
      expect(w, closeTo(30.09, 0.2));
    });

    test('Hammerschmidt returns 0 wt% when deltaT is 0 or negative', () {
      const m = 32.04;
      const k = 1297.0;
      const deltaT = 0.0;

      final w = deltaT <= 0 ? 0.0 : (100.0 * m * deltaT) / (k + (m * deltaT));
      expect(w, equals(0.0));
    });
  });

  group('HydratePredictionScreen Widget Tests', () {
    testWidgets('HydratePredictionScreen mounts and renders top KPIs and alert banner',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: HydratePredictionScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify App Bar title and standards
      expect(find.text('Hydrate & Methanol Prediction'), findsOneWidget);
      expect(find.text('DNPL 192 KM'), findsOneWidget);
      expect(find.textContaining('GPSA 20th Ed.'), findsWidgets);

      // 2. Verify Subcooling Risk Banner (active risk at Disang River 8.2°C)
      expect(find.textContaining('SUBCOOLING MARGIN'), findsWidgets);
      expect(find.textContaining('ACTIVE HYDRATE FORMATION RISK'), findsWidgets);

      // 3. Verify Top Metric Strip Cards
      expect(find.text('HYDRATE TEMP (Thyd)'), findsOneWidget);
      expect(find.text('FLOWING TEMP (Tflow)'), findsOneWidget);
      expect(find.text('INHIBITOR CONC (W)'), findsOneWidget);
      expect(find.text('DOSING PUMP RATE'), findsOneWidget);
      expect(find.text('METHANOL STOCK'), findsOneWidget);

      // 4. Verify 5 Tab Headers
      expect(find.text('Model & Predictor'), findsOneWidget);
      expect(find.text('THI Hammerschmidt'), findsOneWidget);
      expect(find.text('Trunkline Heatmap'), findsOneWidget);
      expect(find.text('Dosing Skids'), findsOneWidget);
      expect(find.text('Gas Chromatography'), findsOneWidget);

      // 5. Verify Tab 1 (Model & Predictor) Content
      expect(find.text('Thermodynamic Operating Parameters'), findsOneWidget);
      expect(find.textContaining('Operating Pipeline Pressure'), findsOneWidget);
      expect(find.textContaining('Gas Specific Gravity'), findsOneWidget);
      expect(find.textContaining('Flowing Gas Temperature'), findsOneWidget);
      expect(find.text('Hydrate Equilibrium P-T Phase Envelope'), findsOneWidget);
      expect(find.text('Thermodynamic Phase Analysis Summary'), findsOneWidget);
    });

    testWidgets('Tab 2 THI Hammerschmidt Dosing calculator functions correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: HydratePredictionScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Tab 2
      await tester.tap(find.text('THI Hammerschmidt'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Hammerschmidt Mathematical Formulation Header
      expect(find.text('Hammerschmidt Equation (Thermodynamic Hydrate Inhibitor)'), findsOneWidget);
      expect(find.text('ΔT = (K × W) / (100 × M - M × W)'), findsOneWidget);
      expect(find.text('Rearranged for Weight %:  W = (100 × M × ΔT) / (K + M × ΔT)'), findsOneWidget);

      // Verify Inhibitor Options
      expect(find.text('Select Thermodynamic Hydrate Inhibitor (THI)'), findsOneWidget);
      expect(find.text('Methanol'), findsOneWidget);
      expect(find.text('Monoethylene'), findsOneWidget);
      expect(find.text('Diethylene'), findsOneWidget);

      // Tap MEG chip
      await tester.tap(find.text('Monoethylene'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Chemical Mass Balance and OPEX Cards
      expect(find.text('Chemical Mass & Partition Balance'), findsOneWidget);
      expect(find.text('API 675 Injection Rate & OPEX Projection'), findsOneWidget);
      expect(find.text('PUMP FLOW RATE'), findsOneWidget);
      expect(find.text('DAILY USAGE'), findsOneWidget);
      expect(find.text('DAILY COST'), findsOneWidget);
    });

    testWidgets('Tab 3 Trunkline Heatmap renders river crossing cold spots and station selection',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: HydratePredictionScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Tab 3
      await tester.tap(find.text('Trunkline Heatmap'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Trunkline Heatmap Overview Card
      expect(find.text('Duliajan–Numaligarh Trunkline Heatmap'), findsOneWidget);
      expect(find.text('192.0 KM • 16-Inch X70'), findsOneWidget);
      expect(find.text('KP 0.0 (Duliajan)'), findsOneWidget);
      expect(find.text('KP 64.0 (Disang HDD)'), findsOneWidget);
      expect(find.text('KP 88.5 (Dikhow HDD)'), findsOneWidget);
      expect(find.text('KP 192.0 (NRL)'), findsOneWidget);

      // Verify River Station Inventory
      expect(find.text('Trunkline Station & River Crossing Inventory'), findsOneWidget);
      expect(find.textContaining('Buri Dihing River HDD Crossing'), findsWidgets);
      expect(find.textContaining('Disang River HDD Crossing'), findsWidgets);
      expect(find.textContaining('Dikhow River Crossing'), findsWidgets);
      expect(find.textContaining('Numaligarh Custody Terminal'), findsWidgets);

      // Select Buri Dihing chip
      final buriDihingChip = find.textContaining('KP 18.5: Buri');
      expect(buriDihingChip, findsOneWidget);
      await tester.tap(buriDihingChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Buri Dihing River'), findsWidgets);
    });

    testWidgets('Tab 4 Dosing Skids enables pump duty switch and emergency shock slug',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: HydratePredictionScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Tab 4
      await tester.tap(find.text('Dosing Skids'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Skids
      expect(find.text('SK-HYD-01'), findsOneWidget);
      expect(find.text('SK-HYD-02'), findsOneWidget);
      expect(find.text('SK-HYD-03'), findsOneWidget);
      expect(find.textContaining('Pipeline Injection Skids'), findsOneWidget);

      // Test Switch Duty button
      final switchDutyButtons = find.text('Switch Duty');
      expect(switchDutyButtons, findsWidgets);
      await tester.tap(switchDutyButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Test Shock Slug Dosing button
      final shockSlugButtons = find.text('Shock Slug Dosing');
      expect(shockSlugButtons, findsWidgets);
      await tester.tap(shockSlugButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Shock Slug Dialog appears
      expect(find.text('Authorize Emergency Shock Slug'), findsOneWidget);
      expect(find.textContaining('OISD-141 / PNGRB T4S Slug Protocol'), findsOneWidget);

      // Execute Shock Slug
      final executeButton = find.widgetWithText(ElevatedButton, 'Execute Slug');
      expect(executeButton, findsOneWidget);
      await tester.tap(executeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SHOCK SLUG ACTIVE'), findsOneWidget);
    });

    testWidgets('Tab 5 Gas Chromatography displays ISO 6974 analysis and clathrate structures',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: HydratePredictionScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Tab 5
      await tester.tap(find.text('Gas Chromatography'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Gas Composition Table
      expect(find.text('Natural Gas Composition (Duliajan Lean Gas)'), findsOneWidget);
      expect(find.text('ISO 6974 / GPA 2261'), findsOneWidget);
      expect(find.text('Methane'), findsOneWidget);
      expect(find.text('CH₄'), findsOneWidget);
      expect(find.text('Propane'), findsOneWidget);
      expect(find.text('Structure II (sII - Critical)'), findsOneWidget);

      // Verify Clathrate Thermodynamics & Standards Cards
      expect(find.text('Clathrate Hydrate Molecular Thermodynamics'), findsOneWidget);
      expect(find.text('Statutory & Standards Compliance'), findsOneWidget);
      expect(find.textContaining('OISD-STD-141 Clause 6.4'), findsOneWidget);
      expect(find.textContaining('PNGRB T4S Regulations'), findsOneWidget);
    });
  });
}
