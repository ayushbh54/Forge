import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS
// ============================================================================

enum MeterStreamId {
  ufm01,
  ufm02,
}

enum StreamOperationalState {
  dutyActive,
  hotStandby,
  inProving,
  maintenanceLockout,
}

enum ProverPhase {
  standbyReady,
  diverterValveCycling,
  forwardPass,
  reversePass,
  stabilizing,
  completed,
}

enum TripartiteParty {
  transporter, // Oil India Limited (Operator / Dispatcher)
  shipper, // GAIL India Limited (Offtaker / Buyer)
  tpia, // Engineers India Limited (TPIA Independent Witness)
}

enum SignatureStatus {
  pending,
  signed,
  rejected,
}

/// Acoustic Path model per AGA Report No. 9
class AcousticPathData {
  final int pathIndex; // 1, 2, 3, 4
  final String chordDesignation; // e.g. "Chord 1 (Outer Top)"
  final double chordElevationFraction; // e.g. +0.809R
  final double pathLengthMm; // e.g. 742.3 mm
  final double inclinationAngleDeg; // e.g. 45.00 deg
  final String transducerPairTag; // e.g. X1A / X1B

  // Dynamic Acoustic Measurements
  double upstreamTransitTimeUs; // t1 (microsec)
  double downstreamTransitTimeUs; // t2 (microsec)
  double deltaTNs; // Δt (nanoseconds)
  double measuredSos; // m/s
  double theoreticalSos; // AGA-8 calculated SOS (m/s)
  double axialVelocity; // m/s
  double gainDb; // Receiver AGC Gain (dB)
  double snrDb; // Signal-to-Noise Ratio (dB)
  double pulseAcceptancePct; // Pulse acceptance (nominal > 99%)
  double pathTurbulenceIndex; // RMS velocity fluctuation %

  AcousticPathData({
    required this.pathIndex,
    required this.chordDesignation,
    required this.chordElevationFraction,
    required this.pathLengthMm,
    required this.inclinationAngleDeg,
    required this.transducerPairTag,
    required this.upstreamTransitTimeUs,
    required this.downstreamTransitTimeUs,
    required this.deltaTNs,
    required this.measuredSos,
    required this.theoreticalSos,
    required this.axialVelocity,
    required this.gainDb,
    required this.snrDb,
    required this.pulseAcceptancePct,
    required this.pathTurbulenceIndex,
  });

  /// SOS Deviation per AGA 9 clause 5.2.2: |c_i - c_theoretical| / c_theoretical * 100%
  double get sosDeviationPct =>
      ((measuredSos - theoreticalSos) / theoreticalSos) * 100.0;

  /// Tolerance check: AGA-9 limit is ±0.20% (approx ±0.82 m/s)
  bool get isSosValid => sosDeviationPct.abs() <= 0.20;

  /// Signal quality check: SNR >= 30 dB and Acceptance >= 99.0%
  bool get isSignalHealthy => snrDb >= 30.0 && pulseAcceptancePct >= 99.0;
}

/// Telemetry for an Ultrasonic Flow Metering Stream (UFM-01 or UFM-02)
class UfmStreamTelemetry {
  final MeterStreamId id;
  final String streamTag; // "UFM-01" or "UFM-02"
  final String skidLine; // "Stream A (24-inch Class 600#)"
  final String meterMakeModel; // "Daniel SeniorSonic 3804 4-Path"
  final String flowComputerTag; // "FC-0101 (Emerson S600+ Redundant)"
  final String serialNumber;

  StreamOperationalState state;
  bool inletValveOpen;
  bool outletValveOpen;
  bool proverBypassValveOpen;

  // Process Telemetry
  double linePressureBarg;
  double lineTemperatureC;
  double standardFlowRateMmscmd; // Million Metric Standard Cubic Meters/Day
  double standardFlowRateScmh; // Standard Cubic Meters/Hour
  double actualFlowRateM3h; // Actual cubic meters per hour
  double massFlowRateKgh; // kg/h
  double energyFlowRateGjh; // GJ/h
  double energyFlowRateMmbtuh; // MMBtu/h
  double differentialPressureMbar; // Skid DP (filter / conditioning)

  // Meter Factors & Metrology
  double activeMeterFactor; // Nominal 0.9995
  double nominalKFactor; // pulses/m3
  DateTime lastProvedDate;

  // 4 Chordal Acoustic Paths
  List<AcousticPathData> paths;

  // Rolling Telemetry History for Live Sparkline Charts
  List<FlSpot> flowHistory;
  List<FlSpot> sosHistory;

  UfmStreamTelemetry({
    required this.id,
    required this.streamTag,
    required this.skidLine,
    required this.meterMakeModel,
    required this.flowComputerTag,
    required this.serialNumber,
    required this.state,
    required this.inletValveOpen,
    required this.outletValveOpen,
    required this.proverBypassValveOpen,
    required this.linePressureBarg,
    required this.lineTemperatureC,
    required this.standardFlowRateMmscmd,
    required this.standardFlowRateScmh,
    required this.actualFlowRateM3h,
    required this.massFlowRateKgh,
    required this.energyFlowRateGjh,
    required this.energyFlowRateMmbtuh,
    required this.differentialPressureMbar,
    required this.activeMeterFactor,
    required this.nominalKFactor,
    required this.lastProvedDate,
    required this.paths,
    required this.flowHistory,
    required this.sosHistory,
  });

  /// Mean Speed of Sound across all active chords
  double get meanSos {
    if (paths.isEmpty) return 0.0;
    final sum = paths.fold<double>(0.0, (acc, p) => acc + p.measuredSos);
    return sum / paths.length;
  }

  /// Maximum SOS spread between highest and lowest chord
  double get sosSpread {
    if (paths.isEmpty) return 0.0;
    double minS = paths.first.measuredSos;
    double maxS = paths.first.measuredSos;
    for (final p in paths) {
      if (p.measuredSos < minS) minS = p.measuredSos;
      if (p.measuredSos > maxS) maxS = p.measuredSos;
    }
    return maxS - minS;
  }

  /// Profile Factor: Ratio of inner chord velocities (Ch 2 + Ch 3) to outer (Ch 1 + Ch 4)
  /// Nominal turbulent flow: 1.15 to 1.25
  double get profileFactor {
    if (paths.length < 4) return 1.18;
    final outer = paths[0].axialVelocity + paths[3].axialVelocity;
    final inner = paths[1].axialVelocity + paths[2].axialVelocity;
    if (outer <= 0.001) return 1.18;
    return inner / outer;
  }

  /// Symmetry Factor: Ratio of top chords (Ch 1 + Ch 2) to bottom (Ch 3 + Ch 4)
  /// Nominal: 1.000 ± 0.015
  double get symmetryFactor {
    if (paths.length < 4) return 1.00;
    final top = paths[0].axialVelocity + paths[1].axialVelocity;
    final bottom = paths[2].axialVelocity + paths[3].axialVelocity;
    if (bottom <= 0.001) return 1.00;
    return top / bottom;
  }

  /// Cross-Flow Factor: Indicator of swirl or cross-flow disturbance
  /// Nominal: 1.000 ± 0.020
  double get crossFlowFactor {
    if (paths.length < 4) return 1.00;
    final setA = paths[0].axialVelocity + paths[2].axialVelocity;
    final setB = paths[1].axialVelocity + paths[3].axialVelocity;
    if (setB <= 0.001) return 1.00;
    return setA / setB;
  }

  /// Swirl Angle (degrees): derived from chordal velocity imbalance
  double get swirlAngleDeg {
    final diff = (crossFlowFactor - 1.0).abs();
    return diff * 28.5; // Empirical correlation
  }

  /// Mean Skid Turbulence Index %
  double get averageTurbulenceIndex {
    if (paths.isEmpty) return 0.0;
    final sum = paths.fold<double>(0.0, (acc, p) => acc + p.pathTurbulenceIndex);
    return sum / paths.length;
  }

  /// AGA 9 Skid Compliance Status
  bool get isAga9Compliant {
    for (final p in paths) {
      if (!p.isSosValid || !p.isSignalHealthy) return false;
    }
    return sosSpread <= 0.50 && profileFactor >= 1.12 && profileFactor <= 1.28;
  }
}

/// Real-time Gas Chromatograph (GC-0101) Analysis
class GasChromatographData {
  final String tag;
  final DateTime lastAnalysisTime;
  final double methaneMolePct; // C1
  final double ethaneMolePct; // C2
  final double propaneMolePct; // C3
  final double iButaneMolePct; // iC4
  final double nButaneMolePct; // nC4
  final double iPentaneMolePct; // iC5
  final double nPentaneMolePct; // nC5
  final double hexanesPlusMolePct; // C6+
  final double carbonDioxideMolePct; // CO2
  final double nitrogenMolePct; // N2

  final double specificGravity; // Rel. density vs air
  final double grossHeatingValueMjSm3; // GHV (MJ/Sm³)
  final double wobbeIndex; // GHV / sqrt(SG)
  final double compressibilityZ; // AGA-8 Detail Characterization Z factor
  final double theoreticalSosAga8; // Calculated SOS (m/s)

