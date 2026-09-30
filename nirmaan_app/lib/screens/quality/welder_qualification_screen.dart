import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// ENUMS & STANDARDS CONSTANTS
// ============================================================================

enum WeldingProcessType {
  smawCellulosic,
  gmawStt,
  gtawTig,
  fcawGas,
  sawDoubleJoint,
}

extension WeldingProcessTypeExt on WeldingProcessType {
  String get displayName {
    switch (this) {
      case WeldingProcessType.smawCellulosic:
        return 'SMAW Cellulosic Downhill';
      case WeldingProcessType.gmawStt:
        return 'GMAW STT (Semi-Auto)';
      case WeldingProcessType.gtawTig:
        return 'GTAW TIG (Argon Backup)';
      case WeldingProcessType.fcawGas:
        return 'FCAW-G (Flux-Cored Gas)';
      case WeldingProcessType.sawDoubleJoint:
        return 'SAW (Submerged Arc DJ)';
    }
  }

  String get shortName {
    switch (this) {
      case WeldingProcessType.smawCellulosic:
        return 'SMAW';
      case WeldingProcessType.gmawStt:
        return 'GMAW STT';
      case WeldingProcessType.gtawTig:
        return 'GTAW TIG';
      case WeldingProcessType.fcawGas:
        return 'FCAW';
      case WeldingProcessType.sawDoubleJoint:
        return 'SAW';
    }
  }

  String get electrodeClass {
    switch (this) {
      case WeldingProcessType.smawCellulosic:
        return 'E6010 root / E8010-P1 fill-cap';
      case WeldingProcessType.gmawStt:
        return 'AWS A5.18 ER70S-6 / ER80S-G';
      case WeldingProcessType.gtawTig:
        return 'AWS A5.18 ER70S-6 + 99.995% Ar';
      case WeldingProcessType.fcawGas:
        return 'AWS A5.29 E81T1-K2M';
      case WeldingProcessType.sawDoubleJoint:
        return 'AWS A5.23 EA2 / F8A4-EA2-A2';
    }
  }

  Color get color {
    switch (this) {
      case WeldingProcessType.smawCellulosic:
        return const Color(0xFF0284C7);
      case WeldingProcessType.gmawStt:
        return const Color(0xFFFFB95F);
      case WeldingProcessType.gtawTig:
        return const Color(0xFF4EDEA3);
      case WeldingProcessType.fcawGas:
        return const Color(0xFFA78BFA);
      case WeldingProcessType.sawDoubleJoint:
        return const Color(0xFF38BDF8);
    }
  }
}

enum QualifiedPosition {
  pos5G,
  pos6G,
  pos6GR,
  pos1G2G,
}

extension QualifiedPositionExt on QualifiedPosition {
  String get code {
    switch (this) {
      case QualifiedPosition.pos5G:
        return '5G Fixed';
      case QualifiedPosition.pos6G:
        return '6G Inclined 45°';
      case QualifiedPosition.pos6GR:
        return '6GR Restricted';
      case QualifiedPosition.pos1G2G:
        return '1G / 2G Rolled';
    }
  }

  String get description {
    switch (this) {
      case QualifiedPosition.pos5G:
        return 'Horizontal pipe fixed, vertical progression (Downhill)';
      case QualifiedPosition.pos6G:
        return 'Pipe fixed at 45° inclination (All positions qualified)';
      case QualifiedPosition.pos6GR:
        return '45° pipe with restriction ring (Branches & T-joints)';
      case QualifiedPosition.pos1G2G:
        return 'Rotated horizontal or vertical axis pipe';
    }
  }
}

enum WelderStatus {
  active,
  renewalDue,
  suspended,
  expired,
}

extension WelderStatusExt on WelderStatus {
  String get label {
    switch (this) {
      case WelderStatus.active:
        return 'ACTIVE';
      case WelderStatus.renewalDue:
        return 'RENEWAL DUE';
      case WelderStatus.suspended:
        return 'SUSPENDED';
      case WelderStatus.expired:
        return 'EXPIRED';
    }
  }

  Color get color {
    switch (this) {
      case WelderStatus.active:
        return const Color(0xFF4EDEA3);
      case WelderStatus.renewalDue:
        return const Color(0xFFFFB95F);
      case WelderStatus.suspended:
        return const Color(0xFFFF5252);
      case WelderStatus.expired:
        return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case WelderStatus.active:
        return Icons.verified_user_rounded;
      case WelderStatus.renewalDue:
        return Icons.timer_outlined;
      case WelderStatus.suspended:
        return Icons.warning_amber_rounded;
      case WelderStatus.expired:
        return Icons.cancel_outlined;
    }
  }
}

enum NdtTestStatus {
  accepted,
  rejected,
  pending,
}

// ============================================================================
// DATA MODELS
// ============================================================================

class WelderQualificationRecord {
  final String welderId; // e.g. WLD-KPL-084
  final String name; // e.g. Rajeshwar Sharma
  final String stampId; // Hard stamp ID: RS-084
  final String contractor; // Kalpataru, L&T, Punj Lloyd, Corrtech
  final WeldingProcessType process;
  final QualifiedPosition position;
  final String diameterRange; // e.g. >= 12.75" (323.9mm) to Unlimited
  final String thicknessRange; // e.g. 4.8mm to 25.4mm
  final String standard; // API 1104 Cl. 6 / ASME Sec IX QW-300
  final String pqrReference; // PQR-2024-X70-01
  final String qualifiedWps; // WPS-OIL-SMAW-01

  // NDT Test Results
  final NdtTestStatus rtResult;
  final String rtDetails; // RT Class 1 per API 1104 Clause 9
  final NdtTestStatus autResult;
  final String autDetails; // AUT zonal discrimination
  final NdtTestStatus bendTestResult;
  final String bendTestDetails; // 4x Guided Root/Face Bend (180° mandrel, 0 defects > 3.2mm)
  final NdtTestStatus nickBreakResult;

  // Performance KPIs
  int cumulativeJoints;
  int repairedJoints;
  double get repairRate => cumulativeJoints > 0 ? (repairedJoints / cumulativeJoints) * 100 : 0.0;
  DateTime lastWeldDate;
  DateTime qualificationDate;
  WelderStatus status;

  // Sign-off credentials
  final String tpiaInspector; // e.g. A. K. Barua (EIL Level III)
  final String clientEngineer; // e.g. P. Gogoi (Oil India Ltd)
  final String verificationHash;

  WelderQualificationRecord({
    required this.welderId,
    required this.name,
    required this.stampId,
    required this.contractor,
    required this.process,
    required this.position,
    required this.diameterRange,
    required this.thicknessRange,
    required this.standard,
    required this.pqrReference,
    required this.qualifiedWps,
    required this.rtResult,
    required this.rtDetails,
    required this.autResult,
    required this.autDetails,
    required this.bendTestResult,
    required this.bendTestDetails,
    required this.nickBreakResult,
    required this.cumulativeJoints,
    required this.repairedJoints,
    required this.lastWeldDate,
    required this.qualificationDate,
    required this.status,
    required this.tpiaInspector,
    required this.clientEngineer,
    required this.verificationHash,
  });

  /// Continuity expiry is 6 months (180 days) from last active weld per API 1104 Cl. 6.8 & ASME IX QW-322
  DateTime get continuityExpiryDate => lastWeldDate.add(const Duration(days: 180));
  int get daysUntilExpiry => continuityExpiryDate.difference(DateTime.now()).inDays;
}

class WeldingProcedureSpecification {
  final String wpsId; // WPS-OIL-SMAW-01
  final String pqrNumber; // PQR-2024-X70-01
  final String title;
  final String standard; // API 1104 (22nd Ed) / ASME Sec IX
  final WeldingProcessType process;
  final String progression; // Downhill / Uphill
  final String baseMaterial; // API 5L Grade X70M PSL2
  final String diameterRange; // 18" (457 mm) to 48" (1219 mm)
  final String thicknessRange; // 6.4 mm to 25.4 mm
  final String jointDesign; // Single V-Groove 60° (30° ± 2.5°), Root face 1.6mm
  final String rootFiller; // AWS A5.1 E6010 Cellulosic (3.2mm)
  final String fillCapFiller; // AWS A5.5 E8010-P1 (4.0mm / 4.8mm)
  final String shieldingGas; // N/A (SMAW) or 99.995% Argon (GTAW)
  final double minPreheatTempC; // 100°C min
  final double maxInterpassTempC; // 250°C max
  final String pwhtRequirement; // None for WT <= 19.1mm per API 1104
  final double heatInputMin; // 0.8 kJ/mm
  final double heatInputMax; // 1.65 kJ/mm
  final String approvalStatus; // Approved by EIL & OIL
  final String approvedDate;
  final List<WpsPassParameter> passParameters;

  const WeldingProcedureSpecification({
    required this.wpsId,
    required this.pqrNumber,
    required this.title,
    required this.standard,
    required this.process,
    required this.progression,
    required this.baseMaterial,
    required this.diameterRange,
    required this.thicknessRange,
    required this.jointDesign,
    required this.rootFiller,
    required this.fillCapFiller,
    required this.shieldingGas,
    required this.minPreheatTempC,
    required this.maxInterpassTempC,
    required this.pwhtRequirement,
    required this.heatInputMin,
    required this.heatInputMax,
    required this.approvalStatus,
    required this.approvedDate,
    required this.passParameters,
  });
}

