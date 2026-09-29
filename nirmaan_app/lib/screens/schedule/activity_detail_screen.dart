import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../dpr/dpr_screen.dart';

class ActivityDetailScreen extends StatelessWidget {
  final String activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activity = provider.activities.firstWhere(
      (a) => a.id == activityId,
      orElse: () => ActivityModel(
        id: activityId,
        code: 'N/A',
        uwid: 'N/A',
        wbsCode: 'N/A',
        name: 'Unknown Activity',
        discipline: 'N/A',
        plannedStart: DateTime.now(),
        plannedFinish: DateTime.now(),
        durationDays: 0,
        totalFloatDays: 0,
        isCriticalPath: false,
        plannedProgress: 0,
        contractorReportedProgress: 0,
        quantitySurveyProgress: 0,
        qcPassedProgress: 0,
        droneLidarProgress: 0,
        validatedConsensusProgress: 0,
        plannedQuantity: 0,
        installedQuantity: 0,
        unit: '',
        supervisor: 'N/A',
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text('Activity: ${activity.code}', style: const TextStyle(color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(activity),
            const SizedBox(height: 16),
            _buildProgressChart(activity),
            const SizedBox(height: 16),
            _buildDependencies(),
            const SizedBox(height: 16),
            _buildChecklist(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DprScreen(initialActivity: activity.id)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Submit DPR for this Activity', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ActivityModel activity) {
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
          Text(activity.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _infoRow('Status', activity.validatedConsensusProgress == 100 ? 'Completed' : (activity.validatedConsensusProgress > 0 ? 'In Progress' : 'Not Started'), activity.validatedConsensusProgress == 100 ? AppTheme.tertiary : Colors.orange),
          const SizedBox(height: 8),
          _infoRow('Planned Start', DateFormat('dd MMM yyyy').format(activity.plannedStart), AppTheme.textSecondary),
          const SizedBox(height: 8),
          _infoRow('Planned Finish', DateFormat('dd MMM yyyy').format(activity.plannedFinish), AppTheme.textSecondary),
          const SizedBox(height: 8),
          _infoRow('Assigned To', activity.supervisor, AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProgressChart(ActivityModel activity) {
    final isBreached = activity.isVarianceToleranceBreached;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBreached ? Colors.redAccent.withAlpha(120) : AppTheme.border,
          width: isBreached ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '5-Factor Progress Triangulation Chart',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      ? 'Tolerance Exceeded (+${activity.varianceDelta.toStringAsFixed(1)}% > ±5.0%)'
                      : 'Within ±5.0% Tolerance',
                  style: TextStyle(
                    color: isBreached ? Colors.redAccent : AppTheme.tertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Factor 1: Planned Baseline
          _buildChartBar('1. Planned Baseline', activity.plannedProgress, AppTheme.primaryLight),
          // Factor 2: Contractor Claim (highlighted in red if tolerance breached)
          _buildChartBar(
            '2. Contractor Claim',
            activity.contractorReportedProgress,
            isBreached ? Colors.redAccent : Colors.blue,
            suffix: isBreached ? ' (+${activity.varianceDelta.toStringAsFixed(1)}%)' : null,
            isWarning: isBreached,
          ),
          // Factor 3: QS Verified
          _buildChartBar('3. QS Verified', activity.quantitySurveyProgress, Colors.orange),
          // Factor 4: QC Passed
          _buildChartBar('4. QC Passed', activity.qcPassedProgress, Colors.yellow),
          // Factor 5: Drone/LiDAR
          _buildChartBar('5. Drone/LiDAR', activity.droneLidarProgress, Colors.purple),
          const Divider(color: AppTheme.border, height: 24),
          // Validated Consensus
          _buildChartBar(
            'Validated Consensus',
            activity.effectiveConsensus,
            AppTheme.tertiary,
            isHighlighted: true,
          ),

          if (isBreached) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'FIDIC Cl. 14.3 Variance Alert: Contractor claim (${activity.contractorReportedProgress.toStringAsFixed(1)}%) exceeds consensus truth (${activity.effectiveConsensus.toStringAsFixed(1)}%) by +${activity.varianceDelta.toStringAsFixed(1)}%, exceeding the contractual ±5.0% tolerance limit. Joint measurement review required.',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11),
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

  Widget _buildChartBar(
    String label,
    double value,
    Color color, {
    bool isHighlighted = false,
    String? suffix,
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
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
            child: Stack(
              children: [
                Container(
                  height: isHighlighted ? 12 : 8,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (value / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: isHighlighted ? 12 : 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
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
          ),
        ],
      ),
    );
  }

  Widget _buildDependencies() {
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
          const Text('Dependencies', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Predecessors', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.arrow_forward_rounded, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text('ACT-099 Excavation', style: TextStyle(color: Colors.green.shade300)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Successors', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.arrow_forward_rounded, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Text('ACT-101 Column Erection', style: TextStyle(color: Colors.orange.shade300)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist() {
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
          const Text('Activity Steps', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _checklistItem('Rebar inspection', true),
          _checklistItem('Formwork approval', true),
          _checklistItem('Concrete pouring', false),
          _checklistItem('Curing', false),
        ],
      ),
    );
  }

  Widget _checklistItem(String title, bool isCompleted) {
    return Row(
      children: [
        Checkbox(
          value: isCompleted,
          onChanged: (val) {},
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.primary;
            }
            return AppTheme.background;
          }),
        ),
        Text(
          title,
          style: TextStyle(
            color: isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}
