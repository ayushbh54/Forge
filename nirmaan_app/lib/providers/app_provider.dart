import 'package:flutter/foundation.dart';
import '../core/models/app_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/offline_sync_service.dart';

class AppProvider with ChangeNotifier {
  final ApiService apiService;
  final AuthService authService;

  AppProvider({ApiService? apiService, AuthService? authService})
      : apiService = apiService ?? ApiService(),
        authService = authService ?? AuthService() {
    _init();
  }

  Map<String, dynamic>? currentUser;
  String? currentProjectId;

  List<ProjectModel> projects = [];
  List<ActivityModel> activities = [];
  List<WorkerModel> workers = [];
  List<Map<String, dynamic>> materials = [];
  List<Map<String, dynamic>> conflicts = [];
  List<Map<String, dynamic>> auditLogs = [];

  // --- Static Industrial Oil & Gas Benchmark Datasets (Oil India Duliajan Spread) ---
  static final ProjectModel defaultBenchmarkProject = ProjectModel.fromJson({
    'id': 'PRJ-OIL-2026',
    'code': 'OIL-PL-024',
    'name': 'Oil India Duliajan Central Operational Area - 24" Trunk Crude Pipeline Spread',
    'client': 'Oil India Limited (OIL)',
    'contractorJV': 'L&T - Punj Lloyd Consortium JV',
    'contractType': 'FIDIC Red Book Cl. 8.4 (EPC/Turnkey)',
    'location': 'Duliajan & Digboi Sector, Dibrugarh / Tinsukia, Assam',
    'budget': 1845000000.0,
    'spentBudget': 1240000000.0,
    'currency': 'INR (₹)',
    'startDate': '2026-01-15',
    'plannedFinishDate': '2027-03-31',
    'forecastFinishDate': '2027-05-15',
    'status': 'IN_PROGRESS',
    'spi': 0.96,
    'cpi': 0.98,
    'evidenceCoverage': 92.4,
  });

