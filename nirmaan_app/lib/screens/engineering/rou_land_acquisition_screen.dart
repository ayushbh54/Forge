import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DOMAIN MODELS & ENUMS — P&MP ACT, 1962 / ASSAM REVENUE & CADASTRAL SYSTEMS
// ============================================================================

/// Districts along the 194.5 KM Pipeline RoU Alignment
enum PipelineDistrict {
  dibrugarh(
    name: 'Dibrugarh',
    chainageSpan: 'Ch. 0.00 – 42.80 KM',
    startKm: 0.0,
    endKm: 42.8,
    headquarters: 'Dibrugarh / Duliajan',
    totalParcels: 278,
    clearedKm: 38.4,
    disbursedCrores: 9.85,
    activeStays: 1,
    color: Color(0xFF0284C7),
  ),
  sivasagar(
    name: 'Sivasagar',
    chainageSpan: 'Ch. 42.80 – 86.40 KM',
    startKm: 42.8,
    endKm: 86.4,
    headquarters: 'Sivasagar / Nazira',
    totalParcels: 264,
    clearedKm: 37.1,
    disbursedCrores: 8.92,
    activeStays: 1,
    color: Color(0xFF38BDF8),
  ),
  jorhat(
    name: 'Jorhat',
    chainageSpan: 'Ch. 86.40 – 128.20 KM',
    startKm: 86.4,
    endKm: 128.2,
    headquarters: 'Jorhat / Teok / Titabor',
    totalParcels: 256,
    clearedKm: 31.8,
    disbursedCrores: 7.45,
    activeStays: 2,
    color: Color(0xFFFFB95F),
  ),
  golaghat(
    name: 'Golaghat',
    chainageSpan: 'Ch. 128.20 – 164.70 KM',
    startKm: 128.2,
    endKm: 164.7,
    headquarters: 'Golaghat / Numaligarh',
    totalParcels: 242,
    clearedKm: 26.5,
    disbursedCrores: 5.12,
    activeStays: 1,
    color: Color(0xFFF59E0B),
  ),
  nagaon(
    name: 'Nagaon',
    chainageSpan: 'Ch. 164.70 – 194.50 KM',
    startKm: 164.7,
    endKm: 194.5,
    headquarters: 'Nagaon / Kaliabor',
    totalParcels: 208,
    clearedKm: 18.5,
    disbursedCrores: 3.58,
    activeStays: 1,
    color: Color(0xFF4EDEA3),
  );

  final String name;
  final String chainageSpan;
  final double startKm;
  final double endKm;
  final String headquarters;
  final int totalParcels;
  final double clearedKm;
  final double disbursedCrores;
  final int activeStays;
  final Color color;

  const PipelineDistrict({
    required this.name,
    required this.chainageSpan,
    required this.startKm,
    required this.endKm,
    required this.headquarters,
    required this.totalParcels,
    required this.clearedKm,
    required this.disbursedCrores,
    required this.activeStays,
    required this.color,
  });

  double get lengthKm => endKm - startKm;
  double get clearancePct => (clearedKm / lengthKm) * 100.0;
}

/// Assam Land Classifications (Assam Land Records & Dharitree Portal)
enum LandClassification {
  bari(
    name: 'Bari',
    description: 'Homestead & ancestral orchard land (Areca nut, bamboo, betel vine)',
    circleRatePerBigha: 1250000,
    color: Color(0xFF4EDEA3),
    badge: 'HOMESTEAD BARI',
  ),
  rupit(
    name: 'Rupit',
    description: 'First-class transplanted Sali / wet paddy agricultural land',
    circleRatePerBigha: 850000,
    color: Color(0xFF38BDF8),
    badge: 'AGRICULTURAL RUPIT',
  ),
  faringati(
    name: 'Faringati',
    description: 'Dry upland arable soil (Mustard, rapeseed, black gram, pulses)',
    circleRatePerBigha: 600000,
    color: Color(0xFFFFB95F),
    badge: 'UPLAND FARINGATI',
  ),
  teaGarden(
    name: 'Tea Garden',
    description: 'Commercial clonal tea plantation grant land / Small tea grower',
    circleRatePerBigha: 1500000,
    color: Color(0xFFA78BFA),
    badge: 'TEA GRANT',
  ),
  wetlandBeel(
    name: 'Doba / Beel',
    description: 'Perennial low-lying waterbody / fishery reservoir',
    circleRatePerBigha: 450000,
    color: Color(0xFF2DD4BF),
    badge: 'WETLAND / BEEL',
  );

  final String name;
  final String description;
  final double circleRatePerBigha;
  final Color color;
  final String badge;

  const LandClassification({
    required this.name,
    required this.description,
    required this.circleRatePerBigha,
    required this.color,
    required this.badge,
  });
}

/// Assam Cadastral Patta Types
enum PattaType {
  periodicMyadi('Periodic Patta (Myadi)', 'Permanent, heritable and transferable title rights'),
  annualEksona('Annual Patta (Eksona)', 'Renewable 1-year government lease title'),
  specialCultivation('Special Cultivation Grant', '30-year industrial tea plantation lease'),
  khasCeilingSurplus('Government Khas / Ceiling', 'State government unallotted revenue land');

  final String label;
  final String description;

  const PattaType(this.label, this.description);
}

/// Statutory Stages under P&MP Act, 1962
enum StatutoryStage {
  sec3_1Notified(
    stepNumber: 1,
    title: 'Sec 3(1) Intention Gazetted',
    legalSection: 'Section 3(1) of P&MP Act, 1962',
    description: 'Gazette Extra-Ordinary published; 21-day CALA objection period triggered',
    statusColor: Color(0xFF0284C7),
  ),
  sec5_1Objections(
    stepNumber: 2,
    title: 'Sec 5(1) CALA Hearing',
    legalSection: 'Section 5(1) of P&MP Act, 1962',
    description: 'Competent Authority conducts hearings and disposes written objections',
    statusColor: Color(0xFF38BDF8),
  ),
  sec6_1Declared(
    stepNumber: 3,
    title: 'Sec 6(1) Declaration Gazetted',
    legalSection: 'Section 6(1) of P&MP Act, 1962',
    description: 'Right of User vests absolutely in Central Govt free from all encumbrances',
    statusColor: Color(0xFFFFB95F),
  ),
  jointDamageSurvey(
    stepNumber: 4,
    title: 'Joint Damage Survey (JMS)',
    legalSection: 'Sections 6 & 10 Joint Inspection',
    description: 'Joint inventory of crops, timber trees, tea bushes & structures signed by Circle Officer',
    statusColor: Color(0xFFF59E0B),
  ),
  sec10AwardDetermined(
    stepNumber: 5,
    title: 'Sec 10 Award Determined',
    legalSection: 'Section 10(1) Compensation Order',
    description: 'Competent Authority assesses 10% RoU market value + damages schedule',
    statusColor: Color(0xFFA78BFA),
  ),
  sec10Disbursed(
    stepNumber: 6,
    title: 'Sec 10 Disbursement (DBT)',
    legalSection: 'Section 10(4) Direct Bank Transfer',
    description: 'Award amount credited directly to verified landowner bank account via PFMS',
    statusColor: Color(0xFF4EDEA3),
  ),
  corridorCleared(
    stepNumber: 7,
    title: '18m RoU Handover to EPC',
    legalSection: 'Section 7 Power to Enter Land',
    description: 'Permanent 18m corridor cleared of obstacles and handed over for trenching & pipe stringing',
    statusColor: Color(0xFF10B981),
  );

  final int stepNumber;
  final String title;
  final String legalSection;
  final String description;
  final Color statusColor;

  const StatutoryStage({
    required this.stepNumber,
    required this.title,
    required this.legalSection,
    required this.description,
    required this.statusColor,
  });
}

/// Legal Dispute / Court Stay Classification
enum DisputeStatus {
  none('Clear / No Dispute', Color(0xFF4EDEA3), Icons.verified_rounded),
  highCourtStay('Gauhati High Court Stay Order', Color(0xFFF43F5E), Icons.gavel_rounded),
  sec10_2DistrictCourt('Sec 10(2) Dist. Judge Reference', Color(0xFFFFB95F), Icons.account_balance_rounded),
  boundaryDemarcation('Circle Officer Boundary Dispute', Color(0xFF38BDF8), Icons.polyline_rounded),
  inheritancePartition('Legal Heir Partition Conflict', Color(0xFFA78BFA), Icons.family_restroom_rounded),
  teaEstateGrant('Tea Grant vs Raiyat Lease Dispute', Color(0xFFFB923C), Icons.nature_people_rounded),
  stayVacated('Stay Vacated / Amicable Accord', Color(0xFF2DD4BF), Icons.task_alt_rounded);

  final String label;
  final Color color;
  final IconData icon;

  const DisputeStatus(this.label, this.color, this.icon);
}

/// Cadastral Land Parcel Model
class CadastralParcel {
  final String id;
  final PipelineDistrict district;
  final String revenueVillage;
  final String revenueCircle;
  final String mouza;
  final String dagNo;
  final String pattaNo;
  final PattaType pattaType;
  final String landownerName;
  final String phone;
  final String bankAccountMasked;
  final String bankIfsc;
  final LandClassification classification;
  final double startChainageKm;
  final double endChainageKm;
  final double lengthInParcelM;
  final double rouWidthM; // Statutory 18.0m
  final double circleRatePerBigha;
  final StatutoryStage stage;
  final DisputeStatus disputeStatus;
  final String? disputeCaseRef;
  final String? disputeNotes;
  final DateTime sec3GazetteDate;
  final String sec3GazetteRef;
  final DateTime? sec6GazetteDate;
  final String? sec6GazetteRef;
  final DateTime? jmsDate;
  final bool isDisbursed;
  final String? paymentUtr;
  final double standingCropsValuation;
  final double teaBushesValuation;
  final double timberTreesValuation;
  final double structuresValuation;
  final double lidarGroundElevationM;
  final double lidarPointDensity;
  final List<String> identifiedObstacles;

  const CadastralParcel({
    required this.id,
    required this.district,
    required this.revenueVillage,
    required this.revenueCircle,
    required this.mouza,
    required this.dagNo,
    required this.pattaNo,
    required this.pattaType,
    required this.landownerName,
    required this.phone,
    required this.bankAccountMasked,
    required this.bankIfsc,
    required this.classification,
    required this.startChainageKm,
    required this.endChainageKm,
    required this.lengthInParcelM,
    this.rouWidthM = 18.0,
    required this.circleRatePerBigha,
    required this.stage,
    this.disputeStatus = DisputeStatus.none,
    this.disputeCaseRef,
    this.disputeNotes,
    required this.sec3GazetteDate,
    required this.sec3GazetteRef,
    this.sec6GazetteDate,
    this.sec6GazetteRef,
    this.jmsDate,
    this.isDisbursed = false,
    this.paymentUtr,
    this.standingCropsValuation = 0.0,
    this.teaBushesValuation = 0.0,
    this.timberTreesValuation = 0.0,
    this.structuresValuation = 0.0,
    required this.lidarGroundElevationM,
    this.lidarPointDensity = 42.5,
    this.identifiedObstacles = const [],
  });

  /// Total permanent RoU area in Square Meters
  double get rouAreaSqM => lengthInParcelM * rouWidthM;

  /// Assam standard: 1 Bigha = 1,337.8038 sq. meters = 5 Kathas = 100 Lessas
  double get totalBighas => rouAreaSqM / 1337.8038;

