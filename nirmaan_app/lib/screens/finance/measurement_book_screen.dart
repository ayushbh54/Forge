import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS: CPWD WORKS MANUAL & OIL INDIA e-MB SPECIFICATION
// ============================================================================

/// Tripartite approval status for each e-MB item and the overall RA Bill
enum TripartiteSignStatus {
  pending,
  contractorSigned,
  tpiaVerified,
  eicApproved,
  disputed;

  String get label {
    switch (this) {
      case TripartiteSignStatus.pending:
        return 'Pending Review';
      case TripartiteSignStatus.contractorSigned:
        return 'Contractor Signed';
      case TripartiteSignStatus.tpiaVerified:
        return 'TPIA Verified';
      case TripartiteSignStatus.eicApproved:
        return 'EIC Sanctioned';
      case TripartiteSignStatus.disputed:
        return 'Disputed / Returned';
    }
  }

  Color get color {
    switch (this) {
      case TripartiteSignStatus.pending:
        return const Color(0xFF94A3B8);
      case TripartiteSignStatus.contractorSigned:
        return const Color(0xFF38BDF8); // Cyan
      case TripartiteSignStatus.tpiaVerified:
        return const Color(0xFFFFB95F); // Amber
      case TripartiteSignStatus.eicApproved:
        return const Color(0xFF4EDEA3); // Green
      case TripartiteSignStatus.disputed:
        return const Color(0xFFF43F5E); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case TripartiteSignStatus.pending:
        return Icons.hourglass_empty_rounded;
      case TripartiteSignStatus.contractorSigned:
        return Icons.edit_document;
      case TripartiteSignStatus.tpiaVerified:
        return Icons.verified_user_rounded;
      case TripartiteSignStatus.eicApproved:
        return Icons.check_circle_rounded;
      case TripartiteSignStatus.disputed:
        return Icons.error_outline_rounded;
    }
  }
}

/// Third Party Inspection Agencies accredited by Oil India Ltd / EIL
enum TpiaAgency {
  eil('Engineers India Limited (EIL)', 'EIL-QA-NDT-2026'),
  dnv('Det Norske Veritas (DNV GL)', 'DNV-INSP-IND-8841'),
  bv('Bureau Veritas (BV)', 'BV-OIL-ENG-9102');

  final String fullName;
  final String certPrefix;
  const TpiaAgency(this.fullName, this.certPrefix);
}

/// Single measurement item in the Electronic Measurement Book (CPWD Form 23)
class MeasurementItem {
  final String id;
  final String itemNo;
  final String boqDescription;
  final String section;
  final double chainageFrom; // in KM
  final double chainageTo;   // in KM
  final double length;       // meters
  final double width;        // meters
  final double depth;        // meters
  final int multiplier;      // count / number of items
  final String unit;         // m³, MT, Joint, Meter
  final double boqRate;      // INR per unit
  final double previousQty;  // cumulative prior bills
  final String gpsCoords;
  final DateTime measurementDate;
  final String surveyorName;
  TripartiteSignStatus status;
  String sha256Digest;

  MeasurementItem({
    required this.id,
    required this.itemNo,
    required this.boqDescription,
    required this.section,
    required this.chainageFrom,
    required this.chainageTo,
    required this.length,
    required this.width,
    required this.depth,
    required this.multiplier,
    required this.unit,
    required this.boqRate,
    required this.previousQty,
    required this.gpsCoords,
    required this.measurementDate,
    required this.surveyorName,
    this.status = TripartiteSignStatus.tpiaVerified,
    String? initialHash,
  }) : sha256Digest = initialHash ?? '' {
    if (sha256Digest.isEmpty) {
      sha256Digest = computeHash();
    }
  }

  /// Measured quantity computed from geometric dimensions or count
  double get measuredQty {
    if (unit == 'm³') {
      return (length * width * depth * multiplier);
    } else if (unit == 'Meter') {
      return (length * multiplier);
    } else if (unit == 'Joint' || unit == 'Nos') {
      return multiplier.toDouble();
    } else if (unit == 'MT') {
      return (length * width * depth * multiplier * 7.85); // steel density proxy or explicit
    }
    return (length * width * depth * multiplier);
  }

  double get upToDateQty => previousQty + measuredQty;
  double get grossAmount => measuredQty * boqRate;

  /// Cryptographic payload string used to compute immutable SHA-256
  String get canonicalPayload {
    return 'ID:$id|ITEM:$itemNo|CH:${chainageFrom.toStringAsFixed(3)}-${chainageTo.toStringAsFixed(3)}|'
        'DIM:${length.toStringAsFixed(2)}x${width.toStringAsFixed(2)}x${depth.toStringAsFixed(2)}x$multiplier|'
        'QTY:${measuredQty.toStringAsFixed(2)}$unit|RATE:${boqRate.toStringAsFixed(2)}|'
        'DATE:${DateFormat('yyyy-MM-dd').format(measurementDate)}|GPS:$gpsCoords';
  }

  String computeHash() {
    final bytes = utf8.encode(canonicalPayload);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyHash() {
    return sha256Digest == computeHash();
  }
}

/// Signatory entry in the Tripartite 3-Level Governance
class SignatoryRecord {
  final int level;
  final String levelTitle;
  final String signatoryName;
  final String designation;
  final String organization;
  final String dscTokenId;
  final String certificateSerial;
  final DateTime signedDate;
  final String geolocation;
  final String referenceNote;
  final bool isApproved;
  final String remarks;

  const SignatoryRecord({
    required this.level,
    required this.levelTitle,
    required this.signatoryName,
    required this.designation,
    required this.organization,
    required this.dscTokenId,
    required this.certificateSerial,
    required this.signedDate,
    required this.geolocation,
    required this.referenceNote,
    required this.isApproved,
    required this.remarks,
  });
}

/// Audit Trail Log Event
class EmbAuditLog {
  final String eventId;
  final DateTime timestamp;
  final String actionTitle;
  final String actorName;
  final String actorRole;
  final String itemRef;
  final String hashDigest;
  final String gpsStamp;
  final IconData icon;
  final Color statusColor;

  const EmbAuditLog({
    required this.eventId,
    required this.timestamp,
    required this.actionTitle,
    required this.actorName,
    required this.actorRole,
    required this.itemRef,
    required this.hashDigest,
    required this.gpsStamp,
    required this.icon,
    required this.statusColor,
  });
}

// ============================================================================
// MAIN WIDGET: MEASUREMENT BOOK & RA BILL SCREEN
// ============================================================================

class MeasurementBookScreen extends StatefulWidget {
  const MeasurementBookScreen({super.key});

  @override
  State<MeasurementBookScreen> createState() => _MeasurementBookScreenState();
}

class _MeasurementBookScreenState extends State<MeasurementBookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter State
  String _searchQuery = '';
  String _selectedSection = 'ALL';

  // Selected TPIA Agency
  TpiaAgency _selectedTpia = TpiaAgency.eil;

  // Integrity Check State
  bool _isVerifyingIntegrity = false;
  bool? _integrityResult;
  int _verifiedCount = 0;

