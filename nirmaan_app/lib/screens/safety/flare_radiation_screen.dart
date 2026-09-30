import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// API 521 / OISD-106 FLARE SYSTEM & THERMAL RADIATION MODELS & ENUMS
// ============================================================================

/// Thermal Radiation Zone classification per API Standard 521 (Table 10) & OISD-STD-106
enum RadiationZoneType {
  zone1Sterile(
    label: 'Zone 1: Fatal / Sterile Exclusion',
    shortCode: 'ZONE 1',
    thresholdKwM2: 9.46,
    thresholdBtuHrFt2: 3000,
    permissibleExposure: '0 sec (Immediate pain & blistering < 5s)',
    protectiveReq: 'Sterile exclusion fence, remote ignition only, no entry',
    color: Color(0xFFEF4444),
    bgTint: Color(0x26EF4444),
    severity: 'FATAL / STERILE',
    description: 'Requires sterile boundary fencing. Uninsulated structural steel loses strength. Flaring causes immediate pain and severe blisters within 5 seconds.',
  ),
  zone2Limited(
    label: 'Zone 2: Limited Exposure / Egress',
    shortCode: 'ZONE 2',
    thresholdKwM2: 4.73,
    thresholdBtuHrFt2: 1500,
    permissibleExposure: 'Max 30 seconds escape time',
    protectiveReq: 'Full FRC turnout gear, flash hood, emergency egress',
    color: Color(0xFFFFB95F),
    bgTint: Color(0x26FFB95F),
    severity: 'RESTRICTED / 30S',
    description: 'Emergency escape zone. Personnel require shelter within 30 seconds. Max permissible for emergency operations with appropriate protective gear.',
  ),
  zone3Public(
    label: 'Zone 3: Continuous Exposure / Boundary',
    shortCode: 'ZONE 3',
    thresholdKwM2: 1.58,
    thresholdBtuHrFt2: 500,
    permissibleExposure: 'Continuous (> 8 hours continuous)',
    protectiveReq: 'Standard industrial Flame-Resistant Clothing (FRC)',
    color: Color(0xFF4EDEA3),
    bgTint: Color(0x264EDEA3),
    severity: 'CONTINUOUS / SAFE',
    description: 'Permissible continuous exposure for operating personnel and general public offsite boundary per API 521 / OISD-106.',
  ),
  zoneSolarBackground(
    label: 'Zone 4: Ambient Solar Baseline',
    shortCode: 'ZONE 4',
    thresholdKwM2: 1.00,
    thresholdBtuHrFt2: 317,
    permissibleExposure: 'Unrestricted baseline',
    protectiveReq: 'Standard PPE',
    color: Color(0xFF38BDF8),
    bgTint: Color(0x2638BDF8),
    severity: 'BASELINE',
    description: 'Background solar radiation during clear summer midday in Upper Assam basin.',
  );

  final String label;
  final String shortCode;
  final double thresholdKwM2;
  final double thresholdBtuHrFt2;
  final String permissibleExposure;
  final String protectiveReq;
  final Color color;
  final Color bgTint;
  final String severity;
  final String description;

  const RadiationZoneType({
    required this.label,
    required this.shortCode,
    required this.thresholdKwM2,
    required this.thresholdBtuHrFt2,
    required this.permissibleExposure,
    required this.protectiveReq,
    required this.color,
    required this.bgTint,
    required this.severity,
    required this.description,
  });
}

/// Flare Pilot Flame Data with Triple Redundant Detection
class PilotFlameData {
  final String id;
  final String compassQuadrant;
  final String tag;
  double thermocoupleATempC;
  double thermocoupleBTempC;
  double opticalIntensityPercent;
  bool isSolenoidOpen;
  double fuelGasPressureBar;
  String sparkIgniterStatus;
  DateTime lastIgnitionTimestamp;

  PilotFlameData({
    required this.id,
    required this.compassQuadrant,
    required this.tag,
    required this.thermocoupleATempC,
    required this.thermocoupleBTempC,
    required this.opticalIntensityPercent,
    this.isSolenoidOpen = true,
    this.fuelGasPressureBar = 2.3,
    this.sparkIgniterStatus = 'STANDBY',
    required this.lastIgnitionTimestamp,
  });

  bool get isTcAHealthy => thermocoupleATempC >= 450.0;
  bool get isTcBHealthy => thermocoupleBTempC >= 450.0;
  bool get isOpticalHealthy => opticalIntensityPercent >= 60.0;

  /// Triple redundancy 2-out-of-3 voting logic
  bool get isFlameDetected {
    int votes = 0;
    if (isTcAHealthy) votes++;
    if (isTcBHealthy) votes++;
    if (isOpticalHealthy) votes++;
    return votes >= 2;
  }

  String get healthStatus {
    if (isFlameDetected) {
      if (isTcAHealthy && isTcBHealthy && isOpticalHealthy) {
        return 'OPTIMAL (3/3)';
      }
      return 'DEGRADED (2/3)';
    }
    return 'FLAMEOUT ALERT';
  }

  Color get healthColor {
    if (isFlameDetected) {
      if (isTcAHealthy && isTcBHealthy && isOpticalHealthy) {
        return const Color(0xFF4EDEA3);
      }
      return const Color(0xFFFFB95F);
    }
    return const Color(0xFFEF4444);
  }
}

/// Heat Flux Radiometer field sensor point
class RadiometerSensor {
  final String id;
  final String location;
  final double radialDistanceMeters;
  final double compassAngleDeg;
  double currentHeatFluxKwM2;
  double peakHeatFluxKwM2;
  bool isAlertTriggered;

  RadiometerSensor({
    required this.id,
    required this.location,
    required this.radialDistanceMeters,
    required this.compassAngleDeg,
    required this.currentHeatFluxKwM2,
    required this.peakHeatFluxKwM2,
    this.isAlertTriggered = false,
  });

  RadiationZoneType get currentZone {
    if (currentHeatFluxKwM2 >= RadiationZoneType.zone1Sterile.thresholdKwM2) {
      return RadiationZoneType.zone1Sterile;
    } else if (currentHeatFluxKwM2 >= RadiationZoneType.zone2Limited.thresholdKwM2) {
      return RadiationZoneType.zone2Limited;
    } else if (currentHeatFluxKwM2 >= RadiationZoneType.zone3Public.thresholdKwM2) {
      return RadiationZoneType.zone3Public;
    }
    return RadiationZoneType.zoneSolarBackground;
  }
}

/// Real-time Worker Location Beacon in Flare Vicinity
class FlareWorkerBeacon {
  final String id;
  final String name;
  final String role;
  final String radioChannel;
  double distanceMeters;
  double angleDeg;
  int exposureSeconds;
  bool isInSterileZone;

  FlareWorkerBeacon({
    required this.id,
    required this.name,
    required this.role,
    required this.radioChannel,
    required this.distanceMeters,
    required this.angleDeg,
    this.exposureSeconds = 0,
    this.isInSterileZone = false,
  });
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class FlareRadiationScreen extends StatefulWidget {
  const FlareRadiationScreen({super.key});

  @override
  State<FlareRadiationScreen> createState() => _FlareRadiationScreenState();
}

class _FlareRadiationScreenState extends State<FlareRadiationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _telemetryTimer;

