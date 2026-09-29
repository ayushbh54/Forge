import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../diary/site_diary_screen.dart';
import '../weather/weather_impact_screen.dart';

// ============================================================================
// DATA MODELS & ENUMS
// ============================================================================

/// 5-Stage FIDIC Clause 20 Dispute Resolution Workflow
enum DabWorkflowStage {
  noticeServed,
  dabReferral,
  hearingScheduled,
  amicableSettlement,
  decisionRendered;

  String get label {
    switch (this) {
      case DabWorkflowStage.noticeServed:
        return 'Notice Served';
      case DabWorkflowStage.dabReferral:
        return 'DAB Referral';
      case DabWorkflowStage.hearingScheduled:
        return 'Hearing Scheduled';
      case DabWorkflowStage.amicableSettlement:
        return 'Amicable Settlement';
      case DabWorkflowStage.decisionRendered:
        return 'DAB Decision Rendered';
    }
  }

  String get shortLabel {
    switch (this) {
      case DabWorkflowStage.noticeServed:
        return 'Notice';
      case DabWorkflowStage.dabReferral:
        return 'Referral';
      case DabWorkflowStage.hearingScheduled:
        return 'Hearing';
      case DabWorkflowStage.amicableSettlement:
        return 'Settlement';
      case DabWorkflowStage.decisionRendered:
        return 'Decision';
    }
  }

  int get stepIndex {
    switch (this) {
      case DabWorkflowStage.noticeServed:
        return 0;
      case DabWorkflowStage.dabReferral:
        return 1;
      case DabWorkflowStage.hearingScheduled:
        return 2;
      case DabWorkflowStage.amicableSettlement:
        return 3;
      case DabWorkflowStage.decisionRendered:
        return 4;
    }
  }

  Color get color {
    switch (this) {
      case DabWorkflowStage.noticeServed:
        return const Color(0xFF38BDF8); // Primary Light / Cyan
      case DabWorkflowStage.dabReferral:
        return const Color(0xFFFFB95F); // Amber / Secondary
      case DabWorkflowStage.hearingScheduled:
        return const Color(0xFFA78BFA); // Purple
      case DabWorkflowStage.amicableSettlement:
        return const Color(0xFFFB923C); // Orange
      case DabWorkflowStage.decisionRendered:
        return const Color(0xFF4EDEA3); // Tertiary Green
    }
  }

  IconData get icon {
    switch (this) {
      case DabWorkflowStage.noticeServed:
        return Icons.mark_email_read_rounded;
      case DabWorkflowStage.dabReferral:
        return Icons.send_and_archive_rounded;
      case DabWorkflowStage.hearingScheduled:
        return Icons.gavel_rounded;
      case DabWorkflowStage.amicableSettlement:
        return Icons.handshake_rounded;
      case DabWorkflowStage.decisionRendered:
        return Icons.verified_rounded;
    }
  }
}

/// Evidentiary classification categories for Claim Dossier Builder
enum EvidenceCategory {
  delayEvent,
  weatherStoppage,
  siteDiary,
  costVoucher,
  statutoryNotice;

  String get label {
    switch (this) {
      case EvidenceCategory.delayEvent:
        return 'Delay Event Evidence';
      case EvidenceCategory.weatherStoppage:
        return 'Weather Stoppage Log';
      case EvidenceCategory.siteDiary:
        return 'Contemporaneous Diary';
      case EvidenceCategory.costVoucher:
        return 'Cost & Invoicing Voucher';
      case EvidenceCategory.statutoryNotice:
        return 'Statutory Notice';
    }
  }

  Color get color {
    switch (this) {
      case EvidenceCategory.delayEvent:
        return const Color(0xFF38BDF8);
      case EvidenceCategory.weatherStoppage:
        return const Color(0xFF00E5FF);
      case EvidenceCategory.siteDiary:
        return const Color(0xFFFFB95F);
      case EvidenceCategory.costVoucher:
        return const Color(0xFF4EDEA3);
      case EvidenceCategory.statutoryNotice:
        return const Color(0xFFA78BFA);
    }
  }

  IconData get icon {
    switch (this) {
      case EvidenceCategory.delayEvent:
        return Icons.event_busy_rounded;
      case EvidenceCategory.weatherStoppage:
        return Icons.thunderstorm_rounded;
      case EvidenceCategory.siteDiary:
        return Icons.menu_book_rounded;
      case EvidenceCategory.costVoucher:
        return Icons.receipt_long_rounded;
      case EvidenceCategory.statutoryNotice:
        return Icons.verified_user_rounded;
    }
  }
}

/// Single documentary or technical evidence artifact
class EvidenceItem {
  final String id;
  final String title;
  final EvidenceCategory category;
  final String fileType;
  final String fileSize;
  final String date;
  final String referenceNumber;
  final String verifiedBy;
  final String description;
  final String sha256Hash;

  const EvidenceItem({
    required this.id,
    required this.title,
    required this.category,
    required this.fileType,
    required this.fileSize,
    required this.date,
    required this.referenceNumber,
    required this.verifiedBy,
    required this.description,
    required this.sha256Hash,
  });
}

/// Telemetric Weather Stoppage Log linkage
class WeatherStoppageRecord {
  final String id;
  final String date;
  final String station;
  final double rainfallMm;
  final double windSpeedKmph;
  final String waterLevelM;
  final int hoursLost;
  final String severity;
  final String workStopped;

  const WeatherStoppageRecord({
    required this.id,
    required this.date,
    required this.station,
    required this.rainfallMm,
    required this.windSpeedKmph,
    required this.waterLevelM,
    required this.hoursLost,
    required this.severity,
    required this.workStopped,
  });
}

/// Contemporaneous Site Diary Record linkage under FIDIC Sub-Clause 4.20
class SiteDiaryReferenceRecord {
  final String id;
  final String dprNumber;
  final String date;
  final String chainage;
  final String recordedHindrance;
  final String idleMachinery;
  final int idleLabourCount;
  final String siteEngineerSignature;

  const SiteDiaryReferenceRecord({
    required this.id,
    required this.dprNumber,
    required this.date,
    required this.chainage,
    required this.recordedHindrance,
    required this.idleMachinery,
    required this.idleLabourCount,
    required this.siteEngineerSignature,
  });
}

/// Primary FIDIC Clause 20 Dispute & Claim Entity
class DabClaimModel {
  final String id;
  final String title;
  final String clauseReference;
  final double amountClaimedCr;
  final double? amountAwardedCr;
  final int eotRequestedDays;
  final int? eotAwardedDays;
  final DabWorkflowStage status;
  final String noticeDate;
  final int noticeDayElapsed;
  final int noticeTimeBarDaysRemaining;
  final String detailedSubmissionDeadline;
  final String workPackage;
  final String chainageLocation;
  final String contractorJV;
  final String clientEmployer;
  final String engineer;
  final String scopeSummary;
  final List<String> dabPanel;
  final String? hearingDetails;
  final String? decisionDate;
  final String? decisionRuling;
  final Map<String, double> costBreakdown;
  final List<EvidenceItem> evidenceList;
  final List<WeatherStoppageRecord> weatherLogs;
  final List<SiteDiaryReferenceRecord> siteDiaryRefs;
  final double evidenceCoverageScore;

  const DabClaimModel({
    required this.id,
    required this.title,
    required this.clauseReference,
    required this.amountClaimedCr,
    this.amountAwardedCr,
    required this.eotRequestedDays,
    this.eotAwardedDays,
    required this.status,
    required this.noticeDate,
    required this.noticeDayElapsed,
    required this.noticeTimeBarDaysRemaining,
    required this.detailedSubmissionDeadline,
    required this.workPackage,
    required this.chainageLocation,
    required this.contractorJV,
    required this.clientEmployer,
    required this.engineer,
    required this.scopeSummary,
    required this.dabPanel,
    this.hearingDetails,
    this.decisionDate,
    this.decisionRuling,
    required this.costBreakdown,
    required this.evidenceList,
    required this.weatherLogs,
    required this.siteDiaryRefs,
    required this.evidenceCoverageScore,
  });

  String get formattedClaimedCost => '₹${amountClaimedCr.toStringAsFixed(2)} Cr';
  String get formattedAwardedCost => amountAwardedCr != null
      ? '₹${amountAwardedCr!.toStringAsFixed(2)} Cr'
      : 'Pending Ruling';
  String get formattedRequestedEot => '+$eotRequestedDays Days';
  String get formattedAwardedEot =>
      eotAwardedDays != null ? '+$eotAwardedDays Days' : 'Pending Ruling';

  bool get isDecided => status == DabWorkflowStage.decisionRendered;
  bool get isSettled => status == DabWorkflowStage.amicableSettlement;
  bool get isHearing => status == DabWorkflowStage.hearingScheduled;
  bool get isReferred => status == DabWorkflowStage.dabReferral;
  bool get isNoticeOnly => status == DabWorkflowStage.noticeServed;

  DabClaimModel copyWith({
    String? id,
    String? title,
    String? clauseReference,
    double? amountClaimedCr,
    double? amountAwardedCr,
    int? eotRequestedDays,
    int? eotAwardedDays,
    DabWorkflowStage? status,
    String? noticeDate,
    int? noticeDayElapsed,
    int? noticeTimeBarDaysRemaining,
    String? detailedSubmissionDeadline,
    String? workPackage,
    String? chainageLocation,
    String? contractorJV,
    String? clientEmployer,
    String? engineer,
    String? scopeSummary,
    List<String>? dabPanel,
    String? hearingDetails,
    String? decisionDate,
    String? decisionRuling,
    Map<String, double>? costBreakdown,
    List<EvidenceItem>? evidenceList,
    List<WeatherStoppageRecord>? weatherLogs,
    List<SiteDiaryReferenceRecord>? siteDiaryRefs,
    double? evidenceCoverageScore,
  }) {
    return DabClaimModel(
      id: id ?? this.id,
      title: title ?? this.title,
      clauseReference: clauseReference ?? this.clauseReference,
      amountClaimedCr: amountClaimedCr ?? this.amountClaimedCr,
      amountAwardedCr: amountAwardedCr ?? this.amountAwardedCr,
      eotRequestedDays: eotRequestedDays ?? this.eotRequestedDays,
      eotAwardedDays: eotAwardedDays ?? this.eotAwardedDays,
      status: status ?? this.status,
      noticeDate: noticeDate ?? this.noticeDate,
      noticeDayElapsed: noticeDayElapsed ?? this.noticeDayElapsed,
      noticeTimeBarDaysRemaining:
          noticeTimeBarDaysRemaining ?? this.noticeTimeBarDaysRemaining,
      detailedSubmissionDeadline:
          detailedSubmissionDeadline ?? this.detailedSubmissionDeadline,
      workPackage: workPackage ?? this.workPackage,
      chainageLocation: chainageLocation ?? this.chainageLocation,
      contractorJV: contractorJV ?? this.contractorJV,
      clientEmployer: clientEmployer ?? this.clientEmployer,
      engineer: engineer ?? this.engineer,
      scopeSummary: scopeSummary ?? this.scopeSummary,
      dabPanel: dabPanel ?? this.dabPanel,
      hearingDetails: hearingDetails ?? this.hearingDetails,
      decisionDate: decisionDate ?? this.decisionDate,
      decisionRuling: decisionRuling ?? this.decisionRuling,
      costBreakdown: costBreakdown ?? this.costBreakdown,
      evidenceList: evidenceList ?? this.evidenceList,
      weatherLogs: weatherLogs ?? this.weatherLogs,
      siteDiaryRefs: siteDiaryRefs ?? this.siteDiaryRefs,
      evidenceCoverageScore:
          evidenceCoverageScore ?? this.evidenceCoverageScore,
    );
  }
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

/// FIDIC Clause 20 Dispute Adjudication Board (DAB) & Arbitration Claims Screen
class DisputeAdjudicationScreen extends StatefulWidget {
  const DisputeAdjudicationScreen({super.key});

