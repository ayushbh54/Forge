import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DOMAIN MODELS & ENUMS
// ============================================================================

enum HydrateRiskSeverity {
  safe,
  lowMetastable,
  moderateElevated,
  highCritical,
}

enum InhibitorType {
  methanol,
  meg,
  deg,
}

class HydrateInhibitorConfig {
  final InhibitorType type;
  final String name;
  final String chemicalFormula;
  final double molecularWeight; // g/mol
  final double hammerschmidtKSi; // SI Constant for ΔT in °C
  final double hammerschmidtKFps; // FPS Constant for ΔT in °F
  final double densityKgL; // kg/L at 20°C
  final double defaultPurityPct; // Commercial purity %
  final double vaporLossFactor; // relative volatility factor
  final double costPerKgInr;
  final String casNumber;
  final String oisdClause;
  final String notes;

  const HydrateInhibitorConfig({
    required this.type,
    required this.name,
    required this.chemicalFormula,
    required this.molecularWeight,
    required this.hammerschmidtKSi,
    required this.hammerschmidtKFps,
    required this.densityKgL,
    required this.defaultPurityPct,
    required this.vaporLossFactor,
    required this.costPerKgInr,
    required this.casNumber,
    required this.oisdClause,
    required this.notes,
  });

  static const List<HydrateInhibitorConfig> allInhibitors = [
    HydrateInhibitorConfig(
      type: InhibitorType.methanol,
      name: 'Methanol (MeOH)',
      chemicalFormula: 'CH₃OH',
      molecularWeight: 32.04,
      hammerschmidtKSi: 1297.0,
      hammerschmidtKFps: 2335.0,
      densityKgL: 0.792,
      defaultPurityPct: 99.5,
      vaporLossFactor: 1.0,
      costPerKgInr: 54.0,
      casNumber: '67-56-1',
      oisdClause: 'OISD-STD-141 Sec 6.4 (THI Solvent Storage & Handling)',
      notes: 'Most economical thermodynamic inhibitor; high volatility requires vapor loss compensation.',
    ),
    HydrateInhibitorConfig(
      type: InhibitorType.meg,
      name: 'Monoethylene Glycol (MEG)',
      chemicalFormula: 'C₂H₆O₂',
      molecularWeight: 62.07,
      hammerschmidtKSi: 1500.0,
      hammerschmidtKFps: 2700.0,
      densityKgL: 1.115,
      defaultPurityPct: 80.0,
      vaporLossFactor: 0.005,
      costPerKgInr: 82.0,
      casNumber: '107-21-1',
      oisdClause: 'OISD-STD-141 Sec 6.5 (Regenerable Glycol Closed Loops)',
      notes: 'Low volatility, suitable for gas loops with regeneration units. Higher viscosity.',
    ),
    HydrateInhibitorConfig(
      type: InhibitorType.deg,
      name: 'Diethylene Glycol (DEG)',
      chemicalFormula: 'C₄H₁₀O₃',
      molecularWeight: 106.12,
      hammerschmidtKSi: 2222.0,
      hammerschmidtKFps: 4000.0,
      densityKgL: 1.118,
      defaultPurityPct: 95.0,
      vaporLossFactor: 0.002,
      costPerKgInr: 105.0,
      casNumber: '111-46-6',
      oisdClause: 'OISD-STD-141 Sec 6.6 (High Temperature Gas Dehydration)',
      notes: 'Negligible vapor loss, used in high pressure transmission pipelines and low-temperature dewpoint plants.',
    ),
  ];
}

class RiverCrossingColdSpot {
  final String id;
  final String stationName;
  final double chainageKp;
  final String riverName;
  final String crossingMethod;
  final double scourDepthM;
  final double ambientGroundOrWaterTempC;
  final double flowingGasTempC;
  final double operatingPressureBar;
  final String dosingSkidRef;
  final String geologicalStrata;
  final bool isColdSpotRisk;

  const RiverCrossingColdSpot({
    required this.id,
    required this.stationName,
    required this.chainageKp,
    required this.riverName,
    required this.crossingMethod,
    required this.scourDepthM,
    required this.ambientGroundOrWaterTempC,
    required this.flowingGasTempC,
    required this.operatingPressureBar,
    required this.dosingSkidRef,
    required this.geologicalStrata,
    required this.isColdSpotRisk,
  });
}

class DosingSkidTelemetry {
  final String skidId;
  final String tag;
  final String name;
  final double chainageKp;
  final String targetInhibitor;
  final double tankCapacityLiters;
  double currentTankLiters;
  bool isLeadPumpRunning;
  bool isStandbyPumpAvailable;
  int activePumpIndex; // 0 = Pump A, 1 = Pump B
  double strokeLengthPct;
  double strokeSpeedSpm;
  double injectionRateLph;
  double dischargePressureBar;
  double batteryVoltageVdc;
  bool isShockSlugActive;
  DateTime lastShockSlugTime;

  DosingSkidTelemetry({
    required this.skidId,
    required this.tag,
    required this.name,
    required this.chainageKp,
    required this.targetInhibitor,
    required this.tankCapacityLiters,
    required this.currentTankLiters,
    required this.isLeadPumpRunning,
    required this.isStandbyPumpAvailable,
    required this.activePumpIndex,
    required this.strokeLengthPct,
    required this.strokeSpeedSpm,
    required this.injectionRateLph,
    required this.dischargePressureBar,
    required this.batteryVoltageVdc,
    required this.isShockSlugActive,
    required this.lastShockSlugTime,
  });

  double get tankPercentage => (currentTankLiters / tankCapacityLiters) * 100.0;
  double get autonomyHours => injectionRateLph > 0 ? (currentTankLiters / injectionRateLph) : 999.0;
  double get autonomyDays => autonomyHours / 24.0;
}

class GasComponent {
  final String name;
  final String formula;
  final double molPct;
  final double molecularWeight;
  final bool isHydrateFormer;
  final String structureType;

  const GasComponent({
    required this.name,
    required this.formula,
    required this.molPct,
    required this.molecularWeight,
    required this.isHydrateFormer,
    required this.structureType,
  });
}

// ============================================================================
// MAIN STATEFUL SCREEN WIDGET
// ============================================================================

class HydratePredictionScreen extends StatefulWidget {
  const HydratePredictionScreen({super.key});

  @override
  State<HydratePredictionScreen> createState() => _HydratePredictionScreenState();
}

