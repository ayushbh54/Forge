import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'activity_detail_screen.dart';

/// Representation of a Work Breakdown Structure (WBS) node from L1 to L6.
class WbsNodeItem {
  final String id;
  final String code;
  final String name;
  final int level; // 1: Project, 2: Spread/Package, 3: Discipline/Section, 4: Segment/Task Group, 5: Field Activity, 6: Work Step
  final String? parentId;
  final String discipline;
  final DateTime startDate;
  final DateTime finishDate;
  final int durationDays;
  final int floatDays;
  final bool isCriticalPath;
  final double progressPercent;
  final double plannedProgress;
  final String status; // 'ON_TRACK', 'IN_PROGRESS', 'CRITICAL', 'COMPLETED'
  final String? supervisor;
  final String? chainage;
  final String? unit;
  final double? plannedQuantity;
  final double? installedQuantity;
  final String? uwid;
  final String? description;
  final List<String> equipment;
  final Map<String, double>? triangulation;
  final List<WbsNodeItem> children;

  const WbsNodeItem({
    required this.id,
    required this.code,
    required this.name,
    required this.level,
    this.parentId,
    required this.discipline,
    required this.startDate,
    required this.finishDate,
    required this.durationDays,
    required this.floatDays,
    required this.isCriticalPath,
    required this.progressPercent,
    required this.plannedProgress,
    this.status = 'IN_PROGRESS',
    this.supervisor,
    this.chainage,
    this.unit,
    this.plannedQuantity,
    this.installedQuantity,
    this.uwid,
    this.description,
    this.equipment = const [],
    this.triangulation,
    this.children = const [],
  });

  bool get hasChildren => children.isNotEmpty;

  Color get levelColor {
    switch (level) {
      case 1:
        return const Color(0xFF818CF8); // Indigo / Macro Milestone
      case 2:
        return const Color(0xFF38BDF8); // Sky Blue / Spreads & Packages
      case 3:
        return const Color(0xFF34D399); // Emerald / Discipline & Civil
      case 4:
        return const Color(0xFFFBBF24); // Amber / Segment
      case 5:
        return const Color(0xFFF43F5E); // Rose-Crimson / Executable Field Activity
      case 6:
        return const Color(0xFFA855F7); // Purple / Field Work Step
      default:
        return AppTheme.primaryLight;
    }
  }

  String get levelLabel {
    switch (level) {
      case 1:
        return 'L1 MACRO';
      case 2:
        return 'L2 SPREAD';
      case 3:
        return 'L3 DISCIPLINE';
      case 4:
        return 'L4 SEGMENT';
      case 5:
        return 'L5 FIELD ACT';
      case 6:
        return 'L6 WORK STEP';
      default:
        return 'L$level';
    }
  }
}

class WbsGanttScreen extends StatefulWidget {
  const WbsGanttScreen({super.key});

  @override
  State<WbsGanttScreen> createState() => _WbsGanttScreenState();
}

class _WbsGanttScreenState extends State<WbsGanttScreen> {
  // View mode: 'CASCADE' (Tree + timeline), 'GANTT' (Horizontal calendar matrix), 'CRITICAL' (Critical path stream)
  String _activeViewMode = 'CASCADE';
  String _selectedDiscipline = 'ALL';
  bool _criticalPathOnly = false;
  final TextEditingController _searchController = TextEditingController();

  // Track expanded state for nodes
  final Set<String> _expandedNodeIds = {
    'WBS-L1-001',
    'WBS-L2-001',
    'WBS-L3-001',
    'WBS-L4-001',
    'WBS-L5-204',
  };

  // Master timeline boundaries for Gantt matrix
  final DateTime _projectMinDate = DateTime(2026, 6, 1);
  final DateTime _projectMaxDate = DateTime(2027, 4, 30);

  late final List<WbsNodeItem> _rootData;