class WpsPassParameter {
  final String passLayer; // Root, Hot Pass, Fill 1, Fill 2, Cap
  final String process;
  final String electrodeClass;
  final double electrodeDiameterMm;
  final String polarity;
  final int currentMinAmp;
  final int currentMaxAmp;
  final int voltageMin;
  final int voltageMax;
  final double travelSpeedMin; // cm/min
  final double travelSpeedMax;
  final double heatInputKjMm;

  const WpsPassParameter({
    required this.passLayer,
    required this.process,
    required this.electrodeClass,
    required this.electrodeDiameterMm,
    required this.polarity,
    required this.currentMinAmp,
    required this.currentMaxAmp,
    required this.voltageMin,
    required this.voltageMax,
    required this.travelSpeedMin,
    required this.travelSpeedMax,
    required this.heatInputKjMm,
  });
}

class NdtTestCouponRecord {
  final String couponId; // TC-2026-KPL-084
  final String welderId;
  final String welderName;
  final String pipeSize; // 18" OD x 14.3mm WT
  final String steelGrade; // API 5L X70M
  final String testDate;
  final String position; // 5G Downhill
  final String visualInspectionResult; // Passed: Uniform crown 1.8mm, root penetration full
  final String rtReportNo; // RT-EIL-2026-441
  final String rtInterpretation; // Class 1 Acceptable: 0 cracks, 0 LOF, porosity < 1.2mm
  final double rtFilmDensity; // 2.65 H&D
  final String autReportNo; // AUT-KPL-902
  final String autZonalResult; // Root, L1, L2, Cap: All clear within ASME Sec IX acceptance
  final String bendTestResult; // 2 Root Bends, 2 Face Bends: 180° mandrel, 0 tears
  final double tensileUltimateMpa; // 625 MPa (Specified Min 570 MPa)
  final String tpiaWitness; // EIL QA/QC Level III

  const NdtTestCouponRecord({
    required this.couponId,
    required this.welderId,
    required this.welderName,
    required this.pipeSize,
    required this.steelGrade,
    required this.testDate,
    required this.position,
    required this.visualInspectionResult,
    required this.rtReportNo,
    required this.rtInterpretation,
    required this.rtFilmDensity,
    required this.autReportNo,
    required this.autZonalResult,
    required this.bendTestResult,
    required this.tensileUltimateMpa,
    required this.tpiaWitness,
  });
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class WelderQualificationScreen extends StatefulWidget {
  const WelderQualificationScreen({super.key});

  @override
  State<WelderQualificationScreen> createState() => _WelderQualificationScreenState();
}

class _WelderQualificationScreenState extends State<WelderQualificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedContractor = 'ALL';
  String _selectedProcess = 'ALL';
  String _selectedStatus = 'ALL';
  String _selectedPosition = 'ALL';

  // Industry threshold: Max allowable repair rate
  static const double kRepairRateTargetPercent = 2.0;

  // Master Data Lists
  late List<WelderQualificationRecord> _welders;
  late List<WeldingProcedureSpecification> _wpsList;
  late List<NdtTestCouponRecord> _testCoupons;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final now = DateTime.now();

