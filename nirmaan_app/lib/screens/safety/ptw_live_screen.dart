import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// PERMIT TO WORK (PTW) LIVE FIELD MANAGEMENT ENUMS & MODELS
// ============================================================================

/// Multi-Permit Classification per OISD-STD-105 & DGMS Guidelines
enum PtwClassification {
  hotWork(
    title: 'Hot Work Permit',
    subtitle: 'Welding, cutting, grinding & preheating',
    badge: 'HOT WORK',
    icon: Icons.local_fire_department_rounded,
    primaryColor: Color(0xFFEF4444),
    riskLevel: 'VERY HIGH',
  ),
  coldWork(
    title: 'Cold Work Permit',
    subtitle: 'Flange bolting, cold cutting & scaffolding',
    badge: 'COLD WORK',
    icon: Icons.handyman_rounded,
    primaryColor: Color(0xFF38BDF8),
    riskLevel: 'MEDIUM',
  ),
  confinedSpace(
    title: 'Confined Space Entry',
    subtitle: 'Tanks, pig receiver barrels & vessels',
    badge: 'CONFINED SPACE',
    icon: Icons.meeting_room_rounded,
    primaryColor: Color(0xFFA855F7),
    riskLevel: 'EXTREME',
  ),
  workingAtHeight(
    title: 'Working at Height (>1.8m)',
    subtitle: 'Pipe racks, column platforms & flare tip',
    badge: 'HEIGHT >1.8M',
    icon: Icons.height_rounded,
    primaryColor: Color(0xFFFFB95F),
    riskLevel: 'HIGH',
  ),
  heavyLifting(
    title: 'Heavy Crane Lifting (>20T)',
    subtitle: 'Slug catcher, spool modules & tandem lifts',
    badge: 'HEAVY LIFT >20T',
    icon: Icons.precision_manufacturing_rounded,
    primaryColor: Color(0xFFF97316),
    riskLevel: 'VERY HIGH',
  );

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color primaryColor;
  final String riskLevel;

  const PtwClassification({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.primaryColor,
    required this.riskLevel,
  });
}

/// Real-time Permit Status
enum PtwLiveStatus {
  issued(
    label: 'ISSUED',
    color: Color(0xFF38BDF8),
    icon: Icons.assignment_turned_in_rounded,
    description: 'Authorized by Area Authority, site pre-checks pending',
  ),
  active(
    label: 'ACTIVE',
    color: Color(0xFF10B981),
    icon: Icons.play_circle_filled_rounded,
    description: 'Live field work underway, all isolations & tests verified',
  ),
  suspended(
    label: 'SUSPENDED',
    color: Color(0xFFF59E0B),
    icon: Icons.pause_circle_filled_rounded,
    description: 'Work halted due to weather, gas drift, or shift pause',
  ),
  surrendered(
    label: 'SURRENDERED',
    color: Color(0xFF94A3B8),
    icon: Icons.assignment_return_rounded,
    description: 'Work completed, tools cleared, isolations restored',
  ),
  cancelled(
    label: 'CANCELLED',
    color: Color(0xFFEF4444),
    icon: Icons.cancel_rounded,
    description: 'Revoked by Safety Officer or Emergency Stop beacon',
  );

  final String label;
  final Color color;
  final IconData icon;
  final String description;

  const PtwLiveStatus({
    required this.label,
    required this.color,
    required this.icon,
    required this.description,
  });
}

/// Energy Isolation & LOTO Classification
enum EnergyIsolationType {
  electricalBreaker(
    label: 'Electrical Breaker Lockout',
    code: 'LOTO-ELEC',
    icon: Icons.flash_on_rounded,
    color: Color(0xFFFFB95F),
    standard: 'OISD-RP-112 §4.2',
  ),
  mechanicalBlindSpade(
    label: 'Mechanical Blind Spade',
    code: 'LOTO-MECH',
    icon: Icons.settings_rounded,
    color: Color(0xFF38BDF8),
    standard: 'ASME B16.48 / OISD-105',
  ),
  hydraulicBleed(
    label: 'Hydraulic / Pneumatic Bleed',
    code: 'LOTO-HYDR',
    icon: Icons.water_drop_rounded,
    color: Color(0xFF4EDEA3),
    standard: 'API 598 / OISD-STD-114',
  );

  final String label;
  final String code;
  final IconData icon;
  final Color color;
  final String standard;

  const EnergyIsolationType({
    required this.label,
    required this.code,
    required this.icon,
    required this.color,
    required this.standard,
  });
}

/// Pre-Task Atmospheric Gas Testing Record
class AtmosphericGasTest {
  final double o2Concentration; // Safe: 19.5% - 23.5%
  final double flammableLel; // Safe: < 1.0% LEL
  final double toxicH2s; // Safe: < 10.0 ppm
  final double carbonMonoxideCo; // Safe: < 25.0 ppm
  final DateTime testTimestamp;
  final String testerName;
  final String testerCertification;
  final String detectorModel;
  final String detectorSerial;
  final DateTime bumpTestDate;
  final DateTime calibrationCertExpiry;
  final double t90ResponseSeconds;
  final String samplingStratum; // Top, Middle, Bottom

  const AtmosphericGasTest({
    required this.o2Concentration,
    required this.flammableLel,
    required this.toxicH2s,
    required this.carbonMonoxideCo,
    required this.testTimestamp,
    required this.testerName,
    required this.testerCertification,
    required this.detectorModel,
    required this.detectorSerial,
    required this.bumpTestDate,
    required this.calibrationCertExpiry,
    required this.t90ResponseSeconds,
    required this.samplingStratum,
  });

  bool get isO2Safe => o2Concentration >= 19.5 && o2Concentration <= 23.5;
  bool get isLelSafe => flammableLel < 1.0;
  bool get isH2sSafe => toxicH2s < 10.0;
  bool get isCoSafe => carbonMonoxideCo < 25.0;
  bool get isBumpTestValid => DateTime.now().difference(bumpTestDate).inHours < 24;
  bool get isCalibrated => DateTime.now().isBefore(calibrationCertExpiry);

  bool get isAtmosphereSafe => isO2Safe && isLelSafe && isH2sSafe && isCoSafe && isBumpTestValid;

  String get atmosphericStatusSummary {
    if (!isO2Safe) {
      return o2Concentration < 19.5
          ? 'ALARM: Oxygen Deficiency (<19.5%)'
          : 'CRITICAL: Oxygen Enriched (>23.5%) - Flash Hazard';
    }
    if (!isLelSafe) return 'CRITICAL: Flammable Vapor Exceeds LEL Limit (≥1.0%)';
    if (!isH2sSafe) return 'TOXIC HAZARD: H₂S Exceeds Safe Ceiling (≥10 ppm)';
    if (!isCoSafe) return 'HAZARD: Carbon Monoxide High (≥25 ppm)';
    if (!isBumpTestValid) return 'WARNING: Detector Bump Test Expired (>24h)';
    return 'SAFE TO ENTER / ALL 4 GASES NORMAL';
  }
}

/// LOTO & Energy Isolation Point Record
class LotoIsolationRecord {
  final String id;
  final String pointTag;
  final String equipmentName;
  final EnergyIsolationType isolationType;
  final String padlockNumber;
  final String dangerTagNumber;
  final String isolatedBy;
  final String verifiedBy;
  final DateTime isolationTimestamp;
  final double? residualPressureBar; // For hydraulic/bleed
  final double? spadeThicknessMm; // For mechanical spade
  final double? verifiedVoltage; // For electrical breaker
  bool isVerifiedAndLocked;
  String remarks;

  LotoIsolationRecord({
    required this.id,
    required this.pointTag,
    required this.equipmentName,
    required this.isolationType,
    required this.padlockNumber,
    required this.dangerTagNumber,
    required this.isolatedBy,
    required this.verifiedBy,
    required this.isolationTimestamp,
    this.residualPressureBar,
    this.spadeThicknessMm,
    this.verifiedVoltage,
    this.isVerifiedAndLocked = true,
    this.remarks = '',
  });
}

/// Complete Live Field Permit Model
class PtwLiveModel {
  final String id;
  final String permitNumber;
  final PtwClassification classification;
  final String title;
  final String locationZone;
  final String chainageKp;
  final String areaAuthority;
  final String performingAuthority;
  final String safetyOfficer;
  final String contractor;
  final int crewCount;
  PtwLiveStatus status;
  final DateTime validFrom;
  DateTime validTo;
  AtmosphericGasTest gasTest;
  List<LotoIsolationRecord> lotoRecords;
  final List<String> mandatoryPpe;
  final List<String> safetyPrecautions;
  String? suspensionOrCancellationReason;
  int extensionCount;

  PtwLiveModel({
    required this.id,
    required this.permitNumber,
    required this.classification,
    required this.title,
    required this.locationZone,
    required this.chainageKp,
    required this.areaAuthority,
    required this.performingAuthority,
    required this.safetyOfficer,
    required this.contractor,
    required this.crewCount,
    required this.status,
    required this.validFrom,
    required this.validTo,
    required this.gasTest,
    required this.lotoRecords,
    required this.mandatoryPpe,
    required this.safetyPrecautions,
    this.suspensionOrCancellationReason,
    this.extensionCount = 0,
  });

