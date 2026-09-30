import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS — TELECOM, OFC BACKBONE & SDH STM-4 NETWORK
// ============================================================================

/// ITU-T Fiber Standards & Construction Specification
enum FiberStandard {
  ituTG652D, // Single-mode low water peak zero-dispersion shifted
  ituTG655,  // Non-zero dispersion-shifted fiber (DWDM long haul)
}

/// Optical Core Tube Color Codes (EIA/TIA-598)
enum TubeColor {
  blue,
  orange,
  green,
  brown,
}

/// Operational Health Status of Fiber Cores & Nodes
enum LinkHealthStatus {
  normal,
  standby,
  attenuationWarning,
  fiberBreakCut,
  degraded,
}

/// OTDR Optical Event Classification
enum OtdrEventType {
  launchConnector,
  fusionSplice,
  mechanicalSplice,
  macroBending,
  reflectivePatch,
  fiberBreakCut,
  fiberEndFresnel,
}

/// SDH Ring Automatic Protection Switching (APS) State (ITU-T G.841)
enum SdhApsState {
  idleProtected,
  switchingActive,
  switchedToWestLine,
  switchedToEastLine,
  manualLockout,
}

/// Service Class of Bandwidth Tunnels on SDH Ring
enum ServiceClass {
  scadaTelemetry,
  cctvSurveillance,
  hotlineVoip,
  pagaAudioSystem,
  stationLanEthernet,
}

/// Repeater Power Source Mode
enum PowerSourceMode {
  solarPvActive,
  batteryFloat,
  dgAutoRunning,
  mainsGridHybrid,
}

// ----------------------------------------------------------------------------
// Core 24-Fiber Matrix Model
// ----------------------------------------------------------------------------
class OfcFiberCore {
  final int coreNumber; // 1 to 24
  final int tubeNumber; // 1 to 4
  final TubeColor tubeColor;
  final String tubeName;
  final FiberStandard standard;
  final String serviceAllocation;
  final ServiceClass? serviceClass;
  final LinkHealthStatus status;
  final double opticalPowerDbm; // Rx power e.g. -18.4 dBm
  final double attenuationDbPerKm; // e.g. 0.198 dB/km @ 1550nm
  final double totalSpanLossDb; // e.g. 38.5 dB
  final String connectorType; // e.g. FC/APC, SC/APC
  final bool isDarkFiber;
  final String patchPanelPort;

  const OfcFiberCore({
    required this.coreNumber,
    required this.tubeNumber,
    required this.tubeColor,
    required this.tubeName,
    this.standard = FiberStandard.ituTG652D,
    required this.serviceAllocation,
    this.serviceClass,
    required this.status,
    required this.opticalPowerDbm,
    required this.attenuationDbPerKm,
    required this.totalSpanLossDb,
    this.connectorType = 'FC/APC',
    this.isDarkFiber = false,
    required this.patchPanelPort,
  });

  Color get tubeUiColor {
    switch (tubeColor) {
      case TubeColor.blue:
        return const Color(0xFF0284C7);
      case TubeColor.orange:
        return const Color(0xFFFF9800);
      case TubeColor.green:
        return const Color(0xFF10B981);
      case TubeColor.brown:
        return const Color(0xFF8D6E63);
    }
  }

  Color get statusColor {
    switch (status) {
      case LinkHealthStatus.normal:
        return const Color(0xFF10B981);
      case LinkHealthStatus.standby:
        return const Color(0xFF38BDF8);
      case LinkHealthStatus.attenuationWarning:
        return const Color(0xFFFFB95F);
      case LinkHealthStatus.fiberBreakCut:
        return const Color(0xFFEF4444);
      case LinkHealthStatus.degraded:
        return const Color(0xFFF97316);
    }
  }

  String get statusLabel {
    switch (status) {
      case LinkHealthStatus.normal:
        return 'OPTIMAL';
      case LinkHealthStatus.standby:
        return 'HOT STANDBY';
      case LinkHealthStatus.attenuationWarning:
        return 'HIGH LOSS';
      case LinkHealthStatus.fiberBreakCut:
        return 'FIBER BREAK';
      case LinkHealthStatus.degraded:
        return 'DEGRADED';
    }
  }
}

// ----------------------------------------------------------------------------
// OTDR Reflectometer Event & Trace Model
// ----------------------------------------------------------------------------
class OtdrEvent {
  final int eventNumber;
  final double chainageKm; // Exact distance e.g. 78.432 km
  final double accuracyMarginM; // Accuracy tolerance e.g. ±3.8m (within ±5m spec)
  final OtdrEventType type;
  final double stepLossDb; // e.g. 0.042 dB (spec <= 0.05 dB)
  final double reflectanceDb; // e.g. -54.2 dB
  final double cumulativeLossDb;
  final double slopeDbPerKm;
  final String nearestStation;
  final String physicalLandmark;
  final bool isFault;

  const OtdrEvent({
    required this.eventNumber,
    required this.chainageKm,
    required this.accuracyMarginM,
    required this.type,
    required this.stepLossDb,
    required this.reflectanceDb,
    required this.cumulativeLossDb,
    required this.slopeDbPerKm,
    required this.nearestStation,
    required this.physicalLandmark,
    this.isFault = false,
  });

  String get typeLabel {
    switch (type) {
      case OtdrEventType.launchConnector:
        return 'Launch Connector (ODF)';
      case OtdrEventType.fusionSplice:
        return 'Fusion Splice Joint';
      case OtdrEventType.mechanicalSplice:
        return 'Mechanical Joint';
      case OtdrEventType.macroBending:
        return 'Macro-bend Stress Point';
      case OtdrEventType.reflectivePatch:
        return 'Intermediate Patch Panel';
      case OtdrEventType.fiberBreakCut:
        return 'TOTAL FIBER BREAK / CUT';
      case OtdrEventType.fiberEndFresnel:
        return 'Far-End Reflection (Fresnel)';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case OtdrEventType.launchConnector:
        return Icons.input_rounded;
      case OtdrEventType.fusionSplice:
        return Icons.link_rounded;
      case OtdrEventType.mechanicalSplice:
        return Icons.build_circle_rounded;
      case OtdrEventType.macroBending:
        return Icons.gesture_rounded;
      case OtdrEventType.reflectivePatch:
        return Icons.alt_route_rounded;
      case OtdrEventType.fiberBreakCut:
        return Icons.broken_image_rounded;
      case OtdrEventType.fiberEndFresnel:
        return Icons.output_rounded;
    }
  }

  Color get eventColor {
    if (isFault || type == OtdrEventType.fiberBreakCut) {
      return const Color(0xFFEF4444);
    }
    if (type == OtdrEventType.macroBending || stepLossDb > 0.1) {
      return const Color(0xFFFFB95F);
    }
    return const Color(0xFF4EDEA3);
  }
}

// ----------------------------------------------------------------------------
// SDH STM-4 Node & Station Model
// ----------------------------------------------------------------------------
class SdhStationNode {
  final String stationId;
  final String stationName;
  final double chainageKm;
  final String nodeRole; // CCR Master ADM, Reg/Terminal ADM, SV Substation ADM
  final double txOpticalPowerDbm;
  final double rxOpticalPowerEastDbm;
  final double rxOpticalPowerWestDbm;
  final double opticalMarginDb;
  final double bitErrorRate; // e.g. 1.2e-13
  final SdhApsState apsState;
  final double lastSwitchoverMs; // e.g. 26.4 ms (<50ms compliant)
  final bool hasRedundantPsu;
  final bool isLoopbackActive;

  const SdhStationNode({
    required this.stationId,
    required this.stationName,
    required this.chainageKm,
    required this.nodeRole,
    required this.txOpticalPowerDbm,
    required this.rxOpticalPowerEastDbm,
    required this.rxOpticalPowerWestDbm,
    required this.opticalMarginDb,
    required this.bitErrorRate,
    required this.apsState,
    required this.lastSwitchoverMs,
    this.hasRedundantPsu = true,
    this.isLoopbackActive = false,
  });

  Color get apsColor {
    switch (apsState) {
      case SdhApsState.idleProtected:
        return const Color(0xFF10B981);
      case SdhApsState.switchingActive:
        return const Color(0xFFFFB95F);
      case SdhApsState.switchedToWestLine:
      case SdhApsState.switchedToEastLine:
        return const Color(0xFF38BDF8);
      case SdhApsState.manualLockout:
        return const Color(0xFFEF4444);
    }
  }

  String get apsLabel {
    switch (apsState) {
      case SdhApsState.idleProtected:
        return 'SNCP DUAL-PATH NORMAL';
      case SdhApsState.switchingActive:
        return 'APS SWITCHING...';
      case SdhApsState.switchedToWestLine:
        return 'ACTIVE ON WEST RING';
      case SdhApsState.switchedToEastLine:
        return 'ACTIVE ON EAST RING';
      case SdhApsState.manualLockout:
        return 'LOCKOUT / REPAIR';
    }
  }
}

// ----------------------------------------------------------------------------
// SDH Bandwidth Allocation Tunnel Model
// ----------------------------------------------------------------------------
class SdhBandwidthTunnel {
  final String tunnelId;
  final String serviceName;
  final ServiceClass serviceClass;
  final String vcMapping; // e.g. 8 x VC-12, 2 x VC-4
  final double allocatedMbps;
  final double utilizedMbps;
  final double latencyMs;
  final double jitterMs;
  final double packetLossPct;
  final String priorityLevel; // P1 Hard Real-Time, P2 Mission Critical, P3 General
  final bool isHotStandbyProtected;

  const SdhBandwidthTunnel({
    required this.tunnelId,
    required this.serviceName,
    required this.serviceClass,
    required this.vcMapping,
    required this.allocatedMbps,
    required this.utilizedMbps,
    required this.latencyMs,
    required this.jitterMs,
    required this.packetLossPct,
    required this.priorityLevel,
    this.isHotStandbyProtected = true,
  });

  double get utilizationRatio => (utilizedMbps / allocatedMbps).clamp(0.0, 1.0);

  Color get serviceColor {
    switch (serviceClass) {
      case ServiceClass.scadaTelemetry:
        return const Color(0xFF0284C7);
      case ServiceClass.cctvSurveillance:
        return const Color(0xFF38BDF8);
      case ServiceClass.hotlineVoip:
        return const Color(0xFFFFB95F);
      case ServiceClass.pagaAudioSystem:
        return const Color(0xFFEF4444);
      case ServiceClass.stationLanEthernet:
        return const Color(0xFF4EDEA3);
    }
  }

  IconData get serviceIcon {
    switch (serviceClass) {
      case ServiceClass.scadaTelemetry:
        return Icons.settings_input_composite_rounded;
      case ServiceClass.cctvSurveillance:
        return Icons.videocam_rounded;
      case ServiceClass.hotlineVoip:
        return Icons.phone_in_talk_rounded;
      case ServiceClass.pagaAudioSystem:
        return Icons.campaign_rounded;
      case ServiceClass.stationLanEthernet:
        return Icons.router_rounded;
    }
  }
}

