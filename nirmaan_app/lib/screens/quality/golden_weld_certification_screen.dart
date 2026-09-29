import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS
// ============================================================================

enum NdtExamStatus {
  passed,
  underReview,
  pending,
  rejected,
}

extension NdtExamStatusExt on NdtExamStatus {
  String get label {
    switch (this) {
      case NdtExamStatus.passed:
        return 'PASSED (100%)';
      case NdtExamStatus.underReview:
        return 'UNDER TPIA REVIEW';
      case NdtExamStatus.pending:
        return 'EXAMINATION PENDING';
      case NdtExamStatus.rejected:
        return 'REJECTED / REPAIR';
    }
  }

  Color get color {
    switch (this) {
      case NdtExamStatus.passed:
        return const Color(0xFF4EDEA3);
      case NdtExamStatus.underReview:
        return const Color(0xFFFFB95F);
      case NdtExamStatus.pending:
        return const Color(0xFF94A3B8);
      case NdtExamStatus.rejected:
        return const Color(0xFFFF5252);
    }
  }

  IconData get icon {
    switch (this) {
      case NdtExamStatus.passed:
        return Icons.check_circle_rounded;
      case NdtExamStatus.underReview:
        return Icons.hourglass_top_rounded;
      case NdtExamStatus.pending:
        return Icons.pending_actions_rounded;
      case NdtExamStatus.rejected:
        return Icons.cancel_rounded;
    }
  }
}

enum TripartiteRole {
  contractorWelder,
  eilTpia,
  oilResidentEng,
}

extension TripartiteRoleExt on TripartiteRole {
  String get title {
    switch (this) {
      case TripartiteRole.contractorWelder:
        return 'Contractor Lead Welder / QA-QC';
      case TripartiteRole.eilTpia:
        return 'EIL TPIA Level III Inspector';
      case TripartiteRole.oilResidentEng:
        return 'Oil India Resident Engineer';
    }
  }

  String get organization {
    switch (this) {
      case TripartiteRole.contractorWelder:
        return 'Kalpataru Projects Ltd / L&T Cons.';
      case TripartiteRole.eilTpia:
        return 'Engineers India Limited (TPIA)';
      case TripartiteRole.oilResidentEng:
        return 'Oil India Limited (Pipeline HQ)';
    }
  }

  IconData get icon {
    switch (this) {
      case TripartiteRole.contractorWelder:
        return Icons.engineering_rounded;
      case TripartiteRole.eilTpia:
        return Icons.verified_user_rounded;
      case TripartiteRole.oilResidentEng:
        return Icons.military_tech_rounded;
    }
  }
}

class HydrotestSectionSummary {
  final String sectionId;
  final String chainageRange;
  final double lengthKm;
  final double testPressureBar;
  final double designPressureBar;
  final String testDate;
  final int holdDurationHours;
  final String testMedium;
  final String recorderChartNo;
  final String witnessOrg;
  final bool isPretestedAndAccepted;

  const HydrotestSectionSummary({
    required this.sectionId,
    required this.chainageRange,
    required this.lengthKm,
    required this.testPressureBar,
    required this.designPressureBar,
    required this.testDate,
    required this.holdDurationHours,
    required this.testMedium,
    required this.recorderChartNo,
    required this.witnessOrg,
    required this.isPretestedAndAccepted,
  });
}

class RadiographicTestingDossier {
  final NdtExamStatus status;
  final String technique;
  final String radiationSource;
  final double sourceStrengthCi;
  final String filmType;
  final double filmDensityHnd;
  final String sensitivityWire;
  final double geometricUnsharpnessMm;
  final double weldCircumferenceExaminedMm;
  final double coveragePercent;
  final String defectsIdentified;
  final String reportNo;
  final String filmReaderName;
  final String certificationLevel;
  final String inspectionDate;

  const RadiographicTestingDossier({
    required this.status,
    required this.technique,
    required this.radiationSource,
    required this.sourceStrengthCi,
    required this.filmType,
    required this.filmDensityHnd,
    required this.sensitivityWire,
    required this.geometricUnsharpnessMm,
    required this.weldCircumferenceExaminedMm,
    required this.coveragePercent,
    required this.defectsIdentified,
    required this.reportNo,
    required this.filmReaderName,
    required this.certificationLevel,
    required this.inspectionDate,
  });
}

class PautTestingDossier {
  final NdtExamStatus status;
  final String instrument;
  final String probeSpec;
  final String wedgeSpec;
  final String sectorialAngleRange;
  final bool tofdPairUsed;
  final String calibrationBlockRef;
  final double encoderResolutionMm;
  final double volumeCoveragePercent;
  final String flawEvaluation;
  final double maxAmplitudeDacPercent;
  final String reportNo;
  final String inspectorName;
  final String certificationLevel;
  final String inspectionDate;

  const PautTestingDossier({
    required this.status,
    required this.instrument,
    required this.probeSpec,
    required this.wedgeSpec,
    required this.sectorialAngleRange,
    required this.tofdPairUsed,
    required this.calibrationBlockRef,
    required this.encoderResolutionMm,
    required this.volumeCoveragePercent,
    required this.flawEvaluation,
    required this.maxAmplitudeDacPercent,
    required this.reportNo,
    required this.inspectorName,
    required this.certificationLevel,
    required this.inspectionDate,
  });
}

class MptTestingDossier {
  final NdtExamStatus status;
  final String yokeType;
  final double liftCapacityKg;
  final String mediumType;
  final String rootPassResult;
  final String hotPassResult;
  final String cappingPassResult;
  final String reportNo;
  final String inspectorName;
  final String certificationLevel;
  final String inspectionDate;

  const MptTestingDossier({
    required this.status,
    required this.yokeType,
    required this.liftCapacityKg,
    required this.mediumType,
    required this.rootPassResult,
    required this.hotPassResult,
    required this.cappingPassResult,
    required this.reportNo,
    required this.inspectorName,
    required this.certificationLevel,
    required this.inspectionDate,
  });
}

class HardnessTestingDossier {
  final NdtExamStatus status;
  final String method;
  final int averageHv10;
  final int maxRecordedHv10;
  final int limitHv10;
  final bool isNaceMr0175Compliant;
  final String reportNo;

  const HardnessTestingDossier({
    required this.status,
    required this.method,
    required this.averageHv10,
    required this.maxRecordedHv10,
    required this.limitHv10,
    required this.isNaceMr0175Compliant,
    required this.reportNo,
  });
}

class PartySignature {
  final TripartiteRole role;
  final String roleTitle;
  final String name;
  final String organization;
  final String licenseId;
  final bool isSigned;
  final String? signedAt;
  final String? signatureHash;
  final List<Offset>? signatureStrokePoints;

  const PartySignature({
    required this.role,
    required this.roleTitle,
    required this.name,
    required this.organization,
    required this.licenseId,
    required this.isSigned,
    this.signedAt,
    this.signatureHash,
    this.signatureStrokePoints,
  });

  PartySignature copyWith({
    bool? isSigned,
    String? signedAt,
    String? signatureHash,
    List<Offset>? signatureStrokePoints,
  }) {
    return PartySignature(
      role: role,
      roleTitle: roleTitle,
      name: name,
      organization: organization,
      licenseId: licenseId,
      isSigned: isSigned ?? this.isSigned,
      signedAt: signedAt ?? this.signedAt,
      signatureHash: signatureHash ?? this.signatureHash,
      signatureStrokePoints:
          signatureStrokePoints ?? this.signatureStrokePoints,
    );
  }
}

class HydrostaticExemptionCertificate {
  final String certificateNo;
  final String governingStandard;
  final String oisdClauseRef;
  final String asmeClauseRef;
  final String issueDate;
  final bool isApproved;
  final String pretestSectionAId;
  final String pretestSectionBId;
  final String tieInWpsNo;
  final double operatingSafetyFactor;
  final bool nitrogenPurgingCleared;
  final int checklistCompletedCount;
  final int checklistTotalCount;

  const HydrostaticExemptionCertificate({
    required this.certificateNo,
    required this.governingStandard,
    required this.oisdClauseRef,
    required this.asmeClauseRef,
    required this.issueDate,
    required this.isApproved,
    required this.pretestSectionAId,
    required this.pretestSectionBId,
    required this.tieInWpsNo,
    required this.operatingSafetyFactor,
    required this.nitrogenPurgingCleared,
    required this.checklistCompletedCount,
    required this.checklistTotalCount,
  });

  HydrostaticExemptionCertificate copyWith({
    bool? isApproved,
    int? checklistCompletedCount,
    bool? nitrogenPurgingCleared,
    String? issueDate,
  }) {
    return HydrostaticExemptionCertificate(
      certificateNo: certificateNo,
      governingStandard: governingStandard,
      oisdClauseRef: oisdClauseRef,
      asmeClauseRef: asmeClauseRef,
      issueDate: issueDate ?? this.issueDate,
      isApproved: isApproved ?? this.isApproved,
      pretestSectionAId: pretestSectionAId,
      pretestSectionBId: pretestSectionBId,
      tieInWpsNo: tieInWpsNo,
      operatingSafetyFactor: operatingSafetyFactor,
      nitrogenPurgingCleared:
          nitrogenPurgingCleared ?? this.nitrogenPurgingCleared,
      checklistCompletedCount:
          checklistCompletedCount ?? this.checklistCompletedCount,
      checklistTotalCount: checklistTotalCount,
    );
  }
}

class GoldenWeldRecord {
  final String id;
  final String jointNumber;
  final double chainageKm;
  final String chainageDisplay;
  final String locationName;
  final String gpsCoords;
  final double pipeSizeInches;
  final double pipeOdMm;
  final double wallThicknessMm;
  final double? connectingWallThicknessMm;
  final String pipeGrade;
  final String wpsNumber;
  final String welderIds;
  final String welderNames;
  final String weldProcess;
  final double preheatCelsius;
  final double interpassCelsius;
  final String ambientCondition;
  final HydrotestSectionSummary sectionA;
  final HydrotestSectionSummary sectionB;
  final RadiographicTestingDossier rtDossier;
  final PautTestingDossier pautDossier;
  final MptTestingDossier mptDossier;
  final HardnessTestingDossier hardnessDossier;
  final PartySignature contractorSign;
  final PartySignature eilTpiaSign;
  final PartySignature oilResidentSign;
  final HydrostaticExemptionCertificate exemptionCert;
  final String tamperProofSha256;

  const GoldenWeldRecord({
    required this.id,
    required this.jointNumber,
    required this.chainageKm,
    required this.chainageDisplay,
    required this.locationName,
    required this.gpsCoords,
    required this.pipeSizeInches,
    required this.pipeOdMm,
    required this.wallThicknessMm,
    this.connectingWallThicknessMm,
    required this.pipeGrade,
    required this.wpsNumber,
    required this.welderIds,
    required this.welderNames,
    required this.weldProcess,
    required this.preheatCelsius,
    required this.interpassCelsius,
    required this.ambientCondition,
    required this.sectionA,
    required this.sectionB,
    required this.rtDossier,
    required this.pautDossier,
    required this.mptDossier,
    required this.hardnessDossier,
    required this.contractorSign,
    required this.eilTpiaSign,
    required this.oilResidentSign,
    required this.exemptionCert,
    required this.tamperProofSha256,
  });

  bool get isFullyCertified =>
      contractorSign.isSigned &&
      eilTpiaSign.isSigned &&
      oilResidentSign.isSigned &&
      exemptionCert.isApproved;

  int get signatureCount {
    int c = 0;
    if (contractorSign.isSigned) c++;
    if (eilTpiaSign.isSigned) c++;
    if (oilResidentSign.isSigned) c++;
    return c;
  }

  GoldenWeldRecord copyWith({
    PartySignature? contractorSign,
    PartySignature? eilTpiaSign,
    PartySignature? oilResidentSign,
    HydrostaticExemptionCertificate? exemptionCert,
    String? tamperProofSha256,
  }) {
    return GoldenWeldRecord(
      id: id,
      jointNumber: jointNumber,
      chainageKm: chainageKm,
      chainageDisplay: chainageDisplay,
      locationName: locationName,
      gpsCoords: gpsCoords,
      pipeSizeInches: pipeSizeInches,
      pipeOdMm: pipeOdMm,
      wallThicknessMm: wallThicknessMm,
      connectingWallThicknessMm: connectingWallThicknessMm,
      pipeGrade: pipeGrade,
      wpsNumber: wpsNumber,
      welderIds: welderIds,
      welderNames: welderNames,
      weldProcess: weldProcess,
      preheatCelsius: preheatCelsius,
      interpassCelsius: interpassCelsius,
      ambientCondition: ambientCondition,
      sectionA: sectionA,
      sectionB: sectionB,
      rtDossier: rtDossier,
      pautDossier: pautDossier,
      mptDossier: mptDossier,
      hardnessDossier: hardnessDossier,
      contractorSign: contractorSign ?? this.contractorSign,
      eilTpiaSign: eilTpiaSign ?? this.eilTpiaSign,
      oilResidentSign: oilResidentSign ?? this.oilResidentSign,
      exemptionCert: exemptionCert ?? this.exemptionCert,
      tamperProofSha256: tamperProofSha256 ?? this.tamperProofSha256,
    );
  }
}

// ============================================================================
// SIGNATURE DRAWING PAINTER
// ============================================================================

class JointSignaturePainter extends CustomPainter {
  final List<Offset> points;
  final Color strokeColor;

  JointSignaturePainter({
    required this.points,
    this.strokeColor = const Color(0xFF38BDF8),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Guidelines
    final guidelinePaint = Paint()
      ..color = const Color(0xFF26396E).withAlpha(120)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final baselineY = size.height * 0.72;
    double startX = 10;
    while (startX < size.width - 10) {
      canvas.drawLine(
        Offset(startX, baselineY),
        Offset(startX + 6, baselineY),
        guidelinePaint,
      );
      startX += 10;
    }

    if (points.isEmpty) return;

    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.8;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant JointSignaturePainter oldDelegate) => true;
}

// ============================================================================
// ULTRASONIC & BEVEL CAD CUSTOM PAINTER
// ============================================================================

class WeldBevelUltrasonicPainter extends CustomPainter {
  final double probeAngleDeg;
  final double probePositionX; // 0.0 to 1.0 along pipe surface
  final bool animateSweep;
  final double sweepPhase;

  WeldBevelUltrasonicPainter({
    required this.probeAngleDeg,
    required this.probePositionX,
    this.animateSweep = true,
    this.sweepPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final backgroundPaint = Paint()..color = const Color(0xFF0F182F);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), backgroundPaint);

