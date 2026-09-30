import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS
// ============================================================================

enum HydroSectionId {
  ts01,
  ts02,
  ts03,
  ts04,
  ts05,
  ts06,
}

extension HydroSectionIdExt on HydroSectionId {
  String get code {
    switch (this) {
      case HydroSectionId.ts01:
        return 'TS-01';
      case HydroSectionId.ts02:
        return 'TS-02';
      case HydroSectionId.ts03:
        return 'TS-03';
      case HydroSectionId.ts04:
        return 'TS-04';
      case HydroSectionId.ts05:
        return 'TS-05';
      case HydroSectionId.ts06:
        return 'TS-06';
    }
  }

  String get sectionName {
    switch (this) {
      case HydroSectionId.ts01:
        return 'Duliajan Dispatch to VS-01';
      case HydroSectionId.ts02:
        return 'VS-01 to VS-02 (Burhi Dihing Crossing)';
      case HydroSectionId.ts03:
        return 'VS-02 to VS-03 (Naharkatia Sector)';
      case HydroSectionId.ts04:
        return 'VS-03 to VS-04 (Moran Sector)';
      case HydroSectionId.ts05:
        return 'VS-04 to VS-05 (Sivasagar Sector)';
      case HydroSectionId.ts06:
        return 'VS-05 to Numaligarh Terminal';
    }
  }
}

enum SectionPhase {
  waterFillingSoaking,
  pvPlottingAirCheck,
  strengthTestHold,
  leaktightness24Hr,
  dewateringPigTrain,
  swabbingDesiccantDry,
  nitrogenPurgeBlanket,
  certifiedApproved,
}

extension SectionPhaseExt on SectionPhase {
  String get label {
    switch (this) {
      case SectionPhase.waterFillingSoaking:
        return 'Filling & Soaking';
      case SectionPhase.pvPlottingAirCheck:
        return 'P/V Air Check';
      case SectionPhase.strengthTestHold:
        return 'Strength Test (112.5 Bar)';
      case SectionPhase.leaktightness24Hr:
        return '24-Hr Leak Test (90 Bar)';
      case SectionPhase.dewateringPigTrain:
        return 'Dewatering Pigging';
      case SectionPhase.swabbingDesiccantDry:
        return 'Swabbing & -40°C Dry';
      case SectionPhase.nitrogenPurgeBlanket:
        return 'N2 Purge & Blanket';
      case SectionPhase.certifiedApproved:
        return 'Certified & Endorsed';
    }
  }

  Color get color {
    switch (this) {
      case SectionPhase.waterFillingSoaking:
        return const Color(0xFF64748B);
      case SectionPhase.pvPlottingAirCheck:
        return const Color(0xFFFFB95F);
      case SectionPhase.strengthTestHold:
        return const Color(0xFF0284C7);
      case SectionPhase.leaktightness24Hr:
        return const Color(0xFF38BDF8);
      case SectionPhase.dewateringPigTrain:
        return const Color(0xFFF97316);
      case SectionPhase.swabbingDesiccantDry:
        return const Color(0xFFA855F7);
      case SectionPhase.nitrogenPurgeBlanket:
        return const Color(0xFF06B6D4);
      case SectionPhase.certifiedApproved:
        return const Color(0xFF4EDEA3);
    }
  }

  IconData get icon {
    switch (this) {
      case SectionPhase.waterFillingSoaking:
        return Icons.water_drop_outlined;
      case SectionPhase.pvPlottingAirCheck:
        return Icons.show_chart_rounded;
      case SectionPhase.strengthTestHold:
        return Icons.speed_rounded;
      case SectionPhase.leaktightness24Hr:
        return Icons.timer_rounded;
      case SectionPhase.dewateringPigTrain:
        return Icons.cleaning_services_rounded;
      case SectionPhase.swabbingDesiccantDry:
        return Icons.air_rounded;
      case SectionPhase.nitrogenPurgeBlanket:
        return Icons.shield_rounded;
      case SectionPhase.certifiedApproved:
        return Icons.verified_rounded;
    }
  }
}

class PipelineHydroSection {
  final HydroSectionId sectionId;
  final String startChainage;
  final String endChainage;
  final double lengthKm;
  final String pipeSize;
  final String materialGrade;
  final String wallThickness;
  final double designPressureBar; // 90.0 Bar
  final double strengthTestPressureBar; // 112.5 Bar (1.25x)
  final double leakTestPressureBar; // 90.0 Bar (1.0x)
  final double totalFillVolumeM3;
  final double staticHeadDiffBar;
  final String testHeadLocation;
  final String receiverLocation;
  final String highPointCh;
  final String lowPointCh;
  SectionPhase currentPhase;
  double currentPressureBar;
  double deadweightReadingBar;
  double quartzGaugeABar;
  double quartzGaugeBBar;
  double rtdHeadTempC;
  double rtdMidTempC;
  double rtdTailTempC;
  double ambientTempC;
  double airVolumePercent; // target < 0.20%
  double currentDewPointC; // target -40.0°C
  int strengthHoldRemainingMins;
  int leakHoldRemainingMins;
  bool isStrengthPassed;
  bool isLeakPassed;
  bool isDryingPassed;
  bool isTripartiteSigned;
  String contractorSignatory;
  String tpiaSignatory;
  String clientSignatory;
  DateTime lastUpdated;

  PipelineHydroSection({
    required this.sectionId,
    required this.startChainage,
    required this.endChainage,
    required this.lengthKm,
    this.pipeSize = '18" (457.2 mm OD)',
    this.materialGrade = 'API 5L Grade X70 PSL2',
    this.wallThickness = '11.91 mm / 14.27 mm',
    this.designPressureBar = 90.0,
    this.strengthTestPressureBar = 112.5,
    this.leakTestPressureBar = 90.0,
    required this.totalFillVolumeM3,
    required this.staticHeadDiffBar,
    required this.testHeadLocation,
    required this.receiverLocation,
    required this.highPointCh,
    required this.lowPointCh,
    required this.currentPhase,
    required this.currentPressureBar,
    required this.deadweightReadingBar,
    required this.quartzGaugeABar,
    required this.quartzGaugeBBar,
    required this.rtdHeadTempC,
    required this.rtdMidTempC,
    required this.rtdTailTempC,
    required this.ambientTempC,
    required this.airVolumePercent,
    required this.currentDewPointC,
    this.strengthHoldRemainingMins = 0,
    this.leakHoldRemainingMins = 0,
    this.isStrengthPassed = false,
    this.isLeakPassed = false,
    this.isDryingPassed = false,
    this.isTripartiteSigned = false,
    this.contractorSignatory = 'Pending',
    this.tpiaSignatory = 'Pending',
    this.clientSignatory = 'Pending',
    required this.lastUpdated,
  });

  double get meanSoilRtdTempC => (rtdHeadTempC + rtdMidTempC + rtdTailTempC) / 3.0;

  bool get isAirVolumeCompliant => airVolumePercent <= 0.20;

  bool get isDewPointCompliant => currentDewPointC <= -40.0;
}

class HourlyHydroLog {
  final int hour;
  final String timestamp;
  final double deadweightBar;
  final double quartzABar;
  final double quartzBBar;
  final double rtdHeadC;
  final double rtdMidC;
  final double rtdTailC;
  final double ambientC;
  final double theoreticalBar;
  final double deltaBar;
  final bool isWithinTol;
  final String remarks;

  const HourlyHydroLog({
    required this.hour,
    required this.timestamp,
    required this.deadweightBar,
    required this.quartzABar,
    required this.quartzBBar,
    required this.rtdHeadC,
    required this.rtdMidC,
    required this.rtdTailC,
    required this.ambientC,
    required this.theoreticalBar,
    required this.deltaBar,
    required this.isWithinTol,
    required this.remarks,
  });

  double get meanSoilTempC => (rtdHeadC + rtdMidC + rtdTailC) / 3.0;
}

class PvDataPoint {
  final double pressureBar;
  final double actualVolumeLiters;
  final double theoreticalElasticLiters;
  final double offset02Liters;
  final int pumpStrokes;
  final bool isHoldPoint;
  final String note;

  const PvDataPoint({
    required this.pressureBar,
    required this.actualVolumeLiters,
    required this.theoreticalElasticLiters,
    required this.offset02Liters,
    required this.pumpStrokes,
    required this.isHoldPoint,
    required this.note,
  });
}

enum PigType {
  mechanicalScraper,
  batchingCup,
  foamSwabLow,
  foamSwabMed,
  foamSwabHigh,
  desiccantDrying,
}

extension PigTypeExt on PigType {
  String get title {
    switch (this) {
      case PigType.mechanicalScraper:
        return '4-Cup Bi-Di Mechanical Scraper';
      case PigType.batchingCup:
        return '4-Cup Polyurethane Batching Pig';
      case PigType.foamSwabLow:
        return 'Low-Density Open Cell Foam (25 kg/m³)';
      case PigType.foamSwabMed:
        return 'Medium-Density Foam Pig (35 kg/m³)';
      case PigType.foamSwabHigh:
        return 'High-Density Criss-Cross Foam (45 kg/m³)';
      case PigType.desiccantDrying:
        return 'Super-Dry Multi-Disc Foam Bullet';
    }
  }

  IconData get icon {
    switch (this) {
      case PigType.mechanicalScraper:
        return Icons.build_circle_rounded;
      case PigType.batchingCup:
        return Icons.view_stream_rounded;
      case PigType.foamSwabLow:
      case PigType.foamSwabMed:
      case PigType.foamSwabHigh:
        return Icons.cleaning_services_rounded;
      case PigType.desiccantDrying:
        return Icons.air_rounded;
    }
  }
}

class DewateringPigRun {
  final String runId;
  final PigType type;
  final String launchTime;
  final String receiveTime;
  final double distanceKm;
  final double speedMps;
  final double drivingPressureBar;
  final double preRunWeightKg;
  final double postRunWeightKg;
  final double waterAbsorbedLiters;
  final double cupWearPercent;
  final String transmitterStatus; // 22 Hz EM signal
  final bool isPassed;

  const DewateringPigRun({
    required this.runId,
    required this.type,
    required this.launchTime,
    required this.receiveTime,
    required this.distanceKm,
    required this.speedMps,
    required this.drivingPressureBar,
    required this.preRunWeightKg,
    required this.postRunWeightKg,
    required this.waterAbsorbedLiters,
    required this.cupWearPercent,
    required this.transmitterStatus,
    required this.isPassed,
  });

  double get weightGainPercent =>
      preRunWeightKg > 0 ? ((postRunWeightKg - preRunWeightKg) / preRunWeightKg) * 100 : 0.0;
}

class DewPointLog {
  final int elapsedHours;
  final double outletDewPointC;
  final double inletDewPointC;
  final double airflowCfm;
  final double dischargeTempC;
  final String status;

  const DewPointLog({
    required this.elapsedHours,
    required this.outletDewPointC,
    required this.inletDewPointC,
    required this.airflowCfm,
    required this.dischargeTempC,
    required this.status,
  });
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class HydrotestingScreen extends StatefulWidget {
  const HydrotestingScreen({super.key});

  @override
  State<HydrotestingScreen> createState() => _HydrotestingScreenState();
}

class _HydrotestingScreenState extends State<HydrotestingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  HydroSectionId _selectedSectionId = HydroSectionId.ts02;

  // Sections TS-01 through TS-06
  late Map<HydroSectionId, PipelineHydroSection> _sections;
  late Map<HydroSectionId, List<HourlyHydroLog>> _hourlyLogs;
  late Map<HydroSectionId, List<PvDataPoint>> _pvCurves;
  late Map<HydroSectionId, List<DewateringPigRun>> _pigRuns;
  late Map<HydroSectionId, List<DewPointLog>> _dewPointLogs;

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
    final now = DateTime.now();

