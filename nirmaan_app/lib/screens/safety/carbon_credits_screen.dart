import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// STATUTORY FRAMEWORKS, ENUMS & CARBON ACCOUNTING MODELS
// ============================================================================

/// Global Warming Potential (GWP) Time Horizon per IPCC AR5 / AR6 Guidelines
enum GwpHorizon {
  gwp100(
    value: 28.0,
    label: '100-Year Horizon (IPCC AR5)',
    shortLabel: 'GWP₁₀₀ = 28',
    subtext: 'BEE CCTS & Paris Agreement Article 6 Statutory Standard',
    color: Color(0xFF0284C7),
    badgeColor: Color(0x260284C7),
  ),
  gwp20(
    value: 84.0,
    label: '20-Year Horizon (IPCC AR5)',
    shortLabel: 'GWP₂₀ = 84',
    subtext: 'Near-Term Climate Impact (Highlights CH₄ Slip Severity)',
    color: Color(0xFFFFB95F),
    badgeColor: Color(0x26FFB95F),
  );

  final double value;
  final String label;
  final String shortLabel;
  final String subtext;
  final Color color;
  final Color badgeColor;

  const GwpHorizon({
    required this.value,
    required this.label,
    required this.shortLabel,
    required this.subtext,
    required this.color,
    required this.badgeColor,
  });
}

/// Flare Header Stream Classifications
enum FlaringStreamType {
  hpFlare(
    label: 'High-Pressure Flare (HP)',
    shortCode: 'HP-FLARE',
    operatingPressureBar: 45.0,
    typicalDestructionEfficiency: 0.985,
    color: Color(0xFFEF4444),
    icon: Icons.local_fire_department_rounded,
  ),
  lpFlare(
    label: 'Low-Pressure Flare (LP)',
    shortCode: 'LP-FLARE',
    operatingPressureBar: 3.5,
    typicalDestructionEfficiency: 0.980,
    color: Color(0xFFFFB95F),
    icon: Icons.whatshot_rounded,
  ),
  acidGasFlare(
    label: 'Sour Acid Gas Flare',
    shortCode: 'ACID-FLARE',
    operatingPressureBar: 1.8,
    typicalDestructionEfficiency: 0.992,
    color: Color(0xFFA78BFA),
    icon: Icons.warning_amber_rounded,
  ),
  coldAtmosphericVent(
    label: 'Cold Atmospheric Vent (Emergency)',
    shortCode: 'COLD-VENT',
    operatingPressureBar: 1.0,
    typicalDestructionEfficiency: 0.000, // 100% methane slip
    color: Color(0xFFF43F5E),
    icon: Icons.air_rounded,
  ),
  nitrogenPurgeHeader(
    label: 'N₂ Continuous Sweep & Purge',
    shortCode: 'N2-PURGE',
    operatingPressureBar: 0.8,
    typicalDestructionEfficiency: 1.000,
    color: Color(0xFF38BDF8),
    icon: Icons.waves_rounded,
  );

  final String label;
  final String shortCode;
  final double operatingPressureBar;
  final double typicalDestructionEfficiency;
  final Color color;
  final IconData icon;

  const FlaringStreamType({
    required this.label,
    required this.shortCode,
    required this.operatingPressureBar,
    required this.typicalDestructionEfficiency,
    required this.color,
    required this.icon,
  });
}

/// Pipeline Blowdown / Purge Event Record (Scope 1 Direct Source)
class BlowdownEventRecord {
  final String id;
  final String sectionName;
  final DateTime timestamp;
  final double diameterMm;
  final double lengthKm;
  final double pressureBar;
  final double tempCelsius;
  final double volumeSm3;
  final double methaneFraction; // e.g. 0.92 = 92%
  final double gasDensityKgM3;  // e.g. 0.716 kg/Sm3
  final bool routedToFlare;     // true: combusted, false: cold vented
  final bool capturedByVru;     // true: zero-flared via VRU compressor
  final double combustionEfficiency; // e.g. 0.985
  final String statutoryWorkPermit;
  final String loggedBy;
  final String notes;

  const BlowdownEventRecord({
    required this.id,
    required this.sectionName,
    required this.timestamp,
    required this.diameterMm,
    required this.lengthKm,
    required this.pressureBar,
    required this.tempCelsius,
    required this.volumeSm3,
    required this.methaneFraction,
    required this.gasDensityKgM3,
    required this.routedToFlare,
    required this.capturedByVru,
    required this.combustionEfficiency,
    required this.statutoryWorkPermit,
    required this.loggedBy,
    required this.notes,
  });

  /// Total mass of gas released or handled in kg
  double get totalGasMassKg => volumeSm3 * gasDensityKgM3;

  /// Pure Methane (CH4) mass in kg
  double get ch4MassKg => totalGasMassKg * methaneFraction;

  /// Scope 1 Direct Emissions in metric tons CO2 equivalent (tCO2e)
  double calculateScope1Tco2e(double gwpCh4) {
    if (capturedByVru) {
      // Zero-flaring vapor recovery: zero direct Scope 1 release
      return 0.0;
    }

    if (!routedToFlare) {
      // Cold atmospheric venting: all CH4 released directly to atmosphere
      // Formula: tCO2e = (V_gas * rho_gas * f_CH4 * GWP_CH4) / 1000
      return (ch4MassKg * gwpCh4) / 1000.0;
    }

    // Combusted Flaring:
    // Fraction combusted emits CO2: CH4 + 2O2 -> CO2 + 2H2O (44/16 = 2.744 kg CO2 per kg CH4)
    final combustedCh4Kg = ch4MassKg * combustionEfficiency;
    final producedCo2Kg = combustedCh4Kg * (44.01 / 16.04);
    final co2Tons = producedCo2Kg / 1000.0; // GWP of CO2 = 1.0

    // Unburned Methane Slip: (1 - eta_comb) released directly
    final slipCh4Kg = ch4MassKg * (1.0 - combustionEfficiency);
    final slipTco2e = (slipCh4Kg * gwpCh4) / 1000.0;

    return co2Tons + slipTco2e;
  }

  /// Flared CO2 component alone in tCO2e
  double getFlaredCo2Tons() {
    if (capturedByVru || !routedToFlare) return 0.0;
    final combustedCh4Kg = ch4MassKg * combustionEfficiency;
    return (combustedCh4Kg * (44.01 / 16.04)) / 1000.0;
  }

  /// Methane slip component alone in tCO2e
  double getSlipTco2e(double gwpCh4) {
    if (capturedByVru) return 0.0;
    if (!routedToFlare) {
      return (ch4MassKg * gwpCh4) / 1000.0;
    }
    final slipCh4Kg = ch4MassKg * (1.0 - combustionEfficiency);
    return (slipCh4Kg * gwpCh4) / 1000.0;
  }

  /// Abated emissions compared to unmitigated cold venting in tCO2e
  double calculateAbatementVsColdVenting(double gwpCh4) {
    final unmitigatedColdVentTco2e = (ch4MassKg * gwpCh4) / 1000.0;
    final actualScope1 = calculateScope1Tco2e(gwpCh4);
    return math.max(0.0, unmitigatedColdVentTco2e - actualScope1);
  }
}

/// Fugitive Component Types for LDAR (Leak Detection and Repair)
enum LdarComponentType {
  flange(
    label: 'Flanged Connection / Gasket',
    shortCode: 'FLG',
    typicalLeakFactorKgHr: 0.00025,
    icon: Icons.album_rounded,
    color: Color(0xFF38BDF8),
  ),
  controlValve(
    label: 'Control Valve Stem / Packing',
    shortCode: 'VLV-CTRL',
    typicalLeakFactorKgHr: 0.00560,
    icon: Icons.tune_rounded,
    color: Color(0xFFFFB95F),
  ),
  blockValve(
    label: 'Manual Isolation Ball/Gate Valve',
    shortCode: 'VLV-ISO',
    typicalLeakFactorKgHr: 0.00120,
    icon: Icons.radio_button_checked_rounded,
    color: Color(0xFF0284C7),
  ),
  prv(
    label: 'Pressure Relief Valve (PRV Seat)',
    shortCode: 'PRV',
    typicalLeakFactorKgHr: 0.01630,
    icon: Icons.security_rounded,
    color: Color(0xFFEF4444),
  ),
  compressorSeal(
    label: 'Compressor Shaft Seal / Packing',
    shortCode: 'CMP-SEAL',
    typicalLeakFactorKgHr: 0.08840,
    icon: Icons.compress_rounded,
    color: Color(0xFFA78BFA),
  ),
  openEndedLine(
    label: 'Open-Ended Bleed / Drain Valve',
    shortCode: 'OEL',
    typicalLeakFactorKgHr: 0.00230,
    icon: Icons.plumbing_rounded,
    color: Color(0xFFF59E0B),
  ),
  pigTrapClosure(
    label: 'Pig Trap Quick-Opening Door',
    shortCode: 'PIG-TRAP',
    typicalLeakFactorKgHr: 0.01450,
    icon: Icons.door_sliding_rounded,
    color: Color(0xFF10B981),
  );

  final String label;
  final String shortCode;
  final double typicalLeakFactorKgHr;
  final IconData icon;
  final Color color;

