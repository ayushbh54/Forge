import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';

// ============================================================================
// ENUMS & DOMAIN CONSTANTS
// ============================================================================

enum PigToolType {
  foamSwab,
  mechanicalScraper,
  caliperEgp,
  mflHighRes,
  ultrasonicUt,
}

extension PigToolTypeExt on PigToolType {
  String get displayName {
    switch (this) {
      case PigToolType.foamSwab:
        return 'Foam Swab & Batching Pig';
      case PigToolType.mechanicalScraper:
        return 'Wire Brush & Scraper Pig';
      case PigToolType.caliperEgp:
        return 'Geometric Caliper Tool (EGP)';
      case PigToolType.mflHighRes:
        return 'Magnetic Flux Leakage (MFL)';
      case PigToolType.ultrasonicUt:
        return 'Ultrasonic Phased Array (UT)';
    }
  }

  String get shortName {
    switch (this) {
      case PigToolType.foamSwab:
        return 'Foam Pig';
      case PigToolType.mechanicalScraper:
        return 'Cleaning Pig';
      case PigToolType.caliperEgp:
        return 'Caliper Pig';
      case PigToolType.mflHighRes:
        return 'MFL Tool';
      case PigToolType.ultrasonicUt:
        return 'UT Tool';
    }
  }

  IconData get icon {
    switch (this) {
      case PigToolType.foamSwab:
        return Icons.cleaning_services_rounded;
      case PigToolType.mechanicalScraper:
        return Icons.brush_rounded;
      case PigToolType.caliperEgp:
        return Icons.straighten_rounded;
      case PigToolType.mflHighRes:
        return Icons.graphic_eq_rounded;
      case PigToolType.ultrasonicUt:
        return Icons.waves_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PigToolType.foamSwab:
        return const Color(0xFF38BDF8); // Cyan
      case PigToolType.mechanicalScraper:
        return const Color(0xFFFFB95F); // Amber
      case PigToolType.caliperEgp:
        return const Color(0xFFC084FC); // Purple
      case PigToolType.mflHighRes:
        return const Color(0xFF4EDEA3); // Tertiary Green
      case PigToolType.ultrasonicUt:
        return const Color(0xFFF43F5E); // Rose
    }
  }

  double get optimalMinSpeed => switch (this) {
        PigToolType.foamSwab => 1.5,
        PigToolType.mechanicalScraper => 1.8,
        PigToolType.caliperEgp => 1.0,
        PigToolType.mflHighRes => 1.5,
        PigToolType.ultrasonicUt => 0.5,
      };

  double get optimalMaxSpeed => switch (this) {
        PigToolType.foamSwab => 4.5,
        PigToolType.mechanicalScraper => 3.5,
        PigToolType.caliperEgp => 3.0,
        PigToolType.mflHighRes => 3.0,
        PigToolType.ultrasonicUt => 1.5,
      };
}

enum PigRunStatus {
  inRun,
  scheduled,
  completed,
  standby,
  aborted,
}

extension PigRunStatusExt on PigRunStatus {
  String get label {
    switch (this) {
      case PigRunStatus.inRun:
        return 'IN-LINE ACTIVE';
      case PigRunStatus.scheduled:
        return 'SCHEDULED';
      case PigRunStatus.completed:
        return 'COMPLETED';
      case PigRunStatus.standby:
        return 'STANDBY';
      case PigRunStatus.aborted:
        return 'ABORTED';
    }
  }

  Color get color {
    switch (this) {
      case PigRunStatus.inRun:
        return const Color(0xFF4EDEA3);
      case PigRunStatus.scheduled:
        return const Color(0xFF38BDF8);
      case PigRunStatus.completed:
        return const Color(0xFF94A3B8);
      case PigRunStatus.standby:
        return const Color(0xFFFFB95F);
      case PigRunStatus.aborted:
        return const Color(0xFFEF4444);
    }
  }
}

enum PofMorphology {
  pinhole,
  pitting,
  generalMetalLoss,
  axialGroove,
  circumferentialGroove,
  plainDent,
  gougedDent,
  lamination,
}

extension PofMorphologyExt on PofMorphology {
  String get code {
    switch (this) {
      case PofMorphology.pinhole:
        return 'POF-PIN (1t x 1t)';
      case PofMorphology.pitting:
        return 'POF-PIT (1t to 3t)';
      case PofMorphology.generalMetalLoss:
        return 'POF-GEN (> 3t x 3t)';
      case PofMorphology.axialGroove:
        return 'POF-AXG (L>=3t, W<3t)';
      case PofMorphology.circumferentialGroove:
        return 'POF-CFG (L<3t, W>=3t)';
      case PofMorphology.plainDent:
        return 'POF-DNT (Smooth Dent)';
      case PofMorphology.gougedDent:
        return 'POF-DNTG (Dent + Gouge)';
      case PofMorphology.lamination:
        return 'POF-LAM (Laminar Inclusion)';
    }
  }

  String get label {
    switch (this) {
      case PofMorphology.pinhole:
        return 'Pinhole Metal Loss';
      case PofMorphology.pitting:
        return 'Pitting Corrosion';
      case PofMorphology.generalMetalLoss:
        return 'General Area Metal Loss';
      case PofMorphology.axialGroove:
        return 'Axial Grooving';
      case PofMorphology.circumferentialGroove:
        return 'Circumferential Grooving';
      case PofMorphology.plainDent:
        return 'Plain Geometric Dent';
      case PofMorphology.gougedDent:
        return 'Critical Dent with Gouge';
      case PofMorphology.lamination:
        return 'Mid-Wall Lamination';
    }
  }
}

enum WallSurface {
  internal,
  external,
  midWall,
}

extension WallSurfaceExt on WallSurface {
  String get label {
    switch (this) {
      case WallSurface.internal:
        return 'INTERNAL (ID)';
      case WallSurface.external:
        return 'EXTERNAL (OD)';
      case WallSurface.midWall:
        return 'MID-WALL';
    }
  }

  Color get color {
    switch (this) {
      case WallSurface.internal:
        return const Color(0xFFF43F5E); // Red
      case WallSurface.external:
        return const Color(0xFFFFB95F); // Amber
      case WallSurface.midWall:
        return const Color(0xFFC084FC); // Purple
    }
  }
}

enum ErfSeverity {
  safe,
  monitor,
  actionRequired,
}

extension ErfSeverityExt on ErfSeverity {
  String get label {
    switch (this) {
      case ErfSeverity.safe:
        return 'SAFE (ERF < 0.90)';
      case ErfSeverity.monitor:
        return 'MONITOR (0.90 ≤ ERF ≤ 1.00)';
      case ErfSeverity.actionRequired:
        return 'ACTION REQUIRED (ERF > 1.00)';
    }
  }

  Color get color {
    switch (this) {
      case ErfSeverity.safe:
        return const Color(0xFF4EDEA3);
      case ErfSeverity.monitor:
        return const Color(0xFFFFB95F);
      case ErfSeverity.actionRequired:
        return const Color(0xFFEF4444);
    }
  }
}

enum SignallerStatus {
  passed,
  activeDetecting,
  armedStandby,
  faultOffline,
}

extension SignallerStatusExt on SignallerStatus {
  String get label {
    switch (this) {
      case SignallerStatus.passed:
        return 'PIG PASSED';
      case SignallerStatus.activeDetecting:
        return 'SIGNAL ACTIVE';
      case SignallerStatus.armedStandby:
        return 'ARMED / STANDBY';
      case SignallerStatus.faultOffline:
        return 'FAULT / OFFLINE';
    }
  }