    _welders = [
      WelderQualificationRecord(
        welderId: 'WLD-KPL-084',
        name: 'Rajeshwar Sharma',
        stampId: 'RS-084',
        contractor: 'Kalpataru Projects Ltd',
        process: WeldingProcessType.smawCellulosic,
        position: QualifiedPosition.pos5G,
        diameterRange: '>= 12.75" (323.9mm) to Unlimited',
        thicknessRange: '4.8 mm to 25.4 mm WT',
        standard: 'API 1104 (22nd Ed) Cl. 6',
        pqrReference: 'PQR-2024-X70-01',
        qualifiedWps: 'WPS-OIL-SMAW-01',
        rtResult: NdtTestStatus.accepted,
        rtDetails: 'RT Class 1 per API 1104 §9 (IQI Wire 11 visible)',
        autResult: NdtTestStatus.accepted,
        autDetails: 'AUT Phased Array Zonal: Zero LOF/LOP',
        bendTestResult: NdtTestStatus.accepted,
        bendTestDetails: '4x Guided Bend (2 Root, 2 Face) 180° No tears',
        nickBreakResult: NdtTestStatus.accepted,
        cumulativeJoints: 540,
        repairedJoints: 6, // 1.11% repair rate
        lastWeldDate: now.subtract(const Duration(days: 4)),
        qualificationDate: DateTime(2025, 3, 15),
        status: WelderStatus.active,
        tpiaInspector: 'A. K. Barua (EIL Level III)',
        clientEngineer: 'P. Gogoi (Oil India Ltd)',
        verificationHash: _generateCertHash('WLD-KPL-084', 'Rajeshwar Sharma', 'RS-084'),
      ),
      WelderQualificationRecord(
        welderId: 'WLD-LT-102',
        name: 'Gurpreet Singh',
        stampId: 'GS-102',
        contractor: 'L&T Hydrocarbon',
        process: WeldingProcessType.gmawStt,
        position: QualifiedPosition.pos6G,
        diameterRange: '>= 2.375" (60.3mm) to Unlimited',
        thicknessRange: '3.2 mm to 28.0 mm WT',
        standard: 'API 1104 / ASME Sec IX QW-300',
        pqrReference: 'PQR-2024-STT-03',
        qualifiedWps: 'WPS-OIL-GMAW-STT-03',
        rtResult: NdtTestStatus.accepted,
        rtDetails: 'RT Class 1 Approved (D4 Film, Density 2.8 H&D)',
        autResult: NdtTestStatus.accepted,
        autDetails: 'AUT Phased Array Zonal: Complete root fusion',
        bendTestResult: NdtTestStatus.accepted,
        bendTestDetails: 'Guided Side Bend 180° 4 specimens passed',
        nickBreakResult: NdtTestStatus.accepted,
        cumulativeJoints: 612,
        repairedJoints: 5, // 0.82% repair rate
        lastWeldDate: now.subtract(const Duration(days: 2)),
        qualificationDate: DateTime(2025, 1, 10),
        status: WelderStatus.active,
        tpiaInspector: 'M. S. Roy (EIL Level III)',
        clientEngineer: 'D. Bordoloi (Oil India Ltd)',
        verificationHash: _generateCertHash('WLD-LT-102', 'Gurpreet Singh', 'GS-102'),
      ),
      WelderQualificationRecord(
        welderId: 'WLD-PL-045',
        name: 'Bikram Bora',
        stampId: 'BB-045',
        contractor: 'Punj Lloyd Ltd',
        process: WeldingProcessType.gtawTig,
        position: QualifiedPosition.pos6GR,
        diameterRange: 'All Diameters (Tie-in & Station Headers)',
        thicknessRange: '2.5 mm to 32.0 mm WT',
        standard: 'ASME Sec IX QW-304 & API 1104',
        pqrReference: 'PQR-2024-TIG-02',
        qualifiedWps: 'WPS-OIL-GTAW-SMAW-02',
        rtResult: NdtTestStatus.accepted,
        rtDetails: '100% Radiography Class 1 (Zero porosity)',
        autResult: NdtTestStatus.accepted,
        autDetails: 'PAUT + TOFD Dual Probe passed',
        bendTestResult: NdtTestStatus.accepted,
        bendTestDetails: '4x Root/Face Bend 180° sound metal',
        nickBreakResult: NdtTestStatus.accepted,
        cumulativeJoints: 218,
        repairedJoints: 2, // 0.92% repair rate
        lastWeldDate: now.subtract(const Duration(days: 12)),
        qualificationDate: DateTime(2025, 2, 20),
        status: WelderStatus.active,
        tpiaInspector: 'S. K. Saikia (DNV-GL / EIL)',
        clientEngineer: 'P. Gogoi (Oil India Ltd)',
        verificationHash: _generateCertHash('WLD-PL-045', 'Bikram Bora', 'BB-045'),
      ),
      WelderQualificationRecord(
        welderId: 'WLD-KPL-092',
        name: 'Manoj V. Kumar',
        stampId: 'MK-092',
        contractor: 'Kalpataru Projects Ltd',
        process: WeldingProcessType.smawCellulosic,
        position: QualifiedPosition.pos5G,
        diameterRange: '>= 12.75" (323.9mm) to Unlimited',
        thicknessRange: '4.8 mm to 22.0 mm WT',
        standard: 'API 1104 (22nd Ed) Cl. 6',
        pqrReference: 'PQR-2024-X70-01',
        qualifiedWps: 'WPS-OIL-SMAW-01',
        rtResult: NdtTestStatus.accepted,
        rtDetails: 'RT Class 1 per API 1104 Clause 9',
        autResult: NdtTestStatus.accepted,
        autDetails: 'AUT Zonal: Incomplete Fusion < 10mm limit',
        bendTestResult: NdtTestStatus.accepted,
        bendTestDetails: 'Guided Bend tests passed (No cracks)',
        nickBreakResult: NdtTestStatus.accepted,
        cumulativeJoints: 430,
        repairedJoints: 8, // 1.86% repair rate (approaching limit)
        lastWeldDate: now.subtract(const Duration(days: 165)), // Expiring in 15 days!
        qualificationDate: DateTime(2024, 11, 5),
        status: WelderStatus.renewalDue,
        tpiaInspector: 'A. K. Barua (EIL Level III)',
        clientEngineer: 'P. Gogoi (Oil India Ltd)',
        verificationHash: _generateCertHash('WLD-KPL-092', 'Manoj V. Kumar', 'MK-092'),
      ),
      WelderQualificationRecord(
        welderId: 'WLD-COR-118',
        name: 'Suresh Patil',
        stampId: 'SP-118',
        contractor: 'Corrtech Energy',
        process: WeldingProcessType.fcawGas,
        position: QualifiedPosition.pos5G,
        diameterRange: '>= 8.625" (219.1mm) to Unlimited',
        thicknessRange: '6.4 mm to 26.0 mm WT',
        standard: 'API 1104 Appendix A / ASME Sec IX',
        pqrReference: 'PQR-2024-FCAW-04',
        qualifiedWps: 'WPS-OIL-FCAW-04',
        rtResult: NdtTestStatus.accepted,
        rtDetails: 'RT Class 1 acceptable',
        autResult: NdtTestStatus.accepted,
        autDetails: 'AUT Phased Array verification clear',
        bendTestResult: NdtTestStatus.accepted,
        bendTestDetails: '4x Bend tests acceptable',
        nickBreakResult: NdtTestStatus.accepted,
        cumulativeJoints: 320,
        repairedJoints: 9, // 2.81% repair rate (Exceeded 2.0% target!)
        lastWeldDate: now.subtract(const Duration(days: 8)),
        qualificationDate: DateTime(2025, 4, 1),
        status: WelderStatus.suspended, // Suspended due to excessive cut-out rate
        tpiaInspector: 'H. N. Deka (EIL Level III)',
        clientEngineer: 'R. K. Hazarika (OIL)',
        verificationHash: _generateCertHash('WLD-COR-118', 'Suresh Patil', 'SP-118'),
      ),
      WelderQualificationRecord(
        welderId: 'WLD-LT-115',
        name: 'Mohammad Farooq',
        stampId: 'MF-115',
        contractor: 'L&T Hydrocarbon',
        process: WeldingProcessType.smawCellulosic,
        position: QualifiedPosition.pos5G,
        diameterRange: '>= 12.75" to Unlimited',
        thicknessRange: '4.8 mm to 25.4 mm WT',
        standard: 'API 1104 (22nd Ed) Cl. 6',
        pqrReference: 'PQR-2024-X70-01',
        qualifiedWps: 'WPS-OIL-SMAW-01',
        rtResult: NdtTestStatus.accepted,
        rtDetails: 'RT Class 1 Certified',
        autResult: NdtTestStatus.accepted,
        autDetails: 'AUT verified sound weld',
        bendTestResult: NdtTestStatus.accepted,
        bendTestDetails: '4x Root/Face Bend specimens accepted',
        nickBreakResult: NdtTestStatus.accepted,
        cumulativeJoints: 488,
        repairedJoints: 6, // 1.23% repair rate
        lastWeldDate: now.subtract(const Duration(days: 3)),
        qualificationDate: DateTime(2025, 2, 14),
        status: WelderStatus.active,
        tpiaInspector: 'M. S. Roy (EIL Level III)',
        clientEngineer: 'D. Bordoloi (Oil India Ltd)',
        verificationHash: _generateCertHash('WLD-LT-115', 'Mohammad Farooq', 'MF-115'),
      ),
      WelderQualificationRecord(
        welderId: 'WLD-PL-058',
        name: 'Tapan Hazarika',
        stampId: 'TH-058',
        contractor: 'Punj Lloyd Ltd',
        process: WeldingProcessType.sawDoubleJoint,
        position: QualifiedPosition.pos1G2G,
        diameterRange: '18" (457 mm) to 36" (914 mm) Double Jointing',
        thicknessRange: '8.0 mm to 25.4 mm WT',
        standard: 'API 1104 / ASME Sec IX QW-300',
        pqrReference: 'PQR-2024-SAW-05',
        qualifiedWps: 'WPS-OIL-SAW-DJ-04',
        rtResult: NdtTestStatus.accepted,
        rtDetails: '100% Real-Time Radioscopy & RT Class 1',
        autResult: NdtTestStatus.accepted,
        autDetails: 'Submerged Arc continuous zonal UT pass',
        bendTestResult: NdtTestStatus.accepted,
        bendTestDetails: 'Guided Side Bend 180° passed',
        nickBreakResult: NdtTestStatus.accepted,
        cumulativeJoints: 890,
        repairedJoints: 7, // 0.79% repair rate
        lastWeldDate: now.subtract(const Duration(days: 1)),
        qualificationDate: DateTime(2024, 12, 1),
        status: WelderStatus.active,
        tpiaInspector: 'S. K. Saikia (DNV-GL / EIL)',
        clientEngineer: 'P. Gogoi (Oil India Ltd)',
        verificationHash: _generateCertHash('WLD-PL-058', 'Tapan Hazarika', 'TH-058'),
      ),
      WelderQualificationRecord(
        welderId: 'WLD-KPL-077',
        name: 'Devendra Yadav',
        stampId: 'DY-077',
        contractor: 'Kalpataru Projects Ltd',
        process: WeldingProcessType.gmawStt,
        position: QualifiedPosition.pos6G,
        diameterRange: '>= 4.5" to Unlimited',
        thicknessRange: '3.2 mm to 24.0 mm WT',
        standard: 'API 1104 Cl. 6 & ASME Sec IX',
        pqrReference: 'PQR-2024-STT-03',
        qualifiedWps: 'WPS-OIL-GMAW-STT-03',
        rtResult: NdtTestStatus.accepted,
        rtDetails: 'RT Class 1 per API 1104',
        autResult: NdtTestStatus.accepted,
        autDetails: 'AUT Phased Array clear',
        bendTestResult: NdtTestStatus.accepted,
        bendTestDetails: 'Root/Face bend 180° passed',
        nickBreakResult: NdtTestStatus.accepted,
        cumulativeJoints: 180,
        repairedJoints: 3, // 1.67% repair rate
        lastWeldDate: now.subtract(const Duration(days: 195)), // > 180 days: EXPIRED!
        qualificationDate: DateTime(2024, 8, 10),
        status: WelderStatus.expired,
        tpiaInspector: 'A. K. Barua (EIL Level III)',
        clientEngineer: 'P. Gogoi (Oil India Ltd)',
        verificationHash: _generateCertHash('WLD-KPL-077', 'Devendra Yadav', 'DY-077'),
      ),
    ];