    // Subtle CAD Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2E5C).withAlpha(80)
      ..strokeWidth = 0.8;
    const double gridSize = 20.0;
    for (double x = 0; x < w; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Pipe Wall Cross-Section Geometry
    // Top surface at y = 45, Bottom (ID surface) at y = 145 (Thickness = 100px scaled)
    final double pipeTop = 45;
    final double pipeBottom = 145;
    final double centerX = w * 0.5;

    // Left Pipe Section (API 5L X70 Steel)
    final leftPipePath = Path()
      ..moveTo(10, pipeTop)
      ..lineTo(centerX - 18, pipeTop) // Bevel top edge
      ..lineTo(centerX - 4, pipeBottom - 8) // Root face top
      ..lineTo(centerX - 4, pipeBottom) // Root face bottom
      ..lineTo(10, pipeBottom)
      ..close();

    final steelPaint = Paint()
      ..color = const Color(0xFF1B2A4A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftPipePath, steelPaint);

    // Right Pipe Section (Connecting heavy wall / standard)
    final rightPipePath = Path()
      ..moveTo(w - 10, pipeTop)
      ..lineTo(centerX + 18, pipeTop)
      ..lineTo(centerX + 4, pipeBottom - 8)
      ..lineTo(centerX + 4, pipeBottom)
      ..lineTo(w - 10, pipeBottom)
      ..close();
    canvas.drawPath(rightPipePath, steelPaint);

    // Pipe outlines
    final pipeBorderPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(leftPipePath, pipeBorderPaint);
    canvas.drawPath(rightPipePath, pipeBorderPaint);

    // Weld Metal Layers (Simulated Golden Weld Passes)
    // 1. Root Pass (GTAW ER70S-6)
    final rootPassPath = Path()
      ..moveTo(centerX - 4, pipeBottom)
      ..quadraticBezierTo(centerX, pipeBottom + 3, centerX + 4, pipeBottom)
      ..lineTo(centerX + 5, pipeBottom - 12)
      ..quadraticBezierTo(
          centerX, pipeBottom - 15, centerX - 5, pipeBottom - 12)
      ..close();
    final rootPaint = Paint()..color = const Color(0xFFEAB308);
    canvas.drawPath(rootPassPath, rootPaint);

    // 2. Hot Pass & Filler Passes
    final fillPassPath = Path()
      ..moveTo(centerX - 5, pipeBottom - 12)
      ..lineTo(centerX + 5, pipeBottom - 12)
      ..lineTo(centerX + 14, pipeTop + 12)
      ..lineTo(centerX - 14, pipeTop + 12)
      ..close();
    final fillPaint = Paint()..color = const Color(0xFFF97316);
    canvas.drawPath(fillPassPath, fillPaint);

    // 3. Capping Pass with reinforcement crown (max 2.0 mm per API 1104)
    final capPassPath = Path()
      ..moveTo(centerX - 18, pipeTop)
      ..quadraticBezierTo(centerX, pipeTop - 8, centerX + 18, pipeTop)
      ..lineTo(centerX + 14, pipeTop + 12)
      ..lineTo(centerX - 14, pipeTop + 12)
      ..close();
    final capPaint = Paint()..color = const Color(0xFF10B981);
    canvas.drawPath(capPassPath, capPaint);

    // Heat Affected Zone (HAZ) Dashed Indicator
    final hazPaint = Paint()
      ..color = const Color(0xFFFFB95F).withAlpha(160)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(centerX - 24, pipeTop), Offset(centerX - 8, pipeBottom), hazPaint);
    canvas.drawLine(
        Offset(centerX + 24, pipeTop), Offset(centerX + 8, pipeBottom), hazPaint);

    // Phased Array Ultrasonic Testing (PAUT) Probe Simulation
    final double probeX = 30 + probePositionX * (centerX - 60);
    const double probeWidth = 36;
    const double probeHeight = 18;

    // Wedge + Transducer
    final wedgePath = Path()
      ..moveTo(probeX, pipeTop)
      ..lineTo(probeX + probeWidth, pipeTop)
      ..lineTo(probeX + probeWidth - 6, pipeTop - probeHeight)
      ..lineTo(probeX + 4, pipeTop - probeHeight)
      ..close();
    final wedgePaint = Paint()..color = const Color(0xFF0284C7);
    canvas.drawPath(wedgePath, wedgePaint);

    final wedgeBorder = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(wedgePath, wedgeBorder);

    // Sectorial Sound Beams (Phased Array Sweep from probe into pipe wall)
    final double radAngle = (probeAngleDeg * math.pi) / 180.0;
    final beamStart = Offset(probeX + probeWidth * 0.7, pipeTop);

    // Primary Central Beam
    final double beamLength = (pipeBottom - pipeTop) / math.cos(radAngle - 0.7);
    final double beamTargetX = beamStart.dx + beamLength * math.sin(radAngle);
    final double beamTargetY = pipeBottom;

    // Fan Beam (Sectorial 40° to 70°)
    for (int i = -3; i <= 3; i++) {
      final subAngle = radAngle + (i * 0.06);
      final tx = beamStart.dx + (pipeBottom - pipeTop) * math.tan(subAngle);
      final rayPaint = Paint()
        ..color = i == 0
            ? const Color(0xFF4EDEA3)
            : const Color(0xFF38BDF8).withAlpha(100 - (i.abs() * 20))
        ..strokeWidth = i == 0 ? 2.0 : 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(beamStart, Offset(tx, beamTargetY), rayPaint);

      // Bottom Skip/Reflection back upwards towards weld root/fill
      final reflectedX = tx + (pipeBottom - pipeTop) * math.tan(subAngle) * 0.7;
      final reflectPaint = Paint()
        ..color = const Color(0xFFEAB308).withAlpha(110 - (i.abs() * 20))
        ..strokeWidth = 1.0;
      canvas.drawLine(
          Offset(tx, beamTargetY), Offset(reflectedX, pipeTop + 10), reflectPaint);
    }

    // Dynamic Scanning Pulse Ring
    final pulseOffset = (sweepPhase * 60) % 60;
    final pulseCenter = Offset(
      beamStart.dx + (beamTargetX - beamStart.dx) * (pulseOffset / 60),
      beamStart.dy + (beamTargetY - beamStart.dy) * (pulseOffset / 60),
    );
    final pulsePaint = Paint()
      ..color = const Color(0xFF4EDEA3).withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(pulseCenter, 4.0 + (pulseOffset * 0.1), pulsePaint);

    // CAD Dimension Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = const TextSpan(
      text: 'WT 14.3mm',
      style: TextStyle(
          color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(14, (pipeTop + pipeBottom) * 0.5 - 6));

    textPainter.text = TextSpan(
      text: 'PAUT ${probeAngleDeg.toStringAsFixed(0)}° Shear',
      style: const TextStyle(
          color: Color(0xFF38BDF8), fontSize: 9, fontWeight: FontWeight.w700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(probeX - 4, pipeTop - 32));

    textPainter.text = const TextSpan(
      text: 'Root Face 1.6mm',
      style: TextStyle(
          color: Color(0xFFFFB95F), fontSize: 9, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX - 35, pipeBottom + 10));

    textPainter.text = const TextSpan(
      text: 'Weld Crown +1.8mm',
      style: TextStyle(
          color: Color(0xFF4EDEA3), fontSize: 9, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX - 38, pipeTop - 22));
  }

  @override
  bool shouldRepaint(covariant WeldBevelUltrasonicPainter oldDelegate) {
    return oldDelegate.probeAngleDeg != probeAngleDeg ||
        oldDelegate.probePositionX != probePositionX ||
        oldDelegate.sweepPhase != sweepPhase;
  }
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class GoldenWeldCertificationScreen extends StatefulWidget {
  const GoldenWeldCertificationScreen({super.key});

  @override
  State<GoldenWeldCertificationScreen> createState() =>
      _GoldenWeldCertificationScreenState();
}

class _GoldenWeldCertificationScreenState
    extends State<GoldenWeldCertificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _sweepAnimController;

  String _filterStatus = 'ALL'; // ALL, CERTIFIED, PENDING_SIGN, IN_PROGRESS
  String _selectedJointId = 'GW-DUL-01';

  // Interactive CAD / Ultrasonic Probe Simulation State
  double _probeAngleDeg = 55.0; // 40.0 to 70.0
  double _probePositionSlider = 0.55;

  late List<GoldenWeldRecord> _records;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _sweepAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _sweepAnimController.addListener(() {
      if (mounted) setState(() {});
    });

    _records = _initInitialRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sweepAnimController.dispose();
    super.dispose();
  }

  GoldenWeldRecord get currentRecord {
    return _records.firstWhere(
      (r) => r.id == _selectedJointId,
      orElse: () => _records.first,
    );
  }