  Color get color {
    switch (this) {
      case SignallerStatus.passed:
        return const Color(0xFF38BDF8);
      case SignallerStatus.activeDetecting:
        return const Color(0xFF4EDEA3);
      case SignallerStatus.armedStandby:
        return const Color(0xFFFFB95F);
      case SignallerStatus.faultOffline:
        return const Color(0xFFEF4444);
    }
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class PigToolSpec {
  final String id;
  final String name;
  final PigToolType type;
  final String manufacturer;
  final String modelNo;
  final double weightKg;
  final double lengthMeters;
  final String minBendRadius;
  final double maxPressureBar;
  final int sensorCount;
  final String resolutionMm;
  final double batteryLifeHours;
  final String telemetrySystem;
  final String description;

  const PigToolSpec({
    required this.id,
    required this.name,
    required this.type,
    required this.manufacturer,
    required this.modelNo,
    required this.weightKg,
    required this.lengthMeters,
    required this.minBendRadius,
    required this.maxPressureBar,
    required this.sensorCount,
    required this.resolutionMm,
    required this.batteryLifeHours,
    required this.telemetrySystem,
    required this.description,
  });
}

class PigSignallerRecord {
  final String id;
  final String name;
  final double chainageKm;
  final String chainageStr;
  final String landmark;
  SignallerStatus status;
  final String sensorTechnology;
  DateTime? lastTripTime;
  double acousticDb;
  double magneticGauss;
  double batteryVoltage;
  int signalDbm;

  PigSignallerRecord({
    required this.id,
    required this.name,
    required this.chainageKm,
    required this.chainageStr,
    required this.landmark,
    required this.status,
    required this.sensorTechnology,
    this.lastTripTime,
    required this.acousticDb,
    required this.magneticGauss,
    required this.batteryVoltage,
    required this.signalDbm,
  });
}

class PofAnomalyRecord {
  final String id;
  final double chainageKm;
  final String chainageStr;
  final String spoolId;
  final String upstreamGirthWeld;
  final double distFromWeldMeters;
  final WallSurface wallSurface;
  final PofMorphology morphology;
  final double depthMm;
  final double nominalThicknessMm;
  final double lengthMm;
  final double widthMm;
  final int clockHour;
  final int clockMinute;
  final double dentDepthPctOd;
  final double pipeOdMm;
  final double designPressureBar;
  final double maopBar;
  final String jointDefectId;
  final String repairRecommendation;

  const PofAnomalyRecord({
    required this.id,
    required this.chainageKm,
    required this.chainageStr,
    required this.spoolId,
    required this.upstreamGirthWeld,
    required this.distFromWeldMeters,
    required this.wallSurface,
    required this.morphology,
    required this.depthMm,
    required this.nominalThicknessMm,
    required this.lengthMm,
    required this.widthMm,
    required this.clockHour,
    required this.clockMinute,
    this.dentDepthPctOd = 0.0,
    required this.pipeOdMm,
    required this.designPressureBar,
    required this.maopBar,
    required this.jointDefectId,
    required this.repairRecommendation,
  });

  double get depthPct => (depthMm / nominalThicknessMm) * 100.0;

  String get clockOrientationStr {
    final hStr = clockHour.toString().padLeft(2, '0');
    final mStr = clockMinute.toString().padLeft(2, '0');
    return "$hStr:$mStr o'clock";
  }

  // Folias Bulging Factor M calculation per ASME B31G / Modified B31G
  double get foliasM {
    final z = (lengthMm * lengthMm) / (pipeOdMm * nominalThicknessMm);
    if (z <= 50.0) {
      final inside = 1.0 + (0.6275 * z) - (0.003375 * z * z);
      return math.sqrt(math.max(1.0, inside));
    } else {
      return (0.032 * z) + 3.3;
    }
  }

  // Modified B31G Safe Operating Pressure P'_safe
  double get safePressureBar {
    final dt = depthMm / nominalThicknessMm;
    if (dt >= 0.80) return 0.0; // Critical flaw >80% WT
    final m = foliasM;
    final numerator = 1.0 - (0.85 * dt);
    final denominator = 1.0 - ((0.85 * dt) / m);
    if (denominator <= 0) return 0.0;
    // P_safe = 1.1 * P_design * (numerator / denominator)
    final pSafe = 1.1 * designPressureBar * (numerator / denominator);
    return math.min(designPressureBar * 1.1, pSafe);
  }

  // Estimated Repair Factor (ERF) = MAOP / P_safe
  double get erf {
    final pSafe = safePressureBar;
    if (pSafe <= 0.0) return 2.50; // Critical failure
    return maopBar / pSafe;
  }

  ErfSeverity get severity {
    if (dentDepthPctOd > 6.0 || depthPct >= 80.0 || erf > 1.0) {
      return ErfSeverity.actionRequired;
    } else if (erf >= 0.90 || depthPct >= 50.0 || dentDepthPctOd >= 2.0) {
      return ErfSeverity.monitor;
    } else {
      return ErfSeverity.safe;
    }
  }
}

class BarrelTelemetryData {
  final String stationCode;
  final String stationName;
  final String barrelType; // 'Launcher PL-01' or 'Receiver PR-01'
  final double chainageKm;
  final String barrelDimensions;
  double barrelPressureBar;
  double mainlinePressureBar;
  double kickerValvePct;
  bool isKickerValveOpen;
  bool isEqualizationValveOpen;
  bool isVentValveClosed;
  bool isDrainValveClosed;
  bool isDoorInterlockPinSafe;
  bool isPigPresentInTray;
  String interlockStatusDescription;

  BarrelTelemetryData({
    required this.stationCode,
    required this.stationName,
    required this.barrelType,
    required this.chainageKm,
    required this.barrelDimensions,
    required this.barrelPressureBar,
    required this.mainlinePressureBar,
    required this.kickerValvePct,
    required this.isKickerValveOpen,
    required this.isEqualizationValveOpen,
    required this.isVentValveClosed,
    required this.isDrainValveClosed,
    required this.isDoorInterlockPinSafe,
    required this.isPigPresentInTray,
    required this.interlockStatusDescription,
  });

  double get deltaP => (mainlinePressureBar - barrelPressureBar).abs();
}

// ============================================================================
// PIPELINE PIGGING SCREEN WIDGET
// ============================================================================

class PipelinePiggingScreen extends StatefulWidget {
  const PipelinePiggingScreen({super.key});

  @override
  State<PipelinePiggingScreen> createState() => _PipelinePiggingScreenState();
}

class _PipelinePiggingScreenState extends State<PipelinePiggingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _countdownTimer;

  // Pipeline Core Specifications (OIL Duliajan - Digboi Trunkline)
  final String _pipelineName = 'OIL Duliajan to Digboi Crude Oil Trunkline';
  final double _pipelineLengthKm = 54.800; // 54.8 km
  final double _nominalOdMm = 457.2; // 18-inch
  final double _nominalWallThicknessMm = 9.52; // 9.52 mm (API 5L X70)
  final double _designPressureBar = 98.0; // 98 Bar
  final double _maopBar = 88.2; // MAOP = 88.2 Bar

  // Hydraulics & Dynamic Flow Simulation State
  double _flowRateM3h = 1260.0; // Flow rate Q (m3/h)
  final double _pigToolSlippage = 0.018; // 1.8% bypass slippage
  double _currentPigLocationKm = 35.820; // Current KP position
  final int _batteryPercent = 88;
  final int _memoryWrittenGb = 148;
  final int _memoryTotalGb = 512;
  final double _diffPressureBar = 1.85;

  // Launch Timestamp & ETA simulation
  final DateTime _launchTime =
      DateTime.now().subtract(const Duration(hours: 4, minutes: 22));
  Duration _remainingEta = const Duration(hours: 2, minutes: 18, seconds: 42);

  // Selected Anomaly filter & detail
  String _anomalyFilter = 'ALL';
  PofAnomalyRecord? _selectedAnomaly;

  // Interactive B31G Calculator Form state
  double _calcDefectDepthMm = 4.50;
  double _calcDefectLengthMm = 110.0;
  final double _calcPipeOdMm = 457.2;
  final double _calcWallThicknessMm = 9.52;
  final double _calcMaopBar = 88.2;
  final String _calcStandard = 'Modified B31G (0.85dL)';

  // Launcher Safety Sequence Interactive Step
  int _launchSequenceStep = 3; // 0=Bleed, 1=Equalize, 2=Kicker, 3=Launched
  final bool _isSimulatingPumping = true;

  // --------------------------------------------------------------------------
  // TOOL SPECIFICATIONS DATA (5 Pig Classes)
  // --------------------------------------------------------------------------
  final List<PigToolSpec> _pigFleet = const [
    PigToolSpec(
      id: 'PIG-FS-01',
      name: 'AquaFoam Heavy Swab 18"',
      type: PigToolType.foamSwab,
      manufacturer: 'Girard Industries / Pro-Line',
      modelNo: 'F-HD-457-SWB',
      weightKg: 28.5,
      lengthMeters: 0.95,
      minBendRadius: '1.5D',
      maxPressureBar: 120.0,
      sensorCount: 0,
      resolutionMm: 'N/A (Mechanical Swab)',
      batteryLifeHours: 0,
      telemetrySystem: '128 kHz Acoustic Pinger Beacon',
      description:
          'High-density open-cell polyurethane foam swab with polyurethane cross-spiral coating. Used for dewatering post-hydrotest, drying, and pipeline swabbing.',
    ),
    PigToolSpec(
      id: 'PIG-MC-04',
      name: 'MagnoScrape HD Wire Brush 18"',
      type: PigToolType.mechanicalScraper,
      manufacturer: 'TDW (T.D. Williamson)',
      modelNo: 'VANTAGE-WB-18',
      weightKg: 145.0,
      lengthMeters: 1.45,
      minBendRadius: '1.5D',
      maxPressureBar: 150.0,
      sensorCount: 4,
      resolutionMm: 'Debris Collection',
      batteryLifeHours: 72,
      telemetrySystem: 'Magnetic Flux Transponder & Pinger',
      description:
          'Multi-disc heavy-duty scraper with hardened carbon steel circular wire brushes, bypass jetting nose, and 12-cluster NdFeB rare-earth permanent magnets collecting up to 30 kg ferrous scale.',
    ),
    PigToolSpec(
      id: 'PIG-CAL-02',
      name: 'GeoScan-36 High-Res Caliper EGP',
      type: PigToolType.caliperEgp,
      manufacturer: 'Baker Hughes / Waygate',
      modelNo: 'CAL-EGP-18-36CH',
      weightKg: 210.0,
      lengthMeters: 2.10,
      minBendRadius: '1.5D',
      maxPressureBar: 135.0,
      sensorCount: 36,
      resolutionMm: '0.1% OD (0.45 mm)',
      batteryLifeHours: 120,
      telemetrySystem: 'Dual Multi-frequency Transponder',
      description:
          '36 independent spring-loaded mechanical caliper fingers with contactless rotary magnetic encoders. Accurately profiles pipe ovality, geometric dents, wrinkles, and bends per POF 2016.',
    ),
    PigToolSpec(
      id: 'PIG-MFL-08',
      name: 'MFL-Max Tri-Axial Ultra 18"',
      type: PigToolType.mflHighRes,
      manufacturer: 'Rosen Group / Pipetronix',
      modelNo: 'ROCORR-MFL-A-18',
      weightKg: 460.0,
      lengthMeters: 3.40,
      minBendRadius: '3.0D',
      maxPressureBar: 150.0,
      sensorCount: 256,
      resolutionMm: 'Axial 1.2mm, Circumferential 3.5mm',
      batteryLifeHours: 96,
      telemetrySystem: 'Acoustic / Magnetic / EM Triangulation',
      description:
          'High-resolution tri-axial Hall-effect sensor array (Radial, Axial, Circumferential) with high-coercivity NdFeB magnetic yoke. Distinguishes internal vs external metal loss, pitting, and grooving.',
    ),
    PigToolSpec(
      id: 'PIG-UT-03',
      name: 'UltraScan Duo Phased Array UT',
      type: PigToolType.ultrasonicUt,
      manufacturer: 'NDT Global / Linz',
      modelNo: 'UM-PA-18-128',
      weightKg: 520.0,
      lengthMeters: 3.85,
      minBendRadius: '3.0D',
      maxPressureBar: 160.0,
      sensorCount: 128,
      resolutionMm: 'Wall Thickness ±0.1 mm, Crack 1.0mm',
      batteryLifeHours: 72,
      telemetrySystem: 'High-speed acoustic carrier + IMU',
      description:
          '128-transducer piezoelectric phased-array ultrasonic tool for direct pipe wall thickness measurement, mid-wall laminar defects, and longitudinal Stress Corrosion Cracking (SCC) detection.',
    ),
  ];

  // --------------------------------------------------------------------------
  // BARREL TELEMETRY (PL-01 Duliajan & PR-01 Digboi)
  // --------------------------------------------------------------------------
  late BarrelTelemetryData _launcherBarrel;
  late BarrelTelemetryData _receiverBarrel;

  // --------------------------------------------------------------------------
  // PIG PASSAGE SIGNALLERS (SP-01 to SP-06)
  // --------------------------------------------------------------------------
  late List<PigSignallerRecord> _signallers;

  // --------------------------------------------------------------------------
  // POF PIPE WALL ANOMALIES REGISTER
  // --------------------------------------------------------------------------
  late List<PofAnomalyRecord> _anomalies;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    _initTelemetryData();
    _startLiveCountdownTicker();
  }

