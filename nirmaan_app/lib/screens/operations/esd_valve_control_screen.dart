// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS — OISD-141 / IEC 61508 / IEC 61511
// ============================================================================

/// Operating status of a Mainline Sectionalizing Valve (SV) actuator
enum ValveActuatorStatus {
  open,
  closed,
  traveling,
  fault,
}

extension ValveActuatorStatusExt on ValveActuatorStatus {
  String get label {
    switch (this) {
      case ValveActuatorStatus.open:
        return 'OPEN (100%)';
      case ValveActuatorStatus.closed:
        return 'CLOSED (0%)';
      case ValveActuatorStatus.traveling:
        return 'TRAVELING';
      case ValveActuatorStatus.fault:
        return 'FAULT / ALARM';
    }
  }

  Color get color {
    switch (this) {
      case ValveActuatorStatus.open:
        return const Color(0xFF4EDEA3); // Emerald
      case ValveActuatorStatus.closed:
        return const Color(0xFFFF5252); // Red
      case ValveActuatorStatus.traveling:
        return const Color(0xFFFFB95F); // Amber
      case ValveActuatorStatus.fault:
        return const Color(0xFFFF3366); // Crimson
    }
  }

  IconData get icon {
    switch (this) {
      case ValveActuatorStatus.open:
        return Icons.lock_open_rounded;
      case ValveActuatorStatus.closed:
        return Icons.lock_rounded;
      case ValveActuatorStatus.traveling:
        return Icons.sync_rounded;
      case ValveActuatorStatus.fault:
        return Icons.warning_amber_rounded;
    }
  }
}

/// Line Break Detection (LBD) rate-of-drop status
enum LbdStatus {
  normal,
  warning,
  tripTriggered,
}

/// Partial Stroke Testing (PST) status
enum PstExecutionState {
  idle,
  running,
  completedSuccess,
  failed,
}

/// Model for a Mainline Sectionalizing Valve Station
class MainlineValve {
  final String id;
  final String name;
  final double chainageKp;
  final String locationTag;
  final int pipeDiameterInch;
  final String pressureClass;
  
  // Real-time telemetry
  ValveActuatorStatus status;
  double positionPercent; // 0.0 to 100.0
  double upstreamPressureBar;
  double downstreamPressureBar;
  double actuatorHydraulicBar;
  double rateOfDropDpDt; // Bar/min (negative is pressure drop)
  LbdStatus lbdStatus;
  double rtuBatteryVoltage;
  
  // SIL-3 Hardware Loop Telemetry
  bool dualSolenoid1Energized;
  bool dualSolenoid2Energized;
  bool limitSwitchOpenZSO;
  bool limitSwitchClosedZSC;
  int cycleCount;
  
  // Bypass Manifold Equalization
  bool bypassValveAOpen;
  bool bypassValveBOpen;
  
  // Partial Stroke Test Diagnostics
  DateTime lastPstDate;
  double lastPstBreakawayTorqueNm;
  double lastPstTravelTimeSec;
  String lastPstResult;
  bool zeroStickingVerified;

  MainlineValve({
    required this.id,
    required this.name,
    required this.chainageKp,
    required this.locationTag,
    this.pipeDiameterInch = 24,
    this.pressureClass = 'ANSI 600# (100 Bar)',
    required this.status,
    required this.positionPercent,
    required this.upstreamPressureBar,
    required this.downstreamPressureBar,
    required this.actuatorHydraulicBar,
    required this.rateOfDropDpDt,
    this.lbdStatus = LbdStatus.normal,
    this.rtuBatteryVoltage = 24.2,
    this.dualSolenoid1Energized = true,
    this.dualSolenoid2Energized = true,
    this.limitSwitchOpenZSO = true,
    this.limitSwitchClosedZSC = false,
    this.cycleCount = 142,
    this.bypassValveAOpen = false,
    this.bypassValveBOpen = false,
    required this.lastPstDate,
    this.lastPstBreakawayTorqueNm = 3840.0,
    this.lastPstTravelTimeSec = 6.4,
    this.lastPstResult = 'PASS (SIL-3)',
    this.zeroStickingVerified = true,
  });

  double get differentialPressureBar =>
      (upstreamPressureBar - downstreamPressureBar).abs();

  bool get isEqualized => differentialPressureBar <= 1.5;
}

/// PST Torque Signature Sample Point
class PstSamplePoint {
  final double strokePercent;
  final double baselineTorqueNm;
  final double actualTorqueNm;
  final double upperEnvelopeNm;
  final double lowerEnvelopeNm;
  final double hydraulicPressureBar;

  const PstSamplePoint({
    required this.strokePercent,
    required this.baselineTorqueNm,
    required this.actualTorqueNm,
    required this.upperEnvelopeNm,
    required this.lowerEnvelopeNm,
    required this.hydraulicPressureBar,
  });
}

/// Cryptographic Tamper-Evident SIS Audit Entry
class SisAuditEntry {
  final String id;
  final DateTime timestamp;
  final String stationId;
  final String actionType;
  final String primaryAuthorizer;
  final String secondaryAuthorizer;
  final String cryptoSha256Hash;
  final String summary;
  final String severity; // 'CRITICAL', 'WARNING', 'INFO'

  SisAuditEntry({
    required this.id,
    required this.timestamp,
    required this.stationId,
    required this.actionType,
    required this.primaryAuthorizer,
    required this.secondaryAuthorizer,
    required this.cryptoSha256Hash,
    required this.summary,
    required this.severity,
  });
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class EsdValveControlScreen extends StatefulWidget {
  const EsdValveControlScreen({super.key});

  @override
  State<EsdValveControlScreen> createState() => _EsdValveControlScreenState();
}

class _EsdValveControlScreenState extends State<EsdValveControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _telemetryTimer;
  Timer? _equalizingTimer;
  Timer? _pstTimer;
  
  // Selected valve station for deep diagnostic & control
  int _selectedValveIndex = 2; // Defaults to SV-03 Sibsagar River Crossing
  
  // Live Simulation Toggle
  bool _isLiveTelemetryActive = true;
  
  // Partial Stroke Test dynamic state
  PstExecutionState _pstState = PstExecutionState.idle;
  double _pstCurrentStroke = 100.0;
  double _pstPeakTorque = 3840.0;
  double _pstElapsedTime = 0.0;
  final List<PstSamplePoint> _pstLiveCurve = [];
  
  // Bypass Equalization in-progress flag
  bool _isEqualizingInProgress = false;

