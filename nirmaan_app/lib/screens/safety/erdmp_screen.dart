import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';

// ============================================================================
// ENUMS & DATA MODELS FOR PNGRB ERDMP & OISD-GDN-166 DISASTER MANAGEMENT
// ============================================================================

/// 3-Tier Emergency Classification per PNGRB ERDMP Regulations & OISD-GDN-166
enum EmergencyTier {
  level1(
    levelNumber: 1,
    title: 'LEVEL 1: LOCAL SITE INCIDENT',
    subtitle: 'Contained within facility battery limit / site boundary',
    description:
        'Incident capable of being dealt with by on-site emergency controller (OEC) using internal resources. Localized leak, flange packing blowout, small trench flash fire extinguished immediately.',
    regulatoryLead: 'On-Site Emergency Controller (OEC) / Shift In-Charge',
    primaryColor: Color(0xFFF59E0B), // Industrial Amber
    badgeText: 'TIER-1 LOCAL',
    icon: Icons.shield_rounded,
    alertTone: 'Intermittent Wailing Siren (2 min)',
  ),
  level2(
    levelNumber: 2,
    title: 'LEVEL 2: OFF-SITE ZONAL INCIDENT',
    subtitle: 'Escalated beyond site battery limit into Pipeline ROW / Buffer Zone',
    description:
        'Incident requiring activation of Off-site Emergency Controller and external mutual aid. Uncontrolled hydrocarbon vapor release, fire with radiation >4.75 kW/m² at boundary, potential community impact within 500m.',
    regulatoryLead: 'Off-site Emergency Controller (GM Ops / Asset Head) + DC Dibrugarh',
    primaryColor: Color(0xFFF97316), // High-Risk Orange
    badgeText: 'TIER-2 OFF-SITE',
    icon: Icons.warning_amber_rounded,
    alertTone: '3-Tone Alternating Siren (3 min)',
  ),
  level3(
    levelNumber: 3,
    title: 'LEVEL 3: MAJOR CATASTROPHE',
    subtitle: 'Regional / National Disaster triggering NDRF & PNGRB Emergency Cell',
    description:
        'Major high-pressure pipeline rupture, large-scale Vapor Cloud Explosion (VCE), toxic H2S release engulfing settlements (>1 km radius). Requires National Disaster Management Authority (NDMA) intervention.',
    regulatoryLead: 'District Collector (Incident Commander) + NDRF 1st Bn + MoP&NG / PNGRB',
    primaryColor: Color(0xFFEF4444), // Critical Red
    badgeText: 'TIER-3 DISASTER',
    icon: Icons.dangerous_rounded,
    alertTone: 'Continuous Disaster Siren (5 min)',
  );

  final int levelNumber;
  final String title;
  final String subtitle;
  final String description;
  final String regulatoryLead;
  final Color primaryColor;
  final String badgeText;
  final IconData icon;
  final String alertTone;

  const EmergencyTier({
    required this.levelNumber,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.regulatoryLead,
    required this.primaryColor,
    required this.badgeText,
    required this.icon,
    required this.alertTone,
  });
}

/// Atmospheric Pasquill-Gifford Stability Class for ALOHA dispersion
enum AtmosphericStability {
  classB('Class B (Unstable)', 'Strong daytime solar insolence, rapid dispersion', 32.0),
  classD('Class D (Neutral)', 'Moderate wind / overcast sky, standard dispersion', 22.0),
  classF('Class F (Stable)', 'Nighttime, calm winds, severe downwind vapor pooling', 14.0);

  final String label;
  final String description;
  final double plumeSpreadDeg;

  const AtmosphericStability(this.label, this.description, this.plumeSpreadDeg);
}

/// Siren Mode Status
enum SirenMode {
  silent('SYSTEM STANDBY', 'No active siren broadcast', Color(0xFF64748B), Icons.volume_off_rounded),
  level1Alert('LEVEL 1 LOCAL SIREN', '2 Min Intermittent Wailing (5s ON / 3s OFF)', Color(0xFFF59E0B), Icons.volume_up_rounded),
  level2Alert('LEVEL 2 OFF-SITE SIREN', '3 Min 3-Tone Alternating Zonal Alarm', Color(0xFFF97316), Icons.campaign_rounded),
  level3Disaster('LEVEL 3 CATASTROPHE SIREN', '5 Min Continuous High-Pitch Evacuation Siren', Color(0xFFEF4444), Icons.crisis_alert_rounded),
  allClear('ALL CLEAR SIREN', '2 Min Continuous Steady Tone (Safe Atmosphere)', Color(0xFF10B981), Icons.check_circle_outline_rounded);

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  const SirenMode(this.title, this.subtitle, this.color, this.icon);
}

/// Automated Emergency Call Tree Node
class CallTreeNodeModel {
  final String id;
  final String agency;
  final String contactPerson;
  final String role;
  final String primaryPhone;
  final String alternatePhone;
  final String radioChannel;
  final int tierPriority; // 1 = immediate, 2 = secondary, 3 = tertiary
  String status; // 'PENDING', 'DISPATCHED', 'ACKNOWLEDGED', 'ON_SCENE'
  String eta;
  int mobilizedPersonnel;
  String latestUpdate;
  DateTime lastContactTime;

  CallTreeNodeModel({
    required this.id,
    required this.agency,
    required this.contactPerson,
    required this.role,
    required this.primaryPhone,
    required this.alternatePhone,
    required this.radioChannel,
    required this.tierPriority,
    this.status = 'PENDING',
    required this.eta,
    required this.mobilizedPersonnel,
    required this.latestUpdate,
    required this.lastContactTime,
  });
}

/// START (Simple Triage and Rapid Treatment) Patient Model
class StartTriagePatient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String triageCategory; // 'RED', 'YELLOW', 'GREEN', 'BLACK'
  final String vitals; // e.g. HR: 122, SpO2: 89%, RR: 32
  final String injurySummary;
  final bool decontaminationDone;
  final String targetHospital;
  final String ambulanceCode;
  final DateTime triageTime;

  StartTriagePatient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.triageCategory,
    required this.vitals,
    required this.injurySummary,
    required this.decontaminationDone,
    required this.targetHospital,
    required this.ambulanceCode,
    required this.triageTime,
  });
}

/// Hospital Capacity & Readiness Model
class HospitalFacilityModel {
  final String name;
  final String designation;
  final double distanceKm;
  final String groundEta;
  final String airEta;
  final String emergencyHotline;
  final String medicalSuperintendent;
  final int traumaIcuBedsTotal;
  int traumaIcuBedsAvailable;
  final int burnUnitBedsTotal;
  int burnUnitBedsAvailable;
  final int oxygenBedsTotal;
  int oxygenBedsAvailable;
  final int bloodUnitsOminus;
  final int bloodUnitsOplus;
  final int bloodUnitsAplus;
  final int alsAmbulanceCount;
  final bool helipadCleared;
  final String mutualAidStatus;

  HospitalFacilityModel({
    required this.name,
    required this.designation,
    required this.distanceKm,
    required this.groundEta,
    required this.airEta,
    required this.emergencyHotline,
    required this.medicalSuperintendent,
    required this.traumaIcuBedsTotal,
    required this.traumaIcuBedsAvailable,
    required this.burnUnitBedsTotal,
    required this.burnUnitBedsAvailable,
    required this.oxygenBedsTotal,
    required this.oxygenBedsAvailable,
    required this.bloodUnitsOminus,
    required this.bloodUnitsOplus,
    required this.bloodUnitsAplus,
    required this.alsAmbulanceCount,
    required this.helipadCleared,
    required this.mutualAidStatus,
  });
}

/// Safe Assembly Point Model
class AssemblyPointModel {
  final String id;
  final String name;
  final String locationCode;
  final String crosswindDirection;
  final int capacity;
  int currentHeadcount;
  final bool isCurrentlySafe;
  final String elevationMeters;
  final String safetyOfficer;

