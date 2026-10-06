import 'package:flutter/material.dart';

/// Department taxonomy for major infrastructure projects
enum ProjectDepartment {
  executiveClient,
  civilStructures,
  pipingMechanical,
  electricalInstrumentation,
  planningControls,
  qaQcInspection,
  hseSafety,
  materialsStores,
  workforceFieldGangs,
}

/// Comprehensive Role-Based Authority Definition
class RoleAuthority {
  final String roleCode;
  final String roleTitle;
  final String departmentName;
  final String fidicJurisdiction;
  final String financialLimit;
  final Color badgeColor;
  final IconData icon;

  /// Visible modules & screens (Read Access)
  final List<String> viewScope;

  /// Creation Permissions (Write Access)
  final List<String> createAuthority;

  /// Approval & Sign-Off Rights (Admin / Governance Access)
  final List<String> approveAuthority;

  /// Editing & Modification Authority (Update Access)
  final List<String> editAuthority;

  const RoleAuthority({
    required this.roleCode,
    required this.roleTitle,
    required this.departmentName,
    required this.fidicJurisdiction,
    required this.financialLimit,
    required this.badgeColor,
    required this.icon,
    required this.viewScope,
    required this.createAuthority,
    required this.approveAuthority,
    required this.editAuthority,
  });
}

