import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nirmaan_app/providers/app_provider.dart';
import 'package:nirmaan_app/core/models/app_models.dart';
import 'package:nirmaan_app/core/localization/language_controller.dart';
import 'package:nirmaan_app/widgets/status_badge.dart';

// Navigation Destinations
import 'package:nirmaan_app/screens/conflicts/conflicts_screen.dart';
import 'package:nirmaan_app/screens/schedule/schedule_screen.dart';
import 'package:nirmaan_app/screens/dpr/dpr_screen.dart';
import 'package:nirmaan_app/screens/quality/aut_phased_array_screen.dart';
import 'package:nirmaan_app/screens/safety/ptw_live_screen.dart';
import 'package:nirmaan_app/screens/procurement/pipe_heat_tally_screen.dart';
import 'package:nirmaan_app/screens/operations/rtu_solar_microgrid_screen.dart';
import 'package:nirmaan_app/screens/finance/measurement_book_screen.dart';
import 'package:nirmaan_app/screens/map/digital_twin_site_map_screen.dart';
import 'package:nirmaan_app/screens/operations/drone_row_surveillance_screen.dart';
import 'package:nirmaan_app/screens/ai/gemini_brain_screen.dart';
import 'package:nirmaan_app/screens/ai/voice_assistant_screen.dart';
import 'package:nirmaan_app/screens/materials/qr_material_scanner_screen.dart';
import 'package:nirmaan_app/screens/quality/hydrotesting_screen.dart';
import 'package:nirmaan_app/screens/quality/golden_weld_certification_screen.dart';
import 'package:nirmaan_app/screens/audit/audit_screen.dart';
import 'package:nirmaan_app/screens/settings/settings_screen.dart';
import 'package:nirmaan_app/screens/more/more_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.projects.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0284C7)),
              );
            }

            final currentProject = provider.currentProject ??
                (provider.projects.isNotEmpty ? provider.projects.first : null);

            return RefreshIndicator(
              onRefresh: () => provider.loadInitialData(),
              color: const Color(0xFF0284C7),
              backgroundColor: const Color(0xFF111C38),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 1. STICKY BLINKIT / AMAZON STYLE APP BAR & SEARCH
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBrandingRow(context, currentProject),
                          const SizedBox(height: 12),
                          _buildOmniSearchBar(context),
                        ],
                      ),
                    ),
                  ),

                  // 2. INSTAGRAM-STYLE "LIVE SITE ASSET STORIES"
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: _buildLiveStoriesRow(context),
                    ),
                  ),

                  // 3. MAIN DASHBOARD CONTENT SHELVES
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Hero Truth Triangulation Consensus Card
                        _buildTruthTriangulationBanner(context),
                        const SizedBox(height: 16),

                        // Macro EVM S-Curve Health Card
                        if (currentProject != null) ...[
                          _buildProjectOverviewCard(context, currentProject),
                          const SizedBox(height: 20),
                        ],

                        // Blinkit-Style 8 Major Actionable Category Hubs
                        _buildSectionHeader(
                          context,
                          title: 'Core Industrial Modules',
                          subtitle: 'Direct 1-tap access to project domains',
                          actionLabel: 'View All 93',
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MoreScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildBlinkitCategoryGrid(context),
                        const SizedBox(height: 24),

                        // Amazon-Style Horizontal Shelf: Quick Field Tools
                        _buildSectionHeader(
                          context,
                          title: 'Quick Field Tools',
                          subtitle: 'High-frequency site inspection & telemetry',
                        ),
                        const SizedBox(height: 12),
                        _buildQuickFieldToolsShelf(context),
                        const SizedBox(height: 24),

                        // Real-time Field Telemetry Pulse
                        _buildSectionHeader(
                          context,
                          title: 'Live Site Edge Telemetry',
                          subtitle: 'Direct IoT & SCADA sensor readings',
                        ),
                        const SizedBox(height: 12),
                        _buildLiveTelemetryShelf(context),
                        const SizedBox(height: 24),

                        // Recent Activity & Audit Ledger
                        _buildSectionHeader(
                          context,
                          title: 'Recent Audit & Verification Log',
                          subtitle: 'Immutable SHA-256 event trail',
                          actionLabel: 'Audit Ledger',
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AuditScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildRecentActivityList(provider.auditLogs),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP BRANDING & LOCATION ROW (Blinkit / Amazon style)
  // ===========================================================================
  Widget _buildTopBrandingRow(BuildContext context, ProjectModel? project) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'OIL INDIA LIMITED',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'LIVE CLOUD',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project?.location ?? 'Duliajan-Numaligarh Crude Trunk • KM 142.8',
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Language selector button
            IconButton(
              icon: const Icon(Icons.translate_rounded, color: Color(0xFF94A3B8), size: 21),
              tooltip: 'Switch Language',
              onPressed: () => _showLanguageDialog(context),
            ),
            // Notifications / Audit log
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Color(0xFFF1F5F9), size: 22),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuditScreen()),
                    );
                  },
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            // Profile / Settings
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                ),
                child: const Center(
                  child: Text(
                    'OIL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // OMNI-SEARCH BAR (Blinkit / Amazon style)
  // ===========================================================================
  Widget _buildOmniSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111C38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2E5C), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search 93+ modules, joints, WBS, permits...',
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 21),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.mic_rounded, color: Color(0xFF10B981), size: 20),
                tooltip: 'Gemini Voice Assistant',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VoiceAssistantScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Color(0xFF94A3B8), size: 18),
                tooltip: 'Open Modules Hub',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MoreScreen()),
                  );
                },
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        onSubmitted: (query) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MoreScreen()),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // INSTAGRAM-STYLE "LIVE SITE ASSET STORIES"
  // ===========================================================================
  Widget _buildLiveStoriesRow(BuildContext context) {
    final stories = [
      _StoryItem(
        title: 'Satellite SAR',
        badge: '99.8%',
        icon: Icons.satellite_alt_rounded,
        ringColor: const Color(0xFF10B981),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConflictsScreen())),
      ),
      _StoryItem(
        title: 'Drone RoW',
        badge: 'Live',
        icon: Icons.flight_takeoff_rounded,
        ringColor: const Color(0xFF38BDF8),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DroneRowSurveillanceScreen())),
      ),
      _StoryItem(
        title: '3D GIS Map',
        badge: 'KM 142',
        icon: Icons.map_rounded,
        ringColor: const Color(0xFF818CF8),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitalTwinSiteMapScreen())),
      ),
      _StoryItem(
        title: 'SV-04 Solar',
        badge: '64.2 bar',
        icon: Icons.solar_power_rounded,
        ringColor: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RtuSolarMicrogridScreen())),
      ),
      _StoryItem(
        title: 'AUT Weld',
        badge: 'Passed',
        icon: Icons.biotech_rounded,
        ringColor: const Color(0xFF10B981),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AutPhasedArrayScreen())),
      ),
      _StoryItem(
        title: 'Live PTW',
        badge: '0% LEL',
        icon: Icons.health_and_safety_rounded,
        ringColor: const Color(0xFF38BDF8),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PtwLiveScreen())),
      ),
      _StoryItem(
        title: 'Gemini AI',
        badge: 'Ready',
        icon: Icons.auto_awesome_rounded,
        ringColor: const Color(0xFFA855F7),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GeminiBrainScreen())),
      ),
      _StoryItem(
        title: 'Heat Tally',
        badge: 'X70',
        icon: Icons.qr_code_scanner_rounded,
        ringColor: const Color(0xFF0284C7),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PipeHeatTallyScreen())),
      ),
    ];

    return SizedBox(
      height: 94,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = stories[index];
          return InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 66,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: item.ringColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: item.ringColor.withValues(alpha: 0.25),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFF162347),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: Colors.white, size: 22),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: item.ringColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.badge,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // HERO TRUTH TRIANGULATION CONSENSUS BANNER
  // ===========================================================================
  Widget _buildTruthTriangulationBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConflictsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F2B48), Color(0xFF111C38)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '5-Factor Truth Triangulation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '99.4% CONSENSUS',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Zero-Fraud Milestone Certification Active: Physical consensus achieved across Sentinel-1 SAR, Drone LiDAR, UHF RFID, SCADA, and Bureau Veritas QA/QC.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMicroStreamChip('Satellite SAR', '99.8%', const Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                _buildMicroStreamChip('Drone RTK', '99.2%', const Color(0xFF10B981)),
                const SizedBox(width: 6),
                _buildMicroStreamChip('RFID Tally', '1,420 Jts', const Color(0xFFF59E0B)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF38BDF8), size: 13),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicroStreamChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ===========================================================================
  // PROJECT MACRO OVERVIEW CARD
  // ===========================================================================
  Widget _buildProjectOverviewCard(BuildContext context, ProjectModel project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StatusBadge(status: project.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildEVMBlock('Schedule (SPI)', project.spi, project.spi >= 1.0)),
              const SizedBox(width: 12),
              Expanded(child: _buildEVMBlock('Cost (CPI)', project.cpi, project.cpi >= 1.0)),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.insights_rounded, color: Color(0xFF38BDF8), size: 18),
                        SizedBox(height: 3),
                        Text(
                          'P6 Gantt',
                          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEVMBlock(String title, double value, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111C38),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2E5C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: isPositive ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BLINKIT-STYLE 8 MAJOR CATEGORY HUBS GRID
  // ===========================================================================
  Widget _buildBlinkitCategoryGrid(BuildContext context) {
    final categories = [
      _CategoryTile(
        title: 'Truth Engine',
        subtitle: '5-Factor Consensus',
        icon: Icons.verified_user_rounded,
        gradient: const [Color(0xFF065F46), Color(0xFF047857)],
        iconColor: const Color(0xFF34D399),
        badge: '99.4%',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConflictsScreen())),
      ),
      _CategoryTile(
        title: 'Schedule & EVM',
        subtitle: 'P6 WBS & S-Curve',
        icon: Icons.calendar_month_rounded,
        gradient: const [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
        iconColor: const Color(0xFF60A5FA),
        badge: 'SPI 1.04',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen())),
      ),
      _CategoryTile(
        title: 'Daily DPR',
        subtitle: 'Shift Execution Logs',
        icon: Icons.assignment_rounded,
        gradient: const [Color(0xFF0F766E), Color(0xFF0D9488)],
        iconColor: const Color(0xFF2DD4BF),
        badge: 'Today',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DprScreen())),
      ),
      _CategoryTile(
        title: 'Quality & NDT',
        subtitle: 'AUT Phased Array',
        icon: Icons.biotech_rounded,
        gradient: const [Color(0xFF5B21B6), Color(0xFF6D28D9)],
        iconColor: const Color(0xFFA78BFA),
        badge: '0.0mm',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AutPhasedArrayScreen())),
      ),
      _CategoryTile(
        title: 'HSE & Safety',
        subtitle: 'Live PTW & Sensors',
        icon: Icons.health_and_safety_rounded,
        gradient: const [Color(0xFF831843), Color(0xFF9D174D)],
        iconColor: const Color(0xFFF472B6),
        badge: '0% LEL',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PtwLiveScreen())),
      ),
      _CategoryTile(
        title: 'Pipe Heat Tally',
        subtitle: 'API 5L X70 Barcodes',
        icon: Icons.view_in_ar_rounded,
        gradient: const [Color(0xFF92400E), Color(0xFFB45309)],
        iconColor: const Color(0xFFFBBF24),
        badge: '100%',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PipeHeatTallyScreen())),
      ),
      _CategoryTile(
        title: 'SCADA Solar RTU',
        subtitle: 'SV-04 Microgrid',
        icon: Icons.solar_power_rounded,
        gradient: const [Color(0xFF1E293B), Color(0xFF334155)],
        iconColor: const Color(0xFF38BDF8),
        badge: '64.2 bar',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RtuSolarMicrogridScreen())),
      ),
      _CategoryTile(
        title: 'Contracts & MB',
        subtitle: 'FIDIC Claims & Books',
        icon: Icons.gavel_rounded,
        gradient: const [Color(0xFF374151), Color(0xFF4B5563)],
        iconColor: const Color(0xFFE5E7EB),
        badge: 'Clause 8.4',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeasurementBookScreen())),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return InkWell(
          onTap: cat.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: cat.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(cat.icon, color: cat.iconColor, size: 20),
                    ),
                    if (cat.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          cat.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      cat.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10,
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

  // ===========================================================================
  // AMAZON-STYLE HORIZONTAL SHELF: QUICK TOOLS
  // ===========================================================================
  Widget _buildQuickFieldToolsShelf(BuildContext context) {
    final tools = [
      _ShelfActionItem(
        title: 'QR Material Scan',
        subtitle: 'Heat Tally Check',
        icon: Icons.qr_code_2_rounded,
        color: const Color(0xFF0284C7),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrMaterialScannerScreen())),
      ),
      _ShelfActionItem(
        title: 'Hydrostatic Test',
        subtitle: 'Hold Pressure Cert',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF38BDF8),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HydrotestingScreen())),
      ),
      _ShelfActionItem(
        title: 'Golden Weld QA',
        subtitle: 'Tie-in Certification',
        icon: Icons.offline_bolt_rounded,
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoldenWeldCertificationScreen())),
      ),
      _ShelfActionItem(
        title: '3D GIS Route',
        subtitle: 'Digital Twin Corridor',
        icon: Icons.explore_rounded,
        color: const Color(0xFF10B981),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitalTwinSiteMapScreen())),
      ),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tool = tools[index];
          return InkWell(
            onTap: tool.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF162347),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF26396E)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tool.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(tool.icon, color: tool.color, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tool.title,
                          style: const TextStyle(
                            color: Color(0xFFF1F5F9),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          tool.subtitle,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // LIVE TELEMETRY SHELF
  // ===========================================================================
  Widget _buildLiveTelemetryShelf(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111C38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2E5C)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTelemetryMetric(
            title: 'SV-04 Pressure',
            value: '64.2 bar',
            subtitle: 'API 6D Valve 100% Open',
            icon: Icons.speed_rounded,
            color: const Color(0xFF38BDF8),
          ),
          Container(width: 1, height: 40, color: const Color(0xFF26396E)),
          _buildTelemetryMetric(
            title: 'Gas Detector',
            value: '0% LEL',
            subtitle: 'H2S: 0.0 ppm (Safe)',
            icon: Icons.shield_rounded,
            color: const Color(0xFF10B981),
          ),
          Container(width: 1, height: 40, color: const Color(0xFF26396E)),
          _buildTelemetryMetric(
            title: 'Solar Microgrid',
            value: '94% SoC',
            subtitle: '4.8 kW Generation',
            icon: Icons.battery_charging_full_rounded,
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryMetric({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 8.5)),
      ],
    );
  }

  // ===========================================================================
  // RECENT ACTIVITY LIST
  // ===========================================================================
  Widget _buildRecentActivityList(List<Map<String, dynamic>> auditLogs) {
    if (auditLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF162347),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF26396E)),
        ),
        child: const Center(
          child: Text(
            'All events verified and cryptographically notarized.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      children: auditLogs.take(4).map((log) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF162347),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF26396E)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_rounded, color: Color(0xFF38BDF8), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['action']?.toString() ?? 'Verified Inspection',
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${log['user'] ?? 'Inspector'} • ${log['details'] ?? 'Cryptographic ledger signed'}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // SECTION HEADER WITH OPTIONAL ACTION
  // ===========================================================================
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // LANGUAGE DIALOG
  // ===========================================================================
  void _showLanguageDialog(BuildContext context) {
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'hi', 'name': 'हिंदी (Hindi)'},
      {'code': 'as', 'name': 'অসমীয়া (Assamese - Duliajan/Digboi)'},
      {'code': 'bn', 'name': 'বাংলা (Bengali)'},
      {'code': 'gu', 'name': 'ગુજરાતી (Gujarati)'},
      {'code': 'mr', 'name': 'मराठी (Marathi)'},
      {'code': 'ta', 'name': 'தமிழ் (Tamil)'},
      {'code': 'te', 'name': 'తెలుగు (Telugu)'},
      {'code': 'kn', 'name': 'ಕನ್ನಡ (Kannada)'},
      {'code': 'pa', 'name': 'ਪੰਜਾਬੀ (Punjabi)'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111C38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF26396E), borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Select Operational Language', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: languages.length,
                  itemBuilder: (c, idx) {
                    final lang = languages[idx];
                    return ListTile(
                      title: Text(lang['name']!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      trailing: LanguageController.instance.currentLocale.languageCode == lang['code']
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
                          : null,
                      onTap: () {
                        LanguageController.instance.changeLanguage(lang['code']!);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Data models for dashboard components
class _StoryItem {
  final String title;
  final String badge;
  final IconData icon;
  final Color ringColor;
  final VoidCallback onTap;

  _StoryItem({
    required this.title,
    required this.badge,
    required this.icon,
    required this.ringColor,
    required this.onTap,
  });
}

class _CategoryTile {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final Color iconColor;
  final String? badge;
  final VoidCallback onTap;

  _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.iconColor,
    this.badge,
    required this.onTap,
  });
}

class _ShelfActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ShelfActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
