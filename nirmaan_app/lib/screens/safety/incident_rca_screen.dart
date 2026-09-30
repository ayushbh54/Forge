import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// ENUMS & DATA MODELS FOR OISD-GDN-107 & DGMS INCIDENT INVESTIGATION & RCA
// ============================================================================

/// Statutory Incident Classification per OISD-GDN-107 & DGMS Regulations
enum IncidentClassification {
  nearMiss(
    label: 'Near Miss',
    code: 'NM',
    description: 'Unsafe condition or event halted prior to injury or asset damage',
    color: Color(0xFF38BDF8),
    icon: Icons.near_me_disabled_rounded,
    dgmsMandatoryNotice: false,
  ),
  firstAid(
    label: 'First Aid (FAC)',
    code: 'FAC',
    description: 'Minor wound, burn, or scratch treated on site without lost shift',
    color: Color(0xFF10B981),
    icon: Icons.medical_services_rounded,
    dgmsMandatoryNotice: false,
  ),
  medicalTreatment(
    label: 'Medical Treatment (MTC)',
    code: 'MTC',
    description: 'Physician attention, suturing, or splinting with no lost workdays',
    color: Color(0xFFFFB95F),
    icon: Icons.local_hospital_rounded,
    dgmsMandatoryNotice: false,
  ),
  lostTimeIncident(
    label: 'Lost Time Incident (LTI)',
    code: 'LTI',
    description: 'Statutory reportable injury resulting in lost workdays beyond shift',
    color: Color(0xFFEF4444),
    icon: Icons.personal_injury_rounded,
    dgmsMandatoryNotice: true,
  ),
  highPotential(
    label: 'High Potential (HiPo)',
    code: 'HiPo',
    description: 'Incident with realistic potential for fatality or catastrophic damage',
    color: Color(0xFFF97316),
    icon: Icons.warning_amber_rounded,
    dgmsMandatoryNotice: true,
  );

  final String label;
  final String code;
  final String description;
  final Color color;
  final IconData icon;
  final bool dgmsMandatoryNotice;

  const IncidentClassification({
    required this.label,
    required this.code,
    required this.description,
    required this.color,
    required this.icon,
    required this.dgmsMandatoryNotice,
  });
}

/// Incident Severity Level per OISD Standard
enum SeverityRating {
  catastrophic('Level 5 - Catastrophic', Color(0xFFEF4444)),
  major('Level 4 - Major', Color(0xFFF97316)),
  moderate('Level 3 - Moderate', Color(0xFFFFB95F)),
  minor('Level 2 - Minor', Color(0xFF38BDF8)),
  negligible('Level 1 - Low', Color(0xFF10B981));

  final String label;
  final Color color;
  const SeverityRating(this.label, this.color);
}

/// Investigation Workflow State
enum InvestigationStage {
  reported('Preliminary Log', Color(0xFF94A3B8), Icons.assignment_late_rounded),
  evidenceGathering('Evidence Gathering', Color(0xFF38BDF8), Icons.biotech_rounded),
  rcaAnalysis('RCA in Progress', Color(0xFFFFB95F), Icons.account_tree_rounded),
  capaExecution('CAPA Implementation', Color(0xFFF97316), Icons.pending_actions_rounded),
  statutoryClosed('Statutory Closed', Color(0xFF10B981), Icons.verified_rounded);

  final String label;
  final Color color;
  final IconData icon;
  const InvestigationStage(this.label, this.color, this.icon);
}

/// DGMS 24-Hour Statutory Notice Status
enum DgmsNoticeStatus {
  complied('Form IV-A Filed', Color(0xFF10B981), Icons.check_circle_rounded),
  pending24h('24-Hr Notice Due', Color(0xFFF97316), Icons.alarm_rounded),
  overdue('Notice Overdue', Color(0xFFEF4444), Icons.error_rounded),
  exempt('Statutory Exempt', Color(0xFF64748B), Icons.remove_circle_outline_rounded);

  final String label;
  final Color color;
  final IconData icon;
  const DgmsNoticeStatus(this.label, this.color, this.icon);
}

