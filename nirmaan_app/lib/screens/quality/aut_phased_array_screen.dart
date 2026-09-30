import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS — ASTM E1961 & API 1104 ANNEX A
// ============================================================================

enum WeldZoneId {
  capL,
  capR,
  fill4L,
  fill4R,
  fill3L,
  fill3R,
  fill2L,
  fill2R,
  fill1L,
  fill1R,
  hotPassL,
  hotPassR,
  rootL1,
  rootL2,
  tofd,
  coupling,
}

extension WeldZoneIdExt on WeldZoneId {
  String get displayName {
    switch (this) {
      case WeldZoneId.capL:
        return 'Cap Left (Upstream Toe)';
      case WeldZoneId.capR:
        return 'Cap Right (Downstream Toe)';
      case WeldZoneId.fill4L:
        return 'Fill 4 Left (Bevel Top)';
      case WeldZoneId.fill4R:
        return 'Fill 4 Right (Bevel Top)';
      case WeldZoneId.fill3L:
        return 'Fill 3 Left (Upper Mid)';
      case WeldZoneId.fill3R:
        return 'Fill 3 Right (Upper Mid)';
      case WeldZoneId.fill2L:
        return 'Fill 2 Left (Lower Mid)';
      case WeldZoneId.fill2R:
        return 'Fill 2 Right (Lower Mid)';
      case WeldZoneId.fill1L:
        return 'Fill 1 Left (Above HP)';
      case WeldZoneId.fill1R:
        return 'Fill 1 Right (Above HP)';
      case WeldZoneId.hotPassL:
        return 'Hot Pass Left (HP1)';
      case WeldZoneId.hotPassR:
        return 'Hot Pass Right (HP2)';
      case WeldZoneId.rootL1:
        return 'Root L1 (Upstream Land)';
      case WeldZoneId.rootL2:
        return 'Root L2 (Downstream Land)';
      case WeldZoneId.tofd:
        return 'TOFD Channel (Full Thickness)';
      case WeldZoneId.coupling:
        return 'Acoustic Coupling Monitor';
    }
  }

  String get shortCode {
    switch (this) {
      case WeldZoneId.capL:
        return 'CAP-L';
      case WeldZoneId.capR:
        return 'CAP-R';
      case WeldZoneId.fill4L:
        return 'F4-L';
      case WeldZoneId.fill4R:
        return 'F4-R';
      case WeldZoneId.fill3L:
        return 'F3-L';
      case WeldZoneId.fill3R:
        return 'F3-R';
      case WeldZoneId.fill2L:
        return 'F2-L';
      case WeldZoneId.fill2R:
        return 'F2-R';
      case WeldZoneId.fill1L:
        return 'F1-L';
      case WeldZoneId.fill1R:
        return 'F1-R';
      case WeldZoneId.hotPassL:
        return 'HP-L';
      case WeldZoneId.hotPassR:
        return 'HP-R';
      case WeldZoneId.rootL1:
        return 'ROOT-L1';
      case WeldZoneId.rootL2:
        return 'ROOT-L2';
      case WeldZoneId.tofd:
        return 'TOFD';
      case WeldZoneId.coupling:
        return 'COUP';
    }
  }

  double get nominalAngleDeg {
    switch (this) {
      case WeldZoneId.capL:
      case WeldZoneId.capR:
        return 70.0;
      case WeldZoneId.fill4L:
      case WeldZoneId.fill4R:
        return 45.0;
      case WeldZoneId.fill3L:
      case WeldZoneId.fill3R:
        return 50.0;
      case WeldZoneId.fill2L:
      case WeldZoneId.fill2R:
        return 55.0;
      case WeldZoneId.fill1L:
      case WeldZoneId.fill1R:
        return 60.0;
      case WeldZoneId.hotPassL:
      case WeldZoneId.hotPassR:
        return 65.0;
      case WeldZoneId.rootL1:
      case WeldZoneId.rootL2:
        return 70.0;
      case WeldZoneId.tofd:
        return 60.0;
      case WeldZoneId.coupling:
        return 0.0;
    }
  }

  double get depthStartMm {
    switch (this) {
      case WeldZoneId.capL:
      case WeldZoneId.capR:
        return 0.0;
      case WeldZoneId.fill4L:
      case WeldZoneId.fill4R:
        return 1.5;
      case WeldZoneId.fill3L:
      case WeldZoneId.fill3R:
        return 4.5;
      case WeldZoneId.fill2L:
      case WeldZoneId.fill2R:
        return 8.0;
      case WeldZoneId.fill1L:
      case WeldZoneId.fill1R:
        return 11.5;
      case WeldZoneId.hotPassL:
      case WeldZoneId.hotPassR:
        return 14.5;
      case WeldZoneId.rootL1:
      case WeldZoneId.rootL2:
        return 16.7;
      case WeldZoneId.tofd:
        return 0.0;
      case WeldZoneId.coupling:
        return 0.0;
    }
  }

  double get depthEndMm {
    switch (this) {
      case WeldZoneId.capL:
      case WeldZoneId.capR:
        return 2.0;
      case WeldZoneId.fill4L:
      case WeldZoneId.fill4R:
        return 4.5;
      case WeldZoneId.fill3L:
      case WeldZoneId.fill3R:
        return 8.0;
      case WeldZoneId.fill2L:
      case WeldZoneId.fill2R:
        return 11.5;
      case WeldZoneId.fill1L:
      case WeldZoneId.fill1R:
        return 14.5;
      case WeldZoneId.hotPassL:
      case WeldZoneId.hotPassR:
        return 16.7;
      case WeldZoneId.rootL1:
      case WeldZoneId.rootL2:
        return 18.2;
      case WeldZoneId.tofd:
        return 18.2;
      case WeldZoneId.coupling:
        return 18.2;
    }
  }
}

enum DefectClass {
  planar,
  nonPlanar,
}

extension DefectClassExt on DefectClass {
  String get label {
    switch (this) {
      case DefectClass.planar:
        return 'Planar (Sharp Notch / High SIF)';
      case DefectClass.nonPlanar:
        return 'Non-Planar (Volumetric / Blunt)';
    }
  }

  Color get color {
    switch (this) {
      case DefectClass.planar:
        return const Color(0xFFFF5252);
      case DefectClass.nonPlanar:
        return const Color(0xFFFFB95F);
    }
  }
}

enum DefectType {
  lackOfSidewallFusion,
  incompletePenetration,
  crack,
  slagInclusion,
  porosityCluster,
  hollowBead,
}

extension DefectTypeExt on DefectType {
  String get label {
    switch (this) {
      case DefectType.lackOfSidewallFusion:
        return 'Lack of Sidewall Fusion (LOSW)';
      case DefectType.incompletePenetration:
        return 'Incomplete Penetration (IP)';
      case DefectType.crack:
        return 'Root/Toe Micro-Crack';
      case DefectType.slagInclusion:
        return 'Elongated Slag Inclusion';
      case DefectType.porosityCluster:
        return 'Cluster Porosity';
      case DefectType.hollowBead:
        return 'Hollow Bead Porosity';
    }
  }

  DefectClass get defectClass {
    switch (this) {
      case DefectType.lackOfSidewallFusion:
      case DefectType.incompletePenetration:
      case DefectType.crack:
        return DefectClass.planar;
      case DefectType.slagInclusion:
      case DefectType.porosityCluster:
      case DefectType.hollowBead:
        return DefectClass.nonPlanar;
    }
  }

  String get standardReference {
    switch (this) {
      case DefectType.lackOfSidewallFusion:
        return 'API 1104 Annex A §A.5.1 / ASTM E1961 §7.3';
      case DefectType.incompletePenetration:
        return 'API 1104 Annex A §A.5.2 / ASTM E1961 §7.4';
      case DefectType.crack:
        return 'API 1104 Annex A §A.5.3 (Rejectable without ECA)';
      case DefectType.slagInclusion:
        return 'API 1104 Annex A §A.5.4 / ASTM E1961 §7.5';
      case DefectType.porosityCluster:
        return 'API 1104 Annex A §A.5.5 / ASTM E1961 §7.6';
      case DefectType.hollowBead:
        return 'API 1104 Annex A §A.5.6 / ASTM E1961 §7.7';
    }
  }
}

enum EcaDisposition {
  acceptable,
  repairRequired,
  monitoringRequired,
}

extension EcaDispositionExt on EcaDisposition {
  String get label {
    switch (this) {
      case EcaDisposition.acceptable:
        return 'ACCEPTABLE (ECA LEVEL 2)';
      case EcaDisposition.repairRequired:
        return 'REJECTABLE (CUT-OUT / REPAIR)';
      case EcaDisposition.monitoringRequired:
        return 'MONITORING REQUIRED';
    }
  }

  Color get color {
    switch (this) {
      case EcaDisposition.acceptable:
        return const Color(0xFF4EDEA3);
      case EcaDisposition.repairRequired:
        return const Color(0xFFFF5252);
      case EcaDisposition.monitoringRequired:
        return const Color(0xFFFFB95F);
    }
  }

  IconData get icon {
    switch (this) {
      case EcaDisposition.acceptable:
        return Icons.check_circle_rounded;
      case EcaDisposition.repairRequired:
        return Icons.dangerous_rounded;
      case EcaDisposition.monitoringRequired:
        return Icons.warning_amber_rounded;
    }
  }
}

enum ScanDisplayMode {
  sectoralSScan,
  linearEScan,
  circumferentialCScan,
}

// ----------------------------------------------------------------------------
// DATA CLASSES & CALCULATOR UTILITIES
// ----------------------------------------------------------------------------

class AutEcaCalculator {
  const AutEcaCalculator._();

  static double calculateDepthFromTofdTime({
    required double timeUs,
    required double pcsDistanceMm,
    double longitudinalVelocityMPerS = 5920.0,
  }) {
    final soundPathHalf = (longitudinalVelocityMPerS * timeUs * 1e-6) / 2.0 * 1000.0;
    final halfPcs = pcsDistanceMm / 2.0;
    if (soundPathHalf <= halfPcs) return 0.0;
    return math.sqrt(soundPathHalf * soundPathHalf - halfPcs * halfPcs);
  }

