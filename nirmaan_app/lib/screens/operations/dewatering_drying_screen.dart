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
// DOMAIN MODELS & ENUMS
// ============================================================================

enum DryingPhase {
  dewateringPigTrain,
  swabbingPigs,
  superDryPurging,
  soakStabilizationTest,
  completedCertified,
}

extension DryingPhaseExt on DryingPhase {
  String get title {
    switch (this) {
      case DryingPhase.dewateringPigTrain:
        return 'Phase 1: Disc Pig De-watering';
      case DryingPhase.swabbingPigs:
        return 'Phase 2: Foam Swabbing (< 0.1 mm)';
      case DryingPhase.superDryPurging:
        return 'Phase 3: Air/N₂ Purge (-40°C ADP)';
      case DryingPhase.soakStabilizationTest:
        return 'Phase 4: 24-Hr Soak (ΔTdp ≤ 2°C)';
      case DryingPhase.completedCertified:
        return 'Phase 5: ASME/OISD Certified';
    }
  }

  String get shortName {
    switch (this) {
      case DryingPhase.dewateringPigTrain:
        return 'De-watering';
      case DryingPhase.swabbingPigs:
        return 'Swabbing';
      case DryingPhase.superDryPurging:
        return 'Purging';
      case DryingPhase.soakStabilizationTest:
        return '24h Soak';
      case DryingPhase.completedCertified:
        return 'Certified';
    }
  }

  IconData get icon {
    switch (this) {
      case DryingPhase.dewateringPigTrain:
        return Icons.water_drop_rounded;
      case DryingPhase.swabbingPigs:
        return Icons.cleaning_services_rounded;
      case DryingPhase.superDryPurging:
        return Icons.air_rounded;
      case DryingPhase.soakStabilizationTest:
        return Icons.timer_rounded;
      case DryingPhase.completedCertified:
        return Icons.verified_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DryingPhase.dewateringPigTrain:
        return const Color(0xFF0284C7);
      case DryingPhase.swabbingPigs:
        return const Color(0xFFFFB95F);
      case DryingPhase.superDryPurging:
        return const Color(0xFF38BDF8);
      case DryingPhase.soakStabilizationTest:
        return const Color(0xFFA78BFA);
      case DryingPhase.completedCertified:
        return const Color(0xFF4EDEA3);
    }
  }
}

class PipelineSectionConfig {
  final String id;
  final String tag;
  final String name;
  final String chainage;
  final double lengthKm;
  final double outerDiaInch;
  final double wallThicknessMm;
  final double innerDiaMm;
  final double totalWaterVolumeM3;
  final double designPressureBar;
  final double hydrotestPressureBar;
  final double holdingSumpCapacityM3;
  final String launcherStation;
  final String receiverStation;
  final List<String> valveStations;

  const PipelineSectionConfig({
    required this.id,
    required this.tag,
    required this.name,
    required this.chainage,
    required this.lengthKm,
    required this.outerDiaInch,
    required this.wallThicknessMm,
    required this.innerDiaMm,
    required this.totalWaterVolumeM3,
    required this.designPressureBar,
    required this.hydrotestPressureBar,
    required this.holdingSumpCapacityM3,
    required this.launcherStation,
    required this.receiverStation,
    required this.valveStations,
  });

  double get internalAreaSqM => (math.pi / 4) * math.pow(innerDiaMm / 1000.0, 2);
  double get internalCircumferenceM => math.pi * (innerDiaMm / 1000.0);
}

class SwabRunEntry {
  final int runNumber;
  final String swabType;
  final double densityKgM3;
  final double dryWeightKg;
  final double wetWeightKg;
  final double waterTrappedKg;
  final double calculatedFilmThicknessMm;
  final double runSpeedKmH;
  final double drivePressureBar;
  final bool isCompliant;
  final DateTime timestamp;
  final String notes;

  const SwabRunEntry({
    required this.runNumber,
    required this.swabType,
    required this.densityKgM3,
    required this.dryWeightKg,
    required this.wetWeightKg,
    required this.waterTrappedKg,
    required this.calculatedFilmThicknessMm,
    required this.runSpeedKmH,
    required this.drivePressureBar,
    required this.isCompliant,
    required this.timestamp,
    required this.notes,
  });
}

class SoakHourEntry {
  final int hour;
  final DateTime timestamp;
  final double dewPointC;
  final double deltaTdpC;
  final double linepackPressureBar;
  final double pipeWallTempC;
  final double waterVaporGM3;
  final bool isPassed;
  final String remarks;

  const SoakHourEntry({
    required this.hour,
    required this.timestamp,
    required this.dewPointC,
    required this.deltaTdpC,
    required this.linepackPressureBar,
    required this.pipeWallTempC,
    required this.waterVaporGM3,
    required this.isPassed,
    required this.remarks,
  });
}

class ComplianceClause {
  final String clause;
  final String standard;
  final String title;
  final String requirement;
  final String observedValue;
  final bool isVerified;
  final String auditor;

  const ComplianceClause({
    required this.clause,
    required this.standard,
    required this.title,
    required this.requirement,
    required this.observedValue,
    required this.isVerified,
    required this.auditor,
  });
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class DewateringDryingScreen extends StatefulWidget {
  const DewateringDryingScreen({super.key});

  @override
  State<DewateringDryingScreen> createState() => _DewateringDryingScreenState();
}

class _DewateringDryingScreenState extends State<DewateringDryingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _simulationTimer;
  bool _isSimulating = true;

  // Pipeline Sections Catalog
  static const List<PipelineSectionConfig> _sections = [
    PipelineSectionConfig(
      id: 'SEC-01',
      tag: 'SEC-01: Duliajan to Digboi',
      name: 'Duliajan CPF Dispatch to Digboi Terminal',
      chainage: 'KP 0.00 to KP 48.50',
      lengthKm: 48.50,
      outerDiaInch: 24.0,
      wallThicknessMm: 12.7,
      innerDiaMm: 584.2,
      totalWaterVolumeM3: 13001.0,
      designPressureBar: 98.0,
      hydrotestPressureBar: 125.0,
      holdingSumpCapacityM3: 15000.0,
      launcherStation: 'Duliajan CPF Scraper Trap ST-01',
      receiverStation: 'Digboi Terminal Scraper Trap RT-01',
      valveStations: ['SV-01 (KP 12.4)', 'SV-02 (KP 24.8)', 'SV-03 (KP 37.1)'],
    ),
    PipelineSectionConfig(
      id: 'SEC-02',
      tag: 'SEC-02: Digboi to Moran',
      name: 'Digboi Station to Moran Junction SV-05',
      chainage: 'KP 48.50 to KP 112.30',
      lengthKm: 63.80,
      outerDiaInch: 24.0,
      wallThicknessMm: 12.7,
      innerDiaMm: 584.2,
      totalWaterVolumeM3: 17101.0,
      designPressureBar: 98.0,
      hydrotestPressureBar: 125.0,
      holdingSumpCapacityM3: 20000.0,
      launcherStation: 'Digboi Dispatch Scraper Trap ST-02',
      receiverStation: 'Moran Junction Scraper Trap RT-02',
      valveStations: ['SV-04 (KP 62.0)', 'SV-05 (KP 78.5)', 'SV-06 (KP 95.2)'],
    ),
    PipelineSectionConfig(
      id: 'SEC-03',
      tag: 'SEC-03: Moran to Jorhat',
      name: 'Moran Junction to Jorhat Main Terminal',
      chainage: 'KP 112.30 to KP 194.50',
      lengthKm: 82.20,
      outerDiaInch: 24.0,
      wallThicknessMm: 12.7,
      innerDiaMm: 584.2,
      totalWaterVolumeM3: 22033.0,
      designPressureBar: 98.0,
      hydrotestPressureBar: 125.0,
      holdingSumpCapacityM3: 25000.0,
      launcherStation: 'Moran Dispatch Scraper Trap ST-03',
      receiverStation: 'Jorhat Main Terminal Scraper Trap RT-03',
      valveStations: ['SV-07 (KP 132.0)', 'SV-08 (KP 154.5)', 'SV-09 (KP 175.2)'],
    ),
  ];

