import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ContractorRecord {
  final String id;
  final String name;
  final String discipline;
  final double rating;
  final double spi;
  final double safetyScore;
  final int activeWorkers;
  final double plannedProductivity;
  final double actualProductivity;
  final String unit;
  final double qcPassRate;
  final int zeroLtiDays;
  final double liquidatedDamagesRisk;
  final String status;

  const ContractorRecord({
    required this.id,
    required this.name,
    required this.discipline,
    required this.rating,
    required this.spi,
    required this.safetyScore,
    required this.activeWorkers,
    required this.plannedProductivity,
    required this.actualProductivity,
    required this.unit,
    required this.qcPassRate,
    required this.zeroLtiDays,
    required this.liquidatedDamagesRisk,
    required this.status,
  });
}

class ContractorScorecardScreen extends StatefulWidget {
  const ContractorScorecardScreen({super.key});

  @override
  State<ContractorScorecardScreen> createState() => _ContractorScorecardScreenState();
}

class _ContractorScorecardScreenState extends State<ContractorScorecardScreen> {
  String _selectedDiscipline = 'ALL';

  final List<ContractorRecord> _contractors = const [
    ContractorRecord(
      id: 'CONT-LT-01',
      name: 'L&T Hydrocarbon Engineering',
      discipline: 'PIPING',
      rating: 4.8,
      spi: 0.98,
      safetyScore: 99.2,
      activeWorkers: 280,
      plannedProductivity: 85.0,
      actualProductivity: 83.5,
      unit: 'm/day',
      qcPassRate: 98.4,
      zeroLtiDays: 412,
      liquidatedDamagesRisk: 0.0,
      status: 'TOP PERFORMER',
    ),
    ContractorRecord(
      id: 'CONT-PL-02',
      name: 'Punj Lloyd Piping JV',
      discipline: 'PIPING',
      rating: 3.7,
      spi: 0.82,
      safetyScore: 91.5,
      activeWorkers: 140,
      plannedProductivity: 65.0,
      actualProductivity: 48.0,
      unit: 'm/day',
      qcPassRate: 91.0,
      zeroLtiDays: 180,
      liquidatedDamagesRisk: 1.45,
      status: 'AT RISK',
    ),
    ContractorRecord(
      id: 'CONT-BR-03',
      name: 'Bridge & Roof Civil Gang',
      discipline: 'CIVIL',
      rating: 4.3,
      spi: 0.94,
      safetyScore: 96.0,
      activeWorkers: 95,
      plannedProductivity: 120.0,
      actualProductivity: 114.0,
      unit: 'm3/day',
      qcPassRate: 96.5,
      zeroLtiDays: 290,
      liquidatedDamagesRisk: 0.20,
      status: 'ON TRACK',
    ),
    ContractorRecord(
      id: 'CONT-KZ-04',
      name: 'KazStroy Pipeline Services',
      discipline: 'MECHANICAL',
      rating: 4.1,
      spi: 0.91,
      safetyScore: 94.8,
      activeWorkers: 75,
      plannedProductivity: 45.0,
      actualProductivity: 41.5,
      unit: 'joints/day',
      qcPassRate: 94.0,
      zeroLtiDays: 245,
      liquidatedDamagesRisk: 0.55,
      status: 'ON TRACK',
    ),
  ];

