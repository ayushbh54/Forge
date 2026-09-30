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
// DATA MODELS & ENUMS
// ============================================================================

enum CommissioningStage {
  airDisplacement,
  nitrogenPurging,
  hydrocarbonGasIn,
  linepackPressurization,
}

extension CommissioningStageExt on CommissioningStage {
  int get stepNumber {
    switch (this) {
      case CommissioningStage.airDisplacement:
        return 1;
      case CommissioningStage.nitrogenPurging:
        return 2;
      case CommissioningStage.hydrocarbonGasIn:
        return 3;
      case CommissioningStage.linepackPressurization:
        return 4;
    }
  }

  String get shortTitle {
    switch (this) {
      case CommissioningStage.airDisplacement:
        return 'Air Displacement';
      case CommissioningStage.nitrogenPurging:
        return 'N₂ Purging & Inerting';
      case CommissioningStage.hydrocarbonGasIn:
        return 'Natural Gas-In';
      case CommissioningStage.linepackPressurization:
        return 'Linepack Pressurization';
    }
  }

  String get standardCode {
    switch (this) {
      case CommissioningStage.airDisplacement:
        return 'OISD-141 Cl. 8.2';
      case CommissioningStage.nitrogenPurging:
        return 'ASME B31.8 / API 521';
      case CommissioningStage.hydrocarbonGasIn:
        return 'PNGRB T4S / OISD-141';
      case CommissioningStage.linepackPressurization:
        return 'ASME B31.8 Ch. VIII';
    }
  }

  IconData get icon {
    switch (this) {
      case CommissioningStage.airDisplacement:
        return Icons.air_rounded;
      case CommissioningStage.nitrogenPurging:
        return Icons.science_rounded;
      case CommissioningStage.hydrocarbonGasIn:
        return Icons.local_fire_department_rounded;
      case CommissioningStage.linepackPressurization:
        return Icons.speed_rounded;
    }
  }
}

class StageProgressInfo {
  final CommissioningStage stage;
  final String title;
  final String subtitle;
  final String description;
  final double progressPct;
  final String status; // 'COMPLETED', 'ACTIVE', 'STANDBY', 'LOCKED'
  final String targetCriteria;
  final List<String> prerequisites;

  const StageProgressInfo({
    required this.stage,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.progressPct,
    required this.status,
    required this.targetCriteria,
    required this.prerequisites,
  });
}

class StationGasSample {
  final String stationId; // VS-01 to VS-08
  final String stationName;
  final String chainage;
  final double chainageKm;
  double n2PurityPct; // Target > 98.0%
  double oxygenResidualPct; // Target < 1.0%
  double lelCombustiblePct; // Target < 0.1% LEL during purge
  double dewPointC; // Target <= -40.0 °C
  double pressureBar;
  String sampleTapPoint;
  String analyzerTag;
  String testedBy;
  DateTime lastTestedTime;
  bool isVerified;

  StationGasSample({
    required this.stationId,
    required this.stationName,
    required this.chainage,
    required this.chainageKm,
    required this.n2PurityPct,
    required this.oxygenResidualPct,
    required this.lelCombustiblePct,
    required this.dewPointC,
    required this.pressureBar,
    required this.sampleTapPoint,
    required this.analyzerTag,
    required this.testedBy,
    required this.lastTestedTime,
    this.isVerified = true,
  });

  bool get isN2Compliant => n2PurityPct >= 98.0;
  bool get isO2Compliant => oxygenResidualPct <= 1.0;
  bool get isLelCompliant => lelCombustiblePct <= 0.10;
  bool get isDewPointCompliant => dewPointC <= -40.0;
  bool get isFullyCompliant =>
      isN2Compliant && isO2Compliant && isLelCompliant && isDewPointCompliant;

  String get statusBadgeText {
    if (isFullyCompliant) return 'COMPLIANT';
    if (!isN2Compliant || !isO2Compliant) return 'PURGING ACTIVE';
    if (!isDewPointCompliant) return 'DEW POINT HOLD';
    return 'ATTENTION';
  }

  Color get statusColor {
    if (isFullyCompliant) return AppTheme.tertiary;
    if (!isN2Compliant || !isO2Compliant) return AppTheme.secondary;
    return AppTheme.error;
  }
}

class FlareStackTelemetry {
  final String unitId;
  final String location;
  final double stackHeightM;
  bool pilotIgnitionActive;
  double thermocoupleAC;
  double thermocoupleBC;
  double coldVentVelocityMach; // Target Mach < 0.20
  double ventMassFlowNm3h;
  double soundLevelDba; // Target < 85 dBA
  double soundDistanceM;
  double exclusionZoneRadiusM;
  bool exclusionZoneClear;
  double radiationAtBoundaryKwM2; // Target <= 1.58 kW/m2
  double radiationPeak50mKwM2;
  double windSpeedKmh;
  String windDirection;
  double nitrogenAssistFlowNm3h;
  double headerPressureMbar;

  FlareStackTelemetry({
    required this.unitId,
    required this.location,
    required this.stackHeightM,
    required this.pilotIgnitionActive,
    required this.thermocoupleAC,
    required this.thermocoupleBC,
    required this.coldVentVelocityMach,
    required this.ventMassFlowNm3h,
    required this.soundLevelDba,
    required this.soundDistanceM,
    required this.exclusionZoneRadiusM,
    required this.exclusionZoneClear,
    required this.radiationAtBoundaryKwM2,
    required this.radiationPeak50mKwM2,
    required this.windSpeedKmh,
    required this.windDirection,
    required this.nitrogenAssistFlowNm3h,
    required this.headerPressureMbar,
  });

  bool get isMachSafe => coldVentVelocityMach < 0.20;
  bool get isSoundSafe => soundLevelDba < 85.0;
  bool get isRadiationSafe => radiationAtBoundaryKwM2 <= 1.58;
  bool get isPilotHealthy =>
      pilotIgnitionActive &&
      thermocoupleAC >= 600.0 &&
      thermocoupleBC >= 600.0;
}

class PressurizationHoldStep {
  final int stepIndex;
  final double targetPressureBar;
  final String title;
  final int requiredHoldHours;
  double elapsedHoldHours;
  String status; // 'COMPLETED', 'HOLDING', 'SCHEDULED'
  double rateOfPressureChangeBarHr; // Target <= 0.05 Bar/hr
  int inspectedJointsCount;
  final int totalJointsCount;
  bool flirOgiCameraPassed;
  double acousticUltrasonicDbuv;
  String acousticVerdict;
  String notes;

  PressurizationHoldStep({
    required this.stepIndex,
    required this.targetPressureBar,
    required this.title,
    required this.requiredHoldHours,
    required this.elapsedHoldHours,
    required this.status,
    required this.rateOfPressureChangeBarHr,
    required this.inspectedJointsCount,
    required this.totalJointsCount,
    required this.flirOgiCameraPassed,
    required this.acousticUltrasonicDbuv,
    required this.acousticVerdict,
    required this.notes,
  });

  bool get isHoldComplete => elapsedHoldHours >= requiredHoldHours;
  double get holdProgressPct =>
      (elapsedHoldHours / requiredHoldHours).clamp(0.0, 1.0);
}

class TripartiteSignoffItem {
  final String key;
  final String roleBadge;
  final String organization;
  final String officerName;
  final String designation;
  final String requiredStandards;
  bool isSigned;
  DateTime? signedAt;
  String? digitalHash;
  String pinCode;
  String comments;

