import 'package:flutter/foundation.dart';
import '../core/models/app_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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
      if (currentUser != null) {
        await loadProjects(silent: true);
        if (projects.isNotEmpty && currentProjectId == null) {
          currentProjectId = projects.first.id;
          await loadAllData(silent: true);
        }
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
      final res = await apiService.createProject(projectData);
      if (res != null) {
        await loadProjects(silent: true);
        if (projects.isNotEmpty) {
          final created = projects.firstWhere(
            (p) => p.name == projectData['name'] || p.code == projectData['code'] || p.id == projectData['id'],
            orElse: () => projects.first,
          );
          currentProjectId = created.id;
          await loadAllData(silent: true);
        }
        return true;
      }
      return false;
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
      _setError(e.toString());
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<void> loadActivities({bool silent = false}) async {
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
    } catch (e) {
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
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<bool> createWorker(Map<String, dynamic> data) async {
    if (currentProjectId == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      await apiService.createWorker(currentProjectId!, data);
      await loadWorkers(silent: true);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMaterials({bool silent = false}) async {
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
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<bool> createMaterialTx(Map<String, dynamic> data) async {
    if (currentProjectId == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      await apiService.createMaterialTx(currentProjectId!, data);
      await loadMaterials(silent: true);
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
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<void> loadAuditLogs({bool silent = false}) async {
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
    } catch (e) {
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
    if (currentProjectId == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      final actId = data['activityId'] ?? data['activityCode'];
      ActivityModel? act;
      if (activities.isNotEmpty) {
        try {
          act = activities.firstWhere(
            (a) => a.id == actId || a.code == actId,
            orElse: () => activities.first,
          );
        } catch (_) {
          act = activities.first;
        }
      }

      final enrichedData = Map<String, dynamic>.from(data);
      enrichedData['activityCode'] = data['activityCode'] ?? act?.code ?? 'PIP-L5-024';
      enrichedData['completedQuantity'] = data['completedQuantity'] ?? data['quantity'] ?? 0.0;
      if (!enrichedData.containsKey('unit') && act != null) {
        enrichedData['unit'] = act.unit;
      }
      if (!enrichedData.containsKey('reportedBy') && currentUser != null) {
        enrichedData['reportedBy'] = currentUser!['name'] ?? 'Field Supervisor';
      }

      await apiService.submitDpr(currentProjectId!, enrichedData);
      await loadActivities(silent: true);
      await loadAuditLogs(silent: true);
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
      await apiService.clockIn(workerId, lat, lng);
      await loadWorkers(silent: true);
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
      await apiService.resolveConflict(conflictId, note);
      await loadConflicts(silent: true);
      await loadAuditLogs(silent: true);
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
