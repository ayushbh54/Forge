import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/core/models/app_models.dart';
import 'package:nirmaan_app/providers/app_provider.dart';
import 'package:nirmaan_app/services/api_service.dart';
import 'package:nirmaan_app/services/auth_service.dart';
import 'package:nirmaan_app/screens/dashboard/dashboard_screen.dart';
import 'package:nirmaan_app/screens/schedule/schedule_screen.dart';
import 'package:nirmaan_app/screens/dpr/dpr_screen.dart';
import 'package:nirmaan_app/screens/workforce/workforce_screen.dart';
import 'package:nirmaan_app/screens/analytics/evm_dashboard_screen.dart';
import 'package:nirmaan_app/screens/weather/weather_impact_screen.dart';

// ---------------------------------------------------------------------------
// Mock Services for Test Isolation
// ---------------------------------------------------------------------------

class MockApiService extends ApiService {
  final List<Map<String, dynamic>> mockProjects;
  final List<Map<String, dynamic>> mockActivities;
  final List<Map<String, dynamic>> mockWorkers;
  final List<Map<String, dynamic>> mockMaterials;
  final List<Map<String, dynamic>> mockConflicts;
  final List<Map<String, dynamic>> mockAuditLogs;

  MockApiService({
    this.mockProjects = const [],
    this.mockActivities = const [],
    this.mockWorkers = const [],
    this.mockMaterials = const [],
    this.mockConflicts = const [],
    this.mockAuditLogs = const [],
  });

  @override
  Future<dynamic> getProjects() async => {'projects': mockProjects};

  @override
  Future<dynamic> getActivities(String projectId) async => {'activities': mockActivities};

  @override
  Future<dynamic> getWorkers(String projectId) async => {'workers': mockWorkers};

  @override
  Future<dynamic> getMaterials(String projectId) async => {'materials': mockMaterials};

  @override
  Future<dynamic> getConflicts(String projectId) async => {'conflicts': mockConflicts};

  @override
  Future<dynamic> getAuditLogs(String projectId) async => {'logs': mockAuditLogs};

  @override
  Future<dynamic> submitDpr(String projectId, Map<String, dynamic> data) async => {
    'success': true,
    'message': 'DPR Submitted successfully',
  };
}

class MockAuthService extends AuthService {
  final Map<String, dynamic>? mockUser;
  MockAuthService({this.mockUser});

  @override
  Future<Map<String, dynamic>?> getUser() async => mockUser ?? {
    'id': 'USR-001',
    'name': 'Chief Engineer',
    'role': 'Project Director',
  };

  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<String> getApiBaseUrl() async => 'http://localhost:3000';
}

// ---------------------------------------------------------------------------
// Benchmark Test Datasets
// ---------------------------------------------------------------------------

final List<Map<String, dynamic>> testProjects = [
  {
    'id': 'PRJ-OIL-2026',
    'code': 'OIL-PL-024',
    'name': 'Trunk Crude Oil Pipeline Expansion',
    'client': 'Oil India Limited (OIL)',
    'contractorJV': 'Consortium JV',
    'contractType': 'FIDIC Red Book Cl. 8.4',
    'location': 'Duliajan, Assam',
    'budget': 2450000000.0,
    'spentBudget': 1720000000.0,
    'currency': 'INR (₹)',
    'startDate': '2026-01-15',
    'plannedFinishDate': '2028-01-15',
    'forecastFinishDate': '2028-07-15',
    'spi': 0.94,
    'cpi': 0.98,
    'evidenceCoverage': 88.5,
    'status': 'ON_TRACK',
  }
];

