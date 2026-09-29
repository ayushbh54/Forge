import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & STATUTORY STANDARDS (Assam Minimum Wages Act 2024 Revision)
// ============================================================================

enum SkillTier {
  skilled,
  semiSkilled,
  unskilled,
}

extension SkillTierExt on SkillTier {
  String get label {
    switch (this) {
      case SkillTier.skilled:
        return 'Skilled';
      case SkillTier.semiSkilled:
        return 'Semi-Skilled';
      case SkillTier.unskilled:
        return 'Unskilled';
    }
  }

  Color get color {
    switch (this) {
      case SkillTier.skilled:
        return const Color(0xFF38BDF8); // PrimaryLight
      case SkillTier.semiSkilled:
        return const Color(0xFFFFB95F); // Amber
      case SkillTier.unskilled:
        return const Color(0xFF818CF8); // Indigo
    }
  }
}

class AssamStatutoryWageStandard {
  final SkillTier tier;
  final String title;
  final double basicDailyWage;
  final double vdaDaily; // Variable Dearness Allowance (Assam Gazette 2024)
  final double totalDailyWage;
  final double monthlyWage26Days;
  final double statutoryOtHourlyRate; // 2x hourly rate under Factories/BOCW Act
  final List<String> eligibleTrades;
  final int activeHeadcount;
  final int compliantHeadcount;

  const AssamStatutoryWageStandard({
    required this.tier,
    required this.title,
    required this.basicDailyWage,
    required this.vdaDaily,
    required this.totalDailyWage,
    required this.monthlyWage26Days,
    required this.statutoryOtHourlyRate,
    required this.eligibleTrades,
    required this.activeHeadcount,
    required this.compliantHeadcount,
  });

  int get nonCompliantHeadcount => activeHeadcount - compliantHeadcount;
  double get complianceRate =>
      activeHeadcount > 0 ? (compliantHeadcount / activeHeadcount) * 100 : 0.0;
}

class LaborerAuditRecord {
  final String id;
  final String badgeNumber;
  final String name;
  final String trade;
  final SkillTier skillTier;
  final String contractor;
  final double dailyWagePaid;
  final double statutoryMinWage;
  final String epfUan;
  final String epfStatus; // 'VERIFIED', 'KYC_PENDING', 'MISSING'
  final String epfTrrnRef;
  final String esicIpNumber;
  final String esicStatus; // 'ACTIVE', 'SUBMITTED', 'UNREGISTERED'
  final String esicDispensary;
  final String dbtStatus; // 'SETTLED', 'PROCESSING', 'CASH_VIOLATION'
  final String bankName;
  final String bankAccountMasked;
  final String ifscCode;
  final String dbtTxnId;
  final int musterRollDays;
  final int biometricDays;
  final int overtimeHours;
  final double otMultiplierPaid; // Should be 2.0x, 1.0x if violation
  final List<String> complianceIssues;

  const LaborerAuditRecord({
    required this.id,
    required this.badgeNumber,
    required this.name,
    required this.trade,
    required this.skillTier,
    required this.contractor,
    required this.dailyWagePaid,
    required this.statutoryMinWage,
    required this.epfUan,
    required this.epfStatus,
    required this.epfTrrnRef,
    required this.esicIpNumber,
    required this.esicStatus,
    required this.esicDispensary,
    required this.dbtStatus,
    required this.bankName,
    required this.bankAccountMasked,
    required this.ifscCode,
    required this.dbtTxnId,
    required this.musterRollDays,
    required this.biometricDays,
    required this.overtimeHours,
    required this.otMultiplierPaid,
    this.complianceIssues = const [],
  });

  bool get isWageCompliant => dailyWagePaid >= statutoryMinWage;
  double get wageDeficit =>
      dailyWagePaid < statutoryMinWage ? statutoryMinWage - dailyWagePaid : 0.0;
  int get attendanceDiscrepancy => musterRollDays - biometricDays;
  bool get hasGhostAttendance => attendanceDiscrepancy > 0;
  bool get isOtCompliant => otMultiplierPaid >= 2.0;

  double get regularGrossWage => biometricDays * dailyWagePaid;
  double get hourlyWage => dailyWagePaid / 8.0;
  double get otEarnings => overtimeHours * (hourlyWage * otMultiplierPaid);
  double get totalGrossEarnings => regularGrossWage + otEarnings;

  // Statutory Deductions
  double get epfEmployeeDeduction => (regularGrossWage * 0.12).roundToDouble();
  double get esicEmployeeDeduction => (totalGrossEarnings * 0.0075).roundToDouble();
  double get netDisbursed =>
      totalGrossEarnings - epfEmployeeDeduction - esicEmployeeDeduction;

  bool get hasAnyViolation =>
      !isWageCompliant ||
      epfStatus != 'VERIFIED' ||
      esicStatus != 'ACTIVE' ||
      dbtStatus == 'CASH_VIOLATION' ||
      hasGhostAttendance ||
      !isOtCompliant;
}

class ContractorComplianceAudit {
  final String id;
  final String name;
  final String code;
  final String tradeDiscipline;
  final int totalLaborers;
  final double wageComplianceRate;
  final double epfComplianceRate;
  final double esicComplianceRate;
  final double biometricMatchRate;
  final double dbtComplianceRate;
  final double otReconciliationRate;
  final double overallScore;
  final String complianceGrade; // 'GRADE A', 'GRADE B', 'GRADE C (AT RISK)'
  final int ghostDaysClaimed;
  final int wageBreachCount;
  final int cashViolationCount;
  final bool isRetentionWithheld;
  final double withheldAmountLakhs;
  final List<String> activeNotices;

  const ContractorComplianceAudit({
    required this.id,
    required this.name,
    required this.code,
    required this.tradeDiscipline,
    required this.totalLaborers,
    required this.wageComplianceRate,
    required this.epfComplianceRate,
    required this.esicComplianceRate,
    required this.biometricMatchRate,
    required this.dbtComplianceRate,
    required this.otReconciliationRate,
    required this.overallScore,
    required this.complianceGrade,
    required this.ghostDaysClaimed,
    required this.wageBreachCount,
    required this.cashViolationCount,
    required this.isRetentionWithheld,
    required this.withheldAmountLakhs,
    required this.activeNotices,
  });

  Color get gradeColor {
    if (overallScore >= 95.0) return const Color(0xFF4EDEA3);
    if (overallScore >= 85.0) return const Color(0xFFFFB95F);
    return const Color(0xFFFF6B6B);
  }
}

class StatutoryWarningNotice {
  final String noticeId;
  final String contractorId;
  final String contractorName;
  final String noticeType; // '48-Hour Show Cause', '7-Day Cure Notice', 'Retention Notice'
  final String legalStatute;
  final String issueDate;
  final String cureDeadline;
  final String summary;
  final List<String> specificViolations;
  final double financialPenaltyLakhs;
  final String status; // 'ACTIVE_CURE_PENDING', 'RESOLVED', 'ESCALATED_FIDIC_14_6'
  final String issuedBy;