    _sections = {
      HydroSectionId.ts01: PipelineHydroSection(
        sectionId: HydroSectionId.ts01,
        startChainage: 'Ch 00+000',
        endChainage: 'Ch 14+850',
        lengthKm: 14.85,
        totalFillVolumeM3: 2190.3,
        staticHeadDiffBar: 2.15,
        testHeadLocation: 'Ch 00+000 (Dispatch Terminal Elev 122m)',
        receiverLocation: 'Ch 14+850 (VS-01 Elev 118m)',
        highPointCh: 'Ch 06+400 (Elev 134m)',
        lowPointCh: 'Ch 11+200 (Elev 112m)',
        currentPhase: SectionPhase.certifiedApproved,
        currentPressureBar: 0.65, // Nitrogen blanket
        deadweightReadingBar: 0.65,
        quartzGaugeABar: 0.65,
        quartzGaugeBBar: 0.64,
        rtdHeadTempC: 23.2,
        rtdMidTempC: 22.9,
        rtdTailTempC: 23.0,
        ambientTempC: 28.5,
        airVolumePercent: 0.035,
        currentDewPointC: -43.2,
        isStrengthPassed: true,
        isLeakPassed: true,
        isDryingPassed: true,
        isTripartiteSigned: true,
        contractorSignatory: 'Er. Rajesh Nair (Kalpataru)',
        tpiaSignatory: 'Er. Marcus Vance (EIL TPIA)',
        clientSignatory: 'Er. B. Bordoloi (Oil India)',
        lastUpdated: now.subtract(const Duration(days: 3)),
      ),
      HydroSectionId.ts02: PipelineHydroSection(
        sectionId: HydroSectionId.ts02,
        startChainage: 'Ch 14+850',
        endChainage: 'Ch 31+200',
        lengthKm: 16.35,
        totalFillVolumeM3: 2411.6,
        staticHeadDiffBar: 4.35,
        testHeadLocation: 'Ch 14+850 (VS-01 Elev 118.4m)',
        receiverLocation: 'Ch 31+200 (VS-02 Elev 112.1m)',
        highPointCh: 'Ch 22+450 (Elev 142.6m)',
        lowPointCh: 'Ch 28+100 (Burhi Dihing River Bed Elev 98.2m)',
        currentPhase: SectionPhase.leaktightness24Hr,
        currentPressureBar: 90.04,
        deadweightReadingBar: 90.04,
        quartzGaugeABar: 90.05,
        quartzGaugeBBar: 90.03,
        rtdHeadTempC: 22.4,
        rtdMidTempC: 22.1,
        rtdTailTempC: 22.3,
        ambientTempC: 29.1,
        airVolumePercent: 0.042,
        currentDewPointC: 14.2, // Still wet, leak test underway
        strengthHoldRemainingMins: 0,
        leakHoldRemainingMins: 360, // 6 hrs remaining (hour 18 of 24)
        isStrengthPassed: true,
        isLeakPassed: false,
        isDryingPassed: false,
        isTripartiteSigned: false,
        lastUpdated: now,
      ),
      HydroSectionId.ts03: PipelineHydroSection(
        sectionId: HydroSectionId.ts03,
        startChainage: 'Ch 31+200',
        endChainage: 'Ch 47+600',
        lengthKm: 16.40,
        totalFillVolumeM3: 2419.0,
        staticHeadDiffBar: 3.80,
        testHeadLocation: 'Ch 31+200 (VS-02 Elev 112.1m)',
        receiverLocation: 'Ch 47+600 (VS-03 Elev 105.4m)',
        highPointCh: 'Ch 38+900 (Elev 138.0m)',
        lowPointCh: 'Ch 44+200 (Elev 99.5m)',
        currentPhase: SectionPhase.strengthTestHold,
        currentPressureBar: 112.52,
        deadweightReadingBar: 112.52,
        quartzGaugeABar: 112.53,
        quartzGaugeBBar: 112.51,
        rtdHeadTempC: 22.6,
        rtdMidTempC: 22.3,
        rtdTailTempC: 22.5,
        ambientTempC: 30.2,
        airVolumePercent: 0.048,
        currentDewPointC: 15.0,
        strengthHoldRemainingMins: 45, // 45 mins remaining of 4-hr strength test
        leakHoldRemainingMins: 1440,
        isStrengthPassed: false,
        isLeakPassed: false,
        isDryingPassed: false,
        isTripartiteSigned: false,
        lastUpdated: now,
      ),
      HydroSectionId.ts04: PipelineHydroSection(
        sectionId: HydroSectionId.ts04,
        startChainage: 'Ch 47+600',
        endChainage: 'Ch 63+100',
        lengthKm: 15.50,
        totalFillVolumeM3: 2286.2,
        staticHeadDiffBar: 3.10,
        testHeadLocation: 'Ch 47+600 (VS-03 Elev 105.4m)',
        receiverLocation: 'Ch 63+100 (VS-04 Elev 101.2m)',
        highPointCh: 'Ch 55+100 (Elev 126.8m)',
        lowPointCh: 'Ch 59+800 (Elev 95.8m)',
        currentPhase: SectionPhase.pvPlottingAirCheck,
        currentPressureBar: 75.0,
        deadweightReadingBar: 75.02,
        quartzGaugeABar: 75.01,
        quartzGaugeBBar: 74.99,
        rtdHeadTempC: 22.8,
        rtdMidTempC: 22.6,
        rtdTailTempC: 22.7,
        ambientTempC: 29.8,
        airVolumePercent: 0.038,
        currentDewPointC: 16.5,
        strengthHoldRemainingMins: 240,
        leakHoldRemainingMins: 1440,
        isStrengthPassed: false,
        isLeakPassed: false,
        isDryingPassed: false,
        isTripartiteSigned: false,
        lastUpdated: now,
      ),
      HydroSectionId.ts05: PipelineHydroSection(
        sectionId: HydroSectionId.ts05,
        startChainage: 'Ch 63+100',
        endChainage: 'Ch 78+900',
        lengthKm: 15.80,
        totalFillVolumeM3: 2330.5,
        staticHeadDiffBar: 2.85,
        testHeadLocation: 'Ch 63+100 (VS-04 Elev 101.2m)',
        receiverLocation: 'Ch 78+900 (VS-05 Elev 98.6m)',
        highPointCh: 'Ch 71+300 (Elev 119.5m)',
        lowPointCh: 'Ch 76+400 (Elev 92.4m)',
        currentPhase: SectionPhase.swabbingDesiccantDry,
        currentPressureBar: 3.2, // Air compressor dry run
        deadweightReadingBar: 3.2,
        quartzGaugeABar: 3.21,
        quartzGaugeBBar: 3.19,
        rtdHeadTempC: 23.5,
        rtdMidTempC: 23.2,
        rtdTailTempC: 23.4,
        ambientTempC: 31.0,
        airVolumePercent: 0.041,
        currentDewPointC: -34.8, // Progressing towards -40°C
        isStrengthPassed: true,
        isLeakPassed: true,
        isDryingPassed: false,
        isTripartiteSigned: false,
        lastUpdated: now,
      ),
      HydroSectionId.ts06: PipelineHydroSection(
        sectionId: HydroSectionId.ts06,
        startChainage: 'Ch 78+900',
        endChainage: 'Ch 94+500',
        lengthKm: 15.60,
        totalFillVolumeM3: 2301.0,
        staticHeadDiffBar: 2.40,
        testHeadLocation: 'Ch 78+900 (VS-05 Elev 98.6m)',
        receiverLocation: 'Ch 94+500 (Numaligarh Terminal Elev 95.0m)',
        highPointCh: 'Ch 85+200 (Elev 114.2m)',
        lowPointCh: 'Ch 91+700 (Elev 88.5m)',
        currentPhase: SectionPhase.waterFillingSoaking,
        currentPressureBar: 12.5, // Water fill head pressure
        deadweightReadingBar: 12.5,
        quartzGaugeABar: 12.52,
        quartzGaugeBBar: 12.48,
        rtdHeadTempC: 24.1,
        rtdMidTempC: 23.8,
        rtdTailTempC: 23.9,
        ambientTempC: 32.5,
        airVolumePercent: 0.00, // Not pressurized yet
        currentDewPointC: 22.0,
        strengthHoldRemainingMins: 240,
        leakHoldRemainingMins: 1440,
        isStrengthPassed: false,
        isLeakPassed: false,
        isDryingPassed: false,
        isTripartiteSigned: false,
        lastUpdated: now,
      ),
    };

    // 24-hr Hourly Hydro Log for TS-02 (Currently at hour 18)
    _hourlyLogs = {
      HydroSectionId.ts02: _generateHourlyLogsForTs02(),
      HydroSectionId.ts01: _generateHourlyLogsForTs01(),
      HydroSectionId.ts03: _generateHourlyLogsForTs03(),
      HydroSectionId.ts04: _generateHourlyLogsForTs04(),
      HydroSectionId.ts05: _generateHourlyLogsForTs05(),
      HydroSectionId.ts06: _generateHourlyLogsForTs06(),
    };

    // P/V curve data (Pressure vs Volume in Liters)
    _pvCurves = {
      HydroSectionId.ts02: _generatePvCurve(2411600.0, 16.35),
      HydroSectionId.ts01: _generatePvCurve(2190300.0, 14.85),
      HydroSectionId.ts03: _generatePvCurve(2419000.0, 16.40),
      HydroSectionId.ts04: _generatePvCurve(2286200.0, 15.50),
      HydroSectionId.ts05: _generatePvCurve(2330500.0, 15.80),
      HydroSectionId.ts06: _generatePvCurve(2301000.0, 15.60),
    };

    // Pigging & Dewatering records
    _pigRuns = {
      HydroSectionId.ts02: [
        const DewateringPigRun(
          runId: 'PIG-TS02-01',
          type: PigType.mechanicalScraper,
          launchTime: '06:00 AM (Day 1)',
          receiveTime: '09:12 AM (Day 1)',
          distanceKm: 16.35,
          speedMps: 1.45,
          drivingPressureBar: 2.8,
          preRunWeightKg: 185.0,
          postRunWeightKg: 188.4,
          waterAbsorbedLiters: 3.4,
          cupWearPercent: 1.2,
          transmitterStatus: 'Active 22 Hz Tracked',
          isPassed: true,
        ),
        const DewateringPigRun(
          runId: 'PIG-TS02-02',
          type: PigType.batchingCup,
          launchTime: '10:30 AM (Day 1)',
          receiveTime: '13:45 AM (Day 1)',
          distanceKm: 16.35,
          speedMps: 1.42,
          drivingPressureBar: 2.5,
          preRunWeightKg: 192.0,
          postRunWeightKg: 194.8,
          waterAbsorbedLiters: 2.8,
          cupWearPercent: 0.8,
          transmitterStatus: 'Active 22 Hz Tracked',
          isPassed: true,
        ),
      ],
      HydroSectionId.ts01: [
        const DewateringPigRun(
          runId: 'PIG-TS01-01',
          type: PigType.mechanicalScraper,
          launchTime: '07:00 AM',
          receiveTime: '09:48 AM',
          distanceKm: 14.85,
          speedMps: 1.50,
          drivingPressureBar: 2.6,
          preRunWeightKg: 185.0,
          postRunWeightKg: 187.2,
          waterAbsorbedLiters: 2.2,
          cupWearPercent: 0.9,
          transmitterStatus: 'Pass Confirmed',
          isPassed: true,
        ),
        const DewateringPigRun(
          runId: 'PIG-TS01-02',
          type: PigType.batchingCup,
          launchTime: '11:00 AM',
          receiveTime: '13:50 PM',
          distanceKm: 14.85,
          speedMps: 1.48,
          drivingPressureBar: 2.4,
          preRunWeightKg: 190.0,
          postRunWeightKg: 192.1,
          waterAbsorbedLiters: 2.1,
          cupWearPercent: 0.7,
          transmitterStatus: 'Pass Confirmed',
          isPassed: true,
        ),
        const DewateringPigRun(
          runId: 'SWAB-TS01-01',
          type: PigType.foamSwabLow,
          launchTime: '15:00 PM',
          receiveTime: '18:15 PM',
          distanceKm: 14.85,
          speedMps: 1.35,
          drivingPressureBar: 1.9,
          preRunWeightKg: 42.0,
          postRunWeightKg: 64.5,
          waterAbsorbedLiters: 22.5,
          cupWearPercent: 2.1,
          transmitterStatus: 'Pass Confirmed',
          isPassed: true,
        ),
        const DewateringPigRun(
          runId: 'SWAB-TS01-02',
          type: PigType.foamSwabMed,
          launchTime: '19:30 PM',
          receiveTime: '22:40 PM',
          distanceKm: 14.85,
          speedMps: 1.38,
          drivingPressureBar: 2.1,
          preRunWeightKg: 58.0,
          postRunWeightKg: 69.2,
          waterAbsorbedLiters: 11.2,
          cupWearPercent: 1.5,
          transmitterStatus: 'Pass Confirmed',
          isPassed: true,
        ),
        const DewateringPigRun(
          runId: 'SWAB-TS01-03',
          type: PigType.foamSwabHigh,
          launchTime: '00:15 AM',
          receiveTime: '03:20 AM',
          distanceKm: 14.85,
          speedMps: 1.40,
          drivingPressureBar: 2.2,
          preRunWeightKg: 74.0,
          postRunWeightKg: 75.8,
          waterAbsorbedLiters: 1.8, // Exit weight gain < 5%
          cupWearPercent: 0.6,
          transmitterStatus: 'Dry Sweep Met (<5% gain)',
          isPassed: true,
        ),
      ],
      HydroSectionId.ts05: [
        const DewateringPigRun(
          runId: 'PIG-TS05-01',
          type: PigType.mechanicalScraper,
          launchTime: '05:30 AM',
          receiveTime: '08:45 AM',
          distanceKm: 15.80,
          speedMps: 1.42,
          drivingPressureBar: 2.7,
          preRunWeightKg: 185.0,
          postRunWeightKg: 189.1,
          waterAbsorbedLiters: 4.1,
          cupWearPercent: 1.4,
          transmitterStatus: 'Pass Confirmed',
          isPassed: true,
        ),
        const DewateringPigRun(
          runId: 'SWAB-TS05-01',
          type: PigType.foamSwabLow,
          launchTime: '10:00 AM',
          receiveTime: '13:20 PM',
          distanceKm: 15.80,
          speedMps: 1.36,
          drivingPressureBar: 2.0,
          preRunWeightKg: 42.0,
          postRunWeightKg: 68.4,
          waterAbsorbedLiters: 26.4,
          cupWearPercent: 2.4,
          transmitterStatus: 'Pass Confirmed',
          isPassed: true,
        ),
        const DewateringPigRun(
          runId: 'SWAB-TS05-02',
          type: PigType.foamSwabMed,
          launchTime: '14:30 PM',
          receiveTime: '17:40 PM',
          distanceKm: 15.80,
          speedMps: 1.38,
          drivingPressureBar: 2.1,
          preRunWeightKg: 58.0,
          postRunWeightKg: 66.8,
          waterAbsorbedLiters: 8.8,
          cupWearPercent: 1.8,
          transmitterStatus: 'Pass Confirmed',
          isPassed: true,
        ),
        const DewateringPigRun(
          runId: 'SWAB-TS05-03',
          type: PigType.foamSwabHigh,
          launchTime: '19:00 PM',
          receiveTime: '22:10 PM',
          distanceKm: 15.80,
          speedMps: 1.40,
          drivingPressureBar: 2.3,
          preRunWeightKg: 74.0,
          postRunWeightKg: 76.2,
          waterAbsorbedLiters: 2.2, // <5% gain
          cupWearPercent: 0.8,
          transmitterStatus: 'Dry Sweep Met (<5% gain)',
          isPassed: true,
        ),
      ],
      HydroSectionId.ts03: [],
      HydroSectionId.ts04: [],
      HydroSectionId.ts06: [],
    };

