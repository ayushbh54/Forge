import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// ENUMS & DOMAIN CONSTANTS (NACE SP0169 / DNV-RP-F103 / NACE SP0177)
// ============================================================================

/// Galvanic Sacrificial Anode Metallurgy per ASTM B843, ASTM B418, DNV-RP-F103
enum SacrificialAlloyType {
  highPotentialMg, // ASTM B843 Grade M1C High-Potential Magnesium Ribbon
  standardMg, // ASTM B843 Grade AZ63B Standard Potential Magnesium
  zincRibbonSoil, // ASTM B418 Type II High-Purity Zinc Ribbon (Diamond Line)
  aluminiumRibbon, // DNV-RP-F103 Al-Zn-In Marine / Estuarine Ribbon
}

extension SacrificialAlloyTypeExt on SacrificialAlloyType {
  String get name {
    switch (this) {
      case SacrificialAlloyType.highPotentialMg:
        return 'High-Potential Mg Ribbon';
      case SacrificialAlloyType.standardMg:
        return 'Standard AZ63 Mg Ribbon';
      case SacrificialAlloyType.zincRibbonSoil:
        return 'Zinc Ribbon (Diamond Line)';
      case SacrificialAlloyType.aluminiumRibbon:
        return 'Aluminium Ribbon (Al-Zn-In)';
    }
  }

  String get standardCode {
    switch (this) {
      case SacrificialAlloyType.highPotentialMg:
        return 'ASTM B843 M1C (HP-Mg)';
      case SacrificialAlloyType.standardMg:
        return 'ASTM B843 AZ63B / H1';
      case SacrificialAlloyType.zincRibbonSoil:
        return 'ASTM B418 Type II (Zn)';
      case SacrificialAlloyType.aluminiumRibbon:
        return 'DNV-RP-F103 (Al-Zn-In)';
    }
  }

  String get applicationDomain {
    switch (this) {
      case SacrificialAlloyType.highPotentialMg:
        return 'High-resistivity soil (>2,000 Ω·cm), rocky ridges, HDD pullbacks';
      case SacrificialAlloyType.standardMg:
        return 'Moderate resistivity soil (1,000 - 2,500 Ω·cm), alluvial clays';
      case SacrificialAlloyType.zincRibbonSoil:
        return 'AC mitigation along 220kV lines, low-R soil (<1,500 Ω·cm), grounding mats';
      case SacrificialAlloyType.aluminiumRibbon:
        return 'Estuarine / tidal river crossings, saline marsh, brackish HDD bores';
    }
  }

  /// Open-circuit potential vs Cu/CuSO4 (CSE) in mV
  double get defaultOpenCircuitPotentialMv {
    switch (this) {
      case SacrificialAlloyType.highPotentialMg:
        return -1750.0; // -1.75 V CSE
      case SacrificialAlloyType.standardMg:
        return -1550.0; // -1.55 V CSE
      case SacrificialAlloyType.zincRibbonSoil:
        return -1100.0; // -1.10 V CSE
      case SacrificialAlloyType.aluminiumRibbon:
        return -1120.0; // -1.12 V CSE (-1.08 V Ag/AgCl)
    }
  }

  /// Electrochemical current efficiency factor (epsilon)
  double get efficiencyFactor {
    switch (this) {
      case SacrificialAlloyType.highPotentialMg:
        return 0.50; // 50% efficiency due to self-corrosion
      case SacrificialAlloyType.standardMg:
        return 0.50; // 50%
      case SacrificialAlloyType.zincRibbonSoil:
        return 0.90; // 90% high efficiency
      case SacrificialAlloyType.aluminiumRibbon:
        return 0.85; // 85% high efficiency
    }
  }

  /// Theoretical electrochemical capacity mu in Amp-hours per kg (A·h/kg)
  double get theoreticalCapacityAhPerKg {
    switch (this) {
      case SacrificialAlloyType.highPotentialMg:
        return 2200.0;
      case SacrificialAlloyType.standardMg:
        return 2200.0;
      case SacrificialAlloyType.zincRibbonSoil:
        return 820.0;
      case SacrificialAlloyType.aluminiumRibbon:
        return 2980.0;
    }
  }

  /// Practical actual delivery capacity (mu * epsilon) in A·h/kg
  double get practicalCapacityAhPerKg => theoreticalCapacityAhPerKg * efficiencyFactor;

  /// Practical consumption rate in kg / (Amp · year)
  /// 8760 hours/year / practical Ah/kg
  double get consumptionRateKgPerAmpYear => 8760.0 / practicalCapacityAhPerKg;

  /// Typical nominal linear mass of continuous ribbon (kg/m)
  double get typicalLinearMassKgPerM {
    switch (this) {
      case SacrificialAlloyType.highPotentialMg:
        return 0.357; // 3/8" x 3/4" standard extruded Mg ribbon (0.24 lb/ft)
      case SacrificialAlloyType.standardMg:
        return 0.357;
      case SacrificialAlloyType.zincRibbonSoil:
        return 0.893; // Standard Diamond Line zinc ribbon (0.60 lb/ft)
      case SacrificialAlloyType.aluminiumRibbon:
        return 0.420;
    }
  }

  Color get badgeColor {
    switch (this) {
      case SacrificialAlloyType.highPotentialMg:
        return const Color(0xFF38BDF8); // Cyan
      case SacrificialAlloyType.standardMg:
        return const Color(0xFF818CF8); // Indigo
      case SacrificialAlloyType.zincRibbonSoil:
        return const Color(0xFFFFB95F); // Amber
      case SacrificialAlloyType.aluminiumRibbon:
        return const Color(0xFF4EDEA3); // Tertiary Green
    }
  }

  IconData get icon {
    switch (this) {
      case SacrificialAlloyType.highPotentialMg:
        return Icons.bolt_rounded;
      case SacrificialAlloyType.standardMg:
        return Icons.electric_bolt_rounded;
      case SacrificialAlloyType.zincRibbonSoil:
        return Icons.waves_rounded;
      case SacrificialAlloyType.aluminiumRibbon:
        return Icons.water_rounded;
    }
  }
}

/// Anode Deployment Architecture
enum AnodeDeploymentForm {
  continuousRibbonTrench, // Continuous ribbon parallel to pipe inside bottom ditch
  groundingMatAcMitigation, // Spiral / grid zinc ribbon mat for 220kV overhead line
  packagedCanister, // Discrete prepackaged canister with gypsum/bentonite
  braceletCrossing, // Segmented bracelet for HDD river / cased crossing
}

extension AnodeDeploymentFormExt on AnodeDeploymentForm {
  String get label {
    switch (this) {
      case AnodeDeploymentForm.continuousRibbonTrench:
        return 'Continuous Ribbon in Trench';
      case AnodeDeploymentForm.groundingMatAcMitigation:
        return 'Zinc Ribbon AC Grounding Mat';
      case AnodeDeploymentForm.packagedCanister:
        return 'Prepackaged Canister Bed';
      case AnodeDeploymentForm.braceletCrossing:
        return 'Cased / HDD Bracelet Assembly';
    }
  }

  IconData get icon {
    switch (this) {
      case AnodeDeploymentForm.continuousRibbonTrench:
        return Icons.linear_scale_rounded;
      case AnodeDeploymentForm.groundingMatAcMitigation:
        return Icons.grid_4x4_rounded;
      case AnodeDeploymentForm.packagedCanister:
        return Icons.battery_charging_full_rounded;
      case AnodeDeploymentForm.braceletCrossing:
        return Icons.donut_large_rounded;
    }
  }
}

/// Test Station Disconnect Coupon Switch State
enum CouponSwitchState {
  closed, // Connected: closed-circuit potential E_on & normal galvanic current
  open, // Disconnected: instant-off IR-free E_off measurement
}

/// NACE SP0169 / NACE SP0177 Compliance Status
enum StationComplianceStatus {
  fullyCompliant, // E_off <= -850 mV & >= -1200 mV & Vac < 15V
  underProtected, // E_off > -850 mV (e.g. -780 mV)
  overProtected, // E_off < -1200 mV (hydrogen embrittlement / disbondment risk)
  acInterferenceHazard, // Vac >= 15V RMS or Jac > 30 A/m2
  decayAlert, // Polarization decay < 100 mV
}

extension StationComplianceStatusExt on StationComplianceStatus {
  String get label {
    switch (this) {
      case StationComplianceStatus.fullyCompliant:
        return 'Compliant (SP0169)';
      case StationComplianceStatus.underProtected:
        return 'Under-Protected (> -850 mV)';
      case StationComplianceStatus.overProtected:
        return 'Over-Protected (< -1200 mV)';
      case StationComplianceStatus.acInterferenceHazard:
        return 'AC Hazard (PowerGrid 220kV)';
      case StationComplianceStatus.decayAlert:
        return 'Decay Alert (< 100 mV)';
    }
  }

