import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_controller.dart';
import '../../core/models/persona_model.dart';
import '../../providers/app_provider.dart';
import '../auth/login_screen.dart';
import 'gemini_keys_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;
  bool _isTestingConnection = false;
  String? _connectionTestResult;
  bool _connectionSuccess = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _urlController = TextEditingController(text: provider.apiService.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    final currentPersona = getPersonaForUser(user);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text(
          'Settings & Enterprise Profile',
          style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: LanguageController.instance,
        builder: (context, _) {
          final activeLangCode = LanguageController.instance.currentLanguageCode;
          final activeLang = LanguageController.instance.currentLanguage;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Profile Section
              _buildSectionHeader('Enterprise Identity & Role', Icons.badge_rounded),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF162347),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: currentPersona.accentColor.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: currentPersona.accentColor.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: currentPersona.accentColor.withValues(alpha: 0.2),
                          child: Icon(currentPersona.icon, color: currentPersona.accentColor, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user?['name'] ?? currentPersona.name,
                                      style: const TextStyle(
                                        color: Color(0xFFF1F5F9),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: currentPersona.accentColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: currentPersona.accentColor.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      currentPersona.category,
                                      style: TextStyle(
                                        color: currentPersona.accentColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?['role'] ?? currentPersona.role,
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentPersona.fidicRole,
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 10),
                              SizedBox(width: 4),
                              Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFF1E2E5C), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                            label: const Text('Switch Persona', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _showPersonaSwitchModal(context, provider),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFF43F5E),
                            side: const BorderSide(color: Color(0xFFF43F5E)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Sign Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _handleLogout(context, provider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Server Configuration Section
              _buildSectionHeader('Server Configuration & Diagnostics', Icons.dns_outlined),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF162347),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF26396E)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Color(0xFFF1F5F9)),
                      decoration: InputDecoration(
                        labelText: 'API Base URL',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF111C38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF26396E)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF26396E)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF0284C7)),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save, color: Color(0xFF38BDF8)),
                          onPressed: () {
                            provider.apiService.updateBaseUrl(_urlController.text.trim());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Server URL updated')),
                            );
                          },
                        ),
                      ),
                      onSubmitted: (val) {
                        provider.apiService.updateBaseUrl(val.trim());
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Quick Environment Presets:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          backgroundColor: const Color(0xFF111C38),
                          side: const BorderSide(color: Color(0xFF0284C7)),
                          label: const Text('Vercel Production', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                          onPressed: () {
                            _urlController.text = 'https://forge-tau-eight-89.vercel.app';
                            provider.apiService.updateBaseUrl(_urlController.text);
                          },
                        ),
                        ActionChip(
                          backgroundColor: const Color(0xFF111C38),
                          side: const BorderSide(color: Color(0xFF26396E)),
                          label: const Text('Android 10.0.2.2', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 12)),
                          onPressed: () {
                            _urlController.text = 'http://10.0.2.2:3000';
                            provider.apiService.updateBaseUrl(_urlController.text);
                          },
                        ),
                        ActionChip(
                          backgroundColor: const Color(0xFF111C38),
                          side: const BorderSide(color: Color(0xFF26396E)),
                          label: const Text('Localhost:3000', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 12)),
                          onPressed: () {
                            _urlController.text = 'http://localhost:3000';
                            provider.apiService.updateBaseUrl(_urlController.text);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isTestingConnection
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.network_ping, size: 18),
                        label: Text(_isTestingConnection ? 'Testing Connection...' : 'Test Connection & Ping Backend'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isTestingConnection
                            ? null
                            : () async {
                                setState(() {
                                  _isTestingConnection = true;
                                  _connectionTestResult = null;
                                });
                                final sw = Stopwatch()..start();
                                try {
                                  final res = await provider.apiService.getProjects();
                                  sw.stop();
                                  int count = 0;
                                  if (res is Map && res['projects'] is List) {
                                    count = (res['projects'] as List).length;
                                  }
                                  setState(() {
                                    _isTestingConnection = false;
                                    _connectionSuccess = true;
                                    _connectionTestResult = 'Connected to server (${sw.elapsedMilliseconds}ms) - $count projects found';
                                  });
                                  await provider.loadProjects();
                                } catch (e) {
                                  sw.stop();
                                  setState(() {
                                    _isTestingConnection = false;
                                    _connectionSuccess = false;
                                    _connectionTestResult = 'Ping failed: ${e.toString().replaceAll('Exception:', '').trim()}';
                                  });
                                }
                              },
                      ),
                    ),
                    if (_connectionTestResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _connectionSuccess ? const Color(0xFF4EDEA3).withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _connectionSuccess ? const Color(0xFF4EDEA3) : Colors.redAccent),
                        ),
                        child: Row(
                          children: [
                            Icon(_connectionSuccess ? Icons.check_circle : Icons.error_outline,
                                color: _connectionSuccess ? const Color(0xFF4EDEA3) : Colors.redAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _connectionTestResult!,
                                style: TextStyle(
                                  color: _connectionSuccess ? const Color(0xFF4EDEA3) : Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Multilingual Support Header & Badge
              Row(
                children: [
                  Expanded(
                    child: _buildSectionHeader('Language Selection (10 Languages)', Icons.translate),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF38BDF8)),
                    ),
                    child: Text(
                      'ACTIVE: ${activeLang.name.toUpperCase()}',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // All 10 Supported Indian Languages
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF162347),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF26396E)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select preferred language for real-time dynamic switching without restarting the app:',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppLocalizations.supportedLanguages.map((lang) {
                        final isSelected = activeLangCode == lang.code;
                        return ChoiceChip(
                          avatar: isSelected
                              ? const Icon(Icons.check_circle, size: 16, color: Colors.white)
                              : null,
                          label: Text(
                            '${lang.nativeName} (${lang.name})',
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              LanguageController.instance.changeLanguage(lang.code);
                              provider.setLanguage(lang.code);
                            }
                          },
                          selectedColor: const Color(0xFF0284C7),
                          backgroundColor: const Color(0xFF111C38),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF26396E),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Live Dynamic Localization Preview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF162347), Color(0xFF111C38)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.preview_outlined, color: Color(0xFFFFB95F), size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Live Dynamic Localization Preview',
                          style: TextStyle(
                            color: Color(0xFFFFB95F),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '[${activeLang.code.toUpperCase()}] ${activeLang.nativeName}',
                          style: const TextStyle(
                            color: Color(0xFF4EDEA3),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF26396E), height: 20),
                    _buildPreviewRow('App Title', AppLocalizations.text('app_title', activeLangCode)),
                    const SizedBox(height: 6),
                    _buildPreviewRow('Tagline', AppLocalizations.text('tagline', activeLangCode)),
                    const SizedBox(height: 6),
                    _buildPreviewRow('Project Workspace', AppLocalizations.text('project_workspace', activeLangCode)),
                    const SizedBox(height: 6),
                    _buildPreviewRow('Labour Attendance', AppLocalizations.text('labour_attendance', activeLangCode)),
                    const SizedBox(height: 6),
                    _buildPreviewRow('Budget Tracking', AppLocalizations.text('budget_tracking', activeLangCode)),
                    const SizedBox(height: 6),
                    _buildPreviewRow('Voice Assistant', AppLocalizations.text('voice_assistant', activeLangCode)),
                    const SizedBox(height: 6),
                    _buildPreviewRow('FIDIC Variations', AppLocalizations.text('fidic_variations', activeLangCode)),
                    const SizedBox(height: 6),
                    _buildPreviewRow('Claims & DAB', AppLocalizations.text('claims_dab', activeLangCode)),
                    const SizedBox(height: 6),
                    _buildPreviewRow('Pipeline NDT', AppLocalizations.text('pipeline_ndt', activeLangCode)),
                    const SizedBox(height: 6),
                    _buildPreviewRow('Digital Twin', AppLocalizations.text('digital_twin', activeLangCode)),
                    const SizedBox(height: 6),
                    _buildPreviewRow('Executive Reports', AppLocalizations.text('executive_reports', activeLangCode)),
                    const SizedBox(height: 6),
                    _buildPreviewRow('Stakeholder Portal', AppLocalizations.text('stakeholder_portal', activeLangCode)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Gemini Multi-Key Architecture Card
              _buildSectionHeader('AI Brain Multi-Key Setup', Icons.auto_awesome_rounded),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF162347),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0284C7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.vpn_key_rounded, color: Color(0xFF38BDF8), size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Per-Module Gemini API Keys',
                          style: TextStyle(
                            color: Color(0xFFF1F5F9),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Assign dedicated Gemini 2.0 Flash API keys for Voice Agent, Tender PDF, Risk Radar, and Copilot to prevent quota bottlenecks.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GeminiKeysScreen()),
                          );
                        },
                        icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                        label: const Text('Configure Module Keys & Test', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  await provider.logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewRow(String label, String translatedText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        Expanded(
          child: Text(
            translatedText,
            style: const TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context, AppProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162347),
        title: const Text('Confirm Sign Out', style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to sign out of Nirmaan OS? Any offline queued mutations will remain cached safely.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SIGN OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await provider.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showPersonaSwitchModal(BuildContext context, AppProvider provider) {
    final activeId = provider.currentUser?['id'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1326),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Switch Enterprise Role',
                            style: TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Instant 1-tap live persona switching',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF1E2E5C), height: 1),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: kAllPersonas.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final persona = kAllPersonas[index];
                        final isCurrent = persona.id == activeId;

                        return InkWell(
                          onTap: () async {
                            Navigator.pop(ctx);
                            await provider.loginUser(persona.toUserData());
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF162347),
                                  content: Row(
                                    children: [
                                      Icon(persona.icon, color: persona.accentColor, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Switched to ${persona.name} (${persona.role})',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? persona.accentColor.withValues(alpha: 0.12)
                                  : const Color(0xFF162347),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrent
                                    ? persona.accentColor
                                    : const Color(0xFF26396E),
                                width: isCurrent ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: persona.accentColor.withValues(alpha: 0.2),
                                  child: Icon(persona.icon, color: persona.accentColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              persona.name,
                                              style: TextStyle(
                                                color: isCurrent ? Colors.white : const Color(0xFFE2E8F0),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: persona.accentColor.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              persona.category,
                                              style: TextStyle(
                                                color: persona.accentColor,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        persona.role,
                                        style: TextStyle(
                                          color: persona.accentColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'FIDIC: ${persona.fidicRole}',
                                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: persona.accentColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                else
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF64748B), size: 14),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
