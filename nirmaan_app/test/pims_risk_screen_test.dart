import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/integrity/pims_risk_screen.dart';

void main() {
  testWidgets('PimsRiskScreen mounts and renders 5x5 matrix, calculator, and dig schedule',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PimsRiskScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Subtitle
    expect(find.text('PIMS Risk & Remnant Life'), findsOneWidget);
    expect(find.textContaining('ASME B31.8S / API 1160'), findsWidgets);

    // Verify Global Stats Header
    expect(find.textContaining('OIL INDIA 18" X70 TRUNKLINE'), findsOneWidget);
    expect(find.text('MONITORED'), findsOneWidget);
    expect(find.text('CRITICAL / HIGH'), findsOneWidget);
    expect(find.text('MAX ERF'), findsOneWidget);
    expect(find.text('ACTIVE DIGS'), findsOneWidget);

    // Verify Tabs
    expect(find.text('5x5 Risk Matrix & QRA'), findsOneWidget);
    expect(find.text('Remnant Strength & MAOP'), findsOneWidget);
    expect(find.text('Remnant Life & ILI Cycle'), findsOneWidget);
    expect(find.text('Critical Dig Repair Orders'), findsOneWidget);

    // Verify 5x5 Matrix content
    expect(find.text('5x5 QUANTITATIVE RISK MATRIX'), findsOneWidget);
    expect(find.textContaining('PROBABILITY (PoF)'), findsOneWidget);
    expect(find.textContaining('CONSEQUENCE OF FAILURE (CoF)'), findsOneWidget);

    // Switch to Remnant Strength & MAOP tab
    await tester.tap(find.text('Remnant Strength & MAOP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('MODIFIED B31G & RSTRENG CALCULATOR'), findsOneWidget);
    expect(find.text('MODIFIED B31G (0.85dL)'), findsOneWidget);
    expect(find.text('RSTRENG (EFF. AREA)'), findsOneWidget);
    expect(find.textContaining('DEFECT WALL-LOSS CROSS SECTION'), findsOneWidget);

    // Switch to Remnant Life & ILI Cycle tab
    await tester.tap(find.text('Remnant Life & ILI Cycle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('REMNANT LIFE & RE-ASSESSMENT INTERVAL'), findsOneWidget);
    expect(find.text('ACTIVE CORROSION GROWTH RATE (CGR)'), findsOneWidget);
    expect(find.textContaining('WALL DEGRADATION PROJECTION'), findsOneWidget);

    // Switch to Critical Dig Repair Orders tab
    await tester.tap(find.text('Critical Dig Repair Orders'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('CRITICAL DIG REPAIR SCHEDULE'), findsOneWidget);
    expect(find.text('ASME PCC-2 REPAIR SELECTION STANDARD'), findsOneWidget);
    expect(find.text('DIG-2026-001'), findsOneWidget);
    expect(find.text('DIG-2026-002'), findsOneWidget);
  });
}
