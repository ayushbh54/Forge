import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';

// ============================================================================
// DOMAIN MODELS & ENUMS
// Standards: NACE SP0188 / DIN 30670 / ISO 21809-3 / ISO 8501-1 / ISO 8502-6,9
// ============================================================================

enum CoatingSystemType {
  hssMastic, // Heat Shrinkable Sleeve + Liquid Epoxy Primer (Canusa / Raychem)
  threeLpe, // 3-Layer Polyethylene (Liquid Epoxy/FBE + Copolymer + HDPE)
  viscoElastic, // Visco-Elastic wrapping tape + mechanical outer wrap
  liquidEpoxy100, // 100% Solids Two-component liquid epoxy (Protal / Denso)
}

extension CoatingSystemTypeExt on CoatingSystemType {
  String get label {
    switch (this) {
      case CoatingSystemType.hssMastic:
        return 'HSS + Liquid Epoxy Primer (DIN 30670 / ISO 21809-3)';
      case CoatingSystemType.threeLpe:
        return '3LPE Field Joint System (FBE + Copolymer + HDPE)';
      case CoatingSystemType.viscoElastic:
        return 'Visco-Elastic System + Polymeric Outer Wrap';
      case CoatingSystemType.liquidEpoxy100:
        return '100% Solids Solvent-Free Liquid Epoxy (Protal 7200)';
    }
  }

  String get shortLabel {
    switch (this) {
      case CoatingSystemType.hssMastic:
        return 'HSS Mastic + Epoxy';
      case CoatingSystemType.threeLpe:
        return '3LPE FJC System';
      case CoatingSystemType.viscoElastic:
        return 'Visco-Elastic Wrap';
      case CoatingSystemType.liquidEpoxy100:
        return '100% Liquid Epoxy';
    }
  }

  double get nominalTotalDftMm {
    switch (this) {
      case CoatingSystemType.hssMastic:
        return 2.80; // 2.8 mm
      case CoatingSystemType.threeLpe:
        return 3.00; // 3.0 mm
      case CoatingSystemType.viscoElastic:
        return 2.50; // 2.5 mm
      case CoatingSystemType.liquidEpoxy100:
        return 1.25; // 1.25 mm (1250 µm)
    }
  }

  double get minOverlapMm {
    switch (this) {
      case CoatingSystemType.hssMastic:
      case CoatingSystemType.threeLpe:
        return 50.0; // Min 50 mm onto factory 3LPE bevel
      case CoatingSystemType.viscoElastic:
        return 75.0; // 75 mm overlap
      case CoatingSystemType.liquidEpoxy100:
        return 50.0;
    }
  }

  double get targetPreheatMinC {
    switch (this) {
      case CoatingSystemType.hssMastic:
        return 200.0;
      case CoatingSystemType.threeLpe:
        return 210.0;
      case CoatingSystemType.viscoElastic:
        return 60.0;
      case CoatingSystemType.liquidEpoxy100:
        return 70.0;
    }
  }

  double get targetPreheatMaxC {
    switch (this) {
      case CoatingSystemType.hssMastic:
        return 230.0;
      case CoatingSystemType.threeLpe:
        return 235.0;
      case CoatingSystemType.viscoElastic:
        return 90.0;
      case CoatingSystemType.liquidEpoxy100:
        return 100.0;
    }
  }
}

enum SurfacePreparationStandard {
  iso8501Sa2_5, // Near-White Metal (SSPC-SP 10 / NACE No. 2)
  iso8501Sa3, // White Metal Blast (SSPC-SP 5 / NACE No. 1)
  iso8501St3, // Very thorough power tool cleaning
}

extension SurfacePreparationStandardExt on SurfacePreparationStandard {
  String get label {
    switch (this) {
      case SurfacePreparationStandard.iso8501Sa2_5:
        return 'ISO 8501-1 Sa 2.5 (SSPC-SP 10 Near-White)';
      case SurfacePreparationStandard.iso8501Sa3:
        return 'ISO 8501-1 Sa 3.0 (SSPC-SP 5 White Metal)';
      case SurfacePreparationStandard.iso8501St3:
        return 'ISO 8501-1 St 3 (Power Tool Cleaning)';
    }
  }

  String get shortCode {
    switch (this) {
      case SurfacePreparationStandard.iso8501Sa2_5:
        return 'Sa 2.5';
      case SurfacePreparationStandard.iso8501Sa3:
        return 'Sa 3.0';
      case SurfacePreparationStandard.iso8501St3:
        return 'St 3';
    }
  }

  bool get isApprovedForBuriedPipe => this != SurfacePreparationStandard.iso8501St3;
}

enum JointQaStatus {
  prepPending,
  preheating,
  coated,
  holidayTesting,
  holidayDefect,
  repairedPendingTest,
  peelTesting,
  fullyCertified,
}

extension JointQaStatusExt on JointQaStatus {
  String get label {
    switch (this) {
      case JointQaStatus.prepPending:
        return 'Grit Blast & Surface Prep';
      case JointQaStatus.preheating:
        return 'MF Induction Preheating';
      case JointQaStatus.coated:
        return 'Coated & Shrink Recovered';
      case JointQaStatus.holidayTesting:
        return 'HV Holiday Spark Testing';
      case JointQaStatus.holidayDefect:
        return 'HOLIDAY DEFECT (Hold)';
      case JointQaStatus.repairedPendingTest:
        return 'Patch Repaired (Re-Test)';
      case JointQaStatus.peelTesting:
        return 'DIN 30670 Peel Adhesion';
      case JointQaStatus.fullyCertified:
        return 'CERTIFIED (Zero-Defect Release)';
    }
  }

  Color get color {
    switch (this) {
      case JointQaStatus.prepPending:
        return const Color(0xFF94A3B8); // Slate
      case JointQaStatus.preheating:
        return const Color(0xFFFFB95F); // Amber
      case JointQaStatus.coated:
        return const Color(0xFF38BDF8); // Cyan
      case JointQaStatus.holidayTesting:
        return const Color(0xFFA78BFA); // Purple
      case JointQaStatus.holidayDefect:
        return const Color(0xFFEF4444); // Red
      case JointQaStatus.repairedPendingTest:
        return const Color(0xFFFB923C); // Orange
      case JointQaStatus.peelTesting:
        return const Color(0xFF0284C7); // Primary Blue
      case JointQaStatus.fullyCertified:
        return const Color(0xFF4EDEA3); // Tertiary Green
    }
  }

  IconData get icon {
    switch (this) {
      case JointQaStatus.prepPending:
        return Icons.cleaning_services_rounded;
      case JointQaStatus.preheating:
        return Icons.local_fire_department_rounded;
      case JointQaStatus.coated:
        return Icons.layers_rounded;
      case JointQaStatus.holidayTesting:
        return Icons.flash_on_rounded;
      case JointQaStatus.holidayDefect:
        return Icons.report_problem_rounded;
      case JointQaStatus.repairedPendingTest:
        return Icons.build_circle_rounded;
      case JointQaStatus.peelTesting:
        return Icons.fitness_center_rounded;
      case JointQaStatus.fullyCertified:
        return Icons.verified_user_rounded;
    }
  }

  int get stageStep {
    switch (this) {
      case JointQaStatus.prepPending:
        return 1;
      case JointQaStatus.preheating:
        return 2;
      case JointQaStatus.coated:
        return 3;
      case JointQaStatus.holidayTesting:
      case JointQaStatus.holidayDefect:
      case JointQaStatus.repairedPendingTest:
        return 4;
      case JointQaStatus.peelTesting:
        return 5;
      case JointQaStatus.fullyCertified:
        return 6;
    }
  }
}

enum PeelFailureMode {
  cohesiveMastic, // >95% adhesive residue on steel - PASS
  cohesivePrimer, // Failure within primer layer - PASS
  adhesiveSteel, // Clean peel off steel substrate - REJECT
  intercoatBacking, // Delamination between backing & mastic - REJECT
}

extension PeelFailureModeExt on PeelFailureMode {
  String get label {
    switch (this) {
      case PeelFailureMode.cohesiveMastic:
        return 'Cohesive in Adhesive Mastic (>95% Residue)';
      case PeelFailureMode.cohesivePrimer:
        return 'Cohesive in Epoxy Primer Layer';
      case PeelFailureMode.adhesiveSteel:
        return 'Adhesive Failure at Steel Surface (Bare Metal)';
      case PeelFailureMode.intercoatBacking:
        return 'Intercoat Delamination (Backing / Mastic)';
    }
  }

  bool get isAcceptable =>
      this == PeelFailureMode.cohesiveMastic || this == PeelFailureMode.cohesivePrimer;

  Color get color => isAcceptable ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444);
}

class HolidayDefectRecord {
  final String id;
  final int clockHour; // 1 to 12
  final int clockMinute; // 0 to 59
  final double distFromWeldCenterMm; // e.g. -35mm to +35mm
  final double voltageKv;
  final String description;
  final String repairMethod;
  final bool retestPass;
  final DateTime detectedAt;
  final DateTime? repairedAt;

  const HolidayDefectRecord({
    required this.id,
    required this.clockHour,
    required this.clockMinute,
    required this.distFromWeldCenterMm,
    required this.voltageKv,
    required this.description,
    required this.repairMethod,
    required this.retestPass,
    required this.detectedAt,
    this.repairedAt,
  });

  String get clockOrientation =>
      '${clockHour.toString().padLeft(2, '0')}:${clockMinute.toString().padLeft(2, '0')}';
}

class FieldJointRecord {
  final String id;
  final String weldNumber;
  final double chainageKm;
  final String chainageStr;
  final String spoolAhead;
  final String spoolBack;
  final double pipeOdMm;
  final double wallThicknessMm;
  final String steelGrade;
  final CoatingSystemType coatingSystem;
  final String contractor;
  final String inspectorName;
  final String tpiInspector;
  final JointQaStatus status;

  // 1. Surface Preparation (ISO 8501-1 Sa 2.5, ASTM D4417, ISO 8502-6/9)
  final SurfacePreparationStandard blastStandard;
  final String blastMedium;
  final double ambientTempC;
  final double relativeHumidityPct;
  final double dewPointC;
  final double pipeSurfaceTempC;
  final Map<String, double> profileDepthUmClock; // '12:00', '3:00', '6:00', '9:00'
  final double bresleConductivityInitialUs;
  final double bresleConductivityFinalUs;
  final double bresleSaltDensityUgCm2;
  final int dustTapeClass; // ISO 8502-3: 1 to 5

  // 2. Induction Preheating (DIN 30670 / ISO 21809-3)
  final double inductionCoilPowerKw;
  final double inductionFrequencyKhz;
  final int heatingDurationSec;
  final Map<String, double> pyrometerTempClockC; // '12:00', '3:00', '6:00', '9:00'
  final bool preheatVerified;

  // 3. Coating Application
  final String epoxyBatchNumber;
  final String sleeveBatchNumber;
  final double primerWftUm;
  final double primerDftUm;
  final double sleeveOverlapMmAhead;
  final double sleeveOverlapMmBack;
  final Map<String, double> totalDftMmClock; // 8 clock positions
  final bool masticExtrusionVisual;

  // 4. HV Holiday Testing (NACE SP0188)
  final double holidayTestVoltageKv;
  final String sparkDetectorModel;
  final int holidaysDetected;
  final List<HolidayDefectRecord> holidayRecords;
  final bool holidayTestedPassed;

  // 5. DIN 30670 Peel Adhesion Testing
  final bool peelTested;
  final double peelTestTempC;
  final double peelStripWidthMm;
  final double peelRateMmPerMin;
  final double peelMeanForceNPerCm;
  final double peelPeakForceNPerCm;
  final double peelMinForceNPerCm;
  final PeelFailureMode peelFailureMode;
  final List<double> peelDisplacementLoads; // Force over 100mm travel