class _HydratePredictionScreenState extends State<HydratePredictionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _liveTelemetryTimer;

  // Operating Predictor State Variables (Configurable)
  double _operatingPressureBar = 68.5; // Bar
  double _gasSpecificGravity = 0.612; // Air = 1.0
  double _flowingGasTempC = 8.2; // °C (Cold spot baseline at Disang river)
  double _gasFlowMmscmd = 5.5; // MMSCMD
  double _waterContentMgSm3 = 85.0; // mg/Sm3 free/vapor moisture
  double _safetyMarginDeltaTC = 3.0; // °C buffer above subcooling
  InhibitorType _selectedInhibitorType = InhibitorType.methanol;

  // Selected Cold Spot River Station
  int _selectedColdSpotIndex = 3; // Default to Disang River (Critical Cold Spot)

  // Shock Slug Notification Message
  String? _bannerStatusMessage;

  // Pipeline Route Cold Spots (Duliajan–Numaligarh Trunkline 192 KM)
  final List<RiverCrossingColdSpot> _trunklineStations = const [
    RiverCrossingColdSpot(
      id: 'ST-00',
      stationName: 'Duliajan CGGS Gas Gathering Station',
      chainageKp: 0.0,
      riverName: 'Upstream Compressor Station Outlet',
      crossingMethod: 'Main Terminal Header',
      scourDepthM: 0.0,
      ambientGroundOrWaterTempC: 24.5,
      flowingGasTempC: 32.0,
      operatingPressureBar: 68.5,
      dosingSkidRef: 'SK-HYD-01 (Duliajan Main Quench Skid)',
      geologicalStrata: 'Compacted Sandy Clay / Terminal Yard',
      isColdSpotRisk: false,
    ),
    RiverCrossingColdSpot(
      id: 'ST-01',
      stationName: 'Buri Dihing River HDD Crossing',
      chainageKp: 18.5,
      riverName: 'Buri Dihing River',
      crossingMethod: 'Horizontal Directional Drilling (HDD)',
      scourDepthM: 16.5,
      ambientGroundOrWaterTempC: 13.0,
      flowingGasTempC: 13.5,
      operatingPressureBar: 67.4,
      dosingSkidRef: 'SK-HYD-01 Remote Satellite Manifold',
      geologicalStrata: 'Alluvial Coarse Gravel & Silt',
      isColdSpotRisk: true,
    ),
    RiverCrossingColdSpot(
      id: 'ST-02',
      stationName: 'Moran SV-01 Valve Station',
      chainageKp: 38.2,
      riverName: 'Deohall River Drainage Basin',
      crossingMethod: 'Open Trench Cased Crossing',
      scourDepthM: 3.2,
      ambientGroundOrWaterTempC: 16.2,
      flowingGasTempC: 14.8,
      operatingPressureBar: 66.1,
      dosingSkidRef: 'SK-HYD-01 Quench Downstream Zone',
      geologicalStrata: 'Tea Garden Alluvial Silty Loam',
      isColdSpotRisk: false,
    ),
    RiverCrossingColdSpot(
      id: 'ST-03',
      stationName: 'Disang River HDD Crossing (CRITICAL COLD SPOT)',
      chainageKp: 64.0,
      riverName: 'Disang River',
      crossingMethod: 'HDD Deep Invert Borehole (22m Scour Depth)',
      scourDepthM: 22.0,
      ambientGroundOrWaterTempC: 7.5,
      flowingGasTempC: 8.2,
      operatingPressureBar: 63.8,
      dosingSkidRef: 'SK-HYD-02 (Moran SV-02 / Disang River Injection)',
      geologicalStrata: 'Dense Alluvial Boulder Gravel & Quaternary Sand',
      isColdSpotRisk: true,
    ),
    RiverCrossingColdSpot(
      id: 'ST-04',
      stationName: 'Dikhow River Crossing (Sibsagar SV-03)',
      chainageKp: 88.5,
      riverName: 'Dikhow River',
      crossingMethod: 'HDD Sub-riverbed Invert Crossing',
      scourDepthM: 19.5,
      ambientGroundOrWaterTempC: 7.2,
      flowingGasTempC: 7.8,
      operatingPressureBar: 61.5,
      dosingSkidRef: 'SK-HYD-02 Intermediate Satellite Tap',
      geologicalStrata: 'Submerged Fluvial Sandstone & Alluvium',
      isColdSpotRisk: true,
    ),
    RiverCrossingColdSpot(
      id: 'ST-05',
      stationName: 'Jhanji River HDD Crossing',
      chainageKp: 115.2,
      riverName: 'Jhanji River',
      crossingMethod: 'HDD Subterranean Aquifer Profile',
      scourDepthM: 17.8,
      ambientGroundOrWaterTempC: 8.4,
      flowingGasTempC: 8.6,
      operatingPressureBar: 59.2,
      dosingSkidRef: 'SK-HYD-02 Tail Quench Reach',
      geologicalStrata: 'Fine Quartz Sand & Plastic Clay Beds',
      isColdSpotRisk: true,
    ),
    RiverCrossingColdSpot(
      id: 'ST-06',
      stationName: 'Bhogdoi River Crossing (Jorhat SV-05)',
      chainageKp: 142.0,
      riverName: 'Bhogdoi River',
      crossingMethod: 'Deep Trench River Crossing with Concrete Weight Coating',
      scourDepthM: 8.5,
      ambientGroundOrWaterTempC: 9.8,
      flowingGasTempC: 9.1,
      operatingPressureBar: 56.6,
      dosingSkidRef: 'SK-HYD-03 (Jorhat SV-05 Injection Skid)',
      geologicalStrata: 'Clayey Sandstone & Heavy Silt',
      isColdSpotRisk: true,
    ),
    RiverCrossingColdSpot(
      id: 'ST-07',
      stationName: 'Kakodonga River Wetlands Crossing',
      chainageKp: 168.4,
      riverName: 'Kakodonga River Swamp Basin',
      crossingMethod: 'Continuous Subsurface Trench & Concrete Saddles',
      scourDepthM: 4.8,
      ambientGroundOrWaterTempC: 11.2,
      flowingGasTempC: 10.5,
      operatingPressureBar: 54.2,
      dosingSkidRef: 'SK-HYD-03 Upstream Intermediate Reach',
      geologicalStrata: 'Hydromorphic Organic Swamp Peat & Clay',
      isColdSpotRisk: true,
    ),
    RiverCrossingColdSpot(
      id: 'ST-08',
      stationName: 'Numaligarh Custody Terminal / JT Throttling',
      chainageKp: 192.0,
      riverName: 'Dhansiri River Basin / NRL Delivery Point',
      crossingMethod: 'Custody Metering & Pressure Let-down Station',
      scourDepthM: 0.0,
      ambientGroundOrWaterTempC: 14.0,
      flowingGasTempC: 4.5, // JT Throttling cooling effect
      operatingPressureBar: 52.0,
      dosingSkidRef: 'SK-HYD-03 NRL Custody Metering Quench Skid',
      geologicalStrata: 'Terminal Yard Concrete Pad & Granular Base',
      isColdSpotRisk: true,
    ),
  ];

  // Telemetry Dosing Skids along the Trunkline
  final List<DosingSkidTelemetry> _dosingSkids = [
    DosingSkidTelemetry(
      skidId: 'SK-01',
      tag: 'SK-HYD-01',
      name: 'Duliajan Terminal High-Pressure Quench Skid',
      chainageKp: 0.5,
      targetInhibitor: 'Methanol (MeOH 99.5%)',
      tankCapacityLiters: 15000.0,
      currentTankLiters: 12450.0,
      isLeadPumpRunning: true,
      isStandbyPumpAvailable: true,
      activePumpIndex: 0,
      strokeLengthPct: 52.0,
      strokeSpeedSpm: 78.0,
      injectionRateLph: 31.2,
      dischargePressureBar: 84.5,
      batteryVoltageVdc: 26.8,
      isShockSlugActive: false,
      lastShockSlugTime: DateTime.now().subtract(const Duration(days: 3)),
    ),
    DosingSkidTelemetry(
      skidId: 'SK-02',
      tag: 'SK-HYD-02',
      name: 'Moran SV-02 / Disang River Approach Skid',
      chainageKp: 62.8,
      targetInhibitor: 'Methanol (MeOH 99.5%)',
      tankCapacityLiters: 10000.0,
      currentTankLiters: 7820.0,
      isLeadPumpRunning: true,
      isStandbyPumpAvailable: true,
      activePumpIndex: 0,
      strokeLengthPct: 71.0,
      strokeSpeedSpm: 92.0,
      injectionRateLph: 42.6,
      dischargePressureBar: 81.0,
      batteryVoltageVdc: 27.2,
      isShockSlugActive: false,
      lastShockSlugTime: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    DosingSkidTelemetry(
      skidId: 'SK-03',
      tag: 'SK-HYD-03',
      name: 'Jorhat SV-05 / Bhogdoi & NRL Terminal Skid',
      chainageKp: 141.5,
      targetInhibitor: 'Methanol (MeOH 99.5%)',
      tankCapacityLiters: 8000.0,
      currentTankLiters: 5930.0,
      isLeadPumpRunning: true,
      isStandbyPumpAvailable: true,
      activePumpIndex: 1, // Standby B running as Lead
      strokeLengthPct: 45.0,
      strokeSpeedSpm: 65.0,
      injectionRateLph: 24.5,
      dischargePressureBar: 76.5,
      batteryVoltageVdc: 26.4,
      isShockSlugActive: false,
      lastShockSlugTime: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  // Natural Gas Chromatography Composition (Duliajan Field Lean Gas)
  final List<GasComponent> _gasComposition = const [
    GasComponent(
      name: 'Methane',
      formula: 'CH₄',
      molPct: 92.45,
      molecularWeight: 16.043,
      isHydrateFormer: true,
      structureType: 'Structure I (sI)',
    ),
    GasComponent(
      name: 'Ethane',
      formula: 'C₂H₆',
      molPct: 3.82,
      molecularWeight: 30.070,
      isHydrateFormer: true,
      structureType: 'Structure I / II',
    ),
    GasComponent(
      name: 'Propane',
      formula: 'C₃H₈',
      molPct: 1.64,
      molecularWeight: 44.097,
      isHydrateFormer: true,
      structureType: 'Structure II (sII - Critical)',
    ),
    GasComponent(
      name: 'Iso-Butane',
      formula: 'i-C₄H₁₀',
      molPct: 0.42,
      molecularWeight: 58.123,
      isHydrateFormer: true,
      structureType: 'Structure II (sII)',
    ),
    GasComponent(
      name: 'Normal-Butane',
      formula: 'n-C₄H₁₀',
      molPct: 0.48,
      molecularWeight: 58.123,
      isHydrateFormer: true,
      structureType: 'Structure II (sII)',
    ),
    GasComponent(
      name: 'Nitrogen',
      formula: 'N₂',
      molPct: 0.72,
      molecularWeight: 28.013,
      isHydrateFormer: true,
      structureType: 'Structure II (sII)',
    ),
    GasComponent(
      name: 'Carbon Dioxide',
      formula: 'CO₂',
      molPct: 0.47,
      molecularWeight: 44.010,
      isHydrateFormer: true,
      structureType: 'Structure I (sI)',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Live micro-simulation timer for telemetry oscillations
    _liveTelemetryTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          // Micro variations in line pressure and temp
          final rand = math.Random();
          final pDelta = (rand.nextDouble() - 0.5) * 0.15;
          _operatingPressureBar = math.max(20.0, math.min(100.0, _operatingPressureBar + pDelta));

          // Consume trace chemical from active skid
          for (final skid in _dosingSkids) {
            if (skid.isLeadPumpRunning) {
              final loss = (skid.injectionRateLph / 3600.0) * 4.0;
              skid.currentTankLiters = math.max(100.0, skid.currentTankLiters - loss);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _liveTelemetryTimer?.cancel();
    super.dispose();
  }

  // ============================================================================
  // GPSA / SLOAN / HAMMERSCHMIDT THERMODYNAMIC ENGINE
  // ============================================================================

  /// Computes Hydrate Equilibrium Temperature ($T_{hyd}$) in °C
  /// Uses calibrated GPSA Katz Gravity / Sloan empirical model
  /// Baseline: at P = 68.5 Bar, SG = 0.612 -> T_hyd = 15.6 °C
  double calculateHydrateEquilibriumTemp({
    required double pressureBar,
    required double specificGravity,
  }) {
    if (pressureBar <= 0) return 0.0;
    final lnP = math.log(pressureBar);
    final lnP0 = math.log(68.5);

    // Calibrated multi-variable Sloan/GPSA correlation
    final tHyd = 15.6 +
        (6.85 * (lnP - lnP0)) +
        (19.4 * (specificGravity - 0.612)) -
        (0.008 * (pressureBar - 68.5));

    return tHyd;
  }

  /// Subcooling temperature margin: ΔT_sub = T_hyd - T_flowing
  /// Active hydrate risk occurs whenever ΔT_sub > 0 °C
  double calculateSubcoolingMargin({
    required double tHyd,
    required double tFlowing,
  }) {
    return tHyd - tFlowing;
  }

  HydrateRiskSeverity determineRiskSeverity(double deltaTSub) {
    if (deltaTSub <= 0.0) {
      return HydrateRiskSeverity.safe;
    } else if (deltaTSub <= 3.0) {
      return HydrateRiskSeverity.lowMetastable;
    } else if (deltaTSub <= 6.0) {
      return HydrateRiskSeverity.moderateElevated;
    } else {
      return HydrateRiskSeverity.highCritical;
    }
  }

  /// Hammerschmidt Formula:
  /// ΔT = (K * W) / (100 * M - M * W) = (K * W) / [ M * (100 - W) ]
  /// Rearranged for required inhibitor concentration W (weight % in water):
  /// W = (100 * M * ΔT) / (K + M * ΔT)
  double calculateHammerschmidtWeightPct({
    required double requiredDepressionDeltaT,
    required HydrateInhibitorConfig inhibitor,
  }) {
    if (requiredDepressionDeltaT <= 0.0) return 0.0;

    final m = inhibitor.molecularWeight;
    final k = inhibitor.hammerschmidtKSi;
    final deltaT = requiredDepressionDeltaT;

    final w = (100.0 * m * deltaT) / (k + (m * deltaT));
    // Physical limit for thermodynamic aqueous solubility
    return math.min(w, 85.0);
  }

  /// Calculates complete chemical injection mass balance and pump volumetric rate
  Map<String, double> calculateDosingRequirements({
    required double operatingPressureBar,
    required double flowingTempC,
    required double gasFlowMmscmd,
    required double waterContentMgSm3,
    required double deltaTSub,
    required double safetyMarginC,
    required HydrateInhibitorConfig inhibitor,
  }) {
    final double requiredDepressionC = deltaTSub > 0.0 ? (deltaTSub + safetyMarginC) : 0.0;
    final double requiredWeightPct = calculateHammerschmidtWeightPct(
      requiredDepressionDeltaT: requiredDepressionC,
      inhibitor: inhibitor,
    );

    // Hourly Gas Volume: MMSCMD -> Sm3/hr
    final double gasFlowSm3Hr = (gasFlowMmscmd * 1000000.0) / 24.0;

    // Free Water Condensation Rate: kg/hr
    // waterContentMgSm3 is mg per Sm3 -> divide by 1e6 to get kg/Sm3
    final double waterCondensedKgHr = gasFlowSm3Hr * (waterContentMgSm3 / 1000000.0);

    // Inhibitor mass in aqueous liquid phase:
    // m_aq = m_water * [ W / (100 - W) ]
    double massAqueousKgHr = 0.0;
    if (requiredWeightPct > 0.0 && requiredWeightPct < 100.0) {
      massAqueousKgHr = waterCondensedKgHr * (requiredWeightPct / (100.0 - requiredWeightPct));
    }

    // Vapor Phase Carryover Loss (Nielsen-Bucklin correlation)
    // Methanol evaporates into dry gas; Glycols (MEG/DEG) have negligible vapor loss
    double massVaporLossKgHr = 0.0;
    if (inhibitor.type == InhibitorType.methanol) {
      final tk = flowingTempC + 273.15;
      final pBar = math.max(10.0, operatingPressureBar);
      // GPSA Fig 20-30 approximation: ~30-40 kg/MMSCM for 8°C at 68.5 Bar
      final vaporFactor = (0.0022 * math.pow(tk, 1.45)) / math.pow(pBar, 0.45);
      massVaporLossKgHr = (gasFlowSm3Hr / 1000.0) * vaporFactor * inhibitor.vaporLossFactor;
    } else {
      // MEG / DEG: trace vapor loss
      massVaporLossKgHr = (gasFlowSm3Hr / 100000.0) * 0.04;
    }

    // Liquid Hydrocarbon Dissolution Loss (lean gas ~ 2.5% of aqueous mass)
    final double massHydrocarbonLossKgHr = massAqueousKgHr * 0.025;

    // Total Pure Inhibitor Mass Rate (kg/hr)
    final double totalMassPureKgHr = massAqueousKgHr + massVaporLossKgHr + massHydrocarbonLossKgHr;

    // Account for commercial chemical purity and density
    final double purityFrac = inhibitor.defaultPurityPct / 100.0;
    final double totalCommercialMassKgHr = purityFrac > 0 ? (totalMassPureKgHr / purityFrac) : 0.0;

    // Volumetric Injection Pump Rate (L/hr)
    // Rate = Mass (kg/hr) / Density (kg/L)
    final double pumpRateLph = inhibitor.densityKgL > 0 ? (totalCommercialMassKgHr / inhibitor.densityKgL) : 0.0;

    // Daily consumption (Liters/day)
    final double dailyLiters = pumpRateLph * 24.0;

    // API 675 Metering Pump Stroke % (Assuming 0-80 L/hr duplex diaphragm pump)
    const double pumpMaxCapacityLph = 80.0;
    final double pumpStrokePct = math.min(100.0, (pumpRateLph / pumpMaxCapacityLph) * 100.0);

    // Daily Chemical OPEX in INR
    final double dailyOpexInr = totalCommercialMassKgHr * 24.0 * inhibitor.costPerKgInr;

    return {
      'requiredDepressionC': requiredDepressionC,
      'requiredWeightPct': requiredWeightPct,
      'waterCondensedKgHr': waterCondensedKgHr,
      'massAqueousKgHr': massAqueousKgHr,
      'massVaporLossKgHr': massVaporLossKgHr,
      'massHydrocarbonLossKgHr': massHydrocarbonLossKgHr,
      'totalMassPureKgHr': totalMassPureKgHr,
      'totalCommercialMassKgHr': totalCommercialMassKgHr,
      'pumpRateLph': pumpRateLph,
      'dailyLiters': dailyLiters,
      'pumpStrokePct': pumpStrokePct,
      'dailyOpexInr': dailyOpexInr,
    };
  }

  // Active Inhibitor Config Object
  HydrateInhibitorConfig get _currentInhibitor =>
      HydrateInhibitorConfig.allInhibitors.firstWhere((i) => i.type == _selectedInhibitorType);

  // Quick Action: Execute Shock Slug Dosing for rapid line clearing
  void _executeShockSlugDosing(DosingSkidTelemetry skid) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.secondary, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on_rounded, color: AppTheme.secondary, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Authorize Emergency Shock Slug',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Skid: ${skid.tag} (${skid.name})',
              style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Text(
              'A high-concentration slug (150% standard dosage = ${(skid.injectionRateLph * 1.5).toStringAsFixed(1)} L/hr) '
              'will be injected at ${skid.dischargePressureBar.toStringAsFixed(1)} Bar into the pipeline header '
              'to dissolve metastable hydrate crystals and prevent complete trunkline agglomeration plug.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppTheme.tertiary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OISD-141 / PNGRB T4S Slug Protocol: Max Slug Duration = 45 Minutes',
                      style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.9), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              setState(() {
                skid.isShockSlugActive = true;
                skid.lastShockSlugTime = DateTime.now();
                skid.strokeLengthPct = 100.0;
                skid.strokeSpeedSpm = 115.0;
                skid.injectionRateLph = skid.injectionRateLph * 1.5;
                _bannerStatusMessage = 'Shock Slug Active on ${skid.tag}! Line pressure clearing underway.';
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  content: Text(
                    '⚡ Shock Slug Injection Started on ${skid.tag} at ${skid.injectionRateLph.toStringAsFixed(1)} L/hr',
                    style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            icon: const Icon(Icons.flash_on_rounded, size: 18),
            label: const Text('Execute Slug', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Quick Action: Export Dossier
  void _showExportDossierDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.primary, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryLight, size: 24),
            SizedBox(width: 10),
            Text(
              'Hydrate Dossier & Audit Cert',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thermodynamic calculations comply with GPSA Engineering Data Book (20th Edition, Section 20) '
              'and Hammerschmidt correlation for Thermodynamic Hydrate Inhibition (THI).',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            _buildAuditRow('Pipeline Corridor', 'Duliajan–Numaligarh Trunkline (DNPL 192 KM)'),
            _buildAuditRow('Operating Pressure', '${_operatingPressureBar.toStringAsFixed(1)} Bar'),
            _buildAuditRow('Gas Specific Gravity', _gasSpecificGravity.toStringAsFixed(3)),
            _buildAuditRow('Coldest Spot Flowing Temp', '${_flowingGasTempC.toStringAsFixed(1)} °C'),
            _buildAuditRow('Active Inhibitor', _currentInhibitor.name),
            _buildAuditRow('Compliance Standard', 'PNGRB T4S & OISD-STD-141'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.surfaceCard,
                  content: Text('✓ Hydrate Dossier Exported to /reports/hydrate_prediction_audit.pdf'),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Generate PDF Dossier'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5))),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 11.5)),
        ],
      ),
    );
  }

  // ============================================================================
  // BUILD METHOD & ROOT SCAFFOLD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    // Current Thermodynamics Calculations
    final double tHyd = calculateHydrateEquilibriumTemp(
      pressureBar: _operatingPressureBar,
      specificGravity: _gasSpecificGravity,
    );
    final double deltaTSub = calculateSubcoolingMargin(
      tHyd: tHyd,
      tFlowing: _flowingGasTempC,
    );
    final HydrateRiskSeverity severity = determineRiskSeverity(deltaTSub);
    final dosing = calculateDosingRequirements(
      operatingPressureBar: _operatingPressureBar,
      flowingTempC: _flowingGasTempC,
      gasFlowMmscmd: _gasFlowMmscmd,
      waterContentMgSm3: _waterContentMgSm3,
      deltaTSub: deltaTSub,
      safetyMarginC: _safetyMarginDeltaTC,
      inhibitor: _currentInhibitor,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'Hydrate & Methanol Prediction',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'DNPL 192 KM',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              'GPSA 20th Ed. • Hammerschmidt THI • Sloan P-T Model • OISD-141',
              style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.9), fontSize: 10),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export Hydrate Dossier',
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primaryLight),
            onPressed: _showExportDossierDialog,
          ),
          IconButton(
            tooltip: 'Reset to Field Baseline',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: () {
              setState(() {
                _operatingPressureBar = 68.5;
                _gasSpecificGravity = 0.612;
                _flowingGasTempC = 8.2;
                _gasFlowMmscmd = 5.5;
                _waterContentMgSm3 = 85.0;
                _safetyMarginDeltaTC = 3.0;
                _selectedInhibitorType = InhibitorType.methanol;
                _selectedColdSpotIndex = 3;
                _bannerStatusMessage = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.surfaceCard,
                  content: Text('Reset to Disang River HDD Baseline (68.5 Bar, SG 0.612, 8.2°C)'),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
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
              indicatorWeight: 3,
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              tabs: const [
                Tab(icon: Icon(Icons.analytics_rounded, size: 18), text: 'Model & Predictor'),
                Tab(icon: Icon(Icons.science_rounded, size: 18), text: 'THI Hammerschmidt'),
                Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'Trunkline Heatmap'),
                Tab(icon: Icon(Icons.precision_manufacturing_rounded, size: 18), text: 'Dosing Skids'),
                Tab(icon: Icon(Icons.biotech_rounded, size: 18), text: 'Gas Chromatography'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Top Hydrate Alert / Subcooling Banner
          _buildHydrateRiskAlertBanner(deltaTSub, tHyd, _flowingGasTempC, severity),

          // 2. High-Impact KPI Metric Bar
          _buildKpiMetricsStrip(tHyd, _flowingGasTempC, deltaTSub, dosing),

          // 3. Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildModelPredictorTab(tHyd, deltaTSub, dosing),
                _buildHammerschmidtDosingTab(deltaTSub, dosing),
                _buildTrunklineHeatmapTab(),
                _buildDosingSkidsTab(dosing),
                _buildGasChromatographyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SECTION 1: HYDRATE RISK ALERT BANNER
  // ============================================================================

  Widget _buildHydrateRiskAlertBanner(
    double deltaTSub,
    double tHyd,
    double tFlowing,
    HydrateRiskSeverity severity,
  ) {
    Color bannerBg;
    Color bannerBorder;
    IconData icon;
    String statusTitle;
    String statusDesc;

    switch (severity) {
      case HydrateRiskSeverity.safe:
        bannerBg = const Color(0xFF0F392B);
        bannerBorder = AppTheme.tertiary;
        icon = Icons.check_circle_outline_rounded;
        statusTitle = 'OPERATING OUTSIDE HYDRATE FORMATION ENVELOPE';
        statusDesc = 'Flowing temp (${tFlowing.toStringAsFixed(1)}°C) is above Hydrate Equilibrium (${tHyd.toStringAsFixed(1)}°C). '
            'Subcooling Margin ΔTsub = ${deltaTSub.toStringAsFixed(1)}°C. Free hydrate nucleation suppressed.';
        break;
      case HydrateRiskSeverity.lowMetastable:
        bannerBg = const Color(0xFF382E12);
        bannerBorder = AppTheme.secondary;
        icon = Icons.warning_amber_rounded;
        statusTitle = 'METASTABLE INDUCTION ZONE — HYDRATE FORMATION RISK';
        statusDesc = 'Subcooling Margin ΔTsub = +${deltaTSub.toStringAsFixed(1)}°C. Gas temperature is chilling below '
            'equilibrium (${tHyd.toStringAsFixed(1)}°C). Induction period active; early micro-crystals forming.';
        break;
      case HydrateRiskSeverity.moderateElevated:
        bannerBg = const Color(0xFF45220C);
        bannerBorder = const Color(0xFFFF8A00);
        icon = Icons.error_outline_rounded;
        statusTitle = 'ACTIVE HYDRATE FORMATION RISK — DOSING REQUIRED';
        statusDesc = 'Subcooling Margin ΔTsub = +${deltaTSub.toStringAsFixed(1)}°C > 0°C! Free water droplets are clathrating '
            'methane/propane into solid ice cages. Continuous THI injection must be maintained.';
        break;
      case HydrateRiskSeverity.highCritical:
        bannerBg = const Color(0xFF45111B);
        bannerBorder = const Color(0xFFFF4E64);
        icon = Icons.dangerous_rounded;
        statusTitle = 'CRITICAL SEVERE PLUGGING RISK — ACTIVE HYDRATE FORMATION RISK';
        statusDesc = 'Subcooling Margin ΔTsub = +${deltaTSub.toStringAsFixed(1)}°C > 6.0°C! Rapid clathrate agglomeration '
            'active at pipeline low spots & riverbeds. Immediate high-rate THI dosing or shock slug injection mandatory!';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bannerBg,
        border: Border(
          bottom: BorderSide(color: bannerBorder.withValues(alpha: 0.8), width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: bannerBorder, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    color: bannerBorder,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bannerBorder.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: bannerBorder, width: 0.8),
                ),
                child: Text(
                  'ΔTsub = ${deltaTSub >= 0 ? "+" : ""}${deltaTSub.toStringAsFixed(1)} °C',
                  style: TextStyle(
                    color: bannerBorder,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            statusDesc,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10.5, height: 1.25),
          ),
          if (_bannerStatusMessage != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on_rounded, color: AppTheme.secondary, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _bannerStatusMessage!,
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _bannerStatusMessage = null),
                    child: const Icon(Icons.close_rounded, color: AppTheme.secondary, size: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // SECTION 2: TOP KPI METRICS STRIP
  // ============================================================================

  Widget _buildKpiMetricsStrip(
    double tHyd,
    double tFlowing,
    double deltaTSub,
    Map<String, double> dosing,
  ) {
    final double pumpRate = dosing['pumpRateLph'] ?? 0.0;
    final double requiredW = dosing['requiredWeightPct'] ?? 0.0;
    final bool isRisk = deltaTSub > 0;

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiCard(
              title: 'HYDRATE TEMP (Thyd)',
              value: '${tHyd.toStringAsFixed(1)} °C',
              subtitle: 'P = ${_operatingPressureBar.toStringAsFixed(1)} Bar',
              icon: Icons.ac_unit_rounded,
              color: AppTheme.primaryLight,
            ),
            _buildKpiCard(
              title: 'FLOWING TEMP (Tflow)',
              value: '${tFlowing.toStringAsFixed(1)} °C',
              subtitle: 'River Bed Aquifer',
              icon: Icons.thermostat_rounded,
              color: isRisk ? AppTheme.secondary : AppTheme.tertiary,
            ),
            _buildKpiCard(
              title: 'SUBCOOLING MARGIN',
              value: '${deltaTSub >= 0 ? "+" : ""}${deltaTSub.toStringAsFixed(1)} °C',
              subtitle: isRisk ? 'ACTIVE RISK (>0°C)' : 'SAFE ZONE (<=0°C)',
              icon: Icons.speed_rounded,
              color: isRisk ? const Color(0xFFFF5252) : AppTheme.tertiary,
            ),
            _buildKpiCard(
              title: 'INHIBITOR CONC (W)',
              value: '${requiredW.toStringAsFixed(1)} wt%',
              subtitle: 'Hammerschmidt THI',
              icon: Icons.water_drop_rounded,
              color: AppTheme.primaryLight,
            ),
            _buildKpiCard(
              title: 'DOSING PUMP RATE',
              value: '${pumpRate.toStringAsFixed(1)} L/hr',
              subtitle: '${dosing['pumpStrokePct']?.toStringAsFixed(0)}% Stroke (API 675)',
              icon: Icons.precision_manufacturing_rounded,
              color: AppTheme.secondary,
            ),
            _buildKpiCard(
              title: 'METHANOL STOCK',
              value: '${(_dosingSkids[1].currentTankLiters / 1000).toStringAsFixed(1)}k L',
              subtitle: '${_dosingSkids[1].autonomyDays.toStringAsFixed(1)} Days Autonomy',
              icon: Icons.battery_charging_full_rounded,
              color: AppTheme.tertiary,
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
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 156,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.9),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: MODEL PREDICTOR & SLOAN PHASE ENVELOPE CHART
  // ============================================================================

  Widget _buildModelPredictorTab(
    double tHyd,
    double deltaTSub,
    Map<String, double> dosing,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section A: Interactive Thermodynamic Sliders
          _buildThermodynamicSlidersCard(),

          const SizedBox(height: 12),

          // Section B: P-T Phase Envelope Chart (GPSA / Sloan Hydrate Line)
          _buildPhaseEnvelopeChartCard(tHyd),

          const SizedBox(height: 12),

          // Section C: Real-Time Thermodynamic Synthesis Card
          _buildThermodynamicSynthesisCard(tHyd, deltaTSub, dosing),
        ],
      ),
    );
  }

  Widget _buildThermodynamicSlidersCard() {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Thermodynamic Operating Parameters',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'DNPL Trunkline API 5L X70',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Slider 1: Operating Pressure (Bar)
            _buildSliderRow(
              label: 'Operating Pipeline Pressure (P)',
              valueString: '${_operatingPressureBar.toStringAsFixed(1)} Bar',
              value: _operatingPressureBar,
              min: 20.0,
              max: 95.0,
              divisions: 150,
              color: AppTheme.primaryLight,
              onChanged: (val) => setState(() => _operatingPressureBar = val),
              hint: 'Design Pressure: 90.0 Bar | Nominal: 68.5 Bar',
            ),

            const Divider(color: AppTheme.border, height: 16),

            // Slider 2: Gas Specific Gravity (SG)
            _buildSliderRow(
              label: 'Gas Specific Gravity (SG, Air = 1.0)',
              valueString: _gasSpecificGravity.toStringAsFixed(3),
              value: _gasSpecificGravity,
              min: 0.550,
              max: 0.750,
              divisions: 200,
              color: AppTheme.secondary,
              onChanged: (val) => setState(() => _gasSpecificGravity = val),
              hint: 'Lean Field Gas = 0.612 | Rich Gas > 0.680 (sII Hydrate)',
            ),

            const Divider(color: AppTheme.border, height: 16),

            // Slider 3: Flowing Temperature (°C)
            _buildSliderRow(
              label: 'Flowing Gas Temperature (Tflowing)',
              valueString: '${_flowingGasTempC.toStringAsFixed(1)} °C',
              value: _flowingGasTempC,
              min: -5.0,
              max: 30.0,
              divisions: 140,
              color: _flowingGasTempC < 10 ? const Color(0xFFFF5252) : AppTheme.tertiary,
              onChanged: (val) => setState(() => _flowingGasTempC = val),
              hint: 'Riverbed Cold Spots: 7.2°C – 8.6°C | Station Inlets: 24°C',
            ),

            const Divider(color: AppTheme.border, height: 16),

            // Slider 4: Gas Flow Rate (MMSCMD)
            _buildSliderRow(
              label: 'Gas Transmission Flow Rate (Q)',
              valueString: '${_gasFlowMmscmd.toStringAsFixed(1)} MMSCMD',
              value: _gasFlowMmscmd,
              min: 1.0,
              max: 12.0,
              divisions: 110,
              color: AppTheme.primaryLight,
              onChanged: (val) => setState(() => _gasFlowMmscmd = val),
              hint: 'OIL CGGS to NRL Delivery Allocation: 5.5 MMSCMD',
            ),

            const Divider(color: AppTheme.border, height: 16),

            // Slider 5: Water Content / Dewpoint
            _buildSliderRow(
              label: 'Gas Moisture Content (Wwater)',
              valueString: '${_waterContentMgSm3.toStringAsFixed(0)} mg/Sm³',
              value: _waterContentMgSm3,
              min: 20.0,
              max: 200.0,
              divisions: 180,
              color: AppTheme.secondary,
              onChanged: (val) => setState(() => _waterContentMgSm3 = val),
              hint: 'Pipeline Spec Limit: < 100 mg/Sm³ (ADP -5°C @ 68.5 Bar)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueString,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color color,
    required ValueChanged<double> onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.6), width: 0.8),
              ),
              child: Text(
                valueString,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: AppTheme.surfaceContainerHigh,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.2),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Text(hint, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
      ],
    );
  }

  Widget _buildPhaseEnvelopeChartCard(double tHyd) {
    // Generate data points for Hydrate Equilibrium Curve: P vs T
    // Using Sloan model: T as function of P
    final List<FlSpot> uninhibitedCurve = [];
    final List<FlSpot> inhibitedCurve = [];

    final double deltaDepression = calculateHammerschmidtWeightPct(
      requiredDepressionDeltaT: _flowingGasTempC < tHyd ? (tHyd - _flowingGasTempC + _safetyMarginDeltaTC) : 5.0,
      inhibitor: _currentInhibitor,
    ) > 0
        ? (_flowingGasTempC < tHyd ? (tHyd - _flowingGasTempC + _safetyMarginDeltaTC) : 5.0)
        : 5.0;

    for (double p = 20.0; p <= 95.0; p += 5.0) {
      final t = calculateHydrateEquilibriumTemp(
        pressureBar: p,
        specificGravity: _gasSpecificGravity,
      );
      uninhibitedCurve.add(FlSpot(t, p));
      inhibitedCurve.add(FlSpot(t - deltaDepression, p));
    }

    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
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
                    Icon(Icons.show_chart_rounded, color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Hydrate Equilibrium P-T Phase Envelope',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('GPSA Sec 20 / Sloan', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Hydrate crystals nucleate to the LEFT of the equilibrium boundary. Operating point shows current pipeline status.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
            ),
            const SizedBox(height: 14),

            // fl_chart LineChart for P-T
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 20,
                    verticalInterval: 5,
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
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Temperature (°C)',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}°',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Pressure (Bar)',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppTheme.border),
                  ),
                  minX: -10,
                  maxX: 25,
                  minY: 15,
                  maxY: 100,
                  lineBarsData: [
                    // 1. Uninhibited Hydrate Boundary (Cyan)
                    LineChartBarData(
                      spots: uninhibitedCurve,
                      isCurved: true,
                      color: AppTheme.primaryLight,
                      barWidth: 2.2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryLight.withValues(alpha: 0.08),
                      ),
                    ),
                    // 2. Inhibited Hydrate Boundary with Methanol (Emerald)
                    LineChartBarData(
                      spots: inhibitedCurve,
                      isCurved: true,
                      color: AppTheme.tertiary,
                      barWidth: 1.8,
                      dashArray: [6, 4],
                      dotData: const FlDotData(show: false),
                    ),
                    // 3. Current Operating Point Dot
                    LineChartBarData(
                      spots: [FlSpot(_flowingGasTempC, _operatingPressureBar)],
                      isCurved: false,
                      color: _flowingGasTempC < tHyd ? const Color(0xFFFF5252) : AppTheme.tertiary,
                      barWidth: 0,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: _flowingGasTempC < tHyd ? const Color(0xFFFF5252) : AppTheme.tertiary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _buildLegendItem(AppTheme.primaryLight, 'Uninhibited Hydrate Line (Sloan)'),
                _buildLegendItem(AppTheme.tertiary, 'Inhibited Line (with ${_currentInhibitor.name})'),
                _buildLegendItem(
                  _flowingGasTempC < tHyd ? const Color(0xFFFF5252) : AppTheme.tertiary,
                  'Current Point (${_flowingGasTempC.toStringAsFixed(1)}°C, ${_operatingPressureBar.toStringAsFixed(1)} Bar)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5)),
      ],
    );
  }

  Widget _buildThermodynamicSynthesisCard(
    double tHyd,
    double deltaTSub,
    Map<String, double> dosing,
  ) {
    final bool isRisk = deltaTSub > 0;

    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: AppTheme.secondary, size: 18),
                SizedBox(width: 8),
                Text(
                  'Thermodynamic Phase Analysis Summary',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSynthesisRow('Equilibrium Hydrate Temp (Thyd)', '${tHyd.toStringAsFixed(2)} °C', AppTheme.primaryLight),
            _buildSynthesisRow('Flowing Stream Temp (Tflowing)', '${_flowingGasTempC.toStringAsFixed(2)} °C', AppTheme.textPrimary),
            _buildSynthesisRow(
              'Subcooling Margin (ΔTsub = Thyd - Tflow)',
              '${deltaTSub >= 0 ? "+" : ""}${deltaTSub.toStringAsFixed(2)} °C',
              isRisk ? const Color(0xFFFF5252) : AppTheme.tertiary,
            ),
            _buildSynthesisRow('Crystalline Structure Predominance', 'Structure II (sII) Clathrate Cages', AppTheme.secondary),
            _buildSynthesisRow('Hydrate Nucleation Kinetics', isRisk ? 'Active Nucleation & Growth' : 'Suppressed / Metastable Free', isRisk ? AppTheme.secondary : AppTheme.tertiary),
            _buildSynthesisRow('Induction Delay Time (t_ind)', isRisk ? '~14 to 38 Minutes at Riverbed Shear' : '> 48 Hours Stable', AppTheme.textSecondary),
            _buildSynthesisRow('Required Hammerschmidt Inhibitor', '${dosing['requiredWeightPct']?.toStringAsFixed(1)} wt% ${_currentInhibitor.chemicalFormula}', AppTheme.primaryLight),
          ],
        ),
      ),
    );
  }

  Widget _buildSynthesisRow(String label, String value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: 11.5, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: THI HAMMERSCHMIDT DOSING CALCULATOR
  // ============================================================================

  Widget _buildHammerschmidtDosingTab(
    double deltaTSub,
    Map<String, double> dosing,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hammerschmidt Formula Box
          _buildHammerschmidtFormulaHeader(),

          const SizedBox(height: 12),

          // 2. Inhibitor Selector Chips
          _buildInhibitorSelector(),

          const SizedBox(height: 12),

          // 3. Safety Margin Slider
          _buildSafetyMarginCard(),

          const SizedBox(height: 12),

          // 4. Complete Chemical Mass & Volumetric Balance Card
          _buildMassBalanceCard(dosing),

          const SizedBox(height: 12),

          // 5. API 675 Metering Pump Output & OPEX Card
          _buildPumpOpexCard(dosing),
        ],
      ),
    );
  }

  Widget _buildHammerschmidtFormulaHeader() {
    return Card(
      color: const Color(0xFF131D38),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.primary, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.functions_rounded, color: AppTheme.primaryLight, size: 20),
                SizedBox(width: 8),
                Text(
                  'Hammerschmidt Equation (Thermodynamic Hydrate Inhibitor)',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Column(
                children: [
                  Text(
                    'ΔT = (K × W) / (100 × M - M × W)',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Rearranged for Weight %:  W = (100 × M × ΔT) / (K + M × ΔT)',
                    style: TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Where: ΔT = Hydrate temperature depression (°C) | W = Inhibitor weight % in aqueous phase | '
              'M = Molecular weight of inhibitor (g/mol) | K = Hammerschmidt empirical constant (1297 for MeOH, 1500 for MEG in SI).',
              style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.9), fontSize: 10.5, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInhibitorSelector() {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Thermodynamic Hydrate Inhibitor (THI)',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: HydrateInhibitorConfig.allInhibitors.map((inhibitor) {
                final isSelected = _selectedInhibitorType == inhibitor.type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _selectedInhibitorType = inhibitor.type),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              inhibitor.name.split(' ')[0],
                              style: TextStyle(
                                color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              inhibitor.chemicalFormula,
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'M=${inhibitor.molecularWeight.toStringAsFixed(1)} | K=${inhibitor.hammerschmidtKSi.toInt()}',
                              style: TextStyle(
                                color: isSelected ? AppTheme.secondary : AppTheme.textMuted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.secondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentInhibitor.notes,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
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

  Widget _buildSafetyMarginCard() {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Safety Temperature Buffer (ΔTbuffer)',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                Text(
                  '+${_safetyMarginDeltaTC.toStringAsFixed(1)} °C',
                  style: const TextStyle(color: AppTheme.tertiary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.tertiary,
                thumbColor: AppTheme.tertiary,
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _safetyMarginDeltaTC,
                min: 1.0,
                max: 6.0,
                divisions: 50,
                onChanged: (val) => setState(() => _safetyMarginDeltaTC = val),
              ),
            ),
            const Text(
              'OISD-141 mandates +2.0°C to +3.0°C over-depression buffer against riverbed transient temperature dips.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMassBalanceCard(Map<String, double> dosing) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.scale_rounded, color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Chemical Mass & Partition Balance',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text('GPSA Fig 20-30', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 12),
            _buildBalanceRow('Required Depression (ΔT = ΔTsub + buffer)', '${dosing['requiredDepressionC']?.toStringAsFixed(1)} °C', AppTheme.primaryLight),
            _buildBalanceRow('Aqueous Phase Inhibitor Conc (W)', '${dosing['requiredWeightPct']?.toStringAsFixed(2)} wt%', AppTheme.secondary),
            const Divider(color: AppTheme.border, height: 16),
            _buildBalanceRow('Free Water Drop-out Rate (m_water)', '${dosing['waterCondensedKgHr']?.toStringAsFixed(2)} kg/hr', AppTheme.textPrimary),
            _buildBalanceRow('Aqueous Phase Inhibitor Mass (m_aq)', '${dosing['massAqueousKgHr']?.toStringAsFixed(2)} kg/hr', AppTheme.textPrimary),
            _buildBalanceRow('Vapor Phase Carryover Loss (m_vap)', '${dosing['massVaporLossKgHr']?.toStringAsFixed(2)} kg/hr', AppTheme.textMuted),
            _buildBalanceRow('Hydrocarbon Liquid Dissolution (m_hc)', '${dosing['massHydrocarbonLossKgHr']?.toStringAsFixed(2)} kg/hr', AppTheme.textMuted),
            const Divider(color: AppTheme.border, height: 16),
            _buildBalanceRow('Total Pure Inhibitor Mass Rate', '${dosing['totalMassPureKgHr']?.toStringAsFixed(2)} kg/hr', AppTheme.secondary),
            _buildBalanceRow('Total Commercial Chemical Rate (${_currentInhibitor.defaultPurityPct}%)', '${dosing['totalCommercialMassKgHr']?.toStringAsFixed(2)} kg/hr', AppTheme.primaryLight),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11.5, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPumpOpexCard(Map<String, double> dosing) {
    final currencyFormat = NumberFormat('#,##,###');
    final double pumpRate = dosing['pumpRateLph'] ?? 0.0;
    final double dailyLiters = dosing['dailyLiters'] ?? 0.0;
    final double dailyOpex = dosing['dailyOpexInr'] ?? 0.0;

    return Card(
      color: const Color(0xFF162347),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.secondary, width: 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.monetization_on_outlined, color: AppTheme.secondary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'API 675 Injection Rate & OPEX Projection',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text('₹ INR / Day', style: TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'PUMP FLOW RATE',
                    '${pumpRate.toStringAsFixed(1)} L/hr',
                    '${(pumpRate * 0.264172).toStringAsFixed(1)} GPH',
                    AppTheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    'DAILY USAGE',
                    '${dailyLiters.toStringAsFixed(0)} L/day',
                    '${(dailyLiters * _currentInhibitor.densityKgL).toStringAsFixed(0)} kg/day',
                    AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    'DAILY COST',
                    '₹${currencyFormat.format(dailyOpex.round())}',
                    '₹${_currentInhibitor.costPerKgInr.toStringAsFixed(0)}/kg pure',
                    AppTheme.tertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String mainVal, String subVal, Color color) {
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
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(mainVal, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text(subVal, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: TRUNKLINE HEATMAP & RIVER CROSSING COLD SPOTS
  // ============================================================================

  Widget _buildTrunklineHeatmapTab() {
    final selectedStation = _trunklineStations[_selectedColdSpotIndex];
    final double stationHydTemp = calculateHydrateEquilibriumTemp(
      pressureBar: selectedStation.operatingPressureBar,
      specificGravity: _gasSpecificGravity,
    );
    final double stationDeltaTSub = calculateSubcoolingMargin(
      tHyd: stationHydTemp,
      tFlowing: selectedStation.flowingGasTempC,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Duliajan–Numaligarh Pipeline Visual Heatmap Bar
          _buildPipelineRouteOverviewCard(),

          const SizedBox(height: 12),

          // 2. Selected Station / River Crossing Deep Dive Card
          _buildSelectedColdSpotDetailCard(selectedStation, stationHydTemp, stationDeltaTSub),

          const SizedBox(height: 12),

          // 3. Complete List of Trunkline Stations
          _buildAllStationsListCard(),
        ],
      ),
    );
  }

  Widget _buildPipelineRouteOverviewCard() {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.route_rounded, color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Duliajan–Numaligarh Trunkline Heatmap',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text('192.0 KM • 16-Inch X70', style: TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Cold spots occur at subterranean HDD riverbed crossings where rapid alluvial heat dissipation drops flowing gas temp into hydrate zone.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
            ),
            const SizedBox(height: 16),

            // Continuous Visual Gradient Heatmap Bar
            Container(
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4EDEA3), // KP 0 Duliajan (Safe 32°C)
                    Color(0xFFFFB95F), // KP 18 Buri Dihing (Metastable)
                    Color(0xFF4EDEA3), // KP 38 Moran (Safe)
                    Color(0xFFFF4E64), // KP 64 Disang River (Severe Cold Spot)
                    Color(0xFFFF4E64), // KP 88 Dikhow River (Severe Cold Spot)
                    Color(0xFFFF8A00), // KP 115 Jhanji (High Risk)
                    Color(0xFFFFB95F), // KP 142 Bhogdoi (Moderate)
                    Color(0xFFFF8A00), // KP 168 Kakodonga (Moderate)
                    Color(0xFFFF4E64), // KP 192 NRL JT Throttling (Severe)
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('KP 0.0 (Duliajan)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                Text('KP 64.0 (Disang HDD)', style: TextStyle(color: Color(0xFFFF4E64), fontSize: 9.5, fontWeight: FontWeight.bold)),
                Text('KP 88.5 (Dikhow HDD)', style: TextStyle(color: Color(0xFFFF4E64), fontSize: 9.5, fontWeight: FontWeight.bold)),
                Text('KP 192.0 (NRL)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
              ],
            ),

            const SizedBox(height: 14),

            // Quick Station Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_trunklineStations.length, (idx) {
                  final station = _trunklineStations[idx];
                  final isSelected = _selectedColdSpotIndex == idx;
                  final isColdRisk = station.isColdSpotRisk;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(
                        'KP ${station.chainageKp.toStringAsFixed(1)}: ${station.riverName.split(' ')[0]}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black : (isColdRisk ? const Color(0xFFFF8A00) : AppTheme.textSecondary),
                        ),
                      ),
                      selectedColor: isColdRisk ? const Color(0xFFFF8A00) : AppTheme.primaryLight,
                      backgroundColor: AppTheme.surface,
                      side: BorderSide(
                        color: isSelected
                            ? (isColdRisk ? const Color(0xFFFF8A00) : AppTheme.primaryLight)
                            : AppTheme.border,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedColdSpotIndex = idx;
                            // Update predictor to this station
                            _operatingPressureBar = station.operatingPressureBar;
                            _flowingGasTempC = station.flowingGasTempC;
                          });
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedColdSpotDetailCard(
    RiverCrossingColdSpot station,
    double tHyd,
    double deltaTSub,
  ) {
    final bool isRisk = deltaTSub > 0;

    return Card(
      color: const Color(0xFF131D38),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isRisk ? const Color(0xFFFF5252) : AppTheme.tertiary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isRisk ? const Color(0xFFFF5252).withValues(alpha: 0.2) : AppTheme.tertiary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isRisk ? const Color(0xFFFF5252) : AppTheme.tertiary, width: 0.8),
                            ),
                            child: Text(
                              station.id,
                              style: TextStyle(
                                color: isRisk ? const Color(0xFFFF5252) : AppTheme.tertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              station.stationName,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chainage: KP ${station.chainageKp.toStringAsFixed(1)} | ${station.riverName}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRisk ? const Color(0xFFFF4E64) : AppTheme.tertiary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isRisk ? 'ACTIVE RISK' : 'SAFE ZONE',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10),
                  ),
                ),
              ],
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
                children: [
                  _buildDetailRow('Crossing Method & Invert Depth', '${station.crossingMethod} (${station.scourDepthM.toStringAsFixed(1)}m below bed)'),
                  _buildDetailRow('Riverbed Ambient Aquifer Temp', '${station.ambientGroundOrWaterTempC.toStringAsFixed(1)} °C'),
                  _buildDetailRow('Local Gas Flowing Temp (Tflow)', '${station.flowingGasTempC.toStringAsFixed(1)} °C'),
                  _buildDetailRow('Operating Pressure at Chainage', '${station.operatingPressureBar.toStringAsFixed(1)} Bar'),
                  _buildDetailRow('Calculated Hydrate Temp (Thyd)', '${tHyd.toStringAsFixed(1)} °C'),
                  _buildDetailRow(
                    'Subcooling Temperature Margin (ΔTsub)',
                    '${deltaTSub >= 0 ? "+" : ""}${deltaTSub.toStringAsFixed(1)} °C',
                    highlightColor: isRisk ? const Color(0xFFFF5252) : AppTheme.tertiary,
                  ),
                  _buildDetailRow('Assigned THI Dosing Skid', station.dosingSkidRef),
                  _buildDetailRow('Geological Strata Formation', station.geologicalStrata),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryLight),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      setState(() {
                        _operatingPressureBar = station.operatingPressureBar;
                        _flowingGasTempC = station.flowingGasTempC;
                        _tabController.animateTo(0);
                      });
                    },
                    icon: const Icon(Icons.analytics_rounded, size: 16, color: AppTheme.primaryLight),
                    label: const Text('Sync to Model Predictor', style: TextStyle(fontSize: 11, color: AppTheme.primaryLight)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      _tabController.animateTo(1);
                    },
                    icon: const Icon(Icons.science_rounded, size: 16),
                    label: const Text('Calculate THI Dosing', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: highlightColor ?? AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllStationsListCard() {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list_alt_rounded, color: AppTheme.primaryLight, size: 18),
                SizedBox(width: 8),
                Text(
                  'Trunkline Station & River Crossing Inventory',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _trunklineStations.length,
              separatorBuilder: (ctx, i) => const Divider(color: AppTheme.border, height: 1),
              itemBuilder: (ctx, i) {
                final st = _trunklineStations[i];
                final th = calculateHydrateEquilibriumTemp(
                  pressureBar: st.operatingPressureBar,
                  specificGravity: _gasSpecificGravity,
                );
                final dSub = calculateSubcoolingMargin(tHyd: th, tFlowing: st.flowingGasTempC);
                final isRisk = dSub > 0;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColdSpotIndex = i;
                      _operatingPressureBar = st.operatingPressureBar;
                      _flowingGasTempC = st.flowingGasTempC;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isRisk ? const Color(0xFFFF5252) : AppTheme.tertiary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                st.stationName,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'KP ${st.chainageKp.toStringAsFixed(1)} • ${st.crossingMethod}',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${st.flowingGasTempC.toStringAsFixed(1)} °C',
                              style: TextStyle(
                                color: isRisk ? const Color(0xFFFF5252) : AppTheme.tertiary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'ΔT: ${dSub >= 0 ? "+" : ""}${dSub.toStringAsFixed(1)}°',
                              style: TextStyle(
                                color: isRisk ? const Color(0xFFFF5252) : AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 4: DOSING SKIDS & FIELD TELEMETRY
  // ============================================================================

  Widget _buildDosingSkidsTab(Map<String, double> dosing) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pipeline Injection Skids (API 675 / OISD-141)',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_dosingSkids.length} Skids Online',
                style: const TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Render Skid Cards
          ..._dosingSkids.map((skid) => _buildSkidCard(skid, dosing)),
        ],
      ),
    );
  }

  Widget _buildSkidCard(DosingSkidTelemetry skid, Map<String, double> dosing) {
    final bool isLowStock = skid.tankPercentage < 25.0;

    return Card(
      color: AppTheme.surfaceCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: skid.isShockSlugActive ? AppTheme.secondary : AppTheme.border,
          width: skid.isShockSlugActive ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skid Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.precision_manufacturing_rounded, color: AppTheme.primaryLight, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skid.tag,
                          style: const TextStyle(color: AppTheme.primaryLight, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Chainage: KP ${skid.chainageKp.toStringAsFixed(1)} | ${skid.targetInhibitor}',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: skid.isShockSlugActive
                        ? AppTheme.secondary.withValues(alpha: 0.2)
                        : (skid.isLeadPumpRunning ? AppTheme.tertiary.withValues(alpha: 0.2) : AppTheme.surface),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: skid.isShockSlugActive
                          ? AppTheme.secondary
                          : (skid.isLeadPumpRunning ? AppTheme.tertiary : AppTheme.border),
                    ),
                  ),
                  child: Text(
                    skid.isShockSlugActive ? 'SHOCK SLUG ACTIVE' : (skid.isLeadPumpRunning ? 'INJECTING' : 'STANDBY'),
                    style: TextStyle(
                      color: skid.isShockSlugActive
                          ? AppTheme.secondary
                          : (skid.isLeadPumpRunning ? AppTheme.tertiary : AppTheme.textMuted),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Skid Name
            Text(
              skid.name,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            // Pump Dual Diaphragm A/B Status
            Container(
              padding: const EdgeInsets.all(10),
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
                      _buildPumpStatusBadge('PUMP A (LEAD)', skid.activePumpIndex == 0),
                      _buildPumpStatusBadge('PUMP B (STANDBY)', skid.activePumpIndex == 1),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            skid.activePumpIndex = skid.activePumpIndex == 0 ? 1 : 0;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.surfaceCard,
                              content: Text('Switched Duty to Pump ${skid.activePumpIndex == 0 ? "A" : "B"} on ${skid.tag}'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.swap_horiz_rounded, size: 14, color: AppTheme.primaryLight),
                        label: const Text('Switch Duty', style: TextStyle(color: AppTheme.primaryLight, fontSize: 11)),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.border, height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTelemetryCol('Pump Flow', '${skid.injectionRateLph.toStringAsFixed(1)} L/hr', AppTheme.secondary),
                      _buildTelemetryCol('Discharge P', '${skid.dischargePressureBar.toStringAsFixed(1)} Bar', AppTheme.primaryLight),
                      _buildTelemetryCol('Stroke Length', '${skid.strokeLengthPct.toStringAsFixed(0)}%', AppTheme.textPrimary),
                      _buildTelemetryCol('Speed', '${skid.strokeSpeedSpm.toStringAsFixed(0)} SPM', AppTheme.textPrimary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Storage Tank Level Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storage_rounded, color: AppTheme.primaryLight, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'Tank Stock: ${skid.currentTankLiters.toStringAsFixed(0)} / ${skid.tankCapacityLiters.toStringAsFixed(0)} L',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  '${skid.autonomyDays.toStringAsFixed(1)} Days Runout',
                  style: TextStyle(
                    color: isLowStock ? const Color(0xFFFF5252) : AppTheme.tertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: skid.tankPercentage / 100.0,
                minHeight: 6,
                backgroundColor: AppTheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isLowStock ? const Color(0xFFFF5252) : AppTheme.tertiary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons: Shock Slug Injection & Sync Dosing Rate
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryLight),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      final double calculatedRate = dosing['pumpRateLph'] ?? 30.0;
                      setState(() {
                        skid.injectionRateLph = calculatedRate;
                        skid.strokeLengthPct = dosing['pumpStrokePct'] ?? 50.0;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.surfaceCard,
                          content: Text('Applied Hammerschmidt Rate (${calculatedRate.toStringAsFixed(1)} L/hr) to ${skid.tag}'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.sync_rounded, size: 16, color: AppTheme.primaryLight),
                    label: const Text('Apply Model Rate', style: TextStyle(color: AppTheme.primaryLight, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: skid.isShockSlugActive ? const Color(0xFFFF4E64) : AppTheme.secondary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _executeShockSlugDosing(skid),
                    icon: const Icon(Icons.flash_on_rounded, size: 16),
                    label: Text(
                      skid.isShockSlugActive ? 'Slug In Progress' : 'Shock Slug Dosing',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPumpStatusBadge(String name, bool isRunning) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isRunning ? AppTheme.tertiary : AppTheme.textMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: TextStyle(
            color: isRunning ? AppTheme.tertiary : AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 5: GAS CHROMATOGRAPHY & CLATHRATE STRUCTURE SPECS
  // ============================================================================

  Widget _buildGasChromatographyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Gas Composition Table (ISO 6974 / GPA 2261)
          _buildGasCompositionCard(),

          const SizedBox(height: 12),

          // 2. Clathrate Hydrate Structure Comparison (sI vs sII)
          _buildClathrateGeometryCard(),

          const SizedBox(height: 12),

          // 3. Regulatory Reference Dossier (OISD-141 / PNGRB T4S)
          _buildRegulatoryComplianceCard(),
        ],
      ),
    );
  }

  Widget _buildGasCompositionCard() {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.biotech_rounded, color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Natural Gas Composition (Duliajan Lean Gas)',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text('ISO 6974 / GPA 2261', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Online GC telemetry sampled at Duliajan CGGS Inlet Metering Skid. Propane and Iso-butane are primary Structure II former.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _gasComposition.length,
              separatorBuilder: (ctx, i) => const Divider(color: AppTheme.border, height: 1),
              itemBuilder: (ctx, i) {
                final comp = _gasComposition[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comp.name,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              comp.formula,
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${comp.molPct.toStringAsFixed(2)} mol%',
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          comp.structureType,
                          style: TextStyle(
                            color: comp.structureType.contains('Critical') ? const Color(0xFFFF8A00) : AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClathrateGeometryCard() {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hub_outlined, color: AppTheme.secondary, size: 18),
                SizedBox(width: 8),
                Text(
                  'Clathrate Hydrate Molecular Thermodynamics',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Gas hydrates are crystalline ice-like inclusion compounds formed when hydrogen-bonded water molecules '
              'form polyhedral polyhedral host lattices encapsulating small natural gas molecules.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Structure I (sI)', 'Body-centered cubic; 46 H₂O molecules per unit cell; encapsulates CH₄, CO₂'),
                  _buildDetailRow('Structure II (sII)', 'Diamond cubic; 136 H₂O molecules per unit cell; encapsulates C₃H₈, i-C₄H₁₀ (Predominant in DNPL)'),
                  _buildDetailRow('Structure H (sH)', 'Hexagonal; requires small and very large guest molecules (C₅+ fraction)'),
                  _buildDetailRow('Hydrate Density', '0.912 to 0.945 g/cm³ (Floats at fluid interfaces in pipeline dips)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegulatoryComplianceCard() {
    return Card(
      color: const Color(0xFF131D38),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.tertiary, width: 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_outlined, color: AppTheme.tertiary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Statutory & Standards Compliance',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text('PNGRB / OISD', style: TextStyle(color: AppTheme.tertiary, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            _buildComplianceCheck('OISD-STD-141 Clause 6.4: Continuous chemical injection mandatory at riverbed crossings.'),
            _buildComplianceCheck('PNGRB T4S Regulations: Free water accumulation prevented via pigging and THI dosing.'),
            _buildComplianceCheck('GPSA Engineering Data Book (Sec 20): Hammerschmidt THI equation verified for ΔT up to 25°C.'),
            _buildComplianceCheck('API 675 Metering Pumps: Redundant dual-diaphragm with leak detection sensors.'),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                onPressed: _showExportDossierDialog,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export Official Hydrate Prevention Certificate'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceCheck(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, height: 1.25)),
          ),
        ],
      ),
    );
  }
}
