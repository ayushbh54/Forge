import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

// ============================================================================
// ENUMS & DOMAIN MODELS (ASME B31.8S / API 1160 / ASME PCC-2)
// ============================================================================

enum RiskTier {
  low,
  medium,
  high,
  critical,
}

extension RiskTierExt on RiskTier {
  String get label {
    switch (this) {
      case RiskTier.low:
        return 'Low Risk';
      case RiskTier.medium:
        return 'Medium Risk';
      case RiskTier.high:
        return 'High Risk';
      case RiskTier.critical:
        return 'Critical Risk';
    }
  }

  Color get color {
    switch (this) {
      case RiskTier.low:
        return const Color(0xFF4EDEA3); // Tertiary green
      case RiskTier.medium:
        return const Color(0xFFFFB95F); // Amber
      case RiskTier.high:
        return const Color(0xFFFB923C); // Deep Orange
      case RiskTier.critical:
        return const Color(0xFFEF4444); // Danger Red
    }
  }

  Color get bgTint {
    switch (this) {
      case RiskTier.low:
        return const Color(0x1F4EDEA3);
      case RiskTier.medium:
        return const Color(0x1FFFB95F);
      case RiskTier.high:
        return const Color(0x1FFB923C);
      case RiskTier.critical:
        return const Color(0x28EF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case RiskTier.low:
        return Icons.verified_user_rounded;
      case RiskTier.medium:
        return Icons.shield_outlined;
      case RiskTier.high:
        return Icons.warning_amber_rounded;
      case RiskTier.critical:
        return Icons.dangerous_rounded;
    }
  }

  String get actionRequired {
    switch (this) {
      case RiskTier.low:
        return 'Standard 10-Yr Re-assessment; routine CP surveillance.';
      case RiskTier.medium:
        return 'Biennial CIS & DCVG survey; enhance monitoring.';
      case RiskTier.high:
        return 'Scheduled dig & NDT validation within 12 months.';
      case RiskTier.critical:
        return 'Immediate MAOP derating or 30-day sleeve repair.';
    }
  }
}

enum ThreatCategory {
  externalCorrosion,
  internalCorrosion,
  geotechnicalScour,
  thirdPartyDamage,
  cyclicFatigue,
}

extension ThreatCategoryExt on ThreatCategory {
  String get label {
    switch (this) {
      case ThreatCategory.externalCorrosion:
        return 'External Corrosion / Disbondment';
      case ThreatCategory.internalCorrosion:
        return 'Internal / MIC Pitting';
      case ThreatCategory.geotechnicalScour:
        return 'Geotechnical / River Scour';
      case ThreatCategory.thirdPartyDamage:
        return 'Third-Party Encroachment / Dent';
      case ThreatCategory.cyclicFatigue:
        return 'Pressure Cycling / Weld Flaw';
    }
  }

  IconData get icon {
    switch (this) {
      case ThreatCategory.externalCorrosion:
        return Icons.shield_rounded;
      case ThreatCategory.internalCorrosion:
        return Icons.water_drop_rounded;
      case ThreatCategory.geotechnicalScour:
        return Icons.terrain_rounded;
      case ThreatCategory.thirdPartyDamage:
        return Icons.warning_amber_rounded;
      case ThreatCategory.cyclicFatigue:
        return Icons.repeat_rounded;
    }
  }
}

class PipelineSegment {
  final String id;
  final String name;
  final double startKm;
  final double endKm;
  final double wallThicknessMm;
  final double smysMpa;
  final double soilResistivityOhmCm;
  final double cpPotentialMv;
  final double maxDepthPercent; // d/t in %
  final double defectLengthMm;
  final double activeGrowthRateMmYr;
  final ThreatCategory primaryThreat;
  final String classLocation;
  final bool isHca;
  final int pof; // 1 to 5
  final int cof; // 1 to 5
  final String mitigationPlan;

  const PipelineSegment({
    required this.id,
    required this.name,
    required this.startKm,
    required this.endKm,
    required this.wallThicknessMm,
    required this.smysMpa,
    required this.soilResistivityOhmCm,
    required this.cpPotentialMv,
    required this.maxDepthPercent,
    required this.defectLengthMm,
    required this.activeGrowthRateMmYr,
    required this.primaryThreat,
    required this.classLocation,
    required this.isHca,
    required this.pof,
    required this.cof,
    required this.mitigationPlan,
  });

  int get riskScore => pof * cof;

  RiskTier get riskTier {
    final score = riskScore;
    if (score >= 16 || (pof >= 4 && cof >= 4)) return RiskTier.critical;
    if (score >= 10) return RiskTier.high;
    if (score >= 5) return RiskTier.medium;
    return RiskTier.low;
  }

  double get lengthKm => endKm - startKm;

  String get chainageSpan =>
      'Ch ${startKm.toStringAsFixed(1)}+000 - Ch ${endKm.toStringAsFixed(1)}+000';

  // Remnant life to 80% limit in years
  double get remnantLifeYears {
    final currentDepthMm = (maxDepthPercent / 100.0) * wallThicknessMm;
    final criticalDepthMm = 0.80 * wallThicknessMm;
    final remainingMarginMm = criticalDepthMm - currentDepthMm;
    if (remainingMarginMm <= 0) return 0.0;
    if (activeGrowthRateMmYr <= 0.001) return 20.0;
    return remainingMarginMm / activeGrowthRateMmYr;
  }

  // ASME B31.8S Recommended Re-assessment Interval: Half-life rule
  double get recommendedReassessmentYears {
    final halfLife = remnantLifeYears / 2.0;
    final statutoryCap = isHca ? 5.0 : 10.0;
    return math.max(0.5, math.min(halfLife, statutoryCap));
  }

  // Quick Modified B31G ERF at nominal MAOP = 98.0 bar, OD = 457.2 mm
  double get modB31gErf {
    const double od = 457.2;
    const double maop = 98.0;
    final double depthRatio = (maxDepthPercent / 100.0).clamp(0.01, 0.95);
    final double z = (defectLengthMm * defectLengthMm) / (od * wallThicknessMm);
    final double folias = z <= 50.0
        ? math.sqrt(1.0 + 0.6275 * z - 0.003375 * z * z)
        : (0.032 * z + 3.3);
    final double sflow = smysMpa + 68.95;
    final double num = 1.0 - 0.85 * depthRatio;
    final double den = (1.0 - (0.85 * depthRatio) / folias).clamp(0.01, 10.0);
    final double sigmaFail = num > 0 ? sflow * (num / den) : 0.0;
    final double burstBar = ((2.0 * wallThicknessMm * sigmaFail) / od) * 10.0;
    final double designFactor = classLocation.contains('3')
        ? 0.50
        : (classLocation.contains('2') ? 0.60 : 0.72);
    final double pSafe = math.min(maop, burstBar * designFactor);
    if (pSafe <= 0.01) return 9.99;
    return maop / pSafe;
  }
}

enum DigPriority {
  immediate,
  scheduled,
  oneYear,
  monitored,
}

extension DigPriorityExt on DigPriority {
  String get label {
    switch (this) {
      case DigPriority.immediate:
        return 'Immediate (30-Day)';
      case DigPriority.scheduled:
        return 'Scheduled (60-90 Day)';
      case DigPriority.oneYear:
        return '1-Year Condition';
      case DigPriority.monitored:
        return 'Monitored Condition';
    }
  }

  Color get color {
    switch (this) {
      case DigPriority.immediate:
        return const Color(0xFFEF4444);
      case DigPriority.scheduled:
        return const Color(0xFFFB923C);
      case DigPriority.oneYear:
        return const Color(0xFFFFB95F);
      case DigPriority.monitored:
        return const Color(0xFF4EDEA3);
    }
  }
}

enum RepairMethodology {
  typeBSteelSleeve,
  compositeWrap,
  typeASteelSleeve,
  recoatAndHolidayTest,
}

extension RepairMethodologyExt on RepairMethodology {
  String get name {
    switch (this) {
      case RepairMethodology.typeBSteelSleeve:
        return 'Type B Pressure-Tight Steel Sleeve';
      case RepairMethodology.compositeWrap:
        return 'Composite Wrap Sleeve (Clock Spring / Carbon 8-Ply)';
      case RepairMethodology.typeASteelSleeve:
        return 'Type A Mechanical Reinforcing Sleeve';
      case RepairMethodology.recoatAndHolidayTest:
        return 'Recoat (Visco-Elastic / HSS) + CP Coupon';
    }
  }

  String get standardCode {
    switch (this) {
      case RepairMethodology.typeBSteelSleeve:
        return 'ASME PCC-2 Art 4.2 / API 1160 §8.4';
      case RepairMethodology.compositeWrap:
        return 'ASME PCC-2 Art 4.1 / ISO 24817';
      case RepairMethodology.typeASteelSleeve:
        return 'ASME PCC-2 Art 4.1 / OISD-141 §9';
      case RepairMethodology.recoatAndHolidayTest:
        return 'NACE SP0169 / ISO 21809';
    }
  }

  String get description {
    switch (this) {
      case RepairMethodology.typeBSteelSleeve:
        return 'Full-encirclement steel sleeve with full-penetration longitudinal welds and circumferential fillet seals. Restores 100% MAOP on defects up to 80% wall loss.';
      case RepairMethodology.compositeWrap:
        return 'High-tensile carbon/epoxy composite matrix installed cold without hot-work shutdown. Restores hoop strength for non-leaking external/internal anomalies.';
      case RepairMethodology.typeASteelSleeve:
        return 'Reinforcing non-welded ends with load-transfer structural epoxy grout filler. Prevents bulging under cyclic operating stress.';
      case RepairMethodology.recoatAndHolidayTest:
        return 'Surface blast SA 2.5, visco-elastic corrosion protection wrap, outer mechanical shield, high-voltage holiday spark test, and zinc coupon.';
    }
  }

  IconData get icon {
    switch (this) {
      case RepairMethodology.typeBSteelSleeve:
        return Icons.security_rounded;
      case RepairMethodology.compositeWrap:
        return Icons.layers_rounded;
      case RepairMethodology.typeASteelSleeve:
        return Icons.fit_screen_rounded;
      case RepairMethodology.recoatAndHolidayTest:
        return Icons.brush_rounded;
    }
  }
}

enum DigStatus {
  planned,
  rowCleared,
  excavated,
  inspected,
  repaired,
  backfilled,
}

extension DigStatusExt on DigStatus {
  String get label {
    switch (this) {
      case DigStatus.planned:
        return 'Planned & RoW Notice';
      case DigStatus.rowCleared:
        return 'RoW Cleared';
      case DigStatus.excavated:
        return 'Bell-Hole Excavated';
      case DigStatus.inspected:
        return 'NDT UT Mapped';
      case DigStatus.repaired:
        return 'Sleeve Installed';
      case DigStatus.backfilled:
        return 'Passed & Backfilled';
    }
  }

  int get stepIndex {
    switch (this) {
      case DigStatus.planned:
        return 0;
      case DigStatus.rowCleared:
        return 1;
      case DigStatus.excavated:
        return 2;
      case DigStatus.inspected:
        return 3;
      case DigStatus.repaired:
        return 4;
      case DigStatus.backfilled:
        return 5;
    }
  }

  Color get color {
    switch (this) {
      case DigStatus.planned:
        return const Color(0xFF94A3B8);
      case DigStatus.rowCleared:
        return const Color(0xFF38BDF8);
      case DigStatus.excavated:
        return const Color(0xFFFFB95F);
      case DigStatus.inspected:
        return const Color(0xFFA78BFA);
      case DigStatus.repaired:
        return const Color(0xFF0284C7);
      case DigStatus.backfilled:
        return const Color(0xFF4EDEA3);
    }
  }
}

class DigWorkOrder {
  final String id;
  final String segmentId;
  final String chainageStr;
  final String locationName;
  final double gpsLat;
  final double gpsLong;
  final double defectDepthPercent;
  final double defectLengthMm;
  final double defectWidthMm;
  final String clockPosition;
  final double erf;
  final DigPriority priority;
  final RepairMethodology repairMethod;
  final String rowClearance;
  final String assignedCrew;
  DigStatus status;
  final DateTime targetDate;
  final String fieldNotes;

  DigWorkOrder({
    required this.id,
    required this.segmentId,
    required this.chainageStr,
    required this.locationName,
    required this.gpsLat,
    required this.gpsLong,
    required this.defectDepthPercent,
    required this.defectLengthMm,
    required this.defectWidthMm,
    required this.clockPosition,
    required this.erf,
    required this.priority,
    required this.repairMethod,
    required this.rowClearance,
    required this.assignedCrew,
    required this.status,
    required this.targetDate,
    required this.fieldNotes,
  });
}

// ============================================================================
// MAIN PIMS RISK & REMNANT LIFE SCREEN
// ============================================================================

class PimsRiskScreen extends StatefulWidget {
  const PimsRiskScreen({super.key});

