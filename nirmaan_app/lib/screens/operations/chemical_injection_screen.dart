import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// ENUMS & DOMAIN MODELS
// ============================================================================

enum DosingSkidId {
  sk01Duliajan,
  sk02Moran,
  sk03Jorhat,
}

enum ChemicalCategory {
  corrosionInhibitor,
  demulsifier,
  h2sScavenger,
  biocide,
}

enum DosingMode {
  continuous,
  pulseBatch,
  shockSlug,
}

class DosingSkidConfig {
  final DosingSkidId id;
  final String tag;
  final String name;
  final String facilityName;
  final double chainageKp;
  final int pipelineDiaInch;
  final double designPressureBar;
  final double operatingPressureBar;
  final double gasFlowMmscmd;
  final double waterCutBblMmscf;
  final double h2sConcentrationPpmv;
  final double co2MolPct;
  final String pipelineGrade;
  final String gpsCoords;
  final String solarSystemDesc;

  const DosingSkidConfig({
    required this.id,
    required this.tag,
    required this.name,
    required this.facilityName,
    required this.chainageKp,
    required this.pipelineDiaInch,
    required this.designPressureBar,
    required this.operatingPressureBar,
    required this.gasFlowMmscmd,
    required this.waterCutBblMmscf,
    required this.h2sConcentrationPpmv,
    required this.co2MolPct,
    required this.pipelineGrade,
    required this.gpsCoords,
    required this.solarSystemDesc,
  });
}

class ChemicalProduct {
  final String id;
  final ChemicalCategory category;
  final String tradeName;
  final String chemicalName;
  final String supplier;
  final String batchNumber;
  final double targetPpm;
  final double minPpm;
  final double maxPpm;
  final double specificGravity;
  final double viscosityCst;
  final DosingMode dosingMode;
  final bool naceCompliant;
  final String oisdClause;
  final String functionDescription;
  final String msdsHazardClassification;
  final double tankCapacityLiters;
  final double currentStockLiters;
  final DateTime expiryDate;

  const ChemicalProduct({
    required this.id,
    required this.category,
    required this.tradeName,
    required this.chemicalName,
    required this.supplier,
    required this.batchNumber,
    required this.targetPpm,
    required this.minPpm,
    required this.maxPpm,
    required this.specificGravity,
    required this.viscosityCst,
    required this.dosingMode,
    required this.naceCompliant,
    required this.oisdClause,
    required this.functionDescription,
    required this.msdsHazardClassification,
    required this.tankCapacityLiters,
    required this.currentStockLiters,
    required this.expiryDate,
  });

  double get stockPercentage => (currentStockLiters / tankCapacityLiters) * 100.0;
}

class WeightLossCouponRecord {
  final String couponSerial;
  final String skidTag;
  final String locationDescription;
  final String clockOrientation;
  final String steelGrade;
  final double initialWeightG;
  final int exposedDays;
  final int targetExposureDays;
  final DateTime installDate;
  final DateTime scheduledRetrievalDate;
  final String retrievalTool;
  final String status;
  final double? measuredMpy;
  final double? pittingDepthMm;
  final String? pittingClassification;
  final String? labCertNumber;

  const WeightLossCouponRecord({
    required this.couponSerial,
    required this.skidTag,
    required this.locationDescription,
    required this.clockOrientation,
    required this.steelGrade,
    required this.initialWeightG,
    required this.exposedDays,
    required this.targetExposureDays,
    required this.installDate,
    required this.scheduledRetrievalDate,
    required this.retrievalTool,
    required this.status,
    this.measuredMpy,
    this.pittingDepthMm,
    this.pittingClassification,
    this.labCertNumber,
  });

  double get exposureProgress =>
      (exposedDays / targetExposureDays).clamp(0.0, 1.0);
  int get daysRemaining =>
      math.max(0, targetExposureDays - exposedDays);
}

class ComplianceAuditItem {
  final String code;
  final String standard;
  final String requirement;
  final String measuredValue;
  final String limitValue;
  final bool isCompliant;
  final DateTime auditDate;

  const ComplianceAuditItem({
    required this.code,
    required this.standard,
    required this.requirement,
    required this.measuredValue,
    required this.limitValue,
    required this.isCompliant,
    required this.auditDate,
  });
}

// ============================================================================
// MAIN WIDGET
// ============================================================================

class ChemicalInjectionScreen extends StatefulWidget {
  const ChemicalInjectionScreen({super.key});

  @override
  State<ChemicalInjectionScreen> createState() => _ChemicalInjectionScreenState();
}

