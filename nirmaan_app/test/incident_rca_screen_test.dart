import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/safety/incident_rca_screen.dart';

void main() {
  testWidgets('IncidentRcaScreen mounts and renders header, metrics, and tabs',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: IncidentRcaScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Statutory Badges
    expect(find.text('Incident Investigation & RCA'), findsOneWidget);
    expect(find.text('OISD-GDN-107'), findsOneWidget);
    expect(find.text('DGMS FORM IV'), findsOneWidget);

    // Verify 24-Hr DGMS SLA Banner
    expect(find.textContaining('DGMS'), findsWidgets);
    expect(find.textContaining('REMAINING'), findsWidgets);

    // Verify Executive Metrics Strip
    expect(find.text('INCIDENTS'), findsOneWidget);
    expect(find.text('LTI CASES'), findsOneWidget);
    expect(find.text('HIPO NEAR-HITS'), findsOneWidget);
    expect(find.text('OPEN CAPAs'), findsOneWidget);
    expect(find.text('VAULT SEALS'), findsOneWidget);

    // Verify 5 Navigation Tabs
    expect(find.textContaining('Incident Log'), findsWidgets);
    expect(find.textContaining('5-Whys Tree'), findsOneWidget);
    expect(find.textContaining('6M Fishbone'), findsOneWidget);
    expect(find.textContaining('CAPA Matrix'), findsOneWidget);
    expect(find.textContaining('Evidence Vault'), findsOneWidget);

    // Verify Tab 1 contents (Incident Log)
    expect(find.text('LOG INCIDENT'), findsOneWidget);
    expect(find.text('All Events'), findsOneWidget);
    expect(find.textContaining('INC-2026-0491'), findsWidgets);
    expect(find.textContaining('INC-2026-0382'), findsWidgets);
    expect(find.textContaining('INC-2026-0219'), findsWidgets);
  });

  testWidgets('Incident filter chips filter the incident log list',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: IncidentRcaScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Initially all 3 incidents are visible
    expect(find.textContaining('INC-2026-0491'), findsWidgets);
    expect(find.textContaining('INC-2026-0382'), findsWidgets);
    expect(find.textContaining('INC-2026-0219'), findsWidgets);

    // Tap 'Lost Time (LTI)' filter chip
    await tester.tap(find.text('Lost Time (LTI)'));
    await tester.pumpAndSettle();

    // Now only INC-2026-0491 should be displayed
    expect(find.textContaining('INC-2026-0491'), findsWidgets);
    expect(find.textContaining('INC-2026-0382'), findsNothing);
    expect(find.textContaining('INC-2026-0219'), findsNothing);

    // Tap 'All Events' filter chip
    await tester.tap(find.text('All Events'));
    await tester.pumpAndSettle();

    // All should be visible again
    expect(find.textContaining('INC-2026-0491'), findsWidgets);
    expect(find.textContaining('INC-2026-0382'), findsWidgets);
  });

  testWidgets('5-Whys Root Cause Tree renders progressive nodes and summary',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: IncidentRcaScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap 5-Whys Tree Tab
    await tester.tap(find.textContaining('5-Whys Tree'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify 5-Whys header & buttons
    expect(find.text('5-WHYS ROOT CAUSE INVESTIGATION ENGINE'), findsOneWidget);
    expect(find.text('ADD WHY'), findsOneWidget);

    // Verify Why nodes
    expect(find.text('W1'), findsOneWidget);
    expect(find.text('W2'), findsOneWidget);
    expect(find.text('W3'), findsOneWidget);
    expect(find.text('W4'), findsOneWidget);
    expect(find.text('W5'), findsOneWidget);

    // Verify Root Cause tag & summary box
    expect(find.textContaining('VALIDATED STATUTORY ROOT CAUSE'), findsOneWidget);
    expect(find.text('SYSTEMIC ROOT CAUSE CONCLUSION'), findsOneWidget);
  });

  testWidgets('6M Fishbone / Ishikawa tab renders bone matrix and factors',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: IncidentRcaScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap 6M Fishbone Tab
    await tester.tap(find.textContaining('6M Fishbone'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Fishbone header
    expect(find.text('ISHIKAWA 6M CAUSE-AND-EFFECT ENGINE'), findsOneWidget);
    expect(find.text('ATTACH FACTOR'), findsOneWidget);
    expect(find.text('INCIDENT EVENT'), findsOneWidget);

    // Verify 6M Category Bones
    expect(find.text('MAN'), findsWidgets);
    expect(find.text('MACHINE'), findsWidgets);
    expect(find.text('METHOD'), findsWidgets);
    expect(find.text('MATERIAL'), findsWidgets);
    expect(find.text('MEASUREMENT'), findsWidgets);
    expect(find.text('MILIEU'), findsWidgets);

    // Tap Machine category bone to switch inspection
    await tester.tap(find.text('Machine').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('MACHINE (EQUIPMENT)'), findsOneWidget);
    expect(find.textContaining('PSV-102 Spindle Seized by Sludge'), findsOneWidget);
  });

  testWidgets('CAPA Matrix renders action items and status updates',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: IncidentRcaScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap CAPA Matrix Tab
    await tester.tap(find.textContaining('CAPA Matrix'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify CAPA header & buttons
    expect(find.text('CAPA ACTION TRACKER & STATUTORY CONTROLS'), findsOneWidget);
    expect(find.text('NEW CAPA'), findsOneWidget);
    expect(find.text('CAPA IMPLEMENTATION VELOCITY'), findsOneWidget);

    // Verify CAPA items
    expect(find.textContaining('CAPA-2026-0881'), findsOneWidget);
    expect(find.textContaining('Enforce Digital MOC Quarantine Interlock in PTW'), findsOneWidget);
    expect(find.textContaining('PREVENTIVE ACTION'), findsWidgets);
    expect(find.textContaining('3. Engineering Controls'), findsWidgets);

    // Toggle CAPA status from IN PROGRESS to CLOSED
    await tester.tap(find.text('IN PROGRESS').first);
    await tester.pumpAndSettle();

    expect(find.text('CLOSED'), findsWidgets);
  });

  testWidgets('Evidence Vault renders SHA-256 custody seals and lab metadata',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: IncidentRcaScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Evidence Vault Tab
    await tester.tap(find.textContaining('Evidence Vault'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Evidence Vault header
    expect(find.text('FORENSIC EVIDENCE VAULT & LAB AUDIT'), findsOneWidget);
    expect(find.text('DEPOSIT EVIDENCE'), findsOneWidget);

    // Verify Evidence records
    expect(find.text('EVD-2026-104'), findsOneWidget);
    expect(find.text('EVD-2026-105'), findsOneWidget);
    expect(find.textContaining('CSIR-NML Metallurgical Fractography Report'), findsOneWidget);
    expect(find.textContaining('SHA-256: '), findsWidgets);
    expect(find.textContaining('SEAL-DGMS-0941'), findsOneWidget);
    expect(find.textContaining('Vickers Hardness (HV)'), findsOneWidget);
  });

  testWidgets('DGMS Notice Dispatch dialog opens and executes Form IV-A dispatch',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: IncidentRcaScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Find and tap 'DISPATCH NOTICE' in top statutory banner
    expect(find.text('DISPATCH NOTICE'), findsOneWidget);
    await tester.tap(find.text('DISPATCH NOTICE'));
    await tester.pumpAndSettle();

    // Verify Form IV-A Dialog
    expect(find.text('DGMS FORM IV-A DISPATCH'), findsOneWidget);
    expect(find.textContaining('Statutory Authority'), findsOneWidget);
    expect(find.textContaining('Regulation 91 of OMR 2017'), findsOneWidget);

    // Execute dispatch
    await tester.tap(find.text('DISPATCH & SEAL FORM IV-A'));
    await tester.pumpAndSettle();

    // Dialog dismissed and banner updated to COMPLIED
    expect(find.text('DGMS FORM IV-A DISPATCH'), findsNothing);
    expect(find.textContaining('COMPLIED: Form IV-A Filed'), findsOneWidget);
  });

  testWidgets('OISD Investigation Dossier export modal opens and exports',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: IncidentRcaScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap FAB or AppBar Export button
    await tester.tap(find.text('OISD DOSSIER'));
    await tester.pumpAndSettle();

    // Verify Modal
    expect(find.text('EXPORT OISD-GDN-107 INVESTIGATION DOSSIER'), findsOneWidget);
    expect(find.textContaining('Preliminary Incident Report (PIR - 24 Hr)'), findsOneWidget);
    expect(find.textContaining('Root Cause Analysis Complete Package'), findsOneWidget);

    // Tap Generate
    await tester.tap(find.text('GENERATE SIGNED OISD-107 PDF DOSSIER'));
    await tester.pumpAndSettle();

    // Modal dismissed
    expect(find.text('EXPORT OISD-GDN-107 INVESTIGATION DOSSIER'), findsNothing);
  });
}
