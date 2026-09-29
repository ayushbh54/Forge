import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_controller.dart';
import '../../providers/app_provider.dart';
import 'gemini_keys_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;

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

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text(
          'Settings & Localization',
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
              _buildSectionHeader('User Profile', Icons.account_circle_outlined),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF162347),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF26396E)),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF0284C7),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    user?['name'] ?? 'Admin User',
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Role: ${user?['role'] ?? 'Project Manager'}',
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4EDEA3).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF4EDEA3)),
                    ),
                    child: const Text(
                      'ONLINE',
                      style: TextStyle(
                        color: Color(0xFF4EDEA3),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Server Configuration Section
              _buildSectionHeader('Server Configuration', Icons.dns_outlined),
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
}