/// Master Department & Role Authority Matrix
class AuthorityMatrix {
  static const List<RoleAuthority> allRoles = [
    // 1. EXECUTIVE & CLIENT (PROJECT DIRECTOR / CHIEF ENGINEER)
    RoleAuthority(
      roleCode: 'DIR_EXEC',
      roleTitle: 'Project Director / Client Chief Representative',
      departmentName: 'Executive, Client & Project Governance',
      fidicJurisdiction: "Engineer's Representative (FIDIC Red/Yellow Book Cl. 3.1)",
      financialLimit: 'Unlimited / Board Sanctioned Budget',
      badgeColor: Color(0xFFFFB95F),
      icon: Icons.analytics_rounded,
      viewScope: [
        'ALL_MODULES',
        'EVM_FINANCE',
        'MASTER_SCHEDULE_P6',
        'FIDIC_CLAIMS_DAB',
        'CONFLICT_CENTER',
        'DIGITAL_TWIN',
        'EXECUTIVE_DOSSIER',
      ],
      createAuthority: [
        'PROJECT_CHARTER',
        'VARIATION_ORDER_SANCTION',
        'EOT_DETERMINATION',
        'DISPUTE_REFERRAL_DAB',
        'COMMISSIONING_CLEARANCE',
      ],
      approveAuthority: [
        'VARIATION_ORDERS_ABOVE_1CR',
        'MONTHLY_CONTRACTOR_INVOICE',
        'EOT_EXTENSION_DAYS',
        'FINAL_TAKEOVER_CERTIFICATE',
        'SUB_CONTRACTOR_MOBILIZATION',
      ],
      editAuthority: [
        'CONTRACT_BASELINE',
        'BUDGET_REALLOCATION',
        'CRITICAL_PATH_OVERRIDE',
      ],
    ),

    // 2. PLANNING & CONTROLS (CHIEF SCHEDULER & DELAY ANALYST)
    RoleAuthority(
      roleCode: 'PLN_ENG',
      roleTitle: 'Planning & Project Controls Lead',
      departmentName: 'Project Controls & Baseline Governance',
      fidicJurisdiction: 'Delay Analyst & Time Program Lead (FIDIC Cl. 8.3 / 8.4)',
      financialLimit: 'Up to ₹25 Lakhs (Acceleration Provisions)',
      badgeColor: Color(0xFF818CF8),
      icon: Icons.calendar_month_rounded,
      viewScope: [
        'MASTER_SCHEDULE_P6',
        'WBS_LEVELS_1_6',
        'CRITICAL_PATH_FLOATS',
        'DPR_SUBMISSIONS',
        'WEATHER_STOPPAGES',
        'SCADA_TELEMETRY',
        'GANTT_VIEW',
      ],
      createAuthority: [
        'P6_ACTIVITY_IMPORT',
        'SCHEDULE_BASELINE_V2',
        'TIME_IMPACT_ANALYSIS_TIA',
        'FIDIC_8_4_WEATHER_NOTICE',
      ],
      approveAuthority: [
        'PROGRESS_PERCENT_SIGN_OFF',
        'SCHEDULE_RE_SEQUENCING',
        'DPR_INSTALLED_QUANTITIES',
      ],
      editAuthority: [
        'ACTIVITY_LOGICAL_RELATIONSHIPS',
        'DURATION_DAYS',
        'FLOAT_CONSUMPTION_LOGS',
      ],
    ),

    // 3. SITE PIPING / CIVIL SUPERVISOR (RESIDENT SITE ENGINEER)
    RoleAuthority(
      roleCode: 'SITE_SUP',
      roleTitle: 'Resident Site Supervisor / Section In-Charge',
      departmentName: 'Civil, Piping & Marine Field Operations',
      fidicJurisdiction: 'Section In-Charge & Works Superintendent (FIDIC Cl. 4.21)',
      financialLimit: 'Up to ₹5 Lakhs (Emergency Field Procurements)',
      badgeColor: Color(0xFF38BDF8),
      icon: Icons.engineering_rounded,
      viewScope: [
        'DPR_PROGRESS_LOG',
        'WORKFORCE_ATTENDANCE',
        'MATERIALS_STORES_GIN',
        'EQUIPMENT_FLEET',
        'SAFETY_PERMITS_PTW',
        'VOICE_ASSISTANT',
      ],
      createAuthority: [
        'DAILY_DPR_SUBMISSION',
        'VOICE_UPDATE_HINDI_ENGLISH',
        'MATERIAL_ISSUE_REQUEST_GIN',
        'GANG_ALLOCATION_ROSTER',
        'EQUIPMENT_BREAKDOWN_LOG',
        'SITE_VISIT_CAPTCHA_VERIFICATION',
      ],
      approveAuthority: [
        'LABOUR_SHIFT_ATTENDANCE',
        'DAILY_CONSUMABLES_DISPATCH',
        'TRENCH_PREPARATION_PASS',
      ],
      editAuthority: [
        'INSTALLED_QUANTITY_LOG',
        'SHIFT_DELAY_REASON',
        'CHAINAGE_START_FINISH',
      ],
    ),

    // 4. QA/QC & TESTING LAB (LEAD INSPECTION OFFICER)
    RoleAuthority(
      roleCode: 'QA_QC_LEAD',
      roleTitle: 'QA/QC Lead Inspector & Materials Engineer',
      departmentName: 'Quality Assurance & NDT Testing Labs',
      fidicJurisdiction: 'Quality Authority & Inspection Test Plan Lead (FIDIC Cl. 7.3)',
      financialLimit: 'Zero (Non-Financial Inspection Integrity Guard)',
      badgeColor: Color(0xFF10B981),
      icon: Icons.fact_check_rounded,
      viewScope: [
        'QUALITY_HOLD_POINTS',
        'NDT_WELD_CLEARANCE',
        'CONCRETE_CUBE_BREAKS',
        'MATERIAL_TEST_CERTS_MTR',
        'PIPE_HEAT_TALLY',
        'NON_CONFORMANCE_REPORTS',
      ],
      createAuthority: [
        'INSPECTION_TEST_PLAN_ITP',
        'AUT_RADIOGRAPHY_CLEARANCE',
        'CUBE_CRUSH_TEST_ENTRY',
        'NON_CONFORMANCE_NOTICE_NCR',
        'LAB_EXPEDITE_NOTICE',
      ],
      approveAuthority: [
        'MANDATORY_HOLD_POINT_RELEASE',
        'POUR_CARD_CONCRETE_CLEARANCE',
        'PIPE_GOLDEN_WELD_CERTIFICATE',
        'MATERIAL_ACCEPTANCE_GRN',
      ],
      editAuthority: [
        'TEST_OBSERVED_VALUE',
        'WELD_REPAIR_STATUS',
        'CALIBRATION_EXPIRY_DATE',
      ],
    ),

    // 5. SAFETY & HSE (HSE DIRECTOR & FIELD COMPLIANCE OFFICER)
    RoleAuthority(
      roleCode: 'HSE_LEAD',
      roleTitle: 'HSE & Safety Lead Officer',
      departmentName: 'Health, Safety & Environmental Compliance',
      fidicJurisdiction: 'Safety Representative (FIDIC Cl. 4.8 / 6.7 Zero-Harm)',
      financialLimit: 'Up to ₹10 Lakhs (Emergency PPE & Rescue Kit)',
      badgeColor: Color(0xFFEF4444),
      icon: Icons.health_and_safety_rounded,
      viewScope: [
        'SAFETY_PERMITS_PTW',
        'INCIDENT_RCA_REPORTS',
        'GAS_MONITORING_TELEMETRY',
        'WEATHER_STATION_SENSORS',
        'TOOLBOX_TALK_ROSTERS',
        'ENVIRONMENTAL_COMPLIANCE',
      ],
      createAuthority: [
        'HOT_WORK_PERMIT_PTW',
        'CONFINED_SPACE_PERMIT',
        'TANDEM_HEAVY_LIFT_PERMIT',
        'INCIDENT_RCA_INVESTIGATION',
        'STOP_WORK_SAFETY_ORDER',
      ],
      approveAuthority: [
        'PTW_ACTIVATION_AND_CLOSURE',
        'ATMOSPHERIC_GAS_SAFETY_SIGN_OFF',
        'RIVER_CROSSING_LIFE_JACKET_CLEARANCE',
      ],
      editAuthority: [
        'TOOLBOX_TALK_ATTENDEE_COUNT',
        'GAS_DETECTOR_CALIBRATION_LOG',
      ],
    ),

    // 6. STORES, MATERIALS & LOGISTICS (GATEKEEPER & WEIGHBRIDGE LEAD)
    RoleAuthority(
      roleCode: 'MAT_MGR',
      roleTitle: 'Materials Controller & Store Yard In-Charge',
      departmentName: 'Stores, Materials & Procurement Logistics',
      fidicJurisdiction: 'Materials Vesting Officer (FIDIC Cl. 7.7 / 8.10 Off-Site Goods)',
      financialLimit: 'Up to ₹25 Lakhs (Consumables Purchase Orders)',
      badgeColor: Color(0xFFF59E0B),
      icon: Icons.inventory_2_rounded,
      viewScope: [
        'MATERIALS_STORES_LEDGER',
        'PIPE_HEAT_NUMBER_TALLY',
        'WEIGHBRIDGE_TICKETS',
        'PURCHASE_ORDERS_PO',
        'GATE_PASS_REGISTER',
      ],
      createAuthority: [
        'GOODS_RECEIPT_NOTE_GRN',
        'GOODS_ISSUE_NOTE_GIN',
        'WEIGHBRIDGE_TARE_NET_ENTRY',
        'RETURN_TO_VENDOR_RTV',
        'GATE_PASS_DISPATCH',
      ],
      approveAuthority: [
        'STORE_RECEIPT_VERIFICATION',
        'DISPATCH_TO_SITE_GANGS',
        'CONSUMABLES_REORDER_FLAG',
      ],
      editAuthority: [
        'STORAGE_LOCATION_BIN',
        'HEAT_NUMBER_MAPPING',
        'STOCK_INVENTORY_BALANCE',
      ],
    ),

    // 7. CONTRACTOR & LABOUR GANG FOREMAN (SKILLED TRADE / LABOUR ID)
    RoleAuthority(
      roleCode: 'LAB_GANG',
      roleTitle: 'Certified Welder / Field Gang Foreman',
      departmentName: 'Subcontractor Trade & Direct Labour Force',
      fidicJurisdiction: 'Contractor Workforce Representative (FIDIC Cl. 6.9 Labor Engagement)',
      financialLimit: 'Zero (Piece-Rate / Daily Wage Earner)',
      badgeColor: Color(0xFF00E5FF),
      icon: Icons.badge_rounded,
      viewScope: [
        'LABOUR_SELF_SERVICE',
        'ATTENDANCE_RECORD',
        'WAGE_SLIP_STATEMENT',
        'SAFETY_CERTIFICATION_STATUS',
      ],
      createAuthority: [
        'GPS_BIOMETRIC_CLOCK_IN',
        'WELDER_STAMP_TALLY',
        'SAFETY_GRIEVANCE_REPORT',
      ],
      approveAuthority: [
        'OWN_TIME_CARD_ACCEPTANCE',
      ],
      editAuthority: [
        'EMERGENCY_CONTACT_PHONE',
      ],
    ),
  ];