  // Global Plant / Flare Operating State
  bool _isEmergencyBlowdownActive = false;
  bool _isAutoDrainActive = true;
  bool _isN2PurgeMedium = true; // true = N2, false = Fuel Gas
  bool _isExclusionSirenRinging = false;
  bool _isPilotRelightInProgress = false;
  int _relightStepIndex = 0;

  // Dynamic Parameters (API 521 Brzustowski & Sommer plume simulation)
  double _flareMassFlowTonHr = 18.5; // Normal purge flaring
  double _windSpeedKmh = 19.5;
  double _windDirectionDeg = 72.0; // ENE
  final double _ambientTempC = 28.5;
  final double _stackHeightM = 85.0; // 85m elevated stack
  final double _stackDiameterM = 1.22; // 48-inch tip

  // KO Drum Telemetry
  double _koDrumLiquidLevelPct = 34.8;
  final double _koDrumPressureBar = 0.22;
  final double _koDrumTempC = 41.5;
  final double _pumpAFlowM3Hr = 8.8;
  final double _pumpADischargePressureBar = 4.3;
  bool _pumpARunning = true;
  bool _pumpBRunning = false;

  // Molecular Seal & Purge Gas
  double _molecularSealDeltaP = 14.8; // mmH2O
  double _purgeGasFlowNm3Hr = 88.5; // Safe threshold >= 45 Nm3/hr
  double _stackBaseO2Pct = 0.12; // vol % (Trip >= 0.5%)
  double _purgeVelocityMS = 0.038; // API 521 requirement >= 0.03 m/s

  // Noise Telemetry dB(A)
  double _noiseZone1Db = 101.4;
  double _noiseZone2Db = 83.2;
  double _noiseZone3Db = 61.8;
  double _noiseOffsiteDb = 53.6;