  const LdarComponentType({
    required this.label,
    required this.shortCode,
    required this.typicalLeakFactorKgHr,
    required this.icon,
    required this.color,
  });
}

/// LDAR Leak Severity Classification per EPA Method 21 / OISD Standards
enum LdarSeverity {
  minor(
    label: 'Minor Leak (< 1,000 ppmv)',
    thresholdPpm: 1000,
    maxRepairDays: 30,
    color: Color(0xFF4EDEA3),
  ),
  major(
    label: 'Major Leak (1,000 - 10,000 ppmv)',
    thresholdPpm: 10000,
    maxRepairDays: 15,
    color: Color(0xFFFFB95F),
  ),
  critical(
    label: 'Critical Leak (> 10,000 ppmv / Plume)',
    thresholdPpm: 50000,
    maxRepairDays: 5,
    color: Color(0xFFEF4444),
  );

  final String label;
  final double thresholdPpm;
  final int maxRepairDays;
  final Color color;

  const LdarSeverity({
    required this.label,
    required this.thresholdPpm,
    required this.maxRepairDays,
    required this.color,
  });
}

/// LDAR Repair Lifecycle Status
enum LdarStatus {
  detected(
    label: 'OGI DETECTED',
    color: Color(0xFFEF4444),
    badgeColor: Color(0x26EF4444),
    icon: Icons.warning_rounded,
  ),
  scheduled(
    label: 'REPAIR SCHEDULED',
    color: Color(0xFFFFB95F),
    badgeColor: Color(0x26FFB95F),
    icon: Icons.pending_actions_rounded,
  ),
  repaired(
    label: 'REPAIRED (PENDING QA)',
    color: Color(0xFF38BDF8),
    badgeColor: Color(0x2638BDF8),
    icon: Icons.build_circle_rounded,
  ),
  verifiedCompliant(
    label: 'VERIFIED ZERO-LEAK',
    color: Color(0xFF4EDEA3),
    badgeColor: Color(0x264EDEA3),
    icon: Icons.verified_rounded,
  );

  final String label;
  final Color color;
  final Color badgeColor;
  final IconData icon;

  const LdarStatus({
    required this.label,
    required this.color,
    required this.badgeColor,
    required this.icon,
  });
}

/// Optical Gas Imaging (OGI) LDAR Inspection Log Entry
class LdarLogEntry {
  final String id;
  final String tagNumber;
  final LdarComponentType componentType;
  final String facilityStation;
  final String ogiCameraModel; // e.g. FLIR GF320 / EyeCGas
  final String inspectorName;
  final DateTime detectedDate;
  final double concentrationPpm;
  final double estimatedLeakRateKgHr;
  final LdarSeverity severity;
  final LdarStatus status;
  final DateTime repairDeadline;
  final DateTime? repairDate;
  final String repairTechnique;
  final double postRepairPpm;

  const LdarLogEntry({
    required this.id,
    required this.tagNumber,
    required this.componentType,
    required this.facilityStation,
    required this.ogiCameraModel,
    required this.inspectorName,
    required this.detectedDate,
    required this.concentrationPpm,
    required this.estimatedLeakRateKgHr,
    required this.severity,
    required this.status,
    required this.repairDeadline,
    this.repairDate,
    required this.repairTechnique,
    required this.postRepairPpm,
  });

  /// Annualized avoided methane emissions in tCO2e if repaired
  double calculateAnnualAbatementTco2e(double gwpCh4) {
    // Annual operating hours = 8760
    final annualMethaneKg = estimatedLeakRateKgHr * 8760.0;
    return (annualMethaneKg * gwpCh4) / 1000.0;
  }
}

/// Zero-Flaring Vapor Recovery Compressor Unit (VRU)
class VruCompressorUnit {
  final String id;
  final String unitName;
  final String stationLocation;
  final bool isOnline;
  final double suctionPressureBar;
  final double dischargePressureBar;
  final double recoveryFlowSm3Hr;
  final double motorPowerKw;
  final double cumulativeRecoveredSm3;
  final double availabilityPercent;

  const VruCompressorUnit({
    required this.id,
    required this.unitName,
    required this.stationLocation,
    required this.isOnline,
    required this.suctionPressureBar,
    required this.dischargePressureBar,
    required this.recoveryFlowSm3Hr,
    required this.motorPowerKw,
    required this.cumulativeRecoveredSm3,
    required this.availabilityPercent,
  });

  /// Net Carbon Offset Credits accrued from captured gas in tCO2e (1 CCC = 1 tCO2e)
  /// Net = Avoided flaring/venting baseline emissions minus Scope 2 compression electricity
  double calculateNetCreditsAccrued(double gwpCh4) {
    // Density 0.716 kg/Sm3, 94% CH4
    final methaneMassKg = cumulativeRecoveredSm3 * 0.716 * 0.94;
    // Avoided baseline emissions: flaring with 98.5% efficiency baseline
    final flaredCo2T = (methaneMassKg * 0.985 * (44.01 / 16.04)) / 1000.0;
    final slipTco2e = (methaneMassKg * (1.0 - 0.985) * gwpCh4) / 1000.0;
    final grossBaselineTco2e = flaredCo2T + slipTco2e;

    // Scope 2 emissions from compression (0.716 tCO2/MWh Indian national grid factor)
    final hours = cumulativeRecoveredSm3 / math.max(1.0, recoveryFlowSm3Hr);
    final mwhConsumed = (motorPowerKw * hours) / 1000.0;
    final scope2Tco2 = mwhConsumed * 0.716;

    return math.max(0.0, grossBaselineTco2e - scope2Tco2);
  }
}

/// Carbon Credit Registry Token Status
enum TokenRegistryStatus {
  mintedVerified(
    label: 'MINTED & VERIFIED',
    color: Color(0xFF4EDEA3),
    badgeColor: Color(0x264EDEA3),
    icon: Icons.shield_rounded,
  ),
  activeTrading(
    label: 'ACTIVE / TRADABLE (IEX/PXIL)',
    color: Color(0xFF0284C7),
    badgeColor: Color(0x260284C7),
    icon: Icons.currency_exchange_rounded,
  ),
  surrenderedCompliance(
    label: 'SURRENDERED (BEE QUOTA)',
    color: Color(0xFFFFB95F),
    badgeColor: Color(0x26FFB95F),
    icon: Icons.fact_check_rounded,
  ),
  article6Itmo(
    label: 'PARIS ART 6.2 ITMO TRANSFERRED',
    color: Color(0xFFA78BFA),
    badgeColor: Color(0x26A78BFA),
    icon: Icons.public_rounded,
  );

  final String label;
  final Color color;
  final Color badgeColor;
  final IconData icon;

  const TokenRegistryStatus({
    required this.label,
    required this.color,
    required this.badgeColor,
    required this.icon,
  });
}

/// Carbon Credit Registry Token (Digital MRV Ledger Record)
class CarbonCreditToken {
  final String serialNumber;
  final String sha256Hash;
  final int vintageYear;
  final double quantityCredits; // 1 CCC = 1 tCO2e
  final String originProject;
  final String standardProtocol; // e.g. BEE CCTS 2022 / Article 6.4 / VCS
  final TokenRegistryStatus status;
  final DateTime issueDate;
  final String accreditedVerifier; // DOE e.g. TÜV SÜD / Bureau Veritas
  final String transactionReference;

  const CarbonCreditToken({
    required this.serialNumber,
    required this.sha256Hash,
    required this.vintageYear,
    required this.quantityCredits,
    required this.originProject,
    required this.standardProtocol,
    required this.status,
    required this.issueDate,
    required this.accreditedVerifier,
    required this.transactionReference,
  });
}

/// Statutory MoEFCC & BEE CCTS Quarterly Return Filing Record
class BeeQuarterlyReturnFiling {
  final String fiscalQuarter; // 'Q1 FY26', 'Q2 FY26', etc.
  final DateTime reportingPeriodEnd;
  final double totalThroughputMmscm;
  final double routineFlaringMmscm;
  final double blowdownPurgeMmscm;
  final double unburnedSlipTco2e;
  final double vruCaptureMmscm;
  final double ldarAbatedTco2e;
  final double grossScope1Tco2e;
  final double netScope1Tco2e;
  final double beeAssignedEmissionIntensityCap; // tCO2e / MMSCM throughput
  final double actualEmissionIntensity;        // tCO2e / MMSCM throughput
  final double carbonCreditsSurrendered;
  final String complianceStatus; // 'SURPLUS', 'COMPLIANT', 'DEFICIT'
  final bool isFiledWithMoefcc;
  final DateTime? filingTimestamp;
  final String digitalAckNumber;