  // QA Dossier & Sign-off
  final bool tpiWitnessed;
  final DateTime inspectionDate;
  final String dossierHashSha256;
  final String loweringReleasePermitNo;

  const FieldJointRecord({
    required this.id,
    required this.weldNumber,
    required this.chainageKm,
    required this.chainageStr,
    required this.spoolAhead,
    required this.spoolBack,
    required this.pipeOdMm,
    required this.wallThicknessMm,
    required this.steelGrade,
    required this.coatingSystem,
    required this.contractor,
    required this.inspectorName,
    required this.tpiInspector,
    required this.status,
    required this.blastStandard,
    required this.blastMedium,
    required this.ambientTempC,
    required this.relativeHumidityPct,
    required this.dewPointC,
    required this.pipeSurfaceTempC,
    required this.profileDepthUmClock,
    required this.bresleConductivityInitialUs,
    required this.bresleConductivityFinalUs,
    required this.bresleSaltDensityUgCm2,
    required this.dustTapeClass,
    required this.inductionCoilPowerKw,
    required this.inductionFrequencyKhz,
    required this.heatingDurationSec,
    required this.pyrometerTempClockC,
    required this.preheatVerified,
    required this.epoxyBatchNumber,
    required this.sleeveBatchNumber,
    required this.primerWftUm,
    required this.primerDftUm,
    required this.sleeveOverlapMmAhead,
    required this.sleeveOverlapMmBack,
    required this.totalDftMmClock,
    required this.masticExtrusionVisual,
    required this.holidayTestVoltageKv,
    required this.sparkDetectorModel,
    required this.holidaysDetected,
    required this.holidayRecords,
    required this.holidayTestedPassed,
    required this.peelTested,
    required this.peelTestTempC,
    required this.peelStripWidthMm,
    required this.peelRateMmPerMin,
    required this.peelMeanForceNPerCm,
    required this.peelPeakForceNPerCm,
    required this.peelMinForceNPerCm,
    required this.peelFailureMode,
    required this.peelDisplacementLoads,
    required this.tpiWitnessed,
    required this.inspectionDate,
    required this.dossierHashSha256,
    required this.loweringReleasePermitNo,
  });

  // Computed Properties & Compliance Checks
  double get meanProfileDepthUm {
    if (profileDepthUmClock.isEmpty) return 0.0;
    final sum = profileDepthUmClock.values.fold(0.0, (a, b) => a + b);
    return sum / profileDepthUmClock.length;
  }

  // Anchor profile requirement: 50 - 75 µm (ASTM D4417 / ISO 8503)
  bool get isProfileCompliant => meanProfileDepthUm >= 50.0 && meanProfileDepthUm <= 75.0;

  // Salt contamination requirement: < 2.0 µg/cm² (ISO 8502-9 Bresle patch)
  bool get isBresleCompliant => bresleSaltDensityUgCm2 < 2.0;

  // Psychrometry check: Steel temp >= Dew point + 3.0°C and RH <= 85%
  bool get isPsychrometryCompliant =>
      (pipeSurfaceTempC >= dewPointC + 3.0) && (relativeHumidityPct <= 85.0);

  double get meanPreheatTempC {
    if (pyrometerTempClockC.isEmpty) return 0.0;
    final sum = pyrometerTempClockC.values.fold(0.0, (a, b) => a + b);
    return sum / pyrometerTempClockC.length;
  }

  double get preheatDeltaC {
    if (pyrometerTempClockC.isEmpty) return 0.0;
    final max = pyrometerTempClockC.values.reduce(math.max);
    final min = pyrometerTempClockC.values.reduce(math.min);
    return max - min;
  }

  // Induction Pre-heating requirement: 200°C - 230°C and delta <= 15°C
  bool get isPreheatCompliant =>
      meanPreheatTempC >= coatingSystem.targetPreheatMinC &&
      meanPreheatTempC <= coatingSystem.targetPreheatMaxC &&
      preheatDeltaC <= 15.0;

  double get meanTotalDftMm {
    if (totalDftMmClock.isEmpty) return 0.0;
    final sum = totalDftMmClock.values.fold(0.0, (a, b) => a + b);
    return sum / totalDftMmClock.length;
  }

  bool get isOverlapCompliant =>
      sleeveOverlapMmAhead >= coatingSystem.minOverlapMm &&
      sleeveOverlapMmBack >= coatingSystem.minOverlapMm;

  // HV Holiday Voltage Rule: 5 kV / mm DFT (DIN 30670 / NACE SP0188)
  double get calculatedHolidayVoltageKv => (meanTotalDftMm * 5.0).clamp(15.0, 25.0);

  // NACE SP0188 Mil formula for comparison: V = 3294 * sqrt(DFT_mils)
  double get naceRuleVoltageKv {
    final mils = meanTotalDftMm * 39.3701;
    final v = 3294.0 * math.sqrt(mils) / 1000.0;
    return v.clamp(15.0, 25.0);
  }

  bool get hasActiveHolidays =>
      holidaysDetected > 0 && holidayRecords.any((rec) => !rec.retestPass);

  bool get isHolidayCompliant => holidayTestedPassed && !hasActiveHolidays;

  // DIN 30670 Peel strength requirement: > 100 N/cm at 23°C & cohesive failure
  bool get isPeelCompliant {
    if (!peelTested) return true; // not all joints undergo destructive/coupon peel test
    return peelMeanForceNPerCm >= 100.0 && peelFailureMode.isAcceptable;
  }

  bool get isZeroDefectCertified =>
      isProfileCompliant &&
      isBresleCompliant &&
      isPsychrometryCompliant &&
      isPreheatCompliant &&
      isOverlapCompliant &&
      masticExtrusionVisual &&
      isHolidayCompliant &&
      isPeelCompliant &&
      status == JointQaStatus.fullyCertified;

  static String generateCertificateHash(String id, String weld, double ch, double peel, int hol) {
    final payload = 'FJC-NIRMAAN-$id-$weld-${ch.toStringAsFixed(3)}-$peel-$hol-DIN30670-NACESP0188';
    return sha256.convert(utf8.encode(payload)).toString();
  }
}

// ============================================================================
// MOCK DATASET (Duliajan - Digboi - Numaligarh Gas Pipeline Project)
// ============================================================================

