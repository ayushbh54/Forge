import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Threat Level Classification Matrix
enum GeohazardThreatLevel {
  normal(
    label: 'NORMAL',
    sublabel: 'Condition Green • Routine Baseline',
    color: AppTheme.tertiary,
    bgTint: Color(0x1A4EDEA3),
    borderTint: Color(0x664EDEA3),
    icon: Icons.check_circle_outline_rounded,
    sopAction: 'Weekly LiDAR survey & bi-weekly inclinometer log dump.',
  ),
  watch(
    label: 'WATCH',
    sublabel: 'Stage I • Advisory Alert',
    color: AppTheme.secondary,
    bgTint: Color(0x1AFFB95F),
    borderTint: Color(0x66FFB95F),
    icon: Icons.visibility_outlined,
    sopAction: '15-min automated telemetry ping, acoustic sonar standby.',
  ),
  warning(
    label: 'WARNING',
    sublabel: 'Stage II • Heightened Threat',
    color: Color(0xFFFB923C),
    bgTint: Color(0x1AFB923C),
    borderTint: Color(0x66FB923C),
    icon: Icons.warning_amber_rounded,
    sopAction: 'Immediate on-site geotechnical inspection; mobilize riprap barge.',
  ),
  emergency(
    label: 'EMERGENCY',
    sublabel: 'Stage III • Critical Hazard Action',
    color: Color(0xFFF43F5E),
    bgTint: Color(0x1AF43F5E),
    borderTint: Color(0x66F43F5E),
    icon: Icons.crisis_alert_rounded,
    sopAction: 'Trigger ESDV isolation interlock, line pressure drawdown, RoW cordon.',
  );

  final String label;
  final String sublabel;
  final Color color;
  final Color bgTint;
  final Color borderTint;
  final IconData icon;
  final String sopAction;

  const GeohazardThreatLevel({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.bgTint,
    required this.borderTint,
    required this.icon,
    required this.sopAction,
  });
}

/// In-place Inclinometer Sensor Model (IN-01 to IN-12)
class InclinometerSensor {
  final String id;
  final String chainage;
  final String locationDescription;
  final double depthM;
  final double displacementRateMmDay; // mm/day
  final double cumulativeDispMm; // mm
  final double slipPlaneDepthM; // shear slip plane depth (negative meters)
  final double batteryPct;
  final int loraSnrDb;
  final DateTime lastPing;
  final List<double> displacementProfile; // Displacements at 2m depth intervals

  const InclinometerSensor({
    required this.id,
    required this.chainage,
    required this.locationDescription,
    required this.depthM,
    required this.displacementRateMmDay,
    required this.cumulativeDispMm,
    required this.slipPlaneDepthM,
    required this.batteryPct,
    required this.loraSnrDb,
    required this.lastPing,
    required this.displacementProfile,
  });

  GeohazardThreatLevel get threatLevel {
    if (displacementRateMmDay >= 5.0) return GeohazardThreatLevel.emergency;
    if (displacementRateMmDay >= 2.0) return GeohazardThreatLevel.warning;
    if (displacementRateMmDay >= 0.5) return GeohazardThreatLevel.watch;
    return GeohazardThreatLevel.normal;
  }
}

/// Riverbed Bathymetric Echo Sounder Survey Station
class BathymetricStation {
  final double chainageM; // 0m to 450m transect across river
  final double bedElevationRlm; // Riverbed Reduced Level (m MSL)
  final double pipeTopElevationRlm; // Pipeline Top of Pipe RL (m MSL)
  final double baselineBedRlm; // Baseline post-HDD construction bed RL
  final String zoneType; // e.g., 'North Bank', 'Thalweg Scour Hole', 'Bar'

  const BathymetricStation({
    required this.chainageM,
    required this.bedElevationRlm,
    required this.pipeTopElevationRlm,
    required this.baselineBedRlm,
    required this.zoneType,
  });

  double get depthOfCoverM => bedElevationRlm - pipeTopElevationRlm;
  double get scourDeepeningM => baselineBedRlm - bedElevationRlm;

  GeohazardThreatLevel get threatLevel {
    if (depthOfCoverM < 1.5) return GeohazardThreatLevel.emergency;
    if (depthOfCoverM < 2.0) return GeohazardThreatLevel.warning;
    if (depthOfCoverM < 2.5) return GeohazardThreatLevel.watch;
    return GeohazardThreatLevel.normal;
  }
}

/// Triaxial Strong-Motion Accelerometer Station
class SeismicStation {
  final String id;
  final String stationName;
  final String geologicalSetting;
  final double pgaG; // Peak Ground Acceleration in g
  final double accelX; // East-West (g)
  final double accelY; // North-South (g)
  final double accelZ; // Vertical (g)
  final double ariasIntensityMs;
  final double liquefactionRu; // Pore pressure ratio ru (threshold 0.85)

  const SeismicStation({
    required this.id,
    required this.stationName,
    required this.geologicalSetting,
    required this.pgaG,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.ariasIntensityMs,
    required this.liquefactionRu,
  });

  GeohazardThreatLevel get threatLevel {
    if (pgaG >= 0.25 || liquefactionRu >= 0.85) return GeohazardThreatLevel.emergency;
    if (pgaG >= 0.12 || liquefactionRu >= 0.65) return GeohazardThreatLevel.warning;
    if (pgaG >= 0.05 || liquefactionRu >= 0.45) return GeohazardThreatLevel.watch;
    return GeohazardThreatLevel.normal;
  }
}

/// Pipeline FBG Strain Gauge Rosette Station
class StrainGaugeStation {
  final String id;
  final String chainage;
  final String locationSegment;
  final double axialMicrostrain; // με
  final double bendingMicrostrain; // με
  final double hoopMicrostrain; // με (operating pressure 92.5 bar)
  final double temperatureC;

  const StrainGaugeStation({
    required this.id,
    required this.chainage,
    required this.locationSegment,
    required this.axialMicrostrain,
    required this.bendingMicrostrain,
    required this.hoopMicrostrain,
    required this.temperatureC,
  });

  // API 5L X70 Steel Yield strain = 2343 με (SMYS = 485 MPa, E = 207 GPa)
  // Max Allowable = 85% SMYS = 1991.5 με
  static const double yieldStrain = 2343.0;
  static const double smys85Limit = 1991.5;

  double get equivalentVonMisesStrain {
    // Equivalent strain combining axial, bending, and hoop
    final totalAxial = axialMicrostrain + bendingMicrostrain;
    return math.sqrt(
      math.pow(totalAxial, 2) - (totalAxial * hoopMicrostrain) + math.pow(hoopMicrostrain, 2),
    );
  }

  double get pctSmys => (equivalentVonMisesStrain / yieldStrain) * 100.0;

  GeohazardThreatLevel get threatLevel {
    if (pctSmys >= 85.0) return GeohazardThreatLevel.emergency;
    if (pctSmys >= 72.0) return GeohazardThreatLevel.warning;
    if (pctSmys >= 55.0) return GeohazardThreatLevel.watch;
    return GeohazardThreatLevel.normal;
  }
}

/// Geohazard Automated Notification Log Entry
class GeohazardNotification {
  final String id;
  final DateTime timestamp;
  final String triggerSource;
  final String message;
  final GeohazardThreatLevel level;
  final List<String> recipients;
  final bool acknowledged;

  const GeohazardNotification({
    required this.id,
    required this.timestamp,
    required this.triggerSource,
    required this.message,
    required this.level,
    required this.recipients,
    required this.acknowledged,
  });
}

/// Main Screen
class GeohazardMonitoringScreen extends StatefulWidget {
  const GeohazardMonitoringScreen({super.key});

  @override
  State<GeohazardMonitoringScreen> createState() => _GeohazardMonitoringScreenState();
}

