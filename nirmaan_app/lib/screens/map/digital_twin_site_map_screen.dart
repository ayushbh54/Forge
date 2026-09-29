import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Progress status for physical asset nodes in the Digital Twin
enum AssetProgressStatus {
  erected,
  inProgress,
  blocked,
  notStarted;

  Color get color {
    switch (this) {
      case AssetProgressStatus.erected:
        return const Color(0xFF4EDEA3); // Green (100% Erected)
      case AssetProgressStatus.inProgress:
        return const Color(0xFFFFB95F); // Amber (65% In-Progress)
      case AssetProgressStatus.blocked:
        return const Color(0xFFFF5252); // Red (Blocked / Delayed)
      case AssetProgressStatus.notStarted:
        return const Color(0xFF64748B); // Grey (Not Started)
    }
  }

  String get label {
    switch (this) {
      case AssetProgressStatus.erected:
        return '100% Erected';
      case AssetProgressStatus.inProgress:
        return '65% In-Progress';
      case AssetProgressStatus.blocked:
        return 'Blocked / Delayed';
      case AssetProgressStatus.notStarted:
        return 'Not Started';
    }
  }

  String get shortLabel {
    switch (this) {
      case AssetProgressStatus.erected:
        return 'Erected';
      case AssetProgressStatus.inProgress:
        return 'In-Progress';
      case AssetProgressStatus.blocked:
        return 'Blocked';
      case AssetProgressStatus.notStarted:
        return 'Not Started';
    }
  }

  IconData get icon {
    switch (this) {
      case AssetProgressStatus.erected:
        return Icons.check_circle_rounded;
      case AssetProgressStatus.inProgress:
        return Icons.build_circle_rounded;
      case AssetProgressStatus.blocked:
        return Icons.warning_rounded;
      case AssetProgressStatus.notStarted:
        return Icons.hourglass_empty_rounded;
    }
  }
}

/// Represents a physical engineering asset in the 3D / Isometric Digital Twin
class PhysicalAssetNode {
  final String id;
  final String tag;
  final String name;
  final String zoneId;
  final String zoneName;
  final AssetProgressStatus status;
  final double progressPercent;
  final String linkedActivityId;
  final String wbsCode;
  final String assignedGang;
  final String gangSupervisor;
  final int gangWorkerCount;
  final String qcStampNumber;
  final String qcStampStatus;
  final String qcInspector;
  final String qcStampDate;
  final String heatNumber;
  final String materialSpec;
  final String coordinatesGps;
  final String chainage;
  final double elevationMsl;
  final String? delayReason;
  final String? lidarScanVariance;
  final double isoX;
  final double isoY;
  final double isoZ;
  final String category;

  const PhysicalAssetNode({
    required this.id,
    required this.tag,
    required this.name,
    required this.zoneId,
    required this.zoneName,
    required this.status,
    required this.progressPercent,
    required this.linkedActivityId,
    required this.wbsCode,
    required this.assignedGang,
    required this.gangSupervisor,
    required this.gangWorkerCount,
    required this.qcStampNumber,
    required this.qcStampStatus,
    required this.qcInspector,
    required this.qcStampDate,
    required this.heatNumber,
    required this.materialSpec,
    required this.coordinatesGps,
    required this.chainage,
    required this.elevationMsl,
    this.delayReason,
    this.lidarScanVariance,
    required this.isoX,
    required this.isoY,
    required this.isoZ,
    required this.category,
  });
}

/// Represents a distinct geographical zone of the Oil India pipeline spread & facility
class SiteZone {
  final String id;
  final String name;
  final String code;
  final String type;
  final String chainage;
  final double focusX;
  final double focusY;
  final double focusScale;
  final String description;
  final int activeGangs;
  final double completionPercent;

  const SiteZone({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.chainage,
    required this.focusX,
    required this.focusY,
    this.focusScale = 1.25,
    required this.description,
    required this.activeGangs,
    required this.completionPercent,
  });
}

class DigitalTwinSiteMapScreen extends StatefulWidget {
  const DigitalTwinSiteMapScreen({super.key});

  @override
  State<DigitalTwinSiteMapScreen> createState() =>
      _DigitalTwinSiteMapScreenState();
}

