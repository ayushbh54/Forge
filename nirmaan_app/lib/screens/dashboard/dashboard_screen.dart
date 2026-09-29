import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nirmaan_app/providers/app_provider.dart';
import 'package:nirmaan_app/core/models/app_models.dart';
import 'package:nirmaan_app/screens/dashboard/create_project_screen.dart';
import 'package:nirmaan_app/widgets/status_badge.dart';
import 'package:nirmaan_app/widgets/metric_card.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:nirmaan_app/screens/ai/risk_radar_screen.dart';
import 'package:nirmaan_app/screens/ai/gemini_brain_screen.dart';
import 'package:nirmaan_app/screens/ai/institutional_memory_screen.dart';
import 'package:nirmaan_app/screens/dpr/dpr_screen.dart';
import 'package:nirmaan_app/screens/workforce/clock_in_screen.dart';
import 'package:nirmaan_app/screens/schedule/import_schedule_screen.dart';
import 'package:nirmaan_app/screens/conflicts/conflicts_screen.dart';
import 'package:nirmaan_app/screens/audit/audit_screen.dart';
import 'package:nirmaan_app/screens/reports/executive_report_screen.dart';
import 'package:nirmaan_app/screens/settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326), // Background
      appBar: AppBar(
        title: const Text('Nirmaan OS', style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF111C38),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Audit Log & Notifications',
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFFF1F5F9)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditScreen()));
            },
          ),
          IconButton(
            tooltip: 'App Settings & Profile',
            icon: const Icon(Icons.person_outline, color: Color(0xFFF1F5F9)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          )
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.projects.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
          }

          if (provider.projects.isEmpty) {
            return _buildEmptyState(context);
          }

          final currentProject = provider.currentProject ?? provider.projects.first;

          return RefreshIndicator(
            onRefresh: () => provider.loadInitialData(),
            color: const Color(0xFF0284C7),
            backgroundColor: const Color(0xFF162347),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProjectSelector(provider),
                  const SizedBox(height: 24),
                  _buildProjectOverviewCard(currentProject),
                  const SizedBox(height: 24),
                  const Text('Key Metrics', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildKeyMetricsGrid(currentProject),
                  const SizedBox(height: 24),
                  const Text('Quick Actions', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildQuickActionsRow(context),
                  const SizedBox(height: 24),
                  const Text('Recent Activity', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildRecentActivityList(provider.auditLogs),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.business, size: 80, color: Color(0x8094A3B8)),
          const SizedBox(height: 24),
          const Text(
            'No Projects Found',
            style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first project to get started.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Create Project', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProjectScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSelector(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: provider.projects.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == provider.projects.length) {
                return ActionChip(
                  label: const Text('New Project', style: TextStyle(color: Color(0xFFF1F5F9))),
                  avatar: const Icon(Icons.add, size: 16, color: Color(0xFFF1F5F9)),
                  backgroundColor: const Color(0xFF162347),
                  side: const BorderSide(color: Color(0xFF26396E)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProjectScreen()));
                  },
                );
              }
              final project = provider.projects[index];
              final isSelected = provider.currentProject?.id == project.id || (provider.currentProject == null && index == 0);
              return ChoiceChip(
                label: Text(project.code, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8))),
                selected: isSelected,
                selectedColor: const Color(0xFF0284C7),
                backgroundColor: const Color(0xFF111C38),
                side: BorderSide(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF26396E)),
                onSelected: (selected) {
                  if (selected) provider.setCurrentProject(project.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProjectOverviewCard(ProjectModel project) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF26396E)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${project.code} • ${project.client}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          project.location,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusBadge(status: project.status), // Assuming project.status exists
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGauge('SPI', project.spi),
              _buildGauge('CPI', project.cpi),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Evidence Coverage', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  Text('78%', style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 12, fontWeight: FontWeight.bold)), // Hardcoded for demo
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.78,
                backgroundColor: const Color(0xFF111C38),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4EDEA3)),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGauge(String label, double value) {
    Color gaugeColor = value >= 1.0 ? const Color(0xFF4EDEA3) : (value >= 0.85 ? const Color(0xFFFFB95F) : Colors.red);
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 40.0,
          lineWidth: 8.0,
          percent: value > 1.5 ? 1.0 : value / 1.5,
          center: Text(
            value.toStringAsFixed(2),
            style: const TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 16),
          ),
          progressColor: gaugeColor,
          backgroundColor: const Color(0xFF111C38),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      ],
    );
  }

  Widget _buildKeyMetricsGrid(ProjectModel project) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        MetricCard(
          title: 'Budget',
          value: '₹${(project.totalBudget / 10000000).toStringAsFixed(2)} Cr',
          subtitle: 'Spent: ₹${(project.spentBudget / 10000000).toStringAsFixed(2)} Cr',
          icon: Icons.account_balance_wallet,
          iconColor: const Color(0xFF0284C7),
          trend: '-2.1%',
        ),
        MetricCard(
          title: 'Schedule',
          value: DateFormat('MMM yy').format(project.originalFinishDate),
          subtitle: 'Delay: 0 Months',
          icon: Icons.calendar_today,
          iconColor: const Color(0xFF38BDF8),
        ),
        const MetricCard(
          title: 'Workforce',
          value: '450',
          subtitle: 'Verified: 425 (94%)',
          icon: Icons.people,
          iconColor: Color(0xFFFFB95F),
          trend: '+5%',
        ),
        const MetricCard(
          title: 'Activities',
          value: '1,245',
          subtitle: 'Critical Path: 45',
          icon: Icons.account_tree,
          iconColor: Color(0xFF4EDEA3),
          trend: 'Avg 42%',
        ),
      ],
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    final actions = [
      {'label': 'Executive Report', 'icon': Icons.picture_as_pdf, 'action': 'executive_report'},
      {'label': 'Risk Radar', 'icon': Icons.radar, 'action': 'risk_radar'},
      {'label': 'AI Brain', 'icon': Icons.psychology, 'action': 'ai_brain'},
      {'label': 'Institutional Memory', 'icon': Icons.history_edu, 'action': 'institutional_memory'},
      {'label': 'Submit DPR', 'icon': Icons.assignment, 'action': 'dpr'},
      {'label': 'Clock-In', 'icon': Icons.access_time, 'action': 'clock_in'},
      {'label': 'Import Schedule', 'icon': Icons.upload_file, 'action': 'import'},
      {'label': 'View Conflicts', 'icon': Icons.warning_amber, 'action': 'conflicts'},
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final action = actions[index];
          return ActionChip(
            label: Text(action['label'] as String, style: const TextStyle(color: Color(0xFFF1F5F9))),
            avatar: Icon(action['icon'] as IconData, size: 18, color: const Color(0xFF38BDF8)),
            backgroundColor: const Color(0xFF162347),
            side: const BorderSide(color: Color(0xFF26396E)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: () {
              final act = action['action'];
              if (act == 'executive_report') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ExecutiveReportScreen()));
              } else if (act == 'risk_radar') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RiskRadarScreen()));
              } else if (act == 'ai_brain') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GeminiBrainScreen()));
              } else if (act == 'institutional_memory') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InstitutionalMemoryScreen()));
              } else if (act == 'dpr') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DprScreen()));
              } else if (act == 'clock_in') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ClockInScreen()));
              } else if (act == 'import') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScheduleScreen()));
              } else if (act == 'conflicts') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ConflictsScreen()));
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildRecentActivityList(List<dynamic> logs) {
    if (logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No recent activity', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }
    
    final displayLogs = logs.take(5).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayLogs.length,
        separatorBuilder: (context, index) => const Divider(color: Color(0xFF26396E), height: 1),
        itemBuilder: (context, index) {
          final log = displayLogs[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF111C38),
              child: Icon(_getIconForAction(log['action'] ?? ''), size: 18, color: const Color(0xFF0284C7)),
            ),
            title: Text(log['action']?.toString() ?? 'Activity Log', style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 14)),
            subtitle: Text(
              '${log['actor_name'] ?? log['actor'] ?? 'System'} • ${log['timestamp'] != null ? DateFormat('MMM d, h:mm a').format(DateTime.tryParse(log['timestamp'].toString()) ?? DateTime.now()) : (log['time'] ?? 'Recent')}', 
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForAction(String action) {
    if (action.toLowerCase().contains('upload') || action.toLowerCase().contains('import')) return Icons.upload_file;
    if (action.toLowerCase().contains('dpr')) return Icons.assignment;
    if (action.toLowerCase().contains('update')) return Icons.edit;
    if (action.toLowerCase().contains('resolve')) return Icons.check_circle_outline;
    return Icons.info_outline;
  }
}
