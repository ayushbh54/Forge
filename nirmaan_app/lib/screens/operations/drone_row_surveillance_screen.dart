import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS — DRONE ROW SURVEILLANCE & STATUTORY PROTECTION
// ============================================================================

/// Buffer zone classifications under Petroleum & Minerals Pipelines Act 1957
enum BufferZone {
  coreHazard, // 0 - 5m: Immediate prohibited zone, acute structural danger
  innerStatutory, // 5 - 15m: Statutory RoW zone, strict no-dig / no-build
  outerBuffer, // 15 - 30m: Statutory buffer zone, prior Oil India NOC required
  externalClear, // > 30m: Permitted civil activity zone outside statutory RoW
}

extension BufferZoneExt on BufferZone {
  String get displayName {
    switch (this) {
      case BufferZone.coreHazard:
        return 'Core Hazard Zone (0-5m)';
      case BufferZone.innerStatutory:
        return 'Statutory RoW (5-15m)';
      case BufferZone.outerBuffer:
        return 'Regulated Buffer (15-30m)';
      case BufferZone.externalClear:
        return 'Clear Zone (>30m)';
    }
  }

  Color get color {
    switch (this) {
      case BufferZone.coreHazard:
        return const Color(0xFFEF4444); // Critical Red
      case BufferZone.innerStatutory:
        return const Color(0xFFF97316); // High Orange
      case BufferZone.outerBuffer:
        return const Color(0xFFFFB95F); // Amber Warning
      case BufferZone.externalClear:
        return const Color(0xFF4EDEA3); // Safe Green
    }
  }

  String get statuteClause {
    switch (this) {
      case BufferZone.coreHazard:
        return 'P&MP Act 1957 Sec 15(1) — Direct Pipeline Damage Threat';
      case BufferZone.innerStatutory:
        return 'P&MP Act 1957 Sec 15(2) — Prohibited Heavy Excavation';
      case BufferZone.outerBuffer:
        return 'PNGRB T4S Reg. 7 — Mandatory RoW No-Encroachment Buffer';
      case BufferZone.externalClear:
        return 'Compliant — Outside Statutory 30m RoW Limit';
    }
  }
}

/// Encroachment types identified by AI Computer Vision & Payload Sensors
enum EncroachmentType {
  heavyMachinery, // JCB 3DX, Tata Hitachi EX200, CAT Excavators
  excavationDigging, // Mechanical/Manual Trenching, Third-Party Digging
  unauthorizedStructure, // Brick Masonry, Boundary Walls, Tin Sheds
  illegalTapAttempt, // Hydrocarbon Theft Clamp, Hidden Tap Pits, Siphon Lines
  vegetationRootOvergrowth, // Deep Rooting Trees breaching pipe coating
}

extension EncroachmentTypeExt on EncroachmentType {
  String get title {
    switch (this) {
      case EncroachmentType.heavyMachinery:
        return 'Heavy Machinery Encroachment';
      case EncroachmentType.excavationDigging:
        return 'Unauthorized Digging / Excavation';
      case EncroachmentType.unauthorizedStructure:
        return 'Unauthorized Permanent Structure';
      case EncroachmentType.illegalTapAttempt:
        return 'Illegal Tap Hole / Theft Attempt';
      case EncroachmentType.vegetationRootOvergrowth:
        return 'Tree Roots Threatening Coating';
    }
  }

  IconData get icon {
    switch (this) {
      case EncroachmentType.heavyMachinery:
        return Icons.precision_manufacturing_rounded;
      case EncroachmentType.excavationDigging:
        return Icons.construction_rounded;
      case EncroachmentType.unauthorizedStructure:
        return Icons.domain_disabled_rounded;
      case EncroachmentType.illegalTapAttempt:
        return Icons.local_fire_department_rounded;
      case EncroachmentType.vegetationRootOvergrowth:
        return Icons.park_rounded;
    }
  }
}

/// Severity classification
enum ThreatSeverity {
  critical,
  high,
  medium,
  low,
}

extension ThreatSeverityExt on ThreatSeverity {
  String get label {
    switch (this) {
      case ThreatSeverity.critical:
        return 'CRITICAL BREACH';
      case ThreatSeverity.high:
        return 'HIGH RISK';
      case ThreatSeverity.medium:
        return 'MODERATE RISK';
      case ThreatSeverity.low:
        return 'LOW CAUTION';
    }
  }

  Color get color {
    switch (this) {
      case ThreatSeverity.critical:
        return const Color(0xFFEF4444);
      case ThreatSeverity.high:
        return const Color(0xFFF97316);
      case ThreatSeverity.medium:
        return const Color(0xFFFFB95F);
      case ThreatSeverity.low:
        return const Color(0xFF38BDF8);
    }
  }
}

/// Dispatch status of Oil India Security Patrol Gang / QRT
enum QrtDispatchStatus {
  detected, // AI alert recorded, awaiting operator dispatch
  dispatched, // QRT Patrol Gang alerted & dispatched
  enRoute, // QRT 4x4 Tactical Vehicle traveling to coordinates
  onScene, // QRT arrived, megaphone warning & physical intervention
  intercepted, // Encroachment halted, machinery seized or work ceased
  firLodged, // Legal notice served, FIR under P&MP Act registered
  cleared, // RoW restored, verified by follow-up drone pass
}

extension QrtDispatchStatusExt on QrtDispatchStatus {
  String get label {
    switch (this) {
      case QrtDispatchStatus.detected:
        return 'ALERT PENDING';
      case QrtDispatchStatus.dispatched:
        return 'GANG DISPATCHED';
      case QrtDispatchStatus.enRoute:
        return 'EN ROUTE';
      case QrtDispatchStatus.onScene:
        return 'ON SCENE';
      case QrtDispatchStatus.intercepted:
        return 'INTERCEPTED';
      case QrtDispatchStatus.firLodged:
        return 'FIR LODGED';
      case QrtDispatchStatus.cleared:
        return 'ROW CLEARED';
    }
  }

  Color get color {
    switch (this) {
      case QrtDispatchStatus.detected:
        return const Color(0xFFFFB4AB);
      case QrtDispatchStatus.dispatched:
        return const Color(0xFFFFB95F);
      case QrtDispatchStatus.enRoute:
        return const Color(0xFF38BDF8);
      case QrtDispatchStatus.onScene:
        return const Color(0xFFA78BFA);
      case QrtDispatchStatus.intercepted:
        return const Color(0xFF4EDEA3);
      case QrtDispatchStatus.firLodged:
        return const Color(0xFF0284C7);
      case QrtDispatchStatus.cleared:
        return const Color(0xFF10B981);
    }
  }
}

/// Pipeline Sector definition along 194.5 KM Corridor
class CorridorSector {
  final String id;
  final String name;
  final double startKm;
  final double endKm;
  final String primaryBase;
  final String qrtCallsign;
  final int activeThreats;
  final double riskScore; // 0-100

  const CorridorSector({
    required this.id,
    required this.name,
    required this.startKm,
    required this.endKm,
    required this.primaryBase,
    required this.qrtCallsign,
    required this.activeThreats,
    required this.riskScore,
  });

  double get lengthKm => endKm - startKm;
}

/// Active UAV Fleet Model
class UavDroneUnit {
  final String id;
  final String callsign;
  final String model;
  final String missionType;
  double batteryPct;
  double voltageV;
  double speedKmh;
  double altitudeAglM;
  double headingDeg;
  double currentChainageKm;
  String currentSectorId;
  double latitude;
  double longitude;
  bool isLive;
  bool isPayloadActive;
  bool rtkFixed;
  int satelliteCount;
  int commLatencyMs;
  int remainingMinutes;

  UavDroneUnit({
    required this.id,
    required this.callsign,
    required this.model,
    required this.missionType,
    required this.batteryPct,
    required this.voltageV,
    required this.speedKmh,
    required this.altitudeAglM,
    required this.headingDeg,
    required this.currentChainageKm,
    required this.currentSectorId,
    required this.latitude,
    required this.longitude,
    this.isLive = true,
    this.isPayloadActive = true,
    this.rtkFixed = true,
    this.satelliteCount = 26,
    this.commLatencyMs = 38,
    this.remainingMinutes = 44,
  });
}

/// Encroachment Incident Record
class EncroachmentIncident {
  final String id;
  final DateTime detectedAt;
  final String sectorId;
  final String chainageStr;
  final double chainageKm;
  final double latitude;
  final double longitude;
  final String dagPattaNo;
  final EncroachmentType type;
  final ThreatSeverity severity;
  final double distanceFromCenterlineM;
  final BufferZone bufferZone;
  final double aiConfidencePct;
  final String machineryIdentity;
  final String description;
  final double thermalDeltaTC;
  final String statutoryClause;
  final String assignedQrtCallsign;
  QrtDispatchStatus status;
  int etaMinutes;
  bool sirenTriggered;
  bool noticeServed;

