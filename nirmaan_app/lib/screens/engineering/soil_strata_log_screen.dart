import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Strata classification per IS 1498, IRC, OISD-141 & ASME B31.8 geotechnical specs
enum StrataClassification {
  ordinarySoil(
    label: 'Ordinary Soil',
    shortCode: 'OS',
    description: 'Alluvial loam, tea garden humic topsoil & sandy silt',
    color: Color(0xFF8D6E63), // Earthy soil
    icon: Icons.grass_rounded,
    excavationMethod: 'Direct Excavation (CAT 320D / JCB 3DX)',
    reposeAngle: '1:1 (45°)',
    surchargeSetbackM: 1.0,
    isHardRock: false,
  ),
  softClay(
    label: 'Soft Clay',
    shortCode: 'SC',
    description: 'High plasticity alluvial clay (CH/CL), prone to heaving',
    color: Color(0xFF0284C7), // High moisture river clay
    icon: Icons.water_drop_rounded,
    excavationMethod: 'Ditcher / Bucket with Steel Trench Shield',
    reposeAngle: '1:1.5 (34°)',
    surchargeSetbackM: 1.5,
    isHardRock: false,
  ),
  cohesiveSilt(
    label: 'Cohesive Silt',
    shortCode: 'CS',
    description: 'Brahmaputra alluvial silt with fine cohesion (ML/MH)',
    color: Color(0xFFD97706), // Silt amber/ochre
    icon: Icons.layers_rounded,
    excavationMethod: 'Hydraulic Backhoe + Sump Pit Drainage',
    reposeAngle: '1:1 (45°)',
    surchargeSetbackM: 1.2,
    isHardRock: false,
  ),
  weatheredRock(
    label: 'Weathered Rock',
    shortCode: 'WR',
    description: 'Fractured Disang sandstone & shale, rippable',
    color: Color(0xFF9333EA), // Fractured bedrock
    icon: Icons.terrain_rounded,
    excavationMethod: 'CAT D8R Single Shank Heavy Ripper Tooth',
    reposeAngle: '1:0.5 (63°)',
    surchargeSetbackM: 0.8,
    isHardRock: true,
  ),
  hardRock(
    label: 'Hard Rock (Blasting/Breaker)',
    shortCode: 'HR',
    description: 'Massive Basalt & Quartzite, UCS > 75 MPa',
    color: Color(0xFFEF4444), // Crimson danger rock
    icon: Icons.dangerous_rounded,
    excavationMethod: 'Hydraulic Rock Breaker (PC300) / Micro-Blasting',
    reposeAngle: 'Near Vertical (85°-90°)',
    surchargeSetbackM: 0.5,
    isHardRock: true,
  );

  final String label;
  final String shortCode;
  final String description;
  final Color color;
  final IconData icon;
  final String excavationMethod;
  final String reposeAngle;
  final double surchargeSetbackM;
  final bool isHardRock;

  const StrataClassification({
    required this.label,
    required this.shortCode,
    required this.description,
    required this.color,
    required this.icon,
    required this.excavationMethod,
    required this.reposeAngle,
    required this.surchargeSetbackM,
    required this.isHardRock,
  });
}

/// OISD-141 / ASME B31.8 Pipeline Crown Cover Compliance Status
enum ComplianceStatus {
  compliant(
    label: 'Compliant (≥ 1.50m)',
    color: Color(0xFF4EDEA3),
    icon: Icons.check_circle_rounded,
    actionNeeded: 'OISD-141 & ASME B31.8 cover satisfied.',
  ),
  warning(
    label: 'Warning: Cover < 1.50m',
    color: Color(0xFFFFB95F),
    icon: Icons.warning_amber_rounded,
    actionNeeded: 'Reinforced concrete protection slab or extra mounding required.',
  ),
  nonCompliant(
    label: 'Non-Compliant Deficient',
    color: Color(0xFFFF5252),
    icon: Icons.cancel_rounded,
    actionNeeded: 'Immediate excavation deepening or re-route instruction required.',
  );

  final String label;
  final Color color;
  final IconData icon;
  final String actionNeeded;

  const ComplianceStatus({
    required this.label,
    required this.color,
    required this.icon,
    required this.actionNeeded,
  });
}

/// Shoring & Trench Wall Support Type
enum ShoringMethod {
  steelTrenchBox(
    'Steel Shield Trench Box',
    'Pre-fabricated double-walled steel shield with spreader struts',
    Icons.shield_rounded,
  ),
  hydraulicAluminum(
    'Hydraulic Aluminum Shores',
    'Pressurized hydraulic struts & aluminum rails for rapid installation',
    Icons.compress_rounded,
  ),
  timberLagging(
    'Heavy Timber Lagging',
    'Heavy timber close sheeting with steel H-beam soldiers',
    Icons.view_column_rounded,
  ),
  batteredSloped(
    'Battered 1:1 Sloped Face',
    'Step-benched earthen excavation with 0.6m stability berm',
    Icons.stairs_rounded,
  ),
  noneRockCut(
    'Stable Rock Wall Face',
    'Vertical competent rock face with surface mesh & spot anchoring',
    Icons.terrain_rounded,
  );

  final String label;
  final String description;
  final IconData icon;

  const ShoringMethod(this.label, this.description, this.icon);
}

/// Geotechnical chainage trench log record model
class TrenchLogEntry {
  final String id;
  final double chainageStartKm;
  final double chainageEndKm;
  final String locationSector;
  final String terrainType; // "Assam Tea Estate", "Alluvial Floodplain", "Rock Outcrop"
  final StrataClassification primaryStrata;
  final StrataClassification? secondaryStrata;
  final double ordinarySoilPct;
  final double softClayPct;
  final double cohesiveSiltPct;
  final double weatheredRockPct;
  final double hardRockPct;
  final double trenchDepthM;
  final double pipeCrownCoverM;
  final double pipeOdMm;
  final double beddingThicknessMm;
  final double trenchTopWidthM;
  final double trenchBaseWidthM;
  final double groundWaterLevelM; // meters below Ground Level
  final bool dewateringActive;
  final int dewateringPumpCount;
  final double dewateringDischargeLpm;
  final double dewateringHours24h;
  final ShoringMethod shoringMethod;
  final bool isShoringCertified;
  final String competentPerson;
  final String competentPersonBadge;
  final String signOffTimestamp;
  final bool isBlastingRequired;
  final String? blastingPermitRef;
  final double? seismicPpvMmSec; // Peak Particle Velocity in mm/sec
  final String excavationStatus; // "Verified / Completed", "Active Trenching", "Backfill QA"
  final String notes;

  const TrenchLogEntry({
    required this.id,
    required this.chainageStartKm,
    required this.chainageEndKm,
    required this.locationSector,
    required this.terrainType,
    required this.primaryStrata,
    this.secondaryStrata,
    required this.ordinarySoilPct,
    required this.softClayPct,
    required this.cohesiveSiltPct,
    required this.weatheredRockPct,
    required this.hardRockPct,
    required this.trenchDepthM,
    required this.pipeCrownCoverM,
    this.pipeOdMm = 610.0, // 24" Mainline
    this.beddingThicknessMm = 150.0,
    required this.trenchTopWidthM,
    required this.trenchBaseWidthM,
    required this.groundWaterLevelM,
    required this.dewateringActive,
    required this.dewateringPumpCount,
    required this.dewateringDischargeLpm,
    required this.dewateringHours24h,
    required this.shoringMethod,
    required this.isShoringCertified,
    required this.competentPerson,
    required this.competentPersonBadge,
    required this.signOffTimestamp,
    required this.isBlastingRequired,
    this.blastingPermitRef,
    this.seismicPpvMmSec,
    required this.excavationStatus,
    required this.notes,
  });

  String get chainageSpan =>
      'Ch ${_formatChainage(chainageStartKm)} – ${_formatChainage(chainageEndKm)}';

  double get lengthKm => chainageEndKm - chainageStartKm;

  ComplianceStatus get complianceStatus {
    if (pipeCrownCoverM >= 1.50) {
      return ComplianceStatus.compliant;
    } else if (pipeCrownCoverM >= 1.35) {
      return ComplianceStatus.warning;
    } else {
      return ComplianceStatus.nonCompliant;
    }
  }

  static String _formatChainage(double km) {
    final int wholeKm = km.floor();
    final int meters = ((km - wholeKm) * 1000).round();
    return '$wholeKm+${meters.toString().padLeft(3, '0')}';
  }
}

/// Dewatering Pump Unit Telemetry Record
class DewateringPumpUnit {
  final String pumpTag;
  final String modelName;
  final String chainageLocation;
  final int capacityLpm;
  final int currentDischargeLpm;
  final double operatingHours24h;
  final int fuelLevelPct;
  final double phValue;
  final double turbidityNtu;
  final String siltTrapCondition;
  final String status; // "Running", "Standby", "Maintenance"
  final String operatorName;

  const DewateringPumpUnit({
    required this.pumpTag,
    required this.modelName,
    required this.chainageLocation,
    required this.capacityLpm,
    required this.currentDischargeLpm,
    required this.operatingHours24h,
    required this.fuelLevelPct,
    required this.phValue,
    required this.turbidityNtu,
    required this.siltTrapCondition,
    required this.status,
    required this.operatorName,
  });
}

/// Shoring & Geotechnical Safety Inspection Sign-Off Record
class ShoringSignOffRecord {
  final String inspectionId;
  final String chainageSpan;
  final String inspectorName;
  final String inspectorBadge;
  final String designation;
  final ShoringMethod shoringMethod;
  final double spoilPileSetbackM; // min 1.0m / 1.5m
  final double ladderSpacingM; // max 15.0m
  final double o2LevelPct; // 20.9%
  final double h2sLevelPpm; // 0.0 PPM
  final String trenchStabilityRating; // "Optimal", "Acceptable", "Hazardous"
  final String signOffStatus; // "CERTIFIED SAFE", "CONDITIONAL", "RESTRICTED"
  final String timestamp;
  final String remarks;

  const ShoringSignOffRecord({
    required this.inspectionId,
    required this.chainageSpan,
    required this.inspectorName,
    required this.inspectorBadge,
    required this.designation,
    required this.shoringMethod,
    required this.spoilPileSetbackM,
    required this.ladderSpacingM,
    required this.o2LevelPct,
    required this.h2sLevelPpm,
    required this.trenchStabilityRating,
    required this.signOffStatus,
    required this.timestamp,
    required this.remarks,
  });
}

/// Main Screen: Soil Strata & Pipeline Trenching Geotechnical Log
class SoilStrataLogScreen extends StatefulWidget {
  const SoilStrataLogScreen({super.key});

