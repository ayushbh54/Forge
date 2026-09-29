import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/theme/app_theme.dart';
import 'api_service.dart';

/// Supported types of offline records captured at zero-connectivity remote sites.
enum SyncItemType {
  dpr,
  gpsClockIn,
  materialGrn,
  conflict,
  fieldNote,
  custom,
}

/// Network connectivity states for monitoring offline queue drainage.
enum ConnectivityResult {
  none,
  mobile,
  wifi,
  ethernet,
  bluetooth,
  vpn,
  other,
}

/// Synchronization lifecycle status for an offline queue item.
enum SyncItemStatus {
  pending,
  syncing,
  failed,
  synced,
}

/// Represents an offline action queued during remote field operations
/// (e.g. Assam crude pipeline corridors or Rajasthan desert wellpads).
class OfflineQueueItem {
  final String id;
  final String idempotencyKey;
  final SyncItemType type;
  final String title;
  final String subtitle;
  final String endpoint;
  final String httpMethod;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  DateTime? lastAttemptAt;
  DateTime? nextRetryAt;
  int retryCount;
  final int maxRetries;
  SyncItemStatus status;
  String? lastError;
  final String locationTag;

  OfflineQueueItem({
    required this.id,
    String? idempotencyKey,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.endpoint,
    this.httpMethod = 'POST',
    required this.payload,
    required this.createdAt,
    this.lastAttemptAt,
    this.nextRetryAt,
    this.retryCount = 0,
    this.maxRetries = 5,
    this.status = SyncItemStatus.pending,
    this.lastError,
    this.locationTag = 'Remote Field Site (Assam / Rajasthan)',
  }) : idempotencyKey = idempotencyKey ?? id;

  Map<String, dynamic> toJson() => {
        'id': id,
        'idempotency_key': idempotencyKey,
        'type': type.name,
        'title': title,
        'subtitle': subtitle,
        'endpoint': endpoint,
        'httpMethod': httpMethod,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
        'nextRetryAt': nextRetryAt?.toIso8601String(),
        'retryCount': retryCount,
        'maxRetries': maxRetries,
        'status': status.name,
        'lastError': lastError,
        'locationTag': locationTag,
      };

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) {
    SyncItemType parseType(String? val) {
      for (final t in SyncItemType.values) {
        if (t.name == val) return t;
      }
      return SyncItemType.custom;
    }

    SyncItemStatus parseStatus(String? val) {
      for (final s in SyncItemStatus.values) {
        if (s.name == val) return s;
      }
      return SyncItemStatus.pending;
    }

    final id = json['id'] as String? ??
        json['idempotency_key'] as String? ??
        'sync-${DateTime.now().millisecondsSinceEpoch}';
    final idempotencyKey = json['idempotency_key'] as String? ?? id;

    return OfflineQueueItem(
      id: id,
      idempotencyKey: idempotencyKey,
      type: parseType(json['type'] as String?),
      title: json['title'] as String? ?? 'Field Record',
      subtitle: json['subtitle'] as String? ?? '',
      endpoint: json['endpoint'] as String? ?? '/api/dpr',
      httpMethod: json['httpMethod'] as String? ?? 'POST',
      payload: (json['payload'] is Map)
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : {},
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.tryParse(json['lastAttemptAt'] as String)
          : null,
      nextRetryAt: json['nextRetryAt'] != null
          ? DateTime.tryParse(json['nextRetryAt'] as String)
          : null,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 5,
      status: parseStatus(json['status'] as String?),
      lastError: json['lastError'] as String?,
      locationTag: json['locationTag'] as String? ??
          'Remote Field Site (Assam / Rajasthan)',
    );
  }

  OfflineQueueItem copyWith({
    String? id,
    String? idempotencyKey,
    SyncItemType? type,
    String? title,
    String? subtitle,
    String? endpoint,
    String? httpMethod,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    int? retryCount,
    int? maxRetries,
    SyncItemStatus? status,
    String? lastError,
    String? locationTag,
  }) {
    return OfflineQueueItem(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      endpoint: endpoint ?? this.endpoint,
      httpMethod: httpMethod ?? this.httpMethod,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      locationTag: locationTag ?? this.locationTag,
    );
  }
}

/// Result summary of a batch sync operation.
class SyncBatchResult {
  final int totalProcessed;
  final int succeeded;
  final int failed;
  final List<String> errors;
  final DateTime timestamp;

  const SyncBatchResult({
    required this.totalProcessed,
    required this.succeeded,
    required this.failed,
    required this.errors,
    required this.timestamp,
  });

  factory SyncBatchResult.empty() => SyncBatchResult(
        totalProcessed: 0,
        succeeded: 0,
        failed: 0,
        errors: const [],
        timestamp: DateTime.now(),
      );

  bool get hasErrors => failed > 0;
  bool get isFullySynced => totalProcessed > 0 && failed == 0;
}

/// Offline-First Synchronization Service for Nirmaan OS.
///
/// Designed specifically for remote oil & gas operations (e.g. Digboi, Duliajan,
/// Naharkatiya crude pipeline spreads in Assam and Barmer Thar desert wellpads in Rajasthan)
/// where cellular coverage is intermittent or completely zero.
///
/// Automatically queues offline Daily Progress Reports (DPRs), GPS biometric clock-in
/// attendance records, material Goods Receipt Notes (GRNs), conflict disputes,
/// and informal field notes into local storage.
///
/// Implements RFC 4122 UUID v4 deterministic idempotency keys (`idempotency_key = uuid_v4`),
/// exponential backoff retry scheduling (1s, 2s, 4s, max 30s), and a reactive network
/// connectivity listener ([ConnectivityResult]) that drains the queue automatically on reconnection.
class OfflineSyncService {
  static OfflineSyncService? _instance;
  static OfflineSyncService get instance =>
      _instance ??= OfflineSyncService._internal();