// ----------------------------------------------------------------------------
// Repeater Auxiliary Power Subsystem Model
// ----------------------------------------------------------------------------
class RepeaterAuxPowerData {
  final String stationId;
  final String stationName;
  final double chainageKm;
  final PowerSourceMode activeSource;
  // Solar PV Parameters
  final double solarPvArrayKw; // e.g. 4.8 kWp
  final double solarGenerationKw; // Current output e.g. 3.92 kW
  final double solarIrradianceWm2; // e.g. 840 W/m²
  final double pvString1Volts;
  final double pvString1Amps;
  final double pvString2Volts;
  final double pvString2Amps;
  final double mpptEfficiencyPct; // e.g. 98.6%
  final String mpptChargingState; // Bulk, Absorption, Float
  // 48V DC Telecom Battery Bank
  final double dcBusVoltage; // e.g. 53.6 V DC (Float nominal)
  final double batterySocPct; // 94.2%
  final double batterySohPct; // 98.8%
  final double batteryLoadCurrentAmps; // e.g. 24.8 A
  final double batteryAutonomyHoursRemaining; // e.g. 36.4 hrs
  final List<double> cellVoltages; // 24 cells for 48V bank
  // Backup Diesel Generator (DG)
  final String dgStatus; // Standby Auto-Ready, Cranking, Running, Cooldown
  final double dgFuelTankPct; // 88.5%
  final double dgFuelLitersRemaining; // 220 L
  final double dgCoolantTempC; // 42°C (Engine block heater active)
  final double dgCrankingBatteryVolts; // 12.8 V DC
  final double dgTotalRunHours; // 142.5 hrs
  final bool isAmfAutoReady;
  // Shelter Environment
  final double shelterTempC; // 21.4°C
  final double shelterHumidityPct; // 45%
  final bool isDoorSecured;
  final bool isFireSmokeNormal;

  const RepeaterAuxPowerData({
    required this.stationId,
    required this.stationName,
    required this.chainageKm,
    required this.activeSource,
    required this.solarPvArrayKw,
    required this.solarGenerationKw,
    required this.solarIrradianceWm2,
    required this.pvString1Volts,
    required this.pvString1Amps,
    required this.pvString2Volts,
    required this.pvString2Amps,
    required this.mpptEfficiencyPct,
    required this.mpptChargingState,
    required this.dcBusVoltage,
    required this.batterySocPct,
    required this.batterySohPct,
    required this.batteryLoadCurrentAmps,
    required this.batteryAutonomyHoursRemaining,
    required this.cellVoltages,
    required this.dgStatus,
    required this.dgFuelTankPct,
    required this.dgFuelLitersRemaining,
    required this.dgCoolantTempC,
    required this.dgCrankingBatteryVolts,
    required this.dgTotalRunHours,
    this.isAmfAutoReady = true,
    required this.shelterTempC,
    required this.shelterHumidityPct,
    this.isDoorSecured = true,
    this.isFireSmokeNormal = true,
  });

  Color get sourceColor {
    switch (activeSource) {
      case PowerSourceMode.solarPvActive:
        return const Color(0xFFFFB95F);
      case PowerSourceMode.batteryFloat:
        return const Color(0xFF4EDEA3);
      case PowerSourceMode.dgAutoRunning:
        return const Color(0xFFEF4444);
      case PowerSourceMode.mainsGridHybrid:
        return const Color(0xFF38BDF8);
    }
  }

  String get sourceLabel {
    switch (activeSource) {
      case PowerSourceMode.solarPvActive:
        return 'SOLAR PV ACTIVE (PRIMARY)';
      case PowerSourceMode.batteryFloat:
        return '48V DC BATTERY FLOAT';
      case PowerSourceMode.dgAutoRunning:
        return 'DG AUTO-STARTED (EMERGENCY)';
      case PowerSourceMode.mainsGridHybrid:
        return 'GRID / SOLAR HYBRID';
    }
  }
}

// ----------------------------------------------------------------------------
// Pipeline Trench Burial Profile Model
// ----------------------------------------------------------------------------
class TrenchSectionProfile {
  final String sectionId;
  final String startStation;
  final String endStation;
  final double startChainageKm;
  final double endChainageKm;
  final double measuredBurialDepthM; // Target: 1.50m (tolerance ±0.05m)
  final double sandBeddingThicknessMm; // 150mm
  final bool warningTilesIntact;
  final bool warningTapeTracerIntact;
  final int electronicMarkerRfidCount;
  final String soilStrata;
  final double groundCoverTempC;
  final DateTime lastInspectionDate;

  const TrenchSectionProfile({
    required this.sectionId,
    required this.startStation,
    required this.endStation,
    required this.startChainageKm,
    required this.endChainageKm,
    required this.measuredBurialDepthM,
    this.sandBeddingThicknessMm = 150.0,
    this.warningTilesIntact = true,
    this.warningTapeTracerIntact = true,
    required this.electronicMarkerRfidCount,
    required this.soilStrata,
    required this.groundCoverTempC,
    required this.lastInspectionDate,
  });

  bool get isDepthCompliant => measuredBurialDepthM >= 1.45 && measuredBurialDepthM <= 1.65;

  Color get depthColor => isDepthCompliant ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F);
}

// ============================================================================
// MAIN STATEFUL SCREEN WIDGET
// ============================================================================

class TelecomOfcScreen extends StatefulWidget {
  const TelecomOfcScreen({super.key});

  @override
  State<TelecomOfcScreen> createState() => _TelecomOfcScreenState();
}