  /// Get role authority by role title or code
  static RoleAuthority getRole(String roleIdentifier) {
    final clean = roleIdentifier.trim().toLowerCase();
    for (final role in allRoles) {
      if (role.roleCode.toLowerCase() == clean ||
          role.roleTitle.toLowerCase().contains(clean) ||
          clean.contains(role.roleTitle.toLowerCase().split(' ').first)) {
        return role;
      }
    }
    // Default fallback to Site Supervisor
    return allRoles[2];
  }

  /// Permission checker: can this role view module?
  static bool canView(String roleTitle, String moduleKey) {
    final role = getRole(roleTitle);
    if (role.viewScope.contains('ALL_MODULES')) return true;
    final upperKey = moduleKey.toUpperCase();
    return role.viewScope.any((scope) => scope.contains(upperKey) || upperKey.contains(scope));
  }

  /// Permission checker: can this role create action?
  static bool canCreate(String roleTitle, String actionKey) {
    final role = getRole(roleTitle);
    final upperKey = actionKey.toUpperCase();
    return role.createAuthority.any((auth) => auth.contains(upperKey) || upperKey.contains(auth));
  }

  /// Permission checker: can this role approve?
  static bool canApprove(String roleTitle, String approvalKey) {
    final role = getRole(roleTitle);
    final upperKey = approvalKey.toUpperCase();
    return role.approveAuthority.any((auth) => auth.contains(upperKey) || upperKey.contains(auth));
  }
}