  EncroachmentIncident({
    required this.id,
    required this.detectedAt,
    required this.sectorId,
    required this.chainageStr,
    required this.chainageKm,
    required this.latitude,
    required this.longitude,
    required this.dagPattaNo,
    required this.type,
    required this.severity,
    required this.distanceFromCenterlineM,
    required this.bufferZone,
    required this.aiConfidencePct,
    required this.machineryIdentity,
    required this.description,
    required this.thermalDeltaTC,
    required this.statutoryClause,
    required this.assignedQrtCallsign,
    this.status = QrtDispatchStatus.detected,
    this.etaMinutes = 12,
    this.sirenTriggered = false,
    this.noticeServed = false,
  });
}

/// Thermal IR Radiometric Anomaly
class ThermalTapAnomaly {
  final String id;
  final String chainageStr;
  final double chainageKm;
  final String sector;
  final double surfaceTempC;
  final double ambientTempC;
  final double deltaTC;
  final String suspectedDevice;
  final ThreatSeverity risk;
  final double theftProbabilityPct;
  final bool groundDisturbance;
  final DateTime detectedTime;

  const ThermalTapAnomaly({
    required this.id,
    required this.chainageStr,
    required this.chainageKm,
    required this.sector,
    required this.surfaceTempC,
    required this.ambientTempC,
    required this.deltaTC,
    required this.suspectedDevice,
    required this.risk,
    required this.theftProbabilityPct,
    required this.groundDisturbance,
    required this.detectedTime,
  });
}

/// Oil India Security Patrol Gang Unit
class SecurityPatrolGang {
  final String gangId;
  final String name;
  final String callsign;
  final String baseStation;
  final String vehicleModel;
  final String registrationNo;
  final String commanderName;
  final String contactPhone;
  final int armedPersonnelCount;
  double distanceToTargetKm;
  int currentEtaMinutes;
  bool isDispatched;

  SecurityPatrolGang({
    required this.gangId,
    required this.name,
    required this.callsign,
    required this.baseStation,
    required this.vehicleModel,
    required this.registrationNo,
    required this.commanderName,
    required this.contactPhone,
    required this.armedPersonnelCount,
    required this.distanceToTargetKm,
    required this.currentEtaMinutes,
    this.isDispatched = false,
  });
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class DroneRowSurveillanceScreen extends StatefulWidget {
  const DroneRowSurveillanceScreen({super.key});

  @override
  State<DroneRowSurveillanceScreen> createState() =>
      _DroneRowSurveillanceScreenState();
}

class _DroneRowSurveillanceScreenState extends State<DroneRowSurveillanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _telemetryStreamTimer;
  final math.Random _random = math.Random(108);

  // Active View Filter & Selections
  int _selectedUavIndex = 0;
  String _selectedSectorFilter = 'ALL';
  String _activePayloadMode = 'RGB'; // 'RGB', 'THERMAL_IR', 'SPLIT'
  bool _isAutoPatrolActive = true;
  bool _spotlightSirenStrobe = false;
  int _simulatedTick = 0;

  // Selected Thermal Colormap
  String _selectedThermalColormap = 'Ironbow'; // Ironbow, Rainbow, White-Hot, Black-Hot

  // 194.5 KM Corridor Pipeline Sectors
  final List<CorridorSector> _corridorSectors = const [
    CorridorSector(
      id: 'SEC-A',
      name: 'Sector A: Duliajan to Moran',
      startKm: 0.0,
      endKm: 45.0,
      primaryBase: 'Duliajan Central Dispatch HQ',
      qrtCallsign: 'EAGLE-01',
      activeThreats: 1,
      riskScore: 32.5,
    ),
    CorridorSector(
      id: 'SEC-B',
      name: 'Sector B: Moran to Sivasagar',
      startKm: 45.0,
      endKm: 98.0,
      primaryBase: 'Moran Intermediate Base',
      qrtCallsign: 'RHINO-02',
      activeThreats: 3,
      riskScore: 78.4,
    ),
    CorridorSector(
      id: 'SEC-C',
      name: 'Sector C: Sivasagar to Jorhat',
      startKm: 98.0,
      endKm: 142.0,
      primaryBase: 'Sivasagar Security Outpost',
      qrtCallsign: 'CHEETAH-03',
      activeThreats: 2,
      riskScore: 54.0,
    ),
    CorridorSector(
      id: 'SEC-D',
      name: 'Sector D: Jorhat to Nagaon Delivery',
      startKm: 142.0,
      endKm: 194.5,
      primaryBase: 'Jorhat Sectionalizing Base',
      qrtCallsign: 'PANTHER-04',
      activeThreats: 1,
      riskScore: 41.2,
    ),
  ];

  // Active Drone Fleet
  late List<UavDroneUnit> _droneFleet;

  // Encroachment Records
  late List<EncroachmentIncident> _incidents;

  // Thermal Anomalies (Tap holes & theft attempts)
  late List<ThermalTapAnomaly> _thermalAnomalies;

