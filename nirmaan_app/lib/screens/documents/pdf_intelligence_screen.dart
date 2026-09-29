import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class PdfIntelligenceScreen extends StatelessWidget {
  const PdfIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('PDF Intelligence', style: TextStyle(color: Color(0xFFF1F5F9))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (provider.currentProject != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Scope: ${provider.currentProject!.name}',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                ),
              ),
            InkWell(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF162347),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF26396E), style: BorderStyle.solid),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.upload_file, size: 48, color: Color(0xFF38BDF8)),
                    SizedBox(height: 16),
                    Text('Upload Tender PDF', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 18)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard('Extract Key Insights', Icons.insights, Colors.amber),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard('Page-Preserving Translation', Icons.g_translate, Colors.green),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF1F5F9))),
        ],
      ),
    );
  }
}