  GasChromatographData({
    required this.tag,
    required this.lastAnalysisTime,
    required this.methaneMolePct,
    required this.ethaneMolePct,
    required this.propaneMolePct,
    required this.iButaneMolePct,
    required this.nButaneMolePct,
    required this.iPentaneMolePct,
    required this.nPentaneMolePct,
    required this.hexanesPlusMolePct,
    required this.carbonDioxideMolePct,
    required this.nitrogenMolePct,
    required this.specificGravity,
    required this.grossHeatingValueMjSm3,
    required this.wobbeIndex,
    required this.compressibilityZ,
    required this.theoreticalSosAga8,
  });
}

/// Single Proving Run per API MPMS Chapter 4.2 & Chapter 12.2
class ProvingRunRecord {
  final int runNumber; // 1 to 5
  final String passDirection; // "Bi-directional Combined (Fwd+Rev)"
  final double forwardTravelSec;
  final double reverseTravelSec;
  final double roundTripTimeSec;
  final int proverPulsesAcquired;
  final double proverDisplacedBaseVolumeM3; // Calibrated volume corrected
  final double meterIndicatedBaseVolumeM3;
  final double proverTempC;
  final double proverPressureBarg;
  final double ctsCorrection; // Prover steel temperature correction
  final double cpsCorrection; // Prover steel pressure correction
  final double calculatedMeterFactor;
  final bool isRepeatable;

  ProvingRunRecord({
    required this.runNumber,
    required this.passDirection,
    required this.forwardTravelSec,
    required this.reverseTravelSec,
    required this.roundTripTimeSec,
    required this.proverPulsesAcquired,
    required this.proverDisplacedBaseVolumeM3,
    required this.meterIndicatedBaseVolumeM3,
    required this.proverTempC,
    required this.proverPressureBarg,
    required this.ctsCorrection,
    required this.cpsCorrection,
    required this.calculatedMeterFactor,
    required this.isRepeatable,
  });
}

/// Bi-directional Pipe Prover Skid Loop
class PipeProverSkidData {
  final String proverTag; // "PRV-0101 Bi-Directional Pipe Prover"
  final String standardCode; // "API MPMS Chapter 4.2 & ISO 7278"
  final String calibratedVolumeCert; // "NABL/EIL-CAL-2026-0812"
  final double calibratedWaterDrawVolumeM3; // 14.2854 m³ at 15°C, 1.01325 bar
  final double proverPipeDiameterMm; // DN500 (20-inch ID)
  final String sphereDisplacerMaterial; // "Neoprene / Polyurethane Inflatable"

  ProverPhase currentPhase;
  int currentActiveRun; // 1 to 5
  double sequenceProgress; // 0.0 to 1.0
  String fourWayValvePosition; // "SEALED - FORWARD PASS"
  bool doubleBlockAndBleedHold; // True if valve seat DP verified
  double diverterSealDpBar; // 0.0 bar = perfect seal

  List<ProvingRunRecord> completedRuns;

  PipeProverSkidData({
    required this.proverTag,
    required this.standardCode,
    required this.calibratedVolumeCert,
    required this.calibratedWaterDrawVolumeM3,
    required this.proverPipeDiameterMm,
    required this.sphereDisplacerMaterial,
    required this.currentPhase,
    required this.currentActiveRun,
    required this.sequenceProgress,
    required this.fourWayValvePosition,
    required this.doubleBlockAndBleedHold,
    required this.diverterSealDpBar,
    required this.completedRuns,
  });

  /// Mean Meter Factor across completed runs
  double get meanMeterFactor {
    if (completedRuns.isEmpty) return 0.9995;
    final sum = completedRuns.fold<double>(0.0, (acc, r) => acc + r.calculatedMeterFactor);
    return sum / completedRuns.length;
  }

  /// Minimum Meter Factor
  double get minMeterFactor {
    if (completedRuns.isEmpty) return 0.9995;
    return completedRuns.map((r) => r.calculatedMeterFactor).reduce(math.min);
  }

  /// Maximum Meter Factor
  double get maxMeterFactor {
    if (completedRuns.isEmpty) return 0.9995;
    return completedRuns.map((r) => r.calculatedMeterFactor).reduce(math.max);
  }

  /// Repeatability Spread %: (MF_max - MF_min) / MF_min * 100%
  /// API MPMS tolerance: <= 0.0500% (5 parts in 10,000)
  double get repeatabilitySpreadPct {
    if (completedRuns.length < 2) return 0.0;
    return ((maxMeterFactor - minMeterFactor) / minMeterFactor) * 100.0;
  }

  /// API MPMS 5-run compliance check
  bool get isApiRepeatabilityCompliant {
    if (completedRuns.length < 5) return false;
    return repeatabilitySpreadPct <= 0.0500;
  }

  /// Standard Deviation of Meter Factor
  double get meterFactorStdDev {
    if (completedRuns.length < 2) return 0.0;
    final mean = meanMeterFactor;
    final variance = completedRuns.fold<double>(
            0.0, (acc, r) => acc + math.pow(r.calculatedMeterFactor - mean, 2)) /
        (completedRuns.length - 1);
    return math.sqrt(variance);
  }
}

/// Hourly Fiscal Batch Delivery Slice
class HourlyFiscalSlice {
  final int hourIndex; // 0 to 23
  final String intervalLabel; // "08:00 - 09:00"
  final double grossStandardVolumeSm3;
  final double energyGigajoules;
  final double energyMmbtu;
  final double averagePressureBarg;
  final double averageTemperatureC;
  final double averageSosMs;
  final double averageWobbeIndex;
  final bool isHourClosed;

  HourlyFiscalSlice({
    required this.hourIndex,
    required this.intervalLabel,
    required this.grossStandardVolumeSm3,
    required this.energyGigajoules,
    required this.energyMmbtu,
    required this.averagePressureBarg,
    required this.averageTemperatureC,
    required this.averageSosMs,
    required this.averageWobbeIndex,
    required this.isHourClosed,
  });
}

/// Tripartite Legal Signature Record
class TripartiteSignature {
  final TripartiteParty party;
  final String partyOrganization; // "Oil India Limited (Transporter)"
  final String officerName;
  final String designation;
  final String identityCredentialNumber; // Employee ID or NABL Registration
  SignatureStatus status;
  DateTime? timestamp;
  String? cryptographicSignatureHash;

  TripartiteSignature({
    required this.party,
    required this.partyOrganization,
    required this.officerName,
    required this.designation,
    required this.identityCredentialNumber,
    required this.status,
    this.timestamp,
    this.cryptographicSignatureHash,
  });
}

/// Daily Fiscal Custody Transfer Batch Ticket
class FiscalCustodyTransferTicket {
  final String ticketNumber; // "OIL-DUL-CT-20260930-001"
  final String contractReference; // "GTA-OIL-GAIL-DULIAJAN-REV04"
  final DateTime fiscalDate;
  final String dispatchLocation;
  final String receivingOfftaker;
  final String meteringSkidTag;
  final String activeStreamId;
  final String flowComputerAuditId;

  // Totalized Quantities
  final double totalStandardVolumeSm3; // Standard m3 (15°C, 1.01325 bar)
  final double totalMassMetricTonnes; // MT
  final double totalEnergyGigajoules; // GJ
  final double totalEnergyMmbtu; // MMBtu
  final double tariffRateInrPerMmbtu; // Contractual pricing
  final double grossInvoiceValuationInr; // Commercial value

  // Weighted Average Metrological Conditions
  final double weightedAvgPressureBarg;
  final double weightedAvgTemperatureC;
  final double weightedAvgCompressibilityZ;
  final double weightedAvgGhvMjSm3;
  final double weightedAvgWobbeIndex;
  final double appliedProverMeterFactor;
  final double avgAcousticSosDeviationPct;

  final String cryptographicSha256Hash;
  final List<TripartiteSignature> signatures;

  FiscalCustodyTransferTicket({
    required this.ticketNumber,
    required this.contractReference,
    required this.fiscalDate,
    required this.dispatchLocation,
    required this.receivingOfftaker,
    required this.meteringSkidTag,
    required this.activeStreamId,
    required this.flowComputerAuditId,
    required this.totalStandardVolumeSm3,
    required this.totalMassMetricTonnes,
    required this.totalEnergyGigajoules,
    required this.totalEnergyMmbtu,
    required this.tariffRateInrPerMmbtu,
    required this.grossInvoiceValuationInr,
    required this.weightedAvgPressureBarg,
    required this.weightedAvgTemperatureC,
    required this.weightedAvgCompressibilityZ,
    required this.weightedAvgGhvMjSm3,
    required this.weightedAvgWobbeIndex,
    required this.appliedProverMeterFactor,
    required this.avgAcousticSosDeviationPct,
    required this.cryptographicSha256Hash,
    required this.signatures,
  });

  bool get isFullyApproved {
    return signatures.every((s) => s.status == SignatureStatus.signed);
  }
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class CustodyMeteringScreen extends StatefulWidget {
  const CustodyMeteringScreen({super.key});

  @override
  State<CustodyMeteringScreen> createState() => _CustodyMeteringScreenState();
}

class _CustodyMeteringScreenState extends State<CustodyMeteringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _liveSimulationTimer;

  MeterStreamId _activeDutyStream = MeterStreamId.ufm01;
  int _chartTimeTicker = 20;