  static double calculateTofdTimeFromDepth({
    required double depthMm,
    required double pcsDistanceMm,
    double longitudinalVelocityMPerS = 5920.0,
  }) {
    final halfPcs = pcsDistanceMm / 2.0;
    final soundPathHalf = math.sqrt(depthMm * depthMm + halfPcs * halfPcs);
    return (2.0 * soundPathHalf / 1000.0) / longitudinalVelocityMPerS * 1e6;
  }

  static double calculateAllowableHeight({
    required double lengthMm,
    required DefectClass defectClass,
  }) {
    if (defectClass == DefectClass.planar) {
      if (lengthMm <= 10.0) return 3.20;
      if (lengthMm <= 25.0) return 2.45;
      if (lengthMm <= 40.0) return 1.85;
      if (lengthMm <= 60.0) return 1.50;
      return 1.20;
    } else {
      if (lengthMm <= 15.0) return 4.50;
      if (lengthMm <= 30.0) return 3.80;
      if (lengthMm <= 50.0) return 2.90;
      return 2.20;
    }
  }

  static EcaDisposition evaluateFlawDisposition({
    required double measuredHeightMm,
    required double allowableHeightMm,
  }) {
    if (measuredHeightMm <= allowableHeightMm) {
      return EcaDisposition.acceptable;
    }
    return EcaDisposition.repairRequired;
  }
}

class AutWeldZone {
  final WeldZoneId id;
  final String name;
  final String shortCode;
  final double depthStartMm;
  final double depthEndMm;
  final double refractedAngleDeg;
  final double probeFreqMhz;
  final double gateStartUs;
  final double gateWidthUs;
  final double recordingThresholdFsh; // 40%
  final double evaluationThresholdFsh; // 80%
  final double peakAmplitudeFsh;
  final bool hasIndication;
  final String calibratedReflector;

  const AutWeldZone({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.depthStartMm,
    required this.depthEndMm,
    required this.refractedAngleDeg,
    required this.probeFreqMhz,
    required this.gateStartUs,
    required this.gateWidthUs,
    required this.recordingThresholdFsh,
    required this.evaluationThresholdFsh,
    required this.peakAmplitudeFsh,
    required this.hasIndication,
    required this.calibratedReflector,
  });

  bool get isAboveThreshold => peakAmplitudeFsh >= evaluationThresholdFsh;
}

class AutFlawIndication {
  final String indicationId;
  final DefectType defectType;
  final WeldZoneId zone;
  final double circumferentialStartMm;
  final double circumferentialEndMm;
  final double lengthMm;
  final double depthFromOdMm;
  final double tofdHeightMm; // Sized within ±0.3mm
  final double tofdUncertaintyMm; // ±0.3 mm
  final bool isSurfaceBreaking;
  final double peakAmplitudeFsh;
  final double allowableHeightMm;
  final EcaDisposition disposition;
  final String clockPosition;
  final String repairWps;
  final String repairExcavationInstruction;

  const AutFlawIndication({
    required this.indicationId,
    required this.defectType,
    required this.zone,
    required this.circumferentialStartMm,
    required this.circumferentialEndMm,
    required this.lengthMm,
    required this.depthFromOdMm,
    required this.tofdHeightMm,
    this.tofdUncertaintyMm = 0.3,
    required this.isSurfaceBreaking,
    required this.peakAmplitudeFsh,
    required this.allowableHeightMm,
    required this.disposition,
    required this.clockPosition,
    required this.repairWps,
    required this.repairExcavationInstruction,
  });

  DefectClass get defectClass => defectType.defectClass;
}

class AutWeldJoint {
  final String jointNo;
  final String chainage;
  final String pipeSpec;
  final String steelGrade;
  final double pipeOdMm;
  final double wallThicknessMm;
  final String bevelType;
  final String autCrawler;
  final String operatorLevel3;
  final String tpiaWitness;
  final double scanSpeedMmS;
  final double totalCircumferenceMm;
  final String scanTimestamp;
  final List<AutWeldZone> zones;
  final List<AutFlawIndication> indications;
  final double couplingLossPercentage;
  final bool calibrationVerified;
  final String calibrationBlockSerial;

  const AutWeldJoint({
    required this.jointNo,
    required this.chainage,
    required this.pipeSpec,
    required this.steelGrade,
    required this.pipeOdMm,
    required this.wallThicknessMm,
    required this.bevelType,
    required this.autCrawler,
    required this.operatorLevel3,
    required this.tpiaWitness,
    required this.scanSpeedMmS,
    required this.totalCircumferenceMm,
    required this.scanTimestamp,
    required this.zones,
    required this.indications,
    required this.couplingLossPercentage,
    required this.calibrationVerified,
    required this.calibrationBlockSerial,
  });

  int get rejectCount =>
      indications.where((i) => i.disposition == EcaDisposition.repairRequired).length;

  int get acceptCount =>
      indications.where((i) => i.disposition == EcaDisposition.acceptable).length;

  bool get overallPass => rejectCount == 0 && couplingLossPercentage <= 2.0;
}

// ============================================================================
// MAIN WIDGET SCREEN
// ============================================================================

class AutPhasedArrayScreen extends StatefulWidget {
  const AutPhasedArrayScreen({super.key});

  @override
  State<AutPhasedArrayScreen> createState() => _AutPhasedArrayScreenState();
}

