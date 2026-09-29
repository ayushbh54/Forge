import 'package:flutter/material.dart';

class WorkforceScreen extends StatefulWidget {
  const WorkforceScreen({super.key});

  @override
  State<WorkforceScreen> createState() => _WorkforceScreenState();
}

class _WorkforceScreenState extends State<WorkforceScreen> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _workers = [
    {
      'name': 'Ramesh Kumar',
      'id': '#W-1000',
      'trade': 'WELDER',
      'color': Colors.orange,
      'skills': ['TIG', 'MIG'],
      'contractor': 'L&T Eng Gang A',
      'present': true,
      'certExpired': false,
    },
    {
      'name': 'Suresh Patel',
      'id': '#W-1001',
      'trade': 'ELECTRICIAN',
      'color': Colors.blue,
      'skills': ['HV', 'Wiring'],
      'contractor': 'Tata Projects Gang B',
      'present': false,
      'certExpired': false,
    },
    {
      'name': 'Amit Sharma',
      'id': '#W-1002',
      'trade': 'FITTER',
      'color': Colors.green,
      'skills': ['Pipe', 'Alignment'],
      'contractor': 'Shapoorji Gang C',
      'present': true,
      'certExpired': false,
    },
    {
      'name': 'Vikram Singh',
      'id': '#W-1003',
      'trade': 'RIGGER',
      'color': Colors.purple,
      'skills': ['Crane', 'Slinging'],
      'contractor': 'L&T Eng Gang A',
      'present': false,
      'certExpired': true,
    },
    {
      'name': 'Dinesh Verma',
      'id': '#W-1004',
      'trade': 'MASON',
      'color': Colors.teal,
      'skills': ['Concrete', 'Brickwork'],
      'contractor': 'BHEL Gang D',
      'present': true,
      'certExpired': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredWorkers {
    if (_searchQuery.trim().isEmpty) return _workers;
    final query = _searchQuery.toLowerCase().trim();
    return _workers.where((worker) {
      final name = (worker['name'] as String).toLowerCase();
      final id = (worker['id'] as String).toLowerCase();
      final trade = (worker['trade'] as String).toLowerCase();
      final contractor = (worker['contractor'] as String).toLowerCase();
      return name.contains(query) || id.contains(query) || trade.contains(query) || contractor.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredWorkers;
    // Scaffold background: 0xFF0B1326
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        title: const Text('Workforce & HR Management', style: TextStyle(color: Color(0xFFF1F5F9))),
        backgroundColor: const Color(0xFF111C38),
        iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
      ),
      body: Column(
        children: [
          _buildStatsRow(),
          _buildSearchBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return _buildWorkerCard(filtered[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add worker
          Navigator.pushNamed(context, '/add_worker');
        },
        backgroundColor: const Color(0xFF0284C7),
        child: const Icon(Icons.add, color: Color(0xFFF1F5F9)),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF111C38),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn('Total', '150', const Color(0xFFF1F5F9)),
          _buildStatColumn('Present', '125', const Color(0xFF4EDEA3)),
          _buildStatColumn('Absent', '25', Colors.redAccent),
          _buildStatColumn('Rate', '83%', const Color(0xFF38BDF8)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        style: const TextStyle(color: Color(0xFFF1F5F9)),
        decoration: InputDecoration(
          hintText: 'Search by name, badge, trade...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
          filled: true,
          fillColor: const Color(0xFF162347),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF26396E)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF26396E)),
          ),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    final bool isPresent = worker['present'] as bool? ?? false;
    final bool isCertExpired = worker['certExpired'] as bool? ?? false;
    final String name = worker['name'] as String? ?? '';
    final String id = worker['id'] as String? ?? '';
    final String trade = worker['trade'] as String? ?? 'GENERAL';
    final Color color = worker['color'] as Color? ?? Colors.orange;
    final List<String> skills = (worker['skills'] as List<dynamic>?)?.cast<String>() ?? [];
    final String contractor = worker['contractor'] as String? ?? '';
    
    return Card(
      color: const Color(0xFF162347),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF26396E)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 16, fontWeight: FontWeight.bold)),
                Text(id, style: const TextStyle(color: Color(0xFF94A3B8))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTradeBadge(trade, color),
                const SizedBox(width: 8),
                ...skills.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _buildSkillChip(s),
                )),
              ],
            ),
            const SizedBox(height: 8),
            Text('Contractor: $contractor', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAttendanceStatus(isPresent),
                if (!isPresent)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/clock_in');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Clock In', style: TextStyle(color: Colors.white)),
                  )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Safety Cert: ${isCertExpired ? "Expired (Oct 12)" : "Valid (Dec 25)"}',
              style: TextStyle(color: isCertExpired ? Colors.redAccent : const Color(0xFF4EDEA3), fontSize: 12),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTradeBadge(String trade, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(trade, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF111C38),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Text(skill, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
    );
  }

  Widget _buildAttendanceStatus(bool isPresent) {
    if (isPresent) {
      return Row(
        children: const [
          Icon(Icons.check_circle, color: Color(0xFF4EDEA3), size: 16),
          SizedBox(width: 4),
          Text('Verified Present (07:45 AM, 98%)', style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 12)),
        ],
      );
    } else {
      return Row(
        children: const [
          Icon(Icons.cancel, color: Colors.redAccent, size: 16),
          SizedBox(width: 4),
          Text('Not Clocked In', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
        ],
      );
    }
  }
}
