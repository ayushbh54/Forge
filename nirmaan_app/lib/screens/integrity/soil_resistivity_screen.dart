import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';

// ============================================================================
// ENUMS & DOMAIN CONSTANTS
// ============================================================================

enum SoilCorrosivityClass {
  extremelyCorrosive, // < 500 Ohm-cm (< 5 Ohm-m)
  veryCorrosive, // 500 - 1,000 Ohm-cm (5 - 10 Ohm-m)
  corrosive, // 1,000 - 2,000 Ohm-cm (10 - 20 Ohm-m)
  moderatelyCorrosive, // 2,000 - 10,000 Ohm-cm (20 - 100 Ohm-m)
  mildlyNonCorrosive, // > 10,000 Ohm-cm (> 100 Ohm-m)
}

extension SoilCorrosivityClassExt on SoilCorrosivityClass {
  String get label {
    switch (this) {
      case SoilCorrosivityClass.extremelyCorrosive:
        return 'Extremely Corrosive (< 5 Ω·m)';
      case SoilCorrosivityClass.veryCorrosive:
        return 'Very Corrosive (5 - 10 Ω·m)';
      case SoilCorrosivityClass.corrosive:
        return 'Corrosive (10 - 20 Ω·m)';
      case SoilCorrosivityClass.moderatelyCorrosive:
        return 'Moderately Corrosive (20 - 100 Ω·m)';
      case SoilCorrosivityClass.mildlyNonCorrosive:
        return 'Mild / Non-Corrosive (> 100 Ω·m)';
    }
  }

  String get shortLabel {
    switch (this) {
      case SoilCorrosivityClass.extremelyCorrosive:
        return 'Severe (< 5 Ω·m)';
      case SoilCorrosivityClass.veryCorrosive:
        return 'High (5-10 Ω·m)';
      case SoilCorrosivityClass.corrosive:
        return 'Corrosive (10-20 Ω·m)';
      case SoilCorrosivityClass.moderatelyCorrosive:
        return 'Moderate (20-100 Ω·m)';
      case SoilCorrosivityClass.mildlyNonCorrosive:
        return 'Mild (> 100 Ω·m)';
    }
  }

  Color get color {
    switch (this) {
      case SoilCorrosivityClass.extremelyCorrosive:
        return const Color(0xFFEF4444); // Red
      case SoilCorrosivityClass.veryCorrosive:
        return const Color(0xFFF97316); // Deep Orange
      case SoilCorrosivityClass.corrosive:
        return const Color(0xFFFFB95F); // Amber
      case SoilCorrosivityClass.moderatelyCorrosive:
        return const Color(0xFF38BDF8); // Cyan
      case SoilCorrosivityClass.mildlyNonCorrosive:
        return const Color(0xFF4EDEA3); // Tertiary Green
    }
  }

  IconData get icon {
    switch (this) {
      case SoilCorrosivityClass.extremelyCorrosive:
        return Icons.dangerous_rounded;
      case SoilCorrosivityClass.veryCorrosive:
        return Icons.warning_rounded;
      case SoilCorrosivityClass.corrosive:
        return Icons.report_problem_rounded;
      case SoilCorrosivityClass.moderatelyCorrosive:
        return Icons.verified_user_outlined;
      case SoilCorrosivityClass.mildlyNonCorrosive:
        return Icons.shield_rounded;
    }
  }

  double get recommendedCpCurrentDensityMaPerM2 {
    switch (this) {
      case SoilCorrosivityClass.extremelyCorrosive:
        return 35.0; // High bare current requirement
      case SoilCorrosivityClass.veryCorrosive:
        return 25.0;
      case SoilCorrosivityClass.corrosive:
        return 18.0;
      case SoilCorrosivityClass.moderatelyCorrosive:
        return 12.0;
      case SoilCorrosivityClass.mildlyNonCorrosive:
        return 8.0;
    }
  }

  static SoilCorrosivityClass fromRho(double rhoOhmM) {
    if (rhoOhmM < 5.0) return SoilCorrosivityClass.extremelyCorrosive;
    if (rhoOhmM < 10.0) return SoilCorrosivityClass.veryCorrosive;
    if (rhoOhmM < 20.0) return SoilCorrosivityClass.corrosive;
    if (rhoOhmM < 100.0) return SoilCorrosivityClass.moderatelyCorrosive;
    return SoilCorrosivityClass.mildlyNonCorrosive;
  }
}

enum AnodeMaterialType {
  mmoTitanium,
  hsciAlloy,
}

extension AnodeMaterialTypeExt on AnodeMaterialType {
  String get name {
    switch (this) {
      case AnodeMaterialType.mmoTitanium:
        return 'MMO / Titanium Tube';
      case AnodeMaterialType.hsciAlloy:
        return 'High-Silicon Cr-Iron (HSCI)';
    }
  }

  String get standardSpec {
    switch (this) {
      case AnodeMaterialType.mmoTitanium:
        return 'ASTM B348 Gr 1 Substrate + IrO2/Ta2O5 Coating';
      case AnodeMaterialType.hsciAlloy:
        return 'ASTM A518 Grade 3 (14.5% Si, 4.5% Cr)';
    }
  }

  double get defaultConsumptionRateKgPerAmpYear {
    switch (this) {
      case AnodeMaterialType.mmoTitanium:
        // ~1.5 mg/A-year = 0.0000015 kg/A-year
        return 0.0000015;
      case AnodeMaterialType.hsciAlloy:
        // 0.25 kg/A-year in calcined petroleum coke backfill
        return 0.250;
    }
  }

  double get defaultNominalMassKg {
    switch (this) {
      case AnodeMaterialType.mmoTitanium:
        return 1.45; // Titanium tube with connection core
      case AnodeMaterialType.hsciAlloy:
        return 45.0; // Solid stick 2" x 60"
    }
  }

  double get maxCurrentCapacityAmps {
    switch (this) {
      case AnodeMaterialType.mmoTitanium:
        return 8.0; // Tubular MMO up to 8A in carbon backfill
      case AnodeMaterialType.hsciAlloy:
        return 4.5; // HSCI recommended max 4.0 - 4.5A
    }
  }
}

enum GroundbedStatus {
  compliant, // Rg < 1.0 Ohm
  marginal, // 1.0 <= Rg < 1.5 Ohm
  highResistanceAlert, // Rg >= 1.5 Ohm
}

extension GroundbedStatusExt on GroundbedStatus {
  String get label {
    switch (this) {
      case GroundbedStatus.compliant:
        return 'COMPLIANT (Rg < 1.0 Ω)';
      case GroundbedStatus.marginal:
        return 'MARGINAL (1.0 ≤ Rg < 1.5 Ω)';
      case GroundbedStatus.highResistanceAlert:
        return 'HIGH RESISTANCE ALERT (Rg ≥ 1.5 Ω)';
    }
  }

