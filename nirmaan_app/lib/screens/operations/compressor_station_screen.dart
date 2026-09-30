// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS
// ============================================================================

/// Operating status of a compressor train
enum TrainOperationalStatus {
  runningBaseLoad,
  runningModulating,
  hotStandby,
  coldStandby,
  inMaintenance,
  tripLockout,
}

/// ISO 10816-3 & ISO 7919-3 Vibration Severity Zones
enum IsoVibrationZone {
  zoneA, // Good / New condition (< 25 μm pk-pk)
  zoneB, // Acceptable for unrestricted continuous operation (25 - 45 μm pk-pk)
  zoneC, // Unsatisfactory / Alarm limit (45 - 65 μm pk-pk)
  zoneD, // Unacceptable / Instant Trip threshold (> 65 μm pk-pk)
}

/// Anti-Surge Control dynamic state
enum AscSafetyStatus {
  safeZone, // Surge margin > 15%
  controlApproach, // Surge margin 10% - 15%, SCL active
  fastActingRecycle, // Surge margin < 10%, rapid ASV opening
  surgeTripWarning, // Surge margin < 4%, imminent aerodynamic stall
}

/// Single eddy-current proximity probe telemetry reading
class VibrationProbeReading {
  final String tag;
  final String location;
  final String axis; // 'X-Radial', 'Y-Radial', 'Axial-Thrust'
  double amplitudeUmPkPk;
  double baselineUmPkPk;
  double warningThresholdUm;
  double tripThresholdUm;

  VibrationProbeReading({
    required this.tag,
    required this.location,
    required this.axis,
    required this.amplitudeUmPkPk,
    required this.baselineUmPkPk,
    this.warningThresholdUm = 45.0,
    this.tripThresholdUm = 65.0,
  });

  IsoVibrationZone get isoZone {
    if (amplitudeUmPkPk < 25.0) return IsoVibrationZone.zoneA;
    if (amplitudeUmPkPk < 45.0) return IsoVibrationZone.zoneB;
    if (amplitudeUmPkPk < 65.0) return IsoVibrationZone.zoneC;
    return IsoVibrationZone.zoneD;
  }

  Color get zoneColor {
    switch (isoZone) {
      case IsoVibrationZone.zoneA:
        return const Color(0xFF4EDEA3); // Emerald
      case IsoVibrationZone.zoneB:
        return const Color(0xFF38BDF8); // Sky blue
      case IsoVibrationZone.zoneC:
        return const Color(0xFFFFB95F); // Amber
      case IsoVibrationZone.zoneD:
        return const Color(0xFFEF4444); // Crimson
    }
  }

  String get zoneLabel {
    switch (isoZone) {
      case IsoVibrationZone.zoneA:
        return 'Zone A (Good)';
      case IsoVibrationZone.zoneB:
        return 'Zone B (Acceptable)';
      case IsoVibrationZone.zoneC:
        return 'Zone C (Alert)';
      case IsoVibrationZone.zoneD:
        return 'Zone D (Trip Danger)';
    }
  }
}

/// Babbitt metal temperature reading (Pt100 duplex RTD)
class BabbittTempSensor {
  final String tag;
  final String location;
  double temperatureC;
  final double alarmThresholdC;
  final double tripThresholdC;

  BabbittTempSensor({
    required this.tag,
    required this.location,
    required this.temperatureC,
    this.alarmThresholdC = 95.0,
    this.tripThresholdC = 105.0,
  });

  bool get isAlarm => temperatureC >= alarmThresholdC;
  bool get isTrip => temperatureC >= tripThresholdC;

  Color get statusColor {
    if (isTrip) return const Color(0xFFEF4444);
    if (isAlarm) return const Color(0xFFFFB95F);
    return const Color(0xFF4EDEA3);
  }
}

/// Dry Gas Seal (DGS) API 692 Tandem Seal Telemetry
class DryGasSealTelemetry {
  final String sealEnd; // 'Drive End (DE)' or 'Non-Drive End (NDE)'
  double bufferGasDifferentialPressureBar; // Positive margin: +3.0 to +5.0 Bar
  double primaryVentPressureBar; // Normal 0.15 - 0.45 Bar
  double secondaryVentPressureBar; // Normal 0.02 - 0.08 Bar
  double primaryLeakageFlowNm3h; // Normal < 15 Nm3/h
  double nitrogenBarrierGasPressureBar; // Normal 1.8 - 2.5 Bar
  double sealGasSupplyTempC; // Clean heated gas ~45°C
  double coalescingFilterDpBar; // Clean filter < 0.5 Bar

  DryGasSealTelemetry({
    required this.sealEnd,
    required this.bufferGasDifferentialPressureBar,
    required this.primaryVentPressureBar,
    required this.secondaryVentPressureBar,
    required this.primaryLeakageFlowNm3h,
    required this.nitrogenBarrierGasPressureBar,
    required this.sealGasSupplyTempC,
    required this.coalescingFilterDpBar,
  });

  bool get isBufferPressureSafe => bufferGasDifferentialPressureBar >= 2.0;
  bool get isPrimaryVentNormal => primaryVentPressureBar < 1.0;
  bool get isPrimaryVentAlarm => primaryVentPressureBar >= 1.0 && primaryVentPressureBar < 2.0;
  bool get isPrimaryVentTrip => primaryVentPressureBar >= 2.0;
  bool get isSecondaryVentNormal => secondaryVentPressureBar < 0.3;
}

/// Anti-Surge Control (ASC) dynamic operating data
class AntiSurgeControllerData {
  double surgeMarginPct; // e.g. 21.8%
  double recycleValvePositionPct; // 0.0% = Closed, 100.0% = Full Recycle
  double distanceToSurgeLine; // Non-dimensional (e.g. +0.22)
  double surgeControlLineOffsetPct; // Typical 10.0%
  double fastActingDerivativeGain;
  int valveStrokeTimeMs; // e.g. 840 ms
  bool isFastOpeningArmed;
  bool isTestModeActive;

  AntiSurgeControllerData({
    required this.surgeMarginPct,
    required this.recycleValvePositionPct,
    required this.distanceToSurgeLine,
    this.surgeControlLineOffsetPct = 10.0,
    this.fastActingDerivativeGain = 1.85,
    this.valveStrokeTimeMs = 840,
    this.isFastOpeningArmed = true,
    this.isTestModeActive = false,
  });

  AscSafetyStatus get safetyStatus {
    if (surgeMarginPct < 4.0) return AscSafetyStatus.surgeTripWarning;
    if (surgeMarginPct < 10.0) return AscSafetyStatus.fastActingRecycle;
    if (surgeMarginPct <= 15.0) return AscSafetyStatus.controlApproach;
    return AscSafetyStatus.safeZone;
  }

  Color get statusColor {
    switch (safetyStatus) {
      case AscSafetyStatus.safeZone:
        return const Color(0xFF4EDEA3);
      case AscSafetyStatus.controlApproach:
        return const Color(0xFFFFB95F);
      case AscSafetyStatus.fastActingRecycle:
        return const Color(0xFFFF8A00);
      case AscSafetyStatus.surgeTripWarning:
        return const Color(0xFFEF4444);
    }
  }

  String get statusText {
    switch (safetyStatus) {
      case AscSafetyStatus.safeZone:
        return 'STABLE ENVELOPE';
      case AscSafetyStatus.controlApproach:
        return 'SCL APPROACH';
      case AscSafetyStatus.fastActingRecycle:
        return 'FAST RECYCLE OPEN';
      case AscSafetyStatus.surgeTripWarning:
        return 'SURGE TRIP IMMINENT';
    }
  }
}

/// Associated Condensate Booster Pump Telemetry (API 610 BB3)
class BoosterPumpTelemetry {
  final String tag; // BP-101A
  final String name;
  bool isRunning;
  double suctionPressureBar;
  double dischargePressureBar;
  double flowRateM3h;
  double motorCurrentAmps;
  double motorWindingTempC;
  double casingVibrationMmS;
  double sealPlan53BPressureBar;
  double npshAvailableM;
  double npshRequiredM;

  BoosterPumpTelemetry({
    required this.tag,
    required this.name,
    required this.isRunning,
    required this.suctionPressureBar,
    required this.dischargePressureBar,
    required this.flowRateM3h,
    required this.motorCurrentAmps,
    required this.motorWindingTempC,
    required this.casingVibrationMmS,
    required this.sealPlan53BPressureBar,
    required this.npshAvailableM,
    required this.npshRequiredM,
  });

  double get differentialHeadM => (dischargePressureBar - suctionPressureBar) * 10.197;
  double get npshMarginM => npshAvailableM - npshRequiredM;
  bool get isNpshSafe => npshMarginM >= 1.5;
}

/// Complete multi-stage centrifugal compressor train
class CompressorTrainTelemetry {
  final String id; // 'C-101', 'C-102', 'C-103'
  final String name;
  final String stationId;
  final String driverDescription; // 'Solar Mars 100 Gas Turbine (11,200 kW)'
  final double ratedPowerKw;
  final double ratedSpeedRpm;
  final double maxContinuousSpeedRpm;
  final double tripSpeedRpm;
  final int stageCount; // 2 or 3 stages

  TrainOperationalStatus status;
  double runningHours;

  // Real-time Thermodynamic & Process Data
  double suctionPressureBar;
  double suctionTemperatureC;
  double interstagePressureBar;
  double interstageTemperatureC;
  double dischargePressureBar;
  double dischargeTemperatureC;
  double massFlowRateKgH; // e.g. 52,400 kg/h
  double volumetricSuctionFlowM3h; // e.g. 1,480 m3/h
  double shaftSpeedRpm; // e.g. 11,850 RPM
  double polytropicHeadKjKg; // e.g. 78.4 kJ/kg
  double polytropicEfficiencyPct; // e.g. 84.8%
  double driverPowerKw; // e.g. 9,450 kW
  double turbineExhaustGasTempC; // e.g. 518 °C
  double fuelGasFlowSm3h; // e.g. 2,140 Sm3/h
  double lubeOilHeaderPressureBar; // e.g. 2.9 Bar
  double lubeOilSupplyTempC; // e.g. 45.8 °C

  // Anti-Surge Control Subsystem
  AntiSurgeControllerData antiSurge;

  // ISO 10816-3 Non-Contact Vibration Probes
  List<VibrationProbeReading> vibrationProbes;

  // Babbitt Bearing RTDs
  List<BabbittTempSensor> babbittTemps;

  // Dry Gas Seal Systems (DE & NDE)
  DryGasSealTelemetry dgsDriveEnd;
  DryGasSealTelemetry dgsNonDriveEnd;

  // Real-time Trend Histories for Charts
  List<FlSpot> suctionPressureTrend;
  List<FlSpot> dischargePressureTrend;
  List<FlSpot> flowTrend;
  List<FlSpot> speedTrend;
  List<FlSpot> surgeMarginTrend;
  List<FlSpot> vibrationTrend;