    _wpsList = [
      const WeldingProcedureSpecification(
        wpsId: 'WPS-OIL-SMAW-01',
        pqrNumber: 'PQR-2024-X70-01',
        title: 'Mainline Cross-Country Pipe-to-Pipe Girth Butt Weld',
        standard: 'API 1104 (22nd Ed) & OISD-141',
        process: WeldingProcessType.smawCellulosic,
        progression: 'Vertical Downhill',
        baseMaterial: 'API 5L Grade X70M PSL2 (457 mm OD x 14.3 mm WT)',
        diameterRange: '12.75" (323.9 mm) to Unlimited',
        thicknessRange: '4.8 mm to 25.4 mm WT',
        jointDesign: 'Single V-Groove: 60° Included Angle (30° ± 2.5°), Root Face 1.6 ± 0.8 mm, Root Gap 1.6 ± 0.8 mm',
        rootFiller: 'AWS A5.1 E6010 Cellulosic (3.2 mm Ø, DCEP)',
        fillCapFiller: 'AWS A5.5 E8010-P1 High Strength Cellulosic (4.0 & 4.8 mm Ø, DCEP)',
        shieldingGas: 'None (Electrode flux shielding)',
        minPreheatTempC: 100.0,
        maxInterpassTempC: 250.0,
        pwhtRequirement: 'None (WT <= 19.1 mm per API 1104 Clause 5.3.2.16)',
        heatInputMin: 0.78,
        heatInputMax: 1.55,
        approvalStatus: 'APPROVED (EIL Level III & OIL Resident Eng)',
        approvedDate: '15 Jan 2025',
        passParameters: [
          WpsPassParameter(
            passLayer: 'Pass 1 (Root / Stringer)',
            process: 'SMAW',
            electrodeClass: 'AWS A5.1 E6010',
            electrodeDiameterMm: 3.2,
            polarity: 'DCEP (+)',
            currentMinAmp: 85,
            currentMaxAmp: 125,
            voltageMin: 22,
            voltageMax: 28,
            travelSpeedMin: 22.0,
            travelSpeedMax: 32.0,
            heatInputKjMm: 0.85,
          ),
          WpsPassParameter(
            passLayer: 'Pass 2 (Hot Pass)',
            process: 'SMAW',
            electrodeClass: 'AWS A5.5 E8010-P1',
            electrodeDiameterMm: 4.0,
            polarity: 'DCEP (+)',
            currentMinAmp: 130,
            currentMaxAmp: 175,
            voltageMin: 24,
            voltageMax: 30,
            travelSpeedMin: 24.0,
            travelSpeedMax: 36.0,
            heatInputKjMm: 0.98,
          ),
          WpsPassParameter(
            passLayer: 'Pass 3-5 (Filler Layers)',
            process: 'SMAW',
            electrodeClass: 'AWS A5.5 E8010-P1',
            electrodeDiameterMm: 4.8,
            polarity: 'DCEP (+)',
            currentMinAmp: 140,
            currentMaxAmp: 195,
            voltageMin: 24,
            voltageMax: 32,
            travelSpeedMin: 18.0,
            travelSpeedMax: 26.0,
            heatInputKjMm: 1.25,
          ),
          WpsPassParameter(
            passLayer: 'Pass 6 (Cap / Cover Pass)',
            process: 'SMAW',
            electrodeClass: 'AWS A5.5 E8010-P1',
            electrodeDiameterMm: 4.0,
            polarity: 'DCEP (+)',
            currentMinAmp: 120,
            currentMaxAmp: 165,
            voltageMin: 23,
            voltageMax: 28,
            travelSpeedMin: 14.0,
            travelSpeedMax: 22.0,
            heatInputKjMm: 1.35,
          ),
        ],
      ),
      const WeldingProcedureSpecification(
        wpsId: 'WPS-OIL-GTAW-SMAW-02',
        pqrNumber: 'PQR-2024-TIG-02',
        title: 'Station Piping, Tie-Ins & Golden Weld Procedure',
        standard: 'ASME Section IX & ASME B31.8',
        process: WeldingProcessType.gtawTig,
        progression: 'Vertical Uphill',
        baseMaterial: 'API 5L X70M PSL2 / ASTM A106 Gr. B (All WT)',
        diameterRange: '2.0" (50.8 mm) to Unlimited',
        thicknessRange: '3.2 mm to 32.0 mm WT',
        jointDesign: 'Single V-Groove 60° - 75°, Root Face 1.2 ± 0.5 mm, Root Gap 2.4 ± 0.8 mm',
        rootFiller: 'AWS A5.18 ER70S-6 (2.4 mm wire)',
        fillCapFiller: 'AWS A5.5 E8018-G Low-Hydrogen Basic (3.2 & 4.0 mm, DCEP)',
        shieldingGas: 'Argon 99.995% High Purity (12-16 L/min flow)',
        minPreheatTempC: 120.0,
        maxInterpassTempC: 220.0,
        pwhtRequirement: 'Required for WT > 19.1 mm (600°C ± 15°C soaking 1 hr/inch)',
        heatInputMin: 0.95,
        heatInputMax: 1.85,
        approvalStatus: 'APPROVED (EIL TPIA & OIL Resident Engineer)',
        approvedDate: '22 Feb 2025',
        passParameters: [
          WpsPassParameter(
            passLayer: 'Pass 1 (TIG Root)',
            process: 'GTAW',
            electrodeClass: 'AWS A5.18 ER70S-6',
            electrodeDiameterMm: 2.4,
            polarity: 'DCEN (-)',
            currentMinAmp: 90,
            currentMaxAmp: 135,
            voltageMin: 12,
            voltageMax: 16,
            travelSpeedMin: 6.0,
            travelSpeedMax: 10.0,
            heatInputKjMm: 1.15,
          ),
          WpsPassParameter(
            passLayer: 'Pass 2 (TIG Hot Pass)',
            process: 'GTAW',
            electrodeClass: 'AWS A5.18 ER70S-6',
            electrodeDiameterMm: 2.4,
            polarity: 'DCEN (-)',
            currentMinAmp: 110,
            currentMaxAmp: 155,
            voltageMin: 13,
            voltageMax: 17,
            travelSpeedMin: 8.0,
            travelSpeedMax: 12.0,
            heatInputKjMm: 1.28,
          ),
          WpsPassParameter(
            passLayer: 'Pass 3-6 (SMAW Fill & Cap)',
            process: 'SMAW Low-H2',
            electrodeClass: 'AWS A5.5 E8018-G',
            electrodeDiameterMm: 3.2,
            polarity: 'DCEP (+)',
            currentMinAmp: 115,
            currentMaxAmp: 160,
            voltageMin: 22,
            voltageMax: 26,
            travelSpeedMin: 10.0,
            travelSpeedMax: 16.0,
            heatInputKjMm: 1.52,
          ),
        ],
      ),
      const WeldingProcedureSpecification(
        wpsId: 'WPS-OIL-GMAW-STT-03',
        pqrNumber: 'PQR-2024-STT-03',
        title: 'Semi-Automatic STT Root + Mechanized Fill/Cap',
        standard: 'API 1104 (22nd Ed) Appendix A',
        process: WeldingProcessType.gmawStt,
        progression: 'Vertical Downhill',
        baseMaterial: 'API 5L Grade X70M PSL2 (457 mm OD x 14.3 mm WT)',
        diameterRange: '16" (406.4 mm) to 48" (1219 mm)',
        thicknessRange: '6.4 mm to 28.0 mm WT',
        jointDesign: 'Modified J-Prep or Compound V-Groove: 45° bevel with 5° compound, Root Face 1.5mm',
        rootFiller: 'AWS A5.18 ER70S-6 (1.0 mm solid wire, STT power source)',
        fillCapFiller: 'AWS A5.28 ER80S-G (1.2 mm solid wire, Pulsed GMAW)',
        shieldingGas: 'Root: 100% CO2 (15 L/min); Fill/Cap: 85% Ar + 15% CO2 (20 L/min)',
        minPreheatTempC: 80.0,
        maxInterpassTempC: 240.0,
        pwhtRequirement: 'None',
        heatInputMin: 0.65,
        heatInputMax: 1.45,
        approvalStatus: 'APPROVED (EIL Level III & OIL Resident Eng)',
        approvedDate: '08 Feb 2025',
        passParameters: [
          WpsPassParameter(
            passLayer: 'Pass 1 (STT Root)',
            process: 'GMAW-STT',
            electrodeClass: 'AWS A5.18 ER70S-6',
            electrodeDiameterMm: 1.0,
            polarity: 'DCEP (+)',
            currentMinAmp: 120,
            currentMaxAmp: 160,
            voltageMin: 16,
            voltageMax: 20,
            travelSpeedMin: 28.0,
            travelSpeedMax: 42.0,
            heatInputKjMm: 0.72,
          ),
          WpsPassParameter(
            passLayer: 'Pass 2 (Pulsed GMAW Hot Pass)',
            process: 'P-GMAW',
            electrodeClass: 'AWS A5.28 ER80S-G',
            electrodeDiameterMm: 1.2,
            polarity: 'DCEP (+)',
            currentMinAmp: 170,
            currentMaxAmp: 230,
            voltageMin: 22,
            voltageMax: 27,
            travelSpeedMin: 32.0,
            travelSpeedMax: 48.0,
            heatInputKjMm: 0.88,
          ),
          WpsPassParameter(
            passLayer: 'Pass 3-5 (Pulsed Fill & Cap)',
            process: 'P-GMAW',
            electrodeClass: 'AWS A5.28 ER80S-G',
            electrodeDiameterMm: 1.2,
            polarity: 'DCEP (+)',
            currentMinAmp: 190,
            currentMaxAmp: 260,
            voltageMin: 24,
            voltageMax: 29,
            travelSpeedMin: 25.0,
            travelSpeedMax: 38.0,
            heatInputKjMm: 1.18,
          ),
        ],
      ),
      const WeldingProcedureSpecification(
        wpsId: 'WPS-OIL-SAW-DJ-04',
        pqrNumber: 'PQR-2024-SAW-05',
        title: 'Yard Double Jointing Submerged Arc Welding (SAW)',
        standard: 'API 1104 / ASME Section IX',
        process: WeldingProcessType.sawDoubleJoint,
        progression: '1G Rolled Flat',
        baseMaterial: 'API 5L Grade X70M PSL2 (457 mm OD x 14.3 mm WT)',
        diameterRange: '18" (457 mm) to 48" (1219 mm)',
        thicknessRange: '8.0 mm to 32.0 mm WT',
        jointDesign: 'Double V-Groove asymmetric: 60° outside, 70° inside back-weld',
        rootFiller: 'AWS A5.18 ER70S-6 (GMAW Root backing)',
        fillCapFiller: 'AWS A5.23 EA2 wire with F8A4-EA2-A2 Neutral Flux (3.2 mm wire)',
        shieldingGas: 'Neutral Submerged Arc Flux Linde 709-5',
        minPreheatTempC: 75.0,
        maxInterpassTempC: 230.0,
        pwhtRequirement: 'None',
        heatInputMin: 1.20,
        heatInputMax: 2.40,
        approvalStatus: 'APPROVED (EIL Level III & OIL Resident Eng)',
        approvedDate: '04 Dec 2024',
        passParameters: [
          WpsPassParameter(
            passLayer: 'Pass 1 (External Fill)',
            process: 'SAW',
            electrodeClass: 'AWS A5.23 EA2',
            electrodeDiameterMm: 3.2,
            polarity: 'DCEP (+)',
            currentMinAmp: 380,
            currentMaxAmp: 460,
            voltageMin: 28,
            voltageMax: 32,
            travelSpeedMin: 45.0,
            travelSpeedMax: 65.0,
            heatInputKjMm: 1.65,
          ),
          WpsPassParameter(
            passLayer: 'Pass 2 (External Cap)',
            process: 'SAW',
            electrodeClass: 'AWS A5.23 EA2',
            electrodeDiameterMm: 3.2,
            polarity: 'AC / DCEP',
            currentMinAmp: 420,
            currentMaxAmp: 520,
            voltageMin: 30,
            voltageMax: 34,
            travelSpeedMin: 40.0,
            travelSpeedMax: 55.0,
            heatInputKjMm: 1.95,
          ),
        ],
      ),
      const WeldingProcedureSpecification(
        wpsId: 'WPS-OIL-REP-05',
        pqrNumber: 'PQR-2024-REP-06',
        title: 'Pipeline Defect Excavation & Full-Penetration Weld Repair',
        standard: 'API 1104 Clause 10 (Repair and Removal of Defects)',
        process: WeldingProcessType.smawCellulosic,
        progression: 'Vertical Uphill (Low-H2) or Downhill',
        baseMaterial: 'API 5L X70M PSL2 (457 mm OD x 14.3 mm WT)',
        diameterRange: 'All Diameters',
        thicknessRange: 'Full Wall Thickness Excavation',
        jointDesign: 'Excavated Groove: 60° Boat-Shaped cavity, Dye Penetrant PT verified before re-weld',
        rootFiller: 'AWS A5.5 E8018-G Low-Hydrogen (2.5 & 3.2 mm, baked at 350°C)',
        fillCapFiller: 'AWS A5.5 E8018-G Low-Hydrogen (3.2 & 4.0 mm, DCEP)',
        shieldingGas: 'None',
        minPreheatTempC: 150.0, // Higher preheat for repairs per API 1104
        maxInterpassTempC: 220.0,
        pwhtRequirement: 'Controlled cooling under insulating blanket for 4 hours',
        heatInputMin: 1.10,
        heatInputMax: 1.70,
        approvalStatus: 'APPROVED (EIL Level III & OIL Resident Eng)',
        approvedDate: '28 Jan 2025',
        passParameters: [
          WpsPassParameter(
            passLayer: 'Pass 1 (Repair Root)',
            process: 'SMAW Low-H2',
            electrodeClass: 'AWS A5.5 E8018-G',
            electrodeDiameterMm: 2.5,
            polarity: 'DCEP (+)',
            currentMinAmp: 80,
            currentMaxAmp: 110,
            voltageMin: 21,
            voltageMax: 25,
            travelSpeedMin: 8.0,
            travelSpeedMax: 14.0,
            heatInputKjMm: 1.22,
          ),
        ],
      ),
    ];