  Color get color {
    switch (this) {
      case GroundbedStatus.compliant:
        return const Color(0xFF4EDEA3);
      case GroundbedStatus.marginal:
        return const Color(0xFFFFB95F);
      case GroundbedStatus.highResistanceAlert:
        return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case GroundbedStatus.compliant:
        return Icons.check_circle_rounded;
      case GroundbedStatus.marginal:
        return Icons.warning_amber_rounded;
      case GroundbedStatus.highResistanceAlert:
        return Icons.error_outline_rounded;
    }
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

/// Represents a single Wenner 4-pin spacing test per ASTM G57
class WennerPinReading {
  final double pinSpacingA; // Spacing 'a' in meters (1m, 2m, 3m, 5m, 10m)
  double measuredResistanceOhms; // Measured R in Ohms
  final double pinDepthMeters; // Insertion depth 'd' in meters (d <= 0.05 a)
  final double soilTempC; // Soil temperature
  final int testFrequencyHz; // 97 Hz or 128 Hz

  WennerPinReading({
    required this.pinSpacingA,
    required this.measuredResistanceOhms,
    this.pinDepthMeters = 0.05,
    this.soilTempC = 25.0,
    this.testFrequencyHz = 128,
  });

  /// ASTM G57 Apparent Soil Resistivity Formula:
  /// rho = 2 * pi * a * R (Ohm-meter)
  double get apparentResistivityRho {
    return 2.0 * math.pi * pinSpacingA * measuredResistanceOhms;
  }

  /// Resistivity in Ohm-cm (1 Ohm-m = 100 Ohm-cm)
  double get resistivityOhmCm => apparentResistivityRho * 100.0;

  /// ASTM G57 Temperature Correction to 20°C:
  /// rho_20 = rho_T * ((T + 24.5) / (20.0 + 24.5))
  double get temperatureCorrectedRho {
    return apparentResistivityRho * ((soilTempC + 24.5) / (20.0 + 24.5));
  }

  /// Check ASTM G57 electrode depth rule: d <= 0.05 * a
  bool get isElectrodeDepthCompliant => pinDepthMeters <= (0.05 * pinSpacingA);

  SoilCorrosivityClass get corrosivityClass =>
      SoilCorrosivityClassExt.fromRho(apparentResistivityRho);

  WennerPinReading copyWith({
    double? pinSpacingA,
    double? measuredResistanceOhms,
    double? pinDepthMeters,
    double? soilTempC,
    int? testFrequencyHz,
  }) {
    return WennerPinReading(
      pinSpacingA: pinSpacingA ?? this.pinSpacingA,
      measuredResistanceOhms:
          measuredResistanceOhms ?? this.measuredResistanceOhms,
      pinDepthMeters: pinDepthMeters ?? this.pinDepthMeters,
      soilTempC: soilTempC ?? this.soilTempC,
      testFrequencyHz: testFrequencyHz ?? this.testFrequencyHz,
    );
  }
}

/// Represents individual Anode Telemetry Node in a Deep Well Groundbed
class DwicgAnodeTelemetry {
  final int anodeIndex; // 1 to 12
  final String tag; // AN-01 to AN-12
  final double depthMeters; // Depth in well (e.g. 45m to 100m)
  double currentAmps; // Current output in Amperes
  double shuntResistanceOhms; // Calibrated shunt resistor (e.g. 0.010 Ohm)
  final String leadWireCondition; // e.g. "Kynar/HMWPE Intact"
  final double temperatureC;

  DwicgAnodeTelemetry({
    required this.anodeIndex,
    required this.tag,
    required this.depthMeters,
    required this.currentAmps,
    this.shuntResistanceOhms = 0.010,
    required this.leadWireCondition,
    this.temperatureC = 28.5,
  });

  double get shuntVoltageDropMv => currentAmps * shuntResistanceOhms * 1000.0;

  bool get isSevered => currentAmps <= 0.05;
  bool get isOvercurrent => currentAmps > 4.2;
  bool get isNominal => currentAmps >= 1.0 && currentAmps <= 3.8;

  DwicgAnodeTelemetry copyWith({
    int? anodeIndex,
    String? tag,
    double? depthMeters,
    double? currentAmps,
    double? shuntResistanceOhms,
    String? leadWireCondition,
    double? temperatureC,
  }) {
    return DwicgAnodeTelemetry(
      anodeIndex: anodeIndex ?? this.anodeIndex,
      tag: tag ?? this.tag,
      depthMeters: depthMeters ?? this.depthMeters,
      currentAmps: currentAmps ?? this.currentAmps,
      shuntResistanceOhms: shuntResistanceOhms ?? this.shuntResistanceOhms,
      leadWireCondition: leadWireCondition ?? this.leadWireCondition,
      temperatureC: temperatureC ?? this.temperatureC,
    );
  }
}

/// Deep Well Impressed Current Groundbed Record
class DwicgGroundbedRecord {
  final String id;
  final String name;
  final String chainage;
  final double chainageKm;
  final double totalBoreholeDepthM;
  final double activeColumnM;
  final double boreholeDiameterMm;
  final double casingDepthM;
  final List<DwicgAnodeTelemetry> anodes; // 12 Anodes
  double trVoltageVolts;
  double cokeBreezeResistanceOhms; // Inter-column resistance
  double cokeSettlingDeltaHM; // Settling height in meters
  final double gasVentPressurePsi;
  final double waterTableDepthM;
  final AnodeMaterialType anodeType;
  final DateTime installationDate;

  DwicgGroundbedRecord({
    required this.id,
    required this.name,
    required this.chainage,
    required this.chainageKm,
    required this.totalBoreholeDepthM,
    required this.activeColumnM,
    required this.boreholeDiameterMm,
    required this.casingDepthM,
    required this.anodes,
    required this.trVoltageVolts,
    required this.cokeBreezeResistanceOhms,
    required this.cokeSettlingDeltaHM,
    required this.gasVentPressurePsi,
    required this.waterTableDepthM,
    required this.anodeType,
    required this.installationDate,
  });

  /// Total Current Output across all 12 Anodes
  double get totalCurrentAmps =>
      anodes.fold(0.0, (acc, anode) => acc + anode.currentAmps);

  /// Groundbed Resistance-to-Earth: Rg = V_tr / I_total (Ohms)
  double get groundbedResistanceEarthOhms {
    final totalI = totalCurrentAmps;
    if (totalI <= 0.1) return 99.9;
    return trVoltageVolts / totalI;
  }

  GroundbedStatus get complianceStatus {
    final rg = groundbedResistanceEarthOhms;
    if (rg < 1.0) return GroundbedStatus.compliant;
    if (rg < 1.5) return GroundbedStatus.marginal;
    return GroundbedStatus.highResistanceAlert;
  }

  double get averageCurrentPerAnode {
    if (anodes.isEmpty) return 0.0;
    return totalCurrentAmps / anodes.length;
  }

  double get maxCurrentDifferencePercent {
    if (anodes.isEmpty) return 0.0;
    final avg = averageCurrentPerAnode;
    if (avg <= 0.01) return 0.0;
    double maxDiff = 0.0;
    for (final a in anodes) {
      final diff = (a.currentAmps - avg).abs();
      if (diff > maxDiff) maxDiff = diff;
    }
    return (maxDiff / avg) * 100.0;
  }
}

/// Location Survey Dossier for ASTM G57 Wenner Surveys
class SurveyLocationDossier {
  final String id;
  final String locationName;
  final String chainage;
  final double chainageKm;
  final String gpsCoords;
  final String soilStrataDescription;
  final DateTime surveyDate;
  final String surveyorName;
  final String testerInstrument;
  final List<WennerPinReading> readings;
  final String notes;

  SurveyLocationDossier({
    required this.id,
    required this.locationName,
    required this.chainage,
    required this.chainageKm,
    required this.gpsCoords,
    required this.soilStrataDescription,
    required this.surveyDate,
    required this.surveyorName,
    required this.testerInstrument,
    required this.readings,
    required this.notes,
  });

  double get minResistivityRho {
    if (readings.isEmpty) return 0.0;
    return readings
        .map((r) => r.apparentResistivityRho)
        .reduce((a, b) => a < b ? a : b);
  }

  double get maxResistivityRho {
    if (readings.isEmpty) return 0.0;
    return readings
        .map((r) => r.apparentResistivityRho)
        .reduce((a, b) => a > b ? a : b);
  }

  double get avgResistivityRho {
    if (readings.isEmpty) return 0.0;
    final sum =
        readings.fold(0.0, (acc, r) => acc + r.apparentResistivityRho);
    return sum / readings.length;
  }

  SoilCorrosivityClass get worstCorrosivityClass =>
      SoilCorrosivityClassExt.fromRho(minResistivityRho);
}

// ============================================================================
// SOIL RESISTIVITY & ANODE BED SCREEN WIDGET
// ============================================================================

class SoilResistivityScreen extends StatefulWidget {
  const SoilResistivityScreen({super.key});

  @override
  State<SoilResistivityScreen> createState() => _SoilResistivityScreenState();
}

class _SoilResistivityScreenState extends State<SoilResistivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Active Selected Station / Location
  late List<SurveyLocationDossier> _surveyLocations;
  late int _selectedLocationIndex;

  // Deep Well Groundbed Telemetry Records
  late List<DwicgGroundbedRecord> _groundbeds;
  late int _selectedGroundbedIndex;

  // Anode Consumption Calculator Parameters
  AnodeMaterialType _calcMaterial = AnodeMaterialType.mmoTitanium;
  double _calcInitialMassKg = 1.45;
  double _calcOperatingCurrentAmps = 2.25;
  final int _calcActiveAnodeCount = 12;
  double _calcYearsInService = 4.2;
  double _calcUtilizationLimit = 0.80; // 80% maximum consumption limit
  double _calcConsumptionRate = 0.0000015; // kg/A-year for MMO

  // Coke Breeze Replenishment Calculator State
  double _replenishWellDiameterMm = 200.0;
  double _replenishSettlingDeltaHM = 2.8;
  final double _replenishCokeBulkDensityKgM3 = 1120.0;
  final double _replenishBagWeightKg = 25.0;

  // Audit Logs
  final List<Map<String, dynamic>> _auditLog = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    // 1. ASTM G57 Wenner 4-Pin Surveys along Pipeline Corridor
    _surveyLocations = [
      SurveyLocationDossier(
        id: 'SURV-ASTM-01',
        locationName: 'Duliajan CPF Terminal Corridor',
        chainage: 'KP 04+200',
        chainageKm: 4.200,
        gpsCoords: "27°21'32.4\"N, 95°19'11.8\"E",
        soilStrataDescription:
            'Alluvial clayey silt overlaying dense water-saturated loam',
        surveyDate: DateTime.now().subtract(const Duration(days: 3)),
        surveyorName: 'Er. R. Borah (NACE CP-3 #49281)',
        testerInstrument: 'AEMC 6471 Ground & Soil Tester (128 Hz)',
        readings: [
          WennerPinReading(pinSpacingA: 1.0, measuredResistanceOhms: 1.85),
          WennerPinReading(pinSpacingA: 2.0, measuredResistanceOhms: 1.12),
          WennerPinReading(pinSpacingA: 3.0, measuredResistanceOhms: 0.78),
          WennerPinReading(pinSpacingA: 5.0, measuredResistanceOhms: 0.44),
          WennerPinReading(pinSpacingA: 10.0, measuredResistanceOhms: 0.21),
        ],
        notes:
            'Low resistivity topsoil layer prone to seasonal ponding. Requires cathodic protection current density of 25 mA/m².',
      ),
      SurveyLocationDossier(
        id: 'SURV-ASTM-02',
        locationName: 'Burhi Dihing River HDD Crossing',
        chainage: 'KP 18+750',
        chainageKm: 18.750,
        gpsCoords: "27°18'04.1\"N, 95°14'48.5\"E",
        soilStrataDescription:
            'Riparian marshland silt with brackish water table at 1.8m',
        surveyDate: DateTime.now().subtract(const Duration(days: 8)),
        surveyorName: 'Er. T. Sonowal (NACE CP-2)',
        testerInstrument: 'Megger DET4TC2 Multi-Frequency Tester (97 Hz)',
        readings: [
          WennerPinReading(pinSpacingA: 1.0, measuredResistanceOhms: 0.65),
          WennerPinReading(pinSpacingA: 2.0, measuredResistanceOhms: 0.42),
          WennerPinReading(pinSpacingA: 3.0, measuredResistanceOhms: 0.31),
          WennerPinReading(pinSpacingA: 5.0, measuredResistanceOhms: 0.18),
          WennerPinReading(pinSpacingA: 10.0, measuredResistanceOhms: 0.09),
        ],
        notes:
            'Severe corrosion risk zone. Soil resistivity < 5.0 Ω·m across all pin depths. Dedicated deep well groundbed commissioned.',
      ),
      SurveyLocationDossier(
        id: 'SURV-ASTM-03',
        locationName: 'Moran Tea Estate Pipeline Trench',
        chainage: 'KP 34+100',
        chainageKm: 34.100,
        gpsCoords: "27°12'19.7\"N, 95°05'22.0\"E",
        soilStrataDescription:
            'Laterite clay subsoil with iron gravel intrusions',
        surveyDate: DateTime.now().subtract(const Duration(days: 14)),
        surveyorName: 'Er. M. Barman (NACE CP-2)',
        testerInstrument: 'AEMC 6471 Ground & Soil Tester (128 Hz)',
        readings: [
          WennerPinReading(pinSpacingA: 1.0, measuredResistanceOhms: 4.80),
          WennerPinReading(pinSpacingA: 2.0, measuredResistanceOhms: 3.10),
          WennerPinReading(pinSpacingA: 3.0, measuredResistanceOhms: 2.15),
          WennerPinReading(pinSpacingA: 5.0, measuredResistanceOhms: 1.45),
          WennerPinReading(pinSpacingA: 10.0, measuredResistanceOhms: 0.88),
        ],
        notes:
            'Resistivity increases toward shallow strata. Deeper substrata displays moderate conductivity.',
      ),
      SurveyLocationDossier(
        id: 'SURV-ASTM-04',
        locationName: 'Sibsagar Wetland Approach',
        chainage: 'KP 62+800',
        chainageKm: 62.800,
        gpsCoords: "27°04'55.3\"N, 94°52'16.2\"E",
        soilStrataDescription: 'Peat moss & high humic organic soil',
        surveyDate: DateTime.now().subtract(const Duration(days: 20)),
        surveyorName: 'Er. R. Borah (NACE CP-3)',
        testerInstrument: 'Megger DET4TC2 Multi-Frequency Tester (128 Hz)',
        readings: [
          WennerPinReading(pinSpacingA: 1.0, measuredResistanceOhms: 1.10),
          WennerPinReading(pinSpacingA: 2.0, measuredResistanceOhms: 0.72),
          WennerPinReading(pinSpacingA: 3.0, measuredResistanceOhms: 0.54),
          WennerPinReading(pinSpacingA: 5.0, measuredResistanceOhms: 0.35),
          WennerPinReading(pinSpacingA: 10.0, measuredResistanceOhms: 0.16),
        ],
        notes:
            'High organic acids detected. Requires sacrificial grounding ribbon or continuous cathodic current.',
      ),
      SurveyLocationDossier(
        id: 'SURV-ASTM-05',
        locationName: 'Numaligarh Junction Terminal',
        chainage: 'KP 88+500',
        chainageKm: 88.500,
        gpsCoords: "26°56'28.9\"N, 94°38'42.1\"E",
        soilStrataDescription:
            'Dense riverbed cobbles, coarse sand & rocky dry subsoil',
        surveyDate: DateTime.now().subtract(const Duration(days: 25)),
        surveyorName: 'Er. D. Kalita (NACE CP-2)',
        testerInstrument: 'AEMC 6471 Ground & Soil Tester (128 Hz)',
        readings: [
          WennerPinReading(pinSpacingA: 1.0, measuredResistanceOhms: 18.2),
          WennerPinReading(pinSpacingA: 2.0, measuredResistanceOhms: 12.4),
          WennerPinReading(pinSpacingA: 3.0, measuredResistanceOhms: 8.6),
          WennerPinReading(pinSpacingA: 5.0, measuredResistanceOhms: 5.1),
          WennerPinReading(pinSpacingA: 10.0, measuredResistanceOhms: 2.8),
        ],
        notes:
            'Mildly corrosive upper strata (> 100 Ω·m). Deep well groundbed drilled to 110m to tap conductive water table layer.',
      ),
    ];
    _selectedLocationIndex = 0;

    // 2. DWICG Deep Well Impressed Current Groundbed Telemetry
    // Anode String 1 to 12 distributed along 100m well
    final List<DwicgAnodeTelemetry> dwicgAnodes1 = [
      DwicgAnodeTelemetry(
          anodeIndex: 1,
          tag: 'AN-01',
          depthMeters: 45.0,
          currentAmps: 2.15,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 2,
          tag: 'AN-02',
          depthMeters: 50.0,
          currentAmps: 2.22,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 3,
          tag: 'AN-03',
          depthMeters: 55.0,
          currentAmps: 2.30,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 4,
          tag: 'AN-04',
          depthMeters: 60.0,
          currentAmps: 2.45,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 5,
          tag: 'AN-05',
          depthMeters: 65.0,
          currentAmps: 2.50,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 6,
          tag: 'AN-06',
          depthMeters: 70.0,
          currentAmps: 2.40,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 7,
          tag: 'AN-07',
          depthMeters: 75.0,
          currentAmps: 2.35,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 8,
          tag: 'AN-08',
          depthMeters: 80.0,
          currentAmps: 2.28,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 9,
          tag: 'AN-09',
          depthMeters: 85.0,
          currentAmps: 2.18,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 10,
          tag: 'AN-10',
          depthMeters: 90.0,
          currentAmps: 2.05,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 11,
          tag: 'AN-11',
          depthMeters: 95.0,
          currentAmps: 1.95,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 12,
          tag: 'AN-12',
          depthMeters: 100.0,
          currentAmps: 1.87,
          leadWireCondition: 'Kynar/HMWPE Intact'),
    ];

    final List<DwicgAnodeTelemetry> dwicgAnodes2 = [
      DwicgAnodeTelemetry(
          anodeIndex: 1,
          tag: 'AN-01',
          depthMeters: 40.0,
          currentAmps: 0.12,
          leadWireCondition: 'Cable Degradation Alert'),
      DwicgAnodeTelemetry(
          anodeIndex: 2,
          tag: 'AN-02',
          depthMeters: 46.0,
          currentAmps: 1.40,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 3,
          tag: 'AN-03',
          depthMeters: 52.0,
          currentAmps: 1.85,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 4,
          tag: 'AN-04',
          depthMeters: 58.0,
          currentAmps: 2.90,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 5,
          tag: 'AN-05',
          depthMeters: 64.0,
          currentAmps: 3.45,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 6,
          tag: 'AN-06',
          depthMeters: 70.0,
          currentAmps: 3.60,
          leadWireCondition: 'High Current Bias'),
      DwicgAnodeTelemetry(
          anodeIndex: 7,
          tag: 'AN-07',
          depthMeters: 76.0,
          currentAmps: 3.20,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 8,
          tag: 'AN-08',
          depthMeters: 82.0,
          currentAmps: 2.10,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 9,
          tag: 'AN-09',
          depthMeters: 88.0,
          currentAmps: 1.65,
          leadWireCondition: 'Kynar/HMWPE Intact'),
      DwicgAnodeTelemetry(
          anodeIndex: 10,
          tag: 'AN-10',
          depthMeters: 94.0,
          currentAmps: 0.95,
          leadWireCondition: 'Low Current Warning'),
      DwicgAnodeTelemetry(
          anodeIndex: 11,
          tag: 'AN-11',
          depthMeters: 100.0,
          currentAmps: 0.00,
          leadWireCondition: 'OPEN CIRCUIT / SEVERED'),
      DwicgAnodeTelemetry(
          anodeIndex: 12,
          tag: 'AN-12',
          depthMeters: 106.0,
          currentAmps: 0.85,
          leadWireCondition: 'Kynar/HMWPE Intact'),
    ];

    _groundbeds = [
      DwicgGroundbedRecord(
        id: 'DWICG-01',
        name: 'Duliajan CPF Main Anode Bed',
        chainage: 'KP 04+200',
        chainageKm: 4.200,
        totalBoreholeDepthM: 105.0,
        activeColumnM: 65.0,
        boreholeDiameterMm: 200.0,
        casingDepthM: 35.0,
        anodes: dwicgAnodes1,
        trVoltageVolts: 18.5,
        cokeBreezeResistanceOhms: 0.18,
        cokeSettlingDeltaHM: 2.4,
        gasVentPressurePsi: 4.8,
        waterTableDepthM: 14.2,
        anodeType: AnodeMaterialType.mmoTitanium,
        installationDate: DateTime(2022, 5, 12),
      ),
      DwicgGroundbedRecord(
        id: 'DWICG-02',
        name: 'Burhi Dihing River Crossing Groundbed',
        chainage: 'KP 18+750',
        chainageKm: 18.750,
        totalBoreholeDepthM: 110.0,
        activeColumnM: 70.0,
        boreholeDiameterMm: 200.0,
        casingDepthM: 38.0,
        anodes: dwicgAnodes2,
        trVoltageVolts: 29.8,
        cokeBreezeResistanceOhms: 0.42,
        cokeSettlingDeltaHM: 4.6, // Requires top-up
        gasVentPressurePsi: 7.2,
        waterTableDepthM: 6.8,
        anodeType: AnodeMaterialType.hsciAlloy,
        installationDate: DateTime(2020, 11, 24),
      ),
    ];
    _selectedGroundbedIndex = 0;

    // Default Calculator setup for MMO
    _applyCalculatorPreset(AnodeMaterialType.mmoTitanium);

    // Initial Audit Log Entry
    _addAuditRecord(
      action: 'SYSTEM_INITIALIZATION',
      description:
          'ASTM G57 Wenner Survey database and DWICG telemetry telemetry live stream initialized.',
      user: 'Nirmaan Integrity Engine',
    );
  }

