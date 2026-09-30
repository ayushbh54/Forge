import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/screens/procurement/pipe_heat_tally_screen.dart';

void main() {
  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: const PipeHeatTallyScreen(),
    );
  }

  testWidgets('PipeHeatTallyScreen mounts and renders header, KPIs, and registry tab', (WidgetTester tester) async {
    // Set a tablet/desktop size to avoid overflow issues during test
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify AppBar Title & Subtitle
    expect(find.text('Pipe Heat Tally & Traceability'), findsOneWidget);
    expect(find.text('API Spec 5L PSL-2 / ISO 3183 • Oil India Limited'), findsOneWidget);
    expect(find.text('EN 10204 3.2'), findsOneWidget);

    // Verify KPI Metrics Strip
    expect(find.text('TOTAL PIPES'), findsOneWidget);
    expect(find.text('STRUNG / WELDED'), findsOneWidget);
    expect(find.text('YARD STOCK'), findsOneWidget);
    expect(find.text('HEAVY WALL'), findsOneWidget);

    // Verify 4 Tab Titles
    expect(find.text('Pipe Tally Registry'), findsOneWidget);
    expect(find.text('MTC EN 10204 (3.2)'), findsOneWidget);
    expect(find.text('Scan & Pup Tracking'), findsOneWidget);
    expect(find.text('Yard Stock Reconcile'), findsOneWidget);

    // Verify Pipe Registry Cards
    expect(find.text('OIL-24-X70-1001'), findsOneWidget);
    expect(find.text('OIL-24-X70-1002'), findsOneWidget);
    expect(find.text('H-89412'), findsWidgets);
    expect(find.text('CL-5501A'), findsWidgets);

    // Verify Floating Action Button
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Add Pipe'), findsOneWidget);
  });

  testWidgets('PipeHeatTallyScreen filter chips and search filter pipe list', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Search for specific pipe ID
    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'OIL-24-X70-1006');
    await tester.pumpAndSettle();

    expect(find.text('OIL-24-X70-1006-HD'), findsOneWidget);
    expect(find.text('OIL-24-X70-1001'), findsNothing);

    // Clear search
    await tester.enterText(searchField, '');
    await tester.pumpAndSettle();
    expect(find.text('OIL-24-X70-1001'), findsOneWidget);

    // Tap 12.7mm River HDD filter chip
    await tester.tap(find.text('12.7mm River HDD'));
    await tester.pumpAndSettle();

    // Heavy wall pipes should be visible, 9.5mm mainline should be filtered out
    expect(find.text('OIL-24-X70-1006-HD'), findsOneWidget);
    expect(find.text('OIL-24-X70-1001'), findsNothing);
  });

  testWidgets('PipeHeatTallyScreen displays MTC EN 10204 (3.2) tab with chemical and mechanical data', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Switch to MTC Tab
    await tester.tap(find.text('MTC EN 10204 (3.2)'));
    await tester.pumpAndSettle();

    // Verify Specification Banner
    expect(find.text('EN 10204 Type 3.2 Dual Inspection'), findsOneWidget);
    expect(find.text('API 5L PSL-2 / ISO 3183 ACCEPTANCE CRITERIA:'), findsOneWidget);
    expect(find.text('Yield Strength (Rt0.5)'), findsOneWidget);
    expect(find.text('Tensile Strength (Rm)'), findsOneWidget);
    expect(find.text('Carbon Equiv (CE_Pcm)'), findsOneWidget);
    expect(find.text('Charpy V-Notch (CVN)'), findsOneWidget);

    // Verify Heat Batch Card
    expect(find.text('HEAT: H-89412'), findsOneWidget);
    expect(find.text('3.2 TPIA APPROVED'), findsWidgets);
    expect(find.text('LADLE CHEMICAL ANALYSIS (wt %):'), findsWidgets);
  });

  testWidgets('PipeHeatTallyScreen displays Scan & Pup Tracking tab with QR launcher and child pups', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Switch to Scan & Pup Tracking Tab
    await tester.tap(find.text('Scan & Pup Tracking'));
    await tester.pumpAndSettle();

    // Verify QR scan trigger card
    expect(find.text('Scan Pipe QR Tag / Stencil Barcode'), findsOneWidget);
    expect(find.text('Launch Optical Tag Scanner'), findsOneWidget);

    // Verify Pup Piece section
    expect(find.text('CUT-PIPE / PUP PIECE TRACKER'), findsOneWidget);
    expect(find.text('New Cut Pup'), findsOneWidget);
    expect(find.text('OIL-24-X70-1042-P1'), findsOneWidget);
    expect(find.text('STENCIL TRANSFERRED'), findsWidgets);
    expect(find.text('Burhi Dihing HDD Entry Tie-In Spool'), findsOneWidget);
  });

  testWidgets('PipeHeatTallyScreen displays Yard Stock Reconciliation tab with all 3 depots', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Switch to Yard Stock Reconcile Tab
    await tester.tap(find.text('Yard Stock Reconcile'));
    await tester.pumpAndSettle();

    // Verify dump yard cards
    expect(find.text('PIPE DUMP YARD RECONCILIATION'), findsOneWidget);
    expect(find.text('Inter-Yard Transfer'), findsOneWidget);
    expect(find.text('Duliajan Central Yard'), findsOneWidget);
    expect(find.text('Moran Intermediate Yard'), findsOneWidget);
    expect(find.text('Numaligarh Terminal Yard'), findsOneWidget);

    // Verify Stock Summary & Zero-Variance Audit
    expect(find.text('Corridor Steel Stock Summary'), findsOneWidget);
    expect(find.text('0 PIPES (100% RECONCILED)'), findsOneWidget);
  });
}
