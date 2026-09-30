import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/safety/ptw_live_screen.dart';

void main() {
  testWidgets('PtwLiveScreen mounts and renders header, metrics, and tabs',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PtwLiveScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Standards Badge
    expect(find.text('Permit to Work (PTW) Live'), findsOneWidget);
    expect(find.text('OISD-105'), findsWidgets);
    expect(find.textContaining('Oil India Duliajan'), findsWidgets);

    // Verify Emergency Stop Beacon button in AppBar
    expect(find.text('ESD BEACON'), findsOneWidget);

    // Verify Metrics Strip
    expect(find.text('ACTIVE'), findsWidgets);
    expect(find.text('ISSUED'), findsWidgets);
    expect(find.text('SUSPENDED'), findsWidgets);
    expect(find.text('MEN IN ZONE'), findsOneWidget);
    expect(find.text('LOTO PTS'), findsOneWidget);

    // Verify 4 Main Tabs
    expect(find.text('Live Permits'), findsOneWidget);
    expect(find.text('Atmospheric Gas Test'), findsOneWidget);
    expect(find.text('LOTO & Isolation'), findsOneWidget);
    expect(find.text('Compliance & Safety'), findsOneWidget);

    // Tab 1: Live Permits contents
    expect(find.text('All Permits'), findsOneWidget);
    expect(find.textContaining('HW/DUL/2026/0841'), findsWidgets);

    // Switch to Tab 2: Atmospheric Gas Test
    await tester.tap(find.text('Atmospheric Gas Test'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('PRE-TASK ATMOSPHERIC 4-GAS MONITOR'), findsOneWidget);
    expect(find.textContaining('Oxygen (O₂)'), findsWidgets);
    expect(find.textContaining('Flammable (LEL)'), findsWidgets);
    expect(find.textContaining('Hydrogen Sulfide (H₂S)'), findsWidgets);
    expect(find.textContaining('Carbon Monoxide (CO)'), findsWidgets);
    expect(find.textContaining('MULTI-GAS DETECTOR CALIBRATION RECORD'), findsOneWidget);
    expect(find.textContaining('FIELD GAS SAMPLING CONTROLS & LOGGING'), findsOneWidget);

    // Switch to Tab 3: LOTO & Isolation
    await tester.tap(find.text('LOTO & Isolation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('ENERGY ISOLATION CERTIFICATE (EIC)'), findsOneWidget);
    expect(find.textContaining('MASTER LOCKBOX KEY CUSTODY'), findsOneWidget);
    expect(find.textContaining('ADD POINT'), findsOneWidget);

    // Switch to Tab 4: Compliance & Safety
    await tester.tap(find.text('Compliance & Safety'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('EMERGENCY MUSTER POINT'), findsOneWidget);
    expect(find.textContaining('PRE-SHIFT TOOLBOX TALK (TBT) LOG'), findsOneWidget);
    expect(find.textContaining('OISD-STD-105 STATUTORY AUDIT CRITERIA'), findsOneWidget);
  });

  testWidgets('ESD Emergency Stop Beacon dialog can be opened and dismissed',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PtwLiveScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap ESD Beacon
    await tester.tap(find.text('ESD BEACON'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify dialog appears
    expect(find.text('SUPERVISOR EMERGENCY STOP'), findsOneWidget);
    expect(find.text('ABORT'), findsOneWidget);
    expect(find.text('EXECUTE EMERGENCY STOP'), findsOneWidget);

    // Tap ABORT
    await tester.tap(find.text('ABORT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dialog dismissed
    expect(find.text('SUPERVISOR EMERGENCY STOP'), findsNothing);
  });
}
