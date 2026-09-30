import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DOMAIN MODELS & ENUMS
// ============================================================================

enum HotTapOperationPhase {
  fittingWelding,
  hotTappingLive,
  dualStoppleIsolation,
  lorCompletionPlug,
}

enum CutterPhase {
  retracted('Retracted (Clearance)', 0.0, 150.0),
  pilotContact('Pilot Drill Contact', 150.0, 185.0),
  pilotRetentionEngaged('Retention Wire Engaged', 185.0, 210.0),
  pilotBreakthrough('Pilot Breakthrough', 210.0, 235.0),
  cutterShellContact('Trepanning Cutter Contact', 235.0, 250.0),
  trepanningCut('Active Trepanning Cut', 250.0, 275.0),
  couponSevered('Coupon Fully Severed', 275.0, 290.0),
  couponRetracted('Cutter Retracted w/ Coupon', 290.0, 310.0);

  final String label;
  final double startDepthMm;
  final double endDepthMm;
  const CutterPhase(this.label, this.startDepthMm, this.endDepthMm);
}

enum CouponRetentionState {
  disengaged('Disengaged', Color(0xFF64748B), Icons.link_off_rounded),
  armed('Armed / Spring Loaded', Color(0xFFFFB95F), Icons.warning_amber_rounded),
  latched('U-Wire Catch Latched', Color(0xFF38BDF8), Icons.lock_clock_rounded),
  securedVerified('Coupon Retained & Verified', Color(0xFF4EDEA3), Icons.verified_rounded);

  final String label;
  final Color color;
  final IconData icon;
  const CouponRetentionState(this.label, this.color, this.icon);
}

enum BypassValveState {
  closed('Closed', Color(0xFF64748B)),
  equalizing('Equalizing Pressure...', Color(0xFFFFB95F)),
  openEqualized('Equalized (ΔP ≤ 0.1 bar)', Color(0xFF4EDEA3));

  final String label;
  final Color color;
  const BypassValveState(this.label, this.color);
}

enum SandwichValveState {
  closed('Closed & Tested', Color(0xFF64748B)),
  openLocked('100% Full Bore Open', Color(0xFF4EDEA3)),
  recovering('Demounting from LOR', Color(0xFFFFB95F));

  final String label;
  final Color color;
  const SandwichValveState(this.label, this.color);
}

class PipeSpec {
  final String tag;
  final String pipelineName;
  final double chainageKp;
  final double nominalDiaInch;
  final double outerDiaMm;
  final double wallThicknessMm;
  final String steelGrade;
  final double smysMpa;
  final double designPressureBar;
  final double operatingPressureBar;
  final double gasVelocityMs;
  final double gasTempC;

  const PipeSpec({
    required this.tag,
    required this.pipelineName,
    required this.chainageKp,
    required this.nominalDiaInch,
    required this.outerDiaMm,
    required this.wallThicknessMm,
    required this.steelGrade,
    required this.smysMpa,
    required this.designPressureBar,
    required this.operatingPressureBar,
    required this.gasVelocityMs,
    required this.gasTempC,
  });
}

class WeldingParams {
  final String process;
  final String electrode;
  final double currentAmps;
  final double voltageVolts;
  final double travelSpeedMmMin;
  final double arcEfficiency;
  final double preheatTempC;
  final double interpassTempC;

  const WeldingParams({
    required this.process,
    required this.electrode,
    required this.currentAmps,
    required this.voltageVolts,
    required this.travelSpeedMmMin,
    required this.arcEfficiency,
    required this.preheatTempC,
    required this.interpassTempC,
  });

  WeldingParams copyWith({
    String? process,
    String? electrode,
    double? currentAmps,
    double? voltageVolts,
    double? travelSpeedMmMin,
    double? arcEfficiency,
    double? preheatTempC,
    double? interpassTempC,
  }) {
    return WeldingParams(
      process: process ?? this.process,
      electrode: electrode ?? this.electrode,
      currentAmps: currentAmps ?? this.currentAmps,
      voltageVolts: voltageVolts ?? this.voltageVolts,
      travelSpeedMmMin: travelSpeedMmMin ?? this.travelSpeedMmMin,
      arcEfficiency: arcEfficiency ?? this.arcEfficiency,
      preheatTempC: preheatTempC ?? this.preheatTempC,
      interpassTempC: interpassTempC ?? this.interpassTempC,
    );
  }

  double get netHeatInputKjPerMm {
    if (travelSpeedMmMin <= 0) return 0;
    // H = (V * I * 60 * eta) / (travelSpeed * 1000)
    return (voltageVolts * currentAmps * 60.0 * arcEfficiency) / (travelSpeedMmMin * 1000.0);
  }
}

class BattelleCalculation {
  final double heatInputKjPerMm;
  final double peakInnerTempC;
  final double coolingTimeT85Sec;
  final double predictedHazHardnessHv;
  final double minSafeHeatInputKjMm;
  final double maxSafeHeatInputKjMm;
  final bool isSafe;
  final String safetyStatus;
  final Color statusColor;

  const BattelleCalculation({
    required this.heatInputKjPerMm,
    required this.peakInnerTempC,
    required this.coolingTimeT85Sec,
    required this.predictedHazHardnessHv,
    required this.minSafeHeatInputKjMm,
    required this.maxSafeHeatInputKjMm,
    required this.isSafe,
    required this.safetyStatus,
    required this.statusColor,
  });
}

class BattelleModelEngine {
  /// Evaluates Battelle thermal analysis model for in-service pipeline welding.
  /// PRCI / Battelle formula evaluates forced convection cooling by gas flow.
  static BattelleCalculation evaluate({
    required PipeSpec pipe,
    required WeldingParams welding,
  }) {
    final double h = welding.netHeatInputKjPerMm;
    final double t = pipe.wallThicknessMm;
    final double v = pipe.gasVelocityMs;
    final double p = pipe.operatingPressureBar;
    final double tGas = pipe.gasTempC;

    // Convective heat transfer coefficient correlation
    final double convectiveFactor = math.sqrt(1.0 + 0.25 * v * (p / 50.0));

    // Peak inside surface temperature (°C):
    // Battelle model: T_inner = T_gas + (k1 * H) / (t * convectiveFactor)
    final double deltaT = (2800.0 * h) / (math.max(4.0, t) * convectiveFactor);
    final double peakInnerTemp = tGas + deltaT;

    // Cooling rate t8/5 (time in seconds to cool from 800°C to 500°C):
    // Under high gas flow, cooling is accelerated.
    final double coolingT85 = (16.5 * math.pow(h, 1.4)) / (math.sqrt(math.max(4.0, t)) * (1.0 + 0.15 * v));

    // Predicted HAZ Vickers Hardness (HV):
    // Lower cooling time -> higher hardness. Max acceptable is 250 - 300 HV.
    final double hazHardness = 160.0 + (260.0 / (1.0 + 0.55 * math.max(0.4, coolingT85)));

    // Maximum safe heat input to prevent burn-through (API RP 2201 threshold):
    final double maxSafeH = math.min(1.45, ((580.0 - tGas) * t * convectiveFactor) / 4500.0);

    // Minimum safe heat input to avoid fast quench cracking (hardness <= 300 HV):
    final double minSafeH = math.max(0.55, 0.045 * t * math.sqrt(1.0 + 0.15 * v));

    bool safe = true;
    String status = 'SAFE WINDOW (ASME B31.8 / API 2201)';
    Color color = const Color(0xFF4EDEA3);

    if (h > maxSafeH) {
      safe = false;
      status = 'BURN-THROUGH DANGER (H > Max Limit)';
      color = const Color(0xFFFF5252);
    } else if (h < minSafeH) {
      safe = false;
      status = 'HYDROGEN CRACKING RISK (Hardness > 300 HV)';
      color = const Color(0xFFFFB95F);
    } else if (peakInnerTemp > 500.0) {
      status = 'ELEVATED INNER TEMP (Monitor Closely)';
      color = const Color(0xFFFFB95F);
    }

    return BattelleCalculation(
      heatInputKjPerMm: h,
      peakInnerTempC: peakInnerTemp,
      coolingTimeT85Sec: coolingT85,
      predictedHazHardnessHv: hazHardness,
      minSafeHeatInputKjMm: minSafeH,
      maxSafeHeatInputKjMm: maxSafeH,
      isSafe: safe,
      safetyStatus: status,
      statusColor: color,
    );
  }
}

class TappingMachineTelemetry {
  final double strokeDepthMm;
  final double targetDepthMm;
  final CutterPhase phase;
  final CouponRetentionState retentionState;
  final double retentionWireTensionKn;
  final double gearboxHydraulicRpm;
  final double feedRateMmMin;
  final double hydraulicPressureBar;
  final double cuttingTorqueNm;
  final double housingPressureBar;
  final double pipelinePressureBar;
  final BypassValveState bypassValveState;
  final SandwichValveState sandwichValveState;
  final double cutterMotorTempC;

