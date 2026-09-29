import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/providers/app_provider.dart';
import 'package:nirmaan_app/screens/materials/weighbridge_ticket_screen.dart';

void main() {
  testWidgets('WeighbridgeTicketScreen mounts and calculates Net Weight properly', (WidgetTester tester) async {
    final appProvider = AppProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppProvider>.value(value: appProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const WeighbridgeTicketScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Weighbridge & Challan Verification'), findsOneWidget);
    expect(find.text('Nirmaan OS Inbound Logistics Engine'), findsOneWidget);

    // Verify Unit Selector pills exist
    expect(find.text('MT'), findsWidgets);
    expect(find.text('Qtl'), findsWidgets);

    // Verify Net Material Card exists
    expect(find.text('NET MATERIAL DELIVERED'), findsOneWidget);

    // Verify Gate Pass Details section
    expect(find.text('INBOUND GATE PASS & LOGISTICS'), findsOneWidget);
    expect(find.text('AS-06-BC-4129'), findsOneWidget);

    // Verify Action Bar button
    expect(find.text('Generate GRN'), findsOneWidget);
  });

  testWidgets('WeighbridgeTicketScreen switches tabs and displays DC reconciliation', (WidgetTester tester) async {
    final appProvider = AppProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppProvider>.value(value: appProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const WeighbridgeTicketScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on Reconciliation Tab
    await tester.tap(find.text('Reconciliation'));
    await tester.pumpAndSettle();

    // Verify Reconciliation card headers
    expect(find.text('DELIVERY CHALLAN RECONCILIATION'), findsOneWidget);
    expect(find.text('Tolerance Variance Deviation'), findsOneWidget);
    expect(find.text('Financial Discrepancy'), findsOneWidget);

    // Tap on Ticket Registry Tab
    await tester.tap(find.text('Ticket Registry'));
    await tester.pumpAndSettle();

    // Verify Registry Tab elements
    expect(find.text('All Tickets (3)'), findsOneWidget);
    expect(find.text('Within Tolerance'), findsOneWidget);
    expect(find.text('Shortage Alerts'), findsOneWidget);
    expect(find.text('GRN Issued'), findsOneWidget);
  });
}
