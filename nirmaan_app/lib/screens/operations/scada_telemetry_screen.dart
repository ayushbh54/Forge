import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS
// ============================================================================

enum ValvePositionState {
  fullyOpen,
  fullyClosed,
  traveling,
  partiallyOpen,
  faultTripped,
}

enum EsdvSafetyState {
  armedOpen,
  trippedClosed,
  partialStrokeTesting,
  interlockBlocked,
}

enum LdsAlarmSeverity {
  critical,
  high,
  warning,
  info,
}

enum LdsDetectionMethod {
  computationalMassBalance,
  acousticNegativePressureWave,
  pressureGradientRoPD,
  statisticalVolumeBalance,
}

/// Model representing a Sectionalizing Valve Station (VS-01 to VS-08)
class ValveStationTelemetry {
  final String id; // e.g. VS-01
  final String name; // e.g. Duliajan Dispatch Terminal
  final String chainage; // e.g. KP 0+000
  final double chainageKm; // 0.0
  final double elevationM; // 116.0
  final String rtuModel; // Moxa ioPAC 8600 / ScadaPack 357E
  final String commProtocol; // IEC 60870-5-104

  // Live dynamic telemetry
  double upstreamPressureBar;
  double downstreamPressureBar;
  double flowRateMmscmd;
  double gasTemperatureC;
  double actuatorHydraulicPressureBar;
  double nitrogenPressureBar;
  int rtuLatencyMs;
  double rtuBatteryVolt;
  bool commLinkOnline;

  // Valve physical states
  ValvePositionState mainlineValveState;
  double mainlinePositionPct; // 0.0 to 100.0%
  bool bypassValveOpen;

  // ESDV safety and PST state
  EsdvSafetyState esdvState;
  double esdvPositionPct;
  DateTime lastPstDate;
  DateTime nextPstDueDate;
  String pstResult; // 'PASSED', 'DUE', 'WARNING'
  double pstTravelTimeSec;
  double pstBreakawayTorqueNm;

  // Trend historical points (last 12 points for upstream & downstream)
  List<FlSpot> upstreamHistory;
  List<FlSpot> downstreamHistory;

  ValveStationTelemetry({
    required this.id,
    required this.name,
    required this.chainage,
    required this.chainageKm,
    required this.elevationM,
    required this.rtuModel,
    required this.commProtocol,
    required this.upstreamPressureBar,
    required this.downstreamPressureBar,
    required this.flowRateMmscmd,
    required this.gasTemperatureC,
    required this.actuatorHydraulicPressureBar,
    required this.nitrogenPressureBar,
    required this.rtuLatencyMs,
    required this.rtuBatteryVolt,
    this.commLinkOnline = true,
    this.mainlineValveState = ValvePositionState.fullyOpen,
    this.mainlinePositionPct = 100.0,
    this.bypassValveOpen = false,
    this.esdvState = EsdvSafetyState.armedOpen,
    this.esdvPositionPct = 100.0,
    required this.lastPstDate,
    required this.nextPstDueDate,
    this.pstResult = 'PASSED',
    this.pstTravelTimeSec = 2.4,
    this.pstBreakawayTorqueNm = 4250.0,
    required this.upstreamHistory,
    required this.downstreamHistory,
  });

  double get differentialPressureBar =>
      (upstreamPressureBar - downstreamPressureBar).abs();

  bool get isDifferentialPressureSafe => differentialPressureBar <= 3.0;

  bool get isEsdvHealthy =>
      esdvState == EsdvSafetyState.armedOpen &&
      actuatorHydraulicPressureBar >= 160.0;
}

/// Model for Gas Leak Detection System (LDS) alarms
class LdsAlarmEvent {
  final String id;
  final DateTime timestamp;
  final String section;
  final double chainageKm;
  final String chainageText;
  final LdsDetectionMethod method;
  final LdsAlarmSeverity severity;
  final double estimatedLeakRateMms;
  final double estimatedMassLossKgHr;
  final double confidenceScorePct;
  final double timeOfFlightDeltaMs;
  final String description;
  final String recommendedAction;
  bool isAcknowledged;
  bool isHornSilenced;

  LdsAlarmEvent({
    required this.id,
    required this.timestamp,
    required this.section,
    required this.chainageKm,
    required this.chainageText,
    required this.method,
    required this.severity,
    required this.estimatedLeakRateMms,
    required this.estimatedMassLossKgHr,
    required this.confidenceScorePct,
    required this.timeOfFlightDeltaMs,
    required this.description,
    required this.recommendedAction,
    this.isAcknowledged = false,
    this.isHornSilenced = false,
  });
}

/// Model for audit logs of remote valve overrides
class ValveOverrideAuditRecord {
  final String id;
  final DateTime timestamp;
  final String stationId;
  final String valveTarget;
  final String command;
  final String operatorName;
  final String authorizationRole;
  final double preDiffPressureBar;
  final bool bypassUsed;
  final String outcomeStatus;
  final String verificationHash;

  const ValveOverrideAuditRecord({
    required this.id,
    required this.timestamp,
    required this.stationId,
    required this.valveTarget,
    required this.command,
    required this.operatorName,
    required this.authorizationRole,
    required this.preDiffPressureBar,
    required this.bypassUsed,
    required this.outcomeStatus,
    required this.verificationHash,
  });
}

// ============================================================================
// MAIN SCADA TELEMETRY SCREEN
// ============================================================================

class ScadaTelemetryScreen extends StatefulWidget {
  const ScadaTelemetryScreen({super.key});

  @override
  State<ScadaTelemetryScreen> createState() => _ScadaTelemetryScreenState();
}

