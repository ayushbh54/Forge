import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/providers/app_provider.dart';
import 'package:nirmaan_app/screens/reports/executive_report_screen.dart';
import 'package:nirmaan_app/services/api_service.dart';
import 'package:nirmaan_app/services/auth_service.dart';

class _FakeApiService extends ApiService {
  @override
  Future<dynamic> getProjects() async => {
        'projects': [
          {
            'id': 'proj-oil-024',
            'code': 'OIL-PL-024',
            'name': 'Trunk Crude Oil Pipeline Expansion',
            'client': 'Oil India Limited (OIL)',
            'contractType': 'FIDIC Red Book Cl. 8.4',
            'status': 'ACTIVE',
            'budget': 24500000000,
            'spent': 15300000000,
            'progress': 62.4,
          }
        ]
      };
}

class _FakeAuthService extends AuthService {}

void main() {
  Widget createTestWidget() {
    return ChangeNotifierProvider<AppProvider>(
      create: (_) => AppProvider(
        apiService: _FakeApiService(),
        authService: _FakeAuthService(),
      ),
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const ExecutiveReportScreen(),
      ),
    );
  }

  testWidgets('ExecutiveReportScreen renders all 4 report templates and live preview metrics',
      (WidgetTester tester) async {
    // Set a tablet-like portrait resolution for clean scrolling
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Executive Progress Dossier'), findsOneWidget);
    expect(find.text('Report Templates'), findsOneWidget);

    // Verify 4 Report Templates
    expect(find.text('Weekly Progress Report (WPR)'), findsOneWidget);
    expect(find.text('Monthly Executive Summary'), findsOneWidget);
    expect(find.text('Contractor Performance Ledger'), findsOneWidget);
    expect(find.text('FIDIC Delay Claims Dossier'), findsOneWidget);

    // Verify Live Report Preview Card Header
    expect(find.text('LIVE REPORT PREVIEW'), findsOneWidget);

    // Verify Project Health Index (84/100)
    expect(find.text('Project Health Index'), findsWidgets);
    expect(find.text('84'), findsWidgets);
    expect(find.text('/100'), findsWidgets);

    // Verify SPI/CPI Trend section
    expect(find.text('SPI & CPI Trend (Earned Value)'), findsOneWidget);
    expect(find.textContaining('SPI: 0.94'), findsWidgets);
    expect(find.textContaining('CPI: 0.98'), findsWidgets);

    // Verify Physical vs Financial Progress %
    expect(find.text('Physical vs Financial Progress %'), findsOneWidget);
    expect(find.textContaining('62.4%'), findsWidgets);

    // Verify Top 3 Critical Path Blockers
    expect(find.text('Top 3 Critical Path Blockers'), findsOneWidget);
    expect(find.textContaining('River Brahmaputra Crossing'), findsWidgets);
    expect(find.textContaining('Right-of-Way (RoW) KM 42–48 Forest Clearance'), findsWidgets);
    expect(find.textContaining('32-inch High-Yield API 5L X70 Pipe Spools'), findsWidgets);

    // Verify Adverse Weather Stoppages
    expect(find.text('Adverse Weather Stoppages'), findsOneWidget);
    expect(find.textContaining('7.5 Shift Days Lost'), findsWidgets);
    expect(find.textContaining('342 mm'), findsWidgets);

    // Verify One-Tap Action Buttons
    expect(find.textContaining('Generate Formal PDF Dossier'), findsOneWidget);
    expect(find.text('Share via WhatsApp / Email'), findsOneWidget);
    expect(find.text('Print Sign-Off Sheet'), findsOneWidget);
  });

  testWidgets('Template selection switches active template and updates button label',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Default template is Monthly Executive Summary (MES)
    expect(find.text('Generate Formal PDF Dossier (MES)'), findsOneWidget);

    // Tap on Weekly Progress Report (WPR)
    await tester.tap(find.text('Weekly Progress Report (WPR)'));
    await tester.pumpAndSettle();

    // Verify button label reflects WPR
    expect(find.text('Generate Formal PDF Dossier (WPR)'), findsOneWidget);

    // Tap on FIDIC Delay Claims Dossier (FDC)
    await tester.tap(find.text('FIDIC Delay Claims Dossier'));
    await tester.pumpAndSettle();

    // Verify button label reflects FDC
    expect(find.text('Generate Formal PDF Dossier (FDC)'), findsOneWidget);
  });
}