  const BeeQuarterlyReturnFiling({
    required this.fiscalQuarter,
    required this.reportingPeriodEnd,
    required this.totalThroughputMmscm,
    required this.routineFlaringMmscm,
    required this.blowdownPurgeMmscm,
    required this.unburnedSlipTco2e,
    required this.vruCaptureMmscm,
    required this.ldarAbatedTco2e,
    required this.grossScope1Tco2e,
    required this.netScope1Tco2e,
    required this.beeAssignedEmissionIntensityCap,
    required this.actualEmissionIntensity,
    required this.carbonCreditsSurrendered,
    required this.complianceStatus,
    required this.isFiledWithMoefcc,
    this.filingTimestamp,
    required this.digitalAckNumber,
  });
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class CarbonCreditsScreen extends StatefulWidget {
  const CarbonCreditsScreen({super.key});

  @override
  State<CarbonCreditsScreen> createState() => _CarbonCreditsScreenState();
}

class _CarbonCreditsScreenState extends State<CarbonCreditsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Active Global Warming Potential Horizon toggle
  GwpHorizon _activeGwpHorizon = GwpHorizon.gwp100;

  // Market Spot Price per CCC (INR)
  final double _spotCccInr = 1450.0;

  // --------------------------------------------------------------------------
  // IN-MEMORY DATA STORE (Simulated Industrial Pipeline Telemetry)
  // --------------------------------------------------------------------------

  late List<BlowdownEventRecord> _blowdownEvents;
  late List<LdarLogEntry> _ldarLogs;
  late List<VruCompressorUnit> _vruUnits;
  late List<CarbonCreditToken> _tokenLedger;
  late List<BeeQuarterlyReturnFiling> _quarterlyReturns;

  // LDAR Filter & Search
  String _ldarSearchQuery = '';
  LdarSeverity? _selectedLdarSeverity;