class _ScadaTelemetryScreenState extends State<ScadaTelemetryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _liveTelemetryTimer;
  bool _isLiveStreaming = true;
  int _selectedStationIndex = 0;
  final math.Random _random = math.Random(42);

  // Safety Authorization PIN for override simulation
  static const String _masterSafetyPin = '7492';

  // Overall pipeline metrics
  double _linePackMassTons = 2418.6;
  double _inletMassFlowTonsHr = 184.25;
  double _outletMassFlowTonsHr = 183.90;
  double _unaccountedMassTonsHr = 0.35; // within acceptable 0.5% boundary

  // Stations List (VS-01 to VS-08)
  late List<ValveStationTelemetry> _stations;

  // Active LDS Leak Alarms
  late List<LdsAlarmEvent> _activeLdsAlarms;

  // Audit Log Records
  late List<ValveOverrideAuditRecord> _auditLogs;

  // Interlock Trip Simulation States for ESDV testing
  bool _tripPshhSimulated = false; // Pressure Switch High-High (>90 Bar)
  bool _tripPsllSimulated = false; // Pressure Switch Low-Low (<45 Bar)
  bool _tripRopdSimulated = false; // Rate of Pressure Drop (>2.5 Bar/min)
  bool _tripManualEsdSimulated = false; // Field Push-Button Station

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeScadaData();
    _startLiveTelemetryTimer();
  }

  @override
  void dispose() {
    _liveTelemetryTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeScadaData() {
    final now = DateTime.now();

    _stations = [
      ValveStationTelemetry(
        id: 'VS-01',
        name: 'Duliajan Dispatch Terminal',
        chainage: 'KP 0+000',
        chainageKm: 0.0,
        elevationM: 116.0,
        rtuModel: 'Moxa ioPAC 8600 Dual-LAN',
        commProtocol: 'IEC 60870-5-104',
        upstreamPressureBar: 76.85,
        downstreamPressureBar: 76.45,
        flowRateMmscmd: 5.12,
        gasTemperatureC: 26.4,
        actuatorHydraulicPressureBar: 198.5,
        nitrogenPressureBar: 220.0,
        rtuLatencyMs: 22,
        rtuBatteryVolt: 24.6,
        lastPstDate: now.subtract(const Duration(days: 2)),
        nextPstDueDate: now.add(const Duration(days: 28)),
        pstResult: 'PASSED',
        pstTravelTimeSec: 2.35,
        pstBreakawayTorqueNm: 4180.0,
        upstreamHistory: _generateInitialTrend(76.85, 0.4),
        downstreamHistory: _generateInitialTrend(76.45, 0.4),
      ),
      ValveStationTelemetry(
        id: 'VS-02',
        name: 'Moran Junction SV',
        chainage: 'KP 28+400',
        chainageKm: 28.4,
        elevationM: 104.0,
        rtuModel: 'Schneider ScadaPack 357E',
        commProtocol: 'IEC 60870-5-104',
        upstreamPressureBar: 75.60,
        downstreamPressureBar: 75.20,
        flowRateMmscmd: 5.09,
        gasTemperatureC: 25.8,
        actuatorHydraulicPressureBar: 192.0,
        nitrogenPressureBar: 218.0,
        rtuLatencyMs: 27,
        rtuBatteryVolt: 24.2,
        lastPstDate: now.subtract(const Duration(days: 6)),
        nextPstDueDate: now.add(const Duration(days: 24)),
        pstResult: 'PASSED',
        pstTravelTimeSec: 2.42,
        pstBreakawayTorqueNm: 4210.0,
        upstreamHistory: _generateInitialTrend(75.60, 0.35),
        downstreamHistory: _generateInitialTrend(75.20, 0.35),
      ),
      ValveStationTelemetry(
        id: 'VS-03',
        name: 'Sibsagar Desang River SV',
        chainage: 'KP 54+100',
        chainageKm: 54.1,
        elevationM: 98.0,
        rtuModel: 'Schneider ScadaPack 357E',
        commProtocol: 'Modbus TCP / DNP3',
        upstreamPressureBar: 74.35,
        downstreamPressureBar: 73.95,
        flowRateMmscmd: 5.05,
        gasTemperatureC: 25.1,
        actuatorHydraulicPressureBar: 188.0,
        nitrogenPressureBar: 215.0,
        rtuLatencyMs: 31,
        rtuBatteryVolt: 24.1,
        lastPstDate: now.subtract(const Duration(days: 29)),
        nextPstDueDate: now.add(const Duration(days: 1)),
        pstResult: 'DUE',
        pstTravelTimeSec: 2.65,
        pstBreakawayTorqueNm: 4320.0,
        upstreamHistory: _generateInitialTrend(74.35, 0.38),
        downstreamHistory: _generateInitialTrend(73.95, 0.38),
      ),
      ValveStationTelemetry(
        id: 'VS-04',
        name: 'Jorhat North Section SV',
        chainage: 'KP 81+200',
        chainageKm: 81.2,
        elevationM: 92.0,
        rtuModel: 'Emerson ROC809 Remote RTU',
        commProtocol: 'IEC 60870-5-104',
        upstreamPressureBar: 73.10,
        downstreamPressureBar: 72.72,
        flowRateMmscmd: 4.98,
        gasTemperatureC: 24.7,
        actuatorHydraulicPressureBar: 185.5,
        nitrogenPressureBar: 214.0,
        rtuLatencyMs: 29,
        rtuBatteryVolt: 24.4,
        lastPstDate: now.subtract(const Duration(days: 11)),
        nextPstDueDate: now.add(const Duration(days: 19)),
        pstResult: 'PASSED',
        pstTravelTimeSec: 2.38,
        pstBreakawayTorqueNm: 4150.0,
        upstreamHistory: _generateInitialTrend(73.10, 0.32),
        downstreamHistory: _generateInitialTrend(72.72, 0.32),
      ),
      ValveStationTelemetry(
        id: 'VS-05',
        name: 'Golaghat Central Tap SV',
        chainage: 'KP 109+600',
        chainageKm: 109.6,
        elevationM: 88.0,
        rtuModel: 'Emerson ROC809 Remote RTU',
        commProtocol: 'IEC 60870-5-104',
        upstreamPressureBar: 71.80,
        downstreamPressureBar: 71.40,
        flowRateMmscmd: 4.88,
        gasTemperatureC: 24.3,
        actuatorHydraulicPressureBar: 181.0,
        nitrogenPressureBar: 212.0,
        rtuLatencyMs: 34,
        rtuBatteryVolt: 23.9,
        lastPstDate: now.subtract(const Duration(days: 18)),
        nextPstDueDate: now.add(const Duration(days: 12)),
        pstResult: 'PASSED',
        pstTravelTimeSec: 2.45,
        pstBreakawayTorqueNm: 4260.0,
        upstreamHistory: _generateInitialTrend(71.80, 0.34),
        downstreamHistory: _generateInitialTrend(71.40, 0.34),
      ),
      ValveStationTelemetry(
        id: 'VS-06',
        name: 'Bokakhat Kaziranga Border SV',
        chainage: 'KP 138+900',
        chainageKm: 138.9,
        elevationM: 79.0,
        rtuModel: 'Moxa ioPAC 8600 Solar Node',
        commProtocol: 'DNP3 Secure Over IP',
        upstreamPressureBar: 70.45,
        downstreamPressureBar: 70.05,
        flowRateMmscmd: 4.83,
        gasTemperatureC: 23.9,
        actuatorHydraulicPressureBar: 190.0,
        nitrogenPressureBar: 219.0,
        rtuLatencyMs: 38,
        rtuBatteryVolt: 24.5,
        lastPstDate: now.subtract(const Duration(days: 22)),
        nextPstDueDate: now.add(const Duration(days: 8)),
        pstResult: 'PASSED',
        pstTravelTimeSec: 2.40,
        pstBreakawayTorqueNm: 4190.0,
        upstreamHistory: _generateInitialTrend(70.45, 0.36),
        downstreamHistory: _generateInitialTrend(70.05, 0.36),
      ),
      ValveStationTelemetry(
        id: 'VS-07',
        name: 'Jakhalabandha Mountain Pass SV',
        chainage: 'KP 167+300',
        chainageKm: 167.3,
        elevationM: 72.0,
        rtuModel: 'Schneider ScadaPack 357E',
        commProtocol: 'IEC 60870-5-104',
        upstreamPressureBar: 69.15,
        downstreamPressureBar: 68.75,
        flowRateMmscmd: 4.79,
        gasTemperatureC: 23.5,
        actuatorHydraulicPressureBar: 186.2,
        nitrogenPressureBar: 216.0,
        rtuLatencyMs: 33,
        rtuBatteryVolt: 24.0,
        lastPstDate: now.subtract(const Duration(days: 30)),
        nextPstDueDate: now,
        pstResult: 'DUE',
        pstTravelTimeSec: 2.58,
        pstBreakawayTorqueNm: 4310.0,
        upstreamHistory: _generateInitialTrend(69.15, 0.31),
        downstreamHistory: _generateInitialTrend(68.75, 0.31),
      ),
      ValveStationTelemetry(
        id: 'VS-08',
        name: 'Nagaon City Gate Terminal SV',
        chainage: 'KP 194+500',
        chainageKm: 194.5,
        elevationM: 68.0,
        rtuModel: 'Moxa ioPAC 8600 Dual-LAN',
        commProtocol: 'IEC 60870-5-104',
        upstreamPressureBar: 67.85,
        downstreamPressureBar: 67.42,
        flowRateMmscmd: 4.75,
        gasTemperatureC: 23.1,
        actuatorHydraulicPressureBar: 194.0,
        nitrogenPressureBar: 220.0,
        rtuLatencyMs: 25,
        rtuBatteryVolt: 24.8,
        lastPstDate: now.subtract(const Duration(days: 4)),
        nextPstDueDate: now.add(const Duration(days: 26)),
        pstResult: 'PASSED',
        pstTravelTimeSec: 2.30,
        pstBreakawayTorqueNm: 4120.0,
        upstreamHistory: _generateInitialTrend(67.85, 0.33),
        downstreamHistory: _generateInitialTrend(67.42, 0.33),
      ),
    ];

    // Initial LDS leak alarm
    _activeLdsAlarms = [
      LdsAlarmEvent(
        id: 'LDS-2026-092',
        timestamp: now.subtract(const Duration(minutes: 14)),
        section: 'VS-02 (Moran) to VS-03 (Sibsagar)',
        chainageKm: 43.2,
        chainageText: 'KP 43+200 (Moran-Sibsagar Inter-station)',
        method: LdsDetectionMethod.acousticNegativePressureWave,
        severity: LdsAlarmSeverity.high,
        estimatedLeakRateMms: 0.18,
        estimatedMassLossKgHr: 1420.0,
        confidenceScorePct: 96.8,
        timeOfFlightDeltaMs: 142.0,
        description:
            'Acoustic wavefront detected with rarefaction pulse at 385 m/s. Computational mass balance confirms slight rate dip.',
        recommendedAction:
            'Dispatch UAV surveillance & alert Sectionalizing Valves VS-02 and VS-03 for isolation preparation.',
        isAcknowledged: false,
        isHornSilenced: false,
      ),
    ];

    // Initial audit logs
    _auditLogs = [
      ValveOverrideAuditRecord(
        id: 'AUD-8821',
        timestamp: now.subtract(const Duration(hours: 3)),
        stationId: 'VS-01',
        valveTarget: '18" Mainline Ball Valve MOV-01',
        command: 'VERIFY_SEAT_LEAKAGE',
        operatorName: 'Chief Controller A. Saikia',
        authorizationRole: 'Safety Engineer Level-4',
        preDiffPressureBar: 0.40,
        bypassUsed: true,
        outcomeStatus: 'EXECUTED_SUCCESS',
        verificationHash: 'SHA256:7e9a8f...31c4',
      ),
      ValveOverrideAuditRecord(
        id: 'AUD-8820',
        timestamp: now.subtract(const Duration(hours: 14)),
        stationId: 'VS-04',
        valveTarget: 'ESDV-04 Scotch-Yoke Actuator',
        command: 'PST_PARTIAL_STROKE_15%',
        operatorName: 'Field Eng. B. Gogoi',
        authorizationRole: 'Field SCADA Specialist',
        preDiffPressureBar: 0.38,
        bypassUsed: false,
        outcomeStatus: 'PASSED (2.38s)',
        verificationHash: 'SHA256:3a1b4c...98ef',
      ),
      ValveOverrideAuditRecord(
        id: 'AUD-8819',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        stationId: 'VS-08',
        valveTarget: '2" Equalizing Bypass Valve BV-08',
        command: 'EQUALIZATION_CYCLE',
        operatorName: 'Dispatch Eng. T. Borah',
        authorizationRole: 'Terminal Lead Controller',
        preDiffPressureBar: 0.43,
        bypassUsed: true,
        outcomeStatus: 'PRESSURE_BALANCED',
        verificationHash: 'SHA256:9f2c8d...041a',
      ),
    ];
  }

  List<FlSpot> _generateInitialTrend(double baseline, double variance) {
    final list = <FlSpot>[];
    for (int i = 0; i < 12; i++) {
      final jitter = (math.sin(i * 0.8) * variance * 0.5) +
          ((_random.nextDouble() - 0.5) * variance);
      list.add(
          FlSpot(i.toDouble(), double.parse((baseline + jitter).toStringAsFixed(2))));
    }
    return list;
  }

  void _startLiveTelemetryTimer() {
    _liveTelemetryTimer?.cancel();
    _liveTelemetryTimer =
        Timer.periodic(const Duration(milliseconds: 3200), (timer) {
      if (!_isLiveStreaming || !mounted) return;

      setState(() {
        // Jitter overall line pack
        _linePackMassTons += (_random.nextDouble() - 0.49) * 0.15;
        _linePackMassTons =
            double.parse(_linePackMassTons.toStringAsFixed(2));

        // Jitter each station's live readings
        for (var s in _stations) {
          final pDelta = (_random.nextDouble() - 0.5) * 0.08;
          s.upstreamPressureBar = double.parse(
              (s.upstreamPressureBar + pDelta).clamp(40.0, 95.0).toStringAsFixed(2));
          s.downstreamPressureBar = double.parse((s.upstreamPressureBar -
                  (0.35 + (_random.nextDouble() * 0.1)))
              .clamp(39.0, 94.5)
              .toStringAsFixed(2));

          final flowDelta = (_random.nextDouble() - 0.5) * 0.02;
          s.flowRateMmscmd = double.parse(
              (s.flowRateMmscmd + flowDelta).clamp(3.0, 7.0).toStringAsFixed(2));

          s.rtuLatencyMs = (20 + _random.nextInt(18));
          s.actuatorHydraulicPressureBar = double.parse(
              (s.actuatorHydraulicPressureBar + ((_random.nextDouble() - 0.5) * 0.3))
                  .clamp(170.0, 205.0)
                  .toStringAsFixed(1));

          // Append to chart history (keep 12 points window)
          if (s.upstreamHistory.isNotEmpty) {
            final lastX = s.upstreamHistory.last.x;
            final newSpotsUp = <FlSpot>[];
            final newSpotsDn = <FlSpot>[];
            for (int i = 1; i < s.upstreamHistory.length; i++) {
              newSpotsUp.add(
                  FlSpot(s.upstreamHistory[i].x - 1, s.upstreamHistory[i].y));
              newSpotsDn.add(FlSpot(
                  s.downstreamHistory[i].x - 1, s.downstreamHistory[i].y));
            }
            newSpotsUp.add(FlSpot(lastX, s.upstreamPressureBar));
            newSpotsDn.add(FlSpot(lastX, s.downstreamPressureBar));
            s.upstreamHistory = newSpotsUp;
            s.downstreamHistory = newSpotsDn;
          }
        }

        // Dynamically compute inlet, outlet, and imbalance mass flows
        _inletMassFlowTonsHr = double.parse(
            (_stations.first.flowRateMmscmd * 35.98).toStringAsFixed(2));
        _outletMassFlowTonsHr = double.parse(
            (_stations.last.flowRateMmscmd * 35.92).toStringAsFixed(2));
        _unaccountedMassTonsHr = double.parse(
            (_inletMassFlowTonsHr - _outletMassFlowTonsHr - 0.02).toStringAsFixed(2));
      });
    });
  }

  void _toggleLiveStream() {
    setState(() {
      _isLiveStreaming = !_isLiveStreaming;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLiveStreaming
              ? 'Telemetry Live Polling RESUMED (3.2s Modbus/IEC Stream)'
              : 'Telemetry Polling PAUSED for Static Inspection',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor:
            _isLiveStreaming ? AppTheme.primary : AppTheme.surfaceContainerHigh,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================================
  // INTERLOCK & TRIP SIMULATION LOGIC
  // ============================================================================

  void _triggerSimulatedTrip({
    required bool isPshh,
    required bool isPsll,
    required bool isRopd,
    required bool isManual,
  }) {
    final currentStation = _stations[_selectedStationIndex];
    setState(() {
      if (isPshh) _tripPshhSimulated = !_tripPshhSimulated;
      if (isPsll) _tripPsllSimulated = !_tripPsllSimulated;
      if (isRopd) _tripRopdSimulated = !_tripRopdSimulated;
      if (isManual) _tripManualEsdSimulated = !_tripManualEsdSimulated;

      final anyTrip = _tripPshhSimulated ||
          _tripPsllSimulated ||
          _tripRopdSimulated ||
          _tripManualEsdSimulated;

      if (anyTrip) {
        currentStation.esdvState = EsdvSafetyState.trippedClosed;
        currentStation.esdvPositionPct = 0.0;
        currentStation.mainlineValveState = ValvePositionState.fullyClosed;
        currentStation.mainlinePositionPct = 0.0;

        _auditLogs.insert(
          0,
          ValveOverrideAuditRecord(
            id: 'TRIP-${DateTime.now().millisecondsSinceEpoch % 10000}',
            timestamp: DateTime.now(),
            stationId: currentStation.id,
            valveTarget: 'ESDV-${currentStation.id} Hydraulic Fast-Closure',
            command: 'AUTOMATIC_SIL3_INTERLOCK_TRIP',
            operatorName: 'SIS Matrix Safety Logic',
            authorizationRole: 'Safety Instrumented System (IEC 61511)',
            preDiffPressureBar: currentStation.differentialPressureBar,
            bypassUsed: false,
            outcomeStatus: 'TRIPPED_TO_FAIL_SAFE (0.0s)',
            verificationHash: 'SHA256:e5c9a1...fa92',
          ),
        );
      } else {
        currentStation.esdvState = EsdvSafetyState.armedOpen;
        currentStation.esdvPositionPct = 100.0;
        currentStation.mainlineValveState = ValvePositionState.fullyOpen;
        currentStation.mainlinePositionPct = 100.0;
      }
    });

    if (currentStation.esdvState == EsdvSafetyState.trippedClosed) {
      _showEmergencyTripDialog(currentStation);
    }
  }

  void _showEmergencyTripDialog(ValveStationTelemetry station) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1014),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFEF4444), width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Row(
          children: [
            Icon(Icons.crisis_alert_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 10),
            Text(
              'SAFETY INTERLOCK TRIPPED',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'CRITICAL SHUTDOWN: ${station.id} (${station.name}) Emergency Shutdown Valve (ESDV) tripped to FAIL-SAFE CLOSED position.',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tripped Initiators Active:',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            if (_tripPshhSimulated)
              _buildTripIndicatorRow('PSHH (>90.0 Bar)', 'Pressure Switch High-High EXCEEDED'),
            if (_tripPsllSimulated)
              _buildTripIndicatorRow('PSLL (<45.0 Bar)', 'Pressure Switch Low-Low DROP'),
            if (_tripRopdSimulated)
              _buildTripIndicatorRow('RoPD (>2.5 Bar/min)', 'Rate of Pressure Drop VIOLATION'),
            if (_tripManualEsdSimulated)
              _buildTripIndicatorRow('Field Manual ESD', 'Emergency Push-Button Actuated'),
            const SizedBox(height: 10),
            const Text(
              'Scotch-yoke spring accumulator dumped in 0.85s. Pipeline sectionalized.',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('ACKNOWLEDGE INTERLOCK'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripIndicatorRow(String label, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '($detail)',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // PARTIAL STROKE TEST (PST) SIMULATION
  // ============================================================================

  void _runPartialStrokeTest(ValveStationTelemetry station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _PstExecutionSheet(
          station: station,
          onPstCompleted: (newPstDate, travelTime, breakawayTorque) {
            setState(() {
              station.lastPstDate = newPstDate;
              station.nextPstDueDate = newPstDate.add(const Duration(days: 30));
              station.pstResult = 'PASSED';
              station.pstTravelTimeSec = travelTime;
              station.pstBreakawayTorqueNm = breakawayTorque;

              _auditLogs.insert(
                0,
                ValveOverrideAuditRecord(
                  id: 'PST-${DateTime.now().millisecondsSinceEpoch % 10000}',
                  timestamp: newPstDate,
                  stationId: station.id,
                  valveTarget: 'ESDV-${station.id} Scotch-Yoke',
                  command: 'PST_15%_STROKE_TEST',
                  operatorName: 'SCADA PST Automated Engine',
                  authorizationRole: 'SIL-3 Diagnostic Test Routine',
                  preDiffPressureBar: station.differentialPressureBar,
                  bypassUsed: false,
                  outcomeStatus:
                      'PASSED (${travelTime.toStringAsFixed(2)}s, ${breakawayTorque.toStringAsFixed(0)}Nm)',
                  verificationHash: 'SHA256:d8b2e1...89cc',
                ),
              );
            });
          },
        );
      },
    );
  }

  // ============================================================================
  // VALVE OVERRIDE SIMULATION WITH SAFETY PIN
  // ============================================================================

  void _openValveOverrideSheet(ValveStationTelemetry station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _ValveActuationOverrideSheet(
          station: station,
          masterPin: _masterSafetyPin,
          onActionSuccess: (command, valveTarget, bypassUsed) {
            setState(() {
              _auditLogs.insert(
                0,
                ValveOverrideAuditRecord(
                  id: 'OVR-${DateTime.now().millisecondsSinceEpoch % 10000}',
                  timestamp: DateTime.now(),
                  stationId: station.id,
                  valveTarget: valveTarget,
                  command: command,
                  operatorName: 'Safety Controller (PIN Verified)',
                  authorizationRole: 'Chief Pipeline SCADA Controller',
                  preDiffPressureBar: station.differentialPressureBar,
                  bypassUsed: bypassUsed,
                  outcomeStatus: 'EXECUTED_SUCCESS',
                  verificationHash: 'SHA256:1a8c9b...44fd',
                ),
              );
            });
          },
        );
      },
    );
  }

  // ============================================================================
  // LDS LEAK SIMULATION & ACKNOWLEDGMENT
  // ============================================================================

  void _simulateNewLeakIncident() {
    final now = DateTime.now();
    final newId = 'LDS-${now.year}-${(now.millisecondsSinceEpoch % 900) + 100}';
    final candidateKp = 114.5 + (_random.nextDouble() * 20.0);

    setState(() {
      _activeLdsAlarms.insert(
        0,
        LdsAlarmEvent(
          id: newId,
          timestamp: now,
          section: 'VS-05 (Golaghat) to VS-06 (Bokakhat)',
          chainageKm: double.parse(candidateKp.toStringAsFixed(1)),
          chainageText: 'KP ${candidateKp.toStringAsFixed(1)} (Kaziranga Buffer)',
          method: LdsDetectionMethod.computationalMassBalance,
          severity: LdsAlarmSeverity.critical,
          estimatedLeakRateMms: 0.32,
          estimatedMassLossKgHr: 2540.0,
          confidenceScorePct: 98.4,
          timeOfFlightDeltaMs: 94.0,
          description:
              'Mass discrepancy transient detected (>1.8% inlet vs outlet imbalance). Acoustic rarefaction wavefront confirmed by upstream VS-05 piezoelectric sensor.',
          recommendedAction:
              'Immediate emergency sectionalizing advised. Close VS-05 Downstream and VS-06 Upstream ESDVs.',
          isAcknowledged: false,
          isHornSilenced: false,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'CRITICAL LDS LEAK ALARM SIMULATED: $newId at KP ${candidateKp.toStringAsFixed(1)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'VIEW ALARM',
          textColor: Colors.white,
          onPressed: () {
            _tabController.animateTo(3); // Switch to LDS tab
          },
        ),
      ),
    );
  }

  void _acknowledgeLdsAlarm(LdsAlarmEvent alarm) {
    setState(() {
      alarm.isAcknowledged = true;
      alarm.isHornSilenced = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('LDS Alarm ${alarm.id} Acknowledged by SCADA Operator'),
        backgroundColor: AppTheme.surfaceContainerHigh,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================================
  // BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final selectedStation = _stations[_selectedStationIndex];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Flexible(
                  child: Text(
                    'Valve Station SCADA',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: _isLiveStreaming
                        ? AppTheme.tertiary.withValues(alpha: 0.2)
                        : AppTheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _isLiveStreaming
                          ? AppTheme.tertiary
                          : AppTheme.secondary,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isLiveStreaming
                              ? AppTheme.tertiary
                              : AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _isLiveStreaming ? 'LIVE' : 'PAUSED',
                        style: TextStyle(
                          color: _isLiveStreaming
                              ? AppTheme.tertiary
                              : AppTheme.secondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            const Text(
              'DNNPL-18 Trunkline • VS-01 to VS-08 Remote Hub',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isLiveStreaming ? 'Pause Live Polling' : 'Resume Live Polling',
            icon: Icon(
              _isLiveStreaming
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: _isLiveStreaming ? AppTheme.primaryLight : AppTheme.secondary,
              size: 22,
            ),
            onPressed: _toggleLiveStream,
          ),
          IconButton(
            tooltip: 'Simulate Pipeline Leak Incident',
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 22,
            ),
            onPressed: _simulateNewLeakIncident,
          ),
          IconButton(
            tooltip: 'Safety Actuation Override',
            icon: const Icon(
              Icons.lock_open_rounded,
              color: AppTheme.secondary,
              size: 22,
            ),
            onPressed: () => _openValveOverrideSheet(selectedStation),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.primaryLight,
              indicatorWeight: 2.5,
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              tabs: [
                const Tab(text: 'Topology & Overview'),
                const Tab(text: 'Station Telemetry'),
                const Tab(text: 'ESDV & PST Testing'),
                Tab(
                  child: Row(
                    children: [
                      const Text('LDS Leak Detection'),
                      if (_activeLdsAlarms.any((a) => !a.isAcknowledged)) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_activeLdsAlarms.where((a) => !a.isAcknowledged).length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Override & Audit Log'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTopologyOverviewTab(),
          _buildStationTelemetryTab(),
          _buildEsdvPstTestingTab(),
          _buildLdsLeakDetectionTab(),
          _buildOverrideAuditLogTab(),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: TOPOLOGY & PIPELINE OVERVIEW
  // ============================================================================

  Widget _buildTopologyOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pipeline Mass Balance & Line Pack Summary Ribbon
          _buildPipelineHeaderBanner(),
          const SizedBox(height: 16),

          // Active Alarms Alert Banner (if any)
          if (_activeLdsAlarms.isNotEmpty) ...[
            _buildActiveAlarmsCallout(),
            const SizedBox(height: 16),
          ],

          // Schematic Pipeline Topology Map (VS-01 to VS-08 Flow Sequence)
          const Text(
            '194.5 KM NATURAL GAS TRUNKLINE SCHEMATIC (VS-01 → VS-08)',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _buildSchematicPipelineFlowStrip(),
          const SizedBox(height: 20),

          // Sectionalizing Valve Station Cards Grid
          Row(
            children: [
              const Expanded(
                child: Text(
                  'SECTIONALIZING VALVE STATIONS (VS-01 to VS-08)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_stations.length} ONLINE',
                style: const TextStyle(
                  color: AppTheme.tertiary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final station = _stations[index];
              final isSelected = index == _selectedStationIndex;
              return _buildStationCard(station, index, isSelected);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings_input_composite_rounded,
                  color: AppTheme.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duliajan – Numaligarh – Nagaon Trunkline',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '18" OD API 5L X70 • Design: 98 Bar • MOP: 85 Bar • IEC 60870-5-104',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.tertiary, width: 0.8),
                ),
                child: const Text(
                  'SIL 3 SIS READY',
                  style: TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat(
                'Line Pack Mass',
                '${_linePackMassTons.toStringAsFixed(1)} T',
                Icons.inventory_2_rounded,
                AppTheme.primaryLight,
              ),
              _buildHeaderStat(
                'Inlet Mass Rate',
                '${_inletMassFlowTonsHr.toStringAsFixed(1)} t/h',
                Icons.input_rounded,
                AppTheme.tertiary,
              ),
              _buildHeaderStat(
                'Outlet Mass Rate',
                '${_outletMassFlowTonsHr.toStringAsFixed(1)} t/h',
                Icons.output_rounded,
                AppTheme.secondary,
              ),
              _buildHeaderStat(
                'CPM Balance Δ',
                '${_unaccountedMassTonsHr > 0 ? "+" : ""}${_unaccountedMassTonsHr.toStringAsFixed(2)} t/h',
                Icons.balance_rounded,
                _unaccountedMassTonsHr.abs() < 0.5
                    ? AppTheme.tertiary
                    : const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveAlarmsCallout() {
    final unacked = _activeLdsAlarms.where((a) => !a.isAcknowledged).toList();
    if (unacked.isEmpty) return const SizedBox.shrink();

    final topAlarm = unacked.first;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.crisis_alert_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ACTIVE LDS ALARM: ${topAlarm.id}',
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        topAlarm.severity.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${topAlarm.chainageText} • Est: ${topAlarm.estimatedLeakRateMms} MMSCMD (${topAlarm.confidenceScorePct}% confidence)',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              _tabController.animateTo(3);
            },
            child: const Text('INSPECT'),
          ),
        ],
      ),
    );
  }

  Widget _buildSchematicPipelineFlowStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.compare_arrows_rounded,
                  color: AppTheme.primaryLight, size: 16),
              SizedBox(width: 6),
              Text(
                'Sequential Hydraulic Flow & Valve Isolation Status',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Text(
                'KP 0.0 → KP 194.5',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal scrolling schematic node tree
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_stations.length, (i) {
                final st = _stations[i];
                final isSelected = i == _selectedStationIndex;
                final isTripped = st.esdvState == EsdvSafetyState.trippedClosed;
                final isPstDue = st.pstResult == 'DUE';

                return Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedStationIndex = i;
                        });
                        _tabController.animateTo(1);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.25)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isTripped
                                ? const Color(0xFFEF4444)
                                : isSelected
                                    ? AppTheme.primaryLight
                                    : AppTheme.border,
                            width: isSelected || isTripped ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isTripped
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                    : isPstDue
                                        ? AppTheme.secondary.withValues(alpha: 0.2)
                                        : AppTheme.tertiary.withValues(alpha: 0.2),
                              ),
                              child: Icon(
                                isTripped
                                    ? Icons.cancel_rounded
                                    : Icons.radio_button_checked_rounded,
                                size: 16,
                                color: isTripped
                                    ? const Color(0xFFEF4444)
                                    : isPstDue
                                        ? AppTheme.secondary
                                        : AppTheme.tertiary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              st.id,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryLight
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              st.chainage,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 9.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${st.upstreamPressureBar.toStringAsFixed(1)} Bar',
                                style: const TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < _stations.length - 1)
                      Container(
                        width: 24,
                        height: 3,
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCard(
      ValveStationTelemetry station, int index, bool isSelected) {
    final isTripped = station.esdvState == EsdvSafetyState.trippedClosed;
    final isPstDue = station.pstResult == 'DUE';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStationIndex = index;
        });
        _tabController.animateTo(1);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isTripped
                ? const Color(0xFFEF4444)
                : isSelected
                    ? AppTheme.primaryLight
                    : AppTheme.border,
            width: isSelected || isTripped ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTripped
                        ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                        : AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isTripped
                          ? const Color(0xFFEF4444)
                          : AppTheme.primaryLight,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    station.id,
                    style: TextStyle(
                      color: isTripped
                          ? const Color(0xFFEF4444)
                          : AppTheme.primaryLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${station.chainage} • Elev: ${station.elevationM.toStringAsFixed(0)}m • ${station.rtuModel}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quick Action: Actuation override button
                IconButton(
                  icon: const Icon(Icons.tune_rounded,
                      color: AppTheme.secondary, size: 20),
                  tooltip: 'Actuation & Bypass Override',
                  onPressed: () => _openValveOverrideSheet(station),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textMuted,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.border),
            const SizedBox(height: 10),
            // Primary telemetry meters
            Row(
              children: [
                Expanded(
                  child: _buildTelemetryPill(
                    'Upstream',
                    '${station.upstreamPressureBar.toStringAsFixed(2)} Bar',
                    AppTheme.primaryLight,
                  ),
                ),
                Expanded(
                  child: _buildTelemetryPill(
                    'Downstream',
                    '${station.downstreamPressureBar.toStringAsFixed(2)} Bar',
                    AppTheme.primaryLight,
                  ),
                ),
                Expanded(
                  child: _buildTelemetryPill(
                    'Differential ΔP',
                    '${station.differentialPressureBar.toStringAsFixed(2)} Bar',
                    station.isDifferentialPressureSafe
                        ? AppTheme.tertiary
                        : const Color(0xFFEF4444),
                  ),
                ),
                Expanded(
                  child: _buildTelemetryPill(
                    'Flow Rate',
                    '${station.flowRateMmscmd.toStringAsFixed(2)} MMS',
                    AppTheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Secondary status badges
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusPill(
                    label: station.mainlineValveState == ValvePositionState.fullyOpen
                        ? 'MAINLINE OPEN'
                        : 'MAINLINE CLOSED',
                    color: station.mainlineValveState == ValvePositionState.fullyOpen
                        ? AppTheme.tertiary
                        : const Color(0xFFEF4444),
                    icon: station.mainlineValveState == ValvePositionState.fullyOpen
                        ? Icons.check_circle_rounded
                        : Icons.block_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusPill(
                    label: isTripped ? 'ESDV TRIPPED' : 'ESDV ARMED',
                    color: isTripped ? const Color(0xFFEF4444) : AppTheme.tertiary,
                    icon: isTripped
                        ? Icons.error_outline_rounded
                        : Icons.shield_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusPill(
                    label: 'PST: ${station.pstResult}',
                    color: isPstDue ? AppTheme.secondary : AppTheme.tertiary,
                    icon: isPstDue
                        ? Icons.timelapse_rounded
                        : Icons.verified_user_rounded,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${station.rtuLatencyMs}ms ping',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryPill(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: DETAILED STATION TELEMETRY
  // ============================================================================

  Widget _buildStationTelemetryTab() {
    final station = _stations[_selectedStationIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Selector Dropdown Strip
          _buildStationSelectorStrip(),
          const SizedBox(height: 16),

          // Station Header Banner
          _buildStationDetailHeader(station),
          const SizedBox(height: 16),

          // Primary Gauges & Metrics (Upstream, Downstream, Flow, Temp)
          _buildTelemetryMetricCards(station),
          const SizedBox(height: 16),

          // Pressure Trends Chart (fl_chart)
          _buildPressureTrendChartCard(station),
          const SizedBox(height: 16),

          // RTU Communications & Solar Health Card
          _buildRtuDiagnosticsCard(station),
          const SizedBox(height: 20),

          // Quick Action Bar
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                  label: const Text('ACTUATE / OVERRIDE'),
                  onPressed: () => _openValveOverrideSheet(station),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondary,
                    side: const BorderSide(color: AppTheme.secondary),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.speed_rounded, size: 18),
                  label: const Text('RUN PST TEST'),
                  onPressed: () => _runPartialStrokeTest(station),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStationSelectorStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_stations.length, (idx) {
          final st = _stations[idx];
          final isSelected = idx == _selectedStationIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${st.id} (${st.chainage})'),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedStationIndex = idx;
                  });
                }
              },
              backgroundColor: AppTheme.surfaceCard,
              selectedColor: AppTheme.primary.withValues(alpha: 0.3),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryLight : AppTheme.border,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStationDetailHeader(ValveStationTelemetry station) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.router_rounded,
              color: AppTheme.primaryLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'MODBUS TCP ONLINE',
                        style: TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Chainage: ${station.chainage} • Elev: ${station.elevationM.toStringAsFixed(1)} m MSL • Protocol: ${station.commProtocol}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryMetricCards(ValveStationTelemetry station) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Upstream Pressure',
                value: station.upstreamPressureBar.toStringAsFixed(2),
                unit: 'Bar(g)',
                subtitle: 'Normal: 70 - 82 Bar',
                color: AppTheme.primaryLight,
                icon: Icons.compress_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Downstream Pressure',
                value: station.downstreamPressureBar.toStringAsFixed(2),
                unit: 'Bar(g)',
                subtitle: 'ΔP: ${station.differentialPressureBar.toStringAsFixed(2)} Bar',
                color: AppTheme.primaryLight,
                icon: Icons.expand_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Natural Gas Flow',
                value: station.flowRateMmscmd.toStringAsFixed(2),
                unit: 'MMSCMD',
                subtitle: 'Standard Volumetric Rate',
                color: AppTheme.secondary,
                icon: Icons.water_drop_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Gas Temperature',
                value: station.gasTemperatureC.toStringAsFixed(1),
                unit: '°C',
                subtitle: 'PT100 RTD Dual Sensor',
                color: AppTheme.tertiary,
                icon: Icons.thermostat_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 5),
              Text(
                unit,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureTrendChartCard(ValveStationTelemetry station) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded,
                  color: AppTheme.primaryLight, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Live Hydraulic Pressure Trend (Bar)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildChartLegendPill(
                  'Upstream', AppTheme.primaryLight),
              const SizedBox(width: 8),
              _buildChartLegendPill(
                  'Downstream', AppTheme.tertiary),
            ],
          ),
          const SizedBox(height: 16),
          // FlChart
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1.0,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: AppTheme.border.withValues(alpha: 0.4),
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 2,
                      getTitlesWidget: (val, meta) {
                        final v = val.toInt();
                        return Text(
                          'T-$v',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 9.5),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 1.0,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          val.toStringAsFixed(0),
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 9.5),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 11,
                minY: (station.downstreamPressureBar - 2.0).clamp(40.0, 90.0),
                maxY: (station.upstreamPressureBar + 2.0).clamp(50.0, 100.0),
                lineBarsData: [
                  // Upstream pressure curve
                  LineChartBarData(
                    spots: station.upstreamHistory,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: AppTheme.primaryLight,
                    barWidth: 2.2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  // Downstream pressure curve
                  LineChartBarData(
                    spots: station.downstreamHistory,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: AppTheme.tertiary,
                    barWidth: 2.0,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendPill(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRtuDiagnosticsCard(ValveStationTelemetry station) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.perm_device_information_rounded,
                  color: AppTheme.textSecondary, size: 16),
              SizedBox(width: 6),
              Text(
                'RTU TELEMETRY & HARDWARE HEALTH',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDiagItem(
                'RTU Supply',
                '${station.rtuBatteryVolt.toStringAsFixed(1)} VDC',
                'Solar Float',
                Icons.solar_power_rounded,
                AppTheme.tertiary,
              ),
              _buildDiagItem(
                'Comm Latency',
                '${station.rtuLatencyMs} ms',
                'IEC 60870 Link',
                Icons.network_ping_rounded,
                AppTheme.primaryLight,
              ),
              _buildDiagItem(
                'Hydraulic Acc.',
                '${station.actuatorHydraulicPressureBar.toStringAsFixed(1)} Bar',
                'Accumulator',
                Icons.speed_rounded,
                AppTheme.secondary,
              ),
              _buildDiagItem(
                'N2 Backup',
                '${station.nitrogenPressureBar.toStringAsFixed(0)} Bar',
                'Backup Cylinder',
                Icons.propane_tank_rounded,
                AppTheme.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagItem(String title, String val, String sub, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        Text(sub, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
      ],
    );
  }

  // ============================================================================
  // TAB 3: ESDV STATUS & PARTIAL STROKE TESTING (PST)
  // ============================================================================

  Widget _buildEsdvPstTestingTab() {
    final station = _stations[_selectedStationIndex];
    final isTripped = station.esdvState == EsdvSafetyState.trippedClosed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Selector
          _buildStationSelectorStrip(),
          const SizedBox(height: 16),

          // ESDV Valve State & Actuator Status Card
          _buildEsdvStatusOverviewCard(station),
          const SizedBox(height: 16),

          // Partial Stroke Testing (PST) Engine Card
          _buildPstTelemetryCard(station),
          const SizedBox(height: 16),

          // SIL-3 Remote Closure Interlock Simulation Matrix
          _buildInterlockSimulationMatrixCard(station, isTripped),
          const SizedBox(height: 16),

          // Actuator Diagnostics & Nitrogen Reservoir
          _buildActuatorHydraulicsCard(station),
        ],
      ),
    );
  }

  Widget _buildEsdvStatusOverviewCard(ValveStationTelemetry station) {
    final isTripped = station.esdvState == EsdvSafetyState.trippedClosed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTripped
            ? const Color(0xFFEF4444).withValues(alpha: 0.1)
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTripped ? const Color(0xFFEF4444) : AppTheme.border,
          width: isTripped ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isTripped
                      ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                      : AppTheme.tertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isTripped ? Icons.warning_rounded : Icons.shield_rounded,
                  color: isTripped ? const Color(0xFFEF4444) : AppTheme.tertiary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESDV-${station.id} Emergency Shutdown Valve',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Actuator: Scotch-Yoke Spring Return • SIL-3 Rated (IEC 61508)',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isTripped
                      ? const Color(0xFFEF4444)
                      : AppTheme.tertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isTripped ? 'TRIPPED (0%)' : 'ARMED (100%)',
                  style: TextStyle(
                    color: isTripped ? Colors.white : AppTheme.tertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Position progress meter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Valve Stem Position',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  Text(
                    '${station.esdvPositionPct.toStringAsFixed(0)}% (${station.esdvPositionPct == 100.0 ? "FULL OPEN" : "FAIL-SAFE CLOSED"})',
                    style: TextStyle(
                      color: isTripped ? const Color(0xFFEF4444) : AppTheme.tertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: station.esdvPositionPct / 100.0,
                  backgroundColor: AppTheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isTripped ? const Color(0xFFEF4444) : AppTheme.tertiary,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPstTelemetryCard(ValveStationTelemetry station) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final isDue = station.pstResult == 'DUE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_rounded,
                  color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Partial Stroke Testing (PST) Diagnostics',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDue
                      ? AppTheme.secondary.withValues(alpha: 0.2)
                      : AppTheme.tertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'STATUS: ${station.pstResult}',
                  style: TextStyle(
                    color: isDue ? AppTheme.secondary : AppTheme.tertiary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'PST strokes the ESDV disc by 15% to confirm solenoid, valve stem mobility, and seat breakaway torque without interrupting natural gas flow.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPstStat('Last Executed', dateFormat.format(station.lastPstDate)),
              _buildPstStat('Travel Time', '${station.pstTravelTimeSec} s (<3.5s norm)'),
              _buildPstStat('Breakaway Torque', '${station.pstBreakawayTorqueNm.toStringAsFixed(0)} Nm'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: const Color(0xFF0B1326),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text('EXECUTE PARTIAL STROKE TEST (15%) ON ${station.id}'),
              onPressed: () => _runPartialStrokeTest(station),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPstStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInterlockSimulationMatrixCard(
      ValveStationTelemetry station, bool isTripped) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppTheme.primaryLight, size: 18),
              SizedBox(width: 8),
              Text(
                'SIL-3 Remote Closure Interlock Simulation',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Simulate safety instrumented initiators to verify fast-trip action & fail-safe dumping logic.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          _buildInterlockSwitchTile(
            title: 'Pressure Switch High-High (PSHH > 90.0 Bar)',
            subtitle: 'Over-pressure pipeline burst protection',
            isActive: _tripPshhSimulated,
            onChanged: (val) => _triggerSimulatedTrip(
              isPshh: true,
              isPsll: false,
              isRopd: false,
              isManual: false,
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          _buildInterlockSwitchTile(
            title: 'Pressure Switch Low-Low (PSLL < 45.0 Bar)',
            subtitle: 'Major downstream rupture detection trip',
            isActive: _tripPsllSimulated,
            onChanged: (val) => _triggerSimulatedTrip(
              isPshh: false,
              isPsll: true,
              isRopd: false,
              isManual: false,
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          _buildInterlockSwitchTile(
            title: 'Rate of Pressure Drop (RoPD > 2.5 Bar/min)',
            subtitle: 'Rapid acoustic transient decompression trip',
            isActive: _tripRopdSimulated,
            onChanged: (val) => _triggerSimulatedTrip(
              isPshh: false,
              isPsll: false,
              isRopd: true,
              isManual: false,
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          _buildInterlockSwitchTile(
            title: 'Field Manual Push-Button ESD Station',
            subtitle: 'Physical operator emergency mushroom button',
            isActive: _tripManualEsdSimulated,
            onChanged: (val) => _triggerSimulatedTrip(
              isPshh: false,
              isPsll: false,
              isRopd: false,
              isManual: true,
            ),
          ),
          if (isTripped) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tertiary,
                  foregroundColor: const Color(0xFF0B1326),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('RESET & RE-ARM ESDV SAFETY SYSTEM'),
                onPressed: () {
                  setState(() {
                    _tripPshhSimulated = false;
                    _tripPsllSimulated = false;
                    _tripRopdSimulated = false;
                    _tripManualEsdSimulated = false;
                    station.esdvState = EsdvSafetyState.armedOpen;
                    station.esdvPositionPct = 100.0;
                    station.mainlineValveState = ValvePositionState.fullyOpen;
                    station.mainlinePositionPct = 100.0;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ESDV Safety Interlock Cleared and Re-Armed to OPEN'),
                      backgroundColor: AppTheme.tertiary,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInterlockSwitchTile({
    required String title,
    required String subtitle,
    required bool isActive,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? const Color(0xFFEF4444) : AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            activeThumbColor: const Color(0xFFEF4444),
            activeTrackColor: const Color(0xFFEF4444).withValues(alpha: 0.5),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActuatorHydraulicsCard(ValveStationTelemetry station) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.precision_manufacturing_rounded,
                  color: AppTheme.primaryLight, size: 16),
              SizedBox(width: 6),
              Text(
                'ACTUATOR HYDRAULIC POWER UNIT (HPU)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHpuMetric(
                'Accumulator P',
                '${station.actuatorHydraulicPressureBar.toStringAsFixed(1)} Bar',
                'Set: 190 Bar',
                station.actuatorHydraulicPressureBar >= 160.0
                    ? AppTheme.tertiary
                    : AppTheme.secondary,
              ),
              _buildHpuMetric(
                'N2 Pre-charge',
                '${station.nitrogenPressureBar.toStringAsFixed(0)} Bar',
                'Design: 220 Bar',
                AppTheme.primaryLight,
              ),
              _buildHpuMetric(
                'Fluid Level',
                '94.2 %',
                'AeroShell Fluid 41',
                AppTheme.tertiary,
              ),
              _buildHpuMetric(
                'Solenoid Dual',
                'ENERGIZED',
                '24V DC Redundant',
                AppTheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHpuMetric(String title, String val, String sub, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 3),
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        Text(sub, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
      ],
    );
  }

  // ============================================================================
  // TAB 4: GAS LEAK DETECTION SYSTEM (LDS) & CPM MASS BALANCE
  // ============================================================================

  Widget _buildLdsLeakDetectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CPM Mass Balance Calculation Summary
          _buildCpmMassBalanceCard(),
          const SizedBox(height: 16),

          // Acoustic Negative Pressure Wave (NPW) Transducer Array Status
          _buildAcousticSensorArrayCard(),
          const SizedBox(height: 16),

          // Active LDS Alarms Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE LDS INCIDENTS & TRANSIENT ALARMS',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.add_alert_rounded, size: 16),
                label: const Text('Simulate Leak'),
                onPressed: _simulateNewLeakIncident,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // List of LDS Alarms
          if (_activeLdsAlarms.isEmpty)
            _buildNoAlarmsCard()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activeLdsAlarms.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final alarm = _activeLdsAlarms[index];
                return _buildLdsAlarmCard(alarm);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCpmMassBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calculate_rounded,
                    color: AppTheme.primaryLight, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Computational Pipeline Monitoring (CPM)',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'API 1130 & OISD-141 Mass Balance Continuous Algorithm',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BALANCE 99.8%',
                  style: TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pipeline Inventory (Line Pack):',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    Text('${_linePackMassTons.toStringAsFixed(1)} Tons',
                        style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Custody Transfer Inflow (VS-01):',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    Text('${_inletMassFlowTonsHr.toStringAsFixed(2)} t/h',
                        style: const TextStyle(
                            color: AppTheme.tertiary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Terminal Outflow (VS-08):',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    Text('${_outletMassFlowTonsHr.toStringAsFixed(2)} t/h',
                        style: const TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Mass Imbalance (Δm):',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    Text(
                      '${_unaccountedMassTonsHr.toStringAsFixed(2)} t/h (0.19%)',
                      style: TextStyle(
                        color: _unaccountedMassTonsHr < 0.5
                            ? AppTheme.tertiary
                            : const Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcousticSensorArrayCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.graphic_eq_rounded,
                  color: AppTheme.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Acoustic Wave & Negative Pressure Wave (NPW)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Piezoelectric transducers at 100 Hz calculate rarefaction wave time-of-flight to pinpoint rupture location within ±150m.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAcousticStat('Wave Velocity (a)', '385 m/s', 'Natural Gas'),
              _buildAcousticStat('Sample Rate', '100 Hz', 'High-Speed RTU'),
              _buildAcousticStat('Sensors Online', '16 / 16', 'Dual Transducers'),
              _buildAcousticStat('Avg Background', '-68 dBm', 'Normal Vibration'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcousticStat(String label, String value, String sub) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.secondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        Text(sub, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
      ],
    );
  }

  Widget _buildNoAlarmsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 40),
          SizedBox(height: 10),
          Text(
            'All Pipeline Segments Normal',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'No active acoustic negative pressure waves or mass discrepancies detected.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLdsAlarmCard(LdsAlarmEvent alarm) {
    final isCritical = alarm.severity == LdsAlarmSeverity.critical;
    final timeStr = DateFormat('HH:mm:ss').format(alarm.timestamp);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCritical
            ? const Color(0xFFEF4444).withValues(alpha: 0.12)
            : const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCritical
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.crisis_alert_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          alarm.id,
                          style: TextStyle(
                            color: isCritical
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 10.5),
                        ),
                      ],
                    ),
                    Text(
                      alarm.section,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: alarm.isAcknowledged
                      ? AppTheme.surface
                      : (isCritical
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  alarm.isAcknowledged ? 'ACKNOWLEDGED' : 'ACTIVE UNACKED',
                  style: TextStyle(
                    color: alarm.isAcknowledged
                        ? AppTheme.textSecondary
                        : Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Triangulated location & leak parameters
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Leak Location:',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    Text(alarm.chainageText,
                        style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Rate of Leakage:',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    Text(
                      '${alarm.estimatedLeakRateMms} MMSCMD (${alarm.estimatedMassLossKgHr.toStringAsFixed(0)} kg/h)',
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Wave Time-of-Flight (Δt):',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    Text('${alarm.timeOfFlightDeltaMs} ms (${alarm.confidenceScorePct}% confidence)',
                        style: const TextStyle(
                            color: AppTheme.tertiary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            alarm.description,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            'Recommended Protocol: ${alarm.recommendedAction}',
            style: const TextStyle(
              color: AppTheme.secondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!alarm.isAcknowledged)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCritical
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _acknowledgeLdsAlarm(alarm),
                    child: const Text('ACKNOWLEDGE ALARM'),
                  ),
                ),
              if (!alarm.isAcknowledged) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                    side: const BorderSide(color: AppTheme.primaryLight),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    // Navigate to valve override
                    _openValveOverrideSheet(_stations[_selectedStationIndex]);
                  },
                  child: const Text('ISOLATE SECTION'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 5: VALVE OVERRIDE & AUDIT LOGS
  // ============================================================================

  Widget _buildOverrideAuditLogTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Safety Authorization Rules Card
          _buildSafetyAuthorizationNoticeCard(),
          const SizedBox(height: 16),

          // Interactive Quick Override Launcher
          _buildQuickOverrideLauncherCard(),
          const SizedBox(height: 20),

          // Audit Records List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CRYPTOGRAPHIC SCADA AUDIT TRAIL (SHA-256)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${_auditLogs.length} LOGGED ACTIONS',
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _auditLogs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final log = _auditLogs[index];
              return _buildAuditLogCard(log);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyAuthorizationNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel_rounded, color: AppTheme.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'SCADA Valve Actuation & Override Protocol',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'In accordance with PNGRB T4S & OISD-STD-141: Remote mainline ball valve opening against differential pressure (ΔP) > 3.0 Bar is physically interlocked. Equalizing bypass line must be engaged first to prevent seal erosion.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.pin_rounded, color: AppTheme.primaryLight, size: 16),
                SizedBox(width: 6),
                Text(
                  'Simulation Master Safety PIN: 7492 (Chief Controller Access)',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOverrideLauncherCard() {
    final currentStation = _stations[_selectedStationIndex];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Selected Target: ${currentStation.id} (${currentStation.name})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ΔP: ${currentStation.differentialPressureBar.toStringAsFixed(2)} Bar',
                style: TextStyle(
                  color: currentStation.isDifferentialPressureSafe
                      ? AppTheme.tertiary
                      : const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.dialpad_rounded, size: 18),
              label: Text('ENTER SAFETY PIN & OVERRIDE ${currentStation.id}'),
              onPressed: () => _openValveOverrideSheet(currentStation),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogCard(ValveOverrideAuditRecord log) {
    final timeStr = DateFormat('dd MMM, HH:mm:ss').format(log.timestamp);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.stationId,
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  log.command,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Text(
                timeStr,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Target: ${log.valveTarget} • Authorized by: ${log.operatorName} (${log.authorizationRole})',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pre-actuation ΔP: ${log.preDiffPressureBar.toStringAsFixed(2)} Bar • Bypass: ${log.bypassUsed ? "YES" : "NO"}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.outcomeStatus,
                  style: const TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            log.verificationHash,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 8.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PARTIAL STROKE TEST (PST) EXECUTION BOTTOM SHEET
// ============================================================================

class _PstExecutionSheet extends StatefulWidget {
  final ValveStationTelemetry station;
  final Function(DateTime newDate, double travelTime, double torque)
      onPstCompleted;

  const _PstExecutionSheet({
    required this.station,
    required this.onPstCompleted,
  });

  @override
  State<_PstExecutionSheet> createState() => _PstExecutionSheetState();
}

class _PstExecutionSheetState extends State<_PstExecutionSheet> {
  int _currentStep = 0;
  bool _isTesting = false;
  double _valveStrokePct = 100.0;
  String _stepStatusText = 'Ready to initiate test routine';
  Timer? _pstTimer;

  final List<String> _stepTitles = [
    'Pre-Check: Verify RTU Permissives & Hydraulic Pressure',
    'Actuate Solenoid: Ramp Valve Position to 85% (15% Stroke)',
    'Hold & Diagnostic Measurement (Breakaway Torque Profile)',
    'Spring-Return Actuator Recovery to 100% (Full Open)',
    'Verification & Limit Switch ZSO Engagement Complete',
  ];

  @override
  void dispose() {
    _pstTimer?.cancel();
    super.dispose();
  }

  void _startPstSimulation() {
    setState(() {
      _isTesting = true;
      _currentStep = 0;
      _stepStatusText = 'Step 1/5: Checking RTU accumulator pressure (190 Bar)...';
    });

    _pstTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) return;

      setState(() {
        if (_currentStep == 0) {
          _currentStep = 1;
          _valveStrokePct = 92.0;
          _stepStatusText = 'Step 2/5: Solenoid pulsing valve stem towards 85%...';
        } else if (_currentStep == 1) {
          _currentStep = 2;
          _valveStrokePct = 85.0;
          _stepStatusText = 'Step 3/5: Measuring breakaway torque (4,180 Nm)...';
        } else if (_currentStep == 2) {
          _currentStep = 3;
          _valveStrokePct = 95.0;
          _stepStatusText = 'Step 4/5: Actuator spring recovering valve to full open...';
        } else if (_currentStep == 3) {
          _currentStep = 4;
          _valveStrokePct = 100.0;
          _stepStatusText = 'Step 5/5: Limit switch ZSO engaged. PST PASSED!';
        } else {
          _pstTimer?.cancel();
          _isTesting = false;
          widget.onPstCompleted(DateTime.now(), 2.38, 4180.0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.speed_rounded,
                    color: AppTheme.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PST Routine: ESDV-${widget.station.id}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Station: ${widget.station.name} (${widget.station.chainage})',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Live valve position gauge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Valve Stem Position:',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    Text(
                      '${_valveStrokePct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _valveStrokePct / 100.0,
                    backgroundColor: AppTheme.surfaceCard,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _stepStatusText,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Step progression
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stepTitles.length,
            itemBuilder: (context, idx) {
              final isDone = idx < _currentStep;
              final isCurrent = idx == _currentStep && _isTesting;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : isCurrent
                              ? Icons.sync_rounded
                              : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isDone
                          ? AppTheme.tertiary
                          : isCurrent
                              ? AppTheme.secondary
                              : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _stepTitles[idx],
                        style: TextStyle(
                          color: isDone || isCurrent
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTesting
                        ? AppTheme.surfaceContainerHigh
                        : AppTheme.secondary,
                    foregroundColor: const Color(0xFF0B1326),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(
                    _isTesting ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(_isTesting ? 'TEST IN PROGRESS...' : 'START PST TEST'),
                  onPressed: _isTesting ? null : _startPstSimulation,
                ),
              ),
              if (!_isTesting && _currentStep >= 4) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.tertiary,
                    side: const BorderSide(color: AppTheme.tertiary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// VALVE ACTUATION & OVERRIDE SHEET WITH SAFETY PIN KEYPAD
// ============================================================================

class _ValveActuationOverrideSheet extends StatefulWidget {
  final ValveStationTelemetry station;
  final String masterPin;
  final Function(String command, String target, bool bypassUsed)
      onActionSuccess;

  const _ValveActuationOverrideSheet({
    required this.station,
    required this.masterPin,
    required this.onActionSuccess,
  });

  @override
  State<_ValveActuationOverrideSheet> createState() =>
      _ValveActuationOverrideSheetState();
}

class _ValveActuationOverrideSheetState
    extends State<_ValveActuationOverrideSheet> {
  String _enteredPin = '';
  bool _isPinVerified = false;
  String _pinErrorMessage = '';
  String _selectedAction = 'CLOSE_MAINLINE'; // 'OPEN_MAINLINE', 'CLOSE_MAINLINE', 'OPEN_BYPASS'
  bool _bypassEngaged = false;
  bool _isActuating = false;
  double _actuationProgress = 0.0;
  String _actuationStageText = '';
  Timer? _actuationTimer;

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _pinErrorMessage = '';
      });
      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _pinErrorMessage = '';
      });
    }
  }

  void _verifyPin() {
    if (_enteredPin == widget.masterPin) {
      setState(() {
        _isPinVerified = true;
        _pinErrorMessage = '';
      });
    } else {
      setState(() {
        _enteredPin = '';
        _pinErrorMessage = 'Invalid Safety PIN. Use demo PIN 7492.';
      });
    }
  }

  void _executeValveActuation() {
    // Safety Interlock check: If attempting to OPEN Mainline valve while ΔP > 3.0 Bar without bypass
    final diffP = widget.station.differentialPressureBar;
    if (_selectedAction == 'OPEN_MAINLINE' && diffP > 3.0 && !_bypassEngaged) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFEF4444)),
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 24),
              SizedBox(width: 8),
              Text(
                'DIFFERENTIAL PRESSURE TRIP',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Cannot open 18" Mainline Ball Valve against ΔP of ${diffP.toStringAsFixed(2)} Bar (> 3.0 Bar limit). High pressure differential will cause seal scouring and seat cavitation.\n\nPlease open the 2" Equalizing Bypass Valve first to balance upstream/downstream pressure.',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _selectedAction = 'OPEN_BYPASS';
                });
              },
              child: const Text('SELECT BYPASS VALVE FIRST'),
            ),
          ],
        ),
      );
      return;
    }

    // Execute simulated actuation
    setState(() {
      _isActuating = true;
      _actuationProgress = 0.0;
      _actuationStageText = 'Energizing hydraulic actuator solenoid...';
    });

    _actuationTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;

      setState(() {
        _actuationProgress += 0.25;

        if (_actuationProgress <= 0.25) {
          _actuationStageText = 'Unseating seal breakaway torque (4,200 Nm)...';
        } else if (_actuationProgress <= 0.50) {
          _actuationStageText = 'Quarter-turn ball traveling: 45° rotation...';
        } else if (_actuationProgress <= 0.75) {
          _actuationStageText = 'Approaching end-stop limit switch...';
        } else if (_actuationProgress >= 1.0) {
          _actuationTimer?.cancel();
          _isActuating = false;
          _actuationStageText = 'Actuation Complete. Limit switches confirmed.';

          // Apply state change to station
          if (_selectedAction == 'OPEN_MAINLINE') {
            widget.station.mainlineValveState = ValvePositionState.fullyOpen;
            widget.station.mainlinePositionPct = 100.0;
          } else if (_selectedAction == 'CLOSE_MAINLINE') {
            widget.station.mainlineValveState = ValvePositionState.fullyClosed;
            widget.station.mainlinePositionPct = 0.0;
          } else if (_selectedAction == 'OPEN_BYPASS') {
            widget.station.bypassValveOpen = true;
            _bypassEngaged = true;
            // Equalize pressure
            widget.station.downstreamPressureBar =
                widget.station.upstreamPressureBar - 0.2;
          }

          widget.onActionSuccess(
            _selectedAction,
            _selectedAction.contains('BYPASS')
                ? '2" Equalizing Bypass Valve'
                : '18" Mainline Ball Valve',
            _bypassEngaged,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _actuationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.security_rounded,
                      color: AppTheme.secondary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remote Actuation: ${widget.station.id}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.station.name} • ΔP: ${widget.station.differentialPressureBar.toStringAsFixed(2)} Bar',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // PIN Verification Step
            if (!_isPinVerified) ...[
              _buildPinVerificationView(),
            ] else ...[
              // Action Selection & Actuation Controls
              _buildActionControlsView(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPinVerificationView() {
    return Column(
      children: [
        const Text(
          'ENTER 4-DIGIT SAFETY AUTHORIZATION PIN',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Two-factor engineering sign-off required before motor actuation.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 16),
        // PIN Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final isFilled = i < _enteredPin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? AppTheme.primaryLight : AppTheme.surface,
                border: Border.all(
                  color: isFilled ? AppTheme.primaryLight : AppTheme.border,
                  width: 1.5,
                ),
              ),
            );
          }),
        ),
        if (_pinErrorMessage.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            _pinErrorMessage,
            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
          ),
        ],
        const SizedBox(height: 20),
        // Keypad (0-9)
        _buildKeypad(),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            setState(() {
              _enteredPin = widget.masterPin;
              _verifyPin();
            });
          },
          child: const Text(
            'Auto-Fill Demo Safety PIN (7492)',
            style: TextStyle(color: AppTheme.primaryLight, fontSize: 11.5),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            return Padding(
              padding: const EdgeInsets.all(5),
              child: SizedBox(
                width: 68,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    if (key == 'C') {
                      setState(() {
                        _enteredPin = '';
                        _pinErrorMessage = '';
                      });
                    } else if (key == '⌫') {
                      _onBackspace();
                    } else {
                      _onKeyPress(key);
                    }
                  },
                  child: Text(
                    key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildActionControlsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.tertiary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.tertiary, width: 0.8),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded,
                  color: AppTheme.tertiary, size: 16),
              SizedBox(width: 8),
              Text(
                'Authorization Verified: Chief Pipeline Controller',
                style: TextStyle(
                  color: AppTheme.tertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'SELECT ACTUATION TARGET & COMMAND',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        // Custom Radio choices
        _buildActionOptionTile(
          value: 'OPEN_MAINLINE',
          title: 'Open 18" Mainline Ball Valve',
          subtitle: 'Check ΔP < 3.0 Bar before opening',
          icon: Icons.lock_open_rounded,
        ),
        _buildActionOptionTile(
          value: 'CLOSE_MAINLINE',
          title: 'Close 18" Mainline Ball Valve',
          subtitle: 'Sectionalize pipeline block',
          icon: Icons.lock_rounded,
        ),
        _buildActionOptionTile(
          value: 'OPEN_BYPASS',
          title: 'Open 2" Equalizing Bypass Valve',
          subtitle: 'Safely equalize upstream and downstream ΔP',
          icon: Icons.compare_arrows_rounded,
        ),
        const SizedBox(height: 14),
        // Live Actuation Progress
        if (_isActuating || _actuationProgress >= 1.0) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Motor Actuation Travel:',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    Text(
                      '${(_actuationProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _actuationProgress,
                    backgroundColor: AppTheme.surfaceCard,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _actuationStageText,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        // Execute Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isActuating ? AppTheme.surfaceContainerHigh : AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            icon: Icon(
              _isActuating ? Icons.hourglass_top_rounded : Icons.power_settings_new_rounded,
              size: 18,
            ),
            label: Text(_isActuating ? 'ACTUATING VALVE MOTOR...' : 'TRANSMIT SCADA COMMAND'),
            onPressed: _isActuating ? null : _executeValveActuation,
          ),
        ),
      ],
    );
  }

  Widget _buildActionOptionTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedAction == value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAction = value;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.15)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryLight : AppTheme.border,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryLight
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