  int get bighas => totalBighas.floor();
  int get kathas => ((rouAreaSqM - (bighas * 1337.8038)) / 267.5608).floor();
  double get lessas =>
      (rouAreaSqM - (bighas * 1337.8038) - (kathas * 267.5608)) / 13.37804;

  String get assamAreaFormat =>
      '$bighas Bigha - $kathas Katha - ${lessas.toStringAsFixed(1)} Lessa';

  /// Total full market value of acquired parcel swath
  double get fullMarketValue => totalBighas * circleRatePerBigha;

  /// Section 10(1) Statutory RoU Compensation: Exactly 10% of Market Value
  double get statutoryRouLandPayment => fullMarketValue * 0.10;

  /// Total Compensation Award (Section 10)
  double get totalStatutoryAward =>
      statutoryRouLandPayment +
      standingCropsValuation +
      teaBushesValuation +
      timberTreesValuation +
      structuresValuation;
}

/// Dispute Case Dossier Model
class DisputeCaseRecord {
  final String caseId;
  final String courtForum;
  final String caseNumber;
  final String parcelId;
  final String revenueVillage;
  final String petitioner;
  final String respondents;
  final String chainageLocation;
  final String prayerAndGrounds;
  final DateTime stayGrantedDate;
  final DateTime nextListingDate;
  final DisputeStatus status;
  final String riskRating; // 'CRITICAL', 'MODERATE', 'LOW'
  final String defenseStrategy;
  final String stateCounsel;
  final double conditionalEscrowDeposit;

  const DisputeCaseRecord({
    required this.caseId,
    required this.courtForum,
    required this.caseNumber,
    required this.parcelId,
    required this.revenueVillage,
    required this.petitioner,
    required this.respondents,
    required this.chainageLocation,
    required this.prayerAndGrounds,
    required this.stayGrantedDate,
    required this.nextListingDate,
    required this.status,
    required this.riskRating,
    required this.defenseStrategy,
    required this.stateCounsel,
    this.conditionalEscrowDeposit = 0.0,
  });
}

/// Official Gazette Record Model
class GazetteRecord {
  final String gazetteId;
  final String sectionType;
  final String gazetteNumber;
  final DateTime notificationDate;
  final List<String> coveredDistricts;
  final int parcelsCount;
  final double alignmentLengthKm;
  final String status;
  final String issuingAuthority;

  const GazetteRecord({
    required this.gazetteId,
    required this.sectionType,
    required this.gazetteNumber,
    required this.notificationDate,
    required this.coveredDistricts,
    required this.parcelsCount,
    required this.alignmentLengthKm,
    required this.status,
    required this.issuingAuthority,
  });
}

// ============================================================================
// COMPENSATION ENGINE — STATUTORY RATES & CALCULATORS
// ============================================================================

class CompensationEngine {
  // Assam Agricultural Schedule (Directorate of Agriculture & MSP 2024-25)
  static const double saliPaddyYieldPerBighaQuintals = 18.0;
  static const double saliPaddyMspPerQuintal = 2300.0;
  static const double yellowMustardYieldPerBighaQuintals = 5.5;
  static const double yellowMustardMspPerQuintal = 5650.0;
  static const double seasonalVegetableRatePerBigha = 14000.0;

  // Tea Board of India Commercial Bush Valuation Schedule (Assam Valley)
  static const double teaBushImmatureRate = 220.0; // <3 years
  static const double teaBushYoungRate = 480.0; // 3-7 years
  static const double teaBushPrimeRate = 620.0; // 8-35 years (prime yield)
  static const double teaBushAgedRate = 340.0; // >35 years

  // Assam Forest Department Schedule of Timber Rates
  static const double timberClassA1SmallRate = 1800.0; // Sal, Teak, Gamari, Hollong (<60cm)
  static const double timberClassA1MediumRate = 6500.0; // (60-120cm)
  static const double timberClassA1LargeRate = 18000.0; // (>120cm)
  static const double timberClassA2MediumRate = 4800.0; // Nahar, Titachapa, Bonsum
  static const double bambooCulmRate = 180.0; // Bhaluka / Jati bamboo culm
  static const double betelNutBearingTreeRate = 1500.0; // Tamul tree (annual yield factor)

  /// Calculate Section 10(1) RoU Land Component (10% of Zonal Market Rate)
  static double calculateRouLandCompensation({
    required double areaSqM,
    required double circleRatePerBigha,
  }) {
    final bighas = areaSqM / 1337.8038;
    final fullMarketVal = bighas * circleRatePerBigha;
    return fullMarketVal * 0.10;
  }

  /// Calculate Crop Damage
  static double calculateCropDamage({
    required double areaSqM,
    required String cropType,
  }) {
    final bighas = areaSqM / 1337.8038;
    if (cropType == 'Sali Paddy (Transplanted)') {
      return bighas * saliPaddyYieldPerBighaQuintals * saliPaddyMspPerQuintal;
    } else if (cropType == 'Yellow Mustard (Rape Seed)') {
      return bighas * yellowMustardYieldPerBighaQuintals * yellowMustardMspPerQuintal;
    } else if (cropType == 'Seasonal Winter Vegetables') {
      return bighas * seasonalVegetableRatePerBigha;
    }
    return 0.0;
  }

  /// Calculate Tea Bush Valuation based on Tea Board of India Norms
  static double calculateTeaBushValuation({
    required int bushCount,
    required String ageBracket,
  }) {
    double ratePerBush = teaBushPrimeRate;
    if (ageBracket == 'Immature (< 3 Years)') {
      ratePerBush = teaBushImmatureRate;
    } else if (ageBracket == 'Young Bearing (3 – 7 Years)') {
      ratePerBush = teaBushYoungRate;
    } else if (ageBracket == 'Prime Commercial (8 – 35 Years)') {
      ratePerBush = teaBushPrimeRate;
    } else if (ageBracket == 'Over-aged (> 35 Years)') {
      ratePerBush = teaBushAgedRate;
    }
    return bushCount * ratePerBush;
  }

  /// Calculate Timber Valuation
  static double calculateTimberValuation({
    required int classA1Trees,
    required int classA2Trees,
    required int bambooCulms,
    required int betelNutTrees,
  }) {
    return (classA1Trees * timberClassA1MediumRate) +
        (classA2Trees * timberClassA2MediumRate) +
        (bambooCulms * bambooCulmRate) +
        (betelNutTrees * betelNutBearingTreeRate);
  }

  /// Calculate Statutory Delayed Payment Interest under Section 10(4)
  static double calculateStatutoryInterest({
    required double principalAward,
    required int delayedMonths,
  }) {
    if (delayedMonths <= 0) return 0.0;
    // 6.0% simple interest per annum
    return principalAward * 0.06 * (delayedMonths / 12.0);
  }
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class RouLandAcquisitionScreen extends StatefulWidget {
  const RouLandAcquisitionScreen({super.key});

  @override
  State<RouLandAcquisitionScreen> createState() => _RouLandAcquisitionScreenState();
}

class _RouLandAcquisitionScreenState extends State<RouLandAcquisitionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Selected Filter State
  String _selectedDistrictFilter = 'ALL';
  String _selectedClassificationFilter = 'ALL';
  String _selectedStageFilter = 'ALL';
  String _searchQuery = '';
  bool _filterOnlyDisputes = false;

  // Selected Parcel for Detail View
  CadastralParcel? _selectedParcel;

  // Interactive Compensation Calculator State
  double _calcParcelLengthM = 150.0;
  LandClassification _calcClassification = LandClassification.rupit;
  double _calcCustomCircleRate = 850000;
  String _calcCropType = 'Sali Paddy (Transplanted)';
  int _calcTeaBushCount = 120;
  String _calcTeaBushAgeBracket = 'Prime Commercial (8 – 35 Years)';
  int _calcClassA1Trees = 4;
  int _calcClassA2Trees = 6;
  int _calcBambooCulms = 35;
  int _calcBetelNutTrees = 28;
  double _calcStructureDamage = 45000.0;
  bool _calcIncludeStatutoryInterest = true;
  int _calcDelayedMonths = 8;

  // LiDAR Cross-Section Scrubber Chainage (0 to 194.5 KM)
  double _scrubberChainageKm = 28.2;