  @override
  void initState() {
    super.initState();
    _rootData = _buildWbsHierarchy();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Builds the industrial L1-L6 WBS hierarchy containing the exact requested sequence:
  /// L1: Crude Oil Pipeline Project (Overall 48%)
  ///   L2: Pipeline Spreads & Crossings (54%)
  ///     L3: Spread 2 Civil & Trenching (72%)
  ///       L4: Trench Excavation Km 12-16 (88%)
  ///         L5: ACT-204 Ditch Padding & Lowering (45% - Critical Path)
  ///           L6: Granular Field Work Steps
  List<WbsNodeItem> _buildWbsHierarchy() {
    return [
      WbsNodeItem(
        id: 'WBS-L1-001',
        code: 'OIL-PL-024',
        name: 'Crude Oil Pipeline Project',
        level: 1,
        discipline: 'PIPELINE',
        startDate: DateTime(2026, 6, 1),
        finishDate: DateTime(2027, 4, 30),
        durationDays: 333,
        floatDays: 0,
        isCriticalPath: true,
        progressPercent: 48.0,
        plannedProgress: 52.0,
        status: 'IN_PROGRESS',
        description:
            'Comprehensive 142 km Crude Oil Trunk Pipeline Expansion EPC Project with terminal pumping stations and river crossing HDDs.',
        children: [
          // L2: Pipeline Spreads & Crossings (54%)
          WbsNodeItem(
            id: 'WBS-L2-001',
            code: 'WBS-02',
            name: 'Pipeline Spreads & Crossings',
            level: 2,
            parentId: 'WBS-L1-001',
            discipline: 'PIPING',
            startDate: DateTime(2026, 7, 1),
            finishDate: DateTime(2027, 2, 28),
            durationDays: 242,
            floatDays: 0,
            isCriticalPath: true,
            progressPercent: 54.0,
            plannedProgress: 58.0,
            status: 'IN_PROGRESS',
            description:
                'Mainline pipeline construction across Spread 1 (Km 00-60) and Spread 2 (Km 60-142), including major river crossings.',
            children: [
              // L3: Spread 2 Civil & Trenching (72%)
              WbsNodeItem(
                id: 'WBS-L3-001',
                code: 'WBS-02.02',
                name: 'Spread 2 Civil & Trenching',
                level: 3,
                parentId: 'WBS-L2-001',
                discipline: 'CIVIL',
                startDate: DateTime(2026, 8, 1),
                finishDate: DateTime(2026, 12, 15),
                durationDays: 136,
                floatDays: 0,
                isCriticalPath: true,
                progressPercent: 72.0,
                plannedProgress: 75.0,
                status: 'IN_PROGRESS',
                chainage: 'Km 12+000 to Km 38+500',
                supervisor: 'A. K. Baruah (Senior Civil Eng.)',
                description:
                    'Right-of-Way (RoW) civil works, clearing, grading, ditch excavation, padding, and lowering for Spread 2 pipeline.',
                children: [
                  // L4: Trench Excavation Km 12-16 (88%)
                  WbsNodeItem(
                    id: 'WBS-L4-001',
                    code: 'WBS-02.02.01',
                    name: 'Trench Excavation Km 12-16',
                    level: 4,
                    parentId: 'WBS-L3-001',
                    discipline: 'CIVIL',
                    startDate: DateTime(2026, 8, 15),
                    finishDate: DateTime(2026, 10, 15),
                    durationDays: 61,
                    floatDays: 0,
                    isCriticalPath: true,
                    progressPercent: 88.0,
                    plannedProgress: 90.0,
                    status: 'IN_PROGRESS',
                    chainage: 'Km 12+000 to Km 16+000',
                    unit: 'linear meters',
                    plannedQuantity: 4000,
                    installedQuantity: 3520,
                    supervisor: 'Vikram Joshi (Field Operations)',
                    description:
                        'Mechanical trenching in mixed alluvial and fractured sandstone formation with side-wall battering.',
                    children: [
                      // L5: ACT-204 Ditch Padding & Lowering (45% - Critical Path)
                      WbsNodeItem(
                        id: 'WBS-L5-204',
                        code: 'ACT-204',
                        name: 'ACT-204 Ditch Padding & Lowering',
                        level: 5,
                        parentId: 'WBS-L4-001',
                        discipline: 'PIPING',
                        startDate: DateTime(2026, 9, 10),
                        finishDate: DateTime(2026, 10, 5),
                        durationDays: 25,
                        floatDays: 0,
                        isCriticalPath: true,
                        progressPercent: 45.0,
                        plannedProgress: 60.0,
                        status: 'CRITICAL',
                        uwid: 'UWID-OIL-2026-ACT204',
                        chainage: 'Km 14+320 to Km 14+850',
                        unit: 'meters',
                        plannedQuantity: 530,
                        installedQuantity: 238.5,
                        supervisor: 'R. K. Sharma (Lead Inspector)',
                        description:
                            'Pre-lowering holiday spark testing (15kV), continuous bottom sand padding (150mm), synchronized 3-boom sideboom pipe lowering, and rock shield padding protection.',
                        equipment: const [
                          'CAT 572R Sideboom (x3)',
                          'Komatsu PC300 Excavator',
                          'Padding Machine PM-02',
                          'Jeep Holiday Detector 15kV'
                        ],
                        triangulation: const {
                          'Contractor': 50.0,
                          'QS Verified': 44.0,
                          'QC Passed': 42.0,
                          'Drone/LiDAR': 45.0,
                          'Consensus': 45.0,
                        },
                        children: [
                          // L6: Granular Executable Work Steps
                          WbsNodeItem(
                            id: 'WBS-L6-204-1',
                            code: 'ACT-204.1',
                            name: 'Bottom Sand Padding 150mm Bed Layer',
                            level: 6,
                            parentId: 'WBS-L5-204',
                            discipline: 'CIVIL',
                            startDate: DateTime(2026, 9, 10),
                            finishDate: DateTime(2026, 9, 15),
                            durationDays: 5,
                            floatDays: 0,
                            isCriticalPath: true,
                            progressPercent: 100.0,
                            plannedProgress: 100.0,
                            status: 'COMPLETED',
                            description: 'Bedding layer sieve-analyzed fine sand spread evenly along trench floor.',
                          ),
                          WbsNodeItem(
                            id: 'WBS-L6-204-2',
                            code: 'ACT-204.2',
                            name: '15kV Holiday Spark Test & NDT Clearance',
                            level: 6,
                            parentId: 'WBS-L5-204',
                            discipline: 'PIPING',
                            startDate: DateTime(2026, 9, 16),
                            finishDate: DateTime(2026, 9, 19),
                            durationDays: 4,
                            floatDays: 0,
                            isCriticalPath: true,
                            progressPercent: 100.0,
                            plannedProgress: 100.0,
                            status: 'COMPLETED',
                            description: 'High-voltage porosity check of 3-layer polyethylene (3LPE) external coat.',
                          ),
                          WbsNodeItem(
                            id: 'WBS-L6-204-3',
                            code: 'ACT-204.3',
                            name: 'Sideboom Pipe Lower-in Execution',
                            level: 6,
                            parentId: 'WBS-L5-204',
                            discipline: 'PIPING',
                            startDate: DateTime(2026, 9, 20),
                            finishDate: DateTime(2026, 9, 28),
                            durationDays: 8,
                            floatDays: 0,
                            isCriticalPath: true,
                            progressPercent: 40.0,
                            plannedProgress: 65.0,
                            status: 'CRITICAL',
                            description: 'Synchronous tandem lowering into trench avoiding bend overstress.',
                          ),
                          WbsNodeItem(
                            id: 'WBS-L6-204-4',
                            code: 'ACT-204.4',
                            name: 'Rock Shield Padding & Initial Backfill',
                            level: 6,
                            parentId: 'WBS-L5-204',
                            discipline: 'CIVIL',
                            startDate: DateTime(2026, 9, 29),
                            finishDate: DateTime(2026, 10, 5),
                            durationDays: 7,
                            floatDays: 0,
                            isCriticalPath: true,
                            progressPercent: 0.0,
                            plannedProgress: 25.0,
                            status: 'IN_PROGRESS',
                            description: 'Protective rock shield wrap and 300mm soft padding crown layer.',
                          ),
                        ],
                      ),
                      // L5: ACT-205 Rock Trench Blasting & Pre-split (92%, Float: 8d)
                      WbsNodeItem(
                        id: 'WBS-L5-205',
                        code: 'ACT-205',
                        name: 'ACT-205 Rock Trench Pre-Split & Hydraulic Ripping',
                        level: 5,
                        parentId: 'WBS-L4-001',
                        discipline: 'CIVIL',
                        startDate: DateTime(2026, 8, 15),
                        finishDate: DateTime(2026, 9, 14),
                        durationDays: 30,
                        floatDays: 8,
                        isCriticalPath: false,
                        progressPercent: 92.0,
                        plannedProgress: 95.0,
                        status: 'IN_PROGRESS',
                        chainage: 'Km 12+800 to Km 13+600',
                        unit: 'meters',
                        plannedQuantity: 800,
                        installedQuantity: 736,
                        supervisor: 'Mohan Sen (Blasting Engineer)',
                        description: 'Controlled pre-split blasting and breaker ripping in hard rock stretch.',
                      ),
                      // L5: ACT-206 Dewatering & Sump Wellpoints (100%, Float: 14d)
                      WbsNodeItem(
                        id: 'WBS-L5-206',
                        code: 'ACT-206',
                        name: 'ACT-206 Dewatering & Sump Pump Deployment',
                        level: 5,
                        parentId: 'WBS-L4-001',
                        discipline: 'CIVIL',
                        startDate: DateTime(2026, 8, 18),
                        finishDate: DateTime(2026, 9, 8),
                        durationDays: 21,
                        floatDays: 14,
                        isCriticalPath: false,
                        progressPercent: 100.0,
                        plannedProgress: 100.0,
                        status: 'COMPLETED',
                        chainage: 'Km 13+200 to Km 14+100',
                        unit: 'locations',
                        plannedQuantity: 6,
                        installedQuantity: 6,
                        supervisor: 'K. N. Saikia',
                        description: 'Submersible water pump lines and trench sump pits for monsoon runoff.',
                      ),
                    ],
                  ),
                  // L4: Trench Excavation Km 16-20 (60%)
                  WbsNodeItem(
                    id: 'WBS-L4-002',
                    code: 'WBS-02.02.02',
                    name: 'Trench Excavation Km 16-20',
                    level: 4,
                    parentId: 'WBS-L3-001',
                    discipline: 'CIVIL',
                    startDate: DateTime(2026, 9, 1),
                    finishDate: DateTime(2026, 11, 15),
                    durationDays: 75,
                    floatDays: 12,
                    isCriticalPath: false,
                    progressPercent: 60.0,
                    plannedProgress: 65.0,
                    status: 'IN_PROGRESS',
                    chainage: 'Km 16+000 to Km 20+000',
                    children: [
                      WbsNodeItem(
                        id: 'WBS-L5-207',
                        code: 'ACT-207',
                        name: 'ACT-207 RoW Clearing & Topsoil Stripping',
                        level: 5,
                        parentId: 'WBS-L4-002',
                        discipline: 'CIVIL',
                        startDate: DateTime(2026, 9, 1),
                        finishDate: DateTime(2026, 9, 20),
                        durationDays: 19,
                        floatDays: 18,
                        isCriticalPath: false,
                        progressPercent: 100.0,
                        plannedProgress: 100.0,
                        status: 'COMPLETED',
                        unit: 'km',
                        plannedQuantity: 4.0,
                        installedQuantity: 4.0,
                        description: 'Topsoil preservation and grubbing along 30m RoW corridor.',
                      ),
                      WbsNodeItem(
                        id: 'WBS-L5-208',
                        code: 'ACT-208',
                        name: 'ACT-208 Continuous Mechanical Trenching',
                        level: 5,
                        parentId: 'WBS-L4-002',
                        discipline: 'CIVIL',
                        startDate: DateTime(2026, 9, 21),
                        finishDate: DateTime(2026, 10, 30),
                        durationDays: 39,
                        floatDays: 5,
                        isCriticalPath: false,
                        progressPercent: 42.0,
                        plannedProgress: 50.0,
                        status: 'IN_PROGRESS',
                        unit: 'meters',
                        plannedQuantity: 4000,
                        installedQuantity: 1680,
                        description: 'Bucket wheel trencher operation in clayey loam soil.',
                      ),
                    ],
                  ),
                ],
              ),
              // L3: Spread 1 River Crossing HDD (35%)
              WbsNodeItem(
                id: 'WBS-L3-002',
                code: 'WBS-02.01',
                name: 'Spread 1 River Crossing HDD',
                level: 3,
                parentId: 'WBS-L2-001',
                discipline: 'PIPING',
                startDate: DateTime(2026, 8, 20),
                finishDate: DateTime(2027, 1, 20),
                durationDays: 153,
                floatDays: 4,
                isCriticalPath: false,
                progressPercent: 35.0,
                plannedProgress: 40.0,
                status: 'IN_PROGRESS',
                chainage: 'Brahmaputra Tributary Km 04+200',
                children: [
                  WbsNodeItem(
                    id: 'WBS-L4-003',
                    code: 'WBS-02.01.01',
                    name: 'HDD Drill Km 04-06 Under Riverbed',
                    level: 4,
                    parentId: 'WBS-L3-002',
                    discipline: 'PIPING',
                    startDate: DateTime(2026, 8, 20),
                    finishDate: DateTime(2026, 11, 30),
                    durationDays: 102,
                    floatDays: 4,
                    isCriticalPath: false,
                    progressPercent: 42.0,
                    plannedProgress: 45.0,
                    status: 'IN_PROGRESS',
                    children: [
                      WbsNodeItem(
                        id: 'WBS-L5-112',
                        code: 'ACT-112',
                        name: 'ACT-112 Pilot Hole Directional Drilling 12-1/4"',
                        level: 5,
                        parentId: 'WBS-L4-003',
                        discipline: 'PIPING',
                        startDate: DateTime(2026, 8, 20),
                        finishDate: DateTime(2026, 9, 25),
                        durationDays: 36,
                        floatDays: 4,
                        isCriticalPath: false,
                        progressPercent: 70.0,
                        plannedProgress: 75.0,
                        status: 'IN_PROGRESS',
                        description: 'Steerable mud motor pilot drilling with gyro tracking.',
                      ),
                      WbsNodeItem(
                        id: 'WBS-L5-114',
                        code: 'ACT-114',
                        name: 'ACT-114 Hole Reaming Pass 36-inch',
                        level: 5,
                        parentId: 'WBS-L4-003',
                        discipline: 'PIPING',
                        startDate: DateTime(2026, 9, 26),
                        finishDate: DateTime(2026, 11, 10),
                        durationDays: 45,
                        floatDays: 0,
                        isCriticalPath: true,
                        progressPercent: 15.0,
                        plannedProgress: 20.0,
                        status: 'CRITICAL',
                        description: 'Multi-stage barrel reaming pass prior to pipe pullback.',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // L2: Pumping Stations & Terminals (42%)
          WbsNodeItem(
            id: 'WBS-L2-002',
            code: 'WBS-03',
            name: 'Pumping Stations & Terminals',
            level: 2,
            parentId: 'WBS-L1-001',
            discipline: 'MECHANICAL',
            startDate: DateTime(2026, 7, 15),
            finishDate: DateTime(2027, 3, 15),
            durationDays: 243,
            floatDays: 14,
            isCriticalPath: false,
            progressPercent: 42.0,
            plannedProgress: 48.0,
            status: 'IN_PROGRESS',
            children: [
              WbsNodeItem(
                id: 'WBS-L3-003',
                code: 'WBS-03.01',
                name: 'Terminal Station Hub Civil Works',
                level: 3,
                parentId: 'WBS-L2-002',
                discipline: 'CIVIL',
                startDate: DateTime(2026, 7, 15),
                finishDate: DateTime(2026, 12, 10),
                durationDays: 148,
                floatDays: 14,
                isCriticalPath: false,
                progressPercent: 50.0,
                plannedProgress: 55.0,
                status: 'IN_PROGRESS',
                children: [
                  WbsNodeItem(
                    id: 'WBS-L4-004',
                    code: 'WBS-03.01.01',
                    name: 'Foundation & Sump Pit Pouring',
                    level: 4,
                    parentId: 'WBS-L3-003',
                    discipline: 'CIVIL',
                    startDate: DateTime(2026, 8, 1),
                    finishDate: DateTime(2026, 10, 20),
                    durationDays: 80,
                    floatDays: 14,
                    isCriticalPath: false,
                    progressPercent: 65.0,
                    plannedProgress: 70.0,
                    status: 'IN_PROGRESS',
                    children: [
                      WbsNodeItem(
                        id: 'WBS-L5-301',
                        code: 'ACT-301',
                        name: 'ACT-301 Main Pump Skid Base Concrete Pour',
                        level: 5,
                        parentId: 'WBS-L4-004',
                        discipline: 'CIVIL',
                        startDate: DateTime(2026, 8, 1),
                        finishDate: DateTime(2026, 9, 28),
                        durationDays: 58,
                        floatDays: 14,
                        isCriticalPath: false,
                        progressPercent: 65.0,
                        plannedProgress: 70.0,
                        status: 'IN_PROGRESS',
                        description: 'M35 grade monolithic reinforced concrete machine foundation.',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // L2: Cathodic Protection & SCADA (38%)
          WbsNodeItem(
            id: 'WBS-L2-003',
            code: 'WBS-04',
            name: 'Cathodic Protection & SCADA Instrumentation',
            level: 2,
            parentId: 'WBS-L1-001',
            discipline: 'ELECTRICAL',
            startDate: DateTime(2026, 8, 15),
            finishDate: DateTime(2027, 4, 10),
            durationDays: 238,
            floatDays: 20,
            isCriticalPath: false,
            progressPercent: 38.0,
            plannedProgress: 42.0,
            status: 'IN_PROGRESS',
            children: [
              WbsNodeItem(
                id: 'WBS-L3-004',
                code: 'WBS-04.01',
                name: 'Deep Well Anode Groundbeds',
                level: 3,
                parentId: 'WBS-L2-003',
                discipline: 'ELECTRICAL',
                startDate: DateTime(2026, 8, 15),
                finishDate: DateTime(2026, 12, 5),
                durationDays: 112,
                floatDays: 20,
                isCriticalPath: false,
                progressPercent: 45.0,
                plannedProgress: 48.0,
                status: 'IN_PROGRESS',
                children: [
                  WbsNodeItem(
                    id: 'WBS-L4-005',
                    code: 'WBS-04.01.01',
                    name: 'Drilling & Anode String Installation',
                    level: 4,
                    parentId: 'WBS-L3-004',
                    discipline: 'ELECTRICAL',
                    startDate: DateTime(2026, 9, 1),
                    finishDate: DateTime(2026, 11, 10),
                    durationDays: 70,
                    floatDays: 20,
                    isCriticalPath: false,
                    progressPercent: 45.0,
                    plannedProgress: 48.0,
                    status: 'IN_PROGRESS',
                    children: [
                      WbsNodeItem(
                        id: 'WBS-L5-402',
                        code: 'ACT-402',
                        name: 'ACT-402 Deep Well CP Anode Bed #4',
                        level: 5,
                        parentId: 'WBS-L4-005',
                        discipline: 'ELECTRICAL',
                        startDate: DateTime(2026, 9, 1),
                        finishDate: DateTime(2026, 10, 15),
                        durationDays: 44,
                        floatDays: 20,
                        isCriticalPath: false,
                        progressPercent: 45.0,
                        plannedProgress: 48.0,
                        status: 'IN_PROGRESS',
                        description: '100m vertical bore with MMO tubular anode string and calcined coke breeze backfill.',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ];
  }

  void _toggleNodeExpansion(String id) {
    setState(() {
      if (_expandedNodeIds.contains(id)) {
        _expandedNodeIds.remove(id);
      } else {
        _expandedNodeIds.add(id);
      }
    });
  }

  void _expandAll() {
    setState(() {
      void recurse(WbsNodeItem item) {
        _expandedNodeIds.add(item.id);
        for (final child in item.children) {
          recurse(child);
        }
      }

      for (final root in _rootData) {
        recurse(root);
      }
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedNodeIds.clear();
      // Keep root expanded for visual clarity
      if (_rootData.isNotEmpty) {
        _expandedNodeIds.add(_rootData.first.id);
      }
    });
  }

  /// Flattens the visible tree nodes based on current filter & expansion state
  List<WbsNodeItem> _getVisibleNodes() {
    final List<WbsNodeItem> visible = [];
    final query = _searchController.text.trim().toLowerCase();

    bool matchesFilters(WbsNodeItem item) {
      if (_criticalPathOnly && !item.isCriticalPath) return false;
      if (_selectedDiscipline != 'ALL' &&
          item.discipline != 'PIPELINE' &&
          item.discipline.toUpperCase() != _selectedDiscipline.toUpperCase()) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesSelf = item.name.toLowerCase().contains(query) ||
            item.code.toLowerCase().contains(query) ||
            item.levelLabel.toLowerCase().contains(query);
        if (matchesSelf) return true;

        // Check if any descendant matches
        bool checkDescendant(WbsNodeItem node) {
          if (node.name.toLowerCase().contains(query) ||
              node.code.toLowerCase().contains(query)) {
            return true;
          }
          return node.children.any(checkDescendant);
        }

        return checkDescendant(item);
      }
      return true;
    }

    void traverse(WbsNodeItem node) {
      if (!matchesFilters(node)) return;

      visible.add(node);

      final isExpanded = _expandedNodeIds.contains(node.id) || query.isNotEmpty;
      if (isExpanded && node.children.isNotEmpty) {
        for (final child in node.children) {
          traverse(child);
        }
      }
    }

    for (final root in _rootData) {
      traverse(root);
    }

    return visible;
  }

  /// Flattens all nodes across the tree (used for the full Gantt chart view)
  List<WbsNodeItem> _getAllNodesFlattened() {
    final List<WbsNodeItem> all = [];
    void traverse(WbsNodeItem node) {
      all.add(node);
      for (final child in node.children) {
        traverse(child);
      }
    }

    for (final root in _rootData) {
      traverse(root);
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final visibleNodes = _getVisibleNodes();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'WBS L1–L6 Gantt Cascade',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Primavera P6 Critical Path Method (CPM)',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _criticalPathOnly ? Icons.crisis_alert_rounded : Icons.crisis_alert_outlined,
              color: _criticalPathOnly ? const Color(0xFFFF334B) : AppTheme.textSecondary,
            ),
            tooltip: 'Critical Path Only',
            onPressed: () {
              setState(() {
                _criticalPathOnly = !_criticalPathOnly;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.primaryLight),
            tooltip: 'Export P6 XML',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exported Primavera P6 XER/XML schema for OIL-PL-024'),
                  backgroundColor: AppTheme.surfaceContainerHigh,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildProjectSummaryHeader(),
          _buildControlToolbar(),
          Expanded(
            child: _activeViewMode == 'GANTT'
                ? _buildFullGanttMatrixView()
                : _buildCascadeTreeView(visibleNodes),
          ),
          _buildFooterStatusBanner(),
        ],
      ),
    );
  }

  /// Top macro summary displaying project performance indicators
  Widget _buildProjectSummaryHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(50),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primaryLight.withAlpha(120)),
                ),
                child: const Text(
                  'OIL-PL-024',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Trunk Crude Oil Pipeline Expansion',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF334B).withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF334B).withAlpha(150)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF334B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF334B),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'CRITICAL (0d Float)',
                      style: TextStyle(
                        color: Color(0xFFFF8B94),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Project Progress Bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Overall L1 Progress (Consensus)',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        Text(
                          '48.0%  (Planned: 52.0%)',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 8,
                        color: AppTheme.background,
                        child: Row(
                          children: [
                            Container(
                              width: 140, // Proportional representation
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Micro Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderStatChip(
                label: 'Driving Path',
                value: 'ACT-204 (Ditch Padding)',
                valueColor: const Color(0xFFFF8B94),
                icon: Icons.alt_route_rounded,
              ),
              _buildHeaderStatChip(
                label: 'Schedule SPI',
                value: '0.94 (-4% Behind)',
                valueColor: const Color(0xFFFFB95F),
                icon: Icons.speed_rounded,
              ),
              _buildHeaderStatChip(
                label: 'Time Frame',
                value: 'Jun 26 – Apr 27',
                valueColor: AppTheme.primaryLight,
                icon: Icons.date_range_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatChip({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Toolbar for switching modes, search, discipline filtering, and expand/collapse
  Widget _buildControlToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              // View Mode Segment
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      _buildViewModeButton('CASCADE', 'Cascade Tree', Icons.account_tree_outlined),
                      _buildViewModeButton('GANTT', 'Gantt Timeline', Icons.view_timeline_outlined),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Expand/Collapse controls
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: const Size(0, 36),
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _expandAll,
                child: const Text('Expand All', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: const Size(0, 36),
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _collapseAll,
                child: const Text('Collapse', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Search Field
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      hintText: 'Search WBS L1-L6, ACT-204, Trenching...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: AppTheme.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
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
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryLight, width: 1.2),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Discipline Dropdown
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDiscipline,
                    dropdownColor: AppTheme.surfaceCard,
                    icon: const Icon(Icons.filter_alt_outlined, size: 16, color: AppTheme.textSecondary),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Disciplines')),
                      DropdownMenuItem(value: 'PIPING', child: Text('Piping')),
                      DropdownMenuItem(value: 'CIVIL', child: Text('Civil')),
                      DropdownMenuItem(value: 'ELECTRICAL', child: Text('Electrical')),
                      DropdownMenuItem(value: 'MECHANICAL', child: Text('Mechanical')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDiscipline = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(String modeKey, String label, IconData icon) {
    final isSelected = _activeViewMode == modeKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeViewMode = modeKey),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the expandable cascade tree with inline timeline bars
  Widget _buildCascadeTreeView(List<WbsNodeItem> nodes) {
    if (nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted.withAlpha(120)),
            const SizedBox(height: 12),
            const Text(
              'No WBS items match current filters',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedDiscipline = 'ALL';
                  _criticalPathOnly = false;
                });
              },
              child: const Text('Reset All Filters', style: TextStyle(color: AppTheme.primaryLight)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final item = nodes[index];
        return _buildWbsCascadeNodeCard(item);
      },
    );
  }

  /// Builds a single node in the cascade with level indentation, timeline bar, and critical path glows
  Widget _buildWbsCascadeNodeCard(WbsNodeItem item) {
    final isExpanded = _expandedNodeIds.contains(item.id);
    final isCritical = item.isCriticalPath;

    // Indentation based on level (L1 = 0, L2 = 14, L3 = 26, L4 = 38, L5 = 50, L6 = 62)
    final double leftPadding = (item.level - 1) * 12.0;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isCritical
              ? const Color(0xFF191D34) // Dark crimson-navy tint for critical
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCritical
                ? const Color(0xFFFF334B).withAlpha(190)
                : AppTheme.border,
            width: isCritical ? 1.5 : 1.0,
          ),
          boxShadow: isCritical
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF334B).withAlpha(45),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (item.hasChildren) {
              _toggleNodeExpansion(item.id);
            } else {
              _showActivityInspectionSheet(item);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Level Badge, Code, Name, Critical Marker, Chevron
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level Indicator Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: item.levelColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: item.levelColor.withAlpha(140)),
                      ),
                      child: Text(
                        item.levelLabel,
                        style: TextStyle(
                          color: item.levelColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Code & Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.code,
                                style: TextStyle(
                                  color: isCritical ? const Color(0xFFFF8B94) : AppTheme.primaryLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (item.chainage != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.chainage!,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 9,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.name,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: item.level <= 2 ? 14 : 12.5,
                              fontWeight: item.level <= 3 ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Critical Path Glowing Marker / Expand Chevron
                    if (isCritical)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF334B).withAlpha(35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFF334B).withAlpha(160)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33FF334B),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.warning_amber_rounded, size: 11, color: Color(0xFFFF5252)),
                            SizedBox(width: 3),
                            Text(
                              'CP',
                              style: TextStyle(
                                color: Color(0xFFFF8B94),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item.hasChildren)
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: isExpanded ? 0.25 : 0.0,
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: AppTheme.textSecondary,
                        ),
                      )
                    else
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textMuted),
                        onPressed: () => _showActivityInspectionSheet(item),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Horizontal Timeline Bar Representation
                _buildInlineTimelineBar(item),
                const SizedBox(height: 8),
                // Dates, Float Days & Discipline Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Start & Finish Dates
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 11, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${DateFormat('dd MMM yy').format(item.startDate)} → ${DateFormat('dd MMM yy').format(item.finishDate)}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${item.durationDays}d)',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    // Float Days Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCritical
                            ? const Color(0xFFFF334B).withAlpha(35)
                            : item.floatDays <= 5
                                ? const Color(0xFFFFB95F).withAlpha(35)
                                : AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isCritical
                              ? const Color(0xFFFF334B).withAlpha(120)
                              : item.floatDays <= 5
                                  ? const Color(0xFFFFB95F).withAlpha(120)
                                  : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        item.floatDays == 0 ? '0d Float (Critical)' : 'Float: +${item.floatDays}d',
                        style: TextStyle(
                          color: isCritical
                              ? const Color(0xFFFF8B94)
                              : item.floatDays <= 5
                                  ? const Color(0xFFFFB95F)
                                  : AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  /// Builds the horizontal timeline bar showing progress percentage and critical status
  Widget _buildInlineTimelineBar(WbsNodeItem item) {
    final isCritical = item.isCriticalPath;
    final progress = item.progressPercent.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${item.discipline.toUpperCase()} • ${item.status.replaceAll('_', ' ')}',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${progress.toStringAsFixed(0)}%',
              style: TextStyle(
                color: isCritical ? const Color(0xFFFF8B94) : AppTheme.tertiary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 7,
            width: double.infinity,
            color: AppTheme.background,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress / 100.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCritical
                        ? [
                            const Color(0xFFE11D48),
                            const Color(0xFFFF334B),
                          ]
                        : progress >= 100.0
                            ? [
                                const Color(0xFF10B981),
                                const Color(0xFF34D399),
                              ]
                            : [
                                const Color(0xFF0284C7),
                                const Color(0xFF38BDF8),
                              ],
                  ),
                  boxShadow: isCritical
                      ? [
                          const BoxShadow(
                            color: Color(0x66FF334B),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Full interactive Gantt Matrix view with calendar axis and horizontal timeline bars
  Widget _buildFullGanttMatrixView() {
    final allNodes = _getAllNodesFlattened();
    final totalProjectDays = _projectMaxDate.difference(_projectMinDate).inDays;

    return Column(
      children: [
        // Gantt Chart Sub-Header / Calendar Months Ruler
        Container(
          height: 38,
          color: AppTheme.surfaceCard,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const SizedBox(
                width: 140,
                child: Text(
                  'WBS Activity',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const VerticalDivider(color: AppTheme.border, width: 1),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildTimelineMonthHeaders(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.border),
        // Gantt Activities List
        Expanded(
          child: ListView.builder(
            itemCount: allNodes.length,
            itemBuilder: (context, index) {
              final node = allNodes[index];
              return _buildGanttRow(node, totalProjectDays);
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTimelineMonthHeaders() {
    final List<String> months = [
      'Jun 26',
      'Jul 26',
      'Aug 26',
      'Sep 26 (Now)',
      'Oct 26',
      'Nov 26',
      'Dec 26',
      'Jan 27',
      'Feb 27',
      'Mar 27',
      'Apr 27',
    ];

    return months.map((m) {
      final isCurrent = m.contains('Now');
      return Container(
        width: 100,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isCurrent ? AppTheme.primary.withAlpha(30) : Colors.transparent,
          border: const Border(
            right: BorderSide(color: AppTheme.border, width: 0.5),
          ),
        ),
        child: Text(
          m,
          style: TextStyle(
            color: isCurrent ? AppTheme.primaryLight : AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildGanttRow(WbsNodeItem node, int totalDays) {
    final isCritical = node.isCriticalPath;
    final startOffsetDays = node.startDate.difference(_projectMinDate).inDays.clamp(0, totalDays);
    final durationDays = node.durationDays.clamp(1, totalDays);

    // Pixels per day scale for timeline canvas
    const double pxPerDay = 3.3;
    final double leftOffset = startOffsetDays * pxPerDay;
    final double barWidth = (durationDays * pxPerDay).clamp(32.0, 1100.0);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: indexIsOdd(node.id) ? AppTheme.surfaceCard : AppTheme.surface,
        border: const Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Left Sticky Label
          SizedBox(
            width: 140,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: node.levelColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          node.levelLabel.split(' ').first,
                          style: TextStyle(color: node.levelColor, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          node.code,
                          style: TextStyle(
                            color: isCritical ? const Color(0xFFFF8B94) : AppTheme.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    node.name,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(color: AppTheme.border, width: 1),
          // Scrollable Timeline Canvas with Gantt Bar
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1100, // 11 months * 100px
                height: 48,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Grid guide lines
                    ...List.generate(11, (i) {
                      return Positioned(
                        left: i * 100.0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 1,
                          color: AppTheme.border.withAlpha(40),
                        ),
                      );
                    }),
                    // Today Marker line (approx Sep 2026 = 330px)
                    Positioned(
                      left: 360,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 1.5,
                        color: const Color(0xFFFFB95F).withAlpha(180),
                      ),
                    ),
                    // Gantt Bar
                    Positioned(
                      left: leftOffset,
                      width: barWidth,
                      height: 24,
                      child: GestureDetector(
                        onTap: () => _showActivityInspectionSheet(node),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCritical
                                  ? [
                                      const Color(0xFFDC2626),
                                      const Color(0xFFFF334B),
                                    ]
                                  : [
                                      const Color(0xFF0284C7),
                                      const Color(0xFF38BDF8),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: isCritical
                                ? const [
                                    BoxShadow(
                                      color: Color(0x66FF334B),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                            border: Border.all(
                              color: isCritical ? const Color(0xFFFF8B94) : Colors.white24,
                              width: 0.8,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  node.code,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${node.progressPercent.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool indexIsOdd(String id) {
    return id.hashCode % 2 == 1;
  }

  /// Bottom industrial status banner
  Widget _buildFooterStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.surface,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF334B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF334B),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Driving Critical Path: ACT-204',
                  style: TextStyle(
                    color: Color(0xFFFF8B94),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.flash_on_rounded, size: 14, color: Colors.white),
              label: const Text(
                'Gemini Float Audit',
                style: TextStyle(fontSize: 11, color: Colors.white),
              ),
              onPressed: () {
                _showAiFloatAuditDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Detailed Bottom Sheet showing industrial Primavera P6 inspection data
  void _showActivityInspectionSheet(WbsNodeItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted.withAlpha(100),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.levelColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: item.levelColor),
                        ),
                        child: Text(
                          '${item.levelLabel} • ${item.discipline}',
                          style: TextStyle(
                            color: item.levelColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (item.isCriticalPath)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF334B).withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFF334B)),
                          ),
                          child: const Text(
                            'CRITICAL PATH (0d FLOAT)',
                            style: TextStyle(
                              color: Color(0xFFFF8B94),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${item.code} ${item.uwid != null ? '• UWID: ${item.uwid}' : ''}',
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (item.description != null) ...[
                    Text(
                      item.description!,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Primavera CPM Grid
                  Container(
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
                          'PRIMAVERA P6 SCHEDULE PARAMETERS',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildParamCell('Planned Start', DateFormat('dd MMM yyyy').format(item.startDate)),
                            _buildParamCell('Planned Finish', DateFormat('dd MMM yyyy').format(item.finishDate)),
                            _buildParamCell('Duration', '${item.durationDays} Days'),
                            _buildParamCell(
                              'Total Float',
                              '${item.floatDays} Days',
                              valueColor: item.floatDays == 0 ? const Color(0xFFFF5252) : AppTheme.tertiary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Multi-Source Triangulation
                  if (item.triangulation != null) ...[
                    const Text(
                      'PROGRESS TRIANGULATION CONSENSUS',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: item.triangulation!.entries.map((entry) {
                          final isConsensus = entry.key == 'Consensus';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      color: isConsensus ? AppTheme.tertiary : AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: isConsensus ? FontWeight.w800 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: entry.value / 100.0,
                                      backgroundColor: AppTheme.background,
                                      color: isConsensus ? AppTheme.tertiary : AppTheme.primaryLight,
                                      minHeight: isConsensus ? 8 : 5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${entry.value.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: isConsensus ? AppTheme.tertiary : AppTheme.textPrimary,
                                    fontSize: 11,
                                    fontWeight: isConsensus ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Equipment List
                  if (item.equipment.isNotEmpty) ...[
                    const Text(
                      'ACTIVE FIELD EQUIPMENT DEPLOYED',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: item.equipment.map((eq) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.precision_manufacturing_rounded, size: 12, color: AppTheme.secondary),
                              const SizedBox(width: 5),
                              Text(
                                eq,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Open Activity Detail'),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActivityDetailScreen(activityId: item.id),
                              ),
                            );
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

  Widget _buildParamCell(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// Dialog simulating AI Float Audit & Critical Path Slippage
  void _showAiFloatAuditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: const [
              Icon(Icons.psychology_rounded, color: AppTheme.primaryLight, size: 24),
              SizedBox(width: 8),
              Text(
                'Gemini CPM Float Audit',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Critical Path Impact Analysis:',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              SizedBox(height: 6),
              Text(
                'Activity ACT-204 (Ditch Padding & Lowering) has ZERO days of total float. '
                'Any delay exceeding 24 hours on lower-in sideboom sync will trigger day-for-day slippage on '
                'Spread 2 tie-in milestone and Section B handover.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Recommended Mitigation:',
                style: TextStyle(color: Color(0xFFFFB95F), fontWeight: FontWeight.w700, fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                '• Mobilize backup CAT 572R Sideboom from Km 08 buffer yard.\n'
                '• Parallelize 15kV spark testing with section 2 bed padding.\n'
                '• Issue FIDIC Red Book Clause 8.4 Early Warning Notice.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('FIDIC Cl. 8.4 Early Warning logged to Audit Trail'),
                    backgroundColor: AppTheme.surfaceContainerHigh,
                  ),
                );
              },
              child: const Text('Log Clause 8.4 Warning'),
            ),
          ],
        );
      },
    );
  }
}
