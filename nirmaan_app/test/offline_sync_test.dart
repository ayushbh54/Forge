import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nirmaan_app/services/offline_sync_service.dart';
import 'package:nirmaan_app/services/api_service.dart';

// Mock ApiService for testing offline sync drainage and retry logic
class MockApiService extends ApiService {
  bool shouldFail = false;
  bool isNetworkDown = false;
  final List<Map<String, dynamic>> submittedDprs = [];
  final List<Map<String, dynamic>> clockedInWorkers = [];

  @override
  Future<dynamic> submitDpr(String projectId, Map<String, dynamic> data) async {
    if (isNetworkDown) {
      throw Exception('SocketException: Failed host lookup localhost');
    }
    if (shouldFail) {
      throw Exception('HTTP 500: Internal Server Error');
    }
    submittedDprs.add({'projectId': projectId, ...data});
    return {'status': 'success', 'dprId': 'DPR-TEST-123'};
  }

  @override
  Future<dynamic> clockIn(
    String workerId,
    double lat,
    double lng, {
    String status = 'VERIFIED_PRESENT',
    String method = 'GEOFENCE_BIOMETRIC',
    double confidence = 98.5,
  }) async {
    if (isNetworkDown) {
      throw Exception('ClientException: network is unreachable');
    }
    if (shouldFail) {
      throw Exception('HTTP 502: Bad Gateway');
    }
    clockedInWorkers.add({
      'workerId': workerId,
      'lat': lat,
      'lng': lng,
      'status': status,
      'method': method,
      'confidence': confidence,
    });
    return {'status': 'success', 'timestamp': DateTime.now().toIso8601String()};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiService mockApi;
  late OfflineSyncService syncService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockApi = MockApiService();
    syncService = OfflineSyncService(apiService: mockApi);
    await syncService.ensureInitialized();
    await syncService.clearQueue();
  });

  tearDown(() async {
    syncService.stopAutoSync();
    await syncService.clearQueue();
  });

  group('OfflineSyncService - Core Enqueue & UUID Audit', () {
    test('Verify offline queueing for DPR submissions with UUID v4', () async {
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      final item = await syncService.enqueueDpr(
        projectId: 'PRJ-OIL-ASSAM',
        activityCode: 'PIP-L5-024',
        completedQuantity: 85.5,
        unit: 'meters',
        delayReason: 'Monsoon Heavy Downpour',
        notes: 'Duliajan sector spread trenching progress logged offline',
        reportedBy: 'Field Engineer Baruah',
        supervisorRole: 'Piping In-Charge',
        locationTag: 'Assam Crude Pipeline Spread 2',
      );

      // Verify UUID v4 format
      expect(item.id, isNotEmpty);
      expect(uuidRegex.hasMatch(item.id), isTrue,
          reason: 'Item ID should be a valid RFC 4122 UUID v4: ${item.id}');

      // Verify payload and properties
      expect(item.type, SyncItemType.dpr);
      expect(item.endpoint, '/api/dpr');
      expect(item.httpMethod, 'POST');
      expect(item.status, SyncItemStatus.pending);
      expect(item.retryCount, 0);
      expect(item.maxRetries, 5);
      expect(item.payload['projectId'], 'PRJ-OIL-ASSAM');
      expect(item.payload['activityCode'], 'PIP-L5-024');
      expect(item.payload['completedQuantity'], 85.5);
      expect(item.payload['delayReason'], 'Monsoon Heavy Downpour');
      expect(item.locationTag, 'Assam Crude Pipeline Spread 2');

      // Verify pending count and queue length
      expect(syncService.pendingSyncCount.value, 1);
      expect(syncService.getAllItems().length, 1);
    });

    test('Verify offline queueing for GPS Clock-ins with UUID v4', () async {
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      final item = await syncService.enqueueGpsClockIn(
        workerId: 'WRK-BARMER-1002',
        workerName: 'Suresh Singh',
        badgeNumber: 'LAB-1002',
        latitude: 25.7532,
        longitude: 71.3965,
        status: 'VERIFIED_PRESENT',
        method: 'GEOFENCE_BIOMETRIC',
        confidence: 99.4,
        locationTag: 'Barmer Thar Desert Wellpad 04, Rajasthan',
      );

      // Verify UUID v4
      expect(item.id, isNotEmpty);
      expect(uuidRegex.hasMatch(item.id), isTrue,
          reason: 'Clock-in ID should be a valid RFC 4122 UUID v4: ${item.id}');

      // Verify payload and properties
      expect(item.type, SyncItemType.gpsClockIn);
      expect(item.endpoint, '/api/workforce');
      expect(item.httpMethod, 'PATCH');
      expect(item.status, SyncItemStatus.pending);
      expect(item.payload['workerId'], 'WRK-BARMER-1002');
      expect(item.payload['workerName'], 'Suresh Singh');
      expect(item.payload['latitude'], 25.7532);
      expect(item.payload['longitude'], 71.3965);
      expect(item.payload['confidence'], 99.4);
      expect(item.locationTag, 'Barmer Thar Desert Wellpad 04, Rajasthan');

      // Verify count
      expect(syncService.pendingSyncCount.value, 1);
    });

    test('Verify unique UUIDs generated across successive enqueues', () async {
      final item1 = await syncService.enqueueDpr(
        projectId: 'PRJ-1',
        activityCode: 'ACT-1',
        completedQuantity: 10.0,
      );
      final item2 = await syncService.enqueueDpr(
        projectId: 'PRJ-1',
        activityCode: 'ACT-2',
        completedQuantity: 20.0,
      );
      final item3 = await syncService.enqueueGpsClockIn(
        workerId: 'WRK-1',
        latitude: 27.48,
        longitude: 95.32,
      );

      expect(item1.id, isNot(equals(item2.id)));
      expect(item2.id, isNot(equals(item3.id)));
      expect(item1.id, isNot(equals(item3.id)));
      expect(syncService.pendingSyncCount.value, 3);
    });
  });

  group('OfflineSyncService - SharedPreferences Persistence Audit', () {
    test('Verify items are persisted to SharedPreferences key and survive re-init', () async {
      const storageKey = 'nirmaan_offline_sync_queue_v1';

      await syncService.enqueueDpr(
        projectId: 'PRJ-OIL-PERSIST',
        activityCode: 'WLD-001',
        completedQuantity: 42.0,
        unit: 'joints',
        delayReason: 'No Delay',
      );

      await syncService.enqueueGpsClockIn(
        workerId: 'WRK-999',
        latitude: 27.5000,
        longitude: 95.3500,
        workerName: 'Arun Das',
      );

      // Verify SharedPreferences contains raw JSON data
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(storageKey);
      expect(rawJson, isNotNull);
      expect(rawJson, isNotEmpty);

      final decoded = jsonDecode(rawJson!) as List;
      expect(decoded.length, 2);
      expect(decoded[0]['type'], 'dpr');
      expect(decoded[0]['payload']['activityCode'], 'WLD-001');
      expect(decoded[1]['type'], 'gpsClockIn');
      expect(decoded[1]['payload']['workerId'], 'WRK-999');

      // Verify item removal updates persistence
      final firstItemId = decoded[0]['id'] as String;
      final removed = await syncService.removeItem(firstItemId);
      expect(removed, isTrue);

      final updatedRaw = prefs.getString(storageKey);
      final updatedList = jsonDecode(updatedRaw!) as List;
      expect(updatedList.length, 1);
      expect(updatedList[0]['payload']['workerId'], 'WRK-999');
    });
  });

  group('OfflineSyncService - Retry Logic & Network Dispatch Audit', () {
    test('Verify successful sync drains items and updates lastSyncTime', () async {
      await syncService.enqueueDpr(
        projectId: 'PRJ-100',
        activityCode: 'ACT-SYNC-1',
        completedQuantity: 50.0,
      );

      expect(syncService.pendingSyncCount.value, 1);

      final result = await syncService.syncPendingData();

      expect(result.totalProcessed, 1);
      expect(result.succeeded, 1);
      expect(result.failed, 0);
      expect(result.isFullySynced, isTrue);
      expect(syncService.pendingSyncCount.value, 0);
      expect(syncService.lastSyncTime.value, isNotNull);
      expect(mockApi.submittedDprs.length, 1);
      expect(mockApi.submittedDprs.first['activityCode'], 'ACT-SYNC-1');
    });

    test('Verify retry logic increments retryCount on failure and caps at maxRetries', () async {
      mockApi.shouldFail = true;

      await syncService.enqueueDpr(
        projectId: 'PRJ-FAIL',
        activityCode: 'ACT-FAIL-1',
        completedQuantity: 15.0,
      );

      // Attempt 1
      var result = await syncService.syncPendingData();
      expect(result.failed, 1);
      expect(syncService.getAllItems().first.retryCount, 1);
      expect(syncService.getAllItems().first.status, SyncItemStatus.pending);

      // Attempt 2
      result = await syncService.syncPendingData(forceAll: true);
      expect(syncService.getAllItems().first.retryCount, 2);

      // Exhaust up to maxRetries (5)
      await syncService.syncPendingData(forceAll: true); // 3
      await syncService.syncPendingData(forceAll: true); // 4
      await syncService.syncPendingData(forceAll: true); // 5

      final currentItem = syncService.getAllItems().first;
      expect(currentItem.retryCount, 5);
      expect(currentItem.status, SyncItemStatus.failed);
      expect(currentItem.lastError, contains('Internal Server Error'));
    });

    test('Verify batch sync pauses gracefully on complete network disconnect', () async {
      mockApi.isNetworkDown = true;

      await syncService.enqueueDpr(
        projectId: 'PRJ-1',
        activityCode: 'ACT-1',
        completedQuantity: 10.0,
      );
      await syncService.enqueueDpr(
        projectId: 'PRJ-2',
        activityCode: 'ACT-2',
        completedQuantity: 20.0,
      );

      // When network is completely down (SocketException), the batch should pause early
      final result = await syncService.syncPendingData();
      expect(result.failed, 1, reason: 'Should halt batch loop after first network failure');
      expect(result.totalProcessed, 2);
    });
  });

  group('OfflineSyncService - SyncStatusBadge Reactivity Audit', () {
    testWidgets('Verify SyncStatusBadge reactivity: synced, pending count, and syncing states', (tester) async {
      // 1. Initial State: Synced (0 pending)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusBadge(service: syncService),
          ),
        ),
      );

      expect(find.text('Synced'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);

      // 2. Enqueue item -> State changes reactively to '1 Offline Record Queued'
      await syncService.enqueueDpr(
        projectId: 'PRJ-TEST',
        activityCode: 'ACT-01',
        completedQuantity: 10.0,
      );
      await tester.pump();

      expect(find.text('1 Offline Record Queued'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_queue_rounded), findsOneWidget);

      // 3. Enqueue second item -> Updates to '2 Offline Records Queued'
      await syncService.enqueueGpsClockIn(
        workerId: 'WRK-2',
        latitude: 25.0,
        longitude: 71.0,
      );
      await tester.pump();

      expect(find.text('2 Offline Records Queued'), findsOneWidget);

      // 4. Set isSyncing to true -> shows CircularProgressIndicator and 'Syncing (2)...'
      syncService.isSyncing.value = true;
      await tester.pump();

      expect(find.text('Syncing (2)...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 5. Reset syncing and clear queue -> returns to 'Synced'
      syncService.isSyncing.value = false;
      await syncService.clearQueue();
      await tester.pump();

      expect(find.text('Synced'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    });

    testWidgets('Verify compact SyncStatusBadge rendering', (tester) async {
      await syncService.enqueueDpr(
        projectId: 'PRJ-COMPACT',
        activityCode: 'ACT-C1',
        completedQuantity: 5.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                SyncStatusBadge(service: syncService, compact: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_queue_rounded), findsOneWidget);
    });
  });
}
