import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DOMAIN MODELS & ENUMS — ASME B31.8 / API RP 1111 HDD CROSSING
// ============================================================================

/// Crossing Category
enum HddCrossingType {
  riverCrossing(
    label: 'River Crossing',
    code: 'ASME B31.8 / API RP 1111',
    icon: Icons.waves_rounded,
  ),
  highwayCrossing(
    label: 'National Highway Crossing',
    code: 'IRC:112 / PNGRB T4S',
    icon: Icons.add_road_rounded,
  );

  final String label;
  final String code;
  final IconData icon;

  const HddCrossingType({
    required this.label,
    required this.code,
    required this.icon,
  });
}

/// Steering Tool Telemetry Guidance Systems
enum SteeringToolMode {
  gyro(
    title: 'North-Seeking Optical Gyroscope',
    shortName: 'Optical Gyro',
    sensorType: 'Fiber-Optic Gyro (FOG)',
    interferenceResistance: '100% Magnetic Immune',
    driftRate: '< 0.04°/hr drift',
    icon: Icons.explore_rounded,
    badgeColor: AppTheme.tertiary,
  ),
  paratrack(
    title: 'ParaTrack-2 Magnetic Guidance System',
    shortName: 'ParaTrack-2',
    sensorType: 'DC Surface Wire Loop + AC Beacon',
    interferenceResistance: 'Active AC Cancellation',
    driftRate: 'Zero Drift (Fixed Reference)',
    icon: Icons.hub_rounded,
    badgeColor: AppTheme.primaryLight,
  );

  final String title;
  final String shortName;
  final String sensorType;
  final String interferenceResistance;
  final String driftRate;
  final IconData icon;
  final Color badgeColor;

  const SteeringToolMode({
    required this.title,
    required this.shortName,
    required this.sensorType,
    required this.interferenceResistance,
    required this.driftRate,
    required this.icon,
    required this.badgeColor,
  });
}

/// Status of Reaming Passes
enum ReamingStatus {
  completed(
    label: 'Completed',
    color: AppTheme.tertiary,
    icon: Icons.check_circle_rounded,
  ),
  inProgress(
    label: 'In Progress',
    color: AppTheme.secondary,
    icon: Icons.sync_rounded,
  ),
  scheduled(
    label: 'Scheduled',
    color: AppTheme.textMuted,
    icon: Icons.schedule_rounded,
  );

  final String label;
  final Color color;
  final IconData icon;