  const TappingMachineTelemetry({
    required this.strokeDepthMm,
    required this.targetDepthMm,
    required this.phase,
    required this.retentionState,
    required this.retentionWireTensionKn,
    required this.gearboxHydraulicRpm,
    required this.feedRateMmMin,
    required this.hydraulicPressureBar,
    required this.cuttingTorqueNm,
    required this.housingPressureBar,
    required this.pipelinePressureBar,
    required this.bypassValveState,
    required this.sandwichValveState,
    required this.cutterMotorTempC,
  });

  double get differentialPressureBar => (housingPressureBar - pipelinePressureBar).abs();
  double get progressRatio => (strokeDepthMm / targetDepthMm).clamp(0.0, 1.0);
}

class DualStoppleTelemetry {
  final double stopple1CylinderPressureBar;
  final double stopple2CylinderPressureBar;
  final bool stopple1Seated;
  final bool stopple2Seated;
  final double stopple1SealBorePercent;
  final double stopple2SealBorePercent;
  final double isolatedChamberPressureBar;
  final double n2PurgeFlowM3h;
  final double n2TotalPurgedM3;
  final double sniffer1LelPercent;
  final double sniffer2LelPercent;
  final double sniffer3LelPercent;
  final double oxygenLevelPercent;
  final double temporaryBypassFlowMmscmd;
  final double temporaryBypassDiffPressureBar;
  final double temporaryBypassVelocityMs;
  final bool bypassActive;

  const DualStoppleTelemetry({
    required this.stopple1CylinderPressureBar,
    required this.stopple2CylinderPressureBar,
    required this.stopple1Seated,
    required this.stopple2Seated,
    required this.stopple1SealBorePercent,
    required this.stopple2SealBorePercent,
    required this.isolatedChamberPressureBar,
    required this.n2PurgeFlowM3h,
    required this.n2TotalPurgedM3,
    required this.sniffer1LelPercent,
    required this.sniffer2LelPercent,
    required this.sniffer3LelPercent,
    required this.oxygenLevelPercent,
    required this.temporaryBypassFlowMmscmd,
    required this.temporaryBypassDiffPressureBar,
    required this.temporaryBypassVelocityMs,
    required this.bypassActive,
  });

  double get maxSnifferLel => math.max(sniffer1LelPercent, math.max(sniffer2LelPercent, sniffer3LelPercent));
  bool get isHotWorkSafe => maxSnifferLel < 1.0 && oxygenLevelPercent < 1.0 && isolatedChamberPressureBar <= 0.05;
}

class LorCompletionData {
  final double plugDepthMm;
  final int lockedSegments;
  final int totalSegments;
  final double cavityBleedPressureBar;
  final bool isLorSealHolding;
  final bool sandwichValveRecovered;
  final String rtjGasketType;
  final double torqueTargetNm;
  final double torqueAppliedNm;
  final int torqueStarPassesCompleted;
  final double n2TestPressureBar;
  final bool n2TestVerified;

  const LorCompletionData({
    required this.plugDepthMm,
    required this.lockedSegments,
    required this.totalSegments,
    required this.cavityBleedPressureBar,
    required this.isLorSealHolding,
    required this.sandwichValveRecovered,
    required this.rtjGasketType,
    required this.torqueTargetNm,
    required this.torqueAppliedNm,
    required this.torqueStarPassesCompleted,
    required this.n2TestPressureBar,
    required this.n2TestVerified,
  });

  bool get allSegmentsLocked => lockedSegments == totalSegments;
  bool get isTorqueComplete => torqueAppliedNm >= torqueTargetNm && torqueStarPassesCompleted >= 4;
}

