import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';

/// Strain alert classification per ASME B31.8 / PRCI Strain-Based Design
enum StrainAlertLevel {
  normal(
    label: 'NORMAL',
    sublabel: 'Elastic Range (< 70% Limit)',
    color: AppTheme.tertiary,
    bgTint: Color(0x1A4EDEA3),
    borderTint: Color(0x664EDEA3),
    icon: Icons.check_circle_outline_rounded,
  ),
  yellowAlert(
    label: 'YELLOW ALERT',
    sublabel: 'Advisory Threshold (>= 70% Limit)',
    color: AppTheme.secondary,
    bgTint: Color(0x1AFFB95F),
    borderTint: Color(0x66FFB95F),
    icon: Icons.warning_amber_rounded,
  ),
  redAlert(
    label: 'RED ALERT',
    sublabel: 'Critical Threshold (>= 85% Limit)',
    color: Color(0xFFF43F5E),
    bgTint: Color(0x1AF43F5E),
    borderTint: Color(0x66F43F5E),
    icon: Icons.crisis_alert_rounded,
  ),
  exceeded(
    label: 'EXCEEDED',
    sublabel: 'Design Plastic Limit (>= 100%)',
    color: Color(0xFFE11D48),
    bgTint: Color(0x2AE11D48),
    borderTint: Color(0x88E11D48),
    icon: Icons.report_problem_rounded,
  );

  final String label;
  final String sublabel;
  final Color color;
  final Color bgTint;
  final Color borderTint;
  final IconData icon;

  const StrainAlertLevel({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.bgTint,
    required this.borderTint,
    required this.icon,
  });
}

/// Pipeline Steel Grade Specifications
enum PipelineSteelGrade {
  x65(name: 'API 5L X65', smysMpa: 448.0, smtsMpa: 535.0),
  x70(name: 'API 5L X70', smysMpa: 485.0, smtsMpa: 570.0),
  x80(name: 'API 5L X80', smysMpa: 555.0, smtsMpa: 625.0);

  final String name;
  final double smysMpa;
  final double smtsMpa;

  const PipelineSteelGrade({
    required this.name,
    required this.smysMpa,
    required this.smtsMpa,
  });
}

/// Historical microstrain reading for a station
class MicrostrainHistoryPoint {
  final DateTime timestamp;
  final double crownMicrostrain;
  final double invertMicrostrain;
  final double eastMicrostrain;
  final double westMicrostrain;

  const MicrostrainHistoryPoint({
    required this.timestamp,
    required this.crownMicrostrain,
    required this.invertMicrostrain,
    required this.eastMicrostrain,
    required this.westMicrostrain,
  });

  double get maxMicrostrain => [
        crownMicrostrain.abs(),
        invertMicrostrain.abs(),
        eastMicrostrain.abs(),
        westMicrostrain.abs(),
      ].reduce(math.max);
}

/// 3-Axis Vibrating Wire Strain Gauge Rosette Station Model (SG-01 to SG-08)
class RosetteStation {
  final String id;
  final String chainage;
  final String locationDescription;
  final double chainageOffsetM;
  final double pipeElevationRlm;
  final double riverbedElevationRlm;
  final double activeScourDepthM;
  final double crownStrain; // 12 o'clock (microstrain)
  final double eastStrain; // 3 o'clock (microstrain)
  final double invertStrain; // 6 o'clock (microstrain)
  final double westStrain; // 9 o'clock (microstrain)
  final double temperatureC;
  final double internalPressureMpa;
  final double slopeSlipMm;
  final double slopeSlipRateMmDay;
  final double porePressureKpa;
  final DateTime lastPing;
  final List<MicrostrainHistoryPoint> history;

  // Pipeline Constants for Burhi Dihing Crossing
  static const double outerDiameterMm = 609.6; // 24" pipe
  static const double wallThicknessMm = 14.3;
  static const double youngsModulusMpa = 207000.0; // Steel E (MPa)
  static const double poissonsRatio = 0.30;
  static const double allowableStrainCapacity = 5000.0; // 5000 microstrain (0.50% strain)
  static const PipelineSteelGrade defaultGrade = PipelineSteelGrade.x70;

  const RosetteStation({
    required this.id,
    required this.chainage,
    required this.locationDescription,
    required this.chainageOffsetM,
    required this.pipeElevationRlm,
    required this.riverbedElevationRlm,
    required this.activeScourDepthM,
    required this.crownStrain,
    required this.eastStrain,
    required this.invertStrain,
    required this.westStrain,
    required this.temperatureC,
    required this.internalPressureMpa,
    required this.slopeSlipMm,
    required this.slopeSlipRateMmDay,
    required this.porePressureKpa,
    required this.lastPing,
    required this.history,
  });

  /// Depth of cover over pipeline
  double get depthOfCoverM => riverbedElevationRlm - pipeElevationRlm;

  /// Vertical bending strain: (epsilon_12 - epsilon_6) / 2
  double get verticalBendingStrain => (crownStrain - invertStrain) / 2.0;

  /// Horizontal bending strain: (epsilon_3 - epsilon_9) / 2
  double get horizontalBendingStrain => (eastStrain - westStrain) / 2.0;

  /// Net bending strain: sqrt(eps_bv^2 + eps_bh^2)
  double get netBendingStrain => math.sqrt(
        verticalBendingStrain * verticalBendingStrain +
            horizontalBendingStrain * horizontalBendingStrain,
      );

  /// Average axial strain: (eps_12 + eps_3 + eps_6 + eps_9) / 4
  double get axialStrain =>
      (crownStrain + eastStrain + invertStrain + westStrain) / 4.0;

  /// Maximum tensile extreme fiber strain
  double get maxTensileStrain => axialStrain + netBendingStrain;

  /// Maximum compressive extreme fiber strain
  double get maxCompressiveStrain => axialStrain - netBendingStrain;

  /// Peak strain absolute magnitude in microstrain
  double get peakMicrostrain => math.max(
        maxTensileStrain.abs(),
        maxCompressiveStrain.abs(),
      );

  /// Strain Utilization Ratio (Peak Strain / Allowable Strain)
  double get strainUtilizationRatio =>
      peakMicrostrain / allowableStrainCapacity;

  /// Curvature kappa = 2 * epsilon_b / D_o (1/m)
  double get curvaturePerM =>
      (2.0 * netBendingStrain * 1e-6) / (outerDiameterMm * 1e-3);

  /// Radius of Curvature R = 1 / kappa (meters)
  double get radiusOfCurvatureM =>
      curvaturePerM > 1e-7 ? (1.0 / curvaturePerM) : 99999.0;

  /// Longitudinal bending stress sigma_b = E * epsilon_b (MPa)
  double get longitudinalBendingStressMpa =>
      youngsModulusMpa * (netBendingStrain * 1e-6);

  /// Hoop stress sigma_h = P * D / (2 * t) (MPa)
  double get hoopStressMpa =>
      (internalPressureMpa * outerDiameterMm) / (2.0 * wallThicknessMm);

  /// Total Longitudinal stress sigma_L = nu * sigma_h + sigma_b (MPa)
  double get totalLongitudinalStressMpa =>
      (poissonsRatio * hoopStressMpa) + longitudinalBendingStressMpa;

  /// von Mises equivalent stress sigma_eq = sqrt(sigma_h^2 + sigma_L^2 - sigma_h * sigma_L)
  double get vonMisesStressMpa => math.sqrt(
        (hoopStressMpa * hoopStressMpa) +
            (totalLongitudinalStressMpa * totalLongitudinalStressMpa) -
            (hoopStressMpa * totalLongitudinalStressMpa),
      );

  /// Allowable equivalent stress per ASME B31.8 = 0.90 * SMYS
  double get allowableEquivalentStressMpa =>
      0.90 * defaultGrade.smysMpa; // 436.5 MPa for X70

