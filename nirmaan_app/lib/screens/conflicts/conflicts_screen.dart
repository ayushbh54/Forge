import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class ConflictsScreen extends StatefulWidget {
  const ConflictsScreen({super.key});

  @override
  State<ConflictsScreen> createState() => _ConflictsScreenState();
}

class _ConflictsScreenState extends State<ConflictsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final conflicts = provider.conflicts.where((c) {
      if (_filter == 'All') return true;
      return c['status'] == _filter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('Conflict & Dispute Center', style: TextStyle(color: Color(0xFFF1F5F9))),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Color(0xFFF1F5F9)),
            color: const Color(0xFF162347),
            onSelected: (val) => setState(() => _filter = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All', style: TextStyle(color: Color(0xFFF1F5F9)))),
              const PopupMenuItem(value: 'OPEN', child: Text('OPEN', style: TextStyle(color: Color(0xFFF1F5F9)))),
              const PopupMenuItem(value: 'RESOLVED', child: Text('RESOLVED', style: TextStyle(color: Color(0xFFF1F5F9)))),
            ],
          )
        ],
      ),
      body: conflicts.isEmpty 
        ? const Center(child: Text('No conflicts found.', style: TextStyle(color: Color(0xFF94A3B8))))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conflicts.length,
            itemBuilder: (context, index) {
              final conflict = conflicts[index];
              final isOpen = conflict['status'] == 'OPEN';
              return Card(
                color: const Color(0xFF162347),
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(conflict['title'] ?? 'Unknown Conflict', style: const TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold)),
                  subtitle: Text('Activity: ${conflict['activityCode'] ?? 'N/A'} | Type: ${conflict['type'] ?? 'Unknown'}', style: const TextStyle(color: Color(0xFF94A3B8))),
                  leading: CircleAvatar(backgroundColor: isOpen ? Colors.red : Colors.green, radius: 10),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    Text(conflict['description'] ?? '', style: const TextStyle(color: Color(0xFFF1F5F9))),
                    const SizedBox(height: 8),
                    Text('Spec/Clause Reference: ${conflict['reference'] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF94A3B8))),
                    const SizedBox(height: 16),
                    if (isOpen)
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                          onPressed: () {
                            _showResolveDialog(context, provider, conflict['id'].toString());
                          },
                          child: const Text('Resolve', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
    );
  }

  void _showResolveDialog(BuildContext context, AppProvider provider, String conflictId) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162347),
        title: const Text('Resolve Conflict', style: TextStyle(color: Color(0xFFF1F5F9))),
        content: TextField(
          controller: noteCtrl,
          style: const TextStyle(color: Color(0xFFF1F5F9)),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter resolution note...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFF0B1326),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () async {
              Navigator.pop(context);
              await provider.resolveConflict(conflictId, noteCtrl.text);
            },
            child: const Text('Submit Resolution', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