final List<FieldJointRecord> kMockFieldJoints = [
  FieldJointRecord(
    id: 'FJ-18-042',
    weldNumber: 'GW-42',
    chainageKm: 14.850,
    chainageStr: 'KP 14+850',
    spoolAhead: 'SP-18-042',
    spoolBack: 'SP-18-041',
    pipeOdMm: 457.2,
    wallThicknessMm: 9.52,
    steelGrade: 'API 5L X70 PSL2',
    coatingSystem: CoatingSystemType.hssMastic,
    contractor: 'Punj Lloyd - Kalpataru JV',
    inspectorName: 'Er. Rajesh Verma (NACE CIP Level 3)',
    tpiInspector: 'Er. S. Bhattacharya (EIL TPI)',
    status: JointQaStatus.fullyCertified,
    blastStandard: SurfacePreparationStandard.iso8501Sa2_5,
    blastMedium: 'Chilled Iron Grit GL-25 / Garnet 20/40',
    ambientTempC: 28.5,
    relativeHumidityPct: 62.0,
    dewPointC: 20.4,
    pipeSurfaceTempC: 31.8,
    profileDepthUmClock: const {
      '12:00': 64.0,
      '3:00': 61.5,
      '6:00': 67.2,
      '9:00': 63.8,
    },
    bresleConductivityInitialUs: 2.1,
    bresleConductivityFinalUs: 11.8,
    bresleSaltDensityUgCm2: 0.85,
    dustTapeClass: 1,
    inductionCoilPowerKw: 88.5,
    inductionFrequencyKhz: 3.45,
    heatingDurationSec: 46,
    pyrometerTempClockC: const {
      '12:00': 216.5,
      '3:00': 222.0,
      '6:00': 214.0,
      '9:00': 219.5,
    },
    preheatVerified: true,
    epoxyBatchNumber: 'EP-2026-X88',
    sleeveBatchNumber: 'HSS-WPC100-9441',
    primerWftUm: 185.0,
    primerDftUm: 130.0,
    sleeveOverlapMmAhead: 68.0,
    sleeveOverlapMmBack: 64.0,
    totalDftMmClock: const {
      '12:00': 2.82,
      '1:30': 2.78,
      '3:00': 2.86,
      '4:30': 2.91,
      '6:00': 2.84,
      '7:30': 2.79,
      '9:00': 2.85,
      '10:30': 2.80,
    },
    masticExtrusionVisual: true,
    holidayTestVoltageKv: 20.0,
    sparkDetectorModel: 'Spy Model 785 High-Voltage DC Pulse',
    holidaysDetected: 0,
    holidayRecords: const [],
    holidayTestedPassed: true,
    peelTested: true,
    peelTestTempC: 23.0,
    peelStripWidthMm: 25.0,
    peelRateMmPerMin: 10.0,
    peelMeanForceNPerCm: 148.5,
    peelPeakForceNPerCm: 172.0,
    peelMinForceNPerCm: 124.0,
    peelFailureMode: PeelFailureMode.cohesiveMastic,
    peelDisplacementLoads: const [
      120.0, 132.0, 144.0, 155.0, 168.0, 172.0, 160.0, 148.0, 142.0, 146.0,
      150.0, 147.0, 149.0, 145.0, 148.0, 151.0, 149.0, 146.0, 148.5, 149.0
    ],
    tpiWitnessed: true,
    inspectionDate: DateTime(2026, 9, 28, 14, 30),
    dossierHashSha256: '9a7e2b14c33d87f540b991ae9f57871239cdfe801124698ea019bbdc77123aa1',
    loweringReleasePermitNo: 'OIL-NIRM-RLP-2026-042',
  ),
  FieldJointRecord(
    id: 'FJ-18-043',
    weldNumber: 'GW-43',
    chainageKm: 15.220,
    chainageStr: 'KP 15+220',
    spoolAhead: 'SP-18-043',
    spoolBack: 'SP-18-042',
    pipeOdMm: 457.2,
    wallThicknessMm: 9.52,
    steelGrade: 'API 5L X70 PSL2',
    coatingSystem: CoatingSystemType.threeLpe,
    contractor: 'Punj Lloyd - Kalpataru JV',
    inspectorName: 'Er. Rajesh Verma (NACE CIP Level 3)',
    tpiInspector: 'Er. S. Bhattacharya (EIL TPI)',
    status: JointQaStatus.fullyCertified,
    blastStandard: SurfacePreparationStandard.iso8501Sa2_5,
    blastMedium: 'Chilled Iron Grit GL-25 / Garnet 20/40',
    ambientTempC: 29.0,
    relativeHumidityPct: 65.0,
    dewPointC: 21.6,
    pipeSurfaceTempC: 33.2,
    profileDepthUmClock: const {
      '12:00': 68.0,
      '3:00': 64.0,
      '6:00': 71.0,
      '9:00': 66.5,
    },
    bresleConductivityInitialUs: 2.3,
    bresleConductivityFinalUs: 13.5,
    bresleSaltDensityUgCm2: 0.98,
    dustTapeClass: 1,
    inductionCoilPowerKw: 92.0,
    inductionFrequencyKhz: 3.50,
    heatingDurationSec: 50,
    pyrometerTempClockC: const {
      '12:00': 224.0,
      '3:00': 228.5,
      '6:00': 221.0,
      '9:00': 226.0,
    },
    preheatVerified: true,
    epoxyBatchNumber: '3LPE-FBE-1092',
    sleeveBatchNumber: '3LPE-PE-CAN-8812',
    primerWftUm: 200.0,
    primerDftUm: 145.0,
    sleeveOverlapMmAhead: 72.0,
    sleeveOverlapMmBack: 70.0,
    totalDftMmClock: const {
      '12:00': 3.05,
      '1:30': 3.12,
      '3:00': 3.08,
      '4:30': 3.15,
      '6:00': 3.02,
      '7:30': 3.09,
      '9:00': 3.14,
      '10:30': 3.06,
    },
    masticExtrusionVisual: true,
    holidayTestVoltageKv: 22.5,
    sparkDetectorModel: 'Tinker & Rasor APS High-Voltage Holiday Detector',
    holidaysDetected: 0,
    holidayRecords: const [],
    holidayTestedPassed: true,
    peelTested: true,
    peelTestTempC: 23.0,
    peelStripWidthMm: 25.0,
    peelRateMmPerMin: 10.0,
    peelMeanForceNPerCm: 162.0,
    peelPeakForceNPerCm: 188.5,
    peelMinForceNPerCm: 140.0,
    peelFailureMode: PeelFailureMode.cohesiveMastic,
    peelDisplacementLoads: const [
      135.0, 148.0, 158.0, 172.0, 185.0, 188.5, 174.0, 165.0, 160.0, 162.0,
      164.0, 161.0, 163.0, 160.0, 162.0, 165.0, 162.0, 161.0, 162.0, 162.5
    ],
    tpiWitnessed: true,
    inspectionDate: DateTime(2026, 9, 28, 16, 45),
    dossierHashSha256: '4b3f81e0129c90daeef781204cba765109fecd1894aa1b332b7810aa493d2208',
    loweringReleasePermitNo: 'OIL-NIRM-RLP-2026-043',
  ),
  FieldJointRecord(
    id: 'FJ-18-044',
    weldNumber: 'GW-44',
    chainageKm: 15.600,
    chainageStr: 'KP 15+600',
    spoolAhead: 'SP-18-044',
    spoolBack: 'SP-18-043',
    pipeOdMm: 457.2,
    wallThicknessMm: 9.52,
    steelGrade: 'API 5L X70 PSL2',
    coatingSystem: CoatingSystemType.hssMastic,
    contractor: 'Punj Lloyd - Kalpataru JV',
    inspectorName: 'Er. Rajesh Verma (NACE CIP Level 3)',
    tpiInspector: 'Er. S. Bhattacharya (EIL TPI)',
    status: JointQaStatus.repairedPendingTest,
    blastStandard: SurfacePreparationStandard.iso8501Sa2_5,
    blastMedium: 'Chilled Iron Grit GL-25 / Garnet 20/40',
    ambientTempC: 30.1,
    relativeHumidityPct: 69.0,
    dewPointC: 23.5,
    pipeSurfaceTempC: 35.0,
    profileDepthUmClock: const {
      '12:00': 62.0,
      '3:00': 59.0,
      '6:00': 66.0,
      '9:00': 63.0,
    },
    bresleConductivityInitialUs: 2.0,
    bresleConductivityFinalUs: 14.2,
    bresleSaltDensityUgCm2: 1.05,
    dustTapeClass: 2,
    inductionCoilPowerKw: 86.0,
    inductionFrequencyKhz: 3.42,
    heatingDurationSec: 47,
    pyrometerTempClockC: const {
      '12:00': 214.0,
      '3:00': 218.0,
      '6:00': 211.0,
      '9:00': 215.0,
    },
    preheatVerified: true,
    epoxyBatchNumber: 'EP-2026-X88',
    sleeveBatchNumber: 'HSS-WPC100-9442',
    primerWftUm: 175.0,
    primerDftUm: 120.0,
    sleeveOverlapMmAhead: 65.0,
    sleeveOverlapMmBack: 62.0,
    totalDftMmClock: const {
      '12:00': 2.75,
      '1:30': 2.80,
      '3:00': 2.78,
      '4:30': 2.82,
      '6:00': 2.74,
      '7:30': 2.76,
      '9:00': 2.81,
      '10:30': 2.77,
    },
    masticExtrusionVisual: true,
    holidayTestVoltageKv: 20.0,
    sparkDetectorModel: 'Spy Model 785 High-Voltage DC Pulse',
    holidaysDetected: 1,
    holidayRecords: [
      HolidayDefectRecord(
        id: 'HD-FJ44-1',
        clockHour: 7,
        clockMinute: 30,
        distFromWeldCenterMm: -32.0,
        voltageKv: 20.0,
        description: 'Pinhole void spark discharge at 07:30 bevel transition',
        repairMethod: 'Chamfered 45°, Canusa PERP melt stick applied + HSS patch shrunk',
        retestPass: true,
        detectedAt: DateTime(2026, 9, 29, 9, 15),
        repairedAt: DateTime(2026, 9, 29, 10, 45),
      ),
    ],
    holidayTestedPassed: false,
    peelTested: false,
    peelTestTempC: 23.0,
    peelStripWidthMm: 25.0,
    peelRateMmPerMin: 10.0,
    peelMeanForceNPerCm: 0.0,
    peelPeakForceNPerCm: 0.0,
    peelMinForceNPerCm: 0.0,
    peelFailureMode: PeelFailureMode.cohesiveMastic,
    peelDisplacementLoads: const [],
    tpiWitnessed: false,
    inspectionDate: DateTime(2026, 9, 29, 9, 0),
    dossierHashSha256: 'Pending Repair Clearance',
    loweringReleasePermitNo: 'HOLD-REPAIR-044',
  ),
  FieldJointRecord(
    id: 'FJ-18-045',
    weldNumber: 'GW-45',
    chainageKm: 15.980,
    chainageStr: 'KP 15+980',
    spoolAhead: 'SP-18-045',
    spoolBack: 'SP-18-044',
    pipeOdMm: 457.2,
    wallThicknessMm: 9.52,
    steelGrade: 'API 5L X70 PSL2',
    coatingSystem: CoatingSystemType.hssMastic,
    contractor: 'Punj Lloyd - Kalpataru JV',
    inspectorName: 'Er. Rajesh Verma (NACE CIP Level 3)',
    tpiInspector: 'Er. S. Bhattacharya (EIL TPI)',
    status: JointQaStatus.holidayTesting,
    blastStandard: SurfacePreparationStandard.iso8501Sa2_5,
    blastMedium: 'Chilled Iron Grit GL-25 / Garnet 20/40',
    ambientTempC: 28.0,
    relativeHumidityPct: 61.0,
    dewPointC: 19.8,
    pipeSurfaceTempC: 31.5,
    profileDepthUmClock: const {
      '12:00': 65.0,
      '3:00': 62.0,
      '6:00': 69.0,
      '9:00': 64.0,
    },
    bresleConductivityInitialUs: 2.1,
    bresleConductivityFinalUs: 10.5,
    bresleSaltDensityUgCm2: 0.72,
    dustTapeClass: 1,
    inductionCoilPowerKw: 88.0,
    inductionFrequencyKhz: 3.45,
    heatingDurationSec: 45,
    pyrometerTempClockC: const {
      '12:00': 218.0,
      '3:00': 221.0,
      '6:00': 215.0,
      '9:00': 219.0,
    },
    preheatVerified: true,
    epoxyBatchNumber: 'EP-2026-X89',
    sleeveBatchNumber: 'HSS-WPC100-9443',
    primerWftUm: 180.0,
    primerDftUm: 128.0,
    sleeveOverlapMmAhead: 67.0,
    sleeveOverlapMmBack: 65.0,
    totalDftMmClock: const {
      '12:00': 2.80,
      '1:30': 2.84,
      '3:00': 2.82,
      '4:30': 2.85,
      '6:00': 2.78,
      '7:30': 2.81,
      '9:00': 2.83,
      '10:30': 2.80,
    },
    masticExtrusionVisual: true,
    holidayTestVoltageKv: 20.0,
    sparkDetectorModel: 'Spy Model 785 High-Voltage DC Pulse',
    holidaysDetected: 0,
    holidayRecords: const [],
    holidayTestedPassed: true,
    peelTested: false,
    peelTestTempC: 23.0,
    peelStripWidthMm: 25.0,
    peelRateMmPerMin: 10.0,
    peelMeanForceNPerCm: 0.0,
    peelPeakForceNPerCm: 0.0,
    peelMinForceNPerCm: 0.0,
    peelFailureMode: PeelFailureMode.cohesiveMastic,
    peelDisplacementLoads: const [],
    tpiWitnessed: false,
    inspectionDate: DateTime(2026, 9, 29, 14, 0),
    dossierHashSha256: 'In-Progress Signoff',
    loweringReleasePermitNo: 'PENDING-PEEL-SIGN',
  ),
  FieldJointRecord(
    id: 'FJ-18-046',
    weldNumber: 'GW-46',
    chainageKm: 16.350,
    chainageStr: 'KP 16+350',
    spoolAhead: 'SP-18-046',
    spoolBack: 'SP-18-045',
    pipeOdMm: 457.2,
    wallThicknessMm: 9.52,
    steelGrade: 'API 5L X70 PSL2',
    coatingSystem: CoatingSystemType.hssMastic,
    contractor: 'Punj Lloyd - Kalpataru JV',
    inspectorName: 'Er. Rajesh Verma (NACE CIP Level 3)',
    tpiInspector: 'Er. S. Bhattacharya (EIL TPI)',
    status: JointQaStatus.preheating,
    blastStandard: SurfacePreparationStandard.iso8501Sa2_5,
    blastMedium: 'Chilled Iron Grit GL-25 / Garnet 20/40',
    ambientTempC: 31.0,
    relativeHumidityPct: 58.0,
    dewPointC: 21.0,
    pipeSurfaceTempC: 36.0,
    profileDepthUmClock: const {
      '12:00': 63.0,
      '3:00': 60.0,
      '6:00': 68.0,
      '9:00': 62.0,
    },
    bresleConductivityInitialUs: 2.2,
    bresleConductivityFinalUs: 12.0,
    bresleSaltDensityUgCm2: 0.86,
    dustTapeClass: 1,
    inductionCoilPowerKw: 85.0,
    inductionFrequencyKhz: 3.40,
    heatingDurationSec: 32,
    pyrometerTempClockC: const {
      '12:00': 208.0,
      '3:00': 212.0,
      '6:00': 204.0,
      '9:00': 209.0,
    },
    preheatVerified: false,
    epoxyBatchNumber: 'EP-2026-X90',
    sleeveBatchNumber: 'HSS-WPC100-9444',
    primerWftUm: 0.0,
    primerDftUm: 0.0,
    sleeveOverlapMmAhead: 0.0,
    sleeveOverlapMmBack: 0.0,
    totalDftMmClock: const {},
    masticExtrusionVisual: false,
    holidayTestVoltageKv: 20.0,
    sparkDetectorModel: 'Spy Model 785 High-Voltage DC Pulse',
    holidaysDetected: 0,
    holidayRecords: const [],
    holidayTestedPassed: false,
    peelTested: false,
    peelTestTempC: 23.0,
    peelStripWidthMm: 25.0,
    peelRateMmPerMin: 10.0,
    peelMeanForceNPerCm: 0.0,
    peelPeakForceNPerCm: 0.0,
    peelMinForceNPerCm: 0.0,
    peelFailureMode: PeelFailureMode.cohesiveMastic,
    peelDisplacementLoads: const [],
    tpiWitnessed: false,
    inspectionDate: DateTime(2026, 9, 30, 8, 0),
    dossierHashSha256: 'Active Induction',
    loweringReleasePermitNo: 'STG-PREHEAT-046',
  ),
];

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class FieldJointCoatingScreen extends StatefulWidget {
  const FieldJointCoatingScreen({super.key});

  @override
  State<FieldJointCoatingScreen> createState() => _FieldJointCoatingScreenState();
}

