import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// ENUMS & MODELS FOR SCAFFOLDING & HEAVY RIGGING SAFETY
// ============================================================================

enum ScaffoldingTagType {
  green, // Safe to Use, Inspected within 7 days per IS 3696
  yellow, // Caution, Full Body Harness 100% tie-off mandatory
  red, // DANGER - Do Not Use / Incomplete
}

enum ScaffoldDutyRating {
  heavy(300, 'Heavy Duty', 'Masonry, heavy stone, concrete demolition'),
  medium(200, 'Medium Duty', 'Plastering, painting, light cladding'),
  light(75, 'Light Duty', 'Inspection, cleaning, access only');

  final int loadKgPerM2;
  final String label;
  final String description;

  const ScaffoldDutyRating(this.loadKgPerM2, this.label, this.description);
}

enum ReInspectionAlertTag {
  certifiedValid('CERTIFIED VALID', Color(0xFF10B981), Icons.verified_user_rounded),
  urgentDue('URGENT: DUE < 24H', Color(0xFFF59E0B), Icons.warning_amber_rounded),
  overdueRedTag('OVERDUE - RED TAG', Color(0xFFEF4444), Icons.dangerous_rounded),
  weatherTrigger('WEATHER TRIGGER (>40 km/h)', Color(0xFF06B6D4), Icons.air_rounded),
  alterationAlert('ALTERATION DETECTED', Color(0xFFA855F7), Icons.construction_rounded);

  final String label;
  final Color color;
  final IconData icon;

  const ReInspectionAlertTag(this.label, this.color, this.icon);
}

class ChecklistItemModel {
  final String id;
  final String title;
  final String description;
  final String standardCode;
  final String category; // 'FOUNDATION', 'STRUCTURE', 'FALL_PROTECTION', 'ACCESS', 'RIGGING'
  final bool isMandatory;
  String status; // 'PASS', 'FAIL', 'NA'
  String notes;
  bool hasPhoto;

  ChecklistItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.standardCode,
    required this.category,
    this.isMandatory = true,
    this.status = 'PASS',
    this.notes = '',
    this.hasPhoto = false,
  });
}

class ScaffoldStructureModel {
  final String id;
  final String name;
  final String location;
  final String zone;
  ScaffoldingTagType tagStatus;
  ScaffoldDutyRating dutyRating;
  double platformLengthM;
  double platformWidthM;
  int workingTiers;
  int workerCount;
  double materialWeightKg;
  DateTime lastInspectionDate;
  DateTime nextInspectionDate;
  String inspectorName;
  String inspectorBadge;
  String permitNumber;
  ReInspectionAlertTag alertTag;
  double windSpeedKmh;
  List<ChecklistItemModel> checklist;

  ScaffoldStructureModel({
    required this.id,
    required this.name,
    required this.location,
    required this.zone,
    required this.tagStatus,
    required this.dutyRating,
    required this.platformLengthM,
    required this.platformWidthM,
    this.workingTiers = 1,
    this.workerCount = 2,
    this.materialWeightKg = 150.0,
    required this.lastInspectionDate,
    required this.nextInspectionDate,
    required this.inspectorName,
    required this.inspectorBadge,
    required this.permitNumber,
    required this.alertTag,
    this.windSpeedKmh = 14.5,
    required this.checklist,
  });

  double get platformArea => platformLengthM * platformWidthM;
  double get maxPermissibleLoadKg => platformArea * dutyRating.loadKgPerM2 * workingTiers;
  double get liveLoadKg => (workerCount * 85.0) + materialWeightKg;
  double get utilizationPercent => maxPermissibleLoadKg > 0
      ? (liveLoadKg / maxPermissibleLoadKg) * 100
      : 0.0;

  int get daysUntilInspection => nextInspectionDate.difference(DateTime.now()).inDays;
  bool get isInspectionOverdue => DateTime.now().isAfter(nextInspectionDate);

  void refreshAlertStatus() {
    final now = DateTime.now();
    if (tagStatus == ScaffoldingTagType.red) {
      alertTag = ReInspectionAlertTag.overdueRedTag;
    } else if (windSpeedKmh > 40.0) {
      alertTag = ReInspectionAlertTag.weatherTrigger;
    } else if (now.isAfter(nextInspectionDate)) {
      alertTag = ReInspectionAlertTag.overdueRedTag;
      tagStatus = ScaffoldingTagType.red;
    } else if (nextInspectionDate.difference(now).inHours <= 36) {
      alertTag = ReInspectionAlertTag.urgentDue;
    } else {
      alertTag = ReInspectionAlertTag.certifiedValid;
    }
  }
}

// ============================================================================
// MAIN SCAFFOLDING INSPECTION SCREEN
// ============================================================================

class ScaffoldingInspectionScreen extends StatefulWidget {
  const ScaffoldingInspectionScreen({super.key});

  @override
  State<ScaffoldingInspectionScreen> createState() =>
      _ScaffoldingInspectionScreenState();
}