  /// Stress Utilization Ratio (von Mises / 0.90 SMYS)
  double get stressUtilizationRatio =>
      vonMisesStressMpa / allowableEquivalentStressMpa;

  /// Alert trigger based on ASME B31.8 & PRCI Strain-Based criteria:
  /// Yellow alert at 70% allowable strain, Red alert at 85% allowable strain
  StrainAlertLevel get alertLevel {
    if (strainUtilizationRatio >= 1.0) return StrainAlertLevel.exceeded;
    if (strainUtilizationRatio >= 0.85) return StrainAlertLevel.redAlert;
    if (strainUtilizationRatio >= 0.70) return StrainAlertLevel.yellowAlert;
    return StrainAlertLevel.normal;
  }
}

/// Main Screen Widget
class StrainGaugeMonitoringScreen extends StatefulWidget {
  const StrainGaugeMonitoringScreen({super.key});

  @override
  State<StrainGaugeMonitoringScreen> createState() =>
      _StrainGaugeMonitoringScreenState();
}

class _StrainGaugeMonitoringScreenState extends State<StrainGaugeMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Selected station for detail inspection
  String _selectedStationId = 'SG-04';

  // Calculator Parameters
  double _calcPressureMpa = 9.8; // 98 bar
  double _calcWallThicknessMm = 14.3; // 14.3mm
  double _calcBendingStrain = 4200.0; // microstrain
  PipelineSteelGrade _calcSteelGrade = PipelineSteelGrade.x70;

  // 3D Wireframe Visualizer Controls
  double _viewAzimuthDeg = 35.0; // Azimuth angle
  double _viewElevationDeg = 24.0; // Elevation angle
  double _deflectionMagnification = 25.0; // 1x to 50x magnification
  double _wireframeZoom = 1.0;
  bool _showTerrainScour = true;
  bool _showWaterSurface = true;

  // Time Range Filter for Telemetry Chart
  int _selectedHistoryDays = 7; // 1, 7, 30

  // Dataset of SG-01 to SG-08 rosettes along Burhi Dihing flood plain
  late List<RosetteStation> _stations;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _stations = _generateStationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  RosetteStation get _activeStation =>
      _stations.firstWhere((s) => s.id == _selectedStationId,
          orElse: () => _stations[3]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeStation = _activeStation;

    // Count alert statuses across rosettes
    int redCount = 0;
    int yellowCount = 0;
    int normalCount = 0;
    for (final s in _stations) {
      if (s.alertLevel == StrainAlertLevel.redAlert ||
          s.alertLevel == StrainAlertLevel.exceeded) {
        redCount++;
      } else if (s.alertLevel == StrainAlertLevel.yellowAlert) {
        yellowCount++;
      } else {
        normalCount++;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pipeline Strain & Bending Stress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'ASME B31.8 / PRCI SBD • Burhi Dihing 24" Pipe',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Emergency SOP & Mitigation Trigger',
            icon: const Icon(Icons.shield_outlined, color: AppTheme.secondary),
            onPressed: () => _showEmergencySopDialog(context, activeStation),
          ),
          IconButton(
            tooltip: 'Export Geotechnical Report',
            icon: const Icon(Icons.ios_share_rounded, color: AppTheme.primaryLight),
            onPressed: () => _showExportSnackbar(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              // System Alert Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sensors_rounded,
                        size: 16, color: AppTheme.primaryLight),
                    const SizedBox(width: 8),
                    const Text(
                      '8/8 Rosettes Live',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _buildStatusPill(
                      label: '$redCount RED',
                      color: const Color(0xFFF43F5E),
                      isActive: redCount > 0,
                    ),
                    const SizedBox(width: 6),
                    _buildStatusPill(
                      label: '$yellowCount YELLOW',
                      color: AppTheme.secondary,
                      isActive: yellowCount > 0,
                    ),
                    const SizedBox(width: 6),
                    _buildStatusPill(
                      label: '$normalCount NORMAL',
                      color: AppTheme.tertiary,
                      isActive: normalCount > 0,
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryLight,
                labelColor: AppTheme.primaryLight,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorWeight: 2.5,
                labelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'ROSETTES', icon: Icon(Icons.donut_large_rounded, size: 18)),
                  Tab(text: '3D WIREFRAME', icon: Icon(Icons.view_in_ar_rounded, size: 18)),
                  Tab(text: 'B31.8 CALCULATOR', icon: Icon(Icons.calculate_rounded, size: 18)),
                  Tab(text: 'TELEMETRY & LOGS', icon: Icon(Icons.timeline_rounded, size: 18)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRosettesTab(theme),
          _build3DWireframeTab(theme),
          _buildCalculatorTab(theme),
          _buildTelemetryAndLogsTab(theme),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color color,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.8 : 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? color : color.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: ROSETTES & STATION OVERVIEW
  // ==========================================
  Widget _buildRosettesTab(ThemeData theme) {
    final activeStation = _activeStation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // High-level KPI Summary Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'PEAK VON MISES',
                  value: '${activeStation.vonMisesStressMpa.toStringAsFixed(1)} MPa',
                  subtitle: 'Limit: ${activeStation.allowableEquivalentStressMpa.toStringAsFixed(1)} MPa (90% SMYS)',
                  progress: activeStation.stressUtilizationRatio,
                  color: activeStation.alertLevel.color,
                  icon: Icons.speed_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'MAX MICROSTRAIN',
                  value: '${activeStation.peakMicrostrain.toStringAsFixed(0)} με',
                  subtitle: 'Allowable: 5,000 με (ASME B31.8)',
                  progress: activeStation.strainUtilizationRatio,
                  color: activeStation.alertLevel.color,
                  icon: Icons.stacked_line_chart_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'MIN BENDING RADIUS',
                  value: '${activeStation.radiusOfCurvatureM.toStringAsFixed(0)} m',
                  subtitle: 'Elastic Limit: >= 610 m (1000 D)',
                  progress: math.min(1.0, 610.0 / math.max(1.0, activeStation.radiusOfCurvatureM)),
                  color: activeStation.radiusOfCurvatureM < 610 ? const Color(0xFFF43F5E) : AppTheme.tertiary,
                  icon: Icons.architecture_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'RIVERBANK SLIP RATE',
                  value: '${activeStation.slopeSlipRateMmDay.toStringAsFixed(2)} mm/d',
                  subtitle: 'Cumulative: ${activeStation.slopeSlipMm.toStringAsFixed(1)} mm',
                  progress: math.min(1.0, activeStation.slopeSlipRateMmDay / 5.0),
                  color: activeStation.slopeSlipRateMmDay >= 2.5
                      ? const Color(0xFFF43F5E)
                      : AppTheme.secondary,
                  icon: Icons.landslide_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Station Horizontal Selector Carousel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MONITORED ROSETTE STATIONS (24" PIPE)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Selected: ${_activeStation.id}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _stations.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final station = _stations[index];
                final isSelected = station.id == _selectedStationId;
                return _buildRosetteSelectorCard(station, isSelected);
              },
            ),
          ),
          const SizedBox(height: 20),

          // Active Rosette Detailed Cross-Section & Stress Analysis
          _buildRosetteDetailCard(activeStation),
          const SizedBox(height: 20),

          // ASME B31.8 / PRCI Criteria Explanation Card
          _buildDesignCriteriaCard(),
        ],
      ),
    );
  }

  Widget _buildRosetteSelectorCard(RosetteStation station, bool isSelected) {
    final alert = station.alertLevel;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStationId = station.id;
          _calcBendingStrain = station.netBendingStrain;
          _calcPressureMpa = station.internalPressureMpa;
        });
      },
      child: Container(
        width: 135,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceContainerHigh : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : alert.color.withValues(alpha: 0.4),
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
                Text(
                  station.id,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: alert.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Text(
              station.chainage,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${station.peakMicrostrain.toStringAsFixed(0)} με',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: alert.color,
                  ),
                ),
                Text(
                  '${(station.strainUtilizationRatio * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required double progress,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosetteDetailCard(RosetteStation station) {
    final alert = station.alertLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: alert.borderTint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rosette Header & Alert Badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${station.id} • ${station.locationDescription}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${station.chainage} • Soil Cover: ${station.depthOfCoverM.toStringAsFixed(1)}m • Scour Depth: ${station.activeScourDepthM.toStringAsFixed(1)}m',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: alert.bgTint,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: alert.color),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(alert.icon, size: 14, color: alert.color),
                    const SizedBox(width: 4),
                    Text(
                      alert.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: alert.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 16),

          // 24" Pipe Cross-Section Rosette Clock Positions & Vector Diagram
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Custom Painted Clock Rosette Cross-Section
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _RosetteCrossSectionPainter(
                    crownStrain: station.crownStrain,
                    eastStrain: station.eastStrain,
                    invertStrain: station.invertStrain,
                    westStrain: station.westStrain,
                    alertColor: alert.color,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 4 Clock Position Reading Table
              Expanded(
                child: Column(
                  children: [
                    _buildClockReadingRow(
                      clock: '12:00 CROWN (TOP)',
                      microstrain: station.crownStrain,
                      isTension: station.crownStrain >= 0,
                    ),
                    const SizedBox(height: 6),
                    _buildClockReadingRow(
                      clock: '03:00 EAST SPRINGLINE',
                      microstrain: station.eastStrain,
                      isTension: station.eastStrain >= 0,
                    ),
                    const SizedBox(height: 6),
                    _buildClockReadingRow(
                      clock: '06:00 INVERT (BOTTOM)',
                      microstrain: station.invertStrain,
                      isTension: station.invertStrain >= 0,
                    ),
                    const SizedBox(height: 6),
                    _buildClockReadingRow(
                      clock: '09:00 WEST SPRINGLINE',
                      microstrain: station.westStrain,
                      isTension: station.westStrain >= 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 16),

          // Strain & Stress Deconstruction Matrix
          const Text(
            'STRESS & STRAIN DECOMPOSITION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _buildDecompositionGrid(station),
        ],
      ),
    );
  }

  Widget _buildClockReadingRow({
    required String clock,
    required double microstrain,
    required bool isTension,
  }) {
    final color = isTension ? AppTheme.primaryLight : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            clock,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          Row(
            children: [
              Text(
                '${microstrain > 0 ? "+" : ""}${microstrain.toStringAsFixed(0)} με',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isTension ? '(T)' : '(C)',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecompositionGrid(RosetteStation station) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDecompCell(
                label: 'Vertical Bending (ε_bv)',
                value: '${station.verticalBendingStrain.toStringAsFixed(1)} με',
                sub: '(ε_12 - ε_6) / 2',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDecompCell(
                label: 'Horiz Bending (ε_bh)',
                value: '${station.horizontalBendingStrain.toStringAsFixed(1)} με',
                sub: '(ε_3 - ε_9) / 2',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDecompCell(
                label: 'Longitudinal Bending (σ_b)',
                value: '${station.longitudinalBendingStressMpa.toStringAsFixed(1)} MPa',
                sub: 'E • ε_b (${(station.longitudinalBendingStressMpa / 485 * 100).toStringAsFixed(0)}% SMYS)',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDecompCell(
                label: 'Hoop Stress (σ_h)',
                value: '${station.hoopStressMpa.toStringAsFixed(1)} MPa',
                sub: 'P • D / (2t) (Barlow eq)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDecompCell(
                label: 'Total Long Stress (σ_L)',
                value: '${station.totalLongitudinalStressMpa.toStringAsFixed(1)} MPa',
                sub: 'ν•σ_h + σ_b',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDecompCell(
                label: 'von Mises Equiv (σ_eq)',
                value: '${station.vonMisesStressMpa.toStringAsFixed(1)} MPa',
                sub: 'Limit: 436.5 MPa (0.90 SMYS)',
                highlightColor: station.alertLevel.color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDecompCell({
    required String label,
    required String value,
    required String sub,
    Color? highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlightColor != null
              ? highlightColor.withValues(alpha: 0.5)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlightColor ?? AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignCriteriaCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.menu_book_rounded, size: 16, color: AppTheme.secondary),
              SizedBox(width: 6),
              Text(
                'ASME B31.8 / PRCI GUIDELINES FOR GEOHAZARD RIVER CROSSINGS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• ASME B31.8 Clause 833.4: In areas subject to longitudinal bending induced by active slope movement or river scour spans, combined von Mises equivalent stress shall not exceed 0.90 * SMYS under design pressure.\n'
            '• PRCI Pipeline Strain-Based Design (SBD): Allowable tensile strain capacity (TSC) is capped at 0.50% (5,000 με) for high-grade welded steel linepipe.\n'
            '• Yellow Alert Trigger: 70% of allowable strain (3,500 με) or slope displacement rate >= 2.0 mm/day.\n'
            '• Red Alert Trigger: 85% of allowable strain (4,250 με) or slope displacement rate >= 4.0 mm/day.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: PIPELINE 3D CURVATURE WIREFRAME
  // ==========================================
  Widget _build3DWireframeTab(ThemeData theme) {
    final activeStation = _activeStation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3D Canvas Card with Touch Orbit Controls
          Container(
            height: 380,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Interactive Pan / Rotate Gesture Detector
                  GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _viewAzimuthDeg = (_viewAzimuthDeg + details.delta.dx * 0.45) % 360;
                        _viewElevationDeg = (_viewElevationDeg - details.delta.dy * 0.35)
                            .clamp(-15.0, 75.0);
                      });
                    },
                    child: CustomPaint(
                      size: const Size(double.infinity, 380),
                      painter: _Pipeline3DWireframePainter(
                        stations: _stations,
                        activeStationId: _selectedStationId,
                        azimuthDeg: _viewAzimuthDeg,
                        elevationDeg: _viewElevationDeg,
                        deflectionMagnification: _deflectionMagnification,
                        zoom: _wireframeZoom,
                        showTerrainScour: _showTerrainScour,
                        showWaterSurface: _showWaterSurface,
                      ),
                    ),
                  ),

                  // Overlay Controls: Legend & Reset
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.background.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '3D WIREFRAME DEFORMATION PLOT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Drag to Orbit • Az: ${_viewAzimuthDeg.toStringAsFixed(0)}° • El: ${_viewElevationDeg.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.textSecondary),
                      tooltip: 'Reset Camera Angles',
                      onPressed: () {
                        setState(() {
                          _viewAzimuthDeg = 35.0;
                          _viewElevationDeg = 24.0;
                          _deflectionMagnification = 25.0;
                          _wireframeZoom = 1.0;
                        });
                      },
                    ),
                  ),

                  // Legend overlay
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.background.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          _buildLegendDot(AppTheme.tertiary, 'Normal'),
                          const SizedBox(width: 8),
                          _buildLegendDot(AppTheme.secondary, 'Yellow Alert'),
                          const SizedBox(width: 8),
                          _buildLegendDot(const Color(0xFFF43F5E), 'Red Alert'),
                          const SizedBox(width: 8),
                          _buildLegendDot(Colors.cyanAccent, 'Water HFL'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3D Visualizer Interactive Adjustment Sliders
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '3D MODEL PARAMETERS & DEFLECTION EXAGGERATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Deflection Scale Multiplier',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              Text('${_deflectionMagnification.toStringAsFixed(0)}x',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
                            ],
                          ),
                          Slider(
                            value: _deflectionMagnification,
                            min: 1.0,
                            max: 50.0,
                            activeColor: AppTheme.primaryLight,
                            inactiveColor: AppTheme.surface,
                            onChanged: (val) => setState(() => _deflectionMagnification = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Camera Zoom Scale',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              Text('${_wireframeZoom.toStringAsFixed(1)}x',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
                            ],
                          ),
                          Slider(
                            value: _wireframeZoom,
                            min: 0.6,
                            max: 2.0,
                            activeColor: AppTheme.primaryLight,
                            inactiveColor: AppTheme.surface,
                            onChanged: (val) => setState(() => _wireframeZoom = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Scour Trench Bathymetry', style: TextStyle(fontSize: 11)),
                      selected: _showTerrainScour,
                      selectedColor: AppTheme.primary.withValues(alpha: 0.3),
                      checkmarkColor: AppTheme.primaryLight,
                      onSelected: (val) => setState(() => _showTerrainScour = val),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Burhi Dihing Water Surface', style: TextStyle(fontSize: 11)),
                      selected: _showWaterSurface,
                      selectedColor: Colors.cyan.withValues(alpha: 0.3),
                      checkmarkColor: Colors.cyanAccent,
                      onSelected: (val) => setState(() => _showWaterSurface = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Selected Station Scour & Curvature Analysis Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: activeStation.alertLevel.bgTint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: activeStation.alertLevel.borderTint),
            ),
            child: Row(
              children: [
                Icon(activeStation.alertLevel.icon, color: activeStation.alertLevel.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Curvature Analysis at ${activeStation.id} (${activeStation.chainage})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: activeStation.alertLevel.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Elastic radius R = ${activeStation.radiusOfCurvatureM.toStringAsFixed(0)}m (Max allowable curvature κ = ${(activeStation.curvaturePerM * 1000).toStringAsFixed(2)} × 10⁻³ m⁻¹). '
                        'Scour bed overhang span = ${(activeStation.activeScourDepthM * 3.5).toStringAsFixed(1)}m.',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
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

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      ],
    );
  }

  // ==========================================
  // TAB 3: ASME B31.8 / PRCI CALCULATOR
  // ==========================================
  Widget _buildCalculatorTab(ThemeData theme) {
    // Live Calculation
    const double dMm = 609.6; // 24"
    final double tMm = _calcWallThicknessMm;
    final double pMpa = _calcPressureMpa;
    final double epsBending = _calcBendingStrain; // microstrain
    const double eMpa = 207000.0;
    const double nu = 0.30;
    final double smys = _calcSteelGrade.smysMpa;

    // Formulas:
    // sigma_b = E * epsilon
    final double sigmaB = eMpa * (epsBending * 1e-6);

    // hoop stress sigma_h = P * D / (2 * t)
    final double sigmaH = (pMpa * dMm) / (2.0 * tMm);

    // longitudinal stress sigma_L = nu * sigma_h + sigma_b
    final double sigmaL = (nu * sigmaH) + sigmaB;

    // von Mises equivalent stress sigma_eq = sqrt(sigma_h^2 + sigma_L^2 - sigma_h * sigma_L)
    final double sigmaEq = math.sqrt(
      (sigmaH * sigmaH) + (sigmaL * sigmaL) - (sigmaH * sigmaL),
    );

    // Allowable limit = 0.90 * SMYS
    final double allowableStress = 0.90 * smys;
    final double stressUr = sigmaEq / allowableStress;

    // Allowable strain = 5,000 microstrain
    const double allowableStrain = 5000.0;
    final double strainUr = epsBending / allowableStrain;

    // Radius of Curvature R = D / (2 * epsilon_b)
    final double radiusOfCurv = (dMm * 1e-3) / (2.0 * epsBending * 1e-6);

    Color resultColor = AppTheme.tertiary;
    String statusText = 'SAFE (ELASTIC BEHAVIOR)';
    if (stressUr >= 1.0 || strainUr >= 1.0) {
      resultColor = const Color(0xFFE11D48);
      statusText = 'PLASTIC WRINKLING / TENSILE RUPTURE RISK';
    } else if (stressUr >= 0.85 || strainUr >= 0.85) {
      resultColor = const Color(0xFFF43F5E);
      statusText = 'RED ALERT (CRITICAL ACTION THRESHOLD)';
    } else if (stressUr >= 0.70 || strainUr >= 0.70) {
      resultColor = AppTheme.secondary;
      statusText = 'YELLOW ALERT (ADVISORY SURVEILLANCE)';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: const [
                Icon(Icons.tune_rounded, size: 20, color: AppTheme.primaryLight),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Interactive ASME B31.8 / PRCI Pipeline Stress Engine\n'
                    'Calculates combined longitudinal bending & hoop stress vs 0.90 SMYS envelope.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary Interactive Input Sliders Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INPUT DESIGN & LOAD PARAMETERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 16),

                // Steel Grade Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pipeline Steel Grade',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    DropdownButton<PipelineSteelGrade>(
                      value: _calcSteelGrade,
                      dropdownColor: AppTheme.surfaceCard,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                      underline: const SizedBox(),
                      items: PipelineSteelGrade.values.map((grade) {
                        return DropdownMenuItem(
                          value: grade,
                          child: Text('${grade.name} (SMYS ${grade.smysMpa.toStringAsFixed(0)} MPa)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _calcSteelGrade = val);
                      },
                    ),
                  ],
                ),
                const Divider(color: AppTheme.border, height: 20),

                // Internal Operating Pressure P
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Internal Pressure (P)',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Text('${_calcPressureMpa.toStringAsFixed(1)} MPa (${(_calcPressureMpa * 10).toStringAsFixed(0)} bar)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
                  ],
                ),
                Slider(
                  value: _calcPressureMpa,
                  min: 0.0,
                  max: 15.0,
                  divisions: 30,
                  activeColor: AppTheme.primaryLight,
                  inactiveColor: AppTheme.surface,
                  onChanged: (val) => setState(() => _calcPressureMpa = val),
                ),
                const SizedBox(height: 8),

                // Wall Thickness t
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Wall Thickness (t)',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Text('${_calcWallThicknessMm.toStringAsFixed(1)} mm (24" OD)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
                  ],
                ),
                Slider(
                  value: _calcWallThicknessMm,
                  min: 9.5,
                  max: 22.0,
                  divisions: 25,
                  activeColor: AppTheme.primaryLight,
                  inactiveColor: AppTheme.surface,
                  onChanged: (val) => setState(() => _calcWallThicknessMm = val),
                ),
                const SizedBox(height: 8),

                // Measured Bending Microstrain epsilon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bending Strain (ε_b)',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Text('${_calcBendingStrain.toStringAsFixed(0)} με (${(strainUr * 100).toStringAsFixed(1)}% Limit)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: resultColor)),
                  ],
                ),
                Slider(
                  value: _calcBendingStrain,
                  min: 100.0,
                  max: 6000.0,
                  divisions: 59,
                  activeColor: resultColor,
                  inactiveColor: AppTheme.surface,
                  onChanged: (val) => setState(() => _calcBendingStrain = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Output Results Card with Formulas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: resultColor.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'STRESS CALCULATION OUTPUT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: resultColor),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: resultColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Formula Breakdown Items
                _buildCalcFormulaRow(
                  title: 'Hoop Stress: σ_h = P • D / (2t)',
                  value: '${sigmaH.toStringAsFixed(1)} MPa',
                  calcDetail: '(${pMpa.toStringAsFixed(1)} × 609.6) / (2 × ${tMm.toStringAsFixed(1)})',
                ),
                const SizedBox(height: 10),
                _buildCalcFormulaRow(
                  title: 'Longitudinal Bending: σ_b = E • ε_b',
                  value: '${sigmaB.toStringAsFixed(1)} MPa',
                  calcDetail: '207,000 × (${epsBending.toStringAsFixed(0)} × 10⁻⁶)',
                ),
                const SizedBox(height: 10),
                _buildCalcFormulaRow(
                  title: 'Total Longitudinal: σ_L = ν • σ_h + σ_b',
                  value: '${sigmaL.toStringAsFixed(1)} MPa',
                  calcDetail: '(0.30 × ${sigmaH.toStringAsFixed(1)}) + ${sigmaB.toStringAsFixed(1)}',
                ),
                const SizedBox(height: 10),
                _buildCalcFormulaRow(
                  title: 'Equivalent von Mises: σ_eq',
                  value: '${sigmaEq.toStringAsFixed(1)} MPa',
                  calcDetail: '√(σ_h² + σ_L² - σ_h•σ_L)',
                  isBold: true,
                  valueColor: resultColor,
                ),
                const SizedBox(height: 10),
                _buildCalcFormulaRow(
                  title: 'Radius of Curvature: R = D / (2ε_b)',
                  value: '${radiusOfCurv.toStringAsFixed(0)} m',
                  calcDetail: '0.6096 / (2 × ${epsBending.toStringAsFixed(0)} × 10⁻⁶)',
                ),
                const SizedBox(height: 16),
                const Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 16),

                // Utilization Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Stress Utilization (σ_eq / 0.90 SMYS)',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '${(stressUr * 100).toStringAsFixed(1)}% of ${allowableStress.toStringAsFixed(1)} MPa',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: resultColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stressUr.clamp(0.0, 1.2) / 1.2,
                    backgroundColor: AppTheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(resultColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('0% (Zero Load)', style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                    Text('70% (Yellow)', style: TextStyle(fontSize: 9, color: AppTheme.secondary)),
                    Text('85% (Red)', style: TextStyle(fontSize: 9, color: Color(0xFFF43F5E))),
                    Text('100% (Plastic Limit)', style: TextStyle(fontSize: 9, color: Color(0xFFE11D48))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcFormulaRow({
    required String title,
    required String value,
    required String calcDetail,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  calcDetail,
                  style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: TELEMETRY LOGS & TIME SERIES CHART
  // ==========================================
  Widget _buildTelemetryAndLogsTab(ThemeData theme) {
    final activeStation = _activeStation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs for Time Span
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MICROSTRAIN HISTORY (${activeStation.id})',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  _buildTimeFilterPill(label: '24 Hours', days: 1),
                  const SizedBox(width: 4),
                  _buildTimeFilterPill(label: '7 Days', days: 7),
                  const SizedBox(width: 4),
                  _buildTimeFilterPill(label: '30 Days', days: 30),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Microstrain Multi-line Chart
          Container(
            height: 260,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: _buildHistoryLineChart(activeStation),
          ),
          const SizedBox(height: 10),

          // Chart Clock Position Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendTrace(color: AppTheme.primaryLight, label: '12h Crown'),
              const SizedBox(width: 12),
              _buildLegendTrace(color: const Color(0xFFF59E0B), label: '06h Invert'),
              const SizedBox(width: 12),
              _buildLegendTrace(color: AppTheme.tertiary, label: '03h East'),
              const SizedBox(width: 12),
              _buildLegendTrace(color: const Color(0xFFA855F7), label: '09h West'),
              const SizedBox(width: 12),
              _buildLegendTrace(color: const Color(0xFFF43F5E), label: 'Alert Thresh', isDashed: true),
            ],
          ),
          const SizedBox(height: 20),

          // Riverbank Slope Slip Telemetry Table
          const Text(
            'RIVERBANK SLOPE SLIP & PIEZOMETER TELEMETRY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _buildSlopeSlipTelemetryTable(),
          const SizedBox(height: 20),

          // Geohazard Alert Response SOP Quick Actions
          _buildSopActionsCard(activeStation),
        ],
      ),
    );
  }

  Widget _buildTimeFilterPill({required String label, required int days}) {
    final isSelected = _selectedHistoryDays == days;
    return GestureDetector(
      onTap: () => setState(() => _selectedHistoryDays = days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppTheme.background : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendTrace({required Color color, required String label, bool isDashed = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildHistoryLineChart(RosetteStation station) {
    final history = station.history;
    if (history.isEmpty) {
      return const Center(child: Text('No telemetry history available'));
    }

    final crownSpots = <FlSpot>[];
    final invertSpots = <FlSpot>[];
    final eastSpots = <FlSpot>[];
    final westSpots = <FlSpot>[];

    for (int i = 0; i < history.length; i++) {
      crownSpots.add(FlSpot(i.toDouble(), history[i].crownMicrostrain));
      invertSpots.add(FlSpot(i.toDouble(), history[i].invertMicrostrain.abs()));
      eastSpots.add(FlSpot(i.toDouble(), history[i].eastMicrostrain));
      westSpots.add(FlSpot(i.toDouble(), history[i].westMicrostrain.abs()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppTheme.border.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}με',
                  style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                final int idx = value.toInt();
                if (idx >= 0 && idx < history.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('MM/dd').format(history[idx].timestamp),
                      style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 5500,
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            // 70% Yellow Alert Line (3500 microstrain)
            HorizontalLine(
              y: 3500,
              color: AppTheme.secondary.withValues(alpha: 0.7),
              strokeWidth: 1.5,
              dashArray: [5, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 5, bottom: 2),
                style: const TextStyle(fontSize: 9, color: AppTheme.secondary, fontWeight: FontWeight.w700),
                labelResolver: (line) => '70% Yellow (3500με)',
              ),
            ),
            // 85% Red Alert Line (4250 microstrain)
            HorizontalLine(
              y: 4250,
              color: const Color(0xFFF43F5E).withValues(alpha: 0.8),
              strokeWidth: 1.5,
              dashArray: [5, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 5, bottom: 2),
                style: const TextStyle(fontSize: 9, color: Color(0xFFF43F5E), fontWeight: FontWeight.w700),
                labelResolver: (line) => '85% Red (4250με)',
              ),
            ),
          ],
        ),
        lineBarsData: [
          // Crown
          LineChartBarData(
            spots: crownSpots,
            isCurved: true,
            color: AppTheme.primaryLight,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
          // Invert
          LineChartBarData(
            spots: invertSpots,
            isCurved: true,
            color: const Color(0xFFF59E0B),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
          // East
          LineChartBarData(
            spots: eastSpots,
            isCurved: true,
            color: AppTheme.tertiary,
            barWidth: 1.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
          // West
          LineChartBarData(
            spots: westSpots,
            isCurved: true,
            color: const Color(0xFFA855F7),
            barWidth: 1.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSlopeSlipTelemetryTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.surface),
            horizontalMargin: 12,
            columnSpacing: 18,
            columns: const [
              DataColumn(label: Text('Rosette / Loc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Chainage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Cum Slip (mm)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Slip Rate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Pore Press', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Scour Dep', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Alert Tier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
            ],
            rows: _stations.map((s) {
              final isSelected = s.id == _selectedStationId;
              final alert = s.alertLevel;
              return DataRow(
                selected: isSelected,
                onSelectChanged: (_) {
                  setState(() => _selectedStationId = s.id);
                },
                cells: [
                  DataCell(
                    Row(
                      children: [
                        Text(s.id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                        const SizedBox(width: 4),
                        Icon(alert.icon, size: 12, color: alert.color),
                      ],
                    ),
                  ),
                  DataCell(Text(s.chainage, style: const TextStyle(fontSize: 11))),
                  DataCell(Text('${s.slopeSlipMm.toStringAsFixed(1)} mm', style: const TextStyle(fontSize: 11))),
                  DataCell(
                    Text(
                      '${s.slopeSlipRateMmDay.toStringAsFixed(2)} mm/d',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: s.slopeSlipRateMmDay >= 2.5 ? const Color(0xFFF43F5E) : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  DataCell(Text('${s.porePressureKpa.toStringAsFixed(0)} kPa', style: const TextStyle(fontSize: 11))),
                  DataCell(Text('${s.activeScourDepthM.toStringAsFixed(1)} m', style: const TextStyle(fontSize: 11))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: alert.bgTint,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alert.label,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: alert.color),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSopActionsCard(RosetteStation station) {
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
            children: const [
              Icon(Icons.security_update_warning_rounded, size: 16, color: AppTheme.secondary),
              SizedBox(width: 8),
              Text(
                'STANDARD OPERATING PROCEDURE (SOP) TRIGGERS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFF43F5E)),
                label: const Text('ESDV Pressure Drawdown (Advisory)', style: TextStyle(fontSize: 11)),
                backgroundColor: AppTheme.surface,
                onPressed: () => _triggerSopAction(context, 'ESDV Pressure Drawdown to 65 bar initiated.'),
              ),
              ActionChip(
                avatar: const Icon(Icons.waves_rounded, size: 14, color: AppTheme.primaryLight),
                label: const Text('Mobilize Riprap Barge & Mattresses', style: TextStyle(fontSize: 11)),
                backgroundColor: AppTheme.surface,
                onPressed: () => _triggerSopAction(context, 'Riprap dumping barge mobilized to Burhi Dihing toe.'),
              ),
              ActionChip(
                avatar: const Icon(Icons.radar_rounded, size: 14, color: AppTheme.tertiary),
                label: const Text('Launch Multibeam Echo Sounder Survey', style: TextStyle(fontSize: 11)),
                backgroundColor: AppTheme.surface,
                onPressed: () => _triggerSopAction(context, 'Hydrographic multibeam bathymetric sonar team dispatched.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _triggerSopAction(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
          ],
        ),
        backgroundColor: AppTheme.surfaceContainerHigh,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showExportSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ASME B31.8 / PRCI Geotechnical Strain Report exported to PDF & CSV.'),
        backgroundColor: AppTheme.surfaceContainerHigh,
      ),
    );
  }

  void _showEmergencySopDialog(BuildContext context, RosetteStation station) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Row(
          children: [
            Icon(station.alertLevel.icon, color: station.alertLevel.color),
            const SizedBox(width: 8),
            Text('SOP Actions: ${station.id}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status: ${station.alertLevel.label} (${(station.strainUtilizationRatio * 100).toStringAsFixed(0)}% Allowable Strain)',
              style: TextStyle(fontWeight: FontWeight.w700, color: station.alertLevel.color, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${station.locationDescription} (${station.chainage})\n'
              'von Mises Stress: ${station.vonMisesStressMpa.toStringAsFixed(1)} MPa\n'
              'Bending Radius: ${station.radiusOfCurvatureM.toStringAsFixed(0)} m\n'
              'Active River Scour: ${station.activeScourDepthM.toStringAsFixed(1)} m\n'
              'Slope Slip Rate: ${station.slopeSlipRateMmDay.toStringAsFixed(2)} mm/day',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'Mandatory ASME B31.8 Protocols:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              '1. Real-time strain telemetry logged at 1-min intervals.\n'
              '2. Notify Pipeline Integrity Manager & OISD within 2 hours.\n'
              '3. Reduce linepack pressure if strain exceeds 85% allowable limit.',
              style: TextStyle(fontSize: 10, color: AppTheme.textMuted, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('DISMISS', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _triggerSopAction(context, 'Emergency Geotechnical Alert dispatched to Control Center.');
            },
            style: ElevatedButton.styleFrom(backgroundColor: station.alertLevel.color),
            child: const Text('DISPATCH ADVISORY'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MOCK DATA GENERATOR
  // ==========================================
  static List<RosetteStation> _generateStationData() {
    final now = DateTime.now();

    List<MicrostrainHistoryPoint> generateHistory(double baseCrown, double baseInvert, double baseEast, double baseWest) {
      return List.generate(8, (i) {
        final date = now.subtract(Duration(days: 7 - i));
        final variation = math.sin(i * 0.8) * 180;
        return MicrostrainHistoryPoint(
          timestamp: date,
          crownMicrostrain: (baseCrown + variation).clamp(100.0, 5200.0),
          invertMicrostrain: (baseInvert - variation).clamp(-5200.0, -100.0),
          eastMicrostrain: (baseEast + variation * 0.4).clamp(-2000.0, 2000.0),
          westMicrostrain: (baseWest - variation * 0.4).clamp(-2000.0, 2000.0),
        );
      });
    }

    return [
      RosetteStation(
        id: 'SG-01',
        chainage: 'Ch. 42+120',
        locationDescription: 'South Riverbank Crest Transition',
        chainageOffsetM: 120.0,
        pipeElevationRlm: 98.4,
        riverbedElevationRlm: 102.6,
        activeScourDepthM: 0.4,
        crownStrain: 620.0,
        eastStrain: 240.0,
        invertStrain: -590.0,
        westStrain: -210.0,
        temperatureC: 22.4,
        internalPressureMpa: 9.8,
        slopeSlipMm: 3.2,
        slopeSlipRateMmDay: 0.15,
        porePressureKpa: 42.0,
        lastPing: now.subtract(const Duration(minutes: 2)),
        history: generateHistory(620.0, -590.0, 240.0, -210.0),
      ),
      RosetteStation(
        id: 'SG-02',
        chainage: 'Ch. 42+350',
        locationDescription: 'South Scour Scarp / Toe Slope',
        chainageOffsetM: 350.0,
        pipeElevationRlm: 94.2,
        riverbedElevationRlm: 97.8,
        activeScourDepthM: 2.1,
        crownStrain: 2450.0,
        eastStrain: 610.0,
        invertStrain: -2380.0,
        westStrain: -580.0,
        temperatureC: 21.8,
        internalPressureMpa: 9.8,
        slopeSlipMm: 18.6,
        slopeSlipRateMmDay: 1.20,
        porePressureKpa: 78.0,
        lastPing: now.subtract(const Duration(minutes: 3)),
        history: generateHistory(2450.0, -2380.0, 610.0, -580.0),
      ),
      RosetteStation(
        id: 'SG-03',
        chainage: 'Ch. 42+580',
        locationDescription: 'Thalweg Channel Approach - East',
        chainageOffsetM: 580.0,
        pipeElevationRlm: 88.5,
        riverbedElevationRlm: 91.2,
        activeScourDepthM: 3.8,
        crownStrain: 3680.0, // Yellow alert (>= 3500)
        eastStrain: 940.0,
        invertStrain: -3590.0,
        westStrain: -880.0,
        temperatureC: 20.6,
        internalPressureMpa: 9.8,
        slopeSlipMm: 42.1,
        slopeSlipRateMmDay: 2.85,
        porePressureKpa: 115.0,
        lastPing: now.subtract(const Duration(minutes: 1)),
        history: generateHistory(3680.0, -3590.0, 940.0, -880.0),
      ),
      RosetteStation(
        id: 'SG-04',
        chainage: 'Ch. 42+820',
        locationDescription: 'Deep Thalweg Active Scour Trench',
        chainageOffsetM: 820.0,
        pipeElevationRlm: 84.1,
        riverbedElevationRlm: 86.4,
        activeScourDepthM: 5.6,
        crownStrain: 4420.0, // Red alert (>= 4250)
        eastStrain: 1320.0,
        invertStrain: -4350.0,
        westStrain: -1260.0,
        temperatureC: 19.8,
        internalPressureMpa: 9.8,
        slopeSlipMm: 68.4,
        slopeSlipRateMmDay: 4.90,
        porePressureKpa: 148.0,
        lastPing: now.subtract(const Duration(minutes: 1)),
        history: generateHistory(4420.0, -4350.0, 1320.0, -1260.0),
      ),
      RosetteStation(
        id: 'SG-05',
        chainage: 'Ch. 43+050',
        locationDescription: 'Mid-Channel Sand Bar / Splay Zone',
        chainageOffsetM: 1050.0,
        pipeElevationRlm: 87.3,
        riverbedElevationRlm: 90.8,
        activeScourDepthM: 1.2,
        crownStrain: 1840.0,
        eastStrain: 320.0,
        invertStrain: -1790.0,
        westStrain: -290.0,
        temperatureC: 20.2,
        internalPressureMpa: 9.8,
        slopeSlipMm: 12.3,
        slopeSlipRateMmDay: 0.45,
        porePressureKpa: 65.0,
        lastPing: now.subtract(const Duration(minutes: 4)),
        history: generateHistory(1840.0, -1790.0, 320.0, -290.0),
      ),
      RosetteStation(
        id: 'SG-06',
        chainage: 'Ch. 43+280',
        locationDescription: 'North Active Scour Pool Transition',
        chainageOffsetM: 1280.0,
        pipeElevationRlm: 86.8,
        riverbedElevationRlm: 89.4,
        activeScourDepthM: 4.2,
        crownStrain: 3720.0, // Yellow alert (>= 3500)
        eastStrain: 1050.0,
        invertStrain: -3640.0,
        westStrain: -990.0,
        temperatureC: 20.4,
        internalPressureMpa: 9.8,
        slopeSlipMm: 46.8,
        slopeSlipRateMmDay: 3.10,
        porePressureKpa: 122.0,
        lastPing: now.subtract(const Duration(minutes: 2)),
        history: generateHistory(3720.0, -3640.0, 1050.0, -990.0),
      ),
      RosetteStation(
        id: 'SG-07',
        chainage: 'Ch. 43+490',
        locationDescription: 'North Bank Inclinometer Slip Zone',
        chainageOffsetM: 1490.0,
        pipeElevationRlm: 92.4,
        riverbedElevationRlm: 95.1,
        activeScourDepthM: 4.8,
        crownStrain: 4380.0, // Red alert (>= 4250)
        eastStrain: 1410.0,
        invertStrain: -4290.0,
        westStrain: -1350.0,
        temperatureC: 21.2,
        internalPressureMpa: 9.8,
        slopeSlipMm: 74.2,
        slopeSlipRateMmDay: 5.40,
        porePressureKpa: 160.0,
        lastPing: now.subtract(const Duration(minutes: 1)),
        history: generateHistory(4380.0, -4290.0, 1410.0, -1350.0),
      ),
      RosetteStation(
        id: 'SG-08',
        chainage: 'Ch. 43+640',
        locationDescription: 'North Riverbank Tie-in Anchor Block',
        chainageOffsetM: 1640.0,
        pipeElevationRlm: 99.1,
        riverbedElevationRlm: 103.5,
        activeScourDepthM: 0.3,
        crownStrain: 710.0,
        eastStrain: 190.0,
        invertStrain: -680.0,
        westStrain: -170.0,
        temperatureC: 22.8,
        internalPressureMpa: 9.8,
        slopeSlipMm: 4.1,
        slopeSlipRateMmDay: 0.18,
        porePressureKpa: 38.0,
        lastPing: now.subtract(const Duration(minutes: 3)),
        history: generateHistory(710.0, -680.0, 190.0, -170.0),
      ),
    ];
  }
}

// ==========================================
// CUSTOM PAINTER: 3D PIPELINE WIREFRAME
// ==========================================
class _Pipeline3DWireframePainter extends CustomPainter {
  final List<RosetteStation> stations;
  final String activeStationId;
  final double azimuthDeg;
  final double elevationDeg;
  final double deflectionMagnification;
  final double zoom;
  final bool showTerrainScour;
  final bool showWaterSurface;

  _Pipeline3DWireframePainter({
    required this.stations,
    required this.activeStationId,
    required this.azimuthDeg,
    required this.elevationDeg,
    required this.deflectionMagnification,
    required this.zoom,
    required this.showTerrainScour,
    required this.showWaterSurface,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background Grid
    final gridPaint = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3D Rotation Matrix parameters
    final double azRad = azimuthDeg * math.pi / 180.0;
    final double elRad = elevationDeg * math.pi / 180.0;
    final double cosAz = math.cos(azRad);
    final double sinAz = math.sin(azRad);
    final double cosEl = math.cos(elRad);
    final double sinEl = math.sin(elRad);

    // World to Screen Projection Helper
    Offset project(double wx, double wy, double wz) {
      // Rotate around Z by azimuth
      final double rx = wx * cosAz - wy * sinAz;
      final double ry = wx * sinAz + wy * cosAz;

      // Rotate around X by elevation
      final double rz = wz * cosEl - ry * sinEl;
      final double projY = wz * sinEl + ry * cosEl;

      // Perspective divide
      final double scale = (350.0 / (350.0 + projY * 0.15)) * zoom;
      return Offset(cx + rx * scale, cy - rz * scale);
    }

    // Draw Water Surface Plane if enabled
    if (showWaterSurface) {
      final waterPaint = Paint()
        ..color = const Color(0x1800E5FF)
        ..style = PaintingStyle.fill;
      final waterBorder = Paint()
        ..color = const Color(0x4400E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final w1 = project(-180, -70, 20);
      final w2 = project(180, -70, 20);
      final w3 = project(180, 70, 20);
      final w4 = project(-180, 70, 20);

      final waterPath = Path()
        ..moveTo(w1.dx, w1.dy)
        ..lineTo(w2.dx, w2.dy)
        ..lineTo(w3.dx, w3.dy)
        ..lineTo(w4.dx, w4.dy)
        ..close();
      canvas.drawPath(waterPath, waterPaint);
      canvas.drawPath(waterPath, waterBorder);
    }

    // Draw Riverbed / Scour Trench Terrain Contour if enabled
    if (showTerrainScour) {
      final bedPaint = Paint()
        ..color = const Color(0x1A8D6E63)
        ..style = PaintingStyle.fill;
      final bedWire = Paint()
        ..color = const Color(0x338D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Terrain mesh across river transect
      for (double x = -160; x <= 160; x += 40) {
        // Thalweg dips near center
        final distFromCenter = x.abs();
        final scourDip = math.max(0.0, 35.0 - distFromCenter * 0.22);
        final t1 = project(x, -50, 10 - scourDip);
        final t2 = project(x + 35, -50, 10 - (math.max(0.0, 35.0 - (distFromCenter + 35) * 0.22)));
        final t3 = project(x + 35, 50, 10 - (math.max(0.0, 35.0 - (distFromCenter + 35) * 0.22)));
        final t4 = project(x, 50, 10 - scourDip);

        final p = Path()
          ..moveTo(t1.dx, t1.dy)
          ..lineTo(t2.dx, t2.dy)
          ..lineTo(t3.dx, t3.dy)
          ..lineTo(t4.dx, t4.dy)
          ..close();
        canvas.drawPath(p, bedPaint);
        canvas.drawPath(p, bedWire);
      }
    }

    // Generate 3D pipeline centerline and cylindrical ring wireframes
    const int numSegments = 64;
    final List<Offset> topGeneratrix = [];
    final List<Offset> bottomGeneratrix = [];
    final List<Offset> leftGeneratrix = [];
    final List<Offset> rightGeneratrix = [];
    final List<Offset> centerLine = [];

    const double pipeRadius = 8.0; // Visual radius for 24" pipe wireframe

    for (int i = 0; i <= numSegments; i++) {
      final double t = i / numSegments.toDouble();
      // Pipe spans from x = -170 to +170 across river
      final double wx = -170.0 + t * 340.0;

      // Natural catenary sagging + localized scour sag + bank slip
      final double midFactor = math.sin(t * math.pi);
      // Double peak scour sagging at Thalweg (t = 0.45) and North pool (t = 0.85)
      final double scourSag1 = math.exp(-math.pow((t - 0.45) / 0.15, 2)) * 32.0;
      final double scourSag2 = math.exp(-math.pow((t - 0.82) / 0.12, 2)) * 26.0;
      final double bankSlipY = math.exp(-math.pow((t - 0.88) / 0.14, 2)) * 18.0; // Bank slip displacement

      final double deflScale = (deflectionMagnification / 25.0);
      final double wz = -(15.0 * midFactor + scourSag1 + scourSag2) * deflScale;
      final double wy = bankSlipY * deflScale;

      centerLine.add(project(wx, wy, wz));
      topGeneratrix.add(project(wx, wy, wz + pipeRadius));
      bottomGeneratrix.add(project(wx, wy, wz - pipeRadius));
      leftGeneratrix.add(project(wx, wy + pipeRadius, wz));
      rightGeneratrix.add(project(wx, wy - pipeRadius, wz));

      // Draw circular ring wireframe at regular intervals
      if (i % 4 == 0) {
        final ringPath = Path();
        const int ringPoints = 12;
        for (int r = 0; r <= ringPoints; r++) {
          final double theta = (r / ringPoints) * 2 * math.pi;
          final double crY = wy + math.sin(theta) * pipeRadius;
          final double crZ = wz + math.cos(theta) * pipeRadius;
          final pt = project(wx, crY, crZ);
          if (r == 0) {
            ringPath.moveTo(pt.dx, pt.dy);
          } else {
            ringPath.lineTo(pt.dx, pt.dy);
          }
        }

        // Color rings based on stress/strain along profile
        Color ringColor = AppTheme.tertiary;
        if (scourSag1 > 20.0 || scourSag2 > 18.0) {
          ringColor = const Color(0xFFF43F5E); // Red alert zone
        } else if (scourSag1 > 12.0 || scourSag2 > 10.0) {
          ringColor = AppTheme.secondary; // Yellow alert zone
        }

        final ringPaint = Paint()
          ..color = ringColor.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawPath(ringPath, ringPaint);
      }
    }

    // Draw Longitudinal Wireframe Generator Lines
    void drawLineStrip(List<Offset> pts, Color color, double width) {
      if (pts.length < 2) return;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width;
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    drawLineStrip(topGeneratrix, AppTheme.primaryLight.withValues(alpha: 0.75), 1.5);
    drawLineStrip(bottomGeneratrix, const Color(0xFFF59E0B).withValues(alpha: 0.75), 1.5);
    drawLineStrip(leftGeneratrix, AppTheme.border.withValues(alpha: 0.5), 1.0);
    drawLineStrip(rightGeneratrix, AppTheme.border.withValues(alpha: 0.5), 1.0);
    drawLineStrip(centerLine, Colors.white.withValues(alpha: 0.4), 1.0);

    // Draw Rosette Station Markers & Beacons (SG-01 to SG-08)
    for (int idx = 0; idx < stations.length; idx++) {
      final st = stations[idx];
      // Map station offset to normalized t along pipe [120m to 1640m]
      final double t = (st.chainageOffsetM - 120.0) / (1640.0 - 120.0);
      final double wx = -170.0 + t * 340.0;
      final double midFactor = math.sin(t * math.pi);
      final double scourSag1 = math.exp(-math.pow((t - 0.45) / 0.15, 2)) * 32.0;
      final double scourSag2 = math.exp(-math.pow((t - 0.82) / 0.12, 2)) * 26.0;
      final double bankSlipY = math.exp(-math.pow((t - 0.88) / 0.14, 2)) * 18.0;

      final double deflScale = (deflectionMagnification / 25.0);
      final double wz = -(15.0 * midFactor + scourSag1 + scourSag2) * deflScale;
      final double wy = bankSlipY * deflScale;

      final pipePt = project(wx, wy, wz);
      final beaconPt = project(wx, wy, wz + 28);

      final isSelected = st.id == activeStationId;
      final alert = st.alertLevel;

      // Stem line
      final stemPaint = Paint()
        ..color = alert.color.withValues(alpha: isSelected ? 0.9 : 0.5)
        ..strokeWidth = isSelected ? 2.0 : 1.2;
      canvas.drawLine(pipePt, beaconPt, stemPaint);

      // Rosette Node Beacon
      final nodePaint = Paint()
        ..color = alert.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(beaconPt, isSelected ? 6.0 : 4.0, nodePaint);

      if (isSelected) {
        final haloPaint = Paint()
          ..color = alert.color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(beaconPt, 10.0, haloPaint);
      }

      // Station ID Text Label
      final textSpan = TextSpan(
        text: st.id,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontSize: isSelected ? 10 : 8,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(beaconPt.dx - textPainter.width / 2, beaconPt.dy - 16),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Pipeline3DWireframePainter oldDelegate) {
    return oldDelegate.azimuthDeg != azimuthDeg ||
        oldDelegate.elevationDeg != elevationDeg ||
        oldDelegate.deflectionMagnification != deflectionMagnification ||
        oldDelegate.zoom != zoom ||
        oldDelegate.activeStationId != activeStationId ||
        oldDelegate.showTerrainScour != showTerrainScour ||
        oldDelegate.showWaterSurface != showWaterSurface;
  }
}

// ==========================================
// CUSTOM PAINTER: 4-QUADRANT CLOCK ROSETTE
// ==========================================
class _RosetteCrossSectionPainter extends CustomPainter {
  final double crownStrain;
  final double eastStrain;
  final double invertStrain;
  final double westStrain;
  final Color alertColor;

  _RosetteCrossSectionPainter({
    required this.crownStrain,
    required this.eastStrain,
    required this.invertStrain,
    required this.westStrain,
    required this.alertColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Outer pipe circle
    final pipePaint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(Offset(cx, cy), r, pipePaint);

    // Inner pipe cavity
    final innerPaint = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r - 4, innerPaint);

    // Coordinate crosshairs (vertical and horizontal axes)
    final axisPaint = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(cx, cy - r - 8), Offset(cx, cy + r + 8), axisPaint);
    canvas.drawLine(Offset(cx - r - 8, cy), Offset(cx + r + 8, cy), axisPaint);

    // 4 Gauge Nodes at 12, 3, 6, 9 o'clock
    void drawGauge(double gx, double gy, double strain, String label) {
      final isTension = strain >= 0;
      final nodeColor = isTension ? AppTheme.primaryLight : const Color(0xFFF59E0B);

      final nodePaint = Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(gx, gy), 6, nodePaint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(gx, gy), 6, borderPaint);
    }

    drawGauge(cx, cy - r, crownStrain, '12');
    drawGauge(cx + r, cy, eastStrain, '3');
    drawGauge(cx, cy + r, invertStrain, '6');
    drawGauge(cx - r, cy, westStrain, '9');

    // Neutral Axis tilt line
    // eps_bv = (eps12 - eps6)/2, eps_bh = (eps3 - eps9)/2
    final epsBv = (crownStrain - invertStrain) / 2.0;
    final epsBh = (eastStrain - westStrain) / 2.0;
    final double angle = math.atan2(epsBv, epsBh);

    final naX1 = cx + math.sin(angle) * (r - 6);
    final naY1 = cy - math.cos(angle) * (r - 6);
    final naX2 = cx - math.sin(angle) * (r - 6);
    final naY2 = cy + math.cos(angle) * (r - 6);

    final naPaint = Paint()
      ..color = alertColor.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(naX1, naY1), Offset(naX2, naY2), naPaint);

    // Center badge with 24" pipe label
    const centerText = TextSpan(
      text: '24"\nPIPE',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppTheme.textSecondary,
        height: 1.1,
      ),
    );
    final textPainter = TextPainter(
      text: centerText,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RosetteCrossSectionPainter oldDelegate) {
    return oldDelegate.crownStrain != crownStrain ||
        oldDelegate.eastStrain != eastStrain ||
        oldDelegate.invertStrain != invertStrain ||
        oldDelegate.westStrain != westStrain ||
        oldDelegate.alertColor != alertColor;
  }
}
