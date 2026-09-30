import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS
// ============================================================================

enum ProverOperatingState {
  standby,
  valveDiverting,
  forwardPass,
  stabilizing,
  reversePass,
  sequenceCompleted,
}

enum MeterType {
  turbineAga7,
  ultrasonicAga9,
  coriolisApi56,
}

class ProverSkidConfig {
  final String skidId;
  final String proverTag;
  final String location;
  final String pipeSizeNominal;
  final double internalDiameterMm;
  final double wallThicknessMm;
  final double modulusElasticityMpa;
  final double steelThermalExpansionCoeff;
  final double baseVolumeCpvM3;
  final double fwdCalibratedVolumeM3;
  final double revCalibratedVolumeM3;
  final String legalMetrologyCertNo;
  final String certDateStr;
  final String nextDueCertDateStr;
  final String rtdSensorTag;
  final String ptTransmitterTag;

  const ProverSkidConfig({
    required this.skidId,
    required this.proverTag,
    required this.location,
    required this.pipeSizeNominal,
    required this.internalDiameterMm,
    required this.wallThicknessMm,
    required this.modulusElasticityMpa,
    required this.steelThermalExpansionCoeff,
    required this.baseVolumeCpvM3,
    required this.fwdCalibratedVolumeM3,
    required this.revCalibratedVolumeM3,
    required this.legalMetrologyCertNo,
    required this.certDateStr,
    required this.nextDueCertDateStr,
    required this.rtdSensorTag,
    required this.ptTransmitterTag,
  });
}

class MeterDeviceConfig {
  final String meterTag;
  final String makeModel;
  final String serialNumber;
  final MeterType meterType;
  final double nominalKFactor; // pulses / m3
  final double nominalFlowRateM3h;
  final double maxFlowRateM3h;
  final String streamTag;
  final String flowComputerTag;

  const MeterDeviceConfig({
    required this.meterTag,
    required this.makeModel,
    required this.serialNumber,
    required this.meterType,
    required this.nominalKFactor,
    required this.nominalFlowRateM3h,
    required this.maxFlowRateM3h,
    required this.streamTag,
    required this.flowComputerTag,
  });
}

class ProverRunRecord {
  final int runNumber;
  final String directionLabel;
  final double forwardTransitSec;
  final double reverseTransitSec;
  final double roundTripTransitSec;
  final int rawPulsesAccumulated;
  final double interpolatedPulses;
  final double proverTempC;
  final double meterTempC;
  final double proverPressureBarg;
  final double meterPressureBarg;
  final double ctsp;
  final double cpsp;
  final double ctls;
  final double cpls;
  final double ccf;
  final double proverCorrectedVolumeM3;
  final double meterIndicatedVolumeM3;
  final double calculatedMeterFactor;
  final double deltaFromNominalPct;
  final bool isRepeatable;

  const ProverRunRecord({
    required this.runNumber,
    required this.directionLabel,
    required this.forwardTransitSec,
    required this.reverseTransitSec,
    required this.roundTripTransitSec,
    required this.rawPulsesAccumulated,
    required this.interpolatedPulses,
    required this.proverTempC,
    required this.meterTempC,
    required this.proverPressureBarg,
    required this.meterPressureBarg,
    required this.ctsp,
    required this.cpsp,
    required this.ctls,
    required this.cpls,
    required this.ccf,
    required this.proverCorrectedVolumeM3,
    required this.meterIndicatedVolumeM3,
    required this.calculatedMeterFactor,
    required this.deltaFromNominalPct,
    required this.isRepeatable,
  });
}

class CalibrationCurvePoint {
  final double flowPct;
  final double flowRateM3h;
  final double meterFactor;
  final double upperLimit;
  final double lowerLimit;

  const CalibrationCurvePoint({
    required this.flowPct,
    required this.flowRateM3h,
    required this.meterFactor,
    required this.upperLimit,
    required this.lowerLimit,
  });
}

class UncertaintyComponent {
  final String sourceName;
  final String standardCode;
  final String uncertaintyType; // "Type A" or "Type B"
  final double standardUncertaintyPct;
  final String probabilityDistribution;
  final double divisor;
  final double sensitivityCoeff;
  final double contributionPct;

  const UncertaintyComponent({
    required this.sourceName,
    required this.standardCode,
    required this.uncertaintyType,
    required this.standardUncertaintyPct,
    required this.probabilityDistribution,
    required this.divisor,
    required this.sensitivityCoeff,
    required this.contributionPct,
  });
}

class TripartiteSignatory {
  final String role;
  final String organization;
  final String officerName;
  final String designation;
  bool isSigned;
  DateTime? signedAt;
  String? signatureHash;

  TripartiteSignatory({
    required this.role,
    required this.organization,
    required this.officerName,
    required this.designation,
    this.isSigned = false,
    this.signedAt,
    this.signatureHash,
  });
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class MeterProverScreen extends StatefulWidget {
  const MeterProverScreen({super.key});

  @override
  State<MeterProverScreen> createState() => _MeterProverScreenState();
}

class _MeterProverScreenState extends State<MeterProverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Selected Skid & Meter Configurations
  int _selectedSkidIndex = 0;
  int _selectedMeterIndex = 0;

  static const List<ProverSkidConfig> _skidConfigs = [
    ProverSkidConfig(
      skidId: 'PRV-01',
      proverTag: 'PRV-0101 Bi-Directional Pipe Prover',
      location: 'Duliajan CPF Custody Transfer Terminal',
      pipeSizeNominal: 'DN500 / 20" Class 600#',
      internalDiameterMm: 508.0,
      wallThicknessMm: 12.7,
      modulusElasticityMpa: 206000.0,
      steelThermalExpansionCoeff: 0.00001116,
      baseVolumeCpvM3: 24.9171,
      fwdCalibratedVolumeM3: 12.4582,
      revCalibratedVolumeM3: 12.4589,
      legalMetrologyCertNo: 'LMD/RRSL/ASSAM/2026/G-882',
      certDateStr: '28-Sep-2026',
      nextDueCertDateStr: '27-Sep-2027',
      rtdSensorTag: 'TT-0101 (4-Wire PT100 Duplex)',
      ptTransmitterTag: 'PT-0101 (Yokogawa DPharp 0.04%)',
    ),
    ProverSkidConfig(
      skidId: 'PRV-02',
      proverTag: 'PRV-0102 Bi-Directional Pipe Prover',
      location: 'Moran SV-03 Delivery Interconnect Skid',
      pipeSizeNominal: 'DN400 / 16" Class 600#',
      internalDiameterMm: 406.4,
      wallThicknessMm: 11.13,
      modulusElasticityMpa: 206000.0,
      steelThermalExpansionCoeff: 0.00001116,
      baseVolumeCpvM3: 18.4230,
      fwdCalibratedVolumeM3: 9.2110,
      revCalibratedVolumeM3: 9.2120,
      legalMetrologyCertNo: 'LMD/RRSL/ASSAM/2026/G-889',
      certDateStr: '15-Aug-2026',
      nextDueCertDateStr: '14-Aug-2027',
      rtdSensorTag: 'TT-0201 (4-Wire PT100 Duplex)',
      ptTransmitterTag: 'PT-0201 (Rosemount 3051S 0.04%)',
    ),
    ProverSkidConfig(
      skidId: 'MCP-01',
      proverTag: 'MCP-0103 Mobile Compact Small Volume Prover',
      location: 'Mobile Metrology Calibration Laboratory Van',
      pipeSizeNominal: 'DN300 / 12" SVP Precision Barrel',
      internalDiameterMm: 304.8,
      wallThicknessMm: 9.52,
      modulusElasticityMpa: 206000.0,
      steelThermalExpansionCoeff: 0.00001116,
      baseVolumeCpvM3: 8.7540,
      fwdCalibratedVolumeM3: 4.3770,
      revCalibratedVolumeM3: 4.3770,
      legalMetrologyCertNo: 'LMD/RRSL/ASSAM/2026/MCP-041',
      certDateStr: '10-Sep-2026',
      nextDueCertDateStr: '09-Sep-2027',
      rtdSensorTag: 'TT-0301 (Precision Calibrated RTD)',
      ptTransmitterTag: 'PT-0301 (Honeywell SmartLine 0.035%)',
    ),
  ];

  static const List<MeterDeviceConfig> _meterConfigs = [
    MeterDeviceConfig(
      meterTag: 'MTR-0101 (Stream A)',
      makeModel: 'Daniel 3814 Custody Flow Turbine Meter',
      serialNumber: 'SN-DNL-948271',
      meterType: MeterType.turbineAga7,
      nominalKFactor: 1000.0,
      nominalFlowRateM3h: 2500.0,
      maxFlowRateM3h: 5000.0,
      streamTag: 'Stream A (20" Class 600# Custody)',
      flowComputerTag: 'FC-0101 (Emerson S600+ Redundant)',
    ),
    MeterDeviceConfig(
      meterTag: 'MTR-0102 (Stream B)',
      makeModel: 'SeniorSonic 3804 4-Chord Ultrasonic Flow Meter',
      serialNumber: 'SN-SS-772910',
      meterType: MeterType.ultrasonicAga9,
      nominalKFactor: 1000.0,
      nominalFlowRateM3h: 2480.0,
      maxFlowRateM3h: 5000.0,
      streamTag: 'Stream B (20" Class 600# Custody)',
      flowComputerTag: 'FC-0102 (Emerson S600+ Redundant)',
    ),
    MeterDeviceConfig(
      meterTag: 'MTR-0103 (Skid C)',
      makeModel: 'Micro Motion ELITE Coriolis Mass/Volume Meter',
      serialNumber: 'SN-MM-310892',
      meterType: MeterType.coriolisApi56,
      nominalKFactor: 1000.0,
      nominalFlowRateM3h: 1200.0,
      maxFlowRateM3h: 2500.0,
      streamTag: 'Stream C (12" Class 600# Condensate)',
      flowComputerTag: 'FC-0103 (Omni 6000 Flow Computer)',
    ),
  ];

  // Prover Dynamic State
  ProverOperatingState _operatingState = ProverOperatingState.standby;
  double _sequenceProgress = 0.0; // 0.0 to 1.0
  double _spherePositionPct = 0.0; // 0.0 to 1.0 along prover loop
  Timer? _sequenceTimer;