  static final List<ActivityModel> defaultBenchmarkActivities = [
    ActivityModel(
      id: 'ACT-01',
      code: 'PIP-L1-001',
      uwid: 'UWID-EXP-2026-03080',
      wbsCode: '01.01.01',
      name: 'RoU Clearing, Grading & Trench Excavation',
      discipline: 'CIVIL',
      plannedStart: DateTime(2026, 1, 15),
      plannedFinish: DateTime(2026, 3, 30),
      durationDays: 75,
      totalFloatDays: 4,
      isCriticalPath: false,
      plannedProgress: 60.0,
      contractorReportedProgress: 55.0,
      quantitySurveyProgress: 52.0,
      qcPassedProgress: 50.0,
      droneLidarProgress: 51.4,
      validatedConsensusProgress: 51.4,
      plannedQuantity: 3500.0,
      installedQuantity: 1800.0,
      unit: 'meters',
      supervisor: 'Vikram Joshi',
    ),
    ActivityModel(
      id: 'ACT-02',
      code: 'PIP-L2-005',
      uwid: 'UWID-EXP-2026-03082',
      wbsCode: '02.01.01',
      name: 'Pipe Stringing, Bending & Alignment',
      discipline: 'PIPING',
      plannedStart: DateTime(2026, 2, 1),
      plannedFinish: DateTime(2026, 4, 15),
      durationDays: 74,
      totalFloatDays: 2,
      isCriticalPath: true,
      plannedProgress: 70.0,
      contractorReportedProgress: 65.0,
      quantitySurveyProgress: 63.5,
      qcPassedProgress: 61.0,
      droneLidarProgress: 62.8,
      validatedConsensusProgress: 62.8,
      plannedQuantity: 3500.0,
      installedQuantity: 2200.0,
      unit: 'meters',
      supervisor: 'Vikram Joshi',
    ),
    ActivityModel(
      id: 'ACT-03',
      code: 'PIP-L3-012',
      uwid: 'UWID-EXP-2026-03085',
      wbsCode: '03.01.01',
      name: 'API 5L X70 Mainline SMAW/GMAW Welding',
      discipline: 'PIPING',
      plannedStart: DateTime(2026, 2, 10),
      plannedFinish: DateTime(2026, 5, 20),
      durationDays: 100,
      totalFloatDays: 0,
      isCriticalPath: true,
      plannedProgress: 58.0,
      contractorReportedProgress: 55.0,
      quantitySurveyProgress: 53.0,
      qcPassedProgress: 51.5,
      droneLidarProgress: 52.8,
      validatedConsensusProgress: 52.8,
      plannedQuantity: 3500.0,
      installedQuantity: 1850.0,
      unit: 'meters',
      supervisor: 'Ramesh Kumar',
    ),
    ActivityModel(
      id: 'ACT-04',
      code: 'NDT-AUT-018',
      uwid: 'UWID-EXP-2026-03086',
      wbsCode: '03.02.01',
      name: 'Phased Array Ultrasonic Testing (AUT) & NDT',
      discipline: 'QA_QC',
      plannedStart: DateTime(2026, 2, 15),
      plannedFinish: DateTime(2026, 5, 25),
      durationDays: 100,
      totalFloatDays: 0,
      isCriticalPath: true,
      plannedProgress: 55.0,
      contractorReportedProgress: 52.0,
      quantitySurveyProgress: 50.0,
      qcPassedProgress: 50.0,
      droneLidarProgress: 50.0,
      validatedConsensusProgress: 50.0,
      plannedQuantity: 320.0,
      installedQuantity: 160.0,
      unit: 'joints',
      supervisor: 'R. K. Sharma',
    ),
    ActivityModel(
      id: 'ACT-05',
      code: 'FJC-SLEEVE-022',
      uwid: 'UWID-EXP-2026-03087',
      wbsCode: '03.03.01',
      name: 'Field Joint Coating (Heat Shrink Sleeves)',
      discipline: 'PIPING',
      plannedStart: DateTime(2026, 2, 20),
      plannedFinish: DateTime(2026, 5, 30),
      durationDays: 100,
      totalFloatDays: 1,
      isCriticalPath: true,
      plannedProgress: 48.0,
      contractorReportedProgress: 45.0,
      quantitySurveyProgress: 44.0,
      qcPassedProgress: 43.0,
      droneLidarProgress: 43.7,
      validatedConsensusProgress: 43.7,
      plannedQuantity: 320.0,
      installedQuantity: 140.0,
      unit: 'joints',
      supervisor: 'Amit Sharma',
    ),
    ActivityModel(
      id: 'ACT-06',
      code: 'PIP-L5-024',
      uwid: 'UWID-EXP-2026-03088',
      wbsCode: '03.04.01',
      name: 'Trench Sand Bedding & Padding',
      discipline: 'CIVIL',
      plannedStart: DateTime(2026, 3, 1),
      plannedFinish: DateTime(2026, 6, 15),
      durationDays: 106,
      totalFloatDays: 2,
      isCriticalPath: false,
      plannedProgress: 40.0,
      contractorReportedProgress: 36.0,
      quantitySurveyProgress: 35.0,
      qcPassedProgress: 33.0,
      droneLidarProgress: 34.2,
      validatedConsensusProgress: 34.2,
      plannedQuantity: 3500.0,
      installedQuantity: 1200.0,
      unit: 'meters',
      supervisor: 'Dinesh Verma',
    ),
    ActivityModel(
      id: 'ACT-07',
      code: 'PIP-L6-029',
      uwid: 'UWID-EXP-2026-03089',
      wbsCode: '04.01.01',
      name: 'Pipeline Lower-in & Tie-in Operations',
      discipline: 'PIPING',
      plannedStart: DateTime(2026, 3, 15),
      plannedFinish: DateTime(2026, 6, 30),
      durationDays: 107,
      totalFloatDays: 0,
      isCriticalPath: true,
      plannedProgress: 32.0,
      contractorReportedProgress: 30.0,
      quantitySurveyProgress: 28.0,
      qcPassedProgress: 26.0,
      droneLidarProgress: 27.1,
      validatedConsensusProgress: 27.1,
      plannedQuantity: 3500.0,
      installedQuantity: 950.0,
      unit: 'meters',
      supervisor: 'Vikram Joshi',
    ),
    ActivityModel(
      id: 'ACT-08',
      code: 'CIV-L7-033',
      uwid: 'UWID-EXP-2026-03090',
      wbsCode: '04.02.01',
      name: 'Backfilling, Padding & Crown Reinstatement',
      discipline: 'CIVIL',
      plannedStart: DateTime(2026, 3, 20),
      plannedFinish: DateTime(2026, 7, 10),
      durationDays: 112,
      totalFloatDays: 3,
      isCriticalPath: false,
      plannedProgress: 28.0,
      contractorReportedProgress: 25.0,
      quantitySurveyProgress: 23.5,
      qcPassedProgress: 22.0,
      droneLidarProgress: 22.8,
      validatedConsensusProgress: 22.8,
      plannedQuantity: 3500.0,
      installedQuantity: 800.0,
      unit: 'meters',
      supervisor: 'Dinesh Verma',
    ),
    ActivityModel(
      id: 'ACT-09',
      code: 'QAC-GW-041',
      uwid: 'UWID-EXP-2026-03091',
      wbsCode: '05.01.01',
      name: 'Golden Tie-in Weld Radiographic Certification',
      discipline: 'QA_QC',
      plannedStart: DateTime(2026, 4, 1),
      plannedFinish: DateTime(2026, 7, 20),
      durationDays: 110,
      totalFloatDays: 0,
      isCriticalPath: true,
      plannedProgress: 50.0,
      contractorReportedProgress: 50.0,
      quantitySurveyProgress: 50.0,
      qcPassedProgress: 50.0,
      droneLidarProgress: 50.0,
      validatedConsensusProgress: 50.0,
      plannedQuantity: 8.0,
      installedQuantity: 4.0,
      unit: 'welds',
      supervisor: 'R. K. Sharma',
    ),
    ActivityModel(
      id: 'ACT-10',
      code: 'HYD-TST-009',
      uwid: 'UWID-EXP-2026-03092',
      wbsCode: '05.02.01',
      name: 'Hydrostatic Strength & 24hr Leak Testing',
      discipline: 'QA_QC',
      plannedStart: DateTime(2026, 5, 1),
      plannedFinish: DateTime(2026, 8, 15),
      durationDays: 106,
      totalFloatDays: 0,
      isCriticalPath: true,
      plannedProgress: 0.0,
      contractorReportedProgress: 0.0,
      quantitySurveyProgress: 0.0,
      qcPassedProgress: 0.0,
      droneLidarProgress: 0.0,
      validatedConsensusProgress: 0.0,
      plannedQuantity: 148.0,
      installedQuantity: 0.0,
      unit: 'bar',
      supervisor: 'R. K. Sharma',
    ),
    ActivityModel(
      id: 'ACT-11',
      code: 'CP-ANODE-052',
      uwid: 'UWID-EXP-2026-03093',
      wbsCode: '06.01.01',
      name: 'Impressed Current Cathodic Protection (ICCP)',
      discipline: 'ELECTRICAL',
      plannedStart: DateTime(2026, 3, 1),
      plannedFinish: DateTime(2026, 7, 30),
      durationDays: 151,
      totalFloatDays: 5,
      isCriticalPath: false,
      plannedProgress: 55.0,
      contractorReportedProgress: 52.0,
      quantitySurveyProgress: 50.0,
      qcPassedProgress: 50.0,
      droneLidarProgress: 50.0,
      validatedConsensusProgress: 50.0,
      plannedQuantity: 24.0,
      installedQuantity: 12.0,
      unit: 'test posts',
      supervisor: 'Suresh Patel',
    ),
    ActivityModel(
      id: 'ACT-12',
      code: 'SCADA-RTU-065',
      uwid: 'UWID-EXP-2026-03094',
      wbsCode: '06.02.01',
      name: 'Solar Microgrid RTU & SCADA Telemetry',
      discipline: 'INSTRUMENTATION',
      plannedStart: DateTime(2026, 4, 15),
      plannedFinish: DateTime(2026, 8, 30),
      durationDays: 137,
      totalFloatDays: 2,
      isCriticalPath: false,
      plannedProgress: 50.0,
      contractorReportedProgress: 50.0,
      quantitySurveyProgress: 50.0,
      qcPassedProgress: 50.0,
      droneLidarProgress: 50.0,
      validatedConsensusProgress: 50.0,
      plannedQuantity: 6.0,
      installedQuantity: 3.0,
      unit: 'stations',
      supervisor: 'Suresh Patel',
    ),
  ];

