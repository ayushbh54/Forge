import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/operations/scada_telemetry_screen.dart';

void main() {
  testWidgets('ScadaTelemetryScreen mounts and renders VS-01 to VS-08 telemetry',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ScadaTelemetryScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Subtitle
    expect(find.text('Valve Station SCADA'), findsOneWidget);
    expect(find.textContaining('DNNPL-18 Trunkline'), findsOneWidget);

    // Verify Tab headers
    expect(find.text('Topology & Overview'), findsOneWidget);
    expect(find.text('Station Telemetry'), findsOneWidget);
    expect(find.text('ESDV & PST Testing'), findsOneWidget);
    expect(find.textContaining('LDS Leak Detection'), findsOneWidget);
    expect(find.text('Override & Audit Log'), findsOneWidget);

    // Verify Stations VS-01 through VS-08 exist in schematic/list
    expect(find.text('VS-01'), findsWidgets);
    expect(find.text('VS-02'), findsWidgets);
    expect(find.text('VS-03'), findsWidgets);
    expect(find.text('VS-08'), findsWidgets);

    // Switch to Station Telemetry tab
    await tester.tap(find.text('Station Telemetry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Upstream Pressure'), findsOneWidget);
    expect(find.text('Downstream Pressure'), findsOneWidget);
    expect(find.text('Natural Gas Flow'), findsOneWidget);
    expect(find.text('Gas Temperature'), findsOneWidget);

    // Switch to ESDV & PST Testing tab
    await tester.tap(find.text('ESDV & PST Testing'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Emergency Shutdown Valve'), findsOneWidget);
    expect(find.textContaining('Partial Stroke Testing'), findsOneWidget);
    expect(find.textContaining('SIL-3 Remote Closure Interlock'), findsOneWidget);

    // Switch to LDS Leak Detection tab
    await tester.tap(find.textContaining('LDS Leak Detection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Computational Pipeline Monitoring'), findsOneWidget);
    expect(find.textContaining('Acoustic Wave & Negative Pressure Wave'), findsOneWidget);

    // Switch to Override & Audit Log tab
    await tester.tap(find.text('Override & Audit Log'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('SCADA Valve Actuation & Override Protocol'), findsOneWidget);
    expect(find.textContaining('CRYPTOGRAPHIC SCADA AUDIT TRAIL'), findsOneWidget);
  });
}