  Color get color {
    switch (this) {
      case StationComplianceStatus.fullyCompliant:
        return const Color(0xFF4EDEA3); // Tertiary Green
      case StationComplianceStatus.underProtected:
        return const Color(0xFFEF4444); // Critical Red
      case StationComplianceStatus.overProtected:
        return const Color(0xFFFF7043); // Orange
      case StationComplianceStatus.acInterferenceHazard:
        return const Color(0xFFFFB95F); // Amber Warning
      case StationComplianceStatus.decayAlert:
        return const Color(0xFFE879F9); // Magenta
    }
  }

  IconData get icon {
    switch (this) {
      case StationComplianceStatus.fullyCompliant:
        return Icons.check_circle_rounded;
      case StationComplianceStatus.underProtected:
        return Icons.error_outline_rounded;
      case StationComplianceStatus.overProtected:
        return Icons.shield_outlined;
      case StationComplianceStatus.acInterferenceHazard:
        return Icons.bolt_rounded;
      case StationComplianceStatus.decayAlert:
        return Icons.timelapse_rounded;
    }
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

/// Real-time Test Station Survey Telemetry Record
class TestStationTelemetry {
  final String id;
  final String stationTag; // e.g. TS-14
  final double chainageKm; // Distance KP e.g. 14.250
  final String chainageStr; // e.g. "KP 14+250"
  final String locationTitle; // e.g. "PowerGrid 220kV Crossing Span #4"
  final SacrificialAlloyType alloyType;
  final AnodeDeploymentForm deploymentForm;
  final double ribbonLengthM; // Continuous ribbon length (m)
  final double totalAnodeMassKg; // W (kg)
  final double openCircuitPotentialMv; // E_anode, OC (mV vs CSE)
  final double closedCircuitPotentialMv; // E_on with IR drop (mV vs CSE)
  final double instantOffPotentialMv; // E_off IR-free (mV vs CSE)
  final double nativePotentialMv; // Baseline depolarized native (mV vs CSE)
  final double calibratedShuntResistanceOhms; // R_shunt e.g. 0.100 Ohm
  final double shuntVoltageDropMv; // V_shunt (mV)
  final double soilResistivityOhmM; // Local soil resistivity (Ohm-m)
  final double acInducedVoltageV; // Vac RMS from 220kV lines
  final double acCouponCurrentDensityAm2; // Jac (A/m2)
  final bool hasSolidStateDecoupler; // SSD / PCR decoupler present
  final String decouplerStatus; // "Normal (AC Draining)", "Surge Clamped", "N/A"
  final CouponSwitchState couponSwitchState;
  final DateTime surveyTimestamp;
  final String inspectorName;

  const TestStationTelemetry({
    required this.id,
    required this.stationTag,
    required this.chainageKm,
    required this.chainageStr,
    required this.locationTitle,
    required this.alloyType,
    required this.deploymentForm,
    required this.ribbonLengthM,
    required this.totalAnodeMassKg,
    required this.openCircuitPotentialMv,
    required this.closedCircuitPotentialMv,
    required this.instantOffPotentialMv,
    required this.nativePotentialMv,
    required this.calibratedShuntResistanceOhms,
    required this.shuntVoltageDropMv,
    required this.soilResistivityOhmM,
    required this.acInducedVoltageV,
    required this.acCouponCurrentDensityAm2,
    required this.hasSolidStateDecoupler,
    required this.decouplerStatus,
    required this.couponSwitchState,
    required this.surveyTimestamp,
    required this.inspectorName,
  });

  /// Galvanic Anode Driving Potential: E_driving = E_pipe - E_anode (Volts)
  /// E_pipe is closed circuit pipe potential (-980 mV), E_anode is open circuit (-1750 mV)
  /// Driving potential = -0.980 - (-1.750) = 0.770 V
  double get drivingPotentialV =>
      (closedCircuitPotentialMv - openCircuitPotentialMv).abs() / 1000.0;

  double get drivingPotentialMv => drivingPotentialV * 1000.0;

  /// Current output through calibrated shunt resistor:
  /// I = V_shunt / R_shunt (in Amperes)
  double get calculatedCurrentAmps {
    if (couponSwitchState == CouponSwitchState.open) return 0.0;
    if (calibratedShuntResistanceOhms <= 0.0) return 0.0;
    return (shuntVoltageDropMv / 1000.0) / calibratedShuntResistanceOhms;
  }

  /// Current output in milliamperes (mA)
  double get calculatedCurrentMa => calculatedCurrentAmps * 1000.0;

  /// Total Circuit Resistance: R = Delta_E / I (Ohms)
  double get totalCircuitResistanceOhms {
    final i = calculatedCurrentAmps;
    if (i <= 0.0001) return 0.0;
    return drivingPotentialV / i;
  }

  /// NACE SP0169 100 mV Polarization Decay Check: |E_off - E_native|
  double get polarizationDecayMv => (instantOffPotentialMv - nativePotentialMv).abs();

  bool get is100MvDecayAchieved => polarizationDecayMv >= 100.0;

  /// Anode Groundbed Design Life Calculator:
  /// T = (W * epsilon * mu * u) / (8760 * I)
  /// where W = total mass (kg), epsilon = efficiency, mu = theo capacity (Ah/kg),
  /// u = utilization factor (0.85 for ribbon), 8760 = hours/year, I = current in Amps.
  double get calculatedDesignLifeYears {
    final i = calculatedCurrentAmps;
    if (i <= 0.0001) return 99.0;
    const utilizationFactor = 0.85;
    final totalAh = totalAnodeMassKg *
        alloyType.theoreticalCapacityAhPerKg *
        alloyType.efficiencyFactor *
        utilizationFactor;
    final annualAhConsumption = 8760.0 * i;
    return totalAh / annualAhConsumption;
  }

  /// NACE SP0169 / NACE SP0177 Compliance Status
  StationComplianceStatus get complianceStatus {
    if (acInducedVoltageV >= 15.0 || acCouponCurrentDensityAm2 >= 30.0) {
      return StationComplianceStatus.acInterferenceHazard;
    }
    if (instantOffPotentialMv > -850.0) {
      return StationComplianceStatus.underProtected;
    }
    if (instantOffPotentialMv < -1200.0) {
      return StationComplianceStatus.overProtected;
    }
    if (!is100MvDecayAchieved && instantOffPotentialMv > -850.0) {
      return StationComplianceStatus.decayAlert;
    }
    return StationComplianceStatus.fullyCompliant;
  }

  TestStationTelemetry copyWith({
    CouponSwitchState? couponSwitchState,
    double? shuntVoltageDropMv,
    double? calibratedShuntResistanceOhms,
  }) {
    return TestStationTelemetry(
      id: id,
      stationTag: stationTag,
      chainageKm: chainageKm,
      chainageStr: chainageStr,
      locationTitle: locationTitle,
      alloyType: alloyType,
      deploymentForm: deploymentForm,
      ribbonLengthM: ribbonLengthM,
      totalAnodeMassKg: totalAnodeMassKg,
      openCircuitPotentialMv: openCircuitPotentialMv,
      closedCircuitPotentialMv: closedCircuitPotentialMv,
      instantOffPotentialMv: instantOffPotentialMv,
      nativePotentialMv: nativePotentialMv,
      calibratedShuntResistanceOhms:
          calibratedShuntResistanceOhms ?? this.calibratedShuntResistanceOhms,
      shuntVoltageDropMv: shuntVoltageDropMv ?? this.shuntVoltageDropMv,
      soilResistivityOhmM: soilResistivityOhmM,
      acInducedVoltageV: acInducedVoltageV,
      acCouponCurrentDensityAm2: acCouponCurrentDensityAm2,
      hasSolidStateDecoupler: hasSolidStateDecoupler,
      decouplerStatus: decouplerStatus,
      couponSwitchState: couponSwitchState ?? this.couponSwitchState,
      surveyTimestamp: surveyTimestamp,
      inspectorName: inspectorName,
    );
  }
}

/// 220 kV PowerGrid AC Interference Node along pipeline corridor
class AcInterferenceSpan {
  final String spanId;
  final String chainageRange;
  final double parallelLengthKm;
  final double separationDistanceMeters;
  final double unmitigatedAcVoltageV;
  final double mitigatedAcVoltageV;
  final double zincRibbonLengthM;
  final int solidStateDecouplersCount;
  final String status;

  const AcInterferenceSpan({
    required this.spanId,
    required this.chainageRange,
    required this.parallelLengthKm,
    required this.separationDistanceMeters,
    required this.unmitigatedAcVoltageV,
    required this.mitigatedAcVoltageV,
    required this.zincRibbonLengthM,
    required this.solidStateDecouplersCount,
    required this.status,
  });
}

// ============================================================================
// MAIN WIDGET: SacrificialAnodeScreen
// ============================================================================

class SacrificialAnodeScreen extends StatefulWidget {
  const SacrificialAnodeScreen({super.key});

  @override
  State<SacrificialAnodeScreen> createState() => _SacrificialAnodeScreenState();
}

class _SacrificialAnodeScreenState extends State<SacrificialAnodeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search and Filter State
  String _searchQuery = '';
  SacrificialAlloyType? _selectedAlloyFilter;
  StationComplianceStatus? _selectedStatusFilter;

  // Design Life Calculator State
  SacrificialAlloyType _calcAlloy = SacrificialAlloyType.highPotentialMg;
  double _calcMassKg = 85.0; // Total mass W
  double _calcRibbonLengthM = 240.0; // Length L
  double _calcEfficiency = 0.50; // epsilon
  double _calcTheoCapacity = 2200.0; // mu (Ah/kg)
  double _calcCurrentMa = 55.0; // Mean current I in mA
  double _calcUtilization = 0.85; // u
  double _calcPipePotentialMv = -850.0; // Closed circuit pipe potential
  double _calcSoilResistivity = 55.0; // Soil resistivity Ohm-m
  bool _calcAutoCurrentFromResistance = true;

  // Telemetry Dataset
  late List<TestStationTelemetry> _stations;
  late List<AcInterferenceSpan> _acSpans;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _stations = [
      TestStationTelemetry(
        id: 'TS-01',
        stationTag: 'TS-04',
        chainageKm: 4.250,
        chainageStr: 'KP 4+250',
        locationTitle: 'Moran High-Resistivity Lateral Ridge',
        alloyType: SacrificialAlloyType.highPotentialMg,
        deploymentForm: AnodeDeploymentForm.continuousRibbonTrench,
        ribbonLengthM: 180.0,
        totalAnodeMassKg: 64.2,
        openCircuitPotentialMv: -1765.0,
        closedCircuitPotentialMv: -1020.0,
        instantOffPotentialMv: -925.0,
        nativePotentialMv: -560.0,
        calibratedShuntResistanceOhms: 0.100,
        shuntVoltageDropMv: 4.6, // I = 46 mA
        soilResistivityOhmM: 88.0,
        acInducedVoltageV: 3.4,
        acCouponCurrentDensityAm2: 4.2,
        hasSolidStateDecoupler: false,
        decouplerStatus: 'N/A (Non-HVAC RoW)',
        couponSwitchState: CouponSwitchState.closed,
        surveyTimestamp: DateTime.now().subtract(const Duration(hours: 4)),
        inspectorName: 'Er. Rajesh Borah',
      ),
      TestStationTelemetry(
        id: 'TS-02',
        stationTag: 'TS-08',
        chainageKm: 8.600,
        chainageStr: 'KP 8+600',
        locationTitle: 'PowerGrid 220kV Crossing Span #1',
        alloyType: SacrificialAlloyType.zincRibbonSoil,
        deploymentForm: AnodeDeploymentForm.groundingMatAcMitigation,
        ribbonLengthM: 320.0,
        totalAnodeMassKg: 285.0,
        openCircuitPotentialMv: -1105.0,
        closedCircuitPotentialMv: -945.0,
        instantOffPotentialMv: -885.0,
        nativePotentialMv: -575.0,
        calibratedShuntResistanceOhms: 0.010,
        shuntVoltageDropMv: 0.85, // I = 85 mA
        soilResistivityOhmM: 22.0,
        acInducedVoltageV: 11.8,
        acCouponCurrentDensityAm2: 18.5,
        hasSolidStateDecoupler: true,
        decouplerStatus: 'Normal (AC Draining / DC Blocked)',
        couponSwitchState: CouponSwitchState.closed,
        surveyTimestamp: DateTime.now().subtract(const Duration(hours: 5)),
        inspectorName: 'Er. Sandeep Baruah',
      ),
      TestStationTelemetry(
        id: 'TS-03',
        stationTag: 'TS-11',
        chainageKm: 11.400,
        chainageStr: 'KP 11+400',
        locationTitle: 'PowerGrid 220kV Collocated Parallel RoW',
        alloyType: SacrificialAlloyType.zincRibbonSoil,
        deploymentForm: AnodeDeploymentForm.groundingMatAcMitigation,
        ribbonLengthM: 450.0,
        totalAnodeMassKg: 402.0,
        openCircuitPotentialMv: -1100.0,
        closedCircuitPotentialMv: -910.0,
        instantOffPotentialMv: -860.0,
        nativePotentialMv: -590.0,
        calibratedShuntResistanceOhms: 0.010,
        shuntVoltageDropMv: 1.25, // I = 125 mA
        soilResistivityOhmM: 18.5,
        acInducedVoltageV: 14.2, // Warning near 15V threshold
        acCouponCurrentDensityAm2: 26.8,
        hasSolidStateDecoupler: true,
        decouplerStatus: 'Normal (AC Drainage 4.2A RMS)',
        couponSwitchState: CouponSwitchState.closed,
        surveyTimestamp: DateTime.now().subtract(const Duration(hours: 6)),
        inspectorName: 'Er. Sandeep Baruah',
      ),
      TestStationTelemetry(
        id: 'TS-04',
        stationTag: 'TS-14',
        chainageKm: 14.750,
        chainageStr: 'KP 14+750',
        locationTitle: 'Dikom Tea Estate Rocky Incline',
        alloyType: SacrificialAlloyType.highPotentialMg,
        deploymentForm: AnodeDeploymentForm.continuousRibbonTrench,
        ribbonLengthM: 220.0,
        totalAnodeMassKg: 78.5,
        openCircuitPotentialMv: -1770.0,
        closedCircuitPotentialMv: -1050.0,
        instantOffPotentialMv: -940.0,
        nativePotentialMv: -550.0,
        calibratedShuntResistanceOhms: 0.100,
        shuntVoltageDropMv: 5.8, // I = 58 mA
        soilResistivityOhmM: 125.0, // High-R soil
        acInducedVoltageV: 2.1,
        acCouponCurrentDensityAm2: 2.5,
        hasSolidStateDecoupler: false,
        decouplerStatus: 'N/A (Isolated Pipeline)',
        couponSwitchState: CouponSwitchState.closed,
        surveyTimestamp: DateTime.now().subtract(const Duration(hours: 7)),
        inspectorName: 'Er. Rajesh Borah',
      ),
      TestStationTelemetry(
        id: 'TS-05',
        stationTag: 'TS-18',
        chainageKm: 18.200,
        chainageStr: 'KP 18+200',
        locationTitle: 'Burhi Dihing Estuarine Marsh Crossing',
        alloyType: SacrificialAlloyType.aluminiumRibbon,
        deploymentForm: AnodeDeploymentForm.braceletCrossing,
        ribbonLengthM: 120.0,
        totalAnodeMassKg: 95.0,
        openCircuitPotentialMv: -1125.0,
        closedCircuitPotentialMv: -960.0,
        instantOffPotentialMv: -895.0,
        nativePotentialMv: -580.0,
        calibratedShuntResistanceOhms: 0.050,
        shuntVoltageDropMv: 3.5, // I = 70 mA
        soilResistivityOhmM: 6.2, // Highly conductive brackish
        acInducedVoltageV: 1.8,
        acCouponCurrentDensityAm2: 3.1,
        hasSolidStateDecoupler: false,
        decouplerStatus: 'N/A',
        couponSwitchState: CouponSwitchState.closed,
        surveyTimestamp: DateTime.now().subtract(const Duration(hours: 8)),
        inspectorName: 'Er. Anupam Gogoi',
      ),
      TestStationTelemetry(
        id: 'TS-06',
        stationTag: 'TS-21',
        chainageKm: 21.850,
        chainageStr: 'KP 21+850',
        locationTitle: 'PowerGrid 220kV Angle Tower Parallel Span',
        alloyType: SacrificialAlloyType.zincRibbonSoil,
        deploymentForm: AnodeDeploymentForm.groundingMatAcMitigation,
        ribbonLengthM: 380.0,
        totalAnodeMassKg: 339.0,
        openCircuitPotentialMv: -1095.0,
        closedCircuitPotentialMv: -890.0,
        instantOffPotentialMv: -820.0, // UNDER-PROTECTED DEPRESSION!
        nativePotentialMv: -560.0,
        calibratedShuntResistanceOhms: 0.010,
        shuntVoltageDropMv: 0.62, // I = 62 mA
        soilResistivityOhmM: 35.0,
        acInducedVoltageV: 16.4, // AC INTERFERENCE HAZARD (>15V)
        acCouponCurrentDensityAm2: 38.5, // >30 A/m2
        hasSolidStateDecoupler: true,
        decouplerStatus: 'Warning: High AC Drainage (8.6A RMS)',
        couponSwitchState: CouponSwitchState.closed,
        surveyTimestamp: DateTime.now().subtract(const Duration(hours: 9)),
        inspectorName: 'Er. Sandeep Baruah',
      ),
      TestStationTelemetry(
        id: 'TS-07',
        stationTag: 'TS-25',
        chainageKm: 25.400,
        chainageStr: 'KP 25+400',
        locationTitle: 'Bogapani Road Boring & Casing Insulator',
        alloyType: SacrificialAlloyType.standardMg,
        deploymentForm: AnodeDeploymentForm.packagedCanister,
        ribbonLengthM: 80.0,
        totalAnodeMassKg: 52.0,
        openCircuitPotentialMv: -1545.0,
        closedCircuitPotentialMv: -995.0,
        instantOffPotentialMv: -910.0,
        nativePotentialMv: -580.0,
        calibratedShuntResistanceOhms: 0.100,
        shuntVoltageDropMv: 4.1, // I = 41 mA
        soilResistivityOhmM: 42.0,
        acInducedVoltageV: 2.8,
        acCouponCurrentDensityAm2: 3.8,
        hasSolidStateDecoupler: false,
        decouplerStatus: 'N/A',
        couponSwitchState: CouponSwitchState.closed,
        surveyTimestamp: DateTime.now().subtract(const Duration(hours: 10)),
        inspectorName: 'Er. Rajesh Borah',
      ),
      TestStationTelemetry(
        id: 'TS-08',
        stationTag: 'TS-29',
        chainageKm: 29.100,
        chainageStr: 'KP 29+100',
        locationTitle: 'Naharkatia Forest Waterlogged Clay',
        alloyType: SacrificialAlloyType.highPotentialMg,
        deploymentForm: AnodeDeploymentForm.continuousRibbonTrench,
        ribbonLengthM: 260.0,
        totalAnodeMassKg: 92.8,
        openCircuitPotentialMv: -1780.0,
        closedCircuitPotentialMv: -1260.0,
        instantOffPotentialMv: -1215.0, // OVER-PROTECTED ALERT (< -1200 mV)
        nativePotentialMv: -620.0,
        calibratedShuntResistanceOhms: 0.100,
        shuntVoltageDropMv: 8.9, // I = 89 mA
        soilResistivityOhmM: 14.0, // Very low resistivity for HP Mg!
        acInducedVoltageV: 1.2,
        acCouponCurrentDensityAm2: 1.8,
        hasSolidStateDecoupler: false,
        decouplerStatus: 'N/A',
        couponSwitchState: CouponSwitchState.closed,
        surveyTimestamp: DateTime.now().subtract(const Duration(hours: 11)),
        inspectorName: 'Er. Rajesh Borah',
      ),
    ];

    _acSpans = [
      const AcInterferenceSpan(
        spanId: 'SPAN-01',
        chainageRange: 'KP 8+200 to KP 12+800',
        parallelLengthKm: 4.6,
        separationDistanceMeters: 35.0,
        unmitigatedAcVoltageV: 48.5,
        mitigatedAcVoltageV: 11.8,
        zincRibbonLengthM: 4600.0,
        solidStateDecouplersCount: 6,
        status: 'Mitigated (< 15V RMS)',
      ),
      const AcInterferenceSpan(
        spanId: 'SPAN-02',
        chainageRange: 'KP 19+400 to KP 23+600',
        parallelLengthKm: 4.2,
        separationDistanceMeters: 18.0,
        unmitigatedAcVoltageV: 64.0,
        mitigatedAcVoltageV: 16.4, // Requires supplemental zinc ribbon
        zincRibbonLengthM: 4200.0,
        solidStateDecouplersCount: 5,
        status: 'Warning (Supplemental Zn Needed)',
      ),
      const AcInterferenceSpan(
        spanId: 'SPAN-03',
        chainageRange: 'KP 31+100 to KP 36+200',
        parallelLengthKm: 5.1,
        separationDistanceMeters: 45.0,
        unmitigatedAcVoltageV: 32.0,
        mitigatedAcVoltageV: 8.5,
        zincRibbonLengthM: 5100.0,
        solidStateDecouplersCount: 7,
        status: 'Mitigated (< 15V RMS)',
      ),
    ];
  }

