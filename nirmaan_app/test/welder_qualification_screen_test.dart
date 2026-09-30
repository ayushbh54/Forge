import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/screens/quality/welder_qualification_screen.dart';

void main() {
  group('Welder Qualification Domain Models & Enums Unit Tests', () {
    test('WeldingProcessTypeExt returns correct names, electrodes, and colors', () {
      expect(WeldingProcessType.smawCellulosic.displayName, 'SMAW Cellulosic Downhill');
      expect(WeldingProcessType.smawCellulosic.shortName, 'SMAW');
      expect(WeldingProcessType.smawCellulosic.electrodeClass, contains('E6010'));

      expect(WeldingProcessType.gmawStt.displayName, contains('GMAW STT'));
      expect(WeldingProcessType.gmawStt.shortName, 'GMAW STT');
      expect(WeldingProcessType.gmawStt.electrodeClass, contains('ER70S-6'));

      expect(WeldingProcessType.gtawTig.displayName, contains('GTAW TIG'));
      expect(WeldingProcessType.gtawTig.shortName, 'GTAW TIG');
      expect(WeldingProcessType.gtawTig.electrodeClass, contains('99.995% Ar'));

      expect(WeldingProcessType.fcawGas.shortName, 'FCAW');
      expect(WeldingProcessType.sawDoubleJoint.shortName, 'SAW');
      expect(WeldingProcessType.sawDoubleJoint.color, isA<Color>());
    });

    test('QualifiedPositionExt returns valid positions and descriptions', () {
      expect(QualifiedPosition.pos5G.code, '5G Fixed');
      expect(QualifiedPosition.pos5G.description, contains('Horizontal pipe fixed'));

      expect(QualifiedPosition.pos6G.code, '6G Inclined 45°');
      expect(QualifiedPosition.pos6G.description, contains('All positions qualified'));

      expect(QualifiedPosition.pos6GR.code, '6GR Restricted');
      expect(QualifiedPosition.pos6GR.description, contains('restriction ring'));

      expect(QualifiedPosition.pos1G2G.code, '1G / 2G Rolled');
    });

    test('WelderStatusExt labels and colors', () {
      expect(WelderStatus.active.label, 'ACTIVE');
      expect(WelderStatus.renewalDue.label, 'RENEWAL DUE');
      expect(WelderStatus.suspended.label, 'SUSPENDED');
      expect(WelderStatus.expired.label, 'EXPIRED');

      expect(WelderStatus.active.color, const Color(0xFF4EDEA3));
      expect(WelderStatus.renewalDue.color, const Color(0xFFFFB95F));
      expect(WelderStatus.suspended.color, const Color(0xFFFF5252));
      expect(WelderStatus.active.icon, Icons.verified_user_rounded);
    });

    test('WelderQualificationRecord repair rate and 6-month continuity calculations', () {
      final now = DateTime.now();
      final record = WelderQualificationRecord(
        welderId: 'WLD-TEST-001',
        name: 'Test Welder',
        stampId: 'TW-001',
        contractor: 'Test Contractor',
        process: WeldingProcessType.smawCellulosic,
        position: QualifiedPosition.pos5G,
        diameterRange: '>= 12.75"',
        thicknessRange: '4.8mm to 25.4mm',
        standard: 'API 1104 Cl. 6',
        pqrReference: 'PQR-TEST-01',
        qualifiedWps: 'WPS-TEST-01',
        rtResult: NdtTestStatus.accepted,
        rtDetails: 'RT Class 1 Pass',
        autResult: NdtTestStatus.accepted,
        autDetails: 'AUT Zonal Pass',
        bendTestResult: NdtTestStatus.accepted,
        bendTestDetails: '4x Guided Bend Pass',
        nickBreakResult: NdtTestStatus.accepted,
        cumulativeJoints: 200,
        repairedJoints: 3,
        lastWeldDate: now.subtract(const Duration(days: 10)),
        qualificationDate: now.subtract(const Duration(days: 100)),
        status: WelderStatus.active,
        tpiaInspector: 'Test Inspector',
        clientEngineer: 'Test Engineer',
        verificationHash: 'TESTHASH1234',
      );

      // Repair rate = (3 / 200) * 100 = 1.5%
      expect(record.repairRate, closeTo(1.5, 0.001));

      // 6-Month continuity = lastWeldDate + 180 days
      final expectedExpiry = now.subtract(const Duration(days: 10)).add(const Duration(days: 180));
      expect(record.continuityExpiryDate.day, expectedExpiry.day);
      expect(record.daysUntilExpiry, closeTo(170, 1));
    });
  });

  group('WelderQualificationScreen Widget Tests', () {
    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: const WelderQualificationScreen(),
      );
    }

    testWidgets('WelderQualificationScreen mounts and displays title and top KPI strip', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify AppBar Title & Standards Subtitle
      expect(find.text('Welder & WPS Registry'), findsOneWidget);
      expect(find.textContaining('API 1104 (22nd Ed) / ASME Sec IX'), findsOneWidget);

      // Verify Top Executive Summary Strip Metrics
      expect(find.text('QUALIFIED WELDERS'), findsOneWidget);
      expect(find.text('FLEET REPAIR RATE'), findsOneWidget);
      expect(find.text('WPS PROCEDURES'), findsOneWidget);
      expect(find.text('EXPIRY / CONTINUITY'), findsOneWidget);

      // Verify 4 Tabs
      expect(find.textContaining('Welder Roster'), findsOneWidget);
      expect(find.textContaining('WPS Register'), findsOneWidget);
      expect(find.textContaining('NDT & Bend Quals'), findsOneWidget);
      expect(find.text('KPIs & Continuity'), findsOneWidget);

      // Verify Action buttons in AppBar
      expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('Welder Roster displays cards and search filtering works correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Check for welders in initial roster
      expect(find.text('Rajeshwar Sharma'), findsOneWidget);
      expect(find.text('Gurpreet Singh'), findsOneWidget);
      expect(find.text('Bikram Bora'), findsOneWidget);

      // Find search field and enter 'Gurpreet'
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Gurpreet');
      await tester.pumpAndSettle();

      // Gurpreet Singh should be found, Rajeshwar Sharma filtered out
      expect(find.text('Gurpreet Singh'), findsOneWidget);
      expect(find.text('Rajeshwar Sharma'), findsNothing);

      // Clear search
      final clearButton = find.byIcon(Icons.clear_rounded);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // All welders restored
      expect(find.text('Rajeshwar Sharma'), findsOneWidget);
      expect(find.text('Gurpreet Singh'), findsOneWidget);
    });

    testWidgets('Tapping welder card opens WPQ detail sheet with certificate and NDT tests', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on Rajeshwar Sharma card
      final welderCard = find.text('Rajeshwar Sharma');
      await tester.tap(welderCard);
      await tester.pumpAndSettle();

      // Verify BottomSheet header & Certificate
      expect(find.text('WELDER PERFORMANCE QUALIFICATION (WPQ)'), findsOneWidget);
      expect(find.text('Governing Standard'), findsOneWidget);
      expect(find.text('API 1104 (22nd Ed) Cl. 6'), findsWidgets);

      // Scroll to view NDT & Mechanical evaluation section
      await tester.scrollUntilVisible(
        find.text('QUALIFICATION COUPON NDT & MECHANICAL EVALUATION'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('QUALIFICATION COUPON NDT & MECHANICAL EVALUATION'), findsOneWidget);
      expect(find.text('Radiography (RT Class 1)'), findsOneWidget);
      expect(find.text('Automated Ultrasonic Testing (AUT)'), findsOneWidget);

      // Scroll to view Log Joint button
      await tester.scrollUntilVisible(
        find.text('LOG CONTINUITY JOINT & RENEW 6-MONTHS'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('LOG CONTINUITY JOINT & RENEW 6-MONTHS'), findsOneWidget);

      // Tap Log Joint button
      await tester.tap(find.text('LOG CONTINUITY JOINT & RENEW 6-MONTHS'));
      await tester.pumpAndSettle();

      // Verify SnackBar confirmation appeared
      expect(find.textContaining('Continuity logged for Rajeshwar Sharma'), findsOneWidget);
    });

    testWidgets('Switching to WPS Register tab displays procedures and opens detail view', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on WPS Register Tab
      final wpsTab = find.textContaining('WPS Register');
      await tester.tap(wpsTab);
      await tester.pumpAndSettle();

      // Verify WPS procedures
      expect(find.text('WPS-OIL-SMAW-01'), findsOneWidget);
      expect(find.text('WPS-OIL-GTAW-SMAW-02'), findsOneWidget);

      // Tap on WPS-OIL-SMAW-01 card
      await tester.tap(find.text('WPS-OIL-SMAW-01'));
      await tester.pumpAndSettle();

      // Verify Joint and Material card in bottom sheet
      expect(find.text('Base Metal'), findsOneWidget);

      // Scroll to view Pass Schedule Table
      await tester.scrollUntilVisible(
        find.text('WELD PASS SCHEDULE & ELECTRICAL PARAMETERS'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('WELD PASS SCHEDULE & ELECTRICAL PARAMETERS'), findsOneWidget);
    });

    testWidgets('Switching to NDT & Bend Quals tab displays coupon evaluation dossiers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on NDT & Bend Quals tab
      final ndtTab = find.textContaining('NDT & Bend Quals');
      await tester.tap(ndtTab);
      await tester.pumpAndSettle();

      // Verify standards reference banner
      expect(find.text('API 1104 Clause 6 & ASME Section IX QW-302'), findsOneWidget);
      expect(find.text('QUALIFICATION TEST COUPON DOSSIERS'), findsOneWidget);
      expect(find.text('TC-2025-KPL-084'), findsOneWidget);
      expect(find.textContaining('Visual Inspection (VT)'), findsWidgets);
      expect(find.textContaining('Guided Root & Face Bend Tests'), findsWidgets);
    });

    testWidgets('Switching to KPIs & Continuity tab renders charts, pareto, and 6-month rule audit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on KPIs & Continuity tab
      final kpiTab = find.text('KPIs & Continuity');
      await tester.tap(kpiTab);
      await tester.pumpAndSettle();

      // Verify Fleet Repair Cut-out KPI card
      expect(find.text('FLEET REPAIR CUT-OUT RATE KPI'), findsOneWidget);
      expect(find.textContaining('vs 2.00% GAIL/OIL Pipeline Benchmark'), findsOneWidget);

      // Verify Contractor Benchmarking
      expect(find.text('CONTRACTOR REPAIR PERFORMANCE BENCHMARK'), findsOneWidget);

      // Verify Defect Pareto Distribution
      expect(find.text('DEFECT PARETO DISTRIBUTION (API 1104 REPAIRS)'), findsOneWidget);
      expect(find.text('Incomplete Sidewall Fusion (IF/LOF)'), findsOneWidget);

      // Verify 6-Month Continuity Rule Audit
      expect(find.text('6-MONTH CONTINUITY RULE AUDIT (API 1104 §6.8 / ASME QW-322)'), findsOneWidget);
    });

    testWidgets('AppBar Qualify New Welder button opens registration dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap add welder button
      final addButton = find.byIcon(Icons.person_add_alt_1_rounded);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Verify Dialog renders
      expect(find.text('Qualify New Welder'), findsOneWidget);
      expect(find.text('Welder Full Name'), findsOneWidget);
      expect(find.text('Hard Stamp ID'), findsOneWidget);
      expect(find.text('Register & Qualify'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Qualify New Welder'), findsNothing);
    });
  });
}
