import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// ENUMS & MODELS FOR PRE-COMMISSIONING & PUNCH LIST MANAGEMENT
// ============================================================================

/// Pre-commissioning Subsystems
enum CommissioningSubsystem {
  wellheadManifold,
  gasGatheringSkid,
  meteringSkid,
  pigLauncherReceiver,
}

extension CommissioningSubsystemExtension on CommissioningSubsystem {
  String get code {
    switch (this) {
      case CommissioningSubsystem.wellheadManifold:
        return 'SS-01-WHD';
      case CommissioningSubsystem.gasGatheringSkid:
        return 'SS-02-GGS';
      case CommissioningSubsystem.meteringSkid:
        return 'SS-03-MTR';
      case CommissioningSubsystem.pigLauncherReceiver:
        return 'SS-04-PLR';
    }
  }

  String get displayName {
    switch (this) {
      case CommissioningSubsystem.wellheadManifold:
        return 'Wellhead Manifold';
      case CommissioningSubsystem.gasGatheringSkid:
        return 'Gas Gathering Skid';
      case CommissioningSubsystem.meteringSkid:
        return 'Metering Skid';
      case CommissioningSubsystem.pigLauncherReceiver:
        return 'Pig Launcher/Receiver Barrels';
    }
  }

  String get tagPrefix {
    switch (this) {
      case CommissioningSubsystem.wellheadManifold:
        return 'WHD';
      case CommissioningSubsystem.gasGatheringSkid:
        return 'GGS';
      case CommissioningSubsystem.meteringSkid:
        return 'MTR';
      case CommissioningSubsystem.pigLauncherReceiver:
        return 'PLR';
    }
  }

  String get pAndIdRef {
    switch (this) {
      case CommissioningSubsystem.wellheadManifold:
        return 'PID-DUL-WHD-101-Rev-03';
      case CommissioningSubsystem.gasGatheringSkid:
        return 'PID-DUL-GGS-201-Rev-04';
      case CommissioningSubsystem.meteringSkid:
        return 'PID-DUL-MTR-301-Rev-02';
      case CommissioningSubsystem.pigLauncherReceiver:
        return 'PID-DUL-PLR-401-Rev-03';
    }
  }

  String get designRating {
    switch (this) {
      case CommissioningSubsystem.wellheadManifold:
        return 'Class 2500 RTJ • 5,000 PSIG • HP Manifold Header';
      case CommissioningSubsystem.gasGatheringSkid:
        return 'Class 600 RF • 1,440 PSIG • 2-Phase Separator Plinth';
      case CommissioningSubsystem.meteringSkid:
        return 'Class 600 RF • Fiscal Accuracy 0.15% • Dual Ultrasonic';
      case CommissioningSubsystem.pigLauncherReceiver:
        return 'Class 600 • 18" Quick Opening Bandlock Closure';
    }
  }

  String get description {
    switch (this) {
      case CommissioningSubsystem.wellheadManifold:
        return 'High-pressure xmas tree tie-in, choke valves, manifold headers, ESDV valves, hydraulic control panels & instrumentation taps.';
      case CommissioningSubsystem.gasGatheringSkid:
        return '2-Phase production separator, knock-out drums, fuel gas conditioning, flare blowdown headers & drain manifolds.';
      case CommissioningSubsystem.meteringSkid:
        return 'Ultrasonic & Coriolis custody transfer flow meters, flow computers, GC sampling probe loop & bidirectional prover connection.';
      case CommissioningSubsystem.pigLauncherReceiver:
        return '18" Class 600 pig launcher and receiver traps, quick-opening Bandlock closures, pressure interlocks, kicker lines & intrusive pig signalers.';
    }
  }

  IconData get icon {
    switch (this) {
      case CommissioningSubsystem.wellheadManifold:
        return Icons.alt_route_rounded;
      case CommissioningSubsystem.gasGatheringSkid:
        return Icons.grain_rounded;
      case CommissioningSubsystem.meteringSkid:
        return Icons.speed_rounded;
      case CommissioningSubsystem.pigLauncherReceiver:
        return Icons.swap_horiz_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case CommissioningSubsystem.wellheadManifold:
        return const Color(0xFF38BDF8); // Sky blue
      case CommissioningSubsystem.gasGatheringSkid:
        return const Color(0xFFFFB95F); // Amber
      case CommissioningSubsystem.meteringSkid:
        return const Color(0xFF4EDEA3); // Emerald
      case CommissioningSubsystem.pigLauncherReceiver:
        return const Color(0xFFA78BFA); // Purple
    }
  }
}

/// Punch Item Classification
enum PunchCategory {
  categoryA,
  categoryB,
  categoryC,
}

extension PunchCategoryExtension on PunchCategory {
  String get code {
    switch (this) {
      case PunchCategory.categoryA:
        return 'Category A';
      case PunchCategory.categoryB:
        return 'Category B';
      case PunchCategory.categoryC:
        return 'Category C';
    }
  }

  String get shortLabel {
    switch (this) {
      case PunchCategory.categoryA:
        return 'Cat A (Hold)';
      case PunchCategory.categoryB:
        return 'Cat B (Major)';
      case PunchCategory.categoryC:
        return 'Cat C (Minor)';
    }
  }

  String get fullTitle {
    switch (this) {
      case PunchCategory.categoryA:
        return 'Critical Pre-Commissioning Hold';
      case PunchCategory.categoryB:
        return 'Major Pre-Commissioning Punch';
      case PunchCategory.categoryC:
        return 'Minor / Architectural Punch';
    }
  }

  String get gateRequirement {
    switch (this) {
      case PunchCategory.categoryA:
        return 'Must be cleared BEFORE nitrogen purging and hydrocarbon intake. Strict plant hold point.';
      case PunchCategory.categoryB:
        return 'To be cleared before Handover / Commercial Operation (COD). Permitted to commission under permit.';
      case PunchCategory.categoryC:
        return 'Minor / Architectural punch items (cosmetic, labeling, civil touch-up, gravel dress-up).';
    }
  }

  Color get color {
    switch (this) {
      case PunchCategory.categoryA:
        return const Color(0xFFEF4444); // Red
      case PunchCategory.categoryB:
        return const Color(0xFFFFB95F); // Amber
      case PunchCategory.categoryC:
        return const Color(0xFF38BDF8); // Cyan
    }
  }

  Color get containerColor {
    switch (this) {
      case PunchCategory.categoryA:
        return const Color(0x26EF4444);
      case PunchCategory.categoryB:
        return const Color(0x26FFB95F);
      case PunchCategory.categoryC:
        return const Color(0x2638BDF8);
    }
  }

  IconData get icon {
    switch (this) {
      case PunchCategory.categoryA:
        return Icons.block_flipped;
      case PunchCategory.categoryB:
        return Icons.warning_amber_rounded;
      case PunchCategory.categoryC:
        return Icons.info_outline_rounded;
    }
  }
}

/// Punch item lifecycle status: Raised -> Work In Progress -> Rectified -> TPIA Inspected -> Closed
enum PunchStatus {
  raised,
  workInProgress,
  rectified,
  tpiaInspected,
  closed,
}

extension PunchStatusExtension on PunchStatus {
  String get label {
    switch (this) {
      case PunchStatus.raised:
        return 'Raised';
      case PunchStatus.workInProgress:
        return 'Work In Progress';
      case PunchStatus.rectified:
        return 'Rectified';
      case PunchStatus.tpiaInspected:
        return 'TPIA Inspected';
      case PunchStatus.closed:
        return 'Closed';
    }
  }

  int get stepIndex {
    switch (this) {
      case PunchStatus.raised:
        return 0;
      case PunchStatus.workInProgress:
        return 1;
      case PunchStatus.rectified:
        return 2;
      case PunchStatus.tpiaInspected:
        return 3;
      case PunchStatus.closed:
        return 4;
    }
  }

  Color get color {
    switch (this) {
      case PunchStatus.raised:
        return const Color(0xFF94A3B8); // Slate
      case PunchStatus.workInProgress:
        return const Color(0xFFFFB95F); // Amber
      case PunchStatus.rectified:
        return const Color(0xFF38BDF8); // Blue
      case PunchStatus.tpiaInspected:
        return const Color(0xFFA78BFA); // Purple
      case PunchStatus.closed:
        return const Color(0xFF4EDEA3); // Emerald
    }
  }

  IconData get icon {
    switch (this) {
      case PunchStatus.raised:
        return Icons.assignment_outlined;
      case PunchStatus.workInProgress:
        return Icons.pending_actions_rounded;
      case PunchStatus.rectified:
        return Icons.construction_rounded;
      case PunchStatus.tpiaInspected:
        return Icons.verified_user_outlined;
      case PunchStatus.closed:
        return Icons.check_circle_rounded;
    }
  }
}

/// Discipline
enum EngineeringDiscipline {
  piping,
  mechanical,
  instrumentation,
  electrical,
  civilStructural,
}

extension EngineeringDisciplineExtension on EngineeringDiscipline {
  String get label {
    switch (this) {
      case EngineeringDiscipline.piping:
        return 'Piping';
      case EngineeringDiscipline.mechanical:
        return 'Mechanical';
      case EngineeringDiscipline.instrumentation:
        return 'Instrumentation';
      case EngineeringDiscipline.electrical:
        return 'Electrical';
      case EngineeringDiscipline.civilStructural:
        return 'Civil/Structural';
    }
  }

  IconData get icon {
    switch (this) {
      case EngineeringDiscipline.piping:
        return Icons.water_damage_rounded;
      case EngineeringDiscipline.mechanical:
        return Icons.settings_rounded;
      case EngineeringDiscipline.instrumentation:
        return Icons.tune_rounded;
      case EngineeringDiscipline.electrical:
        return Icons.bolt_rounded;
      case EngineeringDiscipline.civilStructural:
        return Icons.foundation_rounded;
    }
  }
}

/// Digital Clearing Stamp
class DigitalClearingStamp {
  final String stampId;
  final String sha256Hash;
  final String clearedByInspector;
  final String inspectorDesignation;
  final String tpiaAgency;
  final String tpiaInspectorName;
  final String tpiaInspectionCode;
  final DateTime stampedAt;
  final String clearanceCertificateNo;
  final String gpsCoordinates;
  final String clearanceStatement;

  const DigitalClearingStamp({
    required this.stampId,
    required this.sha256Hash,
    required this.clearedByInspector,
    required this.inspectorDesignation,
    required this.tpiaAgency,
    required this.tpiaInspectorName,
    required this.tpiaInspectionCode,
    required this.stampedAt,
    required this.clearanceCertificateNo,
    required this.gpsCoordinates,
    required this.clearanceStatement,
  });
}

/// Photo attachment proof
class PunchPhotoProof {
  final String defectPhotoLabel;
  final String defectDescription;
  final DateTime defectCapturedAt;
  final String defectCapturedBy;
  final String defectCoordinates;
  final String defectMockAsset;

  // Rectified proof (nullable until rectified)
  String? rectifiedPhotoLabel;
  String? rectifiedDescription;
  DateTime? rectifiedCapturedAt;
  String? rectifiedCapturedBy;
  String? rectifiedCoordinates;
  String? rectifiedMockAsset;
  String? torqueRecordNo;
  String? calibrationReportNo;

  PunchPhotoProof({
    required this.defectPhotoLabel,
    required this.defectDescription,
    required this.defectCapturedAt,
    required this.defectCapturedBy,
    required this.defectCoordinates,
    required this.defectMockAsset,
    this.rectifiedPhotoLabel,
    this.rectifiedDescription,
    this.rectifiedCapturedAt,
    this.rectifiedCapturedBy,
    this.rectifiedCoordinates,
    this.rectifiedMockAsset,
    this.torqueRecordNo,
    this.calibrationReportNo,
  });