  // Master Roster of Mainline Sectionalizing Valves (SV-01 to SV-08)
  final List<MainlineValve> _valves = [
    MainlineValve(
      id: 'SV-01',
      name: 'Duliajan Terminal',
      chainageKp: 0.0,
      locationTag: 'DLN-KP-000.0',
      status: ValveActuatorStatus.open,
      positionPercent: 100.0,
      upstreamPressureBar: 74.8,
      downstreamPressureBar: 74.5,
      actuatorHydraulicBar: 88.2,
      rateOfDropDpDt: -0.04,
      lastPstDate: DateTime.now().subtract(const Duration(days: 14)),
      lastPstBreakawayTorqueNm: 3750,
      lastPstTravelTimeSec: 6.2,
    ),
    MainlineValve(
      id: 'SV-02',
      name: 'Moran Junction',
      chainageKp: 28.4,
      locationTag: 'MRN-KP-028.4',
      status: ValveActuatorStatus.open,
      positionPercent: 100.0,
      upstreamPressureBar: 72.9,
      downstreamPressureBar: 72.6,
      actuatorHydraulicBar: 87.5,
      rateOfDropDpDt: -0.05,
      lastPstDate: DateTime.now().subtract(const Duration(days: 21)),
      lastPstBreakawayTorqueNm: 3880,
      lastPstTravelTimeSec: 6.5,
    ),
    MainlineValve(
      id: 'SV-03',
      name: 'Sibsagar River Crossing',
      chainageKp: 56.8,
      locationTag: 'SIB-KP-056.8',
      status: ValveActuatorStatus.open,
      positionPercent: 100.0,
      upstreamPressureBar: 70.6,
      downstreamPressureBar: 70.2,
      actuatorHydraulicBar: 89.0,
      rateOfDropDpDt: -0.06,
      lastPstDate: DateTime.now().subtract(const Duration(days: 9)),
      lastPstBreakawayTorqueNm: 3820,
      lastPstTravelTimeSec: 6.4,
    ),
    MainlineValve(
      id: 'SV-04',
      name: 'Jorhat Central Junction',
      chainageKp: 88.2,
      locationTag: 'JRH-KP-088.2',
      status: ValveActuatorStatus.open,
      positionPercent: 100.0,
      upstreamPressureBar: 68.2,
      downstreamPressureBar: 67.8,
      actuatorHydraulicBar: 86.8,
      rateOfDropDpDt: -0.07,
      lastPstDate: DateTime.now().subtract(const Duration(days: 42)),
      lastPstBreakawayTorqueNm: 3960,
      lastPstTravelTimeSec: 6.8,
    ),
    MainlineValve(
      id: 'SV-05',
      name: 'Bokakhat Pumping Station',
      chainageKp: 118.6,
      locationTag: 'BKT-KP-118.6',
      status: ValveActuatorStatus.open,
      positionPercent: 100.0,
      upstreamPressureBar: 65.5,
      downstreamPressureBar: 65.1,
      actuatorHydraulicBar: 85.4,
      rateOfDropDpDt: -0.05,
      lastPstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastPstBreakawayTorqueNm: 4010,
      lastPstTravelTimeSec: 6.9,
    ),
    MainlineValve(
      id: 'SV-06',
      name: 'Kaziranga Eco-Corridor',
      chainageKp: 144.1,
      locationTag: 'KZR-KP-144.1',
      status: ValveActuatorStatus.open,
      positionPercent: 100.0,
      upstreamPressureBar: 63.1,
      downstreamPressureBar: 62.7,
      actuatorHydraulicBar: 91.2,
      rateOfDropDpDt: -0.04,
      lastPstDate: DateTime.now().subtract(const Duration(days: 18)),
      lastPstBreakawayTorqueNm: 3790,
      lastPstTravelTimeSec: 6.3,
    ),
    MainlineValve(
      id: 'SV-07',
      name: 'Jakhalabandha Hub',
      chainageKp: 169.3,
      locationTag: 'JKB-KP-169.3',
      status: ValveActuatorStatus.open,
      positionPercent: 100.0,
      upstreamPressureBar: 60.7,
      downstreamPressureBar: 60.3,
      actuatorHydraulicBar: 86.0,
      rateOfDropDpDt: -0.08,
      lastPstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastPstBreakawayTorqueNm: 3870,
      lastPstTravelTimeSec: 6.6,
    ),
    MainlineValve(
      id: 'SV-08',
      name: 'Nagaon Delivery Terminal',
      chainageKp: 194.5,
      locationTag: 'NGN-KP-194.5',
      status: ValveActuatorStatus.open,
      positionPercent: 100.0,
      upstreamPressureBar: 58.2,
      downstreamPressureBar: 57.9,
      actuatorHydraulicBar: 88.0,
      rateOfDropDpDt: -0.05,
      lastPstDate: DateTime.now().subtract(const Duration(days: 5)),
      lastPstBreakawayTorqueNm: 3910,
      lastPstTravelTimeSec: 6.5,
    ),
  ];

