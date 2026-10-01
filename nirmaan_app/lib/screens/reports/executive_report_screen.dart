import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/status_badge.dart';

/// Report Template Types supported by the Nirmaan OS Executive Generator
enum ReportTemplateType {
  weeklyProgress,
  monthlySummary,
  contractorLedger,
  fidicDelayClaims,
}

class ReportTemplateMeta {
  final ReportTemplateType type;
  final String title;
  final String shortCode;
  final String description;
  final String audience;
  final String standardCode;
  final IconData icon;
  final Color accentColor;
  final int estimatedPages;

  const ReportTemplateMeta({
    required this.type,
    required this.title,
    required this.shortCode,
    required this.description,
    required this.audience,
    required this.standardCode,
    required this.icon,
    required this.accentColor,
    required this.estimatedPages,
  });
}

class CriticalBlockerItem {
  final String id;
  final String title;
  final String uwid;
  final String chainage;
  final int daysImpacted;
  final int totalFloat;
  final String severity; // 'CRITICAL', 'HIGH', 'MEDIUM'
  final Color severityColor;
  final String rootCause;
  final String mitigation;
  final String contractor;

  const CriticalBlockerItem({
    required this.id,
    required this.title,
    required this.uwid,
    required this.chainage,
    required this.daysImpacted,
    required this.totalFloat,
    required this.severity,
    required this.severityColor,
    required this.rootCause,
    required this.mitigation,
    required this.contractor,
  });
}

class ExecutiveReportScreen extends StatefulWidget {
  const ExecutiveReportScreen({super.key});

  @override
  State<ExecutiveReportScreen> createState() => _ExecutiveReportScreenState();
}

class _ExecutiveReportScreenState extends State<ExecutiveReportScreen> {
  // Selected Template
  ReportTemplateType _selectedTemplate = ReportTemplateType.monthlySummary;

  // Selected Reporting Period
  String _selectedPeriod = 'September 2026 (Cutoff W39)';
  final List<String> _periods = const [
    'September 2026 (Cutoff W39)',
    'Week 39 ending 29 Sep 2026',
    'Q3 2026 Comprehensive',
    'Fiscal YTD 2026-27',
  ];

  // Dossier Inclusion Options
  bool _includeDroneOrthomosaics = true;
  bool _includeBiometricGpsLogs = true;
  bool _includeRawScheduleXml = false;
  bool _appendCryptographicStamp = true;

  // Simulated Document Page Index for Live Sheet
  int _activeSheetPageIndex = 0;

  // Static Metadata Definitions
  static const List<ReportTemplateMeta> _templates = [
    ReportTemplateMeta(
      type: ReportTemplateType.weeklyProgress,
      title: 'Weekly Progress Report (WPR)',
      shortCode: 'WPR',
      description: 'Weekly lookahead, shift productivity, gang counts, and critical path activities.',
      audience: 'Site In-charge, PMs & Discipline Leads',
      standardCode: 'FIDIC Cl. 4.21 / WPR-W39',
      icon: Icons.calendar_view_week_rounded,
      accentColor: AppTheme.primaryLight,
      estimatedPages: 6,
    ),
    ReportTemplateMeta(
      type: ReportTemplateType.monthlySummary,
      title: 'Monthly Executive Summary',
      shortCode: 'MES',
      description: 'C-Suite board pack: S-Curve EVM, CAPEX burn, milestone compliance, and risks.',
      audience: 'Board of Directors, OIL MoPNG Execs & C-Suite',
      standardCode: 'ISO 19650 / FIDIC Cl. 4.21',
      icon: Icons.analytics_rounded,
      accentColor: AppTheme.secondary,
      estimatedPages: 8,
    ),
    ReportTemplateMeta(
      type: ReportTemplateType.contractorLedger,
      title: 'Contractor Performance Ledger',
      shortCode: 'CPL',
      description: 'Vendor scorecards, certified billing vs retention, rework rates, and tender points.',
      audience: 'Commercial & Contracts, Vendor Management',
      standardCode: 'Contract Cl. 14 / Cl. 60.1',
      icon: Icons.leaderboard_rounded,
      accentColor: AppTheme.tertiary,
      estimatedPages: 10,
    ),
    ReportTemplateMeta(
      type: ReportTemplateType.fidicDelayClaims,
      title: 'FIDIC Delay Claims Dossier',
      shortCode: 'FDC',
      description: 'Extension of Time (EoT) substantiation, force majeure weather, and DAB claim defense.',
      audience: 'Legal Counsel, Dispute Adjudication Board & FIDIC Eng.',
      standardCode: 'FIDIC Red Book Cl. 8.4 & 20.1',
      icon: Icons.gavel_rounded,
      accentColor: Color(0xFFFF5252),
      estimatedPages: 14,
    ),
  ];