class _DigitalTwinSiteMapScreenState extends State<DigitalTwinSiteMapScreen>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _pulseController;

  String _selectedZoneId = 'ALL';
  PhysicalAssetNode? _selectedAsset;
  AssetProgressStatus? _selectedStatusFilter;
  String _searchQuery = '';
  bool _is3dIsometric = true;
  bool _showLidarCloud = true;
  bool _showPipelineFlow = true;
  bool _showGangMarkers = true;
  bool _showQcStamps = false;
  bool _isSearchExpanded = false;

  final TextEditingController _searchController = TextEditingController();

  // Virtual canvas dimensions for isometric coordinate projection
  static const double _canvasWidth = 2400.0;
  static const double _canvasHeight = 2200.0;

  // Site Zones (Oil India Duliajan Pipeline Spread & Gas Gathering Station)
  static const List<SiteZone> _zones = [
    SiteZone(
      id: 'WP-04',
      name: 'Wellpad 04',
      code: 'WP-04',
      type: 'Production Well Cluster',
      chainage: 'KP 04+200',
      focusX: 680,
      focusY: 550,
      focusScale: 1.4,
      description: 'Multi-well extraction cluster, manifold skid & high-pressure christmas trees.',
      activeGangs: 3,
      completionPercent: 68.5,
    ),
    SiteZone(
      id: 'VS-12',
      name: 'Valve Station 12',
      code: 'VS-12',
      type: 'Mainline Block Valve',
      chainage: 'KP 12+450',
      focusX: 1150,
      focusY: 880,
      focusScale: 1.35,
      description: 'Intermediate sectionalizing station, cathodic protection beds & bypass loop.',
      activeGangs: 4,
      completionPercent: 74.0,
    ),
    SiteZone(
      id: 'CPS-02',
      name: 'Crude Pipeline Spread 2',
      code: 'CPS-02',
      type: 'Trunk Line Right-of-Way',
      chainage: 'KP 18+000 - KP 28+500',
      focusX: 1580,
      focusY: 1220,
      focusScale: 1.25,
      description: '12" API 5L X52 trunk crude transfer corridor across Burhi Dihing riverbed.',
      activeGangs: 6,
      completionPercent: 62.0,
    ),
    SiteZone(
      id: 'CTF-01',
      name: 'Central Tank Farm',
      code: 'CTF-01',
      type: 'Storage & Transfer Terminal',
      chainage: 'Madhuban Hub',
      focusX: 880,
      focusY: 1550,
      focusScale: 1.3,
      description: 'Crude storage tanks, booster pump stations, fiscal metering & manifold array.',
      activeGangs: 5,
      completionPercent: 71.5,
    ),
    SiteZone(
      id: 'GGS-01',
      name: 'Gas Gathering Station',
      code: 'GGS-01',
      type: 'Central Compression Hub',
      chainage: 'Duliajan Central GGS',
      focusX: 1820,
      focusY: 650,
      focusScale: 1.3,
      description: 'High pressure gas compression, knock-out separators & elevated flare system.',
      activeGangs: 5,
      completionPercent: 82.0,
    ),
  ];

  // Physical Asset Nodes
  static const List<PhysicalAssetNode> _assets = [
    // --- Crude Pipeline Spread 2 ---
    PhysicalAssetNode(
      id: 'AST-CPS-01',
      tag: 'Pipe Spool 24-A',
      name: '12" Carbon Steel Trunk Line Pipe Spool 24-A (API 5L Gr. X52 PSL2)',
      zoneId: 'CPS-02',
      zoneName: 'Crude Pipeline Spread 2',
      status: AssetProgressStatus.inProgress,
      progressPercent: 65.0,
      linkedActivityId: 'PIP-L5-024',
      wbsCode: '03.02.04.01',
      assignedGang: 'Gang 4 — PetroFab Mechanical Crew',
      gangSupervisor: 'Vikram Joshi (Senior Piping Foreman)',
      gangWorkerCount: 18,
      qcStampNumber: 'OIL-QC-NDT-9824',
      qcStampStatus: 'PASSED (Radiography RT & UT 100%)',
      qcInspector: 'R. K. Sharma (Level III NDT / OIL QA/QC)',
      qcStampDate: '29-Sep-2026 16:30 IST',
      heatNumber: 'HT-98211-OIL / Batch 4B',
      materialSpec: 'API 5L Gr. X52 PSL2, 12" NB Sch 40 (9.53mm WT)',
      coordinatesGps: '27°18\'38.4"N, 95°19\'22.1"E',
      chainage: 'KP 24+180',
      elevationMsl: 118.4,
      delayReason: null,
      lidarScanVariance:
          '+1.4cm deviation vs BIM model (Within ±2.5cm tolerance)',
      isoX: 1540,
      isoY: 1180,
      isoZ: 28,
      category: 'PIPING',
    ),
    PhysicalAssetNode(
      id: 'AST-CPS-02',
      tag: 'River HDD Pull-Head 02',
      name:
          'Burhi Dihing River Crossing Horizontal Directional Drill Pull-Head',
      zoneId: 'CPS-02',
      zoneName: 'Crude Pipeline Spread 2',
      status: AssetProgressStatus.blocked,
      progressPercent: 40.0,
      linkedActivityId: 'HDD-L5-081',
      wbsCode: '03.02.04.05',
      assignedGang: 'Gang 11 — Trenchless & HDD Consortium',
      gangSupervisor: 'Anup Bordoloi (Trenchless Specialist)',
      gangWorkerCount: 14,
      qcStampNumber: 'OIL-QC-GEO-6701',
      qcStampStatus: 'BLOCKED (River Bank Geotechnical Hold)',
      qcInspector: 'Dr. B. C. Gogoi (Senior Geotechnical Engineer)',
      qcStampDate: '28-Sep-2026 11:15 IST',
      heatNumber: 'HDD-TOOL-901-H',
      materialSpec: 'API 5L Gr. X65 Heavy Wall Casing 16" OD',
      coordinatesGps: '27°18\'46.2"N, 95°19\'45.0"E',
      chainage: 'KP 24+650',
      elevationMsl: 104.2,
      delayReason: 'North riverbank scour; geogrid anchor stabilization required before reamer pull-back.',
      lidarScanVariance: '+6.8cm bank slope displacement detected',
      isoX: 1680,
      isoY: 1260,
      isoZ: 15,
      category: 'CIVIL',
    ),
    PhysicalAssetNode(
      id: 'AST-CPS-03',
      tag: 'Cathodic Test Station TS-24',
      name: 'Mainline Impressed Current Cathodic Protection Test Station TS-24',
      zoneId: 'CPS-02',
      zoneName: 'Crude Pipeline Spread 2',
      status: AssetProgressStatus.erected,
      progressPercent: 100.0,
      linkedActivityId: 'COR-L5-085',
      wbsCode: '03.02.04.09',
      assignedGang: 'Gang 9 — Cathodic Protection Specialists',
      gangSupervisor: 'Nirmal Saikia (NACE CP Level II)',
      gangWorkerCount: 6,
      qcStampNumber: 'OIL-QC-CP-2419',
      qcStampStatus: 'PASSED (Pipe-to-Soil Potential -1.18V CSE)',
      qcInspector: 'P. Bora (Corrosion Engineer / OIL)',
      qcStampDate: '27-Sep-2026 14:00 IST',
      heatNumber: 'CP-TS-2026-B',
      materialSpec: 'Cu/CuSO4 Reference Cell with Remote SCADA RTU Box',
      coordinatesGps: '27°18\'35.0"N, 95°19\'15.6"E',
      chainage: 'KP 24+050',
      elevationMsl: 119.1,
      delayReason: null,
      lidarScanVariance: 'Exact 0.0cm match to design',
      isoX: 1460,
      isoY: 1130,
      isoZ: 20,
      category: 'ELECTRICAL',
    ),
    PhysicalAssetNode(
      id: 'AST-CPS-04',
      tag: 'Fiber Duct FOT-02',
      name: '24-Core Armored Optical Fiber Telemetry Duct Along RoW Trench',
      zoneId: 'CPS-02',
      zoneName: 'Crude Pipeline Spread 2',
      status: AssetProgressStatus.notStarted,
      progressPercent: 0.0,
      linkedActivityId: 'TEL-L5-089',
      wbsCode: '03.02.04.14',
      assignedGang: 'Gang 10 — Fiber Optic & SCADA Cable Crew',
      gangSupervisor: 'Deepak Chetia (Telecom Lead)',
      gangWorkerCount: 8,
      qcStampNumber: 'OIL-QC-TEL-0044',
      qcStampStatus: 'PENDING (Pre-Installation Drums Tested)',
      qcInspector: 'S. K. Nath (Telecom QA)',
      qcStampDate: 'Pending Laying',
      heatNumber: 'OFC-DRUM-992-OIL',
      materialSpec: '24-Fiber Single Mode G.652D Direct Buried Armored',
      coordinatesGps: '27°18\'40.1"N, 95°19\'30.0"E',
      chainage: 'KP 24+400',
      elevationMsl: 116.5,
      delayReason:
          'Awaiting completion of pipe trench backfill before cable plowing.',
      lidarScanVariance: null,
      isoX: 1610,
      isoY: 1330,
      isoZ: 10,
      category: 'ELECTRICAL',
    ),

    // --- Central Tank Farm ---
    PhysicalAssetNode(
      id: 'AST-CTF-01',
      tag: 'Pump Foundation B',
      name:
          'Heavy Duty Crude Booster Pump P-201B Reinforced Concrete Foundation',
      zoneId: 'CTF-01',
      zoneName: 'Central Tank Farm',
      status: AssetProgressStatus.erected,
      progressPercent: 100.0,
      linkedActivityId: 'CIV-L5-088',
      wbsCode: '04.01.02.03',
      assignedGang: 'Gang 2 — Assam Civil Infra Structurals',
      gangSupervisor: 'A. K. Baruah (Chief Civil Works Manager)',
      gangWorkerCount: 22,
      qcStampNumber: 'OIL-QC-CIV-4410',
      qcStampStatus: 'PASSED (Compressive Strength 42.5 MPa @ 28 Days C40)',
      qcInspector: 'R. K. Sharma (Materials Testing Lab / OIL QA)',
      qcStampDate: '26-Sep-2026 17:45 IST',
      heatNumber: 'REBAR-FE500D-L418',
      materialSpec: 'C40/50 Self-Compacting Concrete with Fe500D Rebar Grid',
      coordinatesGps: '27°17\'55.2"N, 95°18\'44.8"E',
      chainage: 'Pump Bay 02',
      elevationMsl: 122.0,
      delayReason: null,
      lidarScanVariance:
          'Flatness deviation 0.8mm (Well below 2.0mm tolerance)',
      isoX: 850,
      isoY: 1530,
      isoZ: 35,
      category: 'CIVIL',
    ),
    PhysicalAssetNode(
      id: 'AST-CTF-02',
      tag: 'Storage Tank TK-101',
      name: '50,000 Barrels Floating Roof Crude Oil Bulk Storage Tank TK-101',
      zoneId: 'CTF-01',
      zoneName: 'Central Tank Farm',
      status: AssetProgressStatus.inProgress,
      progressPercent: 65.0,
      linkedActivityId: 'STR-L5-091',
      wbsCode: '04.01.01.01',
      assignedGang: 'Gang 2 — Assam Civil Infra Structurals',
      gangSupervisor: 'A. K. Baruah (Chief Civil Works Manager)',
      gangWorkerCount: 30,
      qcStampNumber: 'OIL-QC-TK-4482',
      qcStampStatus: 'IN-PROGRESS (Shell Courses 1 to 4 Vacuum Tested)',
      qcInspector: 'M. K. Kalita (API 650 Certified Inspector)',
      qcStampDate: '29-Sep-2026 15:10 IST',
      heatNumber: 'PLT-API650-B902',
      materialSpec: 'ASTM A516 Gr. 70 Carbon Steel Plates, API 650 Code',
      coordinatesGps: '27°17\'50.8"N, 95°18\'38.2"E',
      chainage: 'Tank Dike 01',
      elevationMsl: 121.5,
      delayReason: null,
      lidarScanVariance:
          'Plumbness out-of-roundness < 12mm across 42m diameter',
      isoX: 740,
      isoY: 1640,
      isoZ: 50,
      category: 'CIVIL',
    ),
    PhysicalAssetNode(
      id: 'AST-CTF-03',
      tag: 'Booster Pump Motor P-201B',
      name: '750 kW Flameproof High-Pressure Centrifugal Booster Pump Motor',
      zoneId: 'CTF-01',
      zoneName: 'Central Tank Farm',
      status: AssetProgressStatus.blocked,
      progressPercent: 35.0,
      linkedActivityId: 'MEC-L5-095',
      wbsCode: '04.01.02.07',
      assignedGang: 'Gang 7 — Bharat Heavy Rigging & Turbomachinery',
      gangSupervisor: 'Tapan Hazarika (Turbomachinery Specialist)',
      gangWorkerCount: 12,
      qcStampNumber: 'OIL-QC-MEC-8114',
      qcStampStatus: 'HOLD (Foundation Anchor Bolt Size Mismatch)',
      qcInspector: 'R. K. Sharma (OIL QA/QC Lead)',
      qcStampDate: '28-Sep-2026 09:30 IST',
      heatNumber: 'MTR-PUMP-B9921',
      materialSpec:
          'Ex d IIB T4 Flameproof Motor with Sulzer High Pressure Volute',
      coordinatesGps: '27°17\'55.8"N, 95°18\'45.3"E',
      chainage: 'Pump Bay 02',
      elevationMsl: 122.3,
      delayReason: 'Anchor bolt pattern diameter mismatch (M36 specified vs M30 pre-cast sleeve); structural modification memo filed.',
      lidarScanVariance: 'Offset 18mm off center-line axis',
      isoX: 940,
      isoY: 1560,
      isoZ: 40,
      category: 'EQUIPMENT',
    ),
    PhysicalAssetNode(
      id: 'AST-CTF-04',
      tag: 'Foam Deluge Skid FFS-01',
      name: 'Automated Tank Foam Deluge & High-Expansion Fire Suppression Skid',
      zoneId: 'CTF-01',
      zoneName: 'Central Tank Farm',
      status: AssetProgressStatus.notStarted,
      progressPercent: 0.0,
      linkedActivityId: 'HSE-L5-099',
      wbsCode: '04.01.05.02',
      assignedGang: 'Gang 3 — Utilities & Auxiliaries Crew',
      gangSupervisor: 'Subhash Roy (Safety & Fire Safety Lead)',
      gangWorkerCount: 8,
      qcStampNumber: 'OIL-QC-HSE-1102',
      qcStampStatus: 'PENDING (Pre-Installation Shop Verification)',
      qcInspector: 'B. J. Medhi (OISD Fire Protection Auditor)',
      qcStampDate: 'Pending Delivery',
      heatNumber: 'SKID-FOAM-771',
      materialSpec: 'OISD-117 Compliant Balanced Pressure Proportioner System',
      coordinatesGps: '27°17\'58.0"N, 95°18\'35.0"E',
      chainage: 'Fire Protection Zone',
      elevationMsl: 122.8,
      delayReason:
          'Awaiting concrete curing of surrounding containment bund wall.',
      lidarScanVariance: null,
      isoX: 790,
      isoY: 1470,
      isoZ: 30,
      category: 'SAFETY',
    ),

    // --- Gas Gathering Station (GGS) ---
    PhysicalAssetNode(
      id: 'AST-GGS-01',
      tag: 'Compressor Package 01',
      name: 'High-Pressure 3-Stage Reciprocating Natural Gas Compressor Package 01',
      zoneId: 'GGS-01',
      zoneName: 'Gas Gathering Station',
      status: AssetProgressStatus.inProgress,
      progressPercent: 65.0,
      linkedActivityId: 'MEC-L5-101',
      wbsCode: '05.02.01.02',
      assignedGang: 'Gang 7 — Bharat Heavy Rigging & Turbomachinery',
      gangSupervisor: 'Tapan Hazarika (Turbomachinery Specialist)',
      gangWorkerCount: 16,
      qcStampNumber: 'OIL-QC-MEC-7721',
      qcStampStatus: 'PROVISIONAL (Cold Alignment Complete < 0.04mm)',
      qcInspector: 'R. K. Sharma (OIL QA/QC Lead)',
      qcStampDate: '29-Sep-2026 14:20 IST',
      heatNumber: 'COMP-SKID-2026-X1',
      materialSpec:
          'API 618 5th Edition Reciprocating Frame with GE Gas Engine',
      coordinatesGps: '27°19\'12.5"N, 95°20\'10.2"E',
      chainage: 'GGS Bay 01',
      elevationMsl: 126.5,
      delayReason: null,
      lidarScanVariance: 'Skid levelness within 0.05mm/m specification',
      isoX: 1780,
      isoY: 620,
      isoZ: 45,
      category: 'EQUIPMENT',
    ),
    PhysicalAssetNode(
      id: 'AST-GGS-02',
      tag: 'Flare Header',
      name: '24" Elevated Flange-Connected Smokeless Flare Line Header & Knockout Inlet',
      zoneId: 'GGS-01',
      zoneName: 'Gas Gathering Station',
      status: AssetProgressStatus.erected,
      progressPercent: 100.0,
      linkedActivityId: 'PIP-L5-112',
      wbsCode: '05.02.03.04',
      assignedGang: 'Gang 5 — North-East High-Altitude Piping Crew',
      gangSupervisor: 'Bikash Sonowal (Rigging & Piping Lead)',
      gangWorkerCount: 20,
      qcStampNumber: 'OIL-QC-NDT-9905',
      qcStampStatus:
          'PASSED (Hydrostatic Pressure Tested 18.5 Bar / 4-Hr Hold)',
      qcInspector: 'A. K. Bhattacharya (Chief Pipeline Inspector)',
      qcStampDate: '28-Sep-2026 18:00 IST',
      heatNumber: 'FLR-HDR-24X52-OIL',
      materialSpec: 'API 5L Gr. X52 Low-Temp Carbon Steel, ASTM A333 Gr. 6',
      coordinatesGps: '27°19\'20.1"N, 95°20\'25.0"E',
      chainage: 'Flare Yard North',
      elevationMsl: 128.0,
      delayReason: null,
      lidarScanVariance: 'Truss verticality deviation 1.1mm (Tolerance ±5mm)',
      isoX: 1940,
      isoY: 560,
      isoZ: 65,
      category: 'PIPING',
    ),
    PhysicalAssetNode(
      id: 'AST-GGS-03',
      tag: 'Knockout Drum KOD-01',
      name: 'High Pressure Gas Liquid Separation Knockout Vessel KOD-01',
      zoneId: 'GGS-01',
      zoneName: 'Gas Gathering Station',
      status: AssetProgressStatus.erected,
      progressPercent: 100.0,
      linkedActivityId: 'MEC-L5-108',
      wbsCode: '05.02.02.01',
      assignedGang: 'Gang 4 — PetroFab Mechanical Crew',
      gangSupervisor: 'Vikram Joshi (Senior Piping Foreman)',
      gangWorkerCount: 14,
      qcStampNumber: 'OIL-QC-VES-6019',
      qcStampStatus: 'PASSED (ASME Sec VIII Div 1 Hydrotest Passed)',
      qcInspector: 'S. N. Gogoi (Boiler & Pressure Vessel Inspector)',
      qcStampDate: '25-Sep-2026 12:30 IST',
      heatNumber: 'VESSEL-PV-1109',
      materialSpec: 'SA 516 Gr. 70 HIC Tested with 3mm SS 316L Internal Clad',
      coordinatesGps: '27°19\'15.0"N, 95°20\'18.4"E',
      chainage: 'GGS Vessel Bay',
      elevationMsl: 126.8,
      delayReason: null,
      lidarScanVariance: 'Exact nozzle centerlines verified',
      isoX: 1850,
      isoY: 710,
      isoZ: 38,
      category: 'EQUIPMENT',
    ),
    PhysicalAssetNode(
      id: 'AST-GGS-04',
      tag: 'Gas Dehydration TEG-01',
      name: 'Tri-Ethylene Glycol (TEG) Natural Gas Moisture Dehydration Skid',
      zoneId: 'GGS-01',
      zoneName: 'Gas Gathering Station',
      status: AssetProgressStatus.notStarted,
      progressPercent: 0.0,
      linkedActivityId: 'PRC-L5-115',
      wbsCode: '05.02.04.01',
      assignedGang: 'Gang 5 — Process Plant Erection Crew',
      gangSupervisor: 'Bikash Sonowal (Rigging & Piping Lead)',
      gangWorkerCount: 10,
      qcStampNumber: 'OIL-QC-PRC-0012',
      qcStampStatus: 'PENDING (Customs Clearance en-route Guwahati Port)',
      qcInspector: 'P. Bora (OIL QA Engineer)',
      qcStampDate: 'Pending Delivery',
      heatNumber: 'TEG-SKID-2026-OIL',
      materialSpec: 'Structured Packed Contactor Column with Reboiler Skids',
      coordinatesGps: '27°19\'10.0"N, 95°20\'08.0"E',
      chainage: 'GGS Process Sector',
      elevationMsl: 126.2,
      delayReason: 'Delivery convoy delayed at Numaligarh transport checkpost.',
      lidarScanVariance: null,
      isoX: 1720,
      isoY: 740,
      isoZ: 30,
      category: 'EQUIPMENT',
    ),

    // --- Wellpad 04 ---
    PhysicalAssetNode(
      id: 'AST-WP-01',
      tag: 'Wellhead X-Tree 04-A',
      name: '5,000 PSI High-Pressure Dual-String Christmas Tree Assembly 04-A',
      zoneId: 'WP-04',
      zoneName: 'Wellpad 04',
      status: AssetProgressStatus.erected,
      progressPercent: 100.0,
      linkedActivityId: 'DRILL-L5-041',
      wbsCode: '02.01.01.01',
      assignedGang: 'Gang 1 — Well Services & Drilling Technicians',
      gangSupervisor: 'Dhiraj Saikia (Well Services Superintendent)',
      gangWorkerCount: 16,
      qcStampNumber: 'OIL-QC-WH-1022',
      qcStampStatus: 'PASSED (API 6A PSL3 Hydrostatic Body Test 7,500 PSI)',
      qcInspector: 'K. M. Phukan (API 6A Senior Surveyor)',
      qcStampDate: '27-Sep-2026 16:00 IST',
      heatNumber: 'WH-TREE-441-OIL',
      materialSpec:
          'AISI 4130 Forged Steel, EE-0.5 Material Class for Sour Service',
      coordinatesGps: '27°19\'05.1"N, 95°18\'12.3"E',
      chainage: 'Cellar Bay 01',
      elevationMsl: 120.4,
      delayReason: null,
      lidarScanVariance: 'Vertical alignment verified within 0.1°',
      isoX: 630,
      isoY: 530,
      isoZ: 42,
      category: 'EQUIPMENT',
    ),
    PhysicalAssetNode(
      id: 'AST-WP-02',
      tag: 'Production Manifold PM-04',
      name:
          'Wellpad Multi-Port Production & Test Flowline Header Manifold Skid',
      zoneId: 'WP-04',
      zoneName: 'Wellpad 04',
      status: AssetProgressStatus.inProgress,
      progressPercent: 65.0,
      linkedActivityId: 'PIP-L5-045',
      wbsCode: '02.01.02.02',
      assignedGang: 'Gang 4 — PetroFab Mechanical Crew',
      gangSupervisor: 'Vikram Joshi (Senior Piping Foreman)',
      gangWorkerCount: 14,
      qcStampNumber: 'OIL-QC-NDT-9412',
      qcStampStatus: 'IN-PROGRESS (Butt Welds 14/18 NDT Radiography Cleared)',
      qcInspector: 'R. K. Sharma (Level III NDT / OIL QA/QC)',
      qcStampDate: '29-Sep-2026 12:15 IST',
      heatNumber: 'MNF-HDR-6X52',
      materialSpec: '6" API 5L Gr. X52 Seamless with Class 600 Ball Valves',
      coordinatesGps: '27°19\'08.4"N, 95°18\'16.7"E',
      chainage: 'Manifold Slab',
      elevationMsl: 120.8,
      delayReason: null,
      lidarScanVariance: 'Flange orientation within 0.5° rotation tolerance',
      isoX: 710,
      isoY: 590,
      isoZ: 32,
      category: 'PIPING',
    ),
    PhysicalAssetNode(
      id: 'AST-WP-03',
      tag: 'Shutdown Valve ESDV-04',
      name: 'High-Integrity Pressure Protection System Emergency Shutdown Valve ESDV-04',
      zoneId: 'WP-04',
      zoneName: 'Wellpad 04',
      status: AssetProgressStatus.blocked,
      progressPercent: 30.0,
      linkedActivityId: 'INS-L5-049',
      wbsCode: '02.01.03.04',
      assignedGang: 'Gang 8 — Instrumentation & SCADA Team',
      gangSupervisor: 'Manas Jyoti Das (SCADA Systems Lead)',
      gangWorkerCount: 10,
      qcStampNumber: 'OIL-QC-INS-0091',
      qcStampStatus: 'REJECTED / HOLD (Actuator SIL-3 Certification Missing)',
      qcInspector: 'H. Sarma (Functional Safety TÜV Certified Engineer)',
      qcStampDate: '28-Sep-2026 15:40 IST',
      heatNumber: 'VAL-ESDV-SIL3-90',
      materialSpec:
          '8" Cl 600 Top-Entry Metal-Seated Ball Valve with Pneumatic Actuator',
      coordinatesGps: '27°19\'06.8"N, 95°18\'14.5"E',
      chainage: 'Wellpad Outlet',
      elevationMsl: 120.6,
      delayReason: 'SIL-3 factory calibration certificate missing from OEM documentation pack; installation suspended under FIDIC Cl. 7.4.',
      lidarScanVariance: 'Valve body mounted; actuator disconnected',
      isoX: 760,
      isoY: 510,
      isoZ: 35,
      category: 'INSTRUMENTATION',
    ),

    // --- Valve Station 12 ---
    PhysicalAssetNode(
      id: 'AST-VS-01',
      tag: 'Mainline Valve SV-12',
      name: '12" Class 600 Full-Bore Motor Operated Sectionalizing Valve SV-12',
      zoneId: 'VS-12',
      zoneName: 'Valve Station 12',
      status: AssetProgressStatus.erected,
      progressPercent: 100.0,
      linkedActivityId: 'PIP-L5-061',
      wbsCode: '03.01.01.01',
      assignedGang: 'Gang 6 — Valve & Pipeline Technicians',
      gangSupervisor: 'Pranjal Gogoi (Senior Valve Specialist)',
      gangWorkerCount: 12,
      qcStampNumber: 'OIL-QC-VAL-3108',
      qcStampStatus:
          'PASSED (Seat Leakage & Shell Hydrotest Verified Zero Leakage)',
      qcInspector: 'A. K. Bhattacharya (Chief Pipeline Inspector)',
      qcStampDate: '27-Sep-2026 10:30 IST',
      heatNumber: 'VAL-12-600-ROT',
      materialSpec:
          'API 6D Forged Steel Ball Valve with Rotork Electric Actuator',
      coordinatesGps: '27°18\'15.0"N, 95°19\'01.2"E',
      chainage: 'KP 12+450',
      elevationMsl: 115.2,
      delayReason: null,
      lidarScanVariance: 'Centerline aligned exactly to pipeline RoW',
      isoX: 1120,
      isoY: 850,
      isoZ: 30,
      category: 'PIPING',
    ),
    PhysicalAssetNode(
      id: 'AST-VS-02',
      tag: 'Actuator Power Skid APS-12',
      name: 'Solar-PV & Battery Backed UPS Actuator Power Station Skid APS-12',
      zoneId: 'VS-12',
      zoneName: 'Valve Station 12',
      status: AssetProgressStatus.inProgress,
      progressPercent: 65.0,
      linkedActivityId: 'ELE-L5-064',
      wbsCode: '03.01.02.03',
      assignedGang: 'Gang 8 — Instrumentation & SCADA Team',
      gangSupervisor: 'Manas Jyoti Das (SCADA Systems Lead)',
      gangWorkerCount: 8,
      qcStampNumber: 'OIL-QC-ELE-5520',
      qcStampStatus:
          'IN-PROGRESS (Solar String Inverters Connected & Grounded)',
      qcInspector: 'K. C. Deka (Electrical Inspectorate Assam)',
      qcStampDate: '29-Sep-2026 11:00 IST',
      heatNumber: 'PV-SKID-2026-VS12',
      materialSpec: '24V DC Industrial Battery Bank with 3.5 kW Solar Array',
      coordinatesGps: '27°18\'16.2"N, 95°19\'03.0"E',
      chainage: 'KP 12+460',
      elevationMsl: 115.5,
      delayReason: null,
      lidarScanVariance: 'Foundation pad aligned properly',
      isoX: 1200,
      isoY: 910,
      isoZ: 25,
      category: 'ELECTRICAL',
    ),
    PhysicalAssetNode(
      id: 'AST-VS-03',
      tag: 'Bypass Loop BML-12',
      name: '6" Sectionalizing Equalization & Depressurization Bypass Piping Loop',
      zoneId: 'VS-12',
      zoneName: 'Valve Station 12',
      status: AssetProgressStatus.blocked,
      progressPercent: 45.0,
      linkedActivityId: 'PIP-L5-070',
      wbsCode: '03.01.01.05',
      assignedGang: 'Gang 6 — Valve & Pipeline Technicians',
      gangSupervisor: 'Pranjal Gogoi (Senior Valve Specialist)',
      gangWorkerCount: 10,
      qcStampNumber: 'OIL-QC-NDT-8840',
      qcStampStatus: 'REJECTED (NDT Radiography Cluster Porosity on Weld W-14)',
      qcInspector: 'R. K. Sharma (Level III NDT / OIL QA/QC)',
      qcStampDate: '28-Sep-2026 16:45 IST',
      heatNumber: 'PIP-6X52-BML',
      materialSpec:
          '6" API 5L Gr. X52 Seamless Line Pipe with Heavy Wall Elbows',
      coordinatesGps: '27°18\'14.4"N, 95°18\'59.8"E',
      chainage: 'KP 12+445',
      elevationMsl: 115.0,
      delayReason: 'Cluster porosity defect detected on butt weld W-14; grinding and re-welding mandated under ASME B31.4.',
      lidarScanVariance: 'Cut-out mark verified on pipe exterior',
      isoX: 1060,
      isoY: 890,
      isoZ: 28,
      category: 'PIPING',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Initial camera view centering on overview
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerViewOnZone('ALL');
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _centerViewOnZone(String zoneId) {
    final Size screenSize = MediaQuery.of(context).size;
    double targetX = _canvasWidth / 2;
    double targetY = _canvasHeight / 2;
    double targetScale = 0.85;

    if (zoneId != 'ALL') {
      final zone = _zones.firstWhere((z) => z.id == zoneId);
      targetX = zone.focusX;
      targetY = zone.focusY;
      targetScale = zone.focusScale;
    }

    final double screenCenterX = screenSize.width / 2;
    final double screenCenterY = screenSize.height / 2;

    final Matrix4 newMatrix = Matrix4.identity()
      ..translateByDouble(screenCenterX, screenCenterY, 0.0, 1.0)
      ..scaleByDouble(targetScale, targetScale, 1.0, 1.0)
      ..translateByDouble(-targetX, -targetY, 0.0, 1.0);

    _transformationController.value = newMatrix;
  }

  void _zoomIn() {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    if (currentScale < 3.2) {
      final newScale = currentScale * 1.3;
      final Size screenSize = MediaQuery.of(context).size;
      final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);

      final Matrix4 updated = Matrix4.identity()
        ..translateByDouble(screenCenter.dx, screenCenter.dy, 0.0, 1.0)
        ..scaleByDouble(
          newScale / currentScale,
          newScale / currentScale,
          1.0,
          1.0,
        )
        ..translateByDouble(-screenCenter.dx, -screenCenter.dy, 0.0, 1.0)
        ..multiply(currentMatrix);

      _transformationController.value = updated;
    }
  }

  void _zoomOut() {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    if (currentScale > 0.45) {
      final newScale = currentScale / 1.3;
      final Size screenSize = MediaQuery.of(context).size;
      final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);

      final Matrix4 updated = Matrix4.identity()
        ..translateByDouble(screenCenter.dx, screenCenter.dy, 0.0, 1.0)
        ..scaleByDouble(
          newScale / currentScale,
          newScale / currentScale,
          1.0,
          1.0,
        )
        ..translateByDouble(-screenCenter.dx, -screenCenter.dy, 0.0, 1.0)
        ..multiply(currentMatrix);

      _transformationController.value = updated;
    }
  }

  List<PhysicalAssetNode> get _filteredAssets {
    return _assets.where((asset) {
      if (_selectedZoneId != 'ALL' && asset.zoneId != _selectedZoneId) {
        return false;
      }
      if (_selectedStatusFilter != null &&
          asset.status != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTag = asset.tag.toLowerCase().contains(query);
        final matchesName = asset.name.toLowerCase().contains(query);
        final matchesAct = asset.linkedActivityId.toLowerCase().contains(query);
        final matchesGang = asset.assignedGang.toLowerCase().contains(query);
        final matchesStamp = asset.qcStampNumber.toLowerCase().contains(query);
        if (!matchesTag &&
            !matchesName &&
            !matchesAct &&
            !matchesGang &&
            !matchesStamp) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _handleCanvasTap(TapUpDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Invert the transformation matrix to get canvas coordinates
    final matrix = _transformationController.value;
    final inverseMatrix = Matrix4.tryInvert(matrix);
    if (inverseMatrix == null) return;

    final transformed = MatrixUtils.transformPoint(
      inverseMatrix,
      localPosition,
    );

    // Find closest asset node within tap threshold
    PhysicalAssetNode? closestAsset;
    double minDistance = 50.0; // Hit radius

    for (final asset in _filteredAssets) {
      final Offset pinScreenPos = _getAssetPinPosition(asset);
      final double distance = (pinScreenPos - transformed).distance;
      if (distance < minDistance) {
        minDistance = distance;
        closestAsset = asset;
      }
    }

    if (closestAsset != null) {
      setState(() {
        _selectedAsset = closestAsset;
      });
      _showAssetDetailModal(closestAsset);
    }
  }

  Offset _getAssetPinPosition(PhysicalAssetNode asset) {
    if (_is3dIsometric) {
      return Offset(asset.isoX, asset.isoY - asset.isoZ);
    } else {
      return Offset(asset.isoX, asset.isoY);
    }
  }

  void _showAssetDetailModal(PhysicalAssetNode asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AssetDetailSheet(
        asset: asset,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAssets;
    final SiteZone? currentZone = _selectedZoneId == 'ALL'
        ? null
        : _zones.firstWhere((z) => z.id == _selectedZoneId);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // 1. Interactive 3D / Isometric Canvas
          GestureDetector(
            onTapUp: _handleCanvasTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.35,
              maxScale: 3.5,
              boundaryMargin: const EdgeInsets.all(1200),
              constrained: false,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(_canvasWidth, _canvasHeight),
                    painter: DigitalTwinPainter(
                      assets: filtered,
                      allAssets: _assets,
                      selectedAsset: _selectedAsset,
                      selectedZoneId: _selectedZoneId,
                      pulseValue: _pulseController.value,
                      is3dIsometric: _is3dIsometric,
                      showLidarCloud: _showLidarCloud,
                      showPipelineFlow: _showPipelineFlow,
                      showGangMarkers: _showGangMarkers,
                      showQcStamps: _showQcStamps,
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Top Interactive Zone Selector Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildZoneSelectorHeader(),
          ),

          // 3. Floating HUD: GIS Telemetry Badge (Top Right)
          Positioned(top: 76, right: 16, child: _buildGisTelemetryCard()),

          // 4. Quick Status Filter Pills (Under Zone Selector)
          Positioned(top: 76, left: 16, child: _buildStatusFilterPills()),

          // 5. Floating Navigation & Layer Control Toolbar (Bottom Right)
          Positioned(
            bottom: currentZone != null ? 140 : 24,
            right: 16,
            child: _buildFloatingControls(),
          ),

          // 6. Bottom Zone Summary HUD (when zone is selected)
          if (currentZone != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 80,
              child: _buildBottomZoneSummaryCard(currentZone),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 3,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: AppTheme.textPrimary,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: _isSearchExpanded
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search asset tag, L5 ID, gang, stamp...',
                hintStyle: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearchExpanded = false;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x330284C7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppTheme.primaryLight,
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'DIGITAL TWIN 3D',
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Oil India Duliajan GIS',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Pipeline Spread 2 & Gas Gathering Station (GGS)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
      actions: [
        if (!_isSearchExpanded)
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppTheme.textPrimary),
            tooltip: 'Search Asset',
            onPressed: () => setState(() => _isSearchExpanded = true),
          ),
        IconButton(
          icon: Icon(
            _is3dIsometric ? Icons.view_in_ar_rounded : Icons.map_rounded,
            color: _is3dIsometric ? AppTheme.primaryLight : AppTheme.secondary,
          ),
          tooltip: _is3dIsometric
              ? 'Switch to 2D Ortho'
              : 'Switch to 3D Isometric',
          onPressed: () {
            setState(() {
              _is3dIsometric = !_is3dIsometric;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _is3dIsometric
                      ? 'Switched to 3D Isometric Projection'
                      : 'Switched to 2D GIS Orthographic View',
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: AppTheme.surfaceCard,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.layers_outlined, color: AppTheme.textPrimary),
          tooltip: 'Map Layers',
          onPressed: _showLayersDialog,
        ),
      ],
    );
  }

  Widget _buildZoneSelectorHeader() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xF2111C38),
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x60000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          // "All Zones" Button
          _buildZoneTabButton(
            id: 'ALL',
            label: 'All Zones (Corridor)',
            code: 'GIS',
            count: _assets.length,
            isSelected: _selectedZoneId == 'ALL',
            accentColor: AppTheme.primaryLight,
            onTap: () {
              setState(() {
                _selectedZoneId = 'ALL';
                _selectedAsset = null;
              });
              _centerViewOnZone('ALL');
            },
          ),
          const SizedBox(width: 8),

          // Zone Tabs
          ..._zones.map((zone) {
            final isSelected = _selectedZoneId == zone.id;
            final zoneAssets = _assets
                .where((a) => a.zoneId == zone.id)
                .toList();
            final hasBlocked = zoneAssets.any(
              (a) => a.status == AssetProgressStatus.blocked,
            );
            final Color badgeColor = hasBlocked
                ? const Color(0xFFFF5252)
                : (zone.completionPercent >= 80
                      ? const Color(0xFF4EDEA3)
                      : const Color(0xFFFFB95F));

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildZoneTabButton(
                id: zone.id,
                label: zone.name,
                code: zone.code,
                count: zoneAssets.length,
                isSelected: isSelected,
                accentColor: badgeColor,
                onTap: () {
                  setState(() {
                    _selectedZoneId = zone.id;
                    _selectedAsset = null;
                  });
                  _centerViewOnZone(zone.id);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildZoneTabButton({
    required String id,
    required String label,
    required String code,
    required int count,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.18)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accentColor : AppTheme.border,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? accentColor : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterPills() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xEB162347),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterChip(
            label: 'All',
            count: _assets.length,
            color: AppTheme.textSecondary,
            isSelected: _selectedStatusFilter == null,
            onTap: () => setState(() => _selectedStatusFilter = null),
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: '100% Erected',
            count: _assets
                .where((a) => a.status == AssetProgressStatus.erected)
                .length,
            color: const Color(0xFF4EDEA3),
            isSelected: _selectedStatusFilter == AssetProgressStatus.erected,
            onTap: () => setState(
              () => _selectedStatusFilter = AssetProgressStatus.erected,
            ),
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: '65% In-Progress',
            count: _assets
                .where((a) => a.status == AssetProgressStatus.inProgress)
                .length,
            color: const Color(0xFFFFB95F),
            isSelected: _selectedStatusFilter == AssetProgressStatus.inProgress,
            onTap: () => setState(
              () => _selectedStatusFilter = AssetProgressStatus.inProgress,
            ),
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Blocked',
            count: _assets
                .where((a) => a.status == AssetProgressStatus.blocked)
                .length,
            color: const Color(0xFFFF5252),
            isSelected: _selectedStatusFilter == AssetProgressStatus.blocked,
            onTap: () => setState(
              () => _selectedStatusFilter = AssetProgressStatus.blocked,
            ),
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Not Started',
            count: _assets
                .where((a) => a.status == AssetProgressStatus.notStarted)
                .length,
            color: const Color(0xFF64748B),
            isSelected: _selectedStatusFilter == AssetProgressStatus.notStarted,
            onTap: () => setState(
              () => _selectedStatusFilter = AssetProgressStatus.notStarted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              '$label ($count)',
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGisTelemetryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xEB162347),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 8)],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.satellite_alt_rounded,
                size: 13,
                color: AppTheme.primaryLight,
              ),
              SizedBox(width: 5),
              Text(
                '27°18\'24"N, 95°19\'36"E',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            'Datum: WGS84 • Alt: 118m MSL • Zone 46N',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFabButton(
          icon: Icons.add_rounded,
          tooltip: 'Zoom In',
          onPressed: _zoomIn,
        ),
        const SizedBox(height: 8),
        _buildFabButton(
          icon: Icons.remove_rounded,
          tooltip: 'Zoom Out',
          onPressed: _zoomOut,
        ),
        const SizedBox(height: 8),
        _buildFabButton(
          icon: Icons.center_focus_strong_rounded,
          tooltip: 'Recenter View',
          onPressed: () => _centerViewOnZone(_selectedZoneId),
        ),
      ],
    );
  }

  Widget _buildFabButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x50000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: AppTheme.textPrimary),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomZoneSummaryCard(SiteZone zone) {
    final zoneAssets = _assets.where((a) => a.zoneId == zone.id).toList();
    final erectedCount = zoneAssets
        .where((a) => a.status == AssetProgressStatus.erected)
        .length;
    final inProgressCount = zoneAssets
        .where((a) => a.status == AssetProgressStatus.inProgress)
        .length;
    final blockedCount = zoneAssets
        .where((a) => a.status == AssetProgressStatus.blocked)
        .length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xF2162347),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x60000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x330284C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primaryLight, width: 1),
                ),
                child: Text(
                  zone.code,
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${zone.type} • ${zone.chainage}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${zone.completionPercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Color(0xFF4EDEA3),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Completed',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: zone.completionPercent / 100.0,
            backgroundColor: AppTheme.background,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4EDEA3)),
            minHeight: 5,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(
                label: 'Erected',
                value: '$erectedCount',
                color: const Color(0xFF4EDEA3),
              ),
              _buildMiniMetric(
                label: 'In-Progress',
                value: '$inProgressCount',
                color: const Color(0xFFFFB95F),
              ),
              _buildMiniMetric(
                label: 'Blocked',
                value: '$blockedCount',
                color: const Color(0xFFFF5252),
              ),
              _buildMiniMetric(
                label: 'Active Gangs',
                value: '${zone.activeGangs}',
                color: AppTheme.primaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showLayersDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.layers_rounded, color: AppTheme.primaryLight),
              SizedBox(width: 8),
              Text(
                'Digital Twin Layers',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: _showLidarCloud,
                activeThumbColor: AppTheme.primaryLight,
                title: const Text(
                  'Drone LiDAR Point Cloud',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
                subtitle: const Text(
                  'Dense point cloud overlay & scan variance',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
                onChanged: (val) {
                  setDialogState(() => _showLidarCloud = val);
                  setState(() => _showLidarCloud = val);
                },
              ),
              SwitchListTile(
                value: _showPipelineFlow,
                activeThumbColor: AppTheme.primaryLight,
                title: const Text(
                  'Pipeline Fluid Flow Vector',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
                subtitle: const Text(
                  'Animated crude transfer hydraulic vectors',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
                onChanged: (val) {
                  setDialogState(() => _showPipelineFlow = val);
                  setState(() => _showPipelineFlow = val);
                },
              ),
              SwitchListTile(
                value: _showGangMarkers,
                activeThumbColor: AppTheme.primaryLight,
                title: const Text(
                  'Workforce GPS Geofence Tags',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
                subtitle: const Text(
                  'Real-time verified gang deployment positions',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
                onChanged: (val) {
                  setDialogState(() => _showGangMarkers = val);
                  setState(() => _showGangMarkers = val);
                },
              ),
              SwitchListTile(
                value: _showQcStamps,
                activeThumbColor: AppTheme.primaryLight,
                title: const Text(
                  'Always Show QC Inspection Stamps',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
                subtitle: const Text(
                  'Float digital NDT stamps directly over pins',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
                onChanged: (val) {
                  setDialogState(() => _showQcStamps = val);
                  setState(() => _showQcStamps = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet displaying rich linked engineering metadata for an asset node
class _AssetDetailSheet extends StatelessWidget {
  final PhysicalAssetNode asset;
  final VoidCallback onClose;

  const _AssetDetailSheet({required this.asset, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0x8064748B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Zone Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: asset.status.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: asset.status.color,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              asset.status.icon,
                              size: 14,
                              color: asset.status.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              asset.status.label.toUpperCase(),
                              style: TextStyle(
                                color: asset.status.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Asset Tag & Name
                  Text(
                    asset.tag,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    asset.name,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Zone & Chainage Pill Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoBadge(
                        Icons.location_on_rounded,
                        asset.zoneName,
                      ),
                      _buildInfoBadge(Icons.straighten_rounded, asset.chainage),
                      _buildInfoBadge(
                        Icons.height_rounded,
                        '${asset.elevationMsl}m MSL',
                      ),
                      _buildInfoBadge(Icons.category_rounded, asset.category),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Physical Erection Progress',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${asset.progressPercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: asset.status.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: asset.progressPercent / 100.0,
                        backgroundColor: AppTheme.surfaceCard,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          asset.status.color,
                        ),
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Blocker Notice (if blocked)
                  if (asset.status == AssetProgressStatus.blocked &&
                      asset.delayReason != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x1FFF5252),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF5252),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFFF5252),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CRITICAL BOTTLENECK / DELAY NOTICE',
                                  style: TextStyle(
                                    color: Color(0xFFFF5252),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  asset.delayReason!,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 3 CORE MANDATORY PANELS:
                  // 1. Linked L5 Activity ID
                  _buildSectionHeader(
                    '1. LINKED L5 SCHEDULE ACTIVITY',
                    Icons.calendar_month_rounded,
                  ),
                  const SizedBox(height: 8),
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
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x330284C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.primaryLight,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                asset.linkedActivityId,
                                style: const TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'WBS Code: ${asset.wbsCode}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          asset.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: AppTheme.secondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Primavera P6 Critical Path Activity',
                              style: TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Assigned Gang
                  _buildSectionHeader(
                    '2. ASSIGNED WORKFORCE GANG',
                    Icons.groups_rounded,
                  ),
                  const SizedBox(height: 8),
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
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.surfaceContainerHigh,
                              child: Icon(
                                Icons.engineering_rounded,
                                color: AppTheme.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    asset.assignedGang,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Supervisor: ${asset.gangSupervisor}',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11.5,
                                    ),
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
                            _buildMetaField(
                              'Deployed Laborers',
                              '${asset.gangWorkerCount} Verified',
                            ),
                            _buildMetaField(
                              'Geofence Verification',
                              '100% Biometric',
                            ),
                            _buildMetaField('Shift Hours', '07:00 - 18:00 IST'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Latest QC Inspection Stamp
                  _buildSectionHeader(
                    '3. LATEST QC INSPECTION STAMP',
                    Icons.verified_rounded,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: asset.status == AssetProgressStatus.blocked
                            ? const Color(0x80FF5252)
                            : (asset.status == AssetProgressStatus.erected
                                  ? const Color(0x804EDEA3)
                                  : AppTheme.border),
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
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        (asset.status ==
                                                    AssetProgressStatus.erected
                                                ? const Color(0xFF4EDEA3)
                                                : AppTheme.secondary)
                                            .withValues(alpha: 0.18),
                                  ),
                                  child: Icon(
                                    Icons.military_tech_rounded,
                                    size: 18,
                                    color:
                                        asset.status ==
                                            AssetProgressStatus.erected
                                        ? const Color(0xFF4EDEA3)
                                        : AppTheme.secondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      asset.qcStampNumber,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    Text(
                                      'Stamped: ${asset.qcStampDate}',
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (asset.status == AssetProgressStatus.erected
                                            ? const Color(0xFF4EDEA3)
                                            : (asset.status ==
                                                      AssetProgressStatus
                                                          .blocked
                                                  ? const Color(0xFFFF5252)
                                                  : AppTheme.secondary))
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                asset.status == AssetProgressStatus.erected
                                    ? 'CERTIFIED'
                                    : (asset.status ==
                                              AssetProgressStatus.blocked
                                          ? 'FLAGGED'
                                          : 'INSPECTION OK'),
                                style: TextStyle(
                                  color:
                                      asset.status ==
                                          AssetProgressStatus.erected
                                      ? const Color(0xFF4EDEA3)
                                      : (asset.status ==
                                                AssetProgressStatus.blocked
                                            ? const Color(0xFFFF5252)
                                            : AppTheme.secondary),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          asset.qcStampStatus,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Inspector: ${asset.qcInspector}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const Divider(color: AppTheme.border, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetaField(
                              'Heat / MTR Batch',
                              asset.heatNumber,
                            ),
                            _buildMetaField(
                              'Material Specification',
                              asset.materialSpec,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Technical Telemetry & Drone LiDAR
                  _buildSectionHeader(
                    'TECHNICAL SPECS & LIDAR ALIGNMENT',
                    Icons.analytics_outlined,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'GPS Coordinates',
                          asset.coordinatesGps,
                        ),
                        const Divider(color: AppTheme.border, height: 16),
                        _buildDetailRow('Pipeline Chainage', asset.chainage),
                        const Divider(color: AppTheme.border, height: 16),
                        _buildDetailRow(
                          'Elevation',
                          '${asset.elevationMsl} m Above MSL',
                        ),
                        if (asset.lidarScanVariance != null) ...[
                          const Divider(color: AppTheme.border, height: 16),
                          _buildDetailRow(
                            'Drone LiDAR Variance',
                            asset.lidarScanVariance!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.verified_outlined, size: 16),
                          label: const Text('Verify Stamp'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'QC Stamp ${asset.qcStampNumber} verified against Oil India NDT Registry.',
                                ),
                                backgroundColor: AppTheme.surfaceCard,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.assignment_turned_in_rounded,
                            size: 16,
                          ),
                          label: const Text('Log DPR / Update'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Navigating to DPR entry for Activity ${asset.linkedActivityId}',
                                ),
                                backgroundColor: AppTheme.surfaceCard,
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
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryLight),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.primaryLight,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom Painter rendering the 3D / Isometric Digital Twin GIS Map
class DigitalTwinPainter extends CustomPainter {
  final List<PhysicalAssetNode> assets;
  final List<PhysicalAssetNode> allAssets;
  final PhysicalAssetNode? selectedAsset;
  final String selectedZoneId;
  final double pulseValue;
  final bool is3dIsometric;
  final bool showLidarCloud;
  final bool showPipelineFlow;
  final bool showGangMarkers;
  final bool showQcStamps;

  DigitalTwinPainter({
    required this.assets,
    required this.allAssets,
    required this.selectedAsset,
    required this.selectedZoneId,
    required this.pulseValue,
    required this.is3dIsometric,
    required this.showLidarCloud,
    required this.showPipelineFlow,
    required this.showGangMarkers,
    required this.showQcStamps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawTerrainAndGrid(canvas, size);
    _drawZoneGeofencePerimeters(canvas);
    _drawPipelineNetwork(canvas);
    _drawPhysicalStructures(canvas);
    if (showLidarCloud) _drawLidarPointCloud(canvas);
    if (showGangMarkers) _drawWorkforceLocations(canvas);
    _drawAssetPins(canvas);
  }

  /// 1. Ground plane grid, terrain elevation contours, and GIS north arrow
  void _drawTerrainAndGrid(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xFF090E1F);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Subtle isometric or orthogonal grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF14203F)
      ..strokeWidth = 1.0;

    const double step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Topographic / Elevation contour lines representing Duliajan tea-garden basin
    final contourPaint = Paint()
      ..color = const Color(0xFF192A54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path1 = Path();
    path1.moveTo(200, 400);
    path1.cubicTo(600, 320, 1000, 480, 1500, 360);
    path1.cubicTo(1800, 300, 2100, 420, 2300, 400);
    canvas.drawPath(path1, contourPaint);

    final path2 = Path();
    path2.moveTo(100, 800);
    path2.cubicTo(500, 720, 950, 920, 1400, 820);
    path2.cubicTo(1750, 750, 2050, 860, 2300, 830);
    canvas.drawPath(path2, contourPaint);

    final path3 = Path();
    path3.moveTo(150, 1300);
    path3.cubicTo(650, 1200, 1100, 1420, 1600, 1300);
    path3.cubicTo(1950, 1220, 2200, 1360, 2350, 1320);
    canvas.drawPath(path3, contourPaint);

    final path4 = Path();
    path4.moveTo(100, 1750);
    path4.cubicTo(550, 1650, 1050, 1850, 1550, 1720);
    path4.cubicTo(1900, 1640, 2150, 1760, 2300, 1740);
    canvas.drawPath(path4, contourPaint);

    // River bed representation: Burhi Dihing River crossing
    final riverPaint = Paint()
      ..color = const Color(0x280284C7)
      ..style = PaintingStyle.fill;
    final riverBorder = Paint()
      ..color = const Color(0x4038BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final riverPath = Path();
    riverPath.moveTo(1450, 0);
    riverPath.cubicTo(1550, 500, 1700, 1000, 1800, 1500);
    riverPath.cubicTo(1850, 1800, 1920, 2100, 1950, 2400);
    riverPath.lineTo(2100, 2400);
    riverPath.cubicTo(2070, 2100, 2000, 1800, 1950, 1500);
    riverPath.cubicTo(1850, 1000, 1700, 500, 1600, 0);
    riverPath.close();
    canvas.drawPath(riverPath, riverPaint);
    canvas.drawPath(riverPath, riverBorder);

    // River Label
    _drawText(
      canvas,
      'BURHI DIHING RIVER CORRIDOR (HDD CROSSING)',
      const Offset(1720, 1080),
      const TextStyle(
        color: Color(0x7038BDF8),
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );

    // GIS North Compass
    _drawNorthCompass(canvas, const Offset(120, 120));
  }

  void _drawNorthCompass(Canvas canvas, Offset center) {
    final borderPaint = Paint()
      ..color = const Color(0xFF26396E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 24, borderPaint);

    final nPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;
    final arrowPath = Path();
    arrowPath.moveTo(center.dx, center.dy - 20);
    arrowPath.lineTo(center.dx + 5, center.dy);
    arrowPath.lineTo(center.dx - 5, center.dy);
    arrowPath.close();
    canvas.drawPath(arrowPath, nPaint);

    final sPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;
    final sArrow = Path();
    sArrow.moveTo(center.dx, center.dy + 20);
    sArrow.lineTo(center.dx + 5, center.dy);
    sArrow.lineTo(center.dx - 5, center.dy);
    sArrow.close();
    canvas.drawPath(sArrow, sPaint);

    _drawText(
      canvas,
      'N',
      Offset(center.dx - 4, center.dy - 34),
      const TextStyle(
        color: Color(0xFF38BDF8),
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 2. Bounding geofences and neon perimeters around site zones
  void _drawZoneGeofencePerimeters(Canvas canvas) {
    // Wellpad 04 Geofence
    _drawZoneBox(
      canvas,
      rect: const Rect.fromLTWH(520, 420, 360, 280),
      label: 'ZONE WP-04 • WELLPAD 04',
      isSelected: selectedZoneId == 'WP-04',
    );

    // Valve Station 12 Geofence
    _drawZoneBox(
      canvas,
      rect: const Rect.fromLTWH(980, 780, 320, 240),
      label: 'ZONE VS-12 • VALVE STATION 12',
      isSelected: selectedZoneId == 'VS-12',
    );

    // Crude Pipeline Spread 2 Geofence
    _drawZoneBox(
      canvas,
      rect: const Rect.fromLTWH(1380, 1060, 420, 340),
      label: 'ZONE CPS-02 • CRUDE PIPELINE SPREAD 2',
      isSelected: selectedZoneId == 'CPS-02',
    );

    // Central Tank Farm Geofence
    _drawZoneBox(
      canvas,
      rect: const Rect.fromLTWH(660, 1400, 380, 340),
      label: 'ZONE CTF-01 • CENTRAL TANK FARM',
      isSelected: selectedZoneId == 'CTF-01',
    );

    // Gas Gathering Station Geofence
    _drawZoneBox(
      canvas,
      rect: const Rect.fromLTWH(1640, 480, 400, 360),
      label: 'ZONE GGS-01 • GAS GATHERING STATION',
      isSelected: selectedZoneId == 'GGS-01',
    );
  }

  void _drawZoneBox(
    Canvas canvas, {
    required Rect rect,
    required String label,
    required bool isSelected,
  }) {
    final Color strokeColor = isSelected
        ? const Color(0xFF38BDF8)
        : const Color(0xFF1E2E5C);
    final Color fillColor = isSelected
        ? const Color(0x1838BDF8)
        : const Color(0x0C111C38);

    final bgPaint = Paint()..color = fillColor;
    final borderPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      borderPaint,
    );

    // Corner brackets
    final cornerPaint = Paint()
      ..color = isSelected ? const Color(0xFF38BDF8) : const Color(0xFF26396E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    const double cornerLen = 16.0;
    // Top-Left
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(0, cornerLen),
      cornerPaint,
    );
    // Top-Right
    canvas.drawLine(
      rect.topRight,
      rect.topRight - const Offset(cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(0, cornerLen),
      cornerPaint,
    );
    // Bottom-Left
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(0, cornerLen),
      cornerPaint,
    );
    // Bottom-Right
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - const Offset(cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - const Offset(0, cornerLen),
      cornerPaint,
    );

    // Label Header
    _drawText(
      canvas,
      label,
      rect.topLeft + const Offset(12, 10),
      TextStyle(
        color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }

  /// 3. Pipeline network linking Wellpad, Valve Station, Spread 2, Tank Farm, and GGS
  void _drawPipelineNetwork(Canvas canvas) {
    // Trunk crude oil pipeline path (12" NB API 5L X52)
    final trunkPipePath = Path();
    trunkPipePath.moveTo(710, 590); // Wellpad 04 Manifold
    trunkPipePath.lineTo(1120, 850); // Valve Station 12
    trunkPipePath.lineTo(1540, 1180); // Pipe Spool 24-A
    trunkPipePath.lineTo(1680, 1260); // HDD Pull Head
    trunkPipePath.lineTo(940, 1560); // Central Tank Farm Booster Pump

    // Flare / Associated Gas line to GGS
    final gasPipePath = Path();
    gasPipePath.moveTo(710, 590); // Wellpad
    gasPipePath.lineTo(1780, 620); // GGS Compressor Package
    gasPipePath.lineTo(1850, 710); // Knockout Drum
    gasPipePath.lineTo(1940, 560); // Flare Header

    // 1. Pipeline Outer Trench / Shading
    final trenchPaint = Paint()
      ..color = const Color(0x30162347)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(trunkPipePath, trenchPaint);

    // 2. Main Metallic Steel Pipe Body
    final pipeBodyPaint = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(trunkPipePath, pipeBodyPaint);

    // 3. Highlight Specular Line
    final pipeHighlightPaint = Paint()
      ..color = const Color(0x6638BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(trunkPipePath, pipeHighlightPaint);

    // Gas Line Body (Greenish-Cyan)
    final gasBodyPaint = Paint()
      ..color = const Color(0xFF0F4C5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(gasPipePath, gasBodyPaint);

    // Animated Hydraulic Flow Pulses
    if (showPipelineFlow) {
      final pulseFlowPaint = Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Draw glowing fluid flow markers along the path
      final metrics = trunkPipePath.computeMetrics();
      for (final metric in metrics) {
        final double length = metric.length;
        final double pulseOffset = (pulseValue * 120.0) % length;
        for (double d = pulseOffset; d < length; d += 140.0) {
          final tangent = metric.getTangentForOffset(d);
          if (tangent != null) {
            canvas.drawCircle(tangent.position, 3.5, pulseFlowPaint);
            // Draw small directional tail
            final tailPos = tangent.position - (tangent.vector * 8.0);
            canvas.drawLine(tangent.position, tailPos, pulseFlowPaint);
          }
        }
      }
    }
  }

  /// 4. 3D Isometric / 2D Physical Structures
  void _drawPhysicalStructures(Canvas canvas) {
    if (is3dIsometric) {
      _draw3dIsometricWellhead(canvas, const Offset(630, 530));
      _draw3dIsometricValvePit(canvas, const Offset(1120, 850));
      _draw3dIsometricPipeSpool(canvas, const Offset(1540, 1180));
      _draw3dIsometricPumpFoundation(canvas, const Offset(850, 1530));
      _draw3dIsometricStorageTank(canvas, const Offset(740, 1640));
      _draw3dIsometricCompressorHall(canvas, const Offset(1780, 620));
      _draw3dIsometricFlareTower(canvas, const Offset(1940, 560));
    } else {
      _draw2dTopDownStructures(canvas);
    }
  }

  // --- 3D Isometric Structure Renderers ---

  void _draw3dIsometricPipeSpool(Canvas canvas, Offset pos) {
    // Concrete Trench & Spool 24-A
    final trench = Paint()..color = const Color(0xFF14203F);
    canvas.drawRect(
      Rect.fromCenter(center: pos, width: 70, height: 26),
      trench,
    );

    // Pipe Spool Cylinders in 3D isometric angle
    final pipePaint = Paint()..color = const Color(0xFF2A4365);
    final weldPaint = Paint()
      ..color = const Color(0xFFFFB95F); // Golden amber weld

    canvas.drawLine(
      pos - const Offset(28, 6),
      pos + const Offset(28, 6),
      pipePaint..strokeWidth = 8,
    );
    // Welded collar joint
    canvas.drawCircle(pos, 5, weldPaint);
    canvas.drawCircle(pos, 2.5, Paint()..color = Colors.white);
  }

  void _draw3dIsometricPumpFoundation(Canvas canvas, Offset pos) {
    // Concrete Plinth Foundation B (3D beveled block)
    final topFace = Path();
    topFace.moveTo(pos.dx, pos.dy - 16);
    topFace.lineTo(pos.dx + 28, pos.dy - 2);
    topFace.lineTo(pos.dx, pos.dy + 12);
    topFace.lineTo(pos.dx - 28, pos.dy - 2);
    topFace.close();

    final topPaint = Paint()..color = const Color(0xFF243B55);
    final edgePaint = Paint()
      ..color = const Color(0xFF4EDEA3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(topFace, topPaint);
    canvas.drawPath(topFace, edgePaint);

    // Plinth Depth Faces
    final rightFace = Path();
    rightFace.moveTo(pos.dx, pos.dy + 12);
    rightFace.lineTo(pos.dx + 28, pos.dy - 2);
    rightFace.lineTo(pos.dx + 28, pos.dy + 14);
    rightFace.lineTo(pos.dx, pos.dy + 28);
    rightFace.close();
    canvas.drawPath(rightFace, Paint()..color = const Color(0xFF17263C));

    final leftFace = Path();
    leftFace.moveTo(pos.dx, pos.dy + 12);
    leftFace.lineTo(pos.dx - 28, pos.dy - 2);
    leftFace.lineTo(pos.dx - 28, pos.dy + 14);
    leftFace.lineTo(pos.dx, pos.dy + 28);
    leftFace.close();
    canvas.drawPath(leftFace, Paint()..color = const Color(0xFF0F1B2C));

    // Anchor bolt pins
    final boltPaint = Paint()..color = const Color(0xFF4EDEA3);
    canvas.drawCircle(pos + const Offset(-12, 0), 2, boltPaint);
    canvas.drawCircle(pos + const Offset(12, 0), 2, boltPaint);
    canvas.drawCircle(pos + const Offset(0, -6), 2, boltPaint);
    canvas.drawCircle(pos + const Offset(0, 6), 2, boltPaint);
  }

  void _draw3dIsometricCompressorHall(Canvas canvas, Offset pos) {
    // 3D Extruded Industrial Compressor Skid
    final skidTop = Path();
    skidTop.moveTo(pos.dx, pos.dy - 24);
    skidTop.lineTo(pos.dx + 36, pos.dy - 4);
    skidTop.lineTo(pos.dx, pos.dy + 16);
    skidTop.lineTo(pos.dx - 36, pos.dy - 4);
    skidTop.close();

    canvas.drawPath(skidTop, Paint()..color = const Color(0xFF1E3A5F));
    canvas.drawPath(
      skidTop,
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Compressor engine cylinders on top
    final enginePaint = Paint()..color = const Color(0xFF2C5282);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: pos + const Offset(0, -4),
          width: 34,
          height: 16,
        ),
        const Radius.circular(4),
      ),
      enginePaint,
    );
  }

  void _draw3dIsometricFlareTower(Canvas canvas, Offset pos) {
    // Tall vertical flare stack truss with flare tip
    const double stackHeight = 55.0;
    final basePos = pos;
    final tipPos = pos - const Offset(0, stackHeight);

    // Steel Lattice Truss Legs
    final trussPaint = Paint()
      ..color = const Color(0xFF4EDEA3)
      ..strokeWidth = 1.4;

    canvas.drawLine(basePos + const Offset(-10, 0), tipPos, trussPaint);
    canvas.drawLine(basePos + const Offset(10, 0), tipPos, trussPaint);

    // Cross bracings
    for (int i = 1; i <= 4; i++) {
      final double frac = i / 5.0;
      final y = basePos.dy - (stackHeight * frac);
      final span = 10.0 * (1.0 - frac);
      canvas.drawLine(
        Offset(basePos.dx - span, y),
        Offset(basePos.dx + span, y),
        trussPaint,
      );
    }

    // Flare Flame at Tip (Animated Glow)
    final double flameGlow = 8.0 + (pulseValue * 4.0);
    final flameGlowPaint = Paint()
      ..color = const Color(0x80FFB95F)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(tipPos - const Offset(0, 4), flameGlow, flameGlowPaint);

    final flameCorePaint = Paint()..color = const Color(0xFFFF5252);
    canvas.drawCircle(tipPos - const Offset(0, 4), 4.5, flameCorePaint);
    canvas.drawCircle(
      tipPos - const Offset(0, 5),
      2.0,
      Paint()..color = Colors.white,
    );
  }

  void _draw3dIsometricStorageTank(Canvas canvas, Offset pos) {
    // Cylindrical Tank TK-101
    const double radius = 32.0;
    const double height = 30.0;

    // Cylinder Base
    final tankBaseRect = Rect.fromCenter(
      center: pos,
      width: radius * 2,
      height: radius,
    );
    canvas.drawOval(tankBaseRect, Paint()..color = const Color(0xFF101C36));

    // Cylinder Wall
    final wallPath = Path();
    wallPath.moveTo(pos.dx - radius, pos.dy);
    wallPath.lineTo(pos.dx - radius, pos.dy - height);
    wallPath.arcToPoint(
      Offset(pos.dx + radius, pos.dy - height),
      radius: const Radius.elliptical(radius, radius / 2),
      clockwise: false,
    );
    wallPath.lineTo(pos.dx + radius, pos.dy);
    wallPath.arcToPoint(
      Offset(pos.dx - radius, pos.dy),
      radius: const Radius.elliptical(radius, radius / 2),
      clockwise: true,
    );
    wallPath.close();

    final wallPaint = Paint()
      ..shader =
          const LinearGradient(
            colors: [Color(0xFF1E2E5C), Color(0xFF283E7A), Color(0xFF162347)],
          ).createShader(
            Rect.fromLTWH(pos.dx - radius, pos.dy - height, radius * 2, height),
          );
    canvas.drawPath(wallPath, wallPaint);

    // Floating Roof Top
    final roofRect = Rect.fromCenter(
      center: pos - Offset(0, height),
      width: radius * 2,
      height: radius,
    );
    canvas.drawOval(roofRect, Paint()..color = const Color(0xFF2E4380));
    canvas.drawOval(
      roofRect,
      Paint()
        ..color = const Color(0xFF4EDEA3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _draw3dIsometricWellhead(Canvas canvas, Offset pos) {
    // Christmas tree vertical valve assembly
    final steelPaint = Paint()..color = const Color(0xFF38BDF8);
    // Vertical riser
    canvas.drawLine(
      pos,
      pos - const Offset(0, 36),
      steelPaint..strokeWidth = 5,
    );
    // Master valve wing horizontal arms
    canvas.drawLine(
      pos - const Offset(16, 20),
      pos + const Offset(16, -20),
      steelPaint..strokeWidth = 3,
    );
    // Handwheels & pressure gauges
    canvas.drawCircle(
      pos - const Offset(16, 20),
      4,
      Paint()..color = const Color(0xFFFFB95F),
    );
    canvas.drawCircle(
      pos + const Offset(16, -20),
      4,
      Paint()..color = const Color(0xFFFFB95F),
    );
    canvas.drawCircle(
      pos - const Offset(0, 38),
      3.5,
      Paint()..color = const Color(0xFF4EDEA3),
    );
  }

  void _draw3dIsometricValvePit(Canvas canvas, Offset pos) {
    // Valve Station 12 concrete pit
    final pitRect = Rect.fromCenter(center: pos, width: 44, height: 32);
    canvas.drawRect(pitRect, Paint()..color = const Color(0xFF14203F));
    canvas.drawRect(
      pitRect,
      Paint()
        ..color = const Color(0xFF26396E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Motorized Actuator Valve in Center
    canvas.drawCircle(pos, 7, Paint()..color = const Color(0xFF4EDEA3));
    canvas.drawCircle(pos, 3, Paint()..color = Colors.white);
  }

  void _draw2dTopDownStructures(Canvas canvas) {
    for (final asset in allAssets) {
      final pos = Offset(asset.isoX, asset.isoY);
      canvas.drawCircle(
        pos,
        14,
        Paint()
          ..color = const Color(0xFF162347)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        pos,
        14,
        Paint()
          ..color = const Color(0xFF26396E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  /// 5. Drone LiDAR Point Cloud Scatter Overlay
  void _drawLidarPointCloud(Canvas canvas) {
    final lidarPaint = Paint()..color = const Color(0x6038BDF8);
    // Draw clusters of tiny laser points around structures
    final List<Offset> points = [
      const Offset(1530, 1175),
      const Offset(1545, 1170),
      const Offset(1550, 1185),
      const Offset(1535, 1188),
      const Offset(1542, 1178),
      const Offset(1525, 1182),
      const Offset(840, 1520),
      const Offset(860, 1525),
      const Offset(855, 1540),
      const Offset(845, 1535),
      const Offset(850, 1528),
      const Offset(865, 1532),
      const Offset(1770, 610),
      const Offset(1790, 615),
      const Offset(1785, 630),
      const Offset(1775, 625),
      const Offset(1795, 620),
      const Offset(1782, 612),
      const Offset(1930, 545),
      const Offset(1945, 540),
      const Offset(1950, 555),
      const Offset(1935, 565),
      const Offset(1940, 530),
      const Offset(1948, 570),
    ];

    for (final pt in points) {
      canvas.drawCircle(pt, 1.2, lidarPaint);
    }
  }

  /// 6. Workforce GPS verified positions in the field
  void _drawWorkforceLocations(Canvas canvas) {
    final List<Offset> gangPositions = [
      const Offset(1510, 1160), // Gang 4 at Pipe Spool
      const Offset(880, 1510), // Gang 2 at Pump Foundation
      const Offset(1750, 640), // Gang 7 at Compressor Package
      const Offset(1910, 580), // Gang 5 at Flare Header
      const Offset(670, 560), // Gang 1 at Wellpad
      const Offset(1150, 870), // Gang 6 at Valve Station
    ];

    final workerIconPaint = Paint()..color = const Color(0xFFFFB95F);
    for (final gPos in gangPositions) {
      canvas.drawCircle(gPos, 4.0, workerIconPaint);
      canvas.drawCircle(
        gPos,
        8.0 + (pulseValue * 3.0),
        Paint()
          ..color = const Color(0x4DFFB95F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  /// 7. Draw physical asset node holographic pins with status colors
  void _drawAssetPins(Canvas canvas) {
    for (final asset in assets) {
      final isSelected = selectedAsset?.id == asset.id;
      final Offset pinBase = is3dIsometric
          ? Offset(asset.isoX, asset.isoY)
          : Offset(asset.isoX, asset.isoY);
      final Offset pinHead = is3dIsometric
          ? Offset(asset.isoX, asset.isoY - asset.isoZ)
          : Offset(asset.isoX, asset.isoY);

      final Color statusColor = asset.status.color;

      // 1. Ground Shadow / Drop Marker
      canvas.drawOval(
        Rect.fromCenter(center: pinBase, width: 22, height: 10),
        Paint()..color = const Color(0x70000000),
      );

      // 2. Vertical Laser Stem (Projecting up in 3D space)
      if (is3dIsometric && asset.isoZ > 0) {
        final stemPaint = Paint()
          ..color = statusColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.5;
        canvas.drawLine(pinBase, pinHead, stemPaint);
      }

      // 3. Pulsing Aura for Active / Blocked / Selected assets
      if (isSelected ||
          asset.status == AssetProgressStatus.blocked ||
          asset.status == AssetProgressStatus.inProgress) {
        final double auraRadius = 18.0 + (pulseValue * 8.0);
        final auraPaint = Paint()
          ..color = statusColor.withValues(
            alpha: 0.35 * (1.0 - (pulseValue * 0.4)),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(pinHead, auraRadius, auraPaint);
      }

      // 4. Holographic Diamond Pin Head
      final diamondPath = Path();
      const double radius = 13.0;
      diamondPath.moveTo(pinHead.dx, pinHead.dy - radius);
      diamondPath.lineTo(pinHead.dx + radius, pinHead.dy);
      diamondPath.lineTo(pinHead.dx, pinHead.dy + radius);
      diamondPath.lineTo(pinHead.dx - radius, pinHead.dy);
      diamondPath.close();

      // Pin Background Fill
      canvas.drawPath(diamondPath, Paint()..color = const Color(0xFF111C38));

      // Pin Glow Border
      canvas.drawPath(
        diamondPath,
        Paint()
          ..color = statusColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 3.0 : 2.0,
      );

      // Inner Status Pip
      canvas.drawCircle(pinHead, 4.0, Paint()..color = statusColor);

      // 5. Pin Label Tag (Floating Pill with Asset Tag & Progress)
      _drawPinLabelPill(canvas, pinHead, asset, statusColor, isSelected);

      // 6. Optional Always-On QC Stamp Floating Badge
      if (showQcStamps) {
        _drawPinQcStamp(canvas, pinHead, asset);
      }
    }
  }

  void _drawPinLabelPill(
    Canvas canvas,
    Offset pinHead,
    PhysicalAssetNode asset,
    Color statusColor,
    bool isSelected,
  ) {
    final String labelText = asset.tag;
    final String pctText = '${asset.progressPercent.toStringAsFixed(0)}%';

    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.2,
    );
    const pctStyle = TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 9,
      fontWeight: FontWeight.w600,
    );

    final textSpan = TextSpan(
      text: '$labelText  ',
      style: textStyle,
      children: [
        TextSpan(
          text: pctText,
          style: pctStyle.copyWith(color: statusColor),
        ),
      ],
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final pillWidth = textPainter.width + 16;
    const pillHeight = 20.0;
    final pillRect = Rect.fromCenter(
      center: pinHead - const Offset(0, 26),
      width: pillWidth,
      height: pillHeight,
    );

    // Pill Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(10)),
      Paint()..color = const Color(0xE6111C38),
    );

    // Pill Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(10)),
      Paint()
        ..color = isSelected ? const Color(0xFF38BDF8) : const Color(0xFF26396E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.5 : 1.0,
    );

    // Draw Text inside Pill
    textPainter.paint(
      canvas,
      Offset(
        pillRect.left + 8,
        pillRect.top + (pillHeight - textPainter.height) / 2,
      ),
    );
  }

  void _drawPinQcStamp(Canvas canvas, Offset pinHead, PhysicalAssetNode asset) {
    final stampText = asset.qcStampNumber;
    final textPainter = TextPainter(
      text: TextSpan(
        text: stampText,
        style: const TextStyle(
          color: Color(0xFF38BDF8),
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeRect = Rect.fromCenter(
      center: pinHead + const Offset(0, 24),
      width: textPainter.width + 10,
      height: 16,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
      Paint()..color = const Color(0xF00B1326),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    textPainter.paint(
      canvas,
      Offset(
        badgeRect.left + 5,
        badgeRect.top + (badgeRect.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant DigitalTwinPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.selectedAsset != selectedAsset ||
        oldDelegate.selectedZoneId != selectedZoneId ||
        oldDelegate.assets != assets ||
        oldDelegate.is3dIsometric != is3dIsometric ||
        oldDelegate.showLidarCloud != showLidarCloud ||
        oldDelegate.showPipelineFlow != showPipelineFlow ||
        oldDelegate.showGangMarkers != showGangMarkers ||
        oldDelegate.showQcStamps != showQcStamps;
  }
}
