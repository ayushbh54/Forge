import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/operations/gas_chromatography_screen.dart';

void main() {
  testWidgets('GasChromatographyScreen mounts, verifies 14-components and tariff billing',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: GasChromatographyScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Standards
    expect(find.text('Gas Chromatography & Quality Billing'), findsOneWidget);
    expect(find.textContaining('ISO 6974 / GPA 2261'), findsWidgets);

    // Verify Stream Selector Chips
    expect(find.text('GC-01'), findsOneWidget);
    expect(find.text('Duliajan Trunk'), findsOneWidget);
    expect(find.text('GC-02'), findsOneWidget);
    expect(find.text('Digboi Offtake'), findsOneWidget);

    // Verify Tab Headers
    expect(find.text('14-Component Mol%'), findsOneWidget);
    expect(find.text('Quality Parameters'), findsOneWidget);
    expect(find.text('Chromatogram & HW'), findsOneWidget);
    expect(find.text('MMBTU Gas Tariff'), findsOneWidget);

    // Verify 14-Component Tab contents
    expect(find.text('14-COMPONENT MOLAR COMPOSITION'), findsOneWidget);
    expect(find.text('Methane'), findsOneWidget);
    expect(find.text('Ethane'), findsOneWidget);
    expect(find.text('Propane'), findsOneWidget);
    expect(find.text('Iso-Butane'), findsOneWidget);
    expect(find.text('Normal-Butane'), findsOneWidget);
    expect(find.text('Hexanes & Heavier'), findsOneWidget);

    // Switch to Quality Parameters Tab
    await tester.tap(find.text('Quality Parameters'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Gross Calorific Value (GCV)'), findsOneWidget);
    expect(find.text('Net Calorific Value (NCV)'), findsOneWidget);
    expect(find.text('Gross Wobbe Index (Ws)'), findsOneWidget);
    expect(find.text('Hydrocarbon Dew Point'), findsOneWidget);
    expect(find.text('PNGRB Gas Transmission Quality Compliance'), findsOneWidget);

    // Switch to Chromatogram Tab
    await tester.tap(find.text('Chromatogram & HW'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('PROCESS CHROMATOGRAM'), findsOneWidget);
    expect(find.text('Oven Isothermal Temp'), findsOneWidget);
    expect(find.text('Helium Carrier Gas'), findsOneWidget);

    // Switch to MMBTU Gas Tariff Tab
    await tester.tap(find.text('MMBTU Gas Tariff'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('OIL INDIA CONTRACTED CONSUMER (GSPA)'), findsOneWidget);
    expect(find.text('BILLING VOLUME (SCM)'), findsOneWidget);
    expect(find.text('COMMERCIAL TARIFF & RECONCILIATION SUMMARY'), findsOneWidget);
    expect(find.text('VIEW & RECONCILE GSPA TAX INVOICE'), findsOneWidget);
  });
}