  void _applyCalculatorPreset(AnodeMaterialType type) {
    setState(() {
      _calcMaterial = type;
      _calcConsumptionRate = type.defaultConsumptionRateKgPerAmpYear;
      _calcInitialMassKg = type.defaultNominalMassKg;
      _calcOperatingCurrentAmps =
          type == AnodeMaterialType.mmoTitanium ? 2.25 : 3.50;
      _calcUtilizationLimit = 0.80;
    });
  }

  void _addAuditRecord({
    required String action,
    required String description,
    required String user,
  }) {
    final timestamp = DateTime.now();
    final rawHash =
        '$action|$description|$user|${timestamp.toIso8601String()}|NIRMAAN_SECRET_SALT';
    final sha256Digest =
        sha256.convert(utf8.encode(rawHash)).toString().substring(0, 16);

    setState(() {
      _auditLog.insert(0, {
        'action': action,
        'description': description,
        'user': user,
        'timestamp': timestamp,
        'hash': 'SHA256:$sha256Digest',
      });
    });
  }

  // ============================================================================
  // BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final activeLocation = _surveyLocations[_selectedLocationIndex];
    final activeGroundbed = _groundbeds[_selectedGroundbedIndex];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cathodic Protection & Soil Resistivity',
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
                  'ASTM G57 Wenner 4-Pin | DWICG Anode String Telemetry (12 Anodes)',
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
            tooltip: 'Export ASTM G57 Dossier',
            icon: const Icon(Icons.file_download_outlined,
                color: AppTheme.primaryLight),
            onPressed: () => _showExportDossierDialog(context),
          ),
          IconButton(
            tooltip: 'Log New Field Survey',
            icon: const Icon(Icons.add_location_alt_rounded,
                color: AppTheme.secondary),
            onPressed: () => _showAddSurveyDialog(context),
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
                  icon: Icon(Icons.architecture_rounded, size: 16),
                  text: 'ASTM G57 Wenner Survey',
                ),
                Tab(
                  icon: Icon(Icons.tune_rounded, size: 16),
                  text: 'DWICG Groundbed Telemetry',
                ),
                Tab(
                  icon: Icon(Icons.calculate_rounded, size: 16),
                  text: 'MMO / HSCI Consumption',
                ),
                Tab(
                  icon: Icon(Icons.inventory_2_rounded, size: 16),
                  text: 'Coke Bed Replenishment',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWennerSurveyTab(activeLocation),
          _buildDwicgTelemetryTab(activeGroundbed),
          _buildAnodeConsumptionTab(),
          _buildReplenishmentTab(activeGroundbed),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: ASTM G57 WENNER 4-PIN SURVEY TAB
  // ============================================================================

  Widget _buildWennerSurveyTab(SurveyLocationDossier dossier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Selector Ribbon
          _buildSurveyStationRibbon(),
          const SizedBox(height: 16),

          // Overview KPI Card Banner
          _buildWennerKpiBanner(dossier),
          const SizedBox(height: 16),

          // ASTM G57 Wenner 4-Pin Electrode Geometry Schematic
          _buildWennerPinSchematicCard(),
          const SizedBox(height: 16),

          // Pin-a Spacing Table with Live Interactive Sliders & Formula
          _buildPinReadingsTable(dossier),
          const SizedBox(height: 16),

          // Depth vs Apparent Resistivity Profile Chart (fl_chart)
          _buildResistivityDepthChart(dossier),
          const SizedBox(height: 16),

          // Barnes Layer Soil Stratification Analysis
          _buildBarnesLayerAnalysisCard(dossier),
          const SizedBox(height: 16),

          // Quick Soil Preset Injector
          _buildQuickSoilPresetsCard(dossier),
        ],
      ),
    );
  }

  Widget _buildSurveyStationRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_rounded, color: AppTheme.primaryLight, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Survey Station:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedLocationIndex,
                isExpanded: true,
                isDense: true,
                dropdownColor: AppTheme.surfaceCard,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                icon: const Icon(Icons.arrow_drop_down,
                    color: AppTheme.primaryLight),
                items: List.generate(_surveyLocations.length, (idx) {
                  final loc = _surveyLocations[idx];
                  return DropdownMenuItem<int>(
                    value: idx,
                    child: Text(
                      '${loc.chainage} • ${loc.locationName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedLocationIndex = val;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWennerKpiBanner(SurveyLocationDossier dossier) {
    final worstClass = dossier.worstCorrosivityClass;
    return Container(
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: worstClass.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(worstClass.icon, color: worstClass.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dossier.locationName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GPS: ${dossier.gpsCoords} | ASTM G57 Compliant',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: worstClass.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: worstClass.color),
                ),
                child: Text(
                  worstClass.shortLabel,
                  style: TextStyle(
                    color: worstClass.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildKpiItem(
                label: 'MIN RESISTIVITY (ρ)',
                value: '${dossier.minResistivityRho.toStringAsFixed(1)} Ω·m',
                subtext:
                    '${(dossier.minResistivityRho * 100).toInt()} Ω·cm',
                color: worstClass.color,
              ),
              _buildKpiItem(
                label: 'AVG RESISTIVITY',
                value: '${dossier.avgResistivityRho.toStringAsFixed(1)} Ω·m',
                subtext: '5 pin depths (1m-10m)',
                color: AppTheme.primaryLight,
              ),
              _buildKpiItem(
                label: 'REC. CP CURRENT',
                value:
                    '${worstClass.recommendedCpCurrentDensityMaPerM2.toStringAsFixed(0)} mA/m²',
                subtext: 'NACE SP0169 standard',
                color: AppTheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem({
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Visual schematic showing the 4 collinear pins in the ground
  Widget _buildWennerPinSchematicCard() {
    return Container(
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
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.hub_rounded, color: AppTheme.secondary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ASTM G57 Wenner 4-Pin Electrode Configuration',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ρ = 2 · π · a · R',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom Schematic Canvas Representation
          Container(
            height: 140,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D172E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: CustomPaint(
              painter: _WennerArrayPainter(),
            ),
          ),

          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildPinInfoTag('C1 (Current In)', const Color(0xFFEF4444)),
              _buildPinInfoTag('P1 (Potential +)', const Color(0xFF38BDF8)),
              _buildPinInfoTag('P2 (Potential -)', const Color(0xFF4EDEA3)),
              _buildPinInfoTag('C2 (Current Out)', const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Equispaced collinear pins spaced distance "a" apart. Current injected between C1 & C2, potential measured between P1 & P2. Exploration depth corresponds to pin-a. Electrode insertion depth d ≤ 0.05a avoids boundary distortion.',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinInfoTag(String text, Color color) {
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
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPinReadingsTable(SurveyLocationDossier dossier) {
    return Container(
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
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.table_chart_rounded,
                        color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pin Spacing (pin-a) & Resistivity Matrix',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${dossier.readings.length} Spacings Logged',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'PIN-A (m)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'RESISTANCE R (Ω)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'RESISTIVITY ρ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'CORROSIVITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                SizedBox(width: 36), // Action button slot
              ],
            ),
          ),
          const SizedBox(height: 6),

          // List of Rows
          ...List.generate(dossier.readings.length, (idx) {
            final reading = dossier.readings[idx];
            final rho = reading.apparentResistivityRho;
            final rhoCm = reading.resistivityOhmCm;
            final corClass = reading.corrosivityClass;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: idx % 2 == 0
                      ? AppTheme.border.withValues(alpha: 0.4)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${reading.pinSpacingA.toStringAsFixed(1)}m',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reading.measuredResistanceOhms.toStringAsFixed(3)} Ω',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Courier',
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'freq: ${reading.testFrequencyHz} Hz',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${rho.toStringAsFixed(2)} Ω·m',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: corClass.color,
                          ),
                        ),
                        Text(
                          '${rhoCm.toInt()} Ω·cm',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: corClass.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: corClass.color.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        corClass.shortLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: corClass.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded,
                        color: AppTheme.textMuted, size: 20),
                    tooltip: 'Adjust Measured Resistance R',
                    onPressed: () => _showEditReadingModal(context, reading, idx),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResistivityDepthChart(SurveyLocationDossier dossier) {
    final spots = <FlSpot>[];
    for (int i = 0; i < dossier.readings.length; i++) {
      final r = dossier.readings[i];
      spots.add(FlSpot(r.pinSpacingA, r.apparentResistivityRho));
    }

    final maxRho = dossier.maxResistivityRho * 1.25;

    return Container(
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
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.show_chart_rounded,
                        color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Apparent Resistivity Profile (ρ vs Pin-a Spacing)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ASTM G57 Depth Curve',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // fl_chart LineChart
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0.5,
                maxX: 10.5,
                minY: 0,
                maxY: math.max(25.0, maxRho),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 5,
                  verticalInterval: 2,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: AppTheme.border.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (val) => FlLine(
                    color: AppTheme.border.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Pin Spacing "a" / Exploration Depth (Meters)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 2,
                      getTitlesWidget: (val, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${val.toInt()}m',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Resistivity ρ (Ω·m)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 10,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toInt()}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
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
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppTheme.primaryLight,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: AppTheme.secondary,
                          strokeWidth: 2,
                          strokeColor: AppTheme.background,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendDot(
                  const Color(0xFFEF4444), '< 10 Ω·m Severe Corrosive Zone'),
              _buildLegendDot(
                  const Color(0xFFFFB95F), '10-20 Ω·m Corrosive Zone'),
              _buildLegendDot(
                  const Color(0xFF4EDEA3), '> 20 Ω·m Mild/Moderate Zone'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildBarnesLayerAnalysisCard(SurveyLocationDossier dossier) {
    // Barnes Layer Method: calculates incremental layer resistivities
    // between pin spacings a1 and a2:
    // 1/R_layer = 1/R2 - 1/R1
    // rho_layer = 2 * pi * (a2 - a1) * R_layer
    final layers = <Map<String, dynamic>>[];
    final readings = dossier.readings;

    for (int i = 0; i < readings.length - 1; i++) {
      final r1 = readings[i];
      final r2 = readings[i + 1];
      final a1 = r1.pinSpacingA;
      final a2 = r2.pinSpacingA;
      final r1Val = r1.measuredResistanceOhms;
      final r2Val = r2.measuredResistanceOhms;

      double layerRho = 0.0;
      final conductanceDiff = (1.0 / r2Val) - (1.0 / r1Val);
      if (conductanceDiff > 0.0001) {
        final rLayer = 1.0 / conductanceDiff;
        layerRho = 2.0 * math.pi * (a2 - a1) * rLayer;
      } else {
        layerRho = r2.apparentResistivityRho; // Fallback
      }

      layers.add({
        'range': '${a1.toStringAsFixed(0)}m - ${a2.toStringAsFixed(0)}m Depth',
        'deltaA': a2 - a1,
        'layerRho': layerRho,
        'class': SoilCorrosivityClassExt.fromRho(layerRho),
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.layers_rounded, color: AppTheme.tertiary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Barnes Equivalent Layer Soil Stratification',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Decomposes multi-pin Wenner surveys into discrete horizontal geotechnical layers using Barnes conductance subtraction method.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          ...layers.map((l) {
            final corClass = l['class'] as SoilCorrosivityClass;
            final rho = l['layerRho'] as double;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: corClass.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l['range'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Layer ρ: ${rho.toStringAsFixed(1)} Ω·m',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: corClass.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '(${corClass.shortLabel})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickSoilPresetsCard(SurveyLocationDossier dossier) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.flash_on_rounded, color: AppTheme.secondary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Geotechnical Soil Type Presets (ASTM G57 Simulation)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Quickly test pipeline corrosion response by applying regional Assam geological strata profiles:',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetButton(
                label: 'Assam Alluvial Clay (Low ρ)',
                color: const Color(0xFFEF4444),
                onTap: () => _applySoilPreset([1.2, 0.7, 0.45, 0.28, 0.14]),
              ),
              _buildPresetButton(
                label: 'Brahmaputra Wet Sand (Moderate)',
                color: const Color(0xFFFFB95F),
                onTap: () => _applySoilPreset([3.5, 2.4, 1.8, 1.2, 0.7]),
              ),
              _buildPresetButton(
                label: 'Upper Assam Laterite Loam',
                color: const Color(0xFF38BDF8),
                onTap: () => _applySoilPreset([6.8, 4.5, 3.2, 2.1, 1.1]),
              ),
              _buildPresetButton(
                label: 'Shillong Plateau Dry Gravel',
                color: const Color(0xFF4EDEA3),
                onTap: () => _applySoilPreset([22.0, 16.5, 11.8, 7.5, 4.2]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  void _applySoilPreset(List<double> resistances) {
    setState(() {
      final readings = _surveyLocations[_selectedLocationIndex].readings;
      for (int i = 0; i < math.min(readings.length, resistances.length); i++) {
        readings[i].measuredResistanceOhms = resistances[i];
      }
    });
    _addAuditRecord(
      action: 'SOIL_PRESET_APPLIED',
      description:
          'Applied simulation preset to station ${_surveyLocations[_selectedLocationIndex].chainage}.',
      user: 'Field Engineer',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ASTM G57 Soil Resistivity profile updated.'),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================================
  // TAB 2: DWICG DEEP WELL GROUNDBED TELEMETRY TAB
  // ============================================================================

  Widget _buildDwicgTelemetryTab(DwicgGroundbedRecord groundbed) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Groundbed Selector Ribbon
          _buildGroundbedSelectorRibbon(),
          const SizedBox(height: 16),

          // Groundbed Executive Telemetry Cards (Rg < 1.0 Ohm compliance check)
          _buildDwicgExecutiveCards(groundbed),
          const SizedBox(height: 16),

          // Borehole Vertical Cross-Section Visualizer (100m Deep Well with 12 Anodes)
          _buildBoreholeVerticalVisualizer(groundbed),
          const SizedBox(height: 16),

          // 12-Anode String Current Telemetry Bar Chart
          _buildAnodeCurrentBarChart(groundbed),
          const SizedBox(height: 16),

          // Anode String 1-12 Detailed Tuning Matrix
          _buildAnodeTuningMatrix(groundbed),
          const SizedBox(height: 16),

          // Coke Breeze Column Resistance & Gas Venting Telemetry
          _buildCokeColumnTelemetryCard(groundbed),
        ],
      ),
    );
  }

  Widget _buildGroundbedSelectorRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.electrical_services_rounded,
              color: AppTheme.secondary, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Groundbed:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedGroundbedIndex,
                isExpanded: true,
                isDense: true,
                dropdownColor: AppTheme.surfaceCard,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                icon: const Icon(Icons.arrow_drop_down,
                    color: AppTheme.secondary),
                items: List.generate(_groundbeds.length, (idx) {
                  final gb = _groundbeds[idx];
                  return DropdownMenuItem<int>(
                    value: idx,
                    child: Text(
                      '${gb.id} • ${gb.name} (${gb.chainage})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedGroundbedIndex = val;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDwicgExecutiveCards(DwicgGroundbedRecord groundbed) {
    final status = groundbed.complianceStatus;
    final rg = groundbed.groundbedResistanceEarthOhms;

    return Container(
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(status.icon, color: status.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Groundbed Resistance-to-Earth (Rg)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Design Standard: Rg < 1.0 Ω (OISD-141 / NACE SP0169)',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: status.color),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    color: status.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildKpiItem(
                label: 'MEASURED Rg',
                value: '${rg.toStringAsFixed(3)} Ω',
                subtext: rg < 1.0 ? 'Within Specification' : 'Requires Backfill',
                color: status.color,
              ),
              _buildKpiItem(
                label: 'TOTAL CURRENT',
                value: '${groundbed.totalCurrentAmps.toStringAsFixed(2)} A',
                subtext: 'across 12 anodes',
                color: AppTheme.primaryLight,
              ),
              _buildKpiItem(
                label: 'TR VOLTAGE',
                value: '${groundbed.trVoltageVolts.toStringAsFixed(1)} V',
                subtext: 'Power: ${(groundbed.trVoltageVolts * groundbed.totalCurrentAmps).toStringAsFixed(0)} W',
                color: AppTheme.secondary,
              ),
              _buildKpiItem(
                label: 'COKE COLUMN R',
                value: '${groundbed.cokeBreezeResistanceOhms.toStringAsFixed(3)} Ω',
                subtext: 'Calcined petroleum',
                color: AppTheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoreholeVerticalVisualizer(DwicgGroundbedRecord groundbed) {
    return Container(
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
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.view_column_rounded,
                        color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deep Well Impressed Current Groundbed Elevation',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Well Depth: ${groundbed.totalBoreholeDepthM.toInt()}m',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Visual Custom Paint Borehole Diagram
          Container(
            height: 180,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF091024),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: CustomPaint(
              painter: _DwicgBoreholePainter(groundbed: groundbed),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildStratumTag('Surface Casing (0-35m)', const Color(0xFF64748B)),
              _buildStratumTag('Active Coke Zone (35-105m)', const Color(0xFF334155)),
              _buildStratumTag('Vent Pipe (0.28 bar)', const Color(0xFF38BDF8)),
              _buildStratumTag('Water Table (14m)', const Color(0xFF0284C7)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStratumTag(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAnodeCurrentBarChart(DwicgGroundbedRecord groundbed) {
    final avg = groundbed.averageCurrentPerAnode;

    return Container(
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
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Anode String Current Distribution (Anode 1 to 12)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Mean: ${avg.toStringAsFixed(2)} A',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bar Chart with 12 rods
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: 5.0,
                minY: 0.0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceContainerHigh,
                    tooltipRoundedRadius: 6,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final anode = groundbed.anodes[group.x.toInt()];
                      return BarTooltipItem(
                        '${anode.tag} (Depth: ${anode.depthMeters.toInt()}m)\n',
                        const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toStringAsFixed(2)} Amps\n',
                            style: TextStyle(
                              color: rod.toY > 4.0
                                  ? Colors.redAccent
                                  : rod.toY < 0.5
                                      ? Colors.amberAccent
                                      : AppTheme.primaryLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(
                            text: 'Shunt Drop: ${anode.shuntVoltageDropMv.toStringAsFixed(1)} mV',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Anode Position (Top AN-01 to Deep AN-12)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= groundbed.anodes.length) {
                          return const SizedBox();
                        }
                        return Text(
                          'A${idx + 1}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Current (Amperes)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1.0,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toInt()}A',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
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
                barGroups: List.generate(groundbed.anodes.length, (idx) {
                  final anode = groundbed.anodes[idx];
                  Color barColor = AppTheme.primaryLight;
                  if (anode.isSevered) {
                    barColor = const Color(0xFFEF4444);
                  } else if (anode.isOvercurrent) {
                    barColor = const Color(0xFFF97316);
                  } else if (!anode.isNominal) {
                    barColor = const Color(0xFFFFB95F);
                  }

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: anode.currentAmps,
                        color: barColor,
                        width: 14,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnodeTuningMatrix(DwicgGroundbedRecord groundbed) {
    return Container(
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
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppTheme.secondary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Individual Anode Shunt Tuning & Telemetry',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Max Imbalance: ${groundbed.maxCurrentDifferencePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: groundbed.maxCurrentDifferencePercent > 35
                      ? const Color(0xFFFFB95F)
                      : AppTheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2x6 or 3x4 Grid of 12 Anodes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: groundbed.anodes.length,
            itemBuilder: (context, idx) {
              final anode = groundbed.anodes[idx];
              Color statusColor = AppTheme.tertiary;
              if (anode.isSevered) {
                statusColor = const Color(0xFFEF4444);
              } else if (anode.isOvercurrent) {
                statusColor = const Color(0xFFF97316);
              } else if (!anode.isNominal) {
                statusColor = const Color(0xFFFFB95F);
              }

              return InkWell(
                onTap: () => _showAnodeDetailDialog(context, groundbed, anode, idx),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.6),
                      width: 1,
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
                            anode.tag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${anode.currentAmps.toStringAsFixed(2)} A',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Courier',
                          color: statusColor,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${anode.depthMeters.toInt()}m depth',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          Text(
                            '${anode.shuntVoltageDropMv.toStringAsFixed(0)}mV',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.textSecondary,
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
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Tap any anode card to adjust variable shunt resistance or inspect cable continuity.',
              style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCokeColumnTelemetryCard(DwicgGroundbedRecord groundbed) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.compress_rounded, color: AppTheme.tertiary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Coke Breeze Backfill Column & Gas Vent Telemetry',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildTelemetryTile(
                title: 'COKE COLUMN R',
                value: '${groundbed.cokeBreezeResistanceOhms.toStringAsFixed(3)} Ω',
                subtitle: 'Inter-anode conductivity',
                status: 'HEALTHY (< 0.5 Ω)',
                color: AppTheme.tertiary,
              ),
              const SizedBox(width: 10),
              _buildTelemetryTile(
                title: 'COKE SETTLING (Δh)',
                value: '${groundbed.cokeSettlingDeltaHM.toStringAsFixed(1)} m',
                subtitle: 'From casing top',
                status: groundbed.cokeSettlingDeltaHM > 3.0
                    ? 'REPLENISHMENT DUE'
                    : 'NORMAL',
                color: groundbed.cokeSettlingDeltaHM > 3.0
                    ? const Color(0xFFFFB95F)
                    : AppTheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTelemetryTile(
                title: 'VENT PRESSURE',
                value: '${groundbed.gasVentPressurePsi.toStringAsFixed(1)} psi',
                subtitle: 'O2 & Cl2 venting free',
                status: 'UNBLOCKED',
                color: AppTheme.primaryLight,
              ),
              const SizedBox(width: 10),
              _buildTelemetryTile(
                title: 'WATER TABLE DEPTH',
                value: '${groundbed.waterTableDepthM.toStringAsFixed(1)} m',
                subtitle: 'Hydrostatic head',
                status: 'SATURATED',
                color: AppTheme.primaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryTile({
    required String title,
    required String value,
    required String subtitle,
    required String status,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 3: MMO / HSCI ANODE CONSUMPTION CALCULATOR (FARADAY'S LAW)
  // ============================================================================

  Widget _buildAnodeConsumptionTab() {
    // Faraday's Law Computational Engine:
    // Annual Mass Consumption = OperatingCurrent * ConsumptionRate * ActiveAnodes
    // Remnant Usable Mass = (InitialMass * UtilizationLimit) - (AnnualConsumption * YearsInService)
    // Remnant Life (Years) = RemnantUsableMass / AnnualConsumption
    final totalAnnualConsumptionKg = _calcOperatingCurrentAmps *
        _calcConsumptionRate *
        _calcActiveAnodeCount;
    final totalInitialUsableMassKg =
        (_calcInitialMassKg * _calcActiveAnodeCount) * _calcUtilizationLimit;
    final cumulativeConsumedMassKg =
        totalAnnualConsumptionKg * _calcYearsInService;
    final remnantMassKg =
        math.max(0.0, totalInitialUsableMassKg - cumulativeConsumedMassKg);

    final remnantLifeYears = totalAnnualConsumptionKg > 0
        ? (remnantMassKg / totalAnnualConsumptionKg)
        : 99.9;
    final remainingPercent = totalInitialUsableMassKg > 0
        ? ((remnantMassKg / totalInitialUsableMassKg) * 100.0)
        : 0.0;

    final projectedExhaustionYear =
        DateTime.now().year + remnantLifeYears.toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Anode Material Toggle (MMO vs HSCI)
          _buildMaterialSelectorCard(),
          const SizedBox(height: 16),

          // Faraday's Law Key Output Dashboard
          _buildFaradayKpiDashboard(
            remnantLifeYears: remnantLifeYears,
            remainingPercent: remainingPercent,
            cumulativeConsumedKg: cumulativeConsumedMassKg,
            projectedYear: projectedExhaustionYear,
          ),
          const SizedBox(height: 16),

          // Interactive Calculation Parameters (Sliders & Inputs)
          _buildConsumptionParametersCard(),
          const SizedBox(height: 16),

          // 30-Year Remnant Life Degradation Curve (fl_chart)
          _buildLifeDegradationChart(
            remnantLifeYears: remnantLifeYears,
            yearsInService: _calcYearsInService,
          ),
          const SizedBox(height: 16),

          // Faraday's Law Physics Breakdown Card
          _buildFaradayPhysicsCard(),
        ],
      ),
    );
  }

  Widget _buildMaterialSelectorCard() {
    return Container(
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
            'Select Anode Metallurgy Chemistry',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMaterialRadioOption(
                  title: 'MMO / Titanium Tubular',
                  subtitle:
                      'IrO2/Ta2O5 Coating\nk = 1.5 mg/A·yr (Near-Zero Loss)',
                  type: AnodeMaterialType.mmoTitanium,
                  color: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMaterialRadioOption(
                  title: 'High-Silicon Cr Iron (HSCI)',
                  subtitle:
                      'ASTM A518 Gr 3 (14.5% Si)\nk = 0.25 kg/A·yr in Coke',
                  type: AnodeMaterialType.hsciAlloy,
                  color: const Color(0xFFFFB95F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialRadioOption({
    required String title,
    required String subtitle,
    required AnodeMaterialType type,
    required Color color,
  }) {
    final isSelected = _calcMaterial == type;
    return InkWell(
      onTap: () => _applyCalculatorPreset(type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : AppTheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? color : AppTheme.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? color : AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaradayKpiDashboard({
    required double remnantLifeYears,
    required double remainingPercent,
    required double cumulativeConsumedKg,
    required int projectedYear,
  }) {
    Color lifeColor = AppTheme.tertiary;
    String urgency = 'HEALTHY';
    if (remnantLifeYears < 5.0) {
      lifeColor = const Color(0xFFEF4444);
      urgency = 'REPLENISHMENT URGENT';
    } else if (remnantLifeYears < 12.0) {
      lifeColor = const Color(0xFFFFB95F);
      urgency = 'SCHEDULE REPLENISHMENT';
    }

    return Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: lifeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.timelapse_rounded,
                        color: lifeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Remnant Operational Life',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Faraday Mass Consumption @ ${_calcOperatingCurrentAmps.toStringAsFixed(2)}A/anode',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: lifeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: lifeColor),
                ),
                child: Text(
                  urgency,
                  style: TextStyle(
                    color: lifeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildKpiItem(
                label: 'REMNANT LIFE',
                value: '${remnantLifeYears.toStringAsFixed(1)} YRS',
                subtext: 'Projected EOL: Year $projectedYear',
                color: lifeColor,
              ),
              _buildKpiItem(
                label: 'MASS REMAINING',
                value: '${remainingPercent.toStringAsFixed(1)}%',
                subtext: '80% utilization limit',
                color: AppTheme.primaryLight,
              ),
              _buildKpiItem(
                label: 'CONSUMED TO DATE',
                value: _calcMaterial == AnodeMaterialType.mmoTitanium
                    ? '${(cumulativeConsumedKg * 1000).toStringAsFixed(2)} g'
                    : '${cumulativeConsumedKg.toStringAsFixed(1)} kg',
                subtext: 'Over ${_calcYearsInService.toStringAsFixed(1)} yrs',
                color: AppTheme.secondary,
              ),
              _buildKpiItem(
                label: 'ANNUAL LOSS',
                value: _calcMaterial == AnodeMaterialType.mmoTitanium
                    ? '${(_calcOperatingCurrentAmps * _calcConsumptionRate * _calcActiveAnodeCount * 1000).toStringAsFixed(2)} g/yr'
                    : '${(_calcOperatingCurrentAmps * _calcConsumptionRate * _calcActiveAnodeCount).toStringAsFixed(2)} kg/yr',
                subtext: 'Total string depletion',
                color: AppTheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionParametersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.tune_rounded, color: AppTheme.primaryLight, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Faraday Electrolysis Parameters (Live Tuning)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Operating Current Slider
          _buildSliderParam(
            label: 'Operating Current per Anode (Amps)',
            value: _calcOperatingCurrentAmps,
            min: 0.5,
            max: 6.0,
            unit: ' A',
            onChanged: (val) {
              setState(() {
                _calcOperatingCurrentAmps = val;
              });
            },
          ),
          const SizedBox(height: 12),

          // Years in Service Slider
          _buildSliderParam(
            label: 'Operating Service Duration (Years)',
            value: _calcYearsInService,
            min: 0.5,
            max: 25.0,
            unit: ' yrs',
            onChanged: (val) {
              setState(() {
                _calcYearsInService = val;
              });
            },
          ),
          const SizedBox(height: 12),

          // Initial Mass per Anode Slider
          _buildSliderParam(
            label: _calcMaterial == AnodeMaterialType.mmoTitanium
                ? 'MMO Coated Tube Mass (kg)'
                : 'Initial HSCI Solid Anode Mass (kg)',
            value: _calcInitialMassKg,
            min: _calcMaterial == AnodeMaterialType.mmoTitanium ? 0.5 : 15.0,
            max: _calcMaterial == AnodeMaterialType.mmoTitanium ? 5.0 : 70.0,
            unit: ' kg',
            onChanged: (val) {
              setState(() {
                _calcInitialMassKg = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderParam({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${value.toStringAsFixed(2)}$unit',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryLight,
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryLight,
            inactiveTrackColor: AppTheme.surfaceContainerHigh,
            thumbColor: AppTheme.secondary,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildLifeDegradationChart({
    required double remnantLifeYears,
    required double yearsInService,
  }) {
    final spots = <FlSpot>[];
    const totalHorizonYears = 30.0;
    final totalLife = yearsInService + remnantLifeYears;

    for (double t = 0; t <= totalHorizonYears; t += 2.0) {
      double percent = 100.0 - (t / totalLife) * 100.0;
      if (percent < 0) percent = 0;
      spots.add(FlSpot(t, percent));
    }

    return Container(
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
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.trending_down_rounded,
                        color: AppTheme.secondary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '30-Year Anode Mass Depletion Trajectory',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Faraday Depletion Curve',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 30,
                minY: 0,
                maxY: 105,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 20,
                  verticalInterval: 5,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: AppTheme.border.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (val) => FlLine(
                    color: AppTheme.border.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Operational Time (Years in Service)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 5,
                      getTitlesWidget: (val, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Yr ${val.toInt()}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Remaining Mass (%)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toInt()}%',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
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
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: AppTheme.secondary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.secondary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Threshold line indicates 20% residual mass cut-off. At < 20% mass, central copper lead core fractures due to thermal/mechanical hoop stress.',
            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFaradayPhysicsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_rounded, color: AppTheme.tertiary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Faraday\'s Law of Electrolysis & Electrochemical Reactions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '1. Mass Loss Formula: m = (I · t · M) / (z · F)\n'
            '   Where I is current (Amps), t is time (seconds), M is molar mass, z is valence charge, and F is Faraday constant (96,485 C/mol).\n\n'
            '2. High-Silicon Chromium Iron (HSCI):\n'
            '   Iron oxidation Fe → Fe²⁺ + 2e⁻ is retarded by silicon dioxide (SiO2) protective barrier film formed in acidic anode groundbed environment. Consumption rate in calcined coke: 0.25 kg/A·year.\n\n'
            '3. Mixed Metal Oxide (MMO):\n'
            '   Substrate titanium is inert. Anodic oxidation reaction occurs at electrocatalytic IrO2/Ta2O5 coating via oxygen evolution: 2H2O → O2 + 4H⁺ + 4e⁻. Consumption rate: ~1.5 mg/A·year (virtually dimensionally stable).',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: COKE BREEZE REPLENISHMENT & FIELD WORK ORDERS
  // ============================================================================

  Widget _buildReplenishmentTab(DwicgGroundbedRecord groundbed) {
    // Borehole Volume Calculation:
    // Radius r = (boreholeDiameterMm / 2) / 1000 (m)
    // Delta Height = settlingDeltaHM (m)
    // Volume V = pi * r^2 * Delta H (m3)
    // Total Mass = V * CokeBulkDensity (kg)
    // Required Bags = ceil(TotalMass / BagWeight)
    final radiusM = (_replenishWellDiameterMm / 2.0) / 1000.0;
    final volumeM3 =
        math.pi * math.pow(radiusM, 2) * _replenishSettlingDeltaHM;
    final totalCokeMassKg = volumeM3 * _replenishCokeBulkDensityKgM3;
    final requiredBags =
        (totalCokeMassKg / _replenishBagWeightKg).ceil();
    final waterMixLiters = totalCokeMassKg * 0.45; // 0.45 L/kg slurry ratio

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Replenishment Assessment Card
          _buildReplenishmentAssessmentCard(groundbed),
          const SizedBox(height: 16),

          // Fluid Coke Slurry Volume Calculator
          _buildCokeBreezeCalculatorCard(
            volumeM3: volumeM3,
            totalCokeMassKg: totalCokeMassKg,
            requiredBags: requiredBags,
            waterMixLiters: waterMixLiters,
          ),
          const SizedBox(height: 16),

          // OISD-141 / NACE SP0572 Step-by-Step Procedure Checklist
          _buildReplenishmentProcedureCard(),
          const SizedBox(height: 16),

          // Action Buttons: Generate Work Order & Simulate Top-Up
          _buildReplenishmentActionRow(groundbed, requiredBags),
          const SizedBox(height: 16),

          // Cryptographic Audit Trail
          _buildAuditTrailCard(),
        ],
      ),
    );
  }

  Widget _buildReplenishmentAssessmentCard(DwicgGroundbedRecord groundbed) {
    final needsTopUp = groundbed.cokeSettlingDeltaHM >= 3.0 ||
        groundbed.groundbedResistanceEarthOhms >= 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: needsTopUp ? const Color(0xFFFFB95F) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: needsTopUp
                      ? const Color(0xFFFFB95F).withValues(alpha: 0.15)
                      : AppTheme.tertiary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  needsTopUp ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                  color: needsTopUp ? const Color(0xFFFFB95F) : AppTheme.tertiary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Groundbed Coke Breeze Assessment: ${groundbed.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Settling Detected: ${groundbed.cokeSettlingDeltaHM.toStringAsFixed(1)}m from top casing datum',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: needsTopUp
                      ? const Color(0xFFFFB95F).withValues(alpha: 0.2)
                      : AppTheme.tertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  needsTopUp ? 'TOP-UP DUE' : 'OPTIMAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: needsTopUp
                        ? const Color(0xFFFFB95F)
                        : AppTheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Over years of high-current cathodic discharge, calcined petroleum coke breeze undergoes electrochemical gasification (C + 2H2O → CO2 + 4H⁺ + 4e⁻) and settling, elevating groundbed resistance-to-earth above the 1.0 Ω limit. Fluidized slurry replenishment restores conductive contact.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCokeBreezeCalculatorCard({
    required double volumeM3,
    required double totalCokeMassKg,
    required int requiredBags,
    required double waterMixLiters,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.calculate_rounded, color: AppTheme.primaryLight, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fluid Coke Slurry Replenishment Calculator',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sliders for Settling Delta-H and Well Diameter
          _buildSliderParam(
            label: 'Measured Settling Height (Δh meters)',
            value: _replenishSettlingDeltaHM,
            min: 0.5,
            max: 10.0,
            unit: ' m',
            onChanged: (val) {
              setState(() {
                _replenishSettlingDeltaHM = val;
              });
            },
          ),
          const SizedBox(height: 12),

          _buildSliderParam(
            label: 'Borehole Diameter (mm)',
            value: _replenishWellDiameterMm,
            min: 150.0,
            max: 300.0,
            unit: ' mm',
            onChanged: (val) {
              setState(() {
                _replenishWellDiameterMm = val;
              });
            },
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 16),

          // Calculation Results Output Matrix
          Row(
            children: [
              _buildKpiItem(
                label: 'REPLENISH VOL.',
                value: '${volumeM3.toStringAsFixed(3)} m³',
                subtext: 'Borehole void',
                color: AppTheme.primaryLight,
              ),
              _buildKpiItem(
                label: 'DRY COKE MASS',
                value: '${totalCokeMassKg.toInt()} kg',
                subtext: 'Bulk: 1,120 kg/m³',
                color: AppTheme.secondary,
              ),
              _buildKpiItem(
                label: 'BAGS REQUIRED',
                value: '$requiredBags Bags',
                subtext: '25 kg bags',
                color: const Color(0xFF4EDEA3),
              ),
              _buildKpiItem(
                label: 'WATER SLURRY',
                value: '${waterMixLiters.toInt()} L',
                subtext: 'Tremie pumping mix',
                color: AppTheme.primaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplenishmentProcedureCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.checklist_rounded, color: AppTheme.secondary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OISD-141 & NACE SP0572 Standard Field Protocol',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildChecklistStep(
            stepNumber: '1',
            title: 'Isolate & Lock-Out Tag-Out (LOTO) TR Unit',
            desc: 'Disconnect DC positive & negative output to groundbed and verify 0.0V residual.',
          ),
          _buildChecklistStep(
            stepNumber: '2',
            title: 'Nitrogen Purge Gas Vent Pipe',
            desc: 'Clear trapped chlorine and oxygen gas head to prevent gas blocking in the active zone.',
          ),
          _buildChecklistStep(
            stepNumber: '3',
            title: 'Insert Flexible Tremie Slurry Pipe',
            desc: 'Lower tremie pipe to bottom of void (0.5m above settled coke column) to prevent air entrapment.',
          ),
          _buildChecklistStep(
            stepNumber: '4',
            title: 'Inject Fluidized Calcined Coke Slurry',
            desc: 'Pump coke breeze slurry under 1.5 - 2.5 bar pressure with fluidizing surfactant wetting agent.',
          ),
          _buildChecklistStep(
            stepNumber: '5',
            title: '48-Hour Settlement & Earth Resistance Verification',
            desc: 'Allow natural water displacement, sound column depth, and confirm Rg drops below 1.0 Ω before re-energizing.',
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistStep({
    required String stepNumber,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryLight),
            ),
            child: Text(
              stepNumber,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryLight,
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplenishmentActionRow(
      DwicgGroundbedRecord groundbed, int requiredBags) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.assignment_add, size: 18),
            label: const Text('GENERATE WORK ORDER'),
            onPressed: () =>
                _showCreateWorkOrderDialog(context, groundbed, requiredBags),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.tertiary),
              foregroundColor: AppTheme.tertiary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: const Text('SIMULATE TOP-UP'),
            onPressed: () => _simulateCokeTopUp(groundbed),
          ),
        ),
      ],
    );
  }

  void _simulateCokeTopUp(DwicgGroundbedRecord groundbed) {
    setState(() {
      groundbed.cokeSettlingDeltaHM = 0.2; // Replenished!
      groundbed.cokeBreezeResistanceOhms = 0.12;
      // Lower groundbed resistance
      groundbed.trVoltageVolts = 15.2;
      _replenishSettlingDeltaHM = 0.2;
    });

    _addAuditRecord(
      action: 'COKE_TOPUP_COMPLETED',
      description:
          'Simulated fluidized calcined coke breeze replenishment for ${groundbed.id}. Rg reduced to ${groundbed.groundbedResistanceEarthOhms.toStringAsFixed(3)} Ω (Compliant < 1.0 Ω).',
      user: 'Integrity Field Supervisor',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Top-Up Simulated: Groundbed ${groundbed.id} Rg is now ${groundbed.groundbedResistanceEarthOhms.toStringAsFixed(3)} Ω (COMPLIANT < 1.0 Ω).',
        ),
        backgroundColor: AppTheme.tertiary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildAuditTrailCard() {
    return Container(
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
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.security_rounded, color: AppTheme.tertiary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cryptographic Audit Trail (SHA-256 Verified)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TAMPER-EVIDENT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._auditLog.take(5).map((log) {
            final dt = log['timestamp'] as DateTime;
            final timeStr = DateFormat('dd MMM HH:mm:ss').format(dt);
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log['action'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log['description'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Actor: ${log['user']}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        log['hash'] as String,
                        style: const TextStyle(
                          fontSize: 8,
                          fontFamily: 'Courier',
                          color: AppTheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================================
  // DIALOGS & MODALS
  // ============================================================================

  void _showEditReadingModal(
      BuildContext context, WennerPinReading reading, int index) {
    final controller = TextEditingController(
        text: reading.measuredResistanceOhms.toStringAsFixed(3));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Edit Resistance R at pin-a = ${reading.pinSpacingA.toStringAsFixed(1)}m',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter measured 4-terminal resistance from Megger/AEMC tester:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Resistance R (Ohms)',
                  suffixText: 'Ω',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Calculated ρ = 2 · π · ${reading.pinSpacingA.toStringAsFixed(1)} · R',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Courier',
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final newR = double.tryParse(controller.text);
                if (newR != null && newR > 0) {
                  setState(() {
                    reading.measuredResistanceOhms = newR;
                  });
                  _addAuditRecord(
                    action: 'WENNER_READING_UPDATED',
                    description:
                        'Updated pin-a ${reading.pinSpacingA}m resistance to $newR Ω at station ${_surveyLocations[_selectedLocationIndex].chainage}.',
                    user: 'Field Engineer',
                  );
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showAnodeDetailDialog(BuildContext context,
      DwicgGroundbedRecord groundbed, DwicgAnodeTelemetry anode, int index) {
    double shuntR = anode.shuntResistanceOhms;
    double current = anode.currentAmps;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final mv = current * shuntR * 1000.0;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${anode.tag} • Depth: ${anode.depthMeters.toInt()}m',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          anode.leadWireCondition,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: anode.isSevered
                                ? const Color(0xFFEF4444)
                                : AppTheme.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildKpiItem(
                        label: 'CURRENT',
                        value: '${current.toStringAsFixed(2)} A',
                        subtext: 'Target: 2.2A',
                        color: AppTheme.primaryLight,
                      ),
                      _buildKpiItem(
                        label: 'SHUNT mV',
                        value: '${mv.toStringAsFixed(1)} mV',
                        subtext: 'Drop across shunt',
                        color: AppTheme.secondary,
                      ),
                      _buildKpiItem(
                        label: 'RESISTOR',
                        value: '${shuntR.toStringAsFixed(3)} Ω',
                        subtext: 'Variable shunt',
                        color: AppTheme.tertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Balance Shunt Resistance (Fine Trimming):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.secondary,
                      thumbColor: AppTheme.secondary,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: shuntR,
                      min: 0.005,
                      max: 0.050,
                      divisions: 45,
                      onChanged: (val) {
                        setSheetState(() {
                          shuntR = val;
                          // Inversely adjust current based on shunt trim
                          current = math.max(0.2, 2.2 * (0.010 / shuntR));
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              current = 0.0; // Simulate severed cable
                            });
                          },
                          child: const Text('Simulate Severed'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              anode.shuntResistanceOhms = shuntR;
                              anode.currentAmps = current;
                            });
                            _addAuditRecord(
                              action: 'ANODE_SHUNT_TUNED',
                              description:
                                  'Tuned ${anode.tag} shunt to ${shuntR.toStringAsFixed(3)}Ω (${current.toStringAsFixed(2)}A) at ${groundbed.id}.',
                              user: 'Integrity Field Crew',
                            );
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Apply Calibration'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSurveyDialog(BuildContext context) {
    final chainageController = TextEditingController(text: 'KP 45+600');
    final nameController = TextEditingController(text: 'Moran Junction Bypass');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Log New ASTM G57 Wenner Survey',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: chainageController,
                decoration: const InputDecoration(labelText: 'Chainage (KP)'),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Location Name'),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              const Text(
                'Will generate default ASTM G57 5-pin spacing array (1m, 2m, 3m, 5m, 10m).',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final newDossier = SurveyLocationDossier(
                  id: 'SURV-ASTM-0${_surveyLocations.length + 1}',
                  locationName: nameController.text,
                  chainage: chainageController.text,
                  chainageKm: 45.6,
                  gpsCoords: "27°10'15.2\"N, 95°02'44.1\"E",
                  soilStrataDescription:
                      'Alluvial sandy clay with river gravel',
                  surveyDate: DateTime.now(),
                  surveyorName: 'Er. R. Borah (NACE CP-3)',
                  testerInstrument: 'AEMC 6471 Ground & Soil Tester (128 Hz)',
                  readings: [
                    WennerPinReading(
                        pinSpacingA: 1.0, measuredResistanceOhms: 2.10),
                    WennerPinReading(
                        pinSpacingA: 2.0, measuredResistanceOhms: 1.40),
                    WennerPinReading(
                        pinSpacingA: 3.0, measuredResistanceOhms: 0.95),
                    WennerPinReading(
                        pinSpacingA: 5.0, measuredResistanceOhms: 0.55),
                    WennerPinReading(
                        pinSpacingA: 10.0, measuredResistanceOhms: 0.28),
                  ],
                  notes: 'Initial geotechnical baseline for anode bed planning.',
                );
                setState(() {
                  _surveyLocations.add(newDossier);
                  _selectedLocationIndex = _surveyLocations.length - 1;
                });
                _addAuditRecord(
                  action: 'NEW_SURVEY_CREATED',
                  description:
                      'Registered new ASTM G57 survey at ${newDossier.chainage} (${newDossier.locationName}).',
                  user: 'NACE Field Inspector',
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('Save Survey'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateWorkOrderDialog(
      BuildContext context, DwicgGroundbedRecord groundbed, int requiredBags) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Work Order: Coke Replenishment ${groundbed.id}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location: ${groundbed.chainage} • ${groundbed.name}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '• Dry Coke Breeze Requirement: $requiredBags Bags (25 kg each)\n'
                '• Pumping Method: Positive displacement tremie slurry injection\n'
                '• Target Resistance: Rg < 0.60 Ω post-settlement\n'
                '• Safety Standard: OISD-141 / NACE SP0572 compliant LOTO',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                _addAuditRecord(
                  action: 'WORK_ORDER_DISPATCHED',
                  description:
                      'Dispatched Work Order WO-COKE-${groundbed.id} for $requiredBags bags calcined petroleum coke.',
                  user: 'Operations Superintendent',
                );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Work Order WO-COKE dispatched to Field Crew.'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              child: const Text('Dispatch Order'),
            ),
          ],
        );
      },
    );
  }

  void _showExportDossierDialog(BuildContext context) {
    final loc = _surveyLocations[_selectedLocationIndex];
    final gb = _groundbeds[_selectedGroundbedIndex];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Export ASTM G57 & Groundbed Dossier',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate signed engineering PDF dossier containing:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                '1. ASTM G57 4-Pin Soil Resistivity Table & Depth Curve\n'
                '2. DWICG 12-Anode Current Telemetry & Shunt Matrix\n'
                '3. Faraday Remnant Life Calculation & Metallurgy Spec\n'
                '4. Coke Breeze Settling & Replenishment Slurry Log\n'
                '5. Cryptographic SHA-256 Seal (${_auditLog.first['hash']})',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                  height: 1.45,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
              label: const Text('Export PDF'),
              onPressed: () {
                _addAuditRecord(
                  action: 'DOSSIER_EXPORTED',
                  description:
                      'Exported ASTM G57 / DWICG Dossier for ${loc.chainage} and ${gb.id}.',
                  user: 'Integrity Lead',
                );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Engineering Dossier PDF Exported successfully.'),
                    backgroundColor: AppTheme.tertiary,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS
// ============================================================================

/// Paints the ASTM G57 Wenner 4-pin physical array layout
class _WennerArrayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * 0.40;

    // Ground line
    final groundPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 2.0;
    canvas.drawLine(
        Offset(0, groundY), Offset(size.width, groundY), groundPaint);

    // Soil hatch lines below ground
    final soilPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(0, groundY, size.width, size.height),
      soilPaint,
    );

    // Pin positions equispaced
    final pinSpacing = size.width / 5.0;
    final pinX = [
      pinSpacing * 1.0, // C1
      pinSpacing * 2.0, // P1
      pinSpacing * 3.0, // P2
      pinSpacing * 4.0, // C2
    ];

    final pinDepth = 25.0;
    final pinColors = [
      const Color(0xFFEF4444), // C1
      const Color(0xFF38BDF8), // P1
      const Color(0xFF4EDEA3), // P2
      const Color(0xFFEF4444), // C2
    ];

    final labels = ['C1', 'P1', 'P2', 'C2'];

    // Draw Current Flow lines (Hemispherical arcs from C1 to C2)
    final arcPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final arcPath = Path();
    arcPath.moveTo(pinX[0], groundY + pinDepth);
    arcPath.quadraticBezierTo(
      size.width / 2.0,
      size.height * 0.95,
      pinX[3],
      groundY + pinDepth,
    );
    canvas.drawPath(arcPath, arcPaint);

    // Draw Potential lines (between P1 and P2)
    final pArcPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final pArcPath = Path();
    pArcPath.moveTo(pinX[1], groundY + pinDepth);
    pArcPath.quadraticBezierTo(
      size.width / 2.0,
      size.height * 0.70,
      pinX[2],
      groundY + pinDepth,
    );
    canvas.drawPath(pArcPath, pArcPaint);

    // Draw 4 Pins
    for (int i = 0; i < 4; i++) {
      final x = pinX[i];
      final color = pinColors[i];

      // Pin rod
      final rodPaint = Paint()
        ..color = color
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, groundY - 12),
        Offset(x, groundY + pinDepth),
        rodPaint,
      );

      // Pin terminal top circle
      final circlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, groundY - 14), 4.5, circlePaint);

      // Pin Label text
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 6, groundY - 30));
    }

    // Draw "a" spacing dimension lines
    final dimPaint = Paint()
      ..color = const Color(0xFFFFB95F)
      ..strokeWidth = 1.0;
    final dimY = groundY + pinDepth + 12;

    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(pinX[i], dimY),
        Offset(pinX[i + 1], dimY),
        dimPaint,
      );
      // Small vertical tick
      canvas.drawLine(
        Offset(pinX[i], dimY - 3),
        Offset(pinX[i], dimY + 3),
        dimPaint,
      );
      canvas.drawLine(
        Offset(pinX[i + 1], dimY - 3),
        Offset(pinX[i + 1], dimY + 3),
        dimPaint,
      );

      final dimPainter = TextPainter(
        text: const TextSpan(
          text: 'a',
          style: TextStyle(
            color: Color(0xFFFFB95F),
            fontWeight: FontWeight.bold,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      dimPainter.layout();
      dimPainter.paint(
        canvas,
        Offset((pinX[i] + pinX[i + 1]) / 2 - 3, dimY + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints the 100m Deep Well Vertical Cross-Section
class _DwicgBoreholePainter extends CustomPainter {
  final DwicgGroundbedRecord groundbed;

  _DwicgBoreholePainter({required this.groundbed});

  @override
  void paint(Canvas canvas, Size size) {
    final wellWidth = 32.0;
    final wellX = size.width / 2.0 - (wellWidth / 2.0);

    // Surface line
    final surfacePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, 16), Offset(size.width, 16), surfacePaint);

    // Inactive Casing (0m - 35m) -> Top 35% of well
    final casingHeight = size.height * 0.32;
    final casingPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(wellX, 16, wellWidth, casingHeight),
      casingPaint,
    );

    // Active Column with Coke Breeze (35m - 105m)
    final activeHeight = size.height - 16 - casingHeight - 6;
    final cokePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(wellX, 16 + casingHeight, wellWidth, activeHeight),
      cokePaint,
    );

    // Coke column border
    final wellBorderPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(
      Rect.fromLTWH(wellX, 16, wellWidth, size.height - 22),
      wellBorderPaint,
    );

    // Central Vent Pipe
    final ventPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.width / 2.0, 8),
      Offset(size.width / 2.0, size.height - 10),
      ventPaint,
    );

    // Draw Anodes (12 Anodes distributed in active column)
    final startY = 16 + casingHeight + 8;
    final stepY = (activeHeight - 16) / 11.0;

    for (int i = 0; i < groundbed.anodes.length; i++) {
      final anode = groundbed.anodes[i];
      final y = startY + (i * stepY);

      Color anodeColor = const Color(0xFF4EDEA3);
      if (anode.isSevered) {
        anodeColor = const Color(0xFFEF4444);
      } else if (anode.isOvercurrent) {
        anodeColor = const Color(0xFFF97316);
      } else if (!anode.isNominal) {
        anodeColor = const Color(0xFFFFB95F);
      }

      // Anode solid bar across borehole
      final anodePaint = Paint()
        ..color = anodeColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2.0, y),
            width: wellWidth - 8,
            height: 6,
          ),
          const Radius.circular(2),
        ),
        anodePaint,
      );

      // Draw Depth marker on the left
      if (i == 0 || i == 5 || i == 11) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${anode.depthMeters.toInt()}m (${anode.tag})',
            style: TextStyle(
              color: anodeColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(wellX - 70, y - 5));
      }
    }

    // Water Table line
    final waterY = 16 + (size.height * 0.16);
    final waterPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(wellX + wellWidth + 4, waterY),
        Offset(size.width - 20, waterY), waterPaint);

    final waterText = TextPainter(
      text: const TextSpan(
        text: 'Water Table (-14m)',
        style: TextStyle(
          color: Color(0xFF0284C7),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    waterText.layout();
    waterText.paint(canvas, Offset(wellX + wellWidth + 8, waterY - 12));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