  // Dataset Collections
  late List<CadastralParcel> _parcels;
  late List<DisputeCaseRecord> _disputeCases;
  late List<GazetteRecord> _gazetteRecords;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _parcels = [
      CadastralParcel(
        id: 'PARCEL-DIB-0014',
        district: PipelineDistrict.dibrugarh,
        revenueVillage: 'Tipam Gaon',
        revenueCircle: 'Tengakhat Revenue Circle',
        mouza: 'Tengakhat Mouza',
        dagNo: 'Dag 412/108',
        pattaNo: 'Periodic Patta 78',
        pattaType: PattaType.periodicMyadi,
        landownerName: 'Bhaben Hazarika & Pulin Hazarika',
        phone: '+91 94350 18234',
        bankAccountMasked: 'SBIN*****8491',
        bankIfsc: 'SBIN0001421',
        classification: LandClassification.bari,
        startChainageKm: 12.450,
        endChainageKm: 12.592,
        lengthInParcelM: 142.0,
        circleRatePerBigha: 1250000,
        stage: StatutoryStage.corridorCleared,
        disputeStatus: DisputeStatus.none,
        sec3GazetteDate: DateTime(2024, 1, 15),
        sec3GazetteRef: 'Gaz. Ext. 2024/PMP/AS/01',
        sec6GazetteDate: DateTime(2024, 7, 10),
        sec6GazetteRef: 'Gaz. Ext. 2024/PMP/AS/07',
        jmsDate: DateTime(2024, 8, 22),
        isDisbursed: true,
        paymentUtr: 'PFMS20240915SBIN882194',
        standingCropsValuation: 0.0,
        teaBushesValuation: 0.0,
        timberTreesValuation: 64500.0,
        structuresValuation: 38000.0,
        lidarGroundElevationM: 124.6,
        identifiedObstacles: const ['6 Betel nut trees felled', '1 RCC well protected outside 18m swath'],
      ),
      CadastralParcel(
        id: 'PARCEL-DIB-0089',
        district: PipelineDistrict.dibrugarh,
        revenueVillage: 'Duliajan Habigaon',
        revenueCircle: 'Naharkatia Revenue Circle',
        mouza: 'Naharkatia Mouza',
        dagNo: 'Dag 198/44',
        pattaNo: 'Periodic Patta 112',
        pattaType: PattaType.periodicMyadi,
        landownerName: 'Hemanta Gogoi (Small Tea Grower)',
        phone: '+91 98540 76211',
        bankAccountMasked: 'PUNB*****3312',
        bankIfsc: 'PUNB0291000',
        classification: LandClassification.teaGarden,
        startChainageKm: 28.110,
        endChainageKm: 28.310,
        lengthInParcelM: 200.0,
        circleRatePerBigha: 1500000,
        stage: StatutoryStage.sec6_1Declared,
        disputeStatus: DisputeStatus.sec10_2DistrictCourt,
        disputeCaseRef: 'CALA/MISC/2024/88',
        disputeNotes: 'Petitioner filed Sec 10(2) reference seeking commercial bush rate enhancement',
        sec3GazetteDate: DateTime(2024, 1, 15),
        sec3GazetteRef: 'Gaz. Ext. 2024/PMP/AS/01',
        sec6GazetteDate: DateTime(2024, 7, 10),
        sec6GazetteRef: 'Gaz. Ext. 2024/PMP/AS/07',
        jmsDate: DateTime(2024, 9, 05),
        isDisbursed: false,
        standingCropsValuation: 0.0,
        teaBushesValuation: 372000.0,
        timberTreesValuation: 18000.0,
        structuresValuation: 12000.0,
        lidarGroundElevationM: 118.2,
        identifiedObstacles: const ['600 clonal tea bushes within 18m corridor', '1 Shade Albizia tree'],
      ),
      CadastralParcel(
        id: 'PARCEL-SVR-0045',
        district: PipelineDistrict.sivasagar,
        revenueVillage: 'Nitai Pukhuri',
        revenueCircle: 'Demow Revenue Circle',
        mouza: 'Demow Mouza',
        dagNo: 'Dag 77/12',
        pattaNo: 'Periodic Patta 34',
        pattaType: PattaType.periodicMyadi,
        landownerName: 'Diganta Saikia',
        phone: '+91 94351 90812',
        bankAccountMasked: 'UBIN*****7144',
        bankIfsc: 'UBIN0538914',
        classification: LandClassification.rupit,
        startChainageKm: 54.200,
        endChainageKm: 54.380,
        lengthInParcelM: 180.0,
        circleRatePerBigha: 850000,
        stage: StatutoryStage.sec10AwardDetermined,
        disputeStatus: DisputeStatus.none,
        sec3GazetteDate: DateTime(2024, 1, 15),
        sec3GazetteRef: 'Gaz. Ext. 2024/PMP/AS/01',
        sec6GazetteDate: DateTime(2024, 8, 22),
        sec6GazetteRef: 'Gaz. Ext. 2024/PMP/AS/09',
        jmsDate: DateTime(2024, 10, 14),
        isDisbursed: false,
        standingCropsValuation: 100260.0, // Sali paddy
        teaBushesValuation: 0.0,
        timberTreesValuation: 0.0,
        structuresValuation: 0.0,
        lidarGroundElevationM: 96.4,
        identifiedObstacles: const ['Transplanted Sali Paddy crop (harvest awaited)'],
      ),
      CadastralParcel(
        id: 'PARCEL-SVR-0112',
        district: PipelineDistrict.sivasagar,
        revenueVillage: 'Mezenga Gaon',
        revenueCircle: 'Nazira Revenue Circle',
        mouza: 'Mezenga Mouza',
        dagNo: 'Dag 523/89',
        pattaNo: 'Periodic Patta 201',
        pattaType: PattaType.periodicMyadi,
        landownerName: 'Monomati Chetia',
        phone: '+91 97060 44219',
        bankAccountMasked: 'SBIN*****6290',
        bankIfsc: 'SBIN0002049',
        classification: LandClassification.faringati,
        startChainageKm: 72.100,
        endChainageKm: 72.240,
        lengthInParcelM: 140.0,
        circleRatePerBigha: 600000,
        stage: StatutoryStage.jointDamageSurvey,
        disputeStatus: DisputeStatus.boundaryDemarcation,
        disputeCaseRef: 'CO/DEM/2025/14',
        disputeNotes: 'Circle Officer joint boundary peg realignment requested with PWD roadside',
        sec3GazetteDate: DateTime(2024, 1, 15),
        sec3GazetteRef: 'Gaz. Ext. 2024/PMP/AS/01',
        sec6GazetteDate: DateTime(2024, 8, 22),
        sec6GazetteRef: 'Gaz. Ext. 2024/PMP/AS/09',
        jmsDate: DateTime(2024, 11, 02),
        isDisbursed: false,
        standingCropsValuation: 58500.0, // Mustard
        teaBushesValuation: 0.0,
        timberTreesValuation: 12000.0,
        structuresValuation: 0.0,
        lidarGroundElevationM: 92.1,
        identifiedObstacles: const ['Yellow mustard crop', 'Bamboo fence on northern RoU boundary'],
      ),
      CadastralParcel(
        id: 'PARCEL-JHT-0067',
        district: PipelineDistrict.jorhat,
        revenueVillage: 'Seleng Hat Gaon',
        revenueCircle: 'Teok Revenue Circle',
        mouza: 'Lahing Mouza',
        dagNo: 'Dag 881/31',
        pattaNo: 'Special Cultivation Grant 65',
        pattaType: PattaType.specialCultivation,
        landownerName: 'Pranjal Baruah & Tea Estate Partners',
        phone: '+91 94350 49102',
        bankAccountMasked: 'HDFC*****9981',
        bankIfsc: 'HDFC0001824',
        classification: LandClassification.teaGarden,
        startChainageKm: 98.400,
        endChainageKm: 98.620,
        lengthInParcelM: 220.0,
        circleRatePerBigha: 1500000,
        stage: StatutoryStage.sec6_1Declared,
        disputeStatus: DisputeStatus.highCourtStay,
        disputeCaseRef: 'WP(C) 4120/2025 Gauhati HC',
        disputeNotes: 'Gauhati High Court interim stay on trenching; challenge to tea bush gestation loss schedule',
        sec3GazetteDate: DateTime(2024, 2, 28),
        sec3GazetteRef: 'Gaz. Ext. 2024/PMP/AS/02',
        sec6GazetteDate: DateTime(2024, 11, 18),
        sec6GazetteRef: 'Gaz. Ext. 2024/PMP/AS/14',
        jmsDate: DateTime(2024, 11, 29),
        isDisbursed: false,
        standingCropsValuation: 0.0,
        teaBushesValuation: 582800.0,
        timberTreesValuation: 36000.0,
        structuresValuation: 65000.0,
        lidarGroundElevationM: 88.5,
        identifiedObstacles: const ['940 Prime tea bushes', 'Internal estate masonry drainage channel'],
      ),
      CadastralParcel(
        id: 'PARCEL-JHT-0142',
        district: PipelineDistrict.jorhat,
        revenueVillage: 'Madhapur Gaon',
        revenueCircle: 'Titabor Revenue Circle',
        mouza: 'Titabor Mouza',
        dagNo: 'Dag 311/09',
        pattaNo: 'Periodic Patta 144',
        pattaType: PattaType.periodicMyadi,
        landownerName: 'Ananta Bora',
        phone: '+91 98641 55092',
        bankAccountMasked: 'SBIN*****4012',
        bankIfsc: 'SBIN0000109',
        classification: LandClassification.rupit,
        startChainageKm: 116.000,
        endChainageKm: 116.160,
        lengthInParcelM: 160.0,
        circleRatePerBigha: 850000,
        stage: StatutoryStage.sec10Disbursed,
        disputeStatus: DisputeStatus.none,
        sec3GazetteDate: DateTime(2024, 2, 28),
        sec3GazetteRef: 'Gaz. Ext. 2024/PMP/AS/02',
        sec6GazetteDate: DateTime(2024, 11, 18),
        sec6GazetteRef: 'Gaz. Ext. 2024/PMP/AS/14',
        jmsDate: DateTime(2024, 12, 05),
        isDisbursed: true,
        paymentUtr: 'PFMS20250118SBIN009124',
        standingCropsValuation: 89100.0,
        teaBushesValuation: 0.0,
        timberTreesValuation: 0.0,
        structuresValuation: 0.0,
        lidarGroundElevationM: 84.2,
        identifiedObstacles: const ['Sali paddy harvest completed', '18m corridor demarcated with RCC markers'],
      ),
      CadastralParcel(
        id: 'PARCEL-GLT-0033',
        district: PipelineDistrict.golaghat,
        revenueVillage: 'Mohpara Gaon',
        revenueCircle: 'Bokakhat Revenue Circle',
        mouza: 'Kaziranga Mouza',
        dagNo: 'Dag 64/18',
        pattaNo: 'Periodic Patta 52',
        pattaType: PattaType.periodicMyadi,
        landownerName: 'Lakhimi Kurmi & Brothers',
        phone: '+91 97063 88120',
        bankAccountMasked: 'CBIN*****5110',
        bankIfsc: 'CBIN0281290',
        classification: LandClassification.bari,
        startChainageKm: 138.800,
        endChainageKm: 138.940,
        lengthInParcelM: 140.0,
        circleRatePerBigha: 1250000,
        stage: StatutoryStage.sec6_1Declared,
        disputeStatus: DisputeStatus.inheritancePartition,
        disputeCaseRef: 'REV/PART/2024/91',
        disputeNotes: 'Legal heirs partition in Circle Officer court; joint escrow account agreed for DBT',
        sec3GazetteDate: DateTime(2024, 2, 28),
        sec3GazetteRef: 'Gaz. Ext. 2024/PMP/AS/02',
        sec6GazetteDate: DateTime(2024, 11, 18),
        sec6GazetteRef: 'Gaz. Ext. 2024/PMP/AS/14',
        jmsDate: DateTime(2024, 12, 19),
        isDisbursed: false,
        standingCropsValuation: 0.0,
        teaBushesValuation: 0.0,
        timberTreesValuation: 52000.0,
        structuresValuation: 25000.0,
        lidarGroundElevationM: 78.4,
        identifiedObstacles: const ['14 Mature Betel nut trees', 'Bamboo clump on western boundary'],
      ),
      CadastralParcel(
        id: 'PARCEL-GLT-0098',
        district: PipelineDistrict.golaghat,
        revenueVillage: 'Telgaram Gaon',
        revenueCircle: 'Numaligarh Revenue Circle',
        mouza: 'Morongi Mouza',
        dagNo: 'Dag 402/76',
        pattaNo: 'Special Cultivation Grant 189',
        pattaType: PattaType.specialCultivation,
        landownerName: 'Numaligarh Tea Estate Ltd.',
        phone: '+91 94350 33811',
        bankAccountMasked: 'UTBI*****1045',
        bankIfsc: 'UTBI0NUM801',
        classification: LandClassification.teaGarden,
        startChainageKm: 154.200,
        endChainageKm: 154.500,
        lengthInParcelM: 300.0,
        circleRatePerBigha: 1500000,
        stage: StatutoryStage.sec6_1Declared,
        disputeStatus: DisputeStatus.sec10_2DistrictCourt,
        disputeCaseRef: 'DJ-GLT-2024-0312',
        disputeNotes: 'Section 10(2) petition claiming factory tea leaf transport hindrance; conditional escrow deposited',
        sec3GazetteDate: DateTime(2024, 2, 28),
        sec3GazetteRef: 'Gaz. Ext. 2024/PMP/AS/02',
        sec6GazetteDate: DateTime(2024, 11, 18),
        sec6GazetteRef: 'Gaz. Ext. 2024/PMP/AS/14',
        jmsDate: DateTime(2025, 1, 08),
        isDisbursed: false,
        standingCropsValuation: 0.0,
        teaBushesValuation: 790000.0,
        timberTreesValuation: 45000.0,
        structuresValuation: 110000.0,
        lidarGroundElevationM: 72.8,
        identifiedObstacles: const ['1,270 Prime commercial tea bushes', 'Internal tractor road crossing requiring HDD'],
      ),
      CadastralParcel(
        id: 'PARCEL-NGN-0021',
        district: PipelineDistrict.nagaon,
        revenueVillage: 'Kuwaritol Gaon',
        revenueCircle: 'Kaliabor Revenue Circle',
        mouza: 'Kaliabor Mouza',
        dagNo: 'Dag 115/33',
        pattaNo: 'Periodic Patta 87',
        pattaType: PattaType.periodicMyadi,
        landownerName: 'Jiten Mahanta',
        phone: '+91 94355 60124',
        bankAccountMasked: 'SBIN*****9201',
        bankIfsc: 'SBIN0002075',
        classification: LandClassification.rupit,
        startChainageKm: 172.300,
        endChainageKm: 172.450,
        lengthInParcelM: 150.0,
        circleRatePerBigha: 850000,
        stage: StatutoryStage.sec10Disbursed,
        disputeStatus: DisputeStatus.none,
        sec3GazetteDate: DateTime(2024, 2, 28),
        sec3GazetteRef: 'Gaz. Ext. 2024/PMP/AS/02',
        sec6GazetteDate: DateTime(2024, 11, 18),
        sec6GazetteRef: 'Gaz. Ext. 2024/PMP/AS/14',
        jmsDate: DateTime(2025, 1, 15),
        isDisbursed: true,
        paymentUtr: 'PFMS20250210SBIN904812',
        standingCropsValuation: 83500.0,
        teaBushesValuation: 0.0,
        timberTreesValuation: 0.0,
        structuresValuation: 0.0,
        lidarGroundElevationM: 64.1,
        identifiedObstacles: const ['No obstacles; 18m corridor handed over for trenching'],
      ),
      CadastralParcel(
        id: 'PARCEL-NGN-0078',
        district: PipelineDistrict.nagaon,
        revenueVillage: 'Bajiagaon',
        revenueCircle: 'Samaguri Revenue Circle',
        mouza: 'Samaguri Mouza',
        dagNo: 'Dag 290/61',
        pattaNo: 'Periodic Patta 133',
        pattaType: PattaType.periodicMyadi,
        landownerName: 'Abdul Latif & Brothers',
        phone: '+91 98544 19280',
        bankAccountMasked: 'CBIN*****7419',
        bankIfsc: 'CBIN0283011',
        classification: LandClassification.faringati,
        startChainageKm: 188.100,
        endChainageKm: 188.280,
        lengthInParcelM: 180.0,
        circleRatePerBigha: 600000,
        stage: StatutoryStage.sec3_1Notified,
        disputeStatus: DisputeStatus.none,
        sec3GazetteDate: DateTime(2024, 2, 28),
        sec3GazetteRef: 'Gaz. Ext. 2024/PMP/AS/02',
        sec6GazetteDate: null,
        sec6GazetteRef: null,
        jmsDate: null,
        isDisbursed: false,
        standingCropsValuation: 75200.0,
        teaBushesValuation: 0.0,
        timberTreesValuation: 8000.0,
        structuresValuation: 0.0,
        lidarGroundElevationM: 58.7,
        identifiedObstacles: const ['Seasonal pulse crop', 'DGPS boundary flags fixed'],
      ),
    ];