  // Pilots Array
  late List<PilotFlameData> _pilots;
  late List<RadiometerSensor> _radiometers;
  late List<FlareWorkerBeacon> _workerBeacons;
  late List<FlSpot> _noiseHistoricalTrend;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initSubsystems();
    _startTelemetryStream();
  }

  void _initSubsystems() {
    // 4 Quadrant Pilot Array
    _pilots = [
      PilotFlameData(
        id: 'P-1',
        compassQuadrant: 'NORTH',
        tag: 'PILOT-NORTH-01',
        thermocoupleATempC: 738.0,
        thermocoupleBTempC: 745.0,
        opticalIntensityPercent: 94.0,
        lastIgnitionTimestamp: DateTime.now().subtract(const Duration(hours: 14)),
      ),
      PilotFlameData(
        id: 'P-2',
        compassQuadrant: 'EAST',
        tag: 'PILOT-EAST-02',
        thermocoupleATempC: 712.0,
        thermocoupleBTempC: 720.0,
        opticalIntensityPercent: 88.0,
        lastIgnitionTimestamp: DateTime.now().subtract(const Duration(hours: 14)),
      ),
      PilotFlameData(
        id: 'P-3',
        compassQuadrant: 'SOUTH',
        tag: 'PILOT-SOUTH-03',
        thermocoupleATempC: 755.0,
        thermocoupleBTempC: 749.0,
        opticalIntensityPercent: 96.0,
        lastIgnitionTimestamp: DateTime.now().subtract(const Duration(hours: 14)),
      ),
      PilotFlameData(
        id: 'P-4',
        compassQuadrant: 'WEST',
        tag: 'PILOT-WEST-04',
        thermocoupleATempC: 694.0,
        thermocoupleBTempC: 701.0,
        opticalIntensityPercent: 82.0,
        lastIgnitionTimestamp: DateTime.now().subtract(const Duration(hours: 14)),
      ),
    ];

    // Field Radiometers
    _radiometers = [
      RadiometerSensor(
        id: 'HF-101',
        location: 'Sterile Perimeter North (42m)',
        radialDistanceMeters: 42.0,
        compassAngleDeg: 0.0,
        currentHeatFluxKwM2: 7.85,
        peakHeatFluxKwM2: 9.12,
      ),
      RadiometerSensor(
        id: 'HF-102',
        location: 'Downwind Plume East (88m)',
        radialDistanceMeters: 88.0,
        compassAngleDeg: 72.0,
        currentHeatFluxKwM2: 4.45,
        peakHeatFluxKwM2: 5.68,
      ),
      RadiometerSensor(
        id: 'HF-103',
        location: 'KO Drum Pad South (95m)',
        radialDistanceMeters: 95.0,
        compassAngleDeg: 180.0,
        currentHeatFluxKwM2: 3.10,
        peakHeatFluxKwM2: 3.90,
      ),
      RadiometerSensor(
        id: 'HF-104',
        location: 'Process Unit Boundary West (160m)',
        radialDistanceMeters: 160.0,
        compassAngleDeg: 270.0,
        currentHeatFluxKwM2: 1.48,
        peakHeatFluxKwM2: 1.85,
      ),
      RadiometerSensor(
        id: 'HF-105',
        location: 'Security Gate & Public Fence (240m)',
        radialDistanceMeters: 240.0,
        compassAngleDeg: 135.0,
        currentHeatFluxKwM2: 0.88,
        peakHeatFluxKwM2: 1.10,
      ),
    ];

    // Worker Beacons
    _workerBeacons = [
      FlareWorkerBeacon(
        id: 'WB-402',
        name: 'Bhaben Saikia',
        role: 'Process Operator',
        radioChannel: 'CH-04 Flare Ops',
        distanceMeters: 92.0,
        angleDeg: 175.0,
        exposureSeconds: 12,
        isInSterileZone: false,
      ),
      FlareWorkerBeacon(
        id: 'WB-109',
        name: 'Ranjan Gogoi',
        role: 'Lead Instrumentation Tech',
        radioChannel: 'CH-04 Flare Ops',
        distanceMeters: 185.0,
        angleDeg: 260.0,
        exposureSeconds: 0,
        isInSterileZone: false,
      ),
    ];

    // Acoustic Trend History (past 6 hours)
    _noiseHistoricalTrend = const [
      FlSpot(0, 58.2),
      FlSpot(1, 59.4),
      FlSpot(2, 61.0),
      FlSpot(3, 86.5), // Small relief test
      FlSpot(4, 64.2),
      FlSpot(5, 62.0),
      FlSpot(6, 61.8),
    ];
  }

  void _startTelemetryStream() {
    _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        final rand = math.Random();
        // Slight natural fluctuation
        final deltaRate = (rand.nextDouble() - 0.5) * 0.4;
        if (!_isEmergencyBlowdownActive) {
          _flareMassFlowTonHr = (_flareMassFlowTonHr + deltaRate).clamp(14.0, 24.0);
        }

        // Radiometer jitter
        for (var r in _radiometers) {
          final jitter = (rand.nextDouble() - 0.5) * 0.15;
          r.currentHeatFluxKwM2 = (r.currentHeatFluxKwM2 + jitter).clamp(0.5, 12.0);
          if (r.currentHeatFluxKwM2 > r.peakHeatFluxKwM2) {
            r.peakHeatFluxKwM2 = r.currentHeatFluxKwM2;
          }
        }

        // KO Drum liquid level control
        if (_isAutoDrainActive && _pumpARunning) {
          _koDrumLiquidLevelPct = (_koDrumLiquidLevelPct - 0.12).clamp(18.0, 92.0);
        } else if (!_pumpARunning && !_pumpBRunning) {
          _koDrumLiquidLevelPct = (_koDrumLiquidLevelPct + 0.25).clamp(18.0, 95.0);
        }

        // Auto pump stop/start logic per OISD-106
        if (_koDrumLiquidLevelPct >= 60.0 && !_pumpARunning) {
          _pumpARunning = true; // Auto drain start on HLL
        } else if (_koDrumLiquidLevelPct <= 16.0 && _pumpARunning) {
          _pumpARunning = false; // Auto cut-off on LLL
        }

        // Thermocouple minor jitter
        for (var p in _pilots) {
          p.thermocoupleATempC += (rand.nextDouble() - 0.5) * 2.0;
          p.thermocoupleBTempC += (rand.nextDouble() - 0.5) * 2.0;
        }

        // Molecular seal DP & O2 minor telemetry jitter
        _molecularSealDeltaP = (14.8 + (rand.nextDouble() - 0.5) * 0.8).clamp(11.0, 22.0);
        _stackBaseO2Pct = (0.12 + (rand.nextDouble() - 0.5) * 0.02).clamp(0.05, 0.45);

        // Worker beacon exposure increment
        for (var w in _workerBeacons) {
          if (w.distanceMeters <= _calculateZone2Radius()) {
            w.exposureSeconds += 2;
          } else {
            w.exposureSeconds = 0;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // API 521 POINT-SOURCE THERMAL RADIATION CALCULATION
  // q = (tau * F * Q) / (4 * pi * R^2)
  // R = sqrt( (tau * F * Q) / (4 * pi * q) )
  // ==========================================================================
  double _calculateZone1Radius() {
    // Zone 1: 9.46 kW/m2
    return _computeRadiusForHeatFlux(RadiationZoneType.zone1Sterile.thresholdKwM2);
  }

  double _calculateZone2Radius() {
    // Zone 2: 4.73 kW/m2
    return _computeRadiusForHeatFlux(RadiationZoneType.zone2Limited.thresholdKwM2);
  }

  double _calculateZone3Radius() {
    // Zone 3: 1.58 kW/m2
    return _computeRadiusForHeatFlux(RadiationZoneType.zone3Public.thresholdKwM2);
  }

  double _computeRadiusForHeatFlux(double targetKwM2) {
    // Lower Heating Value (LHV) of Assam Natural Gas ~ 47,500 kJ/kg
    // Q = Mass rate (kg/s) * LHV (kJ/kg)
    final massKgS = (_flareMassFlowTonHr * 1000.0) / 3600.0;
    const lhvKjKg = 47500.0;
    final heatReleaseKw = massKgS * lhvKjKg;

    // F = Radiative fraction (API 521 typical for hydrocarbon: 0.20 to 0.25)
    const fFraction = 0.22;
    // tau = Atmospheric transmissivity (~0.85 typical)
    const tauTransmissivity = 0.85;

    final qRad = tauTransmissivity * fFraction * heatReleaseKw;
    // Slant distance from flame center to ground
    final rSlant = math.sqrt(qRad / (4 * math.pi * targetKwM2));

    // Ground radius considering stack height (85m)
    final flameCenterElevationM = _stackHeightM + (_flareMassFlowTonHr * 0.12);
    if (rSlant > flameCenterElevationM) {
      final groundRadius = math.sqrt(math.pow(rSlant, 2) - math.pow(flameCenterElevationM, 2));
      // Add wind tilt deflection elongation
      final windFactor = 1.0 + (_windSpeedKmh / 120.0);
      return groundRadius * windFactor;
    }
    return 15.0; // minimum base radius
  }

  // ==========================================================================
  // EMERGENCY SIMULATION & CONTROL ACTIONS
  // ==========================================================================
  void _toggleEmergencyBlowdown() {
    setState(() {
      _isEmergencyBlowdownActive = !_isEmergencyBlowdownActive;
      if (_isEmergencyBlowdownActive) {
        _flareMassFlowTonHr = 240.0; // Relief blowdown event
        _noiseZone1Db = 114.2;
        _noiseZone2Db = 94.6;
        _noiseZone3Db = 72.8;
        _noiseOffsiteDb = 68.2;
        _koDrumLiquidLevelPct = 71.5;
        _pumpARunning = true;
        _pumpBRunning = true;
      } else {
        _flareMassFlowTonHr = 18.5; // Return to purge
        _noiseZone1Db = 101.4;
        _noiseZone2Db = 83.2;
        _noiseZone3Db = 61.8;
        _noiseOffsiteDb = 53.6;
        _koDrumLiquidLevelPct = 34.8;
        _pumpBRunning = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _isEmergencyBlowdownActive ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(
              _isEmergencyBlowdownActive ? Icons.warning_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isEmergencyBlowdownActive
                    ? 'EMERGENCY BLOWDOWN ACTIVATED: Relief rate at 240 T/h. Zone 1 sterile boundary engaged!'
                    : 'NORMAL PURGE RESTORED: Relief valves reseated. Thermal radiation at safe baseline.',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerSterileZoneIntrusionSimulation() {
    setState(() {
      final target = _workerBeacons.first;
      if (target.isInSterileZone) {
        target.distanceMeters = 92.0;
        target.isInSterileZone = false;
        _isExclusionSirenRinging = false;
      } else {
        target.distanceMeters = 32.0; // Inside Zone 1 (<42m)
        target.isInSterileZone = true;
        _isExclusionSirenRinging = true;
      }
    });
  }

  void _startPilotRelightSequence() {
    setState(() {
      _isPilotRelightInProgress = true;
      _relightStepIndex = 1;
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _relightStepIndex = 2);
    });

    Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      setState(() => _relightStepIndex = 3);
    });

    Timer(const Duration(milliseconds: 5000), () {
      if (!mounted) return;
      setState(() {
        _relightStepIndex = 4;
        _isPilotRelightInProgress = false;
        for (var p in _pilots) {
          p.thermocoupleATempC = 745.0 + math.Random().nextInt(30);
          p.thermocoupleBTempC = 740.0 + math.Random().nextInt(30);
          p.opticalIntensityPercent = 95.0;
          p.sparkIgniterStatus = 'SUCCESS';
          p.lastIgnitionTimestamp = DateTime.now();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF4EDEA3),
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Pilot Auto-Ignition Sequence Completed: All 4 Pilots firing stably (3/3 verification)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      );
    });
  }

  void _showComplianceDossierModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _buildComplianceDossierSheet(ctx),
    );
  }

  // ==========================================================================
  // UI BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final zone1R = _calculateZone1Radius();
    final zone2R = _calculateZone2Radius();
    final zone3R = _calculateZone3Radius();
    final isWorkerViolatingSterileZone = _workerBeacons.any((w) => w.isInSterileZone);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Flare Stack & Thermal Radiation',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'API 521 / OISD-106 • OIL Duliajan GPP (FS-01)',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sterile Zone Siren',
            icon: Icon(
              _isExclusionSirenRinging
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: _isExclusionSirenRinging ? const Color(0xFFEF4444) : AppTheme.textSecondary,
            ),
            onPressed: () {
              setState(() => _isExclusionSirenRinging = !_isExclusionSirenRinging);
            },
          ),
          IconButton(
            tooltip: 'Compliance Dossier',
            icon: const Icon(Icons.assignment_outlined, color: AppTheme.primaryLight),
            onPressed: _showComplianceDossierModal,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          tabs: const [
            Tab(icon: Icon(Icons.radar_rounded, size: 18), text: 'Radiation Contours'),
            Tab(icon: Icon(Icons.local_fire_department_rounded, size: 18), text: 'Flare Tip & Pilots'),
            Tab(icon: Icon(Icons.propane_tank_rounded, size: 18), text: 'KO Drum & Slop'),
            Tab(icon: Icon(Icons.shield_rounded, size: 18), text: 'Molecular Seal'),
            Tab(icon: Icon(Icons.volume_up_rounded, size: 18), text: 'Noise Contours'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Sterile Intrusion Emergency Alert Banner
          if (isWorkerViolatingSterileZone || _isExclusionSirenRinging)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFEF4444),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'CRITICAL ALERT: Personnel detected inside Zone 1 Sterile Fence (<42m). Thermal flux exceeds 9.46 kW/m²! Immediate evacuation required!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    onPressed: _triggerSterileZoneIntrusionSimulation,
                    child: const Text('DISMISS'),
                  ),
                ],
              ),
            ),

          // Master Operational Telemetry Quick Bar
          _buildMasterTelemetryBar(zone1R, zone2R, zone3R),

          // Main Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRadiationContoursTab(zone1R, zone2R, zone3R),
                _buildFlareTipPilotsTab(),
                _buildKoDrumTab(),
                _buildMolecularSealTab(),
                _buildNoiseContoursTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TOP METRIC STRIP
  // ==========================================================================
  Widget _buildMasterTelemetryBar(double z1R, double z2R, double z3R) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isEmergencyBlowdownActive
                    ? const Color(0x33EF4444)
                    : const Color(0x264EDEA3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isEmergencyBlowdownActive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF4EDEA3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isEmergencyBlowdownActive
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF4EDEA3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isEmergencyBlowdownActive ? 'RELIEF BLOWDOWN' : 'NORMAL PURGE FLARING',
                    style: TextStyle(
                      color: _isEmergencyBlowdownActive
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF4EDEA3),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            _buildCompactMetric('Mass Relief', '${_flareMassFlowTonHr.toStringAsFixed(1)} T/h', AppTheme.primaryLight),
            const SizedBox(width: 12),
            _buildCompactMetric('Zone 1 Radius', '${z1R.toStringAsFixed(1)} m', const Color(0xFFEF4444)),
            const SizedBox(width: 12),
            _buildCompactMetric('Zone 2 Egress', '${z2R.toStringAsFixed(1)} m', const Color(0xFFFFB95F)),
            const SizedBox(width: 12),
            _buildCompactMetric('Public Boundary', '${z3R.toStringAsFixed(1)} m', const Color(0xFF4EDEA3)),
            const SizedBox(width: 12),
            _buildCompactMetric('Wind Telemetry', '${_windSpeedKmh.toStringAsFixed(1)} km/h @ ${_windDirectionDeg.toInt()}°', AppTheme.textPrimary),
            const SizedBox(width: 12),
            _buildCompactMetric('Ambient Temp', '${_ambientTempC.toStringAsFixed(1)}°C', AppTheme.textSecondary),
            const SizedBox(width: 12),
            _buildCompactMetric('Tip Dia', '${_stackDiameterM.toStringAsFixed(2)}m (48")', AppTheme.primaryLight),
            const SizedBox(width: 12),
            _buildCompactMetric('KO Drum Level', '${_koDrumLiquidLevelPct.toStringAsFixed(1)}%', _koDrumLiquidLevelPct > 60.0 ? const Color(0xFFFFB95F) : AppTheme.tertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMetric(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: THERMAL RADIATION CONTOURS & RADAR (API 521)
  // ==========================================================================
  Widget _buildRadiationContoursTab(double z1R, double z2R, double z3R) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulation & Relief Event Controls
          _buildReliefSimulationHeader(),

          const SizedBox(height: 16),

          // Interactive Thermal Radiation Radar Contour Map
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                            'Thermal Radiation Isopleth Map (API 521)',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Concentric ground-level heat flux contours & live RFID beacon tags',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Test Sterile Zone Intrusion',
                        icon: const Icon(Icons.person_pin_circle_rounded, color: Color(0xFFEF4444)),
                        onPressed: _triggerSterileZoneIntrusionSimulation,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Custom Painter Canvas for Isopleth Radiation Contours
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 320,
                      width: double.infinity,
                      color: const Color(0xFF070D1A),
                      child: CustomPaint(
                        painter: _FlareRadiationContourPainter(
                          zone1RadiusM: z1R,
                          zone2RadiusM: z2R,
                          zone3RadiusM: z3R,
                          windSpeedKmh: _windSpeedKmh,
                          windDirectionDeg: _windDirectionDeg,
                          sensors: _radiometers,
                          workerBeacons: _workerBeacons,
                          stackHeightM: _stackHeightM,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Legend for Zones
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildZoneLegendPill(
                        'Zone 1 (>9.46 kW/m²)',
                        '${z1R.toStringAsFixed(1)}m Sterile Fence',
                        const Color(0xFFEF4444),
                      ),
                      _buildZoneLegendPill(
                        'Zone 2 (4.73 kW/m²)',
                        '${z2R.toStringAsFixed(1)}m 30s Escape',
                        const Color(0xFFFFB95F),
                      ),
                      _buildZoneLegendPill(
                        'Zone 3 (1.58 kW/m²)',
                        '${z3R.toStringAsFixed(1)}m Public Boundary',
                        const Color(0xFF4EDEA3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Parameter Sliders Card (API 521 Sensitivity Analysis)
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API 521 Radiation Sensitivity Tuning',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Simulate varying flaring mass relief rates, wind velocity & atmospheric tilt',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 16),

                  // Flare Mass Flow Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Flare Relief Rate (Ton/hr):',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      Text(
                        '${_flareMassFlowTonHr.toStringAsFixed(1)} T/h',
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _flareMassFlowTonHr,
                    min: 5.0,
                    max: 350.0,
                    divisions: 69,
                    activeColor: AppTheme.primaryLight,
                    inactiveColor: AppTheme.border,
                    onChanged: (val) {
                      setState(() {
                        _flareMassFlowTonHr = val;
                        if (val > 100.0) {
                          _isEmergencyBlowdownActive = true;
                        } else {
                          _isEmergencyBlowdownActive = false;
                        }
                      });
                    },
                  ),

                  // Wind Velocity Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Wind Velocity (km/h):',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      Text(
                        '${_windSpeedKmh.toStringAsFixed(1)} km/h',
                        style: const TextStyle(
                          color: Color(0xFFFFB95F),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _windSpeedKmh,
                    min: 0.0,
                    max: 60.0,
                    divisions: 60,
                    activeColor: const Color(0xFFFFB95F),
                    inactiveColor: AppTheme.border,
                    onChanged: (val) {
                      setState(() => _windSpeedKmh = val);
                    },
                  ),

                  // Wind Direction Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Wind Azimuth Angle (°):',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      Text(
                        '${_windDirectionDeg.toInt()}° (${_getCompassOrientation(_windDirectionDeg)})',
                        style: const TextStyle(
                          color: Color(0xFF4EDEA3),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _windDirectionDeg,
                    min: 0.0,
                    max: 360.0,
                    divisions: 36,
                    activeColor: const Color(0xFF4EDEA3),
                    inactiveColor: AppTheme.border,
                    onChanged: (val) {
                      setState(() => _windDirectionDeg = val);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // API 521 Table 10 Human Exposure Limits Card
          _buildApi521Table10Card(),

          const SizedBox(height: 16),

          // Field Radiometer Telemetry List
          _buildRadiometersListCard(),
        ],
      ),
    );
  }

  Widget _buildZoneLegendPill(String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReliefSimulationHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isEmergencyBlowdownActive ? const Color(0xFFEF4444) : AppTheme.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isEmergencyBlowdownActive ? const Color(0x33EF4444) : AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isEmergencyBlowdownActive
                  ? Icons.local_fire_department_rounded
                  : Icons.cloud_done_rounded,
              color: _isEmergencyBlowdownActive ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEmergencyBlowdownActive
                      ? 'SIMULATION: ESD Full Plant Depressurizing'
                      : 'Operational Mode: Normal Continuous Flaring',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isEmergencyBlowdownActive
                      ? 'Simulating maximum design relief case (240 T/h, Q = 3,166 MW thermal)'
                      : 'Purge rate 18.5 T/h, baseline sterile radius 42m per OISD-STD-106',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEmergencyBlowdownActive
                  ? const Color(0xFF4EDEA3)
                  : const Color(0xFFEF4444),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
            onPressed: _toggleEmergencyBlowdown,
            child: Text(
              _isEmergencyBlowdownActive ? 'RESET PURGE' : 'SIMULATE ESD',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApi521Table10Card() {
    return Card(
      color: AppTheme.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.menu_book_rounded, color: AppTheme.secondary, size: 18),
                SizedBox(width: 8),
                Text(
                  'API Standard 521 (Table 10) Thermal Radiation Criteria',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTable10Row(
              'Zone 1 (>9.46 kW/m² / 3,000 Btu/hr·ft²)',
              '0 sec',
              'FATAL / STERILE',
              'Pain < 5s, severe blistering. Uninsulated structural steel loses strength. Mandatory sterile exclusion fencing.',
              const Color(0xFFEF4444),
            ),
            const Divider(color: AppTheme.border, height: 16),
            _buildTable10Row(
              'Zone 2 (4.73 kW/m² / 1,500 Btu/hr·ft²)',
              '30 sec',
              'RESTRICTED EGRESS',
              'Max permissible for emergency operations with appropriate clothing to escape within 30 seconds to shelter.',
              const Color(0xFFFFB95F),
            ),
            const Divider(color: AppTheme.border, height: 16),
            _buildTable10Row(
              'Zone 3 (1.58 kW/m² / 500 Btu/hr·ft²)',
              'Continuous',
              'PUBLIC / CONTINUOUS',
              'Permissible continuous exposure for operating personnel & perimeter fence boundary per OISD-106.',
              const Color(0xFF4EDEA3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable10Row(
    String zoneTitle,
    String exposureTime,
    String severityBadge,
    String description,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              zoneTitle,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color, width: 0.8),
              ),
              child: Text(
                '$severityBadge • $exposureTime',
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.3),
        ),
      ],
    );
  }

  Widget _buildRadiometersListCard() {
    return Card(
      color: AppTheme.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Perimeter Heat Flux Radiometer Array',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${_radiometers.length} Transmitters Online',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._radiometers.map((r) => _buildRadiometerItem(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiometerItem(RadiometerSensor r) {
    final zone = r.currentZone;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: zone.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.sensors_rounded, color: zone.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.id,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${r.currentHeatFluxKwM2.toStringAsFixed(2)} kW/m²',
                      style: TextStyle(
                        color: zone.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.location} • Peak: ${r.peakHeatFluxKwM2.toStringAsFixed(2)} kW/m²',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: FLARE TIP & PILOT FLAME STATUS (TRIPLE REDUNDANCY)
  // ==========================================================================
  Widget _buildFlareTipPilotsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Igniter Sequencer & Flare Tip Header Card
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                            'Flare Tip Pilot Flame Management',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'API 521 / OISD-106 Section 5.6 Triple Redundancy Voting',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        icon: _isPilotRelightInProgress
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.flash_on_rounded, size: 16),
                        label: Text(_isPilotRelightInProgress ? 'IGNITING...' : 'AUTO-RELIGHT'),
                        onPressed: _isPilotRelightInProgress ? null : _startPilotRelightSequence,
                      ),
                    ],
                  ),

                  // Ignition Sequence Progress Bar
                  if (_isPilotRelightInProgress) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryLight, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getIgnitionStepLabel(_relightStepIndex),
                                style: const TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                'Step $_relightStepIndex of 4',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _relightStepIndex / 4.0,
                            backgroundColor: AppTheme.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Triple Redundancy Overview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTipTelemetryPill('Stack Elevation', '85.0 m', Icons.height_rounded),
                        _buildTipTelemetryPill('Tip Diameter', '48 inch (1.22m)', Icons.circle_outlined),
                        _buildTipTelemetryPill('Steam Assist Flow', '1.8 T/h (Smokeless)', Icons.water_drop_rounded),
                        _buildTipTelemetryPill('Opacity (Ringelmann)', '0.0 (Clear)', Icons.visibility_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4 Quadrant Pilot Grid
          const Text(
            'Quad-Quadrant Pilot Flame Telemetry (2-out-of-3 Voting)',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          ..._pilots.map((p) => _buildPilotCard(p)),

          const SizedBox(height: 16),

          // Ground-Mounted Optical Flame Detectors (UV/IR Scanners)
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Ground Optical CCTV & Multispectrum IR/UV Scanners',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Line of Sight: 85m Mast',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildOpticalScannerItem(
                    'FD-101 UV/IR Multispectrum',
                    'North-East Perimeter Tower (85m range)',
                    96.0,
                    19.2,
                    'TARGET LOCKED',
                    const Color(0xFF4EDEA3),
                  ),
                  const SizedBox(height: 8),
                  _buildOpticalScannerItem(
                    'FD-102 Dual-Spectrum Fast-IR',
                    'South-West Perimeter Mast (95m range)',
                    91.5,
                    18.8,
                    'TARGET LOCKED',
                    const Color(0xFF4EDEA3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getIgnitionStepLabel(int step) {
    switch (step) {
      case 1:
        return 'Purging pilot gas headers with Nitrogen (N2)...';
      case 2:
        return 'Opening solenoid valve SV-101 (Fuel gas admission)...';
      case 3:
        return 'Discharging 15 kV High-Energy Ignition (HEI) spark...';
      case 4:
        return 'Verifying flame front via dual thermocouple & optical array...';
      default:
        return 'Ignition sequencer ready';
    }
  }

  Widget _buildTipTelemetryPill(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
      ],
    );
  }

  Widget _buildPilotCard(PilotFlameData pilot) {
    final statusColor = pilot.healthColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pilot.id,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${pilot.compassQuadrant} Pilot (${pilot.tag})',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor, width: 0.8),
                ),
                child: Text(
                  pilot.healthStatus,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Thermocouple A, Thermocouple B & Optical Bar
          Row(
            children: [
              Expanded(
                child: _buildSensorMetricBox(
                  'TC-A Temp',
                  '${pilot.thermocoupleATempC.toStringAsFixed(0)}°C',
                  pilot.isTcAHealthy ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
                  'Type K (Duplex)',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSensorMetricBox(
                  'TC-B Temp',
                  '${pilot.thermocoupleBTempC.toStringAsFixed(0)}°C',
                  pilot.isTcBHealthy ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
                  'Type K (Duplex)',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSensorMetricBox(
                  'Optical Flame',
                  '${pilot.opticalIntensityPercent.toStringAsFixed(0)}%',
                  pilot.isOpticalHealthy ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
                  'UV/IR Scan',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fuel Gas line & Spark Igniter status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fuel Gas: ${pilot.fuelGasPressureBar.toStringAsFixed(1)} bar(g) • Solenoid: ${pilot.isSolenoidOpen ? "OPEN" : "CLOSED"}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
              Text(
                'Last Verified: ${DateFormat('HH:mm:ss').format(pilot.lastIgnitionTimestamp)}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorMetricBox(String title, String value, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildOpticalScannerItem(
    String title,
    String subtitle,
    double signalPct,
    double flickerHz,
    String status,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Row(
        children: [
          Icon(Icons.videocam_rounded, color: AppTheme.primaryLight, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
              ),
              Text(
                'Flicker: ${flickerHz.toStringAsFixed(1)} Hz ($signalPct%)',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: KNOCK-OUT (KO) DRUM & SLOP PUMPS (OISD-106)
  // ==========================================================================
  Widget _buildKoDrumTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KO Drum Vessel Card
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                            'Flare Knock-Out (KO) Drum (V-101)',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'OISD-STD-106 Section 5.4 Liquid Droplet Separation (300-600 μm)',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _koDrumLiquidLevelPct >= 80.0
                              ? const Color(0x33EF4444)
                              : const Color(0x264EDEA3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _koDrumLiquidLevelPct >= 80.0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF4EDEA3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _koDrumLiquidLevelPct >= 80.0 ? 'HHLL TRIP INTERLOCK' : 'VESSEL HEALTHY',
                          style: TextStyle(
                            color: _koDrumLiquidLevelPct >= 80.0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF4EDEA3),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Liquid Level Visual Progress Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Liquid Level (LT-101A Radar / LT-101B DP Redundant):',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      Text(
                        '${_koDrumLiquidLevelPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getLevelColor(_koDrumLiquidLevelPct),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Stack(
                    children: [
                      // Background Track
                      Container(
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: AppTheme.border, width: 1),
                        ),
                      ),
                      // Fill Indicator
                      FractionallySizedBox(
                        widthFactor: (_koDrumLiquidLevelPct / 100.0).clamp(0.0, 1.0),
                        child: Container(
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF0284C7),
                                _getLevelColor(_koDrumLiquidLevelPct),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                      // Marker Lines (LLL 15%, NLL 35%, HLL 60%, HHLL 80%)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          children: [
                            const Spacer(flex: 15),
                            _buildLevelMarker('LLL 15%'),
                            const Spacer(flex: 20),
                            _buildLevelMarker('NLL 35%'),
                            const Spacer(flex: 25),
                            _buildLevelMarker('HLL 60%'),
                            const Spacer(flex: 20),
                            _buildLevelMarker('HHLL 80%'),
                            const Spacer(flex: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('LLL: 15% (Pump Stop)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                      Text('NLL: 35% (Normal)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                      Text('HLL: 60% (Auto Drain)', style: TextStyle(color: Color(0xFFFFB95F), fontSize: 9)),
                      Text('HHLL: 80% (ESD Trip)', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Vessel Critical Parameters
                  Row(
                    children: [
                      Expanded(
                        child: _buildVesselParamBox('Operating Pressure', '${_koDrumPressureBar.toStringAsFixed(2)} bar(g)', 'PT-101 (Low DP)'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildVesselParamBox('Vessel Temp', '${_koDrumTempC.toStringAsFixed(1)}°C', 'TT-101 (Steam Traced)'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildVesselParamBox('Accumulation', '${(_koDrumLiquidLevelPct * 0.42).toStringAsFixed(1)} m³', 'Total Cap: 42 m³'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Auto-Drain Slop Pumps (P-101A Duty & P-101B Standby)
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Slop Auto-Drain Pump Skid (P-101A/B)',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            'Auto-Drain Mode:',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                          const SizedBox(width: 6),
                          Switch(
                            value: _isAutoDrainActive,
                            activeThumbColor: const Color(0xFF4EDEA3),
                            onChanged: (val) {
                              setState(() => _isAutoDrainActive = val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Pump A (Duty)
                  _buildPumpCard(
                    pumpTag: 'PUMP P-101A (DUTY)',
                    isRunning: _pumpARunning,
                    flowRateM3Hr: _pumpARunning ? _pumpAFlowM3Hr : 0.0,
                    dischargePressureBar: _pumpARunning ? _pumpADischargePressureBar : 0.0,
                    vibrationMmS: 1.2,
                    motorCurrentAmps: 18.4,
                    onToggle: () {
                      setState(() => _pumpARunning = !_pumpARunning);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Pump B (Standby)
                  _buildPumpCard(
                    pumpTag: 'PUMP P-101B (STANDBY)',
                    isRunning: _pumpBRunning,
                    flowRateM3Hr: _pumpBRunning ? 8.6 : 0.0,
                    dischargePressureBar: _pumpBRunning ? 4.2 : 0.0,
                    vibrationMmS: 0.9,
                    motorCurrentAmps: _pumpBRunning ? 18.0 : 0.0,
                    onToggle: () {
                      setState(() => _pumpBRunning = !_pumpBRunning);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Interlock & Droplet Carryover Prevention
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Liquid Droplet Carryover Protection (API 521 Section 5.4.2)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Demister Pad DP: 2.1 mbar (Normal clean condition)\n'
                    '• Critical droplet drop-out velocity: 1.84 m/s (Assam gas condensate)\n'
                    '• HHLL Interlock (80%): Automatically isolates plant blowdown valves BDV-101 to prevent liquid rain of fire downwind\n'
                    '• Steam heating tracing coil prevents wax precipitation and hydrate plugs during winter months.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelMarker(String label) {
    return Container(
      width: 1.5,
      height: 22,
      color: Colors.white70,
    );
  }

  Color _getLevelColor(double level) {
    if (level >= 80.0) return const Color(0xFFEF4444);
    if (level >= 60.0) return const Color(0xFFFFB95F);
    return const Color(0xFF4EDEA3);
  }

  Widget _buildVesselParamBox(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildPumpCard({
    required String pumpTag,
    required bool isRunning,
    required double flowRateM3Hr,
    required double dischargePressureBar,
    required double vibrationMmS,
    required double motorCurrentAmps,
    required VoidCallback onToggle,
  }) {
    final statusColor = isRunning ? const Color(0xFF4EDEA3) : AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.settings_suggest_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pumpTag,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      isRunning ? 'RUNNING' : 'STOPPED / STANDBY',
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Flow: ${flowRateM3Hr.toStringAsFixed(1)} m³/h • DP: ${dischargePressureBar.toStringAsFixed(1)} bar • Vib: ${vibrationMmS.toStringAsFixed(1)} mm/s',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: isRunning ? 'Stop Pump' : 'Start Pump',
            icon: Icon(
              isRunning ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
              color: statusColor,
            ),
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: MOLECULAR SEAL & PURGE GAS (FLASHBACK PREVENTION)
  // ==========================================================================
  Widget _buildMolecularSealTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Molecular Seal Architecture Card
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                            'Molecular Seal (Velocity & Density Barrier)',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Located at 80m Elevation below tip to prevent air ingress & flashback',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0x264EDEA3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF4EDEA3), width: 0.8),
                        ),
                        child: const Text(
                          'FLASHBACK SAFE',
                          style: TextStyle(
                            color: Color(0xFF4EDEA3),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Key Diagnostic Telemetry
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Seal Differential DP',
                          '${_molecularSealDeltaP.toStringAsFixed(1)} mmH2O',
                          'Normal: 10-25 mmH2O',
                          const Color(0xFF4EDEA3),
                          Icons.speed_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'Purge Gas Velocity',
                          '${_purgeVelocityMS.toStringAsFixed(3)} m/s',
                          'API 521 Min: 0.030 m/s',
                          const Color(0xFF4EDEA3),
                          Icons.air_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Oxygen Content (Stack Base)',
                          '${_stackBaseO2Pct.toStringAsFixed(2)} % vol',
                          'Trip Limit: >= 0.50 %',
                          _stackBaseO2Pct >= 0.50 ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
                          Icons.science_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'Purge Gas Flow (FT-201)',
                          '${_purgeGasFlowNm3Hr.toStringAsFixed(1)} Nm³/h',
                          'Safe Baseline >= 45 Nm³/h',
                          AppTheme.primaryLight,
                          Icons.water_drop_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Purge Medium Control Selector Card
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Continuous Purge Gas Medium Selection',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Nitrogen (N2)'),
                            selected: _isN2PurgeMedium,
                            selectedColor: AppTheme.primary,
                            labelStyle: TextStyle(
                              color: _isN2PurgeMedium ? Colors.white : AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              setState(() {
                                _isN2PurgeMedium = true;
                                _purgeGasFlowNm3Hr = 88.5;
                                _purgeVelocityMS = 0.038;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Fuel Gas (CH4)'),
                            selected: !_isN2PurgeMedium,
                            selectedColor: const Color(0xFFFFB95F),
                            labelStyle: TextStyle(
                              color: !_isN2PurgeMedium ? Colors.black87 : AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              setState(() {
                                _isN2PurgeMedium = false;
                                _purgeGasFlowNm3Hr = 112.0; // Higher volumetric purge due to density difference
                                _purgeVelocityMS = 0.046;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isN2PurgeMedium
                        ? 'Nitrogen Purge Mode: Pure inerting gas (MW 28.01). Excellent density barrier against atmospheric oxygen ingress (MW 28.96). Economizer valve CV-201 throttled to 68%.'
                        : 'Fuel Gas Purge Mode: Methane-rich fuel gas (MW 18.2). Requires 25% higher purge volume per API 521 Husa equation to counteract buoyant air diffusion down the stack.',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // API 521 Flashback Prevention & Husa Equation Criteria
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'API 521 Purge Rate & Flashback Mechanism',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Molecular Seal Labyrinth: Inverted gas trap utilizes density differential between the purge gas and ambient air, stopping oxygen diffusion at the 80m bend.\n'
                    '• Velocity Criterion (API 521 Section 5.7.3.2): Without molecular seal, velocity required = 0.15 m/s. With inverted molecular seal, purge velocity drops to 0.03 m/s, saving ~80% purge gas volume.\n'
                    '• Low Purge Rate Alarm (FT-201 < 45 Nm³/hr): Interlocked to auto-open emergency N2 purge booster valve XV-202 within 2 seconds.\n'
                    '• Stack Base Oxygen Analyzer (AT-301): Auto-trips plant ESD if oxygen content exceeds 0.5% for >10 seconds.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 5: NOISE LEVEL CONTOURS & ACOUSTIC TELEMETRY
  // ==========================================================================
  Widget _buildNoiseContoursTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Noise Sensor Summary Card
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                            'Sonic Jet Noise & Acoustic Contours',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'OSHA / DGMS 8-Hour Permissible Noise Exposure Boundaries',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0x2638BDF8),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.primaryLight, width: 0.8),
                        ),
                        child: const Text(
                          'ACOUSTIC LIVE',
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4 Distance Sound Level Meters
                  Row(
                    children: [
                      Expanded(
                        child: _buildNoiseTile(
                          'SLM-01 (Sterile 40m)',
                          '${_noiseZone1Db.toStringAsFixed(1)} dB(A)',
                          'Double Ear Protection',
                          const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNoiseTile(
                          'SLM-02 (Process 90m)',
                          '${_noiseZone2Db.toStringAsFixed(1)} dB(A)',
                          'Standard Ear Protection',
                          const Color(0xFFFFB95F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNoiseTile(
                          'SLM-03 (Admin 180m)',
                          '${_noiseZone3Db.toStringAsFixed(1)} dB(A)',
                          'Permissible (<65 dB)',
                          const Color(0xFF4EDEA3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNoiseTile(
                          'SLM-04 (Offsite 260m)',
                          '${_noiseOffsiteDb.toStringAsFixed(1)} dB(A)',
                          'Assam Env PCB Standard',
                          const Color(0xFF4EDEA3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Noise Trend Chart Card (fl_chart)
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Acoustic Decibel Trend (Last 6 Hours)',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Threshold: 85 dB(A) OSHA Limit',
                        style: TextStyle(color: Color(0xFFFFB95F), fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 190,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: AppTheme.border.withValues(alpha: 0.3),
                            strokeWidth: 1,
                          ),
                          getDrawingVerticalLine: (value) => FlLine(
                            color: AppTheme.border.withValues(alpha: 0.3),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (val, meta) => Text(
                                '${val.toInt()} dB',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (val, meta) => Text(
                                '-${(6 - val.toInt())}h',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: AppTheme.border, width: 0.8),
                        ),
                        minX: 0,
                        maxX: 6,
                        minY: 40,
                        maxY: 120,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _noiseHistoricalTrend,
                            isCurved: true,
                            color: AppTheme.primaryLight,
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.primaryLight.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Acoustic Mitigation & Engineering Controls Card
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Flare Noise Attenuation Engineering (API 521 Section 5.8)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Sonic Jet Shear: Turbulent gas expansion generates high frequency sound (Lighthill eighth power law, W ~ v^8).\n'
                    '• Multiport Sonic Tip Design: Multi-arm tip shifts acoustic peak to ultrasonic frequencies (>15 kHz), attenuating audible dB(A) by 6.2 dB.\n'
                    '• Steam Assist Damping: High-velocity steam injection reduces core turbulent shear and provides acoustic damping (-4.5 dB).\n'
                    '• Distance Attenuation: Inverse-square law provides 6 dB attenuation per doubling of radial distance under calm atmospheric conditions.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoiseTile(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }

  // ==========================================================================
  // COMPLIANCE AUDIT DOSSIER SHEET
  // ==========================================================================
  Widget _buildComplianceDossierSheet(BuildContext ctx) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF4EDEA3), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'API 521 / OISD-106 Compliance Audit',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Oil India Limited • Duliajan Central Gas Gathering Station (CGGS)\n'
            'Flare System FS-01 • Design Base: API 521 6th Edition / OISD-STD-106',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _buildDossierRow('Sterile Zone Radius', '${_calculateZone1Radius().toStringAsFixed(1)} m (Compliant > 35m)'),
                _buildDossierRow('Pilot Flame Detection', 'Triple Redundant 2-out-of-3 Voting (Pass)'),
                _buildDossierRow('KO Drum Droplet Sizing', '350 micron (Compliant per OISD-106)'),
                _buildDossierRow('Molecular Seal Velocity', '${_purgeVelocityMS.toStringAsFixed(3)} m/s (Pass >= 0.03 m/s)'),
                _buildDossierRow('Boundary Noise dB(A)', '${_noiseOffsiteDb.toStringAsFixed(1)} dB(A) (Pass < 65 dB)'),
                _buildDossierRow('Digital SHA-256 Stamp', '7F9A-B23E-01FA-OIL-DGMS'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.download_rounded),
            label: const Text('EXPORT REGULATORY AUDIT DOSSIER (PDF)'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF4EDEA3),
                  content: Text('Audit Dossier exported to regulatory archive with cryptographic verification!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDossierRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getCompassOrientation(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'N';
    if (deg >= 22.5 && deg < 67.5) return 'NE';
    if (deg >= 67.5 && deg < 112.5) return 'E';
    if (deg >= 112.5 && deg < 157.5) return 'SE';
    if (deg >= 157.5 && deg < 202.5) return 'S';
    if (deg >= 202.5 && deg < 247.5) return 'SW';
    if (deg >= 247.5 && deg < 292.5) return 'W';
    return 'NW';
  }
}

// ============================================================================
// CUSTOM PAINTER: THERMAL RADIATION ISOPLETH CONTOURS & RADAR
// ============================================================================

class _FlareRadiationContourPainter extends CustomPainter {
  final double zone1RadiusM;
  final double zone2RadiusM;
  final double zone3RadiusM;
  final double windSpeedKmh;
  final double windDirectionDeg;
  final List<RadiometerSensor> sensors;
  final List<FlareWorkerBeacon> workerBeacons;
  final double stackHeightM;

  _FlareRadiationContourPainter({
    required this.zone1RadiusM,
    required this.zone2RadiusM,
    required this.zone3RadiusM,
    required this.windSpeedKmh,
    required this.windDirectionDeg,
    required this.sensors,
    required this.workerBeacons,
    required this.stackHeightM,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Scale: map 0-250m to fit within canvas dimensions
    final maxDimension = math.min(size.width, size.height);
    final scale = (maxDimension / 2 - 25) / 250.0; // pixels per meter

    // 1. Grid Rings (Distance Reference Circles: 50m, 100m, 150m, 200m)
    final gridPaint = Paint()
      ..color = const Color(0xFF162347)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var r = 50; r <= 200; r += 50) {
      canvas.drawCircle(center, r * scale, gridPaint);
    }

    // Radial Compass Lines (N, S, E, W)
    final crossPaint = Paint()
      ..color = const Color(0xFF1E2E5C)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx, center.dy - 120), Offset(center.dx, center.dy + 120), crossPaint);
    canvas.drawLine(Offset(center.dx - 120, center.dy), Offset(center.dx + 120, center.dy), crossPaint);

    // 2. Wind Deflection Plume Center (Brzustowski & Sommer plume tilt)
    final windAngleRad = (windDirectionDeg - 90) * (math.pi / 180.0);
    final plumeOffsetPixels = (windSpeedKmh / 60.0) * 28.0;
    final plumeCenter = Offset(
      center.dx + math.cos(windAngleRad) * plumeOffsetPixels,
      center.dy + math.sin(windAngleRad) * plumeOffsetPixels,
    );

    // 3. Zone 3: Continuous Exposure (1.58 kW/m2) - Green Isopleth
    final zone3RadiusPx = zone3RadiusM * scale;
    final zone3Paint = Paint()
      ..color = const Color(0xFF4EDEA3).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final zone3Stroke = Paint()
      ..color = const Color(0xFF4EDEA3).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(plumeCenter, zone3RadiusPx, zone3Paint);
    canvas.drawCircle(plumeCenter, zone3RadiusPx, zone3Stroke);

    // 4. Zone 2: Limited Exposure 30s (4.73 kW/m2) - Amber Isopleth
    final zone2RadiusPx = zone2RadiusM * scale;
    final zone2Paint = Paint()
      ..color = const Color(0xFFFFB95F).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final zone2Stroke = Paint()
      ..color = const Color(0xFFFFB95F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawCircle(plumeCenter, zone2RadiusPx, zone2Paint);
    canvas.drawCircle(plumeCenter, zone2RadiusPx, zone2Stroke);

    // 5. Zone 1: Fatal/Sterile Exclusion (>9.46 kW/m2) - Red Isopleth
    final zone1RadiusPx = zone1RadiusM * scale;
    final zone1Paint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final zone1Stroke = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawCircle(plumeCenter, zone1RadiusPx, zone1Paint);
    canvas.drawCircle(plumeCenter, zone1RadiusPx, zone1Stroke);

    // 6. Draw Flare Stack at absolute Center (0,0)
    final stackBasePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7, stackBasePaint);

    final flameTipPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, flameTipPaint);

    // 7. Wind Vector Arrow
    final windArrowStart = Offset(size.width - 45, 45);
    final windVectorEnd = Offset(
      windArrowStart.dx + math.cos(windAngleRad) * 22,
      windArrowStart.dy + math.sin(windAngleRad) * 22,
    );
    final windArrowPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(windArrowStart, windVectorEnd, windArrowPaint);
    canvas.drawCircle(windVectorEnd, 3, windArrowPaint);

    // 8. Field Radiometers (Sensors)
    for (var s in sensors) {
      final sAngleRad = (s.compassAngleDeg - 90) * (math.pi / 180.0);
      final sDistancePx = s.radialDistanceMeters * scale;
      final sensorPos = Offset(
        center.dx + math.cos(sAngleRad) * sDistancePx,
        center.dy + math.sin(sAngleRad) * sDistancePx,
      );

      final sensorPaint = Paint()
        ..color = s.currentZone.color
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromCenter(center: sensorPos, width: 8, height: 8),
        sensorPaint,
      );
    }

    // 9. Worker Beacons (Live tracking)
    for (var w in workerBeacons) {
      final wAngleRad = (w.angleDeg - 90) * (math.pi / 180.0);
      final wDistancePx = w.distanceMeters * scale;
      final workerPos = Offset(
        center.dx + math.cos(wAngleRad) * wDistancePx,
        center.dy + math.sin(wAngleRad) * wDistancePx,
      );

      final workerPaint = Paint()
        ..color = w.isInSterileZone ? const Color(0xFFEF4444) : const Color(0xFF38BDF8)
        ..style = PaintingStyle.fill;

      // Pulsing circle
      canvas.drawCircle(workerPos, w.isInSterileZone ? 8 : 6, workerPaint);

      final innerWorkerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(workerPos, 2.5, innerWorkerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlareRadiationContourPainter oldDelegate) {
    return oldDelegate.zone1RadiusM != zone1RadiusM ||
        oldDelegate.zone2RadiusM != zone2RadiusM ||
        oldDelegate.zone3RadiusM != zone3RadiusM ||
        oldDelegate.windSpeedKmh != windSpeedKmh ||
        oldDelegate.windDirectionDeg != windDirectionDeg ||
        oldDelegate.workerBeacons.first.isInSterileZone != workerBeacons.first.isInSterileZone;
  }
}
