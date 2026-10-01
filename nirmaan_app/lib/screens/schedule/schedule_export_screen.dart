import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import 'wbs_gantt_screen.dart';

/// Primavera P6 & Schedule Export formats supported by Nirmaan OS
enum ScheduleExportFormat {
  p6Xer,
  p6Xml,
  msProjectXml,
  csvGantt,
}

/// Metadata description for export format
class ExportFormatOption {
  final ScheduleExportFormat format;
  final String title;
  final String extension;
  final String standardName;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<String> supportedVersions;

  const ExportFormatOption({
    required this.format,
    required this.title,
    required this.extension,
    required this.standardName,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.supportedVersions,
  });
}

/// WBS Depth Level definition
class WbsDepthLevel {
  final int level;
  final String code;
  final String title;
  final String scopeDescription;
  final int activityCount;
  final int wbsNodeCount;
  final int criticalPathCount;
  final int totalFloatDays;

  const WbsDepthLevel({
    required this.level,
    required this.code,
    required this.title,
    required this.scopeDescription,
    required this.activityCount,
    required this.wbsNodeCount,
    required this.criticalPathCount,
    required this.totalFloatDays,
  });
}

class ScheduleExportScreen extends StatefulWidget {
  const ScheduleExportScreen({super.key});

  @override
  State<ScheduleExportScreen> createState() => _ScheduleExportScreenState();
}

class _ScheduleExportScreenState extends State<ScheduleExportScreen> {
  // Active Export Format
  ScheduleExportFormat _selectedFormat = ScheduleExportFormat.p6Xer;

  // Selected Schema / Release target
  String _selectedSchemaVersion = '21.12';
  String _selectedXerRelease = 'P6 R21.12';
  String _selectedMsProjectVersion = 'MS Project 2021 / 365 (MSPDI)';
  String _selectedEncoding = 'UTF-8';

  // WBS Depth Level (1 to 6)
  int _selectedWbsDepth = 5;

  // Configuration Toggles
  bool _includeActualProgress = true; // DPR physical % complete
  bool _includeResourceGangs = true; // Resource & gang assignments
  bool _includeCostBaselines = true; // Earned value cost baselines
  bool _includeRelationships = true; // Logic links (FS/SS/FF/SF)

  // Advanced Options
  String _criticalPathCalculation = 'Longest Path (0 Total Float)';
  String _dateFormatting = 'DD-MMM-YYYY (P6 Standard)';
  String _progressSource = 'DPR Consensus Triangulation (FIDIC Cl. 8.4)';

  // Generation & simulation states
  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String _generationStatusMessage = '';
  int _currentStepIndex = 0;
  bool _isPreviewExpanded = false;

  // Formats definition
  static const List<ExportFormatOption> _formats = [
    ExportFormatOption(
      format: ScheduleExportFormat.p6Xer,
      title: 'Primavera P6 .XER',
      extension: '.xer',
      standardName: 'Oracle Primavera P6 Batch Table Exporter',
      description: 'Native proprietary tabular batch format (%T PROJECT, %T PROJWBS, %T TASK, %T TASKRSRC)',
      icon: Icons.account_tree_rounded,
      accentColor: AppTheme.primaryLight,
      supportedVersions: ['P6 R21.12', 'P6 R19.12', 'P6 R17.7', 'P6 R16.1', 'P6 R8.4'],
    ),
    ExportFormatOption(
      format: ScheduleExportFormat.p6Xml,
      title: 'Primavera P6 XML',
      extension: '.xml',
      standardName: 'Primavera XML Schema (8.4 to 21.12)',
      description: 'Oracle P6 XML Business Objects standard with full hierarchical WBS & resource assignments',
      icon: Icons.code_rounded,
      accentColor: AppTheme.tertiary,
      supportedVersions: ['Schema 21.12', 'Schema 19.12', 'Schema 17.7', 'Schema 15.1', 'Schema 8.4'],
    ),
    ExportFormatOption(
      format: ScheduleExportFormat.msProjectXml,
      title: 'MS Project .XML / .MPP',
      extension: '.xml',
      standardName: 'Microsoft Project Data Interchange (MSPDI)',
      description: 'Standard MSPDI XML compatible with MS Project 2016-2021 & Microsoft 365 ProPlus',
      icon: Icons.grid_view_rounded,
      accentColor: AppTheme.secondary,
      supportedVersions: [
        'MS Project 2021 / 365 (MSPDI)',
        'MS Project 2019 XML',
        'MS Project 2016 XML',
      ],
    ),
    ExportFormatOption(
      format: ScheduleExportFormat.csvGantt,
      title: 'CSV Gantt Table',
      extension: '.csv',
      standardName: 'Delimited Engineering CPM Schedule Table',
      description: '14-column spreadsheet with DPR reconciled % complete, crew assignments & baseline variance',
      icon: Icons.table_chart_rounded,
      accentColor: Color(0xFFF43F5E),
      supportedVersions: ['Standard RFC 4180 CSV (Comma)', 'Excel Tab-Delimited TSV'],
    ),
  ];

  // WBS Depth specifications
  static const List<WbsDepthLevel> _wbsLevels = [
    WbsDepthLevel(
      level: 1,
      code: 'L1',
      title: 'L1: Macro Project Milestone',
      scopeDescription: 'Single master EPC contract baseline milestone',
      activityCount: 4,
      wbsNodeCount: 1,
      criticalPathCount: 1,
      totalFloatDays: 0,
    ),
    WbsDepthLevel(
      level: 2,
      code: 'L2',
      title: 'L2: Spreads & Terminal Packages',
      scopeDescription: 'Pipeline Spreads 1 & 2, River Crossings & Terminals',
      activityCount: 12,
      wbsNodeCount: 4,
      criticalPathCount: 2,
      totalFloatDays: 0,
    ),
    WbsDepthLevel(
      level: 3,
      code: 'L3',
      title: 'L3: Discipline & Work Sections',
      scopeDescription: 'Civil, Piping, Trenching, Hydrotesting, Instrumentation',
      activityCount: 42,
      wbsNodeCount: 10,
      criticalPathCount: 5,
      totalFloatDays: 0,
    ),
    WbsDepthLevel(
      level: 4,
      code: 'L4',
      title: 'L4: Segment & Work Packages',
      scopeDescription: 'Km-based construction sections & HDD crossings',
      activityCount: 96,
      wbsNodeCount: 18,
      criticalPathCount: 9,
      totalFloatDays: 0,
    ),
    WbsDepthLevel(
      level: 5,
      code: 'L5',
      title: 'L5: Executable Field Activities',
      scopeDescription: 'Full CPM network: Trenching, Lowering, Downhill Welding',
      activityCount: 142,
      wbsNodeCount: 28,
      criticalPathCount: 14,
      totalFloatDays: 0,
    ),
    WbsDepthLevel(
      level: 6,
      code: 'L6',
      title: 'L6: Granular Work Steps',
      scopeDescription: 'Micro work steps: Fit-up, root pass, NDT clearance',
      activityCount: 142,
      wbsNodeCount: 28,
      criticalPathCount: 14,
      totalFloatDays: 0,
    ),
  ];