class _FieldJointCoatingScreenState extends State<FieldJointCoatingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<FieldJointRecord> _joints = List.from(kMockFieldJoints);
  late FieldJointRecord _selectedJoint;

  String _filterStatus = 'ALL'; // ALL, CERTIFIED, REPAIR, TESTING, PREHEAT

  // Real-time Induction Simulator state
  bool _isInductionSimRunning = false;
  Timer? _inductionTimer;
  double _currentSimTempC = 214.0;
  double _inductionPowerKw = 88.0;
  int _inductionElapsedSec = 45;
  final List<FlSpot> _inductionLiveCurve = [
    const FlSpot(0, 32),
    const FlSpot(10, 85),
    const FlSpot(20, 140),
    const FlSpot(30, 185),
    const FlSpot(40, 210),
    const FlSpot(45, 218),
  ];

  // HV Holiday Spark Scanner Simulator
  bool _isHolidayScanning = false;
  double _scannerAngleDeg = 45.0; // 0 to 360 degrees
  Timer? _holidayScanTimer;
  double _sparkVoltageKv = 20.0;
  bool _sparkDefectTriggered = false;

  // DIN 30670 Peel Bench Simulator
  double _peelDisplacementMm = 65.0;
  double _currentPeelForceNPerCm = 146.5;

  // Bresle Patch Interactive Calculator
  double _bresleWaterVolumeMl = 3.0;
  double _bresleInitialUs = 2.1;
  double _bresleFinalUs = 12.5;
  double _breslePatchAreaCm2 = 12.5;

  // Custom Holiday Voltage Calculator
  double _calcCustomDftMm = 2.80;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _selectedJoint = _joints.first;
    _sparkVoltageKv = _selectedJoint.calculatedHolidayVoltageKv;
  }

  @override
  void dispose() {
    _inductionTimer?.cancel();
    _holidayScanTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _selectJoint(FieldJointRecord joint) {
    setState(() {
      _selectedJoint = joint;
      _sparkVoltageKv = joint.calculatedHolidayVoltageKv;
      _currentSimTempC = joint.meanPreheatTempC > 0 ? joint.meanPreheatTempC : 210.0;
    });
  }

  void _toggleInductionSimulator() {
    if (_isInductionSimRunning) {
      _inductionTimer?.cancel();
      setState(() => _isInductionSimRunning = false);
    } else {
      setState(() {
        _isInductionSimRunning = true;
        _inductionElapsedSec = 0;
        _inductionLiveCurve.clear();
        _inductionLiveCurve.add(const FlSpot(0, 32));
      });
      _inductionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _inductionElapsedSec += 2;
          final target = 218.0 + (math.Random().nextDouble() * 6 - 3);
          _currentSimTempC = math.min(
            target,
            32.0 + (_inductionPowerKw / 88.0) * (_inductionElapsedSec * 4.2),
          );
          _inductionLiveCurve.add(FlSpot(_inductionElapsedSec.toDouble(), _currentSimTempC));

          if (_inductionElapsedSec >= 60) {
            timer.cancel();
            _isInductionSimRunning = false;
          }
        });
      });
    }
  }

  void _toggleHolidayScanner() {
    if (_isHolidayScanning) {
      _holidayScanTimer?.cancel();
      setState(() => _isHolidayScanning = false);
    } else {
      setState(() {
        _isHolidayScanning = true;
        _sparkDefectTriggered = false;
      });
      _holidayScanTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _scannerAngleDeg = (_scannerAngleDeg + 6.0) % 360.0;
          // Trigger simulated spark warning if near 225 deg (7:30 clock pos) on joint 44
          if (_selectedJoint.id == 'FJ-18-044' &&
              (_scannerAngleDeg >= 220 && _scannerAngleDeg <= 230)) {
            _sparkDefectTriggered = true;
          } else {
            _sparkDefectTriggered = false;
          }
        });
      });
    }
  }

  double _computeBresleSalt() {
    // Formula: S = 1.1 * (sigma_f - sigma_i) * V / A [µg/cm²]
    final deltaConductivity = math.max(0.0, _bresleFinalUs - _bresleInitialUs);
    return (1.1 * deltaConductivity * _bresleWaterVolumeMl) / _breslePatchAreaCm2;
  }

  double _calculateSparkVoltageFromDft(double dftMm) {
    // Rule: 5.0 kV per mm
    return (dftMm * 5.0).clamp(15.0, 25.0);
  }

  @override
  Widget build(BuildContext context) {
    final filteredJoints = _joints.where((j) {
      final matchesSearch = j.id.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          j.weldNumber.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          j.chainageStr.toLowerCase().contains(_searchController.text.toLowerCase());

      if (!matchesSearch) return false;
      if (_filterStatus == 'ALL') return true;
      if (_filterStatus == 'CERTIFIED') return j.status == JointQaStatus.fullyCertified;
      if (_filterStatus == 'REPAIR') {
        return j.status == JointQaStatus.holidayDefect ||
            j.status == JointQaStatus.repairedPendingTest;
      }
      if (_filterStatus == 'TESTING') {
        return j.status == JointQaStatus.holidayTesting || j.status == JointQaStatus.peelTesting;
      }
      if (_filterStatus == 'PREHEAT') return j.status == JointQaStatus.preheating;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildKpiHeaderStrip(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJointRegisterTab(filteredJoints),
                _buildSurfacePrepTab(),
                _buildInductionPreheatTab(),
                _buildCoatingApplicationTab(),
                _buildHolidayTestingTab(),
                _buildPeelAdhesionTab(),
                _buildDossierSignoffTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Field Joint Coating & Holiday QA',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          SizedBox(height: 2),
          Text(
            'NACE SP0188 • DIN 30670 • ISO 21809-3 • 18" API 5L X70',
            style: TextStyle(fontSize: 11, color: AppTheme.primaryLight, letterSpacing: 0.2),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
          tooltip: 'Standards & Tolerance Specifications',
          onPressed: _showStandardsDialog,
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryLight),
          tooltip: 'Log New Field Joint Inspection',
          onPressed: _showNewJointWizardDialog,
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.secondary),
          tooltip: 'Export FJC Inspection Dossier',
          onPressed: () => _showExportDossierModal(_selectedJoint),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ============================================================================
  // KPI METRICS STRIP
  // ============================================================================

  Widget _buildKpiHeaderStrip() {
    final total = _joints.length;
    final certified = _joints.where((j) => j.status == JointQaStatus.fullyCertified).length;
    final repairNeeded = _joints.where((j) => j.hasActiveHolidays).length;
    final passRate = total > 0 ? (certified / total * 100).toStringAsFixed(1) : '100.0';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiCard(
              title: 'TOTAL JOINTS',
              value: '$total Joints',
              sub: 'KP 0+000 - 45+000',
              icon: Icons.linear_scale_rounded,
              color: AppTheme.primaryLight,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'ZERO-DEFECT PASS',
              value: '$passRate%',
              sub: '$certified / $total Certified',
              icon: Icons.verified_user_rounded,
              color: AppTheme.tertiary,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'ACTIVE DEFECTS',
              value: '$repairNeeded Defects',
              sub: repairNeeded > 0 ? 'Requires HSS Patch' : 'Zero Holidays Logged',
              icon: Icons.flash_on_rounded,
              color: repairNeeded > 0 ? const Color(0xFFEF4444) : AppTheme.tertiary,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'AVG PEEL STRENGTH',
              value: '155.2 N/cm',
              sub: 'DIN 30670 > 100 N/cm',
              icon: Icons.speed_rounded,
              color: AppTheme.secondary,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'SELECTED JOINT',
              value: _selectedJoint.id,
              sub: '${_selectedJoint.chainageStr} (${_selectedJoint.weldNumber})',
              icon: Icons.gps_fixed_rounded,
              color: AppTheme.primaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
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
                sub,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB BAR
  // ============================================================================

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 2.5,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(text: 'Joint Register', icon: Icon(Icons.view_list_rounded, size: 18)),
          Tab(text: 'Surface Prep & Bresle', icon: Icon(Icons.cleaning_services_rounded, size: 18)),
          Tab(text: 'Induction Heating', icon: Icon(Icons.local_fire_department_rounded, size: 18)),
          Tab(text: 'Coating & DFT', icon: Icon(Icons.layers_rounded, size: 18)),
          Tab(text: 'HV Holiday Lab', icon: Icon(Icons.flash_on_rounded, size: 18)),
          Tab(text: 'DIN 30670 Peel Bench', icon: Icon(Icons.fitness_center_rounded, size: 18)),
          Tab(text: 'QA Dossier & Sign-Off', icon: Icon(Icons.verified_user_rounded, size: 18)),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: FIELD JOINT REGISTER & PIPELINE BOARD
  // ============================================================================

  Widget _buildJointRegisterTab(List<FieldJointRecord> joints) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.surface,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by Joint ID (FJ-18-042), Weld (GW-42), or KP...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: AppTheme.textSecondary),
                          onPressed: () => setState(() => _searchController.clear()),
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primaryLight),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All Joints (${_joints.length})'),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'CERTIFIED',
                      'Certified 100% (${_joints.where((j) => j.status == JointQaStatus.fullyCertified).length})',
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'REPAIR',
                      'Defects / Repaired (${_joints.where((j) => j.status == JointQaStatus.holidayDefect || j.status == JointQaStatus.repairedPendingTest).length})',
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'TESTING',
                      'Active Testing (${_joints.where((j) => j.status == JointQaStatus.holidayTesting || j.status == JointQaStatus.peelTesting).length})',
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'PREHEAT',
                      'Induction Prep (${_joints.where((j) => j.status == JointQaStatus.preheating).length})',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: joints.isEmpty
              ? const Center(
                  child: Text(
                    'No field joints match the filter criteria.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: joints.length,
                  itemBuilder: (context, index) {
                    final j = joints[index];
                    final isSelected = j.id == _selectedJoint.id;
                    return _buildJointCard(j, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final active = _filterStatus == key;
    return InkWell(
      onTap: () => setState(() => _filterStatus = key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppTheme.primaryLight : AppTheme.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildJointCard(FieldJointRecord joint, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.surfaceCard : AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppTheme.primaryLight : AppTheme.border,
          width: isSelected ? 1.8 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _selectJoint(joint),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                          color: joint.status.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(joint.status.icon, size: 16, color: joint.status.color),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        joint.id,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          joint.weldNumber,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        joint.chainageStr,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: joint.status.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: joint.status.color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      joint.status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: joint.status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Coating System & Spool Info
              Text(
                '${joint.coatingSystem.shortLabel} • Spools: ${joint.spoolBack} / ${joint.spoolAhead}',
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              // 5-Stage Step Progress Indicator
              _buildProgressSteps(joint),
              const SizedBox(height: 10),
              // Key QA Telemetry Values
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniTelemetry(
                    label: 'Blast Profile',
                    val: joint.meanProfileDepthUm > 0
                        ? '${joint.meanProfileDepthUm.toStringAsFixed(0)} µm'
                        : '--',
                    isPass: joint.isProfileCompliant,
                  ),
                  _buildMiniTelemetry(
                    label: 'Bresle Salt',
                    val: '${joint.bresleSaltDensityUgCm2.toStringAsFixed(2)} µg/cm²',
                    isPass: joint.isBresleCompliant,
                  ),
                  _buildMiniTelemetry(
                    label: 'Induction Temp',
                    val: joint.meanPreheatTempC > 0
                        ? '${joint.meanPreheatTempC.toStringAsFixed(0)}°C'
                        : '--',
                    isPass: joint.isPreheatCompliant,
                  ),
                  _buildMiniTelemetry(
                    label: 'HV Holiday',
                    val: joint.holidayTestedPassed
                        ? '${joint.holidayTestVoltageKv.toStringAsFixed(0)} kV (0 Def)'
                        : (joint.hasActiveHolidays ? 'FAIL (1 Void)' : 'PENDING'),
                    isPass: joint.isHolidayCompliant,
                  ),
                  _buildMiniTelemetry(
                    label: 'Peel Strength',
                    val: joint.peelTested
                        ? '${joint.peelMeanForceNPerCm.toStringAsFixed(0)} N/cm'
                        : 'N/A',
                    isPass: joint.isPeelCompliant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: const Text(
                        'ACTIVE JOINT SELECTED',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _selectJoint(joint);
                      _showExportDossierModal(joint);
                    },
                    icon: const Icon(Icons.description_outlined, size: 14),
                    label: const Text('Full Dossier', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryLight,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 28),
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

  Widget _buildProgressSteps(FieldJointRecord joint) {
    final steps = [
      {'name': 'Sa 2.5', 'pass': joint.isProfileCompliant && joint.isBresleCompliant},
      {'name': '200-230°C', 'pass': joint.isPreheatCompliant},
      {'name': 'Coated', 'pass': joint.isOverlapCompliant && joint.masticExtrusionVisual},
      {'name': 'HV Spark', 'pass': joint.isHolidayCompliant},
      {'name': 'Peel >100', 'pass': joint.isPeelCompliant},
    ];

    return Row(
      children: List.generate(steps.length, (idx) {
        final step = steps[idx];
        final passed = step['pass'] as bool;
        final name = step['name'] as String;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: passed
                        ? AppTheme.tertiary
                        : (joint.status == JointQaStatus.holidayDefect && idx == 3
                            ? const Color(0xFFEF4444)
                            : AppTheme.surfaceContainerHigh),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                name,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: passed ? FontWeight.bold : FontWeight.normal,
                  color: passed ? AppTheme.tertiary : AppTheme.textMuted,
                ),
              ),
              if (idx < steps.length - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMiniTelemetry({
    required String label,
    required String val,
    required bool isPass,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 1),
        Text(
          val,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isPass ? AppTheme.textPrimary : const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 2: SURFACE PREPARATION & BRESLE LAB
  // ============================================================================

  Widget _buildSurfacePrepTab() {
    final j = _selectedJoint;
    final bresleResult = _computeBresleSalt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveJointBanner(),
          const SizedBox(height: 14),

          // Standard Reference Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: AppTheme.primaryLight),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Standard: ISO 8501-1 Sa 2.5 • ASTM D4417 Method B (50-75 µm) • ISO 8502-6/9 Salt (< 2 µg/cm²)',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: j.isProfileCompliant && j.isBresleCompliant
                        ? AppTheme.tertiary.withValues(alpha: 0.18)
                        : const Color(0xFFEF4444).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    j.isProfileCompliant && j.isBresleCompliant ? 'PREP PASS' : 'HOLD / VERIFY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: j.isProfileCompliant && j.isBresleCompliant
                          ? AppTheme.tertiary
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Psychrometric Ambient Gauge Card
          _buildPsychrometryCard(j),
          const SizedBox(height: 14),

          // Anchor Profile Depth Gauge (50 - 75 µm) Card
          _buildAnchorProfileCard(j),
          const SizedBox(height: 14),

          // Bresle Patch Soluble Salt Contamination Card
          _buildBreslePatchCard(j, bresleResult),
        ],
      ),
    );
  }

  Widget _buildActiveJointBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.2),
            AppTheme.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppTheme.primaryLight, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Inspection: ${_selectedJoint.id} (${_selectedJoint.weldNumber})',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${_selectedJoint.chainageStr} • 18" API 5L X70 • ${_selectedJoint.coatingSystem.shortLabel}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _selectedJoint.status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _selectedJoint.status.color.withValues(alpha: 0.5)),
            ),
            child: Text(
              _selectedJoint.status.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _selectedJoint.status.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPsychrometryCard(FieldJointRecord j) {
    final deltaT = j.pipeSurfaceTempC - j.dewPointC;
    final isDeltaPass = deltaT >= 3.0;
    final isRhPass = j.relativeHumidityPct <= 85.0;

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
              const Text(
                'Psychrometric Environmental Conditions',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDeltaPass && isRhPass
                      ? AppTheme.tertiary.withValues(alpha: 0.18)
                      : const Color(0xFFEF4444).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isDeltaPass && isRhPass ? 'SUITABLE TO BLAST' : 'CONDENSATION RISK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDeltaPass && isRhPass ? AppTheme.tertiary : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Ambient Air Temp',
                  val: '${j.ambientTempC.toStringAsFixed(1)} °C',
                  desc: 'Wet/Dry Bulb Telemetry',
                  icon: Icons.thermostat_rounded,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Relative Humidity',
                  val: '${j.relativeHumidityPct.toStringAsFixed(0)} %',
                  desc: 'Spec: ≤ 85% RH',
                  icon: Icons.water_drop_outlined,
                  color: isRhPass ? AppTheme.tertiary : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Dew Point (Td)',
                  val: '${j.dewPointC.toStringAsFixed(1)} °C',
                  desc: 'Magnus-Tetens psych',
                  icon: Icons.cloud_outlined,
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Pipe Steel (Ts)',
                  val: '${j.pipeSurfaceTempC.toStringAsFixed(1)} °C',
                  desc: 'Δ = +${deltaT.toStringAsFixed(1)}°C (≥3°C)',
                  icon: Icons.speed_rounded,
                  color: isDeltaPass ? AppTheme.tertiary : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Requirement: Steel temperature must exceed dew point by at least 3.0°C (Ts - Td ≥ 3°C) '
            'prior to grit blasting or primer application to prevent flash rust.',
            style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAnchorProfileCard(FieldJointRecord j) {
    final meanProfile = j.meanProfileDepthUm;
    final isCompliant = j.isProfileCompliant;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Anchor Profile Depth Gauge (ASTM D4417)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Specified Range: 50.0 µm to 75.0 µm (Peak-to-Valley)',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompliant
                      ? AppTheme.tertiary.withValues(alpha: 0.18)
                      : const Color(0xFFEF4444).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'MEAN: ${meanProfile.toStringAsFixed(1)} µm (${isCompliant ? "PASS" : "OUT OF SPEC"})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCompliant ? AppTheme.tertiary : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4-Quadrant Clock Telemetry
          Row(
            children: [
              Expanded(child: _buildClockProfileBox('12:00 (Crown)', j.profileDepthUmClock['12:00'] ?? 0.0)),
              const SizedBox(width: 8),
              Expanded(child: _buildClockProfileBox('3:00 (Right)', j.profileDepthUmClock['3:00'] ?? 0.0)),
              const SizedBox(width: 8),
              Expanded(child: _buildClockProfileBox('6:00 (Invert)', j.profileDepthUmClock['6:00'] ?? 0.0)),
              const SizedBox(width: 8),
              Expanded(child: _buildClockProfileBox('9:00 (Left)', j.profileDepthUmClock['9:00'] ?? 0.0)),
            ],
          ),
          const SizedBox(height: 12),

          // Profile Range Bar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('0 µm', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    const Text('Min: 50 µm', style: TextStyle(fontSize: 10, color: AppTheme.secondary)),
                    Text(
                      'Gauge Mean: ${meanProfile.toStringAsFixed(1)} µm',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCompliant ? AppTheme.tertiary : const Color(0xFFEF4444),
                      ),
                    ),
                    const Text('Max: 75 µm', style: TextStyle(fontSize: 10, color: AppTheme.secondary)),
                    const Text('100 µm', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    // Acceptable Zone 50 - 75%
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.5 * 0.5,
                      width: MediaQuery.of(context).size.width * 0.25 * 0.5,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Current Indicator
                    Positioned(
                      left: ((meanProfile / 100.0).clamp(0.0, 1.0)) *
                          (MediaQuery.of(context).size.width - 60),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: isCompliant ? AppTheme.tertiary : const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Grit Blasting Standard: ${j.blastStandard.label} using ${j.blastMedium}. '
            'Surface profile verified with digital micrometric dial depth gauge.',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildClockProfileBox(String position, double value) {
    final ok = value >= 50.0 && value <= 75.0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ok ? AppTheme.border : const Color(0xFFEF4444).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Text(position, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          Text(
            '${value.toStringAsFixed(1)} µm',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: ok ? AppTheme.textPrimary : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreslePatchCard(FieldJointRecord j, double computedSalt) {
    final isPass = computedSalt < 2.0;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Bresle Patch Soluble Salt Extraction (ISO 8502-6 / 8502-9)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Threshold: < 2.0 µg/cm² (Chlorides & Soluble Salts)',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPass
                      ? AppTheme.tertiary.withValues(alpha: 0.18)
                      : const Color(0xFFEF4444).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${computedSalt.toStringAsFixed(2)} µg/cm² (${isPass ? "PASS" : "FAIL"})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPass ? AppTheme.tertiary : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Interactive Patch Inputs
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interactive Conductivity Extraction Calculator',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildBresleSlider(
                        label: 'Initial Water (σ₀)',
                        valStr: '${_bresleInitialUs.toStringAsFixed(1)} µS/cm',
                        val: _bresleInitialUs,
                        min: 0.5,
                        max: 5.0,
                        onChanged: (v) => setState(() => _bresleInitialUs = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBresleSlider(
                        label: 'Extracted Soln (σ₁)',
                        valStr: '${_bresleFinalUs.toStringAsFixed(1)} µS/cm',
                        val: _bresleFinalUs,
                        min: 2.0,
                        max: 30.0,
                        onChanged: (v) => setState(() => _bresleFinalUs = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildBresleSlider(
                        label: 'Pure Water Vol (V)',
                        valStr: '${_bresleWaterVolumeMl.toStringAsFixed(1)} mL',
                        val: _bresleWaterVolumeMl,
                        min: 2.0,
                        max: 5.0,
                        onChanged: (v) => setState(() => _bresleWaterVolumeMl = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBresleSlider(
                        label: 'Patch Area (A)',
                        valStr: '${_breslePatchAreaCm2.toStringAsFixed(1)} cm²',
                        val: _breslePatchAreaCm2,
                        min: 10.0,
                        max: 15.0,
                        onChanged: (v) => setState(() => _breslePatchAreaCm2 = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ISO 8502-9 Formula: S = 1.1 × (σ₁ - σ₀) × V / A. '
            'Current calculated salt density is ${computedSalt.toStringAsFixed(2)} µg/cm². '
            '${computedSalt < 2.0 ? "Surface is cleanly decontaminated below maximum allowable threshold." : "Excessive salt detected! High-pressure washdown required."}',
            style: TextStyle(
              fontSize: 11,
              color: isPass ? AppTheme.textSecondary : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBresleSlider({
    required String label,
    required String valStr,
    required double val,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            Text(
              valStr,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            activeTrackColor: AppTheme.primaryLight,
            inactiveTrackColor: AppTheme.surfaceContainerHigh,
            thumbColor: AppTheme.primaryLight,
          ),
          child: Slider(
            value: val,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String val,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            val,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            desc,
            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: INDUCTION PRE-HEATING TELEMETRY
  // ============================================================================

  Widget _buildInductionPreheatTab() {
    final j = _selectedJoint;
    final isTempCompliant = _currentSimTempC >= 200.0 && _currentSimTempC <= 230.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveJointBanner(),
          const SizedBox(height: 14),

          // Induction Telemetry Strip
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Medium-Frequency (MF) Induction Heating Coil',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Target Temperature Window: 200.0°C - 230.0°C (Uniformity ΔT ≤ 15°C)',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _toggleInductionSimulator,
                      icon: Icon(
                        _isInductionSimRunning ? Icons.pause_circle_filled : Icons.play_arrow_rounded,
                        size: 16,
                      ),
                      label: Text(
                        _isInductionSimRunning ? 'Pause Heat Coil' : 'Simulate Coil Heat',
                        style: const TextStyle(fontSize: 11),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isInductionSimRunning
                            ? const Color(0xFFEF4444)
                            : AppTheme.secondary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Heat Telemetry Gauges
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Coil Generator Power',
                        val: '${_inductionPowerKw.toStringAsFixed(1)} kW',
                        desc: 'Medium-Freq 3.5 kHz',
                        icon: Icons.flash_on_rounded,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Pyrometer Peak',
                        val: '${_currentSimTempC.toStringAsFixed(1)} °C',
                        desc: 'Target: 200 - 230°C',
                        icon: Icons.local_fire_department_rounded,
                        color: isTempCompliant ? AppTheme.tertiary : AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Circumferential ΔT',
                        val: '${j.preheatDeltaC.toStringAsFixed(1)} °C',
                        desc: 'Limit: ≤ 15.0°C',
                        icon: Icons.swap_horiz_rounded,
                        color: j.preheatDeltaC <= 15.0 ? AppTheme.tertiary : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Heat Soaking Time',
                        val: '$_inductionElapsedSec sec',
                        desc: 'Cycle Limit: 45 - 60s',
                        icon: Icons.timer_outlined,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Generator Output Power (kW): ',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    Text(
                      '${_inductionPowerKw.toStringAsFixed(0)} kW',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _inductionPowerKw,
                        min: 60.0,
                        max: 120.0,
                        divisions: 12,
                        activeColor: AppTheme.secondary,
                        inactiveColor: AppTheme.surfaceContainerHigh,
                        onChanged: (v) => setState(() => _inductionPowerKw = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Line Chart: Thermal Ramp-Up Curve
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Induction Preheating Temperature Curve (°C vs Time)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isTempCompliant
                            ? AppTheme.tertiary.withValues(alpha: 0.18)
                            : AppTheme.secondary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isTempCompliant ? 'IN TARGET WINDOW' : 'HEATING IN PROGRESS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isTempCompliant ? AppTheme.tertiary : AppTheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 190,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 60,
                      minY: 0,
                      maxY: 260,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 50,
                        verticalInterval: 10,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppTheme.border.withValues(alpha: 0.5),
                          strokeWidth: 0.8,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: AppTheme.border.withValues(alpha: 0.5),
                          strokeWidth: 0.8,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: 50,
                            getTitlesWidget: (v, meta) => Text(
                              '${v.toInt()}°C',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 10,
                            getTitlesWidget: (v, meta) => Text(
                              '${v.toInt()}s',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                            ),
                          ),
                        ),
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: 200,
                            color: AppTheme.secondary.withValues(alpha: 0.7),
                            strokeWidth: 1.5,
                            dashArray: [4, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              labelResolver: (line) => 'Min 200°C',
                              style: const TextStyle(color: AppTheme.secondary, fontSize: 9),
                            ),
                          ),
                          HorizontalLine(
                            y: 230,
                            color: const Color(0xFFEF4444).withValues(alpha: 0.7),
                            strokeWidth: 1.5,
                            dashArray: [4, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              labelResolver: (line) => 'Max 230°C',
                              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppTheme.border),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _inductionLiveCurve,
                          isCurved: true,
                          color: AppTheme.secondary,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.secondary.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4-Quadrant Pyrometer Validation Box
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
                const Text(
                  'Circumferential Pyrometer Reading Matrix (Digital Contact Pyrometer)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildPyrometerBox(
                        '12:00 (Crown)',
                        j.pyrometerTempClockC['12:00'] ?? 216.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPyrometerBox(
                        '3:00 (Right)',
                        j.pyrometerTempClockC['3:00'] ?? 222.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPyrometerBox(
                        '6:00 (Invert)',
                        j.pyrometerTempClockC['6:00'] ?? 214.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPyrometerBox(
                        '9:00 (Left)',
                        j.pyrometerTempClockC['9:00'] ?? 219.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'DIN 30670 / ISO 21809-3 Note: Overheating above 230°C degrades the bevel transition of factory '
                  '3LPE coating. Underheating below 200°C causes poor epoxy primer curing and cold mastic adhesion failure.',
                  style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPyrometerBox(String position, double tempC) {
    final inWindow = tempC >= 200.0 && tempC <= 230.0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: inWindow ? AppTheme.border : const Color(0xFFEF4444).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Text(position, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          const SizedBox(height: 3),
          Text(
            '${tempC.toStringAsFixed(1)}°C',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: inWindow ? AppTheme.textPrimary : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            inWindow ? 'IN WINDOW' : (tempC < 200.0 ? 'UNDERHEAT' : 'OVERHEAT'),
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: inWindow ? AppTheme.tertiary : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: COATING APPLICATION & DFT PROFILER
  // ============================================================================

  Widget _buildCoatingApplicationTab() {
    final j = _selectedJoint;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveJointBanner(),
          const SizedBox(height: 14),

          // System Specification Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      j.coatingSystem.label,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'DFT SPEC: ≥ ${j.coatingSystem.nominalTotalDftMm.toStringAsFixed(1)} mm',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Liquid Epoxy Primer WFT',
                        val: '${j.primerWftUm.toStringAsFixed(0)} µm',
                        desc: 'Solvent-free 2-part liquid',
                        icon: Icons.format_paint_rounded,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Primer DFT',
                        val: '${j.primerDftUm.toStringAsFixed(0)} µm',
                        desc: 'Target: 100 - 150 µm',
                        icon: Icons.line_weight_rounded,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Mean Total Joint DFT',
                        val: '${j.meanTotalDftMm.toStringAsFixed(2)} mm',
                        desc: 'Backing + Mastic + Epoxy',
                        icon: Icons.layers_rounded,
                        color: j.meanTotalDftMm >= j.coatingSystem.nominalTotalDftMm
                            ? AppTheme.tertiary
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Overlap & Visual Inspection Card
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
                const Text(
                  'Sleeve Overlap & Circumferential Recovery (DIN 30670 Requirement)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildOverlapGauge(
                        'Upstream Overlap (Ahead)',
                        j.sleeveOverlapMmAhead,
                        j.coatingSystem.minOverlapMm,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildOverlapGauge(
                        'Downstream Overlap (Back)',
                        j.sleeveOverlapMmBack,
                        j.coatingSystem.minOverlapMm,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        j.masticExtrusionVisual ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: j.masticExtrusionVisual ? AppTheme.tertiary : const Color(0xFFEF4444),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Circumferential Mastic Extrusion Bead',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              j.masticExtrusionVisual
                                  ? 'Verified: Continuous 360° mastic extrusion bead observed along both sleeve edges. No air entrapment or wrinkles.'
                                  : 'Reject: Discontinuous mastic extrusion bead or sleeve tenting observed at weld seam.',
                              style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
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
          const SizedBox(height: 14),

          // 8-Point Circumferential DFT Profiler
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
                const Text(
                  '8-Point Circumferential Dry Film Thickness (DFT) Profiler',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '12:00',
                    '1:30',
                    '3:00',
                    '4:30',
                    '6:00',
                    '7:30',
                    '9:00',
                    '10:30',
                  ].map((pos) {
                    final dft = j.totalDftMmClock[pos] ?? 0.0;
                    final ok = dft >= 2.50;
                    return Container(
                      width: 75,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: ok ? AppTheme.border : const Color(0xFFEF4444).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(pos, style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            dft > 0 ? '${dft.toStringAsFixed(2)} mm' : '--',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: ok ? AppTheme.textPrimary : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlapGauge(String label, double overlapMm, double minReqMm) {
    final ok = overlapMm >= minReqMm;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ok ? AppTheme.border : const Color(0xFFEF4444).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${overlapMm.toStringAsFixed(1)} mm',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ok ? AppTheme.textPrimary : const Color(0xFFEF4444),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ok
                      ? AppTheme.tertiary.withValues(alpha: 0.15)
                      : const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ok ? '≥ 50 mm PASS' : 'UNDERLAP FAIL',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: ok ? AppTheme.tertiary : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 5: HIGH-VOLTAGE HOLIDAY TESTING LAB (NACE SP0188)
  // ============================================================================

  Widget _buildHolidayTestingTab() {
    final j = _selectedJoint;
    final isHolidayClear = j.isHolidayCompliant;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveJointBanner(),
          const SizedBox(height: 14),

          // Standard Header & Zero Defect Banner
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'High-Voltage Continuous DC Holiday Testing',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'NACE SP0188 / DIN 30670 Section 5.3.3 • 5.0 kV per mm Rule',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _toggleHolidayScanner,
                      icon: Icon(
                        _isHolidayScanning ? Icons.stop_circle_outlined : Icons.radar_rounded,
                        size: 16,
                      ),
                      label: Text(
                        _isHolidayScanning ? 'Stop 360° Scan' : 'Run 360° Holiday Scan',
                        style: const TextStyle(fontSize: 11),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isHolidayScanning
                            ? const Color(0xFFEF4444)
                            : AppTheme.primaryLight,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Continuous DC Voltage',
                        val: '${_sparkVoltageKv.toStringAsFixed(1)} kV',
                        desc: 'Spec: 5 kV/mm rule',
                        icon: Icons.flash_on_rounded,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Electrode Apparatus',
                        val: 'Spring Coil',
                        desc: 'Full-circle bronze coil',
                        icon: Icons.blur_circular_rounded,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Active Pinholes',
                        val: '${j.holidaysDetected} Detected',
                        desc: isHolidayClear ? 'Zero-Defect Certified' : 'Defect Hold Applied',
                        icon: Icons.warning_amber_rounded,
                        color: isHolidayClear ? AppTheme.tertiary : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Sign-off Status',
                        val: isHolidayClear ? '100% CLEAR' : 'REPAIR REQ',
                        desc: isHolidayClear ? 'Zero-Defect Pass' : 'Action Required',
                        icon: Icons.verified_user_rounded,
                        color: isHolidayClear ? AppTheme.tertiary : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 360° Pipe Joint Scanning Visualizer
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '360° Rolling Spring Electrode Scanning Telemetry',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (_sparkDefectTriggered)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFEF4444)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEF4444)),
                            SizedBox(width: 4),
                            Text(
                              'SPARK DISCHARGE DETECTED!',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Interactive Custom Pipe Cross-Section
                SizedBox(
                  height: 180,
                  child: Center(
                    child: CustomPaint(
                      size: const Size(260, 180),
                      painter: _PipeCircumferencePainter(
                        scanAngleDeg: _scannerAngleDeg,
                        hasDefect: _selectedJoint.hasActiveHolidays || _sparkDefectTriggered,
                        isScanning: _isHolidayScanning,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Electrode Sweep Position: ${_scannerAngleDeg.toStringAsFixed(0)}° '
                    '(${((_scannerAngleDeg / 30.0).floor() % 12 + 1).toString().padLeft(2, '0')}:'
                    '${(((_scannerAngleDeg % 30) / 30 * 60).floor()).toString().padLeft(2, '0')} clock pos)',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Interactive Test Voltage Calculator
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
                const Text(
                  'Continuous DC Test Voltage Calculator (5 kV/mm Rule)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Coating Thickness (DFT):',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              Text(
                                '${_calcCustomDftMm.toStringAsFixed(2)} mm (${(_calcCustomDftMm * 39.37).toStringAsFixed(0)} mils)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _calcCustomDftMm,
                            min: 1.0,
                            max: 5.0,
                            divisions: 40,
                            activeColor: AppTheme.primaryLight,
                            inactiveColor: AppTheme.surfaceContainerHigh,
                            onChanged: (v) => setState(() => _calcCustomDftMm = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Computed Voltage:',
                                style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                            Text(
                              '${_calculateSparkVoltageFromDft(_calcCustomDftMm).toStringAsFixed(1)} kV',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondary,
                              ),
                            ),
                            Text(
                              'DIN 30670: 5 kV/mm\nNACE Mils: ${(3294 * math.sqrt(_calcCustomDftMm * 39.37) / 1000).toStringAsFixed(1)} kV',
                              style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Pinhole Defect Log & Repair Sign-off
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pinhole Discontinuity & Repair Register',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${j.holidayRecords.length} Defects Logged',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (j.holidayRecords.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle_outline, color: AppTheme.tertiary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Zero holidays detected across 100% of field joint circumference.',
                          style: TextStyle(fontSize: 11.5, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  )
                else
                  ...j.holidayRecords.map((def) => _buildDefectRecordTile(def, j)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefectRecordTile(HolidayDefectRecord def, FieldJointRecord j) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: def.retestPass ? AppTheme.tertiary.withValues(alpha: 0.5) : const Color(0xFFEF4444),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Defect #${def.id} at Clock ${def.clockOrientation} (${def.distFromWeldCenterMm.toStringAsFixed(0)}mm from weld)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: def.retestPass
                      ? AppTheme.tertiary.withValues(alpha: 0.15)
                      : const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  def.retestPass ? 'RETEST PASSED' : 'HOLD - REPAIR REQ',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: def.retestPass ? AppTheme.tertiary : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(def.description, style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(
            'Repair Method: ${def.repairMethod}',
            style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 6: DIN 30670 PEEL ADHESION TESTING BENCH
  // ============================================================================

  Widget _buildPeelAdhesionTab() {
    final j = _selectedJoint;
    final peelPass = j.peelTested && j.isPeelCompliant;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveJointBanner(),
          const SizedBox(height: 14),

          // Standard Header
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '90-Degree Peel Strength Adhesion Test Bench',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'DIN 30670 Section 5.3.2 / ISO 21809-3 • Requirement: > 100 N/cm at 23°C',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: peelPass
                            ? AppTheme.tertiary.withValues(alpha: 0.18)
                            : (j.peelTested
                                ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                                : AppTheme.secondary.withValues(alpha: 0.18)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        j.peelTested
                            ? (peelPass ? 'DIN 30670 PASS' : 'ADHIBITION FAIL')
                            : 'COUPON PENDING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: peelPass
                              ? AppTheme.tertiary
                              : (j.peelTested ? const Color(0xFFEF4444) : AppTheme.secondary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Mean Peel Force',
                        val: j.peelTested
                            ? '${j.peelMeanForceNPerCm.toStringAsFixed(1)} N/cm'
                            : '148.5 N/cm',
                        desc: 'Spec: > 100 N/cm',
                        icon: Icons.fitness_center_rounded,
                        color: AppTheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Peak Peel Force',
                        val: j.peelTested
                            ? '${j.peelPeakForceNPerCm.toStringAsFixed(1)} N/cm'
                            : '172.0 N/cm',
                        desc: 'Tensile crosshead peak',
                        icon: Icons.trending_up_rounded,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Strip Width',
                        val: '${j.peelStripWidthMm.toStringAsFixed(0)} mm',
                        desc: 'DIN Specimen width',
                        icon: Icons.straighten_rounded,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Pull Speed',
                        val: '${j.peelRateMmPerMin.toStringAsFixed(0)} mm/min',
                        desc: 'Temp: ${j.peelTestTempC.toStringAsFixed(0)}°C ±2°C',
                        icon: Icons.speed_rounded,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Peel Force vs Travel Graph (fl_chart)
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Peel Load vs Displacement Curve (0 - 100 mm Travel)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Threshold: 100 N/cm (Red Line)',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 190,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 100,
                      minY: 0,
                      maxY: 200,
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 40,
                        verticalInterval: 20,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: AppTheme.border.withValues(alpha: 0.5),
                          strokeWidth: 0.8,
                        ),
                        getDrawingVerticalLine: (v) => FlLine(
                          color: AppTheme.border.withValues(alpha: 0.5),
                          strokeWidth: 0.8,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: 50,
                            getTitlesWidget: (v, meta) => Text(
                              '${v.toInt()}N',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 20,
                            getTitlesWidget: (v, meta) => Text(
                              '${v.toInt()}mm',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                            ),
                          ),
                        ),
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: 100,
                            color: const Color(0xFFEF4444),
                            strokeWidth: 1.5,
                            dashArray: [4, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              labelResolver: (line) => 'DIN 30670 Min: 100 N/cm',
                              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppTheme.border),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: (j.peelDisplacementLoads.isNotEmpty
                                  ? j.peelDisplacementLoads
                                  : [
                                      120.0, 135.0, 144.0, 155.0, 168.0, 172.0, 160.0, 148.0, 142.0, 146.0,
                                      150.0, 147.0, 149.0, 145.0, 148.0, 151.0, 149.0, 146.0, 148.5, 149.0
                                    ])
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key * 5.0, e.value))
                              .toList(),
                          isCurved: true,
                          color: AppTheme.tertiary,
                          barWidth: 2.2,
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
                const SizedBox(height: 12),
                // Crosshead Travel Simulator Slider
                Row(
                  children: [
                    const Text('Bench Crosshead Travel: ',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    Text(
                      '${_peelDisplacementMm.toStringAsFixed(0)} mm',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _peelDisplacementMm,
                        min: 0.0,
                        max: 100.0,
                        divisions: 20,
                        activeColor: AppTheme.primaryLight,
                        inactiveColor: AppTheme.surfaceContainerHigh,
                        onChanged: (v) {
                          setState(() {
                            _peelDisplacementMm = v;
                            _currentPeelForceNPerCm = 140.0 + math.sin(v / 10.0) * 12.0;
                          });
                        },
                      ),
                    ),
                    Text(
                      '${_currentPeelForceNPerCm.toStringAsFixed(1)} N/cm',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Failure Mode Classification Card
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
                const Text(
                  'Adhesion Failure Mode Classification',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildFailureModeTile(
                  mode: PeelFailureMode.cohesiveMastic,
                  current: j.peelFailureMode == PeelFailureMode.cohesiveMastic,
                  title: 'Type 1: Cohesive Failure in Mastic (>95% Residue on Steel)',
                  sub: 'Acceptable per DIN 30670. High chemical bonding to epoxy primer.',
                ),
                const SizedBox(height: 6),
                _buildFailureModeTile(
                  mode: PeelFailureMode.cohesivePrimer,
                  current: j.peelFailureMode == PeelFailureMode.cohesivePrimer,
                  title: 'Type 2: Cohesive Failure within Liquid Epoxy Primer',
                  sub: 'Acceptable. Primer shear strength exceeded before steel interface.',
                ),
                const SizedBox(height: 6),
                _buildFailureModeTile(
                  mode: PeelFailureMode.adhesiveSteel,
                  current: j.peelFailureMode == PeelFailureMode.adhesiveSteel,
                  title: 'Type 3: Adhesive Failure at Steel Substrate (Clean Bare Steel)',
                  sub: 'REJECTABLE DEFECT. Inadequate surface prep or low preheat temperature.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureModeTile({
    required PeelFailureMode mode,
    required bool current,
    required String title,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: current ? mode.color : AppTheme.border,
          width: current ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            current ? Icons.radio_button_checked : Icons.radio_button_off,
            color: current ? mode.color : AppTheme.textMuted,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: current ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
                Text(sub, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 7: QA DOSSIER & DIGITAL SIGN-OFF
  // ============================================================================

  Widget _buildDossierSignoffTab() {
    final j = _selectedJoint;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveJointBanner(),
          const SizedBox(height: 14),

          // Release Permit & Hash Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.surfaceCard,
                  AppTheme.primary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
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
                          'PIPELINE TRENCH LOWERING RELEASE PERMIT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: AppTheme.secondary,
                          ),
                        ),
                        Text(
                          j.loweringReleasePermitNo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: j.isZeroDefectCertified
                            ? AppTheme.tertiary.withValues(alpha: 0.2)
                            : const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: j.isZeroDefectCertified
                              ? AppTheme.tertiary
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      child: Text(
                        j.isZeroDefectCertified ? 'LOWERING AUTHORIZED' : 'HOLD - UNRELEASED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: j.isZeroDefectCertified
                              ? AppTheme.tertiary
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint_rounded, size: 16, color: AppTheme.primaryLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SHA-256: ${j.dossierHashSha256}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
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
          const SizedBox(height: 14),

          // 5-Gate Clearance Checklist
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
                const Text(
                  'Comprehensive 5-Gate QA/QC Clearance Matrix',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGateTile(
                  gateNum: 'Gate 1',
                  name: 'Surface Preparation & Salt Decontamination',
                  spec: 'ISO 8501-1 Sa 2.5 • Profile 50-75 µm • Bresle < 2 µg/cm²',
                  passed: j.isProfileCompliant && j.isBresleCompliant && j.isPsychrometryCompliant,
                  details:
                      'Profile: ${j.meanProfileDepthUm.toStringAsFixed(0)} µm | Salt: ${j.bresleSaltDensityUgCm2.toStringAsFixed(2)} µg/cm²',
                ),
                const SizedBox(height: 8),
                _buildGateTile(
                  gateNum: 'Gate 2',
                  name: 'MF Induction Pre-heating Uniformity',
                  spec: 'DIN 30670 / ISO 21809-3 • 200°C - 230°C • ΔT ≤ 15°C',
                  passed: j.isPreheatCompliant,
                  details:
                      'Mean Temp: ${j.meanPreheatTempC.toStringAsFixed(0)}°C | Circumferential ΔT: ${j.preheatDeltaC.toStringAsFixed(1)}°C',
                ),
                const SizedBox(height: 8),
                _buildGateTile(
                  gateNum: 'Gate 3',
                  name: 'Sleeve Overlap & Circumferential Recovery',
                  spec: 'Overlap ≥ 50 mm • 360° Mastic Extrusion Bead • DFT ≥ 2.5 mm',
                  passed: j.isOverlapCompliant && j.masticExtrusionVisual,
                  details:
                      'Overlap Ahead: ${j.sleeveOverlapMmAhead.toStringAsFixed(0)}mm | Overlap Back: ${j.sleeveOverlapMmBack.toStringAsFixed(0)}mm',
                ),
                const SizedBox(height: 8),
                _buildGateTile(
                  gateNum: 'Gate 4',
                  name: 'Continuous DC High-Voltage Holiday Testing',
                  spec: 'NACE SP0188 • 5.0 kV/mm rule (15-25 kV) • ZERO DEFECTS',
                  passed: j.isHolidayCompliant,
                  details:
                      'Tested Voltage: ${j.holidayTestVoltageKv.toStringAsFixed(0)} kV | Active Holidays: ${j.holidaysDetected}',
                ),
                const SizedBox(height: 8),
                _buildGateTile(
                  gateNum: 'Gate 5',
                  name: 'DIN 30670 90° Peel Strength Adhesion',
                  spec: '> 100 N/cm at 23°C • Cohesive Failure in Mastic',
                  passed: j.isPeelCompliant,
                  details: j.peelTested
                      ? 'Mean Force: ${j.peelMeanForceNPerCm.toStringAsFixed(0)} N/cm (${j.peelFailureMode.label})'
                      : 'Sample Tested on Pipeline Coupon Lot',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Digital Inspector Signatures
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
                const Text(
                  'Multi-Party Digital Sign-Off & Verification',
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
                      child: _buildSignatureBox(
                        title: 'NACE CIP LEVEL 3 INSPECTOR',
                        name: j.inspectorName,
                        org: 'Lead Coating Inspector',
                        date: 'Signed: ${DateFormat('dd MMM yyyy').format(j.inspectionDate)}',
                        signed: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSignatureBox(
                        title: 'THIRD-PARTY INSPECTION (TPI)',
                        name: j.tpiInspector,
                        org: 'Engineers India Limited (EIL)',
                        date: j.tpiWitnessed
                            ? 'Witnessed: ${DateFormat('dd MMM yyyy').format(j.inspectionDate)}'
                            : 'Pending TPI Witness',
                        signed: j.tpiWitnessed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => _showSignoffApprovalDialog(j),
                    icon: const Icon(Icons.verified_user_rounded, size: 18),
                    label: const Text(
                      'AUTHORIZE LOWERING & SEAL IMMUTABLE QA RECORD',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tertiary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGateTile({
    required String gateNum,
    required String name,
    required String spec,
    required bool passed,
    required String details,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: passed ? AppTheme.tertiary.withValues(alpha: 0.4) : const Color(0xFFEF4444).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: passed
                  ? AppTheme.tertiary.withValues(alpha: 0.18)
                  : const Color(0xFFEF4444).withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              passed ? Icons.check : Icons.close,
              size: 14,
              color: passed ? AppTheme.tertiary : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$gateNum: $name',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      passed ? 'CLEAR' : 'HOLD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: passed ? AppTheme.tertiary : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(spec, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(fontSize: 10.5, color: AppTheme.primaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureBox({
    required String title,
    required String name,
    required String org,
    required String date,
    required bool signed,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(org, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                signed ? Icons.check_circle_rounded : Icons.pending_outlined,
                size: 12,
                color: signed ? AppTheme.tertiary : AppTheme.secondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  date,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: signed ? AppTheme.tertiary : AppTheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // DIALOGS & MODALS
  // ============================================================================

  void _showStandardsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Pipeline FJC Engineering Standards'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '1. Surface Cleanliness: ISO 8501-1 Sa 2.5 / SSPC-SP 10\n'
                '• Near-White blast cleaning; ≥ 95% mill scale & rust removed.\n\n'
                '2. Anchor Profile Depth: ASTM D4417 Method B\n'
                '• 50 µm to 75 µm peak-to-valley roughness.\n\n'
                '3. Salt Contamination: ISO 8502-6 / 8502-9 (Bresle Patch)\n'
                '• Threshold < 2.0 µg/cm² total soluble salts.\n\n'
                '4. Induction Heating: DIN 30670 / ISO 21809-3\n'
                '• 200°C - 230°C digital pyrometer check; ΔT ≤ 15°C.\n\n'
                '5. High-Voltage Holiday Testing: NACE SP0188\n'
                '• Continuous DC spark detector at 5 kV/mm DFT (15 - 25 kV).\n'
                '• Zero defects permitted.\n\n'
                '6. Peel Adhesion: DIN 30670 Section 5.3.2\n'
                '• > 100 N/cm at 23°C; cohesive failure in mastic.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss', style: TextStyle(color: AppTheme.primaryLight)),
          ),
        ],
      ),
    );
  }

  void _showNewJointWizardDialog() {
    final weldCtrl = TextEditingController(text: 'GW-${_joints.length + 1}');
    final chainageCtrl =
        TextEditingController(text: 'KP ${(16.0 + _joints.length * 0.35).toStringAsFixed(3)}');
    CoatingSystemType selectedSys = CoatingSystemType.hssMastic;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Log New Field Joint Inspection'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: weldCtrl,
                  decoration: const InputDecoration(labelText: 'Weld Girth Seam Number'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: chainageCtrl,
                  decoration: const InputDecoration(labelText: 'Pipeline Chainage (KP)'),
                ),
                const SizedBox(height: 12),
                const Text('Coating System:', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                DropdownButton<CoatingSystemType>(
                  value: selectedSys,
                  isExpanded: true,
                  dropdownColor: AppTheme.surface,
                  items: CoatingSystemType.values.map((sys) {
                    return DropdownMenuItem(
                      value: sys,
                      child: Text(sys.shortLabel, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedSys = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final newId = 'FJ-18-0${_joints.length + 42}';
                final newRec = FieldJointRecord(
                  id: newId,
                  weldNumber: weldCtrl.text,
                  chainageKm: 16.5 + _joints.length * 0.35,
                  chainageStr: chainageCtrl.text,
                  spoolAhead: 'SP-18-0${_joints.length + 42}',
                  spoolBack: 'SP-18-0${_joints.length + 41}',
                  pipeOdMm: 457.2,
                  wallThicknessMm: 9.52,
                  steelGrade: 'API 5L X70 PSL2',
                  coatingSystem: selectedSys,
                  contractor: 'Punj Lloyd - Kalpataru JV',
                  inspectorName: 'Er. Rajesh Verma (NACE CIP Level 3)',
                  tpiInspector: 'Er. S. Bhattacharya (EIL TPI)',
                  status: JointQaStatus.prepPending,
                  blastStandard: SurfacePreparationStandard.iso8501Sa2_5,
                  blastMedium: 'Chilled Iron Grit GL-25 / Garnet 20/40',
                  ambientTempC: 28.0,
                  relativeHumidityPct: 62.0,
                  dewPointC: 20.0,
                  pipeSurfaceTempC: 31.5,
                  profileDepthUmClock: const {
                    '12:00': 62.0,
                    '3:00': 64.0,
                    '6:00': 66.0,
                    '9:00': 61.0,
                  },
                  bresleConductivityInitialUs: 2.1,
                  bresleConductivityFinalUs: 11.5,
                  bresleSaltDensityUgCm2: 0.82,
                  dustTapeClass: 1,
                  inductionCoilPowerKw: 88.0,
                  inductionFrequencyKhz: 3.45,
                  heatingDurationSec: 45,
                  pyrometerTempClockC: const {
                    '12:00': 215.0,
                    '3:00': 220.0,
                    '6:00': 212.0,
                    '9:00': 218.0,
                  },
                  preheatVerified: true,
                  epoxyBatchNumber: 'EP-2026-X99',
                  sleeveBatchNumber: 'HSS-WPC100-9999',
                  primerWftUm: 180.0,
                  primerDftUm: 125.0,
                  sleeveOverlapMmAhead: 65.0,
                  sleeveOverlapMmBack: 65.0,
                  totalDftMmClock: const {
                    '12:00': 2.80,
                    '3:00': 2.85,
                    '6:00': 2.82,
                    '9:00': 2.81,
                  },
                  masticExtrusionVisual: true,
                  holidayTestVoltageKv: 20.0,
                  sparkDetectorModel: 'Spy Model 785 High-Voltage DC Pulse',
                  holidaysDetected: 0,
                  holidayRecords: const [],
                  holidayTestedPassed: true,
                  peelTested: true,
                  peelTestTempC: 23.0,
                  peelStripWidthMm: 25.0,
                  peelRateMmPerMin: 10.0,
                  peelMeanForceNPerCm: 145.0,
                  peelPeakForceNPerCm: 168.0,
                  peelMinForceNPerCm: 122.0,
                  peelFailureMode: PeelFailureMode.cohesiveMastic,
                  peelDisplacementLoads: const [125.0, 140.0, 145.0, 150.0, 148.0],
                  tpiWitnessed: true,
                  inspectionDate: DateTime.now(),
                  dossierHashSha256: FieldJointRecord.generateCertificateHash(
                    newId,
                    weldCtrl.text,
                    16.5,
                    145.0,
                    0,
                  ),
                  loweringReleasePermitNo: 'OIL-NIRM-RLP-2026-0${_joints.length + 42}',
                );
                setState(() {
                  _joints.add(newRec);
                  _selectedJoint = newRec;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Field Joint $newId successfully logged!')),
                );
              },
              child: const Text('Create Joint Record'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignoffApprovalDialog(FieldJointRecord j) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Authorize Trench Lowering: ${j.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weld: ${j.weldNumber} • Chainage: ${j.chainageStr}'),
            const SizedBox(height: 8),
            const Text(
              'Zero-Defect Sign-off Verification:\n'
              '✓ Sa 2.5 Near-White Grit Blast Verified\n'
              '✓ Anchor Profile 50-75 µm Cleared\n'
              '✓ Bresle Soluble Salt < 2 µg/cm²\n'
              '✓ Induction Preheat 200-230°C Cleared\n'
              '✓ Sleeve Overlap ≥ 50mm Verified\n'
              '✓ Continuous DC Holiday Spark Test: 0 Pinholes\n'
              '✓ DIN 30670 Peel Adhesion > 100 N/cm Certified',
              style: TextStyle(fontSize: 11.5, color: AppTheme.tertiary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tertiary,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.tertiary,
                  content: Text(
                    'Joint ${j.id} Authorized for Trench Lowering! Permit: ${j.loweringReleasePermitNo}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            child: const Text('Confirm Sign-off'),
          ),
        ],
      ),
    );
  }

  void _showExportDossierModal(FieldJointRecord j) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FJC Inspection Dossier: ${j.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${j.weldNumber} • ${j.chainageStr} • Permit: ${j.loweringReleasePermitNo}',
              style: const TextStyle(fontSize: 11.5, color: AppTheme.primaryLight),
            ),
            const Divider(color: AppTheme.border, height: 16),
            Text(
              'Coating System: ${j.coatingSystem.label}\n'
              'Blast: ${j.blastStandard.shortCode} (${j.meanProfileDepthUm.toStringAsFixed(1)} µm) | Salt: ${j.bresleSaltDensityUgCm2.toStringAsFixed(2)} µg/cm²\n'
              'Induction Temp: ${j.meanPreheatTempC.toStringAsFixed(1)}°C (ΔT ${j.preheatDeltaC.toStringAsFixed(1)}°C)\n'
              'Total DFT: ${j.meanTotalDftMm.toStringAsFixed(2)} mm | Overlap: ${j.sleeveOverlapMmAhead.toStringAsFixed(0)}mm\n'
              'HV Holiday: ${j.holidayTestVoltageKv.toStringAsFixed(0)} kV (${j.holidaysDetected} Defects)\n'
              'Peel Adhesion: ${j.peelMeanForceNPerCm.toStringAsFixed(1)} N/cm (${j.peelFailureMode.label})\n'
              'Lead Inspector: ${j.inspectorName}\n'
              'TPI Witness: ${j.tpiInspector}\n'
              'SHA-256 Hash: ${j.dossierHashSha256}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dossier exported to PDF / Audit trail recorded.'),
                    ),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export Digital QA PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER: 360° PIPE JOINT CIRCUMFERENCE SCANNER
// ============================================================================

class _PipeCircumferencePainter extends CustomPainter {
  final double scanAngleDeg;
  final bool hasDefect;
  final bool isScanning;

  _PipeCircumferencePainter({
    required this.scanAngleDeg,
    required this.hasDefect,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) * 0.42;
    final innerRadius = outerRadius - 14.0;

    // Steel Pipe Wall Ring
    final steelPaint = Paint()
      ..color = const Color(0xFF1E2E5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    canvas.drawCircle(center, innerRadius, steelPaint);

    // Coating Sleeve Layer Ring
    final coatingPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;
    canvas.drawCircle(center, outerRadius, coatingPaint);

    // Clock hour markings
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final clockLabels = ['12', '3', '6', '9'];
    final angles = [-math.pi / 2, 0.0, math.pi / 2, math.pi];

    for (int i = 0; i < 4; i++) {
      final rad = angles[i];
      final pos = Offset(
        center.dx + (outerRadius + 18.0) * math.cos(rad),
        center.dy + (outerRadius + 18.0) * math.sin(rad),
      );
      textPainter.text = TextSpan(
        text: clockLabels[i],
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }

    // Known Defect Marker at ~225° (7:30 clock pos) if flagged
    if (hasDefect) {
      const defRad = 225.0 * math.pi / 180.0;
      final defPos = Offset(
        center.dx + outerRadius * math.cos(defRad),
        center.dy + outerRadius * math.sin(defRad),
      );
      final defectPaint = Paint()
        ..color = const Color(0xFFEF4444)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(defPos, 6.0, defectPaint);
    }

    // Scanning Spring Electrode & Spark Telemetry
    final scanRad = (scanAngleDeg - 90.0) * math.pi / 180.0;
    final electrodePos = Offset(
      center.dx + outerRadius * math.cos(scanRad),
      center.dy + outerRadius * math.sin(scanRad),
    );

    final electrodePaint = Paint()
      ..color = isScanning ? AppTheme.secondary : AppTheme.primaryLight
      ..style = PaintingStyle.fill;
    canvas.drawCircle(electrodePos, 7.0, electrodePaint);

    // Radial sweep ray
    if (isScanning) {
      final rayPaint = Paint()
        ..color = AppTheme.secondary.withValues(alpha: 0.5)
        ..strokeWidth = 1.8;
      canvas.drawLine(center, electrodePos, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PipeCircumferencePainter oldDelegate) {
    return oldDelegate.scanAngleDeg != scanAngleDeg ||
        oldDelegate.hasDefect != hasDefect ||
        oldDelegate.isScanning != isScanning;
  }
}