  static final List<WorkerModel> defaultBenchmarkWorkers = [
    WorkerModel(
      id: 'WRK-1001',
      badgeNumber: 'W-1000',
      name: 'Ramesh Kumar',
      trade: 'WELDER',
      skills: ['TIG', 'MIG', '6G Downhill'],
      gang: 'L&T Eng Gang A',
      safetyCertExpiry: '2027-10-15',
      attendanceStatus: 'VERIFIED_PRESENT',
      verificationMethod: 'GEOFENCE_BIOMETRIC',
      confidenceScore: 98.4,
      lastClockIn: '07:45 AM Today',
      geofenceDistanceMeters: 14.2,
      isAiSpoofProtected: true,
    ),
    WorkerModel(
      id: 'WRK-1002',
      badgeNumber: 'W-1001',
      name: 'Suresh Patel',
      trade: 'ELECTRICIAN',
      skills: ['HV', 'Wiring', 'Substation'],
      gang: 'Tata Projects Gang B',
      safetyCertExpiry: '2027-08-20',
      attendanceStatus: 'VERIFIED_PRESENT',
      verificationMethod: 'GEOFENCE_BIOMETRIC',
      confidenceScore: 99.1,
      lastClockIn: '07:50 AM Today',
      geofenceDistanceMeters: 22.0,
      isAiSpoofProtected: true,
    ),
    WorkerModel(
      id: 'WRK-1003',
      badgeNumber: 'W-1002',
      name: 'Amit Sharma',
      trade: 'FITTER',
      skills: ['Pipe', 'Alignment', 'Bevelling'],
      gang: 'Shapoorji Gang C',
      safetyCertExpiry: '2027-12-05',
      attendanceStatus: 'VERIFIED_PRESENT',
      verificationMethod: 'GEOFENCE_BIOMETRIC',
      confidenceScore: 97.8,
      lastClockIn: '07:55 AM Today',
      geofenceDistanceMeters: 18.5,
      isAiSpoofProtected: true,
    ),
    WorkerModel(
      id: 'WRK-1004',
      badgeNumber: 'W-1003',
      name: 'Vikram Singh',
      trade: 'RIGGER',
      skills: ['Crane', 'Slinging', 'Sideboom'],
      gang: 'L&T Eng Gang A',
      safetyCertExpiry: '2026-10-12',
      attendanceStatus: 'ABSENT',
      verificationMethod: 'NOT_VERIFIED',
      confidenceScore: 0.0,
      lastClockIn: 'Pending Clock-in',
      geofenceDistanceMeters: 0.0,
      isAiSpoofProtected: true,
    ),
    WorkerModel(
      id: 'WRK-1005',
      badgeNumber: 'W-1004',
      name: 'Dinesh Verma',
      trade: 'MASON',
      skills: ['Concrete', 'Brickwork', 'Thrust Blocks'],
      gang: 'BHEL Gang D',
      safetyCertExpiry: '2028-02-14',
      attendanceStatus: 'VERIFIED_PRESENT',
      verificationMethod: 'GEOFENCE_BIOMETRIC',
      confidenceScore: 98.9,
      lastClockIn: '08:00 AM Today',
      geofenceDistanceMeters: 12.0,
      isAiSpoofProtected: true,
    ),
    WorkerModel(
      id: 'WRK-1006',
      badgeNumber: 'W-1005',
      name: 'R. K. Sharma',
      trade: 'QA_QC',
      skills: ['AUT NDT', 'CSWIP 3.1', 'Radiography'],
      gang: 'Oil India Inspection Unit',
      safetyCertExpiry: '2028-11-30',
      attendanceStatus: 'VERIFIED_PRESENT',
      verificationMethod: 'GEOFENCE_BIOMETRIC',
      confidenceScore: 99.8,
      lastClockIn: '07:30 AM Today',
      geofenceDistanceMeters: 8.0,
      isAiSpoofProtected: true,
    ),
    WorkerModel(
      id: 'WRK-1007',
      badgeNumber: 'W-1006',
      name: 'Manoj Das',
      trade: 'HSE_OFFICER',
      skills: ['NEBOSH', 'PTW Live', 'Gas Testing'],
      gang: 'Safety Advisory Cell',
      safetyCertExpiry: '2027-06-18',
      attendanceStatus: 'VERIFIED_PRESENT',
      verificationMethod: 'GEOFENCE_BIOMETRIC',
      confidenceScore: 99.5,
      lastClockIn: '07:25 AM Today',
      geofenceDistanceMeters: 5.5,
      isAiSpoofProtected: true,
    ),
    WorkerModel(
      id: 'WRK-1008',
      badgeNumber: 'W-1007',
      name: 'Harish Buragohain',
      trade: 'GENERAL_LABOUR',
      skills: ['Trench Padding', 'Dewatering'],
      gang: 'Consortium Spreads Team',
      safetyCertExpiry: '2027-09-01',
      attendanceStatus: 'ABSENT',
      verificationMethod: 'NOT_VERIFIED',
      confidenceScore: 0.0,
      lastClockIn: 'Pending Clock-in',
      geofenceDistanceMeters: 0.0,
      isAiSpoofProtected: true,
    ),
  ];