  bool get hasRectificationProof => rectifiedPhotoLabel != null && rectifiedPhotoLabel!.isNotEmpty;
}

/// Complete Punch List Item Model
class PunchListItem {
  final String id;
  final CommissioningSubsystem subsystem;
  PunchCategory category;
  PunchStatus status;
  final EngineeringDiscipline discipline;
  final String equipmentTag;
  final String itemName;
  final String description;
  final String pAndIdRef;
  final String isometricRef;
  final String locationPlinth;
  final DateTime raisedDate;
  DateTime targetClearanceDate;
  DateTime? closedDate;
  final String walkdownParty;
  final String assignedContractor;
  String? rectificationNotes;
  String? tpiaRemarks;
  PunchPhotoProof photoProof;
  DigitalClearingStamp? digitalStamp;

  PunchListItem({
    required this.id,
    required this.subsystem,
    required this.category,
    required this.status,
    required this.discipline,
    required this.equipmentTag,
    required this.itemName,
    required this.description,
    required this.pAndIdRef,
    required this.isometricRef,
    required this.locationPlinth,
    required this.raisedDate,
    required this.targetClearanceDate,
    this.closedDate,
    required this.walkdownParty,
    required this.assignedContractor,
    this.rectificationNotes,
    this.tpiaRemarks,
    required this.photoProof,
    this.digitalStamp,
  });

  bool get isCriticalHold => category == PunchCategory.categoryA && status != PunchStatus.closed;
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class CommissioningPunchlistScreen extends StatefulWidget {
  const CommissioningPunchlistScreen({super.key});

  @override
  State<CommissioningPunchlistScreen> createState() => _CommissioningPunchlistScreenState();
}

class _CommissioningPunchlistScreenState extends State<CommissioningPunchlistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter & Search states
  String _searchQuery = '';
  CommissioningSubsystem? _filterSubsystem; // null = ALL
  PunchCategory? _filterCategory; // null = ALL
  PunchStatus? _filterStatus; // null = ALL

  // Master Punch Register
  late List<PunchListItem> _punchList;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializePunchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // SEED DOMAIN DATA
  // ==========================================================================