  // --------------------------------------------------------------------------
  // INITIAL DATA (GW-DUL-01 TO GW-DUL-06)
  // --------------------------------------------------------------------------
  List<GoldenWeldRecord> _initInitialRecords() {
    return [
      // ----------------------------------------------------------------------
      // GW-DUL-01: Dihing River North Bank Crossing
      // ----------------------------------------------------------------------
      GoldenWeldRecord(
        id: 'GW-DUL-01',
        jointNumber: 'GW-01',
        chainageKm: 14.320,
        chainageDisplay: 'KP 14+320',
        locationName: 'Dihing River North Bank HDD Tie-In',
        gpsCoords: '27.3184° N, 95.3219° E',
        pipeSizeInches: 24.0,
        pipeOdMm: 610.0,
        wallThicknessMm: 14.3,
        connectingWallThicknessMm: 17.5,
        pipeGrade: 'API 5L Grade X-70 PSL2 (Sour Service)',
        wpsNumber: 'WPS-OIL-GW-01 Rev.3',
        welderIds: 'W-2088 / W-1944',
        welderNames: 'Dipankar Saikia / Biren Gogoi',
        weldProcess: 'GTAW Root (ER70S-6) + SMAW Fill/Cap (E8018-G Low-H)',
        preheatCelsius: 155.0,
        interpassCelsius: 215.0,
        ambientCondition: '28°C, 64% RH, Overcast (Assam Riverine)',
        sectionA: const HydrotestSectionSummary(
          sectionId: 'HT-SEC-01',
          chainageRange: 'KP 00+000 to KP 14+320',
          lengthKm: 14.320,
          testPressureBar: 148.5,
          designPressureBar: 98.0,
          testDate: '12-May-2026',
          holdDurationHours: 24,
          testMedium: 'Inhibited Potable Water',
          recorderChartNo: 'PR-SEC01-OIL-094',
          witnessOrg: 'EIL TPIA & OIL Resident Inspection',
          isPretestedAndAccepted: true,
        ),
        sectionB: const HydrotestSectionSummary(
          sectionId: 'HT-SEC-02',
          chainageRange: 'KP 14+320 to KP 28+650 (Dihing HDD)',
          lengthKm: 14.330,
          testPressureBar: 155.0,
          designPressureBar: 98.0,
          testDate: '18-May-2026',
          holdDurationHours: 24,
          testMedium: 'Inhibited Potable Water',
          recorderChartNo: 'PR-SEC02-HDD-102',
          witnessOrg: 'EIL TPIA & OIL Resident Inspection',
          isPretestedAndAccepted: true,
        ),
        rtDossier: const RadiographicTestingDossier(
          status: NdtExamStatus.passed,
          technique: 'Double Wall Single Image (DWSI) Elliptical Exposure',
          radiationSource: 'Iridium-192 (Gamma Ray Isotope)',
          sourceStrengthCi: 44.5,
          filmType: 'Agfa Structurix D4 Class 1 High Contrast',
          filmDensityHnd: 2.85,
          sensitivityWire: 'ASTM Wire #11 (0.40mm dia) Clearly Visible',
          geometricUnsharpnessMm: 0.14,
          weldCircumferenceExaminedMm: 1916.0,
          coveragePercent: 100.0,
          defectsIdentified: 'Zero Planar Flaws, Zero Cracks (API 1104 §9.3)',
          reportNo: 'RT/OIL/DUL/GW-01/REV-1',
          filmReaderName: 'Alok Sen, NDT Specialist',
          certificationLevel: 'ASNT Level II RT / ISNT',
          inspectionDate: '24-May-2026',
        ),
        pautDossier: const PautTestingDossier(
          status: NdtExamStatus.passed,
          instrument: 'Olympus OmniScan X3 64:128PR Phased Array',
          probeSpec: '5L32-A31 (5 MHz, 32 elements, 0.6mm pitch)',
          wedgeSpec: 'SA31-N55S (55° shear wave refracting in steel)',
          sectorialAngleRange: '40° to 70° Sectorial Scan + 15MHz TOFD Pair',
          tofdPairUsed: true,
          calibrationBlockRef: 'IIW V1 + 24" X70 Curved Reference Block',
          encoderResolutionMm: 1.0,
          volumeCoveragePercent: 100.0,
          flawEvaluation:
              '0 Planar Defects, 100% Fusion at Bevel Sidewalls & Root Face',
          maxAmplitudeDacPercent: 24.5,
          reportNo: 'PAUT/OIL/DUL/GW-01/2026',
          inspectorName: 'Pranjal Baruah',
          certificationLevel: 'ASNT Level III PAUT/TOFD',
          inspectionDate: '24-May-2026',
        ),
        mptDossier: const MptTestingDossier(
          status: NdtExamStatus.passed,
          yokeType: 'Parker Contour B-300 AC Electromagnetic Yoke',
          liftCapacityKg: 5.2,
          mediumType:
              'Black Oxide Wet Fluorescent on White Contrast Paint (WCP-2)',
          rootPassResult: '100% Sound, Zero Root Star Cracks or Micro-Fissures',
          hotPassResult: '100% Cleaned, Zero Slag Traps along Groove',
          cappingPassResult: '100% Uniform, Zero Undercut > 0.4mm, Zero Toe Crack',
          reportNo: 'MPT/OIL/DUL/GW-01/C-01',
          inspectorName: 'Hemanta Dutta',
          certificationLevel: 'ISNT Level II MPT',
          inspectionDate: '24-May-2026',
        ),
        hardnessDossier: const HardnessTestingDossier(
          status: NdtExamStatus.passed,
          method: 'Vickers HV10 Portable Hardness (Equotip Bambino)',
          averageHv10: 218,
          maxRecordedHv10: 234,
          limitHv10: 248,
          isNaceMr0175Compliant: true,
          reportNo: 'HD-OIL-DUL-01-HV10',
        ),
        contractorSign: const PartySignature(
          role: TripartiteRole.contractorWelder,
          roleTitle: 'Contractor Lead Welder & QA/QC',
          name: 'Suresh Kumar Sharma',
          organization: 'Kalpataru Projects Ltd (KPL)',
          licenseId: 'KPL-QAQC-7741 / WPQR-OIL-401',
          isSigned: true,
          signedAt: '2026-05-25 16:30 IST',
          signatureHash:
              '4f8b2d1e0a9c8b7a6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c',
        ),
        eilTpiaSign: const PartySignature(
          role: TripartiteRole.eilTpia,
          roleTitle: 'EIL TPIA Level III Inspector',
          name: 'Er. Bhaskar Jyoti Goswami',
          organization: 'Engineers India Limited (TPIA)',
          licenseId: 'EIL-NDT-L3-8824 / ASNT-19842',
          isSigned: true,
          signedAt: '2026-05-26 10:15 IST',
          signatureHash:
              '8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7b',
        ),
        oilResidentSign: const PartySignature(
          role: TripartiteRole.oilResidentEng,
          roleTitle: 'Oil India Resident Engineer',
          name: 'Er. Debajit Phukan',
          organization: 'Oil India Limited (Pipeline Duliajan)',
          licenseId: 'OIL-RE-PL-4109',
          isSigned: true,
          signedAt: '2026-05-26 14:45 IST',
          signatureHash:
              '1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d',
        ),
        exemptionCert: const HydrostaticExemptionCertificate(
          certificateNo: 'HEC/OIL-DUL/2026/GW-01',
          governingStandard:
              'OISD-141 (2020) Cl. 13.4.1 & ASME B31.8 (2022) §841.3.2(d)',
          oisdClauseRef: 'OISD-141 Cl. 13.4.1 (Mandatory Golden Weld Criteria)',
          asmeClauseRef: 'ASME B31.8 Section 841.3.2(d) Tie-In Weld Clearance',
          issueDate: '26-May-2026',
          isApproved: true,
          pretestSectionAId: 'HT-SEC-01 (148.5 Bar Hold 24h)',
          pretestSectionBId: 'HT-SEC-02 (155.0 Bar Hold 24h)',
          tieInWpsNo: 'WPS-OIL-GW-01 Rev.3',
          operatingSafetyFactor: 0.72,
          nitrogenPurgingCleared: true,
          checklistCompletedCount: 7,
          checklistTotalCount: 7,
        ),
        tamperProofSha256:
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      ),

      // ----------------------------------------------------------------------
      // GW-DUL-02: Moran Bypass Intermediate Block Valve BVS-03 Tie-in
      // ----------------------------------------------------------------------
      GoldenWeldRecord(
        id: 'GW-DUL-02',
        jointNumber: 'GW-02',
        chainageKm: 38.750,
        chainageDisplay: 'KP 38+750',
        locationName: 'Moran Bypass Intermediate Block Valve BVS-03 Tie-In',
        gpsCoords: '27.1852° N, 95.0084° E',
        pipeSizeInches: 24.0,
        pipeOdMm: 610.0,
        wallThicknessMm: 14.3,
        connectingWallThicknessMm: 14.3,
        pipeGrade: 'API 5L Grade X-70 PSL2',
        wpsNumber: 'WPS-OIL-GW-02 Rev.2',
        welderIds: 'W-1822 / W-2110',
        welderNames: 'Rahul Borgohain / Manoj Kalita',
        weldProcess: 'GTAW Root (ER70S-6) + SMAW Fill/Cap (E9018-G Low-H)',
        preheatCelsius: 160.0,
        interpassCelsius: 220.0,
        ambientCondition: '30°C, 58% RH, Sunny (Tea Estate Corridor)',
        sectionA: const HydrotestSectionSummary(
          sectionId: 'HT-SEC-02',
          chainageRange: 'KP 14+320 to KP 38+750',
          lengthKm: 24.430,
          testPressureBar: 148.5,
          designPressureBar: 98.0,
          testDate: '28-May-2026',
          holdDurationHours: 24,
          testMedium: 'Inhibited Potable Water',
          recorderChartNo: 'PR-SEC02-OIL-118',
          witnessOrg: 'EIL TPIA & OIL Resident Inspection',
          isPretestedAndAccepted: true,
        ),
        sectionB: const HydrotestSectionSummary(
          sectionId: 'HT-SEC-03 (BVS-03 Manifold)',
          chainageRange: 'KP 38+750 to KP 52+110',
          lengthKm: 13.360,
          testPressureBar: 152.0,
          designPressureBar: 98.0,
          testDate: '04-Jun-2026',
          holdDurationHours: 24,
          testMedium: 'Inhibited Potable Water',
          recorderChartNo: 'PR-SEC03-BVS-124',
          witnessOrg: 'EIL TPIA & OIL Resident Inspection',
          isPretestedAndAccepted: true,
        ),
        rtDossier: const RadiographicTestingDossier(
          status: NdtExamStatus.passed,
          technique: 'Double Wall Single Image (DWSI)',
          radiationSource: 'Iridium-192',
          sourceStrengthCi: 39.0,
          filmType: 'Agfa Structurix D4 Class 1',
          filmDensityHnd: 2.78,
          sensitivityWire: 'ASTM Wire #11 (0.40mm)',
          geometricUnsharpnessMm: 0.15,
          weldCircumferenceExaminedMm: 1916.0,
          coveragePercent: 100.0,
          defectsIdentified: 'Zero Cracks, Zero Lack of Fusion (API 1104 §9)',
          reportNo: 'RT/OIL/DUL/GW-02/REV-0',
          filmReaderName: 'Alok Sen, NDT Specialist',
          certificationLevel: 'ASNT Level II RT',
          inspectionDate: '08-Jun-2026',
        ),
        pautDossier: const PautTestingDossier(
          status: NdtExamStatus.passed,
          instrument: 'Olympus OmniScan X3 64:128PR',
          probeSpec: '5L32-A31 (5 MHz, 32 elements)',
          wedgeSpec: 'SA31-N55S (55° shear wave)',
          sectorialAngleRange: '40° to 70° Sectorial + TOFD Pair',
          tofdPairUsed: true,
          calibrationBlockRef: 'IIW V1 + 24" X70 Block',
          encoderResolutionMm: 1.0,
          volumeCoveragePercent: 100.0,
          flawEvaluation: 'Clean weld volume, zero sidewall LOF',
          maxAmplitudeDacPercent: 21.0,
          reportNo: 'PAUT/OIL/DUL/GW-02/2026',
          inspectorName: 'Pranjal Baruah',
          certificationLevel: 'ASNT Level III PAUT',
          inspectionDate: '08-Jun-2026',
        ),
        mptDossier: const MptTestingDossier(
          status: NdtExamStatus.passed,
          yokeType: 'Parker Contour B-300 AC Yoke',
          liftCapacityKg: 5.1,
          mediumType: 'Black Oxide Fluorescent on White Contrast (WCP-2)',
          rootPassResult: '100% Cleared, zero root crater cracks',
          hotPassResult: '100% Cleared, no trapped inclusions',
          cappingPassResult: '100% Cleared, smooth cap toe transition',
          reportNo: 'MPT/OIL/DUL/GW-02/C-02',
          inspectorName: 'Hemanta Dutta',
          certificationLevel: 'ISNT Level II MPT',
          inspectionDate: '08-Jun-2026',
        ),
        hardnessDossier: const HardnessTestingDossier(
          status: NdtExamStatus.passed,
          method: 'Vickers HV10 Portable',
          averageHv10: 224,
          maxRecordedHv10: 238,
          limitHv10: 248,
          isNaceMr0175Compliant: true,
          reportNo: 'HD-OIL-DUL-02-HV10',
        ),
        contractorSign: const PartySignature(
          role: TripartiteRole.contractorWelder,
          roleTitle: 'Contractor Lead Welder & QA/QC',
          name: 'Suresh Kumar Sharma',
          organization: 'Kalpataru Projects Ltd (KPL)',
          licenseId: 'KPL-QAQC-7741',
          isSigned: true,
          signedAt: '2026-06-09 11:20 IST',
          signatureHash:
              '3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c',
        ),
        eilTpiaSign: const PartySignature(
          role: TripartiteRole.eilTpia,
          roleTitle: 'EIL TPIA Level III Inspector',
          name: 'Er. Bhaskar Jyoti Goswami',
          organization: 'Engineers India Limited (TPIA)',
          licenseId: 'EIL-NDT-L3-8824',
          isSigned: true,
          signedAt: '2026-06-09 15:40 IST',
          signatureHash:
              '5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f',
        ),
        oilResidentSign: const PartySignature(
          role: TripartiteRole.oilResidentEng,
          roleTitle: 'Oil India Resident Engineer',
          name: 'Er. Debajit Phukan',
          organization: 'Oil India Limited (Pipeline HQ)',
          licenseId: 'OIL-RE-PL-4109',
          isSigned: true,
          signedAt: '2026-06-10 09:30 IST',
          signatureHash:
              '7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b',
        ),
        exemptionCert: const HydrostaticExemptionCertificate(
          certificateNo: 'HEC/OIL-DUL/2026/GW-02',
          governingStandard:
              'OISD-141 (2020) Cl. 13.4.1 & ASME B31.8 (2022) §841.3.2(d)',
          oisdClauseRef: 'OISD-141 Cl. 13.4.1 Golden Weld Exemption',
          asmeClauseRef: 'ASME B31.8 Section 841.3.2(d) Tie-In Clearance',
          issueDate: '10-Jun-2026',
          isApproved: true,
          pretestSectionAId: 'HT-SEC-02 (148.5 Bar)',
          pretestSectionBId: 'HT-SEC-03 (152.0 Bar)',
          tieInWpsNo: 'WPS-OIL-GW-02 Rev.2',
          operatingSafetyFactor: 0.72,
          nitrogenPurgingCleared: true,
          checklistCompletedCount: 7,
          checklistTotalCount: 7,
        ),
        tamperProofSha256:
            '98fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855e3b0c442',
      ),

      // ----------------------------------------------------------------------
      // GW-DUL-03: Disang River Major HDD South Shore Tie-in
      // ----------------------------------------------------------------------
      GoldenWeldRecord(
        id: 'GW-DUL-03',
        jointNumber: 'GW-03',
        chainageKm: 52.110,
        chainageDisplay: 'KP 52+110',
        locationName: 'Disang River Major HDD South Shore Tie-In',
        gpsCoords: '27.0211° N, 94.8872° E',
        pipeSizeInches: 24.0,
        pipeOdMm: 610.0,
        wallThicknessMm: 17.5,
        connectingWallThicknessMm: 14.3,
        pipeGrade: 'API 5L Grade X-70 PSL2 (Heavy Wall HDD Section)',
        wpsNumber: 'WPS-OIL-GW-03 Rev.4',
        welderIds: 'W-2088 / W-2305',
        welderNames: 'Dipankar Saikia / Tapan Chetia',
        weldProcess: 'GTAW Root (ER70S-6) + SMAW Fill/Cap (E8018-G)',
        preheatCelsius: 165.0,
        interpassCelsius: 225.0,
        ambientCondition: '31°C, 70% RH, High Humidity (River Bank)',
        sectionA: const HydrotestSectionSummary(
          sectionId: 'HT-SEC-03',
          chainageRange: 'KP 38+750 to KP 52+110',
          lengthKm: 13.360,
          testPressureBar: 148.5,
          designPressureBar: 98.0,
          testDate: '15-Jun-2026',
          holdDurationHours: 24,
          testMedium: 'Inhibited Potable Water',
          recorderChartNo: 'PR-SEC03-OIL-141',
          witnessOrg: 'EIL TPIA & OIL Resident Inspection',
          isPretestedAndAccepted: true,
        ),
        sectionB: const HydrotestSectionSummary(
          sectionId: 'HT-SEC-04 (Disang HDD)',
          chainageRange: 'KP 52+110 to KP 54+180 (2,070m HDD)',
          lengthKm: 2.070,
          testPressureBar: 160.0,
          designPressureBar: 98.0,
          testDate: '20-Jun-2026',
          holdDurationHours: 24,
          testMedium: 'Inhibited Potable Water',
          recorderChartNo: 'PR-SEC04-HDD-158',
          witnessOrg: 'EIL TPIA & OIL Resident Inspection',
          isPretestedAndAccepted: true,
        ),
        rtDossier: const RadiographicTestingDossier(
          status: NdtExamStatus.passed,
          technique: 'DWSI Elliptical Exposure Class 1',
          radiationSource: 'Iridium-192',
          sourceStrengthCi: 48.0,
          filmType: 'Agfa Structurix D4 Class 1',
          filmDensityHnd: 2.92,
          sensitivityWire: 'ASTM Wire #11 (0.40mm)',
          geometricUnsharpnessMm: 0.13,
          weldCircumferenceExaminedMm: 1916.0,
          coveragePercent: 100.0,
          defectsIdentified: 'Zero Imperfections Detected (API 1104 §9.3)',
          reportNo: 'RT/OIL/DUL/GW-03/REV-2',
          filmReaderName: 'Alok Sen, NDT Specialist',
          certificationLevel: 'ASNT Level II RT',
          inspectionDate: '26-Jun-2026',
        ),
        pautDossier: const PautTestingDossier(
          status: NdtExamStatus.passed,
          instrument: 'Olympus OmniScan X3 64:128PR',
          probeSpec: '5L32-A31 (5 MHz, 32 elements)',
          wedgeSpec: 'SA31-N55S (55° shear)',
          sectorialAngleRange: '40° to 70° Sectorial + Dual TOFD',
          tofdPairUsed: true,
          calibrationBlockRef: 'IIW V1 + 24" X70 Heavy Wall Block',
          encoderResolutionMm: 1.0,
          volumeCoveragePercent: 100.0,
          flawEvaluation: 'Fully compliant, 0 planar flaws across 17.5mm taper',
          maxAmplitudeDacPercent: 18.5,
          reportNo: 'PAUT/OIL/DUL/GW-03/2026',
          inspectorName: 'Pranjal Baruah',
          certificationLevel: 'ASNT Level III PAUT',
          inspectionDate: '26-Jun-2026',
        ),
        mptDossier: const MptTestingDossier(
          status: NdtExamStatus.passed,
          yokeType: 'Parker Contour B-300 AC Yoke',
          liftCapacityKg: 5.3,
          mediumType: 'Black Oxide on White Contrast (WCP-2)',
          rootPassResult: '100% Cleared, zero defects',
          hotPassResult: '100% Cleared, zero defects',
          cappingPassResult: '100% Cleared, smooth taper cap',
          reportNo: 'MPT/OIL/DUL/GW-03/C-03',
          inspectorName: 'Hemanta Dutta',
          certificationLevel: 'ISNT Level II MPT',
          inspectionDate: '26-Jun-2026',
        ),
        hardnessDossier: const HardnessTestingDossier(
          status: NdtExamStatus.passed,
          method: 'Vickers HV10 Portable',
          averageHv10: 228,
          maxRecordedHv10: 242,
          limitHv10: 248,
          isNaceMr0175Compliant: true,
          reportNo: 'HD-OIL-DUL-03-HV10',
        ),
        contractorSign: const PartySignature(
          role: TripartiteRole.contractorWelder,
          roleTitle: 'Contractor Lead Welder & QA/QC',
          name: 'Suresh Kumar Sharma',
          organization: 'Kalpataru Projects Ltd (KPL)',
          licenseId: 'KPL-QAQC-7741',
          isSigned: true,
          signedAt: '2026-06-27 12:10 IST',
          signatureHash:
              '2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b',
        ),
        eilTpiaSign: const PartySignature(
          role: TripartiteRole.eilTpia,
          roleTitle: 'EIL TPIA Level III Inspector',
          name: 'Er. Bhaskar Jyoti Goswami',
          organization: 'Engineers India Limited (TPIA)',
          licenseId: 'EIL-NDT-L3-8824',
          isSigned: true,
          signedAt: '2026-06-27 16:45 IST',
          signatureHash:
              '4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d',
        ),
        oilResidentSign: const PartySignature(
          role: TripartiteRole.oilResidentEng,
          roleTitle: 'Oil India Resident Engineer',
          name: 'Er. Debajit Phukan',
          organization: 'Oil India Limited (Pipeline HQ)',
          licenseId: 'OIL-RE-PL-4109',
          isSigned: true,
          signedAt: '2026-06-28 10:15 IST',
          signatureHash:
              '6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f',
        ),
        exemptionCert: const HydrostaticExemptionCertificate(
          certificateNo: 'HEC/OIL-DUL/2026/GW-03',
          governingStandard:
              'OISD-141 (2020) Cl. 13.4.1 & ASME B31.8 (2022) §841.3.2(d)',
          oisdClauseRef: 'OISD-141 Cl. 13.4.1 Golden Weld Exemption',
          asmeClauseRef: 'ASME B31.8 Section 841.3.2(d) Tie-In Clearance',
          issueDate: '28-Jun-2026',
          isApproved: true,
          pretestSectionAId: 'HT-SEC-03 (148.5 Bar)',
          pretestSectionBId: 'HT-SEC-04 HDD (160.0 Bar)',
          tieInWpsNo: 'WPS-OIL-GW-03 Rev.4',
          operatingSafetyFactor: 0.60,
          nitrogenPurgingCleared: true,
          checklistCompletedCount: 7,
          checklistTotalCount: 7,
        ),
        tamperProofSha256:
            'afbf4c8996fb92427ae41e4649b934ca495991b7852b855e3b0c44298fc1c149',
      ),

      // ----------------------------------------------------------------------
      // GW-DUL-04: NH-37 Highway Crossing Cased Thrust-Bore Tie-in
      // ----------------------------------------------------------------------
      GoldenWeldRecord(
        id: 'GW-DUL-04',
        jointNumber: 'GW-04',
        chainageKm: 74.880,
        chainageDisplay: 'KP 74+880',
        locationName: 'NH-37 Cased Highway Crossing Tie-In',
        gpsCoords: '26.8920° N, 94.6145° E',
        pipeSizeInches: 24.0,
        pipeOdMm: 610.0,
        wallThicknessMm: 14.3,
        connectingWallThicknessMm: 14.3,
        pipeGrade: 'API 5L Grade X-70 PSL2',
        wpsNumber: 'WPS-OIL-GW-01 Rev.3',
        welderIds: 'W-1944 / W-2110',
        welderNames: 'Biren Gogoi / Manoj Kalita',
        weldProcess: 'GTAW Root (ER70S-6) + SMAW Fill/Cap (E8018-G Low-H)',
        preheatCelsius: 155.0,
        interpassCelsius: 210.0,
        ambientCondition: '29°C, 60% RH, Dusty Roadside Crossing',
        sectionA: const HydrotestSectionSummary(
          sectionId: 'HT-SEC-04',
          chainageRange: 'KP 54+180 to KP 74+880',
          lengthKm: 20.700,
          testPressureBar: 148.5,
          designPressureBar: 98.0,
          testDate: '05-Jul-2026',
          holdDurationHours: 24,
          testMedium: 'Inhibited Potable Water',
          recorderChartNo: 'PR-SEC04-OIL-182',
          witnessOrg: 'EIL TPIA & OIL Resident Inspection',
          isPretestedAndAccepted: true,
        ),
        sectionB: const HydrotestSectionSummary(
          sectionId: 'HT-SEC-05 (Highway Bore)',
          chainageRange: 'KP 74+880 to KP 75+060 (180m Cased Bore)',
          lengthKm: 0.180,
          testPressureBar: 155.0,
          designPressureBar: 98.0,
          testDate: '10-Jul-2026',
          holdDurationHours: 24,
          testMedium: 'Inhibited Potable Water',
          recorderChartNo: 'PR-SEC05-HWY-196',
          witnessOrg: 'EIL TPIA & OIL Resident Inspection',
          isPretestedAndAccepted: true,
        ),
        rtDossier: const RadiographicTestingDossier(
          status: NdtExamStatus.passed,
          technique: 'DWSI Elliptical Exposure Class 1',
          radiationSource: 'Iridium-192',
          sourceStrengthCi: 41.5,
          filmType: 'Agfa Structurix D4 Class 1',
          filmDensityHnd: 2.80,
          sensitivityWire: 'ASTM Wire #11 (0.40mm)',
          geometricUnsharpnessMm: 0.14,
          weldCircumferenceExaminedMm: 1916.0,
          coveragePercent: 100.0,
          defectsIdentified: 'Zero Imperfections Detected (API 1104 §9.3)',
          reportNo: 'RT/OIL/DUL/GW-04/REV-0',
          filmReaderName: 'Alok Sen, NDT Specialist',
          certificationLevel: 'ASNT Level II RT',
          inspectionDate: '14-Jul-2026',
        ),
        pautDossier: const PautTestingDossier(
          status: NdtExamStatus.passed,
          instrument: 'Olympus OmniScan X3 64:128PR',
          probeSpec: '5L32-A31 (5 MHz, 32 elements)',
          wedgeSpec: 'SA31-N55S (55° shear)',
          sectorialAngleRange: '40° to 70° Sectorial + Dual TOFD',
          tofdPairUsed: true,
          calibrationBlockRef: 'IIW V1 + 24" X70 Block',
          encoderResolutionMm: 1.0,
          volumeCoveragePercent: 100.0,
          flawEvaluation: 'Acceptable per ASME Sec V Art 4, zero planar defects',
          maxAmplitudeDacPercent: 22.0,
          reportNo: 'PAUT/OIL/DUL/GW-04/2026',
          inspectorName: 'Pranjal Baruah',
          certificationLevel: 'ASNT Level III PAUT',
          inspectionDate: '14-Jul-2026',
        ),
        mptDossier: const MptTestingDossier(
          status: NdtExamStatus.passed,
          yokeType: 'Parker Contour B-300 AC Yoke',
          liftCapacityKg: 5.2,
          mediumType: 'Black Oxide on White Contrast (WCP-2)',
          rootPassResult: '100% Cleared, zero defects',
          hotPassResult: '100% Cleared, zero defects',
          cappingPassResult: '100% Cleared, smooth weld cap',
          reportNo: 'MPT/OIL/DUL/GW-04/C-04',
          inspectorName: 'Hemanta Dutta',
          certificationLevel: 'ISNT Level II MPT',
          inspectionDate: '14-Jul-2026',
        ),
        hardnessDossier: const HardnessTestingDossier(
          status: NdtExamStatus.passed,
          method: 'Vickers HV10 Portable',
          averageHv10: 222,
          maxRecordedHv10: 236,
          limitHv10: 248,
          isNaceMr0175Compliant: true,
          reportNo: 'HD-OIL-DUL-04-HV10',
        ),
        contractorSign: const PartySignature(
          role: TripartiteRole.contractorWelder,
          roleTitle: 'Contractor Lead Welder & QA/QC',
          name: 'Suresh Kumar Sharma',
          organization: 'Kalpataru Projects Ltd (KPL)',
          licenseId: 'KPL-QAQC-7741',
          isSigned: true,
          signedAt: '2026-07-15 14:00 IST',
          signatureHash:
              '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
        ),
        eilTpiaSign: const PartySignature(
          role: TripartiteRole.eilTpia,
          roleTitle: 'EIL TPIA Level III Inspector',
          name: 'Er. Bhaskar Jyoti Goswami',
          organization: 'Engineers India Limited (TPIA)',
          licenseId: 'EIL-NDT-L3-8824',
          isSigned: true,
          signedAt: '2026-07-15 18:30 IST',
          signatureHash:
              '3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d',
        ),
        oilResidentSign: const PartySignature(
          role: TripartiteRole.oilResidentEng,
          roleTitle: 'Oil India Resident Engineer',
          name: 'Er. Debajit Phukan',
          organization: 'Oil India Limited (Pipeline HQ)',
          licenseId: 'OIL-RE-PL-4109',
          isSigned: false, // Pending Resident Engineer Final Audit
        ),
        exemptionCert: const HydrostaticExemptionCertificate(
          certificateNo: 'HEC/OIL-DUL/2026/GW-04',
          governingStandard:
              'OISD-141 (2020) Cl. 13.4.1 & ASME B31.8 (2022) §841.3.2(d)',
          oisdClauseRef: 'OISD-141 Cl. 13.4.1 Golden Weld Exemption',
          asmeClauseRef: 'ASME B31.8 Section 841.3.2(d) Tie-In Clearance',
          issueDate: 'Pending OIL Sign-Off',
          isApproved: false,
          pretestSectionAId: 'HT-SEC-04 (148.5 Bar)',
          pretestSectionBId: 'HT-SEC-05 HWY (155.0 Bar)',
          tieInWpsNo: 'WPS-OIL-GW-01 Rev.3',
          operatingSafetyFactor: 0.60,
          nitrogenPurgingCleared: false,
          checklistCompletedCount: 6,
          checklistTotalCount: 7,
        ),
        tamperProofSha256:
            '7ae41e4649b934ca495991b7852b855e3b0c44298fc1c149afbf4c8996fb9242',
      ),

      // ----------------------------------------------------------------------
      // GW-DUL-05: Railway Siding & Switchyard HDD Tie-in
      // ----------------------------------------------------------------------
      GoldenWeldRecord(
        id: 'GW-DUL-05',
        jointNumber: 'GW-05',
        chainageKm: 98.420,
        chainageDisplay: 'KP 98+420',
        locationName: 'Railway Siding & Switchyard HDD Tie-In',
        gpsCoords: '26.7410° N, 94.3980° E',
        pipeSizeInches: 24.0,
        pipeOdMm: 610.0,
        wallThicknessMm: 17.5,
        connectingWallThicknessMm: 14.3,
        pipeGrade: 'API 5L Grade X-70 PSL2 (Heavy Wall Railway)',
        wpsNumber: 'WPS-OIL-GW-03 Rev.4',
        welderIds: 'W-2088 / W-1822',
        welderNames: 'Dipankar Saikia / Rahul Borgohain',
        weldProcess: 'GTAW Root (ER70S-6) + SMAW Fill/Cap (E8018-G Low-H)',
        preheatCelsius: 160.0,
        interpassCelsius: 220.0,
        ambientCondition: '32°C, 55% RH, Switchyard Embankment',
        sectionA: const HydrotestSectionSummary(
          sectionId: 'HT-SEC-05',
          chainageRange: 'KP 75+060 to KP 98+420',
          lengthKm: 23.360,
          testPressureBar: 148.5,
          designPressureBar: 98.0,
          testDate: '22-Jul-2026',
          holdDurationHours: 24,
          testMedium: 'Inhibited Potable Water',
          recorderChartNo: 'PR-SEC05-OIL-221',
          witnessOrg: 'EIL TPIA & OIL Resident Inspection',
          isPretestedAndAccepted: true,
        ),
        sectionB: const HydrotestSectionSummary(
          sectionId: 'HT-SEC-06 (Railway HDD)',
          chainageRange: 'KP 98+420 to KP 99+380 (960m HDD)',
          lengthKm: 0.960,
          testPressureBar: 155.0,
          designPressureBar: 98.0,
          testDate: '26-Jul-2026',
          holdDurationHours: 24,
          testMedium: 'Inhibited Potable Water',
          recorderChartNo: 'PR-SEC06-RLY-238',
          witnessOrg: 'EIL TPIA & OIL Resident Inspection',
          isPretestedAndAccepted: true,
        ),
        rtDossier: const RadiographicTestingDossier(
          status: NdtExamStatus.passed,
          technique: 'DWSI Elliptical Exposure Class 1',
          radiationSource: 'Iridium-192',
          sourceStrengthCi: 43.0,
          filmType: 'Agfa Structurix D4 Class 1',
          filmDensityHnd: 2.84,
          sensitivityWire: 'ASTM Wire #11 (0.40mm)',
          geometricUnsharpnessMm: 0.13,
          weldCircumferenceExaminedMm: 1916.0,
          coveragePercent: 100.0,
          defectsIdentified: 'Zero Imperfections Detected (API 1104 §9.3)',
          reportNo: 'RT/OIL/DUL/GW-05/REV-0',
          filmReaderName: 'Alok Sen, NDT Specialist',
          certificationLevel: 'ASNT Level II RT',
          inspectionDate: '28-Jul-2026',
        ),
        pautDossier: const PautTestingDossier(
          status: NdtExamStatus.underReview,
          instrument: 'Olympus OmniScan X3 64:128PR',
          probeSpec: '5L32-A31 (5 MHz, 32 elements)',
          wedgeSpec: 'SA31-N55S (55° shear)',
          sectorialAngleRange: '40° to 70° Sectorial + TOFD',
          tofdPairUsed: true,
          calibrationBlockRef: 'IIW V1 + 24" X70 Block',
          encoderResolutionMm: 1.0,
          volumeCoveragePercent: 98.5,
          flawEvaluation:
              'Sectorial scan complete; resolving 1.2mm volumetric inclusion at clock 4:30',
          maxAmplitudeDacPercent: 28.0,
          reportNo: 'PAUT/OIL/DUL/GW-05/2026',
          inspectorName: 'Pranjal Baruah',
          certificationLevel: 'ASNT Level III PAUT',
          inspectionDate: '28-Jul-2026',
        ),
        mptDossier: const MptTestingDossier(
          status: NdtExamStatus.passed,
          yokeType: 'Parker Contour B-300 AC Yoke',
          liftCapacityKg: 5.1,
          mediumType: 'Black Oxide on White Contrast (WCP-2)',
          rootPassResult: '100% Cleared, zero defects',
          hotPassResult: '100% Cleared, zero defects',
          cappingPassResult: '100% Cleared, smooth cap',
          reportNo: 'MPT/OIL/DUL/GW-05/C-05',
          inspectorName: 'Hemanta Dutta',
          certificationLevel: 'ISNT Level II MPT',
          inspectionDate: '28-Jul-2026',
        ),
        hardnessDossier: const HardnessTestingDossier(
          status: NdtExamStatus.passed,
          method: 'Vickers HV10 Portable',
          averageHv10: 226,
          maxRecordedHv10: 240,
          limitHv10: 248,
          isNaceMr0175Compliant: true,
          reportNo: 'HD-OIL-DUL-05-HV10',
        ),
        contractorSign: const PartySignature(
          role: TripartiteRole.contractorWelder,
          roleTitle: 'Contractor Lead Welder & QA/QC',
          name: 'Suresh Kumar Sharma',
          organization: 'Kalpataru Projects Ltd (KPL)',
          licenseId: 'KPL-QAQC-7741',
          isSigned: true,
          signedAt: '2026-07-29 09:15 IST',
          signatureHash:
              '2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c',
        ),
        eilTpiaSign: const PartySignature(
          role: TripartiteRole.eilTpia,
          roleTitle: 'EIL TPIA Level III Inspector',
          name: 'Er. Bhaskar Jyoti Goswami',
          organization: 'Engineers India Limited (TPIA)',
          licenseId: 'EIL-NDT-L3-8824',
          isSigned: false, // Pending PAUT review
        ),
        oilResidentSign: const PartySignature(
          role: TripartiteRole.oilResidentEng,
          roleTitle: 'Oil India Resident Engineer',
          name: 'Er. Debajit Phukan',
          organization: 'Oil India Limited (Pipeline HQ)',
          licenseId: 'OIL-RE-PL-4109',
          isSigned: false,
        ),
        exemptionCert: const HydrostaticExemptionCertificate(
          certificateNo: 'HEC/OIL-DUL/2026/GW-05',
          governingStandard:
              'OISD-141 (2020) Cl. 13.4.1 & ASME B31.8 (2022) §841.3.2(d)',
          oisdClauseRef: 'OISD-141 Cl. 13.4.1 Golden Weld Exemption',
          asmeClauseRef: 'ASME B31.8 Section 841.3.2(d) Tie-In Clearance',
          issueDate: 'Dossier Under Review',
          isApproved: false,
          pretestSectionAId: 'HT-SEC-05 (148.5 Bar)',
          pretestSectionBId: 'HT-SEC-06 RLY (155.0 Bar)',
          tieInWpsNo: 'WPS-OIL-GW-03 Rev.4',
          operatingSafetyFactor: 0.60,
          nitrogenPurgingCleared: false,
          checklistCompletedCount: 5,
          checklistTotalCount: 7,
        ),
        tamperProofSha256:
            '49b934ca495991b7852b855e3b0c44298fc1c149afbf4c8996fb92427ae41e46',
      ),

      // ----------------------------------------------------------------------
      // GW-DUL-06: Numaligarh Despatch / Custody Transfer Metering Skid Tie-in
      // ----------------------------------------------------------------------
      GoldenWeldRecord(
        id: 'GW-DUL-06',
        jointNumber: 'GW-06',
        chainageKm: 118.950,
        chainageDisplay: 'KP 118+950',
        locationName: 'Numaligarh Custody Transfer Metering Skid Tie-In',
        gpsCoords: '26.5874° N, 93.7312° E',
        pipeSizeInches: 24.0,
        pipeOdMm: 610.0,
        wallThicknessMm: 14.3,
        connectingWallThicknessMm: 14.3,
        pipeGrade: 'API 5L Grade X-70 PSL2 / WNRF Cl.600 Header',
        wpsNumber: 'WPS-OIL-GW-02 Rev.2',
        welderIds: 'W-1822 / W-2305',
        welderNames: 'Rahul Borgohain / Tapan Chetia',
        weldProcess: 'GTAW Root (ER70S-6) + SMAW Fill/Cap (E9018-G Low-H)',
        preheatCelsius: 160.0,
        interpassCelsius: 215.0,
        ambientCondition: '33°C, 52% RH, Refinery Terminal Terminal Yard',
        sectionA: const HydrotestSectionSummary(
          sectionId: 'HT-SEC-06',
          chainageRange: 'KP 99+380 to KP 118+950',
          lengthKm: 19.570,
          testPressureBar: 148.5,
          designPressureBar: 98.0,
          testDate: '02-Aug-2026',
          holdDurationHours: 24,
          testMedium: 'Inhibited Potable Water',
          recorderChartNo: 'PR-SEC06-OIL-264',
          witnessOrg: 'EIL TPIA & OIL Resident Inspection',
          isPretestedAndAccepted: true,
        ),
        sectionB: const HydrotestSectionSummary(
          sectionId: 'HT-SEC-SKID (NRL Skid)',
          chainageRange: 'KP 118+950 Custody Metering Manifold',
          lengthKm: 0.120,
          testPressureBar: 155.0,
          designPressureBar: 98.0,
          testDate: '05-Aug-2026',
          holdDurationHours: 24,
          testMedium: 'Inhibited Potable Water',
          recorderChartNo: 'PR-SKID01-NRL-280',
          witnessOrg: 'EIL TPIA & OIL Resident Inspection',
          isPretestedAndAccepted: true,
        ),
        rtDossier: const RadiographicTestingDossier(
          status: NdtExamStatus.pending,
          technique: 'DWSI Elliptical Exposure Class 1',
          radiationSource: 'Iridium-192',
          sourceStrengthCi: 40.0,
          filmType: 'Agfa Structurix D4 Class 1',
          filmDensityHnd: 0.0,
          sensitivityWire: 'Wire #11 Scheduled',
          geometricUnsharpnessMm: 0.0,
          weldCircumferenceExaminedMm: 0.0,
          coveragePercent: 0.0,
          defectsIdentified: 'Welding completed; RT film exposure scheduled 22:00 tonight',
          reportNo: 'RT/OIL/DUL/GW-06/PENDING',
          filmReaderName: 'Alok Sen, NDT Specialist',
          certificationLevel: 'ASNT Level II RT',
          inspectionDate: 'Scheduled 10-Aug-2026',
        ),
        pautDossier: const PautTestingDossier(
          status: NdtExamStatus.pending,
          instrument: 'Olympus OmniScan X3 64:128PR',
          probeSpec: '5L32-A31 (5 MHz, 32 elements)',
          wedgeSpec: 'SA31-N55S (55° shear)',
          sectorialAngleRange: '40° to 70° Sectorial + TOFD',
          tofdPairUsed: true,
          calibrationBlockRef: 'IIW V1 Block Calibrated',
          encoderResolutionMm: 1.0,
          volumeCoveragePercent: 0.0,
          flawEvaluation: 'Awaiting weld cooldown to ambient < 50°C for ultrasonic coupling',
          maxAmplitudeDacPercent: 0.0,
          reportNo: 'PAUT/OIL/DUL/GW-06/PENDING',
          inspectorName: 'Pranjal Baruah',
          certificationLevel: 'ASNT Level III PAUT',
          inspectionDate: 'Scheduled 11-Aug-2026',
        ),
        mptDossier: const MptTestingDossier(
          status: NdtExamStatus.passed,
          yokeType: 'Parker Contour B-300 AC Yoke',
          liftCapacityKg: 5.2,
          mediumType: 'Black Oxide on White Contrast (WCP-2)',
          rootPassResult: '100% Cleared (Witnessed by EIL Inspector)',
          hotPassResult: '100% Cleared',
          cappingPassResult: 'Capping MPI inspection in queue',
          reportNo: 'MPT/OIL/DUL/GW-06/ROOT',
          inspectorName: 'Hemanta Dutta',
          certificationLevel: 'ISNT Level II MPT',
          inspectionDate: '09-Aug-2026',
        ),
        hardnessDossier: const HardnessTestingDossier(
          status: NdtExamStatus.pending,
          method: 'Vickers HV10 Portable',
          averageHv10: 0,
          maxRecordedHv10: 0,
          limitHv10: 248,
          isNaceMr0175Compliant: false,
          reportNo: 'HD-OIL-DUL-06-PENDING',
        ),
        contractorSign: const PartySignature(
          role: TripartiteRole.contractorWelder,
          roleTitle: 'Contractor Lead Welder & QA/QC',
          name: 'Suresh Kumar Sharma',
          organization: 'Kalpataru Projects Ltd (KPL)',
          licenseId: 'KPL-QAQC-7741',
          isSigned: false,
        ),
        eilTpiaSign: const PartySignature(
          role: TripartiteRole.eilTpia,
          roleTitle: 'EIL TPIA Level III Inspector',
          name: 'Er. Bhaskar Jyoti Goswami',
          organization: 'Engineers India Limited (TPIA)',
          licenseId: 'EIL-NDT-L3-8824',
          isSigned: false,
        ),
        oilResidentSign: const PartySignature(
          role: TripartiteRole.oilResidentEng,
          roleTitle: 'Oil India Resident Engineer',
          name: 'Er. Debajit Phukan',
          organization: 'Oil India Limited (Pipeline HQ)',
          licenseId: 'OIL-RE-PL-4109',
          isSigned: false,
        ),
        exemptionCert: const HydrostaticExemptionCertificate(
          certificateNo: 'HEC/OIL-DUL/2026/GW-06',
          governingStandard:
              'OISD-141 (2020) Cl. 13.4.1 & ASME B31.8 (2022) §841.3.2(d)',
          oisdClauseRef: 'OISD-141 Cl. 13.4.1 Golden Weld Exemption',
          asmeClauseRef: 'ASME B31.8 Section 841.3.2(d) Tie-In Clearance',
          issueDate: 'Awaiting 100% NDE Dossier',
          isApproved: false,
          pretestSectionAId: 'HT-SEC-06 (148.5 Bar)',
          pretestSectionBId: 'HT-SEC-SKID (155.0 Bar)',
          tieInWpsNo: 'WPS-OIL-GW-02 Rev.2',
          operatingSafetyFactor: 0.72,
          nitrogenPurgingCleared: false,
          checklistCompletedCount: 3,
          checklistTotalCount: 7,
        ),
        tamperProofSha256:
            '27ae41e4649b934ca495991b7852b855e3b0c44298fc1c149afbf4c8996fb924',
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // ACTIONS & LOGIC
  // --------------------------------------------------------------------------

  void _applyFilter(String filter) {
    setState(() {
      _filterStatus = filter;
    });
  }

  List<GoldenWeldRecord> get filteredRecords {
    if (_filterStatus == 'CERTIFIED') {
      return _records.where((r) => r.isFullyCertified).toList();
    } else if (_filterStatus == 'PENDING_SIGN') {
      return _records
          .where((r) => !r.isFullyCertified && r.signatureCount > 0)
          .toList();
    } else if (_filterStatus == 'IN_PROGRESS') {
      return _records.where((r) => r.signatureCount == 0).toList();
    }
    return _records;
  }

  void _signRecord(GoldenWeldRecord record, TripartiteRole role,
      List<Offset> strokePoints) {
    final nowStr =
        '${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())} IST';
    final rawSeed =
        '${record.id}-${role.name}-$nowStr-${strokePoints.length}-NIRMAAN-OIL-EIL';
    final generatedHash = sha256.convert(utf8.encode(rawSeed)).toString();

    setState(() {
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index == -1) return;

      var updated = _records[index];

      PartySignature newContractor = updated.contractorSign;
      PartySignature newEil = updated.eilTpiaSign;
      PartySignature newOil = updated.oilResidentSign;

      switch (role) {
        case TripartiteRole.contractorWelder:
          newContractor = updated.contractorSign.copyWith(
            isSigned: true,
            signedAt: nowStr,
            signatureHash: generatedHash,
            signatureStrokePoints: strokePoints,
          );
          break;
        case TripartiteRole.eilTpia:
          newEil = updated.eilTpiaSign.copyWith(
            isSigned: true,
            signedAt: nowStr,
            signatureHash: generatedHash,
            signatureStrokePoints: strokePoints,
          );
          break;
        case TripartiteRole.oilResidentEng:
          newOil = updated.oilResidentSign.copyWith(
            isSigned: true,
            signedAt: nowStr,
            signatureHash: generatedHash,
            signatureStrokePoints: strokePoints,
          );
          break;
      }

      final allThreeSigned =
          newContractor.isSigned && newEil.isSigned && newOil.isSigned;

      HydrostaticExemptionCertificate newCert = updated.exemptionCert;
      if (allThreeSigned) {
        newCert = updated.exemptionCert.copyWith(
          isApproved: true,
          checklistCompletedCount: 7,
          nitrogenPurgingCleared: true,
          issueDate: DateFormat('dd-MMM-yyyy').format(DateTime.now()),
        );
      }

      // Re-hash composite dossier
      final compositeContent = '${updated.id}|${newCert.certificateNo}|'
          '${newContractor.signatureHash}|${newEil.signatureHash}|${newOil.signatureHash}|'
          '${updated.sectionA.recorderChartNo}|${updated.sectionB.recorderChartNo}';
      final compositeSha256 =
          sha256.convert(utf8.encode(compositeContent)).toString();

      _records[index] = updated.copyWith(
        contractorSign: newContractor,
        eilTpiaSign: newEil,
        oilResidentSign: newOil,
        exemptionCert: newCert,
        tamperProofSha256: compositeSha256,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${role.title} digital sign-off recorded for ${record.id}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BUILD METHOD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProjectSummaryHeader(),
          _buildKpiDashboardRow(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabJointRegistry(),
                _buildTabNdeDossier(),
                _buildTabExemptionCertificate(),
                _buildTabTripartiteVault(),
                _buildTabCadUltrasonicVisualizer(),
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
      backgroundColor: AppTheme.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Golden Weld & Tie-In Certification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'OISD-141 Cl. 13.4 • ASME B31.8 §841.3 • 100% NDE Dossier',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Standards & OISD Guidelines',
          icon: const Icon(Icons.menu_book_rounded,
              color: AppTheme.textSecondary, size: 22),
          onPressed: _showStandardsGuideModal,
        ),
        IconButton(
          tooltip: 'Export Tripartite Dossier',
          icon: const Icon(Icons.file_download_rounded,
              color: AppTheme.primaryLight, size: 22),
          onPressed: () => _showExportDossierDialog(currentRecord),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // HEADER BANNER
  // --------------------------------------------------------------------------
  Widget _buildProjectSummaryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withAlpha(40),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF0284C7).withAlpha(100),
              ),
            ),
            child: const Icon(
              Icons.precision_manufacturing_rounded,
              color: Color(0xFF38BDF8),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'OIL INDIA LIMITED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFB95F),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2E5C),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF3B82F6)),
                      ),
                      child: const Text(
                        'PMC: ENGINEERS INDIA LTD (EIL)',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Duliajan - Numaligarh Pipeline Project (DNPL Ext-II 24" X-70)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Joint Selector Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedJointId,
                dropdownColor: AppTheme.surfaceCard,
                icon: const Icon(Icons.arrow_drop_down,
                    color: AppTheme.primaryLight),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
                items: _records.map((r) {
                  return DropdownMenuItem<String>(
                    value: r.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          r.isFullyCertified
                              ? Icons.verified_rounded
                              : Icons.watch_later_rounded,
                          color: r.isFullyCertified
                              ? const Color(0xFF4EDEA3)
                              : const Color(0xFFFFB95F),
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(r.id),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newVal) {
                  if (newVal != null) {
                    setState(() {
                      _selectedJointId = newVal;
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

  // --------------------------------------------------------------------------
  // KPI DASHBOARD
  // --------------------------------------------------------------------------
  Widget _buildKpiDashboardRow() {
    final totalWelds = _records.length;
    final certifiedWelds = _records.where((r) => r.isFullyCertified).length;
    final pendingCount = totalWelds - certifiedWelds;

    int totalSigs = 0;
    for (var r in _records) {
      totalSigs += r.signatureCount;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildKpiCard(
                title: 'GOLDEN WELDS',
                value: '$totalWelds Joints',
                subtitle: 'GW-DUL-01 to 06',
                accentColor: const Color(0xFF38BDF8),
                icon: Icons.hub_rounded,
              ),
              const SizedBox(width: 8),
              _buildKpiCard(
                title: 'EXEMPTION CERT.',
                value: '$certifiedWelds / $totalWelds',
                subtitle: certifiedWelds == totalWelds
                    ? '100% EXEMPTED'
                    : '$pendingCount IN PROGRESS',
                accentColor: const Color(0xFF4EDEA3),
                icon: Icons.verified_rounded,
              ),
              const SizedBox(width: 8),
              _buildKpiCard(
                title: '100% NDE COVERAGE',
                value: 'RT + PAUT',
                subtitle: 'Plus MPT Root & Cap',
                accentColor: const Color(0xFFFFB95F),
                icon: Icons.radar_rounded,
              ),
              const SizedBox(width: 8),
              _buildKpiCard(
                title: 'TRIPARTITE SIGNS',
                value: '$totalSigs / 18',
                subtitle: 'OIL • EIL • Contractor',
                accentColor: const Color(0xFFA78BFA),
                icon: Icons.rate_review_rounded,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Welds (6)'),
                const SizedBox(width: 6),
                _buildFilterChip(
                    'CERTIFIED', 'Fully Certified ($certifiedWelds)'),
                const SizedBox(width: 6),
                _buildFilterChip(
                    'PENDING_SIGN', 'Sign-Off In Progress ($pendingCount)'),
                const SizedBox(width: 6),
                _buildFilterChip('IN_PROGRESS', 'Dossier Assembly'),
              ],
            ),
          ),
        ],
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.2,
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
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
              maxLines: 1,
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 8,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filterStatus == key;
    return GestureDetector(
      onTap: () => _applyFilter(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withAlpha(50)
              : AppTheme.surfaceContainerHigh.withAlpha(100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB BAR
  // --------------------------------------------------------------------------
  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.view_agenda_rounded, size: 18),
            text: 'Joints Registry',
          ),
          Tab(
            icon: Icon(Icons.science_rounded, size: 18),
            text: '100% NDE Dossier',
          ),
          Tab(
            icon: Icon(Icons.verified_rounded, size: 18),
            text: 'Hydro Exemption',
          ),
          Tab(
            icon: Icon(Icons.draw_rounded, size: 18),
            text: 'Tripartite Sign-Off',
          ),
          Tab(
            icon: Icon(Icons.biotech_rounded, size: 18),
            text: 'PAUT & Bevel Visualizer',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: GOLDEN WELDS REGISTRY
  // ==========================================================================
  Widget _buildTabJointRegistry() {
    final list = filteredRecords;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final record = list[index];
        final isSelected = record.id == _selectedJointId;
        return _buildJointRegistryCard(record, isSelected);
      },
    );
  }

  Widget _buildJointRegistryCard(GoldenWeldRecord record, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryLight : AppTheme.border,
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.primaryLight.withAlpha(40),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedJointId = record.id;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Joint ID & Exemption Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF38BDF8),
                            ),
                          ),
                          child: Text(
                            record.id,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          record.chainageDisplay,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFB95F),
                          ),
                        ),
                      ],
                    ),
                    _buildExemptionPill(record),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  record.locationName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      record.gpsCoords,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 12),

                // Connecting Hydrotest Sections Visual Flow
                _buildConnectingSectionsFlow(record),

                const SizedBox(height: 14),

                // NDE 3-Method Badges
                Row(
                  children: [
                    _buildMiniNdeBadge('100% RT Class 1', record.rtDossier.status),
                    const SizedBox(width: 6),
                    _buildMiniNdeBadge(
                        '100% PAUT/TOFD', record.pautDossier.status),
                    const SizedBox(width: 6),
                    _buildMiniNdeBadge(
                        'MPT Root & Cap', record.mptDossier.status),
                  ],
                ),

                const SizedBox(height: 14),

                // Tripartite Sign-off Status Indicators
                _buildTripartiteStatusBar(record),

                const SizedBox(height: 10),

                // Bottom Quick Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WPS: ${record.wpsNumber} • Welder: ${record.welderIds}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(Icons.description_outlined,
                              size: 14, color: AppTheme.primaryLight),
                          label: const Text(
                            'View Dossier',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedJointId = record.id;
                            });
                            _tabController.animateTo(1);
                          },
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: record.isFullyCertified
                                ? const Color(0xFF10B981)
                                : AppTheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          icon: Icon(
                            record.isFullyCertified
                                ? Icons.verified_rounded
                                : Icons.edit_note_rounded,
                            size: 14,
                          ),
                          label: Text(
                            record.isFullyCertified
                                ? 'Certificate'
                                : 'Sign (${record.signatureCount}/3)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedJointId = record.id;
                            });
                            if (record.isFullyCertified) {
                              _tabController.animateTo(2); // Exemption tab
                            } else {
                              _tabController.animateTo(3); // Sign-off tab
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExemptionPill(GoldenWeldRecord record) {
    if (record.isFullyCertified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withAlpha(40),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_rounded,
                color: Color(0xFF4EDEA3), size: 14),
            SizedBox(width: 5),
            Text(
              'OISD EXEMPTION ISSUED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4EDEA3),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB95F).withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFB95F)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pending_actions_rounded,
                color: Color(0xFFFFB95F), size: 14),
            const SizedBox(width: 5),
            Text(
              '${record.signatureCount}/3 SIGNED',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFFB95F),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildConnectingSectionsFlow(GoldenWeldRecord record) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border.withAlpha(120)),
      ),
      child: Row(
        children: [
          // Section A
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF4EDEA3), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      record.sectionA.sectionId,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.sectionA.testPressureBar} Bar (24h hold)',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF38BDF8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  record.sectionA.chainageRange,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Central Tie-in Weld Icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB95F).withAlpha(40),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFB95F)),
                  ),
                  child: const Icon(
                    Icons.offline_bolt_rounded,
                    color: Color(0xFFFFB95F),
                    size: 14,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'TIE-IN',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFB95F),
                  ),
                ),
              ],
            ),
          ),

          // Section B
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      record.sectionB.sectionId,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle,
                        color: Color(0xFF4EDEA3), size: 12),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.sectionB.testPressureBar} Bar (24h hold)',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF38BDF8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  record.sectionB.chainageRange,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniNdeBadge(String label, NdtExamStatus status) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: status.color.withAlpha(20),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: status.color.withAlpha(90)),
        ),
        child: Row(
          children: [
            Icon(status.icon, color: status.color, size: 12),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: status.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripartiteStatusBar(GoldenWeldRecord record) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTriPartyIcon(
            role: 'Lead Welder',
            isSigned: record.contractorSign.isSigned,
            icon: Icons.engineering_rounded,
          ),
          Container(width: 20, height: 1.5, color: AppTheme.border),
          _buildTriPartyIcon(
            role: 'EIL TPIA Level III',
            isSigned: record.eilTpiaSign.isSigned,
            icon: Icons.verified_user_rounded,
          ),
          Container(width: 20, height: 1.5, color: AppTheme.border),
          _buildTriPartyIcon(
            role: 'OIL Resident Eng',
            isSigned: record.oilResidentSign.isSigned,
            icon: Icons.military_tech_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTriPartyIcon({
    required String role,
    required bool isSigned,
    required IconData icon,
  }) {
    final color =
        isSigned ? const Color(0xFF4EDEA3) : const Color(0xFF64748B);
    return Row(
      children: [
        Icon(
          isSigned ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: color,
          size: 13,
        ),
        const SizedBox(width: 5),
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          role,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 2: 100% NON-DESTRUCTIVE EXAMINATION DOSSIER
  // ==========================================================================
  Widget _buildTabNdeDossier() {
    final record = currentRecord;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActiveJointContextBanner(record),
        const SizedBox(height: 14),

        // Section 1: 100% Radiographic Testing (RT Class 1)
        _buildRtDossierCard(record.rtDossier),

        const SizedBox(height: 14),

        // Section 2: 100% Phased Array Ultrasonic Testing (PAUT & TOFD)
        _buildPautDossierCard(record.pautDossier),

        const SizedBox(height: 14),

        // Section 3: 100% Magnetic Particle Testing (MPT Root & Cap)
        _buildMptDossierCard(record.mptDossier),

        const SizedBox(height: 14),

        // Section 4: Hardness (Vickers HV10) & Weld Metallurgy
        _buildHardnessMetallurgyCard(record),

        const SizedBox(height: 14),

        // Section 5: Welding Procedure Specification (WPS) & Welder WPQR Record
        _buildWpsWelderCard(record),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActiveJointContextBanner(GoldenWeldRecord record) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXAMINATION DOSSIER • ${record.id}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryLight,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${record.chainageDisplay} — ${record.pipeSizeInches}" OD × ${record.wallThicknessMm}mm WT ${record.pipeGrade}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          _buildExemptionPill(record),
        ],
      ),
    );
  }

  // --- RT DOSSIER CARD ---
  Widget _buildRtDossierCard(RadiographicTestingDossier rt) {
    return _buildDossierCardContainer(
      title: '1. 100% Radiographic Testing (RT Class 1)',
      subtitle:
          'API 1104 §9.3 & ASME Sec V Art. 2 • DWSI Elliptical Gamma Radiography',
      status: rt.status,
      accentColor: const Color(0xFF38BDF8),
      icon: Icons.camera_enhance_rounded,
      child: Column(
        children: [
          _buildDossierMetricRow([
            _buildMetricCell('TECHNIQUE', rt.technique),
            _buildMetricCell(
                'SOURCE', '${rt.radiationSource} (${rt.sourceStrengthCi} Ci)'),
          ]),
          const SizedBox(height: 8),
          _buildDossierMetricRow([
            _buildMetricCell('FILM TYPE', rt.filmType),
            _buildMetricCell(
              'FILM DENSITY (H&D)',
              rt.filmDensityHnd > 0
                  ? '${rt.filmDensityHnd.toStringAsFixed(2)} H&D (Req: 2.0-4.0)'
                  : 'Pending Exposure',
              highlightColor: rt.filmDensityHnd >= 2.0
                  ? const Color(0xFF4EDEA3)
                  : const Color(0xFFFFB95F),
            ),
          ]),
          const SizedBox(height: 8),
          _buildDossierMetricRow([
            _buildMetricCell('IQI SENSITIVITY', rt.sensitivityWire),
            _buildMetricCell('GEOM. UNSHARPNESS',
                '${rt.geometricUnsharpnessMm} mm (Limit ≤ 0.5mm)'),
          ]),
          const SizedBox(height: 8),
          _buildDossierMetricRow([
            _buildMetricCell('WELD EXAMINED',
                '${rt.weldCircumferenceExaminedMm} mm (100% Circumference)'),
            _buildMetricCell('REPORT REF.', rt.reportNo),
          ]),
          const SizedBox(height: 10),
          // Film Reader & Evaluation Result Banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_search_rounded,
                    color: Color(0xFF38BDF8), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interpreted by ${rt.filmReaderName} (${rt.certificationLevel}) on ${rt.inspectionDate}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Finding: ${rt.defectsIdentified}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4EDEA3),
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

  // --- PAUT DOSSIER CARD ---
  Widget _buildPautDossierCard(PautTestingDossier paut) {
    return _buildDossierCardContainer(
      title: '2. 100% Phased Array Ultrasonic Testing (PAUT & TOFD)',
      subtitle:
          'ASME Sec V Art. 4 & ISO 13588 • Automated Sectorial Scan & Time-of-Flight',
      status: paut.status,
      accentColor: const Color(0xFF4EDEA3),
      icon: Icons.graphic_eq_rounded,
      child: Column(
        children: [
          _buildDossierMetricRow([
            _buildMetricCell('INSTRUMENT', paut.instrument),
            _buildMetricCell('PROBE & WEDGE', '${paut.probeSpec}\n${paut.wedgeSpec}'),
          ]),
          const SizedBox(height: 8),
          _buildDossierMetricRow([
            _buildMetricCell('SECTORIAL SWEEP', paut.sectorialAngleRange),
            _buildMetricCell('CALIBRATION BLOCK', paut.calibrationBlockRef),
          ]),
          const SizedBox(height: 8),
          _buildDossierMetricRow([
            _buildMetricCell('ENCODER RESOLUTION',
                '${paut.encoderResolutionMm} mm (Scan Axis)'),
            _buildMetricCell('VOLUME COVERAGE',
                '${paut.volumeCoveragePercent}% of Bevel + HAZ'),
          ]),
          const SizedBox(height: 8),
          _buildDossierMetricRow([
            _buildMetricCell('MAX DAC AMPLITUDE',
                '${paut.maxAmplitudeDacPercent}% DAC (Threshold < 50%)'),
            _buildMetricCell('REPORT REF.', paut.reportNo),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_rounded,
                    color: Color(0xFF4EDEA3), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evaluated by ${paut.inspectorName} (${paut.certificationLevel}) on ${paut.inspectionDate}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Evaluation: ${paut.flawEvaluation}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: paut.status == NdtExamStatus.passed
                              ? const Color(0xFF4EDEA3)
                              : const Color(0xFFFFB95F),
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

  // --- MPT DOSSIER CARD ---
  Widget _buildMptDossierCard(MptTestingDossier mpt) {
    return _buildDossierCardContainer(
      title: '3. 100% Magnetic Particle Testing (MPT Root & Cap)',
      subtitle:
          'ASME Sec V Art. 7 & ASTM E709 • Dual Pass Surface & Sub-Surface Crack Detection',
      status: mpt.status,
      accentColor: const Color(0xFFFFB95F),
      icon: Icons.troubleshoot_rounded,
      child: Column(
        children: [
          _buildDossierMetricRow([
            _buildMetricCell('YOKE EQUIPMENT', mpt.yokeType),
            _buildMetricCell('LIFT CAPACITY',
                '${mpt.liftCapacityKg} kg Lift (ASME Min: 4.5 kg)'),
          ]),
          const SizedBox(height: 8),
          _buildDossierMetricRow([
            _buildMetricCell('TEST MEDIUM', mpt.mediumType),
            _buildMetricCell('REPORT REF.', mpt.reportNo),
          ]),
          const SizedBox(height: 10),

          // Root & Cap Pass Detail Cards
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF4EDEA3), size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'Root Pass Inspection: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        mpt.rootPassResult,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF4EDEA3),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF4EDEA3), size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'Final Cap Inspection: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        mpt.cappingPassResult,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF4EDEA3),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  // --- HARDNESS & METALLURGY CARD ---
  Widget _buildHardnessMetallurgyCard(GoldenWeldRecord record) {
    final hd = record.hardnessDossier;
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
              Row(
                children: const [
                  Icon(Icons.shield_rounded,
                      color: Color(0xFFA78BFA), size: 18),
                  SizedBox(width: 8),
                  Text(
                    '4. Hardness & Sour Service Compliance (NACE MR0175)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: const Text(
                  '≤ 248 HV10 COMPLIANT',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4EDEA3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDossierMetricRow([
            _buildMetricCell('TEST METHOD', hd.method),
            _buildMetricCell('MAX RECORDED',
                hd.maxRecordedHv10 > 0 ? '${hd.maxRecordedHv10} HV10' : 'Pending',
                highlightColor: const Color(0xFF4EDEA3)),
          ]),
          const SizedBox(height: 8),
          _buildDossierMetricRow([
            _buildMetricCell('AVERAGE WELD',
                hd.averageHv10 > 0 ? '${hd.averageHv10} HV10' : 'Pending'),
            _buildMetricCell('STANDARD LIMIT', '≤ 248 HV10 (NACE / ISO 15156)'),
          ]),
        ],
      ),
    );
  }

  // --- WPS & WELDER WPQR CARD ---
  Widget _buildWpsWelderCard(GoldenWeldRecord record) {
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
            children: const [
              Icon(Icons.assignment_ind_rounded,
                  color: Color(0xFFFFB95F), size: 18),
              SizedBox(width: 8),
              Text(
                '5. Welding Procedure (WPS) & Qualified Welders',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDossierMetricRow([
            _buildMetricCell('WPS SPECIFICATION', record.wpsNumber),
            _buildMetricCell('WELD PROCESS', record.weldProcess),
          ]),
          const SizedBox(height: 8),
          _buildDossierMetricRow([
            _buildMetricCell('QUALIFIED WELDERS',
                '${record.welderNames}\n(Stamps: ${record.welderIds})'),
            _buildMetricCell('PREHEAT & INTERPASS',
                'Preheat: ${record.preheatCelsius}°C (Min 150°C)\nInterpass: ${record.interpassCelsius}°C (Max 250°C)'),
          ]),
          const SizedBox(height: 8),
          _buildDossierMetricRow([
            _buildMetricCell('AMBIENT CONDITION', record.ambientCondition),
            _buildMetricCell('PIPE SPECIFICATION',
                '${record.pipeOdMm}mm OD × ${record.wallThicknessMm}mm WT ${record.pipeGrade}'),
          ]),
        ],
      ),
    );
  }

  Widget _buildDossierCardContainer({
    required String title,
    required String subtitle,
    required NdtExamStatus status,
    required Color accentColor,
    required IconData icon,
    required Widget child,
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
              Row(
                children: [
                  Icon(icon, color: accentColor, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: status.color),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: status.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDossierMetricRow(List<Widget> cells) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cells.map((cell) => Expanded(child: cell)).toList(),
    );
  }

  Widget _buildMetricCell(String label, String value, {Color? highlightColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: highlightColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 3: HYDROSTATIC EXEMPTION CERTIFICATE (OISD-141 & ASME B31.8)
  // ==========================================================================
  Widget _buildTabExemptionCertificate() {
    final record = currentRecord;
    final cert = record.exemptionCert;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Official Statutory Certificate Paper Document
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A34),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cert.isApproved
                  ? const Color(0xFF10B981)
                  : const Color(0xFFFFB95F),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(120),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Government / Oil India / EIL Crest Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2E5C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'GOVT. OF INDIA REGD.',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                  const Text(
                    'FORM OISD-141 / HEC-REV2',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Icon(Icons.verified_rounded,
                  color: Color(0xFFFFB95F), size: 36),
              const SizedBox(height: 8),
              const Text(
                'OIL INDIA LIMITED',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Color(0xFFFFB95F),
                ),
              ),
              const Text(
                'PIPELINE HEADQUARTERS • DULIAJAN, ASSAM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: AppTheme.border, thickness: 1.2),
              const SizedBox(height: 8),
              const Text(
                'STATUTORY HYDROSTATIC TEST EXEMPTION CERTIFICATE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF1F5F9),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Issued under OISD-141 Clause 13.4.1 & ASME B31.8 (2022) Section 841.3.2(d)',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(height: 16),

              // Certificate Identification Grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _buildCertIdRow('CERTIFICATE NO:', cert.certificateNo,
                        isBoldVal: true),
                    const Divider(color: AppTheme.border, height: 12),
                    _buildCertIdRow('JOINT IDENTIFIER:', record.id),
                    const Divider(color: AppTheme.border, height: 12),
                    _buildCertIdRow('CHAINAGE / KP:',
                        '${record.chainageDisplay} (${record.locationName})'),
                    const Divider(color: AppTheme.border, height: 12),
                    _buildCertIdRow('PIPE DETAILS:',
                        '${record.pipeSizeInches}" OD × ${record.wallThicknessMm}mm WT ${record.pipeGrade}'),
                    const Divider(color: AppTheme.border, height: 12),
                    _buildCertIdRow(
                        'WELD PROCEDURE:', '${record.wpsNumber} (${record.weldProcess})'),
                    const Divider(color: AppTheme.border, height: 12),
                    _buildCertIdRow('ISSUE DATE:', cert.issueDate),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Legal / Engineering Exemption Declaration
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0284C7).withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUTORY EXEMPTION DECLARATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF38BDF8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'It is hereby formally certified that Golden Weld Tie-in Joint ${record.id} '
                      'connecting pre-tested hydrostatic sections ${record.sectionA.sectionId} and ${record.sectionB.sectionId} '
                      'is granted STATUTORY EXEMPTION from post-weld hydrostatic pressure testing in accordance with '
                      'OISD-141 Cl. 13.4.1 and ASME B31.8 Section 841.3.2(d), having strictly satisfied 100% Non-Destructive '
                      'Examination comprising 100% Class 1 Radiographic Testing, 100% Phased Array Ultrasonic Testing with TOFD, '
                      'and 100% Magnetic Particle Inspection of both Root and Cap passes.',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Dual Pre-tested Hydrotest Section Evidence Table
              _buildPretestedSectionsTable(record),

              const SizedBox(height: 16),

              // Mandatory 7-Point Exemption Prerequisite Checklist
              _buildMandatoryChecklist(record),

              const SizedBox(height: 20),

              // Tripartite Signature Sign-off Stamp Block
              _buildCertificateSignoffStampBlock(record),

              const SizedBox(height: 16),

              // SHA-256 Tamper-Proof Cryptographic Hash Seal
              _buildCryptographicHashSeal(record),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCertIdRow(String label, String value, {bool isBoldVal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBoldVal ? FontWeight.w900 : FontWeight.w700,
              color: isBoldVal
                  ? const Color(0xFF4EDEA3)
                  : AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPretestedSectionsTable(GoldenWeldRecord record) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: const [
                Icon(Icons.compress_rounded,
                    color: Color(0xFF38BDF8), size: 14),
                SizedBox(width: 6),
                Text(
                  'ADJACENT PRE-TESTED HYDROSTATIC TEST SECTIONS',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPSTREAM: ${record.sectionA.sectionId}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFB95F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Test Pressure: ${record.sectionA.testPressureBar} Bar',
                          style: const TextStyle(
                              fontSize: 9.5, color: AppTheme.textPrimary)),
                      Text('Hold Duration: ${record.sectionA.holdDurationHours} Hours',
                          style: const TextStyle(
                              fontSize: 9.5, color: AppTheme.textMuted)),
                      Text('Chart Ref: ${record.sectionA.recorderChartNo}',
                          style: const TextStyle(
                              fontSize: 9.5, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: AppTheme.border,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DOWNSTREAM: ${record.sectionB.sectionId}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFB95F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Test Pressure: ${record.sectionB.testPressureBar} Bar',
                          style: const TextStyle(
                              fontSize: 9.5, color: AppTheme.textPrimary)),
                      Text('Hold Duration: ${record.sectionB.holdDurationHours} Hours',
                          style: const TextStyle(
                              fontSize: 9.5, color: AppTheme.textMuted)),
                      Text('Chart Ref: ${record.sectionB.recorderChartNo}',
                          style: const TextStyle(
                              fontSize: 9.5, color: AppTheme.textMuted)),
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

  Widget _buildMandatoryChecklist(GoldenWeldRecord record) {
    final items = [
      '1. Upstream and downstream pipeline sections tested hydrostatically to ≥ 1.25x / 1.5x design pressure for 24h.',
      '2. Both sections completely dewatered, swiped with foam pigs, and calibrated with electronic caliper pig (EGP).',
      '3. 100% Class 1 Radiographic Examination (DWSI) evaluated to API 1104 §9 with 0 unacceptable defects.',
      '4. 100% Phased Array Ultrasonic Testing (PAUT) with Time-of-Flight Diffraction (TOFD) verified by ASNT Level III.',
      '5. 100% Magnetic Particle Testing (MPT) of Root bead, Hot pass, and Capping bead completed with AC yoke.',
      '6. Pre-heat temperature (≥150°C) and interpass temperature (≤250°C) digitally logged with calibrated contact pyrometer.',
      '7. Hardness survey completed (Vickers HV10 ≤ 248) verifying compliance with NACE MR0175 / ISO 15156 sour service.',
    ];

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
              const Text(
                'MANDATORY STATUTORY CHECKLIST (OISD-141 / ASME B31.8)',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF38BDF8),
                ),
              ),
              Text(
                '${record.exemptionCert.checklistCompletedCount}/7 SATISFIED',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4EDEA3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            final isChecked =
                idx < record.exemptionCert.checklistCompletedCount;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isChecked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: isChecked
                        ? const Color(0xFF4EDEA3)
                        : const Color(0xFF64748B),
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isChecked
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCertificateSignoffStampBlock(GoldenWeldRecord record) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Text(
            'TRIPARTITE CERTIFICATION COMMITTEE SIGN-OFF',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFB95F),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStampCell(
                roleTitle: 'CONTRACTOR LEAD',
                org: 'Kalpataru / L&T',
                name: record.contractorSign.name,
                isSigned: record.contractorSign.isSigned,
                date: record.contractorSign.signedAt ?? 'Pending',
              ),
              const SizedBox(width: 8),
              _buildStampCell(
                roleTitle: 'TPIA INSPECTOR',
                org: 'Engineers India Ltd',
                name: record.eilTpiaSign.name,
                isSigned: record.eilTpiaSign.isSigned,
                date: record.eilTpiaSign.signedAt ?? 'Pending',
              ),
              const SizedBox(width: 8),
              _buildStampCell(
                roleTitle: 'CLIENT RESIDENT ENG',
                org: 'Oil India Limited',
                name: record.oilResidentSign.name,
                isSigned: record.oilResidentSign.isSigned,
                date: record.oilResidentSign.signedAt ?? 'Pending',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStampCell({
    required String roleTitle,
    required String org,
    required String name,
    required bool isSigned,
    required String date,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSigned
                ? const Color(0xFF10B981).withAlpha(120)
                : AppTheme.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              roleTitle,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
            ),
            Text(
              org,
              style: const TextStyle(
                fontSize: 7.5,
                color: AppTheme.textMuted,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 8),
            Container(
              height: 38,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isSigned
                    ? const Color(0xFF10B981).withAlpha(20)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSigned
                      ? const Color(0xFF10B981)
                      : AppTheme.border,
                  style: isSigned ? BorderStyle.solid : BorderStyle.none,
                ),
              ),
              child: Center(
                child: isSigned
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.verified_rounded,
                              color: Color(0xFF4EDEA3), size: 16),
                          Text(
                            'DIGITALLY SIGNED',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4EDEA3),
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Awaiting Sign-off',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              date,
              style: const TextStyle(
                fontSize: 7,
                color: AppTheme.textMuted,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCryptographicHashSeal(GoldenWeldRecord record) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1326),
        borderRadius: BorderRadius.circular(6),
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
                  Icon(Icons.lock_rounded, color: Color(0xFF38BDF8), size: 13),
                  SizedBox(width: 4),
                  Text(
                    'TAMPER-PROOF SHA-256 DOSSIER DIGEST',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: record.tamperProofSha256));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('SHA-256 hash copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  'COPY HASH',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFB95F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            record.tamperProofSha256,
            style: const TextStyle(
              fontSize: 8.5,
              fontFamily: 'monospace',
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: TRIPARTITE DIGITAL SIGN-OFF VAULT
  // ==========================================================================
  Widget _buildTabTripartiteVault() {
    final record = currentRecord;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActiveJointContextBanner(record),
        const SizedBox(height: 14),

        // Tripartite Process Description
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2E5C).withAlpha(60),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3B82F6).withAlpha(100)),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tripartite digital certification requires unanimous validation from Contractor Lead Welder, '
                  'EIL TPIA Level III Inspector, and Oil India Resident Engineer before statutory exemption takes effect.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Party 1: Contractor Lead Welder & QA/QC
        _buildPartySignCard(
          record: record,
          sig: record.contractorSign,
          role: TripartiteRole.contractorWelder,
        ),

        const SizedBox(height: 14),

        // Party 2: EIL TPIA Level III Inspector
        _buildPartySignCard(
          record: record,
          sig: record.eilTpiaSign,
          role: TripartiteRole.eilTpia,
        ),

        const SizedBox(height: 14),

        // Party 3: Oil India Resident Engineer
        _buildPartySignCard(
          record: record,
          sig: record.oilResidentSign,
          role: TripartiteRole.oilResidentEng,
        ),

        const SizedBox(height: 20),

        // Audit Trail Summary
        _buildSignoffAuditTrailCard(record),
      ],
    );
  }

  Widget _buildPartySignCard({
    required GoldenWeldRecord record,
    required PartySignature sig,
    required TripartiteRole role,
  }) {
    final isSigned = sig.isSigned;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSigned ? const Color(0xFF10B981) : AppTheme.border,
          width: isSigned ? 1.5 : 1.0,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSigned
                          ? const Color(0xFF10B981).withAlpha(40)
                          : const Color(0xFF1E2E5C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      role.icon,
                      color: isSigned
                          ? const Color(0xFF4EDEA3)
                          : const Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sig.roleTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        sig.organization,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSigned
                      ? const Color(0xFF10B981).withAlpha(30)
                      : const Color(0xFFFFB95F).withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSigned
                        ? const Color(0xFF10B981)
                        : const Color(0xFFFFB95F),
                  ),
                ),
                child: Text(
                  isSigned ? 'SIGNED & SEALED' : 'AWAITING SIGN-OFF',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isSigned
                        ? const Color(0xFF4EDEA3)
                        : const Color(0xFFFFB95F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDossierMetricRow([
            _buildMetricCell('OFFICIAL REPRESENTATIVE', sig.name),
            _buildMetricCell('CREDENTIAL / LICENSE ID', sig.licenseId),
          ]),
          const SizedBox(height: 10),

          if (isSigned) ...[
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
                      Text(
                        'Signed: ${sig.signedAt}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4EDEA3),
                        ),
                      ),
                      const Icon(Icons.security_rounded,
                          color: Color(0xFF38BDF8), size: 14),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sig Digest: ${sig.signatureHash}',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Interactive Sign Button for Pending Signatures
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.draw_rounded, size: 18),
                label: Text(
                  'AUTHENTICATE & SIGN AS ${sig.name.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                onPressed: () => _showDigitalSignaturePadModal(record, role),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignoffAuditTrailCard(GoldenWeldRecord record) {
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
            children: const [
              Icon(Icons.history_edu_rounded,
                  color: Color(0xFF38BDF8), size: 18),
              SizedBox(width: 8),
              Text(
                'Audit Trail & Immutable Chain of Custody',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildAuditStep(
            step: '1',
            title: 'Welding & Interpass Temperature Verification',
            subtitle:
                'Contact pyrometer logged 155°C preheat. Lead Welder WPQR recorded.',
            isComplete: true,
          ),
          _buildAuditStep(
            step: '2',
            title: '100% NDE Dossier Review & Film Interpretation',
            subtitle:
                'RT Class 1 film D4 verified. PAUT sectorial scan 0 defects confirmed.',
            isComplete: record.rtDossier.status == NdtExamStatus.passed &&
                record.pautDossier.status == NdtExamStatus.passed,
          ),
          _buildAuditStep(
            step: '3',
            title: 'Adjacent Hydrotest Section Clearance Cross-Reference',
            subtitle:
                'Section A (148.5 Bar) & Section B (155.0 Bar) charts linked.',
            isComplete: true,
          ),
          _buildAuditStep(
            step: '4',
            title: 'Tripartite Unanimous Execution & SHA-256 Sealing',
            subtitle: record.isFullyCertified
                ? 'All 3 parties verified and sealed into immutable block.'
                : 'Awaiting completion of remaining signatures.',
            isComplete: record.isFullyCertified,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditStep({
    required String step,
    required String title,
    required String subtitle,
    required bool isComplete,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isComplete
                    ? const Color(0xFF10B981)
                    : const Color(0xFF1E2E5C),
              ),
              child: Center(
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isComplete ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isComplete
                    ? const Color(0xFF10B981)
                    : AppTheme.border,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isComplete
                      ? AppTheme.textPrimary
                      : AppTheme.textMuted,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 5: PAUT & BEVEL CAD VISUALIZER
  // ==========================================================================
  Widget _buildTabCadUltrasonicVisualizer() {
    final record = currentRecord;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActiveJointContextBanner(record),
        const SizedBox(height: 14),

        // CAD Interactive Cross-Section Canvas
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: const Color(0xFF0B1326),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: WeldBevelUltrasonicPainter(
              probeAngleDeg: _probeAngleDeg,
              probePositionX: _probePositionSlider,
              animateSweep: true,
              sweepPhase: _sweepAnimController.value,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Interactive Ultrasound Controls
        Container(
          padding: const EdgeInsets.all(16),
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
                    'PHASED ARRAY PROBE CONTROLS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF38BDF8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Angle: ${_probeAngleDeg.toStringAsFixed(1)}° Shear Wave',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4EDEA3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Angle Slider
              Row(
                children: [
                  const Text('40°',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  Expanded(
                    child: Slider(
                      value: _probeAngleDeg,
                      min: 40.0,
                      max: 70.0,
                      divisions: 30,
                      activeColor: const Color(0xFF38BDF8),
                      inactiveColor: const Color(0xFF1E2E5C),
                      onChanged: (val) {
                        setState(() {
                          _probeAngleDeg = val;
                        });
                      },
                    ),
                  ),
                  const Text('70°',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),

              const SizedBox(height: 6),

              // Stand-off Position Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Probe Standoff Distance along Pipe Surface:',
                    style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${(20 + _probePositionSlider * 45).toStringAsFixed(1)} mm from Weld Centerline',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFB95F),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _probePositionSlider,
                min: 0.1,
                max: 0.95,
                activeColor: const Color(0xFFFFB95F),
                inactiveColor: const Color(0xFF1E2E5C),
                onChanged: (val) {
                  setState(() {
                    _probePositionSlider = val;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Live Simulated Ultrasonic A-Scan & S-Scan Chart
        _buildUltrasonicFlChart(record),

        const SizedBox(height: 14),

        // Weld Pass Layer Legend
        _buildWeldPassLayerLegend(),
      ],
    );
  }

  Widget _buildUltrasonicFlChart(GoldenWeldRecord record) {
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
            children: const [
              Text(
                'LIVE ULTRASONIC S-SCAN DAC AMPLITUDE (FLCHART)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF38BDF8),
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'REF: 100% DAC CURVE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFB95F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFF1E2E5C),
                    strokeWidth: 0.8,
                  ),
                  getDrawingVerticalLine: (value) => const FlLine(
                    color: Color(0xFF1E2E5C),
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(
                            fontSize: 8, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}mm',
                        style: const TextStyle(
                            fontSize: 8, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.border),
                ),
                minX: 0,
                maxX: 60,
                minY: 0,
                maxY: 120,
                lineBarsData: [
                  // 100% DAC Reference Threshold Curve
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 100),
                      FlSpot(15, 88),
                      FlSpot(30, 76),
                      FlSpot(45, 66),
                      FlSpot(60, 58),
                    ],
                    isCurved: true,
                    color: const Color(0xFFFF5252),
                    barWidth: 1.5,
                    dashArray: [4, 4],
                    dotData: const FlDotData(show: false),
                  ),
                  // Live Phased Array Signal Curve
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 5),
                      const FlSpot(10, 8),
                      const FlSpot(20, 14),
                      FlSpot(
                        28 + (_probePositionSlider * 8),
                        record.pautDossier.maxAmplitudeDacPercent > 0
                            ? record.pautDossier.maxAmplitudeDacPercent
                            : 18.0,
                      ),
                      const FlSpot(40, 12),
                      const FlSpot(50, 6),
                      const FlSpot(60, 4),
                    ],
                    isCurved: true,
                    color: const Color(0xFF4EDEA3),
                    barWidth: 2.2,
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF4EDEA3).withAlpha(40),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '• Green: Live Echo Amplitude (Peak 24.5% DAC)',
                style: TextStyle(fontSize: 8.5, color: Color(0xFF4EDEA3)),
              ),
              Text(
                '• Red: 100% DAC Rejection Limit',
                style: TextStyle(fontSize: 8.5, color: Color(0xFFFF5252)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeldPassLayerLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GOLDEN WELD BEVEL & PASS METALLURGY SPECIFICATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFB95F),
            ),
          ),
          const SizedBox(height: 8),
          _buildPassRow(
            color: const Color(0xFFEAB308),
            name: 'Root Pass (GTAW ER70S-6)',
            desc: 'Root gap 2.4mm ± 0.8mm • Argon backing purge 99.99%',
          ),
          const SizedBox(height: 6),
          _buildPassRow(
            color: const Color(0xFFF97316),
            name: 'Hot Pass & Filler Passes 1-4 (SMAW E8018-G)',
            desc: 'Electrode baked at 350°C • Holding oven 150°C',
          ),
          const SizedBox(height: 6),
          _buildPassRow(
            color: const Color(0xFF10B981),
            name: 'Capping Crown Pass (SMAW E8018-G Low Hydrogen)',
            desc: 'Cap height 1.6mm - 2.0mm max • 0 undercut > 0.4mm',
          ),
        ],
      ),
    );
  }

  Widget _buildPassRow({
    required Color color,
    required String name,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // MODALS & DIALOGS
  // ==========================================================================

  // --- DIGITAL SIGNATURE PAD MODAL ---
  void _showDigitalSignaturePadModal(
      GoldenWeldRecord record, TripartiteRole role) {
    final List<Offset> strokePoints = [];
    final pinController = TextEditingController();
    bool isVerifyingPin = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(role.icon,
                              color: const Color(0xFF38BDF8), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Digital Sign-Off: ${role.title}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Joint: ${record.id} (${record.chainageDisplay}) • OISD-141 Hydrostatic Exemption Dossier',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Signature Canvas
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1326),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border, width: 1.5),
                    ),
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final RenderBox box =
                            context.findRenderObject() as RenderBox;
                        final localPos = box.globalToLocal(details.globalPosition);
                        // Clamp to canvas box height
                        if (localPos.dy >= 0 && localPos.dy <= 160) {
                          setModalState(() {
                            strokePoints.add(localPos);
                          });
                        }
                      },
                      onPanEnd: (details) {
                        setModalState(() {
                          strokePoints.add(Offset.zero);
                        });
                      },
                      child: CustomPaint(
                        painter: JointSignaturePainter(points: strokePoints),
                        size: const Size(double.infinity, 160),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Draw authorized biometric signature above',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            strokePoints.clear();
                          });
                        },
                        child: const Text(
                          'CLEAR PAD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF5252),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // PIN Input
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Authorizing Digital PIN / Token',
                      hintText: 'Enter 4-digit credential pin (Default: 2026)',
                      prefixIcon: const Icon(Icons.password_rounded,
                          color: AppTheme.primaryLight, size: 20),
                      filled: true,
                      fillColor: AppTheme.surface,
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: isVerifyingPin
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified_rounded, size: 20),
                      label: Text(
                        isVerifyingPin
                          ? 'CALCULATING SHA-256...'
                          : 'AFFIX DIGITAL SIGNATURE & SEAL',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: isVerifyingPin
                          ? null
                          : () async {
                              if (strokePoints.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please draw signature on pad first'),
                                    backgroundColor: Color(0xFFFF5252),
                                  ),
                                );
                                return;
                              }

                              setModalState(() {
                                isVerifyingPin = true;
                              });

                              await Future.delayed(
                                  const Duration(milliseconds: 600));

                              if (!mounted || !ctx.mounted) return;
                              Navigator.pop(ctx);
                              _signRecord(record, role, strokePoints);
                            },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- STANDARDS REFERENCE MODAL ---
  void _showStandardsGuideModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.menu_book_rounded, color: Color(0xFF38BDF8), size: 22),
              SizedBox(width: 8),
              Text(
                'Golden Weld Technical Standards',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'OISD-141 Clause 13.4.1 (Golden Weld Exemption)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFB95F),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tie-in joints between pre-hydrotested pipeline sections can be exempted from further hydrotesting '
                  'provided they are subjected to 100% RT (Class 1) and 100% Ultrasonic Testing (PAUT) along with '
                  'magnetic particle testing (MPT) of both root and capping runs, and certified jointly by Owner and TPIA.',
                  style: TextStyle(fontSize: 10.5, color: AppTheme.textPrimary, height: 1.4),
                ),
                SizedBox(height: 12),
                Text(
                  'ASME B31.8 Section 841.3.2(d)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFB95F),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tie-in joints connecting tested piping segments are not required to be hydrostatically tested if '
                  'they are examined over their entire circumference by radiographic or other approved non-destructive '
                  'examination methods.',
                  style: TextStyle(fontSize: 10.5, color: AppTheme.textPrimary, height: 1.4),
                ),
                SizedBox(height: 12),
                Text(
                  'API 1104 §9 Acceptance Standards',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFB95F),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Zero cracks of any kind allowed. Incomplete fusion (IF) and incomplete penetration (IP) limits: strictly 0mm for golden welds. '
                  'Slag inclusion maximum cumulative length: ≤ 50mm in 300mm continuous weld length.',
                  style: TextStyle(fontSize: 10.5, color: AppTheme.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CLOSE',
                  style: TextStyle(color: AppTheme.primaryLight)),
            ),
          ],
        );
      },
    );
  }

  // --- EXPORT DOSSIER DIALOG ---
  void _showExportDossierDialog(GoldenWeldRecord record) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.file_download_rounded,
                  color: Color(0xFF4EDEA3), size: 22),
              const SizedBox(width: 8),
              Text(
                'Export Dossier: ${record.id}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tripartite Package Components for Statutory Filing:',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                _buildExportCheckbox(
                    '1. Hydrostatic Exemption Certificate (${record.exemptionCert.certificateNo})'),
                _buildExportCheckbox(
                    '2. 100% RT Class 1 Radiographic Examination Film Dossier'),
                _buildExportCheckbox(
                    '3. 100% PAUT Sectorial Scan & TOFD Ultrasonic Volumetric Package'),
                _buildExportCheckbox(
                    '4. MPT Root & Cap Wet Magnetic Particle Examination Sheet'),
                _buildExportCheckbox(
                    '5. Adjacent Sections Hydrotest 24-hr Pressure Recorder Charts'),
                _buildExportCheckbox(
                    '6. Tripartite Digital Signature Certificate & SHA-256 Seal'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Hash: ${record.tamperProofSha256}',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('GENERATE PDF & JSON'),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    content: Text(
                        'Full Tripartite Exemption Dossier for ${record.id} exported successfully!'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildExportCheckbox(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF4EDEA3), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