  // Core Skid Telemetry State
  late UfmStreamTelemetry _ufm01;
  late UfmStreamTelemetry _ufm02;
  late GasChromatographData _gasChromatograph;
  late PipeProverSkidData _proverSkid;
  late List<HourlyFiscalSlice> _hourlySlices;
  late FiscalCustodyTransferTicket _dailyBatchTicket;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeSkidData();
    _startLiveTelemetrySimulation();
  }

  @override
  void dispose() {
    _liveSimulationTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeSkidData() {
    // 1. Gas Chromatograph Online Data
    _gasChromatograph = GasChromatographData(
      tag: 'GC-0101 (ABB NGC 8206 Online C9+)',
      lastAnalysisTime: DateTime.now().subtract(const Duration(minutes: 4)),
      methaneMolePct: 91.45,
      ethaneMolePct: 4.24,
      propaneMolePct: 1.82,
      iButaneMolePct: 0.41,
      nButaneMolePct: 0.38,
      iPentaneMolePct: 0.12,
      nPentaneMolePct: 0.09,
      hexanesPlusMolePct: 0.05,
      carbonDioxideMolePct: 0.88,
      nitrogenMolePct: 0.56,
      specificGravity: 0.6138,
      grossHeatingValueMjSm3: 38.52,
      wobbeIndex: 49.16,
      compressibilityZ: 0.8842,
      theoreticalSosAga8: 412.45,
    );

    // 2. Ultrasonic Flow Meter Stream A (Duty UFM-01)
    _ufm01 = UfmStreamTelemetry(
      id: MeterStreamId.ufm01,
      streamTag: 'UFM-01',
      skidLine: 'Stream A (24" Class 600# Duty)',
      meterMakeModel: 'Daniel SeniorSonic 3804 (4-Path Chordal)',
      flowComputerTag: 'FC-0101 (Emerson S600+ Dual Core)',
      serialNumber: 'DS-3804-998241',
      state: StreamOperationalState.dutyActive,
      inletValveOpen: true,
      outletValveOpen: true,
      proverBypassValveOpen: false,
      linePressureBarg: 65.20,
      lineTemperatureC: 24.80,
      standardFlowRateMmscmd: 5.428,
      standardFlowRateScmh: 226166.7,
      actualFlowRateM3h: 3418.5,
      massFlowRateKgh: 158420.0,
      energyFlowRateGjh: 8712.0,
      energyFlowRateMmbtuh: 8257.4,
      differentialPressureMbar: 14.8,
      activeMeterFactor: 0.9994,
      nominalKFactor: 1000.0,
      lastProvedDate: DateTime.now().subtract(const Duration(days: 3)),
      paths: [
        AcousticPathData(
          pathIndex: 1,
          chordDesignation: 'Chord 1 (Outer Top +0.809R)',
          chordElevationFraction: 0.809,
          pathLengthMm: 724.2,
          inclinationAngleDeg: 45.0,
          transducerPairTag: 'X1A / X1B',
          upstreamTransitTimeUs: 1754.21,
          downstreamTransitTimeUs: 1748.12,
          deltaTNs: 6090.0,
          measuredSos: 412.38,
          theoreticalSos: 412.45,
          axialVelocity: 8.42,
          gainDb: 42.1,
          snrDb: 38.4,
          pulseAcceptancePct: 99.85,
          pathTurbulenceIndex: 3.12,
        ),
        AcousticPathData(
          pathIndex: 2,
          chordDesignation: 'Chord 2 (Inner Top +0.309R)',
          chordElevationFraction: 0.309,
          pathLengthMm: 812.5,
          inclinationAngleDeg: 45.0,
          transducerPairTag: 'X2A / X2B',
          upstreamTransitTimeUs: 1968.42,
          downstreamTransitTimeUs: 1960.98,
          deltaTNs: 7440.0,
          measuredSos: 412.48,
          theoreticalSos: 412.45,
          axialVelocity: 10.15,
          gainDb: 39.5,
          snrDb: 41.2,
          pulseAcceptancePct: 100.0,
          pathTurbulenceIndex: 2.68,
        ),
        AcousticPathData(
          pathIndex: 3,
          chordDesignation: 'Chord 3 (Inner Bottom -0.309R)',
          chordElevationFraction: -0.309,
          pathLengthMm: 812.6,
          inclinationAngleDeg: 45.0,
          transducerPairTag: 'X3A / X3B',
          upstreamTransitTimeUs: 1968.35,
          downstreamTransitTimeUs: 1961.02,
          deltaTNs: 7330.0,
          measuredSos: 412.51,
          theoreticalSos: 412.45,
          axialVelocity: 10.18,
          gainDb: 39.8,
          snrDb: 40.8,
          pulseAcceptancePct: 99.95,
          pathTurbulenceIndex: 2.74,
        ),
        AcousticPathData(
          pathIndex: 4,
          chordDesignation: 'Chord 4 (Outer Bottom -0.809R)',
          chordElevationFraction: -0.809,
          pathLengthMm: 724.3,
          inclinationAngleDeg: 45.0,
          transducerPairTag: 'X4A / X4B',
          upstreamTransitTimeUs: 1754.15,
          downstreamTransitTimeUs: 1748.18,
          deltaTNs: 5970.0,
          measuredSos: 412.40,
          theoreticalSos: 412.45,
          axialVelocity: 8.39,
          gainDb: 42.4,
          snrDb: 37.9,
          pulseAcceptancePct: 99.78,
          pathTurbulenceIndex: 3.25,
        ),
      ],
      flowHistory: List.generate(
        15,
        (i) => FlSpot(i.toDouble(), 5.35 + (math.sin(i * 0.4) * 0.12)),
      ),
      sosHistory: List.generate(
        15,
        (i) => FlSpot(i.toDouble(), 412.40 + (math.cos(i * 0.5) * 0.08)),
      ),
    );

    // 3. Ultrasonic Flow Meter Stream B (Standby UFM-02)
    _ufm02 = UfmStreamTelemetry(
      id: MeterStreamId.ufm02,
      streamTag: 'UFM-02',
      skidLine: 'Stream B (24" Class 600# Standby)',
      meterMakeModel: 'Daniel SeniorSonic 3804 (4-Path Chordal)',
      flowComputerTag: 'FC-0102 (Emerson S600+ Dual Core)',
      serialNumber: 'DS-3804-998242',
      state: StreamOperationalState.hotStandby,
      inletValveOpen: false,
      outletValveOpen: false,
      proverBypassValveOpen: false,
      linePressureBarg: 65.18,
      lineTemperatureC: 24.75,
      standardFlowRateMmscmd: 0.000,
      standardFlowRateScmh: 0.0,
      actualFlowRateM3h: 0.0,
      massFlowRateKgh: 0.0,
      energyFlowRateGjh: 0.0,
      energyFlowRateMmbtuh: 0.0,
      differentialPressureMbar: 0.0,
      activeMeterFactor: 0.9996,
      nominalKFactor: 1000.0,
      lastProvedDate: DateTime.now().subtract(const Duration(days: 7)),
      paths: [
        AcousticPathData(
          pathIndex: 1,
          chordDesignation: 'Chord 1 (Outer Top +0.809R)',
          chordElevationFraction: 0.809,
          pathLengthMm: 724.1,
          inclinationAngleDeg: 45.0,
          transducerPairTag: 'Y1A / Y1B',
          upstreamTransitTimeUs: 1754.00,
          downstreamTransitTimeUs: 1754.00,
          deltaTNs: 0.0,
          measuredSos: 412.42,
          theoreticalSos: 412.45,
          axialVelocity: 0.0,
          gainDb: 38.0,
          snrDb: 44.0,
          pulseAcceptancePct: 100.0,
          pathTurbulenceIndex: 0.0,
        ),
        AcousticPathData(
          pathIndex: 2,
          chordDesignation: 'Chord 2 (Inner Top +0.309R)',
          chordElevationFraction: 0.309,
          pathLengthMm: 812.4,
          inclinationAngleDeg: 45.0,
          transducerPairTag: 'Y2A / Y2B',
          upstreamTransitTimeUs: 1968.20,
          downstreamTransitTimeUs: 1968.20,
          deltaTNs: 0.0,
          measuredSos: 412.46,
          theoreticalSos: 412.45,
          axialVelocity: 0.0,
          gainDb: 37.2,
          snrDb: 45.1,
          pulseAcceptancePct: 100.0,
          pathTurbulenceIndex: 0.0,
        ),
        AcousticPathData(
          pathIndex: 3,
          chordDesignation: 'Chord 3 (Inner Bottom -0.309R)',
          chordElevationFraction: -0.309,
          pathLengthMm: 812.5,
          inclinationAngleDeg: 45.0,
          transducerPairTag: 'Y3A / Y3B',
          upstreamTransitTimeUs: 1968.18,
          downstreamTransitTimeUs: 1968.18,
          deltaTNs: 0.0,
          measuredSos: 412.44,
          theoreticalSos: 412.45,
          axialVelocity: 0.0,
          gainDb: 37.0,
          snrDb: 44.8,
          pulseAcceptancePct: 100.0,
          pathTurbulenceIndex: 0.0,
        ),
        AcousticPathData(
          pathIndex: 4,
          chordDesignation: 'Chord 4 (Outer Bottom -0.809R)',
          chordElevationFraction: -0.809,
          pathLengthMm: 724.2,
          inclinationAngleDeg: 45.0,
          transducerPairTag: 'Y4A / Y4B',
          upstreamTransitTimeUs: 1753.98,
          downstreamTransitTimeUs: 1753.98,
          deltaTNs: 0.0,
          measuredSos: 412.41,
          theoreticalSos: 412.45,
          axialVelocity: 0.0,
          gainDb: 38.5,
          snrDb: 43.5,
          pulseAcceptancePct: 100.0,
          pathTurbulenceIndex: 0.0,
        ),
      ],
      flowHistory: List.generate(15, (i) => FlSpot(i.toDouble(), 0.0)),
      sosHistory: List.generate(15, (i) => FlSpot(i.toDouble(), 412.43)),
    );

    // 4. Pipe Prover Skid Loop
    _proverSkid = PipeProverSkidData(
      proverTag: 'PRV-0101 Bi-Directional Pipe Prover',
      standardCode: 'API MPMS Ch. 4.2 / Ch. 12.2 / AGA-9',
      calibratedVolumeCert: 'NABL/EIL-CAL-2026-0812 (Water Draw)',
      calibratedWaterDrawVolumeM3: 14.2854,
      proverPipeDiameterMm: 508.0,
      sphereDisplacerMaterial: 'Neoprene Inflatable (2% Oversized)',
      currentPhase: ProverPhase.standbyReady,
      currentActiveRun: 5,
      sequenceProgress: 1.0,
      fourWayValvePosition: 'SEALED - FORWARD POSITION (DBB VERIFIED)',
      doubleBlockAndBleedHold: true,
      diverterSealDpBar: 0.0,
      completedRuns: [
        ProvingRunRecord(
          runNumber: 1,
          passDirection: 'Bi-directional (Fwd+Rev)',
          forwardTravelSec: 15.12,
          reverseTravelSec: 15.08,
          roundTripTimeSec: 30.20,
          proverPulsesAcquired: 14291,
          proverDisplacedBaseVolumeM3: 14.2892,
          meterIndicatedBaseVolumeM3: 14.2981,
          proverTempC: 24.78,
          proverPressureBarg: 65.18,
          ctsCorrection: 1.00023,
          cpsCorrection: 1.00084,
          calculatedMeterFactor: 0.99938,
          isRepeatable: true,
        ),
        ProvingRunRecord(
          runNumber: 2,
          passDirection: 'Bi-directional (Fwd+Rev)',
          forwardTravelSec: 15.10,
          reverseTravelSec: 15.09,
          roundTripTimeSec: 30.19,
          proverPulsesAcquired: 14293,
          proverDisplacedBaseVolumeM3: 14.2891,
          meterIndicatedBaseVolumeM3: 14.2978,
          proverTempC: 24.79,
          proverPressureBarg: 65.19,
          ctsCorrection: 1.00023,
          cpsCorrection: 1.00084,
          calculatedMeterFactor: 0.99939,
          isRepeatable: true,
        ),
        ProvingRunRecord(
          runNumber: 3,
          passDirection: 'Bi-directional (Fwd+Rev)',
          forwardTravelSec: 15.11,
          reverseTravelSec: 15.10,
          roundTripTimeSec: 30.21,
          proverPulsesAcquired: 14295,
          proverDisplacedBaseVolumeM3: 14.2893,
          meterIndicatedBaseVolumeM3: 14.2976,
          proverTempC: 24.80,
          proverPressureBarg: 65.20,
          ctsCorrection: 1.00024,
          cpsCorrection: 1.00084,
          calculatedMeterFactor: 0.99942,
          isRepeatable: true,
        ),
        ProvingRunRecord(
          runNumber: 4,
          passDirection: 'Bi-directional (Fwd+Rev)',
          forwardTravelSec: 15.09,
          reverseTravelSec: 15.08,
          roundTripTimeSec: 30.17,
          proverPulsesAcquired: 14294,
          proverDisplacedBaseVolumeM3: 14.2892,
          meterIndicatedBaseVolumeM3: 14.2980,
          proverTempC: 24.81,
          proverPressureBarg: 65.20,
          ctsCorrection: 1.00024,
          cpsCorrection: 1.00084,
          calculatedMeterFactor: 0.99939,
          isRepeatable: true,
        ),
        ProvingRunRecord(
          runNumber: 5,
          passDirection: 'Bi-directional (Fwd+Rev)',
          forwardTravelSec: 15.11,
          reverseTravelSec: 15.09,
          roundTripTimeSec: 30.20,
          proverPulsesAcquired: 14296,
          proverDisplacedBaseVolumeM3: 14.2894,
          meterIndicatedBaseVolumeM3: 14.2977,
          proverTempC: 24.80,
          proverPressureBarg: 65.21,
          ctsCorrection: 1.00024,
          cpsCorrection: 1.00084,
          calculatedMeterFactor: 0.99942,
          isRepeatable: true,
        ),
      ],
    );

    // 5. Hourly Fiscal Transfer Slices (Past 24 Hours)
    _hourlySlices = List.generate(24, (index) {
      final hour = index;
      final nextHour = (index + 1) % 24;
      final label = '${hour.toString().padLeft(2, '0')}:00 - ${nextHour.toString().padLeft(2, '0')}:00';
      final isClosed = index < 18; // 18 hours closed so far today
      final baseVol = 226000.0 + (math.sin(index * 0.3) * 4500.0);
      final gj = baseVol * 0.03852;
      return HourlyFiscalSlice(
        hourIndex: index,
        intervalLabel: label,
        grossStandardVolumeSm3: isClosed ? baseVol : (index == 18 ? baseVol * 0.65 : 0.0),
        energyGigajoules: isClosed ? gj : (index == 18 ? gj * 0.65 : 0.0),
        energyMmbtu: (isClosed ? gj : (index == 18 ? gj * 0.65 : 0.0)) * 0.9478,
        averagePressureBarg: 65.15 + (index * 0.02) % 0.25,
        averageTemperatureC: 24.5 + (math.sin(index * 0.2) * 1.2),
        averageSosMs: 412.44,
        averageWobbeIndex: 49.16,
        isHourClosed: isClosed,
      );
    });

    // 6. Daily Fiscal Custody Transfer Ticket
    final totalVol = _hourlySlices
        .where((s) => s.isHourClosed)
        .fold<double>(0.0, (acc, s) => acc + s.grossStandardVolumeSm3);
    final totalGj = totalVol * 0.03852;
    final totalMmbtu = totalGj * 0.9478;
    final totalMassMt = (totalVol * 0.6138 * 1.225) / 1000.0;
    const tariff = 824.50; // INR per MMBtu
    final valuation = totalMmbtu * tariff;

    final rawAuditString = 'OIL-DUL-CT-20260930-001|GTA-OIL-GAIL-DULIAJAN-REV04|'
        '$totalVol|$totalMmbtu|0.99940|412.45|2026-09-30';
    final shaDigest = sha256.convert(utf8.encode(rawAuditString)).toString();

    _dailyBatchTicket = FiscalCustodyTransferTicket(
      ticketNumber: 'OIL-DUL-CT-20260930-001',
      contractReference: 'GTA-OIL-GAIL-DULIAJAN-REV04',
      fiscalDate: DateTime.now(),
      dispatchLocation: 'Oil India Ltd Central Gas Terminal, Duliajan, Assam',
      receivingOfftaker: 'GAIL (India) Limited / BVFCL Namrup Complex',
      meteringSkidTag: 'M-01/02 Fiscal Ultrasonic Custody Skid',
      activeStreamId: 'UFM-01 (Stream A Active Duty)',
      flowComputerAuditId: 'S600-AUDIT-2026-0930-771',
      totalStandardVolumeSm3: totalVol,
      totalMassMetricTonnes: totalMassMt,
      totalEnergyGigajoules: totalGj,
      totalEnergyMmbtu: totalMmbtu,
      tariffRateInrPerMmbtu: tariff,
      grossInvoiceValuationInr: valuation,
      weightedAvgPressureBarg: 65.22,
      weightedAvgTemperatureC: 24.81,
      weightedAvgCompressibilityZ: 0.8842,
      weightedAvgGhvMjSm3: 38.52,
      weightedAvgWobbeIndex: 49.16,
      appliedProverMeterFactor: 0.99940,
      avgAcousticSosDeviationPct: 0.015,
      cryptographicSha256Hash: shaDigest,
      signatures: [
        TripartiteSignature(
          party: TripartiteParty.transporter,
          partyOrganization: 'Oil India Limited (Transporter / Operator)',
          officerName: 'Er. Bhaskar Jyoti Phukan',
          designation: 'Chief Engineer (Gas Metering & Instrumentation)',
          identityCredentialNumber: 'OIL-EMP-40819',
          status: SignatureStatus.signed,
          timestamp: DateTime.now().subtract(const Duration(minutes: 54)),
          cryptographicSignatureHash: '8f921ab04e76d91c7a82b43d2c1e95e8',
        ),
        TripartiteSignature(
          party: TripartiteParty.shipper,
          partyOrganization: 'GAIL (India) Limited (Shipper / Offtaker)',
          officerName: 'Er. Sunita Barman',
          designation: 'General Manager (Gas Dispatch & Offtake QA)',
          identityCredentialNumber: 'GAIL-ND-882194',
          status: SignatureStatus.signed,
          timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
          cryptographicSignatureHash: '3c19e5a7b21908d4f014e27b89d6e4a2',
        ),
        TripartiteSignature(
          party: TripartiteParty.tpia,
          partyOrganization: 'Engineers India Limited (TPIA Independent Witness)',
          officerName: 'Er. Rajeshwar Hazarika',
          designation: 'Lead Fiscal Metrology Assessor',
          identityCredentialNumber: 'EIL-NABL-AUD-2026',
          status: SignatureStatus.pending,
          timestamp: null,
          cryptographicSignatureHash: null,
        ),
      ],
    );
  }

  void _startLiveTelemetrySimulation() {
    _liveSimulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        _chartTimeTicker++;
        final rand = math.Random();
        final jitterP = (rand.nextDouble() - 0.5) * 0.06;
        final jitterT = (rand.nextDouble() - 0.5) * 0.04;
        final jitterQ = (rand.nextDouble() - 0.5) * 0.025;

        if (_activeDutyStream == MeterStreamId.ufm01) {
          _ufm01.linePressureBarg = 65.20 + jitterP;
          _ufm01.lineTemperatureC = 24.80 + jitterT;
          _ufm01.standardFlowRateMmscmd = math.max(0.0, 5.428 + jitterQ);
          _ufm01.standardFlowRateScmh = _ufm01.standardFlowRateMmscmd * 1000000.0 / 24.0;
          _ufm01.actualFlowRateM3h = 3418.5 + (jitterQ * 600.0);
          _ufm01.massFlowRateKgh = _ufm01.standardFlowRateScmh * 0.7004;
          _ufm01.energyFlowRateGjh = _ufm01.standardFlowRateScmh * 0.03852;
          _ufm01.energyFlowRateMmbtuh = _ufm01.energyFlowRateGjh * 0.9478;

          // Jitter individual path measurements
          for (final p in _ufm01.paths) {
            p.measuredSos = 412.45 + ((rand.nextDouble() - 0.5) * 0.16);
            p.axialVelocity = math.max(0.0, p.axialVelocity + ((rand.nextDouble() - 0.5) * 0.04));
            p.gainDb = 40.0 + ((rand.nextDouble() - 0.5) * 1.5);
            p.snrDb = 39.5 + ((rand.nextDouble() - 0.5) * 1.8);
          }

          // Update sparklines
          _ufm01.flowHistory.add(FlSpot(_chartTimeTicker.toDouble(), _ufm01.standardFlowRateMmscmd));
          if (_ufm01.flowHistory.length > 20) _ufm01.flowHistory.removeAt(0);

          _ufm01.sosHistory.add(FlSpot(_chartTimeTicker.toDouble(), _ufm01.meanSos));
          if (_ufm01.sosHistory.length > 20) _ufm01.sosHistory.removeAt(0);
        } else {
          // UFM-02 is Duty
          _ufm02.linePressureBarg = 65.20 + jitterP;
          _ufm02.lineTemperatureC = 24.80 + jitterT;
          _ufm02.standardFlowRateMmscmd = math.max(0.0, 5.428 + jitterQ);
          _ufm02.standardFlowRateScmh = _ufm02.standardFlowRateMmscmd * 1000000.0 / 24.0;
          _ufm02.actualFlowRateM3h = 3418.5 + (jitterQ * 600.0);
          _ufm02.massFlowRateKgh = _ufm02.standardFlowRateScmh * 0.7004;
          _ufm02.energyFlowRateGjh = _ufm02.standardFlowRateScmh * 0.03852;
          _ufm02.energyFlowRateMmbtuh = _ufm02.energyFlowRateGjh * 0.9478;

          for (final p in _ufm02.paths) {
            p.measuredSos = 412.45 + ((rand.nextDouble() - 0.5) * 0.16);
            p.axialVelocity = math.max(0.0, p.axialVelocity + ((rand.nextDouble() - 0.5) * 0.04));
          }

          _ufm02.flowHistory.add(FlSpot(_chartTimeTicker.toDouble(), _ufm02.standardFlowRateMmscmd));
          if (_ufm02.flowHistory.length > 20) _ufm02.flowHistory.removeAt(0);

          _ufm02.sosHistory.add(FlSpot(_chartTimeTicker.toDouble(), _ufm02.meanSos));
          if (_ufm02.sosHistory.length > 20) _ufm02.sosHistory.removeAt(0);
        }
      });
    });
  }

  void _showStreamSwitchDialog() {
    final targetStream = _activeDutyStream == MeterStreamId.ufm01 ? 'UFM-02 (Stream B)' : 'UFM-01 (Stream A)';
    final sourceStream = _activeDutyStream == MeterStreamId.ufm01 ? 'UFM-01 (Stream A)' : 'UFM-02 (Stream B)';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: const [
            Icon(Icons.swap_horiz_rounded, color: AppTheme.secondary),
            SizedBox(width: 8),
            Text(
              'Confirm Duty Stream Switch',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Switch fiscal duty flow from $sourceStream to $targetStream?',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Interlock Sequence Checks:',
                    style: TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text('• Motorized Block Valves XV-0101 / XV-0201 ramp rate controlled.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  Text('• S600+ Flow Computer accumulator hot handover.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  Text('• Zero custody flow interruption guaranteed.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeStreamSwitch();
            },
            child: const Text('Execute Switchover', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _executeStreamSwitch() {
    setState(() {
      if (_activeDutyStream == MeterStreamId.ufm01) {
        _activeDutyStream = MeterStreamId.ufm02;
        _ufm01.state = StreamOperationalState.hotStandby;
        _ufm01.inletValveOpen = false;
        _ufm01.outletValveOpen = false;
        _ufm01.standardFlowRateMmscmd = 0.0;

        _ufm02.state = StreamOperationalState.dutyActive;
        _ufm02.inletValveOpen = true;
        _ufm02.outletValveOpen = true;
        _ufm02.standardFlowRateMmscmd = 5.428;
      } else {
        _activeDutyStream = MeterStreamId.ufm01;
        _ufm02.state = StreamOperationalState.hotStandby;
        _ufm02.inletValveOpen = false;
        _ufm02.outletValveOpen = false;
        _ufm02.standardFlowRateMmscmd = 0.0;

        _ufm01.state = StreamOperationalState.dutyActive;
        _ufm01.inletValveOpen = true;
        _ufm01.outletValveOpen = true;
        _ufm01.standardFlowRateMmscmd = 5.428;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceCard,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Duty switched to ${_activeDutyStream == MeterStreamId.ufm01 ? "UFM-01" : "UFM-02"}. S600+ accumulators synchronized.',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _startInteractiveProvingSequence() {
    if (_proverSkid.currentPhase != ProverPhase.standbyReady &&
        _proverSkid.currentPhase != ProverPhase.completed) {
      return;
    }

    setState(() {
      _proverSkid.currentPhase = ProverPhase.diverterValveCycling;
      _proverSkid.sequenceProgress = 0.1;
      _proverSkid.fourWayValvePosition = 'CYCLING 4-WAY DIVERTER VALVE...';
      _proverSkid.completedRuns.clear();
      _proverSkid.currentActiveRun = 1;
    });

    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _proverSkid.currentPhase = ProverPhase.forwardPass;
        _proverSkid.sequenceProgress = 0.25;
        _proverSkid.fourWayValvePosition = 'SEALED - FORWARD PASS (DBB VERIFIED)';
      });

      Timer(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _proverSkid.currentPhase = ProverPhase.reversePass;
          _proverSkid.sequenceProgress = 0.50;
          _proverSkid.fourWayValvePosition = 'SEALED - REVERSE PASS (DBB VERIFIED)';
        });

        Timer(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          _completeProvingSimulation();
        });
      });
    });
  }

  void _completeProvingSimulation() {
    final rand = math.Random();
    final newRuns = <ProvingRunRecord>[];
    const baseMf = 0.99940;

    for (int i = 1; i <= 5; i++) {
      // Small jitter strictly within 0.035% spread (well under 0.05% API MPMS limit)
      final jitter = ((rand.nextDouble() - 0.5) * 0.00025);
      final runMf = baseMf + jitter;
      newRuns.add(
        ProvingRunRecord(
          runNumber: i,
          passDirection: 'Bi-directional (Fwd+Rev)',
          forwardTravelSec: 15.10 + ((rand.nextDouble() - 0.5) * 0.06),
          reverseTravelSec: 15.09 + ((rand.nextDouble() - 0.5) * 0.06),
          roundTripTimeSec: 30.19,
          proverPulsesAcquired: 14290 + rand.nextInt(8),
          proverDisplacedBaseVolumeM3: 14.2892,
          meterIndicatedBaseVolumeM3: 14.2892 / runMf,
          proverTempC: 24.80 + ((rand.nextDouble() - 0.5) * 0.04),
          proverPressureBarg: 65.20 + ((rand.nextDouble() - 0.5) * 0.05),
          ctsCorrection: 1.00024,
          cpsCorrection: 1.00084,
          calculatedMeterFactor: double.parse(runMf.toStringAsFixed(5)),
          isRepeatable: true,
        ),
      );
    }

    setState(() {
      _proverSkid.completedRuns = newRuns;
      _proverSkid.currentPhase = ProverPhase.completed;
      _proverSkid.sequenceProgress = 1.0;
      _proverSkid.fourWayValvePosition = 'SEALED - FORWARD POSITION (HOLD)';
      _proverSkid.currentActiveRun = 5;

      // Update active stream MF
      if (_activeDutyStream == MeterStreamId.ufm01) {
        _ufm01.activeMeterFactor = _proverSkid.meanMeterFactor;
        _ufm01.lastProvedDate = DateTime.now();
      } else {
        _ufm02.activeMeterFactor = _proverSkid.meanMeterFactor;
        _ufm02.lastProvedDate = DateTime.now();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceCard,
        content: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 20),
            const SizedBox(width: 8),
            Text(
              '5-Run Proving Completed! Repeatability: ${_proverSkid.repeatabilitySpreadPct.toStringAsFixed(4)}% (PASSED API MPMS < 0.05%)',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignatureDialog(TripartiteSignature signature) {
    if (signature.status == SignatureStatus.signed) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: const [
              Icon(Icons.verified_user_rounded, color: AppTheme.tertiary),
              SizedBox(width: 8),
              Text(
                'Signature Verified',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(signature.partyOrganization,
                  style: const TextStyle(
                      color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Text('Signatory: ${signature.officerName}',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
              Text('Designation: ${signature.designation}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text('ID / Credential: ${signature.identityCredentialNumber}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const Divider(color: AppTheme.border, height: 20),
              const Text('Cryptographic Fingerprint:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              SelectableText(
                signature.cryptographicSignatureHash ?? 'None',
                style: const TextStyle(
                  color: AppTheme.tertiary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Signed at: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(signature.timestamp ?? DateTime.now())} IST',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final pinController = TextEditingController(text: '8841');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.draw_rounded, color: AppTheme.primaryLight),
            const SizedBox(width: 8),
            Text(
              'Sign Fiscal Batch Ticket',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(signature.partyOrganization,
                style: const TextStyle(
                    color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Signatory: ${signature.officerName} (${signature.designation})',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            const Text(
              'Enter Fiscal Authorization PIN or Biometric Key to execute tripartite sign-off:',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary, letterSpacing: 4),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock_rounded, color: AppTheme.primary),
                labelText: 'Fiscal Security PIN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tertiary,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeSignTicket(signature);
            },
            child: const Text('Authorize & Sign', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _executeSignTicket(TripartiteSignature signature) {
    setState(() {
      signature.status = SignatureStatus.signed;
      signature.timestamp = DateTime.now();
      final hashInput = '${signature.officerName}|${signature.partyOrganization}|${signature.timestamp}';
      signature.cryptographicSignatureHash = sha256.convert(utf8.encode(hashInput)).toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceCard,
        content: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Ticket signed by ${signature.officerName} (${signature.partyOrganization}).',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketDossierDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FISCAL CUSTODY TRANSFER TICKET',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _dailyBatchTicket.ticketNumber,
                        style: const TextStyle(color: AppTheme.primaryLight, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _dailyBatchTicket.isFullyApproved
                          ? AppTheme.tertiary.withValues(alpha: 0.15)
                          : AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _dailyBatchTicket.isFullyApproved
                            ? AppTheme.tertiary
                            : AppTheme.secondary,
                      ),
                    ),
                    child: Text(
                      _dailyBatchTicket.isFullyApproved ? 'OFFICIALLY SEALED' : 'TRIPARTITE IN PROGRESS',
                      style: TextStyle(
                        color: _dailyBatchTicket.isFullyApproved
                            ? AppTheme.tertiary
                            : AppTheme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.border, height: 24),
              _buildDossierRow('Contract Reference', _dailyBatchTicket.contractReference),
              _buildDossierRow('Dispatch Facility', _dailyBatchTicket.dispatchLocation),
              _buildDossierRow('Receiving Terminal', _dailyBatchTicket.receivingOfftaker),
              _buildDossierRow('Fiscal Skid Line', _dailyBatchTicket.meteringSkidTag),
              _buildDossierRow('Active Duty Stream', _dailyBatchTicket.activeStreamId),
              _buildDossierRow('Flow Computer Audit', _dailyBatchTicket.flowComputerAuditId),
              const Divider(color: AppTheme.border, height: 24),
              const Text(
                'Totalized Quantities & Billing Parameters',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildDossierRow(
                'Total Standard Volume (Sm³)',
                NumberFormat('#,##0.0').format(_dailyBatchTicket.totalStandardVolumeSm3),
              ),
              _buildDossierRow(
                'Total Energy (Gigajoules)',
                NumberFormat('#,##0.0').format(_dailyBatchTicket.totalEnergyGigajoules),
              ),
              _buildDossierRow(
                'Total Energy (MMBtu)',
                NumberFormat('#,##0.0').format(_dailyBatchTicket.totalEnergyMmbtu),
              ),
              _buildDossierRow(
                'Total Mass Dispatched',
                '${NumberFormat('#,##0.0').format(_dailyBatchTicket.totalMassMetricTonnes)} Metric Tonnes',
              ),
              _buildDossierRow(
                'Weighted Avg Gross Heating Value',
                '${_dailyBatchTicket.weightedAvgGhvMjSm3.toStringAsFixed(2)} MJ/Sm³',
              ),
              _buildDossierRow(
                'Weighted Avg Compressibility (Z)',
                _dailyBatchTicket.weightedAvgCompressibilityZ.toStringAsFixed(4),
              ),
              _buildDossierRow(
                'Applied Pipe Prover Meter Factor',
                _dailyBatchTicket.appliedProverMeterFactor.toStringAsFixed(5),
              ),
              _buildDossierRow(
                'Contract Tariff Rate',
                '₹${_dailyBatchTicket.tariffRateInrPerMmbtu.toStringAsFixed(2)} / MMBtu',
              ),
              _buildDossierRow(
                'Gross Consignment Valuation',
                '₹${NumberFormat('#,##0.00').format(_dailyBatchTicket.grossInvoiceValuationInr)}',
                isHighlight: true,
              ),
              const Divider(color: AppTheme.border, height: 24),
              const Text(
                'Tripartite Legal Signatures',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (final s in _dailyBatchTicket.signatures) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: s.status == SignatureStatus.signed
                          ? AppTheme.tertiary.withValues(alpha: 0.3)
                          : AppTheme.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.partyOrganization,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          Text('${s.officerName} (${s.designation})',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          if (s.timestamp != null)
                            Text('Signed: ${DateFormat('yyyy-MM-dd HH:mm').format(s.timestamp!)} IST',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                      Icon(
                        s.status == SignatureStatus.signed
                            ? Icons.verified_rounded
                            : Icons.hourglass_top_rounded,
                        color: s.status == SignatureStatus.signed
                            ? AppTheme.tertiary
                            : AppTheme.secondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Cryptographic Audit Hash (SHA-256):',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              SelectableText(
                _dailyBatchTicket.cryptographicSha256Hash,
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Share CSV / EDI'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fiscal EDI 867 Custody File exported to terminal gateway.'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Export Official PDF'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Official Fiscal Custody Ticket PDF generated.'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDossierRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppTheme.tertiary : AppTheme.textPrimary,
              fontSize: isHighlight ? 13 : 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final activeTelemetry =
        _activeDutyStream == MeterStreamId.ufm01 ? _ufm01 : _ufm02;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Custody Transfer Metering',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'AGA Report No. 9 / API MPMS Ch. 14 / Pipe Prover Skid',
              style: TextStyle(color: AppTheme.primaryLight, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export Batch Dossier',
            icon: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryLight),
            onPressed: _showTicketDossierDialog,
          ),
          IconButton(
            tooltip: 'Duty Stream Switch',
            icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.secondary),
            onPressed: _showStreamSwitchDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.speed_rounded, size: 18), text: 'Skid Live'),
                Tab(icon: Icon(Icons.graphic_eq_rounded, size: 18), text: 'AGA-9 SOS & Chords'),
                Tab(icon: Icon(Icons.repeat_rounded, size: 18), text: 'Pipe Prover Loop'),
                Tab(icon: Icon(Icons.verified_rounded, size: 18), text: 'Batch Tickets & Sign'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTopIndustrialTelemetryBanner(activeTelemetry),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSkidLiveTab(activeTelemetry),
                _buildAga9AcousticsTab(activeTelemetry),
                _buildPipeProverTab(),
                _buildBatchTicketsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TOP INDUSTRIAL TELEMETRY BANNER
  // ============================================================================

  Widget _buildTopIndustrialTelemetryBanner(UfmStreamTelemetry active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Stream Badge
          InkWell(
            onTap: _showStreamSwitchDialog,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary),
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
                  Text(
                    '${active.streamTag} (DUTY)',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary, size: 16),
                ],
              ),
            ),
          ),
          // Flow Rate
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${active.standardFlowRateMmscmd.toStringAsFixed(3)} MMSCMD',
                style: const TextStyle(
                  color: AppTheme.tertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                '${NumberFormat('#,##0').format(active.standardFlowRateScmh)} SCMH',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          // Pressure & Temp
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${active.linePressureBarg.toStringAsFixed(2)} barg',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                '${active.lineTemperatureC.toStringAsFixed(1)} °C',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          // MF Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('METER FACTOR', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                Text(
                  active.activeMeterFactor.toStringAsFixed(5),
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
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
  // TAB 1: SKID LIVE & DUTY/STANDBY ARCHITECTURE
  // ============================================================================

  Widget _buildSkidLiveTab(UfmStreamTelemetry active) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Duty / Standby Stream Dual Status Card
        Row(
          children: [
            Expanded(child: _buildStreamStatusMiniCard(_ufm01)),
            const SizedBox(width: 12),
            Expanded(child: _buildStreamStatusMiniCard(_ufm02)),
          ],
        ),
        const SizedBox(height: 16),

        // Live Process Flow & Energy Dispatch Metrics
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
                  Row(
                    children: const [
                      Icon(Icons.bolt_rounded, color: AppTheme.secondary, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Live Thermal Energy & Mass Rate',
                        style: TextStyle(
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
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ISO 6976 / AGA-5',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      'Energy Dispatch Rate',
                      '${NumberFormat('#,##0.0').format(active.energyFlowRateMmbtuh)} MMBtu/h',
                      '${NumberFormat('#,##0.0').format(active.energyFlowRateGjh)} GJ/h',
                      AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      'Mass Flow Rate',
                      '${NumberFormat('#,##0').format(active.massFlowRateKgh)} kg/h',
                      'SG: ${_gasChromatograph.specificGravity.toStringAsFixed(4)}',
                      AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      'Actual Volume Flow (Qa)',
                      '${NumberFormat('#,##0.0').format(active.actualFlowRateM3h)} m³/h',
                      'Flow Conditioning DP: ${active.differentialPressureMbar.toStringAsFixed(1)} mbar',
                      AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      'Flow Computer Lineup',
                      active.flowComputerTag,
                      'Serial: ${active.serialNumber}',
                      AppTheme.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live Dynamic Flow Telemetry Chart
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
                  Row(
                    children: const [
                      Icon(Icons.show_chart_rounded, color: AppTheme.primaryLight, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Standard Flow Trend (MMSCMD)',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Updated Live (2s sample)',
                    style: TextStyle(color: AppTheme.tertiary.withValues(alpha: 0.9), fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (val) => FlLine(
                        color: AppTheme.border.withValues(alpha: 0.4),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (val, meta) => Text(
                            val.toStringAsFixed(2),
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: 5.1,
                    maxY: 5.7,
                    lineBarsData: [
                      LineChartBarData(
                        spots: active.flowHistory,
                        isCurved: true,
                        color: AppTheme.tertiary,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.tertiary.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Online Gas Chromatograph Breakdown Card
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
                  Row(
                    children: const [
                      Icon(Icons.science_rounded, color: AppTheme.tertiary, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Online Gas Chromatograph (GC-0101)',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'ISO 6974 / GPA 2261',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildGcMoleculeChip('C1 Methane', '${_gasChromatograph.methaneMolePct}%', AppTheme.primaryLight),
                  _buildGcMoleculeChip('C2 Ethane', '${_gasChromatograph.ethaneMolePct}%', AppTheme.textPrimary),
                  _buildGcMoleculeChip('C3 Propane', '${_gasChromatograph.propaneMolePct}%', AppTheme.textPrimary),
                  _buildGcMoleculeChip('i/n-C4 Butanes', '${(_gasChromatograph.iButaneMolePct + _gasChromatograph.nButaneMolePct).toStringAsFixed(2)}%', AppTheme.textPrimary),
                  _buildGcMoleculeChip('CO₂ Dioxide', '${_gasChromatograph.carbonDioxideMolePct}%', AppTheme.secondary),
                  _buildGcMoleculeChip('N₂ Nitrogen', '${_gasChromatograph.nitrogenMolePct}%', AppTheme.textMuted),
                ],
              ),
              const Divider(color: AppTheme.border, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGcParamText('Gross Heating Value', '${_gasChromatograph.grossHeatingValueMjSm3} MJ/Sm³'),
                  _buildGcParamText('Wobbe Index', '${_gasChromatograph.wobbeIndex} MJ/Sm³'),
                  _buildGcParamText('Compressibility Z', _gasChromatograph.compressibilityZ.toStringAsFixed(4)),
                  _buildGcParamText('AGA-8 SOS', '${_gasChromatograph.theoreticalSosAga8} m/s'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreamStatusMiniCard(UfmStreamTelemetry stream) {
    final isDuty = stream.state == StreamOperationalState.dutyActive;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDuty ? AppTheme.surfaceContainerHigh : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDuty ? AppTheme.primary : AppTheme.border,
          width: isDuty ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stream.streamTag,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDuty ? AppTheme.tertiary.withValues(alpha: 0.2) : AppTheme.border.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isDuty ? 'DUTY FLOW' : 'HOT STANDBY',
                  style: TextStyle(
                    color: isDuty ? AppTheme.tertiary : AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(stream.skidLine, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniValveStatus('Inlet XV', stream.inletValveOpen),
              _buildMiniValveStatus('Outlet XV', stream.outletValveOpen),
              _buildMiniValveStatus('Prover XV', stream.proverBypassValveOpen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniValveStatus(String label, bool isOpen) {
    return Column(
      children: [
        Icon(
          isOpen ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isOpen ? AppTheme.tertiary : AppTheme.textMuted,
          size: 14,
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
      ],
    );
  }

  Widget _buildMetricTile(String label, String mainVal, String subVal, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            mainVal,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(subVal, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildGcMoleculeChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGcParamText(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 2: AGA-9 ACOUSTIC PATH SPEED OF SOUND & VELOCITY PROFILES
  // ============================================================================

  Widget _buildAga9AcousticsTab(UfmStreamTelemetry active) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AGA-9 Metrology Compliance Badge Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active.isAga9Compliant ? AppTheme.tertiary : AppTheme.secondary,
            ),
          ),
          child: Row(
            children: [
              Icon(
                active.isAga9Compliant ? Icons.verified_rounded : Icons.warning_rounded,
                color: active.isAga9Compliant ? AppTheme.tertiary : AppTheme.secondary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active.isAga9Compliant
                          ? 'AGA REPORT NO. 9 COMPLIANT'
                          : 'AGA-9 METROLOGY NOTICE',
                      style: TextStyle(
                        color: active.isAga9Compliant ? AppTheme.tertiary : AppTheme.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Max SOS spread: ${active.sosSpread.toStringAsFixed(2)} m/s (Limit: 0.50 m/s) • Profile Factor: ${active.profileFactor.toStringAsFixed(3)} (Norm: 1.15-1.25)',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Hydrodynamic Indices (Profile, Symmetry, Crossflow, Swirl, Turbulence)
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
                children: const [
                  Text(
                    'Hydrodynamic Diagnostic Indices',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('AGA-9 § 6.3.2', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildHydroIndexTile(
                      'Profile Factor',
                      active.profileFactor.toStringAsFixed(3),
                      'Target: 1.18 ± 0.05',
                      active.profileFactor >= 1.12 && active.profileFactor <= 1.25,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHydroIndexTile(
                      'Symmetry Factor',
                      active.symmetryFactor.toStringAsFixed(3),
                      'Target: 1.00 ± 0.015',
                      (active.symmetryFactor - 1.0).abs() <= 0.015,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHydroIndexTile(
                      'Cross-Flow Factor',
                      active.crossFlowFactor.toStringAsFixed(3),
                      'Target: 1.00 ± 0.02',
                      (active.crossFlowFactor - 1.0).abs() <= 0.02,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildHydroIndexTile(
                      'Swirl Angle',
                      '${active.swirlAngleDeg.toStringAsFixed(1)}°',
                      'Target: < 2.0°',
                      active.swirlAngleDeg < 2.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHydroIndexTile(
                      'Turbulence Index',
                      '${active.averageTurbulenceIndex.toStringAsFixed(2)}%',
                      'Target: 2.0% - 4.5%',
                      active.averageTurbulenceIndex <= 4.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Chordal Velocity Bar Chart
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
                children: const [
                  Text(
                    'Chordal Velocity Profile (m/s)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Gauss-Chebyshev Quadrature',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 12,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            switch (val.toInt()) {
                              case 0:
                                return const Text('Ch 1 (Outer Top)',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 9));
                              case 1:
                                return const Text('Ch 2 (Inner Top)',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 9));
                              case 2:
                                return const Text('Ch 3 (Inner Bot)',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 9));
                              case 3:
                                return const Text('Ch 4 (Outer Bot)',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 9));
                              default:
                                return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (val, meta) => Text(
                            '${val.toInt()} m/s',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (val) => FlLine(
                        color: AppTheme.border.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      for (int i = 0; i < active.paths.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: active.paths[i].axialVelocity,
                              color: (i == 1 || i == 2)
                                  ? AppTheme.primaryLight
                                  : AppTheme.primary,
                              width: 28,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
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

        // Path-by-Path Speed of Sound & Diagnostics Detailed Cards
        const Text(
          'Individual Acoustic Path SOS & Diagnostics',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final path in active.paths) _buildAcousticPathCard(path),
      ],
    );
  }

  Widget _buildHydroIndexTile(String label, String value, String sub, bool isOk) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOk ? AppTheme.border : AppTheme.secondary.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isOk ? AppTheme.tertiary : AppTheme.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isOk ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: isOk ? AppTheme.tertiary : AppTheme.secondary,
                size: 13,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildAcousticPathCard(AcousticPathData path) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: path.isSosValid ? AppTheme.border : AppTheme.error,
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
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'P${path.pathIndex}',
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    path.chordDesignation,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: path.isSosValid
                      ? AppTheme.tertiary.withValues(alpha: 0.15)
                      : AppTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DEV: ${path.sosDeviationPct >= 0 ? "+" : ""}${path.sosDeviationPct.toStringAsFixed(3)}%',
                  style: TextStyle(
                    color: path.isSosValid ? AppTheme.tertiary : AppTheme.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPathStatColumn(
                'Measured SOS',
                '${path.measuredSos.toStringAsFixed(2)} m/s',
                AppTheme.textPrimary,
              ),
              _buildPathStatColumn(
                'AGA-8 SOS',
                '${path.theoreticalSos.toStringAsFixed(2)} m/s',
                AppTheme.textMuted,
              ),
              _buildPathStatColumn(
                'Axial Vel.',
                '${path.axialVelocity.toStringAsFixed(2)} m/s',
                AppTheme.primaryLight,
              ),
              _buildPathStatColumn(
                'Gain / SNR',
                '${path.gainDb.toStringAsFixed(1)}dB / ${path.snrDb.toStringAsFixed(1)}dB',
                AppTheme.tertiary,
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                't₁: ${path.upstreamTransitTimeUs.toStringAsFixed(2)} μs • t₂: ${path.downstreamTransitTimeUs.toStringAsFixed(2)} μs • Δt: ${path.deltaTNs.toStringAsFixed(0)} ns',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
              ),
              Text(
                'Acc: ${path.pulseAcceptancePct.toStringAsFixed(1)}% • TI: ${path.pathTurbulenceIndex.toStringAsFixed(2)}%',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPathStatColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 3: BI-DIRECTIONAL PIPE PROVER & REPEATABILITY LOOP
  // ============================================================================

  Widget _buildPipeProverTab() {
    final isProving = _proverSkid.currentPhase != ProverPhase.standbyReady &&
        _proverSkid.currentPhase != ProverPhase.completed;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Prover Loop State & 4-Way Diverter Valve Card
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
                  Row(
                    children: const [
                      Icon(Icons.repeat_rounded, color: AppTheme.primaryLight, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Bi-Directional Pipe Prover (PRV-0101)',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      _proverSkid.standardCode,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Certified Base Volume: ${_proverSkid.calibratedWaterDrawVolumeM3.toStringAsFixed(4)} m³ (Water Draw Cert: ${_proverSkid.calibratedVolumeCert})',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('4-Way Diverter Valve Status:',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        Text(
                          _proverSkid.fourWayValvePosition,
                          style: TextStyle(
                            color: isProving ? AppTheme.secondary : AppTheme.tertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Displacer Sphere:',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        Text(
                          _proverSkid.sphereDisplacerMaterial,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isProving ? AppTheme.border : AppTheme.primary,
                  minimumSize: const Size.fromHeight(44),
                ),
                icon: isProving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.textPrimary),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                  isProving
                      ? 'Proving Run In Progress (Pass ${_proverSkid.currentActiveRun}/5)...'
                      : 'Initiate 5-Run Proving Sequence',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: isProving ? null : _startInteractiveProvingSequence,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // API MPMS Repeatability Summary Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _proverSkid.isApiRepeatabilityCompliant
                  ? AppTheme.tertiary
                  : AppTheme.secondary,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'API MPMS Repeatability Verification',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _proverSkid.isApiRepeatabilityCompliant
                          ? AppTheme.tertiary.withValues(alpha: 0.15)
                          : AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _proverSkid.isApiRepeatabilityCompliant
                          ? 'PASSED (≤ 0.0500%)'
                          : 'RUNS PENDING',
                      style: TextStyle(
                        color: _proverSkid.isApiRepeatabilityCompliant
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
                    child: _buildProverMetric(
                      'Repeatability Spread',
                      '${_proverSkid.repeatabilitySpreadPct.toStringAsFixed(4)}%',
                      'Tolerance: ≤ 0.0500%',
                      _proverSkid.isApiRepeatabilityCompliant
                          ? AppTheme.tertiary
                          : AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildProverMetric(
                      'Mean Meter Factor',
                      _proverSkid.meanMeterFactor.toStringAsFixed(5),
                      'Std Dev: ${_proverSkid.meterFactorStdDev.toStringAsFixed(6)}',
                      AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Proving Runs Table
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              '5 Consecutive Proving Runs Log',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'API MPMS Ch. 12.2',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final run in _proverSkid.completedRuns) _buildProvingRunCard(run),
        if (_proverSkid.completedRuns.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text(
              'No completed runs. Tap "Initiate 5-Run Proving Sequence" above to calibrate.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildProverMetric(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildProvingRunCard(ProvingRunRecord run) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${run.runNumber}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MF: ${run.calculatedMeterFactor.toStringAsFixed(5)}',
                    style: const TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'Round Trip: ${run.roundTripTimeSec.toStringAsFixed(2)}s • ${run.proverPulsesAcquired} pulses',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Vol: ${run.meterIndicatedBaseVolumeM3.toStringAsFixed(4)} m³',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontFamily: 'monospace'),
              ),
              Text(
                'Cts: ${run.ctsCorrection.toStringAsFixed(5)} • Cps: ${run.cpsCorrection.toStringAsFixed(5)}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: FISCAL BATCH TICKETS & TRIPARTITE SIGN-OFF
  // ============================================================================

  Widget _buildBatchTicketsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily Fiscal Transfer Consignment Card
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
                    children: [
                      const Text(
                        'DAILY FISCAL CUSTODY BATCH',
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _dailyBatchTicket.ticketNumber,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_rounded, color: AppTheme.textSecondary),
                    onPressed: _showTicketDossierDialog,
                  ),
                ],
              ),
              const Divider(color: AppTheme.border, height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTicketStatTile(
                      'Gross Standard Vol',
                      '${NumberFormat('#,##0').format(_dailyBatchTicket.totalStandardVolumeSm3)} Sm³',
                      AppTheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTicketStatTile(
                      'Total Energy',
                      '${NumberFormat('#,##0').format(_dailyBatchTicket.totalEnergyMmbtu)} MMBtu',
                      AppTheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTicketStatTile(
                      'Commercial Value',
                      '₹${NumberFormat('#,##0').format(_dailyBatchTicket.grossInvoiceValuationInr)}',
                      AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTicketStatTile(
                      'Prover MF Applied',
                      _dailyBatchTicket.appliedProverMeterFactor.toStringAsFixed(5),
                      AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tripartite Signature Approval Cards
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Tripartite Legal Signatures',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'PNGRB / OISD-141 Clause 11',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final sig in _dailyBatchTicket.signatures) _buildSignatureApprovalCard(sig),
        const SizedBox(height: 16),

        // Hourly Fiscal Log
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hourly Delivery Accumulator Log',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_hourlySlices.where((s) => s.isHourClosed).length}/24 Closed',
              style: const TextStyle(color: AppTheme.tertiary, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final slice in _hourlySlices.take(8)) _buildHourlySliceTile(slice),
      ],
    );
  }

  Widget _buildTicketStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureApprovalCard(TripartiteSignature sig) {
    final isSigned = sig.status == SignatureStatus.signed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSigned ? AppTheme.tertiary.withValues(alpha: 0.4) : AppTheme.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isSigned ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                color: isSigned ? AppTheme.tertiary : AppTheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sig.partyOrganization,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${sig.officerName} • ${sig.designation}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  if (sig.timestamp != null)
                    Text(
                      'Signed: ${DateFormat('HH:mm dd MMM').format(sig.timestamp!)} IST',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                    ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSigned ? AppTheme.surfaceContainerHigh : AppTheme.primary,
              foregroundColor: isSigned ? AppTheme.tertiary : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => _showSignatureDialog(sig),
            child: Text(
              isSigned ? 'Verified' : 'Sign Ticket',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlySliceTile(HourlyFiscalSlice slice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                slice.isHourClosed ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                color: slice.isHourClosed ? AppTheme.textMuted : AppTheme.secondary,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                slice.intervalLabel,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Text(
            '${NumberFormat('#,##0').format(slice.grossStandardVolumeSm3)} Sm³',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            '${NumberFormat('#,##0').format(slice.energyMmbtu)} MMBtu',
            style: const TextStyle(
              color: AppTheme.secondary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: slice.isHourClosed
                  ? AppTheme.surfaceContainerHigh
                  : AppTheme.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              slice.isHourClosed ? 'CLOSED' : 'ACCUMULATING',
              style: TextStyle(
                color: slice.isHourClosed ? AppTheme.textMuted : AppTheme.secondary,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