final List<Map<String, dynamic>> testActivities = [
  {
    'id': 'ACT-01',
    'code': 'PIP-L5-024',
    'uwid': 'UWID-EXP-2026-03088',
    'wbsCode': '03.02.04',
    'name': 'Pipe Lower-in & Downhill Welding',
    'discipline': 'PIPING',
    'durationDays': 74,
    'totalFloatDays': 2,
    'isCriticalPath': true,
    'plannedProgress': 65.0,
    'contractorReportedProgress': 80.0,
    'quantitySurveyProgress': 74.5,
    'qcPassedProgress': 70.0,
    'droneLidarProgress': 68.2,
    'validatedConsensusProgress': 71.3,
    'plannedQuantity': 1200.0,
    'installedQuantity': 868.0,
    'unit': 'meters',
    'assignedSupervisor': 'Vikram Joshi',
  },
  {
    'id': 'ACT-02',
    'code': 'CIV-F4-012',
    'uwid': 'UWID-EXP-2026-03089',
    'wbsCode': '02.01.01',
    'name': 'Compressor Foundation Pouring',
    'discipline': 'CIVIL',
    'durationDays': 50,
    'totalFloatDays': 0,
    'isCriticalPath': true,
    'plannedProgress': 85.0,
    'contractorReportedProgress': 85.0,
    'quantitySurveyProgress': 85.0,
    'qcPassedProgress': 85.0,
    'droneLidarProgress': 85.0,
    'validatedConsensusProgress': 85.0,
    'plannedQuantity': 450.0,
    'installedQuantity': 382.5,
    'unit': 'm3',
    'assignedSupervisor': 'Rajesh Verma',
  },
];

final List<Map<String, dynamic>> testAuditLogs = [
  {
    'id': 'LOG-001',
    'action': 'PROJECT_INITIALIZED',
    'actor': 'Marcus Vance',
    'timestamp': '2026-09-30T00:00:00Z',
    'details': 'Pipeline project loaded into Nirmaan OS',
  }
];

AppProvider createMockAppProvider({bool withData = true}) {
  final apiService = MockApiService(
    mockProjects: withData ? testProjects : [],
    mockActivities: withData ? testActivities : [],
    mockAuditLogs: withData ? testAuditLogs : [],
  );
  final authService = MockAuthService();
  final provider = AppProvider(apiService: apiService, authService: authService);
  if (withData) {
    provider.projects = testProjects.map((p) => ProjectModel.fromJson(p)).toList();
    provider.currentProjectId = 'PRJ-OIL-2026';
    provider.activities = testActivities.map((a) => ActivityModel.fromJson(a)).toList();
    provider.auditLogs = List<Map<String, dynamic>>.from(testAuditLogs);
  }
  return provider;
}