class _AutPhasedArrayScreenState extends State<AutPhasedArrayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Selected state
  late List<AutWeldJoint> _joints;
  late AutWeldJoint _selectedJoint;
  AutFlawIndication? _selectedFlaw;
  WeldZoneId _selectedZone = WeldZoneId.fill2R;
  ScanDisplayMode _scanDisplayMode = ScanDisplayMode.sectoralSScan;

  // Interactive controls
  double _circumferentialPositionMm = 425.0; // Near Flaw 1
  double _sectoralAngleDeg = 55.0; // Degrees

  // TOFD Precision Cursors (mm depth)
  double _tofdCursorUpperMm = 8.15;
  double _tofdCursorLowerMm = 10.31;
  final double _pcsDistanceMm = 78.5; // Probe Center Separation (2s)
  final double _longitudinalVelocityMPerS = 5920.0; // In steel

  // Search & Filter
  DefectClass? _flawFilterClass;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initSampleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initSampleData() {
    final zonesJoint1 = [
      const AutWeldZone(
        id: WeldZoneId.capL,
        name: 'Cap Left (Upstream Toe)',
        shortCode: 'CAP-L',
        depthStartMm: 0.0,
        depthEndMm: 2.0,
        refractedAngleDeg: 70.0,
        probeFreqMhz: 7.5,
        gateStartUs: 5.2,
        gateWidthUs: 1.4,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 34.0,
        hasIndication: false,
        calibratedReflector: '1.5mm EDM Notch OD (0.5mm depth)',
      ),
      const AutWeldZone(
        id: WeldZoneId.capR,
        name: 'Cap Right (Downstream Toe)',
        shortCode: 'CAP-R',
        depthStartMm: 0.0,
        depthEndMm: 2.0,
        refractedAngleDeg: 70.0,
        probeFreqMhz: 7.5,
        gateStartUs: 5.2,
        gateWidthUs: 1.4,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 38.0,
        hasIndication: false,
        calibratedReflector: '1.5mm EDM Notch OD (0.5mm depth)',
      ),
      const AutWeldZone(
        id: WeldZoneId.fill4L,
        name: 'Fill 4 Left (Bevel Top)',
        shortCode: 'F4-L',
        depthStartMm: 1.5,
        depthEndMm: 4.5,
        refractedAngleDeg: 45.0,
        probeFreqMhz: 7.5,
        gateStartUs: 7.0,
        gateWidthUs: 1.8,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 28.0,
        hasIndication: false,
        calibratedReflector: '2.0mm Flat Bottom Hole (FBH)',
      ),
      const AutWeldZone(
        id: WeldZoneId.fill4R,
        name: 'Fill 4 Right (Bevel Top)',
        shortCode: 'F4-R',
        depthStartMm: 1.5,
        depthEndMm: 4.5,
        refractedAngleDeg: 45.0,
        probeFreqMhz: 7.5,
        gateStartUs: 7.1,
        gateWidthUs: 1.8,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 62.0,
        hasIndication: true,
        calibratedReflector: '2.0mm Flat Bottom Hole (FBH)',
      ),
      const AutWeldZone(
        id: WeldZoneId.fill3L,
        name: 'Fill 3 Left (Upper Mid)',
        shortCode: 'F3-L',
        depthStartMm: 4.5,
        depthEndMm: 8.0,
        refractedAngleDeg: 50.0,
        probeFreqMhz: 7.5,
        gateStartUs: 8.5,
        gateWidthUs: 2.0,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 31.0,
        hasIndication: false,
        calibratedReflector: '2.0mm Flat Bottom Hole (FBH)',
      ),
      const AutWeldZone(
        id: WeldZoneId.fill3R,
        name: 'Fill 3 Right (Upper Mid)',
        shortCode: 'F3-R',
        depthStartMm: 4.5,
        depthEndMm: 8.0,
        refractedAngleDeg: 50.0,
        probeFreqMhz: 7.5,
        gateStartUs: 8.6,
        gateWidthUs: 2.0,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 35.0,
        hasIndication: false,
        calibratedReflector: '2.0mm Flat Bottom Hole (FBH)',
      ),
      const AutWeldZone(
        id: WeldZoneId.fill2L,
        name: 'Fill 2 Left (Lower Mid)',
        shortCode: 'F2-L',
        depthStartMm: 8.0,
        depthEndMm: 11.5,
        refractedAngleDeg: 55.0,
        probeFreqMhz: 7.5,
        gateStartUs: 10.1,
        gateWidthUs: 2.2,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 29.0,
        hasIndication: false,
        calibratedReflector: '2.0mm Flat Bottom Hole (FBH)',
      ),
      const AutWeldZone(
        id: WeldZoneId.fill2R,
        name: 'Fill 2 Right (Lower Mid)',
        shortCode: 'F2-R',
        depthStartMm: 8.0,
        depthEndMm: 11.5,
        refractedAngleDeg: 55.0,
        probeFreqMhz: 7.5,
        gateStartUs: 10.2,
        gateWidthUs: 2.2,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 94.2,
        hasIndication: true,
        calibratedReflector: '2.0mm Flat Bottom Hole (FBH)',
      ),
      const AutWeldZone(
        id: WeldZoneId.fill1L,
        name: 'Fill 1 Left (Above HP)',
        shortCode: 'F1-L',
        depthStartMm: 11.5,
        depthEndMm: 14.5,
        refractedAngleDeg: 60.0,
        probeFreqMhz: 7.5,
        gateStartUs: 11.8,
        gateWidthUs: 2.4,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 26.0,
        hasIndication: false,
        calibratedReflector: '2.0mm Flat Bottom Hole (FBH)',
      ),
      const AutWeldZone(
        id: WeldZoneId.fill1R,
        name: 'Fill 1 Right (Above HP)',
        shortCode: 'F1-R',
        depthStartMm: 11.5,
        depthEndMm: 14.5,
        refractedAngleDeg: 60.0,
        probeFreqMhz: 7.5,
        gateStartUs: 11.9,
        gateWidthUs: 2.4,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 30.0,
        hasIndication: false,
        calibratedReflector: '2.0mm Flat Bottom Hole (FBH)',
      ),
      const AutWeldZone(
        id: WeldZoneId.hotPassL,
        name: 'Hot Pass Left (HP1)',
        shortCode: 'HP-L',
        depthStartMm: 14.5,
        depthEndMm: 16.7,
        refractedAngleDeg: 65.0,
        probeFreqMhz: 7.5,
        gateStartUs: 13.5,
        gateWidthUs: 2.2,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 33.0,
        hasIndication: false,
        calibratedReflector: '2.0mm Flat Bottom Hole (FBH)',
      ),
      const AutWeldZone(
        id: WeldZoneId.hotPassR,
        name: 'Hot Pass Right (HP2)',
        shortCode: 'HP-R',
        depthStartMm: 14.5,
        depthEndMm: 16.7,
        refractedAngleDeg: 65.0,
        probeFreqMhz: 7.5,
        gateStartUs: 13.6,
        gateWidthUs: 2.2,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 36.0,
        hasIndication: false,
        calibratedReflector: '2.0mm Flat Bottom Hole (FBH)',
      ),
      const AutWeldZone(
        id: WeldZoneId.rootL1,
        name: 'Root L1 (Upstream Land)',
        shortCode: 'ROOT-L1',
        depthStartMm: 16.7,
        depthEndMm: 18.2,
        refractedAngleDeg: 70.0,
        probeFreqMhz: 7.5,
        gateStartUs: 15.2,
        gateWidthUs: 2.0,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 106.5,
        hasIndication: true,
        calibratedReflector: '1.5mm EDM Notch ID (1.0mm depth)',
      ),
      const AutWeldZone(
        id: WeldZoneId.rootL2,
        name: 'Root L2 (Downstream Land)',
        shortCode: 'ROOT-L2',
        depthStartMm: 16.7,
        depthEndMm: 18.2,
        refractedAngleDeg: 70.0,
        probeFreqMhz: 7.5,
        gateStartUs: 15.3,
        gateWidthUs: 2.0,
        recordingThresholdFsh: 40.0,
        evaluationThresholdFsh: 80.0,
        peakAmplitudeFsh: 39.0,
        hasIndication: false,
        calibratedReflector: '1.5mm EDM Notch ID (1.0mm depth)',
      ),
      const AutWeldZone(
        id: WeldZoneId.tofd,
        name: 'TOFD Channel (Full Thickness)',
        shortCode: 'TOFD',
        depthStartMm: 0.0,
        depthEndMm: 18.2,
        refractedAngleDeg: 60.0,
        probeFreqMhz: 15.0,
        gateStartUs: 13.2,
        gateWidthUs: 5.0,
        recordingThresholdFsh: 20.0,
        evaluationThresholdFsh: 60.0,
        peakAmplitudeFsh: 72.0,
        hasIndication: true,
        calibratedReflector: 'Through-transmission & Lateral wave',
      ),
      const AutWeldZone(
        id: WeldZoneId.coupling,
        name: 'Acoustic Coupling Monitor',
        shortCode: 'COUP',
        depthStartMm: 0.0,
        depthEndMm: 18.2,
        refractedAngleDeg: 0.0,
        probeFreqMhz: 5.0,
        gateStartUs: 4.0,
        gateWidthUs: 2.0,
        recordingThresholdFsh: 50.0,
        evaluationThresholdFsh: 50.0,
        peakAmplitudeFsh: 98.4,
        hasIndication: false,
        calibratedReflector: '0dB Attenuation reference (> -6dB threshold)',
      ),
    ];

    final indicationsJoint1 = [
      const AutFlawIndication(
        indicationId: 'IND-01',
        defectType: DefectType.lackOfSidewallFusion,
        zone: WeldZoneId.fill2R,
        circumferentialStartMm: 412.0,
        circumferentialEndMm: 436.5,
        lengthMm: 24.5,
        depthFromOdMm: 9.42,
        tofdHeightMm: 2.16,
        tofdUncertaintyMm: 0.3,
        isSurfaceBreaking: false,
        peakAmplitudeFsh: 94.2,
        allowableHeightMm: 2.45, // ECA curve gives 2.45 mm for L=24.5 mm
        disposition: EcaDisposition.acceptable, // 2.16 <= 2.45 mm
        clockPosition: '02:35 to 02:44 (Top Right)',
        repairWps: 'N/A — ACCEPTED UNDER API 1104 ANNEX A ECA',
        repairExcavationInstruction:
            'Indication is an embedded planar sidewall lack of fusion. '
            'TOFD verified height h=2.16±0.3mm is within allowable ECA boundary (2.45mm). '
            'No excavation required. Retain in pipeline integrity baseline record.',
      ),
      const AutFlawIndication(
        indicationId: 'IND-02',
        defectType: DefectType.incompletePenetration,
        zone: WeldZoneId.rootL1,
        circumferentialStartMm: 1120.0,
        circumferentialEndMm: 1168.0,
        lengthMm: 48.0,
        depthFromOdMm: 17.15,
        tofdHeightMm: 2.82,
        tofdUncertaintyMm: 0.3,
        isSurfaceBreaking: true,
        peakAmplitudeFsh: 106.5,
        allowableHeightMm: 1.55, // For surface-breaking planar L=48 mm, max is 1.55 mm
        disposition: EcaDisposition.repairRequired, // 2.82 > 1.55 mm -> REJECT
        clockPosition: '07:01 to 07:19 (Bottom Left)',
        repairWps: 'WPS-OIL-ECA-REPAIR-03 (SMAW E8010-P1 / E9018-G)',
        repairExcavationInstruction:
            'Excavate from OD at circumferential position 1115mm to 1175mm (clock 07:00-07:20). '
            'Full depth excavation to root land (17.5mm depth). '
            'Confirm removal via MT (wet fluorescent) and re-inspect with 100% PAUT + TOFD.',
      ),
      const AutFlawIndication(
        indicationId: 'IND-03',
        defectType: DefectType.slagInclusion,
        zone: WeldZoneId.fill4R,
        circumferentialStartMm: 1640.0,
        circumferentialEndMm: 1668.0,
        lengthMm: 28.0,
        depthFromOdMm: 3.10,
        tofdHeightMm: 1.38,
        tofdUncertaintyMm: 0.3,
        isSurfaceBreaking: false,
        peakAmplitudeFsh: 62.0,
        allowableHeightMm: 3.80, // Non-planar curve gives 3.8 mm for L=28 mm
        disposition: EcaDisposition.acceptable, // 1.38 <= 3.80 mm
        clockPosition: '10:17 to 10:27 (Top Left)',
        repairWps: 'N/A — ACCEPTED (NON-PLANAR ECA)',
        repairExcavationInstruction:
            'Embedded volumetric slag inclusion. Length 28mm, height 1.38mm. '
            'Well below non-planar acceptance threshold (3.80mm). Compliant with API 1104 Annex A.',
      ),
    ];

    _joints = [
      AutWeldJoint(
        jointNo: 'GW-KP-142+500',
        chainage: 'KP 142+500.00',
        pipeSpec: '24" OD (609.6 mm) x 18.2 mm WT, API 5L X70 PSL2, LSAW',
        steelGrade: 'API 5L X70 PSL2 (SMYS: 485 MPa, CTOD: 0.18 mm)',
        pipeOdMm: 609.6,
        wallThicknessMm: 18.2,
        bevelType: 'CRC-Evans Narrow Gap Compound J-Bevel (5° / 1.5mm land)',
        autCrawler: 'PipeWizard V4 Mechanized Crawler (Dual 128-ch PA + 15MHz TOFD)',
        operatorLevel3: 'Er. Vikramaditya Rao (ASNT Level III AUT #84912)',
        tpiaWitness: 'Engineers India Limited (EIL / TPIA Level III)',
        scanSpeedMmS: 50.0,
        totalCircumferenceMm: 1915.0,
        scanTimestamp: '2026-09-30 08:45 IST',
        zones: zonesJoint1,
        indications: indicationsJoint1,
        couplingLossPercentage: 0.0,
        calibrationVerified: true,
        calibrationBlockSerial: 'CAL-X70-24-18.2-04',
      ),
      AutWeldJoint(
        jointNo: 'GW-KP-142+524',
        chainage: 'KP 142+524.00',
        pipeSpec: '24" OD (609.6 mm) x 18.2 mm WT, API 5L X70 PSL2, LSAW',
        steelGrade: 'API 5L X70 PSL2 (SMYS: 485 MPa, CTOD: 0.18 mm)',
        pipeOdMm: 609.6,
        wallThicknessMm: 18.2,
        bevelType: 'CRC-Evans Narrow Gap Compound J-Bevel (5° / 1.5mm land)',
        autCrawler: 'PipeWizard V4 Mechanized Crawler (Dual 128-ch PA + 15MHz TOFD)',
        operatorLevel3: 'Er. Vikramaditya Rao (ASNT Level III AUT #84912)',
        tpiaWitness: 'Engineers India Limited (EIL / TPIA Level III)',
        scanSpeedMmS: 50.0,
        totalCircumferenceMm: 1915.0,
        scanTimestamp: '2026-09-30 09:30 IST',
        zones: zonesJoint1,
        indications: [
          const AutFlawIndication(
            indicationId: 'IND-01',
            defectType: DefectType.porosityCluster,
            zone: WeldZoneId.fill3L,
            circumferentialStartMm: 850.0,
            circumferentialEndMm: 864.0,
            lengthMm: 14.0,
            depthFromOdMm: 6.20,
            tofdHeightMm: 1.12,
            tofdUncertaintyMm: 0.3,
            isSurfaceBreaking: false,
            peakAmplitudeFsh: 58.0,
            allowableHeightMm: 4.20,
            disposition: EcaDisposition.acceptable,
            clockPosition: '05:20 to 05:25',
            repairWps: 'N/A — ACCEPTED (ECA)',
            repairExcavationInstruction: 'Isolated mid-wall cluster porosity.',
          ),
        ],
        couplingLossPercentage: 0.0,
        calibrationVerified: true,
        calibrationBlockSerial: 'CAL-X70-24-18.2-04',
      ),
      AutWeldJoint(
        jointNo: 'GW-KP-142+548',
        chainage: 'KP 142+548.00',
        pipeSpec: '24" OD (609.6 mm) x 18.2 mm WT, API 5L X70 PSL2, LSAW',
        steelGrade: 'API 5L X70 PSL2 (SMYS: 485 MPa, CTOD: 0.18 mm)',
        pipeOdMm: 609.6,
        wallThicknessMm: 18.2,
        bevelType: 'CRC-Evans Narrow Gap Compound J-Bevel (5° / 1.5mm land)',
        autCrawler: 'PipeWizard V4 Mechanized Crawler (Dual 128-ch PA + 15MHz TOFD)',
        operatorLevel3: 'Er. Vikramaditya Rao (ASNT Level III AUT #84912)',
        tpiaWitness: 'Engineers India Limited (EIL / TPIA Level III)',
        scanSpeedMmS: 50.0,
        totalCircumferenceMm: 1915.0,
        scanTimestamp: '2026-09-30 10:15 IST',
        zones: zonesJoint1,
        indications: const [],
        couplingLossPercentage: 0.0,
        calibrationVerified: true,
        calibrationBlockSerial: 'CAL-X70-24-18.2-04',
      ),
    ];

    _selectedJoint = _joints.first;
    _selectedFlaw = _selectedJoint.indications.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildExecutiveSummaryBanner(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildZonalStripChartTab(),
                _buildPhasedArraySScanTab(),
                _buildTofdChannelTab(),
                _buildEcaEvaluationTab(),
                _buildCalibrationBlockTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'AUT Phased Array & TOFD',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primaryLight, width: 0.8),
                ),
                child: const Text(
                  'ASTM E1961',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'API 1104 Annex A ECA • CRC-Evans J-Bevel 24" X70',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Select Girth Weld Joint',
          icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.textPrimary),
          onPressed: _showJointSelectDialog,
        ),
        IconButton(
          tooltip: 'Calibration Block Verification',
          icon: const Icon(Icons.tune_rounded, color: AppTheme.secondary),
          onPressed: _showCalibrationModal,
        ),
        IconButton(
          tooltip: 'Inspection Dossier / SHA-256 Report',
          icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.tertiary),
          onPressed: _showExportDossierModal,
        ),
      ],
    );
  }

  Widget _buildExecutiveSummaryBanner() {
    final statusColor = _selectedJoint.overallPass
        ? AppTheme.tertiary
        : AppTheme.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 1.2),
                ),
                child: Icon(
                  _selectedJoint.overallPass
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _selectedJoint.jointNo,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedJoint.chainage,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedJoint.pipeSpec,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  _selectedJoint.overallPass ? 'ALL PASS (ECA)' : '1 REPAIR CUT-OUT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 4 KPIs Strip
          Row(
            children: [
              _buildKpiCell(
                label: 'AUT COVERAGE',
                value: '100% (1915mm)',
                color: AppTheme.primaryLight,
              ),
              _buildKpiCell(
                label: 'TOFD ACCURACY',
                value: '±0.3 mm Sizing',
                color: AppTheme.tertiary,
              ),
              _buildKpiCell(
                label: 'COUPLING LOSS',
                value: '${_selectedJoint.couplingLossPercentage.toStringAsFixed(1)}% (PASS)',
                color: AppTheme.tertiary,
              ),
              _buildKpiCell(
                label: 'DEFECTS DETECTED',
                value: '${_selectedJoint.indications.length} Flaws',
                color: _selectedJoint.indications.isEmpty
                    ? AppTheme.tertiary
                    : AppTheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCell({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
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
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
        indicatorWeight: 2.5,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.view_column_rounded, size: 18),
            text: 'Zonal Strip Chart',
          ),
          Tab(
            icon: Icon(Icons.radar_rounded, size: 18),
            text: 'PAUT S-Scan & E-Scan',
          ),
          Tab(
            icon: Icon(Icons.graphic_eq_rounded, size: 18),
            text: 'TOFD (±0.3mm)',
          ),
          Tab(
            icon: Icon(Icons.analytics_rounded, size: 18),
            text: 'API 1104 ECA',
          ),
          Tab(
            icon: Icon(Icons.verified_rounded, size: 18),
            text: 'ASTM E1961 Calib',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: ZONAL STRIP CHART (ASTM E1961)
  // ==========================================================================

  Widget _buildZonalStripChartTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: 'ZONAL DISCRIMINATION METHOD (ASTM E1961-16)',
            subtitle:
                'Division of CRC-Evans compound bevel into 14 discrete focused examination gates',
            icon: Icons.layers_rounded,
            child: Column(
              children: [
                _buildCircumferentialScrubber(),
                const SizedBox(height: 16),
                _buildStripChartChannelsWidget(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'BEVEL ZONAL DISSECTION MATRIX',
            subtitle:
                'Target zones: Root L1/L2, Hot Pass L/R, Fill 1-4 L/R, Cap L/R & Acoustic Coupling',
            icon: Icons.table_chart_rounded,
            child: _buildZonalMatrixTable(),
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'AUT SCAN RIG & OPTICAL ENCODER TELEMETRY',
            subtitle:
                'High-speed mechanized crawler tracking at 50 mm/sec with 0.1 mm position resolution',
            icon: Icons.precision_manufacturing_rounded,
            child: _buildEncoderTelemetry(),
          ),
        ],
      ),
    );
  }

  Widget _buildCircumferentialScrubber() {
    final clockHours = (_circumferentialPositionMm / _selectedJoint.totalCircumferenceMm * 12.0);
    final hours = clockHours.floor();
    final minutes = ((clockHours - hours) * 60).round();
    final clockStr = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} O\'Clock';

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Circumferential Index Position (X-Axis):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primaryLight, width: 0.8),
                ),
                child: Text(
                  '${_circumferentialPositionMm.toStringAsFixed(1)} mm ($clockStr)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primaryLight,
              inactiveTrackColor: AppTheme.border,
              thumbColor: AppTheme.secondary,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: _circumferentialPositionMm,
              min: 0.0,
              max: _selectedJoint.totalCircumferenceMm,
              onChanged: (val) {
                setState(() {
                  _circumferentialPositionMm = val;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('00:00 (0 mm / TDC)',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text('06:00 (957.5 mm / BDC)',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text('12:00 (1915 mm / Wrap)',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStripChartChannelsWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '14-CHANNEL REAL-TIME STRIP CHART (ASTM E1961)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
            Row(
              children: [
                _buildLegendItem('Pass <40%', AppTheme.tertiary),
                const SizedBox(width: 8),
                _buildLegendItem('Record 40-80%', AppTheme.secondary),
                const SizedBox(width: 8),
                _buildLegendItem('Eval >80%', AppTheme.error),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 380,
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedJoint.zones.length,
            separatorBuilder: (context, i) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final zone = _selectedJoint.zones[index];
              return _buildStripChannelRow(zone);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStripChannelRow(AutWeldZone zone) {
    // Generate dynamic amplitude based on current position and flaw location
    double currentFsh = zone.peakAmplitudeFsh;

    // Check if current position matches flaw zone
    final flawInZone = _selectedJoint.indications.firstWhere(
      (f) =>
          f.zone == zone.id &&
          _circumferentialPositionMm >= f.circumferentialStartMm - 10 &&
          _circumferentialPositionMm <= f.circumferentialEndMm + 10,
      orElse: () => const AutFlawIndication(
        indicationId: '',
        defectType: DefectType.lackOfSidewallFusion,
        zone: WeldZoneId.capL,
        circumferentialStartMm: 0,
        circumferentialEndMm: 0,
        lengthMm: 0,
        depthFromOdMm: 0,
        tofdHeightMm: 0,
        isSurfaceBreaking: false,
        peakAmplitudeFsh: 0,
        allowableHeightMm: 0,
        disposition: EcaDisposition.acceptable,
        clockPosition: '',
        repairWps: '',
        repairExcavationInstruction: '',
      ),
    );

    if (flawInZone.indicationId.isNotEmpty) {
      currentFsh = flawInZone.peakAmplitudeFsh;
    } else {
      // Background noise
      currentFsh = math.min(currentFsh * 0.3, 30.0);
    }

    Color barColor = AppTheme.tertiary;
    if (currentFsh >= zone.evaluationThresholdFsh) {
      barColor = AppTheme.error;
    } else if (currentFsh >= zone.recordingThresholdFsh) {
      barColor = AppTheme.secondary;
    }

    final isSelected = _selectedZone == zone.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedZone = zone.id;
          _sectoralAngleDeg = zone.refractedAngleDeg;
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.border.withValues(alpha: 0.4),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                zone.shortCode,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppTheme.primaryLight : AppTheme.textPrimary,
                ),
              ),
            ),
            SizedBox(
              width: 55,
              child: Text(
                '${zone.refractedAngleDeg.toInt()}°',
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Threshold line 80%
                  Positioned(
                    left: 0.8 * 180, // Approximate scale
                    child: Container(
                      width: 1.5,
                      height: 14,
                      color: AppTheme.error.withValues(alpha: 0.6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: math.min(currentFsh / 120.0, 1.0),
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 55,
              child: Text(
                '${currentFsh.toStringAsFixed(1)}%',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
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
          style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildZonalMatrixTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 36,
          horizontalMargin: 12,
          columnSpacing: 16,
          headingTextStyle: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          columns: const [
            DataColumn(label: Text('ZONE')),
            DataColumn(label: Text('DEPTH RANGE')),
            DataColumn(label: Text('ANGLE')),
            DataColumn(label: Text('GATE (μs)')),
            DataColumn(label: Text('CAL REFLECTOR')),
            DataColumn(label: Text('MAX FSH')),
            DataColumn(label: Text('STATUS')),
          ],
          rows: _selectedJoint.zones.map((zone) {
            final hasIndication = zone.hasIndication;
            final isFail = zone.peakAmplitudeFsh >= zone.evaluationThresholdFsh;

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    zone.shortCode,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${zone.depthStartMm.toStringAsFixed(1)} - ${zone.depthEndMm.toStringAsFixed(1)} mm',
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                  ),
                ),
                DataCell(
                  Text(
                    '${zone.refractedAngleDeg.toInt()}°',
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                  ),
                ),
                DataCell(
                  Text(
                    '${zone.gateStartUs.toStringAsFixed(1)} + ${zone.gateWidthUs.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                  ),
                ),
                DataCell(
                  Text(
                    zone.calibratedReflector,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ),
                DataCell(
                  Text(
                    '${zone.peakAmplitudeFsh.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isFail ? AppTheme.error : (hasIndication ? AppTheme.secondary : AppTheme.tertiary),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isFail ? AppTheme.error : (hasIndication ? AppTheme.secondary : AppTheme.tertiary))
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isFail ? 'EVALUATION' : (hasIndication ? 'RECORD' : 'CLEAR'),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isFail ? AppTheme.error : (hasIndication ? AppTheme.secondary : AppTheme.tertiary),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEncoderTelemetry() {
    return Column(
      children: [
        Row(
          children: [
            _buildTelemetryItem(
              'OPTICAL ENCODER 1',
              'Resolution 0.1 mm',
              'Active (Tire-Drive Track)',
              AppTheme.tertiary,
            ),
            const SizedBox(width: 8),
            _buildTelemetryItem(
              'OPTICAL ENCODER 2',
              'Redundancy Sync',
              'Sync Drift < 0.2 mm',
              AppTheme.tertiary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTelemetryItem(
              'SCAN SPEED',
              '50.0 mm/s',
              'Target 45-55 mm/s (Compliant)',
              AppTheme.primaryLight,
            ),
            const SizedBox(width: 8),
            _buildTelemetryItem(
              'COUPLING LOSS GATE',
              'Through-Transmission',
              'Attenuation Margin: +14.2 dB',
              AppTheme.tertiary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelemetryItem(
    String title,
    String value,
    String subtext,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 2: PHASED ARRAY S-SCAN & E-SCAN
  // ==========================================================================

  Widget _buildPhasedArraySScanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Control strip for S-Scan vs E-Scan
          _buildCard(
            title: 'PHASED ARRAY ELECTRONIC SCANNING MODE',
            subtitle:
                'Electronic Sectoral Scan (S-Scan: 40°-72°) vs Electronic Linear Scan (E-Scan: 60° Fixed)',
            icon: Icons.graphic_eq_rounded,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<ScanDisplayMode>(
                        segments: const [
                          ButtonSegment(
                            value: ScanDisplayMode.sectoralSScan,
                            label: Text('Sectoral S-Scan (40°-72°)'),
                            icon: Icon(Icons.pie_chart_outline_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: ScanDisplayMode.linearEScan,
                            label: Text('Linear E-Scan (L-Scan)'),
                            icon: Icon(Icons.linear_scale_rounded, size: 16),
                          ),
                        ],
                        selected: {_scanDisplayMode},
                        onSelectionChanged: (Set<ScanDisplayMode> selected) {
                          setState(() {
                            _scanDisplayMode = selected.first;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppTheme.primary;
                            }
                            return AppTheme.surfaceContainerHigh;
                          }),
                          foregroundColor: WidgetStateProperty.all(AppTheme.textPrimary),
                          textStyle: WidgetStateProperty.all(
                            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _scanDisplayMode == ScanDisplayMode.sectoralSScan
                                    ? 'Sectorial Sweep Angle (θ):'
                                    : 'Aperture Index (Element Span):',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                              Text(
                                _scanDisplayMode == ScanDisplayMode.sectoralSScan
                                    ? '${_sectoralAngleDeg.toStringAsFixed(1)}°'
                                    : 'Elements 32-64 (Center)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _sectoralAngleDeg,
                            min: 40.0,
                            max: 72.0,
                            divisions: 64,
                            activeColor: AppTheme.primaryLight,
                            inactiveColor: AppTheme.border,
                            onChanged: (val) {
                              setState(() {
                                _sectoralAngleDeg = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('FOCAL LAW DEPTH',
                                style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              '${(math.cos(_sectoralAngleDeg * math.pi / 180.0) * 22.0).toStringAsFixed(1)} mm',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.secondary),
                            ),
                            const Text('True Vertical Depth',
                                style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // S-Scan Visualizer Card (CustomPainter)
          _buildCard(
            title: 'WELD BEVEL PROFILE & ACOUSTIC HEATMAP',
            subtitle:
                'CRC-Evans Narrow Gap J-Bevel (18.2mm WT) with ray traces and volumetric amplitude echo',
            icon: Icons.radar_rounded,
            child: Column(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF070D1E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: PhasedArraySScanPainter(
                        selectedAngleDeg: _sectoralAngleDeg,
                        displayMode: _scanDisplayMode,
                        wallThicknessMm: _selectedJoint.wallThicknessMm,
                        flaw: _selectedFlaw,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildHeatmapColorScaleBar(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // A-Scan Oscilloscope Card
          _buildCard(
            title: 'SYNCHRONIZED RF A-SCAN OSCILLOSCOPE',
            subtitle:
                'Reflected wave RF rectified waveform with Gate A threshold monitor at ${_sectoralAngleDeg.toStringAsFixed(1)}°',
            icon: Icons.show_chart_rounded,
            child: Column(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF050914),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: AScanOscilloscopePainter(
                        angleDeg: _sectoralAngleDeg,
                        peakFsh: _selectedFlaw != null ? _selectedFlaw!.peakAmplitudeFsh : 45.0,
                        thresholdFsh: 80.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildOscilloscopeMetric(
                      'PEAK AMPLITUDE',
                      '${(_selectedFlaw?.peakAmplitudeFsh ?? 45.0).toStringAsFixed(1)}% FSH',
                      (_selectedFlaw?.peakAmplitudeFsh ?? 45.0) >= 80.0
                          ? AppTheme.error
                          : AppTheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    _buildOscilloscopeMetric(
                      'SOUND PATH (W)',
                      '${(18.2 / math.cos(_sectoralAngleDeg * math.pi / 180.0)).toStringAsFixed(1)} mm',
                      AppTheme.primaryLight,
                    ),
                    const SizedBox(width: 8),
                    _buildOscilloscopeMetric(
                      'TIME OF FLIGHT',
                      '${((18.2 / math.cos(_sectoralAngleDeg * math.pi / 180.0)) / 3.24).toStringAsFixed(2)} μs',
                      AppTheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    _buildOscilloscopeMetric(
                      'GATE STATUS',
                      (_selectedFlaw?.peakAmplitudeFsh ?? 45.0) >= 80.0 ? '+1.4 dB' : '-6.2 dB',
                      (_selectedFlaw?.peakAmplitudeFsh ?? 45.0) >= 80.0
                          ? AppTheme.error
                          : AppTheme.tertiary,
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

  Widget _buildHeatmapColorScaleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Text('AMPLITUDE % FSH:  ',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
          Expanded(
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0B2545), // Deep Blue (0%)
                    Color(0xFF134E5E), // Teal (20%)
                    Color(0xFF71B280), // Green (40%)
                    Color(0xFFFFB95F), // Amber (60%)
                    Color(0xFFFF5252), // Red (80% Threshold)
                    Color(0xFFFF0055), // Magenta (>100% Saturation)
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('0%       40%       80%      120%',
              style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildOscilloscopeMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8.5, color: AppTheme.textMuted)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 3: TOFD (TIME-OF-FLIGHT DIFFRACTION) SIZING CHANNEL
  // ==========================================================================

  Widget _buildTofdChannelTab() {
    // Height calculation via TOFD tip diffraction formula:
    // d_top = sqrt((c*t1/2)^2 - s^2)
    // d_bottom = sqrt((c*t2/2)^2 - s^2)
    // Height = d_bottom - d_top
    final calculatedHeightMm = (_tofdCursorLowerMm - _tofdCursorUpperMm).abs();
    final ligamentToOdMm = _tofdCursorUpperMm;
    final ligamentToIdMm = _selectedJoint.wallThicknessMm - _tofdCursorLowerMm;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOFD Theory & Sizing Accuracy Strip
          _buildCard(
            title: 'TIME-OF-FLIGHT DIFFRACTION (TOFD) SIZING CHANNEL',
            subtitle:
                'Non-amplitude tip diffraction measurement for flaw height sizing within ±0.3 mm accuracy',
            icon: Icons.straighten_rounded,
            child: Column(
              children: [
                Row(
                  children: [
                    _buildTofdStatBox(
                      'PROBE CENTER SEP (2s)',
                      '${_pcsDistanceMm.toStringAsFixed(1)} mm',
                      'Pitch-Catch Setup',
                      AppTheme.primaryLight,
                    ),
                    const SizedBox(width: 8),
                    _buildTofdStatBox(
                      'L-WAVE VELOCITY (c)',
                      '${_longitudinalVelocityMPerS.toInt()} m/s',
                      'Carbon Steel X70',
                      AppTheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    _buildTofdStatBox(
                      'SIZING ACCURACY',
                      '±0.30 mm',
                      'API 1104 Annex A',
                      AppTheme.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.tertiary, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppTheme.tertiary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ASTM E1961 §7.8 Mandate: TOFD shall be utilized simultaneously with Phased Array '
                          'for accurate flaw height (2a) measurement, avoiding amplitude shadowing errors.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.tertiary.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // TOFD Greyscale B-Scan CustomPainter
          _buildCard(
            title: 'TOFD GREYSCALE B-SCAN (D-SCAN COMPOSITE)',
            subtitle:
                'Lateral Wave (LW: OD surface), Upper Tip Diffracted Signal, Lower Tip Diffracted Signal & Backwall Echo (BW: ID)',
            icon: Icons.waves_rounded,
            child: Column(
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: TofdGreyscalePainter(
                        cursorUpperMm: _tofdCursorUpperMm,
                        cursorLowerMm: _tofdCursorLowerMm,
                        wallThicknessMm: _selectedJoint.wallThicknessMm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTofdCursorControls(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Real-time TOFD Precision Sizing Readout Card
          _buildCard(
            title: 'DEFECT HEIGHT & EMBEDMENT COMPUTATION',
            subtitle:
                'Mathematical triangulation solving d = √((c·t/2)² - s²) with ligament checks',
            icon: Icons.calculate_rounded,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'MEASURED FLAW HEIGHT (2a):',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${calculatedHeightMm.toStringAsFixed(2)} mm ± 0.3 mm',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppTheme.border, height: 20),
                      Row(
                        children: [
                          _buildLigamentCell(
                            'UPPER TIP DEPTH',
                            '${_tofdCursorUpperMm.toStringAsFixed(2)} mm',
                            'From Outer Surface (OD)',
                            AppTheme.primaryLight,
                          ),
                          _buildLigamentCell(
                            'LOWER TIP DEPTH',
                            '${_tofdCursorLowerMm.toStringAsFixed(2)} mm',
                            'From Outer Surface (OD)',
                            AppTheme.primaryLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildLigamentCell(
                            'LIGAMENT TO OD',
                            '${ligamentToOdMm.toStringAsFixed(2)} mm',
                            ligamentToOdMm < 1.0 ? 'Surface-Breaking' : 'Sub-surface Embedded',
                            ligamentToOdMm < 1.0 ? AppTheme.error : AppTheme.tertiary,
                          ),
                          _buildLigamentCell(
                            'LIGAMENT TO ID',
                            '${ligamentToIdMm.toStringAsFixed(2)} mm',
                            ligamentToIdMm < 1.0 ? 'Root Penetration' : 'Sub-surface Embedded',
                            ligamentToIdMm < 1.0 ? AppTheme.error : AppTheme.tertiary,
                          ),
                        ],
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

  Widget _buildTofdStatBox(String title, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 8.5, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTofdCursorControls() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cursor A (Upper Tip Peak):',
                        style: TextStyle(fontSize: 11, color: AppTheme.tertiary, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${_tofdCursorUpperMm.toStringAsFixed(2)} mm',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _tofdCursorUpperMm,
                    min: 0.0,
                    max: 18.2,
                    activeColor: AppTheme.tertiary,
                    inactiveColor: AppTheme.border,
                    onChanged: (val) {
                      setState(() {
                        _tofdCursorUpperMm = math.min(val, _tofdCursorLowerMm - 0.3);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cursor B (Lower Tip Peak):',
                        style: TextStyle(fontSize: 11, color: AppTheme.secondary, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${_tofdCursorLowerMm.toStringAsFixed(2)} mm',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _tofdCursorLowerMm,
                    min: 0.0,
                    max: 18.2,
                    activeColor: AppTheme.secondary,
                    inactiveColor: AppTheme.border,
                    onChanged: (val) {
                      setState(() {
                        _tofdCursorLowerMm = math.max(val, _tofdCursorUpperMm + 0.3);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLigamentCell(String label, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8.5, color: AppTheme.textMuted)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 4: API 1104 ANNEX A ECA EVALUATION
  // ==========================================================================

  Widget _buildEcaEvaluationTab() {
    final filteredFlaws = _selectedJoint.indications.where((f) {
      if (_flawFilterClass != null && f.defectClass != _flawFilterClass) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ECA Curve Card (fl_chart)
          _buildCard(
            title: 'API 1104 ANNEX A ECA ACCEPTANCE ENVELOPE',
            subtitle:
                'Allowable Flaw Height (h) vs Flaw Length (L) Curve based on CTOD (0.18mm) & 72% SMYS stress',
            icon: Icons.show_chart_rounded,
            child: Column(
              children: [
                _buildEcaCurveChart(),
                const SizedBox(height: 12),
                _buildEcaChartLegend(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Planar vs Non-Planar Classifier & Flaw List
          _buildCard(
            title: 'DETECTED FLAW DISPOSITION DOSSIER',
            subtitle:
                'Automated classification of Planar (LOSW, IP, Cracks) vs Non-Planar (Slag, Porosity)',
            icon: Icons.list_alt_rounded,
            child: Column(
              children: [
                _buildDefectClassifierFilter(),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredFlaws.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final flaw = filteredFlaws[index];
                    return _buildFlawIndicationCard(flaw);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEcaCurveChart() {
    // Generate Allowable Planar Curve: h vs L
    final planarLineSpots = <FlSpot>[
      const FlSpot(0, 3.20),
      const FlSpot(10, 3.10),
      const FlSpot(20, 2.65),
      const FlSpot(25, 2.45),
      const FlSpot(30, 2.15),
      const FlSpot(40, 1.85),
      const FlSpot(50, 1.50),
      const FlSpot(60, 1.35),
      const FlSpot(70, 1.25),
      const FlSpot(80, 1.20),
    ];

    // Generate Allowable Non-Planar Curve: h vs L
    final nonPlanarLineSpots = <FlSpot>[
      const FlSpot(0, 4.80),
      const FlSpot(10, 4.60),
      const FlSpot(20, 4.15),
      const FlSpot(30, 3.75),
      const FlSpot(40, 3.30),
      const FlSpot(50, 2.90),
      const FlSpot(60, 2.60),
      const FlSpot(70, 2.35),
      const FlSpot(80, 2.20),
    ];

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 80,
          minY: 0,
          maxY: 5.5,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
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
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text(
                'Flaw Length L (mm)',
                style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 20,
                getTitlesWidget: (val, meta) => Text(
                  '${val.toInt()}mm',
                  style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text(
                'Flaw Height h (mm)',
                style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1.0,
                getTitlesWidget: (val, meta) => Text(
                  val.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppTheme.border),
          ),
          lineBarsData: [
            // Planar Acceptance Boundary (Red line)
            LineChartBarData(
              spots: planarLineSpots,
              isCurved: true,
              color: AppTheme.error,
              barWidth: 2.2,
              dotData: const FlDotData(show: false),
            ),
            // Non-Planar Acceptance Boundary (Amber line)
            LineChartBarData(
              spots: nonPlanarLineSpots,
              isCurved: true,
              color: AppTheme.secondary,
              barWidth: 2.0,
              dotData: const FlDotData(show: false),
            ),
            // Actual Detected Flaws plotted as points
            LineChartBarData(
              spots: _selectedJoint.indications.map((f) {
                return FlSpot(f.lengthMm, f.tofdHeightMm);
              }).toList(),
              isCurved: false,
              color: Colors.transparent,
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final flaw = _selectedJoint.indications[index];
                  final isPass = flaw.disposition == EcaDisposition.acceptable;
                  return FlDotCirclePainter(
                    radius: 5,
                    color: isPass ? AppTheme.tertiary : AppTheme.error,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEcaChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Planar ECA Boundary', AppTheme.error),
        _buildLegendItem('Non-Planar ECA Boundary', AppTheme.secondary),
        _buildLegendItem('Flaw (Accept)', AppTheme.tertiary),
        _buildLegendItem('Flaw (Reject)', AppTheme.error),
      ],
    );
  }

  Widget _buildDefectClassifierFilter() {
    return Row(
      children: [
        FilterChip(
          label: const Text('All Indications'),
          selected: _flawFilterClass == null,
          onSelected: (val) {
            setState(() {
              _flawFilterClass = null;
            });
          },
          selectedColor: AppTheme.primary,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            fontSize: 11,
            color: _flawFilterClass == null ? Colors.white : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('Planar Defects'),
          selected: _flawFilterClass == DefectClass.planar,
          onSelected: (val) {
            setState(() {
              _flawFilterClass = DefectClass.planar;
            });
          },
          selectedColor: AppTheme.error.withValues(alpha: 0.3),
          checkmarkColor: AppTheme.error,
          labelStyle: TextStyle(
            fontSize: 11,
            color: _flawFilterClass == DefectClass.planar ? AppTheme.error : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('Non-Planar Defects'),
          selected: _flawFilterClass == DefectClass.nonPlanar,
          onSelected: (val) {
            setState(() {
              _flawFilterClass = DefectClass.nonPlanar;
            });
          },
          selectedColor: AppTheme.secondary.withValues(alpha: 0.3),
          checkmarkColor: AppTheme.secondary,
          labelStyle: TextStyle(
            fontSize: 11,
            color: _flawFilterClass == DefectClass.nonPlanar ? AppTheme.secondary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFlawIndicationCard(AutFlawIndication flaw) {
    final isPass = flaw.disposition == EcaDisposition.acceptable;
    final statusColor = flaw.disposition.color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPass ? AppTheme.border : AppTheme.error.withValues(alpha: 0.8),
          width: isPass ? 1.0 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor, width: 0.8),
                ),
                child: Text(
                  flaw.indicationId,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  flaw.defectType.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  flaw.disposition.label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Target Zone: ${flaw.zone.displayName} • Clock: ${flaw.clockPosition}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFlawStatCell('LENGTH (L)', '${flaw.lengthMm.toStringAsFixed(1)} mm'),
              _buildFlawStatCell('MEASURED HEIGHT (h)', '${flaw.tofdHeightMm.toStringAsFixed(2)} mm'),
              _buildFlawStatCell('ALLOWABLE (h_max)', '${flaw.allowableHeightMm.toStringAsFixed(2)} mm'),
              _buildFlawStatCell('PEAK FSH', '${flaw.peakAmplitudeFsh.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isPass ? Icons.verified_user_rounded : Icons.handyman_rounded,
                      size: 14,
                      color: isPass ? AppTheme.tertiary : AppTheme.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPass ? 'ECA FIT-FOR-PURPOSE DISPOSITION' : 'ENGINEERING REPAIR CUT-SHEET',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isPass ? AppTheme.tertiary : AppTheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  flaw.repairExcavationInstruction,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                if (!isPass) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Approved Repair Procedure: ${flaw.repairWps}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlawStatCell(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8, color: AppTheme.textMuted)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 5: ASTM E1961 CALIBRATION BLOCK & VERIFICATION
  // ==========================================================================

  Widget _buildCalibrationBlockTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: 'ASTM E1961 REFERENCE CALIBRATION BLOCK',
            subtitle:
                'Pipe curvature matching 24" OD x 18.2mm WT API 5L X70 with calibrated EDM notches & FBHs',
            icon: Icons.verified_user_rounded,
            child: Column(
              children: [
                _buildCalibrationDetailsList(),
                const SizedBox(height: 16),
                _buildCalibrationChecklist(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'DIGITAL CALIBRATION STAMP & CRYPTOGRAPHIC HASH',
            subtitle:
                'Tamper-proof audit integrity per OISD-141 / ISO 13588 QA regulations',
            icon: Icons.security_rounded,
            child: _buildDigitalStampCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationDetailsList() {
    return Column(
      children: [
        Row(
          children: [
            _buildCalibParam(
              'CAL BLOCK SERIAL',
              _selectedJoint.calibrationBlockSerial,
              'Matching Heat No. 82194',
            ),
            const SizedBox(width: 8),
            _buildCalibParam(
              'TEMPERATURE COMPENSATION',
              '28.4°C (ΔT = 0.6°C)',
              'Limit: ΔT ≤ 3.0°C (PASS)',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildCalibParam(
              'WEDGE DELAY CALIBRATION',
              '4.18 μs Rexolite Wedge',
              'Zero-offset synchronized',
            ),
            const SizedBox(width: 8),
            _buildCalibParam(
              'PRIMARY REFERENCE SENSITIVITY',
              '80% Full Screen Height (FSH)',
              'TCG Curve active (±1.5dB)',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalibParam(String title, String val, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 8.5, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryLight)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationChecklist() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MANDATORY PRE-SCAN CALIBRATION VERIFICATION (ASTM E1961 §8)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          _buildChecklistItem('Acoustic velocity verification: Longitudinal 5,920 m/s, Shear 3,240 m/s', true),
          _buildChecklistItem('14-channel gate positioning centered over bevel targets (FBH & notches)', true),
          _buildChecklistItem('Primary reference sensitivity set to 80% FSH ± 5% for all examination zones', true),
          _buildChecklistItem('Coupling monitor threshold verified: loss > 6dB triggers auto-stop warning', true),
          _buildChecklistItem('TOFD lateral wave and backwall echo linearized within ±0.15mm depth error', true),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: checked ? AppTheme.tertiary : AppTheme.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalStampCard() {
    // Generate simulated SHA-256 hash
    final bytes = utf8.encode(
        '${_selectedJoint.jointNo}:${_selectedJoint.scanTimestamp}:${_selectedJoint.calibrationBlockSerial}');
    final digest = sha256.convert(bytes);
    final hashStr = digest.toString().toUpperCase();

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
              const Icon(Icons.fingerprint_rounded, color: AppTheme.tertiary, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DIGITALLY CERTIFIED BY ASNT / PCN LEVEL III',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _selectedJoint.operatorLevel3,
                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                    ),
                    Text(
                      'TPIA Witness: ${_selectedJoint.tpiaWitness}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SHA-256 INTEGRITY DIGEST:',
                    style: TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                SelectableText(
                  hashStr,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SHARED CARDS & MODALS
  // ==========================================================================

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryLight, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  void _showJointSelectDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Girth Weld Joint Dossier',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ..._joints.map((joint) {
                final isSelected = joint.jointNo == _selectedJoint.jointNo;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    joint.overallPass ? Icons.check_circle_rounded : Icons.error_rounded,
                    color: joint.overallPass ? AppTheme.tertiary : AppTheme.error,
                  ),
                  title: Text(
                    joint.jointNo,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppTheme.primaryLight : AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${joint.chainage} • ${joint.indications.length} Flaws',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: AppTheme.primaryLight)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedJoint = joint;
                      _selectedFlaw = joint.indications.isNotEmpty ? joint.indications.first : null;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showCalibrationModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppTheme.secondary),
              SizedBox(width: 8),
              Text('AUT Calibration Check', style: TextStyle(fontSize: 15)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calibration Block: ${_selectedJoint.calibrationBlockSerial}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'ASTM E1961 Section 8 requires recalibration every 4 hours or after every 25 welds, '
                'whichever comes first, and upon any temperature variation > 3°C.',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Calibration Validated for 4.0 Hours',
                      style: TextStyle(fontSize: 11, color: AppTheme.tertiary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showExportDossierModal() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceCard,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'AUT Inspection Dossier for ${_selectedJoint.jointNo} exported with SHA-256 stamp.',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS: PHASED ARRAY S-SCAN, TOFD B-SCAN, A-SCAN
// ============================================================================

class PhasedArraySScanPainter extends CustomPainter {
  final double selectedAngleDeg;
  final ScanDisplayMode displayMode;
  final double wallThicknessMm;
  final AutFlawIndication? flaw;

  PhasedArraySScanPainter({
    required this.selectedAngleDeg,
    required this.displayMode,
    required this.wallThicknessMm,
    required this.flaw,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2.0;
    const odY = 40.0;
    const scaleY = 10.0; // 10 pixels per mm
    final idY = odY + wallThicknessMm * scaleY; // ~222.0

    // Background Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2E5C).withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    for (double y = odY; y <= idY; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x <= size.width; x += 30) {
      canvas.drawLine(Offset(x, odY), Offset(x, idY), gridPaint);
    }

    // Pipe Outer and Inner Boundaries
    final pipeBorderPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.8;

    canvas.drawLine(Offset(0, odY), Offset(size.width, odY), pipeBorderPaint);
    canvas.drawLine(Offset(0, idY), Offset(size.width, idY), pipeBorderPaint);

    // CRC-Evans Compound J-Bevel Geometry
    final bevelPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final bevelFillPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Weld Centerline
    final centerLinePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(centerX, odY - 15), Offset(centerX, idY + 15), centerLinePaint);

    // Narrow Gap Bevel Boundaries (Included angle 5 deg, Root face 1.5mm, Land 1.0mm)
    final bevelPath = Path();
    bevelPath.moveTo(centerX - 10, odY - 8); // Weld crown cap left
    bevelPath.lineTo(centerX - 6, odY); // Bevel top left
    bevelPath.lineTo(centerX - 2.5, idY - 25); // Lower bevel J-radius
    bevelPath.lineTo(centerX - 1.5, idY); // Root land left
    bevelPath.lineTo(centerX + 1.5, idY); // Root land right
    bevelPath.lineTo(centerX + 2.5, idY - 25); // Lower bevel J-radius right
    bevelPath.lineTo(centerX + 6, odY); // Bevel top right
    bevelPath.lineTo(centerX + 10, odY - 8); // Weld crown cap right
    bevelPath.close();

    canvas.drawPath(bevelPath, bevelFillPaint);
    canvas.drawPath(bevelPath, bevelPaint);

    // Ultrasonic Sectorial Beam Fan (S-Scan: 40 deg to 72 deg)
    final probeEntryX = centerX - 120.0;
    final probeEntryY = odY;

    // Draw Array Wedge
    final wedgePaint = Paint()
      ..color = const Color(0xFFFFB95F).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final wedgeBorder = Paint()
      ..color = const Color(0xFFFFB95F)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final wedgePath = Path()
      ..moveTo(probeEntryX - 35, odY - 25)
      ..lineTo(probeEntryX + 15, odY - 25)
      ..lineTo(probeEntryX + 25, odY)
      ..lineTo(probeEntryX - 45, odY)
      ..close();
    canvas.drawPath(wedgePath, wedgePaint);
    canvas.drawPath(wedgePath, wedgeBorder);

    // Fan of Acoustic Rays
    final rayPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.25)
      ..strokeWidth = 0.8;

    for (double angle = 40; angle <= 72; angle += 4) {
      final rad = angle * math.pi / 180.0;
      final targetDepth = wallThicknessMm * scaleY;
      final rayLength = targetDepth / math.cos(rad);
      final endX = probeEntryX + rayLength * math.sin(rad);
      final endY = odY + targetDepth;
      canvas.drawLine(Offset(probeEntryX, probeEntryY), Offset(endX, endY), rayPaint);
    }

    // Active Selected Angle Ray (Highlighted)
    final activeRad = selectedAngleDeg * math.pi / 180.0;
    final activeDepth = wallThicknessMm * scaleY;
    final activeLength = activeDepth / math.cos(activeRad);
    final activeEndX = probeEntryX + activeLength * math.sin(activeRad);
    final activeEndY = odY + activeDepth;

    final activeRayPaint = Paint()
      ..color = const Color(0xFFFFB95F)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(probeEntryX, probeEntryY),
      Offset(activeEndX, activeEndY),
      activeRayPaint,
    );

    // Draw Acoustic Echo Clutter / Heatmap in Bevel
    final heatmapCenter = Offset(centerX + 3.0, odY + 95.0); // Fill 2 region
    final heatmapGradient = RadialGradient(
      colors: [
        const Color(0xFFFF0055), // Saturated Core
        const Color(0xFFFF5252), // High Reflection (Red)
        const Color(0xFFFFB95F).withValues(alpha: 0.8), // Amber
        const Color(0xFF4EDEA3).withValues(alpha: 0.5), // Green
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.65, 0.85, 1.0],
    );

    final heatmapPaint = Paint()
      ..shader = heatmapGradient.createShader(
        Rect.fromCircle(center: heatmapCenter, radius: 24.0),
      );
    canvas.drawCircle(heatmapCenter, 24.0, heatmapPaint);

    // Flaw Indication Marker Box (Fill 2 LOSW)
    final flawRect = Rect.fromCenter(
      center: heatmapCenter,
      width: 14.0,
      height: 22.0,
    );
    final flawBoxPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(flawRect, flawBoxPaint);

    // Flaw Label Text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'IND-01: LOSW (Fill 2)',
        style: TextStyle(
          color: Color(0xFFFF5252),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          backgroundColor: Color(0xFF0B1326),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(heatmapCenter.dx + 12, heatmapCenter.dy - 10));

    // Depth Ruler Axis on right
    final rulerPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(size.width - 24, odY), Offset(size.width - 24, idY), rulerPaint);

    for (double d = 0; d <= wallThicknessMm; d += 4) {
      final y = odY + d * scaleY;
      canvas.drawLine(Offset(size.width - 28, y), Offset(size.width - 24, y), rulerPaint);

      final label = TextPainter(
        text: TextSpan(
          text: '${d.toInt()}',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(size.width - 20, y - 4));
    }
  }

  @override
  bool shouldRepaint(covariant PhasedArraySScanPainter oldDelegate) {
    return oldDelegate.selectedAngleDeg != selectedAngleDeg ||
        oldDelegate.displayMode != displayMode ||
        oldDelegate.flaw != flaw;
  }
}

class AScanOscilloscopePainter extends CustomPainter {
  final double angleDeg;
  final double peakFsh;
  final double thresholdFsh;

  AScanOscilloscopePainter({
    required this.angleDeg,
    required this.peakFsh,
    required this.thresholdFsh,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF050914);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Oscilloscope Grid Lines (10% vertical increments, 10 horizontal divisions)
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2E5C).withValues(alpha: 0.5)
      ..strokeWidth = 0.6;

    for (int i = 0; i <= 10; i++) {
      final y = size.height * (i / 10.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 0; i <= 10; i++) {
      final x = size.width * (i / 10.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // 80% FSH Threshold Line (Dashed Amber/Red)
    final thresholdY = size.height * (1.0 - thresholdFsh / 120.0);
    final threshPaint = Paint()
      ..color = const Color(0xFFFFB95F)
      ..strokeWidth = 1.2;

    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, thresholdY), Offset(x + 4, thresholdY), threshPaint);
    }

    // Gate A Visualizer Bar (Cyan/Green Bar at threshold)
    final gateStartX = size.width * 0.42;
    final gateWidth = size.width * 0.22;
    final gatePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(gateStartX, thresholdY),
      Offset(gateStartX + gateWidth, thresholdY),
      gatePaint,
    );
    canvas.drawLine(
      Offset(gateStartX, thresholdY - 4),
      Offset(gateStartX, thresholdY + 4),
      gatePaint,
    );
    canvas.drawLine(
      Offset(gateStartX + gateWidth, thresholdY - 4),
      Offset(gateStartX + gateWidth, thresholdY + 4),
      gatePaint,
    );

    // RF Rectified Ultrasonic Signal Trace (Luminescent Cyan)
    final tracePath = Path();
    tracePath.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 1.5) {
      double normX = x / size.width;
      double amp = 0.04; // Noise floor

      // Initial wedge entry echo around x=0.1
      if (normX >= 0.08 && normX <= 0.14) {
        amp += 0.28 * math.sin((normX - 0.08) / 0.06 * math.pi);
      }

      // Flaw Echo Peak inside Gate A around x=0.52
      final flawPeakFactor = peakFsh / 120.0;
      if (normX >= 0.46 && normX <= 0.58) {
        amp += flawPeakFactor * math.sin((normX - 0.46) / 0.12 * math.pi);
      }

      // Backwall echo around x=0.88
      if (normX >= 0.84 && normX <= 0.94) {
        amp += 0.35 * math.sin((normX - 0.84) / 0.10 * math.pi);
      }

      final y = size.height * (1.0 - math.min(amp, 1.0));
      tracePath.lineTo(x, y);
    }

    final tracePaint = Paint()
      ..color = const Color(0xFF4EDEA3)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final fillTracePaint = Paint()
      ..color = const Color(0xFF4EDEA3).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final closedPath = Path.from(tracePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(closedPath, fillTracePaint);
    canvas.drawPath(tracePath, tracePaint);
  }

  @override
  bool shouldRepaint(covariant AScanOscilloscopePainter oldDelegate) {
    return oldDelegate.angleDeg != angleDeg ||
        oldDelegate.peakFsh != peakFsh ||
        oldDelegate.thresholdFsh != thresholdFsh;
  }
}

class TofdGreyscalePainter extends CustomPainter {
  final double cursorUpperMm;
  final double cursorLowerMm;
  final double wallThicknessMm;

  TofdGreyscalePainter({
    required this.cursorUpperMm,
    required this.cursorLowerMm,
    required this.wallThicknessMm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF101014);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final scaleY = size.height / wallThicknessMm;

    // TOFD Synthetic B-Scan Waterfall Greyscale Pattern
    final rand = math.Random(42);
    for (double y = 0; y < size.height; y += 3) {
      final depthMm = y / scaleY;

      // Base background speckle
      double baseBrightness = 0.25 + rand.nextDouble() * 0.1;

      // 1. Lateral Wave (Near OD surface, depth 0 to 2.5 mm)
      if (depthMm <= 2.8) {
        final phase = math.sin(depthMm / 2.8 * math.pi * 3);
        baseBrightness = 0.5 + phase * 0.45;
      }

      // 2. Backwall Echo (Near ID surface, depth 16.5 to 18.2 mm)
      if (depthMm >= 16.2) {
        final phase = math.sin((depthMm - 16.2) / 2.0 * math.pi * 3);
        baseBrightness = 0.5 - phase * 0.45; // Inverted phase from LW
      }

      // 3. Flaw Diffracted Waves (Hyperbolic Fringe Arc between 8mm and 11mm)
      if (depthMm >= 7.8 && depthMm <= 10.8) {
        final phase = math.sin((depthMm - 7.8) / 3.0 * math.pi * 4);
        baseBrightness = 0.5 + phase * 0.4;
      }

      baseBrightness = baseBrightness.clamp(0.0, 1.0);
      final greyVal = (baseBrightness * 255).toInt();
      final linePaint = Paint()
        ..color = Color.fromARGB(255, greyVal, greyVal, greyVal)
        ..strokeWidth = 3.0;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Annotations for Lateral Wave and Backwall Echo
    _drawLabel(canvas, 'LATERAL WAVE (LW)', Offset(10, 12), const Color(0xFF4EDEA3));
    _drawLabel(canvas, 'BACKWALL ECHO (BW)', Offset(10, size.height - 22), const Color(0xFF38BDF8));

    // Interactive Cursor A: Upper Tip (Green Line)
    final cursorUpperY = cursorUpperMm * scaleY;
    final cursorAPaint = Paint()
      ..color = const Color(0xFF4EDEA3)
      ..strokeWidth = 1.4;

    canvas.drawLine(Offset(0, cursorUpperY), Offset(size.width, cursorUpperY), cursorAPaint);
    _drawLabel(
      canvas,
      'CURSOR A (TOP TIP): ${cursorUpperMm.toStringAsFixed(2)} mm',
      Offset(size.width - 200, cursorUpperY - 14),
      const Color(0xFF4EDEA3),
    );

    // Interactive Cursor B: Lower Tip (Amber Line)
    final cursorLowerY = cursorLowerMm * scaleY;
    final cursorBPaint = Paint()
      ..color = const Color(0xFFFFB95F)
      ..strokeWidth = 1.4;

    canvas.drawLine(Offset(0, cursorLowerY), Offset(size.width, cursorLowerY), cursorBPaint);
    _drawLabel(
      canvas,
      'CURSOR B (BOTTOM TIP): ${cursorLowerMm.toStringAsFixed(2)} mm',
      Offset(size.width - 215, cursorLowerY + 4),
      const Color(0xFFFFB95F),
    );

    // Vertical Sizing Bracket
    final bracketX = size.width - 25;
    final bracketPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(bracketX, cursorUpperY), Offset(bracketX, cursorLowerY), bracketPaint);
    canvas.drawLine(Offset(bracketX - 6, cursorUpperY), Offset(bracketX, cursorUpperY), bracketPaint);
    canvas.drawLine(Offset(bracketX - 6, cursorLowerY), Offset(bracketX, cursorLowerY), bracketPaint);

    final heightMm = (cursorLowerMm - cursorUpperMm).abs();
    _drawLabel(
      canvas,
      'Δh = ${heightMm.toStringAsFixed(2)}mm',
      Offset(bracketX - 75, (cursorUpperY + cursorLowerY) / 2 - 6),
      const Color(0xFFFF5252),
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          backgroundColor: Colors.black.withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant TofdGreyscalePainter oldDelegate) {
    return oldDelegate.cursorUpperMm != cursorUpperMm ||
        oldDelegate.cursorLowerMm != cursorLowerMm ||
        oldDelegate.wallThicknessMm != wallThicknessMm;
  }
}