  void _updateCalculatorAlloy(SacrificialAlloyType alloy) {
    setState(() {
      _calcAlloy = alloy;
      _calcEfficiency = alloy.efficiencyFactor;
      _calcTheoCapacity = alloy.theoreticalCapacityAhPerKg;
      _calcMassKg = _calcRibbonLengthM * alloy.typicalLinearMassKgPerM;
      _recalculateCurrent();
    });
  }

  void _recalculateCurrent() {
    if (!_calcAutoCurrentFromResistance) return;
    // Anode groundbed resistance by Sunde formula:
    // Ra = (rho / (2 * pi * L)) * (ln(4L / d) - 1)
    final l = _calcRibbonLengthM;
    final rho = _calcSoilResistivity;
    final d = 0.015; // 15mm equivalent diameter
    final ra = (rho / (2.0 * math.pi * l)) * (math.log((4.0 * l) / d) - 1.0);
    final deltaV = ((_calcPipePotentialMv - _calcAlloy.defaultOpenCircuitPotentialMv).abs()) / 1000.0;
    final rTotal = math.max(0.2, ra + 0.15); // Add cable and coating resistance
    final iAmps = deltaV / rTotal;
    _calcCurrentMa = (iAmps * 1000.0).clamp(2.0, 5000.0);
  }

