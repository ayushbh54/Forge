import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import 'activity_detail_screen.dart';
import 'import_schedule_screen.dart';
import 'wbs_gantt_screen.dart';
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _selectedDiscipline = 'ALL';
  final List<String> _disciplines = ['ALL', 'CIVIL', 'PIPING', 'ELECTRICAL', 'INSTRUMENTATION', 'MECHANICAL', 'HSE'];
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activities = provider.activities.where((a) {
      if (_selectedDiscipline != 'ALL' && a.discipline.toUpperCase() != _selectedDiscipline) return false;
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        return a.name.toLowerCase().contains(query) || a.code.toLowerCase().contains(query);
      }
      return true;
    }).toList();
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Schedule & Activity Tracker', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_rounded, color: AppTheme.primaryLight),
            tooltip: 'WBS Gantt Cascade (L1-L6)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WbsGanttScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ImportScheduleScreen()),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.file_upload, color: Colors.white),
        label: const Text('Import P6', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: activities.isEmpty 
              ? const Center(child: Text('No activities found', style: TextStyle(color: AppTheme.textPrimary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    return _buildActivityCard(activities[index]);
                  },
                ),
          ),
          _buildBottomStats(provider.activities),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WbsGanttScreen()),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryLight.withAlpha(90)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.account_tree_rounded, size: 18, color: AppTheme.primaryLight),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'WBS L1–L6 Interactive Gantt & Timeline Cascade',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primaryLight),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search activities...',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surfaceCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDiscipline,
                    dropdownColor: AppTheme.surfaceCard,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textPrimary),
                    items: _disciplines.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedDiscipline = newValue!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    final isBreached = activity.isVarianceToleranceBreached;

    return Card(
      color: AppTheme.surfaceCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isBreached ? Colors.redAccent.withAlpha(140) : AppTheme.border,
          width: isBreached ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ActivityDetailScreen(activityId: activity.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${activity.code} - ${activity.name}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isBreached) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(35),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.redAccent.withAlpha(120)),
                      ),
                      child: Text(
                        'VARIANCE ALERT (+${activity.varianceDelta.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (activity.isCriticalPath)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildDisciplineBadge(activity.discipline),
                  const Spacer(),
                  Text('Duration: ${activity.durationDays}d', style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(width: 8),
                  Text('Float: ${activity.totalFloatDays}d', style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Start: ${DateFormat('dd MMM yyyy').format(activity.plannedStart)}", style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                  Text("Finish: ${DateFormat('dd MMM yyyy').format(activity.plannedFinish)}", style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),

              // 5-Factor Progress Triangulation Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '5-Factor Progress Triangulation',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isBreached
                          ? Colors.redAccent.withAlpha(30)
                          : AppTheme.tertiary.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isBreached
                            ? Colors.redAccent.withAlpha(100)
                            : AppTheme.tertiary.withAlpha(100),
                      ),
                    ),
                    child: Text(
                      isBreached
                          ? 'Tolerance Breached (>±5.0%)'
                          : 'Within ±5.0% Limit',
                      style: TextStyle(
                        color: isBreached ? Colors.redAccent : AppTheme.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Factor 1: Planned Schedule Baseline
              _buildProgressBar('1. Planned Baseline', activity.plannedProgress, AppTheme.primaryLight),
              // Factor 2: Contractor Field Claim (highlighted in red if tolerance breached)
              _buildProgressBar(
                '2. Contractor Claim',
                activity.contractorReportedProgress,
                isBreached ? Colors.redAccent : Colors.blue,
                suffix: isBreached ? ' (+${activity.varianceDelta.toStringAsFixed(1)}% vs Consensus)' : null,
                isWarning: isBreached,
              ),
              // Factor 3: Quantity Surveyor Verified
              _buildProgressBar('3. QS Verified', activity.quantitySurveyProgress, Colors.orange),
              // Factor 4: QA/QC Lab Passed Inspection
              _buildProgressBar('4. QC Passed', activity.qcPassedProgress, Colors.yellow),
              // Factor 5: Drone LiDAR Volumetric Scan
              _buildProgressBar('5. Drone/LiDAR', activity.droneLidarProgress, Colors.purple),
              const SizedBox(height: 4),
              const Divider(color: AppTheme.border, height: 16),
              // Validated Consensus Truth
              _buildProgressBar(
                'Validated Consensus',
                activity.effectiveConsensus,
                AppTheme.tertiary,
                isHighlighted: true,
              ),

              // Variance Alert Callout when variance exceeds 5%
              if (isBreached)
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent.withAlpha(90)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Contractor claim (${activity.contractorReportedProgress.toStringAsFixed(1)}%) deviates from consensus truth (${activity.effectiveConsensus.toStringAsFixed(1)}%) by +${activity.varianceDelta.toStringAsFixed(1)}%, exceeding the ±5.0% contract tolerance limit under FIDIC Cl. 14.3.',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Qty: ${activity.installedQuantity} / ${activity.plannedQuantity} ${activity.unit}', style: const TextStyle(color: AppTheme.textSecondary)),
                  Text('Supervisor: ${activity.supervisor}', style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisciplineBadge(String discipline) {
    Color color;
    switch (discipline.toUpperCase()) {
      case 'CIVIL': color = Colors.blue; break;
      case 'PIPING': color = Colors.orange; break;
      case 'ELECTRICAL': color = Colors.yellow; break;
      case 'INSTRUMENTATION': color = Colors.purple; break;
      case 'MECHANICAL': color = Colors.red; break;
      default: color = Colors.grey; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(51), // 0.2 * 255 = 51
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(127)), // 0.5 * 255 = 127
      ),
      child: Text(
        discipline.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProgressBar(
    String label,
    double value,
    Color color, {
    bool isHighlighted = false,
    String? suffix,
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: TextStyle(
                color: isHighlighted
                    ? color
                    : (isWarning ? Colors.redAccent : AppTheme.textSecondary),
                fontWeight: isHighlighted || isWarning ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.background,
              color: color,
              minHeight: isHighlighted ? 8 : 5,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${value.toStringAsFixed(1)}%${suffix ?? ''}',
            style: TextStyle(
              color: isHighlighted
                  ? color
                  : (isWarning ? Colors.redAccent : AppTheme.textPrimary),
              fontWeight: isHighlighted || isWarning ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStats(List<ActivityModel> activities) {
    int total = activities.length;
    int critical = activities.where((a) => a.isCriticalPath).length;
    int varianceBreaches = activities.where((a) => a.isVarianceToleranceBreached).length;
    double avgProgress = total > 0
        ? activities.fold(0.0, (sum, item) => sum + item.effectiveConsensus) / total
        : 0.0;
    int overdue = activities
        .where((a) => a.plannedFinish.isBefore(DateTime.now()) && a.effectiveConsensus < 100)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Total', value: '$total'),
          _StatItem(label: 'Critical', value: '$critical', valueColor: Colors.redAccent),
          _StatItem(label: 'Avg Truth', value: '${avgProgress.toStringAsFixed(1)}%'),
          _StatItem(
            label: 'Variance >5%',
            value: '$varianceBreaches',
            valueColor: varianceBreaches > 0 ? Colors.redAccent : AppTheme.tertiary,
          ),
          _StatItem(label: 'Overdue', value: '$overdue', valueColor: Colors.orange),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: valueColor ?? AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}