  const StatutoryWarningNotice({
    required this.noticeId,
    required this.contractorId,
    required this.contractorName,
    required this.noticeType,
    required this.legalStatute,
    required this.issueDate,
    required this.cureDeadline,
    required this.summary,
    required this.specificViolations,
    required this.financialPenaltyLakhs,
    required this.status,
    required this.issuedBy,
  });
}

// ============================================================================
// MAIN SCREEN IMPLEMENTATION
// ============================================================================

class WageComplianceScreen extends StatefulWidget {
  const WageComplianceScreen({super.key});

  @override
  State<WageComplianceScreen> createState() => _WageComplianceScreenState();
}

class _WageComplianceScreenState extends State<WageComplianceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter & Search states
  String _searchQuery = '';
  String _selectedContractorFilter = 'ALL';
  final String _selectedTierFilter = 'ALL';
  String _selectedStatusFilter = 'ALL'; // 'ALL', 'VIOLATIONS_ONLY', 'EPF_ISSUES', 'ESIC_ISSUES', 'GHOST_DAYS', 'CASH_PAY'

  // Dynamic state for withholding toggles and notices
  late List<ContractorComplianceAudit> _contractors;
  late List<StatutoryWarningNotice> _warningNotices;
  late List<LaborerAuditRecord> _laborers;

  // Assam Statutory standards lookup
  final List<AssamStatutoryWageStandard> _statutoryStandards = const [
    AssamStatutoryWageStandard(
      tier: SkillTier.skilled,
      title: 'Skilled Trades (Category I)',
      basicDailyWage: 415.00,
      vdaDaily: 125.00,
      totalDailyWage: 540.00,
      monthlyWage26Days: 14040.00,
      statutoryOtHourlyRate: 135.00, // (540 / 8) * 2
      eligibleTrades: [
        'Welder 6G / GTAW',
        'NDT & Radiographer',
        'Crane Operator',
        'Master Electrician',
        'Precision Pipe Fabricator',
      ],
      activeHeadcount: 100,
      compliantHeadcount: 100,
    ),
    AssamStatutoryWageStandard(
      tier: SkillTier.semiSkilled,
      title: 'Semi-Skilled Trades (Category II)',
      basicDailyWage: 350.00,
      vdaDaily: 100.00,
      totalDailyWage: 450.00,
      monthlyWage26Days: 11700.00,
      statutoryOtHourlyRate: 112.50, // (450 / 8) * 2
      eligibleTrades: [
        'Pipe Fitter',
        'Bar Bender',
        'Rigger',
        'Scaffolder',
        'Hydro-test Pump Operator',
        'Gas Cutter',
      ],
      activeHeadcount: 80,
      compliantHeadcount: 78,
    ),
    AssamStatutoryWageStandard(
      tier: SkillTier.unskilled,
      title: 'Unskilled Trades (Category III)',
      basicDailyWage: 300.00,
      vdaDaily: 80.00,
      totalDailyWage: 380.00,
      monthlyWage26Days: 9880.00,
      statutoryOtHourlyRate: 95.00, // (380 / 8) * 2
      eligibleTrades: [
        'General Helper',
        'Trench Khalasi',
        'Earthwork Beldar',
        'Material Handler',
        'Site Watchman',
      ],
      activeHeadcount: 60,
      compliantHeadcount: 50,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _contractors = [
      const ContractorComplianceAudit(
        id: 'CONT-LT-01',
        name: 'L&T Hydrocarbon Engineering',
        code: 'LTH-PIP',
        tradeDiscipline: 'Trunk Pipeline & Mechanical',
        totalLaborers: 92,
        wageComplianceRate: 100.0,
        epfComplianceRate: 100.0,
        esicComplianceRate: 97.8,
        biometricMatchRate: 99.1,
        dbtComplianceRate: 100.0,
        otReconciliationRate: 100.0,
        overallScore: 98.4,
        complianceGrade: 'GRADE A (EXEMPLARY)',
        ghostDaysClaimed: 0,
        wageBreachCount: 0,
        cashViolationCount: 0,
        isRetentionWithheld: false,
        withheldAmountLakhs: 0.0,
        activeNotices: [],
      ),
      const ContractorComplianceAudit(
        id: 'CONT-BIP-02',
        name: 'Brahmaputra Infra Projects',
        code: 'BIP-CIV',
        tradeDiscipline: 'Civil Works & Trenching',
        totalLaborers: 68,
        wageComplianceRate: 85.3,
        epfComplianceRate: 85.3,
        esicComplianceRate: 82.4,
        biometricMatchRate: 91.2,
        dbtComplianceRate: 88.2,
        otReconciliationRate: 79.4,
        overallScore: 72.8,
        complianceGrade: 'GRADE C (STATUTORY BREACH)',
        ghostDaysClaimed: 42,
        wageBreachCount: 10,
        cashViolationCount: 8,
        isRetentionWithheld: true,
        withheldAmountLakhs: 6.85,
        activeNotices: ['SCN-OIL-2026-04'],
      ),
      const ContractorComplianceAudit(
        id: 'CONT-DMF-03',
        name: 'Duliajan Mech Fabricators',
        code: 'DMF-FAB',
        tradeDiscipline: 'Welding & Structural Spools',
        totalLaborers: 44,
        wageComplianceRate: 95.5,
        epfComplianceRate: 95.5,
        esicComplianceRate: 93.2,
        biometricMatchRate: 96.8,
        dbtComplianceRate: 95.5,
        otReconciliationRate: 94.0,
        overallScore: 89.6,
        complianceGrade: 'GRADE B (CURE WINDOW)',
        ghostDaysClaimed: 6,
        wageBreachCount: 2,
        cashViolationCount: 0,
        isRetentionWithheld: false,
        withheldAmountLakhs: 0.0,
        activeNotices: ['CN-OIL-2026-01'],
      ),
      const ContractorComplianceAudit(
        id: 'CONT-ERL-04',
        name: 'Eastern Rigging & Logistics',
        code: 'ERL-RIG',
        tradeDiscipline: 'Heavy Lifting & Pipe Transport',
        totalLaborers: 36,
        wageComplianceRate: 100.0,
        epfComplianceRate: 100.0,
        esicComplianceRate: 97.2,
        biometricMatchRate: 97.5,
        dbtComplianceRate: 100.0,
        otReconciliationRate: 98.0,
        overallScore: 95.2,
        complianceGrade: 'GRADE A (COMPLIANT)',
        ghostDaysClaimed: 0,
        wageBreachCount: 0,
        cashViolationCount: 0,
        isRetentionWithheld: false,
        withheldAmountLakhs: 0.0,
        activeNotices: [],
      ),
    ];

    _warningNotices = [
      const StatutoryWarningNotice(
        noticeId: 'SCN-OIL-2026-04',
        contractorId: 'CONT-BIP-02',
        contractorName: 'Brahmaputra Infra Projects',
        noticeType: '48-Hour Statutory Show Cause Notice',
        legalStatute:
            'Minimum Wages Act 1948 (Assam 2024 Gazette) §20(2), Contract Labour Act 1970 §21(4), FIDIC Cl. 14.6',
        issueDate: '28 Sep 2026',
        cureDeadline: '30 Sep 2026 18:00 IST',
        summary:
            'Statutory wage underpayment, ghost muster roll man-days, cash advance violations, and unpaid overtime multipliers.',
        specificViolations: [
          '10 Unskilled trench laborers paid ₹350/day vs mandatory Assam Minimum Wage floor of ₹380/day (Total wage deficit: ₹7,800).',
          '42 Muster Roll man-days billed with 0 turnstile biometric clock-in verification logs (Ghost labor claim: ₹15,960).',
          '8 Laborers disbursed via unregistered cash advances violating Section 6 Direct Bank Transfer mandate.',
          'Overtime compensated at 1.0x flat rate instead of mandatory double-rate (2.0x) under BOCW / Factories Act (OT deficit: ₹14,060).',
        ],
        financialPenaltyLakhs: 6.85,
        status: 'ACTIVE_CURE_PENDING',
        issuedBy: 'Marcus Vance, P.E. (Project Director / FIDIC Engineer 3.1)',
      ),
      const StatutoryWarningNotice(
        noticeId: 'CN-OIL-2026-01',
        contractorId: 'CONT-DMF-03',
        contractorName: 'Duliajan Mech Fabricators',
        noticeType: '7-Day Statutory Rectification Cure Notice',
        legalStatute: 'EPF & MP Act 1952 §7A & ESIC Act 1948 §45A',
        issueDate: '25 Sep 2026',
        cureDeadline: '02 Oct 2026 18:00 IST',
        summary:
            'Aadhaar UAN seeding backlog and biometric Pehchan insurance cards dispatch for welding spool helpers.',
        specificViolations: [
          '2 Semi-skilled spools fitters pending Aadhaar-UAN seeding on EPFO Unified Member portal.',
          '3 Laborers pending biometric verification for ESIC Pehchan Cards at Duliajan Branch Dispensary.',
          '6 Muster Roll days with biometric log discrepancies pending supervisor verification.',
        ],
        financialPenaltyLakhs: 0.0,
        status: 'ACTIVE_CURE_PENDING',
        issuedBy: 'Ananya Sen (Lead Project Controls & Statutory Officer)',
      ),
    ];

    _laborers = _generateAll240Laborers();
  }

  /// Generates the complete 240 active site laborers with deterministic, realistic data
  List<LaborerAuditRecord> _generateAll240Laborers() {
    final list = <LaborerAuditRecord>[];

    final assamFirstNames = [
      'Bikash', 'Manoranjan', 'Pranjal', 'Dipankar', 'Hemanta', 'Mrinal', 'Debajit',
      'Nayan', 'Partha', 'Bhupen', 'Ratan', 'Subhash', 'Tarun', 'Anup', 'Gopal',
      'Kishore', 'Bipul', 'Jatin', 'Raju', 'Mukesh', 'Santosh', 'Rajesh', 'Sanjib',
      'Suraj', 'Dinesh', 'Ajit', 'Pankaj', 'Babul', 'Kamal', 'Paban', 'Ramen'
    ];

    final assamLastNames = [
      'Gogoi', 'Saikia', 'Borah', 'Dutta', 'Barman', 'Phukan', 'Hazarika', 'Mech',
      'Sonowal', 'Rabha', 'Das', 'Sarmah', 'Chetia', 'Miri', 'Kachari', 'Chutia',
      'Barua', 'Lahkar', 'Kalita', 'Tamuly', 'Nath', 'Deka', 'Moran', 'Konwar'
    ];

    final banks = ['State Bank of India', 'Punjab National Bank', 'Union Bank of India', 'Canara Bank', 'Bank of Baroda'];

    int globalIndex = 0;

    void addGroup({
      required String contractor,
      required int count,
      required int skilledCount,
      required int semiSkilledCount,
      required int unskilledCount,
      required double baseWageBonus,
      required bool hasBreaches,
      required int ghostWorkerLaborersCount,
      required int cashPaymentLaborersCount,
    }) {
      int localIndex = 0;
      for (int i = 0; i < count; i++) {
        globalIndex++;
        localIndex++;
        final badge = 'LAB-${1000 + globalIndex}';
        final fName = assamFirstNames[(globalIndex + 7) % assamFirstNames.length];
        final lName = assamLastNames[(globalIndex * 3) % assamLastNames.length];
        final name = '$fName $lName';
        final bank = banks[globalIndex % banks.length];
        final ifsc = '${bank.split(' ').map((w) => w[0]).join()}000${(globalIndex % 8) + 1}28';
        final accMask = '•••• ${(1000 + (globalIndex * 37) % 9000)}';

        SkillTier tier;
        String trade;
        double minWage;
        double paidWage;

        if (i < skilledCount) {
          tier = SkillTier.skilled;
          minWage = 540.0;
          trade = ['Welder 6G / GTAW', 'Crane Operator', 'NDT Inspector', 'Master Electrician', 'Pipe Fabricator'][i % 5];
          paidWage = 540.0 + baseWageBonus + ((i % 4) * 15.0);
        } else if (i < skilledCount + semiSkilledCount) {
          tier = SkillTier.semiSkilled;
          minWage = 450.0;
          trade = ['Pipe Fitter', 'Bar Bender', 'Rigger', 'Scaffolder', 'Hydro-test Operator', 'Gas Cutter'][i % 6];
          if (hasBreaches && (i == skilledCount || i == skilledCount + 1)) {
            // Minor wage breach for 2 workers in Duliajan Mech
            paidWage = 440.0; // ₹10 below min wage
          } else {
            paidWage = 450.0 + baseWageBonus + ((i % 3) * 10.0);
          }
        } else {
          tier = SkillTier.unskilled;
          minWage = 380.0;
          trade = ['General Helper', 'Trench Khalasi', 'Earthwork Beldar', 'Material Handler', 'Watchman'][i % 5];
          if (hasBreaches && (i - skilledCount - semiSkilledCount) < 10) {
            // Flagged wage breach for 10 unskilled workers in Brahmaputra Infra!
            paidWage = 350.0; // ₹30 below statutory min wage!
          } else {
            paidWage = 380.0 + baseWageBonus + ((i % 2) * 10.0);
          }
        }

        // EPF & ESIC distribution
        String epfUan = '101${(800000000 + (globalIndex * 1337)) % 900000000}';
        String epfStatus = 'VERIFIED';
        String epfTrrn = 'TRRN-2609-${100000 + globalIndex}';

        String esicIp = '1324${(5000000000000 + (globalIndex * 997)) % 9000000000000}';
        String esicStatus = 'ACTIVE';
        String esicDispensary = (globalIndex % 2 == 0)
            ? 'ESIC Dispensary, Duliajan Town'
            : 'ESIC Model Hospital, Tinsukia';

        String dbtStatus = 'SETTLED';
        String dbtTxnId = 'DBT-OIL-${DateFormat('yyyyMM').format(DateTime.now())}-${20000 + globalIndex}';

        int musterDays = 26;
        int biometricDays = 26;
        int otHours = (globalIndex % 4 == 0) ? 24 : ((globalIndex % 3 == 0) ? 16 : 0);
        double otMultiplier = 2.0;

        final issues = <String>[];

        if (paidWage < minWage) {
          issues.add('MIN_WAGE_BREACH');
        }

        // Specific non-compliance scenarios
        if (contractor == 'Brahmaputra Infra Projects') {
          // Brahmaputra Infra: 10 EPF KYC pending, 12 ESIC card gaps
          if (localIndex <= 10) {
            epfStatus = 'KYC_PENDING';
            issues.add('EPF_KYC_PENDING');
          }
          if (localIndex > 10 && localIndex <= 22) {
            esicStatus = 'SUBMITTED';
            issues.add('ESIC_PEHCHAN_GAP');
          }
          // Ghost attendance for 14 workers (each has 3 ghost days = 42 days)
          if (localIndex <= ghostWorkerLaborersCount) {
            biometricDays = 23; // Muster claimed 26, biometric logged 23
            issues.add('GHOST_MUSTER_DISCREPANCY');
          }
          // Cash advance violation for 8 workers
          if (localIndex <= cashPaymentLaborersCount) {
            dbtStatus = 'CASH_VIOLATION';
            dbtTxnId = 'MANUAL_CASH_VOUCHER_UNAUDITED';
            issues.add('CASH_PAYMENT_VIOLATION');
          }
          // Single rate OT violation
          if (otHours > 0) {
            otMultiplier = 1.0; // Paid 1x instead of statutory 2x!
            issues.add('OT_SINGLE_RATE_BREACH');
          }
        } else if (contractor == 'Duliajan Mech Fabricators') {
          // Duliajan Mech: 2 KYC pending, 3 ESIC pending, 3 workers with 2 ghost days = 6 ghost days
          if (localIndex <= 2) {
            epfStatus = 'KYC_PENDING';
            issues.add('EPF_KYC_PENDING');
          }
          if (localIndex > 2 && localIndex <= 5) {
            esicStatus = 'SUBMITTED';
            issues.add('ESIC_PEHCHAN_GAP');
          }
          if (localIndex <= ghostWorkerLaborersCount) {
            biometricDays = 24; // 2 ghost days each
            issues.add('GHOST_MUSTER_DISCREPANCY');
          }
        }

        list.add(
          LaborerAuditRecord(
            id: 'WRK-OIL-${1000 + globalIndex}',
            badgeNumber: badge,
            name: name,
            trade: trade,
            skillTier: tier,
            contractor: contractor,
            dailyWagePaid: paidWage,
            statutoryMinWage: minWage,
            epfUan: epfUan,
            epfStatus: epfStatus,
            epfTrrnRef: epfTrrn,
            esicIpNumber: esicIp,
            esicStatus: esicStatus,
            esicDispensary: esicDispensary,
            dbtStatus: dbtStatus,
            bankName: bank,
            bankAccountMasked: accMask,
            ifscCode: ifsc,
            dbtTxnId: dbtTxnId,
            musterRollDays: musterDays,
            biometricDays: biometricDays,
            overtimeHours: otHours,
            otMultiplierPaid: otMultiplier,
            complianceIssues: issues,
          ),
        );
      }
    }

    // 1. L&T Hydrocarbon Engineering: 92 laborers (100% compliant)
    addGroup(
      contractor: 'L&T Hydrocarbon Engineering',
      count: 92,
      skilledCount: 46,
      semiSkilledCount: 28,
      unskilledCount: 18,
      baseWageBonus: 35.0,
      hasBreaches: false,
      ghostWorkerLaborersCount: 0,
      cashPaymentLaborersCount: 0,
    );

    // 2. Brahmaputra Infra Projects: 68 laborers (high risk)
    addGroup(
      contractor: 'Brahmaputra Infra Projects',
      count: 68,
      skilledCount: 18,
      semiSkilledCount: 22,
      unskilledCount: 28,
      baseWageBonus: 0.0,
      hasBreaches: true,
      ghostWorkerLaborersCount: 14, // 14 * 3 = 42 ghost days!
      cashPaymentLaborersCount: 8,
    );

    // 3. Duliajan Mech Fabricators: 44 laborers (moderate risk)
    addGroup(
      contractor: 'Duliajan Mech Fabricators',
      count: 44,
      skilledCount: 24,
      semiSkilledCount: 14,
      unskilledCount: 6,
      baseWageBonus: 15.0,
      hasBreaches: true,
      ghostWorkerLaborersCount: 3, // 3 * 2 = 6 ghost days
      cashPaymentLaborersCount: 0,
    );

    // 4. Eastern Rigging & Logistics: 36 laborers (compliant)
    addGroup(
      contractor: 'Eastern Rigging & Logistics',
      count: 36,
      skilledCount: 12,
      semiSkilledCount: 16,
      unskilledCount: 8,
      baseWageBonus: 20.0,
      hasBreaches: false,
      ghostWorkerLaborersCount: 0,
      cashPaymentLaborersCount: 0,
    );

    // Total = 92 + 68 + 44 + 36 = exactly 240 active site laborers!
    return list;
  }

  // Filtered laborers getter
  List<LaborerAuditRecord> get _filteredLaborers {
    return _laborers.where((laborer) {
      if (_selectedContractorFilter != 'ALL' &&
          laborer.contractor != _selectedContractorFilter) {
        return false;
      }

      if (_selectedTierFilter != 'ALL' &&
          laborer.skillTier.label != _selectedTierFilter) {
        return false;
      }

      if (_selectedStatusFilter == 'VIOLATIONS_ONLY' && !laborer.hasAnyViolation) {
        return false;
      }
      if (_selectedStatusFilter == 'MIN_WAGE_BREACH' && laborer.isWageCompliant) {
        return false;
      }
      if (_selectedStatusFilter == 'EPF_ISSUES' && laborer.epfStatus == 'VERIFIED') {
        return false;
      }
      if (_selectedStatusFilter == 'ESIC_ISSUES' && laborer.esicStatus == 'ACTIVE') {
        return false;
      }
      if (_selectedStatusFilter == 'GHOST_DAYS' && !laborer.hasGhostAttendance) {
        return false;
      }
      if (_selectedStatusFilter == 'CASH_PAY' && laborer.dbtStatus != 'CASH_VIOLATION') {
        return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matches = laborer.name.toLowerCase().contains(q) ||
            laborer.badgeNumber.toLowerCase().contains(q) ||
            laborer.trade.toLowerCase().contains(q) ||
            laborer.epfUan.contains(q) ||
            laborer.esicIpNumber.contains(q) ||
            laborer.contractor.toLowerCase().contains(q);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  void _toggleWithholding(String contractorId) {
    setState(() {
      _contractors = _contractors.map((c) {
        if (c.id == contractorId) {
          final newStatus = !c.isRetentionWithheld;
          final newAmount = newStatus ? 6.85 : 0.0;
          return ContractorComplianceAudit(
            id: c.id,
            name: c.name,
            code: c.code,
            tradeDiscipline: c.tradeDiscipline,
            totalLaborers: c.totalLaborers,
            wageComplianceRate: c.wageComplianceRate,
            epfComplianceRate: c.epfComplianceRate,
            esicComplianceRate: c.esicComplianceRate,
            biometricMatchRate: c.biometricMatchRate,
            dbtComplianceRate: c.dbtComplianceRate,
            otReconciliationRate: c.otReconciliationRate,
            overallScore: c.overallScore,
            complianceGrade: c.complianceGrade,
            ghostDaysClaimed: c.ghostDaysClaimed,
            wageBreachCount: c.wageBreachCount,
            cashViolationCount: c.cashViolationCount,
            isRetentionWithheld: newStatus,
            withheldAmountLakhs: newAmount,
            activeNotices: c.activeNotices,
          );
        }
        return c;
      }).toList();
    });

    final contractor = _contractors.firstWhere((c) => c.id == contractorId);
    final msg = contractor.isRetentionWithheld
        ? 'FIDIC Cl. 14.6 Payment Withholding (15% - ₹${contractor.withheldAmountLakhs}L) APPLIED on ${contractor.name}'
        : 'Payment Withholding released for ${contractor.name}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: contractor.isRetentionWithheld
            ? const Color(0xFFFF6B6B)
            : const Color(0xFF4EDEA3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Wage & Statutory Compliance Audit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Assam Minimum Wages Act 2024 • EPF/ESIC • DBT Ledger • Subcontractor Audit',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export Statutory Audit Dossier',
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primaryLight),
            onPressed: _showExportAuditDialog,
          ),
          IconButton(
            tooltip: 'Assam Wage Calculator',
            icon: const Icon(Icons.calculate_outlined, color: AppTheme.secondary),
            onPressed: _showStatutoryCalculatorDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Statutory Overview'),
            Tab(text: 'EPF & ESIC (240 Laborers)'),
            Tab(text: 'Disbursement Ledger & OT 2x'),
            Tab(text: 'Contractor Scorecards & Notices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatutoryOverviewTab(),
          _buildEpfEsicRegistryTab(),
          _buildDisbursementLedgerTab(),
          _buildContractorsAndNoticesTab(),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: STATUTORY COMPLIANCE OVERVIEW (Assam Minimum Wages Act 2024)
  // ==========================================================================

  Widget _buildStatutoryOverviewTab() {
    final totalLaborers = _laborers.length;
    final wageCompliantCount = _laborers.where((l) => l.isWageCompliant).length;
    final epfActiveCount = _laborers.where((l) => l.epfStatus == 'VERIFIED').length;
    final esicActiveCount = _laborers.where((l) => l.esicStatus == 'ACTIVE').length;
    final dbtVerifiedCount = _laborers.where((l) => l.dbtStatus == 'SETTLED').length;
    final totalGhostDays = _laborers.fold<int>(0, (sum, l) => sum + (l.hasGhostAttendance ? l.attendanceDiscrepancy : 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAssamGazetteNoticeBanner(),
          const SizedBox(height: 16),
          _buildSiteExecutiveKpiGrid(
            totalLaborers: totalLaborers,
            wageCompliantCount: wageCompliantCount,
            epfActiveCount: epfActiveCount,
            esicActiveCount: esicActiveCount,
            dbtVerifiedCount: dbtVerifiedCount,
            totalGhostDays: totalGhostDays,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assam Statutory Wage Schedule (2024 Gazette)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withAlpha(100)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gavel, size: 14, color: AppTheme.primaryLight),
                    SizedBox(width: 4),
                    Text(
                      'GLR(RC)58/2023/Pt/14',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._statutoryStandards.map(_buildWageStandardCard),
          const SizedBox(height: 20),
          _buildQuickActionAuditRow(),
        ],
      ),
    );
  }

  Widget _buildAssamGazetteNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, color: AppTheme.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Govt. of Assam Labour Welfare Department',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Revised Minimum Wages Schedule for Engineering & Pipeline Works',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4EDEA3).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF4EDEA3).withAlpha(120)),
                ),
                child: const Text(
                  'MANDATORY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4EDEA3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),
          const Text(
            'Under Section 3 & 5(2) of the Minimum Wages Act 1948, no subcontractor or labour contractor operating on Oil India Trunk Crude Pipeline Expansion (OIL-PL-024) may disburse wages below the statutory basic + VDA rates. Overtime beyond 8 hours/day must be compensated at double (2.0x) base hourly wages under BOCW Act.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.shield_outlined, size: 14, color: AppTheme.primaryLight),
              SizedBox(width: 6),
              Text(
                'Jurisdiction: Tinsukia & Dibrugarh Districts, Assam State',
                style: TextStyle(fontSize: 11, color: AppTheme.primaryLight, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSiteExecutiveKpiGrid({
    required int totalLaborers,
    required int wageCompliantCount,
    required int epfActiveCount,
    required int esicActiveCount,
    required int dbtVerifiedCount,
    required int totalGhostDays,
  }) {
    final wagePct = ((wageCompliantCount / totalLaborers) * 100).toStringAsFixed(1);
    final epfPct = ((epfActiveCount / totalLaborers) * 100).toStringAsFixed(1);
    final esicPct = ((esicActiveCount / totalLaborers) * 100).toStringAsFixed(1);
    final dbtPct = ((dbtVerifiedCount / totalLaborers) * 100).toStringAsFixed(1);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Total Site Laborers',
                value: '$totalLaborers Active',
                subtitle: '4 Subcontractor Gangs',
                icon: Icons.groups_rounded,
                iconColor: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Assam Min Wage',
                value: '$wagePct%',
                subtitle: '$wageCompliantCount / $totalLaborers Compliant',
                icon: Icons.currency_rupee_rounded,
                iconColor: wageCompliantCount == totalLaborers
                    ? const Color(0xFF4EDEA3)
                    : const Color(0xFFFFB95F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'EPF UAN Seeded',
                value: '$epfPct%',
                subtitle: '$epfActiveCount / $totalLaborers Active',
                icon: Icons.badge_outlined,
                iconColor: const Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'ESIC Medical Cards',
                value: '$esicPct%',
                subtitle: '$esicActiveCount / $totalLaborers Issued',
                icon: Icons.medical_services_outlined,
                iconColor: const Color(0xFF4EDEA3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'DBT Bank Deposit',
                value: '$dbtPct%',
                subtitle: '$dbtVerifiedCount / $totalLaborers Verified',
                icon: Icons.account_balance_outlined,
                iconColor: const Color(0xFF818CF8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Ghost Man-Days',
                value: '$totalGhostDays Days',
                subtitle: '₹${(totalGhostDays * 380).toStringAsFixed(0)} Leakage Blocked',
                icon: Icons.warning_amber_rounded,
                iconColor: totalGhostDays > 0 ? const Color(0xFFFF6B6B) : const Color(0xFF4EDEA3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
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
                title,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildWageStandardCard(AssamStatutoryWageStandard standard) {
    final tierColor = standard.tier.color;
    final isFullCompliance = standard.compliantHeadcount == standard.activeHeadcount;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFullCompliance ? AppTheme.border : const Color(0xFFFFB95F).withAlpha(120),
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
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: tierColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    standard.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFullCompliance
                      ? const Color(0xFF4EDEA3).withAlpha(30)
                      : const Color(0xFFFF6B6B).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFullCompliance
                        ? const Color(0xFF4EDEA3).withAlpha(100)
                        : const Color(0xFFFF6B6B).withAlpha(100),
                  ),
                ),
                child: Text(
                  isFullCompliance
                      ? '100% COMPLIANT'
                      : '${standard.nonCompliantHeadcount} BREACHES DETECTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isFullCompliance
                        ? const Color(0xFF4EDEA3)
                        : const Color(0xFFFF6B6B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStandardMetricCol(
                  'Statutory Daily Floor',
                  '₹${standard.totalDailyWage.toStringAsFixed(2)}',
                  'Basic ₹${standard.basicDailyWage.toInt()} + VDA ₹${standard.vdaDaily.toInt()}',
                ),
              ),
              Expanded(
                child: _buildStandardMetricCol(
                  'Monthly Floor (26 Days)',
                  '₹${standard.monthlyWage26Days.toStringAsFixed(0)}',
                  'Assam 2024 Gazette',
                ),
              ),
              Expanded(
                child: _buildStandardMetricCol(
                  'Overtime (2.0x / Hour)',
                  '₹${standard.statutoryOtHourlyRate.toStringAsFixed(2)}/hr',
                  'BOCW Act Mandatory',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Sample Trades: ${standard.eligibleTrades.take(3).join(', ')}...',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Headcount: ${standard.compliantHeadcount} / ${standard.activeHeadcount} (${standard.complianceRate.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isFullCompliance ? AppTheme.textSecondary : const Color(0xFFFFB95F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandardMetricCol(String label, String value, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildQuickActionAuditRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Auditor Quick Operations',
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
                child: OutlinedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(3); // Switch to Contractors & Notices
                  },
                  icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFFF6B6B)),
                  label: const Text('Review Notices', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showExportAuditDialog,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export Audit Pack', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: EPF & ESIC VERIFICATION REGISTRY (240 Laborers)
  // ==========================================================================

  Widget _buildEpfEsicRegistryTab() {
    final filtered = _filteredLaborers;
    final epfVerified = _laborers.where((l) => l.epfStatus == 'VERIFIED').length;
    final epfPending = _laborers.where((l) => l.epfStatus == 'KYC_PENDING').length;
    final esicActive = _laborers.where((l) => l.esicStatus == 'ACTIVE').length;
    final esicPending = _laborers.where((l) => l.esicStatus == 'SUBMITTED').length;

    return Column(
      children: [
        // Top filter & search header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: AppTheme.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search by worker, badge, UAN, IP number...',
                        prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        fillColor: AppTheme.surfaceCard,
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedContractorFilter,
                      dropdownColor: AppTheme.surfaceCard,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                      items: [
                        'ALL',
                        'L&T Hydrocarbon Engineering',
                        'Brahmaputra Infra Projects',
                        'Duliajan Mech Fabricators',
                        'Eastern Rigging & Logistics',
                      ].map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            c == 'ALL' ? 'All Contractors' : c.split(' ').take(2).join(' '),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedContractorFilter = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All 240 Laborers', 'ALL'),
                    _buildFilterChip('Violations Only', 'VIOLATIONS_ONLY'),
                    _buildFilterChip('EPF Pending ($epfPending)', 'EPF_ISSUES'),
                    _buildFilterChip('ESIC Pending ($esicPending)', 'ESIC_ISSUES'),
                    _buildFilterChip('Wage Breaches', 'MIN_WAGE_BREACH'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quick status strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.surfaceContainerHigh.withAlpha(50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filtered.length} of ${_laborers.length} registered laborers',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Row(
                children: [
                  _buildStatDot('EPF: $epfVerified/240', const Color(0xFF4EDEA3)),
                  const SizedBox(width: 10),
                  _buildStatDot('ESIC: $esicActive/240', const Color(0xFF38BDF8)),
                ],
              ),
            ],
          ),
        ),

        // Laborers list
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No laborer records match filter query',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final laborer = filtered[index];
                    return _buildLaborerEpfEsicCard(laborer);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.textSecondary)),
        backgroundColor: AppTheme.surfaceCard,
        selectedColor: AppTheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.border),
        ),
        onSelected: (_) {
          setState(() => _selectedStatusFilter = value);
        },
      ),
    );
  }

  Widget _buildStatDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildLaborerEpfEsicCard(LaborerAuditRecord laborer) {
    final isEpfOk = laborer.epfStatus == 'VERIFIED';
    final isEsicOk = laborer.esicStatus == 'ACTIVE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: laborer.hasAnyViolation
              ? const Color(0xFFFF6B6B).withAlpha(120)
              : AppTheme.border,
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
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: laborer.skillTier.color.withAlpha(40),
                    child: Text(
                      laborer.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: laborer.skillTier.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            laborer.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              laborer.badgeNumber,
                              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${laborer.trade} • ${laborer.contractor.split(' ').take(2).join(' ')}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
                onPressed: () => _showLaborerDetailModal(laborer),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildEpfStatusPill(laborer.epfUan, isEpfOk, laborer.epfStatus),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEsicStatusPill(laborer.esicIpNumber, isEsicOk, laborer.esicStatus),
              ),
            ],
          ),
          if (laborer.complianceIssues.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: laborer.complianceIssues.map((issue) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFF6B6B).withAlpha(100)),
                  ),
                  child: Text(
                    issue.replaceAll('_', ' '),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEpfStatusPill(String uan, bool isOk, String status) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isOk ? const Color(0xFF4EDEA3).withAlpha(15) : const Color(0xFFFFB95F).withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOk ? const Color(0xFF4EDEA3).withAlpha(80) : const Color(0xFFFFB95F).withAlpha(100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOk ? Icons.check_circle : Icons.error_outline,
                size: 12,
                color: isOk ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F),
              ),
              const SizedBox(width: 4),
              Text(
                'EPF UAN ($status)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isOk ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            uan,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEsicStatusPill(String ip, bool isOk, String status) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isOk ? const Color(0xFF38BDF8).withAlpha(15) : const Color(0xFFFFB95F).withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOk ? const Color(0xFF38BDF8).withAlpha(80) : const Color(0xFFFFB95F).withAlpha(100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOk ? Icons.medical_services : Icons.access_time,
                size: 12,
                color: isOk ? const Color(0xFF38BDF8) : const Color(0xFFFFB95F),
              ),
              const SizedBox(width: 4),
              Text(
                'ESIC IP ($status)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isOk ? const Color(0xFF38BDF8) : const Color(0xFFFFB95F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            ip.length > 12 ? '${ip.substring(0, 4)}...${ip.substring(ip.length - 4)}' : ip,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: WAGE DISBURSEMENT LEDGER (DBT, Biometrics, OT 2x)
  // ==========================================================================

  Widget _buildDisbursementLedgerTab() {
    final filtered = _filteredLaborers;

    final totalGross = _laborers.fold<double>(0.0, (sum, l) => sum + l.totalGrossEarnings);
    final totalDbtDisbursed = _laborers.fold<double>(0.0, (sum, l) => sum + l.netDisbursed);
    final totalOtHours = _laborers.fold<int>(0, (sum, l) => sum + l.overtimeHours);

    return Column(
      children: [
        // Summary header strip
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Wage Disbursement & OT 2x Ledger',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Cycle: September 2026',
                    style: TextStyle(fontSize: 12, color: AppTheme.primaryLight, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildLedgerSummaryBox(
                      'Gross Wages Earned',
                      '₹${(totalGross / 100000).toStringAsFixed(2)}L',
                      '240 Active Laborers',
                      const Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLedgerSummaryBox(
                      'Net Disbursed (DBT)',
                      '₹${(totalDbtDisbursed / 100000).toStringAsFixed(2)}L',
                      'Bank Transfers',
                      const Color(0xFF4EDEA3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLedgerSummaryBox(
                      'Overtime Reconciled',
                      '$totalOtHours Hours',
                      'Mandatory 2.0x Rate',
                      const Color(0xFFFFB95F),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Sub-filter tabs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.surfaceCard,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All 240 Records', 'ALL'),
                _buildFilterChip('Muster vs Biometric Discrepancy', 'GHOST_DAYS'),
                _buildFilterChip('Cash Advance Breach', 'CASH_PAY'),
                _buildFilterChip('Wage Underpayment', 'MIN_WAGE_BREACH'),
              ],
            ),
          ),
        ),

        // Ledger list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final laborer = filtered[index];
              return _buildLedgerCard(laborer);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerSummaryBox(String title, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildLedgerCard(LaborerAuditRecord laborer) {
    final hasGhost = laborer.hasGhostAttendance;
    final isCashViolation = laborer.dbtStatus == 'CASH_VIOLATION';
    final isOtBreach = !laborer.isOtCompliant && laborer.overtimeHours > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (hasGhost || isCashViolation || isOtBreach || !laborer.isWageCompliant)
              ? const Color(0xFFFF6B6B).withAlpha(120)
              : AppTheme.border,
        ),
      ),
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
                      laborer.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${laborer.trade} • ${laborer.contractor}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${laborer.netDisbursed.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4EDEA3),
                    ),
                  ),
                  const Text('Net Disbursed', style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 10),

          // Muster Roll vs Biometric comparison row
          Row(
            children: [
              Expanded(
                child: _buildLedgerMetric(
                  'Muster Claim vs Biometric',
                  '${laborer.musterRollDays}d Claimed / ${laborer.biometricDays}d Verified',
                  hasGhost
                      ? '+${laborer.attendanceDiscrepancy} Ghost Days Flagged!'
                      : '100% Turnstile Match',
                  hasGhost ? const Color(0xFFFF6B6B) : const Color(0xFF4EDEA3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLedgerMetric(
                  'Overtime Reconciliation',
                  '${laborer.overtimeHours} hrs @ ${laborer.otMultiplierPaid}x rate',
                  isOtBreach ? 'Underpaid: 1.0x single rate breach!' : 'Statutory 2.0x Reconciled',
                  isOtBreach ? const Color(0xFFFF6B6B) : AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // DBT status row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCashViolation
                  ? const Color(0xFFFF6B6B).withAlpha(20)
                  : const Color(0xFF4EDEA3).withAlpha(15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCashViolation
                    ? const Color(0xFFFF6B6B).withAlpha(80)
                    : const Color(0xFF4EDEA3).withAlpha(60),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isCashViolation ? Icons.money_off : Icons.check_circle_outline,
                      size: 14,
                      color: isCashViolation ? const Color(0xFFFF6B6B) : const Color(0xFF4EDEA3),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCashViolation
                          ? 'Cash Advance Violation (§6 Breach)'
                          : 'DBT Direct Deposit: ${laborer.bankName}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCashViolation ? const Color(0xFFFF6B6B) : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  laborer.bankAccountMasked,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerMetric(String label, String main, String sub, Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(
          main,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 1),
        Text(
          sub,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 4: CONTRACTOR SCORECARDS & WARNING NOTICES
  // ==========================================================================

  Widget _buildContractorsAndNoticesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Labour Contractor Compliance Scorecard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                tooltip: 'Draft Show Cause Notice',
                icon: const Icon(Icons.add_alert_rounded, color: Color(0xFFFF6B6B)),
                onPressed: _showDraftNoticeDialog,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Audited against Minimum Wages Act, EPF/ESIC ECR Challans, and Biometric logs.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ..._contractors.map(_buildContractorScorecardCard),
          const SizedBox(height: 24),
          Row(
            children: const [
              Icon(Icons.gavel, size: 18, color: Color(0xFFFF6B6B)),
              SizedBox(width: 8),
              Text(
                'Active Statutory Show Cause & Cure Notices',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._warningNotices.map(_buildNoticeCard),
        ],
      ),
    );
  }

  Widget _buildContractorScorecardCard(ContractorComplianceAudit contractor) {
    final gradeColor = contractor.gradeColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: contractor.isRetentionWithheld
              ? const Color(0xFFFF6B6B)
              : AppTheme.border,
          width: contractor.isRetentionWithheld ? 1.5 : 1.0,
        ),
      ),
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
                      contractor.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${contractor.tradeDiscipline} • ${contractor.totalLaborers} Laborers',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gradeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: gradeColor.withAlpha(100)),
                ),
                child: Text(
                  '${contractor.overallScore.toStringAsFixed(1)} / 100 • ${contractor.complianceGrade}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),

          // Compliance Progress Bars
          _buildScoreRow('Assam Minimum Wage Compliance', contractor.wageComplianceRate),
          const SizedBox(height: 8),
          _buildScoreRow('EPF UAN Seeded Rate', contractor.epfComplianceRate),
          const SizedBox(height: 8),
          _buildScoreRow('ESIC Medical Card Issuance', contractor.esicComplianceRate),
          const SizedBox(height: 8),
          _buildScoreRow('Biometric vs Muster Roll Match', contractor.biometricMatchRate),
          const SizedBox(height: 8),
          _buildScoreRow('Direct Bank Transfer (DBT) Rate', contractor.dbtComplianceRate),
          const SizedBox(height: 8),
          _buildScoreRow('Overtime 2.0x Statutory Multiplier', contractor.otReconciliationRate),
          const SizedBox(height: 14),

          // Action controls & Retention toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (contractor.isRetentionWithheld)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFF6B6B).withAlpha(120)),
                  ),
                  child: Text(
                    'FIDIC 14.6 Retention Withheld: ₹${contractor.withheldAmountLakhs}L',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                )
              else
                const Text(
                  'Zero Payment Withholding',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              Row(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      side: BorderSide(
                        color: contractor.isRetentionWithheld
                            ? const Color(0xFF4EDEA3)
                            : const Color(0xFFFF6B6B),
                      ),
                    ),
                    onPressed: () => _toggleWithholding(contractor.id),
                    child: Text(
                      contractor.isRetentionWithheld ? 'Release Retention' : 'Withhold Cl. 14.6 (15%)',
                      style: TextStyle(
                        fontSize: 11,
                        color: contractor.isRetentionWithheld
                            ? const Color(0xFF4EDEA3)
                            : const Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, double rate) {
    Color barColor = const Color(0xFF4EDEA3);
    if (rate < 90.0) {
      barColor = const Color(0xFFFF6B6B);
    } else if (rate < 98.0) {
      barColor = const Color(0xFFFFB95F);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: barColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: rate / 100.0,
            backgroundColor: AppTheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeCard(StatutoryWarningNotice notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B6B).withAlpha(140)),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning, color: Color(0xFFFF6B6B), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.noticeId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B6B),
                        ),
                      ),
                      Text(
                        notice.contractorName,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFF6B6B).withAlpha(100)),
                ),
                child: Text(
                  notice.noticeType,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notice.summary,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh.withAlpha(80),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: notice.specificViolations.map((v) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          v,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cure Deadline: ${notice.cureDeadline}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFFB95F)),
              ),
              TextButton(
                onPressed: () => _showFullNoticeModal(notice),
                child: const Text('View Formal Notice (FIDIC/BOCW)', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // MODALS & DIALOGS
  // ==========================================================================

  void _showLaborerDetailModal(LaborerAuditRecord laborer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        laborer.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${laborer.badgeNumber} • ${laborer.trade} • ${laborer.contractor}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 16),

              // Statutory Wage Audit
              _buildDetailRow('Statutory Minimum Wage Floor', '₹${laborer.statutoryMinWage.toStringAsFixed(2)} / day'),
              _buildDetailRow('Contractor Daily Disbursed Rate', '₹${laborer.dailyWagePaid.toStringAsFixed(2)} / day'),
              _buildDetailRow(
                'Wage Floor Compliance',
                laborer.isWageCompliant ? 'COMPLIANT (Meets Assam 2024 Schedule)' : 'BREACH: Deficit of ₹${laborer.wageDeficit.toStringAsFixed(2)}/day',
                valueColor: laborer.isWageCompliant ? const Color(0xFF4EDEA3) : const Color(0xFFFF6B6B),
              ),
              const SizedBox(height: 12),

              // EPF & ESIC Records
              _buildDetailRow('EPF Universal Account Number (UAN)', laborer.epfUan),
              _buildDetailRow('EPF Status & ECR Challan TRRN', '${laborer.epfStatus} (${laborer.epfTrrnRef})'),
              _buildDetailRow('ESIC Insurance Person (IP) No.', laborer.esicIpNumber),
              _buildDetailRow('ESIC Designated Medical Dispensary', laborer.esicDispensary),
              const SizedBox(height: 12),

              // Attendance & DBT
              _buildDetailRow('Muster Roll vs Biometric Turnstile', '${laborer.musterRollDays} Days Claimed / ${laborer.biometricDays} Days Logged'),
              _buildDetailRow('Overtime Logged & Reconciled', '${laborer.overtimeHours} Hours @ ${laborer.otMultiplierPaid}x Multiplier'),
              _buildDetailRow('DBT Direct Bank Transfer Txn ID', laborer.dbtTxnId),
              _buildDetailRow('Direct Bank Account', '${laborer.bankName} (${laborer.bankAccountMasked}) • IFSC: ${laborer.ifscCode}'),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Exporting Certified Form XVII Wage Slip for ${laborer.name}...'),
                        backgroundColor: const Color(0xFF162347),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('Export Form XVII Wage Slip & Biometric Log'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullNoticeModal(StatutoryWarningNotice notice) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.gavel, color: Color(0xFFFF6B6B)),
              const SizedBox(width: 8),
              Text(
                notice.noticeId,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('TO: ${notice.contractorName}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text('STATUTE: ${notice.legalStatute}', style: const TextStyle(fontSize: 11, color: AppTheme.primaryLight)),
                const SizedBox(height: 12),
                const Text(
                  'TAKE NOTICE that upon formal inspection of September 2026 payroll records, the following statutory non-compliance violations have been documented on the Oil India Pipeline Project (OIL-PL-024):',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 10),
                ...notice.specificViolations.map((v) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $v', style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                    )),
                const SizedBox(height: 12),
                Text(
                  'YOU ARE HEREBY REQUIRED to pay all statutory wage arrears through Direct Bank Transfer (DBT) and cure biometric muster roll discrepancies by ${notice.cureDeadline}. Failure to comply will result in withholding 15% under FIDIC Clause 14.6 and blacklisting recommendation.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFFF6B6B), height: 1.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'ISSUED BY: ${notice.issuedBy}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Notice ${notice.noticeId} dispatched to ${notice.contractorName} and Regional Labour Commissioner'),
                    backgroundColor: const Color(0xFF162347),
                  ),
                );
              },
              icon: const Icon(Icons.send, size: 14),
              label: const Text('Dispatch Copy to Labour Dept'),
            ),
          ],
        );
      },
    );
  }

  void _showDraftNoticeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text('Draft Statutory Notice', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          content: const Text(
            'Select subcontractor to generate an automated 48-Hour Statutory Cure Notice under Minimum Wages Act §20 and Contract Labour Act §21.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notice generator opened for active subcontractors'),
                    backgroundColor: Color(0xFF162347),
                  ),
                );
              },
              child: const Text('Proceed to Draft'),
            ),
          ],
        );
      },
    );
  }

  void _showStatutoryCalculatorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text('Assam Minimum Wage 2024 Calculator', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('• Skilled: ₹540/day (Basic ₹415 + VDA ₹125) • OT: ₹135/hr', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
              SizedBox(height: 6),
              Text('• Semi-Skilled: ₹450/day (Basic ₹350 + VDA ₹100) • OT: ₹112.50/hr', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
              SizedBox(height: 6),
              Text('• Unskilled: ₹380/day (Basic ₹300 + VDA ₹80) • OT: ₹95/hr', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
              SizedBox(height: 12),
              Text('Statutory Deductions:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
              Text('• Employee EPF: 12% of Basic Wages\n• Employee ESIC: 0.75% of Gross Wages\n• Employer EPF: 12% (3.67% EPF + 8.33% EPS)\n• Employer ESIC: 3.25% of Gross Wages',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        );
      },
    );
  }

  void _showExportAuditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text('Export Statutory Compliance Dossier', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('The generated statutory audit pack includes:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              SizedBox(height: 8),
              Text('1. Form D & Form XVII Muster Roll Reconciliation Ledger', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
              Text('2. Direct Bank Transfer (DBT) NEFT/PFMS Bank Proofs', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
              Text('3. EPF ECR Challan TRRN & UAN Aadhaar Seeding Register', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
              Text('4. ESIC Form 5 Contribution & Pehchan Card Matrix', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
              Text('5. Statutory Show Cause Notice Ref SCN-OIL-2026-04 Copy', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Downloading Statutory_Wage_Compliance_Audit_OIL_PL_024.pdf (4.8 MB)...'),
                    backgroundColor: Color(0xFF162347),
                  ),
                );
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download Dossier (PDF)'),
            ),
          ],
        );
      },
    );
  }
}