    _selectedParcel = _parcels[0];

    _disputeCases = [
      DisputeCaseRecord(
        caseId: 'HC-GHY-2024-4120',
        courtForum: 'Gauhati High Court (Principal Bench, Guwahati)',
        caseNumber: 'WP(C) 4120/2025',
        parcelId: 'PARCEL-JHT-0067',
        revenueVillage: 'Seleng Hat Gaon, Teok Circle, Jorhat',
        petitioner: 'Pranjal Baruah & Tea Estate Partners',
        respondents: 'Union of India (MoPNG), Competent Authority P&MP Act, Deputy Commissioner Jorhat',
        chainageLocation: 'Ch. 98+400 – 98+620 (220m)',
        prayerAndGrounds:
            'Challenged tea bush damage valuation rate. Prayed for stay on pipeline trenching within 18m corridor pending re-survey by Tea Board of India.',
        stayGrantedDate: DateTime(2024, 12, 10),
        nextListingDate: DateTime(2025, 4, 18),
        status: DisputeStatus.highCourtStay,
        riskRating: 'CRITICAL',
        defenseStrategy:
            'Joint affidavit filed citing Section 10(1) statutory schedule and Tea Board commercial bush guidelines. Moving vacation application under Article 226(3).',
        stateCounsel: 'Senior Standing Counsel for Central Govt & P&MP CALA',
        conditionalEscrowDeposit: 750000.0,
      ),
      DisputeCaseRecord(
        caseId: 'DJ-GLT-2024-0312',
        courtForum: 'Court of District & Sessions Judge, Golaghat',
        caseNumber: 'Misc. Case (P&MP) 312/2024',
        parcelId: 'PARCEL-GLT-0098',
        revenueVillage: 'Telgaram Gaon, Numaligarh Circle, Golaghat',
        petitioner: 'Numaligarh Tea Estate Ltd.',
        respondents: 'Competent Authority, P&MP Act & Project Proponent',
        chainageLocation: 'Ch. 154+200 – 154+500 (300m)',
        prayerAndGrounds:
            'Section 10(2) reference for enhancement of land RoU market valuation and vehicular culvert access across 18m corridor.',
        stayGrantedDate: DateTime(2024, 11, 24),
        nextListingDate: DateTime(2025, 4, 25),
        status: DisputeStatus.sec10_2DistrictCourt,
        riskRating: 'MODERATE',
        defenseStrategy:
            'Pipeline engineering EPC committed to reinforced concrete slab crossing over pipeline trench. 50% provisional compensation deposited in Court registry.',
        stateCounsel: 'Government Pleader, Golaghat District Bar',
        conditionalEscrowDeposit: 950000.0,
      ),
      DisputeCaseRecord(
        caseId: 'CALA-DIB-2024-0088',
        courtForum: 'CALA Statutory Revenue Tribunal, Dibrugarh',
        caseNumber: 'CALA/MISC/2024/88',
        parcelId: 'PARCEL-DIB-0089',
        revenueVillage: 'Duliajan Habigaon, Naharkatia Circle',
        petitioner: 'Hemanta Gogoi & All Assam Small Tea Growers Association',
        respondents: 'CALA Dibrugarh & Revenue Circle Officer Naharkatia',
        chainageLocation: 'Ch. 28+110 – 28+310 (200m)',
        prayerAndGrounds:
            'Section 10(2) compensation enhancement from ₹8.5L/Bigha to ₹15L/Bigha on ground of clonal plantation conversion.',
        stayGrantedDate: DateTime(2024, 8, 15),
        nextListingDate: DateTime(2025, 4, 10),
        status: DisputeStatus.sec10_2DistrictCourt,
        riskRating: 'MODERATE',
        defenseStrategy:
            'CALA scheduled joint hearing with Tea Board Advisory Officer to inspect clone age records. Work permitted on working strip with escrow deposit.',
        stateCounsel: 'CALA Legal Advisor, Dibrugarh',
        conditionalEscrowDeposit: 420000.0,
      ),
      DisputeCaseRecord(
        caseId: 'REV-SVR-2025-0014',
        courtForum: 'Circle Officer Revenue Demarcation Court, Nazira',
        caseNumber: 'CO/DEM/2025/14',
        parcelId: 'PARCEL-SVR-0112',
        revenueVillage: 'Mezenga Gaon, Nazira Circle, Sivasagar',
        petitioner: 'Monomati Chetia & PWD Roads Division',
        respondents: 'Competent Authority, P&MP Act',
        chainageLocation: 'Ch. 72+100 – 72+240 (140m)',
        prayerAndGrounds:
            'Demarcation overlap between 18m pipeline statutory RoU and PWD state highway right-of-way reservation.',
        stayGrantedDate: DateTime(2025, 1, 20),
        nextListingDate: DateTime(2025, 4, 08),
        status: DisputeStatus.boundaryDemarcation,
        riskRating: 'LOW',
        defenseStrategy:
            'DGPS joint survey conducted by Lot Mondal and LiDAR survey team. Alignment shifted 2.5m southwards within private parcel with landowner consent.',
        stateCounsel: 'Lot Mondal & Kanungo, Nazira Circle',
        conditionalEscrowDeposit: 0.0,
      ),
      DisputeCaseRecord(
        caseId: 'HC-GHY-2024-3891',
        courtForum: 'Gauhati High Court (Principal Bench, Guwahati)',
        caseNumber: 'WP(C) 3891/2024',
        parcelId: 'PARCEL-DIB-0014',
        revenueVillage: 'Tipam Gaon, Tengakhat Circle, Dibrugarh',
        petitioner: 'Tipam Gram Unnayan Samiti',
        respondents: 'Union of India & State of Assam',
        chainageLocation: 'Ch. 12+450 – 12+592 (142m)',
        prayerAndGrounds:
            'Alleged infringement on Village Grazing Reserve (VGR) land. Demanded route realignment.',
        stayGrantedDate: DateTime(2024, 3, 14),
        nextListingDate: DateTime(2024, 6, 20),
        status: DisputeStatus.stayVacated,
        riskRating: 'LOW',
        defenseStrategy:
            'Cadastral overlay proved alignment strictly traversing private Myadi Patta Dag 412/108 without touching VGR. High Court dismissed writ with liberty to proceed.',
        stateCounsel: 'Senior Standing Counsel for MoPNG',
        conditionalEscrowDeposit: 0.0,
      ),
    ];

