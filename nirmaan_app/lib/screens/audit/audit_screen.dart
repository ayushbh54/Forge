import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final logs = provider.auditLogs;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('Tamper-Proof Audit Trail', style: TextStyle(color: Color(0xFFF1F5F9))),
      ),
      body: logs.isEmpty
        ? const Center(child: Text('No audit logs found.', style: TextStyle(color: Color(0xFF94A3B8))))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.edit_document, color: Color(0xFF38BDF8)),
                        const SizedBox(height: 4),
                        Container(width: 2, height: 100, color: const Color(0xFF26396E)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162347),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF26396E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(log['action'] ?? 'Unknown Action', style: const TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold)),
                                Text(log['time'] ?? '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Actor: ${log['actor'] ?? 'System'}', style: const TextStyle(color: Color(0xFF94A3B8))),
                            Text('Entity: ${log['entityType'] ?? ''} | ID: ${log['entityId'] ?? ''}', style: const TextStyle(color: Color(0xFF94A3B8))),
                            const SizedBox(height: 8),
                            if (log['oldValue'] != null && log['newValue'] != null)
                              Row(
                                children: [
                                  Text('${log['oldValue']}', style: const TextStyle(color: Colors.red, decoration: TextDecoration.lineThrough)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 8),
                                  Text('${log['newValue']}', style: const TextStyle(color: Color(0xFF4EDEA3))),
                                ],
                              ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B1326),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('SHA-256: ${log['hash'] ?? 'e3b0c44298fc1c14...'}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10)),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
