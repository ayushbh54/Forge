import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class LinkingBridgeScreen extends StatelessWidget {
  const LinkingBridgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('NLP Activity Linking Bridge', style: TextStyle(color: Color(0xFFF1F5F9))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (provider.currentProject != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Active Project: ${provider.currentProject!.name}',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                ),
              ),
            TextField(
              maxLines: 5,
              style: const TextStyle(color: Color(0xFFF1F5F9)),
              decoration: InputDecoration(
                hintText: 'Enter raw field text here (e.g., Daily report, Site diary)...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFF162347),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {},
                child: const Text('Extract & Match', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Match Results', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF162347),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('No results yet. Run extraction.', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