  void _toggleCouponSwitch(String stationId) {
    setState(() {
      final index = _stations.indexWhere((s) => s.id == stationId);
      if (index != -1) {
        final current = _stations[index];
        final nextState = current.couponSwitchState == CouponSwitchState.closed
            ? CouponSwitchState.open
            : CouponSwitchState.closed;

        // When open, current drops to 0 and potential reads Instant-Off E_off
        _stations[index] = current.copyWith(
          couponSwitchState: nextState,
          shuntVoltageDropMv: nextState == CouponSwitchState.open ? 0.0 : current.shuntVoltageDropMv,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceContainerHigh,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Text(
              nextState == CouponSwitchState.open
                  ? '${current.stationTag}: Disconnect switch OPEN. Instant-OFF IR-free: ${current.instantOffPotentialMv.toStringAsFixed(0)} mV CSE'
                  : '${current.stationTag}: Disconnect switch CLOSED. Galvanic current active: ${current.calculatedCurrentMa.toStringAsFixed(1)} mA',
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
            ),
          ),
        );
      }
    });
  }

  // ============================================================================
  // UI BUILD & TAB DISPATCH
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTelemetryTopBanner(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLiveTelemetryTab(),
                _buildDesignLifeCalculatorTab(),
                _buildPowerGridAcMitigationTab(),
                _buildSurveyLogAndShuntTab(),
                _buildStandardsAndAuditTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Sacrificial Anode & AC Mitigation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(width: 8),
              _StandardComplianceBadge(),
            ],
          ),
          Text(
            'NACE SP0169 · DNV-RP-F103 · NACE SP0177 220kV HVAC Shielding',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryLight.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 20),
          tooltip: 'Quick Preset Simulation',
          onPressed: _showSimulationDialog,
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
          tooltip: 'Export Cathodic Protection Engineering Dossier',
          onPressed: _showExportDossierDialog,
        ),
      ],
    );
  }

  Widget _buildTelemetryTopBanner() {
    final activeCount = _stations.length;
    final underProtectedCount = _stations.where((s) => s.complianceStatus == StationComplianceStatus.underProtected).length;
    final acHazardsCount = _stations.where((s) => s.complianceStatus == StationComplianceStatus.acInterferenceHazard).length;
    final overProtectedCount = _stations.where((s) => s.complianceStatus == StationComplianceStatus.overProtected).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          // PowerGrid 220kV active status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB95F).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFB95F).withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 13, color: Color(0xFFFFB95F)),
                SizedBox(width: 4),
                Text(
                  'POWERGRID 220kV HVAC: 18.4 km RoW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFB95F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // SSD Decoupler status
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, size: 13, color: Color(0xFF4EDEA3)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '18 Solid-State Decouplers (SSD) Active · $underProtectedCount Low E_off · $acHazardsCount AC Alert',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Total Stations Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              '$activeCount Stations',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(
            icon: Icon(Icons.dashboard_customize_rounded, size: 18),
            text: 'TS Live Telemetry',
          ),
          Tab(
            icon: Icon(Icons.calculate_rounded, size: 18),
            text: 'Groundbed Design Life',
          ),
          Tab(
            icon: Icon(Icons.bolt_rounded, size: 18),
            text: '220kV AC Mitigation',
          ),
          Tab(
            icon: Icon(Icons.table_chart_rounded, size: 18),
            text: 'Shunt Survey Log',
          ),
          Tab(
            icon: Icon(Icons.verified_rounded, size: 18),
            text: 'NACE / DNV Audit',
          ),
        ],
      ),
    );
  }

  Widget? _buildFab() {
    return FloatingActionButton.extended(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_chart_rounded, size: 18),
      label: const Text(
        'LOG TS SURVEY',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
      onPressed: _showAddSurveyDialog,
    );
  }

  // ============================================================================
  // TAB 1: TS LIVE TELEMETRY & INTERACTIVE COUPON SWITCH
  // ============================================================================

  Widget _buildLiveTelemetryTab() {
    final filtered = _stations.where((s) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTag = s.stationTag.toLowerCase().contains(q);
        final matchChainage = s.chainageStr.toLowerCase().contains(q);
        final matchLoc = s.locationTitle.toLowerCase().contains(q);
        if (!matchTag && !matchChainage && !matchLoc) return false;
      }
      if (_selectedAlloyFilter != null && s.alloyType != _selectedAlloyFilter) {
        return false;
      }
      if (_selectedStatusFilter != null && s.complianceStatus != _selectedStatusFilter) {
        return false;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // KPI Summary Matrix
        _buildKpiMetricsRow(),
        const SizedBox(height: 14),

        // Search & Filter Bar
        _buildSearchBar(),
        const SizedBox(height: 10),
        _buildFilterChipsRow(),
        const SizedBox(height: 14),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TEST STATION TELEMETRY CARDS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Showing ${filtered.length} of ${_stations.length} stations',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 40, color: AppTheme.textMuted),
                  SizedBox(height: 10),
                  Text(
                    'No test stations matching filter criteria',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          ...filtered.map((station) => _buildTestStationCard(station)),
      ],
    );
  }

  Widget _buildKpiMetricsRow() {
    final meanCurrent = _stations.map((s) => s.calculatedCurrentMa).reduce((a, b) => a + b) / _stations.length;
    final minOffPotential = _stations.map((s) => s.instantOffPotentialMv).reduce((a, b) => a > b ? a : b); // closest to 0
    final maxAcInduced = _stations.map((s) => s.acInducedVoltageV).reduce(math.max);
    final compliantRate = (_stations.where((s) => s.complianceStatus == StationComplianceStatus.fullyCompliant).length / _stations.length) * 100.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildMetricTile(
              width: cardWidth,
              label: 'MEAN CP CURRENT',
              value: '${meanCurrent.toStringAsFixed(1)} mA',
              subtext: 'Across ${_stations.length} Shunts',
              icon: Icons.electric_meter_rounded,
              color: AppTheme.primaryLight,
            ),
            _buildMetricTile(
              width: cardWidth,
              label: 'WORST E_OFF',
              value: '${minOffPotential.toStringAsFixed(0)} mV',
              subtext: minOffPotential > -850 ? 'Under-Protected!' : 'IR-Free Compliant',
              icon: Icons.speed_rounded,
              color: minOffPotential > -850 ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
            ),
            _buildMetricTile(
              width: cardWidth,
              label: 'PEAK 220kV VAC',
              value: '${maxAcInduced.toStringAsFixed(1)} V RMS',
              subtext: maxAcInduced >= 15.0 ? 'Exceeds 15V NACE' : 'Safe Touch Potential',
              icon: Icons.bolt_rounded,
              color: maxAcInduced >= 15.0 ? const Color(0xFFFFB95F) : const Color(0xFF4EDEA3),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required double width,
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
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
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search station tag (e.g. TS-14), chainage KP, or landmark...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.textMuted),
                onPressed: () => setState(() => _searchQuery = ''),
              )
            : null,
        filled: true,
        fillColor: AppTheme.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
      ),
      onChanged: (val) => setState(() => _searchQuery = val),
    );
  }

  Widget _buildFilterChipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Alloys'),
            selected: _selectedAlloyFilter == null,
            onSelected: (_) => setState(() => _selectedAlloyFilter = null),
            backgroundColor: AppTheme.surfaceCard,
            selectedColor: AppTheme.primary.withValues(alpha: 0.25),
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _selectedAlloyFilter == null ? AppTheme.primaryLight : AppTheme.textSecondary,
            ),
            side: BorderSide(
              color: _selectedAlloyFilter == null ? AppTheme.primary : AppTheme.border,
            ),
          ),
          const SizedBox(width: 6),
          ...SacrificialAlloyType.values.map((alloy) {
            final isSelected = _selectedAlloyFilter == alloy;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(alloy.name.replaceAll(' Ribbon', '')),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selectedAlloyFilter = isSelected ? null : alloy;
                }),
                backgroundColor: AppTheme.surfaceCard,
                selectedColor: alloy.badgeColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? alloy.badgeColor : AppTheme.textSecondary,
                ),
                side: BorderSide(
                  color: isSelected ? alloy.badgeColor : AppTheme.border,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTestStationCard(TestStationTelemetry station) {
    final isSwitchOpen = station.couponSwitchState == CouponSwitchState.open;
    final compliance = station.complianceStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: compliance == StationComplianceStatus.fullyCompliant
              ? AppTheme.border
              : compliance.color.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: station.alloyType.badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    station.alloyType.icon,
                    size: 20,
                    color: station.alloyType.badgeColor,
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
                            station.stationTag,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              station.chainageStr,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _buildComplianceBadge(compliance),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        station.locationTitle,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.border),

          // Interactive Schematic Strip: Disconnect Switch & Calibrated Shunt
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppTheme.surface.withValues(alpha: 0.6),
            child: Row(
              children: [
                // Coupon Switch Button
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COUPON DISCONNECT SWITCH',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _toggleCouponSwitch(station.id),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSwitchOpen
                                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                : const Color(0xFF4EDEA3).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSwitchOpen ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSwitchOpen ? Icons.toggle_off_rounded : Icons.toggle_on_rounded,
                                size: 18,
                                color: isSwitchOpen ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isSwitchOpen ? 'OPEN (IR-Free E_off)' : 'CLOSED (Current Active)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSwitchOpen ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Calibrated Shunt Readout
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'SHUNT (${station.calibratedShuntResistanceOhms.toStringAsFixed(3)} Ω)',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            isSwitchOpen ? '0.0 mA' : '${station.calculatedCurrentMa.toStringAsFixed(1)} mA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isSwitchOpen ? AppTheme.textMuted : AppTheme.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${station.shuntVoltageDropMv.toStringAsFixed(2)} mV drop)',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.border),

          // Potential Telemetry Grid: Open-Circuit, Closed-Circuit, Instant-Off, Driving Potential
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildPotentialCell(
                      label: 'OPEN-CIRCUIT (E_oc)',
                      value: '${station.openCircuitPotentialMv.toStringAsFixed(0)} mV',
                      caption: 'Anode disconnected',
                      color: station.alloyType.badgeColor,
                    ),
                    _buildPotentialCell(
                      label: 'CLOSED-CIRCUIT (E_on)',
                      value: '${station.closedCircuitPotentialMv.toStringAsFixed(0)} mV',
                      caption: 'Pipe with IR drop',
                      color: AppTheme.textPrimary,
                    ),
                    _buildPotentialCell(
                      label: 'INSTANT-OFF (E_off)',
                      value: '${station.instantOffPotentialMv.toStringAsFixed(0)} mV',
                      caption: 'IR-drop free (SP0169)',
                      color: station.instantOffPotentialMv <= -850.0 && station.instantOffPotentialMv >= -1200.0
                          ? const Color(0xFF4EDEA3)
                          : const Color(0xFFEF4444),
                    ),
                    _buildPotentialCell(
                      label: 'DRIVING VOLTAGE (ΔE)',
                      value: '${station.drivingPotentialMv.toStringAsFixed(0)} mV',
                      caption: 'E_pipe - E_anode',
                      color: const Color(0xFFFFB95F),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Auxiliary Telemetry: AC induced voltage & design life remaining
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      // AC Voltage
                      Icon(
                        Icons.electric_bolt_rounded,
                        size: 14,
                        color: station.acInducedVoltageV >= 15.0 ? const Color(0xFFEF4444) : const Color(0xFFFFB95F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '220kV AC: ${station.acInducedVoltageV.toStringAsFixed(1)} V RMS (${station.acCouponCurrentDensityAm2.toStringAsFixed(1)} A/m²)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: station.acInducedVoltageV >= 15.0 ? const Color(0xFFEF4444) : AppTheme.textSecondary,
                        ),
                      ),
                      const Spacer(),

                      // Groundbed Design Life
                      const Icon(Icons.timelapse_rounded, size: 14, color: AppTheme.primaryLight),
                      const SizedBox(width: 4),
                      Text(
                        'Design Life: ${station.calculatedDesignLifeYears.toStringAsFixed(1)} yrs',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryLight,
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

  Widget _buildPotentialCell({
    required String label,
    required String value,
    required String caption,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            caption,
            style: const TextStyle(fontSize: 8.5, color: AppTheme.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceBadge(StationComplianceStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: status.color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 11, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: GROUNDBED DESIGN LIFE CALCULATOR
  // ============================================================================

  Widget _buildDesignLifeCalculatorTab() {
    // Anode groundbed design life:
    // T = (W * epsilon * mu * u) / (8760 * I)
    final iAmps = _calcCurrentMa / 1000.0;
    final totalEffectiveAh = _calcMassKg * _calcEfficiency * _calcTheoCapacity * _calcUtilization;
    final annualAh = 8760.0 * iAmps;
    final designLifeYears = annualAh > 0 ? (totalEffectiveAh / annualAh) : 99.0;
    final consumptionRate = 8760.0 / (_calcTheoCapacity * _calcEfficiency); // kg/A-yr
    final annualConsumptionKg = consumptionRate * iAmps;
    final drivingDeltaV = (_calcPipePotentialMv - _calcAlloy.defaultOpenCircuitPotentialMv).abs() / 1000.0;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Formula Header Banner
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
                  Icon(Icons.functions_rounded, color: AppTheme.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'NACE SP0169 / DNV-RP-F103 DESIGN LIFE EQUATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  'T = (W · ε · μ · u) / (8,760 · I)   or   T = (W · u) / (Cr · I)\n'
                  'I = ΔE / R   where   ΔE = |E_pipe - E_anode|',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFB95F),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Where: W = Anode Mass (kg), ε = Anode Efficiency (0.50 for Mg, 0.90 for Zn), '
                'μ = Theoretical Capacity (A·h/kg), u = Utilization factor (0.85), '
                'I = Mean Protective Current (Amperes), 8,760 = Hours per Year.',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Alloy Selection Grid
        const Text(
          'SELECT ANODE ALLOY METALLURGY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: SacrificialAlloyType.values.map((alloy) {
            final isSelected = _calcAlloy == alloy;
            return Expanded(
              child: GestureDetector(
                onTap: () => _updateCalculatorAlloy(alloy),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? alloy.badgeColor.withValues(alpha: 0.15) : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? alloy.badgeColor : AppTheme.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(alloy.icon, size: 18, color: alloy.badgeColor),
                      const SizedBox(height: 4),
                      Text(
                        alloy.name.split(' ').first,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? alloy.badgeColor : AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'ε = ${(alloy.efficiencyFactor * 100).toInt()}%',
                        style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Interactive Parameter Sliders
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
                'GROUNDBED DESIGN INPUTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 12),

              // Ribbon Length & Mass
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ribbon Length: ${_calcRibbonLengthM.toStringAsFixed(0)} m',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  Text(
                    'Calculated Mass W: ${_calcMassKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
                  ),
                ],
              ),
              Slider(
                value: _calcRibbonLengthM,
                min: 20.0,
                max: 1000.0,
                divisions: 98,
                activeColor: AppTheme.primaryLight,
                inactiveColor: AppTheme.border,
                onChanged: (val) {
                  setState(() {
                    _calcRibbonLengthM = val;
                    _calcMassKg = val * _calcAlloy.typicalLinearMassKgPerM;
                    _recalculateCurrent();
                  });
                },
              ),

              // Soil Resistivity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Soil Resistivity (ρ): ${_calcSoilResistivity.toStringAsFixed(0)} Ω·m',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  Text(
                    'Driving ΔE: ${(drivingDeltaV * 1000).toStringAsFixed(0)} mV',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFB95F)),
                  ),
                ],
              ),
              Slider(
                value: _calcSoilResistivity,
                min: 5.0,
                max: 300.0,
                divisions: 59,
                activeColor: const Color(0xFFFFB95F),
                inactiveColor: AppTheme.border,
                onChanged: (val) {
                  setState(() {
                    _calcSoilResistivity = val;
                    _recalculateCurrent();
                  });
                },
              ),

              // Pipe Polarized Potential
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pipe Polarized E_pipe: ${_calcPipePotentialMv.toStringAsFixed(0)} mV CSE',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  Text(
                    'Anode E_oc: ${_calcAlloy.defaultOpenCircuitPotentialMv.toStringAsFixed(0)} mV',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _calcAlloy.badgeColor),
                  ),
                ],
              ),
              Slider(
                value: _calcPipePotentialMv,
                min: -1150.0,
                max: -700.0,
                divisions: 45,
                activeColor: const Color(0xFF4EDEA3),
                inactiveColor: AppTheme.border,
                onChanged: (val) {
                  setState(() {
                    _calcPipePotentialMv = val;
                    _recalculateCurrent();
                  });
                },
              ),

              // Protective Current Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Protective Current Output (I): ${_calcCurrentMa.toStringAsFixed(1)} mA',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  Row(
                    children: [
                      const Text('Auto (I=ΔE/R)', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      Switch(
                        value: _calcAutoCurrentFromResistance,
                        activeColor: AppTheme.primaryLight,
                        onChanged: (val) {
                          setState(() {
                            _calcAutoCurrentFromResistance = val;
                            if (val) _recalculateCurrent();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (!_calcAutoCurrentFromResistance)
                Slider(
                  value: _calcCurrentMa,
                  min: 5.0,
                  max: 500.0,
                  divisions: 99,
                  activeColor: AppTheme.primaryLight,
                  inactiveColor: AppTheme.border,
                  onChanged: (val) {
                    setState(() => _calcCurrentMa = val);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Design Life Results Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.surfaceCard,
                designLifeYears >= 25.0 ? const Color(0xFF4EDEA3).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: designLifeYears >= 25.0 ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CALCULATED ANODE DESIGN LIFE (T)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            designLifeYears.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: designLifeYears >= 25.0 ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'YEARS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: designLifeYears >= 25.0
                          ? const Color(0xFF4EDEA3).withValues(alpha: 0.2)
                          : const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: designLifeYears >= 25.0 ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
                      ),
                    ),
                    child: Text(
                      designLifeYears >= 25.0 ? 'TARGET 25-YR ACHIEVED' : 'LIFE DEFICIENT (<25 YR)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: designLifeYears >= 25.0 ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 12),

              // Secondary Metrics
              Row(
                children: [
                  _buildResultMiniCol(
                    label: 'CONSUMPTION RATE (Cr)',
                    value: '${consumptionRate.toStringAsFixed(2)} kg/A-yr',
                  ),
                  _buildResultMiniCol(
                    label: 'ANNUAL LOSS',
                    value: '${annualConsumptionKg.toStringAsFixed(2)} kg/yr',
                  ),
                  _buildResultMiniCol(
                    label: 'EFFECTIVE CAPACITY',
                    value: '${(totalEffectiveAh / 1000.0).toStringAsFixed(1)} kAh',
                  ),
                  _buildResultMiniCol(
                    label: 'DRIVING VOLTAGE',
                    value: '${(drivingDeltaV * 1000).toStringAsFixed(0)} mV',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 30-Year Anode Depletion Forecast Line Chart
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '30-YEAR ANODE MASS DEPLETION PROFILE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    'Mass (kg) vs Time (Years)',
                    style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: LineChart(
                  _buildDepletionLineChartData(
                    initialMass: _calcMassKg,
                    annualLoss: annualConsumptionKg,
                    designLife: designLifeYears,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultMiniCol({required String label, required String value}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  LineChartData _buildDepletionLineChartData({
    required double initialMass,
    required double annualLoss,
    required double designLife,
  }) {
    final spots = <FlSpot>[];
    for (int yr = 0; yr <= 30; yr += 5) {
      final remaining = math.max(0.0, initialMass - (annualLoss * yr));
      spots.add(FlSpot(yr.toDouble(), remaining));
    }

    final cutoffMass = initialMass * (1.0 - 0.85); // 85% utilization cutoff

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: initialMass > 0 ? (initialMass / 4) : 25,
        verticalInterval: 5,
        getDrawingHorizontalLine: (val) => const FlLine(color: AppTheme.border, strokeWidth: 0.6),
        getDrawingVerticalLine: (val) => const FlLine(color: AppTheme.border, strokeWidth: 0.6),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            getTitlesWidget: (val, _) => Text(
              '${val.toInt()}k',
              style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: 5,
            getTitlesWidget: (val, _) => Text(
              'Y${val.toInt()}',
              style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
            ),
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: AppTheme.border),
      ),
      minX: 0,
      maxX: 30,
      minY: 0,
      maxY: initialMass * 1.15,
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: cutoffMass,
            color: const Color(0xFFEF4444).withValues(alpha: 0.8),
            strokeWidth: 1.2,
            dashArray: [5, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              style: const TextStyle(fontSize: 9, color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
              labelResolver: (_) => '85% EOL Cutoff',
            ),
          ),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: AppTheme.primaryLight,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.primary.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 3: 220 KV POWERGRID AC MITIGATION & ZINC RIBBON MATS
  // ============================================================================

  Widget _buildPowerGridAcMitigationTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // RoW Engineering Banner
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
                  Icon(Icons.bolt_rounded, size: 22, color: Color(0xFFFFB95F)),
                  SizedBox(width: 8),
                  Text(
                    '220kV HVAC PARALLEL TRANSMISSION CORRIDOR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'PowerGrid 220kV Double-Circuit transmission lines co-located within 15-45 meters '
                'of the 24-inch natural gas pipeline. Induces electromagnetic field (EMF) creating '
                'touch hazard potentials (>15V RMS) and AC-induced corrosion pitting (>30 A/m²). '
                'Mitigated via continuous Zinc Ribbon (ASTM B418-II) grounding mats and Solid-State Decouplers (SSD).',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildAcBadge('Touch Hazard Limit: < 15.0 V RMS (NACE SP0177)'),
                  _buildAcBadge('AC Current Density: < 30 A/m² Safe (ISO 18086)'),
                  _buildAcBadge('Solid-State Decouplers: 5kA / 100kA Surge Rated'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // AC Voltage Profile Line Chart: Unmitigated vs Mitigated
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'INDUCED AC VOLTAGE PROFILE (RMS)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Row(
                    children: [
                      _LegendPill(color: Color(0xFFEF4444), label: 'Unmitigated'),
                      SizedBox(width: 8),
                      _LegendPill(color: Color(0xFF4EDEA3), label: 'Mitigated (Zn)'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 190,
                child: LineChart(_buildAcMitigationChartData()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // AC Interference Spans List
        const Text(
          'POWERGRID CO-LOCATION SPAN SECTORS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        ..._acSpans.map((span) => _buildAcSpanCard(span)),
      ],
    );
  }

  Widget _buildAcBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryLight),
      ),
    );
  }

  LineChartData _buildAcMitigationChartData() {
    const unmitigated = [
      FlSpot(0, 12.0),
      FlSpot(4, 28.0),
      FlSpot(8, 48.5),
      FlSpot(12, 38.0),
      FlSpot(16, 22.0),
      FlSpot(20, 64.0),
      FlSpot(24, 45.0),
      FlSpot(28, 18.0),
      FlSpot(32, 32.0),
      FlSpot(36, 14.0),
    ];

    const mitigated = [
      FlSpot(0, 3.2),
      FlSpot(4, 5.8),
      FlSpot(8, 11.8),
      FlSpot(12, 9.4),
      FlSpot(16, 4.6),
      FlSpot(20, 14.8),
      FlSpot(24, 11.2),
      FlSpot(28, 4.0),
      FlSpot(32, 8.5),
      FlSpot(36, 3.8),
    ];

    return LineChartData(
      gridData: const FlGridData(
        show: true,
        horizontalInterval: 15,
        verticalInterval: 4,
        drawVerticalLine: true,
        getDrawingHorizontalLine: _gridLine,
        getDrawingVerticalLine: _gridLine,
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 15,
            getTitlesWidget: (val, _) => Text(
              '${val.toInt()}V',
              style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: 4,
            getTitlesWidget: (val, _) => Text(
              'KP${val.toInt()}',
              style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
            ),
          ),
        ),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.border)),
      minX: 0,
      maxX: 36,
      minY: 0,
      maxY: 75,
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: 15.0,
            color: const Color(0xFFFFB95F),
            strokeWidth: 1.2,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              style: const TextStyle(fontSize: 9, color: Color(0xFFFFB95F), fontWeight: FontWeight.w700),
              labelResolver: (_) => '15V NACE SP0177 Limit',
            ),
          ),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: unmitigated,
          isCurved: true,
          color: const Color(0xFFEF4444),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: mitigated,
          isCurved: true,
          color: const Color(0xFF4EDEA3),
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF4EDEA3).withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  static FlLine _gridLine(double _) => const FlLine(color: AppTheme.border, strokeWidth: 0.5);

  Widget _buildAcSpanCard(AcInterferenceSpan span) {
    final isWarn = span.mitigatedAcVoltageV >= 15.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWarn ? const Color(0xFFFFB95F) : AppTheme.border,
          width: isWarn ? 1.2 : 1.0,
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
                  Icon(
                    isWarn ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                    size: 16,
                    color: isWarn ? const Color(0xFFFFB95F) : const Color(0xFF4EDEA3),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    span.spanId,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    span.chainageRange,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isWarn ? const Color(0xFFFFB95F).withValues(alpha: 0.15) : const Color(0xFF4EDEA3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  span.status,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isWarn ? const Color(0xFFFFB95F) : const Color(0xFF4EDEA3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSpanMetric('Unmitigated Vac', '${span.unmitigatedAcVoltageV.toStringAsFixed(1)} V', const Color(0xFFEF4444)),
              _buildSpanMetric('Mitigated Vac', '${span.mitigatedAcVoltageV.toStringAsFixed(1)} V', isWarn ? const Color(0xFFFFB95F) : const Color(0xFF4EDEA3)),
              _buildSpanMetric('Zn Ribbon', '${span.zincRibbonLengthM.toStringAsFixed(0)} m', AppTheme.primaryLight),
              _buildSpanMetric('Decouplers (SSD)', '${span.solidStateDecouplersCount} Units', AppTheme.textPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpanMetric(String title, String val, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 8.5, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: SHUNT SURVEY LOG & CALIBRATED CURRENT READINGS
  // ============================================================================

  Widget _buildSurveyLogAndShuntTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CALIBRATED SHUNT CURRENT SURVEY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceCard,
                foregroundColor: AppTheme.primaryLight,
                side: const BorderSide(color: AppTheme.border),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Reading', style: TextStyle(fontSize: 11)),
              onPressed: _showAddSurveyDialog,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Shunt Table Card
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.surface),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              columnSpacing: 18,
              columns: const [
                DataColumn(label: Text('Station', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight))),
                DataColumn(label: Text('Alloy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                DataColumn(label: Text('Shunt (Ω)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                DataColumn(label: Text('Drop (mV)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                DataColumn(label: Text('Current I (mA)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4EDEA3)))),
                DataColumn(label: Text('E_off (mV)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                DataColumn(label: Text('Driving ΔE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFFFB95F)))),
                DataColumn(label: Text('Life (Yrs)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                DataColumn(label: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
              ],
              rows: _stations.map((s) {
                final isWarn = s.complianceStatus != StationComplianceStatus.fullyCompliant;
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.stationTag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                          Text(s.chainageStr, style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        s.alloyType.name.split(' ').first,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: s.alloyType.badgeColor),
                      ),
                    ),
                    DataCell(Text(s.calibratedShuntResistanceOhms.toStringAsFixed(3), style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary))),
                    DataCell(Text(s.shuntVoltageDropMv.toStringAsFixed(2), style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary))),
                    DataCell(
                      Text(
                        s.calculatedCurrentMa.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4EDEA3)),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${s.instantOffPotentialMv.toStringAsFixed(0)} mV',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: s.instantOffPotentialMv <= -850 ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${s.drivingPotentialMv.toStringAsFixed(0)} mV',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFFFB95F)),
                      ),
                    ),
                    DataCell(Text(s.calculatedDesignLifeYears.toStringAsFixed(1), style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: s.complianceStatus.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          s.complianceStatus.label.split(' ').first,
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: s.complianceStatus.color),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 5: NACE SP0169 / DNV-RP-F103 ENGINEERING AUDIT
  // ============================================================================

  Widget _buildStandardsAndAuditTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Standard Overview
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INTERNATIONAL REGULATORY DESIGN CODE MATRIX',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Nirmaan OS performs automated rule-based compliance checking against NACE SP0169-2013 '
                'external corrosion control, DNV-RP-F103 galvanic cathodic protection of marine/trenchless pipelines, '
                'and NACE SP0177 / EN 15280 AC interference mitigation rules.',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Compliance Rules Breakdown
        _buildComplianceRuleCard(
          title: 'Criterion 1: -850 mV Polarized Instant-OFF (IR-Free)',
          standard: 'NACE SP0169 Section 6.2.1.1',
          description: 'A negative (cathodic) polarized potential of at least -850 mV relative to a saturated copper/copper sulfate (CSE) reference electrode. All voltage (IR) drops other than across the structure-to-electrolyte boundary must be eliminated using instant disconnect coupon switches.',
          statusText: 'PASS: 7 of 8 Stations Compliant (87.5%)',
          isPass: true,
        ),
        _buildComplianceRuleCard(
          title: 'Criterion 2: 100 mV Cathodic Polarization Decay',
          standard: 'NACE SP0169 Section 6.2.1.2',
          description: 'A minimum of 100 mV of cathodic polarization between the structure surface and a stable reference electrode in contact with the electrolyte. Verified by measuring instant-off potential minus baseline depolarized native steel potential.',
          statusText: 'PASS: 8 of 8 Stations Achieved >100 mV Decay',
          isPass: true,
        ),
        _buildComplianceRuleCard(
          title: 'Criterion 3: Upper Limit -1,200 mV (Hydrogen Embrittlement)',
          standard: 'NACE SP0169 / ISO 15589-1',
          description: 'Polarized potential shall not be more negative than -1,200 mV CSE on high-strength pipeline steels (API 5L X70 / X80) to prevent cathodic disbondment and hydrogen-induced cracking (HIC). High-potential Mg ribbons in low resistivity soils must be current-limited.',
          statusText: 'ALERT: TS-29 (-1,215 mV) Over-Protected in Waterlogged Clay',
          isPass: false,
        ),
        _buildComplianceRuleCard(
          title: 'Criterion 4: AC Interference Touch Voltage < 15 V RMS',
          standard: 'NACE SP0177 / EN 15280 / ISO 18086',
          description: 'Induced AC pipe-to-soil voltage must remain below 15.0 V RMS under continuous steady-state conditions to avoid personal electrical shock hazard and mitigate AC corrosion pitting (coupon AC current density Jac < 30 A/m²).',
          statusText: 'WARNING: TS-21 (16.4 V RMS) Exceeds 15V Threshold',
          isPass: false,
        ),
        _buildComplianceRuleCard(
          title: 'Criterion 5: DNV-RP-F103 Marine & Trenchless Design Life',
          standard: 'DNV-RP-F103 Section 5',
          description: 'Aluminium-Zinc-Indium alloy ribbon and bracelet anodes deployed in river crossing HDD bores and estuarine sections must provide minimum 25-year design life with electrochemical capacity >= 2,000 A·h/kg and closed-circuit driving voltage >= 0.25 V.',
          statusText: 'PASS: Burhi Dihing HDD Crossing Life: 34.2 Years',
          isPass: true,
        ),
      ],
    );
  }

  Widget _buildComplianceRuleCard({
    required String title,
    required String standard,
    required String description,
    required String statusText,
    required bool isPass,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPass ? const Color(0xFF4EDEA3).withValues(alpha: 0.4) : const Color(0xFFFFB95F).withValues(alpha: 0.5),
        ),
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  standard,
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPass ? const Color(0xFF4EDEA3).withValues(alpha: 0.15) : const Color(0xFFFFB95F).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPass ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  size: 13,
                  color: isPass ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F),
                ),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPass ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F),
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
  // DIALOGS & ACTION SHEETS
  // ============================================================================

  void _showAddSurveyDialog() {
    final formKey = GlobalKey<FormState>();
    final tagCtrl = TextEditingController(text: 'TS-${_stations.length + 1}');
    final chainageCtrl = TextEditingController(text: 'KP 33+400');
    final locCtrl = TextEditingController(text: 'Naharkatia Station Inlet');
    final shuntDropCtrl = TextEditingController(text: '4.50');
    final shuntValCtrl = TextEditingController(text: '0.100');
    final offCtrl = TextEditingController(text: '-935');
    final onCtrl = TextEditingController(text: '-1060');
    final vacCtrl = TextEditingController(text: '4.2');
    SacrificialAlloyType selectedAlloy = SacrificialAlloyType.highPotentialMg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Row(
            children: [
              Icon(Icons.add_chart_rounded, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Log Test Station Survey Reading',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Station Information', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: tagCtrl,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                          decoration: const InputDecoration(labelText: 'Station Tag', isDense: true),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: chainageCtrl,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                          decoration: const InputDecoration(labelText: 'Chainage KP', isDense: true),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: locCtrl,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Landmark / Terrain', isDense: true),
                  ),
                  const SizedBox(height: 12),

                  const Text('Anode Metallurgy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<SacrificialAlloyType>(
                    value: selectedAlloy,
                    dropdownColor: AppTheme.surfaceCard,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    decoration: const InputDecoration(isDense: true),
                    items: SacrificialAlloyType.values.map((a) {
                      return DropdownMenuItem(value: a, child: Text(a.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedAlloy = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  const Text('Calibrated Shunt Reading', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: shuntValCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                          decoration: const InputDecoration(labelText: 'Shunt (Ω)', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: shuntDropCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                          decoration: const InputDecoration(labelText: 'Drop (mV)', isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Text('Potentials (mV vs CSE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: onCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                          decoration: const InputDecoration(labelText: 'E_on (mV)', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: offCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                          decoration: const InputDecoration(labelText: 'E_off (mV)', isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: vacCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: '220kV Induced Vac (V RMS)', isDense: true),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final shuntDrop = double.tryParse(shuntDropCtrl.text) ?? 4.5;
                  final shuntVal = double.tryParse(shuntValCtrl.text) ?? 0.100;
                  final offVal = double.tryParse(offCtrl.text) ?? -935.0;
                  final onVal = double.tryParse(onCtrl.text) ?? -1060.0;
                  final vac = double.tryParse(vacCtrl.text) ?? 4.2;

                  final newStation = TestStationTelemetry(
                    id: 'TS-${_stations.length + 1}',
                    stationTag: tagCtrl.text.trim(),
                    chainageKm: 33.400,
                    chainageStr: chainageCtrl.text.trim(),
                    locationTitle: locCtrl.text.trim(),
                    alloyType: selectedAlloy,
                    deploymentForm: AnodeDeploymentForm.continuousRibbonTrench,
                    ribbonLengthM: 150.0,
                    totalAnodeMassKg: 55.0,
                    openCircuitPotentialMv: selectedAlloy.defaultOpenCircuitPotentialMv,
                    closedCircuitPotentialMv: onVal,
                    instantOffPotentialMv: offVal,
                    nativePotentialMv: -570.0,
                    calibratedShuntResistanceOhms: shuntVal,
                    shuntVoltageDropMv: shuntDrop,
                    soilResistivityOhmM: 45.0,
                    acInducedVoltageV: vac,
                    acCouponCurrentDensityAm2: 5.8,
                    hasSolidStateDecoupler: vac >= 15.0,
                    decouplerStatus: vac >= 15.0 ? 'Normal' : 'N/A',
                    couponSwitchState: CouponSwitchState.closed,
                    surveyTimestamp: DateTime.now(),
                    inspectorName: 'Er. Rajesh Borah',
                  );

                  setState(() {
                    _stations.insert(0, newStation);
                  });
                  Navigator.of(ctx).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test station reading logged: ${newStation.stationTag} (${newStation.calculatedCurrentMa.toStringAsFixed(1)} mA)'),
                      backgroundColor: const Color(0xFF4EDEA3),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Save Reading'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSimulationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sacrificial Anode Quick Presets',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an industrial installation scenario to simulate design parameters:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.bolt_rounded, color: Color(0xFFFFB95F)),
              title: const Text('PowerGrid 220kV AC Mitigation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Zinc ribbon grounding mat (ASTM B418-II) + SSD Decouplers', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.of(ctx).pop();
                _updateCalculatorAlloy(SacrificialAlloyType.zincRibbonSoil);
                _tabController.animateTo(2); // AC Mitigation Tab
              },
            ),
            ListTile(
              leading: const Icon(Icons.terrain_rounded, color: Color(0xFF38BDF8)),
              title: const Text('High-Resistivity Soil (>2,000 Ω·cm)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('High-Potential Magnesium Ribbon (ASTM B843 M1C, -1.75V CSE)', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.of(ctx).pop();
                _updateCalculatorAlloy(SacrificialAlloyType.highPotentialMg);
                _tabController.animateTo(1); // Calculator Tab
              },
            ),
            ListTile(
              leading: const Icon(Icons.water_rounded, color: Color(0xFF4EDEA3)),
              title: const Text('HDD River Crossing / Saline Wetland', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Al-Zn-In ribbon per DNV-RP-F103 (2,980 Ah/kg capacity)', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.of(ctx).pop();
                _updateCalculatorAlloy(SacrificialAlloyType.aluminiumRibbon);
                _tabController.animateTo(1);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDossierDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primaryLight, size: 20),
            SizedBox(width: 8),
            Text(
              'Export CP Dossier',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'Generate comprehensive NACE SP0169 / DNV-RP-F103 Cathodic Protection '
          'Engineering Verification Dossier with all test station shunts, coupon disconnect '
          'telemetry, and 220kV AC mitigation models?',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cathodic Protection Engineering Dossier compiled successfully.'),
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Generate Dossier'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AUXILIARY WIDGETS
// ============================================================================

class _StandardComplianceBadge extends StatelessWidget {
  const _StandardComplianceBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6)),
      ),
      child: const Text(
        'NACE / DNV',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryLight,
        ),
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
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
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