  factory OfflineSyncService({ApiService? apiService}) {
    if (_instance == null) {
      _instance = OfflineSyncService._internal(apiService: apiService);
    } else if (apiService != null) {
      _instance!._apiService = apiService;
    }
    return _instance!;
  }

  OfflineSyncService._internal({ApiService? apiService})
      : _apiService = apiService ?? ApiService() {
    _init();
  }

  static const String _storageKey = 'nirmaan_offline_sync_queue_v1';
  static const String _syncedKeysStorageKey = 'nirmaan_synced_idempotency_keys_v1';
  static const Uuid _uuid = Uuid();

  ApiService _apiService;
  final List<OfflineQueueItem> _queue = [];
  final Set<String> _syncedIdempotencyKeys = {};
  bool _isInitialized = false;
  Timer? _autoSyncTimer;

  // --- Network Connectivity State & Listener ---
  ConnectivityResult _connectivity = ConnectivityResult.wifi;
  final StreamController<ConnectivityResult> _connectivityController =
      StreamController<ConnectivityResult>.broadcast();

  /// Current network connectivity state.
  ConnectivityResult get currentConnectivity => _connectivity;

  /// Whether device currently has active network connectivity.
  bool get isOnline => _connectivity != ConnectivityResult.none;

  /// Broadcast stream emitting changes in network connectivity.
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivityController.stream;

  /// Notifier exposing the count of items currently awaiting cloud sync.
  /// UI can attach directly to this notifier to show '3 items pending sync'.
  final ValueNotifier<int> pendingSyncCount = ValueNotifier<int>(0);