  // Security Patrol Gangs
  late List<SecurityPatrolGang> _patrolGangs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeSurveillanceData();
    _startLiveTelemetryTimer();
  }

  @override
  void dispose() {
    _telemetryStreamTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeSurveillanceData() {
    _droneFleet = [
      UavDroneUnit(
        id: 'UAV-ALPHA',
        callsign: 'SkyGuard-Alpha',
        model: 'VTOL Hexacopter Heavy Payload (Oil India Air Wing)',
        missionType: 'Autonomous Statutory RoW Corridor Patrol',
        batteryPct: 84.5,
        voltageV: 49.2,
        speedKmh: 54.2,
        altitudeAglM: 110.0,
        headingDeg: 228.0,
        currentChainageKm: 48.32,
        currentSectorId: 'SEC-B',
        latitude: 27.2418,
        longitude: 94.9521,
        isLive: true,
        isPayloadActive: true,
        rtkFixed: true,
        satelliteCount: 28,
        commLatencyMs: 34,
        remainingMinutes: 42,
      ),
      UavDroneUnit(
        id: 'UAV-HAWK',
        callsign: 'AeroHawk-04',
        model: 'Fixed-Wing Long-Endurance Hybrid VTOL (4.5h)',
        missionType: 'High-Altitude Multispectral Corridor Survey',
        batteryPct: 96.0,
        voltageV: 51.4,
        speedKmh: 78.5,
        altitudeAglM: 185.0,
        headingDeg: 232.0,
        currentChainageKm: 122.15,
        currentSectorId: 'SEC-C',
        latitude: 26.8912,
        longitude: 94.4124,
        isLive: true,
        isPayloadActive: true,
        rtkFixed: true,
        satelliteCount: 24,
        commLatencyMs: 46,
        remainingMinutes: 180,
      ),
      UavDroneUnit(
        id: 'UAV-BETA',
        callsign: 'Sentinel-Beta',
        model: 'Rapid-Reaction Quadcopter Tactical Interceptor',
        missionType: 'Standby / Low-Altitude Threat Verification',
        batteryPct: 100.0,
        voltageV: 24.8,
        speedKmh: 0.0,
        altitudeAglM: 0.0,
        headingDeg: 0.0,
        currentChainageKm: 45.0,
        currentSectorId: 'SEC-B',
        latitude: 27.2610,
        longitude: 94.9810,
        isLive: false,
        isPayloadActive: false,
        rtkFixed: true,
        satelliteCount: 22,
        commLatencyMs: 28,
        remainingMinutes: 35,
      ),
    ];

    _incidents = [
      EncroachmentIncident(
        id: 'ENC-2026-0842',
        detectedAt: DateTime.now().subtract(const Duration(minutes: 9)),
        sectorId: 'SEC-B',
        chainageStr: 'KP 48+320',
        chainageKm: 48.32,
        latitude: 27.2418,
        longitude: 94.9521,
        dagPattaNo: 'Dag No. 412, Patta No. 89 (Moran Circle)',
        type: EncroachmentType.heavyMachinery,
        severity: ThreatSeverity.critical,
        distanceFromCenterlineM: 4.2,
        bufferZone: BufferZone.coreHazard,
        aiConfidencePct: 97.4,
        machineryIdentity: 'JCB 3DX Super Eco (Yellow Excavator)',
        description:
            'Unauthorized mechanical excavator conducting unpermitted deep trenching 4.2m from 18" hydrocarbon pipeline centerline. Extreme risk of third-party pipe puncture.',
        thermalDeltaTC: 6.8,
        statutoryClause:
            'Section 15(1) & 15(2) Petroleum & Minerals Pipelines Act 1957 (3 Years Imprisonment & Non-Bailable Cognizable Offense); PNGRB T4S Reg. 7',
        assignedQrtCallsign: 'RHINO-02',
        status: QrtDispatchStatus.dispatched,
        etaMinutes: 7,
      ),
      EncroachmentIncident(
        id: 'ENC-2026-0839',
        detectedAt: DateTime.now().subtract(const Duration(minutes: 34)),
        sectorId: 'SEC-B',
        chainageStr: 'KP 62+180',
        chainageKm: 62.18,
        latitude: 27.1142,
        longitude: 94.8015,
        dagPattaNo: 'Dag No. 182, Moran Tea Estate Boundary',
        type: EncroachmentType.illegalTapAttempt,
        severity: ThreatSeverity.critical,
        distanceFromCenterlineM: 1.8,
        bufferZone: BufferZone.coreHazard,
        aiConfidencePct: 98.8,
        machineryIdentity: 'Concealed 2" High-Pressure Ball Valve Tap Rig',
        description:
            'Radiometric FLIR payload detected chilled thermal anomaly (ΔT -10.4°C) with freshly excavated soil tamped down over welded saddle clamp. Hydrocarbon theft attempt in progress.',
        thermalDeltaTC: -10.4,
        statutoryClause:
            'Section 15(4) P&MP Act 1957; Section 379/427 IPC (Theft of Petroleum & Mischief); Public Property Damage Act 1984',
        assignedQrtCallsign: 'RHINO-02',
        status: QrtDispatchStatus.enRoute,
        etaMinutes: 4,
      ),
      EncroachmentIncident(
        id: 'ENC-2026-0831',
        detectedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
        sectorId: 'SEC-B',
        chainageStr: 'KP 79+450',
        chainageKm: 79.45,
        latitude: 27.0210,
        longitude: 94.6930,
        dagPattaNo: 'Dag No. 904, Sivasagar Bypass Margin',
        type: EncroachmentType.unauthorizedStructure,
        severity: ThreatSeverity.high,
        distanceFromCenterlineM: 11.5,
        bufferZone: BufferZone.innerStatutory,
        aiConfidencePct: 94.2,
        machineryIdentity: 'Permanent Brick Masonry & RCC Column Plinth',
        description:
            'Unauthorized commercial garage construction within 15m statutory RoW core buffer. Masonry foundation encroaches 8.5m inside statutory restricted easement.',
        thermalDeltaTC: 1.2,
        statutoryClause:
            'Section 15(2) P&MP Act 1957 (Demolition Order & Penalty); PNGRB Integrity Management Code',
        assignedQrtCallsign: 'CHEETAH-03',
        status: QrtDispatchStatus.onScene,
        etaMinutes: 0,
      ),
      EncroachmentIncident(
        id: 'ENC-2026-0824',
        detectedAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 50)),
        sectorId: 'SEC-C',
        chainageStr: 'KP 114+800',
        chainageKm: 114.8,
        latitude: 26.9421,
        longitude: 94.5120,
        dagPattaNo: 'Dag No. 238, Teok Agricultural Corridor',
        type: EncroachmentType.excavationDigging,
        severity: ThreatSeverity.medium,
        distanceFromCenterlineM: 22.4,
        bufferZone: BufferZone.outerBuffer,
        aiConfidencePct: 91.5,
        machineryIdentity: 'Tractor Backhoe Ditcher Rig',
        description:
            'Local irrigation canal trenching inside 30m regulated buffer without prior Oil India No-Objection Certificate. Machinery instructed to halt excavation.',
        thermalDeltaTC: 3.1,
        statutoryClause:
            'PNGRB T4S Reg. 7 (Prior Approval Required for Earthmoving within 30m RoW boundary)',
        assignedQrtCallsign: 'CHEETAH-03',
        status: QrtDispatchStatus.intercepted,
        etaMinutes: 0,
        noticeServed: true,
      ),
      EncroachmentIncident(
        id: 'ENC-2026-0819',
        detectedAt: DateTime.now().subtract(const Duration(hours: 7)),
        sectorId: 'SEC-A',
        chainageStr: 'KP 18+200',
        chainageKm: 18.2,
        latitude: 27.3105,
        longitude: 95.1204,
        dagPattaNo: 'Dag No. 67, Duliajan Periphery',
        type: EncroachmentType.heavyMachinery,
        severity: ThreatSeverity.high,
        distanceFromCenterlineM: 8.7,
        bufferZone: BufferZone.innerStatutory,
        aiConfidencePct: 95.0,
        machineryIdentity: 'Tata Hitachi EX200 Hydraulic Shovel',
        description:
            'Heavy crawler excavator traversing across buried pipeline without high-load timber mats. Risk of excessive ground compaction and coating deflection.',
        thermalDeltaTC: 5.6,
        statutoryClause: 'OISD-141 Cl. 6.4; P&MP Act 1957 Statutory RoW Protection',
        assignedQrtCallsign: 'EAGLE-01',
        status: QrtDispatchStatus.firLodged,
        etaMinutes: 0,
        noticeServed: true,
      ),
      EncroachmentIncident(
        id: 'ENC-2026-0810',
        detectedAt: DateTime.now().subtract(const Duration(hours: 14)),
        sectorId: 'SEC-D',
        chainageStr: 'KP 168+900',
        chainageKm: 168.9,
        latitude: 26.5812,
        longitude: 93.9921,
        dagPattaNo: 'Dag No. 511, Kaliabor Belt',
        type: EncroachmentType.vegetationRootOvergrowth,
        severity: ThreatSeverity.low,
        distanceFromCenterlineM: 3.5,
        bufferZone: BufferZone.coreHazard,
        aiConfidencePct: 88.6,
        machineryIdentity: 'Ficus Tree Deep Root Encroachment',
        description:
            'Heavy ficus tree root system directly above pipeline crown causing cathodic protection shield and 3LPE coating disbondment risk.',
        thermalDeltaTC: -0.8,
        statutoryClause: 'OISD-141 Maintenance Specification for Pipeline RoW Clearing',
        assignedQrtCallsign: 'PANTHER-04',
        status: QrtDispatchStatus.cleared,
        etaMinutes: 0,
        noticeServed: true,
      ),
    ];

    _thermalAnomalies = [
      ThermalTapAnomaly(
        id: 'THM-TAP-04',
        chainageStr: 'KP 62+180',
        chainageKm: 62.18,
        sector: 'Sector B (Moran-Sivasagar)',
        surfaceTempC: 18.2,
        ambientTempC: 28.6,
        deltaTC: -10.4,
        suspectedDevice: '2" Welded High-Pressure Tapping Saddle with Camlock Hose',
        risk: ThreatSeverity.critical,
        theftProbabilityPct: 98.8,
        groundDisturbance: true,
        detectedTime: DateTime.now().subtract(const Duration(minutes: 34)),
      ),
      ThermalTapAnomaly(
        id: 'THM-TAP-03',
        chainageStr: 'KP 88+940',
        chainageKm: 88.94,
        sector: 'Sector B (Moran-Sivasagar)',
        surfaceTempC: 38.4,
        ambientTempC: 28.1,
        deltaTC: 10.3,
        suspectedDevice: 'Portable Diesel Generator & Electric Arc Welder Hot-Tap Rig',
        risk: ThreatSeverity.critical,
        theftProbabilityPct: 96.2,
        groundDisturbance: true,
        detectedTime: DateTime.now().subtract(const Duration(hours: 5, minutes: 12)),
      ),
      ThermalTapAnomaly(
        id: 'THM-TAP-02',
        chainageStr: 'KP 135+400',
        chainageKm: 135.4,
        sector: 'Sector C (Sivasagar-Jorhat)',
        surfaceTempC: 21.0,
        ambientTempC: 27.5,
        deltaTC: -6.5,
        suspectedDevice: 'Buried Valve Flange Weep / Subsurface Hydrocarbon Seepage',
        risk: ThreatSeverity.high,
        theftProbabilityPct: 82.5,
        groundDisturbance: false,
        detectedTime: DateTime.now().subtract(const Duration(hours: 18)),
      ),
    ];

    _patrolGangs = [
      SecurityPatrolGang(
        gangId: 'GANG-02',
        name: 'Moran Sector Quick Response Team',
        callsign: 'RHINO-02',
        baseStation: 'Moran Intermediate Pigging Post (KP 45+000)',
        vehicleModel: 'Mahindra Scorpio 4x4 Armed Tactical Unit',
        registrationNo: 'AS-06-G-1102',
        commanderName: 'Inspector R. K. Gogoi (CISF)',
        contactPhone: '+91 94350-29184',
        armedPersonnelCount: 6,
        distanceToTargetKm: 3.32,
        currentEtaMinutes: 5,
        isDispatched: true,
      ),
      SecurityPatrolGang(
        gangId: 'GANG-01',
        name: 'Duliajan Pipeline Defense Wing',
        callsign: 'EAGLE-01',
        baseStation: 'Duliajan Central Security Barracks (KP 0+000)',
        vehicleModel: 'Tata Xenon Heavy 4x4 Patrol',
        registrationNo: 'AS-23-E-8804',
        commanderName: 'Sub-Inspector M. Borah',
        contactPhone: '+91 94351-40192',
        armedPersonnelCount: 8,
        distanceToTargetKm: 18.2,
        currentEtaMinutes: 24,
      ),
      SecurityPatrolGang(
        gangId: 'GANG-03',
        name: 'Sivasagar Strike Patrol',
        callsign: 'CHEETAH-03',
        baseStation: 'Sivasagar Sectionalizing Post (KP 98+000)',
        vehicleModel: 'Force Gurkha 4x4 Armored Escort',
        registrationNo: 'AS-04-T-3321',
        commanderName: 'Inspector T. Saikia (Assam Police Battalion)',
        contactPhone: '+91 94355-66710',
        armedPersonnelCount: 6,
        distanceToTargetKm: 16.5,
        currentEtaMinutes: 19,
      ),
      SecurityPatrolGang(
        gangId: 'GANG-04',
        name: 'Jorhat Rapid Intervention Unit',
        callsign: 'PANTHER-04',
        baseStation: 'Jorhat Dispatch Station (KP 142+000)',
        vehicleModel: 'Mahindra Bolero Camper 4x4',
        registrationNo: 'AS-03-P-5591',
        commanderName: 'Havildar D. Phukan',
        contactPhone: '+91 94352-78833',
        armedPersonnelCount: 5,
        distanceToTargetKm: 26.8,
        currentEtaMinutes: 32,
      ),
    ];
  }

  void _startLiveTelemetryTimer() {
    _telemetryStreamTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        _simulatedTick++;

        // Update active drone telemetry
        final activeDrone = _droneFleet[_selectedUavIndex];
        if (activeDrone.isLive) {
          // Slow patrol flight progression along pipeline
          activeDrone.currentChainageKm += 0.045; // ~54 km/h flight speed
          if (activeDrone.currentChainageKm > 194.5) {
            activeDrone.currentChainageKm = 0.0;
          }

          // Small fluctuations in live metrics
          activeDrone.speedKmh = 52.0 + (_random.nextDouble() * 4.0);
          activeDrone.altitudeAglM = 110.0 + (_random.nextDouble() * 3.0 - 1.5);
          activeDrone.batteryPct = math.max(12.0, activeDrone.batteryPct - 0.03);
          activeDrone.commLatencyMs = 32 + _random.nextInt(8);
          activeDrone.voltageV = 44.0 + (activeDrone.batteryPct / 100.0) * 8.0;

          // Lat/long micro drift based on chainage
          activeDrone.latitude = 27.3500 - (activeDrone.currentChainageKm / 194.5) * 1.1;
          activeDrone.longitude = 95.3000 - (activeDrone.currentChainageKm / 194.5) * 2.3;
        }

        // Update ETA for dispatched QRT gangs
        for (final inc in _incidents) {
          if (inc.status == QrtDispatchStatus.dispatched ||
              inc.status == QrtDispatchStatus.enRoute) {
            if (inc.etaMinutes > 1 && _simulatedTick % 4 == 0) {
              inc.etaMinutes--;
            } else if (inc.etaMinutes == 1 && _simulatedTick % 4 == 0) {
              inc.status = QrtDispatchStatus.onScene;
              inc.etaMinutes = 0;
            }
          }
        }
      });
    });
  }

  // ==========================================================================
  // ACTION HANDLERS
  // ==========================================================================

  void _triggerRtlReturn() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.border),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.flight_land_rounded, color: AppTheme.primaryLight),
            SizedBox(width: 8),
            Text(
              'Initiate Return-to-Launch (RTL)?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Autonomous abort command will engage GPS Return-to-Base trajectory toward closest secured landing pad:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _infoKeyValue(
                      'UAV Unit', _droneFleet[_selectedUavIndex].callsign),
                  _infoKeyValue('Target Home Pad',
                      'Moran Sector QRT Helipad (KP 45+000)'),
                  _infoKeyValue('Distance to Home', '3.32 KM'),
                  _infoKeyValue('Estimated Transit', '3.8 Minutes'),
                  _infoKeyValue('Battery at Touchdown', '78.2% (Safe Reserve)'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isAutoPatrolActive = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.primary,
                  content: Text(
                      'RTL Command Acknowledged: ${_droneFleet[_selectedUavIndex].callsign} navigating to Home Base.'),
                ),
              );
            },
            child: const Text('CONFIRM RTL'),
          ),
        ],
      ),
    );
  }

  void _triggerStrobeSirenAlert() {
    setState(() {
      _spotlightSirenStrobe = !_spotlightSirenStrobe;
    });

    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            _spotlightSirenStrobe ? const Color(0xFFEF4444) : AppTheme.surfaceCard,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(
              _spotlightSirenStrobe
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _spotlightSirenStrobe
                    ? '12,000-LUMEN STROBE & 110dB ACOUSTIC SIREN ACTIVE ON DRONE GIMBAL'
                    : 'Acoustic siren & strobe spotlight deactivated.',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _dispatchPatrolGangModal(EncroachmentIncident incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.crisis_alert_rounded,
                                color: Color(0xFFEF4444),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Automated Patrol Dispatch',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Target: ${incident.chainageStr} • ${incident.sectorId}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Incident Snapshot Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: incident.bufferZone.color.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: incident.bufferZone.color
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  incident.bufferZone.displayName,
                                  style: TextStyle(
                                    color: incident.bufferZone.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${incident.distanceFromCenterlineM.toStringAsFixed(1)}m from Centerline',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            incident.machineryIdentity,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            incident.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Statutory Violation: ${incident.statutoryClause}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.secondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Available Oil India Security Patrol Gangs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._patrolGangs.map((gang) {
                      final isAssigned =
                          gang.callsign == incident.assignedQrtCallsign;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAssigned
                              ? AppTheme.primary.withValues(alpha: 0.12)
                              : AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isAssigned
                                ? AppTheme.primaryLight
                                : AppTheme.border,
                            width: isAssigned ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: AppTheme.primaryLight,
                                size: 22,
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
                                        gang.callsign,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.tertiary
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${gang.armedPersonnelCount} CISF Armed',
                                          style: const TextStyle(
                                            color: AppTheme.tertiary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    gang.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'Cmdr: ${gang.commanderName} • ${gang.contactPhone}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${gang.distanceToTargetKm.toStringAsFixed(1)} KM',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'ETA: ~${gang.currentEtaMinutes}m',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.flash_on_rounded),
                        label: const Text(
                          'CONFIRM IMMEDIATE QRT DISPATCH',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () {
                          setState(() {
                            incident.status = QrtDispatchStatus.dispatched;
                            incident.etaMinutes = 8;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFEF4444),
                              content: Text(
                                  'DISPATCH ORDER CONFIRMED: ${incident.assignedQrtCallsign} en route to ${incident.chainageStr}. ETA 8 Mins.'),
                            ),
                          );
                        },
                      ),
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

  void _showNoticeGeneratorModal(EncroachmentIncident incident) {
    final now = DateTime.now();
    final noticeId =
        'OIL/ROW/LEGAL/${now.year}/${incident.id.replaceAll('ENC-', '')}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.border),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.gavel_rounded, color: AppTheme.secondary),
            SizedBox(width: 8),
            Text(
              'Statutory RoW Violation Notice',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NOTICE ID: $noticeId',
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.primaryLight)),
                    Text(
                        'DATE: ${DateFormat('dd-MMM-yyyy HH:mm').format(now)} IST',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ORDER TO CEASE AND DESIST UNAUTHORIZED WORK',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Issued under Section 15 of Petroleum & Minerals Pipelines (Acquisition of Right of User in Land) Act, 1957.\n\n'
                'To the Owner/Contractor/Excavator Operator at ${incident.dagPattaNo}, Chainage ${incident.chainageStr}:\n\n'
                'Take notice that an Aerial Drone Computer Vision scan conducted by Oil India Limited at GPS coordinates (${incident.latitude.toStringAsFixed(4)}° N, ${incident.longitude.toStringAsFixed(4)}° E) has verified unauthorized heavy earthmoving machinery operating ${incident.distanceFromCenterlineM.toStringAsFixed(1)}m from the high-pressure hydrocarbon pipeline centerline within the 30-meter statutory RoW buffer.\n\n'
                'PENAL CONSEQUENCES:\n'
                '• Immediate cessation of all mechanical excavation.\n'
                '• Cognizable non-bailable offense under Section 15(1) & 15(2) of P&MP Act 1957.\n'
                '• Penalty of imprisonment up to 3 years and compensation for damage under Public Property Damage Act 1984.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified_user_rounded,
                        color: AppTheme.tertiary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Digitally Signed by Competent Authority, Oil India Ltd. (Duliajan HQ)',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.tertiary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DISMISS',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.black87,
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('DISPATCH NOTICE & NOTIFY POLICE'),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                incident.noticeServed = true;
                incident.status = QrtDispatchStatus.firLodged;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.secondary,
                  content: Text(
                      'Statutory Notice $noticeId transmitted to Assam Police & Local Revenue Circle Officer.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // BUILD METHOD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCorridorQuickTicker(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLiveRadarTelemetryTab(),
                _buildAiVisionEncroachmentsTab(),
                _buildThermalTheftTab(),
                _buildSecurityPatrolTab(),
                _buildStatutoryAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // APP BAR & TICKER
  // ==========================================================================

  PreferredSizeWidget _buildAppBar() {
    final activeDrone = _droneFleet[_selectedUavIndex];
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_takeoff_rounded,
                  color: AppTheme.primaryLight, size: 20),
              const SizedBox(width: 8),
              const Text(
                'RoW Drone Surveillance & AI Protection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
                ),
                child: const Text(
                  '194.5 KM LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Duliajan–Nagaon Corridor • Active: ${activeDrone.callsign} • RTK FIXED',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Toggle Siren & Strobe Deterrence',
          icon: Icon(
            _spotlightSirenStrobe
                ? Icons.flash_on_rounded
                : Icons.flash_off_rounded,
            color: _spotlightSirenStrobe
                ? const Color(0xFFEF4444)
                : AppTheme.textMuted,
          ),
          onPressed: _triggerStrobeSirenAlert,
        ),
        IconButton(
          tooltip: 'Return-to-Launch (RTL)',
          icon: const Icon(Icons.flight_land_rounded,
              color: AppTheme.primaryLight),
          onPressed: _triggerRtlReturn,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: const [
          Tab(
            icon: Icon(Icons.radar_rounded, size: 18),
            text: 'RADAR & FLIGHT',
          ),
          Tab(
            icon: Icon(Icons.visibility_rounded, size: 18),
            text: 'AI VISION BUFFER',
          ),
          Tab(
            icon: Icon(Icons.thermostat_rounded, size: 18),
            text: 'THERMAL THEFT IR',
          ),
          Tab(
            icon: Icon(Icons.security_rounded, size: 18),
            text: 'PATROL & QRT',
          ),
          Tab(
            icon: Icon(Icons.assignment_turned_in_rounded, size: 18),
            text: 'STATUTORY COMPLIANCE',
          ),
        ],
      ),
    );
  }

  Widget _buildCorridorQuickTicker() {
    final activeDrone = _droneFleet[_selectedUavIndex];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // UAV Drone Selector Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedUavIndex,
                dropdownColor: AppTheme.surfaceCard,
                icon: const Icon(Icons.arrow_drop_down,
                    color: AppTheme.primaryLight, size: 18),
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                items: [
                  for (int i = 0; i < _droneFleet.length; i++)
                    DropdownMenuItem<int>(
                      value: i,
                      child: Text(_droneFleet[i].callsign),
                    ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedUavIndex = val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Telemetry Indicators
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tickerItem(
                    Icons.battery_charging_full_rounded,
                    '${activeDrone.batteryPct.toStringAsFixed(0)}%',
                    activeDrone.batteryPct > 30
                        ? AppTheme.tertiary
                        : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 12),
                  _tickerItem(
                    Icons.speed_rounded,
                    '${activeDrone.speedKmh.toStringAsFixed(0)} KM/H',
                    AppTheme.primaryLight,
                  ),
                  const SizedBox(width: 12),
                  _tickerItem(
                    Icons.height_rounded,
                    '${activeDrone.altitudeAglM.toStringAsFixed(0)}m AGL',
                    AppTheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  _tickerItem(
                    Icons.pin_drop_rounded,
                    'KP ${activeDrone.currentChainageKm.toStringAsFixed(1)}',
                    AppTheme.textPrimary,
                  ),
                  const SizedBox(width: 12),
                  _tickerItem(
                    Icons.wifi_tethering_rounded,
                    '${activeDrone.commLatencyMs}ms (5G SAT)',
                    AppTheme.tertiary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tickerItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 1: RADAR & FLIGHT TELEMETRY
  // ==========================================================================

  Widget _buildLiveRadarTelemetryTab() {
    final activeDrone = _droneFleet[_selectedUavIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tactical Radar / Visual Corridor Canvas
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: _CorridorRadarPainter(
                      activeDroneChainageKm: activeDrone.currentChainageKm,
                      incidents: _incidents,
                      patrolGangs: _patrolGangs,
                      sectors: _corridorSectors,
                      strobeActive: _spotlightSirenStrobe,
                      simulatedTick: _simulatedTick,
                    ),
                  ),
                  // HUD Overlay Top Left
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.tertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE CORRIDOR RADAR • 194.5 KM',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Corridor Segment Guide Bottom Right
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Text(
                        'Cyan = 18" Pipe • Amber/Red = 30m RoW Buffer',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Flight Mission Telemetry Card Grid
          const Text(
            'UAV Flight Telemetry & Downlink',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryMetricCard(
                  title: 'BATTERY PACK',
                  value: '${activeDrone.batteryPct.toStringAsFixed(1)}%',
                  subtext:
                      '${activeDrone.voltageV.toStringAsFixed(1)}V • ~${activeDrone.remainingMinutes}m left',
                  icon: Icons.battery_charging_full_rounded,
                  accentColor: activeDrone.batteryPct > 25
                      ? AppTheme.tertiary
                      : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTelemetryMetricCard(
                  title: 'FLIGHT DYNAMICS',
                  value: '${activeDrone.speedKmh.toStringAsFixed(0)} KM/H',
                  subtext:
                      'Alt: ${activeDrone.altitudeAglM.toStringAsFixed(0)}m AGL • Heading ${activeDrone.headingDeg.toInt()}°',
                  icon: Icons.navigation_rounded,
                  accentColor: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryMetricCard(
                  title: 'RTK POSITIONING',
                  value: activeDrone.rtkFixed ? 'RTK FIX (±1.2cm)' : 'FLOAT',
                  subtext:
                      '${activeDrone.satelliteCount} Sats • GPS/GLONASS/NavIC',
                  icon: Icons.gps_fixed_rounded,
                  accentColor: AppTheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTelemetryMetricCard(
                  title: 'PAYLOAD DOWNLINK',
                  value: '4K H.265 / 12 Mbps',
                  subtext: 'Latency: ${activeDrone.commLatencyMs}ms • 5G Mesh',
                  icon: Icons.videocam_rounded,
                  accentColor: AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interactive Mission Command Deck
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mission Control & Payload Command',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isAutoPatrolActive
                            ? AppTheme.tertiary.withValues(alpha: 0.2)
                            : AppTheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isAutoPatrolActive
                            ? 'AUTONOMOUS PATROL ACTIVE'
                            : 'MANUAL HOVER MODE',
                        style: TextStyle(
                          color: _isAutoPatrolActive
                              ? AppTheme.tertiary
                              : AppTheme.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          _isAutoPatrolActive
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_arrow_rounded,
                          size: 16,
                          color: AppTheme.primaryLight,
                        ),
                        label: Text(_isAutoPatrolActive
                            ? 'HOVER POI'
                            : 'RESUME PATROL'),
                        onPressed: () {
                          setState(() {
                            _isAutoPatrolActive = !_isAutoPatrolActive;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.sync_rounded,
                            size: 16, color: AppTheme.secondary),
                        label: const Text('360° ORBIT'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppTheme.surfaceCard,
                              content: Text(
                                  'Gimbal executing 360° Orbit Scan around current RoW Waypoint.'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.flight_land_rounded,
                            size: 16, color: Color(0xFFEF4444)),
                        label: const Text('RTL HOME'),
                        onPressed: _triggerRtlReturn,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Corridor Sector Breakdown Card
          const Text(
            '194.5 KM Corridor Sectors & Threat Index',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ..._corridorSectors.map((sector) => _buildSectorRowCard(sector)),
        ],
      ),
    );
  }

  Widget _buildTelemetryMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorRowCard(CorridorSector sector) {
    final isHighRisk = sector.riskScore > 60;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighRisk
              ? const Color(0xFFEF4444).withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: isHighRisk ? const Color(0xFFEF4444) : AppTheme.tertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sector.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'KP ${sector.startKm.toInt()} to ${sector.endKm.toInt()} (${sector.lengthKm.toStringAsFixed(1)} KM) • QRT: ${sector.qrtCallsign}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${sector.activeThreats} Threats',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isHighRisk
                      ? const Color(0xFFEF4444)
                      : AppTheme.textPrimary,
                ),
              ),
              Text(
                'Risk: ${sector.riskScore.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: isHighRisk ? const Color(0xFFEF4444) : AppTheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: AI VISION & 30M STATUTORY BUFFER
  // ==========================================================================

  Widget _buildAiVisionEncroachmentsTab() {
    final filteredIncidents = _selectedSectorFilter == 'ALL'
        ? _incidents
        : _incidents
            .where((i) => i.sectorId == _selectedSectorFilter)
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payload Selector Chips
          Row(
            children: [
              const Text(
                'Sensor Payload: ',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final mode in ['RGB Optical', 'Thermal IR', 'Split EO/IR'])
                    ChoiceChip(
                      label: Text(mode, style: const TextStyle(fontSize: 11)),
                      selected: (_activePayloadMode == 'RGB' && mode == 'RGB Optical') ||
                          (_activePayloadMode == 'THERMAL_IR' && mode == 'Thermal IR') ||
                          (_activePayloadMode == 'SPLIT' && mode == 'Split EO/IR'),
                      selectedColor: AppTheme.primaryLight.withValues(alpha: 0.3),
                      backgroundColor: AppTheme.surfaceCard,
                      side: BorderSide(
                        color: ((_activePayloadMode == 'RGB' && mode == 'RGB Optical') ||
                                (_activePayloadMode == 'THERMAL_IR' && mode == 'Thermal IR') ||
                                (_activePayloadMode == 'SPLIT' && mode == 'Split EO/IR'))
                            ? AppTheme.primaryLight
                            : AppTheme.border,
                      ),
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            if (mode == 'RGB Optical') _activePayloadMode = 'RGB';
                            if (mode == 'Thermal IR') _activePayloadMode = 'THERMAL_IR';
                            if (mode == 'Split EO/IR') _activePayloadMode = 'SPLIT';
                          });
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Live AI Computer Vision Camera Feed Simulation
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: _AiCameraHudPainter(
                      activeIncident: _incidents.first,
                      strobeActive: _spotlightSirenStrobe,
                      tick: _simulatedTick,
                      payloadMode: _activePayloadMode,
                    ),
                  ),
                  // HUD Telemetry Header
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AI DETECT • LIVE 4K EO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ZOOM: 30x • FL: 180mm • ISO 200',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 30m Statutory Buffer Zone Legend Meter
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
                  'Statutory Pipeline Buffer Zones (Petroleum & Minerals Pipelines Act 1957)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 16,
                          color: const Color(0xFFEF4444),
                          alignment: Alignment.center,
                          child: const Text('0-5m',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: Container(
                          height: 16,
                          color: const Color(0xFFF97316),
                          alignment: Alignment.center,
                          child: const Text('5-15m',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                      Expanded(
                        flex: 15,
                        child: Container(
                          height: 16,
                          color: const Color(0xFFFFB95F),
                          alignment: Alignment.center,
                          child: const Text('15-30m',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                        ),
                      ),
                      Expanded(
                        flex: 20,
                        child: Container(
                          height: 16,
                          color: const Color(0xFF4EDEA3),
                          alignment: Alignment.center,
                          child: const Text('>30m Clear',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Core Hazard (Strict Stop)',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600)),
                    Text('15m RoW Easement',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFF97316),
                            fontWeight: FontWeight.w600)),
                    Text('30m Statutory Buffer',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFFFB95F),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Encroachment Filter Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Encroachments (${filteredIncidents.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSectorFilter,
                  dropdownColor: AppTheme.surfaceCard,
                  icon: const Icon(Icons.filter_list_rounded,
                      color: AppTheme.primaryLight, size: 18),
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All Sectors')),
                    DropdownMenuItem(value: 'SEC-A', child: Text('Sector A (KP 0-45)')),
                    DropdownMenuItem(value: 'SEC-B', child: Text('Sector B (KP 45-98)')),
                    DropdownMenuItem(value: 'SEC-C', child: Text('Sector C (KP 98-142)')),
                    DropdownMenuItem(value: 'SEC-D', child: Text('Sector D (KP 142-194.5)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedSectorFilter = val);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Encroachment Incident Cards List
          ...filteredIncidents.map((inc) => _buildEncroachmentIncidentCard(inc)),
        ],
      ),
    );
  }

  Widget _buildEncroachmentIncidentCard(EncroachmentIncident incident) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: incident.bufferZone.color.withValues(alpha: 0.5),
          width: incident.severity == ThreatSeverity.critical ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: incident.bufferZone.color.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(incident.type.icon,
                    size: 18, color: incident.bufferZone.color),
                const SizedBox(width: 8),
                Text(
                  incident.type.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: incident.bufferZone.color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: incident.status.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    incident.status.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: incident.status.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      incident.machineryIdentity,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'AI: ${incident.aiConfidencePct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${incident.chainageStr} • ${incident.sectorId} • ${incident.dagPattaNo}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  incident.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                // Centerline Offset Badge & Statute
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        'Offset: ${incident.distanceFromCenterlineM.toStringAsFixed(1)}m from Centerline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: incident.bufferZone.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (incident.thermalDeltaTC != 0.0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          'ΔT: ${incident.thermalDeltaTC > 0 ? '+' : ''}${incident.thermalDeltaTC.toStringAsFixed(1)}°C',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: incident.thermalDeltaTC < 0
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFFF97316),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.secondary),
                        ),
                        icon: const Icon(Icons.gavel_rounded,
                            size: 15, color: AppTheme.secondary),
                        label: const Text(
                          'STATUTORY NOTICE',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.secondary),
                        ),
                        onPressed: () => _showNoticeGeneratorModal(incident),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: incident.status ==
                                  QrtDispatchStatus.dispatched
                              ? AppTheme.tertiary
                              : const Color(0xFFEF4444),
                        ),
                        icon: const Icon(Icons.flash_on_rounded, size: 15),
                        label: Text(
                          incident.status == QrtDispatchStatus.dispatched
                              ? 'DISPATCHED (ETA ${incident.etaMinutes}m)'
                              : 'DISPATCH QRT',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () => _dispatchPatrolGangModal(incident),
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

  // ==========================================================================
  // TAB 3: THERMAL IR & THEFT DETECTION
  // ==========================================================================

  Widget _buildThermalTheftTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Radiometric Thermal Stream Canvas
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: _ThermalRadiometricPainter(
                      colormap: _selectedThermalColormap,
                      tick: _simulatedTick,
                    ),
                  ),
                  // Thermal Status Header
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FLIR BOSON 640 RADIOMETRIC IR',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SPOT: 18.2°C • ΔT: -10.4°C (CHILLED LEAK)',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Colormap Palette Switcher
          Row(
            children: [
              const Text(
                'IR Palette: ',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final cmap in ['Ironbow', 'Rainbow', 'White-Hot', 'Black-Hot'])
                    ChoiceChip(
                      label: Text(cmap, style: const TextStyle(fontSize: 11)),
                      selected: _selectedThermalColormap == cmap,
                      selectedColor: AppTheme.primaryLight.withValues(alpha: 0.3),
                      backgroundColor: AppTheme.surfaceCard,
                      side: BorderSide(
                        color: _selectedThermalColormap == cmap
                            ? AppTheme.primaryLight
                            : AppTheme.border,
                      ),
                      onSelected: (sel) {
                        if (sel) {
                          setState(() => _selectedThermalColormap = cmap);
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Radiometric Temperature Cross-Section Chart
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Cross-Section Radiometric Soil Gradient (°C)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'KP 62+180 (Tap Hole #4)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sharp temperature drop indicates Joule-Thomson gas expansion cooling escaping from illegal hot-tap saddle clamp.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (val) => FlLine(
                          color: AppTheme.border.withValues(alpha: 0.5),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (val, meta) => Text(
                              '${val.toInt()}°C',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 9),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              const offsets = [
                                '-10m',
                                '-5m',
                                'Pipe CL',
                                '+5m',
                                '+10m'
                              ];
                              final idx = val.toInt();
                              if (idx >= 0 && idx < offsets.length) {
                                return Text(offsets[idx],
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 9));
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 4,
                      minY: 15,
                      maxY: 35,
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: const Color(0xFF38BDF8),
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          spots: const [
                            FlSpot(0, 28.5), // -10m (normal ground)
                            FlSpot(1, 27.8), // -5m
                            FlSpot(2, 18.2), // Pipe Centerline (Depressurized Leak!)
                            FlSpot(3, 27.4), // +5m
                            FlSpot(4, 28.6), // +10m (normal ground)
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Illegal Tap & Hydrocarbon Theft Registry
          const Text(
            'Thermal Tap Anomalies & Theft Investigation Register',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ..._thermalAnomalies.map((tap) => _buildThermalAnomalyCard(tap)),
        ],
      ),
    );
  }

  Widget _buildThermalAnomalyCard(ThermalTapAnomaly tap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.5),
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
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tap.chainageStr} • ${tap.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      tap.sector,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'THEFT PROB: ${tap.theftProbabilityPct.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Suspected Device: ${tap.suspectedDevice}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _metricChip('Surface Temp', '${tap.surfaceTempC.toStringAsFixed(1)}°C',
                  AppTheme.textPrimary),
              const SizedBox(width: 8),
              _metricChip('Ambient Ground', '${tap.ambientTempC.toStringAsFixed(1)}°C',
                  AppTheme.textSecondary),
              const SizedBox(width: 8),
              _metricChip('Thermal ΔT', '${tap.deltaTC > 0 ? '+' : ''}${tap.deltaTC.toStringAsFixed(1)}°C',
                  const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryLight),
                ),
                icon: const Icon(Icons.share_location_rounded,
                    size: 15, color: AppTheme.primaryLight),
                label: const Text('DISPATCH TAP INVESTIGATION SQUAD',
                    style: TextStyle(fontSize: 11, color: AppTheme.primaryLight)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFEF4444),
                      content: Text(
                          'Oil India Anti-Theft Task Force & CISF Squad dispatched to ${tap.chainageStr}.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          Text(value,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: PATROL & QUICK RESPONSE TEAM (QRT) DISPATCH
  // ==========================================================================

  Widget _buildSecurityPatrolTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Headquarters Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppTheme.primaryLight,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Oil India Pipeline Security Command',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '4 Quick Response Patrol Gangs • 25 CISF / Assam Police Personnel • 194.5 KM Corridor Protection',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Active QRT Gangs List
          const Text(
            'Security Patrol Gangs & Vehicle Fleet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ..._patrolGangs.map((gang) => _buildGangStatusCard(gang)),
          const SizedBox(height: 16),

          // Recent Dispatch Action Log
          const Text(
            'Recent Enforcement & Interception Log',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _buildEnforcementHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildGangStatusCard(SecurityPatrolGang gang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gang.isDispatched
              ? AppTheme.primaryLight
              : AppTheme.border,
          width: gang.isDispatched ? 1.5 : 1.0,
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
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: AppTheme.primaryLight, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          gang.callsign,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (gang.isDispatched
                                    ? AppTheme.secondary
                                    : AppTheme.tertiary)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            gang.isDispatched
                                ? 'ON ACTIVE MISSION'
                                : 'STANDBY AT POST',
                            style: TextStyle(
                              color: gang.isDispatched
                                  ? AppTheme.secondary
                                  : AppTheme.tertiary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      gang.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${gang.armedPersonnelCount} CISF Armed',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    gang.registrationNo,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoKeyValue('Station Base', gang.baseStation),
                _infoKeyValue('Commander', gang.commanderName),
                _infoKeyValue('Hotline', gang.contactPhone),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vehicle: ${gang.vehicleModel}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.tertiary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                icon: const Icon(Icons.phone_in_talk_rounded,
                    size: 14, color: AppTheme.tertiary),
                label: const Text('RADIO CALL',
                    style: TextStyle(fontSize: 10, color: AppTheme.tertiary)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.surfaceCard,
                      content: Text(
                          'Patching secure VHF/UHF tactical radio link to ${gang.commanderName} (${gang.callsign}).'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnforcementHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _enforcementLogRow(
            time: '08:42 IST',
            action: 'JCB Excavator Halted at KP 48+320',
            actor: 'RHINO-02 (Moran QRT)',
            status: 'Cease-Work Served',
          ),
          const Divider(color: AppTheme.border, height: 16),
          _enforcementLogRow(
            time: '06:15 IST',
            action: 'Illegal Hot-Tap Rig Seized at KP 62+180',
            actor: 'RHINO-02 & Assam Police',
            status: 'FIR Registered under P&MP Sec 15',
          ),
          const Divider(color: AppTheme.border, height: 16),
          _enforcementLogRow(
            time: 'Yesterday',
            action: 'Unauthorized Wall Demolished at KP 79+450',
            actor: 'CHEETAH-03 & Sivasagar Circle Officer',
            status: 'RoW Cleared',
          ),
        ],
      ),
    );
  }

  Widget _enforcementLogRow({
    required String time,
    required String action,
    required String actor,
    required String status,
  }) {
    return Row(
      children: [
        Text(
          time,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                actor,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.tertiary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.tertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 5: STATUTORY ROW COMPLIANCE & ANALYTICS
  // ==========================================================================

  Widget _buildStatutoryAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statutory RoW Compliance Score Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.surfaceCard,
                  AppTheme.surfaceContainerHigh,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Statutory RoW Integrity Index',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PNGRB COMPLIANT',
                        style: TextStyle(
                          color: AppTheme.tertiary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '194.5 KM Duliajan-Nagaon Corridor Statutory Protection Audit (P&MP Act 1957 & PNGRB T4S)',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _statBox(
                        'SURVEILLANCE COVERAGE',
                        '100%',
                        'Bi-Daily AI Passes',
                        AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBox(
                        'AVG INTERCEPT TIME',
                        '7.4 MIN',
                        'Target < 15 Min',
                        AppTheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBox(
                        'THEFT PREVENTED',
                        '₹4.82 CR',
                        '2026 Fiscal Year',
                        AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Encroachment Risk Heatmap by KP Segment
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Encroachment Threat Density along 194.5 KM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Identifies high-density third-party excavation and illegal tapping zones.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (val, meta) => Text(
                              '${val.toInt()}',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 9),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              const labels = [
                                'KP 0-45',
                                'KP 45-98',
                                'KP 98-142',
                                'KP 142-194'
                              ];
                              final idx = val.toInt();
                              if (idx >= 0 && idx < labels.length) {
                                return Text(labels[idx],
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 9));
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(
                            toY: 3,
                            color: AppTheme.tertiary,
                            width: 24,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ]),
                        BarChartGroupData(x: 1, barRods: [
                          BarChartRodData(
                            toY: 8,
                            color: const Color(0xFFEF4444),
                            width: 24,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ]),
                        BarChartGroupData(x: 2, barRods: [
                          BarChartRodData(
                            toY: 5,
                            color: AppTheme.secondary,
                            width: 24,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ]),
                        BarChartGroupData(x: 3, barRods: [
                          BarChartRodData(
                            toY: 2,
                            color: AppTheme.primaryLight,
                            width: 24,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Automated Drone Patrol Flight Scheduler
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Automated Drone Flight Schedule',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'DGCA / MoCA Approved',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _scheduleItem(
                  '06:00 IST — Morning Dawn Patrol',
                  'SkyGuard-Alpha (KP 0 to 98) • Optical & Thermal IR Scan',
                  'COMPLETED (100%)',
                  AppTheme.tertiary,
                ),
                const SizedBox(height: 8),
                _scheduleItem(
                  '14:00 IST — Midday Excavator Check',
                  'SkyGuard-Alpha (KP 45 to 98) • Active High-Risk Corridor',
                  'IN PROGRESS (ACTIVE)',
                  AppTheme.primaryLight,
                ),
                const SizedBox(height: 8),
                _scheduleItem(
                  '18:30 IST — Dusk Hydrocarbon Theft Patrol',
                  'AeroHawk-04 (KP 98 to 194.5) • Long-Wave Radiometric IR',
                  'SCHEDULED',
                  AppTheme.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(
      String title, String mainValue, String subtext, Color accent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mainValue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _scheduleItem(
      String timeTitle, String subtitle, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Key-Value row
  static Widget _infoKeyValue(String key, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          Text(val,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER: CORRIDOR RADAR & DRONE VISUAL MAP
// ============================================================================

class _CorridorRadarPainter extends CustomPainter {
  final double activeDroneChainageKm;
  final List<EncroachmentIncident> incidents;
  final List<SecurityPatrolGang> patrolGangs;
  final List<CorridorSector> sectors;
  final bool strobeActive;
  final int simulatedTick;

  _CorridorRadarPainter({
    required this.activeDroneChainageKm,
    required this.incidents,
    required this.patrolGangs,
    required this.sectors,
    required this.strobeActive,
    required this.simulatedTick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0D1832);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2E5C).withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Pipeline Corridor Centerline (Curving S-curve from left to right)
    final path = Path();

    final p0 = Offset(20, size.height * 0.7);
    final p1 = Offset(size.width * 0.3, size.height * 0.3);
    final p2 = Offset(size.width * 0.65, size.height * 0.8);
    final p3 = Offset(size.width - 20, size.height * 0.35);

    path.moveTo(p0.dx, p0.dy);
    path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);

    // Draw 30m Statutory Buffer Corridor (Translucent amber band)
    final bufferBandPaint = Paint()
      ..color = const Color(0xFFFFB95F).withValues(alpha: 0.08)
      ..strokeWidth = 44
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, bufferBandPaint);

    // Draw 5m Core Hazard Buffer (Translucent red band)
    final coreBandPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.12)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, coreBandPaint);

    // Draw Pipeline Centerline
    final pipePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, pipePaint);


    // Milepost Markers (KP 0, KP 45, KP 98, KP 142, KP 194.5)
    _drawMilepost(canvas, Offset(25, size.height * 0.7 + 16), 'Duliajan KP 0');
    _drawMilepost(
        canvas, Offset(size.width * 0.28, size.height * 0.34 - 12), 'Moran KP 45');
    _drawMilepost(canvas,
        Offset(size.width * 0.58, size.height * 0.78 + 14), 'Sivasagar KP 98');
    _drawMilepost(
        canvas, Offset(size.width * 0.78, size.height * 0.48), 'Jorhat KP 142');
    _drawMilepost(canvas, Offset(size.width - 65, size.height * 0.35 - 12),
        'Nagaon KP 194.5');

    // Draw Encroachments
    for (int i = 0; i < incidents.length; i++) {
      final inc = incidents[i];
      final t = (inc.chainageKm / 194.5).clamp(0.05, 0.95);
      final pt = _computeCubicPoint(p0, p1, p2, p3, t);

      // Offset slightly perpendicular to pipe based on buffer zone
      final offsetDirection = (i % 2 == 0 ? 1 : -1);
      final perpOffset = pt + Offset(0, offsetDirection * 14.0);

      final encPaint = Paint()
        ..color = inc.bufferZone.color
        ..style = PaintingStyle.fill;

      // Pulsing threat ring
      final pulseRadius = 7.0 + (simulatedTick % 3) * 1.5;
      final pulsePaint = Paint()
        ..color = inc.bufferZone.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(perpOffset, pulseRadius, pulsePaint);
      canvas.drawCircle(perpOffset, 4, encPaint);
    }

    // Draw QRT Vehicle Markers
    final qrtPt = _computeCubicPoint(p0, p1, p2, p3, 0.28) + const Offset(10, 22);
    final qrtPaint = Paint()..color = const Color(0xFF4EDEA3);
    canvas.drawRect(
        Rect.fromCenter(center: qrtPt, width: 8, height: 8), qrtPaint);

    // Draw Active Drone Position
    final droneT = (activeDroneChainageKm / 194.5).clamp(0.02, 0.98);
    final dronePos = _computeCubicPoint(p0, p1, p2, p3, droneT);

    // Drone Radar Sweep Ring
    final sweepPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(dronePos, 22, sweepPaint);

    // Strobe Alert Visual Wave
    if (strobeActive) {
      final strobePaint = Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(dronePos, 36, strobePaint);
    }

    // Drone Hexacopter Icon (Pulsing marker)
    final dronePaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawCircle(dronePos, 6, dronePaint);
    final centerDot = Paint()..color = Colors.white;
    canvas.drawCircle(dronePos, 2.5, centerDot);
  }

  void _drawMilepost(Canvas canvas, Offset pos, String text) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        backgroundColor: Color(0xCC0B1326),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, pos);
  }

  Offset _computeCubicPoint(
      Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    final x = uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
    final y = uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _CorridorRadarPainter oldDelegate) => true;
}

// ============================================================================
// CUSTOM PAINTER: AI CAMERA HUD & BOUNDING BOX VISUALIZER
// ============================================================================

class _AiCameraHudPainter extends CustomPainter {
  final EncroachmentIncident activeIncident;
  final bool strobeActive;
  final int tick;
  final String payloadMode;

  _AiCameraHudPainter({
    required this.activeIncident,
    required this.strobeActive,
    required this.tick,
    this.payloadMode = 'RGB',
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Simulated terrain background based on payload mode
    if (payloadMode == 'THERMAL_IR') {
      final bgPaint = Paint()..color = const Color(0xFF1E0C2C);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    } else if (payloadMode == 'SPLIT') {
      final rgbPaint = Paint()..color = const Color(0xFF132219);
      final irPaint = Paint()..color = const Color(0xFF1E0C2C);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width / 2, size.height), rgbPaint);
      canvas.drawRect(
          Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height), irPaint);
      final splitLinePaint = Paint()
        ..color = const Color(0xFF38BDF8)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height), splitLinePaint);
    } else {
      final bgPaint = Paint()..color = const Color(0xFF132219);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    }

    // Crosshairs & Center Reticle
    final reticlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawLine(
        Offset(center.dx - 20, center.dy), Offset(center.dx + 20, center.dy), reticlePaint);
    canvas.drawLine(
        Offset(center.dx, center.dy - 20), Offset(center.dx, center.dy + 20), reticlePaint);

    // Artificial Horizon / Pitch Ladder
    final horizonPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width * 0.25, center.dy - 25),
        Offset(size.width * 0.35, center.dy - 25), horizonPaint);
    canvas.drawLine(Offset(size.width * 0.65, center.dy - 25),
        Offset(size.width * 0.75, center.dy - 25), horizonPaint);

    // 30m Statutory Buffer Guideline on Ground Plane
    final bufferLinePaint = Paint()
      ..color = const Color(0xFFFFB95F).withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(40, size.height * 0.75),
        Offset(size.width - 40, size.height * 0.75), bufferLinePaint);

    // AI Bounding Box around target machinery
    final boxRect = Rect.fromCenter(
      center: Offset(center.dx + 25, center.dy + 15),
      width: 140,
      height: 90,
    );

    final boxPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(boxRect, boxPaint);

    // Corner brackets on bounding box
    final bracketPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 3;
    _drawCornerBrackets(canvas, boxRect, bracketPaint);

    // AI Confidence Tag
    final textSpan = TextSpan(
      text:
          'JCB 3DX EXCAVATOR [${activeIncident.aiConfidencePct.toStringAsFixed(1)}%]\nOFFSET: 4.2m FROM PIPELINE CL [CRITICAL BREACH]',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        backgroundColor: Color(0xCCEF4444),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
        canvas, Offset(boxRect.left, boxRect.top - 26));

    // Strobe flash visualizer
    if (strobeActive && tick % 2 == 0) {
      final flashPaint = Paint()..color = Colors.white.withValues(alpha: 0.18);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);
    }
  }

  void _drawCornerBrackets(Canvas canvas, Rect r, Paint p) {
    const len = 12.0;
    // Top-left
    canvas.drawLine(r.topLeft, r.topLeft + const Offset(len, 0), p);
    canvas.drawLine(r.topLeft, r.topLeft + const Offset(0, len), p);
    // Top-right
    canvas.drawLine(r.topRight, r.topRight + const Offset(-len, 0), p);
    canvas.drawLine(r.topRight, r.topRight + const Offset(0, len), p);
    // Bottom-left
    canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(len, 0), p);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(0, -len), p);
    // Bottom-right
    canvas.drawLine(r.bottomRight, r.bottomRight + const Offset(-len, 0), p);
    canvas.drawLine(r.bottomRight, r.bottomRight + const Offset(0, -len), p);
  }

  @override
  bool shouldRepaint(covariant _AiCameraHudPainter oldDelegate) => true;
}

// ============================================================================
// CUSTOM PAINTER: RADIOMETRIC THERMAL IR THEFT DETECTION
// ============================================================================

class _ThermalRadiometricPainter extends CustomPainter {
  final String colormap;
  final int tick;

  _ThermalRadiometricPainter({
    required this.colormap,
    required this.tick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background thermal gradient based on chosen colormap
    final bgPaint = Paint();
    if (colormap == 'White-Hot') {
      bgPaint.color = const Color(0xFF222222);
    } else if (colormap == 'Black-Hot') {
      bgPaint.color = const Color(0xFFEEEEEE);
    } else {
      // Ironbow / Rainbow
      bgPaint.color = const Color(0xFF1E0C2C);
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Warm Ambient Ground Soil Layer
    final soilGradient = RadialGradient(
      center: Alignment.center,
      radius: 0.9,
      colors: colormap == 'Rainbow'
          ? [const Color(0xFF550088), const Color(0xFF003366)]
          : [const Color(0xFF6B174F), const Color(0xFF280B3A)],
    );
    final soilPaint = Paint()
      ..shader = soilGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), soilPaint);

    // Pipeline Subsurface Centerline Line
    final pipePaint = Paint()
      ..color = const Color(0xFF882255)
      ..strokeWidth = 6;
    canvas.drawLine(Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5), pipePaint);

    // Chilled Thermal Anomaly (Illegal Tap Hole Joule-Thomson cooling plume)
    final tapCenter = Offset(size.width * 0.55, size.height * 0.5);
    final anomalyGradient = RadialGradient(
      center: Alignment.center,
      radius: 0.6,
      colors: [
        const Color(0xFF00E5FF), // Cold core (18.2°C)
        const Color(0xFF0055FF).withValues(alpha: 0.8),
        const Color(0xFF280B3A).withValues(alpha: 0.0),
      ],
    );
    final anomalyPaint = Paint()
      ..shader = anomalyGradient
          .createShader(Rect.fromCircle(center: tapCenter, radius: 45));
    canvas.drawCircle(tapCenter, 45, anomalyPaint);

    // Hot Excavation Engine Anomaly nearby
    final engineCenter = Offset(size.width * 0.35, size.height * 0.35);
    final engineGradient = RadialGradient(
      center: Alignment.center,
      radius: 0.6,
      colors: [
        const Color(0xFFFFEE00), // Hot spot (58°C)
        const Color(0xFFFF3300).withValues(alpha: 0.8),
        const Color(0xFF6B174F).withValues(alpha: 0.0),
      ],
    );
    final enginePaint = Paint()
      ..shader = engineGradient
          .createShader(Rect.fromCircle(center: engineCenter, radius: 25));
    canvas.drawCircle(engineCenter, 25, enginePaint);

    // Radiometric Crosshair Spot Meter at Illegal Tap
    final crosshairPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(tapCenter.dx - 12, tapCenter.dy),
        Offset(tapCenter.dx + 12, tapCenter.dy), crosshairPaint);
    canvas.drawLine(Offset(tapCenter.dx, tapCenter.dy - 12),
        Offset(tapCenter.dx, tapCenter.dy + 12), crosshairPaint);

    // Temperature Text Tag
    final textSpan = TextSpan(
      text: 'CHILLED TAP HOLE\n18.2°C (ΔT -10.4°C)',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        backgroundColor: Color(0xCC0055FF),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
        canvas, Offset(tapCenter.dx + 15, tapCenter.dy - 10));
  }

  @override
  bool shouldRepaint(covariant _ThermalRadiometricPainter oldDelegate) => true;
}