  AssemblyPointModel({
    required this.id,
    required this.name,
    required this.locationCode,
    required this.crosswindDirection,
    required this.capacity,
    required this.currentHeadcount,
    required this.isCurrentlySafe,
    required this.elevationMeters,
    required this.safetyOfficer,
  });
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class ErdmpScreen extends StatefulWidget {
  const ErdmpScreen({super.key});

  @override
  State<ErdmpScreen> createState() => _ErdmpScreenState();
}

class _ErdmpScreenState extends State<ErdmpScreen> with TickerProviderStateMixin {
  // Navigation & View State
  int _selectedTabIndex = 0; // 0: Command & 3-Tier, 1: GIS Plume & Evac, 2: Call Tree & Sirens, 3: Hospital & Triage
  bool _isMockDrillMode = false;

  // Active Incident Data
  EmergencyTier _currentTier = EmergencyTier.level2;
  final String _incidentId = 'OIL-ERDMP-2026-09-003';
  final String _locationName = 'Burhi Dihing River Crossing — KP 42+350';
  final String _chemicalSubstance = 'High-Pressure Natural Gas / H2S Sour Condensate (92% CH4 + 120 ppm H2S)';
  final DateTime _incidentStartTime = DateTime.now().subtract(const Duration(minutes: 46));

  // Siren Controller State
  SirenMode _activeSiren = SirenMode.level2Alert;
  bool _isSirenBroadcasting = true;
  int _sirenRemainingSeconds = 134;
  Timer? _sirenTimer;
  Timer? _telemetryTimer;

  // Meteorological & Plume Simulation Parameters (ALOHA Model)
  double _windDirectionDeg = 45.0; // Wind blowing towards North-East (from SW 225° towards NE 045°)
  double _windSpeedKmh = 14.5;
  AtmosphericStability _stabilityClass = AtmosphericStability.classD;
  double _leakRateKgSec = 140.0; // High rate pipeline release
  bool _showPlumeZones = true;
  bool _showEvacuationRoutes = true;
  bool _showAssemblyPoints = true;

  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _plumeWaveController;
  late AnimationController _sirenAudioController;

  // Automated Call Tree Data Nodes
  late List<CallTreeNodeModel> _callTreeNodes;

  // Hospitals Data
  late List<HospitalFacilityModel> _hospitals;

  // Assembly Points Data
  late List<AssemblyPointModel> _assemblyPoints;

  // START Triage Registered Patients
  late List<StartTriagePatient> _triagePatients;

  // Regulatory Checklist
  final Map<String, bool> _complianceChecklist = {
    'PNGRB ERDMP On-Site Plan updated within 12 months': true,
    'OISD-GDN-166 Incident Command System (ICS) activated': true,
    'Mutual Aid Agreement active with Numaligarh & BCPL': true,
    'Dual Wind Socks calibrated at North & South Valve Stations': true,
    'SCBA Breathing Apparatus (45 min) checked (32 sets)': true,
    'Automated ESDV Isolation verified (VS-02 & VS-03 CLOSED)': true,
    'District Collector & SDM Dibrugarh formally notified': true,
    'Public Siren & Geo-fence broadcast triggered (420 users)': true,
  };

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _plumeWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _sirenAudioController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _initCallTreeData();
    _initHospitalData();
    _initAssemblyPointData();
    _initTriageData();
    _startSirenCountdown();
  }

  @override
  void dispose() {
    _sirenTimer?.cancel();
    _telemetryTimer?.cancel();
    _pulseController.dispose();
    _plumeWaveController.dispose();
    _sirenAudioController.dispose();
    super.dispose();
  }