  void _initTelemetryData() {
    _launcherBarrel = BarrelTelemetryData(
      stationCode: 'PL-01',
      stationName: 'Duliajan Pump Station Dispatch Terminal',
      barrelType: 'Pig Launcher Barrel PL-01',
      chainageKm: 0.000,
      barrelDimensions: '22" x 18" Eccentric Reducer, Class 600',
      barrelPressureBar: 82.1,
      mainlinePressureBar: 82.4,
      kickerValvePct: 100.0,
      isKickerValveOpen: true,
      isEqualizationValveOpen: true,
      isVentValveClosed: true,
      isDrainValveClosed: true,
      isDoorInterlockPinSafe: true,
      isPigPresentInTray: false, // Launched
      interlockStatusDescription:
          'ASME Sec VIII Div 1 Trapped Key LOCKED & ARMED (Key B-01 captive)',
    );

    _receiverBarrel = BarrelTelemetryData(
      stationCode: 'PR-01',
      stationName: 'Digboi Refinery Receiving Terminal',
      barrelType: 'Pig Receiver Barrel PR-01',
      chainageKm: 54.800,
      barrelDimensions: '22" x 18" Concentric Reducer, Class 600',
      barrelPressureBar: 74.6,
      mainlinePressureBar: 74.8,
      kickerValvePct: 35.0, // Throttled for back-pressure cushioning
      isKickerValveOpen: true,
      isEqualizationValveOpen: true,
      isVentValveClosed: true,
      isDrainValveClosed: true,
      isDoorInterlockPinSafe: true,
      isPigPresentInTray: false, // Awaiting arrival
      interlockStatusDescription:
          'ASME Sec VIII Div 1 Trapped Key LOCKED & ARMED (Buffer Spring Primed)',
    );

    _signallers = [
      PigSignallerRecord(
        id: 'SP-01',
        name: 'Launcher Neck Signaller',
        chainageKm: 0.250,
        chainageStr: 'KP 0+250',
        landmark: 'PL-01 Discharge Manifold',
        status: SignallerStatus.passed,
        sensorTechnology: 'Intrusive Flag + Acoustic Sensor',
        lastTripTime: _launchTime.add(const Duration(minutes: 2)),
        acousticDb: 88.5,
        magneticGauss: 1240.0,
        batteryVoltage: 3.65,
        signalDbm: -62,
      ),
      PigSignallerRecord(
        id: 'SP-02',
        name: 'Burhi Dihing River HDD Entry',
        chainageKm: 11.420,
        chainageStr: 'KP 11+420',
        landmark: 'HDD North Bank Crossing',
        status: SignallerStatus.passed,
        sensorTechnology: 'Non-Intrusive Magnetic + Acoustic',
        lastTripTime: _launchTime.add(const Duration(hours: 1, minutes: 28)),
        acousticDb: 82.1,
        magneticGauss: 1110.0,
        batteryVoltage: 3.62,
        signalDbm: -71,
      ),
      PigSignallerRecord(
        id: 'SP-03',
        name: 'Valve Station VS-03 Signaller',
        chainageKm: 22.850,
        chainageStr: 'KP 22+850',
        landmark: 'Deohall Reserve Forest Edge',
        status: SignallerStatus.passed,
        sensorTechnology: 'Non-Intrusive Magnetometer',
        lastTripTime: _launchTime.add(const Duration(hours: 2, minutes: 48)),
        acousticDb: 79.4,
        magneticGauss: 980.0,
        batteryVoltage: 3.60,
        signalDbm: -68,
      ),
      PigSignallerRecord(
        id: 'SP-04',
        name: 'Midway Booster Station Signaller',
        chainageKm: 34.600,
        chainageStr: 'KP 34+600',
        landmark: 'Bapapung Midway Pumping Stn',
        status: SignallerStatus.passed,
        sensorTechnology: 'Intrusive Bi-directional + Magnetic',
        lastTripTime: _launchTime.add(const Duration(hours: 4, minutes: 12)),
        acousticDb: 91.2,
        magneticGauss: 1420.0,
        batteryVoltage: 3.58,
        signalDbm: -65,
      ),
      PigSignallerRecord(
        id: 'SP-05',
        name: 'Valve Station VS-06 Signaller',
        chainageKm: 44.150,
        chainageStr: 'KP 44+150',
        landmark: 'Bogapani Tea Estate Rail Spur',
        status: SignallerStatus.armedStandby,
        sensorTechnology: 'Non-Intrusive Magnetic + Acoustic',
        lastTripTime: null,
        acousticDb: 18.2, // Ambient
        magneticGauss: 42.0, // Earth field
        batteryVoltage: 3.64,
        signalDbm: -69,
      ),
      PigSignallerRecord(
        id: 'SP-06',
        name: 'Receiver Lead Neck Signaller',
        chainageKm: 54.550,
        chainageStr: 'KP 54+550',
        landmark: 'PR-01 Digboi Intake Header',
        status: SignallerStatus.armedStandby,
        sensorTechnology: 'Intrusive Flag + Hall-Effect Array',
        lastTripTime: null,
        acousticDb: 22.0, // Ambient
        magneticGauss: 48.0,
        batteryVoltage: 3.65,
        signalDbm: -64,
      ),
    ];

    _anomalies = [
      const PofAnomalyRecord(
        id: 'ANOM-MFL-0412',
        chainageKm: 14.825,
        chainageStr: 'KP 14+825',
        spoolId: 'SP-X70-0382',
        upstreamGirthWeld: 'GW-1240',
        distFromWeldMeters: 3.42,
        wallSurface: WallSurface.internal,
        morphology: PofMorphology.pitting,
        depthMm: 5.90, // 62% of 9.52mm
        nominalThicknessMm: 9.52,
        lengthMm: 142.0,
        widthMm: 78.0,
        clockHour: 5,
        clockMinute: 45,
        pipeOdMm: 457.2,
        designPressureBar: 98.0,
        maopBar: 88.2,
        jointDefectId: 'FLAW-0412-ID',
        repairRecommendation:
            'CRITICAL: Type-B Full Encirclement Welded Sleeve within 30 days per ASME PCC-2. Immediate pressure restriction to 62.8 Bar.',
      ),
      const PofAnomalyRecord(
        id: 'ANOM-MFL-0498',
        chainageKm: 21.340,
        chainageStr: 'KP 21+340',
        spoolId: 'SP-X70-0544',
        upstreamGirthWeld: 'GW-1782',
        distFromWeldMeters: 6.85,
        wallSurface: WallSurface.external,
        morphology: PofMorphology.generalMetalLoss,
        depthMm: 4.85, // 51% WT
        nominalThicknessMm: 9.52,
        lengthMm: 195.0,
        widthMm: 120.0,
        clockHour: 6,
        clockMinute: 15,
        pipeOdMm: 457.2,
        designPressureBar: 98.0,
        maopBar: 88.2,
        jointDefectId: 'FLAW-0498-OD',
        repairRecommendation:
            'Composite carbon-fiber wrap or Type-A mechanical sleeve within 60 days. Monitor CP potential at adjacent TLP-14.',
      ),
      const PofAnomalyRecord(
        id: 'ANOM-CAL-0518',
        chainageKm: 31.420,
        chainageStr: 'KP 31+420',
        spoolId: 'SP-X70-0792',
        upstreamGirthWeld: 'GW-2598',
        distFromWeldMeters: 1.15,
        wallSurface: WallSurface.external,
        morphology: PofMorphology.gougedDent,
        depthMm: 3.20,
        nominalThicknessMm: 9.52,
        lengthMm: 85.0,
        widthMm: 65.0,
        clockHour: 11,
        clockMinute: 30,
        dentDepthPctOd: 3.4, // >2% on girth weld proximity
        pipeOdMm: 457.2,
        designPressureBar: 98.0,
        maopBar: 88.2,
        jointDefectId: 'DENT-0518-GW',
        repairRecommendation:
            'ACTION REQUIRED: Dent with 1.15m weld proximity exceeds ASME B31.8 / OISD-141 limits. Excavate, NDT ultrasonic phased array verification, install Type-B sleeve.',
      ),
      const PofAnomalyRecord(
        id: 'ANOM-MFL-0604',
        chainageKm: 8.650,
        chainageStr: 'KP 8+650',
        spoolId: 'SP-X70-0220',
        upstreamGirthWeld: 'GW-0720',
        distFromWeldMeters: 8.10,
        wallSurface: WallSurface.internal,
        morphology: PofMorphology.axialGroove,
        depthMm: 3.80, // 40% WT
        nominalThicknessMm: 9.52,
        lengthMm: 210.0,
        widthMm: 22.0,
        clockHour: 6,
        clockMinute: 0,
        pipeOdMm: 457.2,
        designPressureBar: 98.0,
        maopBar: 88.2,
        jointDefectId: 'FLAW-0604-AX',
        repairRecommendation:
            'MONITOR: Axial bottom invert channeling from stratified water accumulation. Inject biocides / corrosion inhibitor batch.',
      ),
      const PofAnomalyRecord(
        id: 'ANOM-MFL-0722',
        chainageKm: 27.810,
        chainageStr: 'KP 27+810',
        spoolId: 'SP-X70-0704',
        upstreamGirthWeld: 'GW-2315',
        distFromWeldMeters: 4.20,
        wallSurface: WallSurface.external,
        morphology: PofMorphology.pinhole,
        depthMm: 2.10, // 22% WT
        nominalThicknessMm: 9.52,
        lengthMm: 8.5,
        widthMm: 7.2,
        clockHour: 2,
        clockMinute: 15,
        pipeOdMm: 457.2,
        designPressureBar: 98.0,
        maopBar: 88.2,
        jointDefectId: 'FLAW-0722-PIN',
        repairRecommendation:
            'ACCEPTABLE: Minor pinhole corrosion. Retain in 3-year ILI comparison baseline tracking.',
      ),
      const PofAnomalyRecord(
        id: 'ANOM-CAL-0830',
        chainageKm: 34.120,
        chainageStr: 'KP 34+120',
        spoolId: 'SP-X70-0865',
        upstreamGirthWeld: 'GW-2844',
        distFromWeldMeters: 9.35,
        wallSurface: WallSurface.external,
        morphology: PofMorphology.plainDent,
        depthMm: 1.80,
        nominalThicknessMm: 9.52,
        lengthMm: 62.0,
        widthMm: 45.0,
        clockHour: 7,
        clockMinute: 20,
        dentDepthPctOd: 1.6, // <2% smooth rock dent
        pipeOdMm: 457.2,
        designPressureBar: 98.0,
        maopBar: 88.2,
        jointDefectId: 'DENT-0830-PLN',
        repairRecommendation:
            'ACCEPTABLE: Smooth bottom dent < 2% OD without stress concentration or girth weld interference.',
      ),
      const PofAnomalyRecord(
        id: 'ANOM-MFL-0910',
        chainageKm: 35.400,
        chainageStr: 'KP 35+400',
        spoolId: 'SP-X70-0898',
        upstreamGirthWeld: 'GW-2950',
        distFromWeldMeters: 2.90,
        wallSurface: WallSurface.internal,
        morphology: PofMorphology.pitting,
        depthMm: 3.40, // 35.7% WT
        nominalThicknessMm: 9.52,
        lengthMm: 48.0,
        widthMm: 36.0,
        clockHour: 6,
        clockMinute: 30,
        pipeOdMm: 457.2,
        designPressureBar: 98.0,
        maopBar: 88.2,
        jointDefectId: 'FLAW-0910-PIT',
        repairRecommendation:
            'MONITOR: Invert pitting corrosion. Safe pressure 84.1 Bar exceeds current operating pressure.',
      ),
    ];

    _selectedAnomaly = _anomalies.first;
  }