class _TelecomOfcScreenState extends State<TelecomOfcScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _liveTelemetryTimer;
  bool _isAutoTelemetryStreaming = true;

  // Selected State Filters
  String _selectedStationFilter = 'ALL';
  int _selectedOtdrWavelengthNm = 1550; // 1310, 1550, 1625
  int _selectedOtdrFiberCore = 19; // Dark supervisory fiber (Cores 19-24)
  bool _isSimulatedBreakInjected = false;
  bool _isOtdrScanningInProgress = false;
  double _otdrScanProgress = 1.0;
  bool _isDgTestRunning = false;
  int _dgTestSecondsLeft = 0;
  Timer? _dgCountdownTimer;

  // Domain Datasets
  late List<OfcFiberCore> _fiberMatrix;
  late List<OtdrEvent> _otdrEvents;
  late List<SdhStationNode> _sdhNodes;
  late List<SdhBandwidthTunnel> _bandwidthTunnels;
  late List<RepeaterAuxPowerData> _repeaterStations;
  late List<TrenchSectionProfile> _trenchProfiles;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
    _startLiveTelemetryEngine();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _liveTelemetryTimer?.cancel();
    _dgCountdownTimer?.cancel();
    super.dispose();
  }

  void _startLiveTelemetryEngine() {
    _liveTelemetryTimer =
        Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted || !_isAutoTelemetryStreaming) return;
      setState(() {
        _jitterRealTimeTelemetry();
      });
    });
  }

  void _jitterRealTimeTelemetry() {
    final rand = math.Random();
    // Minor fluctuating readings for industrial realism
    for (int i = 0; i < _repeaterStations.length; i++) {
      final old = _repeaterStations[i];
      final solarJitter = (rand.nextDouble() - 0.5) * 0.08;
      final newIrradiance = (old.solarIrradianceWm2 + (rand.nextDouble() - 0.5) * 12.0)
          .clamp(600.0, 950.0);
      final newSolarKw = (old.solarGenerationKw + solarJitter).clamp(2.5, 4.8);
      final newBusVolts = (old.dcBusVoltage + (rand.nextDouble() - 0.5) * 0.05)
          .clamp(52.8, 54.2);

      _repeaterStations[i] = RepeaterAuxPowerData(
        stationId: old.stationId,
        stationName: old.stationName,
        chainageKm: old.chainageKm,
        activeSource: _isDgTestRunning ? PowerSourceMode.dgAutoRunning : old.activeSource,
        solarPvArrayKw: old.solarPvArrayKw,
        solarGenerationKw: newSolarKw,
        solarIrradianceWm2: newIrradiance,
        pvString1Volts: old.pvString1Volts + (rand.nextDouble() - 0.5) * 0.4,
        pvString1Amps: old.pvString1Amps + (rand.nextDouble() - 0.5) * 0.2,
        pvString2Volts: old.pvString2Volts + (rand.nextDouble() - 0.5) * 0.4,
        pvString2Amps: old.pvString2Amps + (rand.nextDouble() - 0.5) * 0.2,
        mpptEfficiencyPct: (98.4 + rand.nextDouble() * 0.5).clamp(97.5, 99.2),
        mpptChargingState: old.mpptChargingState,
        dcBusVoltage: newBusVolts,
        batterySocPct: old.batterySocPct,
        batterySohPct: old.batterySohPct,
        batteryLoadCurrentAmps: (old.batteryLoadCurrentAmps + (rand.nextDouble() - 0.5) * 0.3)
            .clamp(20.0, 32.0),
        batteryAutonomyHoursRemaining: old.batteryAutonomyHoursRemaining,
        cellVoltages: old.cellVoltages.map((v) => (v + (rand.nextDouble() - 0.5) * 0.003)).toList(),
        dgStatus: _isDgTestRunning ? 'RUNNING TEST (UNLOADED)' : old.dgStatus,
        dgFuelTankPct: old.dgFuelTankPct,
        dgFuelLitersRemaining: old.dgFuelLitersRemaining,
        dgCoolantTempC: _isDgTestRunning ? 72.0 : old.dgCoolantTempC,
        dgCrankingBatteryVolts: old.dgCrankingBatteryVolts,
        dgTotalRunHours: old.dgTotalRunHours,
        isAmfAutoReady: old.isAmfAutoReady,
        shelterTempC: (21.2 + rand.nextDouble() * 0.4).clamp(19.0, 24.0),
        shelterHumidityPct: (44.5 + rand.nextDouble() * 1.0).clamp(35.0, 60.0),
        isDoorSecured: old.isDoorSecured,
        isFireSmokeNormal: old.isFireSmokeNormal,
      );
    }
  }

  void _initializeData() {
    // 1. 24-Core OFC Allocation per ITU-T G.652D
    _fiberMatrix = [
      // Tube 1 (Blue) — SCADA & LDS Leak Detection
      const OfcFiberCore(
        coreNumber: 1,
        tubeNumber: 1,
        tubeColor: TubeColor.blue,
        tubeName: 'Tube 1 (Blue)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'SCADA Host Primary Ring (CCR to SVs)',
        serviceClass: ServiceClass.scadaTelemetry,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -17.8,
        attenuationDbPerKm: 0.198,
        totalSpanLossDb: 38.5,
        connectorType: 'FC/APC',
        patchPanelPort: 'ODF-01-P01',
      ),
      const OfcFiberCore(
        coreNumber: 2,
        tubeNumber: 1,
        tubeColor: TubeColor.blue,
        tubeName: 'Tube 1 (Blue)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'SCADA Host Secondary Hot-Standby',
        serviceClass: ServiceClass.scadaTelemetry,
        status: LinkHealthStatus.standby,
        opticalPowerDbm: -18.2,
        attenuationDbPerKm: 0.201,
        totalSpanLossDb: 39.1,
        connectorType: 'FC/APC',
        patchPanelPort: 'ODF-01-P02',
      ),
      const OfcFiberCore(
        coreNumber: 3,
        tubeNumber: 1,
        tubeColor: TubeColor.blue,
        tubeName: 'Tube 1 (Blue)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'LDS Fiber-Optic Acoustic Sensing (DAS)',
        serviceClass: ServiceClass.scadaTelemetry,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -16.4,
        attenuationDbPerKm: 0.195,
        totalSpanLossDb: 37.9,
        connectorType: 'SC/APC',
        patchPanelPort: 'ODF-01-P03',
      ),
      const OfcFiberCore(
        coreNumber: 4,
        tubeNumber: 1,
        tubeColor: TubeColor.blue,
        tubeName: 'Tube 1 (Blue)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'LDS Strain & Temperature Profile (DTS)',
        serviceClass: ServiceClass.scadaTelemetry,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -16.9,
        attenuationDbPerKm: 0.197,
        totalSpanLossDb: 38.3,
        connectorType: 'SC/APC',
        patchPanelPort: 'ODF-01-P04',
      ),
      const OfcFiberCore(
        coreNumber: 5,
        tubeNumber: 1,
        tubeColor: TubeColor.blue,
        tubeName: 'Tube 1 (Blue)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'SV ESDV Hardwired Inter-trip Loop A',
        serviceClass: ServiceClass.scadaTelemetry,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -18.6,
        attenuationDbPerKm: 0.202,
        totalSpanLossDb: 39.3,
        connectorType: 'FC/APC',
        patchPanelPort: 'ODF-01-P05',
      ),
      const OfcFiberCore(
        coreNumber: 6,
        tubeNumber: 1,
        tubeColor: TubeColor.blue,
        tubeName: 'Tube 1 (Blue)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'SV ESDV Hardwired Inter-trip Loop B',
        serviceClass: ServiceClass.scadaTelemetry,
        status: LinkHealthStatus.standby,
        opticalPowerDbm: -18.9,
        attenuationDbPerKm: 0.203,
        totalSpanLossDb: 39.5,
        connectorType: 'FC/APC',
        patchPanelPort: 'ODF-01-P06',
      ),

      // Tube 2 (Orange) — SDH STM-4 Main Transmission
      const OfcFiberCore(
        coreNumber: 7,
        tubeNumber: 2,
        tubeColor: TubeColor.orange,
        tubeName: 'Tube 2 (Orange)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'SDH STM-4 Line Transmit (East Line)',
        serviceClass: ServiceClass.stationLanEthernet,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -2.1,
        attenuationDbPerKm: 0.194,
        totalSpanLossDb: 37.7,
        connectorType: 'LC/PC',
        patchPanelPort: 'ODF-02-P01',
      ),
      const OfcFiberCore(
        coreNumber: 8,
        tubeNumber: 2,
        tubeColor: TubeColor.orange,
        tubeName: 'Tube 2 (Orange)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'SDH STM-4 Line Receive (East Line)',
        serviceClass: ServiceClass.stationLanEthernet,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -18.4,
        attenuationDbPerKm: 0.196,
        totalSpanLossDb: 38.1,
        connectorType: 'LC/PC',
        patchPanelPort: 'ODF-02-P02',
      ),
      const OfcFiberCore(
        coreNumber: 9,
        tubeNumber: 2,
        tubeColor: TubeColor.orange,
        tubeName: 'Tube 2 (Orange)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'SDH STM-4 Line Transmit (West Line)',
        serviceClass: ServiceClass.stationLanEthernet,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -1.9,
        attenuationDbPerKm: 0.195,
        totalSpanLossDb: 38.0,
        connectorType: 'LC/PC',
        patchPanelPort: 'ODF-02-P03',
      ),
      const OfcFiberCore(
        coreNumber: 10,
        tubeNumber: 2,
        tubeColor: TubeColor.orange,
        tubeName: 'Tube 2 (Orange)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'SDH STM-4 Line Receive (West Line)',
        serviceClass: ServiceClass.stationLanEthernet,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -17.9,
        attenuationDbPerKm: 0.197,
        totalSpanLossDb: 38.3,
        connectorType: 'LC/PC',
        patchPanelPort: 'ODF-02-P04',
      ),
      const OfcFiberCore(
        coreNumber: 11,
        tubeNumber: 2,
        tubeColor: TubeColor.orange,
        tubeName: 'Tube 2 (Orange)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'Fast Ethernet over SDH (EoS WAN)',
        serviceClass: ServiceClass.stationLanEthernet,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -19.1,
        attenuationDbPerKm: 0.204,
        totalSpanLossDb: 39.7,
        connectorType: 'SC/APC',
        patchPanelPort: 'ODF-02-P05',
      ),
      const OfcFiberCore(
        coreNumber: 12,
        tubeNumber: 2,
        tubeColor: TubeColor.orange,
        tubeName: 'Tube 2 (Orange)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'Engineering Service Channel (E1/E2 OW)',
        serviceClass: ServiceClass.stationLanEthernet,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -18.7,
        attenuationDbPerKm: 0.200,
        totalSpanLossDb: 38.9,
        connectorType: 'SC/APC',
        patchPanelPort: 'ODF-02-P06',
      ),

      // Tube 3 (Green) — CCTV, Hotline Telephony & PAGA System
      const OfcFiberCore(
        coreNumber: 13,
        tubeNumber: 3,
        tubeColor: TubeColor.green,
        tubeName: 'Tube 3 (Green)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'SV Station 4K CCTV Video Stream A',
        serviceClass: ServiceClass.cctvSurveillance,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -18.1,
        attenuationDbPerKm: 0.199,
        totalSpanLossDb: 38.7,
        connectorType: 'SC/APC',
        patchPanelPort: 'ODF-03-P01',
      ),
      const OfcFiberCore(
        coreNumber: 14,
        tubeNumber: 3,
        tubeColor: TubeColor.green,
        tubeName: 'Tube 3 (Green)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'SV Station 4K CCTV Video Stream B',
        serviceClass: ServiceClass.cctvSurveillance,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -18.3,
        attenuationDbPerKm: 0.201,
        totalSpanLossDb: 39.1,
        connectorType: 'SC/APC',
        patchPanelPort: 'ODF-03-P02',
      ),
      const OfcFiberCore(
        coreNumber: 15,
        tubeNumber: 3,
        tubeColor: TubeColor.green,
        tubeName: 'Tube 3 (Green)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'CCR Hotline IP Magneto Telephony A',
        serviceClass: ServiceClass.hotlineVoip,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -17.5,
        attenuationDbPerKm: 0.194,
        totalSpanLossDb: 37.8,
        connectorType: 'FC/APC',
        patchPanelPort: 'ODF-03-P03',
      ),
      const OfcFiberCore(
        coreNumber: 16,
        tubeNumber: 3,
        tubeColor: TubeColor.green,
        tubeName: 'Tube 3 (Green)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'CCR Hotline IP Magneto Telephony B',
        serviceClass: ServiceClass.hotlineVoip,
        status: LinkHealthStatus.standby,
        opticalPowerDbm: -17.7,
        attenuationDbPerKm: 0.196,
        totalSpanLossDb: 38.2,
        connectorType: 'FC/APC',
        patchPanelPort: 'ODF-03-P04',
      ),
      const OfcFiberCore(
        coreNumber: 17,
        tubeNumber: 3,
        tubeColor: TubeColor.green,
        tubeName: 'Tube 3 (Green)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'PAGA Emergency Siren & PA Broadcast A',
        serviceClass: ServiceClass.pagaAudioSystem,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -18.0,
        attenuationDbPerKm: 0.198,
        totalSpanLossDb: 38.6,
        connectorType: 'FC/APC',
        patchPanelPort: 'ODF-03-P05',
      ),
      const OfcFiberCore(
        coreNumber: 18,
        tubeNumber: 3,
        tubeColor: TubeColor.green,
        tubeName: 'Tube 3 (Green)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'PAGA Emergency Siren & PA Broadcast B',
        serviceClass: ServiceClass.pagaAudioSystem,
        status: LinkHealthStatus.standby,
        opticalPowerDbm: -18.4,
        attenuationDbPerKm: 0.200,
        totalSpanLossDb: 39.0,
        connectorType: 'FC/APC',
        patchPanelPort: 'ODF-03-P06',
      ),

      // Tube 4 (Brown) — Dark Supervisory Fibers for Continuous OTDR & Spares
      const OfcFiberCore(
        coreNumber: 19,
        tubeNumber: 4,
        tubeColor: TubeColor.brown,
        tubeName: 'Tube 4 (Brown)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'Continuous OTDR Online Dark Fiber (East)',
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -22.5,
        attenuationDbPerKm: 0.197,
        totalSpanLossDb: 38.3,
        connectorType: 'FC/APC',
        isDarkFiber: true,
        patchPanelPort: 'ODF-04-P01',
      ),
      const OfcFiberCore(
        coreNumber: 20,
        tubeNumber: 4,
        tubeColor: TubeColor.brown,
        tubeName: 'Tube 4 (Brown)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'Continuous OTDR Online Dark Fiber (West)',
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -22.9,
        attenuationDbPerKm: 0.199,
        totalSpanLossDb: 38.7,
        connectorType: 'FC/APC',
        isDarkFiber: true,
        patchPanelPort: 'ODF-04-P02',
      ),
      const OfcFiberCore(
        coreNumber: 21,
        tubeNumber: 4,
        tubeColor: TubeColor.brown,
        tubeName: 'Tube 4 (Brown)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'Dark Spare / Emergency Splice Reserve',
        status: LinkHealthStatus.standby,
        opticalPowerDbm: -24.0,
        attenuationDbPerKm: 0.198,
        totalSpanLossDb: 38.5,
        connectorType: 'FC/APC',
        isDarkFiber: true,
        patchPanelPort: 'ODF-04-P03',
      ),
      const OfcFiberCore(
        coreNumber: 22,
        tubeNumber: 4,
        tubeColor: TubeColor.brown,
        tubeName: 'Tube 4 (Brown)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'Dark Spare / Emergency Splice Reserve',
        status: LinkHealthStatus.standby,
        opticalPowerDbm: -24.2,
        attenuationDbPerKm: 0.201,
        totalSpanLossDb: 39.1,
        connectorType: 'FC/APC',
        isDarkFiber: true,
        patchPanelPort: 'ODF-04-P04',
      ),
      const OfcFiberCore(
        coreNumber: 23,
        tubeNumber: 4,
        tubeColor: TubeColor.brown,
        tubeName: 'Tube 4 (Brown)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'Third-Party National Gas Grid Carrier Lease',
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -18.2,
        attenuationDbPerKm: 0.196,
        totalSpanLossDb: 38.1,
        connectorType: 'LC/PC',
        isDarkFiber: false,
        patchPanelPort: 'ODF-04-P05',
      ),
      const OfcFiberCore(
        coreNumber: 24,
        tubeNumber: 4,
        tubeColor: TubeColor.brown,
        tubeName: 'Tube 4 (Brown)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'Third-Party National Gas Grid Carrier Lease',
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -18.5,
        attenuationDbPerKm: 0.198,
        totalSpanLossDb: 38.5,
        connectorType: 'LC/PC',
        isDarkFiber: false,
        patchPanelPort: 'ODF-04-P06',
      ),
    ];

    // 2. OTDR Continuous Reflected Events along 194.5 km route
    _otdrEvents = [
      const OtdrEvent(
        eventNumber: 1,
        chainageKm: 0.000,
        accuracyMarginM: 1.2,
        type: OtdrEventType.launchConnector,
        stepLossDb: 0.12,
        reflectanceDb: -42.8,
        cumulativeLossDb: 0.12,
        slopeDbPerKm: 0.198,
        nearestStation: 'CCR Duliajan',
        physicalLandmark: 'Telecom Room ODF Rack-01 Port 19',
      ),
      const OtdrEvent(
        eventNumber: 2,
        chainageKm: 24.620,
        accuracyMarginM: 2.1,
        type: OtdrEventType.fusionSplice,
        stepLossDb: 0.038,
        reflectanceDb: -62.4,
        cumulativeLossDb: 5.01,
        slopeDbPerKm: 0.197,
        nearestStation: 'SV-01 Tingkhong',
        physicalLandmark: 'Underground Joint Closure JC-01 (Trench Marker TM-24)',
      ),
      const OtdrEvent(
        eventNumber: 3,
        chainageKm: 48.350,
        accuracyMarginM: 3.4,
        type: OtdrEventType.fusionSplice,
        stepLossDb: 0.041,
        reflectanceDb: -61.8,
        cumulativeLossDb: 9.82,
        slopeDbPerKm: 0.199,
        nearestStation: 'SV-02 Moran',
        physicalLandmark: 'Underground Joint Closure JC-02 (Culvert Crossing)',
      ),
      const OtdrEvent(
        eventNumber: 4,
        chainageKm: 78.432,
        accuracyMarginM: 3.8, // ±3.8m accuracy within ±5m
        type: OtdrEventType.macroBending,
        stepLossDb: 0.380, // High attenuation event
        reflectanceDb: -58.2,
        cumulativeLossDb: 16.24,
        slopeDbPerKm: 0.245,
        nearestStation: 'SV-04 Dergaon/Bokakhat',
        physicalLandmark: 'NH-37 Highway HDD Boring Underpass Section',
        isFault: true,
      ),
      const OtdrEvent(
        eventNumber: 5,
        chainageKm: 112.800,
        accuracyMarginM: 2.8,
        type: OtdrEventType.fusionSplice,
        stepLossDb: 0.035,
        reflectanceDb: -63.1,
        cumulativeLossDb: 23.15,
        slopeDbPerKm: 0.196,
        nearestStation: 'CS-01 Numaligarh',
        physicalLandmark: 'Compressor Station Entrance Vault JC-05',
      ),
      const OtdrEvent(
        eventNumber: 6,
        chainageKm: 145.200,
        accuracyMarginM: 4.1,
        type: OtdrEventType.fusionSplice,
        stepLossDb: 0.044,
        reflectanceDb: -60.5,
        cumulativeLossDb: 29.68,
        slopeDbPerKm: 0.198,
        nearestStation: 'SV-05 Kaziranga Bypass',
        physicalLandmark: 'Joint Closure JC-07 Elevated Causeway',
      ),
      const OtdrEvent(
        eventNumber: 7,
        chainageKm: 172.950,
        accuracyMarginM: 3.2,
        type: OtdrEventType.fusionSplice,
        stepLossDb: 0.039,
        reflectanceDb: -62.0,
        cumulativeLossDb: 35.32,
        slopeDbPerKm: 0.197,
        nearestStation: 'SV-06 Jakhalabandha',
        physicalLandmark: 'Joint Closure JC-08 Railway Crossing ROW',
      ),
      const OtdrEvent(
        eventNumber: 8,
        chainageKm: 194.500,
        accuracyMarginM: 1.5,
        type: OtdrEventType.fiberEndFresnel,
        stepLossDb: 0.15,
        reflectanceDb: -38.5,
        cumulativeLossDb: 39.80,
        slopeDbPerKm: 0.198,
        nearestStation: 'Nagaon Terminal Station',
        physicalLandmark: 'Gas Terminal ODF Rack-02 Port 19 Terminator',
      ),
    ];

    // 3. SDH STM-4 Network Nodes (622.08 Mbps Ring)
    _sdhNodes = [
      const SdhStationNode(
        stationId: 'CCR-DUL',
        stationName: 'Central Control Room (Duliajan)',
        chainageKm: 0.0,
        nodeRole: 'Master Terminal Multiplexer (TM/ADM)',
        txOpticalPowerDbm: -2.0,
        rxOpticalPowerEastDbm: -18.4,
        rxOpticalPowerWestDbm: -17.9,
        opticalMarginDb: 11.6,
        bitErrorRate: 1.1e-13,
        apsState: SdhApsState.idleProtected,
        lastSwitchoverMs: 24.2,
      ),
      const SdhStationNode(
        stationId: 'SV-01',
        stationName: 'SV-01 Tingkhong Substation',
        chainageKm: 24.6,
        nodeRole: 'Optical Add-Drop Multiplexer (OADM)',
        txOpticalPowerDbm: -2.2,
        rxOpticalPowerEastDbm: -18.7,
        rxOpticalPowerWestDbm: -18.1,
        opticalMarginDb: 11.3,
        bitErrorRate: 1.4e-13,
        apsState: SdhApsState.idleProtected,
        lastSwitchoverMs: 27.8,
      ),
      const SdhStationNode(
        stationId: 'SV-02',
        stationName: 'SV-02 Moran Sectionalizing',
        chainageKm: 48.4,
        nodeRole: 'Optical Add-Drop Multiplexer (OADM)',
        txOpticalPowerDbm: -2.1,
        rxOpticalPowerEastDbm: -18.9,
        rxOpticalPowerWestDbm: -18.3,
        opticalMarginDb: 11.1,
        bitErrorRate: 1.8e-13,
        apsState: SdhApsState.idleProtected,
        lastSwitchoverMs: 26.1,
      ),
      const SdhStationNode(
        stationId: 'IP-01',
        stationName: 'IP-01 Sibsagar Intermediate Pigging',
        chainageKm: 68.2,
        nodeRole: 'Optical Add-Drop Multiplexer (OADM)',
        txOpticalPowerDbm: -2.3,
        rxOpticalPowerEastDbm: -19.2,
        rxOpticalPowerWestDbm: -18.5,
        opticalMarginDb: 10.8,
        bitErrorRate: 2.1e-13,
        apsState: SdhApsState.idleProtected,
        lastSwitchoverMs: 29.4,
      ),
      const SdhStationNode(
        stationId: 'CS-01',
        stationName: 'CS-01 Numaligarh Compressor Hub',
        chainageKm: 112.8,
        nodeRole: 'Regional Gateway Multiplexer (ADM)',
        txOpticalPowerDbm: -1.8,
        rxOpticalPowerEastDbm: -17.6,
        rxOpticalPowerWestDbm: -17.2,
        opticalMarginDb: 12.4,
        bitErrorRate: 0.9e-13,
        apsState: SdhApsState.idleProtected,
        lastSwitchoverMs: 21.5,
      ),
      const SdhStationNode(
        stationId: 'SV-04',
        stationName: 'SV-04 Dergaon/Bokakhat Valve Stn',
        chainageKm: 134.0,
        nodeRole: 'Optical Add-Drop Multiplexer (OADM)',
        txOpticalPowerDbm: -2.2,
        rxOpticalPowerEastDbm: -19.5,
        rxOpticalPowerWestDbm: -18.8,
        opticalMarginDb: 10.5,
        bitErrorRate: 3.4e-13,
        apsState: SdhApsState.idleProtected,
        lastSwitchoverMs: 28.0,
      ),
      const SdhStationNode(
        stationId: 'SV-06',
        stationName: 'SV-06 Jakhalabandha Substation',
        chainageKm: 172.9,
        nodeRole: 'Optical Add-Drop Multiplexer (OADM)',
        txOpticalPowerDbm: -2.1,
        rxOpticalPowerEastDbm: -18.6,
        rxOpticalPowerWestDbm: -18.2,
        opticalMarginDb: 11.4,
        bitErrorRate: 1.6e-13,
        apsState: SdhApsState.idleProtected,
        lastSwitchoverMs: 25.3,
      ),
      const SdhStationNode(
        stationId: 'TS-NAG',
        stationName: 'Nagaon Terminal Delivery Station',
        chainageKm: 194.5,
        nodeRole: 'Terminal Multiplexer (TM/ADM)',
        txOpticalPowerDbm: -2.0,
        rxOpticalPowerEastDbm: -18.3,
        rxOpticalPowerWestDbm: -17.8,
        opticalMarginDb: 11.7,
        bitErrorRate: 1.2e-13,
        apsState: SdhApsState.idleProtected,
        lastSwitchoverMs: 23.8,
      ),
    ];

    // 4. Bandwidth Allocation Tunnels on STM-4 (622 Mbps capacity)
    _bandwidthTunnels = [
      const SdhBandwidthTunnel(
        tunnelId: 'VC12-SCADA-01',
        serviceName: 'SCADA Telemetry & ESD Inter-Trip Control',
        serviceClass: ServiceClass.scadaTelemetry,
        vcMapping: '8 x VC-12 (E1 Equivalent)',
        allocatedMbps: 16.384,
        utilizedMbps: 11.240,
        latencyMs: 3.8,
        jitterMs: 0.6,
        packetLossPct: 0.00,
        priorityLevel: 'P1 Ultra Real-Time',
      ),
      const SdhBandwidthTunnel(
        tunnelId: 'VC4-CCTV-01',
        serviceName: 'Pipeline Perimeter 4K CCTV Video Security',
        serviceClass: ServiceClass.cctvSurveillance,
        vcMapping: '2 x VC-4 (Trunk Stream)',
        allocatedMbps: 310.000,
        utilizedMbps: 228.600,
        latencyMs: 14.5,
        jitterMs: 2.1,
        packetLossPct: 0.01,
        priorityLevel: 'P2 Mission Critical',
      ),
      const SdhBandwidthTunnel(
        tunnelId: 'VC12-VOIP-01',
        serviceName: 'CCR Hotline IP Magneto & Dispatch Telephony',
        serviceClass: ServiceClass.hotlineVoip,
        vcMapping: '4 x VC-12 (G.711 Voice)',
        allocatedMbps: 8.192,
        utilizedMbps: 4.850,
        latencyMs: 6.2,
        jitterMs: 0.9,
        packetLossPct: 0.00,
        priorityLevel: 'P1 Ultra Real-Time',
      ),
      const SdhBandwidthTunnel(
        tunnelId: 'VC12-PAGA-01',
        serviceName: 'Public Address & General Alarm (PAGA Audio)',
        serviceClass: ServiceClass.pagaAudioSystem,
        vcMapping: '2 x VC-12 (Broadcast Audio)',
        allocatedMbps: 4.096,
        utilizedMbps: 1.820,
        latencyMs: 2.9,
        jitterMs: 0.4,
        packetLossPct: 0.00,
        priorityLevel: 'P1 Emergency Priority',
      ),
      const SdhBandwidthTunnel(
        tunnelId: 'VC4-EOS-01',
        serviceName: 'RoW Cathodic Protection & Drone WAN (EoS)',
        serviceClass: ServiceClass.stationLanEthernet,
        vcMapping: '1 x VC-4 (Fast Ethernet WAN)',
        allocatedMbps: 155.520,
        utilizedMbps: 94.700,
        latencyMs: 18.2,
        jitterMs: 3.4,
        packetLossPct: 0.02,
        priorityLevel: 'P3 Standard IP',
      ),
    ];

    // 5. Unattended Telecom Repeater Stations & Auxiliary Power Systems
    _repeaterStations = [
      RepeaterAuxPowerData(
        stationId: 'RS-01',
        stationName: 'Repeater Station RS-01 (Tingkhong)',
        chainageKm: 24.6,
        activeSource: PowerSourceMode.solarPvActive,
        solarPvArrayKw: 4.8,
        solarGenerationKw: 3.92,
        solarIrradianceWm2: 840.0,
        pvString1Volts: 112.4,
        pvString1Amps: 18.2,
        pvString2Volts: 110.8,
        pvString2Amps: 17.5,
        mpptEfficiencyPct: 98.6,
        mpptChargingState: 'Float Charging (98.6%)',
        dcBusVoltage: 53.6,
        batterySocPct: 94.2,
        batterySohPct: 98.8,
        batteryLoadCurrentAmps: 24.8,
        batteryAutonomyHoursRemaining: 36.4,
        cellVoltages: List.generate(24, (i) => 2.23 + (i % 3) * 0.005),
        dgStatus: 'STANDBY AUTO-READY',
        dgFuelTankPct: 88.5,
        dgFuelLitersRemaining: 220.0,
        dgCoolantTempC: 42.0,
        dgCrankingBatteryVolts: 12.8,
        dgTotalRunHours: 142.5,
        shelterTempC: 21.4,
        shelterHumidityPct: 45.0,
      ),
      RepeaterAuxPowerData(
        stationId: 'RS-02',
        stationName: 'Repeater Station RS-02 (Moran)',
        chainageKm: 48.4,
        activeSource: PowerSourceMode.solarPvActive,
        solarPvArrayKw: 4.8,
        solarGenerationKw: 4.15,
        solarIrradianceWm2: 875.0,
        pvString1Volts: 114.1,
        pvString1Amps: 18.9,
        pvString2Volts: 112.5,
        pvString2Amps: 18.4,
        mpptEfficiencyPct: 98.8,
        mpptChargingState: 'Float Charging (98.8%)',
        dcBusVoltage: 53.8,
        batterySocPct: 96.0,
        batterySohPct: 99.1,
        batteryLoadCurrentAmps: 23.5,
        batteryAutonomyHoursRemaining: 38.2,
        cellVoltages: List.generate(24, (i) => 2.24 + (i % 2) * 0.004),
        dgStatus: 'STANDBY AUTO-READY',
        dgFuelTankPct: 92.0,
        dgFuelLitersRemaining: 230.0,
        dgCoolantTempC: 41.5,
        dgCrankingBatteryVolts: 12.9,
        dgTotalRunHours: 118.0,
        shelterTempC: 20.8,
        shelterHumidityPct: 43.5,
      ),
      RepeaterAuxPowerData(
        stationId: 'RS-03',
        stationName: 'Repeater Station RS-03 (Bokakhat)',
        chainageKm: 134.0,
        activeSource: PowerSourceMode.solarPvActive,
        solarPvArrayKw: 4.8,
        solarGenerationKw: 3.65,
        solarIrradianceWm2: 780.0,
        pvString1Volts: 108.9,
        pvString1Amps: 17.1,
        pvString2Volts: 107.4,
        pvString2Amps: 16.9,
        mpptEfficiencyPct: 98.2,
        mpptChargingState: 'Absorption Charging',
        dcBusVoltage: 53.4,
        batterySocPct: 91.5,
        batterySohPct: 97.4,
        batteryLoadCurrentAmps: 26.2,
        batteryAutonomyHoursRemaining: 34.0,
        cellVoltages: List.generate(24, (i) => 2.22 + (i % 4) * 0.006),
        dgStatus: 'STANDBY AUTO-READY',
        dgFuelTankPct: 84.0,
        dgFuelLitersRemaining: 210.0,
        dgCoolantTempC: 43.0,
        dgCrankingBatteryVolts: 12.7,
        dgTotalRunHours: 165.2,
        shelterTempC: 22.1,
        shelterHumidityPct: 47.0,
      ),
      RepeaterAuxPowerData(
        stationId: 'RS-04',
        stationName: 'Repeater Station RS-04 (Jakhalabandha)',
        chainageKm: 172.9,
        activeSource: PowerSourceMode.solarPvActive,
        solarPvArrayKw: 4.8,
        solarGenerationKw: 3.88,
        solarIrradianceWm2: 830.0,
        pvString1Volts: 111.7,
        pvString1Amps: 17.8,
        pvString2Volts: 110.2,
        pvString2Amps: 17.4,
        mpptEfficiencyPct: 98.5,
        mpptChargingState: 'Float Charging (98.5%)',
        dcBusVoltage: 53.5,
        batterySocPct: 93.8,
        batterySohPct: 98.2,
        batteryLoadCurrentAmps: 25.1,
        batteryAutonomyHoursRemaining: 35.8,
        cellVoltages: List.generate(24, (i) => 2.23 + (i % 3) * 0.004),
        dgStatus: 'STANDBY AUTO-READY',
        dgFuelTankPct: 86.5,
        dgFuelLitersRemaining: 216.0,
        dgCoolantTempC: 42.5,
        dgCrankingBatteryVolts: 12.8,
        dgTotalRunHours: 139.8,
        shelterTempC: 21.6,
        shelterHumidityPct: 46.0,
      ),
    ];

    // 6. Pipeline Trench Burial Cross-Sections along 194.5 KM Right-of-Way
    _trenchProfiles = [
      TrenchSectionProfile(
        sectionId: 'SEC-01',
        startStation: 'Duliajan CCR',
        endStation: 'SV-01 Tingkhong',
        startChainageKm: 0.0,
        endChainageKm: 24.6,
        measuredBurialDepthM: 1.52,
        electronicMarkerRfidCount: 124,
        soilStrata: 'Alluvial Loam & Silt (Compacted)',
        groundCoverTempC: 26.4,
        lastInspectionDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TrenchSectionProfile(
        sectionId: 'SEC-02',
        startStation: 'SV-01 Tingkhong',
        endStation: 'SV-02 Moran',
        startChainageKm: 24.6,
        endChainageKm: 48.4,
        measuredBurialDepthM: 1.48,
        electronicMarkerRfidCount: 118,
        soilStrata: 'Dense Clay with Fine Sand Matrix',
        groundCoverTempC: 25.8,
        lastInspectionDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
      TrenchSectionProfile(
        sectionId: 'SEC-03',
        startStation: 'SV-02 Moran',
        endStation: 'IP-01 Sibsagar',
        startChainageKm: 48.4,
        endChainageKm: 68.2,
        measuredBurialDepthM: 1.54,
        electronicMarkerRfidCount: 98,
        soilStrata: 'Tea Estate Humus & Red Silt',
        groundCoverTempC: 26.1,
        lastInspectionDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TrenchSectionProfile(
        sectionId: 'SEC-04',
        startStation: 'IP-01 Sibsagar',
        endStation: 'CS-01 Numaligarh',
        startChainageKm: 68.2,
        endChainageKm: 112.8,
        measuredBurialDepthM: 1.55,
        electronicMarkerRfidCount: 220,
        soilStrata: 'NH-37 HDD Crossings & Sandy Loam',
        groundCoverTempC: 27.2,
        lastInspectionDate: DateTime.now().subtract(const Duration(days: 4)),
      ),
      TrenchSectionProfile(
        sectionId: 'SEC-05',
        startStation: 'CS-01 Numaligarh',
        endStation: 'SV-04 Bokakhat',
        startChainageKm: 112.8,
        endChainageKm: 134.0,
        measuredBurialDepthM: 1.49,
        electronicMarkerRfidCount: 106,
        soilStrata: 'Brahmaputra Flood Plain Alluvium',
        groundCoverTempC: 26.8,
        lastInspectionDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TrenchSectionProfile(
        sectionId: 'SEC-06',
        startStation: 'SV-04 Bokakhat',
        endStation: 'Nagaon Terminal',
        startChainageKm: 134.0,
        endChainageKm: 194.5,
        measuredBurialDepthM: 1.51,
        electronicMarkerRfidCount: 302,
        soilStrata: 'Stiff Clayey Silt & Gravelly Sand',
        groundCoverTempC: 26.0,
        lastInspectionDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // INTERACTIVE ACTIONS & SIMULATIONS
  // --------------------------------------------------------------------------

  /// Trigger Continuous OTDR Diagnostic Scan on Dark Fiber Core
  void _triggerOtdrDiagnosticScan() {
    if (_isOtdrScanningInProgress) return;
    setState(() {
      _isOtdrScanningInProgress = true;
      _otdrScanProgress = 0.0;
    });

    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _otdrScanProgress += 0.05;
        if (_otdrScanProgress >= 1.0) {
          _otdrScanProgress = 1.0;
          _isOtdrScanningInProgress = false;
          timer.cancel();
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'OTDR sweep completed on Dark Fiber Core $_selectedOtdrFiberCore ($_selectedOtdrWavelengthNm nm). Link span 194.5 km verified within ±3.8m.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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

  /// Inject Simulated Fiber Cut / Break near KM 78.432 to test SDH APS failover
  void _toggleSimulateFiberCut() {
    setState(() {
      _isSimulatedBreakInjected = !_isSimulatedBreakInjected;

      if (_isSimulatedBreakInjected) {
        // Degrade fiber matrix
        _fiberMatrix = _fiberMatrix.map((core) {
          if (core.coreNumber == 7 || core.coreNumber == 8 || core.coreNumber == 19) {
            return OfcFiberCore(
              coreNumber: core.coreNumber,
              tubeNumber: core.tubeNumber,
              tubeColor: core.tubeColor,
              tubeName: core.tubeName,
              standard: core.standard,
              serviceAllocation: core.serviceAllocation,
              serviceClass: core.serviceClass,
              status: LinkHealthStatus.fiberBreakCut,
              opticalPowerDbm: -45.0,
              attenuationDbPerKm: 12.5,
              totalSpanLossDb: 60.0,
              connectorType: core.connectorType,
              patchPanelPort: core.patchPanelPort,
            );
          }
          return core;
        }).toList();

        // Switch SDH nodes to West line with <50ms APS
        _sdhNodes = _sdhNodes.map((node) {
          return SdhStationNode(
            stationId: node.stationId,
            stationName: node.stationName,
            chainageKm: node.chainageKm,
            nodeRole: node.nodeRole,
            txOpticalPowerDbm: node.txOpticalPowerDbm,
            rxOpticalPowerEastDbm: -45.0, // East broken
            rxOpticalPowerWestDbm: node.rxOpticalPowerWestDbm,
            opticalMarginDb: 9.8,
            bitErrorRate: 2.5e-12,
            apsState: SdhApsState.switchedToWestLine,
            lastSwitchoverMs: 28.4, // <50ms compliant
          );
        }).toList();

        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
            content: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'SIMULATION: Optical break injected at KM 78.432 (±3.8m). SDH SNCP APS automatically switched traffic to West Ring in 28.4 ms (<50ms).',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Restore normal link
        _initializeData();
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.restore_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Optical fiber link restored. SDH Ring back to protected dual-path state.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  /// Trigger DG Manual Test Start sequence
  void _triggerDgManualTest() {
    if (_isDgTestRunning) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Row(
          children: [
            Icon(Icons.power_settings_new_rounded, color: Color(0xFFFFB95F)),
            SizedBox(width: 10),
            Text('Repeater DG Auto-Exercise', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Initiate 15-second unloaded test cranking of the 15 kVA Silent Diesel Generator at Repeater RS-01 (Tingkhong)? This verifies AMF controller relay response, cranking voltage (12.8V DC), and engine governor speed without interrupting the 48V DC bus.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _runDgExerciseCountdown();
            },
            child: const Text('START DG TEST'),
          ),
        ],
      ),
    );
  }

  void _runDgExerciseCountdown() {
    setState(() {
      _isDgTestRunning = true;
      _dgTestSecondsLeft = 15;
    });

    _dgCountdownTimer?.cancel();
    _dgCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _dgTestSecondsLeft--;
        if (_dgTestSecondsLeft <= 0) {
          timer.cancel();
          _isDgTestRunning = false;
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              content: Text('DG test sequence completed. Engine returned to Standby Auto-Ready.'),
            ),
          );
        }
      });
    });
  }

  /// Show Full Telemetry Audit Export Dialog
  void _showExportReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 10),
            Text('Export Telecom Audit Report', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate consolidated ISO/IEC & ITU-T compliant telecom log including:\n\n'
              '• 24-Core OFC attenuation matrix (1310/1550/1625nm)\n'
              '• C-OTDR event table with ±3.8m localized splice logs\n'
              '• SDH STM-4 SNCP ring protection switch logs (<50ms)\n'
              '• Repeater solar PV generation, 48V DC battery string telemetry & DG AMF exercise records.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Signed with SHA-256 integrity hash for Oil India Pipeline Telemetry Audit.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('GENERATE PDF'),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF0284C7),
                  behavior: SnackBarBehavior.floating,
                  content: Text('Telecom & OFC Backbone report generated: TELECOM-OIL-2026-Q3.pdf'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // BUILD METHOD & ROOT SCAFFOLD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatusBanner(),
          _buildMetricChipsHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTab1TrenchAndBackbone(),
                _buildTab2OtdrTelemetry(),
                _buildTab3SdhRingNetwork(),
                _buildTab4RepeaterAuxPower(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // APP BAR & HEADER
  // --------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Telecom, OFC & SDH Network',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF0284C7), width: 0.8),
                ),
                child: const Text(
                  'STM-4 / 622M',
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
            'Pipeline Optical Fiber Backbone & Supervisory Communications',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Export Audit Report',
          icon: const Icon(Icons.file_download_outlined, color: AppTheme.textPrimary, size: 20),
          onPressed: _showExportReportDialog,
        ),
        IconButton(
          tooltip: _isAutoTelemetryStreaming ? 'Pause Live Telemetry' : 'Resume Telemetry',
          icon: Icon(
            _isAutoTelemetryStreaming ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
            color: _isAutoTelemetryStreaming ? const Color(0xFF4EDEA3) : AppTheme.textMuted,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _isAutoTelemetryStreaming = !_isAutoTelemetryStreaming;
            });
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textPrimary, size: 20),
          color: AppTheme.surfaceCard,
          onSelected: (val) {
            if (val == 'cut') _toggleSimulateFiberCut();
            if (val == 'otdr') _triggerOtdrDiagnosticScan();
            if (val == 'dg') _triggerDgManualTest();
            if (val == 'export') _showExportReportDialog();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'cut',
              child: Row(
                children: [
                  Icon(
                    _isSimulatedBreakInjected ? Icons.check_circle_outline : Icons.broken_image_outlined,
                    color: _isSimulatedBreakInjected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isSimulatedBreakInjected ? 'Restore Fiber Link' : 'Simulate Cable Cut (KM 78)',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'otdr',
              child: Row(
                children: [
                  Icon(Icons.radar_rounded, color: Color(0xFF0284C7), size: 18),
                  SizedBox(width: 8),
                  Text('Run OTDR Dark Fiber Sweep', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'dg',
              child: Row(
                children: [
                  Icon(Icons.power_settings_new_rounded, color: Color(0xFFFFB95F), size: 18),
                  SizedBox(width: 8),
                  Text('Test DG Auto-Crank', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF38BDF8), size: 18),
                  SizedBox(width: 8),
                  Text('Export Telecom Audit Report', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TOP INDUSTRIAL STATUS BANNER
  // --------------------------------------------------------------------------
  Widget _buildStatusBanner() {
    final isDegraded = _isSimulatedBreakInjected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDegraded
            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
            : const Color(0xFF0284C7).withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: isDegraded ? const Color(0xFFEF4444) : AppTheme.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDegraded
                  ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                  : const Color(0xFF10B981).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDegraded ? Icons.warning_rounded : Icons.check_circle_rounded,
              color: isDegraded ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isDegraded ? 'OFC RING FAULT: KM 78.432 ± 3.8m' : 'OFC DUAL-RING: SYNCHRONIZED',
                      style: TextStyle(
                        color: isDegraded ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isDegraded
                            ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                            : const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        isDegraded ? 'APS WEST ACTIVE (<50ms)' : 'SNCP PROTECTED',
                        style: TextStyle(
                          color: isDegraded ? Colors.white : const Color(0xFF4EDEA3),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isDegraded
                      ? 'Single-point cut localized near SV-04 Dergaon. Traffic maintained over West Ring.'
                      : '24-Core Armored SMF (ITU-T G.652D) plowed at depth 1.50m. All 4 tubes operational.',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          if (_isDgTestRunning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB95F).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFB95F)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFB95F)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DG TEST ${_dgTestSecondsLeft}s',
                    style: const TextStyle(color: Color(0xFFFFB95F), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // KEY TELEMETRY METRIC CHIPS HEADER
  // --------------------------------------------------------------------------
  Widget _buildMetricChipsHeader() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMetricChip(
              icon: Icons.linear_scale_rounded,
              label: 'Total Route Span',
              value: '194.5 KM',
              subtext: 'Duliajan to Nagaon',
              color: const Color(0xFF0284C7),
            ),
            const SizedBox(width: 8),
            _buildMetricChip(
              icon: Icons.layers_rounded,
              label: 'Trench Depth',
              value: '1.50 m',
              subtext: 'Warning Tiles 1.2m',
              color: const Color(0xFF10B981),
            ),
            const SizedBox(width: 8),
            _buildMetricChip(
              icon: Icons.cable_rounded,
              label: 'OFC Armor Spec',
              value: '24-Core SMF',
              subtext: 'ITU-T G.652.D',
              color: const Color(0xFF38BDF8),
            ),
            const SizedBox(width: 8),
            _buildMetricChip(
              icon: Icons.speed_rounded,
              label: 'SDH Capacity',
              value: 'STM-4 (622M)',
              subtext: '252 x E1 equiv',
              color: const Color(0xFFFFB95F),
            ),
            const SizedBox(width: 8),
            _buildMetricChip(
              icon: Icons.solar_power_rounded,
              label: 'Repeater Solar',
              value: '3.92 kW',
              subtext: '48V DC / 600Ah',
              color: const Color(0xFF4EDEA3),
            ),
            const SizedBox(width: 8),
            _buildMetricChip(
              icon: Icons.track_changes_rounded,
              label: 'OTDR Accuracy',
              value: '±3.8 m',
              subtext: 'Spec: within ±5m',
              color: const Color(0xFF818CF8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($subtext)',
                    style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 4 INDUSTRIAL TABS
  // --------------------------------------------------------------------------
  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(
            icon: Icon(Icons.cable_rounded, size: 18),
            text: 'OFC Backbone & Trench',
          ),
          Tab(
            icon: Icon(Icons.radar_rounded, size: 18),
            text: 'OTDR Fiber Health',
          ),
          Tab(
            icon: Icon(Icons.settings_ethernet_rounded, size: 18),
            text: 'SDH STM-4 Ring',
          ),
          Tab(
            icon: Icon(Icons.solar_power_rounded, size: 18),
            text: 'Repeater Power',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: 24-CORE OFC BACKBONE & TRENCH BURIAL ARCHITECTURE
  // ==========================================================================
  Widget _buildTab1TrenchAndBackbone() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Technical Specification Summary Card
        _buildOfcSpecificationCard(),
        const SizedBox(height: 16),

        // 2. Trench Cross-Section Graphic Schematic
        _buildTrenchCrossSectionCard(),
        const SizedBox(height: 16),

        // 3. 24-Core Fiber Allocation Matrix (4 Tubes)
        _build24CoreFiberMatrixCard(),
        const SizedBox(height: 16),

        // 4. Section-Wise Trench Burial Depth Telemetry
        _buildTrenchSectionTelemetryCard(),
      ],
    );
  }

  Widget _buildOfcSpecificationCard() {
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
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '24-Core Armored Single-Mode OFC Specification',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'ITU-T G.652.D Low Water Peak (Zero Dispersion @ 1312 nm)',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: const Text(
                  'OIL INDIA COMPLIANT',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSpecItem('Plow Depth', '1.50 m', 'Nominal target'),
              _buildSpecItem('Warning Tiles', '1.20 m', 'Reinforced Precast'),
              _buildSpecItem('Bedding', '150 mm', 'Clean Sand Cushion'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSpecItem('Attenuation @ 1550nm', '0.198 dB/km', 'Limit: ≤0.22 dB/km'),
              _buildSpecItem('Attenuation @ 1310nm', '0.334 dB/km', 'Limit: ≤0.36 dB/km'),
              _buildSpecItem('Armor Construction', 'Corrugated ECCS', 'Rodent / Termite Proof'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value, String sub) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }

  /// Custom Visual Trench Cross-Section Diagram
  Widget _buildTrenchCrossSectionCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pipeline Trench Burial Cross-Section Profile',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                'Trench Depth: 1.50m (Depth to Invert)',
                style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Cross-section vertical schematic
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _buildTrenchLayer(
                  depthLabel: '0.00 m (Ground Level)',
                  title: 'Finished RoW Ground Level & Grass Cover',
                  color: const Color(0xFF475569),
                  icon: Icons.terrain_rounded,
                  height: 28,
                ),
                const SizedBox(height: 4),
                _buildTrenchLayer(
                  depthLabel: '0.60 m Depth',
                  title: 'Warning Yellow HDPE Marker Tape with SS Tracer Wire',
                  color: const Color(0xFFEAB308),
                  icon: Icons.warning_amber_rounded,
                  height: 32,
                  isHighlight: true,
                ),
                const SizedBox(height: 4),
                _buildTrenchLayer(
                  depthLabel: '1.20 m Depth (300mm above OFC)',
                  title: 'Heavy-Duty Reinforced Concrete Warning Tiles ("OIL DANGER")',
                  color: const Color(0xFFDC2626),
                  icon: Icons.view_agenda_rounded,
                  height: 34,
                  isHighlight: true,
                ),
                const SizedBox(height: 4),
                _buildTrenchLayer(
                  depthLabel: '1.35 m Depth',
                  title: 'Clean Stone-Free River Sand Bedding (150mm thick padding)',
                  color: const Color(0xFFD97706),
                  icon: Icons.grain_rounded,
                  height: 28,
                ),
                const SizedBox(height: 4),
                _buildTrenchLayer(
                  depthLabel: '1.50 m Depth (Plow Level)',
                  title: '24-CORE ARMORED OPTICAL FIBER CABLE (ITU-T G.652D)',
                  color: const Color(0xFF0284C7),
                  icon: Icons.cable_rounded,
                  height: 38,
                  isCore: true,
                ),
                const SizedBox(height: 4),
                _buildTrenchLayer(
                  depthLabel: '1.80 m Depth',
                  title: '24" High-Pressure Natural Gas Pipeline (API 5L X70)',
                  color: const Color(0xFF1E293B),
                  icon: Icons.oil_barrel_rounded,
                  height: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrenchLayer({
    required String depthLabel,
    required String title,
    required Color color,
    required IconData icon,
    required double height,
    bool isHighlight = false,
    bool isCore = false,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isCore
            ? color.withValues(alpha: 0.3)
            : isHighlight
                ? color.withValues(alpha: 0.18)
                : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCore
              ? color
              : isHighlight
                  ? color.withValues(alpha: 0.7)
                  : AppTheme.border,
          width: isCore ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isCore ? Colors.white : AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: isCore ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Text(
            depthLabel,
            style: TextStyle(
              color: isCore ? const Color(0xFF38BDF8) : AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 24-Core Optical Fiber Allocation Matrix
  Widget _build24CoreFiberMatrixCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '24-Core Fiber Tube Allocation Matrix',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '4 Tubes x 6 Cores',
                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Group by Tube
          ...[TubeColor.blue, TubeColor.orange, TubeColor.green, TubeColor.brown].map((tube) {
            final coresInTube = _fiberMatrix.where((c) => c.tubeColor == tube).toList();
            final tubeName = coresInTube.isNotEmpty ? coresInTube.first.tubeName : 'Tube';
            final tubeUiColor = coresInTube.isNotEmpty ? coresInTube.first.tubeUiColor : Colors.blue;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: tubeUiColor.withValues(alpha: 0.4)),
                ),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                initiallyExpanded: tube == TubeColor.blue || tube == TubeColor.brown,
                tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: tubeUiColor,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  tubeName,
                  style: TextStyle(
                    color: tubeUiColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Cores ${coresInTube.first.coreNumber} - ${coresInTube.last.coreNumber} | ${coresInTube.where((c) => c.status == LinkHealthStatus.normal).length}/6 Active',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
                children: [
                  const Divider(color: AppTheme.border, height: 1),
                  ...coresInTube.map((core) => _buildCoreTile(core)),
                ],
              ),
            ),
          );
          }),
        ],
      ),
    );
  }

  Widget _buildCoreTile(OfcFiberCore core) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: core.tubeUiColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: core.tubeUiColor, width: 0.8),
            ),
            child: Text(
              '${core.coreNumber}',
              style: TextStyle(
                color: core.tubeUiColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  core.serviceAllocation,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${core.patchPanelPort} • ${core.connectorType}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${core.attenuationDbPerKm.toStringAsFixed(3)} dB/km',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${core.opticalPowerDbm.toStringAsFixed(1)} dBm',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: core.statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  core.statusLabel,
                  style: TextStyle(
                    color: core.statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section-Wise Trench Depth Telemetry Table
  Widget _buildTrenchSectionTelemetryCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Right-of-Way Trench Burial & Depth Inspection',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                'Depth Spec: 1.50m ± 0.05m',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 38,
              dataRowMaxHeight: 46,
              horizontalMargin: 10,
              columnSpacing: 18,
              columns: const [
                DataColumn(label: Text('Section', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Chainage', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Burial Depth', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Warning Tiles', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tracer Wire', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('RFID Markers', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Soil Type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
              rows: _trenchProfiles.map((sec) {
                return DataRow(
                  cells: [
                    DataCell(Text(sec.sectionId, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold))),
                    DataCell(Text('KM ${sec.startChainageKm.toStringAsFixed(1)} - ${sec.endChainageKm.toStringAsFixed(1)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_downward_rounded, color: sec.depthColor, size: 12),
                          const SizedBox(width: 4),
                          Text('${sec.measuredBurialDepthM.toStringAsFixed(2)} m', style: TextStyle(color: sec.depthColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('INTACT (1.2m)', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    DataCell(
                      const Text('Active (0.6m)', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10)),
                    ),
                    DataCell(
                      Text('${sec.electronicMarkerRfidCount} Balls', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11)),
                    ),
                    DataCell(
                      Text(sec.soilStrata, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: CONTINUOUS OTDR FIBER HEALTH & FAULT LOCALIZATION
  // ==========================================================================
  Widget _buildTab2OtdrTelemetry() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. OTDR Diagnostic Trigger & Wavelength Controls Card
        _buildOtdrControlBarCard(),
        const SizedBox(height: 16),

        // 2. Rayleigh Backscattering OTDR Trace Chart (fl_chart)
        _buildOtdrTraceChartCard(),
        const SizedBox(height: 16),

        // 3. Automated Fiber Break / Fault Localization Banner (±5m accuracy)
        _buildFaultLocalizationAlertBanner(),
        const SizedBox(height: 16),

        // 4. OTDR Continuous Events Table
        _buildOtdrEventsTableCard(),
      ],
    );
  }

  Widget _buildOtdrControlBarCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continuous OTDR Dark Fiber Telemetry',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Continuous optical time-domain reflectometer monitoring on dark fibers',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: _isOtdrScanningInProgress
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.radar_rounded, size: 16),
                label: Text(
                  _isOtdrScanningInProgress ? 'SCANNING...' : 'TRIGGER SCAN',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onPressed: _isOtdrScanningInProgress ? null : _triggerOtdrDiagnosticScan,
              ),
            ],
          ),
          if (_isOtdrScanningInProgress) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _otdrScanProgress,
                backgroundColor: AppTheme.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                minHeight: 6,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              // Wavelength Selector
              const Text('Wavelength: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ...[1310, 1550, 1625].map((wl) {
                final isSelected = _selectedOtdrWavelengthNm == wl;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedOtdrWavelengthNm = wl;
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0284C7) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF38BDF8) : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        '$wl nm${wl == 1625 ? ' (U-Band)' : ''}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Fiber Core Dropdown
              const Text('Dark Core: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButton<int>(
                  value: _selectedOtdrFiberCore,
                  underline: const SizedBox(),
                  dropdownColor: AppTheme.surfaceCard,
                  isDense: true,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                  items: [19, 20, 21, 22].map((coreNum) {
                    return DropdownMenuItem<int>(
                      value: coreNum,
                      child: Text('Core $coreNum (Dark)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedOtdrFiberCore = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// OTDR Rayleigh Backscattering Curve with fl_chart
  Widget _buildOtdrTraceChartCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rayleigh Backscattering Trace (dB vs KM)',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Index of Refraction (IOR): 1.4682 | Pulse Width: 100 ns',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF38BDF8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Trace (1550nm)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Fault Peak', style: TextStyle(color: Color(0xFFEF4444), fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart Container
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 10,
                  verticalInterval: 30,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: AppTheme.border.withValues(alpha: 0.5),
                    strokeWidth: 0.8,
                  ),
                  getDrawingVerticalLine: (val) => FlLine(
                    color: AppTheme.border.withValues(alpha: 0.5),
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Distance along Pipeline Right-of-Way (Kilometers)',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 30,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}k',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Relative Backscatter Level (dB)',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 10,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()} dB',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.border, width: 1),
                ),
                minX: 0,
                maxX: 195,
                minY: -55,
                maxY: 10,
                lineBarsData: [
                  _generateOtdrLineChartData(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CCR Duliajan (KM 0.0)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
              const Text('SV-02 Moran (KM 48)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
              Text(
                _isSimulatedBreakInjected ? 'FAULT @ KM 78.4 (±3.8m)' : 'SV-04 Dergaon (KM 78.4)',
                style: TextStyle(
                  color: _isSimulatedBreakInjected ? const Color(0xFFEF4444) : AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: _isSimulatedBreakInjected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Text('CS-01 Numaligarh (KM 112)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
              const Text('Nagaon Terminal (KM 194.5)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _generateOtdrLineChartData() {
    final points = <FlSpot>[];
    // Baseline launch
    points.add(const FlSpot(0, 0));
    points.add(const FlSpot(0.1, 4.2)); // Launch Fresnel peak
    points.add(const FlSpot(0.5, -0.2));

    // Slope from 0 to 24.6 (SV-01)
    points.add(const FlSpot(24.5, -4.8));
    points.add(const FlSpot(24.62, -4.84)); // Splice step
    points.add(const FlSpot(24.7, -4.88));

    // Slope from 24.6 to 48.35 (SV-02)
    points.add(const FlSpot(48.3, -9.5));
    points.add(const FlSpot(48.35, -9.54)); // Splice step
    points.add(const FlSpot(48.4, -9.58));

    // Point at KM 78.432 (High loss / Break point)
    points.add(const FlSpot(78.4, -15.5));
    if (_isSimulatedBreakInjected) {
      // Fresnel spike followed by sudden drop to noise floor
      points.add(const FlSpot(78.432, 6.5)); // Fresnel spike
      points.add(const FlSpot(78.5, -52.0)); // Drop to noise floor
      points.add(const FlSpot(194.5, -52.0));
    } else {
      // Normal minor macrobend step
      points.add(const FlSpot(78.432, -15.88));
      points.add(const FlSpot(112.8, -22.7));
      points.add(const FlSpot(145.2, -29.1));
      points.add(const FlSpot(172.9, -34.6));
      points.add(const FlSpot(194.4, -38.8));
      points.add(const FlSpot(194.5, -34.2)); // End Fresnel reflection
    }

    return LineChartBarData(
      spots: points,
      isCurved: false,
      color: _isSimulatedBreakInjected ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: (_isSimulatedBreakInjected ? const Color(0xFFEF4444) : const Color(0xFF0284C7))
            .withValues(alpha: 0.12),
      ),
    );
  }

  /// Automated Fiber Break & Fault Localization Alert Banner (within ±5m)
  Widget _buildFaultLocalizationAlertBanner() {
    final isFaultActive = _isSimulatedBreakInjected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFaultActive
            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
            : const Color(0xFFFFB95F).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFaultActive ? const Color(0xFFEF4444) : const Color(0xFFFFB95F),
          width: 1.2,
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
                  color: isFaultActive
                      ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                      : const Color(0xFFFFB95F).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isFaultActive ? Icons.broken_image_rounded : Icons.warning_amber_rounded,
                  color: isFaultActive ? const Color(0xFFEF4444) : const Color(0xFFFFB95F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFaultActive
                          ? 'AUTOMATED FIBER BREAK LOCALIZATION (KM ACCURACY ±3.8m)'
                          : 'SPLICE LOSS & MACRO-BEND ATTENUATION ALERT (±3.8m)',
                      style: TextStyle(
                        color: isFaultActive ? const Color(0xFFEF4444) : const Color(0xFFFFB95F),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFaultActive
                          ? 'Total Optical Signal Loss detected at Ch 78.432 km (±3.8m) — SV-04 Bokakhat HDD Crossing.'
                          : 'Event #4 at Ch 78.432 km (±3.8m): Step Loss 0.380 dB exceeds standard threshold (0.05 dB).',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFaultActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: _toggleSimulateFiberCut,
                child: Text(
                  isFaultActive ? 'RESTORE' : 'SIM BREAK',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed_rounded, color: Color(0xFF38BDF8), size: 14),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'GPS Geo-Coordinates: 26°38\'14.2"N 93°35\'28.9"E | Marker Ball RFID: MB-078-43',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  ),
                ),
                Text(
                  'Accuracy: ±3.8 m',
                  style: TextStyle(
                    color: isFaultActive ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
                    fontSize: 10,
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

  /// OTDR Continuous Reflectometer Events Table
  Widget _buildOtdrEventsTableCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Continuous OTDR Splice & Event Ledger',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                'Spec: Splice Loss ≤ 0.05 dB',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 38,
              dataRowMaxHeight: 46,
              horizontalMargin: 8,
              columnSpacing: 14,
              columns: const [
                DataColumn(label: Text('#', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Location (KM)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Accuracy', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Event Type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Loss (dB)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Reflectance', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Cumulative', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Landmark', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
              rows: _otdrEvents.map((evt) {
                final isFault = evt.isFault || (_isSimulatedBreakInjected && evt.eventNumber == 4);
                final lossColor = isFault ? const Color(0xFFEF4444) : (evt.stepLossDb > 0.05 ? const Color(0xFFFFB95F) : const Color(0xFF4EDEA3));

                return DataRow(
                  cells: [
                    DataCell(Text('${evt.eventNumber}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold))),
                    DataCell(Text('KM ${evt.chainageKm.toStringAsFixed(3)}', style: TextStyle(color: isFault ? const Color(0xFFEF4444) : AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
                    DataCell(Text('±${evt.accuracyMarginM.toStringAsFixed(1)} m', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(evt.typeIcon, color: evt.eventColor, size: 12),
                          const SizedBox(width: 4),
                          Text(evt.typeLabel, style: TextStyle(color: evt.eventColor, fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        '${evt.stepLossDb.toStringAsFixed(3)} dB',
                        style: TextStyle(color: lossColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text('${evt.reflectanceDb.toStringAsFixed(1)} dB', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10))),
                    DataCell(Text('${evt.cumulativeLossDb.toStringAsFixed(2)} dB', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10))),
                    DataCell(Text('${evt.nearestStation} — ${evt.physicalLandmark}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: SDH / STM-4 NETWORK RINGS & BANDWIDTH ALLOCATION
  // ==========================================================================
  Widget _buildTab3SdhRingNetwork() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. SDH STM-4 Protection Ring Overview
        _buildSdhRingTopologyCard(),
        const SizedBox(height: 16),

        // 2. Bandwidth Allocation & QoS Tunnels (SCADA, CCTV, Hotline IP, PAGA)
        _buildBandwidthAllocationCard(),
        const SizedBox(height: 16),

        // 3. Station SDH ADM Optical Node Telemetry
        _buildSdhNodeStationsCard(),
      ],
    );
  }

  Widget _buildSdhRingTopologyCard() {
    final isWestActive = _sdhNodes.any((n) => n.apsState == SdhApsState.switchedToWestLine);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SDH / STM-4 Synchronous Transmission Ring',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '622.08 Mbps (4 x STM-1 / 252 x E1) • 2-Fiber SNCP Protection',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isWestActive ? const Color(0xFFEF4444).withValues(alpha: 0.2) : const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isWestActive ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                ),
                child: Text(
                  isWestActive ? 'APS FAILOVER (<50ms)' : 'DUAL-RING SYNCHRONIZED',
                  style: TextStyle(
                    color: isWestActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ring Flow Schematic Box
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
                    _buildRingNodeBox('CCR Duliajan', 'Master TM', true),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFF38BDF8), size: 16),
                    _buildRingNodeBox('SV-01 / SV-02', 'Intermediate ADM', true),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFF38BDF8), size: 16),
                    _buildRingNodeBox('CS-01 Numaligarh', 'Regional Hub', true),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFF38BDF8), size: 16),
                    _buildRingNodeBox('Nagaon Terminal', 'Terminal TM', true),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isWestActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isWestActive ? 'East Fiber Line: SEVERED (KM 78)' : 'East Fiber Line: Tx -2.1 dBm / Rx -18.4 dBm (Normal)',
                            style: TextStyle(
                              color: isWestActive ? const Color(0xFFEF4444) : AppTheme.textPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'West Protected Line: ACTIVE (<50ms)',
                            style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSdhStatItem('Ring Capacity', '622.08 Mbps', 'STM-4 Payload'),
              _buildSdhStatItem('Switch Time (APS)', '24.2 ms', 'Spec: < 50 ms'),
              _buildSdhStatItem('Optical Margin', '+11.6 dB', 'Reserve Budget'),
              _buildSdhStatItem('Bit Error Rate', '1.1 × 10⁻¹³', 'Target: < 10⁻¹²'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRingNodeBox(String name, String role, bool isOnline) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isOnline ? const Color(0xFF0284C7) : AppTheme.border),
          ),
          child: Column(
            children: [
              Icon(Icons.router_rounded, color: isOnline ? const Color(0xFF38BDF8) : AppTheme.textMuted, size: 16),
              const SizedBox(height: 2),
              Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(role, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8)),
      ],
    );
  }

  Widget _buildSdhStatItem(String label, String value, String sub) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9)),
        ],
      ),
    );
  }

  /// Bandwidth Allocation & QoS Tunnels Card
  Widget _buildBandwidthAllocationCard() {
    final totalAllocated = _bandwidthTunnels.fold<double>(0, (sum, t) => sum + t.allocatedMbps);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bandwidth Allocation & Virtual Container (VC) Mapping',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                '${totalAllocated.toStringAsFixed(1)} / 622.0 Mbps Allocated',
                style: const TextStyle(color: Color(0xFF4EDEA3), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stacked Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: _bandwidthTunnels.map((tunnel) {
                  final flex = (tunnel.allocatedMbps / 6.22).round().clamp(1, 100);
                  return Flexible(
                    flex: flex,
                    child: Container(color: tunnel.serviceColor),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Tunnel Item List
          ..._bandwidthTunnels.map((tunnel) => _buildTunnelRow(tunnel)),
        ],
      ),
    );
  }

  Widget _buildTunnelRow(SdhBandwidthTunnel tunnel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tunnel.serviceColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(tunnel.serviceIcon, color: tunnel.serviceColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tunnel.serviceName,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: tunnel.serviceColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        tunnel.priorityLevel,
                        style: TextStyle(color: tunnel.serviceColor, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${tunnel.vcMapping} • Latency: ${tunnel.latencyMs} ms • Jitter: ${tunnel.jitterMs} ms',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tunnel.utilizedMbps.toStringAsFixed(1)} / ${tunnel.allocatedMbps.toStringAsFixed(1)} Mbps',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: tunnel.utilizationRatio,
                    backgroundColor: AppTheme.border,
                    valueColor: AlwaysStoppedAnimation<Color>(tunnel.serviceColor),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// SDH Node Stations Telemetry Table
  Widget _buildSdhNodeStationsCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SDH Add-Drop Multiplexer (ADM) Optical Telemetry',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                'APS Switchover Spec < 50ms',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 38,
              dataRowMaxHeight: 44,
              horizontalMargin: 8,
              columnSpacing: 14,
              columns: const [
                DataColumn(label: Text('Station', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Chainage', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tx Power', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Rx East Line', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Rx West Line', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('APS State', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('APS Time', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('BER', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
              rows: _sdhNodes.map((node) {
                return DataRow(
                  cells: [
                    DataCell(Text(node.stationName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold))),
                    DataCell(Text('KM ${node.chainageKm.toStringAsFixed(1)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10))),
                    DataCell(Text('${node.txOpticalPowerDbm.toStringAsFixed(1)} dBm', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10))),
                    DataCell(
                      Text(
                        '${node.rxOpticalPowerEastDbm.toStringAsFixed(1)} dBm',
                        style: TextStyle(
                          color: node.rxOpticalPowerEastDbm < -30 ? const Color(0xFFEF4444) : AppTheme.textPrimary,
                          fontSize: 10,
                          fontWeight: node.rxOpticalPowerEastDbm < -30 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    DataCell(Text('${node.rxOpticalPowerWestDbm.toStringAsFixed(1)} dBm', style: const TextStyle(color: Color(0xFF4EDEA3), fontSize: 10))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: node.apsColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          node.apsLabel,
                          style: TextStyle(color: node.apsColor, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${node.lastSwitchoverMs.toStringAsFixed(1)} ms',
                        style: const TextStyle(color: Color(0xFF4EDEA3), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text(node.bitErrorRate.toStringAsExponential(1), style: const TextStyle(color: AppTheme.textMuted, fontSize: 9))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: REPEATER STATION AUXILIARY POWER (SOLAR PV, 48V DC, DG)
  // ==========================================================================
  Widget _buildTab4RepeaterAuxPower() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Station Selector Dropdown
        _buildStationSelectorBar(),
        const SizedBox(height: 16),

        // 1. Solar PV Array Generation Subsystem
        _buildSolarPvSubsystemCard(),
        const SizedBox(height: 16),

        // 2. 48V DC Telecom Battery Bank & Cell Telemetry
        _build48vBatteryBankCard(),
        const SizedBox(height: 16),

        // 3. Backup Diesel Generator (DG) Auto-Start System
        _buildDgAutoStartCard(),
        const SizedBox(height: 16),

        // 4. Shelter Environmental & Physical Security Card
        _buildShelterEnvironmentCard(),
      ],
    );
  }

  Widget _buildStationSelectorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Repeater Station Location:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButton<String>(
              value: _selectedStationFilter,
              underline: const SizedBox(),
              dropdownColor: AppTheme.surfaceCard,
              isDense: true,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Repeater Stations (RS-01 to RS-04)')),
                DropdownMenuItem(value: 'RS-01', child: Text('RS-01 Tingkhong (KM 24.6)')),
                DropdownMenuItem(value: 'RS-02', child: Text('RS-02 Moran (KM 48.4)')),
                DropdownMenuItem(value: 'RS-03', child: Text('RS-03 Bokakhat (KM 134.0)')),
                DropdownMenuItem(value: 'RS-04', child: Text('RS-04 Jakhalabandha (KM 172.9)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedStationFilter = val;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  RepeaterAuxPowerData _getActiveStationData() {
    if (_selectedStationFilter == 'ALL' || _selectedStationFilter == 'RS-01') {
      return _repeaterStations.first;
    }
    return _repeaterStations.firstWhere(
      (s) => s.stationId == _selectedStationFilter,
      orElse: () => _repeaterStations.first,
    );
  }

  /// Solar PV Generation Array Card
  Widget _buildSolarPvSubsystemCard() {
    final site = _getActiveStationData();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB95F).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.solar_power_rounded, color: Color(0xFFFFB95F), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solar PV Generation Array (${site.stationId})',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Capacity: ${site.solarPvArrayKw} kWp Bifacial Monocrystalline',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: site.sourceColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: site.sourceColor),
                ),
                child: Text(
                  site.sourceLabel,
                  style: TextStyle(color: site.sourceColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildPowerMetric(
                label: 'PV Generation',
                value: '${site.solarGenerationKw.toStringAsFixed(2)} kW',
                sub: '${(site.solarGenerationKw / site.solarPvArrayKw * 100).toStringAsFixed(1)}% Capacity',
                color: const Color(0xFFFFB95F),
              ),
              _buildPowerMetric(
                label: 'Solar Irradiance',
                value: '${site.solarIrradianceWm2.toStringAsFixed(0)} W/m²',
                sub: 'Peak Sun Hours',
                color: const Color(0xFF38BDF8),
              ),
              _buildPowerMetric(
                label: 'MPPT Efficiency',
                value: '${site.mpptEfficiencyPct.toStringAsFixed(1)}%',
                sub: site.mpptChargingState,
                color: const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'String 1: ${site.pvString1Volts.toStringAsFixed(1)} V DC / ${site.pvString1Amps.toStringAsFixed(1)} A',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
                Text(
                  'String 2: ${site.pvString2Volts.toStringAsFixed(1)} V DC / ${site.pvString2Amps.toStringAsFixed(1)} A',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 48V DC Telecom Battery Bank & Cell Telemetry Card
  Widget _build48vBatteryBankCard() {
    final site = _getActiveStationData();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4EDEA3).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.battery_charging_full_rounded, color: Color(0xFF4EDEA3), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '48V DC Telecom Battery Bank (600Ah)',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Telecom Grade LiFePO4 / VRLA Gel (28.8 kWh Energy Reserve)',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${site.dcBusVoltage.toStringAsFixed(1)} V DC',
                style: const TextStyle(color: Color(0xFF4EDEA3), fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildPowerMetric(
                label: 'State of Charge (SoC)',
                value: '${site.batterySocPct.toStringAsFixed(1)}%',
                sub: 'Nominal 48V (Float 53.6V)',
                color: const Color(0xFF10B981),
              ),
              _buildPowerMetric(
                label: 'State of Health (SoH)',
                value: '${site.batterySohPct.toStringAsFixed(1)}%',
                sub: 'Cycle degradation 1.2%',
                color: const Color(0xFF38BDF8),
              ),
              _buildPowerMetric(
                label: 'Autonomy Remaining',
                value: '${site.batteryAutonomyHoursRemaining.toStringAsFixed(1)} Hrs',
                sub: 'Without Solar or DG',
                color: const Color(0xFFFFB95F),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 24 Cells Voltage Matrix
          const Text(
            'Individual 24-Cell String Voltages (Balance Delta ≤ 12 mV):',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: site.cellVoltages.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final volts = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  'C$idx: ${volts.toStringAsFixed(3)}V',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Backup Diesel Generator (DG) Auto-Start System Card
  Widget _buildDgAutoStartCard() {
    final site = _getActiveStationData();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.power_settings_new_rounded, color: Color(0xFFEF4444), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backup Diesel Generator (15 kVA Silent DG)',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'AMF Auto-Mains Failure Controller • Auto-Start on DC < 46.5V',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDgTestRunning ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 14),
                label: Text(
                  _isDgTestRunning ? 'TESTING...' : 'TEST CRANK',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                onPressed: _isDgTestRunning ? null : _triggerDgManualTest,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildPowerMetric(
                label: 'AMF Status',
                value: site.dgStatus,
                sub: 'Exercise Bi-Weekly',
                color: _isDgTestRunning ? const Color(0xFFFFB95F) : const Color(0xFF10B981),
              ),
              _buildPowerMetric(
                label: 'Fuel Day Tank',
                value: '${site.dgFuelTankPct.toStringAsFixed(1)}%',
                sub: '${site.dgFuelLitersRemaining.toStringAsFixed(0)} L (44h run)',
                color: const Color(0xFF38BDF8),
              ),
              _buildPowerMetric(
                label: 'Coolant Temp',
                value: '${site.dgCoolantTempC.toStringAsFixed(1)}°C',
                sub: 'Block Heater ON',
                color: const Color(0xFF4EDEA3),
              ),
              _buildPowerMetric(
                label: 'Crank Battery',
                value: '${site.dgCrankingBatteryVolts.toStringAsFixed(1)} V DC',
                sub: 'Run: ${site.dgTotalRunHours}h',
                color: const Color(0xFF818CF8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shelter Environmental & Intrusion Security
  Widget _buildShelterEnvironmentCard() {
    final site = _getActiveStationData();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Telecom Shelter Environmental & Physical Security',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                'Redundant Dual Inverter AC',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildEnvChip(
                icon: Icons.thermostat_rounded,
                label: 'Cabin Temp',
                value: '${site.shelterTempC.toStringAsFixed(1)}°C',
                status: 'Optimal (21±2°C)',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              _buildEnvChip(
                icon: Icons.water_drop_rounded,
                label: 'Humidity',
                value: '${site.shelterHumidityPct.toStringAsFixed(0)}%',
                status: 'Non-Condensing',
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 8),
              _buildEnvChip(
                icon: Icons.door_front_door_rounded,
                label: 'Door Security',
                value: site.isDoorSecured ? 'SECURED' : 'OPEN',
                status: 'Magnetic Sensor',
                color: site.isDoorSecured ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              _buildEnvChip(
                icon: Icons.local_fire_department_rounded,
                label: 'Fire / Smoke',
                value: site.isFireSmokeNormal ? 'CLEAR' : 'ALARM',
                status: 'Optical Sensor',
                color: site.isFireSmokeNormal ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnvChip({
    required IconData icon,
    required String label,
    required String value,
    required String status,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(status, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8)),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerMetric({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8)),
        ],
      ),
    );
  }
}