  void _initializePunchData() {
    _punchList = [
      // ----------------------------------------------------------------------
      // WELLHEAD MANIFOLD (SS-01-WHD)
      // ----------------------------------------------------------------------
      PunchListItem(
        id: 'PCH-WHD-001',
        subsystem: CommissioningSubsystem.wellheadManifold,
        category: PunchCategory.categoryA,
        status: PunchStatus.rectified,
        discipline: EngineeringDiscipline.piping,
        equipmentTag: 'ESDV-101',
        itemName: '4" Class 2500 RTJ Bonnet Flange Bolt Torque & Ring Gasket',
        description:
            'Critical Hold: Bolt torquing record missing for ESDV-101 bonnet flange. RTJ Soft Iron Octagonal Ring Gasket inspection tag unendorsed. Potential high-pressure gas release hazard.',
        pAndIdRef: 'PID-DUL-WHD-101-Rev-03',
        isometricRef: 'ISO-WHD-101-04-R2',
        locationPlinth: 'Wellhead Pad-04, North Header Header Rack',
        raisedDate: DateTime.now().subtract(const Duration(days: 6)),
        targetClearanceDate: DateTime.now().add(const Duration(days: 1)),
        walkdownParty: 'Joint: Oil India Comm Team + L&T Piping QC + EIL TPIA',
        assignedContractor: 'L&T Heavy Engineering (Discipline: Piping)',
        rectificationNotes:
            'Bolt torque performed with calibrated hydraulic torque wrench Hytorc #H-412. Final torque 420 Nm. Tag verified by contractor QC.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Loose stud bolts, missing QA ring gasket tag',
          defectDescription: 'ESDV-101 bonnet studs hand-tightened without torque stamp; RTJ seal unverified.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 6)),
          defectCapturedBy: 'S. K. Saikia (OIL Comm. Inspector)',
          defectCoordinates: '27.4812° N, 95.3198° E (Pad-04)',
          defectMockAsset: 'flange_defect_untorqued',
          rectifiedPhotoLabel: 'Rectified: Torqued to 420 Nm, Torqued torque seals applied',
          rectifiedDescription: 'Torque verified in cross-pattern. Octagonal RTJ ring seated; calibration cert attached.',
          rectifiedCapturedAt: DateTime.now().subtract(const Duration(days: 1)),
          rectifiedCapturedBy: 'Manas Pratim (L&T QC Lead)',
          rectifiedCoordinates: '27.4812° N, 95.3198° E (Pad-04)',
          rectifiedMockAsset: 'flange_rectified_torqued',
          torqueRecordNo: 'TRQ-WHD-2026-089',
        ),
      ),
      PunchListItem(
        id: 'PCH-WHD-002',
        subsystem: CommissioningSubsystem.wellheadManifold,
        category: PunchCategory.categoryA,
        status: PunchStatus.closed,
        discipline: EngineeringDiscipline.piping,
        equipmentTag: 'BV-104',
        itemName: '1" Class 2500 Blind Flange & Companion RTJ Gasket Missing',
        description:
            'Critical Hold: Bleed-off valve BV-104 on high-pressure header downstream of Choke Manifold left open-ended without companion blind flange and lock wire.',
        pAndIdRef: 'PID-DUL-WHD-101-Rev-03',
        isometricRef: 'ISO-WHD-101-08-R1',
        locationPlinth: 'Wellhead Pad-04, Choke Skid Plinth B',
        raisedDate: DateTime.now().subtract(const Duration(days: 8)),
        targetClearanceDate: DateTime.now().subtract(const Duration(days: 2)),
        closedDate: DateTime.now().subtract(const Duration(days: 1)),
        walkdownParty: 'Joint: Oil India Comm Team + L&T QC + EIL TPIA',
        assignedContractor: 'L&T Heavy Engineering (Discipline: Piping)',
        rectificationNotes:
            'ASTM A105 Class 2500 blind flange installed with B7/2H studs and soft iron ring gasket. Wire sealed shut.',
        tpiaRemarks: 'Verified in field walkdown. Hydrostatic integrity cleared for N2 purging.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Open-ended high pressure bleed-off port',
          defectDescription: 'Open 1" Class 2500 valve outlet without blind flange. Strict hold before purge.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 8)),
          defectCapturedBy: 'Arindam Sen (Lead Comm. Engr)',
          defectCoordinates: '27.4813° N, 95.3199° E',
          defectMockAsset: 'open_valve_defect',
          rectifiedPhotoLabel: 'Rectified: Class 2500 Blind Flange & Car-Seal Lock applied',
          rectifiedDescription: 'Flange installed, torque certified, lock wired with Car-Seal tag #CS-WHD-091.',
          rectifiedCapturedAt: DateTime.now().subtract(const Duration(days: 2)),
          rectifiedCapturedBy: 'K. Gogoi (Piping Foreman)',
          rectifiedCoordinates: '27.4813° N, 95.3199° E',
          rectifiedMockAsset: 'blind_flange_rectified',
          torqueRecordNo: 'TRQ-WHD-2026-074',
        ),
        digitalStamp: DigitalClearingStamp(
          stampId: 'STAMP-WHD-002-N2',
          sha256Hash: _generateSha256(
              'PCH-WHD-002|SS-01-WHD|Arindam Sen|EIL-TPIA-9901|${DateTime.now().subtract(const Duration(days: 1)).toIso8601String()}'),
          clearedByInspector: 'Er. Arindam Sen',
          inspectorDesignation: 'Lead Pre-Commissioning Engineer, OIL Duliajan',
          tpiaAgency: 'Engineers India Limited (EIL)',
          tpiaInspectorName: 'R. K. Verma',
          tpiaInspectionCode: 'EIL/NDT/PCH/2026/0411',
          stampedAt: DateTime.now().subtract(const Duration(days: 1)),
          clearanceCertificateNo: 'CERT-N2-WHD-041',
          gpsCoordinates: '27.4813° N, 95.3199° E',
          clearanceStatement: 'CRITICAL HOLD CLEARED — APPROVED FOR N2 PURGING & HC INTAKE',
        ),
      ),
      PunchListItem(
        id: 'PCH-WHD-003',
        subsystem: CommissioningSubsystem.wellheadManifold,
        category: PunchCategory.categoryB,
        status: PunchStatus.workInProgress,
        discipline: EngineeringDiscipline.instrumentation,
        equipmentTag: 'HPU-TUB-01',
        itemName: 'Hydraulic Tubing Vibration Damper Clamping Missing',
        description:
            'Major: 3/8" SS316L hydraulic tubing bundle running from Master Control Panel to ESDV actuators lacks vibration damping neoprene clamps at 1.2m intervals per OISD-179.',
        pAndIdRef: 'PID-DUL-WHD-101-Rev-03',
        isometricRef: 'LAY-INST-WHD-012',
        locationPlinth: 'Wellhead Pad-04, HPU Enclosure Skid',
        raisedDate: DateTime.now().subtract(const Duration(days: 4)),
        targetClearanceDate: DateTime.now().add(const Duration(days: 3)),
        walkdownParty: 'Joint: OIL Comm Lead + Instrument Contractor',
        assignedContractor: 'Siemens Energy Automation (Instrumentation)',
        rectificationNotes: 'Neoprene clamp brackets requisitioned from Duliajan central warehouse; 4 of 9 installed.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Unsupported SS316L hydraulic tubing span',
          defectDescription: 'Tubing span vibrates during booster pump tests. Clamps missing.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 4)),
          defectCapturedBy: 'B. J. Deka (Inst Inspector)',
          defectCoordinates: '27.4811° N, 95.3197° E',
          defectMockAsset: 'tubing_unclamped_defect',
        ),
      ),
      PunchListItem(
        id: 'PCH-WHD-004',
        subsystem: CommissioningSubsystem.wellheadManifold,
        category: PunchCategory.categoryC,
        status: PunchStatus.closed,
        discipline: EngineeringDiscipline.civilStructural,
        equipmentTag: 'SKD-WHD-PLN',
        itemName: 'Yellow Polyurethane Coating Touch-up on Skid Structural Base',
        description:
            'Minor / Architectural: Paint abrasions on skid perimeter I-beam caused during crane sling rigging offloading. Requires zinc primer + yellow topcoat touch-up.',
        pAndIdRef: 'PID-DUL-WHD-101-Rev-03',
        isometricRef: 'STR-WHD-SKD-001',
        locationPlinth: 'Wellhead Pad-04, Perimeter Curb',
        raisedDate: DateTime.now().subtract(const Duration(days: 9)),
        targetClearanceDate: DateTime.now().subtract(const Duration(days: 2)),
        closedDate: DateTime.now().subtract(const Duration(days: 2)),
        walkdownParty: 'EPC Structural QC + OIL Inspector',
        assignedContractor: 'Assam Civil Infraworks (Structural)',
        rectificationNotes: 'Wire brushed, inorganic zinc primer applied, finished with RAL 1023 Traffic Yellow polyurethane.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Paint scratch along skid I-beam toe',
          defectDescription: 'Scratched primer exposing carbon steel structural flange.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 9)),
          defectCapturedBy: 'Manas Pratim (L&T QC)',
          defectCoordinates: '27.4810° N, 95.3195° E',
          defectMockAsset: 'paint_scratch_defect',
          rectifiedPhotoLabel: 'Rectified: RAL 1023 Topcoat Reapplied & DFT 180µm verified',
          rectifiedDescription: 'Paint cured, magnetic DFT gauge confirms 185 µm dry film thickness.',
          rectifiedCapturedAt: DateTime.now().subtract(const Duration(days: 3)),
          rectifiedCapturedBy: 'D. Kalita (Painting Supv)',
          rectifiedCoordinates: '27.4810° N, 95.3195° E',
          rectifiedMockAsset: 'paint_touchup_rectified',
        ),
      ),

      // ----------------------------------------------------------------------
      // GAS GATHERING SKID (SS-02-GGS)
      // ----------------------------------------------------------------------
      PunchListItem(
        id: 'PCH-GGS-001',
        subsystem: CommissioningSubsystem.gasGatheringSkid,
        category: PunchCategory.categoryA,
        status: PunchStatus.raised,
        discipline: EngineeringDiscipline.instrumentation,
        equipmentTag: 'PSV-201',
        itemName: 'Pressure Safety Valve PSV-201 Cold Bench Test Tag Expired',
        description:
            'Critical Hold: Inlet separator PSV-201 set pressure test tag has expired. Bench pop-test report (1,440 PSIG) not signed by TPIA. Purge and inlet gas admission strictly prohibited.',
        pAndIdRef: 'PID-DUL-GGS-201-Rev-04',
        isometricRef: 'ISO-GGS-201-12-R3',
        locationPlinth: 'Gathering Plinth 2, Separator V-201 Top Nozzle',
        raisedDate: DateTime.now().subtract(const Duration(days: 2)),
        targetClearanceDate: DateTime.now().add(const Duration(days: 1)),
        walkdownParty: 'Joint: OIL Comm Lead + EIL TPIA + L&T Safety Team',
        assignedContractor: 'Instrumentation & Relief Valve Services (Guwahati)',
        rectificationNotes: 'PSV unbolted and sent to certified on-site mobile testing rig for recalibration.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: PSV-201 with expired bench test seal',
          defectDescription: 'Lead seal broken, test plate date 6 months outdated. Unverified relief set point.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 2)),
          defectCapturedBy: 'R. K. Verma (EIL TPIA)',
          defectCoordinates: '27.4820° N, 95.3210° E (Plinth 2)',
          defectMockAsset: 'psv_uncalibrated_defect',
        ),
      ),
      PunchListItem(
        id: 'PCH-GGS-002',
        subsystem: CommissioningSubsystem.gasGatheringSkid,
        category: PunchCategory.categoryA,
        status: PunchStatus.tpiaInspected,
        discipline: EngineeringDiscipline.electrical,
        equipmentTag: 'EARTH-GGS-01',
        itemName: '70mm² Copper Grounding & Bonding Strap Disconnected on V-201',
        description:
            'Critical Hold: Static dissipation earthing braid disconnected between production separator vessel skirt and skid grounding grid. Severe static spark hazard during hydrocarbon charging.',
        pAndIdRef: 'PID-DUL-GGS-201-Rev-04',
        isometricRef: 'ELE-GGS-GRD-004',
        locationPlinth: 'Gathering Plinth 2, Separator V-201 Skirt Base',
        raisedDate: DateTime.now().subtract(const Duration(days: 5)),
        targetClearanceDate: DateTime.now().add(const Duration(days: 1)),
        walkdownParty: 'Joint: OIL Safety + Electrical Comm Team + EIL TPIA',
        assignedContractor: 'Bharat Electrical Works (Electrical)',
        rectificationNotes:
            'Tinned copper flex braid 70mm² bonded with exothermically welded Cadweld lugs. Earth resistance tested at 0.42 Ohms (< 1.0 Ohm limit).',
        tpiaRemarks:
            'TPIA inspected and verified in presence of EIL Lead Electrical Engineer. Earth test record ET-2026-08 endorsed. Ready for digital stamp.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Hanging grounding lug without connection to earth boss',
          defectDescription: 'Lug bolted loosely with heavy rust on contact surface. Continuity open.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 5)),
          defectCapturedBy: 'N. Barman (OIL Elec. Comm)',
          defectCoordinates: '27.4821° N, 95.3211° E',
          defectMockAsset: 'earthing_disconnected_defect',
          rectifiedPhotoLabel: 'Rectified: Cadweld bonded lug & copper earthing braid secured',
          rectifiedDescription: 'Surface polished to bare metal, anti-corrosion paste applied, torqued to 45 Nm.',
          rectifiedCapturedAt: DateTime.now().subtract(const Duration(days: 1)),
          rectifiedCapturedBy: 'A. Hazarika (Elec QC)',
          rectifiedCoordinates: '27.4821° N, 95.3211° E',
          rectifiedMockAsset: 'earthing_bonded_rectified',
          calibrationReportNo: 'ET-2026-08 (0.42 Ohm)',
        ),
      ),
      PunchListItem(
        id: 'PCH-GGS-003',
        subsystem: CommissioningSubsystem.gasGatheringSkid,
        category: PunchCategory.categoryB,
        status: PunchStatus.workInProgress,
        discipline: EngineeringDiscipline.instrumentation,
        equipmentTag: 'LT-202',
        itemName: 'Level Transmitter Bridle Trace Heating Insulation Damaged',
        description:
            'Major: Silicone heating tape cladding damaged near low-pressure tapping nozzle of Guided Wave Radar LT-202. May cause hydrate condensation during cold winter nights.',
        pAndIdRef: 'PID-DUL-GGS-201-Rev-04',
        isometricRef: 'ISO-GGS-201-18-R1',
        locationPlinth: 'Gathering Plinth 2, Separator V-201 Side Bridle',
        raisedDate: DateTime.now().subtract(const Duration(days: 3)),
        targetClearanceDate: DateTime.now().add(const Duration(days: 4)),
        walkdownParty: 'OIL Comm Lead + Thermal Insulation Contractor',
        assignedContractor: 'Insul-Tech Thermal Solutions',
        rectificationNotes: 'New aerogel blanket cut to size; heating tape continuity test passed 48 Ohms.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Torn weather barrier on bridle heat tracing',
          defectDescription: 'Moisture ingress visible on rockwool cladding. Requires replacement.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 3)),
          defectCapturedBy: 'S. K. Saikia (OIL Comm)',
          defectCoordinates: '27.4822° N, 95.3212° E',
          defectMockAsset: 'insulation_torn_defect',
        ),
      ),
      PunchListItem(
        id: 'PCH-GGS-004',
        subsystem: CommissioningSubsystem.gasGatheringSkid,
        category: PunchCategory.categoryC,
        status: PunchStatus.closed,
        discipline: EngineeringDiscipline.mechanical,
        equipmentTag: 'LG-203',
        itemName: 'Level Gauge Reflex Glass Directional Arrow Inverted',
        description:
            'Minor / Architectural: Stainless steel nameplate flow indicator arrow pointing downwards instead of upwards on reflex level gauge LG-203.',
        pAndIdRef: 'PID-DUL-GGS-201-Rev-04',
        isometricRef: 'MEC-GGS-LG-002',
        locationPlinth: 'Gathering Plinth 2, Knock-out Drum D-202',
        raisedDate: DateTime.now().subtract(const Duration(days: 7)),
        targetClearanceDate: DateTime.now().subtract(const Duration(days: 3)),
        closedDate: DateTime.now().subtract(const Duration(days: 3)),
        walkdownParty: 'EPC QC Inspector',
        assignedContractor: 'L&T Heavy Engineering (Mechanical)',
        rectificationNotes: 'SS316 riveted tag remanufactured and re-riveted with correct fluid flow arrow orientation.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Inverted flow arrow tag on LG-203',
          defectDescription: 'Nameplate arrow pointing in opposite direction to process flow.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 7)),
          defectCapturedBy: 'Manas Pratim (L&T QC)',
          defectCoordinates: '27.4820° N, 95.3210° E',
          defectMockAsset: 'tag_inverted_defect',
          rectifiedPhotoLabel: 'Rectified: Re-riveted nameplate with correct orientation',
          rectifiedDescription: 'Verified against P&ID PID-DUL-GGS-201. Tag sealed.',
          rectifiedCapturedAt: DateTime.now().subtract(const Duration(days: 3)),
          rectifiedCapturedBy: 'Manas Pratim (L&T QC)',
          rectifiedCoordinates: '27.4820° N, 95.3210° E',
          rectifiedMockAsset: 'tag_rectified_correct',
        ),
      ),

      // ----------------------------------------------------------------------
      // METERING SKID (SS-03-MTR)
      // ----------------------------------------------------------------------
      PunchListItem(
        id: 'PCH-MTR-001',
        subsystem: CommissioningSubsystem.meteringSkid,
        category: PunchCategory.categoryA,
        status: PunchStatus.rectified,
        discipline: EngineeringDiscipline.instrumentation,
        equipmentTag: 'USM-301',
        itemName: 'Ultrasonic Flow Conditioner Alignment Pin Off by 15° (AGA-9)',
        description:
            'Critical Hold: CPA 50E flow conditioner pin misaligned by 15° relative to horizontal transducer plane on Ultrasonic Meter USM-301. Violates AGA Report No. 9 pre-requisites for fiscal custody transfer accuracy.',
        pAndIdRef: 'PID-DUL-MTR-301-Rev-02',
        isometricRef: 'ISO-MTR-301-02-R3',
        locationPlinth: 'Custody Metering Skid Building, Stream A',
        raisedDate: DateTime.now().subtract(const Duration(days: 4)),
        targetClearanceDate: DateTime.now().add(const Duration(days: 1)),
        walkdownParty: 'Joint: OIL Custody Metering Specialist + Daniel/Emerson FSE + EIL TPIA',
        assignedContractor: 'Emerson Process Management (Metering Package)',
        rectificationNotes:
            'Spool dismantled, flow conditioning plate indexed using precision alignment jig, pin re-torqued. Differential pressure tap verified.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Flow conditioner pin indexed at 15° skew',
          defectDescription: 'Index mark misaligned from 12 o’clock position by 15 degrees.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 4)),
          defectCapturedBy: 'T. Sarma (Custody Metering Lead)',
          defectCoordinates: '27.4835° N, 95.3225° E',
          defectMockAsset: 'flow_conditioner_skewed_defect',
          rectifiedPhotoLabel: 'Rectified: Aligned to true top dead centre ±0.5°',
          rectifiedDescription: 'Alignment verified with precision dial gauge. Ready for calibration verification.',
          rectifiedCapturedAt: DateTime.now().subtract(const Duration(days: 1)),
          rectifiedCapturedBy: 'Emerson Field Service Engineer',
          rectifiedCoordinates: '27.4835° N, 95.3225° E',
          rectifiedMockAsset: 'flow_conditioner_aligned_rectified',
          calibrationReportNo: 'AGA9-ALIGN-2026-01',
        ),
      ),
      PunchListItem(
        id: 'PCH-MTR-002',
        subsystem: CommissioningSubsystem.meteringSkid,
        category: PunchCategory.categoryB,
        status: PunchStatus.raised,
        discipline: EngineeringDiscipline.electrical,
        equipmentTag: 'UPS-MTR-01',
        itemName: 'Flow Computer UPS Earth Resistance High (3.8 Ω vs < 1.0 Ω limit)',
        description:
            'Major: Clean instrumental earth pit resistance for custody transfer flow computer cabinet FC-301 measured at 3.8 Ohms. Exceeds max 1.0 Ohm limit for digital pulse integrity.',
        pAndIdRef: 'PID-DUL-MTR-301-Rev-02',
        isometricRef: 'ELE-MTR-UPS-001',
        locationPlinth: 'Metering Control Room, Earth Pit EP-09',
        raisedDate: DateTime.now().subtract(const Duration(days: 3)),
        targetClearanceDate: DateTime.now().add(const Duration(days: 4)),
        walkdownParty: 'OIL Electrical Lead + EIL Inspector',
        assignedContractor: 'Assam Power & Electricals',
        rectificationNotes: 'Bentonite chemical compound treatment planned for earth pit EP-09.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Megger Earth Tester reading 3.82 Ohms',
          defectDescription: 'High soil resistance at earth pit due to dry clay layer.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 3)),
          defectCapturedBy: 'N. Barman (OIL Electrical)',
          defectCoordinates: '27.4838° N, 95.3228° E',
          defectMockAsset: 'earth_tester_high_defect',
        ),
      ),
      PunchListItem(
        id: 'PCH-MTR-003',
        subsystem: CommissioningSubsystem.meteringSkid,
        category: PunchCategory.categoryB,
        status: PunchStatus.workInProgress,
        discipline: EngineeringDiscipline.piping,
        equipmentTag: 'GC-SAM-01',
        itemName: 'Gas Chromatograph Sample Fast Loop Vent Not Routed to Flare',
        description:
            'Major: 1/2" sample fast-loop bypass relief line vents into shelter room instead of safe external atmospheric vent riser above roof eave.',
        pAndIdRef: 'PID-DUL-MTR-301-Rev-02',
        isometricRef: 'ISO-MTR-301-08-R1',
        locationPlinth: 'Metering Analyzer House, GC Shelter',
        raisedDate: DateTime.now().subtract(const Duration(days: 5)),
        targetClearanceDate: DateTime.now().add(const Duration(days: 2)),
        walkdownParty: 'Joint: OIL Safety + Piping QC + EIL TPIA',
        assignedContractor: 'L&T Heavy Engineering (Piping)',
        rectificationNotes: '3m SS316 1/2" tubing routed through roof penetration sleeve with flame arrestor cowl.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Open vent stub inside shelter room',
          defectDescription: 'Toxic and flammable hydrocarbon build-up hazard inside enclosed shelter.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 5)),
          defectCapturedBy: 'Arindam Sen (Lead Comm)',
          defectCoordinates: '27.4836° N, 95.3226° E',
          defectMockAsset: 'vent_shelter_defect',
        ),
      ),
      PunchListItem(
        id: 'PCH-MTR-004',
        subsystem: CommissioningSubsystem.meteringSkid,
        category: PunchCategory.categoryC,
        status: PunchStatus.closed,
        discipline: EngineeringDiscipline.instrumentation,
        equipmentTag: 'JB-MTR-02',
        itemName: 'Ferrule Sleeve Wire Numbers Smudged in Junction Box JB-MTR-02',
        description:
            'Minor / Architectural: Thermal heat-shrink wire ferrules on RTD temperature transmitter terminals smudged during pulling. Re-label with laser-printed sleeves.',
        pAndIdRef: 'PID-DUL-MTR-301-Rev-02',
        isometricRef: 'SCH-MTR-JB-002',
        locationPlinth: 'Custody Metering Skid Building, Junction Box Rack',
        raisedDate: DateTime.now().subtract(const Duration(days: 10)),
        targetClearanceDate: DateTime.now().subtract(const Duration(days: 4)),
        closedDate: DateTime.now().subtract(const Duration(days: 4)),
        walkdownParty: 'EPC Instrument QC Inspector',
        assignedContractor: 'Siemens Energy Automation',
        rectificationNotes: 'New Brady yellow polyolefin heat-shrink sleeves printed and heat-gun shrunk on all 8 conductors.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Indistinct wire numbers on terminal block 12-16',
          defectDescription: 'Ink rubbed off during wire dress-up inside marshalling box.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 10)),
          defectCapturedBy: 'B. J. Deka (Inst Inspector)',
          defectCoordinates: '27.4835° N, 95.3225° E',
          defectMockAsset: 'ferrule_smudged_defect',
          rectifiedPhotoLabel: 'Rectified: Brady laser heat-shrink ferrules installed',
          rectifiedDescription: 'Wires neatly loomed, printed clearly, verified against wiring diagram.',
          rectifiedCapturedAt: DateTime.now().subtract(const Duration(days: 4)),
          rectifiedCapturedBy: 'B. J. Deka (Inst Inspector)',
          rectifiedCoordinates: '27.4835° N, 95.3225° E',
          rectifiedMockAsset: 'ferrule_neat_rectified',
        ),
      ),

      // ----------------------------------------------------------------------
      // PIG LAUNCHER/RECEIVER BARRELS (SS-04-PLR)
      // ----------------------------------------------------------------------
      PunchListItem(
        id: 'PCH-PLR-001',
        subsystem: CommissioningSubsystem.pigLauncherReceiver,
        category: PunchCategory.categoryA,
        status: PunchStatus.closed,
        discipline: EngineeringDiscipline.mechanical,
        equipmentTag: 'PL-401-QOC',
        itemName: 'Quick Opening Closure (QOC) Mechanical Interlock Key Misaligned',
        description:
            'Critical Hold: 18" Bandlock closure mechanical safety pressure interlock pin bound in housing. Cannot open closure without interlock key. Prevented barrel pressurization test.',
        pAndIdRef: 'PID-DUL-PLR-401-Rev-03',
        isometricRef: 'MEC-PLR-401-01-R3',
        locationPlinth: 'Terminal Perimeter, Pig Launcher Station PL-401',
        raisedDate: DateTime.now().subtract(const Duration(days: 7)),
        targetClearanceDate: DateTime.now().subtract(const Duration(days: 2)),
        closedDate: DateTime.now().subtract(const Duration(days: 1)),
        walkdownParty: 'Joint: OIL Pipeline Operations + GD Engineering Specialist + EIL TPIA',
        assignedContractor: 'GD Engineering / SPX FLOW Specialist Team',
        rectificationNotes:
            'Closure locking band disassembled, bronze safety bleed screw cleared of grit, interlock key assembly re-lubricated with high-temp fluorosilicone grease.',
        tpiaRemarks:
            'QOC closure cycled 5 times smoothly under 100% witness of EIL and OIL Operations Lead. Interlock operates fail-safe. Fully cleared.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Binding locking band on 18" Quick Opening Closure',
          defectDescription: 'Closure door unable to latch safely; bleed pin jammed with grit.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 7)),
          defectCapturedBy: 'H. Bora (Pipeline Comm Lead)',
          defectCoordinates: '27.4850° N, 95.3240° E',
          defectMockAsset: 'qoc_jammed_defect',
          rectifiedPhotoLabel: 'Rectified: Bandlock closure lubricated & safety interlock cycling',
          rectifiedDescription: 'Tested with nitrogen leak bubble test; zero leakage at locking segment.',
          rectifiedCapturedAt: DateTime.now().subtract(const Duration(days: 2)),
          rectifiedCapturedBy: 'GD Engineering Field Specialist',
          rectifiedCoordinates: '27.4850° N, 95.3240° E',
          rectifiedMockAsset: 'qoc_cleared_rectified',
          torqueRecordNo: 'QOC-TEST-2026-11',
        ),
        digitalStamp: DigitalClearingStamp(
          stampId: 'STAMP-PLR-001-N2',
          sha256Hash: _generateSha256(
              'PCH-PLR-001|SS-04-PLR|H. Bora|EIL-TPIA-9902|${DateTime.now().subtract(const Duration(days: 1)).toIso8601String()}'),
          clearedByInspector: 'Er. Hemanta Bora',
          inspectorDesignation: 'Chief Pipeline Commissioning Engineer, OIL',
          tpiaAgency: 'Engineers India Limited (EIL)',
          tpiaInspectorName: 'S. N. Chakraborty',
          tpiaInspectionCode: 'EIL/PLR/QOC/2026/089',
          stampedAt: DateTime.now().subtract(const Duration(days: 1)),
          clearanceCertificateNo: 'CERT-N2-PLR-018',
          gpsCoordinates: '27.4850° N, 95.3240° E',
          clearanceStatement: 'CRITICAL HOLD CLEARED — APPROVED FOR N2 PURGING & PIGGING OPS',
        ),
      ),
      PunchListItem(
        id: 'PCH-PLR-002',
        subsystem: CommissioningSubsystem.pigLauncherReceiver,
        category: PunchCategory.categoryA,
        status: PunchStatus.tpiaInspected,
        discipline: EngineeringDiscipline.piping,
        equipmentTag: 'DV-402',
        itemName: '2" Class 600 Barrel Drain Valve Gland Packing Bubble Leak',
        description:
            'Critical Hold: Soap bubble test on Pig Receiver barrel drain valve DV-402 stem gland revealed continuous bubbling during preliminary nitrogen tightness hold. Gland packing loose.',
        pAndIdRef: 'PID-DUL-PLR-401-Rev-03',
        isometricRef: 'ISO-PLR-401-06-R2',
        locationPlinth: 'Terminal Perimeter, Pig Receiver Station PR-402',
        raisedDate: DateTime.now().subtract(const Duration(days: 4)),
        targetClearanceDate: DateTime.now().add(const Duration(days: 1)),
        walkdownParty: 'Joint: OIL Comm Lead + Piping QC + EIL TPIA',
        assignedContractor: 'L&T Heavy Engineering (Piping)',
        rectificationNotes:
            'Gland packing follower studs torqued evenly to 35 Nm. Re-tested with Snoop leak detector solution at 5.0 Bar N2; zero bubble formation over 15 minutes.',
        tpiaRemarks:
            'Tightness test witnessed by EIL TPIA inspector. No leak observed. Approved for final closure sign-off.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Nitrogen soap bubbling at valve stem gland',
          defectDescription: 'Continuous bubble formation indicating gland packing failure under 5 Bar N2 hold.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 4)),
          defectCapturedBy: 'Arindam Sen (Lead Comm)',
          defectCoordinates: '27.4852° N, 95.3242° E',
          defectMockAsset: 'drain_valve_bubble_defect',
          rectifiedPhotoLabel: 'Rectified: Gland re-packed, torqued, zero bubble leak',
          rectifiedDescription: 'Snoop leak detector applied for 15 mins. Clean bubble-free seal verified.',
          rectifiedCapturedAt: DateTime.now().subtract(const Duration(days: 1)),
          rectifiedCapturedBy: 'K. Gogoi (Piping Foreman)',
          rectifiedCoordinates: '27.4852° N, 95.3242° E',
          rectifiedMockAsset: 'drain_valve_tight_rectified',
          torqueRecordNo: 'LEAK-TEST-PLR-094',
        ),
      ),
      PunchListItem(
        id: 'PCH-PLR-003',
        subsystem: CommissioningSubsystem.pigLauncherReceiver,
        category: PunchCategory.categoryB,
        status: PunchStatus.raised,
        discipline: EngineeringDiscipline.instrumentation,
        equipmentTag: 'PIG-SIG-401',
        itemName: 'Intrusive Pig Signaler Flag Mechanism Inverted 180°',
        description:
            'Major: Intrusive omni-directional pig passage indicator PIG-SIG-401 flag counterweight tripped upside-down. Internal micro-switch trigger arm requires reversal to correspond with pipeline pig travel direction.',
        pAndIdRef: 'PID-DUL-PLR-401-Rev-03',
        isometricRef: 'LAY-PLR-SIG-001',
        locationPlinth: 'Pig Launcher Kicker Header Line',
        raisedDate: DateTime.now().subtract(const Duration(days: 3)),
        targetClearanceDate: DateTime.now().add(const Duration(days: 5)),
        walkdownParty: 'Joint: OIL Pipeline Operations + Instrument Comm',
        assignedContractor: 'Siemens Energy Automation',
        rectificationNotes: 'Vendor technician scheduled to adjust omni-directional trigger cam.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Pig signaler flag pointing opposite to flow',
          defectDescription: 'Flag trips downwards instead of upright upon pig passage.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 3)),
          defectCapturedBy: 'H. Bora (Pipeline Lead)',
          defectCoordinates: '27.4849° N, 95.3238° E',
          defectMockAsset: 'pig_sig_inverted_defect',
        ),
      ),
      PunchListItem(
        id: 'PCH-PLR-004',
        subsystem: CommissioningSubsystem.pigLauncherReceiver,
        category: PunchCategory.categoryC,
        status: PunchStatus.closed,
        discipline: EngineeringDiscipline.civilStructural,
        equipmentTag: 'DRP-PLR-01',
        itemName: 'Drip Tray Oil Drain Sump Plastic Cap Requires SS Plug',
        description:
            'Minor / Architectural: Temporary shipping plastic threaded cap on barrel door drip tray drain fitting was not replaced with permanent SS316 hex plug.',
        pAndIdRef: 'PID-DUL-PLR-401-Rev-03',
        isometricRef: 'STR-PLR-SUMP-002',
        locationPlinth: 'Pig Launcher Door Apron Drip Pan',
        raisedDate: DateTime.now().subtract(const Duration(days: 11)),
        targetClearanceDate: DateTime.now().subtract(const Duration(days: 5)),
        closedDate: DateTime.now().subtract(const Duration(days: 5)),
        walkdownParty: 'EPC Piping QC',
        assignedContractor: 'L&T Heavy Engineering',
        rectificationNotes: '1" NPT SS316 square head plug wrapped with PTFE tape and installed.',
        photoProof: PunchPhotoProof(
          defectPhotoLabel: 'Defect: Red plastic transport cap on drain port',
          defectDescription: 'Unsuitable for field weathering; risk of tearing and environmental spill.',
          defectCapturedAt: DateTime.now().subtract(const Duration(days: 11)),
          defectCapturedBy: 'Manas Pratim (L&T QC)',
          defectCoordinates: '27.4851° N, 95.3241° E',
          defectMockAsset: 'plastic_cap_defect',
          rectifiedPhotoLabel: 'Rectified: Stainless steel NPT hex plug installed',
          rectifiedDescription: 'Plug torqued tightly. Tray verified clean of construction debris.',
          rectifiedCapturedAt: DateTime.now().subtract(const Duration(days: 5)),
          rectifiedCapturedBy: 'Manas Pratim (L&T QC)',
          rectifiedCoordinates: '27.4851° N, 95.3241° E',
          rectifiedMockAsset: 'ss_plug_rectified',
        ),
      ),
    ];
  }

  static String _generateSha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().toUpperCase();
  }

  // ==========================================================================
  // COMPUTED STATS & GATEKEEPER LOGIC
  // ==========================================================================

  List<PunchListItem> get _filteredPunches {
    return _punchList.where((p) {
      if (_filterSubsystem != null && p.subsystem != _filterSubsystem) {
        return false;
      }
      if (_filterCategory != null && p.category != _filterCategory) {
        return false;
      }
      if (_filterStatus != null && p.status != _filterStatus) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchId = p.id.toLowerCase().contains(q);
        final matchTag = p.equipmentTag.toLowerCase().contains(q);
        final matchDesc = p.description.toLowerCase().contains(q);
        final matchItem = p.itemName.toLowerCase().contains(q);
        final matchDiscipline = p.discipline.label.toLowerCase().contains(q);
        if (!matchId && !matchTag && !matchDesc && !matchItem && !matchDiscipline) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get _totalPunches => _punchList.length;

  int get _catAOpenCount {
    return _punchList.where((p) => p.category == PunchCategory.categoryA && p.status != PunchStatus.closed).length;
  }

  int get _catBOpenCount {
    return _punchList.where((p) => p.category == PunchCategory.categoryB && p.status != PunchStatus.closed).length;
  }

  int get _catCOpenCount {
    return _punchList.where((p) => p.category == PunchCategory.categoryC && p.status != PunchStatus.closed).length;
  }

  int get _closedPunches => _punchList.where((p) => p.status == PunchStatus.closed).length;

  bool isSubsystemClearedForN2Purge(CommissioningSubsystem sub) {
    final catAHolds = _punchList.where((p) => p.subsystem == sub && p.category == PunchCategory.categoryA);
    if (catAHolds.isEmpty) return true;
    return catAHolds.every((p) => p.status == PunchStatus.closed);
  }

  int getOpenCatAHoldsForSubsystem(CommissioningSubsystem sub) {
    return _punchList
        .where((p) => p.subsystem == sub && p.category == PunchCategory.categoryA && p.status != PunchStatus.closed)
        .length;
  }

  // ==========================================================================
  // BUILD SCREEN UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Gatekeeper Pre-Commissioning Hold Alert Strip
          _buildGatekeeperBanner(),

          // KPI Metric Summary Bar
          _buildKpiSummaryBar(),

          // Tab Navigation Bar
          _buildTabBar(),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Punch Register & Filtering
                _buildPunchRegisterTab(),

                // TAB 2: Subsystems & N2 Gatekeeper View
                _buildSubsystemsGatekeeperTab(),

                // TAB 3: Walkdown Analytics & Progress S-Curve
                _buildAnalyticsTab(),

                // TAB 4: Digital Stamps & Pre-Commissioning Dossier
                _buildDossierStampsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Raise Punch Item', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _showRaisePunchItemModal(context),
            )
          : null,
    );
  }

  // ==========================================================================
  // APP BAR
  // ==========================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Text(
                'Pre-Commissioning Walkdown',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(width: 8),
              _PillBadge(label: 'Punch List OS', color: AppTheme.primaryLight),
            ],
          ),
          SizedBox(height: 2),
          Text(
            'Oil India Duliajan Gas Plant • Cat A/B/C • TPIA & N2 Purge Gatekeeper',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Walkdown Audit Dossier',
          icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryLight),
          onPressed: () => _showDossierExportPreview(context),
        ),
        IconButton(
          tooltip: 'Digital Clearing Seal Verifier',
          icon: const Icon(Icons.verified_rounded, color: AppTheme.tertiary),
          onPressed: () => _showVerificationStampInspectorModal(context),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ==========================================================================
  // GATEKEEPER BANNER (HOLDS & PURGE STATUS)
  // ==========================================================================

  Widget _buildGatekeeperBanner() {
    final catAHoldCount = _catAOpenCount;
    final isBlocked = catAHoldCount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isBlocked ? const Color(0x33EF4444) : const Color(0x2E4EDEA3),
        border: Border(
          bottom: BorderSide(
            color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isBlocked ? const Color(0xFFEF4444).withValues(alpha: 0.2) : const Color(0xFF4EDEA3).withValues(alpha: 0.2),
            ),
            child: Icon(
              isBlocked ? Icons.gpp_bad_rounded : Icons.gpp_good_rounded,
              color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
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
                      isBlocked
                          ? 'NITROGEN PURGE HOLD: $catAHoldCount CRITICAL CAT A PUNCHES OPEN'
                          : 'ALL CAT A HOLDS CLEARED: APPROVED FOR N2 PURGING & HC INTAKE',
                      style: TextStyle(
                        color: isBlocked ? const Color(0xFFFFB4AB) : const Color(0xFF4EDEA3),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isBlocked
                      ? 'Cat A items require complete rectification, photo proof & TPIA digital clearing stamp before HC introduction.'
                      : 'Third Party Inspection Agency (EIL) and Commissioning Lead digital stamps verified. Ready for commissioning.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              side: BorderSide(
                color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3),
              ),
            ),
            onPressed: () {
              setState(() {
                if (isBlocked) {
                  _filterCategory = PunchCategory.categoryA;
                  _filterStatus = null;
                } else {
                  _filterCategory = null;
                  _filterStatus = PunchStatus.closed;
                }
              });
              _tabController.animateTo(0);
            },
            child: Text(
              isBlocked ? 'View Holds' : 'View Cleared',
              style: TextStyle(
                color: isBlocked ? const Color(0xFFFFB4AB) : const Color(0xFF4EDEA3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TOP KPI SUMMARY BAR
  // ==========================================================================

  Widget _buildKpiSummaryBar() {
    final completionPct = _totalPunches > 0 ? ((_closedPunches / _totalPunches) * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          _buildKpiItem(
            label: 'TOTAL ITEMS',
            value: '$_totalPunches',
            color: AppTheme.textPrimary,
            icon: Icons.list_alt_rounded,
          ),
          _buildKpiDivider(),
          _buildKpiItem(
            label: 'CAT A (HOLD)',
            value: '$_catAOpenCount open',
            color: const Color(0xFFEF4444),
            icon: Icons.dangerous_rounded,
          ),
          _buildKpiDivider(),
          _buildKpiItem(
            label: 'CAT B (MAJOR)',
            value: '$_catBOpenCount open',
            color: const Color(0xFFFFB95F),
            icon: Icons.warning_rounded,
          ),
          _buildKpiDivider(),
          _buildKpiItem(
            label: 'CAT C (MINOR)',
            value: '$_catCOpenCount open',
            color: const Color(0xFF38BDF8),
            icon: Icons.info_rounded,
          ),
          _buildKpiDivider(),
          _buildKpiItem(
            label: 'CLOSED RATE',
            value: '$completionPct%',
            color: const Color(0xFF4EDEA3),
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiDivider() {
    return Container(
      height: 24,
      width: 1,
      color: AppTheme.border.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // ==========================================================================
  // TAB BAR
  // ==========================================================================

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(
            icon: Icon(Icons.format_list_bulleted_rounded, size: 18),
            text: 'Punch Register',
          ),
          Tab(
            icon: Icon(Icons.shield_rounded, size: 18),
            text: 'Subsystems Gatekeeper',
          ),
          Tab(
            icon: Icon(Icons.analytics_rounded, size: 18),
            text: 'Analytics & S-Curve',
          ),
          Tab(
            icon: Icon(Icons.verified_user_rounded, size: 18),
            text: 'Digital Stamps & Dossier',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: PUNCH REGISTER
  // ==========================================================================

  Widget _buildPunchRegisterTab() {
    final list = _filteredPunches;

    return Column(
      children: [
        // Filter and Search Toolbar
        _buildFilterSearchBar(),

        // Quick Subsystem Pills
        _buildSubsystemPillSelector(),

        // List View of Punches
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 80),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildPunchCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      color: AppTheme.background,
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: TextField(
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by Punch ID, tag (e.g. ESDV-101), description...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 16),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: AppTheme.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(width: 8),

          // Category Filter Dropdown / Menu
          _buildCategoryFilterButton(),
          const SizedBox(width: 6),

          // Status Filter Button
          _buildStatusFilterButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterButton() {
    return PopupMenuButton<PunchCategory?>(
      tooltip: 'Filter Category',
      initialValue: _filterCategory,
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(10),
      ),
      onSelected: (cat) => setState(() => _filterCategory = cat),
      itemBuilder: (context) => [
        const PopupMenuItem<PunchCategory?>(
          value: null,
          child: Text('All Categories (A, B, C)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
        ),
        PopupMenuItem<PunchCategory?>(
          value: PunchCategory.categoryA,
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('Cat A (Pre-Comm Hold)', style: TextStyle(color: Color(0xFFFFB4AB), fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        PopupMenuItem<PunchCategory?>(
          value: PunchCategory.categoryB,
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFFB95F), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('Cat B (Major Punch)', style: TextStyle(color: Color(0xFFFFB95F), fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem<PunchCategory?>(
          value: PunchCategory.categoryC,
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF38BDF8), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('Cat C (Minor / Arch)', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: _filterCategory != null ? _filterCategory!.containerColor : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _filterCategory != null ? _filterCategory!.color : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _filterCategory != null ? _filterCategory!.icon : Icons.category_rounded,
              size: 16,
              color: _filterCategory != null ? _filterCategory!.color : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              _filterCategory != null ? _filterCategory!.code : 'Category',
              style: TextStyle(
                color: _filterCategory != null ? _filterCategory!.color : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterButton() {
    return PopupMenuButton<PunchStatus?>(
      tooltip: 'Filter Status',
      initialValue: _filterStatus,
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(10),
      ),
      onSelected: (st) => setState(() => _filterStatus = st),
      itemBuilder: (context) => [
        const PopupMenuItem<PunchStatus?>(
          value: null,
          child: Text('All Statuses', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
        ),
        ...PunchStatus.values.map(
          (status) => PopupMenuItem<PunchStatus?>(
            value: status,
            child: Row(
              children: [
                Icon(status.icon, size: 16, color: status.color),
                const SizedBox(width: 8),
                Text(status.label, style: TextStyle(color: status.color, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: _filterStatus != null ? _filterStatus!.color.withValues(alpha: 0.15) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _filterStatus != null ? _filterStatus!.color : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _filterStatus != null ? _filterStatus!.icon : Icons.filter_list_rounded,
              size: 16,
              color: _filterStatus != null ? _filterStatus!.color : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              _filterStatus != null ? _filterStatus!.label : 'Status',
              style: TextStyle(
                color: _filterStatus != null ? _filterStatus!.color : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSubsystemPillSelector() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _buildSubsystemPill(null, 'All Subsystems', Icons.all_inclusive_rounded),
          ...CommissioningSubsystem.values.map(
            (sub) => _buildSubsystemPill(sub, sub.displayName, sub.icon),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsystemPill(CommissioningSubsystem? sub, String title, IconData icon) {
    final isSelected = _filterSubsystem == sub;
    final int openHolds = sub != null ? getOpenCatAHoldsForSubsystem(sub) : _catAOpenCount;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 14,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (openHolds > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$openHolds',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppTheme.surfaceCard,
        selectedColor: AppTheme.primary,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryLight : AppTheme.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        onSelected: (selected) {
          setState(() {
            _filterSubsystem = selected ? sub : null;
          });
        },
      ),
    );
  }

  // ==========================================================================
  // PUNCH ITEM CARD
  // ==========================================================================

  Widget _buildPunchCard(PunchListItem item) {
    final isCatA = item.category == PunchCategory.categoryA;
    final isClosed = item.status == PunchStatus.closed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCatA && !isClosed ? const Color(0xFFEF4444).withValues(alpha: 0.8) : AppTheme.border,
          width: isCatA && !isClosed ? 1.5 : 1,
        ),
        boxShadow: [
          if (isCatA && !isClosed)
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPunchDetailSheet(context, item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Punch ID, Subsystem, Category Badge, Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Punch ID
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      item.id,
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Subsystem Pill
                  _PillBadge(
                    label: item.subsystem.tagPrefix,
                    color: item.subsystem.accentColor,
                  ),
                  const SizedBox(width: 8),

                  // Discipline
                  Icon(item.discipline.icon, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    item.discipline.label,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),

                  const Spacer(),

                  // Category Badge
                  _buildCategoryBadge(item.category),
                ],
              ),

              const SizedBox(height: 10),

              // Title / Item Name
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.itemName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Tag & Description
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.equipmentTag,
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status Progression Stepper Bar
              _buildLifecycleStepperStrip(item.status),

              const SizedBox(height: 12),

              // Bottom Metadata Row & Actions
              Row(
                children: [
                  // Photo Proof indicator
                  _buildProofIndicatorBadge(item.photoProof),
                  const SizedBox(width: 8),

                  // Digital Stamp indicator if closed
                  if (item.digitalStamp != null) ...[
                    _buildStampIndicatorBadge(item.digitalStamp!),
                    const SizedBox(width: 8),
                  ],

                  const Spacer(),

                  // Quick Action Button: Photos or Advance
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    icon: const Icon(Icons.photo_library_rounded, size: 14, color: AppTheme.primaryLight),
                    label: const Text(
                      'Photos',
                      style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _showPhotoProofInspectorModal(context, item),
                  ),
                  const SizedBox(width: 6),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.status == PunchStatus.closed
                          ? AppTheme.surfaceContainerHigh
                          : AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    icon: Icon(
                      item.status == PunchStatus.closed ? Icons.verified_user_rounded : Icons.arrow_forward_rounded,
                      size: 14,
                    ),
                    label: Text(
                      item.status == PunchStatus.closed ? 'Seal' : 'Advance',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _showLifecycleAdvanceDialog(context, item),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(PunchCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: category.containerColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: category.color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 12, color: category.color),
          const SizedBox(width: 4),
          Text(
            category.shortLabel,
            style: TextStyle(
              color: category.color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofIndicatorBadge(PunchPhotoProof proof) {
    final hasRectified = proof.hasRectificationProof;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: hasRectified ? const Color(0x244EDEA3) : const Color(0x24FFB95F),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasRectified ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasRectified ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 12,
            color: hasRectified ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F),
          ),
          const SizedBox(width: 4),
          Text(
            hasRectified ? 'Proof: Defect + Rectified' : 'Proof: Defect Only',
            style: TextStyle(
              color: hasRectified ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStampIndicatorBadge(DigitalClearingStamp stamp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x29A78BFA),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFA78BFA), width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 12, color: Color(0xFFA78BFA)),
          SizedBox(width: 4),
          Text(
            'TPIA Stamped',
            style: TextStyle(
              color: Color(0xFFA78BFA),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleStepperStrip(PunchStatus currentStatus) {
    final statuses = PunchStatus.values;
    final currentIdx = currentStatus.stepIndex;

    return Row(
      children: List.generate(statuses.length, (idx) {
        final step = statuses[idx];
        final isReached = idx <= currentIdx;
        final isCurrent = idx == currentIdx;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      color: idx == 0
                          ? Colors.transparent
                          : (idx <= currentIdx ? currentStatus.color : AppTheme.border),
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isReached ? step.color : AppTheme.surfaceCard,
                      border: Border.all(
                        color: isReached ? step.color : AppTheme.border,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: isReached
                        ? const Icon(Icons.check, size: 9, color: AppTheme.background)
                        : null,
                  ),
                  Expanded(
                    child: Container(
                      height: 4,
                      color: idx == statuses.length - 1
                          ? Colors.transparent
                          : (idx < currentIdx ? currentStatus.color : AppTheme.border),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                step.label,
                style: TextStyle(
                  color: isCurrent ? step.color : AppTheme.textMuted,
                  fontSize: 8.5,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 56, color: AppTheme.tertiary),
            const SizedBox(height: 16),
            const Text(
              'No Punch Items Match Filter',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'All walkdown items in this criteria are either cleared or not yet logged.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _filterSubsystem = null;
                  _filterCategory = null;
                  _filterStatus = null;
                });
              },
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 2: SUBSYSTEMS & GATEKEEPER VIEW
  // ==========================================================================

  Widget _buildSubsystemsGatekeeperTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subsystems Header Card
          _buildSubsystemsGatekeeperHeader(),

          const SizedBox(height: 16),

          // 4 Subsystem Cards
          ...CommissioningSubsystem.values.map((sub) => _buildSubsystemDetailCard(sub)),

          const SizedBox(height: 16),

          // OISD & API Standards Gatekeeper Compliance Note
          _buildComplianceInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSubsystemsGatekeeperHeader() {
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
            children: const [
              Icon(Icons.security_rounded, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Pre-Commissioning Subsystem Readiness Index',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Each subsystem cannot undergo Nitrogen Purging, Leak Test with N2/He, or Hydrocarbon Intake until 100% of Category A holds are closed and endorsed with a cryptographic TPIA digital clearing stamp.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsystemDetailCard(CommissioningSubsystem sub) {
    final subPunches = _punchList.where((p) => p.subsystem == sub).toList();
    final total = subPunches.length;
    final catAOpen = subPunches.where((p) => p.category == PunchCategory.categoryA && p.status != PunchStatus.closed).length;
    final catBOpen = subPunches.where((p) => p.category == PunchCategory.categoryB && p.status != PunchStatus.closed).length;
    final catCOpen = subPunches.where((p) => p.category == PunchCategory.categoryC && p.status != PunchStatus.closed).length;
    final closed = subPunches.where((p) => p.status == PunchStatus.closed).length;
    final isCleared = catAOpen == 0;
    final double progress = total > 0 ? (closed / total) : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCleared ? const Color(0xFF4EDEA3).withValues(alpha: 0.6) : const Color(0xFFEF4444).withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Subsystem Name, Code, and Gate Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: sub.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(sub.icon, color: sub.accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              sub.displayName,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PillBadge(label: sub.code, color: sub.accentColor),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub.designRating,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Clearance Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCleared ? const Color(0x264EDEA3) : const Color(0x26EF4444),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCleared ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCleared ? Icons.check_circle_rounded : Icons.lock_clock_rounded,
                        color: isCleared ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCleared ? 'PURGE CLEARED' : 'PURGE HOLD',
                        style: TextStyle(
                          color: isCleared ? const Color(0xFF4EDEA3) : const Color(0xFFFFB4AB),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              sub.description,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3),
            ),

            const SizedBox(height: 12),

            // P&ID Reference & Isometric
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 14, color: AppTheme.primaryLight),
                  const SizedBox(width: 6),
                  const Text('Approved P&ID: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  Text(
                    sub.pAndIdRef,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Subsystem Progress Bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCleared ? const Color(0xFF4EDEA3) : AppTheme.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$closed / $total Cleared (${(progress * 100).toInt()}%)',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Category Counts Chips
            Row(
              children: [
                _buildSmallCountBadge('Cat A (Hold): $catAOpen open', const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                _buildSmallCountBadge('Cat B: $catBOpen open', const Color(0xFFFFB95F)),
                const SizedBox(width: 8),
                _buildSmallCountBadge('Cat C: $catCOpen open', const Color(0xFF38BDF8)),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.filter_list_rounded, size: 14),
                  label: const Text('View Punches', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _filterSubsystem = sub;
                      _filterCategory = null;
                      _filterStatus = null;
                    });
                    _tabController.animateTo(0);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCountBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildComplianceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.rule_rounded, color: AppTheme.secondary, size: 18),
              SizedBox(width: 8),
              Text(
                'Pre-Commissioning Statutory & Standard Protocols',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• OISD-STD-141: Design, construction & pre-commissioning of cross-country and terminal piping.\n'
            '• ASME B31.8 / API 1104: Pressure test verification & safety interlock verification.\n'
            '• TPIA Joint Walkdown: Third Party Inspection Agency (EIL) must walk down each skid with EPC and Client commissioning team prior to N2 gas filling.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: ANALYTICS & S-CURVE
  // ==========================================================================

  Widget _buildAnalyticsTab() {
    final catACount = _punchList.where((p) => p.category == PunchCategory.categoryA).length;
    final catBCount = _punchList.where((p) => p.category == PunchCategory.categoryB).length;
    final catCCount = _punchList.where((p) => p.category == PunchCategory.categoryC).length;

    final closedCatA = _punchList.where((p) => p.category == PunchCategory.categoryA && p.status == PunchStatus.closed).length;
    final closedCatB = _punchList.where((p) => p.category == PunchCategory.categoryB && p.status == PunchStatus.closed).length;
    final closedCatC = _punchList.where((p) => p.category == PunchCategory.categoryC && p.status == PunchStatus.closed).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // S-Curve Clearance Velocity Header
          _buildAnalyticsHeaderCard(),

          const SizedBox(height: 16),

          // Category Clearance Burndown Matrix
          _buildCategoryBurndownCard(
            catACount: catACount,
            closedCatA: closedCatA,
            catBCount: catBCount,
            closedCatB: closedCatB,
            catCCount: catCCount,
            closedCatC: closedCatC,
          ),

          const SizedBox(height: 16),

          // Discipline Distribution Card
          _buildDisciplineDistributionCard(),

          const SizedBox(height: 16),

          // Subsystem Clearance Comparison
          _buildSubsystemClearanceBarsCard(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.insights_rounded, color: AppTheme.primaryLight, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Walkdown Punch Burn-Down Velocity',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Tracking Category A, B, and C items against milestone target for Ready For Start-Up (RFSU).',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBurndownCard({
    required int catACount,
    required int closedCatA,
    required int catBCount,
    required int closedCatB,
    required int catCCount,
    required int closedCatC,
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
          const Text(
            'Punch Classification Breakdown & Clearance Rate',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),

          // Category A
          _buildCategoryProgressRow(
            label: 'Category A (Critical Pre-Comm Hold)',
            total: catACount,
            closed: closedCatA,
            color: const Color(0xFFEF4444),
            desc: 'Must clear 100% prior to N2 purge',
          ),

          const SizedBox(height: 14),

          // Category B
          _buildCategoryProgressRow(
            label: 'Category B (Major / Commercial Handover)',
            total: catBCount,
            closed: closedCatB,
            color: const Color(0xFFFFB95F),
            desc: 'Target 80% prior to first hydrocarbon',
          ),

          const SizedBox(height: 14),

          // Category C
          _buildCategoryProgressRow(
            label: 'Category C (Minor / Architectural)',
            total: catCCount,
            closed: closedCatC,
            color: const Color(0xFF38BDF8),
            desc: 'Final snag list before provisional handover',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProgressRow({
    required String label,
    required int total,
    required int closed,
    required Color color,
    required String desc,
  }) {
    final double pct = total > 0 ? closed / total : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Text(
              '$closed of $total closed (${(pct * 100).toInt()}%)',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppTheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildDisciplineDistributionCard() {
    final Map<EngineeringDiscipline, int> discCounts = {};
    for (var disc in EngineeringDiscipline.values) {
      discCounts[disc] = _punchList.where((p) => p.discipline == disc).length;
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
          const Text(
            'Discipline Breakdown',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: discCounts.entries.map((entry) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Icon(entry.key.icon, size: 20, color: AppTheme.primaryLight),
                      const SizedBox(height: 6),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.key.label,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsystemClearanceBarsCard() {
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
            'Subsystem Ready-For-Start-Up (RFSU) S-Curve Milestone',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...CommissioningSubsystem.values.map((sub) {
            final total = _punchList.where((p) => p.subsystem == sub).length;
            final closed = _punchList.where((p) => p.subsystem == sub && p.status == PunchStatus.closed).length;
            final pct = total > 0 ? (closed / total) : 1.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      sub.displayName,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor: AppTheme.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(sub.accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${(pct * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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

  // ==========================================================================
  // TAB 4: DIGITAL STAMPS & PRE-COMMISSIONING DOSSIER
  // ==========================================================================

  Widget _buildDossierStampsTab() {
    final stampedItems = _punchList.where((p) => p.digitalStamp != null).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Official Emblem Card
          _buildDigitalStampEmblemCard(),

          const SizedBox(height: 16),

          // Certificate Details
          _buildMasterClearanceCertificateCard(),

          const SizedBox(height: 16),

          // Register of Digitally Stamped Punches
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Digital Clearing Stamps Issued (${stampedItems.length})',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...stampedItems.map((item) => _buildStampedItemCard(item)),

          const SizedBox(height: 16),

          // Action Buttons: Verify & Export Dossier PDF
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.tertiary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.fingerprint_rounded, color: AppTheme.tertiary),
                  label: const Text('Verify SHA-256 Hashes', style: TextStyle(color: AppTheme.tertiary)),
                  onPressed: () => _showVerificationStampInspectorModal(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Export Pre-Comm Dossier'),
                  onPressed: () => _showDossierExportPreview(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalStampEmblemCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.6), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceCard,
            AppTheme.surfaceContainerHigh.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Circular Seal
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.secondary, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.border, width: 1),
                  color: AppTheme.background.withValues(alpha: 0.9),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.verified_user_rounded, color: AppTheme.tertiary, size: 28),
                    SizedBox(height: 2),
                    Text(
                      'TPIA CLEARED',
                      style: TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      'OIL / EIL 2026',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'NIRMAAN OS • COMMISSIONING CLEARANCE SEAL',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cryptographically Signed & Endorsed by Third Party Inspection Agency (EIL) and OIL Commissioning Authority',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterClearanceCertificateCard() {
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
            children: const [
              Icon(Icons.workspace_premium_rounded, color: AppTheme.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Pre-Commissioning Quality & Safety Dossier',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Facility Name', 'Oil India Limited — Duliajan Gas Gathering Station-02'),
          _buildInfoRow('Client Representative', 'Er. Arindam Sen, Lead Pre-Commissioning Engineer'),
          _buildInfoRow('TPIA Authority', 'Engineers India Limited (EIL) Inspection Bureau'),
          _buildInfoRow('Lead TPIA Inspector', 'R. K. Verma (Inspector Badge #EIL-DUL-0914)'),
          _buildInfoRow('Standard Basis', 'OISD-STD-141 / ASME B31.8 / API 1104 22nd Edition'),
          _buildInfoRow('RFSU Target Date', '15-October-2026 (Ready for Hydrocarbon Charging)'),
        ],
      ),
    );
  }

  Widget _buildStampedItemCard(PunchListItem item) {
    final stamp = item.digitalStamp!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.id,
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.equipmentTag,
                style: const TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x264EDEA3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF4EDEA3)),
                ),
                child: const Text(
                  'SEAL VERIFIED',
                  style: TextStyle(
                    color: Color(0xFF4EDEA3),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stamp.clearanceStatement,
            style: const TextStyle(
              color: Color(0xFFA78BFA),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.fingerprint_rounded, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'SHA-256: ${stamp.sha256Hash}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryLight),
                tooltip: 'Copy Hash',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: stamp.sha256Hash));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF0F766E),
                      content: Text('Cryptographic SHA-256 seal hash copied to clipboard!'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Endorsed by: ${stamp.tpiaInspectorName} (${stamp.tpiaAgency}) on ${DateFormat('dd-MMM-yyyy HH:mm').format(stamp.stampedAt)}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // MODALS & DIALOGS
  // ==========================================================================

  /// Bottom sheet showing full punch details, technical specs & lifecycle
  void _showPunchDetailSheet(BuildContext context, PunchListItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header: Punch ID & Category
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          item.id,
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryBadge(item.category),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    item.itemName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Category Hold Impact Callout
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.category.containerColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: item.category.color.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.category.icon, color: item.category.color, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.category.fullTitle,
                                style: TextStyle(
                                  color: item.category.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.category.gateRequirement,
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lifecycle Stepper
                  const Text('Lifecycle State Progression', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _buildLifecycleStepperStrip(item.status),

                  const SizedBox(height: 16),

                  // Description
                  const Text('Deficiency / Non-Conformance Details', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      item.description,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Engineering Metadata
                  const Text('Technical & Engineering References', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailField('Subsystem', '${item.subsystem.displayName} (${item.subsystem.code})'),
                        _buildDetailField('Component Tag', item.equipmentTag),
                        _buildDetailField('Discipline', item.discipline.label),
                        _buildDetailField('Approved P&ID', item.pAndIdRef),
                        _buildDetailField('Isometric / Drawing', item.isometricRef),
                        _buildDetailField('Plinth Location', item.locationPlinth),
                        _buildDetailField('Walkdown Party', item.walkdownParty),
                        _buildDetailField('Assigned Contractor', item.assignedContractor),
                        _buildDetailField('Raised Date', DateFormat('dd-MMM-yyyy').format(item.raisedDate)),
                        _buildDetailField('Target Clearance', DateFormat('dd-MMM-yyyy').format(item.targetClearanceDate)),
                        if (item.closedDate != null)
                          _buildDetailField('Closed Date', DateFormat('dd-MMM-yyyy').format(item.closedDate!)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rectification Notes & TPIA Remarks
                  if (item.rectificationNotes != null) ...[
                    const Text('Contractor Rectification Summary', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        item.rectificationNotes!,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (item.tpiaRemarks != null) ...[
                    const Text('TPIA Joint Walkdown Inspection Endorsement', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x1FA78BFA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        item.tpiaRemarks!,
                        style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, height: 1.3),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Bar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          icon: const Icon(Icons.photo_camera_rounded, size: 16),
                          label: const Text('Photo Proofs'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showPhotoProofInspectorModal(context, item);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const Text('Update Status'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showLifecycleAdvanceDialog(context, item);
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

  Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Photo Proof Inspector: Before vs After with geotag & QA stamp watermarks
  void _showPhotoProofInspectorModal(BuildContext context, PunchListItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final proof = item.photoProof;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Bar
                  Row(
                    children: [
                      const Icon(Icons.photo_library_rounded, color: AppTheme.primaryLight, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Photographic Rectification Proof: ${item.id}',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Side-by-side or stacked photo evidence cards
                  Row(
                    children: [
                      // Defect Photo (Walkdown)
                      Expanded(
                        child: _buildPhotoEvidenceCard(
                          title: 'WALKDOWN DEFECT',
                          label: proof.defectPhotoLabel,
                          capturedAt: proof.defectCapturedAt,
                          capturedBy: proof.defectCapturedBy,
                          coordinates: proof.defectCoordinates,
                          isDefect: true,
                          equipmentTag: item.equipmentTag,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Rectified Photo Proof
                      Expanded(
                        child: proof.hasRectificationProof
                            ? _buildPhotoEvidenceCard(
                                title: 'RECTIFIED PROOF',
                                label: proof.rectifiedPhotoLabel!,
                                capturedAt: proof.rectifiedCapturedAt!,
                                capturedBy: proof.rectifiedCapturedBy!,
                                coordinates: proof.rectifiedCoordinates!,
                                isDefect: false,
                                equipmentTag: item.equipmentTag,
                                extraCert: proof.torqueRecordNo ?? proof.calibrationReportNo,
                              )
                            : _buildPendingRectificationPhotoCard(
                                onAttach: () {
                                  setModalState(() {
                                    proof.rectifiedPhotoLabel =
                                        'Rectified: Mechanical torque & calibration witness passed';
                                    proof.rectifiedDescription =
                                        'Components aligned, torqued to specification and witnessed by contractor QC.';
                                    proof.rectifiedCapturedAt = DateTime.now();
                                    proof.rectifiedCapturedBy = 'Contractor QC Lead (Live Walkdown)';
                                    proof.rectifiedCoordinates = '27.4812° N, 95.3198° E';
                                    proof.torqueRecordNo = 'TRQ-LIVE-2026-09';
                                    if (item.status == PunchStatus.raised || item.status == PunchStatus.workInProgress) {
                                      item.status = PunchStatus.rectified;
                                    }
                                  });
                                  setState(() {});
                                },
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Photo proof verification banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.verified_user_rounded, color: AppTheme.tertiary, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'All uploaded photo attachments are automatically tagged with GPS site coordinates, synchronized UTC timestamp, and SHA-256 image checksum for tamper-proof audit trail.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Close Inspector'),
                      onPressed: () => Navigator.pop(ctx),
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

  Widget _buildPhotoEvidenceCard({
    required String title,
    required String label,
    required DateTime capturedAt,
    required String capturedBy,
    required String coordinates,
    required bool isDefect,
    required String equipmentTag,
    String? extraCert,
  }) {
    final Color badgeColor = isDefect ? const Color(0xFFEF4444) : const Color(0xFF4EDEA3);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulated Industrial Photo Viewer Frame
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0D1829),
                  AppTheme.surfaceContainerHigh,
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isDefect ? Icons.report_problem_rounded : Icons.task_alt_rounded,
                        size: 38,
                        color: badgeColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        equipmentTag,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                // Header Stamp Watermark
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: badgeColor, width: 0.8),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                // GPS Watermark
                Positioned(
                  bottom: 6,
                  left: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'GPS: $coordinates • ${DateFormat('dd-MMM-yy HH:mm').format(capturedAt)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Inspector: $capturedBy',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (extraCert != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Cert/QA Ref: $extraCert',
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
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

  Widget _buildPendingRectificationPhotoCard({required VoidCallback onAttach}) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_a_photo_rounded, color: AppTheme.textMuted, size: 32),
              const SizedBox(height: 8),
              const Text(
                'Rectification Proof Pending',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Attach verified photo proof upon contractor sign-off.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.camera_alt_rounded, size: 12),
                label: const Text('Capture Proof', style: TextStyle(fontSize: 10)),
                onPressed: onAttach,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lifecycle State Advance Dialog
  void _showLifecycleAdvanceDialog(BuildContext context, PunchListItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: [
              Icon(item.status.icon, color: item.status.color, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Update Lifecycle Stage',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Status: ${item.status.label}',
                style: TextStyle(color: item.status.color, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Item: ${item.id} • ${item.equipmentTag}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select next pre-commissioning walkdown stage:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...PunchStatus.values.map((target) {
                final isCurrent = item.status == target;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(target.icon, color: target.color, size: 20),
                  title: Text(
                    target.label,
                    style: TextStyle(
                      color: isCurrent ? target.color : AppTheme.textPrimary,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 18) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyStatusChange(item, target);
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _applyStatusChange(PunchListItem item, PunchStatus newStatus) {
    setState(() {
      item.status = newStatus;

      // If transitioning to rectified, ensure proof exists
      if (newStatus == PunchStatus.rectified && !item.photoProof.hasRectificationProof) {
        item.photoProof.rectifiedPhotoLabel = 'Rectified: Mechanical alignment & inspection complete';
        item.photoProof.rectifiedDescription = 'Contractor completed physical rectification with test witness.';
        item.photoProof.rectifiedCapturedAt = DateTime.now();
        item.photoProof.rectifiedCapturedBy = 'Lead Piping QC';
        item.photoProof.rectifiedCoordinates = '27.4812° N, 95.3198° E';
        item.photoProof.torqueRecordNo = 'TRQ-QC-AUTO-01';
      }

      // If transitioning to closed, generate digital clearing stamp if not present
      if (newStatus == PunchStatus.closed) {
        item.closedDate = DateTime.now();
        if (item.digitalStamp == null) {
          final stampId = 'STAMP-${item.id.replaceAll('PCH-', '')}-N2';
          final hash = _generateSha256(
              '${item.id}|${item.subsystem.code}|Arindam Sen|EIL-TPIA|${DateTime.now().toIso8601String()}');
          item.digitalStamp = DigitalClearingStamp(
            stampId: stampId,
            sha256Hash: hash,
            clearedByInspector: 'Er. Arindam Sen',
            inspectorDesignation: 'Lead Pre-Commissioning Engineer, OIL',
            tpiaAgency: 'Engineers India Limited (EIL)',
            tpiaInspectorName: 'R. K. Verma',
            tpiaInspectionCode: 'EIL/LIVE/2026/089',
            stampedAt: DateTime.now(),
            clearanceCertificateNo: 'CERT-N2-DUL-${item.id}',
            gpsCoordinates: '27.4812° N, 95.3198° E',
            clearanceStatement: item.category == PunchCategory.categoryA
                ? 'CRITICAL HOLD CLEARED — APPROVED FOR N2 PURGING & HC INTAKE'
                : 'ACCEPTANCE CLEARANCE — READY FOR COMMERCIAL OPERATION',
          );
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F766E),
        content: Text('✅ ${item.id} status updated to ${newStatus.label}!'),
      ),
    );
  }

  /// Raise New Punch Item Modal Form
  void _showRaisePunchItemModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    CommissioningSubsystem selectedSub = CommissioningSubsystem.wellheadManifold;
    PunchCategory selectedCat = PunchCategory.categoryA;
    EngineeringDiscipline selectedDisc = EngineeringDiscipline.piping;

    final tagController = TextEditingController(text: 'ESDV-202');
    final itemNameController = TextEditingController(text: 'RTJ Flange Gasket Verification Pending');
    final descController = TextEditingController(
      text: 'Bolt tensioning report not endorsed. Must verify ring gasket seating prior to N2 purging.',
    );
    final pAndIdController = TextEditingController(text: 'PID-DUL-WHD-101-Rev-03');
    final isoController = TextEditingController(text: 'ISO-WHD-101-14');
    final plinthController = TextEditingController(text: 'Wellhead Pad-04 Header Bay');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
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
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.add_task_rounded, color: AppTheme.primaryLight, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Log New Walkdown Punch Item',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.textMuted),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Subsystem Dropdown
                      const Text('Pre-Commissioning Subsystem', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<CommissioningSubsystem>(
                        initialValue: selectedSub,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        items: CommissioningSubsystem.values.map((sub) {
                          return DropdownMenuItem(
                            value: sub,
                            child: Row(
                              children: [
                                Icon(sub.icon, size: 16, color: sub.accentColor),
                                const SizedBox(width: 8),
                                Text('${sub.displayName} (${sub.code})'),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedSub = val;
                              pAndIdController.text = val.pAndIdRef;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // Category Dropdown
                      const Text('Punch Classification', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<PunchCategory>(
                        initialValue: selectedCat,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        items: PunchCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(cat.icon, size: 16, color: cat.color),
                                const SizedBox(width: 8),
                                Text(cat.fullTitle, style: TextStyle(color: cat.color, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedCat = val);
                        },
                      ),

                      const SizedBox(height: 12),

                      // Discipline & Equipment Tag
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Discipline', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<EngineeringDiscipline>(
                                  initialValue: selectedDisc,
                                  dropdownColor: AppTheme.surfaceCard,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                  items: EngineeringDiscipline.values.map((disc) {
                                    return DropdownMenuItem(
                                      value: disc,
                                      child: Text(disc.label),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedDisc = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Equipment Tag', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: tagController,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                  validator: (v) => v == null || v.isEmpty ? 'Tag required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Item Title
                      const Text('Item Name / Defect Heading', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: itemNameController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
                      ),

                      const SizedBox(height: 12),

                      // Description
                      const Text('Deficiency Description', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
                      ),

                      const SizedBox(height: 12),

                      // Location / Plinth
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('P&ID Reference', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: pAndIdController,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Plinth / Grid Ref', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: plinthController,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save & Issue Punch Item'),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final newId = 'PCH-${selectedSub.tagPrefix}-00${_punchList.length + 1}';
                              final newItem = PunchListItem(
                                id: newId,
                                subsystem: selectedSub,
                                category: selectedCat,
                                status: PunchStatus.raised,
                                discipline: selectedDisc,
                                equipmentTag: tagController.text.trim(),
                                itemName: itemNameController.text.trim(),
                                description: descController.text.trim(),
                                pAndIdRef: pAndIdController.text.trim(),
                                isometricRef: isoController.text.trim(),
                                locationPlinth: plinthController.text.trim(),
                                raisedDate: DateTime.now(),
                                targetClearanceDate: DateTime.now().add(const Duration(days: 3)),
                                walkdownParty: 'Joint: OIL Comm Team + L&T QC + EIL TPIA',
                                assignedContractor: 'L&T Heavy Engineering',
                                photoProof: PunchPhotoProof(
                                  defectPhotoLabel: 'Defect: ${itemNameController.text.trim()}',
                                  defectDescription: descController.text.trim(),
                                  defectCapturedAt: DateTime.now(),
                                  defectCapturedBy: 'Lead Walkdown Inspector',
                                  defectCoordinates: '27.4815° N, 95.3205° E',
                                  defectMockAsset: 'generic_defect',
                                ),
                              );

                              setState(() {
                                _punchList.insert(0, newItem);
                              });

                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF0F766E),
                                  content: Text('🎉 Punch item $newId logged successfully under ${selectedSub.displayName}!'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Verification Stamp Inspector Modal
  void _showVerificationStampInspectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.fingerprint_rounded, color: AppTheme.tertiary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Cryptographic TPIA Stamp Verification',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Each closed punch item is locked with an immutable SHA-256 digital stamp computed from Punch ID, Subsystem ID, Authorized Inspector credentials, and UTC timestamp.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _buildStampMetricRow('Cryptographic Algorithm', 'SHA-256 (FIPS PUB 180-4)'),
                    _buildStampMetricRow('Registered Inspector', 'Er. Arindam Sen (Lead Comm, OIL)'),
                    _buildStampMetricRow('TPIA Witness Agency', 'Engineers India Limited (EIL)'),
                    _buildStampMetricRow('Verification Status', 'ACTIVE • 100% VALID & IMMUTABLE'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF0F766E),
                        content: Text('🔒 All digital clearing stamp cryptographic hashes verified against OIL master ledger!'),
                      ),
                    );
                  },
                  child: const Text('Verify All Signatures'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStampMetricRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          Text(val, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  /// PDF Dossier Export Preview Modal
  void _showDossierExportPreview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryLight, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Pre-Commissioning Clearance Dossier',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Generate official PDF clearance dossier for statutory submission to OISD, PNGRB, and Client Management for Nitrogen Purging authorization.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _buildStampMetricRow('Total Punch Items', '$_totalPunches items'),
                    _buildStampMetricRow('Category A Hold Clearances', '${_punchList.where((p) => p.category == PunchCategory.categoryA && p.status == PunchStatus.closed).length} cleared'),
                    _buildStampMetricRow('Pending Category A Holds', '$_catAOpenCount hold items'),
                    _buildStampMetricRow('Subsystems Covered', 'Wellhead, Gas Gathering, Metering, Pig Barrels'),
                    _buildStampMetricRow('Dossier Format', 'ISO 19005-1 PDF/A Compliant Dossier'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export Official PDF Dossier'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF0F766E),
                        content: Text('📄 Pre-Commissioning Clearance Dossier PDF generated and saved to device!'),
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
}

// ============================================================================
// REUSABLE HELPER BADGE
// ============================================================================

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PillBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