    // Dew point decay logs (-40°C progression)
    _dewPointLogs = {
      HydroSectionId.ts01: [
        const DewPointLog(elapsedHours: 0, outletDewPointC: 18.5, inletDewPointC: -45.0, airflowCfm: 1500, dischargeTempC: 32.0, status: 'Air Purge Initial'),
        const DewPointLog(elapsedHours: 6, outletDewPointC: 9.2, inletDewPointC: -45.5, airflowCfm: 1500, dischargeTempC: 30.5, status: 'Moisture Sweeping'),
        const DewPointLog(elapsedHours: 12, outletDewPointC: -1.4, inletDewPointC: -45.8, airflowCfm: 1500, dischargeTempC: 28.4, status: 'Sub-Zero Vapor Evap'),
        const DewPointLog(elapsedHours: 18, outletDewPointC: -14.6, inletDewPointC: -46.0, airflowCfm: 1500, dischargeTempC: 26.8, status: 'Deep Desiccant Flow'),
        const DewPointLog(elapsedHours: 24, outletDewPointC: -27.2, inletDewPointC: -46.2, airflowCfm: 1500, dischargeTempC: 25.5, status: 'Approaching Target'),
        const DewPointLog(elapsedHours: 30, outletDewPointC: -36.5, inletDewPointC: -46.5, airflowCfm: 1500, dischargeTempC: 24.8, status: 'Near ASME Limit'),
        const DewPointLog(elapsedHours: 36, outletDewPointC: -41.8, inletDewPointC: -46.8, airflowCfm: 1500, dischargeTempC: 24.2, status: 'Target -40°C Met'),
        const DewPointLog(elapsedHours: 42, outletDewPointC: -43.2, inletDewPointC: -47.0, airflowCfm: 1500, dischargeTempC: 23.9, status: '24-Hr Soak Held Stable'),
      ],
      HydroSectionId.ts05: [
        const DewPointLog(elapsedHours: 0, outletDewPointC: 19.2, inletDewPointC: -45.0, airflowCfm: 1500, dischargeTempC: 33.0, status: 'Air Purge Initial'),
        const DewPointLog(elapsedHours: 6, outletDewPointC: 10.5, inletDewPointC: -45.2, airflowCfm: 1500, dischargeTempC: 31.2, status: 'Moisture Sweeping'),
        const DewPointLog(elapsedHours: 12, outletDewPointC: 0.8, inletDewPointC: -45.5, airflowCfm: 1500, dischargeTempC: 29.1, status: 'Sub-Zero Evaporation'),
        const DewPointLog(elapsedHours: 18, outletDewPointC: -12.4, inletDewPointC: -45.8, airflowCfm: 1500, dischargeTempC: 27.2, status: 'Desiccant Flow Active'),
        const DewPointLog(elapsedHours: 24, outletDewPointC: -24.8, inletDewPointC: -46.1, airflowCfm: 1500, dischargeTempC: 26.0, status: 'Vapor Pressure Dropping'),
        const DewPointLog(elapsedHours: 30, outletDewPointC: -34.8, inletDewPointC: -46.5, airflowCfm: 1500, dischargeTempC: 25.1, status: 'In Progress to -40°C'),
      ],
      HydroSectionId.ts02: [],
      HydroSectionId.ts03: [],
      HydroSectionId.ts04: [],
      HydroSectionId.ts06: [],
    };
  }

  List<HourlyHydroLog> _generateHourlyLogsForTs02() {
    // TS-02: 24-hr leak test at 90.0 Bar, 18 hours elapsed
    final logs = <HourlyHydroLog>[];
    const initialPressure = 90.00;
    const initialMeanSoilTemp = 22.10;
    const thermalCoeff = 0.94; // ~0.94 Bar per °C thermal balance for 18" X70 filled with water

    // Temperatures gently fluctuate between 21.9 and 22.6 at 1.5m depth
    final soilTemps = [
      22.10, 22.12, 22.15, 22.18, 22.22, 22.28, 22.34, 22.42, 22.48, 22.52,
      22.55, 22.54, 22.50, 22.45, 22.38, 22.31, 22.25, 22.20, 22.18,
    ];

    final ambients = [
      24.5, 23.8, 23.2, 22.8, 22.5, 23.1, 24.8, 27.2, 29.5, 31.8,
      32.5, 32.8, 32.1, 31.2, 29.8, 28.4, 27.1, 26.0, 25.2,
    ];

    for (int h = 0; h <= 18; h++) {
      final tMean = soilTemps[h];
      final deltaT = tMean - initialMeanSoilTemp;
      final theoP = initialPressure + (deltaT * thermalCoeff);
      // Actual reading tracking very close to theoretical (±0.03 Bar max variation)
      final actualP = theoP + (0.01 * math.sin(h * 0.8));
      final qA = actualP + 0.01;
      final qB = actualP - 0.01;
      final deltaActualTheo = actualP - theoP;

      logs.add(
        HourlyHydroLog(
          hour: h,
          timestamp: '${(h).toString().padLeft(2, '0')}:00',
          deadweightBar: double.parse(actualP.toStringAsFixed(2)),
          quartzABar: double.parse(qA.toStringAsFixed(2)),
          quartzBBar: double.parse(qB.toStringAsFixed(2)),
          rtdHeadC: double.parse((tMean + 0.1).toStringAsFixed(2)),
          rtdMidC: double.parse((tMean - 0.1).toStringAsFixed(2)),
          rtdTailC: double.parse(tMean.toStringAsFixed(2)),
          ambientC: ambients[h],
          theoreticalBar: double.parse(theoP.toStringAsFixed(2)),
          deltaBar: double.parse(deltaActualTheo.toStringAsFixed(3)),
          isWithinTol: deltaActualTheo.abs() <= 0.15,
          remarks: h == 0
              ? 'Leaktightness Test Commenced (90.0 Bar)'
              : (h == 18 ? 'Live Reading: Stable & Thermally Balanced' : 'Normal Thermal Drift (<0.03 Bar)'),
        ),
      );
    }
    return logs;
  }

  List<HourlyHydroLog> _generateHourlyLogsForTs01() {
    // 24 completed hours
    final logs = <HourlyHydroLog>[];
    for (int h = 0; h <= 24; h++) {
      final t = 22.8 + (0.3 * math.sin(h * 0.25));
      final theo = 90.00 + ((t - 22.8) * 0.92);
      final p = theo + 0.01;
      logs.add(
        HourlyHydroLog(
          hour: h,
          timestamp: '${h.toString().padLeft(2, '0')}:00',
          deadweightBar: double.parse(p.toStringAsFixed(2)),
          quartzABar: double.parse((p + 0.01).toStringAsFixed(2)),
          quartzBBar: double.parse((p - 0.01).toStringAsFixed(2)),
          rtdHeadC: double.parse((t + 0.05).toStringAsFixed(2)),
          rtdMidC: double.parse((t - 0.05).toStringAsFixed(2)),
          rtdTailC: double.parse(t.toStringAsFixed(2)),
          ambientC: 25.0 + (5.0 * math.sin(h * 0.2)),
          theoreticalBar: double.parse(theo.toStringAsFixed(2)),
          deltaBar: 0.01,
          isWithinTol: true,
          remarks: h == 24 ? 'Test Successfully Concluded' : 'Stable Hold',
        ),
      );
    }
    return logs;
  }

  List<HourlyHydroLog> _generateHourlyLogsForTs03() {
    final logs = <HourlyHydroLog>[];
    for (int h = 0; h <= 3; h++) {
      logs.add(
        HourlyHydroLog(
          hour: h,
          timestamp: '${h.toString().padLeft(2, '0')}:00',
          deadweightBar: 112.52,
          quartzABar: 112.53,
          quartzBBar: 112.51,
          rtdHeadC: 22.6,
          rtdMidC: 22.3,
          rtdTailC: 22.5,
          ambientC: 30.0,
          theoreticalBar: 112.50,
          deltaBar: 0.02,
          isWithinTol: true,
          remarks: 'Strength Hold 112.5 Bar (Hour $h of 4)',
        ),
      );
    }
    return logs;
  }

  List<HourlyHydroLog> _generateHourlyLogsForTs04() => [];
  List<HourlyHydroLog> _generateHourlyLogsForTs05() => [];
  List<HourlyHydroLog> _generateHourlyLogsForTs06() => [];

  List<PvDataPoint> _generatePvCurve(double totalVolumeLiters, double lengthKm) {
    // 0.2% Offset calculation:
    // 0.2% of total volume
    final offset02Volume = totalVolumeLiters * 0.002;

    // Linear elastic slope calculation:
    // For 18" X70, elasticity + water compressibility dV/dP is approx 21.4 L/Bar/km
    final slopeLitersPerBar = 21.4 * lengthKm;

    final pressures = [0.0, 15.0, 30.0, 45.0, 60.0, 75.0, 90.0, 100.0, 107.0, 112.5];
    final points = <PvDataPoint>[];

    for (final p in pressures) {
      final theoreticalElastic = p * slopeLitersPerBar;
      final offset02 = theoreticalElastic + offset02Volume;

      // Actual curve: slightly non-linear below 40 Bar due to minimal trace air compressibility (Boyle's law),
      // then strictly parallel to theoretical elastic line with only ~1,010 Liters trace offset (0.042% air content)
      double actual;
      if (p == 0.0) {
        actual = 0.0;
      } else if (p < 45.0) {
        // Minor curved toe
        actual = theoreticalElastic + (1000.0 * (1.0 - math.exp(-p / 15.0)));
      } else {
        // Pure elastic linear behavior
        actual = theoreticalElastic + 1010.0;
      }

      final strokes = (actual / 1.85).round(); // 1.85 Liters per stroke high pressure pump

      points.add(
        PvDataPoint(
          pressureBar: p,
          actualVolumeLiters: double.parse(actual.toStringAsFixed(1)),
          theoreticalElasticLiters: double.parse(theoreticalElastic.toStringAsFixed(1)),
          offset02Liters: double.parse(offset02.toStringAsFixed(1)),
          pumpStrokes: strokes,
          isHoldPoint: p == 45.0 || p == 90.0 || p == 112.5,
          note: p == 45.0
              ? '50% Design Pressure Air Check Hold'
              : (p == 90.0
                  ? '100% Design Pressure Hold (15 Min)'
                  : (p == 112.5 ? '125% Strength Test Pressure Reached' : 'Pump Injection')),
        ),
      );
    }
    return points;
  }

  // ============================================================================
  // USER ACTIONS & DIALOGS
  // ============================================================================

  void _showAddHourlyLogDialog() {
    final currentSection = _sections[_selectedSectionId]!;
    final dwtCtrl = TextEditingController(text: currentSection.currentPressureBar.toStringAsFixed(2));
    final qpACtrl = TextEditingController(text: (currentSection.currentPressureBar + 0.01).toStringAsFixed(2));
    final qpBCtrl = TextEditingController(text: (currentSection.currentPressureBar - 0.01).toStringAsFixed(2));
    final rtdHeadCtrl = TextEditingController(text: currentSection.rtdHeadTempC.toStringAsFixed(2));
    final rtdMidCtrl = TextEditingController(text: currentSection.rtdMidTempC.toStringAsFixed(2));
    final rtdTailCtrl = TextEditingController(text: currentSection.rtdTailTempC.toStringAsFixed(2));
    final ambientCtrl = TextEditingController(text: currentSection.ambientTempC.toStringAsFixed(1));
    final remarksCtrl = TextEditingController(text: 'Routine Hourly Verification');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: [
              const Icon(Icons.add_chart_rounded, color: AppTheme.primaryLight, size: 22),
              const SizedBox(width: 10),
              Text(
                'Log DWT & RTD Reading (${currentSection.sectionId.code})',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hydraulic Deadweight Tester & Dual Quartz Gauges (Bar)',
                    style: TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModalTextField(
                          controller: dwtCtrl,
                          label: 'DWT (Budenberg)',
                          suffix: 'Bar',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildModalTextField(
                          controller: qpACtrl,
                          label: 'Quartz QPG-A',
                          suffix: 'Bar',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildModalTextField(
                          controller: qpBCtrl,
                          label: 'Quartz QPG-B',
                          suffix: 'Bar',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ground Temperature RTDs (1.5m Pipe Depth, °C)',
                    style: TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModalTextField(
                          controller: rtdHeadCtrl,
                          label: 'RTD Head (Ch 0)',
                          suffix: '°C',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildModalTextField(
                          controller: rtdMidCtrl,
                          label: 'RTD Mid (Ch Mid)',
                          suffix: '°C',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildModalTextField(
                          controller: rtdTailCtrl,
                          label: 'RTD Tail (Ch End)',
                          suffix: '°C',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildModalTextField(
                    controller: ambientCtrl,
                    label: 'Ambient Air Temp (°C)',
                    suffix: '°C',
                  ),
                  const SizedBox(height: 14),
                  _buildModalTextField(
                    controller: remarksCtrl,
                    label: 'Inspector Remarks / Event',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final dwt = double.tryParse(dwtCtrl.text) ?? currentSection.currentPressureBar;
                final qA = double.tryParse(qpACtrl.text) ?? dwt;
                final qB = double.tryParse(qpBCtrl.text) ?? dwt;
                final rH = double.tryParse(rtdHeadCtrl.text) ?? 22.4;
                final rM = double.tryParse(rtdMidCtrl.text) ?? 22.1;
                final rT = double.tryParse(rtdTailCtrl.text) ?? 22.3;
                final amb = double.tryParse(ambientCtrl.text) ?? 28.0;

                final currentLogs = _hourlyLogs[_selectedSectionId] ?? [];
                final nextHour = currentLogs.isEmpty ? 0 : currentLogs.last.hour + 1;
                final meanT = (rH + rM + rT) / 3.0;
                final theoP = currentSection.leakTestPressureBar + ((meanT - 22.1) * 0.94);
                final delta = dwt - theoP;

                final newLog = HourlyHydroLog(
                  hour: nextHour,
                  timestamp: DateFormat('HH:mm').format(DateTime.now()),
                  deadweightBar: dwt,
                  quartzABar: qA,
                  quartzBBar: qB,
                  rtdHeadC: rH,
                  rtdMidC: rM,
                  rtdTailC: rT,
                  ambientC: amb,
                  theoreticalBar: double.parse(theoP.toStringAsFixed(2)),
                  deltaBar: double.parse(delta.toStringAsFixed(3)),
                  isWithinTol: delta.abs() <= 0.15,
                  remarks: remarksCtrl.text,
                );

                setState(() {
                  currentLogs.add(newLog);
                  currentSection.currentPressureBar = dwt;
                  currentSection.deadweightReadingBar = dwt;
                  currentSection.quartzGaugeABar = qA;
                  currentSection.quartzGaugeBBar = qB;
                  currentSection.rtdHeadTempC = rH;
                  currentSection.rtdMidTempC = rM;
                  currentSection.rtdTailTempC = rT;
                  currentSection.ambientTempC = amb;
                  currentSection.lastUpdated = DateTime.now();
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.surfaceCard,
                    content: Text(
                      'Logged reading for ${currentSection.sectionId.code} at Hour $nextHour: ${dwt.toStringAsFixed(2)} Bar (Delta: ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(3)} Bar)',
                      style: const TextStyle(color: AppTheme.tertiary),
                    ),
                  ),
                );
              },
              child: const Text('Save Log'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPvPointDialog() {
    final currentSection = _sections[_selectedSectionId]!;
    final pCtrl = TextEditingController(text: '80.0');
    final volCtrl = TextEditingController(text: '28600.0');
    final strokesCtrl = TextEditingController(text: '15450');
    final noteCtrl = TextEditingController(text: 'Pressure Step Increment');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: [
              const Icon(Icons.stacked_line_chart_rounded, color: AppTheme.secondary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Record P/V Increment (${currentSection.sectionId.code})',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModalTextField(
                controller: pCtrl,
                label: 'Gauge Pressure (Bar)',
                suffix: 'Bar',
              ),
              const SizedBox(height: 12),
              _buildModalTextField(
                controller: volCtrl,
                label: 'Cumulative Volume Injected (Liters)',
                suffix: 'L',
              ),
              const SizedBox(height: 12),
              _buildModalTextField(
                controller: strokesCtrl,
                label: 'Positive Displacement Stroke Count',
              ),
              const SizedBox(height: 12),
              _buildModalTextField(
                controller: noteCtrl,
                label: 'Step Remarks',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final p = double.tryParse(pCtrl.text) ?? 80.0;
                final v = double.tryParse(volCtrl.text) ?? 28600.0;
                final strokes = int.tryParse(strokesCtrl.text) ?? 15450;

                final slope = 21.4 * currentSection.lengthKm;
                final theo = p * slope;
                final offset02 = theo + (currentSection.totalFillVolumeM3 * 1000 * 0.002);

                final newPoint = PvDataPoint(
                  pressureBar: p,
                  actualVolumeLiters: v,
                  theoreticalElasticLiters: theo,
                  offset02Liters: offset02,
                  pumpStrokes: strokes,
                  isHoldPoint: false,
                  note: noteCtrl.text,
                );

                setState(() {
                  _pvCurves[_selectedSectionId]?.add(newPoint);
                  _pvCurves[_selectedSectionId]?.sort((a, b) => a.pressureBar.compareTo(b.pressureBar));
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.surfaceCard,
                    content: Text(
                      'P/V point added: ${p.toStringAsFixed(1)} Bar — $v L. Zero Trapped Air confirmed!',
                      style: const TextStyle(color: AppTheme.tertiary),
                    ),
                  ),
                );
              },
              child: const Text('Add P/V Point', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddPigRunDialog() {
    final currentSection = _sections[_selectedSectionId]!;
    PigType selectedType = PigType.foamSwabMed;
    final speedCtrl = TextEditingController(text: '1.40');
    final drivePCtrl = TextEditingController(text: '2.2');
    final preWeightCtrl = TextEditingController(text: '58.0');
    final postWeightCtrl = TextEditingController(text: '62.4');
    final waterCtrl = TextEditingController(text: '4.4');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Row(
                children: [
                  const Icon(Icons.cleaning_services_rounded, color: AppTheme.primaryLight, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Record Pig Run (${currentSection.sectionId.code})',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Pig Model / Train Position',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<PigType>(
                        initialValue: selectedType,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: PigType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                Icon(t.icon, size: 16, color: AppTheme.primaryLight),
                                const SizedBox(width: 8),
                                Text(t.title),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedType = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModalTextField(
                              controller: speedCtrl,
                              label: 'Velocity (m/s)',
                              suffix: 'm/s',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildModalTextField(
                              controller: drivePCtrl,
                              label: 'Drive ΔP (Bar)',
                              suffix: 'Bar',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModalTextField(
                              controller: preWeightCtrl,
                              label: 'Pre-Run Wt (kg)',
                              suffix: 'kg',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildModalTextField(
                              controller: postWeightCtrl,
                              label: 'Post-Run Wt (kg)',
                              suffix: 'kg',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildModalTextField(
                        controller: waterCtrl,
                        label: 'Water Squeezed / Displaced (Liters)',
                        suffix: 'L',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final speed = double.tryParse(speedCtrl.text) ?? 1.40;
                    final dp = double.tryParse(drivePCtrl.text) ?? 2.2;
                    final preW = double.tryParse(preWeightCtrl.text) ?? 58.0;
                    final postW = double.tryParse(postWeightCtrl.text) ?? 62.4;
                    final wL = double.tryParse(waterCtrl.text) ?? 4.4;
                    final gainPct = preW > 0 ? ((postW - preW) / preW) * 100 : 0.0;

                    final newRun = DewateringPigRun(
                      runId: 'PIG-${currentSection.sectionId.code}-${(_pigRuns[_selectedSectionId]?.length ?? 0) + 1}',
                      type: selectedType,
                      launchTime: DateFormat('HH:mm').format(DateTime.now().subtract(const Duration(hours: 3))),
                      receiveTime: DateFormat('HH:mm').format(DateTime.now()),
                      distanceKm: currentSection.lengthKm,
                      speedMps: speed,
                      drivingPressureBar: dp,
                      preRunWeightKg: preW,
                      postRunWeightKg: postW,
                      waterAbsorbedLiters: wL,
                      cupWearPercent: 1.1,
                      transmitterStatus: 'Received at Trap (22 Hz)',
                      isPassed: gainPct <= 5.0 || selectedType == PigType.mechanicalScraper,
                    );

                    setState(() {
                      _pigRuns[_selectedSectionId]?.add(newRun);
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.surfaceCard,
                        content: Text(
                          'Pig run logged: ${newRun.runId} (${gainPct.toStringAsFixed(1)}% weight gain)',
                          style: TextStyle(color: newRun.isPassed ? AppTheme.tertiary : AppTheme.secondary),
                        ),
                      ),
                    );
                  },
                  child: const Text('Save Pig Run'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTripartiteSignDialog() {
    final currentSection = _sections[_selectedSectionId]!;
    final contractorCtrl = TextEditingController(text: 'Er. Rajesh Nair (Kalpataru Lead QA/QC)');
    final tpiaCtrl = TextEditingController(text: 'Er. Marcus Vance (EIL TPIA Level III)');
    final clientCtrl = TextEditingController(text: 'Er. B. Bordoloi (Oil India Resident Engineer)');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: const [
              Icon(Icons.verified_user_rounded, color: AppTheme.tertiary, size: 24),
              SizedBox(width: 10),
              Text(
                'Tripartite Hydrotest Certification',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.tertiary,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ASME B31.8 §841.3 & OISD-141 COMPLIANCE DECLARATION',
                          style: TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pipeline Section ${currentSection.sectionId.code} (${currentSection.lengthKm} km, 18" X70) has undergone 1.25x Strength Testing (112.5 Bar) and 24-Hr Leaktightness Testing (90.0 Bar). Trapped air is certified < 0.2% via P/V plot. Dew point verification target is -40°C.',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildModalTextField(
                    controller: contractorCtrl,
                    label: 'Contractor Lead QA/QC Engineer',
                  ),
                  const SizedBox(height: 12),
                  _buildModalTextField(
                    controller: tpiaCtrl,
                    label: 'EIL TPIA Level III Inspecting Authority',
                  ),
                  const SizedBox(height: 12),
                  _buildModalTextField(
                    controller: clientCtrl,
                    label: 'Oil India Limited Resident Engineer',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tertiary,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  currentSection.isTripartiteSigned = true;
                  currentSection.isStrengthPassed = true;
                  currentSection.isLeakPassed = true;
                  currentSection.currentPhase = SectionPhase.certifiedApproved;
                  currentSection.contractorSignatory = contractorCtrl.text;
                  currentSection.tpiaSignatory = tpiaCtrl.text;
                  currentSection.clientSignatory = clientCtrl.text;
                  currentSection.lastUpdated = DateTime.now();
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.surfaceCard,
                    content: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppTheme.tertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Section ${currentSection.sectionId.code} officially certified and endorsed by all 3 parties!',
                            style: const TextStyle(color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              label: const Text('Sign & Seal Dossier', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDossierExportDialog() {
    final currentSection = _sections[_selectedSectionId]!;
    final shaPayload = '${currentSection.sectionId.code}-${currentSection.lengthKm}-${currentSection.designPressureBar}-${currentSection.lastUpdated.toIso8601String()}';
    final sha256Hash = sha256.convert(utf8.encode(shaPayload)).toString().toUpperCase();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: const [
              Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryLight, size: 24),
              SizedBox(width: 10),
              Text(
                'ASME B31.8 Hydrotest Dossier',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
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
                              'REPORT: OIL/HT/2026/${currentSection.sectionId.code}',
                              style: const TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.tertiary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                currentSection.isTripartiteSigned ? 'CERTIFIED' : 'PROVISIONAL',
                                style: TextStyle(
                                  color: currentSection.isTripartiteSigned ? AppTheme.tertiary : AppTheme.secondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppTheme.border, height: 16),
                        _buildDossierRow('Pipeline Section', '${currentSection.sectionId.code} (${currentSection.sectionId.sectionName})'),
                        _buildDossierRow('Pipe Specification', '${currentSection.pipeSize}, ${currentSection.materialGrade}'),
                        _buildDossierRow('Chainage & Length', '${currentSection.startChainage} to ${currentSection.endChainage} (${currentSection.lengthKm} km)'),
                        _buildDossierRow('Design Pressure', '${currentSection.designPressureBar.toStringAsFixed(1)} Bar'),
                        _buildDossierRow('Strength Test Pressure', '${currentSection.strengthTestPressureBar.toStringAsFixed(1)} Bar (1.25x DP)'),
                        _buildDossierRow('Leaktightness Pressure', '${currentSection.leakTestPressureBar.toStringAsFixed(1)} Bar (24 Hours)'),
                        _buildDossierRow('P/V Air Volume', '${currentSection.airVolumePercent.toStringAsFixed(3)}% (Limit: ≤ 0.200%)'),
                        _buildDossierRow('Final Dew Point', '${currentSection.currentDewPointC.toStringAsFixed(1)}°C (Limit: ≤ -40.0°C)'),
                        _buildDossierRow('Instrument Certs', 'DWT #OIL-891, Digiquartz XP2i #A77, Pt100 #RTD-441'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Cryptographic SHA-256 Verification Stamp',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      sha256Hash,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppTheme.primaryLight,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: sha256Hash));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.surfaceCard,
                    content: Text(
                      'Dossier hash copied to clipboard. Generating formal PDF bundle...',
                      style: TextStyle(color: AppTheme.tertiary),
                    ),
                  ),
                );
              },
              label: const Text('Export Dossier PDF'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDossierRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String label,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  // ============================================================================
  // BUILD METHOD & APP BAR
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final currentSection = _sections[_selectedSectionId]!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop_rounded, color: AppTheme.primaryLight, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Pipeline Hydrotesting & Dewatering',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'ASME B31.8 / OISD-141',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '18" API 5L X70 (90 Bar DP) • Strength 112.5 Bar (1.25x) • 24-hr Leak • 0.2% P/V • -40°C Dew Point',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export Hydrotest Dossier',
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryLight),
            onPressed: _showDossierExportDialog,
          ),
          IconButton(
            tooltip: 'Tripartite Endorsement',
            icon: const Icon(Icons.verified_user_rounded, color: AppTheme.tertiary),
            onPressed: _showTripartiteSignDialog,
          ),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 12.5),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: 'Sections & Overview'),
            Tab(icon: Icon(Icons.speed_rounded, size: 18), text: 'Strength & Leak Test'),
            Tab(icon: Icon(Icons.thermostat_rounded, size: 18), text: 'Temp & DWT Stabilize'),
            Tab(icon: Icon(Icons.show_chart_rounded, size: 18), text: 'P/V Plot (0.2% Air)'),
            Tab(icon: Icon(Icons.air_rounded, size: 18), text: 'Dewater & -40°C Dry'),
            Tab(icon: Icon(Icons.verified_rounded, size: 18), text: 'Tripartite Cert'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSectionSelectorBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(currentSection),
                _buildStrengthAndLeakTab(currentSection),
                _buildTempStabilizationTab(currentSection),
                _buildPvPlotTab(currentSection),
                _buildDewateringDryingTab(currentSection),
                _buildCertificationTab(currentSection),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SECTION SELECTOR BAR (TS-01 TO TS-06)
  // ============================================================================

  Widget _buildSectionSelectorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: HydroSectionId.values.map((secId) {
            final sec = _sections[secId]!;
            final isSelected = secId == _selectedSectionId;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedSectionId = secId;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.2)
                        : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: sec.currentPhase.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sec.sectionId.code,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${sec.lengthKm} km)',
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: sec.currentPhase.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sec.currentPhase.label,
                          style: TextStyle(
                            color: sec.currentPhase.color,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 1: OVERVIEW & SECTION DASHBOARD
  // ============================================================================

  Widget _buildOverviewTab(PipelineHydroSection section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header card with key pipeline parameters
          _buildSectionHeaderCard(section),
          const SizedBox(height: 16),

          // Live Readouts Row (Pressure, Temperature, Dew Point, Air %)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'CURRENT TEST PRESSURE',
                  value: '${section.currentPressureBar.toStringAsFixed(2)} Bar',
                  subtitle: 'Target: ${section.currentPhase == SectionPhase.strengthTestHold ? "112.50 Bar" : "90.00 Bar"}',
                  icon: Icons.speed_rounded,
                  color: AppTheme.primaryLight,
                  statusText: section.currentPhase == SectionPhase.strengthTestHold
                      ? 'STRENGTH HOLD'
                      : (section.currentPhase == SectionPhase.leaktightness24Hr ? 'LEAK TEST HOLD' : 'NORMAL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'GROUND RTD @ 1.5M DEPTH',
                  value: '${section.meanSoilRtdTempC.toStringAsFixed(2)} °C',
                  subtitle: 'Head: ${section.rtdHeadTempC.toStringAsFixed(1)} | Mid: ${section.rtdMidTempC.toStringAsFixed(1)} | Tail: ${section.rtdTailTempC.toStringAsFixed(1)}',
                  icon: Icons.thermostat_rounded,
                  color: AppTheme.secondary,
                  statusText: 'STABILIZED (ΔT<0.3°C)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'TRAPPED AIR (P/V CURVE)',
                  value: '${section.airVolumePercent.toStringAsFixed(3)} %',
                  subtitle: 'ASME B31.8 Limit: ≤ 0.200%',
                  icon: Icons.pie_chart_rounded,
                  color: section.isAirVolumeCompliant ? AppTheme.tertiary : const Color(0xFFEF4444),
                  statusText: section.isAirVolumeCompliant ? 'PASS: AIR-FREE' : 'EXCESS AIR',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'OUTLET DEW POINT',
                  value: '${section.currentDewPointC.toStringAsFixed(1)} °C',
                  subtitle: 'Target: ≤ -40.0 °C per §841.3',
                  icon: Icons.air_rounded,
                  color: section.isDewPointCompliant ? AppTheme.tertiary : const Color(0xFFA855F7),
                  statusText: section.isDewPointCompliant ? 'ACCEPTANCE MET' : 'DRYING IN PROGRESS',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Technical Specifications & ASME B31.8 / OISD-141 Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildEngineeringSpecCard(section),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildElevationProfileCard(section),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Six Section Matrix (Status table for TS-01 through TS-06)
          _buildAllSectionsMatrixCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderCard(PipelineHydroSection section) {
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          section.sectionId.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        section.sectionId.sectionName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chainage: ${section.startChainage} to ${section.endChainage} • Length: ${section.lengthKm} km • Fill Volume: ${NumberFormat('#,##0').format(section.totalFillVolumeM3 * 1000)} Liters',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: section.currentPhase.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: section.currentPhase.color),
                    ),
                    child: Row(
                      children: [
                        Icon(section.currentPhase.icon, size: 14, color: section.currentPhase.color),
                        const SizedBox(width: 6),
                        Text(
                          section.currentPhase.label,
                          style: TextStyle(
                            color: section.currentPhase.color,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 20),
          Row(
            children: [
              _buildHeaderBadge(Icons.straighten_rounded, 'Pipe OD', section.pipeSize),
              _buildHeaderBadge(Icons.architecture_rounded, 'Grade', section.materialGrade),
              _buildHeaderBadge(Icons.line_weight_rounded, 'WT', section.wallThickness),
              _buildHeaderBadge(Icons.compress_rounded, 'Design Pressure', '${section.designPressureBar.toStringAsFixed(1)} Bar'),
              _buildHeaderBadge(Icons.shield_rounded, 'Strength Test (1.25x)', '${section.strengthTestPressureBar.toStringAsFixed(1)} Bar'),
              _buildHeaderBadge(Icons.history_toggle_off_rounded, '24-Hr Leak Test', '${section.leakTestPressureBar.toStringAsFixed(1)} Bar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 11, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String statusText,
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
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineeringSpecCard(PipelineHydroSection section) {
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
              Row(
                children: const [
                  Icon(Icons.engineering_rounded, color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Code Compliance & Engineering Calculations',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  'ASME B31.8 Cl 841.3 / OISD-141',
                  style: TextStyle(color: AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 18),
          _buildSpecRow('Governing Pipeline Code', 'ASME B31.8 (Gas Transmission Pipelines) & OISD-141 Standard'),
          _buildSpecRow('Design Factor (F)', '0.72 (Class 1 & 2 Cross-Country Mainline Location)'),
          _buildSpecRow('Specified Min Yield Strength (SMYS)', '485 MPa (70,343 psi) — API 5L Grade X70 PSL2'),
          _buildSpecRow('Hoop Stress at Strength Test (112.5 Bar)', '215.8 MPa (44.5% of SMYS, safe threshold < 90% SMYS)'),
          _buildSpecRow('Strength Test Hold Duration', '4 Hours minimum continuous hold with zero unexplained drop'),
          _buildSpecRow('Leaktightness Hold Duration', '24 Hours with temperature compensation & DWT calibration'),
          _buildSpecRow('Permissible Pressure Variance', '±0.15 Bar thermally compensated (Thermal coeff ~0.94 Bar/°C)'),
          _buildSpecRow('Water Fill Treatment', 'Filtered to 50µm, 200 ppm Oxygen Scavenger, 50 ppm Biocide'),
        ],
      ),
    );
  }

  Widget _buildElevationProfileCard(PipelineHydroSection section) {
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
            children: const [
              Icon(Icons.terrain_rounded, color: AppTheme.secondary, size: 18),
              SizedBox(width: 8),
              Text(
                'Elevation Profile & Hydrostatic Head',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 18),
          _buildSpecRow('Test Head Location', section.testHeadLocation),
          _buildSpecRow('Receiver Location', section.receiverLocation),
          _buildSpecRow('Route High Point', section.highPointCh),
          _buildSpecRow('Route Low Point', section.lowPointCh),
          _buildSpecRow('Elevation Differential', 'ΔH = 44.4 m (Burhi Dihing flood plain)'),
          _buildSpecRow('Static Head Pressure (ΔP_head)', '${section.staticHeadDiffBar.toStringAsFixed(2)} Bar (0.0981 Bar/m)'),
          _buildSpecRow('Top Section Test Pressure', '${(section.strengthTestPressureBar - section.staticHeadDiffBar).toStringAsFixed(2)} Bar'),
          _buildSpecRow('Lowest Point Max Pressure', '${section.strengthTestPressureBar.toStringAsFixed(2)} Bar (112.5 Bar cap)'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 210,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          const Text(' : ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSectionsMatrixCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.table_chart_rounded, color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Pipeline Hydrotesting Master Matrix (TS-01 through TS-06)',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'Total Project Pipeline: 94.50 km (18" API 5L X70)',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.border, height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.surface),
              dataRowColor: WidgetStateProperty.all(AppTheme.surfaceCard),
              horizontalMargin: 16,
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Section', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Sector Span', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Length', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Design P', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Strength P (1.25x)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Phase Status', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Live Pressure', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Air Volume', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Dew Point', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Action', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
              rows: HydroSectionId.values.map((secId) {
                final s = _sections[secId]!;
                final isCurrent = secId == _selectedSectionId;

                return DataRow(
                  selected: isCurrent,
                  onSelectChanged: (_) {
                    setState(() {
                      _selectedSectionId = secId;
                    });
                  },
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: s.currentPhase.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(s.sectionId.code, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    DataCell(Text('${s.startChainage} - ${s.endChainage}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                    DataCell(Text('${s.lengthKm} km', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                    DataCell(Text('${s.designPressureBar.toStringAsFixed(1)} Bar', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                    DataCell(Text('${s.strengthTestPressureBar.toStringAsFixed(1)} Bar', style: const TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: s.currentPhase.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          s.currentPhase.label,
                          style: TextStyle(color: s.currentPhase.color, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    DataCell(Text('${s.currentPressureBar.toStringAsFixed(2)} Bar', style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold))),
                    DataCell(
                      Text(
                        s.airVolumePercent > 0 ? '${s.airVolumePercent.toStringAsFixed(3)}%' : 'Pending',
                        style: TextStyle(
                          color: s.isAirVolumeCompliant ? AppTheme.tertiary : AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${s.currentDewPointC.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          color: s.isDewPointCompliant ? AppTheme.tertiary : (s.currentDewPointC < 0 ? const Color(0xFFA855F7) : AppTheme.textMuted),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrent ? AppTheme.primary : AppTheme.surface,
                          foregroundColor: isCurrent ? Colors.white : AppTheme.primaryLight,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(60, 26),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedSectionId = secId;
                          });
                        },
                        child: Text(isCurrent ? 'Viewing' : 'Select', style: const TextStyle(fontSize: 10.5)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: STRENGTH (112.5 BAR) & LEAKTIGHTNESS (90 BAR)
  // ============================================================================

  Widget _buildStrengthAndLeakTab(PipelineHydroSection section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Pressurization Roadmap Card
          _buildPressurizationRoadmapCard(section),
          const SizedBox(height: 16),

          // Two-Column Grid: Strength Test details vs 24-hr Leaktightness details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildStrengthTestDetailCard(section)),
              const SizedBox(width: 16),
              Expanded(child: _buildLeakTestDetailCard(section)),
            ],
          ),
          const SizedBox(height: 16),

          // Elevation Head & Top/Bottom Pressure Differential Calculator
          _buildHeadPressureCalculatorCard(section),
        ],
      ),
    );
  }

  Widget _buildPressurizationRoadmapCard(PipelineHydroSection section) {
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
              Row(
                children: const [
                  Icon(Icons.stairs_rounded, color: AppTheme.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Step-Pressurization Protocol per ASME B31.8 §841.3',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  'Section ${section.sectionId.code}',
                  style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 20),
          const SizedBox(height: 6),
          // Steps visual timeline
          Row(
            children: [
              _buildStepNode('1', '35.0 Bar', '30% DP', 'Fill Check', true),
              _buildStepConnector(true),
              _buildStepNode('2', '45.0 Bar', '50% DP', 'P/V Air Check', section.currentPressureBar >= 45.0),
              _buildStepConnector(section.currentPressureBar >= 45.0),
              _buildStepNode('3', '75.0 Bar', '70% DP', 'Hold 15 Min', section.currentPressureBar >= 75.0),
              _buildStepConnector(section.currentPressureBar >= 75.0),
              _buildStepNode('4', '90.0 Bar', '100% DP', 'Leak Check', section.currentPressureBar >= 90.0),
              _buildStepConnector(section.currentPressureBar >= 90.0),
              _buildStepNode('5', '112.5 Bar', '125% DP', '4-Hr Strength', section.currentPressureBar >= 112.0),
              _buildStepConnector(section.isStrengthPassed),
              _buildStepNode('6', '90.0 Bar', 'Depressurize', '24-Hr Leak Test', section.currentPhase == SectionPhase.leaktightness24Hr || section.isLeakPassed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode(String stepNum, String pressure, String percent, String label, bool isDone) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone ? AppTheme.primary : AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? AppTheme.primaryLight : AppTheme.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                stepNum,
                style: TextStyle(
                  color: isDone ? Colors.white : AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pressure,
            style: TextStyle(
              color: isDone ? AppTheme.textPrimary : AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            percent,
            style: const TextStyle(color: AppTheme.secondary, fontSize: 9.5),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(
      width: 24,
      height: 2,
      color: isActive ? AppTheme.primaryLight : AppTheme.border,
      margin: const EdgeInsets.only(bottom: 30),
    );
  }

  Widget _buildStrengthTestDetailCard(PipelineHydroSection section) {
    final isHolding = section.currentPhase == SectionPhase.strengthTestHold;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHolding ? AppTheme.primaryLight : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.speed_rounded, color: AppTheme.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Strength Test (1.25x Design Pressure)',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (section.isStrengthPassed ? AppTheme.tertiary : AppTheme.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  section.isStrengthPassed ? 'COMPLETED' : (isHolding ? 'ACTIVE HOLD' : 'SCHEDULED'),
                  style: TextStyle(
                    color: section.isStrengthPassed ? AppTheme.tertiary : AppTheme.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 18),
          _buildSpecRow('Required Test Pressure', '112.50 Bar (1.25 × 90.0 Bar DP)'),
          _buildSpecRow('Current Actual Pressure', '${section.currentPressureBar.toStringAsFixed(2)} Bar'),
          _buildSpecRow('Standard Reference', 'ASME B31.8 Section 841.3.2 / OISD-141 Table 7'),
          _buildSpecRow('Specified Hold Time', '4 Hours continuous hold'),
          _buildSpecRow('Hold Status / Remaining', isHolding ? '${section.strengthHoldRemainingMins} mins remaining' : (section.isStrengthPassed ? '4 Hours Completed (Zero Drop)' : 'Not Started')),
          _buildSpecRow('Max Allowable Stress', '485 MPa SMYS (Actual: 215.8 MPa = 44.5% SMYS)'),
          _buildSpecRow('Pressure Loss Permitted', '0.00 Bar (strictly zero unexplained pressure drop)'),
          const SizedBox(height: 14),
          // Timer Widget
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_rounded, color: AppTheme.primaryLight, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Strength Test Hold Status', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5)),
                      Text(
                        section.isStrengthPassed
                            ? '4:00:00 HELD — ZERO PRESSURE LOSS'
                            : (isHolding ? 'HOLDING: 03:15:00 / 04:00:00' : 'HOLD NOT ACTIVE'),
                        style: TextStyle(
                          color: section.isStrengthPassed ? AppTheme.tertiary : (isHolding ? AppTheme.secondary : AppTheme.textMuted),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
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

  Widget _buildLeakTestDetailCard(PipelineHydroSection section) {
    final isLeakActive = section.currentPhase == SectionPhase.leaktightness24Hr;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLeakActive ? AppTheme.primaryLight : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.av_timer_rounded, color: AppTheme.secondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '24-Hour Leaktightness Test (1.0x DP)',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (section.isLeakPassed ? AppTheme.tertiary : AppTheme.secondary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  section.isLeakPassed ? 'CERTIFIED' : (isLeakActive ? 'HOUR 18 OF 24' : 'PENDING'),
                  style: TextStyle(
                    color: section.isLeakPassed ? AppTheme.tertiary : AppTheme.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 18),
          _buildSpecRow('Required Test Pressure', '90.00 Bar (100% Design Pressure)'),
          _buildSpecRow('Current Actual Pressure', '${section.deadweightReadingBar.toStringAsFixed(2)} Bar (DWT)'),
          _buildSpecRow('Standard Reference', 'ASME B31.8 Section 841.3.3 / OISD-141 Clause 8.2'),
          _buildSpecRow('Hold Duration', '24 Continuous Hours with hourly logs'),
          _buildSpecRow('Thermal Balance Coeff', 'B = 0.94 Bar / °C (Thermally compensated)'),
          _buildSpecRow('Measured Variance', 'ΔP = +0.02 Bar (Well within ±0.15 Bar limit)'),
          _buildSpecRow('Instrumentation', 'Dual Quartz (QPG-A/B) + Hydraulic DWT'),
          const SizedBox(height: 14),
          // Timer Widget
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded, color: AppTheme.secondary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Leaktightness Timer (24-Hour Hold)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5)),
                      Text(
                        section.isLeakPassed
                            ? '24:00:00 COMPLETED — ACCEPTABLE'
                            : (isLeakActive ? '18:00:00 ELAPSED • 06:00:00 REMAINING' : 'HOLD NOT STARTED'),
                        style: TextStyle(
                          color: section.isLeakPassed ? AppTheme.tertiary : (isLeakActive ? AppTheme.secondary : AppTheme.textMuted),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
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

  Widget _buildHeadPressureCalculatorCard(PipelineHydroSection section) {
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
            children: const [
              Icon(Icons.calculate_rounded, color: AppTheme.tertiary, size: 20),
              SizedBox(width: 8),
              Text(
                'Static Hydrostatic Head Differential Analysis (High vs Low Point)',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HIGHEST POINT ELEVATION', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(section.highPointCh, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Test Pressure: ${(section.strengthTestPressureBar - section.staticHeadDiffBar).toStringAsFixed(2)} Bar', style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TEST HEAD MANIFOLD (Ch 14+850)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(section.testHeadLocation, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Target Pump Pressure: ${section.strengthTestPressureBar.toStringAsFixed(2)} Bar', style: const TextStyle(color: AppTheme.secondary, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LOWEST ELEVATION (Burhi Dihing)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(section.lowPointCh, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Total Head: ${(section.strengthTestPressureBar).toStringAsFixed(2)} Bar (112.5 Bar Cap)', style: const TextStyle(color: AppTheme.tertiary, fontSize: 11)),
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

  // ============================================================================
  // TAB 3: TEMPERATURE STABILIZATION & DWT CURVE
  // ============================================================================

  Widget _buildTempStabilizationTab(PipelineHydroSection section) {
    final logs = _hourlyLogs[_selectedSectionId] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instrumentation banner card
          _buildInstrumentationStatusBanner(section),
          const SizedBox(height: 16),

          // Pressure vs Temperature Stabilization Chart
          _buildStabilizationChartCard(section, logs),
          const SizedBox(height: 16),

          // Hourly Verification Table
          _buildHourlyLogsTableCard(section, logs),
        ],
      ),
    );
  }

  Widget _buildInstrumentationStatusBanner(PipelineHydroSection section) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInstrumentTile(
              'HYDRAULIC DEADWEIGHT TESTER',
              'Budenberg Model 700 (0.01 Bar)',
              '${section.deadweightReadingBar.toStringAsFixed(2)} Bar',
              'Traceable Cert #OIL/CAL/26-891',
              Icons.balance_rounded,
              AppTheme.primaryLight,
            ),
          ),
          Container(width: 1, height: 50, color: AppTheme.border),
          Expanded(
            child: _buildInstrumentTile(
              'DUAL QUARTZ SENSOR (A/B)',
              'Paroscientific Digiquartz QPG',
              'A: ${section.quartzGaugeABar.toStringAsFixed(2)} | B: ${section.quartzGaugeBBar.toStringAsFixed(2)}',
              'Differential: ${(section.quartzGaugeABar - section.quartzGaugeBBar).abs().toStringAsFixed(2)} Bar (≤0.05)',
              Icons.sensors_rounded,
              AppTheme.secondary,
            ),
          ),
          Container(width: 1, height: 50, color: AppTheme.border),
          Expanded(
            child: _buildInstrumentTile(
              'GROUND RTDs @ 1.5M DEPTH',
              'Pt100 4-Wire Class A Sensors',
              'Mean: ${section.meanSoilRtdTempC.toStringAsFixed(2)} °C',
              'Head: ${section.rtdHeadTempC.toStringAsFixed(1)}° | Mid: ${section.rtdMidTempC.toStringAsFixed(1)}° | Tail: ${section.rtdTailTempC.toStringAsFixed(1)}°',
              Icons.thermostat_rounded,
              AppTheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstrumentTile(
    String title,
    String model,
    String reading,
    String cert,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(reading, style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.bold)),
          Text(model, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10.5)),
          Text(cert, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
        ],
      ),
    );
  }

  Widget _buildStabilizationChartCard(PipelineHydroSection section, List<HourlyHydroLog> logs) {
    final spotsActual = logs.map((l) => FlSpot(l.hour.toDouble(), l.deadweightBar)).toList();
    final spotsTheoretical = logs.map((l) => FlSpot(l.hour.toDouble(), l.theoreticalBar)).toList();

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
                  Row(
                    children: const [
                      Icon(Icons.stacked_line_chart_rounded, color: AppTheme.primaryLight, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Pressure & Ground Temperature Stabilization Curve (24 Hours)',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Deadweight Tester Reading vs Thermally-Compensated Pressure & Mean Soil RTD (1.5m Pipe Depth)',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem('Actual DWT (Bar)', AppTheme.primaryLight, false),
                  const SizedBox(width: 12),
                  _buildLegendItem('Theoretical P (Bar)', AppTheme.tertiary, true),
                  const SizedBox(width: 12),
                  _buildLegendItem('Ground RTD (°C)', AppTheme.secondary, false),
                ],
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 20),
          const SizedBox(height: 10),

          // Chart
          SizedBox(
            height: 250,
            child: logs.isEmpty
                ? const Center(child: Text('No stabilization log data recorded yet for this section', style: TextStyle(color: AppTheme.textMuted)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 0.1,
                        verticalInterval: 4,
                        getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.border.withValues(alpha: 0.4), strokeWidth: 0.8),
                        getDrawingVerticalLine: (v) => FlLine(color: AppTheme.border.withValues(alpha: 0.3), strokeWidth: 0.8),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: 0.5,
                            getTitlesWidget: (val, meta) {
                              return Text(
                                '${val.toStringAsFixed(1)}°C',
                                style: const TextStyle(color: AppTheme.secondary, fontSize: 9.5),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: 2,
                            getTitlesWidget: (val, meta) {
                              final h = val.toInt();
                              return Text('${h}h', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10));
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            interval: 0.2,
                            getTitlesWidget: (val, meta) {
                              return Text(
                                '${val.toStringAsFixed(1)} Bar',
                                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 9.5),
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
                      maxX: 24,
                      minY: section.currentPhase == SectionPhase.strengthTestHold ? 112.0 : 89.6,
                      maxY: section.currentPhase == SectionPhase.strengthTestHold ? 112.8 : 90.5,
                      lineBarsData: [
                        // Actual DWT Pressure
                        LineChartBarData(
                          spots: spotsActual,
                          isCurved: true,
                          curveSmoothness: 0.2,
                          color: AppTheme.primaryLight,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            checkToShowDot: (spot, barData) => spot.x.toInt() % 3 == 0 || spot.x == spotsActual.length - 1,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 3,
                              color: AppTheme.primaryLight,
                              strokeWidth: 1,
                              strokeColor: AppTheme.surface,
                            ),
                          ),
                        ),
                        // Theoretical Compensated Line
                        LineChartBarData(
                          spots: spotsTheoretical,
                          isCurved: true,
                          curveSmoothness: 0.2,
                          color: AppTheme.tertiary,
                          barWidth: 1.8,
                          dashArray: [6, 4],
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

  Widget _buildLegendItem(String label, Color color, bool isDashed) {
    return Row(
      children: [
        Container(
          width: 14,
          height: isDashed ? 2 : 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: isDashed ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildHourlyLogsTableCard(PipelineHydroSection section, List<HourlyHydroLog> logs) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.list_alt_rounded, color: AppTheme.secondary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Hourly Deadweight & Temperature Stabilization Logs',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: _showAddHourlyLogDialog,
                  label: const Text('Add Reading', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.border, height: 1),
          logs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No hourly logs recorded yet. Click "Add Reading" to start logging.', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.surface),
                    dataRowColor: WidgetStateProperty.all(AppTheme.surfaceCard),
                    horizontalMargin: 16,
                    columnSpacing: 18,
                    columns: const [
                      DataColumn(label: Text('Hour', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Time', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('DWT (Bar)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('QPG-A', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('QPG-B', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Mean Soil RTD', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Ambient °C', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Theoretical P', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Delta (Bar)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Tolerance', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Remarks', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                    rows: logs.reversed.map((log) {
                      return DataRow(
                        cells: [
                          DataCell(Text('${log.hour}h', style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 11.5))),
                          DataCell(Text(log.timestamp, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                          DataCell(Text(log.deadweightBar.toStringAsFixed(2), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5))),
                          DataCell(Text(log.quartzABar.toStringAsFixed(2), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                          DataCell(Text(log.quartzBBar.toStringAsFixed(2), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                          DataCell(Text('${log.meanSoilTempC.toStringAsFixed(2)} °C', style: const TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.w600))),
                          DataCell(Text('${log.ambientC.toStringAsFixed(1)} °C', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11))),
                          DataCell(Text('${log.theoreticalBar.toStringAsFixed(2)} Bar', style: const TextStyle(color: AppTheme.tertiary, fontSize: 11))),
                          DataCell(
                            Text(
                              '${log.deltaBar >= 0 ? '+' : ''}${log.deltaBar.toStringAsFixed(3)}',
                              style: TextStyle(
                                color: log.isWithinTol ? AppTheme.tertiary : const Color(0xFFEF4444),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: (log.isWithinTol ? AppTheme.tertiary : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                log.isWithinTol ? 'WITHIN LIMIT' : 'EXCEEDED',
                                style: TextStyle(
                                  color: log.isWithinTol ? AppTheme.tertiary : const Color(0xFFEF4444),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(log.remarks, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: P/V PLOT & 0.2% OFFSET AIR LINE
  // ============================================================================

  Widget _buildPvPlotTab(PipelineHydroSection section) {
    final pvData = _pvCurves[_selectedSectionId] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Acceptance Callout Banner
          _buildAirVolumeAcceptanceBanner(section),
          const SizedBox(height: 16),

          // P/V Interactive Chart
          _buildPvChartCard(section, pvData),
          const SizedBox(height: 16),

          // Step-by-Step P/V Log Data Table
          _buildPvDataTableCard(section, pvData),
        ],
      ),
    );
  }

  Widget _buildAirVolumeAcceptanceBanner(PipelineHydroSection section) {
    final isPass = section.isAirVolumeCompliant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPass ? AppTheme.tertiary : const Color(0xFFEF4444)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isPass ? AppTheme.tertiary : const Color(0xFFEF4444)).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPass ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: isPass ? AppTheme.tertiary : const Color(0xFFEF4444),
              size: 28,
            ),
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
                      isPass ? 'ZERO TRAPPED AIR GUARANTEE VERIFIED (< 0.2% CRITERIA)' : 'EXCESS AIR DETECTED — RE-VENTING REQUIRED',
                      style: TextStyle(
                        color: isPass ? AppTheme.tertiary : const Color(0xFFEF4444),
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ASME B31.8 §841.3.2 & API RP 1110',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Section Total Fill: ${NumberFormat('#,##0').format(section.totalFillVolumeM3 * 1000)} Liters. 0.2% Offset Limit: ${NumberFormat('#,##0').format(section.totalFillVolumeM3 * 1000 * 0.002)} Liters. Calculated Trapped Air Volume: ${NumberFormat('#,##0').format(section.totalFillVolumeM3 * 1000 * (section.airVolumePercent / 100))} Liters (${section.airVolumePercent.toStringAsFixed(3)}%).',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPvChartCard(PipelineHydroSection section, List<PvDataPoint> pvData) {
    final spotsActual = pvData.map((p) => FlSpot(p.actualVolumeLiters / 1000, p.pressureBar)).toList();
    final spotsElastic = pvData.map((p) => FlSpot(p.theoreticalElasticLiters / 1000, p.pressureBar)).toList();
    final spotsOffset = pvData.map((p) => FlSpot(p.offset02Liters / 1000, p.pressureBar)).toList();

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
                  Row(
                    children: const [
                      Icon(Icons.show_chart_rounded, color: AppTheme.secondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Pressure vs Volume (P/V) Plot with 0.2% Air Offset Verification',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Actual water injected must lie to the LEFT of the 0.2% Offset Line to certify zero trapped air pockets',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem('Actual P/V Injected', AppTheme.primaryLight, false),
                  const SizedBox(width: 12),
                  _buildLegendItem('Theoretical Elastic Line', AppTheme.tertiary, false),
                  const SizedBox(width: 12),
                  _buildLegendItem('0.2% Air Offset Line', const Color(0xFFEF4444), true),
                ],
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 20),
          const SizedBox(height: 10),

          // P/V Chart
          SizedBox(
            height: 280,
            child: pvData.isEmpty
                ? const Center(child: Text('No P/V data logged for this section', style: TextStyle(color: AppTheme.textMuted)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 20,
                        verticalInterval: 10,
                        getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.border.withValues(alpha: 0.4), strokeWidth: 0.8),
                        getDrawingVerticalLine: (v) => FlLine(color: AppTheme.border.withValues(alpha: 0.3), strokeWidth: 0.8),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            interval: 10,
                            getTitlesWidget: (val, meta) {
                              return Text('${val.toInt()} m³', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10));
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 46,
                            interval: 20,
                            getTitlesWidget: (val, meta) {
                              return Text('${val.toInt()} Bar', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.border)),
                      minX: 0,
                      maxX: 50,
                      minY: 0,
                      maxY: 120,
                      lineBarsData: [
                        // Theoretical Elastic Line (Green)
                        LineChartBarData(
                          spots: spotsElastic,
                          isCurved: false,
                          color: AppTheme.tertiary,
                          barWidth: 1.8,
                          dotData: const FlDotData(show: false),
                        ),
                        // 0.2% Offset Line (Red Dashed)
                        LineChartBarData(
                          spots: spotsOffset,
                          isCurved: false,
                          color: const Color(0xFFEF4444),
                          barWidth: 1.8,
                          dashArray: [6, 4],
                          dotData: const FlDotData(show: false),
                        ),
                        // Actual Data Points (Cyan)
                        LineChartBarData(
                          spots: spotsActual,
                          isCurved: true,
                          curveSmoothness: 0.15,
                          color: AppTheme.primaryLight,
                          barWidth: 2.8,
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primaryLight.withValues(alpha: 0.08),
                          ),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 4,
                              color: AppTheme.primaryLight,
                              strokeWidth: 1.5,
                              strokeColor: AppTheme.surface,
                            ),
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

  Widget _buildPvDataTableCard(PipelineHydroSection section, List<PvDataPoint> pvData) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.format_list_numbered_rounded, color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'P/V Pressurization Step Log & Pump Stroke Counts',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: _showAddPvPointDialog,
                  label: const Text('Record Step Increment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.border, height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.surface),
              dataRowColor: WidgetStateProperty.all(AppTheme.surfaceCard),
              horizontalMargin: 16,
              columnSpacing: 22,
              columns: const [
                DataColumn(label: Text('Pressure (Bar)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actual Vol (L)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Theoretical Vol (L)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('0.2% Offset Vol (L)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Difference ΔV', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Pump Strokes', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Air Check Status', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Stage Protocol Note', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
              rows: pvData.map((pt) {
                final isLeftOfOffset = pt.actualVolumeLiters <= pt.offset02Liters;
                final deltaLiters = pt.offset02Liters - pt.actualVolumeLiters;

                return DataRow(
                  cells: [
                    DataCell(Text('${pt.pressureBar.toStringAsFixed(1)} Bar', style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 11.5))),
                    DataCell(Text(NumberFormat('#,##0.0').format(pt.actualVolumeLiters), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5))),
                    DataCell(Text(NumberFormat('#,##0.0').format(pt.theoreticalElasticLiters), style: const TextStyle(color: AppTheme.tertiary, fontSize: 11))),
                    DataCell(Text(NumberFormat('#,##0.0').format(pt.offset02Liters), style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11))),
                    DataCell(Text('+${NumberFormat('#,##0').format(deltaLiters)} L margin', style: const TextStyle(color: AppTheme.secondary, fontSize: 11))),
                    DataCell(Text(NumberFormat('#,##0').format(pt.pumpStrokes), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isLeftOfOffset ? AppTheme.tertiary : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isLeftOfOffset ? 'AIR < 0.2%' : 'AIR > 0.2%',
                          style: TextStyle(
                            color: isLeftOfOffset ? AppTheme.tertiary : const Color(0xFFEF4444),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(pt.note, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 5: DEWATERING, SWABBING & AIR/N2 DRYING (-40°C)
  // ============================================================================

  Widget _buildDewateringDryingTab(PipelineHydroSection section) {
    final pigRuns = _pigRuns[_selectedSectionId] ?? [];
    final dewPointLogs = _dewPointLogs[_selectedSectionId] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4-Phase Progression Tracker
          _buildDewateringRoadmapCard(section),
          const SizedBox(height: 16),

          // Pig Train Pipeline Schematic Card
          _buildPigTrainPipelineCard(section, pigRuns),
          const SizedBox(height: 16),

          // Two-Column: Dewatering & Swabbing Pig Runs vs Dew Point Decay to -40°C
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildPigRunsTableCard(section, pigRuns),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildDewPointDecayCard(section, dewPointLogs),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDewateringRoadmapCard(PipelineHydroSection section) {
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
              Row(
                children: const [
                  Icon(Icons.air_rounded, color: AppTheme.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Dewatering, Swabbing & Air/N2 Drying Protocol (ASME B31.8 §841.3)',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TARGET: -40.0°C DEW POINT',
                  style: TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 20),
          Row(
            children: [
              _buildPhaseCard('PHASE 1', 'Dewatering Pig Train', 'Bi-Di Mechanical displacement', true),
              const SizedBox(width: 10),
              _buildPhaseCard('PHASE 2', 'Foam Pig Swabbing', 'Free water pickup (<5% gain)', section.currentDewPointC < 20.0),
              const SizedBox(width: 10),
              _buildPhaseCard('PHASE 3', 'Desiccant Air Drying', '1500 CFM dry air to -40°C', section.currentDewPointC <= -20.0),
              const SizedBox(width: 10),
              _buildPhaseCard('PHASE 4', 'N2 Purge & Blanket', '99.5% purity @ 0.65 Bar', section.currentDewPointC <= -40.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(String phase, String title, String desc, bool isPassed) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isPassed ? AppTheme.tertiary : AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(phase, style: const TextStyle(color: AppTheme.secondary, fontSize: 9.5, fontWeight: FontWeight.bold)),
                Icon(isPassed ? Icons.check_circle_rounded : Icons.pending_rounded, size: 14, color: isPassed ? AppTheme.tertiary : AppTheme.textMuted),
              ],
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildPigTrainPipelineCard(PipelineHydroSection section, List<DewateringPigRun> runs) {
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
              Row(
                children: const [
                  Icon(Icons.cleaning_services_rounded, color: AppTheme.secondary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Multi-Pig Dewatering Train Pipeline Cross-Section',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'Propulsion: Oil-Free Compressed Air (1500 CFM @ 2.5 Bar)',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 18),
          const SizedBox(height: 10),
          // Interactive visual pipeline graphic
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                // Launcher Trap
                _buildTrapIndicator('LAUNCHER TRAP', section.startChainage, Icons.login_rounded),
                const SizedBox(width: 12),
                // Pipeline Body
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pipe Wall Lines
                      Container(height: 24, decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: AppTheme.border.withValues(alpha: 0.8), width: 3)))),
                      // Water displacement gradient
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF0284C7).withValues(alpha: 0.2),
                                const Color(0xFF0284C7).withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Pigs in transit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPigIcon('PIG 1', 'Mechanical Scraper', Icons.settings_rounded, AppTheme.primaryLight),
                          _buildSlugIndicator('Water Slug'),
                          _buildPigIcon('PIG 2', 'Batching Cup', Icons.layers_rounded, AppTheme.secondary),
                          _buildSlugIndicator('Air Slug'),
                          _buildPigIcon('SWAB', 'Foam Pig', Icons.cleaning_services_rounded, AppTheme.tertiary),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Receiver Trap
                _buildTrapIndicator('RECEIVER TRAP', section.endChainage, Icons.logout_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrapIndicator(String label, String chainage, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryLight),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(chainage, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
      ],
    );
  }

  Widget _buildPigIcon(String label, String type, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold)),
        Text(type, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8)),
      ],
    );
  }

  Widget _buildSlugIndicator(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8)),
    );
  }

  Widget _buildPigRunsTableCard(PipelineHydroSection section, List<DewateringPigRun> runs) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.inventory_2_rounded, color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Pig Run Register & Weight Gain Tracking',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  ),
                  onPressed: _showAddPigRunDialog,
                  label: const Text('Add Pig Run', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.border, height: 1),
          runs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No pig runs logged yet for this section', style: TextStyle(color: AppTheme.textMuted))),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.surface),
                    dataRowColor: WidgetStateProperty.all(AppTheme.surfaceCard),
                    horizontalMargin: 16,
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('Run ID', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Pig Type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Launch/Recv', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Velocity', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Drive ΔP', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Pre/Post Wt', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Gain %', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Transmitter', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                    rows: runs.map((r) {
                      return DataRow(
                        cells: [
                          DataCell(Text(r.runId, style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 11.5))),
                          DataCell(Text(r.type.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                          DataCell(Text('${r.launchTime} - ${r.receiveTime}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5))),
                          DataCell(Text('${r.speedMps.toStringAsFixed(2)} m/s', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                          DataCell(Text('${r.drivingPressureBar.toStringAsFixed(1)} Bar', style: const TextStyle(color: AppTheme.secondary, fontSize: 11))),
                          DataCell(Text('${r.preRunWeightKg} / ${r.postRunWeightKg} kg', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                          DataCell(
                            Text(
                              '+${r.weightGainPercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: r.weightGainPercent <= 5.0 ? AppTheme.tertiary : AppTheme.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text(r.transmitterStatus, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: (r.isPassed ? AppTheme.tertiary : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                r.isPassed ? 'PASSED' : 'RE-RUN',
                                style: TextStyle(color: r.isPassed ? AppTheme.tertiary : const Color(0xFFEF4444), fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDewPointDecayCard(PipelineHydroSection section, List<DewPointLog> logs) {
    final spots = logs.map((l) => FlSpot(l.elapsedHours.toDouble(), l.outletDewPointC)).toList();

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
              Row(
                children: const [
                  Icon(Icons.grain_rounded, color: AppTheme.tertiary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Dew Point Decay vs Time (-40°C)',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (section.isDewPointCompliant ? AppTheme.tertiary : const Color(0xFFA855F7)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${section.currentDewPointC.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    color: section.isDewPointCompliant ? AppTheme.tertiary : const Color(0xFFA855F7),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 18),
          const SizedBox(height: 6),

          // Chart
          SizedBox(
            height: 220,
            child: logs.isEmpty
                ? const Center(child: Text('Drying phase not yet initiated for this section', style: TextStyle(color: AppTheme.textMuted)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 10,
                        verticalInterval: 6,
                        getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.border.withValues(alpha: 0.4), strokeWidth: 0.8),
                        getDrawingVerticalLine: (v) => FlLine(color: AppTheme.border.withValues(alpha: 0.3), strokeWidth: 0.8),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 6,
                            getTitlesWidget: (val, meta) => Text('${val.toInt()}h', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            interval: 10,
                            getTitlesWidget: (val, meta) => Text('${val.toInt()}°C', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.border)),
                      minX: 0,
                      maxX: 48,
                      minY: -50,
                      maxY: 25,
                      lineBarsData: [
                        // Target -40°C Line
                        LineChartBarData(
                          spots: const [FlSpot(0, -40.0), FlSpot(48, -40.0)],
                          isCurved: false,
                          color: AppTheme.tertiary.withValues(alpha: 0.7),
                          barWidth: 1.5,
                          dashArray: [6, 4],
                          dotData: const FlDotData(show: false),
                        ),
                        // Actual Dew Point Line
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.2,
                          color: const Color(0xFFA855F7),
                          barWidth: 2.5,
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFFA855F7).withValues(alpha: 0.08),
                          ),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 3,
                              color: const Color(0xFFA855F7),
                              strokeWidth: 1,
                              strokeColor: AppTheme.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('24-Hour Dew Point Soak Criteria', style: TextStyle(color: AppTheme.secondary, fontSize: 10.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text(
                  'Pipeline shut-in after achieving -40.0°C dew point. Dew point must remain ≤ -40.0°C for 24 continuous hours without dry air injection.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 6: TRIPARTITE CERTIFICATION & ASME B31.8 DOSSIER
  // ============================================================================

  Widget _buildCertificationTab(PipelineHydroSection section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Certificate Header & Status
          _buildOfficialCertificateHeader(section),
          const SizedBox(height: 16),

          // Tripartite Signatures Row
          _buildTripartiteSignaturesGrid(section),
          const SizedBox(height: 16),

          // Quality Inspection Checkpoints Matrix
          _buildInspectionCheckpointsCard(section),
        ],
      ),
    );
  }

  Widget _buildOfficialCertificateHeader(PipelineHydroSection section) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: section.isTripartiteSigned ? AppTheme.tertiary : AppTheme.border,
          width: section.isTripartiteSigned ? 1.5 : 1.0,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HYDROSTATIC TEST & DRYING COMPLETION CERTIFICATE',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      Text(
                        'ASME B31.8 Cl. 841.3 • OISD-141 Table 7 • Oil India Limited Trunkline Expansion',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_document, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tertiary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: _showTripartiteSignDialog,
                label: const Text('Endorse Certificate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 24),
          Row(
            children: [
              _buildCertSummaryCol('SECTION REF', '${section.sectionId.code} (${section.lengthKm} km)'),
              _buildCertSummaryCol('STRENGTH TEST', '${section.strengthTestPressureBar.toStringAsFixed(1)} Bar (4-Hr Hold)'),
              _buildCertSummaryCol('LEAK TEST', '${section.leakTestPressureBar.toStringAsFixed(1)} Bar (24-Hr Hold)'),
              _buildCertSummaryCol('AIR VOLUME', '${section.airVolumePercent.toStringAsFixed(3)}% (Pass < 0.2%)'),
              _buildCertSummaryCol('DEW POINT', '${section.currentDewPointC.toStringAsFixed(1)}°C (Pass ≤ -40°C)'),
              _buildCertSummaryCol('CERT STATUS', section.isTripartiteSigned ? 'TRIPARTITE SIGNED' : 'PENDING APPROVAL'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCertSummaryCol(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildTripartiteSignaturesGrid(PipelineHydroSection section) {
    return Row(
      children: [
        Expanded(
          child: _buildSignatureTile(
            role: 'CONTRACTOR LEAD QA/QC',
            company: 'Kalpataru Projects International',
            signatory: section.contractorSignatory,
            date: section.isTripartiteSigned ? DateFormat('dd MMM yyyy').format(section.lastUpdated) : 'Pending',
            isSigned: section.isTripartiteSigned,
            icon: Icons.engineering_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSignatureTile(
            role: 'EIL TPIA INSPECTING AUTHORITY',
            company: 'Engineers India Limited (EIL)',
            signatory: section.tpiaSignatory,
            date: section.isTripartiteSigned ? DateFormat('dd MMM yyyy').format(section.lastUpdated) : 'Pending',
            isSigned: section.isTripartiteSigned,
            icon: Icons.verified_user_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSignatureTile(
            role: 'CLIENT RESIDENT ENGINEER',
            company: 'Oil India Limited (Pipeline HQ)',
            signatory: section.clientSignatory,
            date: section.isTripartiteSigned ? DateFormat('dd MMM yyyy').format(section.lastUpdated) : 'Pending',
            isSigned: section.isTripartiteSigned,
            icon: Icons.account_balance_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureTile({
    required String role,
    required String company,
    required String signatory,
    required String date,
    required bool isSigned,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSigned ? AppTheme.tertiary.withValues(alpha: 0.6) : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: isSigned ? AppTheme.tertiary : AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(role, style: TextStyle(color: isSigned ? AppTheme.tertiary : AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(company, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(signatory, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('Signed: $date', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                  ],
                ),
                Icon(
                  isSigned ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                  color: isSigned ? AppTheme.tertiary : AppTheme.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionCheckpointsCard(PipelineHydroSection section) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: const [
                Icon(Icons.checklist_rtl_rounded, color: AppTheme.primaryLight, size: 18),
                SizedBox(width: 8),
                Text(
                  'Statutory Quality & Safety Inspection Checkpoints',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.border, height: 1),
          _buildCheckpointRow('1', 'Water Quality Compliance', 'Filtration < 50 micron, pH 7.2, biocides & O2 scavenger certified', true),
          _buildCheckpointRow('2', 'Ground Temperature Soaking', 'Minimum 24-hr stabilization with ΔT < 0.3°C / 12 hours confirmed', true),
          _buildCheckpointRow('3', 'P/V Air Volume Verification', 'Actual line to the left of 0.2% offset; air volume = ${section.airVolumePercent.toStringAsFixed(3)}% (<0.200%)', section.isAirVolumeCompliant),
          _buildCheckpointRow('4', 'Strength Test (112.5 Bar)', 'Hold for 4 hours with 0.00 Bar unexplained drop (Hoop stress 44.5% SMYS)', section.isStrengthPassed),
          _buildCheckpointRow('5', '24-Hour Leaktightness Test (90.0 Bar)', '24-hour continuous DWT + quartz gauge recording within thermal tolerance', section.isLeakPassed),
          _buildCheckpointRow('6', 'Dewatering Multi-Pig Train', 'Bi-di mechanical & batching pig sequence safely received at terminal trap', section.currentDewPointC < 20.0),
          _buildCheckpointRow('7', 'Foam Swabbing Runs', 'Final foam pig exit weight gain < 5% confirming complete free water extraction', section.currentDewPointC <= -20.0),
          _buildCheckpointRow('8', 'Air Compressor Desiccant Drying', 'Outlet pressure dew point reaches ≤ -40.0°C per ASME B31.8 §841.3', section.isDewPointCompliant),
          _buildCheckpointRow('9', 'Nitrogen Purging & Blanket', '99.5% N2 purity displacement with 0.65 Bar positive preservation blanket', section.currentPhase == SectionPhase.nitrogenPurgeBlanket || section.isTripartiteSigned),
        ],
      ),
    );
  }

  Widget _buildCheckpointRow(String num, String title, String detail, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isChecked ? AppTheme.tertiary.withValues(alpha: 0.15) : AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: isChecked ? AppTheme.tertiary : AppTheme.border),
            ),
            child: Center(
              child: Icon(
                isChecked ? Icons.check : Icons.circle,
                size: isChecked ? 13 : 5,
                color: isChecked ? AppTheme.tertiary : AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
