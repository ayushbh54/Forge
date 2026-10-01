import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/screens/contracts/variation_order_screen.dart';

void main() {
  testWidgets('VariationOrderScreen renders all 6 baseline variations and summary stats',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const VariationOrderScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('FIDIC Cl. 13 Variations'), findsOneWidget);
    expect(find.text('Scope Change Management & Register'), findsOneWidget);

    // Verify Executive Summary Dashboard
    expect(find.text('VARIATION REGISTER OVERVIEW'), findsOneWidget);
    expect(find.text('6 Change Orders'), findsOneWidget);
    expect(find.text('+₹18.95 Cr'), findsOneWidget); // Cumulative cost
    expect(find.text('+92 Days'), findsOneWidget); // Cumulative EOT

    // Verify FIDIC 15% Threshold Banner
    expect(find.text('FIDIC Cl. 12/13 Cumulative Variation Cap (15%)'), findsOneWidget);

    // Verify all baseline Variation Orders (VO-2026-01 to VO-2026-06)
    expect(find.text('VO-2026-01'), findsOneWidget);
    expect(find.text('VO-2026-02'), findsOneWidget);
    expect(find.text('VO-2026-03'), findsOneWidget);
    expect(find.text('VO-2026-04'), findsOneWidget);
    expect(find.text('VO-2026-05'), findsOneWidget);
    expect(find.text('VO-2026-06'), findsOneWidget);

    // Verify specific VO details
    // VO-01: +₹4.20 Cr, +21 Days EOT, FIDIC 13.1
    expect(find.text('+₹4.20 Cr'), findsOneWidget);
    expect(find.text('+21 Days EOT'), findsOneWidget);
    expect(find.text('FIDIC Cl. 13.1 (Right to Vary) & 13.3'), findsOneWidget);
    expect(find.text('CLIENT SANCTIONED'), findsNWidgets(2)); // VO-01 and VO-02

    // Verify Approval workflow stages present
    expect(find.text('ENGINEER REVIEWED'), findsNWidgets(2)); // VO-03 and VO-04
    expect(find.text('INITIATED'), findsNWidgets(2)); // VO-05 and VO-06

    // Verify Reasons
    expect(find.text('Unforeseen geological strata'), findsWidgets);
    expect(find.text('Client design modification'), findsWidgets);
  });

  testWidgets('Filter chips filter variation orders accurately',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const VariationOrderScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Sanctioned filter chip
    await tester.tap(find.text('Sanctioned (2)'));
    await tester.pumpAndSettle();

    expect(find.text('VO-2026-01'), findsOneWidget);
    expect(find.text('VO-2026-02'), findsOneWidget);
    expect(find.text('VO-2026-03'), findsNothing);
    expect(find.text('VO-2026-04'), findsNothing);
    expect(find.text('VO-2026-05'), findsNothing);
    expect(find.text('VO-2026-06'), findsNothing);

    // Tap Initiated filter chip
    await tester.tap(find.text('Initiated (2)'));
    await tester.pumpAndSettle();

    expect(find.text('VO-2026-01'), findsNothing);
    expect(find.text('VO-2026-05'), findsOneWidget);
    expect(find.text('VO-2026-06'), findsOneWidget);
  });

  testWidgets('New Variation Request modal can be opened and submitted',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const VariationOrderScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Floating Action Button to open form
    final fabFinder = find.byType(FloatingActionButton);
    expect(fabFinder, findsOneWidget);
    await tester.tap(fabFinder);
    await tester.pumpAndSettle();

    // Verify Form Header & Generated ID
    expect(find.text('New Variation Request'), findsAtLeastNWidgets(1));
    expect(find.text('VO-2026-07'), findsOneWidget);
    expect(find.text('REASON FOR VARIATION *'), findsOneWidget);
    expect(find.text('SCOPE DESCRIPTION & SITE JUSTIFICATION *'), findsOneWidget);
    expect(find.text('ESTIMATED COST (₹ CR) *'), findsOneWidget);
    expect(find.text('ESTIMATED TIME (DAYS EOT) *'), findsOneWidget);

    // In modal, find text fields within the Form
    final modalForm = find.byType(Form);
    final formFields = find.descendant(of: modalForm, matching: find.byType(TextField));
    // title: index 0 inside the modal form
    await tester.enterText(
      formFields.at(0),
      'River Embankment Sheet Piling & Scour Protection',
    );

    // scope: index 1
    await tester.enterText(
      formFields.at(1),
      'High velocity scouring observed along southern bank of river crossing. Sheet piling required.',
    );

    // cost: index 2
    await tester.enterText(formFields.at(2), '2.50');

    // time: index 3
    await tester.enterText(formFields.at(3), '12');

    await tester.pumpAndSettle();

    // Tap submit button
    final submitBtn = find.text('Submit FIDIC Cl. 13 Variation Proposal');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Verify modal is closed and VO-2026-07 is present in list
    expect(find.text('VO-2026-07'), findsOneWidget);
    expect(find.text('River Embankment Sheet Piling & Scour Protection'), findsOneWidget);
    expect(find.text('+₹2.50 Cr'), findsAtLeastNWidgets(1));
    expect(find.text('+12 Days EOT'), findsOneWidget);

    // Total change orders count should be updated to 7
    expect(find.text('7 Change Orders'), findsOneWidget);
  });
}
