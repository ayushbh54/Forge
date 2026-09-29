import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

// ---------------------------------------------------------------------------
// ENUMS & ROLE ACCESS SPECIFICATION
// ---------------------------------------------------------------------------

enum StakeholderRole {
  clientDirector,
  epcMainContractor,
  thirdPartyInspector,
  subcontractorForeman,
}

extension StakeholderRoleExt on StakeholderRole {
  String get title {
    switch (this) {
      case StakeholderRole.clientDirector:
        return 'Client / Oil India Director';
      case StakeholderRole.epcMainContractor:
        return 'EPC Main Contractor / L&T';
      case StakeholderRole.thirdPartyInspector:
        return 'Third-Party Inspection / EIL-TPIA';
      case StakeholderRole.subcontractorForeman:
        return 'Subcontractors / Gang Foremen';
    }
  }

  String get shortLabel {
    switch (this) {
      case StakeholderRole.clientDirector:
        return 'Client (OIL)';
      case StakeholderRole.epcMainContractor:
        return 'EPC (L&T)';
      case StakeholderRole.thirdPartyInspector:
        return 'TPIA (EIL)';
      case StakeholderRole.subcontractorForeman:
        return 'Foremen';
    }
  }

  String get tierBadge {
    switch (this) {
      case StakeholderRole.clientDirector:
        return 'TIER 1 • EXECUTIVE GOVERNANCE';
      case StakeholderRole.epcMainContractor:
        return 'TIER 2 • EPC PROJECT MGMT';
      case StakeholderRole.thirdPartyInspector:
        return 'TIER 2/3 • QA/QC STATUTORY';
      case StakeholderRole.subcontractorForeman:
        return 'TIER 4 • FIELD EXECUTION';
    }
  }

  IconData get icon {
    switch (this) {
      case StakeholderRole.clientDirector:
        return Icons.account_balance_rounded;
      case StakeholderRole.epcMainContractor:
        return Icons.business_center_rounded;
      case StakeholderRole.thirdPartyInspector:
        return Icons.verified_rounded;
      case StakeholderRole.subcontractorForeman:
        return Icons.engineering_rounded;
    }
  }

  Color get primaryAccent {
    switch (this) {
      case StakeholderRole.clientDirector:
        return AppTheme.primaryLight; // 0xFF38BDF8
      case StakeholderRole.epcMainContractor:
        return AppTheme.secondary; // 0xFFFFB95F
      case StakeholderRole.thirdPartyInspector:
        return AppTheme.tertiary; // 0xFF4EDEA3
      case StakeholderRole.subcontractorForeman:
        return const Color(0xFFA78BFA); // Purple
    }
  }

  List<String> get permissions {
    switch (this) {
      case StakeholderRole.clientDirector:
        return const [
          'Capex Sanction & Financial Release (FIDIC Cl. 14.3)',
          'Macro Milestone Sign-off & Commercial Penalties',
          'Variation Order Authorization (Cl. 13)',
          'Multi-Agency Executive Transparency Audit',
        ];
      case StakeholderRole.epcMainContractor:
        return const [
          'Daily Site Production Targets & Critical Path Scheduling',
          'Heavy Machinery & Gang Resource Allocation',
          'DPR Verification & Contractor Invoicing Submission',
          'Subcontractor Work Order Issuance & Oversight',
        ];
      case StakeholderRole.thirdPartyInspector:
        return const [
          'Statutory Quality Hold Point (QHP) Enforcement',
          'NDT Radiographic & Ultrasonic Weld Clearance (API 1104)',
          'Hydrostatic Pressure Test 24-hr Certification (OISD-141)',
          'Issue Non-Conformance Reports (NCR) & Stop Work Notices',
        ];
      case StakeholderRole.subcontractorForeman:
        return const [
          'Daily Field Work Order Execution & Chainage Log',
          'Emergency Tool & Welding Consumable Indents',
          'Gang Biometric & Geofenced Muster Roll Call',
          'Morning Toolbox Talk (TBT) Safety Compliance Signoff',
        ];
    }
  }
}

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

class MacroMilestoneItem {
  final String id;
  final String code;
  final String name;
  final String targetDate;
  final double weightagePct;
  final double progressPct;
  final String fidicClause;
  final String status; // 'COMPLETED', 'ON_TRACK', 'IN_PROGRESS', 'PENDING_CLEARANCE', 'CRITICAL_RISK'
  final String authority;

  const MacroMilestoneItem({
    required this.id,
    required this.code,
    required this.name,
    required this.targetDate,
    required this.weightagePct,
    required this.progressPct,
    required this.fidicClause,
    required this.status,
    required this.authority,
  });
}

class CapexInvoiceItem {
  final String id;
  final String certificateNo;
  final String contractor;
  final double requestedCr;
  final double certifiedCr;
  final String submissionDate;
  final String fidicRef;
  String status; // 'PENDING_APPROVAL', 'APPROVED', 'QUERY_RAISED'

  CapexInvoiceItem({
    required this.id,
    required this.certificateNo,
    required this.contractor,
    required this.requestedCr,
    required this.certifiedCr,
    required this.submissionDate,
    required this.fidicRef,
    required this.status,
  });
}

class DailyProgressTargetItem {
  final String id;
  final String activityName;
  final String discipline;
  final double plannedToday;
  final double actualToday;
  final String unit;
  final bool isCritical;
  final String status; // 'MET', 'LAGGING', 'EXCEEDED'
  final String gangAssigned;

  const DailyProgressTargetItem({
    required this.id,
    required this.activityName,
    required this.discipline,
    required this.plannedToday,
    required this.actualToday,
    required this.unit,
    required this.isCritical,
    required this.status,
    required this.gangAssigned,
  });
}

class GangDeploymentItem {
  final String id;
  final String gangName;
  final String foreman;
  final String trade;
  final int headcount;
  final String locationChainage;
  final String assignedEquipment;
  final double utilizationRate;
  final String shiftStatus; // 'ACTIVE', 'REST', 'STANDBY'

  const GangDeploymentItem({
    required this.id,
    required this.gangName,
    required this.foreman,
    required this.trade,
    required this.headcount,
    required this.locationChainage,
    required this.assignedEquipment,
    required this.utilizationRate,
    required this.shiftStatus,
  });
}

class DprApprovalRecord {
  final String id;
  final String dprNumber;
  final String sector;
  final String submittedBy;
  final String timestamp;
  final int jointsWelded;
  final double trenchMeters;
  final double lowerInMeters;
  final int manHours;
  String status; // 'PENDING_REVIEW', 'APPROVED', 'REJECTED'

  DprApprovalRecord({
    required this.id,
    required this.dprNumber,
    required this.sector,
    required this.submittedBy,
    required this.timestamp,
    required this.jointsWelded,
    required this.trenchMeters,
    required this.lowerInMeters,
    required this.manHours,
    required this.status,
  });
}

class QualityHoldPointItem {
  final String id;
  final String code;
  final String standard;
  final String title;
  final String chainage;
  final String holdType; // 'MANDATORY_HOLD', 'WITNESS_POINT', 'SURVEILLANCE'
  String status; // 'HOLD_ACTIVE', 'RELEASED', 'NCR_ISSUED'
  final String scheduledDate;
  final String inspector;

  QualityHoldPointItem({
    required this.id,
    required this.code,
    required this.standard,
    required this.title,
    required this.chainage,
    required this.holdType,
    required this.status,
    required this.scheduledDate,
    required this.inspector,
  });
}

class NdtWeldRadiographItem {
  final String id;
  final String weldJoint;
  final String chainage;
  final double pipeDiaInches;
  final double thicknessMm;
  final String welderTag;
  final String technique; // 'RT_CLASS_A', 'PAUT_AUT', 'MPI_DYE'
  String status; // 'ACCEPTED', 'REPAIR_REQUIRED', 'CUT_OUT'
  final String? defectRemarks;
  final double opticalDensity;
  final String certifiedBy;

  NdtWeldRadiographItem({
    required this.id,
    required this.weldJoint,
    required this.chainage,
    required this.pipeDiaInches,
    required this.thicknessMm,
    required this.welderTag,
    required this.technique,
    required this.status,
    this.defectRemarks,
    required this.opticalDensity,
    required this.certifiedBy,
  });
}

