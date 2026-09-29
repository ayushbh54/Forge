import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../schedule/activity_detail_screen.dart';

class DprHistoryScreen extends StatefulWidget {
  const DprHistoryScreen({super.key});

  @override
  State<DprHistoryScreen> createState() => _DprHistoryScreenState();
}

class _DprHistoryScreenState extends State<DprHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activities = provider.activities.where((a) => a.contractorReportedProgress > 0).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('DPR History', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Filter by activity, date...',
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
                IconButton(
                  icon: const Icon(Icons.filter_list, color: AppTheme.textPrimary),
                  onPressed: () {},
                )
              ],
            ),
          ),
          Expanded(
            child: activities.isEmpty 
              ? const Center(child: Text('No DPR history found', style: TextStyle(color: AppTheme.textPrimary)))
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                if (_searchController.text.isNotEmpty && !activity.name.toLowerCase().contains(_searchController.text.toLowerCase()) && !activity.code.toLowerCase().contains(_searchController.text.toLowerCase())) {
                  return const SizedBox.shrink();
                }
                return _buildHistoryCard(activity);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ActivityModel activity) {
    bool hasDelay = activity.varianceDelta < 0; // Simple simulation for UI
    
    return Card(
      color: AppTheme.surfaceCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: ExpansionTile(
        title: Text(
          '${activity.code} - ${activity.name}',
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Progress: ${activity.contractorReportedProgress}% | Qty: ${activity.installedQuantity} ${activity.unit}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            if (hasDelay)
              const Text('Status: Delayed/Variance', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))
            else
              const Text('Status: On Track', style: TextStyle(color: AppTheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: const Text('Recent', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textPrimary)),
        iconColor: AppTheme.primary,
        collapsedIconColor: AppTheme.textSecondary,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: AppTheme.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notes:', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  hasDelay ? 'Variance detected compared to QS/Drone.' : 'Work progressing as planned.',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.image, color: AppTheme.textSecondary, size: 16),
                    const SizedBox(width: 4),
                    const Text('0 Attachments', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActivityDetailScreen(activityId: activity.id),
                          ),
                        );
                      },
                      child: const Text('View details', style: TextStyle(color: AppTheme.primary)),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