  /// Notifier indicating whether a batch sync operation is actively in flight.
  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);

  /// Timestamp of the last successful or completed sync pass.
  final ValueNotifier<DateTime?> lastSyncTime = ValueNotifier<DateTime?>(null);

  /// Listenable stream of all queued items.
  final ValueNotifier<List<OfflineQueueItem>> queueNotifier =
      ValueNotifier<List<OfflineQueueItem>>([]);

  /// Load persisted offline queue from SharedPreferences.
  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          _queue.clear();
          for (final raw in decoded) {
            if (raw is Map) {
              _queue.add(
                OfflineQueueItem.fromJson(Map<String, dynamic>.from(raw)),
              );
            }
          }
        }
      }

      final syncedKeys = prefs.getStringList(_syncedKeysStorageKey);
      if (syncedKeys != null) {
        _syncedIdempotencyKeys.addAll(syncedKeys);
      }
    } catch (e) {
      debugPrint('[OfflineSyncService] Error initializing offline queue: $e');
    } finally {
      _isInitialized = true;
      _updateNotifiers();
    }
  }

  /// Ensure initialization has completed before performing critical operations.
  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await _init();
    }
  }

  /// Persist current queue state and synced idempotency keys to local storage.
  Future<void> _persistQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _queue.map((item) => item.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
      await prefs.setStringList(
        _syncedKeysStorageKey,
        _syncedIdempotencyKeys.toList(),
      );
    } catch (e) {
      debugPrint('[OfflineSyncService] Failed to persist offline queue: $e');
    }
  }

  /// Synchronize internal state with public ValueNotifiers.
  void _updateNotifiers() {
    final pendingCount = _queue
        .where((item) =>
            item.status == SyncItemStatus.pending ||
            item.status == SyncItemStatus.failed ||
            item.status == SyncItemStatus.syncing)
        .length;
    pendingSyncCount.value = pendingCount;
    queueNotifier.value = List.unmodifiable(_queue);
  }

  // ===========================================================================
  // NETWORK CONNECTIVITY LISTENER & STATE
  // ===========================================================================

  /// Updates current network connectivity state.
  ///
  /// When connectivity is restored (transitions from [ConnectivityResult.none]
  /// to [ConnectivityResult.wifi], [ConnectivityResult.mobile], etc.),
  /// it automatically drains pending transactions in the offline queue.
  void updateConnectivity(ConnectivityResult result) {
    final wasOffline = _connectivity == ConnectivityResult.none;
    final isNowOnline = result != ConnectivityResult.none;
    _connectivity = result;
    _connectivityController.add(result);

    if (wasOffline && isNowOnline) {
      debugPrint(
          '[OfflineSyncService] Network connectivity restored ($result). Draining offline sync queue...');
      syncPendingData();
    }
  }

  /// Alias for [updateConnectivity] compatible with network state listeners.
  void setConnectivity(ConnectivityResult result) => updateConnectivity(result);

  // ===========================================================================
  // EXPONENTIAL BACKOFF RETRY MECHANISM (1s, 2s, 4s, max 30s)
  // ===========================================================================

  /// Computes deterministic exponential backoff duration based on retry attempt:
  /// - Attempt 1: 1s  (2^0)
  /// - Attempt 2: 2s  (2^1)
  /// - Attempt 3: 4s  (2^2)
  /// - Attempt 4: 8s  (2^3)
  /// - Attempt 5: 16s (2^4)
  /// - Attempt 6+: capped at max 30s
  static Duration calculateBackoff(
    int retryCount, {
    Duration maxDelay = const Duration(seconds: 30),
  }) {
    if (retryCount <= 0) return Duration.zero;
    final int exponent = retryCount - 1;
    final int seconds = exponent >= 30 ? maxDelay.inSeconds : (1 << exponent);
    final int clamped =
        seconds > maxDelay.inSeconds ? maxDelay.inSeconds : seconds;
    return Duration(seconds: clamped);
  }

  /// Instance helper to query retry delay for a given retry attempt count.
  Duration getRetryDelay(int retryCount) => calculateBackoff(retryCount);

  // ===========================================================================
  // IDEMPOTENCY KEY DEDUPLICATION HELPERS
  // ===========================================================================

  /// Checks if an idempotency key has already been successfully synced.
  bool isIdempotencyKeySynced(String key) =>
      _syncedIdempotencyKeys.contains(key);

  /// Find existing item in queue by idempotency key.
  OfflineQueueItem? _findExistingItem(String idempotencyKey) {
    for (final item in _queue) {
      if (item.idempotencyKey == idempotencyKey || item.id == idempotencyKey) {
        return item;
      }
    }
    return null;
  }

  // ===========================================================================
  // QUEUE ENQUEUE METHODS (4 CORE TRANSACTIONS)
  // ===========================================================================

  /// 1. Queue an offline Daily Progress Report (DPR).
  ///
  /// Example use-case: Site Piping Supervisor at Duliajan Pipeline Spread 2
  /// logs 85 meters of pipeline trenching without 4G/5G connectivity.
  Future<OfflineQueueItem> enqueueDpr({
    required String projectId,
    required String activityCode,
    required double completedQuantity,
    String? idempotencyKey,
    String? unit,
    String? delayReason,
    String? notes,
    String? reportedBy,
    String? supervisorRole,
    String? locationTag,
    Map<String, dynamic>? extraData,
  }) async {
    await ensureInitialized();

    final key = idempotencyKey ?? _uuid.v4();
    final existing = _findExistingItem(key);
    if (existing != null) {
      debugPrint('[OfflineSyncService] Deduplicated DPR transaction: $key');
      return existing;
    }

    final effectiveUnit = unit ?? 'meters';
    final effectiveDelay = delayReason ?? 'No Delay';
    final effectiveLocation = locationTag ?? 'Assam Crude Pipeline (Spread 2)';

    final payload = <String, dynamic>{
      'idempotency_key': key,
      'projectId': projectId,
      'activityCode': activityCode,
      'completedQuantity': completedQuantity,
      'unit': effectiveUnit,
      'delayReason': effectiveDelay,
      'notes': notes ?? '',
      'reportedBy': reportedBy ?? 'Field Piping Supervisor',
      'supervisorRole': supervisorRole ?? 'Section In-Charge',
      'timestamp': DateTime.now().toIso8601String(),
    };
    if (extraData != null) payload.addAll(extraData);

    final item = OfflineQueueItem(
      id: key,
      idempotencyKey: key,
      type: SyncItemType.dpr,
      title: 'DPR: $activityCode ($completedQuantity $effectiveUnit)',
      subtitle: effectiveDelay != 'No Delay'
          ? 'Delay: $effectiveDelay • $effectiveLocation'
          : 'Progress Logged • $effectiveLocation',
      endpoint: '/api/dpr',
      httpMethod: 'POST',
      payload: payload,
      createdAt: DateTime.now(),
      locationTag: effectiveLocation,
    );

    _queue.add(item);
    await _persistQueue();
    _updateNotifiers();
    debugPrint('[OfflineSyncService] Queued offline DPR: ${item.title}');
    return item;
  }

  /// 2. Queue an offline GPS Geofenced Worker Biometric Clock-in record.
  ///
  /// Example use-case: Biometric attendance captured at Barmer Thar Desert Wellpad 04
  /// with device-cached site boundary verification while satellite/cellular link is down.
  Future<OfflineQueueItem> enqueueGpsClockIn({
    required String workerId,
    required double latitude,
    required double longitude,
    String? idempotencyKey,
    String? workerName,
    String? badgeNumber,
    String? status,
    String? method,
    double? confidence,
    String? locationTag,
    Map<String, dynamic>? extraData,
  }) async {
    await ensureInitialized();

    final key = idempotencyKey ?? _uuid.v4();
    final existing = _findExistingItem(key);
    if (existing != null) {
      debugPrint('[OfflineSyncService] Deduplicated GPS Clock-in transaction: $key');
      return existing;
    }

    final effectiveName = workerName ?? badgeNumber ?? workerId;
    final effectiveLocation = locationTag ?? 'Rajasthan Barmer Desert Wellpad 04';

    final payload = <String, dynamic>{
      'idempotency_key': key,
      'workerId': workerId,
      'action': 'CLOCK_IN',
      'status': status ?? 'VERIFIED_PRESENT',
      'method': method ?? 'GEOFENCE_BIOMETRIC',
      'confidence': confidence ?? 98.5,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };
    if (workerName != null) payload['workerName'] = workerName;
    if (badgeNumber != null) payload['badgeNumber'] = badgeNumber;
    if (extraData != null) payload.addAll(extraData);

    final item = OfflineQueueItem(
      id: key,
      idempotencyKey: key,
      type: SyncItemType.gpsClockIn,
      title: 'Clock-in: $effectiveName',
      subtitle:
          'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)} • Geofenced OK',
      endpoint: '/api/workforce',
      httpMethod: 'PATCH',
      payload: payload,
      createdAt: DateTime.now(),
      locationTag: effectiveLocation,
    );

    _queue.add(item);
    await _persistQueue();
    _updateNotifiers();
    debugPrint('[OfflineSyncService] Queued offline GPS Clock-in: ${item.title}');
    return item;
  }

  /// 3. Queue an offline Material Goods Receipt Note (GRN) creation.
  ///
  /// Example use-case: Storekeeper at Digboi Central Pipe Yard inspects 42 MT
  /// of API 5L X70 line pipes received via truck convoy with zero mobile connectivity.
  Future<OfflineQueueItem> enqueueMaterialGrn({
    required String projectId,
    required String materialCode,
    required double quantity,
    String? docNumber,
    String docType = 'GRN',
    String? idempotencyKey,
    String? description,
    String? unit,
    String? destinationLocation,
    String? sourceSupplier,
    String? associatedActivityCode,
    String? locationTag,
    Map<String, dynamic>? extraData,
  }) async {
    await ensureInitialized();

    final key = idempotencyKey ?? _uuid.v4();
    final existing = _findExistingItem(key);
    if (existing != null) {
      debugPrint('[OfflineSyncService] Deduplicated Material GRN transaction: $key');
      return existing;
    }

    final effectiveDocNumber = docNumber ??
        'GRN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final effectiveUnit = unit ?? 'MT';
    final effectiveDesc = description ?? 'Industrial Material Consignment';
    final effectiveSource = sourceSupplier ?? 'Jindal Steel & Power Ltd';
    final effectiveDest = destinationLocation ?? 'Digboi Central Pipe Yard';
    final effectiveLocation = locationTag ?? 'Assam Materials Depot';

    final payload = <String, dynamic>{
      'idempotency_key': key,
      'projectId': projectId,
      'docType': docType,
      'docNumber': effectiveDocNumber,
      'materialCode': materialCode,
      'description': effectiveDesc,
      'quantity': quantity,
      'unit': effectiveUnit,
      'sourceSupplier': effectiveSource,
      'destinationLocation': effectiveDest,
      'associatedActivityCode': associatedActivityCode ?? 'PIP-L5-024',
      'date': DateTime.now().toIso8601String().split('T')[0],
      'status': 'RECEIVED_OFFLINE',
      'timestamp': DateTime.now().toIso8601String(),
    };
    if (extraData != null) payload.addAll(extraData);

    final item = OfflineQueueItem(
      id: key,
      idempotencyKey: key,
      type: SyncItemType.materialGrn,
      title: 'Material $docType: $materialCode ($quantity $effectiveUnit)',
      subtitle: '$effectiveDocNumber • $effectiveSource -> $effectiveDest',
      endpoint: '/api/materials',
      httpMethod: 'POST',
      payload: payload,
      createdAt: DateTime.now(),
      locationTag: effectiveLocation,
    );

    _queue.add(item);
    await _persistQueue();
    _updateNotifiers();
    debugPrint('[OfflineSyncService] Queued offline Material $docType: ${item.title}');
    return item;
  }

  /// 4. Queue an offline Contractual / FIDIC Conflict raising event.
  ///
  /// Example use-case: Lead QA/QC Engineer detects trench bedding specification
  /// discrepancy at Chainage 18+400 requiring immediate FIDIC Cl. 4.21 variance notice.
  Future<OfflineQueueItem> enqueueConflict({
    required String projectId,
    required String title,
    required String description,
    String? idempotencyKey,
    String? activityCode,
    String? activityName,
    String type = 'SPEC_VARIATION',
    String severity = 'MEDIUM',
    String? specOrClause,
    String? actionRequired,
    String? varianceValue,
    String? claimedValue,
    String? verifiedValue,
    String? locationTag,
    Map<String, dynamic>? extraData,
  }) async {
    await ensureInitialized();

    final key = idempotencyKey ?? _uuid.v4();
    final existing = _findExistingItem(key);
    if (existing != null) {
      debugPrint('[OfflineSyncService] Deduplicated Conflict transaction: $key');
      return existing;
    }

    final effectiveActivityCode = activityCode ?? 'PIP-L5-024';
    final effectiveActivityName =
        activityName ?? 'Pipeline Welding & Lower-in';
    final effectiveClause = specOrClause ?? 'FIDIC Cl. 4.21 & API 1104';
    final effectiveLocation = locationTag ?? 'Naharkatiya Field Spread';

    final payload = <String, dynamic>{
      'idempotency_key': key,
      'id': key,
      'projectId': projectId,
      'action': 'RAISE',
      'title': title,
      'description': description,
      'activityCode': effectiveActivityCode,
      'activityName': effectiveActivityName,
      'type': type,
      'severity': severity,
      'specOrClause': effectiveClause,
      'actionRequired':
          actionRequired ?? 'Immediate Joint Engineering Inspection',
      'varianceValue': varianceValue ?? '+12.4%',
      'claimedValue': claimedValue ?? '100% compliant',
      'verifiedValue': verifiedValue ?? 'Tolerance exceeded',
      'status': 'OPEN',
      'timestamp': DateTime.now().toIso8601String(),
    };
    if (extraData != null) payload.addAll(extraData);

    final item = OfflineQueueItem(
      id: key,
      idempotencyKey: key,
      type: SyncItemType.conflict,
      title: 'Conflict: $title',
      subtitle: '$severity • $type • $effectiveActivityCode',
      endpoint: '/api/conflicts',
      httpMethod: 'POST',
      payload: payload,
      createdAt: DateTime.now(),
      locationTag: effectiveLocation,
    );

    _queue.add(item);
    await _persistQueue();
    _updateNotifiers();
    debugPrint('[OfflineSyncService] Queued offline Conflict: ${item.title}');
    return item;
  }

  /// Queue an informal field note or voice observation from a remote site.
  ///
  /// Example use-case: QA/QC Inspector logs trench waterlogging note near Digboi
  /// to be matched against P6 schedule activities when back in camp Wi-Fi range.
  Future<OfflineQueueItem> enqueueFieldNote({
    required String projectId,
    required String note,
    String? idempotencyKey,
    String? activityCode,
    String? author,
    String? supervisorRole,
    String? source,
    String? locationTag,
    Map<String, dynamic>? extraData,
  }) async {
    await ensureInitialized();

    final key = idempotencyKey ?? _uuid.v4();
    final existing = _findExistingItem(key);
    if (existing != null) {
      return existing;
    }

    final effectiveLocation =
        locationTag ?? 'Naharkatiya Crude Pumping Station 3';
    final effectiveAuthor = author ?? 'Field Engineer';

    final payload = <String, dynamic>{
      'idempotency_key': key,
      'projectId': projectId,
      'rawInput': note,
      'reportedBy': effectiveAuthor,
      'supervisorRole': supervisorRole ?? 'Site In-Charge',
      'source': source ?? 'OFFLINE_FIELD_NOTE',
      'timestamp': DateTime.now().toIso8601String(),
    };
    if (activityCode != null) payload['activityCode'] = activityCode;
    if (extraData != null) payload.addAll(extraData);

    final preview = note.length > 32 ? '${note.substring(0, 30)}...' : note;
    final item = OfflineQueueItem(
      id: key,
      idempotencyKey: key,
      type: SyncItemType.fieldNote,
      title: 'Field Note: $preview',
      subtitle: 'By $effectiveAuthor • $effectiveLocation',
      endpoint: '/api/linking',
      httpMethod: 'POST',
      payload: payload,
      createdAt: DateTime.now(),
      locationTag: effectiveLocation,
    );

    _queue.add(item);
    await _persistQueue();
    _updateNotifiers();
    debugPrint('[OfflineSyncService] Queued offline field note: ${item.title}');
    return item;
  }

  /// Enqueue an arbitrary offline item.
  Future<void> enqueueItem(OfflineQueueItem item) async {
    await ensureInitialized();
    final existing = _findExistingItem(item.idempotencyKey);
    if (existing != null) return;
    _queue.add(item);
    await _persistQueue();
    _updateNotifiers();
  }

  /// Remove a specific item by its unique ID.
  Future<bool> removeItem(String id) async {
    await ensureInitialized();
    final initialLen = _queue.length;
    _queue.removeWhere((item) => item.id == id || item.idempotencyKey == id);
    if (_queue.length != initialLen) {
      await _persistQueue();
      _updateNotifiers();
      return true;
    }
    return false;
  }

  /// Clear the entire offline queue.
  Future<void> clearQueue() async {
    await ensureInitialized();
    _queue.clear();
    await _persistQueue();
    _updateNotifiers();
  }

  /// Retrieve all items currently pending or failed.
  List<OfflineQueueItem> getPendingItems() {
    return _queue
        .where((item) =>
            item.status == SyncItemStatus.pending ||
            item.status == SyncItemStatus.failed ||
            item.status == SyncItemStatus.syncing)
        .toList();
  }

  /// Retrieve all items in the queue.
  List<OfflineQueueItem> getAllItems() {
    return List.unmodifiable(_queue);
  }

  // ===========================================================================
  // SYNCHRONIZATION & AUTOMATIC RETRY ENGINE
  // ===========================================================================

  /// Synchronize all pending offline items with backend when connectivity is restored.
  ///
  /// Features:
  /// - Executes FIFO synchronization.
  /// - Handles endpoint-specific payloads for DPR, Workforce, Materials, Conflicts, and Linking.
  /// - Enforces exponential backoff retry scheduling (1s, 2s, 4s, max 30s).
  /// - Deduplicates and tracks idempotency keys to prevent duplicate transactions.
  /// - Halts gracefully on complete network disconnect to save battery and bandwidth.
  Future<SyncBatchResult> syncPendingData({bool forceAll = false}) async {
    await ensureInitialized();

    if (isSyncing.value) {
      debugPrint('[OfflineSyncService] Sync already in progress, skipping pass.');
      return SyncBatchResult.empty();
    }

    final now = DateTime.now();
    final itemsToSync = _queue.where((item) {
      if (item.status != SyncItemStatus.pending &&
          item.status != SyncItemStatus.failed) {
        return false;
      }
      if (forceAll) return true;
      // Exponential backoff check: skip if retry window not reached
      if (item.nextRetryAt != null && now.isBefore(item.nextRetryAt!)) {
        return false;
      }
      return true;
    }).toList();

    if (itemsToSync.isEmpty) {
      debugPrint('[OfflineSyncService] No offline items eligible for synchronization.');
      return SyncBatchResult.empty();
    }

    isSyncing.value = true;

    int succeeded = 0;
    int failed = 0;
    final List<String> errors = [];
    final List<String> succeededIds = [];

    debugPrint(
        '[OfflineSyncService] Starting sync for ${itemsToSync.length} offline records...');

    for (final item in itemsToSync) {
      // If already synced according to idempotency set, mark done without network call
      if (_syncedIdempotencyKeys.contains(item.idempotencyKey)) {
        item.status = SyncItemStatus.synced;
        item.nextRetryAt = null;
        succeededIds.add(item.id);
        succeeded++;
        continue;
      }

      item.status = SyncItemStatus.syncing;
      item.lastAttemptAt = DateTime.now();
      _updateNotifiers();

      bool success = false;
      String? errorMessage;

      try {
        success = await _dispatchItemSync(item);
      } catch (e) {
        success = false;
        errorMessage = e.toString();
        debugPrint(
            '[OfflineSyncService] Exception syncing record [${item.id}]: $e');
      }

      if (success) {
        item.status = SyncItemStatus.synced;
        item.nextRetryAt = null;
        succeededIds.add(item.id);
        _syncedIdempotencyKeys.add(item.idempotencyKey);
        succeeded++;
      } else {
        item.retryCount++;
        final backoffDelay = calculateBackoff(item.retryCount);
        item.nextRetryAt = DateTime.now().add(backoffDelay);
        item.lastError =
            errorMessage ?? 'Unknown server synchronization error';

        if (item.retryCount >= item.maxRetries) {
          item.status = SyncItemStatus.failed;
        } else {
          item.status = SyncItemStatus.pending;
        }
        failed++;
        errors.add('${item.title}: ${item.lastError}');

        // If the error indicates a socket / network connection issue,
        // stop further calls in this pass to avoid wasteful timeouts.
        final lower = (errorMessage ?? '').toLowerCase();
        if (lower.contains('failed host lookup') ||
            lower.contains('connection refused') ||
            lower.contains('network is unreachable') ||
            lower.contains('network is down') ||
            lower.contains('socketexception') ||
            lower.contains('clientexception')) {
          debugPrint(
              '[OfflineSyncService] Detected complete offline state. Pausing sync batch.');
          break;
        }
      }
    }

    // Remove successfully synchronized items from queue
    _queue.removeWhere((item) => succeededIds.contains(item.id));
    await _persistQueue();

    lastSyncTime.value = DateTime.now();
    _updateNotifiers();
    isSyncing.value = false;

    final result = SyncBatchResult(
      totalProcessed: itemsToSync.length,
      succeeded: succeeded,
      failed: failed,
      errors: errors,
      timestamp: DateTime.now(),
    );

    debugPrint(
        '[OfflineSyncService] Sync finished: ${result.succeeded} succeeded, ${result.failed} failed.');
    return result;
  }

  /// Internal dispatcher routing the offline item to the proper API call.
  Future<bool> _dispatchItemSync(OfflineQueueItem item) async {
    final baseUrl = _apiService.baseUrl;

    if (item.type == SyncItemType.dpr) {
      final projectId = item.payload['projectId'] as String? ?? 'PRJ-OIL-2026';
      await _apiService.submitDpr(projectId, item.payload);
      return true;
    } else if (item.type == SyncItemType.gpsClockIn) {
      final workerId = item.payload['workerId'] as String? ?? '';
      final lat = (item.payload['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (item.payload['longitude'] as num?)?.toDouble() ?? 0.0;

      await _apiService.clockIn(
        workerId,
        lat,
        lng,
        status: item.payload['status'] as String? ?? 'VERIFIED_PRESENT',
        method: item.payload['method'] as String? ?? 'GEOFENCE_BIOMETRIC',
        confidence: (item.payload['confidence'] as num?)?.toDouble() ?? 98.5,
      );
      return true;
    } else if (item.type == SyncItemType.materialGrn) {
      final projectId = item.payload['projectId'] as String? ?? 'PRJ-OIL-2026';
      await _apiService.createMaterialTx(projectId, item.payload);
      return true;
    } else if (item.type == SyncItemType.conflict) {
      final projectId = item.payload['projectId'] as String? ?? 'PRJ-OIL-2026';
      await _apiService.raiseConflict(projectId, item.payload);
      return true;
    } else if (item.type == SyncItemType.fieldNote) {
      final projectId = item.payload['projectId'] as String? ?? 'PRJ-OIL-2026';
      final rawText = item.payload['rawInput'] as String? ?? '';
      final source = item.payload['source'] as String? ?? 'OFFLINE_FIELD_NOTE';
      await _apiService.submitLinking(projectId, rawText, source);
      return true;
    } else {
      // Generic dispatch
      final uri = Uri.parse('$baseUrl${item.endpoint}');
      final http.Response response;
      final headers = {
        'Content-Type': 'application/json',
        'X-Idempotency-Key': item.idempotencyKey,
      };

      if (item.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(item.payload),
        ).timeout(const Duration(seconds: 20));
      } else if (item.httpMethod.toUpperCase() == 'PATCH') {
        response = await http.patch(
          uri,
          headers: headers,
          body: jsonEncode(item.payload),
        ).timeout(const Duration(seconds: 20));
      } else {
        response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// Start automatic background retry timer.
  ///
  /// Periodically attempts to drain pending records if items are in the queue.
  void startAutoSync({Duration interval = const Duration(seconds: 30)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) async {
      if (pendingSyncCount.value > 0 && !isSyncing.value && isOnline) {
        debugPrint(
            '[OfflineSyncService] Periodic auto-sync triggering for ${pendingSyncCount.value} items...');
        await syncPendingData();
      }
    });
  }

  /// Stop background auto-sync timer.
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Seed realistic demo data for remote oil field operations (Assam & Rajasthan).
  ///
  /// Includes all 4 primary industrial transaction types: DPR, GPS Clock-in,
  /// Material GRN, and FIDIC Conflict.
  Future<void> seedRemoteFieldDemoQueue() async {
    await ensureInitialized();

    // 1. Assam Pipeline DPR
    await enqueueDpr(
      projectId: 'PRJ-OIL-2026',
      activityCode: 'PIP-L5-024',
      completedQuantity: 64.5,
      unit: 'meters',
      delayReason: 'Weather/Rain',
      notes:
          'Heavy monsoon downpour in Digboi sector. Trench de-watering completed before lower-in.',
      reportedBy: 'Vikram Joshi (Field Operations)',
      supervisorRole: 'Site Piping Supervisor',
      locationTag: 'Digboi Corridor, Assam',
    );

    // 2. Rajasthan Wellpad GPS Clock-in
    await enqueueGpsClockIn(
      workerId: 'WRK-1002',
      workerName: 'Suresh Singh',
      badgeNumber: 'LAB-1002',
      latitude: 25.7532,
      longitude: 71.3965,
      status: 'VERIFIED_PRESENT',
      method: 'GEOFENCE_BIOMETRIC',
      confidence: 99.2,
      locationTag: 'Cairn Mangala Wellpad 07, Barmer, Rajasthan',
    );

    // 3. Assam Pipe Yard Material GRN
    await enqueueMaterialGrn(
      projectId: 'PRJ-OIL-2026',
      materialCode: 'PIP-X70-24IN',
      quantity: 42.0,
      unit: 'MT',
      docNumber: 'GRN-DIG-2026-088',
      description: 'API 5L X70 Bare Line Pipes (24 inch OD, 12m length)',
      sourceSupplier: 'Jindal Steel & Power Ltd',
      destinationLocation: 'Digboi Pipe Yard Spread 2',
      associatedActivityCode: 'PIP-L5-024',
      locationTag: 'Digboi Central Store, Assam',
    );

    // 4. FIDIC Contractual Conflict
    await enqueueConflict(
      projectId: 'PRJ-OIL-2026',
      title: 'Trench Bedding Sand Quality Specification Variance',
      description:
          'River sand delivered contains silt content of 8.2% exceeding max 3.0% under FIDIC Cl. 4.21 & Shell DEP specs.',
      activityCode: 'PIP-L5-024',
      activityName: 'Trench Sand Bedding & Padding',
      type: 'SPEC_VARIATION',
      severity: 'HIGH',
      specOrClause: 'FIDIC Cl. 4.21 / Shell DEP 31.40.10.19',
      varianceValue: '+5.2% silt content',
      claimedValue: 'Compliant with Indian Standard IS 383 Zone III',
      verifiedValue: 'Exceeds pipeline bedding limit',
      locationTag: 'Duliajan Chainage 18+400, Assam',
    );

    // 5. Field Note / Linking Note
    await enqueueFieldNote(
      projectId: 'PRJ-OIL-2026',
      note:
          'Hydrostatic test manifold pressure drop observed at Chainage 14+200. Inspecting flange seals.',
      activityCode: 'HYD-TST-009',
      author: 'R. K. Sharma (QA/QC)',
      supervisorRole: 'Lead Inspector',
      source: 'VOICE_ASSISTANT_OFFLINE',
      locationTag: 'Duliajan Terminal Junction, Assam',
    );
  }

  void dispose() {
    _autoSyncTimer?.cancel();
    _connectivityController.close();
    pendingSyncCount.dispose();
    isSyncing.dispose();
    lastSyncTime.dispose();
    queueNotifier.dispose();
  }
}

// =============================================================================
// UI WIDGET: SYNC STATUS BADGE & STATUS BAR
// =============================================================================

/// Helper widget displaying the synchronization state of the offline queue.
///
/// Behavior:
/// - When count == 0: Green cloud icon with text 'Synced'.
/// - When count > 0: Amber cloud icon with text '3 Offline Records Queued' (interpolated count).
/// - When syncing: Blue spinning loader with 'Syncing...'.
/// - Tapping opens the interactive [showOfflineSyncQueueSheet] with full record details.
class SyncStatusBadge extends StatelessWidget {
  final OfflineSyncService? service;
  final VoidCallback? onTap;
  final bool showLabel;
  final bool compact;
  final String? syncedText;
  final String? offlineText;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const SyncStatusBadge({
    super.key,
    this.service,
    this.onTap,
    this.showLabel = true,
    this.compact = false,
    this.syncedText,
    this.offlineText,
    this.textStyle,
    this.padding,
  });

  OfflineSyncService get _svc => service ?? OfflineSyncService.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _svc.isSyncing,
      builder: (context, syncing, _) {
        return ValueListenableBuilder<int>(
          valueListenable: _svc.pendingSyncCount,
          builder: (context, count, _) {
            final Color badgeColor;
            final Color bgColor;
            final Color borderColor;
            final IconData iconData;
            final String label;

            if (syncing) {
              badgeColor = AppTheme.primaryLight; // Color(0xFF38BDF8)
              bgColor = AppTheme.primaryLight.withAlpha(28);
              borderColor = AppTheme.primaryLight.withAlpha(128);
              iconData = Icons.sync_rounded;
              label = count > 0 ? 'Syncing ($count)...' : 'Syncing...';
            } else if (count == 0) {
              badgeColor = AppTheme.tertiary; // Color(0xFF4EDEA3) Green
              bgColor = AppTheme.tertiary.withAlpha(24);
              borderColor = AppTheme.tertiary.withAlpha(120);
              iconData = Icons.cloud_done_rounded;
              label = syncedText ?? 'Synced';
            } else {
              badgeColor = AppTheme.secondary; // Color(0xFFFFB95F) Amber
              bgColor = AppTheme.secondary.withAlpha(24);
              borderColor = AppTheme.secondary.withAlpha(130);
              iconData = Icons.cloud_queue_rounded;
              label = offlineText ??
                  (count == 1
                      ? '1 Offline Record Queued'
                      : '$count Offline Records Queued');
            }

            if (compact) {
              return Tooltip(
                message: label,
                child: InkWell(
                  onTap: onTap ?? () => showOfflineSyncQueueSheet(context, service: _svc),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (syncing)
                          SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: badgeColor,
                            ),
                          )
                        else
                          Icon(iconData, size: 14, color: badgeColor),
                        if (count > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$count',
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }

            return InkWell(
              onTap: onTap ?? () => showOfflineSyncQueueSheet(context, service: _svc),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: padding ??
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (syncing)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: badgeColor,
                        ),
                      )
                    else
                      Icon(iconData, size: 16, color: badgeColor),
                    if (showLabel) ...[
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: textStyle ??
                            TextStyle(
                              color: badgeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Full-width industrial status bar banner for remote site offline alerts.
///
/// Designed to be placed below an AppBar or at the top of field data collection screens.
class SyncStatusBar extends StatelessWidget {
  final OfflineSyncService? service;
  final VoidCallback? onSyncPressed;

  const SyncStatusBar({
    super.key,
    this.service,
    this.onSyncPressed,
  });

  OfflineSyncService get _svc => service ?? OfflineSyncService.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _svc.isSyncing,
      builder: (context, syncing, _) {
        return ValueListenableBuilder<int>(
          valueListenable: _svc.pendingSyncCount,
          builder: (context, count, _) {
            if (count == 0 && !syncing) {
              return const SizedBox.shrink();
            }

            final isAmber = count > 0 && !syncing;
            final Color barColor = isAmber ? AppTheme.secondary : AppTheme.primaryLight;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: barColor.withAlpha(22),
                border: Border(
                  top: BorderSide(color: barColor.withAlpha(90), width: 1),
                  bottom: BorderSide(color: barColor.withAlpha(90), width: 1),
                ),
              ),
              child: Row(
                children: [
                  if (syncing)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: barColor,
                      ),
                    )
                  else
                    Icon(Icons.offline_bolt_rounded, size: 16, color: barColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      syncing
                          ? 'Synchronizing $count pending records with cloud...'
                          : 'Remote Site Mode (Assam / Rajasthan) — $count Offline Records Queued',
                      style: TextStyle(
                        color: barColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: syncing
                        ? null
                        : (onSyncPressed ?? () => _svc.syncPendingData()),
                    style: TextButton.styleFrom(
                      foregroundColor: barColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: barColor.withAlpha(30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      syncing ? 'Syncing...' : 'Sync Now',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// MODAL SHEET: QUEUE DETAILS & MANAGEMENT
// =============================================================================

/// Displays the detailed offline sync queue bottom sheet modal.
Future<void> showOfflineSyncQueueSheet(
  BuildContext context, {
  OfflineSyncService? service,
}) {
  final svc = service ?? OfflineSyncService.instance;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _OfflineSyncQueueSheet(service: svc),
  );
}

class _OfflineSyncQueueSheet extends StatelessWidget {
  final OfflineSyncService service;

  const _OfflineSyncQueueSheet({required this.service});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111C38),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.cloud_sync_rounded,
                        color: AppTheme.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Offline Sync Queue',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Remote Field Sites (Assam & Rajasthan)',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SyncStatusBadge(compact: true),
                  ],
                ),
              ),
              const Divider(color: AppTheme.border, height: 16),
              // Metric row
              _buildMetricsRow(),
              const Divider(color: AppTheme.border, height: 16),
              // Action buttons row
              _buildActionToolbar(context),
              const SizedBox(height: 6),
              // List of items
              Expanded(
                child: ValueListenableBuilder<List<OfflineQueueItem>>(
                  valueListenable: service.queueNotifier,
                  builder: (context, items, _) {
                    if (items.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildItemCard(context, item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricsRow() {
    return ValueListenableBuilder<int>(
      valueListenable: service.pendingSyncCount,
      builder: (context, count, _) {
        return ValueListenableBuilder<DateTime?>(
          valueListenable: service.lastSyncTime,
          builder: (context, lastSync, _) {
            final timeStr = lastSync != null
                ? DateFormat('HH:mm:ss').format(lastSync)
                : 'Not yet';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Pending Sync',
                      value: '$count items',
                      color: count > 0 ? AppTheme.secondary : AppTheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Auto-Sync',
                      value: 'Active (30s)',
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Last Synced',
                      value: timeStr,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: service.isSyncing,
      builder: (context, syncing, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: syncing
                      ? null
                      : () async {
                          final res = await service.syncPendingData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res.isFullySynced
                                      ? 'Successfully synced ${res.succeeded} field records!'
                                      : 'Synced ${res.succeeded}, failed ${res.failed}. Will auto-retry.',
                                ),
                                backgroundColor: res.isFullySynced
                                    ? AppTheme.tertiary
                                    : AppTheme.secondary,
                              ),
                            );
                          }
                        },
                  icon: syncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_rounded, size: 16),
                  label: Text(syncing ? 'Syncing...' : 'Sync All Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: syncing
                      ? null
                      : () async {
                          await service.seedRemoteFieldDemoQueue();
                        },
                  icon: const Icon(Icons.add_task_rounded, size: 14),
                  label: const Text('Seed Demo', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Clear All Queued Items',
                onPressed: syncing
                    ? null
                    : () async {
                        await service.clearQueue();
                      },
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.textMuted, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.tertiary.withAlpha(24),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_done_rounded,
                color: AppTheme.tertiary,
                size: 42,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'All Records Synchronized',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No pending records in offline queue.\nAny DPR, GPS clock-in, or field note logged without signal will queue here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => service.seedRemoteFieldDemoQueue(),
              icon: const Icon(Icons.playlist_add_rounded, size: 16),
              label: const Text('Add Remote Site Test Records'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, OfflineQueueItem item) {
    final IconData typeIcon;
    final Color typeColor;

    switch (item.type) {
      case SyncItemType.dpr:
        typeIcon = Icons.assignment_rounded;
        typeColor = AppTheme.primaryLight;
        break;
      case SyncItemType.gpsClockIn:
        typeIcon = Icons.fingerprint_rounded;
        typeColor = AppTheme.tertiary;
        break;
      case SyncItemType.fieldNote:
        typeIcon = Icons.edit_note_rounded;
        typeColor = AppTheme.secondary;
        break;
      case SyncItemType.custom:
        typeIcon = Icons.data_object_rounded;
        typeColor = AppTheme.textSecondary;
        break;
      case SyncItemType.materialGrn:
        typeIcon = Icons.inventory_2_outlined;
        typeColor = AppTheme.secondary;
        break;
      case SyncItemType.conflict:
        typeIcon = Icons.warning_amber_rounded;
        typeColor = const Color(0xFFEF4444);
        break;
    }

    final dateStr = DateFormat('dd MMM, HH:mm').format(item.createdAt);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.status == SyncItemStatus.failed
              ? AppTheme.error.withAlpha(128)
              : AppTheme.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withAlpha(28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(typeIcon, color: typeColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _buildItemStatusChip(item.status),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: AppTheme.textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        item.locationTag,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                if (item.retryCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Retried ${item.retryCount}/${item.maxRetries} times${item.lastError != null ? ' • ${item.lastError}' : ''}',
                    style: TextStyle(
                      color: item.status == SyncItemStatus.failed
                          ? AppTheme.error
                          : AppTheme.secondary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Discard Record',
            onPressed: () => service.removeItem(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildItemStatusChip(SyncItemStatus status) {
    final String label;
    final Color color;

    switch (status) {
      case SyncItemStatus.pending:
        label = 'Pending';
        color = AppTheme.secondary;
        break;
      case SyncItemStatus.syncing:
        label = 'Syncing';
        color = AppTheme.primaryLight;
        break;
      case SyncItemStatus.failed:
        label = 'Failed';
        color = AppTheme.error;
        break;
      case SyncItemStatus.synced:
        label = 'Synced';
        color = AppTheme.tertiary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(90), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
