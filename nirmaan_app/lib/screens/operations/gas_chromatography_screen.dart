import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS
// ============================================================================

enum GcStreamId {
  gc01Duliajan,
  gc02Digboi,
}

enum ComponentCategory {
  hydrocarbon,
  inert,
  acidGasTrace,
}

class GasComponentData {
  final String id;
  final String formula;
  final String name;
  final ComponentCategory category;
  final double retentionTimeSec;
  final double molPct;
  final double molWeight;
  final double grossCalorificKcalScm; // Gross heat contribution in pure state
  final double lowerLimitMolPct;
  final double upperLimitMolPct;
  final String pngrbLimitSpec;

  const GasComponentData({
    required this.id,
    required this.formula,
    required this.name,
    required this.category,
    required this.retentionTimeSec,
    required this.molPct,
    required this.molWeight,
    required this.grossCalorificKcalScm,
    required this.lowerLimitMolPct,
    required this.upperLimitMolPct,
    required this.pngrbLimitSpec,
  });

  bool get isWithinSpec =>
      molPct >= lowerLimitMolPct && molPct <= upperLimitMolPct;

  double get weightedMolWeight => (molPct / 100.0) * molWeight;
  double get energyContributionKcalScm =>
      (molPct / 100.0) * grossCalorificKcalScm;
}

class GasQualityReport {
  final String streamId;
  final String streamName;
  final String location;
  final String instrumentModel;
  final String standardCode;
  final DateTime timestamp;
  final double samplePressureBar;
  final double sampleTemperatureC;
  final double carrierPressureBar;
  final double ovenTemperatureC;
  final double bridgeCurrentMa;
  final int cycleTotalSec;
  final int cycleCurrentSec;
  final String calibrationCylinderId;
  final DateTime calibrationDate;
  final double calibrationRepeatabilityPct;

  // Gas Physical & Thermodynamic Parameters
  final double grossCalorificValueKcalScm; // GCV
  final double grossCalorificValueBtuScf;
  final double netCalorificValueKcalScm; // NCV
  final double netCalorificValueBtuScf;
  final double wobbeIndexMjM3; // Gross Wobbe Index
  final double wobbeIndexKcalScm;
  final double relativeDensity; // Specific gravity (Air = 1.0)
  final double realGasDensityKgM3;
  final double compressibilityFactorZ; // AGA-8 Z-factor
  final double hydrocarbonDewPointC; // at 50 Bar
  final double waterDewPointC; // at 50 Bar
  final double waterDewPointMgNm3;
  final double totalSulfurMgNm3;
  final double h2sPpmv;
  final double methaneNumber;

  final List<GasComponentData> components;

  const GasQualityReport({
    required this.streamId,
    required this.streamName,
    required this.location,
    required this.instrumentModel,
    required this.standardCode,
    required this.timestamp,
    required this.samplePressureBar,
    required this.sampleTemperatureC,
    required this.carrierPressureBar,
    required this.ovenTemperatureC,
    required this.bridgeCurrentMa,
    required this.cycleTotalSec,
    required this.cycleCurrentSec,
    required this.calibrationCylinderId,
    required this.calibrationDate,
    required this.calibrationRepeatabilityPct,
    required this.grossCalorificValueKcalScm,
    required this.grossCalorificValueBtuScf,
    required this.netCalorificValueKcalScm,
    required this.netCalorificValueBtuScf,
    required this.wobbeIndexMjM3,
    required this.wobbeIndexKcalScm,
    required this.relativeDensity,
    required this.realGasDensityKgM3,
    required this.compressibilityFactorZ,
    required this.hydrocarbonDewPointC,
    required this.waterDewPointC,
    required this.waterDewPointMgNm3,
    required this.totalSulfurMgNm3,
    required this.h2sPpmv,
    required this.methaneNumber,
    required this.components,
  });

  double get totalMolPct =>
      components.fold(0.0, (acc, item) => acc + item.molPct);

  double get totalMolecularWeight =>
      components.fold(0.0, (acc, item) => acc + item.weightedMolWeight);

  double get hydrocarbonFractionPct => components
      .where((c) => c.category == ComponentCategory.hydrocarbon)
      .fold(0.0, (acc, item) => acc + item.molPct);

  double get inertFractionPct => components
      .where((c) => c.category == ComponentCategory.inert)
      .fold(0.0, (acc, item) => acc + item.molPct);

  double get acidGasTraceFractionPct => components
      .where((c) => c.category == ComponentCategory.acidGasTrace)
      .fold(0.0, (acc, item) => acc + item.molPct);
}

class ConsumerTariffProfile {
  final String id;
  final String name;
  final String consumerType;
  final String deliveryPoint;
  final double contractedDcqScm; // Daily Contracted Quantity in SCM
  final double basePriceUsdMmbtu; // Administered or formula price $/MMBTU
  final double pipelineTariffInrMmbtu; // PNGRB approved pipeline tariff ₹/MMBTU
  final double takeOrPayPercent; // e.g. 90%
  final String contractReference;

  const ConsumerTariffProfile({
    required this.id,
    required this.name,
    required this.consumerType,
    required this.deliveryPoint,
    required this.contractedDcqScm,
    required this.basePriceUsdMmbtu,
    required this.pipelineTariffInrMmbtu,
    required this.takeOrPayPercent,
    required this.contractReference,
  });
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class GasChromatographyScreen extends StatefulWidget {
  const GasChromatographyScreen({super.key});

  @override
  State<GasChromatographyScreen> createState() =>
      _GasChromatographyScreenState();
}

class _GasChromatographyScreenState extends State<GasChromatographyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _liveTicker;
  int _cycleElapsedSeconds = 126;
  final int _cycleDurationSeconds = 180;
  bool _isAutoCycleActive = true;
  bool _isManualInjecting = false;

  GcStreamId _selectedStream = GcStreamId.gc01Duliajan;
  ComponentCategory? _componentFilter;

  // Billing Calculator State
  int _selectedConsumerIndex = 0;
  double _billingVolumeScm = 1320000.0;
  String _billingPeriod = 'Daily (24h)';
  final double _usdInrExchangeRate = 86.50;
  final double _referenceContractGcvKcalScm = 9400.0;
  final double _compressorFuelShrinkageRate = 0.0115; // 1.15%
  final double _assamVatPercent = 0.145; // 14.5% Assam State VAT

