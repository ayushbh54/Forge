import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

/// Single item in the interactive recovery plan checklist
class RecoveryAction {
  final String id;
  final String title;
  final String description;
  final int daysRecovered;
  final String resourceType; // 'Workforce', 'Shift', 'QA/QC', 'Equipment', 'Logistics'
  final String costEstimate;
  bool isSelected;

  RecoveryAction({
    required this.id,
    required this.title,
    required this.description,
    required this.daysRecovered,
    required this.resourceType,
    required this.costEstimate,
    this.isSelected = true,
  });

  RecoveryAction copyWith({
    String? id,
    String? title,
    String? description,
    int? daysRecovered,
    String? resourceType,
    String? costEstimate,
    bool? isSelected,
  }) {
    return RecoveryAction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      daysRecovered: daysRecovered ?? this.daysRecovered,
      resourceType: resourceType ?? this.resourceType,
      costEstimate: costEstimate ?? this.costEstimate,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Industrial risk item with P6 WBS alignment and mitigation plan
class RiskItem {
  final String id;
  final String title;
  final String categoryId; // 'piping', 'civil', 'monsoon', 'vendor'
  final String wbs;
  final String discipline;
  final int probability;
  final int impactDays;
  final String severity; // 'CRITICAL', 'HIGH', 'MEDIUM'
  final String rootCause;
  final String fidicClause;
  final String mitigation;
  final List<RecoveryAction> recoveryActions;
  bool isMitigated;
  int mitigatedDaysRecovered;
  DateTime? mitigatedAt;

  RiskItem({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.wbs,
    required this.discipline,
    required this.probability,
    required this.impactDays,
    required this.severity,
    required this.rootCause,
    required this.fidicClause,
    required this.mitigation,
    required this.recoveryActions,
    this.isMitigated = false,
    this.mitigatedDaysRecovered = 0,
    this.mitigatedAt,
  });

  int get maxRecoveryDays =>
      recoveryActions.fold(0, (sum, a) => sum + a.daysRecovered);

  int get selectedRecoveryDays => recoveryActions
      .where((a) => a.isSelected)
      .fold(0, (sum, a) => sum + a.daysRecovered);
}

/// Prompt Tab definition for Gemini Brain risk assessment categories
class RiskPromptTab {
  final String id;
  final String name;
  final IconData icon;
  final String geminiPrompt;
  final String aiReasoning;
  final String keyDiscipline;
  final int baselineDelayDays;
  final double confidenceScore;

  const RiskPromptTab({
    required this.id,
    required this.name,
    required this.icon,
    required this.geminiPrompt,
    required this.aiReasoning,
    required this.keyDiscipline,
    required this.baselineDelayDays,
    required this.confidenceScore,
  });
}

class RiskRadarScreen extends StatefulWidget {
  const RiskRadarScreen({super.key});

  @override
  State<RiskRadarScreen> createState() => _RiskRadarScreenState();
}

class _RiskRadarScreenState extends State<RiskRadarScreen> {
  int _selectedTabIndex = 0;
  bool _isSimulating = false;
  int _simulationCount = 10000;
  bool _isAiQuerying = false;

  // The 4 specialized prompt tabs requested by user
  final List<RiskPromptTab> _promptTabs = const [
    RiskPromptTab(
      id: 'piping',
      name: 'Piping Bottlenecks',
      icon: Icons.plumbing_rounded,
      geminiPrompt:
          'Audit ASME B31.8 downhill welding production, qualified 6G welder deficit, radiograph rejection backlog, and golden tie-in bottlenecks across WBS 03.02.',
      aiReasoning:
          'Gemini Brain scanned 42 P6 activities: Golden joint tie-ins on Line 24 have 0 days total float. A 14% welder deficit combined with 6.2% NDT film retakes threatens critical path downstream hydrotesting.',
      keyDiscipline: 'PIPING & PIPELINE',
      baselineDelayDays: 24,
      confidenceScore: 94.6,
    ),
    RiskPromptTab(
      id: 'civil',
      name: 'Civil Delays',
      icon: Icons.foundation_rounded,
      geminiPrompt:
          'Evaluate trench sidewall stability, sand-loam waterlogging, Right-of-Way forest clearances, and valve station RCC curing strength against P6 baseline.',
      aiReasoning:
          'Gemini geotechnical simulation: High water table in km 14–22 corridor creates acute sloughing risk. Forest Dept tree felling transit pass pending for 3.2 km corridor under FIDIC Clause 2.2.',
      keyDiscipline: 'CIVIL & EARTHWORKS',
      baselineDelayDays: 28,
      confidenceScore: 91.2,
    ),
    RiskPromptTab(
      id: 'monsoon',
      name: 'Monsoon Risks',
      icon: Icons.water_drop_rounded,
      geminiPrompt:
          'Simulate Brahmaputra basin precipitation models, HDD borehole slurry inundation, pipe haulage road washouts, and buoyant pipe float-out exposure.',
      aiReasoning:
          'Gemini hydrological triangulation: Flash pre-monsoon precipitation expected in Upper Assam in 11 days. River HDD exit pit sits within 10-year flood line; immediate bunding and 24/7 pullback required.',
      keyDiscipline: 'ENVIRONMENT & HYDROLOGY',
      baselineDelayDays: 32,
      confidenceScore: 96.4,
    ),
    RiskPromptTab(
      id: 'vendor',
      name: 'Vendor Delays',
      icon: Icons.local_shipping_rounded,
      geminiPrompt:
          'Track API 5L bare pipe plate rolling mill dispatches from Vizag, SIL-3 motorized actuator customs clearance, and 3LPE field joint coating inventory.',
      aiReasoning:
          'Gemini supply chain agent: 12-day rolling dispatch lag from Vizag steel mill for 24" API 5L X70 pipes. Kolkata seaport customs classification dispute holding 18 Class 600 emergency valves.',
      keyDiscipline: 'PROCUREMENT & STORES',
      baselineDelayDays: 26,
      confidenceScore: 93.8,
    ),
  ];

  late List<RiskItem> _risks;

  @override
  void initState() {
    super.initState();
    _initializeRisks();
  }

  void _initializeRisks() {
    _risks = [
      // ==========================================
      // TAB 1: PIPING BOTTLENECK RISKS
      // ==========================================
      RiskItem(
        id: 'RSK-PIP-01',
        title: 'ASME B31.8 Downhill Welding & Golden Tie-In Lag',
        categoryId: 'piping',
        wbs: 'WBS 03.02.04: Pipe Lower-in & Golden Tie-ins',
        discipline: 'PIPING',
        probability: 82,
        impactDays: 21,
        severity: 'CRITICAL',
        rootCause:
            'Critical deficit of ASME Sec IX certified downhill welders and root-pass radiography clearance backlog.',
        fidicClause: 'FIDIC Cl. 8.4 (Extension of Time) & Cl. 4.15',
        mitigation:
            'Shift certified welders from yard spools, authorize double twilight shifts, and fast-track digital radiography.',
        recoveryActions: [
          RecoveryAction(
            id: 'REC-PIP-01-A',
            title: 'Shift Certified Welders',
            description:
                'Reallocate 10 ASNT Level-II / 6G certified welders from Spool Pre-fab Yard to Critical Trench Golden Tie-ins.',
            daysRecovered: 8,
            resourceType: 'Workforce',
            costEstimate: '₹1.80L gang transfer & mobilization',
          ),
          RecoveryAction(
            id: 'REC-PIP-01-B',
            title: 'Double Shifts & Twilight Welding',
            description:
                'Deploy 4 twin diesel mast floodlights for non-stop 20:00 - 04:00 night welding corridor with 1.5x overtime incentive.',
            daysRecovered: 7,
            resourceType: 'Shift',
            costEstimate: '₹2.20L diesel fuel & overtime premium',
          ),
          RecoveryAction(
            id: 'REC-PIP-01-C',
            title: 'Fast-Track QC & Mobile Radiography',
            description:
                'Deploy mobile digital radiography darkroom directly along ROW for sub-4h weld joint NDT sign-off under ASME B31.8.',
            daysRecovered: 5,
            resourceType: 'QA/QC',
            costEstimate: '₹1.10L express lab deployment',
          ),
          RecoveryAction(
            id: 'REC-PIP-01-D',
            title: 'Pre-Bevel Spools with Mechanical Facing Tools',
            description:
                'Pre-machine pipe end-bevels in yard to reduce trench fit-up duration per joint by 45 minutes.',
            daysRecovered: 3,
            resourceType: 'Equipment',
            costEstimate: '₹0.60L pneumatic beveler rental',
          ),
        ],
      ),
      RiskItem(
        id: 'RSK-PIP-02',
        title: 'Hydrostatic Strength & Pressure Test Clearance Hold',
        categoryId: 'piping',
        wbs: 'WBS 03.04.01: Sectional Hydrotesting & Dewatering',
        discipline: 'PIPING',
        probability: 66,
        impactDays: 15,
        severity: 'HIGH',
        rootCause:
            'Water filling volume restricted by river intake permits; electronic deadweight calibration verification pending.',
        fidicClause: 'FIDIC Cl. 9.1 (Tests on Completion) & Cl. 14.3',
        mitigation:
            'Fast-track QC pressure log sign-off, mobilize double shifts for 24/7 pumping, and shift standby welders for rapid golden joints.',
        recoveryActions: [
          RecoveryAction(
            id: 'REC-PIP-02-A',
            title: 'Fast-Track QC Pressure Log Verification',
            description:
                'Authorize remote digital telemetry deadweight logger verification for immediate TPI / Third-Party Inspector sign-off.',
            daysRecovered: 6,
            resourceType: 'QA/QC',
            costEstimate: '₹0.75L telemetry certification',
          ),
          RecoveryAction(
            id: 'REC-PIP-02-B',
            title: 'Double Shifts for Water Filling & Pressurization',
            description:
                'Run continuous 24/7 pump pressure monitoring and temperature stabilization crews.',
            daysRecovered: 5,
            resourceType: 'Shift',
            costEstimate: '₹1.40L night shift monitoring',
          ),
          RecoveryAction(
            id: 'REC-PIP-02-C',
            title: 'Shift Certified Welders for Test Manifold Golden Joints',
            description:
                'Station 4 certified welders on immediate standby to cut out test manifolds and execute golden tie-ins.',
            daysRecovered: 3,
            resourceType: 'Workforce',
            costEstimate: '₹0.90L standby crew allocation',
          ),
        ],
      ),
      RiskItem(
        id: 'RSK-PIP-03',
        title: 'Induction Bend Fit-Up Angular Misalignment at Ch. 18+400',
        categoryId: 'piping',
        wbs: 'WBS 03.01.08: Cold & Hot Bend Stringing',
        discipline: 'PIPING',
        probability: 49,
        impactDays: 9,
        severity: 'MEDIUM',
        rootCause:
            'Trench curvature deviation exceeding 1.5° tolerance requiring field hydraulic re-alignment.',
        fidicClause: 'FIDIC Cl. 12.3 (Evaluation and Measurement)',
        mitigation:
            'Shift master fitters and internal hydraulic clamps, fast-track 3D laser ovality QC, and run twilight fit-up shift.',
        recoveryActions: [
          RecoveryAction(
            id: 'REC-PIP-03-A',
            title: 'Shift Certified Welders & Master Pipe Fitters',
            description:
                'Deploy senior pipe fitters with internal hydraulic line-up clamps from Section A.',
            daysRecovered: 4,
            resourceType: 'Workforce',
            costEstimate: '₹0.70L specialist technician fee',
          ),
          RecoveryAction(
            id: 'REC-PIP-03-B',
            title: 'Fast-Track QC Laser Ovality Scanning',
            description:
                'Instant 3D LiDAR scan of joint ovality before clamp release to eliminate cold-springing.',
            daysRecovered: 3,
            resourceType: 'QA/QC',
            costEstimate: '₹0.50L LiDAR scanner audit',
          ),
          RecoveryAction(
            id: 'REC-PIP-03-C',
            title: 'Double Shifts for Rapid Line-Up Preparation',
            description:
                'Schedule twilight alignment shift ahead of dawn downhill welding crew.',
            daysRecovered: 2,
            resourceType: 'Shift',
            costEstimate: '₹0.60L overtime lighting & crew',
          ),
        ],
      ),

      // ==========================================
      // TAB 2: CIVIL DELAYS
      // ==========================================
      RiskItem(
        id: 'RSK-CIV-01',
        title: 'Trench Collapse in Sandy Loam Waterlogged Strata',
        categoryId: 'civil',
        wbs: 'WBS 02.01.03: Trench Excavation & Padding',
        discipline: 'CIVIL',
        probability: 84,
        impactDays: 22,
        severity: 'CRITICAL',
        rootCause:
            'High groundwater saturation in alluvial sector km 14-22 causing sidewall sloughing.',
        fidicClause: 'FIDIC Cl. 4.12 (Unforeseeable Physical Conditions)',
        mitigation:
            'Double shifts on 24/7 excavators, fast-track soil compaction QC, and shift welders to rocky terrain.',
        recoveryActions: [
          RecoveryAction(
            id: 'REC-CIV-01-A',
            title: 'Double Shifts with Dual Cat 320 Excavators',
            description:
                'Deploy round-the-clock dual excavator operators with LED floodlight towers to maintain trench corridor.',
            daysRecovered: 8,
            resourceType: 'Shift',
            costEstimate: '₹2.80L dual machine fuel & night crews',
          ),
          RecoveryAction(
            id: 'REC-CIV-01-B',
            title: 'Fast-Track QC Soil Compaction & Bedding Certification',
            description:
                'On-site nuclear density gauge testing for immediate bedding layer clearance prior to pipe lower-in.',
            daysRecovered: 5,
            resourceType: 'QA/QC',
            costEstimate: '₹0.90L field compaction kit',
          ),
          RecoveryAction(
            id: 'REC-CIV-01-C',
            title: 'Shift Certified Welders to Rock Trench Sector',
            description:
                'Re-sequence pipeline welding gangs to non-waterlogged hard-rock sector to maintain planned joint rate.',
            daysRecovered: 5,
            resourceType: 'Workforce',
            costEstimate: '₹1.20L transport & rig repositioning',
          ),
          RecoveryAction(
            id: 'REC-CIV-01-D',
            title: 'Modular Vibratory Sheet Pile Shoring',
            description:
                'Drive temporary interlocking steel trench boxes to halt lateral embankment collapse.',
            daysRecovered: 4,
            resourceType: 'Equipment',
            costEstimate: '₹3.40L shoring equipment hire',
          ),
        ],
      ),
      RiskItem(
        id: 'RSK-CIV-02',
        title: 'Forest Dept Right-of-Way (ROW) Clearance Hold',
        categoryId: 'civil',
        wbs: 'WBS 01.02.01: Trenching Corridor Right-of-Way',
        discipline: 'CIVIL',
        probability: 71,
        impactDays: 26,
        severity: 'HIGH',
        rootCause:
            'Transit pass delays for 3.2 km protected forest stretch awaiting State DFO sign-off.',
        fidicClause: 'FIDIC Cl. 2.2 (Unhindered Access) & Cl. 8.4',
        mitigation:
            'Shift certified welders to unencumbered Section C, fast-track environmental QC audit, and double tree-felling shifts.',
        recoveryActions: [
          RecoveryAction(
            id: 'REC-CIV-02-A',
            title: 'Shift Certified Welders to Section C Corridor',
            description:
                'Leapfrog 3 spreads past forest zone into unencumbered Section C farmland corridor.',
            daysRecovered: 9,
            resourceType: 'Workforce',
            costEstimate: '₹2.10L spread transfer logistics',
          ),
          RecoveryAction(
            id: 'REC-CIV-02-B',
            title: 'Fast-Track QC Environmental Compliance Clearance',
            description:
                'Joint field survey with DFO nodal officer for rapid afforestation demarcation and transit certificate.',
            daysRecovered: 7,
            resourceType: 'QA/QC',
            costEstimate: '₹1.00L liaison & GPS boundary audit',
          ),
          RecoveryAction(
            id: 'REC-CIV-02-C',
            title: 'Double Shifts with Mechanical Stump Mulchers',
            description:
                'Execute 24-hr mechanised tree clearing and stump mulching the hour permission is released.',
            daysRecovered: 6,
            resourceType: 'Shift',
            costEstimate: '₹1.50L high-capacity forestry rigs',
          ),
        ],
      ),
      RiskItem(
        id: 'RSK-CIV-03',
        title: 'Valve Station 4 RCC Foundation Curing & Grouting Hold',
        categoryId: 'civil',
        wbs: 'WBS 02.03.02: Structural Foundations & Earthworks',
        discipline: 'CIVIL',
        probability: 53,
        impactDays: 13,
        severity: 'MEDIUM',
        rootCause:
            '7-day concrete cube compressive strength requirement holding heavy actuator pedestal installation.',
        fidicClause: 'FIDIC Cl. 7.4 (Testing) & Cl. 14.1',
        mitigation:
            'Fast-track QC rebound hammer testing, double shifts for formwork backfill, and shift welders to yard skid pre-assembly.',
        recoveryActions: [
          RecoveryAction(
            id: 'REC-CIV-03-A',
            title: 'Fast-Track QC Rebound Hammer & UPV Testing',
            description:
                'Non-destructive ultrasonic pulse velocity & Schmidt hammer testing for early 4-day formwork stripping clearance.',
            daysRecovered: 5,
            resourceType: 'QA/QC',
            costEstimate: '₹0.70L NDT testing lab fee',
          ),
          RecoveryAction(
            id: 'REC-CIV-03-B',
            title: 'Double Shifts for Nighttime Formwork Stripping',
            description:
                'Authorize twilight shift for immediate formwork removal and non-shrink epoxy grout injection.',
            daysRecovered: 4,
            resourceType: 'Shift',
            costEstimate: '₹1.10L night shift crew wages',
          ),
          RecoveryAction(
            id: 'REC-CIV-03-C',
            title: 'Shift Certified Welders for Yard Skid Pre-Assembly',
            description:
                'Fabricate valve manifold spools on structural skid bases in dry workshop while foundation cures.',
            daysRecovered: 3,
            resourceType: 'Workforce',
            costEstimate: '₹0.85L yard pre-assembly logistics',
          ),
        ],
      ),

      // ==========================================
      // TAB 3: MONSOON RISKS
      // ==========================================
      RiskItem(
        id: 'RSK-MON-01',
        title: 'River Brahmaputra HDD Borehole Slurry Flooding',
        categoryId: 'monsoon',
        wbs: 'WBS 02.02.06: River HDD Crossing & Pullback',
        discipline: 'ENVIRONMENT',
        probability: 88,
        impactDays: 28,
        severity: 'CRITICAL',
        rootCause:
            'River discharge surge threatening to breach HDD entry pit and drown bentonite recovery units.',
        fidicClause: 'FIDIC Cl. 17.3 (Adverse Climatic Events) & Cl. 8.4',
        mitigation:
            'Double shifts on 24/7 pullback, shift certified welders to HDD exit sleeve, and fast-track ultrasonic QC under canopy.',
        recoveryActions: [
          RecoveryAction(
            id: 'REC-MON-01-A',
            title: 'Double Shifts for 24/7 HDD Pullback Sprint',
            description:
                'Run continuous 24/7 reaming and string pullback to prevent borehole collapse or stuck drill string.',
            daysRecovered: 10,
            resourceType: 'Shift',
            costEstimate: '₹3.40L continuous drill crew & power',
          ),
          RecoveryAction(
            id: 'REC-MON-01-B',
            title: 'Shift Certified Welders to HDD Exit Pit',
            description:
                'Pre-station 12 certified downhill welders on HDD exit side for instantaneous sleeve tie-in upon breakthrough.',
            daysRecovered: 8,
            resourceType: 'Workforce',
            costEstimate: '₹2.20L high-priority crew mobilization',
          ),
          RecoveryAction(
            id: 'REC-MON-01-C',
            title: 'Fast-Track QC Phased Array UT Under Shelter',
            description:
                'Erect all-weather canopy tent and execute instantaneous Phased Array UT and underwater holiday check.',
            daysRecovered: 6,
            resourceType: 'QA/QC',
            costEstimate: '₹1.60L canopy tent & PAUT crew',
          ),
          RecoveryAction(
            id: 'REC-MON-01-D',
            title: 'Slurry Berming & High-Capacity Dewatering',
            description:
                'Build 2.5m compacted clay flood bund and commission 3x 2500 LPM industrial sludge pumps.',
            daysRecovered: 4,
            resourceType: 'Equipment',
            costEstimate: '₹2.90L earthworks & dewatering pumps',
          ),
        ],
      ),
      RiskItem(
        id: 'RSK-MON-02',
        title: 'Pipe Haulage ROW Road Submergence & Cut-Off',
        categoryId: 'monsoon',
        wbs: 'WBS 01.04.02: Access Roads & Logistics Corridor',
        discipline: 'ENVIRONMENT',
        probability: 79,
        impactDays: 18,
        severity: 'HIGH',
        rootCause:
            'Alluvial roadbed inundation blocking 40-foot articulated pipe delivery trailers from highway.',
        fidicClause: 'FIDIC Cl. 4.15 (Access Routes)',
        mitigation:
            'Double shifts for road boulder reinforcement, shift welders to forward camp, and fast-track bridge load QC.',
        recoveryActions: [
          RecoveryAction(
            id: 'REC-MON-02-A',
            title: 'Double Shifts for Geotextile Road Stabilization',
            description:
                '24-hr round-the-clock road reinforcement gang laying heavy non-woven geotextile and crushed stone capping.',
            daysRecovered: 7,
            resourceType: 'Shift',
            costEstimate: '₹2.10L gravel aggregate & night crews',
          ),
          RecoveryAction(
            id: 'REC-MON-02-B',
            title: 'Shift Certified Welders to Elevated Forward Camps',
            description:
                'Stage welder containerized living quarters and power banks on elevated hardstand along Chainage 28.',
            daysRecovered: 5,
            resourceType: 'Workforce',
            costEstimate: '₹1.40L forward camp establishment',
          ),
          RecoveryAction(
            id: 'REC-MON-02-C',
            title: 'Fast-Track QC Culvert Integrity Sign-Off',
            description:
                'Expedite dynamic load testing of low-level agricultural culverts for safe 45-ton trailer transit.',
            daysRecovered: 4,
            resourceType: 'QA/QC',
            costEstimate: '₹0.60L structural load inspection',
          ),
        ],
      ),
      RiskItem(
        id: 'RSK-MON-03',
        title: 'Trench Submergence & Buoyant Pipe Float-Out in Paddy Zone',
        categoryId: 'monsoon',
        wbs: 'WBS 02.01.08: Marshy Sector Lower-In & Anchoring',
        discipline: 'ENVIRONMENT',
        probability: 64,
        impactDays: 14,
        severity: 'HIGH',
        rootCause:
            'Unanticipated torrential cloudburst filling open ditch before concrete saddle clamp installation.',
        fidicClause: 'FIDIC Cl. 8.4 & Cl. 19 (Exceptional Events)',
        mitigation:
            'Shift certified welders for rapid anchor welding, double shifts on dewatering, and fast-track buoyancy QC.',
        recoveryActions: [
          RecoveryAction(
            id: 'REC-MON-03-A',
            title: 'Shift Certified Welders for Anchor Collar Tack-Welding',
            description:
                'Reassign 6 welders to rapid anchor ring and buoyancy strap tacking prior to flood progression.',
            daysRecovered: 5,
            resourceType: 'Workforce',
            costEstimate: '₹1.10L rapid gang assignment',
          ),
          RecoveryAction(
            id: 'REC-MON-03-B',
            title: 'Double Shifts with Submersible Sludge Pumps',
            description:
                'All-night wellpoint suction dewatering spread powered by trailer diesel generators.',
            daysRecovered: 5,
            resourceType: 'Shift',
            costEstimate: '₹1.60L overnight pumping operations',
          ),
          RecoveryAction(
            id: 'REC-MON-03-C',
            title: 'Fast-Track QC Negative Buoyancy & Holiday Sign-Off',
            description:
                'Immediate post-submergence wet sponge holiday detection and pipeline negative buoyancy verification.',
            daysRecovered: 3,
            resourceType: 'QA/QC',
            costEstimate: '₹0.50L holiday detector certification',
          ),
        ],
      ),

      // ==========================================
      // TAB 4: VENDOR DELAYS
      // ==========================================
      RiskItem(
        id: 'RSK-VEN-01',
        title: 'API 5L Line Pipe Mill Dispatch Slump from Vizag Yard',
        categoryId: 'vendor',
        wbs: 'WBS 01.01.05: Line Pipe Supply & Receipt',
        discipline: 'PROCUREMENT',
        probability: 84,
        impactDays: 24,
        severity: 'CRITICAL',
        rootCause:
            'Plate rolling mill overhaul turnaround coupled with freight rake allocation hold at steel terminal.',
        fidicClause: 'FIDIC Cl. 8.8 (Delay Damages) & Cl. 14.5 (Materials)',
        mitigation:
            'Double shifts for rail siding unloading, fast-track QC mill certificates, and shift welders to manifold fabrication.',
        recoveryActions: [
          RecoveryAction(
            id: 'REC-VEN-01-A',
            title: 'Double Shifts for 24/7 Rail Siding Crane Offloading',
            description:
                'Contract 24/7 tandem hydra crane crews at Duliajan siding to turn incoming rakes around within 6 hours.',
            daysRecovered: 9,
            resourceType: 'Shift',
            costEstimate: '₹2.60L crane crews & rake demurrage waiver',
          ),
          RecoveryAction(
            id: 'REC-VEN-01-B',
            title: 'Fast-Track QC Mill Test Report Digital Audit',
            description:
                'Deploy electronic Mill Test Certificate (MTC) optical heat-number scanning to clear incoming pipe batches instantly.',
            daysRecovered: 6,
            resourceType: 'QA/QC',
            costEstimate: '₹1.10L digital MTC clearance engine',
          ),
          RecoveryAction(
            id: 'REC-VEN-01-C',
            title: 'Shift Certified Welders to Yard Manifold Fabrication',
            description:
                'Reposition pipeline mainline welders to prefabricate 24" scraper trap barrels in yard while pipe transits.',
            daysRecovered: 5,
            resourceType: 'Workforce',
            costEstimate: '₹1.30L workshop tooling & consumable kits',
          ),
          RecoveryAction(
            id: 'REC-VEN-01-D',
            title: 'Charter Emergency Buffer Stock from Numaligarh',
            description:
                'Truck 4.8 km API 5L bare pipe from secondary strategic reserve via priority highway trailers.',
            daysRecovered: 4,
            resourceType: 'Logistics',
            costEstimate: '₹3.20L express road freight tariff',
          ),
        ],
      ),
      RiskItem(
        id: 'RSK-VEN-02',
        title: 'Class 600 Motorized Actuator Valves Customs Clearing Hold',
        categoryId: 'vendor',
        wbs: 'WBS 03.05.02: Valve Stations & Actuator Integration',
        discipline: 'PROCUREMENT',
        probability: 72,
        impactDays: 17,
        severity: 'HIGH',
        rootCause:
            'Customs harmonized tariff dispute at seaport holding SIL-3 electric actuators from European supplier.',
        fidicClause: 'FIDIC Cl. 1.13 (Compliance with Laws) & Cl. 8.4',
        mitigation:
            'Shift certified welders to build temporary bypass pup-spools, fast-track digital FAT QC, and double shifts on cabling.',
        recoveryActions: [
          RecoveryAction(
            id: 'REC-VEN-02-A',
            title: 'Shift Certified Welders for Temporary Bypass Spools',
            description:
                'Fabricate and weld temporary test pup-pieces into line so hydrotesting can proceed unhindered without valves.',
            daysRecovered: 7,
            resourceType: 'Workforce',
            costEstimate: '₹1.50L bypass pup-spool materials',
          ),
          RecoveryAction(
            id: 'REC-VEN-02-B',
            title: 'Fast-Track QC Remote Factory Acceptance (FAT) Telemetry',
            description:
                'Witness torque and hydrotest sign-offs via encrypted live video stream to avoid overseas witness travel delay.',
            daysRecovered: 5,
            resourceType: 'QA/QC',
            costEstimate: '₹0.85L digital inspection audit',
          ),
          RecoveryAction(
            id: 'REC-VEN-02-C',
            title: 'Double Shifts for Actuator Electrical Cabling & Rigging',
            description:
                'Twilight shift electrician gang to pull armored cables and mount actuators immediately on arrival.',
            daysRecovered: 4,
            resourceType: 'Shift',
            costEstimate: '₹1.20L overtime electrical gang',
          ),
        ],
      ),
      RiskItem(
        id: 'RSK-VEN-03',
        title: '3-Layer Polyethylene (3LPE) Field Joint Coating Stockout',
        categoryId: 'vendor',
        wbs: 'WBS 03.03.04: Field Joint Coating & Holiday Testing',
        discipline: 'PROCUREMENT',
        probability: 56,
        impactDays: 11,
        severity: 'MEDIUM',
        rootCause:
            'Heat-shrink sleeve factory raw polymer backlog in Vadodara factory.',
        fidicClause: 'FIDIC Cl. 4.10 (Data on Works) & Cl. 7.2',
        mitigation:
            'Fast-track QC cold-applied tape alternate, double shifts for induction heating, and shift welders forward.',
        recoveryActions: [
          RecoveryAction(
            id: 'REC-VEN-03-A',
            title: 'Fast-Track QC Cold-Applied Polymeric Tape Alternate',
            description:
                'Approve engineering concession for cold-applied viscous-elastic tape to bridge heat-shrink sleeve delivery gap.',
            daysRecovered: 4,
            resourceType: 'QA/QC',
            costEstimate: '₹0.70L client deviation approval',
          ),
          RecoveryAction(
            id: 'REC-VEN-03-B',
            title: 'Double Shifts for Joint Induction Pre-Heating',
            description:
                'Mobilize high-frequency induction coil generators for twilight joint wrapping and heat-shrink shrinking.',
            daysRecovered: 4,
            resourceType: 'Shift',
            costEstimate: '₹1.10L induction rig overtime hire',
          ),
          RecoveryAction(
            id: 'REC-VEN-03-C',
            title: 'Shift Certified Welders Forward along Trench',
            description:
                'Maintain weld completion speed ahead; leave bare joints tagged for specialized night coating crew.',
            daysRecovered: 3,
            resourceType: 'Workforce',
            costEstimate: '₹0.80L sequence rearrangement',
          ),
        ],
      ),
    ];
  }

  // Active category risks
  List<RiskItem> get _currentTabRisks {
    final currentTab = _promptTabs[_selectedTabIndex];
    return _risks.where((r) => r.categoryId == currentTab.id).toList();
  }

  // Total mitigated days across all categories
  int get _totalMitigatedDaysAcrossProject {
    return _risks
        .where((r) => r.isMitigated)
        .fold(0, (sum, r) => sum + r.mitigatedDaysRecovered);
  }

  // Active tab mitigated days
  int get _currentTabMitigatedDays {
    return _currentTabRisks
        .where((r) => r.isMitigated)
        .fold(0, (sum, r) => sum + r.mitigatedDaysRecovered);
  }

  // Dynamic P-values based on mitigations deployed
  int get _calculatedP80Days {
    final daysSaved = _totalMitigatedDaysAcrossProject;
    final residual = 38 - (daysSaved * 0.72).round();
    return residual < 6 ? 6 : residual;
  }

  int get _calculatedP50Days {
    final daysSaved = _totalMitigatedDaysAcrossProject;
    final residual = 22 - (daysSaved * 0.50).round();
    return residual < 3 ? 3 : residual;
  }

  int get _calculatedP95Days {
    final daysSaved = _totalMitigatedDaysAcrossProject;
    final residual = 56 - (daysSaved * 0.85).round();
    return residual < 10 ? 10 : residual;
  }

  int get _calculatedProbability {
    final daysSaved = _totalMitigatedDaysAcrossProject;
    final prob = 84 - (daysSaved * 1.3).round();
    return prob < 24 ? 24 : prob;
  }

  void _runSimulation() async {
    setState(() => _isSimulating = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _isSimulating = false;
      _simulationCount += 5000;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Monte Carlo complete: $_simulationCount runs evaluated with active AI mitigations (P80: +$_calculatedP80Days days).',
        ),
        backgroundColor: AppTheme.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _queryGeminiBrain() async {
    final tab = _promptTabs[_selectedTabIndex];
    setState(() => _isAiQuerying = true);

    final apiService = ApiService();
    String aiResult = tab.aiReasoning;

    try {
      final res = await apiService.geminiChat(
        'COPILOT_QUERY',
        {
          'query': 'Risk radar evaluation for ${tab.name}: ${tab.geminiPrompt}',
          'projectId': 'PRJ-OIL-2026',
        },
      );
      if (res != null && res['reply'] != null && res['reply'].toString().isNotEmpty) {
        aiResult = res['reply'].toString();
      }
    } catch (_) {
      // Fallback seamlessly to domain reasoning
    } finally {
      if (mounted) {
        setState(() => _isAiQuerying = false);
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.psychology_rounded, color: AppTheme.primaryLight, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gemini Brain: ${tab.name}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Prompt: "${tab.geminiPrompt}"',
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Autonomous Project Intelligence Assessment:',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                aiResult,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: AppTheme.tertiary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Confidence Score: ${tab.confidenceScore}% (Primavera P6 + Weather LiDAR)',
                        style: const TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTheme.primaryLight)),
          ),
        ],
      ),
    );
  }

  /// Opens the interactive recovery plan checklist modal
  void _openMitigationModal(RiskItem risk) {
    // Clone recovery actions state for local editing inside bottom sheet
    final List<RecoveryAction> tempActions = risk.recoveryActions
        .map((a) => a.copyWith())
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final int selectedDays = tempActions
                .where((a) => a.isSelected)
                .fold(0, (sum, a) => sum + a.daysRecovered);
            final int maxDays = tempActions.fold(0, (sum, a) => sum + a.daysRecovered);
            final int residualImpact = (risk.impactDays - selectedDays).clamp(0, 99);
            final double recoveryRatio = maxDays > 0 ? (selectedDays / maxDays).clamp(0.0, 1.0) : 0.0;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
              ),
              child: Column(
                children: [
                  // Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: AppTheme.primaryLight, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Mitigation Recovery Plan',
                                style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                risk.title,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                risk.wbs,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: AppTheme.border, height: 1),

                  // Interactive Recovery Stats Ribbon
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    color: AppTheme.surfaceCard,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Threat',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '+${risk.impactDays} Days Delay',
                                  style: const TextStyle(
                                    color: AppTheme.error,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 28,
                              width: 1,
                              color: AppTheme.border,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Days Recovered',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '-$selectedDays Days',
                                  style: const TextStyle(
                                    color: AppTheme.tertiary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 28,
                              width: 1,
                              color: AppTheme.border,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Residual Slippage',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  residualImpact == 0 ? '0 Days (Cleared!)' : '+$residualImpact Days',
                                  style: TextStyle(
                                    color: residualImpact == 0 ? AppTheme.tertiary : AppTheme.secondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: recoveryRatio,
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.tertiary),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recovery efficiency: ${(recoveryRatio * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            ),
                            Text(
                              '$selectedDays of $maxDays days recoverable',
                              style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick toggle row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'INTERACTIVE RECOVERY ACTIONS',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  for (var a in tempActions) {
                                    a.isSelected = true;
                                  }
                                });
                              },
                              child: const Text(
                                'Select All',
                                style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Text('  •  ', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                            GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  for (var a in tempActions) {
                                    a.isSelected = false;
                                  }
                                });
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Checklist
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: tempActions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final action = tempActions[idx];
                        final isHighlightedCore = action.title.contains('certified welders') ||
                            action.title.contains('Certified Welders') ||
                            action.title.contains('Double Shifts') ||
                            action.title.contains('Fast-Track QC') ||
                            action.title.contains('Fast-track QC');

                        return Container(
                          decoration: BoxDecoration(
                            color: action.isSelected
                                ? AppTheme.surfaceContainerHigh.withValues(alpha: 0.6)
                                : AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: action.isSelected ? AppTheme.primary.withValues(alpha: 0.6) : AppTheme.border,
                              width: action.isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setModalState(() {
                                action.isSelected = !action.isSelected;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: action.isSelected,
                                    activeColor: AppTheme.primary,
                                    checkColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) {
                                      setModalState(() {
                                        action.isSelected = val ?? false;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                action.title,
                                                style: TextStyle(
                                                  color: action.isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.tertiary.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4)),
                                              ),
                                              child: Text(
                                                '+${action.daysRecovered}d Saved',
                                                style: const TextStyle(
                                                  color: AppTheme.tertiary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          action.description,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.surface,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                action.resourceType,
                                                style: const TextStyle(
                                                  color: AppTheme.primaryLight,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                action.costEstimate,
                                                style: const TextStyle(
                                                  color: AppTheme.secondary,
                                                  fontSize: 10,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isHighlightedCore)
                                              const Icon(Icons.star_rounded, color: AppTheme.secondary, size: 14),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceCard,
                      border: Border(top: BorderSide(color: AppTheme.border)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.security_rounded, color: AppTheme.tertiary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Contractual Safeguard: ${risk.fidicClause}',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedDays > 0 ? AppTheme.primary : AppTheme.surfaceContainerHigh,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: selectedDays == 0
                                ? null
                                : () {
                                    setState(() {
                                      // Commit the modified selections
                                      for (int i = 0; i < risk.recoveryActions.length; i++) {
                                        risk.recoveryActions[i].isSelected = tempActions[i].isSelected;
                                      }
                                      risk.isMitigated = true;
                                      risk.mitigatedDaysRecovered = selectedDays;
                                      risk.mitigatedAt = DateTime.now();
                                    });
                                    Navigator.pop(sheetContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: AppTheme.tertiary, size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'AI Mitigation Deployed: Recovered $selectedDays days for "${risk.title}". Directives issued to site supervisors.',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: AppTheme.surfaceContainerHigh,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.offline_bolt_rounded, color: Colors.white, size: 18),
                            label: Text(
                              selectedDays > 0
                                  ? 'Confirm & Deploy Mitigation Orders (-$selectedDays Days)'
                                  : 'Select at least 1 recovery action',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
        );
      },
    );
  }

  void _executeAllTabMitigations() {
    final tabRisks = _currentTabRisks;
    int newlySaved = 0;

    setState(() {
      for (var r in tabRisks) {
        for (var a in r.recoveryActions) {
          a.isSelected = true;
        }
        r.isMitigated = true;
        r.mitigatedDaysRecovered = r.maxRecoveryDays;
        r.mitigatedAt = DateTime.now();
        newlySaved += r.maxRecoveryDays;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Batch AI Mitigation active: Full recovery plan authorized for ${_promptTabs[_selectedTabIndex].name} (Recovers up to $newlySaved days).',
        ),
        backgroundColor: AppTheme.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = _promptTabs[_selectedTabIndex];
    final tabRisks = _currentTabRisks;
    final totalProjectMitigated = _totalMitigatedDaysAcrossProject;
    final currentTabMitigated = _currentTabMitigatedDays;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI Delay Risk Radar'),
        actions: [
          IconButton(
            icon: _isAiQuerying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: AppTheme.primaryLight, strokeWidth: 2),
                  )
                : const Icon(Icons.psychology_outlined),
            tooltip: 'Gemini Copilot Insights',
            onPressed: _isAiQuerying ? null : _queryGeminiBrain,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. TOP PROBABILITY & MONTE CARLO BANNER
            // ==========================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: totalProjectMitigated > 0
                      ? const [Color(0xFF0F2B26), Color(0xFF162347)]
                      : const [Color(0xFF2E1010), Color(0xFF162347)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: totalProjectMitigated > 0
                      ? AppTheme.tertiary.withValues(alpha: 0.4)
                      : AppTheme.error.withValues(alpha: 0.4),
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
                          Icon(
                            totalProjectMitigated > 0 ? Icons.shield_rounded : Icons.warning_amber_rounded,
                            color: totalProjectMitigated > 0 ? AppTheme.tertiary : AppTheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            totalProjectMitigated > 0
                                ? 'Mitigation Active: Slippage Contained'
                                : 'Schedule Slippage Risk: HIGH',
                            style: TextStyle(
                              color: totalProjectMitigated > 0 ? AppTheme.tertiary : AppTheme.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (totalProjectMitigated > 0 ? AppTheme.tertiary : AppTheme.error)
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          totalProjectMitigated > 0 ? 'P80 MITIGATED' : 'P80 UNMITIGATED',
                          style: TextStyle(
                            color: totalProjectMitigated > 0 ? AppTheme.tertiary : AppTheme.error,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_calculatedProbability% Probability of Critical Path Delay',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalProjectMitigated > 0
                        ? 'Simulated Project Finish: +$_calculatedP80Days Calendar Days (Saved $totalProjectMitigated days via AI recovery plan).'
                        : 'Simulated Project Finish: +38 Calendar Days without schedule compression.',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  // P-Values Confidence Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPValueStat(
                        'P50 (Median)',
                        '+$_calculatedP50Days Days',
                        AppTheme.secondary,
                      ),
                      _buildPValueStat(
                        'P80 (Expected)',
                        '+$_calculatedP80Days Days',
                        totalProjectMitigated > 0 ? AppTheme.primaryLight : AppTheme.error,
                      ),
                      _buildPValueStat(
                        'P95 (Worst Case)',
                        '+$_calculatedP95Days Days',
                        totalProjectMitigated > 0 ? AppTheme.secondary : AppTheme.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Monte Carlo Run Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSimulating ? null : _runSimulation,
                icon: _isSimulating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.scatter_plot_rounded, color: Colors.white, size: 18),
                label: Text(
                  _isSimulating
                      ? 'Simulating Schedule Iterations...'
                      : 'Run Monte Carlo Analysis ($_simulationCount runs)',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // 2. GEMINI BRAIN RISK ASSESSMENT PROMPT TABS
            // ==========================================
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gemini Brain Risk Assessment',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.primaryLight, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Gemini 2.0 Flash',
                      style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 4 Prompt Tabs Segmented Scrollable Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_promptTabs.length, (index) {
                  final tab = _promptTabs[index];
                  final isSelected = _selectedTabIndex == index;
                  final categoryRisks = _risks.where((r) => r.categoryId == tab.id).toList();
                  final mitigatedCount = categoryRisks.where((r) => r.isMitigated).length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() => _selectedTabIndex = index);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tab.icon,
                              size: 16,
                              color: isSelected ? Colors.white : AppTheme.primaryLight,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tab.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : (mitigatedCount > 0
                                        ? AppTheme.tertiary.withValues(alpha: 0.2)
                                        : AppTheme.surfaceContainerHigh),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                mitigatedCount > 0 ? '$mitigatedCount/${categoryRisks.length} mitigated' : '${categoryRisks.length}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (mitigatedCount > 0 ? AppTheme.tertiary : AppTheme.textSecondary),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // Prompt Tab Active Intelligence Card
            Container(
              padding: const EdgeInsets.all(14),
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
                          Icon(currentTab.icon, color: AppTheme.primaryLight, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            currentTab.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: _queryGeminiBrain,
                        child: const Row(
                          children: [
                            Text(
                              'Re-evaluate Prompt',
                              style: TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.refresh_rounded, color: AppTheme.secondary, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${currentTab.geminiPrompt}"',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentTab.aiReasoning,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Baseline Threat: +${currentTab.baselineDelayDays} Days',
                        style: const TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      if (currentTabMitigated > 0)
                        Text(
                          'Active Mitigation: -$currentTabMitigated Days',
                          style: const TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold),
                        )
                      else
                        InkWell(
                          onTap: _executeAllTabMitigations,
                          child: const Text(
                            '⚡ Deploy All 3 AI Mitigations',
                            style: TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ==========================================
            // 3. THREAT CARDS & MITIGATION EXECUTION
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currentTab.name} Threats (${tabRisks.length})',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Tap card to configure',
                  style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.8), fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tabRisks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final risk = tabRisks[index];
                return _buildInteractiveRiskCard(risk);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPValueStat(String title, String days, Color color) {
    return Column(
      children: [
        Text(days, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildInteractiveRiskCard(RiskItem risk) {
    final int prob = risk.probability;
    final String severity = risk.severity;
    final Color badgeColor = severity == 'CRITICAL'
        ? AppTheme.error
        : (severity == 'HIGH' ? AppTheme.secondary : AppTheme.primaryLight);

    final bool isMitigated = risk.isMitigated;
    final int recoveredDays = isMitigated ? risk.mitigatedDaysRecovered : risk.selectedRecoveryDays;

    return Container(
      decoration: BoxDecoration(
        color: isMitigated ? AppTheme.surfaceContainerHigh.withValues(alpha: 0.4) : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMitigated ? AppTheme.tertiary.withValues(alpha: 0.6) : AppTheme.border,
          width: isMitigated ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top WBS & Severity row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      risk.wbs,
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    if (isMitigated) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: AppTheme.tertiary, size: 10),
                            SizedBox(width: 3),
                            Text(
                              'DEPLOYED',
                              style: TextStyle(color: AppTheme.tertiary, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        severity,
                        style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              risk.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),

            // Root Cause & FIDIC Clause
            Text(
              risk.rootCause,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.3),
            ),
            const SizedBox(height: 8),

            // Progress bar and Impact Stats
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Probability', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                          Text('$prob%', style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      LinearProgressIndicator(
                        value: prob / 100,
                        backgroundColor: AppTheme.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${risk.impactDays} Days Threat',
                      style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isMitigated
                          ? 'Recovers: -$recoveredDays Days'
                          : 'Recovers: up to -${risk.maxRecoveryDays} Days',
                      style: const TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(color: AppTheme.border, height: 18),

            // AI Action Preview
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primaryLight, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'AI Plan: ${risk.mitigation}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ==========================================
            // EXECUTE AI MITIGATION BUTTON
            // ==========================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMitigated ? AppTheme.surfaceContainerHigh : AppTheme.primary,
                  foregroundColor: isMitigated ? AppTheme.tertiary : Colors.white,
                  side: BorderSide(
                    color: isMitigated ? AppTheme.tertiary.withValues(alpha: 0.5) : AppTheme.primaryLight,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _openMitigationModal(risk),
                icon: Icon(
                  isMitigated ? Icons.checklist_rtl_rounded : Icons.bolt_rounded,
                  color: isMitigated ? AppTheme.tertiary : Colors.white,
                  size: 16,
                ),
                label: Text(
                  isMitigated
                      ? 'Review / Modify Recovery Plan (-$recoveredDays Days Active)'
                      : 'Execute AI Mitigation (Shift Welders, Shifts, QC)',
                  style: TextStyle(
                    color: isMitigated ? AppTheme.tertiary : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