  late PipelineSectionConfig _selectedSection;
  final DryingPhase _currentPhase = DryingPhase.dewateringPigTrain;

  // Real-Time Dewatering Train Parameters
  double _pigChainageKp = 34.6;
  double _pigSpeedKmH = 3.85; // Regulated 3 to 5 km/hr
  final double _drivePressureBar = 10.0; // 10 Bar air drive
  double _backpressureBar = 8.35; // Modulating PID
  double _waterDischargeRateM3H = 188.5; // Discharge rate into holding sump
  double _cumulativeWaterEvacuatedM3 = 9274.0;
  bool _isPidSpeedRegulationActive = true;
  double _targetPigSpeed = 4.0; // km/hr target setpoint

  // Holding Sump Parameters
  double _sumpLevelPct = 61.8;
  final double _sumpTurbidityNtu = 4.2;
  final double _sumpH = 7.4;
  final bool _sumpAeratorActive = true;

  // Swabbing Run Parameters
  List<SwabRunEntry> _swabRuns = [];
  double _residualFilmThicknessMm = 0.043; // ASME B31.8 / OISD-141 Target < 0.1 mm

  // Super-Dry Air / Dry N2 Purging Telemetry
  final String _purgingMedium = 'Oil-Free Super Dry Air (Desiccant Skid)';
  final double _inletDewPointC = -65.4;
  double _outletDewPointC = -42.8; // Target <= -40.0°C
  static const double targetDewPointThresholdC = -40.0;
  final double _purgeAirFlowNm3H = 2650.0;
  final double _purgePressureBar = 3.2;
  bool _desiccantTowerAToB = true; // Tower A drying, Tower B regenerating
  int _desiccantCycleSeconds = 240;

  // 24-Hour Soak & Stabilization Test Telemetry
  final bool _isSoakTestRunning = true;
  final int _currentSoakHour = 24; // Hour 0 to 24
  static const double soakInitialDewPointC = -43.2;
  final double _soakCurrentDewPointC = -42.0;
  final double _soakPackPressureBar = 1.50; // Positive dry N2 pack pressure
  final double _soakPipeWallTempC = 22.0;
  List<SoakHourEntry> _soakLog = [];

  // Compliance Clauses
  late List<ComplianceClause> _complianceClauses;

  // Engineering Calculator Controllers
  final TextEditingController _calcLengthCtrl = TextEditingController(text: '48.5');
  final TextEditingController _calcDiaCtrl = TextEditingController(text: '584.2');
  final TextEditingController _calcSpeedCtrl = TextEditingController(text: '4.0');
  double _calcEvacVolResult = 13001.0;
  double _calcTravelTimeHrs = 12.1;
  double _calcDischargeFlowResult = 1074.5;

  final TextEditingController _swabMassGainCtrl = TextEditingController(text: '3.8');
  final TextEditingController _swabLengthCtrl = TextEditingController(text: '48.5');
  final TextEditingController _swabDiaCtrl = TextEditingController(text: '584.2');
  double _calcSwabFilmResult = 0.043;
  bool _calcSwabPasses = true;

  final TextEditingController _dpInputCtrl = TextEditingController(text: '-42.8');
  double _calcVaporResult = 0.098; // g/Nm3
  double _calcPpmvResult = 122.5;

