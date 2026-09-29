import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'dialect_speech_tuner_screen.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  bool _isRecording = false;
  String _transcript = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('Voice-First Site Update', style: TextStyle(color: Color(0xFFF1F5F9))),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF38BDF8)),
            tooltip: 'Dialect & Lexicon Tuner',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DialectSpeechTunerScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isRecording ? 'Listening...' : 'Tap to speak in Hindi or English',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 18),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isRecording = !_isRecording;
                    if (!_isRecording) {
                      _transcript = 'Excavation completed for 500 cubic meters in zone B.';
                    } else {
                      _transcript = '';
                    }
                  });
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: _isRecording ? Colors.red : const Color(0xFF0284C7),
                  child: const Icon(Icons.mic, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF26396E)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.tune, size: 16, color: Color(0xFF38BDF8)),
                label: const Text('Dialect & Lexicon Tuner (5 Dialects)', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DialectSpeechTunerScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),
              if (_transcript.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF162347),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_transcript, style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 16)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  onPressed: () async {
                    if (provider.currentProjectId != null) {
                      await provider.submitDpr({
                        'notes': _transcript,
                        'reportedBy': provider.currentUser?['name'] ?? 'Voice Agent',
                      });
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Voice DPR submitted successfully!'), backgroundColor: Color(0xFF4EDEA3)),
                      );
                    }
                  },
                  child: const Text('Confirm & Submit as DPR', style: TextStyle(color: Colors.white)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
