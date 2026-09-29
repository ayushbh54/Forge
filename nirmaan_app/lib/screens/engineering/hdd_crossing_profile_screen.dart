import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Crossing Phase Enumeration
enum HddPhase {
  pilotBore(
    phaseNumber: 1,
    title: 'Pilot Bore Drilling',
    tooling: '12.25" PDC/TCI Bit + 6.75" Mud Motor (1.5° bend) + ParaTrack-2',
    progressRatio: 1.0,
    statusText: 'Completed',
    statusColor: AppTheme.tertiary,
    icon: Icons.explore_rounded,
    completedLengthM: 1450.0,
    totalLengthM: 1450.0,
  ),
  forwardReaming(
    phaseNumber: 2,
    title: 'Forward Reaming (24" / 36")',
    tooling: 'Pass 1: 24" Fly Cutter | Pass 2: 36" Hole Opener with Barrel Centralizers',
    progressRatio: 1.0,
    statusText: 'Completed',
    statusColor: AppTheme.tertiary,
    icon: Icons.autorenew_rounded,
    completedLengthM: 1450.0,
    totalLengthM: 1450.0,
  ),
  swabRun(
    phaseNumber: 3,
    title: 'Swab Run & Hole Conditioning',
    tooling: '34" Barrel Swab + Tail String + Low-solids PAC-LV polymer slurry sweep',
    progressRatio: 1.0,
    statusText: 'Completed',
    statusColor: AppTheme.tertiary,
    icon: Icons.cleaning_services_rounded,
    completedLengthM: 1450.0,
    totalLengthM: 1450.0,
  ),
  pipePullback(
    phaseNumber: 4,
    title: 'Pipe String Pullback (18" API 5L X70)',
    tooling: '300T Bearing Swivel + 36" Reamer Head + Roller Cradles + HK300PT Thruster',
    progressRatio: 0.6786, // ~984m out of 1450m
    statusText: 'In Progress (67.9%)',
    statusColor: AppTheme.secondary,
    icon: Icons.swap_horiz_rounded,
    completedLengthM: 984.0,
    totalLengthM: 1450.0,
  );

  final int phaseNumber;
  final String title;
  final String tooling;
  final double progressRatio;
  final String statusText;
  final Color statusColor;
  final IconData icon;
  final double completedLengthM;
  final double totalLengthM;

  const HddPhase({
    required this.phaseNumber,
    required this.title,
    required this.tooling,
    required this.progressRatio,
    required this.statusText,
    required this.statusColor,
    required this.icon,
    required this.completedLengthM,
    required this.totalLengthM,
  });
}

/// Survey Station Data Point for Steering Profile
class HddSurveyStation {
  final double md; // Measured Depth (meters)
  final double tvd; // True Vertical Depth (meters)
  final double pitch; // Inclination / Pitch (degrees)
  final double azimuth; // Azimuth (degrees)
  final double toolFace; // Roll / Tool Face (degrees, 0-360)
  final double mudPressure; // Annular mud pressure (psi)
  final String formation; // Strata type
  final String notes;

  const HddSurveyStation({
    required this.md,
    required this.tvd,
    required this.pitch,
    required this.azimuth,
    required this.toolFace,
    required this.mudPressure,
    required this.formation,
    this.notes = '',
  });
}

/// HDD River Crossing Geometry & Steering Screen
class HddCrossingProfileScreen extends StatefulWidget {
  const HddCrossingProfileScreen({super.key});

  @override
  State<HddCrossingProfileScreen> createState() => _HddCrossingProfileScreenState();
}

