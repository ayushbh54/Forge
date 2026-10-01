import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import 'liquidated_damages_screen.dart';

/// Screen for managing FIDIC Clause 13 Variation Orders & Scope Changes
/// Implements full register tracking (VO-2026-01 to VO-2026-06+),
/// 3-stage Approval Workflow (Initiated -> Engineer Reviewed -> Client Sanctioned),
/// executive financial & schedule impact metrics, and interactive request submission.
class VariationOrderScreen extends StatefulWidget {
  const VariationOrderScreen({super.key});

  @override
  State<VariationOrderScreen> createState() => _VariationOrderScreenState();
}

class _VariationOrderScreenState extends State<VariationOrderScreen> {
  // Baseline contract value for ratio computation (₹245.00 Cr)
  static const double _baselineContractValueCr = 245.00;
  static const double _fidicThresholdPercentage = 15.0; // Cl. 12/13 limit

  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // ALL, SANCTIONED, REVIEWED, INITIATED, GEOLOGY, DESIGN_MOD
  String _sortBy = 'ID_ASC'; // ID_ASC, COST_DESC, EOT_DESC

  final Set<String> _expandedCards = <String>{};

  // Baseline variation orders (VO-2026-01 through VO-2026-06)
  late List<VariationOrderModel> _variationOrders;