  // Cryptographic Audit Trail Ledger
  final List<SisAuditEntry> _auditTrail = [
    SisAuditEntry(
      id: 'AUD-8831',
      timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 12)),
      stationId: 'SV-03',
      actionType: 'PST_DIAGNOSTIC',
      primaryAuthorizer: 'SCADA Auto-Scheduler',
      secondaryAuthorizer: 'IEC-61511 Engine',
      cryptoSha256Hash: 'a7f920bc49d83e201f893e32b490f84cb71c48e894c25f1947b19dc62a11b402',
      summary: '15% Partial Stroke Test completed. Breakaway torque 3820 Nm (nominal). Zero-sticking verified.',
      severity: 'INFO',
    ),
    SisAuditEntry(
      id: 'AUD-8824',
      timestamp: DateTime.now().subtract(const Duration(hours: 19, minutes: 45)),
      stationId: 'SV-05',
      actionType: 'SOLENOID_PROOF_TEST',
      primaryAuthorizer: 'Er. R. Borah (Field SIC)',
      secondaryAuthorizer: 'Er. S. Kalita (OCC Chief)',
      cryptoSha256Hash: '3c8e9b1097fa523c1044ba90ef818742d45c589078f4439df68128ba741549e3',
      summary: '1oo2D Dual-solenoid pulse test. SOV-1 & SOV-2 de-energize proof verified healthy in 42ms.',
      severity: 'INFO',
    ),
    SisAuditEntry(
      id: 'AUD-8819',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
      stationId: 'SV-06',
      actionType: 'BYPASS_EQUALIZATION',
      primaryAuthorizer: 'Er. N. Sharma (Lead)',
      secondaryAuthorizer: 'SCADA OCC Authority',
      cryptoSha256Hash: 'e698ab90fc338271e847192a5490bc8961724032d1f736209848512f491cba90',
      summary: 'BPV-A opened for upstream/downstream pressure equalizing prior to mainline valve stroke.',
      severity: 'WARNING',
    ),
  ];

  MainlineValve get currentValve => _valves[_selectedValveIndex];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _populateBaselinePstCurve();
    _startLiveTelemetryTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _telemetryTimer?.cancel();
    _equalizingTimer?.cancel();
    _pstTimer?.cancel();
    super.dispose();
  }

  void _populateBaselinePstCurve() {
    _pstLiveCurve.clear();
    // Pre-populate baseline signature for SV-03 Sibsagar
    const List<double> strokes = [100.0, 98.0, 96.0, 93.0, 90.0, 87.0, 85.0, 87.0, 91.0, 95.0, 98.0, 100.0];
    for (final s in strokes) {
      double baseTorque;
      double actualTorque;
      if (s == 100.0) {
        baseTorque = 0.0;
        actualTorque = 0.0;
      } else if (s >= 97.0) {
        // Breakaway peak
        baseTorque = 3600.0 + (100.0 - s) * 120.0;
        actualTorque = 3780.0 + (100.0 - s) * 110.0;
      } else if (s >= 90.0) {
        // Dynamic running torque
        baseTorque = 2450.0 + (s - 90.0) * 80.0;
        actualTorque = 2520.0 + (s - 90.0) * 85.0;
      } else {
        // Deepest stroke at 85%
        baseTorque = 2100.0;
        actualTorque = 2190.0;
      }

      _pstLiveCurve.add(
        PstSamplePoint(
          strokePercent: s,
          baselineTorqueNm: baseTorque,
          actualTorqueNm: actualTorque,
          upperEnvelopeNm: (baseTorque == 0 ? 0 : baseTorque * 1.25) + 300,
          lowerEnvelopeNm: (baseTorque == 0 ? 0 : baseTorque * 0.75),
          hydraulicPressureBar: 89.0 - (100.0 - s) * 0.4,
        ),
      );
    }
  }

  void _startLiveTelemetryTimer() {
    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_isLiveTelemetryActive) return;
      setState(() {
        final random = math.Random();
        for (var v in _valves) {
          if (v.status == ValveActuatorStatus.open) {
            // Realistic subtle process drift
            final drift = (random.nextDouble() - 0.5) * 0.08;
            v.upstreamPressureBar = double.parse(
                (v.upstreamPressureBar + drift).clamp(55.0, 78.0).toStringAsFixed(2));
            v.downstreamPressureBar = double.parse(
                (v.downstreamPressureBar + (drift * 0.95)).clamp(54.0, 77.5).toStringAsFixed(2));
            
            // dP/dt small jitter
            if (v.lbdStatus != LbdStatus.tripTriggered) {
              final dPdtJitter = (random.nextDouble() - 0.5) * 0.02;
              v.rateOfDropDpDt = double.parse(
                  (v.rateOfDropDpDt + dPdtJitter).clamp(-0.25, 0.05).toStringAsFixed(2));
            }

            // Hydraulic reservoir small variation
            v.actuatorHydraulicBar = double.parse(
                (v.actuatorHydraulicBar + (random.nextDouble() - 0.5) * 0.1)
                    .clamp(82.0, 93.0)
                    .toStringAsFixed(1));
          }
        }
      });
    });
  }

  // ==========================================================================
  // LOGIC & ACTIONS: REMOTE TRIP, LBD TRIGGER, PST, EQUALIZING
  // ==========================================================================

  /// Execute Remote Trip on the target valve with cryptographic authorization
  void _executeRemoteTrip(MainlineValve valve, String authorizer1, String authorizer2, String cryptoToken) {
    setState(() {
      valve.status = ValveActuatorStatus.traveling;
      valve.dualSolenoid1Energized = false;
      valve.dualSolenoid2Energized = false;
      valve.limitSwitchOpenZSO = false;
      valve.cycleCount += 1;
    });

    // Compute cryptographic SHA-256 hash
    final rawString = '${valve.id}:${DateTime.now().toIso8601String()}:$authorizer1:$authorizer2:$cryptoToken:SIL3_TRIP';
    final shaHash = sha256.convert(utf8.encode(rawString)).toString();

    _auditTrail.insert(
      0,
      SisAuditEntry(
        id: 'AUD-${math.Random().nextInt(9000) + 1000}',
        timestamp: DateTime.now(),
        stationId: valve.id,
        actionType: 'REMOTE_TRIP',
        primaryAuthorizer: authorizer1,
        secondaryAuthorizer: authorizer2,
        cryptoSha256Hash: shaHash,
        summary: 'SIL-3 Dual-Key cryptographic trip executed. Gas-over-oil actuator vented to fail-safe closed.',
        severity: 'CRITICAL',
      ),
    );

    // Actuator travel animation over 4 seconds
    int steps = 0;
    Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      steps++;
      setState(() {
        valve.positionPercent = math.max(0.0, valve.positionPercent - 7.5);
        valve.downstreamPressureBar = math.max(10.0, valve.downstreamPressureBar - 1.8);
        if (valve.positionPercent <= 0.0 || steps >= 14) {
          valve.positionPercent = 0.0;
          valve.status = ValveActuatorStatus.closed;
          valve.limitSwitchClosedZSC = true;
          t.cancel();
        }
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFFF5252),
        content: Row(
          children: [
            const Icon(Icons.emergency_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'SIL-3 EMERGENCY TRIP: ${valve.id} (${valve.name}) COMMAND INITIATED. SHA-256 Hash logged.',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Inject sudden Line Break Detection (LBD) rupture event to test auto-closure
  void _injectLbdRuptureEvent(MainlineValve valve) {
    setState(() {
      valve.rateOfDropDpDt = -3.85; // Exceeds OISD-141 threshold of 2.0 Bar/min
      valve.lbdStatus = LbdStatus.tripTriggered;
    });

    final rawString = '${valve.id}:LBD_RUPTURE_DPDT_3.85:${DateTime.now().toIso8601String()}';
    final shaHash = sha256.convert(utf8.encode(rawString)).toString();

    _auditTrail.insert(
      0,
      SisAuditEntry(
        id: 'AUD-${math.Random().nextInt(9000) + 1000}',
        timestamp: DateTime.now(),
        stationId: valve.id,
        actionType: 'LBD_AUTO_CLOSURE',
        primaryAuthorizer: 'SCADA LBD Algorithm (SIF-01)',
        secondaryAuthorizer: 'OISD-141 Auto-Safety System',
        cryptoSha256Hash: shaHash,
        summary: 'Line Break Detection rate-of-drop trigger (dP/dt = -3.85 Bar/min > 2.0 Bar/min). Actuator auto-tripped!',
        severity: 'CRITICAL',
      ),
    );

    // Auto-closure execution
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        valve.status = ValveActuatorStatus.traveling;
        valve.dualSolenoid1Energized = false;
        valve.dualSolenoid2Energized = false;
        valve.limitSwitchOpenZSO = false;
      });

      Timer.periodic(const Duration(milliseconds: 250), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          valve.positionPercent = math.max(0.0, valve.positionPercent - 10.0);
          valve.downstreamPressureBar = math.max(5.0, valve.downstreamPressureBar - 2.5);
          if (valve.positionPercent <= 0.0) {
            valve.positionPercent = 0.0;
            valve.status = ValveActuatorStatus.closed;
            valve.limitSwitchClosedZSC = true;
            t.cancel();
          }
        });
      });
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFFF5252), width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 28),
            SizedBox(width: 10),
            Text(
              'LBD AUTO-TRIP INITIATED',
              style: TextStyle(
                color: Color(0xFFFF5252),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Station ${valve.id} (${valve.name}) acoustic & pressure differential sensor registered sudden rate-of-drop:',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.4)),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recorded dP/dt:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text('-3.85 Bar/min', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('OISD-141 Trigger Limit:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text('2.00 Bar/min', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('IEC 61511 Safety Function:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text('SIF-01 Auto-Closure', style: TextStyle(color: Color(0xFF4EDEA3), fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Mainline gas-over-oil hydraulic dump valves tripped. Sectionalizing valve is moving to fail-safe closed to isolate rupture zone.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Acknowledge & Monitor', style: TextStyle(color: AppTheme.primaryLight)),
          ),
        ],
      ),
    );
  }

  /// Reset valve to healthy open state after simulated test
  void _resetValveToOpen(MainlineValve valve) {
    setState(() {
      valve.status = ValveActuatorStatus.open;
      valve.positionPercent = 100.0;
      valve.rateOfDropDpDt = -0.05;
      valve.lbdStatus = LbdStatus.normal;
      valve.dualSolenoid1Energized = true;
      valve.dualSolenoid2Energized = true;
      valve.limitSwitchOpenZSO = true;
      valve.limitSwitchClosedZSC = false;
      valve.downstreamPressureBar = valve.upstreamPressureBar - 0.4;
      valve.bypassValveAOpen = false;
      valve.bypassValveBOpen = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF162347),
        content: Text('Station ${valve.id} reset to NORMAL OPEN (100%) operation.'),
      ),
    );
  }

  /// Simulate high differential pressure condition across the valve to test bypass interlock
  void _simulateHighDifferential(MainlineValve valve) {
    setState(() {
      valve.status = ValveActuatorStatus.closed;
      valve.positionPercent = 0.0;
      valve.limitSwitchOpenZSO = false;
      valve.limitSwitchClosedZSC = true;
      valve.upstreamPressureBar = 74.0;
      valve.downstreamPressureBar = 51.5; // dP = 22.5 Bar (High Differential)
      valve.bypassValveAOpen = false;
      valve.bypassValveBOpen = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFFFB95F),
        content: Text(
          'Simulated High Differential on ${valve.id}: dP = ${(valve.upstreamPressureBar - valve.downstreamPressureBar).abs().toStringAsFixed(1)} Bar. Mainline SV open interlocked!',
          style: const TextStyle(color: Color(0xFF0B1326), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Run Step-by-Step Bypass Equalization Workflow
  void _startBypassEqualization(MainlineValve valve) {
    if (_isEqualizingInProgress) return;

    setState(() {
      _isEqualizingInProgress = true;
      valve.bypassValveAOpen = true; // Open 2" equalizing bypass valve
    });

    _auditTrail.insert(
      0,
      SisAuditEntry(
        id: 'AUD-${math.Random().nextInt(9000) + 1000}',
        timestamp: DateTime.now(),
        stationId: valve.id,
        actionType: 'BYPASS_EQUALIZATION',
        primaryAuthorizer: 'Er. Field Controller',
        secondaryAuthorizer: 'OISD-141 Interlock Manager',
        cryptoSha256Hash: sha256.convert(utf8.encode('${valve.id}:EQUALIZATION_START')).toString(),
        summary: '2" Bypass Valve BPV-A commanded OPEN. Differential pressure bleed initiated.',
        severity: 'INFO',
      ),
    );

    // Gradual equalization timer
    _equalizingTimer = Timer.periodic(const Duration(milliseconds: 400), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        final currentDiff = valve.upstreamPressureBar - valve.downstreamPressureBar;
        if (currentDiff > 0.8) {
          valve.downstreamPressureBar += (currentDiff * 0.18);
        } else {
          valve.downstreamPressureBar = valve.upstreamPressureBar - 0.4;
          _isEqualizingInProgress = false;
          t.cancel();

          // Log completion
          _auditTrail.insert(
            0,
            SisAuditEntry(
              id: 'AUD-${math.Random().nextInt(9000) + 1000}',
              timestamp: DateTime.now(),
              stationId: valve.id,
              actionType: 'INTERLOCK_CLEARED',
              primaryAuthorizer: 'Pressure Equalizer Algorithm',
              secondaryAuthorizer: 'SCADA OCC Authority',
              cryptoSha256Hash: sha256.convert(utf8.encode('${valve.id}:EQUALIZED_LE_1.5BAR')).toString(),
              summary: 'Differential pressure <= 1.5 Bar achieved. OISD-141 interlock cleared: Mainline SV OPEN enabled.',
              severity: 'INFO',
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF4EDEA3),
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF0B1326)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Equalization Complete (dP <= 1.5 Bar). Mainline SV Open Interlock CLEARED!',
                      style: TextStyle(color: Color(0xFF0B1326), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      });
    });
  }

  /// Open Mainline SV after equalization interlock cleared
  void _openMainlineValveAfterEqualization(MainlineValve valve) {
    if (!valve.isEqualized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFFF5252),
          content: Text('CANNOT OPEN: dP > 1.5 Bar! OISD-141 safety interlock prohibits opening.'),
        ),
      );
      return;
    }

    setState(() {
      valve.status = ValveActuatorStatus.traveling;
      valve.dualSolenoid1Energized = true;
      valve.dualSolenoid2Energized = true;
      valve.limitSwitchClosedZSC = false;
    });

    Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        valve.positionPercent = math.min(100.0, valve.positionPercent + 10.0);
        if (valve.positionPercent >= 100.0) {
          valve.positionPercent = 100.0;
          valve.status = ValveActuatorStatus.open;
          valve.limitSwitchOpenZSO = true;
          valve.bypassValveAOpen = false; // Isolate bypass line once mainline SV is open
          valve.bypassValveBOpen = false;
          t.cancel();
        }
      });
    });
  }

  /// Run Automated 15% Partial Stroke Test (PST) Diagnostic
  void _initiatePstDiagnostic(MainlineValve valve) {
    if (_pstState == PstExecutionState.running) return;

    setState(() {
      _pstState = PstExecutionState.running;
      _pstCurrentStroke = 100.0;
      _pstElapsedTime = 0.0;
      _pstPeakTorque = 3840.0;
      _pstLiveCurve.clear();
    });

    final List<double> testStrokes = [
      100.0, 98.0, 96.0, 94.0, 91.0, 88.0, 85.0, 88.0, 92.0, 96.0, 99.0, 100.0
    ];
    int stepIndex = 0;

    _pstTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (stepIndex >= testStrokes.length) {
        t.cancel();
        setState(() {
          _pstState = PstExecutionState.completedSuccess;
          _pstCurrentStroke = 100.0;
          valve.lastPstDate = DateTime.now();
          valve.lastPstBreakawayTorqueNm = _pstPeakTorque;
          valve.lastPstTravelTimeSec = _pstElapsedTime;
          valve.lastPstResult = 'PASS (SIL-3)';
          valve.zeroStickingVerified = true;
        });

        _auditTrail.insert(
          0,
          SisAuditEntry(
            id: 'AUD-${math.Random().nextInt(9000) + 1000}',
            timestamp: DateTime.now(),
            stationId: valve.id,
            actionType: 'PST_DIAGNOSTIC',
            primaryAuthorizer: 'Automated PST Subsystem',
            secondaryAuthorizer: 'IEC-61511 Safety Controller',
            cryptoSha256Hash: sha256.convert(utf8.encode('${valve.id}:PST_PASS:${DateTime.now().toIso8601String()}')).toString(),
            summary: '15% Partial Stroke Test PASSED. Peak Breakaway: ${_pstPeakTorque.toStringAsFixed(0)} Nm (< 4500 Nm limit). Zero-sticking verified.',
            severity: 'INFO',
          ),
        );
        return;
      }

      final currentS = testStrokes[stepIndex];
      stepIndex++;

      setState(() {
        _pstCurrentStroke = currentS;
        _pstElapsedTime = double.parse((_pstElapsedTime + 0.5).toStringAsFixed(1));

        double baseTorque;
        double actualTorque;
        if (currentS == 100.0) {
          baseTorque = 0.0;
          actualTorque = 0.0;
        } else if (currentS >= 97.0) {
          baseTorque = 3600.0 + (100.0 - currentS) * 120.0;
          actualTorque = 3780.0 + (100.0 - currentS) * 115.0;
          if (actualTorque > _pstPeakTorque) _pstPeakTorque = actualTorque;
        } else if (currentS >= 90.0) {
          baseTorque = 2450.0 + (currentS - 90.0) * 80.0;
          actualTorque = 2520.0 + (currentS - 90.0) * 85.0;
        } else {
          baseTorque = 2100.0;
          actualTorque = 2190.0;
        }

        _pstLiveCurve.add(
          PstSamplePoint(
            strokePercent: currentS,
            baselineTorqueNm: baseTorque,
            actualTorqueNm: actualTorque,
            upperEnvelopeNm: (baseTorque == 0 ? 0 : baseTorque * 1.25) + 300,
            lowerEnvelopeNm: (baseTorque == 0 ? 0 : baseTorque * 0.75),
            hydraulicPressureBar: valve.actuatorHydraulicBar - (100.0 - currentS) * 0.35,
          ),
        );
      });
    });
  }

  // ==========================================================================
  // DUAL-KEY CRYPTOGRAPHIC AUTHORIZATION DIALOG
  // ==========================================================================

  void _showDualKeyTripDialog(MainlineValve valve) {
    final keyAController = TextEditingController(text: 'SIC-DLN-8842');
    final keyBController = TextEditingController(text: 'OCC-CTRL-9104');
    final keyNameAController = TextEditingController(text: 'Er. R. Borah (Field SIC)');
    final keyNameBController = TextEditingController(text: 'Er. S. Kalita (Chief OCC)');
    bool ptwChecked = true;
    bool zoneClearChecked = true;
    bool custodyNotified = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setSheetState) {
            final allChecked = ptwChecked && zoneClearChecked && custodyNotified;
            final canArm = allChecked &&
                keyAController.text.isNotEmpty &&
                keyBController.text.isNotEmpty;

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF111C38),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFFFF5252), width: 3)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Hazard Striping
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_rounded, color: Color(0xFFFF5252), size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SIL-3 DUAL-KEY REMOTE TRIP AUTHORIZATION',
                                  style: TextStyle(
                                    color: Color(0xFFFF5252),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'IEC 61508 / IEC 61511 Cryptographic Actuator Scram — ${valve.id} (${valve.name})',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5252),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'HAZARD CLASS 1',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Key A Card: Shift In-Charge (Field Key)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.vpn_key_rounded, color: Color(0xFFFFB95F), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'KEY A: SHIFT IN-CHARGE (FIELD VERIFICATION)',
                                style: TextStyle(
                                  color: Color(0xFFFFB95F),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: keyNameAController,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'Authorized Engineer Name & Designation',
                              labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: keyAController,
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Field Hardware Key Token / PIN',
                              labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              prefixIcon: Icon(Icons.fingerprint_rounded, size: 18),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Key B Card: OCC Chief Controller (Remote Key)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'KEY B: CHIEF OCC PIPELINE CONTROLLER',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: keyNameBController,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'OCC Authority & Duty Officer',
                              labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: keyBController,
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'OCC SCADA Cryptographic Key Token',
                              labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              prefixIcon: Icon(Icons.token_rounded, size: 18),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Safety Checklist
                    const Text(
                      'MANDATORY PRE-TRIP VERIFICATION CHECKLIST',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      value: ptwChecked,
                      onChanged: (v) => setSheetState(() => ptwChecked = v ?? false),
                      title: const Text('Live PTW hot-work suspended & linepack flow adjusted', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF0284C7),
                    ),
                    CheckboxListTile(
                      value: zoneClearChecked,
                      onChanged: (v) => setSheetState(() => zoneClearChecked = v ?? false),
                      title: const Text('Valve pit perimeter & blast radius verified clear of personnel', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF0284C7),
                    ),
                    CheckboxListTile(
                      value: custodyNotified,
                      onChanged: (v) => setSheetState(() => custodyNotified = v ?? false),
                      title: const Text('Custody transfer off-takers notified of section emergency isolation', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF0284C7),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancel & Abort', style: TextStyle(color: AppTheme.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: canArm
                                ? () {
                                    Navigator.pop(dialogCtx);
                                    _executeRemoteTrip(
                                      valve,
                                      keyNameAController.text,
                                      keyNameBController.text,
                                      '${keyAController.text}-${keyBController.text}',
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 18),
                            label: const Text('AUTHENTICATE & TRIP SV'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5252),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFFF5252).withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================================
  // UI BUILD & SECTIONS
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCorridorHeaderStrip(),
          _buildStationSelectorBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRosterTab(),
                _buildDualKeyEsdTab(),
                _buildPstTab(),
                _buildBypassEqualizingTab(),
                _buildComplianceAuditTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SCADA Mainline SV & SIL-3 ESD',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF0284C7)),
                ),
                child: const Text(
                  'IEC 61508 SIL-3',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'OISD-141 / IEC 61511 Safety Instrumented Sectionalizing Valve Control',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: _isLiveTelemetryActive ? 'Pause Telemetry' : 'Resume Telemetry',
          icon: Icon(
            _isLiveTelemetryActive ? Icons.sensors_rounded : Icons.sensors_off_rounded,
            color: _isLiveTelemetryActive ? const Color(0xFF4EDEA3) : AppTheme.textMuted,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _isLiveTelemetryActive = !_isLiveTelemetryActive;
            });
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textPrimary),
          color: AppTheme.surfaceCard,
          onSelected: (val) {
            if (val == 'reset_all') {
              setState(() {
                for (var v in _valves) {
                  _resetValveToOpen(v);
                }
              });
            } else if (val == 'sim_rup') {
              _injectLbdRuptureEvent(currentValve);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'sim_rup',
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFFFF5252), size: 18),
                  SizedBox(width: 8),
                  Text('Simulate Rupture (LBD Trigger)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reset_all',
              child: Row(
                children: [
                  Icon(Icons.restore_rounded, color: Color(0xFF4EDEA3), size: 18),
                  SizedBox(width: 8),
                  Text('Reset All Valves to Normal Open', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Top Corridor Pipeline Overview Banner with Summary SIS Metrics
  Widget _buildCorridorHeaderStrip() {
    int openCount = _valves.where((v) => v.status == ValveActuatorStatus.open).length;
    int travelingCount = _valves.where((v) => v.status == ValveActuatorStatus.traveling).length;
    int closedCount = _valves.where((v) => v.status == ValveActuatorStatus.closed).length;
    int faultCount = _valves.where((v) => v.status == ValveActuatorStatus.fault).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1833),
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('SV ROSTER', '8 Stations', const Color(0xFF38BDF8), Icons.tune_rounded),
                _buildMiniStat('OPEN (100%)', '$openCount / 8', const Color(0xFF4EDEA3), Icons.lock_open_rounded),
                _buildMiniStat('TRAVELING', '$travelingCount', const Color(0xFFFFB95F), Icons.sync_rounded),
                _buildMiniStat('CLOSED / TRIP', '$closedCount', closedCount > 0 ? const Color(0xFFFF5252) : AppTheme.textMuted, Icons.lock_rounded),
                _buildMiniStat('SIS FAULT', '$faultCount', faultCount > 0 ? const Color(0xFFFF3366) : const Color(0xFF4EDEA3), Icons.verified_user_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w700)),
            Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }

  /// Station selector horizontal pill row (SV-01 to SV-08)
  Widget _buildStationSelectorBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppTheme.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _valves.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, index) {
          final valve = _valves[index];
          final isSelected = index == _selectedValveIndex;
          final isClosedOrTrip = valve.status == ValveActuatorStatus.closed;

          Color badgeColor;
          if (isClosedOrTrip) {
            badgeColor = const Color(0xFFFF5252);
          } else if (valve.status == ValveActuatorStatus.traveling) {
            badgeColor = const Color(0xFFFFB95F);
          } else {
            badgeColor = const Color(0xFF4EDEA3);
          }

          return InkWell(
            onTap: () {
              setState(() {
                _selectedValveIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0284C7).withOpacity(0.25) : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFF38BDF8) : AppTheme.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badgeColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    valve.id,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'KP ${valve.chainageKp.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF38BDF8) : AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF38BDF8),
        indicatorWeight: 3,
        labelColor: const Color(0xFF38BDF8),
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'SV Roster'),
          Tab(icon: Icon(Icons.vpn_key_rounded, size: 18), text: 'Dual-Key ESD'),
          Tab(icon: Icon(Icons.speed_rounded, size: 18), text: 'PST Diagnostic'),
          Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Bypass Equalizing'),
          Tab(icon: Icon(Icons.fact_check_rounded, size: 18), text: 'SIS Compliance'),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: SV ROSTER (OISD-141 MAINLINE VALVES OVERVIEW)
  // ==========================================================================

  Widget _buildRosterTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pipeline Corridor Flow Schematic
        _buildPipelineCorridorMapWidget(),
        const SizedBox(height: 16),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MAINLINE SECTIONALIZING VALVES (SV-01 TO SV-08)',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Target Station: ${currentValve.id} (${currentValve.name})',
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Cards for each valve
        for (int i = 0; i < _valves.length; i++)
          _buildValveCard(_valves[i], i == _selectedValveIndex, i),
      ],
    );
  }

  Widget _buildPipelineCorridorMapWidget() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.route_rounded, color: Color(0xFF38BDF8), size: 18),
                  SizedBox(width: 8),
                  Text(
                    '194.5 KM DULIAJAN - NAGAON MAINLINE CORRIDOR',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'OISD-141 Sectionalizing Spacing <= 30 KM',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Flow corridor visual
          SizedBox(
            height: 52,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final double totalWidth = constraints.maxWidth;
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Pipe Centerline
                    Container(
                      height: 6,
                      width: totalWidth,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF4EDEA3), Color(0xFF0284C7)],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    // SV Nodes
                    for (int i = 0; i < _valves.length; i++) ...[
                      Positioned(
                        left: (i / (_valves.length - 1)) * (totalWidth - 32),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedValveIndex = i;
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _valves[i].status.color,
                                  border: Border.all(
                                    color: i == _selectedValveIndex ? Colors.white : Colors.black87,
                                    width: i == _selectedValveIndex ? 2.5 : 1.5,
                                  ),
                                  boxShadow: [
                                    if (i == _selectedValveIndex)
                                      BoxShadow(
                                        color: _valves[i].status.color.withOpacity(0.6),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _valves[i].id,
                                style: TextStyle(
                                  color: i == _selectedValveIndex ? const Color(0xFF38BDF8) : AppTheme.textSecondary,
                                  fontSize: 9,
                                  fontWeight: i == _selectedValveIndex ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Duliajan KP 0.0', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              Text('Natural Gas Transmission Direction ➔', style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 10, fontWeight: FontWeight.w600)),
              Text('Nagaon KP 194.5', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValveCard(MainlineValve valve, bool isSelected, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF192850) : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF38BDF8) : AppTheme.border,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedValveIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top line: ID, Name, KP, Status Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF0284C7)),
                    ),
                    child: Text(
                      valve.id,
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          valve.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'KP ${valve.chainageKp.toStringAsFixed(1)} • ${valve.pipeDiameterInch}" ANSI 600# • Gas-Over-Oil Actuator',
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
                      color: valve.status.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: valve.status.color),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(valve.status.icon, color: valve.status.color, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          valve.status.label,
                          style: TextStyle(
                            color: valve.status.color,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Telemetry Grid
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTelemetryItem(
                      'P_UPSTREAM',
                      '${valve.upstreamPressureBar.toStringAsFixed(1)} Bar',
                      const Color(0xFF38BDF8),
                    ),
                    _buildTelemetryItem(
                      'P_DOWNSTREAM',
                      '${valve.downstreamPressureBar.toStringAsFixed(1)} Bar',
                      const Color(0xFF38BDF8),
                    ),
                    _buildTelemetryItem(
                      'DIFFERENTIAL (dP)',
                      '${valve.differentialPressureBar.toStringAsFixed(2)} Bar',
                      valve.isEqualized ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252),
                    ),
                    _buildTelemetryItem(
                      'RATE dP/dt',
                      '${valve.rateOfDropDpDt > 0 ? "+" : ""}${valve.rateOfDropDpDt.toStringAsFixed(2)} B/m',
                      valve.rateOfDropDpDt.abs() > 2.0
                          ? const Color(0xFFFF5252)
                          : (valve.rateOfDropDpDt.abs() > 1.0
                              ? const Color(0xFFFFB95F)
                              : const Color(0xFF4EDEA3)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Bottom Info: Actuator Hyd, Solenoids, PST status, Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop_rounded, size: 14, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 4),
                      Text(
                        'Hyd: ${valve.actuatorHydraulicBar} Bar',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.electrical_services_rounded, size: 14, color: Color(0xFF4EDEA3)),
                      const SizedBox(width: 4),
                      Text(
                        'SIL-3 SOV: 1oo2D OK',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedValveIndex = index;
                            _tabController.animateTo(2); // Jump to PST
                          });
                        },
                        icon: const Icon(Icons.speed_rounded, size: 14, color: Color(0xFF38BDF8)),
                        label: const Text('PST Diagnostic', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        onPressed: () => _showDualKeyTripDialog(valve),
                        icon: const Icon(Icons.power_settings_new_rounded, size: 14, color: Colors.white),
                        label: const Text('TRIP SV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5252),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 2: DUAL-KEY REMOTE TRIP & LINE BREAK DETECTION (LBD)
  // ==========================================================================

  Widget _buildDualKeyEsdTab() {
    final valve = currentValve;
    final isLbdTriggered = valve.lbdStatus == LbdStatus.tripTriggered || valve.rateOfDropDpDt.abs() > 2.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Target Station Quick Card
        _buildTargetStationHeader(valve),
        const SizedBox(height: 16),

        // Line Break Detection (LBD) Rate-of-Drop Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isLbdTriggered
                ? const Color(0xFFFF5252).withOpacity(0.15)
                : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLbdTriggered ? const Color(0xFFFF5252) : AppTheme.border,
              width: isLbdTriggered ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isLbdTriggered ? Icons.warning_amber_rounded : Icons.show_chart_rounded,
                        color: isLbdTriggered ? const Color(0xFFFF5252) : const Color(0xFF38BDF8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LINE BREAK DETECTION (LBD) RATE-OF-DROP',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLbdTriggered
                          ? const Color(0xFFFF5252)
                          : const Color(0xFF4EDEA3).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isLbdTriggered ? 'TRIGGERED: AUTO-CLOSURE' : 'MONITORING: NORMAL',
                      style: TextStyle(
                        color: isLbdTriggered ? Colors.white : const Color(0xFF4EDEA3),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'OISD-141 Clause 8.4 mandates automated closure of Sectionalizing Valves whenever SCADA acoustic or differential pressure rate of drop exceeds 2.0 Bar/minute.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 14),

              // Gauge bar for rate of drop
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Current Rate-of-Drop (dP/dt):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            Text(
                              '${valve.rateOfDropDpDt.toStringAsFixed(2)} Bar/min',
                              style: TextStyle(
                                color: isLbdTriggered ? const Color(0xFFFF5252) : const Color(0xFF38BDF8),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (valve.rateOfDropDpDt.abs() / 4.0).clamp(0.0, 1.0),
                            backgroundColor: const Color(0xFF1E2E5C),
                            color: isLbdTriggered ? const Color(0xFFFF5252) : const Color(0xFF38BDF8),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('0.0 Bar/min', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                            Text('2.0 Bar/min (Trip Limit)', style: TextStyle(color: Color(0xFFFFB95F), fontSize: 9, fontWeight: FontWeight.bold)),
                            Text('4.0 Bar/min', style: TextStyle(color: Color(0xFFFF5252), fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _injectLbdRuptureEvent(valve),
                    icon: const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                    label: const Text('Test Rupture', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5252),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dual-Key Cryptographic Authorization Panel
        Container(
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
                  Icon(Icons.lock_person_rounded, color: Color(0xFFFFB95F), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'DUAL-KEY CRYPTOGRAPHIC TRIP PROTOCOL',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Per IEC 61508 / IEC 61511 SIL-3 Safety Integrity Levels, a remote manual trip of an active hydrocarbon transmission mainline valve requires two independent crypto tokens before the actuator hydraulic dump solenoid is de-energized.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 16),

              // Visual Dual-Key Steps
              Row(
                children: [
                  Expanded(
                    child: _buildKeyStatusCard(
                      'KEY A: FIELD SIC',
                      'Er. R. Borah',
                      'SIC-DLN-8842',
                      'TOKEN READY',
                      const Color(0xFF4EDEA3),
                      Icons.vpn_key_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKeyStatusCard(
                      'KEY B: OCC CONTROLLER',
                      'Er. S. Kalita',
                      'OCC-CTRL-9104',
                      'TOKEN READY',
                      const Color(0xFF38BDF8),
                      Icons.admin_panel_settings_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showDualKeyTripDialog(valve),
                      icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 18),
                      label: const Text('PROMPT DUAL-KEY TRIP AUTHORIZATION'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5252),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  if (valve.status == ValveActuatorStatus.closed) ...[
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => _resetValveToOpen(valve),
                      icon: const Icon(Icons.restore_rounded, color: Color(0xFF4EDEA3), size: 18),
                      label: const Text('Reset Open', style: TextStyle(color: Color(0xFF4EDEA3))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4EDEA3)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // SIL-3 Solenoid Loop Architecture
        Container(
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
                  Icon(Icons.memory_rounded, color: Color(0xFF38BDF8), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'SIL-3 1oo2D ACTUATOR SOLENOID TRIP LOOP',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildLoopComponent(
                      'SOV-1 (Primary)',
                      valve.dualSolenoid1Energized ? 'ENERGIZED / HEALTHY' : 'DE-ENERGIZED (TRIPPED)',
                      valve.dualSolenoid1Energized ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252),
                      Icons.flash_on_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildLoopComponent(
                      'SOV-2 (Secondary)',
                      valve.dualSolenoid2Energized ? 'ENERGIZED / HEALTHY' : 'DE-ENERGIZED (TRIPPED)',
                      valve.dualSolenoid2Energized ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252),
                      Icons.flash_on_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildLoopComponent(
                      'Logic Solver',
                      '1oo2D Active',
                      const Color(0xFF38BDF8),
                      Icons.device_hub_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyStatusCard(String title, String user, String token, String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Text(user, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
          Text('Key: $token', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 4),
              Text(status, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoopComponent(String title, String state, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            state,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: PARTIAL STROKE TESTING (PST) & TORQUE SIGNATURE CURVE
  // ==========================================================================

  Widget _buildPstTab() {
    final valve = currentValve;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTargetStationHeader(valve),
        const SizedBox(height: 16),

        // PST Controller Card
        Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed_rounded, color: Color(0xFF38BDF8), size: 20),
                      SizedBox(width: 8),
                      Text(
                        '15% PARTIAL STROKE TEST (PST) DIAGNOSTIC',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _pstState == PstExecutionState.running
                          ? const Color(0xFFFFB95F).withOpacity(0.2)
                          : const Color(0xFF4EDEA3).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _pstState == PstExecutionState.running ? 'DIAGNOSTIC RUNNING' : 'SIL-3 READY',
                      style: TextStyle(
                        color: _pstState == PstExecutionState.running
                            ? const Color(0xFFFFB95F)
                            : const Color(0xFF4EDEA3),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Automated 15% valve closure stroke (100% ➔ 85% ➔ 100%) tests valve shaft breakaway torque and verifies zero-sticking without halting natural gas transmission throughput.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 14),

              // Progress Bar during PST
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Actuator Stroke Position:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            Text(
                              '${_pstCurrentStroke.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (100.0 - _pstCurrentStroke) / 15.0, // 0.0 at 100%, 1.0 at 85%
                            backgroundColor: const Color(0xFF1E2E5C),
                            color: const Color(0xFF38BDF8),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: _pstState == PstExecutionState.running
                        ? null
                        : () => _initiatePstDiagnostic(valve),
                    icon: _pstState == PstExecutionState.running
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                    label: Text(
                      _pstState == PstExecutionState.running ? 'Testing...' : 'Execute PST',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Interactive FL Chart: Torque Signature Curve
        Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'VALVE TORQUE SIGNATURE CURVE (Nm vs STROKE %)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4EDEA3).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Zero-Sticking Verified',
                      style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Comparing dynamic breakaway & running torque against baseline envelope to detect stem galling, seal sticking, or hydraulic pressure loss.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 16),

              // Chart
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFF1E2E5C), strokeWidth: 1),
                      getDrawingVerticalLine: (value) => const FlLine(color: Color(0xFF1E2E5C), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (val, meta) => Text(
                            '${val.toInt()}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (val, meta) => Text(
                            '${val.toInt()}%',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: AppTheme.border),
                    ),
                    minX: 84,
                    maxX: 100,
                    minY: 0,
                    maxY: 5200,
                    lineBarsData: [
                      // Upper Warning Envelope
                      LineChartBarData(
                        spots: _pstLiveCurve
                            .map((p) => FlSpot(p.strokePercent, p.upperEnvelopeNm))
                            .toList(),
                        isCurved: true,
                        color: const Color(0xFFFF5252).withOpacity(0.5),
                        barWidth: 1.5,
                        dashArray: [4, 4],
                        dotData: const FlDotData(show: false),
                      ),
                      // Baseline Nominal
                      LineChartBarData(
                        spots: _pstLiveCurve
                            .map((p) => FlSpot(p.strokePercent, p.baselineTorqueNm))
                            .toList(),
                        isCurved: true,
                        color: const Color(0xFF4EDEA3).withOpacity(0.7),
                        barWidth: 2,
                        dashArray: [3, 2],
                        dotData: const FlDotData(show: false),
                      ),
                      // Live Actual Measured Torque
                      LineChartBarData(
                        spots: _pstLiveCurve
                            .map((p) => FlSpot(p.strokePercent, p.actualTorqueNm))
                            .toList(),
                        isCurved: true,
                        color: const Color(0xFF38BDF8),
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Legend
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ChartLegendItem(label: 'Live PST Torque', color: Color(0xFF38BDF8)),
                  SizedBox(width: 14),
                  _ChartLegendItem(label: 'Baseline Nominal', color: Color(0xFF4EDEA3), isDashed: true),
                  SizedBox(width: 14),
                  _ChartLegendItem(label: 'Upper Limit Envelope', color: Color(0xFFFF5252), isDashed: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // PST Diagnostics Metric Grid
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PST PERFORMANCE CRITERIA & DIAGNOSTICS REPORT',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDiagnosticTile(
                      'Breakaway Torque',
                      '${valve.lastPstBreakawayTorqueNm.toStringAsFixed(0)} Nm',
                      '< 4500 Nm Limit',
                      const Color(0xFF4EDEA3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDiagnosticTile(
                      'PST Travel Time',
                      '${valve.lastPstTravelTimeSec} s',
                      '< 8.0 s Limit',
                      const Color(0xFF4EDEA3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDiagnosticTile(
                      'Stem Sticking',
                      valve.zeroStickingVerified ? 'ZERO STICK' : 'WARNING',
                      'OISD-141 Compliant',
                      const Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticTile(String title, String value, String limit, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(limit, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: BYPASS EQUALIZING MANIFOLD & DIFFERENTIAL INTERLOCK
  // ==========================================================================

  Widget _buildBypassEqualizingTab() {
    final valve = currentValve;
    final diff = valve.differentialPressureBar;
    final isLocked = !valve.isEqualized;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTargetStationHeader(valve),
        const SizedBox(height: 16),

        // Equalization Status Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isLocked ? const Color(0xFFFF5252).withOpacity(0.12) : const Color(0xFF4EDEA3).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isLocked ? const Color(0xFFFF5252) : const Color(0xFF4EDEA3)),
          ),
          child: Row(
            children: [
              Icon(
                isLocked ? Icons.lock_clock_rounded : Icons.check_circle_rounded,
                color: isLocked ? const Color(0xFFFF5252) : const Color(0xFF4EDEA3),
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLocked
                          ? 'OISD-141 INTERLOCK ACTIVE: MAINLINE OPEN LOCKED'
                          : 'INTERLOCK CLEARED: SAFE TO OPEN MAINLINE SV',
                      style: TextStyle(
                        color: isLocked ? const Color(0xFFFF5252) : const Color(0xFF4EDEA3),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLocked
                          ? 'Differential across valve is ${diff.toStringAsFixed(2)} Bar (> 1.5 Bar limit). Open bypass equalizing line first to prevent seat damage & actuator cavitation.'
                          : 'Differential across valve is ${diff.toStringAsFixed(2)} Bar (<= 1.5 Bar safe limit). Mainline SV equalized and ready for stroke.',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // P&ID Schematic Widget
        _buildPidEqualizingSchematicWidget(valve),
        const SizedBox(height: 16),

        // Interactive Manifold Control Panel
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BYPASS MANIFOLD WORKFLOW CONTROLS',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isEqualizingInProgress
                          ? null
                          : () => _startBypassEqualization(valve),
                      icon: _isEqualizingInProgress
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.tune_rounded, size: 16, color: Colors.white),
                      label: Text(_isEqualizingInProgress ? 'Equalizing...' : 'Open 2" Bypass (BPV-A)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLocked ? null : () => _openMainlineValveAfterEqualization(valve),
                      icon: const Icon(Icons.lock_open_rounded, size: 16, color: Colors.white),
                      label: const Text('Open Mainline SV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4EDEA3),
                        foregroundColor: const Color(0xFF0B1326),
                        disabledBackgroundColor: const Color(0xFF4EDEA3).withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _simulateHighDifferential(valve),
                icon: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFFFB95F)),
                label: const Text('Simulate High Differential Scenario (dP = 22.5 Bar)', style: TextStyle(color: Color(0xFFFFB95F))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFB95F)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPidEqualizingSchematicWidget(MainlineValve valve) {
    final diff = valve.differentialPressureBar;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1124),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'P&ID SCHEMATIC: MAINLINE SV & BYPASS EQUALIZER',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'dP = ${diff.toStringAsFixed(2)} Bar',
                style: TextStyle(
                  color: valve.isEqualized ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // P&ID Diagram visual
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1730),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E2E5C)),
            ),
            child: Column(
              children: [
                // Top Bypass Pipe
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFF38BDF8), thickness: 2)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: valve.bypassValveAOpen ? const Color(0xFF4EDEA3) : const Color(0xFF1E2E5C),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'BPV-A: ${valve.bypassValveAOpen ? "OPEN (Equalizing)" : "CLOSED"}',
                        style: TextStyle(
                          color: valve.bypassValveAOpen ? const Color(0xFF0B1326) : AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFF38BDF8), thickness: 2)),
                  ],
                ),
                const SizedBox(height: 16),

                // Mainline 24" Pipe with Valve
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Upstream side
                    Column(
                      children: [
                        const Text('UPSTREAM (P_up)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                        Text('${valve.upstreamPressureBar} Bar', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const Expanded(child: Divider(color: Color(0xFF0284C7), thickness: 6)),
                    // Main SV Valve symbol
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: valve.status.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: valve.status.color, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(valve.status.icon, color: valve.status.color, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            valve.id,
                            style: TextStyle(color: valve.status.color, fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                          Text(
                            valve.status.label,
                            style: TextStyle(color: valve.status.color, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFF0284C7), thickness: 6)),
                    // Downstream side
                    Column(
                      children: [
                        const Text('DOWNSTREAM (P_down)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                        Text('${valve.downstreamPressureBar.toStringAsFixed(1)} Bar', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
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

  // ==========================================================================
  // TAB 5: OISD / IEC 61511 COMPLIANCE & CRYPTOGRAPHIC AUDIT TRAIL
  // ==========================================================================

  Widget _buildComplianceAuditTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // SIL-3 SIS Health Summary Card
        Container(
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
                  Icon(Icons.verified_rounded, color: Color(0xFF4EDEA3), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'IEC 61508 / IEC 61511 SIL-3 SYSTEM ARCHITECTURE',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSisStat('PFD_avg Target', '1.42 × 10⁻⁴', '< 10⁻³ (SIL-3)', const Color(0xFF4EDEA3))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSisStat('Safe Failure Frac (SFF)', '99.1%', '> 99% Req', const Color(0xFF38BDF8))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSisStat('Proof Test Interval', '365 Days', 'PST Credit Active', const Color(0xFFFFB95F))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section Title
        const Text(
          'CRYPTOGRAPHIC TAMPER-EVIDENT SIS AUDIT TRAIL',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        // Audit Trail List
        for (final entry in _auditTrail)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: entry.severity == 'CRITICAL'
                    ? const Color(0xFFFF5252).withOpacity(0.6)
                    : AppTheme.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.stationId,
                            style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.actionType,
                          style: TextStyle(
                            color: entry.severity == 'CRITICAL' ? const Color(0xFFFF5252) : AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      DateFormat('dd MMM HH:mm:ss').format(entry.timestamp),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(entry.summary, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1326),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint_rounded, size: 12, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'SHA-256: ${entry.cryptoSha256Hash}',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontFamily: 'monospace',
                            fontSize: 9,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSisStat(String title, String val, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }

  // ==========================================================================
  // HELPER WIDGETS
  // ==========================================================================

  Widget _buildTargetStationHeader(MainlineValve valve) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  valve.id,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(valve.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${valve.locationTag} • KP ${valve.chainageKp.toStringAsFixed(1)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: valve.status.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: valve.status.color),
            ),
            child: Text(
              valve.status.label,
              style: TextStyle(color: valve.status.color, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDashed;

  const _ChartLegendItem({
    required this.label,
    required this.color,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}
