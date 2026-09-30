import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/operations/dewatering_drying_screen.dart';

void main() {
  group('Pipeline Dewatering, Swabbing & Air/Nitrogen Drying Tests (ASME B31.8 / OISD-141)', () {
    testWidgets('DewateringDryingScreen mounts and renders core headers, KPIs and SCADA synoptic',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: DewateringDryingScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Title & Standard Header
      expect(find.text('Pipeline De-watering & Drying'), findsOneWidget);
      expect(find.textContaining('ASME B31.8 Sec 841.3 • OISD-141'), findsOneWidget);

      // Verify Section Chips
      expect(find.textContaining('SEC-01: Duliajan to Digboi'), findsOneWidget);
      expect(find.textContaining('SEC-02: Digboi to Moran'), findsOneWidget);
      expect(find.textContaining('SEC-03: Moran to Jorhat'), findsOneWidget);

      // Verify KPI Metrics
      expect(find.text('PIG VELOCITY'), findsOneWidget);
      expect(find.text('DISCHARGE FLOW'), findsOneWidget);
      expect(find.text('RESIDUAL WATER FILM'), findsOneWidget);
      expect(find.text('OUTLET DEW POINT'), findsOneWidget);
      expect(find.text('24-HR SOAK ΔTdp'), findsOneWidget);

      // Verify 5 Tab Headers
      expect(find.text('SCADA Synoptic'), findsOneWidget);
      expect(find.text('De-watering & Swabs'), findsOneWidget);
      expect(find.text('Air/N₂ Purging'), findsOneWidget);
      expect(find.text('24h Soak Test'), findsOneWidget);
      expect(find.text('Calculators & Audit'), findsOneWidget);

      // Verify SCADA Synoptic Tab Elements
      expect(find.textContaining('P&ID SCADA SYNOPTIC'), findsOneWidget);
      expect(find.textContaining('LAUNCHER SKID'), findsOneWidget);
      expect(find.textContaining('RECEIVER SKID'), findsOneWidget);
      expect(find.textContaining('HOLDING SUMP & ENVIRONMENTAL DECANTATION BASIN'), findsOneWidget);
      expect(find.textContaining('PIG TRAIN CLOSED-LOOP SPEED REGULATION (3 to 5 km/hr)'), findsOneWidget);

      // Test Section Switching: Switch to SEC-02 Digboi to Moran
      final sec02Finder = find.textContaining('SEC-02: Digboi to Moran');
      await tester.tap(sec02Finder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Digboi Station to Moran Junction'), findsWidgets);

      // Switch back to SEC-01
      final sec01Finder = find.textContaining('SEC-01: Duliajan to Digboi');
      await tester.tap(sec01Finder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('Tab 2 (De-watering & Swabs) renders dual HD-PU disc pigs and logs foam swabbing runs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: DewateringDryingScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Tab 2: De-watering & Swabs
      await tester.tap(find.text('De-watering & Swabs'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Dual Disc Pigs Spec
      expect(find.text('DUAL HIGH-DENSITY DISC PIG TRAIN SPECIFICATIONS'), findsOneWidget);
      expect(find.textContaining('LEAD PIG: 4-DISC HD-PU DISPLACEMENT'), findsOneWidget);
      expect(find.textContaining('TAIL PIG: 4-DISC BATCHING & SCRAPER'), findsOneWidget);

      // Verify Swabbing Log & Residual Water Film Criteria (< 0.1 mm)
      expect(find.text('FOAM SWABBING LOG & RESIDUAL WATER FILM (< 0.1 mm)'), findsOneWidget);
      expect(find.textContaining('Residual Water Film Thickness Formula'), findsOneWidget);
      expect(find.text('Run #1'), findsOneWidget);
      expect(find.text('Run #4'), findsOneWidget);
      expect(find.text('PASS (< 0.1mm)'), findsWidgets);

      // Tap 'Log Swab Run' button to open dialog
      final logSwabBtn = find.widgetWithText(ElevatedButton, 'Log Swab Run');
      expect(logSwabBtn, findsOneWidget);
      await tester.tap(logSwabBtn, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Dialog
      expect(find.textContaining('Log Swab Run'), findsWidgets);
      expect(find.text('ASME B31.8 / OISD-141 Residual Film Verification'), findsOneWidget);

      // Submit new swab run
      final submitBtn = find.widgetWithText(ElevatedButton, 'Submit Run Log');
      await tester.tap(submitBtn, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify that Run #5 was logged
      expect(find.text('Run #5'), findsOneWidget);
    });

    testWidgets('Tab 3 (Air/N₂ Purging) renders desiccant dryer, dew point monitoring & psychrometric specs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: DewateringDryingScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Tab 3: Air/N₂ Purging
      await tester.tap(find.text('Air/N₂ Purging'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Purge Skid Details
      expect(find.text('SUPER-DRY AIR / DRY NITROGEN PURGE SKID'), findsOneWidget);
      expect(find.text('TWIN-TOWER DESICCANT AIR DRYER'), findsOneWidget);
      expect(find.text('CRYOGENIC NITROGEN (LIN) VAPORIZER'), findsOneWidget);

      // Verify Continuous Dew Point Monitoring
      expect(find.text('CONTINUOUS DEW POINT MONITORING (Inlet vs Outlet)'), findsOneWidget);
      expect(find.textContaining('Atmospheric Dew Point (ADP) down to -40.0°C'), findsOneWidget);
      expect(find.textContaining('Inlet Air ADP'), findsOneWidget);
      expect(find.textContaining('Outlet Air ADP'), findsOneWidget);
      expect(find.textContaining('Target Threshold (-40.0 °C)'), findsOneWidget);

      // Verify Physical Water Vapor Equivalence (< 0.128 g/Nm³)
      expect(find.text('PHYSICAL WATER VAPOR EQUIVALENCE'), findsOneWidget);
      expect(find.text('< 0.128 g/Nm³'), findsWidgets);
      expect(find.text('< 160 ppmv'), findsOneWidget);
    });

    testWidgets('Tab 4 (24h Soak Test) renders soak protocol, ΔTdp ≤ 2°C criteria and sign-off certificate',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: DewateringDryingScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Tab 4: 24h Soak Test
      await tester.tap(find.text('24h Soak Test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Soak Protocol Card
      expect(find.text('24-HOUR DEW POINT SOAK & STABILIZATION PROTOCOL'), findsOneWidget);
      expect(find.text('START DEW POINT (HR 0)'), findsOneWidget);
      expect(find.text('FINAL DEW POINT (HR 24)'), findsOneWidget);
      expect(find.text('OBSERVED ΔTdp'), findsOneWidget);
      expect(find.text('CRITERIA LIMIT'), findsOneWidget);
      expect(find.text('≤ 2.00 °C / 24h'), findsOneWidget);

      // Verify 24-Hour Hourly Log Table
      expect(find.text('24-HOUR HOURLY DATA LOG (00:00 to 24:00)'), findsOneWidget);
      expect(find.text('Hr 0'), findsWidgets);
      expect(find.text('Hr 24'), findsWidgets);

      // Tap 'View Sign-off Certificate' button
      final certBtn = find.widgetWithText(ElevatedButton, 'View Sign-off Certificate');
      expect(certBtn, findsOneWidget);
      await tester.tap(certBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Certificate Dialog Elements
      expect(find.text('PIPELINE DRYNESS CERTIFICATE'), findsOneWidget);
      expect(find.textContaining('ASME B31.8 Sec 841.3 / OISD-141 Compliant'), findsOneWidget);
      expect(find.textContaining('CRYPTOGRAPHIC AUDIT SEAL (SHA-256):'), findsOneWidget);

      // Close Certificate Dialog
      final closeBtn = find.widgetWithText(OutlinedButton, 'Close');
      await tester.tap(closeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('Tab 5 (Calculators & Audit) executes calculators and displays ASME B31.8/OISD-141 checklist',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: DewateringDryingScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Tab 5: Calculators & Audit
      await tester.tap(find.text('Calculators & Audit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify 4 Engineering Calculators
      expect(find.text('PIPELINE DRYING ENGINEERING CALCULATORS'), findsOneWidget);
      expect(find.text('Water Evacuation & Pig Travel'), findsOneWidget);
      expect(find.text('Swab Residual Film Thickness'), findsOneWidget);
      expect(find.text('Atmospheric Dew Point to Vapor'), findsOneWidget);
      expect(find.text('Nitrogen Pack Inventory'), findsOneWidget);

      // Verify Regulatory Compliance Audit Clauses
      expect(find.text('ASME B31.8 / OISD-141 REGULATORY COMPLIANCE AUDIT'), findsOneWidget);
      expect(find.textContaining('ASME B31.8 Sec 841.3.1'), findsOneWidget);
      expect(find.textContaining('OISD-141 Cl. 8.1.2'), findsOneWidget);
      expect(find.textContaining('OISD-141 Cl. 8.1.4'), findsOneWidget);
      expect(find.textContaining('ASME B31.8 Sec 841.3.2'), findsOneWidget);
      expect(find.textContaining('OISD-141 Cl. 8.2.1'), findsOneWidget);
      expect(find.textContaining('ASME B31.8 Sec 841.3.3'), findsOneWidget);

      // Verify simulation toggle in AppBar
      final pauseIconFinder = find.byIcon(Icons.pause_circle_outline_rounded);
      expect(pauseIconFinder, findsOneWidget);
      await tester.tap(pauseIconFinder);
      await tester.pump();
      expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
    });
  });
}