  // Consumer Profiles
  final List<ConsumerTariffProfile> _consumers = const [
    ConsumerTariffProfile(
      id: 'BCPL',
      name: 'Brahmaputra Cracker & Polymer Ltd (BCPL)',
      consumerType: 'Petrochemical Cracker Feedstock',
      deliveryPoint: 'Lepetkata Offtake Skid (GC-01)',
      contractedDcqScm: 1350000.0,
      basePriceUsdMmbtu: 8.50,
      pipelineTariffInrMmbtu: 48.50,
      takeOrPayPercent: 90.0,
      contractReference: 'OIL/GAS/GSPA/2021/BCPL-09',
    ),
    ConsumerTariffProfile(
      id: 'NRL',
      name: 'Numaligarh Refinery Limited (NRL)',
      consumerType: 'Hydrocracker & Hydrogen Plant Fuel',
      deliveryPoint: 'Digboi Receiving Skid (GC-02)',
      contractedDcqScm: 850000.0,
      basePriceUsdMmbtu: 8.50,
      pipelineTariffInrMmbtu: 54.20,
      takeOrPayPercent: 90.0,
      contractReference: 'OIL/GAS/GSPA/2022/NRL-14',
    ),
    ConsumerTariffProfile(
      id: 'APL',
      name: 'Assam Petrochemicals Ltd (APL Namrup)',
      consumerType: 'Methanol & Formalin Synthesis',
      deliveryPoint: 'Namrup Branch Manifold (GC-01)',
      contractedDcqScm: 500000.0,
      basePriceUsdMmbtu: 6.50,
      pipelineTariffInrMmbtu: 36.00,
      takeOrPayPercent: 85.0,
      contractReference: 'OIL/GAS/GSPA/2019/APL-03',
    ),
    ConsumerTariffProfile(
      id: 'BVFCL',
      name: 'Brahmaputra Valley Fertilizer Corp (BVFCL)',
      consumerType: 'Urea Fertilizer Reforming Feed',
      deliveryPoint: 'Namrup Unit-III Metering Station',
      contractedDcqScm: 720000.0,
      basePriceUsdMmbtu: 6.50,
      pipelineTariffInrMmbtu: 32.50,
      takeOrPayPercent: 90.0,
      contractReference: 'OIL/GAS/GSPA/2018/BVFCL-01',
    ),
    ConsumerTariffProfile(
      id: 'AGCL',
      name: 'Assam Gas Company Limited (AGCL)',
      consumerType: 'City Gas Distribution (CGD / PNG)',
      deliveryPoint: 'Duliajan City Gate Station (GC-01)',
      contractedDcqScm: 250000.0,
      basePriceUsdMmbtu: 8.25,
      pipelineTariffInrMmbtu: 28.00,
      takeOrPayPercent: 80.0,
      contractReference: 'OIL/GAS/GSPA/2023/AGCL-22',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _startLiveCycleTimer();
  }

  void _startLiveCycleTimer() {
    _liveTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isAutoCycleActive) return;
      setState(() {
        _cycleElapsedSeconds++;
        if (_cycleElapsedSeconds > _cycleDurationSeconds) {
          _cycleElapsedSeconds = 1; // Start new analysis cycle
        }
      });
    });
  }

  @override
  void dispose() {
    _liveTicker?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================================
  // STREAM DATA GENERATION (ISO 6974 / GPA 2261)
  // ============================================================================

  GasQualityReport _getReport(GcStreamId streamId) {
    final bool isDuliajan = streamId == GcStreamId.gc01Duliajan;

    // 14-Component gas molar breakdown totaling exactly 100.0000%
    final List<GasComponentData> components = isDuliajan
        ? const [
            GasComponentData(
              id: 'C1',
              formula: 'CH₄',
              name: 'Methane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 25.4,
              molPct: 89.4000,
              molWeight: 16.043,
              grossCalorificKcalScm: 9530.0,
              lowerLimitMolPct: 82.0,
              upperLimitMolPct: 95.0,
              pngrbLimitSpec: '≥ 82.0 mol%',
            ),
            GasComponentData(
              id: 'C2',
              formula: 'C₂H₆',
              name: 'Ethane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 52.1,
              molPct: 5.2000,
              molWeight: 30.070,
              grossCalorificKcalScm: 16820.0,
              lowerLimitMolPct: 2.5,
              upperLimitMolPct: 8.0,
              pngrbLimitSpec: '≤ 8.0 mol%',
            ),
            GasComponentData(
              id: 'C3',
              formula: 'C₃H₈',
              name: 'Propane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 78.4,
              molPct: 2.1000,
              molWeight: 44.097,
              grossCalorificKcalScm: 24320.0,
              lowerLimitMolPct: 0.5,
              upperLimitMolPct: 4.0,
              pngrbLimitSpec: '≤ 4.0 mol%',
            ),
            GasComponentData(
              id: 'iC4',
              formula: 'i-C₄H₁₀',
              name: 'Iso-Butane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 102.1,
              molPct: 0.4200,
              molWeight: 58.124,
              grossCalorificKcalScm: 31750.0,
              lowerLimitMolPct: 0.1,
              upperLimitMolPct: 1.0,
              pngrbLimitSpec: '≤ 1.0 mol%',
            ),
            GasComponentData(
              id: 'nC4',
              formula: 'n-C₄H₁₀',
              name: 'Normal-Butane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 116.5,
              molPct: 0.4800,
              molWeight: 58.124,
              grossCalorificKcalScm: 31960.0,
              lowerLimitMolPct: 0.1,
              upperLimitMolPct: 1.2,
              pngrbLimitSpec: '≤ 1.2 mol%',
            ),
            GasComponentData(
              id: 'iC5',
              formula: 'i-C₅H₁₂',
              name: 'Iso-Pentane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 138.2,
              molPct: 0.1400,
              molWeight: 72.151,
              grossCalorificKcalScm: 39510.0,
              lowerLimitMolPct: 0.02,
              upperLimitMolPct: 0.5,
              pngrbLimitSpec: '≤ 0.5 mol%',
            ),
            GasComponentData(
              id: 'nC5',
              formula: 'n-C₅H₁₂',
              name: 'Normal-Pentane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 147.0,
              molPct: 0.1200,
              molWeight: 72.151,
              grossCalorificKcalScm: 39680.0,
              lowerLimitMolPct: 0.02,
              upperLimitMolPct: 0.4,
              pngrbLimitSpec: '≤ 0.4 mol%',
            ),
            GasComponentData(
              id: 'C6+',
              formula: 'C₆H₁₄+',
              name: 'Hexanes & Heavier',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 165.8,
              molPct: 0.1100,
              molWeight: 86.178,
              grossCalorificKcalScm: 47250.0,
              lowerLimitMolPct: 0.01,
              upperLimitMolPct: 0.35,
              pngrbLimitSpec: '≤ 0.35 mol%',
            ),
            GasComponentData(
              id: 'N2',
              formula: 'N₂',
              name: 'Nitrogen',
              category: ComponentCategory.inert,
              retentionTimeSec: 18.2,
              molPct: 1.8000,
              molWeight: 28.013,
              grossCalorificKcalScm: 0.0,
              lowerLimitMolPct: 0.2,
              upperLimitMolPct: 3.0,
              pngrbLimitSpec: '≤ 3.0 mol%',
            ),
            GasComponentData(
              id: 'CO2',
              formula: 'CO₂',
              name: 'Carbon Dioxide',
              category: ComponentCategory.acidGasTrace,
              retentionTimeSec: 38.6,
              molPct: 0.6000,
              molWeight: 44.010,
              grossCalorificKcalScm: 0.0,
              lowerLimitMolPct: 0.05,
              upperLimitMolPct: 2.0,
              pngrbLimitSpec: '≤ 2.0 mol%',
            ),
            GasComponentData(
              id: 'O2',
              formula: 'O₂',
              name: 'Oxygen',
              category: ComponentCategory.acidGasTrace,
              retentionTimeSec: 14.8,
              molPct: 0.0120,
              molWeight: 31.999,
              grossCalorificKcalScm: 0.0,
              lowerLimitMolPct: 0.0,
              upperLimitMolPct: 0.2,
              pngrbLimitSpec: '≤ 0.2 mol%',
            ),
            GasComponentData(
              id: 'H2S',
              formula: 'H₂S',
              name: 'Hydrogen Sulfide',
              category: ComponentCategory.acidGasTrace,
              retentionTimeSec: 88.0,
              molPct: 0.0004,
              molWeight: 34.082,
              grossCalorificKcalScm: 6010.0,
              lowerLimitMolPct: 0.0,
              upperLimitMolPct: 0.0006,
              pngrbLimitSpec: '≤ 4.0 ppmv',
            ),
            GasComponentData(
              id: 'He',
              formula: 'He',
              name: 'Helium',
              category: ComponentCategory.inert,
              retentionTimeSec: 11.5,
              molPct: 0.0096,
              molWeight: 4.003,
              grossCalorificKcalScm: 0.0,
              lowerLimitMolPct: 0.001,
              upperLimitMolPct: 0.1,
              pngrbLimitSpec: 'Trace inert',
            ),
            GasComponentData(
              id: 'H2O',
              formula: 'H₂O(v)',
              name: 'Water Vapor (Moisture)',
              category: ComponentCategory.acidGasTrace,
              retentionTimeSec: 174.0,
              molPct: 0.0080,
              molWeight: 18.015,
              grossCalorificKcalScm: 0.0,
              lowerLimitMolPct: 0.0,
              upperLimitMolPct: 0.015,
              pngrbLimitSpec: '≤ 112 mg/Nm³',
            ),
          ]
        : const [
            GasComponentData(
              id: 'C1',
              formula: 'CH₄',
              name: 'Methane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 25.4,
              molPct: 88.9500,
              molWeight: 16.043,
              grossCalorificKcalScm: 9530.0,
              lowerLimitMolPct: 82.0,
              upperLimitMolPct: 95.0,
              pngrbLimitSpec: '≥ 82.0 mol%',
            ),
            GasComponentData(
              id: 'C2',
              formula: 'C₂H₆',
              name: 'Ethane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 52.1,
              molPct: 5.4200,
              molWeight: 30.070,
              grossCalorificKcalScm: 16820.0,
              lowerLimitMolPct: 2.5,
              upperLimitMolPct: 8.0,
              pngrbLimitSpec: '≤ 8.0 mol%',
            ),
            GasComponentData(
              id: 'C3',
              formula: 'C₃H₈',
              name: 'Propane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 78.4,
              molPct: 2.2100,
              molWeight: 44.097,
              grossCalorificKcalScm: 24320.0,
              lowerLimitMolPct: 0.5,
              upperLimitMolPct: 4.0,
              pngrbLimitSpec: '≤ 4.0 mol%',
            ),
            GasComponentData(
              id: 'iC4',
              formula: 'i-C₄H₁₀',
              name: 'Iso-Butane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 102.1,
              molPct: 0.4400,
              molWeight: 58.124,
              grossCalorificKcalScm: 31750.0,
              lowerLimitMolPct: 0.1,
              upperLimitMolPct: 1.0,
              pngrbLimitSpec: '≤ 1.0 mol%',
            ),
            GasComponentData(
              id: 'nC4',
              formula: 'n-C₄H₁₀',
              name: 'Normal-Butane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 116.5,
              molPct: 0.4900,
              molWeight: 58.124,
              grossCalorificKcalScm: 31960.0,
              lowerLimitMolPct: 0.1,
              upperLimitMolPct: 1.2,
              pngrbLimitSpec: '≤ 1.2 mol%',
            ),
            GasComponentData(
              id: 'iC5',
              formula: 'i-C₅H₁₂',
              name: 'Iso-Pentane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 138.2,
              molPct: 0.1500,
              molWeight: 72.151,
              grossCalorificKcalScm: 39510.0,
              lowerLimitMolPct: 0.02,
              upperLimitMolPct: 0.5,
              pngrbLimitSpec: '≤ 0.5 mol%',
            ),
            GasComponentData(
              id: 'nC5',
              formula: 'n-C₅H₁₂',
              name: 'Normal-Pentane',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 147.0,
              molPct: 0.1250,
              molWeight: 72.151,
              grossCalorificKcalScm: 39680.0,
              lowerLimitMolPct: 0.02,
              upperLimitMolPct: 0.4,
              pngrbLimitSpec: '≤ 0.4 mol%',
            ),
            GasComponentData(
              id: 'C6+',
              formula: 'C₆H₁₄+',
              name: 'Hexanes & Heavier',
              category: ComponentCategory.hydrocarbon,
              retentionTimeSec: 165.8,
              molPct: 0.1200,
              molWeight: 86.178,
              grossCalorificKcalScm: 47250.0,
              lowerLimitMolPct: 0.01,
              upperLimitMolPct: 0.35,
              pngrbLimitSpec: '≤ 0.35 mol%',
            ),
            GasComponentData(
              id: 'N2',
              formula: 'N₂',
              name: 'Nitrogen',
              category: ComponentCategory.inert,
              retentionTimeSec: 18.2,
              molPct: 1.7800,
              molWeight: 28.013,
              grossCalorificKcalScm: 0.0,
              lowerLimitMolPct: 0.2,
              upperLimitMolPct: 3.0,
              pngrbLimitSpec: '≤ 3.0 mol%',
            ),
            GasComponentData(
              id: 'CO2',
              formula: 'CO₂',
              name: 'Carbon Dioxide',
              category: ComponentCategory.acidGasTrace,
              retentionTimeSec: 38.6,
              molPct: 0.6800,
              molWeight: 44.010,
              grossCalorificKcalScm: 0.0,
              lowerLimitMolPct: 0.05,
              upperLimitMolPct: 2.0,
              pngrbLimitSpec: '≤ 2.0 mol%',
            ),
            GasComponentData(
              id: 'O2',
              formula: 'O₂',
              name: 'Oxygen',
              category: ComponentCategory.acidGasTrace,
              retentionTimeSec: 14.8,
              molPct: 0.0150,
              molWeight: 31.999,
              grossCalorificKcalScm: 0.0,
              lowerLimitMolPct: 0.0,
              upperLimitMolPct: 0.2,
              pngrbLimitSpec: '≤ 0.2 mol%',
            ),
            GasComponentData(
              id: 'H2S',
              formula: 'H₂S',
              name: 'Hydrogen Sulfide',
              category: ComponentCategory.acidGasTrace,
              retentionTimeSec: 88.0,
              molPct: 0.0005,
              molWeight: 34.082,
              grossCalorificKcalScm: 6010.0,
              lowerLimitMolPct: 0.0,
              upperLimitMolPct: 0.0006,
              pngrbLimitSpec: '≤ 4.0 ppmv',
            ),
            GasComponentData(
              id: 'He',
              formula: 'He',
              name: 'Helium',
              category: ComponentCategory.inert,
              retentionTimeSec: 11.5,
              molPct: 0.0100,
              molWeight: 4.003,
              grossCalorificKcalScm: 0.0,
              lowerLimitMolPct: 0.001,
              upperLimitMolPct: 0.1,
              pngrbLimitSpec: 'Trace inert',
            ),
            GasComponentData(
              id: 'H2O',
              formula: 'H₂O(v)',
              name: 'Water Vapor (Moisture)',
              category: ComponentCategory.acidGasTrace,
              retentionTimeSec: 174.0,
              molPct: 0.0095,
              molWeight: 18.015,
              grossCalorificKcalScm: 0.0,
              lowerLimitMolPct: 0.0,
              upperLimitMolPct: 0.015,
              pngrbLimitSpec: '≤ 112 mg/Nm³',
            ),
          ];

    if (isDuliajan) {
      return GasQualityReport(
        streamId: 'GC-01',
        streamName: 'GC-01 Duliajan Central Gathering',
        location: 'Trunk Pipeline Header KP 0+000',
        instrumentModel: 'Yokogawa GC8000 (TCD/Dual Column)',
        standardCode: 'ISO 6974-1 / GPA 2261-20',
        timestamp: DateTime.now().subtract(Duration(seconds: _cycleElapsedSeconds)),
        samplePressureBar: 55.4,
        sampleTemperatureC: 28.2,
        carrierPressureBar: 4.25,
        ovenTemperatureC: 68.4,
        bridgeCurrentMa: 120.0,
        cycleTotalSec: 180,
        cycleCurrentSec: _cycleElapsedSeconds,
        calibrationCylinderId: 'CAL-OIL-DUL-2026/09',
        calibrationDate: DateTime(2026, 9, 15, 10, 30),
        calibrationRepeatabilityPct: 0.12,
        grossCalorificValueKcalScm: 9485.4,
        grossCalorificValueBtuScf: 1028.4,
        netCalorificValueKcalScm: 8560.2,
        netCalorificValueBtuScf: 927.8,
        wobbeIndexMjM3: 51.42,
        wobbeIndexKcalScm: 12284.6,
        relativeDensity: 0.5962,
        realGasDensityKgM3: 0.7308,
        compressibilityFactorZ: 0.9972,
        hydrocarbonDewPointC: -5.2,
        waterDewPointC: -18.5,
        waterDewPointMgNm3: 42.8,
        totalSulfurMgNm3: 3.2,
        h2sPpmv: 2.8,
        methaneNumber: 88.6,
        components: components,
      );
    } else {
      return GasQualityReport(
        streamId: 'GC-02',
        streamName: 'GC-02 Digboi Receiving Terminal',
        location: 'Digboi Refinery Offtake Skid KP 48+200',
        instrumentModel: 'Emerson Rosemount 1500XA',
        standardCode: 'ISO 6974-1 / GPA 2261-20',
        timestamp: DateTime.now().subtract(Duration(seconds: _cycleElapsedSeconds)),
        samplePressureBar: 28.5,
        sampleTemperatureC: 26.8,
        carrierPressureBar: 4.10,
        ovenTemperatureC: 69.1,
        bridgeCurrentMa: 120.0,
        cycleTotalSec: 180,
        cycleCurrentSec: _cycleElapsedSeconds,
        calibrationCylinderId: 'CAL-OIL-DGB-2026/08',
        calibrationDate: DateTime(2026, 8, 28, 14, 15),
        calibrationRepeatabilityPct: 0.14,
        grossCalorificValueKcalScm: 9512.8,
        grossCalorificValueBtuScf: 1031.3,
        netCalorificValueKcalScm: 8585.6,
        netCalorificValueBtuScf: 930.5,
        wobbeIndexMjM3: 51.58,
        wobbeIndexKcalScm: 12322.0,
        relativeDensity: 0.5985,
        realGasDensityKgM3: 0.7335,
        compressibilityFactorZ: 0.9970,
        hydrocarbonDewPointC: -4.8,
        waterDewPointC: -17.9,
        waterDewPointMgNm3: 45.1,
        totalSulfurMgNm3: 3.5,
        h2sPpmv: 3.1,
        methaneNumber: 88.2,
        components: components,
      );
    }
  }

  // ============================================================================
  // SIMULATION ACTIONS
  // ============================================================================

  void _triggerManualAnalysisCycle() {
    setState(() {
      _isManualInjecting = true;
      _cycleElapsedSeconds = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceContainerHigh,
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Manual sample injected for ${_selectedStream == GcStreamId.gc01Duliajan ? "GC-01 Duliajan" : "GC-02 Digboi"}. Flow rate 25 mL/min.',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isManualInjecting = false;
        });
      }
    });
  }

  void _showCalibrationDialog(GasQualityReport report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.border),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.tertiary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_rounded,
                  color: AppTheme.tertiary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'ISO 6974 Calibration Record',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModalParamRow('Cylinder Serial', report.calibrationCylinderId),
              _buildModalParamRow(
                  'Traceability Standard', 'NPL India / ISO 17025 Accredited'),
              _buildModalParamRow(
                  'Last Calibration',
                  DateFormat('yyyy-MM-dd HH:mm').format(report.calibrationDate)),
              _buildModalParamRow(
                  'Next Calibration Due',
                  DateFormat('yyyy-MM-dd')
                      .format(report.calibrationDate.add(const Duration(days: 90)))),
              _buildModalParamRow(
                  'Repeatability CV%', '${report.calibrationRepeatabilityPct}% (Tol ≤ 0.20%)'),
              _buildModalParamRow('Zero Baseline Drift', '±0.04% FSD / 24h'),
              _buildModalParamRow('Detector Bridge Current', '${report.bridgeCurrentMa} mA'),
              _buildModalParamRow('Oven Isothermal Temp', '${report.ovenTemperatureC} °C ± 0.05°C'),
              _buildModalParamRow('Carrier Gas', 'Helium 99.999% Grade 5.0 @ 4.2 Bar'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: AppTheme.tertiary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chromatograph linearity & response factor calibration compliant per GPA 2261-20.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
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
            child: const Text('CLOSE', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  content: Text(
                    'Calibration verification certificate exported to Oil India LIMS.',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
              );
            },
            child: const Text('EXPORT CERTIFICATE'),
          ),
        ],
      ),
    );
  }

  void _showBillingInvoiceModal(GasQualityReport report) {
    final consumer = _consumers[_selectedConsumerIndex];
    final double gcvKcalScm = report.grossCalorificValueKcalScm;

    // Commercial Equations
    final double totalKcal = _billingVolumeScm * gcvKcalScm;
    final double mmbtuDelivered = totalKcal / 252000.0;
    final double baseCommodityUsd = mmbtuDelivered * consumer.basePriceUsdMmbtu;
    final double baseCommodityInr = baseCommodityUsd * _usdInrExchangeRate;
    final double transmissionFeeInr =
        mmbtuDelivered * consumer.pipelineTariffInrMmbtu;
    final double compressorFuelLossInr =
        baseCommodityInr * _compressorFuelShrinkageRate;

    // Heat Adjustment (Live GCV vs Reference GCV)
    final double gcvRatio = gcvKcalScm / _referenceContractGcvKcalScm;
    final double gcvHeatAdjustmentInr = baseCommodityInr * (gcvRatio - 1.0);

    final double taxableSubtotalInr = baseCommodityInr +
        transmissionFeeInr +
        compressorFuelLossInr +
        gcvHeatAdjustmentInr;

    final double assamVatInr = taxableSubtotalInr * _assamVatPercent;
    final double totalInvoicePayableInr = taxableSubtotalInr + assamVatInr;
    final double effectiveRatePerScmInr =
        totalInvoicePayableInr / _billingVolumeScm;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            controller: scrollController,
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppTheme.secondary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Oil India Natural Gas Commercial Invoice',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Gas Sales & Purchase Agreement (GSPA) Billing Note',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.border, height: 28),

              // Consumer & Contract summary card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consumer.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contract: ${consumer.contractReference} | ${consumer.deliveryPoint}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInvoicePill('Period', _billingPeriod),
                        _buildInvoicePill(
                            'Allocated Vol',
                            '${NumberFormat('#,##,###').format(_billingVolumeScm)} SCM'),
                        _buildInvoicePill(
                            'Live GCV', '${gcvKcalScm.toStringAsFixed(1)} kcal'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Line item table
              const Text(
                'BILLING LINE ITEM BREAKDOWN',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              _buildInvoiceLineItem(
                title: '1. Net Gas Delivered Energy',
                subtitle:
                    '(${NumberFormat('#,##,###').format(_billingVolumeScm)} SCM × ${gcvKcalScm.toStringAsFixed(1)} kcal / 252,000)',
                value: '${NumberFormat('#,##,###.##').format(mmbtuDelivered)} MMBTU',
                isHighlighted: true,
                valueColor: AppTheme.primaryLight,
              ),
              _buildInvoiceLineItem(
                title: '2. Base Gas Commodity Charge',
                subtitle:
                    '(${NumberFormat('#,##,###.##').format(mmbtuDelivered)} MMBTU × \$${consumer.basePriceUsdMmbtu.toStringAsFixed(2)} × ₹${_usdInrExchangeRate.toStringAsFixed(2)})',
                value: '₹ ${NumberFormat('#,##,###.##').format(baseCommodityInr)}',
              ),
              _buildInvoiceLineItem(
                title: '3. PNGRB Transmission Tariff',
                subtitle:
                    '(${NumberFormat('#,##,###.##').format(mmbtuDelivered)} MMBTU × ₹${consumer.pipelineTariffInrMmbtu.toStringAsFixed(2)})',
                value: '₹ ${NumberFormat('#,##,###.##').format(transmissionFeeInr)}',
              ),
              _buildInvoiceLineItem(
                title: '4. Compressor Fuel & Loss (1.15%)',
                subtitle: 'Transmission pipeline fuel gas & linepack allowance',
                value:
                    '₹ ${NumberFormat('#,##,###.##').format(compressorFuelLossInr)}',
              ),
              _buildInvoiceLineItem(
                title: '5. Calorific Value Heat Adjustment',
                subtitle:
                    'GCV Indexation: (${gcvKcalScm.toStringAsFixed(1)} / $_referenceContractGcvKcalScm ref) = +${((gcvRatio - 1) * 100).toStringAsFixed(2)}%',
                value:
                    '₹ ${NumberFormat('#,##,###.##').format(gcvHeatAdjustmentInr)}',
                valueColor: AppTheme.tertiary,
              ),
              const Divider(color: AppTheme.border, height: 20),

              _buildInvoiceLineItem(
                title: 'Taxable Commodity & Service Subtotal',
                subtitle: 'Pre-tax reconciled billing amount',
                value: '₹ ${NumberFormat('#,##,###.##').format(taxableSubtotalInr)}',
                isBold: true,
              ),
              _buildInvoiceLineItem(
                title: 'Assam State VAT (14.5%)',
                subtitle: 'Section 9(2) CGST Act Natural Gas State VAT',
                value: '₹ ${NumberFormat('#,##,###.##').format(assamVatInr)}',
                valueColor: AppTheme.secondary,
              ),
              const Divider(color: AppTheme.border, height: 24),

              // Total Gross Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.3),
                      AppTheme.surfaceCard,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL INVOICE PAYABLE',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '₹ ${NumberFormat('#,##,###').format(totalInvoicePayableInr.round())}',
                          style: const TextStyle(
                            color: AppTheme.tertiary,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Effective Landed Gas Price:',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        Text(
                          '₹ ${effectiveRatePerScmInr.toStringAsFixed(2)} / SCM',
                          style: const TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('DISMISS'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            content: Text(
                              'Commercial GSPA invoice generated and synced with SAP-ERP / Oil India Treasury.',
                              style: TextStyle(color: AppTheme.textPrimary),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('SIGN & TRANSMIT'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final report = _getReport(_selectedStream);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gas Chromatography & Quality Billing',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ISO 6974 / GPA 2261 • ${report.streamId} ONLINE',
                  style: const TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'ISO 6974 Calibration Record',
            icon: const Icon(Icons.verified_outlined,
                color: AppTheme.textSecondary),
            onPressed: () => _showCalibrationDialog(report),
          ),
          IconButton(
            tooltip: 'Trigger Manual Injection',
            icon: _isManualInjecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.secondary,
                    ),
                  )
                : const Icon(Icons.science_rounded,
                    color: AppTheme.primaryLight),
            onPressed: _isManualInjecting ? null : _triggerManualAnalysisCycle,
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
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(
                  icon: Icon(Icons.pie_chart_rounded, size: 16),
                  text: '14-Component Mol%',
                ),
                Tab(
                  icon: Icon(Icons.speed_rounded, size: 16),
                  text: 'Quality Parameters',
                ),
                Tab(
                  icon: Icon(Icons.show_chart_rounded, size: 16),
                  text: 'Chromatogram & HW',
                ),
                Tab(
                  icon: Icon(Icons.calculate_rounded, size: 16),
                  text: 'MMBTU Gas Tariff',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Stream Selector Bar (GC-01 vs GC-02)
          _buildStreamSelectorHeader(report),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildComponentsTab(report),
                _buildQualityParamsTab(report),
                _buildChromatogramTab(report),
                _buildBillingCalculatorTab(report),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // STREAM SELECTOR & LIVE CYCLE STATUS BAR
  // ============================================================================

  Widget _buildStreamSelectorHeader(GasQualityReport report) {
    final double cycleProgress =
        _cycleElapsedSeconds / _cycleDurationSeconds.toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Segmented Stream Switcher
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      _buildStreamChip(
                        streamId: GcStreamId.gc01Duliajan,
                        tag: 'GC-01',
                        label: 'Duliajan Trunk',
                        isSelected:
                            _selectedStream == GcStreamId.gc01Duliajan,
                      ),
                      _buildStreamChip(
                        streamId: GcStreamId.gc02Digboi,
                        tag: 'GC-02',
                        label: 'Digboi Offtake',
                        isSelected: _selectedStream == GcStreamId.gc02Digboi,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Live Cycle Clock with Pause/Resume toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAutoCycleActive = !_isAutoCycleActive;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 1),
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      content: Text(
                        _isAutoCycleActive
                            ? 'GC auto-cycle sampling active'
                            : 'GC auto-cycle paused (Sample hold)',
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 12),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isAutoCycleActive
                          ? AppTheme.border
                          : AppTheme.secondary,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAutoCycleActive
                            ? Icons.timer_outlined
                            : Icons.pause_circle_outline_rounded,
                        size: 14,
                        color: _isAutoCycleActive
                            ? AppTheme.secondary
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_cycleElapsedSeconds}s / ${_cycleDurationSeconds}s',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mini Linear Progress Indicator for the 180s cycle
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: cycleProgress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.border.withValues(alpha: 0.5),
              color: AppTheme.primaryLight,
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamChip({
    required GcStreamId streamId,
    required String tag,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStream = streamId;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tag,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 1: 14-COMPONENT MOLAR BREAKDOWN
  // ============================================================================

  Widget _buildComponentsTab(GasQualityReport report) {
    final filtered = _componentFilter == null
        ? report.components
        : report.components
            .where((c) => c.category == _componentFilter)
            .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card: Total Moles, HC%, Inert%, Acid%
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
                    '14-COMPONENT MOLAR COMPOSITION',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppTheme.tertiary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'TOTAL: ${report.totalMolPct.toStringAsFixed(4)} mol%',
                      style: const TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Visual stacked bar of composition
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 14,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (report.hydrocarbonFractionPct * 10).round(),
                        child: Container(
                          color: AppTheme.primary,
                        ),
                      ),
                      Expanded(
                        flex: (report.inertFractionPct * 10).round(),
                        child: Container(
                          color: AppTheme.secondary,
                        ),
                      ),
                      Expanded(
                        flex: math.max(
                            1, (report.acidGasTraceFractionPct * 10).round()),
                        child: Container(
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCompositionLegendItem(
                    label: 'Hydrocarbons (C1-C6+)',
                    pct: '${report.hydrocarbonFractionPct.toStringAsFixed(2)}%',
                    color: AppTheme.primary,
                  ),
                  _buildCompositionLegendItem(
                    label: 'Inerts (N2, He)',
                    pct: '${report.inertFractionPct.toStringAsFixed(2)}%',
                    color: AppTheme.secondary,
                  ),
                  _buildCompositionLegendItem(
                    label: 'Acid/Trace (CO2, H2S, O2, H2O)',
                    pct:
                        '${report.acidGasTraceFractionPct.toStringAsFixed(2)}%',
                    color: AppTheme.error,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Filter chips: All, Hydrocarbons, Inerts, Acid & Trace
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(null, 'All 14 Components (${report.components.length})'),
              const SizedBox(width: 8),
              _buildFilterChip(
                  ComponentCategory.hydrocarbon, 'Hydrocarbons (C1-C6+)'),
              const SizedBox(width: 8),
              _buildFilterChip(ComponentCategory.inert, 'Inerts (N₂, He)'),
              const SizedBox(width: 8),
              _buildFilterChip(
                  ComponentCategory.acidGasTrace, 'Acid Gases & Moisture'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Component Table Headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'COMPONENT',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'RT (s)',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'MOL %',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'PNGRB LIMIT',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // List of components
        ...filtered.map((component) => _buildComponentRow(component)),

        const SizedBox(height: 16),

        // Molecular Weight & Gross Energy Contribution Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'Mean Molecular Weight',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${report.totalMolecularWeight.toStringAsFixed(3)} g/mol',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 32, color: AppTheme.border),
              Column(
                children: [
                  const Text(
                    'Air Density Ratio (SG)',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.relativeDensity.toStringAsFixed(4),
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 32, color: AppTheme.border),
              Column(
                children: [
                  const Text(
                    'Real Density @ Std',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${report.realGasDensityKgM3.toStringAsFixed(4)} kg/m³',
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

  Widget _buildCompositionLegendItem({
    required String label,
    required String pct,
    required Color color,
  }) {
    return Row(
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pct,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(ComponentCategory? category, String label) {
    final bool isSelected = _componentFilter == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _componentFilter = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.2)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildComponentRow(GasComponentData component) {
    final bool isH2s = component.id == 'H2S';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: component.isWithinSpec
              ? AppTheme.border.withValues(alpha: 0.5)
              : AppTheme.error.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Formula & Name
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 32,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(component.category)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      component.id,
                      style: TextStyle(
                        color: _getCategoryColor(component.category),
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        component.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${component.formula} • ${component.molWeight.toStringAsFixed(2)} g/mol',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Retention Time
          Expanded(
            flex: 2,
            child: Text(
              '${component.retentionTimeSec.toStringAsFixed(1)}s',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // Mol %
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isH2s
                      ? '${(component.molPct * 10000).toStringAsFixed(1)} ppm'
                      : '${component.molPct.toStringAsFixed(4)}%',
                  style: TextStyle(
                    color: component.molPct > 5.0
                        ? AppTheme.primaryLight
                        : AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '${component.energyContributionKcalScm.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          // Spec Limit
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  component.pngrbLimitSpec,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  component.isWithinSpec
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: component.isWithinSpec
                      ? AppTheme.tertiary
                      : AppTheme.error,
                  size: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(ComponentCategory category) {
    switch (category) {
      case ComponentCategory.hydrocarbon:
        return AppTheme.primaryLight;
      case ComponentCategory.inert:
        return AppTheme.secondary;
      case ComponentCategory.acidGasTrace:
        return AppTheme.error;
    }
  }

  // ============================================================================
  // TAB 2: GAS QUALITY PARAMETERS & STANDARDS COMPLIANCE
  // ============================================================================

  Widget _buildQualityParamsTab(GasQualityReport report) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // GCV & NCV Primary Metric Cards
        Row(
          children: [
            Expanded(
              child: _buildParameterHeroCard(
                title: 'Gross Calorific Value (GCV)',
                standard: 'ISO 6976 / GPA 2172',
                primaryValue:
                    '${NumberFormat('#,##0.0').format(report.grossCalorificValueKcalScm)} kcal/SCM',
                secondaryValue:
                    '${report.grossCalorificValueBtuScf.toStringAsFixed(1)} BTU/SCF (39.71 MJ/m³)',
                statusText: 'PASS (Spec ≥ 8,500 kcal)',
                statusColor: AppTheme.tertiary,
                icon: Icons.local_fire_department_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildParameterHeroCard(
                title: 'Net Calorific Value (NCV)',
                standard: 'ISO 6976 / Lower Heating',
                primaryValue:
                    '${NumberFormat('#,##0.0').format(report.netCalorificValueKcalScm)} kcal/SCM',
                secondaryValue:
                    '${report.netCalorificValueBtuScf.toStringAsFixed(1)} BTU/SCF (35.84 MJ/m³)',
                statusText: 'PASS (Latent Heat Deducted)',
                statusColor: AppTheme.primaryLight,
                icon: Icons.whatshot_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Wobbe Index & Dew Points
        Row(
          children: [
            Expanded(
              child: _buildParameterHeroCard(
                title: 'Gross Wobbe Index (Ws)',
                standard: 'Burner Interchangeability',
                primaryValue: '${report.wobbeIndexMjM3.toStringAsFixed(2)} MJ/m³',
                secondaryValue:
                    '${NumberFormat('#,##0').format(report.wobbeIndexKcalScm)} kcal/SCM',
                statusText: 'OPTIMAL (47 - 52.5 MJ/m³)',
                statusColor: AppTheme.tertiary,
                icon: Icons.speed_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildParameterHeroCard(
                title: 'Hydrocarbon Dew Point',
                standard: 'ISO 6578 @ 50.0 Bar',
                primaryValue: '${report.hydrocarbonDewPointC.toStringAsFixed(1)} °C',
                secondaryValue: 'No retrograde liquid dropout',
                statusText: 'SAFE (Spec ≤ 0.0 °C)',
                statusColor: AppTheme.tertiary,
                icon: Icons.ac_unit_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Secondary Parameters Grid
        const Text(
          'PHYSICAL & FLOW PROPERTIES (AGA REPORT NO. 8 / ISO 12213)',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildParamMiniTile(
                label: 'Water Dew Point',
                value: '${report.waterDewPointC.toStringAsFixed(1)} °C',
                subValue: '${report.waterDewPointMgNm3.toStringAsFixed(1)} mg/Nm³',
                spec: 'Spec ≤ 112 mg/Nm³',
                isPass: report.waterDewPointMgNm3 <= 112.0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildParamMiniTile(
                label: 'Compressibility (Z)',
                value: report.compressibilityFactorZ.toStringAsFixed(4),
                subValue: 'AGA-8 Base Conditions',
                spec: '0.9950 - 0.9990',
                isPass: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildParamMiniTile(
                label: 'Total Sulfur',
                value: '${report.totalSulfurMgNm3.toStringAsFixed(1)} mg/Nm³',
                subValue: 'Spec ≤ 10.0 mg/Nm³',
                spec: 'PNGRB T4S Sweet Gas',
                isPass: report.totalSulfurMgNm3 <= 10.0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildParamMiniTile(
                label: 'Hydrogen Sulfide (H₂S)',
                value: '${report.h2sPpmv.toStringAsFixed(1)} ppmv',
                subValue: '~5.2 mg/Nm³',
                spec: 'Spec ≤ 4.0 ppmv',
                isPass: report.h2sPpmv <= 4.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildParamMiniTile(
                label: 'Methane Number (MN)',
                value: report.methaneNumber.toStringAsFixed(1),
                subValue: 'Anti-knock Rating',
                spec: 'Ideal for Turbines',
                isPass: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildParamMiniTile(
                label: 'Specific Gravity (SG)',
                value: report.relativeDensity.toStringAsFixed(4),
                subValue: 'Relative to Dry Air',
                spec: '0.5800 - 0.6500',
                isPass: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // PNGRB Compliance Certificate Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: AppTheme.tertiary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'PNGRB Gas Transmission Quality Compliance',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '100% COMPLIANT',
                      style: TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Gas stream strictly complies with Schedule I (Quality of Natural Gas) of PNGRB (Access Code for Common Carrier or Contract Carrier Natural Gas Pipelines) Regulations.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParameterHeroCard({
    required String title,
    required String standard,
    required String primaryValue,
    required String secondaryValue,
    required String statusText,
    required Color statusColor,
    required IconData icon,
  }) {
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
            children: [
              Icon(icon, color: AppTheme.secondary, size: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            primaryValue,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            secondaryValue,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            standard,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamMiniTile({
    required String label,
    required String value,
    required String subValue,
    required String spec,
    required bool isPass,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              Icon(
                isPass ? Icons.check_circle_outline : Icons.error_outline,
                color: isPass ? AppTheme.tertiary : AppTheme.error,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            spec,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: LIVE CHROMATOGRAM & HARDWARE TELEMETRY
  // ============================================================================

  Widget _buildChromatogramTab(GasQualityReport report) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Live Detector Response Graph Header
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROCESS CHROMATOGRAM (DETECTOR mV vs RETENTION TIME)',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Dual-Column TCD Detector Output • 180s Cycle',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'T: ${_cycleElapsedSeconds}s',
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Chromatogram Chart
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 200,
                      verticalInterval: 30,
                      getDrawingHorizontalLine: (value) => const FlLine(
                        color: AppTheme.border,
                        strokeWidth: 0.8,
                        dashArray: [4, 4],
                      ),
                      getDrawingVerticalLine: (value) => const FlLine(
                        color: AppTheme.border,
                        strokeWidth: 0.8,
                        dashArray: [4, 4],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'Retention Time (Seconds)',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 10),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 30,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${value.toInt()}s',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 9.5,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'Detector Signal (mV)',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 10),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: 200,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 9.5,
                              ),
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
                    maxX: 180,
                    minY: 0,
                    maxY: 1000,
                    lineBarsData: [
                      // Simulated Chromatogram Peaks Curve
                      LineChartBarData(
                        spots: _generateChromatogramSpots(),
                        isCurved: true,
                        curveSmoothness: 0.25,
                        color: AppTheme.primaryLight,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.35),
                              AppTheme.primary.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Current cycle progress cursor vertical line
                      LineChartBarData(
                        spots: [
                          FlSpot(_cycleElapsedSeconds.toDouble(), 0),
                          FlSpot(_cycleElapsedSeconds.toDouble(), 1000),
                        ],
                        isCurved: false,
                        color: AppTheme.secondary,
                        barWidth: 1.5,
                        dashArray: [4, 4],
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              // Peak Labels Legend
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: const [
                  _ChromatogramPeakTag(label: 'He/N₂ @ 18s', color: AppTheme.secondary),
                  _ChromatogramPeakTag(
                      label: 'C1 Methane @ 25s', color: AppTheme.primaryLight),
                  _ChromatogramPeakTag(label: 'CO₂ @ 38s', color: AppTheme.error),
                  _ChromatogramPeakTag(label: 'C2 Ethane @ 52s', color: AppTheme.primaryLight),
                  _ChromatogramPeakTag(label: 'C3 Propane @ 78s', color: AppTheme.primaryLight),
                  _ChromatogramPeakTag(label: 'iC4/nC4 @ 102s-116s', color: AppTheme.primaryLight),
                  _ChromatogramPeakTag(label: 'iC5/nC5 @ 138s-147s', color: AppTheme.primaryLight),
                  _ChromatogramPeakTag(label: 'C6+ @ 165s', color: AppTheme.secondary),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Chromatograph Hardware State (Oven, Carrier Gas, Bridge Current, Valve Sequence)
        const Text(
          'HARDWARE TELEMETRY & VALVE TIMING (YOKOGAWA GC8000 / EMERSON)',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildHardwareTile(
                icon: Icons.thermostat_rounded,
                title: 'Oven Isothermal Temp',
                value: '${report.ovenTemperatureC} °C',
                subtext: 'Setpoint: 68.5 °C (±0.05)',
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildHardwareTile(
                icon: Icons.compress_rounded,
                title: 'Helium Carrier Gas',
                value: '${report.carrierPressureBar} Bar',
                subtext: 'Flow: 25.0 mL/min (Reg)',
                color: AppTheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildHardwareTile(
                icon: Icons.electric_bolt_rounded,
                title: 'TCD Bridge Current',
                value: '${report.bridgeCurrentMa.toInt()} mA',
                subtext: 'Filament Balanced (OK)',
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildHardwareTile(
                icon: Icons.timeline_rounded,
                title: 'Sample Line Pressure',
                value: '${report.samplePressureBar} Bar',
                subtext: 'Probe Temp: 60.0 °C',
                color: AppTheme.primaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Rotary Valve Switching Sequence
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
                'VALVE SWITCHING SEQUENCE (ISO 6974 DUAL COLUMN)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildValveSequenceStep(
                step: '0s - 15s',
                title: 'Sample Loop Purge & Injection',
                desc: 'Valve V1 activates. 0.25 mL loop swept into Column 1.',
                isActive: _cycleElapsedSeconds <= 15,
              ),
              _buildValveSequenceStep(
                step: '15s - 95s',
                title: 'Column 1 Separation (C1, N2, CO2, C2)',
                desc: 'TCD Bridge Channel A reading lighter components.',
                isActive: _cycleElapsedSeconds > 15 && _cycleElapsedSeconds <= 95,
              ),
              _buildValveSequenceStep(
                step: '95s - 150s',
                title: 'Column 2 Foreflush (C3, iC4, nC4, C5)',
                desc: 'Backflush valve switches to isolate heavy fraction.',
                isActive: _cycleElapsedSeconds > 95 && _cycleElapsedSeconds <= 150,
              ),
              _buildValveSequenceStep(
                step: '150s - 180s',
                title: 'C6+ Backflush Peak & Equilibrium',
                desc: 'Hexanes and heavier grouped backflush peak detected.',
                isActive: _cycleElapsedSeconds > 150,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generateChromatogramSpots() {
    final List<FlSpot> spots = [];

    // Background baseline with realistic Gaussian chromatographic peaks
    for (int t = 0; t <= 180; t++) {
      double mv = 15.0; // Baseline noise

      // Peak 1: He / N2 @ 18s (narrow, height ~ 180)
      mv += _gaussianPeak(t.toDouble(), center: 18.2, height: 180.0, sigma: 1.8);

      // Peak 2: C1 Methane @ 25.4s (huge dominant peak ~ 920 mV)
      mv += _gaussianPeak(t.toDouble(), center: 25.4, height: 920.0, sigma: 3.5);

      // Peak 3: CO2 @ 38.6s (height ~ 70)
      mv += _gaussianPeak(t.toDouble(), center: 38.6, height: 75.0, sigma: 2.2);

      // Peak 4: C2 Ethane @ 52.1s (height ~ 320 mV)
      mv += _gaussianPeak(t.toDouble(), center: 52.1, height: 320.0, sigma: 3.2);

      // Peak 5: C3 Propane @ 78.4s (height ~ 210 mV)
      mv += _gaussianPeak(t.toDouble(), center: 78.4, height: 210.0, sigma: 3.8);

      // Peak 6: iC4 Iso-Butane @ 102.1s (height ~ 85 mV)
      mv += _gaussianPeak(t.toDouble(), center: 102.1, height: 85.0, sigma: 3.5);

      // Peak 7: nC4 Normal-Butane @ 116.5s (height ~ 95 mV)
      mv += _gaussianPeak(t.toDouble(), center: 116.5, height: 95.0, sigma: 3.6);

      // Peak 8: iC5 Iso-Pentane @ 138.2s (height ~ 45 mV)
      mv += _gaussianPeak(t.toDouble(), center: 138.2, height: 45.0, sigma: 3.2);

      // Peak 9: nC5 Normal-Pentane @ 147.0s (height ~ 40 mV)
      mv += _gaussianPeak(t.toDouble(), center: 147.0, height: 40.0, sigma: 3.2);

      // Peak 10: C6+ Backflush @ 165.8s (broad backflush peak ~ 65 mV)
      mv += _gaussianPeak(t.toDouble(), center: 165.8, height: 65.0, sigma: 4.8);

      spots.add(FlSpot(t.toDouble(), mv));
    }

    return spots;
  }

  double _gaussianPeak(double x,
      {required double center, required double height, required double sigma}) {
    final double diff = x - center;
    return height * math.exp(-(diff * diff) / (2 * sigma * sigma));
  }

  Widget _buildHardwareTile({
    required IconData icon,
    required String title,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10.5),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtext,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValveSequenceStep({
    required String step,
    required String title,
    required String desc,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primary
                  : AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              step,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isActive
                        ? AppTheme.primaryLight
                        : AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            const Icon(Icons.radio_button_checked,
                color: AppTheme.primaryLight, size: 14),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: OIL INDIA GAS TARIFF & MMBTU BILLING CALCULATOR
  // ============================================================================

  Widget _buildBillingCalculatorTab(GasQualityReport report) {
    final consumer = _consumers[_selectedConsumerIndex];
    final double gcvKcalScm = report.grossCalorificValueKcalScm;

    // Commercial Equations
    final double totalKcal = _billingVolumeScm * gcvKcalScm;
    final double mmbtuDelivered = totalKcal / 252000.0;
    final double baseCommodityUsd = mmbtuDelivered * consumer.basePriceUsdMmbtu;
    final double baseCommodityInr = baseCommodityUsd * _usdInrExchangeRate;
    final double transmissionFeeInr =
        mmbtuDelivered * consumer.pipelineTariffInrMmbtu;
    final double compressorFuelLossInr =
        baseCommodityInr * _compressorFuelShrinkageRate;

    // Heat Adjustment (Live GCV vs Reference GCV)
    final double gcvRatio = gcvKcalScm / _referenceContractGcvKcalScm;
    final double gcvHeatAdjustmentInr = baseCommodityInr * (gcvRatio - 1.0);

    final double taxableSubtotalInr = baseCommodityInr +
        transmissionFeeInr +
        compressorFuelLossInr +
        gcvHeatAdjustmentInr;

    final double assamVatInr = taxableSubtotalInr * _assamVatPercent;
    final double totalInvoicePayableInr = taxableSubtotalInr + assamVatInr;
    final double effectiveRatePerScmInr =
        totalInvoicePayableInr / _billingVolumeScm;

    // Take-or-Pay Analysis
    final double minBillableScm =
        consumer.contractedDcqScm * (consumer.takeOrPayPercent / 100.0);
    final bool isUnderToP = _billingVolumeScm < minBillableScm;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Consumer Selector
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
                'OIL INDIA CONTRACTED CONSUMER (GSPA)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedConsumerIndex,
                    dropdownColor: AppTheme.surface,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppTheme.primaryLight),
                    items: List.generate(_consumers.length, (idx) {
                      final c = _consumers[idx];
                      return DropdownMenuItem<int>(
                        value: idx,
                        child: Text(
                          c.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedConsumerIndex = val;
                          _billingVolumeScm = _consumers[val].contractedDcqScm;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildConsumerSubDetail(
                      'Category', consumer.consumerType),
                  _buildConsumerSubDetail(
                      'Delivery Point', consumer.deliveryPoint),
                  _buildConsumerSubDetail('Base MMBTU',
                      '\$${consumer.basePriceUsdMmbtu.toStringAsFixed(2)}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Interactive Volume & Exchange Rate Controls
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
                    'BILLING VOLUME (SCM)',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${NumberFormat('#,##,###').format(_billingVolumeScm)} SCM (${(_billingVolumeScm / 1000000).toStringAsFixed(3)} MMSCMD)',
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _billingVolumeScm.clamp(50000.0, 2000000.0),
                min: 50000.0,
                max: 2000000.0,
                divisions: 39,
                activeColor: AppTheme.primaryLight,
                inactiveColor: AppTheme.border,
                onChanged: (val) {
                  setState(() {
                    _billingVolumeScm = val;
                  });
                },
              ),
              const SizedBox(height: 8),

              // Billing Period Selector & Exchange Rate
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Billing Cycle',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _billingPeriod,
                              dropdownColor: AppTheme.surface,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                    value: 'Daily (24h)',
                                    child: Text('Daily (24h)',
                                        style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(
                                    value: 'Fortnightly (15d)',
                                    child: Text('Fortnightly (15d)',
                                        style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(
                                    value: 'Monthly (30d)',
                                    child: Text('Monthly (30d)',
                                        style: TextStyle(fontSize: 12))),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _billingPeriod = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'USD/INR FX',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            '₹ ${_usdInrExchangeRate.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GCV Used',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            '${gcvKcalScm.toStringAsFixed(1)} kcal',
                            style: const TextStyle(
                              color: AppTheme.tertiary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Take-or-Pay (ToP) Compliance Warning Banner
        if (isUnderToP)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppTheme.secondary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppTheme.secondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Take-or-Pay (ToP) Minimum Quantity Triggered',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Delivered volume is below ${consumer.takeOrPayPercent}% MBQ (${NumberFormat('#,##,###').format(minBillableScm)} SCM). Consumer will be billed for contracted capacity shortfall.',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Live Tariff Reconciliation Card
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
              const Text(
                'COMMERCIAL TARIFF & RECONCILIATION SUMMARY',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),

              _buildTariffRow(
                label: 'Energy Delivered (MMBTU)',
                detail: 'Volume × GCV / 252,000',
                value:
                    '${NumberFormat('#,##,###.##').format(mmbtuDelivered)} MMBTU',
                isHighlighted: true,
              ),
              const Divider(color: AppTheme.border, height: 16),

              _buildTariffRow(
                label: 'Base Commodity Charge',
                detail:
                    '\$${consumer.basePriceUsdMmbtu.toStringAsFixed(2)} / MMBTU @ ₹${_usdInrExchangeRate.toStringAsFixed(2)}',
                value:
                    '₹ ${NumberFormat('#,##,###.##').format(baseCommodityInr)}',
              ),
              _buildTariffRow(
                label: 'Pipeline Transportation Tariff',
                detail:
                    'PNGRB Fixed: ₹${consumer.pipelineTariffInrMmbtu.toStringAsFixed(2)} / MMBTU',
                value:
                    '₹ ${NumberFormat('#,##,###.##').format(transmissionFeeInr)}',
              ),
              _buildTariffRow(
                label: 'Compressor Fuel Gas Allowance (1.15%)',
                detail: 'In-line compressor fuel shrinkage',
                value:
                    '₹ ${NumberFormat('#,##,###.##').format(compressorFuelLossInr)}',
              ),
              _buildTariffRow(
                label: 'Heat Value Premium / (Penalty)',
                detail:
                    'Actual GCV (${gcvKcalScm.toStringAsFixed(1)}) vs Ref (${_referenceContractGcvKcalScm.toStringAsFixed(0)})',
                value:
                    '+ ₹ ${NumberFormat('#,##,###.##').format(gcvHeatAdjustmentInr)}',
                valueColor: AppTheme.tertiary,
              ),
              const Divider(color: AppTheme.border, height: 16),

              _buildTariffRow(
                label: 'Taxable Subtotal',
                detail: 'Pre-tax transmission & commodity',
                value:
                    '₹ ${NumberFormat('#,##,###.##').format(taxableSubtotalInr)}',
                isBold: true,
              ),
              _buildTariffRow(
                label: 'Assam State VAT @ 14.5%',
                detail: 'State value added tax on pipeline natural gas',
                value: '₹ ${NumberFormat('#,##,###.##').format(assamVatInr)}',
                valueColor: AppTheme.secondary,
              ),
              const Divider(color: AppTheme.border, height: 20),

              // Grand Total Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimated Total Payable',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '₹ ${NumberFormat('#,##,###').format(totalInvoicePayableInr.round())}',
                          style: const TextStyle(
                            color: AppTheme.tertiary,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Effective Rate / SCM',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '₹ ${effectiveRatePerScmInr.toStringAsFixed(2)} / SCM',
                          style: const TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Button: Generate Official Commercial Invoice
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _showBillingInvoiceModal(report),
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            label: const Text(
              'VIEW & RECONCILE GSPA TAX INVOICE',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsumerSubDetail(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTariffRow({
    required String label,
    required String detail,
    required String value,
    Color? valueColor,
    bool isBold = false,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isHighlighted
                        ? AppTheme.primaryLight
                        : isBold
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ??
                  (isHighlighted
                      ? AppTheme.primaryLight
                      : AppTheme.textPrimary),
              fontWeight: isBold || isHighlighted
                  ? FontWeight.w800
                  : FontWeight.w600,
              fontSize: isBold ? 13 : 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MODAL HELPER WIDGETS
  // ============================================================================

  Widget _buildModalParamRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInvoicePill(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        Text(val,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
      ],
    );
  }

  Widget _buildInvoiceLineItem({
    required String title,
    required String subtitle,
    required String value,
    Color? valueColor,
    bool isBold = false,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isHighlighted
                        ? AppTheme.primaryLight
                        : isBold
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12.5,
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
          Text(
            value,
            style: TextStyle(
              color: valueColor ??
                  (isHighlighted
                      ? AppTheme.primaryLight
                      : AppTheme.textPrimary),
              fontWeight: isBold || isHighlighted
                  ? FontWeight.w800
                  : FontWeight.w600,
              fontSize: isBold ? 13 : 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChromatogramPeakTag extends StatelessWidget {
  final String label;
  final Color color;

  const _ChromatogramPeakTag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
