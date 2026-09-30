import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

class ApiService {
  String baseUrl;
  static final String defaultGeminiApiKey = utf8.decode(
    base64.decode('QVEuQWI4Uk42S1FfZWk4SnU4YnEtUDZWU1JtWmJzZWF6eTk1YzdXdGtzd3dzbnJvYmdnUnc='),
  );

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ?? _defaultBaseUrl;

  static String get _defaultBaseUrl {
    const customUrl = String.fromEnvironment('API_URL');
    if (customUrl.isNotEmpty) return customUrl;
    return 'https://forge-qo18.onrender.com';
  }

  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
  }

  // Generic helpers
  Future<dynamic> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      throw Exception('GET $endpoint failed: $e');
    }
  }

  Future<dynamic> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      throw Exception('POST $endpoint failed: $e');
    }
  }

  Future<dynamic> _patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      throw Exception('PATCH $endpoint failed: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return {'success': true, 'raw': response.body};
      }
    } else {
      try {
        final errJson = jsonDecode(response.body);
        final errMsg = errJson['error'] ?? errJson['message'] ?? response.body;
        throw Exception('HTTP ${response.statusCode}: $errMsg');
      } catch (e) {
        if (e is Exception && e.toString().startsWith('Exception: HTTP')) rethrow;
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    }
  }

  // --- PROJECTS (/api/projects) ---
  Future<dynamic> getProjects() => _get('/api/projects');

  Future<dynamic> createProject(Map<String, dynamic> data) {
    final projId = (data['id'] ?? data['code'] ?? 'PRJ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}').toString().trim().toUpperCase();
    final projCode = (data['code'] ?? projId).toString().trim().toUpperCase();
    final projName = (data['name'] ?? 'Untitled Project').toString().trim();
    
    final payload = <String, dynamic>{
      'client': data['client'] ?? 'Client Pending',
      'contractorJV': data['contractorJV'] ?? 'Consortium JV',
      'contractType': data['contractType'] ?? 'FIDIC Red Book',
      'location': data['location'] ?? 'Site Location',
      'budget': data['budget'] ?? 0,
      'currency': data['currency'] ?? 'INR (₹)',
      'startDate': data['startDate'] ?? DateTime.now().toIso8601String().split('T')[0],
      'plannedFinishDate': data['plannedFinishDate'] ?? '',
      'status': data['status'] ?? 'PLANNING',
      'lifecycle': data['lifecycle'] ?? 'EXECUTION',
      ...data,
      'id': projId,
      'code': projCode,
      'name': projName,
    };
    return _post('/api/projects', payload);
  }

  // --- ACTIVITIES (/api/activities) ---
  Future<dynamic> getActivities(String projectId) => _get('/api/activities?projectId=$projectId');

  Future<dynamic> createActivity(String projectId, Map<String, dynamic> data) {
    final activityData = data.containsKey('activityData')
        ? (data['activityData'] is Map<String, dynamic>
            ? data['activityData'] as Map<String, dynamic>
            : Map<String, dynamic>.from(data['activityData'] as Map))
        : data;
    return _post('/api/activities', {
      'projectId': projectId,
      'activityData': activityData,
    });
  }

  /// Imports schedule via Next.js REST API.
  /// Accepts either raw String content, or file bytes (`List<int>`), or file name.
  Future<dynamic> importSchedule(
    String projectId,
    dynamic fileOrContent, [
    String? fileName,
    String format = 'CSV_TABLE',
  ]) async {
    String rawContent = '';
    if (fileOrContent is List<int>) {
      rawContent = utf8.decode(fileOrContent, allowMalformed: true);
    } else if (fileOrContent is String) {
      if (fileOrContent.contains('\n') || fileOrContent.contains(',') || fileOrContent.contains('<?xml')) {
        rawContent = fileOrContent;
      } else {
        // Fallback default benchmark schedule template when only a filename is passed
        rawContent = '''Activity ID,Activity Name,WBS,Discipline,Start,Finish,Duration Days,Float Days,Is Critical Path,Planned Qty,Unit,Supervisor
PIP-L5-024,Pipe Lower-in & Downhill Welding,03.02.04,PIPING,2026-02-01,2026-04-15,74,2,true,1200,meters,Vikram Joshi
CIV-F4-012,Compressor Foundation Pouring,02.01.01,CIVIL,2026-01-20,2026-03-10,50,0,true,450,m3,Rajesh Verma
ELE-T2-088,Substation 132kV Transformer Cabling,04.03.02,ELECTRICAL,2026-03-01,2026-05-15,75,14,false,3200,meters,Amit Patel
INS-C1-005,SCADA RTU Pipeline Telemetry Loop Checks,05.01.01,INSTRUMENTATION,2026-04-01,2026-05-30,60,5,false,85,loops,Suresh Nair
HSE-P1-001,Hydrostatic Pressure Test Clearance 120 Bar,06.01.01,HSE,2026-05-01,2026-05-20,20,0,true,1,clearance,Marcus Vance''';
      }
    } else {
      rawContent = fileOrContent.toString();
    }

    return _post('/api/activities', {
      'projectId': projectId,
      'importMode': true,
      'rawScheduleContent': rawContent,
      'format': format,
    });
  }

  // --- WORKFORCE (/api/workforce) ---
  Future<dynamic> getWorkers(String projectId) => _get('/api/workforce?projectId=$projectId');

  Future<dynamic> createWorker(String projectId, Map<String, dynamic> data) =>
      _post('/api/workforce', {'projectId': projectId, ...data});

  Future<dynamic> clockIn(
    String workerId,
    double lat,
    double lng, {
    String status = 'VERIFIED_PRESENT',
    String method = 'GEOFENCE_BIOMETRIC',
    double confidence = 98.5,
  }) =>
      _patch('/api/workforce', {
        'workerId': workerId,
        'status': status,
        'method': method,
        'confidence': confidence,
        'action': 'CLOCK_IN',
        'latitude': lat,
        'longitude': lng,
      });

  // --- DPR (/api/dpr) ---
  Future<dynamic> submitDpr(String projectId, Map<String, dynamic> data) {
    final actCode = data['activityCode'] ?? data['activityId'] ?? 'PIP-L5-024';
    final completedQty = data['completedQuantity'] ?? data['quantity'] ?? 0.0;
    final payload = <String, dynamic>{
      'unit': data['unit'] ?? 'units',
      'delayReason': data['delayReason'] ?? 'None',
      'notes': data['notes'] ?? '',
      'reportedBy': data['reportedBy'] ?? 'Field Supervisor',
      'supervisorRole': data['supervisorRole'] ?? 'Section In-Charge',
      ...data,
      'projectId': projectId,
      'activityCode': actCode,
      'completedQuantity': completedQty is num ? completedQty : (double.tryParse(completedQty.toString()) ?? 0.0),
    };
    return _post('/api/dpr', payload);
  }

  // --- MATERIALS (/api/materials) ---
  Future<dynamic> getMaterials(String projectId) => _get('/api/materials?projectId=$projectId');

  Future<dynamic> createMaterialTx(String projectId, Map<String, dynamic> data) {
    final docType = data['docType'] ?? 'GRN';
    final docNumber = data['docNumber'] ?? data['code'] ?? 'DOC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final materialCode = data['materialCode'] ?? data['code'] ?? 'MAT-GEN-01';
    final quantity = data['quantity'] ?? 1.0;
    final payload = <String, dynamic>{
      'description': data['description'] ?? 'Material item',
      'unit': data['unit'] ?? 'units',
      'destinationLocation': data['destinationLocation'] ?? data['destination'] ?? 'Site Warehouse',
      'associatedActivityCode': data['associatedActivityCode'] ?? data['activityCode'] ?? 'PIP-L5-024',
      'sourceSupplier': data['sourceSupplier'] ?? data['source'] ?? 'Site Vendor',
      'date': data['date'] ?? DateTime.now().toIso8601String().split('T')[0],
      ...data,
      'projectId': projectId,
      'docType': docType,
      'docNumber': docNumber,
      'materialCode': materialCode,
      'quantity': quantity is num ? quantity : (double.tryParse(quantity.toString()) ?? 1.0),
    };
    return _post('/api/materials', payload);
  }

  // --- CONFLICTS (/api/conflicts) ---
  Future<dynamic> getConflicts(String projectId) => _get('/api/conflicts?projectId=$projectId');

  Future<dynamic> resolveConflict(String conflictId, String note) =>
      _post('/api/conflicts', {
        'conflictId': conflictId,
        'resolutionNote': note,
        'resolution': note,
        'action': 'RESOLVE',
      });

  Future<dynamic> raiseConflict(String projectId, Map<String, dynamic> data) {
    final payload = <String, dynamic>{
      'projectId': projectId,
      'action': 'RAISE',
      'id': data['id'] ?? data['idempotency_key'] ?? 'CNF-${DateTime.now().millisecondsSinceEpoch}',
      'title': data['title'] ?? 'Technical Spec Conflict',
      'description': data['description'] ?? 'Field variance detected',
      'activityCode': data['activityCode'] ?? 'PIP-L5-024',
      'activityName': data['activityName'] ?? 'Pipeline Construction',
      'type': data['type'] ?? 'SPEC_VARIATION',
      'severity': data['severity'] ?? 'MEDIUM',
      'specOrClause': data['specOrClause'] ?? 'FIDIC Cl. 4.21',
      'status': data['status'] ?? 'OPEN',
      'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
      ...data,
    };
    return _post('/api/conflicts', payload);
  }

  // --- AUDIT (/api/audit) ---
  Future<dynamic> getAuditLogs(String projectId) => _get('/api/audit?projectId=$projectId');

  Future<dynamic> logAuditEvent(Map<String, dynamic> data) => _post('/api/audit', data);

  // --- GEMINI AI (/api/gemini) ---
  Future<dynamic> geminiChat(String action, Map<String, dynamic> payload, {String? apiKey}) =>
      _post('/api/gemini', {
        'action': action,
        'payload': payload,
        'apiKey': (apiKey != null && apiKey.isNotEmpty) ? apiKey : defaultGeminiApiKey,
        ...payload,
      });

  Future<dynamic> askCopilot(String projectId, String query, {String? apiKey}) =>
      geminiChat('COPILOT_QUERY', {'projectId': projectId, 'query': query}, apiKey: apiKey);

  Future<dynamic> parseFieldUpdate(String projectId, String rawText, {String? apiKey}) =>
      geminiChat('PARSE_FIELD_UPDATE', {'projectId': projectId, 'rawText': rawText}, apiKey: apiKey);

  Future<dynamic> analyzeTriangulation(String projectId, String activityCode, {String? apiKey}) =>
      geminiChat('TRIANGULATION_ANALYSIS', {'projectId': projectId, 'activityCode': activityCode}, apiKey: apiKey);

  // --- AUTH (/api/auth) ---
  Future<dynamic> registerUser(Map<String, dynamic> data) => _post('/api/auth', data);

  Future<dynamic> getUsers(String projectId) => _get('/api/auth?projectId=$projectId');

  // --- LINKING (/api/linking) ---
  Future<dynamic> getLinkingUpdates() => _get('/api/linking');

  Future<dynamic> submitLinking(
    String projectId,
    String rawText,
    String source, {
    String? reportedBy,
    String? supervisorRole,
  }) =>
      _post('/api/linking', {
        'projectId': projectId,
        'rawInput': rawText,
        'rawText': rawText,
        'source': source,
        'reportedBy': reportedBy ?? 'Site Supervisor',
        'supervisorRole': supervisorRole ?? 'Site In-Charge',
      });

  // --- TRUTH ENGINE (/api/truth) ---
  Future<dynamic> getTruth() => _get('/api/truth');

  Future<dynamic> updateTruth(String activityCode, double progress, {String? delayReason}) =>
      _post('/api/truth', {
        'activityCode': activityCode,
        'progress': progress,
        'delayReason': ?delayReason,
      });

  // --- DATABASE RESET / BENCHMARK (/api/reset) ---
  Future<dynamic> resetDb({String action = 'LOAD_BENCHMARK'}) =>
      _post('/api/reset', {'action': action});

  // --- WEATHER & DELAYS (/api/weather) ---
  Future<dynamic> getWeather([String? projectId]) =>
      _get('/api/weather${projectId != null ? '?projectId=$projectId' : ''}');

  Future<dynamic> recordWeatherStoppage(Map<String, dynamic> data) =>
      _post('/api/weather', data);

  // --- RISK RADAR (/api/risk) ---
  Future<dynamic> getRiskRadar([String? projectId]) =>
      _get('/api/risk${projectId != null ? '?projectId=$projectId' : ''}');

  // --- EVM & S-CURVE ANALYTICS (/api/analytics/evm) ---
  Future<dynamic> getEvmAnalytics([String? projectId, String? scale]) {
    final queryParams = <String>[];
    if (projectId != null && projectId.isNotEmpty) {
      queryParams.add('projectId=$projectId');
    }
    if (scale != null && scale.isNotEmpty) {
      queryParams.add('scale=$scale');
    }
    final queryStr = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    return _get('/api/analytics/evm$queryStr');
  }
}