  CompressorTrainTelemetry({
    required this.id,
    required this.name,
    required this.stationId,
    required this.driverDescription,
    required this.ratedPowerKw,
    required this.ratedSpeedRpm,
    required this.maxContinuousSpeedRpm,
    required this.tripSpeedRpm,
    required this.stageCount,
    required this.status,
    required this.runningHours,
    required this.suctionPressureBar,
    required this.suctionTemperatureC,
    required this.interstagePressureBar,
    required this.interstageTemperatureC,
    required this.dischargePressureBar,
    required this.dischargeTemperatureC,
    required this.massFlowRateKgH,
    required this.volumetricSuctionFlowM3h,
    required this.shaftSpeedRpm,
    required this.polytropicHeadKjKg,
    required this.polytropicEfficiencyPct,
    required this.driverPowerKw,
    required this.turbineExhaustGasTempC,
    required this.fuelGasFlowSm3h,
    required this.lubeOilHeaderPressureBar,
    required this.lubeOilSupplyTempC,
    required this.antiSurge,
    required this.vibrationProbes,
    required this.babbittTemps,
    required this.dgsDriveEnd,
    required this.dgsNonDriveEnd,
    required this.suctionPressureTrend,
    required this.dischargePressureTrend,
    required this.flowTrend,
    required this.speedTrend,
    required this.surgeMarginTrend,
    required this.vibrationTrend,
  });

  double get compressionRatio =>
      suctionPressureBar > 0 ? (dischargePressureBar / suctionPressureBar) : 1.0;

  double get speedPercentage => (shaftSpeedRpm / ratedSpeedRpm) * 100.0;

  double get maxVibrationUm => vibrationProbes.isEmpty
      ? 0.0
      : vibrationProbes.map((p) => p.amplitudeUmPkPk).reduce(math.max);

  IsoVibrationZone get overallVibrationZone {
    final maxV = maxVibrationUm;
    if (maxV < 25.0) return IsoVibrationZone.zoneA;
    if (maxV < 45.0) return IsoVibrationZone.zoneB;
    if (maxV < 65.0) return IsoVibrationZone.zoneC;
    return IsoVibrationZone.zoneD;
  }

  bool get hasActiveAlarm =>
      overallVibrationZone == IsoVibrationZone.zoneC ||
      overallVibrationZone == IsoVibrationZone.zoneD ||
      antiSurge.safetyStatus == AscSafetyStatus.fastActingRecycle ||
      antiSurge.safetyStatus == AscSafetyStatus.surgeTripWarning ||
      babbittTemps.any((b) => b.isAlarm || b.isTrip) ||
      !dgsDriveEnd.isBufferPressureSafe ||
      !dgsNonDriveEnd.isBufferPressureSafe;
}

/// Gas Compressor Station Master Entity
class CompressorStationData {
  final String id; // 'CS-DULIAJAN', 'CS-MORAN'
  final String code; // 'CS-01', 'CS-02'
  final String name;
  final String chainage;
  final String location;
  final String pipelineSegment;
  double headerSuctionPressureBar;
  double headerSuctionTempC;
  double headerDischargePressureBar;
  double headerDischargeTempC;
  double stationTotalFlowKgH;
  double stationTotalPowerMw;
  double stationFuelGasSm3h;
  bool esdSystemArmed;
  List<CompressorTrainTelemetry> trains;
  List<BoosterPumpTelemetry> boosterPumps;

  CompressorStationData({
    required this.id,
    required this.code,
    required this.name,
    required this.chainage,
    required this.location,
    required this.pipelineSegment,
    required this.headerSuctionPressureBar,
    required this.headerSuctionTempC,
    required this.headerDischargePressureBar,
    required this.headerDischargeTempC,
    required this.stationTotalFlowKgH,
    required this.stationTotalPowerMw,
    required this.stationFuelGasSm3h,
    this.esdSystemArmed = true,
    required this.trains,
    required this.boosterPumps,
  });

  double get stationCompressionRatio =>
      headerSuctionPressureBar > 0
          ? (headerDischargePressureBar / headerSuctionPressureBar)
          : 1.0;

  int get runningTrainsCount =>
      trains.where((t) =>
          t.status == TrainOperationalStatus.runningBaseLoad ||
          t.status == TrainOperationalStatus.runningModulating).length;
}

/// Diagnostic Trip & Interlock event model
class CompressorSafetyInterlock {
  final String id;
  final DateTime timestamp;
  final String trainId;
  final String parameterName;
  final double tripSetpoint;
  final double currentReading;
  final String engineeringUnits;
  final String causeDescription;
  final bool isTripped;
  final bool isLatched;

  const CompressorSafetyInterlock({
    required this.id,
    required this.timestamp,
    required this.trainId,
    required this.parameterName,
    required this.tripSetpoint,
    required this.currentReading,
    required this.engineeringUnits,
    required this.causeDescription,
    required this.isTripped,
    required this.isLatched,
  });
}

// ============================================================================
// MAIN COMPRESSOR STATION SCREEN
// ============================================================================

class CompressorStationScreen extends StatefulWidget {
  const CompressorStationScreen({super.key});

  @override
  State<CompressorStationScreen> createState() =>
      _CompressorStationScreenState();
}