  // Blowdown Calculator Live Controllers
  final TextEditingController _calcSectionCtrl =
      TextEditingController(text: 'Duliajan-Moran Main 24" Trunkline (KP 42-68)');
  double _calcDiameterMm = 610.0;     // 24"
  double _calcLengthKm = 26.4;        // 26.4 km
  double _calcPressureBar = 65.0;      // 65 bar
  double _calcTempCelsius = 24.0;     // 24 C
  double _calcMethaneFraction = 0.94; // 94% CH4
  double _calcCombustionEff = 0.985;  // 98.5%
  bool _calcIsFlared = true;
  bool _calcIsVruCaptured = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _calcSectionCtrl.dispose();
    super.dispose();
  }

  void _initializeData() {
    final now = DateTime.now();

    // 1. Blowdown / Purge Records
    _blowdownEvents = [
      BlowdownEventRecord(
        id: 'BD-2026-081',
        sectionName: 'Section SV-04 to SV-05 Pipeline Depressurization',
        timestamp: now.subtract(const Duration(hours: 14)),
        diameterMm: 610.0,
        lengthKm: 18.2,
        pressureBar: 62.5,
        tempCelsius: 22.0,
        volumeSm3: 84250.0,
        methaneFraction: 0.942,
        gasDensityKgM3: 0.718,
        routedToFlare: true,
        capturedByVru: false,
        combustionEfficiency: 0.988,
        statutoryWorkPermit: 'PTW-HOT-OIL-2026-9041',
        loggedBy: 'Kalyan Gogoi (Lead Gas Dispatcher)',
        notes: 'Planned pig receiver depressurization for ILI MFL tool inspection run.',
      ),
      BlowdownEventRecord(
        id: 'BD-2026-080',
        sectionName: 'Burhi Dihing HDD River Crossing Purge & Inhabitation',
        timestamp: now.subtract(const Duration(days: 2, hours: 4)),
        diameterMm: 508.0,
        lengthKm: 1.45,
        pressureBar: 48.0,
        tempCelsius: 20.5,
        volumeSm3: 4920.0,
        methaneFraction: 0.915,
        gasDensityKgM3: 0.720,
        routedToFlare: false,
        capturedByVru: true, // Recovered via Mobile VRU Skid
        combustionEfficiency: 1.0,
        statutoryWorkPermit: 'PTW-CRIT-OIL-2026-8812',
        loggedBy: 'Tridip Saikia (HSE Manager)',
        notes: 'Pre-hydrotest dry nitrogen displacement; recovered 100% into sales header via Mobile VRU.',
      ),
      BlowdownEventRecord(
        id: 'BD-2026-079',
        sectionName: 'Compressor Station CS-02 Flash Gas Blowdown Header',
        timestamp: now.subtract(const Duration(days: 4, hours: 9)),
        diameterMm: 355.0,
        lengthKm: 4.8,
        pressureBar: 35.0,
        tempCelsius: 26.0,
        volumeSm3: 14600.0,
        methaneFraction: 0.938,
        gasDensityKgM3: 0.714,
        routedToFlare: true,
        capturedByVru: false,
        combustionEfficiency: 0.982,
        statutoryWorkPermit: 'PTW-MECH-OIL-2026-8740',
        loggedBy: 'Anupam Barua (Station Superintendent)',
        notes: 'Emergency shutdown test blowdown to LP knock-out drum and elevated sonic flare.',
      ),
      BlowdownEventRecord(
        id: 'BD-2026-078',
        sectionName: 'Metering Skid MS-03 Filter Separator Depressurization',
        timestamp: now.subtract(const Duration(days: 7)),
        diameterMm: 203.0,
        lengthKm: 0.45,
        pressureBar: 55.0,
        tempCelsius: 21.0,
        volumeSm3: 880.0,
        methaneFraction: 0.945,
        gasDensityKgM3: 0.716,
        routedToFlare: false,
        capturedByVru: false, // Cold vent penalty instance
        combustionEfficiency: 0.0,
        statutoryWorkPermit: 'PTW-INST-OIL-2026-8519',
        loggedBy: 'Bikram Dutta (Lead Instrument Tech)',
        notes: 'Cold atmospheric emergency depressurization due to faulty pilot flame monitor.',
      ),
    ];

    // 2. LDAR OGI Camera Logbook
    _ldarLogs = [
      LdarLogEntry(
        id: 'LDAR-TAG-4091',
        tagNumber: 'TAG-CMP-CS02-04',
        componentType: LdarComponentType.compressorSeal,
        facilityStation: 'Compressor Station 02 (Centrifugal Train B)',
        ogiCameraModel: 'FLIR GF320 (Optical Filter 3.2-3.4 µm)',
        inspectorName: 'Devajit Hazarika (ISO 9712 Level II)',
        detectedDate: now.subtract(const Duration(days: 2)),
        concentrationPpm: 18450.0,
        estimatedLeakRateKgHr: 0.092,
        severity: LdarSeverity.critical,
        status: LdarStatus.scheduled,
        repairDeadline: now.add(const Duration(days: 3)),
        repairTechnique: 'Dry gas seal cartridge replacement & buffer nitrogen retune',
        postRepairPpm: 0.0,
      ),
      LdarLogEntry(
        id: 'LDAR-TAG-4090',
        tagNumber: 'TAG-PRV-TK01-02',
        componentType: LdarComponentType.prv,
        facilityStation: 'Duliajan Condensate Tank Battery TK-01',
        ogiCameraModel: 'EyeCGas 2.0 HD OGI',
        inspectorName: 'Pranab Bordoloi (OGI Specialist)',
        detectedDate: now.subtract(const Duration(days: 6)),
        concentrationPpm: 8200.0,
        estimatedLeakRateKgHr: 0.024,
        severity: LdarSeverity.major,
        status: LdarStatus.repaired,
        repairDeadline: now.add(const Duration(days: 9)),
        repairDate: now.subtract(const Duration(days: 1)),
        repairTechnique: 'Nozzle lapping & recalibration at 58.0 bar_g pop pressure',
        postRepairPpm: 85.0,
      ),
      LdarLogEntry(
        id: 'LDAR-TAG-4089',
        tagNumber: 'TAG-FLG-SV04-18',
        componentType: LdarComponentType.flange,
        facilityStation: 'Sectionalizing Valve Station SV-04',
        ogiCameraModel: 'FLIR GF320',
        inspectorName: 'Devajit Hazarika (ISO 9712 Level II)',
        detectedDate: now.subtract(const Duration(days: 12)),
        concentrationPpm: 2400.0,
        estimatedLeakRateKgHr: 0.0035,
        severity: LdarSeverity.major,
        status: LdarStatus.verifiedCompliant,
        repairDeadline: now.subtract(const Duration(days: 2)),
        repairDate: now.subtract(const Duration(days: 7)),
        repairTechnique: 'Flange bolt cross-pattern retorque to 480 Nm with Spiral-Wound SS316',
        postRepairPpm: 0.0,
      ),
      LdarLogEntry(
        id: 'LDAR-TAG-4088',
        tagNumber: 'TAG-VLV-MS01-33',
        componentType: LdarComponentType.controlValve,
        facilityStation: 'Custody Transfer Metering Skid MS-01',
        ogiCameraModel: 'FLIR GFx320 ATEX Zone 1',
        inspectorName: 'Pranab Bordoloi (OGI Specialist)',
        detectedDate: now.subtract(const Duration(days: 15)),
        concentrationPpm: 740.0,
        estimatedLeakRateKgHr: 0.0011,
        severity: LdarSeverity.minor,
        status: LdarStatus.verifiedCompliant,
        repairDeadline: now.add(const Duration(days: 15)),
        repairDate: now.subtract(const Duration(days: 10)),
        repairTechnique: 'Graphite gland packing ring injection & live-loaded spring adjustment',
        postRepairPpm: 12.0,
      ),
      LdarLogEntry(
        id: 'LDAR-TAG-4087',
        tagNumber: 'TAG-PIG-REC-02',
        componentType: LdarComponentType.pigTrapClosure,
        facilityStation: 'Moran Terminal Pig Receiver Scraper Barrel',
        ogiCameraModel: 'EyeCGas 2.0 HD OGI',
        inspectorName: 'Devajit Hazarika (ISO 9712 Level II)',
        detectedDate: now.subtract(const Duration(days: 21)),
        concentrationPpm: 4600.0,
        estimatedLeakRateKgHr: 0.015,
        severity: LdarSeverity.major,
        status: LdarStatus.verifiedCompliant,
        repairDeadline: now.subtract(const Duration(days: 6)),
        repairDate: now.subtract(const Duration(days: 18)),
        repairTechnique: 'HNBR chevron seal ring replacement with fluorosilicone grease',
        postRepairPpm: 0.0,
      ),
    ];

    // 3. Vapor Recovery Units (VRU)
    _vruUnits = [
      VruCompressorUnit(
        id: 'VRU-SKID-01',
        unitName: 'VRU Train Alpha (Rotary Screw Booster)',
        stationLocation: 'Duliajan Central Gas Gathering Station (CGGS)',
        isOnline: true,
        suctionPressureBar: 1.15,
        dischargePressureBar: 28.5,
        recoveryFlowSm3Hr: 1250.0,
        motorPowerKw: 132.0,
        cumulativeRecoveredSm3: 1845000.0,
        availabilityPercent: 99.4,
      ),
      VruCompressorUnit(
        id: 'VRU-SKID-02',
        unitName: 'VRU Train Bravo (Reciprocating Booster)',
        stationLocation: 'Moran Custody Dispatch Station',
        isOnline: true,
        suctionPressureBar: 1.08,
        dischargePressureBar: 32.0,
        recoveryFlowSm3Hr: 820.0,
        motorPowerKw: 90.0,
        cumulativeRecoveredSm3: 984000.0,
        availabilityPercent: 98.8,
      ),
    ];

    // 4. Carbon Credit Token Registry
    _tokenLedger = [
      CarbonCreditToken(
        serialNumber: 'BEE-CCTS-2026-VRU-OIL-094821',
        sha256Hash: _generateHash('BEE-CCTS-2026-VRU-OIL-094821-VCS-VERIFIED'),
        vintageYear: 2026,
        quantityCredits: 1850.0,
        originProject: 'OIL Duliajan CGGS Zero-Flaring VRU Skid Recovery',
        standardProtocol: 'BEE CCTS (Energy Conservation Act 2022 / MoEFCC)',
        status: TokenRegistryStatus.mintedVerified,
        issueDate: now.subtract(const Duration(days: 18)),
        accreditedVerifier: 'TÜV SÜD South Asia (Designated Operational Entity)',
        transactionReference: 'TX-CCTS-2026-IN-98124',
      ),
      CarbonCreditToken(
        serialNumber: 'BEE-CCTS-2026-LDAR-OIL-094820',
        sha256Hash: _generateHash('BEE-CCTS-2026-LDAR-OIL-094820-OGI-VERIFIED'),
        vintageYear: 2026,
        quantityCredits: 420.0,
        originProject: 'Upper Assam Trunkline Optical Gas Imaging LDAR Program',
        standardProtocol: 'GHG Protocol Corporate Standard (Scope 1 Avoided)',
        status: TokenRegistryStatus.activeTrading,
        issueDate: now.subtract(const Duration(days: 35)),
        accreditedVerifier: 'Bureau Veritas India Certification',
        transactionReference: 'TX-IEX-CARBON-2026-4410',
      ),
      CarbonCreditToken(
        serialNumber: 'A6-ITMO-2025-OIL-IND-01824',
        sha256Hash: _generateHash('PARIS-A6.2-ITMO-OIL-IND-SWISS-2025'),
        vintageYear: 2025,
        quantityCredits: 3500.0,
        originProject: 'Northeast Gas Grid Flaring Abatement & Green Pipeline',
        standardProtocol: 'Paris Agreement Article 6.2 (Bilateral ITMO Transfer)',
        status: TokenRegistryStatus.article6Itmo,
        issueDate: now.subtract(const Duration(days: 120)),
        accreditedVerifier: 'DNV GL Climate Assurance',
        transactionReference: 'UNFCCC-ITMO-IND-CHE-2025-098',
      ),
      CarbonCreditToken(
        serialNumber: 'BEE-CCTS-2025-Q4-OIL-081190',
        sha256Hash: _generateHash('BEE-CCTS-2025-Q4-SURRENDERED-COMPLIANCE'),
        vintageYear: 2025,
        quantityCredits: 2150.0,
        originProject: 'Duliajan Compressor Station VRU Gas Re-injection',
        standardProtocol: 'BEE CCTS Compliance Obligation Surrender',
        status: TokenRegistryStatus.surrenderedCompliance,
        issueDate: now.subtract(const Duration(days: 210)),
        accreditedVerifier: 'TÜV SÜD South Asia',
        transactionReference: 'BEE-SURRENDER-ACK-2025-Q4-012',
      ),
    ];

    // 5. Statutory MoEFCC / BEE Quarterly Returns
    _quarterlyReturns = [
      BeeQuarterlyReturnFiling(
        fiscalQuarter: 'Q2 FY2025-26 (Jul - Sep)',
        reportingPeriodEnd: DateTime(2025, 9, 30),
        totalThroughputMmscm: 142.8,
        routineFlaringMmscm: 0.42,
        blowdownPurgeMmscm: 0.18,
        unburnedSlipTco2e: 485.0,
        vruCaptureMmscm: 1.85,
        ldarAbatedTco2e: 380.0,
        grossScope1Tco2e: 4120.0,
        netScope1Tco2e: 2480.0,
        beeAssignedEmissionIntensityCap: 22.0, // tCO2e/MMSCM
        actualEmissionIntensity: 17.37,        // tCO2e/MMSCM (Compliant!)
        carbonCreditsSurrendered: 0.0,
        complianceStatus: 'SURPLUS (+661 CCCs)',
        isFiledWithMoefcc: true,
        filingTimestamp: DateTime(2025, 10, 14, 16, 30),
        digitalAckNumber: 'BEE-CCTS-2025-Q2-ACK-77401',
      ),
      BeeQuarterlyReturnFiling(
        fiscalQuarter: 'Q1 FY2025-26 (Apr - Jun)',
        reportingPeriodEnd: DateTime(2025, 6, 30),
        totalThroughputMmscm: 138.4,
        routineFlaringMmscm: 0.51,
        blowdownPurgeMmscm: 0.22,
        unburnedSlipTco2e: 540.0,
        vruCaptureMmscm: 1.62,
        ldarAbatedTco2e: 310.0,
        grossScope1Tco2e: 4680.0,
        netScope1Tco2e: 2950.0,
        beeAssignedEmissionIntensityCap: 22.5,
        actualEmissionIntensity: 21.31,
        carbonCreditsSurrendered: 0.0,
        complianceStatus: 'COMPLIANT (+165 CCCs)',
        isFiledWithMoefcc: true,
        filingTimestamp: DateTime(2025, 7, 12, 11, 45),
        digitalAckNumber: 'BEE-CCTS-2025-Q1-ACK-69124',
      ),
    ];
  }

  static String _generateHash(String input) {
    final bytes = utf8.encode(input + DateTime.now().microsecondsSinceEpoch.toString());
    return sha256.convert(bytes).toString().toUpperCase().substring(0, 32);
  }

  // --------------------------------------------------------------------------
  // DYNAMIC COMPUTATIONS & METRICS
  // --------------------------------------------------------------------------

  /// Current GWP factor based on active toggle
  double get _currentGwp => _activeGwpHorizon.value;

  /// Total Scope 1 Direct Emissions from all logged blowdown events (tCO2e)
  double get _totalScope1FromBlowdowns => _blowdownEvents.fold(
        0.0,
        (sum, item) => sum + item.calculateScope1Tco2e(_currentGwp),
      );

  /// Total Methane Slip alone from blowdowns (tCO2e)
  double get _totalSlipFromBlowdowns => _blowdownEvents.fold(
        0.0,
        (sum, item) => sum + item.getSlipTco2e(_currentGwp),
      );

  /// Total Flared CO2 alone from blowdowns (tCO2e)
  double get _totalFlaredCo2FromBlowdowns => _blowdownEvents.fold(
        0.0,
        (sum, item) => sum + item.getFlaredCo2Tons(),
      );

  /// Total Net Carbon Offset Credits accrued from VRU units
  double get _totalVruAccruedCredits => _vruUnits.fold(
        0.0,
        (sum, vru) => sum + vru.calculateNetCreditsAccrued(_currentGwp),
      );

  /// Total Verified Active Carbon Credit Certificates (CCCs) in Registry
  double get _totalActiveRegistryCredits => _tokenLedger
      .where((t) =>
          t.status == TokenRegistryStatus.mintedVerified ||
          t.status == TokenRegistryStatus.activeTrading)
      .fold(0.0, (sum, token) => sum + token.quantityCredits);

  /// Active Registry Valuation in INR Lakhs
  double get _registryValuationLakhs =>
      (_totalActiveRegistryCredits * _spotCccInr) / 100000.0;

  // --------------------------------------------------------------------------
  // USER ACTIONS & DIALOGS
  // --------------------------------------------------------------------------

  void _showAddBlowdownDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            // Calculate instant preview
            final innerRadiusM = (_calcDiameterMm / 1000.0) / 2.0;
            final geomVolM3 = math.pi * math.pow(innerRadiusM, 2) * (_calcLengthKm * 1000.0);
            // Standard conditions volume Sm3: V_std = V_geom * (P_line / 1.01325) * (288.15 / (T_line + 273.15)) * (1 / Z)
            final zFactor = 0.89; // compressibility factor
            final sm3Preview =
                geomVolM3 * (_calcPressureBar / 1.01325) * (288.15 / (_calcTempCelsius + 273.15)) * (1.0 / zFactor);
            final previewRecord = BlowdownEventRecord(
              id: 'PREVIEW',
              sectionName: _calcSectionCtrl.text,
              timestamp: DateTime.now(),
              diameterMm: _calcDiameterMm,
              lengthKm: _calcLengthKm,
              pressureBar: _calcPressureBar,
              tempCelsius: _calcTempCelsius,
              volumeSm3: sm3Preview,
              methaneFraction: _calcMethaneFraction,
              gasDensityKgM3: 0.716,
              routedToFlare: _calcIsFlared,
              capturedByVru: _calcIsVruCaptured,
              combustionEfficiency: _calcCombustionEff,
              statutoryWorkPermit: 'DRAFT',
              loggedBy: 'Field Engineer',
              notes: '',
            );
            final scope1Preview = previewRecord.calculateScope1Tco2e(_currentGwp);
            final abatementPreview = previewRecord.calculateAbatementVsColdVenting(_currentGwp);

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
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
                                color: AppTheme.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.calculate_rounded, color: AppTheme.primaryLight, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Log Scope 1 Blowdown Event',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _calcSectionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pipeline Section / Tag',
                        hintText: 'e.g. Moran SV-02 to SV-03 Depressurization',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Sliders for physics parameters
                    Row(
                      children: [
                        Expanded(
                          child: _buildSliderInput(
                            title: 'Pipe Diameter: ${_calcDiameterMm.toStringAsFixed(0)} mm (${(_calcDiameterMm / 25.4).toStringAsFixed(0)}")',
                            value: _calcDiameterMm,
                            min: 100,
                            max: 1200,
                            onChanged: (val) => setModalState(() => _calcDiameterMm = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSliderInput(
                            title: 'Section Length: ${_calcLengthKm.toStringAsFixed(1)} km',
                            value: _calcLengthKm,
                            min: 0.1,
                            max: 100.0,
                            onChanged: (val) => setModalState(() => _calcLengthKm = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSliderInput(
                            title: 'Line Pressure: ${_calcPressureBar.toStringAsFixed(0)} bar_g',
                            value: _calcPressureBar,
                            min: 5,
                            max: 120,
                            onChanged: (val) => setModalState(() => _calcPressureBar = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSliderInput(
                            title: 'CH₄ Content: ${(_calcMethaneFraction * 100).toStringAsFixed(1)} %',
                            value: _calcMethaneFraction,
                            min: 0.70,
                            max: 0.99,
                            onChanged: (val) => setModalState(() => _calcMethaneFraction = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Mitigation Disposition Toggles
                    Container(
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
                            'Gas Release Disposition Route',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Combusted Flare'),
                                  selected: _calcIsFlared && !_calcIsVruCaptured,
                                  selectedColor: AppTheme.primary,
                                  onSelected: (sel) {
                                    setModalState(() {
                                      _calcIsFlared = true;
                                      _calcIsVruCaptured = false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('VRU Captured (0-Flare)'),
                                  selected: _calcIsVruCaptured,
                                  selectedColor: AppTheme.tertiary,
                                  onSelected: (sel) {
                                    setModalState(() {
                                      _calcIsVruCaptured = true;
                                      _calcIsFlared = false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Cold Vent (Emergency)'),
                                  selected: !_calcIsFlared && !_calcIsVruCaptured,
                                  selectedColor: AppTheme.error,
                                  onSelected: (sel) {
                                    setModalState(() {
                                      _calcIsFlared = false;
                                      _calcIsVruCaptured = false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Calculations Output Summary Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _calcIsVruCaptured
                              ? AppTheme.tertiary.withValues(alpha: 0.6)
                              : AppTheme.primary.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Calculated Release Volume:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              Text(
                                '${NumberFormat('#,##0').format(sm3Preview)} Sm³',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Scope 1 Emission (${_activeGwpHorizon.shortLabel}):',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                              Text(
                                '${scope1Preview.toStringAsFixed(2)} tCO₂e',
                                style: TextStyle(
                                  color: _calcIsVruCaptured ? AppTheme.tertiary : AppTheme.secondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          if (abatementPreview > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Abated vs Cold Venting:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                Text(
                                  '+${abatementPreview.toStringAsFixed(2)} tCO₂e',
                                  style: const TextStyle(
                                    color: AppTheme.tertiary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                        label: const Text(
                          'COMMIT TO SCOPE 1 EMISSION LEDGER',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          final newRecord = BlowdownEventRecord(
                            id: 'BD-2026-${(100 + _blowdownEvents.length).toString()}',
                            sectionName: _calcSectionCtrl.text.isEmpty
                                ? 'Unspecified Pipeline Section'
                                : _calcSectionCtrl.text,
                            timestamp: DateTime.now(),
                            diameterMm: _calcDiameterMm,
                            lengthKm: _calcLengthKm,
                            pressureBar: _calcPressureBar,
                            tempCelsius: _calcTempCelsius,
                            volumeSm3: sm3Preview,
                            methaneFraction: _calcMethaneFraction,
                            gasDensityKgM3: 0.716,
                            routedToFlare: _calcIsFlared,
                            capturedByVru: _calcIsVruCaptured,
                            combustionEfficiency: _calcCombustionEff,
                            statutoryWorkPermit: 'PTW-LIVE-OIL-2026-9901',
                            loggedBy: 'Chief Dispatcher / Shift In-Charge',
                            notes: 'Depressurization logged via Scope 1 Physics Engine.',
                          );
                          setState(() {
                            _blowdownEvents.insert(0, newRecord);
                          });
                          Navigator.pop(modalCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.surfaceCard,
                              content: Text(
                                'Logged ${newRecord.id} (${newRecord.calculateScope1Tco2e(_currentGwp).toStringAsFixed(1)} tCO₂e)',
                                style: const TextStyle(color: AppTheme.tertiary),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddLdarTagDialog() {
    LdarComponentType compType = LdarComponentType.flange;
    final stationCtrl = TextEditingController(text: 'Compressor Station CS-02');
    final tagCtrl = TextEditingController(text: 'TAG-CMP-2026-${_ldarLogs.length + 10}');
    double ppm = 3500.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final severity = ppm >= 10000.0
                ? LdarSeverity.critical
                : (ppm >= 1000.0 ? LdarSeverity.major : LdarSeverity.minor);
            final estimatedKgHr = (ppm / 10000.0) * compType.typicalLeakFactorKgHr * 10.0;
            final annualTco2e = (estimatedKgHr * 8760.0 * _currentGwp) / 1000.0;

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'New LDAR OGI Fugitive Leak Tag',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tagCtrl,
                      decoration: const InputDecoration(labelText: 'Component Tag Number'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stationCtrl,
                      decoration: const InputDecoration(labelText: 'Station / Skid Location'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<LdarComponentType>(
                      value: compType,
                      dropdownColor: AppTheme.surfaceCard,
                      decoration: const InputDecoration(labelText: 'Component Classification'),
                      items: LdarComponentType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t.label, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => compType = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildSliderInput(
                      title: 'Detected Leak Concentration: ${ppm.toStringAsFixed(0)} ppmv (${severity.label})',
                      value: ppm,
                      min: 100,
                      max: 60000,
                      onChanged: (val) => setModalState(() => ppm = val),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: severity.color.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Est. Leak Rate:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              Text(
                                '${estimatedKgHr.toStringAsFixed(4)} kg/hr CH₄',
                                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Annual Impact:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              Text(
                                '${annualTco2e.toStringAsFixed(1)} tCO₂e/yr',
                                style: TextStyle(color: severity.color, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                        label: const Text('ENROLL LDAR LEAK TAG & SCHEDULE REPAIR'),
                        onPressed: () {
                          final newEntry = LdarLogEntry(
                            id: 'LDAR-TAG-${4092 + _ldarLogs.length}',
                            tagNumber: tagCtrl.text.isEmpty ? 'TAG-GEN-99' : tagCtrl.text,
                            componentType: compType,
                            facilityStation: stationCtrl.text.isEmpty ? 'Unspecified Skid' : stationCtrl.text,
                            ogiCameraModel: 'FLIR GF320 (Calibrated)',
                            inspectorName: 'Field Inspection Team',
                            detectedDate: DateTime.now(),
                            concentrationPpm: ppm,
                            estimatedLeakRateKgHr: estimatedKgHr,
                            severity: severity,
                            status: LdarStatus.detected,
                            repairDeadline: DateTime.now().add(Duration(days: severity.maxRepairDays)),
                            repairTechnique: 'Pending initial maintenance review',
                            postRepairPpm: 0.0,
                          );
                          setState(() {
                            _ldarLogs.insert(0, newEntry);
                          });
                          Navigator.pop(modalCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.surfaceCard,
                              content: Text(
                                'Enrolled LDAR Tag ${newEntry.tagNumber} (Deadline: ${severity.maxRepairDays} days)',
                                style: const TextStyle(color: AppTheme.tertiary),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMintCreditsDialog() {
    double mintVolume = 500.0;
    String selectedProject = 'OIL Duliajan Central Gas Gathering Station VRU';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.token_rounded, color: AppTheme.tertiary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Mint Carbon Credit Tokens',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mint new verifiable Carbon Credit Certificates (CCCs) under the BEE Carbon Credit Trading Scheme (CCTS) from verified VRU abatement batches.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    _buildSliderInput(
                      title: 'Quantity: ${mintVolume.toStringAsFixed(0)} CCCs (${mintVolume.toStringAsFixed(0)} tCO₂e)',
                      value: mintVolume,
                      min: 50,
                      max: 2500,
                      onChanged: (val) => setDialogState(() => mintVolume = val),
                    ),
                    const SizedBox(height: 10),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Standard:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              const Text('BEE CCTS (EIA 2006 / MoEFCC)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimated Valuation:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              Text(
                                '₹${NumberFormat('#,##0').format(mintVolume * _spotCccInr)} (@ ₹1,450/CCC)',
                                style: const TextStyle(color: AppTheme.tertiary, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
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
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 16),
                  label: const Text('MINT TO REGISTRY'),
                  onPressed: () {
                    final serial = 'BEE-CCTS-2026-VRU-OIL-${(94822 + _tokenLedger.length)}';
                    final hash = _generateHash('$serial-$mintVolume-DOE-ASSURED');
                    final newToken = CarbonCreditToken(
                      serialNumber: serial,
                      sha256Hash: hash,
                      vintageYear: 2026,
                      quantityCredits: mintVolume,
                      originProject: selectedProject,
                      standardProtocol: 'BEE CCTS (Energy Conservation Act 2022)',
                      status: TokenRegistryStatus.mintedVerified,
                      issueDate: DateTime.now(),
                      accreditedVerifier: 'TÜV SÜD South Asia (Designated Operational Entity)',
                      transactionReference: 'TX-CCTS-MINT-2026-${_tokenLedger.length + 1}',
                    );
                    setState(() {
                      _tokenLedger.insert(0, newToken);
                    });
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.surfaceCard,
                        content: Text(
                          'Minted $mintVolume CCCs to Digital Registry (#$serial)',
                          style: const TextStyle(color: AppTheme.tertiary),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFileQuarterlyReturnDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.primaryLight, size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                'File Statutory BEE Return',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submit the Q3 FY2025-26 statutory compliance filing to Bureau of Energy Efficiency (BEE) & MoEFCC Portal.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 14),
                _buildReturnStatRow('Reporting Period:', 'Q3 FY2025-26 (Oct - Dec)'),
                _buildReturnStatRow('Gas Throughput:', '146.2 MMSCM'),
                _buildReturnStatRow('Gross Scope 1 Released:', '3,920.0 tCO₂e'),
                _buildReturnStatRow('Avoided by VRU + LDAR:', '-2,210.0 tCO₂e'),
                _buildReturnStatRow('Net Corporate Intensity:', '11.69 tCO₂e/MMSCM'),
                _buildReturnStatRow('BEE Mandatory Cap:', '22.00 tCO₂e/MMSCM'),
                const Divider(color: AppTheme.border, height: 20),
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Compliance Surplus: 1,507 CCCs accrued for trading.',
                        style: TextStyle(color: AppTheme.tertiary, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
              label: const Text('TRANSMIT TO BEE PORTAL'),
              onPressed: () {
                final newFiling = BeeQuarterlyReturnFiling(
                  fiscalQuarter: 'Q3 FY2025-26 (Oct - Dec)',
                  reportingPeriodEnd: DateTime(2025, 12, 31),
                  totalThroughputMmscm: 146.2,
                  routineFlaringMmscm: 0.38,
                  blowdownPurgeMmscm: 0.16,
                  unburnedSlipTco2e: 420.0,
                  vruCaptureMmscm: 1.94,
                  ldarAbatedTco2e: 410.0,
                  grossScope1Tco2e: 3920.0,
                  netScope1Tco2e: 1710.0,
                  beeAssignedEmissionIntensityCap: 22.0,
                  actualEmissionIntensity: 11.69,
                  carbonCreditsSurrendered: 0.0,
                  complianceStatus: 'SURPLUS (+1,507 CCCs)',
                  isFiledWithMoefcc: true,
                  filingTimestamp: DateTime.now(),
                  digitalAckNumber: 'BEE-CCTS-2025-Q3-ACK-${DateTime.now().millisecondsSinceEpoch % 100000}',
                );
                setState(() {
                  _quarterlyReturns.insert(0, newFiling);
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.surfaceCard,
                    content: Text(
                      'Successfully Transmitted Return to BEE Portal! Ack: ${newFiling.digitalAckNumber}',
                      style: const TextStyle(color: AppTheme.tertiary),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  static Widget _buildReturnStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 11, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildSliderInput({
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.surfaceContainerHigh,
            thumbColor: AppTheme.primaryLight,
            overlayColor: AppTheme.primary.withValues(alpha: 0.2),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // ROOT BUILD METHOD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hydrocarbon Flaring & Carbon Accounting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(
              'Article 6 Paris Agreement • BEE CCTS • GHG Protocol Scope 1',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          // GWP Horizon Selection Pill
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _activeGwpHorizon.color.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: GwpHorizon.values.map((h) {
                  final isSelected = _activeGwpHorizon == h;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _activeGwpHorizon = h;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? h.color : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        h.shortLabel,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_customize_rounded, size: 18), text: 'Executive Overview'),
            Tab(icon: Icon(Icons.calculate_rounded, size: 18), text: 'Scope 1 Engine'),
            Tab(icon: Icon(Icons.local_fire_department_rounded, size: 18), text: 'CH₄ Slip & DRE'),
            Tab(icon: Icon(Icons.camera_alt_rounded, size: 18), text: 'LDAR & OGI Logbook'),
            Tab(icon: Icon(Icons.token_rounded, size: 18), text: 'CCTS Registry & BEE Filing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExecutiveOverviewTab(),
          _buildScope1EngineTab(),
          _buildMethaneSlipTab(),
          _buildLdarLogbookTab(),
          _buildCctsRegistryTab(),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: EXECUTIVE OVERVIEW & LIVE ACCOUNTING
  // ==========================================================================

  Widget _buildExecutiveOverviewTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statutory Policy Header Banner
            _buildStatutoryBanner(),
            const SizedBox(height: 16),

            // Top KPI Metric Cards Grid
            _buildKpiMetricsGrid(),
            const SizedBox(height: 16),

            // Emissions Breakdown Chart & Methane Slip Ratio
            _buildEmissionsBreakdownChart(),
            const SizedBox(height: 16),

            // Real-Time Flaring & Purge Stream Telemetry
            _buildLiveStreamTelemetrySection(),
            const SizedBox(height: 16),

            // Recent Statutory Return & Compliance Health
            _buildLatestComplianceCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatutoryBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.surfaceCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.public_rounded, color: AppTheme.primaryLight, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PARIS ART. 6 / BEE CCTS',
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _activeGwpHorizon.subtext,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Oil India Limited • Upper Assam Pipeline Gas Asset',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'GHG Protocol Scope 1 Direct Emissions • Zero Routine Flaring by 2030 (World Bank ZRF Initiative)',
                  style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.9), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'SCOPE 1 EMISSIONS',
                value: '${_totalScope1FromBlowdowns.toStringAsFixed(1)} t',
                unit: 'tCO₂e (${_activeGwpHorizon.shortLabel})',
                icon: Icons.cloud_off_rounded,
                color: AppTheme.error,
                subtext: 'Pipeline blowdowns & venting',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'VRU AVOIDED FLARING',
                value: '+${_totalVruAccruedCredits.toStringAsFixed(0)} t',
                unit: 'tCO₂e Net Abatement',
                icon: Icons.energy_savings_leaf_rounded,
                color: AppTheme.tertiary,
                subtext: 'Captured by 0-flare compressors',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'VERIFIED CCC TOKENS',
                value: NumberFormat('#,##0').format(_totalActiveRegistryCredits),
                unit: 'Credits (1 CCC = 1 tCO₂e)',
                icon: Icons.token_rounded,
                color: AppTheme.primaryLight,
                subtext: 'BEE CCTS Registry balance',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'CARBON ASSET VALUE',
                value: '₹${_registryValuationLakhs.toStringAsFixed(2)} L',
                unit: 'INR Lakhs (@ ₹1,450/CCC)',
                icon: Icons.currency_rupee_rounded,
                color: AppTheme.secondary,
                subtext: 'IEX Carbon spot trading index',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
                  fontSize: 10,
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
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildEmissionsBreakdownChart() {
    final flaredCo2 = _totalFlaredCo2FromBlowdowns;
    final slipCh4 = _totalSlipFromBlowdowns;
    final vruAvoided = _totalVruAccruedCredits;

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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direct Emissions vs Abatement Distribution',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Combusted CO₂ vs Unburned CH₄ Slip vs VRU Recovery',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _activeGwpHorizon.badgeColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _activeGwpHorizon.color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _activeGwpHorizon.shortLabel,
                  style: TextStyle(
                    color: _activeGwpHorizon.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart + Legend Row
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: [
                        PieChartSectionData(
                          value: math.max(1.0, flaredCo2),
                          color: const Color(0xFFFFB95F),
                          title: '${((flaredCo2 / (flaredCo2 + slipCh4 + vruAvoided)) * 100).toStringAsFixed(0)}%',
                          radius: 38,
                          titleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 10),
                        ),
                        PieChartSectionData(
                          value: math.max(1.0, slipCh4),
                          color: const Color(0xFFEF4444),
                          title: '${((slipCh4 / (flaredCo2 + slipCh4 + vruAvoided)) * 100).toStringAsFixed(0)}%',
                          radius: 42,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10),
                        ),
                        PieChartSectionData(
                          value: math.max(1.0, vruAvoided),
                          color: const Color(0xFF4EDEA3),
                          title: '${((vruAvoided / (flaredCo2 + slipCh4 + vruAvoided)) * 100).toStringAsFixed(0)}%',
                          radius: 38,
                          titleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartLegendItem(
                        color: const Color(0xFFFFB95F),
                        label: 'Combusted Flared CO₂',
                        value: '${flaredCo2.toStringAsFixed(1)} tCO₂',
                      ),
                      const SizedBox(height: 8),
                      _buildChartLegendItem(
                        color: const Color(0xFFEF4444),
                        label: 'Unburned CH₄ Slip (Slip Hazard)',
                        value: '${slipCh4.toStringAsFixed(1)} tCO₂e',
                      ),
                      const SizedBox(height: 8),
                      _buildChartLegendItem(
                        color: const Color(0xFF4EDEA3),
                        label: 'VRU Avoided Flaring (Offset)',
                        value: '${vruAvoided.toStringAsFixed(1)} tCO₂e',
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

  Widget _buildChartLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              Text(
                value,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStreamTelemetrySection() {
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
              const Text(
                'Live Flare Headers & Pilot Burners',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: AppTheme.tertiary, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'SCADA LIVE',
                      style: TextStyle(color: AppTheme.tertiary, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: FlaringStreamType.values.map((stream) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: stream.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(stream.icon, color: stream.color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stream.label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(
                            'Header: ${stream.operatingPressureBar} bar • DRE: ${(stream.typicalDestructionEfficiency * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: stream.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        stream.shortCode,
                        style: TextStyle(
                          color: stream.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestComplianceCard() {
    final latestReturn = _quarterlyReturns.first;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.tertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.tertiary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      latestReturn.fiscalQuarter,
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      latestReturn.complianceStatus,
                      style: const TextStyle(color: AppTheme.tertiary, fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Actual Emission Intensity: ${latestReturn.actualEmissionIntensity} tCO₂e/MMSCM (Cap: ${latestReturn.beeAssignedEmissionIntensityCap})',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ack: ${latestReturn.digitalAckNumber} • MoEFCC & BEE Portal Sync',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: SCOPE 1 ENGINE & BLOWDOWN CALCULATOR
  // ==========================================================================

  Widget _buildScope1EngineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Physics Engine Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scope 1 Pipeline Blowdown Engine',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    r'tCO₂e = (V_gas × ρ_gas × f_CH₄ × GWP_CH₄) / 1000',
                    style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('LOG EVENT', style: TextStyle(fontSize: 12)),
                onPressed: _showAddBlowdownDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Formula Explanatory Card
          _buildFormulaCard(),
          const SizedBox(height: 16),

          // Logged Blowdown Events List
          const Text(
            'Audited Blowdown & Purge Registry',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _blowdownEvents.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final ev = _blowdownEvents[i];
              return _buildBlowdownEventCard(ev);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaCard() {
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
              const Icon(Icons.functions_rounded, color: AppTheme.primaryLight, size: 20),
              const SizedBox(width: 8),
              const Text(
                'GHG Protocol / API Compendium 2021 Formulation',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'GWP_CH4 = ${_currentGwp.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Direct depressurization of high-pressure pipeline segments releases standard volume V_gas. '
            'Combustion in flares converts CH₄ into CO₂ (MW ratio 44/16 = 2.744) with typical efficiency η_comb ≈ 98.5%. '
            'Uncombusted methane slip (1 - η_comb) carries the full Global Warming Potential penalty (28× or 84×). '
            'Venting without ignition releases pure CH₄ directly to the troposphere.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBlowdownEventCard(BlowdownEventRecord record) {
    final scope1 = record.calculateScope1Tco2e(_currentGwp);
    final isZeroFlared = record.capturedByVru;
    final isColdVent = !record.routedToFlare && !record.capturedByVru;

    Color badgeColor = AppTheme.secondary;
    String badgeText = 'FLARED COMB.';
    if (isZeroFlared) {
      badgeColor = AppTheme.tertiary;
      badgeText = '0-FLARE VRU';
    } else if (isColdVent) {
      badgeColor = AppTheme.error;
      badgeText = 'COLD VENT';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.id,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ),
              Text(
                '${scope1.toStringAsFixed(2)} tCO₂e',
                style: TextStyle(
                  color: isZeroFlared ? AppTheme.tertiary : AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.sectionName,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildDetailMetric('Volume', '${NumberFormat('#,##0').format(record.volumeSm3)} Sm³'),
              _buildDetailMetric('Pressure', '${record.pressureBar} bar'),
              _buildDetailMetric('CH₄ Content', '${(record.methaneFraction * 100).toStringAsFixed(1)}%'),
              _buildDetailMetric('Permit', record.statutoryWorkPermit),
            ],
          ),
          const Divider(color: AppTheme.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(record.timestamp),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
              Text(
                'Logged: ${record.loggedBy}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMetric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
          Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: METHANE SLIP & FLARE DESTRUCTION EFFICIENCY (DRE)
  // ==========================================================================

  Widget _buildMethaneSlipTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildSlipPhysicsHeader(),
          const SizedBox(height: 16),

          // Interactive 20-Yr vs 100-Yr Horizon Comparison Visualizer
          _buildGwpTimeHorizonVisualizer(),
          const SizedBox(height: 16),

          // Destruction Efficiency Sensitivity Curve
          _buildDreSensitivityChart(),
          const SizedBox(height: 16),

          // Operational Mitigation Strategy
          _buildVruOffsetCard(),
        ],
      ),
    );
  }

  Widget _buildSlipPhysicsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.whatshot_rounded, color: AppTheme.error, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Methane Slip vs Combusted Flaring',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Flame Tip Destruction & Removal Efficiency (DRE) Kinetics',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Even at 98.0% DRE, unburned methane slip accounts for a disproportionate share of global warming impact. '
            'Because pure methane traps significantly more infrared radiation than carbon dioxide in its first two decades, '
            'small drops in combustion efficiency (e.g. from crosswinds or improper steam/air assist) radically increase corporate climate liability.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildGwpTimeHorizonVisualizer() {
    // Emissions of 1,000 kg CH4
    const ch4Kg = 1000.0;
    const dre = 0.985;
    final flaredCo2Kg = ch4Kg * dre * (44.01 / 16.04); // 2702.8 kg CO2
    final slipKg = ch4Kg * (1 - dre); // 15 kg CH4

    // 100-Yr GWP: CO2 * 1 + slip * 28
    final gwp100Total = (flaredCo2Kg + slipKg * 28.0) / 1000.0;
    // 20-Yr GWP: CO2 * 1 + slip * 84
    final gwp20Total = (flaredCo2Kg + slipKg * 84.0) / 1000.0;

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
          const Text(
            'Impact of 1,000 kg Methane Flared @ 98.5% DRE',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Direct comparison of Statutory 100-Year vs Near-Term 20-Year Global Warming Potential',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GWP₁₀₀ (Factor = 28)', style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${gwp100Total.toStringAsFixed(2)} tCO₂e',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Flared CO₂: ${(flaredCo2Kg / 1000).toStringAsFixed(2)} t\nSlip CH₄: ${((slipKg * 28) / 1000).toStringAsFixed(2)} t',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GWP₂₀ (Factor = 84)', style: TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${gwp20Total.toStringAsFixed(2)} tCO₂e',
                        style: const TextStyle(color: AppTheme.secondary, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Flared CO₂: ${(flaredCo2Kg / 1000).toStringAsFixed(2)} t\nSlip CH₄: ${((slipKg * 84) / 1000).toStringAsFixed(2)} t',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
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

  Widget _buildDreSensitivityChart() {
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
          const Text(
            'Flare Tip Destruction Efficiency (DRE) Sensitivity',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total emissions (tCO₂e) per ton of CH₄ sent to flare as DRE degrades from 99.5% to 85%',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 5,
                      getTitlesWidget: (val, meta) {
                        return Text('${val.toInt()}%', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        return Text('${val.toInt()}t', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 85,
                maxX: 100,
                minY: 2,
                maxY: 16,
                lineBarsData: [
                  // GWP20 line
                  LineChartBarData(
                    spots: const [
                      FlSpot(85, 14.9),
                      FlSpot(90, 10.9),
                      FlSpot(95, 6.8),
                      FlSpot(98, 4.3),
                      FlSpot(99.5, 3.1),
                    ],
                    isCurved: true,
                    color: AppTheme.secondary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                  // GWP100 line
                  LineChartBarData(
                    spots: const [
                      FlSpot(85, 6.5),
                      FlSpot(90, 5.2),
                      FlSpot(95, 4.0),
                      FlSpot(98, 3.2),
                      FlSpot(99.5, 2.8),
                    ],
                    isCurved: true,
                    color: AppTheme.primaryLight,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 3, color: AppTheme.secondary),
              const SizedBox(width: 6),
              const Text('GWP₂₀ Sensitivity', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              const SizedBox(width: 20),
              Container(width: 12, height: 3, color: AppTheme.primaryLight),
              const SizedBox(width: 6),
              const Text('GWP₁₀₀ Statutory Sensitivity', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVruOffsetCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zero-Flaring VRU Solution',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text(
                  'By recovering 100% of blowdown & flash gas via Vapor Recovery Compressor units, '
                  'methane slip is eliminated entirely, qualifying for high-integrity carbon credit issuance under BEE CCTS & Paris Article 6.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: LDAR & OPTICAL GAS IMAGING (OGI) LOGBOOK
  // ==========================================================================

  Widget _buildLdarLogbookTab() {
    // Filtered LDAR entries
    final filtered = _ldarLogs.where((entry) {
      final matchesQuery = _ldarSearchQuery.isEmpty ||
          entry.tagNumber.toLowerCase().contains(_ldarSearchQuery.toLowerCase()) ||
          entry.facilityStation.toLowerCase().contains(_ldarSearchQuery.toLowerCase()) ||
          entry.componentType.label.toLowerCase().contains(_ldarSearchQuery.toLowerCase());
      final matchesSeverity = _selectedLdarSeverity == null || entry.severity == _selectedLdarSeverity;
      return matchesQuery && matchesSeverity;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add Tag Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LDAR Optical Gas Imaging Logbook',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'EPA Method 21 / FLIR GF320 Thermography Register',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                label: const Text('NEW TAG', style: TextStyle(fontSize: 12)),
                onPressed: _showAddLdarTagDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // VRU Skid Live Hardware Cards
          const Text(
            'Zero-Flaring Vapor Recovery Compressor (VRU) Skids',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _vruUnits.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final vru = _vruUnits[i];
              return _buildVruSkidCard(vru);
            },
          ),
          const SizedBox(height: 16),

          // Search & Filter Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search component tag, skid or location...',
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _ldarSearchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<LdarSeverity?>(
                value: _selectedLdarSeverity,
                dropdownColor: AppTheme.surfaceCard,
                hint: const Text('All Severities', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Severities', style: TextStyle(fontSize: 12))),
                  ...LdarSeverity.values.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 12)));
                  }),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedLdarSeverity = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // LDAR Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final entry = filtered[i];
              return _buildLdarCard(entry);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVruSkidCard(VruCompressorUnit vru) {
    final netCredits = vru.calculateNetCreditsAccrued(_currentGwp);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4)),
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
                      color: AppTheme.tertiary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.compress_rounded, color: AppTheme.tertiary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    vru.unitName,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('ONLINE', style: TextStyle(color: AppTheme.tertiary, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(vru.stationLocation, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDetailMetric('Suction / Disch.', '${vru.suctionPressureBar} / ${vru.dischargePressureBar} bar'),
              _buildDetailMetric('Flow Rate', '${NumberFormat('#,##0').format(vru.recoveryFlowSm3Hr)} Sm³/h'),
              _buildDetailMetric('Motor Power', '${vru.motorPowerKw} kW'),
              _buildDetailMetric('Offset Accrued', '+${netCredits.toStringAsFixed(0)} tCO₂e'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLdarCard(LdarLogEntry entry) {
    final annualTco2e = entry.calculateAnnualAbatementTco2e(_currentGwp);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: entry.severity.color.withValues(alpha: 0.3)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: entry.status.badgeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(entry.status.icon, color: entry.status.color, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          entry.status.label,
                          style: TextStyle(color: entry.status.color, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.tagNumber,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                  ),
                ],
              ),
              Text(
                '${entry.concentrationPpm.toStringAsFixed(0)} ppmv',
                style: TextStyle(color: entry.severity.color, fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${entry.componentType.label} • ${entry.facilityStation}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDetailMetric('Camera', entry.ogiCameraModel),
              _buildDetailMetric('Annual Abatement', '+${annualTco2e.toStringAsFixed(1)} tCO₂e'),
              _buildDetailMetric('SLA Deadline', DateFormat('dd MMM yyyy').format(entry.repairDeadline)),
            ],
          ),
          const Divider(color: AppTheme.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Action: ${entry.repairTechnique}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (entry.status != LdarStatus.verifiedCompliant)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    // Quick state transition to repaired
                    setState(() {
                      final idx = _ldarLogs.indexOf(entry);
                      if (idx != -1) {
                        _ldarLogs[idx] = LdarLogEntry(
                          id: entry.id,
                          tagNumber: entry.tagNumber,
                          componentType: entry.componentType,
                          facilityStation: entry.facilityStation,
                          ogiCameraModel: entry.ogiCameraModel,
                          inspectorName: entry.inspectorName,
                          detectedDate: entry.detectedDate,
                          concentrationPpm: entry.concentrationPpm,
                          estimatedLeakRateKgHr: entry.estimatedLeakRateKgHr,
                          severity: entry.severity,
                          status: LdarStatus.verifiedCompliant,
                          repairDeadline: entry.repairDeadline,
                          repairDate: DateTime.now(),
                          repairTechnique: 'Gland repacked & confirmed 0 ppmv by OGI',
                          postRepairPpm: 0.0,
                        );
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.surfaceCard,
                        content: Text(
                          'Marked ${entry.tagNumber} as VERIFIED ZERO-LEAK',
                          style: const TextStyle(color: AppTheme.tertiary),
                        ),
                      ),
                    );
                  },
                  child: const Text('MARK REPAIRED', style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 5: CARBON CREDIT TOKEN REGISTRY & STATUTORY BEE FILING
  // ==========================================================================

  Widget _buildCctsRegistryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Registry Actions Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BEE CCTS Digital Token Ledger',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Digital MRV • SHA-256 Tamper-Evident Offset Registry',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tertiary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.token_rounded, size: 16),
                    label: const Text('MINT CCC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: _showMintCreditsDialog,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: const Text('FILE RETURN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: _showFileQuarterlyReturnDialog,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Token Registry List
          const Text(
            'Cryptographic Token Ledger (1 CCC = 1 tCO₂e)',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tokenLedger.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final token = _tokenLedger[i];
              return _buildTokenCard(token);
            },
          ),
          const SizedBox(height: 20),

          // Statutory Quarterly Returns History
          const Text(
            'Statutory MoEFCC / BEE Quarterly Returns History',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quarterlyReturns.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final ret = _quarterlyReturns[i];
              return _buildQuarterlyReturnCard(ret);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTokenCard(CarbonCreditToken token) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: token.status.color.withValues(alpha: 0.3)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: token.status.badgeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      token.status.label,
                      style: TextStyle(color: token.status.color, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vintage ${token.vintageYear}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
              Text(
                '${NumberFormat('#,##0').format(token.quantityCredits)} CCCs',
                style: TextStyle(
                  color: token.status.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            token.originProject,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Serial: ${token.serialNumber}',
            style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 4),
          Text(
            'SHA-256: ${token.sha256Hash}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(color: AppTheme.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verifier: ${token.accreditedVerifier}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(token.issueDate),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterlyReturnCard(BeeQuarterlyReturnFiling filing) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                filing.fiscalQuarter,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  filing.complianceStatus,
                  style: const TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDetailMetric('Throughput', '${filing.totalThroughputMmscm} MMSCM'),
              _buildDetailMetric('Routine Flare', '${filing.routineFlaringMmscm} MMSCM'),
              _buildDetailMetric('VRU Capture', '${filing.vruCaptureMmscm} MMSCM'),
              _buildDetailMetric('Intensity', '${filing.actualEmissionIntensity} / ${filing.beeAssignedEmissionIntensityCap}'),
            ],
          ),
          const Divider(color: AppTheme.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Digital Ack: ${filing.digitalAckNumber}',
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontFamily: 'monospace'),
              ),
              if (filing.filingTimestamp != null)
                Text(
                  'Filed: ${DateFormat('dd MMM yyyy').format(filing.filingTimestamp!)}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