class HydrotestSectionItem {
  final String id;
  final String sectionName;
  final String chainageSpan;
  final double lengthKm;
  final double designPressureBar;
  final double testPressureBar;
  final double currentHoldingPressureBar;
  final int holdingHoursElapsed;
  final int requiredHours;
  String certificationStatus; // 'HOLDING_TEST', 'CERTIFIED_PASSED', 'DEPRESSURIZING', 'LEAK_DETECTED'
  final String witnessAgency;

  HydrotestSectionItem({
    required this.id,
    required this.sectionName,
    required this.chainageSpan,
    required this.lengthKm,
    required this.designPressureBar,
    required this.testPressureBar,
    required this.currentHoldingPressureBar,
    required this.holdingHoursElapsed,
    required this.requiredHours,
    required this.certificationStatus,
    required this.witnessAgency,
  });
}

class DailyWorkOrderItem {
  final String id;
  final String orderNo;
  final String gangName;
  final String foremanName;
  final String scope;
  final String chainage;
  final double targetQuantity;
  double completedQuantity;
  final String unit;
  final String priority; // 'HIGH', 'CRITICAL', 'NORMAL'
  String status; // 'IN_PROGRESS', 'COMPLETED', 'HALTED_OBSTACLE'
  final String hazardMitigation;

  DailyWorkOrderItem({
    required this.id,
    required this.orderNo,
    required this.gangName,
    required this.foremanName,
    required this.scope,
    required this.chainage,
    required this.targetQuantity,
    required this.completedQuantity,
    required this.unit,
    required this.priority,
    required this.status,
    required this.hazardMitigation,
  });
}

class ToolIndentItem {
  final String id;
  final String indentNo;
  final String requestedByGang;
  final String toolDescription;
  final int quantity;
  final String urgency; // 'EMERGENCY_2HR', 'SAME_DAY', 'SCHEDULED'
  String status; // 'REQUESTED', 'APPROVED_DISPATCHED', 'DELIVERED'
  final String requestTime;

  ToolIndentItem({
    required this.id,
    required this.indentNo,
    required this.requestedByGang,
    required this.toolDescription,
    required this.quantity,
    required this.urgency,
    required this.status,
    required this.requestTime,
  });
}

class MusterRollSummaryItem {
  final String gangName;
  final String leader;
  final int totalStrength;
  final int presentCount;
  final int biometricCount;
  final String toolboxTalkTopic;
  final bool tbtCompleted;

  const MusterRollSummaryItem({
    required this.gangName,
    required this.leader,
    required this.totalStrength,
    required this.presentCount,
    required this.biometricCount,
    required this.toolboxTalkTopic,
    required this.tbtCompleted,
  });
}

// ---------------------------------------------------------------------------
// MAIN SCREEN WIDGET
// ---------------------------------------------------------------------------

class StakeholderPortalScreen extends StatefulWidget {
  const StakeholderPortalScreen({super.key});

  @override
  State<StakeholderPortalScreen> createState() => _StakeholderPortalScreenState();
}