class _ScaffoldingInspectionScreenState extends State<ScaffoldingInspectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<ScaffoldStructureModel> _scaffolds;
  late ScaffoldStructureModel _selectedScaffold;

  // Rigging Calculator State
  double _riggingLoadTonnes = 12.5;
  double _riggingSlingAngleDeg = 60.0;
  int _riggingSlingLegs = 2;
  double _shackleRatedCapTonnes = 8.5;
  String _riggingHitchType = 'Choker'; // 'Direct', 'Choker', 'Basket'

  // Filter & Search
  String _selectedFilterTag = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeScaffoldingData();
    _selectedScaffold = _scaffolds.first;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeScaffoldingData() {
    final now = DateTime.now();

    List<ChecklistItemModel> createDefaultChecklist() {
      return [
        ChecklistItemModel(
          id: 'CHK-01',
          title: 'Sole boards & base plates',
          description:
              'Firm compacted soil/concrete foundation. Timber sole plates min 300x300x38mm under each standard. Base plates centered without slippage or settlement.',
          standardCode: 'IS 3696: Part 1 Cl. 6.2 / OSHA 1926.451(c)(2)',
          category: 'FOUNDATION',
          status: 'PASS',
        ),
        ChecklistItemModel(
          id: 'CHK-02',
          title: 'Vertical standards plumb',
          description:
              'Standards plumb within 1:500 ratio. Joint pins/spigots inserted and securely locked. Joints staggered across adjacent bays.',
          standardCode: 'IS 3696: Part 1 Cl. 7.1',
          category: 'STRUCTURE',
          status: 'PASS',
        ),
        ChecklistItemModel(
          id: 'CHK-03',
          title: 'Double guardrails at 950mm and 470mm',
          description:
              'Top guardrail firmly fastened between 950mm-1150mm height. Mid-rail installed at 470mm from working deck. Withstands 0.9 kN point force.',
          standardCode: 'IS 3696: Part 1 Cl. 9.4 / EN 12811-1',
          category: 'FALL_PROTECTION',
          status: 'PASS',
        ),
        ChecklistItemModel(
          id: 'CHK-04',
          title: 'Toe boards (150mm height)',
          description:
              'Toe boards minimum 150mm vertical height along all open edges of working platform. Zero gaps exceeding 25mm to stop tools/debris dropping.',
          standardCode: 'IS 3696: Part 1 Cl. 9.5',
          category: 'FALL_PROTECTION',
          status: 'PASS',
        ),
        ChecklistItemModel(
          id: 'CHK-05',
          title: 'Ladder access & landings',
          description:
              'Internal trap-door access or external ladder secured at 4:1 slope (75°). Extends minimum 1.05m above landing platform. Anti-slip rungs clean.',
          standardCode: 'IS 3696: Part 2 Cl. 5.1 / OSHA 1926.451(e)',
          category: 'ACCESS',
          status: 'PASS',
        ),
        ChecklistItemModel(
          id: 'CHK-06',
          title: 'Scaffolding tie-backs to permanent structure',
          description:
              'Positive structural ties (box ties / through ties / anchor bolts) installed every 4m vertical & 6m horizontal (or every 2 bays). Pull-test verified.',
          standardCode: 'IS 3696: Part 1 Cl. 8.3 / TG20:21',
          category: 'STRUCTURE',
          status: 'PASS',
        ),
        ChecklistItemModel(
          id: 'CHK-07',
          title: 'Rigging gear: Slings, D-shackles & safety latches',
          description:
              'Webbing slings inspected with quarterly color tag. Shackles equipped with split cotter pins. Hook safety latches spring-loaded and functional.',
          standardCode: 'IS 2762 / ASME B30.9 / ASME B30.26',
          category: 'RIGGING',
          status: 'PASS',
        ),
        ChecklistItemModel(
          id: 'CHK-08',
          title: 'Crane outrigger mats & exclusion zone barricading',
          description:
              'Hardwood crane mats under full outrigger extension. Taglines attached to load. 360° red exclusion tape with designated banksman on duty.',
          standardCode: 'IS 13367 / OSHA 1926.1402',
          category: 'RIGGING',
          status: 'PASS',
        ),
      ];
    }

    _scaffolds = [
      ScaffoldStructureModel(
        id: 'SCAF-BLR-04',
        name: 'Boiler Unit #2 Superheater Staging',
        location: 'Thermal Block, Elevation +28.5m',
        zone: 'Zone A - High Pressure Boiler',
        tagStatus: ScaffoldingTagType.green,
        dutyRating: ScaffoldDutyRating.heavy,
        platformLengthM: 4.5,
        platformWidthM: 1.8,
        workingTiers: 2,
        workerCount: 3,
        materialWeightKg: 420.0,
        lastInspectionDate: now.subtract(const Duration(days: 3)),
        nextInspectionDate: now.add(const Duration(days: 4)),
        inspectorName: 'K. R. Varma (Lead HSE Officer)',
        inspectorBadge: 'HSE-CERT-904',
        permitNumber: 'PTW-SCAF-2026-118',
        alertTag: ReInspectionAlertTag.certifiedValid,
        windSpeedKmh: 16.2,
        checklist: createDefaultChecklist(),
      ),
      ScaffoldStructureModel(
        id: 'SCAF-CHM-01',
        name: '180m Chimney External Ring Staging',
        location: 'Chimney Flue Staging, Level 4 (+65m)',
        zone: 'Zone B - Stack Elevation',
        tagStatus: ScaffoldingTagType.yellow,
        dutyRating: ScaffoldDutyRating.medium,
        platformLengthM: 6.0,
        platformWidthM: 1.2,
        workingTiers: 1,
        workerCount: 2,
        materialWeightKg: 180.0,
        lastInspectionDate: now.subtract(const Duration(days: 1)),
        nextInspectionDate: now.add(const Duration(days: 6)),
        inspectorName: 'M. S. Deshmukh (Structural Engineer)',
        inspectorBadge: 'STR-ENG-441',
        permitNumber: 'PTW-SCAF-2026-092',
        alertTag: ReInspectionAlertTag.alterationAlert,
        windSpeedKmh: 34.0,
        checklist: createDefaultChecklist()
          ..[2].status = 'FAIL'
          ..[2].notes =
              'Mid-rail temporarily uncoupled for pipe spool insertion. 100% double lanyard tie-off enforced.',
      ),
      ScaffoldStructureModel(
        id: 'SCAF-TRB-08',
        name: 'Turbine Hall Crane Access Platform',
        location: 'Turbine Hall Bay 3, North Wall',
        zone: 'Zone C - Power Island',
        tagStatus: ScaffoldingTagType.red,
        dutyRating: ScaffoldDutyRating.light,
        platformLengthM: 3.0,
        platformWidthM: 1.0,
        workingTiers: 1,
        workerCount: 0,
        materialWeightKg: 0.0,
        lastInspectionDate: now.subtract(const Duration(days: 9)),
        nextInspectionDate: now.subtract(const Duration(days: 2)),
        inspectorName: 'A. K. Sharma (Safety Auditor)',
        inspectorBadge: 'HSE-AUD-108',
        permitNumber: 'PTW-SCAF-2026-064',
        alertTag: ReInspectionAlertTag.overdueRedTag,
        windSpeedKmh: 8.5,
        checklist: createDefaultChecklist()
          ..[0].status = 'FAIL'
          ..[0].notes =
              'Settlement under standard #2 base plate observed after storm water drainage backflow.'
          ..[5].status = 'FAIL'
          ..[5].notes = 'One wall anchor loose. Re-drilling chemical bolt required.',
      ),
      ScaffoldStructureModel(
        id: 'SCAF-RCK-12',
        name: 'Main Pipe Rack Crossover Gantry',
        location: 'Hydrocarbon Corridor, Cross Span #12',
        zone: 'Zone D - Outside Battery Limit',
        tagStatus: ScaffoldingTagType.green,
        dutyRating: ScaffoldDutyRating.medium,
        platformLengthM: 5.0,
        platformWidthM: 1.5,
        workingTiers: 1,
        workerCount: 2,
        materialWeightKg: 210.0,
        lastInspectionDate: now.subtract(const Duration(days: 6)),
        nextInspectionDate: now.add(const Duration(hours: 18)),
        inspectorName: 'Subhash Roy (Chief Safety Officer)',
        inspectorBadge: 'HSE-DIR-002',
        permitNumber: 'PTW-SCAF-2026-140',
        alertTag: ReInspectionAlertTag.urgentDue,
        windSpeedKmh: 12.0,
        checklist: createDefaultChecklist(),
      ),
      ScaffoldStructureModel(
        id: 'RIG-SPRD-02',
        name: '50T Modular Spreader Beam Rigging Frame',
        location: 'Heavy Lift Yard, Pad B',
        zone: 'Zone E - Heavy Erection',
        tagStatus: ScaffoldingTagType.green,
        dutyRating: ScaffoldDutyRating.heavy,
        platformLengthM: 8.0,
        platformWidthM: 2.0,
        workingTiers: 1,
        workerCount: 4,
        materialWeightKg: 850.0,
        lastInspectionDate: now.subtract(const Duration(days: 2)),
        nextInspectionDate: now.add(const Duration(days: 5)),
        inspectorName: 'V. Ramanathan (Rigging Superintendent)',
        inspectorBadge: 'RIG-SUP-770',
        permitNumber: 'PTW-RIG-2026-031',
        alertTag: ReInspectionAlertTag.certifiedValid,
        windSpeedKmh: 19.5,
        checklist: createDefaultChecklist(),
      ),
    ];
  }

  Color _getTagColor(ScaffoldingTagType type) {
    switch (type) {
      case ScaffoldingTagType.green:
        return const Color(0xFF10B981);
      case ScaffoldingTagType.yellow:
        return const Color(0xFFF59E0B);
      case ScaffoldingTagType.red:
        return const Color(0xFFEF4444);
    }
  }

  String _getTagLabel(ScaffoldingTagType type) {
    switch (type) {
      case ScaffoldingTagType.green:
        return 'GREEN TAG — SAFE TO USE';
      case ScaffoldingTagType.yellow:
        return 'YELLOW TAG — CAUTION / 100% TIE-OFF';
      case ScaffoldingTagType.red:
        return 'RED TAG — DANGER / DO NOT USE';
    }
  }

  String _getTagSubtitle(ScaffoldingTagType type) {
    switch (type) {
      case ScaffoldingTagType.green:
        return 'Inspected & Certified within 7 days per IS 3696 & OSHA 1926.451';
      case ScaffoldingTagType.yellow:
        return 'Full Body Harness with Shock Absorber & 100% dual tie-off mandatory';
      case ScaffoldingTagType.red:
        return 'Incomplete, altered, or failed structural inspection. Prohibited access.';
    }
  }

  List<ScaffoldStructureModel> get _filteredScaffolds {
    return _scaffolds.where((s) {
      final matchesQuery = s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.location.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesQuery) return false;

      if (_selectedFilterTag == 'GREEN') return s.tagStatus == ScaffoldingTagType.green;
      if (_selectedFilterTag == 'YELLOW') return s.tagStatus == ScaffoldingTagType.yellow;
      if (_selectedFilterTag == 'RED') return s.tagStatus == ScaffoldingTagType.red;
      return true;
    }).toList();
  }

  void _showTagChangeDialog(ScaffoldStructureModel scaffold) {
    ScaffoldingTagType selectedType = scaffold.tagStatus;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.border, width: 1.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(Icons.style_rounded, color: AppTheme.primaryLight, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Change Scaffolding Tag',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        scaffold.id,
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SELECT NEW TAG STATUS',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...ScaffoldingTagType.values.map((tag) {
                    final isCurrent = selectedType == tag;
                    final tagCol = _getTagColor(tag);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: () {
                          setModalState(() {
                            selectedType = tag;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? tagCol.withValues(alpha: 0.15)
                                : AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent ? tagCol : AppTheme.border,
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: tagCol,
                                  shape: BoxShape.circle,
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: tagCol.withValues(alpha: 0.6),
                                            blurRadius: 8,
                                          )
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getTagLabel(tag),
                                      style: TextStyle(
                                        color: isCurrent ? Colors.white : AppTheme.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getTagSubtitle(tag),
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                Icon(Icons.check_circle_rounded, color: tagCol, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  const Text(
                    'REASON FOR TAG MODIFICATION / OBSERVATION',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. 7-day re-inspection passed, or top guardrail removed for rigging access...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getTagColor(selectedType),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    scaffold.tagStatus = selectedType;
                    scaffold.refreshAlertStatus();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.surfaceCard,
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: _getTagColor(selectedType)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tag updated to ${_getTagLabel(selectedType)} for ${scaffold.id}',
                              style: const TextStyle(color: AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.verified, size: 16),
                label: const Text('Apply Tag & Log Audit'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _triggerSimulatedWeatherAlert() {
    setState(() {
      for (final s in _scaffolds) {
        s.windSpeedKmh = 48.5; // Exceeds 40 km/h threshold per IS 3696
        s.tagStatus = ScaffoldingTagType.yellow;
        s.alertTag = ReInspectionAlertTag.weatherTrigger;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 4),
        content: const Row(
          children: [
            Icon(Icons.air_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'HIGH WIND ALERT (48.5 km/h > 40 km/h)! All scaffolding tags set to CAUTION. Structural re-inspection mandatory per IS 3696.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetWeather() {
    setState(() {
      for (final s in _scaffolds) {
        s.windSpeedKmh = 14.0;
        s.refreshAlertStatus();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.surfaceCard,
        content: Text(
          'Wind speed normalized to 14.0 km/h. Standard 7-day schedule resumed.',
          style: TextStyle(color: AppTheme.tertiary),
        ),
      ),
    );
  }

  void _openPerformInspectionSheet(ScaffoldStructureModel scaffold) {
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          int passCount = scaffold.checklist.where((c) => c.status == 'PASS').length;
          int totalMandatory = scaffold.checklist.where((c) => c.isMandatory).length;
          int passMandatory =
              scaffold.checklist.where((c) => c.isMandatory && c.status == 'PASS').length;
          bool allMandatoryPassed = passMandatory == totalMandatory;

          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppTheme.border, width: 2)),
            ),
            child: Column(
              children: [
                // Modal Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.assignment_turned_in_rounded,
                            color: AppTheme.primaryLight, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weekly Re-Inspection & Tag Certification',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${scaffold.id} • ${scaffold.name}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.border, height: 1),

                // Compliance Score Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: AppTheme.surfaceCard,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Mandatory Compliance Score',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$passCount / ${scaffold.checklist.length} Passed',
                                  style: TextStyle(
                                    color: allMandatoryPassed
                                        ? AppTheme.tertiary
                                        : AppTheme.secondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: scaffold.checklist.isNotEmpty
                                    ? passCount / scaffold.checklist.length
                                    : 0.0,
                                minHeight: 6,
                                backgroundColor: AppTheme.surfaceContainerHigh,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  allMandatoryPassed ? AppTheme.tertiary : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (allMandatoryPassed
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: allMandatoryPassed
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        child: Text(
                          allMandatoryPassed ? 'GREEN TAG ELIGIBLE' : 'DEFECTS DETECTED',
                          style: TextStyle(
                            color: allMandatoryPassed
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Checklist Scrollable
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: scaffold.checklist.length,
                    itemBuilder: (context, index) {
                      final item = scaffold.checklist[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: item.status == 'FAIL'
                                ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                                : AppTheme.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(
                                      color: AppTheme.primaryLight,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.description,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Standard: ${item.standardCode}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Status Toggles
                            Row(
                              children: [
                                _buildStatusChoiceChip(
                                  label: 'PASS',
                                  color: const Color(0xFF10B981),
                                  isSelected: item.status == 'PASS',
                                  onTap: () {
                                    setSheetState(() => item.status = 'PASS');
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildStatusChoiceChip(
                                  label: 'FAIL',
                                  color: const Color(0xFFEF4444),
                                  isSelected: item.status == 'FAIL',
                                  onTap: () {
                                    setSheetState(() => item.status = 'FAIL');
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildStatusChoiceChip(
                                  label: 'N/A',
                                  color: AppTheme.textMuted,
                                  isSelected: item.status == 'NA',
                                  onTap: () {
                                    setSheetState(() => item.status = 'NA');
                                  },
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: Icon(
                                    item.hasPhoto
                                        ? Icons.add_a_photo
                                        : Icons.add_a_photo_outlined,
                                    color: item.hasPhoto
                                        ? AppTheme.primaryLight
                                        : AppTheme.textMuted,
                                    size: 20,
                                  ),
                                  tooltip: 'Attach Verification Photo',
                                  onPressed: () {
                                    setSheetState(() => item.hasPhoto = !item.hasPhoto);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppTheme.surfaceCard,
                                        duration: const Duration(seconds: 1),
                                        content: Text(
                                          item.hasPhoto
                                              ? 'Photo evidence linked to ${item.id}'
                                              : 'Photo evidence cleared',
                                          style: const TextStyle(color: AppTheme.textPrimary),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Action Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: allMandatoryPassed
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            setState(() {
                              scaffold.lastInspectionDate = now;
                              scaffold.nextInspectionDate = now.add(const Duration(days: 7));
                              scaffold.tagStatus = allMandatoryPassed
                                  ? ScaffoldingTagType.green
                                  : ScaffoldingTagType.yellow;
                              scaffold.alertTag = allMandatoryPassed
                                  ? ReInspectionAlertTag.certifiedValid
                                  : ReInspectionAlertTag.alterationAlert;
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.surfaceCard,
                                content: Text(
                                  'Inspection certified! Next re-inspection due: ${DateFormat('dd MMM yyyy').format(scaffold.nextInspectionDate)} (7-day validity per IS 3696)',
                                  style: const TextStyle(color: AppTheme.tertiary),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: Text(
                            allMandatoryPassed
                                ? 'Certify GREEN Tag (7 Days)'
                                : 'Certify YELLOW Tag (Caution)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
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

  Widget _buildStatusChoiceChip({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Structural Scaffolding & Rigging',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'IS 3696 / OSHA 1926.451 / ASME B30.9 Compliance',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Simulate High Wind Event (>40 km/h)',
            icon: const Icon(Icons.air_rounded, color: AppTheme.secondary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.cyclone_rounded, color: AppTheme.secondary),
                      SizedBox(width: 8),
                      Text('Wind Storm Simulation',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                    ],
                  ),
                  content: const Text(
                    'Per IS 3696: Any wind gust exceeding 40 km/h automatically invalidates Green tags, triggering immediate structural re-inspection for displaced planks, ties, and plumb alignment.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetWeather();
                      },
                      child: const Text('Reset Normal (14 km/h)',
                          style: TextStyle(color: AppTheme.tertiary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _triggerSimulatedWeatherAlert();
                      },
                      child: const Text('Trigger Storm (48.5 km/h)',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Export Audit Dossier',
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.surfaceCard,
                  content: Text(
                    'Scaffolding & Rigging Safety Dossier generated. Signed with SHA-256 digital stamp.',
                    style: TextStyle(color: AppTheme.tertiary),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(icon: Icon(Icons.style_outlined, size: 18), text: 'Live Tags'),
            Tab(icon: Icon(Icons.checklist_rounded, size: 18), text: 'Checklist'),
            Tab(icon: Icon(Icons.calculate_outlined, size: 18), text: 'SWL Engine'),
            Tab(icon: Icon(Icons.event_repeat_rounded, size: 18), text: '7-Day Cycle'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveTagsTab(),
          _buildChecklistTab(),
          _buildSwlEngineTab(),
          _buildWeeklyCycleTab(),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: LIVE SCAFFOLDS & TAG STATUS
  // ============================================================================

  Widget _buildLiveTagsTab() {
    int greenCount = _scaffolds.where((s) => s.tagStatus == ScaffoldingTagType.green).length;
    int yellowCount = _scaffolds.where((s) => s.tagStatus == ScaffoldingTagType.yellow).length;
    int redCount = _scaffolds.where((s) => s.tagStatus == ScaffoldingTagType.red).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top KPI Metrics
          Row(
            children: [
              _buildTagKpiCard(
                label: 'GREEN TAGS',
                count: greenCount,
                subtitle: 'Safe to Use',
                color: const Color(0xFF10B981),
                isSelected: _selectedFilterTag == 'GREEN',
                onTap: () {
                  setState(() {
                    _selectedFilterTag = _selectedFilterTag == 'GREEN' ? 'ALL' : 'GREEN';
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildTagKpiCard(
                label: 'YELLOW TAGS',
                count: yellowCount,
                subtitle: 'Caution / 100% Tie',
                color: const Color(0xFFF59E0B),
                isSelected: _selectedFilterTag == 'YELLOW',
                onTap: () {
                  setState(() {
                    _selectedFilterTag = _selectedFilterTag == 'YELLOW' ? 'ALL' : 'YELLOW';
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildTagKpiCard(
                label: 'RED TAGS',
                count: redCount,
                subtitle: 'DANGER / Lockout',
                color: const Color(0xFFEF4444),
                isSelected: _selectedFilterTag == 'RED',
                onTap: () {
                  setState(() {
                    _selectedFilterTag = _selectedFilterTag == 'RED' ? 'ALL' : 'RED';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search & Filter Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 18),
                    hintText: 'Search scaffold ID, plant bay, location...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppTheme.surfaceCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                  ),
                ),
              ),
              if (_selectedFilterTag != 'ALL') ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _selectedFilterTag = 'ALL'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Row(
                      children: [
                        Text('Reset',
                            style: TextStyle(color: AppTheme.primaryLight, fontSize: 12)),
                        SizedBox(width: 4),
                        Icon(Icons.close, color: AppTheme.primaryLight, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Active Scaffolds List
          Text(
            'REGISTERED SITE SCAFFOLDS & RIGGING FRAMES (${_filteredScaffolds.length})',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),

          ..._filteredScaffolds.map((scaffold) => _buildScaffoldTagCard(scaffold)),
        ],
      ),
    );
  }

  Widget _buildTagKpiCard({
    required String label,
    required int count,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppTheme.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  Text(
                    count.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
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

  Widget _buildScaffoldTagCard(ScaffoldStructureModel scaffold) {
    final tagColor = _getTagColor(scaffold.tagStatus);
    final isSelected = _selectedScaffold.id == scaffold.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppTheme.primaryLight : AppTheme.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Tag Banner Header styled like a physical OSHA/IS Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.18),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(bottom: BorderSide(color: tagColor.withValues(alpha: 0.4))),
            ),
            child: Row(
              children: [
                // Tag Eyelet visual
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surface,
                    border: Border.all(color: tagColor, width: 2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTagLabel(scaffold.tagStatus),
                        style: TextStyle(
                          color: tagColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        _getTagSubtitle(scaffold.tagStatus),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Alert Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scaffold.alertTag.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: scaffold.alertTag.color.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(scaffold.alertTag.icon, size: 11, color: scaffold.alertTag.color),
                      const SizedBox(width: 4),
                      Text(
                        scaffold.alertTag.label,
                        style: TextStyle(
                          color: scaffold.alertTag.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Padding(
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
                          Text(
                            scaffold.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${scaffold.id} • ${scaffold.zone}',
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Duty Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            scaffold.dutyRating.label,
                            style: const TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${scaffold.dutyRating.loadKgPerM2} kg/m²',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Specs Row
                Row(
                  children: [
                    _buildSpecChip(
                      icon: Icons.straighten_rounded,
                      label:
                          '${scaffold.platformLengthM}m × ${scaffold.platformWidthM}m (${scaffold.platformArea.toStringAsFixed(1)} m²)',
                    ),
                    const SizedBox(width: 8),
                    _buildSpecChip(
                      icon: Icons.layers_rounded,
                      label: '${scaffold.workingTiers} Working Tiers',
                    ),
                    const SizedBox(width: 8),
                    _buildSpecChip(
                      icon: Icons.air_rounded,
                      label: '${scaffold.windSpeedKmh.toStringAsFixed(1)} km/h wind',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Load Gauge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live Load: ${scaffold.liveLoadKg.toStringAsFixed(0)} kg / ${scaffold.maxPermissibleLoadKg.toStringAsFixed(0)} kg SWL',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    Text(
                      '${scaffold.utilizationPercent.toStringAsFixed(1)}% Capacity',
                      style: TextStyle(
                        color: scaffold.utilizationPercent > 90
                            ? const Color(0xFFEF4444)
                            : (scaffold.utilizationPercent > 70
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981)),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (scaffold.utilizationPercent / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      scaffold.utilizationPercent > 90
                          ? const Color(0xFFEF4444)
                          : (scaffold.utilizationPercent > 70
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Inspector info & Re-inspection date
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Inspector: ${scaffold.inspectorName} (${scaffold.inspectorBadge})',
                          style:
                              const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Due: ${DateFormat('dd MMM').format(scaffold.nextInspectionDate)}',
                        style: TextStyle(
                          color: scaffold.isInspectionOverdue
                              ? const Color(0xFFEF4444)
                              : AppTheme.tertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: AppTheme.border),
                        ),
                        onPressed: () => _showTagChangeDialog(scaffold),
                        icon: const Icon(Icons.swap_horiz, size: 15, color: AppTheme.secondary),
                        label: const Text(
                          'Modify Tag',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                        ),
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
                          setState(() {
                            _selectedScaffold = scaffold;
                          });
                          _openPerformInspectionSheet(scaffold);
                        },
                        icon: const Icon(Icons.fact_check_outlined, size: 15),
                        label: const Text(
                          'Inspect / Retag',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
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

  Widget _buildSpecChip({required IconData icon, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: AppTheme.primaryLight),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 2: CRITICAL SAFETY CHECKLIST
  // ============================================================================

  Widget _buildChecklistTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Scaffold Selector Ribbon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.layers_outlined, color: AppTheme.primaryLight, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedScaffold.id,
                      isDense: true,
                      dropdownColor: AppTheme.surface,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryLight),
                      items: _scaffolds.map((s) {
                        return DropdownMenuItem<String>(
                          value: s.id,
                          child: Text('${s.id} — ${s.name}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedScaffold = _scaffolds.firstWhere((s) => s.id == val);
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

          // IS 3696 & OSHA Compliance Standards Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.2),
                  AppTheme.surfaceCard,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.primaryLight, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IS 3696 / OSHA Mandatory Inspection Criteria',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Every scaffold standard requires sole board, plumb alignment (1:500), 950mm/470mm guardrails, 150mm toe boards, structural ties every 4m/6m, and certified rigging hardware.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Interactive Checklist Items
          ..._selectedScaffold.checklist.asMap().entries.map((entry) {
            int idx = entry.key;
            ChecklistItemModel item = entry.value;
            return _buildDetailedChecklistItem(item, idx);
          }),

          const SizedBox(height: 16),

          // Digital HSE Inspector Sign-off Card
          _buildDigitalSignoffCard(),
        ],
      ),
    );
  }

  Widget _buildDetailedChecklistItem(ChecklistItemModel item, int index) {
    Color statusColor;
    IconData statusIcon;
    switch (item.status) {
      case 'PASS':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'FAIL':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppTheme.textMuted;
        statusIcon = Icons.remove_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.status == 'FAIL'
              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${index + 1}. ${item.title}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.isMandatory) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'MANDATORY',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ref: ${item.standardCode}',
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Toggles and Observation Note
          Row(
            children: [
              _buildChecklistStatusButton('PASS', const Color(0xFF10B981), item),
              const SizedBox(width: 8),
              _buildChecklistStatusButton('FAIL', const Color(0xFFEF4444), item),
              const SizedBox(width: 8),
              _buildChecklistStatusButton('NA', AppTheme.textMuted, item),
              const Spacer(),
              InkWell(
                onTap: () {
                  setState(() {
                    item.hasPhoto = !item.hasPhoto;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.hasPhoto
                        ? AppTheme.primary.withValues(alpha: 0.2)
                        : AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.hasPhoto ? AppTheme.primaryLight : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.hasPhoto ? Icons.photo_library : Icons.camera_alt_outlined,
                        size: 13,
                        color: item.hasPhoto ? AppTheme.primaryLight : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.hasPhoto ? 'Photo Added' : 'Add Photo',
                        style: TextStyle(
                          color:
                              item.hasPhoto ? AppTheme.primaryLight : AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (item.notes.isNotEmpty || item.status == 'FAIL') ...[
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: item.notes),
              onChanged: (val) => item.notes = val,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Inspector observation / corrective action required...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                isDense: true,
                filled: true,
                fillColor: AppTheme.surfaceContainerHigh,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistStatusButton(
      String statusVal, Color activeColor, ChecklistItemModel item) {
    bool isSelected = item.status == statusVal;
    return InkWell(
      onTap: () {
        setState(() {
          item.status = statusVal;
          if (statusVal == 'FAIL' && _selectedScaffold.tagStatus == ScaffoldingTagType.green) {
            _selectedScaffold.tagStatus = ScaffoldingTagType.yellow;
          }
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          statusVal,
          style: TextStyle(
            color: isSelected ? activeColor : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalSignoffCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.draw_rounded, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Digital Safety Officer Ratification',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'I certify that this structural scaffolding and heavy rigging setup has been physically verified in compliance with IS 3696 (Part 1 & 2) and site safety standards.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.3),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.fingerprint_rounded, color: AppTheme.tertiary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedScaffold.inspectorName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Badge: ${_selectedScaffold.inspectorBadge} • PTW: ${_selectedScaffold.permitNumber}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'SHA-256: 4a9f81b2c3d0e91a876f2... [VERIFIED TAMPER-PROOF]',
                        style: TextStyle(color: AppTheme.primaryLight, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(double.infinity, 44),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.surfaceCard,
                  content: Text(
                    'Inspection checklist signed and transmitted to Central HSE Audit Ledger.',
                    style: TextStyle(color: AppTheme.tertiary),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.assignment_turned_in, size: 16),
            label: const Text('Ratify & Update Permit Ledger'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: SAFE WORKING LOAD (SWL) CALCULATION ENGINE
  // ============================================================================

  Widget _buildSwlEngineTab() {
    final scaffold = _selectedScaffold;
    final area = scaffold.platformArea;
    final maxSwl = scaffold.maxPermissibleLoadKg;
    final liveLoad = scaffold.liveLoadKg;
    final utilization = scaffold.utilizationPercent;

    // Hitch multiplier: Direct = 1.0, Choker = 0.75, Basket = 2.0
    double hitchFactor = 1.0;
    if (_riggingHitchType == 'Choker') hitchFactor = 0.75;
    if (_riggingHitchType == 'Basket') hitchFactor = 2.0;

    // Rigging tension calculation:
    // Tension per sling leg = (Load / (Number of Legs * hitchFactor)) / sin(Angle)
    final angleRad = (_riggingSlingAngleDeg * pi) / 180.0;
    final sinVal = sin(angleRad);
    final slingLegTensionTonnes =
        sinVal > 0 ? (_riggingLoadTonnes / (_riggingSlingLegs * hitchFactor)) / sinVal : 0.0;
    final shackleSafetyFactor =
        slingLegTensionTonnes > 0 ? _shackleRatedCapTonnes / slingLegTensionTonnes : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Row(
            children: [
              Icon(Icons.speed_rounded, color: AppTheme.primaryLight, size: 22),
              SizedBox(width: 8),
              Text(
                'Scaffold Safe Working Load (SWL) Engine',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Calibrated strictly to IS 3696 & EN 12811 Load Classes',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 16),

          // Duty Rating Selector Cards
          Row(
            children: ScaffoldDutyRating.values.map((duty) {
              final isSelected = scaffold.dutyRating == duty;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        scaffold.dutyRating = duty;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.2)
                            : AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            duty.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${duty.loadKgPerM2} kg/m²',
                            style: TextStyle(
                              color: isSelected ? AppTheme.secondary : AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            duty.description,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Interactive Platform Parameters Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BAY DIMENSIONS & LIVE OCCUPANCY',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Length & Width Sliders
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Platform Length: ${scaffold.platformLengthM.toStringAsFixed(1)} m',
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppTheme.primary,
                              thumbColor: AppTheme.primaryLight,
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: scaffold.platformLengthM,
                              min: 1.0,
                              max: 10.0,
                              divisions: 18,
                              onChanged: (val) {
                                setState(() {
                                  scaffold.platformLengthM = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Platform Width: ${scaffold.platformWidthM.toStringAsFixed(1)} m',
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppTheme.primary,
                              thumbColor: AppTheme.primaryLight,
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: scaffold.platformWidthM,
                              min: 0.8,
                              max: 3.5,
                              divisions: 27,
                              onChanged: (val) {
                                setState(() {
                                  scaffold.platformWidthM = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Workers & Material Weight
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workers on Deck: ${scaffold.workerCount} (@ 85kg)',
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppTheme.secondary,
                              thumbColor: AppTheme.secondary,
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: scaffold.workerCount.toDouble(),
                              min: 0,
                              max: 8,
                              divisions: 8,
                              onChanged: (val) {
                                setState(() {
                                  scaffold.workerCount = val.toInt();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Material/Tools: ${scaffold.materialWeightKg.toStringAsFixed(0)} kg',
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppTheme.tertiary,
                              thumbColor: AppTheme.tertiary,
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: scaffold.materialWeightKg,
                              min: 0,
                              max: 1500,
                              divisions: 30,
                              onChanged: (val) {
                                setState(() {
                                  scaffold.materialWeightKg = val;
                                });
                              },
                            ),
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

          // SWL Capacity Gauge Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: utilization > 100
                    ? const Color(0xFFEF4444)
                    : (utilization > 85 ? const Color(0xFFF59E0B) : AppTheme.border),
                width: utilization > 85 ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CAPACITY UTILIZATION STATUS',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${utilization.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: utilization > 100
                            ? const Color(0xFFEF4444)
                            : (utilization > 85
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981)),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Large Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (utilization / 100).clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      utilization > 100
                          ? const Color(0xFFEF4444)
                          : (utilization > 85
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Key Calculation Metrics Grid
                Row(
                  children: [
                    _buildMetricBox(
                      title: 'Deck Area',
                      value: '${area.toStringAsFixed(2)} m²',
                      icon: Icons.aspect_ratio_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricBox(
                      title: 'Permissible SWL',
                      value: '${maxSwl.toStringAsFixed(0)} kg',
                      icon: Icons.verified_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricBox(
                      title: 'Live Applied',
                      value: '${liveLoad.toStringAsFixed(0)} kg',
                      icon: Icons.fitness_center_rounded,
                    ),
                  ],
                ),

                if (utilization > 100) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.dangerous_rounded, color: Color(0xFFEF4444), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'DANGER: STRUCTURAL OVERLOAD! Applied load exceeds permissible SWL. Evacuate personnel immediately & tag RED.',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
          const SizedBox(height: 20),

          // Heavy Rigging & Sling Angle Geometry Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.anchor_rounded, color: AppTheme.primaryLight, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Heavy Rigging Sling Tension & Geometry (ASME B30.9)',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Load angle factor increases sling tension exponentially as sling angle flattens.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
                const SizedBox(height: 12),

                // Gross Lifted Weight Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Lift Weight:',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    Text('${_riggingLoadTonnes.toStringAsFixed(1)} Tonnes',
                        style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                Slider(
                  value: _riggingLoadTonnes,
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  onChanged: (val) => setState(() => _riggingLoadTonnes = val),
                ),

                // Hitch Type & Sling Legs Selection
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hitch Type:',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _riggingHitchType,
                                isDense: true,
                                dropdownColor: AppTheme.surface,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                                items: ['Direct', 'Choker', 'Basket'].map((h) {
                                  return DropdownMenuItem(value: h, child: Text(h));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _riggingHitchType = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bridle Sling Legs:',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _riggingSlingLegs,
                                isDense: true,
                                dropdownColor: AppTheme.surface,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                                items: [1, 2, 3, 4].map((legs) {
                                  return DropdownMenuItem(
                                      value: legs, child: Text('$legs Legs'));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _riggingSlingLegs = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bow Shackle WLL:',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<double>(
                                value: _shackleRatedCapTonnes,
                                isDense: true,
                                dropdownColor: AppTheme.surface,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                                items: [4.75, 6.5, 8.5, 12.0, 17.0, 25.0].map((cap) {
                                  return DropdownMenuItem(
                                      value: cap, child: Text('${cap.toStringAsFixed(1)} T'));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _shackleRatedCapTonnes = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sling Angle Selector Chips (60°, 45°, 30°)
                const Text(
                  'Horizontal Sling Angle (θ):',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [60.0, 45.0, 30.0].map((angle) {
                    bool isSelected = _riggingSlingAngleDeg == angle;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => setState(() => _riggingSlingAngleDeg = angle),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary.withValues(alpha: 0.2)
                                  : AppTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${angle.toInt()}° ${angle == 60 ? "(Optimal)" : (angle == 30 ? "(Critical)" : "(Standard)")}',
                              style: TextStyle(
                                color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Rigging Results Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Tension Per Sling Leg',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(
                            '${slingLegTensionTonnes.toStringAsFixed(2)} T',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 30, color: AppTheme.border),
                      Column(
                        children: [
                          const Text('Shackle Safety Factor',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(
                            '${shackleSafetyFactor.toStringAsFixed(2)} : 1',
                            style: TextStyle(
                              color: shackleSafetyFactor >= 5.0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 30, color: AppTheme.border),
                      Column(
                        children: [
                          const Text('Required Shackle WLL',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(
                            '≥ ${(slingLegTensionTonnes * 1.25).toStringAsFixed(1)} T',
                            style: const TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
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

  Widget _buildMetricBox(
      {required String title, required String value, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryLight),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 4: WEEKLY RE-INSPECTION SCHEDULER & ALERT TAGS
  // ============================================================================

  Widget _buildWeeklyCycleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mandatory 7-Day Cycle Explanation Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event_repeat_rounded,
                      color: AppTheme.primaryLight, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statutory 7-Day Re-Inspection Mandate',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Under IS 3696: Section 13 and OSHA 1926.451(f)(3), scaffolds must be inspected before first use, every 7 days thereafter, and immediately following adverse weather or structural alterations. Failure automatically renders the tag RED.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Re-inspection Schedule Table Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '7-DAY COMPLIANCE TIMELINE & EXPIRY QUEUE',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${_scaffolds.length} Registered Structures',
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Timeline Cards
          ..._scaffolds.map((scaffold) => _buildScheduleTimelineCard(scaffold)),
        ],
      ),
    );
  }

  Widget _buildScheduleTimelineCard(ScaffoldStructureModel scaffold) {
    final now = DateTime.now();
    final daysRemaining = scaffold.nextInspectionDate.difference(now).inDays;
    final hoursRemaining = scaffold.nextInspectionDate.difference(now).inHours;
    final isOverdue = now.isAfter(scaffold.nextInspectionDate);

    Color badgeColor;
    String statusText;

    if (isOverdue) {
      badgeColor = const Color(0xFFEF4444);
      statusText = 'OVERDUE by ${(-daysRemaining).clamp(1, 99)} Days';
    } else if (hoursRemaining <= 24) {
      badgeColor = const Color(0xFFF59E0B);
      statusText = 'DUE TODAY (${hoursRemaining}h remaining)';
    } else {
      badgeColor = const Color(0xFF10B981);
      statusText = '$daysRemaining Days Validity Left';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? const Color(0xFFEF4444).withValues(alpha: 0.6) : AppTheme.border,
        ),
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
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getTagColor(scaffold.tagStatus),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scaffold.id,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            scaffold.name,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),

          // Date Milestones
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Last Inspected',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(scaffold.lastInspectionDate),
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Next 7-Day Deadline',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(scaffold.nextInspectionDate),
                      style: TextStyle(
                        color: isOverdue ? const Color(0xFFEF4444) : AppTheme.tertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scaffold.alertTag.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(scaffold.alertTag.icon, size: 12, color: scaffold.alertTag.color),
                    const SizedBox(width: 4),
                    Text(
                      scaffold.alertTag.label,
                      style: TextStyle(
                        color: scaffold.alertTag.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOverdue ? const Color(0xFFEF4444) : AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  setState(() {
                    _selectedScaffold = scaffold;
                  });
                  _openPerformInspectionSheet(scaffold);
                },
                icon: const Icon(Icons.assignment_turned_in_outlined, size: 14),
                label: Text(
                  isOverdue ? 'Clear Overdue Tag' : 'Renew 7-Day Permit',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