  @override
  State<DisputeAdjudicationScreen> createState() =>
      _DisputeAdjudicationScreenState();
}

class _DisputeAdjudicationScreenState extends State<DisputeAdjudicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filters for Claims Register
  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL';
  final String _sortBy = 'ID_ASC'; // ID_ASC, AMOUNT_DESC, EOT_DESC
  final Set<String> _expandedClaimCards = {'CLM-2026-01', 'CLM-2026-04'};

  // Selected claim for Dossier Builder tab
  String _selectedDossierClaimId = 'CLM-2026-01';
  String _dossierEvidenceFilter = 'ALL';

  // FIDIC Cl. 14.8 Delayed Payment Interest Calculator State
  double _calculatorPrincipalCr = 14.20; // in ₹ Cr
  double _benchmarkRatePercentage = 6.50; // RBI Repo Rate
  static const double _fidicStatutoryMargin = 3.00; // FIDIC Cl. 14.8 margin
  DateTime _paymentDueDate = DateTime(2026, 4, 18); // Cl. 14.7 56-day due date
  DateTime _actualSettlementDate = DateTime(2026, 7, 1); // 74 days delayed
  String _selectedIpcPreset = 'IPC #14 (Moran Civil)';

  // Baseline Claims Register (CLM-2026-01 through CLM-2026-04)
  late List<DabClaimModel> _claims;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeClaimsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeClaimsData() {
    _claims = [
      // -----------------------------------------------------------------------
      // CLM-2026-01: Moran-Naharkatiya Spur Line Right-of-Way Handover
      // -----------------------------------------------------------------------
      const DabClaimModel(
        id: 'CLM-2026-01',
        title: 'Delayed Right-of-Way Handover at Moran-Naharkatiya spur line',
        clauseReference: 'FIDIC Cl. 20.1 (Notice within 28 days) & Cl. 2.1 (Right of Access)',
        amountClaimedCr: 18.40,
        amountAwardedCr: 14.85,
        eotRequestedDays: 45,
        eotAwardedDays: 38,
        status: DabWorkflowStage.decisionRendered,
        noticeDate: '12 Feb 2026',
        noticeDayElapsed: 16,
        noticeTimeBarDaysRemaining: 12,
        detailedSubmissionDeadline: '26 Mar 2026',
        workPackage: 'WP-01 Mainline Trenching & Cross-Country Spread',
        chainageLocation: 'Ch 18+200 to 32+400 (Moran-Naharkatiya Spur)',
        contractorJV: 'L&T Hydrocarbon Engineering JV',
        clientEmployer: 'Oil India Limited (OIL)',
        engineer: 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
        scopeSummary:
            'Severe right-of-way obstruction due to unacquired private tea estate parcels and delayed statutory clearance from local revenue authorities. Contractor\'s horizontal directional drilling (HDD) rig, automated double-joint welding spread, and 45-ton pipelayers stood idle for 45 calendar days.',
        dabPanel: [
          'Justice (Retd.) B. N. Srikrishna (Presiding Adjudicator)',
          'Dr. S. Mukherjee, FICE (Technical Member)',
          'Er. K. V. Ramanathan, FCIArb (Contracts Member)',
        ],
        hearingDetails:
            'Formal evidentiary hearings conducted 18-20 May 2026 at Guwahati International Arbitration Centre.',
        decisionDate: '28 Jun 2026',
        decisionRuling:
            'DAB ruling issued unanimously: Contractor entitled under FIDIC Cl. 2.1 & 20.1 to ₹14.85 Cr financial compensation (machinery standby + fixed site overheads) and 38 calendar days Extension of Time (EOT). Employer instruction to issue revised Taking-Over milestone.',
        costBreakdown: {
          'Heavy Plant Standing Charges (2x HDD Rigs, 4x Pipelayers)': 8.20,
          'Stranded Workforce & Technical Specialists Holding': 4.10,
          'Extended Site Camp Overheads & Equipment Insurances': 3.40,
          'Financing Charges (FIDIC Cl. 14.8 delayed certification)': 2.70,
        },
        evidenceCoverageScore: 96.5,
        evidenceList: [
          EvidenceItem(
            id: 'EVD-01-A',
            title: 'Revenue Dept ROW Hindrance Notice & Joint Survey Map',
            category: EvidenceCategory.delayEvent,
            fileType: 'PDF',
            fileSize: '6.4 MB',
            date: '14 Feb 2026',
            referenceNumber: 'OIL/SURV/ROW/MN-884',
            verifiedBy: 'Er. R. Sharma (Chief Land Acquisition Officer)',
            description:
                'Official cadastral survey demarcating 14.2 km unacquired private tea garden boundary holding up trench excavation.',
            sha256Hash: '9a4f2187b415ce3818e9a1120f28e19034c56891ab04e578c772e612984efb31',
          ),
          EvidenceItem(
            id: 'EVD-01-B',
            title: 'Cl. 20.1 Formal 28-Day Notice of Claim Transmittal Receipt',
            category: EvidenceCategory.statutoryNotice,
            fileType: 'PDF',
            fileSize: '1.2 MB',
            date: '12 Feb 2026',
            referenceNumber: 'LT/OIL/CLM-01/NOT-01',
            verifiedBy: 'Marcus Vance, P.E. (Engineer Receipt Stamp)',
            description:
                'Statutory notice served on Day 16 of hindrance occurrence; fully compliant with FIDIC 28-day limitation condition precedent.',
            sha256Hash: '7c89f131a9809cb8d927164ea511c97a8291df130a845112e4bf88091ecf15aa',
          ),
          EvidenceItem(
            id: 'EVD-01-C',
            title: 'Machinery Idling GPS Telematics & Standby Logbook',
            category: EvidenceCategory.costVoucher,
            fileType: 'CSV',
            fileSize: '4.8 MB',
            date: '28 Feb 2026',
            referenceNumber: 'TELEM/CAT/STANDBY/0226',
            verifiedBy: 'A. Sen (Plant & Machinery Superintendent)',
            description:
                'Raw CAN-bus telematics confirming 0 engine RPM operational hours across 6 heavy pipeline equipment units over 45 days.',
            sha256Hash: '3e110cb8971af1829eec014bca889218ff901235a8bc7712399dfa8710238bcd',
          ),
          EvidenceItem(
            id: 'EVD-01-D',
            title: 'FIDIC Cl. 14.8 Delayed Payment Interest Assessment Sheet',
            category: EvidenceCategory.costVoucher,
            fileType: 'XLSX',
            fileSize: '2.1 MB',
            date: '15 Mar 2026',
            referenceNumber: 'FIN/INT/14.8/CLM-01',
            verifiedBy: 'P. K. Ghosh (Lead Commercial Manager)',
            description:
                'Compounded monthly financing charges on unpaid IPC #12 certified balance at RBI Repo + 3.00% statutory margin.',
            sha256Hash: '4f29a0bc881920da771648bc0192e478512fa90123cbef987102941235481a02',
          ),
        ],
        weatherLogs: [
          WeatherStoppageRecord(
            id: 'WTR-01-1',
            date: '18 Feb 2026',
            station: 'IMD Moran AWS-04',
            rainfallMm: 38.5,
            windSpeedKmph: 24.0,
            waterLevelM: '101.4m MSL (+1.2m)',
            hoursLost: 10,
            severity: 'Moderate Rain & Soft Strata',
            workStopped: 'Corridor Grading & Equipment Access',
          ),
        ],
        siteDiaryRefs: [
          SiteDiaryReferenceRecord(
            id: 'SD-2026-0214',
            dprNumber: 'DPR-2026-045',
            date: '14 Feb 2026',
            chainage: 'Ch 22+100',
            recordedHindrance: 'Landowner fence blocking spread access; police escort requested',
            idleMachinery: '2x CAT 336 Excavators, 1x Vermeer D330 HDD Rig',
            idleLabourCount: 48,
            siteEngineerSignature: 'Vikram Joshi (Field Operations)',
          ),
          SiteDiaryReferenceRecord(
            id: 'SD-2026-0220',
            dprNumber: 'DPR-2026-051',
            date: '20 Feb 2026',
            chainage: 'Ch 24+800',
            recordedHindrance: 'ROW still obstructed; machinery standing idle on standby rate',
            idleMachinery: '3x CAT 336 Excavators, 2x Vermeer HDD Rigs, 4x Pipe Layers',
            idleLabourCount: 62,
            siteEngineerSignature: 'Vikram Joshi (Field Operations)',
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      // CLM-2026-02: Exceptional Monsoon Inundation & Basin Flash Floods
      // -----------------------------------------------------------------------
      const DabClaimModel(
        id: 'CLM-2026-02',
        title: 'Exceptional Monsoon Inundation & Brahmaputra Basin Flash Floods',
        clauseReference: 'FIDIC Cl. 20.1 (Notice within 28 days) & Cl. 8.4(c) / Cl. 19.1',
        amountClaimedCr: 9.65,
        amountAwardedCr: 7.20,
        eotRequestedDays: 32,
        eotAwardedDays: 26,
        status: DabWorkflowStage.amicableSettlement,
        noticeDate: '28 May 2026',
        noticeDayElapsed: 8,
        noticeTimeBarDaysRemaining: 20,
        detailedSubmissionDeadline: '09 Jul 2026',
        workPackage: 'WP-03 Trenching & River HDD Crossing',
        chainageLocation: 'KM 74+100 to 89+500 (Dihing Floodplain Corridor)',
        contractorJV: 'Punj Lloyd Piping JV',
        clientEmployer: 'Oil India Limited (OIL)',
        engineer: 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
        scopeSummary:
            'Unprecedented monsoon deluge exceeding 100-year return period records (342mm in 48 hours). Breach of peripheral flood bund submerged active trench excavations, washed away pipe padding, damaged geotextile mats, and submerged 14 pre-welded pipeline strings.',
        dabPanel: [
          'Justice (Retd.) B. N. Srikrishna (Presiding Adjudicator)',
          'Dr. S. Mukherjee, FICE (Technical Member)',
          'Er. K. V. Ramanathan, FCIArb (Contracts Member)',
        ],
        hearingDetails:
            'Conciliation meetings conducted 12-14 Sep 2026 under FIDIC Sub-Clause 20.5 (Amicable Settlement).',
        decisionDate: 'Pending Formal Sign-off',
        decisionRuling:
            'Parties reached amicable settlement under Cl. 20.5: Agreed financial compensation of ₹7.20 Cr for dewatering and trench restoration, plus 26 calendar days EOT with no liquidated damages.',
        costBreakdown: {
          'Trench Dewatering & Silt Extraction (18 Heavy Slurry Pumps)': 3.80,
          'Re-welding & Non-Destructive Testing of Flooded Strings': 2.10,
          'Reconstruction of Washed-away Embankment & Bunds': 2.25,
          'Standby Labor & Equipment Inundation Protection': 1.50,
        },
        evidenceCoverageScore: 92.0,
        evidenceList: [
          EvidenceItem(
            id: 'EVD-02-A',
            title: 'IMD 100-Year Historical Precipitation Anomaly Certification',
            category: EvidenceCategory.weatherStoppage,
            fileType: 'PDF',
            fileSize: '5.2 MB',
            date: '30 May 2026',
            referenceNumber: 'IMD/NERO/MET/FL-44',
            verifiedBy: 'Dr. T. Borah (Director, Regional Met Centre)',
            description:
                'Certified meteorological return-period analysis confirming rainfall exceeded 1-in-100 year threshold under FIDIC Cl. 8.4(c).',
            sha256Hash: '5e771a998b2c41870198aa71cdae01824ef90123cb112048991ef234091ab018',
          ),
          EvidenceItem(
            id: 'EVD-02-B',
            title: 'Drone Photogrammetry & Orthomosaic Trench Flood Survey',
            category: EvidenceCategory.delayEvent,
            fileType: 'TIFF',
            fileSize: '18.4 MB',
            date: '02 Jun 2026',
            referenceNumber: 'AERO/UAV/SURV/FL-09',
            verifiedBy: 'S. Roy (Lead QA/QC Geomatics)',
            description:
                'Ultra-high-resolution multispectral aerial survey illustrating 15.4 km submerged corridor and breached coffer dikes.',
            sha256Hash: '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
          ),
        ],
        weatherLogs: [
          WeatherStoppageRecord(
            id: 'WTR-02-1',
            date: '28 May 2026',
            station: 'Brahmaputra Basin River Gauge #09',
            rainfallMm: 184.0,
            windSpeedKmph: 48.0,
            waterLevelM: '106.8m MSL (+3.6m above High Flood Level)',
            hoursLost: 24,
            severity: 'Code Red Flash Flood Warning',
            workStopped: 'All Spread Activities Suspended - Emergency Evacuation',
          ),
          WeatherStoppageRecord(
            id: 'WTR-02-2',
            date: '29 May 2026',
            station: 'Brahmaputra Basin River Gauge #09',
            rainfallMm: 158.0,
            windSpeedKmph: 36.0,
            waterLevelM: '107.1m MSL (+3.9m above High Flood Level)',
            hoursLost: 24,
            severity: 'Code Red Flash Flood Sustained',
            workStopped: 'Dewatering Operations Only',
          ),
        ],
        siteDiaryRefs: [
          SiteDiaryReferenceRecord(
            id: 'SD-2026-0528',
            dprNumber: 'DPR-2026-148',
            date: '28 May 2026',
            chainage: 'KM 78+400',
            recordedHindrance: 'Floodwaters breached peripheral coffer bund; trench submerged to 3.2m depth',
            idleMachinery: '6x Dewatering Pumps, 4x Cat Excavators, 2x Sidebooms',
            idleLabourCount: 84,
            siteEngineerSignature: 'A. Sen (Site In-Charge)',
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      // CLM-2026-03: Late Approval of SIL-3 Sectionalizing Valve Skid Re-engineering
      // -----------------------------------------------------------------------
      const DabClaimModel(
        id: 'CLM-2026-03',
        title: 'Late Approval & Statutory Clearance of SIL-3 Valve Skid Re-engineering',
        clauseReference: 'FIDIC Cl. 20.1 (Notice within 28 days) & Cl. 1.9 (Delayed Drawings/Instructions)',
        amountClaimedCr: 6.15,
        amountAwardedCr: null,
        eotRequestedDays: 18,
        eotAwardedDays: null,
        status: DabWorkflowStage.hearingScheduled,
        noticeDate: '18 Jun 2026',
        noticeDayElapsed: 14,
        noticeTimeBarDaysRemaining: 14,
        detailedSubmissionDeadline: '30 Jul 2026',
        workPackage: 'WP-07 SCADA & Instrumentation',
        chainageLocation: 'Station SV-01 to SV-14 (Mainline Trunk Pipeline)',
        contractorJV: 'Honeywell Process Solutions JV',
        clientEmployer: 'Oil India Limited (OIL)',
        engineer: 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
        scopeSummary:
            'Engineer delayed technical review and statutory approval of revised vendor instrumentation datasheets for 58 calendar days post-submission, stalling procurement of long-lead emergency shutdown (ESD) electro-hydraulic actuators and holding back critical pre-commissioning schedule.',
        dabPanel: [
          'Justice (Retd.) B. N. Srikrishna (Presiding Adjudicator)',
          'Dr. S. Mukherjee, FICE (Technical Member)',
          'Er. K. V. Ramanathan, FCIArb (Contracts Member)',
        ],
        hearingDetails:
            'Oral hearing scheduled for 15 Oct 2026 at Hearing Room B, Guwahati Arbitration Centre & Virtual Hybrid Link.',
        decisionDate: null,
        decisionRuling: null,
        costBreakdown: {
          'Vendor Factory Storage & Extended Warranty Holding Surcharge': 2.40,
          'SCADA Integration Engineers Standby & Specialist Remobilization': 1.85,
          'Commissioning Spread Holding Costs': 1.20,
          'Contractor Financing & Indirect Overheads': 0.70,
        },
        evidenceCoverageScore: 89.0,
        evidenceList: [
          EvidenceItem(
            id: 'EVD-03-A',
            title: 'Engineering Transmittal Tracking Log (58-Day Review Backlog)',
            category: EvidenceCategory.delayEvent,
            fileType: 'XLSX',
            fileSize: '3.1 MB',
            date: '20 Jun 2026',
            referenceNumber: 'TR-SIL3-LOG-2026',
            verifiedBy: 'D. Kalita (Lead Document Controller)',
            description:
                'Document control transmittal matrix recording 58-day delay between Rev 01 submission and final Engineer mark-up return.',
            sha256Hash: '8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c',
          ),
          EvidenceItem(
            id: 'EVD-03-B',
            title: 'Primavera P6 Time Impact Analysis (TIA) Critical Path Fragnet',
            category: EvidenceCategory.delayEvent,
            fileType: 'PDF',
            fileSize: '7.8 MB',
            date: '10 Jul 2026',
            referenceNumber: 'P6-TIA-SIL3-REV0',
            verifiedBy: 'Ananya Sen (Lead Planning Engineer)',
            description:
                'Forensic critical path schedule fragnet demonstrating 18 calendar days direct shift in project Taking-Over milestone.',
            sha256Hash: '4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b',
          ),
        ],
        weatherLogs: [],
        siteDiaryRefs: [
          SiteDiaryReferenceRecord(
            id: 'SD-2026-0622',
            dprNumber: 'DPR-2026-173',
            date: '22 Jun 2026',
            chainage: 'Station SV-04',
            recordedHindrance: 'Instrumentation installation stalled pending certified vendor GA drawings',
            idleMachinery: 'Calibration bench & testing trailer on standby',
            idleLabourCount: 16,
            siteEngineerSignature: 'R. K. Sharma (QA/QC Lead)',
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      // CLM-2026-04: Forest Department Environmental Clearance Hold
      // -----------------------------------------------------------------------
      const DabClaimModel(
        id: 'CLM-2026-04',
        title: 'Forest Department Environmental Clearance Hold at Dehing Patkai Buffer Zone',
        clauseReference: 'FIDIC Cl. 20.1 (Notice within 28 days) & Cl. 2.2 (Permits, Licences and Approvals)',
        amountClaimedCr: 12.80,
        amountAwardedCr: null,
        eotRequestedDays: 28,
        eotAwardedDays: null,
        status: DabWorkflowStage.noticeServed,
        noticeDate: '12 Sep 2026',
        noticeDayElapsed: 18,
        noticeTimeBarDaysRemaining: 10,
        detailedSubmissionDeadline: '24 Oct 2026',
        workPackage: 'WP-02 Civil & Foundations',
        chainageLocation: 'KM 102+400 to 116+800 (Dehing Patkai Eco-Sensitive Zone)',
        contractorJV: 'L&T Hydrocarbon Engineering JV',
        clientEmployer: 'Oil India Limited (OIL)',
        engineer: 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
        scopeSummary:
            'State Forest Advisory Committee issued an unexpected stop-work directive halting right-of-way tree felling and grading pending supplementary compensatory afforestation sanctions. Pipeline spread stranded with 22 heavy excavators, 4 pipe bending rigs, and 160 specialized welders.',
        dabPanel: [
          'Justice (Retd.) B. N. Srikrishna (Presiding Adjudicator)',
          'Dr. S. Mukherjee, FICE (Technical Member)',
          'Er. K. V. Ramanathan, FCIArb (Contracts Member)',
        ],
        hearingDetails: null,
        decisionDate: null,
        decisionRuling: null,
        costBreakdown: {
          'Specialist Pipeline Spreads & Heavy Equipment Standing Rate': 6.40,
          'Camp Welfare & Retained Workforce Standing Charges': 3.20,
          'Prolongation of Site Overhead & Contract Insurances': 2.10,
          'Anticipated Cl. 14.8 Financing Charges': 1.10,
        },
        evidenceCoverageScore: 84.5,
        evidenceList: [
          EvidenceItem(
            id: 'EVD-04-A',
            title: 'Assam State Forest Advisory Committee Stop-Work Directive',
            category: EvidenceCategory.statutoryNotice,
            fileType: 'PDF',
            fileSize: '2.4 MB',
            date: '10 Sep 2026',
            referenceNumber: 'FAC-AS-2026-994',
            verifiedBy: 'Conservator of Forests, Eastern Division',
            description:
                'Statutory directive halting all mechanized excavation in eco-sensitive buffer zone pending MoEFCC clearance ratification.',
            sha256Hash: '9f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e9d8c7b6a5f4e3d2c1b0a9f8e',
          ),
          EvidenceItem(
            id: 'EVD-04-B',
            title: 'Cl. 20.1 Initial Notice of Claim Served on Engineer',
            category: EvidenceCategory.statutoryNotice,
            fileType: 'PDF',
            fileSize: '1.5 MB',
            date: '12 Sep 2026',
            referenceNumber: 'LT/OIL/CLM-04/NOT-01',
            verifiedBy: 'Marcus Vance, P.E. (Engineer Receipt)',
            description:
                'Timely notice served within 2 days of government halt order; 10 days remaining to compile initial evidentiary register.',
            sha256Hash: '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          ),
          EvidenceItem(
            id: 'EVD-04-C',
            title: 'Stranded Equipment Fleet Inventory Manifest',
            category: EvidenceCategory.costVoucher,
            fileType: 'PDF',
            fileSize: '3.6 MB',
            date: '16 Sep 2026',
            referenceNumber: 'PLANT/DPK/INV-01',
            verifiedBy: 'Subhash Roy (Safety & HSE Officer)',
            description:
                'Audited register of 22 excavators, 4 pipe bending skids, and support vehicles locked down inside safe storage corral.',
            sha256Hash: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
          ),
        ],
        weatherLogs: [],
        siteDiaryRefs: [
          SiteDiaryReferenceRecord(
            id: 'SD-2026-0912',
            dprNumber: 'DPR-2026-255',
            date: '12 Sep 2026',
            chainage: 'KM 108+000',
            recordedHindrance: 'Forest Rangers stopped work at boundary; equipment demobilized to base camp',
            idleMachinery: '22x Excavators, 4x Bending Skids, 6x Sidebooms',
            idleLabourCount: 160,
            siteEngineerSignature: 'Vikram Joshi (Field Operations)',
          ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Metric Computations
  // ---------------------------------------------------------------------------
  double get _totalAmountClaimedCr =>
      _claims.fold(0.0, (acc, item) => acc + item.amountClaimedCr);

  double get _totalAmountAwardedCr => _claims.fold(
      0.0, (acc, item) => acc + (item.amountAwardedCr ?? 0.0));

  int get _totalEotRequestedDays =>
      _claims.fold(0, (acc, item) => acc + item.eotRequestedDays);

  int get _timeBarCompliantCount =>
      _claims.where((c) => c.noticeDayElapsed <= 28).length;

  List<DabClaimModel> get _filteredClaims {
    var list = _claims.where((claim) {
      if (_selectedStatusFilter == 'NOTICE' &&
          claim.status != DabWorkflowStage.noticeServed) {
        return false;
      }
      if (_selectedStatusFilter == 'REFERRAL' &&
          claim.status != DabWorkflowStage.dabReferral) {
        return false;
      }
      if (_selectedStatusFilter == 'HEARING' &&
          claim.status != DabWorkflowStage.hearingScheduled) {
        return false;
      }
      if (_selectedStatusFilter == 'SETTLEMENT' &&
          claim.status != DabWorkflowStage.amicableSettlement) {
        return false;
      }
      if (_selectedStatusFilter == 'DECISION' &&
          claim.status != DabWorkflowStage.decisionRendered) {
        return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesId = claim.id.toLowerCase().contains(q);
        final matchesTitle = claim.title.toLowerCase().contains(q);
        final matchesClause = claim.clauseReference.toLowerCase().contains(q);
        final matchesWp = claim.workPackage.toLowerCase().contains(q);
        final matchesChainage = claim.chainageLocation.toLowerCase().contains(q);
        if (!matchesId &&
            !matchesTitle &&
            !matchesClause &&
            !matchesWp &&
            !matchesChainage) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (_sortBy) {
      case 'AMOUNT_DESC':
        list.sort((a, b) => b.amountClaimedCr.compareTo(a.amountClaimedCr));
        break;
      case 'EOT_DESC':
        list.sort((a, b) => b.eotRequestedDays.compareTo(a.eotRequestedDays));
        break;
      case 'ID_ASC':
      default:
        list.sort((a, b) => a.id.compareTo(b.id));
        break;
    }

    return list;
  }

  void _toggleCardExpansion(String id) {
    setState(() {
      if (_expandedClaimCards.contains(id)) {
        _expandedClaimCards.remove(id);
      } else {
        _expandedClaimCards.add(id);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Status Workflow Progression Action
  // ---------------------------------------------------------------------------
  void _advanceWorkflowStage(DabClaimModel claim) {
    if (claim.status == DabWorkflowStage.decisionRendered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${claim.id} already has a final binding DAB Decision rendered under Sub-Clause 20.4.'),
          backgroundColor: AppTheme.surfaceCard,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: [
            Icon(Icons.rule_folder_rounded, color: claim.status.color, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Advance FIDIC Cl. 20 Workflow',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Claim ID: ${claim.id}',
              style: const TextStyle(
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              claim.title,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Stage:',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      Text(claim.status.label,
                          style: TextStyle(
                              color: claim.status.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Target Stage:',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      Text(_getNextStage(claim.status).label,
                          style: TextStyle(
                              color: _getNextStage(claim.status).color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Confirming this progression records the official transmittal under FIDIC Red Book Sub-Clause 20.4 / 20.5 rules.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _getNextStage(claim.status).color,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final nextStage = _getNextStage(claim.status);
              setState(() {
                final idx = _claims.indexWhere((c) => c.id == claim.id);
                if (idx != -1) {
                  _claims[idx] = _claims[idx].copyWith(
                    status: nextStage,
                    hearingDetails: nextStage == DabWorkflowStage.hearingScheduled
                        ? 'Oral proceedings conducted at Guwahati Arbitration Centre'
                        : _claims[idx].hearingDetails,
                    decisionDate: nextStage == DabWorkflowStage.decisionRendered
                        ? '30 Sep 2026'
                        : _claims[idx].decisionDate,
                  );
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${claim.id} advanced to ${nextStage.label} in FIDIC Register.'),
                  backgroundColor: nextStage.color,
                ),
              );
            },
            child: const Text('Confirm & Advance',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  DabWorkflowStage _getNextStage(DabWorkflowStage current) {
    switch (current) {
      case DabWorkflowStage.noticeServed:
        return DabWorkflowStage.dabReferral;
      case DabWorkflowStage.dabReferral:
        return DabWorkflowStage.hearingScheduled;
      case DabWorkflowStage.hearingScheduled:
        return DabWorkflowStage.amicableSettlement;
      case DabWorkflowStage.amicableSettlement:
        return DabWorkflowStage.decisionRendered;
      case DabWorkflowStage.decisionRendered:
        return DabWorkflowStage.decisionRendered;
    }
  }

  // ---------------------------------------------------------------------------
  // New Notice of Claim Modal Sheet (FIDIC Cl. 20.1)
  // ---------------------------------------------------------------------------
  void _openNewClaimModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewNoticeOfClaimBottomSheet(
        nextClaimNumber: _claims.length + 1,
        onSubmit: (newClaim) {
          setState(() {
            _claims.add(newClaim);
            _expandedClaimCards.add(newClaim.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Notice of Claim ${newClaim.id} successfully registered under FIDIC Cl. 20.1.'),
              backgroundColor: AppTheme.primary,
              duration: const Duration(seconds: 4),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIDIC Clause 20 Info Modal
  // ---------------------------------------------------------------------------
  void _showFidicCl20InfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.gavel_rounded,
                      color: AppTheme.primaryLight, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FIDIC Red Book Clause 20 Framework',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Dispute Adjudication Board & Claims Resolution Process',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
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
            const Divider(color: AppTheme.border, height: 24),
            Expanded(
              child: ListView(
                children: const [
                  _FidicClauseGuideCard(
                    clause: 'Sub-Clause 20.1',
                    title: 'Contractor\'s Claims & 28-Day Strict Time-Bar',
                    content:
                        'The Contractor MUST give notice to the Engineer describing the event or circumstance giving rise to the claim not later than 28 days after the Contractor became aware, or should have become aware, of the event. Failure to give notice within 28 days discharges the Employer from all liability and bars the Contractor from EOT or additional payment.',
                  ),
                  SizedBox(height: 10),
                  _FidicClauseGuideCard(
                    clause: 'Sub-Clause 20.1 (cont.)',
                    title: '42-Day Detailed Claim & Contemporaneous Records',
                    content:
                        'Within 42 days after becoming aware of the event, the Contractor must submit a fully detailed claim with full supporting particulars of the basis of the claim and of the extension of time and/or additional payment claimed. Contemporaneous records must be kept on Site and made available for the Engineer\'s inspection.',
                  ),
                  SizedBox(height: 10),
                  _FidicClauseGuideCard(
                    clause: 'Sub-Clause 20.2',
                    title: 'Appointment of the Dispute Adjudication Board (DAB)',
                    content:
                        'Disputes shall be adjudicated by a DAB in accordance with Sub-Clause 20.4. The DAB comprises either one or three suitably qualified persons. If three, each Party nominates one member for approval of the other Party, and the two members recommend the third member who acts as chairman.',
                  ),
                  SizedBox(height: 10),
                  _FidicClauseGuideCard(
                    clause: 'Sub-Clause 20.4',
                    title: 'Obtaining DAB\'s Decision (84-Day Window)',
                    content:
                        'Within 84 days after receiving a referral, or within such other period as may be proposed by the DAB and approved by both Parties, the DAB shall give its decision in writing. The decision is binding on both Parties, who shall promptly give effect to it unless revised in an amicable settlement or an arbitral award.',
                  ),
                  SizedBox(height: 10),
                  _FidicClauseGuideCard(
                    clause: 'Sub-Clause 20.5',
                    title: 'Amicable Settlement (56-Day Cooling Period)',
                    content:
                        'Where notice of dissatisfaction has been given under Sub-Clause 20.4, both Parties shall attempt to settle the dispute amicably before the commencement of arbitration. Arbitration may commence on or after the 56th day after the day on which notice of dissatisfaction was given.',
                  ),
                  SizedBox(height: 10),
                  _FidicClauseGuideCard(
                    clause: 'Sub-Clause 20.6',
                    title: 'Arbitration (ICC / Domestic Final Resolution)',
                    content:
                        'Unless settled amicably, any dispute in respect of which the DAB\'s decision has not become final and binding shall be finally settled by international arbitration under the Rules of Arbitration of the International Chamber of Commerce (ICC) or Indian Arbitration and Conciliation Act 1996.',
                  ),
                  SizedBox(height: 10),
                  _FidicClauseGuideCard(
                    clause: 'Sub-Clause 14.8',
                    title: 'Financing Charges for Delayed Payment',
                    content:
                        'If the Contractor does not receive payment in accordance with Sub-Clause 14.7, the Contractor is entitled to receive financing charges compounded monthly on the amount unpaid during the period of delay. Calculated at annual rate of 3 percentage points above the Central Bank discount rate (RBI Repo).',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FIDIC Dispute Adjudication Board',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Clause 20 DAB & Arbitration Claims Register',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'FIDIC Cl. 20 Knowledge Hub',
            icon: const Icon(Icons.menu_book_rounded,
                color: AppTheme.primaryLight),
            onPressed: () => _showFidicCl20InfoModal(context),
          ),
          IconButton(
            tooltip: 'Export DAB Register PDF',
            icon: const Icon(Icons.picture_as_pdf_rounded,
                color: AppTheme.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'FIDIC Clause 20 Claims Register exported to legal evidentiary PDF bundle.'),
                  backgroundColor: AppTheme.surfaceCard,
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 2.5,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(
              icon: Icon(Icons.assignment_turned_in_rounded, size: 18),
              text: 'Claims Register',
            ),
            Tab(
              icon: Icon(Icons.folder_shared_rounded, size: 18),
              text: 'Dossier Builder',
            ),
            Tab(
              icon: Icon(Icons.calculate_rounded, size: 18),
              text: 'Cl. 14.8 Calculator',
            ),
            Tab(
              icon: Icon(Icons.account_balance_rounded, size: 18),
              text: 'FIDIC Framework',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_alert_rounded, size: 20),
        label: const Text(
          'Serve Cl. 20.1 Notice',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () => _openNewClaimModal(context),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClaimsRegisterTab(),
          _buildDossierBuilderTab(),
          _buildCl148CalculatorTab(),
          _buildFidicFrameworkTab(),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: CLAIMS REGISTER & WORKFLOW
  // ==========================================================================
  Widget _buildClaimsRegisterTab() {
    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: AppTheme.surfaceCard,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Executive KPI Summary Dashboard
          _buildExecutiveSummaryBanner(),
          const SizedBox(height: 12),

          // Active 28-day statutory notice alert banner
          _buildTimeBarStatutoryAlertBanner(),
          const SizedBox(height: 14),

          // Search and Filter Header
          _buildSearchAndFilterBar(),
          const SizedBox(height: 12),

          // Claims Register List
          if (_filteredClaims.isEmpty)
            _buildEmptyState()
          else
            ..._filteredClaims.map((claim) => _buildClaimCard(claim)),

          const SizedBox(height: 80), // Fab spacing
        ],
      ),
    );
  }

  Widget _buildExecutiveSummaryBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.dashboard_customize_rounded,
                      color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'DAB & ARBITRATION EXECUTIVE SUMMARY',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.tertiary.withAlpha(80)),
                ),
                child: Text(
                  '${_claims.length} CLAIMS LOGGED',
                  style: const TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Total Amount Claimed',
                  value: '₹${_totalAmountClaimedCr.toStringAsFixed(2)} Cr',
                  color: AppTheme.secondary,
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.border),
              Expanded(
                child: _buildMetricTile(
                  label: 'Awarded / Settled',
                  value: '₹${_totalAmountAwardedCr.toStringAsFixed(2)} Cr',
                  color: AppTheme.tertiary,
                  icon: Icons.verified_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'EOT Requested',
                  value: '+$_totalEotRequestedDays Days',
                  color: AppTheme.primaryLight,
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.border),
              Expanded(
                child: _buildMetricTile(
                  label: '28-Day Compliance',
                  value: '$_timeBarCompliantCount/${_claims.length} (100%)',
                  color: AppTheme.tertiary,
                  icon: Icons.timer_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBarStatutoryAlertBanner() {
    final activeNoticeClaim = _claims.firstWhere(
      (c) => c.status == DabWorkflowStage.noticeServed,
      orElse: () => _claims.first,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2E5C).withAlpha(120),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF38BDF8).withAlpha(100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer_outlined,
                color: Color(0xFF38BDF8), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FIDIC Cl. 20.1 Statutory 42-Day Clock Active',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      activeNoticeClaim.id,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Notice served ${activeNoticeClaim.noticeDayElapsed} days ago. Detailed claim dossier submission due by ${activeNoticeClaim.detailedSubmissionDeadline} (Sub-Clause 20.1 condition precedent).',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Search by Claim ID, title, clause or chainage...',
              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              prefixIcon:
                  Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Workflow Status Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL', 'All (${_claims.length})'),
              const SizedBox(width: 6),
              _buildFilterChip(
                  'NOTICE',
                  'Notice Served (${_claims.where((c) => c.status == DabWorkflowStage.noticeServed).length})',
                  DabWorkflowStage.noticeServed.color),
              const SizedBox(width: 6),
              _buildFilterChip(
                  'HEARING',
                  'Hearing (${_claims.where((c) => c.status == DabWorkflowStage.hearingScheduled).length})',
                  DabWorkflowStage.hearingScheduled.color),
              const SizedBox(width: 6),
              _buildFilterChip(
                  'SETTLEMENT',
                  'Settlement (${_claims.where((c) => c.status == DabWorkflowStage.amicableSettlement).length})',
                  DabWorkflowStage.amicableSettlement.color),
              const SizedBox(width: 6),
              _buildFilterChip(
                  'DECISION',
                  'Decision (${_claims.where((c) => c.status == DabWorkflowStage.decisionRendered).length})',
                  DabWorkflowStage.decisionRendered.color),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, [Color? activeColor]) {
    final isSelected = _selectedStatusFilter == key;
    final color = activeColor ?? AppTheme.primaryLight;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(40) : AppTheme.surfaceCard,
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
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildClaimCard(DabClaimModel claim) {
    final isExpanded = _expandedClaimCards.contains(claim.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? claim.status.color.withAlpha(150)
              : AppTheme.border,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            claim.id,
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: claim.status.color.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: claim.status.color.withAlpha(100)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(claim.status.icon,
                                  size: 12, color: claim.status.color),
                              const SizedBox(width: 5),
                              Text(
                                claim.status.label,
                                style: TextStyle(
                                  color: claim.status.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () => _toggleCardExpansion(claim.id),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  claim.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.bookmark_border_rounded,
                        size: 13, color: AppTheme.secondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        claim.clauseReference,
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Financial & EOT Metrics Strip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withAlpha(150)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amount Claimed',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        claim.formattedClaimedCost,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (claim.amountAwardedCr != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Awarded: ${claim.formattedAwardedCost}',
                          style: const TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: AppTheme.border),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EOT Requested',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        claim.formattedRequestedEot,
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (claim.eotAwardedDays != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Awarded: ${claim.formattedAwardedEot}',
                          style: const TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: AppTheme.border),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evidence Dossier',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.shield_rounded,
                              size: 13, color: AppTheme.tertiary),
                          const SizedBox(width: 4),
                          Text(
                            '${claim.evidenceCoverageScore.toInt()}% Verified',
                            style: const TextStyle(
                              color: AppTheme.tertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
          const SizedBox(height: 12),

          // 5-Stage Status Workflow Visual Stepper
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _buildWorkflowStepper(claim),
          ),
          const SizedBox(height: 12),

          // Expandable Detailed Area
          if (isExpanded) ...[
            const Divider(color: AppTheme.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scope summary
                  const Text(
                    'Contractual Delay Cause & Circumstances:',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    claim.scopeSummary,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Chainage & Work Package
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                            'Work Package', claim.workPackage, Icons.work_outline),
                        const SizedBox(height: 6),
                        _buildDetailRow('Location Chainage',
                            claim.chainageLocation, Icons.location_on_outlined),
                        const SizedBox(height: 6),
                        _buildDetailRow('Contractor JV', claim.contractorJV,
                            Icons.business_rounded),
                        const SizedBox(height: 6),
                        _buildDetailRow(
                            'FIDIC Engineer', claim.engineer, Icons.engineering),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // DAB Panel Members
                  const Text(
                    'Dispute Adjudication Board (DAB) Panel:',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...claim.dabPanel.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_pin_rounded,
                              size: 14, color: AppTheme.primaryLight),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              member,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hearing or Decision details if available
                  if (claim.hearingDetails != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA78BFA).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFA78BFA).withAlpha(80)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.event_available_rounded,
                              size: 16, color: Color(0xFFA78BFA)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              claim.hearingDetails!,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (claim.decisionRuling != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.tertiary.withAlpha(80)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: AppTheme.tertiary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              claim.decisionRuling!,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.folder_shared_rounded, size: 16),
                          label: const Text('Open Dossier',
                              style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setState(() {
                              _selectedDossierClaimId = claim.id;
                              _tabController.animateTo(1);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: claim.status.color,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: Text(
                            claim.isDecided ? 'Review Decision' : 'Advance Stage',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _advanceWorkflowStage(claim),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5-STAGE WORKFLOW STEPPER COMPONENT
  // ---------------------------------------------------------------------------
  Widget _buildWorkflowStepper(DabClaimModel claim) {
    const stages = DabWorkflowStage.values;
    final currentStep = claim.status.stepIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'DISPUTE WORKFLOW STAGES',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Text(
              'Stage ${currentStep + 1} of 5',
              style: TextStyle(
                color: claim.status.color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(stages.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Connector Line
              final stepBefore = index ~/ 2;
              final isPassed = stepBefore < currentStep;
              return Expanded(
                child: Container(
                  height: 2.5,
                  color: isPassed
                      ? claim.status.color
                      : AppTheme.border.withAlpha(120),
                ),
              );
            } else {
              // Stage Node
              final stageIndex = index ~/ 2;
              final stage = stages[stageIndex];
              final isPassed = stageIndex < currentStep;
              final isCurrent = stageIndex == currentStep;

              Color nodeColor;
              if (isCurrent) {
                nodeColor = stage.color;
              } else if (isPassed) {
                nodeColor = claim.status.color;
              } else {
                nodeColor = AppTheme.border;
              }

              return Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? stage.color
                          : (isPassed
                              ? claim.status.color.withAlpha(40)
                              : AppTheme.surface),
                      border: Border.all(
                        color: nodeColor,
                        width: isCurrent ? 2.5 : 1.5,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: stage.color.withAlpha(100),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isPassed
                          ? Icon(Icons.check,
                              size: 14, color: claim.status.color)
                          : (isCurrent
                              ? Icon(stage.icon,
                                  size: 13, color: Colors.black)
                              : Text(
                                  '${stageIndex + 1}',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 58,
                    child: Text(
                      stage.shortLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isCurrent
                            ? stage.color
                            : (isPassed
                                ? AppTheme.textPrimary
                                : AppTheme.textMuted),
                        fontSize: 9,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            }
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          const Text(
            'No matching claims in register',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search criteria or filter tags.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: CLAIM DOSSIER BUILDER
  // ==========================================================================
  Widget _buildDossierBuilderTab() {
    final activeClaim = _claims.firstWhere(
      (c) => c.id == _selectedDossierClaimId,
      orElse: () => _claims.first,
    );

    final allEvidence = activeClaim.evidenceList;
    final weatherLogs = activeClaim.weatherLogs;
    final siteDiaryRefs = activeClaim.siteDiaryRefs;

    final filteredEvidence = allEvidence.where((item) {
      if (_dossierEvidenceFilter == 'DELAY_EVENT' &&
          item.category != EvidenceCategory.delayEvent) {
        return false;
      }
      if (_dossierEvidenceFilter == 'WEATHER' &&
          item.category != EvidenceCategory.weatherStoppage) {
        return false;
      }
      if (_dossierEvidenceFilter == 'SITE_DIARY' &&
          item.category != EvidenceCategory.siteDiary) {
        return false;
      }
      if (_dossierEvidenceFilter == 'COST' &&
          item.category != EvidenceCategory.costVoucher) {
        return false;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Dossier Claim Selector Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.folder_special_rounded,
                      color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'CLAIM DOSSIER BUILDER (FIDIC CL. 20.1)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDossierClaimId,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceCard,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppTheme.primaryLight),
                    items: _claims.map((claim) {
                      return DropdownMenuItem<String>(
                        value: claim.id,
                        child: Text(
                          '${claim.id}: ${claim.title}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDossierClaimId = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Triangulation & Completeness Meter
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
                  const Text(
                    'EVIDENTIARY TRIANGULATION STRENGTH',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    '${activeClaim.evidenceCoverageScore.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: activeClaim.evidenceCoverageScore / 100.0,
                  backgroundColor: AppTheme.surface,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.tertiary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDossierStat(
                    'Delay Logs',
                    '${allEvidence.length}',
                    AppTheme.primaryLight,
                  ),
                  _buildDossierStat(
                    'Weather Logs',
                    '${weatherLogs.length}',
                    const Color(0xFF00E5FF),
                  ),
                  _buildDossierStat(
                    'Site Diaries',
                    '${siteDiaryRefs.length}',
                    AppTheme.secondary,
                  ),
                  _buildDossierStat(
                    'Audit Hashes',
                    '${allEvidence.length} SHA-256',
                    AppTheme.tertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Evidence category pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDossierFilterPill('ALL', 'All Artifacts (${allEvidence.length})'),
              const SizedBox(width: 6),
              _buildDossierFilterPill(
                  'DELAY_EVENT', 'Delay Events', EvidenceCategory.delayEvent.color),
              const SizedBox(width: 6),
              _buildDossierFilterPill(
                  'WEATHER', 'Weather Stoppages', EvidenceCategory.weatherStoppage.color),
              const SizedBox(width: 6),
              _buildDossierFilterPill(
                  'SITE_DIARY', 'Site Diaries', EvidenceCategory.siteDiary.color),
              const SizedBox(width: 6),
              _buildDossierFilterPill(
                  'COST', 'Cost Vouchers', EvidenceCategory.costVoucher.color),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Section: Upload Delay Event Evidence
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SUBSTANTIATING DELAY EVIDENCE',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_circle_outline_rounded,
                  size: 16, color: AppTheme.primaryLight),
              label: const Text('Add Evidence',
                  style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              onPressed: () => _showAddEvidenceDialog(activeClaim),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (filteredEvidence.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
              child: Text(
                'No artifacts found under this filter.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          )
        else
          ...filteredEvidence.map((item) => _buildEvidenceCard(item)),

        const SizedBox(height: 16),

        // Section: Weather Stoppage Telemetry Links
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.thunderstorm_rounded,
                    color: Color(0xFF00E5FF), size: 16),
                SizedBox(width: 6),
                Text(
                  'WEATHER STOPPAGE LOG LINKS',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new_rounded,
                  size: 14, color: Color(0xFF00E5FF)),
              label: const Text('Live Telemetry',
                  style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WeatherImpactScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (weatherLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text(
              'No weather stoppage events linked to this specific claim package.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          )
        else
          ...weatherLogs.map((log) => _buildWeatherLogCard(log)),

        const SizedBox(height: 16),

        // Section: Contemporaneous Daily Site Diary References
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.menu_book_rounded,
                    color: AppTheme.secondary, size: 16),
                SizedBox(width: 6),
                Text(
                  'CONTEMPORANEOUS SITE DIARY (CL. 4.20)',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new_rounded,
                  size: 14, color: AppTheme.secondary),
              label: const Text('Site Diary Screen',
                  style: TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SiteDiaryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (siteDiaryRefs.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text(
              'No daily site diary entries linked to this claim.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          )
        else
          ...siteDiaryRefs.map((diary) => _buildSiteDiaryCard(diary)),

        const SizedBox(height: 20),

        // Compile Dossier Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.picture_as_pdf_rounded),
          label: Text(
            'Compile & Export ${activeClaim.id} Cl. 20.1 Dossier PDF',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Compiled ${allEvidence.length} evidence items and ${siteDiaryRefs.length} diary records for ${activeClaim.id} into official legal brief.'),
                backgroundColor: AppTheme.primary,
              ),
            );
          },
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDossierStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildDossierFilterPill(String key, String label,
      [Color? activeColor]) {
    final isSelected = _dossierEvidenceFilter == key;
    final color = activeColor ?? AppTheme.primaryLight;
    return GestureDetector(
      onTap: () => setState(() => _dossierEvidenceFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(40) : AppTheme.surfaceCard,
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
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceCard(EvidenceItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.category.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(item.category.icon,
                    size: 16, color: item.category.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ref: ${item.referenceNumber} • ${item.date} • ${item.fileType} (${item.fileSize})',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  item.fileType,
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.fingerprint_rounded,
                    size: 12, color: AppTheme.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'SHA-256: ${item.sha256Hash.substring(0, 24)}...',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontFamily: 'monospace',
                      fontSize: 9,
                    ),
                  ),
                ),
                Text(
                  'By ${item.verifiedBy}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherLogCard(WeatherStoppageRecord log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00E5FF).withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${log.date} — ${log.station}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${log.hoursLost}h Lost',
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Rainfall: ${log.rainfallMm} mm',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ),
              Expanded(
                child: Text(
                  'Wind: ${log.windSpeedKmph} km/h',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ),
              Expanded(
                child: Text(
                  'Level: ${log.waterLevelM}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Work Suspended: ${log.workStopped}',
            style: const TextStyle(
              color: AppTheme.secondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteDiaryCard(SiteDiaryReferenceRecord diary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.secondary.withAlpha(80)),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      diary.dprNumber,
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${diary.date} • ${diary.chainage}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${diary.idleLabourCount} Lab. Stranded',
                style: const TextStyle(
                  color: AppTheme.error,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            diary.recordedHindrance,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Idle Plant: ${diary.idleMachinery}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Signed: ${diary.siteEngineerSignature}',
                style: const TextStyle(
                  color: AppTheme.tertiary,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialog: Add Evidence Modal
  // ---------------------------------------------------------------------------
  void _showAddEvidenceDialog(DabClaimModel claim) {
    final titleCtrl = TextEditingController();
    final refCtrl = TextEditingController(
        text: 'LT/OIL/${claim.id}/EVD-${DateTime.now().millisecondsSinceEpoch % 1000}');
    final descCtrl = TextEditingController();
    final verifierCtrl =
        TextEditingController(text: 'Marcus Vance, P.E. (FIDIC Engineer)');
    EvidenceCategory selectedCategory = EvidenceCategory.delayEvent;
    String fileType = 'PDF';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.upload_file_rounded,
                  color: AppTheme.primaryLight, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Attach Dossier Evidence',
                  style: TextStyle(
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
                const Text(
                  'Evidence Classification Category:',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<EvidenceCategory>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceCard,
                      items: EvidenceCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.label,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Evidence Document Title:',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Geotechnical Strata Borehole Log #B-14',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Reference Number / Letter Code:',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: refCtrl,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'e.g. OIL/SURV/ROW/992',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Description & Factual Findings:',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Describe contemporaneous site facts & delay impact...',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Certified / Verified By:',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: verifierCtrl,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Lead Engineer / QA Inspector',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Format: ',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 11)),
                    ...['PDF', 'CSV', 'TIFF', 'XLSX'].map((fmt) {
                      final isSelected = fileType == fmt;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(fmt, style: const TextStyle(fontSize: 10)),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setDialogState(() => fileType = fmt);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter an evidence title.')),
                  );
                  return;
                }
                final newEvidence = EvidenceItem(
                  id: 'EVD-${DateTime.now().millisecondsSinceEpoch % 10000}',
                  title: titleCtrl.text.trim(),
                  category: selectedCategory,
                  fileType: fileType,
                  fileSize: '3.4 MB',
                  date: DateFormat('dd MMM yyyy').format(DateTime.now()),
                  referenceNumber: refCtrl.text.trim(),
                  verifiedBy: verifierCtrl.text.trim(),
                  description: descCtrl.text.trim().isNotEmpty
                      ? descCtrl.text.trim()
                      : 'Contemporaneous record verified per FIDIC Sub-Clause 20.1.',
                  sha256Hash:
                      '${math.Random().nextInt(999999999)}abcdef1234567890deadbeef',
                );

                setState(() {
                  final idx = _claims.indexWhere((c) => c.id == claim.id);
                  if (idx != -1) {
                    final updatedList =
                        List<EvidenceItem>.from(_claims[idx].evidenceList)
                          ..add(newEvidence);
                    _claims[idx] = _claims[idx].copyWith(
                      evidenceList: updatedList,
                      evidenceCoverageScore: math.min(
                          100.0, _claims[idx].evidenceCoverageScore + 2.5),
                    );
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Attached "${newEvidence.title}" to ${claim.id} dossier.'),
                    backgroundColor: AppTheme.tertiary,
                  ),
                );
              },
              child: const Text('Attach Evidence',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 3: COST & INTEREST CALCULATOR FOR DELAYED CONTRACTOR PAYMENTS (CL. 14.8)
  // ==========================================================================
  Widget _buildCl148CalculatorTab() {
    final effectiveAnnualRate =
        _benchmarkRatePercentage + _fidicStatutoryMargin;
    final delayedDays =
        math.max(0, _actualSettlementDate.difference(_paymentDueDate).inDays);
    final delayedMonths = delayedDays / 30.4167; // average days per month

    // Compounded Monthly Interest Calculation under FIDIC Cl. 14.8:
    // Rate per month: r_m = effectiveAnnualRate / 100 / 12
    final monthlyRate = (effectiveAnnualRate / 100.0) / 12.0;

    // Principal in Rupees
    final principalRupees = _calculatorPrincipalCr * 10000000.0;

    // Compounded amount: A = P * (1 + monthlyRate) ^ (months)
    final compoundedAmountRupees =
        principalRupees * math.pow(1.0 + monthlyRate, delayedMonths);
    final accruedInterestRupees = compoundedAmountRupees - principalRupees;
    final accruedInterestCr = accruedInterestRupees / 10000000.0;
    final totalEmployerLiabilityCr =
        _calculatorPrincipalCr + accruedInterestCr;
    final dailyInterestBurnRupees =
        delayedDays > 0 ? (accruedInterestRupees / delayedDays) : 0.0;

    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Statutory Background Banner
        Container(
          padding: const EdgeInsets.all(12),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.gavel_rounded,
                        color: AppTheme.secondary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'FIDIC CL. 14.8 FINANCING CHARGES FOR DELAYED PAYMENT',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '"If the Contractor does not receive payment in accordance with Sub-Clause 14.7, the Contractor shall be entitled to receive financing charges compounded monthly on the amount unpaid during the period of delay. Calculated at annual rate of three percentage points above Central Bank discount rate."',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Quick Preset IPC selector
        const Text(
          'Select Certified Interim Payment Certificate (IPC):',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildIpcPresetChip('IPC #14 (Moran Civil)', 14.20,
                  DateTime(2026, 4, 18), DateTime(2026, 7, 1)),
              const SizedBox(width: 8),
              _buildIpcPresetChip('IPC #16 (HDD River)', 8.50,
                  DateTime(2026, 5, 10), DateTime(2026, 8, 15)),
              const SizedBox(width: 8),
              _buildIpcPresetChip('IPC #17 (Terminal Civil)', 18.40,
                  DateTime(2026, 3, 1), DateTime(2026, 6, 25)),
              const SizedBox(width: 8),
              _buildIpcPresetChip('Custom Audit', _calculatorPrincipalCr,
                  _paymentDueDate, _actualSettlementDate),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Interactive Input Card
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
              // Principal Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Certified Unpaid Principal (P):',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  Text(
                    '₹${_calculatorPrincipalCr.toStringAsFixed(2)} Cr',
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _calculatorPrincipalCr,
                min: 1.0,
                max: 50.0,
                divisions: 98,
                activeColor: AppTheme.primaryLight,
                inactiveColor: AppTheme.surface,
                onChanged: (val) {
                  setState(() {
                    _calculatorPrincipalCr = val;
                    _selectedIpcPreset = 'Custom Audit';
                  });
                },
              ),

              // Benchmark rate slider (RBI Repo Rate)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Central Bank Discount Rate (RBI Repo):',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  Text(
                    '${_benchmarkRatePercentage.toStringAsFixed(2)}% p.a.',
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _benchmarkRatePercentage,
                min: 4.0,
                max: 12.0,
                divisions: 32,
                activeColor: AppTheme.secondary,
                inactiveColor: AppTheme.surface,
                onChanged: (val) {
                  setState(() => _benchmarkRatePercentage = val);
                },
              ),

              // FIDIC Margin Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FIDIC Cl. 14.8 Statutory Margin:',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 11),
                    ),
                    const Text(
                      '+3.00% p.a. (Fixed)',
                      style: TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Combined Rate Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Effective Financing Rate (r):',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  Text(
                    '${effectiveAnnualRate.toStringAsFixed(2)}% p.a. (Compounded Monthly)',
                    style: const TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: AppTheme.border, height: 20),

              // Dates Picker Row
              Row(
                children: [
                  Expanded(
                    child: _buildDatePickerBox(
                      title: 'Cl. 14.7 Due Date',
                      date: _paymentDueDate,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _paymentDueDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2028),
                        );
                        if (picked != null) {
                          setState(() {
                            _paymentDueDate = picked;
                            _selectedIpcPreset = 'Custom Audit';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDatePickerBox(
                      title: 'Actual/Payment Date',
                      date: _actualSettlementDate,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _actualSettlementDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2028),
                        );
                        if (picked != null) {
                          setState(() {
                            _actualSettlementDate = picked;
                            _selectedIpcPreset = 'Custom Audit';
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Delay duration indicator
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Delay Duration: $delayedDays Calendar Days (~${delayedMonths.toStringAsFixed(1)} Months)',
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Real-Time Output Calculation Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E2E5C),
                AppTheme.surfaceCard,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryLight.withAlpha(120)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL FINANCING CHARGES ACCRUED',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '₹${accruedInterestCr.toStringAsFixed(3)} Cr',
                      style: const TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                currencyFormat.format(accruedInterestRupees.round()),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Divider(color: AppTheme.border, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Base Certified Principal:',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  Text(
                    '₹${_calculatorPrincipalCr.toStringAsFixed(2)} Cr',
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Employer Liability (P + I):',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  Text(
                    '₹${totalEmployerLiabilityCr.toStringAsFixed(3)} Cr',
                    style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daily Interest Accrual Burn Rate:',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  Text(
                    '${currencyFormat.format(dailyInterestBurnRupees.round())} / day',
                    style: const TextStyle(
                        color: AppTheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Monthly Compounding Schedule Table
        _buildMonthlyCompoundingTable(
          principalRupees: principalRupees,
          monthlyRate: monthlyRate,
          totalMonths: delayedMonths,
          delayedDays: delayedDays,
        ),
        const SizedBox(height: 16),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy Cl. 14.8 Demand Letter',
                    style: TextStyle(fontSize: 11)),
                onPressed: () {
                  final text =
                      'FORMAL DEMAND FOR FINANCING CHARGES UNDER FIDIC SUB-CLAUSE 14.8\n\n'
                      'To: Oil India Limited (Employer)\n'
                      'Attn: Marcus Vance, P.E. (FIDIC Engineer)\n\n'
                      'Certificate Reference: $_selectedIpcPreset\n'
                      'Certified Principal: ₹${_calculatorPrincipalCr.toStringAsFixed(2)} Cr\n'
                      'Due Date (Sub-Clause 14.7): ${DateFormat('dd MMM yyyy').format(_paymentDueDate)}\n'
                      'Actual / Assessment Date: ${DateFormat('dd MMM yyyy').format(_actualSettlementDate)}\n'
                      'Delay Period: $delayedDays Days\n'
                      'Statutory Rate: RBI Repo ${_benchmarkRatePercentage.toStringAsFixed(2)}% + 3.00% = ${effectiveAnnualRate.toStringAsFixed(2)}% p.a. (compounded monthly)\n'
                      'Accrued Financing Charges: ${currencyFormat.format(accruedInterestRupees.round())} (₹${accruedInterestCr.toStringAsFixed(3)} Cr)\n'
                      'Total Amount Due: ₹${totalEmployerLiabilityCr.toStringAsFixed(3)} Cr\n\n'
                      'Please ensure immediate remittance to avoid escalation under Sub-Clause 20.4.';

                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'FIDIC Clause 14.8 Formal Demand Notice copied to clipboard.'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.attach_file_rounded, size: 16),
                label: const Text('Attach to Claim',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'FIDIC Cl. 14.8 calculation attached to active claim register for adjudication.'),
                      backgroundColor: AppTheme.surfaceCard,
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildIpcPresetChip(
      String label, double principalCr, DateTime due, DateTime actual) {
    final isSelected = _selectedIpcPreset == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIpcPreset = label;
          _calculatorPrincipalCr = principalCr;
          _paymentDueDate = due;
          _actualSettlementDate = actual;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight.withAlpha(40)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerBox({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            Text(
              title,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(date),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppTheme.primaryLight),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyCompoundingTable({
    required double principalRupees,
    required double monthlyRate,
    required double totalMonths,
    required int delayedDays,
  }) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final int monthsCount = math.min(6, math.max(1, totalMonths.ceil()));

    double runningPrincipal = principalRupees;

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
            'MONTHLY COMPOUNDING SCHEDULE PROGRESSION',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: AppTheme.border, width: 0.8),
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2.0),
              2: FlexColumnWidth(2.0),
              3: FlexColumnWidth(2.0),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.surface),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('Month',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('Opening Bal.',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('Interest Accrued',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('Closing Bal.',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              ...List.generate(monthsCount, (mIdx) {
                final monthNumber = mIdx + 1;
                final opening = runningPrincipal;
                final monthInterest = opening * monthlyRate;
                final closing = opening + monthInterest;
                runningPrincipal = closing;

                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('M$monthNumber',
                          style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(currency.format(opening.round()),
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 10)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(currency.format(monthInterest.round()),
                          style: const TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(currency.format(closing.round()),
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 10)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: FIDIC CL. 20 FRAMEWORK & ESCALATION TREE
  // ==========================================================================
  Widget _buildFidicFrameworkTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Visual Dispute Resolution Tree
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
              const Row(
                children: [
                  Icon(Icons.account_tree_rounded,
                      color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'FIDIC CLAUSE 20 STATUTORY ESCALATION TREE',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildEscalationTreeNode(
                step: '1',
                title: 'Delay Event / Hindrance Occurs',
                description:
                    'Contractor suffers delay or incurs additional cost due to Employer risk event (e.g. Cl. 2.1 ROW, Cl. 1.9 Drawings, Cl. 8.4 Weather).',
                color: AppTheme.textSecondary,
                isCompleted: true,
              ),
              _buildEscalationTreeConnector(),
              _buildEscalationTreeNode(
                step: '2',
                title: 'FIDIC Sub-Clause 20.1: Notice of Claim (< 28 Days)',
                description:
                    'Mandatory condition precedent: Contractor MUST give notice within 28 days of event awareness. Time-bar forfeits claim if missed.',
                color: const Color(0xFF38BDF8),
                isCompleted: true,
              ),
              _buildEscalationTreeConnector(),
              _buildEscalationTreeNode(
                step: '3',
                title: 'Sub-Clause 20.1: Detailed Claim Dossier (< 42 Days)',
                description:
                    'Submission of fully detailed claim, contemporary site diary records, Primavera P6 TIA critical path analysis, and cost vouchers.',
                color: const Color(0xFFFFB95F),
                isCompleted: true,
              ),
              _buildEscalationTreeConnector(),
              _buildEscalationTreeNode(
                step: '4',
                title: 'Sub-Clause 3.5: Engineer Determination (< 42 Days)',
                description:
                    'Engineer consults with both Parties to reach agreement. If no agreement, Engineer issues a fair determination.',
                color: const Color(0xFFA78BFA),
                isCompleted: true,
              ),
              _buildEscalationTreeConnector(),
              _buildEscalationTreeNode(
                step: '5',
                title: 'Sub-Clause 20.4: DAB Formal Referral (84-Day Ruling)',
                description:
                    'Dispute referred to 1- or 3-member DAB. DAB conducts site visits, oral hearings, and issues binding written ruling within 84 days.',
                color: const Color(0xFFFB923C),
                isCompleted: true,
              ),
              _buildEscalationTreeConnector(),
              _buildEscalationTreeNode(
                step: '6',
                title: 'Sub-Clause 20.5: Amicable Settlement Window (56 Days)',
                description:
                    'If either Party serves Notice of Dissatisfaction, mandatory 56-day cooling period for conciliation before arbitration commences.',
                color: const Color(0xFF4EDEA3),
                isCompleted: true,
              ),
              _buildEscalationTreeConnector(),
              _buildEscalationTreeNode(
                step: '7',
                title: 'Sub-Clause 20.6: Final Binding Arbitration',
                description:
                    'Final settlement by international arbitration under ICC Rules or domestic arbitration under Indian Arbitration and Conciliation Act 1996.',
                color: const Color(0xFFFF5252),
                isCompleted: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Statutory Checklist
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'CONTRACTOR TIME-BAR COMPLIANCE CHECKLIST',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 10),
              _ChecklistRow(
                text:
                    'Notice served within 28 calendar days of awareness (Sub-Clause 20.1)',
                isChecked: true,
              ),
              _ChecklistRow(
                text:
                    'Contemporary Site Diary records kept contemporaneously (Sub-Clause 4.20 / 20.1)',
                isChecked: true,
              ),
              _ChecklistRow(
                text:
                    'Detailed claim submitted within 42 days of notice (Sub-Clause 20.1)',
                isChecked: true,
              ),
              _ChecklistRow(
                text:
                    'Financing charges calculated compounded monthly (Sub-Clause 14.8)',
                isChecked: true,
              ),
              _ChecklistRow(
                text:
                    'Notice of Dissatisfaction issued within 28 days of DAB decision (Sub-Clause 20.4)',
                isChecked: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildEscalationTreeNode({
    required String step,
    required String title,
    required String description,
    required Color color,
    required bool isCompleted,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(40),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEscalationTreeConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      width: 2,
      height: 16,
      color: AppTheme.border,
    );
  }
}

// ============================================================================
// MODAL BOTTOM SHEETS & AUXILIARY WIDGETS
// ============================================================================

/// Modal Bottom Sheet to register a new Cl. 20.1 Notice of Claim
class _NewNoticeOfClaimBottomSheet extends StatefulWidget {
  final int nextClaimNumber;
  final ValueChanged<DabClaimModel> onSubmit;

  const _NewNoticeOfClaimBottomSheet({
    required this.nextClaimNumber,
    required this.onSubmit,
  });

  @override
  State<_NewNoticeOfClaimBottomSheet> createState() =>
      _NewNoticeOfClaimBottomSheetState();
}

class _NewNoticeOfClaimBottomSheetState
    extends State<_NewNoticeOfClaimBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _claimId;
  final _titleCtrl = TextEditingController();
  final _clauseCtrl = TextEditingController(
      text: 'FIDIC Cl. 20.1 (Notice within 28 days) & Cl. 2.1 (Right of Access)');
  final _amountCtrl = TextEditingController(text: '8.40');
  final _eotCtrl = TextEditingController(text: '21');
  final _chainageCtrl = TextEditingController(text: 'Ch 44+200 to 52+600');
  final _workPackageCtrl =
      TextEditingController(text: 'WP-01 Mainline Trenching Spread');
  final _scopeCtrl = TextEditingController();

  DateTime _noticeDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _claimId = 'CLM-2026-0${widget.nextClaimNumber}';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _clauseCtrl.dispose();
    _amountCtrl.dispose();
    _eotCtrl.dispose();
    _chainageCtrl.dispose();
    _workPackageCtrl.dispose();
    _scopeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_alert_rounded,
                      color: AppTheme.primaryLight, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serve Notice of Claim ($_claimId)',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'FIDIC Red Book Sub-Clause 20.1 Statutory 28-Day Initiation',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppTheme.border, height: 20),
            Expanded(
              child: ListView(
                children: [
                  const Text('Claim Title:',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _titleCtrl,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Unforeseen Gas Pipeline Interception at Station SV-08',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Title is mandatory'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  const Text('FIDIC Contract Clause Reference:',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _clauseCtrl,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'e.g. FIDIC Cl. 20.1 & Cl. 4.12 Unforeseeable Physical Conditions',
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Amount Claimed (₹ Cr):',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _amountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'e.g. 18.40',
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
                            const Text('EOT Requested (Days):',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _eotCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'e.g. 45',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Chainage Location:',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _chainageCtrl,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Ch 24+500',
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
                            const Text('Work Package:',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _workPackageCtrl,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'WP-01 Mainline',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Text('Notice Date (Event Occurrence):',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _noticeDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2028),
                      );
                      if (picked != null) {
                        setState(() => _noticeDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(_noticeDate),
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontSize: 13),
                          ),
                          const Icon(Icons.calendar_today_rounded,
                              size: 16, color: AppTheme.primaryLight),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Contemporaneous Delay Description:',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _scopeCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Describe hindrance, site obstruction, plant standby...',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size.fromHeight(46),
              ),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  final amount = double.tryParse(_amountCtrl.text.trim()) ?? 5.0;
                  final eot = int.tryParse(_eotCtrl.text.trim()) ?? 14;

                  final newClaim = DabClaimModel(
                    id: _claimId,
                    title: _titleCtrl.text.trim(),
                    clauseReference: _clauseCtrl.text.trim(),
                    amountClaimedCr: amount,
                    amountAwardedCr: null,
                    eotRequestedDays: eot,
                    eotAwardedDays: null,
                    status: DabWorkflowStage.noticeServed,
                    noticeDate: DateFormat('dd MMM yyyy').format(_noticeDate),
                    noticeDayElapsed: 1,
                    noticeTimeBarDaysRemaining: 27,
                    detailedSubmissionDeadline: DateFormat('dd MMM yyyy')
                        .format(_noticeDate.add(const Duration(days: 42))),
                    workPackage: _workPackageCtrl.text.trim(),
                    chainageLocation: _chainageCtrl.text.trim(),
                    contractorJV: 'L&T Hydrocarbon Engineering JV',
                    clientEmployer: 'Oil India Limited (OIL)',
                    engineer: 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
                    scopeSummary: _scopeCtrl.text.trim().isNotEmpty
                        ? _scopeCtrl.text.trim()
                        : 'Initial notice served per FIDIC Cl. 20.1.',
                    dabPanel: [
                      'Justice (Retd.) B. N. Srikrishna (Presiding)',
                      'Dr. S. Mukherjee, FICE (Technical)',
                      'Er. K. V. Ramanathan, FCIArb (Contracts)',
                    ],
                    hearingDetails: null,
                    decisionDate: null,
                    decisionRuling: null,
                    costBreakdown: {
                      'Estimated Standby Rate': amount * 0.6,
                      'Overheads Prolongation': amount * 0.4,
                    },
                    evidenceList: [
                      EvidenceItem(
                        id: 'EVD-$_claimId-01',
                        title: 'Notice of Claim Transmittal Receipt',
                        category: EvidenceCategory.statutoryNotice,
                        fileType: 'PDF',
                        fileSize: '1.1 MB',
                        date: DateFormat('dd MMM yyyy').format(_noticeDate),
                        referenceNumber: 'NOT-$_claimId-01',
                        verifiedBy: 'Marcus Vance, P.E.',
                        description: 'Formal 28-day notice receipt endorsed.',
                        sha256Hash:
                            '${math.Random().nextInt(999999999)}abcdef1234567890',
                      ),
                    ],
                    weatherLogs: [],
                    siteDiaryRefs: [],
                    evidenceCoverageScore: 80.0,
                  );

                  widget.onSubmit(newClaim);
                  Navigator.pop(context);
                }
              },
              child: const Text('Serve Formal Notice & Add to Register',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper Card for FIDIC Clause Explanations
class _FidicClauseGuideCard extends StatelessWidget {
  final String clause;
  final String title;
  final String content;

  const _FidicClauseGuideCard({
    required this.clause,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  clause,
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Row for Contractor Compliance Checklist
class _ChecklistRow extends StatelessWidget {
  final String text;
  final bool isChecked;

  const _ChecklistRow({
    required this.text,
    required this.isChecked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: isChecked ? AppTheme.tertiary : AppTheme.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