  @override
  State<SoilStrataLogScreen> createState() => _SoilStrataLogScreenState();
}

class _SoilStrataLogScreenState extends State<SoilStrataLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _searchQuery = '';
  String _selectedStrataFilter = 'ALL'; // ALL or StrataClassification shortCode
  String _selectedComplianceFilter = 'ALL'; // ALL, COMPLIANT, WARNING
  String _selectedSectorFilter = 'ALL'; // ALL, Tea Estate, Floodplain, Rock

  int _selectedChainageIndex = 0;

  // Master trench log entries covering Chainage 0+000 to 24+500 km across Assam
  late List<TrenchLogEntry> _trenchEntries;
  late List<DewateringPumpUnit> _dewateringFleet;
  late List<ShoringSignOffRecord> _shoringSignOffs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    // 9 Realistic engineering chainage sectors spanning Ch 0+000 to 24+500 km
    _trenchEntries = [
      const TrenchLogEntry(
        id: 'TR-CH-000-032',
        chainageStartKm: 0.000,
        chainageEndKm: 3.200,
        locationSector: 'Moran Tea Estate (Nursery Section A to Factory)',
        terrainType: 'Assam Tea Estate',
        primaryStrata: StrataClassification.ordinarySoil,
        secondaryStrata: StrataClassification.softClay,
        ordinarySoilPct: 80.0,
        softClayPct: 20.0,
        cohesiveSiltPct: 0.0,
        weatheredRockPct: 0.0,
        hardRockPct: 0.0,
        trenchDepthM: 2.45,
        pipeCrownCoverM: 1.69,
        trenchTopWidthM: 1.80,
        trenchBaseWidthM: 1.25,
        groundWaterLevelM: 1.40,
        dewateringActive: true,
        dewateringPumpCount: 1,
        dewateringDischargeLpm: 450,
        dewateringHours24h: 14.5,
        shoringMethod: ShoringMethod.batteredSloped,
        isShoringCertified: true,
        competentPerson: 'Er. Pranjal Baruah',
        competentPersonBadge: 'GEO-ASM-104',
        signOffTimestamp: '30 Sep 2026, 06:30 IST',
        isBlastingRequired: false,
        excavationStatus: 'Verified / Completed',
        notes:
            'Alluvial humic topsoil over tea garden loam. High organic cohesion. 150mm river sand bedding compacted to 95% MDD.',
      ),
      const TrenchLogEntry(
        id: 'TR-CH-032-068',
        chainageStartKm: 3.200,
        chainageEndKm: 6.800,
        locationSector: 'Burhi Dihing River Alluvial Floodplain Buffer',
        terrainType: 'Alluvial Floodplain',
        primaryStrata: StrataClassification.softClay,
        secondaryStrata: StrataClassification.cohesiveSilt,
        ordinarySoilPct: 0.0,
        softClayPct: 75.0,
        cohesiveSiltPct: 25.0,
        weatheredRockPct: 0.0,
        hardRockPct: 0.0,
        trenchDepthM: 2.65,
        pipeCrownCoverM: 1.89,
        trenchTopWidthM: 2.10,
        trenchBaseWidthM: 1.35,
        groundWaterLevelM: 0.40, // Extreme high water table
        dewateringActive: true,
        dewateringPumpCount: 3,
        dewateringDischargeLpm: 2850,
        dewateringHours24h: 24.0, // 24-hr round-the-clock
        shoringMethod: ShoringMethod.steelTrenchBox,
        isShoringCertified: true,
        competentPerson: 'Er. Debojit Gogoi',
        competentPersonBadge: 'GEO-ASM-4412',
        signOffTimestamp: '30 Sep 2026, 06:45 IST',
        isBlastingRequired: false,
        excavationStatus: 'Verified / Completed',
        notes:
            'Critical monsoon flood basin. High slumping risk. Dual 3m x 2.4m steel trench boxes deployed. Silt settling basin in use before canal discharge.',
      ),
      const TrenchLogEntry(
        id: 'TR-CH-068-105',
        chainageStartKm: 6.800,
        chainageEndKm: 10.500,
        locationSector: 'Tingrai Alluvial Basin & Feeder Canal Reach',
        terrainType: 'Alluvial Floodplain',
        primaryStrata: StrataClassification.cohesiveSilt,
        secondaryStrata: StrataClassification.softClay,
        ordinarySoilPct: 0.0,
        softClayPct: 35.0,
        cohesiveSiltPct: 65.0,
        weatheredRockPct: 0.0,
        hardRockPct: 0.0,
        trenchDepthM: 2.40,
        pipeCrownCoverM: 1.64,
        trenchTopWidthM: 1.90,
        trenchBaseWidthM: 1.30,
        groundWaterLevelM: 0.85,
        dewateringActive: true,
        dewateringPumpCount: 2,
        dewateringDischargeLpm: 1300,
        dewateringHours24h: 18.0,
        shoringMethod: ShoringMethod.hydraulicAluminum,
        isShoringCertified: true,
        competentPerson: 'Er. Manabendra Nath',
        competentPersonBadge: 'GEO-ASM-219',
        signOffTimestamp: '30 Sep 2026, 07:15 IST',
        isBlastingRequired: false,
        excavationStatus: 'Verified / Completed',
        notes:
            'Fine cohesive Brahmaputra silt. Hydraulic aluminum waler shores set at 1.8m c/c. Dewatering sump pits maintained every 200m.',
      ),
      const TrenchLogEntry(
        id: 'TR-CH-105-121',
        chainageStartKm: 10.500,
        chainageEndKm: 12.100,
        locationSector: 'NH-315 Highway Underpass & Culvert Corridor',
        terrainType: 'Highway Crossing',
        primaryStrata: StrataClassification.softClay,
        secondaryStrata: StrataClassification.cohesiveSilt,
        ordinarySoilPct: 0.0,
        softClayPct: 50.0,
        cohesiveSiltPct: 50.0,
        weatheredRockPct: 0.0,
        hardRockPct: 0.0,
        trenchDepthM: 2.90,
        pipeCrownCoverM: 2.14, // Deep cover for vehicular surcharge
        trenchTopWidthM: 2.30,
        trenchBaseWidthM: 1.40,
        groundWaterLevelM: 1.10,
        dewateringActive: true,
        dewateringPumpCount: 1,
        dewateringDischargeLpm: 600,
        dewateringHours24h: 16.0,
        shoringMethod: ShoringMethod.timberLagging,
        isShoringCertified: true,
        competentPerson: 'Er. Debojit Gogoi',
        competentPersonBadge: 'GEO-ASM-4412',
        signOffTimestamp: '29 Sep 2026, 17:30 IST',
        isBlastingRequired: false,
        excavationStatus: 'Verified / Completed',
        notes:
            'High vehicular traffic surcharge. Heavy timber close-lagging with ISMB 250 soldier beams. Pipe crown cover exceeds 1.8m crossing standard.',
      ),
      const TrenchLogEntry(
        id: 'TR-CH-121-154',
        chainageStartKm: 12.100,
        chainageEndKm: 15.400,
        locationSector: 'Doomdooma Foothills Sector 1 (Intermediate Ridge)',
        terrainType: 'Highland / Foothill',
        primaryStrata: StrataClassification.weatheredRock,
        secondaryStrata: StrataClassification.ordinarySoil,
        ordinarySoilPct: 30.0,
        softClayPct: 0.0,
        cohesiveSiltPct: 0.0,
        weatheredRockPct: 70.0,
        hardRockPct: 0.0,
        trenchDepthM: 2.32,
        pipeCrownCoverM: 1.56,
        trenchTopWidthM: 1.70,
        trenchBaseWidthM: 1.25,
        groundWaterLevelM: 3.50, // Deep dry water table
        dewateringActive: false,
        dewateringPumpCount: 0,
        dewateringDischargeLpm: 0,
        dewateringHours24h: 0.0,
        shoringMethod: ShoringMethod.batteredSloped,
        isShoringCertified: true,
        competentPerson: 'Er. Bikas Saikia',
        competentPersonBadge: 'GEO-ASM-882',
        signOffTimestamp: '29 Sep 2026, 15:00 IST',
        isBlastingRequired: false,
        excavationStatus: 'Verified / Completed',
        notes:
            'Fractured Disang sandstone shelf at 1.1m depth. CAT D8R single shank ripper mobilized. No explosive blasting needed.',
      ),
      const TrenchLogEntry(
        id: 'TR-CH-154-179',
        chainageStartKm: 15.400,
        chainageEndKm: 17.900,
        locationSector: 'Doomdooma Foothills Sector 2 (Hard Rock Escarpment)',
        terrainType: 'Hard Rock Outcrop',
        primaryStrata: StrataClassification.hardRock,
        secondaryStrata: StrataClassification.weatheredRock,
        ordinarySoilPct: 0.0,
        softClayPct: 0.0,
        cohesiveSiltPct: 0.0,
        weatheredRockPct: 15.0,
        hardRockPct: 85.0,
        trenchDepthM: 2.28,
        pipeCrownCoverM: 1.52,
        trenchTopWidthM: 1.60,
        trenchBaseWidthM: 1.20,
        groundWaterLevelM: 4.80,
        dewateringActive: false,
        dewateringPumpCount: 0,
        dewateringDischargeLpm: 0,
        dewateringHours24h: 0.0,
        shoringMethod: ShoringMethod.noneRockCut,
        isShoringCertified: true,
        competentPerson: 'Er. Arindam Phukan',
        competentPersonBadge: 'BLAST-CERT-904',
        signOffTimestamp: '29 Sep 2026, 11:20 IST',
        isBlastingRequired: true,
        blastingPermitRef: 'DGMS/NER/BLAST/2026/088',
        seismicPpvMmSec: 11.2, // Below 25 mm/s limit
        excavationStatus: 'Verified / Completed',
        notes:
            'Massive Disang Sandstone & Quartzite (UCS 84 MPa). Controlled micro-blasting with non-electric shock tube detonators + Komatsu PC300 rock breaker. Seismograph PPV 11.2 mm/s well within DGMS 25 mm/s limit.',
      ),
      const TrenchLogEntry(
        id: 'TR-CH-179-212',
        chainageStartKm: 17.900,
        chainageEndKm: 21.200,
        locationSector: 'Bordubi Tea Estate Valley (Drainage Network)',
        terrainType: 'Assam Tea Estate',
        primaryStrata: StrataClassification.ordinarySoil,
        secondaryStrata: StrataClassification.softClay,
        ordinarySoilPct: 55.0,
        softClayPct: 45.0,
        cohesiveSiltPct: 0.0,
        weatheredRockPct: 0.0,
        hardRockPct: 0.0,
        trenchDepthM: 2.42,
        pipeCrownCoverM: 1.66,
        trenchTopWidthM: 1.85,
        trenchBaseWidthM: 1.30,
        groundWaterLevelM: 1.15,
        dewateringActive: true,
        dewateringPumpCount: 2,
        dewateringDischargeLpm: 1100,
        dewateringHours24h: 16.5,
        shoringMethod: ShoringMethod.hydraulicAluminum,
        isShoringCertified: true,
        competentPerson: 'Er. Pranjal Baruah',
        competentPersonBadge: 'GEO-ASM-104',
        signOffTimestamp: '28 Sep 2026, 16:45 IST',
        isBlastingRequired: false,
        excavationStatus: 'Verified / Completed',
        notes:
            'Deep tea root network with intermittent plantation irrigation ditches. Infiltration sumps constructed to preserve tea estate drainage.',
      ),
      const TrenchLogEntry(
        id: 'TR-CH-212-231',
        chainageStartKm: 21.200,
        chainageEndKm: 23.100,
        locationSector: 'Digboi Ridge Approach (Shallow Bedrock Shelf)',
        terrainType: 'Hard Rock Outcrop',
        primaryStrata: StrataClassification.hardRock,
        secondaryStrata: StrataClassification.weatheredRock,
        ordinarySoilPct: 0.0,
        softClayPct: 0.0,
        cohesiveSiltPct: 0.0,
        weatheredRockPct: 10.0,
        hardRockPct: 90.0,
        trenchDepthM: 2.20,
        pipeCrownCoverM: 1.44, // WARNING: Cover is 1.44m (< 1.50m)
        trenchTopWidthM: 1.55,
        trenchBaseWidthM: 1.20,
        groundWaterLevelM: 5.20,
        dewateringActive: false,
        dewateringPumpCount: 0,
        dewateringDischargeLpm: 0,
        dewateringHours24h: 0.0,
        shoringMethod: ShoringMethod.noneRockCut,
        isShoringCertified: true,
        competentPerson: 'Er. Debojit Gogoi & Marcus Vance',
        competentPersonBadge: 'GEO-ASM-4412',
        signOffTimestamp: '28 Sep 2026, 14:15 IST',
        isBlastingRequired: true,
        blastingPermitRef: 'DGMS/NER/BREAKER/2026/102',
        seismicPpvMmSec: 7.8,
        excavationStatus: 'Action Required: RCC Slab',
        notes:
            'WARNING: Measured crown cover is 1.44m (shallow rock shelf). Per OISD-141 Cl 5.3.2, 100mm M25 Reinforced Concrete Protection Slab + warning tiles approved and cast over pipe crown before backfill.',
      ),
      const TrenchLogEntry(
        id: 'TR-CH-231-245',
        chainageStartKm: 23.100,
        chainageEndKm: 24.500,
        locationSector: 'Oil India Duliajan Pumping Terminal Approach',
        terrainType: 'Industrial Corridor',
        primaryStrata: StrataClassification.cohesiveSilt,
        secondaryStrata: StrataClassification.ordinarySoil,
        ordinarySoilPct: 50.0,
        softClayPct: 0.0,
        cohesiveSiltPct: 50.0,
        weatheredRockPct: 0.0,
        hardRockPct: 0.0,
        trenchDepthM: 2.50,
        pipeCrownCoverM: 1.74,
        trenchTopWidthM: 1.95,
        trenchBaseWidthM: 1.35,
        groundWaterLevelM: 1.30,
        dewateringActive: true,
        dewateringPumpCount: 1,
        dewateringDischargeLpm: 500,
        dewateringHours24h: 12.0,
        shoringMethod: ShoringMethod.steelTrenchBox,
        isShoringCertified: true,
        competentPerson: 'Er. Debojit Gogoi',
        competentPersonBadge: 'GEO-ASM-4412',
        signOffTimestamp: '28 Sep 2026, 10:00 IST',
        isBlastingRequired: false,
        excavationStatus: 'Verified / Completed',
        notes:
            'Terminal manifold interface. Strict OISD-141 & ASME B31.8 compliance certified. Sand padding & CP cable test lead pits installed.',
      ),
    ];

    // Dewatering fleet active in high water table alluvial floodplains
    _dewateringFleet = [
      const DewateringPumpUnit(
        pumpTag: 'PUMP-DW-01',
        modelName: 'Kirloskar SP-4H 15HP Heavy Trash Pump',
        chainageLocation: 'Ch 04+150 (Burhi Dihing Floodplain)',
        capacityLpm: 1200,
        currentDischargeLpm: 1140,
        operatingHours24h: 22.5,
        fuelLevelPct: 82,
        phValue: 7.2,
        turbidityNtu: 14.2,
        siltTrapCondition: 'Cleaned - Coir Filter Mesh Active',
        status: 'Running',
        operatorName: 'Biplab Sarma',
      ),
      const DewateringPumpUnit(
        pumpTag: 'PUMP-DW-02',
        modelName: 'Crompton Greaves 6" Submersible Slurry Pump',
        chainageLocation: 'Ch 05+400 (Dihing South Sump)',
        capacityLpm: 1000,
        currentDischargeLpm: 960,
        operatingHours24h: 23.0,
        fuelLevelPct: 88,
        phValue: 7.0,
        turbidityNtu: 16.8,
        siltTrapCondition: 'Dual Baffle Basin Active',
        status: 'Running',
        operatorName: 'Jiten Das',
      ),
      const DewateringPumpUnit(
        pumpTag: 'PUMP-DW-03',
        modelName: 'Honda GX390 4" Dewatering Sump Pump',
        chainageLocation: 'Ch 06+200 (Dihing Levee Crossing)',
        capacityLpm: 800,
        currentDischargeLpm: 750,
        operatingHours24h: 20.0,
        fuelLevelPct: 64,
        phValue: 7.3,
        turbidityNtu: 12.0,
        siltTrapCondition: 'Geo-textile Fence Intact',
        status: 'Running',
        operatorName: 'Hemanta Kalita',
      ),
      const DewateringPumpUnit(
        pumpTag: 'PUMP-DW-04',
        modelName: 'Kirloskar SP-4H 15HP Heavy Trash Pump',
        chainageLocation: 'Ch 07+850 (Tingrai Canal Inflow)',
        capacityLpm: 1200,
        currentDischargeLpm: 720,
        operatingHours24h: 17.5,
        fuelLevelPct: 70,
        phValue: 7.1,
        turbidityNtu: 15.5,
        siltTrapCondition: 'Desilted at 06:00 AM',
        status: 'Running',
        operatorName: 'Nayan Medhi',
      ),
      const DewateringPumpUnit(
        pumpTag: 'PUMP-DW-05',
        modelName: 'Honda GX390 4" Dewatering Sump Pump',
        chainageLocation: 'Ch 09+200 (Tingrai Sump B)',
        capacityLpm: 800,
        currentDischargeLpm: 580,
        operatingHours24h: 18.5,
        fuelLevelPct: 58,
        phValue: 7.4,
        turbidityNtu: 13.9,
        siltTrapCondition: 'Filter Mesh Certified',
        status: 'Running',
        operatorName: 'Diganta Borah',
      ),
      const DewateringPumpUnit(
        pumpTag: 'PUMP-DW-06',
        modelName: 'Greaves Cotton 10HP High Head Pump',
        chainageLocation: 'Ch 18+600 (Bordubi Tea Estate)',
        capacityLpm: 750,
        currentDischargeLpm: 620,
        operatingHours24h: 15.0,
        fuelLevelPct: 75,
        phValue: 6.9,
        turbidityNtu: 11.4,
        siltTrapCondition: 'Sedimentation Trap Active',
        status: 'Running',
        operatorName: 'Mukesh Tanti',
      ),
      const DewateringPumpUnit(
        pumpTag: 'PUMP-DW-07',
        modelName: 'Kirloskar SP-3H Standby Pump',
        chainageLocation: 'Ch 23+600 (Terminal Approach)',
        capacityLpm: 600,
        currentDischargeLpm: 500,
        operatingHours24h: 12.0,
        fuelLevelPct: 92,
        phValue: 7.2,
        turbidityNtu: 10.1,
        siltTrapCondition: 'Cleaned',
        status: 'Running',
        operatorName: 'Rajen Gohain',
      ),
    ];

    // Shoring safety daily sign-off logs
    _shoringSignOffs = [
      const ShoringSignOffRecord(
        inspectionId: 'SHR-SIGN-2026-091',
        chainageSpan: 'Ch 03+200 to 06+800 (Dihing Floodplain)',
        inspectorName: 'Er. Debojit Gogoi',
        inspectorBadge: 'GEO-ASM-4412',
        designation: 'Senior Geotechnical Engineer',
        shoringMethod: ShoringMethod.steelTrenchBox,
        spoilPileSetbackM: 1.85,
        ladderSpacingM: 12.0,
        o2LevelPct: 20.9,
        h2sLevelPpm: 0.0,
        trenchStabilityRating: 'Optimal',
        signOffStatus: 'CERTIFIED SAFE',
        timestamp: '30 Sep 2026, 06:45 AM',
        remarks:
            'Trench boxes fully seated at base level. Spoil pile set back 1.85m (>1.5m min). Dewatering active. Approved for pipe lowering.',
      ),
      const ShoringSignOffRecord(
        inspectionId: 'SHR-SIGN-2026-092',
        chainageSpan: 'Ch 06+800 to 10+500 (Tingrai Basin)',
        inspectorName: 'Er. Manabendra Nath',
        inspectorBadge: 'GEO-ASM-219',
        designation: 'Lead Geotech Resident Engineer',
        shoringMethod: ShoringMethod.hydraulicAluminum,
        spoilPileSetbackM: 1.60,
        ladderSpacingM: 14.0,
        o2LevelPct: 20.8,
        h2sLevelPpm: 0.0,
        trenchStabilityRating: 'Optimal',
        signOffStatus: 'CERTIFIED SAFE',
        timestamp: '30 Sep 2026, 07:15 AM',
        remarks:
            'Hydraulic pressure maintained at 1,500 PSI. No lateral bulging detected on inclinometer pins. Ladders secure.',
      ),
      const ShoringSignOffRecord(
        inspectionId: 'SHR-SIGN-2026-093',
        chainageSpan: 'Ch 10+500 to 12+100 (NH-315 Underpass)',
        inspectorName: 'Er. Debojit Gogoi',
        inspectorBadge: 'GEO-ASM-4412',
        designation: 'Senior Geotechnical Engineer',
        shoringMethod: ShoringMethod.timberLagging,
        spoilPileSetbackM: 2.10,
        ladderSpacingM: 10.0,
        o2LevelPct: 20.9,
        h2sLevelPpm: 0.0,
        trenchStabilityRating: 'Optimal',
        signOffStatus: 'CERTIFIED SAFE',
        timestamp: '29 Sep 2026, 05:30 PM',
        remarks:
            'ISMB 250 soldier beams driven to 4.5m embedment. Traffic surcharge barrier 2.5m away. Vibration sensors stable.',
      ),
      const ShoringSignOffRecord(
        inspectionId: 'SHR-SIGN-2026-094',
        chainageSpan: 'Ch 15+400 to 17+900 (Doomdooma Rock Outcrop)',
        inspectorName: 'Er. Arindam Phukan',
        inspectorBadge: 'BLAST-CERT-904',
        designation: 'DGMS Certified Blasting Manager',
        shoringMethod: ShoringMethod.noneRockCut,
        spoilPileSetbackM: 1.50,
        ladderSpacingM: 15.0,
        o2LevelPct: 20.9,
        h2sLevelPpm: 0.0,
        trenchStabilityRating: 'Optimal',
        signOffStatus: 'CERTIFIED SAFE',
        timestamp: '29 Sep 2026, 11:20 AM',
        remarks:
            'Post-blast scaling completed. Loose rock fragments cleared from trench edge. Wire mesh secured to vertical face.',
      ),
      const ShoringSignOffRecord(
        inspectionId: 'SHR-SIGN-2026-095',
        chainageSpan: 'Ch 21+200 to 23+100 (Digboi Ridge Escarpment)',
        inspectorName: 'Marcus Vance, P.E.',
        inspectorBadge: 'FIDIC-ENG-09',
        designation: 'Resident Engineer (TPIA)',
        shoringMethod: ShoringMethod.noneRockCut,
        spoilPileSetbackM: 1.40,
        ladderSpacingM: 12.0,
        o2LevelPct: 20.9,
        h2sLevelPpm: 0.0,
        trenchStabilityRating: 'Acceptable',
        signOffStatus: 'CONDITIONAL (RCC Slab Mandated)',
        timestamp: '28 Sep 2026, 02:15 PM',
        remarks:
            'Trench depth limited to 2.20m due to massive bedrock. 100mm RCC slab mandated to compensate for 1.44m crown cover per OISD-141.',
      ),
    ];
  }

  // Filtered entries list
  List<TrenchLogEntry> get _filteredEntries {
    return _trenchEntries.where((entry) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matches = entry.locationSector.toLowerCase().contains(query) ||
            entry.chainageSpan.toLowerCase().contains(query) ||
            entry.terrainType.toLowerCase().contains(query) ||
            entry.primaryStrata.label.toLowerCase().contains(query) ||
            entry.competentPerson.toLowerCase().contains(query);
        if (!matches) return false;
      }

      // Strata filter
      if (_selectedStrataFilter != 'ALL') {
        if (entry.primaryStrata.shortCode != _selectedStrataFilter &&
            entry.secondaryStrata?.shortCode != _selectedStrataFilter) {
          return false;
        }
      }

      // Compliance filter
      if (_selectedComplianceFilter != 'ALL') {
        if (_selectedComplianceFilter == 'COMPLIANT' &&
            entry.complianceStatus != ComplianceStatus.compliant) {
          return false;
        }
        if (_selectedComplianceFilter == 'WARNING' &&
            entry.complianceStatus != ComplianceStatus.warning) {
          return false;
        }
      }

      // Sector filter
      if (_selectedSectorFilter != 'ALL') {
        if (!entry.terrainType.contains(_selectedSectorFilter)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Aggregated Corridor Metrics
  double get _totalChainageKm => 24.500;

  double get _compliantChainageKm {
    double sum = 0;
    for (final e in _trenchEntries) {
      if (e.complianceStatus == ComplianceStatus.compliant) {
        sum += e.lengthKm;
      }
    }
    return sum;
  }

  double get _rockChainageKm {
    double sum = 0;
    for (final e in _trenchEntries) {
      if (e.primaryStrata.isHardRock || (e.secondaryStrata?.isHardRock ?? false)) {
        sum += e.lengthKm;
      }
    }
    return sum;
  }

  int get _totalPumpsActive {
    int sum = 0;
    for (final p in _dewateringFleet) {
      if (p.status == 'Running') sum++;
    }
    return sum;
  }

  int get _totalDewateringLpm {
    int sum = 0;
    for (final p in _dewateringFleet) {
      if (p.status == 'Running') sum += p.currentDischargeLpm;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final TrenchLogEntry selectedEntry =
        _trenchEntries.length > _selectedChainageIndex
            ? _trenchEntries[_selectedChainageIndex]
            : _trenchEntries.first;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soil Strata & Pipeline Trenching',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Ch 0+000 – 24+500 • OISD-141 / ASME B31.8 Geotechnical Log',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryLight, size: 20),
            tooltip: 'OISD-141 & ASME B31.8 Specs',
            onPressed: () => _showOisdStandardReferenceModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.textSecondary, size: 20),
            tooltip: 'Export Geotechnical Dossier',
            onPressed: () => _showExportDossierSnack(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(icon: Icon(Icons.format_list_bulleted_rounded, size: 18), text: 'Chainage Log'),
            Tab(icon: Icon(Icons.architecture_rounded, size: 18), text: 'Profile & CAD'),
            Tab(icon: Icon(Icons.water_rounded, size: 18), text: 'Dewatering Log'),
            Tab(icon: Icon(Icons.verified_user_rounded, size: 18), text: 'Shoring Safety'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChainageLogTab(),
          _buildProfileAndCadTab(selectedEntry),
          _buildDewateringTab(),
          _buildShoringSafetyTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_location_alt_rounded, size: 20),
        label: const Text(
          'Log Chainage',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        onPressed: () => _showLogNewChainageModal(context),
      ),
    );
  }

  // ==========================================
  // TAB 1: CHAINAGE TRENCH LOG
  // ==========================================
  Widget _buildChainageLogTab() {
    final filtered = _filteredEntries;

    return CustomScrollView(
      slivers: [
        // Corridor KPI Strip
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: _buildCorridorSummaryCards(),
          ),
        ),

        // Search & Filter Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Input
                TextField(
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search chainage (e.g. 03+200), tea estate, silt, clay...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 16),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surfaceCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStrataFilterChip('ALL', 'All Strata'),
                      const SizedBox(width: 6),
                      _buildStrataFilterChip(
                        StrataClassification.ordinarySoil.shortCode,
                        'Ordinary Soil',
                        color: StrataClassification.ordinarySoil.color,
                      ),
                      const SizedBox(width: 6),
                      _buildStrataFilterChip(
                        StrataClassification.softClay.shortCode,
                        'Soft Clay',
                        color: StrataClassification.softClay.color,
                      ),
                      const SizedBox(width: 6),
                      _buildStrataFilterChip(
                        StrataClassification.cohesiveSilt.shortCode,
                        'Cohesive Silt',
                        color: StrataClassification.cohesiveSilt.color,
                      ),
                      const SizedBox(width: 6),
                      _buildStrataFilterChip(
                        StrataClassification.weatheredRock.shortCode,
                        'Weathered Rock',
                        color: StrataClassification.weatheredRock.color,
                      ),
                      const SizedBox(width: 6),
                      _buildStrataFilterChip(
                        StrataClassification.hardRock.shortCode,
                        'Hard Rock (Breaker)',
                        color: StrataClassification.hardRock.color,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Compliance Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildComplianceFilterChip('ALL', 'All Compliance'),
                      const SizedBox(width: 6),
                      _buildComplianceFilterChip(
                        'COMPLIANT',
                        'Compliant (≥1.5m Cover)',
                        color: const Color(0xFF4EDEA3),
                      ),
                      const SizedBox(width: 6),
                      _buildComplianceFilterChip(
                        'WARNING',
                        'Warning (<1.5m Cover)',
                        color: const Color(0xFFFFB95F),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 16,
                        width: 1,
                        color: AppTheme.border,
                      ),
                      const SizedBox(width: 12),
                      _buildSectorFilterChip('ALL', 'All Terrains'),
                      const SizedBox(width: 6),
                      _buildSectorFilterChip('Tea Estate', 'Tea Estates'),
                      const SizedBox(width: 6),
                      _buildSectorFilterChip('Floodplain', 'Floodplains'),
                      const SizedBox(width: 6),
                      _buildSectorFilterChip('Rock', 'Rock Escarpments'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // List Header with count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  'CHAINAGE LOG ENTRIES (${filtered.length})',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const Spacer(),
                const Text(
                  'OISD-141 Min Cover: 1.50m',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Trench Entries List
        filtered.isEmpty
            ? const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, color: AppTheme.textMuted, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'No chainage records match your filters',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = filtered[index];
                      final isSelected = _selectedChainageIndex ==
                          _trenchEntries.indexOf(entry);
                      return _buildTrenchEntryCard(entry, isSelected);
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
      ],
    );
  }

  // Corridor Summary KPIs
  Widget _buildCorridorSummaryCards() {
    final double compliancePct = (_compliantChainageKm / _totalChainageKm) * 100;

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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.terrain_rounded, color: AppTheme.primaryLight, size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '24.500 KM TRUNKLINE CORRIDOR',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Assam Tea Estates & Alluvial Floodplain Spread',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4EDEA3).withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF4EDEA3).withAlpha(100)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF4EDEA3)),
                    const SizedBox(width: 4),
                    Text(
                      '${compliancePct.toStringAsFixed(1)}% COMPLIANT',
                      style: const TextStyle(
                        color: Color(0xFF4EDEA3),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4-Column Stat Cards
          Row(
            children: [
              _buildMiniMetric(
                label: 'Logged Spread',
                value: '24.50 km',
                subtext: '9 Sections',
                color: AppTheme.primaryLight,
                icon: Icons.linear_scale_rounded,
              ),
              const SizedBox(width: 8),
              _buildMiniMetric(
                label: 'OISD-141 Cover',
                value: '${_compliantChainageKm.toStringAsFixed(1)} km',
                subtext: '≥ 1.5m cover',
                color: const Color(0xFF4EDEA3),
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              _buildMiniMetric(
                label: 'Hard Rock Bed',
                value: '${_rockChainageKm.toStringAsFixed(1)} km',
                subtext: 'Breaker / Blast',
                color: const Color(0xFFEF4444),
                icon: Icons.warning_rounded,
              ),
              const SizedBox(width: 8),
              _buildMiniMetric(
                label: 'Active Pumps',
                value: '$_totalPumpsActive Units',
                subtext: '$_totalDewateringLpm LPM',
                color: const Color(0xFF38BDF8),
                icon: Icons.water_drop_rounded,
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
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withAlpha(120),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border.withAlpha(100)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtext,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Trench Entry Card
  Widget _buildTrenchEntryCard(TrenchLogEntry entry, bool isSelected) {
    final status = entry.complianceStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.surfaceContainerHigh : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryLight
              : (entry.complianceStatus == ComplianceStatus.warning
                  ? const Color(0xFFFFB95F).withAlpha(120)
                  : AppTheme.border),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedChainageIndex = _trenchEntries.indexOf(entry);
            });
            _showChainageDetailBottomSheet(context, entry);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Chainage badge + Compliance Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: entry.primaryStrata.color.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: entry.primaryStrata.color.withAlpha(100)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(entry.primaryStrata.icon, size: 14, color: entry.primaryStrata.color),
                          const SizedBox(width: 5),
                          Text(
                            entry.chainageSpan,
                            style: TextStyle(
                              color: entry.primaryStrata.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        '${entry.lengthKm.toStringAsFixed(1)} KM',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: status.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: status.color.withAlpha(100)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon, size: 12, color: status.color),
                          const SizedBox(width: 4),
                          Text(
                            status == ComplianceStatus.compliant
                                ? 'OISD-141 COMPLIANT'
                                : 'COVER WARNING',
                            style: TextStyle(
                              color: status.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sector Location
                Text(
                  entry.locationSector,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.place_rounded, size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      entry.terrainType,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppTheme.textMuted, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Text(
                      'Primary: ${entry.primaryStrata.label}',
                      style: TextStyle(
                        color: entry.primaryStrata.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Strata Breakdown Bar
                _buildStrataDistributionBar(entry),
                const SizedBox(height: 12),

                // Engineering Cross-Section Metrics Grid (Cover, Depth, Width, GWL)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withAlpha(160),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border.withAlpha(120)),
                  ),
                  child: Row(
                    children: [
                      // Pipe Crown Cover
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Crown Cover',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '${entry.pipeCrownCoverM.toStringAsFixed(2)}m',
                                  style: TextStyle(
                                    color: status.color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '(≥1.5m)',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 9.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: AppTheme.border),
                      const SizedBox(width: 10),

                      // Trench Depth
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trench Depth',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${entry.trenchDepthM.toStringAsFixed(2)}m',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: AppTheme.border),
                      const SizedBox(width: 10),

                      // Trench Width (Top / Base)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Top / Base W',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${entry.trenchTopWidthM.toStringAsFixed(1)}m / ${entry.trenchBaseWidthM.toStringAsFixed(1)}m',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: AppTheme.border),
                      const SizedBox(width: 10),

                      // Dewatering Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dewatering',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  entry.dewateringActive
                                      ? Icons.water_drop_rounded
                                      : Icons.dry_cleaning_rounded,
                                  size: 13,
                                  color: entry.dewateringActive
                                      ? const Color(0xFF38BDF8)
                                      : AppTheme.textMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  entry.dewateringActive
                                      ? '${entry.dewateringPumpCount} Pumps'
                                      : 'Dry Base',
                                  style: TextStyle(
                                    color: entry.dewateringActive
                                        ? const Color(0xFF38BDF8)
                                        : AppTheme.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
                const SizedBox(height: 10),

                // Footer Row: Shoring Method + Sign-Off Stamp
                Row(
                  children: [
                    Icon(entry.shoringMethod.icon, size: 14, color: AppTheme.primaryLight),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        entry.shoringMethod.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 13, color: Color(0xFF4EDEA3)),
                        const SizedBox(width: 4),
                        Text(
                          entry.competentPerson,
                          style: const TextStyle(
                            color: Color(0xFF4EDEA3),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Visual Strata Composition Percentage Bar
  Widget _buildStrataDistributionBar(TrenchLogEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Strata Log Profile:',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
            ),
            Text(
              _buildStrataSummaryText(entry),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 7,
            child: Row(
              children: [
                if (entry.ordinarySoilPct > 0)
                  Expanded(
                    flex: entry.ordinarySoilPct.round(),
                    child: Container(color: StrataClassification.ordinarySoil.color),
                  ),
                if (entry.softClayPct > 0)
                  Expanded(
                    flex: entry.softClayPct.round(),
                    child: Container(color: StrataClassification.softClay.color),
                  ),
                if (entry.cohesiveSiltPct > 0)
                  Expanded(
                    flex: entry.cohesiveSiltPct.round(),
                    child: Container(color: StrataClassification.cohesiveSilt.color),
                  ),
                if (entry.weatheredRockPct > 0)
                  Expanded(
                    flex: entry.weatheredRockPct.round(),
                    child: Container(color: StrataClassification.weatheredRock.color),
                  ),
                if (entry.hardRockPct > 0)
                  Expanded(
                    flex: entry.hardRockPct.round(),
                    child: Container(color: StrataClassification.hardRock.color),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _buildStrataSummaryText(TrenchLogEntry entry) {
    final parts = <String>[];
    if (entry.ordinarySoilPct > 0) parts.add('Soil ${entry.ordinarySoilPct.toInt()}%');
    if (entry.softClayPct > 0) parts.add('Clay ${entry.softClayPct.toInt()}%');
    if (entry.cohesiveSiltPct > 0) parts.add('Silt ${entry.cohesiveSiltPct.toInt()}%');
    if (entry.weatheredRockPct > 0) parts.add('W.Rock ${entry.weatheredRockPct.toInt()}%');
    if (entry.hardRockPct > 0) parts.add('Hard Rock ${entry.hardRockPct.toInt()}%');
    return parts.join(' • ');
  }

  Widget _buildStrataFilterChip(String shortCode, String label, {Color? color}) {
    final isSelected = _selectedStrataFilter == shortCode;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedStrataFilter = shortCode);
      },
      backgroundColor: AppTheme.surfaceCard,
      selectedColor: (color ?? AppTheme.primary).withAlpha(50),
      labelStyle: TextStyle(
        color: isSelected ? (color ?? AppTheme.primaryLight) : AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? (color ?? AppTheme.primaryLight) : AppTheme.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildComplianceFilterChip(String key, String label, {Color? color}) {
    final isSelected = _selectedComplianceFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedComplianceFilter = key);
      },
      backgroundColor: AppTheme.surfaceCard,
      selectedColor: (color ?? AppTheme.primary).withAlpha(50),
      labelStyle: TextStyle(
        color: isSelected ? (color ?? AppTheme.primaryLight) : AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? (color ?? AppTheme.primaryLight) : AppTheme.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildSectorFilterChip(String sector, String label) {
    final isSelected = _selectedSectorFilter == sector;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedSectorFilter = sector);
      },
      backgroundColor: AppTheme.surfaceCard,
      selectedColor: AppTheme.primary.withAlpha(50),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryLight : AppTheme.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  // ==========================================
  // TAB 2: GEOTECHNICAL PROFILE & CAD CROSS-SECTION
  // ==========================================
  Widget _buildProfileAndCadTab(TrenchLogEntry selectedEntry) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Selection Dropdown Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppTheme.primaryLight, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Chainage Sector for CAD Inspection:',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${selectedEntry.chainageSpan} (${selectedEntry.locationSector})',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.arrow_drop_down_circle_rounded, color: AppTheme.primaryLight),
                  color: AppTheme.surfaceCard,
                  onSelected: (index) {
                    setState(() => _selectedChainageIndex = index);
                  },
                  itemBuilder: (context) {
                    return List.generate(_trenchEntries.length, (index) {
                      final item = _trenchEntries[index];
                      return PopupMenuItem<int>(
                        value: index,
                        child: Text(
                          '${item.chainageSpan} • ${item.primaryStrata.shortCode}',
                          style: TextStyle(
                            color: index == _selectedChainageIndex
                                ? AppTheme.primaryLight
                                : AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: index == _selectedChainageIndex
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. Longitudinal Geotechnical Strata Profile Visualizer
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
                  children: [
                    const Icon(Icons.timeline_rounded, color: AppTheme.primaryLight, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'LONGITUDINAL STRATA ELEVATION PROFILE',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Text(
                        '0+000 to 24+500 KM',
                        style: TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Continuous geological layering across Assam Tea Estates, alluvial floodplains, and Digboi ridge bedrock.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 14),

                // Custom Painter: Longitudinal Profile
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1730),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: _LongitudinalStrataProfilePainter(
                        entries: _trenchEntries,
                        selectedIndex: _selectedChainageIndex,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Profile Legends
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildProfileLegendDot(
                      StrataClassification.ordinarySoil.label,
                      StrataClassification.ordinarySoil.color,
                    ),
                    _buildProfileLegendDot(
                      StrataClassification.softClay.label,
                      StrataClassification.softClay.color,
                    ),
                    _buildProfileLegendDot(
                      StrataClassification.cohesiveSilt.label,
                      StrataClassification.cohesiveSilt.color,
                    ),
                    _buildProfileLegendDot(
                      StrataClassification.weatheredRock.label,
                      StrataClassification.weatheredRock.color,
                    ),
                    _buildProfileLegendDot(
                      StrataClassification.hardRock.label,
                      StrataClassification.hardRock.color,
                    ),
                    _buildProfileLegendLine('Ground Level', const Color(0xFF64748B)),
                    _buildProfileLegendLine('Pipeline Axis', const Color(0xFFFFB95F)),
                    _buildProfileLegendLine('Water Table', const Color(0xFF38BDF8), isDashed: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Interactive CAD Trench Cross-Section Diagram
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
                  children: [
                    const Icon(Icons.architecture_rounded, color: AppTheme.tertiary, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'TRENCH CROSS-SECTION & OISD-141 COMPLIANCE',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: selectedEntry.complianceStatus.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: selectedEntry.complianceStatus.color.withAlpha(120)),
                      ),
                      child: Text(
                        selectedEntry.complianceStatus.label,
                        style: TextStyle(
                          color: selectedEntry.complianceStatus.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Cross-section at ${selectedEntry.chainageSpan}: Pipe OD 610mm (24"), Sand Bedding 150mm.',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 14),

                // Custom Painter: CAD Trench Cross-Section
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1730),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: _CadTrenchCrossSectionPainter(entry: selectedEntry),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Cross-Section Dimensions Breakdown Table
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      _buildDimensionRow(
                        label: 'Measured Crown Cover above Pipe',
                        value: '${selectedEntry.pipeCrownCoverM.toStringAsFixed(2)} m',
                        target: '≥ 1.50 m (OISD-141 Cl 5.3)',
                        isPass: selectedEntry.pipeCrownCoverM >= 1.50,
                      ),
                      const Divider(color: AppTheme.border, height: 16),
                      _buildDimensionRow(
                        label: 'Total Excavation Trench Depth',
                        value: '${selectedEntry.trenchDepthM.toStringAsFixed(2)} m',
                        target: 'OD (0.61m) + Bed (0.15m) + Cover',
                        isPass: true,
                      ),
                      const Divider(color: AppTheme.border, height: 16),
                      _buildDimensionRow(
                        label: 'Trench Top Width / Base Width',
                        value: '${selectedEntry.trenchTopWidthM.toStringAsFixed(2)}m / ${selectedEntry.trenchBaseWidthM.toStringAsFixed(2)}m',
                        target: 'Base ≥ 1.20m (OD + 0.60m)',
                        isPass: selectedEntry.trenchBaseWidthM >= 1.20,
                      ),
                      const Divider(color: AppTheme.border, height: 16),
                      _buildDimensionRow(
                        label: 'Cushion Bedding Layer (River Sand)',
                        value: '${selectedEntry.beddingThicknessMm.toInt()} mm',
                        target: 'Min 100mm - 150mm',
                        isPass: selectedEntry.beddingThicknessMm >= 100,
                      ),
                      const Divider(color: AppTheme.border, height: 16),
                      _buildDimensionRow(
                        label: 'Groundwater Table Elevation',
                        value: '${selectedEntry.groundWaterLevelM.toStringAsFixed(2)} m below GL',
                        target: selectedEntry.dewateringActive ? 'Dewatering Active' : 'Dry Trench Base',
                        isPass: true,
                        accentColor: selectedEntry.dewateringActive ? const Color(0xFF38BDF8) : AppTheme.textSecondary,
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

  Widget _buildProfileLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildProfileLegendLine(String label, Color color, {bool isDashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildDimensionRow({
    required String label,
    required String value,
    required String target,
    required bool isPass,
    Color? accentColor,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 1),
              Text(
                target,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: accentColor ?? (isPass ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F)),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isPass ? Icons.check_circle_rounded : Icons.warning_rounded,
                size: 14,
                color: accentColor ?? (isPass ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: DEWATERING PUMP LOG
  // ==========================================
  Widget _buildDewateringTab() {
    final activePumps = _dewateringFleet.where((p) => p.status == 'Running').toList();

    return CustomScrollView(
      slivers: [
        // Dewatering Overview Banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.water_rounded, color: Color(0xFF38BDF8), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ALLUVIAL FLOODPLAIN DEWATERING TELEMETRY',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Burhi Dihing flood basin, Tingrai canal & Bordubi tea estate sumps',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Dewatering Metrics
                  Row(
                    children: [
                      _buildDewateringMetric(
                        label: 'Active Pumps',
                        value: '${activePumps.length} / ${_dewateringFleet.length}',
                        subtext: 'Operational',
                        color: const Color(0xFF38BDF8),
                      ),
                      const SizedBox(width: 8),
                      _buildDewateringMetric(
                        label: 'Fleet Discharge',
                        value: '$_totalDewateringLpm LPM',
                        subtext: '${(_totalDewateringLpm * 60 / 1000).toStringAsFixed(0)} m³/hr',
                        color: const Color(0xFF4EDEA3),
                      ),
                      const SizedBox(width: 8),
                      _buildDewateringMetric(
                        label: 'Silt Turbidity',
                        value: '14.2 NTU',
                        subtext: 'SPCB Norm < 25',
                        color: const Color(0xFFFFB95F),
                      ),
                      const SizedBox(width: 8),
                      _buildDewateringMetric(
                        label: 'Average pH',
                        value: '7.18 pH',
                        subtext: 'Neutral 6.5–8.5',
                        color: AppTheme.primaryLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Dewatering Pump Cards Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  'DEWATERING PUMP UNITS (${_dewateringFleet.length})',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Discharge into Silt Settling Traps',
                  style: TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

        // Dewatering Pump Cards
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final pump = _dewateringFleet[index];
                return _buildPumpUnitCard(pump);
              },
              childCount: _dewateringFleet.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDewateringMetric({
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withAlpha(100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border.withAlpha(120)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 1),
            Text(
              subtext,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPumpUnitCard(DewateringPumpUnit pump) {
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pump.pumpTag,
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pump.modelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4EDEA3).withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF4EDEA3).withAlpha(100)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4EDEA3), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(
                      pump.status.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF4EDEA3),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.place_rounded, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                pump.chainageLocation,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Telemetry Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withAlpha(100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Discharge Rate', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                      const SizedBox(height: 2),
                      Text(
                        '${pump.currentDischargeLpm} LPM',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('24h Runtime', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                      const SizedBox(height: 2),
                      Text(
                        '${pump.operatingHours24h} hrs',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fuel Level', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                      const SizedBox(height: 2),
                      Text(
                        '${pump.fuelLevelPct}%',
                        style: const TextStyle(color: Color(0xFFFFB95F), fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Discharge QA', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                      const SizedBox(height: 2),
                      Text(
                        '${pump.turbidityNtu} NTU / ${pump.phValue} pH',
                        style: const TextStyle(color: Color(0xFF4EDEA3), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Silt Trap & Operator Footer
          Row(
            children: [
              const Icon(Icons.filter_alt_rounded, size: 13, color: AppTheme.primaryLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Silt Filter: ${pump.siltTrapCondition}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Op: ${pump.operatorName}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: SHORING & SAFETY SIGN-OFF
  // ==========================================
  Widget _buildShoringSafetyTab() {
    return CustomScrollView(
      slivers: [
        // Shoring Safety Standards Banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4EDEA3).withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.security_rounded, color: Color(0xFF4EDEA3), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GEOTECHNICAL SHORING & TRENCH SAFETY',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'OISD-141 & OSHA 1926 Subpart P daily competent person sign-off',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Safety Rule Check Items
                  _buildSafetyRuleRow(
                    icon: Icons.compress_rounded,
                    title: 'Trench Depth > 1.50m Mandatory Protection',
                    subtitle: 'Steel shield box, hydraulic struts, or 1:1 repose slope required before entry.',
                  ),
                  const SizedBox(height: 8),
                  _buildSafetyRuleRow(
                    icon: Icons.warning_amber_rounded,
                    title: 'Spoil Pile Setback ≥ 1.0m to 1.5m Minimum',
                    subtitle: 'Excavated soil surcharge must be kept at least 1.5m back from trench crest.',
                  ),
                  const SizedBox(height: 8),
                  _buildSafetyRuleRow(
                    icon: Icons.stairs_rounded,
                    title: 'Safe Egress Ladders ≤ 15m Travel Distance',
                    subtitle: 'Secured aluminum/timber ladders extending 1m above trench surface.',
                  ),
                  const SizedBox(height: 8),
                  _buildSafetyRuleRow(
                    icon: Icons.air_rounded,
                    title: 'Atmospheric Gas Testing (O2 & H2S)',
                    subtitle: 'Continuous gas monitoring prior to man entry in deep clay and river flood sumps.',
                  ),
                ],
              ),
            ),
          ),
        ),

        // Sign-Off Log Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  'COMPETENT PERSON INSPECTION RECORDS (${_shoringSignOffs.length})',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const Spacer(),
                const Text(
                  '100% Certified Safe',
                  style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),

        // Shoring Sign-Off List
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final signOff = _shoringSignOffs[index];
                return _buildShoringRecordCard(signOff);
              },
              childCount: _shoringSignOffs.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyRuleRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF4EDEA3)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShoringRecordCard(ShoringSignOffRecord signOff) {
    final isCertified = signOff.signOffStatus.contains('CERTIFIED');

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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  signOff.inspectionId,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  signOff.chainageSpan,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCertified ? const Color(0xFF4EDEA3).withAlpha(30) : const Color(0xFFFFB95F).withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isCertified ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCertified ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                      size: 12,
                      color: isCertified ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      signOff.signOffStatus,
                      style: TextStyle(
                        color: isCertified ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Inspection Parameters Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withAlpha(100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Shoring Method', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                      const SizedBox(height: 2),
                      Text(
                        signOff.shoringMethod.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Spoil Setback', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                      const SizedBox(height: 2),
                      Text(
                        '${signOff.spoilPileSetbackM.toStringAsFixed(2)}m (≥1.5m)',
                        style: const TextStyle(color: Color(0xFF4EDEA3), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ladder Spacing', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                      const SizedBox(height: 2),
                      Text(
                        '${signOff.ladderSpacingM.toStringAsFixed(0)}m (≤15m)',
                        style: const TextStyle(color: Color(0xFF4EDEA3), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('O2 / H2S Air QA', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                      const SizedBox(height: 2),
                      Text(
                        '${signOff.o2LevelPct}% / ${signOff.h2sLevelPpm} PPM',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Remarks
          Text(
            signOff.remarks,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),

          // Inspector Seal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh.withAlpha(120),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_rounded, size: 14, color: Color(0xFF4EDEA3)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${signOff.inspectorName} (${signOff.inspectorBadge}) • ${signOff.designation}',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  signOff.timestamp,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODALS & BOTTOM SHEETS
  // ==========================================

  // Bottom Sheet for Chainage Details
  void _showChainageDetailBottomSheet(BuildContext context, TrenchLogEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
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

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: entry.primaryStrata.color.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(entry.primaryStrata.icon, color: entry.primaryStrata.color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.chainageSpan,
                              style: TextStyle(
                                color: entry.primaryStrata.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              entry.locationSector,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: entry.complianceStatus.color.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: entry.complianceStatus.color),
                        ),
                        child: Text(
                          entry.complianceStatus.label,
                          style: TextStyle(
                            color: entry.complianceStatus.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mini CAD Preview
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1730),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomPaint(
                        painter: _CadTrenchCrossSectionPainter(entry: entry),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Geotechnical Classification Specs
                  _buildDetailSectionTitle('Geotechnical Strata Classification'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailTextRow('Primary Classification', entry.primaryStrata.label),
                        _buildDetailTextRow('Standard IS/IRC Code', entry.primaryStrata.shortCode),
                        _buildDetailTextRow('Excavation Equipment', entry.primaryStrata.excavationMethod),
                        _buildDetailTextRow('Permissible Safe Slope', entry.primaryStrata.reposeAngle),
                        _buildDetailTextRow('Mandatory Spoil Setback', '${entry.primaryStrata.surchargeSetbackM} m'),
                        _buildDetailTextRow('Geological Description', entry.primaryStrata.description),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // OISD-141 / ASME B31.8 Compliance Checklist
                  _buildDetailSectionTitle('OISD-141 & ASME B31.8 Cover Compliance'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailTextRow('Measured Pipe Crown Cover', '${entry.pipeCrownCoverM.toStringAsFixed(2)} m'),
                        _buildDetailTextRow('Mandatory OISD-141 Cover', '≥ 1.50 m in Agricultural/Tea Land'),
                        _buildDetailTextRow('Trench Depth from Surface', '${entry.trenchDepthM.toStringAsFixed(2)} m'),
                        _buildDetailTextRow('Pipeline Outer Diameter (OD)', '${entry.pipeOdMm.toInt()} mm (24" API 5L X70)'),
                        _buildDetailTextRow('Compacted Sand Bedding', '${entry.beddingThicknessMm.toInt()} mm clean river sand'),
                        _buildDetailTextRow('Compliance Evaluation', entry.complianceStatus.actionNeeded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dewatering & Groundwater Log
                  _buildDetailSectionTitle('Dewatering & Groundwater Telemetry'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailTextRow('Groundwater Level (GWL)', '${entry.groundWaterLevelM.toStringAsFixed(2)} m below Ground Level'),
                        _buildDetailTextRow('Dewatering Active', entry.dewateringActive ? 'Yes (${entry.dewateringPumpCount} Pumps Running)' : 'No (Dry Trench)'),
                        _buildDetailTextRow('Discharge Flow Rate', '${entry.dewateringDischargeLpm.toInt()} LPM'),
                        _buildDetailTextRow('24h Running Hours', '${entry.dewateringHours24h} hrs/day'),
                        _buildDetailTextRow('Settling Basin Filter', 'Geo-textile Silt Trap Installed'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Blasting Log (if hard rock)
                  if (entry.isBlastingRequired) ...[
                    _buildDetailSectionTitle('Controlled Blasting & Seismograph Log'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444).withAlpha(100)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailTextRow('DGMS Blasting Permit', entry.blastingPermitRef ?? 'N/A'),
                          _buildDetailTextRow('Seismograph PPV Peak', '${entry.seismicPpvMmSec?.toStringAsFixed(1) ?? "0"} mm/s (Limit < 25 mm/s)'),
                          _buildDetailTextRow('Vibration Compliance', 'PASS - Safe for adjacent tea estate factories'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Geotechnical Engineer Sign-Off
                  _buildDetailSectionTitle('Competent Person Geotechnical Sign-Off'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4EDEA3).withAlpha(100)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailTextRow('Certifying Engineer', entry.competentPerson),
                        _buildDetailTextRow('Accreditation Badge ID', entry.competentPersonBadge),
                        _buildDetailTextRow('Digital Sign-Off Time', entry.signOffTimestamp),
                        _buildDetailTextRow('Shoring Method Certified', entry.shoringMethod.label),
                        _buildDetailTextRow('Field Engineering Notes', entry.notes),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Close Geotechnical Sheet'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primaryLight,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildDetailTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // OISD-141 Reference Sheet
  void _showOisdStandardReferenceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: AppTheme.primaryLight, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'OISD-141 & ASME B31.8 Standards',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Statutory pipeline depth of cover regulations for cross-country hydrocarbon transmission lines:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 16),
              _buildStandardRow('Normal / Cultivated Agricultural / Tea Garden Soil', '1.50 m Clean Cover above pipe crown'),
              _buildStandardRow('Rocky Terrain (Without Blasting / Shallow Bedrock)', '1.20 m + 100mm Sand Padding + RCC Slab'),
              _buildStandardRow('Drainage Canals, Ditches & Irrigation Streams', '1.50 m Cover below bed scour level'),
              _buildStandardRow('National & State Highway Crossings (Open / HDD)', '1.80 m Cover (or 1.2m under concrete casing)'),
              _buildStandardRow('Railway Track Crossings', '2.10 m Cover below rail base with casing'),
              _buildStandardRow('Burhi Dihing Major River Crossing', '2.50 m below 100-year historical scour depth'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Understood'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStandardRow(String category, String requirement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(requirement, style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Log New Chainage Dialog
  void _showLogNewChainageModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    double chStart = 24.500;
    double chEnd = 26.000;
    String sectorName = 'Duliajan Terminal Outer Perimeter';
    StrataClassification strata = StrataClassification.ordinarySoil;
    double depth = 2.45;
    double cover = 1.69;
    double topW = 1.85;
    double baseW = 1.25;
    bool dewatering = false;
    ShoringMethod shoring = ShoringMethod.batteredSloped;
    const String engineer = 'Er. Debojit Gogoi';
    const String badge = 'GEO-ASM-4412';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isCompliant = cover >= 1.50;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
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
                          Icon(Icons.add_location_alt_rounded, color: AppTheme.primaryLight, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Log New Trench Chainage Inspection',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Record field geotechnical strata, trench dimensions & verify OISD-141 cover.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 14),

                      // Chainage Span Inputs
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '24.500',
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Start Chainage (km)', isDense: true),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) => chStart = double.tryParse(v) ?? chStart,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: '26.000',
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'End Chainage (km)', isDense: true),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) => chEnd = double.tryParse(v) ?? chEnd,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Location / Sector
                      TextFormField(
                        initialValue: sectorName,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(labelText: 'Location / Sector Name', isDense: true),
                        onChanged: (v) => sectorName = v,
                      ),
                      const SizedBox(height: 10),

                      // Strata Classification Dropdown
                      DropdownButtonFormField<StrataClassification>(
                        initialValue: strata,
                        decoration: const InputDecoration(labelText: 'Primary Strata Classification', isDense: true),
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        items: StrataClassification.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Icon(s.icon, color: s.color, size: 16),
                                const SizedBox(width: 8),
                                Text(s.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => strata = val);
                        },
                      ),
                      const SizedBox(height: 10),

                      // Trench Depth & Crown Cover
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '2.45',
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Trench Depth (m)', isDense: true),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) {
                                final d = double.tryParse(v);
                                if (d != null) {
                                  depth = d;
                                  // Auto calculate cover: depth - 0.61 - 0.15
                                  setModalState(() {
                                    cover = math.max(0.5, depth - 0.76);
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: cover.toStringAsFixed(2),
                              style: TextStyle(
                                color: isCompliant ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Crown Cover (m)',
                                isDense: true,
                                helperText: isCompliant ? '≥ 1.50m Compliant' : 'Warning: < 1.50m',
                                helperStyle: TextStyle(
                                  color: isCompliant ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F),
                                  fontSize: 10,
                                ),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) {
                                final c = double.tryParse(v);
                                if (c != null) setModalState(() => cover = c);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Top & Base Width
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '1.85',
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Trench Top Width (m)', isDense: true),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) => topW = double.tryParse(v) ?? topW,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: '1.25',
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Trench Base Width (m)', isDense: true),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) => baseW = double.tryParse(v) ?? baseW,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Shoring Method Dropdown
                      DropdownButtonFormField<ShoringMethod>(
                        initialValue: shoring,
                        decoration: const InputDecoration(labelText: 'Shoring & Trench Wall Safety', isDense: true),
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        items: ShoringMethod.values.map((sh) {
                          return DropdownMenuItem(
                            value: sh,
                            child: Row(
                              children: [
                                Icon(sh.icon, color: AppTheme.primaryLight, size: 16),
                                const SizedBox(width: 8),
                                Text(sh.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => shoring = val);
                        },
                      ),
                      const SizedBox(height: 10),

                      // Dewatering Switch
                      SwitchListTile(
                        title: const Text('Dewatering Pump Active in Reach', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                        subtitle: const Text('Sump pumps running due to high alluvial water table', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        value: dewatering,
                        activeThumbColor: const Color(0xFF38BDF8),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setModalState(() => dewatering = v),
                      ),
                      const SizedBox(height: 14),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('Log & Sign-Off Geotechnical Inspection'),
                          onPressed: () {
                            final newEntry = TrenchLogEntry(
                              id: 'TR-CH-${chStart.toInt().toString().padLeft(3, '0')}-${chEnd.toInt().toString().padLeft(3, '0')}',
                              chainageStartKm: chStart,
                              chainageEndKm: chEnd,
                              locationSector: sectorName,
                              terrainType: 'Assam Trunkline Extension',
                              primaryStrata: strata,
                              ordinarySoilPct: strata == StrataClassification.ordinarySoil ? 100 : 0,
                              softClayPct: strata == StrataClassification.softClay ? 100 : 0,
                              cohesiveSiltPct: strata == StrataClassification.cohesiveSilt ? 100 : 0,
                              weatheredRockPct: strata == StrataClassification.weatheredRock ? 100 : 0,
                              hardRockPct: strata == StrataClassification.hardRock ? 100 : 0,
                              trenchDepthM: depth,
                              pipeCrownCoverM: cover,
                              trenchTopWidthM: topW,
                              trenchBaseWidthM: baseW,
                              groundWaterLevelM: dewatering ? 0.8 : 2.5,
                              dewateringActive: dewatering,
                              dewateringPumpCount: dewatering ? 1 : 0,
                              dewateringDischargeLpm: dewatering ? 600 : 0,
                              dewateringHours24h: dewatering ? 12.0 : 0.0,
                              shoringMethod: shoring,
                              isShoringCertified: true,
                              competentPerson: engineer,
                              competentPersonBadge: badge,
                              signOffTimestamp: 'Just now (Field Verified)',
                              isBlastingRequired: strata == StrataClassification.hardRock,
                              excavationStatus: 'Verified / Completed',
                              notes: 'New chainage verified by Geotechnical Field Inspector.',
                            );

                            setState(() {
                              _trenchEntries.add(newEntry);
                              _selectedChainageIndex = _trenchEntries.length - 1;
                            });

                            Navigator.pop(ctx);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Logged ${newEntry.chainageSpan} successfully. OISD-141: ${newEntry.complianceStatus.label}'),
                                backgroundColor: newEntry.complianceStatus.color,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showExportDossierSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Geotechnical Dossier Ch 0+000 - 24+500 compiled for Client & TPIA sign-off.'),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ==========================================
// CUSTOM PAINTER: LONGITUDINAL STRATA PROFILE
// ==========================================
class _LongitudinalStrataProfilePainter extends CustomPainter {
  final List<TrenchLogEntry> entries;
  final int selectedIndex;

  _LongitudinalStrataProfilePainter({
    required this.entries,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Background Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2E5C).withAlpha(60)
      ..strokeWidth = 0.8;

    for (double y = 20; y < h; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
    for (double x = 40; x < w; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    if (entries.isEmpty) return;

    final double totalKm = entries.last.chainageEndKm;
    double currentX = 0;

    // Strata Segments
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final double segWidth = (entry.lengthKm / totalKm) * w;
      final Rect segRect = Rect.fromLTWH(currentX, 25, segWidth, h - 45);

      // Gradient Fill based on Primary Strata
      final strataPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            entry.primaryStrata.color.withAlpha(200),
            (entry.secondaryStrata?.color ?? entry.primaryStrata.color).withAlpha(120),
            const Color(0xFF0B1326),
          ],
        ).createShader(segRect);

      canvas.drawRect(segRect, strataPaint);

      // Section separator line
      final borderPaint = Paint()
        ..color = const Color(0xFF26396E)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(currentX, 15), Offset(currentX, h - 20), borderPaint);

      // Highlight selected segment
      if (i == selectedIndex) {
        final highlightPaint = Paint()
          ..color = AppTheme.primaryLight.withAlpha(80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRect(segRect, highlightPaint);
      }

      currentX += segWidth;
    }

    // Top Ground Level Surface (Undulating line)
    final glPath = Path();
    glPath.moveTo(0, 24);
    for (double x = 0; x <= w; x += 10) {
      final double wave = math.sin(x / 25) * 3;
      glPath.lineTo(x, 24 + wave);
    }
    final glPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(glPath, glPaint);

    // Pipeline Alignment Line (at depth ~75px from top)
    final pipePath = Path();
    pipePath.moveTo(0, 72);
    for (double x = 0; x <= w; x += 15) {
      final double wave = math.sin(x / 25) * 2;
      pipePath.lineTo(x, 72 + wave);
    }
    final pipePaint = Paint()
      ..color = const Color(0xFFFFB95F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawPath(pipePath, pipePaint);

    // Water Table Line (Dashed cyan)
    final wtPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.2;

    for (double x = 0; x < w; x += 8) {
      final double wave = math.sin(x / 30) * 4;
      canvas.drawLine(Offset(x, 48 + wave), Offset(x + 4, 48 + wave), wtPaint);
    }

    // Chainage Tick Labels at bottom
    const textStyle = TextStyle(color: AppTheme.textMuted, fontSize: 8.5, fontWeight: FontWeight.bold);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final ticks = [0.0, 5.0, 10.0, 15.0, 20.0, 24.5];
    for (final tick in ticks) {
      final double xPos = (tick / 24.5) * w;
      textPainter.text = TextSpan(text: '${tick.toInt()}k', style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(math.max(2, math.min(xPos - 8, w - 20)), h - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _LongitudinalStrataProfilePainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.entries != entries;
  }
}

// ==========================================
// CUSTOM PAINTER: CAD TRENCH CROSS-SECTION
// ==========================================
class _CadTrenchCrossSectionPainter extends CustomPainter {
  final TrenchLogEntry entry;

  _CadTrenchCrossSectionPainter({required this.entry});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final double centerX = w * 0.48;
    const double glY = 38.0; // Ground Level elevation

    // Scale factors: map meters to canvas pixels
    const double scale = 58.0; // 1 meter = 58 pixels

    final double trenchDepthPx = entry.trenchDepthM * scale;
    final double trenchBasePx = entry.trenchBaseWidthM * scale;
    final double trenchTopPx = entry.trenchTopWidthM * scale;

    final double trenchBottomY = glY + trenchDepthPx;
    final double topLeftX = centerX - (trenchTopPx / 2);
    final double topRightX = centerX + (trenchTopPx / 2);
    final double bottomLeftX = centerX - (trenchBasePx / 2);
    final double bottomRightX = centerX + (trenchBasePx / 2);

    // 1. Surrounding Soil Hatch / Stratification
    final soilRect = Rect.fromLTWH(0, glY, w, h - glY);
    final soilPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          entry.primaryStrata.color.withAlpha(80),
          entry.primaryStrata.color.withAlpha(140),
          const Color(0xFF0B1326),
        ],
      ).createShader(soilRect);
    canvas.drawRect(soilRect, soilPaint);

    // 2. Trench Void Cutout
    final trenchVoidPath = Path()
      ..moveTo(topLeftX, glY)
      ..lineTo(bottomLeftX, trenchBottomY)
      ..lineTo(bottomRightX, trenchBottomY)
      ..lineTo(topRightX, glY)
      ..close();

    final voidPaint = Paint()..color = const Color(0xFF091022);
    canvas.drawPath(trenchVoidPath, voidPaint);

    // Trench Wall Outline
    final wallPaint = Paint()
      ..color = const Color(0xFF26396E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(trenchVoidPath, wallPaint);

    // 3. Shoring Representation (Trench Box Plates if steel/hydraulic)
    if (entry.shoringMethod == ShoringMethod.steelTrenchBox ||
        entry.shoringMethod == ShoringMethod.hydraulicAluminum) {
      final shoringColor = entry.shoringMethod == ShoringMethod.steelTrenchBox
          ? const Color(0xFF38BDF8)
          : const Color(0xFFFFB95F);

      final shoringPaint = Paint()
        ..color = shoringColor
        ..strokeWidth = 4.0;

      // Left and right shoring plates
      canvas.drawLine(Offset(bottomLeftX, glY + 10), Offset(bottomLeftX, trenchBottomY - 5), shoringPaint);
      canvas.drawLine(Offset(bottomRightX, glY + 10), Offset(bottomRightX, trenchBottomY - 5), shoringPaint);

      // Hydraulic spreader struts across trench
      final strutPaint = Paint()
        ..color = shoringColor.withAlpha(180)
        ..strokeWidth = 2.5;
      canvas.drawLine(Offset(bottomLeftX, glY + (trenchDepthPx * 0.3)), Offset(bottomRightX, glY + (trenchDepthPx * 0.3)), strutPaint);
      canvas.drawLine(Offset(bottomLeftX, glY + (trenchDepthPx * 0.7)), Offset(bottomRightX, glY + (trenchDepthPx * 0.7)), strutPaint);
    }

    // 4. Compacted Sand Bedding (150mm thick)
    final double beddingHeightPx = (entry.beddingThicknessMm / 1000.0) * scale;
    final beddingRect = Rect.fromLTRB(
      bottomLeftX + 2,
      trenchBottomY - beddingHeightPx,
      bottomRightX - 2,
      trenchBottomY,
    );
    final beddingPaint = Paint()..color = const Color(0xFFD97706).withAlpha(160);
    canvas.drawRect(beddingRect, beddingPaint);

    // 5. 24" Pipeline (610mm OD)
    final double pipeDiameterPx = (entry.pipeOdMm / 1000.0) * scale;
    final double pipeRadius = pipeDiameterPx / 2;
    final double pipeCenterY = trenchBottomY - beddingHeightPx - pipeRadius;
    final Offset pipeCenter = Offset(centerX, pipeCenterY);

    // Pipe Outer Body (Steel + Yellow 3LPE coating)
    final pipeCoatingPaint = Paint()..color = const Color(0xFFFFB95F);
    canvas.drawCircle(pipeCenter, pipeRadius, pipeCoatingPaint);

    final pipeSteelPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawCircle(pipeCenter, pipeRadius - 3.5, pipeSteelPaint);

    final pipeBorePaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(pipeCenter, pipeRadius - 6, pipeBorePaint);

    // 6. Water Table Line (if water table in trench)
    final double wtDepthPx = entry.groundWaterLevelM * scale;
    final double wtY = glY + wtDepthPx;
    if (wtY < trenchBottomY) {
      final wtPaint = Paint()
        ..color = const Color(0xFF38BDF8)
        ..strokeWidth = 1.2;
      for (double x = 10; x < w - 60; x += 8) {
        canvas.drawLine(Offset(x, wtY), Offset(x + 4, wtY), wtPaint);
      }
    }

    // 7. Ground Level Line & Spoil Pile
    final glLinePaint = Paint()
      ..color = const Color(0xFF4EDEA3)
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(10, glY), Offset(topLeftX, glY), glLinePaint);
    canvas.drawLine(Offset(topRightX, glY), Offset(w - 20, glY), glLinePaint);

    // Spoil Pile on right side (with 1.5m setback)
    final double spoilStartX = topRightX + (1.5 * scale * 0.4);
    final spoilPath = Path()
      ..moveTo(spoilStartX, glY)
      ..lineTo(spoilStartX + 20, glY - 18)
      ..lineTo(spoilStartX + 42, glY)
      ..close();
    final spoilPaint = Paint()..color = entry.primaryStrata.color.withAlpha(150);
    canvas.drawPath(spoilPath, spoilPaint);

    // 8. Dimension Arrows & Annotations
    final dimPaint = Paint()
      ..color = entry.complianceStatus.color
      ..strokeWidth = 1.4;

    // Crown Cover Dimension (From GL to Top of Pipe)
    final double pipeCrownY = pipeCenterY - pipeRadius;
    const double dimX = 26.0;

    canvas.drawLine(const Offset(dimX, glY), Offset(dimX, pipeCrownY), dimPaint);
    canvas.drawLine(const Offset(dimX - 4, glY), const Offset(dimX + 4, glY), dimPaint);
    canvas.drawLine(Offset(dimX - 4, pipeCrownY), Offset(dimX + 4, pipeCrownY), dimPaint);

    // Crown Cover Text
    final coverText = TextPainter(
      text: TextSpan(
        text: 'Cover: ${entry.pipeCrownCoverM.toStringAsFixed(2)}m',
        style: TextStyle(
          color: entry.complianceStatus.color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    coverText.paint(canvas, Offset(dimX + 6, (glY + pipeCrownY) / 2 - 6));

    // Ground Level Label
    final glLabel = TextPainter(
      text: const TextSpan(
        text: 'GL 0.00m',
        style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glLabel.paint(canvas, const Offset(12, glY - 14));

    // Pipe Label
    final pipeLabel = TextPainter(
      text: const TextSpan(
        text: '24" OD 610mm',
        style: TextStyle(color: Color(0xFFFFB95F), fontSize: 8.5, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pipeLabel.paint(canvas, Offset(centerX - 30, pipeCenterY - 4));
  }

  @override
  bool shouldRepaint(covariant _CadTrenchCrossSectionPainter oldDelegate) {
    return oldDelegate.entry != entry;
  }
}