  // Top 3 Critical Path Blockers
  static const List<CriticalBlockerItem> _criticalBlockers = [
    CriticalBlockerItem(
      id: 'BLK-01',
      title: 'River Brahmaputra Crossing (HDD Borehole 04)',
      uwid: 'UWID-HDD-04-BRAHMA',
      chainage: 'KM 18+400 to 19+850',
      daysImpacted: 14,
      totalFloat: -8,
      severity: 'CRITICAL',
      severityColor: Color(0xFFFF5252),
      rootCause: 'Sub-surface gravel scour zone ruptured high-pressure bentonite mud pump seal.',
      mitigation: '2nd heavy rig mobilized from Numaligarh; high-density synthetic polymer mix injected.',
      contractor: 'Consortium Heavy HDD JV',
    ),
    CriticalBlockerItem(
      id: 'BLK-02',
      title: 'Right-of-Way (RoW) KM 42–48 Forest Clearance',
      uwid: 'UWID-ROW-42-DFO',
      chainage: 'KM 42+000 to KM 48+200',
      daysImpacted: 9,
      totalFloat: -6,
      severity: 'HIGH',
      severityColor: AppTheme.secondary,
      rootCause: 'State Forest Dept DFO compensatory afforestation gazette notification pending.',
      mitigation: 'Tripartite DC reconciliation scheduled for Oct 3; bypass trenching underway in non-forest sector.',
      contractor: 'Assam Pipeline Infrastructure Ltd',
    ),
    CriticalBlockerItem(
      id: 'BLK-03',
      title: '32-inch High-Yield API 5L X70 Pipe Spools Customs Clearance',
      uwid: 'UWID-MAT-X70-KOL',
      chainage: 'Port CFS / Base Staging Yard Alpha',
      daysImpacted: 5,
      totalFloat: -2,
      severity: 'MEDIUM',
      severityColor: Color(0xFFFFD54F),
      rootCause: 'Kolkata Port container freight station phytosanitary wooden cradle inspection backlog.',
      mitigation: 'Green-channel bonded convoy dispatch cleared; first convoy of 18 spools arriving site Oct 2.',
      contractor: 'Jindal Saw Pipeline Logistics',
    ),
  ];