  static final List<Map<String, dynamic>> defaultBenchmarkMaterials = [
    {
      'code': 'MAT-X70-01',
      'description': 'API 5L X70 24" Bare Line Pipes',
      'quantity': 42.0,
      'unit': 'MT',
      'docType': 'GRN',
      'source': 'Jindal Steel & Power Ltd',
      'destination': 'Digboi Pipe Yard Spread 2',
      'date': '2026-03-28',
      'activityCode': 'PIP-L2-005',
    },
    {
      'code': 'MAT-CANUSA-02',
      'description': 'Canusa 3-Layer Heat Shrink Sleeves 24"',
      'quantity': 80.0,
      'unit': 'units',
      'docType': 'GRN',
      'source': 'Shawcor Coating Systems',
      'destination': 'Digboi Central Store',
      'date': '2026-03-29',
      'activityCode': 'FJC-SLEEVE-022',
    },
    {
      'code': 'MAT-ELECTRODE-03',
      'description': 'Lincoln Electric E8010-P1 Welding Electrodes',
      'quantity': 250.0,
      'unit': 'kg',
      'docType': 'GIN',
      'source': 'Digboi Central Store',
      'destination': 'Mainline Welding Crew A',
      'date': '2026-03-30',
      'activityCode': 'PIP-L3-012',
    },
    {
      'code': 'MAT-SAND-04',
      'description': 'Washed River Bedding Sand (Silt < 3%)',
      'quantity': 140.0,
      'unit': 'm3',
      'docType': 'GRN',
      'source': 'Brahmaputra Approved Quarries',
      'destination': 'Spread 1 Trench Chainage 18+200',
      'date': '2026-03-31',
      'activityCode': 'PIP-L5-024',
    },
    {
      'code': 'MAT-VALVE-05',
      'description': 'API 6D 24" Class 600 Full Bore Ball Valves',
      'quantity': 2.0,
      'unit': 'units',
      'docType': 'GRN',
      'source': 'L&T Valves Coimbatore',
      'destination': 'Duliajan Scraper Trap Station',
      'date': '2026-03-31',
      'activityCode': 'PIP-L6-029',
    },
  ];

