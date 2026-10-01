import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/models/safety_models.dart';
import '../../core/theme/app_theme.dart';
import '../../services/location_service.dart';

class SafetyManagementScreen extends StatefulWidget {
  const SafetyManagementScreen({super.key});

  @override
  State<SafetyManagementScreen> createState() => _SafetyManagementScreenState();
}

class _SafetyManagementScreenState extends State<SafetyManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocationService _locationService = LocationService();
  final ImagePicker _picker = ImagePicker();

  // Safety KPIs & Live Ticker
  int _safeManHoursCount = 1420500;
  Timer? _safeManHoursTimer;
  final String _ltifr = '0.00';
  final int _daysLtiFree = 412;
  int _openNearMissCount = 3;
  int _activePermitsCount = 8;

  // Live Multi-Gas Telemetry Sensor Simulation
  Timer? _gasSimulationTimer;
  late List<GasTelemetrySensor> _gasSensors;
  String _activeGasScenario = 'NORMAL';
  final Random _rng = Random();

  // HSE Golden Rules Compliance & Digital HSE Officer Sign-Off
  late List<HseGoldenRuleModel> _goldenRules;
  HseOfficerSignOff? _goldenRulesSignOff;

  // Active Permits Ledger
  late List<SafetyPermitModel> _permits;

  // Near Miss Register
  late List<NearMissReportModel> _nearMissReports;

  // Safety Audits List
  late List<SafetyAuditModel> _safetyAudits;

  // Emergency Muster Points & Site Clinic
  late List<MusterPointModel> _musterPoints;
  late SiteClinicModel _siteClinic;
  int _checkedInMusterCount = 84;
  bool _isUserCheckedInAtMuster = false;
  bool _isSirenActive = false;

  // Filter for Active Permits
  String _selectedPermitFilter = 'ALL';
  String _permitSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
    _startSafeManHoursTicker();
    _startGasSimulation();
  }

  @override
  void dispose() {
    _safeManHoursTimer?.cancel();
    _gasSimulationTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _permits = [
      SafetyPermitModel(
        id: 'PTW-HW-2026-092',
        title: 'Hot Work Permit (Welding on flare header)',
        permitType: 'Hot Work',
        location: 'Unit 4 Flare Header & Tie-in Line 24',
        issuedTo: 'Tapan Das & Pipe Welding Gang',
        validTill: '18:00',
        status: PermitStatus.approved,
        hazardLevel: 'HIGH HAZARD - CLASS 1',
        safetyChecklist: [
          'Continuous Fire Watch Posted with 2x 10kg DCP Extinguishers',
          'LEL multi-gas atmospheric sniff test passed (0.0% LEL)',
          'Flame-retardant fire blankets installed around pipe headers',
          'Spark containment enclosure erected at elevation +6.5m',
        ],
        gasTestReadings: {
          'LEL': '0.0%',
          'O2': '20.9%',
          'H2S': '0.0 ppm',
          'CO': '0 ppm',
        },
        authorizedOfficer: 'Subhash Roy (Lead HSE)',
        issuedAt: DateTime.now().subtract(const Duration(hours: 3)),
        workOrderRef: 'WO-FLARE-024',
      ),
      SafetyPermitModel(
        id: 'PTW-WAH-2026-042',
        title: 'Working at Height Permit (Scaffolding Unit 4)',
        permitType: 'Working at Height',
        location: 'Scaffolding Unit 4 - Column C40 (18.5m elevation)',
        issuedTo: 'Assam Scaffolding Erectors & Rigging Crew',
        validTill: '19:30',
        status: PermitStatus.approved,
        hazardLevel: 'CRITICAL FALL HAZARD',
        safetyChecklist: [
          'Scaffold Green Tag inspection signed by Competent Person',
          'Full-body harness with double shock-absorbing lanyards (100% tie-off)',
          'Toe-boards, mid-rails, and debris safety netting installed',
          'Tool tethering lanyards secured to prevent dropped objects',
        ],
        gasTestReadings: null,
        authorizedOfficer: 'Subhash Roy (Lead HSE)',
        issuedAt: DateTime.now().subtract(const Duration(hours: 4)),
        workOrderRef: 'WO-SCAF-108',
      ),
      SafetyPermitModel(
        id: 'PTW-CSE-2026-019',
        title: 'Confined Space Entry (Tank 102 inspection)',
        permitType: 'Confined Space',
        location: 'Tank 102 Internal Crude Storage Shell (Bay 3)',
        issuedTo: 'NDT Inspection Squad (R. K. Sharma / Level-II)',
        validTill: 'Pending Gas Test',
        status: PermitStatus.pendingGasTest,
        hazardLevel: 'ATMOSPHERIC HAZARD / ENCLOSED',
        safetyChecklist: [
          'Mechanical forced air ventilation running for minimum 120 mins',
          'Positive isolation and mechanical blinding of crude inlet/outlet flanges',
          'Trained Standby Man posted at manhole with SCBA and rescue tripod',
          'Continuous 4-gas atmospheric monitor to be lowered before entry',
        ],
        gasTestReadings: null,
        authorizedOfficer: 'Subhash Roy (Lead HSE)',
        issuedAt: DateTime.now().subtract(const Duration(hours: 1)),
        workOrderRef: 'WO-TNK-102',
      ),
      SafetyPermitModel(
        id: 'PTW-CW-2026-014',
        title: 'Cold Work Permit (Cold cutting & flange bolting)',
        permitType: 'Cold Work',
        location: 'Process Unit 4 Piperack Corridor (Line 24 Cold Tie-in)',
        issuedTo: 'Mechanical Piping Crew & Flange Torque Technicians',
        validTill: '19:00',
        status: PermitStatus.approved,
        hazardLevel: 'PRESSURIZED LINE / FLANGE HAZARD',
        safetyChecklist: [
          'Process line depressurized, drained, flushed, and verified at 0.0 bar gauge',
          'Double block and bleed positive isolation verified with tagged LOTO locks',
          'Multi-gas sniff test verified 0.0% LEL, H2S <10 ppm, and O2 20.9%',
          'Non-sparking beryllium-copper wrenches used for flange unbolting',
          'Pneumatic clamshell cold cutting machine verified (zero flame/spark)',
          'Chemical drip tray & spill containment kit positioned under joint',
          'Hydraulic torque wrench calibrated to 450 N·m with cross-star bolting sequence',
        ],
        gasTestReadings: {
          'LEL': '0.0%',
          'O2': '20.9%',
          'H2S': '0.0 ppm',
          'CO': '0 ppm',
        },
        authorizedOfficer: 'Subhash Roy (Lead HSE)',
        issuedAt: DateTime.now().subtract(const Duration(hours: 2)),
        workOrderRef: 'WO-COLD-082',
      ),
      SafetyPermitModel(
        id: 'PTW-EL-2026-051',
        title: 'Electrical Isolation & LOTO Permit',
        permitType: 'Electrical Isolation',
        location: 'Main Substation SS-02, 6.6kV Feeders',
        issuedTo: 'Electromechanical Commissioning Gang',
        validTill: '20:00',
        status: PermitStatus.approved,
        hazardLevel: 'HIGH VOLTAGE ARREST',
        safetyChecklist: [
          'Lockout/Tagout (LOTO) locks applied with padlocks and danger tags',
          'Earthing switches closed and proven dead with calibrated detector',
          'Dielectric rubber matting inspected and insulated rescue hook ready',
        ],
        gasTestReadings: null,
        authorizedOfficer: 'Vikram Joshi (Site Lead)',
        issuedAt: DateTime.now().subtract(const Duration(hours: 5)),
        workOrderRef: 'WO-ELEC-440',
      ),
      SafetyPermitModel(
        id: 'PTW-EX-2026-033',
        title: 'Deep Trenching & Excavation Permit (Chainage 14+300)',
        permitType: 'Excavation',
        location: 'Right-of-Way Corridor, KM 14+300 Trench Cut',
        issuedTo: 'Civil Trenching Team B',
        validTill: '18:30',
        status: PermitStatus.approved,
        hazardLevel: 'CAVE-IN HAZARD',
        safetyChecklist: [
          'Underground utilities scanned with Ground Penetrating Radar (GPR)',
          'Trench shoring and 45-degree angle of repose benching verified',
          'Access ladders installed every 7.5 meters of trench run',
        ],
        gasTestReadings: null,
        authorizedOfficer: 'Marcus Vance, P.E.',
        issuedAt: DateTime.now().subtract(const Duration(hours: 6)),
        workOrderRef: 'WO-TRN-301',
      ),
      SafetyPermitModel(
        id: 'PTW-NDT-2026-015',
        title: 'Radiographic Examination (RT / Gamma Source) Permit',
        permitType: 'Radiography',
        location: 'Line 24 Golden Tie-in Joint #W24-06',
        issuedTo: 'NABL Certified Radiography Crew (Ir-192 Source)',
        validTill: '22:00',
        status: PermitStatus.approved,
        hazardLevel: 'IONIZING RADIATION',
        safetyChecklist: [
          'Exclusion zone cordoned off at 25-meter radius with radiation warning signs',
          'Dosimeters, survey meters, and collimator checked before exposure',
          'Sirens and flashing beacon activated during radiation source rollout',
        ],
        gasTestReadings: null,
        authorizedOfficer: 'R. K. Sharma (QA/QC Lead)',
        issuedAt: DateTime.now().subtract(const Duration(hours: 2)),
        workOrderRef: 'WO-NDT-044',
      ),
      SafetyPermitModel(
        id: 'PTW-LFT-2026-008',
        title: 'Critical Heavy Lifting & Tandem Rigging Permit',
        permitType: 'Heavy Lifting',
        location: 'Flare Stack Unit 4 Base Area',
        issuedTo: '150T Sany Crawler Crane Rigging Gang',
        validTill: '17:30',
        status: PermitStatus.approved,
        hazardLevel: 'SUSPENDED LOAD HAZARD',
        safetyChecklist: [
          'Engineered Rigging Plan approved by Chief Construction Engineer',
          'Crane outrigger mats set on compacted soil with load test certificate',
          'Wind speed verified below 9.8 m/s with calibrated anemometer',
          'Tag lines attached to both ends of flare pipe spool',
        ],
        gasTestReadings: null,
        authorizedOfficer: 'Subhash Roy (Lead HSE)',
        issuedAt: DateTime.now().subtract(const Duration(hours: 3)),
        workOrderRef: 'WO-CRN-089',
      ),
    ];

    _nearMissReports = [
      NearMissReportModel(
        id: 'NMR-2026-001',
        hazardCategory: 'Working at Height / Dropped Object',
        location: 'Unit 4 Scaffolding Platform C (27.2948° N, 95.3214° E)',
        description:
            'A 19mm scaffold spanner slipped from worker hand at +12m elevation. Caught by toe-board and safety netting; did not reach lower work deck.',
        immediateActionTaken:
            'Tool tethering policy re-enforced immediately. All 14 scaffolding riggers equipped with wrist tool lanyards before work resumed.',
        severity: 'HIGH',
        reporterName: 'Vikram Joshi (Piping Supervisor)',
        timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 12)),
        latitude: 27.2948,
        longitude: 95.3214,
        status: 'OPEN',
      ),
      NearMissReportModel(
        id: 'NMR-2026-002',
        hazardCategory: 'Hot Work / Fire Hazard',
        location: 'Flare Line Trench Corridor (27.2952° N, 95.3220° E)',
        description:
            'Flying weld sparks reached dry grass edge outside 5-meter clearing perimeter during downhill pipe bead pass.',
        immediateActionTaken:
            'Fire Watch extinguished sparks within 3 seconds using CO2 extinguisher. Perimeter clearing widened to 15 meters and soaked with water barrier.',
        severity: 'MEDIUM',
        reporterName: 'Tapan Das (Lead Welder)',
        timestamp: DateTime.now().subtract(const Duration(hours: 7)),
        latitude: 27.2952,
        longitude: 95.3220,
        status: 'OPEN',
      ),
      NearMissReportModel(
        id: 'NMR-2026-003',
        hazardCategory: 'Excavation & Trenching',
        location: 'Chainage 14+300 West Wall (27.2935° N, 95.3198° E)',
        description:
            'Minor soil spalling observed along trench lip after vibratory roller passed within 3 meters of edge.',
        immediateActionTaken:
            'Heavy plant equipment exclusion boundary moved to 6 meters. Extra timber shoring strut installed on west embankment.',
        severity: 'MEDIUM',
        reporterName: 'Subhash Roy (Lead HSE)',
        timestamp: DateTime.now().subtract(const Duration(hours: 9, minutes: 30)),
        latitude: 27.2935,
        longitude: 95.3198,
        status: 'OPEN',
      ),
    ];

    _safetyAudits = [
      SafetyAuditModel(
        id: 'AUD-HSE-108',
        title: 'Scaffold Green Tag & Fall Arrest Systems Audit',
        standardCode: 'OSHA 1926.451 / OISD-GDN-192',
        location: 'Process Unit 4 & Flare Stack Elevation Walk',
        auditorName: 'Subhash Roy (Lead HSE Auditor)',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'PASS',
        complianceScore: 100.0,
        findings: [
          'All 18 scaffold towers inspected have valid green tags stamped within 7 days.',
          'Double lanyard tie-offs verified on 100% of workers above 1.8m height.',
          'Zero loose tools or missing kick-boards recorded.',
        ],
      ),
      SafetyAuditModel(
        id: 'AUD-HSE-107',
        title: 'Hot Work Fire Prevention & Spark Containment Audit',
        standardCode: 'NFPA 51B / OISD-STD-105',
        location: 'Line 24 Tie-in & Trench Lower-in Corridor',
        auditorName: 'Ananya Sen (Primavera & Safety Auditor)',
        date: DateTime.now().subtract(const Duration(hours: 8)),
        status: 'PASS',
        complianceScore: 100.0,
        findings: [
          'Certified fire watch personnel present at each active welding station.',
          'Calibrated LEL combustible gas detectors reading 0.0% within 10m envelope.',
          'Flame-retardant silicone glass fabrics deployed without tear defects.',
        ],
      ),
      SafetyAuditModel(
        id: 'AUD-HSE-106',
        title: 'Multi-Gas Atmospheric Detector Calibration Verification',
        standardCode: 'ISO 45001:2018 Cl. 8.1.2',
        location: 'Central HSE Safety Instrumentation Lab',
        auditorName: 'R. K. Sharma (QA/QC Lead Inspector)',
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: 'PASS',
        complianceScore: 100.0,
        findings: [
          'Bump test and span calibration conducted on 8 RAE Systems 4-gas monitors.',
          'Sensors calibrated against certified mix (50% LEL Methane, 25 ppm H2S, 50 ppm CO, 18% O2).',
          'Calibration validity certified until next quarterly cycle.',
        ],
      ),
      SafetyAuditModel(
        id: 'AUD-HSE-105',
        title: 'Chemical Storage, Fuel Bowser & Hazmat Secondary Containment',
        standardCode: 'CPCB / Petroleum Rules 2002',
        location: 'Field Heavy Equipment Refueling Station',
        auditorName: 'Subhash Roy (Lead HSE Auditor)',
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: 'PASS_WITH_OBSERVATION',
        complianceScore: 96.5,
        findings: [
          'Diesel bowser bunding verified at 110% tank volume capacity.',
          'Spill response kit fully stocked with absorbent pads and neutralizer.',
          'Observation: Eyewash station inspection tag required renewal signature (Updated on site).',
        ],
      ),
      SafetyAuditModel(
        id: 'AUD-HSE-104',
        title: 'Heavy Crane Outriggers & Rigging Slings NDT Audit',
        standardCode: 'ASME B30.5 / Factory Act Cl. 29',
        location: 'Unit 4 Heavy Lift Staging Yard',
        auditorName: 'Marcus Vance, P.E. (FIDIC 3.1 Director)',
        date: DateTime.now().subtract(const Duration(days: 3)),
        status: 'PASS',
        complianceScore: 100.0,
        findings: [
          'Magnetic Particle Testing (MPT) completed on all 4 crane hook assemblies.',
          'Webbing slings and wire rope chokers tagged with current color code.',
          'Annual third-party load test certificate valid until December 2026.',
        ],
      ),
    ];

    _musterPoints = [
      MusterPointModel(
        id: 'MP-01',
        code: 'MUSTER POINT 1 (PRIMARY)',
        name: 'North Gate Assembly Plaza',
        locationDescription: 'Between Substation SS-02 & North Main Security Turnstile',
        latitude: 27.2965,
        longitude: 95.3230,
        distanceMeters: 120,
        walkingTime: '1.5 mins',
        bearing: 'North-East (38°)',
        capacity: 250,
        currentHeadcount: _checkedInMusterCount,
        status: 'SAFE',
        evacuationRoute: 'Exit Unit 4 North Stairwell -> Follow high-vis green walkway past SS-02 -> Proceed to Assembly Flag A',
        emergencyEquipment: [
          'High-Power Megaphone',
          'Trauma First-Aid Kit #01',
          'Satellite Comms Phone',
          'High-Vis Marshal Vests',
          'Emergency Lighting Beacon',
        ],
      ),
      MusterPointModel(
        id: 'MP-02',
        code: 'MUSTER POINT 2',
        name: 'Flare Stack Perimeter Bunker',
        locationDescription: 'East Buffer Berm, 100m outside thermal radiation envelope',
        latitude: 27.2928,
        longitude: 95.3265,
        distanceMeters: 340,
        walkingTime: '4 mins',
        bearing: 'South-East (115°)',
        capacity: 150,
        currentHeadcount: 22,
        status: 'STANDBY',
        evacuationRoute: 'Follow East Perimeter Trench Walkway -> Enter reinforced concrete blast shelter',
        emergencyEquipment: [
          '6x 50L Cascade Breathing Air',
          'Intrinsically Safe Radios (Ch 4)',
          'Fire Blankets & Heavy Stretchers',
        ],
      ),
      MusterPointModel(
        id: 'MP-03',
        code: 'MUSTER POINT 3',
        name: 'Main Admin & Fabrication Yard',
        locationDescription: 'Main Site Office Complex & Civil Staging Ground',
        latitude: 27.2910,
        longitude: 95.3190,
        distanceMeters: 490,
        walkingTime: '6 mins',
        bearing: 'South-West (220°)',
        capacity: 300,
        currentHeadcount: 112,
        status: 'SAFE',
        evacuationRoute: 'Follow Main Access Haul Road South -> Central Parade Ground Flag Pole',
        emergencyEquipment: [
          'Adjacent to OHC Field Clinic',
          'Backup Power Generator 125kVA',
          'Potable Water Tanks & Blankets',
        ],
      ),
      MusterPointModel(
        id: 'MP-04',
        code: 'MUSTER POINT 4',
        name: 'Tank Farm East Berm',
        locationDescription: 'Crude Storage Tank 101/102 Secondary Containment Bund',
        latitude: 27.2980,
        longitude: 95.3280,
        distanceMeters: 680,
        walkingTime: '8.5 mins',
        bearing: 'North-East (55°)',
        capacity: 100,
        currentHeadcount: 14,
        status: 'DOWNWIND_WARNING',
        evacuationRoute: 'Emergency access via Gate 4 only. CAUTION: Verify wind sock direction before proceeding.',
        emergencyEquipment: [
          'Foam Monitor Remote Station',
          'Wind Sock & Toxic Gas Beacon',
          'Spill Containment Trailer',
        ],
      ),
    ];

    _siteClinic = SiteClinicModel(
      name: 'Duliajan Unit 4 Field Trauma Center & OHC',
      location: 'Bay 1, Gate 2 (Adjacent to Main Admin Block)',
      emergencyHotline: '+91 (374) 280-4911',
      speedDial: '#108',
      medicalOfficer: 'Dr. Anupam Baruah, MD (Occupational Medicine)',
      paramedicOnDuty: 'Sister Sangita Borah (Trauma Care Certified)',
      ambulanceStatus: 'READY AT BAY 1 (Driver: Raju Sonowal · Ext #911)',
      responseTimeSla: '< 3 Minutes to any active site coordinates',
      standbyEquipment: [
        'Automated External Defibrillator (Philips HeartStart AED - Ready)',
        '100% Medical Oxygen Cascade (4x 46.7L High-Pressure Cylinders)',
        'Polyvalent Snake Antivenom (20 vials chilled at 4°C)',
        'Burn Trauma Dressing Kits & Silver Sulfadiazine Packs',
        'Spine Board & Kendrick Extrication Device (KED)',
        'Emergency Eye Wash & Drench Showers (4.2 Bar Certified)',
      ],
      firstAiders: [
        FirstAiderModel(
          name: 'Subhash Roy',
          badgeNumber: 'HSE-001',
          trade: 'Lead HSE Officer',
          location: 'Unit 4 Control Building',
          contactExtension: 'Ext. 401 (Radio Ch 1)',
          certification: 'St. John Ambulance Certified First Aider (Valid: 2027)',
        ),
        FirstAiderModel(
          name: 'Tapan Das',
          badgeNumber: 'WLD-402',
          trade: 'Lead Welder & Fire Watch',
          location: 'Process Unit 4 Pipe Rack',
          contactExtension: 'Ext. 422 (Radio Ch 3)',
          certification: 'Red Cross Industrial CPR & Burn Care (Valid: 2026)',
        ),
        FirstAiderModel(
          name: 'Vikram Joshi',
          badgeNumber: 'PIP-105',
          trade: 'Piping Construction Supervisor',
          location: 'Line 24 Tie-in Trench',
          contactExtension: 'Ext. 418 (Radio Ch 2)',
          certification: 'OSHA First Aid & AED Responder (Valid: 2027)',
        ),
        FirstAiderModel(
          name: 'Biren Gogoi',
          badgeNumber: 'SCF-108',
          trade: 'Scaffolding Rigging Foreman',
          location: 'Flare Stack Elevation +18m',
          contactExtension: 'Ext. 430 (Radio Ch 1)',
          certification: 'IRATA High-Angle Rescue & Trauma First Aid (Valid: 2027)',
        ),
      ],
    );

    _gasSensors = [
      GasTelemetrySensor(
        id: 'SEN-GT-01',
        zone: 'Unit 4 Flare Header Tie-in Corridor',
        associatedPermitType: 'Hot Work',
        h2sPpm: 0.0,
        lelPercent: 0.0,
        o2Percent: 20.9,
        coPpm: 0.0,
        atexClassification: 'ATEX Zone 1 Ex ia IIC T4 Ga',
        detectorModel: 'Honeywell BW Ultra (LoRaWAN 868MHz)',
        batteryLevel: 98,
        lastBumpTest: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      GasTelemetrySensor(
        id: 'SEN-GT-02',
        zone: 'Tank 102 Internal Crude Storage Shell & Sump',
        associatedPermitType: 'Confined Space',
        h2sPpm: 0.0,
        lelPercent: 0.0,
        o2Percent: 20.9,
        coPpm: 0.0,
        atexClassification: 'ATEX Zone 0 Ex ia IIC T4 Ga',
        detectorModel: 'RAE Systems MultiRAE Pro (Wireless Mesh)',
        batteryLevel: 92,
        lastBumpTest: DateTime.now().subtract(const Duration(hours: 2, minutes: 40)),
      ),
      GasTelemetrySensor(
        id: 'SEN-GT-03',
        zone: 'Column C40 Scaffolding Staging Deck (+18.5m)',
        associatedPermitType: 'Working at Height',
        h2sPpm: 0.0,
        lelPercent: 0.0,
        o2Percent: 20.9,
        coPpm: 0.0,
        atexClassification: 'ATEX Zone 2 Ex nA IIC T3 Gc',
        detectorModel: 'Industrial Scientific Ventis Pro5 (BLE Beacon)',
        batteryLevel: 95,
        lastBumpTest: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      GasTelemetrySensor(
        id: 'SEN-GT-04',
        zone: 'Process Piperack Cold Cut Header (Bay 2)',
        associatedPermitType: 'Cold Work',
        h2sPpm: 0.0,
        lelPercent: 0.0,
        o2Percent: 20.9,
        coPpm: 0.0,
        atexClassification: 'ATEX Zone 1 Ex ia IIC T4 Ga',
        detectorModel: 'Dräger X-am 8000 (Field Bus)',
        batteryLevel: 96,
        lastBumpTest: DateTime.now().subtract(const Duration(hours: 3, minutes: 15)),
      ),
    ];

    _goldenRules = [
      HseGoldenRuleModel(
        ruleNumber: 1,
        title: 'Work Authorization & Permit-to-Work (PTW)',
        lifeSavingStandard: 'Always work with an authorized, valid permit for all hot work, height work, confined space, and cold work activities.',
        mandatoryAction: 'Verify job safety analysis (JSA), field precautions, and sign the daily pre-shift toolbox talk prior to commencement.',
        standardCode: 'IOGP Rule 1 / OISD-105',
        isCompliant: true,
        remarks: 'All 8 active site permits verified in field with AGT gas sign-off.',
        auditorName: 'Subhash Roy (Lead HSE Officer)',
        auditTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      HseGoldenRuleModel(
        ruleNumber: 2,
        title: 'Energy Isolation & Lockout / Tagout (LOTO)',
        lifeSavingStandard: 'Verify zero stored mechanical, electrical, pneumatic, and hydraulic energy before commencing any servicing or repair.',
        mandatoryAction: 'Apply personal safety padlocks, hazard tags, verify try-step, and test circuit dead before line breaking.',
        standardCode: 'OSHA 1910.147 / CEA Rules',
        isCompliant: true,
        remarks: 'Padlocks and danger tags verified on 6.6kV feeders SS-02; earthing switches confirmed closed.',
        auditorName: 'Subhash Roy (Lead HSE Officer)',
        auditTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      HseGoldenRuleModel(
        ruleNumber: 3,
        title: 'Confined Space Entry & Continuous Gas Testing',
        lifeSavingStandard: 'Never enter a confined space without atmospheric 4-gas testing clearance, forced ventilation, and a designated standby attendant.',
        mandatoryAction: 'Verify O2 (19.5-23.5%), LEL (<10%), H2S (<10 ppm). Ensure mechanical rescue tripod and SCBA are positioned at hatch.',
        standardCode: 'OSHA 1910.146 / API 2015',
        isCompliant: true,
        remarks: 'Mechanical air ventilation running >120 mins in Tank 102; trained standby attendant stationed with entrant log.',
        auditorName: 'Subhash Roy (Lead HSE Officer)',
        auditTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      HseGoldenRuleModel(
        ruleNumber: 4,
        title: 'Working at Height & Fall Prevention (>1.8m)',
        lifeSavingStandard: '100% tie-off is mandatory whenever working above 1.8m (6 ft) using certified full-body harness and twin shock-absorbing lanyards.',
        mandatoryAction: 'Inspect scaffold green tag, verify toe-boards and guardrails, attach tool tethering wrist lanyards to prevent dropped objects.',
        standardCode: 'OSHA 1926 Subpart M / OISD-192',
        isCompliant: true,
        remarks: 'Column C40 scaffolding green-tagged; all riggers equipped with tool tethering lanyards.',
        auditorName: 'Subhash Roy (Lead HSE Officer)',
        auditTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      HseGoldenRuleModel(
        ruleNumber: 5,
        title: 'Hot Work & Ignition Source Control',
        lifeSavingStandard: 'Control all ignition sources; verify zero flammable vapors (<10% LEL) within 11m (35 ft) perimeter before cutting or welding.',
        mandatoryAction: 'Deploy FM-approved fire blankets, continuous dedicated fire watch with pressurized fire extinguisher, and maintain 60-min post-work watch.',
        standardCode: 'NFPA 51B / OISD-105',
        isCompliant: true,
        remarks: 'Spark containment enclosure certified at +6.5m elevation; 2x 10kg DCP extinguishers at station.',
        auditorName: 'Subhash Roy (Lead HSE Officer)',
        auditTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      HseGoldenRuleModel(
        ruleNumber: 6,
        title: 'Safe Mechanical Lifting & Rigging Operations',
        lifeSavingStandard: 'Never stand, walk, or position yourself under a suspended crane load; observe certified safe working load (SWL) limits.',
        mandatoryAction: 'Execute only approved engineered lift plans; verify outrigger mats, ground compaction, and tag line stabilization.',
        standardCode: 'ASME B30.5 / OSHA 1926',
        isCompliant: true,
        remarks: '150T Sany crane outriggers load tested; calibrated anemometer reading 4.2 m/s (<9.8 m/s limit).',
        auditorName: 'Subhash Roy (Lead HSE Officer)',
        auditTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      HseGoldenRuleModel(
        ruleNumber: 7,
        title: 'Excavation & Trenching Protection (>1.2m)',
        lifeSavingStandard: 'Always scan for underground utilities with GPR; shore, bench, or shield trenches deeper than 1.2m to prevent cave-in.',
        mandatoryAction: 'Install secure ladder access points every 7.5m; maintain heavy equipment exclusion zone at least 2m from trench lip.',
        standardCode: 'OSHA 1926 Subpart P',
        isCompliant: true,
        remarks: 'GPR underground scan complete; 45-degree angle benching certified at Chainage 14+300.',
        auditorName: 'Subhash Roy (Lead HSE Officer)',
        auditTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      HseGoldenRuleModel(
        ruleNumber: 8,
        title: 'Line of Fire & Heavy Machinery Safety',
        lifeSavingStandard: 'Position yourself outside the line of fire of moving plant, high-pressure test manifolds, and crane slewing perimeters.',
        mandatoryAction: 'Erect high-visibility red exclusion barricades; maintain direct visual contact and banksman/spotter guidance.',
        standardCode: 'ISO 45001 §8.1.2',
        isCompliant: true,
        remarks: '360-degree high-vis barricades in place around flare base and earthmoving equipment corridor.',
        auditorName: 'Subhash Roy (Lead HSE Officer)',
        auditTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      HseGoldenRuleModel(
        ruleNumber: 9,
        title: 'Toxic Gas (H2S) & Respiratory Hazard Safety',
        lifeSavingStandard: 'Wear bump-tested personal 4-gas monitor and carry 15-minute emergency escape breathing apparatus (EEBA) in sour hydrocarbon zones.',
        mandatoryAction: 'Immediate upwind evacuation to designated muster point upon H2S alarm >=10 ppm; observe wind sock direction.',
        standardCode: 'API RP 49 / NIOSH / OISD',
        isCompliant: true,
        remarks: 'All 18 personnel in Unit 4 equipped with bump-tested personal H2S detectors and Dräger EEBA hoods.',
        auditorName: 'Subhash Roy (Lead HSE Officer)',
        auditTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      HseGoldenRuleModel(
        ruleNumber: 10,
        title: 'Stop Work Authority (SWA) & Unsafe Act Intervention',
        lifeSavingStandard: 'Every worker, supervisor, and visitor is unconditionally empowered and obligated to stop any unsafe act or condition immediately.',
        mandatoryAction: 'Halt the task immediately without fear of reprisal; notify HSE supervisor; resume work only after hazard mitigation is verified.',
        standardCode: 'OISD-GDN-192 / IOGP',
        isCompliant: true,
        remarks: '3 proactive SWA interventions logged this month and rewarded with site safety merit badges.',
        auditorName: 'Subhash Roy (Lead HSE Officer)',
        auditTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    _goldenRulesSignOff = HseOfficerSignOff(
      officerName: 'Subhash Roy (Lead HSE Officer #HSE-001)',
      badgeId: 'HSE-001',
      shift: 'Day Shift (07:00 - 19:00 IST)',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      digitalSignatureHash: 'SHA256: 7C49-E892-01A4-FF91-ISO45001-RATIFIED',
      compliancePercentage: 100.0,
      latitude: 27.2948,
      longitude: 95.3214,
      isRatified: true,
    );
  }

  void _startSafeManHoursTicker() {
    _safeManHoursTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        _safeManHoursCount += 1;
      });
    });
  }

  void _startGasSimulation() {
    _gasSimulationTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted) return;
      if (_activeGasScenario == 'NORMAL') {
        setState(() {
          for (var s in _gasSensors) {
            final deltaH2s = (_rng.nextDouble() - 0.5) * 0.08;
            s.h2sPpm = (s.h2sPpm + deltaH2s).clamp(0.0, 0.4);

            final deltaLel = (_rng.nextDouble() - 0.5) * 0.1;
            s.lelPercent = (s.lelPercent + deltaLel).clamp(0.0, 0.8);

            final deltaO2 = (_rng.nextDouble() - 0.5) * 0.05;
            s.o2Percent = (s.o2Percent + deltaO2).clamp(20.8, 21.0);
          }
        });
      }
    });
  }

  void _injectGasScenario(String scenario) {
    setState(() {
      _activeGasScenario = scenario;
      if (scenario == 'NORMAL') {
        for (var s in _gasSensors) {
          s.h2sPpm = 0.0;
          s.lelPercent = 0.0;
          s.o2Percent = 20.9;
          s.coPpm = 0.0;
          s.isMuted = false;
        }
      } else if (scenario == 'H2S_LEAK') {
        _gasSensors[0].h2sPpm = 14.8;
        _gasSensors[0].lelPercent = 2.4;
        _gasSensors[1].h2sPpm = 18.2;
        _gasSensors[1].lelPercent = 1.1;
      } else if (scenario == 'LEL_SURGE') {
        _gasSensors[0].lelPercent = 16.5;
        _gasSensors[3].lelPercent = 13.8;
      } else if (scenario == 'O2_DEFICIENT') {
        _gasSensors[1].o2Percent = 16.2;
      } else if (scenario == 'BUMP_TEST') {
        final now = DateTime.now();
        for (var s in _gasSensors) {
          s.lastBumpTest = now;
          s.h2sPpm = 0.0;
          s.lelPercent = 0.0;
          s.o2Percent = 20.9;
          s.batteryLevel = 100;
        }
      }
    });

    if (scenario == 'H2S_LEAK') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CRITICAL ALARM: H2S >= 10 ppm (14.8 ppm) at Unit 4 & Tank 102! Evacuate UPWIND to North Gate!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (scenario == 'LEL_SURGE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.deepOrangeAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
          content: Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'HIGH EXPLOSIVE ALARM: LEL >= 10% (16.5%) detected! Stop all Hot Work & isolate lines immediately!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (scenario == 'O2_DEFICIENT') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
          content: Row(
            children: [
              Icon(Icons.air_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ASPHYXIATION ALARM: O2 < 19.5% (16.2%) in Tank 102! Non-permitted entrants must evacuate!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (scenario == 'BUMP_TEST') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.tertiary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
          content: Text(
            'Multi-Gas Bump Test Successful: All 4 detectors calibrated and verified (T90 < 12s)!',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _showLtifrBreakdownDialog() {
    final formattedHours = NumberFormat('#,###').format(_safeManHoursCount);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppTheme.primaryLight, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.speed_rounded, color: AppTheme.primaryLight, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOST TIME INJURY FREQUENCY RATE',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'OSHA 1904 & ISO 45001 Standard Metric',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: AppTheme.border, height: 24),
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
                  const Text(
                    'GOVERNING LTIFR MATHEMATICAL FORMULA',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Text(
                      'LTIFR = (Number of Lost Time Injuries × 1,000,000) / Total Man-Hours Worked',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Current Project Values:\n'
                    '• Lost Time Injuries (LTI): 0 incidents\n'
                    '• Total Safe Man-Hours Worked: $formattedHours hrs\n'
                    '• Calculation: (0 × 1,000,000) / $formattedHours = 0.00',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Zero-LTI Streak', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text('$_daysLtiFree Days', style: const TextStyle(color: AppTheme.tertiary, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Continuous Incident-Free Run', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Industry Benchmark', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        const SizedBox(height: 2),
                        const Text('0.28 (O&G Avg)', style: TextStyle(color: AppTheme.primaryLight, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Nirmaan OS: Top Decile', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close Specification', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSafeManHoursMilestoneSheet() {
    final formattedHours = NumberFormat('#,###').format(_safeManHoursCount);
    final progress = (_safeManHoursCount / 1500000.0).clamp(0.0, 1.0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppTheme.tertiary, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.timer_outlined, color: AppTheme.tertiary, size: 22),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SAFE MAN-HOURS ACCUMULATION',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Live Ticking Workforce Progress Ledger',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: AppTheme.border, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current LTI-Free Hours:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text(
                  '$formattedHours hrs',
                  style: const TextStyle(color: AppTheme.tertiary, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Target Milestone:', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                const Text('1,500,000 hrs (Gold Trophy)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppTheme.background,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.tertiary),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(progress * 100).toStringAsFixed(1)}% Achieved',
                style: const TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.groups_rounded, color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '420 active personnel across piping, scaffolding, electrical, and civil trades currently logging zero-harm hours on shift.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Acknowledged'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoldenRulesSignOffDialog() {
    final officerCtrl = TextEditingController(text: 'Subhash Roy (Lead HSE Officer #HSE-001)');
    final badgeCtrl = TextEditingController(text: 'HSE-001');
    String selectedShift = 'Day Shift (07:00 - 19:00 IST)';
    bool confirmedAllChecked = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppTheme.primaryLight, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_user_rounded, color: AppTheme.tertiary, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Digital HSE Officer Sign-Off', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                    Text('IOGP / OISD-105 Shift Ratification', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: officerCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'Lead HSE Officer Name & Designation',
                    isDense: true,
                    prefixIcon: Icon(Icons.badge_rounded, color: AppTheme.primaryLight, size: 16),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: badgeCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'Officer Security Badge ID',
                    isDense: true,
                    prefixIcon: Icon(Icons.pin_rounded, color: AppTheme.primaryLight, size: 16),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedShift,
                  dropdownColor: AppTheme.surfaceCard,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Audit Shift', isDense: true),
                  items: [
                    'Day Shift (07:00 - 19:00 IST)',
                    'Night Shift (19:00 - 07:00 IST)',
                    'Turnaround / Shutdown Shift',
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedShift = val);
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AUDITED FIELD COMPLIANCE',
                        style: TextStyle(color: AppTheme.primaryLight, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_goldenRules.where((r) => r.isCompliant).length} of ${_goldenRules.length} Golden Life-Saving Rules confirmed compliant on site.',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'I certify that all high-risk work permits, gas tests, and life-saving controls have been verified on field.',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                  ),
                  value: confirmedAllChecked,
                  activeColor: AppTheme.tertiary,
                  checkColor: Colors.black87,
                  onChanged: (val) => setDialogState(() => confirmedAllChecked = val ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.tertiary, foregroundColor: Colors.black87),
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('RATIFY & SIGN-OFF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () {
                final compliantCount = _goldenRules.where((r) => r.isCompliant).length;
                final percentage = (compliantCount / _goldenRules.length) * 100.0;
                final hash = 'SHA256: ${(DateTime.now().millisecondsSinceEpoch.toRadixString(16)).toUpperCase()}-ISO45001-RATIFIED';

                setState(() {
                  _goldenRulesSignOff = HseOfficerSignOff(
                    officerName: officerCtrl.text.trim(),
                    badgeId: badgeCtrl.text.trim(),
                    shift: selectedShift,
                    timestamp: DateTime.now(),
                    digitalSignatureHash: hash,
                    compliancePercentage: percentage,
                    latitude: 27.2948,
                    longitude: 95.3214,
                    isRatified: true,
                  );
                });
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.tertiary,
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'HSE Golden Rules clearance officially ratified by ${officerCtrl.text.trim()} ($percentage% compliant)!',
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  // --- ACTIONS & DIALOGS ---

  void _openNearMissReporterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NearMissReporterSheet(
        locationService: _locationService,
        picker: _picker,
        onSubmit: (newReport) {
          setState(() {
            _nearMissReports.insert(0, newReport);
            _openNearMissCount = _nearMissReports.where((r) => r.status == 'OPEN').length;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.tertiary,
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.black87),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Near-Miss [${newReport.id}] logged with GPS watermark. HSE alert dispatched!',
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
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

  void _openSafetyBadgeScannerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _SafetyBadgeScannerSheet(),
    );
  }

  void _showGasTestSignOffDialog(SafetyPermitModel permit) {
    final lelCtrl = TextEditingController(text: '0.0');
    final o2Ctrl = TextEditingController(text: '20.9');
    final h2sCtrl = TextEditingController(text: '0.0');
    final coCtrl = TextEditingController(text: '0');
    final testerCtrl = TextEditingController(text: 'Subhash Roy (Authorized Gas Tester #AGT-44)');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.border, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.gas_meter_rounded, color: AppTheme.secondary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Atmospheric Gas Test Sign-Off',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    permit.id,
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primaryLight, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location: ${permit.location}\nMandatory for Confined Space Entry per OSHA & OISD-105.',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MULTI-GAS DETECTOR SENSOR READINGS',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildGasReadingInput(
                      label: 'Oxygen (O2)',
                      unit: '% vol (19.5-23.5)',
                      controller: o2Ctrl,
                      color: AppTheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildGasReadingInput(
                      label: 'Combustibles (LEL)',
                      unit: '% LEL (< 5.0% safe)',
                      controller: lelCtrl,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildGasReadingInput(
                      label: 'Hydrogen Sulfide',
                      unit: 'H2S ppm (< 5 ppm)',
                      controller: h2sCtrl,
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildGasReadingInput(
                      label: 'Carbon Monoxide',
                      unit: 'CO ppm (< 25 ppm)',
                      controller: coCtrl,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: testerCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Certified AGT Inspector',
                  prefixIcon: Icon(Icons.badge_rounded, color: AppTheme.primaryLight, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppTheme.tertiary, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Atmospheric environment tested 100% breathable and non-explosive.',
                      style: TextStyle(color: AppTheme.tertiary, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tertiary,
              foregroundColor: Colors.black87,
            ),
            icon: const Icon(Icons.verified_user_rounded, size: 18),
            label: const Text('Certify & Approve PTW'),
            onPressed: () {
              setState(() {
                permit.status = PermitStatus.approved;
                // Add gas readings to model
                _permits = _permits.map((p) {
                  if (p.id == permit.id) {
                    return SafetyPermitModel(
                      id: p.id,
                      title: p.title,
                      permitType: p.permitType,
                      location: p.location,
                      issuedTo: p.issuedTo,
                      validTill: 'Today, 18:00 (Post-Gas Clearance)',
                      status: PermitStatus.approved,
                      hazardLevel: p.hazardLevel,
                      safetyChecklist: [
                        ...p.safetyChecklist,
                        'Gas Test Certified: O2 ${o2Ctrl.text}%, LEL ${lelCtrl.text}%, H2S ${h2sCtrl.text}ppm by ${testerCtrl.text}',
                      ],
                      gasTestReadings: {
                        'LEL': '${lelCtrl.text}%',
                        'O2': '${o2Ctrl.text}%',
                        'H2S': '${h2sCtrl.text} ppm',
                        'CO': '${coCtrl.text} ppm',
                      },
                      authorizedOfficer: testerCtrl.text,
                      issuedAt: p.issuedAt,
                      workOrderRef: p.workOrderRef,
                    );
                  }
                  return p;
                }).toList();
              });
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.tertiary,
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Permit [${permit.id}] has been APPROVED for entry following AGT gas sign-off!',
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGasReadingInput({
    required String label,
    required String unit,
    required TextEditingController controller,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.sensors_rounded, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: InputBorder.none,
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              suffixText: unit.split(' ').first,
              suffixStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  void _showPermitPassModal(SafetyPermitModel permit) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DIGITAL PTW GATE PASS',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  permit.id,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            _buildPermitStatusBadge(permit.status),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: AppTheme.border, height: 24),
              // Pass Details Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _buildPassDetailRow('Task / Scope', permit.title),
                    const SizedBox(height: 8),
                    _buildPassDetailRow('Work Location', permit.location),
                    const SizedBox(height: 8),
                    _buildPassDetailRow('Issued To', permit.issuedTo),
                    const SizedBox(height: 8),
                    _buildPassDetailRow('Valid Until', permit.validTill),
                    const SizedBox(height: 8),
                    _buildPassDetailRow('HSE Sign-Off', permit.authorizedOfficer),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Simulated Industrial QR / Security Hash Strip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.surfaceContainerHigh,
                      AppTheme.surfaceCard,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Icon(Icons.qr_code_2_rounded, size: 54, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CRYPTOGRAPHIC VERIFICATION',
                            style: TextStyle(
                              color: AppTheme.tertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'SHA-256: 9b8f-4ac2-7e10-ptw-oil\nGeo-Fenced to Duliajan Unit 4',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Scan with Nirmaan Scanner at Gate',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Export PDF Pass'),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.surfaceCard,
                  content: Text(
                    'Exported ${permit.id} Digital Gate Pass to device storage.',
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPassDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(color: AppTheme.textMuted)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // --- MAIN BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.tertiary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.health_and_safety_rounded, color: AppTheme.tertiary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HSE & Digital PTW Control',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Zero Harm · Industrial Safety Operating System',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Emergency SOS & Clinic Quick Link
          IconButton(
            tooltip: 'Emergency Muster & Site Clinic (#108)',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.emergency_rounded, color: Colors.redAccent, size: 20),
            ),
            onPressed: () {
              _tabController.animateTo(2);
            },
          ),
          // Safety Certificate Scanner Quick Link
          IconButton(
            tooltip: 'Safety Badge & Certificate Scanner',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryLight, size: 20),
            ),
            onPressed: _openSafetyBadgeScannerModal,
          ),
          // Near-Miss Quick Reporter Quick Link
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: IconButton(
              tooltip: 'Report Unsafe Condition / Near-Miss',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
              ),
              onPressed: _openNearMissReporterModal,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment_turned_in_rounded, size: 16),
                  const SizedBox(width: 6),
                  const Text('Active Permits'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_activePermitsCount',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_moderator_rounded, size: 16),
                  SizedBox(width: 6),
                  Text('Issue Digital PTW'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emergency_rounded, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  const Text('Emergency & Clinic'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, size: 16),
                  const SizedBox(width: 6),
                  const Text('Safety Audits'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_safetyAudits.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _buildSafetyKpiHeader(),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildActivePermitsTab(),
            _buildIssueDigitalPtwTab(),
            _buildEmergencyAndClinicTab(),
            _buildSafetyAuditsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Report Near-Miss', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _openNearMissReporterModal,
      ),
    );
  }

  // --- 1. SAFETY KPI HEADER ---

  Widget _buildSafetyKpiHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Status Row
          Row(
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
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.tertiary,
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ZERO LTI THRESHOLD: ACTIVE & COMPLIANT',
                    style: TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: AppTheme.primaryLight, size: 13),
                    SizedBox(width: 4),
                    Text(
                      'ISO 45001 / OISD',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Main KPI Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              return Row(
                children: [
                  // KPI 1: Safe Man-Hours
                  Expanded(
                    flex: isWide ? 3 : 2,
                    child: InkWell(
                      onTap: _showSafeManHoursMilestoneSheet,
                      borderRadius: BorderRadius.circular(10),
                      child: _buildKpiCard(
                        icon: Icons.timer_outlined,
                        iconColor: AppTheme.tertiary,
                        label: 'Safe Man-Hours',
                        value: '$_safeManHoursCount hrs',
                        subtitle: 'Zero LTI Streak',
                        accentColor: AppTheme.tertiary,
                        isInteractive: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // KPI 2: LTIFR
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _showLtifrBreakdownDialog,
                      borderRadius: BorderRadius.circular(10),
                      child: _buildKpiCard(
                        icon: Icons.speed_rounded,
                        iconColor: AppTheme.primaryLight,
                        label: 'LTIFR',
                        value: _ltifr,
                        subtitle: 'World-Class (<0.10)',
                        accentColor: AppTheme.primaryLight,
                        isInteractive: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // KPI 3: Open Near-Miss Reports
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _showOpenNearMissListModal,
                      borderRadius: BorderRadius.circular(10),
                      child: _buildKpiCard(
                        icon: Icons.warning_rounded,
                        iconColor: AppTheme.secondary,
                        label: 'Open Near-Miss',
                        value: '$_openNearMissCount',
                        subtitle: 'Tap to inspect',
                        accentColor: AppTheme.secondary,
                        isInteractive: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // KPI 4: Active Permits to Work
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () => _tabController.animateTo(0),
                      borderRadius: BorderRadius.circular(10),
                      child: _buildKpiCard(
                        icon: Icons.assignment_turned_in_outlined,
                        iconColor: AppTheme.primaryLight,
                        label: 'Active PTWs',
                        value: '$_activePermitsCount',
                        subtitle: 'Live authorized',
                        accentColor: AppTheme.primary,
                        isInteractive: true,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // Emergency Muster & Clinic Quick Banner
          InkWell(
            onTap: () => _tabController.animateTo(2),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.emergency_rounded, color: Colors.redAccent, size: 14),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMERGENCY RESPONSE · NEAREST MUSTER POINT 1',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          '120m North-East (Assembly Plaza) · OHC Clinic Ready (#108)',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryLight, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
    required Color accentColor,
    bool isInteractive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isInteractive ? accentColor.withValues(alpha: 0.4) : AppTheme.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: iconColor, size: 15),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: value.contains('hrs') || value.contains('.') ? 'monospace' : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accentColor,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. TAB 1: ACTIVE PERMITS ---

  Widget _buildActivePermitsTab() {
    final filteredPermits = _permits.where((p) {
      if (_selectedPermitFilter == 'APPROVED' && p.status != PermitStatus.approved) {
        return false;
      }
      if (_selectedPermitFilter == 'PENDING_GAS' && p.status != PermitStatus.pendingGasTest) {
        return false;
      }
      if (_permitSearchQuery.isNotEmpty) {
        final q = _permitSearchQuery.toLowerCase();
        final matches = p.id.toLowerCase().contains(q) ||
            p.title.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q) ||
            p.issuedTo.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter bar & Search
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Search input
              TextField(
                onChanged: (val) => setState(() => _permitSearchQuery = val),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search permit code, welding, scaffolding, tank...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 18),
                  suffixIcon: _permitSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 16),
                          onPressed: () => setState(() => _permitSearchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All Permits (${_permits.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'APPROVED',
                      'Approved (${_permits.where((p) => p.status == PermitStatus.approved).length})',
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'PENDING_GAS',
                      'Pending Gas Test (${_permits.where((p) => p.status == PermitStatus.pendingGasTest).length})',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Permit List
        Expanded(
          child: filteredPermits.isEmpty
              ? const Center(
                  child: Text(
                    'No permits found matching criteria.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filteredPermits.length,
                  itemBuilder: (context, index) {
                    final permit = filteredPermits[index];
                    return _buildPermitCard(permit);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedPermitFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPermitFilter = value);
        }
      },
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.surfaceCard,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryLight : AppTheme.border,
      ),
    );
  }

  Widget _buildPermitCard(SafetyPermitModel permit) {
    final isPendingGas = permit.status == PermitStatus.pendingGasTest;
    final isApproved = permit.status == PermitStatus.approved;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPendingGas
              ? AppTheme.secondary.withValues(alpha: 0.6)
              : AppTheme.border,
          width: isPendingGas ? 1.5 : 1.0,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _getPermitTypeColor(permit.permitType).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getPermitTypeColor(permit.permitType).withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            _getPermitTypeIcon(permit.permitType),
            color: _getPermitTypeColor(permit.permitType),
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Text(
              permit.id,
              style: const TextStyle(
                color: AppTheme.primaryLight,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            _buildPermitStatusBadge(permit.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              permit.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.place_outlined, color: AppTheme.textMuted, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    permit.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: AppTheme.textMuted, size: 13),
                const SizedBox(width: 4),
                Text(
                  'Valid till: ${permit.validTill}',
                  style: TextStyle(
                    color: isApproved ? AppTheme.tertiary : AppTheme.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.group_outlined, color: AppTheme.textMuted, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    permit.issuedTo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(color: AppTheme.border, height: 16),
          // Hazard classification strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CLASSIFICATION: ${permit.hazardLevel}',
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'REF: ${permit.workOrderRef}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Gas Test Readings strip if exists
          if (permit.gasTestReadings != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sensors_rounded, color: AppTheme.tertiary, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'ATMOSPHERIC GAS READINGS (VERIFIED)',
                        style: TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: permit.gasTestReadings!.entries.map((e) {
                      return Column(
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                          ),
                          Text(
                            e.value,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Precautions Checklist
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SAFETY PRECAUTIONS & MANDATORY CONTROLS',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ...permit.safetyChecklist.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Digital Pass QR view
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: AppTheme.primaryLight),
                label: const Text('Digital Pass', style: TextStyle(fontSize: 11)),
                onPressed: () => _showPermitPassModal(permit),
              ),
              const SizedBox(width: 8),

              // If Pending Gas Test -> Direct Sign-off button
              if (isPendingGas)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.gas_meter_rounded, size: 16),
                  label: const Text(
                    'Sign-Off Gas Test',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showGasTestSignOffDialog(permit),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text(
                    'Inspect PTW',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showPermitPassModal(permit),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermitStatusBadge(PermitStatus status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case PermitStatus.approved:
        bg = AppTheme.tertiary.withValues(alpha: 0.18);
        fg = AppTheme.tertiary;
        text = 'APPROVED';
        break;
      case PermitStatus.pendingGasTest:
        bg = AppTheme.secondary.withValues(alpha: 0.18);
        fg = AppTheme.secondary;
        text = 'PENDING GAS TEST';
        break;
      case PermitStatus.underReview:
        bg = AppTheme.primary.withValues(alpha: 0.18);
        fg = AppTheme.primaryLight;
        text = 'UNDER REVIEW';
        break;
      case PermitStatus.closed:
        bg = AppTheme.textMuted.withValues(alpha: 0.18);
        fg = AppTheme.textMuted;
        text = 'CLOSED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  IconData _getPermitTypeIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('hot')) return Icons.local_fire_department_rounded;
    if (t.contains('height')) return Icons.terrain_rounded;
    if (t.contains('confined')) return Icons.cyclone_rounded;
    if (t.contains('electrical')) return Icons.flash_on_rounded;
    if (t.contains('excavation')) return Icons.engineering_rounded;
    if (t.contains('radio')) return Icons.warning_rounded;
    if (t.contains('lift')) return Icons.precision_manufacturing_rounded;
    return Icons.assignment_rounded;
  }

  Color _getPermitTypeColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('hot')) return AppTheme.secondary;
    if (t.contains('height')) return AppTheme.primaryLight;
    if (t.contains('confined')) return AppTheme.error;
    if (t.contains('electrical')) return Colors.amberAccent;
    if (t.contains('excavation')) return Colors.deepOrangeAccent;
    if (t.contains('radio')) return Colors.purpleAccent;
    if (t.contains('lift')) return AppTheme.tertiary;
    return AppTheme.primary;
  }

  // --- 3. TAB 2: ISSUE DIGITAL PTW ---

  Widget _buildIssueDigitalPtwTab() {
    return _IssueDigitalPtwForm(
      onPermitCreated: (newPermit) {
        setState(() {
          _permits.insert(0, newPermit);
          _activePermitsCount = _permits.where((p) => p.status != PermitStatus.closed).length;
        });
        _tabController.animateTo(0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.tertiary,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Digital PTW [${newPermit.id}] successfully issued & authenticated!',
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ),
        );
        _showPermitPassModal(newPermit);
      },
    );
  }

  // --- 4. TAB 3: EMERGENCY MUSTER POINT LOCATOR & SITE CLINIC ---

  Widget _buildEmergencyAndClinicTab() {
    final nearestMuster = _musterPoints.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // 1. Meteorological & Emergency Siren Warning Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isSirenActive
                  ? [Colors.red.shade900.withValues(alpha: 0.8), AppTheme.surfaceCard]
                  : [AppTheme.surfaceContainerHigh, AppTheme.surfaceCard],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isSirenActive ? Colors.redAccent : AppTheme.border,
              width: _isSirenActive ? 1.5 : 1.0,
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
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _isSirenActive ? Colors.redAccent : AppTheme.tertiary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _isSirenActive ? Colors.redAccent : AppTheme.tertiary,
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isSirenActive
                            ? 'EMERGENCY EVACUATION / DRILL ACTIVE'
                            : 'SITE HSE CONDITION: LEVEL 1 (NORMAL)',
                        style: TextStyle(
                          color: _isSirenActive ? Colors.redAccent : AppTheme.tertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Text(
                      'OSHA 1910.38 / OISD',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.air_rounded, color: AppTheme.primaryLight, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WIND SENSOR: 14.2 km/h from South-West (210°)',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'UPWIND EVACUATION ADVISORY: In case of toxic gas release (H2S) or smoke, all personnel must evacuate UPWIND towards North Gate (Point 1).',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    tooltip: 'Simulate Gas Release Drill',
                    onSelected: _injectGasScenario,
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'NORMAL', child: Text('Normal Baseline (0 ppm)')),
                      const PopupMenuItem(value: 'H2S_LEAK', child: Text('⚠️ Inject H2S Leak (14.8 ppm)')),
                      const PopupMenuItem(value: 'LEL_SURGE', child: Text('🔥 Inject LEL Flammable Surge')),
                      const PopupMenuItem(value: 'O2_DEFICIENT', child: Text('💨 Inject O2 Deficiency (16.2%)')),
                      const PopupMenuItem(value: 'BUMP_TEST', child: Text('✅ Run Bump Test Calibration')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.science_rounded, size: 14, color: AppTheme.primaryLight),
                          const SizedBox(width: 4),
                          Text('Gas Drill: $_activeGasScenario', style: const TextStyle(fontSize: 11, color: AppTheme.primaryLight, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isSirenActive ? Colors.redAccent : AppTheme.primaryLight,
                      side: BorderSide(color: _isSirenActive ? Colors.redAccent : AppTheme.border),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: Icon(_isSirenActive ? Icons.notifications_off_rounded : Icons.campaign_rounded, size: 16),
                    label: Text(
                      _isSirenActive ? 'Silence Site Siren' : 'Test Muster Siren',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _showSoundSirenDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Nearest Emergency Muster Point Hero Card
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.tertiary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.navigation_rounded, color: AppTheme.tertiary, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'NEAREST MUSTER POINT LOCATOR',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          nearestMuster.code,
                          style: const TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'UPWIND · SAFE',
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.directions_walk_rounded, color: AppTheme.tertiary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${nearestMuster.distanceMeters}m (${nearestMuster.walkingTime})',
                        style: const TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                nearestMuster.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                nearestMuster.locationDescription,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 12),

              // Headcount & Bearing Quick Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BEARING / HEADING', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                          const SizedBox(height: 2),
                          Text(
                            nearestMuster.bearing,
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('HEADCOUNT / CAPACITY', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                          const SizedBox(height: 2),
                          Text(
                            '$_checkedInMusterCount / ${nearestMuster.capacity} Pax',
                            style: const TextStyle(
                              color: AppTheme.tertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.explore_rounded, size: 16),
                      label: const Text('Evacuation Route', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _showEvacuationRouteModal(nearestMuster),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.how_to_reg_rounded, size: 16, color: AppTheme.tertiary),
                      label: const Text('Live Roll Call', style: TextStyle(fontSize: 11)),
                      onPressed: () => _showRollCallModal(nearestMuster),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Other Site Muster Stations List
        const Text(
          'ALL DESIGNATED SITE MUSTER STATIONS',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),

        ..._musterPoints.map((point) => _buildMusterPointCard(point)),
        const SizedBox(height: 20),

        // 4. Site Clinic & OHC Contact Card
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.local_hospital_rounded, color: Colors.redAccent, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'SITE CLINIC & OCCUPATIONAL HEALTH CENTRE',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildSiteClinicCard(_siteClinic),
      ],
    );
  }

  Widget _buildMusterPointCard(MusterPointModel point) {
    Color statusColor;
    String statusLabel;
    switch (point.status) {
      case 'SAFE':
        statusColor = AppTheme.tertiary;
        statusLabel = 'SAFE ZONE';
        break;
      case 'STANDBY':
        statusColor = AppTheme.secondary;
        statusLabel = 'STANDBY';
        break;
      default:
        statusColor = AppTheme.error;
        statusLabel = 'DOWNWIND CAUTION';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                  Text(
                    point.id,
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Text(
                '${point.distanceMeters}m · ${point.walkingTime}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            point.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            point.locationDescription,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: point.emergencyEquipment.map((eq) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  eq,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Capacity: ${point.capacity} Pax',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryLight,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.directions, size: 14),
                label: const Text('View Route Guide', style: TextStyle(fontSize: 11)),
                onPressed: () => _showEvacuationRouteModal(point),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSiteClinicCard(SiteClinicModel clinic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.medical_services_rounded, color: Colors.redAccent, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinic.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            clinic.location,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  '24x7 OHC ON-DUTY',
                  style: TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 22),

          // Medical Staff on Duty
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_rounded, color: AppTheme.primaryLight, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Physician: ${clinic.medicalOfficer}',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.healing_rounded, color: AppTheme.secondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Senior Paramedic: ${clinic.paramedicOnDuty}',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.speed_rounded, color: AppTheme.tertiary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Field Emergency Response SLA: ${clinic.responseTimeSla}',
                        style: const TextStyle(color: AppTheme.tertiary, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Standby Ambulance Status Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.airport_shuttle_rounded, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ALS AMBULANCE: ${clinic.ambulanceStatus}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Standby Medical Supplies Chips
          const Text(
            'FIELD CRITICAL MEDICAL EQUIPMENT ON STANDBY:',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: clinic.standbyEquipment.map((eq) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  eq,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 3 Big Emergency Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text('Call #108 Hotline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _showClinicCallDialog(clinic),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.emergency_rounded, size: 16),
                  label: const Text('Dispatch ALS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _showEmergencyDispatchModal(clinic),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.border),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.people_outline_rounded, size: 16, color: AppTheme.tertiary),
              label: const Text('View Certified Site First-Aiders Roster', style: TextStyle(fontSize: 11)),
              onPressed: () => _showFirstAidersModal(clinic.firstAiders),
            ),
          ),
        ],
      ),
    );
  }

  void _showClinicCallDialog(SiteClinicModel clinic) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text(
              'Call Site Clinic Emergency',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select an emergency line to connect immediately:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Internal Site Speed Dial:', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      Text(
                        clinic.speedDial,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.border, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('External Telecom Line:', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      Text(
                        clinic.emergencyHotline,
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppTheme.tertiary, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Direct line to Dr. Baruah & Trauma Nurse on Duty.',
                    style: TextStyle(color: AppTheme.tertiary, fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Dial #108 Now'),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Connecting to Site Clinic OHC via Intercom ${clinic.speedDial}...',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEmergencyDispatchModal(SiteClinicModel clinic) {
    String selectedTrauma = 'Fall from Height (>1.8m)';
    int casualtyCount = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: Colors.redAccent, width: 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'DISPATCH ADVANCED LIFE SUPPORT (ALS)',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Auto-locked location
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.my_location_rounded, color: AppTheme.tertiary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DISPATCH LOCATION (GPS GEOFENCE LOCKED)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
                          Text('Unit 4 Process Block (27.2948° N, 95.3214° E)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('NATURE OF MEDICAL EMERGENCY', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedTrauma,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceCard,
                    items: [
                      'Fall from Height (>1.8m)',
                      'Hot Work Burn / Arc Flash',
                      'Toxic Gas / H2S Inhalation',
                      'Electrical Shock / Arc Blast',
                      'Crush Injury / Caught-Between',
                      'Cardiac / Unresponsive Worker',
                    ].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedTrauma = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Casualties:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Row(
                    children: [1, 2, 3, 5].map((count) {
                      final isSelected = casualtyCount == count;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text('$count'),
                          selected: isSelected,
                          selectedColor: Colors.redAccent,
                          backgroundColor: AppTheme.surfaceCard,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                          onSelected: (_) => setModalState(() => casualtyCount = count),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'DISPATCH AMBULANCE NOW (ETA < 2 MINS)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.6),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 5),
                        content: Row(
                          children: [
                            const Icon(Icons.airport_shuttle_rounded, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'ALS Ambulance Unit 01 dispatched to Unit 4! Driver Raju Sonowal en route. ETA 2:00 mins.',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
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

  void _showEvacuationRouteModal(MusterPointModel point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppTheme.tertiary, width: 2)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_run_rounded, color: AppTheme.tertiary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Evacuation Route Guide · ${point.code}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                        Text('${point.name} · ${point.distanceMeters}m (${point.walkingTime})', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildEvacStep(
                    stepNum: '1',
                    title: 'Stop Work & Safe Shutdown',
                    desc: 'Immediately extinguish hot work torches, lock welding rigs, and safely isolate localized tools.',
                    color: AppTheme.primaryLight,
                  ),
                  _buildEvacStep(
                    stepNum: '2',
                    title: 'Descend via Fixed North Stairwell',
                    desc: 'Do NOT use motorized hoists or lifts. Walk down North Emergency Stairwell with hand on rail.',
                    color: AppTheme.secondary,
                  ),
                  _buildEvacStep(
                    stepNum: '3',
                    title: 'Follow Illuminated Green Walkway',
                    desc: 'Follow photoluminescent floor strip along Pipeline Corridor A. Keep Substation SS-02 on your left.',
                    color: AppTheme.tertiary,
                  ),
                  _buildEvacStep(
                    stepNum: '4',
                    title: 'Report to Assembly Flag A',
                    desc: 'Proceed through North Turnstile to Muster Plaza. Report to Muster Captain Subhash Roy for roll call.',
                    color: AppTheme.tertiary,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.secondary),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppTheme.secondary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'WIND CAUTION: Stay UPWIND of Flare Stack Unit 4. Do not traverse through trench excavations during alarm.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tertiary,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('I Have Reached Muster Point (Check In)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        if (!_isUserCheckedInAtMuster) {
                          _checkedInMusterCount++;
                          _isUserCheckedInAtMuster = true;
                        }
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.tertiary,
                          content: Text(
                            'You have been checked in as SAFE at ${point.name}. Headcount updated.',
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvacStep({
    required String stepNum,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(
              stepNum,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRollCallModal(MusterPointModel point) {
    final workers = [
      {'name': 'Subhash Roy', 'badge': 'HSE-001', 'trade': 'HSE Lead', 'status': 'CHECKED IN'},
      {'name': 'Tapan Das', 'badge': 'WLD-402', 'trade': 'Master Welder', 'status': 'CHECKED IN'},
      {'name': 'Biren Gogoi', 'badge': 'SCF-108', 'trade': 'Lead Scaffolder', 'status': 'CHECKED IN'},
      {'name': 'Subrat Mohanty', 'badge': 'ELC-204', 'trade': 'HV Electrician', 'status': 'CHECKED IN'},
      {'name': 'Vikram Joshi', 'badge': 'PIP-105', 'trade': 'Piping Supervisor', 'status': 'CHECKED IN'},
      {'name': 'Manish Deka', 'badge': 'CIV-309', 'trade': 'Civil Foreman', 'status': 'EN ROUTE'},
      {'name': 'Deepak Bora', 'badge': 'RIG-221', 'trade': 'Crane Operator', 'status': 'CHECKED IN'},
      {'name': 'Animesh Roy', 'badge': 'NDT-044', 'trade': 'QA/QC Inspector', 'status': 'EN ROUTE'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emergency Headcount · ${point.code}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('$_checkedInMusterCount Checked In · 2 En Route', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('97.6% SAFE', style: TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: workers.length,
                itemBuilder: (context, idx) {
                  final w = workers[idx];
                  final isPresent = w['status'] == 'CHECKED IN';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: isPresent ? AppTheme.tertiary.withValues(alpha: 0.2) : AppTheme.secondary.withValues(alpha: 0.2),
                              child: Text(w['name']!.substring(0, 1), style: TextStyle(color: isPresent ? AppTheme.tertiary : AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(w['name']!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('${w['badge']} · ${w['trade']}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPresent ? AppTheme.tertiary.withValues(alpha: 0.15) : AppTheme.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            w['status']!,
                            style: TextStyle(color: isPresent ? AppTheme.tertiary : AppTheme.secondary, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
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

  void _showFirstAidersModal(List<FirstAiderModel> firstAiders) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.70,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.health_and_safety_rounded, color: AppTheme.tertiary, size: 22),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Certified Site First-Aiders Roster', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('On-duty emergency first response squad', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: firstAiders.length,
                itemBuilder: (context, idx) {
                  final fa = firstAiders[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
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
                            Text(fa.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(fa.badgeNumber, style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('${fa.trade} · Stationed at ${fa.location}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        const SizedBox(height: 6),
                        Text(fa.certification, style: const TextStyle(color: AppTheme.tertiary, fontSize: 10)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.radio_rounded, color: AppTheme.primaryLight, size: 14),
                              const SizedBox(width: 6),
                              Text(fa.contactExtension, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
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

  void _showSoundSirenDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        title: Row(
          children: [
            Icon(
              _isSirenActive ? Icons.notifications_off_rounded : Icons.campaign_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              _isSirenActive ? 'Silence Site Siren' : 'Activate Site Muster Siren',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          _isSirenActive
              ? 'This will deactivate the continuous two-tone plant emergency siren and resume Normal Operations (Level 1).'
              : 'WARNING: This triggers the high-decibel site emergency evacuation alarm across all 4 Process Units. All personnel will cease work and muster.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _isSirenActive = !_isSirenActive;
              });
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: _isSirenActive ? Colors.redAccent : AppTheme.tertiary,
                  content: Text(
                    _isSirenActive
                        ? 'SIREN ACTIVATED! Emergency broadcast transmitted across all site radio frequencies.'
                        : 'Site siren silenced. Plant status returned to Level 1 Normal Operations.',
                    style: TextStyle(color: _isSirenActive ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            child: Text(_isSirenActive ? 'Confirm Silence' : 'Activate Siren'),
          ),
        ],
      ),
    );
  }

  // --- 4. TAB 3: SAFETY AUDITS ---

  Widget _buildSafetyAuditsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Compliance Overview Scorecard
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppTheme.surfaceContainerHigh,
                AppTheme.surfaceCard,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              // Radial / Percentage Display
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.background,
                  border: Border.all(color: AppTheme.tertiary, width: 3),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '98.4%',
                      style: TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'HSE Pass',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIELD SAFETY AUDIT RATING',
                      style: TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Zero Stop-Work Notices Issued\nASTM / API / OSHA Protocols Active',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Next Mandatory Site Walk: Tomorrow 08:30 IST',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Digital HSE Officer Sign-Off Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _goldenRulesSignOff != null ? AppTheme.tertiary.withValues(alpha: 0.5) : AppTheme.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_goldenRulesSignOff != null ? AppTheme.tertiary : AppTheme.primaryLight).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: _goldenRulesSignOff != null ? AppTheme.tertiary : AppTheme.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _goldenRulesSignOff != null ? 'HSE OFFICER SIGN-OFF RATIFIED' : 'DAILY IOGP/OISD SIGN-OFF',
                      style: TextStyle(
                        color: _goldenRulesSignOff != null ? AppTheme.tertiary : AppTheme.primaryLight,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _goldenRulesSignOff != null
                          ? '${_goldenRulesSignOff!.officerName} (${_goldenRulesSignOff!.badgeId})'
                          : '10 Life-Saving Rules compliance sign-off pending',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                ),
                onPressed: _showGoldenRulesSignOffDialog,
                child: Text(
                  _goldenRulesSignOff != null ? 'Re-verify' : 'Sign Off',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RECENT SAFETY INSPECTIONS & PROTOCOLS',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryLight,
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Log Audit Walk', style: TextStyle(fontSize: 12)),
              onPressed: _showLogAuditDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),

        ..._safetyAudits.map((audit) => _buildSafetyAuditCard(audit)),
      ],
    );
  }

  Widget _buildSafetyAuditCard(SafetyAuditModel audit) {
    final isFullPass = audit.status == 'PASS';

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    audit.id,
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isFullPass
                          ? AppTheme.tertiary.withValues(alpha: 0.15)
                          : AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      audit.status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: isFullPass ? AppTheme.tertiary : AppTheme.secondary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '${audit.complianceScore.toStringAsFixed(1)}% Score',
                style: TextStyle(
                  color: isFullPass ? AppTheme.tertiary : AppTheme.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            audit.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Standard: ${audit.standardCode} · ${audit.location}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          const Text(
            'Auditor Observations & Compliance Verification:',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...audit.findings.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppTheme.primaryLight, fontSize: 12)),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Auditor: ${audit.auditorName}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              ),
              Text(
                DateFormat('dd MMM yyyy · HH:mm').format(audit.date),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogAuditDialog() {
    final titleCtrl = TextEditingController(text: 'Routine PPE & Tool Tethering Field Inspection');
    final locCtrl = TextEditingController(text: 'Unit 4 Elevation & Flare Perimeter');
    final findingsCtrl = TextEditingController(text: 'All riggers wearing chin straps and tool lanyards.');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Log Safety Audit Walk',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Inspection Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Location / Work Zone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: findingsCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Key Findings & Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              final newAudit = SafetyAuditModel(
                id: 'AUD-HSE-${109 + _safetyAudits.length}',
                title: titleCtrl.text.trim(),
                standardCode: 'ISO 45001 / Site Rule 4',
                location: locCtrl.text.trim(),
                auditorName: 'Field Safety Officer',
                date: DateTime.now(),
                status: 'PASS',
                complianceScore: 100.0,
                findings: [findingsCtrl.text.trim()],
              );
              setState(() {
                _safetyAudits.insert(0, newAudit);
              });
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.tertiary,
                  content: Text(
                    'Safety audit record saved to HSE compliance ledger.',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              );
            },
            child: const Text('Save Audit Record'),
          ),
        ],
      ),
    );
  }

  // --- 5. OPEN NEAR-MISS REPORTS MODAL ---

  void _showOpenNearMissListModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Open Near-Miss Reports (${_nearMissReports.length})',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primaryLight),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Report'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openNearMissReporterModal();
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _nearMissReports.length,
                itemBuilder: (context, index) {
                  final r = _nearMissReports[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                            Text(
                              r.id,
                              style: const TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${r.severity} SEVERITY',
                                style: const TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.hazardCategory,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.description,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'IMMEDIATE CORRECTIVE ACTION TAKEN:',
                                style: TextStyle(
                                  color: AppTheme.tertiary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.immediateActionTaken,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, color: AppTheme.textMuted, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  r.location.split('(').first.trim(),
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                            Text(
                              'By ${r.reporterName.split('(').first.trim()}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            ),
                          ],
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

// ==============================================================================
// 6. NEAR-MISS QUICK REPORTER SHEET (PHOTO, GEO-LOCATION, HAZARD, IMMEDIATE ACTION)
// ==============================================================================

class _NearMissReporterSheet extends StatefulWidget {
  final LocationService locationService;
  final ImagePicker picker;
  final ValueChanged<NearMissReportModel> onSubmit;

  const _NearMissReporterSheet({
    required this.locationService,
    required this.picker,
    required this.onSubmit,
  });

  @override
  State<_NearMissReporterSheet> createState() => _NearMissReporterSheetState();
}

class _NearMissReporterSheetState extends State<_NearMissReporterSheet> {
  final _descCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'Duliajan Oil Expansion Trunk, Unit 4');

  String _selectedHazardCategory = 'Working at Height';
  String _selectedSeverity = 'MEDIUM';
  String? _capturedPhotoPath;
  String _geoCoordinates = '27.2948° N, 95.3214° E (Auto-tagged)';
  double _lat = 27.2948;
  double _lng = 95.3214;
  bool _isLocating = false;

  final List<String> _hazardCategories = [
    'Working at Height',
    'Hot Work / Fire Hazard',
    'Dropped Object',
    'Confined Space / Gas',
    'Excavation & Trenching',
    'Electrical Hazard',
    'Heavy Lifting / Rigging',
    'Chemical / Toxic Splash',
    'Slip, Trip & Fall',
  ];

  @override
  void initState() {
    super.initState();
    _fetchGeoLocation();
  }

  Future<void> _fetchGeoLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await widget.locationService.getCurrentPosition();
      if (pos != null && mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _geoCoordinates =
              '${pos.latitude.toStringAsFixed(5)}° N, ${pos.longitude.toStringAsFixed(5)}° E';
        });
      }
    } catch (_) {
      // Fallback default coordinates within project boundary
      if (mounted) {
        setState(() {
          _geoCoordinates = '27.2948° N, 95.3214° E (Site Geofence Locked)';
        });
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _capturePhoto(ImageSource source) async {
    try {
      final file = await widget.picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        setState(() {
          _capturedPhotoPath = file.path;
        });
      }
    } catch (_) {
      // Simulated sample photo path for environments without camera access
      if (mounted) {
        setState(() {
          _capturedPhotoPath = 'simulated_photo_evidence.jpg';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.surfaceCard,
            content: Text(
              'Sample high-resolution photo evidence attached with digital watermark.',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        );
      }
    }
  }

  void _submitReport() {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.error,
          content: Text('Please describe the unsafe situation or near-miss observation.'),
        ),
      );
      return;
    }

    if (_actionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.error,
          content: Text('Please state the immediate corrective action taken.'),
        ),
      );
      return;
    }

    final newReport = NearMissReportModel(
      id: 'NMR-2026-00${DateTime.now().millisecondsSinceEpoch % 1000}',
      hazardCategory: _selectedHazardCategory,
      location: '${_locationCtrl.text.trim()} ($_geoCoordinates)',
      description: _descCtrl.text.trim(),
      immediateActionTaken: _actionCtrl.text.trim(),
      photoPath: _capturedPhotoPath,
      severity: _selectedSeverity,
      reporterName: 'Field Safety Officer (Subhash Roy)',
      timestamp: DateTime.now(),
      latitude: _lat,
      longitude: _lng,
      status: 'OPEN',
    );

    widget.onSubmit(newReport);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: AppTheme.secondary, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Near-Miss Quick Reporter',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Zero-Penalty Industrial Reporting Protocol',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.border, height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Hazard Category Dropdown
                const Text(
                  '1. HAZARD CATEGORY',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedHazardCategory,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceCard,
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryLight),
                      items: _hazardCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(
                            cat,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedHazardCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Potential Consequence / Severity
                const Text(
                  '2. SEVERITY / POTENTIAL RISK LEVEL',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildSeverityChoice('LOW', AppTheme.tertiary),
                    const SizedBox(width: 8),
                    _buildSeverityChoice('MEDIUM', AppTheme.secondary),
                    const SizedBox(width: 8),
                    _buildSeverityChoice('HIGH', Colors.deepOrangeAccent),
                    const SizedBox(width: 8),
                    _buildSeverityChoice('CRITICAL', AppTheme.error),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Geo-Location & Site Area
                const Text(
                  '3. GEO-LOCATION & SITE COORDINATES',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.my_location_rounded, color: AppTheme.primaryLight, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _geoCoordinates,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          if (_isLocating)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            InkWell(
                              onTap: _fetchGeoLocation,
                              child: const Text(
                                'Refresh',
                                style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _locationCtrl,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Specific landmark or chainage (e.g. Flare Column 4)',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Description of Incident
                const Text(
                  '4. OBSERVATION / NEAR-MISS DESCRIPTION',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText:
                        'State clearly what happened or what unsafe condition was discovered...',
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Immediate Corrective Action Taken
                const Text(
                  '5. IMMEDIATE CORRECTIVE ACTION TAKEN',
                  style: TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _actionCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Work halted immediately, 10m exclusion barricade erected, safety harness replaced...',
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Photo Evidence Attachment
                const Text(
                  '6. PHOTO EVIDENCE (WATERMARKED)',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                if (_capturedPhotoPath != null)
                  Container(
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.tertiary),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: _capturedPhotoPath!.endsWith('.jpg') &&
                                  !_capturedPhotoPath!.contains('/')
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_outlined, size: 40, color: AppTheme.tertiary),
                                    SizedBox(height: 4),
                                    Text(
                                      'Photo Captured · Evidence Attached',
                                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                                    ),
                                  ],
                                )
                              : Image.file(
                                  File(_capturedPhotoPath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                        ),
                        // HUD Watermark overlay
                        Positioned(
                          bottom: 6,
                          left: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            color: Colors.black.withValues(alpha: 0.75),
                            child: Text(
                              '[NMA-HSE-GEO] $_geoCoordinates · ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                              style: const TextStyle(
                                color: AppTheme.tertiary,
                                fontSize: 9,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.white70, size: 20),
                            onPressed: () => setState(() => _capturedPhotoPath = null),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Take Photo', style: TextStyle(fontSize: 12)),
                          onPressed: () => _capturePhoto(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                          onPressed: () => _capturePhoto(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'SUBMIT NEAR-MISS REPORT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                  ),
                  onPressed: _submitReport,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChoice(String level, Color color) {
    final isSelected = _selectedSeverity == level;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedSeverity = level),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppTheme.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              level,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// 7. REQUEST NEW PTW FORM (ACTIVE PERMITS TAB 2)
// ==============================================================================

// ==============================================================================
// 7. INTERACTIVE 'ISSUE DIGITAL PTW' FORM (HOT WORK, HEIGHT, CONFINED SPACE)
// ==============================================================================

class _IssueDigitalPtwForm extends StatefulWidget {
  final ValueChanged<SafetyPermitModel> onPermitCreated;

  const _IssueDigitalPtwForm({required this.onPermitCreated});

  @override
  State<_IssueDigitalPtwForm> createState() => _IssueDigitalPtwFormState();
}

class _IssueDigitalPtwFormState extends State<_IssueDigitalPtwForm> {
  String _selectedPermitType = 'Hot Work';
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _issuedToCtrl = TextEditingController();
  final _workOrderCtrl = TextEditingController();
  final _officerCtrl = TextEditingController(text: 'Subhash Roy (Lead HSE Officer #HSE-001)');
  final _supervisorCtrl = TextEditingController(text: 'Tapan Das (Permit Receiver / Foreman)');

  String _validHours = '8 Hours (Full Shift)';

  // Multi-Gas Atmospheric Readings
  final _o2Ctrl = TextEditingController(text: '20.9');
  final _lelCtrl = TextEditingController(text: '0.0');
  final _h2sCtrl = TextEditingController(text: '0.0');
  final _coCtrl = TextEditingController(text: '0');
  final _agtCtrl = TextEditingController(text: 'Subhash Roy (#AGT-44)');
  String _gasElevationLevel = 'Middle (Work Deck Level)';

  late List<PtwChecklistItem> _checklist;

  @override
  void initState() {
    super.initState();
    _loadChecklistForType(_selectedPermitType);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _issuedToCtrl.dispose();
    _workOrderCtrl.dispose();
    _officerCtrl.dispose();
    _supervisorCtrl.dispose();
    _o2Ctrl.dispose();
    _lelCtrl.dispose();
    _h2sCtrl.dispose();
    _coCtrl.dispose();
    _agtCtrl.dispose();
    super.dispose();
  }

  void _loadChecklistForType(String type) {
    if (type == 'Hot Work') {
      _titleCtrl.text = 'Flare Header Tie-in Welding & Pipe Spool Fit-up';
      _locationCtrl.text = 'Unit 4 Flare Header & Tie-in Line 24 (Elevation +6.5m)';
      _issuedToCtrl.text = 'Tapan Das & Pipe Welding Gang A';
      _workOrderCtrl.text = 'WO-FLARE-024';
      _checklist = [
        PtwChecklistItem(
          id: 'HW-01',
          title: 'Combustibles & flammables cleared within 11m (35 ft) or covered with FM-approved fire blankets',
          standardRef: 'NFPA 51B §5.2',
          isMandatory: true,
          isVerified: true,
          verifiedBy: _officerCtrl.text,
          verifiedAt: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
        PtwChecklistItem(
          id: 'HW-02',
          title: 'Dedicated Continuous Fire Watch appointed with 2x 10kg DCP & CO2 extinguishers at station',
          standardRef: 'OISD-105 Cl. 7.1',
          isMandatory: true,
          isVerified: true,
          verifiedBy: _officerCtrl.text,
          verifiedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
        PtwChecklistItem(
          id: 'HW-03',
          title: 'Combustible gas sniff test verified 0.0% LEL prior to strike/ignition by certified AGT',
          standardRef: 'OSHA 1926.352',
          isMandatory: true,
          isVerified: true,
          verifiedBy: _officerCtrl.text,
          verifiedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        PtwChecklistItem(
          id: 'HW-04',
          title: 'Welding transformer grounded, cables undamaged, and 30mA ELCB/RCCB verified',
          standardRef: 'IS 3043 / CEA Rules',
          isMandatory: true,
          isVerified: false,
        ),
        PtwChecklistItem(
          id: 'HW-05',
          title: 'Spark containment habitat & flame-retardant welding enclosure erected around elevation',
          standardRef: 'OISD-GDN-192',
          isMandatory: true,
          isVerified: false,
        ),
        PtwChecklistItem(
          id: 'HW-06',
          title: 'Pressurized fire water hose connected from hydrant station #H-04 and tested',
          standardRef: 'NFPA 14',
          isMandatory: true,
          isVerified: false,
        ),
        PtwChecklistItem(
          id: 'HW-07',
          title: 'Mandatory 60-minute post-work continuous fire watch monitoring logged',
          standardRef: 'NFPA 51B §5.6',
          isMandatory: true,
          isVerified: false,
        ),
      ];
    } else if (type == 'Working at Height') {
      _titleCtrl.text = 'Scaffolding Unit 4 Column C40 Erection & Planking';
      _locationCtrl.text = 'Unit 4 Column C40 Structure (+18.5m elevation)';
      _issuedToCtrl.text = 'Assam Scaffolding Erectors & Rigging Crew';
      _workOrderCtrl.text = 'WO-SCAF-108';
      _checklist = [
        PtwChecklistItem(
          id: 'WAH-01',
          title: 'Scaffold Green Tag inspection signed by Competent Person within last 7 days',
          standardRef: 'OSHA 1926.451 / OISD-192',
          isMandatory: true,
          isVerified: true,
          verifiedBy: _officerCtrl.text,
          verifiedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        PtwChecklistItem(
          id: 'WAH-02',
          title: 'Full-body safety harness (IS 3521 / EN 361) with dual shock lanyards (100% tie-off mandatory)',
          standardRef: 'OSHA 1926 Subpart M',
          isMandatory: true,
          isVerified: true,
          verifiedBy: _officerCtrl.text,
          verifiedAt: DateTime.now().subtract(const Duration(minutes: 22)),
        ),
        PtwChecklistItem(
          id: 'WAH-03',
          title: 'Tool tethering wrist lanyards attached to all hand tools to prevent dropped objects',
          standardRef: 'ANSI/ISEA 121',
          isMandatory: true,
          isVerified: true,
          verifiedBy: _officerCtrl.text,
          verifiedAt: DateTime.now().subtract(const Duration(minutes: 18)),
        ),
        PtwChecklistItem(
          id: 'WAH-04',
          title: 'Guardrail system (42" top-rail, 21" mid-rail, 4" toe-boards) fully secured on work platform',
          standardRef: 'OSHA 1926.502',
          isMandatory: true,
          isVerified: false,
        ),
        PtwChecklistItem(
          id: 'WAH-05',
          title: 'Exclusion drop-zone barricaded below with high-vis red danger overhead warning tape',
          standardRef: 'OISD-GDN-192',
          isMandatory: true,
          isVerified: false,
        ),
        PtwChecklistItem(
          id: 'WAH-06',
          title: 'Digital anemometer verified wind speed below 9.8 m/s (22 mph); zero gust risk',
          standardRef: 'ASME B30.5',
          isMandatory: true,
          isVerified: false,
        ),
        PtwChecklistItem(
          id: 'WAH-07',
          title: 'Engineered anchor points load-tested and certified for 22.2 kN (5,000 lbs)',
          standardRef: 'OSHA 1926.502(d)',
          isMandatory: true,
          isVerified: false,
        ),
      ];
    } else if (type == 'Confined Space') {
      _titleCtrl.text = 'Crude Storage Tank 102 Internal Hydro-Cleanout & NDT';
      _locationCtrl.text = 'Tank 102 Internal Crude Storage Shell & Sump (Bay 3)';
      _issuedToCtrl.text = 'NDT Inspection Squad & Tank Cleanout Crew';
      _workOrderCtrl.text = 'WO-TNK-102';
      _checklist = [
        PtwChecklistItem(
          id: 'CSE-01',
          title: 'Atmospheric 4-gas sniff test passed at Top, Middle, Bottom (O2: 19.5-23.5%, LEL: 0%, H2S: 0, CO: 0)',
          standardRef: 'OSHA 1910.146',
          isMandatory: true,
          isVerified: true,
          verifiedBy: _officerCtrl.text,
          verifiedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        PtwChecklistItem(
          id: 'CSE-02',
          title: 'Continuous positive mechanical forced ventilation running minimum 60 mins before entry',
          standardRef: 'OISD-GDN-114',
          isMandatory: true,
          isVerified: true,
          verifiedBy: _officerCtrl.text,
          verifiedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        PtwChecklistItem(
          id: 'CSE-03',
          title: 'Physical positive isolation with spectacle blind & double block and bleed verified',
          standardRef: 'API 2015 / OISD-105',
          isMandatory: true,
          isVerified: false,
        ),
        PtwChecklistItem(
          id: 'CSE-04',
          title: 'Certified Standby Man stationed at manhole entrance with continuous entrant logbook',
          standardRef: 'OSHA 1910.146(k)',
          isMandatory: true,
          isVerified: false,
        ),
        PtwChecklistItem(
          id: 'CSE-05',
          title: 'SCBA (30-min Self-Contained Breathing Apparatus) on standby at entrance',
          standardRef: 'NIOSH / IS 10245',
          isMandatory: true,
          isVerified: false,
        ),
        PtwChecklistItem(
          id: 'CSE-06',
          title: 'Man-rated rescue tripod, mechanical recovery winch, and harness lifeline rigged',
          standardRef: 'ANSI Z117.1',
          isMandatory: true,
          isVerified: false,
        ),
        PtwChecklistItem(
          id: 'CSE-07',
          title: 'Intrinsically safe 24V explosion-proof lighting and ATEX Zone 0 radio deployed',
          standardRef: 'IS/IEC 60079',
          isMandatory: true,
          isVerified: false,
        ),
      ];
    } else {
      _titleCtrl.text = 'General Mechanical Maintenance & Servicing';
      _locationCtrl.text = 'Process Unit 4 Deck';
      _issuedToCtrl.text = 'Mechanical Maintenance Crew';
      _workOrderCtrl.text = 'WO-GEN-2026';
      _checklist = [
        PtwChecklistItem(
          id: 'GEN-01',
          title: 'Work area barricaded and signposted with authorized personnel only notice',
          standardRef: 'Site Rule 1',
          isMandatory: true,
          isVerified: true,
          verifiedBy: _officerCtrl.text,
          verifiedAt: DateTime.now(),
        ),
        PtwChecklistItem(
          id: 'GEN-02',
          title: 'All mandatory PPE (Hard hat, safety boots, high-vis vest, goggles) inspected',
          standardRef: 'ISO 45001',
          isMandatory: true,
          isVerified: false,
        ),
        PtwChecklistItem(
          id: 'GEN-03',
          title: 'LOTO isolation applied and zero energy state verified by Lead Electrician',
          standardRef: 'OSHA 1910.147',
          isMandatory: true,
          isVerified: false,
        ),
      ];
    }
  }

  void _verifyAllChecklist() {
    setState(() {
      for (var item in _checklist) {
        item.isVerified = true;
        item.verifiedBy = _officerCtrl.text;
        item.verifiedAt = DateTime.now();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.tertiary,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'All mandatory safety checklist controls verified & timestamped for HSE sign-off!',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _submitPtw() {
    if (_titleCtrl.text.trim().isEmpty || _locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.error,
          content: Text('Please enter Permit Activity Title and Work Location.'),
        ),
      );
      return;
    }

    final unverifiedCount = _checklist.where((c) => !c.isVerified && c.isMandatory).length;
    if (unverifiedCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppTheme.secondary, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.secondary, size: 24),
              SizedBox(width: 10),
              Text(
                'Safety Verification Incomplete',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'There are $unverifiedCount mandatory safety checklist items still unverified. Industrial HSE regulations require all items to be confirmed before permit activation.\n\nDo you want to sign off and approve all checklist items now?',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Review Checklist', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.tertiary, foregroundColor: Colors.black87),
              onPressed: () {
                Navigator.pop(ctx);
                _verifyAllChecklist();
                _finalizePermitCreation();
              },
              child: const Text('Verify All & Issue PTW'),
            ),
          ],
        ),
      );
      return;
    }

    _finalizePermitCreation();
  }

  void _finalizePermitCreation() {
    String prefix;
    if (_selectedPermitType == 'Hot Work') {
      prefix = 'HW';
    } else if (_selectedPermitType == 'Working at Height') {
      prefix = 'WAH';
    } else if (_selectedPermitType == 'Confined Space') {
      prefix = 'CSE';
    } else {
      prefix = 'GEN';
    }

    final serial = 100 + (DateTime.now().millisecondsSinceEpoch % 899);
    final permitId = 'PTW-$prefix-2026-$serial';

    final verifiedList = _checklist.map((c) {
      final status = c.isVerified ? '[VERIFIED]' : '[PENDING]';
      return '$status ${c.title} (${c.standardRef})';
    }).toList();

    Map<String, String>? gasReadings;
    if (_selectedPermitType == 'Hot Work' || _selectedPermitType == 'Confined Space') {
      gasReadings = {
        'LEL': '${_lelCtrl.text}%',
        'O2': '${_o2Ctrl.text}%',
        'H2S': '${_h2sCtrl.text} ppm',
        'CO': '${_coCtrl.text} ppm',
      };
    }

    final newPermit = SafetyPermitModel(
      id: permitId,
      title: '$_selectedPermitType Permit (${_titleCtrl.text.trim()})',
      permitType: _selectedPermitType,
      location: _locationCtrl.text.trim(),
      issuedTo: _issuedToCtrl.text.trim(),
      validTill: 'Today, 18:00 ($_validHours)',
      status: PermitStatus.approved,
      hazardLevel: _selectedPermitType == 'Hot Work'
          ? 'HIGH HAZARD - CLASS 1 FIRE'
          : (_selectedPermitType == 'Working at Height'
              ? 'CRITICAL FALL HAZARD'
              : 'IDLH ATMOSPHERIC HAZARD'),
      safetyChecklist: verifiedList,
      gasTestReadings: gasReadings,
      authorizedOfficer: _officerCtrl.text.trim(),
      issuedAt: DateTime.now(),
      workOrderRef: _workOrderCtrl.text.trim(),
    );

    widget.onPermitCreated(newPermit);
  }

  @override
  Widget build(BuildContext context) {
    final verifiedCount = _checklist.where((c) => c.isVerified).length;
    final totalCount = _checklist.length;
    final progress = totalCount > 0 ? verifiedCount / totalCount : 0.0;
    final allVerified = verifiedCount == totalCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Form Container
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(_selectedPermitType).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(_selectedPermitType),
                          color: _getCategoryColor(_selectedPermitType),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ISSUE DIGITAL PERMIT-TO-WORK',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Field Risk Verification & Gate Pass Authorizer',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      _getCategoryStandard(_selectedPermitType),
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
              const Divider(color: AppTheme.border, height: 20),

              // 1. Interactive 3 High-Risk Category Cards
              const Text(
                '1. PERMIT CATEGORY (SELECT CLASSIFICATION)',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  _buildPermitCategoryCard(
                    title: 'Hot Work',
                    subtitle: 'Welding, Flame & Sparks',
                    icon: Icons.local_fire_department_rounded,
                    color: AppTheme.secondary,
                    standard: 'NFPA 51B / OISD-105',
                  ),
                  const SizedBox(width: 8),
                  _buildPermitCategoryCard(
                    title: 'Working at Height',
                    subtitle: 'Scaffolding >1.8m',
                    icon: Icons.terrain_rounded,
                    color: AppTheme.primaryLight,
                    standard: 'OSHA 1926 Subpart M',
                  ),
                  const SizedBox(width: 8),
                  _buildPermitCategoryCard(
                    title: 'Confined Space',
                    subtitle: 'Tanks, Vessels & Sumps',
                    icon: Icons.cyclone_rounded,
                    color: AppTheme.error,
                    standard: 'OSHA 1910.146',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Scope & Location
              const Text(
                '2. WORK SCOPE & GEOFENCED LOCATION',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _titleCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Activity Scope / Task Description',
                  prefixIcon: Icon(Icons.description_outlined, color: AppTheme.primaryLight, size: 18),
                ),
              ),
              const SizedBox(height: 8),

              // Quick scope suggestion chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _getScopeSuggestions(_selectedPermitType).map((chip) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(chip),
                        backgroundColor: AppTheme.background,
                        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                        side: const BorderSide(color: AppTheme.border),
                        onPressed: () => setState(() => _titleCtrl.text = chip),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _locationCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Work Location / Unit / Chainage',
                  prefixIcon: Icon(Icons.place_outlined, color: AppTheme.primaryLight, size: 18),
                ),
              ),
              const SizedBox(height: 4),
              // GPS Tag pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_fixed_rounded, color: AppTheme.tertiary, size: 12),
                    SizedBox(width: 6),
                    Text(
                      'GPS Verified: 27.2948° N, 95.3214° E (Unit 4 Geofence)',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _issuedToCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Performing Gang / Contractor',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _workOrderCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Work Order / JSA Ref',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Validity Window
              const Text(
                'PERMIT VALIDITY SHIFT',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildValidityChip('4 Hours (Half)'),
                  const SizedBox(width: 8),
                  _buildValidityChip('8 Hours (Full Shift)'),
                  const SizedBox(width: 8),
                  _buildValidityChip('12 Hours (Overtime)'),
                ],
              ),
              const SizedBox(height: 18),

              // 3. Mandatory Safety Checklist Verification Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.checklist_rounded, color: AppTheme.tertiary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '3. SAFETY CHECKLIST VERIFICATION ($verifiedCount/$totalCount)',
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.tertiary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.done_all_rounded, size: 15),
                    label: const Text('Verify All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: _verifyAllChecklist,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppTheme.background,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    allVerified ? AppTheme.tertiary : AppTheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Verification Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: allVerified
                      ? AppTheme.tertiary.withValues(alpha: 0.15)
                      : AppTheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: allVerified
                        ? AppTheme.tertiary.withValues(alpha: 0.4)
                        : AppTheme.secondary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      allVerified ? Icons.verified_rounded : Icons.info_outline_rounded,
                      color: allVerified ? AppTheme.tertiary : AppTheme.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        allVerified
                            ? 'All $totalCount safety precautions verified on site. Ready for HSE sign-off.'
                            : '${totalCount - verifiedCount} controls pending inspection. Tap each item to verify.',
                        style: TextStyle(
                          color: allVerified ? AppTheme.tertiary : AppTheme.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Checklist Items Interactive Tiles
              ..._checklist.map((item) => _buildChecklistItemTile(item)),
              const SizedBox(height: 16),

              // 4. Multi-Gas Atmospheric Sniff Test Section (If Hot Work or Confined Space)
              if (_selectedPermitType == 'Hot Work' || _selectedPermitType == 'Confined Space') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sensors_rounded, color: AppTheme.secondary, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          '4. MULTI-GAS DETECTOR PRE-ENTRY SNIFF TEST',
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('CALIBRATION VALID', style: TextStyle(color: AppTheme.tertiary, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildGasField(
                              label: 'Oxygen (O2)',
                              unit: '% vol (19.5-23.5)',
                              controller: _o2Ctrl,
                              color: AppTheme.tertiary,
                              isSafe: _isO2Safe(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildGasField(
                              label: 'Combustibles (LEL)',
                              unit: '% (<5.0% safe)',
                              controller: _lelCtrl,
                              color: AppTheme.primaryLight,
                              isSafe: _isLelSafe(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGasField(
                              label: 'Hydrogen Sulfide (H2S)',
                              unit: 'ppm (<5 ppm safe)',
                              controller: _h2sCtrl,
                              color: AppTheme.secondary,
                              isSafe: _isH2sSafe(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildGasField(
                              label: 'Carbon Monoxide (CO)',
                              unit: 'ppm (<25 ppm safe)',
                              controller: _coCtrl,
                              color: AppTheme.primaryLight,
                              isSafe: _isCoSafe(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _agtCtrl,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                              decoration: const InputDecoration(
                                labelText: 'Authorized Gas Tester (AGT)',
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_selectedPermitType == 'Confined Space') ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceCard,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _gasElevationLevel,
                                    isExpanded: true,
                                    dropdownColor: AppTheme.surfaceCard,
                                    items: ['Top (Hatch)', 'Middle (Work Deck Level)', 'Bottom (Sump)']
                                        .map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _gasElevationLevel = val);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 5. Dual Sign-Off & Issuance
              const Text(
                '5. DUAL AUTHORIZATION SIGN-OFF',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _officerCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Issuing HSE Safety Officer Signature & Badge ID',
                  prefixIcon: Icon(Icons.verified_user_rounded, color: AppTheme.tertiary, size: 18),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _supervisorCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Permit Receiver / Trade Foreman Signature',
                  prefixIcon: Icon(Icons.engineering_rounded, color: AppTheme.primaryLight, size: 18),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),

              // Big glowing Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.security_update_good_rounded, size: 20),
                  label: const Text(
                    'ISSUE DIGITAL PTW & GENERATE GATE PASS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                  ),
                  onPressed: _submitPtw,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermitCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String standard,
  }) {
    final isSelected = _selectedPermitType == title;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPermitType = title;
            _loadChecklistForType(title);
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.18) : AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppTheme.border,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: isSelected ? color : AppTheme.textMuted, size: 20),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      child: const Icon(Icons.check, size: 10, color: Colors.black87),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? color : AppTheme.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItemTile(PtwChecklistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: item.isVerified
            ? AppTheme.tertiary.withValues(alpha: 0.08)
            : AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isVerified
              ? AppTheme.tertiary.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        dense: true,
        leading: Checkbox(
          value: item.isVerified,
          activeColor: AppTheme.tertiary,
          checkColor: Colors.black87,
          onChanged: (val) {
            setState(() {
              item.isVerified = val ?? false;
              if (item.isVerified) {
                item.verifiedBy = _officerCtrl.text;
                item.verifiedAt = DateTime.now();
              } else {
                item.verifiedBy = null;
                item.verifiedAt = null;
              }
            });
          },
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: item.isVerified ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: 11.5,
            fontWeight: item.isVerified ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.standardRef,
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 9, fontFamily: 'monospace'),
              ),
            ),
            if (item.isVerified && item.verifiedAt != null) ...[
              const SizedBox(width: 6),
              Text(
                '· Verified at ${DateFormat('HH:mm').format(item.verifiedAt!)} IST',
                style: const TextStyle(color: AppTheme.tertiary, fontSize: 9.5),
              ),
            ],
          ],
        ),
        trailing: item.isVerified
            ? const Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 18)
            : const Icon(Icons.radio_button_unchecked_rounded, color: AppTheme.textMuted, size: 18),
        onTap: () {
          setState(() {
            item.isVerified = !item.isVerified;
            if (item.isVerified) {
              item.verifiedBy = _officerCtrl.text;
              item.verifiedAt = DateTime.now();
            } else {
              item.verifiedBy = null;
              item.verifiedAt = null;
            }
          });
        },
      ),
    );
  }

  Widget _buildGasField({
    required String label,
    required String unit,
    required TextEditingController controller,
    required Color color,
    required bool isSafe,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isSafe ? AppTheme.border : AppTheme.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: (isSafe ? AppTheme.tertiary : AppTheme.error).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  isSafe ? 'SAFE' : 'ALERT',
                  style: TextStyle(
                    color: isSafe ? AppTheme.tertiary : AppTheme.error,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 2),
              border: InputBorder.none,
              suffixText: unit.split(' ').first,
              suffixStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
            onChanged: (_) => setState(() {}),
          ),
          Text(unit, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5)),
        ],
      ),
    );
  }

  bool _isO2Safe() {
    final v = double.tryParse(_o2Ctrl.text.trim()) ?? 0.0;
    return v >= 19.5 && v <= 23.5;
  }

  bool _isLelSafe() {
    final v = double.tryParse(_lelCtrl.text.trim()) ?? 0.0;
    return v < 5.0;
  }

  bool _isH2sSafe() {
    final v = double.tryParse(_h2sCtrl.text.trim()) ?? 0.0;
    return v < 5.0;
  }

  bool _isCoSafe() {
    final v = double.tryParse(_coCtrl.text.trim()) ?? 0.0;
    return v < 25.0;
  }

  Widget _buildValidityChip(String label) {
    final isSelected = _validHours == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _validHours = label),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withValues(alpha: 0.25) : AppTheme.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppTheme.primaryLight : AppTheme.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String type) {
    if (type.contains('Hot')) return Icons.local_fire_department_rounded;
    if (type.contains('Height')) return Icons.terrain_rounded;
    if (type.contains('Confined')) return Icons.cyclone_rounded;
    return Icons.assignment_rounded;
  }

  Color _getCategoryColor(String type) {
    if (type.contains('Hot')) return AppTheme.secondary;
    if (type.contains('Height')) return AppTheme.primaryLight;
    if (type.contains('Confined')) return AppTheme.error;
    return AppTheme.primary;
  }

  String _getCategoryStandard(String type) {
    if (type.contains('Hot')) return 'NFPA 51B';
    if (type.contains('Height')) return 'OSHA 1926';
    if (type.contains('Confined')) return 'OSHA 1910';
    return 'ISO 45001';
  }

  List<String> _getScopeSuggestions(String type) {
    if (type.contains('Hot')) {
      return [
        'Flare Header Weld & Fit-up',
        'Pipe Spool Bevel Torch Cut',
        'Gusset Plate Structural Weld',
        'Pressure Relief Flange Tie-in',
      ];
    } else if (type.contains('Height')) {
      return [
        'Column C40 Scaffolding Erection',
        'Pipe Rack Cable Tray Pulling',
        'Elevation +18.5m Deck Painting',
        'Vessel Top Handrail Rigging',
      ];
    } else if (type.contains('Confined')) {
      return [
        'Tank 102 Internal Hydro-Cleanout',
        'Crude Shell Baffle Inspection',
        'Enclosed Sump De-mucking',
        'Internal Hydrostatic Weld NDT',
      ];
    }
    return ['General Mechanical Servicing', 'Civil Trench Shoring', 'Transformer Inspection'];
  }
}


// ==============================================================================
// 8. SAFETY CERTIFICATE SCANNER / BADGE VERIFICATION SHEET
// ==============================================================================

class _SafetyBadgeScannerSheet extends StatefulWidget {
  const _SafetyBadgeScannerSheet();

  @override
  State<_SafetyBadgeScannerSheet> createState() => _SafetyBadgeScannerSheetState();
}

class _SafetyBadgeScannerSheetState extends State<_SafetyBadgeScannerSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserAnim;
  final TextEditingController _badgeInputCtrl = TextEditingController(text: 'WLD-402');
  late WorkerSafetyProfile _currentProfile;

  final Map<String, WorkerSafetyProfile> _workerDatabase = {
    'WLD-402': WorkerSafetyProfile(
      badgeNumber: 'WLD-402',
      name: 'Tapan Das',
      trade: 'Master Welder (6G SMAW/GTAW)',
      contractor: 'Consortium Pipeline JV Gang A',
      clearanceStatus: 'CLEARED_HIGH_RISK',
      photoUrl: '',
      medicalFitnessDate: '15 Aug 2026 (Fit - Class 1)',
      audiometryClass: 'Audiometry Grade-A Normal',
      authorizedForHighRisk: true,
      certifications: [
        SafetyCertification(
          title: 'ASME Sec IX / API 1104 6G Welder Qualification',
          standard: 'ASME-IX-2024-W24',
          validTill: '15 Aug 2027',
          isValid: true,
        ),
        SafetyCertification(
          title: 'Hot Work Spark Containment & Fire Watch Level 2',
          standard: 'NFPA 51B / OISD-105',
          validTill: '10 Feb 2027',
          isValid: true,
        ),
        SafetyCertification(
          title: 'Confined Space Entry & Standby Entrant',
          standard: 'OSHA 1910.146 Certified',
          validTill: '20 Nov 2026',
          isValid: true,
        ),
      ],
    ),
    'SCF-108': WorkerSafetyProfile(
      badgeNumber: 'SCF-108',
      name: 'Biren Gogoi',
      trade: 'Lead Scaffolder & Rigging Specialist',
      contractor: 'Assam Scaffolding Erectors',
      clearanceStatus: 'CLEARED_HIGH_RISK',
      photoUrl: '',
      medicalFitnessDate: '22 Jul 2026 (Fit)',
      audiometryClass: 'Audiometry Normal',
      authorizedForHighRisk: true,
      certifications: [
        SafetyCertification(
          title: 'CISRS Advanced Scaffolding Erector & Inspector',
          standard: 'BS EN 12811 / OSHA',
          validTill: '05 Jan 2027',
          isValid: true,
        ),
        SafetyCertification(
          title: 'Working at Height Rescue & High-Line Evacuation',
          standard: 'IRATA Level 1 Equiv',
          validTill: '18 Dec 2026',
          isValid: true,
        ),
      ],
    ),
    'ELC-204': WorkerSafetyProfile(
      badgeNumber: 'ELC-204',
      name: 'Subrat Mohanty',
      trade: 'High Voltage Electrical Specialist',
      contractor: 'PowerGrid Solutions',
      clearanceStatus: 'CLEARED_HIGH_RISK',
      photoUrl: '',
      medicalFitnessDate: '10 Jun 2026 (Fit)',
      audiometryClass: 'Class 1',
      authorizedForHighRisk: true,
      certifications: [
        SafetyCertification(
          title: 'CEA High Voltage Electrical Safety Clearance (33kV)',
          standard: 'Central Electricity Authority',
          validTill: '30 Sep 2027',
          isValid: true,
        ),
        SafetyCertification(
          title: 'LOTO Lockout/Tagout System Specialist',
          standard: 'OSHA 1910.147',
          validTill: '15 Apr 2027',
          isValid: true,
        ),
      ],
    ),
  };

  @override
  void initState() {
    super.initState();
    _laserAnim = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _currentProfile = _workerDatabase['WLD-402']!;
  }

  @override
  void dispose() {
    _laserAnim.dispose();
    super.dispose();
  }

  void _verifyBadge(String badge) {
    final b = badge.trim().toUpperCase();
    if (_workerDatabase.containsKey(b)) {
      setState(() => _currentProfile = _workerDatabase[b]!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          content: Text('Badge [$badge] not found in local active registry. Try WLD-402, SCF-108, ELC-204.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryLight, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safety Certificate Scanner',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Badge RFID / QR / Cert Expiry Verifier',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.border, height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Simulated Optical Laser Scanner Viewfinder
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.5)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Grid background
                      Opacity(
                        opacity: 0.15,
                        child: Icon(Icons.grid_4x4_rounded, size: 100, color: AppTheme.primaryLight),
                      ),
                      // Animated scanning laser line
                      AnimatedBuilder(
                        animation: _laserAnim,
                        builder: (context, child) {
                          return Positioned(
                            top: 15 + (_laserAnim.value * 80),
                            left: 20,
                            right: 20,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppTheme.tertiary,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.tertiary.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 36, color: Colors.white70),
                          SizedBox(height: 4),
                          Text(
                            'ALIGN WORKER BADGE QR OR RFID TAG',
                            style: TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Manual search badge field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _badgeInputCtrl,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter Badge ID (e.g. WLD-402)',
                          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onSubmitted: _verifyBadge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onPressed: () => _verifyBadge(_badgeInputCtrl.text),
                      child: const Text('Verify', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Quick selector buttons
                Wrap(
                  spacing: 8,
                  children: [
                    _buildQuickBadgeChip('WLD-402 (Welder)'),
                    _buildQuickBadgeChip('SCF-108 (Scaffolder)'),
                    _buildQuickBadgeChip('ELC-204 (Electrician)'),
                  ],
                ),
                const SizedBox(height: 16),

                // Verified Worker Profile Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                                child: Text(
                                  _currentProfile.name.substring(0, 2).toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.primaryLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentProfile.name,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _currentProfile.trade,
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                  ),
                                  Text(
                                    'Contractor: ${_currentProfile.contractor}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.tertiary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified_user_rounded, color: AppTheme.tertiary, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'CLEARED',
                                  style: TextStyle(
                                    color: AppTheme.tertiary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppTheme.border, height: 20),

                      // Medical & Fitness
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildProfileStat('Medical Fitness', _currentProfile.medicalFitnessDate),
                          _buildProfileStat('Audiometry Test', _currentProfile.audiometryClass),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Certifications Matrix
                      const Text(
                        'ACTIVE SAFETY CERTIFICATIONS (SITE VERIFIED)',
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._currentProfile.certifications.map((cert) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cert.title,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${cert.standard} · Valid till ${cert.validTill}',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),

                      // Authorize Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.tertiary,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.badge_rounded, size: 18),
                          label: const Text(
                            'Authorize on Live Permit Roster',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.tertiary,
                                content: Text(
                                  'Worker [${_currentProfile.badgeNumber}] ${_currentProfile.name} verified and authorized for High-Risk PTW.',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
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

  Widget _buildQuickBadgeChip(String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppTheme.surfaceCard,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
      side: const BorderSide(color: AppTheme.border),
      onPressed: () {
        final badge = label.split(' ').first;
        _badgeInputCtrl.text = badge;
        _verifyBadge(badge);
      },
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