class _CompressorStationScreenState extends State<CompressorStationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _liveTelemetryTimer;
  bool _isLiveStreaming = true;
  final math.Random _random = math.Random(101);

  // Selected station: 0 = CS-Duliajan, 1 = CS-Moran
  int _selectedStationIndex = 0;

  // Selected train within active station: 0 = C-101, 1 = C-102, 2 = C-103, 3 = BP Booster
  int _selectedTrainIndex = 0;

  // Master Data Structures
  late List<CompressorStationData> _stations;
  late List<CompressorSafetyInterlock> _safetyInterlocks;

  // ASC Simulation test state
  bool _ascTestValveModulating = false;
  double _manualValveTestOverridePct = 0.0;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeCompressorStationData();
    _startLiveSimulation();
  }

  @override
  void dispose() {
    _liveTelemetryTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================================
  // DATA INITIALIZATION
  // ============================================================================

  void _initializeCompressorStationData() {
    final now = DateTime.now();

    // Setup CS-Duliajan (Primary Dispatch Compressor Station)
    final duliajanTrains = [
      _buildCompressorTrain(
        id: 'C-101',
        name: 'Centrifugal Train 1',
        stationId: 'CS-DULIAJAN',
        driver: 'Solar Mars 100 Gas Turbine (11,200 kW)',
        ratedKw: 11200,
        ratedRpm: 12200,
        maxContinuousRpm: 12800,
        tripRpm: 13420,
        stageCount: 2,
        status: TrainOperationalStatus.runningBaseLoad,
        runningHours: 14280.5,
        suctionP: 24.60,
        suctionT: 28.5,
        interstageP: 47.80,
        interstageT: 38.2, // Intercooled
        dischargeP: 82.40,
        dischargeT: 104.5,
        flowKgH: 52400.0,
        flowM3h: 1480.0,
        speedRpm: 11840.0,
        headKjKg: 78.4,
        effPct: 85.2,
        powerKw: 9540.0,
        egtC: 516.0,
        fuelSm3h: 2180.0,
        surgeMarginPct: 21.8,
        asvPosPct: 0.0,
        distSurge: 0.22,
        vibrations: [18.4, 19.8, 16.2, 17.5, 4.2, 3.8],
        babbittTemps: [76.5, 78.2, 82.4, 71.0],
        dgsBufferDp: 4.30,
        dgsVent1DE: 0.26,
        dgsVent2DE: 0.04,
        dgsVent1NDE: 0.29,
        dgsVent2NDE: 0.05,
      ),
      _buildCompressorTrain(
        id: 'C-102',
        name: 'Centrifugal Train 2',
        stationId: 'CS-DULIAJAN',
        driver: 'Solar Mars 100 Gas Turbine (11,200 kW)',
        ratedKw: 11200,
        ratedRpm: 12200,
        maxContinuousRpm: 12800,
        tripRpm: 13420,
        stageCount: 2,
        status: TrainOperationalStatus.runningModulating,
        runningHours: 12150.2,
        suctionP: 24.55,
        suctionT: 28.4,
        interstageP: 47.65,
        interstageT: 38.0,
        dischargeP: 82.35,
        dischargeT: 103.8,
        flowKgH: 48900.0,
        flowM3h: 1395.0,
        speedRpm: 11420.0,
        headKjKg: 76.8,
        effPct: 84.6,
        powerKw: 8820.0,
        egtC: 498.0,
        fuelSm3h: 2040.0,
        surgeMarginPct: 18.5,
        asvPosPct: 0.0,
        distSurge: 0.19,
        vibrations: [22.1, 23.4, 20.8, 21.6, 5.1, 4.4],
        babbittTemps: [78.0, 79.5, 84.1, 72.8],
        dgsBufferDp: 4.15,
        dgsVent1DE: 0.31,
        dgsVent2DE: 0.05,
        dgsVent1NDE: 0.33,
        dgsVent2NDE: 0.05,
      ),
      _buildCompressorTrain(
        id: 'C-103',
        name: 'Centrifugal Train 3',
        stationId: 'CS-DULIAJAN',
        driver: 'Solar Taurus 70 Gas Turbine (7,900 kW)',
        ratedKw: 7900,
        ratedRpm: 14300,
        maxContinuousRpm: 15000,
        tripRpm: 15730,
        stageCount: 2,
        status: TrainOperationalStatus.hotStandby,
        runningHours: 6410.8,
        suctionP: 24.50,
        suctionT: 27.8,
        interstageP: 24.50,
        interstageT: 27.8,
        dischargeP: 24.50,
        dischargeT: 27.8,
        flowKgH: 0.0,
        flowM3h: 0.0,
        speedRpm: 0.0,
        headKjKg: 0.0,
        effPct: 0.0,
        powerKw: 0.0,
        egtC: 38.0,
        fuelSm3h: 0.0,
        surgeMarginPct: 0.0,
        asvPosPct: 100.0, // Open in depressurized standby
        distSurge: 0.0,
        vibrations: [2.1, 1.9, 1.8, 2.0, 0.5, 0.4],
        babbittTemps: [36.2, 35.8, 38.0, 34.5],
        dgsBufferDp: 3.80,
        dgsVent1DE: 0.08,
        dgsVent2DE: 0.01,
        dgsVent1NDE: 0.09,
        dgsVent2NDE: 0.01,
      ),
    ];

    final duliajanPumps = [
      BoosterPumpTelemetry(
        tag: 'BP-101A',
        name: 'Condensate Booster Pump A',
        isRunning: true,
        suctionPressureBar: 3.85,
        dischargePressureBar: 26.40,
        flowRateM3h: 42.5,
        motorCurrentAmps: 64.2,
        motorWindingTempC: 68.4,
        casingVibrationMmS: 1.85,
        sealPlan53BPressureBar: 30.5,
        npshAvailableM: 6.8,
        npshRequiredM: 3.2,
      ),
      BoosterPumpTelemetry(
        tag: 'BP-101B',
        name: 'Condensate Booster Pump B',
        isRunning: false,
        suctionPressureBar: 3.85,
        dischargePressureBar: 3.85,
        flowRateM3h: 0.0,
        motorCurrentAmps: 0.0,
        motorWindingTempC: 32.1,
        casingVibrationMmS: 0.12,
        sealPlan53BPressureBar: 29.8,
        npshAvailableM: 6.8,
        npshRequiredM: 3.2,
      ),
    ];

    // Setup CS-Moran (Intermediate Re-compression Hub)
    final moranTrains = [
      _buildCompressorTrain(
        id: 'C-201',
        name: 'Centrifugal Train 201',
        stationId: 'CS-MORAN',
        driver: 'GE Nuovo Pignone PGT10 (10,500 kW)',
        ratedKw: 10500,
        ratedRpm: 11000,
        maxContinuousRpm: 11550,
        tripRpm: 12100,
        stageCount: 2,
        status: TrainOperationalStatus.runningBaseLoad,
        runningHours: 18920.0,
        suctionP: 54.20,
        suctionT: 26.2,
        interstageP: 72.80,
        interstageT: 39.5,
        dischargeP: 94.60,
        dischargeT: 106.8,
        flowKgH: 56800.0,
        flowM3h: 960.0,
        speedRpm: 10650.0,
        headKjKg: 64.2,
        effPct: 86.4,
        powerKw: 9150.0,
        egtC: 524.0,
        fuelSm3h: 2110.0,
        surgeMarginPct: 23.4,
        asvPosPct: 0.0,
        distSurge: 0.24,
        vibrations: [19.2, 21.0, 18.5, 19.4, 4.6, 4.0],
        babbittTemps: [77.4, 79.1, 83.2, 73.0],
        dgsBufferDp: 4.45,
        dgsVent1DE: 0.27,
        dgsVent2DE: 0.04,
        dgsVent1NDE: 0.28,
        dgsVent2NDE: 0.04,
      ),
      _buildCompressorTrain(
        id: 'C-202',
        name: 'Centrifugal Train 202',
        stationId: 'CS-MORAN',
        driver: 'GE Nuovo Pignone PGT10 (10,500 kW)',
        ratedKw: 10500,
        ratedRpm: 11000,
        maxContinuousRpm: 11550,
        tripRpm: 12100,
        stageCount: 2,
        status: TrainOperationalStatus.runningModulating,
        runningHours: 16480.3,
        suctionP: 54.15,
        suctionT: 26.0,
        interstageP: 72.60,
        interstageT: 39.2,
        dischargeP: 94.50,
        dischargeT: 105.9,
        flowKgH: 53100.0,
        flowM3h: 910.0,
        speedRpm: 10420.0,
        headKjKg: 63.8,
        effPct: 85.8,
        powerKw: 8640.0,
        egtC: 512.0,
        fuelSm3h: 1980.0,
        surgeMarginPct: 19.8,
        asvPosPct: 0.0,
        distSurge: 0.20,
        vibrations: [24.5, 25.8, 23.2, 24.1, 5.8, 4.9],
        babbittTemps: [80.2, 82.0, 86.4, 75.1],
        dgsBufferDp: 4.20,
        dgsVent1DE: 0.35,
        dgsVent2DE: 0.06,
        dgsVent1NDE: 0.38,
        dgsVent2NDE: 0.06,
      ),
      _buildCompressorTrain(
        id: 'C-203',
        name: 'Centrifugal Train 203',
        stationId: 'CS-MORAN',
        driver: 'Siemens SGT-300 Gas Turbine (7,900 kW)',
        ratedKw: 7900,
        ratedRpm: 14000,
        maxContinuousRpm: 14700,
        tripRpm: 15400,
        stageCount: 2,
        status: TrainOperationalStatus.inMaintenance,
        runningHours: 9840.1,
        suctionP: 54.00,
        suctionT: 25.5,
        interstageP: 54.00,
        interstageT: 25.5,
        dischargeP: 54.00,
        dischargeT: 25.5,
        flowKgH: 0.0,
        flowM3h: 0.0,
        speedRpm: 0.0,
        headKjKg: 0.0,
        effPct: 0.0,
        powerKw: 0.0,
        egtC: 28.0,
        fuelSm3h: 0.0,
        surgeMarginPct: 0.0,
        asvPosPct: 100.0,
        distSurge: 0.0,
        vibrations: [1.2, 1.4, 1.1, 1.3, 0.2, 0.2],
        babbittTemps: [28.4, 28.0, 29.5, 27.8],
        dgsBufferDp: 0.0,
        dgsVent1DE: 0.02,
        dgsVent2DE: 0.00,
        dgsVent1NDE: 0.02,
        dgsVent2NDE: 0.00,
      ),
    ];

    final moranPumps = [
      BoosterPumpTelemetry(
        tag: 'BP-201A',
        name: 'NGL Injection Booster Pump 1',
        isRunning: true,
        suctionPressureBar: 6.20,
        dischargePressureBar: 34.80,
        flowRateM3h: 38.0,
        motorCurrentAmps: 58.6,
        motorWindingTempC: 64.2,
        casingVibrationMmS: 1.62,
        sealPlan53BPressureBar: 38.5,
        npshAvailableM: 7.4,
        npshRequiredM: 3.5,
      ),
      BoosterPumpTelemetry(
        tag: 'BP-201B',
        name: 'NGL Injection Booster Pump 2',
        isRunning: false,
        suctionPressureBar: 6.20,
        dischargePressureBar: 6.20,
        flowRateM3h: 0.0,
        motorCurrentAmps: 0.0,
        motorWindingTempC: 29.5,
        casingVibrationMmS: 0.08,
        sealPlan53BPressureBar: 37.8,
        npshAvailableM: 7.4,
        npshRequiredM: 3.5,
      ),
    ];

    _stations = [
      CompressorStationData(
        id: 'CS-DULIAJAN',
        code: 'CS-01',
        name: 'Duliajan Gas Compressor Station',
        chainage: 'KP 0+000',
        location: 'Oil India Limited Field Headquarters, Assam',
        pipelineSegment: 'Duliajan-Numaligarh 24" Trunkline',
        headerSuctionPressureBar: 24.60,
        headerSuctionTempC: 28.5,
        headerDischargePressureBar: 82.40,
        headerDischargeTempC: 104.2,
        stationTotalFlowKgH: 101300.0, // C-101 + C-102
        stationTotalPowerMw: 18.36,
        stationFuelGasSm3h: 4220.0,
        trains: duliajanTrains,
        boosterPumps: duliajanPumps,
      ),
      CompressorStationData(
        id: 'CS-MORAN',
        code: 'CS-02',
        name: 'Moran Intermediate Booster Station',
        chainage: 'KP 28+400',
        location: 'Moran Junction Terminal, Charaideo / Dibrugarh',
        pipelineSegment: 'Moran-Sibsagar High Pressure Sector',
        headerSuctionPressureBar: 54.20,
        headerSuctionTempC: 26.2,
        headerDischargePressureBar: 94.60,
        headerDischargeTempC: 106.4,
        stationTotalFlowKgH: 109900.0,
        stationTotalPowerMw: 17.79,
        stationFuelGasSm3h: 4090.0,
        trains: moranTrains,
        boosterPumps: moranPumps,
      ),
    ];

    // Initial Cause & Effect Safety Interlocks
    _safetyInterlocks = [
      CompressorSafetyInterlock(
        id: 'INT-01',
        timestamp: now.subtract(const Duration(minutes: 42)),
        trainId: 'C-101',
        parameterName: 'Discharge Pressure High-High (PSHH)',
        tripSetpoint: 98.0,
        currentReading: 82.40,
        engineeringUnits: 'Bar(g)',
        causeDescription: 'Prevents pipeline MAOP violation (100 Bar rated)',
        isTripped: false,
        isLatched: false,
      ),
      CompressorSafetyInterlock(
        id: 'INT-02',
        timestamp: now.subtract(const Duration(minutes: 36)),
        trainId: 'C-101',
        parameterName: 'Suction Pressure Low-Low (PSLL)',
        tripSetpoint: 12.0,
        currentReading: 24.60,
        engineeringUnits: 'Bar(g)',
        causeDescription: 'Protects compressor against vacuum/cavitation pull',
        isTripped: false,
        isLatched: false,
      ),
      CompressorSafetyInterlock(
        id: 'INT-03',
        timestamp: now.subtract(const Duration(minutes: 31)),
        trainId: 'C-101',
        parameterName: 'Thrust Bearing Vibration High-High (VISHH)',
        tripSetpoint: 65.0,
        currentReading: 19.8,
        engineeringUnits: 'μm pk-pk',
        causeDescription: 'ISO 10816-3 Zone D shutdown for catastrophic rub prevention',
        isTripped: false,
        isLatched: false,
      ),
      CompressorSafetyInterlock(
        id: 'INT-04',
        timestamp: now.subtract(const Duration(minutes: 25)),
        trainId: 'C-101',
        parameterName: 'Dry Gas Seal Buffer Gas DP Low-Low (PDIFFLL)',
        tripSetpoint: 1.5,
        currentReading: 4.30,
        engineeringUnits: 'Bar',
        causeDescription: 'API 692 seal face hydrocarbon blow-by prevention',
        isTripped: false,
        isLatched: false,
      ),
      CompressorSafetyInterlock(
        id: 'INT-05',
        timestamp: now.subtract(const Duration(minutes: 18)),
        trainId: 'C-101',
        parameterName: 'Journal Bearing Babbitt Temp High-High (TSHH)',
        tripSetpoint: 105.0,
        currentReading: 78.2,
        engineeringUnits: '°C',
        causeDescription: 'Bearing babbitt wipeout thermal runaway prevention',
        isTripped: false,
        isLatched: false,
      ),
      CompressorSafetyInterlock(
        id: 'INT-06',
        timestamp: now.subtract(const Duration(minutes: 12)),
        trainId: 'C-101',
        parameterName: 'Turbine Overspeed Trip (OST)',
        tripSetpoint: 13420.0,
        currentReading: 11840.0,
        engineeringUnits: 'RPM',
        causeDescription: 'API 670 triple-modular electronic overspeed trip',
        isTripped: false,
        isLatched: false,
      ),
    ];
  }

  CompressorTrainTelemetry _buildCompressorTrain({
    required String id,
    required String name,
    required String stationId,
    required String driver,
    required double ratedKw,
    required double ratedRpm,
    required double maxContinuousRpm,
    required double tripRpm,
    required int stageCount,
    required TrainOperationalStatus status,
    required double runningHours,
    required double suctionP,
    required double suctionT,
    required double interstageP,
    required double interstageT,
    required double dischargeP,
    required double dischargeT,
    required double flowKgH,
    required double flowM3h,
    required double speedRpm,
    required double headKjKg,
    required double effPct,
    required double powerKw,
    required double egtC,
    required double fuelSm3h,
    required double surgeMarginPct,
    required double asvPosPct,
    required double distSurge,
    required List<double> vibrations, // 6 probes
    required List<double> babbittTemps, // 4 sensors
    required double dgsBufferDp,
    required double dgsVent1DE,
    required double dgsVent2DE,
    required double dgsVent1NDE,
    required double dgsVent2NDE,
  }) {
    return CompressorTrainTelemetry(
      id: id,
      name: name,
      stationId: stationId,
      driverDescription: driver,
      ratedPowerKw: ratedKw,
      ratedSpeedRpm: ratedRpm,
      maxContinuousSpeedRpm: maxContinuousRpm,
      tripSpeedRpm: tripRpm,
      stageCount: stageCount,
      status: status,
      runningHours: runningHours,
      suctionPressureBar: suctionP,
      suctionTemperatureC: suctionT,
      interstagePressureBar: interstageP,
      interstageTemperatureC: interstageT,
      dischargePressureBar: dischargeP,
      dischargeTemperatureC: dischargeT,
      massFlowRateKgH: flowKgH,
      volumetricSuctionFlowM3h: flowM3h,
      shaftSpeedRpm: speedRpm,
      polytropicHeadKjKg: headKjKg,
      polytropicEfficiencyPct: effPct,
      driverPowerKw: powerKw,
      turbineExhaustGasTempC: egtC,
      fuelGasFlowSm3h: fuelSm3h,
      lubeOilHeaderPressureBar: 2.85,
      lubeOilSupplyTempC: 45.4,
      antiSurge: AntiSurgeControllerData(
        surgeMarginPct: surgeMarginPct,
        recycleValvePositionPct: asvPosPct,
        distanceToSurgeLine: distSurge,
      ),
      vibrationProbes: [
        VibrationProbeReading(
          tag: 'VE-101A',
          location: 'Compressor DE Journal',
          axis: 'X-Radial (45°)',
          amplitudeUmPkPk: vibrations[0],
          baselineUmPkPk: 14.5,
        ),
        VibrationProbeReading(
          tag: 'VE-101B',
          location: 'Compressor DE Journal',
          axis: 'Y-Radial (135°)',
          amplitudeUmPkPk: vibrations[1],
          baselineUmPkPk: 15.0,
        ),
        VibrationProbeReading(
          tag: 'VE-102A',
          location: 'Compressor NDE Journal',
          axis: 'X-Radial (45°)',
          amplitudeUmPkPk: vibrations[2],
          baselineUmPkPk: 13.8,
        ),
        VibrationProbeReading(
          tag: 'VE-102B',
          location: 'Compressor NDE Journal',
          axis: 'Y-Radial (135°)',
          amplitudeUmPkPk: vibrations[3],
          baselineUmPkPk: 14.2,
        ),
        VibrationProbeReading(
          tag: 'ZT-103A',
          location: 'Thrust Collar Active',
          axis: 'Axial Displacement',
          amplitudeUmPkPk: vibrations[4],
          baselineUmPkPk: 3.5,
          warningThresholdUm: 15.0,
          tripThresholdUm: 25.0,
        ),
        VibrationProbeReading(
          tag: 'ZT-103B',
          location: 'Thrust Collar Inactive',
          axis: 'Axial Displacement',
          amplitudeUmPkPk: vibrations[5],
          baselineUmPkPk: 3.2,
          warningThresholdUm: 15.0,
          tripThresholdUm: 25.0,
        ),
      ],
      babbittTemps: [
        BabbittTempSensor(
          tag: 'TI-101A',
          location: 'DE Journal Babbitt (Loaded)',
          temperatureC: babbittTemps[0],
        ),
        BabbittTempSensor(
          tag: 'TI-101B',
          location: 'NDE Journal Babbitt (Loaded)',
          temperatureC: babbittTemps[1],
        ),
        BabbittTempSensor(
          tag: 'TI-102A',
          location: 'Thrust Active Pad (Max Load)',
          temperatureC: babbittTemps[2],
        ),
        BabbittTempSensor(
          tag: 'TI-102B',
          location: 'Thrust Inactive Pad',
          temperatureC: babbittTemps[3],
        ),
      ],
      dgsDriveEnd: DryGasSealTelemetry(
        sealEnd: 'Drive End (DE)',
        bufferGasDifferentialPressureBar: dgsBufferDp,
        primaryVentPressureBar: dgsVent1DE,
        secondaryVentPressureBar: dgsVent2DE,
        primaryLeakageFlowNm3h: 7.2,
        nitrogenBarrierGasPressureBar: 2.15,
        sealGasSupplyTempC: 44.5,
        coalescingFilterDpBar: 0.32,
      ),
      dgsNonDriveEnd: DryGasSealTelemetry(
        sealEnd: 'Non-Drive End (NDE)',
        bufferGasDifferentialPressureBar: dgsBufferDp - 0.1,
        primaryVentPressureBar: dgsVent1NDE,
        secondaryVentPressureBar: dgsVent2NDE,
        primaryLeakageFlowNm3h: 7.6,
        nitrogenBarrierGasPressureBar: 2.12,
        sealGasSupplyTempC: 44.0,
        coalescingFilterDpBar: 0.33,
      ),
      suctionPressureTrend: _generateTrendPoints(suctionP, 0.25),
      dischargePressureTrend: _generateTrendPoints(dischargeP, 0.40),
      flowTrend: _generateTrendPoints(flowKgH / 1000.0, 0.60),
      speedTrend: _generateTrendPoints(speedRpm, 45.0),
      surgeMarginTrend: _generateTrendPoints(surgeMarginPct, 0.35),
      vibrationTrend: _generateTrendPoints(vibrations[0], 0.4),
    );
  }

  List<FlSpot> _generateTrendPoints(double baseValue, double jitter) {
    final list = <FlSpot>[];
    for (int i = 0; i < 15; i++) {
      final noise = (_random.nextDouble() - 0.5) * jitter;
      list.add(FlSpot(i.toDouble(), math.max(0.0, baseValue + noise)));
    }
    return list;
  }

  // ============================================================================
  // LIVE TELEMETRY SIMULATION LOOP
  // ============================================================================

  void _startLiveSimulation() {
    _liveTelemetryTimer?.cancel();
    _liveTelemetryTimer =
        Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!_isLiveStreaming || !mounted) return;

      setState(() {
        for (final station in _stations) {
          for (final train in station.trains) {
            if (train.status == TrainOperationalStatus.runningBaseLoad ||
                train.status == TrainOperationalStatus.runningModulating) {
              // Real-time perturbations
              final pJitter = (_random.nextDouble() - 0.49) * 0.08;
              train.suctionPressureBar =
                  math.max(20.0, train.suctionPressureBar + pJitter);

              final dJitter = (_random.nextDouble() - 0.48) * 0.15;
              train.dischargePressureBar =
                  math.max(70.0, train.dischargePressureBar + dJitter);

              final fJitter = (_random.nextDouble() - 0.5) * 120.0;
              train.massFlowRateKgH =
                  math.max(30000.0, train.massFlowRateKgH + fJitter);

              final rpmJitter = (_random.nextDouble() - 0.5) * 15.0;
              train.shaftSpeedRpm =
                  math.max(8000.0, train.shaftSpeedRpm + rpmJitter);

              // Update ASC parameters
              if (!_ascTestValveModulating) {
                final surgeJitter = (_random.nextDouble() - 0.5) * 0.25;
                train.antiSurge.surgeMarginPct = (train.antiSurge.surgeMarginPct + surgeJitter)
                    .clamp(14.0, 26.0);
                train.antiSurge.distanceToSurgeLine =
                    train.antiSurge.surgeMarginPct / 100.0;
              } else {
                train.antiSurge.recycleValvePositionPct = _manualValveTestOverridePct;
                train.antiSurge.surgeMarginPct = 25.0 + (_manualValveTestOverridePct * 0.2);
              }

              // Update Bearing Vibration
              for (final probe in train.vibrationProbes) {
                final vJitter = (_random.nextDouble() - 0.5) * 0.4;
                probe.amplitudeUmPkPk =
                    (probe.amplitudeUmPkPk + vJitter).clamp(8.0, 68.0);
              }

              // Update Babbitt Temps
              for (final sensor in train.babbittTemps) {
                final tJitter = (_random.nextDouble() - 0.5) * 0.15;
                sensor.temperatureC =
                    (sensor.temperatureC + tJitter).clamp(50.0, 110.0);
              }

              // Update DGS Pressures
              final dgsJitter = (_random.nextDouble() - 0.5) * 0.02;
              train.dgsDriveEnd.bufferGasDifferentialPressureBar =
                  (train.dgsDriveEnd.bufferGasDifferentialPressureBar + dgsJitter)
                      .clamp(3.0, 5.5);
              train.dgsDriveEnd.primaryVentPressureBar =
                  (train.dgsDriveEnd.primaryVentPressureBar + (dgsJitter * 0.5))
                      .clamp(0.18, 0.48);

              // Shift and push history trends
              _shiftTrend(train.suctionPressureTrend, train.suctionPressureBar);
              _shiftTrend(train.dischargePressureTrend, train.dischargePressureBar);
              _shiftTrend(train.flowTrend, train.massFlowRateKgH / 1000.0);
              _shiftTrend(train.speedTrend, train.shaftSpeedRpm);
              _shiftTrend(train.surgeMarginTrend, train.antiSurge.surgeMarginPct);
              _shiftTrend(
                  train.vibrationTrend, train.vibrationProbes.first.amplitudeUmPkPk);
            }
          }

          // Recalculate station summary metrics
          final running = station.trains
              .where((t) =>
                  t.status == TrainOperationalStatus.runningBaseLoad ||
                  t.status == TrainOperationalStatus.runningModulating)
              .toList();

          if (running.isNotEmpty) {
            station.stationTotalFlowKgH =
                running.map((t) => t.massFlowRateKgH).reduce((a, b) => a + b);
            station.stationTotalPowerMw =
                running.map((t) => t.driverPowerKw / 1000.0).reduce((a, b) => a + b);
            station.stationFuelGasSm3h =
                running.map((t) => t.fuelGasFlowSm3h).reduce((a, b) => a + b);
            station.headerSuctionPressureBar = running.first.suctionPressureBar;
            station.headerDischargePressureBar = running.first.dischargePressureBar;
          }
        }
      });
    });
  }

  void _shiftTrend(List<FlSpot> trend, double newValue) {
    if (trend.isEmpty) return;
    trend.removeAt(0);
    for (int i = 0; i < trend.length; i++) {
      trend[i] = FlSpot(i.toDouble(), trend[i].y);
    }
    trend.add(FlSpot(trend.length.toDouble(), newValue));
  }

  // ============================================================================
  // UI BUILD & SCAFFOLD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final currentStation = _stations[_selectedStationIndex];
    final currentTrain = currentStation.trains.length > _selectedTrainIndex
        ? currentStation.trains[_selectedTrainIndex]
        : currentStation.trains.first;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Compressor & Booster Station',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                _buildLiveBadge(),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${currentStation.name} • ${currentTrain.id} (${currentTrain.driverDescription.split(' (').first})',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Station Toggle Dropdown
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedStationIndex,
                dropdownColor: AppTheme.surfaceCard,
                icon: const Icon(Icons.arrow_drop_down_rounded,
                    color: AppTheme.primaryLight, size: 20),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  DropdownMenuItem(
                    value: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.factory_rounded,
                            size: 14, color: AppTheme.primaryLight),
                        SizedBox(width: 6),
                        Text('CS-Duliajan'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.compress_rounded,
                            size: 14, color: Color(0xFFFFB95F)),
                        SizedBox(width: 6),
                        Text('CS-Moran'),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedStationIndex = val;
                      _selectedTrainIndex = 0;
                    });
                  }
                },
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isLiveStreaming
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: _isLiveStreaming
                  ? const Color(0xFF4EDEA3)
                  : AppTheme.textMuted,
            ),
            tooltip: _isLiveStreaming ? 'Pause Telemetry' : 'Resume Telemetry',
            onPressed: () {
              setState(() {
                _isLiveStreaming = !_isLiveStreaming;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textPrimary),
            color: AppTheme.surfaceCard,
            onSelected: (action) {
              if (action == 'asc_test') {
                _showAscTestDialog(currentTrain);
              } else if (action == 'vibration_spectrum') {
                _showVibrationSpectrumDialog(currentTrain);
              } else if (action == 'export_log') {
                _showExportLogModal();
              } else if (action == 'reset_alarms') {
                _resetAllAlarms();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'asc_test',
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFFFFB95F), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('ASC Surge Test Stroke',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'vibration_spectrum',
                child: Row(
                  children: [
                    Icon(Icons.graphic_eq_rounded,
                        color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Bently Nevada FFT Orbit',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_log',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined,
                        color: Color(0xFF4EDEA3), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Export Telemetry Dossier',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_alarms',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt_rounded,
                        color: Color(0xFFEF4444), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Reset & Acknowledge Alarms',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
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
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              tabs: [
                const Tab(text: 'Station & Process P&ID'),
                Tab(
                  child: Row(
                    children: [
                      const Text('Anti-Surge Control (ASC)'),
                      if (currentTrain.antiSurge.safetyStatus !=
                          AscSafetyStatus.safeZone) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB95F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'WARN',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Text('Vibration & Bearings (ISO)'),
                      if (currentTrain.overallVibrationZone ==
                              IsoVibrationZone.zoneC ||
                          currentTrain.overallVibrationZone ==
                              IsoVibrationZone.zoneD) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'ZONE C/D',
                            style: TextStyle(
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
                const Tab(text: 'Dry Gas Seal (DGS)'),
                const Tab(text: 'Booster Pumps & ESD'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Station Header Banner
          _buildStationHeaderBanner(currentStation),

          // Train Selection Strip
          _buildTrainSelectorStrip(currentStation),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProcessOverviewTab(currentStation, currentTrain),
                _buildAntiSurgeTab(currentTrain),
                _buildVibrationMatrixTab(currentTrain),
                _buildDryGasSealTab(currentTrain),
                _buildBoosterAndSafetyTab(currentStation, currentTrain),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER BANNER & SELECTION STRIPS
  // ============================================================================

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _isLiveStreaming
            ? const Color(0xFF4EDEA3).withOpacity(0.18)
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _isLiveStreaming
              ? const Color(0xFF4EDEA3).withOpacity(0.6)
              : AppTheme.border,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isLiveStreaming
                  ? const Color(0xFF4EDEA3)
                  : AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _isLiveStreaming ? 'LIVE' : 'PAUSED',
            style: TextStyle(
              color: _isLiveStreaming
                  ? const Color(0xFF4EDEA3)
                  : AppTheme.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationHeaderBanner(CompressorStationData station) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Station icon & info
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primaryLight.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.speed_rounded,
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
                            station.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              station.chainage,
                              style: const TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total Flow: ${(station.stationTotalFlowKgH / 1000.0).toStringAsFixed(1)} T/h • Power: ${station.stationTotalPowerMw.toStringAsFixed(2)} MW • ${station.runningTrainsCount}/${station.trains.length} Trains Online',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Station Compression Ratio Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'COMPRESSION RATIO',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${station.stationCompressionRatio.toStringAsFixed(2)}x',
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainSelectorStrip(CompressorStationData station) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppTheme.background,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: station.trains.length + 1, // +1 for Booster Pumps view
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index < station.trains.length) {
            final train = station.trains[index];
            final isSelected = index == _selectedTrainIndex;
            Color statusColor;
            String statusText;

            switch (train.status) {
              case TrainOperationalStatus.runningBaseLoad:
                statusColor = const Color(0xFF4EDEA3);
                statusText = 'RUN';
                break;
              case TrainOperationalStatus.runningModulating:
                statusColor = const Color(0xFF38BDF8);
                statusText = 'MOD';
                break;
              case TrainOperationalStatus.hotStandby:
                statusColor = const Color(0xFFFFB95F);
                statusText = 'STBY';
                break;
              case TrainOperationalStatus.coldStandby:
                statusColor = AppTheme.textMuted;
                statusText = 'OFF';
                break;
              case TrainOperationalStatus.inMaintenance:
                statusColor = const Color(0xFFF59E0B);
                statusText = 'MAINT';
                break;
              case TrainOperationalStatus.tripLockout:
                statusColor = const Color(0xFFEF4444);
                statusText = 'TRIP';
                break;
            }

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _selectedTrainIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withOpacity(0.25)
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryLight : AppTheme.border,
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
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      train.id,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Booster pumps item
            final isSelected = _selectedTrainIndex == station.trains.length;
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _selectedTrainIndex = station.trains.length;
                  _tabController.animateTo(4); // Switch to Booster pumps tab
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.secondary.withOpacity(0.2)
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppTheme.secondary : AppTheme.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.water_drop_rounded,
                        size: 13, color: AppTheme.secondary),
                    SizedBox(width: 6),
                    Text(
                      'Booster Pumps',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // ============================================================================
  // TAB 1: PROCESS & P&ID OVERVIEW
  // ============================================================================

  Widget _buildProcessOverviewTab(
      CompressorStationData station, CompressorTrainTelemetry train) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compressor Train Driver & Status Card
          _buildTrainHeaderCard(train),
          const SizedBox(height: 12),

          // Interactive Process P&ID Flow Diagram
          _buildInteractiveFlowDiagramCard(train),
          const SizedBox(height: 14),

          // Primary Process Telemetry Parameters Matrix
          const Text(
            'REAL-TIME THERMODYNAMIC & OPERATING PARAMETERS',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          _buildParametersGrid(train),
          const SizedBox(height: 14),

          // Dual Trend Chart: Suction vs Discharge Pressure
          _buildPressureTrendChartCard(train),
          const SizedBox(height: 14),

          // Shaft Speed & Mass Flow Trend Chart
          _buildFlowAndSpeedChartCard(train),
        ],
      ),
    );
  }

  Widget _buildTrainHeaderCard(CompressorTrainTelemetry train) {
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
                  color: AppTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.settings_input_component_rounded,
                    color: AppTheme.primaryLight, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Train ${train.id}: ${train.name}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4EDEA3).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: const Color(0xFF4EDEA3).withOpacity(0.4)),
                          ),
                          child: Text(
                            '${train.stageCount}-STAGE CENTRIFUGAL',
                            style: const TextStyle(
                              color: Color(0xFF4EDEA3),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Driver: ${train.driverDescription}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(
                'Running Hours',
                '${train.runningHours.toStringAsFixed(1)} hrs',
                Icons.history_rounded,
                AppTheme.textSecondary,
              ),
              _buildMiniMetric(
                'Rated Speed',
                '${train.ratedSpeedRpm.toInt()} RPM',
                Icons.speed_rounded,
                AppTheme.primaryLight,
              ),
              _buildMiniMetric(
                'Trip Speed (OST)',
                '${train.tripSpeedRpm.toInt()} RPM',
                Icons.warning_amber_rounded,
                const Color(0xFFEF4444),
              ),
              _buildMiniMetric(
                'Polytropic Eff',
                '${train.polytropicEfficiencyPct.toStringAsFixed(1)}%',
                Icons.energy_savings_leaf_rounded,
                const Color(0xFF4EDEA3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(
      String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveFlowDiagramCard(CompressorTrainTelemetry train) {
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
              Row(
                children: const [
                  Icon(Icons.schema_rounded,
                      size: 16, color: AppTheme.primaryLight),
                  SizedBox(width: 6),
                  Text(
                    'MULTI-STAGE COMPRESSION P&ID FLOW PATH',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  'ISO 13707 / API 617',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Flow Nodes Diagram
          LayoutBuilder(builder: (context, constraints) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Node 1: Suction Scrubber
                      _buildFlowDiagramNode(
                        title: 'Suction Scrubber',
                        subtitle: 'V-101 Knockout',
                        metric: '${train.suctionPressureBar.toStringAsFixed(1)} Bar',
                        metric2: '${train.suctionTemperatureC.toStringAsFixed(1)} °C',
                        color: const Color(0xFF38BDF8),
                        icon: Icons.filter_alt_rounded,
                      ),
                      _buildFlowArrow(),

                      // Node 2: Stage 1 Impeller
                      _buildFlowDiagramNode(
                        title: 'Stage 1 Impeller',
                        subtitle: 'Low Pressure Casing',
                        metric: '${train.interstagePressureBar.toStringAsFixed(1)} Bar',
                        metric2: 'Intercooled',
                        color: AppTheme.secondary,
                        icon: Icons.rotate_right_rounded,
                      ),
                      _buildFlowArrow(),

                      // Node 3: Stage 2 Impeller
                      _buildFlowDiagramNode(
                        title: 'Stage 2 Impeller',
                        subtitle: 'High Pressure Casing',
                        metric: '${train.dischargePressureBar.toStringAsFixed(1)} Bar',
                        metric2: '${train.dischargeTemperatureC.toStringAsFixed(1)} °C',
                        color: const Color(0xFFEF4444),
                        icon: Icons.speed_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Anti-Surge Recycle Loop Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: train.antiSurge.recycleValvePositionPct > 0
                            ? const Color(0xFFFFB95F)
                            : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.replay_rounded,
                              size: 14,
                              color: train.antiSurge.recycleValvePositionPct > 0
                                  ? const Color(0xFFFFB95F)
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Anti-Surge Recycle Loop (ASV-101):',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 10.5),
                            ),
                          ],
                        ),
                        Text(
                          train.antiSurge.recycleValvePositionPct == 0.0
                              ? 'CLOSED (0.0%) - FULL DISCHARGE TO GRID'
                              : 'MODULATING (${train.antiSurge.recycleValvePositionPct.toStringAsFixed(1)}% OPEN)',
                          style: TextStyle(
                            color: train.antiSurge.recycleValvePositionPct > 0
                                ? const Color(0xFFFFB95F)
                                : const Color(0xFF4EDEA3),
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFlowDiagramNode({
    required String title,
    required String subtitle,
    required String metric,
    required String metric2,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 8.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                metric,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              metric2,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 8.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.arrow_forward_ios_rounded,
          color: AppTheme.primaryLight.withOpacity(0.6), size: 12),
    );
  }

  Widget _buildParametersGrid(CompressorTrainTelemetry train) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.85,
      children: [
        _buildMetricCard(
          label: 'SUCTION PRESSURE & TEMP',
          primaryValue: '${train.suctionPressureBar.toStringAsFixed(2)} Bar',
          secondaryValue: '${train.suctionTemperatureC.toStringAsFixed(1)} °C',
          icon: Icons.compress_rounded,
          color: const Color(0xFF38BDF8),
          delta: '+0.12 Bar/hr',
        ),
        _buildMetricCard(
          label: 'DISCHARGE PRESSURE & TEMP',
          primaryValue: '${train.dischargePressureBar.toStringAsFixed(2)} Bar',
          secondaryValue: '${train.dischargeTemperatureC.toStringAsFixed(1)} °C',
          icon: Icons.rocket_launch_rounded,
          color: const Color(0xFFFFB95F),
          delta: 'CR: ${train.compressionRatio.toStringAsFixed(2)}x',
        ),
        _buildMetricCard(
          label: 'MASS FLOW RATE (Qm)',
          primaryValue:
              '${NumberFormat('#,###').format(train.massFlowRateKgH.toInt())} kg/h',
          secondaryValue:
              '${(train.massFlowRateKgH / 1000.0).toStringAsFixed(2)} T/h • ${train.volumetricSuctionFlowM3h.toStringAsFixed(0)} m³/h',
          icon: Icons.waves_rounded,
          color: const Color(0xFF4EDEA3),
          delta: 'Normal Steady',
        ),
        _buildMetricCard(
          label: 'SHAFT ROTATIONAL SPEED',
          primaryValue:
              '${NumberFormat('#,###').format(train.shaftSpeedRpm.toInt())} RPM',
          secondaryValue:
              '${train.speedPercentage.toStringAsFixed(1)}% of Rated (${train.ratedSpeedRpm.toInt()})',
          icon: Icons.rotate_right_rounded,
          color: AppTheme.primaryLight,
          delta: 'Critical: 6,800 RPM',
        ),
        _buildMetricCard(
          label: 'GAS TURBINE SHAFT POWER',
          primaryValue:
              '${NumberFormat('#,###').format(train.driverPowerKw.toInt())} kW',
          secondaryValue: 'EGT: ${train.turbineExhaustGasTempC.toStringAsFixed(1)} °C',
          icon: Icons.bolt_rounded,
          color: const Color(0xFFA78BFA),
          delta: '${(train.driverPowerKw / train.ratedPowerKw * 100).toStringAsFixed(1)}% Load',
        ),
        _buildMetricCard(
          label: 'POLYTROPIC HEAD & EFFICIENCY',
          primaryValue: '${train.polytropicHeadKjKg.toStringAsFixed(1)} kJ/kg',
          secondaryValue: 'Efficiency: ${train.polytropicEfficiencyPct.toStringAsFixed(1)}%',
          icon: Icons.insights_rounded,
          color: const Color(0xFF00E5FF),
          delta: 'ISO Class 1 Aero',
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String primaryValue,
    required String secondaryValue,
    required IconData icon,
    required Color color,
    required String delta,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primaryValue,
                style: TextStyle(
                  color: color,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                secondaryValue,
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
          Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                delta,
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPressureTrendChartCard(CompressorTrainTelemetry train) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'PRESSURE PROFILES (SUCTION VS DISCHARGE)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Live rolling trend • Sampling rate 1.5s',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendIndicator('Suction (Bar)', const Color(0xFF38BDF8)),
                  const SizedBox(width: 10),
                  _buildLegendIndicator('Discharge (Bar)', const Color(0xFFFFB95F)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.border.withOpacity(0.5),
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          val.toInt().toString(),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '-${(15 - val).toInt()}s',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 8.5,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.border, width: 0.8),
                ),
                minX: 0,
                maxX: 14,
                minY: 15,
                maxY: 95,
                lineBarsData: [
                  LineChartBarData(
                    spots: train.suctionPressureTrend,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: const Color(0xFF38BDF8),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: train.dischargePressureTrend,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: const Color(0xFFFFB95F),
                    barWidth: 2,
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

  Widget _buildFlowAndSpeedChartCard(CompressorTrainTelemetry train) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'MASS FLOW RATE & SHAFT SPEED DYNAMICS',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Flow in Metric Tons/hr (Left) vs Shaft RPM (Right)',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
              _buildLegendIndicator('Flow (T/h)', const Color(0xFF4EDEA3)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.border.withOpacity(0.5),
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          val.toStringAsFixed(0),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '-${(15 - val).toInt()}s',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 8.5,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.border, width: 0.8),
                ),
                minX: 0,
                maxX: 14,
                minY: 35,
                maxY: 65,
                lineBarsData: [
                  LineChartBarData(
                    spots: train.flowTrend,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFF4EDEA3),
                    barWidth: 2.2,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF4EDEA3).withOpacity(0.12),
                    ),
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

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 2: ANTI-SURGE CONTROL (ASC)
  // ============================================================================

  Widget _buildAntiSurgeTab(CompressorTrainTelemetry train) {
    final asc = train.antiSurge;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ASC Master Header Card
          _buildAscHeaderStatusCard(asc, train),
          const SizedBox(height: 14),

          // Dynamic Anti-Surge Operating Map (Surge Line, Control Line, Choke & Point)
          _buildSurgeMapCard(train),
          const SizedBox(height: 14),

          // Recycle Valve Position & Fast-Acting Response Card
          _buildRecycleValveCard(asc, train),
          const SizedBox(height: 14),

          // ASC Control Setpoints & Parameters Matrix
          _buildAscParametersMatrix(asc),
          const SizedBox(height: 14),

          // Fast-Acting Surge Test & Simulation Controls
          _buildAscSimulationCard(train),
        ],
      ),
    );
  }

  Widget _buildAscHeaderStatusCard(
      AntiSurgeControllerData asc, CompressorTrainTelemetry train) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: asc.statusColor.withOpacity(0.6), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: asc.statusColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.shield_rounded,
                        color: asc.statusColor, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ANTI-SURGE CONTROLLER (CCC SERIES 5)',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Status: ${asc.statusText}',
                            style: TextStyle(
                              color: asc.statusColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: asc.statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SLL Offset +${asc.surgeControlLineOffsetPct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: asc.statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              // Big Surge Margin Readout
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'SURGE MARGIN',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${asc.surgeMarginPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: asc.statusColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Surge Margin Progress Bar with Zone Markers
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Trip (0-4%)',
                      style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold)),
                  Text('Fast Recycle (4-10%)',
                      style: TextStyle(
                          color: Color(0xFFFF8A00),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold)),
                  Text('SCL (10-15%)',
                      style: TextStyle(
                          color: Color(0xFFFFB95F),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold)),
                  Text('Safe Operating (>15%)',
                      style: TextStyle(
                          color: Color(0xFF4EDEA3),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (asc.surgeMarginPct / 40.0).clamp(0.02, 1.0),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: asc.statusColor,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: asc.statusColor.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurgeMapCard(CompressorTrainTelemetry train) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'COMPRESSOR AERODYNAMIC OPERATING MAP',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pressure Ratio (Pd/Ps) vs Reduced Flow (Q/√Ts)',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  'Dist: +${train.antiSurge.distanceToSurgeLine.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF4EDEA3),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Custom Paint Anti-Surge Graphic
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF090F1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                painter: _SurgeMapPainter(
                  pressureRatio: train.compressionRatio,
                  surgeMarginPct: train.antiSurge.surgeMarginPct,
                  recycleValvePct: train.antiSurge.recycleValvePositionPct,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Surge Map Legend Strip
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendIndicator('Surge Limit Line (SLL)', const Color(0xFFEF4444)),
              _buildLegendIndicator('Surge Control Line (SCL)', const Color(0xFFFFB95F)),
              _buildLegendIndicator('Choke/Stonewall', const Color(0xFF38BDF8)),
              _buildLegendIndicator('Current Operating Point', const Color(0xFF4EDEA3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecycleValveCard(
      AntiSurgeControllerData asc, CompressorTrainTelemetry train) {
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
              Row(
                children: const [
                  Icon(Icons.tune_rounded,
                      size: 18, color: AppTheme.secondary),
                  SizedBox(width: 8),
                  Text(
                    'ANTI-SURGE RECYCLE VALVE (ASV-101)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Text(
                'Stroke Time: ${asc.valveStrokeTimeMs} ms',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Valve position gauge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Actuator Stroke Position:',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        Text(
                          '${asc.recycleValvePositionPct.toStringAsFixed(1)}% OPEN',
                          style: TextStyle(
                            color: asc.recycleValvePositionPct > 0
                                ? const Color(0xFFFFB95F)
                                : const Color(0xFF4EDEA3),
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
                        value: (asc.recycleValvePositionPct / 100.0).clamp(0.0, 1.0),
                        minHeight: 12,
                        backgroundColor: AppTheme.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          asc.recycleValvePositionPct > 0
                              ? const Color(0xFFFFB95F)
                              : const Color(0xFF4EDEA3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildValveDetailItem('Actuator Type', 'Voith Electro-Hydraulic'),
              _buildValveDetailItem('Fail-Safe Position', 'FAIL-OPEN (Air to Close)'),
              _buildValveDetailItem('Positioner Protocol', 'HART 7 / Foundation Fieldbus'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValveDetailItem(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5)),
        const SizedBox(height: 1),
        Text(val,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAscParametersMatrix(AntiSurgeControllerData asc) {
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
          const Text(
            'ANTI-SURGE ALGORITHM CONFIGURATION & GAINS',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: AppTheme.border.withOpacity(0.5)),
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(2),
            },
            children: [
              _buildTableRow('Surge Control Margin (Offset)', '+10.0%', 'Active PID modulation threshold', true),
              _buildTableRow('Derivative Fast Response Gain', 'Kd = 1.85', 'Triggers on rapid flow drop (dQ/dt)', false),
              _buildTableRow('Open-Loop Fast Step Opening', '40.0% Step', 'Instant pulse upon crossing SLL', false),
              _buildTableRow('Surge Cycle Counter', '0 Trips / 30d', 'Zero recorded aerodynamic stalls', false),
              _buildTableRow('Fall-back Transmitter Voting', '2oo3 Validated', 'Triple transmitter redundancy', false),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String col1, String col2, String col3, bool highlight) {
    return TableRow(
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.primary.withOpacity(0.08)
            : Colors.transparent,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(col1,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(col2,
              style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(col3,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 9.5)),
        ),
      ],
    );
  }

  Widget _buildAscSimulationCard(CompressorTrainTelemetry train) {
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
              Row(
                children: const [
                  Icon(Icons.tune_rounded, color: AppTheme.secondary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'ASC FAST RECYCLE VALVE STROKE TEST',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _ascTestValveModulating
                      ? const Color(0xFFFFB95F).withOpacity(0.2)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: _ascTestValveModulating
                          ? const Color(0xFFFFB95F)
                          : AppTheme.border),
                ),
                child: Text(
                  _ascTestValveModulating ? 'TEST ACTIVE' : 'TEST READY',
                  style: TextStyle(
                    color: _ascTestValveModulating
                        ? const Color(0xFFFFB95F)
                        : AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Allows field engineers to stroke ASV-101 in partial or full recycle mode to verify dynamic actuator response time and surge margin clearance.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(
                    _ascTestValveModulating
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    size: 16,
                  ),
                  label: Text(_ascTestValveModulating
                      ? 'End ASC Test Mode'
                      : 'Simulate 25% Partial Stroke'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ascTestValveModulating
                        ? const Color(0xFFEF4444)
                        : AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    setState(() {
                      if (_ascTestValveModulating) {
                        _ascTestValveModulating = false;
                        _manualValveTestOverridePct = 0.0;
                        train.antiSurge.recycleValvePositionPct = 0.0;
                      } else {
                        _ascTestValveModulating = true;
                        _manualValveTestOverridePct = 25.0;
                        train.antiSurge.recycleValvePositionPct = 25.0;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.bolt_rounded,
                    size: 16, color: Color(0xFFFFB95F)),
                label: const Text('Fast Trip Test'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFB95F),
                  side: const BorderSide(color: Color(0xFFFFB95F)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                onPressed: () {
                  _showAscTestDialog(train);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: VIBRATION & BEARING MATRIX (ISO 10816-3)
  // ============================================================================

  Widget _buildVibrationMatrixTab(CompressorTrainTelemetry train) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ISO 10816-3 Severity Zones Master Legend Card
          _buildIsoSeverityZonesLegend(),
          const SizedBox(height: 14),

          // Non-Contact Eddy Current Vibration Probes Matrix
          const Text(
            'BENTLY NEVADA 3500 EDDY CURRENT PROXIMITY PROBES',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          _buildVibrationProbesList(train),
          const SizedBox(height: 14),

          // Babbitt Metal Bearing Temperature Matrix
          const Text(
            'BABBITT METAL BEARING TEMPERATURES (Pt100 RTD)',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          _buildBabbittTempsGrid(train),
          const SizedBox(height: 14),

          // Dynamic Vibration Trend Chart
          _buildVibrationTrendCard(train),
        ],
      ),
    );
  }

  Widget _buildIsoSeverityZonesLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
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
            children: const [
              Text(
                'ISO 10816-3 & ISO 7919-3 VIBRATION SEVERITY CRITERIA',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Rigid Foundation Class II',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildIsoZoneBadge('Zone A', '< 25 μm', 'Good', const Color(0xFF4EDEA3)),
              const SizedBox(width: 6),
              _buildIsoZoneBadge('Zone B', '25-45 μm', 'Acceptable', const Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              _buildIsoZoneBadge('Zone C', '45-65 μm', 'Alert Limit', const Color(0xFFFFB95F)),
              const SizedBox(width: 6),
              _buildIsoZoneBadge('Zone D', '> 65 μm', 'Danger / Trip', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIsoZoneBadge(
      String zone, String range, String status, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(
              zone,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              range,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 7.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibrationProbesList(CompressorTrainTelemetry train) {
    return Column(
      children: train.vibrationProbes.map((probe) {
        final progressFactor =
            (probe.amplitudeUmPkPk / probe.tripThresholdUm).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(8),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: probe.zoneColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: probe.zoneColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          probe.tag,
                          style: TextStyle(
                            color: probe.zoneColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            probe.location,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            probe.axis,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            probe.amplitudeUmPkPk.toStringAsFixed(1),
                            style: TextStyle(
                              color: probe.zoneColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            'μm pk-pk',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        probe.zoneLabel,
                        style: TextStyle(
                          color: probe.zoneColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Vibration level progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progressFactor,
                  minHeight: 6,
                  backgroundColor: AppTheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(probe.zoneColor),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Baseline: ${probe.baselineUmPkPk} μm',
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 8.5)),
                  Text(
                    'Alarm: ${probe.warningThresholdUm.toInt()} μm • Trip: ${probe.tripThresholdUm.toInt()} μm',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 8.5),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBabbittTempsGrid(CompressorTrainTelemetry train) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.1,
      children: train.babbittTemps.map((sensor) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: sensor.statusColor.withOpacity(0.5),
              width: sensor.isAlarm || sensor.isTrip ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sensor.tag,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sensor.statusColor,
                    ),
                  ),
                ],
              ),
              Text(
                sensor.location,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${sensor.temperatureC.toStringAsFixed(1)} °C',
                    style: TextStyle(
                      color: sensor.statusColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Trip: ${sensor.tripThresholdC.toInt()}°C',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVibrationTrendCard(CompressorTrainTelemetry train) {
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
            children: const [
              Text(
                'BEARING VIBRATION DYNAMIC TREND (DE X-PROBE)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'ISO 10816 Limit: 45 μm',
                style: TextStyle(color: Color(0xFFFFB95F), fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.border.withOpacity(0.5),
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          val.toInt().toString(),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '-${(15 - val).toInt()}s',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 8.5,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.border, width: 0.8),
                ),
                minX: 0,
                maxX: 14,
                minY: 0,
                maxY: 60,
                lineBarsData: [
                  LineChartBarData(
                    spots: train.vibrationTrend,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: const Color(0xFF38BDF8),
                    barWidth: 2,
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

  // ============================================================================
  // TAB 4: DRY GAS SEAL (DGS) SYSTEM
  // ============================================================================

  Widget _buildDryGasSealTab(CompressorTrainTelemetry train) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DGS Overview Card
          _buildDgsHeaderCard(train),
          const SizedBox(height: 14),

          // Tandem Seal Cross-Section & Flow Diagram
          _buildDgsSchematicCard(),
          const SizedBox(height: 14),

          // Drive End (DE) Seal Console
          _buildDgsEndConsole('DRIVE END (DE) DRY GAS SEAL CONSOLE',
              train.dgsDriveEnd, const Color(0xFF38BDF8)),
          const SizedBox(height: 14),

          // Non-Drive End (NDE) Seal Console
          _buildDgsEndConsole('NON-DRIVE END (NDE) DRY GAS SEAL CONSOLE',
              train.dgsNonDriveEnd, const Color(0xFFFFB95F)),
          const SizedBox(height: 14),

          // Auxiliary Nitrogen Separation & Filtration Console
          _buildDgsAuxiliaryCard(train),
        ],
      ),
    );
  }

  Widget _buildDgsHeaderCard(CompressorTrainTelemetry train) {
    final de = train.dgsDriveEnd;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Color(0xFF00E5FF), size: 24),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'DRY GAS SEAL SYSTEM (API 692 / API 614)',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tandem Configuration with Intermediate Labyrinth',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4EDEA3).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: const Color(0xFF4EDEA3).withOpacity(0.4)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF4EDEA3), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'SEALS HEALTHY',
                      style: TextStyle(
                        color: Color(0xFF4EDEA3),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(
                'Buffer Gas DP',
                '+${de.bufferGasDifferentialPressureBar.toStringAsFixed(2)} Bar',
                Icons.swap_vert_rounded,
                const Color(0xFF00E5FF),
              ),
              _buildMiniMetric(
                'Primary Vent DE',
                '${de.primaryVentPressureBar.toStringAsFixed(2)} Bar',
                Icons.air_rounded,
                const Color(0xFF4EDEA3),
              ),
              _buildMiniMetric(
                'Secondary Vent DE',
                '${de.secondaryVentPressureBar.toStringAsFixed(2)} Bar',
                Icons.cloud_queue_rounded,
                AppTheme.textSecondary,
              ),
              _buildMiniMetric(
                'N2 Barrier Press',
                '${de.nitrogenBarrierGasPressureBar.toStringAsFixed(2)} Bar',
                Icons.security_rounded,
                AppTheme.primaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDgsSchematicCard() {
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
            children: const [
              Text(
                'TANDEM DRY GAS SEAL FLOW & PRESSURE BARRIER',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '3-5 μm Dynamic Lift Gap',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                _buildDgsFlowStage(
                  'Clean Buffer Gas',
                  'Injected @ +4.3 Bar DP',
                  'Prevents Process Hydrocarbon Ingress',
                  const Color(0xFF00E5FF),
                ),
                _buildFlowArrow(),
                _buildDgsFlowStage(
                  'Primary Face',
                  'Vent to Flare @ 0.28 Bar',
                  'Takes Full Pressure Breakdown (80 Bar)',
                  const Color(0xFF4EDEA3),
                ),
                _buildFlowArrow(),
                _buildDgsFlowStage(
                  'Secondary Face',
                  'Vent to Atmos @ 0.04 Bar',
                  'Safety Backup & N2 Separation Barrier',
                  const Color(0xFFFFB95F),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDgsFlowStage(
      String title, String val, String desc, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDgsEndConsole(
      String title, DryGasSealTelemetry seal, Color accentColor) {
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
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                seal.sealEnd,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.1,
            children: [
              _buildDgsParamBox(
                'BUFFER GAS DP (PDIFF)',
                '+${seal.bufferGasDifferentialPressureBar.toStringAsFixed(2)} Bar',
                'Min Limit: +1.5 Bar',
                const Color(0xFF00E5FF),
                true,
              ),
              _buildDgsParamBox(
                'PRIMARY VENT PRESSURE',
                '${seal.primaryVentPressureBar.toStringAsFixed(2)} Bar(g)',
                'Alarm: 1.0 Bar • Trip: 2.0 Bar',
                seal.isPrimaryVentNormal
                    ? const Color(0xFF4EDEA3)
                    : const Color(0xFFFFB95F),
                seal.isPrimaryVentNormal,
              ),
              _buildDgsParamBox(
                'PRIMARY VENT FLOW',
                '${seal.primaryLeakageFlowNm3h.toStringAsFixed(1)} Nm³/h',
                'Normal (< 15 Nm³/h)',
                const Color(0xFF38BDF8),
                true,
              ),
              _buildDgsParamBox(
                'SECONDARY VENT PRESSURE',
                '${seal.secondaryVentPressureBar.toStringAsFixed(3)} Bar(g)',
                'Normal Atmospheric Vent (< 0.1 Bar)',
                AppTheme.textSecondary,
                true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDgsParamBox(
      String title, String val, String sub, Color color, bool healthy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 8.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDgsAuxiliaryCard(CompressorTrainTelemetry train) {
    final de = train.dgsDriveEnd;

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
          const Text(
            'SEAL GAS CONDITIONING & NITROGEN BARRIER PANEL',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(
                'Coalescing Filter DP',
                '${de.coalescingFilterDpBar.toStringAsFixed(2)} Bar',
                Icons.filter_vintage_rounded,
                const Color(0xFF4EDEA3),
              ),
              _buildMiniMetric(
                'Supply Temperature',
                '${de.sealGasSupplyTempC.toStringAsFixed(1)} °C',
                Icons.thermostat_rounded,
                AppTheme.secondary,
              ),
              _buildMiniMetric(
                'N2 Separation Gas',
                '${de.nitrogenBarrierGasPressureBar.toStringAsFixed(2)} Bar',
                Icons.shield_outlined,
                AppTheme.primaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 5: BOOSTER PUMPS & SAFETY ESD
  // ============================================================================

  Widget _buildBoosterAndSafetyTab(
      CompressorStationData station, CompressorTrainTelemetry train) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Emergency Shutdown (ESD) Master Status
          _buildEsdStatusCard(station),
          const SizedBox(height: 14),

          // Associated Condensate Booster Pumps
          const Text(
            'ASSOCIATED CONDENSATE BOOSTER PUMP TRAINS (API 610 BB3)',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          _buildBoosterPumpsList(station),
          const SizedBox(height: 14),

          // Safety Interlocks & Cause & Effect Matrix
          _buildCauseAndEffectMatrix(),
        ],
      ),
    );
  }

  Widget _buildEsdStatusCard(CompressorStationData station) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: station.esdSystemArmed
              ? const Color(0xFF4EDEA3).withOpacity(0.5)
              : const Color(0xFFEF4444),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4EDEA3).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emergency_rounded,
                color: Color(0xFF4EDEA3), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      'SAFETY INSTRUMENTED SYSTEM (SIS / SIL-3)',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'ESD Interlocks Armed • Zero Trips Active',
                  style: TextStyle(
                    color: Color(0xFF4EDEA3),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'API 14C / OISD-118 compliant station safety shutdown loop',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onPressed: () {
              _showEsdInitiateDialog();
            },
            child: const Text(
              'TEST TRIP',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterPumpsList(CompressorStationData station) {
    return Column(
      children: station.boosterPumps.map((pump) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: pump.isRunning
                  ? AppTheme.primaryLight.withOpacity(0.5)
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: pump.isRunning
                              ? const Color(0xFF4EDEA3).withOpacity(0.18)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.water_drop_rounded,
                            color: pump.isRunning
                                ? const Color(0xFF4EDEA3)
                                : AppTheme.textMuted,
                            size: 16),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pump.tag}: ${pump.name}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'API 610 BB3 Between-Bearings Multi-Stage',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: pump.isRunning
                          ? const Color(0xFF4EDEA3).withOpacity(0.18)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: pump.isRunning
                            ? const Color(0xFF4EDEA3).withOpacity(0.4)
                            : AppTheme.border,
                      ),
                    ),
                    child: Text(
                      pump.isRunning ? 'RUNNING' : 'STANDBY',
                      style: TextStyle(
                        color: pump.isRunning
                            ? const Color(0xFF4EDEA3)
                            : AppTheme.textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniMetric(
                    'Suction / Disch',
                    '${pump.suctionPressureBar.toStringAsFixed(1)} / ${pump.dischargePressureBar.toStringAsFixed(1)} Bar',
                    Icons.compress_rounded,
                    const Color(0xFF38BDF8),
                  ),
                  _buildMiniMetric(
                    'Diff Head (m)',
                    '${pump.differentialHeadM.toStringAsFixed(1)} m',
                    Icons.height_rounded,
                    AppTheme.secondary,
                  ),
                  _buildMiniMetric(
                    'Flow Rate',
                    '${pump.flowRateM3h.toStringAsFixed(1)} m³/h',
                    Icons.waves_rounded,
                    const Color(0xFF4EDEA3),
                  ),
                  _buildMiniMetric(
                    'NPSH Margin',
                    '+${pump.npshMarginM.toStringAsFixed(1)} m',
                    Icons.security_rounded,
                    pump.isNpshSafe
                        ? const Color(0xFF4EDEA3)
                        : const Color(0xFFEF4444),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Motor: ${pump.motorCurrentAmps.toStringAsFixed(1)} A • Winding: ${pump.motorWindingTempC.toStringAsFixed(1)} °C',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 9.5),
                  ),
                  Text(
                    'Seal Plan 53B: ${pump.sealPlan53BPressureBar.toStringAsFixed(1)} Bar',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 9.5),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCauseAndEffectMatrix() {
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
                'CAUSE & EFFECT SAFETY INTERLOCK LOG',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '${_safetyInterlocks.length} Parameters Monitored',
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _safetyInterlocks.length,
            separatorBuilder: (_, _) => const Divider(
                color: AppTheme.border, height: 12),
            itemBuilder: (context, index) {
              final item = _safetyInterlocks[index];
              return Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.isTripped
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF4EDEA3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.parameterName,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                item.trainId,
                                style: const TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          item.causeDescription,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.currentReading.toStringAsFixed(1)} ${item.engineeringUnits}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Trip: ${item.tripSetpoint} ${item.engineeringUnits}',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // INTERACTIVE MODALS & ACTIONS
  // ============================================================================

  void _showAscTestDialog(CompressorTrainTelemetry train) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFFFB95F), size: 22),
                SizedBox(width: 8),
                Text('ASC Recycle Stroke Test',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Authorize anti-surge recycle valve fast opening test on Train ${train.id}. This will stroke ASV-101 to verify rapid response and surge margin stability.',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 14),
                const Text(
                  'SELECT TEST STROKE AMPLITUDE:',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildStrokeChoiceChip('15% Partial', 15.0, setDialogState),
                    const SizedBox(width: 8),
                    _buildStrokeChoiceChip('35% Modulate', 35.0, setDialogState),
                    const SizedBox(width: 8),
                    _buildStrokeChoiceChip('100% Quick Dump', 100.0, setDialogState),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB95F),
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    _ascTestValveModulating = true;
                    train.antiSurge.recycleValvePositionPct =
                        _manualValveTestOverridePct;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'ASC Test Initiated: ASV-101 opened to ${_manualValveTestOverridePct.toInt()}%'),
                      backgroundColor: const Color(0xFFFFB95F),
                    ),
                  );
                },
                child: const Text('Execute Stroke',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildStrokeChoiceChip(
      String label, double pct, StateSetter setDialogState) {
    final isSel = _manualValveTestOverridePct == pct;
    return InkWell(
      onTap: () {
        setDialogState(() {
          _manualValveTestOverridePct = pct;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSel
              ? const Color(0xFFFFB95F).withOpacity(0.25)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSel ? const Color(0xFFFFB95F) : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? const Color(0xFFFFB95F) : AppTheme.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showVibrationSpectrumDialog(CompressorTrainTelemetry train) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.graphic_eq_rounded,
                  color: AppTheme.primaryLight, size: 22),
              SizedBox(width: 8),
              Text('Bently Nevada Orbit & FFT Spectrum',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Harmonic Spectral Analysis for Train ${train.id} Journal DE Probes:',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11.5),
              ),
              const SizedBox(height: 12),
              _buildHarmonicRow(
                  '1X Synchronous (Unbalance)', '14.2 μm', 'Normal residual unbalance', const Color(0xFF4EDEA3)),
              const SizedBox(height: 6),
              _buildHarmonicRow(
                  '2X Harmonics (Misalignment)', '3.4 μm', 'Coupling alignment within API 670', const Color(0xFF38BDF8)),
              const SizedBox(height: 6),
              _buildHarmonicRow(
                  'Subsynchronous (0.43X Oil Whirl)', '1.1 μm', 'Zero fluid-film instability detected', const Color(0xFF4EDEA3)),
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
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF4EDEA3), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Shaft Centerline Orbit is elliptical and stable within clearance circle.',
                        style: TextStyle(
                            color: Color(0xFF4EDEA3),
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHarmonicRow(
      String title, String amplitude, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
              Text(desc,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 8.5)),
            ],
          ),
          Text(
            amplitude,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportLogModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Export Telemetry Dossier',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.file_download_outlined,
                      color: Color(0xFF4EDEA3)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate signed engineering log for Gas Compressor Station CS-Duliajan & CS-Moran containing real-time thermodynamic, ASC, vibration, and dry gas seal records.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_as_pdf_rounded,
                    color: Color(0xFFEF4444)),
                title: const Text('Export Official PDF Shift Log',
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13)),
                subtitle: const Text('Compliant with OISD & DGMS standards',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'PDF Dossier generated: CS_Compressor_Shift_Report.pdf'),
                      backgroundColor: Color(0xFF4EDEA3),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.table_chart_rounded,
                    color: Color(0xFF38BDF8)),
                title: const Text('Export High-Frequency CSV Stream',
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13)),
                subtitle: const Text('1.5s interval raw SCADA time-series',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'CSV Data Exported: CS_Telemetry_1500ms.csv'),
                      backgroundColor: AppTheme.primaryLight,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEsdInitiateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 24),
              SizedBox(width: 8),
              Text('Simulate Station Trip Test',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
            ],
          ),
          content: const Text(
            'This action tests the Emergency Shutdown (ESD) logic by simulating a PSHH trip signal. In real operations, this would close station suction/discharge ESDVs and open blowdown flare valves within 2.5 seconds.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'ESD Logic Test: PSHH trip simulated and verified successfully.'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              },
              child: const Text('Acknowledge Test',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _resetAllAlarms() {
    setState(() {
      _ascTestValveModulating = false;
      _manualValveTestOverridePct = 0.0;
      for (final s in _stations) {
        for (final t in s.trains) {
          t.antiSurge.recycleValvePositionPct = 0.0;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All compressor station alarms reset & acknowledged.'),
        backgroundColor: Color(0xFF4EDEA3),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER: DYNAMIC ANTI-SURGE OPERATING MAP
// ============================================================================

class _SurgeMapPainter extends CustomPainter {
  final double pressureRatio;
  final double surgeMarginPct;
  final double recycleValvePct;

  _SurgeMapPainter({
    required this.pressureRatio,
    required this.surgeMarginPct,
    required this.recycleValvePct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final padL = 36.0;
    final padB = 24.0;
    final padR = 12.0;
    final padT = 12.0;

    final chartW = w - padL - padR;
    final chartH = h - padT - padB;

    // Background Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF26396E).withOpacity(0.4)
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 5; i++) {
      final y = padT + (chartH / 5.0) * i;
      canvas.drawLine(Offset(padL, y), Offset(w - padR, y), gridPaint);
    }
    for (int i = 0; i <= 5; i++) {
      final x = padL + (chartW / 5.0) * i;
      canvas.drawLine(Offset(x, padT), Offset(x, h - padB), gridPaint);
    }

    // Coordinates mapping
    // X: Reduced flow Q (20 to 100)
    // Y: Pressure ratio PR (1.0 to 4.5)
    double mapX(double q) => padL + ((q - 20.0) / 80.0) * chartW;
    double mapY(double pr) => h - padB - ((pr - 1.0) / 3.5) * chartH;

    // 1. Surge Danger Shaded Area (Left of Surge Limit Line)
    final sllPath = Path();
    sllPath.moveTo(mapX(24.0), mapY(1.0));
    sllPath.cubicTo(
      mapX(28.0),
      mapY(2.0),
      mapX(36.0),
      mapY(3.2),
      mapX(48.0),
      mapY(4.4),
    );
    sllPath.lineTo(padL, mapY(4.4));
    sllPath.lineTo(padL, mapY(1.0));
    sllPath.close();

    final dangerPaint = Paint()
      ..color = const Color(0xFFEF4444).withOpacity(0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(sllPath, dangerPaint);

    // 2. Surge Limit Line (SLL) - Red Solid Line
    final sllStroke = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final sllCurve = Path();
    sllCurve.moveTo(mapX(24.0), mapY(1.0));
    sllCurve.cubicTo(
      mapX(28.0),
      mapY(2.0),
      mapX(36.0),
      mapY(3.2),
      mapX(48.0),
      mapY(4.4),
    );
    canvas.drawPath(sllCurve, sllStroke);

    // 3. Surge Control Line (SCL) - Amber Dashed Line (+10% margin)
    final sclStroke = Paint()
      ..color = const Color(0xFFFFB95F)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final sclCurve = Path();
    sclCurve.moveTo(mapX(28.0), mapY(1.0));
    sclCurve.cubicTo(
      mapX(33.0),
      mapY(2.0),
      mapX(42.0),
      mapY(3.2),
      mapX(55.0),
      mapY(4.4),
    );
    canvas.drawPath(sclCurve, sclStroke);

    // 4. Choke / Stonewall Line - Blue line
    final chokeStroke = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final chokeCurve = Path();
    chokeCurve.moveTo(mapX(82.0), mapY(1.0));
    chokeCurve.cubicTo(
      mapX(85.0),
      mapY(2.2),
      mapX(88.0),
      mapY(3.5),
      mapX(92.0),
      mapY(4.4),
    );
    canvas.drawPath(chokeCurve, chokeStroke);

    // 5. Speed Curves (N = 90%, 100%, 105%)
    final speedStroke = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final spd in [0.90, 1.0, 1.05]) {
      final spdPath = Path();
      final qStart = 30.0 + (spd - 0.90) * 12.0;
      final prTop = 2.8 * spd;
      spdPath.moveTo(mapX(qStart), mapY(prTop));
      spdPath.quadraticBezierTo(
        mapX(qStart + 28.0),
        mapY(prTop - 0.2),
        mapX(qStart + 52.0),
        mapY(1.2),
      );
      canvas.drawPath(spdPath, speedStroke);
    }

    // 6. Current Operating Point
    // Calculate live point coordinate based on pressureRatio and surge margin
    final opQ = 58.0 + (surgeMarginPct - 20.0) * 0.8;
    final opPr = pressureRatio.clamp(1.2, 4.2);
    final opCenter = Offset(mapX(opQ), mapY(opPr));

    // Radar pulsing ring
    final pulsePaint = Paint()
      ..color = const Color(0xFF4EDEA3).withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(opCenter, 14, pulsePaint);

    final outerRing = Paint()
      ..color = const Color(0xFF4EDEA3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(opCenter, 9, outerRing);

    final dotPaint = Paint()
      ..color = const Color(0xFF4EDEA3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(opCenter, 4.5, dotPaint);

    // Crosshairs
    final crossHairPaint = Paint()
      ..color = const Color(0xFF4EDEA3).withOpacity(0.4)
      ..strokeWidth = 0.8;
    canvas.drawLine(
        Offset(padL, opCenter.dy), Offset(w - padR, opCenter.dy), crossHairPaint);
    canvas.drawLine(
        Offset(opCenter.dx, padT), Offset(opCenter.dx, h - padB), crossHairPaint);

    // Text annotations: SLL, SCL
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = const TextSpan(
      text: 'SLL (SURGE)',
      style: TextStyle(
          color: Color(0xFFEF4444), fontSize: 8.5, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(mapX(38.0), mapY(3.5) - 14));

    textPainter.text = const TextSpan(
      text: 'SCL (+10%)',
      style: TextStyle(
          color: Color(0xFFFFB95F), fontSize: 8.5, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(mapX(48.0), mapY(3.5) - 14));

    textPainter.text = TextSpan(
      text: 'OP (${opPr.toStringAsFixed(2)}, Q=${opQ.toStringAsFixed(0)})',
      style: const TextStyle(
          color: Color(0xFF4EDEA3), fontSize: 8.5, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(opCenter.dx + 8, opCenter.dy - 12));
  }

  @override
  bool shouldRepaint(covariant _SurgeMapPainter oldDelegate) {
    return oldDelegate.pressureRatio != pressureRatio ||
        oldDelegate.surgeMarginPct != surgeMarginPct ||
        oldDelegate.recycleValvePct != recycleValvePct;
  }
}
