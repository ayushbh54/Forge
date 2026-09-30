import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/operations/scada_cybersecurity_screen.dart';

void main() {
  testWidgets(
      'ScadaCybersecurityScreen renders header, threat banner, tabs, and models',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ScadaCybersecurityScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Badges
    expect(find.text('SCADA Cyber-Security'), findsOneWidget);
    expect(find.text('IEC 62443 SL-3'), findsOneWidget);
    expect(
        find.text('Critical National Infrastructure (CNI) OT Defense Shield'),
        findsOneWidget);

    // Verify Threat Status Banner & DEFCON indicator
    expect(find.textContaining('THREATCON: ELEVATED'), findsOneWidget);
    expect(find.textContaining('6h Clock:'), findsOneWidget);

    // Verify 4 Main Navigation Tabs
    expect(find.text('Zones & Conduits'), findsOneWidget);
    expect(find.text('Protocol DPI & Threat'), findsOneWidget);
    expect(find.text('Remote RTUs & MitM'), findsOneWidget);
    expect(find.text('CERT-In Compliance'), findsOneWidget);

    // Tab 1: Purdue OT Architecture & Conduits
    expect(find.textContaining('PURDUE OT/ICS SEGMENTATION'), findsOneWidget);
    expect(find.textContaining('Process Instrumentation Zone'), findsOneWidget);
    expect(find.textContaining('Basic Control & RTU Substation'), findsOneWidget);
    expect(find.textContaining('Supervisory SCADA & Control Room'), findsOneWidget);
    expect(find.textContaining('SECURED INTER-ZONE CONDUITS & DATA DIODES'),
        findsOneWidget);
    expect(find.text('1-WAY HARDWARE DIODE'), findsOneWidget);

    // Switch to Tab 2: Protocol DPI & Threat Mitigation
    await tester.tap(find.text('Protocol DPI & Threat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Modbus TCP Function Code Enforcement Active'),
        findsOneWidget);
    expect(find.textContaining('24H PACKET INSPECTION & BLOCKED ATTACKS'),
        findsOneWidget);
    expect(find.text('MODBUS TCP (0x05/0x0F)'), findsOneWidget);
    expect(find.text('DNP3 SAv5'), findsWidgets);
    expect(find.text('IEC 60870-5-104'), findsOneWidget);
    expect(find.textContaining('Coil Force 0x05'), findsWidgets);

    // Switch to Tab 3: Remote RTU Links & MitM Defense
    await tester.tap(find.text('Remote RTUs & MitM'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('VALVE STATION SATELLITE / CELLULAR RTU NODES'),
        findsOneWidget);
    expect(find.text('VS-01'), findsOneWidget);
    expect(find.text('VS-03'), findsOneWidget);
    expect(find.text('VS-04'), findsOneWidget);
    expect(find.textContaining('IMSI Catcher'), findsWidgets);
    expect(find.textContaining('GNSS PTP Clock'), findsWidgets);
    expect(find.textContaining('802.1X Port Guard'), findsWidgets);

    // Switch to Tab 4: CERT-In Compliance Workbench
    await tester.tap(find.text('CERT-In Compliance'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
        find.textContaining('CERT-In Cyber Security Directions (Rule 20(5))'),
        findsOneWidget);
    expect(find.textContaining('CERT-IN 6-HOUR MANDATORY NOTIFICATION WORKBENCH'),
        findsOneWidget);
    expect(find.text('INC-2026-OT-088'), findsOneWidget);
    expect(find.textContaining('IEC 62443 Foundational Requirements'),
        findsOneWidget);
    expect(find.textContaining('CRITICAL INFRASTRUCTURE DEFENSE PLAYBOOKS'),
        findsOneWidget);
  });
}