  void _startSirenCountdown() {
    _sirenTimer?.cancel();
    _sirenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_isSirenBroadcasting && _sirenRemainingSeconds > 0) {
        setState(() {
          _sirenRemainingSeconds--;
        });
      } else if (_sirenRemainingSeconds <= 0 && _isSirenBroadcasting) {
        setState(() {
          _isSirenBroadcasting = false;
        });
      }
    });
  }

  void _initCallTreeData() {
    _callTreeNodes = [
      CallTreeNodeModel(
        id: 'CT-01',
        agency: 'OIL Disaster Management Room (DMR)',
        contactPerson: 'Er. B. K. Sarmah (CGM Pipelines)',
        role: 'Chief Incident Controller / OEC',
        primaryPhone: '+91-374-280-2222',
        alternatePhone: '+91-374-280-1011',
        radioChannel: 'OIL VHF Ch 01 (156.050 MHz)',
        tierPriority: 1,
        status: 'ON_SCENE',
        eta: 'ON SITE',
        mobilizedPersonnel: 18,
        latestUpdate: 'Emergency Operations Centre (EOC) Duliajan activated. Line isolated between VS-02 and VS-03.',
        lastContactTime: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      CallTreeNodeModel(
        id: 'CT-02',
        agency: 'NDRF 1st Battalion (Patgaon, Guwahati)',
        contactPerson: 'Commandant S. Thakur',
        role: 'CBRN & Hazmat Search/Rescue Lead',
        primaryPhone: '+91-361-284-9005',
        alternatePhone: '+91-361-284-9008',
        radioChannel: 'NDMA Tactical 1',
        tierPriority: 1,
        status: 'DISPATCHED',
        eta: '1h 45m',
        mobilizedPersonnel: 45,
        latestUpdate: 'Hazmat Deep Reconnaissance unit en route via specialized convoy with heavy SCBA resupply.',
        lastContactTime: DateTime.now().subtract(const Duration(minutes: 9)),
      ),
      CallTreeNodeModel(
        id: 'CT-03',
        agency: 'District Collector & DDMA Dibrugarh',
        contactPerson: 'B. Pegu, IAS (District Collector)',
        role: 'Off-site Statutory Commander',
        primaryPhone: '+91-373-231-6540',
        alternatePhone: '+91-373-231-6541',
        radioChannel: 'Police VHF Ch 04',
        tierPriority: 1,
        status: 'ACKNOWLEDGED',
        eta: 'COORDINATING',
        mobilizedPersonnel: 32,
        latestUpdate: 'Section 144 CrPC perimeter enforced on NH-37 connector. Evacuation buses dispatched to Borbil Village.',
        lastContactTime: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      CallTreeNodeModel(
        id: 'CT-04',
        agency: 'OIL Central Fire Service & State Fire',
        contactPerson: 'Divisional Fire Officer N. Gogoi',
        role: 'Fire Hazard & Foam Suppression Lead',
        primaryPhone: '+91-374-280-2101',
        alternatePhone: '+91-94350-12845',
        radioChannel: 'Fire Net UHF 450.250 MHz',
        tierPriority: 1,
        status: 'ON_SCENE',
        eta: 'ON SITE',
        mobilizedPersonnel: 28,
        latestUpdate: '4 High-Capacity Foam Tenders deployed. Water curtain established to knock down gas plume.',
        lastContactTime: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      CallTreeNodeModel(
        id: 'CT-05',
        agency: 'Mutual Aid Partners (NRL / BCPL / IOCL)',
        contactPerson: 'Er. A. K. Baruah (Mutual Aid Coordinator)',
        role: 'Hydrocarbon Zonal Mutual Support',
        primaryPhone: '+91-3770-265-400',
        alternatePhone: '+91-373-291-4600',
        radioChannel: 'Mutual Aid Net 02',
        tierPriority: 2,
        status: 'DISPATCHED',
        eta: '35 min',
        mobilizedPersonnel: 16,
        latestUpdate: 'BCPL Lepetkata Nitrogen purging truck & 10,000L AFFF foam concentrate tanker en route.',
        lastContactTime: DateTime.now().subtract(const Duration(minutes: 16)),
      ),
      CallTreeNodeModel(
        id: 'CT-06',
        agency: 'Assam Police Control & SP Dibrugarh',
        contactPerson: 'Superintendent of Police',
        role: 'Perimeter Cordon & Evacuation Route Security',
        primaryPhone: '+91-373-232-4424',
        alternatePhone: '+91-374-280-2233',
        radioChannel: 'Police Repeater Ch 01',
        tierPriority: 2,
        status: 'ON_SCENE',
        eta: 'ON SITE',
        mobilizedPersonnel: 40,
        latestUpdate: '1.5 km sterile perimeter sealed. All civilian vehicular transit diverted via Tengakhat.',
        lastContactTime: DateTime.now().subtract(const Duration(minutes: 7)),
      ),
    ];
  }

  void _initHospitalData() {
    _hospitals = [
      HospitalFacilityModel(
        name: 'OIL Hospital Duliajan',
        designation: 'Company Primary Base Hospital & Trauma Center',
        distanceKm: 6.2,
        groundEta: '8 - 10 min',
        airEta: '3 min',
        emergencyHotline: '+91-374-280-2444',
        medicalSuperintendent: 'Dr. P. K. Baruah, CMO',
        traumaIcuBedsTotal: 12,
        traumaIcuBedsAvailable: 8,
        burnUnitBedsTotal: 6,
        burnUnitBedsAvailable: 4,
        oxygenBedsTotal: 40,
        oxygenBedsAvailable: 34,
        bloodUnitsOminus: 6,
        bloodUnitsOplus: 22,
        bloodUnitsAplus: 18,
        alsAmbulanceCount: 3,
        helipadCleared: true,
        mutualAidStatus: 'PRIMARY FACILITY ACTIVE',
      ),
      HospitalFacilityModel(
        name: 'Assam Medical College & Hospital (AMCH) Dibrugarh',
        designation: 'Tertiary Apex Level-1 Trauma & Burn Center',
        distanceKm: 48.0,
        groundEta: '35 - 40 min',
        airEta: '12 min (Helivac)',
        emergencyHotline: '+91-373-230-0080',
        medicalSuperintendent: 'Prof. Dr. H. Saikia, Superintendent',
        traumaIcuBedsTotal: 25,
        traumaIcuBedsAvailable: 18,
        burnUnitBedsTotal: 15,
        burnUnitBedsAvailable: 9,
        oxygenBedsTotal: 120,
        oxygenBedsAvailable: 86,
        bloodUnitsOminus: 14,
        bloodUnitsOplus: 48,
        bloodUnitsAplus: 36,
        alsAmbulanceCount: 6,
        helipadCleared: true,
        mutualAidStatus: 'TERTIARY REFERRAL STANDBY',
      ),
    ];
  }

  void _initAssemblyPointData() {
    _assemblyPoints = [
      AssemblyPointModel(
        id: 'AP-A',
        name: 'Assembly Point A — North Ridge Helipad',
        locationCode: 'Sector 01 (Crosswind Northwest)',
        crosswindDirection: '315° NW (Upwind Safe Zone)',
        capacity: 150,
        currentHeadcount: 58,
        isCurrentlySafe: true,
        elevationMeters: '+42m AMSL',
        safetyOfficer: 'R. K. Hazarika (Sr. HSE Officer)',
      ),
      AssemblyPointModel(
        id: 'AP-B',
        name: 'Assembly Point B — Admin Gate #2 Plaza',
        locationCode: 'Sector 02 (Crosswind West)',
        crosswindDirection: '270° W (Crosswind Safe Zone)',
        capacity: 100,
        currentHeadcount: 43,
        isCurrentlySafe: true,
        elevationMeters: '+35m AMSL',
        safetyOfficer: 'M. Bordoloi (Safety Inspector)',
      ),
      AssemblyPointModel(
        id: 'AP-C',
        name: 'Assembly Point C — Pipeline ROW Camp 4',
        locationCode: 'Sector 04 (Downwind East)',
        crosswindDirection: '045° NE (HAZARDOUS PLUME CONE)',
        capacity: 80,
        currentHeadcount: 0,
        isCurrentlySafe: false, // In the vapor plume footprint!
        elevationMeters: '+22m AMSL',
        safetyOfficer: 'EVACUATED TO POINT A',
      ),
    ];
  }

  void _initTriageData() {
    _triagePatients = [
      StartTriagePatient(
        id: 'TR-101',
        name: 'Ramen Das (Pipeline Fitter)',
        age: 38,
        gender: 'Male',
        triageCategory: 'RED',
        vitals: 'HR: 130 | SpO2: 86% | RR: 34 bpm',
        injurySummary: 'Severe hydrocarbon inhalation & 2nd-degree blast flash burn on upper torso',
        decontaminationDone: true,
        targetHospital: 'OIL Hospital Duliajan (Trauma ICU)',
        ambulanceCode: 'OIL-ALS-01',
        triageTime: DateTime.now().subtract(const Duration(minutes: 24)),
      ),
      StartTriagePatient(
        id: 'TR-102',
        name: 'Tiken Sonowal (Valve Tech)',
        age: 44,
        gender: 'Male',
        triageCategory: 'RED',
        vitals: 'HR: 122 | SpO2: 89% | RR: 28 bpm',
        injurySummary: 'Blast overpressure ear barotrauma & compound tibia fracture from flying debris',
        decontaminationDone: true,
        targetHospital: 'AMCH Dibrugarh (Super-Specialty)',
        ambulanceCode: 'OIL-ALS-02',
        triageTime: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      StartTriagePatient(
        id: 'TR-103',
        name: 'Diganta Borah (Rigger)',
        age: 29,
        gender: 'Male',
        triageCategory: 'YELLOW',
        vitals: 'HR: 96 | SpO2: 96% | RR: 20 bpm',
        injurySummary: 'Right radius-ulna closed fracture sustained during rapid trench ladder egress',
        decontaminationDone: true,
        targetHospital: 'OIL Hospital Duliajan',
        ambulanceCode: 'OIL-BLS-03',
        triageTime: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
      StartTriagePatient(
        id: 'TR-104',
        name: 'S. K. Sharma (Surveyor)',
        age: 51,
        gender: 'Male',
        triageCategory: 'YELLOW',
        vitals: 'HR: 104 | SpO2: 95% | RR: 22 bpm',
        injurySummary: 'Moderate sulfurous H2S eye conjunctival chemical burns; copious eyewash given',
        decontaminationDone: true,
        targetHospital: 'OIL Hospital Duliajan',
        ambulanceCode: 'OIL-BLS-04',
        triageTime: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      StartTriagePatient(
        id: 'TR-105',
        name: 'Anup Phukan (Helper)',
        age: 25,
        gender: 'Male',
        triageCategory: 'GREEN',
        vitals: 'HR: 82 | SpO2: 99% | RR: 16 bpm',
        injurySummary: 'Superficial skin abrasions and anxiety shock; ambulatory, treated at Assembly Point A',
        decontaminationDone: true,
        targetHospital: 'On-Site First Aid Post',
        ambulanceCode: 'N/A (Walking)',
        triageTime: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
    ];
  }

  // ============================================================================
  // USER ACTIONS & PROTOCOLS
  // ============================================================================

  void _handleTierChange(EmergencyTier newTier) {
    if (newTier == _currentTier) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: newTier.primaryColor, width: 2),
        ),
        title: Row(
          children: [
            Icon(newTier.icon, color: newTier.primaryColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ESCALATE TO ${newTier.badgeText}?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Per PNGRB ERDMP Reg. 11 & OISD-GDN-166, escalating to ${newTier.title} triggers mandatory statutory protocols:',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: newTier.primaryColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Incident Commander: ${newTier.regulatoryLead}',
                    style: TextStyle(color: newTier.primaryColor, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Siren Pattern: ${newTier.alertTone}',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    newTier.description,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: newTier.primaryColor),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _currentTier = newTier;
                if (newTier == EmergencyTier.level1) {
                  _activeSiren = SirenMode.level1Alert;
                  _sirenRemainingSeconds = 120;
                } else if (newTier == EmergencyTier.level2) {
                  _activeSiren = SirenMode.level2Alert;
                  _sirenRemainingSeconds = 180;
                } else {
                  _activeSiren = SirenMode.level3Disaster;
                  _sirenRemainingSeconds = 300;
                }
                _isSirenBroadcasting = true;
              });
              _startSirenCountdown();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: newTier.primaryColor,
                  content: Text(
                    'EMERGENCY CLASSIFICATION UPDATED: ${newTier.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              );
            },
            child: const Text('AUTHORIZE ESCALATION', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _triggerSirenMode(SirenMode mode) {
    setState(() {
      _activeSiren = mode;
      _isSirenBroadcasting = mode != SirenMode.silent;
      if (mode == SirenMode.level1Alert) {
        _sirenRemainingSeconds = 120;
      } else if (mode == SirenMode.level2Alert) {
        _sirenRemainingSeconds = 180;
      } else if (mode == SirenMode.level3Disaster) {
        _sirenRemainingSeconds = 300;
      } else if (mode == SirenMode.allClear) {
        _sirenRemainingSeconds = 120;
      } else {
        _sirenRemainingSeconds = 0;
      }
    });
    _startSirenCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: mode.color,
        content: Text('SIREN BROADCAST ACTIVATED: ${mode.title}'),
      ),
    );
  }

  void _broadcastCallTreeNode(CallTreeNodeModel node) {
    setState(() {
      node.status = 'DISPATCHED';
      node.lastContactTime = DateTime.now();
      node.latestUpdate = 'Urgent priority dispatch beacon acknowledged. Unit mobilized.';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primary,
        content: Text('ALERT DISPATCHED TO: ${node.agency} (${node.radioChannel})'),
      ),
    );
  }

  void _broadcastAllCallTree() {
    setState(() {
      for (final node in _callTreeNodes) {
        if (node.status == 'PENDING') {
          node.status = 'DISPATCHED';
          node.lastContactTime = DateTime.now();
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFFEF4444),
        content: Text('MASS CALL TREE DISPATCH TRIGGERED: 6 Agencies alerted via IVR & VHF'),
      ),
    );
  }

  void _showAddTriageDialog() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final injuryCtrl = TextEditingController();
    String selectedCat = 'YELLOW';
    String selectedHosp = 'OIL Hospital Duliajan';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NEW CASUALTY START TRIAGE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Simple Triage and Rapid Treatment (START) classification per OISD-GDN-166',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              // Category Selector
              Row(
                children: [
                  _triageTagOption('RED', 'Immediate (P1)', const Color(0xFFEF4444), selectedCat, (val) {
                    setModalState(() => selectedCat = val);
                  }),
                  const SizedBox(width: 8),
                  _triageTagOption('YELLOW', 'Delayed (P2)', const Color(0xFFF59E0B), selectedCat, (val) {
                    setModalState(() => selectedCat = val);
                  }),
                  const SizedBox(width: 8),
                  _triageTagOption('GREEN', 'Minor (P3)', const Color(0xFF10B981), selectedCat, (val) {
                    setModalState(() => selectedCat = val);
                  }),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Casualty Name / ID Badge',
                  prefixIcon: Icon(Icons.person, color: AppTheme.primaryLight, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ageCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Age (Years)',
                        prefixIcon: Icon(Icons.calendar_today, color: AppTheme.primaryLight, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedHosp,
                      dropdownColor: AppTheme.surfaceCard,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                      decoration: const InputDecoration(labelText: 'Destination Facility'),
                      items: const [
                        DropdownMenuItem(value: 'OIL Hospital Duliajan', child: Text('OIL Hosp Duliajan')),
                        DropdownMenuItem(value: 'AMCH Dibrugarh', child: Text('AMCH Dibrugarh')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedHosp = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: injuryCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Injuries / Vitals / Inhalation Symptoms',
                  hintText: 'e.g. SpO2 91%, respiratory distress, chemical contact burn',
                  prefixIcon: Icon(Icons.medical_services_rounded, color: AppTheme.primaryLight, size: 18),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedCat == 'RED'
                        ? const Color(0xFFEF4444)
                        : selectedCat == 'YELLOW'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.assignment_turned_in_rounded),
                  label: const Text('SUBMIT CASUALTY TO MANIFEST', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final name = nameCtrl.text.trim().isEmpty ? 'Unknown Casualty' : nameCtrl.text.trim();
                    final age = int.tryParse(ageCtrl.text.trim()) ?? 32;
                    final inj = injuryCtrl.text.trim().isEmpty ? 'Minor trauma & gas inhalation under observation' : injuryCtrl.text.trim();

                    setState(() {
                      _triagePatients.insert(
                        0,
                        StartTriagePatient(
                          id: 'TR-${100 + _triagePatients.length + 1}',
                          name: name,
                          age: age,
                          gender: 'Male',
                          triageCategory: selectedCat,
                          vitals: selectedCat == 'RED' ? 'HR: 128 | SpO2: 88% | RR: 32' : 'HR: 94 | SpO2: 97% | RR: 20',
                          injurySummary: inj,
                          decontaminationDone: true,
                          targetHospital: selectedHosp,
                          ambulanceCode: selectedCat == 'RED' ? 'OIL-ALS-03' : 'OIL-BLS-02',
                          triageTime: DateTime.now(),
                        ),
                      );
                    });
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: selectedCat == 'RED' ? const Color(0xFFEF4444) : AppTheme.primary,
                        content: Text('Casualty $name logged as [$selectedCat] priority'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _triageTagOption(String tag, String label, Color color, String selected, ValueChanged<String> onSelect) {
    final isSel = selected == tag;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(tag),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? color.withValues(alpha: 0.25) : AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSel ? color : AppTheme.border, width: isSel ? 2 : 1),
          ),
          child: Column(
            children: [
              Text(
                tag,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSel ? Colors.white : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // MAIN BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildActiveIncidentBanner(),
          _buildSirenLiveTicker(),
          _buildCustomTabBar(),
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildCommandAndClassificationTab(),
                _buildGisPlumeEvacuationTab(),
                _buildCallTreeAndSirensTab(),
                _buildHospitalsAndTriageTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildQuickActionBar(),
    );
  }

  // ============================================================================
  // APP BAR & HEADER BANNERS
  // ============================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 3,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'DISASTER MANAGEMENT & ERDMP',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _isMockDrillMode ? const Color(0xFF38BDF8).withValues(alpha: 0.2) : const Color(0xFFEF4444).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _isMockDrillMode ? const Color(0xFF38BDF8) : const Color(0xFFEF4444),
                  ),
                ),
                child: Text(
                  _isMockDrillMode ? 'MOCK DRILL' : 'LIVE EMERGENCY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: _isMockDrillMode ? const Color(0xFF38BDF8) : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'PNGRB ERDMP Reg. 2020 | OISD-GDN-166 | Oil India Duliajan Asset',
            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Toggle Mock Drill / Live Mode',
          icon: Icon(
            _isMockDrillMode ? Icons.school_rounded : Icons.flash_on_rounded,
            color: _isMockDrillMode ? const Color(0xFF38BDF8) : const Color(0xFFFFB95F),
          ),
          onPressed: () {
            setState(() {
              _isMockDrillMode = !_isMockDrillMode;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: _isMockDrillMode ? const Color(0xFF0284C7) : const Color(0xFFEF4444),
                content: Text(
                  _isMockDrillMode ? 'TRAINING & MOCK DRILL MODE ACTIVE' : 'LIVE STATUTORY DISASTER RESPONSE ACTIVE',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveIncidentBanner() {
    final duration = DateTime.now().difference(_incidentStartTime);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _currentTier.primaryColor.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: _currentTier.primaryColor.withValues(alpha: 0.4), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentTier.primaryColor.withValues(alpha: 0.2 + (_pulseController.value * 0.3)),
                  border: Border.all(color: _currentTier.primaryColor, width: 2),
                ),
                child: Icon(_currentTier.icon, color: _currentTier.primaryColor, size: 20),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _currentTier.badgeText,
                      style: TextStyle(
                        color: _currentTier.primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $_incidentId',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _locationName,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  _chemicalSubstance,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TIME ELAPSED', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  '$hours:$minutes:$seconds',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSirenLiveTicker() {
    if (_activeSiren == SirenMode.silent) return const SizedBox.shrink();

    return Container(
      color: _activeSiren.color.withValues(alpha: 0.18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _sirenAudioController,
            builder: (context, child) {
              return Row(
                children: List.generate(4, (index) {
                  final height = 6.0 + (index * 3.5 * _sirenAudioController.value);
                  return Container(
                    width: 3,
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: _activeSiren.color,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_activeSiren.title}: ${_activeSiren.subtitle}',
              style: TextStyle(
                color: _activeSiren.color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_sirenRemainingSeconds}s REMAINING',
            style: TextStyle(
              color: _activeSiren.color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              setState(() {
                _isSirenBroadcasting = !_isSirenBroadcasting;
              });
            },
            child: Icon(
              _isSirenBroadcasting ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              color: _activeSiren.color,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      color: AppTheme.surface,
      child: Row(
        children: [
          _tabButton(0, Icons.admin_panel_settings_rounded, '3-Tier Command'),
          _tabButton(1, Icons.map_rounded, 'GIS Plume Map'),
          _tabButton(2, Icons.phone_in_talk_rounded, 'Call Tree & Siren'),
          _tabButton(3, Icons.local_hospital_rounded, 'Hospital & Triage'),
        ],
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF38BDF8) : AppTheme.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 1: INCIDENT COMMAND & 3-TIER CLASSIFICATION
  // ============================================================================

  Widget _buildCommandAndClassificationTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClassificationTierCards(),
          const SizedBox(height: 16),
          _buildIncidentCommandDetailsCard(),
          const SizedBox(height: 16),
          _buildRegulatoryChecklistCard(),
          const SizedBox(height: 16),
          _buildStatutoryNotificationSummaryCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildClassificationTierCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PNGRB / OISD-GDN-166 3-TIER EMERGENCY SEVERITY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ...EmergencyTier.values.map((tier) {
          final isSelected = tier == _currentTier;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSelected ? tier.primaryColor.withValues(alpha: 0.14) : AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? tier.primaryColor : AppTheme.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _handleTierChange(tier),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: tier.primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(tier.icon, color: tier.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      tier.title,
                                      style: TextStyle(
                                        color: isSelected ? tier.primaryColor : AppTheme.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: tier.primaryColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'ACTIVE',
                                          style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tier.subtitle,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? tier.primaryColor : AppTheme.textMuted,
                                width: isSelected ? 5 : 2,
                              ),
                              color: isSelected ? tier.primaryColor : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tier.description,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_pin_rounded, color: AppTheme.primaryLight, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Command: ${tier.regulatoryLead}',
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildIncidentCommandDetailsCard() {
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
            children: [
              const Icon(Icons.hub_rounded, color: Color(0xFF38BDF8), size: 20),
              const SizedBox(width: 8),
              const Text(
                'INCIDENT COMMAND SYSTEM (ICS) STRUCTURE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: const Text('EOC ONLINE', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _commandRoleRow('Chief Incident Controller (CIC)', 'Er. B. K. Sarmah (CGM Pipelines)', 'OIL EOC Duliajan', Icons.military_tech_rounded),
          const Divider(color: AppTheme.border, height: 18),
          _commandRoleRow('On-Site Emergency Controller (OEC)', 'Er. D. K. Gogoi (Chief Manager Ops)', 'Mobile Command Post (KP 42)', Icons.engineering_rounded),
          const Divider(color: AppTheme.border, height: 18),
          _commandRoleRow('Off-Site Emergency Lead', 'B. Pegu, IAS (DC Dibrugarh)', 'District EOC Dibrugarh', Icons.account_balance_rounded),
          const Divider(color: AppTheme.border, height: 18),
          _commandRoleRow('Safety & Hazmat Specialist', 'S. Gogoi (Sr. HSE Manager)', 'On-Site Hazmat Team', Icons.sanitizer_rounded),
          const Divider(color: AppTheme.border, height: 18),
          _commandRoleRow('Medical Evacuation Coordinator', 'Dr. P. K. Baruah (CMO OIL Hospital)', 'OIL Hospital Duliajan', Icons.medical_services_rounded),
        ],
      ),
    );
  }

  Widget _commandRoleRow(String role, String name, String location, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF38BDF8)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Text(location, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildRegulatoryChecklistCard() {
    int passedCount = _complianceChecklist.values.where((v) => v).length;
    double compliancePct = passedCount / _complianceChecklist.length;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.rule_rounded, color: Color(0xFFFFB95F), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'PNGRB ERDMP STATUTORY AUDIT CHECKLIST',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Text(
                '${(compliancePct * 100).toInt()}% READY',
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: compliancePct,
            backgroundColor: AppTheme.surface,
            color: const Color(0xFF10B981),
            minHeight: 6,
          ),
          const SizedBox(height: 12),
          ..._complianceChecklist.entries.map((entry) {
            return InkWell(
              onTap: () {
                setState(() {
                  _complianceChecklist[entry.key] = !entry.value;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      entry.value ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: entry.value ? const Color(0xFF10B981) : AppTheme.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 11,
                          color: entry.value ? AppTheme.textPrimary : AppTheme.textMuted,
                          fontWeight: entry.value ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatutoryNotificationSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUTORY ESCALATION TIMELINES (PNGRB REG. 11)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF38BDF8)),
          ),
          const SizedBox(height: 6),
          const Text(
            '• Immediate Verbal Alert to PNGRB & MoP&NG: Within 2 Hours of Level 2/3 declaration.\n'
            '• Preliminary Written Flash Report (Form-I): Within 24 Hours.\n'
            '• Detailed Incident Investigation & Root Cause Report (Form-II): Within 30 Days.\n'
            '• District Magistrate & DDMA updates sent at 60-minute intervals until All-Clear.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.45),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: LIVE GIS PLUME DISPERSION & EVACUATION MAP (ALOHA/CAMEO)
  // ============================================================================

  Widget _buildGisPlumeEvacuationTab() {
    return Column(
      children: [
        _buildPlumeWeatherToolbar(),
        Expanded(
          child: Stack(
            children: [
              // Interactive / Custom Canvas Map
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF070D1A),
                  child: AnimatedBuilder(
                    animation: _plumeWaveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: AlohaPlumeMapPainter(
                          windDirectionDeg: _windDirectionDeg,
                          windSpeedKmh: _windSpeedKmh,
                          plumeSpreadDeg: _stabilityClass.plumeSpreadDeg,
                          leakRateKgSec: _leakRateKgSec,
                          waveProgress: _plumeWaveController.value,
                          pulseProgress: _pulseController.value,
                          showPlumes: _showPlumeZones,
                          showEvacRoutes: _showEvacuationRoutes,
                          showAssemblyPoints: _showAssemblyPoints,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Map Top Overlay: Hazard Footprint Legend
              Positioned(
                top: 12,
                left: 12,
                child: _buildPlumeHazardLegend(),
              ),
              // Map Top Right: Wind Sock & Meteorological Card
              Positioned(
                top: 12,
                right: 12,
                child: _buildWindCompassWidget(),
              ),
              // Map Bottom Overlay: Assembly Points Live Status
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: _buildAssemblyPointsMiniCards(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlumeWeatherToolbar() {
    return Container(
      color: AppTheme.surfaceCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.air_rounded, color: Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 8),
              Text(
                'WIND: ${_windSpeedKmh.toStringAsFixed(1)} km/h | DIR: ${_windDirectionDeg.toInt()}° (${_getCardinalDirection(_windDirectionDeg)})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const Spacer(),
              PopupMenuButton<AtmosphericStability>(
                color: AppTheme.surfaceCard,
                initialValue: _stabilityClass,
                onSelected: (val) => setState(() => _stabilityClass = val),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _stabilityClass.label,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFF38BDF8), size: 16),
                    ],
                  ),
                ),
                itemBuilder: (ctx) => AtmosphericStability.values.map((st) {
                  return PopupMenuItem(
                    value: st,
                    child: Text(st.label, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('WIND DIRECTION (ALOHA):', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  ),
                  child: Slider(
                    value: _windDirectionDeg,
                    min: 0.0,
                    max: 360.0,
                    activeColor: const Color(0xFF38BDF8),
                    inactiveColor: AppTheme.surface,
                    onChanged: (val) => setState(() => _windDirectionDeg = val),
                  ),
                ),
              ),
              Text('${_windDirectionDeg.toInt()}°', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('WIND SPEED:', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  ),
                  child: Slider(
                    value: _windSpeedKmh,
                    min: 5.0,
                    max: 60.0,
                    activeColor: const Color(0xFF4EDEA3),
                    inactiveColor: AppTheme.surface,
                    onChanged: (val) => setState(() => _windSpeedKmh = val),
                  ),
                ),
              ),
              Text('${_windSpeedKmh.toStringAsFixed(1)} km/h', style: const TextStyle(color: Color(0xFF4EDEA3), fontSize: 10.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('LEAK SEVERITY:', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  ),
                  child: Slider(
                    value: _leakRateKgSec,
                    min: 20.0,
                    max: 300.0,
                    activeColor: const Color(0xFFEF4444),
                    inactiveColor: AppTheme.surface,
                    onChanged: (val) => setState(() => _leakRateKgSec = val),
                  ),
                ),
              ),
              Text('${_leakRateKgSec.toInt()} kg/s', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 10.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          // GIS Layer Toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _gisLayerChip('PLUME CONES', _showPlumeZones, const Color(0xFFF97316), () {
                setState(() => _showPlumeZones = !_showPlumeZones);
              }),
              _gisLayerChip('EVAC ROUTES', _showEvacuationRoutes, const Color(0xFF10B981), () {
                setState(() => _showEvacuationRoutes = !_showEvacuationRoutes);
              }),
              _gisLayerChip('MUSTER POINTS', _showAssemblyPoints, const Color(0xFF38BDF8), () {
                setState(() => _showAssemblyPoints = !_showAssemblyPoints);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gisLayerChip(String label, bool active, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.2) : AppTheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: active ? color : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 12, color: active ? color : AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: active ? color : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCardinalDirection(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'N';
    if (deg >= 22.5 && deg < 67.5) return 'NE';
    if (deg >= 67.5 && deg < 112.5) return 'E';
    if (deg >= 112.5 && deg < 157.5) return 'SE';
    if (deg >= 157.5 && deg < 202.5) return 'S';
    if (deg >= 202.5 && deg < 247.5) return 'SW';
    if (deg >= 247.5 && deg < 292.5) return 'W';
    return 'NW';
  }

  Widget _buildPlumeHazardLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ALOHA CHEMICAL PLUME FOOTPRINT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          _legendItem(const Color(0xFFEF4444), 'THREAT ZONE (ERPG-3 / >60% LFL / 350m)'),
          _legendItem(const Color(0xFFF97316), 'IDLH ZONE (ERPG-2 / >10% LFL / 850m)'),
          _legendItem(const Color(0xFFF59E0B), 'PAC-1 CAUTION (ERPG-1 / Odor / 1800m)'),
          _legendItem(const Color(0xFF10B981), 'SAFE CROSSWIND EVACUATION CORRIDOR'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 8.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildWindCompassWidget() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Transform.rotate(
            angle: (_windDirectionDeg - 180) * (pi / 180),
            child: const Icon(Icons.navigation_rounded, color: Color(0xFF38BDF8), size: 28),
          ),
          const SizedBox(height: 2),
          Text(
            '${_getCardinalDirection(_windDirectionDeg)} ${_windDirectionDeg.toInt()}°',
            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.w900),
          ),
          Text(
            '${_windSpeedKmh.toStringAsFixed(0)} km/h',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildAssemblyPointsMiniCards() {
    int totalMuster = _assemblyPoints.fold(0, (sum, ap) => sum + ap.currentHeadcount);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.95),
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
                'LIVE MUSTER ROLL AT SAFE ASSEMBLY POINTS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textSecondary),
              ),
              Text(
                'ACCOUNTED: $totalMuster / 104 (3 SEARCH & RESCUE ACTIVE)',
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: _assemblyPoints.map((ap) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: ap.isCurrentlySafe ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ap.isCurrentlySafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            ap.isCurrentlySafe ? Icons.check_circle_rounded : Icons.dangerous_rounded,
                            size: 12,
                            color: ap.isCurrentlySafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ap.id,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: ap.isCurrentlySafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ap.currentHeadcount} / ${ap.capacity}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        ap.isCurrentlySafe ? 'SAFE UPWIND' : 'PLUME DANGER',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: ap.isCurrentlySafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: AUTOMATED CALL TREE & SIREN BROADCAST
  // ============================================================================

  Widget _buildCallTreeAndSirensTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSirenMasterControlCard(),
          const SizedBox(height: 16),
          _buildCallTreeHeaderAction(),
          const SizedBox(height: 10),
          ..._callTreeNodes.map((node) => _buildCallTreeNodeCard(node)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSirenMasterControlCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _activeSiren.color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _sirenAudioController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _activeSiren.color.withValues(alpha: 0.2 + (_sirenAudioController.value * 0.3)),
                    ),
                    child: Icon(_activeSiren.icon, color: _activeSiren.color, size: 24),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AUTOMATED EMERGENCY SIREN BROADCAST', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(_activeSiren.title, style: TextStyle(color: _activeSiren.color, fontSize: 14, fontWeight: FontWeight.w900)),
                    Text(_activeSiren.subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Siren Selector Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _sirenButton(SirenMode.level1Alert, 'LEVEL 1 LOCAL (2m)'),
              _sirenButton(SirenMode.level2Alert, 'LEVEL 2 ZONAL (3m)'),
              _sirenButton(SirenMode.level3Disaster, 'LEVEL 3 DISASTER (5m)'),
              _sirenButton(SirenMode.allClear, 'ALL CLEAR (2m)'),
              _sirenButton(SirenMode.silent, 'MUTE / SILENT'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sirenButton(SirenMode mode, String label) {
    final isSel = _activeSiren == mode;
    return InkWell(
      onTap: () => _triggerSirenMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? mode.color.withValues(alpha: 0.25) : AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSel ? mode.color : AppTheme.border, width: isSel ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? mode.color : AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildCallTreeHeaderAction() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'AUTOMATED STATUTORY CALL TREE DISPATCH',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          icon: const Icon(Icons.flash_on_rounded, size: 14),
          label: const Text('DISPATCH ALL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          onPressed: _broadcastAllCallTree,
        ),
      ],
    );
  }

  Widget _buildCallTreeNodeCard(CallTreeNodeModel node) {
    Color statusColor;
    if (node.status == 'ON_SCENE') {
      statusColor = const Color(0xFF10B981);
    } else if (node.status == 'DISPATCHED') {
      statusColor = const Color(0xFF38BDF8);
    } else if (node.status == 'ACKNOWLEDGED') {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFF64748B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  node.id,
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF38BDF8)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.agency, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text('${node.contactPerson} • ${node.role}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  node.status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.primaryLight, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.latestUpdate,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.radio_rounded, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(node.radioChannel, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              const Spacer(),
              Text('ETA: ${node.eta}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.send_rounded, size: 12, color: Color(0xFF38BDF8)),
                label: const Text('DISPATCH', style: TextStyle(fontSize: 10, color: Color(0xFF38BDF8))),
                onPressed: () => _broadcastCallTreeNode(node),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: TRIAGING & HOSPITAL BED MATRIX
  // ============================================================================

  Widget _buildHospitalsAndTriageTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHospitalOverviewCards(),
          const SizedBox(height: 16),
          _buildTriageSummaryHeader(),
          const SizedBox(height: 10),
          ..._triagePatients.map((p) => _buildTriagePatientCard(p)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHospitalOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DEDICATED OIL DISASTER HOSPITAL BED AVAILABILITY',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 10),
        ..._hospitals.map((hosp) {
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF38BDF8), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hosp.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
                          Text(hosp.designation, style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: Text('${hosp.distanceKm} KM (${hosp.groundEta})', style: const TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bed matrix stats
                Row(
                  children: [
                    _bedStatBox('TRAUMA ICU', '${hosp.traumaIcuBedsAvailable}/${hosp.traumaIcuBedsTotal}', const Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    _bedStatBox('BURN UNIT', '${hosp.burnUnitBedsAvailable}/${hosp.burnUnitBedsTotal}', const Color(0xFFF97316)),
                    const SizedBox(width: 8),
                    _bedStatBox('O2 BEDS', '${hosp.oxygenBedsAvailable}/${hosp.oxygenBedsTotal}', const Color(0xFF38BDF8)),
                    const SizedBox(width: 8),
                    _bedStatBox('AMBULANCE', '${hosp.alsAmbulanceCount} ALS', const Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bloodtype_rounded, color: Color(0xFFEF4444), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Blood Reserves: O- (${hosp.bloodUnitsOminus}) | O+ (${hosp.bloodUnitsOplus}) | A+ (${hosp.bloodUnitsAplus})',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Icon(Icons.flight_land_rounded, size: 14, color: hosp.helipadCleared ? const Color(0xFF10B981) : AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        hosp.helipadCleared ? 'HELIPAD OPEN' : 'NO HELIPAD',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: hosp.helipadCleared ? const Color(0xFF10B981) : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _bedStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTriageSummaryHeader() {
    int redCount = _triagePatients.where((p) => p.triageCategory == 'RED').length;
    int yellowCount = _triagePatients.where((p) => p.triageCategory == 'YELLOW').length;
    int greenCount = _triagePatients.where((p) => p.triageCategory == 'GREEN').length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'START CASUALTY TRIAGE MANIFEST',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              'P1: $redCount Red | P2: $yellowCount Yellow | P3: $greenCount Green',
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          icon: const Icon(Icons.add, size: 14),
          label: const Text('LOG CASUALTY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          onPressed: _showAddTriageDialog,
        ),
      ],
    );
  }

  Widget _buildTriagePatientCard(StartTriagePatient patient) {
    Color catColor;
    if (patient.triageCategory == 'RED') {
      catColor = const Color(0xFFEF4444);
    } else if (patient.triageCategory == 'YELLOW') {
      catColor = const Color(0xFFF59E0B);
    } else if (patient.triageCategory == 'GREEN') {
      catColor = const Color(0xFF10B981);
    } else {
      catColor = const Color(0xFF1E293B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: catColor, width: 4),
          top: const BorderSide(color: AppTheme.border),
          right: const BorderSide(color: AppTheme.border),
          bottom: const BorderSide(color: AppTheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRIORITY ${patient.triageCategory}',
                  style: TextStyle(color: catColor, fontWeight: FontWeight.w900, fontSize: 9.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                patient.id,
                style: const TextStyle(fontFamily: 'monospace', color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                DateFormat('HH:mm').format(patient.triageTime),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${patient.name}, ${patient.age} yrs (${patient.gender})',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            patient.injurySummary,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.monitor_heart_rounded, color: Color(0xFF38BDF8), size: 14),
                const SizedBox(width: 6),
                Text(
                  patient.vitals,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    patient.targetHospital,
                    style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // QUICK BOTTOM ACTION BAR
  // ============================================================================

  Widget _buildQuickActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSirenBroadcasting ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(_isSirenBroadcasting ? Icons.volume_up_rounded : Icons.campaign_rounded, size: 18),
                label: Text(
                  _isSirenBroadcasting ? 'SIREN ACTIVE' : 'TRIGGER SIREN',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: () {
                  _triggerSirenMode(_currentTier == EmergencyTier.level3
                      ? SirenMode.level3Disaster
                      : _currentTier == EmergencyTier.level2
                          ? SirenMode.level2Alert
                          : SirenMode.level1Alert);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF38BDF8)),
                ),
                icon: const Icon(Icons.dialpad_rounded, color: Color(0xFF38BDF8), size: 18),
                label: const Text(
                  'CALL TREE (6)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF38BDF8)),
                ),
                onPressed: () => setState(() => _selectedTabIndex = 2),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: IconButton(
                tooltip: 'All-Clear Protocol',
                icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.surfaceCard,
                      title: const Text('ISSUE ALL-CLEAR SIGNAL?', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                      content: const Text(
                        'Per PNGRB ERDMP regulations, All-Clear may only be declared after hydrocarbon gas leak is capped and atmosphere tests <10% LFL and <5 ppm H2S across all sectors.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _triggerSirenMode(SirenMode.allClear);
                          },
                          child: const Text('CONFIRM ALL-CLEAR'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM GIS PAINTER FOR ALOHA CHEMICAL PLUME & EVACUATION ROUTES
// ============================================================================

class AlohaPlumeMapPainter extends CustomPainter {
  final double windDirectionDeg;
  final double windSpeedKmh;
  final double plumeSpreadDeg;
  final double leakRateKgSec;
  final double waveProgress;
  final double pulseProgress;
  final bool showPlumes;
  final bool showEvacRoutes;
  final bool showAssemblyPoints;

  AlohaPlumeMapPainter({
    required this.windDirectionDeg,
    required this.windSpeedKmh,
    required this.plumeSpreadDeg,
    required this.leakRateKgSec,
    required this.waveProgress,
    required this.pulseProgress,
    required this.showPlumes,
    required this.showEvacRoutes,
    required this.showAssemblyPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.42, size.height * 0.52);

    // 1. Draw Grid Lines & GIS Coordinate Axes
    _paintGisGrid(canvas, size);

    // 2. Draw Burhi Dihing River & Waterway
    _paintRiverWaterway(canvas, size);

    // 3. Draw Pipeline Centerline (18" High Pressure) & Valve Stations
    _paintPipelineAndValves(canvas, size, center);

    // 4. Draw ALOHA Plume Dispersion Zones (Yellow PAC-1, Orange IDLH, Red Threat Zone)
    if (showPlumes) {
      _paintAlohaPlumeZones(canvas, center);
    }

    // 5. Draw Evacuation Corridors & Blocked Roads
    if (showEvacRoutes) {
      _paintEvacuationRoutes(canvas, size, center);
    }

    // 6. Draw Leak Epicenter with Pulsing Blast Ring
    _paintLeakEpicenter(canvas, center);

    // 7. Draw Safe Assembly Points
    if (showAssemblyPoints) {
      _paintAssemblyPoints(canvas, size);
    }
  }

  void _paintGisGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2E5C).withValues(alpha: 0.3)
      ..strokeWidth = 0.8;

    const spacing = 45.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw scale marker (1 km bar)
    final scalePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.5;
    final scaleStart = Offset(size.width - 110, size.height - 20);
    final scaleEnd = Offset(size.width - 20, size.height - 20);
    canvas.drawLine(scaleStart, scaleEnd, scalePaint);
    canvas.drawLine(Offset(scaleStart.dx, scaleStart.dy - 4), Offset(scaleStart.dx, scaleStart.dy + 4), scalePaint);
    canvas.drawLine(Offset(scaleEnd.dx, scaleEnd.dy - 4), Offset(scaleEnd.dx, scaleEnd.dy + 4), scalePaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '1.0 KM (ALOHA)',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(scaleStart.dx + 12, scaleStart.dy - 14));
  }

  void _paintRiverWaterway(Canvas canvas, Size size) {
    final riverPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.2)
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.25);
    path.cubicTo(
      size.width * 0.35,
      size.height * 0.38,
      size.width * 0.65,
      size.height * 0.65,
      size.width,
      size.height * 0.85,
    );
    canvas.drawPath(path, riverPaint);

    // River label
    final riverText = TextPainter(
      text: const TextSpan(
        text: 'Burhi Dihing River Crossing',
        style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    riverText.paint(canvas, Offset(size.width * 0.15, size.height * 0.31));
  }

  void _paintPipelineAndValves(Canvas canvas, Size size, Offset epicenter) {
    final pipePaint = Paint()
      ..color = const Color(0xFFFFB95F).withValues(alpha: 0.8)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final pipePath = Path();
    pipePath.moveTo(size.width * 0.05, size.height * 0.78);
    pipePath.lineTo(epicenter.dx, epicenter.dy);
    pipePath.lineTo(size.width * 0.85, size.height * 0.22);
    canvas.drawPath(pipePath, pipePaint);

    // Pipeline label
    final pipeText = TextPainter(
      text: const TextSpan(
        text: '18" Crude/Gas Corridor KP 42+350 (90 Bar)',
        style: TextStyle(color: Color(0xFFFFB95F), fontSize: 8.5, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pipeText.paint(canvas, Offset(epicenter.dx - 120, epicenter.dy + 14));

    // Valve Station 02 (Upstream)
    final vs2 = Offset(size.width * 0.15, size.height * 0.70);
    _drawValveStation(canvas, vs2, 'VS-02 (ISOLATED)');

    // Valve Station 03 (Downstream)
    final vs3 = Offset(size.width * 0.72, size.height * 0.32);
    _drawValveStation(canvas, vs3, 'VS-03 (ISOLATED)');
  }

  void _drawValveStation(Canvas canvas, Offset pos, String label) {
    final boxPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRect(Rect.fromCenter(center: pos, width: 10, height: 10), boxPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromCenter(center: pos, width: 10, height: 10), borderPaint);

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - 25, pos.dy - 16));
  }

  void _paintAlohaPlumeZones(Canvas canvas, Offset center) {
    // Convert meteorological wind direction (towards downwind)
    // Wind vector blows towards (windDirectionDeg)
    final rad = (windDirectionDeg - 90) * (pi / 180);
    final spreadRad = (plumeSpreadDeg * 0.5) * (pi / 180);

    // Radii representing distances downwind
    final yellowRadius = 240.0;
    final orangeRadius = 135.0;
    final redRadius = 65.0;

    // 1. Draw PAC-1 Yellow Plume (Caution / Odor)
    _drawPlumeCone(canvas, center, rad, spreadRad * 1.3, yellowRadius, const Color(0xFFF59E0B), 0.22);

    // 2. Draw IDLH Orange Plume (ERPG-2 / >10% LFL)
    _drawPlumeCone(canvas, center, rad, spreadRad * 1.0, orangeRadius, const Color(0xFFF97316), 0.35);

    // 3. Draw Threat Zone Red Plume (Lethal / >60% LFL)
    _drawPlumeCone(canvas, center, rad, spreadRad * 0.75, redRadius, const Color(0xFFEF4444), 0.55);

    // Draw Plume Centerline Vector
    final vectorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final endVector = Offset(
      center.dx + cos(rad) * (yellowRadius + 15),
      center.dy + sin(rad) * (yellowRadius + 15),
    );
    canvas.drawLine(center, endVector, vectorPaint);
  }

  void _drawPlumeCone(Canvas canvas, Offset center, double centerRad, double spread, double radius, Color color, double opacity) {
    final path = Path();
    path.moveTo(center.dx, center.dy);

    final leftRad = centerRad - spread;
    final rightRad = centerRad + spread;

    final leftPt = Offset(center.dx + cos(leftRad) * radius, center.dy + sin(leftRad) * radius);
    final midPt = Offset(center.dx + cos(centerRad) * (radius * 1.12), center.dy + sin(centerRad) * (radius * 1.12));
    final rightPt = Offset(center.dx + cos(rightRad) * radius, center.dy + sin(rightRad) * radius);

    path.lineTo(leftPt.dx, leftPt.dy);
    path.quadraticBezierTo(midPt.dx, midPt.dy, rightPt.dx, rightPt.dy);
    path.close();

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: opacity * 1.2), color.withValues(alpha: opacity * 0.3), Colors.transparent],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.2));

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);
  }

  void _paintEvacuationRoutes(Canvas canvas, Size size, Offset center) {
    // Safe Crosswind Route 1 (Upwind towards Assembly Point A at North)
    final safeRoutePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final safePath1 = Path();
    safePath1.moveTo(center.dx - 15, center.dy - 10);
    safePath1.quadraticBezierTo(
      center.dx - 90,
      center.dy - 90,
      size.width * 0.22,
      size.height * 0.16,
    );
    canvas.drawPath(safePath1, safeRoutePaint);

    // Directional arrows along safe route
    _drawArrow(canvas, Offset(center.dx - 55, center.dy - 55), Offset(center.dx - 65, center.dy - 70), const Color(0xFF10B981));

    // Blocked Road (Crossing through the downwind plume)
    final blockedRoadPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final blockedPath = Path();
    blockedPath.moveTo(center.dx + 20, center.dy + 30);
    blockedPath.lineTo(size.width * 0.75, size.height * 0.72);
    canvas.drawPath(blockedPath, blockedRoadPaint);

    // Hazard X marker
    _drawHazardX(canvas, Offset(center.dx + 70, center.dy + 70));
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);

    final angle = atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowSize = 6.0;
    final path = Path();
    path.moveTo(to.dx, to.dy);
    path.lineTo(to.dx - arrowSize * cos(angle - pi / 6), to.dy - arrowSize * sin(angle - pi / 6));
    path.lineTo(to.dx - arrowSize * cos(angle + pi / 6), to.dy - arrowSize * sin(angle + pi / 6));
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawHazardX(Canvas canvas, Offset pos) {
    final xPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.5;
    const len = 7.0;
    canvas.drawLine(Offset(pos.dx - len, pos.dy - len), Offset(pos.dx + len, pos.dy + len), xPaint);
    canvas.drawLine(Offset(pos.dx - len, pos.dy + len), Offset(pos.dx + len, pos.dy - len), xPaint);

    final tp = TextPainter(
      text: const TextSpan(
        text: 'BLOCKED (VAPOR HAZARD)',
        style: TextStyle(color: Color(0xFFEF4444), fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - 35, pos.dy + 8));
  }

  void _paintLeakEpicenter(Canvas canvas, Offset center) {
    // Pulsing outer shockwave
    final pulseRadius = 14.0 + (pulseProgress * 12.0);
    final pulsePaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.7 - (pulseProgress * 0.6))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, pulseRadius, pulsePaint);

    // Inner epicenter core
    final corePaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(center, 7.0, corePaint);

    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 3.0, centerPaint);

    // Label
    final tp = TextPainter(
      text: const TextSpan(
        text: 'RUPTURE / LEAK EPICENTER',
        style: TextStyle(color: Color(0xFFEF4444), fontSize: 8.5, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - 48, center.dy - 22));
  }

  void _paintAssemblyPoints(Canvas canvas, Size size) {
    // Assembly Point A (North Ridge Helipad)
    final apA = Offset(size.width * 0.22, size.height * 0.16);
    _drawAssemblyMarker(canvas, apA, 'POINT A: HELIPAD (SAFE)');

    // Assembly Point B (Gate 2 Admin)
    final apB = Offset(size.width * 0.12, size.height * 0.48);
    _drawAssemblyMarker(canvas, apB, 'POINT B: ADMIN (SAFE)');
  }

  void _drawAssemblyMarker(Canvas canvas, Offset pos, String label) {
    final pinPaint = Paint()..color = const Color(0xFF10B981);
    canvas.drawCircle(pos, 8.0, pinPaint);

    final innerPaint = Paint()..color = Colors.black;
    canvas.drawCircle(pos, 4.0, innerPaint);

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - 30, pos.dy - 18));
  }

  @override
  bool shouldRepaint(covariant AlohaPlumeMapPainter oldDelegate) {
    return oldDelegate.windDirectionDeg != windDirectionDeg ||
        oldDelegate.windSpeedKmh != windSpeedKmh ||
        oldDelegate.plumeSpreadDeg != plumeSpreadDeg ||
        oldDelegate.waveProgress != waveProgress ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.showPlumes != showPlumes;
  }
}