  @override
  State<PimsRiskScreen> createState() => _PimsRiskScreenState();
}

class _PimsRiskScreenState extends State<PimsRiskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --------------------------------------------------------------------------
  // Tab 1 (5x5 Matrix) State
  // --------------------------------------------------------------------------
  int? _selectedMatrixPof;
  int? _selectedMatrixCof;
  RiskTier? _selectedTierFilter;
  bool _hcaOnlyFilter = false;
  ThreatCategory? _threatFilter;
  final TextEditingController _matrixSearchCtrl = TextEditingController();
  String _matrixSearchQuery = '';

  // --------------------------------------------------------------------------
  // Tab 2 (Remnant Strength Calculator) State
  // --------------------------------------------------------------------------
  double _calcOd = 457.2; // 18" Pipe Outer Diameter (mm)
  double _calcWt = 9.52; // Nominal Wall Thickness (mm)
  final double _calcSmys = 485.0; // API 5L X70 SMYS (MPa)
  double _calcDesignFactor = 0.72; // Class 1 Design Factor
  final double _calcMaop = 98.0; // Design MAOP (bar)
  double _calcDefectLength = 120.0; // Defect Length L (mm)
  double _calcDefectDepth = 5.20; // Defect Depth d (mm)
  final double _calcDefectWidth = 42.0; // Defect Width W (mm)
  final bool _calcIsInternal = false;

  // --------------------------------------------------------------------------
  // Tab 3 (Remnant Life & Re-assessment) State
  // --------------------------------------------------------------------------
  late PipelineSegment _selectedTrajectorySegment;
  double _activeCgrSlider = 0.28; // Active Corrosion Growth Rate (mm/year)
  final double _criticalDepthThresholdPercent = 80.0; // ASME Limit 80%

  // --------------------------------------------------------------------------
  // Tab 4 (Critical Dig Repair Schedule) State
  // --------------------------------------------------------------------------
  DigPriority? _digPriorityFilter;
  final TextEditingController _digSearchCtrl = TextEditingController();
  String _digSearchQuery = '';
  late List<DigWorkOrder> _digWorkOrders;