  // Proximity Detector Switches & Valve DBB Telemetry
  bool _detectorSwitch1Active = false; // Inboard
  bool _detectorSwitch2Active = false; // Outboard
  String _detector1Timestamp = '10:14:02.109281';
  String _detector2Timestamp = '10:14:16.938421';
  String _diverterValvePosition = 'SEALED - FORWARD LOOP';
  double _diverterSealDpBar = 0.00; // 0.00 bar = perfect double block & bleed seal

  // Double Chronometry Telemetry (API MPMS 4.6)
  final double _detectorTransitTimeSec = 14.829140; // TD
  final double _meterPulseWindowSec = 14.828500; // TM
  final int _rawPulsesCounted = 24901; // N
  final double _interpolatedPulses = 24902.0743; // Ni = N * (TD / TM)

  // Interactive Live Process Parameters
  double _proverTempC = 28.40;
  double _meterTempC = 28.20;
  double _proverPressureBarg = 65.40;
  double _meterPressureBarg = 65.55;
  static const double _baseTempC = 15.00;
  static const double _basePressureBara = 1.01325;

  // 5-Run Repeatability Log
  late List<ProverRunRecord> _provingRuns;

  // Multi-Flow Rate Calibration Curve Points (AGA 7 multi-rate test)
  final List<CalibrationCurvePoint> _calibrationCurve = const [
    CalibrationCurvePoint(
      flowPct: 10.0,
      flowRateM3h: 500.0,
      meterFactor: 0.9988,
      upperLimit: 1.0015,
      lowerLimit: 0.9985,
    ),
    CalibrationCurvePoint(
      flowPct: 25.0,
      flowRateM3h: 1250.0,
      meterFactor: 0.9992,
      upperLimit: 1.0015,
      lowerLimit: 0.9985,
    ),
    CalibrationCurvePoint(
      flowPct: 50.0,
      flowRateM3h: 2500.0,
      meterFactor: 0.9994,
      upperLimit: 1.0015,
      lowerLimit: 0.9985,
    ),
    CalibrationCurvePoint(
      flowPct: 75.0,
      flowRateM3h: 3750.0,
      meterFactor: 0.9996,
      upperLimit: 1.0015,
      lowerLimit: 0.9985,
    ),
    CalibrationCurvePoint(
      flowPct: 100.0,
      flowRateM3h: 5000.0,
      meterFactor: 0.9995,
      upperLimit: 1.0015,
      lowerLimit: 0.9985,
    ),
  ];

  // ISO/IEC 17025 Uncertainty Budget Components
  final List<UncertaintyComponent> _uncertaintyComponents = const [
    UncertaintyComponent(
      sourceName: '5-Run Prover Repeatability (API MPMS 4.8)',
      standardCode: 'API MPMS 4.8 / GUM Type A',
      uncertaintyType: 'Type A',
      standardUncertaintyPct: 0.0160,
      probabilityDistribution: 'Normal (k=1)',
      divisor: 1.000,
      sensitivityCoeff: 1.000,
      contributionPct: 0.0160,
    ),
    UncertaintyComponent(
      sourceName: 'Base Calibrated Prover Volume (Water-Draw)',
      standardCode: 'API MPMS 4.9.2 / RRSL Metrology',
      uncertaintyType: 'Type B',
      standardUncertaintyPct: 0.0240,
      probabilityDistribution: 'Rectangular (√3)',
      divisor: 1.732,
      sensitivityCoeff: 1.000,
      contributionPct: 0.0139,
    ),
    UncertaintyComponent(
      sourceName: 'Prover RTD Temperature Sensor (4-Wire PT100)',
      standardCode: 'IEC 60751 Class A / API MPMS 7.1',
      uncertaintyType: 'Type B',
      standardUncertaintyPct: 0.0140,
      probabilityDistribution: 'Normal (k=2)',
      divisor: 2.000,
      sensitivityCoeff: 1.000,
      contributionPct: 0.0070,
    ),
    UncertaintyComponent(
      sourceName: 'Prover Pressure Transmitter (0.04% Calibrated)',
      standardCode: 'API MPMS 7.2 / ASME PTC 19.2',
      uncertaintyType: 'Type B',
      standardUncertaintyPct: 0.0180,
      probabilityDistribution: 'Normal (k=2)',
      divisor: 2.000,
      sensitivityCoeff: 1.000,
      contributionPct: 0.0090,
    ),
    UncertaintyComponent(
      sourceName: 'Double Chronometry Pulse Interpolation',
      standardCode: 'API MPMS Chapter 4.6',
      uncertaintyType: 'Type B',
      standardUncertaintyPct: 0.0040,
      probabilityDistribution: 'Rectangular (√3)',
      divisor: 1.732,
      sensitivityCoeff: 1.000,
      contributionPct: 0.0023,
    ),
    UncertaintyComponent(
      sourceName: 'Steel Modulus & Thermal Expansion Uncertainty',
      standardCode: 'ASTM A106 / API MPMS 12.2',
      uncertaintyType: 'Type B',
      standardUncertaintyPct: 0.0100,
      probabilityDistribution: 'Rectangular (√3)',
      divisor: 1.732,
      sensitivityCoeff: 1.000,
      contributionPct: 0.0058,
    ),
  ];