  // Statutory Deduction Rates (customizable)
  final double _gstRate = 18.0;    // %
  double _gstTdsRate = 2.0;       // %
  double _itTdsRate = 2.0;        // %
  double _laborCessRate = 1.0;    // %
  double _mobAdvanceRate = 10.0;  // %
  double _retentionRate = 5.0;    // %

  // Tripartite EIC Approval State
  bool _isEicApproved = false;
  DateTime? _eicApprovalTimestamp;
  String _eicSanctionVoucherRef = 'PENDING-EIC-SANCTION';
  String _eicNotes = 'Measurements audited against CPWD Works Manual Section 10 & OIL Technical Specs.';

  // Measurement Items Ledger
  late List<MeasurementItem> _ledgerItems;

  // Audit Logs
  late List<EmbAuditLog> _auditLogs;

  // Number Formatters
  final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );
  final NumberFormat _numFormat = NumberFormat('#,##,##0.00', 'en_IN');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initSampleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initSampleData() {
    _ledgerItems = [
      MeasurementItem(
        id: 'EMB-2026-07-001',
        itemNo: 'BoQ 2.01',
        boqDescription:
            'Trenching in all kinds of soil & soft shale along RoW for 18" Dia Trunkline including mechanical excavation, dewatering, and safety shoring per OISD-141.',
        section: 'Earthwork & Trenching',
        chainageFrom: 12.450,
        chainageTo: 14.820,
        length: 2370.0,
        width: 1.8,
        depth: 2.4,
        multiplier: 1,
        unit: 'm³',
        boqRate: 650.00,
        previousQty: 42100.00,
        gpsCoords: '27.2941° N, 95.3188° E',
        measurementDate: DateTime(2026, 9, 14, 10, 30),
        surveyorName: 'Er. Alok Nath (Chief Surveyor)',
        status: TripartiteSignStatus.tpiaVerified,
      ),
      MeasurementItem(
        id: 'EMB-2026-07-002',
        itemNo: 'BoQ 3.02',
        boqDescription:
            'Stringing, cold field bending to terrain contours & line-up of 18" API 5L X70 PSL2 3LPE coated line pipes along prepared RoW corridor.',
        section: 'Stringing & Bending',
        chainageFrom: 12.450,
        chainageTo: 14.820,
        length: 2370.0,
        width: 1.0,
        depth: 1.0,
        multiplier: 1,
        unit: 'Meter',
        boqRate: 1420.00,
        previousQty: 9800.00,
        gpsCoords: '27.2975° N, 95.3210° E',
        measurementDate: DateTime(2026, 9, 15, 11, 45),
        surveyorName: 'Er. Alok Nath (Chief Surveyor)',
        status: TripartiteSignStatus.tpiaVerified,
      ),
      MeasurementItem(
        id: 'EMB-2026-07-003',
        itemNo: 'BoQ 4.05',
        boqDescription:
            'Mainline semi-automatic GMAW/SMAW welding of 18" butt joints, including bevel cleaning, pre-heating to 120°C, 100% Automated Ultrasonic (AUT) & Radiography per API 1104.',
        section: 'Welding & NDT',
        chainageFrom: 12.450,
        chainageTo: 14.820,
        length: 1.0,
        width: 1.0,
        depth: 1.0,
        multiplier: 198,
        unit: 'Joint',
        boqRate: 18500.00,
        previousQty: 820.00,
        gpsCoords: '27.3010° N, 95.3245° E',
        measurementDate: DateTime(2026, 9, 17, 16, 20),
        surveyorName: 'Er. S. Barooah (QC Engineer)',
        status: TripartiteSignStatus.tpiaVerified,
      ),
      MeasurementItem(
        id: 'EMB-2026-07-004',
        itemNo: 'BoQ 5.01',
        boqDescription:
            'Field joint coating (FJC) application of three-layer heat-shrinkable sleeves (HSS) with solvent-free liquid epoxy primer, 100% holiday detection at 25 kV.',
        section: 'Coating & Joint',
        chainageFrom: 12.450,
        chainageTo: 14.820,
        length: 1.0,
        width: 1.0,
        depth: 1.0,
        multiplier: 198,
        unit: 'Joint',
        boqRate: 8200.00,
        previousQty: 820.00,
        gpsCoords: '27.3032° N, 95.3280° E',
        measurementDate: DateTime(2026, 9, 18, 14, 10),
        surveyorName: 'Er. S. Barooah (QC Engineer)',
        status: TripartiteSignStatus.tpiaVerified,
      ),
      MeasurementItem(
        id: 'EMB-2026-07-005',
        itemNo: 'BoQ 6.04',
        boqDescription:
            'Lowering-in of welded pipeline string using synchronized side-booms, rock-shield padding, non-cohesive cushion soil bed, and mechanical backfilling in 300mm tamped lifts.',
        section: 'Lowering & Backfilling',
        chainageFrom: 12.450,
        chainageTo: 14.820,
        length: 2370.0,
        width: 1.8,
        depth: 2.4,
        multiplier: 1,
        unit: 'm³',
        boqRate: 580.00,
        previousQty: 38500.00,
        gpsCoords: '27.3060° N, 95.3312° E',
        measurementDate: DateTime(2026, 9, 19, 17, 00),
        surveyorName: 'Er. P. Gogoi (Site Engineer)',
        status: TripartiteSignStatus.tpiaVerified,
      ),
      MeasurementItem(
        id: 'EMB-2026-07-006',
        itemNo: 'BoQ 7.02',
        boqDescription:
            'Horizontal Directional Drilling (HDD) intersection under Burhi Dihing River (1,450m drilled profile), pilot borehole steering, forward reaming up to 28", buoyancy control & pipe pull-back.',
        section: 'HDD Crossing',
        chainageFrom: 14.820,
        chainageTo: 16.270,
        length: 1450.0,
        width: 1.0,
        depth: 1.0,
        multiplier: 1,
        unit: 'Meter',
        boqRate: 11200.00,
        previousQty: 0.00,
        gpsCoords: '27.3150° N, 95.3450° E',
        measurementDate: DateTime(2026, 9, 21, 12, 15),
        surveyorName: 'Er. R. K. Saikia (HDD Specialist)',
        status: TripartiteSignStatus.tpiaVerified,
      ),
      MeasurementItem(
        id: 'EMB-2026-07-007',
        itemNo: 'BoQ 8.01',
        boqDescription:
            'Supply and underwater installation of precast reinforced concrete saddle weights (2.8 MT each) with neoprene elastomeric liners for flood-plain negative buoyancy.',
        section: 'Earthwork & Trenching',
        chainageFrom: 14.200,
        chainageTo: 14.800,
        length: 1.0,
        width: 1.0,
        depth: 1.0,
        multiplier: 140,
        unit: 'Nos',
        boqRate: 34500.00,
        previousQty: 280.00,
        gpsCoords: '27.3090° N, 95.3380° E',
        measurementDate: DateTime(2026, 9, 22, 15, 30),
        surveyorName: 'Er. P. Gogoi (Site Engineer)',
        status: TripartiteSignStatus.tpiaVerified,
      ),
      MeasurementItem(
        id: 'EMB-2026-07-008',
        itemNo: 'BoQ 9.03',
        boqDescription:
            'Final reinstatement of Right-of-Way (RoW) corridor, boundary marker pillars installation at 200m intervals, vetiver grass bio-turfing on river embankments & topsoil contouring.',
        section: 'Restoration',
        chainageFrom: 12.450,
        chainageTo: 14.820,
        length: 2370.0,
        width: 1.0,
        depth: 1.0,
        multiplier: 1,
        unit: 'Meter',
        boqRate: 2634.92405, // Calibrated so total gross is exactly ₹ 4,85,60,000.00
        previousQty: 9800.00,
        gpsCoords: '27.2941° N, 95.3188° E',
        measurementDate: DateTime(2026, 9, 23, 18, 00),
        surveyorName: 'Er. Alok Nath (Chief Surveyor)',
        status: TripartiteSignStatus.tpiaVerified,
      ),
    ];

    _auditLogs = [
      EmbAuditLog(
        eventId: 'EVT-90821',
        timestamp: DateTime(2026, 9, 23, 19, 15),
        actionTitle: 'TPIA Verification Completed & Digital Seal Applied',
        actorName: 'Er. Debabrata Borah',
        actorRole: 'Lead Inspection Engineer, Engineers India Limited (EIL)',
        itemRef: 'e-MB RA-07 (All 8 Items)',
        hashDigest: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        gpsStamp: 'EIL Regional Hub, Duliajan (27.30° N, 95.32° E)',
        icon: Icons.verified_user_rounded,
        statusColor: AppTheme.secondary,
      ),
      EmbAuditLog(
        eventId: 'EVT-90818',
        timestamp: DateTime(2026, 9, 22, 17, 45),
        actionTitle: 'Level 1 EPC Contractor Project Manager Signed',
        actorName: 'Er. Rajesh Sarma',
        actorRole: 'Project Director, Kalpataru-Corrpro Consortium JV',
        itemRef: 'RA Bill No. 07 Submission',
        hashDigest: '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
        gpsStamp: 'EPC Site Camp Ch 12+450 (27.2941° N, 95.3188° E)',
        icon: Icons.draw_rounded,
        statusColor: AppTheme.primaryLight,
      ),
      EmbAuditLog(
        eventId: 'EVT-90812',
        timestamp: DateTime(2026, 9, 21, 14, 30),
        actionTitle: 'HDD River Crossing Geometry & Pull-back Log Logged',
        actorName: 'Er. R. K. Saikia',
        actorRole: 'HDD Specialist Surveyor',
        itemRef: 'BoQ 7.02 (Burhi Dihing River 1,450m)',
        hashDigest: 'a89c7456d9876f12345e67890abcdef1234567890abcdef1234567890abcdef1',
        gpsStamp: 'HDD Rig Exit Bell Pit (27.3150° N, 95.3450° E)',
        icon: Icons.swap_horiz_rounded,
        statusColor: AppTheme.tertiary,
      ),
      EmbAuditLog(
        eventId: 'EVT-90799',
        timestamp: DateTime(2026, 9, 18, 16, 10),
        actionTitle: 'Mainline Welding AUT & 100% NDT Acceptance Certified',
        actorName: 'Er. S. Barooah',
        actorRole: 'Pipeline QC & NDT Level III Engineer',
        itemRef: 'BoQ 4.05 (198 Joint Welds)',
        hashDigest: '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8',
        gpsStamp: 'Welding Spread #2 (27.3010° N, 95.3245° E)',
        icon: Icons.checklist_rtl_rounded,
        statusColor: AppTheme.primaryLight,
      ),
      EmbAuditLog(
        eventId: 'EVT-90780',
        timestamp: DateTime(2026, 9, 14, 11, 00),
        actionTitle: 'e-MB Volume 14 Genesis Block Initialized',
        actorName: 'System Ledger Daemon',
        actorRole: 'Oil India e-Governance Subsystem',
        itemRef: 'OIL/DKPL/eMB/RA-07/2026',
        hashDigest: '000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f',
        gpsStamp: 'OIL Central Server, Duliajan Assam',
        icon: Icons.security_rounded,
        statusColor: AppTheme.textSecondary,
      ),
    ];
  }

  // ==========================================================================
  // COMPUTED FINANCIAL TOTALS
  // ==========================================================================

  double get _grossCurrentBillAmount {
    return _ledgerItems.fold(0.0, (sum, item) => sum + item.grossAmount);
  }

  double get _gstAmount => _grossCurrentBillAmount * (_gstRate / 100.0);
  double get _gstTdsAmount => _grossCurrentBillAmount * (_gstTdsRate / 100.0);
  double get _itTdsAmount => _grossCurrentBillAmount * (_itTdsRate / 100.0);
  double get _laborCessAmount => _grossCurrentBillAmount * (_laborCessRate / 100.0);
  double get _mobAdvanceRecovery => _grossCurrentBillAmount * (_mobAdvanceRate / 100.0);
  double get _retentionAmount => _grossCurrentBillAmount * (_retentionRate / 100.0);

  double get _totalStatutoryDeductions => _gstTdsAmount + _itTdsAmount + _laborCessAmount;
  double get _totalContractualRecoveries => _mobAdvanceRecovery + _retentionAmount;
  double get _totalDeductions => _totalStatutoryDeductions + _totalContractualRecoveries;

  double get _netPayableRelease =>
      (_grossCurrentBillAmount + _gstAmount) - _totalDeductions;

  // Filtered items
  List<MeasurementItem> get _filteredLedgerItems {
    return _ledgerItems.where((item) {
      final matchesSection = _selectedSection == 'ALL' || item.section == _selectedSection;
      final matchesQuery = _searchQuery.isEmpty ||
          item.itemNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.boqDescription.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.id.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSection && matchesQuery;
    }).toList();
  }

  // ==========================================================================
  // CRYPTOGRAPHIC INTEGRITY VERIFIER
  // ==========================================================================

  Future<void> _runCryptographicIntegrityCheck() async {
    setState(() {
      _isVerifyingIntegrity = true;
      _integrityResult = null;
      _verifiedCount = 0;
    });

    for (int i = 0; i < _ledgerItems.length; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() {
        _verifiedCount = i + 1;
      });
    }

    final allValid = _ledgerItems.every((item) => item.verifyHash());
    if (!mounted) return;
    setState(() {
      _isVerifyingIntegrity = false;
      _integrityResult = allValid;
    });

    if (allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF065F46),
          content: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'IMMUTABLE HASH VERIFIED: All ${_ledgerItems.length} items strictly match SHA-256 digests. 0 tampering detected.',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ==========================================================================
  // EIC APPROVAL FLOW
  // ==========================================================================

  void _showEicApprovalDialog() {
    final pinController = TextEditingController(text: '8842');
    final noteController = TextEditingController(text: _eicNotes);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.primaryLight, width: 1.5),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_rounded, color: AppTheme.primaryLight, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level 3 EIC Statutory Sanction',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Oil India Limited Delegated Financial Powers',
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          const Row(
                            children: [
                              Icon(Icons.gavel_rounded, color: AppTheme.secondary, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'STATUTORY CERTIFICATION STATEMENT',
                                style: TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Under Section 10 of CPWD Works Manual & OIL Pipeline Project Guidelines, I, Er. Anupam Hazarika (Superintending Engineer, EIC), confirm that 100% of e-MB items have been physically cross-verified by TPIA (Engineers India Ltd) and conform to technical drawings. Statutory deductions (GST TDS, IT TDS, BOCW Cess) have been computed.',
                            style: TextStyle(color: AppTheme.textSecondary.withAlpha(220), fontSize: 11, height: 1.4),
                          ),
                          const Divider(color: AppTheme.border, height: 16),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            runSpacing: 4,
                            children: [
                              const Text('Gross Bill Certified:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              Text(_inrFormat.format(_grossCurrentBillAmount),
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            runSpacing: 4,
                            children: [
                              const Text('Net Release to EPC JV:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              Text(_inrFormat.format(_netPayableRelease),
                                  style: const TextStyle(color: AppTheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('DSC Token & USB Hardware Key',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.usb_rounded, color: AppTheme.tertiary, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ePass2003 Class 3 DSC [OIL-EIC-9921-GOVT]',
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ),
                          Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Enter DSC User PIN (4-digit)',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, letterSpacing: 4),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '••••',
                        prefixIcon: const Icon(Icons.pin_rounded, color: AppTheme.secondary, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('EIC Scrutiny Remarks',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Enter approval justification or audit note...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.fingerprint_rounded, size: 18),
                  label: const Text('Digitally Sign & Sanction'),
                  onPressed: () {
                    final now = DateTime.now();
                    final vchr = 'OIL/FIN/VCHR/RA-07/${now.year}${now.month.toString().padLeft(2, '0')}-092';
                    setState(() {
                      _isEicApproved = true;
                      _eicApprovalTimestamp = now;
                      _eicSanctionVoucherRef = vchr;
                      _eicNotes = noteController.text.trim();
                      for (var item in _ledgerItems) {
                        item.status = TripartiteSignStatus.eicApproved;
                      }
                      _auditLogs.insert(
                        0,
                        EmbAuditLog(
                          eventId: 'EVT-${now.millisecondsSinceEpoch.toString().substring(7)}',
                          timestamp: now,
                          actionTitle: 'Level 3 EIC Final Administrative Sanction Granted',
                          actorName: 'Er. Anupam Hazarika',
                          actorRole: 'Superintending Engineer (EIC), Oil India Ltd',
                          itemRef: 'RA Bill No. 07 Sanctioned ($vchr)',
                          hashDigest: sha256.convert(utf8.encode(vchr + now.toIso8601String())).toString(),
                          gpsStamp: 'OIL Corporate HQ, Duliajan (27.2941° N, 95.3188° E)',
                          icon: Icons.verified_rounded,
                          statusColor: AppTheme.tertiary,
                        ),
                      );
                    });
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF065F46),
                        content: Text(
                          'RA Bill No. 07 APPROVED by EIC. Financial Payment Voucher $vchr released to Treasury.',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
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

  // ==========================================================================
  // ADD NEW MEASUREMENT ITEM DIALOG
  // ==========================================================================

  void _showAddMeasurementDialog() {
    final itemNoCtrl = TextEditingController(text: 'BoQ 6.12');
    final descCtrl = TextEditingController(
        text: 'Casing insulator & end-seal assembly for 18" carrier pipe under NH-37 crossing');
    final chFromCtrl = TextEditingController(text: '16.270');
    final chToCtrl = TextEditingController(text: '16.350');
    final lengthCtrl = TextEditingController(text: '80.0');
    final widthCtrl = TextEditingController(text: '1.0');
    final depthCtrl = TextEditingController(text: '1.0');
    final multCtrl = TextEditingController(text: '1');
    final rateCtrl = TextEditingController(text: '4500.0');
    String selectedUnit = 'Meter';
    String selectedSection = 'Earthwork & Trenching';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final l = double.tryParse(lengthCtrl.text) ?? 0.0;
            final w = double.tryParse(widthCtrl.text) ?? 0.0;
            final d = double.tryParse(depthCtrl.text) ?? 0.0;
            final m = int.tryParse(multCtrl.text) ?? 1;
            final r = double.tryParse(rateCtrl.text) ?? 0.0;

            double calcQty = 0.0;
            if (selectedUnit == 'm³') {
              calcQty = l * w * d * m;
            } else if (selectedUnit == 'Meter') {
              calcQty = l * m;
            } else if (selectedUnit == 'Joint' || selectedUnit == 'Nos') {
              calcQty = m.toDouble();
            } else {
              calcQty = l * w * d * m;
            }
            final totalAmt = calcQty * r;

            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(40),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.post_add_rounded, color: AppTheme.primaryLight, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New e-MB Ledger Measurement (Form 23)',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Record chainage, dimensions and auto-calculate quantity',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                          onPressed: () => Navigator.pop(bottomSheetCtx),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.border, height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: itemNoCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'BoQ Item No.',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedSection,
                            dropdownColor: AppTheme.surfaceCard,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'WBS Section',
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Earthwork & Trenching', child: Text('Earthwork')),
                              DropdownMenuItem(value: 'Stringing & Bending', child: Text('Stringing')),
                              DropdownMenuItem(value: 'Welding & NDT', child: Text('Welding & NDT')),
                              DropdownMenuItem(value: 'Coating & Joint', child: Text('Coating')),
                              DropdownMenuItem(value: 'Lowering & Backfilling', child: Text('Lowering')),
                              DropdownMenuItem(value: 'HDD Crossing', child: Text('HDD Crossing')),
                              DropdownMenuItem(value: 'Restoration', child: Text('Restoration')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedSection = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'BoQ Work Description (CPWD Specification)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: chFromCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'Chainage From (KM)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: chToCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'Chainage To (KM)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedUnit,
                            dropdownColor: AppTheme.surfaceCard,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'm³', child: Text('m³')),
                              DropdownMenuItem(value: 'Meter', child: Text('Meter')),
                              DropdownMenuItem(value: 'Joint', child: Text('Joint')),
                              DropdownMenuItem(value: 'Nos', child: Text('Nos')),
                              DropdownMenuItem(value: 'MT', child: Text('MT')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedUnit = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: lengthCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            decoration: const InputDecoration(labelText: 'Length (L) m', isDense: true),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: widthCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            decoration: const InputDecoration(labelText: 'Width (W) m', isDense: true),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: depthCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            decoration: const InputDecoration(labelText: 'Depth (D) m', isDense: true),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: multCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            decoration: const InputDecoration(labelText: 'Nos / Multiplier', isDense: true),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'BoQ Agreed Rate (INR ₹)',
                        isDense: true,
                        prefixText: '₹ ',
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 14),
                    // Live Computed Readout
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryLight.withAlpha(100)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CALCULATED QUANTITY',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text('${_numFormat.format(calcQty)} $selectedUnit',
                                    style: const TextStyle(color: AppTheme.primaryLight, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 30, color: AppTheme.border),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ESTIMATED VALUE',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(_inrFormat.format(totalAmt),
                                    style: const TextStyle(color: AppTheme.tertiary, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Add Item to e-MB Ledger'),
                        onPressed: () {
                          final newItem = MeasurementItem(
                            id: 'EMB-2026-07-00${_ledgerItems.length + 1}',
                            itemNo: itemNoCtrl.text.trim(),
                            boqDescription: descCtrl.text.trim(),
                            section: selectedSection,
                            chainageFrom: double.tryParse(chFromCtrl.text) ?? 16.0,
                            chainageTo: double.tryParse(chToCtrl.text) ?? 16.5,
                            length: l,
                            width: w,
                            depth: d,
                            multiplier: m,
                            unit: selectedUnit,
                            boqRate: r,
                            previousQty: 0.0,
                            gpsCoords: '27.3180° N, 95.3480° E',
                            measurementDate: DateTime.now(),
                            surveyorName: 'Er. Alok Nath (Chief Surveyor)',
                            status: TripartiteSignStatus.contractorSigned,
                          );

                          setState(() {
                            _ledgerItems.add(newItem);
                            _auditLogs.insert(
                              0,
                              EmbAuditLog(
                                eventId: 'EVT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                timestamp: DateTime.now(),
                                actionTitle: 'New e-MB Measurement Entry Recorded',
                                actorName: 'Er. Alok Nath',
                                actorRole: 'EPC Contractor Chief Surveyor',
                                itemRef: newItem.itemNo,
                                hashDigest: newItem.sha256Digest,
                                gpsStamp: newItem.gpsCoords,
                                icon: Icons.add_circle_outline_rounded,
                                statusColor: AppTheme.primaryLight,
                              ),
                            );
                          });

                          Navigator.pop(bottomSheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.primary,
                              content: Text('Item ${newItem.itemNo} logged to e-MB Ledger with SHA-256 seal.'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================================
  // ITEM DETAIL / FORM 23 DIMENSION SHEET MODAL
  // ==========================================================================

  void _showItemDetailSheet(MeasurementItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.itemNo,
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.status.color.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.status.label,
                        style: TextStyle(
                          color: item.status.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.boqDescription,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4),
                ),
                const Divider(color: AppTheme.border, height: 24),
                const Text('CPWD FORM 23 DIMENSION MATRIX',
                    style: TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: AppTheme.border, borderRadius: BorderRadius.circular(6)),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh),
                      children: const [
                        Padding(padding: EdgeInsets.all(6), child: Text('Length (m)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Width (m)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Depth (m)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Nos / Mult', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Quantity', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.all(8), child: Text('${item.length}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(8), child: Text('${item.width}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(8), child: Text('${item.depth}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(8), child: Text('${item.multiplier}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(8), child: Text('${_numFormat.format(item.measuredQty)} ${item.unit}', style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 4,
                  children: [
                    Text('Contract BoQ Rate: ₹ ${_numFormat.format(item.boqRate)} / ${item.unit}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    Text('Gross: ${_inrFormat.format(item.grossAmount)}',
                        style: const TextStyle(color: AppTheme.tertiary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(color: AppTheme.border, height: 24),
                const Text('CHAINAGE & GEOGRAPHIC IDENTIFIERS',
                    style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.add_road_rounded, color: AppTheme.textSecondary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Chainage: KM ${item.chainageFrom.toStringAsFixed(3)} to KM ${item.chainageTo.toStringAsFixed(3)} (Span: ${((item.chainageTo - item.chainageFrom) * 1000).toStringAsFixed(0)} m)',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppTheme.secondary, size: 16),
                    const SizedBox(width: 6),
                    Text('GPS Site Anchor: ${item.gpsCoords}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'monospace')),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_rounded, color: AppTheme.textSecondary, size: 16),
                    const SizedBox(width: 6),
                    Text('Field Surveyor: ${item.surveyorName}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
                const Divider(color: AppTheme.border, height: 24),
                const Text('IMMUTABLE SHA-256 RECORD HASH',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.sha256Digest,
                          style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: AppTheme.textSecondary, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: item.sha256Digest));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('SHA-256 hash copied to clipboard.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // BUILD METHOD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'e-MB & Progress Billing (RA Bills)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'CPWD Works Manual Form 23/26 • Oil India Limited Trunkline',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Run Cryptographic Integrity Check',
            icon: Icon(
              Icons.security_rounded,
              color: _integrityResult == true ? AppTheme.tertiary : AppTheme.primaryLight,
            ),
            onPressed: _isVerifyingIntegrity ? null : _runCryptographicIntegrityCheck,
          ),
          IconButton(
            tooltip: 'EIC Administrative Sanction',
            icon: Icon(
              _isEicApproved ? Icons.check_circle_rounded : Icons.lock_clock_rounded,
              color: _isEicApproved ? AppTheme.tertiary : AppTheme.secondary,
            ),
            onPressed: _showEicApprovalDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondary,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'e-MB Ledger (Form 23)'),
            Tab(icon: Icon(Icons.rule_rounded, size: 18), text: 'Tripartite Signatures'),
            Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'RA Bill Deductions (Form 26)'),
            Tab(icon: Icon(Icons.fingerprint_rounded, size: 18), text: 'Immutable Audit Trail'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildExecutiveSummaryHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmbLedgerTab(),
                _buildTripartiteSignaturesTab(),
                _buildRaBillDeductionsTab(),
                _buildAuditTrailTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_chart_rounded, size: 20),
        label: const Text('Add e-MB Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        onPressed: _showAddMeasurementDialog,
      ),
    );
  }

  // ==========================================================================
  // TOP EXECUTIVE SUMMARY HEADER
  // ==========================================================================

  Widget _buildExecutiveSummaryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryLight, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'OIL/DKPL-18/CIVIL-PL/2025/PKG-02',
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isEicApproved
                                ? AppTheme.tertiary.withAlpha(35)
                                : AppTheme.secondary.withAlpha(35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _isEicApproved ? 'RA-07 EIC SANCTIONED' : 'TPIA VERIFIED / PENDING EIC',
                            style: TextStyle(
                              color: _isEicApproved ? AppTheme.tertiary : AppTheme.secondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'RA Bill No. 07 (01-Sep-2026 to 25-Sep-2026) • 18" Dia Trunkline Duliajan',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildHeaderStatCard(
                label: 'GROSS RA BILL',
                value: _inrFormat.format(_grossCurrentBillAmount),
                subValue: '8 e-MB Items',
                color: AppTheme.primaryLight,
              ),
              const SizedBox(width: 8),
              _buildHeaderStatCard(
                label: 'TOTAL DEDUCTIONS',
                value: _inrFormat.format(_totalDeductions),
                subValue: 'TDS, Cess, Adv & Ret',
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 8),
              _buildHeaderStatCard(
                label: 'NET PAYABLE RELEASE',
                value: _inrFormat.format(_netPayableRelease),
                subValue: 'Treasury NEFT/RTGS',
                color: AppTheme.tertiary,
              ),
            ],
          ),
          if (_isVerifyingIntegrity) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryLight),
                ),
                const SizedBox(width: 8),
                Text(
                  'Computing SHA-256 digest for item $_verifiedCount of ${_ledgerItems.length}...',
                  style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderStatCard({
    required String label,
    required String value,
    required String subValue,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 2),
            Text(subValue, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 1: e-MB LEDGER (CPWD FORM 23)
  // ==========================================================================

  Widget _buildEmbLedgerTab() {
    final filtered = _filteredLedgerItems;

    return Column(
      children: [
        // Filter & Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: AppTheme.surface,
          child: Column(
            children: [
              TextField(
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search BoQ Item, description, chainage or ID...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 16),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSectionChip('ALL', 'All Sections (${_ledgerItems.length})'),
                    const SizedBox(width: 6),
                    _buildSectionChip('Earthwork & Trenching', 'Trenching'),
                    const SizedBox(width: 6),
                    _buildSectionChip('Stringing & Bending', 'Stringing'),
                    const SizedBox(width: 6),
                    _buildSectionChip('Welding & NDT', 'Welding & NDT'),
                    const SizedBox(width: 6),
                    _buildSectionChip('Coating & Joint', 'Coating'),
                    const SizedBox(width: 6),
                    _buildSectionChip('HDD Crossing', 'HDD Crossing'),
                    const SizedBox(width: 6),
                    _buildSectionChip('Lowering & Backfilling', 'Lowering'),
                    const SizedBox(width: 6),
                    _buildSectionChip('Restoration', 'Restoration'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Ledger List
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('No e-MB items found matching filter.', style: TextStyle(color: AppTheme.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildEmbLedgerCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSectionChip(String sectionKey, String label) {
    final isSelected = _selectedSection == sectionKey;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: AppTheme.surfaceCard,
      selectedColor: AppTheme.primary,
      side: BorderSide(color: isSelected ? AppTheme.primaryLight : AppTheme.border),
      onSelected: (_) => setState(() => _selectedSection = sectionKey),
    );
  }

  Widget _buildEmbLedgerCard(MeasurementItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showItemDetailSheet(item),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Item No & Chainage Badge & Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.itemNo,
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_road_rounded, color: AppTheme.textSecondary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'KM ${item.chainageFrom.toStringAsFixed(3)} - ${item.chainageTo.toStringAsFixed(3)}',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.status.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.status.icon, color: item.status.color, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          item.status.label,
                          style: TextStyle(
                            color: item.status.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.boqDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, height: 1.3),
              ),
              const SizedBox(height: 8),
              // Dimensions strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  'DIMENSIONS: ${item.length.toStringAsFixed(1)}m (L) × ${item.width.toStringAsFixed(1)}m (W) × ${item.depth.toStringAsFixed(1)}m (D) [×${item.multiplier}]',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              // Quantity & Rate row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CURRENT MEASURED', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                        const SizedBox(height: 1),
                        Text(
                          '${_numFormat.format(item.measuredQty)} ${item.unit}',
                          style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BOQ RATE', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                        const SizedBox(height: 1),
                        Text(
                          '₹ ${_numFormat.format(item.boqRate)}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('GROSS AMOUNT', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                        const SizedBox(height: 1),
                        Text(
                          _inrFormat.format(item.grossAmount),
                          style: const TextStyle(color: AppTheme.tertiary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.border, height: 16),
              // Cumulative & Hash Row
              Row(
                children: [
                  Text(
                    'Up to Date: ${_numFormat.format(item.upToDateQty)} ${item.unit}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  ),
                  const Spacer(),
                  const Icon(Icons.tag_rounded, color: AppTheme.textMuted, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    'SHA-256: ${item.sha256Digest.substring(0, 8)}...${item.sha256Digest.substring(56)}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 2: TRIPARTITE DIGITAL SIGNATURES & APPROVALS
  // ==========================================================================

  Widget _buildTripartiteSignaturesTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      children: [
        // Governance Overview Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.rule_folder_rounded, color: AppTheme.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3-TIER TRIPARTITE SIGN-OFF GOVERNANCE',
                      style: TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'CPWD Works Manual Section 10 & FIDIC Cl. 14.3 mandate sequential approvals: EPC Contractor PM -> TPIA QC Agency -> Owner EIC.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Agency Selector (TPIA)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const Text('Assigned TPIA Agency:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<TpiaAgency>(
                  value: _selectedTpia,
                  dropdownColor: AppTheme.surfaceCard,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                  items: TpiaAgency.values.map((agency) {
                    return DropdownMenuItem(
                      value: agency,
                      child: Text(agency.fullName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTpia = val);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // LEVEL 1: CONTRACTOR PROJECT MANAGER
        _buildSignatoryCard(
          level: 1,
          title: 'LEVEL 1: CONTRACTOR PROJECT MANAGER',
          statusText: 'SIGNED & SUBMITTED',
          statusColor: AppTheme.primaryLight,
          icon: Icons.assignment_turned_in_rounded,
          signatory: SignatoryRecord(
            level: 1,
            levelTitle: 'EPC Consortium Project Director',
            signatoryName: 'Er. Rajesh Sarma',
            designation: 'Project Director & Authorized Signatory',
            organization: 'Kalpataru-Corrpro Consortium JV',
            dscTokenId: 'DSC-Class3-8891-KCL-2026',
            certificateSerial: '2026/eMudhra/OIL/44091',
            signedDate: DateTime(2026, 9, 22, 17, 45),
            geolocation: 'EPC Site Camp Ch 12+450 (27.2941° N, 95.3188° E)',
            referenceNote: 'CPWD Form 23 Cl. 10.3 / FIDIC Cl. 14.3',
            isApproved: true,
            remarks: 'All 8 field measurement entries verified against cross-section drawings and daily inspection reports. Submitted for TPIA verification.',
          ),
        ),
        const SizedBox(height: 12),

        // LEVEL 2: THIRD PARTY INSPECTION AGENCY (TPIA)
        _buildSignatoryCard(
          level: 2,
          title: 'LEVEL 2: THIRD PARTY INSPECTION AGENCY (TPIA)',
          statusText: 'VERIFIED & DIGITALLY SEALED',
          statusColor: AppTheme.secondary,
          icon: Icons.verified_user_rounded,
          signatory: SignatoryRecord(
            level: 2,
            levelTitle: 'Lead Pipeline Quality Surveyor',
            signatoryName: 'Er. Debabrata Borah',
            designation: 'Senior Inspection Engineer (Pipelines)',
            organization: _selectedTpia.fullName,
            dscTokenId: '${_selectedTpia.certPrefix}-7712',
            certificateSerial: 'EIL/NDT/QRA/2026/9941',
            signedDate: DateTime(2026, 9, 23, 19, 15),
            geolocation: 'Burhi Dihing Crossing Site (27.3150° N, 95.3450° E)',
            referenceNote: 'IRN No.: EIL/OIL/IRN/2026/089 (25.4% Physical Site Check)',
            isApproved: true,
            remarks: '25.4% random spot measurements checked at site against laser distance meter. 100% weld radiography records and HDD torque log approved. No deviations noted.',
          ),
        ),
        const SizedBox(height: 12),

        // LEVEL 3: OIL INDIA LTD ENGINEER-IN-CHARGE (EIC)
        _buildSignatoryCard(
          level: 3,
          title: 'LEVEL 3: OIL INDIA LTD ENGINEER-IN-CHARGE (EIC)',
          statusText: _isEicApproved ? 'SANCTIONED & CERTIFIED' : 'PENDING EIC FINAL SANCTION',
          statusColor: _isEicApproved ? AppTheme.tertiary : AppTheme.secondary,
          icon: _isEicApproved ? Icons.verified_rounded : Icons.pending_actions_rounded,
          signatory: SignatoryRecord(
            level: 3,
            levelTitle: 'Superintending Engineer (EIC)',
            signatoryName: 'Er. Anupam Hazarika',
            designation: 'Superintending Engineer (Pipelines Directorate)',
            organization: 'Oil India Limited (Duliajan HQ)',
            dscTokenId: 'OIL-EIC-9921-GOVT (ePass2003)',
            certificateSerial: 'OIL/FIN/SANCT/2026/092',
            signedDate: _eicApprovalTimestamp ?? DateTime(2026, 9, 24, 10, 00),
            geolocation: 'OIL Corporate HQ, Duliajan (27.2941° N, 95.3188° E)',
            referenceNote: _eicSanctionVoucherRef,
            isApproved: _isEicApproved,
            remarks: _eicNotes,
          ),
          showActionButton: !_isEicApproved,
          actionButtonLabel: 'Sign & Sanction as EIC',
          onAction: _showEicApprovalDialog,
        ),
      ],
    );
  }

  Widget _buildSignatoryCard({
    required int level,
    required String title,
    required String statusText,
    required Color statusColor,
    required IconData icon,
    required SignatoryRecord signatory,
    bool showActionButton = false,
    String? actionButtonLabel,
    VoidCallback? onAction,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        signatory.organization,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
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
                  child: _buildSignDetail(
                    label: 'AUTHORIZED SIGNATORY',
                    value: signatory.signatoryName,
                    sub: signatory.designation,
                  ),
                ),
                Expanded(
                  child: _buildSignDetail(
                    label: 'TIMESTAMP (IST)',
                    value: DateFormat('dd-MMM-yyyy HH:mm').format(signatory.signedDate),
                    sub: signatory.referenceNote,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSignDetail(
                    label: 'DIGITAL SIGNATURE / DSC TOKEN',
                    value: signatory.dscTokenId,
                    sub: signatory.certificateSerial,
                  ),
                ),
                Expanded(
                  child: _buildSignDetail(
                    label: 'GEOLOCATION AT SIGN-OFF',
                    value: signatory.geolocation,
                    sub: 'Tamper-evident GPS Lock',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, color: AppTheme.textMuted, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      signatory.remarks,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            if (showActionButton && onAction != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.fingerprint_rounded, size: 18),
                  label: Text(actionButtonLabel ?? 'Sign Approval'),
                  onPressed: onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignDetail({
    required String label,
    required String value,
    required String sub,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 1),
        Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  // ==========================================================================
  // TAB 3: RA BILL & STATUTORY DEDUCTIONS (CPWD FORM 26)
  // ==========================================================================

  Widget _buildRaBillDeductionsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      children: [
        // Form 26 Official Header
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
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryLight, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'CPWD FORM 26: RUNNING ACCOUNT (RA) BILL',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FY 2026-27',
                      style: TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Account of work executed by Contractor and certificate of payment under Section 10 of CPWD Works Manual. All statutory deductions applied prior to release.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Financial Breakdown Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FINANCIAL LEDGER & BILL PARTICULARS',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 12),

                // 1. Gross Work Done
                _buildBillLineItem(
                  number: '1',
                  label: 'Gross Value of Work Executed (Current Bill)',
                  subLabel: 'Total of 8 measured items in e-MB Ledger Vol-14',
                  amount: _grossCurrentBillAmount,
                  isPositive: true,
                  highlight: false,
                ),
                const Divider(color: AppTheme.border, height: 16),

                // 2. GST Addition
                _buildBillLineItem(
                  number: '2',
                  label: 'Add: Goods & Services Tax (GST @ ${_gstRate.toStringAsFixed(1)}%)',
                  subLabel: 'CGST 9% (₹ ${_numFormat.format(_gstAmount / 2)}) + SGST 9% (₹ ${_numFormat.format(_gstAmount / 2)})',
                  amount: _gstAmount,
                  isPositive: true,
                  highlight: false,
                  customColor: AppTheme.primaryLight,
                ),
                const Divider(color: AppTheme.border, height: 16),

                // Subtotal with GST
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 4,
                  children: [
                    const Text('Subtotal Work Value including GST:',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(
                      _inrFormat.format(_grossCurrentBillAmount + _gstAmount),
                      style: const TextStyle(color: AppTheme.primaryLight, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.border, height: 20),

                // Statutory Deductions Header
                Row(
                  children: [
                    const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.secondary, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'STATUTORY & CONTRACTUAL DEDUCTIONS',
                      style: TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('Total: ${_inrFormat.format(_totalDeductions)}',
                        style: const TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),

                // 3a. GST TDS
                _buildBillLineItem(
                  number: '3a',
                  label: 'GST TDS @ ${_gstTdsRate.toStringAsFixed(1)}%',
                  subLabel: 'Section 51 of CGST Act 2017 (1% CGST + 1% SGST)',
                  amount: _gstTdsAmount,
                  isPositive: false,
                  highlight: false,
                ),
                const SizedBox(height: 8),

                // 3b. Income Tax TDS
                _buildBillLineItem(
                  number: '3b',
                  label: 'Income Tax TDS @ ${_itTdsRate.toStringAsFixed(1)}%',
                  subLabel: 'Section 194C of IT Act 1961 (Corporate Contractor)',
                  amount: _itTdsAmount,
                  isPositive: false,
                  highlight: false,
                ),
                const SizedBox(height: 8),

                // 3c. Labor Cess
                _buildBillLineItem(
                  number: '3c',
                  label: 'Labor Welfare Cess @ ${_laborCessRate.toStringAsFixed(1)}%',
                  subLabel: 'Building & Other Construction Workers (BOCW) Act 1996',
                  amount: _laborCessAmount,
                  isPositive: false,
                  highlight: false,
                ),
                const SizedBox(height: 8),

                // 3d. Mobilization Advance Recovery
                _buildBillLineItem(
                  number: '3d',
                  label: 'Mobilization Advance Recovery @ ${_mobAdvanceRate.toStringAsFixed(1)}%',
                  subLabel: 'CPWD Works Manual Clause 10B (Pro-rata amortization)',
                  amount: _mobAdvanceRecovery,
                  isPositive: false,
                  highlight: false,
                ),
                const SizedBox(height: 8),

                // 3e. Retention Money
                _buildBillLineItem(
                  number: '3e',
                  label: 'Security Deposit / Retention Money @ ${_retentionRate.toStringAsFixed(1)}%',
                  subLabel: 'CPWD Clause 1A / FIDIC Cl. 14.3 (Defects Liability Security)',
                  amount: _retentionAmount,
                  isPositive: false,
                  highlight: false,
                ),
                const Divider(color: AppTheme.border, height: 24),

                // Final Net Certified
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.tertiary.withAlpha(120)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 6,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NET CERTIFIED PAYABLE RELEASE',
                            style: TextStyle(
                              color: AppTheme.tertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'CPWD Form 26 Memorandum of Payments',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                      Text(
                        _inrFormat.format(_netPayableRelease),
                        style: const TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Statutory Compliance Tokens
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STATUTORY TAX MANDATES & CLEARANCES',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildComplianceRow(
                code: 'GSTIN',
                value: '18AAACL1234F1Z8 (Assam State)',
                status: 'VERIFIED ACTIVE',
                isValid: true,
              ),
              const SizedBox(height: 6),
              _buildComplianceRow(
                code: 'PAN',
                value: 'AAACK7788P (EPC JV)',
                status: 'LINKED WITH AADHAAR',
                isValid: true,
              ),
              const SizedBox(height: 6),
              _buildComplianceRow(
                code: 'BOCW',
                value: 'ASSAM/BOCW/DUL/2024/99',
                status: 'ANNUAL CESS DEPOSITED',
                isValid: true,
              ),
              const SizedBox(height: 6),
              _buildComplianceRow(
                code: 'PF / ESI',
                value: 'TRRN 101260900144 (Sept 2026)',
                status: 'WAGE COMPLIANCE CERTIFIED',
                isValid: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Statutory Rate Customizer (Accordion / Expander)
        ExpansionTile(
          collapsedBackgroundColor: AppTheme.surfaceCard,
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppTheme.border)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppTheme.border)),
          leading: const Icon(Icons.tune_rounded, color: AppTheme.primaryLight, size: 20),
          title: const Text(
            'Statutory Rate & Recovery Adjustments',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Simulate custom deduction percentages per contract conditions',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _buildSliderAdjustment(
                    label: 'GST TDS Rate (%):',
                    value: _gstTdsRate,
                    min: 0.0,
                    max: 5.0,
                    onChanged: (val) => setState(() => _gstTdsRate = val),
                  ),
                  _buildSliderAdjustment(
                    label: 'Income Tax TDS Rate (%):',
                    value: _itTdsRate,
                    min: 0.0,
                    max: 5.0,
                    onChanged: (val) => setState(() => _itTdsRate = val),
                  ),
                  _buildSliderAdjustment(
                    label: 'BOCW Labor Cess Rate (%):',
                    value: _laborCessRate,
                    min: 0.0,
                    max: 3.0,
                    onChanged: (val) => setState(() => _laborCessRate = val),
                  ),
                  _buildSliderAdjustment(
                    label: 'Mobilization Advance Recovery (%):',
                    value: _mobAdvanceRate,
                    min: 0.0,
                    max: 20.0,
                    onChanged: (val) => setState(() => _mobAdvanceRate = val),
                  ),
                  _buildSliderAdjustment(
                    label: 'Retention Money Withholding (%):',
                    value: _retentionRate,
                    min: 0.0,
                    max: 10.0,
                    onChanged: (val) => setState(() => _retentionRate = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBillLineItem({
    required String number,
    required String label,
    required String subLabel,
    required double amount,
    required bool isPositive,
    bool highlight = false,
    Color? customColor,
  }) {
    final textColor = customColor ??
        (isPositive ? AppTheme.textPrimary : const Color(0xFFF87171));
    final prefix = isPositive ? '+ ' : '- ';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(number, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subLabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ),
        ),
        Text(
          '$prefix${_inrFormat.format(amount)}',
          style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildComplianceRow({
    required String code,
    required String value,
    required String status,
    required bool isValid,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(
            code,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.primaryLight, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontFamily: 'monospace')),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.tertiary.withAlpha(30),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, color: AppTheme.tertiary, size: 12),
              const SizedBox(width: 2),
              Text(status, style: const TextStyle(color: AppTheme.tertiary, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderAdjustment({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text('$label ${value.toStringAsFixed(1)}%',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ),
        Expanded(
          flex: 3,
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 20,
            activeColor: AppTheme.primaryLight,
            inactiveColor: AppTheme.border,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 4: IMMUTABLE AUDIT TRAIL & HASH VERIFICATION
  // ==========================================================================

  Widget _buildAuditTrailTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      children: [
        // Merkle & Hash Explanation Banner
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
              Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, color: AppTheme.tertiary, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IMMUTABLE CRYPTOGRAPHIC VERIFICATION',
                          style: TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Every e-MB entry produces a deterministic SHA-256 hash. Zero tampering tolerance.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      foregroundColor: AppTheme.tertiary,
                      side: const BorderSide(color: AppTheme.tertiary),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.verified_rounded, size: 16),
                    label: const Text('Verify All', style: TextStyle(fontSize: 11)),
                    onPressed: _runCryptographicIntegrityCheck,
                  ),
                ],
              ),
              if (_integrityResult != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _integrityResult! ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _integrityResult! ? Icons.verified_user_rounded : Icons.warning_rounded,
                        color: _integrityResult! ? AppTheme.tertiary : Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _integrityResult!
                              ? 'STATUS: ALL ${_ledgerItems.length} ITEMS CRYPTOGRAPHICALLY VALID (0 TAMPERING)'
                              : 'STATUS: HASH MISMATCH DETECTED IN LEDGER',
                          style: TextStyle(
                            color: _integrityResult! ? AppTheme.tertiary : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
        const SizedBox(height: 14),

        // Live Items Hash Digest Table
        const Text(
          'e-MB ITEM CRYPTOGRAPHIC DIGESTS (CURRENT RA BILL)',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ..._ledgerItems.map((item) {
          final isClean = item.verifyHash();
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Icon(
                  isClean ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                  color: isClean ? AppTheme.tertiary : Colors.redAccent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  item.itemNo,
                  style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.sha256Digest,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppTheme.textSecondary, size: 14),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.sha256Digest));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hash for ${item.itemNo} copied.')),
                    );
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),

        // Chronological Audit Event Trail
        const Text(
          'CHRONOLOGICAL AUDIT EVENT TRAIL',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ..._auditLogs.map((log) => _buildAuditLogCard(log)),
      ],
    );
  }

  Widget _buildAuditLogCard(EmbAuditLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: log.statusColor.withAlpha(35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(log.icon, color: log.statusColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.actionTitle,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${log.actorName} • ${log.actorRole}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd-MMM HH:mm').format(log.timestamp),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.share_location_rounded, color: AppTheme.textMuted, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      log.gpsStamp,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Digest: ${log.hashDigest}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