  static final List<Map<String, dynamic>> defaultBenchmarkConflicts = [
    {
      'id': 'CONF-01',
      'title': 'Trench Bedding Sand Silt Content Variance',
      'status': 'OPEN',
      'activityCode': 'PIP-L5-024',
      'type': 'SPEC_VARIATION',
      'reference': 'FIDIC Cl. 4.21 / Shell DEP 31.40.10.19',
      'description': 'Delivered sand has 8.2% silt exceeding the 3.0% maximum specification threshold.',
    },
    {
      'id': 'CONF-02',
      'title': 'WPS-OIL-09 Pre-heat Interpass Temperature',
      'status': 'OPEN',
      'activityCode': 'PIP-L3-012',
      'type': 'TECH_PROCEDURE',
      'reference': 'API 1104 / ASME Sec IX',
      'description': 'Monsoon rain caused interpass temperature drops below minimum 120°C on joint J-142.',
    },
  ];

  static final List<Map<String, dynamic>> defaultBenchmarkAuditLogs = [
    {
      'id': 'LOG-001',
      'action': 'PROJECT_INITIALIZED',
      'actor': 'System Automation',
      'time': '2026-01-15',
      'details': 'Baseline Schedule Locked & Oil India Duliajan Spread Activated',
    },
    {
      'id': 'LOG-002',
      'action': 'GIS_GEOFENCE_BOUND',
      'actor': 'GIS Lead (Oil India)',
      'time': '2026-01-16',
      'details': 'Duliajan Central Operational Area (27.4825° N, 95.3225° E, 100m geofence active)',
    },
    {
      'id': 'LOG-003',
      'action': 'ROSTER_VERIFIED',
      'actor': 'Chief HSE Officer',
      'time': 'Today',
      'details': 'Biometric Muster Roll Roster verified with Anti-Spoof Live Liveness Shield',
    },
  ];

  ProjectModel? get currentProject {
    if (projects.isEmpty) return null;
    if (currentProjectId == null) return projects.first;
    try {
      return projects.firstWhere(
        (p) => p.id == currentProjectId,
        orElse: () => projects.first,
      );
    } catch (_) {
      return projects.first;
    }
  }

  bool isLoading = false;
  String? errorMessage;
  String currentLanguage = 'en';

  Future<void> _init() async {
    try {
      currentUser = await authService.getUser();
      currentUser ??= {
        'id': 'USR-001',
        'name': 'Chief Field Engineer',
        'role': 'Project Director',
      };
      await loadProjects(silent: true);
      if (projects.isNotEmpty && currentProjectId == null) {
        currentProjectId = projects.first.id;
        await loadAllData(silent: true);
      }
    } catch (e) {
      debugPrint('[AppProvider] Init error: $e');
    }
    notifyListeners();
  }