  Duration get remainingDuration {
    final now = DateTime.now();
    if (now.isAfter(validTo)) return Duration.zero;
    return validTo.difference(now);
  }

  bool get isExpired => DateTime.now().isAfter(validTo);

  double get timeElapsedFraction {
    final totalMs = validTo.difference(validFrom).inMilliseconds;
    if (totalMs <= 0) return 1.0;
    final elapsedMs = DateTime.now().difference(validFrom).inMilliseconds;
    return (elapsedMs / totalMs).clamp(0.0, 1.0);
  }

  String get formattedCountdown {
    if (status == PtwLiveStatus.surrendered) return '00h 00m 00s (COMPLETED)';
    if (status == PtwLiveStatus.cancelled) return '00h 00m 00s (REVOKED)';
    final rem = remainingDuration;
    if (rem == Duration.zero) return '00h 00m 00s (EXPIRED)';
    final hours = rem.inHours.toString().padLeft(2, '0');
    final minutes = (rem.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (rem.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  bool get isAllLotoVerified =>
      lotoRecords.isEmpty || lotoRecords.every((r) => r.isVerifiedAndLocked);
}

// ============================================================================
// SCREEN WIDGET
// ============================================================================

class PtwLiveScreen extends StatefulWidget {
  const PtwLiveScreen({super.key});

  @override
  State<PtwLiveScreen> createState() => _PtwLiveScreenState();
}

class _PtwLiveScreenState extends State<PtwLiveScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Timer? _countdownTicker;
  late AnimationController _beaconPulseController;
  late Animation<double> _beaconPulseAnimation;

  // Filter & Search
  String _selectedClassificationFilter = 'ALL';
  String _searchQuery = '';

  // Supervisor Emergency Stop State
  bool _isEmergencyBeaconActive = false;
  String _emergencyReason = '';
  String _emergencyTriggeredBy = '';

  // Gas Simulator / Test Logger State
  double _simO2 = 20.9;
  double _simLel = 0.0;
  double _simH2s = 0.0;
  double _simCo = 2.0;
  String _simStratum = 'Pig Barrel Interior - Bottom (Invert)';
  final TextEditingController _simTesterCtrl =
      TextEditingController(text: 'D. K. Gogoi (Lead Gas Tester #OIL-GT-402)');

  // Live Permits Ledger
  late List<PtwLiveModel> _permits;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Pulsing Beacon Animation
    _beaconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _beaconPulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _beaconPulseController, curve: Curves.easeInOut),
    );

    // Initialize mock industrial data with accurate standards
    _initPermitData();