class ChecklistItem {
  final String id;
  final String title;
  final String description;
  final String standardRef;
  final bool isCompleted;
  final String? inspector;
  final DateTime? timestamp;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.standardRef,
    required this.isCompleted,
    this.inspector,
    this.timestamp,
  });

  ChecklistItem copyWith({
    bool? isCompleted,
    String? inspector,
    DateTime? timestamp,
  }) {
    return ChecklistItem(
      id: id,
      title: title,
      description: description,
      standardRef: standardRef,
      isCompleted: isCompleted ?? this.isCompleted,
      inspector: inspector ?? this.inspector,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class HotTapStoppleScreen extends StatefulWidget {
  const HotTapStoppleScreen({super.key});

  @override
  State<HotTapStoppleScreen> createState() => _HotTapStoppleScreenState();
}

class _HotTapStoppleScreenState extends State<HotTapStoppleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _telemetryTimer;

  // Pipeline Configuration
  PipeSpec _pipeSpec = const PipeSpec(
    tag: 'OIL-DUL-NUM-24-001',
    pipelineName: 'Duliajan-Numaligarh 24" Natural Gas Trunkline',
    chainageKp: 42.850,
    nominalDiaInch: 24.0,
    outerDiaMm: 610.0,
    wallThicknessMm: 11.91,
    steelGrade: 'API 5L Grade X65 (PSL2)',
    smysMpa: 448.0,
    designPressureBar: 98.0,
    operatingPressureBar: 68.5,
    gasVelocityMs: 4.2,
    gasTempC: 24.0,
  );

  // Welding Parameters
  WeldingParams _weldingParams = const WeldingParams(
    process: 'SMAW (Shielded Metal Arc)',
    electrode: 'AWS E7018-H4R Low Hydrogen',
    currentAmps: 130.0,
    voltageVolts: 22.0,
    travelSpeedMmMin: 165.0,
    arcEfficiency: 0.80,
    preheatTempC: 115.0,
    interpassTempC: 155.0,
  );

  // Live Telemetry States
  late TappingMachineTelemetry _tapTelemetry;
  late DualStoppleTelemetry _stoppleTelemetry;
  late LorCompletionData _lorData;
  late List<ChecklistItem> _checklist;

  bool _isLiveSimulating = true;
  int _simulationTick = 0;

  // History for fl_chart telemetry plotting
  final List<FlSpot> _depthHistory = [];
  final List<FlSpot> _torqueHistory = [];
  final List<FlSpot> _rpmHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _tapTelemetry = const TappingMachineTelemetry(
      strokeDepthMm: 254.2,
      targetDepthMm: 310.0,
      phase: CutterPhase.trepanningCut,
      retentionState: CouponRetentionState.latched,
      retentionWireTensionKn: 2.85,
      gearboxHydraulicRpm: 19.4,
      feedRateMmMin: 0.38,
      hydraulicPressureBar: 115.0,
      cuttingTorqueNm: 865.0,
      housingPressureBar: 68.4,
      pipelinePressureBar: 68.5,
      bypassValveState: BypassValveState.openEqualized,
      sandwichValveState: SandwichValveState.openLocked,
      cutterMotorTempC: 48.6,
    );

    _stoppleTelemetry = const DualStoppleTelemetry(
      stopple1CylinderPressureBar: 148.0,
      stopple2CylinderPressureBar: 150.0,
      stopple1Seated: true,
      stopple2Seated: true,
      stopple1SealBorePercent: 100.0,
      stopple2SealBorePercent: 100.0,
      isolatedChamberPressureBar: 0.02,
      n2PurgeFlowM3h: 380.0,
      n2TotalPurgedM3: 2450.0,
      sniffer1LelPercent: 0.14,
      sniffer2LelPercent: 0.08,
      sniffer3LelPercent: 0.11,
      oxygenLevelPercent: 0.16,
      temporaryBypassFlowMmscmd: 4.82,
      temporaryBypassDiffPressureBar: 0.74,
      temporaryBypassVelocityMs: 8.4,
      bypassActive: true,
    );

    _lorData = const LorCompletionData(
      plugDepthMm: 310.0,
      lockedSegments: 6,
      totalSegments: 6,
      cavityBleedPressureBar: 0.0,
      isLorSealHolding: true,
      sandwichValveRecovered: false,
      rtjGasketType: 'Soft Iron Ring R-73 (ASME B16.20)',
      torqueTargetNm: 1450.0,
      torqueAppliedNm: 1450.0,
      torqueStarPassesCompleted: 4,
      n2TestPressureBar: 75.0,
      n2TestVerified: true,
    );

    _checklist = [
      ChecklistItem(
        id: 'CHK-01',
        title: 'Full Encirclement Split Tee Longitudinal Seams NDT',
        description: '100% Ultrasonic & Magnetic Particle examination of side backing strip welds.',
        standardRef: 'ASME B31.8 §841.27 / API RP 2201',
        isCompleted: true,
        inspector: 'R. K. Sharma (CSWIP 3.2)',
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      ChecklistItem(
        id: 'CHK-02',
        title: 'Battelle Model Safe Heat Input Envelope Validation',
        description: 'Confirmed welding heat input within Battelle safe limits (< 580°C inner wall).',
        standardRef: 'PRCI Battelle / API 2201 §5.3',
        isCompleted: true,
        inspector: 'M. Bordoloi (Welding Engineer)',
        timestamp: DateTime.now().subtract(const Duration(hours: 10)),
      ),
      ChecklistItem(
        id: 'CHK-03',
        title: 'Circumferential Fillet Welds Temper Bead Technique',
        description: 'Controlled buttering passes & temper beads, interpass temp 150°C, zero cracking.',
        standardRef: 'ASME Sec IX / API 1104 App B',
        isCompleted: true,
        inspector: 'R. K. Sharma (CSWIP 3.2)',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      ChecklistItem(
        id: 'CHK-04',
        title: 'Tapping Valve & Housing Hydrostatic Test',
        description: 'Shell & seat tested to 1.1x line pressure (76 bar) for 30 minutes with nitrogen/water.',
        standardRef: 'API RP 2201 §6.2',
        isCompleted: true,
        inspector: 'A. Saikia (QC Lead)',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ChecklistItem(
        id: 'CHK-05',
        title: 'Pilot Drill Coupon Retention U-Wire Mechanical Verification',
        description: 'Coupon retention wires primed, free spring action verified prior to valve mounting.',
        standardRef: 'TDW Hot Tap Operating Manual',
        isCompleted: true,
        inspector: 'D. Gohain (Hot Tap Specialist)',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ChecklistItem(
        id: 'CHK-06',
        title: 'Dual Stopple Chamber N2 Purge & LEL Gas Sniff Test',
        description: 'Hydrocarbon level verified < 1.0% LEL across 3 sniffer probe ports.',
        standardRef: 'OISD-GDN-115 / API RP 2201',
        isCompleted: true,
        inspector: 'S. Barua (HSE Officer)',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ChecklistItem(
        id: 'CHK-07',
        title: 'Lock-O-Ring (LOR) Completion Plug Setting & Cavity Bleed',
        description: '6 segments expanded into neck groove, pressure bled to 0.0 bar, zero seal leak.',
        standardRef: 'API 2201 §8.1 / ASME B31.8',
        isCompleted: false,
      ),
      ChecklistItem(
        id: 'CHK-08',
        title: 'Blind Flange Calibrated Hydraulic Torquing (1450 Nm)',
        description: 'Criss-cross star pattern torquing of 20x 1-5/8" B7 studs with R-73 RTJ gasket.',
        standardRef: 'ASME PCC-1 / B16.5 Class 600',
        isCompleted: false,
      ),
    ];

    // Seed fl_chart initial points
    for (int i = 0; i < 20; i++) {
      _depthHistory.add(FlSpot(i.toDouble(), 230.0 + (i * 1.2)));
      _torqueHistory.add(FlSpot(i.toDouble(), 820.0 + (math.sin(i) * 35.0)));
      _rpmHistory.add(FlSpot(i.toDouble(), 19.2 + (math.cos(i) * 0.4)));
    }

    _startTelemetryStream();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startTelemetryStream() {
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (!_isLiveSimulating) return;

      setState(() {
        _simulationTick++;
        final rand = math.Random();

        final double jitterDepth = (_tapTelemetry.strokeDepthMm < _tapTelemetry.targetDepthMm)
            ? _tapTelemetry.strokeDepthMm + 0.15
            : _tapTelemetry.strokeDepthMm;

        CutterPhase currentPhase = _tapTelemetry.phase;
        CouponRetentionState retentionState = _tapTelemetry.retentionState;

        if (jitterDepth < 185.0) {
          currentPhase = CutterPhase.pilotContact;
        } else if (jitterDepth < 210.0) {
          currentPhase = CutterPhase.pilotRetentionEngaged;
          retentionState = CouponRetentionState.latched;
        } else if (jitterDepth < 235.0) {
          currentPhase = CutterPhase.pilotBreakthrough;
        } else if (jitterDepth < 250.0) {
          currentPhase = CutterPhase.cutterShellContact;
        } else if (jitterDepth < 275.0) {
          currentPhase = CutterPhase.trepanningCut;
        } else if (jitterDepth < 290.0) {
          currentPhase = CutterPhase.couponSevered;
          retentionState = CouponRetentionState.securedVerified;
        } else {
          currentPhase = CutterPhase.couponRetracted;
          retentionState = CouponRetentionState.securedVerified;
        }

        final double newTorque = 850.0 + (rand.nextDouble() * 30.0 - 15.0);
        final double newRpm = 19.4 + (rand.nextDouble() * 0.3 - 0.15);
        final double newHydraulicPress = 115.0 + (rand.nextDouble() * 2.0 - 1.0);

        _tapTelemetry = TappingMachineTelemetry(
          strokeDepthMm: jitterDepth,
          targetDepthMm: _tapTelemetry.targetDepthMm,
          phase: currentPhase,
          retentionState: retentionState,
          retentionWireTensionKn: 2.80 + (rand.nextDouble() * 0.1),
          gearboxHydraulicRpm: newRpm,
          feedRateMmMin: 0.38,
          hydraulicPressureBar: newHydraulicPress,
          cuttingTorqueNm: newTorque,
          housingPressureBar: 68.5 + (rand.nextDouble() * 0.08 - 0.04),
          pipelinePressureBar: 68.5,
          bypassValveState: _tapTelemetry.bypassValveState,
          sandwichValveState: _tapTelemetry.sandwichValveState,
          cutterMotorTempC: 48.6 + (rand.nextDouble() * 0.2 - 0.1),
        );

        final double x = _simulationTick.toDouble() + 20;
        _depthHistory.add(FlSpot(x, jitterDepth));
        _torqueHistory.add(FlSpot(x, newTorque));
        _rpmHistory.add(FlSpot(x, newRpm));

        if (_depthHistory.length > 25) {
          _depthHistory.removeAt(0);
          _torqueHistory.removeAt(0);
          _rpmHistory.removeAt(0);
        }

        _stoppleTelemetry = DualStoppleTelemetry(
          stopple1CylinderPressureBar: 148.0 + (rand.nextDouble() * 0.4 - 0.2),
          stopple2CylinderPressureBar: 150.0 + (rand.nextDouble() * 0.4 - 0.2),
          stopple1Seated: _stoppleTelemetry.stopple1Seated,
          stopple2Seated: _stoppleTelemetry.stopple2Seated,
          stopple1SealBorePercent: 100.0,
          stopple2SealBorePercent: 100.0,
          isolatedChamberPressureBar: 0.02 + (rand.nextDouble() * 0.005),
          n2PurgeFlowM3h: _stoppleTelemetry.n2PurgeFlowM3h,
          n2TotalPurgedM3: _stoppleTelemetry.n2TotalPurgedM3 + 0.15,
          sniffer1LelPercent: (0.13 + rand.nextDouble() * 0.02).clamp(0.0, 5.0),
          sniffer2LelPercent: (0.08 + rand.nextDouble() * 0.01).clamp(0.0, 5.0),
          sniffer3LelPercent: (0.10 + rand.nextDouble() * 0.02).clamp(0.0, 5.0),
          oxygenLevelPercent: 0.16 + (rand.nextDouble() * 0.02 - 0.01),
          temporaryBypassFlowMmscmd: 4.82 + (rand.nextDouble() * 0.04 - 0.02),
          temporaryBypassDiffPressureBar: 0.74 + (rand.nextDouble() * 0.02 - 0.01),
          temporaryBypassVelocityMs: 8.4 + (rand.nextDouble() * 0.1 - 0.05),
          bypassActive: _stoppleTelemetry.bypassActive,
        );
      });
    });
  }

  // ==========================================================================
  // BUILD METHOD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final battelle = BattelleModelEngine.evaluate(
      pipe: _pipeSpec,
      welding: _weldingParams,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFacilityHeader(battelle),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWeldingBattelleTab(battelle),
                _buildTappingTelemetryTab(),
                _buildDualStoppleTab(),
                _buildLorCompletionChecklistTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // APP BAR & HEADER
  // ==========================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.precision_manufacturing_rounded, color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Hot Tapping & Stopple Ops',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'API RP 2201 / ASME B31.8',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                ),
              ),
            ],
          ),
          const Text(
            'In-Service Gas Pipeline Pressure Intervention & Isolation',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: _isLiveSimulating ? 'Pause Telemetry' : 'Resume Telemetry',
          icon: Icon(
            _isLiveSimulating ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
            color: _isLiveSimulating ? AppTheme.tertiary : AppTheme.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _isLiveSimulating = !_isLiveSimulating;
            });
            ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
              SnackBar(
                content: Text(
                  _isLiveSimulating ? 'Live SCADA Telemetry Streaming Resumed' : 'Telemetry Paused for Analysis',
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: AppTheme.surfaceCard,
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'Emergency Intervention Protocol',
          icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252)),
          onPressed: _showEmergencyProtocolDialog,
        ),
        IconButton(
          tooltip: 'Export Technical Dossier',
          icon: const Icon(Icons.file_download_outlined, color: AppTheme.primaryLight),
          onPressed: _showExportDossierDialog,
        ),
      ],
    );
  }

  Widget _buildFacilityHeader(BattelleCalculation battelle) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _pipeSpec.tag,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryLight,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          '•  Ch. KP ${_pipeSpec.chainageKp.toStringAsFixed(3)}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        Text(
                          '•  ${_pipeSpec.nominalDiaInch.toInt()}" NB (${_pipeSpec.steelGrade})',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _pipeSpec.pipelineName,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: battelle.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: battelle.statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      battelle.isSafe ? Icons.check_circle_rounded : Icons.warning_rounded,
                      size: 14,
                      color: battelle.statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      battelle.isSafe ? 'BATTELLE ENVELOPE: SAFE' : 'LIMIT BREACH: ATTENTION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: battelle.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildHeaderMetricChip(
                label: 'PRESSURE',
                value: '${_pipeSpec.operatingPressureBar.toStringAsFixed(1)} barg',
                icon: Icons.speed_rounded,
                color: AppTheme.primaryLight,
              ),
              const SizedBox(width: 8),
              _buildHeaderMetricChip(
                label: 'GAS VELOCITY',
                value: '${_pipeSpec.gasVelocityMs.toStringAsFixed(1)} m/s',
                icon: Icons.air_rounded,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 8),
              _buildHeaderMetricChip(
                label: 'WALL THICKNESS',
                value: '${_pipeSpec.wallThicknessMm.toStringAsFixed(2)} mm',
                icon: Icons.line_weight_rounded,
                color: const Color(0xFFC084FC),
              ),
              const SizedBox(width: 8),
              _buildHeaderMetricChip(
                label: 'MAX LEL',
                value: '${_stoppleTelemetry.maxSnifferLel.toStringAsFixed(2)}%',
                icon: Icons.local_fire_department_rounded,
                color: _stoppleTelemetry.isHotWorkSafe ? AppTheme.tertiary : const Color(0xFFFF5252),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetricChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(
            icon: Icon(Icons.flash_on_rounded, size: 18),
            text: 'Split Tee & Battelle',
          ),
          Tab(
            icon: Icon(Icons.hardware_rounded, size: 18),
            text: 'Tapping Telemetry',
          ),
          Tab(
            icon: Icon(Icons.call_split_rounded, size: 18),
            text: 'Dual Stopple & Purge',
          ),
          Tab(
            icon: Icon(Icons.fact_check_rounded, size: 18),
            text: 'LOR & QA/QC',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: SPLIT TEE WELDING & BATTELLE MODEL
  // ==========================================================================

  Widget _buildWeldingBattelleTab(BattelleCalculation battelle) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBattelleStatusBanner(battelle),
        const SizedBox(height: 16),
        _buildBattelleThermalChart(battelle),
        const SizedBox(height: 16),
        _buildWeldingHeatInputCalculator(),
        const SizedBox(height: 16),
        _buildSplitTeeWeldingProcedureCard(),
        const SizedBox(height: 16),
        _buildTemperBeadSequenceCard(),
      ],
    );
  }

  Widget _buildBattelleStatusBanner(BattelleCalculation battelle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: battelle.statusColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: battelle.statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.thermostat_rounded, color: battelle.statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      battelle.safetyStatus,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: battelle.statusColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'PRCI Battelle Thermal Model (ASME B31.8 / API RP 2201 In-Service Pipeline)',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBattelleStatItem(
                label: 'NET HEAT INPUT',
                value: '${battelle.heatInputKjPerMm.toStringAsFixed(2)} kJ/mm',
                sub: 'Safe: ${battelle.minSafeHeatInputKjMm.toStringAsFixed(2)} - ${battelle.maxSafeHeatInputKjMm.toStringAsFixed(2)}',
                color: AppTheme.primaryLight,
              ),
              _buildBattelleStatItem(
                label: 'PEAK INNER WALL TEMP',
                value: '${battelle.peakInnerTempC.toStringAsFixed(1)} °C',
                sub: 'Burn-through limit: 580 °C',
                color: battelle.peakInnerTempC > 580 ? const Color(0xFFFF5252) : AppTheme.tertiary,
              ),
              _buildBattelleStatItem(
                label: 'COOLING TIME (t8/5)',
                value: '${battelle.coolingTimeT85Sec.toStringAsFixed(2)} s',
                sub: 'Min threshold: 2.20 s',
                color: battelle.coolingTimeT85Sec < 2.2 ? const Color(0xFFFFB95F) : AppTheme.tertiary,
              ),
              _buildBattelleStatItem(
                label: 'PREDICTED HAZ HARDNESS',
                value: '${battelle.predictedHazHardnessHv.toStringAsFixed(0)} HV',
                sub: 'NACE Max: 250 - 300 HV',
                color: battelle.predictedHazHardnessHv > 300 ? const Color(0xFFFF5252) : AppTheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBattelleStatItem({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBattelleThermalChart(BattelleCalculation battelle) {
    final List<FlSpot> innerTempCurve = [];

    for (double h = 0.4; h <= 2.2; h += 0.1) {
      final double deltaT = (3450.0 * h) / (math.max(4.0, _pipeSpec.wallThicknessMm) * math.sqrt(1.0 + 0.38 * _pipeSpec.gasVelocityMs * (_pipeSpec.operatingPressureBar / 50.0)));
      innerTempCurve.add(FlSpot(h, _pipeSpec.gasTempC + deltaT));
    }

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Battelle Safe Operating Heat Input Envelope',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Inner Pipe Temp (°C) vs Heat Input (kJ/mm) at ${_pipeSpec.gasVelocityMs} m/s Gas Quench',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF38BDF8), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('Inner Temp', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                    const SizedBox(width: 10),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF5252), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('Burn Limit', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0.4,
                maxX: 2.2,
                minY: 0,
                maxY: 800,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: 200,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}°C',
                        style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 0.4,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toStringAsFixed(1)}k',
                        style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.border, width: 1),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 580,
                      color: const Color(0xFFFF5252),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 6, top: 2),
                        style: const TextStyle(fontSize: 9, color: Color(0xFFFF5252), fontWeight: FontWeight.bold),
                        labelResolver: (line) => 'Burn-Through Limit (580°C)',
                      ),
                    ),
                  ],
                  verticalLines: [
                    VerticalLine(
                      x: battelle.heatInputKjPerMm,
                      color: battelle.statusColor,
                      strokeWidth: 2,
                      dashArray: [4, 4],
                      label: VerticalLineLabel(
                        show: true,
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.only(left: 4, top: 4),
                        style: TextStyle(fontSize: 9, color: battelle.statusColor, fontWeight: FontWeight.bold),
                        labelResolver: (line) => 'H = ${battelle.heatInputKjPerMm.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: innerTempCurve,
                    isCurved: true,
                    color: const Color(0xFF38BDF8),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Safe Window: ${battelle.minSafeHeatInputKjMm.toStringAsFixed(2)} to ${battelle.maxSafeHeatInputKjMm.toStringAsFixed(2)} kJ/mm. '
                    'Gas flow rate (${_pipeSpec.gasVelocityMs} m/s) accelerates heat dissipation, necessitating temper-bead buttering to avoid martensitic HAZ cracking.',
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeldingHeatInputCalculator() {
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
                'Welding Parameters & Live Battelle Calculation',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Text(
                'Process: ${_weldingParams.process}',
                style: const TextStyle(fontSize: 11, color: AppTheme.secondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSliderTile(
            label: 'Welding Current (Amperes)',
            value: _weldingParams.currentAmps,
            unit: 'A',
            min: 80.0,
            max: 220.0,
            divisions: 28,
            onChanged: (val) {
              setState(() {
                _weldingParams = _weldingParams.copyWith(currentAmps: val);
              });
            },
          ),
          _buildSliderTile(
            label: 'Arc Voltage (Volts)',
            value: _weldingParams.voltageVolts,
            unit: 'V',
            min: 18.0,
            max: 30.0,
            divisions: 24,
            onChanged: (val) {
              setState(() {
                _weldingParams = _weldingParams.copyWith(voltageVolts: val);
              });
            },
          ),
          _buildSliderTile(
            label: 'Travel Speed (mm/min)',
            value: _weldingParams.travelSpeedMmMin,
            unit: 'mm/min',
            min: 100.0,
            max: 300.0,
            divisions: 40,
            onChanged: (val) {
              setState(() {
                _weldingParams = _weldingParams.copyWith(travelSpeedMmMin: val);
              });
            },
          ),
          _buildSliderTile(
            label: 'Carrier Pipe Gas Velocity (m/s)',
            value: _pipeSpec.gasVelocityMs,
            unit: 'm/s',
            min: 1.0,
            max: 12.0,
            divisions: 22,
            onChanged: (val) {
              setState(() {
                _pipeSpec = PipeSpec(
                  tag: _pipeSpec.tag,
                  pipelineName: _pipeSpec.pipelineName,
                  chainageKp: _pipeSpec.chainageKp,
                  nominalDiaInch: _pipeSpec.nominalDiaInch,
                  outerDiaMm: _pipeSpec.outerDiaMm,
                  wallThicknessMm: _pipeSpec.wallThicknessMm,
                  steelGrade: _pipeSpec.steelGrade,
                  smysMpa: _pipeSpec.smysMpa,
                  designPressureBar: _pipeSpec.designPressureBar,
                  operatingPressureBar: _pipeSpec.operatingPressureBar,
                  gasVelocityMs: val,
                  gasTempC: _pipeSpec.gasTempC,
                );
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reset Qualified WPS Values'),
                  onPressed: () {
                    setState(() {
                      _weldingParams = const WeldingParams(
                        process: 'SMAW (Shielded Metal Arc)',
                        electrode: 'AWS E7018-H4R Low Hydrogen',
                        currentAmps: 130.0,
                        voltageVolts: 22.0,
                        travelSpeedMmMin: 165.0,
                        arcEfficiency: 0.80,
                        preheatTempC: 115.0,
                        interpassTempC: 155.0,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Lock Welding Parameters'),
                  onPressed: () {
                    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                      const SnackBar(
                        content: Text('WPS Heat Input Qualified & Locked for Shift Inspection'),
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
    );
  }

  Widget _buildSliderTile({
    required String label,
    required double value,
    required String unit,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            Text(
              '${value.toStringAsFixed(1)} $unit',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryLight,
            inactiveTrackColor: AppTheme.border,
            thumbColor: AppTheme.primaryLight,
            overlayColor: AppTheme.primaryLight.withValues(alpha: 0.2),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSplitTeeWeldingProcedureCard() {
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
              const Icon(Icons.build_circle_rounded, color: AppTheme.secondary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Full Encirclement Split Tee Specification',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: AppTheme.border, width: 0.8),
            children: const [
              TableRow(
                decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Component / Parameter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Specification & Code Compliance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Split Tee Fitting', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('24" x 24" Class 600 Full Encirclement Extruded Branch (MSS SP-97 / ASME B31.8)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Side Longitudinal Seam', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Mild steel backing strips fitted. NO weld to carrier pipe beneath seam to avoid notch stresses.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('End Sleeve Fillet Welds', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Full penetration bevel / fillet. Temper bead procedure with E7018-H4R (max 4ml H2/100g).', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Preheat & Interpass', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Induction preheat maintained at 100°C - 120°C. Maximum interpass temp 175°C.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemperBeadSequenceCard() {
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
              const Icon(Icons.layers_rounded, color: AppTheme.primaryLight, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Circumferential Sleeve Temper Bead Layer Sequence',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBeadLayerItem(
            step: '1',
            layerName: 'Layer 1: Carrier Pipe Buttering Layer',
            detail: '2.5mm E7018-H4R electrode, stringer beads, heat input 0.75 kJ/mm. Sets base HAZ grain structure.',
            status: 'Completed & UT Cleared',
            statusColor: AppTheme.tertiary,
          ),
          const SizedBox(height: 8),
          _buildBeadLayerItem(
            step: '2',
            layerName: 'Layer 2: Second Buttering / Temper Layer',
            detail: '3.2mm electrode, 50% overlap onto Layer 1 to temper underlying hard martensitic HAZ.',
            status: 'Completed & UT Cleared',
            statusColor: AppTheme.tertiary,
          ),
          const SizedBox(height: 8),
          _buildBeadLayerItem(
            step: '3',
            layerName: 'Layer 3: Sleeve Fill Passes',
            detail: '3.2mm / 4.0mm electrodes, multi-pass fill between sleeve bevel and buttered carrier pipe.',
            status: 'Completed & UT Cleared',
            statusColor: AppTheme.tertiary,
          ),
          const SizedBox(height: 8),
          _buildBeadLayerItem(
            step: '4',
            layerName: 'Layer 4: Tempering Cap Pass',
            detail: 'Deposited 1.5mm setback from toe to temper the final HAZ without touching carrier pipe base metal.',
            status: 'In Progress / Final Visual Insp',
            statusColor: AppTheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildBeadLayerItem({
    required String step,
    required String layerName,
    required String detail,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
            child: Text(step, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryLight)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(layerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: HOT TAPPING MACHINE TELEMETRY
  // ==========================================================================

  Widget _buildTappingTelemetryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCutterDepthTrackerCard(),
        const SizedBox(height: 16),
        _buildCouponRetentionCard(),
        const SizedBox(height: 16),
        _buildPressureEqualizingBypassCard(),
        const SizedBox(height: 16),
        _buildGearboxHydraulicCard(),
        const SizedBox(height: 16),
        _buildLiveTelemetryChartCard(),
      ],
    );
  }

  Widget _buildCutterDepthTrackerCard() {
    final double depth = _tapTelemetry.strokeDepthMm;
    final double target = _tapTelemetry.targetDepthMm;
    final double progress = (depth / target).clamp(0.0, 1.0);

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hot Tap Machine Cutter Travel Depth',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'TDW 660 High-Pressure Machine • Stroke ${depth.toStringAsFixed(1)} / ${target.toStringAsFixed(0)} mm',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _tapTelemetry.phase.label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
            ),
          ),
          const SizedBox(height: 14),
          _buildMilestoneTimeline(depth),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                  label: const Text('Advance Cutter 5.0 mm'),
                  onPressed: () {
                    setState(() {
                      final newDepth = math.min(310.0, _tapTelemetry.strokeDepthMm + 5.0);
                      _tapTelemetry = TappingMachineTelemetry(
                        strokeDepthMm: newDepth,
                        targetDepthMm: _tapTelemetry.targetDepthMm,
                        phase: _tapTelemetry.phase,
                        retentionState: _tapTelemetry.retentionState,
                        retentionWireTensionKn: _tapTelemetry.retentionWireTensionKn,
                        gearboxHydraulicRpm: _tapTelemetry.gearboxHydraulicRpm,
                        feedRateMmMin: _tapTelemetry.feedRateMmMin,
                        hydraulicPressureBar: _tapTelemetry.hydraulicPressureBar,
                        cuttingTorqueNm: _tapTelemetry.cuttingTorqueNm,
                        housingPressureBar: _tapTelemetry.housingPressureBar,
                        pipelinePressureBar: _tapTelemetry.pipelinePressureBar,
                        bypassValveState: _tapTelemetry.bypassValveState,
                        sandwichValveState: _tapTelemetry.sandwichValveState,
                        cutterMotorTempC: _tapTelemetry.cutterMotorTempC,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                  label: const Text('Emergency Retract'),
                  onPressed: () {
                    setState(() {
                      _tapTelemetry = TappingMachineTelemetry(
                        strokeDepthMm: math.max(0.0, _tapTelemetry.strokeDepthMm - 20.0),
                        targetDepthMm: _tapTelemetry.targetDepthMm,
                        phase: CutterPhase.couponRetracted,
                        retentionState: _tapTelemetry.retentionState,
                        retentionWireTensionKn: _tapTelemetry.retentionWireTensionKn,
                        gearboxHydraulicRpm: 12.0,
                        feedRateMmMin: 0.0,
                        hydraulicPressureBar: 90.0,
                        cuttingTorqueNm: 250.0,
                        housingPressureBar: _tapTelemetry.housingPressureBar,
                        pipelinePressureBar: _tapTelemetry.pipelinePressureBar,
                        bypassValveState: _tapTelemetry.bypassValveState,
                        sandwichValveState: _tapTelemetry.sandwichValveState,
                        cutterMotorTempC: _tapTelemetry.cutterMotorTempC,
                      );
                    });
                    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                      const SnackBar(
                        content: Text('Hydraulic Retract Initiated: Cutter withdrawing into sandwich adapter'),
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
    );
  }

  Widget _buildMilestoneTimeline(double currentDepth) {
    const milestones = [
      {'depth': 0.0, 'label': 'Clearance'},
      {'depth': 185.0, 'label': 'Pilot Touch'},
      {'depth': 210.0, 'label': 'U-Wire Lock'},
      {'depth': 235.0, 'label': 'Pilot Thru'},
      {'depth': 250.0, 'label': 'Cutter Touch'},
      {'depth': 275.0, 'label': 'Coupon Cut'},
      {'depth': 310.0, 'label': 'Full Retract'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: milestones.map((m) {
          final depthVal = m['depth'] as double;
          final isPassed = currentDepth >= depthVal;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isPassed ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isPassed ? AppTheme.primaryLight : AppTheme.border,
                width: isPassed ? 1.2 : 0.8,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${depthVal.toInt()} mm',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isPassed ? AppTheme.primaryLight : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  m['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isPassed ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCouponRetentionCard() {
    final ret = _tapTelemetry.retentionState;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ret.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ret.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(ret.icon, color: ret.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilot Drill Coupon Retention Telemetry',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Dual spring-steel retention U-wires lock severed coupon to pilot bit',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ret.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ret.color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  ret.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ret.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildTelemetrySubStat(
                title: 'RETENTION TENSION',
                value: '${_tapTelemetry.retentionWireTensionKn.toStringAsFixed(2)} kN',
                status: 'Verified Latched',
                color: AppTheme.tertiary,
              ),
              _buildTelemetrySubStat(
                title: 'U-WIRE CLIPS',
                value: '2 of 2 Engaged',
                status: 'Dual Redundancy',
                color: AppTheme.primaryLight,
              ),
              _buildTelemetrySubStat(
                title: 'COUPON DIAMETER',
                value: '22.50" (571 mm)',
                status: 'API 5L X65 Steel',
                color: AppTheme.secondary,
              ),
              _buildTelemetrySubStat(
                title: 'COUPON MASS',
                value: '38.4 kg',
                status: 'WT 11.91 mm',
                color: const Color(0xFFC084FC),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded, color: AppTheme.tertiary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Safety Interlock Active: Cutter retraction cannot be executed unless coupon retention wire is latched and tension threshold >= 2.0 kN is validated.',
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureEqualizingBypassCard() {
    final diff = _tapTelemetry.differentialPressureBar;
    final isBalanced = diff <= 0.2;

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
                  Icon(Icons.swap_horizontal_circle_rounded, color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pressure Equalizing Bypass Line & Valve',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBalanced ? AppTheme.tertiary.withValues(alpha: 0.15) : const Color(0xFFFFB95F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isBalanced ? AppTheme.tertiary.withValues(alpha: 0.4) : const Color(0xFFFFB95F).withValues(alpha: 0.4)),
                ),
                child: Text(
                  isBalanced ? 'BALANCED (ΔP ≤ 0.1 bar)' : 'EQUALIZING...',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isBalanced ? AppTheme.tertiary : const Color(0xFFFFB95F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TAP HOUSING PRESSURE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      const SizedBox(height: 4),
                      Text('${_tapTelemetry.housingPressureBar.toStringAsFixed(2)} barg', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryLight)),
                      const SizedBox(height: 2),
                      const Text('Sandwich Adapter Cavity', style: TextStyle(fontSize: 9.5, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'ΔP ${diff.toStringAsFixed(2)}\nbar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isBalanced ? AppTheme.tertiary : const Color(0xFFFFB95F)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PIPELINE HEADER PRESSURE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      const SizedBox(height: 4),
                      Text('${_pipeSpec.operatingPressureBar.toStringAsFixed(2)} barg', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                      const SizedBox(height: 2),
                      const Text('Main Gas Flow Bore', style: TextStyle(fontSize: 9.5, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Equalize Bypass Line (2" Needle)'),
                  onPressed: () {
                    setState(() {
                      _tapTelemetry = TappingMachineTelemetry(
                        strokeDepthMm: _tapTelemetry.strokeDepthMm,
                        targetDepthMm: _tapTelemetry.targetDepthMm,
                        phase: _tapTelemetry.phase,
                        retentionState: _tapTelemetry.retentionState,
                        retentionWireTensionKn: _tapTelemetry.retentionWireTensionKn,
                        gearboxHydraulicRpm: _tapTelemetry.gearboxHydraulicRpm,
                        feedRateMmMin: _tapTelemetry.feedRateMmMin,
                        hydraulicPressureBar: _tapTelemetry.hydraulicPressureBar,
                        cuttingTorqueNm: _tapTelemetry.cuttingTorqueNm,
                        housingPressureBar: 68.5,
                        pipelinePressureBar: 68.5,
                        bypassValveState: BypassValveState.openEqualized,
                        sandwichValveState: _tapTelemetry.sandwichValveState,
                        cutterMotorTempC: _tapTelemetry.cutterMotorTempC,
                      );
                    });
                    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                      const SnackBar(
                        content: Text('Bypass needle valve open: Pressure equalized across 24" sandwich gate valve'),
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
    );
  }

  Widget _buildGearboxHydraulicCard() {
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
                  Icon(Icons.settings_input_component_rounded, color: AppTheme.tertiary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Hydraulic Power Unit & Gearbox Telemetry',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Text(
                'Motor Temp: ${_tapTelemetry.cutterMotorTempC.toStringAsFixed(1)}°C',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildTelemetrySubStat(
                title: 'CUTTER SPEED',
                value: '${_tapTelemetry.gearboxHydraulicRpm.toStringAsFixed(1)} RPM',
                status: 'Optimal 15-22 RPM',
                color: AppTheme.primaryLight,
              ),
              _buildTelemetrySubStat(
                title: 'FEED RATE',
                value: '${_tapTelemetry.feedRateMmMin.toStringAsFixed(2)} mm/min',
                status: 'Hydraulic Auto Feed',
                color: AppTheme.secondary,
              ),
              _buildTelemetrySubStat(
                title: 'CUTTING TORQUE',
                value: '${_tapTelemetry.cuttingTorqueNm.toStringAsFixed(0)} Nm',
                status: 'Limit: 1400 Nm',
                color: _tapTelemetry.cuttingTorqueNm > 1200 ? const Color(0xFFFF5252) : AppTheme.tertiary,
              ),
              _buildTelemetrySubStat(
                title: 'HPU SUPPLY PRESS',
                value: '${_tapTelemetry.hydraulicPressureBar.toStringAsFixed(0)} bar',
                status: 'Max 180 bar',
                color: const Color(0xFFC084FC),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetrySubStat({
    required String title,
    required String value,
    required String status,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(status, style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLiveTelemetryChartCard() {
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
                    'Real-Time Cutting Telemetry Trends',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Stroke Depth (mm) & Cutting Torque (Nm) vs Time',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('Depth (mm)', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                    const SizedBox(width: 10),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('Torque (Nm/10)', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minX: _depthHistory.isNotEmpty ? _depthHistory.first.x : 0,
                maxX: _depthHistory.isNotEmpty ? _depthHistory.last.x : 20,
                minY: 0,
                maxY: 350,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.border.withValues(alpha: 0.4),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 100,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.border, width: 1),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _depthHistory,
                    isCurved: true,
                    color: AppTheme.primaryLight,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: _torqueHistory.map((spot) => FlSpot(spot.x, spot.y / 10.0)).toList(),
                    isCurved: true,
                    color: AppTheme.secondary,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: DUAL STOPPLE & LINE ISOLATION
  // ==========================================================================

  Widget _buildDualStoppleTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStoppleSystemOverviewCard(),
        const SizedBox(height: 16),
        _buildDualStoppleHeadsCard(),
        const SizedBox(height: 16),
        _buildTemporaryBypassFlowCard(),
        const SizedBox(height: 16),
        _buildIsolationChamberPurgeCard(),
        const SizedBox(height: 16),
        _buildHydrocarbonSnifferCard(),
      ],
    );
  }

  Widget _buildStoppleSystemOverviewCard() {
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
                  Icon(Icons.alt_route_rounded, color: AppTheme.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Dual Stopple & Bypass Arrangement',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  '100% ISOLATION ACTIVE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.tertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Schematic Visualization
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                // Top: Bypass Line
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 30, height: 2, color: AppTheme.primaryLight),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.primaryLight),
                      ),
                      child: const Text(
                        '16" TEMPORARY BYPASS LINE (4.82 MMSCMD UNINTERRUPTED GAS FLOW)',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                      ),
                    ),
                    Container(width: 30, height: 2, color: AppTheme.primaryLight),
                  ],
                ),
                const SizedBox(height: 10),
                // Middle arrows connecting down to main pipe
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 16, color: AppTheme.primaryLight),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('ISOLATED WORK SECTION (200m) • P = 0.02 barg • N2 PURGED', style: TextStyle(fontSize: 9, color: Color(0xFFFF5252), fontWeight: FontWeight.bold)),
                    ),
                    const Icon(Icons.arrow_downward_rounded, size: 16, color: AppTheme.primaryLight),
                  ],
                ),
                const SizedBox(height: 10),
                // Bottom: Main Pipeline with Stopples
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          border: Border.all(color: AppTheme.primaryLight),
                        ),
                        child: const Center(
                          child: Text('UPSTREAM\n68.5 bar', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryLight)),
                        ),
                      ),
                    ),
                    // Stopple 1
                    Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB95F),
                      ),
                      child: const Center(
                        child: Text('STOPPLE\n#1', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                    ),
                    // Isolated Section
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Center(
                          child: Text('COLD CUT & VALVE TIE-IN ZONE\nHYDROCARBON < 0.15% LEL', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.tertiary)),
                        ),
                      ),
                    ),
                    // Stopple 2
                    Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB95F),
                      ),
                      child: const Center(
                        child: Text('STOPPLE\n#2', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          border: Border.all(color: AppTheme.primaryLight),
                        ),
                        child: const Center(
                          child: Text('DOWNSTREAM\n67.8 bar', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryLight)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualStoppleHeadsCard() {
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
            'Stopple Sealing Elements & Hydraulic Actuators',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStoppleUnitCard(
                title: 'Stopple Head #1 (Upstream)',
                chainage: 'KP 42.750',
                cylinderBar: _stoppleTelemetry.stopple1CylinderPressureBar,
                sealPercent: _stoppleTelemetry.stopple1SealBorePercent,
                isSeated: _stoppleTelemetry.stopple1Seated,
                diffPressBar: 68.48,
                cupType: 'Parabolic Polyurethane (90 Shore A)',
              ),
              const SizedBox(width: 12),
              _buildStoppleUnitCard(
                title: 'Stopple Head #2 (Downstream)',
                chainage: 'KP 42.950',
                cylinderBar: _stoppleTelemetry.stopple2CylinderPressureBar,
                sealPercent: _stoppleTelemetry.stopple2SealBorePercent,
                isSeated: _stoppleTelemetry.stopple2Seated,
                diffPressBar: 67.78,
                cupType: 'Parabolic Polyurethane (90 Shore A)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoppleUnitCard({
    required String title,
    required String chainage,
    required double cylinderBar,
    required double sealPercent,
    required bool isSeated,
    required double diffPressBar,
    required String cupType,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSeated ? AppTheme.tertiary.withValues(alpha: 0.5) : AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('100% SEALED', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.tertiary)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(chainage, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Text('Seating Actuator: ${cylinderBar.toStringAsFixed(1)} bar', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text('Diff Pressure: ${diffPressBar.toStringAsFixed(2)} bar', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryLight)),
            const SizedBox(height: 2),
            Text('Bore Contact: ${sealPercent.toStringAsFixed(0)}% circumference', style: const TextStyle(fontSize: 10, color: AppTheme.tertiary)),
            const SizedBox(height: 2),
            Text(cupType, style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemporaryBypassFlowCard() {
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
                  Icon(Icons.sync_alt_rounded, color: AppTheme.secondary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Temporary 16" Bypass Line Flow Monitoring',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'DOWNSTREAM GRID ONLINE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildTelemetrySubStat(
                title: 'BYPASS FLOW RATE',
                value: '${_stoppleTelemetry.temporaryBypassFlowMmscmd.toStringAsFixed(2)} MMSCMD',
                status: '100% Demand Met',
                color: AppTheme.secondary,
              ),
              _buildTelemetrySubStat(
                title: 'BYPASS ΔP',
                value: '${_stoppleTelemetry.temporaryBypassDiffPressureBar.toStringAsFixed(2)} bar',
                status: 'Normal Friction Loss',
                color: AppTheme.primaryLight,
              ),
              _buildTelemetrySubStat(
                title: 'BYPASS GAS VELOCITY',
                value: '${_stoppleTelemetry.temporaryBypassVelocityMs.toStringAsFixed(1)} m/s',
                status: 'Erosion Limit: 20 m/s',
                color: AppTheme.tertiary,
              ),
              _buildTelemetrySubStat(
                title: 'BYPASS ISOLATION VALVES',
                value: '2 of 2 Open',
                status: 'Locked In Position',
                color: const Color(0xFFC084FC),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIsolationChamberPurgeCard() {
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
                  Icon(Icons.cloud_sync_rounded, color: AppTheme.tertiary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Isolation Chamber Nitrogen Purge Cycle',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const Text(
                'Chamber Vol: 56.5 m³',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTelemetrySubStat(
                title: 'CHAMBER PRESSURE',
                value: '${_stoppleTelemetry.isolatedChamberPressureBar.toStringAsFixed(3)} barg',
                status: 'Depressurized to Stack',
                color: AppTheme.tertiary,
              ),
              _buildTelemetrySubStat(
                title: 'N2 PURGE FLOW',
                value: '${_stoppleTelemetry.n2PurgeFlowM3h.toStringAsFixed(0)} m³/h',
                status: 'N2 Vaporizer Skid',
                color: AppTheme.primaryLight,
              ),
              _buildTelemetrySubStat(
                title: 'CUMULATIVE N2 PURGED',
                value: '${_stoppleTelemetry.n2TotalPurgedM3.toStringAsFixed(0)} Nm³',
                status: '4.5 Vol Displacements',
                color: AppTheme.secondary,
              ),
              _buildTelemetrySubStat(
                title: 'RESIDUAL O2 CONC.',
                value: '${_stoppleTelemetry.oxygenLevelPercent.toStringAsFixed(2)}% vol',
                status: 'Inert Threshold: < 1.0%',
                color: AppTheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHydrocarbonSnifferCard() {
    final bool safe = _stoppleTelemetry.isHotWorkSafe;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: safe ? AppTheme.tertiary.withValues(alpha: 0.5) : const Color(0xFFFF5252).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (safe ? AppTheme.tertiary : const Color(0xFFFF5252)).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sensor_occupied_rounded, color: safe ? AppTheme.tertiary : const Color(0xFFFF5252), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Multi-Point Hydrocarbon Sniffer (LEL Monitor)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Safe Hot Tapping & Cold Cut Requirement: Continuous Hydrocarbon < 1.0% LEL',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (safe ? AppTheme.tertiary : const Color(0xFFFF5252)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: (safe ? AppTheme.tertiary : const Color(0xFFFF5252)).withValues(alpha: 0.4)),
                ),
                child: Text(
                  safe ? 'LEL SAFE (< 1.0%)' : 'ALARM: LEL HIGH',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: safe ? AppTheme.tertiary : const Color(0xFFFF5252)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSnifferProbeTile(
                probeName: 'SNIFFER PROBE #1',
                location: 'Stopple #1 Seal Cavity',
                lelPct: _stoppleTelemetry.sniffer1LelPercent,
              ),
              const SizedBox(width: 8),
              _buildSnifferProbeTile(
                probeName: 'SNIFFER PROBE #2',
                location: 'Pipe Center Tie-In Point',
                lelPct: _stoppleTelemetry.sniffer2LelPercent,
              ),
              const SizedBox(width: 8),
              _buildSnifferProbeTile(
                probeName: 'SNIFFER PROBE #3',
                location: 'Stopple #2 Seal Cavity',
                lelPct: _stoppleTelemetry.sniffer3LelPercent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.air_rounded, size: 16),
                  label: const Text('Execute Gas Sniff Calibration'),
                  onPressed: () {
                    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                      const SnackBar(
                        content: Text('Optical IR Sniffer calibrated: Multi-point baseline 0.00% LEL confirmed with zero drift'),
                        backgroundColor: AppTheme.surfaceCard,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                  label: const Text('Permit Cold Cutting'),
                  onPressed: safe
                      ? () {
                          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                            const SnackBar(
                              content: Text('PTW-HOT-0428 Validated: Hydrocarbon < 1% LEL, Cold cutting of isolated spool cleared'),
                              backgroundColor: AppTheme.surfaceCard,
                            ),
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSnifferProbeTile({
    required String probeName,
    required String location,
    required double lelPct,
  }) {
    final bool isSafe = lelPct < 1.0;
    final color = isSafe ? AppTheme.tertiary : const Color(0xFFFF5252);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(probeName, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            const SizedBox(height: 2),
            Text(location, style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Text('${lelPct.toStringAsFixed(2)}% LEL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(isSafe ? 'Normal' : 'High Gas Alarm', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 4: LOR COMPLETION PLUG & QA/QC CHECKLIST
  // ==========================================================================

  Widget _buildLorCompletionChecklistTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLorCompletionOverviewCard(),
        const SizedBox(height: 16),
        _buildBlindFlangeTorquingCard(),
        const SizedBox(height: 16),
        _buildInteractiveChecklistCard(),
        const SizedBox(height: 16),
        _buildSignoffDossierCard(),
      ],
    );
  }

  Widget _buildLorCompletionOverviewCard() {
    final lor = _lorData;

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
                  Icon(Icons.security_rounded, color: AppTheme.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Lock-O-Ring (LOR) Completion Plug Setting',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${lor.lockedSegments}/${lor.totalSegments} SEGMENTS LOCKED',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.tertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Allows removal and recovery of expensive 24" sandwich tapping valves while pipeline remains at full operating pressure (68.5 bar).',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildTelemetrySubStat(
                title: 'PLUG SEATING DEPTH',
                value: '${lor.plugDepthMm.toStringAsFixed(0)} mm',
                status: 'Flange Neck Groove',
                color: AppTheme.primaryLight,
              ),
              _buildTelemetrySubStat(
                title: 'RADIAL SEGMENTS',
                value: '${lor.lockedSegments} of ${lor.totalSegments}',
                status: '100% Mechanical Lock',
                color: AppTheme.tertiary,
              ),
              _buildTelemetrySubStat(
                title: 'CAVITY BLEED TEST',
                value: '${lor.cavityBleedPressureBar.toStringAsFixed(1)} barg',
                status: 'Zero Leak Past O-Ring',
                color: AppTheme.tertiary,
              ),
              _buildTelemetrySubStat(
                title: 'TAPPING VALVE',
                value: lor.sandwichValveRecovered ? 'Recovered' : 'Ready For Demount',
                status: 'Salvage Reusable',
                color: AppTheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
                  label: Text(lor.sandwichValveRecovered ? 'Sandwich Valve Recovered' : 'Confirm Valve Demount & Recovery'),
                  onPressed: () {
                    setState(() {
                      _lorData = LorCompletionData(
                        plugDepthMm: _lorData.plugDepthMm,
                        lockedSegments: _lorData.lockedSegments,
                        totalSegments: _lorData.totalSegments,
                        cavityBleedPressureBar: _lorData.cavityBleedPressureBar,
                        isLorSealHolding: _lorData.isLorSealHolding,
                        sandwichValveRecovered: true,
                        rtjGasketType: _lorData.rtjGasketType,
                        torqueTargetNm: _lorData.torqueTargetNm,
                        torqueAppliedNm: _lorData.torqueAppliedNm,
                        torqueStarPassesCompleted: _lorData.torqueStarPassesCompleted,
                        n2TestPressureBar: _lorData.n2TestPressureBar,
                        n2TestVerified: _lorData.n2TestVerified,
                      );
                    });
                    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                      const SnackBar(
                        content: Text('24" Sandwich Valve unbolted and safely demounted from LOR completion flange'),
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
    );
  }

  Widget _buildBlindFlangeTorquingCard() {
    final lor = _lorData;

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
                  Icon(Icons.handyman_rounded, color: AppTheme.secondary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Blind Flange Installation & Hydraulic Torquing',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: lor.isTorqueComplete ? AppTheme.tertiary.withValues(alpha: 0.15) : AppTheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: lor.isTorqueComplete ? AppTheme.tertiary.withValues(alpha: 0.4) : AppTheme.secondary.withValues(alpha: 0.4)),
                ),
                child: Text(
                  lor.isTorqueComplete ? 'TORQUE VERIFIED (1450 Nm)' : 'TORQUING IN PROGRESS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: lor.isTorqueComplete ? AppTheme.tertiary : AppTheme.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ASME B16.5 Class 600 Blind Flange • RTJ Gasket: ${lor.rtjGasketType}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildTelemetrySubStat(
                title: 'STUD BOLTS',
                value: '20x 1-5/8"',
                status: 'ASTM A193 B7 / 2H',
                color: AppTheme.primaryLight,
              ),
              _buildTelemetrySubStat(
                title: 'TARGET TORQUE',
                value: '${lor.torqueTargetNm.toInt()} Nm',
                status: 'ASME PCC-1 Star Pattern',
                color: AppTheme.secondary,
              ),
              _buildTelemetrySubStat(
                title: 'APPLIED TORQUE',
                value: '${lor.torqueAppliedNm.toInt()} Nm',
                status: '${lor.torqueStarPassesCompleted}/4 Criss-Cross Passes',
                color: AppTheme.tertiary,
              ),
              _buildTelemetrySubStat(
                title: 'FINAL N2 LEAK TEST',
                value: '${lor.n2TestPressureBar.toInt()} bar',
                status: lor.n2TestVerified ? 'Verified 0 Leak' : 'Pending Test',
                color: lor.n2TestVerified ? AppTheme.tertiary : const Color(0xFFFFB95F),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveChecklistCard() {
    final completedCount = _checklist.where((item) => item.isCompleted).length;

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
                  Icon(Icons.checklist_rtl_rounded, color: AppTheme.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ASME B31.8 / API RP 2201 Mandatory Checklist',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Text(
                '$completedCount of ${_checklist.length} Completed',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _checklist.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _checklist[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.isCompleted ? AppTheme.tertiary.withValues(alpha: 0.4) : AppTheme.border,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: item.isCompleted,
                      activeColor: AppTheme.tertiary,
                      checkColor: Colors.black,
                      onChanged: (val) {
                        setState(() {
                          _checklist[index] = item.copyWith(
                            isCompleted: val ?? false,
                            inspector: (val ?? false) ? 'A. Saikia (QC Lead)' : null,
                            timestamp: (val ?? false) ? DateTime.now() : null,
                          );
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.id,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: item.isCompleted ? AppTheme.textPrimary : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(item.description, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(item.standardRef, style: const TextStyle(fontSize: 9, color: AppTheme.secondary)),
                              ),
                              if (item.inspector != null) ...[
                                const SizedBox(width: 8),
                                Text('• Signed by ${item.inspector}', style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignoffDossierCard() {
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
                'Quality & Safety Authority Sign-Offs',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('4/4 AUTHORIZED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.tertiary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSignoffRow(
            role: 'API 2201 Hot Tap Specialist',
            name: 'D. Gohain (Cert #HT-9842)',
            status: 'Approved & Signed',
          ),
          const SizedBox(height: 8),
          _buildSignoffRow(
            role: 'Pipeline Welding Inspector (CSWIP 3.2)',
            name: 'R. K. Sharma (Cert #CS-11048)',
            status: 'Approved & Signed',
          ),
          const SizedBox(height: 8),
          _buildSignoffRow(
            role: 'Site Safety / HSE Officer',
            name: 'S. Barua (Gas Safety Lead)',
            status: 'Approved & Signed',
          ),
          const SizedBox(height: 8),
          _buildSignoffRow(
            role: 'Pipeline Operations Lead',
            name: 'P. Gogoi (Executive Engineer)',
            status: 'Approved & Signed',
          ),
        ],
      ),
    );
  }

  Widget _buildSignoffRow({
    required String role,
    required String name,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text(name, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 14, color: AppTheme.tertiary),
              const SizedBox(width: 4),
              Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.tertiary)),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // DIALOGS & ACTIONS
  // ==========================================================================

  void _showEmergencyProtocolDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 24),
            SizedBox(width: 10),
            Text('API RP 2201 Emergency Protocol', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Immediate Action Checklist for In-Service Pipeline Hot Tap Anomalies:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
            ),
            SizedBox(height: 10),
            Text('1. Burn-Through Threat: Immediately isolate welding power source, alert control room to throttle pressure.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            SizedBox(height: 6),
            Text('2. Coupon Retention Failure: Do NOT close sandwich valve until coupon location is confirmed via magnetic sonar.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            SizedBox(height: 6),
            Text('3. Hydrocarbon Leak (> 1.0% LEL): Evacuate bell hole, open N2 blanket purge, trigger emergency blowdown flare.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            SizedBox(height: 6),
            Text('4. Tapping Machine Jam: Engage hydraulic reverse jog at 5 RPM with continuous bypass line equalized.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('DISMISS', style: TextStyle(color: AppTheme.textSecondary)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5252)),
            child: const Text('ACKNOWLEDGE PROTOCOL'),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                const SnackBar(
                  content: Text('Safety Protocol Broadcasted to Field Crew & Bell Hole Team'),
                  backgroundColor: AppTheme.surfaceCard,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showExportDossierDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.description_rounded, color: AppTheme.primaryLight, size: 22),
            SizedBox(width: 8),
            Text('Export Hot Tap Technical Dossier', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compiling ASME B31.8 & API RP 2201 Technical Package for Oil India Ltd / AGCL:',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            SizedBox(height: 10),
            Text('• Battelle Thermal Model Heat Input Certificate', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
            Text('• Split Tee Sleeve UT & MPI Inspection Reports', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
            Text('• Trepanning Cutter Travel & Coupon Retention Log', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
            Text('• Dual Stopple & Bypass Line Flow Verification Chart', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
            Text('• Hydrocarbon Sniffer (< 1% LEL) Calibration Records', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
            Text('• Lock-O-Ring (LOR) Completion Plug & Torque Sign-Off', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('DOWNLOAD PDF DOSSIER'),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                const SnackBar(
                  content: Text('Technical Dossier Generated: OIL_HOT_TAP_KP42_DOSSIER.pdf'),
                  backgroundColor: AppTheme.surfaceCard,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
