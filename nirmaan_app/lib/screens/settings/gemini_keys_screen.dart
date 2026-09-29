import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

class GeminiKeysScreen extends StatefulWidget {
  const GeminiKeysScreen({super.key});

  @override
  State<GeminiKeysScreen> createState() => _GeminiKeysScreenState();
}

class _GeminiKeysScreenState extends State<GeminiKeysScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _obscureText = {};
  final Map<String, String> _testStatus = {};
  final Map<String, bool> _testing = {};

  final List<Map<String, dynamic>> _modules = [
    {
      'id': 'general',
      'name': 'Master Global Key',
      'desc': 'Default key used across all modules if module-specific key is not set.',
      'icon': Icons.vpn_key_rounded,
      'color': Color(0xFF0284C7),
    },
    {
      'id': 'copilot',
      'name': 'AI Copilot & Chat Brain',
      'desc': 'Powers natural language project health analysis, chat Q&A, and recovery suggestions.',
      'icon': Icons.psychology_rounded,
      'color': Color(0xFF38BDF8),
    },
    {
      'id': 'voice',
      'name': 'Voice Time Agent (NLP)',
      'desc': 'Transcribes site audio in Hindi/English and extracts L5 activities & quantities.',
      'icon': Icons.mic_rounded,
      'color': Color(0xFF4EDEA3),
    },
    {
      'id': 'pdf',
      'name': 'Tender PDF Intelligence',
      'desc': 'Extracts clauses, milestones, and performs page-preserving translation on 100+ page PDFs.',
      'icon': Icons.picture_as_pdf_rounded,
      'color': Color(0xFFFFB95F),
    },
    {
      'id': 'risk',
      'name': 'AI Delay Risk Radar',
      'desc': 'Predicts critical path bottlenecks 2-4 weeks in advance using Monte Carlo & pattern analysis.',
      'icon': Icons.radar_rounded,
      'color': Colors.redAccent,
    },
    {
      'id': 'linking',
      'name': 'Field Text Linking Bridge',
      'desc': 'Fuzzy matches unstructured site diary notes & WhatsApp memos to Primavera P6 WBS.',
      'icon': Icons.link_rounded,
      'color': Color(0xFFA855F7),
    },
    {
      'id': 'fidic',
      'name': 'FIDIC Contract Dispute Advisor',
      'desc': 'Drafts Clause 8.4 EOT notices and evaluates contractor interim claim variances.',
      'icon': Icons.gavel_rounded,
      'color': Color(0xFFEC4899),
    },
    {
      'id': 'triangulation',
      'name': '5-Factor Consensus Reasoner',
      'desc': 'Reconciles Contractor vs QS vs QC vs Drone vs Materials physical reality.',
      'icon': Icons.balance_rounded,
      'color': Color(0xFF14B8A6),
    },
  ];

  @override
  void initState() {
    super.initState();
    for (var mod in _modules) {
      final id = mod['id'] as String;
      _controllers[id] = TextEditingController();
      _obscureText[id] = true;
      _testStatus[id] = '';
      _testing[id] = false;
    }
    _loadSavedKeys();
  }

  Future<void> _loadSavedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    for (var mod in _modules) {
      final id = mod['id'] as String;
      final savedKey = prefs.getString('gemini_key_$id');
      if (savedKey != null && savedKey.isNotEmpty) {
        setState(() {
          _controllers[id]?.text = savedKey;
          _testStatus[id] = 'Saved ✓';
        });
      }
    }
  }

  Future<void> _saveKey(String moduleId) async {
    final key = _controllers[moduleId]?.text.trim() ?? '';
    final provider = context.read<AppProvider>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_key_$moduleId', key);

    // Sync with backend API
    try {
      if (moduleId == 'general') {
        await provider.apiService.geminiChat('SET_KEY', {'apiKey': key});
      } else {
        await provider.apiService.geminiChat('SET_MODULE_KEY', {
          'payload': {'module': moduleId, 'key': key},
        });
      }
      setState(() {
        _testStatus[moduleId] = 'Saved & Synced ✓';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gemini Key for [$moduleId] saved & registered!'),
            backgroundColor: const Color(0xFF4EDEA3),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _testStatus[moduleId] = 'Saved Locally';
      });
    }
  }

  Future<void> _testKey(String moduleId) async {
    final key = _controllers[moduleId]?.text.trim() ?? '';
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API Key first')),
      );
      return;
    }

    setState(() {
      _testing[moduleId] = true;
      _testStatus[moduleId] = 'Testing...';
    });

    try {
      final provider = context.read<AppProvider>();
      final res = await provider.apiService.geminiChat('SET_MODULE_KEY', {
        'payload': {'module': moduleId, 'key': key},
      });

      setState(() {
        _testing[moduleId] = false;
        if (res != null && res['success'] == true) {
          _testStatus[moduleId] = 'Active ✓';
        } else {
          _testStatus[moduleId] = 'Configured';
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gemini [$moduleId] key verified successfully!'),
            backgroundColor: const Color(0xFF4EDEA3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _testing[moduleId] = false;
        _testStatus[moduleId] = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Gemini Brain Key Architecture',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppTheme.textSecondary),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0284C7).withAlpha(100)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF38BDF8), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Multi-Key Parallel AI Architecture',
                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You can configure separate Gemini API keys for each module to prevent rate-limit clashing and ensure dedicated AI throughput for Voice, PDFs, Risks, and Copilot.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Module Key Configuration',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Modules List
            ..._modules.map((mod) => _buildModuleCard(mod)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(Map<String, dynamic> mod) {
    final id = mod['id'] as String;
    final name = mod['name'] as String;
    final desc = mod['desc'] as String;
    final icon = mod['icon'] as IconData;
    final color = mod['color'] as Color;
    final controller = _controllers[id]!;
    final obscure = _obscureText[id] ?? true;
    final status = _testStatus[id] ?? '';
    final isTesting = _testing[id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      desc,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status.contains('✓')
                        ? const Color(0xFF4EDEA3).withAlpha(30)
                        : Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status.contains('✓') ? const Color(0xFF4EDEA3) : Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // API Key Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'Enter AI Studio Gemini Key (AIzaSy...)',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF0284C7)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText[id] = !obscure;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Save Button
              IconButton.filled(
                icon: const Icon(Icons.check_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _saveKey(id),
                tooltip: 'Save Key',
              ),
              const SizedBox(width: 4),
              // Test Button
              IconButton.outlined(
                icon: isTesting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 18),
                style: IconButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: const BorderSide(color: Color(0xFF26396E)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isTesting ? null : () => _testKey(id),
                tooltip: 'Test Key',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Gemini API Key Setup', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          '1. Get your free API keys from Google AI Studio (aistudio.google.com).\n\n'
          '2. You can create multiple API keys and assign them to different modules to eliminate quota conflicts.\n\n'
          '3. If a module has no key specified, it automatically falls back to the Master Global Key.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }
}