class _StakeholderPortalScreenState extends State<StakeholderPortalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StakeholderRole _activeRole = StakeholderRole.clientDirector;
  String _searchFilter = '';
  bool _isSearchExpanded = false;

  // Filter chips per tab
  String _clientFilter = 'ALL'; // 'ALL', 'CRITICAL', 'PENDING_APPROVAL'
  String _epcFilter = 'ALL'; // 'ALL', 'CRITICAL_PATH', 'LAGGING'
  String _tpiaFilter = 'ALL'; // 'ALL', 'ACTIVE_HOLD', 'REPAIRS'
  String _subFilter = 'ALL'; // 'ALL', 'ACTIVE_ORDERS', 'EMERGENCY_INDENTS'

  // Stateful Data Lists
  final List<MacroMilestoneItem> _macroMilestones = const [
    MacroMilestoneItem(
      id: 'MS-01',
      code: 'MS-OIL-01',
      name: 'Right of Way (RoW) Clearance & Statutory Gazette Notification',
      targetDate: '15 Mar 2026',
      weightagePct: 15.0,
      progressPct: 100.0,
      fidicClause: 'FIDIC Cl. 2.1 (Right of Access)',
      status: 'COMPLETED',
      authority: 'Govt. Revenue & Oil India Land Directorate',
    ),
    MacroMilestoneItem(
      id: 'MS-02',
      code: 'MS-OIL-02',
      name: 'Line Pipe 24" API 5L X70 Procurement & 120km Stringing',
      targetDate: '30 Jun 2026',
      weightagePct: 25.0,
      progressPct: 88.5,
      fidicClause: 'FIDIC Cl. 4.1 (Contractor General Obligations)',
      status: 'ON_TRACK',
      authority: 'L&T Materials & Central Storage Yard',
    ),
    MacroMilestoneItem(
      id: 'MS-03',
      code: 'MS-OIL-03',
      name: 'Horizontal Directional Drilling (HDD) River Brahmaputra Crossing',
      targetDate: '15 Oct 2026',
      weightagePct: 20.0,
      progressPct: 74.2,
      fidicClause: 'FIDIC Cl. 4.12 (Unforeseeable Physical Conditions)',
      status: 'IN_PROGRESS',
      authority: 'Consortium HDD Special Taskforce',
    ),
    MacroMilestoneItem(
      id: 'MS-04',
      code: 'MS-OIL-04',
      name: 'Hydrotest Section 1 (Chainage 0+000 to 60+000) & Nitrogen Purge',
      targetDate: '30 Dec 2026',
      weightagePct: 20.0,
      progressPct: 45.0,
      fidicClause: 'FIDIC Cl. 9.1 (Tests on Completion)',
      status: 'PENDING_CLEARANCE',
      authority: 'EIL-TPIA Statutory Clearance Desk',
    ),
    MacroMilestoneItem(
      id: 'MS-05',
      code: 'MS-OIL-05',
      name: 'Terminal SCADA, Gas Leak Detection System & Commissioning',
      targetDate: '15 Apr 2027',
      weightagePct: 20.0,
      progressPct: 18.0,
      fidicClause: 'FIDIC Cl. 10.1 (Taking-Over Certificate)',
      status: 'CRITICAL_RISK',
      authority: 'Honeywell DCS / OIL Operations Directorate',
    ),
  ];

  late List<CapexInvoiceItem> _capexInvoices;

  final List<DailyProgressTargetItem> _dailyTargets = const [
    DailyProgressTargetItem(
      id: 'DPT-01',
      activityName: 'Automatic Downhill Welding (6G/TIG API 1104)',
      discipline: 'PIPING',
      plannedToday: 130.0,
      actualToday: 122.0,
      unit: 'joints',
      isCritical: true,
      status: 'MET',
      gangAssigned: 'Gang Bravo (Mainline Welder Crew)',
    ),
    DailyProgressTargetItem(
      id: 'DPT-02',
      activityName: 'Chainage Trench Excavation (Depth 2.4m, Width 1.8m)',
      discipline: 'CIVIL',
      plannedToday: 850.0,
      actualToday: 910.0,
      unit: 'meters',
      isCritical: false,
      status: 'EXCEEDED',
      gangAssigned: 'Gang Alpha (Earthworks & Heavy Excavation)',
    ),
    DailyProgressTargetItem(
      id: 'DPT-03',
      activityName: 'Pipe Lowering & Sand Bed Cushioning Section 3B',
      discipline: 'MECHANICAL',
      plannedToday: 700.0,
      actualToday: 540.0,
      unit: 'meters',
      isCritical: true,
      status: 'LAGGING',
      gangAssigned: 'Gang Delta (Sideboom Lower-in Team)',
    ),
    DailyProgressTargetItem(
      id: 'DPT-04',
      activityName: '3LPE Field Joint Coating & Holiday Spark Testing 25kV',
      discipline: 'COATING',
      plannedToday: 120.0,
      actualToday: 118.0,
      unit: 'joints',
      isCritical: false,
      status: 'MET',
      gangAssigned: 'Gang Charlie (Corrosion Wrap Crew)',
    ),
  ];

  final List<GangDeploymentItem> _gangDeployments = const [
    GangDeploymentItem(
      id: 'GANG-01',
      gangName: 'Gang Alpha • Earthworks & Trenching',
      foreman: 'Harpal Singh (Snr Earthworks Lead)',
      trade: 'Excavation & Shoring',
      headcount: 54,
      locationChainage: 'Ch. 38+200 to 41+500',
      assignedEquipment: '4x CAT 336 Excavators, 2x Bulldozers D8R',
      utilizationRate: 94.2,
      shiftStatus: 'ACTIVE',
    ),
    GangDeploymentItem(
      id: 'GANG-02',
      gangName: 'Gang Bravo • Mainline Downhill Welding',
      foreman: 'S. K. Murugan (Master Welding Foreman)',
      trade: '6G API Welder / Riggers',
      headcount: 88,
      locationChainage: 'Ch. 36+800 to 38+200',
      assignedEquipment: '6x Lincoln Vantage 500, 2x Internal Clamps',
      utilizationRate: 91.5,
      shiftStatus: 'ACTIVE',
    ),
    GangDeploymentItem(
      id: 'GANG-03',
      gangName: 'Gang Charlie • Field Joint Coating',
      foreman: 'Anand Dev (Coating Specialist)',
      trade: 'Heat Shrink Sleeve & 3LPE',
      headcount: 42,
      locationChainage: 'Ch. 35+100 to 36+800',
      assignedEquipment: 'Induction Heating Coils, SPY Holiday Detectors',
      utilizationRate: 88.0,
      shiftStatus: 'ACTIVE',
    ),
    GangDeploymentItem(
      id: 'GANG-04',
      gangName: 'Gang Delta • Sideboom Lower-In & Tie-in',
      foreman: 'Tsering Dorji (Rigging Superintendent)',
      trade: 'Heavy Rigging & Tie-in',
      headcount: 65,
      locationChainage: 'Ch. 34+000 to 35+100',
      assignedEquipment: '4x Komatsu D155C Sidebooms, Foam Dispensers',
      utilizationRate: 82.4,
      shiftStatus: 'STANDBY',
    ),
  ];

  late List<DprApprovalRecord> _dprRecords;
  late List<QualityHoldPointItem> _qualityHoldPoints;
  late List<NdtWeldRadiographItem> _ndtRadiographs;
  late List<HydrotestSectionItem> _hydrotestSections;
  late List<DailyWorkOrderItem> _workOrders;
  late List<ToolIndentItem> _toolIndents;

  final List<MusterRollSummaryItem> _musterRolls = const [
    MusterRollSummaryItem(
      gangName: 'Gang Alpha (Earthmoving)',
      leader: 'Harpal Singh',
      totalStrength: 54,
      presentCount: 52,
      biometricCount: 52,
      toolboxTalkTopic: 'Excavation Cave-in & Underground Utility Strikes',
      tbtCompleted: true,
    ),
    MusterRollSummaryItem(
      gangName: 'Gang Bravo (Downhill Welders)',
      leader: 'S. K. Murugan',
      totalStrength: 88,
      presentCount: 86,
      biometricCount: 85,
      toolboxTalkTopic: 'Confined Space Welding Fumes & Arc Eye Protection',
      tbtCompleted: true,
    ),
    MusterRollSummaryItem(
      gangName: 'Gang Charlie (Field Joint Coating)',
      leader: 'Anand Dev',
      totalStrength: 42,
      presentCount: 40,
      biometricCount: 39,
      toolboxTalkTopic: 'High Voltage Spark Detector & Molten Adhesive Safety',
      tbtCompleted: true,
    ),
    MusterRollSummaryItem(
      gangName: 'Gang Delta (Heavy Rigging & Lower-in)',
      leader: 'Tsering Dorji',
      totalStrength: 65,
      presentCount: 63,
      biometricCount: 63,
      toolboxTalkTopic: 'Sideboom Tandem Lifting Signals & Drop-Zone Radius',
      tbtCompleted: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _activeRole = StakeholderRole.values[_tabController.index];
        });
      }
    });

    _capexInvoices = [
      CapexInvoiceItem(
        id: 'IPC-08',
        certificateNo: 'IPC-2026-08 (Package A)',
        contractor: 'L&T Hydrocarbon Engineering Ltd.',
        requestedCr: 44.50,
        certifiedCr: 41.80,
        submissionDate: '26 Sep 2026',
        fidicRef: 'FIDIC Cl. 14.3 (Interim Payment Certificate)',
        status: 'PENDING_APPROVAL',
      ),
      CapexInvoiceItem(
        id: 'IPC-07',
        certificateNo: 'IPC-2026-07 (Trenching & Stringing)',
        contractor: 'L&T Hydrocarbon Engineering Ltd.',
        requestedCr: 38.20,
        certifiedCr: 37.90,
        submissionDate: '12 Sep 2026',
        fidicRef: 'FIDIC Cl. 14.3 (Interim Payment Certificate)',
        status: 'APPROVED',
      ),
      CapexInvoiceItem(
        id: 'VO-03',
        certificateNo: 'VO-2026-03 (Brahmaputra Rock Strata)',
        contractor: 'Consortium HDD Specialist JV',
        requestedCr: 6.80,
        certifiedCr: 5.40,
        submissionDate: '28 Sep 2026',
        fidicRef: 'FIDIC Cl. 13.3 (Variation Order Procedure)',
        status: 'PENDING_APPROVAL',
      ),
    ];

    _dprRecords = [
      DprApprovalRecord(
        id: 'DPR-2026-249',
        dprNumber: 'DPR #249 (Sector 4B)',
        sector: 'Pipeline Ch. 35+000 to 39+000',
        submittedBy: 'Vikram Joshi (Site Piping Supervisor)',
        timestamp: 'Today, 18:30 IST',
        jointsWelded: 24,
        trenchMeters: 480.0,
        lowerInMeters: 350.0,
        manHours: 1980,
        status: 'PENDING_REVIEW',
      ),
      DprApprovalRecord(
        id: 'DPR-2026-248',
        dprNumber: 'DPR #248 (Sector 4A)',
        sector: 'Pipeline Ch. 31+000 to 35+000',
        submittedBy: 'Vikram Joshi (Site Piping Supervisor)',
        timestamp: 'Yesterday, 19:15 IST',
        jointsWelded: 28,
        trenchMeters: 510.0,
        lowerInMeters: 410.0,
        manHours: 2150,
        status: 'APPROVED',
      ),
      DprApprovalRecord(
        id: 'DPR-2026-247',
        dprNumber: 'DPR #247 (HDD Approach Crossing)',
        sector: 'River Terminal Station 03',
        submittedBy: 'M. K. Barua (HDD Site Engineer)',
        timestamp: '27 Sep 2026, 17:45 IST',
        jointsWelded: 14,
        trenchMeters: 120.0,
        lowerInMeters: 0.0,
        manHours: 850,
        status: 'APPROVED',
      ),
    ];

    _qualityHoldPoints = [
      QualityHoldPointItem(
        id: 'QHP-101',
        code: 'QHP-EIL-PIP-04',
        standard: 'OISD-141 / API 1104',
        title: 'Pre-Lowering Holiday Coating Spark Inspection (25kV)',
        chainage: 'Ch. 37+450 to 38+100',
        holdType: 'MANDATORY_HOLD',
        status: 'HOLD_ACTIVE',
        scheduledDate: '30 Sep 2026 (09:00 IST)',
        inspector: 'R. K. Sharma (EIL Lead Quality Auditor)',
      ),
      QualityHoldPointItem(
        id: 'QHP-102',
        code: 'QHP-EIL-WLD-12',
        standard: 'ASME Sec IX / API 1104',
        title: 'River Crossing Tie-In Golden Weld 100% RT & Ultrasonic',
        chainage: 'Ch. 42+110 (Brahmaputra South Bank)',
        holdType: 'MANDATORY_HOLD',
        status: 'HOLD_ACTIVE',
        scheduledDate: '01 Oct 2026 (14:00 IST)',
        inspector: 'Debashis Ray (EIL NDT Level III)',
      ),
      QualityHoldPointItem(
        id: 'QHP-100',
        code: 'QHP-EIL-TRN-02',
        standard: 'OIL Technical Spec Sec 4',
        title: 'Trench Bottom Sand Padding Depth Verification (150mm)',
        chainage: 'Ch. 34+000 to 36+000',
        holdType: 'WITNESS_POINT',
        status: 'RELEASED',
        scheduledDate: '28 Sep 2026',
        inspector: 'R. K. Sharma (EIL Lead Quality Auditor)',
      ),
    ];

    _ndtRadiographs = [
      NdtWeldRadiographItem(
        id: 'NDT-W-1840',
        weldJoint: 'W-J-3824 (Golden Weld)',
        chainage: 'Ch. 38+240',
        pipeDiaInches: 24.0,
        thicknessMm: 14.3,
        welderTag: 'W-LT-092 (H. Bora)',
        technique: 'RT_CLASS_A',
        status: 'ACCEPTED',
        opticalDensity: 2.45,
        certifiedBy: 'Debashis Ray (EIL Level III)',
      ),
      NdtWeldRadiographItem(
        id: 'NDT-W-1841',
        weldJoint: 'W-J-3825 (Mainline Seam)',
        chainage: 'Ch. 38+252',
        pipeDiaInches: 24.0,
        thicknessMm: 14.3,
        welderTag: 'W-LT-104 (P. Das)',
        technique: 'PAUT_AUT',
        status: 'REPAIR_REQUIRED',
        defectRemarks: 'Root lack of penetration 18mm at 4 o\'clock position (Cl. 9.3 API 1104)',
        opticalDensity: 2.30,
        certifiedBy: 'Debashis Ray (EIL Level III)',
      ),
      NdtWeldRadiographItem(
        id: 'NDT-W-1842',
        weldJoint: 'W-J-3826 (Mainline Seam)',
        chainage: 'Ch. 38+264',
        pipeDiaInches: 24.0,
        thicknessMm: 14.3,
        welderTag: 'W-LT-088 (M. Yadav)',
        technique: 'RT_CLASS_A',
        status: 'ACCEPTED',
        opticalDensity: 2.50,
        certifiedBy: 'Debashis Ray (EIL Level III)',
      ),
    ];

    _hydrotestSections = [
      HydrotestSectionItem(
        id: 'HTP-SEC-01',
        sectionName: 'Package 1 Mainline Section Alpha',
        chainageSpan: 'Ch. 0+000 to Ch. 34+000',
        lengthKm: 34.0,
        designPressureBar: 112.0,
        testPressureBar: 148.0,
        currentHoldingPressureBar: 148.2,
        holdingHoursElapsed: 18,
        requiredHours: 24,
        certificationStatus: 'HOLDING_TEST',
        witnessAgency: 'EIL-TPIA & Chief Controller of Explosives (PESO)',
      ),
      HydrotestSectionItem(
        id: 'HTP-SEC-02',
        sectionName: 'Package 1 Section Bravo',
        chainageSpan: 'Ch. 34+000 to Ch. 60+000',
        lengthKm: 26.0,
        designPressureBar: 112.0,
        testPressureBar: 148.0,
        currentHoldingPressureBar: 0.0,
        holdingHoursElapsed: 0,
        requiredHours: 24,
        certificationStatus: 'DEPRESSURIZING',
        witnessAgency: 'EIL-TPIA Clearance Pending',
      ),
    ];

    _workOrders = [
      DailyWorkOrderItem(
        id: 'DWO-2026-89',
        orderNo: 'WO #89 (Trench Excavation)',
        gangName: 'Gang Alpha',
        foremanName: 'Harpal Singh',
        scope: 'Trench excavation down to 2.4m depth with benching at Ch. 39+500 to 40+200',
        chainage: 'Ch. 39+500',
        targetQuantity: 700.0,
        completedQuantity: 520.0,
        unit: 'meters',
        priority: 'HIGH',
        status: 'IN_PROGRESS',
        hazardMitigation: 'Underground 33kV Assam Power cable crossing marker sighted. Hand probing mandated.',
      ),
      DailyWorkOrderItem(
        id: 'DWO-2026-90',
        orderNo: 'WO #90 (Downhill Mainline Welding)',
        gangName: 'Gang Bravo',
        foremanName: 'S. K. Murugan',
        scope: 'Automatic downhill weld stringing with internal line-up clamp joints W-3828 to W-3850',
        chainage: 'Ch. 38+200',
        targetQuantity: 22.0,
        completedQuantity: 18.0,
        unit: 'joints',
        priority: 'CRITICAL',
        status: 'IN_PROGRESS',
        hazardMitigation: 'Pre-heating to 150°C verified via tempil sticks prior to root pass.',
      ),
      DailyWorkOrderItem(
        id: 'DWO-2026-91',
        orderNo: 'WO #91 (Joint Padding & Lower-In)',
        gangName: 'Gang Delta',
        foremanName: 'Tsering Dorji',
        scope: 'Lower-in of 450m welded string using 4 sidebooms in sync after EIL holiday clearance',
        chainage: 'Ch. 37+000',
        targetQuantity: 450.0,
        completedQuantity: 0.0,
        unit: 'meters',
        priority: 'HIGH',
        status: 'HALTED_OBSTACLE',
        hazardMitigation: 'Halted: Rain runoff pooling in trench bottom at Ch. 37+120. De-watering pumps mobilized.',
      ),
    ];

    _toolIndents = [
      ToolIndentItem(
        id: 'IND-401',
        indentNo: 'IND #401 (Electrodes & Grinding)',
        requestedByGang: 'Gang Bravo (Welders)',
        toolDescription: 'Lincoln Fleetweld 5P+ E6010 Cellulosic Rods (150 kg) + 40x 7" Grinding Wheels',
        quantity: 190,
        urgency: 'EMERGENCY_2HR',
        status: 'APPROVED_DISPATCHED',
        requestTime: '07:15 IST Today',
      ),
      ToolIndentItem(
        id: 'IND-402',
        indentNo: 'IND #402 (De-watering Pumps)',
        requestedByGang: 'Gang Delta (Lower-in)',
        toolDescription: '3" Submersible Diesel Sludge Pump with 50m Layflat Hose',
        quantity: 2,
        urgency: 'EMERGENCY_2HR',
        status: 'REQUESTED',
        requestTime: '09:40 IST Today',
      ),
      ToolIndentItem(
        id: 'IND-403',
        indentNo: 'IND #403 (Sling Inspection)',
        requestedByGang: 'Gang Delta (Lower-in)',
        toolDescription: '25-Ton Heavy-Duty Webbing Lower-in Slings with valid third-party load test cert',
        quantity: 4,
        urgency: 'SAME_DAY',
        status: 'DELIVERED',
        requestTime: 'Yesterday, 16:00 IST',
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE ACTION MODALS
  // ---------------------------------------------------------------------------

  void _showRoleSecurityDialog(StakeholderRole role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: role.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: role.primaryAccent.withValues(alpha: 0.3)),
                    ),
                    child: Icon(role.icon, color: role.primaryAccent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          role.tierBadge,
                          style: TextStyle(
                            color: role.primaryAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'ROLE-SPECIFIC ACCESS PERMISSIONS & SECURITY MATRIX',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              ...role.permissions.map(
                (perm) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          perm,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Audit Trail Active: Every digital signature, sanction, or hold-point change is immutably cryptostamped.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: role.primaryAccent,
                    foregroundColor: AppTheme.background,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ACKNOWLEDGE PERMISSIONS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _approveCapexInvoice(CapexInvoiceItem invoice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: AppTheme.primaryLight),
            SizedBox(width: 10),
            Text(
              'Sanction Capex Release',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authority: Client Director (Oil India Limited)',
              style: TextStyle(color: StakeholderRole.clientDirector.primaryAccent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Certificate: ${invoice.certificateNo}',
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Contractor: ${invoice.contractor}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'Certified Amount: ₹${invoice.certifiedCr.toStringAsFixed(2)} Cr',
              style: const TextStyle(color: AppTheme.tertiary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                'Release authorized under ${invoice.fidicRef}. Retention of 5% automatically deducted to escrow reserve.',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.tertiary, foregroundColor: AppTheme.background),
            onPressed: () {
              setState(() {
                invoice.status = 'APPROVED';
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.surfaceCard,
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Payment Sanctioned: ₹${invoice.certifiedCr} Cr disbursed for ${invoice.certificateNo}',
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: const Text('SANCTION & DISBURSE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _approveDpr(DprApprovalRecord record) {
    setState(() {
      record.status = 'APPROVED';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceCard,
        content: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppTheme.secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${record.dprNumber} approved by EPC Lead Engineer. Forwarded to OIL Director desk.',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _releaseQualityHoldPoint(QualityHoldPointItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: AppTheme.tertiary),
            SizedBox(width: 10),
            Text(
              'Sign Off Hold Point',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hold Point Code: ${item.code}',
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Standard: ${item.standard}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'Location: ${item.chainage}',
              style: const TextStyle(color: AppTheme.primaryLight, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Confirm that physical calibration, spark testing, or welding radiograph scrutiny satisfies all statutory safety norms.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tertiary,
              foregroundColor: AppTheme.background,
            ),
            onPressed: () {
              setState(() {
                item.status = 'RELEASED';
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.surfaceCard,
                  content: Text('Hold Point ${item.code} released with EIL Level III digital stamp.'),
                ),
              );
            },
            child: const Text('RELEASE HOLD POINT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _submitWorkOrderProgress(DailyWorkOrderItem order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        double currentVal = order.completedQuantity;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Update Work Order Progress',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text(
                    '${order.orderNo} • ${order.gangName}',
                    style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Completed (${order.unit}): ${currentVal.toStringAsFixed(1)} / ${order.targetQuantity.toStringAsFixed(1)}',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: currentVal,
                    min: 0,
                    max: order.targetQuantity,
                    activeColor: const Color(0xFFA78BFA),
                    inactiveColor: AppTheme.border,
                    divisions: 20,
                    onChanged: (val) {
                      setModalState(() {
                        currentVal = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA78BFA),
                        foregroundColor: AppTheme.background,
                      ),
                      onPressed: () {
                        setState(() {
                          order.completedQuantity = currentVal;
                          if (currentVal >= order.targetQuantity) {
                            order.status = 'COMPLETED';
                          } else {
                            order.status = 'IN_PROGRESS';
                          }
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Updated ${order.orderNo}: ${currentVal.toStringAsFixed(1)} ${order.unit} logged.'),
                          ),
                        );
                      },
                      child: const Text('SUBMIT SHIFT LOG', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _createNewToolIndent() {
    final textController = TextEditingController();
    int qty = 1;
    String selectedUrgency = 'EMERGENCY_2HR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Raise Urgent Site Tool / Consumable Indent',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Direct requisition from Foreman field terminal to Central Base Yard',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 5x 6010 Welding Rod Boxes, 2x Internal Lineup Clamp Spares',
                      labelText: 'Tool / Material Description',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quantity', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textSecondary),
                                  onPressed: () {
                                    if (qty > 1) {
                                      setModalState(() => qty--);
                                    }
                                  },
                                ),
                                Text(
                                  '$qty',
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.textSecondary),
                                  onPressed: () {
                                    setModalState(() => qty++);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Urgency', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            const SizedBox(height: 6),
                            DropdownButton<String>(
                              value: selectedUrgency,
                              dropdownColor: AppTheme.surfaceCard,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 'EMERGENCY_2HR', child: Text('Critical (2 Hrs)', style: TextStyle(color: AppTheme.error))),
                                DropdownMenuItem(value: 'SAME_DAY', child: Text('Same Day', style: TextStyle(color: AppTheme.secondary))),
                                DropdownMenuItem(value: 'SCHEDULED', child: Text('Tomorrow', style: TextStyle(color: AppTheme.tertiary))),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedUrgency = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA78BFA),
                        foregroundColor: AppTheme.background,
                      ),
                      onPressed: () {
                        if (textController.text.trim().isEmpty) return;
                        final newIndent = ToolIndentItem(
                          id: 'IND-${DateTime.now().millisecondsSinceEpoch % 1000}',
                          indentNo: 'IND #${DateTime.now().millisecondsSinceEpoch % 1000}',
                          requestedByGang: 'Gang Bravo (Mainline Welder Crew)',
                          toolDescription: textController.text.trim(),
                          quantity: qty,
                          urgency: selectedUrgency,
                          status: 'REQUESTED',
                          requestTime: 'Just now',
                        );
                        setState(() {
                          _toolIndents.insert(0, newIndent);
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.surfaceCard,
                            content: Text('Indent #${newIndent.indentNo} dispatched to Yard Storekeeper.'),
                          ),
                        );
                      },
                      child: const Text('DISPATCH INDENT TO YARD', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // ---------------------------------------------------------------------------
  // MAIN BUILD METHOD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: _isSearchExpanded
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search milestones, orders, hold points...',
                  hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchFilter = val.trim().toLowerCase();
                  });
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stakeholder Portal',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Consumer<AppProvider>(
                    builder: (context, provider, _) {
                      final projectName = provider.currentProject?.name ?? 'Trunk Crude Pipeline Expansion';
                      return Text(
                        projectName,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: _isSearchExpanded ? 'Close Search' : 'Search Portal',
            icon: Icon(
              _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _searchFilter = '';
                }
              });
            },
          ),
          IconButton(
            tooltip: 'View Role Security Matrix',
            icon: Icon(Icons.shield_outlined, color: _activeRole.primaryAccent),
            onPressed: () => _showRoleSecurityDialog(_activeRole),
          ),
          IconButton(
            tooltip: 'Refresh Collaboration Hub',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 1),
                  content: Text('Syncing multi-stakeholder telemetry...'),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              _buildClearanceBanner(),
              Container(
                color: AppTheme.surface,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: _activeRole.primaryAccent,
                  indicatorWeight: 3,
                  labelColor: _activeRole.primaryAccent,
                  unselectedLabelColor: AppTheme.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.account_balance_rounded, size: 18),
                      text: StakeholderRole.clientDirector.shortLabel,
                    ),
                    Tab(
                      icon: const Icon(Icons.business_center_rounded, size: 18),
                      text: StakeholderRole.epcMainContractor.shortLabel,
                    ),
                    Tab(
                      icon: const Icon(Icons.verified_rounded, size: 18),
                      text: StakeholderRole.thirdPartyInspector.shortLabel,
                    ),
                    Tab(
                      icon: const Icon(Icons.engineering_rounded, size: 18),
                      text: StakeholderRole.subcontractorForeman.shortLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClientDirectorView(),
          _buildEpcContractorView(),
          _buildThirdPartyInspectionView(),
          _buildSubcontractorForemanView(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CLEARANCE BANNER
  // ---------------------------------------------------------------------------

  Widget _buildClearanceBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _activeRole.primaryAccent,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _activeRole.tierBadge,
            style: TextStyle(
              color: _activeRole.primaryAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 10, color: AppTheme.tertiary),
                SizedBox(width: 4),
                Text(
                  'RBAC ENCRYPTED',
                  style: TextStyle(color: AppTheme.tertiary, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: CLIENT / OIL INDIA DIRECTOR VIEW
  // ---------------------------------------------------------------------------

  Widget _buildClientDirectorView() {
    final filteredMilestones = _macroMilestones.where((ms) {
      if (_searchFilter.isNotEmpty) {
        final matches = ms.name.toLowerCase().contains(_searchFilter) ||
            ms.code.toLowerCase().contains(_searchFilter) ||
            ms.fidicClause.toLowerCase().contains(_searchFilter);
        if (!matches) return false;
      }
      if (_clientFilter == 'CRITICAL') {
        return ms.status == 'CRITICAL_RISK' || ms.status == 'PENDING_CLEARANCE';
      }
      return true;
    }).toList();

    final filteredInvoices = _capexInvoices.where((inv) {
      if (_searchFilter.isNotEmpty) {
        final matches = inv.certificateNo.toLowerCase().contains(_searchFilter) ||
            inv.contractor.toLowerCase().contains(_searchFilter);
        if (!matches) return false;
      }
      if (_clientFilter == 'PENDING_APPROVAL') {
        return inv.status == 'PENDING_APPROVAL';
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRoleContextCard(
          title: 'Client / Oil India Limited Executive Directorate',
          subtitle: 'FIDIC Clause 3 (The Engineer & Employer) • Capex Governance & Macro Schedule Tracking',
          accentColor: StakeholderRole.clientDirector.primaryAccent,
          icon: StakeholderRole.clientDirector.icon,
        ),
        const SizedBox(height: 12),

        // Filter chips
        _buildFilterChipRow(
          activeFilter: _clientFilter,
          onSelect: (filter) => setState(() => _clientFilter = filter),
          filters: const [
            {'key': 'ALL', 'label': 'All Macro Data'},
            {'key': 'CRITICAL', 'label': 'Critical Milestones'},
            {'key': 'PENDING_APPROVAL', 'label': 'Pending IPC Release'},
          ],
        ),
        const SizedBox(height: 14),

        // Sanctioned Budget & Capex Burn Card
        _buildCapexBurnExecutiveCard(),
        const SizedBox(height: 16),

        // Macro Milestones Section
        _buildSectionHeader(
          title: 'Macro Schedule Milestones',
          tag: '${filteredMilestones.length} Contract Key Dates',
          icon: Icons.flag_rounded,
        ),
        const SizedBox(height: 12),
        if (filteredMilestones.isEmpty)
          _buildEmptyFilteredState('No macro milestones matching filters.')
        else
          ...filteredMilestones.map((ms) => _buildMacroMilestoneCard(ms)),
        const SizedBox(height: 20),

        // Interim Payment & Capex Release Approvals Section
        _buildSectionHeader(
          title: 'Sanctioned Capex & Invoice Approvals',
          tag: 'FIDIC Cl. 14.3 IPC Queue',
          icon: Icons.monetization_on_rounded,
        ),
        const SizedBox(height: 12),
        if (filteredInvoices.isEmpty)
          _buildEmptyFilteredState('No invoices matching criteria.')
        else
          ...filteredInvoices.map((inv) => _buildCapexInvoiceCard(inv)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCapexBurnExecutiveCard() {
    const sanctionedCr = 2450.0;
    const spentCr = 1720.0;
    const committedCr = 410.0;
    const remainingCr = sanctionedCr - spentCr - committedCr;
    final burnPct = (spentCr / sanctionedCr) * 100;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SANCTIONED CAPEX & RUN-RATE',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '₹2,450.00 Cr',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('SPI / CPI', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                    Text(
                      '0.94 / 0.98',
                      style: TextStyle(
                        color: StakeholderRole.clientDirector.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Burn Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: spentCr.toInt(),
                    child: Container(color: AppTheme.primary),
                  ),
                  Expanded(
                    flex: committedCr.toInt(),
                    child: Container(color: AppTheme.secondary),
                  ),
                  Expanded(
                    flex: remainingCr.toInt(),
                    child: Container(color: AppTheme.border),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(
                label: 'Incurred Disbursed',
                value: '₹${spentCr.toStringAsFixed(0)} Cr',
                sub: '${burnPct.toStringAsFixed(1)}%',
                color: AppTheme.primary,
              ),
              _buildMiniMetric(
                label: 'Committed Orders',
                value: '₹${committedCr.toStringAsFixed(0)} Cr',
                sub: 'PO Issued',
                color: AppTheme.secondary,
              ),
              _buildMiniMetric(
                label: 'Contingency Balance',
                value: '₹${remainingCr.toStringAsFixed(0)} Cr',
                sub: 'Unencumbered',
                color: AppTheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroMilestoneCard(MacroMilestoneItem item) {
    Color statusColor;
    String statusLabel;
    switch (item.status) {
      case 'COMPLETED':
        statusColor = AppTheme.tertiary;
        statusLabel = 'COMPLETED 100%';
        break;
      case 'ON_TRACK':
        statusColor = AppTheme.primaryLight;
        statusLabel = 'ON TRACK';
        break;
      case 'IN_PROGRESS':
        statusColor = AppTheme.secondary;
        statusLabel = 'IN PROGRESS';
        break;
      case 'PENDING_CLEARANCE':
        statusColor = const Color(0xFFA78BFA);
        statusLabel = 'CLEARANCE PENDING';
        break;
      default:
        statusColor = AppTheme.error;
        statusLabel = 'CRITICAL ATTENTION';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'Target: ${item.targetDate}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                item.fidicClause,
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
              Expanded(
                child: Text(
                  item.authority,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.progressPct / 100.0,
                    backgroundColor: AppTheme.background,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${item.progressPct.toStringAsFixed(1)}%',
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCapexInvoiceCard(CapexInvoiceItem inv) {
    final bool isApproved = inv.status == 'APPROVED';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApproved ? AppTheme.tertiary.withValues(alpha: 0.4) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                inv.certificateNo,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isApproved ? AppTheme.tertiary.withValues(alpha: 0.15) : AppTheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isApproved ? 'SANCTIONED & PAID' : 'AWAITING SANCTION',
                  style: TextStyle(
                    color: isApproved ? AppTheme.tertiary : AppTheme.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            inv.contractor,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Requested', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  Text('₹${inv.requestedCr.toStringAsFixed(2)} Cr', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Certified Net', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  Text(
                    '₹${inv.certifiedCr.toStringAsFixed(2)} Cr',
                    style: const TextStyle(color: AppTheme.tertiary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              if (!isApproved)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('SANCTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _approveCapexInvoice(inv),
                )
              else
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 16),
                    SizedBox(width: 4),
                    Text('DISBURSED', style: TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: EPC MAIN CONTRACTOR / L&T VIEW
  // ---------------------------------------------------------------------------

  Widget _buildEpcContractorView() {
    final filteredTargets = _dailyTargets.where((t) {
      if (_searchFilter.isNotEmpty) {
        final matches = t.activityName.toLowerCase().contains(_searchFilter) ||
            t.discipline.toLowerCase().contains(_searchFilter) ||
            t.gangAssigned.toLowerCase().contains(_searchFilter);
        if (!matches) return false;
      }
      if (_epcFilter == 'CRITICAL_PATH') return t.isCritical;
      if (_epcFilter == 'LAGGING') return t.status == 'LAGGING';
      return true;
    }).toList();

    final filteredGangs = _gangDeployments.where((g) {
      if (_searchFilter.isNotEmpty) {
        return g.gangName.toLowerCase().contains(_searchFilter) ||
            g.foreman.toLowerCase().contains(_searchFilter) ||
            g.trade.toLowerCase().contains(_searchFilter);
      }
      return true;
    }).toList();

    final filteredDprs = _dprRecords.where((dpr) {
      if (_searchFilter.isNotEmpty) {
        return dpr.dprNumber.toLowerCase().contains(_searchFilter) ||
            dpr.sector.toLowerCase().contains(_searchFilter) ||
            dpr.submittedBy.toLowerCase().contains(_searchFilter);
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRoleContextCard(
          title: 'EPC Main Contractor (L&T Hydrocarbon Engineering)',
          subtitle: 'FIDIC Clause 4 • Daily Target Enforcement, Heavy Plant & Gang Optimization',
          accentColor: StakeholderRole.epcMainContractor.primaryAccent,
          icon: StakeholderRole.epcMainContractor.icon,
        ),
        const SizedBox(height: 12),

        _buildFilterChipRow(
          activeFilter: _epcFilter,
          onSelect: (filter) => setState(() => _epcFilter = filter),
          filters: const [
            {'key': 'ALL', 'label': 'All Operations'},
            {'key': 'CRITICAL_PATH', 'label': 'Critical Path'},
            {'key': 'LAGGING', 'label': 'Lagging Tasks'},
          ],
        ),
        const SizedBox(height: 14),

        _buildSectionHeader(
          title: 'Daily Site Progress Targets',
          tag: 'Shift Output vs Plan',
          icon: Icons.track_changes_rounded,
        ),
        const SizedBox(height: 12),
        if (filteredTargets.isEmpty)
          _buildEmptyFilteredState('No targets matching filters.')
        else
          ...filteredTargets.map((target) => _buildDailyTargetCard(target)),
        const SizedBox(height: 20),

        _buildSectionHeader(
          title: 'Active Gang Deployment',
          tag: '${filteredGangs.length} Field Gangs',
          icon: Icons.groups_rounded,
        ),
        const SizedBox(height: 12),
        if (filteredGangs.isEmpty)
          _buildEmptyFilteredState('No gangs matching filters.')
        else
          ...filteredGangs.map((gang) => _buildGangDeploymentCard(gang)),
        const SizedBox(height: 20),

        _buildSectionHeader(
          title: 'Daily Progress Report (DPR) Verifications',
          tag: 'Field Submissions',
          icon: Icons.assignment_turned_in_rounded,
        ),
        const SizedBox(height: 12),
        if (filteredDprs.isEmpty)
          _buildEmptyFilteredState('No DPRs matching filters.')
        else
          ...filteredDprs.map((dpr) => _buildDprApprovalCard(dpr)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDailyTargetCard(DailyProgressTargetItem target) {
    final double pct = (target.actualToday / target.plannedToday) * 100;
    Color statusColor;
    if (pct >= 100) {
      statusColor = AppTheme.tertiary;
    } else if (pct >= 85) {
      statusColor = AppTheme.secondary;
    } else {
      statusColor = AppTheme.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      target.discipline,
                      style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (target.isCritical) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'CRITICAL PATH',
                        style: TextStyle(color: AppTheme.error, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '${pct.toStringAsFixed(1)}% Achieved',
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            target.activityName,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            target.gangAssigned,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (target.actualToday / target.plannedToday).clamp(0.0, 1.0),
                    backgroundColor: AppTheme.background,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${target.actualToday.toStringAsFixed(0)} / ${target.plannedToday.toStringAsFixed(0)} ${target.unit}',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGangDeploymentCard(GangDeploymentItem gang) {
    final bool isActive = gang.shiftStatus == 'ACTIVE';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  gang.gangName,
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.tertiary.withValues(alpha: 0.15) : AppTheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  gang.shiftStatus,
                  style: TextStyle(
                    color: isActive ? AppTheme.tertiary : AppTheme.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Foreman: ${gang.foreman} • ${gang.headcount} Craftsmen',
            style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                gang.locationChainage,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              const Spacer(),
              Text(
                'Plant Util: ${gang.utilizationRate}%',
                style: const TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.precision_manufacturing_rounded, size: 14, color: AppTheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gang.assignedEquipment,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDprApprovalCard(DprApprovalRecord dpr) {
    final bool isApproved = dpr.status == 'APPROVED';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApproved ? AppTheme.tertiary.withValues(alpha: 0.3) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dpr.dprNumber,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(dpr.timestamp, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(dpr.sector, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text('Submitted by: ${dpr.submittedBy}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDprChip('${dpr.jointsWelded} Welds', AppTheme.primaryLight),
              const SizedBox(width: 8),
              _buildDprChip('${dpr.trenchMeters.toStringAsFixed(0)}m Trench', AppTheme.secondary),
              const SizedBox(width: 8),
              _buildDprChip('${dpr.manHours} Man-Hrs', AppTheme.tertiary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isApproved)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: AppTheme.background,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('APPROVE & SIGN OFF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  onPressed: () => _approveDpr(dpr),
                )
              else
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.tertiary, size: 16),
                    SizedBox(width: 6),
                    Text('APPROVED BY EPC LEAD', style: TextStyle(color: AppTheme.tertiary, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDprChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: THIRD-PARTY INSPECTION / EIL-TPIA VIEW
  // ---------------------------------------------------------------------------

  Widget _buildThirdPartyInspectionView() {
    final filteredQhp = _qualityHoldPoints.where((q) {
      if (_searchFilter.isNotEmpty) {
        return q.title.toLowerCase().contains(_searchFilter) ||
            q.code.toLowerCase().contains(_searchFilter) ||
            q.chainage.toLowerCase().contains(_searchFilter);
      }
      if (_tpiaFilter == 'ACTIVE_HOLD') return q.status == 'HOLD_ACTIVE';
      return true;
    }).toList();

    final filteredNdt = _ndtRadiographs.where((n) {
      if (_searchFilter.isNotEmpty) {
        return n.weldJoint.toLowerCase().contains(_searchFilter) ||
            n.welderTag.toLowerCase().contains(_searchFilter) ||
            n.technique.toLowerCase().contains(_searchFilter);
      }
      if (_tpiaFilter == 'REPAIRS') return n.status == 'REPAIR_REQUIRED';
      return true;
    }).toList();

    final filteredHydro = _hydrotestSections.where((h) {
      if (_searchFilter.isNotEmpty) {
        return h.sectionName.toLowerCase().contains(_searchFilter) ||
            h.chainageSpan.toLowerCase().contains(_searchFilter);
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRoleContextCard(
          title: 'Third-Party Inspection Agency (Engineers India Limited - EIL)',
          subtitle: 'ISO 9001 / OISD-141 • Statutory Hold Points, NDT Weld Integrity & Hydrotest Clearance',
          accentColor: StakeholderRole.thirdPartyInspector.primaryAccent,
          icon: StakeholderRole.thirdPartyInspector.icon,
        ),
        const SizedBox(height: 12),

        _buildFilterChipRow(
          activeFilter: _tpiaFilter,
          onSelect: (filter) => setState(() => _tpiaFilter = filter),
          filters: const [
            {'key': 'ALL', 'label': 'All Quality Data'},
            {'key': 'ACTIVE_HOLD', 'label': 'Active Hold Points'},
            {'key': 'REPAIRS', 'label': 'Weld Repairs Required'},
          ],
        ),
        const SizedBox(height: 14),

        _buildSectionHeader(
          title: 'Mandatory Quality Hold Points (QHP)',
          tag: 'Statutory Stop-Work Gates',
          icon: Icons.shield_rounded,
        ),
        const SizedBox(height: 12),
        if (filteredQhp.isEmpty)
          _buildEmptyFilteredState('No quality hold points found.')
        else
          ...filteredQhp.map((qhp) => _buildQualityHoldPointCard(qhp)),
        const SizedBox(height: 20),

        _buildSectionHeader(
          title: 'NDT Radiographic & Ultrasonic Welds',
          tag: 'API 1104 / ASME Sec IX Standards',
          icon: Icons.camera_enhance_rounded,
        ),
        const SizedBox(height: 12),
        if (filteredNdt.isEmpty)
          _buildEmptyFilteredState('No NDT radiograph records found.')
        else
          ...filteredNdt.map((ndt) => _buildNdtRadiographCard(ndt)),
        const SizedBox(height: 20),

        _buildSectionHeader(
          title: '24-Hour Hydrostatic Test Packages',
          tag: 'FIDIC Cl. 9.1 Test on Completion',
          icon: Icons.speed_rounded,
        ),
        const SizedBox(height: 12),
        if (filteredHydro.isEmpty)
          _buildEmptyFilteredState('No hydrotest sections found.')
        else
          ...filteredHydro.map((ht) => _buildHydrotestCard(ht)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQualityHoldPointCard(QualityHoldPointItem qhp) {
    final bool isReleased = qhp.status == 'RELEASED';
    final Color statusColor = isReleased ? AppTheme.tertiary : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReleased ? AppTheme.tertiary.withValues(alpha: 0.3) : AppTheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isReleased ? 'RELEASED & CERTIFIED' : 'ACTIVE QUALITY HOLD POINT',
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(qhp.code, style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            qhp.title,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Standard: ${qhp.standard} • Location: ${qhp.chainage}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            'Inspector: ${qhp.inspector}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isReleased)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tertiary,
                    foregroundColor: AppTheme.background,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.verified_outlined, size: 16),
                  label: const Text('RELEASE HOLD POINT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  onPressed: () => _releaseQualityHoldPoint(qhp),
                )
              else
                const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 16),
                    SizedBox(width: 4),
                    Text('EIL LEVEL III CLEARED', style: TextStyle(color: AppTheme.tertiary, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNdtRadiographCard(NdtWeldRadiographItem ndt) {
    final bool isAccepted = ndt.status == 'ACCEPTED';
    final Color statusColor = isAccepted ? AppTheme.tertiary : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Text(
                ndt.weldJoint,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ndt.status.replaceAll('_', ' '),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Welder Tag: ${ndt.welderTag} • Chainage: ${ndt.chainage}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Dia: ${ndt.pipeDiaInches}" (${ndt.thicknessMm}mm)',
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11),
              ),
              const Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
              Text(
                'Method: ${ndt.technique}',
                style: const TextStyle(color: AppTheme.secondary, fontSize: 11),
              ),
              const Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
              Text(
                'Density: ${ndt.opticalDensity}',
                style: const TextStyle(color: AppTheme.tertiary, fontSize: 11),
              ),
            ],
          ),
          if (ndt.defectRemarks != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ndt.defectRemarks!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHydrotestCard(HydrotestSectionItem ht) {
    final bool isHolding = ht.certificationStatus == 'HOLDING_TEST';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHolding ? AppTheme.primaryLight.withValues(alpha: 0.5) : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ht.sectionName,
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isHolding ? AppTheme.primaryLight.withValues(alpha: 0.2) : AppTheme.textMuted.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ht.certificationStatus.replaceAll('_', ' '),
                  style: TextStyle(
                    color: isHolding ? AppTheme.primaryLight : AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Span: ${ht.chainageSpan} (${ht.lengthKm} km)',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(
                label: 'Test Pressure',
                value: '${ht.testPressureBar} bar',
                sub: '${(ht.testPressureBar * 14.5038).toStringAsFixed(0)} psi',
                color: AppTheme.primaryLight,
              ),
              _buildMiniMetric(
                label: 'Current Gauge',
                value: '${ht.currentHoldingPressureBar} bar',
                sub: 'Stable',
                color: AppTheme.tertiary,
              ),
              _buildMiniMetric(
                label: 'Elapsed Holding',
                value: '${ht.holdingHoursElapsed}h / ${ht.requiredHours}h',
                sub: isHolding ? 'Pressure Log Live' : 'Depressurizing',
                color: AppTheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Witness: ${ht.witnessAgency}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: SUBCONTRACTORS / GANG FOREMEN VIEW
  // ---------------------------------------------------------------------------

  Widget _buildSubcontractorForemanView() {
    final filteredOrders = _workOrders.where((o) {
      if (_searchFilter.isNotEmpty) {
        return o.orderNo.toLowerCase().contains(_searchFilter) ||
            o.scope.toLowerCase().contains(_searchFilter) ||
            o.gangName.toLowerCase().contains(_searchFilter);
      }
      if (_subFilter == 'ACTIVE_ORDERS') return o.status == 'IN_PROGRESS';
      return true;
    }).toList();

    final filteredIndents = _toolIndents.where((ti) {
      if (_searchFilter.isNotEmpty) {
        return ti.indentNo.toLowerCase().contains(_searchFilter) ||
            ti.toolDescription.toLowerCase().contains(_searchFilter);
      }
      if (_subFilter == 'EMERGENCY_INDENTS') return ti.urgency == 'EMERGENCY_2HR';
      return true;
    }).toList();

    final filteredMuster = _musterRolls.where((m) {
      if (_searchFilter.isNotEmpty) {
        return m.gangName.toLowerCase().contains(_searchFilter) ||
            m.leader.toLowerCase().contains(_searchFilter);
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRoleContextCard(
          title: 'Subcontractors & Field Gang Foremen',
          subtitle: 'Tactical Shift Orders • Real-time Tool & Rod Indents • Biometric Muster Roll Call',
          accentColor: StakeholderRole.subcontractorForeman.primaryAccent,
          icon: StakeholderRole.subcontractorForeman.icon,
        ),
        const SizedBox(height: 12),

        _buildFilterChipRow(
          activeFilter: _subFilter,
          onSelect: (filter) => setState(() => _subFilter = filter),
          filters: const [
            {'key': 'ALL', 'label': 'All Field Execution'},
            {'key': 'ACTIVE_ORDERS', 'label': 'Active Work Orders'},
            {'key': 'EMERGENCY_INDENTS', 'label': 'Emergency Indents'},
          ],
        ),
        const SizedBox(height: 14),

        // Quick Action Row for Foremen
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA78BFA),
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.handyman_rounded, size: 18),
                label: const Text('NEW TOOL INDENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _createNewToolIndent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFA78BFA)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.fingerprint_rounded, size: 18, color: Color(0xFFA78BFA)),
                label: const Text('MUSTER CHECK-IN', style: TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppTheme.surfaceCard,
                      content: Text('Shift Muster Verified: 241/249 gang members authenticated via Geofenced Biometrics.'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildSectionHeader(
          title: 'Daily Field Work Orders',
          tag: '${filteredOrders.length} Quotas',
          icon: Icons.assignment_rounded,
        ),
        const SizedBox(height: 12),
        if (filteredOrders.isEmpty)
          _buildEmptyFilteredState('No work orders found.')
        else
          ...filteredOrders.map((order) => _buildWorkOrderCard(order)),
        const SizedBox(height: 20),

        _buildSectionHeader(
          title: 'Urgent Tool & Material Indents',
          tag: '${filteredIndents.length} Indents',
          icon: Icons.build_circle_rounded,
        ),
        const SizedBox(height: 12),
        if (filteredIndents.isEmpty)
          _buildEmptyFilteredState('No tool indents found.')
        else
          ...filteredIndents.map((indent) => _buildToolIndentCard(indent)),
        const SizedBox(height: 20),

        _buildSectionHeader(
          title: 'Gang Muster Roll & Safety TBT',
          tag: 'Morning Safety Briefings',
          icon: Icons.checklist_rounded,
        ),
        const SizedBox(height: 12),
        if (filteredMuster.isEmpty)
          _buildEmptyFilteredState('No muster roll found.')
        else
          ...filteredMuster.map((muster) => _buildMusterRollCard(muster)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWorkOrderCard(DailyWorkOrderItem order) {
    final double pct = (order.completedQuantity / order.targetQuantity) * 100;
    final bool isHalted = order.status == 'HALTED_OBSTACLE';
    final Color statusColor = isHalted
        ? AppTheme.error
        : (pct >= 100 ? AppTheme.tertiary : const Color(0xFFA78BFA));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Text(
                order.orderNo,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.status.replaceAll('_', ' '),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.scope,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (order.completedQuantity / order.targetQuantity).clamp(0.0, 1.0),
                    backgroundColor: AppTheme.background,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${order.completedQuantity.toStringAsFixed(0)} / ${order.targetQuantity.toStringAsFixed(0)} ${order.unit}',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 14, color: AppTheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.hazardMitigation,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFA78BFA)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFFA78BFA)),
                label: const Text('LOG PROGRESS', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _submitWorkOrderProgress(order),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolIndentCard(ToolIndentItem indent) {
    Color statusColor;
    if (indent.status == 'DELIVERED') {
      statusColor = AppTheme.tertiary;
    } else if (indent.status == 'APPROVED_DISPATCHED') {
      statusColor = AppTheme.primaryLight;
    } else {
      statusColor = AppTheme.secondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Text(
                indent.indentNo,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  indent.status.replaceAll('_', ' '),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            indent.toolDescription,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Qty: ${indent.quantity}', style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 11)),
              const Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
              Text('Gang: ${indent.requestedByGang}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const Spacer(),
              Text(indent.requestTime, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMusterRollCard(MusterRollSummaryItem muster) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Text(
                muster.gangName,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, size: 14, color: AppTheme.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${muster.biometricCount}/${muster.totalStrength} Biometric',
                    style: const TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Gang Leader: ${muster.leader} • Present: ${muster.presentCount} Craftsmen',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety_rounded, size: 14, color: AppTheme.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TBT Briefing: "${muster.toolboxTalkTopic}" (Signed)',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildFilterChipRow({
    required String activeFilter,
    required ValueChanged<String> onSelect,
    required List<Map<String, String>> filters,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = activeFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onSelect(f['key']!);
                }
              },
              backgroundColor: AppTheme.surfaceCard,
              selectedColor: _activeRole.primaryAccent.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? _activeRole.primaryAccent : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? _activeRole.primaryAccent : AppTheme.border,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyFilteredState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.filter_list_off_rounded, size: 36, color: AppTheme.textMuted),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleContextCard({
    required String title,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String tag,
    required IconData icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: _activeRole.primaryAccent),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(
            tag,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }
}