/// 6M Fishbone / Ishikawa Diagram Categories
enum IshikawaCategory {
  man(
    title: 'Man (Personnel)',
    subtitle: 'Competency, fatigue, training, supervision, contractor oversight',
    color: Color(0xFF38BDF8),
    icon: Icons.people_alt_rounded,
  ),
  machine(
    title: 'Machine (Equipment)',
    subtitle: 'Mechanical integrity, relief valves, interlocks, wear, telemetry',
    color: Color(0xFFFFB95F),
    icon: Icons.precision_manufacturing_rounded,
  ),
  method(
    title: 'Method (Procedures)',
    subtitle: 'PTW protocols, JSA hazards, SIMOPS, SOP deviations, LOTO',
    color: Color(0xFF10B981),
    icon: Icons.rule_folder_rounded,
  ),
  material(
    title: 'Material (Metallurgy)',
    subtitle: 'Pipe grade, metallurgy, gaskets, corrosion pitting, consumables',
    color: Color(0xFFA855F7),
    icon: Icons.layers_rounded,
  ),
  measurement(
    title: 'Measurement (QA/QC)',
    subtitle: 'Pressure gauge calibration, hydro recorders, ultrasonic QA, tolerance',
    color: Color(0xFF06B6D4),
    icon: Icons.speed_rounded,
  ),
  milieu(
    title: 'Milieu (Environment)',
    subtitle: 'Monsoon flooding, ambient heat, terrain subsidence, night visibility',
    color: Color(0xFFEC4899),
    icon: Icons.wb_sunny_rounded,
  );

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  const IshikawaCategory({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

/// Hierarchy of Controls per ISO 45001 / OISD
enum HierarchyOfControl {
  elimination('1. Elimination', 'Physically remove hazard', Color(0xFF10B981)),
  substitution('2. Substitution', 'Replace hazard with safer alternative', Color(0xFF06B6D4)),
  engineering('3. Engineering Controls', 'Isolate personnel from hazard', Color(0xFF38BDF8)),
  administrative('4. Administrative Controls', 'Alter standard operating procedures', Color(0xFFFFB95F)),
  ppe('5. PPE Enforcement', 'Protect worker with specialized gear', Color(0xFFEF4444));

  final String label;
  final String description;
  final Color color;
  const HierarchyOfControl(this.label, this.description, this.color);
}

/// CAPA Action Item Status
enum CapaStatus {
  open('Open', Color(0xFFEF4444), Icons.radio_button_unchecked_rounded),
  inProgress('In Progress', Color(0xFFFFB95F), Icons.timelapse_rounded),
  closed('Closed', Color(0xFF10B981), Icons.check_circle_rounded),
  overdue('Overdue', Color(0xFFDC2626), Icons.warning_rounded);

  final String label;
  final Color color;
  final IconData icon;
  const CapaStatus(this.label, this.color, this.icon);
}

/// Forensic Evidence Vault Classification
enum EvidenceCategory {
  photo('Geotagged Photo', Icons.photo_camera_rounded, Color(0xFF38BDF8)),
  witness('Witness Statement', Icons.record_voice_over_rounded, Color(0xFFFFB95F)),
  metallurgy('Metallurgical Lab Report', Icons.science_rounded, Color(0xFFA855F7)),
  telemetry('SCADA / Chart Log', Icons.query_stats_rounded, Color(0xFF10B981));

  final String label;
  final IconData icon;
  final Color color;
  const EvidenceCategory(this.label, this.icon, this.color);
}

// ============================================================================
// DATA MODELS
// ============================================================================

class FiveWhysStep {
  final int step;
  final String question;
  final String response;
  final String categoryTag; // Direct Cause, Sub-Cause, Barrier Failure, Systemic, Root Cause
  final bool isRootCause;

  const FiveWhysStep({
    required this.step,
    required this.question,
    required this.response,
    required this.categoryTag,
    this.isRootCause = false,
  });

  FiveWhysStep copyWith({
    int? step,
    String? question,
    String? response,
    String? categoryTag,
    bool? isRootCause,
  }) {
    return FiveWhysStep(
      step: step ?? this.step,
      question: question ?? this.question,
      response: response ?? this.response,
      categoryTag: categoryTag ?? this.categoryTag,
      isRootCause: isRootCause ?? this.isRootCause,
    );
  }
}

class FishboneFactor {
  final String id;
  final IshikawaCategory category;
  final String title;
  final String description;
  final bool isPrimaryRootCause;
  final int severityScore; // 1 to 5

  const FishboneFactor({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.isPrimaryRootCause = false,
    this.severityScore = 3,
  });
}

class CapaItem {
  final String id;
  final String incidentId;
  final String title;
  final String description;
  final bool isPreventive; // true = Preventive Action, false = Corrective Action
  final HierarchyOfControl hierarchy;
  final String ownerName;
  final String ownerRole;
  final DateTime targetDate;
  final CapaStatus status;
  final String? completionNotes;

  const CapaItem({
    required this.id,
    required this.incidentId,
    required this.title,
    required this.description,
    required this.isPreventive,
    required this.hierarchy,
    required this.ownerName,
    required this.ownerRole,
    required this.targetDate,
    required this.status,
    this.completionNotes,
  });

  CapaItem copyWith({
    String? id,
    String? incidentId,
    String? title,
    String? description,
    bool? isPreventive,
    HierarchyOfControl? hierarchy,
    String? ownerName,
    String? ownerRole,
    DateTime? targetDate,
    CapaStatus? status,
    String? completionNotes,
  }) {
    return CapaItem(
      id: id ?? this.id,
      incidentId: incidentId ?? this.incidentId,
      title: title ?? this.title,
      description: description ?? this.description,
      isPreventive: isPreventive ?? this.isPreventive,
      hierarchy: hierarchy ?? this.hierarchy,
      ownerName: ownerName ?? this.ownerName,
      ownerRole: ownerRole ?? this.ownerRole,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      completionNotes: completionNotes ?? this.completionNotes,
    );
  }
}

class EvidenceRecord {
  final String id;
  final String incidentId;
  final EvidenceCategory category;
  final String title;
  final DateTime capturedAt;
  final String chainageLocation;
  final String capturedBy;
  final String sha256Hash;
  final String tamperSealTag;
  final String summary;
  final Map<String, String> technicalMetadata;

  const EvidenceRecord({
    required this.id,
    required this.incidentId,
    required this.category,
    required this.title,
    required this.capturedAt,
    required this.chainageLocation,
    required this.capturedBy,
    required this.sha256Hash,
    required this.tamperSealTag,
    required this.summary,
    required this.technicalMetadata,
  });
}

class IncidentDossier {
  final String id;
  final String title;
  final DateTime incidentTime;
  final String chainageLocation;
  final String plantSection;
  final IncidentClassification classification;
  final SeverityRating severity;
  final InvestigationStage stage;
  final DgmsNoticeStatus dgmsStatus;
  final String? dgmsAckNumber;
  final DateTime dgmsNoticeDeadline;
  final String leadInvestigator;
  final List<String> investigationTeam;
  final String initialSummary;
  final List<FiveWhysStep> fiveWhys;
  final List<FishboneFactor> fishboneFactors;
  final List<CapaItem> capaItems;
  final List<EvidenceRecord> evidenceVault;

  const IncidentDossier({
    required this.id,
    required this.title,
    required this.incidentTime,
    required this.chainageLocation,
    required this.plantSection,
    required this.classification,
    required this.severity,
    required this.stage,
    required this.dgmsStatus,
    this.dgmsAckNumber,
    required this.dgmsNoticeDeadline,
    required this.leadInvestigator,
    required this.investigationTeam,
    required this.initialSummary,
    required this.fiveWhys,
    required this.fishboneFactors,
    required this.capaItems,
    required this.evidenceVault,
  });

  IncidentDossier copyWith({
    String? id,
    String? title,
    DateTime? incidentTime,
    String? chainageLocation,
    String? plantSection,
    IncidentClassification? classification,
    SeverityRating? severity,
    InvestigationStage? stage,
    DgmsNoticeStatus? dgmsStatus,
    String? dgmsAckNumber,
    DateTime? dgmsNoticeDeadline,
    String? leadInvestigator,
    List<String>? investigationTeam,
    String? initialSummary,
    List<FiveWhysStep>? fiveWhys,
    List<FishboneFactor>? fishboneFactors,
    List<CapaItem>? capaItems,
    List<EvidenceRecord>? evidenceVault,
  }) {
    return IncidentDossier(
      id: id ?? this.id,
      title: title ?? this.title,
      incidentTime: incidentTime ?? this.incidentTime,
      chainageLocation: chainageLocation ?? this.chainageLocation,
      plantSection: plantSection ?? this.plantSection,
      classification: classification ?? this.classification,
      severity: severity ?? this.severity,
      stage: stage ?? this.stage,
      dgmsStatus: dgmsStatus ?? this.dgmsStatus,
      dgmsAckNumber: dgmsAckNumber ?? this.dgmsAckNumber,
      dgmsNoticeDeadline: dgmsNoticeDeadline ?? this.dgmsNoticeDeadline,
      leadInvestigator: leadInvestigator ?? this.leadInvestigator,
      investigationTeam: investigationTeam ?? this.investigationTeam,
      initialSummary: initialSummary ?? this.initialSummary,
      fiveWhys: fiveWhys ?? this.fiveWhys,
      fishboneFactors: fishboneFactors ?? this.fishboneFactors,
      capaItems: capaItems ?? this.capaItems,
      evidenceVault: evidenceVault ?? this.evidenceVault,
    );
  }
}

// ============================================================================
// MAIN INCIDENT INVESTIGATION & ROOT CAUSE ANALYSIS (RCA) SCREEN
// ============================================================================

class IncidentRcaScreen extends StatefulWidget {
  const IncidentRcaScreen({super.key});

  @override
  State<IncidentRcaScreen> createState() => _IncidentRcaScreenState();
}

class _IncidentRcaScreenState extends State<IncidentRcaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _slaCountdownTimer;
  DateTime _currentTime = DateTime.now();

  // Active Incident Selection
  int _selectedIncidentIndex = 0;
  String _selectedClassificationFilter = 'ALL';
  String _searchQuery = '';
  IshikawaCategory _selectedIshikawaCategory = IshikawaCategory.man;

  late List<IncidentDossier> _incidents;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initIncidentsData();

    // 1-second statutory countdown ticker
    _slaCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _slaCountdownTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _initIncidentsData() {
    final now = DateTime.now();

    // Sample Incident 1: Major Hydrotest Pressure Rupture (LTI / HiPo)
    final inc1Time = now.subtract(const Duration(hours: 14, minutes: 22));
    final inc1Deadline = inc1Time.add(const Duration(hours: 24));

    final inc1Whys = [
      const FiveWhysStep(
        step: 1,
        question: 'Why did the hydrotest blind flange gasket rupture at 152 bar test pressure?',
        response:
            'The hydrotest manifold pressure rose uncontrollably past the 148 bar design test threshold due to rapid plunger displacement from auxiliary booster pump.',
        categoryTag: 'Direct Physical Trigger',
      ),
      const FiveWhysStep(
        step: 2,
        question: 'Why did the test manifold pressure exceed the design limit without automatic venting?',
        response:
            'The primary high-pressure safety relief valve (PSV-102) set at 145 bar failed to lift and vent pressurized test fluid.',
        categoryTag: 'Barrier Failure',
      ),
      const FiveWhysStep(
        step: 3,
        question: 'Why did PSV-102 fail to lift at its certified pop-off pressure?',
        response:
            'The spring nozzle guide had seized due to dried particulate sludge and its statutory recalibration interval had expired 18 days prior.',
        categoryTag: 'Sub-Component Degradation',
      ),
      const FiveWhysStep(
        step: 4,
        question: 'Why was an uncalibrated / overdue PSV installed on an active pipeline hydrotest spread?',
        response:
            'The QA store staging bay did not maintain physical quarantine for expired valves, and paper tagging was lost during monsoon rains.',
        categoryTag: 'Process & QA Defect',
      ),
      const FiveWhysStep(
        step: 5,
        question: 'Why did the hydrotest permit-to-work issue without verified calibration certificate validation?',
        response:
            'Digital PTW system lacked an automated hard-stop barrier check against the central instrument calibration ledger prior to high-pressure hot permit authorization.',
        categoryTag: 'Root Cause (Systemic MOC)',
        isRootCause: true,
      ),
    ];

    final inc1Fishbone = [
      const FishboneFactor(
        id: 'FB-01',
        category: IshikawaCategory.man,
        title: 'Hydrotest Techs Bypassed Double Verification',
        description: 'Shift changeover crew assumed valve was pre-calibrated without checking physical lead seal tag.',
        isPrimaryRootCause: false,
        severityScore: 3,
      ),
      const FishboneFactor(
        id: 'FB-02',
        category: IshikawaCategory.man,
        title: 'Pump Operator Over-Ramped Flow Rate',
        description: 'Booster pump discharge rate reached 4.2 L/min against 2.0 L/min standard hydrotest ramp procedure.',
        isPrimaryRootCause: false,
        severityScore: 4,
      ),
      const FishboneFactor(
        id: 'FB-03',
        category: IshikawaCategory.machine,
        title: 'PSV-102 Spindle Seized by Sludge',
        description: 'Relief valve internals seized by fine silt deposits from raw river wash water.',
        isPrimaryRootCause: true,
        severityScore: 5,
      ),
      const FishboneFactor(
        id: 'FB-04',
        category: IshikawaCategory.machine,
        title: 'Analog Bourdon Gauge Lagged by 9 Bar',
        description: 'Mechanical dial gauge dampened by vibration showed 143 bar while actual pressure reached 152 bar.',
        isPrimaryRootCause: false,
        severityScore: 4,
      ),
      const FishboneFactor(
        id: 'FB-05',
        category: IshikawaCategory.method,
        title: 'No Digital MOC Lock on PTW Gate',
        description: 'Permit issuer authorized hydrotest without mandatory digital verification of valve calibration barcode.',
        isPrimaryRootCause: true,
        severityScore: 5,
      ),
      const FishboneFactor(
        id: 'FB-06',
        category: IshikawaCategory.material,
        title: 'Substandard Gasket Tensile Rating',
        description: 'Class 300 spiral wound gasket mistakenly fitted into Class 600 test manifold flange.',
        isPrimaryRootCause: false,
        severityScore: 4,
      ),
      const FishboneFactor(
        id: 'FB-07',
        category: IshikawaCategory.measurement,
        title: 'Lapsed Hydro Chart Transducer Calibration',
        description: 'Deadweight tester calibration certificate expired on 12-Sep-2026 without quarantine flag.',
        isPrimaryRootCause: false,
        severityScore: 3,
      ),
      const FishboneFactor(
        id: 'FB-08',
        category: IshikawaCategory.milieu,
        title: 'Monsoon Flooding Softened Manifold Anchoring',
        description: 'Heavy precipitation (>35 mm/hr) saturated pipeline ditch, reducing thrust block stabilization.',
        isPrimaryRootCause: false,
        severityScore: 3,
      ),
    ];

    final inc1Capa = [
      CapaItem(
        id: 'CAPA-2026-0881',
        incidentId: 'INC-2026-0491',
        title: 'Enforce Digital MOC Quarantine Interlock in PTW',
        description:
            'Implement hard database lock preventing hydrotest permit sign-off unless all attached PSV and transducer serials possess valid NABL calibration credentials.',
        isPreventive: true,
        hierarchy: HierarchyOfControl.engineering,
        ownerName: 'Er. Rajeshwar Nath',
        ownerRole: 'Chief Pipeline Integrity Manager',
        targetDate: now.add(const Duration(days: 7)),
        status: CapaStatus.inProgress,
      ),
      CapaItem(
        id: 'CAPA-2026-0882',
        incidentId: 'INC-2026-0491',
        title: 'Complete Fleet Recalibration of Spread B Relief Valves',
        description:
            'Inspect, ultrasonically decontaminate, and recalibrate all 14 hydrotest manifold pressure relief valves on NABL certified bench.',
        isPreventive: false,
        hierarchy: HierarchyOfControl.engineering,
        ownerName: 'Amitava Sen',
        ownerRole: 'QA/QC Lead Mechanical Engineer',
        targetDate: now.add(const Duration(days: 3)),
        status: CapaStatus.open,
      ),
      CapaItem(
        id: 'CAPA-2026-0883',
        incidentId: 'INC-2026-0491',
        title: 'Color-Coded Anti-Tamper Lead Wire Seals for Gaskets',
        description:
            'Introduce ANSI Class 600 distinct yellow banded identification tag on all hydrotest blind flanges to eliminate gasket rating mix-up.',
        isPreventive: true,
        hierarchy: HierarchyOfControl.administrative,
        ownerName: 'Vikas Sharma',
        ownerRole: 'Warehouse & Stores Controller',
        targetDate: now.add(const Duration(days: 5)),
        status: CapaStatus.inProgress,
      ),
      CapaItem(
        id: 'CAPA-2026-0884',
        incidentId: 'INC-2026-0491',
        title: 'Mandatory 4-Eye Barcode Scan at Manifold Hookup',
        description:
            'Require hydrotest engineer and safety officer mutual QR barcode validation of all pressurized fittings prior to filling pump start.',
        isPreventive: true,
        hierarchy: HierarchyOfControl.administrative,
        ownerName: 'Sunita Roy',
        ownerRole: 'HSE Lead Officer Spread B',
        targetDate: now.add(const Duration(days: 10)),
        status: CapaStatus.open,
      ),
    ];

    final inc1Evidence = [
      EvidenceRecord(
        id: 'EVD-2026-104',
        incidentId: 'INC-2026-0491',
        category: EvidenceCategory.photo,
        title: 'Ruptured Class 300 Spiral Wound Gasket & Flange Face',
        capturedAt: inc1Time.add(const Duration(minutes: 25)),
        chainageLocation: 'KP 48+220 SV-04 Valve Station',
        capturedBy: 'Arjun Baruah (Field HSE Officer)',
        sha256Hash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        tamperSealTag: 'SEAL-DGMS-0941',
        summary:
            'High-resolution macro photo displaying radially blown outer graphite filler at 4 o’clock position with bolt stretch elongation.',
        technicalMetadata: {
          'GPS Coordinates': '27.4882° N, 95.3129° E',
          'Camera Sensor': 'Exmor RS 50MP ISO-125 f/1.8',
          'Flange Rating': 'Class 600 WNRF ASTM A105',
          'Observed Gap': '3.4 mm localized extrusion',
        },
      ),
      EvidenceRecord(
        id: 'EVD-2026-105',
        incidentId: 'INC-2026-0491',
        category: EvidenceCategory.metallurgy,
        title: 'CSIR-NML Metallurgical Fractography Report #NML-2026-774',
        capturedAt: inc1Time.add(const Duration(hours: 4)),
        chainageLocation: 'Central NDT & Metallurgy Testing Lab',
        capturedBy: 'Dr. Debabrata Roy (Principal Metallurgist)',
        sha256Hash: 'a7c93e41b2389104b281f9b3c48209dcba841029482103498172049182390a1f',
        tamperSealTag: 'LAB-NML-SEAL-882',
        summary:
            'SEM Fractography confirms overload shear failure of gasket retaining winding with transgranular cleavage micro-cracks. No preexisting fatigue striations observed.',
        technicalMetadata: {
          'Failure Mode': 'Hydrostatic Overpressure Shear Extrusion',
          'Vickers Hardness (HV)': '312 HV10 (Normal)',
          'Charpy V-Notch Energy': '58 Joules at 0°C',
          'Spectrometry Spec': 'AISI 316L SS Winding, Flexible Graphite',
        },
      ),
      EvidenceRecord(
        id: 'EVD-2026-106',
        incidentId: 'INC-2026-0491',
        category: EvidenceCategory.witness,
        title: 'Sworn Statement: Hydrotest Shift In-Charge',
        capturedAt: inc1Time.add(const Duration(hours: 2, minutes: 10)),
        chainageLocation: 'Spread B Site HSE Office',
        capturedBy: 'Sanjay Gogoi (Inquiry Committee Secy)',
        sha256Hash: '3f92b7401c90a182b8492048f029148293847291048201948201948201928472',
        tamperSealTag: 'WITNESS-AUDIO-TAPE-01',
        summary:
            'Testified that pressure rose from 135 to 152 bar in under 45 seconds when high-output pump auxiliary valve was opened to overcome line pack resistance.',
        technicalMetadata: {
          'Witness Name': 'Tapan Borgohain (Sr Hydrotest Engr)',
          'Experience': '11 Years Cross-Country Pipeline QA',
          'Audio File Format': 'FLAC 24-bit 48kHz (Encrypted)',
          'Legal Admissibility': 'OISD-GDN-107 Section 6.3 Certified',
        },
      ),
      EvidenceRecord(
        id: 'EVD-2026-107',
        incidentId: 'INC-2026-0491',
        category: EvidenceCategory.telemetry,
        title: 'Digital Deadweight Chart Recorder Pressure Trace',
        capturedAt: inc1Time.add(const Duration(minutes: 50)),
        chainageLocation: 'Manifold Instrumentation Cabin',
        capturedBy: 'Telemetry Data Logger',
        sha256Hash: '9182049182039481029384019283049182039481029384019283049182039481',
        tamperSealTag: 'SCADA-CRYPTO-LOG-44',
        summary:
            'Time-series pressure log sampled at 10 Hz displaying sharp pressure surge peaking at 152.4 bar followed by sudden pressure drop to 0 bar within 1.2s.',
        technicalMetadata: {
          'Peak Pressure': '152.4 bar gauge (2210 psi)',
          'Depressurization Time': '1.2 seconds',
          'Transducer Model': 'Rosemount 3051S High Accuracy',
          'NABL Calib Due': '12-Sep-2026 (Expired by 18d)',
        },
      ),
    ];

    // Sample Incident 2: HiPo 60T Crane Outrigger Soil Subsidence
    final inc2Time = now.subtract(const Duration(hours: 36, minutes: 10));
    final inc2Deadline = inc2Time.add(const Duration(hours: 24));

    final inc2Whys = [
      const FiveWhysStep(
        step: 1,
        question: 'Why did the 60-Ton crawler crane right outrigger sink 38 cm into ground during pipe string lift?',
        response: 'Subsoil beneath outrigger steel mat suffered bearing capacity shear failure under dynamic load.',
        categoryTag: 'Direct Physical Trigger',
      ),
      const FiveWhysStep(
        step: 2,
        question: 'Why did the soil bearing capacity fail below expected 180 kPa specification?',
        response: 'Uncompacted riverbed clay-silt was saturated by overnight HDD drill slurry seepage runoff.',
        categoryTag: 'Environmental Factor',
      ),
      const FiveWhysStep(
        step: 3,
        question: 'Why was the lifting operation commenced over waterlogged uncompacted ground?',
        response: 'Lifting supervisor performed visual check only without conducting Dynamic Cone Penetrometer (DCP) test.',
        categoryTag: 'Procedural Gap',
      ),
      const FiveWhysStep(
        step: 4,
        question: 'Why was DCP soil compaction testing omitted from pre-lift permit checklist?',
        response: 'Site-specific Heavy Lift Protocol lacked mandatory compaction verification clause for HDD crossing yards.',
        categoryTag: 'Standards Deficiency',
      ),
      const FiveWhysStep(
        step: 5,
        question: 'Why was generic rigging procedure applied to critical river crossing heavy lifting?',
        response: 'Rigging engineering risk assessment matrix failed to mandate geotechnical sign-off for tandem river bank lifts.',
        categoryTag: 'Root Cause (Engineering Governance)',
        isRootCause: true,
      ),
    ];

    final inc2Fishbone = [
      const FishboneFactor(
        id: 'FB-21',
        category: IshikawaCategory.man,
        title: 'Rigger Relied on Visual Ground Assessment',
        description: 'No penetrometer or plate load verification executed prior to positioning 60T crane.',
        isPrimaryRootCause: false,
        severityScore: 4,
      ),
      const FishboneFactor(
        id: 'FB-22',
        category: IshikawaCategory.machine,
        title: 'Standard Wood Timber Cribbing Used Instead of Steel Mats',
        description: 'Outrigger pads measured only 1.2m x 1.2m, exerting 240 kPa ground bearing pressure.',
        isPrimaryRootCause: false,
        severityScore: 4,
      ),
      const FishboneFactor(
        id: 'FB-23',
        category: IshikawaCategory.method,
        title: 'Geotechnical Sign-Off Missing from Lifting Plan',
        description: 'Tandem lift permit signed off as standard routine rather than non-routine critical lift.',
        isPrimaryRootCause: true,
        severityScore: 5,
      ),
      const FishboneFactor(
        id: 'FB-24',
        category: IshikawaCategory.material,
        title: 'HDD Bentonite Slurry Spill Softened Berm',
        description: 'Bentonite mud discharge pond breached retaining bund 6 hours prior to lifting operation.',
        isPrimaryRootCause: false,
        severityScore: 4,
      ),
      const FishboneFactor(
        id: 'FB-25',
        category: IshikawaCategory.measurement,
        title: 'Crane Load Moment Indicator (LMI) Angle Sensor Drift',
        description: 'LMI indicated 72% safe working load, masking real-time 88% tipping moment on slope.',
        isPrimaryRootCause: false,
        severityScore: 4,
      ),
      const FishboneFactor(
        id: 'FB-26',
        category: IshikawaCategory.milieu,
        title: 'Alluvial Riverbank High Water Table',
        description: 'Groundwater table elevated to 0.4m below surface due to Dikhow river monsoon swelling.',
        isPrimaryRootCause: false,
        severityScore: 3,
      ),
    ];

    final inc2Capa = [
      CapaItem(
        id: 'CAPA-2026-0771',
        incidentId: 'INC-2026-0382',
        title: 'Mandate 2.4m x 2.4m Engineered Steel Spreader Mats',
        description:
            'Prohibit timber outrigger mats for all lifts exceeding 20T; mandate FEA-certified steel crane pads providing <120 kPa pressure.',
        isPreventive: true,
        hierarchy: HierarchyOfControl.engineering,
        ownerName: 'Manish Chhabra',
        ownerRole: 'Lead Heavy Rigging Specialist',
        targetDate: now.subtract(const Duration(days: 1)),
        status: CapaStatus.closed,
        completionNotes: 'Certified 12 sets of heavy steel spreader mats across all river crossing packages.',
      ),
      CapaItem(
        id: 'CAPA-2026-0772',
        incidentId: 'INC-2026-0382',
        title: 'Mandatory Dynamic Cone Penetrometer (DCP) Pre-Lift Log',
        description:
            'Incorporate DCP CBR test verification directly into digital PTW checklist before any heavy crane set-up.',
        isPreventive: true,
        hierarchy: HierarchyOfControl.administrative,
        ownerName: 'Bhaskar Saikia',
        ownerRole: 'Senior Geotechnical Engineer',
        targetDate: now.add(const Duration(days: 4)),
        status: CapaStatus.inProgress,
      ),
    ];

    final inc2Evidence = [
      EvidenceRecord(
        id: 'EVD-2026-081',
        incidentId: 'INC-2026-0382',
        category: EvidenceCategory.photo,
        title: 'Outrigger 38cm Subsidence Depicting Saturated Clay Punch',
        capturedAt: inc2Time.add(const Duration(minutes: 15)),
        chainageLocation: 'KP 22+150 Dikhow HDD Crossing Yard',
        capturedBy: 'Pranjal Deka (Safety Officer)',
        sha256Hash: '4a8b7201c90a182b8492048f029148293847291048201948201948201928472a',
        tamperSealTag: 'SEAL-DGMS-0899',
        summary:
            'Photo depicting crane listing 4.2 degrees to starboard with outrigger foot deeply embedded in liquefied bentonite silt.',
        technicalMetadata: {
          'GPS Coordinates': '26.9841° N, 94.6128° E',
          'List Angle': '4.2° (Exceeded 1.0° permissible crane limit)',
          'Suspended Load': '24.2 Ton API 5L X70 Pipe String (96m)',
        },
      ),
    ];

    // Sample Incident 3: Near Miss Hydrocarbon Gas Seepage during Nitrogen Purge
    final inc3Time = now.subtract(const Duration(days: 3, hours: 8));
    final inc3Deadline = inc3Time.add(const Duration(hours: 24));

    final inc3Whys = [
      const FiveWhysStep(
        step: 1,
        question: 'Why was 18% LEL combustible gas detected near CS-02 suction strainer flange during N2 purge?',
        response: 'Residual condensate trapped in dead-leg pocket vaporized as warm nitrogen was injected.',
        categoryTag: 'Direct Physical Trigger',
      ),
      const FiveWhysStep(
        step: 2,
        question: 'Why was residual condensate present in the suction header dead-leg?',
        response: 'Low point drain valve DV-03 was partially clogged with pipeline construction debris.',
        categoryTag: 'Equipment Condition',
      ),
      const FiveWhysStep(
        step: 3,
        question: 'Why was the low point drain valve not rodded or verified clear prior to purging?',
        response: 'Pre-commissioning purge procedure did not mandate optical borescope verification of drain headers.',
        categoryTag: 'Procedural Deficiency',
      ),
      const FiveWhysStep(
        step: 4,
        question: 'Why did the pre-purge checklist treat dead-leg drainage as routine rather than high-risk?',
        response: 'Commissioning team lacked specific HAZOP guidance for condensate accumulation in cold-start headers.',
        categoryTag: 'Process Hazard Defect',
      ),
      const FiveWhysStep(
        step: 5,
        question: 'Why was HAZOP line-tracing verification omitted for suction manifold commissioning?',
        response: 'Subcontractor commissioning manual was adopted without owner engineering review or OISD alignment.',
        categoryTag: 'Root Cause (Contractor Quality Assurance)',
        isRootCause: true,
      ),
    ];

    final inc3Fishbone = [
      const FishboneFactor(
        id: 'FB-31',
        category: IshikawaCategory.method,
        title: 'Purge Flow Rate Exceeded 12 Nm3/min Without Low-Point Flush',
        description: 'Nitrogen gas injected before confirming all low point drains were producing zero liquid condensate.',
        isPrimaryRootCause: true,
        severityScore: 4,
      ),
      const FishboneFactor(
        id: 'FB-32',
        category: IshikawaCategory.machine,
        title: 'Dead-Leg Drain Valve DV-03 Orifice Clogged',
        description: '1/2 inch needle valve orifice obstructed by blasting grit and welding spatter.',
        isPrimaryRootCause: false,
        severityScore: 3,
      ),
      const FishboneFactor(
        id: 'FB-33',
        category: IshikawaCategory.measurement,
        title: 'Fixed Gas Detector Located Downwind of Purge Vent',
        description: 'Fixed catalytic bead detector took 4 minutes to register vapor plume due to wind direction.',
        isPrimaryRootCause: false,
        severityScore: 3,
      ),
    ];

    final inc3Capa = [
      CapaItem(
        id: 'CAPA-2026-0611',
        incidentId: 'INC-2026-0219',
        title: 'Revise CS-02 Pre-Purge Checklist with Mandatory Borescope Verification',
        description:
            'Install full-port ball valves on all header drains and mandate flexible video borescope inspection before N2 pressurization.',
        isPreventive: true,
        hierarchy: HierarchyOfControl.engineering,
        ownerName: 'Debojit Sarma',
        ownerRole: 'Commissioning Manager',
        targetDate: now.subtract(const Duration(days: 2)),
        status: CapaStatus.closed,
        completionNotes: 'Borescope inspection protocol validated and integrated into Pre-Commissioning Manual rev 3.1.',
      ),
    ];

    final inc3Evidence = [
      EvidenceRecord(
        id: 'EVD-2026-052',
        incidentId: 'INC-2026-0219',
        category: EvidenceCategory.telemetry,
        title: 'Portable 4-Gas Monitor Log Trace at DV-03 Vent',
        capturedAt: inc3Time.add(const Duration(minutes: 12)),
        chainageLocation: 'CS-02 Compressor Suction Skid',
        capturedBy: 'Rupjyoti Hazarika (Gas Testing Specialist)',
        sha256Hash: '72910482019482019482019284723f92b7401c90a182b8492048f02914829384',
        tamperSealTag: 'SEAL-GAS-019',
        summary:
            'Log file from Industrial Scientific MX4 monitor proving peak combustible gas of 18% LEL with O2 reading at 1.8% volume.',
        technicalMetadata: {
          'LEL Peak': '18% Pentane Equivalent',
          'O2 Level': '1.8% Vol',
          'Calib Status': 'Freshly Bump Tested at 07:00 IST',
        },
      ),
    ];

    _incidents = [
      IncidentDossier(
        id: 'INC-2026-0491',
        title: 'Hydrotest Manifold High-Pressure Rupture & Gasket Blown at 152 Bar',
        incidentTime: inc1Time,
        chainageLocation: 'KP 48+220, SV-04 Valve Station',
        plantSection: 'Mainline Hydrotest Spread B',
        classification: IncidentClassification.lostTimeIncident,
        severity: SeverityRating.major,
        stage: InvestigationStage.rcaAnalysis,
        dgmsStatus: DgmsNoticeStatus.pending24h,
        dgmsAckNumber: null,
        dgmsNoticeDeadline: inc1Deadline,
        leadInvestigator: 'Er. Rajeshwar Nath (Chief Pipeline Integrity)',
        investigationTeam: [
          'Er. Rajeshwar Nath',
          'Amitava Sen (Lead QC)',
          'Sunita Roy (HSE Spread B)',
          'Dr. Debabrata Roy (CSIR-NML)',
        ],
        initialSummary:
            'During final 4-hour hydrostatic strength test at 152 bar, high pressure blind flange gasket suffered radial blowout, propelling gravel and inflicting deep hand laceration on assisting contractor rigger (14 days LTI).',
        fiveWhys: inc1Whys,
        fishboneFactors: inc1Fishbone,
        capaItems: inc1Capa,
        evidenceVault: inc1Evidence,
      ),
      IncidentDossier(
        id: 'INC-2026-0382',
        title: 'HiPo: 60T Crawler Crane Outrigger Soil Subsidence During 24T Pipe Lift',
        incidentTime: inc2Time,
        chainageLocation: 'KP 22+150, Dikhow River HDD Yard',
        plantSection: 'HDD Crossing Spread A',
        classification: IncidentClassification.highPotential,
        severity: SeverityRating.major,
        stage: InvestigationStage.capaExecution,
        dgmsStatus: DgmsNoticeStatus.complied,
        dgmsAckNumber: 'DGMS/EZ/NE/2026/0942-F4',
        dgmsNoticeDeadline: inc2Deadline,
        leadInvestigator: 'Manish Chhabra (Rigging Specialist)',
        investigationTeam: [
          'Manish Chhabra',
          'Bhaskar Saikia (Geotech)',
          'Pranjal Deka (Safety)',
        ],
        initialSummary:
            '60-Ton crawler crane lifting 24-Ton welded HDD pipe string experienced sudden 38cm outrigger depression into slurry-saturated berm. Crane listed 4.2 degrees; emergency release prevented boom collapse.',
        fiveWhys: inc2Whys,
        fishboneFactors: inc2Fishbone,
        capaItems: inc2Capa,
        evidenceVault: inc2Evidence,
      ),
      IncidentDossier(
        id: 'INC-2026-0219',
        title: 'Near Miss: Hydrocarbon Vapor Pocket Flash Hazard During N2 Purging',
        incidentTime: inc3Time,
        chainageLocation: 'Compressor Station CS-02',
        plantSection: 'Gas Compression Unit Skid 2',
        classification: IncidentClassification.nearMiss,
        severity: SeverityRating.minor,
        stage: InvestigationStage.statutoryClosed,
        dgmsStatus: DgmsNoticeStatus.exempt,
        dgmsAckNumber: 'EXEMPT-OISD-NM-107',
        dgmsNoticeDeadline: inc3Deadline,
        leadInvestigator: 'Debojit Sarma (Commissioning Mgr)',
        investigationTeam: [
          'Debojit Sarma',
          'Rupjyoti Hazarika (Gas Testing)',
          'A. K. Baruah (Ops)',
        ],
        initialSummary:
            'Portable multigas monitor sounded alarm at 18% LEL during high-velocity N2 displacement due to vaporized dead-leg condensate. Purge immediately stopped, line depressurized, zero ignition.',
        fiveWhys: inc3Whys,
        fishboneFactors: inc3Fishbone,
        capaItems: inc3Capa,
        evidenceVault: inc3Evidence,
      ),
    ];
  }

  IncidentDossier get _currentIncident => _incidents[_selectedIncidentIndex];

  List<IncidentDossier> get _filteredIncidents {
    return _incidents.where((inc) {
      final matchesFilter = _selectedClassificationFilter == 'ALL' ||
          inc.classification.code == _selectedClassificationFilter;
      final matchesQuery = _searchQuery.isEmpty ||
          inc.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inc.chainageLocation.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();
  }

  // ============================================================================
  // STATUTORY ACTIONS & DIALOGS
  // ============================================================================

  void _dispatchDgmsNotice(IncidentDossier inc) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border, width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444), width: 1),
                ),
                child: const Icon(Icons.gavel_rounded, color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DGMS FORM IV-A DISPATCH',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Oil Mines Regulations 2017 / Reg 91 & 92',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatutoryField('Statutory Authority', 'DGMS North-East Zone (Guwahati/Sitarampur)'),
                        const SizedBox(height: 6),
                        _buildStatutoryField('Incident ID & Time', '${inc.id} | ${DateFormat('dd-MMM-yyyy HH:mm').format(inc.incidentTime)} IST'),
                        const SizedBox(height: 6),
                        _buildStatutoryField('Location & Chainage', inc.chainageLocation),
                        const SizedBox(height: 6),
                        _buildStatutoryField('Classification', '${inc.classification.label} (${inc.severity.label})'),
                        const SizedBox(height: 6),
                        _buildStatutoryField('Investigation Head', inc.leadInvestigator),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Statutory Undertaking:',
                    style: TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'I hereby certify under Regulation 91 of OMR 2017 that preliminary notice of this serious dangerous occurrence has been transmitted to the Chief Inspector of Mines & Regional Inspector within 24 hours of occurrence. Site evidence has been cryptographically preserved per OISD-GDN-107.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('DISPATCH & SEAL FORM IV-A'),
              onPressed: () {
                final generatedAck = 'DGMS/EZ/NE/${DateTime.now().year}/${1000 + math.Random().nextInt(8999)}-F4';
                setState(() {
                  final updatedInc = inc.copyWith(
                    dgmsStatus: DgmsNoticeStatus.complied,
                    dgmsAckNumber: generatedAck,
                  );
                  _incidents[_selectedIncidentIndex] = updatedInc;
                });
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    content: Text(
                      'Form IV-A successfully transmitted to DGMS! Statutory Ack: $generatedAck',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatutoryField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  void _showNewIncidentDialog() {
    final idController = TextEditingController(text: 'INC-2026-0${500 + _incidents.length}');
    final titleController = TextEditingController();
    final locationController = TextEditingController(text: 'KP 64+100, Moran Block Valve SV-06');
    final summaryController = TextEditingController();
    IncidentClassification selectedClass = IncidentClassification.nearMiss;
    SeverityRating selectedSev = SeverityRating.moderate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border, width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_alert_rounded, color: AppTheme.primaryLight, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'LOG NEW STATUTORY INCIDENT',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: idController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Incident Identifier (OISD Format)',
                          labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Incident Title / Brief Event',
                          hintText: 'e.g. Scaffolding Clamping Failure at Trench 4',
                          labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: locationController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Location / Chainage KP Marker',
                          labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<IncidentClassification>(
                              initialValue: selectedClass,
                              decoration: const InputDecoration(
                                labelText: 'Classification',
                                labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                border: OutlineInputBorder(),
                              ),
                              dropdownColor: AppTheme.surfaceCard,
                              items: IncidentClassification.values.map((cls) {
                                return DropdownMenuItem(
                                  value: cls,
                                  child: Text(cls.code, style: TextStyle(color: cls.color, fontSize: 12, fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDlgState(() => selectedClass = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<SeverityRating>(
                              initialValue: selectedSev,
                              decoration: const InputDecoration(
                                labelText: 'Severity Level',
                                labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                border: OutlineInputBorder(),
                              ),
                              dropdownColor: AppTheme.surfaceCard,
                              items: SeverityRating.values.map((sev) {
                                return DropdownMenuItem(
                                  value: sev,
                                  child: Text(sev.label, style: TextStyle(color: sev.color, fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDlgState(() => selectedSev = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: summaryController,
                        maxLines: 3,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Preliminary Incident Summary & Harm Profile',
                          hintText: 'Describe equipment involved, persons impacted, immediate barriers deployed...',
                          labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('LOG INCIDENT & START CLOCK'),
                  onPressed: () {
                    final newTime = DateTime.now();
                    final newInc = IncidentDossier(
                      id: idController.text.trim().isEmpty ? 'INC-2026-0999' : idController.text.trim(),
                      title: titleController.text.trim().isEmpty ? 'Unspecified Construction Incident' : titleController.text.trim(),
                      incidentTime: newTime,
                      chainageLocation: locationController.text.trim(),
                      plantSection: 'Pipeline Spread C',
                      classification: selectedClass,
                      severity: selectedSev,
                      stage: InvestigationStage.reported,
                      dgmsStatus: selectedClass.dgmsMandatoryNotice ? DgmsNoticeStatus.pending24h : DgmsNoticeStatus.exempt,
                      dgmsNoticeDeadline: newTime.add(const Duration(hours: 24)),
                      leadInvestigator: 'Er. Rajeshwar Nath',
                      investigationTeam: ['Er. Rajeshwar Nath', 'HSE Site Supervisor'],
                      initialSummary: summaryController.text.trim().isEmpty ? 'Initial preliminary log registered.' : summaryController.text.trim(),
                      fiveWhys: [
                        const FiveWhysStep(
                          step: 1,
                          question: 'Why did the preliminary adverse event occur?',
                          response: 'Initial trigger event currently undergoing forensic investigation.',
                          categoryTag: 'Direct Physical Trigger',
                        ),
                      ],
                      fishboneFactors: [],
                      capaItems: [],
                      evidenceVault: [],
                    );

                    setState(() {
                      _incidents.insert(0, newInc);
                      _selectedIncidentIndex = 0;
                    });
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.primary,
                        content: Text('Incident ${newInc.id} logged! 24-Hr DGMS Notice clock initiated.'),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddWhyDialog() {
    final inc = _currentIncident;
    final currentStep = inc.fiveWhys.length + 1;
    final qController = TextEditingController(text: 'Why did the preceding condition occur?');
    final rController = TextEditingController();
    String category = currentStep >= 5 ? 'Root Cause (Systemic MOC)' : 'Process & Procedural Failure';
    bool isRoot = currentStep >= 5;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'WHY #$currentStep',
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ADD 5-WHYS BRANCH STEP',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: qController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Why Question',
                        labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rController,
                      maxLines: 3,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Observed Cause / Verification Response',
                        hintText: 'Document the underlying mechanism discovered during investigation...',
                        labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Mark as Definitive Root Cause',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Will be highlighted in statutory OISD-GDN-107 dossier synthesis',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                      value: isRoot,
                      activeColor: const Color(0xFFEF4444),
                      onChanged: (val) {
                        setDlgState(() {
                          isRoot = val ?? false;
                          if (isRoot) {
                            category = 'Root Cause (Systemic MOC)';
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (rController.text.trim().isEmpty) return;
                    final newStep = FiveWhysStep(
                      step: currentStep,
                      question: qController.text.trim(),
                      response: rController.text.trim(),
                      categoryTag: category,
                      isRootCause: isRoot,
                    );
                    setState(() {
                      final updatedList = List<FiveWhysStep>.from(inc.fiveWhys)..add(newStep);
                      _incidents[_selectedIncidentIndex] = inc.copyWith(fiveWhys: updatedList);
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('APPEND WHY STEP'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddFishboneCauseDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    IshikawaCategory category = _selectedIshikawaCategory;
    bool isPrimary = false;
    int severity = 3;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Row(
                children: [
                  Icon(category.icon, color: category.color, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'ADD ISHIKAWA CAUSE FACTOR',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<IshikawaCategory>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Ishikawa 6M Branch',
                          labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                        dropdownColor: AppTheme.surfaceCard,
                        items: IshikawaCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(cat.icon, color: cat.color, size: 16),
                                const SizedBox(width: 8),
                                Text(cat.title, style: TextStyle(color: cat.color, fontSize: 13)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDlgState(() => category = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleCtrl,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Cause Factor Title',
                          hintText: 'e.g. Relief valve guide seized by silt',
                          labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Detailed Explanation & Physical Evidence',
                          labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Factor Severity (1-5):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          const SizedBox(width: 10),
                          ...List.generate(5, (index) {
                            final score = index + 1;
                            final isSel = severity == score;
                            return InkWell(
                              onTap: () => setDlgState(() => severity = score),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? AppTheme.primary : AppTheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isSel ? AppTheme.primaryLight : AppTheme.border),
                                ),
                                child: Text(
                                  '$score',
                                  style: TextStyle(
                                    color: isSel ? Colors.white : AppTheme.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tag as Primary Root Cause', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                        value: isPrimary,
                        activeColor: const Color(0xFFEF4444),
                        onChanged: (val) => setDlgState(() => isPrimary = val ?? false),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final inc = _currentIncident;
                    final newFactor = FishboneFactor(
                      id: 'FB-${DateTime.now().millisecondsSinceEpoch % 1000}',
                      category: category,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      isPrimaryRootCause: isPrimary,
                      severityScore: severity,
                    );
                    setState(() {
                      final updatedList = List<FishboneFactor>.from(inc.fishboneFactors)..add(newFactor);
                      _incidents[_selectedIncidentIndex] = inc.copyWith(fishboneFactors: updatedList);
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('ATTACH TO BONE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCapaDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ownerCtrl = TextEditingController(text: 'Er. Rajeshwar Nath');
    final roleCtrl = TextEditingController(text: 'Lead Pipeline Engineer');
    bool isPreventive = true;
    HierarchyOfControl hierarchy = HierarchyOfControl.engineering;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: const Row(
                children: [
                  Icon(Icons.assignment_turned_in_rounded, color: AppTheme.tertiary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'NEW CAPA ACTION ITEM',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Preventive Action'),
                              selected: isPreventive,
                              selectedColor: AppTheme.primary,
                              onSelected: (val) => setDlgState(() => isPreventive = true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Corrective Action'),
                              selected: !isPreventive,
                              selectedColor: AppTheme.secondary,
                              onSelected: (val) => setDlgState(() => isPreventive = false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<HierarchyOfControl>(
                        initialValue: hierarchy,
                        decoration: const InputDecoration(
                          labelText: 'Hierarchy of Controls (ISO 45001)',
                          labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                        dropdownColor: AppTheme.surfaceCard,
                        items: HierarchyOfControl.values.map((h) {
                          return DropdownMenuItem(
                            value: h,
                            child: Text(h.label, style: TextStyle(color: h.color, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDlgState(() => hierarchy = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleCtrl,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Action Item Title',
                          labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Technical Execution Scope & Verification Standard',
                          labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ownerCtrl,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Action Owner',
                                labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: roleCtrl,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Role / Designation',
                                labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final inc = _currentIncident;
                    final newItem = CapaItem(
                      id: 'CAPA-2026-${1000 + math.Random().nextInt(8999)}',
                      incidentId: inc.id,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      isPreventive: isPreventive,
                      hierarchy: hierarchy,
                      ownerName: ownerCtrl.text.trim(),
                      ownerRole: roleCtrl.text.trim(),
                      targetDate: DateTime.now().add(const Duration(days: 7)),
                      status: CapaStatus.open,
                    );
                    setState(() {
                      final updated = List<CapaItem>.from(inc.capaItems)..add(newItem);
                      _incidents[_selectedIncidentIndex] = inc.copyWith(capaItems: updated);
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('CREATE CAPA MANDATE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddEvidenceDialog() {
    final titleCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    EvidenceCategory cat = EvidenceCategory.photo;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: const Row(
                children: [
                  Icon(Icons.enhanced_encryption_rounded, color: Color(0xFFA855F7), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'DEPOSIT EVIDENCE IN VAULT',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<EvidenceCategory>(
                      initialValue: cat,
                      decoration: const InputDecoration(
                        labelText: 'Evidence Classification',
                        labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: AppTheme.surfaceCard,
                      items: EvidenceCategory.values.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Icon(c.icon, color: c.color, size: 16),
                              const SizedBox(width: 8),
                              Text(c.label, style: TextStyle(color: c.color, fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => cat = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Evidence Title / Specimen Name',
                        hintText: 'e.g. Metallurgical Coupon from Ruptured Neck',
                        labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: summaryCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Forensic Summary & Observations',
                        hintText: 'Document chain of custody, inspection protocol...',
                        labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.lock_rounded, size: 16),
                  label: const Text('CRYPTOGRAPHICALLY SEAL'),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final inc = _currentIncident;
                    final record = EvidenceRecord(
                      id: 'EVD-2026-${100 + math.Random().nextInt(899)}',
                      incidentId: inc.id,
                      category: cat,
                      title: titleCtrl.text.trim(),
                      capturedAt: DateTime.now(),
                      chainageLocation: inc.chainageLocation,
                      capturedBy: 'Field Investigator (DGMS Custody)',
                      sha256Hash: '9a8b${math.Random().nextInt(999999)}c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
                      tamperSealTag: 'SEAL-DGMS-${math.Random().nextInt(8999)}',
                      summary: summaryCtrl.text.trim().isEmpty ? 'Forensic record preserved under OISD-107.' : summaryCtrl.text.trim(),
                      technicalMetadata: {
                        'Chain of Custody': 'Secured in Fireproof Evidence Locker A-04',
                        'Custody Officer': 'S. Borah (HSE Officer)',
                        'Hash Verification': 'SHA-256 Passed Integrity Match',
                      },
                    );
                    setState(() {
                      final updated = List<EvidenceRecord>.from(inc.evidenceVault)..add(record);
                      _incidents[_selectedIncidentIndex] = inc.copyWith(evidenceVault: updated);
                    });
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _exportDossierReport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final inc = _currentIncident;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'EXPORT OISD-GDN-107 INVESTIGATION DOSSIER',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 8),
              Text(
                'Incident: ${inc.id} - ${inc.title}',
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'DGMS Status: ${inc.dgmsStatus.label} (${inc.dgmsAckNumber ?? "Notice Pending"})',
                style: TextStyle(color: inc.dgmsStatus.color, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildDossierExportRow(
                'Preliminary Incident Report (PIR - 24 Hr)',
                'Statutory Form IV-A, Initial Site Photos, GPS Watermark',
                Icons.check_circle_rounded,
                const Color(0xFF10B981),
              ),
              _buildDossierExportRow(
                'Root Cause Analysis Complete Package',
                '${inc.fiveWhys.length}-Step 5-Whys Tree + 6M Ishikawa Fishbone Analysis',
                Icons.check_circle_rounded,
                const Color(0xFF10B981),
              ),
              _buildDossierExportRow(
                'Corrective & Preventive Action (CAPA) Log',
                '${inc.capaItems.length} Actions Assigned with ISO 45001 Hierarchy of Controls',
                Icons.check_circle_rounded,
                const Color(0xFF10B981),
              ),
              _buildDossierExportRow(
                'Forensic Evidence Vault Index',
                '${inc.evidenceVault.length} Tamper-Sealed Items with SHA-256 Digital Fingerprints',
                Icons.check_circle_rounded,
                const Color(0xFF10B981),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text(
                    'GENERATE SIGNED OISD-107 PDF DOSSIER',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppTheme.primary,
                        content: Text('OISD-GDN-107 Statutory Investigation Dossier PDF exported successfully!'),
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

  Widget _buildDossierExportRow(String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // BUILD METHOD & ROOT SCAFFOLD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatutoryBanner(),
          _buildExecutiveMetricsStrip(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIncidentLogTab(),
                _buildFiveWhysTab(),
                _buildFishboneTab(),
                _buildCapaTab(),
                _buildEvidenceVaultTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ============================================================================
  // APP BAR & EXECUTIVE HEADER
  // ============================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Incident Investigation & RCA',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                const _StaticBadge(text: 'OISD-GDN-107', color: AppTheme.primaryLight),
                const SizedBox(width: 6),
                const _StaticBadge(text: 'DGMS FORM IV', color: Color(0xFFEF4444)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Statutory Incident Log, 5-Whys Root Cause Tree, Ishikawa 6M & CAPA Vault',
            style: TextStyle(
              color: AppTheme.textMuted.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Export OISD Investigation Dossier',
          icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: _exportDossierReport,
        ),
        IconButton(
          tooltip: 'Refresh / Sync Investigation Data',
          icon: const Icon(Icons.sync_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () {
            setState(() {
              _currentTime = DateTime.now();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppTheme.surfaceCard,
                content: Text('Investigation dossier synced with central HSE register.'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================================
  // STATUTORY 24-HR DGMS SLA BANNER & ACTIVE SELECTION
  // ============================================================================

  Widget _buildStatutoryBanner() {
    final inc = _currentIncident;
    final isMandatory = inc.classification.dgmsMandatoryNotice;
    final isComplied = inc.dgmsStatus == DgmsNoticeStatus.complied;
    final isExempt = inc.dgmsStatus == DgmsNoticeStatus.exempt;

    // Remaining duration calculation
    final remaining = inc.dgmsNoticeDeadline.difference(_currentTime);
    final isOverdue = remaining.isNegative && !isComplied && !isExempt;

    String clockText;
    Color statusColor;
    if (isComplied) {
      clockText = 'COMPLIED: Form IV-A Filed (${inc.dgmsAckNumber ?? "Ack #9042"})';
      statusColor = const Color(0xFF10B981);
    } else if (isExempt) {
      clockText = 'EXEMPT: Internal Non-Statutory Investigation Only';
      statusColor = AppTheme.textMuted;
    } else if (isOverdue) {
      final hoursAgo = remaining.inHours.abs();
      clockText = 'CRITICAL BREACH: 24-Hr Notice Overdue by ${hoursAgo}h ${remaining.inMinutes.abs() % 60}m!';
      statusColor = const Color(0xFFEF4444);
    } else {
      final hrs = remaining.inHours;
      final mins = remaining.inMinutes % 60;
      final secs = remaining.inSeconds % 60;
      clockText = '24-HR DGMS MANDATORY SLA: ${hrs.toString().padLeft(2, '0')}h ${mins.toString().padLeft(2, '0')}m ${secs.toString().padLeft(2, '0')}s REMAINING';
      statusColor = hrs < 4 ? const Color(0xFFEF4444) : (hrs < 12 ? const Color(0xFFF97316) : const Color(0xFFFFB95F));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: statusColor.withValues(alpha: 0.4), width: 1.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isComplied
                ? Icons.verified_rounded
                : (isOverdue ? Icons.dangerous_rounded : Icons.alarm_rounded),
            color: statusColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              clockText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isMandatory && !isComplied) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _dispatchDgmsNotice(inc),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.send_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'DISPATCH NOTICE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // EXECUTIVE METRICS STRIP
  // ============================================================================

  Widget _buildExecutiveMetricsStrip() {
    int totalIncidents = _incidents.length;
    int ltiCount = _incidents.where((i) => i.classification == IncidentClassification.lostTimeIncident).length;
    int hipoCount = _incidents.where((i) => i.classification == IncidentClassification.highPotential).length;
    int openCapas = _incidents.fold(0, (acc, i) => acc + i.capaItems.where((c) => c.status != CapaStatus.closed).length);
    int totalEvidence = _incidents.fold(0, (acc, i) => acc + i.evidenceVault.length);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.surface,
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              label: 'INCIDENTS',
              value: '$totalIncidents',
              subtext: 'Active Dossiers',
              color: AppTheme.primaryLight,
              icon: Icons.assignment_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'LTI CASES',
              value: '$ltiCount',
              subtext: 'Lost Time',
              color: const Color(0xFFEF4444),
              icon: Icons.personal_injury_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'HIPO NEAR-HITS',
              value: '$hipoCount',
              subtext: 'High Potential',
              color: const Color(0xFFF97316),
              icon: Icons.warning_amber_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'OPEN CAPAs',
              value: '$openCapas',
              subtext: 'Pending Actions',
              color: const Color(0xFFFFB95F),
              icon: Icons.pending_actions_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'VAULT SEALS',
              value: '$totalEvidence',
              subtext: 'SHA-256 Verified',
              color: const Color(0xFFA855F7),
              icon: Icons.lock_clock_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtext,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 9,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB BAR NAVIGATION
  // ============================================================================

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
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: [
          Tab(
            icon: const Icon(Icons.table_chart_rounded, size: 18),
            text: 'Incident Log (${_incidents.length})',
          ),
          Tab(
            icon: const Icon(Icons.account_tree_rounded, size: 18),
            text: '5-Whys Tree (${_currentIncident.fiveWhys.length})',
          ),
          Tab(
            icon: const Icon(Icons.schema_rounded, size: 18),
            text: '6M Fishbone (${_currentIncident.fishboneFactors.length})',
          ),
          Tab(
            icon: const Icon(Icons.task_alt_rounded, size: 18),
            text: 'CAPA Matrix (${_currentIncident.capaItems.length})',
          ),
          Tab(
            icon: const Icon(Icons.inventory_2_rounded, size: 18),
            text: 'Evidence Vault (${_currentIncident.evidenceVault.length})',
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: INCIDENT LOG & REGULATORY STATUTORY FILING
  // ============================================================================

  Widget _buildIncidentLogTab() {
    return Column(
      children: [
        // Filter & Search Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search by ID, Chainage, or Description...',
                          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                          filled: true,
                          fillColor: AppTheme.surfaceCard,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('LOG INCIDENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _showNewIncidentDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All Events'),
                    _buildFilterChip('LTI', 'Lost Time (LTI)', color: const Color(0xFFEF4444)),
                    _buildFilterChip('HiPo', 'High Potential (HiPo)', color: const Color(0xFFF97316)),
                    _buildFilterChip('NM', 'Near Miss', color: const Color(0xFF38BDF8)),
                    _buildFilterChip('MTC', 'Medical Treatment', color: const Color(0xFFFFB95F)),
                    _buildFilterChip('FAC', 'First Aid', color: const Color(0xFF10B981)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Incident Cards List
        Expanded(
          child: _filteredIncidents.isEmpty
              ? _buildEmptyState('No incidents match the selected filter criteria.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredIncidents.length,
                  itemBuilder: (context, index) {
                    final inc = _filteredIncidents[index];
                    final isSelected = _incidents.indexOf(inc) == _selectedIncidentIndex;
                    return _buildIncidentCard(inc, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String code, String label, {Color? color}) {
    final isSelected = _selectedClassificationFilter == code;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (color ?? AppTheme.textSecondary),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        backgroundColor: AppTheme.surfaceCard,
        selectedColor: color ?? AppTheme.primary,
        side: BorderSide(
          color: isSelected ? Colors.transparent : AppTheme.border,
          width: 1,
        ),
        onSelected: (val) {
          setState(() {
            _selectedClassificationFilter = code;
          });
        },
      ),
    );
  }

  Widget _buildIncidentCard(IncidentDossier inc, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? AppTheme.surfaceContainerHigh : AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? inc.classification.color : AppTheme.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedIncidentIndex = _incidents.indexOf(inc);
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: ID, Badge, Timestamp, Active Pin
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: inc.classification.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: inc.classification.color),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(inc.classification.icon, color: inc.classification.color, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          inc.classification.label,
                          style: TextStyle(
                            color: inc.classification.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    inc.id,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    inc.dgmsStatus.icon,
                    color: inc.dgmsStatus.color,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    inc.dgmsStatus.label,
                    style: TextStyle(
                      color: inc.dgmsStatus.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ACTIVE RCA',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                inc.title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),

              // Summary
              Text(
                inc.initialSummary,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Key metadata chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildTagBadge(Icons.location_on_rounded, inc.chainageLocation, AppTheme.textMuted),
                  _buildTagBadge(Icons.calendar_today_rounded, DateFormat('dd MMM yyyy HH:mm').format(inc.incidentTime), AppTheme.textMuted),
                  _buildTagBadge(Icons.speed_rounded, inc.severity.label, inc.severity.color),
                  _buildTagBadge(Icons.shield_rounded, inc.stage.label, inc.stage.color),
                  if (inc.dgmsAckNumber != null)
                    _buildTagBadge(Icons.check_circle_rounded, 'DGMS Ack: ${inc.dgmsAckNumber}', const Color(0xFF10B981)),
                ],
              ),
              const SizedBox(height: 12),

              // Footer row with quick action stats
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_tree_rounded, size: 14, color: AppTheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${inc.fiveWhys.length} Whys',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.schema_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      '${inc.fishboneFactors.length} Ishikawa Factors',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.pending_actions_rounded, size: 14, color: Color(0xFFF97316)),
                    const SizedBox(width: 4),
                    Text(
                      '${inc.capaItems.length} CAPAs',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      isSelected ? 'CURRENTLY VIEWING' : 'TAP TO SELECT',
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: 5-WHYS ROOT CAUSE ANALYSIS TREE
  // ============================================================================

  Widget _buildFiveWhysTab() {
    final inc = _currentIncident;
    final whys = inc.fiveWhys;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Case Context
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_tree_rounded, color: AppTheme.secondary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '5-WHYS ROOT CAUSE INVESTIGATION ENGINE',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            'OISD-GDN-107 Clause 6.4: Iterative causal progression to underlying organizational deficiency',
                            style: TextStyle(
                              color: AppTheme.textMuted.withValues(alpha: 0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('ADD WHY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _showAddWhyDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'INCIDENT UNDER ANALYSIS: ${inc.id} — ${inc.title}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5-Whys Progressive Step Nodes
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: whys.length,
            itemBuilder: (context, index) {
              final step = whys[index];
              final isLast = index == whys.length - 1;
              return _buildWhyNode(step, index + 1, isLast);
            },
          ),

          const SizedBox(height: 16),

          // Root Cause Synthesis Box
          if (whys.any((w) => w.isRootCause)) ...[
            _buildRootCauseSummaryBox(whys.firstWhere((w) => w.isRootCause)),
          ],
        ],
      ),
    );
  }

  Widget _buildWhyNode(FiveWhysStep step, int index, bool isLast) {
    final isRoot = step.isRootCause;
    final nodeColor = isRoot ? const Color(0xFFEF4444) : (index == 1 ? AppTheme.primaryLight : AppTheme.secondary);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Step Number Badge and Timeline Bar
            Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: nodeColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: nodeColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      'W$index',
                      style: TextStyle(
                        color: nodeColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2.5,
                    height: 90,
                    color: AppTheme.border,
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Card Body
            Expanded(
              child: Card(
                color: isRoot ? const Color(0xFF2A1515) : AppTheme.surfaceCard,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isRoot ? const Color(0xFFEF4444) : AppTheme.border,
                    width: isRoot ? 1.8 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question and Tag
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.question,
                              style: TextStyle(
                                color: nodeColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: nodeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              step.categoryTag,
                              style: TextStyle(
                                color: nodeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Response
                      Text(
                        step.response,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                      if (isRoot) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user_rounded, color: Color(0xFFEF4444), size: 14),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'VALIDATED STATUTORY ROOT CAUSE PER OISD-GDN-107',
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRootCauseSummaryBox(FiveWhysStep rootStep) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: AppTheme.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'SYSTEMIC ROOT CAUSE CONCLUSION',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rootStep.response,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Recommended Remedial Focus: Mandatory Management of Change (MOC) interlock enforcement and cross-functional digital gatekeeper barrier.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: 6M FISHBONE / ISHIKAWA CAUSE & EFFECT ENGINE
  // ============================================================================

  Widget _buildFishboneTab() {
    final inc = _currentIncident;
    final factors = inc.fishboneFactors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.schema_rounded, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ISHIKAWA 6M CAUSE-AND-EFFECT ENGINE',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        'Systematic breakdown: Man, Machine, Method, Material, Measurement, Milieu',
                        style: TextStyle(
                          color: AppTheme.textMuted.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('ATTACH FACTOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: _showAddFishboneCauseDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Central Ishikawa Spine Visual Representation
          _buildFishboneDiagramVisual(factors),

          const SizedBox(height: 20),

          // 6M Category Selector Chips
          const Text(
            'SELECT 6M BONE TO INSPECT / AUDIT FACTORS:',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: IshikawaCategory.values.map((cat) {
                final count = factors.where((f) => f.category == cat).length;
                final isSelected = _selectedIshikawaCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _selectedIshikawaCategory = cat;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? cat.color.withValues(alpha: 0.2) : AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? cat.color : AppTheme.border,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, color: cat.color, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            cat.title.split(' ').first,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: cat.color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Factors in Selected Category
          _buildFactorsListForCategory(_selectedIshikawaCategory, factors),
        ],
      ),
    );
  }

  Widget _buildFishboneDiagramVisual(List<FishboneFactor> factors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Top 3 Bones: Man, Machine, Method
          Row(
            children: [
              Expanded(child: _buildBoneHeader(IshikawaCategory.man, factors, isTop: true)),
              Expanded(child: _buildBoneHeader(IshikawaCategory.machine, factors, isTop: true)),
              Expanded(child: _buildBoneHeader(IshikawaCategory.method, factors, isTop: true)),
            ],
          ),
          const SizedBox(height: 8),

          // Main Horizontal Spine
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Fish Head / Effect Node
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dangerous_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'INCIDENT EVENT',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bottom 3 Bones: Material, Measurement, Milieu
          Row(
            children: [
              Expanded(child: _buildBoneHeader(IshikawaCategory.material, factors, isTop: false)),
              Expanded(child: _buildBoneHeader(IshikawaCategory.measurement, factors, isTop: false)),
              Expanded(child: _buildBoneHeader(IshikawaCategory.milieu, factors, isTop: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoneHeader(IshikawaCategory cat, List<FishboneFactor> factors, {required bool isTop}) {
    final catFactors = factors.where((f) => f.category == cat).toList();
    final hasRoot = catFactors.any((f) => f.isPrimaryRootCause);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIshikawaCategory = cat;
        });
      },
      child: Column(
        children: [
          if (isTop) ...[
            Text(
              cat.title.split(' ').first.toUpperCase(),
              style: TextStyle(
                color: hasRoot ? const Color(0xFFEF4444) : cat.color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${catFactors.length} items',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
            ),
            const SizedBox(height: 4),
            Container(width: 2, height: 20, color: cat.color),
          ] else ...[
            Container(width: 2, height: 20, color: cat.color),
            const SizedBox(height: 4),
            Text(
              cat.title.split(' ').first.toUpperCase(),
              style: TextStyle(
                color: hasRoot ? const Color(0xFFEF4444) : cat.color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${catFactors.length} items',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFactorsListForCategory(IshikawaCategory category, List<FishboneFactor> factors) {
    final items = factors.where((f) => f.category == category).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: category.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(category.icon, color: category.color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title.toUpperCase(),
                      style: TextStyle(
                        color: category.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      category.subtitle,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Text(
              'No factors recorded under ${category.title} yet. Tap "ATTACH FACTOR" to add.',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final factor = items[index];
              return Card(
                color: factor.isPrimaryRootCause ? const Color(0xFF2A1515) : AppTheme.surfaceCard,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: factor.isPrimaryRootCause ? const Color(0xFFEF4444) : AppTheme.border,
                    width: factor.isPrimaryRootCause ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          factor.id,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    factor.title,
                                    style: TextStyle(
                                      color: factor.isPrimaryRootCause ? const Color(0xFFEF4444) : AppTheme.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (factor.isPrimaryRootCause)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'PRIMARY ROOT CAUSE',
                                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              factor.description,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.35),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text(
                                  'Severity Impact: ',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                ),
                                ...List.generate(5, (starIdx) {
                                  final isLit = starIdx < factor.severityScore;
                                  return Icon(
                                    Icons.lens,
                                    size: 8,
                                    color: isLit
                                        ? (factor.isPrimaryRootCause ? const Color(0xFFEF4444) : AppTheme.secondary)
                                        : AppTheme.border,
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ============================================================================
  // TAB 4: CORRECTIVE AND PREVENTIVE ACTION (CAPA) MATRIX
  // ============================================================================

  Widget _buildCapaTab() {
    final inc = _currentIncident;
    final capas = inc.capaItems;

    int openCount = capas.where((c) => c.status == CapaStatus.open).length;
    int inProgressCount = capas.where((c) => c.status == CapaStatus.inProgress).length;
    int closedCount = capas.where((c) => c.status == CapaStatus.closed).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.task_alt_rounded, color: Color(0xFFF97316), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CAPA ACTION TRACKER & STATUTORY CONTROLS',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        'ISO 45001 / OISD-GDN-107: Hierarchy of Controls with designated ownership & SLA closure',
                        style: TextStyle(
                          color: AppTheme.textMuted.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('NEW CAPA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: _showAddCapaDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Status Progress Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'CAPA IMPLEMENTATION VELOCITY',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      '$closedCount of ${capas.length} Closed',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        if (closedCount > 0)
                          Expanded(
                            flex: closedCount,
                            child: Container(color: const Color(0xFF10B981)),
                          ),
                        if (inProgressCount > 0)
                          Expanded(
                            flex: inProgressCount,
                            child: Container(color: const Color(0xFFFFB95F)),
                          ),
                        if (openCount > 0)
                          Expanded(
                            flex: openCount,
                            child: Container(color: const Color(0xFFEF4444)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusPill('Open: $openCount', const Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    _buildStatusPill('In Progress: $inProgressCount', const Color(0xFFFFB95F)),
                    const SizedBox(width: 8),
                    _buildStatusPill('Closed: $closedCount', const Color(0xFF10B981)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CAPA Items List
          if (capas.isEmpty)
            _buildEmptyState('No CAPA items defined. Tap "NEW CAPA" to add remedial mandates.')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: capas.length,
              itemBuilder: (context, index) {
                final capa = capas[index];
                return _buildCapaCard(capa);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCapaCard(CapaItem item) {
    final isClosed = item.status == CapaStatus.closed;

    return Card(
      color: AppTheme.surfaceCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: item.status.color.withValues(alpha: 0.6), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: ID, Preventive vs Corrective, Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: (item.isPreventive ? AppTheme.primary : AppTheme.secondary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.isPreventive ? 'PREVENTIVE ACTION' : 'CORRECTIVE ACTION',
                    style: TextStyle(
                      color: item.isPreventive ? AppTheme.primaryLight : AppTheme.secondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.id,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    // Toggle Status
                    final newStatus = item.status == CapaStatus.open
                        ? CapaStatus.inProgress
                        : (item.status == CapaStatus.inProgress ? CapaStatus.closed : CapaStatus.open);
                    final inc = _currentIncident;
                    final updated = inc.capaItems.map((c) => c.id == item.id ? c.copyWith(status: newStatus) : c).toList();
                    setState(() {
                      _incidents[_selectedIncidentIndex] = inc.copyWith(capaItems: updated);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: item.status.color),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.status.icon, color: item.status.color, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          item.status.label.toUpperCase(),
                          style: TextStyle(
                            color: item.status.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              item.title,
              style: TextStyle(
                color: isClosed ? AppTheme.textSecondary : AppTheme.textPrimary,
                decoration: isClosed ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              item.description,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 10),

            // Hierarchy and Owner Chips
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.hierarchy.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.hierarchy.label,
                    style: TextStyle(color: item.hierarchy.color, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.person_rounded, size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${item.ownerName} (${item.ownerRole})',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.event_rounded, size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(item.targetDate),
                  style: TextStyle(
                    color: item.targetDate.isBefore(_currentTime) && !isClosed ? const Color(0xFFEF4444) : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (item.completionNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'VERIFICATION: ${item.completionNotes}',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 5: FORENSIC EVIDENCE VAULT (METALLURGY, WITNESS STATEMENTS, SENSORS)
  // ============================================================================

  Widget _buildEvidenceVaultTab() {
    final inc = _currentIncident;
    final records = inc.evidenceVault;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.enhanced_encryption_rounded, color: Color(0xFFA855F7), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FORENSIC EVIDENCE VAULT & LAB AUDIT',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        'OISD-GDN-107 Section 6.3: Chain-of-custody, Metallurgy reports & SHA-256 seals',
                        style: TextStyle(
                          color: AppTheme.textMuted.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('DEPOSIT EVIDENCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: _showAddEvidenceDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (records.isEmpty)
            _buildEmptyState('No forensic records secured in vault yet. Tap "DEPOSIT EVIDENCE" to preserve items.')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final rec = records[index];
                return _buildEvidenceCard(rec);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(EvidenceRecord rec) {
    return Card(
      color: AppTheme.surfaceCard,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: rec.category.color.withValues(alpha: 0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type, Tamper Seal, ID
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rec.category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(rec.category.icon, color: rec.category.color, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rec.category.label.toUpperCase(),
                        style: TextStyle(
                          color: rec.category.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  rec.id,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 11, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        rec.tamperSealTag,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              rec.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),

            // Summary
            Text(
              rec.summary,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),

            // Cryptographic SHA-256 Custody Hash Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  const Text(
                    'SHA-256: ',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      rec.sha256Hash,
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Technical Metadata Grid
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: rec.technicalMetadata.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            entry.key,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // SHARED EMPTY STATE & UTILITIES
  // ============================================================================

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFab() {
    return FloatingActionButton.extended(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.share_rounded, size: 18),
      label: const Text(
        'OISD DOSSIER',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
      ),
      onPressed: _exportDossierReport,
    );
  }
}

// ============================================================================
// REUSABLE STATIC BADGE
// ============================================================================

class _StaticBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StaticBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