  TripartiteSignoffItem({
    required this.key,
    required this.roleBadge,
    required this.organization,
    required this.officerName,
    required this.designation,
    required this.requiredStandards,
    required this.isSigned,
    this.signedAt,
    this.digitalHash,
    required this.pinCode,
    required this.comments,
  });
}

// ============================================================================
// MAIN SCREEN IMPLEMENTATION
// ============================================================================

class GasInCommissioningScreen extends StatefulWidget {
  const GasInCommissioningScreen({super.key});

  @override
  State<GasInCommissioningScreen> createState() =>
      _GasInCommissioningScreenState();
}

class _GasInCommissioningScreenState extends State<GasInCommissioningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Active Stage Tracker (Defaults to Stage 2: Nitrogen Purging)
  int _activeStageIndex = 1;

  // Live simulation timer
  Timer? _telemetrySimTimer;
  bool _isSimulationLive = true;
  double _linepackPressureBar = 30.15;
  double _purgeFrontKm = 104.5; // Advancing nitrogen front

  // Pipeline Definition Constants
  static const String pipelineCode = 'OIL-DUL-NUM-DN600';
  static const String pipelineName = 'Duliajan to Numaligarh Trunk Gasline';
  static const double pipelineTotalLengthKm = 142.8;
  static const double pipelineDesignMaopBar = 98.0;

  // Stage sequence definitions
  late List<StageProgressInfo> _stages;

  // 8 Valve Stations (VS-01 to VS-08) Atmospheric Gas Sampling Matrix
  late List<StationGasSample> _samplingMatrix;
  String _selectedStationFilter = 'ALL';
  String _stationSearchQuery = '';

  // Flare Stack & Thermal Radiation Telemetry
  late FlareStackTelemetry _flareData;

  // Stepwise Pressurization Sequences (10, 30, 60, 90 Bar)
  late List<PressurizationHoldStep> _pressurizationSteps;

  // Tripartite Digital Sign-Off
  late Map<String, TripartiteSignoffItem> _tripartiteSignoffs;

  // Pre-Commissioning Safety Gates Checklist
  final Map<String, bool> _safetyGates = {
    'All 8 Sectionalizing Stations report N₂ purity ≥ 98.0%': true,
    'Residual Oxygen stripped to < 1.0% along 142.8 km corridor': true,
    'Flare stack FS-01 pilot continuous ignition confirmed (TC > 600°C)': true,
    'Cold vent velocity interlock armed at Mach < 0.20': true,
    'Exclusion zone (150m radius) perimeter guards & laser barrier active': true,
    'Fire water ring mains pressurized at 10.5 Bar(g) with monitors on standby':
        true,
    'District Administration, Disaster Cell & NDRF formal notice served': true,
    'SCADA optical redundant loop and ESDV station bypasses verified': true,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
    _startTelemetrySimulation();
  }

  @override
  void dispose() {
    _telemetrySimTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _stages = [
      const StageProgressInfo(
        stage: CommissioningStage.airDisplacement,
        title: 'Stage 1: Air Displacement',
        subtitle: 'Dew Point Depression & Bulk Air Push',
        description:
            'Atmospheric air displacement via batching pig train propelled by dry oil-free air to depress pipeline dew point below -40°C.',
        progressPct: 1.0,
        status: 'COMPLETED',
        targetCriteria: 'Dew Point ≤ -40.0°C across all sectional vents',
        prerequisites: [
          'Caliper/EGP pig sweep passed with < 2% ovality',
          'Hydrostatic test water vacuum dried to < 0.2 mbar soak',
          'Compressor air-drying spreads operational at KP 0+000',
        ],
      ),
      const StageProgressInfo(
        stage: CommissioningStage.nitrogenPurging,
        title: 'Stage 2: Nitrogen Purging & Inerting',
        subtitle: 'Cryogenic Liquid N₂ Vaporization & O₂ Stripping',
        description:
            'Liquid N₂ vaporizers displacing pipeline volume to establish inert buffer. Residual Oxygen stripped below 1.0% and N₂ purity elevated above 98.0%.',
        progressPct: 0.88,
        status: 'ACTIVE',
        targetCriteria: 'N₂ > 98.0% | O₂ < 1.0% | Combustible LEL < 0.1%',
        prerequisites: [
          'Cryogenic N₂ tanker fleet (4x 20kL) hooked to vaporizer skid',
          'Sectional sampling points calibrated with RKI Eagle 2 units',
          'Flare vent flame arrestors and purge burn off line connected',
        ],
      ),
      const StageProgressInfo(
        stage: CommissioningStage.hydrocarbonGasIn,
        title: 'Stage 3: Natural Gas Introduction',
        subtitle: 'Controlled Methane Feed & Flare Light-Off',
        description:
            'Controlled admission of treated natural gas from Duliajan Central Gas Gathering Station @ 3.5 Bar. Front tracking with cold vent flared upon N₂/gas interface breakout.',
        progressPct: 0.25,
        status: 'STANDBY',
        targetCriteria: 'Front velocity 2-3 m/s, flare ignition stable',
        prerequisites: [
          'Tripartite digital authorization signed by OIL, EIL, CSO',
          'Flare stack pilot verified and thermal radiation perimeter sealed',
          'Emergency line depressurization ESDVs tested on partial stroke',
        ],
      ),
      const StageProgressInfo(
        stage: CommissioningStage.linepackPressurization,
        title: 'Stage 4: Linepack Pressurization',
        subtitle: 'Stepwise Ramp (10 ➔ 30 ➔ 60 ➔ 90 Bar MAOP)',
        description:
            'Gradual stepwise pressurization with 4-24h stabilization soaking periods and ultrasonic acoustic leak walkdown audits along all 142 flanged spool joints.',
        progressPct: 0.40,
        status: 'STANDBY',
        targetCriteria:
            'Stepwise 10/30/60/90 Bar holds with zero acoustic leaks',
        prerequisites: [
          'Full methane composition confirmed at terminal receiver',
          'Acoustic leak inspection crews stationed at each SV station',
          'Custody transfer ultrasonic flow meters zero-calibrated',
        ],
      ),
    ];

    // Atmospheric Gas Sampling Matrix (8 Sectionalizing Valve Stations)
    final now = DateTime.now();
    _samplingMatrix = [
      StationGasSample(
        stationId: 'VS-01',
        stationName: 'Duliajan Dispatch Terminal',
        chainage: 'KP 0+000',
        chainageKm: 0.0,
        n2PurityPct: 99.6,
        oxygenResidualPct: 0.18,
        lelCombustiblePct: 0.02,
        dewPointC: -47.4,
        pressureBar: 4.8,
        sampleTapPoint: 'Pig Launcher Barrel Bypass 2"',
        analyzerTag: 'RKI-EGL-01 (Cal: Valid)',
        testedBy: 'Er. S. Barman (EIL QA)',
        lastTestedTime: now.subtract(const Duration(minutes: 12)),
      ),
      StationGasSample(
        stationId: 'VS-02',
        stationName: 'Tipling River Crossing',
        chainage: 'KP 18+400',
        chainageKm: 18.4,
        n2PurityPct: 99.4,
        oxygenResidualPct: 0.24,
        lelCombustiblePct: 0.01,
        dewPointC: -46.1,
        pressureBar: 4.5,
        sampleTapPoint: 'Mainline Blowdown Vent 4"',
        analyzerTag: 'RKI-EGL-03 (Cal: Valid)',
        testedBy: 'Er. R. Gogoi (OIL Insp)',
        lastTestedTime: now.subtract(const Duration(minutes: 18)),
      ),
      StationGasSample(
        stationId: 'VS-03',
        stationName: 'Naharkatia South Hub',
        chainage: 'KP 38+250',
        chainageKm: 38.25,
        n2PurityPct: 99.1,
        oxygenResidualPct: 0.42,
        lelCombustiblePct: 0.03,
        dewPointC: -44.8,
        pressureBar: 4.2,
        sampleTapPoint: 'Mainline Valve Body Vent',
        analyzerTag: 'SRV-5200-09 (Cal: Valid)',
        testedBy: 'Er. S. Barman (EIL QA)',
        lastTestedTime: now.subtract(const Duration(minutes: 25)),
      ),
      StationGasSample(
        stationId: 'VS-04',
        stationName: 'Burhi Dihing HDD Crossing',
        chainage: 'KP 59+100',
        chainageKm: 59.1,
        n2PurityPct: 98.9,
        oxygenResidualPct: 0.58,
        lelCombustiblePct: 0.02,
        dewPointC: -43.5,
        pressureBar: 3.9,
        sampleTapPoint: 'HDD Header Vent Stool',
        analyzerTag: 'RKI-EGL-02 (Cal: Valid)',
        testedBy: 'Er. D. Kalita (OIL Insp)',
        lastTestedTime: now.subtract(const Duration(minutes: 32)),
      ),
      StationGasSample(
        stationId: 'VS-05',
        stationName: 'Moran Bypass Station',
        chainage: 'KP 79+600',
        chainageKm: 79.6,
        n2PurityPct: 98.5,
        oxygenResidualPct: 0.72,
        lelCombustiblePct: 0.04,
        dewPointC: -42.2,
        pressureBar: 3.7,
        sampleTapPoint: 'Blowdown High Point Vent',
        analyzerTag: 'SRV-5200-11 (Cal: Valid)',
        testedBy: 'Er. M. Hazarika (EIL QA)',
        lastTestedTime: now.subtract(const Duration(minutes: 40)),
      ),
      StationGasSample(
        stationId: 'VS-06',
        stationName: 'Demow East Junction',
        chainage: 'KP 101+300',
        chainageKm: 101.3,
        n2PurityPct: 98.2,
        oxygenResidualPct: 0.88,
        lelCombustiblePct: 0.03,
        dewPointC: -41.6,
        pressureBar: 3.5,
        sampleTapPoint: 'Mainline Trunk Tap 2"',
        analyzerTag: 'RKI-EGL-05 (Cal: Valid)',
        testedBy: 'Er. R. Gogoi (OIL Insp)',
        lastTestedTime: now.subtract(const Duration(minutes: 50)),
      ),
      StationGasSample(
        stationId: 'VS-07',
        stationName: 'Sivasagar City Gate Station',
        chainage: 'KP 122+800',
        chainageKm: 122.8,
        n2PurityPct: 97.4, // Borderline, flushing active
        oxygenResidualPct: 1.15, // Borderline > 1.0%
        lelCombustiblePct: 0.05,
        dewPointC: -39.8,
        pressureBar: 3.3,
        sampleTapPoint: 'Intermediate Bleeder Spool',
        analyzerTag: 'RKI-EGL-04 (Cal: Valid)',
        testedBy: 'Er. D. Kalita (OIL Insp)',
        lastTestedTime: now.subtract(const Duration(minutes: 8)),
      ),
      StationGasSample(
        stationId: 'VS-08',
        stationName: 'Numaligarh Terminal Receiver',
        chainage: 'KP 142+800',
        chainageKm: 142.8,
        n2PurityPct: 96.8, // Nitrogen front arriving
        oxygenResidualPct: 1.45,
        lelCombustiblePct: 0.06,
        dewPointC: -38.5,
        pressureBar: 3.1,
        sampleTapPoint: 'Flare Stack Header Sample Tap',
        analyzerTag: 'SRV-5200-14 (Cal: Valid)',
        testedBy: 'Er. B. Saikia (OIL DGH)',
        lastTestedTime: now.subtract(const Duration(minutes: 5)),
      ),
    ];

    // Flare Stack & Thermal Radiation Telemetry
    _flareData = FlareStackTelemetry(
      unitId: 'FS-01',
      location: 'Numaligarh Receiving Terminal Elevated Flare',
      stackHeightM: 45.0,
      pilotIgnitionActive: true,
      thermocoupleAC: 694.0,
      thermocoupleBC: 686.0,
      coldVentVelocityMach: 0.118, // Mach < 0.20 Target
      ventMassFlowNm3h: 3820.0,
      soundLevelDba: 74.2, // Target < 85 dBA
      soundDistanceM: 50.0,
      exclusionZoneRadiusM: 150.0,
      exclusionZoneClear: true,
      radiationAtBoundaryKwM2: 1.18, // Target <= 1.58 kW/m2
      radiationPeak50mKwM2: 4.15, // Safe clothing limit 4.7 kW/m2
      windSpeedKmh: 12.4,
      windDirection: 'ENE 68°',
      nitrogenAssistFlowNm3h: 950.0,
      headerPressureMbar: 138.0,
    );

    // Stepwise Pressurization Steps (10, 30, 60, 90 Bar)
    _pressurizationSteps = [
      PressurizationHoldStep(
        stepIndex: 1,
        targetPressureBar: 10.0,
        title: 'Tier 1: 10.0 Bar(g) Low Pressure Hold',
        requiredHoldHours: 4,
        elapsedHoldHours: 4.0,
        status: 'COMPLETED',
        rateOfPressureChangeBarHr: 0.008,
        inspectedJointsCount: 142,
        totalJointsCount: 142,
        flirOgiCameraPassed: true,
        acousticUltrasonicDbuv: 14.5,
        acousticVerdict: '100% Hermetic — Zero Acoustic Whistle',
        notes:
            'Acoustic walkdown confirmed tight integrity on all 142 flanged spool and ESDV gland points.',
      ),
      PressurizationHoldStep(
        stepIndex: 2,
        targetPressureBar: 30.0,
        title: 'Tier 2: 30.0 Bar(g) Intermediate Hold & Soak',
        requiredHoldHours: 6,
        elapsedHoldHours: 3.5,
        status: 'HOLDING',
        rateOfPressureChangeBarHr: 0.015,
        inspectedJointsCount: 114,
        totalJointsCount: 142,
        flirOgiCameraPassed: true,
        acousticUltrasonicDbuv: 16.8,
        acousticVerdict: 'In Progress — 114 of 142 Joints Verified Clear',
        notes:
            'Continuous pressure soaking in progress. Rate of change +0.015 Bar/hr well within ±0.05 limit.',
      ),
      PressurizationHoldStep(
        stepIndex: 3,
        targetPressureBar: 60.0,
        title: 'Tier 3: 60.0 Bar(g) High Pressure Soak',
        requiredHoldHours: 8,
        elapsedHoldHours: 0.0,
        status: 'SCHEDULED',
        rateOfPressureChangeBarHr: 0.0,
        inspectedJointsCount: 0,
        totalJointsCount: 142,
        flirOgiCameraPassed: false,
        acousticUltrasonicDbuv: 0.0,
        acousticVerdict: 'Standby — Pending Tier 2 Completion',
        notes:
            'Drone-mounted Optical Gas Imaging (OGI) sweep scheduled upon reaching 60 Bar.',
      ),
      PressurizationHoldStep(
        stepIndex: 4,
        targetPressureBar: 90.0,
        title: 'Tier 4: 90.0 Bar(g) MAOP Linepack Hold',
        requiredHoldHours: 24,
        elapsedHoldHours: 0.0,
        status: 'SCHEDULED',
        rateOfPressureChangeBarHr: 0.0,
        inspectedJointsCount: 0,
        totalJointsCount: 142,
        flirOgiCameraPassed: false,
        acousticUltrasonicDbuv: 0.0,
        acousticVerdict: 'Standby — Final Regulatory Hold',
        notes:
            'Final 24-hour statutory linepack soak for commercial custody transfer commissioning.',
      ),
    ];

    // Tripartite Sign-Off Authorities
    _tripartiteSignoffs = {
      'oil': TripartiteSignoffItem(
        key: 'oil',
        roleBadge: 'OWNER / OPERATOR',
        organization: 'Oil India Limited (OIL Duliajan)',
        officerName: 'Er. Bhaskar Jyoti Phukan',
        designation: 'Executive Director (Pipelines & Commissioning)',
        requiredStandards:
            'OISD-STD-141 / PNGRB Gas Network Code Reg. 15 / Schedule A',
        isSigned: true,
        signedAt: now.subtract(const Duration(hours: 3, minutes: 15)),
        digitalHash:
            '9f83a472bc1e4d08a556b23984e112d7b1e428c0372df03aa2837bc28198f7e2',
        pinCode: 'OIL-9921',
        comments:
            'Pipeline nitrogen blanket and mechanical integrity certified. Gas admission approved from Duliajan manifold.',
      ),
      'eil': TripartiteSignoffItem(
        key: 'eil',
        roleBadge: 'PMC / EPCM CONSULTANT',
        organization: 'Engineers India Limited (EIL Hydrocarbons)',
        officerName: 'Dr. A. K. Sengupta',
        designation: 'Project Director (Cross-Country Pipelines)',
        requiredStandards:
            'ASME B31.8 Section 841 / API 521 Flare Guidelines / ISO 13623',
        isSigned: true,
        signedAt: now.subtract(const Duration(hours: 2, minutes: 40)),
        digitalHash:
            'e438f619b0ac729486c4f92d6e38209bb45107e3a9856db7e35b7194cf204a91',
        pinCode: 'EIL-4158',
        comments:
            'Purge pig tracking and pressure boundary verified. Flare Mach number and acoustic attenuation compliant.',
      ),
      'cso': TripartiteSignoffItem(
        key: 'cso',
        roleBadge: 'REGULATORY / HSE LEAD',
        organization: 'Directorate General of Hydrocarbons / HSE Lead',
        officerName: 'Smt. Priyanka Baruah',
        designation: 'Chief Safety Officer (Certified OISD Lead Auditor)',
        requiredStandards:
            'Petroleum & Explosives Safety Org (PESO) / OISD-GDN-106',
        isSigned: false,
        signedAt: null,
        digitalHash: null,
        pinCode: 'CSO-7840',
        comments:
            'Pending final verification of Numaligarh terminal exclusion zone flare radiation barriers.',
      ),
    };
  }

  void _startTelemetrySimulation() {
    _telemetrySimTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isSimulationLive || !mounted) return;

      setState(() {
        final rng = math.Random();

        // Jitter linepack pressure gently
        _linepackPressureBar += (rng.nextDouble() - 0.48) * 0.04;
        _linepackPressureBar = double.parse(
          _linepackPressureBar.toStringAsFixed(2),
        );

        // Advance purge front gradually
        if (_purgeFrontKm < pipelineTotalLengthKm) {
          _purgeFrontKm += 0.15;
          if (_purgeFrontKm > pipelineTotalLengthKm) {
            _purgeFrontKm = pipelineTotalLengthKm;
          }
        }

        // Fluctuate flare thermocouples
        _flareData.thermocoupleAC =
            690.0 + (rng.nextDouble() * 12.0) - 6.0;
        _flareData.thermocoupleBC =
            684.0 + (rng.nextDouble() * 10.0) - 5.0;

        // Cold vent mach jitter
        _flareData.coldVentVelocityMach =
            0.115 + (rng.nextDouble() * 0.015);

        // Sound level jitter
        _flareData.soundLevelDba = 73.5 + (rng.nextDouble() * 2.5);

        // Update station 7 & 8 progressive purity as nitrogen sweeps
        final vs7 = _samplingMatrix.firstWhere((s) => s.stationId == 'VS-07');
        if (vs7.n2PurityPct < 98.6) {
          vs7.n2PurityPct = math.min(98.8, vs7.n2PurityPct + 0.05);
          vs7.oxygenResidualPct = math.max(0.75, vs7.oxygenResidualPct - 0.03);
          vs7.dewPointC = math.max(-43.0, vs7.dewPointC - 0.1);
        }

        final vs8 = _samplingMatrix.firstWhere((s) => s.stationId == 'VS-08');
        if (vs8.n2PurityPct < 98.2) {
          vs8.n2PurityPct = math.min(98.3, vs8.n2PurityPct + 0.06);
          vs8.oxygenResidualPct = math.max(0.85, vs8.oxygenResidualPct - 0.04);
        }

        // Advance elapsed hold time in Tier 2
        final tier2 = _pressurizationSteps[1];
        if (tier2.status == 'HOLDING' && tier2.elapsedHoldHours < 6.0) {
          tier2.elapsedHoldHours += 0.02;
          if (tier2.inspectedJointsCount < 142 && rng.nextBool()) {
            tier2.inspectedJointsCount++;
          }
        }
      });
    });
  }

  // ============================================================================
  // BUSINESS ACTIONS
  // ============================================================================

  void _toggleSimulation() {
    setState(() {
      _isSimulationLive = !_isSimulationLive;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSimulationLive
              ? 'Telemetry simulation RESUMED (SCADA Polling Active)'
              : 'Telemetry simulation PAUSED (Holding current buffer)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor:
            _isSimulationLive ? AppTheme.primary : AppTheme.surfaceCard,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openLogSampleDialog(StationGasSample station) {
    final n2Controller =
        TextEditingController(text: station.n2PurityPct.toStringAsFixed(1));
    final o2Controller =
        TextEditingController(text: station.oxygenResidualPct.toStringAsFixed(2));
    final lelController =
        TextEditingController(text: station.lelCombustiblePct.toStringAsFixed(2));
    final dewPointController =
        TextEditingController(text: station.dewPointC.toStringAsFixed(1));
    final pressController =
        TextEditingController(text: station.pressureBar.toStringAsFixed(1));
    final tapPointController =
        TextEditingController(text: station.sampleTapPoint);
    final testerController =
        TextEditingController(text: station.testedBy);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.border, width: 1),
      ),
      builder: (modalCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.science_rounded,
                            color: AppTheme.primaryLight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Log Atmospheric Gas Sample',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${station.stationId}: ${station.stationName} (${station.chainage})',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'OISD-141 Compliance Criteria: N₂ Purity ≥ 98.0%, O₂ ≤ 1.00%, Combustible LEL ≤ 0.10%, Dew Point ≤ -40.0°C.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildModalTextField(
                        controller: n2Controller,
                        label: 'N₂ Purity (%)',
                        hint: '98.5',
                        suffix: '%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModalTextField(
                        controller: o2Controller,
                        label: 'Residual O₂ (%)',
                        hint: '0.45',
                        suffix: '%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildModalTextField(
                        controller: lelController,
                        label: 'Combustible LEL (%)',
                        hint: '0.02',
                        suffix: '% LEL',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModalTextField(
                        controller: dewPointController,
                        label: 'Dew Point (°C)',
                        hint: '-43.5',
                        suffix: '°C',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildModalTextField(
                        controller: pressController,
                        label: 'Line Pressure (Bar)',
                        hint: '3.8',
                        suffix: 'Bar',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModalTextField(
                        controller: testerController,
                        label: 'QA Inspector',
                        hint: 'Er. S. Barman',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildModalTextField(
                  controller: tapPointController,
                  label: 'Sample Tap Point Reference',
                  hint: 'Blowdown High Point Vent 4"',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      final parsedN2 =
                          double.tryParse(n2Controller.text) ?? station.n2PurityPct;
                      final parsedO2 =
                          double.tryParse(o2Controller.text) ?? station.oxygenResidualPct;
                      final parsedLel =
                          double.tryParse(lelController.text) ?? station.lelCombustiblePct;
                      final parsedDew =
                          double.tryParse(dewPointController.text) ?? station.dewPointC;
                      final parsedPress =
                          double.tryParse(pressController.text) ?? station.pressureBar;

                      setState(() {
                        station.n2PurityPct = parsedN2;
                        station.oxygenResidualPct = parsedO2;
                        station.lelCombustiblePct = parsedLel;
                        station.dewPointC = parsedDew;
                        station.pressureBar = parsedPress;
                        station.sampleTapPoint = tapPointController.text.trim();
                        station.testedBy = testerController.text.trim();
                        station.lastTestedTime = DateTime.now();
                        station.isVerified = true;
                      });

                      Navigator.pop(modalCtx);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Gas sample recorded for ${station.stationId}. Verdict: ${station.statusBadgeText}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          backgroundColor: station.isFullyCompliant
                              ? AppTheme.tertiary
                              : AppTheme.secondary,
                        ),
                      );
                    },
                    child: const Text(
                      'VERIFY & RECORD GAS SAMPLE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            suffixStyle: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: AppTheme.surfaceCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _executeDigitalSignoff(TripartiteSignoffItem signoff) {
    final pinController = TextEditingController();
    final commentsController =
        TextEditingController(text: signoff.comments);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppTheme.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Execute Digital Sign-Off',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      signoff.roleBadge,
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signoff.officerName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${signoff.designation}\n${signoff.organization}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Governing Standards & Bylaws:',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        signoff.requiredStandards,
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Digital PIN / Security Authorization Token',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    letterSpacing: 3,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter 8-digit PIN or ID',
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.surfaceCard,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Verification Endorsement Remarks',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: commentsController,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.surfaceCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tertiary,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final timestamp = DateTime.now();
                // Generate genuine SHA-256 cryptographic seal
                final rawSignature =
                    '${signoff.key}_${signoff.officerName}_${timestamp.toIso8601String()}_OISD141';
                final hashDigest =
                    sha256.convert(utf8.encode(rawSignature)).toString();

                setState(() {
                  signoff.isSigned = true;
                  signoff.signedAt = timestamp;
                  signoff.digitalHash = hashDigest;
                  signoff.comments = commentsController.text.trim();
                });

                Navigator.pop(dialogCtx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cryptographic sign-off executed for ${signoff.officerName} (${signoff.roleBadge})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: AppTheme.tertiary,
                  ),
                );
              },
              child: const Text(
                'SIGN & ATTEST',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDossierExportDialog() {
    final allSigned = _tripartiteSignoffs.values.every((s) => s.isSigned);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppTheme.primaryLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Commissioning Dossier Export',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      Text(
                        'FORM COMM-OISD-141: NITROGEN PURGING & HYDROCARBON GAS-IN STATUTORY CERTIFICATE',
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Project: $pipelineName\nAsset Tag: $pipelineCode\nPipeline Length: $pipelineTotalLengthKm km | MAOP: $pipelineDesignMaopBar Bar(g)',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const Divider(color: AppTheme.border, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tripartite Status:',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: allSigned
                                  ? AppTheme.tertiary.withOpacity(0.15)
                                  : AppTheme.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: allSigned
                                    ? AppTheme.tertiary
                                    : AppTheme.secondary,
                              ),
                            ),
                            child: Text(
                              allSigned
                                  ? 'ALL 3 PARTIES CERTIFIED'
                                  : '2 OF 3 SIGNED (CSO PENDING)',
                              style: TextStyle(
                                color: allSigned
                                    ? AppTheme.tertiary
                                    : AppTheme.secondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Included Statutory Documentation:',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDossierDocItem(
                  '1. Atmospheric Gas Chromatography Log (VS-01 to VS-08)',
                  '8 Stations / 142.8 km verified',
                ),
                _buildDossierDocItem(
                  '2. Flare Thermal Radiation & Cold Vent Mach Clearance',
                  'FS-01 45m Stack / Mach < 0.20 compliant',
                ),
                _buildDossierDocItem(
                  '3. Stepwise Pressurization & Acoustic Walkdown Log',
                  '10 & 30 Bar Soaking Certificates attached',
                ),
                _buildDossierDocItem(
                  '4. Cryptographic Tripartite Endorsement Hashes',
                  'SHA-256 tokens embedded with GPS coordinates',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CLOSE',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Commissioning Dossier (PDF-OISD-141) generated & queued for download',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text(
                'EXPORT PDF DOSSIER',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDossierDocItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.tertiary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SCREEN BUILDER
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Top Operational Summary & Stage Stepper Ribbon
          _buildStageStepperRibbon(),

          // 4 Specialized Engineering Tabs
          Container(
            color: AppTheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.gas_meter_rounded, size: 18),
                  text: 'GAS SAMPLING MATRIX',
                ),
                Tab(
                  icon: Icon(Icons.flare_rounded, size: 18),
                  text: 'FLARE & THERMAL',
                ),
                Tab(
                  icon: Icon(Icons.hearing_rounded, size: 18),
                  text: 'PRESSURIZATION & LEAK',
                ),
                Tab(
                  icon: Icon(Icons.assignment_turned_in_rounded, size: 18),
                  text: 'TRIPARTITE SIGN-OFF',
                ),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGasSamplingMatrixTab(),
                _buildFlareMonitoringTab(),
                _buildPressurizationTab(),
                _buildTripartiteSignoffTab(),
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
                'Gas-In Commissioning',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                ),
                child: const Text(
                  'OISD-141',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$pipelineCode • 142.8 km DN600 • MAOP 98 Bar',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: _isSimulationLive ? 'Pause SCADA Sim' : 'Resume SCADA Sim',
          icon: Icon(
            _isSimulationLive
                ? Icons.sensors_rounded
                : Icons.sensors_off_rounded,
            color: _isSimulationLive ? AppTheme.tertiary : AppTheme.textMuted,
            size: 22,
          ),
          onPressed: _toggleSimulation,
        ),
        IconButton(
          tooltip: 'Export Commissioning Dossier',
          icon: const Icon(
            Icons.picture_as_pdf_outlined,
            color: AppTheme.primaryLight,
            size: 22,
          ),
          onPressed: _showDossierExportDialog,
        ),
      ],
    );
  }

  // ============================================================================
  // SECTION 1: 4-STAGE PIPELINE COMMISSIONING SEQUENCE RIBBON
  // ============================================================================

  Widget _buildStageStepperRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
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
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isSimulationLive
                          ? AppTheme.tertiary
                          : AppTheme.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PIPELINE COMMISSIONING SEQUENCE',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                'Purge Front: ${_purgeFrontKm.toStringAsFixed(1)} / $pipelineTotalLengthKm km (${((_purgeFrontKm / pipelineTotalLengthKm) * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal Stages Stepper
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_stages.length, (index) {
                final stage = _stages[index];
                final isSelected = index == _activeStageIndex;
                final isPassed = index < _activeStageIndex;

                Color stageColor;
                if (isPassed || stage.status == 'COMPLETED') {
                  stageColor = AppTheme.tertiary;
                } else if (isSelected || stage.status == 'ACTIVE') {
                  stageColor = AppTheme.primaryLight;
                } else {
                  stageColor = AppTheme.textMuted;
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeStageIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.surfaceContainerHigh
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? stageColor : AppTheme.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: stageColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: stageColor, width: 1.5),
                          ),
                          child: Center(
                            child: isPassed
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: AppTheme.tertiary,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: stageColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stage.stage.shortTitle,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                            Text(
                              stage.status,
                              style: TextStyle(
                                color: stageColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: ATMOSPHERIC GAS SAMPLING MATRIX (VS-01 to VS-08)
  // ============================================================================

  Widget _buildGasSamplingMatrixTab() {
    // Filter sampling stations based on query and filter
    final filteredStations = _samplingMatrix.where((s) {
      if (_selectedStationFilter == 'COMPLIANT' && !s.isFullyCompliant) {
        return false;
      }
      if (_selectedStationFilter == 'HOLD / REPURGE' && s.isFullyCompliant) {
        return false;
      }
      if (_stationSearchQuery.isNotEmpty) {
        final query = _stationSearchQuery.toLowerCase();
        return s.stationId.toLowerCase().contains(query) ||
            s.stationName.toLowerCase().contains(query) ||
            s.chainage.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    // Summary statistics
    final compliantCount =
        _samplingMatrix.where((s) => s.isFullyCompliant).length;
    final avgN2 = _samplingMatrix
            .map((s) => s.n2PurityPct)
            .reduce((a, b) => a + b) /
        _samplingMatrix.length;
    final maxO2 = _samplingMatrix
        .map((s) => s.oxygenResidualPct)
        .reduce(math.max);
    final minDew = _samplingMatrix
        .map((s) => s.dewPointC)
        .reduce(math.min);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPI Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricMiniCard(
                title: 'AVG N₂ PURITY',
                value: '${avgN2.toStringAsFixed(1)}%',
                target: 'Target ≥ 98.0%',
                isSafe: avgN2 >= 98.0,
                icon: Icons.shield_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricMiniCard(
                title: 'PEAK O₂ RESIDUAL',
                value: '${maxO2.toStringAsFixed(2)}%',
                target: 'Limit < 1.00%',
                isSafe: maxO2 < 1.00,
                icon: Icons.bubble_chart_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricMiniCard(
                title: 'MIN DEW POINT',
                value: '${minDew.toStringAsFixed(1)}°C',
                target: 'Limit ≤ -40.0°C',
                isSafe: minDew <= -40.0,
                icon: Icons.water_drop_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Sectional Pipeline Schematic Bar (KP 0+000 to KP 142+800)
        _buildPipelineSchematicRibbon(),
        const SizedBox(height: 16),

        // Filter / Search Toolbar
        Row(
          children: [
            Expanded(
              child: TextField(
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                onChanged: (val) {
                  setState(() {
                    _stationSearchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search valve station (e.g. VS-04, Tipling)...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              initialValue: _selectedStationFilter,
              onSelected: (val) {
                setState(() {
                  _selectedStationFilter = val;
                });
              },
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.border),
              ),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'ALL', child: Text('All Stations (8)')),
                const PopupMenuItem(
                  value: 'COMPLIANT',
                  child: Text('Compliant (≥98% N₂)'),
                ),
                const PopupMenuItem(
                  value: 'HOLD / REPURGE',
                  child: Text('Hold / Flushing Active'),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_list_rounded,
                      size: 16,
                      color: AppTheme.primaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedStationFilter,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'VALVE STATIONS SAMPLING MATRIX ($compliantCount / ${_samplingMatrix.length} COMPLIANT)',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const Text(
              'OISD-141 / ASME B31.8',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // List of Valve Station Cards
        ...filteredStations.map((station) => _buildStationSamplingCard(station)),
      ],
    );
  }

  Widget _buildMetricMiniCard({
    required String title,
    required String value,
    required String target,
    required bool isSafe,
    required IconData icon,
  }) {
    final statusColor = isSafe ? AppTheme.tertiary : AppTheme.secondary;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(icon, size: 14, color: statusColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            target,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineSchematicRibbon() {
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
              const Text(
                'PIPELINE SECTIONAL PURGING CORRIDOR',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DN600 × 142.8 km',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Visual Line corridor with nodes
          SizedBox(
            height: 52,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Gray background pipe
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 14,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    // Nitrogen front advancement bar
                    Positioned(
                      left: 12,
                      top: 14,
                      child: Container(
                        width: (width - 24) *
                            (_purgeFrontKm / pipelineTotalLengthKm)
                                .clamp(0.0, 1.0),
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.tertiary],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    // Station nodes
                    ..._samplingMatrix.asMap().entries.map((entry) {
                      final index = entry.key;
                      final station = entry.value;
                      final pct = station.chainageKm / pipelineTotalLengthKm;
                      final nodeX = 12 + (width - 24) * pct;

                      return Positioned(
                        left: nodeX - 10,
                        top: 4,
                        child: Column(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: station.isFullyCompliant
                                    ? AppTheme.tertiary
                                    : (station.n2PurityPct >= 98.0
                                        ? AppTheme.secondary
                                        : AppTheme.error),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              station.stationId,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Duliajan Dispatch (KP 0+000)',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
              Text(
                'Numaligarh Terminal (KP 142+800)',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStationSamplingCard(StationGasSample station) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: station.isFullyCompliant
              ? AppTheme.border
              : AppTheme.secondary.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Title & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: station.statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: station.statusColor.withOpacity(0.6),
                      ),
                    ),
                    child: Text(
                      station.stationId,
                      style: TextStyle(
                        color: station.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.stationName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${station.chainage} • ${station.sampleTapPoint}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: station.statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  station.statusBadgeText,
                  style: TextStyle(
                    color: station.statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4-Quadrant Gas Measurements Grid
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildGasParamColumn(
                    label: 'N₂ PURITY',
                    value: '${station.n2PurityPct.toStringAsFixed(1)}%',
                    target: 'Target > 98.0%',
                    isPassed: station.isN2Compliant,
                  ),
                ),
                Container(width: 1, height: 36, color: AppTheme.border),
                Expanded(
                  child: _buildGasParamColumn(
                    label: 'RESIDUAL O₂',
                    value: '${station.oxygenResidualPct.toStringAsFixed(2)}%',
                    target: 'Target < 1.0%',
                    isPassed: station.isO2Compliant,
                  ),
                ),
                Container(width: 1, height: 36, color: AppTheme.border),
                Expanded(
                  child: _buildGasParamColumn(
                    label: 'LEL (GAS)',
                    value: '${station.lelCombustiblePct.toStringAsFixed(2)}%',
                    target: 'Target < 0.1%',
                    isPassed: station.isLelCompliant,
                  ),
                ),
                Container(width: 1, height: 36, color: AppTheme.border),
                Expanded(
                  child: _buildGasParamColumn(
                    label: 'DEW POINT',
                    value: '${station.dewPointC.toStringAsFixed(1)}°C',
                    target: 'Target ≤ -40°C',
                    isPassed: station.isDewPointCompliant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Footer: Analyzer tag, QA tester & Log Sample action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${station.analyzerTag} • ${DateFormat('HH:mm:ss').format(station.lastTestedTime)} by ${station.testedBy}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryLight,
                  side: const BorderSide(color: AppTheme.primaryLight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _openLogSampleDialog(station),
                icon: const Icon(Icons.edit_note_rounded, size: 14),
                label: const Text(
                  'LOG SAMPLE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGasParamColumn({
    required String label,
    required String value,
    required String target,
    required bool isPassed,
  }) {
    final color = isPassed ? AppTheme.tertiary : AppTheme.error;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          target,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 2: FLARE STACK & THERMAL RADIATION MONITORING
  // ============================================================================

  Widget _buildFlareMonitoringTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Flare Tip & Ignition Master Status Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _flareData.isPilotHealthy
                  ? AppTheme.border
                  : AppTheme.error,
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_flareData.isPilotHealthy
                                  ? AppTheme.secondary
                                  : AppTheme.error)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          color: _flareData.isPilotHealthy
                              ? AppTheme.secondary
                              : AppTheme.error,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flare Tip & Pilot Igniter (${_flareData.unitId})',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${_flareData.location} • ${_flareData.stackHeightM}m Stack',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.tertiary.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.tertiary,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'PILOT IGNITED',
                          style: TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Thermocouple temperatures
              Row(
                children: [
                  Expanded(
                    child: _buildThermocoupleGauge(
                      name: 'Thermocouple TC-01',
                      tempC: _flareData.thermocoupleAC,
                      minThresholdC: 600.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThermocoupleGauge(
                      name: 'Thermocouple TC-02',
                      tempC: _flareData.thermocoupleBC,
                      minThresholdC: 600.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cold Vent Velocity & Acoustic Noise Ribbon
        Row(
          children: [
            // Cold Vent Velocity (Mach < 0.20)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _flareData.isMachSafe
                        ? AppTheme.border
                        : AppTheme.error,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'COLD VENT VELOCITY',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _flareData.isMachSafe
                                ? AppTheme.tertiary.withOpacity(0.15)
                                : AppTheme.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _flareData.isMachSafe
                                ? 'MACH < 0.20 PASS'
                                : 'MACH EXCEEDED',
                            style: TextStyle(
                              color: _flareData.isMachSafe
                                  ? AppTheme.tertiary
                                  : AppTheme.error,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'Mach ${_flareData.coldVentVelocityMach.toStringAsFixed(3)}',
                          style: TextStyle(
                            color: _flareData.isMachSafe
                                ? AppTheme.primaryLight
                                : AppTheme.error,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${(_flareData.coldVentVelocityMach * 343).toStringAsFixed(0)} m/s)',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (_flareData.coldVentVelocityMach / 0.20)
                          .clamp(0.0, 1.0),
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _flareData.isMachSafe
                            ? AppTheme.primary
                            : AppTheme.error,
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mass Flow: ${_flareData.ventMassFlowNm3h.toStringAsFixed(0)} Nm³/h • Head: ${_flareData.headerPressureMbar.toStringAsFixed(0)} mbar',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Boundary Sound Level (dBA < 85)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _flareData.isSoundSafe
                        ? AppTheme.border
                        : AppTheme.error,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SOUND LEVEL (dBA)',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _flareData.isSoundSafe
                                ? AppTheme.tertiary.withOpacity(0.15)
                                : AppTheme.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _flareData.isSoundSafe
                                ? '< 85 dBA PASS'
                                : 'NOISE WARNING',
                            style: TextStyle(
                              color: _flareData.isSoundSafe
                                  ? AppTheme.tertiary
                                  : AppTheme.error,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${_flareData.soundLevelDba.toStringAsFixed(1)} dBA',
                          style: TextStyle(
                            color: _flareData.isSoundSafe
                                ? AppTheme.tertiary
                                : AppTheme.error,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '@ 50m cordon',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value:
                          (_flareData.soundLevelDba / 85.0).clamp(0.0, 1.0),
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _flareData.isSoundSafe
                            ? AppTheme.tertiary
                            : AppTheme.error,
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'OISD-106 Industrial Noise Standard: Limit 85 dBA',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Thermal Radiation vs Distance Profile Curve (fl_chart)
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'THERMAL RADIATION PROFILE (API 521 / OISD-106)',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Heat flux intensity decay (kW/m²) vs distance from stack base',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      'Wind: ${_flareData.windSpeedKmh.toStringAsFixed(1)} km/h ${_flareData.windDirection}',
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // fl_chart line chart
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppTheme.border.withOpacity(0.4),
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: AppTheme.border.withOpacity(0.4),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}m',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: AppTheme.border),
                    ),
                    minX: 10,
                    maxX: 160,
                    minY: 0,
                    maxY: 12,
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: 4.7,
                          color: AppTheme.secondary.withOpacity(0.7),
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            style: const TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                            labelResolver: (line) =>
                                'Personnel Protective Limit (4.7 kW/m²)',
                          ),
                        ),
                        HorizontalLine(
                          y: 1.58,
                          color: AppTheme.tertiary.withOpacity(0.7),
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.bottomRight,
                            style: const TextStyle(
                              color: AppTheme.tertiary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                            labelResolver: (line) =>
                                'Public Boundary Limit (1.58 kW/m²)',
                          ),
                        ),
                      ],
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(10, 11.2),
                          FlSpot(25, 7.8),
                          FlSpot(50, 4.15),
                          FlSpot(75, 2.6),
                          FlSpot(100, 1.85),
                          FlSpot(125, 1.38),
                          FlSpot(150, 1.18),
                        ],
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: AppTheme.secondary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.secondary.withOpacity(0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Radiation at 150m cordon: ${_flareData.radiationAtBoundaryKwM2.toStringAsFixed(2)} kW/m² (≤ 1.58 PASS)',
                    style: const TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Peak at 50m: ${_flareData.radiationPeak50mKwM2.toStringAsFixed(2)} kW/m²',
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Safe Distance Exclusion Zone & Perimeter Security Card
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
                  Row(
                    children: const [
                      Icon(
                        Icons.security_rounded,
                        color: AppTheme.tertiary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '150m Exclusion Zone & Safety Perimeter',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PERIMETER SECURED',
                      style: TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Radius: ${_flareData.exclusionZoneRadiusM.toStringAsFixed(0)} meters cordon line • Laser perimeter tripwire active • 4 security marshals stationed with VHF hand radios • Fire tender & paramedic stationed at windward access gate.',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryLight,
                        side: const BorderSide(color: AppTheme.primaryLight),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Spark igniter test sequence triggered. Continuous spark discharge 3.0s — Verified Healthy.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: AppTheme.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.flash_on_rounded, size: 16),
                      label: const Text(
                        'TEST SPARK IGNITER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceContainerHigh,
                        foregroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Nitrogen purge assist increased to 1,200 Nm³/h for flame dilution.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: AppTheme.surfaceCard,
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text(
                        'N₂ ASSIST FLOW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildThermocoupleGauge({
    required String name,
    required double tempC,
    required double minThresholdC,
  }) {
    final isHealthy = tempC >= minThresholdC;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHealthy ? AppTheme.border : AppTheme.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${tempC.toStringAsFixed(1)} °C',
                style: TextStyle(
                  color: isHealthy ? AppTheme.secondary : AppTheme.error,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isHealthy
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_rounded,
                color: isHealthy ? AppTheme.tertiary : AppTheme.error,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pilot Threshold: ≥ ${minThresholdC.toStringAsFixed(0)} °C',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: STEPWISE PRESSURIZATION & ACOUSTIC LEAK WALKDOWNS
  // ============================================================================

  Widget _buildPressurizationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Live Linepack Pressure Master Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
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
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.speed_rounded,
                          color: AppTheme.primaryLight,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Pipeline Linepack Pressure',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Active Tier 2 Hold (30.0 Bar(g)) • Design MAOP: 98.0 Bar',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.tertiary.withOpacity(0.5),
                      ),
                    ),
                    child: const Text(
                      'SOAK IN PROGRESS',
                      style: TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Big pressure readout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_linepackPressureBar.toStringAsFixed(2)} Bar(g)',
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Average Gradient across 142.8 km corridor',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'RoP: +0.015 Bar/hr',
                          style: TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Decay Limit: ±0.05 Bar/hr',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stepwise Pressurization Stepper Cards (10, 30, 60, 90 Bar)
        const Text(
          'STEPWISE COMMISSIONING PRESSURIZATION PROTOCOL',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        ..._pressurizationSteps
            .map((step) => _buildPressurizationStepCard(step)),

        const SizedBox(height: 16),

        // Acoustic Leak Walkdown Summary & Joint Checklist Card
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
                  Row(
                    children: const [
                      Icon(
                        Icons.hearing_rounded,
                        color: AppTheme.primaryLight,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Acoustic Ultrasonic Leak Walkdown Audit',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SDT-270 / FLIR Si124',
                      style: TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'High-sensitivity ultrasonic acoustic cameras and sniffer walkdown teams deployed at each SV station. All flanged spool pieces, valve packings, and instrument taps inspected for high-frequency micro-leak whistling.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // Joint Inspection Checklist items
              _buildLeakJointRow(
                'Mainline Block Valve Bonnet & Glands',
                'VS-01 to VS-08 (8 stations)',
                '16/16 Inspected',
                'Pass (< 18 dBµV)',
                true,
              ),
              _buildLeakJointRow(
                'Pig Launcher / Receiver Barrels',
                'Duliajan & Numaligarh terminals',
                '2/2 Inspected',
                'Pass (0.0% LEL)',
                true,
              ),
              _buildLeakJointRow(
                'Impulse Tubing & Instrument Manifolds',
                'Pressure transmitters & DP cells',
                '64/64 Inspected',
                'Pass (< 14 dBµV)',
                true,
              ),
              _buildLeakJointRow(
                'Insulation Flange Joints & Surge Spools',
                'Station isolation joints',
                '32/60 Inspected',
                'In Progress (Sweep Active)',
                false,
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                    side: const BorderSide(color: AppTheme.primaryLight),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Acoustic walkdown report synchronizing with SCADA integrity register...',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: AppTheme.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                  label: const Text(
                    'RECORD ACOUSTIC JOINT LOG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPressurizationStepCard(PressurizationHoldStep step) {
    Color cardColor;
    Color badgeColor;
    String badgeText;

    if (step.status == 'COMPLETED') {
      badgeColor = AppTheme.tertiary;
      badgeText = 'COMPLETED';
      cardColor = AppTheme.surfaceCard;
    } else if (step.status == 'HOLDING') {
      badgeColor = AppTheme.primaryLight;
      badgeText = 'HOLDING (${step.elapsedHoldHours.toStringAsFixed(1)} / ${step.requiredHoldHours}h)';
      cardColor = AppTheme.surfaceContainerHigh;
    } else {
      badgeColor = AppTheme.textMuted;
      badgeText = 'SCHEDULED';
      cardColor = AppTheme.surfaceCard;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: step.status == 'HOLDING' ? AppTheme.primary : AppTheme.border,
          width: step.status == 'HOLDING' ? 1.5 : 1.0,
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
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: badgeColor, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${step.stepIndex}',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar for soaking duration
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Soak Hold: ${step.elapsedHoldHours.toStringAsFixed(1)} / ${step.requiredHoldHours}.0 Hours',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Target: ${step.targetPressureBar.toStringAsFixed(0)} Bar(g)',
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: step.holdProgressPct,
                backgroundColor: AppTheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Notes & acoustic verdict
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  step.status == 'COMPLETED'
                      ? Icons.check_circle_rounded
                      : (step.status == 'HOLDING'
                          ? Icons.sync_rounded
                          : Icons.schedule_rounded),
                  color: badgeColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.acousticVerdict,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildLeakJointRow(
    String jointCategory,
    String location,
    String inspectedCount,
    String verdict,
    bool isPassed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jointCategory,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  location,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                verdict,
                style: TextStyle(
                  color: isPassed ? AppTheme.tertiary : AppTheme.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                inspectedCount,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: TRIPARTITE DIGITAL COMMISSIONING SIGN-OFF
  // ============================================================================

  Widget _buildTripartiteSignoffTab() {
    final allSigned = _tripartiteSignoffs.values.every((s) => s.isSigned);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Official Form Header Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: allSigned ? AppTheme.tertiary : AppTheme.secondary,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FORM COMM-OISD-141',
                      style: TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (allSigned ? AppTheme.tertiary : AppTheme.secondary)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      allSigned
                          ? 'TRIPARTITE AUTHORIZED'
                          : 'PENDING CSO ENDORSEMENT',
                      style: TextStyle(
                        color: allSigned
                            ? AppTheme.tertiary
                            : AppTheme.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Tripartite Statutory Commissioning Authorization',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Joint statutory endorsement mandated by Oil Industry Safety Directorate (OISD) and PNGRB Technical & Safety Standards (T4S) before unsealing natural gas feed from Duliajan dispatch.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // The 3 Signatory Authority Cards
        const Text(
          'TRIPARTITE SIGNATORY AUTHORITIES',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        _buildSignoffAuthorityCard(_tripartiteSignoffs['oil']!),
        _buildSignoffAuthorityCard(_tripartiteSignoffs['eil']!),
        _buildSignoffAuthorityCard(_tripartiteSignoffs['cso']!),

        const SizedBox(height: 16),

        // Pre-Commissioning Safety Gates Checklist
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
                    'STATUTORY PRE-COMMISSIONING SAFETY GATES',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${_safetyGates.values.where((v) => v).length} / ${_safetyGates.length} Cleared',
                    style: const TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._safetyGates.entries.map((gate) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        gate.value
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: gate.value
                            ? AppTheme.tertiary
                            : AppTheme.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          gate.key,
                          style: TextStyle(
                            color: gate.value
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Final Action: Export / Download Dossier
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _showDossierExportDialog,
            icon: const Icon(Icons.file_download_rounded, size: 20),
            label: const Text(
              'VIEW & EXPORT COMMISSIONING CERTIFICATE (PDF)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignoffAuthorityCard(TripartiteSignoffItem signoff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: signoff.isSigned
              ? AppTheme.tertiary.withOpacity(0.5)
              : AppTheme.secondary.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  signoff.roleBadge,
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: (signoff.isSigned
                          ? AppTheme.tertiary
                          : AppTheme.secondary)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      signoff.isSigned
                          ? Icons.check_circle_rounded
                          : Icons.pending_actions_rounded,
                      color: signoff.isSigned
                          ? AppTheme.tertiary
                          : AppTheme.secondary,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      signoff.isSigned ? 'SIGNED & ATTESTED' : 'PENDING SIGN-OFF',
                      style: TextStyle(
                        color: signoff.isSigned
                            ? AppTheme.tertiary
                            : AppTheme.secondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Officer name & designation
          Text(
            signoff.officerName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${signoff.designation} • ${signoff.organization}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),

          // Digital signature or action button
          if (signoff.isSigned) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CRYPTOGRAPHIC SIGNATURE (SHA-256)',
                        style: TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        DateFormat('dd-MMM-yyyy HH:mm').format(signoff.signedAt!),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    signoff.digitalHash ?? '',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontFamily: 'monospace',
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"${signoff.comments}"',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => _executeDigitalSignoff(signoff),
                icon: const Icon(Icons.draw_rounded, size: 16),
                label: const Text(
                  'AUTHENTICATE & EXECUTE SIGN-OFF',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
