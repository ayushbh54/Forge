import 'package:flutter/material.dart';

class HrModuleScreen extends StatelessWidget {
  const HrModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        title: const Text('HR Dashboard', style: TextStyle(color: Color(0xFFF1F5F9))),
        backgroundColor: const Color(0xFF111C38),
        iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWorkforceStats(),
            const SizedBox(height: 16),
            _buildSafetyCompliance(),
            const SizedBox(height: 16),
            _buildAttendanceTrends(),
            const SizedBox(height: 16),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkforceStats() {
    return Card(
      color: const Color(0xFF162347),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Workforce Overview', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Welders', '45', Colors.orange),
                _buildStatItem('Fitters', '60', Colors.blue),
                _buildStatItem('Riggers', '25', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      ],
    );
  }

  Widget _buildSafetyCompliance() {
    return Card(
      color: const Color(0xFF162347),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Safety Compliance', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0x1AFF5252), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('12 Workers with expired certificates', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTrends() {
    return Card(
      color: const Color(0xFF162347),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance Trends (Weekly)', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF111C38),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Bar Chart Placeholder', style: TextStyle(color: Color(0xFF94A3B8))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionChip(context, 'Add Worker', Icons.person_add, '/add_worker'),
            _buildActionChip(context, 'Bulk Clock-In', Icons.access_time, '/clock_in'),
            _buildActionChip(context, 'Export Report', Icons.download, null, onFallbackTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exporting HR & Attendance Compliance Dossier (CSV/PDF)...'),
                  backgroundColor: Color(0xFF162347),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon, String? route, {VoidCallback? onFallbackTap}) {
    return ActionChip(
      backgroundColor: const Color(0xFF111C38),
      avatar: Icon(icon, color: const Color(0xFF0284C7), size: 16),
      label: Text(label, style: const TextStyle(color: Color(0xFFF1F5F9))),
      side: const BorderSide(color: Color(0xFF26396E)),
      onPressed: () {
        if (route != null) {
          Navigator.pushNamed(context, route);
        } else if (onFallbackTap != null) {
          onFallbackTap();
        }
      },
    );
  }
}