  List<ContractorRecord> get _filteredContractors {
    if (_selectedDiscipline == 'ALL') return _contractors;
    return _contractors.where((c) => c.discipline == _selectedDiscipline).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Contractor Performance Scorecard',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded, color: Color(0xFF38BDF8)),
            tooltip: 'Compare Contractors',
            onPressed: () => _showComparisonModal(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Executive Summary Banner
          Container(
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
                    Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB95F), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Live Contractor League & CPM Adherence',
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Continuous evaluation based on Primavera P6 progress, ASNT/API 1104 weld acceptance rates, and FIDIC Cl. 8.7 Delay Liquidated Damages exposure.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatPill('Total Contractors', '4 Active', Colors.blue),
                    _buildStatPill('Total Workforce', '590 Men', Colors.cyan),
                    _buildStatPill('Avg SPI', '0.91', Colors.amber),
                    _buildStatPill('Safety Score', '95.4%', const Color(0xFF4EDEA3)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Liquidated Damages Assessment Card
          _buildLiquidatedDamagesCard(),
          const SizedBox(height: 16),

          // Discipline Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['ALL', 'PIPING', 'CIVIL', 'MECHANICAL'].map((disc) {
                final isSelected = _selectedDiscipline == disc;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(disc),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedDiscipline = disc);
                    },
                    selectedColor: const Color(0xFF0284C7),
                    backgroundColor: AppTheme.surfaceCard,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0284C7) : AppTheme.border,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Contractor Cards List
          ..._filteredContractors.map((c) => _buildContractorCard(c)),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildLiquidatedDamagesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.gavel_rounded, color: Colors.redAccent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'FIDIC Cl. 8.7 Delay Liquidated Damages Exposure',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Punj Lloyd Piping JV is trailing critical path schedule by 18 calendar days on Spread 2. Potential LD exposure under Clause 8.7 is ₹1.45 Cr (0.1% per day of delayed section contract value, capped at 10%).',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Assessed LD Risk: ₹1.45 Cr',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Issued Clause 8.6 Rate of Progress Notice to Punj Lloyd JV'),
                      backgroundColor: Colors.amber,
                    ),
                  );
                },
                child: const Text('Issue Cl. 8.6 Notice', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContractorCard(ContractorRecord c) {
    Color statusColor;
    if (c.status == 'TOP PERFORMER') {
      statusColor = const Color(0xFF4EDEA3);
    } else if (c.status == 'AT RISK') {
      statusColor = Colors.redAccent;
    } else {
      statusColor = const Color(0xFF38BDF8);
    }

    final prodPercentage = (c.actualProductivity / c.plannedProductivity * 100).clamp(0, 150).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: c.status == 'AT RISK' ? Colors.redAccent.withAlpha(120) : AppTheme.border,
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
                      c.name,
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.discipline} • ID: ${c.id}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  c.status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // KPI Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricColumn('Rating', '${c.rating} ★', Colors.amber),
              _buildMetricColumn('SPI', c.spi.toStringAsFixed(2), c.spi >= 0.95 ? const Color(0xFF4EDEA3) : (c.spi >= 0.85 ? Colors.amber : Colors.redAccent)),
              _buildMetricColumn('Safety', '${c.safetyScore}%', const Color(0xFF4EDEA3)),
              _buildMetricColumn('QA Pass', '${c.qcPassRate}%', Colors.cyan),
              _buildMetricColumn('Workforce', '${c.activeWorkers}', AppTheme.textPrimary),
            ],
          ),
          const SizedBox(height: 14),

          // Productivity Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Productivity: ${c.actualProductivity} / ${c.plannedProductivity} ${c.unit}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                '${prodPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: prodPercentage >= 100 ? const Color(0xFF4EDEA3) : (prodPercentage >= 85 ? Colors.amber : Colors.redAccent),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (prodPercentage / 100).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF0B1326),
              valueColor: AlwaysStoppedAnimation<Color>(
                prodPercentage >= 95 ? const Color(0xFF4EDEA3) : (prodPercentage >= 80 ? Colors.amber : Colors.redAccent),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Institutional Memory Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1326),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_edu_rounded, color: Color(0xFF38BDF8), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zero LTI: ${c.zeroLtiDays} days • Future tender qualification weighting score: ${(c.rating * 20).toInt()}%',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  void _showComparisonModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.compare_rounded, color: Color(0xFF38BDF8)),
                  SizedBox(width: 10),
                  Text(
                    'Contractor Benchmark Matrix',
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Table(
                border: TableBorder.all(color: AppTheme.border, width: 0.5),
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Color(0xFF162347)),
                    children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('Contractor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('SPI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Safety', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('QA Pass', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                  ..._contractors.map((c) => TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text(c.name.split(' ').first, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(c.spi.toStringAsFixed(2), style: TextStyle(color: c.spi >= 0.9 ? const Color(0xFF4EDEA3) : Colors.redAccent, fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('${c.safetyScore}%', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('${c.qcPassRate}%', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                        ],
                      )),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Color(0xFF38BDF8))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