  @override
  void initState() {
    super.initState();
    _variationOrders = [
      const VariationOrderModel(
        id: 'VO-2026-01',
        title: 'Trenching Reroute & HDD Under River Crossing (KM 42+300 to 45+800)',
        clauseReference: 'FIDIC Cl. 13.1 (Right to Vary) & 13.3',
        costImpactCr: 4.20,
        scheduleImpactDays: 21,
        workflowStage: VariationWorkflowStage.clientSanctioned,
        reason: 'Unforeseen geological strata',
        scopeDescription:
            'Sub-bed geotechnical core drillings at Dihing river crossing revealed an unmapped massive crystalline basalt intrusion extending 14m beneath scour depth. Open-cut trenching abandoned due to environmental riverbed stability risks. Replaced with 1,200mm diameter Horizontal Directional Drilling (HDD) package, deep entry/exit bell pits, polymer mud recycling, and 3.5 km rerouted right-of-way corridor.',
        workPackage: 'WP-03 Trenching & River HDD Crossing',
        submittedDate: '14 Jun 2026',
        engineerReviewedDate: '28 Jun 2026',
        clientSanctionedDate: '18 Jul 2026',
        contractorOriginator: 'L&T Hydrocarbon Engineering JV',
        engineerSignatory: 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
        clientSignatory: 'Sunil Khurana, CGM (Pipelines) - OIL',
        sanctionReferenceNumber: 'OIL/FIN/SANCT/VO-01/2026',
        boqCostBreakdown: {
          'Direct HDD Drilling & Reaming (1,200mm)': 2.60,
          'Rig Mobilization & Bentonite Slurry Treatment': 0.65,
          'Corridor Reroute Earthwork & Pipe Relocation': 0.55,
          'Contractor Overheads & Contractual Margin': 0.40,
        },
        technicalJustifications: [
          'Sub-surface basalt shelf verified by third-party Geological Survey lab report #GS-AZ-992',
          'Avoids monsoon flash flood bed-scour failure and preserves river navigation clearance',
          'Notice of Claim served strictly within 28 days under FIDIC Clause 20.1',
        ],
        hasCriticalPathImpact: true,
      ),
      const VariationOrderModel(
        id: 'VO-2026-02',
        title: 'Mainline Sectionalizing Valve Actuators SIL-3 Retrofit',
        clauseReference: 'FIDIC Cl. 13.3 (Variation Procedure)',
        costImpactCr: 1.85,
        scheduleImpactDays: 0,
        workflowStage: VariationWorkflowStage.clientSanctioned,
        reason: 'Client design modification',
        scopeDescription:
            'Formal client instruction following updated statutory OISD-141 directive for hydrocarbon transmission trunklines. Upgrades 14 remote mainline sectionalizing valves (SV-01 through SV-14) from basic electric motor actuators to triple-modular redundant electro-hydraulic SIL-3 certified emergency shutdown (ESD) actuators with dual solar power pack backups and redundant satellite telemetry.',
        workPackage: 'WP-07 SCADA & Instrumentation',
        submittedDate: '05 Jul 2026',
        engineerReviewedDate: '19 Jul 2026',
        clientSanctionedDate: '08 Aug 2026',
        contractorOriginator: 'Honeywell Process Solutions JV',
        engineerSignatory: 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
        clientSignatory: 'P. K. Baruah, Director (Operations) - OIL',
        sanctionReferenceNumber: 'OIL/FIN/SANCT/VO-02/2026',
        boqCostBreakdown: {
          'SIL-3 Electro-Hydraulic Actuator Skid Assemblies (14 units)': 1.25,
          'Solar Battery Backup & Redundant Power Skid': 0.35,
          'SCADA RTU Hardware & Fiber Integration': 0.25,
        },
        technicalJustifications: [
          'Mandated by OISD-141 statutory hydrocarbon safety regulations issued June 2026',
          'Procurement executed in parallel with welding; zero impact on critical path milestone',
          'Engineered for 99.999% failsafe automated pipeline isolation during drop-in-pressure events',
        ],
        hasCriticalPathImpact: false,
      ),
      const VariationOrderModel(
        id: 'VO-2026-03',
        title: 'Deep Soil Cement Stabilization & Stone Column Piling at Terminal Pumping Station',
        clauseReference: 'FIDIC Cl. 13.1 (Right to Vary)',
        costImpactCr: 3.10,
        scheduleImpactDays: 14,
        workflowStage: VariationWorkflowStage.engineerReviewed,
        reason: 'Unforeseen geological strata',
        scopeDescription:
            'Foundation excavation at Terminal Pump Station (Station-04) intercepted an unanticipated liquefiable silt pocket coupled with an artesian water lens at 4.5m depth. Dynamic cone penetration tests indicated bearing capacity under 85 kPa (design required 250 kPa). Solution entails installing 800 vibro-replacement stone columns (12m depth, 800mm diameter) and a biaxial high-tensile geogrid load transfer platform.',
        workPackage: 'WP-02 Civil & Foundations',
        submittedDate: '12 Aug 2026',
        engineerReviewedDate: '29 Aug 2026',
        clientSanctionedDate: null,
        contractorOriginator: 'Punj Lloyd Piping JV',
        engineerSignatory: 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
        clientSignatory: null,
        sanctionReferenceNumber: 'PENDING-CLIENT-SANCTION',
        boqCostBreakdown: {
          'Vibro-Replacement Stone Columns (800 nos. @ 12m depth)': 1.80,
          'Biaxial Geogrid Membrane & Crushed Aggregate Platform': 0.50,
          'Wellpoint Dewatering & Shoring Stabilisation': 0.50,
          'EPC Supervision & Quality Audit Margins': 0.30,
        },
        technicalJustifications: [
          'Soil liquefaction potential exceeds safe seismic design criteria under IS 1893:2016',
          'Engineer review confirmed necessity of deep foundation remediation prior to heavy pump placement',
          'Commercial evaluation endorsed under FIDIC Cl. 3.5; submitted for Board Financial Sanction',
        ],
        hasCriticalPathImpact: true,
      ),
      const VariationOrderModel(
        id: 'VO-2026-04',
        title: '33kV Dual Overhead Power Feeder Extension to Intermediate Booster Station',
        clauseReference: 'FIDIC Cl. 13.3 (Variation Procedure)',
        costImpactCr: 2.45,
        scheduleImpactDays: 18,
        workflowStage: VariationWorkflowStage.engineerReviewed,
        reason: 'Client design modification',
        scopeDescription:
            'Client variation issued to incorporate future expansion capacity for Phase 2 crude transmission. Involves erecting 7.8 km of 33kV double-circuit lattice tower overhead transmission line from APDCL sub-station to Intermediate Booster Station (BS-02), including 2 incoming SF6 breaker panels, motor control centers (MCC), and automated grid synchronization relays.',
        workPackage: 'WP-05 Electrical Utilities',
        submittedDate: '22 Aug 2026',
        engineerReviewedDate: '10 Sep 2026',
        clientSanctionedDate: null,
        contractorOriginator: 'Kalpataru Power Transmission JV',
        engineerSignatory: 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
        clientSignatory: null,
        sanctionReferenceNumber: 'PENDING-CLIENT-SANCTION',
        boqCostBreakdown: {
          'Double-Circuit Lattice Towers & Panther Conductor Stringing': 1.40,
          '33kV SF6 Switchgear Bays & Transformer Connections': 0.65,
          'Statutory Right-of-Way Clearances & Forest Clearances': 0.20,
          'Contractor Indirects & Value Markup': 0.20,
        },
        technicalJustifications: [
          'Prepares infrastructure for 120,000 BPD throughput ramp-up without second shutdown',
          'Engineer validated rate analysis against standard state electrical schedule of rates (SOR)',
          'Requires 18-day extension on substation commissioning milestone',
        ],
        hasCriticalPathImpact: true,
      ),
      const VariationOrderModel(
        id: 'VO-2026-05',
        title: 'Heavy-Wall Induction Bends for Seismic Zone V Fault Crossings',
        clauseReference: 'FIDIC Cl. 13.1 (Right to Vary)',
        costImpactCr: 1.60,
        scheduleImpactDays: 9,
        workflowStage: VariationWorkflowStage.initiated,
        reason: 'Unforeseen geological strata',
        scopeDescription:
            'Revised Geological Survey of India (GSI) tectonic hazard boundary shifted the active Dauki Fault rupture zone at KM 81+400. Replaces standard cold field bends with factory-fabricated high-strain induction bends (18.2mm heavy-wall API 5L X70) equipped with high-elongation FBE/ARO anti-corrosion coating to absorb dynamic ground displacements up to 1.8 meters.',
        workPackage: 'WP-04 Mechanical Piping',
        submittedDate: '15 Sep 2026',
        engineerReviewedDate: null,
        clientSanctionedDate: null,
        contractorOriginator: 'Consortium JV / L&T Hydrocarbon',
        engineerSignatory: 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
        clientSignatory: null,
        sanctionReferenceNumber: 'UNDER-INITIAL-REVIEW',
        boqCostBreakdown: {
          'Heavy-Wall Induction Bends (18.2mm WT, API 5L X70)': 1.05,
          'Full-Scale Strain Capacity & Metallurgical Laboratory Tests': 0.25,
          'Specialized High-Toughness Field Tie-in Welding & UT Inspection': 0.30,
        },
        technicalJustifications: [
          'Mandatory for structural integrity in Seismic Zone V per ASME B31.4 & ISO 13623',
          'Notice of Variation under FIDIC Clause 13.3 submitted with finite-element stress modeling',
          'Primavera P6 analysis indicates 9 days net critical path variance for induction bend delivery',
        ],
        hasCriticalPathImpact: true,
      ),
      const VariationOrderModel(
        id: 'VO-2026-06',
        title: 'Dual-Run Ultrasonic Fiscal Metering Skid-03 Integration',
        clauseReference: 'FIDIC Cl. 13.3 (Variation Procedure)',
        costImpactCr: 5.75,
        scheduleImpactDays: 30,
        workflowStage: VariationWorkflowStage.initiated,
        reason: 'Client design modification',
        scopeDescription:
            'Client modification reflecting newly finalized bilateral off-take agreement with Numaligarh Refinery Limited (NRL). Incorporates an additional 16-inch dual-run ultrasonic fiscal custody-transfer metering skid, bidirectional compact prover loop, automated gas-chromatograph analytical shelter, and dedicated dual SCADA flow computer cabinets.',
        workPackage: 'WP-08 Process Skids',
        submittedDate: '22 Sep 2026',
        engineerReviewedDate: null,
        clientSanctionedDate: null,
        contractorOriginator: 'Emerson Process Management JV',
        engineerSignatory: 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
        clientSignatory: null,
        sanctionReferenceNumber: 'UNDER-INITIAL-REVIEW',
        boqCostBreakdown: {
          '16" Ultrasonic Flow Meter Skid (0.15% fiscal accuracy)': 3.60,
          'Bidirectional Master Meter Prover Loop & Valves': 1.10,
          'Chromatograph Analyzer Shelter & Climate HVAC': 0.65,
          'Factory Acceptance Test & Interconnection Piping': 0.40,
        },
        technicalJustifications: [
          'Required for custody transfer billing compliant with OIML R117-1 Class 0.3 standards',
          'Skid delivery lead time is 16 weeks; requires 30-day EOT for final commissioning',
          'Contractor proposed milestone crashing strategy to mitigate further downstream delay',
        ],
        hasCriticalPathImpact: true,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Metrics Computations
  // ---------------------------------------------------------------------------
  double get _totalCostImpactCr =>
      _variationOrders.fold(0.0, (acc, item) => acc + item.costImpactCr);

  double get _sanctionedCostCr => _variationOrders
      .where((item) => item.isSanctioned)
      .fold(0.0, (acc, item) => acc + item.costImpactCr);

  double get _reviewedCostCr => _variationOrders
      .where((item) => item.isReviewed)
      .fold(0.0, (acc, item) => acc + item.costImpactCr);

  double get _initiatedCostCr => _variationOrders
      .where((item) => item.isInitiated)
      .fold(0.0, (acc, item) => acc + item.costImpactCr);

  int get _totalScheduleDaysEot =>
      _variationOrders.fold(0, (acc, item) => acc + item.scheduleImpactDays);

  int get _sanctionedDaysEot => _variationOrders
      .where((item) => item.isSanctioned)
      .fold(0, (acc, item) => acc + item.scheduleImpactDays);

  int get _reviewedDaysEot => _variationOrders
      .where((item) => item.isReviewed)
      .fold(0, (acc, item) => acc + item.scheduleImpactDays);

  int get _initiatedDaysEot => _variationOrders
      .where((item) => item.isInitiated)
      .fold(0, (acc, item) => acc + item.scheduleImpactDays);

  double get _variationToContractRatio =>
      (_totalCostImpactCr / _baselineContractValueCr) * 100;

  // ---------------------------------------------------------------------------
  // Filter & Search Logic
  // ---------------------------------------------------------------------------
  List<VariationOrderModel> get _filteredOrders {
    var list = _variationOrders.where((item) {
      if (_selectedFilter == 'SANCTIONED' && !item.isSanctioned) return false;
      if (_selectedFilter == 'REVIEWED' && !item.isReviewed) return false;
      if (_selectedFilter == 'INITIATED' && !item.isInitiated) return false;
      if (_selectedFilter == 'GEOLOGY' &&
          !item.reason.toLowerCase().contains('geological')) {
        return false;
      }
      if (_selectedFilter == 'DESIGN_MOD' &&
          !item.reason.toLowerCase().contains('design')) {
        return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesId = item.id.toLowerCase().contains(q);
        final matchesTitle = item.title.toLowerCase().contains(q);
        final matchesReason = item.reason.toLowerCase().contains(q);
        final matchesWp = item.workPackage.toLowerCase().contains(q);
        final matchesClause = item.clauseReference.toLowerCase().contains(q);
        if (!matchesId && !matchesTitle && !matchesReason && !matchesWp && !matchesClause) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sorting
    switch (_sortBy) {
      case 'COST_DESC':
        list.sort((a, b) => b.costImpactCr.compareTo(a.costImpactCr));
        break;
      case 'EOT_DESC':
        list.sort((a, b) => b.scheduleImpactDays.compareTo(a.scheduleImpactDays));
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
      if (_expandedCards.contains(id)) {
        _expandedCards.remove(id);
      } else {
        _expandedCards.add(id);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Interactive Workflow Progression
  // ---------------------------------------------------------------------------
  void _advanceWorkflowStage(VariationOrderModel vo) {
    if (vo.isSanctioned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${vo.id} is already Client Sanctioned. Fully authorized under FIDIC Cl. 13.'),
          backgroundColor: AppTheme.surfaceCard,
        ),
      );
      return;
    }

    if (vo.isInitiated) {
      _showEngineerReviewDialog(vo);
    } else if (vo.isReviewed) {
      _showClientSanctionDialog(vo);
    }
  }

  void _showEngineerReviewDialog(VariationOrderModel vo) {
    final commentCtrl = TextEditingController(
      text: 'Technical scope validated against FIDIC Cl. 13.1. Rate build-up evaluated per Cl. 13.3.1. CPM critical path impact accepted.',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: const [
            Icon(Icons.engineering_rounded, color: AppTheme.secondary, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Engineer Cl. 13.3 Review & Determination',
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
              Text(
                'Variation: ${vo.id} — ${vo.title}',
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _buildModalMetricRow('Cost Impact Evaluated', vo.formattedCost),
                    const SizedBox(height: 6),
                    _buildModalMetricRow('Time Impact (EOT)', vo.formattedSchedule),
                    const SizedBox(height: 6),
                    _buildModalMetricRow('Contractor JV', vo.contractorOriginator),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Engineer Evaluation Findings (FIDIC Sub-Clause 3.5 / 13.3):',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Enter engineer evaluation remarks...',
                ),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
            onPressed: () {
              setState(() {
                final idx = _variationOrders.indexWhere((x) => x.id == vo.id);
                if (idx != -1) {
                  _variationOrders[idx] = _variationOrders[idx].copyWith(
                    workflowStage: VariationWorkflowStage.engineerReviewed,
                    engineerReviewedDate: '30 Sep 2026',
                    sanctionReferenceNumber: 'AWAITING-CLIENT-SANCTION',
                  );
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${vo.id} successfully reviewed and endorsed by Engineer Marcus Vance, P.E.'),
                  backgroundColor: AppTheme.secondary,
                ),
              );
            },
            child: const Text('Endorse & Advance', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showClientSanctionDialog(VariationOrderModel vo) {
    final sanctionRefCtrl = TextEditingController(text: 'OIL/FIN/SANCT/${vo.id}/2026');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: const [
            Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Employer / Client Formal Sanction',
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
              Text(
                'Granting formal financial sanction and contract amendment for ${vo.id}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _buildModalMetricRow('Approved Cost Addition', vo.formattedCost),
                    const SizedBox(height: 6),
                    _buildModalMetricRow('Approved EOT Days', vo.formattedSchedule),
                    const SizedBox(height: 6),
                    _buildModalMetricRow('Signatory Body', 'Oil India Limited (OIL) Directorate'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Financial Sanction Authority Reference Number:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: sanctionRefCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'e.g. OIL/FIN/SANCT/...',
                ),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.tertiary),
            onPressed: () {
              setState(() {
                final idx = _variationOrders.indexWhere((x) => x.id == vo.id);
                if (idx != -1) {
                  _variationOrders[idx] = _variationOrders[idx].copyWith(
                    workflowStage: VariationWorkflowStage.clientSanctioned,
                    clientSanctionedDate: '30 Sep 2026',
                    clientSignatory: 'Sunil Khurana, CGM (Pipelines) - OIL',
                    sanctionReferenceNumber: sanctionRefCtrl.text.trim().isNotEmpty
                        ? sanctionRefCtrl.text.trim()
                        : 'OIL/FIN/SANCT/${vo.id}/2026',
                  );
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${vo.id} granted official Client Sanction. Variation Order executed.'),
                  backgroundColor: AppTheme.tertiary,
                ),
              );
            },
            child: const Text('Issue Sanction', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // New Variation Request Modal Sheet
  // ---------------------------------------------------------------------------
  void _openNewVariationRequestModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewVariationRequestBottomSheet(
        existingCount: _variationOrders.length,
        onSubmit: (newOrder) {
          setState(() {
            _variationOrders.add(newOrder);
            _expandedCards.add(newOrder.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Variation Request ${newOrder.id} successfully initiated and logged in FIDIC Cl. 13 register.'),
              backgroundColor: AppTheme.primary,
              duration: const Duration(seconds: 4),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIDIC Contract Information Dialog
  // ---------------------------------------------------------------------------
  void _showFidicCl13InfoModal(BuildContext context) {
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
                    color: AppTheme.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryLight, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FIDIC Red Book Clause 13 Framework',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Variations & Adjustments Standard Operating Protocol',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
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
                  _FidicClauseExplainer(
                    clauseNumber: 'Sub-Clause 13.1',
                    clauseTitle: 'Right to Vary',
                    description:
                        'The Engineer may initiate Variations at any time prior to issuing the Taking-Over Certificate, either by an instruction or by requesting a proposal from the Contractor. Variations may include changes to quantities, quality, levels, positions, dimensions, or omissions of work.',
                  ),
                  SizedBox(height: 12),
                  _FidicClauseExplainer(
                    clauseNumber: 'Sub-Clause 13.2',
                    clauseTitle: 'Value Engineering',
                    description:
                        'The Contractor may at any time submit a written proposal which, if adopted, will accelerate completion, reduce cost of execution, or improve the efficiency/value of the completed Works for the Employer. Financial savings are shared per contract agreement.',
                  ),
                  SizedBox(height: 12),
                  _FidicClauseExplainer(
                    clauseNumber: 'Sub-Clause 13.3',
                    clauseTitle: 'Variation Procedure & Valuation',
                    description:
                        'The Contractor submits: (a) a description of proposed work and schedule of execution, (b) proposal for any necessary modifications to the Programme under Cl. 8.3 and Extension of Time (EOT) under Cl. 8.4, and (c) evaluation of the proposed Variation based on Bill of Quantities rates or reasonable cost plus profit.',
                  ),
                  SizedBox(height: 12),
                  _FidicClauseExplainer(
                    clauseNumber: 'Sub-Clause 8.4',
                    clauseTitle: 'Extension of Time (EOT) for Completion',
                    description:
                        'The Contractor is entitled to an Extension of Time if and to the extent that completion of the Works is delayed by a Variation or substantial change in the quantity of an item of work included in the Contract.',
                  ),
                  SizedBox(height: 12),
                  _FidicClauseExplainer(
                    clauseNumber: 'Sub-Clause 14.1 / 15% Rule',
                    clauseTitle: 'Substantial Variation Limit',
                    description:
                        'Cumulative variations exceeding 15% of the Accepted Contract Amount trigger mandatory joint rate revisions, renegotiation of indirect costs, and specialized Employer Board re-sanctions.',
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
  // Build Main Screen
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'FIDIC Cl. 13 Variations',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Scope Change Management & Register',
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
            tooltip: 'FIDIC Cl. 8.7 Delay Damages',
            icon: const Icon(Icons.gavel_rounded, color: AppTheme.secondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LiquidatedDamagesScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'FIDIC Cl. 13 Guide',
            icon: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryLight),
            onPressed: () => _showFidicCl13InfoModal(context),
          ),
          IconButton(
            tooltip: 'Export Register Audit',
            icon: const Icon(Icons.share_outlined, color: AppTheme.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('FIDIC Clause 13 Variation Register exported to authenticated audit PDF'),
                  backgroundColor: AppTheme.surfaceCard,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'New Variation Request',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () => _openNewVariationRequestModal(context),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.surfaceCard,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Executive KPI Summary Dashboard
            _buildExecutiveSummaryCard(),
            const SizedBox(height: 12),

            // FIDIC 15% Threshold Banner
            _buildThresholdStatusBanner(),
            const SizedBox(height: 12),

            // Search Bar & Filter Chips
            _buildSearchBar(),
            const SizedBox(height: 10),
            _buildFilterChips(),
            const SizedBox(height: 14),

            // Register Header Row
            _buildRegisterSectionHeader(filtered.length),
            const SizedBox(height: 8),

            // Register Items List
            if (filtered.isEmpty)
              _buildEmptySearchResults()
            else
              ...filtered.map((item) => _buildVariationCard(item)),

            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Component: Executive Summary Card
  // ---------------------------------------------------------------------------
  Widget _buildExecutiveSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(14),
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryLight, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'VARIATION REGISTER OVERVIEW',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  '${_variationOrders.length} Change Orders',
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2 Primary Metrics: Total Cost Impact & Schedule EOT
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Cumulative Cost Impact',
                  value: '+₹${_totalCostImpactCr.toStringAsFixed(2)} Cr',
                  valueColor: AppTheme.secondary,
                  icon: Icons.currency_rupee_rounded,
                  subtitle: '${_variationToContractRatio.toStringAsFixed(2)}% of Contract Value',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'Cumulative EOT Claimed',
                  value: '+$_totalScheduleDaysEot Days',
                  valueColor: AppTheme.primaryLight,
                  icon: Icons.calendar_today_rounded,
                  subtitle: '$_sanctionedDaysEot Sanctioned / ${_reviewedDaysEot + _initiatedDaysEot} Pending',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 10),

          // Workflow Stage Pill Breakdown
          Row(
            children: [
              Expanded(
                child: _buildStagePill(
                  label: 'Sanctioned',
                  count: _variationOrders.where((v) => v.isSanctioned).length,
                  amount: '₹${_sanctionedCostCr.toStringAsFixed(2)} Cr',
                  color: AppTheme.tertiary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStagePill(
                  label: 'Eng. Reviewed',
                  count: _variationOrders.where((v) => v.isReviewed).length,
                  amount: '₹${_reviewedCostCr.toStringAsFixed(2)} Cr',
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStagePill(
                  label: 'Initiated',
                  count: _variationOrders.where((v) => v.isInitiated).length,
                  amount: '₹${_initiatedCostCr.toStringAsFixed(2)} Cr',
                  color: const Color(0xFF38BDF8),
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
    required Color valueColor,
    required IconData icon,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
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
              Icon(icon, size: 14, color: valueColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStagePill({
    required String label,
    required int count,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$count $label',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Component: FIDIC 15% Substantial Variation Threshold Banner
  // ---------------------------------------------------------------------------
  Widget _buildThresholdStatusBanner() {
    final ratio = _variationToContractRatio;
    final isWithinLimit = ratio <= _fidicThresholdPercentage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isWithinLimit
            ? AppTheme.tertiary.withAlpha(15)
            : AppTheme.error.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWithinLimit
              ? AppTheme.tertiary.withAlpha(100)
              : AppTheme.error.withAlpha(180),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWithinLimit ? Icons.shield_outlined : Icons.warning_amber_rounded,
            color: isWithinLimit ? AppTheme.tertiary : AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'FIDIC Cl. 12/13 Cumulative Variation Cap (15%)',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${ratio.toStringAsFixed(1)}% / 15.0%',
                      style: TextStyle(
                        color: isWithinLimit ? AppTheme.tertiary : AppTheme.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (ratio / _fidicThresholdPercentage).clamp(0.0, 1.0),
                    backgroundColor: AppTheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isWithinLimit ? AppTheme.tertiary : AppTheme.error,
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isWithinLimit
                      ? 'Within allowable variation ceiling (+₹${_totalCostImpactCr.toStringAsFixed(2)} Cr of ₹245.00 Cr Contract Sum).'
                      : 'WARNING: Cumulative variations exceed 15% threshold; requires Board re-sanction.',
                  style: TextStyle(
                    color: isWithinLimit ? AppTheme.textSecondary : AppTheme.error,
                    fontSize: 9.5,
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
  // UI Component: Search & Sort Bar
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search VO code, title, geology, design...',
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _searchQuery = ''),
                    child: const Icon(Icons.cancel, color: AppTheme.textMuted, size: 16),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              dropdownColor: AppTheme.surfaceCard,
              icon: const Icon(Icons.sort_rounded, color: AppTheme.primaryLight, size: 18),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              items: const [
                DropdownMenuItem(value: 'ID_ASC', child: Text('VO Code')),
                DropdownMenuItem(value: 'COST_DESC', child: Text('Highest Cost')),
                DropdownMenuItem(value: 'EOT_DESC', child: Text('Longest EOT')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _sortBy = val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // UI Component: Filter Chips Row
  // ---------------------------------------------------------------------------
  Widget _buildFilterChips() {
    final filters = [
      {'key': 'ALL', 'label': 'All (${_variationOrders.length})'},
      {'key': 'SANCTIONED', 'label': 'Sanctioned (${_variationOrders.where((v) => v.isSanctioned).length})'},
      {'key': 'REVIEWED', 'label': 'Eng. Reviewed (${_variationOrders.where((v) => v.isReviewed).length})'},
      {'key': 'INITIATED', 'label': 'Initiated (${_variationOrders.where((v) => v.isInitiated).length})'},
      {'key': 'GEOLOGY', 'label': 'Geology Strata'},
      {'key': 'DESIGN_MOD', 'label': 'Design Mod'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = f['key']!),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                  ),
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Component: Section Header
  // ---------------------------------------------------------------------------
  Widget _buildRegisterSectionHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined, size: 16, color: AppTheme.secondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'CHANGE ORDER REGISTER ($count)',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'FIDIC Cl. 13.1 / 13.3 Protocol',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySearchResults() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.find_in_page_outlined, color: AppTheme.textMuted, size: 40),
            const SizedBox(height: 10),
            const Text(
              'No variation orders match your criteria',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try changing search keyword or filter tab',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'ALL';
                });
              },
              child: const Text('Reset All Filters', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Component: Variation Order Card
  // ---------------------------------------------------------------------------
  Widget _buildVariationCard(VariationOrderModel item) {
    final isExpanded = _expandedCards.contains(item.id);

    // Color coordination based on stage
    final Color stageColor;
    final String stageBadgeLabel;
    final IconData stageIcon;
    switch (item.workflowStage) {
      case VariationWorkflowStage.clientSanctioned:
        stageColor = AppTheme.tertiary;
        stageBadgeLabel = 'CLIENT SANCTIONED';
        stageIcon = Icons.verified_rounded;
        break;
      case VariationWorkflowStage.engineerReviewed:
        stageColor = AppTheme.secondary;
        stageBadgeLabel = 'ENGINEER REVIEWED';
        stageIcon = Icons.engineering_rounded;
        break;
      case VariationWorkflowStage.initiated:
        stageColor = const Color(0xFF38BDF8);
        stageBadgeLabel = 'INITIATED';
        stageIcon = Icons.pending_actions_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? stageColor.withAlpha(140) : AppTheme.border,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: stageColor.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: VO ID, Clause Badge, Workflow Stage Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: const Border(bottom: BorderSide(color: AppTheme.border, width: 0.8)),
            ),
            child: Row(
              children: [
                // VO ID Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    item.id,
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Clause Reference Pill
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      item.clauseReference,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Workflow Stage Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: stageColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: stageColor.withAlpha(120)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(stageIcon, size: 12, color: stageColor),
                      const SizedBox(width: 4),
                      Text(
                        stageBadgeLabel,
                        style: TextStyle(
                          color: stageColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Card Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),

                // Reason pill & work package tag
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildTagChip(
                      icon: item.reason.toLowerCase().contains('geological')
                          ? Icons.layers_rounded
                          : Icons.architecture_rounded,
                      label: item.reason,
                      color: item.reason.toLowerCase().contains('geological')
                          ? Colors.amber.shade400
                          : Colors.cyan.shade300,
                    ),
                    _buildTagChip(
                      icon: Icons.inventory_2_outlined,
                      label: item.workPackage,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Key Impact Metrics (Cost & Schedule)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      // Cost Impact
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'COST IMPACT',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.formattedCost,
                              style: const TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: AppTheme.border),
                      const SizedBox(width: 12),

                      // Schedule Impact
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SCHEDULE IMPACT',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.formattedSchedule,
                              style: TextStyle(
                                color: item.scheduleImpactDays > 0
                                    ? AppTheme.primaryLight
                                    : AppTheme.tertiary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Visual Workflow Stepper Bar
                _buildWorkflowStepper(item),
                const SizedBox(height: 8),

                // Accordion Expand/Collapse Action
                InkWell(
                  onTap: () => _toggleCardExpansion(item.id),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isExpanded ? 'Hide Scope Breakdown & BOQ' : 'View Scope Details, BOQ & Approvals',
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.primaryLight,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded Section: Detailed Scope, BOQ Delta, Signatures, Actions
                if (isExpanded) ...[
                  const Divider(color: AppTheme.border, height: 16),
                  _buildExpandedVariationDetails(item),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Component: 3-Stage Workflow Stepper
  // ---------------------------------------------------------------------------
  Widget _buildWorkflowStepper(VariationOrderModel item) {
    final currentStep = item.workflowStage.stepIndex;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'APPROVAL WORKFLOW',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                'Step ${currentStep + 1} of 3',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Stage 1: Initiated
              _buildStepNode(
                title: 'Initiated',
                subtitle: item.submittedDate,
                isCompleted: currentStep >= 0,
                isActive: currentStep == 0,
                color: const Color(0xFF38BDF8),
              ),
              _buildStepConnector(isCompleted: currentStep >= 1, color: AppTheme.secondary),

              // Stage 2: Engineer Reviewed
              _buildStepNode(
                title: 'Engineer Reviewed',
                subtitle: item.engineerReviewedDate ?? 'Pending',
                isCompleted: currentStep >= 1,
                isActive: currentStep == 1,
                color: AppTheme.secondary,
              ),
              _buildStepConnector(isCompleted: currentStep >= 2, color: AppTheme.tertiary),

              // Stage 3: Client Sanctioned
              _buildStepNode(
                title: 'Client Sanctioned',
                subtitle: item.clientSanctionedDate ?? 'Pending',
                isCompleted: currentStep >= 2,
                isActive: currentStep == 2,
                color: AppTheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required Color color,
  }) {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? color : AppTheme.surfaceCard,
              border: Border.all(
                color: isCompleted ? color : AppTheme.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.black)
                  : Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.textMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isCompleted ? AppTheme.textPrimary : AppTheme.textMuted,
              fontSize: 9.5,
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: isCompleted ? color : AppTheme.textMuted,
              fontSize: 8.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector({required bool isCompleted, required Color color}) {
    return Expanded(
      flex: 2,
      child: Container(
        height: 2,
        color: isCompleted ? color : AppTheme.border,
        margin: const EdgeInsets.only(bottom: 22),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Component: Expanded Details (Scope, BOQ, Signatures, Workflow Action)
  // ---------------------------------------------------------------------------
  Widget _buildExpandedVariationDetails(VariationOrderModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scope Description
        const Text(
          'SCOPE BREAKDOWN & TECHNICAL SPECIFICATION',
          style: TextStyle(
            color: AppTheme.primaryLight,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(
            item.scopeDescription,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Technical Justifications
        if (item.technicalJustifications.isNotEmpty) ...[
          const Text(
            'FIDIC CLAUSE JUSTIFICATIONS & DEFECT AUDIT',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          ...item.technicalJustifications.map((justification) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.check_circle_outline, color: AppTheme.tertiary, size: 13),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        justification,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.3),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
        ],

        // BOQ Cost Breakdown
        if (item.boqCostBreakdown.isNotEmpty) ...[
          const Text(
            'BILL OF QUANTITIES (BOQ) VALUATION BREAKDOWN',
            style: TextStyle(
              color: AppTheme.secondary,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                ...item.boqCostBreakdown.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5),
                          ),
                        ),
                        Text(
                          '+₹${entry.value.toStringAsFixed(2)} Cr',
                          style: const TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  color: AppTheme.secondary.withAlpha(20),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total Variation Value',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        item.formattedCost,
                        style: const TextStyle(color: AppTheme.secondary, fontSize: 12.5, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Stakeholder Signatories & References
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              _buildSignatureRow('Contractor JV Originator', item.contractorOriginator, Icons.business_center_outlined),
              const SizedBox(height: 6),
              _buildSignatureRow('FIDIC Cl. 3.1 Engineer', item.engineerSignatory, Icons.engineering_outlined),
              if (item.clientSignatory != null) ...[
                const SizedBox(height: 6),
                _buildSignatureRow('Employer / Client Authority', item.clientSignatory!, Icons.verified_user_outlined),
              ],
              if (item.sanctionReferenceNumber != null) ...[
                const SizedBox(height: 6),
                _buildSignatureRow('Sanction Audit Ref', item.sanctionReferenceNumber!, Icons.tag_rounded),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Interactive Action Row
        Row(
          children: [
            // Workflow Action Button
            if (!item.isSanctioned)
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.isInitiated ? AppTheme.secondary : AppTheme.tertiary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: Icon(
                    item.isInitiated ? Icons.engineering_rounded : Icons.verified_rounded,
                    size: 16,
                  ),
                  label: Text(
                    item.isInitiated ? 'Engineer Review (Cl. 13.3)' : 'Grant Client Sanction',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _advanceWorkflowStage(item),
                ),
              )
            else
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.tertiary.withAlpha(120)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Variation Order Fully Executed & Logged',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 8),

            // Share / Notice preview button
            IconButton(
              tooltip: 'Generate Formal Notice',
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surface,
                side: const BorderSide(color: AppTheme.border),
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primaryLight, size: 18),
              onPressed: () => _showVariationNoticePreview(item),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignatureRow(String role, String name, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Text(
          '$role: ',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10.5, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildModalMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Notice Preview Bottom Sheet
  // ---------------------------------------------------------------------------
  void _showVariationNoticePreview(VariationOrderModel item) {
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
                const Icon(Icons.description_rounded, color: AppTheme.primaryLight, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Formal Variation Notice: ${item.id}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: AppTheme.border, height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'NIRMAAN OS • CONTRACT ADMINISTRATION RECORD',
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          'VARIATION ORDER FORM — FIDIC RED BOOK 2017 SUB-CLAUSE 13.3',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Divider(color: AppTheme.border, height: 20),
                      _buildNoticeField('Project', 'Trunk Crude Oil Pipeline Expansion (OIL-PL-024)'),
                      _buildNoticeField('Employer', 'Oil India Limited (OIL), Duliajan, Assam'),
                      _buildNoticeField('Engineer', item.engineerSignatory),
                      _buildNoticeField('Contractor JV', item.contractorOriginator),
                      _buildNoticeField('Variation Order Ref', item.id),
                      _buildNoticeField('Contractual Clause', item.clauseReference),
                      _buildNoticeField('Variation Title', item.title),
                      _buildNoticeField('Reason for Variation', item.reason),
                      _buildNoticeField('Financial Adjustment', item.formattedCost),
                      _buildNoticeField('Time Adjustment (EOT)', item.formattedSchedule),
                      _buildNoticeField('Workflow Stage', item.workflowStage.label),
                      if (item.sanctionReferenceNumber != null)
                        _buildNoticeField('Sanction Reference', item.sanctionReferenceNumber!),
                      const SizedBox(height: 12),
                      const Text(
                        'SCOPE SUMMARY & INSTRUCTION SUMMARY:',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.scopeDescription,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.lock_clock, size: 14, color: AppTheme.tertiary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Digital Hash & Timestamp logged in Nirmaan Immutable Audit Ledger.',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text('Export & Dispatch Notice PDF'),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notice for ${item.id} generated and ready for digital signing.'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
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
}

// =============================================================================
// Bottom Sheet Form: New Variation Request
// =============================================================================
class _NewVariationRequestBottomSheet extends StatefulWidget {
  final int existingCount;
  final Function(VariationOrderModel) onSubmit;

  const _NewVariationRequestBottomSheet({
    required this.existingCount,
    required this.onSubmit,
  });

  @override
  State<_NewVariationRequestBottomSheet> createState() =>
      _NewVariationRequestBottomSheetState();
}

class _NewVariationRequestBottomSheetState
    extends State<_NewVariationRequestBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _generatedId;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _scopeController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _originatorController = TextEditingController(
    text: 'Consortium EPC Joint Venture',
  );

  String _selectedReason = 'Unforeseen geological strata';
  String _selectedClause = 'FIDIC Cl. 13.1 (Right to Vary)';
  String _selectedWorkPackage = 'WP-03 Trenching & River Crossings';
  bool _hasCriticalPathImpact = true;

  final List<String> _reasonOptions = const [
    'Unforeseen geological strata',
    'Client design modification',
    'Statutory / Regulatory compliance change',
    'FIDIC Cl. 13.2 Value Engineering proposal',
  ];

  final List<String> _clauseOptions = const [
    'FIDIC Cl. 13.1 (Right to Vary)',
    'FIDIC Cl. 13.3 (Variation Procedure)',
    'FIDIC Cl. 13.2 (Value Engineering)',
  ];

  final List<String> _workPackages = const [
    'WP-01 Trunk Line Pipe Laying',
    'WP-02 Civil & Foundations',
    'WP-03 Trenching & River Crossings',
    'WP-04 Mechanical Piping & Bends',
    'WP-05 Electrical Utilities',
    'WP-07 SCADA & Automation',
    'WP-08 Process Equipment Skids',
  ];

  @override
  void initState() {
    super.initState();
    final seqNum = widget.existingCount + 1;
    final seqStr = seqNum < 10 ? '0$seqNum' : '$seqNum';
    _generatedId = 'VO-2026-$seqStr';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scopeController.dispose();
    _costController.dispose();
    _timeController.dispose();
    _originatorController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double costCr = double.tryParse(_costController.text.trim()) ?? 0.0;
    final int timeDays = int.tryParse(_timeController.text.trim()) ?? 0;

    final newVariation = VariationOrderModel(
      id: _generatedId,
      title: _titleController.text.trim(),
      clauseReference: _selectedClause,
      costImpactCr: costCr,
      scheduleImpactDays: timeDays,
      workflowStage: VariationWorkflowStage.initiated,
      reason: _selectedReason,
      scopeDescription: _scopeController.text.trim(),
      workPackage: _selectedWorkPackage,
      submittedDate: '30 Sep 2026',
      engineerReviewedDate: null,
      clientSanctionedDate: null,
      contractorOriginator: _originatorController.text.trim().isNotEmpty
          ? _originatorController.text.trim()
          : 'Consortium EPC Joint Venture',
      engineerSignatory: 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
      clientSignatory: null,
      sanctionReferenceNumber: 'UNDER-INITIAL-REVIEW',
      boqCostBreakdown: {
        'Direct Scope Execution & Labour': costCr * 0.70,
        'Equipment & Materials Procurement': costCr * 0.20,
        'Contractor OH&P Margin': costCr * 0.10,
      },
      technicalJustifications: [
        'Notice of Variation submitted under FIDIC Sub-Clause 13.3 & 20.1',
        'Preliminary Schedule CPM analysis indicates $timeDays days impact on critical path',
        'Directly necessitated by $_selectedReason',
      ],
      hasCriticalPathImpact: _hasCriticalPathImpact,
    );

    widget.onSubmit(newVariation);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppTheme.primary, width: 2)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.post_add_rounded, color: AppTheme.primaryLight, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'New Variation Request',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.primary),
                            ),
                            child: Text(
                              _generatedId,
                              style: const TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Formulated pursuant to FIDIC Red Book Sub-Clause 13.3',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
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

            // Scrollable Form Fields
            Expanded(
              child: ListView(
                children: [
                  // Variation Title
                  const Text(
                    'VARIATION TITLE *',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Additional Cross-Country Pipeline HDD Borehole Crossing',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please provide a descriptive title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Reason for Variation (Required per prompt)
                  const Text(
                    'REASON FOR VARIATION *',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedReason,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        items: _reasonOptions.map((reason) {
                          return DropdownMenuItem(
                            value: reason,
                            child: Row(
                              children: [
                                Icon(
                                  reason.contains('geological')
                                      ? Icons.layers_rounded
                                      : Icons.architecture_rounded,
                                  size: 15,
                                  color: reason.contains('geological') ? AppTheme.secondary : AppTheme.primaryLight,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(reason, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedReason = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // FIDIC Clause Reference
                  const Text(
                    'FIDIC CLAUSE REFERENCE *',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedClause,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        items: _clauseOptions.map((clause) {
                          return DropdownMenuItem(
                            value: clause,
                            child: Text(clause),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedClause = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Scope Description (Required per prompt)
                  const Text(
                    'SCOPE DESCRIPTION & SITE JUSTIFICATION *',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _scopeController,
                    maxLines: 4,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText:
                          'Describe technical scope, site observations (e.g. geological stratum drill findings or client revision drawings), and execution methodology...',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 15) {
                        return 'Please provide a detailed scope description (min 15 chars)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Estimated Cost & Estimated Time (Required per prompt)
                  Row(
                    children: [
                      // Estimated Cost
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ESTIMATED COST (₹ CR) *',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _costController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: AppTheme.secondary, fontSize: 14, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                prefixText: '₹ ',
                                prefixStyle: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                                hintText: 'e.g. 2.75',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter cost in Cr';
                                }
                                final parsed = double.tryParse(val.trim());
                                if (parsed == null || parsed <= 0) {
                                  return 'Must be > 0';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Estimated Time EOT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ESTIMATED TIME (DAYS EOT) *',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _timeController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppTheme.primaryLight, fontSize: 14, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                suffixText: 'Days',
                                suffixStyle: TextStyle(color: AppTheme.primaryLight),
                                hintText: 'e.g. 15',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter days';
                                }
                                final parsed = int.tryParse(val.trim());
                                if (parsed == null || parsed < 0) {
                                  return 'Invalid days';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Work Package Selection
                  const Text(
                    'AFFECTED WORK PACKAGE *',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWorkPackage,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        items: _workPackages.map((wp) {
                          return DropdownMenuItem(
                            value: wp,
                            child: Text(wp),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedWorkPackage = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Originator Contractor
                  const Text(
                    'CONTRACTOR JV ORIGINATOR',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _originatorController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Consortium EPC Joint Venture',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Critical Path Checkbox
                  InkWell(
                    onTap: () {
                      setState(() {
                        _hasCriticalPathImpact = !_hasCriticalPathImpact;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _hasCriticalPathImpact,
                            activeColor: AppTheme.primary,
                            onChanged: (val) {
                              setState(() {
                                _hasCriticalPathImpact = val ?? true;
                              });
                            },
                          ),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Direct Critical Path Impact',
                                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Flags this change order in Primavera P6 schedule network calculation',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Submit FIDIC Cl. 13 Variation Proposal',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: _submitForm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Explainer Card for FIDIC Guide Modal
// =============================================================================
class _FidicClauseExplainer extends StatelessWidget {
  final String clauseNumber;
  final String clauseTitle;
  final String description;

  const _FidicClauseExplainer({
    required this.clauseNumber,
    required this.clauseTitle,
    required this.description,
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
                  clauseNumber,
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  clauseTitle,
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
            description,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}