    _testCoupons = [
      const NdtTestCouponRecord(
        couponId: 'TC-2025-KPL-084',
        welderId: 'WLD-KPL-084',
        welderName: 'Rajeshwar Sharma',
        pipeSize: '18" OD (457 mm) x 14.3 mm WT',
        steelGrade: 'API 5L X70M PSL2',
        testDate: '15 Mar 2025',
        position: '5G Fixed Downhill',
        visualInspectionResult: 'ACCEPTED: Crown height 1.8mm (Limit 2.4mm), Root penetration full 1.2mm, Hi-Lo 0.6mm',
        rtReportNo: 'RT-KPL-2025-084',
        rtInterpretation: 'ACCEPTED (Class 1): 0 cracks, 0 LOF, 0 slag. API 1104 Clause 9 fully compliant',
        rtFilmDensity: 2.62,
        autReportNo: 'AUT-ZONAL-084',
        autZonalResult: 'ACCEPTED: Phased array zonal gating clear across Root, L1, L2, L3, Cap',
        bendTestResult: 'ACCEPTED: 4 specimens (2 Root, 2 Face) bent 180° on 4t mandrel radius. No fissure > 3.2mm',
        tensileUltimateMpa: 618.0,
        tpiaWitness: 'A. K. Barua (EIL Level III)',
      ),
      const NdtTestCouponRecord(
        couponId: 'TC-2025-LT-102',
        welderId: 'WLD-LT-102',
        welderName: 'Gurpreet Singh',
        pipeSize: '18" OD (457 mm) x 14.3 mm WT',
        steelGrade: 'API 5L X70M PSL2',
        testDate: '10 Jan 2025',
        position: '6G Fixed 45°',
        visualInspectionResult: 'ACCEPTED: Smooth STT bead, zero spatter, crown height 1.9mm',
        rtReportNo: 'RT-LT-2025-102',
        rtInterpretation: 'ACCEPTED (Class 1): Zero defect indications. Density 2.80 H&D, IQI wire 11',
        rtFilmDensity: 2.80,
        autReportNo: 'AUT-LT-PAUT-102',
        autZonalResult: 'ACCEPTED: Full sidewall fusion verified via TOFD and Phased Array',
        bendTestResult: 'ACCEPTED: 4 specimens (2 Root, 2 Face) 180° bend sound metal',
        tensileUltimateMpa: 632.0,
        tpiaWitness: 'M. S. Roy (EIL Level III)',
      ),
      const NdtTestCouponRecord(
        couponId: 'TC-2025-PL-045',
        welderId: 'WLD-PL-045',
        welderName: 'Bikram Bora',
        pipeSize: '12" OD (323.9 mm) x 15.9 mm WT Heavy Wall',
        steelGrade: 'API 5L X70M PSL2',
        testDate: '20 Feb 2025',
        position: '6GR Restricted 45°',
        visualInspectionResult: 'ACCEPTED: TIG root bead mirror finish, no oxidation or sugaring',
        rtReportNo: 'RT-PL-2025-045',
        rtInterpretation: 'ACCEPTED (Class 1): Zero porosity, perfect tie-in with SMAW fill',
        rtFilmDensity: 2.74,
        autReportNo: 'AUT-PL-TOFD-045',
        autZonalResult: 'ACCEPTED: 100% Volume UT clear',
        bendTestResult: 'ACCEPTED: 4x Side Bends 180° passed without open defects',
        tensileUltimateMpa: 645.0,
        tpiaWitness: 'S. K. Saikia (DNV-GL / EIL)',
      ),
    ];
  }

  static String _generateCertHash(String id, String name, String stamp) {
    final raw = '$id|$name|$stamp|API1104|ASME_IX|OIL_DULIAJAN|${DateTime.now().year}';
    return sha256.convert(utf8.encode(raw)).toString().substring(0, 16).toUpperCase();
  }

  // Filtered Welder List
  List<WelderQualificationRecord> get _filteredWelders {
    return _welders.where((welder) {
      final matchesSearch = _searchQuery.isEmpty ||
          welder.name.toLowerCase().contains(_searchQuery) ||
          welder.welderId.toLowerCase().contains(_searchQuery) ||
          welder.stampId.toLowerCase().contains(_searchQuery) ||
          welder.contractor.toLowerCase().contains(_searchQuery);

      final matchesContractor = _selectedContractor == 'ALL' ||
          welder.contractor.toLowerCase().contains(_selectedContractor.toLowerCase());

      final matchesProcess = _selectedProcess == 'ALL' ||
          welder.process.shortName.toLowerCase() == _selectedProcess.toLowerCase();

      final matchesStatus = _selectedStatus == 'ALL' ||
          welder.status.label.toLowerCase() == _selectedStatus.toLowerCase();

      final matchesPosition = _selectedPosition == 'ALL' ||
          welder.position.code.startsWith(_selectedPosition);

      return matchesSearch && matchesContractor && matchesProcess && matchesStatus && matchesPosition;
    }).toList();
  }

  // High Level KPIs
  int get _totalWeldersCount => _welders.length;
  int get _activeWeldersCount => _welders.where((w) => w.status == WelderStatus.active).length;
  int get _renewalAlertCount => _welders.where((w) => w.status == WelderStatus.renewalDue || (w.status == WelderStatus.active && w.daysUntilExpiry <= 30)).length;
  int get _suspendedCount => _welders.where((w) => w.status == WelderStatus.suspended || w.status == WelderStatus.expired).length;

  double get _fleetAverageRepairRate {
    final totalWelds = _welders.fold<int>(0, (sum, w) => sum + w.cumulativeJoints);
    final totalRepairs = _welders.fold<int>(0, (sum, w) => sum + w.repairedJoints);
    return totalWelds > 0 ? (totalRepairs / totalWelds) * 100 : 0.0;
  }

  // Log Continuity Action
  void _logContinuityWeld(WelderQualificationRecord welder) {
    setState(() {
      welder.cumulativeJoints += 1;
      welder.lastWeldDate = DateTime.now();
      if (welder.status == WelderStatus.renewalDue) {
        welder.status = WelderStatus.active;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF162347),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF4EDEA3), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Continuity logged for ${welder.name} (${welder.stampId}). 6-Month validity renewed to ${DateFormat('dd MMM yyyy').format(welder.continuityExpiryDate)}.',
                style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welder & WPS Registry',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'API 1104 (22nd Ed) / ASME Sec IX • GAIL/OIL Pipeline',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Qualify New Welder',
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryLight),
            onPressed: _showAddWelderDialog,
          ),
          IconButton(
            tooltip: 'Refresh Registry',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: () {
              setState(() {
                _initializeData();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Welder qualification registry refreshed from site ledger'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.primaryLight,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.engineering_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Welder Roster (${_welders.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('WPS Register (${_wpsList.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.biotech_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('NDT & Bend Quals (${_testCoupons.length})'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    children: [
                      Icon(Icons.query_stats_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('KPIs & Continuity'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Top KPI Summary Strip
          _buildExecutiveSummaryStrip(),

          // Tab Bar Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWelderRosterTab(dateFormat),
                _buildWpsRegistryTab(),
                _buildNdtQualsTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TOP EXECUTIVE SUMMARY STRIP
  // ============================================================================

  Widget _buildExecutiveSummaryStrip() {
    final fleetRate = _fleetAverageRepairRate;
    final isRateCompliant = fleetRate < kRepairRateTargetPercent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Total Qualified Welders
          Expanded(
            child: _buildMetricTile(
              label: 'QUALIFIED WELDERS',
              value: '$_totalWeldersCount',
              sublabel: '$_activeWeldersCount Active',
              icon: Icons.badge_rounded,
              color: AppTheme.primaryLight,
            ),
          ),
          Container(width: 1, height: 38, color: AppTheme.border),
          // Fleet Repair Cut-out Rate
          Expanded(
            child: _buildMetricTile(
              label: 'FLEET REPAIR RATE',
              value: '${fleetRate.toStringAsFixed(2)}%',
              sublabel: 'Target < ${kRepairRateTargetPercent.toStringAsFixed(1)}%',
              icon: Icons.hardware_rounded,
              color: isRateCompliant ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252),
              trailingBadge: isRateCompliant ? 'PASS' : 'EXCEEDED',
            ),
          ),
          Container(width: 1, height: 38, color: AppTheme.border),
          // Active WPS Procedures
          Expanded(
            child: _buildMetricTile(
              label: 'WPS PROCEDURES',
              value: '${_wpsList.length}',
              sublabel: 'API 1104 / ASME IX',
              icon: Icons.assignment_turned_in_rounded,
              color: const Color(0xFFFFB95F),
            ),
          ),
          Container(width: 1, height: 38, color: AppTheme.border),
          // Renewal Alerts
          Expanded(
            child: _buildMetricTile(
              label: 'EXPIRY / CONTINUITY',
              value: '$_renewalAlertCount',
              sublabel: '$_suspendedCount Suspended',
              icon: Icons.notification_important_rounded,
              color: _renewalAlertCount > 0 ? const Color(0xFFFFB95F) : const Color(0xFF4EDEA3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String sublabel,
    required IconData icon,
    required Color color,
    String? trailingBadge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (trailingBadge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    trailingBadge,
                    style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
          Text(
            sublabel,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: WELDER WPQ ROSTER
  // ============================================================================

  Widget _buildWelderRosterTab(DateFormat dateFormat) {
    final welders = _filteredWelders;

    return Column(
      children: [
        // Search & Filter Header
        _buildSearchAndFilterBar(),

        // Welders List
        Expanded(
          child: welders.isEmpty
              ? _buildEmptyState('No welders match current search and filter criteria')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  itemCount: welders.length,
                  itemBuilder: (context, index) {
                    final welder = welders[index];
                    return _buildWelderCard(welder, dateFormat);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      color: AppTheme.surface,
      child: Column(
        children: [
          // Search TextField
          TextField(
            controller: _searchController,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search welder name, ID (e.g. WLD-KPL-084), stamp ID, contractor...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Contractor Filter
                _buildFilterDropdown(
                  label: 'Contractor',
                  value: _selectedContractor,
                  items: const ['ALL', 'Kalpataru', 'L&T', 'Punj Lloyd', 'Corrtech'],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedContractor = val);
                  },
                ),
                const SizedBox(width: 8),

                // Process Filter
                _buildFilterDropdown(
                  label: 'Process',
                  value: _selectedProcess,
                  items: const ['ALL', 'SMAW', 'GMAW STT', 'GTAW TIG', 'FCAW', 'SAW'],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedProcess = val);
                  },
                ),
                const SizedBox(width: 8),

                // Status Filter
                _buildFilterDropdown(
                  label: 'Status',
                  value: _selectedStatus,
                  items: const ['ALL', 'ACTIVE', 'RENEWAL DUE', 'SUSPENDED', 'EXPIRED'],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
                const SizedBox(width: 8),

                // Position Filter
                _buildFilterDropdown(
                  label: 'Position',
                  value: _selectedPosition,
                  items: const ['ALL', '5G', '6G', '6GR', '1G'],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPosition = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            isDense: true,
            dropdownColor: AppTheme.surfaceCard,
            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryLight, size: 18),
            style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w700),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildWelderCard(WelderQualificationRecord welder, DateFormat dateFormat) {
    final isRepairCompliant = welder.repairRate < kRepairRateTargetPercent;
    final repairColor = isRepairCompliant ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252);

    final daysLeft = welder.daysUntilExpiry;
    final isExpiringSoon = daysLeft <= 30 && daysLeft >= 0;
    final isExpired = daysLeft < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: welder.status == WelderStatus.suspended
              ? const Color(0xFFFF5252).withValues(alpha: 0.6)
              : isExpiringSoon
                  ? const Color(0xFFFFB95F).withValues(alpha: 0.6)
                  : AppTheme.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showWelderDetailsModal(welder),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Welder Name, ID, Hard Stamp, Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with initials
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: welder.process.color.withValues(alpha: 0.15),
                    child: Text(
                      welder.name.isNotEmpty ? welder.name[0] : 'W',
                      style: TextStyle(
                        color: welder.process.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Welder Name & ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                welder.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Hard Stamp Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB95F).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFFFB95F).withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'STAMP: ${welder.stampId}',
                                style: const TextStyle(
                                  color: Color(0xFFFFB95F),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${welder.welderId} • ${welder.contractor}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: welder.status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: welder.status.color.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(welder.status.icon, size: 11, color: welder.status.color),
                        const SizedBox(width: 4),
                        Text(
                          welder.status.label,
                          style: TextStyle(
                            color: welder.status.color,
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

              // Technical Tag Chips: Process & Position & Standard
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildTagChip(
                    label: welder.process.shortName,
                    color: welder.process.color,
                    icon: Icons.local_fire_department_rounded,
                  ),
                  _buildTagChip(
                    label: welder.position.code,
                    color: AppTheme.primaryLight,
                    icon: Icons.architecture_rounded,
                  ),
                  _buildTagChip(
                    label: welder.standard,
                    color: AppTheme.textSecondary,
                    icon: Icons.rule_rounded,
                  ),
                  _buildTagChip(
                    label: 'WT: ${welder.thicknessRange.split(' ').first}',
                    color: const Color(0xFF38BDF8),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Divider
              Container(height: 1, color: AppTheme.border.withValues(alpha: 0.5)),
              const SizedBox(height: 8),

              // KPI Row: Cumulative Welds, Repair Cut-out Rate, Continuity Expiry
              Row(
                children: [
                  // Joints Welded
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CUMULATIVE JOINTS',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 8.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${welder.cumulativeJoints}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${welder.repairedJoints} rep)',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Repair Rate % vs 2.0% Target
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REPAIR CUT-OUT RATE',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 8.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${welder.repairRate.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: repairColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isRepairCompliant ? Icons.check_circle_outline_rounded : Icons.warning_rounded,
                              size: 13,
                              color: repairColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 6-Month Continuity Rule Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '6-MO. CONTINUITY',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 8.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isExpired
                              ? 'EXPIRED (${daysLeft.abs()}d ago)'
                              : isExpiringSoon
                                  ? 'ALERT: $daysLeft d left'
                                  : '$daysLeft days left',
                          style: TextStyle(
                            color: isExpired
                                ? const Color(0xFFFF5252)
                                : isExpiringSoon
                                    ? const Color(0xFFFFB95F)
                                    : const Color(0xFF4EDEA3),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bottom Actions: Quick "Log Weld" button + NDT Verification badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // NDT Badges
                  Row(
                    children: [
                      _buildNdtBadge('RT Cl. 1', welder.rtResult == NdtTestStatus.accepted),
                      const SizedBox(width: 4),
                      _buildNdtBadge('AUT Zonal', welder.autResult == NdtTestStatus.accepted),
                      const SizedBox(width: 4),
                      _buildNdtBadge('180° Bend', welder.bendTestResult == NdtTestStatus.accepted),
                    ],
                  ),
                  // Log Weld Button
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 14, color: AppTheme.primaryLight),
                    label: const Text(
                      'Log Joint',
                      style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _logContinuityWeld(welder),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildNdtBadge(String label, bool passed) {
    final color = passed ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(passed ? Icons.check : Icons.close, size: 9, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: WPS & PQR REGISTRY
  // ============================================================================

  Widget _buildWpsRegistryTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: _wpsList.length,
      itemBuilder: (context, index) {
        final wps = _wpsList[index];
        return _buildWpsCard(wps);
      },
    );
  }

  Widget _buildWpsCard(WeldingProcedureSpecification wps) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: () => _showWpsDetailsModal(wps),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: WPS ID, Supporting PQR, Standard
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: wps.process.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.assignment_rounded, color: wps.process.color, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              wps.wpsId,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4EDEA3).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'APPROVED',
                                style: TextStyle(
                                  color: Color(0xFF4EDEA3),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PQR: ${wps.pqrNumber} • ${wps.standard}',
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                wps.title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Technical Specs Grid
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    _buildWpsDataRow('Base Metal Grade', wps.baseMaterial),
                    const SizedBox(height: 4),
                    _buildWpsDataRow('Process & Progression', '${wps.process.displayName} (${wps.progression})'),
                    const SizedBox(height: 4),
                    _buildWpsDataRow('Filler Metal (Root)', wps.rootFiller),
                    const SizedBox(height: 4),
                    _buildWpsDataRow('Filler Metal (Fill/Cap)', wps.fillCapFiller),
                    const SizedBox(height: 4),
                    _buildWpsDataRow('Preheat & Interpass', 'Min ${wps.minPreheatTempC.toInt()}°C / Max ${wps.maxInterpassTempC.toInt()}°C'),
                    const SizedBox(height: 4),
                    _buildWpsDataRow('Heat Input Range', '${wps.heatInputMin} to ${wps.heatInputMax} kJ/mm'),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Footer: Approval Signatures
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF4EDEA3)),
                      const SizedBox(width: 4),
                      Text(
                        wps.approvalStatus,
                        style: const TextStyle(color: Color(0xFF4EDEA3), fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    'Approved: ${wps.approvedDate}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWpsDataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 3: NDT & MECHANICAL TESTING LAB
  // ============================================================================

  Widget _buildNdtQualsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        // Standard Reference Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppTheme.primaryLight, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API 1104 Clause 6 & ASME Section IX QW-302',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Welder qualification coupon testing requires Volumetric Examination (RT Class 1 or AUT Phased Array) + Mechanical Testing (4x Guided Bend Tests 180° on 4t mandrel radius).',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Section Title
        const Text(
          'QUALIFICATION TEST COUPON DOSSIERS',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        // Coupons List
        ..._testCoupons.map(_buildTestCouponCard),
      ],
    );
  }

  Widget _buildTestCouponCard(NdtTestCouponRecord coupon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Coupon ID & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.science_rounded, size: 16, color: Color(0xFF4EDEA3)),
                    const SizedBox(width: 6),
                    Text(
                      coupon.couponId,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Text(
                  coupon.testDate,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Welder: ${coupon.welderName} (${coupon.welderId}) • ${coupon.position}',
              style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              'Test Pipe: ${coupon.pipeSize} • Grade: ${coupon.steelGrade}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 10),

            // Examination Blocks
            _buildNdtBlock(
              title: 'Visual Inspection (VT)',
              status: 'PASSED',
              description: coupon.visualInspectionResult,
              color: const Color(0xFF4EDEA3),
              icon: Icons.visibility_rounded,
            ),
            const SizedBox(height: 6),
            _buildNdtBlock(
              title: 'Radiographic Examination (RT Class 1 per API 1104 §9)',
              status: 'ACCEPTED (Density: ${coupon.rtFilmDensity} H&D)',
              description: '${coupon.rtInterpretation} [Report: ${coupon.rtReportNo}]',
              color: const Color(0xFF38BDF8),
              icon: Icons.filter_center_focus_rounded,
            ),
            const SizedBox(height: 6),
            _buildNdtBlock(
              title: 'Automated Ultrasonic Testing (AUT Phased Array)',
              status: 'ACCEPTED',
              description: '${coupon.autZonalResult} [Report: ${coupon.autReportNo}]',
              color: const Color(0xFFFFB95F),
              icon: Icons.radar_rounded,
            ),
            const SizedBox(height: 6),
            _buildNdtBlock(
              title: 'Guided Root & Face Bend Tests (ASME QW-462.3 / API 1104 Fig 8)',
              status: 'SOUND METAL',
              description: coupon.bendTestResult,
              color: const Color(0xFF4EDEA3),
              icon: Icons.architecture_rounded,
            ),
            const SizedBox(height: 6),
            _buildNdtBlock(
              title: 'Transverse Tensile Strength',
              status: '${coupon.tensileUltimateMpa} MPa',
              description: 'Exceeds specified minimum tensile strength of 570 MPa (Base metal fracture observed)',
              color: const Color(0xFFA78BFA),
              icon: Icons.speed_rounded,
            ),
            const SizedBox(height: 10),

            // Witness
            Row(
              children: [
                const Icon(Icons.how_to_reg_rounded, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Witnessed & Certified by: ${coupon.tpiaWitness}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNdtBlock({
    required String title,
    required String status,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            description,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: PERFORMANCE ANALYTICS & CONTINUITY
  // ============================================================================

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        // Repair Rate Benchmark vs Target Card
        _buildRepairRateBenchmarkCard(),
        const SizedBox(height: 14),

        // Contractor Repair Rate Distribution
        _buildContractorBenchmarkingCard(),
        const SizedBox(height: 14),

        // Defect Pareto Analysis Card
        _buildDefectParetoCard(),
        const SizedBox(height: 14),

        // 6-Month Continuity Rule Audit Card
        _buildContinuityRuleAuditCard(),
      ],
    );
  }

  Widget _buildRepairRateBenchmarkCard() {
    final avgRate = _fleetAverageRepairRate;
    final isPassing = avgRate < kRepairRateTargetPercent;

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
              const Text(
                'FLEET REPAIR CUT-OUT RATE KPI',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPassing ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPassing ? 'COMPLIANT (< 2.0%)' : 'EXCEEDED (> 2.0%)',
                  style: TextStyle(
                    color: isPassing ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Metric Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${avgRate.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: isPassing ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'vs 2.00% GAIL/OIL Pipeline Benchmark',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (avgRate / 4.0).clamp(0.0, 1.0),
              backgroundColor: AppTheme.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPassing ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.0% (Zero Defect)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
              Text('Target: 2.0%', style: TextStyle(color: Color(0xFFFFB95F), fontSize: 9.5, fontWeight: FontWeight.w700)),
              Text('4.0% (Critical Alert)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContractorBenchmarkingCard() {
    // Calculate contractor metrics
    final contractors = ['Kalpataru Projects Ltd', 'L&T Hydrocarbon', 'Punj Lloyd Ltd', 'Corrtech Energy'];

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
          const Text(
            'CONTRACTOR REPAIR PERFORMANCE BENCHMARK',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          ...contractors.map((cName) {
            final cWelders = _welders.where((w) => w.contractor == cName).toList();
            final welds = cWelders.fold<int>(0, (s, w) => s + w.cumulativeJoints);
            final repairs = cWelders.fold<int>(0, (s, w) => s + w.repairedJoints);
            final rate = welds > 0 ? (repairs / welds) * 100 : 0.0;
            final isPassing = rate < kRepairRateTargetPercent;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cName,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${rate.toStringAsFixed(2)}% ($repairs / $welds joints)',
                        style: TextStyle(
                          color: isPassing ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (rate / 3.0).clamp(0.0, 1.0),
                      backgroundColor: AppTheme.background,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPassing ? AppTheme.primaryLight : const Color(0xFFFF5252),
                      ),
                      minHeight: 5,
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

  Widget _buildDefectParetoCard() {
    const defects = [
      {'type': 'Incomplete Sidewall Fusion (IF/LOF)', 'pct': 42.0, 'color': Color(0xFFFF5252)},
      {'type': 'Elongated Slag Inclusions (ESI)', 'pct': 28.0, 'color': Color(0xFFFFB95F)},
      {'type': 'Cluster Porosity (CP)', 'pct': 16.0, 'color': Color(0xFF38BDF8)},
      {'type': 'Inadequate Penetration (IP/High-Low)', 'pct': 9.0, 'color': Color(0xFFA78BFA)},
      {'type': 'Crown/Root Undercut (EU/IU)', 'pct': 5.0, 'color': Color(0xFF4EDEA3)},
    ];

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
          const Text(
            'DEFECT PARETO DISTRIBUTION (API 1104 REPAIRS)',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          ...defects.map((d) {
            final pct = d['pct'] as double;
            final color = d['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d['type'] as String,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContinuityRuleAuditCard() {
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
            children: [
              const Icon(Icons.history_toggle_off_rounded, size: 16, color: Color(0xFFFFB95F)),
              const SizedBox(width: 6),
              const Text(
                '6-MONTH CONTINUITY RULE AUDIT (API 1104 §6.8 / ASME QW-322)',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'A welder qualification remains valid indefinitely provided the welder welds using the process at least once within every 6 months (180 days). If no weld is recorded within 180 days, the qualification expires immediately and requires requalification test coupons.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF4EDEA3), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Nirmaan OS monitors daily DPR weld logs and automatically alerts when a welder is within 30 days of qualification lapse.',
                    style: TextStyle(color: AppTheme.textPrimary.withValues(alpha: 0.9), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MODALS & DETAIL SHEETS
  // ============================================================================

  void _showWelderDetailsModal(WelderQualificationRecord welder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Top drag bar
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: welder.process.color.withValues(alpha: 0.15),
                      child: Text(
                        welder.name.isNotEmpty ? welder.name[0] : 'W',
                        style: TextStyle(
                          color: welder.process.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            welder.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${welder.welderId} • Stamp: ${welder.stampId} • ${welder.contractor}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.border, height: 1),

              // Modal Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Digital Certificate Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.surfaceCard,
                            AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB95F), size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'WELDER PERFORMANCE QUALIFICATION (WPQ)',
                                    style: TextStyle(
                                      color: Color(0xFFFFB95F),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: welder.status.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  welder.status.label,
                                  style: TextStyle(
                                    color: welder.status.color,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildDetailRow('Governing Standard', welder.standard),
                          _buildDetailRow('Qualified WPS', welder.qualifiedWps),
                          _buildDetailRow('Supporting PQR', welder.pqrReference),
                          _buildDetailRow('Welding Process', welder.process.displayName),
                          _buildDetailRow('Qualified Position', '${welder.position.code} (${welder.position.description})'),
                          _buildDetailRow('Diameter Qualified', welder.diameterRange),
                          _buildDetailRow('Thickness Qualified', welder.thicknessRange),
                          _buildDetailRow('Initial Qualification Date', DateFormat('dd MMM yyyy').format(welder.qualificationDate)),
                          _buildDetailRow('Last Active Weld Date', DateFormat('dd MMM yyyy').format(welder.lastWeldDate)),
                          _buildDetailRow('Continuity Expiry Date', DateFormat('dd MMM yyyy').format(welder.continuityExpiryDate)),
                          _buildDetailRow('TPIA Certification Witness', welder.tpiaInspector),
                          _buildDetailRow('Client Approver (OIL)', welder.clientEngineer),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 16, color: AppTheme.primaryLight),
                              const SizedBox(width: 6),
                              Text(
                                'Verification Token: ${welder.verificationHash}',
                                style: const TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 10.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // NDT Inspection Results Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QUALIFICATION COUPON NDT & MECHANICAL EVALUATION',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildNdtRow('Radiography (RT Class 1)', welder.rtDetails, welder.rtResult),
                          const SizedBox(height: 6),
                          _buildNdtRow('Automated Ultrasonic Testing (AUT)', welder.autDetails, welder.autResult),
                          const SizedBox(height: 6),
                          _buildNdtRow('Guided Bend Tests (Root/Face 180°)', welder.bendTestDetails, welder.bendTestResult),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Log Continuity Weld Action
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.verified_rounded, size: 18),
                        label: const Text('LOG CONTINUITY JOINT & RENEW 6-MONTHS'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _logContinuityWeld(welder);
                        },
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
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNdtRow(String testName, String details, NdtTestStatus status) {
    final isPassed = status == NdtTestStatus.accepted;
    final color = isPassed ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                testName,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
              ),
              Text(
                details,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showWpsDetailsModal(WeldingProcedureSpecification wps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Top drag bar
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: wps.process.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.description_rounded, color: wps.process.color, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wps.wpsId,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'PQR: ${wps.pqrNumber} • ${wps.standard}',
                            style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.border, height: 1),

              // Pass schedule table & parameters
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      wps.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Joint & Material Summary Card
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
                          _buildDetailRow('Base Metal', wps.baseMaterial),
                          _buildDetailRow('Qualified Thickness', wps.thicknessRange),
                          _buildDetailRow('Qualified Diameter', wps.diameterRange),
                          _buildDetailRow('Joint Design', wps.jointDesign),
                          _buildDetailRow('Root Pass Filler', wps.rootFiller),
                          _buildDetailRow('Fill/Cap Filler', wps.fillCapFiller),
                          _buildDetailRow('Shielding Gas', wps.shieldingGas),
                          _buildDetailRow('Preheat Temp', 'Minimum ${wps.minPreheatTempC.toInt()}°C (Induction/torch)'),
                          _buildDetailRow('Max Interpass Temp', '${wps.maxInterpassTempC.toInt()}°C'),
                          _buildDetailRow('PWHT Requirement', wps.pwhtRequirement),
                          _buildDetailRow('Heat Input Range', '${wps.heatInputMin} - ${wps.heatInputMax} kJ/mm'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pass Schedule Table
                    const Text(
                      'WELD PASS SCHEDULE & ELECTRICAL PARAMETERS',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.surfaceContainerHigh),
                        headingTextStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w700),
                        dataTextStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        columnSpacing: 16,
                        horizontalMargin: 12,
                        columns: const [
                          DataColumn(label: Text('Pass / Layer')),
                          DataColumn(label: Text('Electrode / Wire')),
                          DataColumn(label: Text('Size Ø')),
                          DataColumn(label: Text('Polarity')),
                          DataColumn(label: Text('Current (A)')),
                          DataColumn(label: Text('Voltage (V)')),
                          DataColumn(label: Text('Travel (cm/m)')),
                          DataColumn(label: Text('Heat (kJ/mm)')),
                        ],
                        rows: wps.passParameters.map((p) {
                          return DataRow(
                            cells: [
                              DataCell(Text(p.passLayer, style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.w600))),
                              DataCell(Text(p.electrodeClass)),
                              DataCell(Text('${p.electrodeDiameterMm} mm')),
                              DataCell(Text(p.polarity)),
                              DataCell(Text('${p.currentMinAmp}-${p.currentMaxAmp}')),
                              DataCell(Text('${p.voltageMin}-${p.voltageMax}')),
                              DataCell(Text('${p.travelSpeedMin.toInt()}-${p.travelSpeedMax.toInt()}')),
                              DataCell(Text(p.heatInputKjMm.toStringAsFixed(2))),
                            ],
                          );
                        }).toList(),
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
  }

  // ============================================================================
  // ADD WELDER MODAL DIALOG
  // ============================================================================

  void _showAddWelderDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final idCtrl = TextEditingController(text: 'WLD-KPL-${100 + _welders.length}');
    final stampCtrl = TextEditingController();
    String selectedContractor = 'Kalpataru Projects Ltd';
    WeldingProcessType selectedProc = WeldingProcessType.smawCellulosic;
    QualifiedPosition selectedPos = QualifiedPosition.pos5G;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: const Row(
                children: [
                  Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryLight),
                  SizedBox(width: 8),
                  Text(
                    'Qualify New Welder',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Welder Full Name',
                            hintText: 'e.g. Ramesh Chandra Verma',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: idCtrl,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                decoration: const InputDecoration(labelText: 'Welder ID'),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: stampCtrl,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                decoration: const InputDecoration(
                                  labelText: 'Hard Stamp ID',
                                  hintText: 'e.g. RV-108',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: selectedContractor,
                          dropdownColor: AppTheme.surfaceCard,
                          decoration: const InputDecoration(labelText: 'Contractor'),
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: 'Kalpataru Projects Ltd', child: Text('Kalpataru Projects Ltd')),
                            DropdownMenuItem(value: 'L&T Hydrocarbon', child: Text('L&T Hydrocarbon')),
                            DropdownMenuItem(value: 'Punj Lloyd Ltd', child: Text('Punj Lloyd Ltd')),
                            DropdownMenuItem(value: 'Corrtech Energy', child: Text('Corrtech Energy')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedContractor = val);
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<WeldingProcessType>(
                          initialValue: selectedProc,
                          dropdownColor: AppTheme.surfaceCard,
                          decoration: const InputDecoration(labelText: 'Welding Process'),
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          items: WeldingProcessType.values.map((p) {
                            return DropdownMenuItem(value: p, child: Text(p.displayName));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedProc = val);
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<QualifiedPosition>(
                          initialValue: selectedPos,
                          dropdownColor: AppTheme.surfaceCard,
                          decoration: const InputDecoration(labelText: 'Qualified Position'),
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          items: QualifiedPosition.values.map((pos) {
                            return DropdownMenuItem(value: pos, child: Text(pos.code));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedPos = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final newWelder = WelderQualificationRecord(
                        welderId: idCtrl.text.trim(),
                        name: nameCtrl.text.trim(),
                        stampId: stampCtrl.text.trim(),
                        contractor: selectedContractor,
                        process: selectedProc,
                        position: selectedPos,
                        diameterRange: '>= 12.75" to Unlimited',
                        thicknessRange: '4.8 mm to 25.4 mm WT',
                        standard: 'API 1104 (22nd Ed) Cl. 6',
                        pqrReference: 'PQR-2024-X70-01',
                        qualifiedWps: 'WPS-OIL-SMAW-01',
                        rtResult: NdtTestStatus.accepted,
                        rtDetails: 'RT Class 1 Approved on Qualification Test Coupon',
                        autResult: NdtTestStatus.accepted,
                        autDetails: 'AUT Phased Array Zonal Cleared',
                        bendTestResult: NdtTestStatus.accepted,
                        bendTestDetails: '4x Guided Bend Tests Passed 180°',
                        nickBreakResult: NdtTestStatus.accepted,
                        cumulativeJoints: 0,
                        repairedJoints: 0,
                        lastWeldDate: DateTime.now(),
                        qualificationDate: DateTime.now(),
                        status: WelderStatus.active,
                        tpiaInspector: 'A. K. Barua (EIL Level III)',
                        clientEngineer: 'P. Gogoi (Oil India Ltd)',
                        verificationHash: _generateCertHash(idCtrl.text.trim(), nameCtrl.text.trim(), stampCtrl.text.trim()),
                      );

                      setState(() {
                        _welders.insert(0, newWelder);
                      });

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF162347),
                          content: Text('Welder ${newWelder.name} (${newWelder.stampId}) qualified and added to roster!'),
                        ),
                      );
                    }
                  },
                  child: const Text('Register & Qualify'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
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
}
