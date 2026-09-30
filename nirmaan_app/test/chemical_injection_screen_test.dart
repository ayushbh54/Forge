import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/operations/chemical_injection_screen.dart';

void main() {
  testWidgets('ChemicalInjectionScreen mounts and renders NACE/OISD dosing telemetry and KPIs',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ChemicalInjectionScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Standard Badges
    expect(find.text('Chemical Injection & Dosing Skid'), findsOneWidget);
    expect(find.textContaining('NACE MR0175 / OISD-141'), findsWidgets);

    // Verify Dosing Skid Selector Chips
    expect(find.text('SK-01'), findsOneWidget);
    expect(find.text('(Duliajan CPF)'), findsOneWidget);
    expect(find.text('SK-02'), findsOneWidget);
    expect(find.text('(Moran SV-03)'), findsOneWidget);
    expect(find.text('SK-03'), findsOneWidget);
    expect(find.text('(Jorhat SV-05)'), findsOneWidget);

    // Verify Top KPI Metric Cards
    expect(find.text('CORROSION RATE'), findsOneWidget);
    expect(find.text('Target < 1.0 mpy'), findsWidgets);
    expect(find.text('DOSING FLOW'), findsOneWidget);
    expect(find.text('TANK AUTONOMY'), findsOneWidget);
    expect(find.text('SOLAR BATTERY'), findsOneWidget);

    // Verify Tab Headers
    expect(find.text('Pump Telemetry'), findsOneWidget);
    expect(find.text('Chemicals'), findsOneWidget);
    expect(find.text('ER Probes'), findsOneWidget);
    expect(find.text('Coupon Schedule'), findsOneWidget);
    expect(find.text('Compliance Audit'), findsOneWidget);

    // Verify Tab 1 (Pump Telemetry) Contents
    expect(find.text('Dual Diaphragm Metering Pump (API 675)'), findsOneWidget);
    expect(find.text('Pump Stroke Speed'), findsOneWidget);
    expect(find.text('Stroke Length Adjustment (Servo Actuator)'), findsOneWidget);
    expect(find.text('Solar Power & Battery Micro-Grid'), findsOneWidget);
    expect(find.text('Auto-Switchover on Fault'), findsOneWidget);
    expect(find.textContaining('Storage Tank Level'), findsOneWidget);

    // Test Pump Duty Switch button
    final switchButtonFinder = find.widgetWithText(ElevatedButton, 'Switch');
    expect(switchButtonFinder, findsOneWidget);
    await tester.tap(switchButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Test Skid Switcher: Switch to SK-02 Moran SV-03
    final sk02Chip = find.widgetWithText(ChoiceChip, 'SK-02');
    await tester.tap(sk02Chip, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Moran Sectionalizing Valve Station'), findsOneWidget);

    // Test Skid Switcher: Switch to SK-03 Jorhat SV-05
    final sk03Chip = find.widgetWithText(ChoiceChip, 'SK-03');
    await tester.tap(sk03Chip, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Jorhat Sectionalizing Valve Station'), findsOneWidget);

    // Switch back to SK-01
    final sk01Chip = find.widgetWithText(ChoiceChip, 'SK-01');
    await tester.tap(sk01Chip, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Switch to Tab 2: Chemicals
    await tester.tap(find.text('Chemicals'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify 4 Chemicals Catalog
    expect(find.text('CORR-SHIELD 8420-NACE'), findsWidgets);
    expect(find.text('DEMUL-BREAK 610-HP'), findsOneWidget);
    expect(find.text('SCAV-TRON 500-TRI'), findsOneWidget);
    expect(find.text('BIO-BAN 360-DUAL'), findsOneWidget);
    expect(find.text('Shock Slug Dosing (Biocide & Batch Treatment)'), findsOneWidget);

    // Select Demulsifier chip
    await tester.tap(find.text('DEMUL-BREAK 610-HP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Polyoxyethylene alkylphenol'), findsOneWidget);

    // Select Biocide chip
    await tester.tap(find.text('BIO-BAN 360-DUAL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Glutaraldehyde (25%) + THPS (50%)'), findsOneWidget);

    // Trigger Biocide Shock Slug Dosing
    final slugButton = find.text('Initiate 4-Hour Biocide Slug Injection (250 ppm)');
    expect(slugButton, findsOneWidget);
    await tester.tap(slugButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('INJECTION IN PROGRESS'), findsOneWidget);
    expect(find.text('Abort Slug'), findsOneWidget);

    // Abort slug
    await tester.tap(find.text('Abort Slug'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Switch to Tab 3: ER Probes
    await tester.tap(find.text('ER Probes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('CORROSION CONTROL: COMPLIANT'), findsOneWidget);
    expect(find.text('Cumulative Metal Loss Trend (30 Days)'), findsOneWidget);
    expect(find.text('ER Probe Hardware & Installation Profile'), findsOneWidget);
    expect(find.textContaining('Rohrback Cosasco Corrosometer 2500'), findsOneWidget);

    // Switch to Tab 4: Coupon Schedule
    await tester.tap(find.text('Coupon Schedule'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Weight Loss Corrosion Coupon Schedule'), findsOneWidget);
    expect(find.text('WLC-SK01-2026-A1'), findsOneWidget);
    expect(find.text('Cosasco High-Pressure Live Line Retriever'), findsOneWidget);

    // Tap Cosasco extraction checklist button
    final checklistButton = find.text('View Cosasco Live Line Extraction Checklist');
    expect(checklistButton, findsOneWidget);
    await tester.tap(checklistButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cosasco Hot-Tap Live Retrieval Checklist'), findsOneWidget);
    await tester.tap(find.text('Acknowledge Safety Protocol'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Switch to Tab 5: Compliance Audit
    await tester.tap(find.text('Compliance Audit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('NACE MR0175 & OISD-141 AUDIT MATRIX'), findsOneWidget);
    expect(find.text('100% COMPLIANT'), findsOneWidget);
    expect(find.text('NACE MR0175 / ISO 15156-2'), findsOneWidget);
    expect(find.text('OISD-141 Clause 8.2.1'), findsOneWidget);
    expect(find.text('API Standard 675'), findsOneWidget);
    expect(find.text('Chemical Batch Traceability & Certificate Ledger'), findsOneWidget);

    // Test Dosage Rate Calculator Modal in AppBar
    await tester.tap(find.byTooltip('Dosage Rate Calculator'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Chemical Dosage Rate Calculator'), findsOneWidget);
    expect(find.text('Apply Computed Parameters to Skid'), findsOneWidget);
    await tester.tap(find.text('Apply Computed Parameters to Skid'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Test Refill Chemical Tank Dialog in AppBar
    await tester.tap(find.byTooltip('Refill Chemical Tank'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Chemical Tank Replenishment'), findsOneWidget);
    expect(find.text('Dispatch Tanker PO'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });
}