  void _setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    errorMessage = error;
    if (error != null) {
      debugPrint('AppProvider Error: $error');
    }
    notifyListeners();
  }

  void setLanguage(String code) {
    currentLanguage = code;
    notifyListeners();
  }

  Future<void> loginUser(Map<String, dynamic> userData) async {
    await authService.saveUser(userData);
    currentUser = userData;
    await loadProjects();
    if (projects.isNotEmpty && currentProjectId == null) {
      currentProjectId = projects.first.id;
      await loadAllData();
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await authService.logout();
    currentUser = null;
    currentProjectId = null;
    projects = [];
    activities = [];
    workers = [];
    materials = [];
    conflicts = [];
    auditLogs = [];
    notifyListeners();
  }

  Future<void> setCurrentProject(String projectId) async {
    currentProjectId = projectId;
    notifyListeners();
    await loadAllData();
  }

  Future<void> loadAllData({bool silent = false}) async {
    if (!silent) _setLoading(true);
    _setError(null);
    try {
      await Future.wait([
        loadActivities(silent: true),
        loadWorkers(silent: true),
        loadMaterials(silent: true),
        loadConflicts(silent: true),
        loadAuditLogs(silent: true),
      ]);
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<void> loadInitialData() async {
    await loadProjects();
    if (projects.isNotEmpty && currentProjectId == null) {
      currentProjectId = projects.first.id;
    }
    await loadAllData();
  }

  List<dynamic> _extractList(dynamic res, List<String> candidateKeys) {
    if (res == null) return [];
    if (res is List) return res;
    if (res is Map) {
      for (final key in candidateKeys) {
        if (res[key] is List) {
          return res[key] as List;
        }
      }
      if (res['data'] is List) {
        return res['data'] as List;
      }
      if (res['items'] is List) {
        return res['items'] as List;
      }
    }
    return [];
  }

  Future<bool> createProject(Map<String, dynamic> projectData) async {
    _setLoading(true);
    _setError(null);
    try {
      final localProj = ProjectModel.fromJson(projectData);

      projects.insert(0, localProj);
      currentProjectId = localProj.id;
      notifyListeners();

      try {
        await apiService.createProject(projectData);
      } catch (_) {}

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProjects({bool silent = false}) async {
    if (!silent) _setLoading(true);
    _setError(null);
    try {
      final res = await apiService.getProjects();
      final rawList = _extractList(res, ['projects']);
      final parsed = <ProjectModel>[];
      for (final item in rawList) {
        if (item is Map) {
          try {
            parsed.add(ProjectModel.fromJson(Map<String, dynamic>.from(item)));
          } catch (e) {
            debugPrint('Project parse error: $e');
          }
        }
      }
      projects = parsed;
      if (projects.isNotEmpty && (currentProjectId == null || !projects.any((p) => p.id == currentProjectId))) {
        currentProjectId = projects.first.id;
      }
    } catch (e) {
      if (projects.isEmpty) {
        projects = [defaultBenchmarkProject];
        currentProjectId = defaultBenchmarkProject.id;
      }
      _setError(e.toString());
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<void> loadActivities({bool silent = false}) async {
    if (currentProjectId == null && projects.isNotEmpty) {
      currentProjectId = projects.first.id;
    }
    if (currentProjectId == null) return;
    if (!silent) _setLoading(true);
    _setError(null);
    try {
      final res = await apiService.getActivities(currentProjectId!);
      final rawList = _extractList(res, ['activities']);
      final parsed = <ActivityModel>[];
      for (final item in rawList) {
        if (item is Map) {
          try {
            parsed.add(ActivityModel.fromJson(Map<String, dynamic>.from(item)));
          } catch (e) {
            debugPrint('Activity parse error: $e');
          }
        }
      }
      activities = parsed;
      if (activities.isEmpty && (currentProjectId == 'PRJ-OIL-2026' || currentProjectId == defaultBenchmarkProject.id)) {
        activities = List<ActivityModel>.from(defaultBenchmarkActivities);
      }
    } catch (e) {
      if (activities.isEmpty) {
        activities = List<ActivityModel>.from(defaultBenchmarkActivities);
      }
      _setError(e.toString());
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<bool> createActivity(Map<String, dynamic> data) async {
    if (currentProjectId == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      await apiService.createActivity(currentProjectId!, data);
      await loadActivities(silent: true);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> importSchedule(dynamic fileOrContent, [String? fileName, String format = 'CSV_TABLE']) async {
    if (currentProjectId == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      await apiService.importSchedule(currentProjectId!, fileOrContent, fileName, format);
      await loadActivities(silent: true);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadWorkers({bool silent = false}) async {
    if (currentProjectId == null && projects.isNotEmpty) {
      currentProjectId = projects.first.id;
    }
    if (currentProjectId == null) return;
    if (!silent) _setLoading(true);
    _setError(null);
    try {
      final res = await apiService.getWorkers(currentProjectId!);
      final rawList = _extractList(res, ['workers']);
      final parsed = <WorkerModel>[];
      for (final item in rawList) {
        if (item is Map) {
          try {
            parsed.add(WorkerModel.fromJson(Map<String, dynamic>.from(item)));
          } catch (e) {
            debugPrint('Worker parse error: $e');
          }
        }
      }
      workers = parsed;
      if (workers.isEmpty && (currentProjectId == 'PRJ-OIL-2026' || currentProjectId == defaultBenchmarkProject.id)) {
        workers = List<WorkerModel>.from(defaultBenchmarkWorkers);
      }
    } catch (e) {
      if (workers.isEmpty) {
        workers = List<WorkerModel>.from(defaultBenchmarkWorkers);
      }
      _setError(e.toString());
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<bool> createWorker(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      final newWorker = WorkerModel.fromJson(data);
      workers.insert(0, newWorker);
      notifyListeners();

      if (currentProjectId != null) {
        try {
          await apiService.createWorker(currentProjectId!, data);
        } catch (_) {}
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMaterials({bool silent = false}) async {
    if (currentProjectId == null && projects.isNotEmpty) {
      currentProjectId = projects.first.id;
    }
    if (currentProjectId == null) return;
    if (!silent) _setLoading(true);
    _setError(null);
    try {
      final res = await apiService.getMaterials(currentProjectId!);
      final rawList = _extractList(res, ['materials', 'transactions']);
      final parsed = <Map<String, dynamic>>[];
      for (final item in rawList) {
        if (item is Map) {
          try {
            final m = Map<String, dynamic>.from(item);
            m['code'] = m['code'] ?? m['materialCode'] ?? m['docNumber'] ?? m['id'] ?? 'MAT-01';
            m['description'] = m['description'] ?? 'Material item';
            m['quantity'] = m['quantity'] ?? 0;
            m['unit'] = m['unit'] ?? 'units';
            m['docType'] = m['docType'] ?? 'GRN';
            m['source'] = m['source'] ?? m['sourceSupplier'] ?? m['destinationLocation'] ?? 'Store Yard';
            m['date'] = m['date'] ?? 'Today';
            parsed.add(m);
          } catch (e) {
            debugPrint('Material parse error: $e');
          }
        }
      }
      materials = parsed;
      if (materials.isEmpty && (currentProjectId == 'PRJ-OIL-2026' || currentProjectId == defaultBenchmarkProject.id)) {
        materials = List<Map<String, dynamic>>.from(defaultBenchmarkMaterials);
      }
    } catch (e) {
      if (materials.isEmpty) {
        materials = List<Map<String, dynamic>>.from(defaultBenchmarkMaterials);
      }
      _setError(e.toString());
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<bool> createMaterialTx(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      final m = Map<String, dynamic>.from(data);
      m['code'] = m['code'] ?? 'MAT-TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      m['date'] = m['date'] ?? DateTime.now().toIso8601String().split('T')[0];
      materials.insert(0, m);
      notifyListeners();

      if (currentProjectId != null) {
        try {
          await apiService.createMaterialTx(currentProjectId!, data);
        } catch (_) {
          try {
            await OfflineSyncService.instance.enqueueMaterialGrn(
              projectId: currentProjectId!,
              materialCode: m['code'].toString(),
              quantity: (m['quantity'] is num) ? (m['quantity'] as num).toDouble() : (double.tryParse(m['quantity']?.toString() ?? '0') ?? 1.0),
              unit: (m['unit'] ?? 'units').toString(),
              docNumber: 'GRN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
              description: (m['description'] ?? 'Field Material Transaction').toString(),
            );
          } catch (_) {}
        }
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> recordMaterialTransaction(Map<String, dynamic> data) => createMaterialTx(data);

  Future<void> loadConflicts({bool silent = false}) async {
    if (currentProjectId == null && projects.isNotEmpty) {
      currentProjectId = projects.first.id;
    }
    if (currentProjectId == null) return;
    if (!silent) _setLoading(true);
    _setError(null);
    try {
      final res = await apiService.getConflicts(currentProjectId!);
      final rawList = _extractList(res, ['conflicts', 'disputes']);
      final parsed = <Map<String, dynamic>>[];
      for (final item in rawList) {
        if (item is Map) {
          try {
            final c = Map<String, dynamic>.from(item);
            c['id'] = c['id']?.toString() ?? 'CONF-${DateTime.now().millisecondsSinceEpoch}';
            c['title'] = c['title'] ?? 'Technical Spec Conflict';
            c['status'] = c['status'] ?? 'OPEN';
            c['activityCode'] = c['activityCode'] ?? 'PIP-L5-024';
            c['type'] = c['type'] ?? 'SPEC_VARIATION';
            c['reference'] = c['reference'] ?? c['specOrClause'] ?? 'FIDIC Cl. 4.21';
            c['description'] = c['description'] ?? 'Specification variance detected';
            parsed.add(c);
          } catch (e) {
            debugPrint('Conflict parse error: $e');
          }
        }
      }
      conflicts = parsed;
      if (conflicts.isEmpty && (currentProjectId == 'PRJ-OIL-2026' || currentProjectId == defaultBenchmarkProject.id)) {
        conflicts = List<Map<String, dynamic>>.from(defaultBenchmarkConflicts);
      }
    } catch (e) {
      if (conflicts.isEmpty) {
        conflicts = List<Map<String, dynamic>>.from(defaultBenchmarkConflicts);
      }
      _setError(e.toString());
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<void> loadAuditLogs({bool silent = false}) async {
    if (currentProjectId == null && projects.isNotEmpty) {
      currentProjectId = projects.first.id;
    }
    if (currentProjectId == null) return;
    if (!silent) _setLoading(true);
    _setError(null);
    try {
      final res = await apiService.getAuditLogs(currentProjectId!);
      final rawList = _extractList(res, ['auditLogs', 'logs', 'audit_logs']);
      final parsed = <Map<String, dynamic>>[];
      for (final item in rawList) {
        if (item is Map) {
          try {
            final l = Map<String, dynamic>.from(item);
            l['action'] = l['action'] ?? 'LOG_RECORDED';
            l['time'] = l['time'] ?? l['timestamp'] ?? 'Just now';
            l['actor'] = l['actor'] ?? (l['actorName'] != null ? '${l['actorName']} (${l['actorRole'] ?? ''})' : 'System Automation');
            l['entityType'] = l['entityType'] ?? 'SYSTEM';
            l['entityId'] = l['entityId'] ?? '';
            l['details'] = l['details'] ?? l['reason'] ?? 'State updated';
            parsed.add(l);
          } catch (e) {
            debugPrint('Audit log parse error: $e');
          }
        }
      }
      auditLogs = parsed;
      if (auditLogs.isEmpty && (currentProjectId == 'PRJ-OIL-2026' || currentProjectId == defaultBenchmarkProject.id)) {
        auditLogs = List<Map<String, dynamic>>.from(defaultBenchmarkAuditLogs);
      }
    } catch (e) {
      if (auditLogs.isEmpty) {
        auditLogs = List<Map<String, dynamic>>.from(defaultBenchmarkAuditLogs);
      }
      _setError(e.toString());
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<dynamic> logAuditEvent(Map<String, dynamic> data) async {
    try {
      final res = await apiService.logAuditEvent(data);
      if (currentProjectId != null) {
        await loadAuditLogs(silent: true);
      }
      return res;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<bool> submitDpr(Map<String, dynamic> data) async {
    if (currentProjectId == null && projects.isNotEmpty) {
      currentProjectId = projects.first.id;
    }
    if (currentProjectId == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      final actId = data['activityId'] ?? data['activityCode'];
      ActivityModel? act;
      int actIndex = -1;
      if (activities.isNotEmpty) {
        for (int i = 0; i < activities.length; i++) {
          if (activities[i].id == actId || activities[i].code == actId) {
            act = activities[i];
            actIndex = i;
            break;
          }
        }
        if (act == null) {
          act = activities.first;
          actIndex = 0;
        }
      }

      final double qty = (data['completedQuantity'] ?? data['quantity'] ?? 0.0) is num
          ? (data['completedQuantity'] ?? data['quantity'] ?? 0.0).toDouble()
          : (double.tryParse((data['completedQuantity'] ?? data['quantity'] ?? '0').toString()) ?? 0.0);

      // Optimistic state update in local activities list
      if (actIndex != -1 && act != null) {
        final newInstalled = act.installedQuantity + qty;
        final newPct = act.plannedQuantity > 0 ? (newInstalled / act.plannedQuantity * 100.0).clamp(0.0, 100.0) : act.validatedConsensusProgress;
        activities[actIndex] = act.copyWith(
          installedQuantity: newInstalled,
          contractorReportedProgress: newPct,
          validatedConsensusProgress: newPct,
        );
      }

      final enrichedData = Map<String, dynamic>.from(data);
      enrichedData['activityCode'] = data['activityCode'] ?? act?.code ?? 'PIP-L5-024';
      enrichedData['completedQuantity'] = qty;
      if (!enrichedData.containsKey('unit') && act != null) {
        enrichedData['unit'] = act.unit;
      }
      if (!enrichedData.containsKey('reportedBy') && currentUser != null) {
        enrichedData['reportedBy'] = currentUser!['name'] ?? 'Field Supervisor';
      }

      // Add to local audit logs
      auditLogs.insert(0, {
        'id': 'LOG-${DateTime.now().millisecondsSinceEpoch}',
        'action': 'DPR_SUBMITTED',
        'actor': enrichedData['reportedBy'] ?? 'Field Supervisor',
        'time': 'Just now',
        'details': 'Installed $qty ${enrichedData['unit'] ?? 'units'} for ${enrichedData['activityCode']}',
      });

      // Attempt online API sync
      try {
        await apiService.submitDpr(currentProjectId!, enrichedData);
      } catch (netErr) {
        // Enqueue to offline sync engine for resilient background replay
        try {
          await OfflineSyncService.instance.enqueueDpr(
            projectId: currentProjectId!,
            activityCode: enrichedData['activityCode'] ?? 'PIP-L5-024',
            completedQuantity: qty,
            unit: enrichedData['unit'] ?? 'units',
            delayReason: (data['delayReason'] ?? 'None').toString(),
            notes: (data['notes'] ?? '').toString(),
            reportedBy: (enrichedData['reportedBy'] ?? 'Field Supervisor').toString(),
          );
        } catch (_) {}
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clockInWorker(String workerId, double lat, double lng) async {
    _setLoading(true);
    _setError(null);
    try {
      final idx = workers.indexWhere((w) => w.id == workerId || w.badgeNumber == workerId);
      if (idx != -1) {
        workers[idx] = workers[idx].copyWith(
          attendanceStatus: 'VERIFIED_PRESENT',
          lastClockIn: 'Just now',
        );
      }

      try {
        await apiService.clockIn(workerId, lat, lng);
      } catch (netErr) {
        try {
          final w = idx != -1 ? workers[idx] : null;
          await OfflineSyncService.instance.enqueueGpsClockIn(
            workerId: workerId,
            workerName: w?.name ?? 'Site Worker',
            badgeNumber: w?.badgeNumber ?? workerId,
            latitude: lat,
            longitude: lng,
            status: 'VERIFIED_PRESENT',
          );
        } catch (_) {}
      }

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resolveConflict(String conflictId, String note) async {
    _setLoading(true);
    _setError(null);
    try {
      final idx = conflicts.indexWhere((c) => c['id'] == conflictId);
      if (idx != -1) {
        conflicts[idx]['status'] = 'RESOLVED';
        conflicts[idx]['resolutionNote'] = note;
      }
      auditLogs.insert(0, {
        'id': 'LOG-${DateTime.now().millisecondsSinceEpoch}',
        'action': 'CONFLICT_RESOLVED',
        'actor': currentUser?['name'] ?? 'Lead Adjudicator',
        'time': 'Just now',
        'details': 'Conflict $conflictId resolved: $note',
      });
      notifyListeners();

      try {
        await apiService.resolveConflict(conflictId, note);
      } catch (_) {}
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<dynamic> submitLinking(String rawText, {String source = 'VOICE_HINDI'}) async {
    if (currentProjectId == null) return null;
    try {
      return await apiService.submitLinking(
        currentProjectId!,
        rawText,
        source,
        reportedBy: currentUser?['name'] ?? 'Site Supervisor',
      );
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }
}