class _HddCrossingProfileScreenState extends State<HddCrossingProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Major Crossing Key Parameters
  static const String crossingName = 'Burhi Dihing River Crossing';
  static const String pipelineCorridor = 'Ch. 42+150 to Ch. 43+600 • Upper Assam Sector';
  static const double totalLengthM = 1450.0;
  static const double designScourClearanceM = 32.0;
  static const double maxAllowedPullLoadTons = 240.0;

  // Live Drill String Telemetry State
  double _currentMd = 984.0; // Current Measured Depth (m)
  double _currentTvd = 34.8; // True Vertical Depth (m)
  double _currentPitch = 1.4; // Pitch angle (degrees)
  double _currentAzimuth = 164.8; // Azimuth roll (degrees)
  double _currentToolFace = 22.0; // Tool Face roll (degrees)
  double _currentMudPressure = 485.0; // Annular mud pressure (psi)
  double _currentPullLoad = 142.0; // Current pull load (Tons)

  // Secondary Telemetry
  double _slurryFlowRate = 2450.0; // L/min
  double _spindleTorque = 28.5; // kNm
  double _penetrationSpeed = 18.2; // m/hr
  static const double _mudDensity = 1.18; // SG
  double _ballastWaterVolumeM3 = 124.0; // m3
  bool _thrusterActive = true;
  double _thrusterPushTons = 42.0;

  // Telemetry Simulation Animation
  bool _isLiveSimulating = false;
  double _pulsePhase = 0.0;
  double _scrubStationMd = 984.0; // Interactive profile scrubber

  // Active Phase Selection
  HddPhase _selectedPhase = HddPhase.pipePullback;

  // Survey Log List
  late List<HddSurveyStation> _surveyStations;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    _surveyStations = _generateInitialSurveyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<HddSurveyStation> _generateInitialSurveyData() {
    return const [
      HddSurveyStation(
        md: 0.0,
        tvd: 0.0,
        pitch: -11.5,
        azimuth: 165.0,
        toolFace: 0.0,
        mudPressure: 110.0,
        formation: 'Alluvial Loam',
        notes: 'North Bank Entry Pit punch-in (11.5° entry angle)',
      ),
      HddSurveyStation(
        md: 120.0,
        tvd: 22.4,
        pitch: -9.8,
        azimuth: 165.1,
        toolFace: 5.0,
        mudPressure: 215.0,
        formation: 'Sandy Silt',
        notes: 'Upper bend transition zone',
      ),
      HddSurveyStation(
        md: 280.0,
        tvd: 32.5,
        pitch: -4.2,
        azimuth: 164.9,
        toolFace: 350.0,
        mudPressure: 340.0,
        formation: 'Fine River Sand',
        notes: 'Approaching minimum 32m scour depth threshold',
      ),
      HddSurveyStation(
        md: 460.0,
        tvd: 35.6,
        pitch: 0.0,
        azimuth: 165.0,
        toolFace: 0.0,
        mudPressure: 420.0,
        formation: 'Medium Sand & Gravel',
        notes: 'Horizontal hold section beneath riverbed scour plane',
      ),
      HddSurveyStation(
        md: 680.0,
        tvd: 36.2,
        pitch: 0.2,
        azimuth: 164.7,
        toolFace: 15.0,
        mudPressure: 450.0,
        formation: 'Dense Sand & Gravel',
        notes: 'Mid-river channel crossing center point',
      ),
      HddSurveyStation(
        md: 850.0,
        tvd: 35.8,
        pitch: 0.8,
        azimuth: 165.2,
        toolFace: 355.0,
        mudPressure: 472.0,
        formation: 'Stiff Silty Clay',
        notes: 'Entering southern bank approach',
      ),
      HddSurveyStation(
        md: 984.0,
        tvd: 34.8,
        pitch: 1.4,
        azimuth: 164.8,
        toolFace: 22.0,
        mudPressure: 485.0,
        formation: 'Stiff Silty Clay',
        notes: 'CURRENT PULLBACK STRING HEAD POSITION',
      ),
    ];
  }

  // Simulation tick step
  void _tickSimulation() {
    setState(() {
      _pulsePhase = (_pulsePhase + 0.1) % (2 * math.pi);
      // Realistic minor fluctuations in telemetry
      _currentPitch = 1.4 + 0.15 * math.sin(_pulsePhase);
      _currentAzimuth = 164.8 + 0.2 * math.cos(_pulsePhase * 0.7);
      _currentToolFace = (22.0 + 8.0 * math.sin(_pulsePhase * 1.2)) % 360;
      _currentMudPressure = 485.0 + 12.0 * math.sin(_pulsePhase * 2.1);
      _currentPullLoad = 142.0 + 3.5 * math.cos(_pulsePhase * 1.5);
      _spindleTorque = 28.5 + 1.2 * math.sin(_pulsePhase * 0.9);
      _slurryFlowRate = 2450.0 + 25.0 * math.cos(_pulsePhase);
      _penetrationSpeed = 18.2 + 0.6 * math.sin(_pulsePhase * 0.8);
      _thrusterPushTons = 42.0 + 1.2 * math.cos(_pulsePhase * 0.5);
    });
  }

  void _advanceJoint() {
    setState(() {
      if (_currentMd < totalLengthM) {
        _currentMd = math.min(totalLengthM, _currentMd + 9.6);
        _scrubStationMd = _currentMd;
        // As depth advances out of bottom hold towards exit
        if (_currentMd > 1050) {
          _currentTvd = math.max(0.0, _currentTvd - 0.28);
          _currentPitch = math.min(7.2, _currentPitch + 0.15);
        }
        _currentPullLoad = math.min(235.0, _currentPullLoad + 0.85);
        _ballastWaterVolumeM3 += 1.4;

        _surveyStations.add(
          HddSurveyStation(
            md: _currentMd,
            tvd: _currentTvd,
            pitch: _currentPitch,
            azimuth: _currentAzimuth,
            toolFace: _currentToolFace,
            mudPressure: _currentMudPressure,
            formation: 'Stiff Silty Clay',
            notes: 'Joint #${((_currentMd / 9.6)).round()} Pullback Survey Shot',
          ),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceCard,
        content: Text(
          'Drill String Advanced: +9.6m Joint (New MD: ${_currentMd.toStringAsFixed(1)}m)',
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frictionSafetyMargin = maxAllowedPullLoadTons - _currentPullLoad;
    final safetyMarginPercent = (frictionSafetyMargin / maxAllowedPullLoadTons) * 100;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildMajorCrossingHeader(frictionSafetyMargin, safetyMarginPercent),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileGeometryTab(),
                _buildSteeringTelemetryTab(),
                _buildProgressionTab(),
                _buildPullbackLoadMonitorTab(frictionSafetyMargin, safetyMarginPercent),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'HDD River Crossing Steering',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primary, width: 0.8),
                ),
                child: const Text(
                  '18" API 5L X70',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Text(
            '$crossingName • 1,450m • Scour Depth: 32m',
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
          tooltip: _isLiveSimulating ? 'Pause Live Telemetry' : 'Play Live Telemetry',
          icon: Icon(
            _isLiveSimulating ? Icons.pause_circle_rounded : Icons.play_circle_filled_rounded,
            color: _isLiveSimulating ? AppTheme.secondary : AppTheme.tertiary,
          ),
          onPressed: () {
            setState(() {
              _isLiveSimulating = !_isLiveSimulating;
            });
            if (_isLiveSimulating) {
              Future.doWhile(() async {
                if (!mounted || !_isLiveSimulating) return false;
                await Future.delayed(const Duration(milliseconds: 600));
                if (mounted && _isLiveSimulating) {
                  _tickSimulation();
                }
                return _isLiveSimulating;
              });
            }
          },
        ),
        IconButton(
          tooltip: 'Frac-out & PWD Safety',
          icon: const Icon(Icons.shield_rounded, color: AppTheme.primaryLight),
          onPressed: _showFracOutSafetyDialog,
        ),
        IconButton(
          tooltip: 'Survey Shot Logger',
          icon: const Icon(Icons.add_location_alt_rounded, color: AppTheme.textPrimary),
          onPressed: _showLogSurveyDialog,
        ),
      ],
    );
  }

  Widget _buildMajorCrossingHeader(double safetyMargin, double safetyMarginPct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.water_rounded, color: AppTheme.primaryLight, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          crossingName.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      pipelineCorridor,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.5), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _isLiveSimulating ? AppTheme.secondary : AppTheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isLiveSimulating ? 'SIMULATING' : 'PARATRACK-2 LIVE',
                      style: TextStyle(
                        color: _isLiveSimulating ? AppTheme.secondary : AppTheme.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 4 Key Quick Status Badges
          Row(
            children: [
              _buildHeaderMetricChip(
                label: 'TOTAL LENGTH',
                value: '${totalLengthM.toStringAsFixed(0)} m',
                icon: Icons.straighten_rounded,
                color: AppTheme.primaryLight,
              ),
              const SizedBox(width: 8),
              _buildHeaderMetricChip(
                label: 'MIN SCOUR DEPTH',
                value: '${designScourClearanceM.toStringAsFixed(0)} m Sub-Bed',
                icon: Icons.vertical_align_bottom_rounded,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 8),
              _buildHeaderMetricChip(
                label: 'PULL LOAD',
                value: '${_currentPullLoad.toStringAsFixed(0)} / ${maxAllowedPullLoadTons.toStringAsFixed(0)} T',
                icon: Icons.speed_rounded,
                color: _currentPullLoad > 200 ? AppTheme.error : AppTheme.tertiary,
              ),
              const SizedBox(width: 8),
              _buildHeaderMetricChip(
                label: 'SAFETY MARGIN',
                value: '${safetyMargin.toStringAsFixed(0)} T (${safetyMarginPct.toStringAsFixed(0)}%)',
                icon: Icons.verified_user_rounded,
                color: AppTheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetricChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 11, color: color),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
        tabs: const [
          Tab(
            icon: Icon(Icons.terrain_rounded, size: 18),
            text: 'Profile Geometry',
          ),
          Tab(
            icon: Icon(Icons.navigation_rounded, size: 18),
            text: 'Steering Telemetry',
          ),
          Tab(
            icon: Icon(Icons.linear_scale_rounded, size: 18),
            text: '4-Phase Progress',
          ),
          Tab(
            icon: Icon(Icons.scale_rounded, size: 18),
            text: 'Pullback Load',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: Profile Geometry & Strata Cross-Section
  // ==========================================
  Widget _buildProfileGeometryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'River Cross-Section Elevation Profile',
            subtitle: 'Real-time bore trajectory vs. 100-Year Scour Bed Depth Envelope (IRC:78 / OISD-141)',
            action: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Scrubber: ${_scrubStationMd.toStringAsFixed(0)}m MD',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Custom Paint Canvas for River Elevation Profile
          Container(
            height: 270,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF090F1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, width: 1.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: GestureDetector(
                onPanUpdate: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final width = MediaQuery.of(context).size.width - 28;
                    final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
                    setState(() {
                      _scrubStationMd = ratio * totalLengthM;
                    });
                  }
                },
                child: CustomPaint(
                  painter: _RiverProfilePainter(
                    totalLengthM: totalLengthM,
                    currentMd: _currentMd,
                    scrubMd: _scrubStationMd,
                    minScourDepthM: designScourClearanceM,
                    surveyStations: _surveyStations,
                    pulsePhase: _pulsePhase,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          // Interactive Station Scrubber Slider
          Row(
            children: [
              const Text('Ch 0+000 (Entry)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryLight,
                    inactiveTrackColor: AppTheme.surfaceContainerHigh,
                    thumbColor: AppTheme.secondary,
                    overlayColor: AppTheme.secondary.withValues(alpha: 0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: _scrubStationMd,
                    min: 0,
                    max: totalLengthM,
                    onChanged: (val) {
                      setState(() {
                        _scrubStationMd = val;
                      });
                    },
                  ),
                ),
              ),
              const Text('Ch 1+450 (Exit)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),

          const SizedBox(height: 12),
          // Selected Chainage Station Inspector Card
          _buildStationInspectorCard(_scrubStationMd),

          const SizedBox(height: 16),
          // Design Geometry Profile Parameters
          _buildGeometryParametersCard(),

          const SizedBox(height: 16),
          // Geotechnical Stratigraphy Legend
          _buildStratigraphyLegendCard(),
        ],
      ),
    );
  }

  Widget _buildStationInspectorCard(double md) {
    // Interpolate theoretical and actual depths
    final fraction = md / totalLengthM;
    final theoreticalTvd = _calculateDesignTvd(md);
    final scourClearance = theoreticalTvd;
    final isClearOfScour = theoreticalTvd >= designScourClearanceM;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isClearOfScour ? AppTheme.border : AppTheme.secondary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.pin_drop_rounded, color: AppTheme.primaryLight, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'STATION SURVEY INSPECTOR: ${md.toStringAsFixed(1)} m MD',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isClearOfScour
                      ? AppTheme.tertiary.withValues(alpha: 0.15)
                      : AppTheme.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isClearOfScour ? '≥ 32m SCOUR SAFE' : 'ENTRY/EXIT INCLINE ZONE',
                  style: TextStyle(
                    color: isClearOfScour ? AppTheme.tertiary : AppTheme.secondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 16),
          Row(
            children: [
              _buildInspectorItem(
                label: 'TRUE VERTICAL DEPTH',
                value: '${theoreticalTvd.toStringAsFixed(1)} m',
                subtitle: 'RL +${(106.2 - theoreticalTvd).toStringAsFixed(1)} m datum',
                color: AppTheme.primaryLight,
              ),
              _buildInspectorItem(
                label: 'SUB-BED SCOUR CLEARANCE',
                value: '${scourClearance.toStringAsFixed(1)} m',
                subtitle: 'Req: ≥ 32.0 m (IRC:78)',
                color: isClearOfScour ? AppTheme.tertiary : AppTheme.secondary,
              ),
              _buildInspectorItem(
                label: 'SECTION SEGMENT',
                value: _getSegmentName(fraction),
                subtitle: 'Design ROC: 1,200 m',
                color: AppTheme.textPrimary,
              ),
              _buildInspectorItem(
                label: 'STRATA FORMATION',
                value: _getStrataAtMd(md),
                subtitle: 'UCS: 0.8 - 1.5 MPa',
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorItem({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8)),
        ],
      ),
    );
  }

  String _getSegmentName(double fraction) {
    if (fraction < 0.12) return 'Entry Tangent (11.5°)';
    if (fraction < 0.32) return 'Build Curve 1 (ROC 1200m)';
    if (fraction < 0.68) return 'Horizontal Bottom Hold';
    if (fraction < 0.88) return 'Exit Curve 2 (ROC 1200m)';
    return 'Exit Tangent (7.2°)';
  }

  String _getStrataAtMd(double md) {
    if (md < 150) return 'Alluvial Loam';
    if (md < 350) return 'Fine River Sand';
    if (md < 750) return 'Dense Sand & Gravel';
    if (md < 1150) return 'Stiff Silty Clay';
    return 'Exit Sand Loam';
  }

  Widget _buildGeometryParametersCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.architecture_rounded, color: AppTheme.primaryLight, size: 16),
              SizedBox(width: 8),
              Text(
                'Design Geometric Parameters & Engineering Limits',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: AppTheme.border.withValues(alpha: 0.5), width: 0.8),
            columnWidths: const {
              0: FlexColumnWidth(1.4),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.4),
            },
            children: const [
              TableRow(
                decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh),
                children: [
                  Padding(padding: EdgeInsets.all(6), child: Text('Parameter', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(6), child: Text('Design Spec', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(6), child: Text('Code / Standard', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.bold))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(6), child: Text('Entry Tangent Angle', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('11.5° (8° to 12° allowed)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('PRCI HDD Guidelines', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(6), child: Text('Exit Tangent Angle', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('7.2° (5° to 8° allowed)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('OISD-141 / ASME B31.8', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(6), child: Text('Radius of Curvature (ROC)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('1,200 m (Min: 685 m)', style: TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(6), child: Text('1500 x D_pipe (457mm)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(6), child: Text('Cover Below 100-Yr Scour', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('32.0 m (Actual: 34.8m)', style: TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(6), child: Text('CWPRS / IRC:78 Hydro Study', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(6), child: Text('Product Pipeline Outer Dia', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('18" OD (457.2mm x 14.3mm)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('API 5L Grade X70 PSL2', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(6), child: Text('Final Reamed Hole Diameter', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('36" (914.4 mm)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('1.5 x D_pipe (ARO clearance)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStratigraphyLegendCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Geotechnical Stratigraphy (Burhi Dihing River Basin Borehole Logs BH-01 to BH-05)',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildStrataLegendItem(const Color(0xFF6D4C41), 'Alluvial Humic Topsoil & Loam (0 - 4m)'),
              _buildStrataLegendItem(const Color(0xFF0284C7), 'Fine Alluvial River Sand & Silt (4 - 18m)'),
              _buildStrataLegendItem(const Color(0xFFD97706), 'Dense Sand with Gravel Lens (18 - 28m)'),
              _buildStrataLegendItem(const Color(0xFF475569), 'Stiff Riverbed Plastic Clay / Siltstone (28 - 45m)'),
              _buildStrataLegendItem(const Color(0xFFEF4444), '100-Year Design Scour Plane (-32m)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrataLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.white24, width: 0.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
      ],
    );
  }

  // ==========================================
  // TAB 2: Real-Time Steering Telemetry Dashboard
  // ==========================================
  Widget _buildSteeringTelemetryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Downhole Steering & MWD Sensor Telemetry',
            subtitle: 'Live readings from ParaTrack-2 Guidance System & PWD Annular Sensor Tool',
            action: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryLight,
                side: const BorderSide(color: AppTheme.primaryLight, width: 0.8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.fiber_manual_record, size: 12, color: AppTheme.tertiary),
              label: Text(
                _isLiveSimulating ? 'SIMULATION ACTIVE' : 'TRANSMITTING',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                setState(() {
                  _tickSimulation();
                });
              },
            ),
          ),
          const SizedBox(height: 12),

          // 5 Core Primary Telemetry Cards
          Row(
            children: [
              // 1. Measured Depth (MD)
              Expanded(
                child: _buildTelemetryCard(
                  title: 'MEASURED DEPTH',
                  value: '${_currentMd.toStringAsFixed(1)} m',
                  target: 'Target: ${totalLengthM.toStringAsFixed(0)} m',
                  icon: Icons.straighten_rounded,
                  color: AppTheme.primaryLight,
                  progressRatio: _currentMd / totalLengthM,
                  statusNote: '${((_currentMd / totalLengthM) * 100).toStringAsFixed(1)}% Completed',
                ),
              ),
              const SizedBox(width: 10),
              // 2. True Vertical Depth (TVD)
              Expanded(
                child: _buildTelemetryCard(
                  title: 'TRUE VERTICAL DEPTH',
                  value: '${_currentTvd.toStringAsFixed(1)} m',
                  target: 'Scour Clearance: 32.8 m',
                  icon: Icons.vertical_align_bottom_rounded,
                  color: AppTheme.tertiary,
                  progressRatio: (_currentTvd / 45.0).clamp(0.0, 1.0),
                  statusNote: '+0.8m Above Min Scour',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              // 3. Pitch Angle (°)
              Expanded(
                child: _buildTelemetryCard(
                  title: 'PITCH INCLINATION',
                  value: '${_currentPitch >= 0 ? "+" : ""}${_currentPitch.toStringAsFixed(2)}°',
                  target: 'Design Target: +1.20°',
                  icon: Icons.show_chart_rounded,
                  color: AppTheme.secondary,
                  progressRatio: ((_currentPitch + 12.0) / 24.0).clamp(0.0, 1.0),
                  statusNote: 'Delta: +0.20° (Normal)',
                ),
              ),
              const SizedBox(width: 10),
              // 4. Azimuth Roll (°)
              Expanded(
                child: _buildTelemetryCard(
                  title: 'AZIMUTH ROLL',
                  value: '${_currentAzimuth.toStringAsFixed(1)}°',
                  target: 'Target Azimuth: 165.0°',
                  icon: Icons.compass_calibration_rounded,
                  color: const Color(0xFFA78BFA),
                  progressRatio: (_currentAzimuth / 360.0).clamp(0.0, 1.0),
                  statusNote: 'Dev: -0.2° (Target Corridor)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5. Annular Mud Pressure (psi) - Full Width Gauge
          _buildAnnularPressureCard(),

          const SizedBox(height: 14),
          // Toolface Roll Compass Dial & Steering Vector
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _buildToolFaceCompassCard(),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: _buildSecondaryTelemetryCard(),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Steering Survey Shot Log Table
          _buildSurveyShotLogTable(),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard({
    required String title,
    required String value,
    required String target,
    required IconData icon,
    required Color color,
    required double progressRatio,
    required String statusNote,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
              Icon(icon, size: 15, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(target, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progressRatio,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 5),
          Text(statusNote, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAnnularPressureCard() {
    // Hydrofracture limit = 720 psi. Minimum cleaning pressure = 320 psi.
    final psi = _currentMudPressure;
    final isSafe = psi >= 320 && psi <= 640;
    final fracMargin = 720.0 - psi;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSafe ? AppTheme.border : AppTheme.error,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.compress_rounded, color: AppTheme.primaryLight, size: 17),
                  SizedBox(width: 8),
                  Text(
                    'ANNULAR MUD PRESSURE (PWD SENSOR)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSafe
                      ? AppTheme.tertiary.withValues(alpha: 0.15)
                      : AppTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSafe ? AppTheme.tertiary : AppTheme.error,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isSafe ? 'HYDROFRACTURE SAFE' : 'PRESSURE WARNING',
                  style: TextStyle(
                    color: isSafe ? AppTheme.tertiary : AppTheme.error,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${psi.toStringAsFixed(0)} psi',
                style: TextStyle(
                  color: isSafe ? AppTheme.tertiary : AppTheme.error,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Safe Operating Window: 320 - 640 psi | Frac Margin: +${fracMargin.toStringAsFixed(0)} psi reserve',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Multi-zone Bar showing Safe Window & Hydrofracture Limit
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                // Safe Zone (320 - 640 out of 800 psi)
                Positioned(
                  left: 320 / 800 * 100,
                  width: (640 - 320) / 800 * 100,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // Frac-out Danger Zone (> 720 psi)
                Positioned(
                  right: 0,
                  width: (800 - 720) / 800 * 100,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0x66EF4444),
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(6)),
                    ),
                  ),
                ),
                // Current Reading Pointer
                FractionallySizedBox(
                  widthFactor: (psi / 800.0).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary,
                          isSafe ? AppTheme.tertiary : AppTheme.error,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 psi (Pore Press)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
              Text('320 psi (Min Clean)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
              Text('640 psi (Opt Max)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
              Text('720 psi (Frac-out Limit)', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolFaceCompassCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOOL FACE ORIENTATION', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              Icon(Icons.explore_rounded, color: AppTheme.primaryLight, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            width: 130,
            child: CustomPaint(
              painter: _ToolFaceCompassPainter(
                toolFaceDeg: _currentToolFace,
                azimuthDeg: _currentAzimuth,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Roll: ${_currentToolFace.toStringAsFixed(0)}° R (High-Right)',
            style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          const Text(
            'Steering: Clock 12:45 • Building Up',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryTelemetryCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RIG DRIVE & MUD RHEOLOGY', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildSecondaryTelemetryRow(
            label: 'Bentonite Slurry Flow',
            value: '${_slurryFlowRate.toStringAsFixed(0)} L/min',
            target: 'Rec: 2,400 L/min',
            icon: Icons.water_drop_rounded,
            color: AppTheme.primaryLight,
          ),
          const Divider(color: AppTheme.border, height: 12),
          _buildSecondaryTelemetryRow(
            label: 'Spindle Rotary Torque',
            value: '${_spindleTorque.toStringAsFixed(1)} kNm',
            target: 'Limit: 65.0 kNm',
            icon: Icons.sync_rounded,
            color: AppTheme.secondary,
          ),
          const Divider(color: AppTheme.border, height: 12),
          _buildSecondaryTelemetryRow(
            label: 'Pullback Travel Rate',
            value: '${_penetrationSpeed.toStringAsFixed(1)} m/hr',
            target: 'Target: 15-20 m/hr',
            icon: Icons.fast_forward_rounded,
            color: AppTheme.tertiary,
          ),
          const Divider(color: AppTheme.border, height: 12),
          _buildSecondaryTelemetryRow(
            label: 'Mud Specific Gravity',
            value: '${_mudDensity.toStringAsFixed(2)} SG',
            target: 'Marsh Funnel: 54s',
            icon: Icons.science_rounded,
            color: const Color(0xFFA78BFA),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryTelemetryRow({
    required String label,
    required String value,
    required String target,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w500)),
              Text(target, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5)),
            ],
          ),
        ),
        Text(value, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildSurveyShotLogTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.list_alt_rounded, color: AppTheme.primaryLight, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'As-Drilled Steering Survey Log',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Text(
                  '${_surveyStations.length} Survey Shots Recorded',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.surfaceContainerHigh),
              columnSpacing: 18,
              horizontalMargin: 12,
              columns: const [
                DataColumn(label: Text('MD (m)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('TVD (m)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Pitch (°)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Azimuth (°)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Toolface', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('PWD (psi)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Formation', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Notes / Remarks', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
              rows: _surveyStations.map((shot) {
                final isCurrent = (shot.md - _currentMd).abs() < 1.0;
                return DataRow(
                  color: isCurrent ? WidgetStateProperty.all(AppTheme.primary.withValues(alpha: 0.15)) : null,
                  cells: [
                    DataCell(Text(shot.md.toStringAsFixed(1), style: TextStyle(color: isCurrent ? AppTheme.primaryLight : AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                    DataCell(Text(shot.tvd.toStringAsFixed(1), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                    DataCell(Text('${shot.pitch >= 0 ? "+" : ""}${shot.pitch.toStringAsFixed(1)}°', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                    DataCell(Text('${shot.azimuth.toStringAsFixed(1)}°', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                    DataCell(Text('${shot.toolFace.toStringAsFixed(0)}°', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                    DataCell(Text(shot.mudPressure.toStringAsFixed(0), style: const TextStyle(color: AppTheme.tertiary, fontSize: 11))),
                    DataCell(Text(shot.formation, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5))),
                    DataCell(Text(shot.notes, style: TextStyle(color: isCurrent ? AppTheme.secondary : AppTheme.textSecondary, fontSize: 10.5))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: 4-Phase Crossing Progression Tracker
  // ==========================================
  Widget _buildProgressionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: '4-Phase Major HDD Execution Timeline',
            subtitle: 'Pilot Bore (12.25") -> Reaming (24"/36") -> Swab Run -> Pipe Pullback (18" API 5L X70)',
            action: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.secondary, width: 0.8),
              ),
              child: const Text(
                'PHASE 4 ACTIVE',
                style: TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Overall Crossing Progress Progress Bar
          _buildOverallProgressBar(),

          const SizedBox(height: 16),
          // 4 Phase Expansion Cards
          _buildPhaseCard(HddPhase.pilotBore),
          const SizedBox(height: 12),
          _buildPhaseCard(HddPhase.forwardReaming),
          const SizedBox(height: 12),
          _buildPhaseCard(HddPhase.swabRun),
          const SizedBox(height: 12),
          _buildPhaseCard(HddPhase.pipePullback),

          const SizedBox(height: 16),
          // Quality & Non-Destructive Testing (NDT) Pre-Pull Signoffs
          _buildPrePullQcChecklistCard(),
        ],
      ),
    );
  }

  Widget _buildOverallProgressBar() {
    // Phase 1 (25%) + Phase 2 (25%) + Phase 3 (25%) + Phase 4 (25% * 0.679) = 91.97% overall HDD milestone
    const overallProgress = (1.0 + 1.0 + 1.0 + (984.0 / 1450.0)) / 4.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CUMULATIVE HDD WORK PACKAGE COMPLETION',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                '${(overallProgress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: AppTheme.tertiary, fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: overallProgress,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.tertiary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phase 1: Pilot (100%)', style: TextStyle(color: AppTheme.tertiary, fontSize: 9.5)),
              Text('Phase 2: Ream (100%)', style: TextStyle(color: AppTheme.tertiary, fontSize: 9.5)),
              Text('Phase 3: Swab (100%)', style: TextStyle(color: AppTheme.tertiary, fontSize: 9.5)),
              Text('Phase 4: Pull (67.9%)', style: TextStyle(color: AppTheme.secondary, fontSize: 9.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(HddPhase phase) {
    final isSelected = _selectedPhase == phase;
    final isCompleted = phase.progressRatio >= 1.0;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPhase = phase;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: phase.statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: phase.statusColor.withValues(alpha: 0.6)),
                  ),
                  child: Center(
                    child: Icon(phase.icon, size: 18, color: phase.statusColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'PHASE ${phase.phaseNumber}: ${phase.title.toUpperCase()}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phase.tooling,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: phase.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCompleted) ...[
                        const Icon(Icons.check_circle_rounded, size: 11, color: AppTheme.tertiary),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        phase.statusText,
                        style: TextStyle(
                          color: phase.statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar for this phase
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: phase == HddPhase.pipePullback
                          ? (_currentMd / totalLengthM)
                          : phase.progressRatio,
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(phase.statusColor),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  phase == HddPhase.pipePullback
                      ? '${_currentMd.toStringAsFixed(0)} / ${totalLengthM.toStringAsFixed(0)} m'
                      : '${phase.completedLengthM.toStringAsFixed(0)} / ${phase.totalLengthM.toStringAsFixed(0)} m',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            if (isSelected) ...[
              const Divider(color: AppTheme.border, height: 18),
              _buildPhaseDetailExpanded(phase),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseDetailExpanded(HddPhase phase) {
    switch (phase) {
      case HddPhase.pilotBore:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phase 1 Technical Verification & Punch-out Stats:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('• Pilot Tooling: 12.25" PDC Drill Bit coupled to 6.75" 7/8 lobe positive displacement mud motor (1.5° bent sub).', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
            Text('• Steering System: ParaTrack-2 electromagnetic tracking with surface TruTracker wire coil laid on Burhi Dihing riverbed.', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
            Text('• Exit Target Accuracy: Punch-out hit South Bank exit pit with only 0.18m North lateral deviation (Tolerance: ±1.5m).', style: TextStyle(color: AppTheme.tertiary, fontSize: 10.5, fontWeight: FontWeight.bold)),
            Text('• Drilling Fluids: High-yield bentonite slurry with PAC-R polymer filtration control (Circulation: 1,850 L/min).', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
          ],
        );
      case HddPhase.forwardReaming:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phase 2 Sequential Hole Enlargement Parameters:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('• Pass 2A (24" Ream): 24" Fly cutter reamer with heavy-duty carbide inserts; 1,450m opened in 16 working shifts.', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
            Text('• Pass 2B (36" Ream): 36" Hole opener with integrated barrel centralizers for smooth bore geometry (1.5x pipe OD).', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
            Text('• Cuttings Removal: 92% volumetric recovery measured at Derrick shale shakers & Brandt hydrocyclone desanders.', style: TextStyle(color: AppTheme.tertiary, fontSize: 10.5)),
            Text('• Torque Log: Spindle torque held below 42 kNm against 65 kNm rig limit; zero mud pack-off incidents.', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
          ],
        );
      case HddPhase.swabRun:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phase 3 Pre-Pull Cleaning & Conditioning Results:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('• Cleaning Tool: 34" Barrel Swab mandrel with polymer wiper rings run through complete 1,450m hole length.', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
            Text('• Hole Drag Test: Total tensile drag recorded at rig tensiometer was 14.2 Tons (Well within < 25 Tons pass criterion).', style: TextStyle(color: AppTheme.tertiary, fontSize: 10.5, fontWeight: FontWeight.bold)),
            Text('• Slurry Displacement: Displaced bore volume with fresh low-solids bentonite slurry dosed with lubricating polymer (COF < 0.22).', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
            Text('• Clearance Signoff: Third-party TPI inspector (EIL / Lloyd\'s Register) certified borehole conditioned for pullback.', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
          ],
        );
      case HddPhase.pipePullback:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Phase 4 Pullback String & Real-Time Rig Parameters:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('• Product String: 1,450m fabricated string of 18" (457.2mm OD) x 14.3mm WT, API 5L Grade X70 PSL2.', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
            Text('• Coating: 3-Layer Polyethylene (3LPE) + 50mm Concrete Weight & Abrasion Resistant Overcoat (ARO).', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
            Text('• Swivel Assembly: Certified 300-Ton capacity sealed bearing swivel to isolate drill string torsion from pipeline.', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
            Text('• Current Hook Load: ${_currentPullLoad.toStringAsFixed(0)} Tons (Safe Working Limit: ${maxAllowedPullLoadTons.toStringAsFixed(0)} Tons).', style: const TextStyle(color: AppTheme.secondary, fontSize: 10.5, fontWeight: FontWeight.bold)),
            Text('• Exit Side Assist: HK300PT Pipe Thruster active, applying ${_thrusterPushTons.toStringAsFixed(0)} Tons pushing thrust.', style: const TextStyle(color: AppTheme.tertiary, fontSize: 10.5)),
          ],
        );
    }
  }

  Widget _buildPrePullQcChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 16),
              SizedBox(width: 8),
              Text(
                'Pre-Pullback QA/QC Inspection & NDT Signoff Records',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildQcItem(
            title: '100% AUT & Radiography of Field Welds',
            agency: 'Engineers India Limited (EIL)',
            status: 'ACCEPTED (0 Repair)',
            icon: Icons.check_circle_rounded,
          ),
          const Divider(color: AppTheme.border, height: 12),
          _buildQcItem(
            title: 'Hydrostatic Strength Pre-Test (1.25x Design Press)',
            agency: 'Oil India Ltd Pipeline QA',
            status: 'PASSED (118.5 bar, 24 hr hold)',
            icon: Icons.check_circle_rounded,
          ),
          const Divider(color: AppTheme.border, height: 12),
          _buildQcItem(
            title: 'High-Voltage Holiday Detection (25 kV)',
            agency: 'Corrosion Inspection Bureau',
            status: 'ZERO PINHOLES (3LPE + Heat Shrink Sleeves)',
            icon: Icons.check_circle_rounded,
          ),
          const Divider(color: AppTheme.border, height: 12),
          _buildQcItem(
            title: 'Pipe String Roller Cradle Alignment',
            agency: 'HDD Rig Superintendent',
            status: 'VERIFIED (38 Roller cradles set at 12m spacing)',
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildQcItem({
    required String title,
    required String agency,
    required String status,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.tertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(agency, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
            ],
          ),
        ),
        Text(status, style: const TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // ==========================================
  // TAB 4: Pullback Pulling Load Monitor & Friction Margin
  // ==========================================
  Widget _buildPullbackLoadMonitorTab(double safetyMargin, double safetyMarginPct) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Pullback Rig Pulling Load & Tensiometer Monitor',
            subtitle: 'Max Allowed: 240 Tons • Current: 142 Tons • Friction Safety Cushion: 98 Tons',
            action: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.tertiary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.tertiary, width: 0.8),
              ),
              child: Text(
                'MARGIN: ${safetyMarginPct.toStringAsFixed(1)}%',
                style: const TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Main Big Arc Load Gauge Card
          _buildPullLoadGaugeCard(safetyMargin, safetyMarginPct),

          const SizedBox(height: 14),
          // Pull Force vs. Distance Profile (Theoretical PRCI vs Actual Measured)
          _buildPullForceVsDistanceChart(),

          const SizedBox(height: 14),
          // Pulling Drag & Friction Force Components Breakdown
          _buildFrictionComponentsCard(),

          const SizedBox(height: 14),
          // Internal Buoyancy Ballast Water Injection Control
          _buildBallastControlCard(),

          const SizedBox(height: 14),
          // Pipe Thruster Assist Integration Card
          _buildPipeThrusterCard(),
        ],
      ),
    );
  }

  Widget _buildPullLoadGaugeCard(double safetyMargin, double safetyMarginPct) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HERRENKNECHT HK300 HDD RIG HOOK LOAD',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'American Augers / Herrenknecht 300T Pull Capacity',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_rounded, size: 12, color: AppTheme.primaryLight),
                    SizedBox(width: 4),
                    Text(
                      'ASME B31.8 / PRCI Spec',
                      style: TextStyle(color: AppTheme.primaryLight, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Big Radial Gauge Visual Painter
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _PullLoadArcGaugePainter(
                currentLoadTons: _currentPullLoad,
                maxAllowedTons: maxAllowedPullLoadTons,
              ),
            ),
          ),

          const SizedBox(height: 10),
          // Primary Metrics Display Row
          Row(
            children: [
              Expanded(
                child: _buildLoadMetricCell(
                  label: 'CURRENT PULL LOAD',
                  value: '${_currentPullLoad.toStringAsFixed(0)} T',
                  subtitle: 'Live Load Cell Tensiometer',
                  color: AppTheme.secondary,
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.border),
              Expanded(
                child: _buildLoadMetricCell(
                  label: 'MAX ALLOWED LIMIT',
                  value: '${maxAllowedPullLoadTons.toStringAsFixed(0)} T',
                  subtitle: '0.8 x SMYS Yield Limit',
                  color: const Color(0xFFEF4444),
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.border),
              Expanded(
                child: _buildLoadMetricCell(
                  label: 'SAFETY RESERVE MARGIN',
                  value: '${safetyMargin.toStringAsFixed(0)} T',
                  subtitle: '${safetyMarginPct.toStringAsFixed(1)}% Available Cushion',
                  color: AppTheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMetricCell({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 1),
        Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
      ],
    );
  }

  Widget _buildPullForceVsDistanceChart() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pulling Force vs. Pulled Distance Profile',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'PRCI Theoretical Engineering Curve vs. Actual Recorded Rig Hook Load',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem(AppTheme.textMuted, 'PRCI Model'),
                  const SizedBox(width: 8),
                  _buildLegendItem(AppTheme.secondary, 'Actual Hook Load'),
                  const SizedBox(width: 8),
                  _buildLegendItem(const Color(0xFFEF4444), '240T Limit'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Custom Canvas for the Pull Force Line Curve
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF090F1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CustomPaint(
                painter: _PullForceCurvePainter(
                  currentMd: _currentMd,
                  currentPullLoad: _currentPullLoad,
                  totalLengthM: totalLengthM,
                  maxLimit: maxAllowedPullLoadTons,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
      ],
    );
  }

  Widget _buildFrictionComponentsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pulling Force Drag Components Breakdown (Total: 142 Tons)',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _buildDragBar(
            name: 'Submerged Pipeline Buoyancy Soil Friction',
            tons: 46.0,
            totalTons: _currentPullLoad,
            color: AppTheme.primaryLight,
            notes: 'Friction coefficient µ = 0.22 with polymer mud cushion',
          ),
          const SizedBox(height: 8),
          _buildDragBar(
            name: 'Fluid Hydrodynamic Viscous Shear Drag',
            tons: 38.0,
            totalTons: _currentPullLoad,
            color: const Color(0xFFA78BFA),
            notes: 'Bentonite annular gel shear over 984m pipe wetted surface',
          ),
          const SizedBox(height: 8),
          _buildDragBar(
            name: 'Capstan Curvature Bending Resistance',
            tons: 36.0,
            totalTons: _currentPullLoad,
            color: AppTheme.secondary,
            notes: 'Elastic bending through 1,200m ROC curve transitions',
          ),
          const SizedBox(height: 8),
          _buildDragBar(
            name: 'South Bank Roller Cradle Rolling Friction',
            tons: 22.0,
            totalTons: _currentPullLoad,
            color: AppTheme.textMuted,
            notes: 'Polyurethane roller beds along 465m tail string',
          ),
        ],
      ),
    );
  }

  Widget _buildDragBar({
    required String name,
    required double tons,
    required double totalTons,
    required Color color,
    required String notes,
  }) {
    final pct = (tons / totalTons) * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            Text('${tons.toStringAsFixed(0)} T (${pct.toStringAsFixed(1)}%)', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: tons / totalTons,
            backgroundColor: AppTheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 2),
        Text(notes, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5)),
      ],
    );
  }

  Widget _buildBallastControlCard() {
    // 18" pipe displacement = 164.2 kg/m. Empty steel weight = 156.4 kg/m.
    // In 1.18 SG mud, buoyant uplift without water ballast = +37.4 kg/m (floating!).
    // With ballast water injection, net submerged weight = -25 kg/m (optimal sinkage).
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.water_drop_rounded, color: AppTheme.primaryLight, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Internal Buoyancy Ballast Water Control',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                icon: const Icon(Icons.tune_rounded, size: 13),
                label: const Text('Ballast Controls', style: TextStyle(fontSize: 10.5)),
                onPressed: _showBallastControlDialog,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildBallastMetric(
                label: 'BALLAST INJECTED',
                value: '${_ballastWaterVolumeM3.toStringAsFixed(1)} m³',
                status: '85% Fill in Bore',
                color: AppTheme.primaryLight,
              ),
              _buildBallastMetric(
                label: 'NET BUOYANCY',
                value: '-25.4 kg/m',
                status: 'Negative (Target: -20 to -30)',
                color: AppTheme.tertiary,
              ),
              _buildBallastMetric(
                label: 'BALLAST LINE FLOW',
                value: '420 L/min',
                status: 'Synchronized Pull Injection',
                color: AppTheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Water is progressively pumped through 2" internal HDPE ballast line to eliminate buoyant lift against hole crown and reduce capstan friction.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBallastMetric({
    required String label,
    required String value,
    required String status,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 1),
            Text(status, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8)),
          ],
        ),
      ),
    );
  }

  Widget _buildPipeThrusterCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.tertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.precision_manufacturing_rounded, color: AppTheme.tertiary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Herrenknecht HK300PT Pipe Thruster Assist',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'STANDBY ACTIVE',
                      style: TextStyle(color: AppTheme.tertiary, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'South Bank entry assist delivering ${_thrusterPushTons.toStringAsFixed(0)} Tons pushing assist to mitigate initial breakaway drag.',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Switch(
            value: _thrusterActive,
            activeThumbColor: AppTheme.tertiary,
            activeTrackColor: AppTheme.tertiary.withValues(alpha: 0.3),
            inactiveThumbColor: AppTheme.textMuted,
            onChanged: (val) {
              setState(() {
                _thrusterActive = val;
                if (!val) {
                  _currentPullLoad += 18.0;
                } else {
                  _currentPullLoad = math.max(100.0, _currentPullLoad - 18.0);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM ACTION BAR
  // ==========================================
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                icon: const Icon(Icons.share_location_rounded, size: 16),
                label: const Text('Log Survey Shot', style: TextStyle(fontSize: 11.5)),
                onPressed: _showLogSurveyDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Advance Drill Joint (+9.6m)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                onPressed: _advanceJoint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DIALOGS & ACTION SHEETS
  // ==========================================

  void _showFracOutSafetyDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: AppTheme.tertiary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Hydrofracture & Frac-Out Safety Window',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 8),
              const Text(
                'Cavity Expansion Hydrofracture Limit (Delft Geotechnical Equation):',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'P_max = (σ_0 + c * cot φ) * [R_p / R_0]^((2 sin φ)/(1 + sin φ)) - c * cot φ',
                style: TextStyle(color: AppTheme.primaryLight, fontSize: 11.5, fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildFracRow('Maximum Allowable Mud Pressure:', '720 psi', const Color(0xFFEF4444)),
                    const SizedBox(height: 4),
                    _buildFracRow('Current Annular PWD Sensor Reading:', '${_currentMudPressure.toStringAsFixed(0)} psi', AppTheme.tertiary),
                    const SizedBox(height: 4),
                    _buildFracRow('Overburden Safety Cushion:', '+${(720 - _currentMudPressure).toStringAsFixed(0)} psi Margin', AppTheme.primaryLight),
                    const SizedBox(height: 4),
                    _buildFracRow('Riverbed Turbidity Monitoring:', '0.0 NTU baseline (Clean)', AppTheme.tertiary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Burhi Dihing River eco-sensitive fish sanctuary protocol active. Automated pump shut-off triggers at 680 psi threshold.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Acknowledge Safety Protocol'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFracRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    );
  }

  void _showLogSurveyDialog() {
    final mdController = TextEditingController(text: (_currentMd + 9.6).toStringAsFixed(1));
    final tvdController = TextEditingController(text: _currentTvd.toStringAsFixed(1));
    final pitchController = TextEditingController(text: _currentPitch.toStringAsFixed(1));
    final azimuthController = TextEditingController(text: _currentAzimuth.toStringAsFixed(1));
    final toolFaceController = TextEditingController(text: _currentToolFace.toStringAsFixed(0));
    final mudPressController = TextEditingController(text: _currentMudPressure.toStringAsFixed(0));
    final remarksController = TextEditingController(text: 'Routine survey shot');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.add_location_alt_rounded, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text('Log Steering Survey Shot', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: mdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'MD (m)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: tvdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'TVD (m)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pitchController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Pitch (°)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: azimuthController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Azimuth (°)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: toolFaceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Tool Face (°)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: mudPressController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Annular (psi)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: remarksController,
                    decoration: const InputDecoration(labelText: 'Remarks / Geotechnical Formation'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                final md = double.tryParse(mdController.text) ?? _currentMd;
                final tvd = double.tryParse(tvdController.text) ?? _currentTvd;
                final pitch = double.tryParse(pitchController.text) ?? _currentPitch;
                final az = double.tryParse(azimuthController.text) ?? _currentAzimuth;
                final tf = double.tryParse(toolFaceController.text) ?? _currentToolFace;
                final mud = double.tryParse(mudPressController.text) ?? _currentMudPressure;

                setState(() {
                  _currentMd = md;
                  _currentTvd = tvd;
                  _currentPitch = pitch;
                  _currentAzimuth = az;
                  _currentToolFace = tf;
                  _currentMudPressure = mud;
                  _scrubStationMd = md;

                  _surveyStations.add(
                    HddSurveyStation(
                      md: md,
                      tvd: tvd,
                      pitch: pitch,
                      azimuth: az,
                      toolFace: tf,
                      mudPressure: mud,
                      formation: 'Stiff Silty Clay',
                      notes: remarksController.text,
                    ),
                  );
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Survey shot successfully logged to ParaTrack-2 profile.'),
                    backgroundColor: AppTheme.tertiary,
                  ),
                );
              },
              child: const Text('Save Shot'),
            ),
          ],
        );
      },
    );
  }

  void _showBallastControlDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ballast Water Injection Optimization', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Regulate water ballast volume to target -20 to -30 kg/m negative buoyancy.', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Injected Ballast Water:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text('${_ballastWaterVolumeM3.toStringAsFixed(1)} m³', style: const TextStyle(color: AppTheme.primaryLight, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _ballastWaterVolumeM3,
                    min: 50.0,
                    max: 200.0,
                    activeColor: AppTheme.primaryLight,
                    onChanged: (val) {
                      setSheetState(() {
                        _ballastWaterVolumeM3 = val;
                      });
                      setState(() {
                        _ballastWaterVolumeM3 = val;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                        onPressed: () {
                          setState(() {
                            _ballastWaterVolumeM3 += 10.0;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Pump +10 m³ Ballast'),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }

  // Pure design calculation for trajectory TVD given station MD
  static double _calculateDesignTvd(double md) {
    if (md <= 0) return 0.0;
    if (md <= 180.0) {
      // Entry tangent at ~11.5 degrees: sin(11.5°) ≈ 0.20
      return md * 0.199;
    } else if (md <= 480.0) {
      // Build curve from 35.8m down to bottom depth 36.2m
      final x = (md - 180.0) / 300.0;
      return 35.8 + 0.4 * math.sin(x * math.pi / 2);
    } else if (md <= 980.0) {
      // Horizontal hold beneath scour bed
      return 36.2;
    } else if (md <= 1270.0) {
      // Exit curve climbing up
      final x = (md - 980.0) / 290.0;
      return 36.2 - (36.2 - 22.0) * (x * x);
    } else if (md <= totalLengthM) {
      // Exit tangent at 7.2 degrees
      final x = (totalLengthM - md) / (totalLengthM - 1270.0);
      return 22.0 * x;
    }
    return 0.0;
  }
}

// ==========================================
// CUSTOM PAINTER: River Profile & Bore Geometry
// ==========================================
class _RiverProfilePainter extends CustomPainter {
  final double totalLengthM;
  final double currentMd;
  final double scrubMd;
  final double minScourDepthM;
  final List<HddSurveyStation> surveyStations;
  final double pulsePhase;

  _RiverProfilePainter({
    required this.totalLengthM,
    required this.currentMd,
    required this.scrubMd,
    required this.minScourDepthM,
    required this.surveyStations,
    required this.pulsePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Coordinate mapping:
    // X axis: 0 to 1450m -> padding Left (40) to w - 20
    const padL = 44.0;
    const padR = 20.0;
    const padT = 28.0;
    const padB = 28.0;
    final drawW = w - padL - padR;
    final drawH = h - padT - padB;

    // Depth: -10m (banks) to 48m depth
    const maxDepth = 48.0;

    double toX(double md) => padL + (md / totalLengthM) * drawW;
    double toY(double tvd) => padT + (tvd / maxDepth) * drawH;

    // 1. Draw Grid Lines and RL Markers
    final gridPaint = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.3)
      ..strokeWidth = 0.8;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int d = 0; d <= 40; d += 10) {
      final y = toY(d.toDouble());
      canvas.drawLine(Offset(padL, y), Offset(w - padR, y), gridPaint);

      textPainter.text = TextSpan(
        text: '-${d}m',
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 8),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(padL - 28, y - 5));
    }

    // Vertical Distance Chainage Markers
    for (int dist = 0; dist <= 1450; dist += 350) {
      final x = toX(dist.toDouble());
      canvas.drawLine(Offset(x, padT), Offset(x, h - padB), gridPaint);

      textPainter.text = TextSpan(
        text: '${dist}m',
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 8),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 10, h - padB + 8));
    }

    // 2. Draw Geotechnical Stratum Bands (Alluvium -> Sand -> Gravel -> Dense Clay)
    final clayPath = Path()
      ..moveTo(padL, toY(28))
      ..lineTo(w - padR, toY(28))
      ..lineTo(w - padR, h - padB)
      ..lineTo(padL, h - padB)
      ..close();
    canvas.drawPath(clayPath, Paint()..color = const Color(0xFF141F36));

    final gravelPath = Path()
      ..moveTo(padL, toY(18))
      ..lineTo(w - padR, toY(18))
      ..lineTo(w - padR, toY(28))
      ..lineTo(padL, toY(28))
      ..close();
    canvas.drawPath(gravelPath, Paint()..color = const Color(0xFF192A48));

    // 3. Draw River Water Body Profile (Burhi Dihing River Channel)
    // River spans from station 300m to 1100m
    final riverStartX = toX(320);
    final riverEndX = toX(1120);
    final waterLevelY = toY(2.0); // Surface RL
    final riverBedMaxY = toY(14.0); // Natural river bed before scour

    final waterPath = Path()
      ..moveTo(riverStartX, waterLevelY)
      ..cubicTo(
        riverStartX + 120, waterLevelY + 8,
        riverEndX - 120, waterLevelY + 8,
        riverEndX, waterLevelY,
      )
      ..lineTo(riverEndX, waterLevelY + 14)
      ..cubicTo(
        riverEndX - 150, riverBedMaxY + 2,
        riverStartX + 150, riverBedMaxY + 2,
        riverStartX, waterLevelY + 12,
      )
      ..close();

    final waterPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0284C7).withValues(alpha: 0.35),
          const Color(0xFF38BDF8).withValues(alpha: 0.15),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(riverStartX, waterLevelY, riverEndX - riverStartX, 30));
    canvas.drawPath(waterPath, waterPaint);

    // River Water Waves Line
    final wavePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(riverStartX, waterLevelY), Offset(riverEndX, waterLevelY), wavePaint);

    // River Name Label
    textPainter.text = const TextSpan(
      text: 'BURHI DIHING RIVER (HIGH MONSOON FLOW)',
      style: TextStyle(color: Color(0xFF38BDF8), fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.8),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(riverStartX + 80, waterLevelY - 14));

    // 4. 100-Year Scour Bed Depth Line (-32m zone)
    final scourY = toY(minScourDepthM);
    final scourPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw dashed red line for scour plane
    double dashX = toX(200);
    final dashLimit = toX(1250);
    while (dashX < dashLimit) {
      canvas.drawLine(Offset(dashX, scourY), Offset(dashX + 8, scourY), scourPaint);
      dashX += 14;
    }

    // Scour depth annotation
    textPainter.text = const TextSpan(
      text: '100-YEAR MAX SCOUR BED PLANE (32.0m DEPTH ZONE)',
      style: TextStyle(color: Color(0xFFEF4444), fontSize: 8, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(toX(220), scourY - 12));

    // 5. Draw North & South River Banks
    final bankPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // North bank entry pit ground
    canvas.drawLine(Offset(padL, toY(0)), Offset(riverStartX, waterLevelY), bankPaint);
    // South bank exit pit ground
    canvas.drawLine(Offset(riverEndX, waterLevelY), Offset(w - padR, toY(2)), bankPaint);

    // Bank labels
    textPainter.text = const TextSpan(
      text: 'NORTH BANK (ENTRY PIT)\nRig HK300',
      style: TextStyle(color: AppTheme.textSecondary, fontSize: 7.5, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(padL + 4, toY(0) - 20));

    textPainter.text = const TextSpan(
      text: 'SOUTH BANK (EXIT PIT)\nPipe Thruster & Rollers',
      style: TextStyle(color: AppTheme.textSecondary, fontSize: 7.5, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(w - padR - 110, toY(0) - 20));

    // 6. Draw Planned Theoretical Bore Profile (Dashed Line)
    final plannedPath = Path();
    for (int step = 0; step <= 1450; step += 25) {
      final x = toX(step.toDouble());
      final y = toY(_HddCrossingProfileScreenState._calculateDesignTvd(step.toDouble()));
      if (step == 0) {
        plannedPath.moveTo(x, y);
      } else {
        plannedPath.lineTo(x, y);
      }
    }
    final plannedPaint = Paint()
      ..color = AppTheme.textMuted.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(plannedPath, plannedPaint);

    // 7. Draw As-Drilled Profile Up To Current MD
    final actualPath = Path();
    for (int step = 0; step <= currentMd.toInt(); step += 15) {
      final x = toX(step.toDouble());
      final y = toY(_HddCrossingProfileScreenState._calculateDesignTvd(step.toDouble()));
      if (step == 0) {
        actualPath.moveTo(x, y);
      } else {
        actualPath.lineTo(x, y);
      }
    }
    // ensure endpoint connects to exact current position
    final curX = toX(currentMd);
    final curY = toY(_HddCrossingProfileScreenState._calculateDesignTvd(currentMd));
    actualPath.lineTo(curX, curY);

    final actualBorePaint = Paint()
      ..color = AppTheme.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(actualPath, actualBorePaint);

    // Pipe Pullback String Inner Line (18" Pipe steel representation)
    final pipeCorePaint = Paint()
      ..color = AppTheme.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(actualPath, pipeCorePaint);

    // 8. Pulsing Glowing Indicator at Current Drill/Pullback Head
    final pulseRadius = 6.0 + 3.0 * math.sin(pulsePhase);
    final glowPaint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(curX, curY), pulseRadius + 4, glowPaint);

    final beaconPaint = Paint()..color = AppTheme.secondary;
    canvas.drawCircle(Offset(curX, curY), 4.5, beaconPaint);
    canvas.drawCircle(Offset(curX, curY), 2.0, Paint()..color = Colors.white);

    // Current position flag callout
    final flagPaint = Paint()..color = AppTheme.secondary;
    canvas.drawLine(Offset(curX, curY), Offset(curX, curY - 26), flagPaint..strokeWidth = 1.0);
    textPainter.text = TextSpan(
      text: 'HEAD: ${currentMd.toStringAsFixed(0)}m MD',
      style: const TextStyle(color: AppTheme.secondary, fontSize: 8, fontWeight: FontWeight.w900),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((curX - 40).clamp(padL, w - padR - 70), curY - 38));

    // 9. Scrubber Station Marker (if user is scrubbing)
    if ((scrubMd - currentMd).abs() > 5.0) {
      final scrubX = toX(scrubMd);
      final scrubY = toY(_HddCrossingProfileScreenState._calculateDesignTvd(scrubMd));

      final scrubLinePaint = Paint()
        ..color = AppTheme.primaryLight.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(scrubX, padT), Offset(scrubX, h - padB), scrubLinePaint);
      canvas.drawCircle(Offset(scrubX, scrubY), 4.0, Paint()..color = AppTheme.primaryLight);
    }
  }

  @override
  bool shouldRepaint(covariant _RiverProfilePainter oldDelegate) {
    return oldDelegate.currentMd != currentMd ||
        oldDelegate.scrubMd != scrubMd ||
        oldDelegate.pulsePhase != pulsePhase;
  }
}

// ==========================================
// CUSTOM PAINTER: ToolFace Orientation Compass
// ==========================================
class _ToolFaceCompassPainter extends CustomPainter {
  final double toolFaceDeg;
  final double azimuthDeg;

  _ToolFaceCompassPainter({
    required this.toolFaceDeg,
    required this.azimuthDeg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background Dial
    final dialPaint = Paint()
      ..color = const Color(0xFF0F1A34)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dialPaint);

    final borderPaint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    // Cardinal Tick Marks (12, 3, 6, 9 o'clock)
    final tickPaint = Paint()
      ..color = AppTheme.textMuted
      ..strokeWidth = 1.0;

    for (int i = 0; i < 12; i++) {
      final angle = i * (math.pi / 6);
      final isCardinal = i % 3 == 0;
      final tickLen = isCardinal ? 7.0 : 4.0;
      final p1 = Offset(
        center.dx + (radius - tickLen) * math.cos(angle),
        center.dy + (radius - tickLen) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint..color = isCardinal ? AppTheme.primaryLight : AppTheme.border);
    }

    // High Side Pointer (Top 12 o'clock marker)
    final highSidePaint = Paint()..color = AppTheme.tertiary;
    final topTriangle = Path()
      ..moveTo(center.dx, center.dy - radius + 1)
      ..lineTo(center.dx - 4, center.dy - radius + 8)
      ..lineTo(center.dx + 4, center.dy - radius + 8)
      ..close();
    canvas.drawPath(topTriangle, highSidePaint);

    // Magnetic Toolface Roll Pointer Needle
    final rollRad = (toolFaceDeg - 90) * (math.pi / 180.0);
    final needleEnd = Offset(
      center.dx + (radius - 12) * math.cos(rollRad),
      center.dy + (radius - 12) * math.sin(rollRad),
    );

    final needlePaint = Paint()
      ..color = AppTheme.secondary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    // Center pivot
    canvas.drawCircle(center, 4, Paint()..color = AppTheme.secondary);
    canvas.drawCircle(center, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _ToolFaceCompassPainter oldDelegate) {
    return oldDelegate.toolFaceDeg != toolFaceDeg || oldDelegate.azimuthDeg != azimuthDeg;
  }
}

// ==========================================
// CUSTOM PAINTER: Pull Load Arc Gauge
// ==========================================
class _PullLoadArcGaugePainter extends CustomPainter {
  final double currentLoadTons;
  final double maxAllowedTons;

  _PullLoadArcGaugePainter({
    required this.currentLoadTons,
    required this.maxAllowedTons,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 15);
    final radius = size.height - 25;

    const startAngle = math.pi; // 180 degrees (left)
    const sweepAngle = math.pi; // 180 degrees sweep (right)

    // 1. Background Inactive Arc Track
    final trackPaint = Paint()
      ..color = AppTheme.surfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // 2. Safe Zone (0 - 180 T = 75% of arc)
    const safeFraction = 180.0 / 240.0;
    final safeArcPaint = Paint()
      ..color = AppTheme.tertiary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * safeFraction,
      false,
      safeArcPaint,
    );

    // 3. Danger / Max Zone (> 220 T to 240 T)
    const dangerStart = 220.0 / 240.0;
    final dangerArcPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + sweepAngle * dangerStart,
      sweepAngle * (1.0 - dangerStart),
      false,
      dangerArcPaint,
    );

    // 4. Current Load Active Gradient Fill
    final loadRatio = (currentLoadTons / maxAllowedTons).clamp(0.0, 1.0);
    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.primary, AppTheme.secondary],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * loadRatio,
      false,
      activePaint,
    );

    // 5. Needle Pointer
    final pointerAngle = startAngle + sweepAngle * loadRatio;
    final pointerEnd = Offset(
      center.dx + (radius - 18) * math.cos(pointerAngle),
      center.dy + (radius - 18) * math.sin(pointerAngle),
    );

    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, pointerEnd, needlePaint);

    canvas.drawCircle(center, 7, Paint()..color = AppTheme.primaryLight);
    canvas.drawCircle(center, 3, Paint()..color = Colors.white);

    // 6. Labels at Key Points
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = const TextSpan(
      text: '0 T',
      style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - radius - 6, center.dy + 4));

    textPainter.text = const TextSpan(
      text: '180 T',
      style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx + 20, center.dy - radius - 10));

    textPainter.text = const TextSpan(
      text: '240 T (MAX)',
      style: TextStyle(color: Color(0xFFEF4444), fontSize: 9.5, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx + radius - 28, center.dy + 4));
  }

  @override
  bool shouldRepaint(covariant _PullLoadArcGaugePainter oldDelegate) {
    return oldDelegate.currentLoadTons != currentLoadTons || oldDelegate.maxAllowedTons != maxAllowedTons;
  }
}

// ==========================================
// CUSTOM PAINTER: Pull Force vs Distance Curve
// ==========================================
class _PullForceCurvePainter extends CustomPainter {
  final double currentMd;
  final double currentPullLoad;
  final double totalLengthM;
  final double maxLimit;

  _PullForceCurvePainter({
    required this.currentMd,
    required this.currentPullLoad,
    required this.totalLengthM,
    required this.maxLimit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const padL = 36.0;
    const padR = 16.0;
    const padT = 16.0;
    const padB = 22.0;
    final drawW = w - padL - padR;
    final drawH = h - padT - padB;

    // Y axis: 0 to 260 Tons
    const maxTons = 260.0;
    double toX(double md) => padL + (md / totalLengthM) * drawW;
    double toY(double tons) => padT + (1.0 - (tons / maxTons)) * drawH;

    // Horizontal Grid Lines
    final gridPaint = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.3)
      ..strokeWidth = 0.8;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int t = 50; t <= 250; t += 50) {
      final y = toY(t.toDouble());
      canvas.drawLine(Offset(padL, y), Offset(w - padR, y), gridPaint);

      textPainter.text = TextSpan(
        text: '${t}T',
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 8),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(padL - 26, y - 5));
    }

    // Max 240T Limit Line
    final maxLineY = toY(maxLimit);
    final limitPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.8)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(padL, maxLineY), Offset(w - padR, maxLineY), limitPaint);

    // 1. PRCI Theoretical Model Curve (Smooth progressive curve)
    final prciPath = Path();
    for (int step = 0; step <= 1450; step += 25) {
      final x = toX(step.toDouble());
      // Theoretical PRCI equation: load starts low, builds through bottom curve, peaks near exit
      final frac = step / totalLengthM;
      final theoreticalLoad = 25.0 + 85.0 * frac + 40.0 * math.pow(frac, 2);
      final y = toY(theoreticalLoad);
      if (step == 0) {
        prciPath.moveTo(x, y);
      } else {
        prciPath.lineTo(x, y);
      }
    }
    final prciPaint = Paint()
      ..color = AppTheme.textMuted.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(prciPath, prciPaint);

    // 2. Actual Measured Hook Load Curve Up To Current MD
    final actualPath = Path();
    for (int step = 0; step <= currentMd.toInt(); step += 20) {
      final x = toX(step.toDouble());
      final frac = step / totalLengthM;
      // Slight noise added to actual recorded tensiometer readings
      final actualLoad = 22.0 + 82.0 * frac + 42.0 * math.pow(frac, 1.8) + 3.0 * math.sin(step * 0.05);
      final y = toY(actualLoad.clamp(0.0, maxTons));
      if (step == 0) {
        actualPath.moveTo(x, y);
      } else {
        actualPath.lineTo(x, y);
      }
    }
    // Connect to actual live reading at current point
    actualPath.lineTo(toX(currentMd), toY(currentPullLoad));

    final actualCurvePaint = Paint()
      ..color = AppTheme.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(actualPath, actualCurvePaint);

    // Point at Current Reading
    final curPt = Offset(toX(currentMd), toY(currentPullLoad));
    canvas.drawCircle(curPt, 4, Paint()..color = AppTheme.secondary);
    canvas.drawCircle(curPt, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PullForceCurvePainter oldDelegate) {
    return oldDelegate.currentMd != currentMd ||
        oldDelegate.currentPullLoad != currentPullLoad;
  }
}