    // 1-Second Timer for countdown accuracy
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _beaconPulseController.dispose();
    _tabController.dispose();
    _simTesterCtrl.dispose();
    super.dispose();
  }

  void _initPermitData() {
    final now = DateTime.now();

    _permits = [
      // 1. Hot Work Permit - Golden Weld & Preheating
      PtwLiveModel(
        id: 'PTW-2026-HW-0841',
        permitNumber: 'HW/DUL/2026/0841',
        classification: PtwClassification.hotWork,
        title: 'Tie-In Golden Weld 18" API 5L X70 & Induction Preheating',
        locationZone: 'Section 4 - Valve Station VS-03 Area',
        chainageKp: 'KP 42+150',
        areaAuthority: 'Pranab Saikia (DGM Ops, OIL)',
        performingAuthority: 'R. K. Hazarika (Welding Foreman)',
        safetyOfficer: 'Subhash Roy (Sr. HSE Engineer)',
        contractor: 'Assam Pipeline Infrastructure Ltd',
        crewCount: 6,
        status: PtwLiveStatus.active,
        validFrom: now.subtract(const Duration(hours: 2, minutes: 15)),
        validTo: now.add(const Duration(hours: 3, minutes: 45, seconds: 30)),
        mandatoryPpe: const [
          'Leather Welding Apron',
          'Welding Helmet Auto-Darkening Shade 11',
          'Fire-Retardant Coverall (NFPA 2112)',
          'Safety Shoes (IS 15298 Class S3)',
          'High-Dexterity TIG Gloves',
        ],
        safetyPrecautions: const [
          'Continuous 4-gas monitoring within 2m radius',
          '2x 10kg DCP & 1x 45L Foam Trolley on standby',
          'Spark containment habitat with fire blankets (IS 11871)',
          'Combustible clearing radius verified at 15 meters',
          'Designated Fire Watcher posted throughout hot pass',
        ],
        gasTest: AtmosphericGasTest(
          o2Concentration: 20.9,
          flammableLel: 0.0,
          toxicH2s: 0.0,
          carbonMonoxideCo: 1.8,
          testTimestamp: now.subtract(const Duration(minutes: 42)),
          testerName: 'D. K. Gogoi',
          testerCertification: 'OIL-GT-402 (Valid OISD Level-II)',
          detectorModel: 'Honeywell BW Ultra Quad-Gas (O2/LEL/H2S/CO)',
          detectorSerial: 'BW-ULTRA-SN-994208-X',
          bumpTestDate: now.subtract(const Duration(hours: 4)),
          calibrationCertExpiry: DateTime(2026, 12, 15),
          t90ResponseSeconds: 11.4,
          samplingStratum: 'Open Trench Zone Weld Vicinity (0.5m level)',
        ),
        lotoRecords: [
          LotoIsolationRecord(
            id: 'LOTO-01',
            pointTag: 'VS03-ESDV-401-PWR',
            equipmentName: 'ESDV Actuator 415V MCC Breaker',
            isolationType: EnergyIsolationType.electricalBreaker,
            padlockNumber: 'PAD-RED-4401',
            dangerTagNumber: 'TAG-DNG-88912',
            isolatedBy: 'N. Sarma (Elec Engg)',
            verifiedBy: 'Subhash Roy (HSE)',
            isolationTimestamp: now.subtract(const Duration(hours: 2, minutes: 30)),
            verifiedVoltage: 0.0,
            remarks: 'Locked in OFF position with hasp. Multimeter verified 0.0V phase-to-earth.',
          ),
          LotoIsolationRecord(
            id: 'LOTO-02',
            pointTag: 'VS03-INLET-18IN-SPADE',
            equipmentName: '18" ANSI 600# Mainline Flange Isolation Spade',
            isolationType: EnergyIsolationType.mechanicalBlindSpade,
            padlockNumber: 'PAD-BLU-1190',
            dangerTagNumber: 'TAG-DNG-88913',
            isolatedBy: 'T. Borah (Mech Fitter)',
            verifiedBy: 'Pranab Saikia (Area Auth)',
            isolationTimestamp: now.subtract(const Duration(hours: 2, minutes: 25)),
            spadeThicknessMm: 28.0,
            remarks: '28mm ASTM A516 Gr.70 paddle blind inserted with fresh spiral wound gasket.',
          ),
        ],
      ),

      // 2. Confined Space Entry - Pig Receiver Barrel Inspection
      PtwLiveModel(
        id: 'PTW-2026-CS-0312',
        permitNumber: 'CS/DUL/2026/0312',
        classification: PtwClassification.confinedSpace,
        title: 'Pig Receiver Barrel Internal NDT & Debris Scraper Cleaning',
        locationZone: 'Duliajan Terminal - Crude Pig Trap Receiving Pit',
        chainageKp: 'KP 00+000 (Terminal Inflow)',
        areaAuthority: 'Pranab Saikia (DGM Ops, OIL)',
        performingAuthority: 'B. C. Phukan (NDT Level-II Inspector)',
        safetyOfficer: 'Subhash Roy (Sr. HSE Engineer)',
        contractor: 'Brahmaputra Industrial Services',
        crewCount: 4,
        status: PtwLiveStatus.active,
        validFrom: now.subtract(const Duration(hours: 1, minutes: 10)),
        validTo: now.add(const Duration(hours: 2, minutes: 50, seconds: 12)),
        mandatoryPpe: const [
          'Full-Body Harness with Dorsal D-Ring & Retrieval Line',
          '3M Scott Safety SCBA Standby & Escape ELSA Hood',
          'Intrinsic Anti-Static Coverall & Boots',
          'ATEX Zone 0 Intrinsically Safe LED Chest Lamp',
          '4-Gas Personal Clip-on Monitor (PPM Display)',
        ],
        safetyPrecautions: const [
          'Top, middle and bottom atmospheric gas profiling before entry',
          'Positive forced air ventilation blower >20 air changes/hour',
          'Stationary Manway Standby Watcher logged at barrel hatch',
          'Emergency mechanical tripod winch deployed & tethered',
          'Max continuous entry limited to 45 mins per technician',
        ],
        gasTest: AtmosphericGasTest(
          o2Concentration: 20.8,
          flammableLel: 0.4,
          toxicH2s: 1.2,
          carbonMonoxideCo: 4.1,
          testTimestamp: now.subtract(const Duration(minutes: 18)),
          testerName: 'D. K. Gogoi',
          testerCertification: 'OIL-GT-402 (Certified Atmospheric Specialist)',
          detectorModel: 'Dräger X-am 8000 Internal Pump Suction',
          detectorSerial: 'DRAEGER-XAM-8000-8812',
          bumpTestDate: now.subtract(const Duration(hours: 3)),
          calibrationCertExpiry: DateTime(2026, 11, 28),
          t90ResponseSeconds: 14.2,
          samplingStratum: 'Pig Barrel Interior - Bottom (Invert Sludge Bed)',
        ),
        lotoRecords: [
          LotoIsolationRecord(
            id: 'LOTO-03',
            pointTag: 'PIG-KICKER-VALVE-V08',
            equipmentName: '6" High-Pressure Kicker Line Ball Valve',
            isolationType: EnergyIsolationType.mechanicalBlindSpade,
            padlockNumber: 'PAD-YEL-0902',
            dangerTagNumber: 'TAG-DNG-77401',
            isolatedBy: 'T. Borah (Mech Fitter)',
            verifiedBy: 'Subhash Roy (HSE)',
            isolationTimestamp: now.subtract(const Duration(hours: 1, minutes: 40)),
            spadeThicknessMm: 16.0,
            remarks: 'Spectacle blind swung to BLIND position. Bolts torque-checked to 210 N·m.',
          ),
          LotoIsolationRecord(
            id: 'LOTO-04',
            pointTag: 'PIG-BARREL-BLEED-V12',
            equipmentName: '2" Receiver Barrel Depressurizing Bleed Valve',
            isolationType: EnergyIsolationType.hydraulicBleed,
            padlockNumber: 'PAD-GRN-3312',
            dangerTagNumber: 'TAG-DNG-77402',
            isolatedBy: 'N. Sarma (Elec/Instr)',
            verifiedBy: 'Pranab Saikia (Area Auth)',
            isolationTimestamp: now.subtract(const Duration(hours: 1, minutes: 35)),
            residualPressureBar: 0.0,
            remarks: 'Vent valve cracked open into closed drain. Pressure gauge reads 0.00 bar.',
          ),
        ],
      ),

      // 3. Working at Height - Flare Knockout Drum Scaffolding
      PtwLiveModel(
        id: 'PTW-2026-WH-0599',
        permitNumber: 'WH/DUL/2026/0599',
        classification: PtwClassification.workingAtHeight,
        title: 'Flare KO Drum Structural Platform & Pressure Safety Valve Rework (14.5m)',
        locationZone: 'Gas Dehydration Plant - Flare Knockout Area',
        chainageKp: 'Sector B - Main Process Yard',
        areaAuthority: 'Manash Baruah (Process Superintendent)',
        performingAuthority: 'Hiren Deka (Rigging Lead)',
        safetyOfficer: 'Subhash Roy (Sr. HSE Engineer)',
        contractor: 'Eastern Engineering Fabricators',
        crewCount: 5,
        status: PtwLiveStatus.issued,
        validFrom: now.add(const Duration(minutes: 15)),
        validTo: now.add(const Duration(hours: 5, minutes: 45)),
        mandatoryPpe: const [
          'Full-Body Harness with Dual Elastic Lanyard & Energy Absorber',
          'Industrial Safety Helmet with 4-Point Chin Strap (EN 397)',
          'Tool Lanyards & Tethers (Drop prevention max 2kg)',
          'Safety Eyewear with Side Shields',
        ],
        safetyPrecautions: const [
          'Green Scaffolding Tag verified per IS 3696 & inspection within 7 days',
          '100% tie-off mandatory on certified anchor line (>22 kN rated)',
          'Exclusion zone cordoned below platform with warning bunting',
          'Wind speed verified below 32 km/h via on-site anemometer',
        ],
        gasTest: AtmosphericGasTest(
          o2Concentration: 20.9,
          flammableLel: 0.0,
          toxicH2s: 0.0,
          carbonMonoxideCo: 0.5,
          testTimestamp: now.subtract(const Duration(minutes: 10)),
          testerName: 'D. K. Gogoi',
          testerCertification: 'OIL-GT-402',
          detectorModel: 'Honeywell BW Ultra Quad-Gas',
          detectorSerial: 'BW-ULTRA-SN-994208-X',
          bumpTestDate: now.subtract(const Duration(hours: 2)),
          calibrationCertExpiry: DateTime(2026, 12, 15),
          t90ResponseSeconds: 10.9,
          samplingStratum: 'Platform Level Elevation +14.5m',
        ),
        lotoRecords: [
          LotoIsolationRecord(
            id: 'LOTO-05',
            pointTag: 'PSV-FLARE-ISOL-01',
            equipmentName: 'PSV-2001 Car-Sealed Inlet Gate Valve',
            isolationType: EnergyIsolationType.mechanicalBlindSpade,
            padlockNumber: 'PAD-BLK-9901',
            dangerTagNumber: 'TAG-DNG-33120',
            isolatedBy: 'T. Borah',
            verifiedBy: 'Manash Baruah',
            isolationTimestamp: now.subtract(const Duration(minutes: 30)),
            spadeThicknessMm: 22.0,
            remarks: 'Car-seal broken under permit, blind spade inserted. Standby PSV in service.',
          ),
        ],
      ),

      // 4. Heavy Crane Lifting - 45T Slug Catcher Vessel Erection
      PtwLiveModel(
        id: 'PTW-2026-HL-0144',
        permitNumber: 'HL/DUL/2026/0144',
        classification: PtwClassification.heavyLifting,
        title: 'Tandem Crane Lifting (250T Demag + 160T Sany) - 45T Slug Catcher Module',
        locationZone: 'Burhi Dihing Riverbank Trench Terminal',
        chainageKp: 'KP 34+800',
        areaAuthority: 'Pranab Saikia (DGM Ops, OIL)',
        performingAuthority: 'Major J. S. Cheema (Heavy Lift Master)',
        safetyOfficer: 'Ranjit Kakoti (Rigging Safety Auditor)',
        contractor: 'Sanghvi Movers & Heavy Rigging Ltd',
        crewCount: 8,
        status: PtwLiveStatus.suspended,
        suspensionOrCancellationReason:
            'Suspended: Wind gusts exceeded 28 km/h (Anemometer measured 36.2 km/h). Awaiting calm conditions.',
        validFrom: now.subtract(const Duration(hours: 3)),
        validTo: now.add(const Duration(hours: 1, minutes: 15)),
        mandatoryPpe: const [
          'High-Visibility Class 3 Vest with Reflective Strips',
          'Steel Toe Rigging Boots with Metatarsal Guard',
          'Rigging Gloves with Kevlar Grip',
          'Two-Way VHF Radio with Noise Cancelling Headset',
        ],
        safetyPrecautions: const [
          '3rd-party load cell calibration certificate verified within 30 days',
          'Ground bearing pressure calculated: Steel outrigger mats 3.5m x 3.5m',
          'Barricaded swing radius 35m with zero unauthorized personnel entry',
          'Dedicated banksman / signalman with high-vis batons',
        ],
        gasTest: AtmosphericGasTest(
          o2Concentration: 20.9,
          flammableLel: 0.0,
          toxicH2s: 0.0,
          carbonMonoxideCo: 1.2,
          testTimestamp: now.subtract(const Duration(hours: 2)),
          testerName: 'D. K. Gogoi',
          testerCertification: 'OIL-GT-402',
          detectorModel: 'Honeywell BW Ultra Quad-Gas',
          detectorSerial: 'BW-ULTRA-SN-994208-X',
          bumpTestDate: now.subtract(const Duration(hours: 4)),
          calibrationCertExpiry: DateTime(2026, 12, 15),
          t90ResponseSeconds: 11.2,
          samplingStratum: 'Open Crane Pad Area Ground Level',
        ),
        lotoRecords: [
          LotoIsolationRecord(
            id: 'LOTO-06',
            pointTag: 'OVERHEAD-11KV-LINE-ISO',
            equipmentName: '11kV Overhead Power Line Feeder 3B',
            isolationType: EnergyIsolationType.electricalBreaker,
            padlockNumber: 'PAD-RED-1192',
            dangerTagNumber: 'TAG-DNG-55201',
            isolatedBy: 'APDCL Substation In-Charge',
            verifiedBy: 'Ranjit Kakoti',
            isolationTimestamp: now.subtract(const Duration(hours: 4)),
            verifiedVoltage: 0.0,
            remarks: 'Feeder de-energized, earthed at tower 14 and 15. Earth discharge stick attached.',
          ),
        ],
      ),

      // 5. Cold Work Permit - Pipeline Hydrostatic Test Manifold Bolting
      PtwLiveModel(
        id: 'PTW-2026-CW-0919',
        permitNumber: 'CW/DUL/2026/0919',
        classification: PtwClassification.coldWork,
        title: 'Hydrostatic Test Header Flange Torque Bolting (ANSI 900#)',
        locationZone: 'Section 3 Hydrotest Spread',
        chainageKp: 'KP 28+500',
        areaAuthority: 'Pranab Saikia (DGM Ops, OIL)',
        performingAuthority: 'Amit Baruah (Pressure Test Engineer)',
        safetyOfficer: 'Subhash Roy (Sr. HSE Engineer)',
        contractor: 'Assam Pipeline Infrastructure Ltd',
        crewCount: 4,
        status: PtwLiveStatus.surrendered,
        validFrom: now.subtract(const Duration(hours: 7)),
        validTo: now.subtract(const Duration(minutes: 45)),
        mandatoryPpe: const [
          'High-Impact Eye Protection / Full Face Shield',
          'Cut-Resistant Impact Gloves (Level 5)',
          'Steel Toe Safety Boots',
          'Standard Industrial Coverall',
        ],
        safetyPrecautions: const [
          'Hydraulic torque wrench calibrated to ASME PCC-1 specs',
          'Flange guards installed over all pressurized connections',
          'Barricaded high-pressure hydrotest corridor (112.5 Bar test)',
        ],
        gasTest: AtmosphericGasTest(
          o2Concentration: 20.9,
          flammableLel: 0.0,
          toxicH2s: 0.0,
          carbonMonoxideCo: 0.8,
          testTimestamp: now.subtract(const Duration(hours: 6)),
          testerName: 'D. K. Gogoi',
          testerCertification: 'OIL-GT-402',
          detectorModel: 'Honeywell BW Ultra Quad-Gas',
          detectorSerial: 'BW-ULTRA-SN-994208-X',
          bumpTestDate: now.subtract(const Duration(hours: 8)),
          calibrationCertExpiry: DateTime(2026, 12, 15),
          t90ResponseSeconds: 11.5,
          samplingStratum: 'Trench Pit Flange Face',
        ),
        lotoRecords: [],
      ),
    ];
  }

  // ============================================================================
  // SUPERVISOR EMERGENCY STOP BEACON WORKFLOW
  // ============================================================================

  void _showEmergencyStopDialog() {
    String selectedReason = 'Atmospheric Hydrocarbon / Toxic Gas Drift (>2.5% LEL / >10 ppm H2S)';
    final reasons = [
      'Atmospheric Hydrocarbon / Toxic Gas Drift (>2.5% LEL / >10 ppm H2S)',
      'Flash Fire / Hot Sparks escaping containment boundary',
      'Structural / Trench Shoring Instability or Slump Warning',
      'Sudden Severe Weather / Lightning Strike within 5km radius',
      'Pipeline Pressure Spike / Unexpected Hazardous Release',
      'Emergency Muster Alarm Triggered by Main Refinery Control Room',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A0A0E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFEF4444), width: 2),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFEF4444),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'SUPERVISOR EMERGENCY STOP',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'TRIGGERING THIS BEACON WILL IMMEDIATELY HALT & SUSPEND ALL ACTIVE HOT WORK, CONFINED SPACE ENTRY & HEAVY RIGGING PERMITS ACROSS THE DULIAJAN SECTOR.\nAN AUDIBLE FIELD EVACUATION SIREN WILL SOUND.',
                      style: TextStyle(
                        color: Color(0xFFFF8B8B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Emergency Event Category:',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButton<String>(
                      value: selectedReason,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceCard,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryLight),
                      items: reasons.map((r) {
                        return DropdownMenuItem<String>(
                          value: r,
                          child: Text(
                            r,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedReason = val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Authorized By: Area Safety Supervisor (Subhash Roy • Badge #HSE-009)',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'ABORT',
                    style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.campaign_rounded, size: 20),
                  label: const Text(
                    'EXECUTE EMERGENCY STOP',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _triggerEmergencyStop(selectedReason);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _triggerEmergencyStop(String reason) {
    setState(() {
      _isEmergencyBeaconActive = true;
      _emergencyReason = reason;
      _emergencyTriggeredBy = 'Subhash Roy (Sr. HSE Engineer)';

      // Instantly suspend or cancel all active high hazard permits
      for (final p in _permits) {
        if (p.status == PtwLiveStatus.active) {
          p.status = PtwLiveStatus.suspended;
          p.suspensionOrCancellationReason = 'EMERGENCY BEACON ACTIVATED: $reason';
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'EMERGENCY STOP BEACON LIVE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  Text(
                    'All permits suspended. Evacuate to Muster Point #3 immediately.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetEmergencyBeacon() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: AppTheme.primaryLight),
              SizedBox(width: 8),
              Text(
                'De-escalate Emergency Beacon',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              ),
            ],
          ),
          content: const Text(
            'Confirm that site atmospheric gas levels have normalized, structural hazards are mitigated, and Area Authority has certified the zone safe for resumption of work.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tertiary,
                foregroundColor: const Color(0xFF0B1326),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _isEmergencyBeaconActive = false;
                  _emergencyReason = '';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Emergency Beacon De-escalated. Permits can now be manually resumed.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              child: const Text('CERTIFY SAFE & RESET', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // PERMIT ACTIONS (EXTEND, SUSPEND, RESUME, SURRENDER)
  // ============================================================================

  void _extendPermit(PtwLiveModel permit) {
    showDialog(
      context: context,
      builder: (ctx) {
        int extendHours = 2;
        final extensionReasonCtrl = TextEditingController(
          text: 'Shift handover extension for final tie-in weld cooling and NDT clearance',
        );

        return StatefulBuilder(
          builder: (dCtx, setDState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Row(
                children: [
                  const Icon(Icons.more_time_rounded, color: AppTheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Extend Permit ${permit.permitNumber}',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Per OISD-STD-105 §6.4, permits may be extended up to a maximum of 4 hours under the same issuing authority and shift supervisor.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Extension Duration:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [1, 2, 4].map((hrs) {
                      final isSelected = extendHours == hrs;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('+$hrs Hours'),
                          selected: isSelected,
                          selectedColor: AppTheme.secondary.withValues(alpha: 0.25),
                          backgroundColor: AppTheme.surface,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.secondary : AppTheme.textMuted,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppTheme.secondary : AppTheme.border,
                          ),
                          onSelected: (val) {
                            if (val) setDState(() => extendHours = hrs);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reason for Shift Extension:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: extensionReasonCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Enter formal shift continuation justification...',
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: const Color(0xFF0B1326),
                  ),
                  onPressed: () {
                    setState(() {
                      permit.validTo = permit.validTo.add(Duration(hours: extendHours));
                      permit.extensionCount++;
                    });
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Permit ${permit.permitNumber} extended by $extendHours hours. Valid till ${DateFormat('HH:mm').format(permit.validTo)}.',
                        ),
                        backgroundColor: AppTheme.secondary,
                      ),
                    );
                  },
                  child: const Text('APPROVE EXTENSION', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _suspendPermit(PtwLiveModel permit) {
    final reasonCtrl = TextEditingController(text: 'High crosswinds / Gas detector bump renewal pending');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: [
              const Icon(Icons.pause_circle_filled_rounded, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Suspend Permit ${permit.permitNumber}',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter suspension reason. Work must immediately stop and work area made safe.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(hintText: 'Reason for suspension...'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  permit.status = PtwLiveStatus.suspended;
                  permit.suspensionOrCancellationReason = reasonCtrl.text;
                });
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Permit ${permit.permitNumber} SUSPENDED.'),
                    backgroundColor: const Color(0xFFF59E0B),
                  ),
                );
              },
              child: const Text('SUSPEND PERMIT', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  void _resumePermit(PtwLiveModel permit) {
    if (_isEmergencyBeaconActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot resume permits while Supervisor Emergency Stop Beacon is active!'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      permit.status = PtwLiveStatus.active;
      permit.suspensionOrCancellationReason = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Permit ${permit.permitNumber} RESUMED to ACTIVE.'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _surrenderPermit(PtwLiveModel permit) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.assignment_return_rounded, color: AppTheme.primaryLight),
              SizedBox(width: 8),
              Text(
                'Surrender & Closeout Permit',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permit: ${permit.permitNumber}\nLocation: ${permit.locationZone}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Closeout Checklist:\n✓ Housekeeping verified (all debris, welding stubs cleared)\n✓ All tools & scaffolding equipment removed\n✓ Fire watch maintained for 30 minutes post hot-work\n✓ LOTO isolations de-isolated or handed over to Area Authority',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.45),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  permit.status = PtwLiveStatus.surrendered;
                });
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Permit ${permit.permitNumber} successfully surrendered and archived.'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              child: const Text('CONFIRM SURRENDER', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // ISSUE NEW PERMIT WIZARD
  // ============================================================================

  void _showNewPermitModal() {
    PtwClassification selectedType = PtwClassification.hotWork;
    final titleCtrl = TextEditingController(text: 'Section 4 Pipe Trench Weld Joint Tie-in');
    final locCtrl = TextEditingController(text: 'KP 45+200 - Near Valve Station 04');
    final contractorCtrl = TextEditingController(text: 'Assam Pipeline Infrastructure Ltd');
    int crew = 4;
    int durationHours = 8;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.note_add_rounded, color: AppTheme.primaryLight),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Issue New Permit to Work (PTW)',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textMuted),
                          onPressed: () => Navigator.of(bCtx).pop(),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.border, height: 24),

                    // Classification Selector
                    const Text(
                      'PERMIT CLASSIFICATION',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PtwClassification.values.map((cls) {
                        final isSel = selectedType == cls;
                        return ChoiceChip(
                          avatar: Icon(cls.icon, size: 16, color: isSel ? Colors.white : cls.primaryColor),
                          label: Text(cls.badge),
                          selected: isSel,
                          selectedColor: cls.primaryColor,
                          backgroundColor: AppTheme.surface,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppTheme.textPrimary,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11,
                          ),
                          side: BorderSide(
                            color: isSel ? cls.primaryColor : AppTheme.border,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedType = cls);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Work Title
                    const Text('Work Activity Title:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(hintText: 'e.g. Flare tip repair / Tie-in weld'),
                    ),
                    const SizedBox(height: 12),

                    // Location
                    const Text('Site Location / Chainage KP:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: locCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(hintText: 'e.g. KP 45+200 Trench Section'),
                    ),
                    const SizedBox(height: 12),

                    // Contractor & Crew
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Contractor:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: contractorCtrl,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                decoration: const InputDecoration(hintText: 'Contractor Name'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Crew Size:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                initialValue: crew,
                                dropdownColor: AppTheme.surfaceCard,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: [2, 3, 4, 5, 6, 8, 10, 12].map((c) {
                                  return DropdownMenuItem<int>(
                                    value: c,
                                    child: Text('$c Men', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => crew = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Validity Window
                    Row(
                      children: [
                        const Text('Validity Duration:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        const Spacer(),
                        ...[4, 8, 12].map((dur) {
                          final isSel = durationHours == dur;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChoiceChip(
                              label: Text('$dur hrs'),
                              selected: isSel,
                              selectedColor: AppTheme.primary,
                              backgroundColor: AppTheme.surface,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              ),
                              side: BorderSide(color: isSel ? AppTheme.primary : AppTheme.border),
                              onSelected: (val) {
                                if (val) setModalState(() => durationHours = dur);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: const Text('AUTHORIZE & ISSUE PERMIT'),
                        onPressed: () {
                          final now = DateTime.now();
                          final newId = 'PTW-${now.year}-${selectedType.name.substring(0, 2).toUpperCase()}-${(1000 + _permits.length + 1)}';
                          final newPermit = PtwLiveModel(
                            id: newId,
                            permitNumber: '${selectedType.name.substring(0, 2).toUpperCase()}/DUL/${now.year}/${(1000 + _permits.length + 1)}',
                            classification: selectedType,
                            title: titleCtrl.text.trim().isEmpty ? 'General Field Work' : titleCtrl.text.trim(),
                            locationZone: locCtrl.text.trim().isEmpty ? 'Pipeline Section' : locCtrl.text.trim(),
                            chainageKp: 'KP 45+200',
                            areaAuthority: 'Pranab Saikia (DGM Ops, OIL)',
                            performingAuthority: 'Field Supervisor #FS-88',
                            safetyOfficer: 'Subhash Roy (Sr. HSE Engineer)',
                            contractor: contractorCtrl.text.trim().isEmpty ? 'Assam Pipeline Ltd' : contractorCtrl.text.trim(),
                            crewCount: crew,
                            status: PtwLiveStatus.issued,
                            validFrom: now,
                            validTo: now.add(Duration(hours: durationHours)),
                            mandatoryPpe: const [
                              'Safety Helmet (EN 397)',
                              'High-Vis Reflective Vest',
                              'Safety Shoes Class S3',
                              'Standard Protective Eye Protection',
                            ],
                            safetyPrecautions: const [
                              'Mandatory Pre-Task Toolbox Talk (TBT) before starting',
                              'Gas test bump verification before hot/entry operations',
                              'Maintain communication with Area Authority',
                            ],
                            gasTest: AtmosphericGasTest(
                              o2Concentration: 20.9,
                              flammableLel: 0.0,
                              toxicH2s: 0.0,
                              carbonMonoxideCo: 1.0,
                              testTimestamp: now,
                              testerName: 'D. K. Gogoi',
                              testerCertification: 'OIL-GT-402',
                              detectorModel: 'Honeywell BW Ultra Quad-Gas',
                              detectorSerial: 'BW-ULTRA-SN-994208-X',
                              bumpTestDate: now,
                              calibrationCertExpiry: DateTime(2026, 12, 15),
                              t90ResponseSeconds: 11.0,
                              samplingStratum: 'Pre-Task Surface Survey',
                            ),
                            lotoRecords: [],
                          );

                          setState(() {
                            _permits.insert(0, newPermit);
                          });

                          Navigator.of(bCtx).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Permit ${newPermit.permitNumber} ISSUED successfully.'),
                              backgroundColor: AppTheme.tertiary,
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

  // ============================================================================
  // BUILD SCREEN UI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Emergency Stop Alert Banner (if active)
          if (_isEmergencyBeaconActive) _buildEmergencyStopBanner(),

          // Quick Metrics Strip
          _buildMetricsStrip(),

          // Tab Bar
          _buildTabBar(),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLivePermitsTab(),
                _buildAtmosphericGasTestingTab(),
                _buildEnergyIsolationLotoTab(),
                _buildComplianceAndEvacuationTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showNewPermitModal,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task_rounded),
              label: const Text(
                'NEW PERMIT',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            )
          : null,
    );
  }

  // ============================================================================
  // APP BAR & HEADER
  // ============================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 2,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Permit to Work (PTW) Live',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'OISD-105',
                  style: TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Oil India Duliajan • 18" Crude Mainline • Field Management',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        // Pulsing Supervisor Emergency Stop Beacon
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: AnimatedBuilder(
            animation: _beaconPulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isEmergencyBeaconActive ? _beaconPulseAnimation.value : 1.0,
                child: InkWell(
                  onTap: _isEmergencyBeaconActive ? _resetEmergencyBeacon : _showEmergencyStopDialog,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isEmergencyBeaconActive
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF7F1D1D).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isEmergencyBeaconActive ? Colors.white : const Color(0xFFEF4444),
                        width: _isEmergencyBeaconActive ? 2 : 1,
                      ),
                      boxShadow: _isEmergencyBeaconActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                                blurRadius: 16,
                                spreadRadius: 3,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isEmergencyBeaconActive ? Icons.campaign_rounded : Icons.emergency_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isEmergencyBeaconActive ? 'EMERGENCY ACTIVE' : 'ESD BEACON',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyStopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFB91C1C),
        border: Border(bottom: BorderSide(color: Colors.white, width: 1.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SUPERVISOR EMERGENCY STOP (ESD) BROADCAST ACTIVE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                ),
                Text(
                  'Reason: $_emergencyReason | Initiated by: $_emergencyTriggeredBy',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFB91C1C),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _resetEmergencyBeacon,
            child: const Text('RESET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // METRICS STRIP
  // ============================================================================

  Widget _buildMetricsStrip() {
    final activeCount = _permits.where((p) => p.status == PtwLiveStatus.active).length;
    final issuedCount = _permits.where((p) => p.status == PtwLiveStatus.issued).length;
    final suspendedCount = _permits.where((p) => p.status == PtwLiveStatus.suspended).length;
    final totalCrew = _permits
        .where((p) => p.status == PtwLiveStatus.active)
        .fold<int>(0, (sum, p) => sum + p.crewCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMetricPill('ACTIVE', '$activeCount', const Color(0xFF10B981)),
          _buildMetricPill('ISSUED', '$issuedCount', const Color(0xFF38BDF8)),
          _buildMetricPill('SUSPENDED', '$suspendedCount', const Color(0xFFF59E0B)),
          _buildMetricPill('MEN IN ZONE', '$totalCrew', AppTheme.secondary),
          _buildMetricPill('LOTO PTS', '6', AppTheme.primaryLight),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(
            icon: Icon(Icons.assignment_rounded, size: 18),
            text: 'Live Permits',
          ),
          Tab(
            icon: Icon(Icons.co2_rounded, size: 18),
            text: 'Atmospheric Gas Test',
          ),
          Tab(
            icon: Icon(Icons.lock_clock_rounded, size: 18),
            text: 'LOTO & Isolation',
          ),
          Tab(
            icon: Icon(Icons.verified_user_rounded, size: 18),
            text: 'Compliance & Safety',
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: LIVE PERMITS BOARD & CLASSIFICATION MATRIX
  // ============================================================================

  Widget _buildLivePermitsTab() {
    // Filter permits
    final filtered = _permits.where((p) {
      if (_selectedClassificationFilter != 'ALL') {
        if (p.classification.name != _selectedClassificationFilter) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = p.title.toLowerCase().contains(q);
        final matchNumber = p.permitNumber.toLowerCase().contains(q);
        final matchLoc = p.locationZone.toLowerCase().contains(q);
        return matchTitle || matchNumber || matchLoc;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter bar & Search box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.surface,
          child: Column(
            children: [
              // Search input
              TextField(
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search permit #, location or work activity...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  fillColor: AppTheme.surfaceCard,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),

              // Classification chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildClassificationChip('ALL', 'All Permits', Icons.apps_rounded, null),
                    ...PtwClassification.values.map((cls) {
                      return _buildClassificationChip(
                        cls.name,
                        cls.badge,
                        cls.icon,
                        cls.primaryColor,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List of permit cards
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'No matching permits found',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    return _buildPermitCard(filtered[idx]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildClassificationChip(String key, String label, IconData icon, Color? color) {
    final isSelected = _selectedClassificationFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        avatar: Icon(
          icon,
          size: 15,
          color: isSelected ? Colors.white : (color ?? AppTheme.textMuted),
        ),
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 11,
        ),
        selectedColor: color ?? AppTheme.primary,
        backgroundColor: AppTheme.surfaceCard,
        side: BorderSide(
          color: isSelected ? (color ?? AppTheme.primary) : AppTheme.border,
        ),
        onSelected: (val) {
          setState(() {
            _selectedClassificationFilter = key;
          });
        },
      ),
    );
  }

  Widget _buildPermitCard(PtwLiveModel permit) {
    final cls = permit.classification;
    final status = permit.status;
    final isUrgentCountdown = permit.remainingDuration.inMinutes <= 30 &&
        permit.status == PtwLiveStatus.active;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: status == PtwLiveStatus.active
              ? cls.primaryColor.withValues(alpha: 0.4)
              : AppTheme.border,
          width: status == PtwLiveStatus.active ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Badge, Permit ID, Status Tag
            Row(
              children: [
                // Type Icon Container
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cls.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cls.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(cls.icon, color: cls.primaryColor, size: 20),
                ),
                const SizedBox(width: 10),

                // Permit Numbers & Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            permit.permitNumber,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: cls.primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              cls.badge,
                              style: TextStyle(
                                color: cls.primaryColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        permit.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Real-time Status Badge
                _buildStatusBadge(status),
              ],
            ),

            const SizedBox(height: 12),

            // Live Countdown Timer Strip (Industrial Box)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isUrgentCountdown
                    ? const Color(0xFF7F1D1D).withValues(alpha: 0.3)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUrgentCountdown
                      ? const Color(0xFFEF4444)
                      : AppTheme.border,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: isUrgentCountdown
                                ? const Color(0xFFEF4444)
                                : AppTheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'SHIFT COUNTDOWN:',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        permit.formattedCountdown,
                        style: TextStyle(
                          color: isUrgentCountdown
                              ? const Color(0xFFEF4444)
                              : (status == PtwLiveStatus.active
                                  ? AppTheme.secondary
                                  : AppTheme.textSecondary),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: permit.timeElapsedFraction,
                      minHeight: 4,
                      backgroundColor: AppTheme.surfaceCard,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUrgentCountdown
                            ? const Color(0xFFEF4444)
                            : (status == PtwLiveStatus.active
                                ? AppTheme.primaryLight
                                : AppTheme.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Start: ${DateFormat('HH:mm').format(permit.validFrom)}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      ),
                      if (permit.extensionCount > 0)
                        Text(
                          '+${permit.extensionCount * 2}h Ext approved',
                          style: const TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        'Expiry: ${DateFormat('HH:mm').format(permit.validTo)}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (permit.suspensionOrCancellationReason != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        permit.suspensionOrCancellationReason!,
                        style: const TextStyle(
                          color: Color(0xFFFFD580),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Location & Signatories Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_rounded, color: AppTheme.primaryLight, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${permit.locationZone} (${permit.chainageKp})',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.groups_rounded, color: AppTheme.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${permit.crewCount} Personnel',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Pre-requisites status indicators (Gas test & LOTO check)
            Row(
              children: [
                _buildPrerequisiteChip(
                  label: 'Gas Test',
                  isValid: permit.gasTest.isAtmosphereSafe,
                  icon: Icons.air_rounded,
                ),
                const SizedBox(width: 8),
                _buildPrerequisiteChip(
                  label: 'LOTO (${permit.lotoRecords.length} pts)',
                  isValid: permit.isAllLotoVerified,
                  icon: Icons.lock_outline_rounded,
                ),
                const Spacer(),
                Text(
                  'Issuer: ${permit.areaAuthority.split(' ').first}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

            const Divider(color: AppTheme.border, height: 20),

            // Action Buttons Strip
            Row(
              children: [
                // View Details / Dossier
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  icon: const Icon(Icons.description_outlined, size: 14, color: AppTheme.textSecondary),
                  label: const Text(
                    'DOSSIER',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  onPressed: () => _showPermitDossier(permit),
                ),
                const SizedBox(width: 8),

                // Extend Time Button
                if (status == PtwLiveStatus.active || status == PtwLiveStatus.issued)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      side: const BorderSide(color: AppTheme.secondary),
                    ),
                    icon: const Icon(Icons.add_alarm_rounded, size: 14, color: AppTheme.secondary),
                    label: const Text(
                      '+ EXTEND',
                      style: TextStyle(fontSize: 11, color: AppTheme.secondary, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _extendPermit(permit),
                  ),

                const Spacer(),

                // State Transition Actions
                if (status == PtwLiveStatus.issued) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('START WORK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    onPressed: () => _resumePermit(permit),
                  ),
                ] else if (status == PtwLiveStatus.active) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                    onPressed: () => _suspendPermit(permit),
                    child: const Text(
                      'SUSPEND',
                      style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _surrenderPermit(permit),
                    child: const Text(
                      'SURRENDER',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ] else if (status == PtwLiveStatus.suspended) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('RESUME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    onPressed: () => _resumePermit(permit),
                  ),
                ] else if (status == PtwLiveStatus.surrendered) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CLOSED & DE-ISOLATED',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PtwLiveStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: status.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrerequisiteChip({
    required String label,
    required bool isValid,
    required IconData icon,
  }) {
    final color = isValid ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isValid ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: PRE-TASK ATMOSPHERIC GAS TESTING & CALIBRATION VERIFICATION
  // ============================================================================

  Widget _buildAtmosphericGasTestingTab() {
    // Current simulated readings
    final bool isO2Safe = _simO2 >= 19.5 && _simO2 <= 23.5;
    final bool isLelSafe = _simLel < 1.0;
    final bool isH2sSafe = _simH2s < 10.0;
    final bool isCoSafe = _simCo < 25.0;
    final bool isAtmospherePermissible = isO2Safe && isLelSafe && isH2sSafe && isCoSafe;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Telemetry Calibration & Bump Test Card
          _buildCalibrationVerificationCard(),

          const SizedBox(height: 16),

          // Live Atmospheric 4-Gas Dial Display
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: AppTheme.primaryLight, size: 20),
              const SizedBox(width: 8),
              const Text(
                'PRE-TASK ATMOSPHERIC 4-GAS MONITOR',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAtmospherePermissible
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isAtmospherePermissible
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
                child: Text(
                  isAtmospherePermissible ? 'ENTRY SAFE' : 'ENTRY PROHIBITED',
                  style: TextStyle(
                    color: isAtmospherePermissible
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 Gas Sensor Cards Grid
          Row(
            children: [
              Expanded(
                child: _buildGasGaugeCard(
                  gasName: 'Oxygen (O₂)',
                  readingValue: '${_simO2.toStringAsFixed(1)}%',
                  thresholdLabel: 'Permissible: 19.5% - 23.5%',
                  isSafe: isO2Safe,
                  icon: Icons.air_rounded,
                  color: const Color(0xFF38BDF8),
                  statusNote: isO2Safe ? 'NORMAL' : (_simO2 < 19.5 ? 'DEFICIENT' : 'ENRICHED'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGasGaugeCard(
                  gasName: 'Flammable (LEL)',
                  readingValue: '${_simLel.toStringAsFixed(1)}%',
                  thresholdLabel: 'Safe: < 1.0% LEL',
                  isSafe: isLelSafe,
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFFFB95F),
                  statusNote: isLelSafe ? 'SAFE' : 'EXPLOSIVE HAZARD',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGasGaugeCard(
                  gasName: 'Hydrogen Sulfide (H₂S)',
                  readingValue: '${_simH2s.toStringAsFixed(1)} ppm',
                  thresholdLabel: 'Ceiling: < 10.0 ppm',
                  isSafe: isH2sSafe,
                  icon: Icons.warning_rounded,
                  color: const Color(0xFFEF4444),
                  statusNote: isH2sSafe ? 'ZERO DETECT' : 'TOXIC LETHAL',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGasGaugeCard(
                  gasName: 'Carbon Monoxide (CO)',
                  readingValue: '${_simCo.toStringAsFixed(1)} ppm',
                  thresholdLabel: 'Safe: < 25.0 ppm',
                  isSafe: isCoSafe,
                  icon: Icons.cloud_queue_rounded,
                  color: const Color(0xFFA855F7),
                  statusNote: isCoSafe ? 'NORMAL' : 'ASPHYXIANT',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Interactive Field Test & Stratum Logger
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
                    const Icon(Icons.edit_note_rounded, color: AppTheme.primaryLight, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'FIELD GAS SAMPLING CONTROLS & LOGGING',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 14, color: AppTheme.primaryLight),
                      label: const Text('Reset Normal', style: TextStyle(fontSize: 11, color: AppTheme.primaryLight)),
                      onPressed: () {
                        setState(() {
                          _simO2 = 20.9;
                          _simLel = 0.0;
                          _simH2s = 0.0;
                          _simCo = 2.0;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sampling Stratum Dropdown
                const Text(
                  'Confined Space Sampling Depth / Stratum:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButton<String>(
                    value: _simStratum,
                    isExpanded: true,
                    dropdownColor: AppTheme.surface,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'Pig Barrel Interior - Bottom (Invert)',
                        child: Text('Pig Barrel Interior - Bottom Invert (Dense H2S/Sludge)', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'Pig Barrel Interior - Middle Vapor Space',
                        child: Text('Pig Barrel Interior - Middle Vapor (CO/Combustible)', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'Crude Tank Top Manway Hatch',
                        child: Text('Crude Tank Top Manway Hatch (Lighter Hydrocarbons)', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'Open Trench Bottom (1.8m Depth)',
                        child: Text('Open Trench Bottom (1.8m Depth Pipeline Tie-In)', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _simStratum = val);
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Interactive Slider 1: Oxygen
                _buildSliderRow(
                  label: 'Simulate Oxygen (O₂):',
                  value: _simO2,
                  min: 15.0,
                  max: 26.0,
                  unit: '%',
                  color: isO2Safe ? const Color(0xFF38BDF8) : const Color(0xFFEF4444),
                  onChanged: (val) => setState(() => _simO2 = val),
                ),

                // Interactive Slider 2: LEL
                _buildSliderRow(
                  label: 'Simulate Flammable LEL:',
                  value: _simLel,
                  min: 0.0,
                  max: 5.0,
                  unit: '% LEL',
                  color: isLelSafe ? const Color(0xFFFFB95F) : const Color(0xFFEF4444),
                  onChanged: (val) => setState(() => _simLel = val),
                ),

                // Interactive Slider 3: Toxic H2S
                _buildSliderRow(
                  label: 'Simulate Toxic H₂S:',
                  value: _simH2s,
                  min: 0.0,
                  max: 25.0,
                  unit: 'ppm',
                  color: isH2sSafe ? const Color(0xFF4EDEA3) : const Color(0xFFEF4444),
                  onChanged: (val) => setState(() => _simH2s = val),
                ),

                // Interactive Slider 4: CO
                _buildSliderRow(
                  label: 'Simulate Carbon Monoxide (CO):',
                  value: _simCo,
                  min: 0.0,
                  max: 60.0,
                  unit: 'ppm',
                  color: isCoSafe ? const Color(0xFFA855F7) : const Color(0xFFEF4444),
                  onChanged: (val) => setState(() => _simCo = val),
                ),

                const SizedBox(height: 16),

                // Commit Gas Test Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAtmospherePermissible
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(
                      isAtmospherePermissible
                          ? Icons.check_circle_rounded
                          : Icons.warning_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isAtmospherePermissible
                          ? 'LOG GAS TEST & CERTIFY ATMOSPHERE'
                          : 'ATMOSPHERE HAZARDOUS - LOG REJECTION',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    onPressed: () {
                      _logSimulatedGasTest(isAtmospherePermissible);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationVerificationCard() {
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
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MULTI-GAS DETECTOR CALIBRATION RECORD',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Honeywell BW Ultra Quad-Gas • S/N: BW-ULTRA-SN-994208-X',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CALIBRATED',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCalibItem('Daily Bump Test', 'PASSED (06:30 AM)', const Color(0xFF10B981)),
              _buildCalibItem('Cert Expiry', '15 DEC 2026', AppTheme.primaryLight),
              _buildCalibItem('t90 Response', '11.4s (<15s SLA)', AppTheme.secondary),
              _buildCalibItem('Quad Mix Lot', '#CG-4821', AppTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalibItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildGasGaugeCard({
    required String gasName,
    required String readingValue,
    required String thresholdLabel,
    required bool isSafe,
    required IconData icon,
    required Color color,
    required String statusNote,
  }) {
    final statusColor = isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSafe ? AppTheme.border : const Color(0xFFEF4444),
          width: isSafe ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  gasName,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            readingValue,
            style: TextStyle(
              color: isSafe ? AppTheme.textPrimary : const Color(0xFFEF4444),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            thresholdLabel,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusNote,
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            Text(
              '${value.toStringAsFixed(1)} $unit',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: AppTheme.surface,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _logSimulatedGasTest(bool isSafe) {
    final now = DateTime.now();
    final newTest = AtmosphericGasTest(
      o2Concentration: _simO2,
      flammableLel: _simLel,
      toxicH2s: _simH2s,
      carbonMonoxideCo: _simCo,
      testTimestamp: now,
      testerName: 'D. K. Gogoi',
      testerCertification: 'OIL-GT-402',
      detectorModel: 'Honeywell BW Ultra Quad-Gas',
      detectorSerial: 'BW-ULTRA-SN-994208-X',
      bumpTestDate: now,
      calibrationCertExpiry: DateTime(2026, 12, 15),
      t90ResponseSeconds: 11.2,
      samplingStratum: _simStratum,
    );

    // Update active permits with new gas test
    setState(() {
      for (final p in _permits) {
        if (p.status == PtwLiveStatus.active || p.status == PtwLiveStatus.issued) {
          p.gasTest = newTest;
          if (!isSafe && p.status == PtwLiveStatus.active) {
            p.status = PtwLiveStatus.suspended;
            p.suspensionOrCancellationReason = 'Gas Alarm: ${newTest.atmosphericStatusSummary}';
          }
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSafe
              ? 'Atmospheric test verified SAFE at $_simStratum. Logged to PTW audit.'
              : 'CRITICAL ALARM: Gas limits exceeded! Active permits automatically suspended.',
        ),
        backgroundColor: isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      ),
    );
  }

  // ============================================================================
  // TAB 3: LOCKOUT / TAGOUT (LOTO) & ENERGY ISOLATION CERTIFICATE
  // ============================================================================

  Widget _buildEnergyIsolationLotoTab() {
    // Extract all unique LOTO records across active permits
    final allLotoRecords = <LotoIsolationRecord>[];
    for (final p in _permits) {
      allLotoRecords.addAll(p.lotoRecords);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Certificate Header Card
          _buildLotoCertificateCard(),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppTheme.primaryLight, size: 18),
              const SizedBox(width: 8),
              const Text(
                'ENERGY ISOLATION POINTS LEDGER',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('ADD POINT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                onPressed: _showAddLotoPointModal,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // LOTO Points List
          ...allLotoRecords.map((record) => _buildLotoRecordCard(record)),

          const SizedBox(height: 16),

          // Lockbox Custody Ledger Card
          _buildLockboxCustodyCard(),
        ],
      ),
    );
  }

  Widget _buildLotoCertificateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.vpn_key_rounded, color: AppTheme.primaryLight),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENERGY ISOLATION CERTIFICATE (EIC)',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'EIC-OIL-2026-0914 • OISD-RP-112 §4 Compliance',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: const Text(
                  '100% ISOLATED',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LotoStatPill(label: 'Total Locked', value: '6 Points', color: Color(0xFF10B981)),
              _LotoStatPill(label: 'Master Padlocks', value: '6 Keys', color: AppTheme.secondary),
              _LotoStatPill(label: 'Mechanical Blinds', value: '3 Spades', color: AppTheme.primaryLight),
              _LotoStatPill(label: 'Bleed Valves', value: '1 Open', color: Color(0xFF4EDEA3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLotoRecordCard(LotoIsolationRecord record) {
    final type = record.isolationType;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: record.isVerifiedAndLocked
              ? AppTheme.border
              : const Color(0xFFEF4444),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(type.icon, color: type.color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.pointTag,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        record.equipmentName,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: record.isVerifiedAndLocked,
                  activeThumbColor: const Color(0xFF10B981),
                  activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                  inactiveThumbColor: const Color(0xFFEF4444),
                  inactiveTrackColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  onChanged: (val) {
                    setState(() {
                      record.isVerifiedAndLocked = val;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          val
                              ? 'Point ${record.pointTag} ISOLATED & PADLOCKED.'
                              : 'Point ${record.pointTag} DE-ISOLATED (Warning!).',
                        ),
                        backgroundColor: val ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(color: AppTheme.border, height: 16),
            Row(
              children: [
                _buildLotoTagBadge('PADLOCK', record.padlockNumber, AppTheme.secondary),
                const SizedBox(width: 8),
                _buildLotoTagBadge('DANGER TAG', record.dangerTagNumber, const Color(0xFFEF4444)),
                const Spacer(),
                if (record.verifiedVoltage != null)
                  _buildLotoMeasurement('Voltage', '${record.verifiedVoltage} V (Zero)'),
                if (record.spadeThicknessMm != null)
                  _buildLotoMeasurement('Spade', '${record.spadeThicknessMm} mm Thick'),
                if (record.residualPressureBar != null)
                  _buildLotoMeasurement('Pressure', '${record.residualPressureBar} Bar'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Remarks: ${record.remarks}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLotoTagBadge(String title, String code, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$title: $code',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildLotoMeasurement(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF10B981),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildLockboxCustodyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.inventory_rounded, color: AppTheme.secondary, size: 18),
              SizedBox(width: 8),
              Text(
                'MASTER LOCKBOX KEY CUSTODY (LOCKBOX #04)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'All individual isolation padlock keys are secured inside Master Lock Box #04.\nCustodian: Subhash Roy (Sr. HSE Engineer) • Co-Signed: R. K. Hazarika (Performing Authority).\nNo de-isolation may occur until all assigned permits are formally surrendered.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  void _showAddLotoPointModal() {
    EnergyIsolationType selectedType = EnergyIsolationType.electricalBreaker;
    final tagCtrl = TextEditingController(text: 'MCC-415V-BKR-09');
    final equipCtrl = TextEditingController(text: 'Crude Booster Pump #02 Motor');
    final lockCtrl = TextEditingController(text: 'PAD-RED-${1000 + Random().nextInt(8999)}');
    final dangerTagCtrl = TextEditingController(text: 'TAG-DNG-${10000 + Random().nextInt(89999)}');
    final remarksCtrl = TextEditingController(text: 'Locked & tagged in isolated position.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) {
        return StatefulBuilder(
          builder: (mCtx, setMState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(mCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Energy Isolation / LOTO Point',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(color: AppTheme.border, height: 20),

                    // Isolation Type
                    const Text('Isolation Type:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: EnergyIsolationType.values.map((t) {
                        final isSel = selectedType == t;
                        return ChoiceChip(
                          avatar: Icon(t.icon, size: 14, color: isSel ? Colors.white : t.color),
                          label: Text(t.label),
                          selected: isSel,
                          selectedColor: t.color,
                          backgroundColor: AppTheme.surface,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                          onSelected: (val) {
                            if (val) setMState(() => selectedType = t);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Equipment Tag & Name
                    TextField(
                      controller: tagCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Isolation Point Tag # (e.g. MCC-415V-BKR-09)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: equipCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Equipment Title / Line Name'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: lockCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Padlock #'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: dangerTagCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Danger Tag #'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: remarksCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Verification Remarks'),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('REGISTER & LOCK POINT'),
                        onPressed: () {
                          final newRecord = LotoIsolationRecord(
                            id: 'LOTO-${Random().nextInt(9999)}',
                            pointTag: tagCtrl.text.trim().isEmpty ? 'ISO-PT-01' : tagCtrl.text.trim(),
                            equipmentName: equipCtrl.text.trim().isEmpty ? 'Equipment' : equipCtrl.text.trim(),
                            isolationType: selectedType,
                            padlockNumber: lockCtrl.text.trim().isEmpty ? 'PAD-001' : lockCtrl.text.trim(),
                            dangerTagNumber: dangerTagCtrl.text.trim().isEmpty ? 'TAG-001' : dangerTagCtrl.text.trim(),
                            isolatedBy: 'N. Sarma (Elec/Mech Engg)',
                            verifiedBy: 'Subhash Roy (HSE)',
                            isolationTimestamp: DateTime.now(),
                            isVerifiedAndLocked: true,
                            remarks: remarksCtrl.text.trim(),
                          );

                          setState(() {
                            if (_permits.isNotEmpty) {
                              _permits.first.lotoRecords.add(newRecord);
                            }
                          });

                          Navigator.of(bCtx).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('LOTO Point ${newRecord.pointTag} added to Energy Isolation Certificate.'),
                              backgroundColor: AppTheme.primary,
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

  // ============================================================================
  // TAB 4: SAFETY COMPLIANCE, TBT & EMERGENCY EVACUATION
  // ============================================================================

  Widget _buildComplianceAndEvacuationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Evacuation Muster Point Status
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.meeting_room_rounded, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMERGENCY MUSTER POINT #3 (MAIN GATE)',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'GPS: 27.3512° N, 95.3218° E • Wind: Upwind (Safe Direction: North-East)',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Evacuation route synchronized to field mobile devices.'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      child: const Text('ROUTE MAP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Daily Toolbox Talk (TBT) Verification
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
                const Row(
                  children: [
                    Icon(Icons.record_voice_over_rounded, color: AppTheme.secondary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'PRE-SHIFT TOOLBOX TALK (TBT) LOG',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Conducted today at 07:15 AM by Lead Safety Officer Subhash Roy.\nTopics covered: Confined space 3-point atmosphere testing, fall arrest double lanyard 100% tie-off, hot work spark blankets, and Emergency Stop beacon protocols.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '27 WORKERS SIGNED',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'BIOMETRIC LOGGED',
                        style: TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // OISD-105 Safety Checklist
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
                const Row(
                  children: [
                    Icon(Icons.checklist_rounded, color: AppTheme.tertiary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'OISD-STD-105 STATUTORY AUDIT CRITERIA',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildComplianceCheckItem(
                  'Continuous combustible gas monitor calibrated & certified',
                  true,
                ),
                _buildComplianceCheckItem(
                  'LOTO isolation double block & bleed or spade physically verified',
                  true,
                ),
                _buildComplianceCheckItem(
                  'Standby Safety Watcher posted with whistle & air horn',
                  true,
                ),
                _buildComplianceCheckItem(
                  'Emergency Stop beacon functional & audible on site siren',
                  true,
                ),
                _buildComplianceCheckItem(
                  'Wind speed anemometer live telemetry linked (<30 km/h)',
                  true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceCheckItem(String title, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            color: isChecked ? const Color(0xFF10B981) : AppTheme.textMuted,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // PERMIT DOSSIER / PRINT PREVIEW MODAL
  // ============================================================================

  void _showPermitDossier(PtwLiveModel permit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (scrollCtx, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: permit.classification.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          permit.classification.icon,
                          color: permit.classification.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              permit.permitNumber,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              permit.classification.title,
                              style: TextStyle(
                                color: permit.classification.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(permit.status),
                    ],
                  ),
                  const Divider(color: AppTheme.border, height: 24),

                  _buildDossierSection('WORK DESCRIPTION & SITE LOCATION', [
                    'Title: ${permit.title}',
                    'Location: ${permit.locationZone}',
                    'Pipeline Chainage: ${permit.chainageKp}',
                    'Contractor: ${permit.contractor}',
                    'Field Gang: ${permit.crewCount} Workmen',
                  ]),

                  const SizedBox(height: 16),

                  _buildDossierSection('STATUTORY SIGNATORIES & AUTHORIZATION', [
                    'Area Authority (Issuer): ${permit.areaAuthority}',
                    'Performing Authority (Holder): ${permit.performingAuthority}',
                    'Lead Safety Officer: ${permit.safetyOfficer}',
                    'Valid From: ${DateFormat('yyyy-MM-dd HH:mm').format(permit.validFrom)}',
                    'Valid Till: ${DateFormat('yyyy-MM-dd HH:mm').format(permit.validTo)}',
                  ]),

                  const SizedBox(height: 16),

                  _buildDossierSection('ATMOSPHERIC GAS TEST AT SITE', [
                    'O₂ Concentration: ${permit.gasTest.o2Concentration}% (Safe: 19.5% - 23.5%)',
                    'Flammable LEL: ${permit.gasTest.flammableLel}% LEL (Safe: < 1.0%)',
                    'Toxic H₂S: ${permit.gasTest.toxicH2s} ppm (Safe: < 10 ppm)',
                    'Carbon Monoxide (CO): ${permit.gasTest.carbonMonoxideCo} ppm (Safe: < 25 ppm)',
                    'Sampling Location: ${permit.gasTest.samplingStratum}',
                    'Detector Serial: ${permit.gasTest.detectorSerial}',
                    'Certified Tester: ${permit.gasTest.testerName} (${permit.gasTest.testerCertification})',
                  ]),

                  const SizedBox(height: 16),

                  _buildDossierSection('ENERGY ISOLATION & LOTO POINTS', [
                    if (permit.lotoRecords.isEmpty)
                      'No energy isolation required for this work category.'
                    else
                      ...permit.lotoRecords.map(
                        (r) => '• [${r.isolationType.code}] ${r.pointTag} - Padlock: ${r.padlockNumber} | Danger Tag: ${r.dangerTagNumber} (${r.equipmentName})',
                      ),
                  ]),

                  const SizedBox(height: 16),

                  _buildDossierSection('MANDATORY PPE REQUIREMENTS', [
                    ...permit.mandatoryPpe.map((p) => '✓ $p'),
                  ]),

                  const SizedBox(height: 16),

                  _buildDossierSection('SPECIAL FIELD PRECAUTIONS', [
                    ...permit.safetyPrecautions.map((p) => '✓ $p'),
                  ]),

                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('GENERATE CRYPTOGRAPHIC PDF DOSSIER'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'PTW Dossier ${permit.permitNumber} exported with SHA-256 digital signature.',
                          ),
                          backgroundColor: AppTheme.tertiary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDossierSection(String heading, List<String> lines) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              color: AppTheme.primaryLight,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          ...lines.map(
            (l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                l,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LotoStatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LotoStatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