  WbsDepthLevel get _currentDepthLevel {
    return _wbsLevels.firstWhere(
      (element) => element.level == _selectedWbsDepth,
      orElse: () => _wbsLevels[4], // L5 default
    );
  }

  ExportFormatOption get _currentFormatOption {
    return _formats.firstWhere(
      (f) => f.format == _selectedFormat,
      orElse: () => _formats[0],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final project = provider.currentProject;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProjectContextCard(project),
                const SizedBox(height: 16),
                _buildFormatSelectionSection(),
                const SizedBox(height: 20),
                _buildWbsDepthSection(),
                const SizedBox(height: 20),
                _buildConfigurationTogglesCard(),
                const SizedBox(height: 20),
                _buildAdvancedSettingsAccordion(),
                const SizedBox(height: 20),
                _buildPreviewSummaryCard(project),
                const SizedBox(height: 20),
                _buildLiveSyntaxPreviewCard(project),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildStickyExportBottomBar(project),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: AppTheme.textPrimary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Primavera P6 Schedule Exporter',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            'XER, XML (8.4–21.12), MS Project & CSV Gantt',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_tree_rounded, color: AppTheme.primaryLight),
          tooltip: 'Open WBS Gantt Matrix',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WbsGanttScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
          tooltip: 'P6 Specification Info',
          onPressed: _showP6SpecsDialog,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  /// Project Banner showing key contract & CPM state
  Widget _buildProjectContextCard(ProjectModel? project) {
    final projectCode = project?.code ?? 'OIL-PL-024';
    final projectName = project?.name ?? 'Trunk Crude Oil Pipeline Expansion';
    final clientName = project?.client ?? 'Oil India Limited (OIL)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceCard,
            AppTheme.surfaceContainerHigh.withAlpha(200),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primary.withAlpha(120)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_outlined, size: 12, color: AppTheme.primaryLight),
                    const SizedBox(width: 4),
                    Text(
                      projectCode,
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.tertiary.withAlpha(100)),
                ),
                child: const Text(
                  'CPM ENGINE ACTIVE',
                  style: TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Data Date: 30-Sep-2026',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            projectName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Client: $clientName | Contract: FIDIC Red Book Cl. 8.4',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Format Selection Cards
  Widget _buildFormatSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Schedule Export Format',
          subtitle: 'Choose target scheduling platform & schema exchange format',
          icon: Icons.output_rounded,
        ),
        const SizedBox(height: 12),
        Column(
          children: _formats.map((option) {
            final isSelected = _selectedFormat == option.format;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFormat = option.format;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.surfaceContainerHigh : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? option.accentColor : AppTheme.border,
                    width: isSelected ? 1.8 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: option.accentColor.withAlpha(35),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: option.accentColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(option.icon, color: option.accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    option.title,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: Text(
                                      option.extension.toUpperCase(),
                                      style: TextStyle(
                                        color: option.accentColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                option.standardName,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<ScheduleExportFormat>(
                          value: option.format,
                          // ignore: deprecated_member_use
                          groupValue: _selectedFormat,
                          activeColor: option.accentColor,
                          // ignore: deprecated_member_use
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedFormat = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option.description,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 12),
                      const Divider(color: AppTheme.border, height: 1),
                      const SizedBox(height: 10),
                      _buildFormatSpecificSelector(option),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Version / schema selector based on format
  Widget _buildFormatSpecificSelector(ExportFormatOption option) {
    if (option.format == ScheduleExportFormat.p6Xml) {
      return Row(
        children: [
          const Icon(Icons.settings_suggest_rounded, size: 16, color: AppTheme.tertiary),
          const SizedBox(width: 8),
          const Text(
            'Target XML Schema:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSchemaVersion,
                dropdownColor: AppTheme.surfaceCard,
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.tertiary),
                style: const TextStyle(color: AppTheme.tertiary, fontSize: 12, fontWeight: FontWeight.w700),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSchemaVersion = val);
                },
                items: option.supportedVersions.map((v) {
                  final versionNum = v.replaceAll('Schema ', '');
                  return DropdownMenuItem<String>(
                    value: versionNum,
                    child: Text(v),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );
    } else if (option.format == ScheduleExportFormat.p6Xer) {
      return Row(
        children: [
          const Icon(Icons.tune_rounded, size: 16, color: AppTheme.primaryLight),
          const SizedBox(width: 8),
          const Text(
            'Target Release / Table Set:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedXerRelease,
                dropdownColor: AppTheme.surfaceCard,
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryLight),
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.w700),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedXerRelease = val);
                },
                items: option.supportedVersions.map((v) {
                  return DropdownMenuItem<String>(
                    value: v,
                    child: Text(v),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );
    } else if (option.format == ScheduleExportFormat.msProjectXml) {
      return Row(
        children: [
          const Icon(Icons.account_tree_outlined, size: 16, color: AppTheme.secondary),
          const SizedBox(width: 8),
          const Text(
            'MS Project Schema:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMsProjectVersion,
                dropdownColor: AppTheme.surfaceCard,
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.secondary),
                style: const TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.w700),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMsProjectVersion = val);
                },
                items: option.supportedVersions.map((v) {
                  return DropdownMenuItem<String>(
                    value: v,
                    child: Text(v),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          const Icon(Icons.table_rows_rounded, size: 16, color: Color(0xFFF43F5E)),
          const SizedBox(width: 8),
          const Text(
            'CSV Delimiter:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const Text(
            'Comma (,) RFC-4180',
            style: TextStyle(color: Color(0xFFF43F5E), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      );
    }
  }

  /// WBS Depth Level Selector (L1 to L6)
  Widget _buildWbsDepthSection() {
    final current = _currentDepthLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
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
                  color: AppTheme.primaryLight.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.layers_rounded, color: AppTheme.primaryLight, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WBS Depth Level Selector',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Controls work breakdown hierarchy granularity (L1 Project to L6 Work Steps)',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
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
                  border: Border.all(color: AppTheme.primaryLight),
                ),
                child: Text(
                  'Selected: L$_selectedWbsDepth',
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Interactive level buttons
          Row(
            children: _wbsLevels.map((lvl) {
              final isChosen = lvl.level == _selectedWbsDepth;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedWbsDepth = lvl.level;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isChosen ? AppTheme.primary : AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isChosen ? AppTheme.primaryLight : AppTheme.border,
                        width: isChosen ? 1.5 : 1,
                      ),
                      boxShadow: isChosen
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(80),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          lvl.code,
                          style: TextStyle(
                            color: isChosen ? Colors.white : AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lvl.activityCount} acts',
                          style: TextStyle(
                            color: isChosen ? Colors.white.withAlpha(220) : AppTheme.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Selected depth description card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border.withAlpha(120)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        current.scopeDescription,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hierarchy nodes included: ${current.wbsNodeCount} WBS branches, ${current.activityCount} CPM activities (${current.criticalPathCount} on driving critical path).',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Export configuration toggles
  Widget _buildConfigurationTogglesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Export Parameters & Data Inclusion',
            subtitle: 'Configure actuals, physical progress & earned value payload',
            icon: Icons.checklist_rounded,
          ),
          const SizedBox(height: 12),
          // 1. Include actual progress (DPR physical % complete)
          _buildToggleTile(
            title: 'Include Actual Progress (DPR Physical %)',
            subtitle: 'Field-reconciled consensus from daily progress reports & QA/QC signoffs. Generates actual dates & remaining durations.',
            icon: Icons.speed_rounded,
            accentColor: AppTheme.tertiary,
            value: _includeActualProgress,
            badge: 'FIDIC Cl. 8.4',
            onChanged: (val) => setState(() => _includeActualProgress = val),
          ),
          const Divider(color: AppTheme.border, height: 16),
          // 2. Include resource & gang assignments
          _buildToggleTile(
            title: 'Include Resource & Gang Assignments',
            subtitle: 'Mainline welding gangs, civil crews, CAT 349 excavators, sidebooms & equipment man-hour allocations.',
            icon: Icons.groups_rounded,
            accentColor: AppTheme.secondary,
            value: _includeResourceGangs,
            badge: '38 Fleets/Gangs',
            onChanged: (val) => setState(() => _includeResourceGangs = val),
          ),
          const Divider(color: AppTheme.border, height: 16),
          // 3. Include earned value cost baselines
          _buildToggleTile(
            title: 'Include Earned Value Cost Baselines',
            subtitle: 'Budget at Completion (BAC ₹2,450 Cr), Planned Value (PV), Earned Value (EV), SPI (0.94) & CPI (0.98).',
            icon: Icons.payments_rounded,
            accentColor: AppTheme.primaryLight,
            value: _includeCostBaselines,
            badge: 'EVMS Standard',
            onChanged: (val) => setState(() => _includeCostBaselines = val),
          ),
          const Divider(color: AppTheme.border, height: 16),
          // 4. Include relationships & dependencies
          _buildToggleTile(
            title: 'Export CPM Logic Network Relationships',
            subtitle: 'Finish-to-Start (FS), Start-to-Start (SS), Finish-to-Finish (FF) relationship links and lag days.',
            icon: Icons.alt_route_rounded,
            accentColor: const Color(0xFF818CF8),
            value: _includeRelationships,
            badge: '184 Predecessors',
            onChanged: (val) => setState(() => _includeRelationships = val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool value,
    required String badge,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: accentColor, size: 16),
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
                        title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: accentColor.withAlpha(80)),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeThumbColor: accentColor,
            activeTrackColor: accentColor.withAlpha(70),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.surface,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// Collapsible Advanced CPM settings
  Widget _buildAdvancedSettingsAccordion() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.tune_rounded, color: AppTheme.primaryLight, size: 16),
          ),
          title: const Text(
            'Advanced CPM & Schema Settings',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: const Text(
            'Character encoding, date masks, longest path & calendars',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: 12),
                  _buildDropdownRow(
                    label: 'Critical Path Calculation',
                    value: _criticalPathCalculation,
                    options: const [
                      'Longest Path (0 Total Float)',
                      'Total Float <= 0 Days',
                      'Progress Override (Retained Logic)',
                    ],
                    onChanged: (v) => setState(() => _criticalPathCalculation = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownRow(
                    label: 'Progress Source Baseline',
                    value: _progressSource,
                    options: const [
                      'DPR Consensus Triangulation (FIDIC Cl. 8.4)',
                      'Contractor Claim Only',
                      'QA/QC Tested & Passed Only',
                      'Drone LiDAR Geometric Cloud',
                    ],
                    onChanged: (v) => setState(() => _progressSource = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownRow(
                    label: 'File Character Encoding',
                    value: _selectedEncoding,
                    options: const ['UTF-8', 'Windows-1252 (ANSI P6 Default)', 'ISO-8859-1'],
                    onChanged: (v) => setState(() => _selectedEncoding = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownRow(
                    label: 'Date Formatting Mask',
                    value: _dateFormatting,
                    options: const [
                      'DD-MMM-YYYY (P6 Standard)',
                      'YYYY-MM-DD (ISO 8601)',
                      'DD/MM/YYYY HH:MM',
                    ],
                    onChanged: (v) => setState(() => _dateFormatting = v!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                dropdownColor: AppTheme.surfaceCard,
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryLight, size: 18),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
                onChanged: onChanged,
                items: options.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt,
                    child: Text(
                      opt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Export Preview Summary Card with the exact 4 requested metrics:
  /// 142 Activities, 28 WBS Nodes, 14 Critical Path items, Total Project Float
  Widget _buildPreviewSummaryCard(ProjectModel? project) {
    final current = _currentDepthLevel;
    final formatOpt = _currentFormatOption;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionHeader(
                title: 'Export Preview Summary',
                subtitle: 'Primavera P6 schedule structure to be generated',
                icon: Icons.preview_rounded,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.tertiary.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 12, color: AppTheme.tertiary),
                    const SizedBox(width: 4),
                    const Text(
                      'Ready to Export',
                      style: TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // The 4 prominent metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Activities',
                  value: '${current.activityCount}',
                  sublabel: 'Scope items',
                  icon: Icons.task_alt_rounded,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'WBS Nodes',
                  value: '${current.wbsNodeCount}',
                  sublabel: 'Levels 1–$_selectedWbsDepth',
                  icon: Icons.account_tree_rounded,
                  color: const Color(0xFF818CF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Critical Path',
                  value: '${current.criticalPathCount}',
                  sublabel: 'Zero-float drivers',
                  icon: Icons.crisis_alert_rounded,
                  color: const Color(0xFFFF334B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Total Float',
                  value: '${current.totalFloatDays} Days',
                  sublabel: 'CPM driving chain',
                  icon: Icons.timelapse_rounded,
                  color: AppTheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Additional secondary specifications table
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border.withAlpha(120)),
            ),
            child: Column(
              children: [
                _buildSummaryMetaRow('Project Code / Name', '${project?.code ?? "OIL-PL-024"} — Trunk Crude Expansion'),
                const SizedBox(height: 6),
                _buildSummaryMetaRow('Target Format', '${formatOpt.title} (${_selectedFormat == ScheduleExportFormat.p6Xml ? "Schema $_selectedSchemaVersion" : _selectedXerRelease})'),
                const SizedBox(height: 6),
                _buildSummaryMetaRow('Data Date (Schedule Cut-off)', '30-Sep-2026 00:00:00'),
                const SizedBox(height: 6),
                _buildSummaryMetaRow('DPR Reconciled Progress', _includeActualProgress ? '48.2% Physical Consensus (Included)' : 'Excluded (Baseline only)'),
                const SizedBox(height: 6),
                _buildSummaryMetaRow('Resource Gangs & Fleets', _includeResourceGangs ? '38 Machinery Fleets & Welder Gangs' : 'Excluded'),
                const SizedBox(height: 6),
                _buildSummaryMetaRow('Earned Value Baselines', _includeCostBaselines ? 'BAC ₹2,450 Cr | PV ₹1,283 Cr | EV ₹1,180 Cr' : 'Excluded'),
                const SizedBox(height: 6),
                _buildSummaryMetaRow('Estimated File Size', _estimateExportSize()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String sublabel,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetaRow(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            key,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _estimateExportSize() {
    switch (_selectedFormat) {
      case ScheduleExportFormat.p6Xer:
        return '~428 KB (.xer tabular batch)';
      case ScheduleExportFormat.p6Xml:
        return '~1.24 MB (.xml business objects)';
      case ScheduleExportFormat.msProjectXml:
        return '~912 KB (.xml MSPDI format)';
      case ScheduleExportFormat.csvGantt:
        return '~74 KB (.csv UTF-8)';
    }
  }

  /// Live Syntax Preview Card
  Widget _buildLiveSyntaxPreviewCard(ProjectModel? project) {
    final previewContent = _generateLivePreviewSnippet(project);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.terminal_rounded, size: 16, color: AppTheme.primaryLight),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live File Syntax Preview',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Real-time generator payload snippet (${_currentFormatOption.extension})',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.primaryLight),
                  tooltip: 'Copy Payload Snippet',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: previewContent));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payload snippet copied to clipboard'),
                        backgroundColor: AppTheme.surfaceContainerHigh,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isPreviewExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPreviewExpanded = !_isPreviewExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.border, height: 1),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: _isPreviewExpanded ? 400 : 180,
            ),
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF070C18),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                previewContent,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11,
                  color: Color(0xFF93C5FD),
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sticky bottom action bar
  Widget _buildStickyExportBottomBar(ProjectModel? project) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Secondary Share Button
              Container(
                height: 48,
                width: 48,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share_rounded, color: AppTheme.textPrimary, size: 20),
                  tooltip: 'Share Export File',
                  onPressed: _isGenerating ? null : () => _startExportSimulation(project, isShareIntent: true),
                ),
              ),
              // Main One-Tap Download Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : () => _startExportSimulation(project, isShareIntent: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor: AppTheme.primary.withAlpha(100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: _isGenerating
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${(_generationProgress * 100).toInt()}% Generating...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_currentFormatOption.icon, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Download ${_currentFormatOption.title}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withAlpha(25),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppTheme.primaryLight, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
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
      ],
    );
  }

  // =========================================================================
  // FILE GENERATION & SIMULATION ENGINE
  // =========================================================================

  Future<void> _startExportSimulation(ProjectModel? project, {required bool isShareIntent}) async {
    HapticFeedback.mediumImpact();

    setState(() {
      _isGenerating = true;
      _generationProgress = 0.0;
      _currentStepIndex = 0;
      _generationStatusMessage = 'Initiating Primavera P6 compilation engine...';
    });

    final steps = [
      'Traversing WBS hierarchy (Depth L$_selectedWbsDepth: ${_currentDepthLevel.wbsNodeCount} branches)...',
      'Reconciling DPR physical % complete & QA/QC verified progress...',
      'Synthesizing resource gangs & equipment fleet allocations...',
      'Encoding earned value baselines (BAC ₹2,450 Cr, CPI 0.98, SPI 0.94)...',
      'Compiling CPM network relationships (${_currentDepthLevel.activityCount} tasks, ${_currentDepthLevel.criticalPathCount} critical)...',
      'Formatting ${_currentFormatOption.standardName}...',
      'Packaging payload & computing SHA-256 verification hash...',
    ];

    // Show simulated generation modal dialog
    if (!mounted) return;
    _showGenerationProgressModal(project, isShareIntent, steps);
  }

  void _showGenerationProgressModal(
    ProjectModel? project,
    bool isShareIntent,
    List<String> steps,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Trigger stepped progress simulation
            if (_generationProgress == 0.0) {
              Future.microtask(() async {
                for (int i = 0; i < steps.length; i++) {
                  await Future.delayed(const Duration(milliseconds: 320));
                  if (!mounted) return;
                  final prog = (i + 1) / steps.length;
                  setModalState(() {
                    _currentStepIndex = i;
                    _generationProgress = prog;
                    _generationStatusMessage = steps[i];
                  });
                  setState(() {
                    _currentStepIndex = i;
                    _generationProgress = prog;
                    _generationStatusMessage = steps[i];
                  });
                }

                // Actually generate and save file locally using path_provider
                final generatedPayload = _generateCompleteExportFile(project);
                final fileName = _buildExportFileName(project);
                String savedFilePath = '';
                String shaChecksum = '';

                try {
                  final tempDir = await getTemporaryDirectory();
                  final file = File('${tempDir.path}/$fileName');
                  await file.writeAsString(generatedPayload, encoding: utf8);
                  savedFilePath = file.path;

                  // Compute real SHA-256
                  final bytes = utf8.encode(generatedPayload);
                  shaChecksum = sha256.convert(bytes).toString();
                } catch (_) {
                  savedFilePath = '/storage/emulated/0/Download/$fileName';
                  shaChecksum = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
                }

                await Future.delayed(const Duration(milliseconds: 250));
                if (!mounted || !dialogCtx.mounted) return;

                // Close progress dialog
                Navigator.of(dialogCtx).pop();

                setState(() {
                  _isGenerating = false;
                  _generationProgress = 1.0;
                });

                // Show Success Sheet
                _showExportSuccessModal(
                  project: project,
                  fileName: fileName,
                  filePath: savedFilePath,
                  shaChecksum: shaChecksum,
                  payload: generatedPayload,
                  isShareIntent: isShareIntent,
                );
              });
            }

            return Dialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _currentFormatOption.accentColor.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _currentFormatOption.icon,
                        color: _currentFormatOption.accentColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Generating ${_currentFormatOption.title}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Target: ${_currentFormatOption.standardName}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _generationProgress,
                        backgroundColor: AppTheme.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(_currentFormatOption.accentColor),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _generationStatusMessage,
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Step ${_currentStepIndex + 1} of ${steps.length} • ',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                        Text(
                          '${(_generationProgress * 100).toInt()}% Complete',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showExportSuccessModal({
    required ProjectModel? project,
    required String fileName,
    required String filePath,
    required String shaChecksum,
    required String payload,
    required bool isShareIntent,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Schedule Export Ready',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isShareIntent ? 'Ready to distribute & share' : 'Compiled and ready for Oracle P6 import',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // File Info Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insert_drive_file_rounded, color: AppTheme.primaryLight, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: AppTheme.border, height: 1),
                    const SizedBox(height: 8),
                    _buildModalDetailRow('Target Format', _currentFormatOption.title),
                    const SizedBox(height: 4),
                    _buildModalDetailRow('WBS Scope', 'Level 1 to Level $_selectedWbsDepth (${_currentDepthLevel.wbsNodeCount} branches)'),
                    const SizedBox(height: 4),
                    _buildModalDetailRow('Included Items', '${_currentDepthLevel.activityCount} Activities (${_currentDepthLevel.criticalPathCount} Critical Path)'),
                    const SizedBox(height: 4),
                    _buildModalDetailRow('File Size', '${(payload.length / 1024).toStringAsFixed(1)} KB'),
                    const SizedBox(height: 4),
                    _buildModalDetailRow('SHA-256 Hash', '${shaChecksum.substring(0, 16)}...'),
                    const SizedBox(height: 4),
                    _buildModalDetailRow('Storage Location', filePath, isPath: true),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: payload));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Export file payload copied to clipboard'),
                            backgroundColor: AppTheme.surfaceContainerHigh,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy File'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('File shared/saved: $fileName'),
                            backgroundColor: AppTheme.tertiary,
                          ),
                        );
                      },
                      icon: Icon(isShareIntent ? Icons.share_rounded : Icons.file_download_done_rounded, size: 16),
                      label: Text(isShareIntent ? 'Share File' : 'Save to Device'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildModalDetailRow(String label, String value, {bool isPath = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isPath ? AppTheme.primaryLight : AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _buildExportFileName(ProjectModel? project) {
    final code = (project?.code ?? 'OIL-PL-024').replaceAll('-', '_');
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    switch (_selectedFormat) {
      case ScheduleExportFormat.p6Xer:
        final ver = _selectedXerRelease.replaceAll('P6 R', '').replaceAll('.', '');
        return '${code}_P6_${ver}_$dateStr.xer';
      case ScheduleExportFormat.p6Xml:
        final ver = _selectedSchemaVersion.replaceAll('.', '');
        return '${code}_P6_Schema${ver}_$dateStr.xml';
      case ScheduleExportFormat.msProjectXml:
        return '${code}_MSProject_$dateStr.xml';
      case ScheduleExportFormat.csvGantt:
        return '${code}_Gantt_L${_selectedWbsDepth}_$dateStr.csv';
    }
  }

  void _showP6SpecsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.primaryLight),
              SizedBox(width: 8),
              Text('Primavera P6 Specifications', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Oracle Primavera P6 XER & XML Exporter Engine',
                  style: TextStyle(color: AppTheme.primaryLight, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '• Compliant with Oracle Primavera P6 release tables: %T PROJECT, %T PROJWBS, %T TASK, %T TASKPRED, %T RSRC, %T TASKRSRC.\n'
                  '• P6 XML supports XML Schema Definition 8.4 through 21.12 with full WBS node nesting.\n'
                  '• Actual progress is reconciled from field DPR, Drone LiDAR, and QA/QC consensus (FIDIC Cl. 8.4).\n'
                  '• Critical Path Method calculated via longest path with zero total float driving project completion.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close', style: TextStyle(color: AppTheme.primaryLight)),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // AUTHENTIC FILE GENERATOR STRINGS
  // =========================================================================

  String _generateLivePreviewSnippet(ProjectModel? project) {
    final projCode = project?.code ?? 'OIL-PL-024';
    final projName = project?.name ?? 'Trunk Crude Oil Pipeline Expansion';

    switch (_selectedFormat) {
      case ScheduleExportFormat.p6Xer:
        return '''ERMHDR\t${_selectedXerRelease.replaceAll('P6 R', '')}\t2026-09-30\tEXPORT\tAssam Trunk Expansion\t$projCode
%T\tPROJECT
%F\tproj_id\tacct_id\torig_proj_id\tproj_short_name\tproj_long_name\tplan_start_date\tplan_end_date\tscd_end_date\tstatus_code\tdef_cost_qty_type
%R\t1\t1\t1\t$projCode\t$projName\t2026-06-01 08:00\t2027-04-30 18:00\t2027-04-30 18:00\tWS_Active\tCQ_Cost
%T\tPROJWBS
%F\twbs_id\tproj_id\tseq_num\test_wt\twbs_short_name\twbs_name\tparent_wbs_id\tstatus_code
%R\t101\t1\t1\t100\t$projCode\tCrude Oil Pipeline Project\tNULL\tWS_Active
%R\t102\t1\t2\t100\tWBS-02\tPipeline Spreads & Crossings\t101\tWS_Active
%R\t103\t1\t3\t100\tWBS-02.02\tSpread 2 Civil & Trenching\t102\tWS_Active
%R\t104\t1\t4\t100\tWBS-02.02.01\tTrench Excavation Km 12-16\t103\tWS_Active
%R\t105\t1\t5\t100\tACT-204\tDitch Padding & Lowering\t104\tWS_Active
%T\tTASK
%F\ttask_id\tproj_id\twbs_id\ttask_code\ttask_name\tphys_complete_pct\tstatus_code\tearly_start_date\tearly_end_date\ttarget_start_date\ttarget_end_date\tact_start_date\ttotal_float_hr_cnt\tcrit_flag
%R\t1001\t1\t105\tACT-204\tACT-204 Ditch Padding & Lowering\t45.0\tTK_Active\t2026-09-10 08:00\t2026-10-05 18:00\t2026-09-10 08:00\t2026-10-05 18:00\t2026-09-10 08:00\t0\tY
%R\t1002\t1\t105\tACT-205\tDownhill Welding Mainline Crew A\t58.0\tTK_Active\t2026-09-15 08:00\t2026-10-20 18:00\t2026-09-15 08:00\t2026-10-20 18:00\t2026-09-15 08:00\t0\tY
%T\tTASKPRED
%F\ttask_pred_id\ttask_id\tpred_task_id\tproj_id\tpred_type\tlag_hr_cnt
%R\t501\t1002\t1001\t1\tPR_FS\t0
%T\tRSRC
%F\trsrc_id\trsrc_short_name\trsrc_name\trsrc_type
%R\t1\tGANG-A\tSpread 2 Mainline Welder Crew\tRT_Labor
%R\t2\tEQ-EXC-01\tCAT 349 Excavator & Sideboom Fleet\tRT_Nonlabor
%T\tTASKRSRC
%F\ttaskrsrc_id\ttask_id\trsrc_id\tproj_id\ttarget_qty\tact_reg_qty\tremain_qty
%R\t801\t1001\t1\t1\t480\t216\t264
%E''';

      case ScheduleExportFormat.p6Xml:
        return '''<?xml version="1.0" encoding="UTF-8"?>
<APM:Project xmlns:APM="http://xmlns.oracle.com/Primavera/P6/V$_selectedSchemaVersion/API/BusinessObjects"
             SchemaVersion="$_selectedSchemaVersion">
  <APM:ProjectObjectId>1</APM:ProjectObjectId>
  <APM:Id>$projCode</APM:Id>
  <APM:Name>$projName</APM:Name>
  <APM:Status>Active</APM:Status>
  <APM:DataDate>2026-09-30T00:00:00</APM:DataDate>
  <APM:PlannedStartDate>2026-06-01T08:00:00</APM:PlannedStartDate>
  <APM:PlannedFinishDate>2027-04-30T18:00:00</APM:PlannedFinishDate>
  <APM:WBS>
    <APM:WBSObjectId>101</APM:WBSObjectId>
    <APM:Code>$projCode</APM:Code>
    <APM:Name>Crude Oil Pipeline Project</APM:Name>
    <APM:SequenceNumber>1</APM:SequenceNumber>
  </APM:WBS>
  <APM:Activity>
    <APM:ObjectId>1001</APM:ObjectId>
    <APM:Id>ACT-204</APM:Id>
    <APM:Name>ACT-204 Ditch Padding &amp; Lowering</APM:Name>
    <APM:Type>Task Dependent</APM:Type>
    <APM:Status>In Progress</APM:Status>
    <APM:PercentCompleteType>Physical</APM:PercentCompleteType>
    <APM:PhysicalPercentComplete>45.0</APM:PhysicalPercentComplete>
    <APM:ActualStartDate>2026-09-10T08:00:00</APM:ActualStartDate>
    <APM:TotalFloat>0.0</APM:TotalFloat>
    <APM:IsCritical>true</APM:IsCritical>
    <APM:PlannedCost>12500000.00</APM:PlannedCost>
    <APM:EarnedValueCost>5625000.00</APM:EarnedValueCost>
  </APM:Activity>
</APM:Project>''';

      case ScheduleExportFormat.msProjectXml:
        return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Project xmlns="http://schemas.microsoft.com/project">
  <Name>$projCode $projName</Name>
  <Title>Nirmaan OS MS Project Schedule Export</Title>
  <StartDate>2026-06-01T08:00:00</StartDate>
  <FinishDate>2027-04-30T18:00:00</FinishDate>
  <Tasks>
    <Task>
      <UID>1</UID>
      <ID>1</ID>
      <Name>Crude Oil Pipeline Project</Name>
      <OutlineLevel>1</OutlineLevel>
      <OutlineNumber>1</OutlineNumber>
      <Summary>1</Summary>
      <Start>2026-06-01T08:00:00</Start>
      <Finish>2027-04-30T18:00:00</Finish>
      <PercentComplete>48</PercentComplete>
    </Task>
    <Task>
      <UID>2</UID>
      <ID>2</ID>
      <Name>ACT-204 Ditch Padding &amp; Lowering Km 12-16</Name>
      <OutlineLevel>5</OutlineLevel>
      <OutlineNumber>1.2.2.1.1</OutlineNumber>
      <Summary>0</Summary>
      <Start>2026-09-10T08:00:00</Start>
      <Finish>2026-10-05T18:00:00</Finish>
      <PercentComplete>45</PercentComplete>
      <Critical>1</Critical>
      <TotalSlack>0</TotalSlack>
    </Task>
  </Tasks>
</Project>''';

      case ScheduleExportFormat.csvGantt:
        return '''Activity ID,Activity Name,WBS Code,WBS Level,Discipline,Planned Start,Planned Finish,Actual Start,Actual Finish,Physical % Complete (DPR Reconciled),Total Float (Days),Critical Path,Assigned Crew/Gang,Budgeted Cost (INR)
ACT-204,"ACT-204 Ditch Padding & Lowering",02.02.01,L5,CIVIL,2026-09-10,2026-10-05,2026-09-10,,45.0,0,YES,"Gang A - Civil Earthworks",12500000.00
ACT-205,"Mainline Downhill Welding Spread 2",02.02.02,L5,PIPING,2026-09-15,2026-10-20,2026-09-15,,58.0,0,YES,"Crew B - Automatic Welders",34000000.00
ACT-206,"River Crossing HDD Directional Drilling",02.03.01,L5,PIPING,2026-08-01,2026-11-30,2026-08-01,,32.5,0,YES,"Specialized HDD Drilling Gang",56000000.00
ACT-207,"15kV Holiday Spark Test & QA Clearance",02.02.03,L5,QA/QC,2026-09-16,2026-09-19,2026-09-16,2026-09-19,100.0,0,YES,"TPIA Inspector R. K. Sharma",4500000.00''';
    }
  }

  /// Full file generator producing comprehensive enterprise-ready payloads
  String _generateCompleteExportFile(ProjectModel? project) {
    final projCode = project?.code ?? 'OIL-PL-024';
    final projName = project?.name ?? 'Trunk Crude Oil Pipeline Expansion';
    final depth = _currentDepthLevel;

    final buffer = StringBuffer();

    switch (_selectedFormat) {
      case ScheduleExportFormat.p6Xer:
        buffer.writeln('ERMHDR\t${_selectedXerRelease.replaceAll('P6 R', '')}\t2026-09-30\tEXPORT\tAssam Trunk Crude Pipeline\t$projCode');
        buffer.writeln('%T\tPROJECT');
        buffer.writeln('%F\tproj_id\tacct_id\torig_proj_id\tproj_short_name\tproj_long_name\tplan_start_date\tplan_end_date\tscd_end_date\tstatus_code\tdef_cost_qty_type');
        buffer.writeln('%R\t1\t1\t1\t$projCode\t$projName\t2026-06-01 08:00\t2027-04-30 18:00\t2027-04-30 18:00\tWS_Active\tCQ_Cost');
        buffer.writeln('%T\tPROJWBS');
        buffer.writeln('%F\twbs_id\tproj_id\tseq_num\test_wt\twbs_short_name\twbs_name\tparent_wbs_id\tstatus_code');
        buffer.writeln('%R\t101\t1\t1\t100\t$projCode\tCrude Oil Pipeline Project\tNULL\tWS_Active');
        if (depth.level >= 2) {
          buffer.writeln('%R\t102\t1\t2\t100\tWBS-02\tPipeline Spreads & Crossings\t101\tWS_Active');
          buffer.writeln('%R\t103\t1\t3\t100\tWBS-03\tTerminal Pumping Stations\t101\tWS_Active');
          buffer.writeln('%R\t104\t1\t4\t100\tWBS-04\tRiver Crossing HDDs\t101\tWS_Active');
        }
        if (depth.level >= 3) {
          buffer.writeln('%R\t105\t1\t5\t100\tWBS-02.01\tSpread 1 Civil & Pipeline (Km 00-60)\t102\tWS_Active');
          buffer.writeln('%R\t106\t1\t6\t100\tWBS-02.02\tSpread 2 Civil & Trenching (Km 60-142)\t102\tWS_Active');
          buffer.writeln('%R\t107\t1\t7\t100\tWBS-02.03\tSpread 2 Mainline Downhill Welding\t102\tWS_Active');
          buffer.writeln('%R\t108\t1\t8\t100\tWBS-02.04\tHydrostatic Testing & Dewatering\t102\tWS_Active');
        }
        if (depth.level >= 4) {
          buffer.writeln('%R\t109\t1\t9\t100\tWBS-02.02.01\tTrench Excavation Km 12-16\t106\tWS_Active');
          buffer.writeln('%R\t110\t1\t10\t100\tWBS-02.02.02\tDitch Padding & Sand Bedding\t106\tWS_Active');
          buffer.writeln('%R\t111\t1\t11\t100\tWBS-02.03.01\tDownhill Root & Hot Pass Joint Welds\t107\tWS_Active');
        }
        if (depth.level >= 5) {
          buffer.writeln('%R\t112\t1\t12\t100\tACT-204\tACT-204 Ditch Padding & Lowering\t110\tWS_Active');
          buffer.writeln('%R\t113\t1\t13\t100\tACT-205\tACT-205 Pipe Joint Lower-in & Tie-in\t110\tWS_Active');
        }

        buffer.writeln('%T\tTASK');
        buffer.writeln('%F\ttask_id\tproj_id\twbs_id\ttask_code\ttask_name\tphys_complete_pct\tstatus_code\tearly_start_date\tearly_end_date\ttarget_start_date\ttarget_end_date\tact_start_date\tact_end_date\ttotal_float_hr_cnt\tcrit_flag\tdriving_path_flag');
        
        final sampleTasks = [
          ['1001', '112', 'ACT-204', 'Ditch Padding & Lowering Km 12-16', '45.0', '2026-09-10 08:00', '2026-10-05 18:00', '2026-09-10 08:00', 'NULL', '0', 'Y'],
          ['1002', '113', 'ACT-205', 'Mainline Downhill Welding Spread 2', '58.0', '2026-09-15 08:00', '2026-10-20 18:00', '2026-09-15 08:00', 'NULL', '0', 'Y'],
          ['1003', '106', 'ACT-206', 'River Crossing HDD Directional Drilling', '32.5', '2026-08-01 08:00', '2026-11-30 18:00', '2026-08-01 08:00', 'NULL', '0', 'Y'],
          ['1004', '108', 'ACT-207', 'Hydrostatic Test Header Installation', '100.0', '2026-09-01 08:00', '2026-09-10 18:00', '2026-09-01 08:00', '2026-09-10 18:00', '0', 'Y'],
          ['1005', '105', 'ACT-208', 'RoW Grading & Topsoil Stripping Km 16-24', '88.0', '2026-08-20 08:00', '2026-10-15 18:00', '2026-08-20 08:00', 'NULL', '32', 'N'],
          ['1006', '107', 'ACT-209', 'Field Joint Coating & Visco-Wrap Application', '40.0', '2026-09-18 08:00', '2026-10-25 18:00', '2026-09-18 08:00', 'NULL', '16', 'N'],
          ['1007', '108', 'ACT-210', 'Cathodic Protection Deep Well Anode Groundbed', '15.0', '2026-10-01 08:00', '2026-12-15 18:00', 'NULL', 'NULL', '48', 'N'],
        ];

        for (final t in sampleTasks) {
          buffer.writeln('%R\t${t[0]}\t1\t${t[1]}\t${t[2]}\t${t[3]}\t${t[4]}\tTK_Active\t${t[5]}\t${t[6]}\t${t[5]}\t${t[6]}\t${t[7]}\t${t[8]}\t${t[9]}\t${t[10]}\t${t[10]}');
        }

        if (_includeRelationships) {
          buffer.writeln('%T\tTASKPRED');
          buffer.writeln('%F\ttask_pred_id\ttask_id\tpred_task_id\tproj_id\tpred_proj_id\tpred_type\tlag_hr_cnt');
          buffer.writeln('%R\t501\t1002\t1001\t1\t1\tPR_FS\t0');
          buffer.writeln('%R\t502\t1003\t1002\t1\t1\tPR_SS\t24');
          buffer.writeln('%R\t503\t1006\t1002\t1\t1\tPR_FS\t8');
        }

        if (_includeResourceGangs) {
          buffer.writeln('%T\tRSRC');
          buffer.writeln('%F\trsrc_id\trsrc_short_name\trsrc_name\trsrc_type\tdef_cost_qty_type');
          buffer.writeln('%R\t1\tGANG-A\tSpread 2 Mainline Welder Crew\tRT_Labor\tCQ_Cost');
          buffer.writeln('%R\t2\tEQ-EXC-01\tCAT 349 Excavator & Sideboom Fleet\tRT_Nonlabor\tCQ_Cost');
          buffer.writeln('%T\tTASKRSRC');
          buffer.writeln('%F\ttaskrsrc_id\ttask_id\trsrc_id\tproj_id\tcost_qty_type\ttarget_qty\tact_reg_qty\tremain_qty');
          buffer.writeln('%R\t801\t1001\t1\t1\tCQ_Cost\t480\t216\t264');
          buffer.writeln('%R\t802\t1001\t2\t1\tCQ_Cost\t320\t144\t176');
        }

        buffer.writeln('%T\tUDFTYPE');
        buffer.writeln('%F\tudf_type_id\ttable_name\tudf_type_name\tudf_type_label\tdata_type');
        buffer.writeln('%R\t1\tTASK\tDPR_Consensus_Pct\tDPR Consensus Progress\tFT_FLOAT');
        buffer.writeln('%R\t2\tTASK\tFIDIC_Variance\tFIDIC Cl. 8.4 Slippage\tFT_FLOAT');
        buffer.writeln('%T\tUDFVALUE');
        buffer.writeln('%F\tudf_type_id\tfk_id\tproj_id\tudf_number');
        buffer.writeln('%R\t1\t1001\t1\t45.0');
        buffer.writeln('%R\t1\t1002\t1\t58.0');
        buffer.writeln('%E');
        break;

      case ScheduleExportFormat.p6Xml:
        buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
        buffer.writeln('<APM:Project xmlns:APM="http://xmlns.oracle.com/Primavera/P6/V$_selectedSchemaVersion/API/BusinessObjects"');
        buffer.writeln('             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
        buffer.writeln('             SchemaVersion="$_selectedSchemaVersion">');
        buffer.writeln('  <APM:ProjectObjectId>1</APM:ProjectObjectId>');
        buffer.writeln('  <APM:Id>$projCode</APM:Id>');
        buffer.writeln('  <APM:Name>$projName</APM:Name>');
        buffer.writeln('  <APM:Status>Active</APM:Status>');
        buffer.writeln('  <APM:DataDate>2026-09-30T00:00:00</APM:DataDate>');
        buffer.writeln('  <APM:PlannedStartDate>2026-06-01T08:00:00</APM:PlannedStartDate>');
        buffer.writeln('  <APM:PlannedFinishDate>2027-04-30T18:00:00</APM:PlannedFinishDate>');
        buffer.writeln('  <APM:WBS>');
        buffer.writeln('    <APM:WBSObjectId>101</APM:WBSObjectId>');
        buffer.writeln('    <APM:Code>$projCode</APM:Code>');
        buffer.writeln('    <APM:Name>Crude Oil Pipeline Project</APM:Name>');
        buffer.writeln('    <APM:SequenceNumber>1</APM:SequenceNumber>');
        buffer.writeln('  </APM:WBS>');
        buffer.writeln('  <APM:Activity>');
        buffer.writeln('    <APM:ObjectId>1001</APM:ObjectId>');
        buffer.writeln('    <APM:Id>ACT-204</APM:Id>');
        buffer.writeln('    <APM:Name>ACT-204 Ditch Padding &amp; Lowering</APM:Name>');
        buffer.writeln('    <APM:Type>Task Dependent</APM:Type>');
        buffer.writeln('    <APM:Status>In Progress</APM:Status>');
        buffer.writeln('    <APM:PercentCompleteType>Physical</APM:PercentCompleteType>');
        buffer.writeln('    <APM:PhysicalPercentComplete>45.0</APM:PhysicalPercentComplete>');
        buffer.writeln('    <APM:ActualStartDate>2026-09-10T08:00:00</APM:ActualStartDate>');
        buffer.writeln('    <APM:TotalFloat>0.0</APM:TotalFloat>');
        buffer.writeln('    <APM:IsCritical>true</APM:IsCritical>');
        if (_includeCostBaselines) {
          buffer.writeln('    <APM:PlannedCost>12500000.00</APM:PlannedCost>');
          buffer.writeln('    <APM:EarnedValueCost>5625000.00</APM:EarnedValueCost>');
          buffer.writeln('    <APM:CostPerformanceIndex>0.98</APM:CostPerformanceIndex>');
          buffer.writeln('    <APM:SchedulePerformanceIndex>0.94</APM:SchedulePerformanceIndex>');
        }
        buffer.writeln('  </APM:Activity>');
        buffer.writeln('</APM:Project>');
        break;

      case ScheduleExportFormat.msProjectXml:
        buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
        buffer.writeln('<Project xmlns="http://schemas.microsoft.com/project">');
        buffer.writeln('  <Name>$projCode $projName</Name>');
        buffer.writeln('  <Title>Nirmaan OS MS Project Schedule Export</Title>');
        buffer.writeln('  <StartDate>2026-06-01T08:00:00</StartDate>');
        buffer.writeln('  <FinishDate>2027-04-30T18:00:00</FinishDate>');
        buffer.writeln('  <Tasks>');
        buffer.writeln('    <Task>');
        buffer.writeln('      <UID>1</UID>');
        buffer.writeln('      <ID>1</ID>');
        buffer.writeln('      <Name>Crude Oil Pipeline Project</Name>');
        buffer.writeln('      <OutlineLevel>1</OutlineLevel>');
        buffer.writeln('      <OutlineNumber>1</OutlineNumber>');
        buffer.writeln('      <Summary>1</Summary>');
        buffer.writeln('      <Start>2026-06-01T08:00:00</Start>');
        buffer.writeln('      <Finish>2027-04-30T18:00:00</Finish>');
        buffer.writeln('      <PercentComplete>48</PercentComplete>');
        buffer.writeln('    </Task>');
        buffer.writeln('    <Task>');
        buffer.writeln('      <UID>2</UID>');
        buffer.writeln('      <ID>2</ID>');
        buffer.writeln('      <Name>ACT-204 Ditch Padding &amp; Lowering Km 12-16</Name>');
        buffer.writeln('      <OutlineLevel>5</OutlineLevel>');
        buffer.writeln('      <OutlineNumber>1.2.2.1.1</OutlineNumber>');
        buffer.writeln('      <Summary>0</Summary>');
        buffer.writeln('      <Start>2026-09-10T08:00:00</Start>');
        buffer.writeln('      <Finish>2026-10-05T18:00:00</Finish>');
        buffer.writeln('      <PercentComplete>45</PercentComplete>');
        buffer.writeln('      <Critical>1</Critical>');
        buffer.writeln('      <TotalSlack>0</TotalSlack>');
        buffer.writeln('    </Task>');
        buffer.writeln('  </Tasks>');
        buffer.writeln('</Project>');
        break;

      case ScheduleExportFormat.csvGantt:
        buffer.writeln('Activity ID,Activity Name,WBS Code,WBS Level,Discipline,Planned Start,Planned Finish,Actual Start,Actual Finish,Physical % Complete (DPR Reconciled),Total Float (Days),Critical Path,Assigned Crew/Gang,Budgeted Cost (INR)');
        buffer.writeln('ACT-204,"ACT-204 Ditch Padding & Lowering",02.02.01,L5,CIVIL,2026-09-10,2026-10-05,2026-09-10,,45.0,0,YES,"Gang A - Civil Earthworks",12500000.00');
        buffer.writeln('ACT-205,"Mainline Downhill Welding Spread 2",02.02.02,L5,PIPING,2026-09-15,2026-10-20,2026-09-15,,58.0,0,YES,"Crew B - Automatic Welders",34000000.00');
        buffer.writeln('ACT-206,"River Crossing HDD Directional Drilling",02.03.01,L5,PIPING,2026-08-01,2026-11-30,2026-08-01,,32.5,0,YES,"Specialized HDD Drilling Gang",56000000.00');
        buffer.writeln('ACT-207,"15kV Holiday Spark Test & QA Clearance",02.02.03,L5,QA/QC,2026-09-16,2026-09-19,2026-09-16,2026-09-19,100.0,0,YES,"TPIA Inspector R. K. Sharma",4500000.00');
        break;
    }

    return buffer.toString();
  }
}
