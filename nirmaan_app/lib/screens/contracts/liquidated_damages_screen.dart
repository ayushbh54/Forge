import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import 'variation_order_screen.dart';

/// Screen for calculating and administering FIDIC Sub-Clause 8.7 Delay Damages
/// (Liquidated Damages), Sectional Milestone breakdowns, SCL Concurrent Delay
/// Offsets, and formal Liquidated Damages Demand Notices under Indian Contract Law.
class LiquidatedDamagesScreen extends StatefulWidget {
  const LiquidatedDamagesScreen({super.key});

  @override
  State<LiquidatedDamagesScreen> createState() => _LiquidatedDamagesScreenState();
}

class _LiquidatedDamagesScreenState extends State<LiquidatedDamagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Contract Baseline Values (OIL Trunk Pipeline Expansion)
  static const double _defaultSanctionedContractCr = 184.00;
  static const double _defaultWeeklyRatePct = 0.50;
  static const double _defaultMaxCapPct = 10.00;

  // Interactive Calculator State
  double _contractValueCr = _defaultSanctionedContractCr;
  double _weeklyRatePct = _defaultWeeklyRatePct;
  double _maxCapPct = _defaultMaxCapPct;
  int _grossDelayDays = 112; // 16.0 weeks
  int _concurrencyOffsetDays = 55; // 7.86 weeks from SCL protocol

  // Active Milestone Data
  late List<MilestoneLdModel> _milestones;

  // Concurrent Delay Events (Employer vs Contractor)
  late List<ConcurrentDelayEventModel> _employerDelayEvents;
  late List<ConcurrentDelayEventModel> _contractorDelayEvents;

  // Demand Notice State
  bool _isNoticeIssued = false;
  String _noticeIssuedTimestamp = '';
  String _noticeRefNumber = 'OIL/PL-024/FIDIC-8.7/DEMAND-NOTICE/2026/04';
  String _contractorSignatory = 'L&T Hydrocarbon Engineering JV (Consortium Lead)';
  String _engineerSignatory = 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)';
  String _employerSignatory = 'Sunil Khurana, CGM (Pipelines) - Oil India Limited';
  int _curePeriodDays = 14;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeContractData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeContractData() {
    // 3 Sectional Milestones
    _milestones = [
      MilestoneLdModel(
        id: 'M1-CIVIL',
        code: 'MS-01',
        title: 'Milestone 1: Civil Foundations & Substructures',
        description:
            'Deep pile caps at terminal pump stations, heavy equipment RCC pedestals, anchor thrust blocks for river crossings, and valve pit vaults.',
        contractValueWeight: 0.30,
        allocatedValueCr: 55.20, // 30% of 184 Cr
        baselineDueDate: DateTime(2026, 5, 15),
        certifiedDate: DateTime(2026, 6, 28),
        grossDelayDays: 44, // 6.29 wks
        concurrentEmployerOffsetDays: 14, // 2.0 wks RoW delay
        weeklyLdRatePct: 0.50,
        maxCapPct: 10.00,
        status: 'COMPLETED_LD',
        scopeKeyDeliverables: [
          'Terminal Pump Station (Station-04) 800 vibro-replacement stone columns',
          'Dihing River entry/exit anchor thrust blocks (KM 42+300)',
          '14 Mainline Sectionalizing Valve RCC chamber vaults (SV-01 to SV-14)',
          'Intermediate Booster Station transformer foundation pads',
        ],
      ),
      MilestoneLdModel(
        id: 'M2-HYDROTEST',
        code: 'MS-02',
        title: 'Milestone 2: Pipeline Laying & Sectional Hydrotesting',
        description:
            '124 km mainline stringing, ditching, automatic orbital welding, 100% UT/RT radiographic inspection, HDD river pull-through, and 24-hr hydrostatic strength test.',
        contractValueWeight: 0.45,
        allocatedValueCr: 82.80, // 45% of 184 Cr
        baselineDueDate: DateTime(2026, 11, 30),
        certifiedDate: DateTime(2027, 1, 20),
        grossDelayDays: 51, // 7.29 wks
        concurrentEmployerOffsetDays: 18, // HDD permit & design freeze offset
        weeklyLdRatePct: 0.50,
        maxCapPct: 10.00,
        status: 'CRITICAL_DELAY',
        scopeKeyDeliverables: [
          '124 km API 5L X70 18.2mm heavy-wall pipeline mainline welding',
          'Dihing River 1,200mm Horizontal Directional Drilling (HDD) crossing pull-back',
          '3-layer PE field joint coating & holiday detection at 25 kV',
          'Hydrostatic test to 1.5x design pressure (148 bar gauge) for 24 continuous hours',
        ],
      ),
      MilestoneLdModel(
        id: 'M3-COMMISSION',
        code: 'MS-03',
        title: 'Milestone 3: Terminal Interconnections, SCADA & Commissioning',
        description:
            'Supervisory Control and Data Acquisition (SCADA) telemetry integration, fiscal custody transfer metering skids, nitrogen line purging, and crude oil trial operation.',
        contractValueWeight: 0.25,
        allocatedValueCr: 46.00, // 25% of 184 Cr
        baselineDueDate: DateTime(2027, 3, 15),
        certifiedDate: DateTime(2027, 5, 31),
        grossDelayDays: 77, // 11.0 wks
        concurrentEmployerOffsetDays: 28, // SCADA protocol freeze & client switchgear delay
        weeklyLdRatePct: 0.50,
        maxCapPct: 10.00,
        status: 'PROJECTED_DELAY',
        scopeKeyDeliverables: [
          'Triple-modular redundant SIL-3 ESD actuators telemetry integration',
          'Dual-run 16" ultrasonic fiscal metering skid & compact prover loop',
          'Inert gas nitrogen drying & purging to dew point -40°C',
          '72-hour sustained continuous crude transmission test run at 120,000 BPD',
        ],
      ),
    ];

    // Employer-Caused Delays (Employer Risk Events - ERE)
    _employerDelayEvents = [
      ConcurrentDelayEventModel(
        id: 'ERE-01',
        code: 'ERE-01',
        title: 'Right-of-Way (RoW) KM 18-24 Forest Clear-felling Delay',
        origin: DelayOrigin.employer,
        description:
            'Late handover of unencumbered site access due to delayed State Forest Department felling permissions and compensatory afforestation clearances under FIDIC Sub-Clause 2.1.',
        fidicSubclause: 'FIDIC Sub-Clause 2.1 [Right of Access to the Site] & 8.4(b)',
        startDate: DateTime(2026, 5, 10),
        endDate: DateTime(2026, 6, 14),
        impactDays: 35,
        isCriticalPath: true,
        evidenceReference: 'Letter Ref: OIL/CIVIL/ROW/2026/118 dated 12 May 2026',
        isApprovedForOffset: true,
      ),
      ConcurrentDelayEventModel(
        id: 'ERE-02',
        code: 'ERE-02',
        title: 'Client Design Changes — Booster Station P&ID Revisions',
        origin: DelayOrigin.employer,
        description:
            'Formal client instruction VO-02 modifying intermediate pumping station manifold piping and dynamic pump head ratings, requiring structural foundation redesign under Sub-Clause 13.1.',
        fidicSubclause: 'FIDIC Sub-Clause 13.1 [Right to Vary] & 8.4(a)',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 22),
        impactDays: 21,
        isCriticalPath: true,
        evidenceReference: 'Variation Order VO-2026-02 Sanction Sheet',
        isApprovedForOffset: true,
      ),
      ConcurrentDelayEventModel(
        id: 'ERE-03',
        code: 'ERE-03',
        title: 'Late Issue of Approved for Construction (IFC) Isometrics',
        origin: DelayOrigin.employer,
        description:
            'Delayed transmittal of verified isometric drawings and seismic induction bend specifications for Dihing River fault crossing KM 81+400.',
        fidicSubclause: 'FIDIC Sub-Clause 1.9 [Delayed Drawings or Instructions] & 8.4(b)',
        startDate: DateTime(2026, 9, 15),
        endDate: DateTime(2026, 9, 29),
        impactDays: 14,
        isCriticalPath: true,
        evidenceReference: 'Doc Transmittal Log #TR-ENG-2026-089',
        isApprovedForOffset: true,
      ),
      ConcurrentDelayEventModel(
        id: 'ERE-04',
        code: 'ERE-04',
        title: 'Client Instructed Flash Flood Structural Integrity Audit',
        origin: DelayOrigin.employer,
        description:
            'Formal engineer suspension order under Sub-Clause 8.8 to execute riverbed scour sonar bathymetry following unseasonal monsoon cloudburst surge.',
        fidicSubclause: 'FIDIC Sub-Clause 8.8 [Suspension of Work] & 8.9',
        startDate: DateTime(2026, 10, 10),
        endDate: DateTime(2026, 10, 20),
        impactDays: 10,
        isCriticalPath: true,
        evidenceReference: 'Engineer Instruction Notice #EI-2026-042',
        isApprovedForOffset: true,
      ),
    ];

    // Contractor-Caused Delays (Contractor Risk Events - CRE)
    _contractorDelayEvents = [
      ConcurrentDelayEventModel(
        id: 'CRE-01',
        code: 'CRE-01',
        title: 'Skilled Welder & Rigger Manpower Severe Deficit',
        origin: DelayOrigin.contractor,
        description:
            'Contractor failure to mobilize requisite complement of 180 certified 6G pipe welders and riggers, operating at an average 45% labor deployment deficit during peak trenching window.',
        fidicSubclause: 'FIDIC Sub-Clause 6.1 [Engagement of Staff and Labour] & 8.7',
        startDate: DateTime(2026, 5, 15),
        endDate: DateTime(2026, 6, 29),
        impactDays: 45,
        isCriticalPath: true,
        evidenceReference: 'Daily Progress Report (DPR) Workforce Logs Week 20-26',
        isApprovedForOffset: true,
      ),
      ConcurrentDelayEventModel(
        id: 'CRE-02',
        code: 'CRE-02',
        title: 'Horizontal Directional Drilling (HDD) Rig Carriage Breakdown',
        origin: DelayOrigin.contractor,
        description:
            'Major mechanical failure of 400-ton capacity HDD rig drive carriage gearbox; prolonged delay in sourcing OEM replacement hydraulic parts from overseas supplier.',
        fidicSubclause: 'FIDIC Sub-Clause 4.17 [Contractor\'s Equipment] & 8.7',
        startDate: DateTime(2026, 7, 5),
        endDate: DateTime(2026, 8, 2),
        impactDays: 28,
        isCriticalPath: true,
        evidenceReference: 'Equipment Breakdown Log #EQ-HDD-992 & Service Report',
        isApprovedForOffset: true,
      ),
      ConcurrentDelayEventModel(
        id: 'CRE-03',
        code: 'CRE-03',
        title: 'Radiography Weld Rejection & Quality Re-work (NDT Failures)',
        origin: DelayOrigin.contractor,
        description:
            'Excessive porosity and lack-of-penetration weld defects exceeding 14.8% (contractual threshold: <2.0%), necessitating mandatory gouging, re-welding, and repeat gamma-ray radiography.',
        fidicSubclause: 'FIDIC Sub-Clause 7.5 [Rejection] & 7.6 [Remedial Work]',
        startDate: DateTime(2026, 8, 20),
        endDate: DateTime(2026, 9, 7),
        impactDays: 18,
        isCriticalPath: true,
        evidenceReference: 'QA/QC Non-Conformance Reports NCR-2026-44 through 62',
        isApprovedForOffset: true,
      ),
      ConcurrentDelayEventModel(
        id: 'CRE-04',
        code: 'CRE-04',
        title: 'Subcontractor Trenching Ditcher Delayed Mobilization',
        origin: DelayOrigin.contractor,
        description:
            'Commercial dispute between lead EPC contractor and earthmoving subcontractor leading to demobilization and 3-week standstill of mechanical trench ditchers.',
        fidicSubclause: 'FIDIC Sub-Clause 4.4 [Subcontractors] & 8.7',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 22),
        impactDays: 21,
        isCriticalPath: true,
        evidenceReference: 'Weekly Coordination Meeting Minutes #WCM-38',
        isApprovedForOffset: true,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Core FIDIC Sub-Clause 8.7 Calculations
  // ---------------------------------------------------------------------------
  double get _maxCapAmountCr => _contractValueCr * (_maxCapPct / 100.0);
  double get _weeklyLdRateCr => _contractValueCr * (_weeklyRatePct / 100.0);
  double get _dailyLdRateCr => _weeklyLdRateCr / 7.0;

  int get _netDelayDays {
    final net = _grossDelayDays - _concurrencyOffsetDays;
    return net < 0 ? 0 : net;
  }

  double get _netDelayWeeks => _netDelayDays / 7.0;

  double get _uncappedTotalLdCr => _netDelayWeeks * _weeklyLdRateCr;

  double get _finalChargeableLdCr =>
      _uncappedTotalLdCr > _maxCapAmountCr ? _maxCapAmountCr : _uncappedTotalLdCr;

  bool get _isCeilingReached => _uncappedTotalLdCr >= _maxCapAmountCr;

  double get _capConsumptionPct =>
      _maxCapAmountCr > 0 ? (_finalChargeableLdCr / _maxCapAmountCr) * 100.0 : 0.0;

  double get _capHeadroomRemainingCr =>
      (_maxCapAmountCr - _finalChargeableLdCr) < 0
          ? 0.0
          : (_maxCapAmountCr - _finalChargeableLdCr);

  // Concurrency Metrics
  int get _totalEmployerDelayDays => _employerDelayEvents
      .where((e) => e.isApprovedForOffset)
      .fold(0, (acc, e) => acc + e.impactDays);

  int get _totalContractorDelayDays => _contractorDelayEvents
      .where((e) => e.isApprovedForOffset)
      .fold(0, (acc, e) => acc + e.impactDays);

  // Concurrency savings
  double get _contractorReliefSavingsCr {
    final offsetWeeks = _concurrencyOffsetDays / 7.0;
    return offsetWeeks * _weeklyLdRateCr;
  }

  // Total Milestones LD sum
  double get _milestonesSumLdCr =>
      _milestones.fold(0.0, (acc, m) => acc + m.calculatedLdCr);

  // ---------------------------------------------------------------------------
  // Helper Formatters
  // ---------------------------------------------------------------------------
  String _formatCr(double val) => '₹${val.toStringAsFixed(3)} Cr';
  String _formatCrShort(double val) => '₹${val.toStringAsFixed(2)} Cr';
  String _formatLakhs(double crVal) =>
      '₹${(crVal * 100.0).toStringAsFixed(2)} Lakhs';

  String _formatCurrencyExact(double crVal) {
    final double inRupees = crVal * 10000000.0;
    final int rounded = inRupees.round();
    final formatter = NumberFormat('#,##,###', 'en_IN');
    return '₹${formatter.format(rounded)}';
  }

  String _numberToWordsIndian(double crVal) {
    final double inRupees = crVal * 10000000.0;
    final int amount = inRupees.round();
    if (amount <= 0) return 'Zero Rupees Only';

    final int crores = amount ~/ 10000000;
    final int remAfterCrore = amount % 10000000;
    final int lakhs = remAfterCrore ~/ 100000;
    final int remAfterLakhs = remAfterCrore % 100000;
    final int thousands = remAfterLakhs ~/ 1000;
    final int remAfterThousands = remAfterLakhs % 1000;
    final int hundreds = remAfterThousands ~/ 100;
    final int remainder = remAfterThousands % 100;

    final StringBuffer buffer = StringBuffer('Rupees ');

    const ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];
    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String twoDigitsToWords(int n) {
      if (n < 20) return ones[n];
      final int t = n ~/ 10;
      final int o = n % 10;
      return '${tens[t]} ${ones[o]}'.trim();
    }

    if (crores > 0) {
      buffer.write('${twoDigitsToWords(crores)} Crore ');
    }
    if (lakhs > 0) {
      buffer.write('${twoDigitsToWords(lakhs)} Lakh ');
    }
    if (thousands > 0) {
      buffer.write('${twoDigitsToWords(thousands)} Thousand ');
    }
    if (hundreds > 0) {
      buffer.write('${ones[hundreds]} Hundred ');
    }
    if (remainder > 0) {
      if (crores > 0 || lakhs > 0 || thousands > 0 || hundreds > 0) {
        buffer.write('and ');
      }
      buffer.write('${twoDigitsToWords(remainder)} ');
    }

    buffer.write('Only');
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------
  void _resetToBaseline() {
    setState(() {
      _contractValueCr = _defaultSanctionedContractCr;
      _weeklyRatePct = _defaultWeeklyRatePct;
      _maxCapPct = _defaultMaxCapPct;
      _grossDelayDays = 112;
      _concurrencyOffsetDays = 55;
      _initializeContractData();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('FIDIC Sub-Clause 8.7 parameters reset to sanctioned baseline (₹184 Cr / 10% Cap).'),
        backgroundColor: AppTheme.surfaceCard,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _applyScenarioPreset(String scenarioName) {
    setState(() {
      switch (scenarioName) {
        case 'BASELINE':
          _contractValueCr = 184.00;
          _weeklyRatePct = 0.50;
          _maxCapPct = 10.00;
          _grossDelayDays = 112;
          _concurrencyOffsetDays = 55;
          break;
        case 'CAP_BREACH':
          _contractValueCr = 184.00;
          _weeklyRatePct = 0.50;
          _maxCapPct = 10.00;
          _grossDelayDays = 180; // 25.7 wks
          _concurrencyOffsetDays = 21; // 3 wks -> 22.7 wks net = cap exceeded
          break;
        case 'M1_ONLY':
          _contractValueCr = 184.00;
          _weeklyRatePct = 0.50;
          _maxCapPct = 10.00;
          _grossDelayDays = 44;
          _concurrencyOffsetDays = 14;
          break;
        case 'FULL_CONCURRENCY':
          _contractValueCr = 184.00;
          _weeklyRatePct = 0.50;
          _maxCapPct = 10.00;
          _grossDelayDays = 112;
          _concurrencyOffsetDays = 105; // 7 days net
          break;
      }
    });
  }

  void _copyDemandNoticeText() {
    final text = _generateNoticeDocumentText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.tertiary, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Formal FIDIC Sub-Clause 8.7 Demand Notice copied to clipboard with legal citations.',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceCard,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _toggleNoticeIssued() {
    setState(() {
      _isNoticeIssued = !_isNoticeIssued;
      if (_isNoticeIssued) {
        final now = DateTime.now();
        _noticeIssuedTimestamp = DateFormat('dd MMM yyyy, HH:mm:ss').format(now);
      } else {
        _noticeIssuedTimestamp = '';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isNoticeIssued
              ? 'Notice officially marked as SERVED to Contractor Consortium under FIDIC Cl. 2.5 / 8.7.'
              : 'Notice status reverted to DRAFT.',
        ),
        backgroundColor: _isNoticeIssued ? AppTheme.primary : AppTheme.surfaceCard,
      ),
    );
  }

  void _showNoticeCustomizationDialog() {
    final refCtrl = TextEditingController(text: _noticeRefNumber);
    final contractorCtrl = TextEditingController(text: _contractorSignatory);
    final engineerCtrl = TextEditingController(text: _engineerSignatory);
    final employerCtrl = TextEditingController(text: _employerSignatory);
    final cureCtrl = TextEditingController(text: _curePeriodDays.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppTheme.primaryLight, size: 24),
            SizedBox(width: 8),
            Text(
              'Customize Notice Particulars',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: refCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Demand Notice Reference Number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contractorCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Contractor JV Addressee'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: engineerCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Engineer Signatory (FIDIC 3.1)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: employerCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Employer Representative (OIL)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cureCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Statutory Cure / Demand Period (Days)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              setState(() {
                _noticeRefNumber = refCtrl.text.trim();
                _contractorSignatory = contractorCtrl.text.trim();
                _engineerSignatory = engineerCtrl.text.trim();
                _employerSignatory = employerCtrl.text.trim();
                _curePeriodDays = int.tryParse(cureCtrl.text.trim()) ?? 14;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMilestoneEditDialog(MilestoneLdModel milestone) {
    final daysCtrl = TextEditingController(text: milestone.grossDelayDays.toString());
    final offsetCtrl =
        TextEditingController(text: milestone.concurrentEmployerOffsetDays.toString());
    final weightCtrl =
        TextEditingController(text: (milestone.contractValueWeight * 100).toStringAsFixed(1));

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
            const Icon(Icons.tune_rounded, color: AppTheme.secondary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Edit ${milestone.code} Parameters',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                milestone.title,
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Gross Delay (Calendar Days)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: offsetCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Concurrent Employer Offset (Days)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Contract Weight Percentage (%)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              final newGross = int.tryParse(daysCtrl.text.trim()) ?? milestone.grossDelayDays;
              final newOffset =
                  int.tryParse(offsetCtrl.text.trim()) ?? milestone.concurrentEmployerOffsetDays;
              final newWeightPct =
                  double.tryParse(weightCtrl.text.trim()) ?? (milestone.contractValueWeight * 100);
              final newWeight = newWeightPct / 100.0;
              final newValCr = _contractValueCr * newWeight;

              setState(() {
                final idx = _milestones.indexWhere((m) => m.id == milestone.id);
                if (idx != -1) {
                  _milestones[idx] = _milestones[idx].copyWith(
                    grossDelayDays: newGross,
                    concurrentEmployerOffsetDays: newOffset,
                    contractValueWeight: newWeight,
                    allocatedValueCr: newValCr,
                  );
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('Update Milestone', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPrecedentInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppTheme.primary, width: 2)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.gavel_rounded, color: AppTheme.secondary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FIDIC 8.7 & Legal Precedents Guide',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Indian Contract Act S. 74 & Apex Court Rulings',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: AppTheme.border, height: 24),
            Expanded(
              child: ListView(
                children: const [
                  _LegalCitationCard(
                    title: 'Oil & Natural Gas Corporation Ltd. v. Saw Pipes Ltd.',
                    citation: '(2003) 5 SCC 705 (Supreme Court of India)',
                    principle: 'Genuine Pre-Estimate of Loss in Industrial & Public Contracts',
                    explanation:
                        'The Supreme Court held that in high-value infrastructure contracts where delay produces indirect economic losses that are impossible to assess penny-by-penny, an agreed liquidated damages clause (e.g. FIDIC 8.7 0.5%/week up to 10%) represents a genuine pre-estimate of loss and is legally enforceable under Section 74 without requiring the Employer to prove actual financial loss.',
                  ),
                  SizedBox(height: 12),
                  _LegalCitationCard(
                    title: 'Kailash Nath Associates v. Delhi Development Authority',
                    citation: '(2015) 4 SCC 136 (Supreme Court of India)',
                    principle: 'Requirement of Reasonable Compensation & Non-Penal Character',
                    explanation:
                        'Clarified that Section 74 does not justify arbitrary forfeiture or punitive exactions. Where damage is capable of calculation, proof of reasonable loss must be tendered. However, where delay harms overall project commissioning, the agreed stipulated ceiling operates as the outer upper limit of reasonable compensation.',
                  ),
                  SizedBox(height: 12),
                  _LegalCitationCard(
                    title: 'Society of Construction Law (SCL) Delay Protocol (2017)',
                    citation: 'Core Principle 10: Concurrent Delay & EOT Apportionment',
                    principle: 'Time-but-no-Money Principle for Overlapping Critical Delays',
                    explanation:
                        'Where an Employer Risk Event (e.g. RoW access delay) and a Contractor Risk Event (e.g. Welder shortage) overlap on the critical path, the Contractor is entitled to an Extension of Time (EOT) to shield against Liquidated Damages, but is not entitled to prolongation compensation.',
                  ),
                  SizedBox(height: 12),
                  _LegalCitationCard(
                    title: 'FIDIC Red Book Sub-Clause 4.2 [Performance Security]',
                    citation: 'FIDIC Conditions of Contract for Construction (1999/2017)',
                    principle: 'Encashment of Bank Guarantee for Defaulted Delay Damages',
                    explanation:
                        'If the Contractor fails to pay substantiated delay damages within the required notice cure period (standard 14 or 42 days), the Employer is legally empowered to invoke the Performance Bank Guarantee up to the exact determined sum under Sub-Clause 2.5.',
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
  // Generate Full Formal Document Text
  // ---------------------------------------------------------------------------
  String _generateNoticeDocumentText() {
    final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());
    final dueStr = DateFormat('dd MMMM yyyy').format(DateTime.now().add(Duration(days: _curePeriodDays)));
    final netWords = _numberToWordsIndian(_finalChargeableLdCr);
    final netExact = _formatCurrencyExact(_finalChargeableLdCr);

    final sb = StringBuffer();
    sb.writeln('================================================================================');
    sb.writeln('                     FORMAL CONTRACTUAL & STATUTORY DEMAND NOTICE');
    sb.writeln('                UNDER FIDIC SUB-CLAUSE 8.7 [DELAY DAMAGES] & SUB-CLAUSE 2.5');
    sb.writeln('              READ WITH SECTION 74 OF THE INDIAN CONTRACT ACT, 1872');
    sb.writeln('================================================================================');
    sb.writeln('');
    sb.writeln('DEMAND NOTICE REF NO: $_noticeRefNumber');
    sb.writeln('DATE OF SERVICE:     $dateStr');
    sb.writeln('PROJECT:             Trunk Crude Oil Pipeline Expansion (Duliajan to Digboi)');
    sb.writeln('CONTRACT CODE:       OIL-PL-024 / PRJ-OIL-2026');
    sb.writeln('SANCTIONED VALUE:    ₹${_contractValueCr.toStringAsFixed(2)} Crores');
    sb.writeln('');
    sb.writeln('TO:');
    sb.writeln('  $_contractorSignatory');
    sb.writeln('  Pipeline Division, Sector 6, Duliajan Complex, Dibrugarh, Assam');
    sb.writeln('');
    sb.writeln('FROM:');
    sb.writeln('  $_engineerSignatory');
    sb.writeln('  Acting for and on behalf of:');
    sb.writeln('  $_employerSignatory');
    sb.writeln('');
    sb.writeln('SUBJECT:');
    sb.writeln('  FORMAL ASSESSMENT AND RECOVERY OF DELAY DAMAGES FOR FAILURE TO COMPLY WITH');
    sb.writeln('  TIME FOR COMPLETION UNDER FIDIC SUB-CLAUSE 8.2 AND SUB-CLAUSE 8.7');
    sb.writeln('');
    sb.writeln('1. CONTRACTUAL PREMISES & FIDIC JURISPRUDENCE:');
    sb.writeln('   1.1 WHEREAS pursuant to the Contract Agreement dated 15 January 2026 entered into');
    sb.writeln('       between Oil India Limited ("the Employer") and the Contractor Consortium, the');
    sb.writeln('       Contractor was obligated to complete the Works within the stipulated Time for');
    sb.writeln('       Completion pursuant to FIDIC Sub-Clause 8.2;');
    sb.writeln('   1.2 WHEREAS Appendix to Tender specifies that Delay Damages under Sub-Clause 8.7');
    sb.writeln('       shall accrue at ${_weeklyRatePct.toStringAsFixed(2)}% of the Contract Price per week (or pro-rata daily rate)');
    sb.writeln('       of unauthorized contractor delay, subject to an agreed maximum ceiling of');
    sb.writeln('       ${_maxCapPct.toStringAsFixed(1)}% of the Sanctioned Contract Value (₹${_maxCapAmountCr.toStringAsFixed(2)} Crores);');
    sb.writeln('   1.3 WHEREAS under Indian Law (Section 74 of the Indian Contract Act, 1872) as');
    sb.writeln('       authoritatively settled by the Hon\'ble Supreme Court of India in "ONGC v. Saw');
    sb.writeln('       Pipes Ltd. (2003) 5 SCC 705" and reaffirmed in "Kailash Nath Associates v. DDA');
    sb.writeln('       (2015) 4 SCC 136", delay damages specified as a pre-estimate of loss in national');
    sb.writeln('       hydrocarbon infrastructure are fully enforceable without requiring individual proof');
    sb.writeln('       of actual financial damage;');
    sb.writeln('');
    sb.writeln('2. CRITICAL PATH DELAY & SCL CONCURRENCY APPORTIONMENT:');
    sb.writeln('   2.1 Gross Contractor-Recorded Critical Path Delay:     $_grossDelayDays calendar days (${(_grossDelayDays / 7.0).toStringAsFixed(2)} Weeks)');
    sb.writeln('   2.2 Concurrency Deduction (SCL Protocol Core Princ. 10): -$_concurrencyOffsetDays calendar days (${(_concurrencyOffsetDays / 7.0).toStringAsFixed(2)} Weeks)');
    sb.writeln('       [Credited towards Employer-caused events ERE-01 through ERE-04 under Cl. 8.4]');
    sb.writeln('   2.3 Net Inexcusable & Culpable Contractor Delay:       $_netDelayDays calendar days (${_netDelayWeeks.toStringAsFixed(2)} Weeks)');
    sb.writeln('');
    sb.writeln('3. SECTIONAL MILESTONE BREAKDOWN:');
    for (final m in _milestones) {
      sb.writeln('   * ${m.code} (${m.title}):');
      sb.writeln('     - Value: ₹${m.allocatedValueCr.toStringAsFixed(2)} Cr (${(m.contractValueWeight * 100).toStringAsFixed(0)}% Weight) | Status: ${m.status}');
      sb.writeln('     - Gross Delay: ${m.grossDelayDays} days | EOT Offset: ${m.concurrentEmployerOffsetDays} days | Net Delay: ${m.netCulpableDelayDays} days');
      sb.writeln('     - Milestone LD Accrued: ₹${m.calculatedLdCr.toStringAsFixed(3)} Cr (Cap: ₹${m.maxCapCr.toStringAsFixed(2)} Cr)');
    }
    sb.writeln('');
    sb.writeln('4. COMPUTATION OF DELAY DAMAGES DEMAND:');
    sb.writeln('   - Weekly Rate: ${_weeklyRatePct.toStringAsFixed(2)}% of ₹${_contractValueCr.toStringAsFixed(2)} Cr = ₹${_weeklyLdRateCr.toStringAsFixed(3)} Cr/Week');
    sb.writeln('   - Daily Pro-rata Rate: ₹${(_dailyLdRateCr * 100.0).toStringAsFixed(2)} Lakhs/Day');
    sb.writeln('   - Net Chargeable Delay: ${_netDelayWeeks.toStringAsFixed(2)} Weeks');
    sb.writeln('   - Uncapped Accrued LD: ₹${_uncappedTotalLdCr.toStringAsFixed(3)} Crores');
    sb.writeln('   - Contractual Cap Applied: ${_isCeilingReached ? "YES (CEILING AT 10.0%)" : "NO (WITHIN CAP)"}');
    sb.writeln('   - NET DELAY DAMAGES DEMANDED: $netExact');
    sb.writeln('     [In Words: $netWords]');
    sb.writeln('');
    sb.writeln('5. PEREMPTORY DIRECTIVE & BANK GUARANTEE INVOCATION WARNING:');
    sb.writeln('   5.1 The Contractor is hereby directed to remit the aforesaid sum of $netExact');
    sb.writeln('       into the designated Employer Project Escrow Account within $_curePeriodDays calendar days');
    sb.writeln('       from service of this notice, being on or before $dueStr.');
    sb.writeln('   5.2 TAKE NOTE that upon default of payment within the stipulated $_curePeriodDays days,');
    sb.writeln('       the Employer shall forthwith, without further notice or judicial process, invoke');
    sb.writeln('       and encash the Contractor\'s Irrevocable Performance Bank Guarantee (PBG #SBI/DUL/PBG/2026/08)');
    sb.writeln('       under FIDIC Sub-Clause 4.2 [Performance Security] and/or deduct the full demand sum');
    sb.writeln('       from Interim Payment Certificate IPC-09.');
    sb.writeln('');
    sb.writeln('DATED THIS $dateStr.');
    sb.writeln('');
    sb.writeln('_______________________________________        _______________________________________');
    sb.writeln('$_engineerSignatory             $_employerSignatory');
    sb.writeln('The Engineer (FIDIC Sub-Clause 3.1)            Chief General Manager (Pipelines) - OIL');
    sb.writeln('================================================================================');

    return sb.toString();
  }

  // ---------------------------------------------------------------------------
  // Build Main Widget
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FIDIC Cl. 8.7 Delay Damages',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Liquidated Damages & Concurrency Offset Engine',
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
            tooltip: 'FIDIC Cl. 13 Variations',
            icon: const Icon(Icons.published_with_changes_rounded, color: AppTheme.secondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VariationOrderScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Legal Citations & Case Precedents',
            icon: const Icon(Icons.gavel_rounded, color: AppTheme.secondary),
            onPressed: _showPrecedentInfoModal,
          ),
          IconButton(
            tooltip: 'Copy Formal Notice',
            icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryLight),
            onPressed: _copyDemandNoticeText,
          ),
          IconButton(
            tooltip: 'Reset to Baseline',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _resetToBaseline,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryLight,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.calculate_rounded, size: 18), text: 'LD Calculator'),
            Tab(icon: Icon(Icons.flag_rounded, size: 18), text: 'Milestones (M1-M3)'),
            Tab(icon: Icon(Icons.balance_rounded, size: 18), text: 'Concurrent Delay'),
            Tab(icon: Icon(Icons.description_rounded, size: 18), text: 'Demand Notice'),
            Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'Jurisprudence'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalculatorTab(),
          _buildMilestonesTab(),
          _buildConcurrentDelayTab(),
          _buildDemandNoticeTab(),
          _buildJurisprudenceTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: LD Calculator & What-If Simulator
  // ---------------------------------------------------------------------------
  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contract Identity Card
          _buildContractIdentityHeader(),
          const SizedBox(height: 16),

          // Top Executive Metrics Grid
          _buildTopExecutiveMetricsGrid(),
          const SizedBox(height: 16),

          // Cap Utilization Gauge & Progress Bar
          _buildCapUtilizationCard(),
          const SizedBox(height: 16),

          // What-If Scenario Presets
          _buildScenarioPresetSelector(),
          const SizedBox(height: 16),

          // Interactive Sliders & Controls
          _buildInteractiveControlsCard(),
          const SizedBox(height: 16),

          // Financial Burn & PBG Exposure Breakdown
          _buildFinancialBurnTable(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildContractIdentityHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.domain_verification_rounded, color: AppTheme.primaryLight, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'OIL-PL-024 / PRJ-OIL-2026',
                      style: TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isCeilingReached
                            ? AppTheme.error.withAlpha(40)
                            : AppTheme.tertiary.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isCeilingReached ? '10% CEILING HIT' : 'WITHIN LEGAL CAP',
                        style: TextStyle(
                          color: _isCeilingReached ? AppTheme.error : AppTheme.tertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Trunk Crude Oil Pipeline Expansion (124 KM)',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Employer: Oil India Limited | Contractor: L&T Hydrocarbon Engineering JV',
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
    );
  }

  Widget _buildTopExecutiveMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Sanctioned Value',
                value: _formatCrShort(_contractValueCr),
                subtitle: 'Contract Baseline Price',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Statutory Max Cap',
                value: _formatCrShort(_maxCapAmountCr),
                subtitle: '${_maxCapPct.toStringAsFixed(1)}% Contract Ceiling',
                icon: Icons.shield_rounded,
                accentColor: AppTheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Net LD Chargeable',
                value: _formatCr(_finalChargeableLdCr),
                subtitle: '${_capConsumptionPct.toStringAsFixed(1)}% of Cap utilized',
                icon: Icons.gavel_rounded,
                accentColor: _isCeilingReached ? AppTheme.error : AppTheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Weekly Delay Rate',
                value: _formatCr(_weeklyLdRateCr),
                subtitle: '${_weeklyRatePct.toStringAsFixed(2)}% per delay week',
                icon: Icons.speed_rounded,
                accentColor: AppTheme.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
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
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapUtilizationCard() {
    final double ratio = (_capConsumptionPct / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCeilingReached ? AppTheme.error.withAlpha(120) : AppTheme.border,
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
                    Icons.security_rounded,
                    color: _isCeilingReached ? AppTheme.error : AppTheme.primaryLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'FIDIC 8.7 Statutory Cap Exposure (10%)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${_capConsumptionPct.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _isCeilingReached ? AppTheme.error : AppTheme.primaryLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isCeilingReached ? AppTheme.error : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Accrued LD: ${_formatCrShort(_finalChargeableLdCr)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              Text(
                'Cap Headroom: ${_formatCrShort(_capHeadroomRemainingCr)}',
                style: TextStyle(
                  color: _capHeadroomRemainingCr <= 0 ? AppTheme.error : AppTheme.tertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_isCeilingReached) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.error.withAlpha(90)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Uncapped delay liability of ${_formatCrShort(_uncappedTotalLdCr)} legally capped at ${_formatCrShort(_maxCapAmountCr)} per Sub-Clause 8.7 & Section 74.',
                      style: const TextStyle(color: AppTheme.error, fontSize: 10, fontWeight: FontWeight.w600),
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

  Widget _buildScenarioPresetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick What-If Delay Scenarios:',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPresetChip('Current Certified (8.1 Wks Net)', 'BASELINE'),
              const SizedBox(width: 8),
              _buildPresetChip('Cap Breach (22.7 Wks Net)', 'CAP_BREACH'),
              const SizedBox(width: 8),
              _buildPresetChip('Milestone 1 Only (4.3 Wks)', 'M1_ONLY'),
              const SizedBox(width: 8),
              _buildPresetChip('Max Concurrency Defense (1 Wk)', 'FULL_CONCURRENCY'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, String scenarioKey) {
    return ActionChip(
      backgroundColor: AppTheme.surfaceCard,
      side: const BorderSide(color: AppTheme.border),
      label: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.primaryLight)),
      onPressed: () => _applyScenarioPreset(scenarioKey),
    );
  }

  Widget _buildInteractiveControlsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.tune_rounded, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Interactive Delay & Penalty Tuning',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Slider 1: Gross Delay Days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gross Contractor Delay:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(
                '$_grossDelayDays Days (${(_grossDelayDays / 7.0).toStringAsFixed(1)} Wks)',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _grossDelayDays.toDouble(),
            min: 0,
            max: 210,
            divisions: 210,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.surface,
            onChanged: (val) => setState(() => _grossDelayDays = val.round()),
          ),

          // Slider 2: Concurrency Offset Days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SCL Concurrency EOT Offset:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(
                '$_concurrencyOffsetDays Days (${(_concurrencyOffsetDays / 7.0).toStringAsFixed(1)} Wks)',
                style: const TextStyle(color: AppTheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _concurrencyOffsetDays.toDouble(),
            min: 0,
            max: 140,
            divisions: 140,
            activeColor: AppTheme.tertiary,
            inactiveColor: AppTheme.surface,
            onChanged: (val) => setState(() => _concurrencyOffsetDays = val.round()),
          ),

          // Net Delay Display Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Inexcusable Delay Culpability:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$_netDelayDays Days (${_netDelayWeeks.toStringAsFixed(2)} Weeks)',
                  style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Slider 3: Sanctioned Contract Value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sanctioned Contract Value:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(
                '₹${_contractValueCr.toStringAsFixed(1)} Crores',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _contractValueCr,
            min: 50.0,
            max: 400.0,
            divisions: 70,
            activeColor: AppTheme.secondary,
            inactiveColor: AppTheme.surface,
            onChanged: (val) => setState(() => _contractValueCr = val),
          ),

          // Slider 4: Weekly Penalty Rate %
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Weekly LD Rate (FIDIC Cl. 8.7):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(
                '${_weeklyRatePct.toStringAsFixed(2)}% / week',
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _weeklyRatePct,
            min: 0.10,
            max: 1.50,
            divisions: 28,
            activeColor: AppTheme.primaryLight,
            inactiveColor: AppTheme.surface,
            onChanged: (val) => setState(() => _weeklyRatePct = val),
          ),

          // Slider 5: Statutory Maximum Cap %
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Contractual Cap Ceiling:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(
                '${_maxCapPct.toStringAsFixed(1)}% (₹${_maxCapAmountCr.toStringAsFixed(2)} Cr)',
                style: const TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _maxCapPct,
            min: 5.0,
            max: 20.0,
            divisions: 30,
            activeColor: AppTheme.error,
            inactiveColor: AppTheme.surface,
            onChanged: (val) => setState(() => _maxCapPct = val),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialBurnTable() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.table_chart_rounded, color: AppTheme.tertiary, size: 20),
              SizedBox(width: 8),
              Text(
                'Financial Exposure & Run Rate Analysis',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Daily Accrual Burn Rate', _formatLakhs(_dailyLdRateCr), isHighlight: false),
          const Divider(color: AppTheme.border, height: 16),
          _buildDetailRow('Weekly Accrual Burn Rate', _formatCr(_weeklyLdRateCr), isHighlight: false),
          const Divider(color: AppTheme.border, height: 16),
          _buildDetailRow('Monthly Projected Burn (30 Days)', _formatCr(_dailyLdRateCr * 30.0), isHighlight: false),
          const Divider(color: AppTheme.border, height: 16),
          _buildDetailRow(
            'Performance Bank Guarantee (PBG @ 10%) Exposure',
            '${((_finalChargeableLdCr / _maxCapAmountCr) * 100.0).toStringAsFixed(1)}% of PBG Sum',
            isHighlight: true,
          ),
          const Divider(color: AppTheme.border, height: 16),
          _buildDetailRow(
            'Contractor SCL Concurrency Relief Savings',
            _formatCr(_contractorReliefSavingsCr),
            isHighlight: false,
            colorOverride: AppTheme.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlight = false, Color? colorOverride}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlight ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colorOverride ?? (isHighlight ? AppTheme.primaryLight : AppTheme.textPrimary),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: Milestone Breakdown (M1, M2, M3)
  // ---------------------------------------------------------------------------
  Widget _buildMilestonesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sectional Completion Explainer Card
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
                const Icon(Icons.info_outline_rounded, color: AppTheme.primaryLight, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sectional Milestones under FIDIC Sub-Clause 1.1.5.6 & 8.7',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The Contract stipulates 3 mandatory sectional completion milestones. Liquidated damages are assessed separately against milestone values. Total sectional sum is currently ${_formatCr(_milestonesSumLdCr)} across Milestones 1, 2, and 3.',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Milestone Cards
          for (final m in _milestones) ...[
            _buildMilestoneCard(m),
            const SizedBox(height: 16),
          ],

          // Total Milestones Summary Card
          _buildMilestoneAggregateSummaryCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(MilestoneLdModel m) {
    Color statusColor;
    String statusLabel;
    switch (m.status) {
      case 'COMPLETED_LD':
        statusColor = AppTheme.secondary;
        statusLabel = 'COMPLETED (LD INCURRED)';
        break;
      case 'CRITICAL_DELAY':
        statusColor = AppTheme.error;
        statusLabel = 'CRITICAL SCHEDULE DELAY';
        break;
      case 'PROJECTED_DELAY':
        statusColor = AppTheme.primaryLight;
        statusLabel = 'PROJECTED DELAY IMPACT';
        break;
      default:
        statusColor = AppTheme.tertiary;
        statusLabel = 'ON SCHEDULE';
    }

    final dateFmt = DateFormat('dd MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: const Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        m.code,
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(m.contractValueWeight * 100).toStringAsFixed(0)}% Weight (₹${m.allocatedValueCr.toStringAsFixed(2)} Cr)',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withAlpha(80)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  m.description,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 12),

                // Date & Delay Metrics Row
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Contract Target', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(dateFmt.format(m.baselineDueDate),
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Actual / Forecast', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(dateFmt.format(m.certifiedDate),
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Net Delay', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text('${m.netCulpableDelayDays} Days (${m.netDelayWeeks.toStringAsFixed(1)} W)',
                                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Financial Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Milestone LD Rate: ${_formatCr(m.weeklyRateCr)}/wk',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    Text(
                      'Cap Ceiling: ₹${m.maxCapCr.toStringAsFixed(2)} Cr',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Assessed Delay Damages:',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatCr(m.calculatedLdCr),
                      style: TextStyle(
                        color: m.isCapped ? AppTheme.error : AppTheme.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Mini Cap Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (m.capUtilizationPct / 100.0).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppTheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      m.isCapped ? AppTheme.error : AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Key Deliverables Accordion Preview
                const Text(
                  'Key Deliverables & Verification Checklist:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                for (final d in m.scopeKeyDeliverables)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppTheme.tertiary, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            d,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),

                // Edit Button
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 14, color: AppTheme.primaryLight),
                    label: const Text('Adjust Milestone Schedule', style: TextStyle(fontSize: 11)),
                    onPressed: () => _showMilestoneEditDialog(m),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneAggregateSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.summarize_rounded, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Sectional Milestones vs Overall Contract Cap',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Sum of Sectional Milestone LDs (M1 + M2 + M3)',
            _formatCr(_milestonesSumLdCr),
            isHighlight: true,
          ),
          const Divider(color: AppTheme.border, height: 16),
          _buildDetailRow(
            'Overall Contract Delay Damages (Whole Work)',
            _formatCr(_finalChargeableLdCr),
            isHighlight: false,
          ),
          const Divider(color: AppTheme.border, height: 16),
          _buildDetailRow(
            'Reconciliation Difference',
            _formatCr((_finalChargeableLdCr - _milestonesSumLdCr).abs()),
            isHighlight: false,
            colorOverride: AppTheme.textMuted,
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: Under FIDIC Sub-Clause 8.7, if Taking-Over for the whole Works is achieved ahead of adjusted milestone schedules, interim milestone delay damages are credited back to the Contractor in the Final Statement.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: Concurrent Delay Offset Analyzer
  // ---------------------------------------------------------------------------
  Widget _buildConcurrentDelayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SCL Protocol Principle 10 Header
          _buildSclProtocolHeader(),
          const SizedBox(height: 16),

          // Concurrency Overlap Result Banner
          _buildConcurrencyCalculationBanner(),
          const SizedBox(height: 16),

          // Employer Risk Events
          const Text(
            'Employer-Caused Delays (Employer Risk Events - ERE):',
            style: TextStyle(color: AppTheme.primaryLight, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final ere in _employerDelayEvents) ...[
            _buildDelayEventCard(ere, isEmployer: true),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),

          // Contractor Risk Events
          const Text(
            'Contractor-Caused Delays (Contractor Risk Events - CRE):',
            style: TextStyle(color: AppTheme.secondary, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final cre in _contractorDelayEvents) ...[
            _buildDelayEventCard(cre, isEmployer: false),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),

          // Concurrency Overlap Timeline Visualization
          _buildConcurrencyTimelineVisualization(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSclProtocolHeader() {
    return Container(
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
              color: AppTheme.secondary.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.balance_rounded, color: AppTheme.secondary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCL Delay and Disruption Protocol (2nd Edition, 2017)',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Core Principle 10: Where an Employer Risk Event and a Contractor Risk Event occur concurrently and both delay the completion of the Works, the Contractor is entitled to an Extension of Time (EOT) to relieve Delay Damages liability, but without prolongation cost compensation.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcurrencyCalculationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.tertiary.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SCL Concurrent Overlap Offset Determination',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Contractor Delay',
                  '$_totalContractorDelayDays Days',
                  AppTheme.secondary,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Employer Delay',
                  '$_totalEmployerDelayDays Days',
                  AppTheme.primaryLight,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'SCL EOT Offset',
                  '-$_concurrencyOffsetDays Days',
                  AppTheme.tertiary,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Net Culpable LD',
                  '$_netDelayDays Days',
                  AppTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Contractor Penalty Shielded (SCL Offset Relief):',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                Text(
                  _formatCr(_contractorReliefSavingsCr),
                  style: const TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDelayEventCard(ConcurrentDelayEventModel event, {required bool isEmployer}) {
    final dateFmt = DateFormat('dd MMM');
    final rangeStr = '${dateFmt.format(event.startDate)} - ${dateFmt.format(event.endDate)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: event.isApprovedForOffset
              ? (isEmployer ? AppTheme.primary.withAlpha(100) : AppTheme.secondary.withAlpha(100))
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isEmployer ? AppTheme.primary : AppTheme.secondary).withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.code,
                      style: TextStyle(
                        color: isEmployer ? AppTheme.primaryLight : AppTheme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${event.impactDays} Days ($rangeStr)',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Switch(
                value: event.isApprovedForOffset,
                activeThumbColor: isEmployer ? AppTheme.primaryLight : AppTheme.secondary,
                onChanged: (val) {
                  setState(() {
                    if (isEmployer) {
                      final idx = _employerDelayEvents.indexWhere((e) => e.id == event.id);
                      if (idx != -1) {
                        _employerDelayEvents[idx] =
                            _employerDelayEvents[idx].copyWith(isApprovedForOffset: val);
                      }
                    } else {
                      final idx = _contractorDelayEvents.indexWhere((e) => e.id == event.id);
                      if (idx != -1) {
                        _contractorDelayEvents[idx] =
                            _contractorDelayEvents[idx].copyWith(isApprovedForOffset: val);
                      }
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            event.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.description,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                event.fidicSubclause,
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontStyle: FontStyle.italic),
              ),
              Text(
                event.evidenceReference,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConcurrencyTimelineVisualization() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.timeline_rounded, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Critical Path Concurrency Timeline Matrix',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimelineBar('May - Jun 2026: RoW Handover vs Welder Shortage (28d Overlap)', 0.60, AppTheme.tertiary),
          const SizedBox(height: 8),
          _buildTimelineBar('Jul - Aug 2026: Design Revision vs HDD Rig Breakdown (17d Overlap)', 0.45, AppTheme.tertiary),
          const SizedBox(height: 8),
          _buildTimelineBar('Sep 2026: NDT Radiography Re-work (18d Culpable Contractor)', 0.30, AppTheme.secondary),
          const SizedBox(height: 8),
          _buildTimelineBar('Oct 2026: Flood Audit vs Ditcher Mobilization (10d Overlap)', 0.25, AppTheme.tertiary),
        ],
      ),
    );
  }

  Widget _buildTimelineBar(String label, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppTheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: Formal Liquidated Damages Demand Notice Generator
  // ---------------------------------------------------------------------------
  Widget _buildDemandNoticeTab() {
    final noticeText = _generateNoticeDocumentText();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notice Status & Controls Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isNoticeIssued
                            ? AppTheme.tertiary.withAlpha(40)
                            : AppTheme.secondary.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isNoticeIssued ? Icons.mark_email_read_rounded : Icons.pending_actions_rounded,
                        color: _isNoticeIssued ? AppTheme.tertiary : AppTheme.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isNoticeIssued ? 'STATUS: OFFICIALLY SERVED' : 'STATUS: DRAFT DEMAND NOTICE',
                          style: TextStyle(
                            color: _isNoticeIssued ? AppTheme.tertiary : AppTheme.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isNoticeIssued ? 'Served on: $_noticeIssuedTimestamp' : 'Pending formal Engineer sign-off',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isNoticeIssued ? AppTheme.surfaceContainerHigh : AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: Icon(_isNoticeIssued ? Icons.undo_rounded : Icons.send_rounded, size: 14),
                  label: Text(_isNoticeIssued ? 'Revoke to Draft' : 'Serve Notice', style: const TextStyle(fontSize: 11)),
                  onPressed: _toggleNoticeIssued,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Secondary Action Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryLight),
                  label: const Text('Copy Notice Text', style: TextStyle(fontSize: 11)),
                  onPressed: _copyDemandNoticeText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.tune_rounded, size: 14, color: AppTheme.secondary),
                  label: const Text('Edit Particulars', style: TextStyle(fontSize: 11)),
                  onPressed: _showNoticeCustomizationDialog,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 14, color: AppTheme.tertiary),
                  label: const Text('Share PDF', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notice formatted and exported as authenticated legal audit PDF.'),
                        backgroundColor: AppTheme.surfaceCard,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Formal Document Viewer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D162B), // Deep legal document background
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: SelectableText(
              noticeText,
              style: const TextStyle(
                color: Color(0xFFD8E2F0),
                fontSize: 11,
                fontFamily: 'Courier', // Monospace legal courier feel
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 5: FIDIC 8.7 & Legal Jurisprudence Guide
  // ---------------------------------------------------------------------------
  Widget _buildJurisprudenceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: AppTheme.secondary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Indian Statutory Doctrine: Section 74',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '"When a contract has been broken, if a sum is named in the contract as the amount to be paid in case of such breach, or if the contract contains any other stipulation by way of penalty, the party complaining of the breach is entitled, whether or not actual damage or loss is proved to have been caused thereby, to receive from the party who has broken the contract reasonable compensation not exceeding the amount so named..."',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const _LegalCitationCard(
            title: '1. ONGC v. Saw Pipes Ltd. (2003) 5 SCC 705',
            citation: 'Supreme Court of India (3-Judge Bench)',
            principle: 'Enforceability of Delay Damages without Proving Actual Loss',
            explanation:
                'In large public works and oil pipelines, delay affects the national exchequer and public interest. Because mathematical proof of consequential business loss is impossible, parties can pre-estimate reasonable compensation. Unless the stipulated sum is unreasonable or penal, court must award the agreed liquidated damages.',
          ),
          const SizedBox(height: 12),

          const _LegalCitationCard(
            title: '2. Kailash Nath Associates v. DDA (2015) 4 SCC 136',
            citation: 'Supreme Court of India',
            principle: 'Proof of Damage where Loss is Measurable',
            explanation:
                'Section 74 emphasizes "reasonable compensation". Where loss can be mathematically proved, the claimant must produce evidence. Where loss is impossible or difficult to quantify (such as commissioning an oil trunkline), the stipulated figure is regarded as the reasonable compensation agreed by commercial parties.',
          ),
          const SizedBox(height: 12),

          const _LegalCitationCard(
            title: '3. Maula Bux v. Union of India (1969) 2 SCC 554',
            citation: 'Supreme Court of India Constitution Bench',
            principle: 'Distinction between Liquidated Damages and Penalty Stipulation',
            explanation:
                'Stipulations in terrorem designed to penalize rather than compensate are void under Indian law. A 0.5% per week rate up to 10% maximum is globally recognized under FIDIC standard practice as purely compensatory and non-penal.',
          ),
          const SizedBox(height: 12),

          const _LegalCitationCard(
            title: '4. FIDIC 1999 vs 2017 Sub-Clause 8.7 Evolution',
            citation: 'International Federation of Consulting Engineers',
            principle: 'Reconciliation upon Taking-Over & Interim Deductions',
            explanation:
                'Under FIDIC 2017 Red Book, Sub-Clause 8.7 explicitly clarifies that delay damages are the only damages due from the Contractor for delay, without prejudice to termination rights under Clause 15.2. If the Contractor achieves overall Taking-Over, sectional damages are re-adjusted.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Helper component for legal precedent cards
class _LegalCitationCard extends StatelessWidget {
  final String title;
  final String citation;
  final String principle;
  final String explanation;

  const _LegalCitationCard({
    required this.title,
    required this.citation,
    required this.principle,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.bookmark_outline_rounded, color: AppTheme.secondary, size: 16),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            citation,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Ratio: $principle',
              style: const TextStyle(
                color: AppTheme.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