class _GeohazardMonitoringScreenState extends State<GeohazardMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Selected Inclinometer for Profile Inspector
  int _selectedInclinometerIndex = 4; // IN-05 default (Active warning sensor)

  // Scour Cross-Section Interactive Scrubber (m)
  double _scrubberChainageM = 275.0; // Point of minimum DOC

  // Seismic Simulation Mode
  bool _isSeismicSimulationActive = false;
  double _simulatedPgaG = 0.048;

  // Inclinometer Rate Filter
  String _inclinometerFilter = 'ALL';

  // Live Telemetry Data Collections
  late List<InclinometerSensor> _inclinometers;
  late List<BathymetricStation> _bathymetricData;
  late List<SeismicStation> _seismicStations;
  late List<StrainGaugeStation> _strainStations;
  late List<GeohazardNotification> _notificationLogs;

  // Basin Hydrological Telemetry State
  final double _riverWaterLevelMsl = 102.40; // m MSL
  final double _dangerLevelMsl = 102.11; // Danger Level
  final double _hflMsl = 104.25; // 1998 Highest Flood Level
  final double _riverDischargeCumecs = 7840.0; // m3/s
  final double _flowVelocityMs = 3.65; // m/s
  final double _bankSetbackDistanceM = 18.4; // m to bluff edge
  final double _staticFos = 1.34; // Static Factor of Safety
  final double _seismicFos = 1.08; // Pseudo-static Seismic FoS

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    _initializeTelemetryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeTelemetryData() {
    final now = DateTime.now();

    // 12 In-place Inclinometers (IN-01 to IN-12)
    _inclinometers = [
      InclinometerSensor(
        id: 'IN-01',
        chainage: 'Ch. 42+180',
        locationDescription: 'North River Bluff Crest & Entry Anchor Block',
        depthM: 35.0,
        displacementRateMmDay: 0.28,
        cumulativeDispMm: 4.8,
        slipPlaneDepthM: -18.5,
        batteryPct: 94.0,
        loraSnrDb: -78,
        lastPing: now.subtract(const Duration(minutes: 3)),
        displacementProfile: const [0.2, 0.4, 0.8, 1.2, 2.1, 3.4, 4.8, 4.8, 4.8, 4.8],
      ),
      InclinometerSensor(
        id: 'IN-02',
        chainage: 'Ch. 42+320',
        locationDescription: 'Floodplain Scour Berm & Gabion Apron',
        depthM: 30.0,
        displacementRateMmDay: 0.42,
        cumulativeDispMm: 6.2,
        slipPlaneDepthM: -12.0,
        batteryPct: 88.0,
        loraSnrDb: -82,
        lastPing: now.subtract(const Duration(minutes: 5)),
        displacementProfile: const [0.3, 0.7, 1.5, 3.2, 5.0, 6.2, 6.2, 6.2, 6.2],
      ),
      InclinometerSensor(
        id: 'IN-03',
        chainage: 'Ch. 42+480',
        locationDescription: 'Active Meander Cut-Bank & Toe Scour Slope',
        depthM: 40.0,
        displacementRateMmDay: 1.84,
        cumulativeDispMm: 26.5,
        slipPlaneDepthM: -14.2,
        batteryPct: 91.0,
        loraSnrDb: -75,
        lastPing: now.subtract(const Duration(minutes: 2)),
        displacementProfile: const [1.2, 3.5, 8.2, 16.4, 23.0, 26.5, 26.5, 26.5, 26.5, 26.5],
      ),
      InclinometerSensor(
        id: 'IN-04',
        chainage: 'Ch. 42+650',
        locationDescription: 'Mid-Channel Alluvial Island Spur',
        depthM: 25.0,
        displacementRateMmDay: 0.72,
        cumulativeDispMm: 11.4,
        slipPlaneDepthM: -9.5,
        batteryPct: 79.0,
        loraSnrDb: -89,
        lastPing: now.subtract(const Duration(minutes: 8)),
        displacementProfile: const [0.5, 1.8, 4.5, 8.9, 11.4, 11.4, 11.4],
      ),
      InclinometerSensor(
        id: 'IN-05',
        chainage: 'Ch. 42+820',
        locationDescription: 'Burhi Dihing South Toe Slip Escarpment',
        depthM: 40.0,
        displacementRateMmDay: 3.42,
        cumulativeDispMm: 48.9,
        slipPlaneDepthM: -15.8,
        batteryPct: 84.0,
        loraSnrDb: -74,
        lastPing: now.subtract(const Duration(minutes: 1)),
        displacementProfile: const [2.5, 6.8, 15.2, 31.0, 42.5, 48.9, 48.9, 48.9, 48.9, 48.9],
      ),
      InclinometerSensor(
        id: 'IN-06',
        chainage: 'Ch. 42+990',
        locationDescription: 'South Bank Approach Cut & Drainage Culvert',
        depthM: 35.0,
        displacementRateMmDay: 0.88,
        cumulativeDispMm: 14.1,
        slipPlaneDepthM: -16.0,
        batteryPct: 92.0,
        loraSnrDb: -80,
        lastPing: now.subtract(const Duration(minutes: 4)),
        displacementProfile: const [0.6, 2.1, 5.4, 9.8, 13.0, 14.1, 14.1, 14.1, 14.1],
      ),
      InclinometerSensor(
        id: 'IN-07',
        chainage: 'Ch. 43+150',
        locationDescription: 'High Bluff Rotational Slump Escarpment',
        depthM: 45.0,
        displacementRateMmDay: 1.15,
        cumulativeDispMm: 19.3,
        slipPlaneDepthM: -22.4,
        batteryPct: 86.0,
        loraSnrDb: -83,
        lastPing: now.subtract(const Duration(minutes: 6)),
        displacementProfile: const [0.8, 2.4, 5.9, 10.5, 15.8, 19.3, 19.3, 19.3, 19.3, 19.3],
      ),
      InclinometerSensor(
        id: 'IN-08',
        chainage: 'Ch. 43+300',
        locationDescription: 'Pipeline Right-of-Way Trench Berm Margin',
        depthM: 30.0,
        displacementRateMmDay: 0.35,
        cumulativeDispMm: 5.1,
        slipPlaneDepthM: -11.0,
        batteryPct: 95.0,
        loraSnrDb: -72,
        lastPing: now.subtract(const Duration(minutes: 7)),
        displacementProfile: const [0.2, 0.6, 1.4, 3.1, 4.8, 5.1, 5.1, 5.1],
      ),
      InclinometerSensor(
        id: 'IN-09',
        chainage: 'Ch. 43+450',
        locationDescription: 'Brahmaputra Confluence Flood Overflow Basin',
        depthM: 40.0,
        displacementRateMmDay: 0.22,
        cumulativeDispMm: 3.8,
        slipPlaneDepthM: -19.0,
        batteryPct: 90.0,
        loraSnrDb: -85,
        lastPing: now.subtract(const Duration(minutes: 10)),
        displacementProfile: const [0.1, 0.4, 1.0, 2.1, 3.2, 3.8, 3.8, 3.8, 3.8, 3.8],
      ),
      InclinometerSensor(
        id: 'IN-10',
        chainage: 'Ch. 43+600',
        locationDescription: 'South Tie-In Valve Station VS-04 Boundary',
        depthM: 25.0,
        displacementRateMmDay: 0.15,
        cumulativeDispMm: 2.1,
        slipPlaneDepthM: -8.0,
        batteryPct: 98.0,
        loraSnrDb: -69,
        lastPing: now.subtract(const Duration(minutes: 2)),
        displacementProfile: const [0.1, 0.3, 0.8, 1.6, 2.1, 2.1, 2.1],
      ),
      InclinometerSensor(
        id: 'IN-11',
        chainage: 'Ch. 43+750',
        locationDescription: 'N.F. Railway Embankment Abutment Interface',
        depthM: 35.0,
        displacementRateMmDay: 0.31,
        cumulativeDispMm: 4.5,
        slipPlaneDepthM: -14.0,
        batteryPct: 89.0,
        loraSnrDb: -81,
        lastPing: now.subtract(const Duration(minutes: 9)),
        displacementProfile: const [0.2, 0.5, 1.2, 2.5, 3.9, 4.5, 4.5, 4.5, 4.5],
      ),
      InclinometerSensor(
        id: 'IN-12',
        chainage: 'Ch. 43+900',
        locationDescription: 'Overburden Trench Spoil Dumping Terrace',
        depthM: 30.0,
        displacementRateMmDay: 0.65,
        cumulativeDispMm: 9.8,
        slipPlaneDepthM: -10.5,
        batteryPct: 82.0,
        loraSnrDb: -86,
        lastPing: now.subtract(const Duration(minutes: 11)),
        displacementProfile: const [0.4, 1.2, 2.9, 6.1, 8.7, 9.8, 9.8, 9.8],
      ),
    ];

    // Bathymetric Riverbed Survey Data across 450m transect
    _bathymetricData = const [
      BathymetricStation(
        chainageM: 0.0,
        bedElevationRlm: 101.50,
        pipeTopElevationRlm: 92.00,
        baselineBedRlm: 101.60,
        zoneType: 'North Bank Crest',
      ),
      BathymetricStation(
        chainageM: 50.0,
        bedElevationRlm: 100.10,
        pipeTopElevationRlm: 91.80,
        baselineBedRlm: 100.40,
        zoneType: 'North Upper Shelf',
      ),
      BathymetricStation(
        chainageM: 100.0,
        bedElevationRlm: 97.40,
        pipeTopElevationRlm: 91.20,
        baselineBedRlm: 98.10,
        zoneType: 'Riprap Revetment Toe',
      ),
      BathymetricStation(
        chainageM: 150.0,
        bedElevationRlm: 94.60,
        pipeTopElevationRlm: 90.30,
        baselineBedRlm: 96.00,
        zoneType: 'Channel Sub-Berm',
      ),
      BathymetricStation(
        chainageM: 200.0,
        bedElevationRlm: 91.20,
        pipeTopElevationRlm: 88.00,
        baselineBedRlm: 93.50,
        zoneType: 'Main Thalweg Slope',
      ),
      BathymetricStation(
        chainageM: 240.0,
        bedElevationRlm: 88.30,
        pipeTopElevationRlm: 85.50,
        baselineBedRlm: 91.20,
        zoneType: 'Thalweg Deep Channel',
      ),
      BathymetricStation(
        chainageM: 275.0,
        bedElevationRlm: 86.80, // High scour hole!
        pipeTopElevationRlm: 84.88, // Only 1.92m DOC (violation of 2.5m!)
        baselineBedRlm: 90.40, // 3.6m bed lowering
        zoneType: 'Active Scour Hole (CRITICAL)',
      ),
      BathymetricStation(
        chainageM: 310.0,
        bedElevationRlm: 88.10,
        pipeTopElevationRlm: 85.80,
        baselineBedRlm: 90.80,
        zoneType: 'Thalweg South Margin',
      ),
      BathymetricStation(
        chainageM: 350.0,
        bedElevationRlm: 93.80,
        pipeTopElevationRlm: 88.20,
        baselineBedRlm: 95.10,
        zoneType: 'South Point Bar',
      ),
      BathymetricStation(
        chainageM: 400.0,
        bedElevationRlm: 98.50,
        pipeTopElevationRlm: 91.00,
        baselineBedRlm: 99.20,
        zoneType: 'South Meander Berm',
      ),
      BathymetricStation(
        chainageM: 450.0,
        bedElevationRlm: 101.80,
        pipeTopElevationRlm: 93.00,
        baselineBedRlm: 101.90,
        zoneType: 'South Bank Bluff Top',
      ),
    ];

    // Triaxial Strong-Motion Accelerometer Stations (SA-01 to SA-06)
    _seismicStations = const [
      SeismicStation(
        id: 'SA-01',
        stationName: 'North Abutment Rock Anchor Station',
        geologicalSetting: 'Terrace Alluvium over Bedrock',
        pgaG: 0.048,
        accelX: 0.048,
        accelY: 0.041,
        accelZ: 0.027,
        ariasIntensityMs: 0.082,
        liquefactionRu: 0.38,
      ),
      SeismicStation(
        id: 'SA-02',
        stationName: 'Burhi Dihing River Mid-Span Caisson',
        geologicalSetting: 'Saturated River Silt & Gravel',
        pgaG: 0.054,
        accelX: 0.054,
        accelY: 0.048,
        accelZ: 0.032,
        ariasIntensityMs: 0.098,
        liquefactionRu: 0.52,
      ),
      SeismicStation(
        id: 'SA-03',
        stationName: 'South Bluff Crest Observation Pylon',
        geologicalSetting: 'Overconsolidated Silty Clay',
        pgaG: 0.044,
        accelX: 0.044,
        accelY: 0.039,
        accelZ: 0.024,
        ariasIntensityMs: 0.076,
        liquefactionRu: 0.34,
      ),
      SeismicStation(
        id: 'SA-04',
        stationName: 'Valve Station VS-04 Boundary Vault',
        geologicalSetting: 'Engineered Compacted Structural Fill',
        pgaG: 0.038,
        accelX: 0.038,
        accelY: 0.032,
        accelZ: 0.020,
        ariasIntensityMs: 0.061,
        liquefactionRu: 0.22,
      ),
      SeismicStation(
        id: 'SA-05',
        stationName: 'Slump Escarpment RoW Toe Vault',
        geologicalSetting: 'Colluvial Debris / Shear Slump',
        pgaG: 0.062,
        accelX: 0.062,
        accelY: 0.056,
        accelZ: 0.035,
        ariasIntensityMs: 0.114,
        liquefactionRu: 0.58,
      ),
      SeismicStation(
        id: 'SA-06',
        stationName: 'Naharkatia Central Header Manifold',
        geologicalSetting: 'Deep Alluvial Sandy Silt',
        pgaG: 0.035,
        accelX: 0.035,
        accelY: 0.030,
        accelZ: 0.018,
        ariasIntensityMs: 0.054,
        liquefactionRu: 0.28,
      ),
    ];

    // Pipeline FBG Strain Gauge Stations (SG-01 to SG-08)
    _strainStations = const [
      StrainGaugeStation(
        id: 'SG-01',
        chainage: 'Ch. 42+180',
        locationSegment: 'North Entry Sagbend Flange',
        axialMicrostrain: 420.0,
        bendingMicrostrain: 210.0,
        hoopMicrostrain: 890.0,
        temperatureC: 24.2,
      ),
      StrainGaugeStation(
        id: 'SG-02',
        chainage: 'Ch. 42+450',
        locationSegment: 'North Riprap Overbend',
        axialMicrostrain: 540.0,
        bendingMicrostrain: 430.0,
        hoopMicrostrain: 895.0,
        temperatureC: 24.5,
      ),
      StrainGaugeStation(
        id: 'SG-03',
        chainage: 'Ch. 42+750',
        locationSegment: 'Thalweg Entry Transition',
        axialMicrostrain: 680.0,
        bendingMicrostrain: 610.0,
        hoopMicrostrain: 902.0,
        temperatureC: 23.8,
      ),
      StrainGaugeStation(
        id: 'SG-04',
        chainage: 'Ch. 42+820',
        locationSegment: 'Scour Pocket Center Spool',
        axialMicrostrain: 780.0,
        bendingMicrostrain: 760.0,
        hoopMicrostrain: 910.0,
        temperatureC: 23.6,
      ),
      StrainGaugeStation(
        id: 'SG-05',
        chainage: 'Ch. 42+920',
        locationSegment: 'South Bank Slump Sagbend',
        axialMicrostrain: 910.0,
        bendingMicrostrain: 890.0, // High bending due to slope subsidence!
        hoopMicrostrain: 915.0,
        temperatureC: 24.0,
      ),
      StrainGaugeStation(
        id: 'SG-06',
        chainage: 'Ch. 43+150',
        locationSegment: 'South Exit Overbend',
        axialMicrostrain: 610.0,
        bendingMicrostrain: 480.0,
        hoopMicrostrain: 898.0,
        temperatureC: 24.8,
      ),
      StrainGaugeStation(
        id: 'SG-07',
        chainage: 'Ch. 43+380',
        locationSegment: 'Floodplain Anchor Block Spool',
        axialMicrostrain: 490.0,
        bendingMicrostrain: 280.0,
        hoopMicrostrain: 892.0,
        temperatureC: 25.1,
      ),
      StrainGaugeStation(
        id: 'SG-08',
        chainage: 'Ch. 43+600',
        locationSegment: 'Tie-In Valve Station VS-04 Manifold',
        axialMicrostrain: 380.0,
        bendingMicrostrain: 190.0,
        hoopMicrostrain: 885.0,
        temperatureC: 25.4,
      ),
    ];

    // Historical Automated Safety Notification Logs
    _notificationLogs = [
      GeohazardNotification(
        id: 'NOTIF-GH-8902',
        timestamp: now.subtract(const Duration(minutes: 14)),
        triggerSource: 'IN-05 Displacement Rate Alarm',
        message: 'Lateral ground displacement rate exceeded Warning limit: 3.42 mm/day at Ch. 42+820 (South Toe).',
        level: GeohazardThreatLevel.warning,
        recipients: const ['OIL Duliajan Incident Command', 'Geotechnical Lead', 'SCADA Ops Room'],
        acknowledged: true,
      ),
      GeohazardNotification(
        id: 'NOTIF-GH-8894',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 20)),
        triggerSource: 'Bathymetric Echo Sounder Survey',
        message: 'Riverbed Depth of Cover (DOC) dropped to 1.92m at Ch. 275m (0.58m deficit vs 2.5m minimum design requirement).',
        level: GeohazardThreatLevel.warning,
        recipients: const ['Pipeline Integrity Head', 'River Training EPC', 'TPIA Lead Inspector'],
        acknowledged: true,
      ),
      GeohazardNotification(
        id: 'NOTIF-GH-8871',
        timestamp: now.subtract(const Duration(hours: 8, minutes: 45)),
        triggerSource: 'CWC Khowang Hydrological Gauge',
        message: 'Burhi Dihing water level crossed Danger Mark: 102.40m MSL (+0.29m over DL 102.11m MSL). Flood hydrograph peak expected in 6 hours.',
        level: GeohazardThreatLevel.watch,
        recipients: const ['All Site Foremen', 'Emergency Response Unit', 'District Disaster Authority'],
        acknowledged: true,
      ),
      GeohazardNotification(
        id: 'NOTIF-GH-8850',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        triggerSource: 'FBG Strain Rosette SG-05',
        message: 'South Bank Slump Sagbend strain reached 1800 με (76.8% SMYS). Approaching 85% SMYS alarm limit.',
        level: GeohazardThreatLevel.warning,
        recipients: const ['Pipeline Operations Room', 'Chief Geotechnical Engineer'],
        acknowledged: true,
      ),
    ];
  }

  /// Master Threat Level computed across all sub-systems
  GeohazardThreatLevel get _overallThreatLevel {
    if (_isSeismicSimulationActive && _simulatedPgaG >= 0.25) {
      return GeohazardThreatLevel.emergency;
    }

    // Check Inclinometers
    final hasInclinometerEmergency = _inclinometers.any((s) => s.threatLevel == GeohazardThreatLevel.emergency);
    final hasInclinometerWarning = _inclinometers.any((s) => s.threatLevel == GeohazardThreatLevel.warning);

    // Check Bathymetry Scour
    final hasBathymetricEmergency = _bathymetricData.any((s) => s.threatLevel == GeohazardThreatLevel.emergency);
    final hasBathymetricWarning = _bathymetricData.any((s) => s.threatLevel == GeohazardThreatLevel.warning);

    // Check Strain
    final hasStrainEmergency = _strainStations.any((s) => s.threatLevel == GeohazardThreatLevel.emergency);
    final hasStrainWarning = _strainStations.any((s) => s.threatLevel == GeohazardThreatLevel.warning);

    if (hasInclinometerEmergency || hasBathymetricEmergency || hasStrainEmergency) {
      return GeohazardThreatLevel.emergency;
    }
    if (hasInclinometerWarning || hasBathymetricWarning || hasStrainWarning) {
      return GeohazardThreatLevel.warning;
    }
    return GeohazardThreatLevel.watch;
  }

  void _toggleSeismicSimulation() {
    setState(() {
      _isSeismicSimulationActive = !_isSeismicSimulationActive;
      _simulatedPgaG = _isSeismicSimulationActive ? 0.28 : 0.048;

      if (_isSeismicSimulationActive) {
        _notificationLogs.insert(
          0,
          GeohazardNotification(
            id: 'NOTIF-GH-SIM-${DateTime.now().millisecondsSinceEpoch % 10000}',
            timestamp: DateTime.now(),
            triggerSource: 'Simulated Kopili Fault Zone V Quake',
            message: 'Strong motion PGA spiked to 0.28g (Zone V threshold exceeded). Emergency interlock auto-standby triggered!',
            level: GeohazardThreatLevel.emergency,
            recipients: const ['OIL Disaster Cell', 'SCADA Gas Dispatcher', 'ESDV Interlock Matrix'],
            acknowledged: false,
          ),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _isSeismicSimulationActive ? const Color(0xFFF43F5E) : AppTheme.tertiary,
        content: Text(
          _isSeismicSimulationActive
              ? 'SIMULATION ACTIVATED: Assam Zone V Ground Motion PGA = 0.28g (EMERGENCY LEVEL)'
              : 'Seismic Simulation Reset: Ambient micro-tremor baseline restored (0.048g Normal)',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showNotificationBroadcastDialog() {
    final now = DateTime.now();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _overallThreatLevel.bgTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_overallThreatLevel.icon, color: _overallThreatLevel.color, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Broadcast Geohazard Alert',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _overallThreatLevel.bgTint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _overallThreatLevel.borderTint),
                ),
                child: Row(
                  children: [
                    Text(
                      _overallThreatLevel.label,
                      style: TextStyle(
                        color: _overallThreatLevel.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _overallThreatLevel.sublabel,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Dispatch Channels & Protocols:',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDispatchTargetItem(Icons.sms_rounded, 'SMS Gateway to 14 On-Call Engineers', 'Priority 1 • Immediate'),
              _buildDispatchTargetItem(Icons.sensors_rounded, 'OIL Duliajan SCADA Interlock Bus', 'MODBUS Tag: GEO_ALM_WARN_02'),
              _buildDispatchTargetItem(Icons.phone_in_talk_rounded, 'District Disaster Incident Commander', '+91 374 280 0411 (Auto-IVR)'),
              _buildDispatchTargetItem(Icons.security_rounded, 'SOP-GEO-09 Action Escalation', 'ESDV Pre-trip Arming Check'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payload Preview:', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '[NIRMAAN-GEOALERT] ${_overallThreatLevel.label}: Scour DOC 1.92m at Ch. 275m (<2.5m DOC design req). IN-05 rate 3.42 mm/day at South Toe. FoS=1.34.',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Timestamp: ${now.toIso8601String().substring(0, 19)}Z • Hash: SHA256:7f8a9e...c41',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _overallThreatLevel.color,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _notificationLogs.insert(
                  0,
                  GeohazardNotification(
                    id: 'NOTIF-GH-MAN-${DateTime.now().millisecondsSinceEpoch % 10000}',
                    timestamp: DateTime.now(),
                    triggerSource: 'Manual Dispatch: Incident Lead',
                    message: 'Official Multi-Channel Safety Broadcast dispatched: ${_overallThreatLevel.label} status confirmed across Burhi Dihing Crossing.',
                    level: _overallThreatLevel,
                    recipients: const ['OIL Duliajan Incident Command', 'SCADA Control Room', 'Geotech Response Gang'],
                    acknowledged: true,
                  ),
                );
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.tertiary,
                  content: Text('Safety Notification successfully broadcast to all 4 channels!'),
                ),
              );
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Confirm Broadcast'),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchTargetItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryLight, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 14),
        ],
      ),
    );
  }

  void _showSopChecklistModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Standard Operating Procedure (SOP-GEO-09)',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Pipeline River Crossing Geohazard Action Matrix',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: AppTheme.border, height: 24),
              _buildSopLevelCard(GeohazardThreatLevel.normal, [
                'Weekly drone LiDAR slope topography scan & photogrammetry comparison.',
                'Bi-weekly LoRa inclinometer data synchronization & baseline drift check.',
                'Quarterly bathymetric dual-frequency echo sounding transect check.',
                'Seismic station SA-01 to SA-06 triaxial zero-point offset calibration.',
              ]),
              const SizedBox(height: 12),
              _buildSopLevelCard(GeohazardThreatLevel.watch, [
                'Telemetry polling rate increased to 15-minute bursts (LoRa Class C).',
                'Activate Autonomous Echo Sounder Boat (USV) on 48-hr standby at Khowang.',
                'Daily visual walk-down along 500m RoW corridor for tension crack formation.',
                'Piezometer pore water pressure monitoring vs saturation threshold (80 kPa).',
              ]),
              const SizedBox(height: 12),
              _buildSopLevelCard(GeohazardThreatLevel.warning, [
                'Mandatory mobilization of riprap / geo-bag barge to Ch. 42+780 scour hole.',
                'Pipeline operating pressure throttled down by 20% (from 92.5 bar to 74.0 bar).',
                'Geotechnical engineering camp deployed on-site with core drilling rig.',
                'FBG strain rosette readings polled continuously every 60 seconds.',
              ]),
              const SizedBox(height: 12),
              _buildSopLevelCard(GeohazardThreatLevel.emergency, [
                'Instant automated ESDV closure (VS-03 and VS-04 fail-close within 12s).',
                'Controlled blowdown vent sequence initiated to de-pressurize the river segment.',
                'Immediate 500-meter safety cordon established; traffic diverted on nearby NH-37.',
                'NDRF / State Disaster Management Authority and OIL Fire & Safety mobilized.',
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSopLevelCard(GeohazardThreatLevel level, List<String> checklist) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: level.bgTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: level.borderTint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(level.icon, color: level.color, size: 18),
              const SizedBox(width: 8),
              Text(
                '${level.label} STAGE PROTOCOL',
                style: TextStyle(color: level.color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...checklist.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right_rounded, color: level.color, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, height: 1.3),
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

  @override
  Widget build(BuildContext context) {
    final threat = _overallThreatLevel;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Geohazard & River Scour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              'Brahmaputra & Burhi Dihing • Assam Zone V Telemetry',
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'SOP-GEO-09 Protocol',
            icon: const Icon(Icons.rule_folder_rounded, color: AppTheme.primaryLight),
            onPressed: _showSopChecklistModal,
          ),
          IconButton(
            tooltip: 'Broadcast Safety Notification',
            icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFFB95F)),
            onPressed: _showNotificationBroadcastDialog,
          ),
          IconButton(
            tooltip: 'Toggle Zone V Quake Simulation',
            icon: Icon(
              Icons.vibration_rounded,
              color: _isSeismicSimulationActive ? const Color(0xFFF43F5E) : AppTheme.textMuted,
            ),
            onPressed: _toggleSeismicSimulation,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(text: 'Overview & Matrix', icon: Icon(Icons.dashboard_rounded, size: 18)),
            Tab(text: 'Inclinometers (12)', icon: Icon(Icons.show_chart_rounded, size: 18)),
            Tab(text: 'Bathymetry & Scour', icon: Icon(Icons.water_rounded, size: 18)),
            Tab(text: 'Seismic Zone V', icon: Icon(Icons.timeline_rounded, size: 18)),
            Tab(text: 'Pipeline Strain', icon: Icon(Icons.speed_rounded, size: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top Threat Level Alert Banner
          _buildThreatLevelBanner(threat),
          // Tab View Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildInclinometersTab(),
                _buildBathymetryTab(),
                _buildSeismicTab(),
                _buildStrainTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Top Threat Level Banner Widget
  Widget _buildThreatLevelBanner(GeohazardThreatLevel threat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: threat.bgTint,
        border: Border(
          bottom: BorderSide(color: threat.borderTint, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: threat.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(threat.icon, color: threat.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'STATUS: ${threat.label}',
                      style: TextStyle(
                        color: threat.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: threat.borderTint),
                      ),
                      child: Text(
                        _isSeismicSimulationActive ? 'SIMULATION ENGAGED' : 'LIVE TELEMETRY',
                        style: TextStyle(
                          color: _isSeismicSimulationActive ? const Color(0xFFF43F5E) : AppTheme.tertiary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  threat.sopAction,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: threat.color,
              side: BorderSide(color: threat.borderTint),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _showNotificationBroadcastDialog,
            child: const Text('Broadcast', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW & THREAT MATRIX
  // ==========================================
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Basin Context & Corridor Header Card
        Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.terrain_rounded, color: AppTheme.primaryLight, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Corridor Geotechnical Assessment',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      '18" API 5L X70 PSL2',
                      style: TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Burhi Dihing Meander Basin (Ch. 42+150 to Ch. 43+600) & Brahmaputra South Bank reach. Saturated alluvial sand/silt prone to monsoon hydraulic bank caving, deep thalweg migration, and Zone V seismic liquefaction.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMetricPill('RoW Bluff Setback', '${_bankSetbackDistanceM}m', _bankSetbackDistanceM < 20 ? AppTheme.secondary : AppTheme.tertiary),
                  _buildMetricPill('Static Slope FoS', _staticFos.toStringAsFixed(2), _staticFos < 1.5 ? const Color(0xFFFB923C) : AppTheme.tertiary),
                  _buildMetricPill('Seismic FoS (kh=0.18)', _seismicFos.toStringAsFixed(2), _seismicFos < 1.15 ? const Color(0xFFF43F5E) : AppTheme.tertiary),
                  _buildMetricPill('Max Inclinometer Rate', '3.42 mm/d', const Color(0xFFFB923C)),
                  _buildMetricPill('Min Scour DOC', '1.92m', const Color(0xFFFB923C)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // River Basin Hydrological Gauge
        Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.waves_rounded, color: Color(0xFF00E5FF), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'CWC Khowang Hydrological Gauge Telemetry',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x33FFB95F),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('OVER DANGER LEVEL', style: TextStyle(color: AppTheme.secondary, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Water Level Bar Indicator
              LayoutBuilder(
                builder: (context, constraints) {
                  final range = _hflMsl - 100.0;
                  final curPos = ((_riverWaterLevelMsl - 100.0) / range).clamp(0.0, 1.0);
                  final dlPos = ((_dangerLevelMsl - 100.0) / range).clamp(0.0, 1.0);

                  return Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          // Current Level Fill
                          FractionallySizedBox(
                            widthFactor: curPos,
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0284C7), Color(0xFFFFB95F)],
                                ),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                          // Danger Level Marker
                          Positioned(
                            left: constraints.maxWidth * dlPos,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: const Color(0xFFF43F5E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('100.0m (Base)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                          Text(
                            'Current: ${_riverWaterLevelMsl.toStringAsFixed(2)}m MSL',
                            style: const TextStyle(color: Color(0xFFFFB95F), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'DL: ${_dangerLevelMsl.toStringAsFixed(2)}m',
                            style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          Text('HFL: ${_hflMsl.toStringAsFixed(2)}m', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSimpleKpi('River Discharge', '${_riverDischargeCumecs.toStringAsFixed(0)} m³/s', Icons.air_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSimpleKpi('Mean Flow Velocity', '$_flowVelocityMs m/s', Icons.speed_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSimpleKpi('Bluff Retreat Rate', '3.2 m/yr', Icons.trending_up_rounded)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Subsystems Threat Level Matrix Grid
        const Text(
          'Geohazard Threat Level Matrix',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildMatrixSubsystemCard(
          title: 'Riverbank In-Place Inclinometers',
          metric: 'IN-05: 3.42 mm/day (Warning threshold: 2.0 mm/day)',
          level: GeohazardThreatLevel.warning,
          detail: 'Active rotational slip detected at -15.8m shear plane on South bank toe.',
          icon: Icons.show_chart_rounded,
        ),
        const SizedBox(height: 8),
        _buildMatrixSubsystemCard(
          title: 'Riverbed Bathymetry & Scour Cover',
          metric: 'Min DOC = 1.92m (Requirement: >= 2.50m DOC)',
          level: GeohazardThreatLevel.warning,
          detail: 'Severe scour depression at Ch. 275m in the main thalweg. 0.58m cover deficit.',
          icon: Icons.water_rounded,
        ),
        const SizedBox(height: 8),
        _buildMatrixSubsystemCard(
          title: 'Assam Zone V Seismic Acceleration',
          metric: _isSeismicSimulationActive ? 'PGA = 0.28g (EMERGENCY LEVEL)' : 'PGA = 0.048g (Normal Baseline)',
          level: _isSeismicSimulationActive ? GeohazardThreatLevel.emergency : GeohazardThreatLevel.normal,
          detail: 'Strong motion network monitoring Kopili Fault & Naga Thrust activity.',
          icon: Icons.timeline_rounded,
        ),
        const SizedBox(height: 8),
        _buildMatrixSubsystemCard(
          title: 'Pipeline Strain & SMYS Yield Envelope',
          metric: 'SG-05: 1800 με • 76.8% of SMYS (Limit: 85% SMYS)',
          level: GeohazardThreatLevel.watch,
          detail: 'Bending microstrain elevated due to differential riverbank settlement.',
          icon: Icons.speed_rounded,
        ),
        const SizedBox(height: 14),

        // Automated Safety Notification Logs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Automated Notification Logs',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_notificationLogs.length} events logged',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._notificationLogs.map((log) => _buildNotificationLogItem(log)),
      ],
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSimpleKpi(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryLight, size: 14),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildMatrixSubsystemCard({
    required String title,
    required String metric,
    required GeohazardThreatLevel level,
    required String detail,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: level.bgTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: level.borderTint),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: level.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: level.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: level.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        level.label,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(metric, style: TextStyle(color: level.color, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationLogItem(GeohazardNotification log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: log.level.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    log.triggerSource,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')} IST',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(log.message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.3)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.send_rounded, size: 10, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Sent to: ${log.recipients.join(', ')}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (log.acknowledged)
                const Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 12, color: AppTheme.tertiary),
                    SizedBox(width: 3),
                    Text('Ack', style: TextStyle(color: AppTheme.tertiary, fontSize: 9)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: IN-PLACE INCLINOMETERS (IN-01 to IN-12)
  // ==========================================
  Widget _buildInclinometersTab() {
    final filteredInclinometers = _inclinometers.where((sensor) {
      if (_inclinometerFilter == 'ALL') return true;
      if (_inclinometerFilter == 'NORMAL') return sensor.threatLevel == GeohazardThreatLevel.normal;
      if (_inclinometerFilter == 'WATCH') return sensor.threatLevel == GeohazardThreatLevel.watch;
      if (_inclinometerFilter == 'WARNING') return sensor.threatLevel == GeohazardThreatLevel.warning;
      return true;
    }).toList();

    final selectedSensor = _inclinometers[_selectedInclinometerIndex.clamp(0, _inclinometers.length - 1)];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Sensor Selection & Filter Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In-Place Inclinometer Array (IN-01 to IN-12)',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Bi-axial MEMS sensors measuring lateral displacement (mm/day)',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
              ],
            ),
            // Filter dropdown/chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _inclinometerFilter,
                  dropdownColor: AppTheme.surfaceCard,
                  isDense: true,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All (12)')),
                    DropdownMenuItem(value: 'WARNING', child: Text('Warning (1)')),
                    DropdownMenuItem(value: 'WATCH', child: Text('Watch (4)')),
                    DropdownMenuItem(value: 'NORMAL', child: Text('Normal (7)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _inclinometerFilter = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Depth vs Displacement Custom Curve Inspector Card
        Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: selectedSensor.threatLevel.bgTint,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: selectedSensor.threatLevel.borderTint),
                        ),
                        child: Text(
                          selectedSensor.id,
                          style: TextStyle(
                            color: selectedSensor.threatLevel.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedSensor.chainage} • ${selectedSensor.locationDescription}',
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Depth: ${selectedSensor.depthM}m • Shear Plane at ${selectedSensor.slipPlaneDepthM}m',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${selectedSensor.displacementRateMmDay.toStringAsFixed(2)} mm/day',
                    style: TextStyle(
                      color: selectedSensor.threatLevel.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Custom Inclinometer Depth vs Displacement Graph
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: InclinometerProfilePainter(
                    profile: selectedSensor.displacementProfile,
                    depthM: selectedSensor.depthM,
                    slipPlaneDepthM: selectedSensor.slipPlaneDepthM,
                    accentColor: selectedSensor.threatLevel.color,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSensorParam('Cumulative Disp.', '${selectedSensor.cumulativeDispMm} mm'),
                  _buildSensorParam('Rate Status', selectedSensor.threatLevel.label),
                  _buildSensorParam('LoRa SNR', '${selectedSensor.loraSnrDb} dBm'),
                  _buildSensorParam('Battery', '${selectedSensor.batteryPct.toInt()}%'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Inclinometer List Cards (Tap to Inspect)
        const Text(
          'Select Sensor to View Slip-Plane Depth Profile:',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...filteredInclinometers.map((sensor) {
          final isSelected = _inclinometers.indexOf(sensor) == _selectedInclinometerIndex;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedInclinometerIndex = _inclinometers.indexOf(sensor);
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.surfaceContainerHigh : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: sensor.threatLevel.bgTint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: sensor.threatLevel.borderTint),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      sensor.id,
                      style: TextStyle(
                        color: sensor.threatLevel.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              sensor.chainage,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: sensor.threatLevel.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                sensor.threatLevel.label,
                                style: TextStyle(color: sensor.threatLevel.color, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sensor.locationDescription,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${sensor.displacementRateMmDay.toStringAsFixed(2)} mm/d',
                        style: TextStyle(
                          color: sensor.threatLevel.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Σ ${sensor.cumulativeDispMm}mm',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSensorParam(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ==========================================
  // TAB 3: RIVERBED BATHYMETRY & SCOUR SURVEY
  // ==========================================
  Widget _buildBathymetryTab() {
    // Current Scrubber Bathymetric Station
    final scrubbedStation = _bathymetricData.firstWhere(
      (st) => (st.chainageM - _scrubberChainageM).abs() < 25.0,
      orElse: () => _bathymetricData[6],
    );

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Hydrographic Survey Summary Card
        Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.water_rounded, color: Color(0xFF00E5FF), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Dual-Frequency Echo Sounding Survey',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x33FB923C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('DEFICIT DETECTED', style: TextStyle(color: Color(0xFFFB923C), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'High-resolution multi-beam acoustic survey comparing post-monsoon riverbed elevation against pipeline top-of-pipe. PNGRB / ASME B31.8 / OISD-141 mandates minimum 2.50m Depth of Cover (DOC) across all major river crossings.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildMetricPill('Min Design DOC', '2.50 m', AppTheme.tertiary)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricPill('Worst Survey DOC', '1.92 m', const Color(0xFFF43F5E))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricPill('Cover Deficit', '-0.58 m', const Color(0xFFF43F5E))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricPill('Free-Span Risk', 'No Span (Safe)', AppTheme.secondary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Interactive Bathymetric Cross-Section Profile
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Burhi Dihing Riverbed & Pipeline Cross-Section Profile',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text('450m Transect', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 8),
              // Custom Painter Cross Section
              SizedBox(
                height: 200,
                width: double.infinity,
                child: CustomPaint(
                  painter: BathymetricCrossSectionPainter(
                    stations: _bathymetricData,
                    waterLevelMsl: _riverWaterLevelMsl,
                    scrubberChainageM: _scrubberChainageM,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Interactive Chainage Scrubber Slider
              Row(
                children: [
                  const Text('0m', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.primaryLight,
                        inactiveTrackColor: AppTheme.surface,
                        thumbColor: const Color(0xFFFFB95F),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _scrubberChainageM,
                        min: 0.0,
                        max: 450.0,
                        onChanged: (val) {
                          setState(() {
                            _scrubberChainageM = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const Text('450m', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
              // Scrubber Inspection Details Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scrubbedStation.threatLevel.borderTint),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chainage: ${scrubbedStation.chainageM.toStringAsFixed(0)}m • ${scrubbedStation.zoneType}',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Bed RL: ${scrubbedStation.bedElevationRlm.toStringAsFixed(2)}m MSL | Pipe Top RL: ${scrubbedStation.pipeTopElevationRlm.toStringAsFixed(2)}m MSL',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'DOC: ${scrubbedStation.depthOfCoverM.toStringAsFixed(2)}m',
                          style: TextStyle(
                            color: scrubbedStation.threatLevel.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          scrubbedStation.depthOfCoverM < 2.5 ? 'DEFICIT vs 2.5m REQ' : 'COMPLIANT',
                          style: TextStyle(
                            color: scrubbedStation.threatLevel.color,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Scour Mitigation Action Plan
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Engineered Scour Protection & Countermeasures',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildScourActionStep('1', 'Articulated Concrete Block (ACB) Mattress Deployment', 'Pre-cast concrete block mattresses (400mm thick) linked by polyester cables scheduled for placement over Ch. 260m - 295m scour depression.'),
              const SizedBox(height: 8),
              _buildScourActionStep('2', 'Non-Woven Geotextile Filter & Heavy Riprap Dumping', 'Grade I stone riprap (300-500mm boulder sizing) to form a 1.2m ballast cap restoring depth of cover to 3.12m MSL.'),
              const SizedBox(height: 8),
              _buildScourActionStep('3', 'Submerged Hydrodynamic Deflector Vanes', 'River training vanes upstream to divert the erosive high-velocity thalweg jet away from the pipeline crossing corridor.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScourActionStep(String stepNumber, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryLight),
          ),
          alignment: Alignment.center,
          child: Text(stepNumber, style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 4: SEISMIC ZONE V ACCELEROMETER ARRAY
  // ==========================================
  Widget _buildSeismicTab() {
    final activePga = _isSeismicSimulationActive ? _simulatedPgaG : 0.048;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Zone V Context Card
        Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timeline_rounded, color: Color(0xFFA78BFA), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Assam Seismic Zone V Network (IS 1893)',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x33A78BFA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('ZONE FACTOR Z = 0.36', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Continuous strong-motion monitoring across Kopili Fault (48km NW) and Naga Thrust (22km SE). Dynamic liquefaction potential index (ru) computed in real-time for saturated alluvial sediments.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMetricPill('Peak Ground Accel (PGA)', '${activePga.toStringAsFixed(3)} g', activePga >= 0.18 ? const Color(0xFFF43F5E) : AppTheme.tertiary),
                  _buildMetricPill('OBE Trigger Limit', '0.180 g', AppTheme.secondary),
                  _buildMetricPill('SSE Shutdown Limit', '0.360 g', const Color(0xFFF43F5E)),
                  _buildMetricPill('Liquefaction (ru)', _isSeismicSimulationActive ? '0.78 (Watch)' : '0.38 (Safe)', _isSeismicSimulationActive ? const Color(0xFFFB923C) : AppTheme.tertiary),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Live Triaxial Waveform Display Card
        Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Triaxial Seismogram Oscillogram (SA-01 Burhi Dihing Abutment)',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      _buildWaveLegend('X (E-W)', const Color(0xFF38BDF8)),
                      const SizedBox(width: 8),
                      _buildWaveLegend('Y (N-S)', const Color(0xFFFFB95F)),
                      const SizedBox(width: 8),
                      _buildWaveLegend('Z (Vert)', const Color(0xFFC084FC)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Waveform Custom Painter
              SizedBox(
                height: 140,
                width: double.infinity,
                child: CustomPaint(
                  painter: SeismicWaveformPainter(
                    isSimulated: _isSeismicSimulationActive,
                    pgaG: activePga,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current PGA: ${activePga.toStringAsFixed(3)} g • Sa(0.2s) = ${(activePga * 2.3).toStringAsFixed(3)}g',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isSeismicSimulationActive ? const Color(0xFFF43F5E) : AppTheme.primaryLight,
                      side: BorderSide(color: _isSeismicSimulationActive ? const Color(0xFFF43F5E) : AppTheme.primaryLight),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _toggleSeismicSimulation,
                    icon: Icon(_isSeismicSimulationActive ? Icons.stop_circle_rounded : Icons.play_arrow_rounded, size: 14),
                    label: Text(_isSeismicSimulationActive ? 'Stop M5.8 Quake Sim' : 'Simulate M5.8 Kopili Quake', style: const TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Triaxial Accelerometer Stations Grid
        const Text(
          'Triaxial Accelerometer Array (SA-01 to SA-06):',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._seismicStations.map((station) {
          final displayPga = _isSeismicSimulationActive ? (station.pgaG * 5.2) : station.pgaG;
          final isWarning = displayPga >= 0.18;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isWarning ? const Color(0xFFF43F5E) : AppTheme.border,
                width: isWarning ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isWarning ? const Color(0x33F43F5E) : const Color(0x334EDEA3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    station.id,
                    style: TextStyle(
                      color: isWarning ? const Color(0xFFF43F5E) : AppTheme.tertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(station.stationName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(station.geologicalSetting, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${displayPga.toStringAsFixed(3)} g',
                      style: TextStyle(
                        color: isWarning ? const Color(0xFFF43F5E) : AppTheme.primaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ru: ${(station.liquefactionRu * (_isSeismicSimulationActive ? 1.6 : 1.0)).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isWarning ? const Color(0xFFF43F5E) : AppTheme.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWaveLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 2, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ==========================================
  // TAB 5: PIPELINE STRAIN & 85% SMYS YIELD
  // ==========================================
  Widget _buildStrainTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // SMYS Yield Envelope Overview Card
        Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed_rounded, color: AppTheme.primaryLight, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '18" API 5L X70 SMYS Yield Envelope',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x334EDEA3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('SAFE YIELD BOUNDARY', style: TextStyle(color: AppTheme.tertiary, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Fiber Bragg Grating (FBG) optical strain rosettes measure axial, bending, and hoop microstrain (με). 85% SMYS alarm limit = 1991.5 με (412.25 MPa von Mises equivalent). Critical watch at South Bank Sagbend.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildMetricPill('SMYS (100%)', '2343 με', AppTheme.textPrimary)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricPill('85% Alarm Limit', '1992 με', const Color(0xFFF43F5E))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricPill('Max Measured', '1800 με', const Color(0xFFFFB95F))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricPill('Max % SMYS', '76.8%', const Color(0xFFFFB95F))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Visual Yield Envelope Gauge Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Strain Gauge Telemetry vs SMYS Yield Threshold',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text('ASME B31.8 Limit', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 14),
              // Gauge Progress Bar
              LayoutBuilder(
                builder: (context, constraints) {
                  const maxStrain = StrainGaugeStation.yieldStrain; // 2343
                  const alarmLimit = StrainGaugeStation.smys85Limit; // 1991.5
                  const curStrain = 1800.0; // SG-05 worst case

                  final curPct = (curStrain / maxStrain).clamp(0.0, 1.0);
                  final alarmPct = (alarmLimit / maxStrain).clamp(0.0, 1.0);

                  return Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 18,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          // Current Fill
                          FractionallySizedBox(
                            widthFactor: curPct,
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0284C7), Color(0xFFFFB95F)],
                                ),
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                          // 85% SMYS Limit Marker
                          Positioned(
                            left: constraints.maxWidth * alarmPct,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 3,
                              color: const Color(0xFFF43F5E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0 με (0%)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                          Text('Current Max: 1800 με (76.8% SMYS)', style: TextStyle(color: Color(0xFFFFB95F), fontSize: 10, fontWeight: FontWeight.bold)),
                          Text('85% SMYS (1992 με)', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 9, fontWeight: FontWeight.bold)),
                          Text('100% SMYS', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              // 4-Quadrant Rosette Strain Breakdown Box (SG-05 South Bank Slump)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Worst-Case Station: SG-05 (South Bank Slump Sagbend, Ch. 42+920)',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildStrainComponent('12 o\'clock (Crown)', '+910 με (Tension)')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStrainComponent('6 o\'clock (Invert)', '-890 με (Compression)')),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _buildStrainComponent('3 o\'clock (East / River)', '+410 με (Lateral)')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStrainComponent('9 o\'clock (West / Bank)', '-395 με (Lateral)')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // FBG Strain Rosette Stations List (SG-01 to SG-08)
        const Text(
          'FBG Distributed Strain Rosette Stations (SG-01 to SG-08):',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._strainStations.map((station) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: station.threatLevel.borderTint),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: station.threatLevel.bgTint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: station.threatLevel.borderTint),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    station.id,
                    style: TextStyle(
                      color: station.threatLevel.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${station.chainage} • ${station.locationSegment}',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Axial: ${station.axialMicrostrain.toInt()} με | Bending: ${station.bendingMicrostrain.toInt()} με | Hoop: ${station.hoopMicrostrain.toInt()} με',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${station.pctSmys.toStringAsFixed(1)}% SMYS',
                      style: TextStyle(
                        color: station.threatLevel.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${station.equivalentVonMisesStrain.toStringAsFixed(0)} με',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStrainComponent(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==========================================
// CUSTOM PAINTERS
// ==========================================

/// Inclinometer Depth vs Lateral Displacement Curve Painter
class InclinometerProfilePainter extends CustomPainter {
  final List<double> profile;
  final double depthM;
  final double slipPlaneDepthM;
  final Color accentColor;

  const InclinometerProfilePainter({
    required this.profile,
    required this.depthM,
    required this.slipPlaneDepthM,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0F1A36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)),
      bgPaint,
    );

    // Draw Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2E5C)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(40, y), Offset(size.width - 20, y), gridPaint);
    }

    // Y Axis (Depth 0m down to -depthM)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final textStyle = const TextStyle(color: Color(0xFF64748B), fontSize: 9);

    for (int i = 0; i <= 4; i++) {
      final depthLabel = '${-(i * (depthM / 4)).round()}m';
      textPainter.text = TextSpan(text: depthLabel, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(8, (size.height * (i / 4) - 6).clamp(4, size.height - 14)));
    }

    // Slip Plane Line (Horizontal dashed or red line)
    final slipRatio = (-slipPlaneDepthM / depthM).clamp(0.0, 1.0);
    final slipY = size.height * slipRatio;

    final slipPaint = Paint()
      ..color = const Color(0xFFF43F5E)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(40, slipY), Offset(size.width - 20, slipY), slipPaint);

    textPainter.text = TextSpan(
      text: 'Shear Slip Plane (${slipPlaneDepthM.toStringAsFixed(1)}m)',
      style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 9, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 24, slipY - 14));

    // Draw Displacement Curve
    if (profile.isEmpty) return;

    final maxDisp = math.max(profile.last, 10.0);
    final curvePath = Path();
    final pointPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < profile.length; i++) {
      final depthRatio = i / (profile.length - 1);
      final y = size.height * (1.0 - depthRatio); // Bottom to top
      final xRatio = (profile[i] / maxDisp).clamp(0.0, 1.0);
      final x = 45.0 + (size.width - 70.0) * xRatio;

      if (i == 0) {
        curvePath.moveTo(x, y);
      } else {
        curvePath.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 3.0, pointPaint);
    }

    final curveLinePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(curvePath, curveLinePaint);
  }

  @override
  bool shouldRepaint(covariant InclinometerProfilePainter oldDelegate) {
    return oldDelegate.profile != profile ||
        oldDelegate.depthM != depthM ||
        oldDelegate.slipPlaneDepthM != slipPlaneDepthM ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Riverbed Bathymetric Echo Sounder Cross-Section Painter
class BathymetricCrossSectionPainter extends CustomPainter {
  final List<BathymetricStation> stations;
  final double waterLevelMsl;
  final double scrubberChainageM;

  const BathymetricCrossSectionPainter({
    required this.stations,
    required this.waterLevelMsl,
    required this.scrubberChainageM,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0B1326);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)),
      bgPaint,
    );

    if (stations.isEmpty) return;

    const minRL = 82.0; // Bottom of diagram RL
    const maxRL = 104.0; // Top of diagram RL
    const minCh = 0.0;
    const maxCh = 450.0;

    double xFromCh(double ch) => (ch - minCh) / (maxCh - minCh) * size.width;
    double yFromRL(double rl) => size.height * (1.0 - (rl - minRL) / (maxRL - minRL));

    // Water Column
    final waterY = yFromRL(waterLevelMsl);
    final waterPaint = Paint()..color = const Color(0x2B0284C7);
    canvas.drawRect(Rect.fromLTWH(0, waterY, size.width, size.height - waterY), waterPaint);

    final waterLinePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, waterY), Offset(size.width, waterY), waterLinePaint);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: 'Water Surface (${waterLevelMsl.toStringAsFixed(1)}m MSL)',
      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9, fontWeight: FontWeight.bold),
    );
    tp.layout();
    tp.paint(canvas, Offset(8, waterY - 14));

    // Riverbed Path & Soil Body
    final bedPath = Path();
    final pipePath = Path();
    final docDeficitPath = Path();

    bedPath.moveTo(0, size.height);
    for (int i = 0; i < stations.length; i++) {
      final x = xFromCh(stations[i].chainageM);
      final y = yFromRL(stations[i].bedElevationRlm);
      if (i == 0) {
        bedPath.lineTo(x, y);
      } else {
        bedPath.lineTo(x, y);
      }
    }
    bedPath.lineTo(size.width, size.height);
    bedPath.close();

    // Draw Soil fill below bed
    final soilPaint = Paint()..color = const Color(0xFF1E2E5C);
    canvas.drawPath(bedPath, soilPaint);

    // Riverbed Stroke
    final bedStrokePaint = Paint()
      ..color = const Color(0xFFFFB95F)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final bedLinePath = Path();
    for (int i = 0; i < stations.length; i++) {
      final x = xFromCh(stations[i].chainageM);
      final y = yFromRL(stations[i].bedElevationRlm);
      if (i == 0) {
        bedLinePath.moveTo(x, y);
      } else {
        bedLinePath.lineTo(x, y);
      }
    }
    canvas.drawPath(bedLinePath, bedStrokePaint);

    // Buried Pipeline Path
    for (int i = 0; i < stations.length; i++) {
      final x = xFromCh(stations[i].chainageM);
      final y = yFromRL(stations[i].pipeTopElevationRlm);
      if (i == 0) {
        pipePath.moveTo(x, y);
      } else {
        pipePath.lineTo(x, y);
      }
    }

    final pipePaint = Paint()
      ..color = const Color(0xFF4EDEA3)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(pipePath, pipePaint);

    // 2.5m Depth of Cover Warning Line (Dotted / Red)
    final cover25Path = Path();
    for (int i = 0; i < stations.length; i++) {
      final x = xFromCh(stations[i].chainageM);
      final y = yFromRL(stations[i].pipeTopElevationRlm + 2.5); // 2.5m above top of pipe
      if (i == 0) {
        cover25Path.moveTo(x, y);
      } else {
        cover25Path.lineTo(x, y);
      }
    }

    final cover25Paint = Paint()
      ..color = const Color(0xFFF43F5E)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(cover25Path, cover25Paint);

    // Highlight Scour Deficit Area (where bed is below 2.5m line)
    // Between Ch. 240 and 310
    final xScour1 = xFromCh(240.0);
    final xScour2 = xFromCh(310.0);
    final yBedScour = yFromRL(86.80);

    docDeficitPath.moveTo(xScour1, yFromRL(88.30));
    docDeficitPath.lineTo(xFromCh(275.0), yBedScour);
    docDeficitPath.lineTo(xScour2, yFromRL(88.10));
    docDeficitPath.lineTo(xScour2, yFromRL(85.80 + 2.5));
    docDeficitPath.lineTo(xFromCh(275.0), yFromRL(84.88 + 2.5));
    docDeficitPath.lineTo(xScour1, yFromRL(85.50 + 2.5));
    docDeficitPath.close();

    final scourHoleFill = Paint()..color = const Color(0x44F43F5E);
    canvas.drawPath(docDeficitPath, scourHoleFill);

    tp.text = const TextSpan(
      text: 'SCOUR HOLE (1.92m DOC)',
      style: TextStyle(color: Color(0xFFF43F5E), fontSize: 8, fontWeight: FontWeight.bold),
    );
    tp.layout();
    tp.paint(canvas, Offset(xFromCh(275.0) - tp.width / 2, yBedScour - 14));

    // Scrubber Line
    final scrubX = xFromCh(scrubberChainageM);
    final scrubPaint = Paint()
      ..color = const Color(0xFFFFB95F)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(scrubX, 0), Offset(scrubX, size.height), scrubPaint);

    canvas.drawCircle(Offset(scrubX, yFromRL(95.0)), 4.0, Paint()..color = const Color(0xFFFFB95F));
  }

  @override
  bool shouldRepaint(covariant BathymetricCrossSectionPainter oldDelegate) {
    return oldDelegate.stations != stations ||
        oldDelegate.waterLevelMsl != waterLevelMsl ||
        oldDelegate.scrubberChainageM != scrubberChainageM;
  }
}

/// Seismic Waveform Oscillogram Painter
class SeismicWaveformPainter extends CustomPainter {
  final bool isSimulated;
  final double pgaG;

  const SeismicWaveformPainter({
    required this.isSimulated,
    required this.pgaG,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0F1A36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)),
      bgPaint,
    );

    // Center Zero Line
    final midY = size.height / 2;
    final centerPaint = Paint()
      ..color = const Color(0xFF1E2E5C)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), centerPaint);

    // Draw 3 Component Waveforms: X (Cyan), Y (Amber), Z (Purple)
    _drawComponentWave(
      canvas: canvas,
      size: size,
      color: const Color(0xFF38BDF8),
      amplitudeScale: isSimulated ? 45.0 : 12.0,
      freqMultiplier: 1.0,
      phaseOffset: 0.0,
      midY: midY,
    );

    _drawComponentWave(
      canvas: canvas,
      size: size,
      color: const Color(0xFFFFB95F),
      amplitudeScale: isSimulated ? 38.0 : 9.5,
      freqMultiplier: 1.3,
      phaseOffset: 1.2,
      midY: midY,
    );

    _drawComponentWave(
      canvas: canvas,
      size: size,
      color: const Color(0xFFC084FC),
      amplitudeScale: isSimulated ? 26.0 : 6.0,
      freqMultiplier: 1.8,
      phaseOffset: 2.4,
      midY: midY,
    );
  }

  void _drawComponentWave({
    required Canvas canvas,
    required Size size,
    required Color color,
    required double amplitudeScale,
    required double freqMultiplier,
    required double phaseOffset,
    required double midY,
  }) {
    final path = Path();
    final wavePaint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final steps = size.width.toInt();
    for (int i = 0; i < steps; i++) {
      final t = (i / size.width) * 20.0 * freqMultiplier + phaseOffset;
      // Synthesized seismogram packet
      final envelope = isSimulated
          ? math.exp(-math.pow((i - size.width * 0.45) / (size.width * 0.25), 2))
          : 0.7;
      final noise = math.sin(t * 3.7) * 0.3 + math.sin(t * 1.2) * 0.7;
      final y = midY + noise * envelope * amplitudeScale;

      if (i == 0) {
        path.moveTo(i.toDouble(), y);
      } else {
        path.lineTo(i.toDouble(), y);
      }
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant SeismicWaveformPainter oldDelegate) {
    return oldDelegate.isSimulated != isSimulated || oldDelegate.pgaG != pgaG;
  }
}
