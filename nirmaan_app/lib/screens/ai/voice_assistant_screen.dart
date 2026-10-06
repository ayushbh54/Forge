import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'dialect_speech_tuner_screen.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  int _recordingSeconds = 0;
  String _transcript = '';
  String _selectedLanguage = 'Hinglish (Site Dialect)';
  bool _isAnalyzing = false;
  bool _showHistory = true;

  // Extracted Entities State
  Map<String, dynamic>? _extractedData;

  // Voice Update History Log
  final List<Map<String, dynamic>> _voiceHistory = [
    {
      'id': 'V-DPR-942',
      'user': 'Vikram Joshi (Resident Engineer)',
      'time': 'Today, 11:20 AM',
      'language': 'Hinglish',
      'rawVoice': 'Pier 24 well sinking 48.5m complete hua, water velocity high hone se 1.5 ghante delay tha, 16 bar benders deployed.',
      'activity': 'Pier P-24 Well Foundation Sinking',
      'quantity': '48.50 Meters',
      'progress': '89.8%',
      'delay': 'FIDIC Cl 8.4 High Scour Velocity (1.5 hrs)',
      'status': 'SYNCED TO P6 & DPR',
    },
    {
      'id': 'V-DPR-939',
      'user': 'Ananya Roy (QA/QC Lead)',
      'time': 'Yesterday, 05:40 PM',
      'language': 'Hindi',
      'rawVoice': 'पियर 22 M60 कंक्रीट पोर 320 क्यूबिक मीटर संपन्न हुआ, स्लम्प 160mm पास हुआ।',
      'activity': 'Pier P-22 M60 Cap Pour',
      'quantity': '320.00 cum',
      'progress': '100.0%',
      'delay': 'No delay / On Schedule',
      'status': 'SYNCED TO P6 & DPR',
    },
    {
      'id': 'V-DPR-924',
      'user': 'Kavita Iyer (HSE Lead)',
      'time': '04 Oct, 03:15 PM',
      'language': 'English',
      'rawVoice': 'Segment span 38 precast stitching locked, stay cable tension tested at 1860 MPa without slippage.',
      'activity': 'Span 38 Cable Stay Tensioning',
      'quantity': '1860 MPa Tension',
      'progress': '79.2%',
      'delay': 'Gantry wind gust 38 km/h noted',
      'status': 'SYNCED TO P6 & DPR',
    },
  ];

  final List<Map<String, dynamic>> _presetVoiceSamples = [
    {
      'title': 'Bridge Well Sinking (Pier 24)',
      'lang': 'Hinglish (Site Dialect)',
      'text': 'Pier 24 well sinking 48.5 meter tak complete ho gaya hai. River water velocity tez hone se 2 ghante ka stoppage hua tha. 18 workers deployed the.',
      'activity': 'Pier P-24 Well Foundation Sinking (-48.5m)',
      'quantity': '48.50 Meters',
      'progress': '89.8%',
      'delay': 'High river velocity stoppage (2.0 hrs)',
      'workforce': '18 Ground Workers',
    },
    {
      'title': 'M60 HPC Pier Cap Pour',
      'lang': 'Hindi (हिन्दी)',
      'text': 'पियर 22 कैप का M60 कंक्रीट पोर 320 क्यूबिक मीटर आज 4 बजे पूरा हुआ। स्लम्प टेस्ट IS 456 के तहत सत्यापित है। कोई रुकावट नहीं हुई।',
      'activity': 'Pier P-22 M60 HPC Cap Pour',
      'quantity': '320.00 cum',
      'progress': '100.0%',
      'delay': 'None (Zero delay)',
      'workforce': '24 Concrete Gang',
    },
    {
      'title': 'Stay Cable Tension Load Test',
      'lang': 'English (Technical)',
      'text': 'Stay cable 1860 MPa tension verification completed for Pier 24 south tower strand group 4. Zero elongation slippage recorded.',
      'activity': 'Pier P-24 Cable Stay Tension Verification',
      'quantity': '1,860.00 MPa',
      'progress': '79.2%',
      'delay': 'None (Passed IRC:SP:47 test)',
      'workforce': '8 Specialized Riggers',
    },
  ];

  void _simulateVoiceRecording({String? customSample, Map<String, dynamic>? sampleData}) async {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _transcript = '';
      _extractedData = null;
    });

    for (int i = 1; i <= 3; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _recordingSeconds = i);
    }

    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final targetText = customSample ?? 'Pier 24 well sinking 48.5 meter complete ho gaya hai, 2 ghante ka river scour current delay tha.';
    final extracted = sampleData ?? {
      'activity': 'Pier P-24 Well Foundation Sinking (-48.5m)',
      'quantity': '48.50 Meters',
      'progress': '89.8%',
      'delay': 'High river scour current (2.0 hrs)',
      'workforce': '18 Workers',
    };

    setState(() {
      _isAnalyzing = false;
      _transcript = targetText;
      _extractedData = extracted;
    });
  }

  void _submitVoiceDpr() async {
    if (_extractedData == null) return;

    final provider = context.read<AppProvider>();
    final userName = provider.currentUser?['name'] ?? 'Voice Agent (Field Supervisor)';

    final newEntry = {
      'id': 'V-DPR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'user': userName,
      'time': 'Just now',
      'language': _selectedLanguage,
      'rawVoice': _transcript,
      'activity': _extractedData!['activity'],
      'quantity': _extractedData!['quantity'],
      'progress': _extractedData!['progress'],
      'delay': _extractedData!['delay'],
      'status': 'SYNCED TO P6 & DPR',
    };

    setState(() {
      _voiceHistory.insert(0, newEntry);
    });

    if (provider.currentProjectId != null) {
      await provider.submitDpr({
        'notes': _transcript,
        'activity': _extractedData!['activity'],
        'quantity': _extractedData!['quantity'],
        'delayReason': _extractedData!['delay'],
        'reportedBy': userName,
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.verified, color: Color(0xFF0B1326), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Voice Update Synced to DPR & Critical Path Schedule!', style: TextStyle(color: Color(0xFF0B1326), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 3),
        ),
      );

      setState(() {
        _transcript = '';
        _extractedData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voice-to-Project Updater', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Hands-free Progress, Qty & Delay Voice Parsing', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF38BDF8)),
            tooltip: 'Dialect & Lexicon Tuner',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DialectSpeechTunerScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Voice Mode Banner
            _buildVoiceLanguageSelector(),
            const SizedBox(height: 16),

            // Main Microphone Visualizer Box
            _buildMicRecordingBox(),
            const SizedBox(height: 16),

            // Quick Preset Voice Chips
            _buildQuickPresets(),
            const SizedBox(height: 16),

            // Structured Extraction Card
            if (_extractedData != null) ...[
              _buildExtractedEntitiesCard(),
              const SizedBox(height: 16),
            ],

            // Dedicated History Section right underneath
            _buildVoiceHistorySection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceLanguageSelector() {
    final languages = [
      'Hinglish (Site Dialect)',
      'Hindi (हिन्दी)',
      'English (Technical)',
      'Bengali (বাংলা)',
      'Marathi (मराठी)',
      'Assamese (অসমীয়া)',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.language_rounded, color: Color(0xFF38BDF8), size: 18),
              SizedBox(width: 8),
              Text('Speech Language', style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: const Color(0xFF111C38),
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
              items: languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedLanguage = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicRecordingBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRecording ? Colors.redAccent : const Color(0xFF26396E),
          width: _isRecording ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Text(
            _isRecording
                ? 'Listening... Speak progress in Hindi or English (00:0$_recordingSeconds)'
                : _isAnalyzing
                    ? 'AI Speech Engine Extracting WBS & Quantities...'
                    : 'Tap microphone to speak site update hands-free',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isRecording ? Colors.redAccent : const Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Animated Mic Button
          GestureDetector(
            onTap: _isAnalyzing ? null : () => _simulateVoiceRecording(),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.redAccent : const Color(0xFF0284C7),
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.redAccent : const Color(0xFF0284C7)).withValues(alpha: 0.4),
                    blurRadius: _isRecording ? 24 : 12,
                    spreadRadius: _isRecording ? 4 : 0,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.mic : (_isAnalyzing ? Icons.hourglass_top_rounded : Icons.mic_none_rounded),
                size: 38,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWaveBar(12),
              _buildWaveBar(24),
              _buildWaveBar(36),
              _buildWaveBar(28),
              _buildWaveBar(16),
              _buildWaveBar(32),
              _buildWaveBar(44),
              _buildWaveBar(22),
              _buildWaveBar(14),
            ],
          ),

          if (_transcript.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1326),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF26396E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('VOICE AUDIO TRANSCRIPT', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('"$_transcript"', style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaveBar(double height) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      width: 4,
      height: _isRecording ? height : 6,
      decoration: BoxDecoration(
        color: _isRecording ? const Color(0xFF38BDF8) : const Color(0xFF26396E),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildQuickPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OR TEST WITH REALISTIC GROUND AUDIO SAMPLES:',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetVoiceSamples.map((sample) {
            return ActionChip(
              avatar: const Icon(Icons.play_circle_fill, size: 14, color: Color(0xFF38BDF8)),
              label: Text(sample['title'], style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 11)),
              backgroundColor: const Color(0xFF162347),
              side: const BorderSide(color: Color(0xFF26396E)),
              onPressed: () => _simulateVoiceRecording(customSample: sample['text'], sampleData: sample),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExtractedEntitiesCard() {
    final data = _extractedData!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 8),
                  Text('Extracted Project Update Entities', style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('AUTO-PARSED', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildEntityRow('Activity', data['activity']),
          _buildEntityRow('Installed Quantity', data['quantity']),
          _buildEntityRow('Progress %', data['progress']),
          _buildEntityRow('Flagged Delay Reason', data['delay'], isHighlight: true),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _submitVoiceDpr,
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('Commit & Sync to DPR & P6 Schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isHighlight ? const Color(0xFFFFB95F) : const Color(0xFFF1F5F9),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceHistorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showHistory = !_showHistory),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, color: Color(0xFF38BDF8), size: 20),
                    const SizedBox(width: 8),
                    const Text('Voice Update History & DPR Audit Log', style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_voiceHistory.length}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Icon(_showHistory ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF94A3B8)),
              ],
            ),
          ),
          if (_showHistory) ...[
            const SizedBox(height: 12),
            const Text(
              'Audit log of all spoken field updates parsed into daily reports and Primavera critical path.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _voiceHistory.length,
              separatorBuilder: (_, _) => const Divider(color: Color(0xFF26396E), height: 16),
              itemBuilder: (context, index) {
                final item = _voiceHistory[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['id'], style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(item['status'], style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item['user'], style: const TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w600, fontSize: 12)),
                    Text('"${item['rawVoice']}"', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1326),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF26396E)),
                          ),
                          child: Text(item['activity'], style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text('Qty: ${item['quantity']}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(item['time'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
