import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// ENUMS & DOMAIN CONSTANTS (NACE TM0497 / SP0207 / SP0169 / SP0502)
// ============================================================================

/// DCVG Coating Defect Severity Classification per NACE SP0207 / SP0502 ECDA
enum DcvgDefectCategory {
  category1, // < 15% IR: Isolated minor holiday / coating micro-defect
  category2, // 15% - 35% IR: Moderate coating defect
  category3, // 35% - 70% IR: Severe coating defect / shielding hazard
  category4, // > 70% IR: Critical holiday / bare steel exposure
}

extension DcvgDefectCategoryExt on DcvgDefectCategory {
  String get code {
    switch (this) {
      case DcvgDefectCategory.category1:
        return 'Cat 1 (<15% IR)';
      case DcvgDefectCategory.category2:
        return 'Cat 2 (15-35% IR)';
      case DcvgDefectCategory.category3:
        return 'Cat 3 (35-70% IR)';
      case DcvgDefectCategory.category4:
        return 'Cat 4 (>70% IR)';
    }
  }

  String get title {
    switch (this) {
      case DcvgDefectCategory.category1:
        return 'Isolated Minor Defect';
      case DcvgDefectCategory.category2:
        return 'Moderate Defect';
      case DcvgDefectCategory.category3:
        return 'Severe Coating Holiday';
      case DcvgDefectCategory.category4:
        return 'Critical Bare Steel Holiday';
    }
  }

  String get severityLabel {
    switch (this) {
      case DcvgDefectCategory.category1:
        return 'Low Priority';
      case DcvgDefectCategory.category2:
        return 'Medium Priority';
      case DcvgDefectCategory.category3:
        return 'High Priority';
      case DcvgDefectCategory.category4:
        return 'Immediate Action';
    }
  }

  Color get color {
    switch (this) {
      case DcvgDefectCategory.category1:
        return const Color(0xFF4EDEA3); // Tertiary Green
      case DcvgDefectCategory.category2:
        return const Color(0xFF38BDF8); // Primary Cyan
      case DcvgDefectCategory.category3:
        return const Color(0xFFFFB95F); // Amber Warning
      case DcvgDefectCategory.category4:
        return const Color(0xFFEF4444); // Critical Red
    }
  }

  IconData get icon {
    switch (this) {
      case DcvgDefectCategory.category1:
        return Icons.check_circle_outline_rounded;
      case DcvgDefectCategory.category2:
        return Icons.info_outline_rounded;
      case DcvgDefectCategory.category3:
        return Icons.warning_amber_rounded;
      case DcvgDefectCategory.category4:
        return Icons.dangerous_rounded;
    }
  }

  String get naceRecommendation {
    switch (this) {
      case DcvgDefectCategory.category1:
        return 'Adequately protected by standard CP. Log in GIS database and re-evaluate at 5-year CIPS cycle.';
      case DcvgDefectCategory.category2:
        return 'Verify polarized E_off <= -850 mV. Schedule routine inspection; inspect if in high corrosivity soil.';
      case DcvgDefectCategory.category3:
        return 'Risk of CP shielding or rapid CP depletion. Rank for ECDA direct examination bell-hole excavation.';
      case DcvgDefectCategory.category4:
        return 'Mandatory bell-hole excavation within 60 days per OISD-141 / NACE ECDA. Recoat with 3LPE sleeve.';
    }
  }

  static DcvgDefectCategory fromPercentIr(double percentIr) {
    if (percentIr < 15.0) {
      return DcvgDefectCategory.category1;
    } else if (percentIr <= 35.0) {
      return DcvgDefectCategory.category2;
    } else if (percentIr <= 70.0) {
      return DcvgDefectCategory.category3;
    } else {
      return DcvgDefectCategory.category4;
    }
  }
}

/// CIPS Pipe-to-Soil Compliance Status per NACE SP0169 criteria
enum CipsComplianceStatus {
  compliant, // E_off <= -850 mV and >= -1200 mV (CSE)
  underProtected, // E_off > -850 mV (e.g. -790 mV)
  overProtected, // E_off < -1200 mV (e.g. -1280 mV, hydrogen embrittlement risk)
  decayCompliant, // 100 mV cathodic polarization decay achieved
}

extension CipsComplianceStatusExt on CipsComplianceStatus {
  String get label {
    switch (this) {
      case CipsComplianceStatus.compliant:
        return 'NACE Compliant (≤ -850 mV)';
      case CipsComplianceStatus.underProtected:
        return 'Under-Protected (> -850 mV)';
      case CipsComplianceStatus.overProtected:
        return 'Over-Protected (< -1200 mV)';
      case CipsComplianceStatus.decayCompliant:
        return '100 mV Decay Compliant';
    }
  }

  Color get color {
    switch (this) {
      case CipsComplianceStatus.compliant:
        return const Color(0xFF4EDEA3);
      case CipsComplianceStatus.underProtected:
        return const Color(0xFFEF4444);
      case CipsComplianceStatus.overProtected:
        return const Color(0xFFFFB95F);
      case CipsComplianceStatus.decayCompliant:
        return const Color(0xFF38BDF8);
    }
  }

  IconData get icon {
    switch (this) {
      case CipsComplianceStatus.compliant:
        return Icons.verified_user_rounded;
      case CipsComplianceStatus.underProtected:
        return Icons.warning_rounded;
      case CipsComplianceStatus.overProtected:
        return Icons.offline_bolt_rounded;
      case CipsComplianceStatus.decayCompliant:
        return Icons.published_with_changes_rounded;
    }
  }
}

/// Defect electrical orientation (Anodic vs Cathodic)
enum GradientPolarity {
  cathodic, // Current entering pipe (normal CP protection)
  anodic, // Current discharging to soil (active corrosion cell!)
}

extension GradientPolarityExt on GradientPolarity {
  String get label {
    switch (this) {
      case GradientPolarity.cathodic:
        return 'Cathodic Current Inflow';
      case GradientPolarity.anodic:
        return 'Anodic Discharge (Active Cell)';
    }
  }

  Color get color {
    switch (this) {
      case GradientPolarity.cathodic:
        return const Color(0xFF4EDEA3);
      case GradientPolarity.anodic:
        return const Color(0xFFEF4444);
    }
  }
}

/// Bell-Hole Excavation Stage for ECDA Direct Examination
enum ExcavationStatus {
  pendingReview,
  approvedForDig,
  inExcavation,
  repairedAndClosed,
}

extension ExcavationStatusExt on ExcavationStatus {
  String get label {
    switch (this) {
      case ExcavationStatus.pendingReview:
        return 'Pending ECDA Review';
      case ExcavationStatus.approvedForDig:
        return 'Approved for Bell-Hole';
      case ExcavationStatus.inExcavation:
        return 'Excavation Active';
      case ExcavationStatus.repairedAndClosed:
        return 'Repaired & Recoated';
    }
  }

