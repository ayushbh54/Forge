import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/screens/finance/measurement_book_screen.dart';

void main() {
  group('MeasurementBookScreen & e-MB Domain Unit Tests', () {
    test('MeasurementItem computes volume, linear and joint quantities accurately', () {
      // 1. Earthwork / Trenching in m³ (L x W x D x Multiplier)
      final trenching = MeasurementItem(
        id: 'TEST-001',
        itemNo: 'BoQ 2.01',
        boqDescription: 'Trenching excavation',
        section: 'Earthwork & Trenching',
        chainageFrom: 10.0,
        chainageTo: 11.0,
        length: 1000.0,
        width: 2.0,
        depth: 2.5,
        multiplier: 1,
        unit: 'm³',
        boqRate: 500.0,
        previousQty: 0.0,
        gpsCoords: '27.0° N, 95.0° E',
        measurementDate: DateTime(2026, 9, 20),
        surveyorName: 'Tester',
      );
      expect(trenching.measuredQty, equals(5000.0));
      expect(trenching.grossAmount, equals(2500000.0));
      expect(trenching.verifyHash(), isTrue);

      // 2. Stringing in linear Meters (Length x Multiplier)
      final stringing = MeasurementItem(
        id: 'TEST-002',
        itemNo: 'BoQ 3.02',
        boqDescription: 'Pipe stringing',
        section: 'Stringing & Bending',
        chainageFrom: 10.0,
        chainageTo: 11.0,
        length: 1000.0,
        width: 1.0,
        depth: 1.0,
        multiplier: 1,
        unit: 'Meter',
        boqRate: 1200.0,
        previousQty: 2000.0,
        gpsCoords: '27.0° N, 95.0° E',
        measurementDate: DateTime(2026, 9, 20),
        surveyorName: 'Tester',
      );
      expect(stringing.measuredQty, equals(1000.0));
      expect(stringing.upToDateQty, equals(3000.0));
      expect(stringing.grossAmount, equals(1200000.0));
      expect(stringing.verifyHash(), isTrue);

      // 3. Welding Butt Joints in Nos/Joints (Multiplier)
      final welding = MeasurementItem(
        id: 'TEST-003',
        itemNo: 'BoQ 4.05',
        boqDescription: 'Butt weld joints',
        section: 'Welding & NDT',
        chainageFrom: 10.0,
        chainageTo: 11.0,
        length: 1.0,
        width: 1.0,
        depth: 1.0,
        multiplier: 85,
        unit: 'Joint',
        boqRate: 15000.0,
        previousQty: 100.0,
        gpsCoords: '27.0° N, 95.0° E',
        measurementDate: DateTime(2026, 9, 20),
        surveyorName: 'Tester',
      );
      expect(welding.measuredQty, equals(85.0));
      expect(welding.grossAmount, equals(1275000.0));
      expect(welding.verifyHash(), isTrue);
    });

    test('Cryptographic SHA-256 detection detects tampering in payload', () {
      final item = MeasurementItem(
        id: 'TAMPER-001',
        itemNo: 'BoQ 2.01',
        boqDescription: 'Trenching',
        section: 'Earthwork & Trenching',
        chainageFrom: 12.0,
        chainageTo: 13.0,
        length: 500.0,
        width: 2.0,
        depth: 2.0,
        multiplier: 1,
        unit: 'm³',
        boqRate: 600.0,
        previousQty: 0.0,
        gpsCoords: '27.2° N, 95.3° E',
        measurementDate: DateTime(2026, 9, 15),
        surveyorName: 'Surveyor A',
      );

      final validDigest = item.sha256Digest;
      expect(item.verifyHash(), isTrue);

      // Simulate malicious tampering of digest
      item.sha256Digest = 'malicious_or_corrupted_hash_00000000000000000000000000000000';
      expect(item.verifyHash(), isFalse);

      // Restore
      item.sha256Digest = validDigest;
      expect(item.verifyHash(), isTrue);
    });
  });

  group('MeasurementBookScreen Widget Tests', () {
    testWidgets('MeasurementBookScreen mounts, renders KPI header, tabs and interactions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MeasurementBookScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Header & App Bar
      expect(find.text('e-MB & Progress Billing (RA Bills)'), findsOneWidget);
      expect(find.textContaining('CPWD Works Manual Form 23/26'), findsOneWidget);
      expect(find.text('OIL/DKPL-18/CIVIL-PL/2025/PKG-02'), findsOneWidget);
      expect(find.textContaining('RA Bill No. 07'), findsOneWidget);

      // 2. Verify Executive KPI Cards
      expect(find.text('GROSS RA BILL'), findsOneWidget);
      expect(find.text('TOTAL DEDUCTIONS'), findsOneWidget);
      expect(find.text('NET PAYABLE RELEASE'), findsOneWidget);

      // 3. Verify Tabs
      expect(find.text('e-MB Ledger (Form 23)'), findsOneWidget);
      expect(find.text('Tripartite Signatures'), findsOneWidget);
      expect(find.text('RA Bill Deductions (Form 26)'), findsOneWidget);
      expect(find.text('Immutable Audit Trail'), findsOneWidget);

      // 4. Tab 1: e-MB Ledger Content
      expect(find.text('BoQ 2.01'), findsOneWidget);
      expect(find.text('BoQ 3.02'), findsOneWidget);
      expect(find.text('BoQ 4.05'), findsOneWidget);
      expect(find.text('BoQ 7.02'), findsOneWidget);
      expect(find.textContaining('KM 12.450 - 14.820'), findsWidgets);
      expect(find.textContaining('DIMENSIONS:'), findsWidgets);

      // Tap on the first item to open Form 23 dimension detail sheet
      await tester.tap(find.text('BoQ 2.01'));
      await tester.pumpAndSettle();

      expect(find.text('CPWD FORM 23 DIMENSION MATRIX'), findsOneWidget);
      expect(find.text('IMMUTABLE SHA-256 RECORD HASH'), findsOneWidget);
      expect(find.textContaining('GPS Site Anchor:'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // 5. Tab 2: Switch to Tripartite Digital Signatures & Approvals
      await tester.tap(find.text('Tripartite Signatures'));
      await tester.pumpAndSettle();

      expect(find.text('3-TIER TRIPARTITE SIGN-OFF GOVERNANCE'), findsOneWidget);
      expect(find.text('LEVEL 1: CONTRACTOR PROJECT MANAGER'), findsOneWidget);
      expect(find.text('Er. Rajesh Sarma'), findsOneWidget);
      expect(find.text('LEVEL 2: THIRD PARTY INSPECTION AGENCY (TPIA)'), findsOneWidget);
      expect(find.text('Er. Debabrata Borah'), findsOneWidget);
      expect(find.text('LEVEL 3: OIL INDIA LTD ENGINEER-IN-CHARGE (EIC)'), findsOneWidget);
      expect(find.text('Er. Anupam Hazarika'), findsOneWidget);
      expect(find.text('PENDING EIC FINAL SANCTION'), findsWidgets);

      // Test EIC Approval action button
      expect(find.text('Sign & Sanction as EIC'), findsOneWidget);
      await tester.tap(find.text('Sign & Sanction as EIC'));
      await tester.pumpAndSettle();

      // Verify EIC Dialog
      expect(find.text('Level 3 EIC Statutory Sanction'), findsOneWidget);
      expect(find.textContaining('STATUTORY CERTIFICATION STATEMENT'), findsOneWidget);
      expect(find.text('DSC Token & USB Hardware Key'), findsOneWidget);
      expect(find.text('Digitally Sign & Sanction'), findsOneWidget);

      // Tap Digitally Sign & Sanction
      await tester.tap(find.text('Digitally Sign & Sanction'));
      await tester.pumpAndSettle();

      // Verify that EIC Status is now sanctioned
      expect(find.text('SANCTIONED & CERTIFIED'), findsOneWidget);

      // 6. Tab 3: Switch to RA Bill Deductions (Form 26)
      await tester.tap(find.text('RA Bill Deductions (Form 26)'));
      await tester.pumpAndSettle();

      expect(find.text('CPWD FORM 26: RUNNING ACCOUNT (RA) BILL'), findsOneWidget);
      expect(find.text('FINANCIAL LEDGER & BILL PARTICULARS'), findsOneWidget);
      expect(find.text('Gross Value of Work Executed (Current Bill)'), findsOneWidget);
      expect(find.textContaining('Goods & Services Tax (GST @ 18.0%)'), findsOneWidget);
      expect(find.textContaining('GST TDS @ 2.0%'), findsOneWidget);
      expect(find.textContaining('Income Tax TDS @ 2.0%'), findsOneWidget);
      expect(find.textContaining('Labor Welfare Cess @ 1.0%'), findsOneWidget);
      expect(find.textContaining('Mobilization Advance Recovery @ 10.0%'), findsOneWidget);
      expect(find.textContaining('Security Deposit / Retention Money @ 5.0%'), findsOneWidget);
      expect(find.text('NET CERTIFIED PAYABLE RELEASE'), findsOneWidget);

      // Check Statutory tax mandates
      expect(find.text('STATUTORY TAX MANDATES & CLEARANCES'), findsOneWidget);
      expect(find.text('GSTIN'), findsOneWidget);
      expect(find.text('PAN'), findsOneWidget);
      expect(find.text('BOCW'), findsOneWidget);
      expect(find.text('PF / ESI'), findsOneWidget);

      // 7. Tab 4: Switch to Immutable Audit Trail
      await tester.tap(find.text('Immutable Audit Trail'));
      await tester.pumpAndSettle();

      expect(find.text('IMMUTABLE CRYPTOGRAPHIC VERIFICATION'), findsOneWidget);
      expect(find.text('e-MB ITEM CRYPTOGRAPHIC DIGESTS (CURRENT RA BILL)'), findsOneWidget);
      expect(find.text('CHRONOLOGICAL AUDIT EVENT TRAIL'), findsOneWidget);

      // Tap Verify All
      expect(find.text('Verify All'), findsOneWidget);
      await tester.tap(find.text('Verify All'));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.textContaining('STATUS: ALL 8 ITEMS CRYPTOGRAPHICALLY VALID'), findsOneWidget);
    });
  });
}