  final TextEditingController _n2PackPressCtrl = TextEditingController(text: '1.5');
  final TextEditingController _n2VolCtrl = TextEditingController(text: '13001');
  double _calcN2GasNm3 = 32502.5;
  double _calcLinLiters = 46432.0;
  double _calcLinTonnes = 37.5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _selectedSection = _sections[0];
    _initSwabRuns();
    _initSoakLog();
    _initComplianceChecklist();
    _startSimulation();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _tabController.dispose();
    _calcLengthCtrl.dispose();
    _calcDiaCtrl.dispose();
    _calcSpeedCtrl.dispose();
    _swabMassGainCtrl.dispose();
    _swabLengthCtrl.dispose();
    _swabDiaCtrl.dispose();
    _dpInputCtrl.dispose();
    _n2PackPressCtrl.dispose();
    _n2VolCtrl.dispose();
    super.dispose();
  }

  void _initSwabRuns() {
    final now = DateTime.now();
    _swabRuns = [
      SwabRunEntry(
        runNumber: 1,
        swabType: 'Low-Density Bare Open-Cell PU (25 kg/m³)',
        densityKgM3: 25.0,
        dryWeightKg: 18.2,
        wetWeightKg: 154.5,
        waterTrappedKg: 136.3,
        calculatedFilmThicknessMm: 1.53,
        runSpeedKmH: 4.1,
        drivePressureBar: 2.4,
        isCompliant: false,
        timestamp: now.subtract(const Duration(hours: 36)),
        notes: 'Initial swab run after bulk dewatering pig train. Large free water pockets swept.',
      ),
      SwabRunEntry(
        runNumber: 2,
        swabType: 'Medium-Density Bare Foam (30 kg/m³)',
        densityKgM3: 30.0,
        dryWeightKg: 21.0,
        wetWeightKg: 58.4,
        waterTrappedKg: 37.4,
        calculatedFilmThicknessMm: 0.42,
        runSpeedKmH: 3.9,
        drivePressureBar: 2.8,
        isCompliant: false,
        timestamp: now.subtract(const Duration(hours: 30)),
        notes: 'Significant water reduction. Inversion cup seals wiped bottom dead-legs.',
      ),
      SwabRunEntry(
        runNumber: 3,
        swabType: 'High-Density Foam Swab with PU Coated Disc (35 kg/m³)',
        densityKgM3: 35.0,
        dryWeightKg: 24.5,
        wetWeightKg: 32.8,
        waterTrappedKg: 8.3,
        calculatedFilmThicknessMm: 0.093,
        runSpeedKmH: 3.7,
        drivePressureBar: 3.0,
        isCompliant: true,
        timestamp: now.subtract(const Duration(hours: 24)),
        notes: 'PASSED ASME B31.8 / OISD-141 limit (< 0.1 mm). Film thickness 0.093 mm.',
      ),
      SwabRunEntry(
        runNumber: 4,
        swabType: 'Verification Dry Swab (35 kg/m³)',
        densityKgM3: 35.0,
        dryWeightKg: 24.5,
        wetWeightKg: 28.3,
        waterTrappedKg: 3.8,
        calculatedFilmThicknessMm: 0.043,
        runSpeedKmH: 4.0,
        drivePressureBar: 3.1,
        isCompliant: true,
        timestamp: now.subtract(const Duration(hours: 18)),
        notes: 'Confirmatory dry swab pass. Film thickness 0.043 mm (< 0.1 mm). Clear for drying.',
      ),
    ];
    _residualFilmThicknessMm = _swabRuns.last.calculatedFilmThicknessMm;
  }

  void _initSoakLog() {
    final baseTime = DateTime.now().subtract(const Duration(hours: 24));
    _soakLog = [];

    // 25 data points (Hour 0 to Hour 24)
    final dpValues = [
      -43.2, -43.1, -43.1, -43.0, -43.0, -42.9, -42.8, -42.7,
      -42.6, -42.6, -42.5, -42.5, -42.4, -42.4, -42.3, -42.3,
      -42.2, -42.2, -42.2, -42.1, -42.1, -42.1, -42.0, -42.0, -42.0
    ];
    final pressValues = [
      1.52, 1.52, 1.51, 1.51, 1.51, 1.51, 1.50, 1.50,
      1.50, 1.50, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49,
      1.48, 1.48, 1.48, 1.48, 1.48, 1.48, 1.48, 1.48, 1.48
    ];
    final tempValues = [
      22.1, 22.0, 21.9, 21.8, 21.7, 21.5, 21.2, 20.8,
      20.4, 20.1, 19.8, 19.8, 20.2, 20.7, 21.3, 21.8,
      22.1, 22.4, 22.6, 22.5, 22.3, 22.2, 22.1, 22.0, 22.0
    ];

    for (int h = 0; h <= 24; h++) {
      final dp = dpValues[h];
      final delta = dp - soakInitialDewPointC;
      final vapor = _calculateWaterVaporContent(dp);
      _soakLog.add(
        SoakHourEntry(
          hour: h,
          timestamp: baseTime.add(Duration(hours: h)),
          dewPointC: dp,
          deltaTdpC: double.parse(delta.toStringAsFixed(2)),
          linepackPressureBar: pressValues[h],
          pipeWallTempC: tempValues[h],
          waterVaporGM3: vapor,
          isPassed: delta <= 2.0 && dp <= -40.0,
          remarks: h == 0
              ? 'Soak test initiated. Launcher & Receiver DBB valves sealed.'
              : (h == 24
                  ? '24-Hour Soak Final Acceptance: ΔTdp = +1.20°C (≤ 2.0°C). PASSED.'
                  : 'Continuous hermetic soak monitoring. No dry gas re-injection.'),
        ),
      );
    }
  }

  void _initComplianceChecklist() {
    _complianceClauses = [
      const ComplianceClause(
        clause: 'ASME B31.8 Sec 841.3.1',
        standard: 'ASME B31.8 / OISD-141',
        title: 'Post-Hydrotest Dewatering Pig Train',
        requirement: 'Dual high-density polyurethane disc pigs driven by oil-free air at 10 Bar',
        observedValue: 'Lead + Tail HD-PU disc pigs @ 10.0 Bar oil-free air. Clean sweep confirmed.',
        isVerified: true,
        auditor: 'OISD Accredited Inspector',
      ),
      const ComplianceClause(
        clause: 'OISD-141 Cl. 8.1.2',
        standard: 'OISD-141',
        title: 'Dewatering Pig Speed Control',
        requirement: 'Regulated speed between 3.0 to 5.0 km/hr to prevent water bypass',
        observedValue: 'Closed-loop PID receiver backpressure maintained 3.85 km/hr mean velocity.',
        isVerified: true,
        auditor: 'Client Lead Commissioning Engineer',
      ),
      const ComplianceClause(
        clause: 'OISD-141 Cl. 8.1.4',
        standard: 'OISD-141 / CPCB',
        title: 'Water Discharge & Sump Containment',
        requirement: 'Discharge into HDPE eco-lined holding basin with aeration & NTU monitoring',
        observedValue: '15,000 m³ geomembrane sump, turbidity 4.2 NTU, pH 7.4. Zero soil contamination.',
        isVerified: true,
        auditor: 'HSE Environmental Officer',
      ),
      const ComplianceClause(
        clause: 'ASME B31.8 Sec 841.3.2',
        standard: 'ASME B31.8',
        title: 'Swabbing Pig Residual Water Film',
        requirement: 'Successive foam swabbing until residual water film thickness < 0.1 mm',
        observedValue: 'Run #4 achieved 0.043 mm (Criteria < 0.100 mm strictly achieved).',
        isVerified: true,
        auditor: 'Quality Assurance Inspector',
      ),
      const ComplianceClause(
        clause: 'OISD-141 Cl. 8.2.1',
        standard: 'OISD-141',
        title: 'Super-Dry Purging Dew Point Spec',
        requirement: 'Inlet/outlet atmospheric dew point ≤ -40.0°C (water vapor < 0.128 g/Nm³)',
        observedValue: 'Outlet ADP -42.8°C with 0.098 g/Nm³ vapor content. Super-dry status certified.',
        isVerified: true,
        auditor: 'Third-Party NDT & QC Lead',
      ),
      const ComplianceClause(
        clause: 'ASME B31.8 Sec 841.3.3',
        standard: 'ASME B31.8 / OISD-141',
        title: '24-Hour Dew Point Soak & Stabilization Test',
        requirement: 'Delta_T_dp ≤ 2.0°C over 24 continuous hours under dry nitrogen pack',
        observedValue: 'ΔTdp = +1.20°C over 24h at 1.5 Bar(g) N₂ pack. Fully accepted without exception.',
        isVerified: true,
        auditor: 'OISD Pipeline Safety Board',
      ),
    ];
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isSimulating) return;

      setState(() {
        // Increment Pig chainage during dewatering
        if (_pigChainageKp < _selectedSection.lengthKm) {
          _pigChainageKp += (_pigSpeedKmH * 2.0 / 3600.0) * 15.0; // Simulated time warp
          if (_pigChainageKp > _selectedSection.lengthKm) {
            _pigChainageKp = _selectedSection.lengthKm;
          }
        }

        // Small realistic telemetry fluctuations
        final rng = math.Random();
        _pigSpeedKmH = double.parse((3.80 + rng.nextDouble() * 0.15).toStringAsFixed(2));
        _waterDischargeRateM3H = double.parse((186.0 + rng.nextDouble() * 5.0).toStringAsFixed(1));
        _backpressureBar = double.parse((8.30 + rng.nextDouble() * 0.10).toStringAsFixed(2));
        _cumulativeWaterEvacuatedM3 = math.min(
          _selectedSection.totalWaterVolumeM3,
          _cumulativeWaterEvacuatedM3 + 1.2,
        );
        _sumpLevelPct = (_cumulativeWaterEvacuatedM3 / _selectedSection.holdingSumpCapacityM3) * 100.0;
        _outletDewPointC = double.parse((-42.8 + (rng.nextDouble() * 0.2 - 0.1)).toStringAsFixed(1));

        // Desiccant cycle countdown
        _desiccantCycleSeconds -= 2;
        if (_desiccantCycleSeconds <= 0) {
          _desiccantCycleSeconds = 600; // 10 min cycle
          _desiccantTowerAToB = !_desiccantTowerAToB;
        }
      });
    });
  }

  double _calculateWaterVaporContent(double dewPointC) {
    // Formula for water vapor mass concentration in air (g/Nm3) based on saturation vapor pressure
    // Magnus-Tetens formula: Psat (hPa) = 6.112 * exp((17.67 * T) / (T + 243.5))
    // Vapor mass (g/Nm3) = (Psat / 1013.25) * 18.015 / 0.022414 / 1000 * 1000
    // At -40°C, Psat ~ 0.1285 hPa -> ~ 0.128 g/Nm3
    final double psatHpa = 6.112 * math.exp((17.67 * dewPointC) / (dewPointC + 243.5));
    final double vaporGM3 = (psatHpa / 1013.25) * (18.015 / 22.414);
    return double.parse(vaporGM3.toStringAsFixed(4));
  }

  void _onSectionSelected(PipelineSectionConfig section) {
    setState(() {
      _selectedSection = section;
      _pigChainageKp = 0.0;
      _cumulativeWaterEvacuatedM3 = 0.0;
      _sumpLevelPct = 0.0;
      _calcLengthCtrl.text = section.lengthKm.toString();
      _calcDiaCtrl.text = section.innerDiaMm.toString();
      _calcEvacVolResult = section.totalWaterVolumeM3;
      _n2VolCtrl.text = section.totalWaterVolumeM3.toInt().toString();
      _recalcEvacuationVolume();
    });
  }

  void _recalcEvacuationVolume() {
    final lenKm = double.tryParse(_calcLengthCtrl.text) ?? 48.5;
    final diaMm = double.tryParse(_calcDiaCtrl.text) ?? 584.2;
    final speed = double.tryParse(_calcSpeedCtrl.text) ?? 4.0;

    final diaM = diaMm / 1000.0;
    final areaSqM = (math.pi / 4.0) * math.pow(diaM, 2);
    final volM3 = areaSqM * (lenKm * 1000.0);
    final travelHrs = speed > 0 ? (lenKm / speed) : 0.0;
    final dischargeFlow = travelHrs > 0 ? (volM3 / travelHrs) : 0.0;

    setState(() {
      _calcEvacVolResult = double.parse(volM3.toStringAsFixed(1));
      _calcTravelTimeHrs = double.parse(travelHrs.toStringAsFixed(1));
      _calcDischargeFlowResult = double.parse(dischargeFlow.toStringAsFixed(1));
    });
  }

  void _recalcSwabFilm() {
    final massKg = double.tryParse(_swabMassGainCtrl.text) ?? 3.8;
    final lenKm = double.tryParse(_swabLengthCtrl.text) ?? 48.5;
    final diaMm = double.tryParse(_swabDiaCtrl.text) ?? 584.2;

    final diaM = diaMm / 1000.0;
    final lenM = lenKm * 1000.0;
    final internalWallAreaSqM = math.pi * diaM * lenM;

    // Mass / (1000 kg/m3 * Area) = film in meters -> * 1000 to mm
    final filmMm = internalWallAreaSqM > 0 ? (massKg / (1000.0 * internalWallAreaSqM)) * 1000.0 : 0.0;

    setState(() {
      _calcSwabFilmResult = double.parse(filmMm.toStringAsFixed(4));
      _calcSwabPasses = _calcSwabFilmResult < 0.100;
    });
  }

  void _recalcDewPointVapor() {
    final dp = double.tryParse(_dpInputCtrl.text) ?? -42.8;
    final vapor = _calculateWaterVaporContent(dp);
    // PPMv ~ (Psat / 1013.25) * 1e6
    final psatHpa = 6.112 * math.exp((17.67 * dp) / (dp + 243.5));
    final ppmv = (psatHpa / 1013.25) * 1000000.0;

    setState(() {
      _calcVaporResult = vapor;
      _calcPpmvResult = double.parse(ppmv.toStringAsFixed(1));
    });
  }

  void _recalcN2Inventory() {
    final pressBar = double.tryParse(_n2PackPressCtrl.text) ?? 1.5;
    final volM3 = double.tryParse(_n2VolCtrl.text) ?? 13001.0;

    // Normal m3 required = Vol * (P_abs / P_atm) = Vol * (pressBar + 1.013) / 1.013
    final n2Nm3 = volM3 * ((pressBar + 1.013) / 1.013);
    // 1 Nm3 GN2 = ~1.428 Liters Liquid N2 (expansion ratio 1:700)
    final linLiters = n2Nm3 / 0.700;
    // Density of LIN ~ 0.808 kg/L -> tonnes
    final linTonnes = (linLiters * 0.808) / 1000.0;

    setState(() {
      _calcN2GasNm3 = double.parse(n2Nm3.toStringAsFixed(1));
      _calcLinLiters = double.parse(linLiters.toStringAsFixed(1));
      _calcLinTonnes = double.parse(linTonnes.toStringAsFixed(1));
    });
  }

  String _generateCertificateHash() {
    final payload = 'ASME_B31.8_OISD-141_DEWATERING_DRYING_${_selectedSection.id}_'
        'FINAL_DP_${_soakCurrentDewPointC}_DELTA_${(_soakCurrentDewPointC - soakInitialDewPointC).toStringAsFixed(2)}_'
        'TIME_${DateTime.now().toIso8601String()}';
    return sha256.convert(utf8.encode(payload)).toString().toUpperCase();
  }

  void _showAddSwabRunDialog() {
    final typeCtrl = TextEditingController(text: 'Low-Density Bare Foam (28 kg/m³)');
    final dryCtrl = TextEditingController(text: '22.0');
    final wetCtrl = TextEditingController(text: '25.5');
    final speedCtrl = TextEditingController(text: '4.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.border),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.cleaning_services_rounded, color: AppTheme.secondary, size: 24),
            const SizedBox(width: 10),
            Text(
              'Log Swab Run #${_swabRuns.length + 1}',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ASME B31.8 / OISD-141 Residual Film Verification',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: typeCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Foam Swab Type & Density'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dryCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Dry Tare Mass (kg)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: wetCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Wet Mass Recv (kg)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: speedCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Swab Average Speed (km/h)'),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.primaryLight, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Acceptance Criteria: Calculated water film thickness must be < 0.1 mm.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
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
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final dry = double.tryParse(dryCtrl.text) ?? 22.0;
              final wet = double.tryParse(wetCtrl.text) ?? 25.5;
              final trapped = math.max(0.0, wet - dry);
              final diaM = _selectedSection.innerDiaMm / 1000.0;
              final lenM = _selectedSection.lengthKm * 1000.0;
              final wallArea = math.pi * diaM * lenM;
              final film = wallArea > 0 ? (trapped / (1000.0 * wallArea)) * 1000.0 : 0.0;
              final filmMm = double.parse(film.toStringAsFixed(4));
              final speed = double.tryParse(speedCtrl.text) ?? 4.0;

              final newEntry = SwabRunEntry(
                runNumber: _swabRuns.length + 1,
                swabType: typeCtrl.text,
                densityKgM3: 30.0,
                dryWeightKg: dry,
                wetWeightKg: wet,
                waterTrappedKg: double.parse(trapped.toStringAsFixed(2)),
                calculatedFilmThicknessMm: filmMm,
                runSpeedKmH: speed,
                drivePressureBar: 3.0,
                isCompliant: filmMm < 0.100,
                timestamp: DateTime.now(),
                notes: 'Field Swab Run #${_swabRuns.length + 1} logged via Nirmaan OS.',
              );

              setState(() {
                _swabRuns.add(newEntry);
                _residualFilmThicknessMm = filmMm;
              });

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: filmMm < 0.100 ? AppTheme.tertiary : AppTheme.secondary,
                  content: Text(
                    filmMm < 0.100
                        ? 'Swab Run #${newEntry.runNumber} PASSED (< 0.1 mm)! Film: ${filmMm}mm'
                        : 'Swab Run #${newEntry.runNumber} Logged: ${filmMm}mm (Target < 0.1 mm)',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            child: const Text('Submit Run Log'),
          ),
        ],
      ),
    );
  }

  void _showCertificateDialog() {
    final hash = _generateCertificateHash();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.tertiary, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.tertiary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PIPELINE DRYNESS CERTIFICATE',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'ASME B31.8 Sec 841.3 / OISD-141 Compliant',
                    style: TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.w600),
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
              _buildCertRow('Pipeline Section', _selectedSection.name),
              _buildCertRow('Chainage / Length', '${_selectedSection.chainage} (${_selectedSection.lengthKm} km)'),
              _buildCertRow('Pipe Specification', '${_selectedSection.outerDiaInch}" OD × ${_selectedSection.wallThicknessMm}mm WT (API 5L X70)'),
              _buildCertRow('De-watering Medium', 'Oil-Free Air @ 10 Bar (Dual HD-PU Disc Pigs)'),
              _buildCertRow('Residual Water Film', '0.043 mm (< 0.1 mm ASME B31.8 Spec)'),
              _buildCertRow('Purge Outlet ADP', '-42.8°C (Water Vapor 0.098 g/Nm³)'),
              _buildCertRow('24-Hr Soak Stability', 'ΔTdp = +1.20°C (Criteria ≤ 2.0°C) - PASSED'),
              _buildCertRow('Stabilization Pack', '1.50 Bar(g) 99.999% Dry Nitrogen'),
              const Divider(color: AppTheme.border, height: 24),
              const Text(
                'CRYPTOGRAPHIC AUDIT SEAL (SHA-256):',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: SelectableText(
                  hash,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ready for Natural Gas-In & Hydrocarbon Commissioning.',
                      style: TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.primary,
                  content: Text(
                    'Drying Dossier & Certificate Exported to Commissioning Archive.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Export Dossier PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildCertRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pipeline De-watering & Drying',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'ASME B31.8 Sec 841.3 • OISD-141 Post-Hydrotest Conditioning',
              style: TextStyle(
                color: AppTheme.primaryLight.withOpacity(0.9),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isSimulating ? 'Pause Telemetry Simulation' : 'Resume Telemetry Simulation',
            icon: Icon(
              _isSimulating ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
              color: _isSimulating ? AppTheme.secondary : AppTheme.tertiary,
            ),
            onPressed: () {
              setState(() => _isSimulating = !_isSimulating);
            },
          ),
          IconButton(
            tooltip: 'Pipeline Dryness Certificate',
            icon: const Icon(Icons.verified_outlined, color: AppTheme.tertiary),
            onPressed: _showCertificateDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(icon: Icon(Icons.view_quilt_rounded, size: 18), text: 'SCADA Synoptic'),
            Tab(icon: Icon(Icons.water_drop_rounded, size: 18), text: 'De-watering & Swabs'),
            Tab(icon: Icon(Icons.air_rounded, size: 18), text: 'Air/N₂ Purging'),
            Tab(icon: Icon(Icons.timer_rounded, size: 18), text: '24h Soak Test'),
            Tab(icon: Icon(Icons.calculate_rounded, size: 18), text: 'Calculators & Audit'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Section Selector Bar & Live Status Strip
          _buildSectionHeader(),

          // KPI Metric Header Strip
          _buildKpiMetricsStrip(),

          // Main Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSynopticTab(),
                _buildDewateringSwabsTab(),
                _buildPurgingTab(),
                _buildSoakTestTab(),
                _buildCalculatorsAuditTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION SELECTOR & KPI STRIP
  // ==========================================================================

  Widget _buildSectionHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.linear_scale_rounded, color: AppTheme.primaryLight, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Pipeline Section:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._sections.map((sec) {
                    final isSelected = sec.id == _selectedSection.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text('${sec.tag} (${sec.lengthKm} km)'),
                        selected: isSelected,
                        onSelected: (_) => _onSectionSelected(sec),
                        backgroundColor: AppTheme.surfaceCard,
                        selectedColor: AppTheme.primary.withOpacity(0.35),
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
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _currentPhase.color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _currentPhase.color.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(_currentPhase.icon, color: _currentPhase.color, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _currentPhase.shortName,
                          style: TextStyle(
                            color: _currentPhase.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.background,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiCard(
              title: 'PIG VELOCITY',
              value: '${_pigSpeedKmH.toStringAsFixed(2)} km/h',
              sub: 'Regulated: 3.0 – 5.0 km/h',
              icon: Icons.speed_rounded,
              color: (_pigSpeedKmH >= 3.0 && _pigSpeedKmH <= 5.0) ? AppTheme.tertiary : AppTheme.secondary,
              badge: 'PID ACTIVE',
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              title: 'DISCHARGE FLOW',
              value: '${_waterDischargeRateM3H.toStringAsFixed(1)} m³/h',
              sub: 'Sump: ${_sumpLevelPct.toStringAsFixed(1)}% full',
              icon: Icons.water_rounded,
              color: AppTheme.primaryLight,
              badge: '${_drivePressureBar.toStringAsFixed(0)} BAR AIR',
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              title: 'RESIDUAL WATER FILM',
              value: '${_residualFilmThicknessMm.toStringAsFixed(3)} mm',
              sub: 'ASME Criteria < 0.100 mm',
              icon: Icons.cleaning_services_rounded,
              color: _residualFilmThicknessMm < 0.100 ? AppTheme.tertiary : AppTheme.secondary,
              badge: _residualFilmThicknessMm < 0.100 ? 'COMPLIANT' : 'SWABBING',
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              title: 'OUTLET DEW POINT',
              value: '${_outletDewPointC.toStringAsFixed(1)} °C',
              sub: 'Target ≤ ${targetDewPointThresholdC.toStringAsFixed(0)} °C ADP',
              icon: Icons.cloud_outlined,
              color: _outletDewPointC <= targetDewPointThresholdC ? AppTheme.tertiary : AppTheme.secondary,
              badge: '< 0.128 g/Nm³',
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              title: '24-HR SOAK ΔTdp',
              value: '+${(_soakCurrentDewPointC - soakInitialDewPointC).toStringAsFixed(2)} °C',
              sub: 'Max Allowed ≤ 2.0 °C',
              icon: Icons.timer_rounded,
              color: (_soakCurrentDewPointC - soakInitialDewPointC) <= 2.0 ? AppTheme.tertiary : AppTheme.error,
              badge: 'HOUR $_currentSoakHour/24',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    required String badge,
  }) {
    return Container(
      width: 185,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: SCADA SYNOPTIC & DIGITAL TWIN
  // ==========================================================================

  Widget _buildSynopticTab() {
    final progressFraction = (_pigChainageKp / _selectedSection.lengthKm).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Schematic Header Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.surfaceCard, AppTheme.surfaceContainerHigh.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                        const Icon(Icons.precision_manufacturing_rounded, color: AppTheme.primaryLight, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'P&ID SCADA SYNOPTIC — ${_selectedSection.name}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.tertiary.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_tethering_rounded, color: AppTheme.tertiary, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'SCADA RTU ONLINE',
                            style: TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Launcher: ${_selectedSection.launcherStation} ──► Receiver: ${_selectedSection.receiverStation}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 16),

                // Cross Country Pipeline Track & Pig Location
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'LAUNCHER (KP 0.00)',
                            style: TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'TRAIN AT KP ${_pigChainageKp.toStringAsFixed(2)} (${(progressFraction * 100).toStringAsFixed(1)}%)',
                            style: const TextStyle(color: AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'RECEIVER (KP ${_selectedSection.lengthKm.toStringAsFixed(2)})',
                            style: const TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Graphic Pipe Track
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final width = constraints.maxWidth;
                          final pigOffset = (width - 32) * progressFraction;

                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              // Pipe outline
                              Container(
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.border),
                                ),
                              ),
                              // Water evacuated / dry section
                              Container(
                                width: (width * progressFraction).clamp(0.0, width),
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.35),
                                  borderRadius: BorderRadius.horizontal(
                                    left: const Radius.circular(4),
                                    right: Radius.circular(progressFraction >= 1.0 ? 4 : 0),
                                  ),
                                ),
                              ),
                              // Valve Stations Markers
                              ...List.generate(_selectedSection.valveStations.length, (idx) {
                                final ratio = (idx + 1) / (_selectedSection.valveStations.length + 1);
                                return Positioned(
                                  left: width * ratio - 6,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: progressFraction > ratio ? AppTheme.tertiary : AppTheme.border,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.circle, color: AppTheme.surfaceCard, size: 6),
                                    ),
                                  ),
                                );
                              }),
                              // Pig Train Marker
                              Positioned(
                                left: pigOffset,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.secondary.withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.double_arrow_rounded, color: Colors.black, size: 12),
                                      SizedBox(width: 2),
                                      Text(
                                        'DISC PIGS',
                                        style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      // Intermediate Valve Station Tags
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _selectedSection.valveStations.map((vs) {
                          return Text(
                            vs,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // P&ID Subsystems Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Launcher Subsystem
              Expanded(
                child: _buildSubsystemCard(
                  title: 'LAUNCHER SKID (KP 0.00)',
                  subtitle: 'Oil-Free Air Drive Unit',
                  icon: Icons.compress_rounded,
                  iconColor: AppTheme.primaryLight,
                  rows: [
                    _buildSubsystemRow('Drive Medium', 'Class 0 Oil-Free Air'),
                    _buildSubsystemRow('Discharge Press', '${_drivePressureBar.toStringAsFixed(1)} Bar(g)'),
                    _buildSubsystemRow('Comp Air Flow', '3,450 Nm³/hr'),
                    _buildSubsystemRow('Dew Point Feed', '${_inletDewPointC.toStringAsFixed(1)} °C ADP'),
                    _buildSubsystemRow('Kicker Valve', '100% OPEN'),
                    _buildSubsystemRow('Pinger Transmitter', '22 Hz Magnetic (ON)'),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Receiver Subsystem
              Expanded(
                child: _buildSubsystemCard(
                  title: 'RECEIVER SKID (KP ${_selectedSection.lengthKm})',
                  subtitle: 'Trap & Backpressure Throttle',
                  icon: Icons.inventory_2_rounded,
                  iconColor: AppTheme.secondary,
                  rows: [
                    _buildSubsystemRow('Backpressure', '${_backpressureBar.toStringAsFixed(2)} Bar(g)'),
                    _buildSubsystemRow('ΔP Across Train', '1.65 Bar'),
                    _buildSubsystemRow('PID Speed Control', _isPidSpeedRegulationActive ? 'AUTO (3-5 km/h)' : 'MANUAL'),
                    _buildSubsystemRow('Water Discharge', '${_waterDischargeRateM3H.toStringAsFixed(1)} m³/hr'),
                    _buildSubsystemRow('Bypass Throttle', '38.4% Modulation'),
                    _buildSubsystemRow('Pig Signaller 01', 'ARMED / CLEAR'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Holding Sump & Environmental Basin Card
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
                        Icon(Icons.waves_rounded, color: AppTheme.primaryLight, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'HOLDING SUMP & ENVIRONMENTAL DECANTATION BASIN',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'OISD-141 / CPCB COMPLIANT',
                        style: TextStyle(color: AppTheme.tertiary, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sump Fill: ${_cumulativeWaterEvacuatedM3.toInt()} / ${_selectedSection.holdingSumpCapacityM3.toInt()} m³',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                              Text(
                                '${_sumpLevelPct.toStringAsFixed(1)}%',
                                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (_sumpLevelPct / 100.0).clamp(0.0, 1.0),
                              minHeight: 12,
                              backgroundColor: AppTheme.background,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Eco-membrane: 2.0 mm HDPE Geomembrane with Leak Detection Geonet.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            _buildSubsystemRow('Turbidity', '${_sumpTurbidityNtu.toStringAsFixed(1)} NTU (< 5 NTU)'),
                            _buildSubsystemRow('pH Reading', '${_sumpH.toStringAsFixed(1)} (6.5 – 8.5)'),
                            _buildSubsystemRow('Freeboard Level', '1.85 m (Safe)'),
                            _buildSubsystemRow('Aerator Skid', _sumpAeratorActive ? 'ACTIVE' : 'OFF'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Speed Regulation Control Panel
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
                    Icon(Icons.tune_rounded, color: AppTheme.secondary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'PIG TRAIN CLOSED-LOOP SPEED REGULATION (3 to 5 km/hr)',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'ASME B31.8 Section 841.3 mandates tight velocity regulation: speeds exceeding 5 km/hr '
                  'induce air blow-by and water bypass; speeds below 3 km/hr cause stick-slip chattering.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Setpoint: ${_targetPigSpeed.toStringAsFixed(1)} km/hr',
                            style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Slider(
                            value: _targetPigSpeed,
                            min: 3.0,
                            max: 5.0,
                            divisions: 20,
                            label: '${_targetPigSpeed.toStringAsFixed(1)} km/h',
                            activeColor: AppTheme.secondary,
                            inactiveColor: AppTheme.surfaceContainerHigh,
                            onChanged: (val) {
                              setState(() => _targetPigSpeed = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        const Text('PID Loop Mode', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        const SizedBox(height: 4),
                        Switch(
                          value: _isPidSpeedRegulationActive,
                          activeColor: AppTheme.tertiary,
                          onChanged: (val) {
                            setState(() => _isPidSpeedRegulationActive = val);
                          },
                        ),
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

  Widget _buildSubsystemCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> rows,
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
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
          const Divider(color: AppTheme.border, height: 16),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildSubsystemRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: DE-WATERING PIG TRAIN & FOAM SWABBING
  // ==========================================================================

  Widget _buildDewateringSwabsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dewatering Pig Train Spec Card
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
                        Icon(Icons.engineering_rounded, color: AppTheme.primaryLight, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'DUAL HIGH-DENSITY DISC PIG TRAIN SPECIFICATIONS',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_drivePressureBar.toStringAsFixed(0)} BAR DRIVE AIR',
                        style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Two high-density polyurethane (HD-PU) bi-directional disc pigs are launched in train. '
                  'The lead pig displaces bulk hydrotest water; the tail batching pig captures liquid bypass. '
                  'Driven strictly with Class 0 oil-free air regulated at 10 Bar gauge.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LEAD PIG: 4-DISC HD-PU DISPLACEMENT',
                              style: TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            _buildSubsystemRow('Disc Material', '85 Shore A Cast Polyurethane'),
                            _buildSubsystemRow('Disc Interference', '3.5% Oversize (24.8" OD)'),
                            _buildSubsystemRow('Transmitter', '22 Hz Electromagnetic Pinger'),
                            _buildSubsystemRow('Seal Efficiency', '99.4% Bulk Water Removal'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TAIL PIG: 4-DISC BATCHING & SCRAPER',
                              style: TextStyle(color: AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            _buildSubsystemRow('Disc Material', '80 Shore A Polyurethane'),
                            _buildSubsystemRow('Slug Spacer', 'Corrosion Inhibitor Batch Slug'),
                            _buildSubsystemRow('Guide Discs', '2 Hard Polyurethane Guide Discs'),
                            _buildSubsystemRow('Seal Efficiency', '99.9% Bypass Capture'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Foam Swabbing Verification Card
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
                        Icon(Icons.cleaning_services_rounded, color: AppTheme.secondary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'FOAM SWABBING LOG & RESIDUAL WATER FILM (< 0.1 mm)',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddSwabRunDialog,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Log Swab Run'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'ASME B31.8 Section 841.3 requires sequential swabbing with low-density polyurethane swabs '
                  'until residual water film thickness across the pipeline circumference is less than 0.1 mm. '
                  'Calculated from tare weight vs received swab weight.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 12),

                // Table of Swab Runs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(AppTheme.background),
                    horizontalMargin: 12,
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('RUN #', style: TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('FOAM SWAB TYPE', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('DRY (KG)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('RECV (KG)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('WATER (KG)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('FILM (MM)', style: TextStyle(color: AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('STATUS', style: TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                    rows: _swabRuns.map((run) {
                      return DataRow(
                        cells: [
                          DataCell(Text('Run #${run.runNumber}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold))),
                          DataCell(Text(run.swabType, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10))),
                          DataCell(Text(run.dryWeightKg.toStringAsFixed(1), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                          DataCell(Text(run.wetWeightKg.toStringAsFixed(1), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                          DataCell(Text(run.waterTrappedKg.toStringAsFixed(1), style: const TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold))),
                          DataCell(Text(
                            '${run.calculatedFilmThicknessMm.toStringAsFixed(3)} mm',
                            style: TextStyle(
                              color: run.isCompliant ? AppTheme.tertiary : AppTheme.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: run.isCompliant ? AppTheme.tertiary.withOpacity(0.2) : AppTheme.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                run.isCompliant ? 'PASS (< 0.1mm)' : 'RE-SWAB',
                                style: TextStyle(
                                  color: run.isCompliant ? AppTheme.tertiary : AppTheme.secondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Calculation formula card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.functions_rounded, color: AppTheme.primaryLight, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Residual Water Film Thickness Formula (OISD-141 / ASME B31.8):',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'tw = ΔMwater / (ρwater × π × ID × L) = ${_residualFilmThicknessMm.toStringAsFixed(3)} mm',
                              style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Where ΔMwater = absorbed water mass (kg), ID = 584.2 mm, L = 48.5 km, ρwater = 1,000 kg/m³.',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: AIR / NITROGEN PURGING & DEW POINT MONITORING
  // ==========================================================================

  Widget _buildPurgingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purging Skid Configuration
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
                        Icon(Icons.air_rounded, color: AppTheme.primaryLight, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'SUPER-DRY AIR / DRY NITROGEN PURGE SKID',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _outletDewPointC <= targetDewPointThresholdC ? AppTheme.tertiary.withOpacity(0.15) : AppTheme.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _outletDewPointC <= targetDewPointThresholdC ? 'OUTLET ≤ -40°C (PASS)' : 'DRYING IN PROGRESS',
                        style: TextStyle(
                          color: _outletDewPointC <= targetDewPointThresholdC ? AppTheme.tertiary : AppTheme.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Purge Medium: $_purgingMedium • Flow: ${_purgeAirFlowNm3H.toStringAsFixed(0)} Nm³/hr @ ${_purgePressureBar.toStringAsFixed(1)} Bar(g)',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPurgeSkidCard(
                        title: 'TWIN-TOWER DESICCANT AIR DRYER',
                        status: 'ONLINE & REGENERATING',
                        icon: Icons.filter_drama_rounded,
                        details: [
                          'Tower A: ${_desiccantTowerAToB ? "DRYING (-65°C)" : "REGENERATING"}',
                          'Tower B: ${!_desiccantTowerAToB ? "DRYING (-65°C)" : "REGENERATING"}',
                          'Cycle Time Left: ${_desiccantCycleSeconds ~/ 60}m ${_desiccantCycleSeconds % 60}s',
                          'Desiccant: Activated Alumina (AA-400)',
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPurgeSkidCard(
                        title: 'CRYOGENIC NITROGEN (LIN) VAPORIZER',
                        status: 'STANDBY / PURGE PACK',
                        icon: Icons.ac_unit_rounded,
                        details: [
                          'Purity: 99.999% Dry Nitrogen',
                          'Dew Point: -68.5 °C ADP',
                          'Flow Capacity: 4,000 Nm³/hr',
                          'Liquid Inventory: 2 × 20,000L Cryo Tanks',
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Continuous Dew Point Progression Chart
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
                        Icon(Icons.show_chart_rounded, color: AppTheme.primaryLight, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'CONTINUOUS DEW POINT MONITORING (Inlet vs Outlet)',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      'Atmospheric Dew Point (ADP) down to -40.0°C',
                      style: TextStyle(color: AppTheme.primaryLight.withOpacity(0.9), fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Continuous chilled mirror hygrometer telemetry at launcher inlet and receiver outlet. '
                  'Purging must proceed until outlet ADP drops and remains ≤ -40.0°C (water vapor < 0.128 g/Nm³).',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 16),

                // FL Chart Line Chart
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (val) => FlLine(
                          color: AppTheme.border.withOpacity(0.4),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (val) => FlLine(
                          color: AppTheme.border.withOpacity(0.4),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (val, meta) {
                              return Text(
                                '${val.toInt()}°C',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (val, meta) {
                              return Text(
                                'T-${(12 - val.toInt()).clamp(0, 12)}h',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppTheme.border),
                      ),
                      minY: -70,
                      maxY: 10,
                      lineBarsData: [
                        // Threshold line at -40°C
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, -40),
                            FlSpot(12, -40),
                          ],
                          isCurved: false,
                          color: AppTheme.error.withOpacity(0.8),
                          barWidth: 1.5,
                          dashArray: [5, 4],
                          dotData: const FlDotData(show: false),
                        ),
                        // Inlet Dew Point curve (steady around -65°C)
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, -64.0),
                            FlSpot(2, -64.5),
                            FlSpot(4, -65.0),
                            FlSpot(6, -65.2),
                            FlSpot(8, -65.5),
                            FlSpot(10, -65.4),
                            FlSpot(12, -65.4),
                          ],
                          isCurved: true,
                          color: AppTheme.primaryLight,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                        // Outlet Dew Point curve (descending from +5 to -42.8°C)
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 4.0),
                            FlSpot(2, -2.5),
                            FlSpot(4, -14.0),
                            FlSpot(6, -26.0),
                            FlSpot(8, -36.5),
                            FlSpot(10, -41.2),
                            FlSpot(12, -42.8),
                          ],
                          isCurved: true,
                          color: AppTheme.tertiary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Chart Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(AppTheme.primaryLight, 'Inlet Air ADP (-65.4 °C)'),
                    const SizedBox(width: 16),
                    _buildLegendItem(AppTheme.tertiary, 'Outlet Air ADP (-42.8 °C)'),
                    const SizedBox(width: 16),
                    _buildLegendItem(AppTheme.error, 'Target Threshold (-40.0 °C)'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Psychrometric Vapor Equivalence Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PHYSICAL WATER VAPOR EQUIVALENCE',
                        style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ASME B31.8 / OISD-141 requires Atmospheric Dew Point ≤ -40°C. '
                        'Under standard temperature and pressure (STP), this corresponds to:',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildEquivBox('WATER VAPOR', '< 0.128 g/Nm³', AppTheme.tertiary),
                          const SizedBox(width: 10),
                          _buildEquivBox('CONCENTRATION', '< 160 ppmv', AppTheme.primaryLight),
                          const SizedBox(width: 10),
                          _buildEquivBox('CURRENT OUTLET', '0.098 g/Nm³', AppTheme.tertiary),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurgeSkidCard({
    required String title,
    required String status,
    required IconData icon,
    required List<String> details,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryLight, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(status, style: const TextStyle(color: AppTheme.tertiary, fontSize: 9, fontWeight: FontWeight.w600)),
          const Divider(color: AppTheme.border, height: 12),
          ...details.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text('• $d', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
              )),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildEquivBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: 24-HOUR DEW POINT SOAK & STABILIZATION TEST
  // ==========================================================================

  Widget _buildSoakTestTab() {
    final deltaTdp = _soakCurrentDewPointC - soakInitialDewPointC;
    final isCompliant = deltaTdp <= 2.0 && _soakCurrentDewPointC <= -40.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soak Protocol Acceptance Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.surfaceCard, AppTheme.surfaceContainerHigh.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCompliant ? AppTheme.tertiary.withOpacity(0.5) : AppTheme.secondary.withOpacity(0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_rounded, color: AppTheme.tertiary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          '24-HOUR DEW POINT SOAK & STABILIZATION PROTOCOL',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompliant ? AppTheme.tertiary.withOpacity(0.2) : AppTheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCompliant ? 'ACCEPTANCE CRITERIA MET' : 'EVALUATING STABILITY',
                        style: TextStyle(
                          color: isCompliant ? AppTheme.tertiary : AppTheme.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'ASME B31.8 Section 841.3 / OISD-141 Acceptance Rule: After super-drying, the pipeline is sealed '
                  'under positive dry nitrogen pack. The line must undergo a 24-hour soak where moisture desorbs '
                  'from internal crevices. Criteria: Dew point change ΔTdp ≤ 2.0°C over 24 hours without re-purging.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Soak State: ${_isSoakTestRunning ? "ACTIVE MONITORING" : "IDLE"} • N₂ Pack Pressure: ${_soakPackPressureBar.toStringAsFixed(2)} Bar(g) • Pipe Temp: ${_soakPipeWallTempC.toStringAsFixed(1)} °C',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Metrics Row
                Row(
                  children: [
                    _buildSoakStat(
                      'START DEW POINT (HR 0)',
                      '${soakInitialDewPointC.toStringAsFixed(1)} °C',
                      AppTheme.primaryLight,
                    ),
                    const SizedBox(width: 10),
                    _buildSoakStat(
                      'FINAL DEW POINT (HR 24)',
                      '${_soakCurrentDewPointC.toStringAsFixed(1)} °C',
                      AppTheme.tertiary,
                    ),
                    const SizedBox(width: 10),
                    _buildSoakStat(
                      'OBSERVED ΔTdp',
                      '+${deltaTdp.toStringAsFixed(2)} °C',
                      deltaTdp <= 2.0 ? AppTheme.tertiary : AppTheme.error,
                    ),
                    const SizedBox(width: 10),
                    _buildSoakStat(
                      'CRITERIA LIMIT',
                      '≤ 2.00 °C / 24h',
                      AppTheme.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Soak Test Stability Line Chart
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
                    Icon(Icons.timeline_rounded, color: AppTheme.primaryLight, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '24-HOUR DEW POINT & AMBIENT TEMPERATURE STABILIZATION CURVE',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 190,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (val) => FlLine(
                          color: AppTheme.border.withOpacity(0.4),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (val) => FlLine(
                          color: AppTheme.border.withOpacity(0.4),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (val, meta) {
                              return Text(
                                '${val.toStringAsFixed(1)}°C',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (val, meta) {
                              if (val % 4 == 0) {
                                return Text(
                                  'Hr ${val.toInt()}',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.border)),
                      minY: -45,
                      maxY: -39,
                      lineBarsData: [
                        // Upper Acceptable limit: Initial + 2.0 = -41.2°C
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, soakInitialDewPointC + 2.0),
                            FlSpot(24, soakInitialDewPointC + 2.0),
                          ],
                          isCurved: false,
                          color: AppTheme.secondary.withOpacity(0.8),
                          barWidth: 1.5,
                          dashArray: [6, 4],
                          dotData: const FlDotData(show: false),
                        ),
                        // Actual Hourly Dew Point Curve
                        LineChartBarData(
                          spots: _soakLog.map((entry) => FlSpot(entry.hour.toDouble(), entry.dewPointC)).toList(),
                          isCurved: true,
                          color: AppTheme.tertiary,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(AppTheme.tertiary, 'Observed Soak Dew Point (-43.2°C to -42.0°C)'),
                    const SizedBox(width: 16),
                    _buildLegendItem(AppTheme.secondary, 'Max Permitted Limit (-41.2°C, ΔTdp ≤ 2.0°C)'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Hourly Log Table
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
                    const Text(
                      '24-HOUR HOURLY DATA LOG (00:00 to 24:00)',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCertificateDialog,
                      icon: const Icon(Icons.verified_rounded, size: 14),
                      label: const Text('View Sign-off Certificate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tertiary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(AppTheme.background),
                    horizontalMargin: 12,
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('HOUR', style: TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('TIME', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('ADP (°C)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('ΔTdp (°C)', style: TextStyle(color: AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('PRESS (BAR)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('PIPE TEMP (°C)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('STATUS', style: TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                    rows: _soakLog.map((log) {
                      return DataRow(
                        cells: [
                          DataCell(Text('Hr ${log.hour}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold))),
                          DataCell(Text(DateFormat('HH:mm').format(log.timestamp), style: const TextStyle(color: AppTheme.textMuted, fontSize: 10))),
                          DataCell(Text('${log.dewPointC.toStringAsFixed(1)} °C', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                          DataCell(Text('+${log.deltaTdpC.toStringAsFixed(2)} °C', style: TextStyle(color: log.deltaTdpC <= 2.0 ? AppTheme.tertiary : AppTheme.error, fontSize: 11, fontWeight: FontWeight.bold))),
                          DataCell(Text(log.linepackPressureBar.toStringAsFixed(2), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                          DataCell(Text('${log.pipeWallTempC.toStringAsFixed(1)} °C', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: log.isPassed ? AppTheme.tertiary.withOpacity(0.18) : AppTheme.error.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                log.isPassed ? 'PASS' : 'FAIL',
                                style: TextStyle(
                                  color: log.isPassed ? AppTheme.tertiary : AppTheme.error,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoakStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 7.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 5: CALCULATORS & REGULATORY COMPLIANCE AUDIT
  // ==========================================================================

  Widget _buildCalculatorsAuditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Row(
            children: [
              Icon(Icons.calculate_rounded, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'PIPELINE DRYING ENGINEERING CALCULATORS',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2x2 Calculators Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calc 1: Bulk Water Evacuation & Travel Time
              Expanded(
                child: _buildCalculatorCard(
                  title: 'Water Evacuation & Pig Travel',
                  subtitle: 'Calculates water volume & pig run time',
                  inputs: [
                    _buildCalcInput('Pipeline Length (km)', _calcLengthCtrl, _recalcEvacuationVolume),
                    _buildCalcInput('Internal Diameter (mm)', _calcDiaCtrl, _recalcEvacuationVolume),
                    _buildCalcInput('Pig Target Speed (km/h)', _calcSpeedCtrl, _recalcEvacuationVolume),
                  ],
                  results: [
                    _buildCalcResult('Water Volume', '$_calcEvacVolResult m³'),
                    _buildCalcResult('Pig Travel Time', '$_calcTravelTimeHrs hrs'),
                    _buildCalcResult('Discharge Flow Rate', '$_calcDischargeFlowResult m³/hr'),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Calc 2: Residual Water Film Thickness
              Expanded(
                child: _buildCalculatorCard(
                  title: 'Swab Residual Film Thickness',
                  subtitle: 'ASME B31.8 (< 0.1 mm target)',
                  inputs: [
                    _buildCalcInput('Water Mass Absorbed (kg)', _swabMassGainCtrl, _recalcSwabFilm),
                    _buildCalcInput('Section Length (km)', _swabLengthCtrl, _recalcSwabFilm),
                    _buildCalcInput('Internal Diameter (mm)', _swabDiaCtrl, _recalcSwabFilm),
                  ],
                  results: [
                    _buildCalcResult('Residual Film Thickness', '$_calcSwabFilmResult mm'),
                    _buildCalcResult('Acceptance Status', _calcSwabPasses ? 'PASS (< 0.100 mm)' : 'FAIL (Needs Re-swab)', isPass: _calcSwabPasses),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calc 3: Dew Point to Vapor Content
              Expanded(
                child: _buildCalculatorCard(
                  title: 'Atmospheric Dew Point to Vapor',
                  subtitle: 'Water vapor density & PPMv',
                  inputs: [
                    _buildCalcInput('Atmospheric Dew Point (°C)', _dpInputCtrl, _recalcDewPointVapor),
                  ],
                  results: [
                    _buildCalcResult('Water Vapor Mass', '$_calcVaporResult g/Nm³'),
                    _buildCalcResult('Vapor PPMv', '$_calcPpmvResult ppmv'),
                    _buildCalcResult('OISD-141 Limit', '< 0.128 g/Nm³ (-40°C)'),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Calc 4: Nitrogen Pack Volume & LIN Tankers
              Expanded(
                child: _buildCalculatorCard(
                  title: 'Nitrogen Pack Inventory',
                  subtitle: 'Linepack volume & Cryogenic LIN',
                  inputs: [
                    _buildCalcInput('Section Volume (m³)', _n2VolCtrl, _recalcN2Inventory),
                    _buildCalcInput('Pack Pressure (Bar gauge)', _n2PackPressCtrl, _recalcN2Inventory),
                  ],
                  results: [
                    _buildCalcResult('Nitrogen Gas Required', '$_calcN2GasNm3 Nm³'),
                    _buildCalcResult('Liquid N₂ (LIN)', '$_calcLinLiters Liters'),
                    _buildCalcResult('LIN Mass', '$_calcLinTonnes Tonnes'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Regulatory Compliance Audit Checklist
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
                    Icon(Icons.checklist_rounded, color: AppTheme.tertiary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ASME B31.8 / OISD-141 REGULATORY COMPLIANCE AUDIT',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...List.generate(_complianceClauses.length, (idx) {
                  final item = _complianceClauses[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.clause} — ${item.title}',
                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.tertiary.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.standard,
                                      style: const TextStyle(color: AppTheme.tertiary, fontSize: 8.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Req: ${item.requirement}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                              const SizedBox(height: 2),
                              Text('Observed: ${item.observedValue}', style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('Verified by: ${item.auditor}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorCard({
    required String title,
    required String subtitle,
    required List<Widget> inputs,
    required List<Widget> results,
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
          Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
          const Divider(color: AppTheme.border, height: 12),
          ...inputs,
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(children: results),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcInput(String label, TextEditingController controller, VoidCallback onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => onChanged(),
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildCalcResult(String label, String value, {bool? isPass}) {
    Color valColor = AppTheme.primaryLight;
    if (isPass != null) {
      valColor = isPass ? AppTheme.tertiary : AppTheme.error;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
          Text(value, style: TextStyle(color: valColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