  ReportTemplateMeta get _currentTemplateMeta {
    return _templates.firstWhere((t) => t.type == _selectedTemplate);
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------

  void _generateFormalPdfDossier() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return _PdfGenerationProgressDialog(
          template: _currentTemplateMeta,
          period: _selectedPeriod,
          onComplete: () {
            Navigator.of(dialogCtx).pop();
            _showDossierSuccessModal();
          },
        );
      },
    );
  }

  void _showDossierSuccessModal() {
    final fileName = 'Nirmaan_${_currentTemplateMeta.shortCode}_OIL-PL-024_Sep2026.pdf';
    final sha256Stamp = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withAlpha(35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Formal PDF Dossier Generated',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Compliant with ${_currentTemplateMeta.standardCode}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primaryLight.withAlpha(120)),
                    ),
                    child: Text(
                      '${_currentTemplateMeta.estimatedPages} Pages',
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Dossier Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Color(0xFFFF5252), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text(
                          '4.82 MB',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.border, height: 18),
                    Row(
                      children: [
                        const Icon(Icons.verified_user, color: AppTheme.tertiary, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'SHA-256 Stamp: ',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                        Expanded(
                          child: Text(
                            '${sha256Stamp.substring(0, 18)}...',
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: sha256Stamp));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('SHA-256 Hash copied to clipboard!'),
                                backgroundColor: AppTheme.surfaceContainerHigh,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.copy, size: 14, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.primaryLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppTheme.primaryLight),
                      label: const Text('View Document', style: TextStyle(color: AppTheme.primaryLight)),
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        _openDocumentReaderModal();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                      label: const Text('Save to Device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.folder_special, color: AppTheme.tertiary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text('Saved: Downloads/$fileName'),
                                ),
                              ],
                            ),
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDocumentReaderModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          maxChildSize: 0.96,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Reader Top Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      border: Border(bottom: BorderSide(color: AppTheme.border)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Color(0xFFFF5252), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_currentTemplateMeta.shortCode} - Executive Dossier (OIL-PL-024)',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Page 1 of 8 • Tamper-proof Certified PDF',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  // Sheet Reader Body
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 620),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(100),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: _buildDossierSheetContent(),
                        ),
                      ),
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

  void _shareViaWhatsAppEmail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (shareCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.share_rounded, color: AppTheme.primaryLight, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Executive Dispatch & Sharing',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Broadcast formal milestone summaries to Client, JV Partners, or Ministry Officials.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              // Option 1: WhatsApp
              _buildShareOptionTile(
                icon: Icons.chat_rounded,
                iconColor: const Color(0xFF25D366),
                title: 'Share via WhatsApp',
                subtitle: 'Dispatches pre-formatted executive summary with Health Index & Blocker alert.',
                onTap: () async {
                  Navigator.pop(shareCtx);
                  final message = _generateShareMessage();
                  final whatsappUrl = 'whatsapp://send?text=${Uri.encodeComponent(message)}';
                  try {
                    final uri = Uri.parse(whatsappUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      await launchUrl(Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}'), mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    Clipboard.setData(ClipboardData(text: message));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('WhatsApp not detected. Summary copied to clipboard!'),
                          backgroundColor: AppTheme.surfaceContainerHigh,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 10),
              // Option 2: Email
              _buildShareOptionTile(
                icon: Icons.email_rounded,
                iconColor: AppTheme.primaryLight,
                title: 'Official Email Dispatch',
                subtitle: 'Pre-fills executive briefing email addressed to Board & FIDIC Engineer.',
                onTap: () async {
                  Navigator.pop(shareCtx);
                  final subject = 'NIRMAAN OS: Executive Progress Report - Trunk Crude Pipeline [Sep 2026]';
                  final body = _generateShareMessage();
                  final emailUrl = 'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
                  try {
                    final uri = Uri.parse(emailUrl);
                    await launchUrl(uri);
                  } catch (e) {
                    Clipboard.setData(ClipboardData(text: body));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email app could not be launched. Text copied to clipboard!'),
                          backgroundColor: AppTheme.surfaceContainerHigh,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 10),
              // Option 3: Copy to Clipboard
              _buildShareOptionTile(
                icon: Icons.copy_rounded,
                iconColor: AppTheme.secondary,
                title: 'Copy Executive Briefing to Clipboard',
                subtitle: 'Formatted plain-text executive briefing for Slack, Teams, or SMS.',
                onTap: () {
                  Navigator.pop(shareCtx);
                  final text = _generateShareMessage();
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Executive briefing copied to clipboard!'),
                      backgroundColor: AppTheme.surfaceContainerHigh,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _generateShareMessage() {
    return '''
*NIRMAAN OS — EXECUTIVE PROGRESS BRIEFING*
*Project:* Trunk Crude Oil Pipeline Expansion (OIL-PL-024)
*Client:* Oil India Limited (OIL) | *Cutoff:* September 2026
----------------------------------------
*Project Health Index:* 84/100 (STABLE / CONTROLLED DELAY)
*EVM Performance:*
• SPI: 0.94 (-14 Days critical path delta)
• CPI: 0.98 (-₹5.40 Cr cost variance)
*Progress Status:*
• Physical Planned: 68.5% | Actual Validated: 62.4% (-6.1% gap)
• Financial Spent: ₹1,530 Cr of ₹2,450 Cr Sanctioned (62.4%)
*Top Critical Blocker:*
• River Brahmaputra HDD-04 (-14 Days, Float -8D) - Rig 02 mobilized.
*Weather Impact:*
• 7.5 Days monsoon stoppage (FIDIC Cl. 8.4(c) certified)
----------------------------------------
*Generated via Nirmaan OS Digital Construction Platform*
Verification Hash: e3b0c44298fc1c14...
''';
  }

  Widget _buildShareOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  void _printSignOffSheet() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return _SignOffSheetDialog(
          template: _currentTemplateMeta,
          period: _selectedPeriod,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build Method
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Executive Progress Dossier',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Consumer<AppProvider>(
              builder: (_, provider, child) {
                final proj = provider.currentProject;
                final code = proj?.code ?? 'OIL-PL-024';
                return Text(
                  '$code • Export & Formal Dossier Engine',
                  style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'FIDIC Cl. 4.21 Compliance Guide',
            icon: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
            onPressed: _showComplianceGuideDialog,
          ),
          IconButton(
            tooltip: 'Quick Refresh',
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('EVM metrics & critical path synchronized with live database.'),
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Project Context Banner
            _buildProjectContextBanner(),
            const SizedBox(height: 20),

            // 2. Report Templates Selector
            _buildTemplateSelectorHeader(),
            const SizedBox(height: 12),
            _buildTemplatesGrid(),
            const SizedBox(height: 24),

            // 3. Live Report Preview Card (Core Required Widget)
            _buildLiveReportPreviewCard(),
            const SizedBox(height: 24),

            // 4. Dossier Configuration & Inclusions
            _buildDossierOptionsSection(),
            const SizedBox(height: 24),

            // 5. Formal Sheet Preview (Simulated A4 Paper)
            _buildSheetPreviewSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionToolbar(),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Project Context Banner
  // ---------------------------------------------------------------------------
  Widget _buildProjectContextBanner() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final project = provider.currentProject;
        final projectName = project?.name ?? 'Trunk Crude Oil Pipeline Expansion';
        final client = project?.client ?? 'Oil India Limited (OIL)';
        final contractType = project?.contractType ?? 'FIDIC Red Book Cl. 8.4';

        return Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.corporate_fare, color: AppTheme.primaryLight, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                projectName,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const StatusBadge(status: 'ON_TRACK'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$client • $contractType',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.border, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_note, color: AppTheme.textMuted, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Reporting Period:',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          isDense: true,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceCard,
                          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryLight),
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          items: _periods.map((period) {
                            return DropdownMenuItem<String>(
                              value: period,
                              child: Text(
                                period,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedPeriod = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Report Templates Selector
  // ---------------------------------------------------------------------------
  Widget _buildTemplateSelectorHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Templates',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Select formal export standard and target stakeholders',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '4 Formats Ready',
            style: TextStyle(color: AppTheme.secondary.withAlpha(220), fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _templates.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final tmpl = _templates[index];
        final isSelected = tmpl.type == _selectedTemplate;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedTemplate = tmpl.type;
              _activeSheetPageIndex = 0;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? tmpl.accentColor.withAlpha(25) : AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? tmpl.accentColor : AppTheme.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? tmpl.accentColor.withAlpha(40) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        tmpl.icon,
                        color: isSelected ? tmpl.accentColor : AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tmpl.accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Text(
                        '${tmpl.estimatedPages}p',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tmpl.title,
                      style: TextStyle(
                        color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tmpl.standardCode,
                      style: TextStyle(
                        color: isSelected ? tmpl.accentColor : AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Live Report Preview Card (Core Required Widget)
  // ---------------------------------------------------------------------------
  Widget _buildLiveReportPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: const Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LIVE REPORT PREVIEW',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentTemplateMeta.accentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _currentTemplateMeta.accentColor.withAlpha(80)),
                  ),
                  child: Text(
                    _currentTemplateMeta.shortCode,
                    style: TextStyle(
                      color: _currentTemplateMeta.accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // (1) PROJECT HEALTH INDEX (84/100)
                _buildHealthIndexSection(),
                const Divider(color: AppTheme.border, height: 32),

                // (2) SPI/CPI TREND
                _buildSpiCpiTrendSection(),
                const Divider(color: AppTheme.border, height: 32),

                // (3) PHYSICAL VS FINANCIAL PROGRESS %
                _buildPhysicalVsFinancialSection(),
                const Divider(color: AppTheme.border, height: 32),

                // (4) TOP 3 CRITICAL PATH BLOCKERS
                _buildCriticalPathBlockersSection(),
                const Divider(color: AppTheme.border, height: 32),

                // (5) WEATHER STOPPAGES
                _buildWeatherStoppagesSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3.1 Project Health Index
  Widget _buildHealthIndexSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Project Health Index',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.tertiary.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'STABLE • CONTROLLED DELAY',
                style: TextStyle(
                  color: AppTheme.tertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Indicator
            CircularPercentIndicator(
              radius: 46.0,
              lineWidth: 9.0,
              percent: 0.84,
              animation: true,
              center: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '84',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              progressColor: const Color(0xFF4EDEA3),
              backgroundColor: AppTheme.surfaceContainerHigh,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(width: 18),
            // Health Breakdown Pillars
            Expanded(
              child: Column(
                children: [
                  _buildHealthPillarRow('Schedule Health (SPI: 0.94)', 0.82, '82/100', AppTheme.secondary),
                  const SizedBox(height: 6),
                  _buildHealthPillarRow('Cost Efficiency (CPI: 0.98)', 0.88, '88/100', AppTheme.primaryLight),
                  const SizedBox(height: 6),
                  _buildHealthPillarRow('Safety & HSE Compliance', 0.96, '96/100', AppTheme.tertiary),
                  const SizedBox(height: 6),
                  _buildHealthPillarRow('QA/QC Acceptance Rate', 0.92, '92/100', const Color(0xFF818CF8)),
                  const SizedBox(height: 6),
                  _buildHealthPillarRow('Critical Path Float Buffer', 0.64, '64/100', const Color(0xFFFF5252)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthPillarRow(String label, double percent, String score, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          score,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 3.2 SPI/CPI Trend Section
  Widget _buildSpiCpiTrendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPI & CPI Trend (Earned Value)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Historical variance from baseline (Apr - Sep 2026)',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem('SPI (0.94)', AppTheme.secondary),
                const SizedBox(width: 8),
                _buildLegendItem('CPI (0.98)', AppTheme.primaryLight),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Mini S-curve Chart
        Container(
          height: 120,
          padding: const EdgeInsets.fromLTRB(4, 12, 12, 6),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.05,
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: AppTheme.border,
                  strokeWidth: 0.8,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      const months = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'];
                      final idx = value.toInt();
                      if (idx >= 0 && idx < months.length) {
                        return Text(
                          months[idx],
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 0.05,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(2),
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 5,
              minY: 0.85,
              maxY: 1.05,
              lineBarsData: [
                // Baseline target line (1.00)
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 1.0),
                    FlSpot(5, 1.0),
                  ],
                  isCurved: false,
                  color: AppTheme.textMuted.withAlpha(90),
                  barWidth: 1,
                  dotData: const FlDotData(show: false),
                  dashArray: [4, 4],
                ),
                // SPI Line (Amber)
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 0.90),
                    FlSpot(1, 0.89),
                    FlSpot(2, 0.91),
                    FlSpot(3, 0.93),
                    FlSpot(4, 0.95),
                    FlSpot(5, 0.94),
                  ],
                  isCurved: true,
                  color: AppTheme.secondary,
                  barWidth: 2.2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                ),
                // CPI Line (Primary Light)
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 0.94),
                    FlSpot(1, 0.93),
                    FlSpot(2, 0.95),
                    FlSpot(3, 0.97),
                    FlSpot(4, 0.98),
                    FlSpot(5, 0.98),
                  ],
                  isCurved: true,
                  color: AppTheme.primaryLight,
                  barWidth: 2.2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Mini status indicators
        Row(
          children: [
            Expanded(
              child: _buildMetricMiniBadge(
                label: 'Schedule Lag',
                value: '-14 Days behind baseline',
                badgeText: 'SPI: 0.94',
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricMiniBadge(
                label: 'Cost Overrun',
                value: '-₹5.40 Cr variance',
                badgeText: 'CPI: 0.98',
                color: AppTheme.primaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMetricMiniBadge({
    required String label,
    required String value,
    required String badgeText,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(badgeText, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 3.3 Physical vs Financial Progress %
  Widget _buildPhysicalVsFinancialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Physical vs Financial Progress %',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Triangulated Consensus',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Physical Progress
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Physical Work Executed',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Variance: -6.1%',
                    style: TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.685,
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF26396E)),
                      minHeight: 12,
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.624,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Validated Consensus: 62.4%',
                      style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Planned Target: 68.5%', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Financial Progress
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Financial Expenditure & Cashflow',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Budget: ₹2,450 Cr',
                    style: TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.624,
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Certified Spent: ₹1,530 Cr (62.4%)',
                      style: TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Unutilized: ₹920 Cr', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3.4 Top 3 Critical Path Blockers
  Widget _buildCriticalPathBlockersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Top 3 Critical Path Blockers',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withAlpha(35),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Negative Float Alert',
                style: TextStyle(color: Color(0xFFFF5252), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _criticalBlockers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final blk = _criticalBlockers[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: blk.severityColor.withAlpha(100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: blk.severityColor.withAlpha(35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          blk.severity,
                          style: TextStyle(
                            color: blk.severityColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          blk.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${blk.chainage} • ${blk.uwid}',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Impact: -${blk.daysImpacted}d (Float: ${blk.totalFloat}d)',
                        style: TextStyle(
                          color: blk.severityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.border, height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Root Cause: ',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          blk.rootCause,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mitigation: ',
                        style: TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          blk.mitigation,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // 3.5 Weather Stoppages
  Widget _buildWeatherStoppagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Icon(Icons.cloud_outlined, color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Adverse Weather Stoppages',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'FIDIC Cl. 8.4(c)',
                style: TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Month Stoppage', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        SizedBox(height: 2),
                        Text(
                          '7.5 Shift Days Lost',
                          style: TextStyle(color: Color(0xFFFF5252), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Precipitation Recorded', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        SizedBox(height: 2),
                        Text(
                          '342 mm (AWS-02)',
                          style: TextStyle(color: AppTheme.primaryLight, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Soil Saturation', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        SizedBox(height: 2),
                        Text(
                          '94% (Non-traversable)',
                          style: TextStyle(color: AppTheme.secondary, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.border, height: 16),
              const Text(
                'Telemetry Verified: Automated weather telemetry from AWS Station 02 confirms 342mm rainfall exceeding 10-year return threshold. Formal notice under FIDIC 8.4(c) served to Client on 22 Sep 2026.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Dossier Configuration & Inclusions
  // ---------------------------------------------------------------------------
  Widget _buildDossierOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dossier Attachments & Security',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Configure annexures to be compiled into the formal dossier PDF',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              _buildOptionSwitchTile(
                title: 'Include Drone Orthomosaic Maps',
                subtitle: 'Attaches LIDAR elevation scans & GIS chainage orthophotos',
                value: _includeDroneOrthomosaics,
                onChanged: (val) => setState(() => _includeDroneOrthomosaics = val),
              ),
              const Divider(color: AppTheme.border, height: 1),
              _buildOptionSwitchTile(
                title: 'Include Biometric Geofence Logs',
                subtitle: 'Appends 425 GPS-verified worker attendance proof sheets',
                value: _includeBiometricGpsLogs,
                onChanged: (val) => setState(() => _includeBiometricGpsLogs = val),
              ),
              const Divider(color: AppTheme.border, height: 1),
              _buildOptionSwitchTile(
                title: 'Include Raw Primavera XML Schedule',
                subtitle: 'Embeds raw P6 activity baseline & Gantt critical path records',
                value: _includeRawScheduleXml,
                onChanged: (val) => setState(() => _includeRawScheduleXml = val),
              ),
              const Divider(color: AppTheme.border, height: 1),
              _buildOptionSwitchTile(
                title: 'Append Cryptographic Hash Stamp (SHA-256)',
                subtitle: 'Guarantees legal admissibility under Indian Evidence Act & FIDIC DAB',
                value: _appendCryptographicStamp,
                onChanged: (val) => setState(() => _appendCryptographicStamp = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppTheme.primaryLight,
            activeTrackColor: AppTheme.primary.withAlpha(120),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.surface,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Formal Sheet Preview (Simulated A4 Paper)
  // ---------------------------------------------------------------------------
  Widget _buildSheetPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formal Dossier Page Preview',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Live rendering of generated A4 executive deliverable',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
                  onPressed: _activeSheetPageIndex > 0
                      ? () => setState(() => _activeSheetPageIndex--)
                      : null,
                ),
                Text(
                  'P.${_activeSheetPageIndex + 1}/${_currentTemplateMeta.estimatedPages}',
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  onPressed: _activeSheetPageIndex < _currentTemplateMeta.estimatedPages - 1
                      ? () => setState(() => _activeSheetPageIndex++)
                      : null,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Sheet Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(70),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildDossierSheetContent(),
        ),
      ],
    );
  }

  Widget _buildDossierSheetContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sheet Corporate Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'OIL INDIA LIMITED (OIL)',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Nirmaan OS Industrial Intelligence Engine',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                'DOC REF: NIRMAAN/OIL-PL-024/${_currentTemplateMeta.shortCode}',
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 9,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const Divider(color: AppTheme.border, height: 24),
        // Document Title Block
        Center(
          child: Column(
            children: [
              Text(
                _currentTemplateMeta.title.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'PROJECT: TRUNK CRUDE OIL PIPELINE EXPANSION (620 KM) • CONTRACT NO. OIL/PL/2026/024',
                style: const TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'REPORTING CUT-OFF PERIOD: $_selectedPeriod',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Executive Summary Narrative Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1.0 EXECUTIVE TRANSMITTAL SUMMARY',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This formal executive transmittal compiles primary progress records for the Trunk Crude Oil Pipeline Expansion project as of $_selectedPeriod. Project Health Index stands at 84/100, reflecting stable overall delivery with active mitigation on river crossing and RoW bottlenecks. Physical completion is 62.4% against a revised schedule baseline of 68.5% (-6.1% variance). Cumulative certified expenditure is ₹1,530 Cr against the ₹2,450 Cr authorized budget (CPI: 0.98).',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Tripartite Signatures Table
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '2.0 TRIPARTITE FORMAL ENDORSEMENTS',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSignatureBox(
                      role: 'Employer / Client',
                      name: 'Ananya Sen',
                      designation: 'Chief Engineer, OIL',
                      status: 'DIGITALLY VERIFIED',
                      statusColor: AppTheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSignatureBox(
                      role: 'Contractor JV',
                      name: 'Vikram Joshi',
                      designation: 'Project Director, JV',
                      status: 'DIGITALLY VERIFIED',
                      statusColor: AppTheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSignatureBox(
                      role: 'FIDIC Engineer (Cl. 3.1)',
                      name: 'Marcus Vance, P.E.',
                      designation: 'The Engineer, FIDIC',
                      status: 'PENDING SIGN-OFF',
                      statusColor: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Security Seal Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: AppTheme.tertiary),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'ISO 19650 BIM L2 • Tamper-evident SHA-256 seal embedded',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('dd-MMM-yyyy HH:mm').format(DateTime.now()),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignatureBox({
    required String role,
    required String name,
    required String designation,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role, style: const TextStyle(color: AppTheme.primaryLight, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(designation, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Action Toolbar (The 3 One-Tap Buttons)
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 1.2)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Button 1: Generate Formal PDF Dossier
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                label: Text(
                  'Generate Formal PDF Dossier (${_currentTemplateMeta.shortCode})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: _generateFormalPdfDossier,
              ),
            ),
            const SizedBox(height: 10),
            // Button 2 & 3: Share and Print
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 16, color: AppTheme.primaryLight),
                      label: const Text(
                        'Share via WhatsApp / Email',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: _shareViaWhatsAppEmail,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(Icons.print_rounded, size: 16, color: AppTheme.secondary),
                      label: const Text(
                        'Print Sign-Off Sheet',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: _printSignOffSheet,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showComplianceGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.gavel, color: AppTheme.secondary, size: 22),
            SizedBox(width: 8),
            Text(
              'FIDIC Cl. 4.21 Compliance',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FIDIC Red Book Clause 4.21 dictates monthly progress report standards required for valid interim payment certification:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text('• Charts and detailed descriptions of progress', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
            SizedBox(height: 4),
            Text('• Photographs showing the status of manufacture and site', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
            SizedBox(height: 4),
            Text('• Records of personnel and Contractor\'s Equipment', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
            SizedBox(height: 4),
            Text('• Quality assurance documents, test results, certificates', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
            SizedBox(height: 4),
            Text('• Safety statistics, hazardous incidents, environmental factors', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
            SizedBox(height: 4),
            Text('• Comparisons of actual and planned progress with EoT notices', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: AppTheme.primaryLight)),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Animated PDF Generation Progress Dialog
// -----------------------------------------------------------------------------
class _PdfGenerationProgressDialog extends StatefulWidget {
  final ReportTemplateMeta template;
  final String period;
  final VoidCallback onComplete;

  const _PdfGenerationProgressDialog({
    required this.template,
    required this.period,
    required this.onComplete,
  });

  @override
  State<_PdfGenerationProgressDialog> createState() => _PdfGenerationProgressDialogState();
}

class _PdfGenerationProgressDialogState extends State<_PdfGenerationProgressDialog> {
  int _currentStep = 0;
  final List<String> _steps = const [
    'Compiling WBS hierarchy & activity ledger...',
    'Synthesizing EVM S-Curve & cost indices...',
    'Hashing SHA-256 cryptographic seal...',
    'Rendering vector PDF pages & sign-off blocks...',
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (_currentStep < _steps.length - 1) {
        setState(() => _currentStep++);
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            widget.onComplete();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _steps.length;

    return AlertDialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border, width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.template.accentColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.template.icon,
              color: widget.template.accentColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Generating ${widget.template.shortCode} Dossier',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.period,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(widget.template.accentColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _steps[_currentStep],
              key: ValueKey<int>(_currentStep),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Printable Sign-Off Sheet Dialog
// -----------------------------------------------------------------------------
class _SignOffSheetDialog extends StatefulWidget {
  final ReportTemplateMeta template;
  final String period;

  const _SignOffSheetDialog({
    required this.template,
    required this.period,
  });

  @override
  State<_SignOffSheetDialog> createState() => _SignOffSheetDialogState();
}

class _SignOffSheetDialogState extends State<_SignOffSheetDialog> {
  bool _chkProgressVerified = true;
  bool _chkCriticalPathReviewed = true;
  bool _chkWeatherCorroborated = true;
  bool _chkQualityTestsApproved = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.print_rounded, color: AppTheme.secondary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Printable Sign-Off Sheet',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Tripartite Formal Approval & Legal Wet-Signature Sheet',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const Divider(color: AppTheme.border, height: 20),
              // Document identifiers
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _buildMetaRow('Project Title:', 'Trunk Crude Pipeline Expansion'),
                    const SizedBox(height: 4),
                    _buildMetaRow('Contract Reference:', 'OIL-PL-024 / FIDIC Red Book'),
                    const SizedBox(height: 4),
                    _buildMetaRow('Cutoff Period:', widget.period),
                    const SizedBox(height: 4),
                    _buildMetaRow('Template Ref:', widget.template.title),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Sign-off verification criteria
              const Text(
                'Sign-off Verification Criteria:',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildCheckboxRow('Physical vs Financial Progress variance verified (-6.1% schedule gap)', _chkProgressVerified, (v) => setState(() => _chkProgressVerified = v!)),
              _buildCheckboxRow('Top 3 critical path blockers reviewed with active mitigation plans', _chkCriticalPathReviewed, (v) => setState(() => _chkCriticalPathReviewed = v!)),
              _buildCheckboxRow('Adverse weather stoppages (7.5 days) corroborated with AWS telemetry', _chkWeatherCorroborated, (v) => setState(() => _chkWeatherCorroborated = v!)),
              _buildCheckboxRow('QA/QC NDT radiograph welds & field hydrotest certificates attached', _chkQualityTestsApproved, (v) => setState(() => _chkQualityTestsApproved = v!)),
              const SizedBox(height: 16),
              // Wet Signatories layout
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1. Employer (OIL)', style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('2. Contractor JV', style: TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('3. FIDIC Eng.', style: TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Text('Signature & Seal', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Text('Signature & Seal', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Text('Signature & Seal', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Print buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppTheme.border),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFFFF5252)),
                      label: const Text('Export Slip PDF', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sign-Off Slip exported to Downloads folder.'),
                            backgroundColor: AppTheme.surfaceContainerHigh,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.print, size: 16, color: Colors.black),
                      label: const Text('Send to Printer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.print_rounded, color: AppTheme.secondary, size: 18),
                                SizedBox(width: 8),
                                Text('Job queued: HP LaserJet Pro @ Site HQ Base Camp'),
                              ],
                            ),
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCheckboxRow(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              activeColor: AppTheme.primaryLight,
              checkColor: Colors.black,
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