class _ChemicalInjectionScreenState extends State<ChemicalInjectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _telemetryTimer;

  // Selected Skid
  DosingSkidId _selectedSkid = DosingSkidId.sk01Duliajan;

  // Skid State Map for Interactive Modulations
  // SK-01 State
  double _sk01StrokeSpeed = 44.0; // spm
  double _sk01StrokeLength = 65.0; // %
  bool _sk01PumpAIsDuty = true;
  bool _sk01PumpRunning = true;
  bool _sk01AutoSwitchover = true;
  ChemicalCategory _sk01SelectedChemical = ChemicalCategory.corrosionInhibitor;

  // SK-02 State
  double _sk02StrokeSpeed = 38.0;
  double _sk02StrokeLength = 58.0;
  bool _sk02PumpAIsDuty = true;
  bool _sk02PumpRunning = true;
  bool _sk02AutoSwitchover = true;
  ChemicalCategory _sk02SelectedChemical = ChemicalCategory.corrosionInhibitor;

  // SK-03 State
  double _sk03StrokeSpeed = 26.0;
  double _sk03StrokeLength = 48.0;
  bool _sk03PumpAIsDuty = false; // Pump B is duty
  bool _sk03PumpRunning = true;
  bool _sk03AutoSwitchover = true;
  ChemicalCategory _sk03SelectedChemical = ChemicalCategory.corrosionInhibitor;

  // Biocide Shock Dosing active state
  bool _isShockDosingActive = false;
  int _shockDoseRemainingSec = 0;
  Timer? _shockDoseTimer;

  // Telemetry fluctuation counter
  int _tickCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _telemetryTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _tickCount++;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _telemetryTimer?.cancel();
    _shockDoseTimer?.cancel();
    super.dispose();
  }

  // ============================================================================
  // STATIC CONFIGURATIONS & MASTER DATA
  // ============================================================================

  static const Map<DosingSkidId, DosingSkidConfig> _skidConfigs = {
    DosingSkidId.sk01Duliajan: DosingSkidConfig(
      id: DosingSkidId.sk01Duliajan,
      tag: 'SK-01',
      name: 'Duliajan CPF',
      facilityName: 'Duliajan Central Processing Facility (Skid Bay 01)',
      chainageKp: 0.0,
      pipelineDiaInch: 24,
      designPressureBar: 98.0,
      operatingPressureBar: 68.5,
      gasFlowMmscmd: 4.85,
      waterCutBblMmscf: 18.5,
      h2sConcentrationPpmv: 18.4,
      co2MolPct: 2.35,
      pipelineGrade: 'API 5L X65 PSL-2 (HIC/SSCC Res.)',
      gpsCoords: '27.3542° N, 95.3188° E',
      solarSystemDesc: '2.4 kWp Solar Array + 24V 400Ah Gel Battery Bank',
    ),
    DosingSkidId.sk02Moran: DosingSkidConfig(
      id: DosingSkidId.sk02Moran,
      tag: 'SK-02',
      name: 'Moran SV-03',
      facilityName: 'Moran Sectionalizing Valve Station (SV-03)',
      chainageKp: 48.2,
      pipelineDiaInch: 20,
      designPressureBar: 98.0,
      operatingPressureBar: 54.2,
      gasFlowMmscmd: 2.95,
      waterCutBblMmscf: 12.0,
      h2sConcentrationPpmv: 4.2,
      co2MolPct: 1.82,
      pipelineGrade: 'API 5L X65',
      gpsCoords: '27.1894° N, 94.9215° E',
      solarSystemDesc: '1.8 kWp Standalone Solar PV + 24V 600Ah Battery',
    ),
    DosingSkidId.sk03Jorhat: DosingSkidConfig(
      id: DosingSkidId.sk03Jorhat,
      tag: 'SK-03',
      name: 'Jorhat SV-05',
      facilityName: 'Jorhat Sectionalizing Valve Station (SV-05 Offtake)',
      chainageKp: 112.6,
      pipelineDiaInch: 18,
      designPressureBar: 80.0,
      operatingPressureBar: 42.0,
      gasFlowMmscmd: 1.62,
      waterCutBblMmscf: 9.4,
      h2sConcentrationPpmv: 8.6,
      co2MolPct: 1.15,
      pipelineGrade: 'API 5L X60',
      gpsCoords: '26.7509° N, 94.2037° E',
      solarSystemDesc: '1.8 kWp Standalone Solar PV + LiFePO4 300Ah',
    ),
  };

  static final List<ChemicalProduct> _chemicalCatalog = [
    ChemicalProduct(
      id: 'CHEM-01',
      category: ChemicalCategory.corrosionInhibitor,
      tradeName: 'CORR-SHIELD 8420-NACE',
      chemicalName: 'Film-forming amine / Imidazoline phosphate ester complex',
      supplier: 'ChampionX / Baker Hughes O&G',
      batchNumber: 'BH-CS8420-2026-08',
      targetPpm: 20.0,
      minPpm: 15.0,
      maxPpm: 35.0,
      specificGravity: 0.945,
      viscosityCst: 18.2,
      dosingMode: DosingMode.continuous,
      naceCompliant: true,
      oisdClause: 'OISD-141 Cl 8.2.1 (Internal Corrosion Inhibitor)',
      functionDescription:
          'Forms persistent hydrophobic monomolecular protective film on steel wall, neutralizing CO2/carbonic acid electrochemical attacks.',
      msdsHazardClassification: 'Class 3 Flammable Liquid (Flash Pt 42°C), Category 1B Skin Corr',
      tankCapacityLiters: 2500,
      currentStockLiters: 1845,
      expiryDate: DateTime(2027, 8, 15),
    ),
    ChemicalProduct(
      id: 'CHEM-02',
      category: ChemicalCategory.demulsifier,
      tradeName: 'DEMUL-BREAK 610-HP',
      chemicalName: 'Polyoxyethylene alkylphenol formaldehyde copolymer blend',
      supplier: 'Dorf Ketal Chemicals Ltd',
      batchNumber: 'DK-DB610-2026-06',
      targetPpm: 12.0,
      minPpm: 8.0,
      maxPpm: 20.0,
      specificGravity: 0.982,
      viscosityCst: 24.5,
      dosingMode: DosingMode.continuous,
      naceCompliant: true,
      oisdClause: 'OISD-141 Cl 8.2.3 (Free Water Separation)',
      functionDescription:
          'Rapidly destabilizes hydrocarbon-water emulsions, promoting water fallout at low elevation sags to prevent stagnant electrolyte corrosion.',
      msdsHazardClassification: 'Class 3 Combustible, Eye Irritant Cat 2A',
      tankCapacityLiters: 1500,
      currentStockLiters: 1120,
      expiryDate: DateTime(2027, 6, 20),
    ),
    ChemicalProduct(
      id: 'CHEM-03',
      category: ChemicalCategory.h2sScavenger,
      tradeName: 'SCAV-TRON 500-TRI',
      chemicalName: 'Hexahydro-1,3,5-triethyl-s-triazine (40% active blend)',
      supplier: 'Schlumberger Production Chem',
      batchNumber: 'SLB-SC500-2026-09',
      targetPpm: 35.0,
      minPpm: 25.0,
      maxPpm: 60.0,
      specificGravity: 1.052,
      viscosityCst: 8.4,
      dosingMode: DosingMode.continuous,
      naceCompliant: true,
      oisdClause: 'OISD-141 Cl 8.2.4 & NACE MR0175 (Sour Service SSC)',
      functionDescription:
          'Irreversibly scavenges H2S into water-soluble dithiazine byproducts, preventing hydrogen embrittlement and sulfide stress corrosion cracking.',
      msdsHazardClassification: 'Class 8 Corrosive Substance, UN 3267',
      tankCapacityLiters: 3000,
      currentStockLiters: 2280,
      expiryDate: DateTime(2027, 9, 10),
    ),
    ChemicalProduct(
      id: 'CHEM-04',
      category: ChemicalCategory.biocide,
      tradeName: 'BIO-BAN 360-DUAL',
      chemicalName: 'Glutaraldehyde (25%) + THPS (50%) synergistic biocide',
      supplier: 'Dow Microbial Solutions / Lanxess',
      batchNumber: 'LX-BB360-2026-07',
      targetPpm: 250.0,
      minPpm: 200.0,
      maxPpm: 400.0,
      specificGravity: 1.120,
      viscosityCst: 12.8,
      dosingMode: DosingMode.shockSlug,
      naceCompliant: true,
      oisdClause: 'OISD-141 Cl 8.2.5 (Microbiologically Influenced Corrosion - MIC)',
      functionDescription:
          'Shock-slug biocide eradicating sessile Sulfate Reducing Bacteria (SRB) and Acid Producing Bacteria (APB) beneath sludge layers.',
      msdsHazardClassification: 'Class 6.1 Toxic, Aquatic Chronic 1',
      tankCapacityLiters: 1000,
      currentStockLiters: 740,
      expiryDate: DateTime(2027, 7, 30),
    ),
  ];

  static final List<WeightLossCouponRecord> _coupons = [
    WeightLossCouponRecord(
      couponSerial: 'WLC-SK01-2026-A1',
      skidTag: 'SK-01',
      locationDescription: 'Duliajan CPF Manifold Invert (KP 0.25)',
      clockOrientation: '6 o\'clock (Bottom Invert)',
      steelGrade: 'API 5L X65 Normalized',
      initialWeightG: 42.8450,
      exposedDays: 68,
      targetExposureDays: 90,
      installDate: DateTime(2026, 7, 24),
      scheduledRetrievalDate: DateTime(2026, 10, 22),
      retrievalTool: 'Cosasco 2" HP Hydraulic Retriever (6000 psi)',
      status: 'In-Service (Active Exposure)',
      measuredMpy: null,
      pittingDepthMm: null,
      pittingClassification: null,
      labCertNumber: null,
    ),
    WeightLossCouponRecord(
      couponSerial: 'WLC-SK01-2026-B1',
      skidTag: 'SK-01',
      locationDescription: 'Duliajan CPF Crown Vapour Zone (KP 0.25)',
      clockOrientation: '12 o\'clock (Crown)',
      steelGrade: 'API 5L X65 Normalized',
      initialWeightG: 43.1200,
      exposedDays: 68,
      targetExposureDays: 90,
      installDate: DateTime(2026, 7, 24),
      scheduledRetrievalDate: DateTime(2026, 10, 22),
      retrievalTool: 'Cosasco 2" HP Hydraulic Retriever (6000 psi)',
      status: 'In-Service (Active Exposure)',
      measuredMpy: null,
      pittingDepthMm: null,
      pittingClassification: null,
      labCertNumber: null,
    ),
    WeightLossCouponRecord(
      couponSerial: 'WLC-SK02-2026-A2',
      skidTag: 'SK-02',
      locationDescription: 'Moran SV-03 Station Header Invert (KP 48.2)',
      clockOrientation: '6 o\'clock (Bottom Invert)',
      steelGrade: 'API 5L X65',
      initialWeightG: 42.5120,
      exposedDays: 88,
      targetExposureDays: 90,
      installDate: DateTime(2026, 7, 4),
      scheduledRetrievalDate: DateTime(2026, 10, 2),
      retrievalTool: 'Cosasco 2" HP Hydraulic Retriever (6000 psi)',
      status: 'Due for Retrieval',
      measuredMpy: null,
      pittingDepthMm: null,
      pittingClassification: null,
      labCertNumber: null,
    ),
    WeightLossCouponRecord(
      couponSerial: 'WLC-SK01-2026-Q2-RET',
      skidTag: 'SK-01',
      locationDescription: 'Duliajan CPF Invert Historical (KP 0.25)',
      clockOrientation: '6 o\'clock (Bottom Invert)',
      steelGrade: 'API 5L X65 Normalized',
      initialWeightG: 42.9150,
      exposedDays: 92,
      targetExposureDays: 90,
      installDate: DateTime(2026, 4, 20),
      scheduledRetrievalDate: DateTime(2026, 7, 21),
      retrievalTool: 'Cosasco 2" HP Hydraulic Retriever (6000 psi)',
      status: 'Retrieved & Certified',
      measuredMpy: 0.38,
      pittingDepthMm: 0.04,
      pittingClassification: 'ASTM G46 Isolated Low Pitting',
      labCertNumber: 'OIL/LAB/CORR/2026/0719',
    ),
    WeightLossCouponRecord(
      couponSerial: 'WLC-SK03-2026-Q2-RET',
      skidTag: 'SK-03',
      locationDescription: 'Jorhat SV-05 Spur Invert (KP 112.6)',
      clockOrientation: '6 o\'clock (Bottom Invert)',
      steelGrade: 'API 5L X60',
      initialWeightG: 41.8740,
      exposedDays: 90,
      targetExposureDays: 90,
      installDate: DateTime(2026, 4, 15),
      scheduledRetrievalDate: DateTime(2026, 7, 14),
      retrievalTool: 'Cosasco 2" HP Hydraulic Retriever (6000 psi)',
      status: 'Retrieved & Certified',
      measuredMpy: 0.29,
      pittingDepthMm: 0.02,
      pittingClassification: 'ASTM G46 Uniform Etch No Pits',
      labCertNumber: 'OIL/LAB/CORR/2026/0712',
    ),
  ];

  static final List<ComplianceAuditItem> _complianceItems = [
    ComplianceAuditItem(
      code: 'NACE-01',
      standard: 'NACE MR0175 / ISO 15156-2',
      requirement: 'Sulfide Stress Cracking (SSC) & H2S Partial Pressure control',
      measuredValue: 'H2S pp: 0.012 bar, Inhibitor: 20 ppm active',
      limitValue: 'pp < 0.05 bar or continuous film inhibitor',
      isCompliant: true,
      auditDate: DateTime(2026, 9, 28),
    ),
    ComplianceAuditItem(
      code: 'OISD-01',
      standard: 'OISD-141 Clause 8.2.1',
      requirement: 'Internal corrosion rate target through continuous inhibition',
      measuredValue: 'ER probe rate: 0.42 mpy (Trunkline)',
      limitValue: 'Target < 1.0 mpy (Max 2.0 mpy)',
      isCompliant: true,
      auditDate: DateTime(2026, 9, 29),
    ),
    ComplianceAuditItem(
      code: 'OISD-02',
      standard: 'OISD-141 Clause 8.2.2',
      requirement: 'Weight loss coupon retrieval cycle & inspection interval',
      measuredValue: 'Quarterly retrieval frequency (88/90 days)',
      limitValue: 'Mandatory 90-day exposure intervals',
      isCompliant: true,
      auditDate: DateTime(2026, 9, 25),
    ),
    ComplianceAuditItem(
      code: 'API-675',
      standard: 'API Standard 675',
      requirement: 'Dual diaphragm positive displacement pump flow accuracy & leak detection',
      measuredValue: 'Steady state linearity ±0.8%, optical leak switch OK',
      limitValue: 'Linearity ±1.0%, zero toxic release',
      isCompliant: true,
      auditDate: DateTime(2026, 9, 15),
    ),
    ComplianceAuditItem(
      code: 'PNGRB-01',
      standard: 'PNGRB T4S Reg 2020',
      requirement: 'Solar telemetry autonomy & minimum 30 days chemical storage autonomy',
      measuredValue: 'Battery SOC: 88.5%, Chemical autonomy: 47.8 days',
      limitValue: 'Min 72h solar autonomy, min 30d chemical storage',
      isCompliant: true,
      auditDate: DateTime(2026, 9, 29),
    ),
  ];

  // ============================================================================
  // TELEMETRY STATE GETTERS & CALCULATIONS
  // ============================================================================

  double get _currentStrokeSpeed {
    switch (_selectedSkid) {
      case DosingSkidId.sk01Duliajan:
        return _sk01StrokeSpeed;
      case DosingSkidId.sk02Moran:
        return _sk02StrokeSpeed;
      case DosingSkidId.sk03Jorhat:
        return _sk03StrokeSpeed;
    }
  }

  double get _currentStrokeLength {
    switch (_selectedSkid) {
      case DosingSkidId.sk01Duliajan:
        return _sk01StrokeLength;
      case DosingSkidId.sk02Moran:
        return _sk02StrokeLength;
      case DosingSkidId.sk03Jorhat:
        return _sk03StrokeLength;
    }
  }

  bool get _currentPumpIsDutyA {
    switch (_selectedSkid) {
      case DosingSkidId.sk01Duliajan:
        return _sk01PumpAIsDuty;
      case DosingSkidId.sk02Moran:
        return _sk02PumpAIsDuty;
      case DosingSkidId.sk03Jorhat:
        return _sk03PumpAIsDuty;
    }
  }

  bool get _currentPumpRunning {
    switch (_selectedSkid) {
      case DosingSkidId.sk01Duliajan:
        return _sk01PumpRunning;
      case DosingSkidId.sk02Moran:
        return _sk02PumpRunning;
      case DosingSkidId.sk03Jorhat:
        return _sk03PumpRunning;
    }
  }

  bool get _currentAutoSwitchover {
    switch (_selectedSkid) {
      case DosingSkidId.sk01Duliajan:
        return _sk01AutoSwitchover;
      case DosingSkidId.sk02Moran:
        return _sk02AutoSwitchover;
      case DosingSkidId.sk03Jorhat:
        return _sk03AutoSwitchover;
    }
  }

  ChemicalCategory get _currentSelectedChemical {
    switch (_selectedSkid) {
      case DosingSkidId.sk01Duliajan:
        return _sk01SelectedChemical;
      case DosingSkidId.sk02Moran:
        return _sk02SelectedChemical;
      case DosingSkidId.sk03Jorhat:
        return _sk03SelectedChemical;
    }
  }

  ChemicalProduct get _activeChemicalProduct {
    return _chemicalCatalog.firstWhere(
      (c) => c.category == _currentSelectedChemical,
      orElse: () => _chemicalCatalog.first,
    );
  }

  // Dual diaphragm pump nominal displacement: 0.45 mL per stroke at 100% stroke length
  static const double _kNominalDisplacementMlPerStroke = 0.45;

  /// Flow rate in Liters Per Hour: (SPM * StrokeLength% * 0.45 mL * 60) / 1000
  double get _flowRateLph {
    if (!_currentPumpRunning) return 0.0;
    final strokeMultiplier = _currentStrokeLength / 100.0;
    final mlPerMin = _currentStrokeSpeed * _kNominalDisplacementMlPerStroke * strokeMultiplier;
    return (mlPerMin * 60.0) / 1000.0;
  }

  /// Flow rate in Liters Per Day
  double get _flowRateLpd => _flowRateLph * 24.0;

  /// Days of Autonomy remaining in current chemical storage tank
  double get _daysOfAutonomy {
    final stock = _activeChemicalProduct.currentStockLiters;
    final dailyRate = _flowRateLpd;
    if (dailyRate <= 0.01) return 999.0;
    return stock / dailyRate;
  }

  /// Real-time Corrosion Rate (mpy) based on current skid & inhibitor injection
  double get _measuredCorrosionRateMpy {
    final baseMpy = switch (_selectedSkid) {
      DosingSkidId.sk01Duliajan => 0.42,
      DosingSkidId.sk02Moran => 0.68,
      DosingSkidId.sk03Jorhat => 0.31,
    };
    // Micro flutter to simulate live telemetry
    final flutter = math.sin(_tickCount * 0.8) * 0.03;
    // If pump not running, corrosion climbs
    final uninhibitedPenalty = !_currentPumpRunning ? 1.45 : 0.0;
    // Target modulation: higher stroke length decreases corrosion rate
    final factor = (70.0 / math.max(10.0, _currentStrokeLength)) * (45.0 / math.max(10.0, _currentStrokeSpeed));
    final calculated = (baseMpy * (0.6 + 0.4 * factor)) + flutter + uninhibitedPenalty;
    return math.max(0.10, double.parse(calculated.toStringAsFixed(2)));
  }

  /// Cumulative Metal Loss (mils) on ER probe
  double get _cumulativeMetalLossMils {
    switch (_selectedSkid) {
      case DosingSkidId.sk01Duliajan:
        return 1.84 + (_tickCount * 0.0005);
      case DosingSkidId.sk02Moran:
        return 2.45 + (_tickCount * 0.0006);
      case DosingSkidId.sk03Jorhat:
        return 1.12 + (_tickCount * 0.0003);
    }
  }

  /// Solar PV telemetry values with slight solar fluctuations
  double get _solarPvWatts {
    final base = switch (_selectedSkid) {
      DosingSkidId.sk01Duliajan => 540.0,
      DosingSkidId.sk02Moran => 480.0,
      DosingSkidId.sk03Jorhat => 450.0,
    };
    final fluctuation = math.sin(_tickCount * 0.4) * 25.0;
    return base + fluctuation;
  }

  double get _batterySocPct {
    final base = switch (_selectedSkid) {
      DosingSkidId.sk01Duliajan => 92.4,
      DosingSkidId.sk02Moran => 88.5,
      DosingSkidId.sk03Jorhat => 90.1,
    };
    return (base + (math.sin(_tickCount * 0.2) * 1.5)).clamp(50.0, 100.0);
  }

  // ============================================================================
  // MUTATION HANDLERS
  // ============================================================================

  void _updateStrokeSpeed(double newSpeed) {
    final clamped = newSpeed.clamp(15.0, 120.0);
    setState(() {
      switch (_selectedSkid) {
        case DosingSkidId.sk01Duliajan:
          _sk01StrokeSpeed = clamped;
          break;
        case DosingSkidId.sk02Moran:
          _sk02StrokeSpeed = clamped;
          break;
        case DosingSkidId.sk03Jorhat:
          _sk03StrokeSpeed = clamped;
          break;
      }
    });
  }

  void _updateStrokeLength(double newLength) {
    final clamped = newLength.clamp(0.0, 100.0);
    setState(() {
      switch (_selectedSkid) {
        case DosingSkidId.sk01Duliajan:
          _sk01StrokeLength = clamped;
          break;
        case DosingSkidId.sk02Moran:
          _sk02StrokeLength = clamped;
          break;
        case DosingSkidId.sk03Jorhat:
          _sk03StrokeLength = clamped;
          break;
      }
    });
  }

  void _togglePumpDuty() {
    setState(() {
      switch (_selectedSkid) {
        case DosingSkidId.sk01Duliajan:
          _sk01PumpAIsDuty = !_sk01PumpAIsDuty;
          break;
        case DosingSkidId.sk02Moran:
          _sk02PumpAIsDuty = !_sk02PumpAIsDuty;
          break;
        case DosingSkidId.sk03Jorhat:
          _sk03PumpAIsDuty = !_sk03PumpAIsDuty;
          break;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceCard,
        content: Text(
          'Pump Duty Switchover Executed: ${_currentPumpIsDutyA ? "Pump A (Duty) / Pump B (Standby)" : "Pump B (Duty) / Pump A (Standby)"}',
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _togglePumpRunning() {
    setState(() {
      switch (_selectedSkid) {
        case DosingSkidId.sk01Duliajan:
          _sk01PumpRunning = !_sk01PumpRunning;
          break;
        case DosingSkidId.sk02Moran:
          _sk02PumpRunning = !_sk02PumpRunning;
          break;
        case DosingSkidId.sk03Jorhat:
          _sk03PumpRunning = !_sk03PumpRunning;
          break;
      }
    });
  }

  void _toggleAutoSwitchover() {
    setState(() {
      switch (_selectedSkid) {
        case DosingSkidId.sk01Duliajan:
          _sk01AutoSwitchover = !_sk01AutoSwitchover;
          break;
        case DosingSkidId.sk02Moran:
          _sk02AutoSwitchover = !_sk02AutoSwitchover;
          break;
        case DosingSkidId.sk03Jorhat:
          _sk03AutoSwitchover = !_sk03AutoSwitchover;
          break;
      }
    });
  }

  void _changeSelectedChemical(ChemicalCategory category) {
    setState(() {
      switch (_selectedSkid) {
        case DosingSkidId.sk01Duliajan:
          _sk01SelectedChemical = category;
          break;
        case DosingSkidId.sk02Moran:
          _sk02SelectedChemical = category;
          break;
        case DosingSkidId.sk03Jorhat:
          _sk03SelectedChemical = category;
          break;
      }
    });
  }

  void _startShockDoseSequence() {
    setState(() {
      _isShockDosingActive = true;
      _shockDoseRemainingSec = 14400; // 4 hours in seconds
    });
    _shockDoseTimer?.cancel();
    _shockDoseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_shockDoseRemainingSec > 0) {
          _shockDoseRemainingSec -= 60; // fast tick for simulation
        } else {
          _isShockDosingActive = false;
          timer.cancel();
        }
      });
    });
  }

  // ============================================================================
  // BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final skidConfig = _skidConfigs[_selectedSkid]!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chemical Injection & Dosing Skid',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'NACE MR0175 / OISD-141 • ${skidConfig.tag} ONLINE',
                  style: const TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Dosage Rate Calculator',
            icon: const Icon(Icons.calculate_outlined, color: AppTheme.primaryLight),
            onPressed: () => _showDosingCalculatorModal(context),
          ),
          IconButton(
            tooltip: 'Refill Chemical Tank',
            icon: const Icon(Icons.local_shipping_outlined, color: AppTheme.secondary),
            onPressed: () => _showRefillTankDialog(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.primaryLight,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(text: 'Pump Telemetry'),
                Tab(text: 'Chemicals'),
                Tab(text: 'ER Probes'),
                Tab(text: 'Coupon Schedule'),
                Tab(text: 'Compliance Audit'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Dosing Skid Switcher Bar
          _buildSkidSelectorBar(),

          // Key KPI Metrics Bar
          _buildTopKpiSummaryBar(),

          // Active Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPumpTelemetryTab(),
                _buildChemicalCatalogTab(),
                _buildErProbesTab(),
                _buildCouponScheduleTab(),
                _buildComplianceAuditTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SKID SELECTOR BAR
  // ============================================================================

  Widget _buildSkidSelectorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.oil_barrel_rounded, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          const Text(
            'DOSING SKID:',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: DosingSkidId.values.map((skidId) {
                  final cfg = _skidConfigs[skidId]!;
                  final isSelected = _selectedSkid == skidId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cfg.tag,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${cfg.name})',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white70 : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppTheme.surfaceCard,
                      selectedColor: AppTheme.primary,
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedSkid = skidId;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TOP KPI SUMMARY BAR
  // ============================================================================

  Widget _buildTopKpiSummaryBar() {
    final mpy = _measuredCorrosionRateMpy;
    final isCompliant = mpy < 1.0;
    final daysAutonomy = _daysOfAutonomy;
    final isAutonomyLow = daysAutonomy < 15.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          // Corrosion Rate KPI
          Expanded(
            child: _buildMetricTile(
              label: 'CORROSION RATE',
              value: '${mpy.toStringAsFixed(2)} mpy',
              subtext: isCompliant ? 'Target < 1.0 mpy' : 'HIGH RATE',
              accentColor: isCompliant ? AppTheme.tertiary : AppTheme.error,
              icon: Icons.shield_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.border),

          // Dosing Output KPI
          Expanded(
            child: _buildMetricTile(
              label: 'DOSING FLOW',
              value: '${_flowRateLpd.toStringAsFixed(1)} L/d',
              subtext: '${_flowRateLph.toStringAsFixed(2)} L/hr',
              accentColor: AppTheme.primaryLight,
              icon: Icons.water_drop_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.border),

          // Tank Autonomy KPI
          Expanded(
            child: _buildMetricTile(
              label: 'TANK AUTONOMY',
              value: '${daysAutonomy.toStringAsFixed(1)} Days',
              subtext: '${_activeChemicalProduct.currentStockLiters.toInt()} L Remaining',
              accentColor: isAutonomyLow ? AppTheme.secondary : AppTheme.tertiary,
              icon: Icons.hourglass_top_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.border),

          // Solar Autonomy KPI
          Expanded(
            child: _buildMetricTile(
              label: 'SOLAR BATTERY',
              value: '${_batterySocPct.toStringAsFixed(1)}%',
              subtext: '${_solarPvWatts.toInt()} W PV Array',
              accentColor: AppTheme.secondary,
              icon: Icons.solar_power_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required Color accentColor,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: PUMP TELEMETRY
  // ============================================================================

  Widget _buildPumpTelemetryTab() {
    final skid = _skidConfigs[_selectedSkid]!;
    final strokeSpeed = _currentStrokeSpeed;
    final strokeLength = _currentStrokeLength;
    final isDutyA = _currentPumpIsDutyA;
    final isRunning = _currentPumpRunning;
    final autoSwitchover = _currentAutoSwitchover;
    final injectionPressure = skid.operatingPressureBar + 9.8;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Skid Header Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skid.facilityName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Pipeline: ${skid.pipelineDiaInch}" Grade ${skid.pipelineGrade} • KP ${skid.chainageKp} • Line Pr: ${skid.operatingPressureBar} bar',
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
                        color: isRunning ? AppTheme.tertiary.withValues(alpha: 0.15) : AppTheme.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isRunning ? AppTheme.tertiary : AppTheme.error,
                        ),
                      ),
                      child: Text(
                        isRunning ? 'SYSTEM RUNNING' : 'PUMP STOPPED',
                        style: TextStyle(
                          color: isRunning ? AppTheme.tertiary : AppTheme.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSubtleTag(Icons.speed_rounded, 'Gas Flow: ${skid.gasFlowMmscmd} MMSCMD'),
                    const SizedBox(width: 8),
                    _buildSubtleTag(Icons.opacity_rounded, 'Water Cut: ${skid.waterCutBblMmscf} bbl/MMSCF'),
                    const SizedBox(width: 8),
                    _buildSubtleTag(Icons.warning_amber_rounded, 'H2S: ${skid.h2sConcentrationPpmv} ppmv'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Dual Diaphragm Positive Displacement Pump Card (API 675)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.settings_input_component_rounded,
                              color: AppTheme.primaryLight, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dual Diaphragm Metering Pump (API 675)',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Milton Roy Solar Roy Series • Positive Displacement',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: isRunning ? 'Stop Pump' : 'Start Pump',
                      icon: Icon(
                        isRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: isRunning ? AppTheme.secondary : AppTheme.tertiary,
                        size: 28,
                      ),
                      onPressed: _togglePumpRunning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Duty / Standby Switcher Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      // Pump A Status
                      Expanded(
                        child: _buildPumpHeadStatusWidget(
                          name: 'Pump Head A',
                          isDuty: isDutyA,
                          isRunning: isRunning && isDutyA,
                          quenchOk: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Switch button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceCard,
                          foregroundColor: AppTheme.primaryLight,
                          side: const BorderSide(color: AppTheme.border),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onPressed: _togglePumpDuty,
                        child: const Row(
                          children: [
                            Icon(Icons.swap_horiz_rounded, size: 16),
                            SizedBox(width: 4),
                            Text('Switch', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Pump B Status
                      Expanded(
                        child: _buildPumpHeadStatusWidget(
                          name: 'Pump Head B',
                          isDuty: !isDutyA,
                          isRunning: isRunning && !isDutyA,
                          quenchOk: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stroke Speed Slider (strokes/min)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pump Stroke Speed',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${strokeSpeed.toInt()} SPM (strokes/min)',
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textSecondary, size: 20),
                      onPressed: () => _updateStrokeSpeed(strokeSpeed - 1),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.primaryLight,
                          inactiveTrackColor: AppTheme.border,
                          thumbColor: AppTheme.primaryLight,
                          overlayColor: AppTheme.primaryLight.withValues(alpha: 0.2),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: strokeSpeed,
                          min: 15.0,
                          max: 120.0,
                          divisions: 105,
                          onChanged: _updateStrokeSpeed,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.textSecondary, size: 20),
                      onPressed: () => _updateStrokeSpeed(strokeSpeed + 1),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Stroke Length Adjustment (0 - 100%)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Stroke Length Adjustment (Servo Actuator)',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${strokeLength.toInt()}% Displacement',
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textSecondary, size: 20),
                      onPressed: () => _updateStrokeLength(strokeLength - 1),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.secondary,
                          inactiveTrackColor: AppTheme.border,
                          thumbColor: AppTheme.secondary,
                          overlayColor: AppTheme.secondary.withValues(alpha: 0.2),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: strokeLength,
                          min: 0.0,
                          max: 100.0,
                          divisions: 100,
                          onChanged: _updateStrokeLength,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.textSecondary, size: 20),
                      onPressed: () => _updateStrokeLength(strokeLength + 1),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Telemetry Readouts Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      _buildTelemetryRow(
                        'Discharge Injection Pressure',
                        '${injectionPressure.toStringAsFixed(1)} bar',
                        'Pipeline: ${skid.operatingPressureBar} bar (DP: +9.8 bar)',
                        AppTheme.tertiary,
                      ),
                      const Divider(color: AppTheme.border, height: 16),
                      _buildTelemetryRow(
                        'Volumetric Rate Delivered',
                        '${_flowRateLph.toStringAsFixed(2)} L/hr',
                        '${_flowRateLpd.toStringAsFixed(1)} L/day continuous',
                        AppTheme.primaryLight,
                      ),
                      const Divider(color: AppTheme.border, height: 16),
                      _buildTelemetryRow(
                        'Diaphragm Rupture Sensor',
                        'NORMAL (NO LEAK)',
                        'Optoelectronic dual barrier integrity',
                        AppTheme.tertiary,
                      ),
                      const Divider(color: AppTheme.border, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Auto-Switchover on Fault',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          Switch(
                            value: autoSwitchover,
                            activeTrackColor: AppTheme.primaryLight,
                            onChanged: (_) => _toggleAutoSwitchover(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Solar PV & Battery Telemetry Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                            color: AppTheme.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.solar_power_rounded,
                              color: AppTheme.secondary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Solar Power & Battery Micro-Grid',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              skid.solarSystemDesc,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'MPPT FLOAT',
                        style: TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildMicroTelemetryBox(
                        title: 'PV Generation',
                        value: '${_solarPvWatts.toInt()} W',
                        subtext: '34.2 V @ 14.1 A',
                        icon: Icons.wb_sunny_rounded,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMicroTelemetryBox(
                        title: 'Battery SOC',
                        value: '${_batterySocPct.toStringAsFixed(1)}%',
                        subtext: '25.8 V DC Bus',
                        icon: Icons.battery_charging_full_rounded,
                        color: AppTheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMicroTelemetryBox(
                        title: 'Solar Autonomy',
                        value: '72 Hours',
                        subtext: 'No-sun reserve',
                        icon: Icons.timer_rounded,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Chemical Storage Tank Level & Autonomy Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                            color: AppTheme.tertiary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.storage_rounded,
                              color: AppTheme.tertiary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Storage Tank Level: ${_activeChemicalProduct.tradeName}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'SS316 Tank with N2 Blanket (25 mbar) • Magnetostrictive Gauge',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.secondary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      icon: const Icon(Icons.local_shipping_outlined, size: 16),
                      label: const Text('Order Refill', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showRefillTankDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Visual Liquid Level Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _activeChemicalProduct.stockPercentage / 100.0,
                    minHeight: 18,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _daysOfAutonomy < 15.0 ? AppTheme.secondary : AppTheme.tertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Liquid Remaining: ${_activeChemicalProduct.currentStockLiters.toInt()} L / ${_activeChemicalProduct.tankCapacityLiters.toInt()} L (${_activeChemicalProduct.stockPercentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Autonomy: ${_daysOfAutonomy.toStringAsFixed(1)} Days',
                      style: TextStyle(
                        color: _daysOfAutonomy < 15.0 ? AppTheme.secondary : AppTheme.tertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      _buildTagWithDot('N2 Blanket: 25 mbar'),
                      _buildTagWithDot('Bund: DRY'),
                      _buildTagWithDot('Flame Arrestor: OK'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPumpHeadStatusWidget({
    required String name,
    required bool isDuty,
    required bool isRunning,
    required bool quenchOk,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDuty ? AppTheme.surfaceCard : AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDuty ? AppTheme.primaryLight : AppTheme.border,
          width: isDuty ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: isDuty ? AppTheme.primaryLight : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isDuty ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isDuty ? 'DUTY' : 'STANDBY',
                  style: TextStyle(
                    color: isDuty ? AppTheme.primaryLight : AppTheme.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isRunning ? AppTheme.tertiary : AppTheme.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isRunning ? 'Pumping Active' : 'Standby Armed',
                style: TextStyle(
                  color: isRunning ? AppTheme.tertiary : AppTheme.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(String title, String mainValue, String subValue, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subValue,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          mainValue,
          style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildMicroTelemetryBox({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
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
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtleTag(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagWithDot(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppTheme.tertiary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 2: CHEMICALS
  // ============================================================================

  Widget _buildChemicalCatalogTab() {
    final activeProd = _activeChemicalProduct;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Chemical Category Switcher
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SELECT CHEMICAL DOSING LOOP',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _chemicalCatalog.map((chem) {
                  final isSelected = chem.category == _currentSelectedChemical;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(
                      chem.tradeName,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    backgroundColor: AppTheme.surface,
                    selectedColor: AppTheme.primary,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onSelected: (selected) {
                      if (selected) {
                        _changeSelectedChemical(chem.category);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Active Chemical Detail Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeProd.tradeName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            activeProd.chemicalName,
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.tertiary),
                      ),
                      child: const Text(
                        'NACE MR0175 PASSED',
                        style: TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  activeProd.functionDescription,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Chemical Properties Table
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      _buildSpecRow('Target Dosage Rate', '${activeProd.targetPpm} PPM (continuous line mix)'),
                      const Divider(color: AppTheme.border, height: 12),
                      _buildSpecRow('Specific Gravity', '${activeProd.specificGravity} g/cm³ @ 20°C'),
                      const Divider(color: AppTheme.border, height: 12),
                      _buildSpecRow('Kinematic Viscosity', '${activeProd.viscosityCst} cSt @ 25°C'),
                      const Divider(color: AppTheme.border, height: 12),
                      _buildSpecRow('Supplier & QA Batch', '${activeProd.supplier} (Batch: ${activeProd.batchNumber})'),
                      const Divider(color: AppTheme.border, height: 12),
                      _buildSpecRow('OISD-141 Standard Mandate', activeProd.oisdClause),
                      const Divider(color: AppTheme.border, height: 12),
                      _buildSpecRow('Hazard & Safety Classification', activeProd.msdsHazardClassification),
                      const Divider(color: AppTheme.border, height: 12),
                      _buildSpecRow('Shelf Life Expiry', DateFormat('dd-MMM-yyyy').format(activeProd.expiryDate)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Shock Dosing Action Card (Special for Biocide & Batch Scavenger)
        Card(
          color: _isShockDosingActive
              ? AppTheme.secondary.withValues(alpha: 0.12)
              : AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: _isShockDosingActive ? AppTheme.secondary : AppTheme.border,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: _isShockDosingActive ? AppTheme.secondary : AppTheme.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Shock Slug Dosing (Biocide & Batch Treatment)',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (_isShockDosingActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'INJECTION IN PROGRESS',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'OISD-141 Clause 8.2.5 mandates biocide shock batch slugging (250 ppm for 4 continuous hours every fortnight) to eradicate sessile SRB bacteria biofilm in pipeline low points.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),

                if (_isShockDosingActive) ...[
                  LinearProgressIndicator(
                    value: (14400 - _shockDoseRemainingSec) / 14400.0,
                    minHeight: 8,
                    backgroundColor: AppTheme.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time Remaining: ${(_shockDoseRemainingSec ~/ 3600)}h ${((_shockDoseRemainingSec % 3600) ~/ 60)}m',
                        style: const TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isShockDosingActive = false;
                            _shockDoseTimer?.cancel();
                          });
                        },
                        child: const Text('Abort Slug', style: TextStyle(color: AppTheme.error, fontSize: 12)),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.flash_on_rounded, size: 16),
                      label: const Text('Initiate 4-Hour Biocide Slug Injection (250 ppm)'),
                      onPressed: _startShockDoseSequence,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
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

  // ============================================================================
  // TAB 3: ER PROBES
  // ============================================================================

  Widget _buildErProbesTab() {
    final skid = _skidConfigs[_selectedSkid]!;
    final mpy = _measuredCorrosionRateMpy;
    final metalLoss = _cumulativeMetalLossMils;
    final isCompliant = mpy < 1.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Target & OISD-141 Standard Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isCompliant
                ? AppTheme.tertiary.withValues(alpha: 0.12)
                : AppTheme.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompliant ? AppTheme.tertiary : AppTheme.error,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCompliant ? Icons.verified_rounded : Icons.warning_rounded,
                color: isCompliant ? AppTheme.tertiary : AppTheme.error,
                size: 28,
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
                          isCompliant
                              ? 'CORROSION CONTROL: COMPLIANT'
                              : 'CORROSION RATE WARNING',
                          style: TextStyle(
                            color: isCompliant ? AppTheme.tertiary : AppTheme.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCompliant ? AppTheme.tertiary : AppTheme.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Target < 1.0 mpy',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time Electrical Resistance (ER) probe metal loss rate is ${mpy.toStringAsFixed(2)} mpy. OISD-141 Clause 8.2 and NACE MR0175 criteria are strictly met.',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ER Probe Live Chart Card (LineChart)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cumulative Metal Loss Trend (30 Days)',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'ER Probe ER-01A (6 o\'clock Invert) • ${skid.name}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                    Text(
                      '${metalLoss.toStringAsFixed(2)} mils loss',
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // fl_chart LineChart
                SizedBox(
                  height: 190,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 0.5,
                        verticalInterval: 5,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: AppTheme.border,
                          strokeWidth: 0.8,
                          dashArray: [4, 4],
                        ),
                        getDrawingVerticalLine: (value) => const FlLine(
                          color: AppTheme.border,
                          strokeWidth: 0.8,
                          dashArray: [4, 4],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Text(
                            'Historical Days Ago (Day 30 to Day 0)',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'D-${30 - value.toInt()}',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: const Text(
                            'Mils Loss',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 0.5,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toStringAsFixed(1)}m',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppTheme.border),
                      ),
                      minX: 0,
                      maxX: 30,
                      minY: 0,
                      maxY: 3.0,
                      lineBarsData: [
                        // Cumulative Metal Loss Line
                        LineChartBarData(
                          spots: _generateMetalLossSpots(),
                          isCurved: true,
                          curveSmoothness: 0.25,
                          color: AppTheme.primaryLight,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Target Guideline Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 12, height: 3, color: AppTheme.primaryLight),
                    const SizedBox(width: 6),
                    const Text('Cumulative Metal Loss (mils)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5)),
                    const SizedBox(width: 16),
                    Container(width: 12, height: 3, color: AppTheme.tertiary),
                    const SizedBox(width: 6),
                    const Text('Inhibition Slope: < 1.0 mpy', style: TextStyle(color: AppTheme.tertiary, fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ER Probe Hardware & Health Table
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ER Probe Hardware & Installation Profile',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      _buildSpecRow('Probe Tag & Model', 'ER-01A (Rohrback Cosasco Corrosometer 2500)'),
                      const Divider(color: AppTheme.border, height: 12),
                      _buildSpecRow('Clock Location in Pipe', '6 o\'clock (Bottom Invert Water Sag Zone)'),
                      const Divider(color: AppTheme.border, height: 12),
                      _buildSpecRow('Sacrificial Element Metallurgy', 'API 5L X65 Flush Element (Matching Pipe)'),
                      const Divider(color: AppTheme.border, height: 12),
                      _buildSpecRow('Element Span & Remaining Life', '20.0 mils total span (90.8% remaining life)'),
                      const Divider(color: AppTheme.border, height: 12),
                      _buildSpecRow('Temperature Compensation', 'ACTIVE (Dual RTD bridge compensated)'),
                      const Divider(color: AppTheme.border, height: 12),
                      _buildSpecRow('Sampling Interval', 'Continuous 15-minute average via RS-485 Modbus'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generateMetalLossSpots() {
    final spots = <FlSpot>[];
    final base = switch (_selectedSkid) {
      DosingSkidId.sk01Duliajan => 1.84,
      DosingSkidId.sk02Moran => 2.45,
      DosingSkidId.sk03Jorhat => 1.12,
    };
    for (int i = 0; i <= 30; i++) {
      // slope of roughly 0.03 mils per day with slight curve
      final loss = (base - (30 - i) * 0.04).clamp(0.2, 3.0);
      spots.add(FlSpot(i.toDouble(), double.parse(loss.toStringAsFixed(2))));
    }
    return spots;
  }

  // ============================================================================
  // TAB 4: COUPON SCHEDULE
  // ============================================================================

  Widget _buildCouponScheduleTab() {
    final skidConfig = _skidConfigs[_selectedSkid]!;
    final relevantCoupons = _coupons.where((c) => c.skidTag == skidConfig.tag).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Standard Reference Header
        Card(
          color: AppTheme.surfaceCard,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Weight Loss Corrosion Coupon Schedule',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'OISD-141 / ASTM G1 / G4',
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Physical weight loss coupons evaluate actual baseline metal loss, pitting distribution, and validate real-time ER probe calibrations. Standard retrieval interval is 90 days.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // List of Coupons for Active Skid
        ...relevantCoupons.map((coupon) => _buildCouponCard(coupon)),

        const SizedBox(height: 16),

        // Cosasco High-Pressure Retrieval Tool Protocol Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.build_rounded, color: AppTheme.secondary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cosasco High-Pressure Live Line Retriever',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Hot-tap retrieval under 68.5 bar operating line pressure',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Live line coupon extraction must follow Cosasco HP 6000 PSI procedure: (1) Attach service valve to 2" access fitting, (2) Hydro-equalize pressure before back-off, (3) Extract coupon into retriever barrel, (4) Close service valve, (5) Depressurize via bleed-off valve.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryLight,
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    icon: const Icon(Icons.checklist_rounded, size: 16),
                    label: const Text('View Cosasco Live Line Extraction Checklist'),
                    onPressed: () => _showCosascoChecklistModal(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCouponCard(WeightLossCouponRecord coupon) {
    final isDue = coupon.status == 'Due for Retrieval';
    final isRetrieved = coupon.status == 'Retrieved & Certified';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isRetrieved
                          ? Icons.check_circle_rounded
                          : (isDue ? Icons.alarm_rounded : Icons.pending_rounded),
                      size: 18,
                      color: isRetrieved
                          ? AppTheme.tertiary
                          : (isDue ? AppTheme.secondary : AppTheme.primaryLight),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      coupon.couponSerial,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isRetrieved
                        ? AppTheme.tertiary.withValues(alpha: 0.15)
                        : (isDue ? AppTheme.secondary.withValues(alpha: 0.2) : AppTheme.surfaceContainerHigh),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    coupon.status,
                    style: TextStyle(
                      color: isRetrieved
                          ? AppTheme.tertiary
                          : (isDue ? AppTheme.secondary : AppTheme.textSecondary),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${coupon.locationDescription} • Orientation: ${coupon.clockOrientation}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
            ),
            const SizedBox(height: 10),

            if (!isRetrieved) ...[
              // Progress bar for 90 days exposure
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: coupon.exposureProgress,
                  minHeight: 6,
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDue ? AppTheme.secondary : AppTheme.primaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Exposed: ${coupon.exposedDays} / ${coupon.targetExposureDays} Days (${(coupon.exposureProgress * 100).toStringAsFixed(1)}%)',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
                  ),
                  Text(
                    isDue ? 'DUE NOW' : '${coupon.daysRemaining} Days to Retrieval',
                    style: TextStyle(
                      color: isDue ? AppTheme.secondary : AppTheme.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Historical Lab Results
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLabResultBadge('Corrosion Rate', '${coupon.measuredMpy} mpy', AppTheme.tertiary),
                    _buildLabResultBadge('Pitting Depth', '${coupon.pittingDepthMm} mm', AppTheme.primaryLight),
                    _buildLabResultBadge('Lab Cert', coupon.labCertNumber ?? 'N/A', AppTheme.textSecondary),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabResultBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ============================================================================
  // TAB 5: COMPLIANCE AUDIT
  // ============================================================================

  Widget _buildComplianceAuditTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Compliance Overview Banner
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
                    'NACE MR0175 & OISD-141 AUDIT MATRIX',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.tertiary, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '100% COMPLIANT',
                        style: TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Comprehensive regulatory verification across sour service sulfide stress cracking mitigation, internal corrosion monitoring, and positive displacement pump standards.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Compliance Items List
        ..._complianceItems.map((item) => _buildComplianceCard(item)),

        const SizedBox(height: 16),

        // Chemical Batch Traceability & Ledger
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chemical Batch Traceability & Certificate Ledger',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'All corrosion inhibitors, demulsifiers, H2S scavengers, and biocides injected into Oil India trunklines require third-party laboratory verification conforming to NACE TM0193 and ASTM G31 autoclave test standards.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.3),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      foregroundColor: AppTheme.primaryLight,
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text('Export Internal Corrosion Audit Dossier (PDF)'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTheme.surfaceCard,
                          content: Text(
                            'Internal Corrosion Mitigation Dossier generated for PNGRB/OISD regulatory submission.',
                            style: TextStyle(color: AppTheme.textPrimary),
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
      ],
    );
  }

  Widget _buildComplianceCard(ComplianceAuditItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.standard,
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PASSED',
                    style: TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.requirement,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Measured Value', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
                        const SizedBox(height: 2),
                        Text(
                          item.measuredValue,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: AppTheme.border),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Permissible Limit', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
                        const SizedBox(height: 2),
                        Text(
                          item.limitValue,
                          style: const TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.w600),
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
    );
  }

  // ============================================================================
  // MODALS & DIALOGS
  // ============================================================================

  void _showDosingCalculatorModal(BuildContext context) {
    double targetPpmInput = _activeChemicalProduct.targetPpm;
    final skid = _skidConfigs[_selectedSkid]!;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Calculation: Required L/day = (PPM * Gas_Flow * WaterCutFactor) / 1000
            final estimatedLpd = (targetPpmInput * skid.gasFlowMmscmd * 0.40);
            final estimatedSpm = (estimatedLpd / (24 * 60 * 0.45 * 0.65) * 1000).clamp(15.0, 120.0);

            return Padding(
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
                      const Expanded(
                        child: Text(
                          'Chemical Dosage Rate Calculator',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Correlating pipeline gas throughput (${skid.gasFlowMmscmd} MMSCMD) and water cut to compute target pump stroke parameters.',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Target Inhibitor Concentration: ${targetPpmInput.toInt()} PPM',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: targetPpmInput.clamp(5.0, 400.0),
                    min: 5.0,
                    max: 400.0,
                    divisions: 79,
                    activeColor: AppTheme.primaryLight,
                    onChanged: (val) {
                      setModalState(() {
                        targetPpmInput = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _buildSpecRow('Computed Daily Consumption', '${estimatedLpd.toStringAsFixed(1)} Liters/day'),
                        const Divider(color: AppTheme.border, height: 12),
                        _buildSpecRow('Recommended Stroke Speed', '${estimatedSpm.toInt()} SPM (@ 65% stroke length)'),
                        const Divider(color: AppTheme.border, height: 12),
                        _buildSpecRow('Anticipated Corrosion Rate', '< 0.50 mpy (Full NACE film protection)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _updateStrokeSpeed(estimatedSpm);
                        _updateStrokeLength(65.0);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.surfaceCard,
                            content: Text(
                              'Pump calibrated: ${estimatedSpm.toInt()} SPM @ 65% stroke length for ${targetPpmInput.toInt()} PPM.',
                              style: const TextStyle(color: AppTheme.textPrimary),
                            ),
                          ),
                        );
                      },
                      child: const Text('Apply Computed Parameters to Skid'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRefillTankDialog(BuildContext context) {
    final activeProd = _activeChemicalProduct;
    final litersNeeded = activeProd.tankCapacityLiters - activeProd.currentStockLiters;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: AppTheme.secondary),
              const SizedBox(width: 8),
              const Text(
                'Chemical Tank Replenishment',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dispatch tanker replenishment for ${activeProd.tradeName} at ${_skidConfigs[_selectedSkid]!.name}.',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildSpecRow('Tank Capacity', '${activeProd.tankCapacityLiters.toInt()} Liters'),
                    const SizedBox(height: 6),
                    _buildSpecRow('Current Level', '${activeProd.currentStockLiters.toInt()} Liters'),
                    const SizedBox(height: 6),
                    _buildSpecRow('Deficit Volume', '${litersNeeded.toInt()} Liters',),
                    const SizedBox(height: 6),
                    _buildSpecRow('Supplier', activeProd.supplier),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.surfaceCard,
                    content: Text(
                      'Refill purchase order dispatched for ${litersNeeded.toInt()} L of ${activeProd.tradeName}.',
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                );
              },
              child: const Text('Dispatch Tanker PO'),
            ),
          ],
        );
      },
    );
  }

  void _showCosascoChecklistModal(BuildContext context) {
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
                children: [
                  const Icon(Icons.shield_outlined, color: AppTheme.primaryLight),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cosasco Hot-Tap Live Retrieval Checklist',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCheckStep('1', 'Inspect Cosasco 2" service valve packing & test to 100 bar hydro'),
              _buildCheckStep('2', 'Thread retriever onto service valve and open equalizing bypass valve'),
              _buildCheckStep('3', 'Extend retriever drive shaft into access fitting & engage coupon plug'),
              _buildCheckStep('4', 'Unthread plug with counter-clockwise rotation and pull into barrel'),
              _buildCheckStep('5', 'Close service valve completely and vent barrel pressure to flare drain'),
              _buildCheckStep('6', 'Remove coupon coupon, degrease, weigh, and seal in desiccant pouch'),
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

  Widget _buildCheckStep(String stepNumber, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