  void _startLiveCountdownTicker() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingEta.inSeconds > 0) {
          _remainingEta = _remainingEta - const Duration(seconds: 1);
        }
        // Micro-advance position in simulated pumping
        if (_isSimulatingPumping &&
            _currentPigLocationKm < _pipelineLengthKm - 0.05) {
          final vMs = _calculateVelocityMs();
          // v in m/s -> km per second = (v / 1000)
          _currentPigLocationKm += (vMs / 1000.0) * 0.1; // gentle advance
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // HYDRAULIC & VELOCITY CALCULATIONS
  // --------------------------------------------------------------------------
  // v = Q / A in m/s
  // Area = pi * (Di)^2 / 4
  // Di = 457.2 mm - 2 * 9.52 mm = 438.16 mm = 0.4382 m
  // Q (m3/s) = Q_m3h / 3600
  double _calculateVelocityMs() {
    final diMeters = (_nominalOdMm - (2 * _nominalWallThicknessMm)) / 1000.0;
    final areaSqMeters = (math.pi * diMeters * diMeters) / 4.0;
    final qM3s = _flowRateM3h / 3600.0;
    final idealVelocity = qM3s / areaSqMeters;
    // Account for slight tool bypass slippage
    return idealVelocity * (1.0 - _pigToolSlippage);
  }

  double _calculateVelocityKmh() {
    return _calculateVelocityMs() * 3.6;
  }

  String _formatEtaString(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _calculateEtaArrivalTime() {
    final arrival = DateTime.now().add(_remainingEta);
    return DateFormat('HH:mm:ss').format(arrival);
  }

  // --------------------------------------------------------------------------
  // UI BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final currentVelocityMs = _calculateVelocityMs();
    final remainingKm =
        math.max(0.0, _pipelineLengthKm - _currentPigLocationKm);
    final progressFraction = (_currentPigLocationKm / _pipelineLengthKm)
        .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Intelligent Pipeline Pigging & ILI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4EDEA3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'OIL 18" Trunkline | PL-01 Duliajan ➔ PR-01 Digboi (54.8 km)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export ILI Inspection Dossier',
            icon: const Icon(Icons.file_download_outlined,
                color: AppTheme.primaryLight),
            onPressed: _showExportDossierDialog,
          ),
          IconButton(
            tooltip: 'Launch Sequence Protocol',
            icon: const Icon(Icons.launch_rounded, color: AppTheme.secondary),
            onPressed: _showLaunchSequenceDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.primaryLight,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.gps_fixed_rounded, size: 16),
                  text: 'Live Tracking & ETA',
                ),
                Tab(
                  icon: Icon(Icons.tune_rounded, size: 16),
                  text: 'Barrels & Telemetry',
                ),
                Tab(
                  icon: Icon(Icons.precision_manufacturing_rounded, size: 16),
                  text: 'Pig Fleet (5 Tools)',
                ),
                Tab(
                  icon: Icon(Icons.pie_chart_rounded, size: 16),
                  text: 'POF Anomaly Clock',
                ),
                Tab(
                  icon: Icon(Icons.calculate_rounded, size: 16),
                  text: 'ASME B31G Sizing',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Global Status Telemetry Banner
          _buildGlobalStatusStrip(
            velocityMs: currentVelocityMs,
            remainingKm: remainingKm,
            progressFraction: progressFraction,
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLiveTrackingTab(
                  currentVelocityMs: currentVelocityMs,
                  remainingKm: remainingKm,
                  progressFraction: progressFraction,
                ),
                _buildBarrelsTelemetryTab(),
                _buildPigFleetTab(),
                _buildPofAnomalyClockTab(),
                _buildB31gCalculatorTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TOP GLOBAL STATUS STRIP
  // ==========================================================================
  Widget _buildGlobalStatusStrip({
    required double velocityMs,
    required double remainingKm,
    required double progressFraction,
  }) {
    // Envelope assessment for MFL
    final isStallRisk = velocityMs < 1.0;
    final isOptimal = velocityMs >= 1.5 && velocityMs <= 3.0;
    final isSpeedExcess = velocityMs > 3.5;

    final Color statusColor = isStallRisk
        ? const Color(0xFFEF4444)
        : isSpeedExcess
            ? const Color(0xFFFFB95F)
            : const Color(0xFF4EDEA3);

    final String statusText = isStallRisk
        ? 'LOW VELOCITY ALERT: STALL DANGER'
        : isSpeedExcess
            ? 'HIGH SPEED: SENSOR BLUR WARNING'
            : 'OPTIMAL ILI SPEED ENVELOPE (1.5 - 3.0 m/s)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: const Border(
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOptimal
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: statusColor,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'ETA DIGBOI: ${_formatEtaString(_remainingEta)} (${_calculateEtaArrivalTime()} IST)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryLight,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    backgroundColor: AppTheme.surface,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'KP ${_currentPigLocationKm.toStringAsFixed(2)} / ${_pipelineLengthKm.toStringAsFixed(1)} km (${(progressFraction * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: LIVE TRACKING & ETA HYDRAULICS
  // ==========================================================================
  Widget _buildLiveTrackingTab({
    required double currentVelocityMs,
    required double remainingKm,
    required double progressFraction,
  }) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Real-time Velocity & Hydraulics Card
        _buildHydraulicsMonitorCard(currentVelocityMs),
        const SizedBox(height: 12),

        // Pipeline Corridor Track Visualizer
        _buildCorridorVisualizerCard(
          progressFraction: progressFraction,
          remainingKm: remainingKm,
        ),
        const SizedBox(height: 12),

        // Real-time Pig Passage Signallers Grid (SP-01 to SP-06)
        _buildSignallersSection(),
        const SizedBox(height: 12),

        // On-board Tool Telemetry & Hardware Health
        _buildHardwareHealthCard(),
      ],
    );
  }

  Widget _buildHydraulicsMonitorCard(double currentVelocityMs) {
    final vKmh = _calculateVelocityKmh();

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
              const Icon(Icons.speed_rounded,
                  color: AppTheme.primaryLight, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pig Tracking Velocity & Hydraulics Engine',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'v = Q / A (m/s)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryLight,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Metric readouts
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Tool Velocity (v)',
                  value: '${currentVelocityMs.toStringAsFixed(2)} m/s',
                  subtitle: '${vKmh.toStringAsFixed(1)} km/h',
                  color: const Color(0xFF4EDEA3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Throughput (Q)',
                  value: '${_flowRateM3h.toStringAsFixed(0)} m³/h',
                  subtitle:
                      '${(_flowRateM3h / 3600).toStringAsFixed(3)} m³/s flow',
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Diff Press (ΔP)',
                  value: '${_diffPressureBar.toStringAsFixed(2)} Bar',
                  subtitle: 'Driving head',
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Bore Area (A)',
                  value: '0.1508 m²',
                  subtitle: 'Di = 438.2 mm',
                  color: const Color(0xFFC084FC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Speed Envelope Gauge Widget
          const Text(
            'MFL HIGH-RESOLUTION SPEED ENVELOPE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          _buildSpeedEnvelopeVisualizer(currentVelocityMs),
          const SizedBox(height: 12),

          // Interactive Flow Rate Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Simulate Line Flow Rate Q (Discharge Pump Modulation):',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${_flowRateM3h.toStringAsFixed(0)} m³/h',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryLight,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.surface,
              thumbColor: AppTheme.primaryLight,
              overlayColor: AppTheme.primaryLight.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _flowRateM3h,
              min: 600.0,
              max: 2200.0,
              divisions: 32,
              onChanged: (val) {
                setState(() {
                  _flowRateM3h = val;
                  // Recalculate remaining ETA dynamically
                  final v = _calculateVelocityMs();
                  final remMeters = math.max(
                          0.0, _pipelineLengthKm - _currentPigLocationKm) *
                      1000.0;
                  final sec = (remMeters / math.max(0.1, v)).round();
                  _remainingEta = Duration(seconds: sec);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedEnvelopeVisualizer(double velocityMs) {
    // 0 to 4.5 m/s range
    final normalized = (velocityMs / 4.5).clamp(0.0, 1.0);

    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEF4444), // 0 to 1.0 m/s: Stall Risk
                    Color(0xFFFFB95F), // 1.0 to 1.5 m/s: Suboptimal
                    Color(0xFF4EDEA3), // 1.5 to 3.0 m/s: Optimal Green
                    Color(0xFF4EDEA3),
                    Color(0xFFFFB95F), // 3.0 to 3.5 m/s: Warning
                    Color(0xFFEF4444), // >3.5 m/s: Sensor Blur
                  ],
                  stops: [0.0, 0.22, 0.33, 0.67, 0.78, 1.0],
                ),
              ),
            ),
            // Current position pin
            Positioned(
              left: (normalized * 280).clamp(0.0, 270),
              top: 0,
              bottom: 0,
              child: Container(
                width: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0 m/s (Stall)',
                style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
            Text('1.5 m/s (Min MFL)',
                style: TextStyle(fontSize: 9, color: Color(0xFF4EDEA3))),
            Text('3.0 m/s (Max MFL)',
                style: TextStyle(fontSize: 9, color: Color(0xFF4EDEA3))),
            Text('4.5 m/s (Blur)',
                style: TextStyle(fontSize: 9, color: Color(0xFFEF4444))),
          ],
        ),
      ],
    );
  }

  Widget _buildCorridorVisualizerCard({
    required double progressFraction,
    required double remainingKm,
  }) {
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
              const Icon(Icons.alt_route_rounded,
                  color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pipeline Corridor Track & Spatial Position',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  'Remaining: ${remainingKm.toStringAsFixed(2)} km',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Custom Corridor Painter
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: _CorridorTrackPainter(
                currentLocationKm: _currentPigLocationKm,
                totalLengthKm: _pipelineLengthKm,
                signallers: _signallers,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Key Landmarks Along Route
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLandmarkLabel('PL-01 Duliajan', 'KP 0.0', true),
              _buildLandmarkLabel('Dihing HDD', 'KP 11.4', false),
              _buildLandmarkLabel('VS-03 Deohall', 'KP 22.8', false),
              _buildLandmarkLabel('Bapapung', 'KP 34.6', false),
              _buildLandmarkLabel('VS-06 Bogapani', 'KP 44.1', false),
              _buildLandmarkLabel('PR-01 Digboi', 'KP 54.8', true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandmarkLabel(String name, String kp, bool isTerminal) {
    return Column(
      children: [
        Text(
          kp,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isTerminal ? AppTheme.primaryLight : AppTheme.textMuted,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isTerminal ? FontWeight.w700 : FontWeight.w500,
            color: isTerminal ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSignallersSection() {
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
              const Icon(Icons.sensors_rounded,
                  color: AppTheme.primaryLight, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pig Passage Acoustic & Magnetic Signallers (SP-01 to SP-06)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                '${_signallers.where((s) => s.status == SignallerStatus.passed).length} / ${_signallers.length} Tripped',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4EDEA3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 6 Signaller Cards in 2 columns
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 580;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _signallers.map((sig) {
                  final cardWidth = isWide
                      ? (constraints.maxWidth - 8) / 2
                      : constraints.maxWidth;
                  return SizedBox(
                    width: cardWidth,
                    child: _buildSignallerCard(sig),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignallerCard(PigSignallerRecord sig) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: sig.status == SignallerStatus.passed
              ? AppTheme.primary.withValues(alpha: 0.5)
              : AppTheme.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: sig.status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              sig.status == SignallerStatus.passed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_checked_rounded,
              color: sig.status.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${sig.id} • ${sig.chainageStr}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: sig.status.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sig.status.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: sig.status.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  sig.landmark,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      sig.sensorTechnology,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (sig.lastTripTime != null)
                      Text(
                        'Tripped: ${DateFormat('HH:mm:ss').format(sig.lastTripTime!)}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryLight,
                          fontFamily: 'monospace',
                        ),
                      )
                    else
                      const Text(
                        'Awaiting passage',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.volume_up_rounded,
                        size: 11, color: sig.status.color),
                    const SizedBox(width: 3),
                    Text(
                      '${sig.acousticDb.toStringAsFixed(1)} dB',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.explore_rounded,
                        size: 11, color: sig.status.color),
                    const SizedBox(width: 3),
                    Text(
                      '${sig.magneticGauss.toStringAsFixed(0)} mG',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.battery_charging_full_rounded,
                        size: 11, color: AppTheme.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      '${sig.batteryVoltage.toStringAsFixed(2)}V (${sig.signalDbm} dBm)',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textMuted,
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

  Widget _buildHardwareHealthCard() {
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
              Icon(Icons.memory_rounded,
                  color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MFL On-Board Computer & Sub-Systems Telemetry',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                'HEALTH: 100% NOMINAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4EDEA3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildHealthBarItem(
                  title: 'Li-SOCl2 Battery Bank',
                  fraction: _batteryPercent / 100.0,
                  valueStr: '$_batteryPercent% (68h remaining)',
                  color: const Color(0xFF4EDEA3),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildHealthBarItem(
                  title: 'Solid-State Memory NVMe',
                  fraction: _memoryWrittenGb / _memoryTotalGb,
                  valueStr: '$_memoryWrittenGb / $_memoryTotalGb GB (28.9%)',
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Odometer 1: 35,821.4 m (Slip 0.002%)',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'Odometer 2: 35,819.8 m (Redundant)',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'IMU 6-DOF: Pitch +0.4°, Roll -1.2°',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBarItem({
    required String title,
    required double fraction,
    required String valueStr,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              valueStr,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppTheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 2: BARRELS & TELEMETRY (PL-01 DULIAJAN & PR-01 DIGBOI)
  // ==========================================================================
  Widget _buildBarrelsTelemetryTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Barrel Station Cards
        _buildBarrelStationCard(_launcherBarrel, isLauncher: true),
        const SizedBox(height: 14),
        _buildBarrelStationCard(_receiverBarrel, isLauncher: false),
        const SizedBox(height: 14),

        // Quick Opening Closure (QOC) Safety Interlock Standards Card
        _buildQocSafetyStandardCard(),
      ],
    );
  }

  Widget _buildBarrelStationCard(
    BarrelTelemetryData barrel, {
    required bool isLauncher,
  }) {
    final statusColor = isLauncher ? AppTheme.primaryLight : AppTheme.secondary;

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isLauncher
                      ? Icons.arrow_circle_up_rounded
                      : Icons.arrow_circle_down_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      barrel.barrelType,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${barrel.stationName} (KP ${barrel.chainageKm.toStringAsFixed(1)})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  barrel.barrelDimensions,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pressure & Equalization Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Barrel Pressure',
                  value: '${barrel.barrelPressureBar.toStringAsFixed(1)} Bar',
                  subtitle: 'Transducer PT-101',
                  color: const Color(0xFF4EDEA3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Mainline Pressure',
                  value: '${barrel.mainlinePressureBar.toStringAsFixed(1)} Bar',
                  subtitle: 'PT-102 Upstream',
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Diff Pressure (ΔP)',
                  value: '${barrel.deltaP.toStringAsFixed(2)} Bar',
                  subtitle:
                      barrel.deltaP <= 0.5 ? 'EQUALIZED' : 'DIFFERENTIAL',
                  color: barrel.deltaP <= 0.5
                      ? const Color(0xFF4EDEA3)
                      : AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: isLauncher ? 'Kicker MOV-101' : 'Kicker MOV-201',
                  value: '${barrel.kickerValvePct.toStringAsFixed(0)}% Open',
                  subtitle: barrel.isKickerValveOpen ? 'ACTIVE' : 'ISOLATED',
                  color: const Color(0xFFC084FC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Valve Status Strip
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildValveStatusIcon(
                  name: 'Equalization Line',
                  isOpen: barrel.isEqualizationValveOpen,
                  isHealthy: barrel.isEqualizationValveOpen,
                ),
                _buildValveStatusIcon(
                  name: 'Vent Line (Bleed)',
                  isOpen: !barrel.isVentValveClosed,
                  isHealthy: barrel.isVentValveClosed,
                ),
                _buildValveStatusIcon(
                  name: 'Drain to Sump',
                  isOpen: !barrel.isDrainValveClosed,
                  isHealthy: barrel.isDrainValveClosed,
                ),
                _buildValveStatusIcon(
                  name: 'QOC Door Lock Pin',
                  isOpen: !barrel.isDoorInterlockPinSafe,
                  isHealthy: barrel.isDoorInterlockPinSafe,
                  customLabel:
                      barrel.isDoorInterlockPinSafe ? 'ENGAGED' : 'UNLOCKED',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Interlock descriptive status
          Row(
            children: [
              const Icon(Icons.lock_clock_rounded,
                  size: 13, color: Color(0xFF4EDEA3)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  barrel.interlockStatusDescription,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4EDEA3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValveStatusIcon({
    required String name,
    required bool isOpen,
    required bool isHealthy,
    String? customLabel,
  }) {
    final statusColor =
        isHealthy ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              customLabel ?? (isOpen ? 'OPEN' : 'CLOSED'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: statusColor,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: const TextStyle(
            fontSize: 9,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildQocSafetyStandardCard() {
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
              Icon(Icons.shield_outlined,
                  color: AppTheme.secondary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ASME Sec VIII Div 1 UG-35.2 & OISD-141 Safety Mandate',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Quick Opening Closures (QOC) must be equipped with mechanical pressure-warning devices and trapped key interlocks. The door locking mechanism physically cannot be retracted until the pressure-warning bleed screw is unseated to prove 0.0 Bar residual pressure.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: PIG FLEET SPECIFICATIONS (5 PIG CLASSES)
  // ==========================================================================
  Widget _buildPigFleetTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _pigFleet.length,
      itemBuilder: (context, index) {
        final tool = _pigFleet[index];
        return _buildPigToolCard(tool);
      },
    );
  }

  Widget _buildPigToolCard(PigToolSpec tool) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tool.type.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(tool.type.icon, color: tool.type.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tool.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tool.type.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tool.type.shortName,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: tool.type.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tool.manufacturer} • Model: ${tool.modelNo}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tool.description,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Specs Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSpecTag('Weight', '${tool.weightKg} kg'),
              _buildSpecTag('Length', '${tool.lengthMeters} m'),
              _buildSpecTag('Min Bend', tool.minBendRadius),
              _buildSpecTag('Max Press', '${tool.maxPressureBar} Bar'),
              _buildSpecTag('Sensors', '${tool.sensorCount} ch'),
              _buildSpecTag('Battery', '${tool.batteryLifeHours} h'),
              _buildSpecTag(
                  'Opt. Speed', '${tool.type.optimalMinSpeed}-${tool.type.optimalMaxSpeed} m/s'),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings_input_antenna_rounded,
                    size: 13, color: AppTheme.primaryLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Telemetry & Tracking: ${tool.telemetrySystem}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: POF ANOMALY CLOCK & DEFECT REGISTER
  // ==========================================================================
  Widget _buildPofAnomalyClockTab() {
    final filtered = _anomalies.where((a) {
      if (_anomalyFilter == 'ACTION') {
        return a.severity == ErfSeverity.actionRequired;
      }
      if (_anomalyFilter == 'INTERNAL') {
        return a.wallSurface == WallSurface.internal;
      }
      if (_anomalyFilter == 'EXTERNAL') {
        return a.wallSurface == WallSurface.external;
      }
      if (_anomalyFilter == 'DENTS') {
        return a.morphology == PofMorphology.plainDent ||
            a.morphology == PofMorphology.gougedDent;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Top Filter Bar & Summary
        _buildPofSummaryCard(),
        const SizedBox(height: 14),

        // Interactive Radial Clock Visualizer Card
        _buildClockRadialCard(),
        const SizedBox(height: 14),

        // Filter Pills
        _buildFilterPills(),
        const SizedBox(height: 10),

        // Anomaly List
        ...filtered.map((anomaly) {
          final isSelected = _selectedAnomaly?.id == anomaly.id;
          return _buildAnomalyCard(anomaly, isSelected);
        }),
      ],
    );
  }

  Widget _buildPofSummaryCard() {
    final criticalCount = _anomalies
        .where((a) => a.severity == ErfSeverity.actionRequired)
        .length;
    final monitorCount =
        _anomalies.where((a) => a.severity == ErfSeverity.monitor).length;
    final safeCount =
        _anomalies.where((a) => a.severity == ErfSeverity.safe).length;

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
              Icon(Icons.assessment_rounded,
                  color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'POF 2016 Specification Anomaly Distribution',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                'OIL Pipeline Integrity',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Action Required',
                  value: '$criticalCount Anomalies',
                  subtitle: 'ERF > 1.00 or Dent > 6%',
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Monitor',
                  value: '$monitorCount Anomalies',
                  subtitle: '0.90 ≤ ERF ≤ 1.00',
                  color: const Color(0xFFFFB95F),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Acceptable',
                  value: '$safeCount Anomalies',
                  subtitle: 'ERF < 0.90 (Safe)',
                  color: const Color(0xFF4EDEA3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClockRadialCard() {
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
              const Icon(Icons.radio_button_checked_rounded,
                  color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Cross-Sectional Pipe Clock Orientation (O\'Clock Position)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (_selectedAnomaly != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _selectedAnomaly!.severity.color
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Selected: ${_selectedAnomaly!.id}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _selectedAnomaly!.severity.color,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Pipe Cross-Section Radial Dial
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(
                painter: _PipeClockCrossSectionPainter(
                  anomalies: _anomalies,
                  selectedAnomaly: _selectedAnomaly,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend for Clock Dial
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ClockLegendItem(
                  color: Color(0xFFEF4444), label: 'Action Required (ERF>1)'),
              SizedBox(width: 14),
              _ClockLegendItem(
                  color: Color(0xFFFFB95F), label: 'Monitor (0.9-1.0)'),
              SizedBox(width: 14),
              _ClockLegendItem(
                  color: Color(0xFF4EDEA3), label: 'Safe (<0.9)'),
            ],
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              '12:00 = Crown (Top) • 06:00 = Invert (Bottom Sediment/Water) • 03:00 / 09:00 = Pipe Sides',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    final filters = [
      {'key': 'ALL', 'label': 'All Anomalies (${_anomalies.length})'},
      {'key': 'ACTION', 'label': 'Action Required (ERF>1)'},
      {'key': 'INTERNAL', 'label': 'Internal ID Flaws'},
      {'key': 'EXTERNAL', 'label': 'External OD Flaws'},
      {'key': 'DENTS', 'label': 'Geometric Dents'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _anomalyFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _anomalyFilter = f['key']!;
                  });
                }
              },
              backgroundColor: AppTheme.surfaceCard,
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              side: const BorderSide(color: AppTheme.border),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnomalyCard(PofAnomalyRecord anomaly, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAnomaly = anomaly;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryLight
                : anomaly.severity == ErfSeverity.actionRequired
                    ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                    : AppTheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: anomaly.severity.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    anomaly.id,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: anomaly.severity.color,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${anomaly.chainageStr} • ${anomaly.spoolId}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: anomaly.wallSurface.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    anomaly.wallSurface.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: anomaly.wallSurface.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Metrics row
            Row(
              children: [
                _buildAnomalyDetailPill(
                  label: 'POF Type',
                  value: anomaly.morphology.code,
                ),
                const SizedBox(width: 6),
                _buildAnomalyDetailPill(
                  label: 'Clock Pos',
                  value: anomaly.clockOrientationStr,
                ),
                const SizedBox(width: 6),
                _buildAnomalyDetailPill(
                  label: 'Depth',
                  value:
                      '${anomaly.depthMm.toStringAsFixed(1)} mm (${anomaly.depthPct.toStringAsFixed(0)}% WT)',
                  highlightColor: anomaly.depthPct >= 50
                      ? const Color(0xFFEF4444)
                      : null,
                ),
                const SizedBox(width: 6),
                _buildAnomalyDetailPill(
                  label: 'ERF (B31G)',
                  value: anomaly.erf.toStringAsFixed(2),
                  highlightColor: anomaly.severity.color,
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  'Girth Weld: ${anomaly.upstreamGirthWeld} + ${anomaly.distFromWeldMeters.toStringAsFixed(2)} m',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                Text(
                  'P_safe: ${anomaly.safePressureBar.toStringAsFixed(1)} Bar (MAOP 88.2)',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Recommendation
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    anomaly.severity == ErfSeverity.actionRequired
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline_rounded,
                    size: 13,
                    color: anomaly.severity.color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      anomaly.repairRecommendation,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: anomaly.severity == ErfSeverity.actionRequired
                            ? const Color(0xFFEF4444)
                            : AppTheme.textSecondary,
                      ),
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

  Widget _buildAnomalyDetailPill({
    required String label,
    required String value,
    Color? highlightColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                color: AppTheme.textMuted,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: highlightColor ?? AppTheme.textPrimary,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 5: ASME B31G & MODIFIED B31G CALCULATOR
  // ==========================================================================
  Widget _buildB31gCalculatorTab() {
    // Perform dynamic calculation
    final z = (_calcDefectLengthMm * _calcDefectLengthMm) /
        (_calcPipeOdMm * _calcWallThicknessMm);
    double foliasM;
    if (z <= 50.0) {
      foliasM = math.sqrt(
          math.max(1.0, 1.0 + (0.6275 * z) - (0.003375 * z * z)));
    } else {
      foliasM = (0.032 * z) + 3.3;
    }

    final dt = _calcDefectDepthMm / _calcWallThicknessMm;
    double pSafeBar = 0.0;
    if (dt < 0.80) {
      final num = 1.0 - (0.85 * dt);
      final den = 1.0 - ((0.85 * dt) / foliasM);
      if (den > 0) {
        pSafeBar = 1.1 * _designPressureBar * (num / den);
        pSafeBar = math.min(_designPressureBar * 1.1, pSafeBar);
      }
    }

    final erf = pSafeBar > 0 ? (_calcMaopBar / pSafeBar) : 2.50;
    final isActionReq = erf > 1.0 || dt >= 0.80;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Header Info
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
                  Icon(Icons.calculate_rounded,
                      color: AppTheme.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Interactive ASME B31G & Modified B31G Engine',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Evaluate allowable remaining strength of corroded pipe per ASME B31G-2012 / Modified B31G (0.85dL) / RSTRENG. Calculates Folias bulging factor M, Safe Operating Pressure P\'_safe, and Estimated Repair Factor (ERF).',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Live Calculation Output Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isActionReq
                ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                : const Color(0xFF4EDEA3).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActionReq
                  ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                  : const Color(0xFF4EDEA3).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isActionReq
                        ? 'ACTION REQUIRED: DEFECT EXCEEDS MAOP'
                        : 'ACCEPTABLE UNDER ASME B31G',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isActionReq
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF4EDEA3),
                    ),
                  ),
                  Text(
                    'ERF = ${erf.toStringAsFixed(3)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isActionReq
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF4EDEA3),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Safe Press (P\'_safe)',
                      value: '${pSafeBar.toStringAsFixed(1)} Bar',
                      subtitle: 'MAOP: ${_calcMaopBar.toStringAsFixed(1)} Bar',
                      color: pSafeBar >= _calcMaopBar
                          ? const Color(0xFF4EDEA3)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Folias Factor (M)',
                      value: foliasM.toStringAsFixed(3),
                      subtitle: 'z = ${z.toStringAsFixed(2)}',
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Metal Loss (d/t)',
                      value: '${(dt * 100).toStringAsFixed(1)}%',
                      subtitle: '${_calcDefectDepthMm.toStringAsFixed(2)} mm',
                      color: dt >= 0.5
                          ? const Color(0xFFEF4444)
                          : AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Sliders & Interactive Controls
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
                'DEFECT GEOMETRY & SIZING INPUTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Defect Depth d Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Defect Depth (d):',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${_calcDefectDepthMm.toStringAsFixed(2)} mm (${((_calcDefectDepthMm / _calcWallThicknessMm) * 100).toStringAsFixed(0)}% WT)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryLight,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Slider(
                value: _calcDefectDepthMm,
                min: 0.5,
                max: _calcWallThicknessMm * 0.95,
                divisions: 30,
                onChanged: (val) {
                  setState(() {
                    _calcDefectDepthMm = val;
                  });
                },
              ),
              const SizedBox(height: 8),

              // Defect Axial Length L Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Defect Axial Length (L):',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${_calcDefectLengthMm.toStringAsFixed(0)} mm',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Slider(
                value: _calcDefectLengthMm,
                min: 10.0,
                max: 400.0,
                divisions: 39,
                onChanged: (val) {
                  setState(() {
                    _calcDefectLengthMm = val;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Fixed Pipeline Parameters
              const Text(
                'PIPELINE MATERIAL & DESIGN PARAMETERS (OIL 18")',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSpecTag('Outer Diameter (OD)', '$_calcPipeOdMm mm (18")'),
                  _buildSpecTag('Wall Thickness (t)', '$_calcWallThicknessMm mm'),
                  _buildSpecTag('Steel Grade', 'API 5L X70 (SMYS 483 MPa)'),
                  _buildSpecTag('Design Pressure', '$_designPressureBar Bar'),
                  _buildSpecTag('MAOP', '$_calcMaopBar Bar'),
                  _buildSpecTag('Standard', _calcStandard),
                  _buildSpecTag('Design Factor (F)', '0.72'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // DIALOGS & PROCEDURAL WIZARDS
  // ==========================================================================
  void _showLaunchSequenceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: const Row(
                children: [
                  Icon(Icons.launch_rounded, color: AppTheme.secondary),
                  SizedBox(width: 8),
                  Text(
                    'Pig Launcher Sequence (PL-01)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStepRow(
                      stepNum: 1,
                      title: 'Door Safety Bleed Screw & Interlock',
                      subtitle:
                          'Verify 0.0 Bar on bleed screw. Retract trapped key.',
                      isDone: _launchSequenceStep >= 1,
                    ),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildStepRow(
                      stepNum: 2,
                      title: 'Barrel Pressurization & Equalization',
                      subtitle:
                          'Open V-102 crack bypass. Equalize to 82.4 Bar.',
                      isDone: _launchSequenceStep >= 2,
                    ),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildStepRow(
                      stepNum: 3,
                      title: 'Kicker Line Divert & Launch',
                      subtitle:
                          'Open MOV-101 to 100%. Throttle main line valve.',
                      isDone: _launchSequenceStep >= 3,
                    ),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildStepRow(
                      stepNum: 4,
                      title: 'Acoustic / Magnetic Passage Confirm',
                      subtitle:
                          'Signaller SP-01 triggered at KP 0+250 (06:15:48 IST).',
                      isDone: _launchSequenceStep >= 4,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setDialogState(() {
                      _launchSequenceStep = 4;
                    });
                    setState(() {
                      _launchSequenceStep = 4;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Launcher sequence validated and logged!'),
                        backgroundColor: Color(0xFF4EDEA3),
                      ),
                    );
                  },
                  child: const Text('Verify All Protocols'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStepRow({
    required int stepNum,
    required String title,
    required String subtitle,
    required bool isDone,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF4EDEA3)
                : AppTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? const Color(0xFF4EDEA3) : AppTheme.border,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.black)
                : Text(
                    '$stepNum',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showExportDossierDialog() {
    final reportJson = {
      'runId': 'ILI-2026-RUN-04',
      'pipeline': _pipelineName,
      'nominalOD': '${_nominalOdMm}mm (18")',
      'nominalWT': '${_nominalWallThicknessMm}mm',
      'designPressureBar': _designPressureBar,
      'maopBar': _maopBar,
      'totalLengthKm': _pipelineLengthKm,
      'currentPositionKp': _currentPigLocationKm,
      'flowRateM3h': _flowRateM3h,
      'velocityMs': _calculateVelocityMs(),
      'etaDigboi': _calculateEtaArrivalTime(),
      'totalAnomalies': _anomalies.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
    final sha = sha256.convert(utf8.encode(jsonEncode(reportJson))).toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF4EDEA3)),
              SizedBox(width: 8),
              Text(
                'ILI Inspection Dossier',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Digital Inspection Dossier compiled with POF 2016 defect classification, ASME B31G repair calculations, and signaller trip logs.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cryptographic Audit Hash (SHA-256):',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sha,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Color(0xFF4EDEA3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'ILI Inspection Dossier SHA-256 exported to storage!'),
                    backgroundColor: Color(0xFF4EDEA3),
                  ),
                );
              },
              child: const Text('Download PDF / CSV'),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// CUSTOM PAINTER: PIPELINE CORRIDOR TRACK VISUALIZER
// ============================================================================

class _CorridorTrackPainter extends CustomPainter {
  final double currentLocationKm;
  final double totalLengthKm;
  final List<PigSignallerRecord> signallers;

  _CorridorTrackPainter({
    required this.currentLocationKm,
    required this.totalLengthKm,
    required this.signallers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 24.0;
    final rightPad = size.width - 24.0;
    final trackWidth = rightPad - leftPad;
    final centerY = size.height / 2.0;

    // Background corridor track (unpassed)
    final bgPaint = Paint()
      ..color = const Color(0xFF1E2E5C)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(leftPad, centerY),
      Offset(rightPad, centerY),
      bgPaint,
    );

    // Passed corridor track
    final progressFraction = (currentLocationKm / totalLengthKm).clamp(0.0, 1.0);
    final currentX = leftPad + (trackWidth * progressFraction);

    final passedPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(leftPad, centerY),
      Offset(currentX, centerY),
      passedPaint,
    );

    // Signaller Pins
    for (final sig in signallers) {
      final sigFrac = (sig.chainageKm / totalLengthKm).clamp(0.0, 1.0);
      final sigX = leftPad + (trackWidth * sigFrac);

      final pinPaint = Paint()
        ..color = sig.status.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(sigX, centerY), 4.5, pinPaint);

      final ringPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(Offset(sigX, centerY), 4.5, ringPaint);
    }

    // Current Pig Location Marker (Glowing circle)
    final glowPaint = Paint()
      ..color = const Color(0xFF4EDEA3).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(currentX, centerY), 12.0, glowPaint);

    final pigCorePaint = Paint()
      ..color = const Color(0xFF4EDEA3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(currentX, centerY), 6.0, pigCorePaint);

    final pigBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(currentX, centerY), 6.0, pigBorder);
  }

  @override
  bool shouldRepaint(covariant _CorridorTrackPainter oldDelegate) {
    return oldDelegate.currentLocationKm != currentLocationKm;
  }
}

// ============================================================================
// CUSTOM PAINTER: PIPE CROSS-SECTION CLOCK RADIAL ORIENTATION
// ============================================================================

class _PipeClockCrossSectionPainter extends CustomPainter {
  final List<PofAnomalyRecord> anomalies;
  final PofAnomalyRecord? selectedAnomaly;

  _PipeClockCrossSectionPainter({
    required this.anomalies,
    this.selectedAnomaly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final outerRadius = (size.width / 2.0) - 24.0;
    const wallThickness = 14.0;
    final innerRadius = outerRadius - wallThickness;

    // Outer Pipe Wall Background
    final wallBgPaint = Paint()
      ..color = const Color(0xFF1E2E5C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, wallBgPaint);

    // Inner Pipe Bore (Crude flow)
    final borePaint = Paint()
      ..color = const Color(0xFF0B1326)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, borePaint);

    // Boundary Rings
    final strokePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, outerRadius, strokePaint);
    canvas.drawCircle(center, innerRadius, strokePaint);

    // Draw 12 Clock Hour Tick Marks
    final tickPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.5;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int h = 1; h <= 12; h++) {
      final angle = (h * 30.0 - 90.0) * (math.pi / 180.0);
      final tickStart = Offset(
        center.dx + (outerRadius + 4) * math.cos(angle),
        center.dy + (outerRadius + 4) * math.sin(angle),
      );
      final tickEnd = Offset(
        center.dx + (outerRadius + 10) * math.cos(angle),
        center.dy + (outerRadius + 10) * math.sin(angle),
      );
      canvas.drawLine(tickStart, tickEnd, tickPaint);

      // Hour Numbers
      if (h % 3 == 0) {
        textPainter.text = TextSpan(
          text: '$h:00',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            fontFamily: 'monospace',
          ),
        );
        textPainter.layout();
        final labelPos = Offset(
          center.dx + (outerRadius + 15) * math.cos(angle) - (textPainter.width / 2),
          center.dy + (outerRadius + 15) * math.sin(angle) - (textPainter.height / 2),
        );
        textPainter.paint(canvas, labelPos);
      }
    }

    // Top Longitudinal Girth Weld Seam Indicator at 12:00
    final weldPaint = Paint()
      ..color = const Color(0xFFFFB95F)
      ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset(center.dx, center.dy - outerRadius - 4),
      Offset(center.dx, center.dy - innerRadius + 2),
      weldPaint,
    );

    // Plot Anomalies on Radial Pipe Wall
    for (final anom in anomalies) {
      final hourFraction = anom.clockHour + (anom.clockMinute / 60.0);
      final angleRad = (hourFraction * 30.0 - 90.0) * (math.pi / 180.0);

      // Radial placement: internal vs external wall
      final r = anom.wallSurface == WallSurface.internal
          ? innerRadius + 3.0
          : outerRadius - 3.0;

      final anomalyPos = Offset(
        center.dx + r * math.cos(angleRad),
        center.dy + r * math.sin(angleRad),
      );

      final isSelected = selectedAnomaly?.id == anom.id;

      if (isSelected) {
        // Glowing halo for selected
        final selHalo = Paint()
          ..color = anom.severity.color.withValues(alpha: 0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(anomalyPos, 10.0, selHalo);
      }

      final defectPaint = Paint()
        ..color = anom.severity.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(anomalyPos, isSelected ? 6.0 : 4.5, defectPaint);

      final defectBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(anomalyPos, isSelected ? 6.0 : 4.5, defectBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _PipeClockCrossSectionPainter oldDelegate) {
    return oldDelegate.selectedAnomaly?.id != selectedAnomaly?.id;
  }
}

class _ClockLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _ClockLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