  const ReamingStatus({
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// Survey Station Profile Data Point
class HddStationSurvey {
  final double measuredDepthM;
  final double trueVerticalDepthM;
  final double pitchAngleDeg;
  final double azimuthDeg;
  final double toolFaceRollDeg;
  final double doglegSeverityDegPer30m;
  final double mudPressureBar;
  final double depthBelowScourM;
  final String formationStrata;
  final String remarks;

  const HddStationSurvey({
    required this.measuredDepthM,
    required this.trueVerticalDepthM,
    required this.pitchAngleDeg,
    required this.azimuthDeg,
    required this.toolFaceRollDeg,
    required this.doglegSeverityDegPer30m,
    required this.mudPressureBar,
    required this.depthBelowScourM,
    required this.formationStrata,
    this.remarks = '',
  });

  bool get isScourSafe => depthBelowScourM >= 6.0;
  bool get isDoglegSafe => doglegSeverityDegPer30m <= 3.0;
}

/// Barrel Reaming Pass Model
class ReamingPassData {
  final int diameterInches;
  final String passTitle;
  final int passNumber;
  final ReamingStatus status;
  final double progressRatio; // 0.0 to 1.0
  final double rotaryTorqueKnm; // live / observed torque
  final double maxTorqueLimitKnm; // target limit 65 kN-m
  final double mudPumpPressureBar; // operating range 70-95 bar, limit 120 bar
  final double maxMudPressureLimitBar;
  final double bentoniteSlurryFlowRateM3h; // target 180-240 m³/hr
  final double rotationSpeedRpm;
  final double penetrationRateMh;
  final double marshFunnelViscositySec;
  final double slurrySpecificGravity;
  final double sandContentPct;
  final double cuttingsReturnsPct;
  final String reamerDescription;
  final String notes;

  const ReamingPassData({
    required this.diameterInches,
    required this.passTitle,
    required this.passNumber,
    required this.status,
    required this.progressRatio,
    required this.rotaryTorqueKnm,
    this.maxTorqueLimitKnm = 65.0,
    required this.mudPumpPressureBar,
    this.maxMudPressureLimitBar = 120.0,
    required this.bentoniteSlurryFlowRateM3h,
    required this.rotationSpeedRpm,
    required this.penetrationRateMh,
    required this.marshFunnelViscositySec,
    required this.slurrySpecificGravity,
    required this.sandContentPct,
    required this.cuttingsReturnsPct,
    required this.reamerDescription,
    this.notes = '',
  });

  bool get isTorqueSafe => rotaryTorqueKnm <= maxTorqueLimitKnm;
  bool get isPressureSafe => mudPumpPressureBar <= maxMudPressureLimitBar;
  bool get isFlowRateInTarget =>
      bentoniteSlurryFlowRateM3h >= 180.0 && bentoniteSlurryFlowRateM3h <= 240.0;
}

/// Buoyancy Control Water Filling Stage
class BuoyancyStageData {
  final int stageNumber;
  final String stageTitle;
  final String chainageSpan;
  final double targetWaterM3;
  final double pumpedWaterM3;
  final double waterFillingRateM3h;
  final double netSubmergedWeightKgM;
  final bool isCompleted;
  final bool isActive;
  final String operationalGuidelines;

  const BuoyancyStageData({
    required this.stageNumber,
    required this.stageTitle,
    required this.chainageSpan,
    required this.targetWaterM3,
    required this.pumpedWaterM3,
    required this.waterFillingRateM3h,
    required this.netSubmergedWeightKgM,
    required this.isCompleted,
    required this.isActive,
    required this.operationalGuidelines,
  });

  double get progressRatio =>
      targetWaterM3 > 0 ? (pumpedWaterM3 / targetWaterM3).clamp(0.0, 1.0) : 0.0;
}

/// Major HDD Crossing Profile Specification
class HddCrossingSite {
  final String id;
  final String name;
  final String subtitle;
  final HddCrossingType crossingType;
  final double profileLengthM;
  final int pipeDiameterInches;
  final double pipeOuterDiameterMm;
  final double wallThicknessMm;
  final String pipeGrade;
  final double smysMpa;
  final String chainage;
  final String geographicLocation;
  final double scourBedDepthM; // Scour depth below riverbed
  final double statutoryMinClearanceM; // 6.0 m requirement
  final double actualDepthBelowScourM; // Depth below scour line
  final double totalTvdBelowSurfaceM;
  final double entryAngleDeg; // 8° to 12°
  final double exitAngleDeg; // 5° to 8°
  final double entryAngleMinDeg;
  final double entryAngleMaxDeg;
  final double exitAngleMinDeg;
  final double exitAngleMaxDeg;
  final double minRadiusOfCurvatureM; // 1200 * D
  final double designRadiusOfCurvatureM;
  final double maxRigCapacityTonnes; // 350 Tonnes
  final double targetPullTensionTonnes; // < 180 Tonnes
  final double pipeYieldTensionTonnes; // 70% SMYS
  final String activePhaseTitle;
  final double activeProgressRatio;
  final List<HddStationSurvey> surveyStations;
  final List<ReamingPassData> reamingPasses;
  final List<BuoyancyStageData> buoyancyStages;

  const HddCrossingSite({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.crossingType,
    required this.profileLengthM,
    required this.pipeDiameterInches,
    required this.pipeOuterDiameterMm,
    required this.wallThicknessMm,
    required this.pipeGrade,
    required this.smysMpa,
    required this.chainage,
    required this.geographicLocation,
    required this.scourBedDepthM,
    this.statutoryMinClearanceM = 6.0,
    required this.actualDepthBelowScourM,
    required this.totalTvdBelowSurfaceM,
    required this.entryAngleDeg,
    required this.exitAngleDeg,
    this.entryAngleMinDeg = 8.0,
    this.entryAngleMaxDeg = 12.0,
    this.exitAngleMinDeg = 5.0,
    this.exitAngleMaxDeg = 8.0,
    required this.minRadiusOfCurvatureM,
    required this.designRadiusOfCurvatureM,
    this.maxRigCapacityTonnes = 350.0,
    this.targetPullTensionTonnes = 180.0,
    required this.pipeYieldTensionTonnes,
    required this.activePhaseTitle,
    required this.activeProgressRatio,
    required this.surveyStations,
    required this.reamingPasses,
    required this.buoyancyStages,
  });

  bool get isEntryAngleCompliant =>
      entryAngleDeg >= entryAngleMinDeg && entryAngleDeg <= entryAngleMaxDeg;

  bool get isExitAngleCompliant =>
      exitAngleDeg >= exitAngleMinDeg && exitAngleDeg <= exitAngleMaxDeg;

  bool get isScourClearanceCompliant =>
      actualDepthBelowScourM >= statutoryMinClearanceM;

  double get scourMarginAboveStatutoryM =>
      actualDepthBelowScourM - statutoryMinClearanceM;
}

// ============================================================================
// REPOSITORY / DATA PROVIDER WITH MAJOR CROSSINGS
// ============================================================================

class HddCrossingRepository {
  static const List<HddCrossingSite> majorCrossings = [
    // 1. Burhi Dihing River (1,250 m profile)
    HddCrossingSite(
      id: 'burhi_dihing',
      name: 'Burhi Dihing River Crossing',
      subtitle: 'Upper Assam Crude & Natural Gas Trunk Pipeline • Ch. 42+150',
      crossingType: HddCrossingType.riverCrossing,
      profileLengthM: 1250.0,
      pipeDiameterInches: 24,
      pipeOuterDiameterMm: 610.0,
      wallThicknessMm: 15.9,
      pipeGrade: 'API 5L X70 PSL2',
      smysMpa: 485.0,
      chainage: 'Ch. 42+150 to Ch. 43+400',
      geographicLocation: 'Khowang Ghat, Dibrugarh District, Assam',
      scourBedDepthM: 8.4,
      statutoryMinClearanceM: 6.0,
      actualDepthBelowScourM: 18.5,
      totalTvdBelowSurfaceM: 26.9,
      entryAngleDeg: 10.5,
      exitAngleDeg: 6.8,
      minRadiusOfCurvatureM: 732.0, // 1200 * 0.61m
      designRadiusOfCurvatureM: 980.0,
      maxRigCapacityTonnes: 350.0,
      targetPullTensionTonnes: 180.0,
      pipeYieldTensionTonnes: 265.0,
      activePhaseTitle: 'Pipe Pullback Telemetry (Stage 3 Active)',
      activeProgressRatio: 0.684, // 855 m / 1250 m
      surveyStations: [
        HddStationSurvey(
          measuredDepthM: 0.0,
          trueVerticalDepthM: 0.0,
          pitchAngleDeg: -10.5,
          azimuthDeg: 165.2,
          toolFaceRollDeg: 0.0,
          doglegSeverityDegPer30m: 0.0,
          mudPressureBar: 18.0,
          depthBelowScourM: 0.0,
          formationStrata: 'Alluvial Topsoil & Humic Silt',
          remarks: 'North Bank Rig entry punch (Entry Angle: 10.5°)',
        ),
        HddStationSurvey(
          measuredDepthM: 180.0,
          trueVerticalDepthM: 16.8,
          pitchAngleDeg: -7.8,
          azimuthDeg: 165.0,
          toolFaceRollDeg: 12.0,
          doglegSeverityDegPer30m: 1.8,
          mudPressureBar: 28.5,
          depthBelowScourM: 8.4,
          formationStrata: 'Soft High Plasticity Clay (CH)',
          remarks: 'Entry overbend transition curvature compliant',
        ),
        HddStationSurvey(
          measuredDepthM: 420.0,
          trueVerticalDepthM: 25.4,
          pitchAngleDeg: -2.1,
          azimuthDeg: 164.8,
          toolFaceRollDeg: 5.0,
          doglegSeverityDegPer30m: 1.4,
          mudPressureBar: 42.0,
          depthBelowScourM: 17.0,
          formationStrata: 'Fine to Medium River Sand',
          remarks: 'Entering 100-yr flood thalweg corridor',
        ),
        HddStationSurvey(
          measuredDepthM: 650.0,
          trueVerticalDepthM: 26.9,
          pitchAngleDeg: 0.0,
          azimuthDeg: 165.0,
          toolFaceRollDeg: 0.0,
          doglegSeverityDegPer30m: 0.8,
          mudPressureBar: 46.5,
          depthBelowScourM: 18.5,
          formationStrata: 'Dense Coarse Sand & Gravel Bed',
          remarks: 'Max depth beneath river thalweg (18.5 m below scour)',
        ),
        HddStationSurvey(
          measuredDepthM: 920.0,
          trueVerticalDepthM: 24.1,
          pitchAngleDeg: 3.2,
          azimuthDeg: 165.1,
          toolFaceRollDeg: 355.0,
          doglegSeverityDegPer30m: 1.2,
          mudPressureBar: 39.0,
          depthBelowScourM: 15.7,
          formationStrata: 'Micaceous Silty Sand',
          remarks: 'Exit build-up curve initiation',
        ),
        HddStationSurvey(
          measuredDepthM: 1120.0,
          trueVerticalDepthM: 12.5,
          pitchAngleDeg: 5.6,
          azimuthDeg: 165.0,
          toolFaceRollDeg: 18.0,
          doglegSeverityDegPer30m: 1.6,
          mudPressureBar: 26.0,
          depthBelowScourM: 12.5,
          formationStrata: 'Stiff Alluvial Clay',
          remarks: 'South Bank approach beneath flood levee',
        ),
        HddStationSurvey(
          measuredDepthM: 1250.0,
          trueVerticalDepthM: 0.0,
          pitchAngleDeg: 6.8,
          azimuthDeg: 165.0,
          toolFaceRollDeg: 0.0,
          doglegSeverityDegPer30m: 0.0,
          mudPressureBar: 12.0,
          depthBelowScourM: 0.0,
          formationStrata: 'South Bank Punchout Pad',
          remarks: 'South Bank exit breakout (Exit Angle: 6.8°)',
        ),
      ],
      reamingPasses: [
        ReamingPassData(
          diameterInches: 16,
          passTitle: '16" Barrel Reamer Pass (Pass 1)',
          passNumber: 1,
          status: ReamingStatus.completed,
          progressRatio: 1.0,
          rotaryTorqueKnm: 22.4,
          mudPumpPressureBar: 62.0,
          bentoniteSlurryFlowRateM3h: 185.0,
          rotationSpeedRpm: 56.0,
          penetrationRateMh: 21.0,
          marshFunnelViscositySec: 68.0,
          slurrySpecificGravity: 1.14,
          sandContentPct: 0.25,
          cuttingsReturnsPct: 99.2,
          reamerDescription:
              '16" Fluted Barrel Body with Tungsten Carbide Inserts (TCI) • 6 Jet Nozzles',
          notes: 'Full circulation returns to North Entry Pit; zero fluid loss.',
        ),
        ReamingPassData(
          diameterInches: 26,
          passTitle: '26" Barrel Reamer Pass (Pass 2)',
          passNumber: 2,
          status: ReamingStatus.completed,
          progressRatio: 1.0,
          rotaryTorqueKnm: 36.8,
          mudPumpPressureBar: 76.5,
          bentoniteSlurryFlowRateM3h: 205.0,
          rotationSpeedRpm: 46.0,
          penetrationRateMh: 15.5,
          marshFunnelViscositySec: 72.0,
          slurrySpecificGravity: 1.15,
          sandContentPct: 0.32,
          cuttingsReturnsPct: 98.4,
          reamerDescription:
              '26" Heavy Barrel Reamer with Spiral Stabilizer Flutes • 8 Jet Nozzles',
          notes:
              'Steady torque profile across sand-gravel strata. Swivel temp 38°C.',
        ),
        ReamingPassData(
          diameterInches: 36,
          passTitle: '36" Barrel Reamer Pass (Pass 3)',
          passNumber: 3,
          status: ReamingStatus.completed,
          progressRatio: 1.0,
          rotaryTorqueKnm: 49.2,
          mudPumpPressureBar: 88.0,
          bentoniteSlurryFlowRateM3h: 225.0,
          rotationSpeedRpm: 38.0,
          penetrationRateMh: 11.2,
          marshFunnelViscositySec: 78.0,
          slurrySpecificGravity: 1.16,
          sandContentPct: 0.40,
          cuttingsReturnsPct: 97.6,
          reamerDescription:
              '36" Hole Opener Barrel Hybrid with Chisel Cutters • 10 Jet Nozzles',
          notes:
              'Torque peaked at 54 kN-m in gravel lens (well below 65 kN-m limit).',
        ),
        ReamingPassData(
          diameterInches: 48,
          passTitle: '48" Final Barrel Reamer Pass (Pass 4)',
          passNumber: 4,
          status: ReamingStatus.completed,
          progressRatio: 1.0,
          rotaryTorqueKnm: 57.5,
          mudPumpPressureBar: 94.0,
          bentoniteSlurryFlowRateM3h: 238.0,
          rotationSpeedRpm: 30.0,
          penetrationRateMh: 8.4,
          marshFunnelViscositySec: 82.0,
          slurrySpecificGravity: 1.17,
          sandContentPct: 0.45,
          cuttingsReturnsPct: 96.8,
          reamerDescription:
              '48" Heavy-Duty Barrel Reamer (1.5x Pipe OD) • 12 Multi-Port Jet Nozzles',
          notes:
              'Final conditioning & swab run complete. Hole clean & ready for pullback.',
        ),
      ],
      buoyancyStages: [
        BuoyancyStageData(
          stageNumber: 1,
          stageTitle: 'Stage 1: North Entry Sag & Overbend',
          chainageSpan: '0 m to 300 m',
          targetWaterM3: 28.0,
          pumpedWaterM3: 28.0,
          waterFillingRateM3h: 30.0,
          netSubmergedWeightKgM: -12.5,
          isCompleted: true,
          isActive: false,
          operationalGuidelines:
              'Ballast water injected via internal 3" poly line to counter positive pipe uplift.',
        ),
        BuoyancyStageData(
          stageNumber: 2,
          stageTitle: 'Stage 2: Downslope Riverbed Descent',
          chainageSpan: '300 m to 600 m',
          targetWaterM3: 46.0,
          pumpedWaterM3: 46.0,
          waterFillingRateM3h: 34.0,
          netSubmergedWeightKgM: -14.2,
          isCompleted: true,
          isActive: false,
          operationalGuidelines:
              'Maintains near-neutral negative buoyancy (-14.2 kg/m) avoiding crown friction.',
        ),
        BuoyancyStageData(
          stageNumber: 3,
          stageTitle: 'Stage 3: Riverbed Thalweg Horizontal Pull',
          chainageSpan: '600 m to 950 m',
          targetWaterM3: 44.0,
          pumpedWaterM3: 34.5,
          waterFillingRateM3h: 32.5,
          netSubmergedWeightKgM: -14.8,
          isCompleted: false,
          isActive: true,
          operationalGuidelines:
              'Active filling in progress. Rig pull load stable at 142.5 tonnes (Target < 180t).',
        ),
        BuoyancyStageData(
          stageNumber: 4,
          stageTitle: 'Stage 4: Upslope Exit Punch & Final Seat',
          chainageSpan: '950 m to 1250 m',
          targetWaterM3: 34.0,
          pumpedWaterM3: 0.0,
          waterFillingRateM3h: 28.0,
          netSubmergedWeightKgM: -13.0,
          isCompleted: false,
          isActive: false,
          operationalGuidelines:
              'Ballast drainage sequencing scheduled once pullhead surfaces at North entry pit.',
        ),
      ],
    ),

    // 2. Disang River (890 m profile)
    HddCrossingSite(
      id: 'disang_river',
      name: 'Disang River Crossing',
      subtitle: 'Upper Assam Spur Feeder Pipeline • Ch. 78+220',
      crossingType: HddCrossingType.riverCrossing,
      profileLengthM: 890.0,
      pipeDiameterInches: 18,
      pipeOuterDiameterMm: 457.0,
      wallThicknessMm: 12.7,
      pipeGrade: 'API 5L X65 PSL2',
      smysMpa: 450.0,
      chainage: 'Ch. 78+220 to Ch. 79+110',
      geographicLocation: 'Dikhumukh Corridor, Sivasagar District, Assam',
      scourBedDepthM: 6.2,
      statutoryMinClearanceM: 6.0,
      actualDepthBelowScourM: 14.2,
      totalTvdBelowSurfaceM: 20.4,
      entryAngleDeg: 9.2,
      exitAngleDeg: 6.0,
      minRadiusOfCurvatureM: 548.4, // 1200 * 0.457m
      designRadiusOfCurvatureM: 780.0,
      maxRigCapacityTonnes: 350.0,
      targetPullTensionTonnes: 180.0,
      pipeYieldTensionTonnes: 195.0,
      activePhaseTitle: '36" Intermediate Reaming Pass (Pass 3 Active)',
      activeProgressRatio: 0.45,
      surveyStations: [
        HddStationSurvey(
          measuredDepthM: 0.0,
          trueVerticalDepthM: 0.0,
          pitchAngleDeg: -9.2,
          azimuthDeg: 210.4,
          toolFaceRollDeg: 0.0,
          doglegSeverityDegPer30m: 0.0,
          mudPressureBar: 15.0,
          depthBelowScourM: 0.0,
          formationStrata: 'Floodplain Alluvium & Silty Clay',
          remarks: 'East Bank drill rig entry (Entry Angle: 9.2°)',
        ),
        HddStationSurvey(
          measuredDepthM: 240.0,
          trueVerticalDepthM: 14.2,
          pitchAngleDeg: -4.5,
          azimuthDeg: 210.2,
          toolFaceRollDeg: 14.0,
          doglegSeverityDegPer30m: 1.5,
          mudPressureBar: 32.0,
          depthBelowScourM: 8.0,
          formationStrata: 'Medium Plasticity Silt & Clay',
          remarks: 'Scour safety threshold crossed safely',
        ),
        HddStationSurvey(
          measuredDepthM: 460.0,
          trueVerticalDepthM: 20.4,
          pitchAngleDeg: 0.0,
          azimuthDeg: 210.0,
          toolFaceRollDeg: 0.0,
          doglegSeverityDegPer30m: 0.9,
          mudPressureBar: 41.5,
          depthBelowScourM: 14.2,
          formationStrata: 'Thalweg Coarse Sand Bed',
          remarks: 'Maximum profile depth (14.2 m below 100-yr scour line)',
        ),
        HddStationSurvey(
          measuredDepthM: 710.0,
          trueVerticalDepthM: 12.8,
          pitchAngleDeg: 3.8,
          azimuthDeg: 210.1,
          toolFaceRollDeg: 350.0,
          doglegSeverityDegPer30m: 1.3,
          mudPressureBar: 28.0,
          depthBelowScourM: 10.6,
          formationStrata: 'Dense Sand & Silt Laminations',
          remarks: 'Ascending smoothly towards West Bank',
        ),
        HddStationSurvey(
          measuredDepthM: 890.0,
          trueVerticalDepthM: 0.0,
          pitchAngleDeg: 6.0,
          azimuthDeg: 210.0,
          toolFaceRollDeg: 0.0,
          doglegSeverityDegPer30m: 0.0,
          mudPressureBar: 10.0,
          depthBelowScourM: 0.0,
          formationStrata: 'West Bank Receiving Pit',
          remarks: 'Pilot hole punched out exactly on target (Exit: 6.0°)',
        ),
      ],
      reamingPasses: [
        ReamingPassData(
          diameterInches: 16,
          passTitle: '16" Barrel Reamer Pass (Pass 1)',
          passNumber: 1,
          status: ReamingStatus.completed,
          progressRatio: 1.0,
          rotaryTorqueKnm: 20.5,
          mudPumpPressureBar: 58.0,
          bentoniteSlurryFlowRateM3h: 175.0,
          rotationSpeedRpm: 58.0,
          penetrationRateMh: 24.5,
          marshFunnelViscositySec: 66.0,
          slurrySpecificGravity: 1.13,
          sandContentPct: 0.22,
          cuttingsReturnsPct: 99.4,
          reamerDescription:
              '16" Fluted Barrel Reamer • 6 Tungsten Carbide Nozzles',
          notes: 'Completed in single 18-hour continuous shift.',
        ),
        ReamingPassData(
          diameterInches: 26,
          passTitle: '26" Barrel Reamer Pass (Pass 2)',
          passNumber: 2,
          status: ReamingStatus.completed,
          progressRatio: 1.0,
          rotaryTorqueKnm: 34.0,
          mudPumpPressureBar: 74.0,
          bentoniteSlurryFlowRateM3h: 195.0,
          rotationSpeedRpm: 48.0,
          penetrationRateMh: 16.2,
          marshFunnelViscositySec: 70.0,
          slurrySpecificGravity: 1.14,
          sandContentPct: 0.28,
          cuttingsReturnsPct: 98.7,
          reamerDescription:
              '26" Barrel Reamer with Spiral Cuttings Grooves • 8 Jet Nozzles',
          notes: 'Uniform torque, excellent bentonite rheology.',
        ),
        ReamingPassData(
          diameterInches: 36,
          passTitle: '36" Final Barrel Reamer Pass (Pass 3)',
          passNumber: 3,
          status: ReamingStatus.inProgress,
          progressRatio: 0.45,
          rotaryTorqueKnm: 44.5,
          mudPumpPressureBar: 84.0,
          bentoniteSlurryFlowRateM3h: 215.0,
          rotationSpeedRpm: 40.0,
          penetrationRateMh: 12.0,
          marshFunnelViscositySec: 76.0,
          slurrySpecificGravity: 1.16,
          sandContentPct: 0.35,
          cuttingsReturnsPct: 98.0,
          reamerDescription:
              '36" Hole Opener Barrel Hybrid (2x Pipe OD) • 10 High-Velocity Jets',
          notes:
              'Currently at MD 400.5 m. Slurry flow 215 m³/hr within target.',
        ),
      ],
      buoyancyStages: [
        BuoyancyStageData(
          stageNumber: 1,
          stageTitle: 'Stage 1: East Entry Overbend',
          chainageSpan: '0 m to 250 m',
          targetWaterM3: 16.0,
          pumpedWaterM3: 0.0,
          waterFillingRateM3h: 25.0,
          netSubmergedWeightKgM: -10.5,
          isCompleted: false,
          isActive: false,
          operationalGuidelines:
              'Scheduled for execution following swab run and hole caliper verification.',
        ),
        BuoyancyStageData(
          stageNumber: 2,
          stageTitle: 'Stage 2: Channel Submerged Run',
          chainageSpan: '250 m to 650 m',
          targetWaterM3: 28.0,
          pumpedWaterM3: 0.0,
          waterFillingRateM3h: 28.0,
          netSubmergedWeightKgM: -13.2,
          isCompleted: false,
          isActive: false,
          operationalGuidelines:
              'Water ballast manifold primed at West Bank pipe string layout area.',
        ),
      ],
    ),

    // 3. NH-37 Highway Crossing (180 m profile)
    HddCrossingSite(
      id: 'nh37_crossing',
      name: 'NH-37 Highway Crossing',
      subtitle: 'National Highway Four-Lane Heavy Crossing • Ch. 12+450',
      crossingType: HddCrossingType.highwayCrossing,
      profileLengthM: 180.0,
      pipeDiameterInches: 30,
      pipeOuterDiameterMm: 762.0,
      wallThicknessMm: 19.1,
      pipeGrade: 'API 5L X70 Heavy Wall',
      smysMpa: 485.0,
      chainage: 'Ch. 12+450 to Ch. 12+630',
      geographicLocation: 'Jorhat Bypass Embankment, Assam',
      scourBedDepthM: 2.2, // Road pavement subgrade depth
      statutoryMinClearanceM: 6.0, // Statutory clearance below pavement
      actualDepthBelowScourM: 6.6, // Clearance below subgrade
      totalTvdBelowSurfaceM: 8.8,
      entryAngleDeg: 8.5,
      exitAngleDeg: 5.5,
      minRadiusOfCurvatureM: 914.4, // 1200 * 0.762m
      designRadiusOfCurvatureM: 1100.0,
      maxRigCapacityTonnes: 350.0,
      targetPullTensionTonnes: 180.0,
      pipeYieldTensionTonnes: 340.0,
      activePhaseTitle: '26" Reamer Pass Setup (Pass 2 Scheduled)',
      activeProgressRatio: 0.22,
      surveyStations: [
        HddStationSurvey(
          measuredDepthM: 0.0,
          trueVerticalDepthM: 0.0,
          pitchAngleDeg: -8.5,
          azimuthDeg: 95.0,
          toolFaceRollDeg: 0.0,
          doglegSeverityDegPer30m: 0.0,
          mudPressureBar: 12.0,
          depthBelowScourM: 0.0,
          formationStrata: 'Road Embankment Compacted Fill',
          remarks: 'North RoW rig setup (Entry Angle: 8.5°)',
        ),
        HddStationSurvey(
          measuredDepthM: 60.0,
          trueVerticalDepthM: 6.4,
          pitchAngleDeg: -3.8,
          azimuthDeg: 95.0,
          toolFaceRollDeg: 8.0,
          doglegSeverityDegPer30m: 1.2,
          mudPressureBar: 22.0,
          depthBelowScourM: 4.2,
          formationStrata: 'Dense Sandy Silt Subgrade',
          remarks: 'Beneath highway northern service road',
        ),
        HddStationSurvey(
          measuredDepthM: 100.0,
          trueVerticalDepthM: 8.8,
          pitchAngleDeg: 0.0,
          azimuthDeg: 95.0,
          toolFaceRollDeg: 0.0,
          doglegSeverityDegPer30m: 0.8,
          mudPressureBar: 26.5,
          depthBelowScourM: 6.6,
          formationStrata: 'Coarse Sand Layer',
          remarks:
              'Crossing highway median; 6.6 m depth below culvert/subgrade (>6m statutory)',
        ),
        HddStationSurvey(
          measuredDepthM: 140.0,
          trueVerticalDepthM: 6.2,
          pitchAngleDeg: 3.5,
          azimuthDeg: 95.0,
          toolFaceRollDeg: 352.0,
          doglegSeverityDegPer30m: 1.1,
          mudPressureBar: 20.0,
          depthBelowScourM: 4.0,
          formationStrata: 'Compacted Embankment Toe',
          remarks: 'Southbound highway shoulder clear',
        ),
        HddStationSurvey(
          measuredDepthM: 180.0,
          trueVerticalDepthM: 0.0,
          pitchAngleDeg: 5.5,
          azimuthDeg: 95.0,
          toolFaceRollDeg: 0.0,
          doglegSeverityDegPer30m: 0.0,
          mudPressureBar: 10.0,
          depthBelowScourM: 0.0,
          formationStrata: 'South RoW Reception Trench',
          remarks: 'Target punchout successful (Exit Angle: 5.5°)',
        ),
      ],
      reamingPasses: [
        ReamingPassData(
          diameterInches: 16,
          passTitle: '16" Pilot Enlargement (Pass 1)',
          passNumber: 1,
          status: ReamingStatus.completed,
          progressRatio: 1.0,
          rotaryTorqueKnm: 18.2,
          mudPumpPressureBar: 48.0,
          bentoniteSlurryFlowRateM3h: 160.0,
          rotationSpeedRpm: 60.0,
          penetrationRateMh: 28.0,
          marshFunnelViscositySec: 62.0,
          slurrySpecificGravity: 1.12,
          sandContentPct: 0.18,
          cuttingsReturnsPct: 99.6,
          reamerDescription:
              '16" Fluted Reamer with Carbide Cutters for Compacted Fill',
          notes:
              'Ground settlement monitors along NH-37 recorded 0.0 mm heave.',
        ),
        ReamingPassData(
          diameterInches: 26,
          passTitle: '26" Intermediate Reamer Pass (Pass 2)',
          passNumber: 2,
          status: ReamingStatus.scheduled,
          progressRatio: 0.0,
          rotaryTorqueKnm: 0.0,
          mudPumpPressureBar: 0.0,
          bentoniteSlurryFlowRateM3h: 190.0,
          rotationSpeedRpm: 45.0,
          penetrationRateMh: 18.0,
          marshFunnelViscositySec: 68.0,
          slurrySpecificGravity: 1.14,
          sandContentPct: 0.25,
          cuttingsReturnsPct: 100.0,
          reamerDescription:
              '26" Barrel Reamer with Centralizer Sleeves & Anti-Fracture Ports',
          notes:
              'NHAI Highway Authority clearance active. Rig positioned for Pass 2.',
        ),
      ],
      buoyancyStages: [
        BuoyancyStageData(
          stageNumber: 1,
          stageTitle: 'Highway Straight Pull Ballast',
          chainageSpan: '0 m to 180 m',
          targetWaterM3: 14.5,
          pumpedWaterM3: 0.0,
          waterFillingRateM3h: 20.0,
          netSubmergedWeightKgM: -18.0,
          isCompleted: false,
          isActive: false,
          operationalGuidelines:
              'Short crossing pull: ballast water reduces highway embankment thrust.',
        ),
      ],
    ),
  ];
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

/// Horizontal Directional Drilling (HDD) River & Highway Crossing Screen
/// ASME B31.8 / API RP 1111 Trenchless Engineering Telemetry Platform
class HddCrossingScreen extends StatefulWidget {
  const HddCrossingScreen({super.key});

  @override
  State<HddCrossingScreen> createState() => _HddCrossingScreenState();
}

class _HddCrossingScreenState extends State<HddCrossingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Selected Major Crossing Site
  late HddCrossingSite _activeSite;

  // Steering Guidance Mode (Gyro vs ParaTrack-2)
  SteeringToolMode _steeringToolMode = SteeringToolMode.gyro;

  // Interactive Longitudinal Canvas Scrubber Position (m)
  double _scrubMeasuredDepthM = 650.0;

  // Pullback Telemetry Live Parameters
  double _pullTensionTonnes = 142.5;
  double _loadCellATonnes = 71.3;
  double _loadCellBTonnes = 71.2;
  final double _thrusterPushTonnes = 38.0;
  double _pumpedWaterVolumeM3 = 108.5;
  final double _waterFillingRateM3h = 32.5;
  double _netBuoyancyWeightKgM = -14.2;

  // Live Telemetry Simulation Timer
  bool _isLiveTelemetryActive = false;
  Timer? _liveTelemetryTimer;
  double _liveTickCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    _activeSite = HddCrossingRepository.majorCrossings.first;
    _scrubMeasuredDepthM = _activeSite.profileLengthM * 0.52;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _liveTelemetryTimer?.cancel();
    super.dispose();
  }

  void _onSelectSite(HddCrossingSite site) {
    setState(() {
      _activeSite = site;
      _scrubMeasuredDepthM = site.profileLengthM * 0.52;
      // Reset pullback defaults for the selected crossing
      if (site.id == 'burhi_dihing') {
        _pullTensionTonnes = 142.5;
        _loadCellATonnes = 71.3;
        _loadCellBTonnes = 71.2;
        _pumpedWaterVolumeM3 = 108.5;
        _netBuoyancyWeightKgM = -14.2;
      } else if (site.id == 'disang_river') {
        _pullTensionTonnes = 98.0;
        _loadCellATonnes = 49.0;
        _loadCellBTonnes = 49.0;
        _pumpedWaterVolumeM3 = 42.0;
        _netBuoyancyWeightKgM = -12.8;
      } else {
        _pullTensionTonnes = 52.0;
        _loadCellATonnes = 26.0;
        _loadCellBTonnes = 26.0;
        _pumpedWaterVolumeM3 = 8.5;
        _netBuoyancyWeightKgM = -16.5;
      }
    });
  }

  void _toggleLiveTelemetry() {
    setState(() {
      _isLiveTelemetryActive = !_isLiveTelemetryActive;
    });

    if (_isLiveTelemetryActive) {
      _liveTelemetryTimer =
          Timer.periodic(const Duration(milliseconds: 900), (timer) {
        if (!mounted) return;
        setState(() {
          _liveTickCount++;
          // Small realistic telemetry fluctuations
          final jitter = math.sin(_liveTickCount * 0.5) * 1.8;
          _pullTensionTonnes = (_pullTensionTonnes + jitter * 0.6)
              .clamp(120.0, _activeSite.targetPullTensionTonnes + 15.0);
          _loadCellATonnes = _pullTensionTonnes * 0.501;
          _loadCellBTonnes = _pullTensionTonnes - _loadCellATonnes;

          // Water ballast simulation
          if (_pumpedWaterVolumeM3 < 152.0) {
            _pumpedWaterVolumeM3 += 0.08;
            _netBuoyancyWeightKgM = -14.2 + math.sin(_liveTickCount * 0.3) * 0.3;
          }
        });
      });
    } else {
      _liveTelemetryTimer?.cancel();
    }
  }

  void _simulateWaterInjection() {
    setState(() {
      _pumpedWaterVolumeM3 = (_pumpedWaterVolumeM3 + 5.0).clamp(0.0, 160.0);
      _netBuoyancyWeightKgM = -14.2 - (_pumpedWaterVolumeM3 * 0.02);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.primaryLight, width: 1.2),
          borderRadius: BorderRadius.circular(10),
        ),
        content: Row(
          children: [
            const Icon(Icons.water_drop_rounded,
                color: AppTheme.primaryLight, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ballast water injected: +5.0 m³ • Net submerged weight: ${_netBuoyancyWeightKgM.toStringAsFixed(1)} kg/m',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComplianceCertificateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ComplianceCertificateSheet(site: _activeSite),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Major Crossing Selector Header
          _buildCrossingSelectorHeader(),

          // Active Profile Summary Bar
          _buildProfileKpiSummaryBar(),

          // 4-Tab Navigation Bar
          _buildTabBar(),

          // Tab Body Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSteeringProfileTab(),
                _buildReamingPassesTab(),
                _buildPullbackBuoyancyTab(),
                _buildAsmeAuditTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // APP BAR
  // ==========================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
        onPressed: () => Navigator.of(context).maybePop(),
        tooltip: 'Back',
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'HDD Crossing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.primaryLight.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'API RP 1111',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryLight,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const Text(
            'ASME B31.8 Ch. VIII • Telemetry Rig',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        // Live Simulation Toggle Button
        IconButton(
          tooltip: _isLiveTelemetryActive
              ? 'Pause Telemetry Stream'
              : 'Start Live Telemetry Stream',
          icon: Icon(
            _isLiveTelemetryActive
                ? Icons.pause_circle_filled_rounded
                : Icons.play_circle_fill_rounded,
            color: _isLiveTelemetryActive
                ? AppTheme.secondary
                : AppTheme.textSecondary,
          ),
          onPressed: _toggleLiveTelemetry,
        ),
        // ASME Compliance Certification Button
        IconButton(
          tooltip: 'ASME B31.8 QA Certificate',
          icon: const Icon(
            Icons.verified_user_rounded,
            color: AppTheme.tertiary,
          ),
          onPressed: _showComplianceCertificateDialog,
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ==========================================================================
  // CROSSING SELECTOR HEADER
  // ==========================================================================

  Widget _buildCrossingSelectorHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MAJOR TRENCHLESS CROSSINGS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isLiveTelemetryActive
                          ? AppTheme.secondary
                          : AppTheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isLiveTelemetryActive ? 'LIVE RIG SYNC' : 'TELEMETRY ONLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _isLiveTelemetryActive
                          ? AppTheme.secondary
                          : AppTheme.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HddCrossingRepository.majorCrossings.map((site) {
                final isSelected = site.id == _activeSite.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onSelectSite(site),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.22)
                              : AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryLight
                                : AppTheme.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              site.crossingType.icon,
                              size: 16,
                              color: isSelected
                                  ? AppTheme.primaryLight
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  site.name,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${site.profileLengthM.toInt()} m • ${site.pipeDiameterInches}" Pipe',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? AppTheme.primaryLight
                                        : AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: AppTheme.primaryLight,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // PROFILE KPI SUMMARY BAR
  // ==========================================================================

  Widget _buildProfileKpiSummaryBar() {
    final site = _activeSite;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildKpiPill(
            label: 'SCOUR CLEARANCE',
            value: '${site.actualDepthBelowScourM.toStringAsFixed(1)} m',
            subtext: 'Req: > 6.0 m',
            isSuccess: site.isScourClearanceCompliant,
            icon: Icons.shield_rounded,
          ),
          _buildKpiPill(
            label: 'ENTRY ANGLE',
            value: '${site.entryAngleDeg.toStringAsFixed(1)}°',
            subtext: '8° to 12°',
            isSuccess: site.isEntryAngleCompliant,
            icon: Icons.south_east_rounded,
          ),
          _buildKpiPill(
            label: 'EXIT ANGLE',
            value: '${site.exitAngleDeg.toStringAsFixed(1)}°',
            subtext: '5° to 8°',
            isSuccess: site.isExitAngleCompliant,
            icon: Icons.north_east_rounded,
          ),
          _buildKpiPill(
            label: 'PULL TENSION',
            value: '${_pullTensionTonnes.toStringAsFixed(0)} t',
            subtext: 'Target < 180t',
            isSuccess: _pullTensionTonnes <= 180.0,
            icon: Icons.speed_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiPill({
    required String label,
    required String value,
    required String subtext,
    required bool isSuccess,
    required IconData icon,
  }) {
    final statusColor = isSuccess ? AppTheme.tertiary : AppTheme.secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: statusColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              subtext,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB BAR
  // ==========================================================================

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 2.5,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.show_chart_rounded, size: 18),
            text: 'Steering & Profile',
          ),
          Tab(
            icon: Icon(Icons.settings_suggest_rounded, size: 18),
            text: 'Reaming Passes',
          ),
          Tab(
            icon: Icon(Icons.swap_horizontal_circle_outlined, size: 18),
            text: 'Pullback & Buoyancy',
          ),
          Tab(
            icon: Icon(Icons.verified_outlined, size: 18),
            text: 'ASME B31.8 Audit',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: STEERING & LONGITUDINAL PROFILE
  // ==========================================================================

  Widget _buildSteeringProfileTab() {
    final site = _activeSite;
    final stations = site.surveyStations;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Steering Tool Mode Switcher (Gyro vs ParaTrack-2)
        _buildSteeringModeCard(),
        const SizedBox(height: 14),

        // Interactive Longitudinal Profile Canvas Card
        _buildLongitudinalProfileCanvasCard(),
        const SizedBox(height: 14),

        // Statutory Alignment & Scour Compliance Cards (Row)
        _buildStatutoryGaugesRow(),
        const SizedBox(height: 14),

        // Scour Line Clearance Diagram Card
        _buildScourLineClearanceCard(),
        const SizedBox(height: 14),

        // Pilot Hole Survey Stations Data Table
        _buildSurveyStationsTableCard(stations),
      ],
    );
  }

  Widget _buildSteeringModeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.track_changes_rounded,
                      color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'STEERING TOOL TELEMETRY MODE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _steeringToolMode.badgeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _steeringToolMode.badgeColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _steeringToolMode.interferenceResistance,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _steeringToolMode.badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildToolModeOption(
                  mode: SteeringToolMode.gyro,
                  isSelected: _steeringToolMode == SteeringToolMode.gyro,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolModeOption(
                  mode: SteeringToolMode.paratrack,
                  isSelected: _steeringToolMode == SteeringToolMode.paratrack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_steeringToolMode.title} • ${_steeringToolMode.sensorType} • Drift: ${_steeringToolMode.driftRate}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolModeOption({
    required SteeringToolMode mode,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _steeringToolMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.2)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryLight : AppTheme.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                mode.icon,
                size: 16,
                color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mode.shortName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLongitudinalProfileCanvasCard() {
    final site = _activeSite;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.terrain_rounded,
                      color: AppTheme.secondary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'LONGITUDINAL DRILL PROFILE & SCOUR BUFFER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                'Profile Length: ${site.profileLengthM.toInt()} m',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom Longitudinal Painter Canvas
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 200,
              width: double.infinity,
              color: const Color(0xFF070D1A),
              child: CustomPaint(
                painter: HddLongitudinalProfilePainter(
                  site: site,
                  scrubberM: _scrubMeasuredDepthM,
                  isLiveTelemetry: _isLiveTelemetryActive,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Scrubber Slider
          Row(
            children: [
              const Text(
                'Station Scrubber:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: AppTheme.primaryLight,
                    inactiveTrackColor: AppTheme.border,
                    thumbColor: AppTheme.secondary,
                    overlayColor: AppTheme.secondary.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _scrubMeasuredDepthM.clamp(0.0, site.profileLengthM),
                    min: 0.0,
                    max: site.profileLengthM,
                    onChanged: (val) {
                      setState(() {
                        _scrubMeasuredDepthM = val;
                      });
                    },
                  ),
                ),
              ),
              Text(
                'MD: ${_scrubMeasuredDepthM.toStringAsFixed(0)} m',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          // Canvas Legend
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _buildCanvasLegendItem(
                color: const Color(0xFF0284C7),
                label: 'Water Body',
                isDashed: false,
              ),
              _buildCanvasLegendItem(
                color: const Color(0xFFEF4444),
                label: '100-Yr Scour Line',
                isDashed: true,
              ),
              _buildCanvasLegendItem(
                color: AppTheme.secondary,
                label: 'Statutory 6m Buffer',
                isDashed: false,
              ),
              _buildCanvasLegendItem(
                color: AppTheme.tertiary,
                label: 'Drill Path Profile',
                isDashed: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasLegendItem({
    required Color color,
    required String label,
    required bool isDashed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatutoryGaugesRow() {
    final site = _activeSite;

    return Row(
      children: [
        // Entry Angle Gauge Card (8° to 12°)
        Expanded(
          child: _buildAngleGaugeCard(
            title: 'ENTRY ANGLE',
            statutoryRange: '8° to 12°',
            actualDeg: site.entryAngleDeg,
            isCompliant: site.isEntryAngleCompliant,
            icon: Icons.south_east_rounded,
            complianceNote: 'ASME B31.8 Compliant',
          ),
        ),
        const SizedBox(width: 12),
        // Exit Angle Gauge Card (5° to 8°)
        Expanded(
          child: _buildAngleGaugeCard(
            title: 'EXIT ANGLE',
            statutoryRange: '5° to 8°',
            actualDeg: site.exitAngleDeg,
            isCompliant: site.isExitAngleCompliant,
            icon: Icons.north_east_rounded,
            complianceNote: 'API RP 1111 Compliant',
          ),
        ),
      ],
    );
  }

  Widget _buildAngleGaugeCard({
    required String title,
    required String statutoryRange,
    required double actualDeg,
    required bool isCompliant,
    required IconData icon,
    required String complianceNote,
  }) {
    final color = isCompliant ? AppTheme.tertiary : AppTheme.secondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompliant
              ? AppTheme.border
              : AppTheme.secondary.withValues(alpha: 0.5),
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
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${actualDeg.toStringAsFixed(1)}°',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Req: $statutoryRange',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCompliant
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  size: 11,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  isCompliant ? 'IN TOLERANCE' : 'EXCEEDS CORRIDOR',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScourLineClearanceCard() {
    final site = _activeSite;
    final isSafe = site.isScourClearanceCompliant;
    final color = isSafe ? AppTheme.tertiary : AppTheme.secondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppTheme.tertiary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'SCOUR LINE STATUTORY DEPTH CHECK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '> 6.0 m MANDATORY',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actual Depth Below Scour Line:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${site.actualDepthBelowScourM.toStringAsFixed(1)} m',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      '+${site.scourMarginAboveStatutoryM.toStringAsFixed(1)} m safety margin above requirement',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppTheme.border,
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'River Bed 100-Yr Scour: ${site.scourBedDepthM.toStringAsFixed(1)} m',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total TVD below ground: ${site.totalTvdBelowSurfaceM.toStringAsFixed(1)} m',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'OISD-141 / ASME B31.8 Section 844.4 verified',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyStationsTableCard(List<HddStationSurvey> stations) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.list_alt_rounded,
                      color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'STEERING LOG SURVEY STATIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                '${stations.length} Stations Logged',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 34,
              dataRowMinHeight: 34,
              dataRowMaxHeight: 40,
              horizontalMargin: 10,
              columnSpacing: 18,
              headingTextStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
                letterSpacing: 0.3,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 11,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              columns: const [
                DataColumn(label: Text('MD (m)')),
                DataColumn(label: Text('TVD (m)')),
                DataColumn(label: Text('PITCH (°)')),
                DataColumn(label: Text('AZIMUTH (°)')),
                DataColumn(label: Text('DLS (°/30m)')),
                DataColumn(label: Text('MUD (Bar)')),
                DataColumn(label: Text('SCOUR CLR')),
                DataColumn(label: Text('FORMATION')),
              ],
              rows: stations.map((st) {
                return DataRow(
                  cells: [
                    DataCell(Text(st.measuredDepthM.toStringAsFixed(0))),
                    DataCell(Text(st.trueVerticalDepthM.toStringAsFixed(1))),
                    DataCell(Text(
                      '${st.pitchAngleDeg.toStringAsFixed(1)}°',
                      style: TextStyle(
                        color: st.pitchAngleDeg.abs() <= 12.0
                            ? AppTheme.textPrimary
                            : AppTheme.secondary,
                      ),
                    )),
                    DataCell(Text('${st.azimuthDeg.toStringAsFixed(1)}°')),
                    DataCell(Text(
                      st.doglegSeverityDegPer30m.toStringAsFixed(1),
                      style: TextStyle(
                        color: st.isDoglegSafe
                            ? AppTheme.textPrimary
                            : AppTheme.secondary,
                      ),
                    )),
                    DataCell(Text(st.mudPressureBar.toStringAsFixed(1))),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          st.isScourSafe
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          size: 12,
                          color: st.isScourSafe
                              ? AppTheme.tertiary
                              : AppTheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${st.depthBelowScourM.toStringAsFixed(1)} m',
                          style: TextStyle(
                            color: st.isScourSafe
                                ? AppTheme.tertiary
                                : AppTheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )),
                    DataCell(Text(st.formationStrata)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: REAMING PASSES TRACKING
  // ==========================================================================

  Widget _buildReamingPassesTab() {
    final site = _activeSite;
    final passes = site.reamingPasses;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Reaming Passes Engineering Banner
        _buildReamingHeaderBanner(),
        const SizedBox(height: 14),

        // 4 Barrel Reamer Passes Cards (16", 26", 36", 48")
        ...passes.map((pass) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildReamingPassCard(pass),
          );
        }),

        // Bentonite Slurry Rheology & Mud Properties Card
        _buildBentoniteMudRheologyCard(),
      ],
    );
  }

  Widget _buildReamingHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded,
                      color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'MULTI-STAGE BARREL REAMING CONTROL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                'ASME B31.8 / API RP 1111',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Hole enlargement sequence: 16" → 26" → 36" → 48" barrel reamer passes. Maximum allowed rotary torque is 65 kN-m. Mud pump pressure target 70–95 Bar (Limit 120 Bar). Bentonite slurry flow rate target 180–240 m³/hr to maintain annular clearance velocity.',
            style: TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReamingPassCard(ReamingPassData pass) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pass.status == ReamingStatus.inProgress
              ? AppTheme.secondary.withValues(alpha: 0.6)
              : AppTheme.border,
          width: pass.status == ReamingStatus.inProgress ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: pass.status.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${pass.diameterInches}"',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: pass.status.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pass.passTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        pass.reamerDescription,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pass.status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(pass.status.icon, size: 12, color: pass.status.color),
                    const SizedBox(width: 4),
                    Text(
                      pass.status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: pass.status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pass.progressRatio,
                    backgroundColor: AppTheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(pass.status.color),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(pass.progressRatio * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: pass.status.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Telemetry Metrics Grid (Torque, Pressure, Slurry Flow)
          Row(
            children: [
              // Rotary Torque (kN-m)
              Expanded(
                child: _buildReamMetricBox(
                  label: 'ROTARY TORQUE',
                  value: '${pass.rotaryTorqueKnm.toStringAsFixed(1)} kN-m',
                  sublabel: 'Limit: < 65 kN-m',
                  isSafe: pass.isTorqueSafe,
                  icon: Icons.rotate_right_rounded,
                ),
              ),
              const SizedBox(width: 8),
              // Mud Pump Pressure (Bar)
              Expanded(
                child: _buildReamMetricBox(
                  label: 'PUMP PRESSURE',
                  value: '${pass.mudPumpPressureBar.toStringAsFixed(0)} Bar',
                  sublabel: 'Target: 70–95 Bar',
                  isSafe: pass.isPressureSafe,
                  icon: Icons.compress_rounded,
                ),
              ),
              const SizedBox(width: 8),
              // Bentonite Slurry Flow Rate (m³/hr)
              Expanded(
                child: _buildReamMetricBox(
                  label: 'BENTONITE FLOW',
                  value:
                      '${pass.bentoniteSlurryFlowRateM3h.toStringAsFixed(0)} m³/h',
                  sublabel: 'Target: 180–240',
                  isSafe: pass.isFlowRateInTarget || pass.progressRatio == 0,
                  icon: Icons.water_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Additional Telemetry Details
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RPM: ${pass.rotationSpeedRpm.toInt()} • ROP: ${pass.penetrationRateMh.toStringAsFixed(1)} m/h',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Returns: ${pass.cuttingsReturnsPct.toStringAsFixed(1)}% • Mud: ${pass.slurrySpecificGravity.toStringAsFixed(2)} SG',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReamMetricBox({
    required String label,
    required String value,
    required String sublabel,
    required bool isSafe,
    required IconData icon,
  }) {
    final color = isSafe ? AppTheme.textPrimary : AppTheme.secondary;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoniteMudRheologyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined,
                  color: AppTheme.primaryLight, size: 18),
              SizedBox(width: 8),
              Text(
                'BENTONITE SLURRY RHEOLOGY SPECIFICATIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RheologyMetricPill(
                label: 'Marsh Funnel',
                value: '76 sec/qt',
                spec: 'Spec: 65–85 s',
              ),
              _RheologyMetricPill(
                label: 'Mud Density',
                value: '1.16 SG',
                spec: 'Spec: 1.12–1.18',
              ),
              _RheologyMetricPill(
                label: 'Sand Content',
                value: '0.35 %',
                spec: 'Spec: < 0.5%',
              ),
              _RheologyMetricPill(
                label: 'Yield Point',
                value: '28 lb/100ft²',
                spec: 'Spec: 25–35',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: PULLBACK & BUOYANCY TELEMETRY
  // ==========================================================================

  Widget _buildPullbackBuoyancyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pullback Rig Load Cell Tension Gauge Card
        _buildPullbackTensionCard(),
        const SizedBox(height: 14),

        // Dual Load Cell Sensor Verification
        _buildDualLoadCellVerificationRow(),
        const SizedBox(height: 14),

        // Buoyancy Control Water Filling Schedule Card
        _buildBuoyancyControlScheduleCard(),
        const SizedBox(height: 14),

        // Interactive Ballast Water Injection Simulator
        _buildBallastSimulatorCard(),
        const SizedBox(height: 14),

        // Pipe Thruster & Break-Over Roller System
        _buildThrusterAndRollerSystemCard(),
      ],
    );
  }

  Widget _buildPullbackTensionCard() {
    final isWithinTarget = _pullTensionTonnes <= 180.0;
    final isSafeCapacity = _pullTensionTonnes <= 245.0;
    final gaugeColor = isWithinTarget
        ? AppTheme.tertiary
        : (isSafeCapacity ? AppTheme.secondary : const Color(0xFFEF4444));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.speed_rounded,
                      color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'PULLBACK RIG LOAD CELL TENSION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: gaugeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isWithinTarget ? 'TARGET COMPLIANT' : 'ELEVATED TENSION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: gaugeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tension Readout Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _pullTensionTonnes.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: gaugeColor,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'TONNES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Target Limit: < 180 tonnes',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.tertiary,
                    ),
                  ),
                  Text(
                    'Max Rig Pull Capacity: 350 tonnes',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Analog / Linear Capacity Utilization Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 14,
              color: AppTheme.surface,
              child: Stack(
                children: [
                  // Target limit marker (< 180 t -> ~51.4%)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.of(context).size.width * 0.514 * 0.85,
                    child: Container(
                      color: AppTheme.tertiary.withValues(alpha: 0.12),
                    ),
                  ),
                  // Active tension fill
                  FractionallySizedBox(
                    widthFactor: (_pullTensionTonnes / 350.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: gaugeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Threshold Scale Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 t',
                  style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
              Text('180 t Target Limit',
                  style: TextStyle(fontSize: 9.5, color: AppTheme.tertiary)),
              Text('245 t 70% SMYS',
                  style: TextStyle(fontSize: 9.5, color: AppTheme.secondary)),
              Text('350 t Rig Max',
                  style: TextStyle(fontSize: 9.5, color: Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDualLoadCellVerificationRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LOAD CELL A (HYDRAULIC)',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_loadCellATonnes.toStringAsFixed(1)} tonnes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Text(
                  'Status: Balanced (50.1%)',
                  style: TextStyle(fontSize: 9.5, color: AppTheme.tertiary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LOAD CELL B (STRAIN GAUGE)',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_loadCellBTonnes.toStringAsFixed(1)} tonnes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Text(
                  'Status: Balanced (49.9%)',
                  style: TextStyle(fontSize: 9.5, color: AppTheme.tertiary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBuoyancyControlScheduleCard() {
    final site = _activeSite;
    final stages = site.buoyancyStages;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop_rounded,
                      color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'BUOYANCY CONTROL WATER FILLING SCHEDULE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                'Anti-Buoyancy Ballast',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Large diameter steel pipelines exhibit high buoyant uplift in 1.15 SG bentonite slurry, creating heavy friction along the borehole crown. Internal water filling balances buoyancy to achieve optimal net negative submerged weight (-14.2 kg/m).',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),

          // Buoyancy Stages Timeline
          ...stages.map((st) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: st.isActive
                    ? AppTheme.primary.withValues(alpha: 0.18)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: st.isActive ? AppTheme.primaryLight : AppTheme.border,
                  width: st.isActive ? 1.2 : 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        st.stageTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: st.isActive
                              ? AppTheme.primaryLight
                              : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        st.chainageSpan,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target: ${st.targetWaterM3.toStringAsFixed(0)} m³ • Pumped: ${st.pumpedWaterM3.toStringAsFixed(1)} m³',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        'Net Wt: ${st.netSubmergedWeightKgM.toStringAsFixed(1)} kg/m',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: st.progressRatio,
                      backgroundColor: AppTheme.surfaceCard,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        st.isCompleted
                            ? AppTheme.tertiary
                            : (st.isActive
                                ? AppTheme.primaryLight
                                : AppTheme.textMuted),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBallastSimulatorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.waves_rounded,
                      color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'BALLAST WATER INJECTION TELEMETRY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _simulateWaterInjection,
                icon: const Icon(Icons.water_drop_rounded, size: 14),
                label: const Text('Inject +5 m³'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBallastKpi(
                  label: 'CUMULATIVE WATER',
                  value: '${_pumpedWaterVolumeM3.toStringAsFixed(1)} m³',
                  sub: 'Planned: 152 m³',
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBallastKpi(
                  label: 'PUMPING RATE',
                  value: '${_waterFillingRateM3h.toStringAsFixed(1)} m³/h',
                  sub: '3" Internal Poly Line',
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBallastKpi(
                  label: 'NET BUOYANCY',
                  value: '${_netBuoyancyWeightKgM.toStringAsFixed(1)} kg/m',
                  sub: 'Optimum: -15 kg/m',
                  color: AppTheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBallastKpi({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 8.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThrusterAndRollerSystemCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.precision_manufacturing_rounded,
                  color: AppTheme.secondary, size: 18),
              SizedBox(width: 8),
              Text(
                'PIPE THRUSTER & ROLLER CRADLE SYSTEM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Auxiliary Thruster Push Force: ${_thrusterPushTonnes.toStringAsFixed(0)} t',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tertiary,
                ),
              ),
              const Text(
                '18 Roller Cradles Active',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Herrenknecht HK300PT Pipe Thruster active at South Bank. Net pull load seen by main rig reduced by 21% through synchronized hydraulic thrust.',
            style: TextStyle(
              fontSize: 10.5,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: ASME B31.8 / API RP 1111 AUDIT & QA/QC
  // ==========================================================================

  Widget _buildAsmeAuditTab() {
    final site = _activeSite;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Compliance Overview Header
        _buildAsmeAuditHeader(),
        const SizedBox(height: 14),

        // ASME B31.8 Stress Calculations Verification
        _buildStressCalculationsCard(site),
        const SizedBox(height: 14),

        // API RP 1111 Hydrostatic Collapse Resistance Card
        _buildHydrostaticCollapseCard(site),
        const SizedBox(height: 14),

        // QA/QC Inspection Checklist
        _buildQaQcChecklistCard(),
        const SizedBox(height: 14),

        // Export Certificate Action Button
        ElevatedButton.icon(
          onPressed: _showComplianceCertificateDialog,
          icon: const Icon(Icons.assignment_turned_in_rounded),
          label: const Text('VIEW ASME B31.8 QA/QC CERTIFICATE'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAsmeAuditHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded,
                  color: AppTheme.tertiary, size: 20),
              SizedBox(width: 8),
              Text(
                'ASME B31.8 / API RP 1111 TRENCHLESS AUDIT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Engineering design verification for Horizontal Directional Drilling under ASME B31.8 Chapter VIII (Crossings), API RP 1111 (Limit-State Design), and OISD-STD-141. Combined installation tensile, bending, and external hydrostatic stresses must not exceed 0.90 × SMYS.',
            style: TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressCalculationsCard(HddCrossingSite site) {
    // ASME B31.8 Radius calculation: R >= 1200 * D
    final rMin = site.minRadiusOfCurvatureM;
    final rDesign = site.designRadiusOfCurvatureM;
    final rSafetyFactor = rDesign / rMin;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ASME B31.8 SECTION 844.4 STRESS VERIFICATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryLight,
                  letterSpacing: 0.4,
                ),
              ),
              Icon(Icons.calculate_outlined,
                  size: 16, color: AppTheme.primaryLight),
            ],
          ),
          const SizedBox(height: 10),
          _buildAuditRow(
            label: 'Minimum Radius of Curvature (R_min = 1200 × D)',
            value: '${rMin.toStringAsFixed(1)} m',
            status: 'Compliant (${rSafetyFactor.toStringAsFixed(2)}x Margin)',
            isOk: true,
          ),
          _buildAuditRow(
            label: 'Actual Design Bore Radius (R_design)',
            value: '${rDesign.toStringAsFixed(1)} m',
            status: 'Pass (R_design > R_min)',
            isOk: true,
          ),
          _buildAuditRow(
            label: 'Longitudinal Bending Stress (S_b = E·D / 2R)',
            value: '130.5 MPa',
            status: 'Pass (< 0.50 SMYS)',
            isOk: true,
          ),
          _buildAuditRow(
            label: 'Axial Pullback Tensile Stress (S_a = T / A)',
            value: '48.2 MPa',
            status: 'Pass (Tension < 180t)',
            isOk: true,
          ),
          _buildAuditRow(
            label: 'Combined Installation Stress (von Mises)',
            value: '178.7 MPa',
            status: '0.37 × SMYS (Limit: 0.90 SMYS)',
            isOk: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHydrostaticCollapseCard(HddCrossingSite site) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'API RP 1111 HYDROSTATIC COLLAPSE INTEGRITY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.secondary,
                  letterSpacing: 0.4,
                ),
              ),
              Icon(Icons.water_drop_outlined,
                  size: 16, color: AppTheme.secondary),
            ],
          ),
          const SizedBox(height: 10),
          _buildAuditRow(
            label: 'Hydrostatic External Mud Head Pressure (P_ext)',
            value: '3.12 Bar (0.31 MPa)',
            status: 'Safe head',
            isOk: true,
          ),
          _buildAuditRow(
            label: 'Critical Elastic Collapse Pressure (P_c)',
            value: '14.8 Bar (1.48 MPa)',
            status: '4.7x Safety Factor',
            isOk: true,
          ),
          _buildAuditRow(
            label: 'Plastic Yield Collapse Pressure (P_y)',
            value: '22.5 Bar (2.25 MPa)',
            status: 'Compliant',
            isOk: true,
          ),
          _buildAuditRow(
            label: 'Depth Below 100-Yr Scour Line (> 6.0m Statutory)',
            value: '${site.actualDepthBelowScourM.toStringAsFixed(1)} m',
            status: 'Statutory Verified',
            isOk: site.isScourClearanceCompliant,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow({
    required String label,
    required String value,
    required String status,
    required bool isOk,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isOk ? AppTheme.tertiary : AppTheme.secondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQaQcChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MANDATORY TRENCHLESS QA/QC SIGN-OFFS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          _buildChecklistItem(
            title: '100% AUT & Radiographic Weld Inspection',
            subtitle: 'API 1104 / ASME Section IX certification complete',
            isDone: true,
          ),
          _buildChecklistItem(
            title: '3-Layer PE Field Joint Coating Holiday Test',
            subtitle: '15 kV Spark Tester verified 0 holidays across string',
            isDone: true,
          ),
          _buildChecklistItem(
            title: 'Pre-Pullback Hydrostatic Section Test (4 Hours)',
            subtitle: 'Test pressure 105 Bar held with 0.0 bar pressure decay',
            isDone: true,
          ),
          _buildChecklistItem(
            title: 'Swivel Bearing & Pull Head Proof Load Test',
            subtitle: 'Certified to 350 tonnes rated tension capacity',
            isDone: true,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required String subtitle,
    required bool isDone,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 15,
            color: isDone ? AppTheme.tertiary : AppTheme.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER PILL WIDGET FOR RHEOLOGY
// ============================================================================

class _RheologyMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final String spec;

  const _RheologyMetricPill({
    required this.label,
    required this.value,
    required this.spec,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryLight,
          ),
        ),
        Text(
          spec,
          style: const TextStyle(
            fontSize: 8.5,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// COMPLIANCE CERTIFICATE MODAL SHEET
// ============================================================================

class _ComplianceCertificateSheet extends StatelessWidget {
  final HddCrossingSite site;

  const _ComplianceCertificateSheet({required this.site});

  @override
  Widget build(BuildContext context) {
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
              const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      color: AppTheme.tertiary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'TRENCHLESS CROSSING CERTIFICATE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppTheme.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 10),
          Text(
            site.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            site.subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _buildModalDetailRow('Design Standard', 'ASME B31.8 / API RP 1111'),
                _buildModalDetailRow('Total Length', '${site.profileLengthM.toInt()} m profile'),
                _buildModalDetailRow('Pipeline Size', '${site.pipeDiameterInches}" OD (${site.pipeOuterDiameterMm} mm)'),
                _buildModalDetailRow('Pipe Grade & WT', '${site.pipeGrade} • ${site.wallThicknessMm} mm'),
                _buildModalDetailRow('Entry Angle', '${site.entryAngleDeg}° (Corridor 8°–12°)'),
                _buildModalDetailRow('Exit Angle', '${site.exitAngleDeg}° (Corridor 5°–8°)'),
                _buildModalDetailRow('Scour Line Clearance', '${site.actualDepthBelowScourM} m (Statutory > 6.0 m)'),
                _buildModalDetailRow('Max Pull Load', '${site.targetPullTensionTonnes} t (Rig Limit: 350 t)'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.tertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.tertiary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Certified: Crossing geometry and installation stresses are within permissible limit state criteria. Approved for Hydrostatic Test.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('CLOSE CERTIFICATE',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER: LONGITUDINAL PROFILE & SCOUR BUFFER CANVAS
// ============================================================================

class HddLongitudinalProfilePainter extends CustomPainter {
  final HddCrossingSite site;
  final double scrubberM;
  final bool isLiveTelemetry;

  const HddLongitudinalProfilePainter({
    required this.site,
    required this.scrubberM,
    required this.isLiveTelemetry,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF162347).withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= w; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y <= h; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Geometry Dimensions
    final entryX = w * 0.08;
    final exitX = w * 0.92;
    final riverStartX = w * 0.28;
    final riverEndX = w * 0.72;

    final groundY = h * 0.26;
    final waterY = h * 0.32;
    final bedY = h * 0.44;
    final scourY = h * 0.58; // 100-yr Scour Line
    final statutoryBufferY = h * 0.68; // 6.0 m Statutory Clearance Line
    final boreDeepY = h * 0.85; // Drill Path Apex Deepest Point

    // 1. Water Body Surface & Flow Fill
    final waterPath = Path()
      ..moveTo(riverStartX, waterY)
      ..quadraticBezierTo(
          (riverStartX + riverEndX) / 2, waterY + 4, riverEndX, waterY)
      ..lineTo(riverEndX, bedY)
      ..quadraticBezierTo(
          (riverStartX + riverEndX) / 2, bedY + 8, riverStartX, bedY)
      ..close();

    final waterPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x330284C7), Color(0x660284C7)],
      ).createShader(Rect.fromLTWH(0, waterY, w, bedY - waterY));
    canvas.drawPath(waterPath, waterPaint);

    // 2. Statutory 6m Scour Protection Buffer (Amber hatched/tinted band)
    final bufferZonePath = Path()
      ..moveTo(riverStartX - 15, scourY)
      ..lineTo(riverEndX + 15, scourY)
      ..lineTo(riverEndX + 15, statutoryBufferY)
      ..lineTo(riverStartX - 15, statutoryBufferY)
      ..close();

    final bufferPaint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.14);
    canvas.drawPath(bufferZonePath, bufferPaint);

    // 3. Ground Profile / River Bed Contour
    final groundPath = Path()
      ..moveTo(0, groundY)
      ..lineTo(riverStartX, groundY)
      ..quadraticBezierTo(riverStartX + 20, bedY, (riverStartX + riverEndX) / 2, bedY)
      ..quadraticBezierTo(riverEndX - 20, bedY, riverEndX, groundY)
      ..lineTo(w, groundY);

    final groundPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(groundPath, groundPaint);

    // 4. 100-Year Scour Line (Dashed Red Line)
    final scourPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      Offset(riverStartX - 10, scourY),
      Offset(riverEndX + 10, scourY),
      5,
      4,
      scrPaint: scourPaint,
    );

    // 5. Statutory 6.0 m Line (Dashed Amber Line)
    final statutoryPaint = Paint()
      ..color = AppTheme.secondary
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      Offset(riverStartX - 10, statutoryBufferY),
      Offset(riverEndX + 10, statutoryBufferY),
      4,
      3,
      scrPaint: statutoryPaint,
    );

    // 6. Borehole Trajectory Profile Curve
    final borePath = Path()
      ..moveTo(entryX, groundY)
      ..cubicTo(
        entryX + (riverStartX - entryX) * 0.9,
        boreDeepY,
        riverEndX - (exitX - riverEndX) * 0.1,
        boreDeepY,
        exitX,
        groundY,
      );

    final boreGlowPaint = Paint()
      ..color = AppTheme.tertiary.withValues(alpha: 0.25)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(borePath, boreGlowPaint);

    final boreLinePaint = Paint()
      ..color = AppTheme.tertiary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(borePath, boreLinePaint);

    // 7. Entry and Exit Pit Markers & Angles
    final rigPaint = Paint()
      ..color = AppTheme.primaryLight
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(entryX, groundY), 4.5, rigPaint);
    canvas.drawCircle(Offset(exitX, groundY), 4.5, rigPaint);

    // Entry Angle Arc / Line Indicator
    final entryTangent = Offset(entryX + 22, groundY + 16);
    canvas.drawLine(
        Offset(entryX, groundY), entryTangent, Paint()..color = AppTheme.primaryLight);

    // Exit Angle Arc / Line Indicator
    final exitTangent = Offset(exitX - 22, groundY + 14);
    canvas.drawLine(
        Offset(exitX, groundY), exitTangent, Paint()..color = AppTheme.primaryLight);

    // 8. Scour Clearance Dimension Callout
    final midX = (riverStartX + riverEndX) / 2;
    final arrowPaint = Paint()
      ..color = AppTheme.tertiary
      ..strokeWidth = 1.4;

    canvas.drawLine(Offset(midX, scourY), Offset(midX, boreDeepY), arrowPaint);
    canvas.drawCircle(Offset(midX, scourY), 2.5, arrowPaint);
    canvas.drawCircle(Offset(midX, boreDeepY), 2.5, arrowPaint);

    // Text annotations on canvas
    _drawText(
      canvas,
      'ENTRY ${site.entryAngleDeg}°',
      Offset(entryX - 10, groundY - 18),
      AppTheme.primaryLight,
      9,
      FontWeight.w700,
    );
    _drawText(
      canvas,
      'EXIT ${site.exitAngleDeg}°',
      Offset(exitX - 18, groundY - 18),
      AppTheme.primaryLight,
      9,
      FontWeight.w700,
    );
    _drawText(
      canvas,
      '100-YR SCOUR',
      Offset(riverStartX - 5, scourY - 12),
      const Color(0xFFEF4444),
      8.5,
      FontWeight.w700,
    );
    _drawText(
      canvas,
      'STATUTORY 6m BUFFER',
      Offset(riverEndX - 85, statutoryBufferY + 4),
      AppTheme.secondary,
      8.5,
      FontWeight.w700,
    );
    _drawText(
      canvas,
      'CLR: ${site.actualDepthBelowScourM} m',
      Offset(midX + 6, (scourY + boreDeepY) / 2 - 6),
      AppTheme.tertiary,
      9.5,
      FontWeight.w800,
    );

    // 9. Interactive Scrubber Indicator Needle
    final scrubFraction = (scrubberM / site.profileLengthM).clamp(0.0, 1.0);
    final scrubX = entryX + (exitX - entryX) * scrubFraction;

    final scrubPaint = Paint()
      ..color = AppTheme.secondary
      ..strokeWidth = 1.2;
    _drawDashedLine(
      canvas,
      Offset(scrubX, 0),
      Offset(scrubX, h),
      3,
      3,
      scrPaint: scrubPaint,
    );

    // Scrubber Head Circle with pulse
    final pulseOffset = isLiveTelemetry ? 2.0 : 0.0;
    canvas.drawCircle(
      Offset(scrubX, boreDeepY),
      5.0 + pulseOffset,
      Paint()..color = AppTheme.secondary.withValues(alpha: 0.4),
    );
    canvas.drawCircle(
      Offset(scrubX, boreDeepY),
      3.5,
      Paint()..color = AppTheme.secondary,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    double dashWidth,
    double dashSpace, {
    Paint? scrPaint,
  }) {
    final paint = scrPaint ??
        (Paint()
          ..color = Colors.white
          ..strokeWidth = 1);
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final count = (dist / (dashWidth + dashSpace)).floor();
    final unitX = dx / dist;
    final unitY = dy / dist;

    for (int i = 0; i < count; i++) {
      final start = Offset(
        p1.dx + (dashWidth + dashSpace) * i * unitX,
        p1.dy + (dashWidth + dashSpace) * i * unitY,
      );
      final end = Offset(
        start.dx + dashWidth * unitX,
        start.dy + dashWidth * unitY,
      );
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
    double fontSize,
    FontWeight fontWeight,
  ) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant HddLongitudinalProfilePainter oldDelegate) {
    return oldDelegate.site != site ||
        oldDelegate.scrubberM != scrubberM ||
        oldDelegate.isLiveTelemetry != isLiveTelemetry;
  }
}