  Color get color {
    switch (this) {
      case ExcavationStatus.pendingReview:
        return const Color(0xFF94A3B8);
      case ExcavationStatus.approvedForDig:
        return const Color(0xFFFFB95F);
      case ExcavationStatus.inExcavation:
        return const Color(0xFF38BDF8);
      case ExcavationStatus.repairedAndClosed:
        return const Color(0xFF4EDEA3);
    }
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

/// Single CIPS survey measurement point along the pipeline chainage
class CipsSurveyPoint {
  final String id;
  final double chainageKm; // Distance in km (e.g. 1.250)
  final String chainageStr; // e.g. "KP 1+250"
  final double latitude;
  final double longitude;
  final double onPotentialMv; // E_on with IR drop (mV vs CSE, e.g. -1220)
  final double instantOffMv; // E_off polarized IR-free (mV vs CSE, e.g. -940)
  final double nativePotentialMv; // Baseline native potential (e.g. -580)
  final double polarizationDecayMv; // InstantOff - Native (mV)
  final double soilResistivityOhmM; // Local soil resistivity in Ohm-m
  final String soilTerrain; // e.g. "Alluvial clay loam", "Waterlogged paddy"
  final String landmark; // e.g. "Road Crossing #2", "Near TLP-04"
  final DateTime timestamp;

  const CipsSurveyPoint({
    required this.id,
    required this.chainageKm,
    required this.chainageStr,
    required this.latitude,
    required this.longitude,
    required this.onPotentialMv,
    required this.instantOffMv,
    required this.nativePotentialMv,
    required this.polarizationDecayMv,
    required this.soilResistivityOhmM,
    required this.soilTerrain,
    required this.landmark,
    required this.timestamp,
  });

  /// IR Drop in soil & coating: |E_on - E_off| in mV
  double get irDropMv => (onPotentialMv - instantOffMv).abs();

  /// Effective polarization formation/decay: |E_off - E_native| in mV
  double get effectivePolarizationMv => (instantOffMv - nativePotentialMv).abs();

  /// Static calculation of polarization decay
  static double calculatePolarizationDecay(double instantOff, double nativePotential) =>
      (instantOff - nativePotential).abs();

  /// Static check for primary NACE -850 mV criterion
  static bool isNace850Compliant(double instantOffMv) =>
      instantOffMv <= -850.0 && instantOffMv >= -1200.0;

  /// Static check for secondary 100 mV polarization decay criterion
  static bool is100MvDecayCompliant(double decayMv) => decayMv >= 100.0;

  /// NACE SP0169 Compliance status
  CipsComplianceStatus get complianceStatus {
    if (instantOffMv < -1200.0) {
      return CipsComplianceStatus.overProtected;
    } else if (instantOffMv <= -850.0) {
      return CipsComplianceStatus.compliant;
    } else if (effectivePolarizationMv >= 100.0) {
      return CipsComplianceStatus.decayCompliant;
    } else {
      return CipsComplianceStatus.underProtected;
    }
  }
}

/// DCVG coating holiday defect record
class DcvgDefectRecord {
  final String id; // e.g. "DCVG-DF-01"
  final double chainageKm; // e.g. 2.450
  final String chainageStr; // "KP 2+450"
  final double latitude;
  final double longitude;
  final double deltaVDefectMv; // Surface gradient from epicenter to remote earth (mV)
  final double totalIrDropMv; // Total pipe-to-soil IR drop (mV)
  final GradientPolarity polarity;
  final String orientationClock; // e.g. "12 o'clock (Crown)", "6 o'clock (Invert)"
  final double estimatedDefectAreaCm2;
  final String soilCondition;
  final DateTime detectedDate;
  final String surveyorName;
  ExcavationStatus excavationStatus;
  final String notes;

  DcvgDefectRecord({
    required this.id,
    required this.chainageKm,
    required this.chainageStr,
    required this.latitude,
    required this.longitude,
    required this.deltaVDefectMv,
    required this.totalIrDropMv,
    required this.polarity,
    required this.orientationClock,
    required this.estimatedDefectAreaCm2,
    required this.soilCondition,
    required this.detectedDate,
    required this.surveyorName,
    required this.excavationStatus,
    required this.notes,
  });

  /// Static calculation of %IR defect severity: %IR = (delta_V / total_IR) * 100
  static double calculatePercentIr(double deltaV, double totalIr) {
    if (totalIr <= 0) return 0.0;
    return (deltaV / totalIr) * 100.0;
  }

  /// %IR defect severity calculation: %IR = (delta_V / total_IR) * 100
  double get percentIr => calculatePercentIr(deltaVDefectMv, totalIrDropMv);

  /// Severity category classification
  DcvgDefectCategory get category => DcvgDefectCategoryExt.fromPercentIr(percentIr);

  /// ECDA excavation priority score (0 to 100)
  double get ecdaPriorityScore {
    double base = percentIr;
    if (polarity == GradientPolarity.anodic) base += 25.0;
    if (orientationClock.contains('6 o\'clock')) base += 10.0; // Invert risk of under-deposit corrosion
    return math.min(100.0, math.max(5.0, base));
  }
}

/// GPS Current Interrupter Unit Status
class GpsInterrupterUnit {
  final String id;
  final String stationName; // e.g. "TRU-01 Duliajan Central"
  final double chainageKm;
  final double operatingCurrentAmps;
  final double operatingVoltageVolts;
  final bool isGpsLocked;
  final int satellitesTracked;
  final double timeDriftMs; // drift in ms (< 1ms required)
  final bool isInterrupterActive;

  const GpsInterrupterUnit({
    required this.id,
    required this.stationName,
    required this.chainageKm,
    required this.operatingCurrentAmps,
    required this.operatingVoltageVolts,
    required this.isGpsLocked,
    required this.satellitesTracked,
    required this.timeDriftMs,
    required this.isInterrupterActive,
  });
}

/// Bell-Hole Direct Examination Record for ECDA Step 3
class BellHoleExamination {
  final String defectId;
  final String chainageStr;
  final double pitDepthMm;
  final double nominalWallThicknessMm;
  final double remainingWallThicknessMm;
  final double soilPh;
  final String coatingCondition;
  final bool microbesDetectedSrb; // Sulfate Reducing Bacteria
  final String actionTaken;

  const BellHoleExamination({
    required this.defectId,
    required this.chainageStr,
    required this.pitDepthMm,
    required this.nominalWallThicknessMm,
    required this.remainingWallThicknessMm,
    required this.soilPh,
    required this.coatingCondition,
    required this.microbesDetectedSrb,
    required this.actionTaken,
  });

  double get wallLossPercentage =>
      ((nominalWallThicknessMm - remainingWallThicknessMm) /
          nominalWallThicknessMm) *
      100.0;
}

// ============================================================================
// MAIN CIPS & DCVG SCREEN WIDGET
// ============================================================================

class CipsDcvgScreen extends StatefulWidget {
  const CipsDcvgScreen({super.key});

  @override
  State<CipsDcvgScreen> createState() => _CipsDcvgScreenState();
}

class _CipsDcvgScreenState extends State<CipsDcvgScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Interrupter settings
  double _interrupterOnSeconds = 0.8;
  double _interrupterOffSeconds = 0.2;
  bool _isInterrupterSynchronized = true;

  // Trailing wire telemetry
  final double _trailingWireTensionNewtons = 14.5;
  final double _trailingWireSpoolRemainingMeters = 3450.0;
  final bool _isTrailingWireIntact = true;

  // Interactive filter & search state
  DcvgDefectCategory? _selectedCategoryFilter;
  String _searchQuery = '';

  // Field Calculator state
  double _calcDeltaV = 85.0; // mV
  double _calcTotalIr = 250.0; // mV
  double _calcInstantOff = -920.0; // mV CSE
  double _calcNative = -580.0; // mV CSE

  // Data lists
  late List<CipsSurveyPoint> _cipsSurveyPoints;
  late List<DcvgDefectRecord> _dcvgDefects;
  late List<GpsInterrupterUnit> _interrupterStations;
  late List<BellHoleExamination> _bellHoleList;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeSurveyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeSurveyData() {
    // Synchronized GPS Interrupters installed at TRU stations
    _interrupterStations = [
      const GpsInterrupterUnit(
        id: 'INT-01',
        stationName: 'TRU-01 Duliajan CGGS Header',
        chainageKm: 0.150,
        operatingCurrentAmps: 18.4,
        operatingVoltageVolts: 24.2,
        isGpsLocked: true,
        satellitesTracked: 14,
        timeDriftMs: 0.12,
        isInterrupterActive: true,
      ),
      const GpsInterrupterUnit(
        id: 'INT-02',
        stationName: 'TRU-02 Tipling River Crossing',
        chainageKm: 4.820,
        operatingCurrentAmps: 14.2,
        operatingVoltageVolts: 21.0,
        isGpsLocked: true,
        satellitesTracked: 12,
        timeDriftMs: 0.18,
        isInterrupterActive: true,
      ),
      const GpsInterrupterUnit(
        id: 'INT-03',
        stationName: 'TRU-03 Digboi Junction Terminal',
        chainageKm: 11.200,
        operatingCurrentAmps: 16.8,
        operatingVoltageVolts: 22.5,
        isGpsLocked: true,
        satellitesTracked: 15,
        timeDriftMs: 0.08,
        isInterrupterActive: true,
      ),
    ];

    // High-Resolution CIPS Survey Points (KP 0+000 to KP 12+500)
    _cipsSurveyPoints = [
      CipsSurveyPoint(
        id: 'CIPS-001',
        chainageKm: 0.200,
        chainageStr: 'KP 0+200',
        latitude: 27.2845,
        longitude: 95.3188,
        onPotentialMv: -1240,
        instantOffMv: -1050,
        nativePotentialMv: -560,
        polarizationDecayMv: 490,
        soilResistivityOhmM: 42.0,
        soilTerrain: 'Moist Sandy Silt',
        landmark: 'TRU-01 Discharge Header',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-002',
        chainageKm: 0.850,
        chainageStr: 'KP 0+850',
        latitude: 27.2872,
        longitude: 95.3215,
        onPotentialMv: -1210,
        instantOffMv: -1025,
        nativePotentialMv: -570,
        polarizationDecayMv: 455,
        soilResistivityOhmM: 38.5,
        soilTerrain: 'Cultivated Paddy Field',
        landmark: 'Culvert Crossing #1',
        timestamp: DateTime.now().subtract(const Duration(hours: 7, minutes: 40)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-003',
        chainageKm: 1.500,
        chainageStr: 'KP 1+500',
        latitude: 27.2899,
        longitude: 95.3248,
        onPotentialMv: -1180,
        instantOffMv: -990,
        nativePotentialMv: -580,
        polarizationDecayMv: 410,
        soilResistivityOhmM: 45.0,
        soilTerrain: 'Dense Tea Garden Loam',
        landmark: 'TLP-02 Marker Post',
        timestamp: DateTime.now().subtract(const Duration(hours: 7, minutes: 15)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-004',
        chainageKm: 2.150,
        chainageStr: 'KP 2+150',
        latitude: 27.2925,
        longitude: 95.3280,
        onPotentialMv: -1150,
        instantOffMv: -960,
        nativePotentialMv: -575,
        polarizationDecayMv: 385,
        soilResistivityOhmM: 28.0,
        soilTerrain: 'Moist Clay Alluvium',
        landmark: 'Drainage Canal Crossing',
        timestamp: DateTime.now().subtract(const Duration(hours: 6, minutes: 50)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-005',
        chainageKm: 2.800,
        chainageStr: 'KP 2+800',
        latitude: 27.2951,
        longitude: 95.3312,
        onPotentialMv: -1090,
        instantOffMv: -915,
        nativePotentialMv: -590,
        polarizationDecayMv: 325,
        soilResistivityOhmM: 22.0,
        soilTerrain: 'Waterlogged Marshy Area',
        landmark: 'Wetland Dip',
        timestamp: DateTime.now().subtract(const Duration(hours: 6, minutes: 20)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-006',
        chainageKm: 3.450,
        chainageStr: 'KP 3+450',
        latitude: 27.2980,
        longitude: 95.3345,
        onPotentialMv: -980,
        instantOffMv: -810, // UNDER-PROTECTED DEPRESSION!
        nativePotentialMv: -600,
        polarizationDecayMv: 210,
        soilResistivityOhmM: 14.5, // Highly corrosive
        soilTerrain: 'Saline Clay Depression',
        landmark: 'Severe Coating Anomaly (DCVG Cat 4)',
        timestamp: DateTime.now().subtract(const Duration(hours: 5, minutes: 50)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-007',
        chainageKm: 4.100,
        chainageStr: 'KP 4+100',
        latitude: 27.3006,
        longitude: 95.3378,
        onPotentialMv: -1130,
        instantOffMv: -930,
        nativePotentialMv: -580,
        polarizationDecayMv: 350,
        soilResistivityOhmM: 34.0,
        soilTerrain: 'Sandy Silt Road Verge',
        landmark: 'SH-38 Highway Casing South',
        timestamp: DateTime.now().subtract(const Duration(hours: 5, minutes: 15)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-008',
        chainageKm: 4.800,
        chainageStr: 'KP 4+800',
        latitude: 27.3033,
        longitude: 95.3410,
        onPotentialMv: -1280,
        instantOffMv: -1080,
        nativePotentialMv: -560,
        polarizationDecayMv: 520,
        soilResistivityOhmM: 52.0,
        soilTerrain: 'Riverbank Coarse Gravel',
        landmark: 'TRU-02 Drainage Tie-in',
        timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 40)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-009',
        chainageKm: 5.500,
        chainageStr: 'KP 5+500',
        latitude: 27.3060,
        longitude: 95.3444,
        onPotentialMv: -1205,
        instantOffMv: -1010,
        nativePotentialMv: -570,
        polarizationDecayMv: 440,
        soilResistivityOhmM: 40.0,
        soilTerrain: 'Alluvial Loam',
        landmark: 'Tipling River North Bank',
        timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 05)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-010',
        chainageKm: 6.200,
        chainageStr: 'KP 6+200',
        latitude: 27.3088,
        longitude: 95.3477,
        onPotentialMv: -1160,
        instantOffMv: -965,
        nativePotentialMv: -585,
        polarizationDecayMv: 380,
        soilResistivityOhmM: 36.0,
        soilTerrain: 'Forest Humus Loam',
        landmark: 'Reserve Forest Boundary Post',
        timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-011',
        chainageKm: 6.900,
        chainageStr: 'KP 6+900',
        latitude: 27.3115,
        longitude: 95.3510,
        onPotentialMv: -1020,
        instantOffMv: -835, // SLIGHT UNDER-PROTECTION (< -850 mV criterion)
        nativePotentialMv: -590,
        polarizationDecayMv: 245, // but > 100 mV decay!
        soilResistivityOhmM: 18.0,
        soilTerrain: 'Stagnant Swale Silt',
        landmark: 'DCVG Moderate Defect (Cat 3)',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 55)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-012',
        chainageKm: 7.600,
        chainageStr: 'KP 7+600',
        latitude: 27.3142,
        longitude: 95.3542,
        onPotentialMv: -1140,
        instantOffMv: -945,
        nativePotentialMv: -575,
        polarizationDecayMv: 370,
        soilResistivityOhmM: 31.0,
        soilTerrain: 'Paddy Silt Loam',
        landmark: 'TLP-08 Test Post',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 20)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-013',
        chainageKm: 8.300,
        chainageStr: 'KP 8+300',
        latitude: 27.3170,
        longitude: 95.3575,
        onPotentialMv: -1175,
        instantOffMv: -980,
        nativePotentialMv: -580,
        polarizationDecayMv: 400,
        soilResistivityOhmM: 44.0,
        soilTerrain: 'Sandy Clay',
        landmark: 'Railway Track Crossing',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-014',
        chainageKm: 9.100,
        chainageStr: 'KP 9+100',
        latitude: 27.3200,
        longitude: 95.3610,
        onPotentialMv: -1190,
        instantOffMv: -1005,
        nativePotentialMv: -565,
        polarizationDecayMv: 440,
        soilResistivityOhmM: 48.0,
        soilTerrain: 'High Ground Sandy Silt',
        landmark: 'TLP-11 Valve Station #2',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-015',
        chainageKm: 10.000,
        chainageStr: 'KP 10+000',
        latitude: 27.3235,
        longitude: 95.3650,
        onPotentialMv: -1215,
        instantOffMv: -1030,
        nativePotentialMv: -570,
        polarizationDecayMv: 460,
        soilResistivityOhmM: 50.0,
        soilTerrain: 'Laterite Gravel',
        landmark: 'Digboi Approach Road',
        timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
      ),
      CipsSurveyPoint(
        id: 'CIPS-016',
        chainageKm: 11.200,
        chainageStr: 'KP 11+200',
        latitude: 27.3280,
        longitude: 95.3700,
        onPotentialMv: -1270,
        instantOffMv: -1085,
        nativePotentialMv: -560,
        polarizationDecayMv: 525,
        soilResistivityOhmM: 60.0,
        soilTerrain: 'Refinery Yard Gravel',
        landmark: 'TRU-03 Receiving Terminal',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ];

    // DCVG Coating Holiday Defect Register
    _dcvgDefects = [
      DcvgDefectRecord(
        id: 'DCVG-DF-01',
        chainageKm: 1.250,
        chainageStr: 'KP 1+250',
        latitude: 27.2885,
        longitude: 95.3232,
        deltaVDefectMv: 24.0,
        totalIrDropMv: 220.0, // %IR = 10.91% -> Cat 1
        polarity: GradientPolarity.cathodic,
        orientationClock: '12 o\'clock (Crown)',
        estimatedDefectAreaCm2: 4.5,
        soilCondition: 'Moist Sandy Silt',
        detectedDate: DateTime.now().subtract(const Duration(days: 4)),
        surveyorName: 'P. Bora (NACE CP-2)',
        excavationStatus: ExcavationStatus.pendingReview,
        notes: 'Isolated pinhole holiday on 3LPE coating. Low potential gradient, protected by CP.',
      ),
      DcvgDefectRecord(
        id: 'DCVG-DF-02',
        chainageKm: 2.340,
        chainageStr: 'KP 2+340',
        latitude: 27.2932,
        longitude: 95.3290,
        deltaVDefectMv: 48.0,
        totalIrDropMv: 210.0, // %IR = 22.86% -> Cat 2
        polarity: GradientPolarity.cathodic,
        orientationClock: '3 o\'clock (East)',
        estimatedDefectAreaCm2: 12.0,
        soilCondition: 'Alluvial Loam',
        detectedDate: DateTime.now().subtract(const Duration(days: 3)),
        surveyorName: 'P. Bora (NACE CP-2)',
        excavationStatus: ExcavationStatus.pendingReview,
        notes: 'Field joint shrink sleeve edge delamination. Adequate cathodic current pickup.',
      ),
      DcvgDefectRecord(
        id: 'DCVG-DF-03',
        chainageKm: 3.450,
        chainageStr: 'KP 3+450',
        latitude: 27.2980,
        longitude: 95.3345,
        deltaVDefectMv: 145.0,
        totalIrDropMv: 170.0, // %IR = 85.29% -> Cat 4 CRITICAL!
        polarity: GradientPolarity.anodic, // ACTIVE DISCHARGE CORROSION!
        orientationClock: '6 o\'clock (Invert)',
        estimatedDefectAreaCm2: 65.0,
        soilCondition: 'Saline Wet Clay (14.5 Ω·m)',
        detectedDate: DateTime.now().subtract(const Duration(days: 2)),
        surveyorName: 'B. Gogoi (NACE CP-3)',
        excavationStatus: ExcavationStatus.inExcavation,
        notes: 'Critical coating holiday in corrosive depression. Backhoe mechanical gouge suspected. E_off dropped to -810 mV.',
      ),
      DcvgDefectRecord(
        id: 'DCVG-DF-04',
        chainageKm: 6.900,
        chainageStr: 'KP 6+900',
        latitude: 27.3115,
        longitude: 95.3510,
        deltaVDefectMv: 82.0,
        totalIrDropMv: 185.0, // %IR = 44.32% -> Cat 3 SEVERE
        polarity: GradientPolarity.cathodic,
        orientationClock: '9 o\'clock (West)',
        estimatedDefectAreaCm2: 28.0,
        soilCondition: 'Swale Waterlogged Silt',
        detectedDate: DateTime.now().subtract(const Duration(days: 2)),
        surveyorName: 'B. Gogoi (NACE CP-3)',
        excavationStatus: ExcavationStatus.approvedForDig,
        notes: 'Severe rock impingement gouge during backfilling. High CP current draw.',
      ),
      DcvgDefectRecord(
        id: 'DCVG-DF-05',
        chainageKm: 8.650,
        chainageStr: 'KP 8+650',
        latitude: 27.3182,
        longitude: 95.3590,
        deltaVDefectMv: 18.0,
        totalIrDropMv: 215.0, // %IR = 8.37% -> Cat 1
        polarity: GradientPolarity.cathodic,
        orientationClock: '12 o\'clock (Crown)',
        estimatedDefectAreaCm2: 3.0,
        soilCondition: 'Sandy Loam',
        detectedDate: DateTime.now().subtract(const Duration(days: 1)),
        surveyorName: 'P. Bora (NACE CP-2)',
        excavationStatus: ExcavationStatus.repairedAndClosed,
        notes: 'Minor holiday repaired with Canusa wrap sleeve during pre-commissioning walkdown.',
      ),
      DcvgDefectRecord(
        id: 'DCVG-DF-06',
        chainageKm: 10.450,
        chainageStr: 'KP 10+450',
        latitude: 27.3250,
        longitude: 95.3670,
        deltaVDefectMv: 58.0,
        totalIrDropMv: 205.0, // %IR = 28.29% -> Cat 2
        polarity: GradientPolarity.cathodic,
        orientationClock: '3 o\'clock (East)',
        estimatedDefectAreaCm2: 15.5,
        soilCondition: 'Lateritic Soil',
        detectedDate: DateTime.now().subtract(const Duration(hours: 18)),
        surveyorName: 'B. Gogoi (NACE CP-3)',
        excavationStatus: ExcavationStatus.pendingReview,
        notes: 'Coating holiday near pipeline road crossing. Polarized potential healthy at -1010 mV.',
      ),
    ];

    // ECDA Direct Examination (Bell-Hole Excavations)
    _bellHoleList = [
      const BellHoleExamination(
        defectId: 'DCVG-DF-03',
        chainageStr: 'KP 3+450',
        pitDepthMm: 2.1,
        nominalWallThicknessMm: 9.53,
        remainingWallThicknessMm: 7.43,
        soilPh: 5.8,
        coatingCondition: 'Torn 3LPE with exposed steel & disbondment',
        microbesDetectedSrb: true,
        actionTaken: 'Sandblasted Sa 2.5, pit filled with Belzona 1111, applied Canusa GTS-PE heat shrink sleeve.',
      ),
      const BellHoleExamination(
        defectId: 'DCVG-DF-05',
        chainageStr: 'KP 8+650',
        pitDepthMm: 0.0,
        nominalWallThicknessMm: 9.53,
        remainingWallThicknessMm: 9.53,
        soilPh: 6.9,
        coatingCondition: 'Surface holiday with zero metal loss',
        microbesDetectedSrb: false,
        actionTaken: 'Coating touch-up applied with melt stick & visco-elastic tape patch.',
      ),
    ];
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
                _buildCipsProfileTab(),
                _buildDcvgSurveyTab(),
                _buildEcdaTriangulationTab(),
                _buildEngineeringCalculatorsTab(),
                _buildEcdaComplianceAuditTab(),
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
                'CIPS & DCVG Integrity Survey',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(width: 8),
              _ComplianceHeaderBadge(),
            ],
          ),
          Text(
            'NACE TM0497 · SP0207 · SP0169 ECDA Indirect Inspection',
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
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Sync Interrupters & GPS',
          onPressed: () {
            setState(() {
              _isInterrupterSynchronized = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('GPS Current Interrupters Re-Synchronized (0.8s ON / 0.2s OFF, Drift: 0.08ms)'),
                backgroundColor: AppTheme.surfaceContainerHigh,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
          tooltip: 'Export ECDA Indirect Inspection Report',
          onPressed: _showExportReportDialog,
        ),
      ],
    );
  }

  Widget _buildTelemetryTopBanner() {
    final cat4Count = _dcvgDefects.where((d) => d.category == DcvgDefectCategory.category4).length;
    final cat3Count = _dcvgDefects.where((d) => d.category == DcvgDefectCategory.category3).length;
    final underProtectedPoints = _cipsSurveyPoints.where((p) => p.complianceStatus == CipsComplianceStatus.underProtected).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          // GPS Interrupter badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isInterrupterSynchronized
                  ? const Color(0xFF4EDEA3).withValues(alpha: 0.15)
                  : const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isInterrupterSynchronized
                    ? const Color(0xFF4EDEA3).withValues(alpha: 0.5)
                    : const Color(0xFFEF4444).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isInterrupterSynchronized ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                  size: 13,
                  color: _isInterrupterSynchronized ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 5),
                Text(
                  'GPS SYNC ${_interrupterOnSeconds}s ON / ${_interrupterOffSeconds}s OFF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _isInterrupterSynchronized ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Trailing wire spool
          Expanded(
            child: Row(
              children: [
                Icon(
                  _isTrailingWireIntact ? Icons.cable_rounded : Icons.link_off_rounded,
                  size: 13,
                  color: _isTrailingWireIntact ? AppTheme.primaryLight : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Wire: ${_trailingWireSpoolRemainingMeters.toStringAsFixed(0)}m (${_trailingWireTensionNewtons}N · ${_isTrailingWireIntact ? "Intact" : "Broken"})',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Severe Anomaly alert chip
          if (cat4Count > 0 || underProtectedPoints > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFEF4444)),
                  const SizedBox(width: 4),
                  Text(
                    'Alert: $cat4Count Cat4 | $cat3Count Cat3 | $underProtectedPoints Unprotected',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
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
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(
            icon: Icon(Icons.stacked_line_chart_rounded, size: 18),
            text: 'CIPS Profile',
          ),
          Tab(
            icon: Icon(Icons.grain_rounded, size: 18),
            text: 'DCVG Defects (%IR)',
          ),
          Tab(
            icon: Icon(Icons.troubleshoot_rounded, size: 18),
            text: 'ECDA Triangulation',
          ),
          Tab(
            icon: Icon(Icons.calculate_rounded, size: 18),
            text: '%IR & Decay Solver',
          ),
          Tab(
            icon: Icon(Icons.verified_rounded, size: 18),
            text: 'Compliance & Audit',
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_chart_rounded, size: 20),
      label: const Text(
        'Log Survey Point',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      onPressed: _showLogSurveyMenu,
    );
  }

  // ============================================================================
  // TAB 1: CIPS PROFILE (E_on vs E_off GRAPH & LIVE LOG)
  // ============================================================================

  Widget _buildCipsProfileTab() {
    final compliantCount = _cipsSurveyPoints.where((p) => p.complianceStatus == CipsComplianceStatus.compliant || p.complianceStatus == CipsComplianceStatus.decayCompliant).length;
    final totalPoints = _cipsSurveyPoints.length;
    final percentCompliant = totalPoints > 0 ? (compliantCount / totalPoints) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Header
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'NACE SP0169 COMPLIANCE',
                  value: '${percentCompliant.toStringAsFixed(1)}%',
                  subtext: '$compliantCount / $totalPoints Points Satisfied',
                  color: percentCompliant >= 90.0 ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F),
                  icon: Icons.verified_user_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: 'INTERRUPTER CYCLE',
                  value: '${_interrupterOnSeconds}s / ${_interrupterOffSeconds}s',
                  subtext: 'GPS Synced 0.8s ON / 0.2s OFF',
                  color: AppTheme.primaryLight,
                  icon: Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: 'CRITERIA THRESHOLD',
                  value: '-850 mV',
                  subtext: 'vs Cu/CuSO4 (CSE) Instant-Off',
                  color: const Color(0xFF4EDEA3),
                  icon: Icons.rule_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interactive Chart Card
          _buildChartContainerCard(),
          const SizedBox(height: 16),

          // Trailing Wire & Interrupter Station Telemetry Bar
          _buildInterrupterStationsCard(),
          const SizedBox(height: 16),

          // CIPS Survey Points Table / List
          _buildCipsPointsList(),
        ],
      ),
    );
  }

  Widget _buildChartContainerCard() {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pipe-to-Soil Potential Profile (CIPS)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'E_on vs E_off Polarized Potential vs Cu/CuSO4 Reference Electrode',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart_rounded, size: 14, color: AppTheme.primaryLight),
                    SizedBox(width: 4),
                    Text(
                      '34.8 km Corridor',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('E_on (With IR Drop)', const Color(0xFF38BDF8)),
              _buildLegendItem('E_off (Instant-Off Polarized)', const Color(0xFF4EDEA3)),
              _buildLegendItem('NACE -850 mV Criterion', const Color(0xFFEF4444), isDashed: true),
              _buildLegendItem('-1200 mV Overprotection', const Color(0xFFFFB95F), isDashed: true),
            ],
          ),
          const SizedBox(height: 20),

          // FlChart
          SizedBox(
            height: 260,
            child: _buildFlChart(),
          ),
          const SizedBox(height: 12),

          // Interpretation callout
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.primaryLight),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Per NACE SP0169: CP is compliant when polarized potential E_off is equal to or more negative than -850 mV (e.g. -950 mV) or satisfies 100 mV cathodic polarization decay. Potential more positive than -850 mV (e.g. -810 mV at KP 3+450) indicates under-protection.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isDashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildFlChart() {
    // We map potentials so that more negative is further down or up
    // In corrosion engineering, standard display often has -1400 at top or -600 at bottom.
    // Here: Y-values are absolute values: 600 to 1400 (representing -600 mV to -1400 mV)
    // -850 mV criterion is at Y = 850. -1200 mV is at Y = 1200.
    final onSpots = _cipsSurveyPoints.map((p) {
      return FlSpot(p.chainageKm, p.onPotentialMv.abs());
    }).toList();

    final offSpots = _cipsSurveyPoints.map((p) {
      return FlSpot(p.chainageKm, p.instantOffMv.abs());
    }).toList();

    return LineChart(
      LineChartData(
        minX: 0.0,
        maxX: 12.0,
        minY: 700.0,
        maxY: 1400.0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 100,
          verticalInterval: 2,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0xFF1E2E5C),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => const FlLine(
            color: Color(0xFF1E2E5C),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'KP ${value.toInt()}',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: 150,
              getTitlesWidget: (value, meta) {
                return Text(
                  '-${value.toInt()} mV',
                  style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            // -850 mV criterion
            HorizontalLine(
              y: 850,
              color: const Color(0xFFEF4444),
              strokeWidth: 2,
              dashArray: [5, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, top: 2),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444),
                ),
                labelResolver: (line) => '-850 mV Limit',
              ),
            ),
            // -1200 mV overprotection limit
            HorizontalLine(
              y: 1200,
              color: const Color(0xFFFFB95F),
              strokeWidth: 1.5,
              dashArray: [4, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFB95F),
                ),
                labelResolver: (line) => '-1200 mV Overprotection',
              ),
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppTheme.surfaceCard,
            tooltipBorder: const BorderSide(color: AppTheme.border, width: 1),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isOff = spot.barIndex == 1;
                final label = isOff ? 'E_off' : 'E_on';
                final mvVal = -spot.y.toInt();
                return LineTooltipItem(
                  'KP ${spot.x.toStringAsFixed(1)}\n$label: $mvVal mV',
                  TextStyle(
                    color: isOff ? const Color(0xFF4EDEA3) : const Color(0xFF38BDF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          // E_on Line
          LineChartBarData(
            spots: onSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: const Color(0xFF38BDF8),
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
          ),
          // E_off Line
          LineChartBarData(
            spots: offSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: const Color(0xFF4EDEA3),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // If spot is underprotected (y < 850 in magnitude, i.e. > -850 mV), draw in red
                final isUnder = spot.y < 850.0;
                return FlDotCirclePainter(
                  radius: isUnder ? 5 : 3,
                  color: isUnder ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
                  strokeWidth: isUnder ? 2 : 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterrupterStationsCard() {
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
              const Row(
                children: [
                  Icon(Icons.satellite_alt_rounded, size: 16, color: AppTheme.primaryLight),
                  SizedBox(width: 8),
                  Text(
                    'Synchronized Current Interrupter Network',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4EDEA3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '3 TRUs Interrupted',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4EDEA3)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: _interrupterStations.map((station) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4EDEA3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.stationName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'KP ${station.chainageKm.toStringAsFixed(3)} · ${station.operatingCurrentAmps}A / ${station.operatingVoltageVolts}V',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.gps_fixed_rounded, size: 12, color: Color(0xFF4EDEA3)),
                            const SizedBox(width: 4),
                            Text(
                              '${station.satellitesTracked} Sats Locked',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4EDEA3)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Drift: ${station.timeDriftMs} ms',
                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCipsPointsList() {
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
              const Text(
                'CIPS Trailing Wire Survey Data',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              Text(
                '${_cipsSurveyPoints.length} logged intervals',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cipsSurveyPoints.length,
            separatorBuilder: (context, index) => const Divider(color: AppTheme.border, height: 1),
            itemBuilder: (context, index) {
              final point = _cipsSurveyPoints[index];
              final status = point.complianceStatus;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status icon
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(status.icon, color: status.color, size: 18),
                    ),
                    const SizedBox(width: 12),

                    // Chainage & Landmark
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                point.chainageStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: status.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status.label,
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: status.color),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${point.landmark} · ${point.soilTerrain} (${DateFormat('HH:mm').format(point.timestamp)})',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // E_on & E_off values
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Off: ${point.instantOffMv.toStringAsFixed(0)} mV',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: status.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'On: ${point.onPotentialMv.toStringAsFixed(0)} mV | IR: ${point.irDropMv.toStringAsFixed(0)} mV',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: DCVG DEFECT SURVEY (%IR & CATEGORY CLASSIFICATION)
  // ============================================================================

  Widget _buildDcvgSurveyTab() {
    // Filter defects by category if selected
    final displayedDefects = _dcvgDefects.where((d) {
      if (_selectedCategoryFilter != null && d.category != _selectedCategoryFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return d.id.toLowerCase().contains(q) ||
            d.chainageStr.toLowerCase().contains(q) ||
            d.notes.toLowerCase().contains(q) ||
            d.soilCondition.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NACE SP0207 DCVG Categories Banner
          _buildDcvgCategoryOverviewCards(),
          const SizedBox(height: 16),

          // Search & Category Filter Chips
          _buildDcvgFilterBar(),
          const SizedBox(height: 16),

          // Defects List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Identified Coating Holidays (${displayedDefects.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Formula: %IR = (ΔV / Total IR) × 100',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.primaryLight.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (displayedDefects.isEmpty)
            _buildEmptyDefectsCard()
          else
            Column(
              children: displayedDefects.map((defect) => _buildDefectCard(defect)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDcvgCategoryOverviewCards() {
    final cat1Count = _dcvgDefects.where((d) => d.category == DcvgDefectCategory.category1).length;
    final cat2Count = _dcvgDefects.where((d) => d.category == DcvgDefectCategory.category2).length;
    final cat3Count = _dcvgDefects.where((d) => d.category == DcvgDefectCategory.category3).length;
    final cat4Count = _dcvgDefects.where((d) => d.category == DcvgDefectCategory.category4).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NACE SP0207 Coating Defect Severity Classification',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Categorized by %IR gradient across soil surface to remote earth',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCategoryBadgeTile(
                category: DcvgDefectCategory.category1,
                count: cat1Count,
                range: '< 15% IR',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCategoryBadgeTile(
                category: DcvgDefectCategory.category2,
                count: cat2Count,
                range: '15% - 35% IR',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCategoryBadgeTile(
                category: DcvgDefectCategory.category3,
                count: cat3Count,
                range: '35% - 70% IR',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCategoryBadgeTile(
                category: DcvgDefectCategory.category4,
                count: cat4Count,
                range: '> 70% IR',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryBadgeTile({
    required DcvgDefectCategory category,
    required int count,
    required String range,
  }) {
    final isSelected = _selectedCategoryFilter == category;

    return InkWell(
      onTap: () {
        setState(() {
          if (_selectedCategoryFilter == category) {
            _selectedCategoryFilter = null;
          } else {
            _selectedCategoryFilter = category;
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? category.color.withValues(alpha: 0.2) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? category.color : AppTheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, size: 14, color: category.color),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: category.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              category.code,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              range,
              style: const TextStyle(fontSize: 8, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDcvgFilterBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by Defect ID, KP, notes...',
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
            ),
          ),
        ),
        if (_selectedCategoryFilter != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textMuted),
            tooltip: 'Clear Filter',
            onPressed: () {
              setState(() {
                _selectedCategoryFilter = null;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDefectCard(DcvgDefectRecord defect) {
    final cat = defect.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cat == DcvgDefectCategory.category4
              ? const Color(0xFFEF4444).withValues(alpha: 0.8)
              : AppTheme.border,
          width: cat == DcvgDefectCategory.category4 ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ID, KP, Category Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      defect.id,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    defect.chainageStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: cat.color.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 12, color: cat.color),
                    const SizedBox(width: 4),
                    Text(
                      cat.code,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: cat.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Key metrics row (%IR, Delta V, Total IR, Area)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DEFECT SEVERITY (%IR)',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${defect.percentIr.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cat.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GRADIENT (ΔV)',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${defect.deltaVDefectMv.toStringAsFixed(0)} mV',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL IR DROP',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${defect.totalIrDropMv.toStringAsFixed(0)} mV',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CLOCK POSITION',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        defect.orientationClock,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Polarity & Soil info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: defect.polarity.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  defect.polarity.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: defect.polarity.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Soil: ${defect.soilCondition} · Area: ~${defect.estimatedDefectAreaCm2} cm²',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Notes
          Text(
            defect.notes,
            style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            'Logged: ${DateFormat('dd MMM yyyy').format(defect.detectedDate)} · ${defect.surveyorName}',
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 10),

          // NACE Mitigation Action & Excavation Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Action: ${cat.naceRecommendation}',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: cat.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildExcavationStatusDropdown(defect),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExcavationStatusDropdown(DcvgDefectRecord defect) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: defect.excavationStatus.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: defect.excavationStatus.color.withValues(alpha: 0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ExcavationStatus>(
          value: defect.excavationStatus,
          isDense: true,
          dropdownColor: AppTheme.surfaceCard,
          icon: Icon(Icons.arrow_drop_down, color: defect.excavationStatus.color, size: 18),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: defect.excavationStatus.color,
          ),
          items: ExcavationStatus.values.map((status) {
            return DropdownMenuItem<ExcavationStatus>(
              value: status,
              child: Text(
                status.label,
                style: TextStyle(fontSize: 10, color: status.color, fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
          onChanged: (newStatus) {
            if (newStatus != null) {
              setState(() {
                defect.excavationStatus = newStatus;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyDefectsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 36, color: Color(0xFF4EDEA3)),
            SizedBox(height: 8),
            Text(
              'No Defect Matches Filter',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            SizedBox(height: 4),
            Text(
              'All coating sections in this category meet integrity criteria.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 3: ECDA TRIANGULATION & BELL-HOLE MATRIX
  // ============================================================================

  Widget _buildEcdaTriangulationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NACE SP0502 ECDA Flow Banner
          _buildEcdaWorkflowHeader(),
          const SizedBox(height: 16),

          // Triangulation Matrix: CIPS vs DCVG
          _buildTriangulationMatrixCard(),
          const SizedBox(height: 16),

          // Bell-Hole Direct Examination Tracker
          _buildBellHoleSection(),
        ],
      ),
    );
  }

  Widget _buildEcdaWorkflowHeader() {
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
              Icon(Icons.account_tree_rounded, size: 16, color: AppTheme.primaryLight),
              SizedBox(width: 8),
              Text(
                'NACE SP0502 External Corrosion Direct Assessment (ECDA)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '4-Step Pipeline Assessment: 1. Pre-Assessment → 2. Indirect Inspection (CIPS & DCVG) → 3. Direct Examination (Bell-Hole NDT) → 4. Post-Assessment Remnant Life.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildEcdaStepBadge('Step 1: Pre-Assess', true),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textMuted),
              _buildEcdaStepBadge('Step 2: CIPS + DCVG', true),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textMuted),
              _buildEcdaStepBadge('Step 3: Bell-Holes', true),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textMuted),
              _buildEcdaStepBadge('Step 4: Post-Assess', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEcdaStepBadge(String label, bool isDone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFF4EDEA3).withValues(alpha: 0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDone ? const Color(0xFF4EDEA3).withValues(alpha: 0.5) : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isDone ? const Color(0xFF4EDEA3) : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildTriangulationMatrixCard() {
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
            'CIPS vs DCVG Triangulation Ranking',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cross-referencing polarized instant-off potentials with surface gradient defects',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),

          // Triangulation rows
          _buildTriangulationRow(
            zone: 'Zone 1: Active Cell',
            cipsCondition: 'E_off > -850 mV (Under-protected)',
            dcvgCondition: 'DCVG Cat 4 (> 70% IR) or Cat 3',
            action: 'Immediate Bell-Hole Dig (Critical Risk)',
            color: const Color(0xFFEF4444),
            matchedDefect: 'DCVG-DF-03 @ KP 3+450 (E_off: -810 mV)',
          ),
          const SizedBox(height: 8),
          _buildTriangulationRow(
            zone: 'Zone 2: Protected Holiday',
            cipsCondition: 'E_off ≤ -850 mV (Compliant CP)',
            dcvgCondition: 'DCVG Cat 3 (35% - 70% IR)',
            action: 'Prioritized Excavation (CP shields for now)',
            color: const Color(0xFFFFB95F),
            matchedDefect: 'DCVG-DF-04 @ KP 6+900 (E_off: -835 mV, Decay > 100mV)',
          ),
          const SizedBox(height: 8),
          _buildTriangulationRow(
            zone: 'Zone 3: Low Risk Coating Flaw',
            cipsCondition: 'E_off ≤ -850 mV (Polarized)',
            dcvgCondition: 'DCVG Cat 1 or Cat 2 (< 35% IR)',
            action: 'Routine Monitoring at Next CIPS Cycle',
            color: const Color(0xFF4EDEA3),
            matchedDefect: 'DCVG-DF-01 @ KP 1+250, DF-02 @ KP 2+340',
          ),
        ],
      ),
    );
  }

  Widget _buildTriangulationRow({
    required String zone,
    required String cipsCondition,
    required String dcvgCondition,
    required String action,
    required Color color,
    required String matchedDefect,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                zone,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  action,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '• CIPS: $cipsCondition',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          Text(
            '• DCVG: $dcvgCondition',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Correlated: $matchedDefect',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildBellHoleSection() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bell-Hole Direct Examination Log (NDT)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              Text(
                'API 579 / ASME B31G',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Physical excavation, pit depth gauge, UT wall thickness & soil pH verification',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),

          Column(
            children: _bellHoleList.map((bh) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
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
                          '${bh.defectId} (${bh.chainageStr})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: bh.pitDepthMm > 0
                                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                : const Color(0xFF4EDEA3).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            bh.pitDepthMm > 0
                                ? 'Pit Depth: ${bh.pitDepthMm} mm (${bh.wallLossPercentage.toStringAsFixed(1)}% loss)'
                                : '0 mm Pit (No Metal Loss)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: bh.pitDepthMm > 0 ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Nominal WT: ${bh.nominalWallThicknessMm} mm',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Remaining: ${bh.remainingWallThicknessMm} mm',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Soil pH: ${bh.soilPh}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coating: ${bh.coatingCondition}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    if (bh.microbesDetectedSrb)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          '⚠️ SRB (Sulfate Reducing Bacteria) colonies confirmed in soil paste.',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Remediation: ${bh.actionTaken}',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: INTERACTIVE FIELD CALCULATORS (%IR & POLARIZATION DECAY)
  // ============================================================================

  Widget _buildEngineeringCalculatorsTab() {
    // Calculate %IR
    final calculatedPercentIr = _calcTotalIr > 0 ? (_calcDeltaV / _calcTotalIr) * 100.0 : 0.0;
    final calcCategory = DcvgDefectCategoryExt.fromPercentIr(calculatedPercentIr);

    // Calculate polarization decay
    final calculatedDecay = (_calcInstantOff - _calcNative).abs();
    final isDecayCompliant = calculatedDecay >= 100.0;
    final is850Compliant = _calcInstantOff <= -850.0 && _calcInstantOff >= -1200.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. DCVG %IR DEFECT SEVERITY CALCULATOR
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
                      'DCVG Defect %IR Calculator',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Text(
                        'NACE SP0207',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Calculates coating defect severity based on soil surface potential gradient vs total IR drop.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // Delta V Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Defect Gradient to Remote (ΔV):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    Text(
                      '${_calcDeltaV.toStringAsFixed(1)} mV',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
                    ),
                  ],
                ),
                Slider(
                  value: _calcDeltaV,
                  min: 5.0,
                  max: 300.0,
                  divisions: 59,
                  activeColor: AppTheme.primaryLight,
                  inactiveColor: AppTheme.border,
                  onChanged: (val) {
                    setState(() {
                      _calcDeltaV = val;
                      if (_calcDeltaV > _calcTotalIr) {
                        _calcTotalIr = _calcDeltaV;
                      }
                    });
                  },
                ),

                // Total IR Drop Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pipe-to-Soil IR Drop (Total IR):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    Text(
                      '${_calcTotalIr.toStringAsFixed(1)} mV',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.secondary),
                    ),
                  ],
                ),
                Slider(
                  value: _calcTotalIr,
                  min: 50.0,
                  max: 500.0,
                  divisions: 45,
                  activeColor: AppTheme.secondary,
                  inactiveColor: AppTheme.border,
                  onChanged: (val) {
                    setState(() {
                      _calcTotalIr = val;
                      if (_calcDeltaV > _calcTotalIr) {
                        _calcDeltaV = _calcTotalIr;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Result Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: calcCategory.color.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: calcCategory.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(calcCategory.icon, color: calcCategory.color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '%IR Defect: ${calculatedPercentIr.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: calcCategory.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${calcCategory.code} · ${calcCategory.title}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              calcCategory.naceRecommendation,
                              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, height: 1.3),
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
          const SizedBox(height: 16),

          // 2. NACE SP0169 100 mV POLARIZATION DECAY SOLVER
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
                      '100 mV Polarization Decay Evaluator',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Text(
                        'NACE SP0169 6.2.2.3.2',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Evaluates secondary cathodic polarization criterion when instant-off is less negative than -850 mV.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // Instant Off Potential Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Instant-Off Potential (E_off):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    Text(
                      '${_calcInstantOff.toStringAsFixed(0)} mV CSE',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4EDEA3)),
                    ),
                  ],
                ),
                Slider(
                  value: _calcInstantOff,
                  min: -1300.0,
                  max: -700.0,
                  divisions: 60,
                  activeColor: const Color(0xFF4EDEA3),
                  inactiveColor: AppTheme.border,
                  onChanged: (val) {
                    setState(() {
                      _calcInstantOff = val;
                    });
                  },
                ),

                // Native Potential Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Native / Depolarized Potential (E_native):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    Text(
                      '${_calcNative.toStringAsFixed(0)} mV CSE',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFFB95F)),
                    ),
                  ],
                ),
                Slider(
                  value: _calcNative,
                  min: -750.0,
                  max: -400.0,
                  divisions: 35,
                  activeColor: const Color(0xFFFFB95F),
                  inactiveColor: AppTheme.border,
                  onChanged: (val) {
                    setState(() {
                      _calcNative = val;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Polarization Verdict Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: is850Compliant || isDecayCompliant
                          ? const Color(0xFF4EDEA3).withValues(alpha: 0.6)
                          : const Color(0xFFEF4444).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            is850Compliant || isDecayCompliant
                                ? Icons.verified_user_rounded
                                : Icons.dangerous_rounded,
                            color: is850Compliant || isDecayCompliant
                                ? const Color(0xFF4EDEA3)
                                : const Color(0xFFEF4444),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Polarization Shift: ${calculatedDecay.toStringAsFixed(0)} mV',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDecayCompliant
                                        ? const Color(0xFF4EDEA3)
                                        : const Color(0xFFFFB95F),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  is850Compliant
                                      ? 'Complies with Primary -850 mV Polarized Criterion'
                                      : isDecayCompliant
                                          ? 'Complies with 100 mV Cathodic Polarization Decay Criterion'
                                          : 'NON-COMPLIANT: Requires CP current boost or coating repair',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: is850Compliant || isDecayCompliant
                                        ? const Color(0xFF4EDEA3)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: math.min(1.0, calculatedDecay / 100.0),
                        backgroundColor: AppTheme.surfaceCard,
                        color: isDecayCompliant ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. INTERRUPTER TIMING & PULSE WAVEFORM CONFIG
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
                  'GPS Interrupter Switching Waveform',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'High-speed synchronized switching eliminates inductive spikes and measures true polarized E_off.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // Timing selector buttons
                Row(
                  children: [
                    _buildCycleSelectorButton('0.8s ON / 0.2s OFF', 0.8, 0.2),
                    const SizedBox(width: 8),
                    _buildCycleSelectorButton('4.0s ON / 1.0s OFF', 4.0, 1.0),
                    const SizedBox(width: 8),
                    _buildCycleSelectorButton('3.0s ON / 1.0s OFF', 3.0, 1.0),
                  ],
                ),
                const SizedBox(height: 16),

                // Simulated pulse graphic
                Container(
                  height: 60,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: CustomPaint(
                    painter: _WaveformPainter(
                      onSec: _interrupterOnSeconds,
                      offSec: _interrupterOffSeconds,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'T_on (Current Injected)',
                      style: TextStyle(fontSize: 10, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'T_off (Sampled at +80ms)',
                      style: TextStyle(fontSize: 10, color: Color(0xFF4EDEA3), fontWeight: FontWeight.w600),
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

  Widget _buildCycleSelectorButton(String title, double onSec, double offSec) {
    final isSelected = _interrupterOnSeconds == onSec && _interrupterOffSeconds == offSec;

    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
          side: BorderSide(
            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onPressed: () {
          setState(() {
            _interrupterOnSeconds = onSec;
            _interrupterOffSeconds = offSec;
          });
        },
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 5: ECDA COMPLIANCE & AUDIT TRAIL
  // ============================================================================

  Widget _buildEcdaComplianceAuditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Certification Badge Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0284C7).withValues(alpha: 0.3),
                  const Color(0xFF162347),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ECDA Indirect Inspection Certificate',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Icon(Icons.verified_rounded, color: Color(0xFF4EDEA3), size: 24),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pipeline Corridor: Duliajan CGGS to Digboi Refinery (34.8 km, 18" API 5L X-65)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Inspection Scope: 100% CIPS trailing wire potential profile + synchronized pulsed DCVG holiday detection.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Lead Auditor: B. Gogoi (NACE CP-3 #49102)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    Text('Survey Date: 2026-09-30', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Standards compliance checklist
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
                  'Standard Specifications Satisfied',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                _buildComplianceCheckItem(
                  standard: 'NACE TM0497-2018',
                  desc: 'Measurement Techniques for Cathodic Protection Criteria on Underground Pipelines.',
                  isSatisfied: true,
                ),
                _buildComplianceCheckItem(
                  standard: 'NACE SP0207-2007',
                  desc: 'Performing Close-Interval Potential Surveys and DC Surface Potential Gradient Surveys.',
                  isSatisfied: true,
                ),
                _buildComplianceCheckItem(
                  standard: 'NACE SP0169-2013',
                  desc: 'Control of External Corrosion on Underground Piping (-850 mV instant-off / 100 mV decay).',
                  isSatisfied: true,
                ),
                _buildComplianceCheckItem(
                  standard: 'NACE SP0502-2010',
                  desc: 'Pipeline External Corrosion Direct Assessment (ECDA) Methodology.',
                  isSatisfied: true,
                ),
                _buildComplianceCheckItem(
                  standard: 'OISD-STD-141',
                  desc: 'Design and Inspection Requirements for Cross Country Liquid & Gas Hydrocarbon Pipelines.',
                  isSatisfied: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Survey Summary & Action Items
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
                  'Immediate Remedial Action Plan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                _buildActionItem(
                  tag: 'DIG-01',
                  title: 'Execute Bell-Hole at KP 3+450 (Cat 4 Holiday)',
                  desc: 'Under-protected CP depression (E_off: -810 mV) and %IR defect 85.3% in saline soil. Mandatory recoating with Canusa GTS-PE sleeve.',
                  isUrgent: true,
                ),
                _buildActionItem(
                  tag: 'DIG-02',
                  title: 'Investigate KP 6+900 Severe Coating Anomaly',
                  desc: 'Cat 3 defect (44.3% IR) located in swale waterlogged area. Verify CP polarization stability after heavy rainfall.',
                  isUrgent: false,
                ),
                _buildActionItem(
                  tag: 'CP-ADJ',
                  title: 'TRU-02 Current Density Re-Balancing',
                  desc: 'Increase TRU-02 current by 2.5 Amps to eliminate CP sag between KP 3+000 and KP 4+000.',
                  isUrgent: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceCheckItem({
    required String standard,
    required String desc,
    required bool isSatisfied,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSatisfied ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isSatisfied ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  standard,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required String tag,
    required String title,
    required String desc,
    required bool isUrgent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrgent ? const Color(0xFFEF4444).withValues(alpha: 0.6) : AppTheme.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isUrgent ? const Color(0xFFEF4444).withValues(alpha: 0.2) : AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isUrgent ? const Color(0xFFEF4444) : AppTheme.primaryLight,
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MODALS & DIALOGS (LOGGING & REPORT EXPORT)
  // ============================================================================

  void _showLogSurveyMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Record Field Measurement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select whether to log a CIPS trailing wire potential interval or a DCVG surface gradient defect.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.stacked_line_chart_rounded, color: AppTheme.primaryLight),
                  ),
                  title: const Text('Log CIPS Potential Interval', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('E_on, E_off, IR drop & 100 mV decay verification', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddCipsDialog();
                  },
                ),
                const Divider(color: AppTheme.border),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB95F).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grain_rounded, color: Color(0xFFFFB95F)),
                  ),
                  title: const Text('Log DCVG Coating Holiday', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Surface gradient ΔV, Total IR drop & %IR category classification', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddDcvgDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCipsDialog() {
    final kpController = TextEditingController(text: 'KP 12+100');
    final onController = TextEditingController(text: '-1220');
    final offController = TextEditingController(text: '-1010');
    final nativeController = TextEditingController(text: '-570');
    final landmarkController = TextEditingController(text: 'Refinery Gate Terminal');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text('Add CIPS Potential Point', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: kpController,
                  decoration: const InputDecoration(labelText: 'Chainage (KP)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: onController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'E_on Potential (mV vs CSE)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: offController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'E_off Polarized (mV vs CSE)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nativeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Native Potential (mV vs CSE)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: landmarkController,
                  decoration: const InputDecoration(labelText: 'Landmark / Terrain'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final onVal = double.tryParse(onController.text) ?? -1200.0;
                final offVal = double.tryParse(offController.text) ?? -1000.0;
                final natVal = double.tryParse(nativeController.text) ?? -570.0;
                final newPoint = CipsSurveyPoint(
                  id: 'CIPS-${(_cipsSurveyPoints.length + 1).toString().padLeft(3, '0')}',
                  chainageKm: 12.100,
                  chainageStr: kpController.text,
                  latitude: 27.3300,
                  longitude: 95.3720,
                  onPotentialMv: onVal,
                  instantOffMv: offVal,
                  nativePotentialMv: natVal,
                  polarizationDecayMv: (offVal - natVal).abs(),
                  soilResistivityOhmM: 45.0,
                  soilTerrain: 'Refinery Approach Soil',
                  landmark: landmarkController.text,
                  timestamp: DateTime.now(),
                );

                setState(() {
                  _cipsSurveyPoints.add(newPoint);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logged CIPS reading at ${newPoint.chainageStr} (${newPoint.instantOffMv.toStringAsFixed(0)} mV)'),
                    backgroundColor: AppTheme.surfaceContainerHigh,
                  ),
                );
              },
              child: const Text('Save Point'),
            ),
          ],
        );
      },
    );
  }

  void _showAddDcvgDialog() {
    final kpController = TextEditingController(text: 'KP 4+250');
    final deltaVController = TextEditingController(text: '45');
    final totalIrController = TextEditingController(text: '200');
    final notesController = TextEditingController(text: 'Roadside ditch anomaly');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text('Record DCVG Coating Defect', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: kpController,
                  decoration: const InputDecoration(labelText: 'Chainage (KP)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: deltaVController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Gradient to Remote (ΔV in mV)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: totalIrController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total IR Drop (mV)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes / Defect Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final dV = double.tryParse(deltaVController.text) ?? 30.0;
                final tIr = double.tryParse(totalIrController.text) ?? 200.0;
                final newDefect = DcvgDefectRecord(
                  id: 'DCVG-DF-${(_dcvgDefects.length + 1).toString().padLeft(2, '0')}',
                  chainageKm: 4.250,
                  chainageStr: kpController.text,
                  latitude: 27.3015,
                  longitude: 95.3390,
                  deltaVDefectMv: dV,
                  totalIrDropMv: tIr,
                  polarity: GradientPolarity.cathodic,
                  orientationClock: '12 o\'clock (Crown)',
                  estimatedDefectAreaCm2: 8.0,
                  soilCondition: 'Moist Clay',
                  detectedDate: DateTime.now(),
                  surveyorName: 'Field Inspector (NACE CP-2)',
                  excavationStatus: ExcavationStatus.pendingReview,
                  notes: notesController.text,
                );

                setState(() {
                  _dcvgDefects.add(newDefect);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logged defect ${newDefect.id}: %IR = ${newDefect.percentIr.toStringAsFixed(1)}% (${newDefect.category.code})'),
                    backgroundColor: AppTheme.surfaceContainerHigh,
                  ),
                );
              },
              child: const Text('Save Defect'),
            ),
          ],
        );
      },
    );
  }

  void _showExportReportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Row(
            children: [
              Icon(Icons.assessment_rounded, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text('Export ECDA Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate official NACE TM0497 / SP0207 Close Interval Potential Survey and DC Surface Potential Gradient Assessment Report.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildReportStatRow('Corridor Length:', '34.8 km (18" Gas)'),
                    _buildReportStatRow('CIPS Survey Points:', '${_cipsSurveyPoints.length} points logged'),
                    _buildReportStatRow('Total DCVG Holidays:', '${_dcvgDefects.length} detected'),
                    _buildReportStatRow('Cat 4 Critical Holidays:', '${_dcvgDefects.where((d) => d.category == DcvgDefectCategory.category4).length} requiring bell-hole'),
                    _buildReportStatRow('Interrupter Mode:', 'GPS 0.8s ON / 0.2s OFF'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Download PDF'),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ECDA Indirect Inspection Report (PDF) compiled and saved to downloads.'),
                    backgroundColor: AppTheme.surfaceContainerHigh,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HEADER BADGE & CUSTOM PAINTERS
// ============================================================================

class _ComplianceHeaderBadge extends StatelessWidget {
  const _ComplianceHeaderBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF4EDEA3).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF4EDEA3).withValues(alpha: 0.4)),
      ),
      child: const Text(
        'NACE ECDA',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4EDEA3),
        ),
      ),
    );
  }
}

/// Custom painter for GPS Interrupter ON/OFF square pulse waveform
class _WaveformPainter extends CustomPainter {
  final double onSec;
  final double offSec;

  const _WaveformPainter({required this.onSec, required this.offSec});

  @override
  void paint(Canvas canvas, Size size) {
    final onPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final offPaint = Paint()
      ..color = const Color(0xFF4EDEA3)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final baselinePaint = Paint()
      ..color = const Color(0xFF1E2E5C)
      ..strokeWidth = 1.0;

    final totalCycle = onSec + offSec;
    final onFraction = onSec / totalCycle;

    // Baseline axis
    canvas.drawLine(Offset(0, size.height - 6), Offset(size.width, size.height - 6), baselinePaint);

    // Two full cycles across width
    final cycleWidth = size.width / 2.0;

    for (int cycle = 0; cycle < 2; cycle++) {
      final startX = cycle * cycleWidth;
      final onEndX = startX + (cycleWidth * onFraction);
      final offEndX = startX + cycleWidth;

      // ON phase: elevated line
      canvas.drawLine(Offset(startX, 8), Offset(onEndX, 8), onPaint);

      // Transition edge downward
      canvas.drawLine(Offset(onEndX, 8), Offset(onEndX, size.height - 6), offPaint);

      // OFF phase: zero/depolarized baseline
      canvas.drawLine(Offset(onEndX, size.height - 6), Offset(offEndX, size.height - 6), offPaint);

      // Transition edge upward for next cycle
      if (cycle < 1) {
        canvas.drawLine(Offset(offEndX, size.height - 6), Offset(offEndX, 8), onPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.onSec != onSec || oldDelegate.offSec != offSec;
  }
}