Widget createTestWidget({
  required Widget child,
  AppProvider? provider,
}) {
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider ?? createMockAppProvider(),
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

void configureTestViewport(WidgetTester tester, {Size size = const Size(1200, 2400)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

// ---------------------------------------------------------------------------
// TEST SUITE
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Comprehensive Screen Mounting Widget Tests', () {
    // -------------------------------------------------------------------------
    // 1. DashboardScreen
    // -------------------------------------------------------------------------
    group('DashboardScreen', () {
      testWidgets('mounts successfully with loaded project and renders key metrics',
          (WidgetTester tester) async {
        configureTestViewport(tester);
        final provider = createMockAppProvider(withData: true);

        await tester.pumpWidget(createTestWidget(
          child: const DashboardScreen(),
          provider: provider,
        ));
        await tester.pumpAndSettle();

        // 1. Verify App Bar
        expect(find.text('Nirmaan OS'), findsOneWidget);
        expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
        expect(find.byIcon(Icons.person_outline), findsOneWidget);

        // 2. Verify Project Details
        expect(find.text('Trunk Crude Oil Pipeline Expansion'), findsOneWidget);
        expect(find.textContaining('OIL-PL-024'), findsWidgets);
        expect(find.textContaining('Duliajan, Assam'), findsOneWidget);

        // 3. Verify Section Headers
        expect(find.text('Key Metrics'), findsOneWidget);
        expect(find.text('Quick Actions'), findsOneWidget);
        expect(find.text('Recent Activity'), findsOneWidget);

        // 4. Verify EVM Key Indicators
        expect(find.text('SPI'), findsWidgets);
        expect(find.text('CPI'), findsWidgets);
        expect(find.text('0.94'), findsOneWidget); // SPI value
        expect(find.text('0.98'), findsOneWidget); // CPI value
      });

      testWidgets('mounts empty state when no projects are available',
          (WidgetTester tester) async {
        configureTestViewport(tester);
        final provider = createMockAppProvider(withData: false);

        await tester.pumpWidget(createTestWidget(
          child: const DashboardScreen(),
          provider: provider,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Nirmaan OS'), findsOneWidget);
        expect(find.text('No Projects Found'), findsOneWidget);
        expect(find.text('Create your first project to get started.'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Create Project'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 2. ScheduleScreen
    // -------------------------------------------------------------------------
    group('ScheduleScreen', () {
      testWidgets('mounts successfully and renders activity list, WBS banner, and filters',
          (WidgetTester tester) async {
        configureTestViewport(tester);
        final provider = createMockAppProvider(withData: true);

        await tester.pumpWidget(createTestWidget(
          child: const ScheduleScreen(),
          provider: provider,
        ));
        await tester.pumpAndSettle();

        // 1. Verify App Bar & Title
        expect(find.text('Schedule & Activity Tracker'), findsOneWidget);
        expect(find.byIcon(Icons.account_tree_rounded), findsWidgets);

        // 2. Verify WBS Gantt Cascade Header Banner
        expect(find.text('WBS L1–L6 Interactive Gantt & Timeline Cascade'), findsOneWidget);

        // 3. Verify Search and Filter Controls
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Search activities...'), findsOneWidget);
        expect(find.text('ALL'), findsOneWidget); // Default discipline dropdown value

        // 4. Verify Floating Action Button
        expect(find.text('Import P6'), findsOneWidget);
        expect(find.byIcon(Icons.file_upload), findsOneWidget);

        // 5. Verify Activities rendered from provider
        expect(find.textContaining('Pipe Lower-in & Downhill Welding'), findsOneWidget);
        expect(find.textContaining('Compressor Foundation Pouring'), findsOneWidget);
        expect(find.textContaining('PIP-L5-024'), findsWidgets);
        expect(find.textContaining('CIV-F4-012'), findsWidgets);

        // 6. Test search filter functionality
        await tester.enterText(find.byType(TextField), 'Compressor');
        await tester.pumpAndSettle();

        expect(find.textContaining('Compressor Foundation Pouring'), findsOneWidget);
        expect(find.textContaining('Pipe Lower-in & Downhill Welding'), findsNothing);
      });

      testWidgets('mounts empty state when no activities exist',
          (WidgetTester tester) async {
        configureTestViewport(tester);
        final provider = createMockAppProvider(withData: true);
        provider.activities = [];

        await tester.pumpWidget(createTestWidget(
          child: const ScheduleScreen(),
          provider: provider,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Schedule & Activity Tracker'), findsOneWidget);
        expect(find.text('No activities found'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 3. DprScreen
    // -------------------------------------------------------------------------
    group('DprScreen', () {
      testWidgets('mounts successfully and renders DPR submission form',
          (WidgetTester tester) async {
        configureTestViewport(tester);
        final provider = createMockAppProvider(withData: true);

        await tester.pumpWidget(createTestWidget(
          child: const DprScreen(),
          provider: provider,
        ));
        await tester.pumpAndSettle();

        // 1. Verify App Bar & Title
        expect(find.widgetWithText(AppBar, 'Submit DPR'), findsOneWidget);
        expect(find.byIcon(Icons.history), findsOneWidget);

        // 2. Verify Form Labels
        expect(find.text('Activity'), findsOneWidget);
        expect(find.text('Completed Quantity'), findsOneWidget);
        expect(find.text('Delay Reason'), findsOneWidget);
        expect(find.text('Notes / Remarks'), findsOneWidget);

        // 3. Verify Dropdown and Text Fields
        expect(find.text('No Delay'), findsOneWidget);
        expect(find.byType(TextField), findsNWidgets(2)); // Qty and Notes text fields

        // 4. Verify Submit Button
        expect(find.widgetWithText(ElevatedButton, 'Submit DPR'), findsOneWidget);
      });

      testWidgets('mounts with pre-filled initialActivity and initialDelayReason',
          (WidgetTester tester) async {
        configureTestViewport(tester);
        final provider = createMockAppProvider(withData: true);

        await tester.pumpWidget(createTestWidget(
          child: const DprScreen(
            initialActivity: 'ACT-01',
            initialDelayReason: 'Weather/Rain',
            initialNotes: 'Heavy monsoon downpour halted welding at chainage 14+200',
          ),
          provider: provider,
        ));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppBar, 'Submit DPR'), findsOneWidget);
        expect(find.text('Weather/Rain'), findsOneWidget);
        expect(find.text('Heavy monsoon downpour halted welding at chainage 14+200'), findsOneWidget);
      });

      testWidgets('mounts empty state when no activities are available',
          (WidgetTester tester) async {
        configureTestViewport(tester);
        final provider = createMockAppProvider(withData: true);
        provider.activities = [];

        await tester.pumpWidget(createTestWidget(
          child: const DprScreen(),
          provider: provider,
        ));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppBar, 'Submit DPR'), findsOneWidget);
        expect(find.text('No activities available'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 4. WorkforceScreen
    // -------------------------------------------------------------------------
    group('WorkforceScreen', () {
      testWidgets('mounts successfully and renders attendance stats, search bar, and worker cards',
          (WidgetTester tester) async {
        configureTestViewport(tester);

        await tester.pumpWidget(createTestWidget(
          child: const WorkforceScreen(),
        ));
        await tester.pumpAndSettle();

        // 1. Verify Title & App Bar
        expect(find.text('Workforce & HR Management'), findsOneWidget);

        // 2. Verify Summary Statistics Row
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('150'), findsOneWidget);
        expect(find.text('Present'), findsOneWidget);
        expect(find.text('125'), findsOneWidget);
        expect(find.text('Absent'), findsOneWidget);
        expect(find.text('25'), findsOneWidget);
        expect(find.text('Rate'), findsOneWidget);
        expect(find.text('83%'), findsOneWidget);

        // 3. Verify Search Bar
        expect(find.text('Search by name, badge, trade...'), findsOneWidget);

        // 4. Verify Worker Cards
        expect(find.text('Ramesh Kumar'), findsOneWidget);
        expect(find.text('WELDER'), findsOneWidget);
        expect(find.text('Suresh Patel'), findsOneWidget);
        expect(find.text('ELECTRICIAN'), findsOneWidget);
        expect(find.text('Amit Sharma'), findsOneWidget);
        expect(find.text('FITTER'), findsOneWidget);
        expect(find.text('Vikram Singh'), findsOneWidget);
        expect(find.text('RIGGER'), findsOneWidget);
        expect(find.text('Dinesh Verma'), findsOneWidget);
        expect(find.text('MASON'), findsOneWidget);

        // 5. Test Search Filtering
        await tester.enterText(find.byType(TextField), 'Welder');
        await tester.pumpAndSettle();

        expect(find.text('Ramesh Kumar'), findsOneWidget);
        expect(find.text('Suresh Patel'), findsNothing);
        expect(find.text('Amit Sharma'), findsNothing);

        // 6. Verify Add Worker FAB
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 5. EvmDashboardScreen
    // -------------------------------------------------------------------------
    group('EvmDashboardScreen', () {
      testWidgets('mounts successfully and renders EVM metrics, S-Curve, and tabs',
          (WidgetTester tester) async {
        configureTestViewport(tester);

        await tester.pumpWidget(createTestWidget(
          child: const EvmDashboardScreen(),
        ));
        await tester.pumpAndSettle();

        // 1. Verify App Bar Title & Subtitle
        expect(find.text('Earned Value Management'), findsOneWidget);
        expect(find.textContaining('OIL-PL-024'), findsOneWidget);
        expect(find.textContaining('Cutoff: Sep 2026'), findsOneWidget);

        // 2. Verify Tab Navigation Bar
        expect(find.text('EVM & S-Curve'), findsOneWidget);
        expect(find.text('Monthly Ledger'), findsOneWidget);
        expect(find.text('WBS Variance'), findsOneWidget);

        // 3. Verify Primary Triad EVM Cards (PV, EV, AC)
        expect(find.text('₹124.50 Cr'), findsWidgets); // Planned Value
        expect(find.text('₹112.80 Cr'), findsWidgets); // Earned Value
        expect(find.text('₹118.20 Cr'), findsWidgets); // Actual Cost

        // 4. Verify Variances & Performance Indices
        expect(find.text('-₹11.70 Cr'), findsOneWidget); // SV
        expect(find.text('-₹5.40 Cr'), findsOneWidget);  // CV
        expect(find.text('0.91'), findsOneWidget);       // SPI
        expect(find.text('0.95'), findsOneWidget);       // CPI

        // 5. Verify Milestone Health Cards
        expect(find.text('Civil Foundations'), findsOneWidget);
        expect(find.text('Pipe Racks'), findsOneWidget);

        // 6. Test Tab Switching to Monthly Ledger
        await tester.tap(find.text('Monthly Ledger'));
        await tester.pumpAndSettle();

        expect(find.text('Monthly EVM Trend Ledger'), findsOneWidget);
        expect(find.text('Sep 26'), findsWidgets);

        // 7. Test Tab Switching to WBS Variance
        await tester.tap(find.text('WBS Variance'));
        await tester.pumpAndSettle();

        expect(find.text('Piping & Welding'), findsOneWidget);
        expect(find.text('Civil & Foundation'), findsOneWidget);
      });

      testWidgets('opens EVM Formula Glossary dialog when info button is tapped',
          (WidgetTester tester) async {
        configureTestViewport(tester);

        await tester.pumpWidget(createTestWidget(
          child: const EvmDashboardScreen(),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('EVM Formula Glossary'));
        await tester.pumpAndSettle();

        expect(find.text('EVM Formulas & Standards'), findsOneWidget);
        expect(find.text('Schedule Variance (SV)'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 6. WeatherImpactScreen
    // -------------------------------------------------------------------------
    group('WeatherImpactScreen', () {
      testWidgets('mounts successfully and renders telemetry, live impact, and forecast tabs',
          (WidgetTester tester) async {
        configureTestViewport(tester);

        await tester.pumpWidget(createTestWidget(
          child: const WeatherImpactScreen(),
        ));
        await tester.pumpAndSettle();

        // 1. Verify App Bar & Title
        expect(find.text('Weather Impact & Delay Correlation'), findsOneWidget);
        expect(find.textContaining('Oil India Duliajan Site'), findsOneWidget);
        expect(find.textContaining('27.4825° N, 95.3225° E'), findsOneWidget);

        // 2. Verify Tab Navigation Bar
        expect(find.text('Live Impact'), findsOneWidget);
        expect(find.text('7-Day Forecast'), findsOneWidget);
        expect(find.text('Delay Ledger'), findsOneWidget);

        // 3. Verify Live Telemetry Sensor Metrics
        expect(find.text('32°C'), findsOneWidget);
        expect(find.text('45 mm'), findsOneWidget);
        expect(find.text('18 km/h'), findsOneWidget);
        expect(find.text('88%'), findsOneWidget);

        // 4. Verify Work Suspension Alert Banner & Suspended Activities
        expect(find.textContaining('WORK SUSPENSION IN EFFECT'), findsOneWidget);
        expect(find.textContaining('ACT-PL-024'), findsOneWidget);
        expect(find.text('Line 24 Welded Joints (SMAW/GTAW & Laying)'), findsOneWidget);
        expect(find.textContaining('ACT-EX-031'), findsOneWidget);
        expect(find.text('Trench Excavation & Dewatering'), findsOneWidget);

        // 5. Test Tab Switching to 7-Day Forecast
        await tester.tap(find.text('7-Day Forecast'));
        await tester.pumpAndSettle();

        expect(find.text('7-Day Monsoon Rainfall Forecast'), findsOneWidget);
        expect(find.text('Daily Operational Outlook'), findsOneWidget);

        // 6. Test Tab Switching to Delay Ledger
        await tester.tap(find.text('Delay Ledger'));
        await tester.pumpAndSettle();

        expect(find.text('Seasonal Rain Delay Breakdown (2026)'), findsOneWidget);
      });
    });
  });
}
