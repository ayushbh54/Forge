import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';

class EvmDashboardScreen extends StatefulWidget {
  const EvmDashboardScreen({super.key});

  @override
  State<EvmDashboardScreen> createState() => _EvmDashboardScreenState();
}

class _EvmDashboardScreenState extends State<EvmDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Chart line visibility toggles
  bool _showPV = true;
  bool _showEV = true;
  bool _showAC = true;
  bool _showForecast = true;

  // Selected month index for detail inspection (null means latest)
  int? _selectedMonthIndex = 8; // Sep (Cutoff month)

  // Interactive Simulator state: workers to crash critical path
  double _crashingWorkers = 24.0;

  // Milestone financial health filter
  String _selectedMilestoneFilter = 'ALL';

  // Key Milestones Financial Health dataset
  final List<MilestoneFinancialRecord> _milestones = const [
    MilestoneFinancialRecord(
      title: 'Civil Foundations',
      wbsCode: 'WBS 02.01 · Substructure & Piling',
      plannedCost: 38.50,
      actualCost: 36.20,
      earnedValue: 38.50,
      progress: 1.00,
      targetDate: 'Jun 2026',
      status: 'UNDER_BUDGET',
      statusLabel: 'COMPLETED · UNDER BUDGET',
      note: '24 equipment foundation pads and compressor plinths casted. Early formwork stripping saved ₹2.30 Cr.',
      icon: Icons.foundation,
    ),
    MilestoneFinancialRecord(
      title: 'Pipe Racks',
      wbsCode: 'WBS 03.02 · Structural Steel & Piping',
      plannedCost: 52.00,
      actualCost: 56.40,
      earnedValue: 47.80,
      progress: 0.85,
      targetDate: 'Oct 2026',
      status: 'OVERRUN',
      statusLabel: 'CRITICAL OVERRUN',
      note: 'Welder gang shortages and field spool fit-up rework at Sector 4 caused ₹4.40 Cr overrun and 18-day critical path slippage.',
      icon: Icons.grid_goldenratio,
    ),
    MilestoneFinancialRecord(
      title: 'Hydrotest',
      wbsCode: 'WBS 04.01 · Pressure Testing & NDT',
      plannedCost: 19.20,
      actualCost: 17.80,
      earnedValue: 12.50,
      progress: 0.60,
      targetDate: 'Nov 2026',
      status: 'ON_TRACK',
      statusLabel: 'ACTIVE · ON TRACK',
      note: 'Testing loop A & B hydrotested to 148 bar successfully without pressure drop. Manpower spending is 7.3% under budget.',
      icon: Icons.speed,
    ),
    MilestoneFinancialRecord(
      title: 'Commissioning',
      wbsCode: 'WBS 06.01 · Systems Handover',
      plannedCost: 26.50,
      actualCost: 7.80,
      earnedValue: 6.00,
      progress: 0.20,
      targetDate: 'Dec 2026',
      status: 'COMMENCING',
      statusLabel: 'COMMENCING',
      note: 'Pre-commissioning electrical loop checks underway. Main turbine package dynamic commissioning scheduled for Q4.',
      icon: Icons.power_settings_new,
    ),
  ];

  // EVM Core Metrics Data (Cutoff: Sep 2026)
  static const double plannedValue = 124.50; // ₹ Cr
  static const double earnedValue = 112.80; // ₹ Cr
  static const double actualCost = 118.20; // ₹ Cr
  static const double budgetAtCompletion = 250.00; // ₹ Cr

  // Verified Mathematical EVM Formulas (PMI / ISO 21508 / FIDIC standards):
  // 1. Schedule Variance: SV = EV - PV
  static double get scheduleVariance => earnedValue - plannedValue; // 112.80 - 124.50 = -11.70 Cr
  // 2. Cost Variance: CV = EV - AC
  static double get costVariance => earnedValue - actualCost; // 112.80 - 118.20 = -5.40 Cr
  // 3. Schedule Performance Index: SPI = EV / PV
  static double get spi => earnedValue / plannedValue; // 112.80 / 124.50 = 0.906024... ≈ 0.91
  // 4. Cost Performance Index: CPI = EV / AC
  static double get cpi => earnedValue / actualCost; // 112.80 / 118.20 = 0.954314... ≈ 0.95
  // 5. Estimate at Completion: EAC = Budget / CPI (or BAC / CPI)
  static double get estimateAtCompletion => budgetAtCompletion / cpi; // 250.00 / 0.954314... = 261.97 Cr
  // 6. Estimate to Complete: ETC = EAC - AC
  static double get estimateToComplete => estimateAtCompletion - actualCost; // 261.97 - 118.20 = 143.77 Cr
  // 7. Variance at Completion: VAC = BAC - EAC
  static double get varianceAtCompletion => budgetAtCompletion - estimateAtCompletion; // 250.00 - 261.97 = -11.97 Cr
  // 8. To-Complete Performance Index: TCPI = (BAC - EV) / (BAC - AC)
  static double get tcpi => (budgetAtCompletion - earnedValue) / (budgetAtCompletion - actualCost); // 137.20 / 131.80 = 1.04

  // Monthly breakdown data (Jan 2026 to Dec 2026)
  final List<EvmMonthlyRecord> _monthlyData = const [
    EvmMonthlyRecord(
      month: 'Jan 26',
      cumPV: 12.00,
      cumEV: 12.50,
      cumAC: 11.80,
      incPV: 12.00,
      incEV: 12.50,
      incAC: 11.80,
      spi: 1.04,
      cpi: 1.06,
      status: 'AHEAD',
    ),
    EvmMonthlyRecord(
      month: 'Feb 26',
      cumPV: 27.00,
      cumEV: 27.30,
      cumAC: 26.30,
      incPV: 15.00,
      incEV: 14.80,
      incAC: 14.50,
      spi: 0.99,
      cpi: 1.02,
      status: 'ON_TRACK',
    ),
    EvmMonthlyRecord(
      month: 'Mar 26',
      cumPV: 45.00,
      cumEV: 44.50,
      cumAC: 44.20,
      incPV: 18.00,
      incEV: 17.20,
      incAC: 17.90,
      spi: 0.96,
      cpi: 0.96,
      status: 'WARNING',
    ),
    EvmMonthlyRecord(
      month: 'Apr 26',
      cumPV: 65.50,
      cumEV: 62.90,
      cumAC: 63.80,
      incPV: 20.50,
      incEV: 18.40,
      incAC: 19.60,
      spi: 0.90,
      cpi: 0.94,
      status: 'DELAYED',
    ),
    EvmMonthlyRecord(
      month: 'May 26',
      cumPV: 87.50,
      cumEV: 82.40,
      cumAC: 84.80,
      incPV: 22.00,
      incEV: 19.50,
      incAC: 21.00,
      spi: 0.89,
      cpi: 0.93,
      status: 'CRITICAL',
    ),
    EvmMonthlyRecord(
      month: 'Jun 26',
      cumPV: 108.50,
      cumEV: 101.30,
      cumAC: 105.20,
      incPV: 21.00,
      incEV: 18.90,
      incAC: 20.40,
      spi: 0.90,
      cpi: 0.93,
      status: 'CRITICAL',
    ),
    EvmMonthlyRecord(
      month: 'Jul 26',
      cumPV: 114.50,
      cumEV: 107.00,
      cumAC: 111.40,
      incPV: 6.00,
      incEV: 5.70,
      incAC: 6.20,
      spi: 0.95,
      cpi: 0.92,
      status: 'DELAYED',
    ),
    EvmMonthlyRecord(
      month: 'Aug 26',
      cumPV: 119.50,
      cumEV: 110.00,
      cumAC: 115.00,
      incPV: 5.00,
      incEV: 3.00,
      incAC: 3.60,
      spi: 0.92,
      cpi: 0.96,
      status: 'DELAYED',
    ),
    EvmMonthlyRecord(
      month: 'Sep 26',
      cumPV: 124.50,
      cumEV: 112.80,
      cumAC: 118.20,
      incPV: 5.00,
      incEV: 2.80,
      incAC: 3.20,
      spi: 0.91,
      cpi: 0.95,
      status: 'CURRENT',
      isCurrent: true,
    ),
    // Forecast Projections
    EvmMonthlyRecord(
      month: 'Oct 26',
      cumPV: 165.00,
      cumEV: 148.00,
      cumAC: 155.00,
      incPV: 40.50,
      incEV: 35.20,
      incAC: 36.80,
      spi: 0.93,
      cpi: 0.95,
      status: 'FORECAST',
      isForecast: true,
    ),
    EvmMonthlyRecord(
      month: 'Nov 26',
      cumPV: 210.00,
      cumEV: 195.00,
      cumAC: 205.00,
      incPV: 45.00,
      incEV: 47.00,
      incAC: 50.00,
      spi: 0.95,
      cpi: 0.95,
      status: 'FORECAST',
      isForecast: true,
    ),
    EvmMonthlyRecord(
      month: 'Dec 26',
      cumPV: 250.00,
      cumEV: 250.00,
      cumAC: 261.97,
      incPV: 40.00,
      incEV: 55.00,
      incAC: 56.97,
      spi: 1.00,
      cpi: 0.95,
      status: 'FORECAST',
      isForecast: true,
    ),
  ];

  // Discipline breakdown
  final List<DisciplineEvm> _disciplineBreakdown = const [
    DisciplineEvm(
      name: 'Piping & Welding',
      code: 'WBS 03.02',
      pv: 54.20,
      ev: 47.40,
      ac: 51.60,
      spi: 0.87,
      cpi: 0.92,
      critical: true,
    ),
    DisciplineEvm(
      name: 'Civil & Foundation',
      code: 'WBS 02.01',
      pv: 34.00,
      ev: 31.90,
      ac: 32.80,
      spi: 0.94,
      cpi: 0.97,
      critical: false,
    ),
    DisciplineEvm(
      name: 'Mechanical Equipment',
      code: 'WBS 04.05',
      pv: 21.80,
      ev: 19.90,
      ac: 20.80,
      spi: 0.91,
      cpi: 0.96,
      critical: false,
    ),
    DisciplineEvm(
      name: 'Electrical & Instrumentation',
      code: 'WBS 05.01',
      pv: 14.50,
      ev: 13.60,
      ac: 13.00,
      spi: 0.94,
      cpi: 1.05,
      critical: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earned Value Management',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'OIL-PL-024 · Pipeline Expansion · Cutoff: Sep 2026',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'EVM Formula Glossary',
            icon: const Icon(Icons.info_outline, color: AppTheme.primaryLight),
            onPressed: () => _showGlossaryDialog(context),
          ),
          IconButton(
            tooltip: 'Export EVM Audit Dossier',
            icon: const Icon(Icons.file_download_outlined, color: AppTheme.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exporting ISO/FIDIC EVM Compliance Dossier (PDF)...'),
                  backgroundColor: AppTheme.surfaceContainerHigh,
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.insights, size: 18), text: 'EVM & S-Curve'),
            Tab(icon: Icon(Icons.table_chart_outlined, size: 18), text: 'Monthly Ledger'),
            Tab(icon: Icon(Icons.account_tree_outlined, size: 18), text: 'WBS Variance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEvmAndSCurveTab(),
          _buildMonthlyLedgerTab(),
          _buildWbsVarianceTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: EVM & S-Curve Dashboard
  // ---------------------------------------------------------------------------
  Widget _buildEvmAndSCurveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Health Alert Banner
          _buildHealthAlertBanner(),
          const SizedBox(height: 16),

          // Primary Triad Cards (PV, EV, AC)
          _buildPrimaryTriadSection(),
          const SizedBox(height: 16),

          // Variance & Index Grid (SV, CV, SPI, CPI)
          _buildVarianceAndIndexGrid(),
          const SizedBox(height: 16),

          // Forecasting Cards (EAC, ETC, VAC, BAC)
          _buildForecastingSection(),
          const SizedBox(height: 24),

          // Milestone Financial Health Card (Planned vs Actual Cost)
          _buildMilestoneFinancialHealthCard(),
          const SizedBox(height: 24),

          // S-Curve Line Chart Section
          _buildSCurveChartSection(),
          const SizedBox(height: 24),

          // Interactive Cost-Schedule Recovery Simulator
          _buildCostScheduleRecoverySimulator(),
          const SizedBox(height: 24),

          // AI Schedule Recovery Recommendation Card
          _buildAiRecoveryCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Banner highlighting critical thresholds
  Widget _buildHealthAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondary.withAlpha(120), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'STATUS: CRITICAL PATH DELAY',
                      style: TextStyle(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '• SPI ${spi.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Physical work earned (₹${earnedValue.toStringAsFixed(2)} Cr) lags baseline (₹${plannedValue.toStringAsFixed(2)} Cr) by ₹${scheduleVariance.abs().toStringAsFixed(2)} Cr. EAC (₹${estimateAtCompletion.toStringAsFixed(2)} Cr) exceeds baseline budget by ₹${varianceAtCompletion.abs().toStringAsFixed(2)} Cr.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
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

  // 1. Primary Triad (PV, EV, AC)
  Widget _buildPrimaryTriadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cumulative Capital Metrics (Cutoff)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Values in ₹ Crores',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTriadCard(
                title: 'Planned Value (PV)',
                subtitle: 'Baseline Scheduled Work',
                value: '₹${plannedValue.toStringAsFixed(2)} Cr',
                accentColor: AppTheme.primaryLight,
                icon: Icons.calendar_month,
                formula: 'PV = Budgeted Cost of Work Sched (BCWS)',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTriadCard(
                title: 'Earned Value (EV)',
                subtitle: 'Physical Work Performed',
                value: '₹${earnedValue.toStringAsFixed(2)} Cr',
                accentColor: AppTheme.tertiary,
                icon: Icons.check_circle_outline,
                formula: 'EV = Budgeted Cost of Work Perf (BCWP)',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTriadCard(
                title: 'Actual Cost (AC)',
                subtitle: 'Incurred Expenditures',
                value: '₹${actualCost.toStringAsFixed(2)} Cr',
                accentColor: AppTheme.secondary,
                icon: Icons.account_balance_wallet_outlined,
                formula: 'AC = Actual Cost of Work Perf (ACWP)',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTriadCard({
    required String title,
    required String subtitle,
    required String value,
    required Color accentColor,
    required IconData icon,
    required String formula,
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              Tooltip(
                message: formula,
                child: const Icon(
                  Icons.help_outline,
                  color: AppTheme.textMuted,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Variance & Index Grid (SV, CV, SPI, CPI)
  Widget _buildVarianceAndIndexGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Indices & Variances',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            // Schedule Variance (SV)
            _buildMetricTile(
              label: 'Schedule Variance (SV)',
              value: '${scheduleVariance >= 0 ? '+' : '-'}₹${scheduleVariance.abs().toStringAsFixed(2)} Cr',
              formula: 'EV - PV (${earnedValue.toStringAsFixed(2)} - ${plannedValue.toStringAsFixed(2)})',
              badgeText: scheduleVariance >= 0 ? 'Ahead' : 'Delayed',
              badgeColor: scheduleVariance >= 0 ? AppTheme.tertiary : Colors.redAccent,
              icon: Icons.access_time_filled,
              isNegative: scheduleVariance < 0,
              subtitle: 'Work lag behind baseline schedule',
            ),

            // Cost Variance (CV)
            _buildMetricTile(
              label: 'Cost Variance (CV)',
              value: '${costVariance >= 0 ? '+' : '-'}₹${costVariance.abs().toStringAsFixed(2)} Cr',
              formula: 'EV - AC (${earnedValue.toStringAsFixed(2)} - ${actualCost.toStringAsFixed(2)})',
              badgeText: costVariance >= 0 ? 'Underbudget' : 'Overbudget',
              badgeColor: costVariance >= 0 ? AppTheme.tertiary : Colors.redAccent,
              icon: Icons.trending_down,
              isNegative: costVariance < 0,
              subtitle: 'Cost overrun against work done',
            ),

            // Schedule Performance Index (SPI)
            _buildIndexTile(
              label: 'Schedule Performance (SPI)',
              indexValue: spi,
              formula: 'EV / PV (${earnedValue.toStringAsFixed(2)} / ${plannedValue.toStringAsFixed(2)})',
              statusText: '${spi.toStringAsFixed(2)} (${spi >= 1.0 ? "Ahead" : (spi >= 0.90 ? "Amber" : "Delayed")})',
              target: 'Target: ≥ 1.00',
              statusColor: spi >= 1.0 ? AppTheme.tertiary : (spi >= 0.90 ? AppTheme.secondary : Colors.redAccent),
              icon: Icons.speed,
            ),

            // Cost Performance Index (CPI)
            _buildIndexTile(
              label: 'Cost Performance (CPI)',
              indexValue: cpi,
              formula: 'EV / AC (${earnedValue.toStringAsFixed(2)} / ${actualCost.toStringAsFixed(2)})',
              statusText: '${cpi.toStringAsFixed(2)} (${cpi >= 1.0 ? "Under budget" : (cpi >= 0.90 ? "Amber" : "Overrun")})',
              target: 'Target: ≥ 1.00',
              statusColor: cpi >= 1.0 ? AppTheme.tertiary : (cpi >= 0.90 ? AppTheme.secondary : Colors.redAccent),
              icon: Icons.pie_chart_outline,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String formula,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required bool isNegative,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(icon, color: badgeColor, size: 22),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            formula,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexTile({
    required String label,
    required double indexValue,
    required String formula,
    required String statusText,
    required String target,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(6),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                indexValue.toStringAsFixed(2),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Linear mini indicator
              SizedBox(
                width: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: indexValue.clamp(0.0, 1.2) / 1.2,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formula,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                target,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Forecasting Section (EAC, ETC, VAC, BAC)
  Widget _buildForecastingSection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_graph, color: AppTheme.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Completion Forecast (EAC / ETC / VAC)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                'BAC: ₹${budgetAtCompletion.toStringAsFixed(2)} Cr',
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // EAC
              Expanded(
                child: _buildForecastColumn(
                  title: 'Estimate at Completion (EAC)',
                  value: '₹${estimateAtCompletion.toStringAsFixed(2)} Cr',
                  comparison: 'Budget / CPI (${budgetAtCompletion.toStringAsFixed(0)} / ${cpi.toStringAsFixed(2)})',
                  color: Colors.orangeAccent,
                  note: varianceAtCompletion < 0
                      ? 'Overrun: +₹${varianceAtCompletion.abs().toStringAsFixed(2)} Cr'
                      : 'Under budget: -₹${varianceAtCompletion.toStringAsFixed(2)} Cr',
                ),
              ),
              Container(width: 1, height: 60, color: AppTheme.border),
              // ETC
              Expanded(
                child: _buildForecastColumn(
                  title: 'Estimate to Complete (ETC)',
                  value: '₹${estimateToComplete.toStringAsFixed(2)} Cr',
                  comparison: 'EAC - AC (${estimateAtCompletion.toStringAsFixed(1)} - ${actualCost.toStringAsFixed(1)})',
                  color: AppTheme.primaryLight,
                  note: 'Work remaining',
                ),
              ),
              Container(width: 1, height: 60, color: AppTheme.border),
              // VAC
              Expanded(
                child: _buildForecastColumn(
                  title: 'Variance at Compl. (VAC)',
                  value: '${varianceAtCompletion >= 0 ? '+' : '-'}₹${varianceAtCompletion.abs().toStringAsFixed(2)} Cr',
                  comparison: 'BAC - EAC (${budgetAtCompletion.toStringAsFixed(0)} - ${estimateAtCompletion.toStringAsFixed(1)})',
                  color: varianceAtCompletion >= 0 ? AppTheme.tertiary : Colors.redAccent,
                  note: varianceAtCompletion < 0 ? 'Unfavorable variance' : 'Favorable variance',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // TCPI progress bar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppTheme.secondary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'To-Complete Performance Index (TCPI) to achieve BAC: ${tcpi.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Higher Efficiency Needed',
                    style: TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastColumn({
    required String title,
    required String value,
    required String comparison,
    required Color color,
    required String note,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            comparison,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.withAlpha(200),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Milestone Financial Health Card (Planned vs Actual Cost)
  // ---------------------------------------------------------------------------
  Widget _buildMilestoneFinancialHealthCard() {
    final filteredMilestones = _selectedMilestoneFilter == 'ALL'
        ? _milestones
        : _milestones
            .where((m) => m.status == _selectedMilestoneFilter)
            .toList();

    const double totalPlanned = 136.20;
    const double totalActual = 118.20;
    const double netVariance = totalPlanned - totalActual;

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_outlined,
                        color: AppTheme.primaryLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Milestone Financial Health',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Planned vs Actual Cost for Core Delivery Packages',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  'FIDIC Cl. 14 / ISO 21508',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Executive Summary KPI Strip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMilestoneSummaryItem(
                    label: 'Total Planned',
                    value: '₹${totalPlanned.toStringAsFixed(2)} Cr',
                    color: AppTheme.primaryLight,
                  ),
                ),
                Container(width: 1, height: 34, color: AppTheme.border),
                Expanded(
                  child: _buildMilestoneSummaryItem(
                    label: 'Total Incurred',
                    value: '₹${totalActual.toStringAsFixed(2)} Cr',
                    color: AppTheme.secondary,
                  ),
                ),
                Container(width: 1, height: 34, color: AppTheme.border),
                Expanded(
                  child: _buildMilestoneSummaryItem(
                    label: 'Net Balance',
                    value: '+₹${netVariance.toStringAsFixed(2)} Cr',
                    color: AppTheme.tertiary,
                  ),
                ),
                Container(width: 1, height: 34, color: AppTheme.border),
                Expanded(
                  child: _buildMilestoneSummaryItem(
                    label: 'Critical Overrun',
                    value: '-₹4.40 Cr',
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Interactive Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMilestoneFilterChip('ALL', 'All Gates (4)'),
                const SizedBox(width: 8),
                _buildMilestoneFilterChip('OVERRUN', 'Cost Overrun (1)'),
                const SizedBox(width: 8),
                _buildMilestoneFilterChip('UNDER_BUDGET', 'Under Budget (1)'),
                const SizedBox(width: 8),
                _buildMilestoneFilterChip('ON_TRACK', 'On Track (1)'),
                const SizedBox(width: 8),
                _buildMilestoneFilterChip('COMMENCING', 'Commencing (1)'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Milestone Cards List
          ...filteredMilestones.map((m) => _buildMilestoneDetailCard(m)),
        ],
      ),
    );
  }

  Widget _buildMilestoneSummaryItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneFilterChip(String filterKey, String label) {
    final isSelected = _selectedMilestoneFilter == filterKey;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMilestoneFilter = filterKey;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight.withAlpha(30)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneDetailCard(MilestoneFinancialRecord m) {
    final bool isOverrun = m.isOverBudget;
    final Color badgeColor = isOverrun
        ? Colors.redAccent
        : (m.progress >= 1.0
            ? AppTheme.tertiary
            : (m.status == 'COMMENCING'
                ? AppTheme.secondary
                : AppTheme.primaryLight));

    // Scale proportional bar width relative to max milestone cost (60 Cr)
    const double maxScale = 60.0;
    final double plannedFactor = (m.plannedCost / maxScale).clamp(0.05, 1.0);
    final double actualFactor = (m.actualCost / maxScale).clamp(0.05, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverrun
              ? Colors.redAccent.withAlpha(100)
              : (m.progress >= 1.0
                  ? AppTheme.tertiary.withAlpha(70)
                  : AppTheme.border),
          width: isOverrun ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Milestone Title & Status Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(m.icon, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${m.wbsCode} · Target: ${m.targetDate}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor.withAlpha(80)),
                    ),
                    child: Text(
                      m.statusLabel,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${(m.progress * 100).toInt()}% Physical Complete',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Visual Comparative Planned vs Actual Bars
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withAlpha(80)),
            ),
            child: Column(
              children: [
                // Planned Cost Bar
                Row(
                  children: [
                    const SizedBox(
                      width: 80,
                      child: Text(
                        'Planned Cost',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          return Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                height: 8,
                                width: constraints.maxWidth * plannedFactor,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 72,
                      child: Text(
                        '₹${m.plannedCost.toStringAsFixed(2)} Cr',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Actual Cost Bar
                Row(
                  children: [
                    const SizedBox(
                      width: 80,
                      child: Text(
                        'Actual Spent',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          return Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                height: 8,
                                width: constraints.maxWidth * actualFactor,
                                decoration: BoxDecoration(
                                  color: isOverrun
                                      ? Colors.redAccent
                                      : AppTheme.tertiary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 72,
                      child: Text(
                        '₹${m.actualCost.toStringAsFixed(2)} Cr',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: isOverrun
                              ? Colors.redAccent
                              : AppTheme.tertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 5-metric summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMilestoneMiniStat(
                label: 'Planned (PV)',
                value: '₹${m.plannedCost.toStringAsFixed(1)} Cr',
                color: AppTheme.primaryLight,
              ),
              _buildMilestoneMiniStat(
                label: 'Actual (AC)',
                value: '₹${m.actualCost.toStringAsFixed(1)} Cr',
                color: isOverrun ? Colors.redAccent : AppTheme.secondary,
              ),
              _buildMilestoneMiniStat(
                label: 'Earned (EV)',
                value: '₹${m.earnedValue.toStringAsFixed(1)} Cr',
                color: AppTheme.tertiary,
              ),
              _buildMilestoneMiniStat(
                label: 'Cost Delta',
                value: isOverrun
                    ? '-₹${(m.actualCost - m.plannedCost).toStringAsFixed(2)} Cr'
                    : '+₹${(m.plannedCost - m.actualCost).toStringAsFixed(2)} Cr',
                color: isOverrun ? Colors.redAccent : AppTheme.tertiary,
              ),
              _buildMilestoneMiniStat(
                label: 'Index (CPI)',
                value: m.cpi.toStringAsFixed(2),
                color: m.cpi >= 1.0 ? AppTheme.tertiary : Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Field Operational Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isOverrun
                  ? Colors.redAccent.withAlpha(15)
                  : AppTheme.surfaceContainerHigh.withAlpha(40),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isOverrun ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: isOverrun ? Colors.redAccent : AppTheme.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    m.note,
                    style: TextStyle(
                      color: isOverrun
                          ? const Color(0xFFFECACA)
                          : AppTheme.textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneMiniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. S-Curve Line Chart (Cumulative PV vs EV vs AC over months)
  // ---------------------------------------------------------------------------
  Widget _buildSCurveChartSection() {
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
          // Header with Toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'S-Curve Progress Tracking',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Cumulative Planned (PV) vs Earned (EV) vs Actual (AC) in ₹ Cr',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, size: 12, color: AppTheme.primaryLight),
                    SizedBox(width: 4),
                    Text(
                      'Tap points to inspect',
                      style: TextStyle(color: AppTheme.primaryLight, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Interactive Filter Chips for Lines
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChartFilterChip(
                label: 'Planned Value (PV)',
                color: AppTheme.primaryLight,
                isActive: _showPV,
                isDashed: true,
                onTap: () => setState(() => _showPV = !_showPV),
              ),
              _buildChartFilterChip(
                label: 'Earned Value (EV)',
                color: AppTheme.tertiary,
                isActive: _showEV,
                onTap: () => setState(() => _showEV = !_showEV),
              ),
              _buildChartFilterChip(
                label: 'Actual Cost (AC)',
                color: AppTheme.secondary,
                isActive: _showAC,
                onTap: () => setState(() => _showAC = !_showAC),
              ),
              _buildChartFilterChip(
                label: 'Forecast (Q4)',
                color: Colors.purpleAccent,
                isActive: _showForecast,
                isDotted: true,
                onTap: () => setState(() => _showForecast = !_showForecast),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // The Line Chart
          SizedBox(
            height: 260,
            child: LineChart(
              _buildLineChartData(),
            ),
          ),
          const SizedBox(height: 12),

          // Selected Month Inspector Strip
          if (_selectedMonthIndex != null &&
              _selectedMonthIndex! < _monthlyData.length)
            _buildMonthInspectorStrip(_monthlyData[_selectedMonthIndex!]),
        ],
      ),
    );
  }

  Widget _buildChartFilterChip({
    required String label,
    required Color color,
    required bool isActive,
    bool isDashed = false,
    bool isDotted = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? color.withAlpha(35) : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : AppTheme.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? color : AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.textPrimary : AppTheme.textMuted,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData() {
    // 0 to 8: Jan to Sep (Actuals)
    // 9 to 11: Oct to Dec (Forecast)

    final List<FlSpot> pvSpots = [];
    final List<FlSpot> evSpots = [];
    final List<FlSpot> acSpots = [];
    final List<FlSpot> forecastEvSpots = [];
    final List<FlSpot> forecastAcSpots = [];

    for (int i = 0; i < _monthlyData.length; i++) {
      final rec = _monthlyData[i];
      if (i <= 8) {
        pvSpots.add(FlSpot(i.toDouble(), rec.cumPV));
        evSpots.add(FlSpot(i.toDouble(), rec.cumEV));
        acSpots.add(FlSpot(i.toDouble(), rec.cumAC));
      } else {
        pvSpots.add(FlSpot(i.toDouble(), rec.cumPV));
      }
    }

    // Add connecting bridge point for forecasts
    if (_showForecast) {
      forecastEvSpots.add(FlSpot(8, _monthlyData[8].cumEV));
      forecastAcSpots.add(FlSpot(8, _monthlyData[8].cumAC));
      for (int i = 9; i < _monthlyData.length; i++) {
        forecastEvSpots.add(FlSpot(i.toDouble(), _monthlyData[i].cumEV));
        forecastAcSpots.add(FlSpot(i.toDouble(), _monthlyData[i].cumAC));
      }
    }

    final List<LineChartBarData> lineBarsData = [];

    // 1. Planned Value (Cyan)
    if (_showPV) {
      lineBarsData.add(
        LineChartBarData(
          spots: pvSpots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: AppTheme.primaryLight,
          barWidth: 3,
          isStrokeCapRound: true,
          dashArray: [5, 4],
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: index == 8 ? 5 : 2.5,
              color: AppTheme.primaryLight,
              strokeWidth: 1.5,
              strokeColor: AppTheme.background,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.primaryLight.withAlpha(15),
          ),
        ),
      );
    }

    // 2. Earned Value (Green)
    if (_showEV) {
      lineBarsData.add(
        LineChartBarData(
          spots: evSpots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: AppTheme.tertiary,
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: index == 8 ? 6 : 3,
              color: AppTheme.tertiary,
              strokeWidth: 2,
              strokeColor: AppTheme.background,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.tertiary.withAlpha(20),
          ),
        ),
      );
    }

    // 3. Actual Cost (Amber)
    if (_showAC) {
      lineBarsData.add(
        LineChartBarData(
          spots: acSpots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: AppTheme.secondary,
          barWidth: 3.2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: index == 8 ? 6 : 3,
              color: AppTheme.secondary,
              strokeWidth: 2,
              strokeColor: AppTheme.background,
            ),
          ),
          belowBarData: BarAreaData(
            show: false,
          ),
        ),
      );
    }

    // 4. Forecast Projected EV (Dashed Purple)
    if (_showForecast && forecastEvSpots.isNotEmpty) {
      lineBarsData.add(
        LineChartBarData(
          spots: forecastEvSpots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: Colors.purpleAccent,
          barWidth: 2.5,
          dashArray: [4, 4],
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: 3,
              color: Colors.purpleAccent,
              strokeWidth: 1.5,
              strokeColor: AppTheme.background,
            ),
          ),
        ),
      );
    }

    return LineChartData(
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchCallback: (event, response) {
          if (response?.lineBarSpots != null &&
              response!.lineBarSpots!.isNotEmpty) {
            final xIndex = response.lineBarSpots!.first.x.round();
            if (xIndex >= 0 && xIndex < _monthlyData.length) {
              setState(() {
                _selectedMonthIndex = xIndex;
              });
            }
          }
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppTheme.surfaceContainerHigh,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((barSpot) {
              final month = _monthlyData[barSpot.x.toInt()].month;
              final lineName = barSpot.barIndex == 0
                  ? 'PV'
                  : barSpot.barIndex == 1
                      ? 'EV'
                      : barSpot.barIndex == 2
                          ? 'AC'
                          : 'Forecast';
              return LineTooltipItem(
                '$month · $lineName: ₹${barSpot.y.toStringAsFixed(1)} Cr',
                TextStyle(
                  color: barSpot.bar.color ?? AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 50,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) => const FlLine(
          color: AppTheme.border,
          strokeWidth: 0.8,
          dashArray: [4, 4],
        ),
        getDrawingVerticalLine: (value) {
          // Highlight cutoff line (Month index 8 = Sep)
          if (value == 8) {
            return const FlLine(
              color: Colors.redAccent,
              strokeWidth: 1.5,
              dashArray: [5, 3],
            );
          }
          return const FlLine(
            color: Color(0xFF162347),
            strokeWidth: 0.5,
          );
        },
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 50,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value > 260) return const SizedBox.shrink();
              return Text(
                '₹${value.toInt()}Cr',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 26,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= _monthlyData.length) {
                return const SizedBox.shrink();
              }
              final isCurrent = index == 8;
              return Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  _monthlyData[index].month.split(' ')[0], // 'Jan', 'Feb' etc
                  style: TextStyle(
                    color: isCurrent
                        ? AppTheme.primaryLight
                        : (index > 8 ? AppTheme.textMuted : AppTheme.textSecondary),
                    fontSize: 9.5,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 275,
    );
  }

  Widget _buildMonthInspectorStrip(EvmMonthlyRecord record) {
    final sv = record.cumEV - record.cumPV;
    final cv = record.cumEV - record.cumAC;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: record.isCurrent ? AppTheme.primaryLight : AppTheme.border,
          width: record.isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Month: ${record.month}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (record.isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withAlpha(40),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'CURRENT CUTOFF',
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if (record.isForecast) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withAlpha(40),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PROJECTED',
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                'SPI: ${record.spi.toStringAsFixed(2)} | CPI: ${record.cpi.toStringAsFixed(2)}',
                style: TextStyle(
                  color: record.spi < 1.0 ? AppTheme.secondary : AppTheme.tertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniValue('Cum PV', '₹${record.cumPV.toStringAsFixed(1)} Cr', AppTheme.primaryLight),
              _buildMiniValue('Cum EV', '₹${record.cumEV.toStringAsFixed(1)} Cr', AppTheme.tertiary),
              _buildMiniValue('Cum AC', '₹${record.cumAC.toStringAsFixed(1)} Cr', AppTheme.secondary),
              _buildMiniValue(
                'SV',
                '${sv >= 0 ? '+' : ''}₹${sv.toStringAsFixed(1)} Cr',
                sv >= 0 ? AppTheme.tertiary : Colors.redAccent,
              ),
              _buildMiniValue(
                'CV',
                '${cv >= 0 ? '+' : ''}₹${cv.toStringAsFixed(1)} Cr',
                cv >= 0 ? AppTheme.tertiary : Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniValue(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Cost-Schedule Recovery Simulator (Simulate Crashing by +X Workers)
  // ---------------------------------------------------------------------------
  Widget _buildCostScheduleRecoverySimulator() {
    final int workers = _crashingWorkers.round();

    // Marginal productivity formula: initial workers recover ~0.44 days each,
    // with realistic diminishing returns (Brooks' Law / coordination overhead)
    final double daysSaved = workers == 0
        ? 0.0
        : (workers * 0.44 - (workers * workers * 0.0019)).clamp(0.0, 22.0);

    // Baseline unmitigated projected finish is 28 Dec 2026 (18-day delay past 10 Dec 2026 target)
    final DateTime baseDelayDate = DateTime(2026, 12, 28);
    final DateTime targetBaselineDate = DateTime(2026, 12, 10);
    final DateTime projectedDate =
        baseDelayDate.subtract(Duration(days: daysSaved.round()));

    final int daysDelayRemaining =
        projectedDate.difference(targetBaselineDate).inDays;

    // Projected SPI: from 0.91 unmitigated up to 1.05+
    final double simulatedSpi =
        (0.91 + (daysSaved / 18.0) * 0.14).clamp(0.91, 1.10);

    // Crashing Cost: ₹3,200/worker-day * 75 days campaign = ₹2.40 Lakh per worker = ₹0.028 Cr with supervisor overhead
    final double crashingCost = workers * 0.028;

    // FIDIC Cl. 8.7 Liquidated Damages avoided: ₹25 Lakh/day (₹0.25 Cr/day)
    final double ldAvoided = daysSaved * 0.25;

    // Net financial benefit
    final double netSavings = ldAvoided - crashingCost;

    // Status classification
    final Color statusColor;
    final String statusBadge;
    if (simulatedSpi >= 1.02) {
      statusColor = AppTheme.primaryLight;
      statusBadge = 'FAST-TRACK AHEAD OF BASELINE';
    } else if (simulatedSpi >= 0.99) {
      statusColor = AppTheme.tertiary;
      statusBadge = 'SCHEDULE RECOVERED (TARGET ACHIEVED)';
    } else if (workers > 0) {
      statusColor = AppTheme.secondary;
      statusBadge = 'PARTIAL SLIPPAGE MITIGATED';
    } else {
      statusColor = Colors.redAccent;
      statusBadge = 'UNMITIGATED CRITICAL PATH LAG';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryLight.withAlpha(120),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withAlpha(15),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withAlpha(20),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune, color: AppTheme.primaryLight, size: 22),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cost-Schedule Recovery Simulator',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Primavera P6 CPM Crashing & Earned Schedule Analysis',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withAlpha(90)),
                  ),
                  child: Text(
                    statusBadge,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Slider Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.groups, color: AppTheme.primaryLight, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Simulate Crashing by +X Workers:',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+$workers Workers',
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (workers > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(+₹${crashingCost.toStringAsFixed(2)} Cr)',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Interactive Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryLight,
                    inactiveTrackColor: AppTheme.surfaceContainerHigh,
                    thumbColor: AppTheme.primaryLight,
                    overlayColor: AppTheme.primaryLight.withAlpha(40),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _crashingWorkers,
                    min: 0.0,
                    max: 60.0,
                    divisions: 60,
                    label: '+$workers Workers',
                    onChanged: (val) {
                      setState(() {
                        _crashingWorkers = val;
                      });
                    },
                  ),
                ),

                // Preset Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCrashingPresetChip(label: 'Baseline (+0)', workers: 0),
                    _buildCrashingPresetChip(label: '+15 NDT Crew', workers: 15),
                    _buildCrashingPresetChip(label: '+24 Gang C', workers: 24),
                    _buildCrashingPresetChip(label: '+50 Dec 10 Target', workers: 50),
                  ],
                ),
                const SizedBox(height: 16),

                // 2x2 Dynamic Recalculation Results Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.55,
                  children: [
                    // Tile 1: Projected Completion Date
                    _buildSimulatorTile(
                      label: 'Projected Completion Date',
                      mainValue: DateFormat('dd MMM yyyy').format(projectedDate),
                      badgeText: daysDelayRemaining > 0
                          ? '-${daysDelayRemaining}d Lag'
                          : (daysDelayRemaining == 0
                              ? 'Target Met'
                              : '+${daysDelayRemaining.abs()}d Ahead'),
                      badgeColor: daysDelayRemaining > 0
                          ? AppTheme.secondary
                          : AppTheme.tertiary,
                      icon: Icons.event_available,
                      subtitle: daysSaved > 0
                          ? '${daysSaved.toStringAsFixed(1)} days recovered vs 28 Dec'
                          : '18 days delayed past Dec 10',
                      accentColor: AppTheme.primaryLight,
                    ),

                    // Tile 2: Projected SPI
                    _buildSimulatorTile(
                      label: 'Projected Schedule Index (SPI)',
                      mainValue: simulatedSpi.toStringAsFixed(2),
                      badgeText: simulatedSpi >= 1.00 ? 'SPI ≥ 1.00' : 'SPI < 1.00',
                      badgeColor: simulatedSpi >= 1.00
                          ? AppTheme.tertiary
                          : AppTheme.secondary,
                      icon: Icons.speed,
                      subtitle:
                          'Current: 0.91 (Δ +${(simulatedSpi - 0.91).toStringAsFixed(2)})',
                      accentColor: simulatedSpi >= 1.00
                          ? AppTheme.tertiary
                          : AppTheme.secondary,
                    ),

                    // Tile 3: Crashing Cost
                    _buildSimulatorTile(
                      label: 'Workforce Crashing Cost',
                      mainValue: workers == 0
                          ? '₹0.00 Cr'
                          : '+₹${crashingCost.toStringAsFixed(2)} Cr',
                      badgeText: workers == 0 ? 'Zero Cost' : '₹3,200/day',
                      badgeColor: AppTheme.secondary,
                      icon: Icons.payments_outlined,
                      subtitle: workers == 0
                          ? 'No additional crashing funds'
                          : '75-day campaign across Sector 4',
                      accentColor: AppTheme.secondary,
                    ),

                    // Tile 4: FIDIC Cl. 8.7 LD Avoided / Net Benefit
                    _buildSimulatorTile(
                      label: 'Net Financial Savings (FIDIC)',
                      mainValue: netSavings >= 0
                          ? '+₹${netSavings.toStringAsFixed(2)} Cr'
                          : '-₹${netSavings.abs().toStringAsFixed(2)} Cr',
                      badgeText: ldAvoided > 0
                          ? 'Avoids ₹${ldAvoided.toStringAsFixed(1)}Cr LD'
                          : 'No Savings',
                      badgeColor: netSavings >= 0
                          ? AppTheme.tertiary
                          : Colors.redAccent,
                      icon: Icons.savings_outlined,
                      subtitle: 'FIDIC Cl. 8.7 Delay Penalties: ₹25L/day',
                      accentColor: netSavings >= 0
                          ? AppTheme.tertiary
                          : Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dynamic Contextual Engineering Narrative Callout
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        workers == 0
                            ? Icons.warning_amber_rounded
                            : (simulatedSpi >= 1.00
                                ? Icons.verified
                                : Icons.lightbulb_outline),
                        color: statusColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _getSimulatorNarrative(
                            workers: workers,
                            daysSaved: daysSaved,
                            simulatedSpi: simulatedSpi,
                            projectedDateStr:
                                DateFormat('dd MMM yyyy').format(projectedDate),
                            netSavings: netSavings,
                            ldAvoided: ldAvoided,
                          ),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Interactive Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.bolt, size: 16),
                        label: const Text('Commit Crashing to Primavera P6'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          _showCrashingCommitDialog(
                            context: context,
                            workers: workers,
                            daysSaved: daysSaved,
                            simulatedSpi: simulatedSpi,
                            projectedDateStr:
                                DateFormat('dd MMM yyyy').format(projectedDate),
                            crashingCost: crashingCost,
                            netSavings: netSavings,
                            ldAvoided: ldAvoided,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.restart_alt, size: 16),
                      label: const Text('Reset'),
                      onPressed: () {
                        setState(() {
                          _crashingWorkers = 0.0;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrashingPresetChip({
    required String label,
    required int workers,
  }) {
    final bool isSelected = _crashingWorkers.round() == workers;
    return InkWell(
      onTap: () {
        setState(() {
          _crashingWorkers = workers.toDouble();
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight.withAlpha(35)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatorTile({
    required String label,
    required String mainValue,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mainValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _getSimulatorNarrative({
    required int workers,
    required double daysSaved,
    required double simulatedSpi,
    required String projectedDateStr,
    required double netSavings,
    required double ldAvoided,
  }) {
    if (workers == 0) {
      return '⚠️ Unmitigated Baseline: Activity PIP-L5-024 (Pipe Racks & Welding) will delay project completion to 28 Dec 2026 (-18 days slip). Client FIDIC Cl. 8.7 Liquidated Damages will reach ₹4.50 Cr without resource crashing.';
    } else if (simulatedSpi >= 1.00) {
      return '🎯 Full Schedule Recovery Achieved: Mobilizing +$workers workers fully absorbs the critical path slippage! Projected completion shifts to $projectedDateStr with SPI recovering to ${simulatedSpi.toStringAsFixed(2)}. Net savings: ₹${netSavings.toStringAsFixed(2)} Cr (avoids ₹${ldAvoided.toStringAsFixed(2)} Cr in contractual penalties).';
    } else {
      return '⚡ Partial Slippage Mitigation: Deploying +$workers skilled workers recovers ${daysSaved.toStringAsFixed(1)} days on critical path piping spools. Completion moves from 28 Dec to $projectedDateStr (SPI: ${simulatedSpi.toStringAsFixed(2)}). Liquidated damages avoided: ₹${ldAvoided.toStringAsFixed(2)} Cr.';
    }
  }

  void _showCrashingCommitDialog({
    required BuildContext context,
    required int workers,
    required double daysSaved,
    required double simulatedSpi,
    required String projectedDateStr,
    required double crashingCost,
    required double netSavings,
    required double ldAvoided,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.bolt, color: AppTheme.primaryLight),
            SizedBox(width: 10),
            Text(
              'Commit Crashing Schedule',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
                'Primavera P6 CPM Schedule Engine will authorize workforce mobilization for Activity PIP-L5-024 (Piping & Welding):',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _buildCommitMetricRow('Skilled Workforce Deployed', '+$workers Workers'),
              _buildCommitMetricRow('Critical Path Days Saved', '${daysSaved.toStringAsFixed(1)} Days'),
              _buildCommitMetricRow('New Projected Completion', projectedDateStr),
              _buildCommitMetricRow('Target Schedule Index (SPI)', simulatedSpi.toStringAsFixed(2)),
              _buildCommitMetricRow('Crashing Budget Allocated', '₹${crashingCost.toStringAsFixed(2)} Cr'),
              _buildCommitMetricRow('Liquidated Damages Avoided', '₹${ldAvoided.toStringAsFixed(2)} Cr'),
              _buildCommitMetricRow('Net Financial ROI', '₹${netSavings.toStringAsFixed(2)} Cr'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  'Work authorization order ready to dispatch to Site Piping Supervisor Vikram Joshi and Subcontractor Lead.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
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
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Crashing plan (+$workers workers) committed to P6 schedule baseline.',
                  ),
                  backgroundColor: AppTheme.surfaceContainerHigh,
                ),
              );
            },
            child: const Text('Approve & Dispatch'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. AI Recommendation Card (Recovering Schedule Slippage)
  // ---------------------------------------------------------------------------
  Widget _buildAiRecoveryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B5CF6).withAlpha(120), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with AI Icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withAlpha(30),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: Color(0xFFA78BFA), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'AI Schedule Recovery Recommendation',
                      style: TextStyle(
                        color: Color(0xFFDDD6FE),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Gemini 1.5 Pro Engine',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bottleneck diagnosis
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.hub_outlined, color: AppTheme.secondary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Critical Bottleneck Diagnosed:',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Activity PIP-L5-024 (Pipe Lower-in & Downhill Welding) has accumulated -18.4 days variance, causing 76% of total project schedule slippage (-₹11.70 Cr SV). Total Float has eroded from 14 days to -4 days (Negative Float).',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Recovery Strategy: Crashing Critical Path Piping Spools
                const Text(
                  'Recommended Action: Crashing Critical Path Piping Spools',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),

                // 3 Action items
                _buildRecoveryStep(
                  stepNumber: '1',
                  title: 'Mobilize Secondary 6G Welding Gang (Gang C)',
                  description:
                      'Deploy 12 certified downhill pipe welders from Duliajan yard to Sector 4 to double daily welding meterage from 32m/day to 68m/day.',
                  cost: '₹0.75 Cr',
                ),
                const SizedBox(height: 8),
                _buildRecoveryStep(
                  stepNumber: '2',
                  title: 'Authorize 2.5h Extended Overtime for NDT Inspection',
                  description:
                      'Fast-track Radiographic Testing (RT) and Ultrasonic Testing crews to prevent pipeline trench backfill holdups behind Lower-in crews.',
                  cost: '₹0.38 Cr',
                ),
                const SizedBox(height: 8),
                _buildRecoveryStep(
                  stepNumber: '3',
                  title: 'Pre-fabricate Induction Bends Offsite at Hazira Yard',
                  description:
                      'Shift field cold bending of 48 spools to vendor automated induction bending to eliminate site bottleneck.',
                  cost: '₹0.72 Cr',
                ),
                const SizedBox(height: 14),

                // Cost-Benefit Tradeoff Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.tertiary.withAlpha(80)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_up, color: AppTheme.tertiary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ROI Impact: Crashing cost of ₹1.85 Cr prevents projected FIDIC Delay Liquidated Damages of ₹6.20 Cr (Net Savings: ₹4.35 Cr). Projected SPI recovery: 0.91 ➔ 0.98 by Nov 2026.',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.bolt, size: 16),
                        label: const Text('Execute Recovery Plan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          _showSimulationSuccess(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.description_outlined, size: 16),
                      label: const Text('FIDIC Cl. 8.4 Notice'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Generating Draft FIDIC Extension of Time (EOT) Notice...'),
                            backgroundColor: AppTheme.surfaceContainerHigh,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryStep({
    required String stepNumber,
    required String title,
    required String description,
    required String cost,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFF6D28D9),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
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
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    cost,
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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

  void _showSimulationSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.tertiary),
            SizedBox(width: 10),
            Text('Crashing Schedule Simulated'),
          ],
        ),
        content: const Text(
          'Primavera P6 schedule engine simulated crashing for 48 critical spools.\n\n'
          '• Critical Path Slippage: Reduced from 18.4 days to 4.2 days.\n'
          '• Total Float restored: +2 days.\n'
          '• Projected SPI for Q4: 0.98.\n'
          '• Work authorization order sent to Site Piping Supervisor Vikram Joshi.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: Monthly Trend Breakdown Table
  // ---------------------------------------------------------------------------
  Widget _buildMonthlyLedgerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly EVM Trend Ledger',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Incremental and cumulative performance audit trail across project lifecycle',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Scrollable Industrial Data Table
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppTheme.surfaceContainerHigh,
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      return states.contains(WidgetState.selected)
                          ? AppTheme.primaryLight.withAlpha(20)
                          : null;
                    },
                  ),
                  horizontalMargin: 16,
                  columnSpacing: 18,
                  headingTextStyle: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  columns: const [
                    DataColumn(label: Text('Month')),
                    DataColumn(label: Text('Cum PV\n(₹ Cr)', textAlign: TextAlign.right)),
                    DataColumn(label: Text('Cum EV\n(₹ Cr)', textAlign: TextAlign.right)),
                    DataColumn(label: Text('Cum AC\n(₹ Cr)', textAlign: TextAlign.right)),
                    DataColumn(label: Text('SV\n(₹ Cr)', textAlign: TextAlign.right)),
                    DataColumn(label: Text('CV\n(₹ Cr)', textAlign: TextAlign.right)),
                    DataColumn(label: Text('SPI', textAlign: TextAlign.center)),
                    DataColumn(label: Text('CPI', textAlign: TextAlign.center)),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: _monthlyData.map((rec) {
                    final sv = rec.cumEV - rec.cumPV;
                    final cv = rec.cumEV - rec.cumAC;
                    final isCur = rec.isCurrent;

                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>(
                        (states) => isCur
                            ? AppTheme.primary.withAlpha(25)
                            : (rec.isForecast ? Colors.purple.withAlpha(12) : null),
                      ),
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                rec.month,
                                style: TextStyle(
                                  color: isCur ? AppTheme.primaryLight : AppTheme.textPrimary,
                                  fontWeight: isCur ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                              if (isCur) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_right, color: AppTheme.primaryLight, size: 16),
                              ],
                            ],
                          ),
                        ),
                        DataCell(Text(
                          rec.cumPV.toStringAsFixed(2),
                          style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontFamily: 'monospace'),
                        )),
                        DataCell(Text(
                          rec.cumEV.toStringAsFixed(2),
                          style: const TextStyle(color: AppTheme.tertiary, fontSize: 12, fontFamily: 'monospace'),
                        )),
                        DataCell(Text(
                          rec.cumAC.toStringAsFixed(2),
                          style: const TextStyle(color: AppTheme.secondary, fontSize: 12, fontFamily: 'monospace'),
                        )),
                        DataCell(Text(
                          '${sv >= 0 ? '+' : ''}${sv.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: sv >= 0 ? AppTheme.tertiary : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        )),
                        DataCell(Text(
                          '${cv >= 0 ? '+' : ''}${cv.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: cv >= 0 ? AppTheme.tertiary : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        )),
                        DataCell(
                          Center(
                            child: Text(
                              rec.spi.toStringAsFixed(2),
                              style: TextStyle(
                                color: rec.spi >= 1.0 ? AppTheme.tertiary : AppTheme.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              rec.cpi.toStringAsFixed(2),
                              style: TextStyle(
                                color: rec.cpi >= 1.0 ? AppTheme.tertiary : AppTheme.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(_buildStatusBadge(rec.status)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Footnote / Cumulative Snapshot
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.textMuted, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cutoff Snapshot as of Sep 2026: Total Work Planned = ₹124.50 Cr | Earned = ₹112.80 Cr | Actual Cost = ₹118.20 Cr | Net Slippage = ₹11.70 Cr.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'AHEAD':
        bg = AppTheme.tertiary.withAlpha(30);
        fg = AppTheme.tertiary;
        break;
      case 'ON_TRACK':
        bg = AppTheme.primaryLight.withAlpha(30);
        fg = AppTheme.primaryLight;
        break;
      case 'WARNING':
        bg = AppTheme.secondary.withAlpha(30);
        fg = AppTheme.secondary;
        break;
      case 'DELAYED':
        bg = Colors.redAccent.withAlpha(30);
        fg = Colors.redAccent;
        break;
      case 'CRITICAL':
        bg = Colors.red.withAlpha(45);
        fg = Colors.redAccent;
        break;
      case 'CURRENT':
        bg = AppTheme.primary.withAlpha(60);
        fg = Colors.white;
        break;
      case 'FORECAST':
        bg = Colors.purpleAccent.withAlpha(30);
        fg = Colors.purpleAccent;
        break;
      default:
        bg = AppTheme.surfaceContainerHigh;
        fg = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: WBS Discipline Variance Breakdown
  // ---------------------------------------------------------------------------
  Widget _buildWbsVarianceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discipline & WBS Performance',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Granular EVM metrics mapped to Work Breakdown Structure packages',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ..._disciplineBreakdown.map((d) => _buildDisciplineCard(d)),
        ],
      ),
    );
  }

  Widget _buildDisciplineCard(DisciplineEvm discipline) {
    final sv = discipline.ev - discipline.pv;
    final cv = discipline.ev - discipline.ac;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: discipline.critical ? Colors.redAccent.withAlpha(120) : AppTheme.border,
          width: discipline.critical ? 1.5 : 1.0,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: discipline.critical
                          ? Colors.redAccent.withAlpha(30)
                          : AppTheme.primaryLight.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      discipline.critical ? Icons.warning : Icons.folder_open,
                      color: discipline.critical ? Colors.redAccent : AppTheme.primaryLight,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discipline.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        discipline.code,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (discipline.critical)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent.withAlpha(90)),
                  ),
                  child: const Text(
                    'CRITICAL PATH',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Values grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWbsMetric('PV', '₹${discipline.pv.toStringAsFixed(1)} Cr', AppTheme.primaryLight),
              _buildWbsMetric('EV', '₹${discipline.ev.toStringAsFixed(1)} Cr', AppTheme.tertiary),
              _buildWbsMetric('AC', '₹${discipline.ac.toStringAsFixed(1)} Cr', AppTheme.secondary),
              _buildWbsMetric(
                'SV',
                '${sv >= 0 ? '+' : ''}₹${sv.toStringAsFixed(1)} Cr',
                sv >= 0 ? AppTheme.tertiary : Colors.redAccent,
              ),
              _buildWbsMetric(
                'CV',
                '${cv >= 0 ? '+' : ''}₹${cv.toStringAsFixed(1)} Cr',
                cv >= 0 ? AppTheme.tertiary : Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mini progress bar comparison
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Schedule Index (SPI)', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        Text(
                          discipline.spi.toStringAsFixed(2),
                          style: TextStyle(
                            color: discipline.spi < 1.0 ? AppTheme.secondary : AppTheme.tertiary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (discipline.spi / 1.2).clamp(0.0, 1.0),
                        backgroundColor: AppTheme.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation(
                          discipline.spi < 0.90 ? Colors.redAccent : AppTheme.secondary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cost Index (CPI)', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        Text(
                          discipline.cpi.toStringAsFixed(2),
                          style: TextStyle(
                            color: discipline.cpi < 1.0 ? AppTheme.secondary : AppTheme.tertiary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (discipline.cpi / 1.2).clamp(0.0, 1.0),
                        backgroundColor: AppTheme.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation(
                          discipline.cpi < 1.0 ? AppTheme.secondary : AppTheme.tertiary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWbsMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // EVM Formula Glossary Dialog
  // ---------------------------------------------------------------------------
  void _showGlossaryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.functions, color: AppTheme.primaryLight),
            SizedBox(width: 10),
            Text(
              'EVM Formulas & Standards',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _FormulaRow(term: 'Planned Value (PV)', formula: '% Planned × BAC'),
              _FormulaRow(term: 'Earned Value (EV)', formula: '% Actual Complete × BAC'),
              _FormulaRow(term: 'Actual Cost (AC)', formula: 'Total Incurred Cost'),
              _FormulaRow(term: 'Schedule Variance (SV)', formula: 'EV - PV (<0 = Delayed)'),
              _FormulaRow(term: 'Cost Variance (CV)', formula: 'EV - AC (<0 = Overbudget)'),
              _FormulaRow(term: 'Schedule Perf. Index (SPI)', formula: 'EV / PV (<1.0 = Behind)'),
              _FormulaRow(term: 'Cost Perf. Index (CPI)', formula: 'EV / AC (<1.0 = Overrun)'),
              _FormulaRow(term: 'Estimate at Completion (EAC)', formula: 'BAC / CPI'),
              _FormulaRow(term: 'Estimate to Complete (ETC)', formula: 'EAC - AC'),
              _FormulaRow(term: 'Variance at Compl. (VAC)', formula: 'BAC - EAC'),
              _FormulaRow(term: 'TCPI (to BAC)', formula: '(BAC - EV) / (BAC - AC)'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class MilestoneFinancialRecord {
  final String title;
  final String wbsCode;
  final double plannedCost; // in ₹ Cr
  final double actualCost; // in ₹ Cr
  final double earnedValue; // in ₹ Cr
  final double progress; // 0.0 to 1.0
  final String targetDate;
  final String status;
  final String statusLabel;
  final String note;
  final IconData icon;

  const MilestoneFinancialRecord({
    required this.title,
    required this.wbsCode,
    required this.plannedCost,
    required this.actualCost,
    required this.earnedValue,
    required this.progress,
    required this.targetDate,
    required this.status,
    required this.statusLabel,
    required this.note,
    required this.icon,
  });

  double get costVariance => plannedCost - actualCost; // Budgeted vs Actual
  double get evmCostVariance => earnedValue - actualCost; // EVM CV = EV - AC
  double get variancePercent =>
      plannedCost > 0 ? ((actualCost - plannedCost) / plannedCost) * 100 : 0.0;
  bool get isOverBudget => actualCost > plannedCost;
  double get cpi => actualCost > 0 ? (earnedValue / actualCost) : 1.0;
}




// ---------------------------------------------------------------------------
// Helper Data Models & Glossary Row
// ---------------------------------------------------------------------------
class EvmMonthlyRecord {
  final String month;
  final double cumPV;
  final double cumEV;
  final double cumAC;
  final double incPV;
  final double incEV;
  final double incAC;
  final double spi;
  final double cpi;
  final String status;
  final bool isCurrent;
  final bool isForecast;

  const EvmMonthlyRecord({
    required this.month,
    required this.cumPV,
    required this.cumEV,
    required this.cumAC,
    required this.incPV,
    required this.incEV,
    required this.incAC,
    required this.spi,
    required this.cpi,
    required this.status,
    this.isCurrent = false,
    this.isForecast = false,
  });

  // EVM Mathematical Formulations:
  // SV = EV - PV
  double get sv => cumEV - cumPV;
  // CV = EV - AC
  double get cv => cumEV - cumAC;
  // SPI = EV / PV
  double get calculatedSpi => cumPV != 0 ? cumEV / cumPV : 1.0;
  // CPI = EV / AC
  double get calculatedCpi => cumAC != 0 ? cumEV / cumAC : 1.0;
  double get incSv => incEV - incPV;
  double get incCv => incEV - incAC;
}

class DisciplineEvm {
  final String name;
  final String code;
  final double pv;
  final double ev;
  final double ac;
  final double spi;
  final double cpi;
  final bool critical;

  const DisciplineEvm({
    required this.name,
    required this.code,
    required this.pv,
    required this.ev,
    required this.ac,
    required this.spi,
    required this.cpi,
    required this.critical,
  });

  // EVM Mathematical Formulations:
  // SV = EV - PV
  double get sv => ev - pv;
  // CV = EV - AC
  double get cv => ev - ac;
  // SPI = EV / PV
  double get calculatedSpi => pv != 0 ? ev / pv : 1.0;
  // CPI = EV / AC
  double get calculatedCpi => ac != 0 ? ev / ac : 1.0;
}

class _FormulaRow extends StatelessWidget {
  final String term;
  final String formula;

  const _FormulaRow({required this.term, required this.formula});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              term,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              formula,
              style: const TextStyle(
                color: AppTheme.primaryLight,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
