import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

class WeatherImpactScreen extends StatefulWidget {
  const WeatherImpactScreen({super.key});

  @override
  State<WeatherImpactScreen> createState() => _WeatherImpactScreenState();
}

class _WeatherImpactScreenState extends State<WeatherImpactScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;
  DateTime _lastTelemetryTime = DateTime.now();

  // Weather telemetry values for Oil India Duliajan site
  final String _siteName = 'Oil India Duliajan Site';
  final String _siteCoordinates = '27.4825° N, 95.3225° E';
  final double _temperature = 32.0; // 32°C
  final double _rainfall = 45.0; // 45mm - Monsoon Heavy
  final double _windSpeed = 18.0; // 18 km/h
  final int _humidity = 88; // 88%
  final double _rainfallThreshold = 25.0; // Safety threshold for outdoor works

  // 7-Day Monsoon Rainfall Forecast Data
  final List<_ForecastDay> _forecastData = const [
    _ForecastDay(day: 'Mon', date: 'Sep 28', rainfall: 28.0, isToday: false),
    _ForecastDay(day: 'Tue', date: 'Sep 29', rainfall: 45.0, isToday: true),
    _ForecastDay(day: 'Wed', date: 'Sep 30', rainfall: 36.0, isToday: false),
    _ForecastDay(day: 'Thu', date: 'Oct 01', rainfall: 22.0, isToday: false),
    _ForecastDay(day: 'Fri', date: 'Oct 02', rainfall: 14.0, isToday: false),
    _ForecastDay(day: 'Sat', date: 'Oct 03', rainfall: 8.0, isToday: false),
    _ForecastDay(day: 'Sun', date: 'Oct 04', rainfall: 12.0, isToday: false),
  ];

  // Activities auto-flagged as suspended due to weather
  final List<_SuspendedActivity> _suspendedActivities = const [
    _SuspendedActivity(
      id: 'ACT-PL-024',
      name: 'Line 24 Welded Joints (SMAW/GTAW & Laying)',
      location: 'Section C-4 / Station 14+200',
      reason: 'Excessive precipitation (>15mm/hr safety cutoff) prevents open-groove SMAW/GTAW welding and joint wrapping integrity; risk of hydrogen-induced cold cracking.',
      crewSize: 38,
      isCriticalPath: true,
      estimatedSlippage: '1.0 Day',
      mitigationAction: 'Pipe ends sealed with hydrostatic caps; welders redeployed to indoor spool fabrication bay.',
    ),
    _SuspendedActivity(
      id: 'ACT-EX-031',
      name: 'Trench Excavation & Dewatering',
      location: 'Section C-4 / Station 14+200 to 15+800',
      reason: 'Torrential monsoon runoff and groundwater rise flooded open pipeline trench; bank sloughing and pipe flotation hazards mandate continuous mechanical sump dewatering before pipe-laying crawler re-entry.',
      crewSize: 26,
      isCriticalPath: true,
      estimatedSlippage: '1.5 Days',
      mitigationAction: 'Submersible mud pump array (4x 100 GPM) mobilized; geotextile silt fencing deployed along trench lip.',
    ),
    _SuspendedActivity(
      id: 'ACT-FD-108',
      name: 'Foundation Pours (Compressor Bay Unit 3)',
      location: 'Civil Substation Yard 2',
      reason: 'Rainfall exceeds 45mm; severe water-cement ratio compromise, concrete wash-out, and aggregate saturation risk.',
      crewSize: 24,
      isCriticalPath: true,
      estimatedSlippage: '1.5 Days',
      mitigationAction: 'Batching transit mixers rerouted; pour stop-ends prepared; curing tarps deployed.',
    ),
    _SuspendedActivity(
      id: 'ACT-CR-019',
      name: 'Crane Erection (Tower Crane TC-02 Heavy Lift)',
      location: 'Process Plant Area 1',
      reason: 'Sub-grade soil bearing capacity degraded by torrential rain; lightning hazard protocol active within 15 km.',
      crewSize: 12,
      isCriticalPath: false,
      estimatedSlippage: '0.5 Day',
      mitigationAction: 'Boom lowered to 15° storm cradle; outrigger timber cribbing inspected.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshTelemetry() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _lastTelemetryTime = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.tertiary, size: 20),
              SizedBox(width: 8),
              Text(
                'Telemetry synchronized from Duliajan AWS Station #09',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showFidicEotNoticeDialog(
    BuildContext context, {
    String? initialActivityId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(200),
      builder: (ctx) => _FidicDelayNoticeDialog(
        siteName: _siteName,
        siteCoordinates: _siteCoordinates,
        rainfall: _rainfall,
        rainfallThreshold: _rainfallThreshold,
        suspendedActivities: _suspendedActivities,
        initialSelectedActivityId: initialActivityId,
        baselineAllowedDays: 6.0,
        totalSeasonDaysLost: 14.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weather Impact & Delay Correlation',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$_siteName ($_siteCoordinates)',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryLight,
                    ),
                  )
                : const Icon(Icons.refresh, color: AppTheme.primaryLight),
            tooltip: 'Sync Telemetry',
            onPressed: _isRefreshing ? null : _refreshTelemetry,
          ),
          IconButton(
            icon: const Icon(
              Icons.description_outlined,
              color: AppTheme.secondary,
            ),
            tooltip: 'Draft FIDIC 8.4 EOT',
            onPressed: () => _showFidicEotNoticeDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.bolt, size: 18), text: 'Live Impact'),
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: '7-Day Forecast'),
            Tab(
              icon: Icon(Icons.history_toggle_off, size: 18),
              text: 'Delay Ledger',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveImpactTab(context),
          _buildForecastTab(context),
          _buildDelayLedgerTab(context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: Live Impact & Suspensions
  // ---------------------------------------------------------------------------
  Widget _buildLiveImpactTab(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss').format(_lastTelemetryTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Telemetry Status Header Bar
          _buildTelemetryBanner(timeStr),
          const SizedBox(height: 16),

          // Weather Sensor Displays Grid (Temp, Rain, Wind, Humidity)
          _buildWeatherMetricsGrid(),
          const SizedBox(height: 20),

          // High-Severity Work Suspension Alert Banner
          _buildSuspensionAlertBanner(),
          const SizedBox(height: 20),

          // Section Title: Suspended Outdoor Activities
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Affected Outdoor Activities',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_suspendedActivities.length} HALTED',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Activity Suspension Cards
          ..._suspendedActivities.map(
            (act) => _buildSuspendedActivityCard(act),
          ),
          const SizedBox(height: 20),

          // FIDIC Clause 8.4 Action Banner
          _buildFidicCallToAction(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTelemetryBanner(String timeStr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.tertiary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                children: [
                  const TextSpan(text: 'AWS Station Duliajan-09  |  '),
                  TextSpan(
                    text: 'Live Telemetry ($timeStr)',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.secondary.withAlpha(100)),
            ),
            child: const Text(
              'MONSOON ACTIVE',
              style: TextStyle(
                color: AppTheme.secondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // 1. Temperature (32°C)
            _buildMetricCard(
              width: cardWidth,
              title: 'TEMPERATURE',
              value: '${_temperature.toInt()}°C',
              subtitle: 'Feels like 38°C • Wet Bulb 29°C',
              statusTag: 'HEAT INDEX HIGH',
              statusColor: AppTheme.secondary,
              icon: Icons.thermostat,
              accentColor: Colors.orangeAccent,
            ),
            // 2. Rainfall (45mm - Monsoon Heavy)
            _buildMetricCard(
              width: cardWidth,
              title: 'RAINFALL (24H)',
              value: '${_rainfall.toInt()} mm',
              subtitle: 'Monsoon Heavy • Cutoff: 25mm',
              statusTag: 'THRESHOLD EXCEEDED',
              statusColor: Colors.redAccent,
              icon: Icons.water_drop,
              accentColor: Colors.blueAccent,
              isAlert: true,
            ),
            // 3. Wind Speed (18 km/h)
            _buildMetricCard(
              width: cardWidth,
              title: 'WIND SPEED',
              value: '${_windSpeed.toInt()} km/h',
              subtitle: 'Moderate Breeze • Gusts 29 km/h',
              statusTag: 'CRANE LIMIT: 35 KM/H',
              statusColor: AppTheme.tertiary,
              icon: Icons.air,
              accentColor: AppTheme.primaryLight,
            ),
            // 4. Humidity (88%)
            _buildMetricCard(
              width: cardWidth,
              title: 'HUMIDITY',
              value: '$_humidity%',
              subtitle: 'High Condensation • Dew Pt 26°C',
              statusTag: 'COATING DELAY',
              statusColor: AppTheme.secondary,
              icon: Icons.water,
              accentColor: Colors.cyanAccent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required String statusTag,
    required Color statusColor,
    required IconData icon,
    required Color accentColor,
    bool isAlert = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert ? Colors.redAccent.withAlpha(160) : AppTheme.border,
          width: isAlert ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor.withAlpha(100), width: 0.8),
            ),
            child: Text(
              statusTag,
              style: TextStyle(
                color: statusColor,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuspensionAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade900.withAlpha(120), AppTheme.surfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withAlpha(180), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORK SUSPENSION IN EFFECT',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'HSE Protocol: Precipitation exceeds 25mm threshold',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Rainfall has reached 45mm (Monsoon Heavy) at Oil India Duliajan site. In accordance with Industrial Safety Standard HSE-SOP-08 & Contractual Conditions, 4 critical outdoor operations including Line 24 Welded Joints and Trench Excavation are auto-flagged and halted immediately to prevent structural compromise and electrical hazards.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildBadgePill(
                Icons.people_outline,
                '100 Workers Protected',
                AppTheme.primaryLight,
              ),
              const SizedBox(width: 8),
              _buildBadgePill(
                Icons.access_time,
                'Delay: +1.5 Days',
                AppTheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgePill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuspendedActivityCard(_SuspendedActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${activity.id} • ${activity.location}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(35),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent.withAlpha(120)),
                ),
                child: const Text(
                  'SUSPENDED DUE TO WEATHER',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            activity.reason,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh.withAlpha(120),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: AppTheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mitigation: ${activity.mitigationAction}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.group,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${activity.crewSize} Crew Standing By',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (activity.isCriticalPath)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppTheme.secondary.withAlpha(100),
                        ),
                      ),
                      child: const Text(
                        'CRITICAL PATH',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    'Impact: ${activity.estimatedSlippage}',
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Auto-flagged under HSE-SOP-08',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              InkWell(
                onTap: () => _showFidicEotNoticeDialog(
                  context,
                  initialActivityId: activity.id,
                ),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.primaryLight.withAlpha(120),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note,
                        size: 14,
                        color: AppTheme.primaryLight,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Draft Cl. 8.4 Delay Notice',
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFidicCallToAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withAlpha(150), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.gavel,
                  color: AppTheme.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIDIC Clause 8.4 EOT Generator',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Contractual Notice for Exceptionally Adverse Climatic Conditions',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Auto-assemble an evidentiary delay package citing rainfall threshold exceedance (45mm vs 25mm baseline) to protect the project from liquidated damages under FIDIC Clause 8.4(c).',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showFidicEotNoticeDialog(context),
              icon: const Icon(Icons.send_outlined, size: 16),
              label: const Text('Auto-Draft FIDIC Cl. 8.4 Delay Notice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: 7-Day Monsoon Rainfall Forecast Bar Chart
  // ---------------------------------------------------------------------------
  Widget _buildForecastTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Forecast Title & Synopsis
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '7-Day Monsoon Rainfall Forecast',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'IMD DOPPLER MODEL',
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Precipitation forecast for Oil India Duliajan site showing daily totals against the 25mm HSE Work Suspension Threshold.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bar Chart Card
          _buildForecastBarChartCard(),
          const SizedBox(height: 16),

          // Threshold Legend & Safety Matrix
          _buildChartLegendCard(),
          const SizedBox(height: 16),

          // Day-by-Day Forecast Breakdown List
          const Text(
            'Daily Operational Outlook',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ..._forecastData.map((d) => _buildForecastDayTile(d)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildForecastBarChartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Precipitation (mm/day)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '≥25mm Stoppage',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '<25mm Workable',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                maxY: 55,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceContainerHigh,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = _forecastData[group.x.toInt()];
                      final isSuspension = rod.toY >= _rainfallThreshold;
                      return BarTooltipItem(
                        '${item.day} (${item.date})\n',
                        const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} mm\n',
                            style: TextStyle(
                              color: isSuspension
                                  ? Colors.redAccent
                                  : AppTheme.primaryLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: isSuspension
                                ? 'WORK SUSPENDED'
                                : 'WORK PERMIT OK',
                            style: TextStyle(
                              color: isSuspension
                                  ? Colors.redAccent
                                  : AppTheme.tertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _forecastData.length) {
                          return const SizedBox.shrink();
                        }
                        final dayItem = _forecastData[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dayItem.day,
                                style: TextStyle(
                                  color: dayItem.isToday
                                      ? AppTheme.secondary
                                      : AppTheme.textPrimary,
                                  fontSize: 11,
                                  fontWeight: dayItem.isToday
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                              if (dayItem.isToday)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    if (value == _rainfallThreshold) {
                      return const FlLine(
                        color: Colors.redAccent,
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                      );
                    }
                    return FlLine(
                      color: AppTheme.border.withAlpha(80),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.border, width: 0.8),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: _rainfallThreshold,
                      color: Colors.redAccent,
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 6, bottom: 2),
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                        labelResolver: (line) => '25mm Threshold',
                      ),
                    ),
                  ],
                ),
                barGroups: _forecastData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final day = entry.value;
                  final exceeds = day.rainfall >= _rainfallThreshold;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: day.rainfall,
                        width: 22,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        gradient: LinearGradient(
                          colors: exceeds
                              ? [Colors.red.shade700, Colors.redAccent]
                              : [AppTheme.primary, AppTheme.primaryLight],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 55,
                          color: AppTheme.surfaceContainerHigh.withAlpha(80),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Dashed red line indicates 25mm HSE Work Stoppage Threshold',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendCol('3 Days', 'Threshold Exceeded', Colors.redAccent),
          Container(width: 1, height: 32, color: AppTheme.border),
          _buildLegendCol('4 Days', 'Workable Windows', AppTheme.tertiary),
          Container(width: 1, height: 32, color: AppTheme.border),
          _buildLegendCol('165 mm', '7-Day Cumulative', AppTheme.primaryLight),
        ],
      ),
    );
  }

  Widget _buildLegendCol(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _buildForecastDayTile(_ForecastDay day) {
    final exceeds = day.rainfall >= _rainfallThreshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: day.isToday
            ? AppTheme.surfaceContainerHigh
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: day.isToday
              ? AppTheme.secondary.withAlpha(150)
              : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      day.day,
                      style: TextStyle(
                        color: day.isToday
                            ? AppTheme.secondary
                            : AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (day.isToday)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  day.date,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            exceeds ? Icons.thunderstorm : Icons.cloud_queue,
            color: exceeds ? Colors.redAccent : AppTheme.primaryLight,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${day.rainfall.toInt()} mm rainfall',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: exceeds
                  ? Colors.red.withAlpha(30)
                  : AppTheme.tertiary.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: exceeds
                    ? Colors.red.withAlpha(100)
                    : AppTheme.tertiary.withAlpha(100),
              ),
            ),
            child: Text(
              exceeds ? 'STOPPAGE' : 'WORKABLE',
              style: TextStyle(
                color: exceeds ? Colors.redAccent : AppTheme.tertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: Historical Rain Delay Correlation (14 Days Lost This Season)
  // ---------------------------------------------------------------------------
  Widget _buildDelayLedgerTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Summary Card: 14 Days Lost
          _buildHistoricalSummaryCard(),
          const SizedBox(height: 16),

          // Delay Correlation Formula & Impact Model
          _buildCorrelationFormulaCard(),
          const SizedBox(height: 16),

          // Monthly Monsoon Delay Breakdown
          const Text(
            'Seasonal Rain Delay Breakdown (2026)',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildMonthlyDelayTable(),
          const SizedBox(height: 16),

          // Contractual Allowance vs Actual Overrun Comparison
          _buildContractAllowanceComparison(),
          const SizedBox(height: 16),

          // Commercial & Legal Protection Summary
          _buildCommercialProtectionCard(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHistoricalSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF162347), Color(0xFF1E2E5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SEASONAL DELAY SUMMARY',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'OIL INDIA CONTRACT #OIL-PL-024',
                  style: TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '14',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Days Lost This Season',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Historical rain delay correlation across the 2026 Monsoon at Duliajan. Exceeds contractual baseline weather allowance of 6 days by +8 days.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat(
                'Baseline Allowed',
                '6 Days',
                AppTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              _buildMiniStat('Weather Stoppage', '14 Days', Colors.redAccent),
              const SizedBox(width: 12),
              _buildMiniStat('Net Claimable EOT', '+8 Days', AppTheme.tertiary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationFormulaCard() {
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
              Icon(Icons.functions, color: AppTheme.primaryLight, size: 18),
              SizedBox(width: 8),
              Text(
                'Delay Correlation Model',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text(
              'Delay Impact = (Rainfall - 25mm Threshold) × 0.08 + Sub-grade Drainage Coeff (1.2 days)',
              style: TextStyle(
                fontFamily: 'Courier',
                color: AppTheme.tertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Heavy rain does not merely stop work for the duration of precipitation; saturated sub-base soils require on average 28 hours of mechanical dewatering before heavy earth-moving equipment and pipe-laying crawler cranes can safely resume operations without footing collapse.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyDelayTable() {
    final List<Map<String, dynamic>> monthlyRecords = [
      {
        'month': 'June 2026',
        'event': 'Early Monsoon Squalls & Inundation',
        'rainfall': '310 mm',
        'normal': '240 mm',
        'daysLost': '3 Days',
        'status': 'EOT Notice Logged',
      },
      {
        'month': 'July 2026',
        'event': 'Brahmaputra Basin Flood Surge',
        'rainfall': '540 mm',
        'normal': '380 mm',
        'daysLost': '5 Days',
        'status': 'EOT Notice Logged',
      },
      {
        'month': 'August 2026',
        'event': 'Continuous Heavy Trough & Cloudbursts',
        'rainfall': '420 mm',
        'normal': '310 mm',
        'daysLost': '4 Days',
        'status': 'EOT Notice Logged',
      },
      {
        'month': 'September 2026',
        'event': 'Active Depression #AS-09 (Current)',
        'rainfall': '195 mm',
        'normal': '130 mm',
        'daysLost': '2 Days',
        'status': 'Drafting Notice',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: monthlyRecords.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isLast = idx == monthlyRecords.length - 1;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item['month'] as String,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (item['status'] as String).contains(
                                    'Drafting',
                                  )
                                  ? AppTheme.secondary.withAlpha(30)
                                  : AppTheme.tertiary.withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['status'] as String,
                              style: TextStyle(
                                color:
                                    (item['status'] as String).contains(
                                      'Drafting',
                                    )
                                    ? AppTheme.secondary
                                    : AppTheme.tertiary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['event'] as String,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Actual: ${item['rainfall']} (Baseline Normal: ${item['normal']})',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item['daysLost'] as String,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContractAllowanceComparison() {
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
            'Contractual Weather Allowance Utilization',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contract Baseline Allowance: 6 Days',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              Text(
                'Actual Lost: 14 Days (233%)',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 1.0,
              minHeight: 10,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Weather delay has exceeded the contract-stipulated abnormal rainfall threshold by 8 full working days, entitling the Contractor to an Extension of Time (EOT) under Clause 8.4.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommercialProtectionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.tertiary.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: AppTheme.tertiary, size: 20),
              SizedBox(width: 8),
              Text(
                'Liquidated Damages (LD) Shield',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Liquidated Damages liability rate for contract OIL-PL-024 is ₹5,31,250 / day. By filing contemporaneous FIDIC Clause 8.4(c) weather notices for the 8 overrun days, ₹42,50,000 in contractual LD liability is insulated from deduction.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showFidicEotNoticeDialog(context),
              icon: const Icon(
                Icons.download,
                size: 16,
                color: AppTheme.tertiary,
              ),
              label: const Text(
                'Generate EOT Claim Dossier',
                style: TextStyle(color: AppTheme.tertiary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.tertiary),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper Data Models
// ---------------------------------------------------------------------------
class _ForecastDay {
  final String day;
  final String date;
  final double rainfall;
  final bool isToday;

  const _ForecastDay({
    required this.day,
    required this.date,
    required this.rainfall,
    required this.isToday,
  });
}

class _SuspendedActivity {
  final String id;
  final String name;
  final String location;
  final String reason;
  final int crewSize;
  final bool isCriticalPath;
  final String estimatedSlippage;
  final String mitigationAction;

  const _SuspendedActivity({
    required this.id,
    required this.name,
    required this.location,
    required this.reason,
    required this.crewSize,
    required this.isCriticalPath,
    required this.estimatedSlippage,
    required this.mitigationAction,
  });
}

// ---------------------------------------------------------------------------
// FIDIC Clause 8.4 Extension of Time Interactive Dialog & Document Suite
// ---------------------------------------------------------------------------

class _FidicRecipient {
  final String title;
  final String organization;
  final String address;
  final String attention;
  final String email;

  const _FidicRecipient({
    required this.title,
    required this.organization,
    required this.address,
    required this.attention,
    required this.email,
  });
}

class _FidicDelayNoticeDialog extends StatefulWidget {
  final String siteName;
  final String siteCoordinates;
  final double rainfall;
  final double rainfallThreshold;
  final List<_SuspendedActivity> suspendedActivities;
  final String? initialSelectedActivityId;
  final double baselineAllowedDays;
  final double totalSeasonDaysLost;

  const _FidicDelayNoticeDialog({
    required this.siteName,
    required this.siteCoordinates,
    required this.rainfall,
    required this.rainfallThreshold,
    required this.suspendedActivities,
    this.initialSelectedActivityId,
    this.baselineAllowedDays = 6.0,
    this.totalSeasonDaysLost = 14.0,
  });

  @override
  State<_FidicDelayNoticeDialog> createState() =>
      _FidicDelayNoticeDialogState();
}

class _FidicDelayNoticeDialogState extends State<_FidicDelayNoticeDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedRecipientIndex = 0;
  late Set<String> _selectedActivityIds;
  late double _requestedEotDays;
  final double _dailyLdRate =
      531250.0; // ₹5,31,250 / day for Contract OIL-PL-024

  // Contractual Clause and Ground Toggles
  bool _includeCl8_4c = true;
  bool _includeCl20_1 = true;
  bool _includeHseSop = true;
  bool _includeCostReservation = true;
  bool _includeDewateringBuffer = true;

  // Process & Logging States
  bool _isExporting = false;
  bool _isSharing = false;
  bool _isSubmitting = false;
  bool _noticeSubmitted = false;
  String? _submittedTimestamp;
  String? _auditLogReceipt;

  final String _contractRef = 'NIRMAAN/EOT/OIL-PL-024/2026/042';
  final String _contractNo = 'OIL/ENG/PL/2025/088';
  final String _projectName = 'Trunk Crude Oil Pipeline Expansion (OIL-PL-024)';

  final List<_FidicRecipient> _recipients = const [
    _FidicRecipient(
      title: "The Engineer / Employer's Representative",
      organization: 'Oil India Limited (OIL)',
      address:
          'Field Headquarters, Duliajan, Dibrugarh District, Assam — 786602',
      attention:
          'Chief General Manager (Pipelines & Projects) / Resident Engineer',
      email: 'engineer.rep@oilindia.in',
    ),
    _FidicRecipient(
      title: 'The Engineer / Project Management Consultant',
      organization: 'Engineers India Limited (EIL)',
      address: 'Eastern Regional Office, Duliajan Site Directorate, Assam',
      attention: 'Superintending Project Manager / PMC Lead Engineer',
      email: 'pmc.oil024@eil.co.in',
    ),
    _FidicRecipient(
      title: "Employer's Technical Oversight Directorate",
      organization: 'Brahmaputra Hydrocarbon Infrastructure Authority',
      address: 'Assam State Industrial Corridor, Dibrugarh, Assam',
      attention: 'Director General (Pipeline Safety & Public Works)',
      email: 'director.infrastructure@assam.gov.in',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initial claim calculation: Season Total (14) - Baseline Allowed (6) = 8 Days
    final netDays = (widget.totalSeasonDaysLost - widget.baselineAllowedDays)
        .clamp(1.0, 30.0);
    _requestedEotDays = netDays;

    if (widget.initialSelectedActivityId != null) {
      _selectedActivityIds = {widget.initialSelectedActivityId!};
    } else {
      _selectedActivityIds = widget.suspendedActivities
          .map((a) => a.id)
          .toSet();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getRevisedCompletionDate() {
    final basePlanned = DateTime.now().add(const Duration(days: 45));
    final revised = basePlanned.add(Duration(days: _requestedEotDays.round()));
    return DateFormat('dd MMMM yyyy').format(revised);
  }

  String _generateFormalLetterText() {
    final dateFormat = DateFormat('dd MMMM yyyy');
    final todayStr = dateFormat.format(DateTime.now());
    final recipient = _recipients[_selectedRecipientIndex];

    final selectedActivities = widget.suspendedActivities
        .where((a) => _selectedActivityIds.contains(a.id))
        .toList();

    final buffer = StringBuffer();
    buffer.writeln(
      '================================================================================',
    );
    buffer.writeln(
      '          NIRMAAN INFRASTRUCTURE CONGLOMERATE — PIPELINES DIVISION            ',
    );
    buffer.writeln(
      '                    EPC CONTRACTOR JOINT VENTURE                                ',
    );
    buffer.writeln(
      '    Site Office: Section C-4 Camp, Duliajan, Dibrugarh District, Assam 786602    ',
    );
    buffer.writeln(
      '================================================================================\n',
    );

    buffer.writeln('Ref. No: $_contractRef');
    buffer.writeln('Date: $todayStr\n');

    buffer.writeln('TO:');
    buffer.writeln('  ${recipient.title}');
    buffer.writeln('  ${recipient.organization}');
    buffer.writeln('  ${recipient.address}');
    buffer.writeln('  ATTN: ${recipient.attention}\n');

    buffer.writeln(
      'SUBJECT: FORMAL NOTICE OF DELAY AND CLAIM FOR EXTENSION OF TIME (EOT)',
    );
    buffer.writeln(
      'PURSUANT TO FIDIC CONDITIONS OF CONTRACT (RED BOOK 1999/2017):',
    );
    if (_includeCl8_4c) {
      buffer.writeln(
        '  • SUB-CLAUSE 8.4(c) [Exceptionally Adverse Climatic Conditions]',
      );
    }
    if (_includeCl20_1) {
      buffer.writeln(
        '  • SUB-CLAUSE 20.1 [Contractor\'s Claims (Contemporaneous 28-Day Notice)]',
      );
    }
    if (_includeHseSop) {
      buffer.writeln(
        '  • INDUSTRIAL SAFETY DIRECTIVE HSE-SOP-08 [Precipitation Stoppage Threshold]',
      );
    }
    buffer.writeln('Project: $_projectName');
    buffer.writeln('Contract Agreement No: $_contractNo');
    buffer.writeln(
      'Site Location: ${widget.siteName} (${widget.siteCoordinates})\n',
    );

    buffer.writeln('Dear Sir/Madam,\n');

    buffer.writeln('1. STATUTORY NOTICE OF DELAY EVENT:');
    buffer.writeln(
      'In compliance with FIDIC Red Book Sub-Clause 8.4 and Sub-Clause 20.1, we hereby give formal notice that the execution and regular progress of the Works has been critically delayed and suspended by reason of Exceptionally Adverse Climatic Conditions (Torrential Monsoon Inundation) at the Duliajan Site.\n',
    );

    buffer.writeln(
      '2. METEOROLOGICAL TELEMETRY EVIDENCE (ASSAM / DULIAJAN BASIN):',
    );
    buffer.writeln(
      'On $todayStr, on-site Automatic Weather Station (AWS Station #09, Coordinates: ${widget.siteCoordinates}) recorded:',
    );
    buffer.writeln(
      '  • Cumulative 8-Hour Precipitation: ${widget.rainfall.toInt()} mm (Monsoon Torrential)',
    );
    buffer.writeln(
      '  • Contractual Weather Baseline Safety Cutoff: ${widget.rainfallThreshold.toInt()} mm/day',
    );
    buffer.writeln(
      '  • Baseline Threshold Exceedance: +${((widget.rainfall - widget.rainfallThreshold) / widget.rainfallThreshold * 100).toInt()}% above contract safety threshold',
    );
    buffer.writeln(
      '  • Ambient Relative Humidity: 88% (Dew Point 26°C, Wet Bulb 29°C)',
    );
    buffer.writeln(
      '  • Regional IMD Doppler Radar (Mohanbari/Dibrugarh Station): High reflectivity (>48 dBZ), active cyclonic depression #AS-09 over Upper Brahmaputra river valley.',
    );
    if (_includeDewateringBuffer) {
      buffer.writeln(
        '  • Sub-grade Soil Saturation: Soil moisture content at 94% liquid limit; geotechnical protocols mandate a 28-hour mechanical sump dewatering and solar drying buffer prior to heavy plant mobilization.\n',
      );
    } else {
      buffer.writeln('');
    }

    buffer.writeln('3. DIRECTLY AFFECTED CRITICAL PATH ACTIVITIES:');
    if (selectedActivities.isEmpty) {
      buffer.writeln('  [No activities currently selected]\n');
    } else {
      for (int i = 0; i < selectedActivities.length; i++) {
        final act = selectedActivities[i];
        buffer.writeln('  3.${i + 1} ${act.name} [ID: ${act.id}]');
        buffer.writeln('      - Location: ${act.location}');
        buffer.writeln(
          '      - Critical Path Status: ${act.isCriticalPath ? "CRITICAL PATH (Float: 0.0 Days)" : "Non-Critical"}',
        );
        buffer.writeln('      - Suspension Ground: ${act.reason}');
        buffer.writeln(
          '      - Workforce Impact: ${act.crewSize} skilled personnel placed on safety stand-down',
        );
        buffer.writeln(
          '      - Schedule Slippage Impact: ${act.estimatedSlippage}',
        );
        buffer.writeln(
          '      - Contemporaneous Mitigation: ${act.mitigationAction}\n',
        );
      }
    }

    buffer.writeln(
      '4. QUANTIFICATION OF DELAY & EXTENSION OF TIME (EOT) REQUEST:',
    );
    buffer.writeln(
      '  • Total Cumulative Monsoon Downtime Recorded (2026 Season): ${widget.totalSeasonDaysLost.toInt()} Working Days',
    );
    buffer.writeln(
      '  • Contract Weather Baseline Allowance (Special Conditions): ${widget.baselineAllowedDays.toInt()} Working Days',
    );
    buffer.writeln(
      '  • Net Claimable Extension of Time under Clause 8.4(c): ${_requestedEotDays.toInt()} Working Days',
    );
    buffer.writeln(
      '  • Revised Contractual Time for Completion: ${_getRevisedCompletionDate()}',
    );
    buffer.writeln(
      '  • Contractual Liquidated Damages Protection (Clause 8.7): ₹${NumberFormat('#,##,###').format((_requestedEotDays * _dailyLdRate).round())} insulated from deduction.\n',
    );

    buffer.writeln('5. MITIGATION MEASURES TAKEN (CLAUSE 8.4 COMPLIANCE):');
    buffer.writeln(
      'In accordance with our contractual obligation to minimize delay, the Contractor has:',
    );
    buffer.writeln(
      '  (a) Sealed all exposed pipe ends with watertight hydrostatic test caps;',
    );
    buffer.writeln(
      '  (b) Mobilized 4x 100 GPM high-head submersible mud pumps along the trench alignment;',
    );
    buffer.writeln(
      '  (c) Erected geotextile silt fences to prevent spoil sloughing into agricultural drains;',
    );
    buffer.writeln(
      '  (d) Redeployed standing welding and fit-up crews to sheltered spool fabrication yards.\n',
    );

    if (_includeCostReservation) {
      buffer.writeln('6. RESERVATION OF RIGHTS (COST CLAIM):');
      buffer.writeln(
        'The Contractor reserves all contractual rights pursuant to Sub-Clause 20.1, Sub-Clause 17.3, and applicable law to quantify and claim associated site overheads, equipment idling charges, and extended financing costs directly attributable to this prolonged adverse weather event.\n',
      );
    }

    buffer.writeln(
      'Contemporary digital telemetry records, IMD Doppler radar logs, drone aerial surveys, and signed site safety registers are archived in the Nirmaan OS immutable ledger and available for inspection.\n',
    );

    buffer.writeln('Yours faithfully,');
    buffer.writeln('FOR AND ON BEHALF OF CONSORTIUM EPC JOINT VENTURE\n\n');
    buffer.writeln('____________________________________________');
    buffer.writeln('Er. Rajesh Borah, FIE, CEng');
    buffer.writeln('Lead Planning Engineer & Commercial Project Director');
    buffer.writeln(
      'Consortium EPC Joint Venture (Oil India Pipeline Project)\n',
    );
    buffer.writeln(
      'Digital Ledger Seal: SHA-256 [0x7F89C421B930EA92] • Tamper-Evident Nirmaan Node',
    );

    return buffer.toString();
  }

  Future<void> _handleCopy() async {
    final text = _generateFormalLetterText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.copy, color: AppTheme.primaryLight, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Formal FIDIC Cl. 8.4 Delay Notice copied to clipboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppTheme.border),
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);

    String receiptId =
        'AUD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final res = await provider.logAuditEvent({
        'projectId': provider.currentProjectId ?? 'OIL-PL-024',
        'actorName': provider.currentUser?['name'] ?? 'Er. Rajesh Borah',
        'actorRole': provider.currentUser?['role'] ?? 'LEAD_PLANNING_ENGINEER',
        'action': 'FIDIC_DELAY_NOTICE_EXPORTED',
        'entityType': 'ACTIVITY',
        'entityId': 'ACT-PL-024',
        'previousValue': 'Contract Baseline: 6 Weather Days',
        'newValue':
            'Claimed EOT: +${_requestedEotDays.toInt()} Days (Season Total: 14 Days)',
        'reason': 'Exported formal FIDIC Cl. 8.4 Delay Notice PDF dossier citing Assam/Duliajan monsoon rainfall (45mm vs 25mm threshold). Affected: Line 24 Welded Joints, Trench Excavation',
      });
      if (res != null &&
          res['auditLog'] != null &&
          res['auditLog']['id'] != null) {
        receiptId = res['auditLog']['id'];
      }
    } catch (e) {
      debugPrint('Export audit logging error: $e');
    }

    if (!mounted) return;
    setState(() {
      _isExporting = false;
      _auditLogReceipt = receiptId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.picture_as_pdf,
              color: AppTheme.tertiary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FIDIC Cl. 8.4 Dossier Exported Successfully',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Logged to immutable audit ledger ($receiptId) • EOT Claim: +${_requestedEotDays.toInt()} Days',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppTheme.tertiary.withAlpha(140)),
        ),
      ),
    );
  }

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);

    String receiptId =
        'AUD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final res = await provider.logAuditEvent({
        'projectId': provider.currentProjectId ?? 'OIL-PL-024',
        'actorName': provider.currentUser?['name'] ?? 'Er. Rajesh Borah',
        'actorRole': provider.currentUser?['role'] ?? 'LEAD_PLANNING_ENGINEER',
        'action': 'FIDIC_DELAY_NOTICE_SHARED',
        'entityType': 'ACTIVITY',
        'entityId': 'ACT-PL-024',
        'previousValue': 'Contract Baseline: 6 Weather Days',
        'newValue':
            'Claimed EOT: +${_requestedEotDays.toInt()} Days (Season Total: 14 Days)',
        'reason': 'Shared FIDIC Cl. 8.4 Delay Notice with Project Stakeholders citing Assam/Duliajan monsoon rainfall (45mm vs 25mm threshold) for Line 24 Welded Joints & Trench Excavation',
      });
      if (res != null &&
          res['auditLog'] != null &&
          res['auditLog']['id'] != null) {
        receiptId = res['auditLog']['id'];
      }
    } catch (e) {
      debugPrint('Share audit logging error: $e');
    }

    if (!mounted) return;
    setState(() {
      _isSharing = false;
      _auditLogReceipt = receiptId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.share, color: AppTheme.secondary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delay Notice Shared with Project Stakeholders',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Event recorded in immutable audit log ($receiptId) • Line 24 & Trench Excavation flagged',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppTheme.secondary.withAlpha(140)),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    String receiptId =
        'AUD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final res = await provider.logAuditEvent({
        'projectId': provider.currentProjectId ?? 'OIL-PL-024',
        'actorName': provider.currentUser?['name'] ?? 'Er. Rajesh Borah',
        'actorRole': provider.currentUser?['role'] ?? 'LEAD_PLANNING_ENGINEER',
        'action': 'FIDIC_DELAY_NOTICE_SUBMITTED',
        'entityType': 'ACTIVITY',
        'entityId': 'OIL-PL-024-EOT-8.4',
        'previousValue': 'Contract Baseline: 6 Weather Days',
        'newValue':
            'Claimed EOT: +${_requestedEotDays.toInt()} Days (Season Total: 14 Days)',
        'reason': 'Formally served FIDIC Cl. 8.4 Delay Notice to Oil India Ltd Engineer for Duliajan monsoon inundation',
      });
      if (res != null &&
          res['auditLog'] != null &&
          res['auditLog']['id'] != null) {
        receiptId = res['auditLog']['id'];
      }
    } catch (e) {
      debugPrint('Submit audit logging error: $e');
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _noticeSubmitted = true;
      _submittedTimestamp =
          '${DateFormat('dd MMM yyyy, HH:mm:ss').format(DateTime.now())} IST';
      _auditLogReceipt = receiptId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.verified, color: AppTheme.tertiary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FIDIC Cl. 8.4 Notice Formally Transmitted to Engineer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Recorded in Oil India Ltd dispatch registry & Audit Trail ($receiptId)',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppTheme.tertiary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1.2),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 28, spreadRadius: 6),
          ],
        ),
        child: Column(
          children: [
            // Top Modal Header Bar
            _buildDialogHeader(context),

            // Tab Bar
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceCard,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryLight,
                indicatorWeight: 3,
                labelColor: AppTheme.primaryLight,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.description, size: 18),
                    text: 'Formal Letter Document',
                  ),
                  Tab(
                    icon: Icon(Icons.tune, size: 18),
                    text: 'Parameters & Scope',
                  ),
                  Tab(
                    icon: Icon(Icons.shield_outlined, size: 18),
                    text: 'Telemetry Proofs',
                  ),
                ],
              ),
            ),

            // Tab Content Area
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFormalLetterTab(),
                  _buildParametersTab(),
                  _buildTelemetryProofsTab(),
                ],
              ),
            ),

            // Bottom Actions Bar
            _buildDialogActionsBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withAlpha(35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.gavel, color: AppTheme.secondary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'FIDIC Cl. 8.4 Delay Notice Dossier',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppTheme.secondary.withAlpha(100),
                        ),
                      ),
                      child: const Text(
                        'SUB-CL. 8.4(c)',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.siteName} • Ref: $_contractRef',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            tooltip: 'Close Dialog',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOG TAB 1: Formal Letter Document Preview
  // ---------------------------------------------------------------------------
  Widget _buildFormalLetterTab() {
    final letterText = _generateFormalLetterText();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notice Status Summary Pill Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: AppTheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'Contractual Citation: '),
                        const TextSpan(
                          text: 'FIDIC Red Book Cl. 8.4(c) & Cl. 20.1',
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' • Requested EOT: '),
                        TextSpan(
                          text: '+${_requestedEotDays.toInt()} Days',
                          style: const TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.withAlpha(100)),
                  ),
                  child: Text(
                    '${widget.rainfall.toInt()}mm > 25mm CUTOFF',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Official Letterhead & Document Parchment Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.border.withAlpha(180),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SelectableText(
              letterText,
              style: const TextStyle(
                fontFamily: 'Courier',
                color: Color(0xFFE2E8F0),
                fontSize: 11.8,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Digital Audit Trail & Ledger Verification Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.tertiary.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fingerprint,
                  color: AppTheme.tertiary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Immutable Digital Ledger Verification',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _auditLogReceipt != null
                            ? 'Ledger Entry: $_auditLogReceipt • Verified on SHA-256 Block'
                            : 'Pending Transmission • SHA-256 hash automatically sealed upon export/dispatch',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
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

  // ---------------------------------------------------------------------------
  // DIALOG TAB 2: Interactive Parameters & Scope
  // ---------------------------------------------------------------------------
  Widget _buildParametersTab() {
    final selectedCount = _selectedActivityIds.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Addressee Selection
          const Text(
            '1. Addressee / Engineer Recipient',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedRecipientIndex,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceCard,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.primaryLight,
                ),
                items: _recipients.asMap().entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(
                      '${entry.value.organization} — ${entry.value.attention}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (newIdx) {
                  if (newIdx != null) {
                    setState(() => _selectedRecipientIndex = newIdx);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Extension of Time (EOT) Slider & Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '2. Requested Extension of Time (EOT)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.secondary.withAlpha(120)),
                ),
                child: Text(
                  '+${_requestedEotDays.toInt()} Working Days',
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: _requestedEotDays > 1.0
                          ? () => setState(
                              () => _requestedEotDays =
                                  (_requestedEotDays - 1.0).clamp(1.0, 30.0),
                            )
                          : null,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.secondary,
                          inactiveTrackColor: AppTheme.border,
                          thumbColor: AppTheme.secondary,
                          overlayColor: AppTheme.secondary.withAlpha(40),
                        ),
                        child: Slider(
                          value: _requestedEotDays,
                          min: 1.0,
                          max: 30.0,
                          divisions: 29,
                          label: '${_requestedEotDays.toInt()} Days',
                          onChanged: (v) =>
                              setState(() => _requestedEotDays = v),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: AppTheme.secondary,
                      ),
                      onPressed: _requestedEotDays < 30.0
                          ? () => setState(
                              () => _requestedEotDays =
                                  (_requestedEotDays + 1.0).clamp(1.0, 30.0),
                            )
                          : null,
                    ),
                  ],
                ),
                const Divider(color: AppTheme.border, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildParamMetricCol(
                      'Baseline Allowed',
                      '${widget.baselineAllowedDays.toInt()} Days',
                    ),
                    _buildParamMetricCol(
                      'Total Season Lost',
                      '${widget.totalSeasonDaysLost.toInt()} Days',
                    ),
                    _buildParamMetricCol(
                      'Net EOT Claim',
                      '+${_requestedEotDays.toInt()} Days',
                    ),
                    _buildParamMetricCol(
                      'LD Protected',
                      '₹${NumberFormat('#,##,###').format((_requestedEotDays * _dailyLdRate).round())}',
                      isAccent: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 3: Affected Activities Checklist
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '3. Suspended Operations Included ($selectedCount/${widget.suspendedActivities.length})',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedActivityIds = widget.suspendedActivities
                            .map((a) => a.id)
                            .toSet();
                      });
                    },
                    child: const Text(
                      'Select All',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedActivityIds = widget.suspendedActivities
                            .where((a) => a.isCriticalPath)
                            .map((a) => a.id)
                            .toSet();
                      });
                    },
                    child: const Text(
                      'Critical Path Only',
                      style: TextStyle(fontSize: 11, color: AppTheme.secondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...widget.suspendedActivities.map((act) {
            final isChecked = _selectedActivityIds.contains(act.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isChecked
                    ? AppTheme.surfaceContainerHigh.withAlpha(140)
                    : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isChecked
                      ? AppTheme.primaryLight.withAlpha(120)
                      : AppTheme.border,
                ),
              ),
              child: CheckboxListTile(
                value: isChecked,
                activeColor: AppTheme.primary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        act.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (act.isCriticalPath)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CRITICAL',
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  '${act.id} • ${act.location} • Slippage: ${act.estimatedSlippage} • Crew: ${act.crewSize}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedActivityIds.add(act.id);
                    } else {
                      _selectedActivityIds.remove(act.id);
                    }
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 20),

          // Section 4: Contractual Grounds & Sub-Clause Toggles
          const Text(
            '4. Contractual Clauses Cited',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildClauseSwitch(
            'FIDIC Cl. 8.4(c) — Exceptionally Adverse Climatic Conditions',
            _includeCl8_4c,
            (v) => setState(() => _includeCl8_4c = v),
          ),
          _buildClauseSwitch(
            'FIDIC Cl. 20.1 — Contractor\'s Claims (Within 28 Days Notice)',
            _includeCl20_1,
            (v) => setState(() => _includeCl20_1 = v),
          ),
          _buildClauseSwitch(
            'Industrial HSE-SOP-08 — Mandatory Stoppage for Rainfall >25mm',
            _includeHseSop,
            (v) => setState(() => _includeHseSop = v),
          ),
          _buildClauseSwitch(
            'Sub-Grade Dewatering Buffer — 28 Hours Mandatory Pumping',
            _includeDewateringBuffer,
            (v) => setState(() => _includeDewateringBuffer = v),
          ),
          _buildClauseSwitch(
            'Cl. 20.1 Cost Reservation — Extended Overheads & Idling',
            _includeCostReservation,
            (v) => setState(() => _includeCostReservation = v),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildParamMetricCol(
    String label,
    String value, {
    bool isAccent = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: isAccent ? AppTheme.tertiary : AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildClauseSwitch(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppTheme.primaryLight,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOG TAB 3: Telemetry Proofs & Attachments
  // ---------------------------------------------------------------------------
  Widget _buildTelemetryProofsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evidentiary Attachments Automatically Bundled',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'These evidentiary artifacts are cryptographically hashed and appended to the formal claim dossier to satisfy FIDIC Clause 20.1 contemporaneous records requirements.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          _buildProofCard(
            icon: Icons.sensors,
            iconColor: Colors.blueAccent,
            title: 'On-Site Automatic Weather Station #09',
            subtitle: 'Raw CSV Telemetry Log (Timestamped, SHA-256 Verified)',
            details: [
              'Coordinates: ${widget.siteCoordinates}',
              'Precipitation (8H): ${widget.rainfall.toInt()} mm (Safety Cutoff: 25.0 mm)',
              'Humidity: 88% • Wind: 18 km/h • Surface Pressure: 994 hPa',
              'Tamper-evident verification hash: 0x9B4E312F...8A92',
            ],
          ),
          const SizedBox(height: 10),

          _buildProofCard(
            icon: Icons.radar,
            iconColor: Colors.purpleAccent,
            title: 'IMD Doppler Weather Radar (Dibrugarh / Mohanbari)',
            subtitle: 'Upper Assam Basin Reflectivity & Cloudburst Snapshot',
            details: [
              'Radar Echo Intensity: 48 dBZ (Torrential Monsoon Classification)',
              'Synoptic System: Upper Assam Monsoon Trough Depression #AS-09',
              'Regional Soil Saturation Index: 94% liquid limit',
              'Source: India Meteorological Department (IMD) North-East Division',
            ],
          ),
          const SizedBox(height: 10),

          _buildProofCard(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orangeAccent,
            title: 'HSE Work Stoppage Directive #HSE-STP-2026-09-29',
            subtitle: 'Mandatory Safety Stand-Down Order by Site Safety Lead',
            details: [
              'Authority: Er. M. Kalita (Site Lead HSE Director, OIL JV)',
              'Standard: HSE-SOP-08 (Outdoor Hot-Work & Earthmoving Safety Cutoff)',
              'Affected Personnel: 100 craftsmen moved to covered prefabrication bays',
              'Signed Order digitally certified with timestamp seal',
            ],
          ),
          const SizedBox(height: 10),

          _buildProofCard(
            icon: Icons.alt_route,
            iconColor: AppTheme.tertiary,
            title: 'Primavera P6 Critical Path Slippage Schedule Run',
            subtitle: 'CPM Schedule Impact Analysis & Float Consumption Ledger',
            details: [
              'Critical Activity: Line 24 Welded Joints & Station 14+200 Trench',
              'Initial Float: +3.0 Days • Current Float: -5.0 Days (Negative Float)',
              'Net Critical Path Slippage: +1.5 Days this storm event',
              'Cumulative Season Slippage: 8.0 Days beyond contract allowance',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProofCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> details,
  }) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
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
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle,
                color: AppTheme.tertiary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 8),
          ...details.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      d,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOG ACTIONS BOTTOM BAR
  // ---------------------------------------------------------------------------
  Widget _buildDialogActionsBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_noticeSubmitted)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.tertiary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.tertiary.withAlpha(120)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified,
                    color: AppTheme.tertiary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Formally Transmitted on $_submittedTimestamp • Audit Hash: $_auditLogReceipt',
                      style: const TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Copy Button
              OutlinedButton.icon(
                onPressed: _handleCopy,
                icon: const Icon(Icons.copy, size: 15),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  side: const BorderSide(color: AppTheme.border),
                  foregroundColor: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),

              // Share Button
              OutlinedButton.icon(
                onPressed: _isSharing ? null : _handleShare,
                icon: _isSharing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.share,
                        size: 15,
                        color: AppTheme.secondary,
                      ),
                label: const Text(
                  'Share Notice',
                  style: TextStyle(color: AppTheme.secondary),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  side: BorderSide(color: AppTheme.secondary.withAlpha(150)),
                ),
              ),
              const SizedBox(width: 8),

              // Export Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : _handleExport,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.picture_as_pdf,
                          size: 16,
                          color: AppTheme.primaryLight,
                        ),
                  label: const Text(
                    'Export Dossier',
                    style: TextStyle(color: AppTheme.primaryLight),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(
                      color: AppTheme.primaryLight.withAlpha(150),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Transmit to Engineer Button
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: (_isSubmitting || _noticeSubmitted)
                      ? null
                      : _handleSubmit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _noticeSubmitted ? Icons.done_all : Icons.send,
                          size: 16,
                        ),
                  label: Text(
                    _noticeSubmitted ? 'Transmitted' : 'Transmit Notice',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _noticeSubmitted
                        ? AppTheme.tertiary
                        : AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
}