  // --------------------------------------------------------------------------
  // 24 SEGMENTS DATASET (Duliajan to Numaligarh 144km Pipeline)
  // --------------------------------------------------------------------------
  static const List<PipelineSegment> _all24Segments = [
    PipelineSegment(
      id: 'SEG-01',
      name: 'Duliajan Dispatch Terminal to Tipling',
      startKm: 0.0,
      endKm: 6.0,
      wallThicknessMm: 11.91,
      smysMpa: 485.0,
      soilResistivityOhmCm: 2800,
      cpPotentialMv: -1050,
      maxDepthPercent: 22.0,
      defectLengthMm: 45.0,
      activeGrowthRateMmYr: 0.12,
      primaryThreat: ThreatCategory.externalCorrosion,
      classLocation: 'Class 2',
      isHca: true,
      pof: 2,
      cof: 4,
      mitigationPlan: 'Biennial Close-Interval Survey (CIS) & CP tuning.',
    ),
    PipelineSegment(
      id: 'SEG-02',
      name: 'Tipling River Alluvial Reach',
      startKm: 6.0,
      endKm: 12.0,
      wallThicknessMm: 9.52,
      smysMpa: 485.0,
      soilResistivityOhmCm: 3200,
      cpPotentialMv: -980,
      maxDepthPercent: 18.0,
      defectLengthMm: 35.0,
      activeGrowthRateMmYr: 0.10,
      primaryThreat: ThreatCategory.geotechnicalScour,
      classLocation: 'Class 1',
      isHca: false,
      pof: 1,
      cof: 2,
      mitigationPlan: 'River bed echo-sounder scour survey post-monsoon.',
    ),
    PipelineSegment(
      id: 'SEG-03',
      name: 'Tengakhat Lowland & Tea Estate',
      startKm: 12.0,
      endKm: 18.0,
      wallThicknessMm: 9.52,
      smysMpa: 485.0,
      soilResistivityOhmCm: 1650,
      cpPotentialMv: -890,
      maxDepthPercent: 46.0,
      defectLengthMm: 65.0,
      activeGrowthRateMmYr: 0.26,
      primaryThreat: ThreatCategory.internalCorrosion,
      classLocation: 'Class 2',
      isHca: false,
      pof: 3,
      cof: 3,
      mitigationPlan: 'Biocide batching & coupon corrosion rate validation.',
    ),
    PipelineSegment(
      id: 'SEG-04',
      name: 'Naharkatia Station VS-01 Junction',
      startKm: 18.0,
      endKm: 24.0,
      wallThicknessMm: 11.91,
      smysMpa: 485.0,
      soilResistivityOhmCm: 2400,
      cpPotentialMv: -940,
      maxDepthPercent: 35.0,
      defectLengthMm: 50.0,
      activeGrowthRateMmYr: 0.18,
      primaryThreat: ThreatCategory.cyclicFatigue,
      classLocation: 'Class 3',
      isHca: true,
      pof: 2,
      cof: 4,
      mitigationPlan: 'Pressure pulsation dampening & automated ESDV testing.',
    ),
    PipelineSegment(
      id: 'SEG-05',
      name: 'Naharkatia Outskirts to Joypur',
      startKm: 24.0,
      endKm: 30.0,
      wallThicknessMm: 9.52,
      smysMpa: 485.0,
      soilResistivityOhmCm: 1900,
      cpPotentialMv: -910,
      maxDepthPercent: 29.0,
      defectLengthMm: 40.0,
      activeGrowthRateMmYr: 0.15,
      primaryThreat: ThreatCategory.thirdPartyDamage,
      classLocation: 'Class 2',
      isHca: false,
      pof: 2,
      cof: 3,
      mitigationPlan: 'Drone aerial surveillance & boundary marker renewal.',
    ),
    PipelineSegment(
      id: 'SEG-06',
      name: 'Joypur Rainforest Eco-Sensitive Corridor',
      startKm: 30.0,
      endKm: 36.0,
      wallThicknessMm: 11.91,
      smysMpa: 485.0,
      soilResistivityOhmCm: 2100,
      cpPotentialMv: -960,
      maxDepthPercent: 24.0,
      defectLengthMm: 42.0,
      activeGrowthRateMmYr: 0.14,
      primaryThreat: ThreatCategory.externalCorrosion,
      classLocation: 'Class 1',
      isHca: true,
      pof: 2,
      cof: 4,
      mitigationPlan: 'Fibre optic acoustic LDS leak monitoring.',
    ),
    PipelineSegment(
      id: 'SEG-07',
      name: 'Burhi Dihing River Crossing HDD',
      startKm: 36.0,
      endKm: 42.0,
      wallThicknessMm: 14.27,
      smysMpa: 485.0,
      soilResistivityOhmCm: 1150,
      cpPotentialMv: -810, // Under-protected!
      maxDepthPercent: 68.0, // High corrosion!
      defectLengthMm: 140.0,
      activeGrowthRateMmYr: 0.38,
      primaryThreat: ThreatCategory.externalCorrosion,
      classLocation: 'Class 3',
      isHca: true,
      pof: 5,
      cof: 5,
      mitigationPlan:
          'CRITICAL: Bell-hole dewatering & Type B Steel Encirclement Sleeve.',
    ),
    PipelineSegment(
      id: 'SEG-08',
      name: 'Khowang North Agrarian Reach',
      startKm: 42.0,
      endKm: 48.0,
      wallThicknessMm: 9.52,
      smysMpa: 485.0,
      soilResistivityOhmCm: 3400,
      cpPotentialMv: -990,
      maxDepthPercent: 15.0,
      defectLengthMm: 28.0,
      activeGrowthRateMmYr: 0.08,
      primaryThreat: ThreatCategory.thirdPartyDamage,
      classLocation: 'Class 1',
      isHca: false,
      pof: 1,
      cof: 1,
      mitigationPlan: 'Routine agricultural RoW depth-of-cover verification.',
    ),
    PipelineSegment(
      id: 'SEG-09',
      name: 'Khowang South to VS-02 Intermediate',
      startKm: 48.0,
      endKm: 54.0,
      wallThicknessMm: 9.52,
      smysMpa: 485.0,
      soilResistivityOhmCm: 3600,
      cpPotentialMv: -1020,
      maxDepthPercent: 12.0,
      defectLengthMm: 25.0,
      activeGrowthRateMmYr: 0.07,
      primaryThreat: ThreatCategory.externalCorrosion,
      classLocation: 'Class 1',
      isHca: false,
      pof: 1,
      cof: 1,
      mitigationPlan: 'Standard 10-year ILI baseline re-assessment.',
    ),
    PipelineSegment(
      id: 'SEG-10',
      name: 'Moran Junction Approach Corridor',
      startKm: 54.0,
      endKm: 60.0,
      wallThicknessMm: 9.52,
      smysMpa: 485.0,
      soilResistivityOhmCm: 2200,
      cpPotentialMv: -930,
      maxDepthPercent: 31.0,
      defectLengthMm: 48.0,
      activeGrowthRateMmYr: 0.16,
      primaryThreat: ThreatCategory.thirdPartyDamage,
      classLocation: 'Class 2',
      isHca: false,
      pof: 2,
      cof: 2,
      mitigationPlan: 'Public liaison and local road construction coordination.',
    ),
    PipelineSegment(
      id: 'SEG-11',
      name: 'Moran Oilfield & VS-03 Pumping Link',
      startKm: 60.0,
      endKm: 66.0,
      wallThicknessMm: 11.91,
      smysMpa: 485.0,
      soilResistivityOhmCm: 1350,
      cpPotentialMv: -860,
      maxDepthPercent: 61.0,
      defectLengthMm: 110.0,
      activeGrowthRateMmYr: 0.34,
      primaryThreat: ThreatCategory.internalCorrosion,
      classLocation: 'Class 3',
      isHca: true,
      pof: 4,
      cof: 4,
      mitigationPlan:
          'PRIORITY: Type B pressure sleeve & continuous H2S scavengers.',
    ),
    PipelineSegment(
      id: 'SEG-12',
      name: 'Moran West to Demow River Basin',
      startKm: 66.0,
      endKm: 72.0,
      wallThicknessMm: 9.52,
      smysMpa: 485.0,
      soilResistivityOhmCm: 1800,
      cpPotentialMv: -905,
      maxDepthPercent: 38.0,
      defectLengthMm: 55.0,
      activeGrowthRateMmYr: 0.22,
      primaryThreat: ThreatCategory.geotechnicalScour,
      classLocation: 'Class 2',
      isHca: false,
      pof: 3,
      cof: 2,
      mitigationPlan: 'Gabion mattress bank reinforcement & CP test post.',
    ),
    PipelineSegment(
      id: 'SEG-13',
      name: 'Demow Cased Highway Crossing (NH-37)',
      startKm: 72.0,
      endKm: 78.0,
      wallThicknessMm: 11.91,
      smysMpa: 485.0,
      soilResistivityOhmCm: 1700,
      cpPotentialMv: -880,
      maxDepthPercent: 44.0,
      defectLengthMm: 72.0,
      activeGrowthRateMmYr: 0.24,
      primaryThreat: ThreatCategory.externalCorrosion,
      classLocation: 'Class 2',
      isHca: false,
      pof: 3,
      cof: 3,
      mitigationPlan: 'Casing short-circuit DCVG test & wax casing filler.',
    ),
    PipelineSegment(
      id: 'SEG-14',
      name: 'Sibsagar Town Bypass & VS-04',
      startKm: 78.0,
      endKm: 84.0,
      wallThicknessMm: 11.91,
      smysMpa: 485.0,
      soilResistivityOhmCm: 1400,
      cpPotentialMv: -920,
      maxDepthPercent: 54.0,
      defectLengthMm: 95.0,
      activeGrowthRateMmYr: 0.31,
      primaryThreat: ThreatCategory.thirdPartyDamage,
      classLocation: 'Class 3',
      isHca: true,
      pof: 4,
      cof: 4,
      mitigationPlan: 'Composite Wrap Sleeve installation & high-impact concrete slab.',
    ),
    PipelineSegment(
      id: 'SEG-15',
      name: 'Sibsagar Heritage Canal & Wet Zone',
      startKm: 84.0,
      endKm: 90.0,
      wallThicknessMm: 9.52,
      smysMpa: 485.0,
      soilResistivityOhmCm: 2500,
      cpPotentialMv: -950,
      maxDepthPercent: 32.0,
      defectLengthMm: 44.0,
      activeGrowthRateMmYr: 0.17,
      primaryThreat: ThreatCategory.externalCorrosion,
      classLocation: 'Class 2',
      isHca: true,
      pof: 2,
      cof: 4,
      mitigationPlan: 'Quarterly archaeological site walkdowns & CP validation.',
    ),
    PipelineSegment(
      id: 'SEG-16',
      name: 'Dikhow River Floodplain',
      startKm: 90.0,
      endKm: 96.0,
      wallThicknessMm: 9.52,
      smysMpa: 485.0,
      soilResistivityOhmCm: 1600,
      cpPotentialMv: -890,
      maxDepthPercent: 40.0,
      defectLengthMm: 62.0,
      activeGrowthRateMmYr: 0.25,
      primaryThreat: ThreatCategory.geotechnicalScour,
      classLocation: 'Class 2',
      isHca: false,
      pof: 3,
      cof: 3,
      mitigationPlan: 'Sonar bathymetric silt inspection and Riprap placement.',
    ),
    PipelineSegment(
      id: 'SEG-17',
      name: 'Gaurisagar Rural Reach to VS-05',
      startKm: 96.0,
      endKm: 102.0,
      wallThicknessMm: 9.52,
      smysMpa: 485.0,
      soilResistivityOhmCm: 3500,
      cpPotentialMv: -1010,
      maxDepthPercent: 16.0,
      defectLengthMm: 30.0,
      activeGrowthRateMmYr: 0.09,
      primaryThreat: ThreatCategory.externalCorrosion,
      classLocation: 'Class 1',
      isHca: false,
      pof: 1,
      cof: 2,
      mitigationPlan: 'Routine CP monitoring at test stations every 6 months.',
    ),
    PipelineSegment(
      id: 'SEG-18',
      name: 'Jhanji River Crossing Section',
      startKm: 102.0,
      endKm: 108.0,
      wallThicknessMm: 11.91,
      smysMpa: 485.0,
      soilResistivityOhmCm: 2300,
      cpPotentialMv: -940,
      maxDepthPercent: 28.0,
      defectLengthMm: 45.0,
      activeGrowthRateMmYr: 0.15,
      primaryThreat: ThreatCategory.geotechnicalScour,
      classLocation: 'Class 2',
      isHca: false,
      pof: 2,
      cof: 3,
      mitigationPlan: 'Annual bridge pier and riverbed elevation sounding.',
    ),
    PipelineSegment(
      id: 'SEG-19',
      name: 'Teok Tea Estate & Railway Line',
      startKm: 108.0,
      endKm: 114.0,
      wallThicknessMm: 11.91,
      smysMpa: 485.0,
      soilResistivityOhmCm: 1550,
      cpPotentialMv: -870, // AC traction interference!
      maxDepthPercent: 49.0,
      defectLengthMm: 85.0,
      activeGrowthRateMmYr: 0.29,
      primaryThreat: ThreatCategory.cyclicFatigue,
      classLocation: 'Class 3',
      isHca: true,
      pof: 4,
      cof: 3,
      mitigationPlan:
          'AC Solid-State Decoupler (SSD) & Type B Steel Sleeve scheduled.',
    ),
    PipelineSegment(
      id: 'SEG-20',
      name: 'Jorhat Outskirts & VS-06 Station',
      startKm: 114.0,
      endKm: 120.0,
      wallThicknessMm: 11.91,
      smysMpa: 485.0,
      soilResistivityOhmCm: 2100,
      cpPotentialMv: -920,
      maxDepthPercent: 37.0,
      defectLengthMm: 58.0,
      activeGrowthRateMmYr: 0.20,
      primaryThreat: ThreatCategory.thirdPartyDamage,
      classLocation: 'Class 3',
      isHca: true,
      pof: 3,
      cof: 4,
      mitigationPlan: 'Optical fiber perimeter sensing & 24/7 patrol squad.',
    ),
    PipelineSegment(
      id: 'SEG-21',
      name: 'Bhogdoi River Alluvial Crossing',
      startKm: 120.0,
      endKm: 126.0,
      wallThicknessMm: 9.52,
      smysMpa: 485.0,
      soilResistivityOhmCm: 2600,
      cpPotentialMv: -960,
      maxDepthPercent: 26.0,
      defectLengthMm: 39.0,
      activeGrowthRateMmYr: 0.13,
      primaryThreat: ThreatCategory.geotechnicalScour,
      classLocation: 'Class 2',
      isHca: false,
      pof: 2,
      cof: 3,
      mitigationPlan: 'River revetment inspection and underwater dive check.',
    ),
    PipelineSegment(
      id: 'SEG-22',
      name: 'Dergaon Agrarian Reach to VS-07',
      startKm: 126.0,
      endKm: 132.0,
      wallThicknessMm: 9.52,
      smysMpa: 485.0,
      soilResistivityOhmCm: 3700,
      cpPotentialMv: -1030,
      maxDepthPercent: 14.0,
      defectLengthMm: 24.0,
      activeGrowthRateMmYr: 0.08,
      primaryThreat: ThreatCategory.externalCorrosion,
      classLocation: 'Class 1',
      isHca: false,
      pof: 1,
      cof: 1,
      mitigationPlan: 'Routine cathodic potential logging & zero dig priority.',
    ),
    PipelineSegment(
      id: 'SEG-23',
      name: 'Kakodonga River Crossing Zone',
      startKm: 132.0,
      endKm: 138.0,
      wallThicknessMm: 9.52,
      smysMpa: 485.0,
      soilResistivityOhmCm: 2200,
      cpPotentialMv: -930,
      maxDepthPercent: 33.0,
      defectLengthMm: 46.0,
      activeGrowthRateMmYr: 0.17,
      primaryThreat: ThreatCategory.geotechnicalScour,
      classLocation: 'Class 2',
      isHca: false,
      pof: 2,
      cof: 3,
      mitigationPlan: 'Reinforced concrete weighting collar stability review.',
    ),
    PipelineSegment(
      id: 'SEG-24',
      name: 'Numaligarh Refinery Terminal Approach',
      startKm: 138.0,
      endKm: 144.0,
      wallThicknessMm: 11.91,
      smysMpa: 485.0,
      soilResistivityOhmCm: 1850,
      cpPotentialMv: -980,
      maxDepthPercent: 41.0,
      defectLengthMm: 68.0,
      activeGrowthRateMmYr: 0.23,
      primaryThreat: ThreatCategory.internalCorrosion,
      classLocation: 'Class 4',
      isHca: true,
      pof: 3,
      cof: 5,
      mitigationPlan:
          'Refinery battery limit ESDV interlocking & Composite Sleeve.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedTrajectorySegment = _all24Segments[6]; // SEG-07 as default

    // Initialize Dig Work Orders
    _digWorkOrders = [
      DigWorkOrder(
        id: 'DIG-2026-001',
        segmentId: 'SEG-07',
        chainageStr: 'Ch 38+420',
        locationName: 'Burhi Dihing River North Bank Approach',
        gpsLat: 27.2841,
        gpsLong: 95.3190,
        defectDepthPercent: 68.0,
        defectLengthMm: 140.0,
        defectWidthMm: 45.0,
        clockPosition: '6:00 (Bottom of pipe)',
        erf: 1.14,
        priority: DigPriority.immediate,
        repairMethod: RepairMethodology.typeBSteelSleeve,
        rowClearance: 'Forest & Water Resources NOC Granted (No. FR/2026/088)',
        assignedCrew: 'Integrity Gang Alpha (Lead: Eng. B. Borah)',
        status: DigStatus.excavated,
        targetDate: DateTime.now().add(const Duration(days: 14)),
        fieldNotes:
            'Bell-hole dewatering pumps running 24/7. High groundwater table. Heavy-duty shoring installed.',
      ),
      DigWorkOrder(
        id: 'DIG-2026-002',
        segmentId: 'SEG-14',
        chainageStr: 'Ch 78+450',
        locationName: 'Sibsagar Town Bypass (Old ASTC Yard)',
        gpsLat: 26.9826,
        gpsLong: 94.6311,
        defectDepthPercent: 54.0,
        defectLengthMm: 95.0,
        defectWidthMm: 38.0,
        clockPosition: '4:30 (External Pitting)',
        erf: 1.05,
        priority: DigPriority.scheduled,
        repairMethod: RepairMethodology.compositeWrap,
        rowClearance: 'PWD Road Encroachment Permit Active',
        assignedCrew: 'Composite Specialized Crew Delta (Lead: Tech. R. Saikia)',
        status: DigStatus.rowCleared,
        targetDate: DateTime.now().add(const Duration(days: 35)),
        fieldNotes:
            'Class 3 HCA zone. Cold installation specified to avoid refinery feeder hot-work shutdown.',
      ),
      DigWorkOrder(
        id: 'DIG-2026-003',
        segmentId: 'SEG-11',
        chainageStr: 'Ch 62+100',
        locationName: 'Moran Oilfield Pumping Tie-in',
        gpsLat: 27.1850,
        gpsLong: 94.9250,
        defectDepthPercent: 61.0,
        defectLengthMm: 110.0,
        defectWidthMm: 52.0,
        clockPosition: '12:00 (Vapor Pocket MIC)',
        erf: 1.09,
        priority: DigPriority.immediate,
        repairMethod: RepairMethodology.typeBSteelSleeve,
        rowClearance: 'OIL Field Operations RoW Clearance Confirmed',
        assignedCrew: 'Integrity Gang Alpha (Lead: Eng. B. Borah)',
        status: DigStatus.inspected,
        targetDate: DateTime.now().add(const Duration(days: 21)),
        fieldNotes:
            'Ultrasonic Phased Array grid scan verified 61% depth. Type B split sleeve staged on site.',
      ),
      DigWorkOrder(
        id: 'DIG-2026-004',
        segmentId: 'SEG-19',
        chainageStr: 'Ch 111+200',
        locationName: 'Teok Railway Crossing (NFR Track 4)',
        gpsLat: 26.5180,
        gpsLong: 93.9720,
        defectDepthPercent: 49.0,
        defectLengthMm: 85.0,
        defectWidthMm: 35.0,
        clockPosition: '3:00 (AC Induced Pitting)',
        erf: 0.99,
        priority: DigPriority.scheduled,
        repairMethod: RepairMethodology.typeBSteelSleeve,
        rowClearance: 'Northeast Frontier Railway Line-Block NOC Approved',
        assignedCrew: 'Railway Crossing Specialist Gang (Lead: Eng. P. Gogoi)',
        status: DigStatus.planned,
        targetDate: DateTime.now().add(const Duration(days: 52)),
        fieldNotes:
            '25kV AC traction interference verified. Installing Zinc grounding ribbon and Solid State Decoupler.',
      ),
      DigWorkOrder(
        id: 'DIG-2026-005',
        segmentId: 'SEG-03',
        chainageStr: 'Ch 14+820',
        locationName: 'Tengakhat Lowland Agricultural Plot',
        gpsLat: 27.3210,
        gpsLong: 95.3421,
        defectDepthPercent: 46.0,
        defectLengthMm: 65.0,
        defectWidthMm: 30.0,
        clockPosition: '6:00 (Bottom-of-Line)',
        erf: 0.96,
        priority: DigPriority.oneYear,
        repairMethod: RepairMethodology.typeASteelSleeve,
        rowClearance: 'Farmer Compensation Settlement in progress',
        assignedCrew: 'Maintenance Gang Gamma (Lead: Foreman D. Das)',
        status: DigStatus.planned,
        targetDate: DateTime.now().add(const Duration(days: 180)),
        fieldNotes:
            'Defect non-critical at current MAOP. Scheduled for post-monsoon harvest window (Nov 2026).',
      ),
      DigWorkOrder(
        id: 'DIG-2026-006',
        segmentId: 'SEG-24',
        chainageStr: 'Ch 141+600',
        locationName: 'Numaligarh Terminal Perimeter Fence',
        gpsLat: 26.5890,
        gpsLong: 93.7310,
        defectDepthPercent: 41.0,
        defectLengthMm: 68.0,
        defectWidthMm: 28.0,
        clockPosition: '5:00 (Soil Stress Corrosion)',
        erf: 0.94,
        priority: DigPriority.scheduled,
        repairMethod: RepairMethodology.compositeWrap,
        rowClearance: 'NRL Terminal Safety Work Permit Validated',
        assignedCrew: 'Composite Specialized Crew Delta (Lead: Tech. R. Saikia)',
        status: DigStatus.repaired,
        targetDate: DateTime.now().add(const Duration(days: 7)),
        fieldNotes:
            'Clock Spring 8-ply wrap installed. Resin cured for 4 hours at 32°C. Awaiting final holiday spark test.',
      ),
      DigWorkOrder(
        id: 'DIG-2026-007',
        segmentId: 'SEG-22',
        chainageStr: 'Ch 128+900',
        locationName: 'Dergaon Cased Crossing (State Highway 1)',
        gpsLat: 26.6540,
        gpsLong: 93.8820,
        defectDepthPercent: 14.0,
        defectLengthMm: 24.0,
        defectWidthMm: 15.0,
        clockPosition: '12:00 (Top of Pipe)',
        erf: 0.76,
        priority: DigPriority.monitored,
        repairMethod: RepairMethodology.recoatAndHolidayTest,
        rowClearance: 'State Highway Maintenance Dept Consent',
        assignedCrew: 'Maintenance Gang Gamma (Lead: Foreman D. Das)',
        status: DigStatus.backfilled,
        targetDate: DateTime.now().subtract(const Duration(days: 10)),
        fieldNotes:
            'Coating holiday repaired with Visco-elastic strip and outer wrap. 15kV spark test passed 100%.',
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _matrixSearchCtrl.dispose();
    _digSearchCtrl.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // CORE ENGINEERING FORMULAS (MODIFIED B31G & RSTRENG)
  // --------------------------------------------------------------------------
  Map<String, double> _computeRemnantStrength({
    required double od,
    required double wt,
    required double smys,
    required double designFactor,
    required double maop,
    required double length,
    required double depth,
  }) {
    final double depthRatio = (depth / wt).clamp(0.01, 0.95);
    final double z = (length * length) / (od * wt);

    // Folias Factor M for Modified B31G
    final double foliasMod = z <= 50.0
        ? math.sqrt(1.0 + 0.6275 * z - 0.003375 * z * z)
        : (0.032 * z + 3.3);

    // Flow Stress (Sflow = SMYS + 68.95 MPa for Modified B31G)
    final double sflow = smys + 68.95;

    // Modified B31G Failure Stress (0.85dL arbitrary area)
    final double numMod = 1.0 - 0.85 * depthRatio;
    final double denMod = (1.0 - (0.85 * depthRatio) / foliasMod).clamp(0.01, 10.0);
    final double sigmaFailMod = numMod > 0 ? sflow * (numMod / denMod) : 0.0;

    // Burst Pressure (Bar) = [2 * t * sigmaFail / D] * 10 (from MPa)
    final double burstModBar = ((2.0 * wt * sigmaFailMod) / od) * 10.0;
    final double pSafeModBar = math.min(maop, burstModBar * designFactor);
    final double erfMod = pSafeModBar > 0.01 ? (maop / pSafeModBar) : 9.99;

    // RSTRENG (Effective Area Discrete Profile Method)
    // Employs a less conservative effective parabolic area coefficient ~0.85 * 0.88
    final double effAreaRatio = math.min(0.85 * depthRatio * 0.88, 0.92);
    final double numRst = 1.0 - effAreaRatio;
    final double denRst = (1.0 - effAreaRatio / foliasMod).clamp(0.01, 10.0);
    final double sigmaFailRst = numRst > 0 ? sflow * (numRst / denRst) : 0.0;

    final double burstRstBar = ((2.0 * wt * sigmaFailRst) / od) * 10.0;
    final double pSafeRstBar = math.min(maop, burstRstBar * designFactor);
    final double erfRst = pSafeRstBar > 0.01 ? (maop / pSafeRstBar) : 9.99;

    return {
      'folias': foliasMod,
      'sflow': sflow,
      'depthRatio': depthRatio * 100.0,
      'burstMod': burstModBar,
      'pSafeMod': pSafeModBar,
      'erfMod': erfMod,
      'burstRst': burstRstBar,
      'pSafeRst': pSafeRstBar,
      'erfRst': erfRst,
      'deratePercentMod': erfMod > 1.0 ? ((1.0 - (pSafeModBar / maop)) * 100.0) : 0.0,
      'deratePercentRst': erfRst > 1.0 ? ((1.0 - (pSafeRstBar / maop)) * 100.0) : 0.0,
    };
  }

  // --------------------------------------------------------------------------
  // FILTERED SEGMENTS FOR TAB 1
  // --------------------------------------------------------------------------
  List<PipelineSegment> get _filteredSegments {
    return _all24Segments.where((seg) {
      if (_selectedMatrixPof != null && seg.pof != _selectedMatrixPof) {
        return false;
      }
      if (_selectedMatrixCof != null && seg.cof != _selectedMatrixCof) {
        return false;
      }
      if (_selectedTierFilter != null && seg.riskTier != _selectedTierFilter) {
        return false;
      }
      if (_hcaOnlyFilter && !seg.isHca) {
        return false;
      }
      if (_threatFilter != null && seg.primaryThreat != _threatFilter) {
        return false;
      }
      if (_matrixSearchQuery.isNotEmpty) {
        final q = _matrixSearchQuery.toLowerCase();
        final matches = seg.id.toLowerCase().contains(q) ||
            seg.name.toLowerCase().contains(q) ||
            seg.chainageSpan.toLowerCase().contains(q) ||
            seg.primaryThreat.label.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  // --------------------------------------------------------------------------
  // FILTERED DIG ORDERS FOR TAB 4
  // --------------------------------------------------------------------------
  List<DigWorkOrder> get _filteredDigOrders {
    return _digWorkOrders.where((order) {
      if (_digPriorityFilter != null && order.priority != _digPriorityFilter) {
        return false;
      }
      if (_digSearchQuery.isNotEmpty) {
        final q = _digSearchQuery.toLowerCase();
        final matches = order.id.toLowerCase().contains(q) ||
            order.segmentId.toLowerCase().contains(q) ||
            order.locationName.toLowerCase().contains(q) ||
            order.chainageStr.toLowerCase().contains(q) ||
            order.repairMethod.name.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  // ============================================================================
  // UI BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildGlobalStatsHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTab1RiskMatrix(),
                _buildTab2RemnantStrengthCalc(),
                _buildTab3RemnantLife(),
                _buildTab4DigSchedule(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // APP BAR
  // --------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF111C38),
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PIMS Risk & Remnant Life',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF1F5F9),
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'ASME B31.8S / API 1160 Quantitative Risk Assessment',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF38BDF8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'ASME PCC-2 Guidelines',
          icon: const Icon(Icons.menu_book_rounded, color: Color(0xFFFFB95F)),
          onPressed: _showAsmeGuidelinesDialog,
        ),
        IconButton(
          tooltip: 'Export PIMS Dossier',
          icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF38BDF8)),
          onPressed: _exportPimsDossier,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // GLOBAL STATS HEADER
  // --------------------------------------------------------------------------
  Widget _buildGlobalStatsHeader() {
    final totalSegs = _all24Segments.length;
    final criticalCount =
        _all24Segments.where((s) => s.riskTier == RiskTier.critical).length;
    final highCount =
        _all24Segments.where((s) => s.riskTier == RiskTier.high).length;
    final maxErf = _all24Segments
        .map((s) => s.modB31gErf)
        .reduce((a, b) => math.max(a, b));
    final activeDigs = _digWorkOrders
        .where((d) => d.status != DigStatus.backfilled)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111C38),
        border: Border(
          bottom: BorderSide(color: Color(0xFF26396E), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Pipeline Meta Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF162347),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF26396E)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 14, color: Color(0xFF38BDF8)),
                    SizedBox(width: 6),
                    Text(
                      'OIL INDIA 18" X70 TRUNKLINE (144.0 KM)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF1F5F9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Health Index
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x284EDEA3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF4EDEA3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.health_and_safety_rounded,
                        size: 14, color: Color(0xFF4EDEA3)),
                    SizedBox(width: 4),
                    Text(
                      'INTEGRITY: 87.4%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4EDEA3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildHeaderStatCard(
                label: 'MONITORED',
                value: '$totalSegs Segs',
                subtext: 'Ch 0+000 - 144+000',
                color: const Color(0xFF38BDF8),
                icon: Icons.alt_route_rounded,
              ),
              const SizedBox(width: 8),
              _buildHeaderStatCard(
                label: 'CRITICAL / HIGH',
                value: '$criticalCount / $highCount',
                subtext: 'ASME Immediate',
                color: const Color(0xFFEF4444),
                icon: Icons.warning_rounded,
              ),
              const SizedBox(width: 8),
              _buildHeaderStatCard(
                label: 'MAX ERF',
                value: maxErf.toStringAsFixed(2),
                subtext: 'Seg-07 (Ch 38+420)',
                color: const Color(0xFFFFB95F),
                icon: Icons.speed_rounded,
              ),
              const SizedBox(width: 8),
              _buildHeaderStatCard(
                label: 'ACTIVE DIGS',
                value: '$activeDigs Sites',
                subtext: 'Sleeve / Wrap',
                color: const Color(0xFF4EDEA3),
                icon: Icons.construction_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatCard({
    required String label,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF162347),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF26396E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtext,
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB BAR
  // --------------------------------------------------------------------------
  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF111C38),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF0284C7),
        indicatorWeight: 3,
        labelColor: const Color(0xFF38BDF8),
        unselectedLabelColor: const Color(0xFF94A3B8),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(
            icon: Icon(Icons.grid_view_rounded, size: 18),
            text: '5x5 Risk Matrix & QRA',
          ),
          Tab(
            icon: Icon(Icons.calculate_rounded, size: 18),
            text: 'Remnant Strength & MAOP',
          ),
          Tab(
            icon: Icon(Icons.timeline_rounded, size: 18),
            text: 'Remnant Life & ILI Cycle',
          ),
          Tab(
            icon: Icon(Icons.assignment_rounded, size: 18),
            text: 'Critical Dig Repair Orders',
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: 5x5 QUANTITATIVE RISK MATRIX & QRA
  // ============================================================================

  Widget _buildTab1RiskMatrix() {
    final filtered = _filteredSegments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '5x5 QUANTITATIVE RISK MATRIX',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF1F5F9),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'ASME B31.8S §3: Probability of Failure (PoF) vs Consequence (CoF)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              if (_selectedMatrixPof != null ||
                  _selectedMatrixCof != null ||
                  _selectedTierFilter != null ||
                  _hcaOnlyFilter ||
                  _threatFilter != null ||
                  _matrixSearchQuery.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                  icon: const Icon(Icons.clear_rounded, size: 14),
                  label: const Text('Reset Filters', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _selectedMatrixPof = null;
                      _selectedMatrixCof = null;
                      _selectedTierFilter = null;
                      _hcaOnlyFilter = false;
                      _threatFilter = null;
                      _matrixSearchCtrl.clear();
                      _matrixSearchQuery = '';
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 5x5 Heatmap Matrix Card
          _build5x5InteractiveGrid(),
          const SizedBox(height: 16),

          // Risk Matrix Legend & Quick Tier Filter Buttons
          _buildRiskLegendBar(),
          const SizedBox(height: 16),

          // Search & Filter Toolbar
          _buildMatrixFilterToolbar(),
          const SizedBox(height: 12),

          // Segment Count / Filter Status Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PIPELINE SEGMENTS (${filtered.length} of ${_all24Segments.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              if (_selectedMatrixPof != null && _selectedMatrixCof != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF0284C7)),
                  ),
                  child: Text(
                    'Cell: PoF $_selectedMatrixPof × CoF $_selectedMatrixCof',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Segments List
          if (filtered.isEmpty)
            _buildEmptyState('No pipeline segments match the selected matrix filters.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _buildSegmentCard(filtered[index]);
              },
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 5x5 MATRIX HEATMAP WIDGET
  // --------------------------------------------------------------------------
  Widget _build5x5InteractiveGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Column(
        children: [
          // Header Row for Consequence of Failure (X-Axis)
          Row(
            children: [
              const SizedBox(
                width: 50,
                child: RotatedBox(
                  quarterTurns: -1,
                  child: Text(
                    'PROBABILITY (PoF) ↑',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF38BDF8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    // CoF Axis Label
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'CONSEQUENCE OF FAILURE (CoF) →',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38BDF8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // CoF Column numbers 1..5
                    Row(
                      children: List.generate(5, (index) {
                        final cof = index + 1;
                        return Expanded(
                          child: Center(
                            child: Text(
                              'C$cof',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 5 Rows (PoF from 5 down to 1)
          ...List.generate(5, (rowIndex) {
            final pof = 5 - rowIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  // PoF Label
                  SizedBox(
                    width: 50,
                    child: Text(
                      'P$pof',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  // 5 Grid Cells
                  Expanded(
                    child: Row(
                      children: List.generate(5, (colIndex) {
                        final cof = colIndex + 1;
                        return Expanded(
                          child: _buildMatrixCell(pof: pof, cof: cof),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),
          // Interactive prompt
          const Center(
            child: Text(
              '💡 Tap any grid cell to filter segments in that PoF × CoF quadrant',
              style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixCell({required int pof, required int cof}) {
    // Count segments in this cell
    final count = _all24Segments
        .where((seg) => seg.pof == pof && seg.cof == cof)
        .length;

    // Determine risk score & tier
    final score = pof * cof;
    Color cellBg;
    Color cellBorder;
    Color textColor;

    if (score >= 16 || (pof >= 4 && cof >= 4)) {
      cellBg = const Color(0xFFEF4444).withValues(alpha: 0.35);
      cellBorder = const Color(0xFFEF4444);
      textColor = const Color(0xFFFF8B8B);
    } else if (score >= 10) {
      cellBg = const Color(0xFFFB923C).withValues(alpha: 0.35);
      cellBorder = const Color(0xFFFB923C);
      textColor = const Color(0xFFFFB67A);
    } else if (score >= 5) {
      cellBg = const Color(0xFFFFB95F).withValues(alpha: 0.30);
      cellBorder = const Color(0xFFFFB95F);
      textColor = const Color(0xFFFFE082);
    } else {
      cellBg = const Color(0xFF4EDEA3).withValues(alpha: 0.25);
      cellBorder = const Color(0xFF4EDEA3);
      textColor = const Color(0xFFA7F3D0);
    }

    final isSelected =
        _selectedMatrixPof == pof && _selectedMatrixCof == cof;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedMatrixPof = null;
              _selectedMatrixCof = null;
            } else {
              _selectedMatrixPof = pof;
              _selectedMatrixCof = cof;
            }
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? cellBorder : cellBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? Colors.white : cellBorder.withValues(alpha: 0.7),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cellBorder.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count > 0 ? '$count' : '-',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : textColor,
                ),
              ),
              Text(
                'R$score',
                style: TextStyle(
                  fontSize: 8,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // RISK LEGEND & TIER FILTER BAR
  // --------------------------------------------------------------------------
  Widget _buildRiskLegendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RISK LEVEL TIERS (TAP TO FILTER)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildTierChip(
                tier: RiskTier.critical,
                label: 'Critical (16-25)',
                count: _all24Segments
                    .where((s) => s.riskTier == RiskTier.critical)
                    .length,
              ),
              const SizedBox(width: 6),
              _buildTierChip(
                tier: RiskTier.high,
                label: 'High (10-15)',
                count: _all24Segments
                    .where((s) => s.riskTier == RiskTier.high)
                    .length,
              ),
              const SizedBox(width: 6),
              _buildTierChip(
                tier: RiskTier.medium,
                label: 'Med (5-9)',
                count: _all24Segments
                    .where((s) => s.riskTier == RiskTier.medium)
                    .length,
              ),
              const SizedBox(width: 6),
              _buildTierChip(
                tier: RiskTier.low,
                label: 'Low (1-4)',
                count: _all24Segments
                    .where((s) => s.riskTier == RiskTier.low)
                    .length,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierChip({
    required RiskTier tier,
    required String label,
    required int count,
  }) {
    final isSelected = _selectedTierFilter == tier;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTierFilter = isSelected ? null : tier;
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? tier.color.withValues(alpha: 0.3) : tier.bgTint,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? tier.color : const Color(0xFF26396E),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: tier.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: tier.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFFF1F5F9) : const Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // MATRIX SEARCH & FILTER TOOLBAR
  // --------------------------------------------------------------------------
  Widget _buildMatrixFilterToolbar() {
    return Column(
      children: [
        // Search TextField
        TextField(
          controller: _matrixSearchCtrl,
          style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search segment, chainage, threat...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
            suffixIcon: _matrixSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      _matrixSearchCtrl.clear();
                      setState(() => _matrixSearchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF162347),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF26396E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0284C7)),
            ),
          ),
          onChanged: (val) => setState(() => _matrixSearchQuery = val),
        ),
        const SizedBox(height: 8),

        // Quick Filter Chips (HCA Only & Threat Types)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('HCA Only', style: TextStyle(fontSize: 11)),
                selected: _hcaOnlyFilter,
                selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
                checkmarkColor: const Color(0xFFEF4444),
                labelStyle: TextStyle(
                  color: _hcaOnlyFilter ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                  fontWeight: _hcaOnlyFilter ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: const Color(0xFF162347),
                side: BorderSide(
                  color: _hcaOnlyFilter ? const Color(0xFFEF4444) : const Color(0xFF26396E),
                ),
                onSelected: (selected) {
                  setState(() => _hcaOnlyFilter = selected);
                },
              ),
              const SizedBox(width: 8),
              ...ThreatCategory.values.map((threat) {
                final isSelected = _threatFilter == threat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    avatar: Icon(threat.icon, size: 12, color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8)),
                    label: Text(threat.name, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0284C7).withValues(alpha: 0.3),
                    checkmarkColor: const Color(0xFF38BDF8),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: const Color(0xFF162347),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF26396E),
                    ),
                    onSelected: (selected) {
                      setState(() => _threatFilter = selected ? threat : null);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SEGMENT CARD COMPONENT
  // --------------------------------------------------------------------------
  Widget _buildSegmentCard(PipelineSegment seg) {
    final tier = seg.riskTier;
    final erf = seg.modB31gErf;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tier == RiskTier.critical
              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
              : const Color(0xFF26396E),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSegmentDetailsBottomSheet(seg),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  children: [
                    // Segment ID Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111C38),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF26396E)),
                      ),
                      child: Text(
                        seg.id,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Class & HCA tag
                    Text(
                      seg.classLocation,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    if (seg.isHca) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0x33EF4444),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
                        ),
                        child: const Text(
                          'HCA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Risk Score Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tier.bgTint,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tier.color),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tier.icon, size: 12, color: tier.color),
                          const SizedBox(width: 4),
                          Text(
                            '${tier.label} (${seg.riskScore})',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: tier.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Segment Name
                Text(
                  seg.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF1F5F9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${seg.chainageSpan} (${seg.lengthKm.toStringAsFixed(1)} km) • WT: ${seg.wallThicknessMm}mm',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 10),

                // Key Pipeline Metrics Grid
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111C38),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      // Max Defect d/t
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MAX CORROSION',
                              style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${seg.maxDepthPercent.toStringAsFixed(1)}% d/t',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: seg.maxDepthPercent >= 60.0
                                    ? const Color(0xFFEF4444)
                                    : (seg.maxDepthPercent >= 40.0
                                        ? const Color(0xFFFFB95F)
                                        : const Color(0xFF4EDEA3)),
                              ),
                            ),
                            Text(
                              'L=${seg.defectLengthMm.toInt()}mm',
                              style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      // CP Potential
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CP OFF-POTENTIAL',
                              style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${seg.cpPotentialMv.toInt()} mV',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: seg.cpPotentialMv > -850
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF4EDEA3),
                              ),
                            ),
                            Text(
                              seg.cpPotentialMv > -850 ? 'Under-Protected' : 'NACE Compliant',
                              style: TextStyle(
                                fontSize: 9,
                                color: seg.cpPotentialMv > -850
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Growth Rate & Re-assessment
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GROWTH & RE-ASSESS',
                              style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${seg.activeGrowthRateMmYr.toStringAsFixed(2)} mm/yr',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                            Text(
                              'Due: ${seg.recommendedReassessmentYears.toStringAsFixed(1)} Yrs',
                              style: const TextStyle(fontSize: 9, color: Color(0xFFFFB95F)),
                            ),
                          ],
                        ),
                      ),
                      // ERF
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EST. REPAIR FACTOR',
                              style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'ERF ${erf.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: erf > 1.0
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF4EDEA3),
                              ),
                            ),
                            Text(
                              erf > 1.0 ? 'Action Req.' : 'Fit for MAOP',
                              style: TextStyle(
                                fontSize: 9,
                                color: erf > 1.0
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Primary Threat & Action footer
                Row(
                  children: [
                    Icon(seg.primaryThreat.icon, size: 13, color: const Color(0xFF38BDF8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        seg.primaryThreat.label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 2: REMNANT STRENGTH & SAFE MAOP CALCULATOR (MODIFIED B31G & RSTRENG)
  // ============================================================================

  Widget _buildTab2RemnantStrengthCalc() {
    final results = _computeRemnantStrength(
      od: _calcOd,
      wt: _calcWt,
      smys: _calcSmys,
      designFactor: _calcDesignFactor,
      maop: _calcMaop,
      length: _calcDefectLength,
      depth: _calcDefectDepth,
    );

    final erfMod = results['erfMod']!;
    final erfRst = results['erfRst']!;
    final pSafeMod = results['pSafeMod']!;
    final pSafeRst = results['pSafeRst']!;
    final burstMod = results['burstMod']!;
    final burstRst = results['burstRst']!;
    final folias = results['folias']!;
    final sflow = results['sflow']!;
    final dOverT = results['depthRatio']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF162347),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF26396E)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calculate_rounded, color: Color(0xFF38BDF8), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MODIFIED B31G & RSTRENG CALCULATOR',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF1F5F9),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ASME B31G §2 / RSTRENG Effective Area (0.85dL) Burst Evaluation',
                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Presets Selector
          _buildCalcPresetSelector(),
          const SizedBox(height: 16),

          // Defect Geometry & Pipe Cross-Section Visualizer
          _buildPipeDefectCrossSectionGraphic(
            od: _calcOd,
            wt: _calcWt,
            defectDepth: _calcDefectDepth,
            defectLength: _calcDefectLength,
            defectWidth: _calcDefectWidth,
            depthPercent: dOverT,
          ),
          const SizedBox(height: 16),

          // Side-by-Side Dual Calculation Results (Modified B31G vs RSTRENG)
          Row(
            children: [
              Expanded(
                child: _buildCalculationMethodCard(
                  title: 'MODIFIED B31G (0.85dL)',
                  subtitle: 'ASME B31G Arbitrary Shape',
                  burstBar: burstMod,
                  pSafeBar: pSafeMod,
                  erf: erfMod,
                  color: erfMod > 1.0 ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                  isConservative: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCalculationMethodCard(
                  title: 'RSTRENG (EFF. AREA)',
                  subtitle: 'River-bottom Profile Integration',
                  burstBar: burstRst,
                  pSafeBar: pSafeRst,
                  erf: erfRst,
                  color: erfRst > 1.0 ? const Color(0xFFFB923C) : const Color(0xFF4EDEA3),
                  isConservative: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status & Derating Banner
          _buildDeratingStatusBanner(
            erfMod: erfMod,
            erfRst: erfRst,
            pSafeMod: pSafeMod,
            pSafeRst: pSafeRst,
            maop: _calcMaop,
            dOverT: dOverT,
          ),
          const SizedBox(height: 16),

          // Interactive Sliders & Engineering Inputs
          _buildInteractiveCalculatorInputs(folias: folias, sflow: sflow),
          const SizedBox(height: 16),

          // Pressure Comparison Graph Bar
          _buildPressureComparisonBar(
            maop: _calcMaop,
            pSafeMod: pSafeMod,
            pSafeRst: pSafeRst,
            burstMod: burstMod,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PRESET SELECTOR
  // --------------------------------------------------------------------------
  Widget _buildCalcPresetSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark_rounded, size: 14, color: Color(0xFFFFB95F)),
          const SizedBox(width: 6),
          const Text(
            'LOAD PRESET DEFECT:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFB95F),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetButton(
                    label: 'Seg-07 (HDD 68% pit)',
                    onTap: () {
                      setState(() {
                        _calcOd = 457.2;
                        _calcWt = 14.27; // Heavy wall crossing
                        _calcDesignFactor = 0.50; // Class 3 crossing
                        _calcDefectLength = 140.0;
                        _calcDefectDepth = 9.70; // ~68%
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildPresetButton(
                    label: 'Seg-11 (Moran 61%)',
                    onTap: () {
                      setState(() {
                        _calcOd = 457.2;
                        _calcWt = 11.91;
                        _calcDesignFactor = 0.50;
                        _calcDefectLength = 110.0;
                        _calcDefectDepth = 7.26; // ~61%
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildPresetButton(
                    label: 'Seg-14 (Sibsagar 54%)',
                    onTap: () {
                      setState(() {
                        _calcOd = 457.2;
                        _calcWt = 11.91;
                        _calcDesignFactor = 0.50;
                        _calcDefectLength = 95.0;
                        _calcDefectDepth = 6.43; // ~54%
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildPresetButton(
                    label: 'Standard Baseline (30%)',
                    onTap: () {
                      setState(() {
                        _calcOd = 457.2;
                        _calcWt = 9.52;
                        _calcDesignFactor = 0.72;
                        _calcDefectLength = 60.0;
                        _calcDefectDepth = 2.85; // 30%
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

  Widget _buildPresetButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF111C38),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF26396E)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFFF1F5F9)),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PIPE CROSS-SECTION GRAPHIC (CUSTOM PAINTER)
  // --------------------------------------------------------------------------
  Widget _buildPipeDefectCrossSectionGraphic({
    required double od,
    required double wt,
    required double defectDepth,
    required double defectLength,
    required double defectWidth,
    required double depthPercent,
  }) {
    final remnantLigament = wt - defectDepth;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DEFECT WALL-LOSS CROSS SECTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Remnant Ligament: ${remnantLigament.toStringAsFixed(2)} mm',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: remnantLigament < 3.0
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF4EDEA3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Custom Painter Canvas
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: _PipeCrossSectionPainter(
                wt: wt,
                depth: defectDepth,
                defectLength: defectLength,
                depthRatio: depthPercent / 100.0,
                isInternal: _calcIsInternal,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Dimension Footnotes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Nominal WT: ${wt.toStringAsFixed(2)}mm',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              Text('Defect Depth d: ${defectDepth.toStringAsFixed(2)}mm (${depthPercent.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: depthPercent > 60.0 ? const Color(0xFFEF4444) : const Color(0xFFFFB95F),
                  )),
              Text('L: ${defectLength.toInt()}mm • W: ${defectWidth.toInt()}mm',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // CALCULATION METHOD COMPARISON CARD
  // --------------------------------------------------------------------------
  Widget _buildCalculationMethodCard({
    required String title,
    required String subtitle,
    required double burstBar,
    required double pSafeBar,
    required double erf,
    required Color color,
    required bool isConservative,
  }) {
    final isUnsafe = erf > 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUnsafe ? const Color(0xFFEF4444) : const Color(0xFF26396E),
          width: isUnsafe ? 1.5 : 1.0,
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isConservative ? 'Conservative' : 'Refined Area',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
          ),
          const Divider(color: Color(0xFF26396E), height: 16),

          // ERF Number
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                erf.toStringAsFixed(3),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isUnsafe ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'ERF',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isUnsafe ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isUnsafe ? const Color(0x33EF4444) : const Color(0x284EDEA3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isUnsafe ? 'ERF > 1.0 (DERATE)' : 'ERF ≤ 1.0 (FIT)',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isUnsafe ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Pressures
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SAFE MAOP (P_safe)', style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
                  Text(
                    '${pSafeBar.toStringAsFixed(1)} Bar',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF1F5F9),
                    ),
                  ),
                  Text('~${(pSafeBar * 14.5038).toInt()} psi', style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('BURST PRESSURE (P_b)', style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
                  Text(
                    '${burstBar.toStringAsFixed(1)} Bar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text('~${(burstBar * 14.5038).toInt()} psi', style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DERATING & ACTION BANNER
  // --------------------------------------------------------------------------
  Widget _buildDeratingStatusBanner({
    required double erfMod,
    required double erfRst,
    required double pSafeMod,
    required double pSafeRst,
    required double maop,
    required double dOverT,
  }) {
    if (dOverT >= 80.0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x33EF4444),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.dangerous_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IMMEDIATE REPAIR CONDITION: DEPTH ≥ 80% WT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'ASME B31.8S §851.4 limits maximum allowable defect depth to 80% of nominal wall thickness regardless of computed pressure. Mandatory Type B Steel Sleeve or Spool Cut-out.',
                    style: TextStyle(fontSize: 10, color: Color(0xFFF1F5F9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (erfMod > 1.0) {
      final derateBar = maop - pSafeMod;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x28EF4444),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEF4444)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MANDATORY PRESSURE DERATING REQUIRED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Design MAOP exceeds Safe Operating Pressure. Per ASME B31G, pipeline MAOP must be immediately reduced by ${derateBar.toStringAsFixed(1)} Bar to ${pSafeMod.toStringAsFixed(1)} Bar (or ${pSafeRst.toStringAsFixed(1)} Bar via RSTRENG) until permanent sleeve repair is completed.',
                    style: const TextStyle(fontSize: 10, color: Color(0xFFF1F5F9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x284EDEA3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4EDEA3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFF4EDEA3), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FIT FOR SERVICE AT DESIGN MAOP (ERF ≤ 1.00)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4EDEA3),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Corrosion defect remnant strength exceeds ASME B31G threshold. Full operating pressure of ${maop.toStringAsFixed(1)} Bar (~${(maop * 14.5038).toInt()} psi) is structurally acceptable without pressure derating.',
                  style: const TextStyle(fontSize: 10, color: Color(0xFFF1F5F9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // CALCULATOR INPUTS & SLIDERS
  // --------------------------------------------------------------------------
  Widget _buildInteractiveCalculatorInputs({
    required double folias,
    required double sflow,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PIPELINE & DEFECT PARAMETER TUNING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF38BDF8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Defect Depth Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Defect Depth d: ${_calcDefectDepth.toStringAsFixed(2)} mm (${((_calcDefectDepth / _calcWt) * 100).toStringAsFixed(1)}% WT)',
                style: const TextStyle(fontSize: 11, color: Color(0xFFF1F5F9)),
              ),
              Text(
                'Max: ${(_calcWt * 0.85).toStringAsFixed(1)}mm',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFEF4444),
              inactiveTrackColor: const Color(0xFF111C38),
              thumbColor: const Color(0xFFEF4444),
              trackHeight: 4,
            ),
            child: Slider(
              value: _calcDefectDepth.clamp(0.5, _calcWt * 0.90),
              min: 0.5,
              max: _calcWt * 0.90,
              divisions: 100,
              onChanged: (val) {
                setState(() => _calcDefectDepth = val);
              },
            ),
          ),

          // Defect Length Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Axial Defect Length L: ${_calcDefectLength.toInt()} mm',
                style: const TextStyle(fontSize: 11, color: Color(0xFFF1F5F9)),
              ),
              Text(
                'Folias M: ${folias.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF38BDF8)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF38BDF8),
              inactiveTrackColor: const Color(0xFF111C38),
              thumbColor: const Color(0xFF38BDF8),
              trackHeight: 4,
            ),
            child: Slider(
              value: _calcDefectLength.clamp(10.0, 400.0),
              min: 10.0,
              max: 400.0,
              divisions: 78,
              onChanged: (val) {
                setState(() => _calcDefectLength = val);
              },
            ),
          ),

          // Wall Thickness Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nominal WT t: ${_calcWt.toStringAsFixed(2)} mm',
                style: const TextStyle(fontSize: 11, color: Color(0xFFF1F5F9)),
              ),
              Text(
                'Flow Stress: ${sflow.toStringAsFixed(1)} MPa',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFFB95F),
              inactiveTrackColor: const Color(0xFF111C38),
              thumbColor: const Color(0xFFFFB95F),
              trackHeight: 4,
            ),
            child: Slider(
              value: _calcWt.clamp(6.0, 20.0),
              min: 6.0,
              max: 20.0,
              divisions: 28,
              onChanged: (val) {
                setState(() {
                  _calcWt = val;
                  if (_calcDefectDepth > _calcWt * 0.90) {
                    _calcDefectDepth = _calcWt * 0.80;
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 6),

          // Pipe OD & Design Factor Quick Pickers
          Row(
            children: [
              // OD Selector
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PIPE DIAMETER (OD)', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<double>(
                      key: ValueKey('calc_od_$_calcOd'),
                      initialValue: _calcOd,
                      dropdownColor: const Color(0xFF111C38),
                      style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 11),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        filled: true,
                        fillColor: const Color(0xFF111C38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 323.85, child: Text('12" (323.9 mm)')),
                        DropdownMenuItem(value: 406.40, child: Text('16" (406.4 mm)')),
                        DropdownMenuItem(value: 457.20, child: Text('18" (457.2 mm)')),
                        DropdownMenuItem(value: 609.60, child: Text('24" (609.6 mm)')),
                        DropdownMenuItem(value: 762.00, child: Text('30" (762.0 mm)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _calcOd = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Design Factor Selector
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DESIGN FACTOR (F)', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<double>(
                      key: ValueKey('calc_df_$_calcDesignFactor'),
                      initialValue: _calcDesignFactor,
                      dropdownColor: const Color(0xFF111C38),
                      style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 11),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        filled: true,
                        fillColor: const Color(0xFF111C38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0.72, child: Text('F = 0.72 (Class 1)')),
                        DropdownMenuItem(value: 0.60, child: Text('F = 0.60 (Class 2)')),
                        DropdownMenuItem(value: 0.50, child: Text('F = 0.50 (Class 3 / HDD)')),
                        DropdownMenuItem(value: 0.40, child: Text('F = 0.40 (Class 4 / Terminal)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _calcDesignFactor = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PRESSURE COMPARISON BAR GRAPH
  // --------------------------------------------------------------------------
  Widget _buildPressureComparisonBar({
    required double maop,
    required double pSafeMod,
    required double pSafeRst,
    required double burstMod,
  }) {
    final maxScale = math.max(burstMod * 1.05, maop * 1.5);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRESSURE THRESHOLD SPECTRUM (BAR)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          _buildPressureBarItem(
            label: 'Design MAOP Target',
            value: maop,
            max: maxScale,
            color: const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 6),
          _buildPressureBarItem(
            label: 'Safe Pressure (Mod B31G)',
            value: pSafeMod,
            max: maxScale,
            color: pSafeMod < maop ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
          ),
          const SizedBox(height: 6),
          _buildPressureBarItem(
            label: 'Safe Pressure (RSTRENG)',
            value: pSafeRst,
            max: maxScale,
            color: pSafeRst < maop ? const Color(0xFFFB923C) : const Color(0xFF4EDEA3),
          ),
          const SizedBox(height: 6),
          _buildPressureBarItem(
            label: 'Ultimate Burst Pressure',
            value: burstMod,
            max: maxScale,
            color: const Color(0xFFA78BFA),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureBarItem({
    required String label,
    required double value,
    required double max,
    required Color color,
  }) {
    final fraction = (value / max).clamp(0.02, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFF1F5F9))),
            Text('${value.toStringAsFixed(1)} Bar',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            height: 6,
            color: const Color(0xFF111C38),
            child: FractionallySizedBox(
              widthFactor: fraction,
              alignment: Alignment.centerLeft,
              child: Container(color: color),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 3: REMNANT LIFE & ILI RE-ASSESSMENT INTERVAL (ASME B31.8S §6.2)
  // ============================================================================

  Widget _buildTab3RemnantLife() {
    final seg = _selectedTrajectorySegment;
    final currentDepthMm = (seg.maxDepthPercent / 100.0) * seg.wallThicknessMm;
    final critDepthMm = (_criticalDepthThresholdPercent / 100.0) * seg.wallThicknessMm;
    final remainingMarginMm = critDepthMm - currentDepthMm;
    final remnantYears = remainingMarginMm > 0 && _activeCgrSlider > 0.001
        ? remainingMarginMm / _activeCgrSlider
        : 0.0;
    final halfLifeInterval = remnantYears / 2.0;
    final statutoryCap = seg.isHca ? 5.0 : 10.0;
    final asmeInterval = math.max(0.5, math.min(halfLifeInterval, statutoryCap));
    final nextIliYear = 2026 + asmeInterval.floor();
    final nextIliQuarter = 'Q${((asmeInterval % 1.0) * 4).floor() + 1}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF162347),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF26396E)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4EDEA3).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.timeline_rounded, color: Color(0xFF4EDEA3), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REMNANT LIFE & RE-ASSESSMENT INTERVAL',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF1F5F9),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ASME B31.8S §6.2: Half-Life Rule & Active Corrosion Kinetics',
                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Active Segment Selector Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF162347),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF26396E)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pin_drop_rounded, size: 16, color: Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                const Text(
                  'TARGET SEGMENT:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PipelineSegment>(
                      value: _selectedTrajectorySegment,
                      dropdownColor: const Color(0xFF111C38),
                      isDense: true,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF38BDF8)),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF1F5F9),
                      ),
                      items: _all24Segments.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text('${s.id} - ${s.name} (${s.maxDepthPercent}% d/t)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTrajectorySegment = val;
                            _activeCgrSlider = val.activeGrowthRateMmYr;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Re-assessment Interval Output Cards
          Row(
            children: [
              Expanded(
                child: _buildRemnantStatCard(
                  label: 'REMNANT LIFE TO 80%',
                  value: '${remnantYears.toStringAsFixed(1)} Yrs',
                  subtext: 'Margin: ${remainingMarginMm.toStringAsFixed(2)} mm',
                  color: remnantYears < 3.0 ? const Color(0xFFEF4444) : const Color(0xFFFFB95F),
                  icon: Icons.timer_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRemnantStatCard(
                  label: 'RECOMMENDED INTERVAL',
                  value: '${asmeInterval.toStringAsFixed(1)} Yrs',
                  subtext: 'ASME Half-Life Rule',
                  color: const Color(0xFF4EDEA3),
                  icon: Icons.update_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRemnantStatCard(
                  label: 'NEXT ILI TARGET',
                  value: '$nextIliQuarter $nextIliYear',
                  subtext: 'High-Res MFL + UT',
                  color: const Color(0xFF38BDF8),
                  icon: Icons.event_available_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Corrosion Growth Rate Slider & Sensitivity Tuning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF162347),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF26396E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ACTIVE CORROSION GROWTH RATE (CGR)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF1F5F9),
                      ),
                    ),
                    Text(
                      '${_activeCgrSlider.toStringAsFixed(2)} mm/year',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _activeCgrSlider > 0.30
                            ? const Color(0xFFEF4444)
                            : (_activeCgrSlider > 0.15
                                ? const Color(0xFFFFB95F)
                                : const Color(0xFF4EDEA3)),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF38BDF8),
                    inactiveTrackColor: const Color(0xFF111C38),
                    thumbColor: const Color(0xFF38BDF8),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _activeCgrSlider.clamp(0.05, 0.70),
                    min: 0.05,
                    max: 0.70,
                    divisions: 65,
                    onChanged: (val) {
                      setState(() => _activeCgrSlider = val);
                    },
                  ),
                ),
                // Growth rate benchmarks
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Low: 0.08 mm/yr', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                    Text('Moderate: 0.20 mm/yr', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                    Text('High/Unmitigated: 0.40+ mm/yr', style: TextStyle(fontSize: 9, color: Color(0xFFEF4444))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // FL CHART: Wall Loss Degradation Trajectory (0 to 12 Years)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF162347),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF26396E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WALL DEGRADATION PROJECTION (12 YEARS)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF1F5F9),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'ASME B31.8 Limit: 80%',
                      style: TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 200,
                  child: _buildDegradationChart(
                    initialDepthPercent: seg.maxDepthPercent,
                    wt: seg.wallThicknessMm,
                    cgr: _activeCgrSlider,
                    asmeDueYears: asmeInterval,
                  ),
                ),
                const SizedBox(height: 10),
                // Chart Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildChartLegendItem('Current Projection', const Color(0xFF38BDF8)),
                    const SizedBox(width: 16),
                    _buildChartLegendItem('70% Repair Threshold', const Color(0xFFFFB95F)),
                    const SizedBox(width: 16),
                    _buildChartLegendItem('80% Critical Limit', const Color(0xFFEF4444)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Re-assessment Schedule Priority Table for High/Critical Segments
          const Text(
            'MULTI-SEGMENT RE-ASSESSMENT TIMETABLE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildSegmentReassessmentTable(),
        ],
      ),
    );
  }

  Widget _buildRemnantStatCard({
    required String label,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEGRADATION LINE CHART
  // --------------------------------------------------------------------------
  Widget _buildDegradationChart({
    required double initialDepthPercent,
    required double wt,
    required double cgr,
    required double asmeDueYears,
  }) {
    final currentDepthMm = (initialDepthPercent / 100.0) * wt;

    final List<FlSpot> spots = [];
    for (int yr = 0; yr <= 12; yr++) {
      final projectedDepthMm = currentDepthMm + (cgr * yr);
      final pct = (projectedDepthMm / wt) * 100.0;
      spots.add(FlSpot(yr.toDouble(), math.min(100.0, pct)));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
          verticalInterval: 2,
          getDrawingHorizontalLine: _defaultGridLine,
          getDrawingVerticalLine: _defaultGridLine,
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  'Yr ${value.toInt()}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xFF26396E)),
        ),
        minX: 0,
        maxX: 12,
        minY: 0,
        maxY: 100,
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 80,
              color: const Color(0xFFEF4444),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (_) => '80% Critical Limit',
              ),
            ),
            HorizontalLine(
              y: 70,
              color: const Color(0xFFFFB95F),
              strokeWidth: 1.2,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                style: const TextStyle(
                  color: Color(0xFFFFB95F),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (_) => '70% Repair Action',
              ),
            ),
          ],
          verticalLines: [
            VerticalLine(
              x: asmeDueYears,
              color: const Color(0xFF4EDEA3),
              strokeWidth: 1.5,
              dashArray: [4, 4],
              label: VerticalLineLabel(
                show: true,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 4),
                style: const TextStyle(
                  color: Color(0xFF4EDEA3),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (_) => 'Re-assess Due',
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF38BDF8),
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  static FlLine _defaultGridLine(double value) => const FlLine(
        color: Color(0xFF26396E),
        strokeWidth: 0.8,
        dashArray: [4, 4],
      );

  Widget _buildChartLegendItem(String label, Color color) {
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
          style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // MULTI-SEGMENT RE-ASSESSMENT TABLE
  // --------------------------------------------------------------------------
  Widget _buildSegmentReassessmentTable() {
    final highRiskSegs = _all24Segments
        .where((s) => s.riskTier == RiskTier.critical || s.riskTier == RiskTier.high)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: highRiskSegs.length,
        separatorBuilder: (_, _) => const Divider(color: Color(0xFF26396E), height: 1),
        itemBuilder: (context, idx) {
          final seg = highRiskSegs[idx];
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Segment ID & Name
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            seg.id,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: seg.riskTier.bgTint,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              seg.riskTier.label,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: seg.riskTier.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        seg.name,
                        style: const TextStyle(fontSize: 10, color: Color(0xFFF1F5F9)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Depth & Rate
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${seg.maxDepthPercent}% d/t',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: seg.maxDepthPercent >= 60.0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFFFB95F),
                        ),
                      ),
                      Text(
                        '${seg.activeGrowthRateMmYr.toStringAsFixed(2)} mm/yr',
                        style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                // Half life & Next Due
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${seg.recommendedReassessmentYears.toStringAsFixed(1)} Yrs',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4EDEA3),
                        ),
                      ),
                      const Text(
                        'Half-Life Rule',
                        style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================================
  // TAB 4: CRITICAL DIG REPAIR SCHEDULE (ASME PCC-2 & API 1160)
  // ============================================================================

  Widget _buildTab4DigSchedule() {
    final filtered = _filteredDigOrders;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & New Dig Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CRITICAL DIG REPAIR SCHEDULE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF1F5F9),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'ASME PCC-2 / API 1160 Bell-Hole Verification & Sleeve Orders',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Dig', style: TextStyle(fontSize: 11)),
                onPressed: _showScheduleNewDigDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Priority Filter Chips
          _buildDigPriorityFilterChips(),
          const SizedBox(height: 10),

          // Dig Search Bar
          TextField(
            controller: _digSearchCtrl,
            style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search dig ID, chainage, repair method...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
              suffixIcon: _digSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                      onPressed: () {
                        _digSearchCtrl.clear();
                        setState(() => _digSearchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF162347),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF26396E)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0284C7)),
              ),
            ),
            onChanged: (val) => setState(() => _digSearchQuery = val),
          ),
          const SizedBox(height: 16),

          // ASME PCC-2 Repair Methodology Guide Expandable Card
          _buildAsmePcc2SelectionGuideBanner(),
          const SizedBox(height: 16),

          // Dig Work Orders List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WORK ORDERS (${filtered.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const Text(
                'ASME PCC-2 Art. 4.1 & 4.2',
                style: TextStyle(fontSize: 10, color: Color(0xFF38BDF8)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (filtered.isEmpty)
            _buildEmptyState('No excavation dig orders match the selected priority filter.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildDigWorkOrderCard(filtered[index]);
              },
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DIG PRIORITY FILTER CHIPS
  // --------------------------------------------------------------------------
  Widget _buildDigPriorityFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text('All Digs (${_digWorkOrders.length})', style: const TextStyle(fontSize: 11)),
            selected: _digPriorityFilter == null,
            selectedColor: const Color(0xFF0284C7),
            labelStyle: TextStyle(
              color: _digPriorityFilter == null ? Colors.white : const Color(0xFF94A3B8),
              fontWeight: _digPriorityFilter == null ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: const Color(0xFF162347),
            side: const BorderSide(color: Color(0xFF26396E)),
            onSelected: (_) => setState(() => _digPriorityFilter = null),
          ),
          const SizedBox(width: 6),
          ...DigPriority.values.map((priority) {
            final isSelected = _digPriorityFilter == priority;
            final count = _digWorkOrders.where((d) => d.priority == priority).length;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text('${priority.label} ($count)', style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: priority.color.withValues(alpha: 0.3),
                labelStyle: TextStyle(
                  color: isSelected ? priority.color : const Color(0xFF94A3B8),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: const Color(0xFF162347),
                side: BorderSide(color: isSelected ? priority.color : const Color(0xFF26396E)),
                onSelected: (selected) {
                  setState(() => _digPriorityFilter = selected ? priority : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ASME PCC-2 SELECTION GUIDE BANNER
  // --------------------------------------------------------------------------
  Widget _buildAsmePcc2SelectionGuideBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rule_rounded, color: Color(0xFFFFB95F), size: 16),
              SizedBox(width: 8),
              Text(
                'ASME PCC-2 REPAIR SELECTION STANDARD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFB95F),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildRepairGuidelinePill(
                  title: 'Type B Encirclement',
                  condition: 'd/t > 60% or ERF > 1.10',
                  action: 'Welded Pressure Steel Sleeve',
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRepairGuidelinePill(
                  title: 'Composite Wrap',
                  condition: 'd/t < 60%, Non-leaking',
                  action: 'Carbon 8-Ply / Clock Spring',
                  color: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepairGuidelinePill({
    required String title,
    required String condition,
    required String action,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF111C38),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text('Criteria: $condition', style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
          Text('Tech: $action', style: const TextStyle(fontSize: 8, color: Color(0xFFF1F5F9))),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DIG WORK ORDER CARD
  // --------------------------------------------------------------------------
  Widget _buildDigWorkOrderCard(DigWorkOrder order) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: order.priority == DigPriority.immediate
              ? const Color(0xFFEF4444).withValues(alpha: 0.7)
              : const Color(0xFF26396E),
          width: order.priority == DigPriority.immediate ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Dig ID, Priority Badge, Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111C38),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF26396E)),
                  ),
                  child: Text(
                    order.id,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${order.segmentId} • ${order.chainageStr}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF1F5F9),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: order.priority.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: order.priority.color),
                  ),
                  child: Text(
                    order.priority.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: order.priority.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Landmark Location Name
            Text(
              order.locationName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF1F5F9),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'GPS: ${order.gpsLat.toStringAsFixed(4)}°N, ${order.gpsLong.toStringAsFixed(4)}°E • Clock: ${order.clockPosition}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 8),

            // Anomaly & Repair Method Highlights
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF111C38),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDigMetricMini(
                        label: 'DEFECT DEPTH',
                        value: '${order.defectDepthPercent.toStringAsFixed(1)}% d/t',
                        color: order.defectDepthPercent >= 60.0
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFFFB95F),
                      ),
                      _buildDigMetricMini(
                        label: 'LENGTH × WIDTH',
                        value: '${order.defectLengthMm.toInt()} × ${order.defectWidthMm.toInt()} mm',
                        color: const Color(0xFFF1F5F9),
                      ),
                      _buildDigMetricMini(
                        label: 'REPAIR FACTOR (ERF)',
                        value: 'ERF ${order.erf.toStringAsFixed(2)}',
                        color: order.erf > 1.0 ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF26396E), height: 12),
                  Row(
                    children: [
                      Icon(order.repairMethod.icon, size: 14, color: const Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.repairMethod.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF38BDF8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              order.repairMethod.standardCode,
                              style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 5-Step Workflow Status Stepper
            _buildDigWorkflowStepIndicator(order.status),
            const SizedBox(height: 8),

            // RoW Clearance & Crew
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 12, color: Color(0xFF4EDEA3)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.rowClearance,
                    style: const TextStyle(fontSize: 9, color: Color(0xFF4EDEA3)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.groups_rounded, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${order.assignedCrew} • Target: ${dateFormat.format(order.targetDate)}',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF26396E)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 14),
                    label: const Text('Update Status', style: TextStyle(fontSize: 10)),
                    onPressed: () => _showUpdateDigStatusDialog(order),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFB95F),
                      side: const BorderSide(color: Color(0xFF26396E)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 14),
                    label: const Text('ASME PCC-2 Dossier', style: TextStyle(fontSize: 10)),
                    onPressed: () => _showDigDossierSheet(order),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigMetricMini({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 5-STAGE WORKFLOW STEPPER
  // --------------------------------------------------------------------------
  Widget _buildDigWorkflowStepIndicator(DigStatus currentStatus) {
    final steps = [
      'RoW',
      'Excavate',
      'NDT',
      'Sleeve',
      'Backfill',
    ];
    final currentIdx = currentStatus.stepIndex;

    return Row(
      children: List.generate(steps.length, (idx) {
        final isDone = idx < currentIdx;
        final isCurrent = idx == currentIdx;
        Color stepColor = isDone
            ? const Color(0xFF4EDEA3)
            : (isCurrent ? const Color(0xFF38BDF8) : const Color(0xFF26396E));

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? stepColor : Colors.transparent,
                  border: Border.all(color: stepColor, width: 1.5),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 10, color: Color(0xFF4EDEA3))
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? const Color(0xFF0B1326) : stepColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  steps[idx],
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? const Color(0xFFF1F5F9) : const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (idx < steps.length - 1)
                Container(
                  width: 8,
                  height: 1.5,
                  color: idx < currentIdx ? const Color(0xFF4EDEA3) : const Color(0xFF26396E),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ============================================================================
  // DIALOGS & BOTTOM SHEETS
  // ============================================================================

  void _showSegmentDetailsBottomSheet(PipelineSegment seg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111C38),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollCtrl) {
            return SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF26396E),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162347),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF26396E)),
                        ),
                        child: Text(
                          seg.id,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          seg.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF1F5F9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${seg.chainageSpan} (${seg.lengthKm} km) • ${seg.classLocation}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const Divider(color: Color(0xFF26396E), height: 24),

                  // Risk Matrix Breakdown Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162347),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: seg.riskTier.color.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ASME B31.8S RISK RATING',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: seg.riskTier.color,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: seg.riskTier.bgTint,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${seg.riskTier.label} (Score: ${seg.riskScore})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: seg.riskTier.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('PROBABILITY (PoF)', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                                  Text(
                                    'P${seg.pof} / 5',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF1F5F9),
                                    ),
                                  ),
                                  Text(
                                    seg.pof >= 4 ? 'High Degradation' : 'Stable CP / Low Scour',
                                    style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('CONSEQUENCE (CoF)', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                                  Text(
                                    'C${seg.cof} / 5',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF1F5F9),
                                    ),
                                  ),
                                  Text(
                                    seg.isHca ? 'High Consequence Area' : 'Low Pop Density',
                                    style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
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

                  // Engineering Parameters Table
                  const Text(
                    'PIPELINE TECHNICAL TELEMETRY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Nominal Wall Thickness', '${seg.wallThicknessMm} mm (API 5L X70)'),
                  _buildDetailRow('Max ILI Defect Depth', '${seg.maxDepthPercent}% d/t (${(seg.wallThicknessMm * seg.maxDepthPercent / 100).toStringAsFixed(2)} mm)'),
                  _buildDetailRow('Defect Axial Length', '${seg.defectLengthMm.toInt()} mm'),
                  _buildDetailRow('Estimated Repair Factor (ERF)', seg.modB31gErf.toStringAsFixed(3)),
                  _buildDetailRow('Soil Resistivity', '${seg.soilResistivityOhmCm.toInt()} Ω·cm'),
                  _buildDetailRow('Cathodic Off-Potential', '${seg.cpPotentialMv.toInt()} mV CSE'),
                  _buildDetailRow('Corrosion Growth Rate', '${seg.activeGrowthRateMmYr.toStringAsFixed(2)} mm/year'),
                  _buildDetailRow('Remnant Life to 80%', '${seg.remnantLifeYears.toStringAsFixed(1)} Years'),
                  _buildDetailRow('ASME Re-assessment Due', '${seg.recommendedReassessmentYears.toStringAsFixed(1)} Years (Half-life rule)'),
                  const SizedBox(height: 16),

                  // Mitigation Plan
                  const Text(
                    'INTEGRITY MITIGATION DIRECTIVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162347),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF26396E)),
                    ),
                    child: Text(
                      seg.mitigationPlan,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFF1F5F9)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.calculate_rounded, size: 18),
                          label: const Text('Send to Calculator'),
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _calcWt = seg.wallThicknessMm;
                              _calcDefectDepth = (seg.maxDepthPercent / 100.0) * seg.wallThicknessMm;
                              _calcDefectLength = seg.defectLengthMm;
                              _tabController.animateTo(1);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFB95F),
                            side: const BorderSide(color: Color(0xFFFFB95F)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.add_task_rounded, size: 18),
                          label: const Text('Create Dig Order'),
                          onPressed: () {
                            Navigator.pop(context);
                            _tabController.animateTo(3);
                            _showScheduleNewDigDialog();
                          },
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF1F5F9),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateDigStatusDialog(DigWorkOrder order) {
    DigStatus selected = order.status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111C38),
              title: Text(
                'Update Status: ${order.id}',
                style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: DigStatus.values.map((status) {
                  final isSelected = selected == status;
                  return InkWell(
                    onTap: () {
                      setDialogState(() => selected = status);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            status.label,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFFF1F5F9) : const Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  onPressed: () {
                    setState(() {
                      order.status = selected;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${order.id} status updated to ${selected.label}'),
                        backgroundColor: const Color(0xFF0284C7),
                      ),
                    );
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showScheduleNewDigDialog() {
    final formKey = GlobalKey<FormState>();
    String segId = 'SEG-07';
    String chainage = 'Ch 40+150';
    String location = 'Burhi Dihing South Embankment';
    double depth = 58.0;
    double length = 85.0;
    final DigPriority priority = DigPriority.scheduled;
    RepairMethodology repair = RepairMethodology.compositeWrap;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111C38),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Schedule Verification Dig Work Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF1F5F9),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Segment selector
                  DropdownButtonFormField<String>(
                    initialValue: segId,
                    dropdownColor: const Color(0xFF162347),
                    style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Pipeline Segment',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    items: _all24Segments.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text('${s.id} - ${s.name}'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) segId = val;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Chainage & Location
                  TextFormField(
                    initialValue: chainage,
                    style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Chainage (e.g. Ch 40+150)',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    onSaved: (val) => chainage = val ?? chainage,
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    initialValue: location,
                    style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Location / Landmark',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    onSaved: (val) => location = val ?? location,
                  ),
                  const SizedBox(height: 10),

                  // Depth & Length
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: depth.toString(),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Defect Depth (% d/t)',
                            labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                          onSaved: (val) => depth = double.tryParse(val ?? '') ?? depth,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: length.toString(),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Length (mm)',
                            labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                          onSaved: (val) => length = double.tryParse(val ?? '') ?? length,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Repair Method
                  DropdownButtonFormField<RepairMethodology>(
                    initialValue: repair,
                    dropdownColor: const Color(0xFF162347),
                    style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 12),
                    decoration: const InputDecoration(
                      labelText: 'Recommended Repair Method',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    items: RepairMethodology.values.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) repair = val;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        formKey.currentState?.save();
                        final newId = 'DIG-2026-00${_digWorkOrders.length + 1}';
                        setState(() {
                          _digWorkOrders.insert(
                            0,
                            DigWorkOrder(
                              id: newId,
                              segmentId: segId,
                              chainageStr: chainage,
                              locationName: location,
                              gpsLat: 27.2500,
                              gpsLong: 95.2800,
                              defectDepthPercent: depth,
                              defectLengthMm: length,
                              defectWidthMm: 35.0,
                              clockPosition: '6:00',
                              erf: depth >= 60.0 ? 1.12 : 0.98,
                              priority: depth >= 60.0 ? DigPriority.immediate : priority,
                              repairMethod: repair,
                              rowClearance: 'Site RoW Verification Pending',
                              assignedCrew: 'Integrity Gang Alpha (Lead: Eng. B. Borah)',
                              status: DigStatus.planned,
                              targetDate: DateTime.now().add(const Duration(days: 30)),
                              fieldNotes: 'Newly initiated verification bell-hole.',
                            ),
                          );
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$newId created successfully.'),
                            backgroundColor: const Color(0xFF0284C7),
                          ),
                        );
                      },
                      child: const Text('Issue Work Order', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDigDossierSheet(DigWorkOrder order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111C38),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_rounded, color: Color(0xFFFFB95F)),
                  const SizedBox(width: 8),
                  Text(
                    'ASME PCC-2 Repair Dossier: ${order.id}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF1F5F9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Repair Tech: ${order.repairMethod.name}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(height: 4),
              Text(
                order.repairMethod.description,
                style: const TextStyle(fontSize: 11, color: Color(0xFFF1F5F9)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF162347),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Applicable Code', order.repairMethod.standardCode),
                    _buildDetailRow('Field Notes', order.fieldNotes),
                    _buildDetailRow('Permit Status', order.rowClearance),
                    _buildDetailRow('Assigned Gang', order.assignedCrew),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('Print Bell-Hole Work Pack'),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ASME PCC-2 Work Pack generated & ready for offline crew.'),
                        backgroundColor: Color(0xFF0284C7),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAsmeGuidelinesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111C38),
          title: const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: Color(0xFFFFB95F)),
              SizedBox(width: 8),
              Text(
                'ASME B31.8S / API 1160 Rules',
                style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 16),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1. 5x5 Quantitative Risk Assessment (QRA)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Risk Score = PoF × CoF. Critical (≥16) requires immediate MAOP derating or 30-day sleeve encapsulation.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                SizedBox(height: 10),
                Text(
                  '2. Remnant Strength (Modified B31G & RSTRENG)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Flow stress Sflow = SMYS + 68.95 MPa. Effective area factor 0.85dL. If ERF = MAOP / P_safe > 1.0, pressure derating is mandatory.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                SizedBox(height: 10),
                Text(
                  '3. Re-assessment Half-Life Rule',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Re-assessment Interval = (Time to 80% Wall Loss) / 2. Statutory cap: 5 yrs for HCA / 10 yrs for rural Class 1.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                SizedBox(height: 10),
                Text(
                  '4. ASME PCC-2 Repair Criteria',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Type B Steel Sleeve for deep pitting (>60%) and planar flaws. Composite Carbon Sleeve (Clock Spring) for non-leaking corrosion without shutdown.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _exportPimsDossier() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting ASME B31.8S Quantitative Risk Assessment PDF dossier...'),
        backgroundColor: Color(0xFF0284C7),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER: PIPE DEFECT WALL-LOSS CROSS SECTION
// ============================================================================

class _PipeCrossSectionPainter extends CustomPainter {
  final double wt;
  final double depth;
  final double defectLength;
  final double depthRatio; // 0.0 to 1.0
  final bool isInternal;

  _PipeCrossSectionPainter({
    required this.wt,
    required this.depth,
    required this.defectLength,
    required this.depthRatio,
    required this.isInternal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background Cyber Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF26396E).withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    for (double x = 0; x < w; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    const double wallTopY = 16.0;
    const double wallBottomY = 74.0;
    final double wallThicknessVisual = wallBottomY - wallTopY;

    // Pipe Steel Wall Base
    final steelPaint = Paint()
      ..color = const Color(0xFF1A365D)
      ..style = PaintingStyle.fill;
    final steelBorderPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Draw intact pipe wall rectangle
    final wallRect = Rect.fromLTWH(0, wallTopY, w, wallThicknessVisual);
    canvas.drawRect(wallRect, steelPaint);

    // Defect Crater geometry
    final double craterWidth = (defectLength * 1.2).clamp(40.0, w * 0.7);
    final double craterCenterX = w / 2;
    final double craterLeftX = craterCenterX - (craterWidth / 2);
    final double craterRightX = craterCenterX + (craterWidth / 2);
    final double defectDepthVisual = (depthRatio * wallThicknessVisual).clamp(4.0, wallThicknessVisual - 2);

    final Path defectPath = Path();
    if (!isInternal) {
      // External Corrosion (Bites into the outer wall from wallTopY down)
      defectPath.moveTo(craterLeftX, wallTopY);
      defectPath.cubicTo(
        craterLeftX + craterWidth * 0.25,
        wallTopY + defectDepthVisual,
        craterRightX - craterWidth * 0.25,
        wallTopY + defectDepthVisual,
        craterRightX,
        wallTopY,
      );
      defectPath.lineTo(craterLeftX, wallTopY);
      defectPath.close();
    } else {
      // Internal Corrosion (Bites into the inner wall from wallBottomY up)
      defectPath.moveTo(craterLeftX, wallBottomY);
      defectPath.cubicTo(
        craterLeftX + craterWidth * 0.25,
        wallBottomY - defectDepthVisual,
        craterRightX - craterWidth * 0.25,
        wallBottomY - defectDepthVisual,
        craterRightX,
        wallBottomY,
      );
      defectPath.lineTo(craterLeftX, wallBottomY);
      defectPath.close();
    }

    // Color of defect pit based on severity
    Color defectColor;
    if (depthRatio >= 0.80) {
      defectColor = const Color(0xFFEF4444);
    } else if (depthRatio >= 0.50) {
      defectColor = const Color(0xFFFFB95F);
    } else {
      defectColor = const Color(0xFF4EDEA3);
    }

    final defectFillPaint = Paint()
      ..color = const Color(0xFF0B1326)
      ..style = PaintingStyle.fill;
    final defectBorderPaint = Paint()
      ..color = defectColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Void out the defect from the pipe wall
    canvas.drawPath(defectPath, defectFillPaint);
    canvas.drawPath(defectPath, defectBorderPaint);

    // Outer & Inner Pipe Boundary lines
    canvas.drawLine(const Offset(0, wallTopY), Offset(craterLeftX, wallTopY), steelBorderPaint);
    canvas.drawLine(Offset(craterRightX, wallTopY), Offset(w, wallTopY), steelBorderPaint);
    canvas.drawLine(const Offset(0, wallBottomY), Offset(w, wallBottomY), steelBorderPaint);

    // Callout Dimension Arrows for Defect Depth
    final arrowPaint = Paint()
      ..color = defectColor
      ..strokeWidth = 1.0;

    // Center vertical arrow
    final double pitBottomY = wallTopY + defectDepthVisual;
    canvas.drawLine(Offset(craterCenterX, wallTopY), Offset(craterCenterX, pitBottomY), arrowPaint);
    canvas.drawLine(Offset(craterCenterX - 3, wallTopY + 3), Offset(craterCenterX, wallTopY), arrowPaint);
    canvas.drawLine(Offset(craterCenterX + 3, wallTopY + 3), Offset(craterCenterX, wallTopY), arrowPaint);
    canvas.drawLine(Offset(craterCenterX - 3, pitBottomY - 3), Offset(craterCenterX, pitBottomY), arrowPaint);
    canvas.drawLine(Offset(craterCenterX + 3, pitBottomY - 3), Offset(craterCenterX, pitBottomY), arrowPaint);

    // Remaining Ligament Indicator
    final ligamentPaint = Paint()
      ..color = const Color(0xFF4EDEA3)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(craterCenterX + 25, pitBottomY), Offset(craterCenterX + 25, wallBottomY), ligamentPaint);

    // Text labels in canvas
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'd=${depth.toStringAsFixed(1)}mm',
        style: TextStyle(
          color: defectColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(craterCenterX + 4, wallTopY + 4));
  }

  @override
  bool shouldRepaint(covariant _PipeCrossSectionPainter oldDelegate) {
    return oldDelegate.wt != wt ||
        oldDelegate.depth != depth ||
        oldDelegate.defectLength != defectLength ||
        oldDelegate.depthRatio != depthRatio ||
        oldDelegate.isInternal != isInternal;
  }
}