    _gazetteRecords = [
      GazetteRecord(
        gazetteId: 'GAZ-01',
        sectionType: 'Section 3(1) Notification',
        gazetteNumber: 'Gazette Extra-Ordinary No. 2024/PMP/AS/01',
        notificationDate: DateTime(2024, 1, 15),
        coveredDistricts: const ['Dibrugarh', 'Sivasagar'],
        parcelsCount: 542,
        alignmentLengthKm: 86.4,
        status: 'Objection Period Expired & Finalized',
        issuingAuthority: 'Ministry of Petroleum & Natural Gas, New Delhi',
      ),
      GazetteRecord(
        gazetteId: 'GAZ-02',
        sectionType: 'Section 3(1) Notification',
        gazetteNumber: 'Gazette Extra-Ordinary No. 2024/PMP/AS/02',
        notificationDate: DateTime(2024, 2, 28),
        coveredDistricts: const ['Jorhat', 'Golaghat', 'Nagaon'],
        parcelsCount: 706,
        alignmentLengthKm: 108.1,
        status: 'Objection Period Expired & Finalized',
        issuingAuthority: 'Ministry of Petroleum & Natural Gas, New Delhi',
      ),
      GazetteRecord(
        gazetteId: 'GAZ-03',
        sectionType: 'Section 6(1) Declaration',
        gazetteNumber: 'Gazette Extra-Ordinary No. 2024/PMP/AS/07',
        notificationDate: DateTime(2024, 7, 10),
        coveredDistricts: const ['Dibrugarh'],
        parcelsCount: 278,
        alignmentLengthKm: 42.8,
        status: 'Vested Absolutely in Central Govt',
        issuingAuthority: 'Competent Authority, P&MP Act, Dibrugarh',
      ),
      GazetteRecord(
        gazetteId: 'GAZ-04',
        sectionType: 'Section 6(1) Declaration',
        gazetteNumber: 'Gazette Extra-Ordinary No. 2024/PMP/AS/09',
        notificationDate: DateTime(2024, 8, 22),
        coveredDistricts: const ['Sivasagar'],
        parcelsCount: 264,
        alignmentLengthKm: 43.6,
        status: 'Vested Absolutely in Central Govt',
        issuingAuthority: 'Competent Authority, P&MP Act, Sivasagar',
      ),
      GazetteRecord(
        gazetteId: 'GAZ-05',
        sectionType: 'Section 6(1) Declaration',
        gazetteNumber: 'Gazette Extra-Ordinary No. 2024/PMP/AS/14',
        notificationDate: DateTime(2024, 11, 18),
        coveredDistricts: const ['Jorhat', 'Golaghat'],
        parcelsCount: 498,
        alignmentLengthKm: 78.3,
        status: 'Vested Absolutely in Central Govt',
        issuingAuthority: 'Competent Authority, P&MP Act, Jorhat',
      ),
    ];
  }

  List<CadastralParcel> get _filteredParcels {
    return _parcels.where((p) {
      if (_selectedDistrictFilter != 'ALL' &&
          p.district.name.toUpperCase() != _selectedDistrictFilter.toUpperCase()) {
        return false;
      }
      if (_selectedClassificationFilter != 'ALL' &&
          p.classification.name.toUpperCase() != _selectedClassificationFilter.toUpperCase()) {
        return false;
      }
      if (_selectedStageFilter != 'ALL' &&
          p.stage.name.toUpperCase() != _selectedStageFilter.toUpperCase()) {
        return false;
      }
      if (_filterOnlyDisputes && p.disputeStatus == DisputeStatus.none) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = p.id.toLowerCase().contains(q) ||
            p.dagNo.toLowerCase().contains(q) ||
            p.pattaNo.toLowerCase().contains(q) ||
            p.revenueVillage.toLowerCase().contains(q) ||
            p.landownerName.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  // ==========================================================================
  // BUILD METHOD & SCAFFOLD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Land Acquisition (RoU) & Cadastral GIS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'P&MP Act, 1962 • 18m Corridor • 194.5 KM Alignment (Assam)',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryLight),
            tooltip: 'P&MP Act Statutory Guide',
            onPressed: _showStatutoryGuideModal,
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppTheme.tertiary),
            tooltip: 'Sync with Dharitree / Bhunaksha Portal',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dharitree Assam Cadastral API synchronized successfully (1,248 Dags verified)'),
                  backgroundColor: AppTheme.surfaceCard,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryLight,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: 'Corridor Overview'),
            Tab(icon: Icon(Icons.layers_rounded, size: 18), text: 'Cadastral Parcels'),
            Tab(icon: Icon(Icons.timeline_rounded, size: 18), text: 'Statutory Stages'),
            Tab(icon: Icon(Icons.calculate_rounded, size: 18), text: 'Compensation Calculator'),
            Tab(icon: Icon(Icons.gavel_rounded, size: 18), text: 'Court Stays & Disputes'),
            Tab(icon: Icon(Icons.terrain_rounded, size: 18), text: 'LiDAR Cross-Section'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCorridorOverviewTab(),
          _buildCadastralParcelsTab(),
          _buildStatutoryStagesTab(),
          _buildCompensationCalculatorTab(),
          _buildCourtStaysTab(),
          _buildLidarCrossSectionTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text('New Parcel Entry', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: _showAddParcelModal,
      ),
    );
  }

  // ==========================================================================
  // TAB 1: CORRIDOR OVERVIEW & KEY STATUTORY METRICS
  // ==========================================================================

  Widget _buildCorridorOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2552), Color(0xFF162347)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.account_balance_rounded, color: AppTheme.primaryLight, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Petroleum & Minerals Pipelines (Acquisition of Right of User in Land) Act, 1962',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Statutory 18.0m permanent RoU strip (350.1 Hectares) along 194.5 KM corridor traversing Dibrugarh, Sivasagar, Jorhat, Golaghat, and Nagaon districts.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Key Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'ALIGNMENT LENGTH',
                  value: '194.5 KM',
                  subtitle: '5 Districts • 18m Width',
                  icon: Icons.straighten_rounded,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'TOTAL PARCELS',
                  value: '1,248 Dags',
                  subtitle: '88 Revenue Villages',
                  icon: Icons.grid_view_rounded,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'ROU CLEARED (ROW)',
                  value: '152.3 KM',
                  subtitle: '78.3% Pipeline Front Open',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'DISBURSED (DBT)',
                  value: '₹34.92 Cr',
                  subtitle: '81.5% of ₹42.85 Cr CALA Award',
                  icon: Icons.payments_rounded,
                  color: const Color(0xFFA78BFA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Statutory Stage Funnel
          const Text(
            'STATUTORY PIPELINE STAGES (194.5 KM CORRIDOR FUNNEL)',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _buildStageFunnelCard(),
          const SizedBox(height: 20),

          // District Breakdown Cards
          const Text(
            'DISTRICT-WISE CADASTRAL PROGRESS',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...PipelineDistrict.values.map(_buildDistrictCard),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageFunnelCard() {
    final stagesData = [
      {'title': 'LiDAR & Cadastral DGPS Survey', 'km': '194.5 KM', 'pct': 1.0, 'color': AppTheme.primaryLight},
      {'title': 'Sec 3(1) Intention Gazetted', 'km': '194.5 KM', 'pct': 1.0, 'color': AppTheme.primaryLight},
      {'title': 'Sec 5(1) Objections Disposed', 'km': '186.2 KM', 'pct': 0.957, 'color': AppTheme.secondary},
      {'title': 'Sec 6(1) Declaration Gazetted', 'km': '179.8 KM', 'pct': 0.924, 'color': AppTheme.secondary},
      {'title': 'Joint Damage Survey (JMS)', 'km': '171.4 KM', 'pct': 0.881, 'color': const Color(0xFFF59E0B)},
      {'title': 'Sec 10 Compensation Awarded', 'km': '164.2 KM', 'pct': 0.844, 'color': const Color(0xFFA78BFA)},
      {'title': 'Sec 10 Disbursement (DBT/PFMS)', 'km': '158.6 KM', 'pct': 0.815, 'color': AppTheme.tertiary},
      {'title': '18m RoU Cleared & Handed Over', 'km': '152.3 KM', 'pct': 0.783, 'color': const Color(0xFF10B981)},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: stagesData.map((stage) {
          final title = stage['title'] as String;
          final km = stage['km'] as String;
          final pct = stage['pct'] as double;
          final color = stage['color'] as Color;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$km (${(pct * 100).toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppTheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDistrictCard(PipelineDistrict district) {
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
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: district.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                district.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: district.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  district.chainageSpan,
                  style: TextStyle(
                    color: district.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Parcels: ${district.totalParcels} Dags',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                'Cleared: ${district.clearedKm.toStringAsFixed(1)} / ${district.lengthKm.toStringAsFixed(1)} KM (${district.clearancePct.toStringAsFixed(1)}%)',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: district.clearancePct / 100.0,
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(district.color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DBT Disbursed: ₹${district.disbursedCrores.toStringAsFixed(2)} Cr',
                style: const TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              if (district.activeStays > 0)
                Text(
                  '${district.activeStays} Court Stay Active',
                  style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 11, fontWeight: FontWeight.w700),
                )
              else
                const Text(
                  '0 Active Court Stays',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: CADASTRAL PARCEL REGISTRY (DAG, PATTA, OWNER, AREA, COMPENSATION)
  // ==========================================================================

  Widget _buildCadastralParcelsTab() {
    final parcels = _filteredParcels;

    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.surface,
          child: Column(
            children: [
              // Search Input
              TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by Dag No, Patta, Village, Landowner name...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textMuted),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // District Filter
                    _buildFilterDropdown(
                      label: 'District: $_selectedDistrictFilter',
                      items: ['ALL', 'DIBRUGARH', 'SIVASAGAR', 'JORHAT', 'GOLAGHAT', 'NAGAON'],
                      selectedValue: _selectedDistrictFilter,
                      onChanged: (val) {
                        setState(() {
                          _selectedDistrictFilter = val!;
                        });
                      },
                    ),
                    const SizedBox(width: 8),

                    // Land Classification Filter
                    _buildFilterDropdown(
                      label: 'Class: $_selectedClassificationFilter',
                      items: ['ALL', 'BARI', 'RUPIT', 'FARINGATI', 'TEAGARDEN', 'WETLANDBEEL'],
                      selectedValue: _selectedClassificationFilter,
                      onChanged: (val) {
                        setState(() {
                          _selectedClassificationFilter = val!;
                        });
                      },
                    ),
                    const SizedBox(width: 8),

                    // Stage Filter
                    _buildFilterDropdown(
                      label: 'Stage: $_selectedStageFilter',
                      items: [
                        'ALL',
                        'SEC3_1NOTIFIED',
                        'SEC5_1OBJECTIONS',
                        'SEC6_1DECLARED',
                        'JOINTDAMAGESURVEY',
                        'SEC10AWARDDETERMINED',
                        'SEC10DISBURSED',
                        'CORRIDORCLEARED'
                      ],
                      selectedValue: _selectedStageFilter,
                      onChanged: (val) {
                        setState(() {
                          _selectedStageFilter = val!;
                        });
                      },
                    ),
                    const SizedBox(width: 8),

                    // Dispute Filter Toggle
                    FilterChip(
                      label: const Text('Disputed / Stay Only', style: TextStyle(fontSize: 11)),
                      selected: _filterOnlyDisputes,
                      selectedColor: const Color(0xFFF43F5E).withValues(alpha: 0.25),
                      checkmarkColor: const Color(0xFFF43F5E),
                      labelStyle: TextStyle(
                        color: _filterOnlyDisputes ? const Color(0xFFF43F5E) : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _filterOnlyDisputes = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Parcels List
        Expanded(
          child: parcels.isEmpty
              ? const Center(
                  child: Text(
                    'No cadastral parcels match the selected filter criteria.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: parcels.length,
                  itemBuilder: (context, index) {
                    final parcel = parcels[index];
                    return _buildParcelCard(parcel);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required List<String> items,
    required String selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 20, color: AppTheme.textMuted),
          dropdownColor: AppTheme.surfaceCard,
          style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildParcelCard(CadastralParcel parcel) {
    final isSelected = _selectedParcel?.id == parcel.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppTheme.primaryLight : AppTheme.border,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _selectedParcel = parcel;
          });
          _showParcelDetailsModal(parcel);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: parcel.district.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: parcel.district.color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      parcel.district.name.toUpperCase(),
                      style: TextStyle(
                        color: parcel.district.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: parcel.classification.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      parcel.classification.badge,
                      style: TextStyle(
                        color: parcel.classification.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Stage pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: parcel.stage.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      parcel.stage.title,
                      style: TextStyle(
                        color: parcel.stage.statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dag & Patta No and Village
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${parcel.dagNo} • ${parcel.pattaNo}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Ch. ${parcel.startChainageKm.toStringAsFixed(3)} KM',
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${parcel.revenueVillage}, ${parcel.revenueCircle}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),

              // Landowner Name & Area
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      parcel.landownerName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    parcel.assamAreaFormat,
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // RoU Corridor Footprint & Award Amount
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '18m RoU Strip',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        ),
                        Text(
                          '${parcel.lengthInParcelM.toStringAsFixed(1)}m × 18m (${parcel.rouAreaSqM.toStringAsFixed(0)} m²)',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Sec 10 Total Award',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        ),
                        Text(
                          '₹${_formatCurrency(parcel.totalStatutoryAward)}',
                          style: const TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Dispute Tag if active
              if (parcel.disputeStatus != DisputeStatus.none) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: parcel.disputeStatus.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: parcel.disputeStatus.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(parcel.disputeStatus.icon, size: 14, color: parcel.disputeStatus.color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${parcel.disputeStatus.label} (${parcel.disputeCaseRef ?? 'Pending'})',
                          style: TextStyle(
                            color: parcel.disputeStatus.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 3: STATUTORY STAGES & GAZETTE TRACKER (P&MP ACT 1962)
  // ==========================================================================

  Widget _buildStatutoryStagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statutory Flowchart Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: AppTheme.primaryLight, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'P&MP Act, 1962 Statutory Workflow',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'The statutory process mandated by Parliament for acquisition of Right of User in land for laying interstate petroleum & natural gas pipelines without taking absolute ownership.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stepper Timeline of the 7 Statutory Stages
          ...StatutoryStage.values.map((stage) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: stage.statusColor.withValues(alpha: 0.2),
                    child: Text(
                      '${stage.stepNumber}',
                      style: TextStyle(
                        color: stage.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stage.title,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: stage.statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                stage.legalSection,
                                style: TextStyle(
                                  color: stage.statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stage.description,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // Gazette Notifications Archive
          const Text(
            'OFFICIAL GAZETTE NOTIFICATIONS (EXTRA-ORDINARY)',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ..._gazetteRecords.map((gaz) {
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
                        gaz.sectionType,
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${gaz.notificationDate.day}/${gaz.notificationDate.month}/${gaz.notificationDate.year}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gaz.gazetteNumber,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Districts: ${gaz.coveredDistricts.join(', ')} • ${gaz.parcelsCount} Parcels • ${gaz.alignmentLengthKm} KM',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Auth: ${gaz.issuingAuthority}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          gaz.status,
                          style: const TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: INTERACTIVE COMPENSATION CALCULATOR (P&MP ACT SECTION 10)
  // ==========================================================================

  Widget _buildCompensationCalculatorTab() {
    final areaSqM = _calcParcelLengthM * 18.0;
    final bighas = areaSqM / 1337.8038;
    final intBighas = bighas.floor();
    final intKathas = ((areaSqM - (intBighas * 1337.8038)) / 267.5608).floor();
    final dblLessas = (areaSqM - (intBighas * 1337.8038) - (intKathas * 267.5608)) / 13.37804;

    // Calculate Components
    final rouLandComp = CompensationEngine.calculateRouLandCompensation(
      areaSqM: areaSqM,
      circleRatePerBigha: _calcCustomCircleRate,
    );

    final cropComp = CompensationEngine.calculateCropDamage(
      areaSqM: areaSqM,
      cropType: _calcCropType,
    );

    final teaComp = (_calcClassification == LandClassification.teaGarden)
        ? CompensationEngine.calculateTeaBushValuation(
            bushCount: _calcTeaBushCount,
            ageBracket: _calcTeaBushAgeBracket,
          )
        : 0.0;

    final timberComp = CompensationEngine.calculateTimberValuation(
      classA1Trees: _calcClassA1Trees,
      classA2Trees: _calcClassA2Trees,
      bambooCulms: _calcBambooCulms,
      betelNutTrees: _calcBetelNutTrees,
    );

    final principalAward = rouLandComp + cropComp + teaComp + timberComp + _calcStructureDamage;

    final statutoryInterest = _calcIncludeStatutoryInterest
        ? CompensationEngine.calculateStatutoryInterest(
            principalAward: principalAward,
            delayedMonths: _calcDelayedMonths,
          )
        : 0.0;

    final totalAward = principalAward + statutoryInterest;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Award Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D2847), Color(0xFF162347)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL STATUTORY CALA AWARD (FORM 10)',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SEC 10(1) & 10(4)',
                        style: TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${_formatCurrency(totalAward)}',
                  style: const TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '18m RoU Area: $intBighas Bigha - $intKathas Katha - ${dblLessas.toStringAsFixed(1)} Lessa (${areaSqM.toStringAsFixed(0)} m²)',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // Sub-breakdowns
                _buildAwardLineItem('10% Land RoU Payment (Section 10(1))', rouLandComp),
                _buildAwardLineItem('Standing Crop Damage ($cropComp)', cropComp),
                if (teaComp > 0) _buildAwardLineItem('Tea Bush Damage (Tea Board Norms)', teaComp),
                _buildAwardLineItem('Timber Trees & Betel Nut Clumps', timberComp),
                _buildAwardLineItem('Damaged Structures & Boundary Wall', _calcStructureDamage),
                if (_calcIncludeStatutoryInterest)
                  _buildAwardLineItem('Statutory Interest @ 6% p.a. ($_calcDelayedMonths mos)', statutoryInterest,
                      isHighlight: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Inputs Card
          const Text(
            'STATUTORY VALUATION PARAMETERS',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
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
                // Parcel Length Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Parcel Length along 18m Corridor:',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('${_calcParcelLengthM.toStringAsFixed(1)} meters',
                        style: const TextStyle(color: AppTheme.primaryLight, fontSize: 13, fontWeight: FontWeight.w800)),
                  ],
                ),
                Slider(
                  value: _calcParcelLengthM,
                  min: 20.0,
                  max: 500.0,
                  divisions: 96,
                  activeColor: AppTheme.primaryLight,
                  inactiveColor: AppTheme.surface,
                  onChanged: (val) {
                    setState(() {
                      _calcParcelLengthM = val;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Land Classification Dropdown
                const Text('Assam Land Classification:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<LandClassification>(
                      value: _calcClassification,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceCard,
                      items: LandClassification.values.map((cls) {
                        return DropdownMenuItem<LandClassification>(
                          value: cls,
                          child: Text('${cls.name} (${cls.badge})',
                              style: TextStyle(color: cls.color, fontWeight: FontWeight.w700, fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _calcClassification = val;
                            _calcCustomCircleRate = val.circleRatePerBigha;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Circle Market Rate Slider / Input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Circle Market Rate (₹ / Bigha):',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('₹${_formatCurrency(_calcCustomCircleRate)}',
                        style: const TextStyle(color: AppTheme.secondary, fontSize: 13, fontWeight: FontWeight.w800)),
                  ],
                ),
                Slider(
                  value: _calcCustomCircleRate,
                  min: 300000.0,
                  max: 2500000.0,
                  divisions: 44,
                  activeColor: AppTheme.secondary,
                  inactiveColor: AppTheme.surface,
                  onChanged: (val) {
                    setState(() {
                      _calcCustomCircleRate = val;
                    });
                  },
                ),
                const SizedBox(height: 14),

                // Standing Crop Dropdown
                const Text('Standing Crop Type (Harvest Damage):',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _calcCropType,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceCard,
                      items: const [
                        DropdownMenuItem(
                            value: 'Sali Paddy (Transplanted)',
                            child: Text('Sali Paddy (Transplanted) — MSP ₹2,300/Qtl')),
                        DropdownMenuItem(
                            value: 'Yellow Mustard (Rape Seed)',
                            child: Text('Yellow Mustard (Rape Seed) — MSP ₹5,650/Qtl')),
                        DropdownMenuItem(
                            value: 'Seasonal Winter Vegetables',
                            child: Text('Seasonal Winter Vegetables — ₹14,000/Bigha')),
                        DropdownMenuItem(value: 'None / Fallow', child: Text('None / Fallow Land')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _calcCropType = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tea Bush Section (if tea garden)
                if (_calcClassification == LandClassification.teaGarden) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tea Bushes to be Uprooted:',
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                            Text('$_calcTeaBushCount Bushes',
                                style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 13, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        Slider(
                          value: _calcTeaBushCount.toDouble(),
                          min: 0.0,
                          max: 1500.0,
                          divisions: 150,
                          activeColor: const Color(0xFFA78BFA),
                          onChanged: (val) {
                            setState(() {
                              _calcTeaBushCount = val.toInt();
                            });
                          },
                        ),
                        const Text('Tea Board Age Classification:',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _calcTeaBushAgeBracket,
                              isExpanded: true,
                              dropdownColor: AppTheme.surfaceCard,
                              items: const [
                                DropdownMenuItem(value: 'Immature (< 3 Years)', child: Text('Immature (< 3 Yrs, ₹220/bush)')),
                                DropdownMenuItem(value: 'Young Bearing (3 – 7 Years)', child: Text('Young Bearing (3-7 Yrs, ₹480/bush)')),
                                DropdownMenuItem(value: 'Prime Commercial (8 – 35 Years)', child: Text('Prime Commercial (8-35 Yrs, ₹620/bush)')),
                                DropdownMenuItem(value: 'Over-aged (> 35 Years)', child: Text('Over-aged (> 35 Yrs, ₹340/bush)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _calcTeaBushAgeBracket = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Forest & Tree Valuation Inputs
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberInputCounter(
                        label: 'Class A1 Timber (Sal/Teak)',
                        value: _calcClassA1Trees,
                        onChanged: (v) => setState(() => _calcClassA1Trees = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberInputCounter(
                        label: 'Class A2 Timber (Nahar)',
                        value: _calcClassA2Trees,
                        onChanged: (v) => setState(() => _calcClassA2Trees = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberInputCounter(
                        label: 'Bamboo Culms',
                        value: _calcBambooCulms,
                        onChanged: (v) => setState(() => _calcBambooCulms = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberInputCounter(
                        label: 'Betel Nut (Tamul)',
                        value: _calcBetelNutTrees,
                        onChanged: (v) => setState(() => _calcBetelNutTrees = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Structure & Boundary Wall Damage Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Structure & Boundary Wall Damage:',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('₹${_formatCurrency(_calcStructureDamage)}',
                        style: const TextStyle(color: AppTheme.primaryLight, fontSize: 13, fontWeight: FontWeight.w800)),
                  ],
                ),
                Slider(
                  value: _calcStructureDamage,
                  min: 0.0,
                  max: 200000.0,
                  divisions: 40,
                  activeColor: AppTheme.primaryLight,
                  inactiveColor: AppTheme.surface,
                  onChanged: (val) {
                    setState(() {
                      _calcStructureDamage = val;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Statutory Interest Checkbox & Months
                Row(
                  children: [
                    Checkbox(
                      value: _calcIncludeStatutoryInterest,
                      activeColor: AppTheme.tertiary,
                      onChanged: (val) {
                        setState(() {
                          _calcIncludeStatutoryInterest = val ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Include Sec 10(4) Statutory Interest (6.0% p.a. from Sec 6(1) vesting)',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (_calcIncludeStatutoryInterest) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delayed Period (Months):',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text('$_calcDelayedMonths Months',
                          style: const TextStyle(color: AppTheme.tertiary, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Slider(
                    value: _calcDelayedMonths.toDouble(),
                    min: 1,
                    max: 36,
                    divisions: 35,
                    activeColor: AppTheme.tertiary,
                    onChanged: (val) {
                      setState(() {
                        _calcDelayedMonths = val.toInt();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Button: Generate Statutory Award Form 10
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text('Generate Statutory Award Form 10 Notice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _showAwardFormPreviewModal(
                totalAward: totalAward,
                rouLandComp: rouLandComp,
                cropComp: cropComp,
                teaComp: teaComp,
                timberComp: timberComp,
                structuresValuation: _calcStructureDamage,
                statutoryInterest: statutoryInterest,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwardLineItem(String title, double amount, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isHighlight ? AppTheme.tertiary : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            '₹${_formatCurrency(amount)}',
            style: TextStyle(
              color: isHighlight ? AppTheme.tertiary : AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInputCounter({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
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
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: value > 0 ? () => onChanged(value - 1) : null,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.remove, size: 16, color: AppTheme.textSecondary),
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
              ),
              InkWell(
                onTap: () => onChanged(value + 1),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add, size: 16, color: AppTheme.primaryLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 5: DISPUTE RESOLUTION & COURT STAY CASE TRACKER
  // ==========================================================================

  Widget _buildCourtStaysTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legal Risk Summary
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'ACTIVE HIGH COURT STAYS',
                  value: '1 Case',
                  subtitle: 'Gauhati High Court (Jorhat)',
                  icon: Icons.gavel_rounded,
                  color: const Color(0xFFF43F5E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'SEC 10(2) REFERENCES',
                  value: '2 Cases',
                  subtitle: 'District Courts (Golaghat/Dib)',
                  icon: Icons.account_balance_rounded,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'CONDITIONAL ESCROW',
                  value: '₹21.20 Lakh',
                  subtitle: 'Permitted Pipelaying front',
                  icon: Icons.lock_clock_rounded,
                  color: AppTheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'STAYS VACATED',
                  value: '1 Case',
                  subtitle: 'Tipam Gaon VGR dismissal',
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF2DD4BF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active Litigation Tracker Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LITIGATION & INJUNCTION DOSSIERS',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Log Notice', style: TextStyle(fontSize: 12)),
                onPressed: _showAddDisputeModal,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dispute Cards List
          ..._disputeCases.map(_buildDisputeCaseCard),
        ],
      ),
    );
  }

  Widget _buildDisputeCaseCard(DisputeCaseRecord dispute) {
    Color riskColor;
    if (dispute.riskRating == 'CRITICAL') {
      riskColor = const Color(0xFFF43F5E);
    } else if (dispute.riskRating == 'MODERATE') {
      riskColor = AppTheme.secondary;
    } else {
      riskColor = AppTheme.tertiary;
    }

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
          // Case Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: riskColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${dispute.riskRating} RISK',
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dispute.caseNumber,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dispute.status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dispute.status.label,
                  style: TextStyle(
                    color: dispute.status.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            dispute.courtForum,
            style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Location: ${dispute.chainageLocation} • ${dispute.revenueVillage}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),

          // Petitioner vs Respondents
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              children: [
                const TextSpan(text: 'Petitioner: ', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                TextSpan(text: dispute.petitioner),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Grounds
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Grounds: ${dispute.prayerAndGrounds}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 8),

          // Strategy & Counsel
          Text(
            'Defense Strategy: ${dispute.defenseStrategy}',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, height: 1.3),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Hearing: ${dispute.nextListingDate.day}/${dispute.nextListingDate.month}/${dispute.nextListingDate.year}',
                style: const TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.w700),
              ),
              if (dispute.conditionalEscrowDeposit > 0)
                Text(
                  'Escrow: ₹${_formatCurrency(dispute.conditionalEscrowDeposit)}',
                  style: const TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 6: LIDAR 18M ROU CORRIDOR & CADASTRAL CROSS-SECTION
  // ==========================================================================

  Widget _buildLidarCrossSectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alignment Scrubber Header
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
                      'ALIGNMENT INSPECTOR (194.5 KM ALIGNMENT)',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      'Chainage: ${_scrubberChainageKm.toStringAsFixed(1)} KM',
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _scrubberChainageKm,
                  min: 0.0,
                  max: 194.5,
                  divisions: 194,
                  activeColor: AppTheme.primaryLight,
                  inactiveColor: AppTheme.surface,
                  onChanged: (val) {
                    setState(() {
                      _scrubberChainageKm = val;
                    });
                  },
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ch. 0.00 (Duliajan)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    Text('Ch. 86.4 (Nazira)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    Text('Ch. 194.5 (Nagaon)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Custom Painted 18m Corridor Cross-Section
          const Text(
            'STATUTORY 18M ROU CORRIDOR & TRENCH CROSS-SECTION',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 220,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF070D1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: CustomPaint(
              painter: _RouCorridorCrossSectionPainter(
                chainageKm: _scrubberChainageKm,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Corridor Strip Breakdown Legend Card
          Container(
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
                  '18m RoU Statutory Corridor Strip Allocation (OISD-141 Standard)',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildCorridorStripTag('Working Side', '11.0m Width', AppTheme.primaryLight),
                    const SizedBox(width: 8),
                    _buildCorridorStripTag('Trench Zone', '2.5m Width', AppTheme.secondary),
                    const SizedBox(width: 8),
                    _buildCorridorStripTag('Spoil Bank', '4.5m Width', const Color(0xFF8D6E63)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '• Left RoU Boundary (-9.0m from centerline) to Right RoU Boundary (+9.0m from centerline).\n'
                  '• Permanent pipeline right-of-user restricts deep-rooted trees, permanent masonry structures, and mining.\n'
                  '• Normal agricultural tilling (ploughing up to 45cm depth) permitted to landowner after commissioning.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // LiDAR Point Cloud Metadata
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLidarMetric('LiDAR DENSITY', '42.8 pts/m²', Icons.grain_rounded, AppTheme.primaryLight),
                _buildLidarMetric('GROUND ELEVATION', '118.4 m MSL', Icons.terrain_rounded, AppTheme.secondary),
                _buildLidarMetric('CAD/DGPS OVERLAY', '99.4% Match', Icons.check_circle_rounded, AppTheme.tertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorridorStripTag(String label, String width, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(width, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildLidarMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ==========================================================================
  // MODALS & DIALOGS
  // ==========================================================================

  void _showParcelDetailsModal(CadastralParcel parcel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
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

                  // Title & Dag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${parcel.dagNo} • ${parcel.pattaNo}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: parcel.stage.statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          parcel.stage.title,
                          style: TextStyle(
                            color: parcel.stage.statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${parcel.revenueVillage}, ${parcel.mouza}, ${parcel.revenueCircle}, District ${parcel.district.name}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const Divider(color: AppTheme.border, height: 24),

                  // Landowner Details
                  _buildModalDetailRow('Landowner Name', parcel.landownerName),
                  _buildModalDetailRow('Contact Phone', parcel.phone),
                  _buildModalDetailRow('Direct Benefit Bank', '${parcel.bankAccountMasked} (${parcel.bankIfsc})'),
                  _buildModalDetailRow('Land Classification', '${parcel.classification.name} (${parcel.classification.description})'),
                  _buildModalDetailRow('Patta Title Type', parcel.pattaType.label),
                  _buildModalDetailRow('Alignment Chainage', 'Ch. ${parcel.startChainageKm.toStringAsFixed(3)} to ${parcel.endChainageKm.toStringAsFixed(3)} KM'),
                  _buildModalDetailRow('Parcel Length in RoU', '${parcel.lengthInParcelM.toStringAsFixed(1)} m'),
                  _buildModalDetailRow('Corridor Footprint', '18.0m Width × ${parcel.lengthInParcelM.toStringAsFixed(1)}m = ${parcel.rouAreaSqM.toStringAsFixed(1)} m²'),
                  _buildModalDetailRow('Assam Revenue Measure', parcel.assamAreaFormat),
                  _buildModalDetailRow('Zonal Circle Rate', '₹${_formatCurrency(parcel.circleRatePerBigha)} / Bigha'),
                  _buildModalDetailRow('10% RoU Statutory Value', '₹${_formatCurrency(parcel.statutoryRouLandPayment)}'),
                  _buildModalDetailRow('Standing Crop Valuation', '₹${_formatCurrency(parcel.standingCropsValuation)}'),
                  _buildModalDetailRow('Tea Bushes Valuation', '₹${_formatCurrency(parcel.teaBushesValuation)}'),
                  _buildModalDetailRow('Timber / Tree Valuation', '₹${_formatCurrency(parcel.timberTreesValuation)}'),
                  _buildModalDetailRow('Structures Valuation', '₹${_formatCurrency(parcel.structuresValuation)}'),
                  _buildModalDetailRow('Total CALA Award', '₹${_formatCurrency(parcel.totalStatutoryAward)}', isBold: true),
                  _buildModalDetailRow('Disbursement Status', parcel.isDisbursed ? 'DISBURSED via PFMS' : 'PENDING DISBURSEMENT'),
                  if (parcel.paymentUtr != null)
                    _buildModalDetailRow('PFMS / UTR Ref', parcel.paymentUtr!),
                  const Divider(color: AppTheme.border, height: 24),

                  // Gazette & Statutory Refs
                  _buildModalDetailRow('Sec 3(1) Gazette', '${parcel.sec3GazetteRef} (${parcel.sec3GazetteDate.day}/${parcel.sec3GazetteDate.month}/${parcel.sec3GazetteDate.year})'),
                  if (parcel.sec6GazetteRef != null)
                    _buildModalDetailRow('Sec 6(1) Declaration', '${parcel.sec6GazetteRef} (${parcel.sec6GazetteDate?.day}/${parcel.sec6GazetteDate?.month}/${parcel.sec6GazetteDate?.year})'),
                  if (parcel.jmsDate != null)
                    _buildModalDetailRow('Joint Survey (JMS)', '${parcel.jmsDate?.day}/${parcel.jmsDate?.month}/${parcel.jmsDate?.year} (Circle Officer Signed)'),
                  const Divider(color: AppTheme.border, height: 24),

                  // Obstacles & LiDAR
                  const Text('Identified Obstacles & Clearance Notes:',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  ...parcel.identifiedObstacles.map((obs) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppTheme.primaryLight, fontSize: 14)),
                            Expanded(child: Text(obs, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),

                  // Action Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Switch to calculator tab and pre-fill
                      setState(() {
                        _calcParcelLengthM = parcel.lengthInParcelM;
                        _calcClassification = parcel.classification;
                        _calcCustomCircleRate = parcel.circleRatePerBigha;
                        _tabController.animateTo(3);
                      });
                    },
                    child: const Text('Open in Compensation Calculator'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isBold ? AppTheme.tertiary : AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAwardFormPreviewModal({
    required double totalAward,
    required double rouLandComp,
    required double cropComp,
    required double teaComp,
    required double timberComp,
    required double structuresValuation,
    required double statutoryInterest,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.description_rounded, color: AppTheme.primaryLight),
              SizedBox(width: 8),
              Expanded(
                child: Text('Statutory Award Form 10 Preview', style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BEFORE THE COMPETENT AUTHORITY UNDER THE PETROLEUM AND MINERALS PIPELINES ACT, 1962',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'NOTICE OF DETERMINATION OF COMPENSATION UNDER SECTION 10',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(color: AppTheme.border, height: 20),
                  const Text('Corridor Swath: 18.0 Meters Statutory RoU Strip along 194.5 KM Pipeline',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  _buildAwardLineItem('10% Land RoU Compensation (Sec 10(1))', rouLandComp),
                  _buildAwardLineItem('Standing Crop Damage Compensation', cropComp),
                  if (teaComp > 0) _buildAwardLineItem('Tea Bush Valuation (Tea Board Norms)', teaComp),
                  _buildAwardLineItem('Forest Timber & Tree Valuation', timberComp),
                  _buildAwardLineItem('Damage to Structures / Boundary Wells', structuresValuation),
                  _buildAwardLineItem('Statutory Interest @ 6% p.a. (Sec 10(4))', statutoryInterest),
                  const Divider(color: AppTheme.border, height: 16),
                  _buildAwardLineItem('TOTAL STATUTORY AWARD DETERMINED', totalAward, isHighlight: true),
                  const SizedBox(height: 12),
                  const Text(
                    'Take notice that the above amount will be disbursed via Direct Benefit Transfer (PFMS) to your bank account upon verification of your original Patta and indemnity bond.',
                    style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.print_rounded, size: 16),
              label: const Text('Print Award Notice'),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Statutory Award Notice Form 10 dispatched for digital sign & DBT disbursement.'),
                    backgroundColor: AppTheme.surfaceCard,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showStatutoryGuideModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: AppTheme.primaryLight),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('P&MP Act, 1962 Statutory Reference Guide',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Key Statutory Sections for RoU Pipeline Corridor Acquisition:\n\n'
                '• Section 3(1): Central Government declares intention to acquire Right of User in Official Gazette. 21-day public objection countdown begins.\n'
                '• Section 5(1): Competent Authority (CALA) hears objections from land titleholders and passes statutory disposal orders.\n'
                '• Section 6(1): Declaration of acquisition gazetted. Right of user vests absolutely in Central Govt/Corporation free from all encumbrances.\n'
                '• Section 7: Power to enter land, dig trenches, string pipes, construct cathodic protection skids.\n'
                '• Section 10(1): Compensation determination — 10% of market value of land + 100% standing crops, timber trees, and tea bushes.\n'
                '• Section 10(2): Aggrieved parties may request reference to District Judge having jurisdiction within statutory limitation.\n'
                '• Section 10(4): Statutory interest @ 6% p.a. payable from date of vesting under Sec 6(1) to date of payment.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Understood'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddParcelModal() {
    final dagController = TextEditingController();
    final pattaController = TextEditingController();
    final villageController = TextEditingController();
    final ownerController = TextEditingController();
    final phoneController = TextEditingController();
    final lengthController = TextEditingController(text: '150');
    PipelineDistrict selectedDist = PipelineDistrict.dibrugarh;
    LandClassification selectedClass = LandClassification.rupit;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Add Cadastral Parcel to RoU Registry', style: TextStyle(fontSize: 15)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: dagController,
                        decoration: const InputDecoration(labelText: 'Dag Number (e.g. Dag 215/12)'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: pattaController,
                        decoration: const InputDecoration(labelText: 'Patta Number (e.g. Periodic Patta 91)'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: villageController,
                        decoration: const InputDecoration(labelText: 'Revenue Village & Circle'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ownerController,
                        decoration: const InputDecoration(labelText: 'Landowner Full Name'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Contact Phone Number'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: lengthController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Parcel Length in 18m RoU Corridor (meters)'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<PipelineDistrict>(
                              initialValue: selectedDist,
                              decoration: const InputDecoration(labelText: 'District'),
                              items: PipelineDistrict.values.map((d) {
                                return DropdownMenuItem(value: d, child: Text(d.name, style: const TextStyle(fontSize: 12)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedDist = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<LandClassification>(
                              initialValue: selectedClass,
                              decoration: const InputDecoration(labelText: 'Land Class'),
                              items: LandClassification.values.map((c) {
                                return DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(fontSize: 12)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedClass = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final length = double.tryParse(lengthController.text) ?? 150.0;
                    final newParcel = CadastralParcel(
                      id: 'PARCEL-${selectedDist.name.substring(0, 3).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch % 10000}',
                      district: selectedDist,
                      revenueVillage: villageController.text.isNotEmpty ? villageController.text : 'New Revenue Village',
                      revenueCircle: '${selectedDist.name} Revenue Circle',
                      mouza: '${selectedDist.name} Mouza',
                      dagNo: dagController.text.isNotEmpty ? dagController.text : 'Dag 101/01',
                      pattaNo: pattaController.text.isNotEmpty ? pattaController.text : 'Periodic Patta 50',
                      pattaType: PattaType.periodicMyadi,
                      landownerName: ownerController.text.isNotEmpty ? ownerController.text : 'Landowner Name',
                      phone: phoneController.text.isNotEmpty ? phoneController.text : '+91 94350 00000',
                      bankAccountMasked: 'SBIN*****1234',
                      bankIfsc: 'SBIN0001000',
                      classification: selectedClass,
                      startChainageKm: selectedDist.startKm + 2.5,
                      endChainageKm: selectedDist.startKm + 2.5 + (length / 1000.0),
                      lengthInParcelM: length,
                      circleRatePerBigha: selectedClass.circleRatePerBigha,
                      stage: StatutoryStage.sec3_1Notified,
                      sec3GazetteDate: DateTime.now(),
                      sec3GazetteRef: 'Gaz. Ext. 2025/PMP/AS/21',
                      lidarGroundElevationM: 95.0,
                    );
                    setState(() {
                      _parcels.insert(0, newParcel);
                      _selectedParcel = newParcel;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Registered parcel ${newParcel.dagNo} in ${newParcel.district.name}')),
                    );
                  },
                  child: const Text('Add Parcel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddDisputeModal() {
    final caseNoController = TextEditingController();
    final petitionerController = TextEditingController();
    final courtController = TextEditingController(text: 'Gauhati High Court (Principal Bench)');
    final groundsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Log Court Notice / Dispute Record', style: TextStyle(fontSize: 15)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: caseNoController,
                    decoration: const InputDecoration(labelText: 'Writ / Case Number (e.g. WP(C) 1240/2025)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: petitionerController,
                    decoration: const InputDecoration(labelText: 'Petitioner Full Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: courtController,
                    decoration: const InputDecoration(labelText: 'Court / Judicial Forum'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: groundsController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Prayer & Grounds of Dispute'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final newCase = DisputeCaseRecord(
                  caseId: 'CASE-${DateTime.now().millisecondsSinceEpoch % 10000}',
                  courtForum: courtController.text,
                  caseNumber: caseNoController.text.isNotEmpty ? caseNoController.text : 'WP(C) 2025/NEW',
                  parcelId: 'PARCEL-JHT-0067',
                  revenueVillage: 'Jorhat Alignment Zone',
                  petitioner: petitionerController.text.isNotEmpty ? petitionerController.text : 'Petitioner Name',
                  respondents: 'Union of India & CALA P&MP Act',
                  chainageLocation: 'Ch. 95+000 KM',
                  prayerAndGrounds: groundsController.text.isNotEmpty ? groundsController.text : 'Compensation enhancement prayer',
                  stayGrantedDate: DateTime.now(),
                  nextListingDate: DateTime.now().add(const Duration(days: 30)),
                  status: DisputeStatus.highCourtStay,
                  riskRating: 'MODERATE',
                  defenseStrategy: 'Notice received; filing parawise comments with circle officer.',
                  stateCounsel: 'Government Advocate, Gauhati High Court',
                );
                setState(() {
                  _disputeCases.insert(0, newCase);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logged case ${newCase.caseNumber}')),
                );
              },
              child: const Text('Log Dispute'),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} Lakh';
    } else {
      return amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
  }
}

// ============================================================================
// CUSTOM PAINTER: 18M ROU CORRIDOR CROSS-SECTION & GROUND PROFILE
// ============================================================================

class _RouCorridorCrossSectionPainter extends CustomPainter {
  final double chainageKm;

  _RouCorridorCrossSectionPainter({required this.chainageKm});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Centerline is at X = width / 2 (Offset 0.0m)
    final centerX = width / 2.0;
    final groundY = height * 0.42;

    // Scale: 18m corridor maps to roughly 80% of canvas width
    final corridorPixelWidth = width * 0.82;
    final pixelsPerMeter = corridorPixelWidth / 18.0;

    final leftRouX = centerX - (9.0 * pixelsPerMeter);
    final rightRouX = centerX + (9.0 * pixelsPerMeter);

    // 1. Draw Sky/Subsurface background
    final subsurfacePaint = Paint()..color = const Color(0xFF131D38);
    canvas.drawRect(Rect.fromLTRB(0, groundY, width, height), subsurfacePaint);

    // 2. Draw 18m RoU Shaded Strip
    final rouStripPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(leftRouX, 0, rightRouX, height), rouStripPaint);

    // 3. Draw Working Side & Spoil Bank Zones
    // Spoil Bank: Left -9m to -4.5m
    final spoilBankX = centerX - (4.5 * pixelsPerMeter);
    final spoilPaint = Paint()..color = const Color(0xFF8D6E63).withValues(alpha: 0.15);
    canvas.drawRect(Rect.fromLTRB(leftRouX, groundY - 24, spoilBankX, groundY), spoilPaint);

    // Working Side: Right 0 to +9m
    final workingPaint = Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.08);
    canvas.drawRect(Rect.fromLTRB(centerX, 0, rightRouX, groundY), workingPaint);

    // 4. Draw Pipeline Trench (Center -1.25m to +1.25m, depth 2.2m)
    final trenchLeftX = centerX - (1.25 * pixelsPerMeter);
    final trenchRightX = centerX + (1.25 * pixelsPerMeter);
    final trenchBottomY = groundY + (2.4 * pixelsPerMeter);

    final trenchPaint = Paint()..color = const Color(0xFF0A1224);
    final trenchPath = Path()
      ..moveTo(trenchLeftX, groundY)
      ..lineTo(trenchLeftX, trenchBottomY)
      ..lineTo(trenchRightX, trenchBottomY)
      ..lineTo(trenchRightX, groundY)
      ..close();
    canvas.drawPath(trenchPath, trenchPaint);

    final trenchBorderPaint = Paint()
      ..color = const Color(0xFFFFB95F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(trenchPath, trenchBorderPaint);

    // 5. Draw 18" Pipeline in Trench
    final pipeDiameterPx = 0.457 * pixelsPerMeter; // 18 inches = 457 mm
    final pipeCenterY = trenchBottomY - (pipeDiameterPx / 2.0) - 4;
    final pipePaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawCircle(Offset(centerX, pipeCenterY), pipeDiameterPx / 2.0, pipePaint);

    final pipeInnerPaint = Paint()..color = const Color(0xFF0F1E3D);
    canvas.drawCircle(Offset(centerX, pipeCenterY), (pipeDiameterPx / 2.0) - 2.5, pipeInnerPaint);

    // 6. Draw Ground Surface Line with subtle undulating LiDAR profile
    final groundPaint = Paint()
      ..color = const Color(0xFF4EDEA3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final groundPath = Path();
    groundPath.moveTo(0, groundY);
    for (double x = 0; x <= width; x += 15) {
      final yOffset = 3.0 * (x / 80.0 % 2 == 0 ? 1 : -1);
      groundPath.lineTo(x, groundY + yOffset);
    }
    canvas.drawPath(groundPath, groundPaint);

    // 7. Draw Statutory 18m Boundary Pegs (Red Dashed Lines)
    final pegLinePaint = Paint()
      ..color = const Color(0xFFF43F5E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _drawDashedLine(canvas, Offset(leftRouX, 15), Offset(leftRouX, height - 10), pegLinePaint);
    _drawDashedLine(canvas, Offset(rightRouX, 15), Offset(rightRouX, height - 10), pegLinePaint);

    // Centerline (Cyan Dashed Line)
    final clPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    _drawDashedLine(canvas, Offset(centerX, 20), Offset(centerX, height - 10), clPaint);

    // 8. Text Annotations
    _drawText(canvas, 'Left RoU (-9.0m)', Offset(leftRouX - 40, 2), const Color(0xFFF43F5E), 10);
    _drawText(canvas, 'Right RoU (+9.0m)', Offset(rightRouX - 45, 2), const Color(0xFFF43F5E), 10);
    _drawText(canvas, '18" Pipeline CL (0.0m)', Offset(centerX - 48, 18), const Color(0xFF38BDF8), 10);
    _drawText(canvas, 'Working Strip (11m)', Offset(centerX + 35, groundY - 18), const Color(0xFF38BDF8), 10);
    _drawText(canvas, 'Spoil Strip (4.5m)', Offset(leftRouX + 15, groundY - 18), const Color(0xFF8D6E63), 10);
    _drawText(canvas, 'DOC: 2.0m', Offset(centerX + 12, pipeCenterY - 14), const Color(0xFFFFB95F), 9);
    _drawText(canvas, '18.0m STATUTORY ROU CORRIDOR WIDTH', Offset(centerX - 95, height - 16), AppTheme.textPrimary, 10, isBold: true);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double currentY = start.dy;
    while (currentY < end.dy) {
      canvas.drawLine(
        Offset(start.dx, currentY),
        Offset(start.dx, currentY + dashHeight),
        paint,
      );
      currentY += dashHeight + dashSpace;
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize, {bool isBold = false}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _RouCorridorCrossSectionPainter oldDelegate) {
    return oldDelegate.chainageKm != chainageKm;
  }
}