  // Tripartite Signatories for Calibration Certificate
  final List<TripartiteSignatory> _signatories = [
    TripartiteSignatory(
      role: 'Transporter (Operator)',
      organization: 'Oil India Limited (OIL Duliajan CPF)',
      officerName: 'Er. Bhabesh Kalita',
      designation: 'Chief Engineer (Custody Metering & Instrumentation)',
      isSigned: true,
      signedAt: DateTime(2026, 9, 28, 14, 30),
      signatureHash: 'OIL-DUL-0928-E78A1B',
    ),
    TripartiteSignatory(
      role: 'Shipper / Offtaker',
      organization: 'GAIL (India) Limited (Assam Gas Grid)',
      officerName: 'Er. R. K. Baruah',
      designation: 'General Manager (Gas Dispatch & Commercial)',
      isSigned: true,
      signedAt: DateTime(2026, 9, 28, 15, 10),
      signatureHash: 'GAIL-AGG-0928-88F40C',
    ),
    TripartiteSignatory(
      role: 'TPIA Witness',
      organization: 'Engineers India Limited (EIL Inspection)',
      officerName: 'Dr. S. Mukherjee',
      designation: 'Lead Inspection Engineer (Hydrocarbon Metrology)',
      isSigned: true,
      signedAt: DateTime(2026, 9, 28, 15, 45),
      signatureHash: 'EIL-CAL-0928-912BD3',
    ),
    TripartiteSignatory(
      role: 'Legal Metrology Officer',
      organization: 'Dept. of Legal Metrology, Govt. of Assam / RRSL',
      officerName: 'Shri A. K. Sarma',
      designation: 'Assistant Controller of Legal Metrology',
      isSigned: true,
      signedAt: DateTime(2026, 9, 28, 16, 20),
      signatureHash: 'LMD-RRSL-0928-AA450F',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _populateDefaultNominalRuns();
  }

  @override
  void dispose() {
    _sequenceTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================================
  // MATHEMATICAL COMPUTATIONS (AGA 7 & API MPMS 4 / 12)
  // ============================================================================

  /// Ctsp: Prover Steel Temperature Correction Factor
  /// Ctsp = 1 + [ (T_prover - T_base) * 3 * alpha_s ]
  double get calculatedCtsp {
    final skid = _skidConfigs[_selectedSkidIndex];
    final deltaT = _proverTempC - _baseTempC;
    final volumetricAlpha = 3.0 * skid.steelThermalExpansionCoeff;
    return 1.0 + (deltaT * volumetricAlpha);
  }

  /// Cpsp: Prover Steel Pressure Correction Factor
  /// Cpsp = 1 + [ (P_prover * D_inner) / (E * t_wall) ]
  double get calculatedCpsp {
    final skid = _skidConfigs[_selectedSkidIndex];
    final pMpa = _proverPressureBarg * 0.1; // Convert barg to MPa
    final numerator = pMpa * skid.internalDiameterMm;
    final denominator = skid.modulusElasticityMpa * skid.wallThicknessMm;
    return 1.0 + (numerator / denominator);
  }

  /// Ctls: Fluid Temperature Correction Factor (Prover vs Meter)
  /// Ctls = (T_meter + 273.15) / (T_prover + 273.15)
  double get calculatedCtls {
    final meterKelvin = _meterTempC + 273.15;
    final proverKelvin = _proverTempC + 273.15;
    return meterKelvin / proverKelvin;
  }

  /// Cpls: Fluid Pressure Correction Factor (Prover vs Meter)
  /// Cpls = (P_prover + P_atm) / (P_meter + P_atm)
  double get calculatedCpls {
    final proverAbs = _proverPressureBarg + _basePressureBara;
    final meterAbs = _meterPressureBarg + _basePressureBara;
    return proverAbs / meterAbs;
  }

  /// Combined Correction Factor (CCF)
  /// CCF = Ctsp * Cpsp * Ctls * Cpls
  double get calculatedCcf {
    return calculatedCtsp * calculatedCpsp * calculatedCtls * calculatedCpls;
  }

  /// Corrected Prover Volume (V_prover_corrected) at Meter Conditions
  double get calculatedProverVolumeM3 {
    final skid = _skidConfigs[_selectedSkidIndex];
    return skid.baseVolumeCpvM3 * calculatedCcf;
  }

  /// Indicated Meter Volume from Double Chronometry Interpolated Pulses
  double get calculatedMeterIndicatedVolumeM3 {
    final meter = _meterConfigs[_selectedMeterIndex];
    return _interpolatedPulses / meter.nominalKFactor;
  }

  /// Live Calculated Meter Factor
  double get calculatedLiveMeterFactor {
    final indicatedVol = calculatedMeterIndicatedVolumeM3;
    if (indicatedVol <= 0.0001) return 1.0000;
    return calculatedProverVolumeM3 / indicatedVol;
  }

  /// Mean Meter Factor of 5 Consecutive Runs
  double get meanMeterFactor {
    if (_provingRuns.isEmpty) return 0.9995;
    final sum = _provingRuns.fold<double>(
        0.0, (acc, r) => acc + r.calculatedMeterFactor);
    return sum / _provingRuns.length;
  }

  /// Minimum Meter Factor of 5 Consecutive Runs
  double get minMeterFactor {
    if (_provingRuns.isEmpty) return 0.9995;
    return _provingRuns.map((r) => r.calculatedMeterFactor).reduce(math.min);
  }

  /// Maximum Meter Factor of 5 Consecutive Runs
  double get maxMeterFactor {
    if (_provingRuns.isEmpty) return 0.9995;
    return _provingRuns.map((r) => r.calculatedMeterFactor).reduce(math.max);
  }

  /// Repeatability Spread %: ((MF_max - MF_min) / MF_min) * 100%
  /// API MPMS Chapter 4.8 Limit is <= 0.0500%
  double get repeatabilitySpreadPct {
    if (_provingRuns.length < 2) return 0.0;
    return ((maxMeterFactor - minMeterFactor) / minMeterFactor) * 100.0;
  }

  /// API MPMS 4.8 Repeatability Compliance Check
  bool get isRepeatabilityCompliant {
    if (_provingRuns.length < 5) return false;
    return repeatabilitySpreadPct <= 0.0500;
  }

  /// Standard Deviation of 5 Consecutive Runs
  double get meterFactorStdDev {
    if (_provingRuns.length < 2) return 0.0;
    final mean = meanMeterFactor;
    final variance = _provingRuns.fold<double>(
            0.0, (acc, r) => acc + math.pow(r.calculatedMeterFactor - mean, 2)) /
        (_provingRuns.length - 1);
    return math.sqrt(variance);
  }

  /// Combined Standard Uncertainty (u_c) per ISO/IEC 17025
  double get combinedStandardUncertaintyPct {
    final sumSquares = _uncertaintyComponents.fold<double>(
        0.0, (acc, c) => acc + math.pow(c.contributionPct, 2));
    return math.sqrt(sumSquares);
  }

  /// Expanded Uncertainty (U = k * u_c, k=2.0 for 95.45% confidence)
  /// Custody Transfer Requirement: U < 0.1500%
  double get expandedUncertaintyPct {
    return 2.0 * combinedStandardUncertaintyPct;
  }

  bool get isUncertaintyCompliant {
    return expandedUncertaintyPct < 0.1500;
  }

  /// Tamper-proof Metrological SHA-256 Hash
  String get metrologicalAuditHash {
    final skid = _skidConfigs[_selectedSkidIndex];
    final meter = _meterConfigs[_selectedMeterIndex];
    final payload = '${skid.proverTag}|${meter.meterTag}|${skid.legalMetrologyCertNo}|'
        '${meanMeterFactor.toStringAsFixed(6)}|${repeatabilitySpreadPct.toStringAsFixed(4)}|'
        '${expandedUncertaintyPct.toStringAsFixed(4)}';
    final bytes = utf8.encode(payload);
    return sha256.convert(bytes).toString().toUpperCase();
  }

  // ============================================================================
  // LOGIC & SEQUENCE SIMULATION
  // ============================================================================

  void _populateDefaultNominalRuns() {
    // 5 consecutive API MPMS 4.8 compliant runs with repeatability < 0.05%
    _provingRuns = [
      const ProverRunRecord(
        runNumber: 1,
        directionLabel: 'Combined Bi-Dir (Fwd+Rev)',
        forwardTransitSec: 14.828,
        reverseTransitSec: 14.831,
        roundTripTransitSec: 29.659,
        rawPulsesAccumulated: 24901,
        interpolatedPulses: 24902.12,
        proverTempC: 28.38,
        meterTempC: 28.19,
        proverPressureBarg: 65.41,
        meterPressureBarg: 65.55,
        ctsp: 1.000448,
        cpsp: 1.001270,
        ctls: 0.999370,
        cpls: 0.997745,
        ccf: 0.998831,
        proverCorrectedVolumeM3: 24.8880,
        meterIndicatedVolumeM3: 24.9021,
        calculatedMeterFactor: 0.99943,
        deltaFromNominalPct: -0.057,
        isRepeatable: true,
      ),
      const ProverRunRecord(
        runNumber: 2,
        directionLabel: 'Combined Bi-Dir (Fwd+Rev)',
        forwardTransitSec: 14.830,
        reverseTransitSec: 14.829,
        roundTripTransitSec: 29.659,
        rawPulsesAccumulated: 24901,
        interpolatedPulses: 24902.05,
        proverTempC: 28.40,
        meterTempC: 28.20,
        proverPressureBarg: 65.40,
        meterPressureBarg: 65.55,
        ctsp: 1.000449,
        cpsp: 1.001270,
        ctls: 0.999337,
        cpls: 0.997724,
        ccf: 0.998778,
        proverCorrectedVolumeM3: 24.8867,
        meterIndicatedVolumeM3: 24.9020,
        calculatedMeterFactor: 0.99939,
        deltaFromNominalPct: -0.061,
        isRepeatable: true,
      ),
      const ProverRunRecord(
        runNumber: 3,
        directionLabel: 'Combined Bi-Dir (Fwd+Rev)',
        forwardTransitSec: 14.829,
        reverseTransitSec: 14.832,
        roundTripTransitSec: 29.661,
        rawPulsesAccumulated: 24900,
        interpolatedPulses: 24901.89,
        proverTempC: 28.41,
        meterTempC: 28.21,
        proverPressureBarg: 65.39,
        meterPressureBarg: 65.54,
        ctsp: 1.000449,
        cpsp: 1.001269,
        ctls: 0.999337,
        cpls: 0.997725,
        ccf: 0.998778,
        proverCorrectedVolumeM3: 24.8867,
        meterIndicatedVolumeM3: 24.9019,
        calculatedMeterFactor: 0.99939,
        deltaFromNominalPct: -0.061,
        isRepeatable: true,
      ),
      const ProverRunRecord(
        runNumber: 4,
        directionLabel: 'Combined Bi-Dir (Fwd+Rev)',
        forwardTransitSec: 14.832,
        reverseTransitSec: 14.830,
        roundTripTransitSec: 29.662,
        rawPulsesAccumulated: 24901,
        interpolatedPulses: 24901.55,
        proverTempC: 28.42,
        meterTempC: 28.22,
        proverPressureBarg: 65.42,
        meterPressureBarg: 65.56,
        ctsp: 1.000450,
        cpsp: 1.001271,
        ctls: 0.999337,
        cpls: 0.997724,
        ccf: 0.998780,
        proverCorrectedVolumeM3: 24.8867,
        meterIndicatedVolumeM3: 24.9015,
        calculatedMeterFactor: 0.99941,
        deltaFromNominalPct: -0.059,
        isRepeatable: true,
      ),
      const ProverRunRecord(
        runNumber: 5,
        directionLabel: 'Combined Bi-Dir (Fwd+Rev)',
        forwardTransitSec: 14.827,
        reverseTransitSec: 14.830,
        roundTripTransitSec: 29.657,
        rawPulsesAccumulated: 24901,
        interpolatedPulses: 24902.30,
        proverTempC: 28.39,
        meterTempC: 28.20,
        proverPressureBarg: 65.40,
        meterPressureBarg: 65.55,
        ctsp: 1.000449,
        cpsp: 1.001270,
        ctls: 0.999370,
        cpls: 0.997724,
        ccf: 0.998811,
        proverCorrectedVolumeM3: 24.8875,
        meterIndicatedVolumeM3: 24.9023,
        calculatedMeterFactor: 0.99941,
        deltaFromNominalPct: -0.059,
        isRepeatable: true,
      ),
    ];
  }

  void _injectThermalPerturbation() {
    setState(() {
      _provingRuns = [
        ..._provingRuns.sublist(0, 4),
        const ProverRunRecord(
          runNumber: 5,
          directionLabel: 'Combined Bi-Dir (Fwd+Rev)',
          forwardTransitSec: 14.920,
          reverseTransitSec: 14.935,
          roundTripTransitSec: 29.855,
          rawPulsesAccumulated: 24945,
          interpolatedPulses: 24950.40,
          proverTempC: 29.85,
          meterTempC: 28.15,
          proverPressureBarg: 64.90,
          meterPressureBarg: 65.60,
          ctsp: 1.000497,
          cpsp: 1.001260,
          ctls: 0.994391,
          cpls: 0.989345,
          ccf: 0.985510,
          proverCorrectedVolumeM3: 24.5560,
          meterIndicatedVolumeM3: 24.9504,
          calculatedMeterFactor: 0.98419, // Significant perturbation > 0.05%
          deltaFromNominalPct: -1.581,
          isRepeatable: false,
        ),
      ];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Thermal perturbation injected: Repeatability spread exceeded 0.05% tolerance!',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _startLiveProverSequence() {
    if (_operatingState != ProverOperatingState.standby &&
        _operatingState != ProverOperatingState.sequenceCompleted) {
      return;
    }

    setState(() {
      _operatingState = ProverOperatingState.valveDiverting;
      _diverterValvePosition = 'CYCLING 4-WAY DIVERTER VALVE';
      _sequenceProgress = 0.05;
      _spherePositionPct = 0.0;
      _detectorSwitch1Active = false;
      _detectorSwitch2Active = false;
      _diverterSealDpBar = 0.01;
    });

    _sequenceTimer?.cancel();
    int tick = 0;
    _sequenceTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      tick++;
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (tick <= 5) {
          // Diverter cycling
          _sequenceProgress = 0.05 + (tick * 0.03);
          _diverterSealDpBar = 0.00;
        } else if (tick == 6) {
          // Diverter seated forward
          _operatingState = ProverOperatingState.forwardPass;
          _diverterValvePosition = 'SEALED - FORWARD LOOP';
          _detectorSwitch1Active = true;
          _detector1Timestamp = DateFormat('HH:mm:ss.SSSSSS').format(DateTime.now());
        } else if (tick > 6 && tick <= 20) {
          // Forward pass sphere moving
          _sequenceProgress = 0.20 + ((tick - 6) * 0.02);
          _spherePositionPct = (tick - 6) / 14.0;
          if (tick == 19) {
            _detectorSwitch2Active = true;
            _detector2Timestamp =
                DateFormat('HH:mm:ss.SSSSSS').format(DateTime.now());
          }
        } else if (tick == 21) {
          // Stabilizing / Diverter Reversing
          _operatingState = ProverOperatingState.stabilizing;
          _diverterValvePosition = 'CYCLING 4-WAY DIVERTER (REVERSE)';
          _detectorSwitch1Active = false;
          _detectorSwitch2Active = false;
          _sequenceProgress = 0.50;
        } else if (tick == 22) {
          // Reverse pass start
          _operatingState = ProverOperatingState.reversePass;
          _diverterValvePosition = 'SEALED - REVERSE LOOP';
          _detectorSwitch2Active = true;
        } else if (tick > 22 && tick <= 35) {
          // Reverse pass sphere returning
          _sequenceProgress = 0.55 + ((tick - 22) * 0.03);
          _spherePositionPct = 1.0 - ((tick - 22) / 13.0);
          if (tick == 34) {
            _detectorSwitch1Active = true;
          }
        } else if (tick > 35) {
          // Sequence completed
          _operatingState = ProverOperatingState.sequenceCompleted;
          _diverterValvePosition = 'SEALED - REST POSITION';
          _sequenceProgress = 1.0;
          _spherePositionPct = 0.0;
          _detectorSwitch1Active = false;
          _detectorSwitch2Active = false;
          _diverterSealDpBar = 0.00;
          timer.cancel();

          // Add a freshly computed run to the list
          final newRunIndex = _provingRuns.length + 1;
          final runRecord = ProverRunRecord(
            runNumber: newRunIndex,
            directionLabel: 'Combined Bi-Dir (Fwd+Rev)',
            forwardTransitSec: _detectorTransitTimeSec,
            reverseTransitSec: _detectorTransitTimeSec + 0.002,
            roundTripTransitSec: (_detectorTransitTimeSec * 2) + 0.002,
            rawPulsesAccumulated: _rawPulsesCounted,
            interpolatedPulses: _interpolatedPulses,
            proverTempC: _proverTempC,
            meterTempC: _meterTempC,
            proverPressureBarg: _proverPressureBarg,
            meterPressureBarg: _meterPressureBarg,
            ctsp: calculatedCtsp,
            cpsp: calculatedCpsp,
            ctls: calculatedCtls,
            cpls: calculatedCpls,
            ccf: calculatedCcf,
            proverCorrectedVolumeM3: calculatedProverVolumeM3,
            meterIndicatedVolumeM3: calculatedMeterIndicatedVolumeM3,
            calculatedMeterFactor: calculatedLiveMeterFactor,
            deltaFromNominalPct: ((calculatedLiveMeterFactor - 1.0) * 100.0),
            isRepeatable: true,
          );

          if (_provingRuns.length >= 5) {
            _provingRuns.removeAt(0);
          }
          _provingRuns.add(runRecord);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Prover Run #$newRunIndex Complete! Meter Factor: ${runRecord.calculatedMeterFactor.toStringAsFixed(5)}',
              ),
              backgroundColor: AppTheme.tertiary,
            ),
          );
        }
      });
    });
  }

  // ============================================================================
  // UI BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meter Prover & Calibration Lab',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'AGA Report No. 7 / API MPMS Chapter 4 Custody Transfer Prover',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Restore Nominal 5 Runs',
            icon: const Icon(Icons.restore_rounded, color: AppTheme.primaryLight),
            onPressed: () {
              setState(() {
                _populateDefaultNominalRuns();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nominal 5 proving runs restored (Repeatability < 0.05%)'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Inject Thermal Perturbation',
            icon: const Icon(Icons.warning_amber_rounded, color: AppTheme.secondary),
            onPressed: _injectThermalPerturbation,
          ),
          IconButton(
            tooltip: 'View Official Certificate',
            icon: const Icon(Icons.verified_rounded, color: AppTheme.tertiary),
            onPressed: _showCalibrationCertificateDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryLight,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.sync_alt_rounded, size: 18), text: 'Prover Loop'),
            Tab(icon: Icon(Icons.timer_rounded, size: 18), text: 'API 4.6 Chronometry'),
            Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Volume Corrections'),
            Tab(icon: Icon(Icons.repeat_rounded, size: 18), text: '5-Run Repeatability'),
            Tab(icon: Icon(Icons.show_chart_rounded, size: 18), text: 'Curve & Uncertainty'),
            Tab(icon: Icon(Icons.workspace_premium_rounded, size: 18), text: 'Certificate'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSkidAndMeterSelectorBar(),
          _buildLiveStatusKpiStrip(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProverLoopTab(),
                _buildDoubleChronometryTab(),
                _buildVolumeCorrectionTab(),
                _buildRepeatabilityTab(),
                _buildCurveAndUncertaintyTab(),
                _buildCertificateTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TOP SELECTOR & KPI BANNER
  // ============================================================================

  Widget _buildSkidAndMeterSelectorBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.loop_rounded, size: 16, color: AppTheme.primaryLight),
              const SizedBox(width: 6),
              const Text(
                'PROVER SKID:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_skidConfigs.length, (index) {
                      final skid = _skidConfigs[index];
                      final isSelected = _selectedSkidIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            '${skid.skidId} (${skid.pipeSizeNominal.split(' ').first})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.primary,
                          backgroundColor: AppTheme.surfaceCard,
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedSkidIndex = index;
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.speed_rounded, size: 16, color: AppTheme.secondary),
              const SizedBox(width: 6),
              const Text(
                'METER STREAM:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_meterConfigs.length, (index) {
                      final meter = _meterConfigs[index];
                      final isSelected = _selectedMeterIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            meter.meterTag.split(' ').first,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.secondary.withValues(alpha: 0.8),
                          backgroundColor: AppTheme.surfaceCard,
                          side: BorderSide(
                            color: isSelected ? AppTheme.secondary : AppTheme.border,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedMeterIndex = index;
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusKpiStrip() {
    final skid = _skidConfigs[_selectedSkidIndex];
    final isCompliant = isRepeatabilityCompliant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiCard(
              title: 'MEAN METER FACTOR (MF)',
              value: meanMeterFactor.toStringAsFixed(5),
              subtitle: 'Nominal 1.00000',
              accentColor: AppTheme.primaryLight,
              icon: Icons.calculate_rounded,
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              title: 'REPEATABILITY SPREAD',
              value: '${repeatabilitySpreadPct.toStringAsFixed(4)}%',
              subtitle: 'Limit: ≤ 0.0500% (${isCompliant ? 'PASS' : 'FAIL'})',
              accentColor: isCompliant ? AppTheme.tertiary : AppTheme.error,
              icon: isCompliant ? Icons.check_circle_rounded : Icons.error_rounded,
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              title: 'CERTIFIED PROVER VOL (CPV)',
              value: '${skid.baseVolumeCpvM3.toStringAsFixed(4)} m³',
              subtitle: 'LMD Cert: ${skid.legalMetrologyCertNo.split('/').last}',
              accentColor: AppTheme.secondary,
              icon: Icons.verified_user_rounded,
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              title: 'COMBINED CORRECTION (CCF)',
              value: calculatedCcf.toStringAsFixed(6),
              subtitle: 'Ctsp·Cpsp·Ctls·Cpls',
              accentColor: Colors.purpleAccent,
              icon: Icons.multiline_chart_rounded,
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              title: 'EXPANDED UNCERTAINTY (U)',
              value: '±${expandedUncertaintyPct.toStringAsFixed(3)}%',
              subtitle: 'ISO 17025 Target < 0.150%',
              accentColor: isUncertaintyCompliant ? AppTheme.tertiary : AppTheme.error,
              icon: Icons.shield_rounded,
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              title: '4-WAY DIVERTER SEAT DP',
              value: '${_diverterSealDpBar.toStringAsFixed(2)} bar',
              subtitle: 'Double Block & Bleed: OK',
              accentColor: AppTheme.primaryLight,
              icon: Icons.lock_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      width: 175,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: BI-DIRECTIONAL PROVER LOOP & SYNOPTIC
  // ============================================================================

  Widget _buildProverLoopTab() {
    final skid = _skidConfigs[_selectedSkidIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prover Loop Status Card
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
                        children: [
                          Text(
                            skid.proverTag,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Location: ${skid.location}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      _buildOperationalStatusBadge(_operatingState),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Synoptic Prover Pipe Loop Graphic
                  _buildProverLoopGraphic(skid),

                  const SizedBox(height: 16),

                  // Sequence Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sequence Phase: $_diverterValvePosition',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                          Text(
                            '${(_sequenceProgress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearPercentIndicator(
                        lineHeight: 8.0,
                        percent: _sequenceProgress.clamp(0.0, 1.0),
                        backgroundColor: AppTheme.surfaceContainerHigh,
                        progressColor: _operatingState == ProverOperatingState.sequenceCompleted
                            ? AppTheme.tertiary
                            : AppTheme.primaryLight,
                        barRadius: const Radius.circular(4),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Sequence Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _operatingState == ProverOperatingState.valveDiverting ||
                                  _operatingState == ProverOperatingState.forwardPass ||
                                  _operatingState == ProverOperatingState.reversePass
                              ? null
                              : _startLiveProverSequence,
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Execute Proving Run (Bi-Dir Pass)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _detectorSwitch1Active = !_detectorSwitch1Active;
                          });
                        },
                        icon: const Icon(Icons.sensors_rounded, size: 16),
                        label: const Text('Test SW-1'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.border),
                        ),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _detectorSwitch2Active = !_detectorSwitch2Active;
                          });
                        },
                        icon: const Icon(Icons.sensors_rounded, size: 16),
                        label: const Text('Test SW-2'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.border),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Metrological Hardware & Legal Metrology Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Proximity Switches Telemetry Card
              Expanded(
                child: Card(
                  color: AppTheme.surfaceCard,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.sensors_rounded, size: 16, color: AppTheme.primaryLight),
                            SizedBox(width: 6),
                            Text(
                              'Dual Proximity Detector Switches',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSwitchStatusRow(
                          switchTag: 'DETECTOR SWITCH 1 (INBOARD)',
                          isActive: _detectorSwitch1Active,
                          timestamp: _detector1Timestamp,
                          typeLabel: 'Hermetic Inductive / Latency < 15 ns',
                        ),
                        const Divider(height: 16, color: AppTheme.border),
                        _buildSwitchStatusRow(
                          switchTag: 'DETECTOR SWITCH 2 (OUTBOARD)',
                          isActive: _detectorSwitch2Active,
                          timestamp: _detector2Timestamp,
                          typeLabel: 'Hermetic Inductive / Latency < 15 ns',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 14, color: AppTheme.primaryLight),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Dual switches establish certified boundary calibrated prover volume (CPV) per API MPMS 4.2.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
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
              ),

              const SizedBox(width: 12),

              // Legal Metrology Calibration Plaque Card
              Expanded(
                child: Card(
                  color: AppTheme.surfaceCard,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.military_tech_rounded, size: 16, color: AppTheme.secondary),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Legal Metrology Department Certification',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPlaqueDataRow('Certificate No.', skid.legalMetrologyCertNo),
                        _buildPlaqueDataRow('Authority', 'Regional Reference Standards Lab (RRSL)'),
                        _buildPlaqueDataRow('Base Volume (CPV₀)', '${skid.baseVolumeCpvM3.toStringAsFixed(4)} m³ @ 15°C'),
                        _buildPlaqueDataRow('Forward Pass Volume', '${skid.fwdCalibratedVolumeM3.toStringAsFixed(4)} m³'),
                        _buildPlaqueDataRow('Reverse Pass Volume', '${skid.revCalibratedVolumeM3.toStringAsFixed(4)} m³'),
                        _buildPlaqueDataRow('Displacer Sphere', 'Inflatable Polyurethane / 3.2% Interference'),
                        _buildPlaqueDataRow('Calibration Method', 'Water-Draw with Gravimetric Standards (API 4.9)'),
                        _buildPlaqueDataRow('Seal Wire Integrity', 'VERIFIED & INTACT (Govt Stamp #0492)'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 4-Way Diverter Valve & Double Block and Bleed Seat Integrity
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.settings_input_component_rounded, size: 18, color: AppTheme.primaryLight),
                          SizedBox(width: 6),
                          Text(
                            '4-Way Diverter Valve & Double Block and Bleed (DBB) Monitoring',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _diverterSealDpBar <= 0.02
                              ? AppTheme.tertiary.withValues(alpha: 0.2)
                              : AppTheme.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _diverterSealDpBar <= 0.02 ? AppTheme.tertiary : AppTheme.error,
                          ),
                        ),
                        child: Text(
                          _diverterSealDpBar <= 0.02 ? 'SEAL INTEGRITY VERIFIED' : 'LEAK DETECTED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _diverterSealDpBar <= 0.02 ? AppTheme.tertiary : AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDbbMetricBox(
                          label: 'Diverter Valve Seat DP',
                          value: '${_diverterSealDpBar.toStringAsFixed(2)} bar',
                          status: 'Acceptable limit < 0.05 bar',
                          isPositive: _diverterSealDpBar <= 0.02,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDbbMetricBox(
                          label: 'Seal Cavity Vent Status',
                          value: 'Zero Venting Flow (0.0 L/min)',
                          status: 'Differential Pressure transducer reading',
                          isPositive: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDbbMetricBox(
                          label: 'Actuator Air Supply',
                          value: '7.20 barg',
                          status: 'Pneumatic Actuator Supply OK',
                          isPositive: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDbbMetricBox(
                          label: 'Diverter Cycle Time',
                          value: '4.85 seconds',
                          status: 'API limit < 8.00 seconds',
                          isPositive: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalStatusBadge(ProverOperatingState state) {
    String label;
    Color color;
    switch (state) {
      case ProverOperatingState.standby:
        label = 'STANDBY READY';
        color = AppTheme.primaryLight;
        break;
      case ProverOperatingState.valveDiverting:
        label = 'CYCLING 4-WAY VALVE';
        color = AppTheme.secondary;
        break;
      case ProverOperatingState.forwardPass:
        label = 'FORWARD PASS ACTIVE';
        color = Colors.greenAccent;
        break;
      case ProverOperatingState.stabilizing:
        label = 'STABILIZING FLOW';
        color = AppTheme.secondary;
        break;
      case ProverOperatingState.reversePass:
        label = 'REVERSE PASS ACTIVE';
        color = Colors.tealAccent;
        break;
      case ProverOperatingState.sequenceCompleted:
        label = '5-RUN SEQUENCE COMPLETE';
        color = AppTheme.tertiary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Row(
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
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProverLoopGraphic(ProverSkidConfig skid) {
    return Container(
      height: 160,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: CustomPaint(
        painter: _ProverLoopPainter(
          operatingState: _operatingState,
          spherePositionPct: _spherePositionPct,
          detector1Active: _detectorSwitch1Active,
          detector2Active: _detectorSwitch2Active,
        ),
      ),
    );
  }

  Widget _buildSwitchStatusRow({
    required String switchTag,
    required bool isActive,
    required String timestamp,
    required String typeLabel,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.tertiary : Colors.grey.shade700,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.tertiary.withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                switchTag,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppTheme.tertiary : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                typeLabel,
                style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isActive ? 'TRIPPED / CLOSED' : 'ARMED / OPEN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? AppTheme.tertiary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timestamp,
              style: const TextStyle(fontSize: 9, color: AppTheme.primaryLight),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaqueDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDbbMetricBox({
    required String label,
    required String value,
    required String status,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isPositive ? AppTheme.primaryLight : AppTheme.error,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: const TextStyle(fontSize: 8.5, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: DOUBLE CHRONOMETRY PULSE INTERPOLATION (API MPMS 4.6)
  // ============================================================================

  Widget _buildDoubleChronometryTab() {
    final meter = _meterConfigs[_selectedMeterIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Principle Banner Card
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timeline_rounded, size: 20, color: AppTheme.primaryLight),
                      SizedBox(width: 8),
                      Text(
                        'API MPMS Chapter 4.6: Pulse Interpolation (Double Chronometry)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Conventional pulse counting truncates fractional pulses at switch trip moments, causing up to ±1 pulse quantization error. '
                    'Double chronometry utilizes a high-frequency (10 MHz) crystal oscillator to time both the detector switch transit period (TD) '
                    'and the whole meter pulse duration (TM) with sub-microsecond resolution, yielding exact fractional pulse interpolation.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MATHEMATICAL GOVERNING FORMULA (API MPMS 4.6):',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Nᵢ = N × ( T_D / T_M )',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Where N = whole meter pulses counted; T_D = time between detector switch 1 and 2 actuation; T_M = time interval of whole meter pulses.',
                          style: TextStyle(fontSize: 9.5, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Double Chronometry Live Telemetry Dashboard
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'High-Speed Clock Counters & Interpolation Telemetry',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChronometryBox(
                          label: 'Master Oscillator Clock Frequency',
                          value: '10.000000 MHz',
                          subValue: 'Period: 100.0 nanoseconds',
                          icon: Icons.speed_rounded,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildChronometryBox(
                          label: 'Detector Transit Time (T_D)',
                          value: '${_detectorTransitTimeSec.toStringAsFixed(6)} s',
                          subValue: 'Clock Counts: 148,291,400',
                          icon: Icons.timer_rounded,
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildChronometryBox(
                          label: 'Meter Pulse Window Time (T_M)',
                          value: '${_meterPulseWindowSec.toStringAsFixed(6)} s',
                          subValue: 'Clock Counts: 148,285,000',
                          icon: Icons.av_timer_rounded,
                          color: AppTheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChronometryBox(
                          label: 'Raw Whole Pulses Counted (N)',
                          value: '$_rawPulsesCounted pulses',
                          subValue: 'Truncation error: ±0.0040%',
                          icon: Icons.grain_rounded,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildChronometryBox(
                          label: 'API 4.6 Interpolated Pulses (Nᵢ)',
                          value: _interpolatedPulses.toStringAsFixed(4),
                          subValue: 'Ratio T_D / T_M = ${(_detectorTransitTimeSec / _meterPulseWindowSec).toStringAsFixed(6)}',
                          icon: Icons.bolt_rounded,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildChronometryBox(
                          label: 'Interpolation Gain / Residual (ΔN)',
                          value: '+${(_interpolatedPulses - _rawPulsesCounted).toStringAsFixed(4)} pulses',
                          subValue: 'Quantization error: < 0.0001%',
                          icon: Icons.auto_graph_rounded,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Timing Diagram Schematic
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API MPMS 4.6 Timing Waveform Diagram',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Visualizing detector trip events against high-frequency pulse trains',
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 140,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: CustomPaint(
                      painter: _ChronometryWaveformPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // K-Factor Resolution Comparison
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pulse Resolution & K-Factor Validation',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meter Device: ${meter.makeModel}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nominal K-Factor: ${meter.nominalKFactor.toStringAsFixed(1)} pulses/m³',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Flow Rate: ${meter.nominalFlowRateM3h.toStringAsFixed(0)} m³/h (Pulse Freq: ${(meter.nominalFlowRateM3h * meter.nominalKFactor / 3600).toStringAsFixed(1)} Hz)',
                              style: const TextStyle(fontSize: 11, color: AppTheme.primaryLight),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.tertiary),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'API 4.6 COMPLIANT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.tertiary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Double Chronometry Active',
                              style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChronometryBox({
    required String label,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: const TextStyle(fontSize: 8.5, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: VOLUME CORRECTION FACTORS (Cpls, Cpsp, Ctls, Ctsp)
  // ============================================================================

  Widget _buildVolumeCorrectionTab() {
    final skid = _skidConfigs[_selectedSkidIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Correction Overview Card
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
                        'API MPMS Chapter 12.2 Volume Correction Factors',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.primaryLight),
                        ),
                        child: Text(
                          'CCF: ${calculatedCcf.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'To determine the true meter factor, the calibrated prover base volume (CPV₀ at 15°C, 1.01325 bar) '
                    'must be corrected for prover steel temperature expansion (Ctsp), prover steel pressure expansion (Cpsp), '
                    'fluid temperature differences between prover and meter (Ctls), and fluid pressure differences (Cpls).',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4 Correction Cards Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ctsp: Prover Steel Temperature
              Expanded(
                child: _buildCorrectionFactorCard(
                  factorName: 'Ctsp (Prover Steel Temperature)',
                  factorSymbol: 'Ctsp',
                  value: calculatedCtsp,
                  formula: '1 + [ (T_p - 15°C) × 3αₛ ]',
                  description: 'Corrects volumetric expansion of carbon steel prover barrel with temperature.',
                  parameters: [
                    'Prover Temp (T_p): ${_proverTempC.toStringAsFixed(2)}°C',
                    'Base Temp: 15.00°C',
                    'Linear Coeff (αₛ): 1.116 × 10⁻⁵ / °C',
                    'Volumetric Coeff (3αₛ): 3.348 × 10⁻⁵ / °C',
                    'Expansion Volume ΔV: +${((calculatedCtsp - 1.0) * skid.baseVolumeCpvM3).toStringAsFixed(4)} m³',
                  ],
                  accentColor: Colors.orangeAccent,
                ),
              ),

              const SizedBox(width: 12),

              // Cpsp: Prover Steel Pressure
              Expanded(
                child: _buildCorrectionFactorCard(
                  factorName: 'Cpsp (Prover Steel Pressure)',
                  factorSymbol: 'Cpsp',
                  value: calculatedCpsp,
                  formula: '1 + [ (P_p × D) / (E × t_w) ]',
                  description: 'Corrects elastic hoop dilation of prover pipe under internal working pressure.',
                  parameters: [
                    'Prover Pressure (P_p): ${_proverPressureBarg.toStringAsFixed(2)} barg',
                    'Internal Diameter (D): ${skid.internalDiameterMm.toStringAsFixed(1)} mm',
                    'Wall Thickness (t_w): ${skid.wallThicknessMm.toStringAsFixed(2)} mm',
                    'Elastic Modulus (E): 206,000 MPa',
                    'Elastic Expansion ΔV: +${((calculatedCpsp - 1.0) * skid.baseVolumeCpvM3).toStringAsFixed(4)} m³',
                  ],
                  accentColor: Colors.blueAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ctls: Fluid Temperature Prover vs Meter
              Expanded(
                child: _buildCorrectionFactorCard(
                  factorName: 'Ctls (Fluid Temperature Difference)',
                  factorSymbol: 'Ctls',
                  value: calculatedCtls,
                  formula: '(T_meter + 273.15) / (T_prover + 273.15)',
                  description: 'Accounts for thermal contraction/expansion of gas/liquid between meter and prover loop.',
                  parameters: [
                    'Prover Temp: ${_proverTempC.toStringAsFixed(2)}°C (Kelvin: ${(_proverTempC + 273.15).toStringAsFixed(2)} K)',
                    'Meter Temp: ${_meterTempC.toStringAsFixed(2)}°C (Kelvin: ${(_meterTempC + 273.15).toStringAsFixed(2)} K)',
                    'Differential ΔT: ${(_proverTempC - _meterTempC).toStringAsFixed(2)}°C',
                    'Fluid: Natural Gas (AGA-8 compressibility model)',
                    'Correction Impact: ${((calculatedCtls - 1.0) * 100).toStringAsFixed(3)}%',
                  ],
                  accentColor: AppTheme.tertiary,
                ),
              ),

              const SizedBox(width: 12),

              // Cpls: Fluid Pressure Prover vs Meter
              Expanded(
                child: _buildCorrectionFactorCard(
                  factorName: 'Cpls (Fluid Pressure Difference)',
                  factorSymbol: 'Cpls',
                  value: calculatedCpls,
                  formula: '(P_prover + 1.013) / (P_meter + 1.013)',
                  description: 'Accounts for fluid compressibility difference across the piping between meter and prover.',
                  parameters: [
                    'Prover Pressure: ${_proverPressureBarg.toStringAsFixed(2)} barg (${(_proverPressureBarg + _basePressureBara).toStringAsFixed(2)} bara)',
                    'Meter Pressure: ${_meterPressureBarg.toStringAsFixed(2)} barg (${(_meterPressureBarg + _basePressureBara).toStringAsFixed(2)} bara)',
                    'Skid Differential ΔP: ${(_meterPressureBarg - _proverPressureBarg).toStringAsFixed(2)} bar',
                    'Fluid Compressibility: Z_m / Z_p = 1.0000',
                    'Correction Impact: ${((calculatedCpls - 1.0) * 100).toStringAsFixed(3)}%',
                  ],
                  accentColor: Colors.purpleAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Interactive Sensitivity Tuning Sliders
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interactive Live Process Parameter Simulator',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Adjust process transmitters to observe real-time dynamic re-calculation of Ctsp, Cpsp, Ctls, Cpls and Meter Factor.',
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Prover Temp Slider
                  _buildProcessSlider(
                    label: 'Prover Temperature (T_p)',
                    value: _proverTempC,
                    min: 10.0,
                    max: 45.0,
                    unit: '°C',
                    onChanged: (val) {
                      setState(() {
                        _proverTempC = val;
                      });
                    },
                  ),

                  // Meter Temp Slider
                  _buildProcessSlider(
                    label: 'Meter Temperature (T_m)',
                    value: _meterTempC,
                    min: 10.0,
                    max: 45.0,
                    unit: '°C',
                    onChanged: (val) {
                      setState(() {
                        _meterTempC = val;
                      });
                    },
                  ),

                  // Prover Pressure Slider
                  _buildProcessSlider(
                    label: 'Prover Pressure (P_p)',
                    value: _proverPressureBarg,
                    min: 30.0,
                    max: 90.0,
                    unit: 'barg',
                    onChanged: (val) {
                      setState(() {
                        _proverPressureBarg = val;
                      });
                    },
                  ),

                  // Meter Pressure Slider
                  _buildProcessSlider(
                    label: 'Meter Pressure (P_m)',
                    value: _meterPressureBarg,
                    min: 30.0,
                    max: 90.0,
                    unit: 'barg',
                    onChanged: (val) {
                      setState(() {
                        _meterPressureBarg = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionFactorCard({
    required String factorName,
    required String factorSymbol,
    required double value,
    required String formula,
    required String description,
    required List<String> parameters,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                  factorName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  factorSymbol,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.toStringAsFixed(6),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              formula,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary),
          ),
          const Divider(height: 14, color: AppTheme.border),
          ...parameters.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Text(
                  '• $p',
                  style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildProcessSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: const SliderThemeData(
                activeTrackColor: AppTheme.primaryLight,
                inactiveTrackColor: AppTheme.surfaceContainerHigh,
                thumbColor: AppTheme.primaryLight,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 3,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 75,
            child: Text(
              '${value.toStringAsFixed(2)} $unit',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: 5-RUN REPEATABILITY LOG (API MPMS 4.8 / AGA 7)
  // ============================================================================

  Widget _buildRepeatabilityTab() {
    final isCompliant = isRepeatabilityCompliant;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compliance Status Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCompliant
                  ? AppTheme.tertiary.withValues(alpha: 0.12)
                  : AppTheme.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCompliant ? AppTheme.tertiary : AppTheme.error,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCompliant ? Icons.verified_rounded : Icons.warning_rounded,
                  size: 32,
                  color: isCompliant ? AppTheme.tertiary : AppTheme.error,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCompliant
                            ? 'API MPMS 4.8 REPEATABILITY PASSED (SPREAD ≤ 0.0500%)'
                            : 'REPEATABILITY TOLERANCE EXCEEDED (SPREAD > 0.0500%)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isCompliant ? AppTheme.tertiary : AppTheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '5 Consecutive Runs: Mean MF = ${meanMeterFactor.toStringAsFixed(5)} | Spread = ${repeatabilitySpreadPct.toStringAsFixed(4)}% | StdDev σ = ${meterFactorStdDev.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Criteria per API MPMS Chapter 4.8 & AGA 7: Prover volume repeatability spread across 5 consecutive round-trip passes must not exceed 0.05% (5 parts in 10,000).',
                        style: TextStyle(fontSize: 9.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5-Run Table Card
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Consecutive Proving Run Ledger (API MPMS 4.8)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Total Runs: ${_provingRuns.length}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Data Table
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppTheme.surfaceContainerHigh.withValues(alpha: 0.8),
                      ),
                      dataRowColor: WidgetStateProperty.resolveWith(
                        (states) => AppTheme.surfaceContainerHigh.withValues(alpha: 0.2),
                      ),
                      horizontalMargin: 12,
                      columnSpacing: 16,
                      columns: const [
                        DataColumn(label: Text('Run #', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Direction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Time (s)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Interp Pulses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Prover Vol (m³)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Meter Vol (m³)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('CCF Factor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Meter Factor (MF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Δ from Mean', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                      rows: _provingRuns.map((run) {
                        final deltaFromMean = ((run.calculatedMeterFactor - meanMeterFactor) / meanMeterFactor) * 100.0;
                        return DataRow(
                          cells: [
                            DataCell(Text('Run #${run.runNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            DataCell(Text(run.directionLabel, style: const TextStyle(fontSize: 10))),
                            DataCell(Text(run.roundTripTransitSec.toStringAsFixed(2), style: const TextStyle(fontSize: 11))),
                            DataCell(Text(run.interpolatedPulses.toStringAsFixed(2), style: const TextStyle(fontSize: 11))),
                            DataCell(Text(run.proverCorrectedVolumeM3.toStringAsFixed(4), style: const TextStyle(fontSize: 11))),
                            DataCell(Text(run.meterIndicatedVolumeM3.toStringAsFixed(4), style: const TextStyle(fontSize: 11))),
                            DataCell(Text(run.ccf.toStringAsFixed(6), style: const TextStyle(fontSize: 11))),
                            DataCell(
                              Text(
                                run.calculatedMeterFactor.toStringAsFixed(5),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: run.isRepeatable ? AppTheme.primaryLight : AppTheme.error,
                                ),
                              ),
                            ),
                            DataCell(Text('${deltaFromMean >= 0 ? '+' : ''}${deltaFromMean.toStringAsFixed(4)}%', style: const TextStyle(fontSize: 10.5))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: run.isRepeatable
                                      ? AppTheme.tertiary.withValues(alpha: 0.2)
                                      : AppTheme.error.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  run.isRepeatable ? 'PASSED' : 'OUT-OF-SPEC',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: run.isRepeatable ? AppTheme.tertiary : AppTheme.error,
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
          ),

          const SizedBox(height: 16),

          // Repeatability Spread Breakdown Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'MAXIMUM RUN MF',
                  value: maxMeterFactor.toStringAsFixed(5),
                  color: AppTheme.primaryLight,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'MINIMUM RUN MF',
                  value: minMeterFactor.toStringAsFixed(5),
                  color: AppTheme.secondary,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'MF SPREAD (MAX - MIN)',
                  value: (maxMeterFactor - minMeterFactor).toStringAsFixed(5),
                  color: Colors.purpleAccent,
                  icon: Icons.straighten_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'REPEATABILITY SPREAD %',
                  value: '${repeatabilitySpreadPct.toStringAsFixed(4)}%',
                  color: isCompliant ? AppTheme.tertiary : AppTheme.error,
                  icon: Icons.percent_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Historical Proving Meter Factor Stability Trend
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Historical Meter Factor Proving Stability (6-Month Calibration Trend)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tracking long-term stability within AGA-7 custody transfer tolerance limits (±0.15%)',
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        backgroundColor: Colors.transparent,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 0.0005,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: AppTheme.border.withValues(alpha: 0.5),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                const labels = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep (Live)'];
                                final idx = value.toInt();
                                if (idx >= 0 && idx < labels.length) {
                                  return Text(
                                    labels[idx],
                                    style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 45,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(4),
                                  style: const TextStyle(fontSize: 8.5, color: AppTheme.textMuted),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: AppTheme.border),
                        ),
                        minX: 0,
                        maxX: 5,
                        minY: 0.9980,
                        maxY: 1.0010,
                        lineBarsData: [
                          // Upper limit (+0.15%)
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 1.0015),
                              FlSpot(5, 1.0015),
                            ],
                            isCurved: false,
                            color: Colors.redAccent.withValues(alpha: 0.6),
                            barWidth: 1,
                            dashArray: [4, 4],
                            dotData: const FlDotData(show: false),
                          ),
                          // Nominal 1.0000
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 1.0000),
                              FlSpot(5, 1.0000),
                            ],
                            isCurved: false,
                            color: Colors.white24,
                            barWidth: 1,
                            dashArray: [2, 2],
                            dotData: const FlDotData(show: false),
                          ),
                          // Actual Historical Meter Factors
                          LineChartBarData(
                            spots: [
                              const FlSpot(0, 0.9992),
                              const FlSpot(1, 0.9993),
                              const FlSpot(2, 0.9995),
                              const FlSpot(3, 0.9994),
                              const FlSpot(4, 0.9994),
                              FlSpot(5, meanMeterFactor),
                            ],
                            isCurved: true,
                            color: AppTheme.primaryLight,
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.primary.withValues(alpha: 0.12),
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
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 5: CALIBRATION CURVE & UNCERTAINTY BUDGET (U < 0.15%)
  // ============================================================================

  Widget _buildCurveAndUncertaintyTab() {
    final isUncertaintyOk = isUncertaintyCompliant;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calibration Curve Card
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
                        'Multi-Rate Calibration Curve (AGA Report No. 7)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.primaryLight),
                        ),
                        child: const Text(
                          'Tolerance Envelope: ±0.15%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Meter Factor vs Flow Rate across 10%, 25%, 50%, 75% and 100% Qmax',
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        backgroundColor: Colors.transparent,
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 0.0005,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: AppTheme.border.withValues(alpha: 0.5),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 1000,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()} m³/h',
                                  style: const TextStyle(fontSize: 8.5, color: AppTheme.textMuted),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 45,
                              interval: 0.0005,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(4),
                                  style: const TextStyle(fontSize: 8.5, color: AppTheme.textMuted),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: AppTheme.border),
                        ),
                        minX: 0,
                        maxX: 5200,
                        minY: 0.9975,
                        maxY: 1.0020,
                        lineBarsData: [
                          // Upper envelope +0.15% (1.0015)
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 1.0015),
                              FlSpot(5200, 1.0015),
                            ],
                            color: Colors.redAccent.withValues(alpha: 0.5),
                            barWidth: 1.5,
                            dashArray: [5, 5],
                            dotData: const FlDotData(show: false),
                          ),
                          // Lower envelope -0.15% (0.9985)
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 0.9985),
                              FlSpot(5200, 0.9985),
                            ],
                            color: Colors.redAccent.withValues(alpha: 0.5),
                            barWidth: 1.5,
                            dashArray: [5, 5],
                            dotData: const FlDotData(show: false),
                          ),
                          // Nominal Base 1.0000
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 1.0000),
                              FlSpot(5200, 1.0000),
                            ],
                            color: Colors.white30,
                            barWidth: 1,
                            dashArray: [2, 2],
                            dotData: const FlDotData(show: false),
                          ),
                          // Actual Meter Factor Curve Points
                          LineChartBarData(
                            spots: _calibrationCurve.map((pt) {
                              return FlSpot(pt.flowRateM3h, pt.meterFactor);
                            }).toList(),
                            isCurved: true,
                            color: AppTheme.tertiary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.tertiary.withValues(alpha: 0.08),
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

          // Uncertainty Compliance Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUncertaintyOk
                  ? AppTheme.tertiary.withValues(alpha: 0.12)
                  : AppTheme.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isUncertaintyOk ? AppTheme.tertiary : AppTheme.error,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isUncertaintyOk ? Icons.shield_rounded : Icons.gpp_bad_rounded,
                  size: 32,
                  color: isUncertaintyOk ? AppTheme.tertiary : AppTheme.error,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUncertaintyOk
                            ? 'ISO/IEC 17025 UNCERTAINTY BUDGET COMPLIANT (U < 0.1500%)'
                            : 'EXPANDED UNCERTAINTY EXCEEDS CUSTODY LIMIT (U ≥ 0.1500%)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isUncertaintyOk ? AppTheme.tertiary : AppTheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Combined Standard Uncertainty u_c = ±${combinedStandardUncertaintyPct.toStringAsFixed(4)}% | '
                        'Expanded Uncertainty U (k=2.00, 95.45% CL) = ±${expandedUncertaintyPct.toStringAsFixed(4)}%',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Conforms to ISO/IEC Guide 98-3 (GUM) and Legal Metrology Custody Transfer accuracy specifications.',
                        style: TextStyle(fontSize: 9.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ISO/IEC 17025 Uncertainty Budget Table Card
          Card(
            color: AppTheme.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ISO/IEC 17025 Uncertainty Budget Breakdown',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppTheme.surfaceContainerHigh.withValues(alpha: 0.8),
                      ),
                      dataRowColor: WidgetStateProperty.resolveWith(
                        (states) => AppTheme.surfaceContainerHigh.withValues(alpha: 0.2),
                      ),
                      horizontalMargin: 12,
                      columnSpacing: 14,
                      columns: const [
                        DataColumn(label: Text('Uncertainty Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Code / Standard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Divisor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Standard uᵢ (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Contribution (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                      rows: _uncertaintyComponents.map((comp) {
                        return DataRow(
                          cells: [
                            DataCell(Text(comp.sourceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5))),
                            DataCell(Text(comp.standardCode, style: const TextStyle(fontSize: 10))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: comp.uncertaintyType == 'Type A'
                                      ? AppTheme.primaryLight.withValues(alpha: 0.2)
                                      : AppTheme.secondary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  comp.uncertaintyType,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: comp.uncertaintyType == 'Type A'
                                        ? AppTheme.primaryLight
                                        : AppTheme.secondary,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(comp.probabilityDistribution, style: const TextStyle(fontSize: 10))),
                            DataCell(Text(comp.divisor.toStringAsFixed(3), style: const TextStyle(fontSize: 10.5))),
                            DataCell(Text('±${comp.standardUncertaintyPct.toStringAsFixed(4)}%', style: const TextStyle(fontSize: 10.5))),
                            DataCell(
                              Text(
                                '±${comp.contributionPct.toStringAsFixed(4)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: AppTheme.primaryLight,
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
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 6: CALIBRATION CERTIFICATE & TRIPARTITE SIGNATURES
  // ============================================================================

  Widget _buildCertificateTab() {
    final skid = _skidConfigs[_selectedSkidIndex];
    final meter = _meterConfigs[_selectedMeterIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Certificate Summary Card
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
                        children: [
                          const Text(
                            'Legal Metrology Custody Transfer Calibration Certificate',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Certificate No: ${skid.legalMetrologyCertNo}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.primaryLight),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showCalibrationCertificateDialog,
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('View Official Certificate'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCertificateSummaryRow('Transporter (Seller)', 'Oil India Limited (OIL Duliajan CPF)'),
                  _buildCertificateSummaryRow('Shipper (Buyer)', 'GAIL (India) Limited (Assam Gas Grid)'),
                  _buildCertificateSummaryRow('TPIA Authority', 'Engineers India Limited (EIL Independent Inspector)'),
                  _buildCertificateSummaryRow('Calibrated Meter Tag', '${meter.meterTag} - ${meter.makeModel}'),
                  _buildCertificateSummaryRow('Meter Serial No', meter.serialNumber),
                  _buildCertificateSummaryRow('Nominal K-Factor', '${meter.nominalKFactor.toStringAsFixed(1)} pulses/m³'),
                  _buildCertificateSummaryRow('Prover Skid Tag', skid.proverTag),
                  _buildCertificateSummaryRow('Base Prover Volume CPV₀', '${skid.baseVolumeCpvM3.toStringAsFixed(4)} m³ @ 15°C, 1.01325 bar'),
                  _buildCertificateSummaryRow('Final Calibrated Meter Factor', meanMeterFactor.toStringAsFixed(5)),
                  _buildCertificateSummaryRow('Repeatability Spread', '${repeatabilitySpreadPct.toStringAsFixed(4)}% (Tolerance ≤ 0.0500% PASS)'),
                  _buildCertificateSummaryRow('Expanded Uncertainty (U)', '±${expandedUncertaintyPct.toStringAsFixed(3)}% (k=2.00, PASS < 0.150%)'),
                  const Divider(height: 20, color: AppTheme.border),
                  Row(
                    children: [
                      const Icon(Icons.fingerprint_rounded, size: 16, color: AppTheme.secondary),
                      const SizedBox(width: 8),
                      const Text(
                        'Metrological Audit SHA-256 Hash: ',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                      ),
                      Expanded(
                        child: Text(
                          metrologicalAuditHash,
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.primaryLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.textMuted),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: metrologicalAuditHash));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Audit Hash copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tripartite Signatures Grid
          const Text(
            'Tripartite Witness Signatures & Official Endorsement',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All parties must digitally authenticate the calibration run data before commercial custody billing.',
            style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),

          ..._signatories.map((sig) {
            return Card(
              color: AppTheme.surfaceCard,
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: sig.isSigned
                            ? AppTheme.tertiary.withValues(alpha: 0.2)
                            : AppTheme.error.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sig.isSigned ? AppTheme.tertiary : AppTheme.error,
                        ),
                      ),
                      child: Icon(
                        sig.isSigned ? Icons.check_rounded : Icons.pending_rounded,
                        size: 20,
                        color: sig.isSigned ? AppTheme.tertiary : AppTheme.error,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                sig.role,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${sig.organization})',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sig.officerName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sig.designation,
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                          if (sig.isSigned && sig.signedAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Signed on: ${DateFormat('yyyy-MM-dd HH:mm').format(sig.signedAt!)} | Token: ${sig.signatureHash}',
                              style: const TextStyle(fontSize: 9.5, color: AppTheme.tertiary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          sig.isSigned = !sig.isSigned;
                          if (sig.isSigned) {
                            sig.signedAt = DateTime.now();
                            sig.signatureHash = 'SIG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                          } else {
                            sig.signedAt = null;
                            sig.signatureHash = null;
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sig.isSigned ? Colors.grey.shade800 : AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        sig.isSigned ? 'Revoke Signature' : 'Sign Certificate',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCertificateSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  void _showCalibrationCertificateDialog() {
    final skid = _skidConfigs[_selectedSkidIndex];
    final meter = _meterConfigs[_selectedMeterIndex];

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppTheme.surface,
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Certificate Official Header
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GOVERNMENT OF INDIA',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.secondary),
                          ),
                          Text(
                            'DEPARTMENT OF LEGAL METROLOGY',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          Text(
                            'Regional Reference Standards Laboratory (RRSL)',
                            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      Icon(Icons.workspace_premium_rounded, size: 36, color: AppTheme.secondary),
                    ],
                  ),
                  const Divider(height: 24, color: AppTheme.border),

                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'CERTIFICATE OF CALIBRATION & VERIFICATION',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppTheme.primaryLight),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Issued under the Legal Metrology Act, 2009 & General Rules, 2011',
                          style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Certificate ID: ${skid.legalMetrologyCertNo}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
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
                        _buildDialogRow('Meter Under Test:', meter.makeModel),
                        _buildDialogRow('Meter Serial No:', meter.serialNumber),
                        _buildDialogRow('Flow Standard Code:', 'AGA Report No. 7 / API MPMS Chapter 4.8'),
                        _buildDialogRow('Prover Pipe Skid:', skid.proverTag),
                        _buildDialogRow('Prover Base Volume CPV₀:', '${skid.baseVolumeCpvM3.toStringAsFixed(4)} m³'),
                        _buildDialogRow('Pulse Interpolation Method:', 'Double Chronometry per API MPMS 4.6'),
                        _buildDialogRow('Consecutive Runs Proved:', '5 Consecutive Bidirectional Passes'),
                        _buildDialogRow('Repeatability Spread:', '${repeatabilitySpreadPct.toStringAsFixed(4)}% (TOLERANCE ≤ 0.0500% PASSED)'),
                        _buildDialogRow('FINAL ASSIGNED METER FACTOR (MF):', meanMeterFactor.toStringAsFixed(5), isHighlighted: true),
                        _buildDialogRow('Expanded Uncertainty (U):', '±${expandedUncertaintyPct.toStringAsFixed(3)}% (k=2.00, CL 95.45% PASSED < 0.150%)'),
                        _buildDialogRow('Validity Period:', '12 Months (Valid until 28-SEP-2027)'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Endorsement signatures in certificate
                  const Text(
                    'Authenticated Signatories:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _signatories.map((s) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                s.isSigned ? Icons.verified_user_rounded : Icons.hourglass_top_rounded,
                                size: 16,
                                color: s.isSigned ? AppTheme.tertiary : Colors.orangeAccent,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.officerName,
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                s.role.split(' ').first,
                                style: const TextStyle(fontSize: 8.5, color: AppTheme.textMuted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Tamper-proof SHA-256 Metrological Fingerprint:\n$metrologicalAuditHash',
                      style: const TextStyle(fontSize: 8.5, fontFamily: 'monospace', color: AppTheme.primaryLight),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close Preview', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Official Certificate Generated & Exported to PDF Archive!'),
                              backgroundColor: AppTheme.primary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Export Official PDF'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? AppTheme.tertiary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS: PROVER LOOP SYNOPTIC & DOUBLE CHRONOMETRY
// ============================================================================

class _ProverLoopPainter extends CustomPainter {
  final ProverOperatingState operatingState;
  final double spherePositionPct;
  final bool detector1Active;
  final bool detector2Active;

  _ProverLoopPainter({
    required this.operatingState,
    required this.spherePositionPct,
    required this.detector1Active,
    required this.detector2Active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pipePaint = Paint()
      ..color = const Color(0xFF26396E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    final pipeInnerPaint = Paint()
      ..color = const Color(0xFF111C38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    final diverterPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.fill;

    // Draw U-Shaped Bi-Directional Prover Pipe Barrel
    final path = Path();
    final leftX = size.width * 0.15;
    final rightX = size.width * 0.85;
    final topY = size.height * 0.30;
    final bottomY = size.height * 0.75;
    final radius = (bottomY - topY) / 2.0;

    // Pipe loop
    path.moveTo(leftX, topY);
    path.lineTo(rightX - radius, topY);
    path.arcToPoint(
      Offset(rightX - radius, bottomY),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(leftX, bottomY);

    canvas.drawPath(path, pipePaint);
    canvas.drawPath(path, pipeInnerPaint);

    // Draw 4-Way Diverter Valve Chamber on Left
    final diverterCenter = Offset(leftX - 10, (topY + bottomY) / 2.0);
    final valveRect = Rect.fromCenter(center: diverterCenter, width: 34, height: 34);
    canvas.drawRRect(RRect.fromRectAndRadius(valveRect, const Radius.circular(6)), diverterPaint);

    // Diverter Valve Icon / Lines
    final valveLinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(diverterCenter.dx - 10, diverterCenter.dy - 10),
      Offset(diverterCenter.dx + 10, diverterCenter.dy + 10),
      valveLinePaint,
    );
    canvas.drawLine(
      Offset(diverterCenter.dx - 10, diverterCenter.dy + 10),
      Offset(diverterCenter.dx + 10, diverterCenter.dy - 10),
      valveLinePaint,
    );

    // Draw Proximity Detector Switch 1 (Top Loop at 35% length)
    final sw1Pos = Offset(leftX + (rightX - leftX) * 0.35, topY);
    _drawDetectorSwitch(canvas, sw1Pos, 'SW-1', detector1Active);

    // Draw Proximity Detector Switch 2 (Bottom Loop at 35% length)
    final sw2Pos = Offset(leftX + (rightX - leftX) * 0.35, bottomY);
    _drawDetectorSwitch(canvas, sw2Pos, 'SW-2', detector2Active);

    // Calibrated Prover Volume (CPV) Bracket Label
    final cpvCenter = Offset(leftX + (rightX - leftX) * 0.65, (topY + bottomY) / 2.0);
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'CALIBRATED PROVER VOLUME (CPV)',
        style: TextStyle(
          color: Color(0xFF38BDF8),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(cpvCenter.dx - (textPainter.width / 2), cpvCenter.dy - 6));

    // Draw Displacer Sphere
    Offset spherePos;
    if (operatingState == ProverOperatingState.forwardPass) {
      // Moves along top branch from left to right
      spherePos = Offset(leftX + ((rightX - radius - leftX) * spherePositionPct), topY);
    } else if (operatingState == ProverOperatingState.reversePass) {
      // Moves along bottom branch from right to left
      spherePos = Offset(leftX + ((rightX - radius - leftX) * spherePositionPct), bottomY);
    } else {
      spherePos = Offset(leftX, topY);
    }

    final spherePaint = Paint()
      ..color = const Color(0xFFFFB95F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(spherePos, 8.0, spherePaint);

    final sphereBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(spherePos, 8.0, sphereBorder);
  }

  void _drawDetectorSwitch(Canvas canvas, Offset pos, String label, bool active) {
    final switchPaint = Paint()
      ..color = active ? const Color(0xFF4EDEA3) : const Color(0xFF64748B)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pos, 6.0, switchPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: active ? const Color(0xFF4EDEA3) : const Color(0xFF94A3B8),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(pos.dx - (textPainter.width / 2), pos.dy - 18));
  }

  @override
  bool shouldRepaint(covariant _ProverLoopPainter oldDelegate) {
    return oldDelegate.operatingState != operatingState ||
        oldDelegate.spherePositionPct != spherePositionPct ||
        oldDelegate.detector1Active != detector1Active ||
        oldDelegate.detector2Active != detector2Active;
  }
}

class _ChronometryWaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF26396E)
      ..strokeWidth = 1.0;

    final pulsePaint = Paint()
      ..color = const Color(0xFF4EDEA3)
      ..strokeWidth = 2.0;

    final switchPaint = Paint()
      ..color = const Color(0xFFFFB95F)
      ..strokeWidth = 2.0;

    // Draw Detector Switch Signal Waveform (Top)
    final textPainter1 = TextPainter(
      text: const TextSpan(
        text: 'Detector Switch SW-1 / SW-2 Gate (T_D):',
        style: TextStyle(color: Color(0xFFFFB95F), fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter1.paint(canvas, const Offset(10, 8));

    // SW gate high between x=60 and x= size.width - 60
    final swGateY = 32.0;
    final startX = size.width * 0.15;
    final endX = size.width * 0.85;

    final gatePath = Path()
      ..moveTo(10, swGateY + 12)
      ..lineTo(startX, swGateY + 12)
      ..lineTo(startX, swGateY)
      ..lineTo(endX, swGateY)
      ..lineTo(endX, swGateY + 12)
      ..lineTo(size.width - 10, swGateY + 12);
    canvas.drawPath(gatePath, switchPaint..style = PaintingStyle.stroke);

    // Draw Meter Whole Pulses Waveform (Bottom)
    final textPainter2 = TextPainter(
      text: const TextSpan(
        text: 'Meter Flow Pulse Train (T_M, N=Whole Pulses):',
        style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter2.paint(canvas, const Offset(10, 72));

    final pulseY = 96.0;
    final pulseStep = (size.width - 40) / 20.0;
    final pulsePath = Path()..moveTo(10, pulseY + 14);

    for (int i = 0; i < 20; i++) {
      final curX = 15.0 + (i * pulseStep);
      pulsePath.lineTo(curX, pulseY + 14);
      pulsePath.lineTo(curX, pulseY);
      pulsePath.lineTo(curX + (pulseStep * 0.5), pulseY);
      pulsePath.lineTo(curX + (pulseStep * 0.5), pulseY + 14);
    }
    canvas.drawPath(pulsePath, pulsePaint..style = PaintingStyle.stroke);

    // Vertical alignment markers showing fractional interpolation
    canvas.drawLine(Offset(startX, 15), Offset(startX, 120), linePaint);
    canvas.drawLine(Offset(endX, 15), Offset(endX, 120), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
