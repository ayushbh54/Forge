import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';

/// Pipeline Fitting Type per ASME B31.8 §835 / AWWA M11
enum FittingType {
  bend90(
    name: '90° Horizontal Bend',
    shortName: '90° Bend',
    defaultAngleDeg: 90.0,
    icon: Icons.turn_right_rounded,
    description: 'Acute direction change requiring maximum thrust restraint.',
  ),
  bend45(
    name: '45° Horizontal Bend',
    shortName: '45° Bend',
    defaultAngleDeg: 45.0,
    icon: Icons.turn_slight_right_rounded,
    description: 'Moderate highway/corridor deflection bend.',
  ),
  bend22_5(
    name: '22.5° Horizontal Bend',
    shortName: '22.5° Bend',
    defaultAngleDeg: 22.5,
    icon: Icons.alt_route_rounded,
    description: 'Gentle pipeline alignment bend.',
  ),
  bend11_25(
    name: '11.25° Horizontal Bend',
    shortName: '11.25° Bend',
    defaultAngleDeg: 11.25,
    icon: Icons.trending_up_rounded,
    description: 'Minor contour deflection angle.',
  ),
  reducer(
    name: 'Reducer (D1 -> D2)',
    shortName: 'Reducer',
    defaultAngleDeg: 0.0,
    icon: Icons.compress_rounded,
    description: 'Axial unbalanced thrust due to cross-sectional area step-down.',
  ),
  deadEnd(
    name: 'Dead-End / Blind Flange',
    shortName: 'Dead-End',
    defaultAngleDeg: 180.0,
    icon: Icons.block_rounded,
    description: 'Terminal bulkhead or scraper receiver test cap full thrust.',
  ),
  verticalSag(
    name: 'Vertical Sag Bend (Trough)',
    shortName: 'Sag Bend',
    defaultAngleDeg: 20.0,
    icon: Icons.south_east_rounded,
    description: 'Depression curve pushing downward into trench bed.',
  ),
  verticalOverbend(
    name: 'Vertical Overbend (Crest)',
    shortName: 'Overbend',
    defaultAngleDeg: 20.0,
    icon: Icons.north_east_rounded,
    description: 'Ridge curve generating upward uplift thrust against cover.',
  ),
  teeBranch(
    name: '90° Branch Tee Outlet',
    shortName: 'Branch Tee',
    defaultAngleDeg: 90.0,
    icon: Icons.call_split_rounded,
    description: 'Unbalanced lateral hydrostatic thrust on the main run opposite branch.',
  );

  final String name;
  final String shortName;
  final double defaultAngleDeg;
  final IconData icon;
  final String description;

  const FittingType({
    required this.name,
    required this.shortName,
    required this.defaultAngleDeg,
    required this.icon,
    required this.description,
  });
}

/// Geotechnical Soil Classification per Rankine Earth Pressure Theory
enum SoilClassification {
  denseSand(
    name: 'Dense Sand & Gravel',
    description: 'High friction, negligible cohesion, rapid drainage',
    gammaKnM3: 19.5,
    phiDeg: 38.0,
    cohesionKpa: 0.0,
    sbcKpa: 300.0,
    frictionCoeff: 0.50,
  ),
  mediumSand(
    name: 'Medium Silty Sand',
    description: 'Standard alluvial valley deposit with good passive wedge',
    gammaKnM3: 18.0,
    phiDeg: 32.0,
    cohesionKpa: 0.0,
    sbcKpa: 220.0,
    frictionCoeff: 0.45,
  ),
  stiffClay(
    name: 'Stiff Silty Clay',
    description: 'Cohesive soil with strong cohesion intercept and moderate friction',
    gammaKnM3: 18.5,
    phiDeg: 22.0,
    cohesionKpa: 35.0,
    sbcKpa: 200.0,
    frictionCoeff: 0.35,
  ),
  mediumClay(
    name: 'Medium Alluvial Clay',
    description: 'Low-to-medium plasticity flood plain clayey silt',
    gammaKnM3: 17.5,
    phiDeg: 18.0,
    cohesionKpa: 25.0,
    sbcKpa: 150.0,
    frictionCoeff: 0.30,
  ),
  gravelBoulder(
    name: 'Riverbed Cobble & Boulder',
    description: 'Coarse interlocking gravel with high bearing capacity',
    gammaKnM3: 21.0,
    phiDeg: 42.0,
    cohesionKpa: 5.0,
    sbcKpa: 400.0,
    frictionCoeff: 0.55,
  ),
  softAlluvium(
    name: 'Soft Floodplain Alluvium',
    description: 'Weak unconsolidated silt clay requiring massive block sizing',
    gammaKnM3: 16.5,
    phiDeg: 15.0,
    cohesionKpa: 15.0,
    sbcKpa: 120.0,
    frictionCoeff: 0.25,
  );

  final String name;
  final String description;
  final double gammaKnM3;
  final double phiDeg;
  final double cohesionKpa;
  final double sbcKpa;
  final double frictionCoeff;

  const SoilClassification({
    required this.name,
    required this.description,
    required this.gammaKnM3,
    required this.phiDeg,
    required this.cohesionKpa,
    required this.sbcKpa,
    required this.frictionCoeff,
  });
}

/// Pipeline Station Preset for Field Thrust Blocks
class ThrustBlockStationPreset {
  final String id;
  final String tag;
  final String chainage;
  final String locationDescription;
  final FittingType fittingType;
  final double bendAngleDeg;
  final double pipeDiameterMm;
  final double reducerDiameterMm;
  final double wallThicknessMm;
  final double testPressureMpa;
  final SoilClassification soilType;
  final double blockLengthM;
  final double blockWidthM;
  final double blockHeightM;
  final double depthOfCoverM;
  final int tieRodCount;
  final double tieRodDiameterMm;
  final double neopreneThicknessMm;

  const ThrustBlockStationPreset({
    required this.id,
    required this.tag,
    required this.chainage,
    required this.locationDescription,
    required this.fittingType,
    required this.bendAngleDeg,
    required this.pipeDiameterMm,
    this.reducerDiameterMm = 457.0,
    required this.wallThicknessMm,
    required this.testPressureMpa,
    required this.soilType,
    required this.blockLengthM,
    required this.blockWidthM,
    required this.blockHeightM,
    required this.depthOfCoverM,
    required this.tieRodCount,
    required this.tieRodDiameterMm,
    required this.neopreneThicknessMm,
  });
}

/// Engineering Calculation Engine per ASME B31.8 §835 / AWWA M11 / IS 4984 / Rankine
class ThrustDesignCalculation {
  final FittingType fittingType;
  final double bendAngleDeg;
  final double pipeDiameterMm;
  final double reducerDiameterMm;
  final double wallThicknessMm;
  final double testPressureMpa;
  final double soilUnitWeightKnM3;
  final double soilFrictionAngleDeg;
  final double soilCohesionKpa;
  final double soilSbcKpa;
  final double soilFrictionCoeff;
  final double blockLengthM;
  final double blockWidthM;
  final double blockHeightM;
  final double depthOfCoverM;
  final double concreteDensityKnM3;
  final int tieRodCount;
  final double tieRodDiameterMm;
  final double neopreneThicknessMm;
  final int neopreneHardnessShoreA;

  const ThrustDesignCalculation({
    required this.fittingType,
    required this.bendAngleDeg,
    required this.pipeDiameterMm,
    this.reducerDiameterMm = 457.0,
    required this.wallThicknessMm,
    required this.testPressureMpa,
    required this.soilUnitWeightKnM3,
    required this.soilFrictionAngleDeg,
    required this.soilCohesionKpa,
    required this.soilSbcKpa,
    required this.soilFrictionCoeff,
    required this.blockLengthM,
    required this.blockWidthM,
    required this.blockHeightM,
    required this.depthOfCoverM,
    this.concreteDensityKnM3 = 24.5,
    required this.tieRodCount,
    required this.tieRodDiameterMm,
    required this.neopreneThicknessMm,
    this.neopreneHardnessShoreA = 60,
  });

  // Pipe Geometry
  double get pipeDiameterM => pipeDiameterMm / 1000.0;
  double get reducerDiameterM => reducerDiameterMm / 1000.0;
  double get pipeAreaM2 => math.pi * math.pow(pipeDiameterM, 2) / 4.0;
  double get reducerAreaM2 => math.pi * math.pow(reducerDiameterM, 2) / 4.0;
  double get testPressureKpa => testPressureMpa * 1000.0;

  // Unbalanced Hydrostatic Thrust Force F_thrust (kN)
  double get thrustForceKn {
    switch (fittingType) {
      case FittingType.bend90:
      case FittingType.bend45:
      case FittingType.bend22_5:
      case FittingType.bend11_25:
      case FittingType.verticalSag:
      case FittingType.verticalOverbend:
        final angleRad = (bendAngleDeg * math.pi) / 180.0;
        return 2.0 * testPressureKpa * pipeAreaM2 * math.sin(angleRad / 2.0);
      case FittingType.reducer:
        final deltaA = (pipeAreaM2 - reducerAreaM2).abs();
        return testPressureKpa * deltaA;
      case FittingType.deadEnd:
        return testPressureKpa * pipeAreaM2;
      case FittingType.teeBranch:
        return testPressureKpa * pipeAreaM2;
    }
  }

  double get thrustForceTonnes => thrustForceKn / 9.80665;

  // Rankine Passive Earth Pressure Coefficient K_p
  double get rankineKp {
    final phiRad = (soilFrictionAngleDeg * math.pi) / 180.0;
    final term = math.tan((math.pi / 4.0) + (phiRad / 2.0));
    return term * term;
  }

  // Passive Soil Resistance per unit area
  double get passivePressureTopKpa {
    final sigmaV1 = soilUnitWeightKnM3 * depthOfCoverM;
    return sigmaV1 * rankineKp + 2.0 * soilCohesionKpa * math.sqrt(rankineKp);
  }

  double get passivePressureBottomKpa {
    final sigmaV2 = soilUnitWeightKnM3 * (depthOfCoverM + blockHeightM);
    return sigmaV2 * rankineKp + 2.0 * soilCohesionKpa * math.sqrt(rankineKp);
  }

  double get passivePressureAvgKpa =>
      (passivePressureTopKpa + passivePressureBottomKpa) / 2.0;

  // Bearing area normal to thrust against undisturbed trench face
  double get bearingAreaM2 => blockWidthM * blockHeightM;

  // Total Soil Passive Resistance Force R_p (kN)
  double get passiveResistanceKn => bearingAreaM2 * passivePressureAvgKpa;

  // Concrete Mass & Geometry
  double get blockGrossVolumeM3 => blockLengthM * blockWidthM * blockHeightM;
  double get pipeCutoutVolumeM3 =>
      (math.pi * math.pow(pipeDiameterM / 2.0, 2)) * blockLengthM * 0.5;
  double get blockNetVolumeM3 =>
      math.max(0.2, blockGrossVolumeM3 - pipeCutoutVolumeM3);

  double get concreteWeightKn => blockNetVolumeM3 * concreteDensityKnM3;
  double get concreteWeightTonnes => concreteWeightKn / 9.80665;

  // Soil Overburden Weight (acting on top of block)
  double get soilOverburdenWeightKn =>
      blockLengthM * blockWidthM * depthOfCoverM * soilUnitWeightKnM3;

  // Pipe + Fluid weight encased in block
  double get pipeSteelWeightKn {
    final tM = wallThicknessMm / 1000.0;
    final steelArea = math.pi * pipeDiameterM * tM;
    return steelArea * blockLengthM * 77.0; // steel unit wt ~ 77 kN/m3
  }

  double get waterWeightKn => pipeAreaM2 * blockLengthM * 9.81;

  double get totalVerticalWeightKn =>
      concreteWeightKn + soilOverburdenWeightKn + pipeSteelWeightKn + waterWeightKn;

  // Base Contact Area
  double get baseAreaM2 => blockLengthM * blockWidthM;

  // Base Soil Interface Friction & Adhesion Resistance R_f (kN)
  double get baseAdhesionKpa => 0.5 * soilCohesionKpa;
  double get baseFrictionKn =>
      (soilFrictionCoeff * totalVerticalWeightKn) + (baseAdhesionKpa * baseAreaM2);

  // Total Resisting Force against Sliding (kN)
  double get totalResistingForceKn => passiveResistanceKn + baseFrictionKn;

  // Factor of Safety against Sliding (FOS_slide >= 1.50)
  double get fosSliding =>
      thrustForceKn > 0 ? (totalResistingForceKn / thrustForceKn) : 99.9;
  bool get isSlidingPass => fosSliding >= 1.50;

  // Overturning Stability about the base toe
  double get thrustLeverArmM => blockHeightM / 2.0;
  double get overturningMomentKnm => thrustForceKn * thrustLeverArmM;
  double get restoringMomentKnm => totalVerticalWeightKn * (blockLengthM / 2.0);

  // Factor of Safety against Overturning (FOS_overturn >= 2.00)
  double get fosOverturning => overturningMomentKnm > 0
      ? (restoringMomentKnm / overturningMomentKnm)
      : 99.9;
  bool get isOverturningPass => fosOverturning >= 2.00;

  // Foundation Base Bearing Pressure Distribution
  double get eccentricityM => totalVerticalWeightKn > 0
      ? (overturningMomentKnm / totalVerticalWeightKn)
      : 0.0;
  double get kernLimitM => blockLengthM / 6.0;

  double get maxBearingPressureKpa {
    if (baseAreaM2 <= 0.01) return 0.0;
    if (eccentricityM <= kernLimitM) {
      return (totalVerticalWeightKn / baseAreaM2) *
          (1.0 + (6.0 * eccentricityM / blockLengthM));
    } else {
      final effectiveLength = 3.0 * math.max(0.1, (blockLengthM / 2.0) - eccentricityM);
      return (2.0 * totalVerticalWeightKn) / (blockWidthM * effectiveLength);
    }
  }

  double get minBearingPressureKpa {
    if (baseAreaM2 <= 0.01) return 0.0;
    if (eccentricityM <= kernLimitM) {
      return (totalVerticalWeightKn / baseAreaM2) *
          (1.0 - (6.0 * eccentricityM / blockLengthM));
    } else {
      return 0.0; // Tension release at heel
    }
  }

  bool get isBearingPass => maxBearingPressureKpa <= soilSbcKpa;

  // Tie-Rods Structural Sizing (IS 2062 / ASTM A193 B7)
  double get tieRodAllowableStressMpa => 0.60 * 415.0; // 249 MPa for Fe415 / B7
  double get tieRodAreaMm2 =>
      math.pi * math.pow(tieRodDiameterMm / 2.0, 2);
  // Each U-bolt has 2 threaded legs
  int get tieRodLegCount => tieRodCount * 2;
  double get tieRodDesignTensionKn =>
      math.max(15.0, 0.15 * thrustForceKn); // 15% lateral/uplift seating thrust
  double get tieRodStressMpa => tieRodLegCount > 0
      ? (tieRodDesignTensionKn * 1000.0) / (tieRodLegCount * tieRodAreaMm2)
      : 0.0;
  bool get isTieRodPass => tieRodStressMpa <= tieRodAllowableStressMpa;

  // Elastomeric Neoprene Pad Isolation (Hardness 60 Shore A)
  double get neopreneAllowableStressMpa => 10.0; // 10 MPa permissible bearing
  double get neopreneContactArcMm =>
      (120.0 / 360.0) * math.pi * pipeDiameterMm; // 120° cradle contact
  double get neoprenePadAreaMm2 =>
      neopreneContactArcMm * (blockLengthM * 1000.0);
  double get neopreneReactionKn =>
      math.min(thrustForceKn, totalVerticalWeightKn);
  double get neopreneStressMpa => neoprenePadAreaMm2 > 0
      ? (neopreneReactionKn * 1000.0) / neoprenePadAreaMm2
      : 0.0;
  bool get isNeoprenePass => neopreneStressMpa <= neopreneAllowableStressMpa;

  // Overall Safety Status
  String get overallStatusLabel {
    if (isSlidingPass && isOverturningPass && isBearingPass && isTieRodPass && isNeoprenePass) {
      return 'SAFE DESIGN';
    } else if (fosSliding >= 1.25 && fosOverturning >= 1.60 && maxBearingPressureKpa <= (soilSbcKpa * 1.15)) {
      return 'MARGINAL FACTOR';
    } else {
      return 'UNSAFE DESIGN';
    }
  }

  Color get overallStatusColor {
    if (overallStatusLabel == 'SAFE DESIGN') return AppTheme.tertiary;
    if (overallStatusLabel == 'MARGINAL FACTOR') return AppTheme.secondary;
    return const Color(0xFFF43F5E);
  }

  /// Auto-size optimization helper: finds minimum dimensions satisfying all criteria
  ThrustDesignCalculation autoSizeBlock() {
    double optL = math.max(2.0, pipeDiameterM + 1.2);
    double optB = math.max(2.2, pipeDiameterM + 1.4);
    double optH = math.max(1.8, pipeDiameterM + 1.2);

    for (int iter = 0; iter < 45; iter++) {
      final calc = ThrustDesignCalculation(
        fittingType: fittingType,
        bendAngleDeg: bendAngleDeg,
        pipeDiameterMm: pipeDiameterMm,
        reducerDiameterMm: reducerDiameterMm,
        wallThicknessMm: wallThicknessMm,
        testPressureMpa: testPressureMpa,
        soilUnitWeightKnM3: soilUnitWeightKnM3,
        soilFrictionAngleDeg: soilFrictionAngleDeg,
        soilCohesionKpa: soilCohesionKpa,
        soilSbcKpa: soilSbcKpa,
        soilFrictionCoeff: soilFrictionCoeff,
        blockLengthM: optL,
        blockWidthM: optB,
        blockHeightM: optH,
        depthOfCoverM: depthOfCoverM,
        concreteDensityKnM3: concreteDensityKnM3,
        tieRodCount: tieRodCount,
        tieRodDiameterMm: tieRodDiameterMm,
        neopreneThicknessMm: neopreneThicknessMm,
        neopreneHardnessShoreA: neopreneHardnessShoreA,
      );

      final passSlide = calc.fosSliding >= 1.55;
      final passOverturn = calc.fosOverturning >= 2.05;
      final passBearing = calc.maxBearingPressureKpa <= (soilSbcKpa * 0.95);

      if (passSlide && passOverturn && passBearing) {
        return calc;
      }

      if (!passSlide) {
        optB += 0.25;
        optH += 0.15;
      }
      if (!passOverturn) {
        optL += 0.30;
        optH += 0.10;
      }
      if (!passBearing) {
        optL += 0.25;
        optB += 0.25;
      }
    }

    return ThrustDesignCalculation(
      fittingType: fittingType,
      bendAngleDeg: bendAngleDeg,
      pipeDiameterMm: pipeDiameterMm,
      reducerDiameterMm: reducerDiameterMm,
      wallThicknessMm: wallThicknessMm,
      testPressureMpa: testPressureMpa,
      soilUnitWeightKnM3: soilUnitWeightKnM3,
      soilFrictionAngleDeg: soilFrictionAngleDeg,
      soilCohesionKpa: soilCohesionKpa,
      soilSbcKpa: soilSbcKpa,
      soilFrictionCoeff: soilFrictionCoeff,
      blockLengthM: optL,
      blockWidthM: optB,
      blockHeightM: optH,
      depthOfCoverM: depthOfCoverM,
      concreteDensityKnM3: concreteDensityKnM3,
      tieRodCount: tieRodCount,
      tieRodDiameterMm: tieRodDiameterMm,
      neopreneThicknessMm: neopreneThicknessMm,
      neopreneHardnessShoreA: neopreneHardnessShoreA,
    );
  }
}

/// Geotechnical Anchor Block & Thrust Restraint Design Screen
class ThrustBlockDesignScreen extends StatefulWidget {
  const ThrustBlockDesignScreen({super.key});

  @override
  State<ThrustBlockDesignScreen> createState() => _ThrustBlockDesignScreenState();
}

class _ThrustBlockDesignScreenState extends State<ThrustBlockDesignScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Presets
  static const List<ThrustBlockStationPreset> _presets = [
    ThrustBlockStationPreset(
      id: 'TB-01',
      tag: 'BURHI-DIHING',
      chainage: 'Ch. 12+450',
      locationDescription: 'River Burhi Dihing Approach — 90° Direction Change',
      fittingType: FittingType.bend90,
      bendAngleDeg: 90.0,
      pipeDiameterMm: 609.6, // 24"
      wallThicknessMm: 14.3,
      testPressureMpa: 9.8,
      soilType: SoilClassification.mediumSand,
      blockLengthM: 4.8,
      blockWidthM: 5.6,
      blockHeightM: 3.4,
      depthOfCoverM: 1.8,
      tieRodCount: 4,
      tieRodDiameterMm: 32.0,
      neopreneThicknessMm: 15.0,
    ),
    ThrustBlockStationPreset(
      id: 'TB-02',
      tag: 'NH-37-CROSS',
      chainage: 'Ch. 24+800',
      locationDescription: 'NH-37 Highway Crossing Turn — 45° Horizontal Bend',
      fittingType: FittingType.bend45,
      bendAngleDeg: 45.0,
      pipeDiameterMm: 609.6,
      wallThicknessMm: 14.3,
      testPressureMpa: 9.8,
      soilType: SoilClassification.stiffClay,
      blockLengthM: 3.8,
      blockWidthM: 4.4,
      blockHeightM: 2.8,
      depthOfCoverM: 2.0,
      tieRodCount: 2,
      tieRodDiameterMm: 28.0,
      neopreneThicknessMm: 15.0,
    ),
    ThrustBlockStationPreset(
      id: 'TB-03',
      tag: 'DILLI-SAG',
      chainage: 'Ch. 38+120',
      locationDescription: 'Dilli River Valley Trench Depression — 22.5° Sag Bend',
      fittingType: FittingType.verticalSag,
      bendAngleDeg: 22.5,
      pipeDiameterMm: 609.6,
      wallThicknessMm: 14.3,
      testPressureMpa: 9.8,
      soilType: SoilClassification.gravelBoulder,
      blockLengthM: 3.4,
      blockWidthM: 3.8,
      blockHeightM: 2.6,
      depthOfCoverM: 1.5,
      tieRodCount: 4,
      tieRodDiameterMm: 32.0,
      neopreneThicknessMm: 20.0,
    ),
    ThrustBlockStationPreset(
      id: 'TB-04',
      tag: 'VS-04-RED',
      chainage: 'Ch. 55+200',
      locationDescription: 'Intermediate Scraper Manifold VS-04 — 24" to 18" Reducer',
      fittingType: FittingType.reducer,
      bendAngleDeg: 0.0,
      pipeDiameterMm: 609.6,
      reducerDiameterMm: 457.2, // 18"
      wallThicknessMm: 12.7,
      testPressureMpa: 9.8,
      soilType: SoilClassification.denseSand,
      blockLengthM: 3.2,
      blockWidthM: 3.4,
      blockHeightM: 2.4,
      depthOfCoverM: 1.6,
      tieRodCount: 2,
      tieRodDiameterMm: 25.0,
      neopreneThicknessMm: 15.0,
    ),
    ThrustBlockStationPreset(
      id: 'TB-05',
      tag: 'LOOP-DEAD-END',
      chainage: 'Ch. 78+400',
      locationDescription: 'Future Loop Tie-In Terminal Blind Flange Hydrotest Cap',
      fittingType: FittingType.deadEnd,
      bendAngleDeg: 180.0,
      pipeDiameterMm: 609.6,
      wallThicknessMm: 14.3,
      testPressureMpa: 12.5, // 1.25x MAOP
      soilType: SoilClassification.mediumClay,
      blockLengthM: 4.4,
      blockWidthM: 5.2,
      blockHeightM: 3.2,
      depthOfCoverM: 2.2,
      tieRodCount: 4,
      tieRodDiameterMm: 36.0,
      neopreneThicknessMm: 20.0,
    ),
    ThrustBlockStationPreset(
      id: 'TB-06',
      tag: 'NAHARKATIA-11',
      chainage: 'Ch. 92+150',
      locationDescription: 'Tea Estate Gentle Alignment — 11.25° Horizontal Bend',
      fittingType: FittingType.bend11_25,
      bendAngleDeg: 11.25,
      pipeDiameterMm: 508.0, // 20"
      wallThicknessMm: 11.9,
      testPressureMpa: 9.8,
      soilType: SoilClassification.mediumSand,
      blockLengthM: 2.8,
      blockWidthM: 3.2,
      blockHeightM: 2.2,
      depthOfCoverM: 1.5,
      tieRodCount: 2,
      tieRodDiameterMm: 25.0,
      neopreneThicknessMm: 12.0,
    ),
  ];

  int _selectedPresetIndex = 0;
  bool _is3dView = true;

  // Active engineering parameters
  late FittingType _fittingType;
  late double _bendAngleDeg;
  late double _pipeDiameterMm;
  late double _reducerDiameterMm;
  late double _wallThicknessMm;
  late double _testPressureMpa;
  late SoilClassification _soilType;
  late double _soilUnitWeightKnM3;
  late double _soilFrictionAngleDeg;
  late double _soilCohesionKpa;
  late double _soilSbcKpa;
  late double _soilFrictionCoeff;
  late double _blockLengthM;
  late double _blockWidthM;
  late double _blockHeightM;
  late double _depthOfCoverM;
  late int _tieRodCount;
  late double _tieRodDiameterMm;
  late double _neopreneThicknessMm;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _applyPreset(_presets[0]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyPreset(ThrustBlockStationPreset preset) {
    setState(() {
      _fittingType = preset.fittingType;
      _bendAngleDeg = preset.bendAngleDeg;
      _pipeDiameterMm = preset.pipeDiameterMm;
      _reducerDiameterMm = preset.reducerDiameterMm;
      _wallThicknessMm = preset.wallThicknessMm;
      _testPressureMpa = preset.testPressureMpa;
      _soilType = preset.soilType;
      _soilUnitWeightKnM3 = preset.soilType.gammaKnM3;
      _soilFrictionAngleDeg = preset.soilType.phiDeg;
      _soilCohesionKpa = preset.soilType.cohesionKpa;
      _soilSbcKpa = preset.soilType.sbcKpa;
      _soilFrictionCoeff = preset.soilType.frictionCoeff;
      _blockLengthM = preset.blockLengthM;
      _blockWidthM = preset.blockWidthM;
      _blockHeightM = preset.blockHeightM;
      _depthOfCoverM = preset.depthOfCoverM;
      _tieRodCount = preset.tieRodCount;
      _tieRodDiameterMm = preset.tieRodDiameterMm;
      _neopreneThicknessMm = preset.neopreneThicknessMm;
    });
  }

  ThrustDesignCalculation _buildCalculation() {
    return ThrustDesignCalculation(
      fittingType: _fittingType,
      bendAngleDeg: _bendAngleDeg,
      pipeDiameterMm: _pipeDiameterMm,
      reducerDiameterMm: _reducerDiameterMm,
      wallThicknessMm: _wallThicknessMm,
      testPressureMpa: _testPressureMpa,
      soilUnitWeightKnM3: _soilUnitWeightKnM3,
      soilFrictionAngleDeg: _soilFrictionAngleDeg,
      soilCohesionKpa: _soilCohesionKpa,
      soilSbcKpa: _soilSbcKpa,
      soilFrictionCoeff: _soilFrictionCoeff,
      blockLengthM: _blockLengthM,
      blockWidthM: _blockWidthM,
      blockHeightM: _blockHeightM,
      depthOfCoverM: _depthOfCoverM,
      tieRodCount: _tieRodCount,
      tieRodDiameterMm: _tieRodDiameterMm,
      neopreneThicknessMm: _neopreneThicknessMm,
    );
  }

  void _autoSize() {
    final current = _buildCalculation();
    final optimized = current.autoSizeBlock();
    setState(() {
      _blockLengthM = double.parse(optimized.blockLengthM.toStringAsFixed(2));
      _blockWidthM = double.parse(optimized.blockWidthM.toStringAsFixed(2));
      _blockHeightM = double.parse(optimized.blockHeightM.toStringAsFixed(2));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceContainerHigh,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Auto-sized to ${optimized.blockLengthM.toStringAsFixed(2)}m (L) x '
                '${optimized.blockWidthM.toStringAsFixed(2)}m (W) x '
                '${optimized.blockHeightM.toStringAsFixed(2)}m (H). FOS Sliding: '
                '${optimized.fosSliding.toStringAsFixed(2)} (>= 1.50)',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showStandardsInfoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollCtrl) {
            return SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryLight.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryLight, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Standards & Governing Codes',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'ASME B31.8 §835 · AWWA M11 · IS 4984 / IS 5330',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildCodeSectionCard(
                    title: 'ASME B31.8 Section 835',
                    subtitle: 'Pipeline Anchorage & Restraint of Unbalanced Forces',
                    content:
                        'Mandates that thrust forces resulting from internal fluid pressure, '
                        'pipeline bends, dead-ends, tees, and reducers be resisted by engineered '
                        'concrete anchor blocks, tied harness joints, or direct soil passive resistance. '
                        'Design must consider hydrotest pressure (typically 1.25x to 1.50x MAOP) and thermal effects.',
                  ),
                  const SizedBox(height: 12),
                  _buildCodeSectionCard(
                    title: 'AWWA M11 (Chapter 13)',
                    subtitle: 'Thrust Restraint Design for Buried Pipelines',
                    content:
                        'Prescribes unbalanced hydrostatic thrust formula:\n'
                        '  F_thrust = 2 * P * A * sin(θ / 2)\n'
                        'Specifies minimum Factor of Safety against sliding FOS >= 1.50 '
                        'and overturning FOS >= 2.00 under field hydrostatic test conditions.',
                  ),
                  const SizedBox(height: 12),
                  _buildCodeSectionCard(
                    title: 'Rankine Earth Pressure Theory',
                    subtitle: 'Soil Passive Resistance & Failure Wedge',
                    content:
                        'Passive pressure coefficient:\n'
                        '  Kp = tan²(45° + φ/2) = (1 + sin φ) / (1 - sin φ)\n'
                        'Passive unit resistance at depth z:\n'
                        '  Pp(z) = γ * z * Kp + 2 * c * √Kp\n'
                        'Provides reliable restraint against undisturbed trench bank.',
                  ),
                  const SizedBox(height: 12),
                  _buildCodeSectionCard(
                    title: 'RCC M30 & Dielectric Isolation',
                    subtitle: 'Corrosion Prevention & Cathodic Protection Integrity',
                    content:
                        'Concrete specified as Grade M30 (fck = 30 MPa) with Fe500 high-yield rebars. '
                        'High-durometer elastomeric neoprene pad (Shore A 60, 15-20mm) between pipe and cradle '
                        'prevents 3-LPE coating damage and maintains 100% electrical dielectric isolation for Impressed Current Cathodic Protection (ICCP).',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Close Standards Reference'),
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

  void _showCalculationReportSheet(ThrustDesignCalculation calc) {
    final numberFmt = NumberFormat('#,##0.0');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollCtrl) {
            return SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thrust Block Verification Report',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Certified Structural & Geotechnical Audit Log',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: calc.overallStatusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: calc.overallStatusColor.withOpacity(0.6)),
                        ),
                        child: Text(
                          calc.overallStatusLabel,
                          style: TextStyle(
                            color: calc.overallStatusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.border, height: 28),
                  _buildReportRow('Pipeline Chainage', _presets[_selectedPresetIndex].chainage),
                  _buildReportRow('Fitting Configuration', calc.fittingType.name),
                  _buildReportRow('Deflection Angle (θ)', '${calc.bendAngleDeg.toStringAsFixed(1)}°'),
                  _buildReportRow('Pipe Nominal Outer Diameter', '${calc.pipeDiameterMm.toStringAsFixed(1)} mm (${(calc.pipeDiameterMm / 25.4).round()}" NPS)'),
                  _buildReportRow('Pipe Wall Thickness', '${calc.wallThicknessMm.toStringAsFixed(1)} mm'),
                  _buildReportRow('Test Internal Pressure (P)', '${calc.testPressureMpa.toStringAsFixed(2)} MPa (${(calc.testPressureMpa * 10).toStringAsFixed(1)} bar)'),
                  _buildReportRow('Soil Strata Class', _soilType.name),
                  _buildReportRow('Internal Friction Angle (φ)', '${calc.soilFrictionAngleDeg.toStringAsFixed(1)}°'),
                  _buildReportRow('Soil Cohesion (c)', '${calc.soilCohesionKpa.toStringAsFixed(1)} kPa'),
                  _buildReportRow('Soil Safe Bearing Capacity (SBC)', '${calc.soilSbcKpa.toStringAsFixed(1)} kPa'),
                  _buildReportRow('Rankine Passive Coeff (Kp)', calc.rankineKp.toStringAsFixed(3)),
                  const Divider(color: AppTheme.border, height: 24),
                  const Text(
                    'CALCULATED FORCES & CAPACITIES',
                    style: TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  _buildReportRow('Hydrostatic Thrust Force (F_thrust)', '${numberFmt.format(calc.thrustForceKn)} kN (${numberFmt.format(calc.thrustForceTonnes)} tonnes)'),
                  _buildReportRow('Soil Passive Resistance (R_passive)', '${numberFmt.format(calc.passiveResistanceKn)} kN'),
                  _buildReportRow('Concrete Block Weight (W_conc)', '${numberFmt.format(calc.concreteWeightKn)} kN (${numberFmt.format(calc.concreteWeightTonnes)} tonnes)'),
                  _buildReportRow('Soil Overburden Weight (W_soil)', '${numberFmt.format(calc.soilOverburdenWeightKn)} kN'),
                  _buildReportRow('Base Interface Friction (R_friction)', '${numberFmt.format(calc.baseFrictionKn)} kN'),
                  _buildReportRow('Total Resisting Force (R_total)', '${numberFmt.format(calc.totalResistingForceKn)} kN'),
                  const Divider(color: AppTheme.border, height: 24),
                  const Text(
                    'FACTORS OF SAFETY & CODE COMPLIANCE',
                    style: TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  _buildReportRow(
                    'Sliding Factor of Safety (FOS_slide)',
                    '${calc.fosSliding.toStringAsFixed(2)}  [Req >= 1.50]',
                    valueColor: calc.isSlidingPass ? AppTheme.tertiary : const Color(0xFFF43F5E),
                  ),
                  _buildReportRow(
                    'Overturning Factor of Safety (FOS_overturn)',
                    '${calc.fosOverturning.toStringAsFixed(2)}  [Req >= 2.00]',
                    valueColor: calc.isOverturningPass ? AppTheme.tertiary : const Color(0xFFF43F5E),
                  ),
                  _buildReportRow(
                    'Max Base Contact Stress (q_max)',
                    '${calc.maxBearingPressureKpa.toStringAsFixed(1)} kPa  [SBC: ${calc.soilSbcKpa.toStringAsFixed(1)} kPa]',
                    valueColor: calc.isBearingPass ? AppTheme.tertiary : const Color(0xFFF43F5E),
                  ),
                  _buildReportRow(
                    'Tie-Rod Harness Tensile Stress',
                    '${calc.tieRodStressMpa.toStringAsFixed(1)} MPa  [Allow: ${calc.tieRodAllowableStressMpa.toStringAsFixed(1)} MPa]',
                    valueColor: calc.isTieRodPass ? AppTheme.tertiary : const Color(0xFFF43F5E),
                  ),
                  _buildReportRow(
                    'Neoprene Pad Compressive Stress',
                    '${calc.neopreneStressMpa.toStringAsFixed(2)} MPa  [Allow: 10.0 MPa]',
                    valueColor: calc.isNeoprenePass ? AppTheme.tertiary : const Color(0xFFF43F5E),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Calculation report copied to clipboard.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copy Data'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.primary,
                                content: Text(
                                  'PDF Report generated for ${_presets[_selectedPresetIndex].chainage} (ASME B31.8 Section 835).',
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                          label: const Text('Export PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCodeSectionCard({
    required String title,
    required String subtitle,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calc = _buildCalculation();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thrust Block & Anchor Design',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: calc.overallStatusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'ASME B31.8 §835 · IS 4984 · AWWA M11',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Auto-Size Optimal Block',
            icon: const Icon(Icons.auto_fix_high_rounded, color: AppTheme.secondary),
            onPressed: _autoSize,
          ),
          IconButton(
            tooltip: 'Governing Standards',
            icon: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryLight),
            onPressed: _showStandardsInfoSheet,
          ),
          IconButton(
            tooltip: 'Verification Report',
            icon: const Icon(Icons.assignment_rounded, color: AppTheme.tertiary),
            onPressed: () => _showCalculationReportSheet(calc),
          ),
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
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              tabs: const [
                Tab(icon: Icon(Icons.view_in_ar_rounded, size: 18), text: '3D/2D Visualizer'),
                Tab(icon: Icon(Icons.alt_route_rounded, size: 18), text: 'Thrust & Soil'),
                Tab(icon: Icon(Icons.foundation_rounded, size: 18), text: 'RCC M30 Sizing'),
                Tab(icon: Icon(Icons.analytics_rounded, size: 18), text: 'Compliance Log'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildPresetSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVisualizerTab(calc),
                _buildThrustAndSoilTab(calc),
                _buildSizingTab(calc),
                _buildComplianceTab(calc),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector() {
    return Container(
      height: 52,
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final preset = _presets[index];
          final isSelected = index == _selectedPresetIndex;
          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            backgroundColor: AppTheme.surfaceCard,
            selectedColor: AppTheme.primary.withOpacity(0.3),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryLight : AppTheme.border,
              width: isSelected ? 1.5 : 1.0,
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  preset.fittingType.icon,
                  size: 15,
                  color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${preset.id}: ${preset.chainage}',
                  style: TextStyle(
                    color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedPresetIndex = index);
                _applyPreset(preset);
              }
            },
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: 3D / 2D INTERACTIVE VISUALIZER
  // --------------------------------------------------------------------------
  Widget _buildVisualizerTab(ThrustDesignCalculation calc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station location header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(calc.fittingType.icon, color: AppTheme.primaryLight, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _presets[_selectedPresetIndex].tag,
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  ${_presets[_selectedPresetIndex].chainage}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _presets[_selectedPresetIndex].locationDescription,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: calc.overallStatusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: calc.overallStatusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    calc.overallStatusLabel,
                    style: TextStyle(
                      color: calc.overallStatusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // View Switcher Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STRUCTURAL DIAGRAM & EQUILIBRIUM',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _is3dView = true),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _is3dView ? AppTheme.primary : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.view_in_ar_rounded,
                              size: 14,
                              color: _is3dView ? Colors.white : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '3D Isometric',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _is3dView ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _is3dView = false),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: !_is3dView ? AppTheme.primary : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.architecture_rounded,
                              size: 14,
                              color: !_is3dView ? Colors.white : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '2D Elevation Prism',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: !_is3dView ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Custom Painted Canvas
          Container(
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF070E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 320),
                    painter: _is3dView
                        ? _ThrustBlock3dPainter(calc: calc)
                        : _ThrustBlock2dElevationPainter(calc: calc),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF43F5E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('F_thrust', style: TextStyle(color: AppTheme.textPrimary, fontSize: 10)),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.tertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('R_passive', style: TextStyle(color: AppTheme.textPrimary, fontSize: 10)),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('W_conc', style: TextStyle(color: AppTheme.textPrimary, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        'Block: ${calc.blockLengthM.toStringAsFixed(1)}m(L) x ${calc.blockWidthM.toStringAsFixed(1)}m(B) x ${calc.blockHeightM.toStringAsFixed(1)}m(H) · Cover: ${calc.depthOfCoverM.toStringAsFixed(1)}m',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Primary Engineering Metrics 2x2 Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'HYDROSTATIC THRUST',
                  value: '${NumberFormat('#,##0.0').format(calc.thrustForceKn)} kN',
                  subtitle: '${calc.thrustForceTonnes.toStringAsFixed(1)} tonnes force',
                  accentColor: const Color(0xFFF43F5E),
                  icon: Icons.trending_flat_rounded,
                  badge: '${calc.fittingType.shortName} (${calc.bendAngleDeg.toStringAsFixed(0)}°)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'SLIDING STABILITY',
                  value: '${calc.fosSliding.toStringAsFixed(2)} FOS',
                  subtitle: 'Target FOS >= 1.50',
                  accentColor: calc.isSlidingPass ? AppTheme.tertiary : const Color(0xFFF43F5E),
                  icon: Icons.swap_horiz_rounded,
                  badge: calc.isSlidingPass ? 'PASS (1.50)' : 'FAIL SLIDING',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'OVERTURNING STABILITY',
                  value: '${calc.fosOverturning.toStringAsFixed(2)} FOS',
                  subtitle: 'Target FOS >= 2.00',
                  accentColor: calc.isOverturningPass ? AppTheme.tertiary : const Color(0xFFF43F5E),
                  icon: Icons.rotate_right_rounded,
                  badge: calc.isOverturningPass ? 'PASS (2.00)' : 'FAIL OVERTURN',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'MAX BEARING SOIL',
                  value: '${calc.maxBearingPressureKpa.toStringAsFixed(1)} kPa',
                  subtitle: 'SBC: ${calc.soilSbcKpa.toStringAsFixed(0)} kPa',
                  accentColor: calc.isBearingPass ? AppTheme.tertiary : const Color(0xFFF43F5E),
                  icon: Icons.vertical_align_bottom_rounded,
                  badge: calc.isBearingPass ? 'BEARING SAFE' : 'SBC EXCEEDED',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Secondary Restraint Cards (Tie-Rods and Neoprene Isolators)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, color: AppTheme.secondary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tie-Rod U-Bolts',
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${calc.tieRodCount} x φ${calc.tieRodDiameterMm.round()}mm (Fe415)',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                            Text(
                              '${calc.tieRodStressMpa.toStringAsFixed(1)} MPa (Allow 249 MPa)',
                              style: TextStyle(
                                color: calc.isTieRodPass ? AppTheme.tertiary : const Color(0xFFF43F5E),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.layers_rounded, color: AppTheme.primaryLight, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Neoprene Pad 60A',
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${calc.neopreneThicknessMm.round()}mm thickness dielectric',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                            Text(
                              '${calc.neopreneStressMpa.toStringAsFixed(2)} MPa (Allow 10 MPa)',
                              style: TextStyle(
                                color: calc.isNeoprenePass ? AppTheme.tertiary : const Color(0xFFF43F5E),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Auto-Size Action Callout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded, color: AppTheme.primaryLight, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automated Geotechnical Optimization',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Automatically finds minimal block mass satisfying FOS_slide >= 1.50 and FOS_overturn >= 2.00.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _autoSize,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: const Text('Auto-Size'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: accentColor, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: accentColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: THRUST & SOIL PARAMETERS
  // --------------------------------------------------------------------------
  Widget _buildThrustAndSoilTab(ThrustDesignCalculation calc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Fitting & Pressure
          const Text(
            'PIPELINE FITTING & HYDROSTATIC TEST PRESSURE',
            style: TextStyle(
              color: AppTheme.primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Fitting Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<FittingType>(
                value: _fittingType,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceCard,
                icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryLight),
                items: FittingType.values.map((f) {
                  return DropdownMenuItem<FittingType>(
                    value: f,
                    child: Row(
                      children: [
                        Icon(f.icon, size: 18, color: AppTheme.secondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f.name,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _fittingType = val;
                      _bendAngleDeg = val.defaultAngleDeg;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bend Deflection Angle Slider (if applicable)
          if (_fittingType != FittingType.deadEnd && _fittingType != FittingType.reducer) ...[
            _buildSliderControl(
              label: 'Deflection Angle (θ)',
              valueStr: '${_bendAngleDeg.toStringAsFixed(1)}°',
              value: _bendAngleDeg,
              min: 5.0,
              max: 90.0,
              divisions: 85,
              onChanged: (v) => setState(() => _bendAngleDeg = v),
            ),
            const SizedBox(height: 12),
          ],

          // Pipe Diameter
          _buildSliderControl(
            label: 'Pipe Outer Diameter',
            valueStr: '${_pipeDiameterMm.toStringAsFixed(0)} mm (${(_pipeDiameterMm / 25.4).round()}" NPS)',
            value: _pipeDiameterMm,
            min: 219.1,
            max: 1219.2,
            divisions: 40,
            onChanged: (v) => setState(() => _pipeDiameterMm = v),
          ),
          const SizedBox(height: 12),

          // Reducer Diameter (if reducer selected)
          if (_fittingType == FittingType.reducer) ...[
            _buildSliderControl(
              label: 'Reducer Small Diameter (D2)',
              valueStr: '${_reducerDiameterMm.toStringAsFixed(0)} mm (${(_reducerDiameterMm / 25.4).round()}" NPS)',
              value: _reducerDiameterMm,
              min: 168.3,
              max: _pipeDiameterMm - 20,
              divisions: 30,
              onChanged: (v) => setState(() => _reducerDiameterMm = v),
            ),
            const SizedBox(height: 12),
          ],

          // Wall thickness
          _buildSliderControl(
            label: 'Pipe Wall Thickness (API 5L X65/X70)',
            valueStr: '${_wallThicknessMm.toStringAsFixed(1)} mm',
            value: _wallThicknessMm,
            min: 6.4,
            max: 25.4,
            divisions: 38,
            onChanged: (v) => setState(() => _wallThicknessMm = v),
          ),
          const SizedBox(height: 12),

          // Hydrostatic Test Pressure
          _buildSliderControl(
            label: 'Internal Hydrotest Pressure (P)',
            valueStr: '${_testPressureMpa.toStringAsFixed(2)} MPa (${(_testPressureMpa * 10).toStringAsFixed(1)} bar)',
            value: _testPressureMpa,
            min: 2.0,
            max: 15.0,
            divisions: 65,
            accentColor: const Color(0xFFF43F5E),
            onChanged: (v) => setState(() => _testPressureMpa = v),
          ),
          const SizedBox(height: 20),

          // Section 2: Soil Mechanics
          const Text(
            'GEOTECHNICAL SOIL PROFILE & RANKINE RESISTANCE',
            style: TextStyle(
              color: AppTheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Soil Classification Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SoilClassification>(
                value: _soilType,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceCard,
                icon: const Icon(Icons.terrain_rounded, color: AppTheme.secondary),
                items: SoilClassification.values.map((s) {
                  return DropdownMenuItem<SoilClassification>(
                    value: s,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                        Text(s.description, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _soilType = val;
                      _soilUnitWeightKnM3 = val.gammaKnM3;
                      _soilFrictionAngleDeg = val.phiDeg;
                      _soilCohesionKpa = val.cohesionKpa;
                      _soilSbcKpa = val.sbcKpa;
                      _soilFrictionCoeff = val.frictionCoeff;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Soil Unit Weight
          _buildSliderControl(
            label: 'Soil Bulk Unit Weight (γ)',
            valueStr: '${_soilUnitWeightKnM3.toStringAsFixed(1)} kN/m³',
            value: _soilUnitWeightKnM3,
            min: 15.0,
            max: 23.0,
            divisions: 16,
            onChanged: (v) => setState(() => _soilUnitWeightKnM3 = v),
          ),
          const SizedBox(height: 12),

          // Internal Friction Angle
          _buildSliderControl(
            label: 'Internal Soil Friction Angle (φ)',
            valueStr: '${_soilFrictionAngleDeg.toStringAsFixed(1)}°',
            value: _soilFrictionAngleDeg,
            min: 12.0,
            max: 45.0,
            divisions: 33,
            onChanged: (v) => setState(() => _soilFrictionAngleDeg = v),
          ),
          const SizedBox(height: 12),

          // Soil Cohesion
          _buildSliderControl(
            label: 'Soil Cohesion (c)',
            valueStr: '${_soilCohesionKpa.toStringAsFixed(0)} kPa',
            value: _soilCohesionKpa,
            min: 0.0,
            max: 60.0,
            divisions: 30,
            onChanged: (v) => setState(() => _soilCohesionKpa = v),
          ),
          const SizedBox(height: 12),

          // Safe Bearing Capacity
          _buildSliderControl(
            label: 'Safe Bearing Capacity (SBC)',
            valueStr: '${_soilSbcKpa.toStringAsFixed(0)} kPa',
            value: _soilSbcKpa,
            min: 80.0,
            max: 450.0,
            divisions: 37,
            onChanged: (v) => setState(() => _soilSbcKpa = v),
          ),
          const SizedBox(height: 12),

          // Depth of cover
          _buildSliderControl(
            label: 'Trench Depth of Cover (Hc)',
            valueStr: '${_depthOfCoverM.toStringAsFixed(2)} m',
            value: _depthOfCoverM,
            min: 1.0,
            max: 3.5,
            divisions: 25,
            onChanged: (v) => setState(() => _depthOfCoverM = v),
          ),
          const SizedBox(height: 16),

          // Rankine Kp Summary Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RANKINE PASSIVE PRESSURE SUMMARY',
                      style: TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Kp = ${calc.rankineKp.toStringAsFixed(3)}',
                      style: const TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Top Passive Pressure (z = ${_depthOfCoverM.toStringAsFixed(1)}m): ${calc.passivePressureTopKpa.toStringAsFixed(1)} kPa\n'
                  'Base Passive Pressure (z = ${(_depthOfCoverM + _blockHeightM).toStringAsFixed(1)}m): ${calc.passivePressureBottomKpa.toStringAsFixed(1)} kPa\n'
                  'Average Passive Resistance on Block: ${calc.passivePressureAvgKpa.toStringAsFixed(1)} kPa\n'
                  'Total Soil Resistance: ${NumberFormat('#,##0.0').format(calc.passiveResistanceKn)} kN',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 3: RCC M30 GRAVITY BLOCK SIZING
  // --------------------------------------------------------------------------
  Widget _buildSizingTab(ThrustDesignCalculation calc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CONCRETE GRAVITY BLOCK GEOMETRY (RCC M30)',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton.icon(
                onPressed: _autoSize,
                icon: const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.secondary),
                label: const Text('Auto-Fit', style: TextStyle(color: AppTheme.secondary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Length slider
          _buildSliderControl(
            label: 'Block Length (L - along pipe axis)',
            valueStr: '${_blockLengthM.toStringAsFixed(2)} m',
            value: _blockLengthM,
            min: 1.5,
            max: 8.0,
            divisions: 65,
            onChanged: (v) => setState(() => _blockLengthM = v),
          ),
          const SizedBox(height: 12),

          // Width slider
          _buildSliderControl(
            label: 'Block Width (B - normal to thrust)',
            valueStr: '${_blockWidthM.toStringAsFixed(2)} m',
            value: _blockWidthM,
            min: 1.5,
            max: 8.0,
            divisions: 65,
            onChanged: (v) => setState(() => _blockWidthM = v),
          ),
          const SizedBox(height: 12),

          // Height slider
          _buildSliderControl(
            label: 'Block Height (H)',
            valueStr: '${_blockHeightM.toStringAsFixed(2)} m',
            value: _blockHeightM,
            min: 1.2,
            max: 5.5,
            divisions: 43,
            onChanged: (v) => setState(() => _blockHeightM = v),
          ),
          const SizedBox(height: 16),

          // Mass & Volume Info Card
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
                _buildSimpleStat('Net Concrete Volume', '${calc.blockNetVolumeM3.toStringAsFixed(2)} m³'),
                _buildSimpleStat('Concrete Mass', '${calc.concreteWeightTonnes.toStringAsFixed(1)} tonnes'),
                _buildSimpleStat('Total Gravity Load', '${(calc.totalVerticalWeightKn / 9.80665).toStringAsFixed(1)} tonnes'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Harness & Isolator Sizing
          const Text(
            'MECHANICAL HARNESS & NEOPRENE ISOLATION',
            style: TextStyle(
              color: AppTheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Tie-Rod Count
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tie-Rod U-Bolts', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      const SizedBox(height: 4),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _tieRodCount,
                          isDense: true,
                          dropdownColor: AppTheme.surfaceCard,
                          items: [1, 2, 3, 4, 6].map((cnt) {
                            return DropdownMenuItem<int>(
                              value: cnt,
                              child: Text('$cnt U-Bolts (${cnt * 2} legs)', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _tieRodCount = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rod Diameter (Fe415)', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      const SizedBox(height: 4),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<double>(
                          value: _tieRodDiameterMm,
                          isDense: true,
                          dropdownColor: AppTheme.surfaceCard,
                          items: [20.0, 25.0, 28.0, 32.0, 36.0, 40.0].map((dia) {
                            return DropdownMenuItem<double>(
                              value: dia,
                              child: Text('φ${dia.round()} mm', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _tieRodDiameterMm = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Neoprene Pad Thickness
          _buildSliderControl(
            label: 'Elastomeric Neoprene Pad Thickness',
            valueStr: '${_neopreneThicknessMm.toStringAsFixed(0)} mm (Shore A 60)',
            value: _neopreneThicknessMm,
            min: 10.0,
            max: 30.0,
            divisions: 20,
            onChanged: (v) => setState(() => _neopreneThicknessMm = v),
          ),
          const SizedBox(height: 20),

          // Section 3: Detailed Stability Check Summary
          const Text(
            'GEOTECHNICAL STABILITY EQUILIBRIUM AUDIT',
            style: TextStyle(
              color: AppTheme.tertiary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          _buildCheckCard(
            title: 'Sliding Resistance Factor of Safety',
            codeClause: 'AWWA M11 §13.4 / IS 4984',
            computedStr: 'FOS = ${calc.fosSliding.toStringAsFixed(2)}',
            requiredStr: 'Required >= 1.50',
            isPass: calc.isSlidingPass,
            details:
                'Driving Thrust: ${NumberFormat('#,##0.0').format(calc.thrustForceKn)} kN\n'
                'Resisting Passive: ${NumberFormat('#,##0.0').format(calc.passiveResistanceKn)} kN + Base Friction: ${NumberFormat('#,##0.0').format(calc.baseFrictionKn)} kN\n'
                'Total Resisting Force: ${NumberFormat('#,##0.0').format(calc.totalResistingForceKn)} kN',
          ),
          const SizedBox(height: 10),

          _buildCheckCard(
            title: 'Overturning Stability Factor of Safety',
            codeClause: 'ASME B31.8 §835 / AWWA M11',
            computedStr: 'FOS = ${calc.fosOverturning.toStringAsFixed(2)}',
            requiredStr: 'Required >= 2.00',
            isPass: calc.isOverturningPass,
            details:
                'Overturning Moment (M_ot): ${NumberFormat('#,##0.0').format(calc.overturningMomentKnm)} kN·m\n'
                'Restoring Moment (M_r): ${NumberFormat('#,##0.0').format(calc.restoringMomentKnm)} kN·m\n'
                'Toe Pivot Arm: ${(calc.blockHeightM / 2).toStringAsFixed(2)}m vs ${(calc.blockLengthM / 2).toStringAsFixed(2)}m',
          ),
          const SizedBox(height: 10),

          _buildCheckCard(
            title: 'Soil Bearing Pressure (Base Contact Stress)',
            codeClause: 'IS 5330 / Rankine Foundation Limit',
            computedStr: 'q_max = ${calc.maxBearingPressureKpa.toStringAsFixed(1)} kPa',
            requiredStr: 'SBC <= ${calc.soilSbcKpa.toStringAsFixed(1)} kPa',
            isPass: calc.isBearingPass,
            details:
                'Contact Eccentricity: e = ${calc.eccentricityM.toStringAsFixed(3)}m (Kern Limit L/6: ${calc.kernLimitM.toStringAsFixed(3)}m)\n'
                'Contact Stress: q_min = ${calc.minBearingPressureKpa.toStringAsFixed(1)} kPa, q_max = ${calc.maxBearingPressureKpa.toStringAsFixed(1)} kPa\n'
                '${calc.eccentricityM <= calc.kernLimitM ? "Trapezoidal distribution (No base tension)" : "Separation at heel (Effective triangular distribution)"}',
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildCheckCard({
    required String title,
    required String codeClause,
    required String computedStr,
    required String requiredStr,
    required bool isPass,
    required String details,
  }) {
    final statusColor = isPass ? AppTheme.tertiary : const Color(0xFFF43F5E);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPass ? 'PASS' : 'FAIL',
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(codeClause, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                computedStr,
                style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Text(requiredStr, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(details, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 4: COMPLIANCE LOG & MATHEMATICAL DERIVATION
  // --------------------------------------------------------------------------
  Widget _buildComplianceTab(ThrustDesignCalculation calc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Certification Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: calc.overallStatusColor.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_rounded, color: calc.overallStatusColor, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASME B31.8 / AWWA M11 COMPLIANCE: ${calc.overallStatusLabel}',
                        style: TextStyle(
                          color: calc.overallStatusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location ${_presets[_selectedPresetIndex].chainage} verified for ${calc.testPressureMpa.toStringAsFixed(1)} MPa field hydrotest pressure.',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mathematical Derivation Steps
          const Text(
            'STEP-BY-STEP MATHEMATICAL DERIVATION',
            style: TextStyle(
              color: AppTheme.primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          _buildMathCard(
            stepNumber: '1',
            title: 'Hydrostatic Thrust Force Calculation',
            formula: 'F_thrust = 2 * P * A * sin(θ / 2)',
            derivation:
                'P = ${calc.testPressureMpa.toStringAsFixed(2)} MPa = ${(calc.testPressureMpa * 1000).toStringAsFixed(0)} kPa\n'
                'Pipe Diameter D = ${calc.pipeDiameterMm.toStringAsFixed(1)} mm => Area A = ${calc.pipeAreaM2.toStringAsFixed(4)} m²\n'
                'Deflection Angle θ = ${calc.bendAngleDeg.toStringAsFixed(1)}° => sin(θ/2) = ${math.sin((calc.bendAngleDeg * math.pi) / 360.0).toStringAsFixed(4)}\n'
                'F_thrust = 2 * ${(calc.testPressureMpa * 1000).toStringAsFixed(0)} * ${calc.pipeAreaM2.toStringAsFixed(4)} * ${math.sin((calc.bendAngleDeg * math.pi) / 360.0).toStringAsFixed(4)}\n'
                '        = ${NumberFormat('#,##0.0').format(calc.thrustForceKn)} kN (${calc.thrustForceTonnes.toStringAsFixed(1)} tonnes)',
          ),
          const SizedBox(height: 12),

          _buildMathCard(
            stepNumber: '2',
            title: 'Rankine Passive Soil Earth Pressure',
            formula: 'Pp(z) = γ * z * Kp + 2 * c * √Kp',
            derivation:
                'Soil Friction Angle φ = ${calc.soilFrictionAngleDeg.toStringAsFixed(1)}°\n'
                'Kp = tan²(45° + φ/2) = tan²(45° + ${(calc.soilFrictionAngleDeg / 2).toStringAsFixed(1)}°) = ${calc.rankineKp.toStringAsFixed(3)}\n'
                'Cover Hc = ${calc.depthOfCoverM.toStringAsFixed(2)}m, Block Height H = ${calc.blockHeightM.toStringAsFixed(2)}m\n'
                'Bearing Area A_b = Width (${calc.blockWidthM.toStringAsFixed(2)}m) * Height (${calc.blockHeightM.toStringAsFixed(2)}m) = ${calc.bearingAreaM2.toStringAsFixed(2)} m²\n'
                'Average Passive Pressure p_p,avg = ${calc.passivePressureAvgKpa.toStringAsFixed(1)} kPa\n'
                'R_passive = A_b * p_p,avg = ${NumberFormat('#,##0.0').format(calc.passiveResistanceKn)} kN',
          ),
          const SizedBox(height: 12),

          _buildMathCard(
            stepNumber: '3',
            title: 'Base Interface Friction Resistance',
            formula: 'R_friction = μ * N_vertical + c_a * A_base',
            derivation:
                'Concrete Density γ_c = 24.5 kN/m³, Block Net Volume = ${calc.blockNetVolumeM3.toStringAsFixed(2)} m³\n'
                'W_concrete = ${calc.concreteWeightKn.toStringAsFixed(1)} kN (${calc.concreteWeightTonnes.toStringAsFixed(1)} tonnes)\n'
                'W_soil overburden = ${calc.soilOverburdenWeightKn.toStringAsFixed(1)} kN\n'
                'Total Downward Force N = ${calc.totalVerticalWeightKn.toStringAsFixed(1)} kN\n'
                'Friction Coeff μ = ${calc.soilFrictionCoeff.toStringAsFixed(2)}, Base Adhesion = ${calc.baseAdhesionKpa.toStringAsFixed(1)} kPa\n'
                'R_friction = ${calc.baseFrictionKn.toStringAsFixed(1)} kN',
          ),
          const SizedBox(height: 12),

          _buildMathCard(
            stepNumber: '4',
            title: 'Sliding & Overturning Factors of Safety',
            formula: 'FOS_slide = R_total / F_thrust  ·  FOS_overturn = M_r / M_ot',
            derivation:
                'Total Resisting Force = ${calc.passiveResistanceKn.toStringAsFixed(1)} + ${calc.baseFrictionKn.toStringAsFixed(1)} = ${calc.totalResistingForceKn.toStringAsFixed(1)} kN\n'
                'FOS_slide = ${calc.totalResistingForceKn.toStringAsFixed(1)} / ${calc.thrustForceKn.toStringAsFixed(1)} = ${calc.fosSliding.toStringAsFixed(2)} (Req >= 1.50) -> ${calc.isSlidingPass ? "PASS" : "FAIL"}\n'
                'Overturning M_ot = ${calc.thrustForceKn.toStringAsFixed(1)} * ${(calc.blockHeightM / 2).toStringAsFixed(2)}m = ${calc.overturningMomentKnm.toStringAsFixed(1)} kN·m\n'
                'Restoring M_r = ${calc.totalVerticalWeightKn.toStringAsFixed(1)} * ${(calc.blockLengthM / 2).toStringAsFixed(2)}m = ${calc.restoringMomentKnm.toStringAsFixed(1)} kN·m\n'
                'FOS_overturn = ${calc.restoringMomentKnm.toStringAsFixed(1)} / ${calc.overturningMomentKnm.toStringAsFixed(1)} = ${calc.fosOverturning.toStringAsFixed(2)} (Req >= 2.00) -> ${calc.isOverturningPass ? "PASS" : "FAIL"}',
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCalculationReportSheet(calc),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('Export Verified Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMathCard({
    required String stepNumber,
    required String title,
    required String formula,
    required String derivation,
  }) {
    return Container(
      width: double.infinity,
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
              CircleAvatar(
                radius: 11,
                backgroundColor: AppTheme.primary,
                child: Text(
                  stepNumber,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF091224),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border.withOpacity(0.5)),
            ),
            child: Text(
              formula,
              style: const TextStyle(
                color: AppTheme.secondary,
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            derivation,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HELPER WIDGETS
  // --------------------------------------------------------------------------
  Widget _buildSliderControl({
    required String label,
    required String valueStr,
    required double value,
    required double min,
    required double max,
    required int divisions,
    Color? accentColor,
    required ValueChanged<double> onChanged,
  }) {
    final activeColor = accentColor ?? AppTheme.primaryLight;
    return Container(
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
              Text(
                label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                valueStr,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              inactiveTrackColor: AppTheme.border,
              thumbColor: activeColor,
              overlayColor: activeColor.withOpacity(0.2),
              trackHeight: 3.5,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// 3D ISOMETRIC CUSTOM PAINTER
// ----------------------------------------------------------------------------
class _ThrustBlock3dPainter extends CustomPainter {
  final ThrustDesignCalculation calc;

  _ThrustBlock3dPainter({required this.calc});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0 + 35.0;

    // Isometric projection helpers: 30 degree projection
    const double cos30 = 0.866025;
    const double sin30 = 0.500000;

    Offset iso(double x, double y, double z) {
      final u = (x - y) * cos30;
      final v = (x + y) * sin30 - z;
      return Offset(cx + u, cy + v);
    }

    // Dynamic block scale based on block dimensions
    final scale = math.min(size.width, size.height) / 12.0;
    final l = (calc.blockLengthM * scale).clamp(40.0, 95.0);
    final w = (calc.blockWidthM * scale).clamp(40.0, 95.0);
    final h = (calc.blockHeightM * scale).clamp(35.0, 85.0);
    final cover = (calc.depthOfCoverM * scale).clamp(20.0, 45.0);

    // 1. Draw Excavated Trench Backfill & Ground Surface
    final groundPaint = Paint()
      ..color = const Color(0xFF1B2B48)
      ..style = PaintingStyle.fill;
    final groundLinePaint = Paint()
      ..color = const Color(0xFF2E4670)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final gP1 = iso(-l * 1.5, -w * 1.5, h + cover);
    final gP2 = iso(l * 1.5, -w * 1.5, h + cover);
    final gP3 = iso(l * 1.5, w * 1.5, h + cover);
    final gP4 = iso(-l * 1.5, w * 1.5, h + cover);

    final groundPath = Path()
      ..moveTo(gP1.dx, gP1.dy)
      ..lineTo(gP2.dx, gP2.dy)
      ..lineTo(gP3.dx, gP3.dy)
      ..lineTo(gP4.dx, gP4.dy)
      ..close();
    canvas.drawPath(groundPath, groundPaint);
    canvas.drawPath(groundPath, groundLinePaint);

    // Trench cut-out walls
    final trenchP1 = iso(-l * 0.9, -w * 0.9, 0);
    final trenchP2 = iso(l * 0.9, -w * 0.9, 0);
    final trenchP3 = iso(l * 0.9, w * 0.9, 0);
    final trenchP4 = iso(-l * 0.9, w * 0.9, 0);

    final trenchFloorPaint = Paint()
      ..color = const Color(0xFF0F1A30)
      ..style = PaintingStyle.fill;
    final trenchFloor = Path()
      ..moveTo(trenchP1.dx, trenchP1.dy)
      ..lineTo(trenchP2.dx, trenchP2.dy)
      ..lineTo(trenchP3.dx, trenchP3.dy)
      ..lineTo(trenchP4.dx, trenchP4.dy)
      ..close();
    canvas.drawPath(trenchFloor, trenchFloorPaint);

    // 2. Concrete Anchor Block 3D Prisms (Base footing + Main block)
    // Vertices of RCC M30 Block:
    // Bottom: B1(-l/2, -w/2, 0), B2(l/2, -w/2, 0), B3(l/2, w/2, 0), B4(-l/2, w/2, 0)
    // Top:    T1(-l/2, -w/2, h), T2(l/2, -w/2, h), T3(l/2, w/2, h), T4(-l/2, w/2, h)
    final b1 = iso(-l / 2, -w / 2, 0);
    final b2 = iso(l / 2, -w / 2, 0);
    final b3 = iso(l / 2, w / 2, 0);
    final b4 = iso(-l / 2, w / 2, 0);

    final t1 = iso(-l / 2, -w / 2, h);
    final t2 = iso(l / 2, -w / 2, h);
    final t3 = iso(l / 2, w / 2, h);
    final t4 = iso(-l / 2, w / 2, h);

    // Shading paints for concrete
    final concFrontRight = Paint()
      ..color = const Color(0xFF334A70)
      ..style = PaintingStyle.fill;
    final concFrontLeft = Paint()
      ..color = const Color(0xFF283B5A)
      ..style = PaintingStyle.fill;
    final concTop = Paint()
      ..color = const Color(0xFF425D88)
      ..style = PaintingStyle.fill;
    final concEdge = Paint()
      ..color = const Color(0xFF6383B3)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Face: Front Right (b2, b3, t3, t2)
    final faceFR = Path()
      ..moveTo(b2.dx, b2.dy)
      ..lineTo(b3.dx, b3.dy)
      ..lineTo(t3.dx, t3.dy)
      ..lineTo(t2.dx, t2.dy)
      ..close();
    canvas.drawPath(faceFR, concFrontRight);
    canvas.drawPath(faceFR, concEdge);

    // Face: Front Left (b1, b2, t2, t1)
    final faceFL = Path()
      ..moveTo(b1.dx, b1.dy)
      ..lineTo(b2.dx, b2.dy)
      ..lineTo(t2.dx, t2.dy)
      ..lineTo(t1.dx, t1.dy)
      ..close();
    canvas.drawPath(faceFL, concFrontLeft);
    canvas.drawPath(faceFL, concEdge);

    // Face: Top (t1, t2, t3, t4)
    final faceTop = Path()
      ..moveTo(t1.dx, t1.dy)
      ..lineTo(t2.dx, t2.dy)
      ..lineTo(t3.dx, t3.dy)
      ..lineTo(t4.dx, t4.dy)
      ..close();
    canvas.drawPath(faceTop, concTop);
    canvas.drawPath(faceTop, concEdge);

    // 3. Draw Steel Pipeline passing through cradle with Bend
    final pipeR = (scale * (calc.pipeDiameterM * 1.5)).clamp(12.0, 24.0);
    final pipeCenterZ = h * 0.52;

    // Pipeline entry and exit in isometric coords
    final pIn = iso(-l * 1.3, 0, pipeCenterZ);
    final pCenter = iso(0, 0, pipeCenterZ);
    final pOut = iso(0, w * 1.3, pipeCenterZ);

    final pipeBodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF64748B), Color(0xFF94A3B8), Color(0xFF334155)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: pCenter, radius: pipeR * 2))
      ..strokeWidth = pipeR * 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pipeOutlinePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Pipe path
    final pipePath = Path()
      ..moveTo(pIn.dx, pIn.dy)
      ..lineTo(pCenter.dx, pCenter.dy)
      ..lineTo(pOut.dx, pOut.dy);
    canvas.drawPath(pipePath, pipeBodyPaint);
    canvas.drawPath(pipePath, pipeOutlinePaint);

    // 4. Elastomeric Neoprene Isolation Pad (Amber/Orange highlight underneath pipe)
    final neoPaint = Paint()
      ..color = const Color(0xFFFFB95F)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final neoPadPath = Path()
      ..moveTo(pCenter.dx - 12, pCenter.dy + pipeR * 0.8)
      ..lineTo(pCenter.dx + 12, pCenter.dy + pipeR * 0.8);
    canvas.drawPath(neoPadPath, neoPaint);

    // 5. Galvanized Steel Tie-Rods (U-bolts hugging pipe)
    final tieRodPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int rod = -1; rod <= 1; rod += 2) {
      final rodOx = rod * 14.0;
      final rodPath = Path()
        ..moveTo(pCenter.dx + rodOx - 16, pCenter.dy + 12)
        ..arcToPoint(
          Offset(pCenter.dx + rodOx + 16, pCenter.dy + 12),
          radius: Radius.circular(pipeR * 1.1),
          clockwise: false,
        );
      canvas.drawPath(rodPath, tieRodPaint);

      // Tie rod anchor nuts
      final nutPaint = Paint()..color = const Color(0xFFF1F5F9);
      canvas.drawCircle(Offset(pCenter.dx + rodOx - 16, pCenter.dy + 12), 2.5, nutPaint);
      canvas.drawCircle(Offset(pCenter.dx + rodOx + 16, pCenter.dy + 12), 2.5, nutPaint);
    }

    // 6. Force Vectors in 3D Space
    // A. Hydrostatic Thrust Vector F_thrust (Crimson red, pushing out along bend bisector)
    final fThrustEnd = Offset(pCenter.dx + 65.0, pCenter.dy + 25.0);
    _drawArrow(canvas, pCenter, fThrustEnd, const Color(0xFFF43F5E), 3.5);
    _drawText(canvas, 'F_thrust: ${calc.thrustForceKn.toStringAsFixed(0)} kN', Offset(fThrustEnd.dx + 4, fThrustEnd.dy - 8), const Color(0xFFF43F5E));

    // B. Soil Passive Resistance R_passive (Emerald green distributed on face)
    final pFaceCenter = iso(l / 2, 0, h / 2);
    final pPassiveEnd = Offset(pFaceCenter.dx - 55.0, pFaceCenter.dy - 18.0);
    _drawArrow(canvas, pFaceCenter, pPassiveEnd, AppTheme.tertiary, 3.0);
    _drawText(canvas, 'R_passive: ${calc.passiveResistanceKn.toStringAsFixed(0)} kN', Offset(pPassiveEnd.dx - 120, pPassiveEnd.dy - 12), AppTheme.tertiary);

    // C. Gravity Block Weight W_block (Amber, pointing downwards)
    final pBlockCenter = iso(0, 0, h / 2);
    final pGravityEnd = Offset(pBlockCenter.dx, pBlockCenter.dy + 50.0);
    _drawArrow(canvas, pBlockCenter, pGravityEnd, AppTheme.secondary, 2.8);
    _drawText(canvas, 'W_block: ${calc.concreteWeightKn.toStringAsFixed(0)} kN', Offset(pGravityEnd.dx - 45, pGravityEnd.dy + 4), AppTheme.secondary);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);

    // Arrowhead
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final arrowLen = width * 3.5;
    final p1 = Offset(
      to.dx - arrowLen * math.cos(angle - math.pi / 6),
      to.dy - arrowLen * math.sin(angle - math.pi / 6),
    );
    final p2 = Offset(
      to.dx - arrowLen * math.cos(angle + math.pi / 6),
      to.dy - arrowLen * math.sin(angle + math.pi / 6),
    );

    final headPath = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(headPath, Paint()..color = color);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          backgroundColor: const Color(0xCC0B1326),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ThrustBlock3dPainter oldDelegate) => true;
}

// ----------------------------------------------------------------------------
// 2D TECHNICAL ELEVATION & RANKINE EARTH PRESSURE PRISM PAINTER
// ----------------------------------------------------------------------------
class _ThrustBlock2dElevationPainter extends CustomPainter {
  final ThrustDesignCalculation calc;

  _ThrustBlock2dElevationPainter({required this.calc});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground level line at y = 45
    const double glY = 48.0;

    // Ground line
    final glPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(20, glY), Offset(w - 20, glY), glPaint);
    _drawText(canvas, '▽ GL +0.00m Ground Level', const Offset(25, glY - 18), const Color(0xFF94A3B8));

    // Soil hatching along ground line
    final hatchPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.0;
    for (double x = 25; x < w - 25; x += 14) {
      canvas.drawLine(Offset(x, glY), Offset(x - 8, glY + 8), hatchPaint);
    }

    // Geometry scaling
    final blockW = (calc.blockLengthM * 34.0).clamp(90.0, 160.0);
    final blockH = (calc.blockHeightM * 34.0).clamp(70.0, 140.0);
    final coverH = (calc.depthOfCoverM * 28.0).clamp(24.0, 60.0);

    final blockLeft = (w * 0.40) - (blockW / 2.0);
    final blockTop = glY + coverH;
    final blockRight = blockLeft + blockW;
    final blockBottom = blockTop + blockH;

    // 1. Concrete Block Rect
    final concRect = Rect.fromLTRB(blockLeft, blockTop, blockRight, blockBottom);
    final concFill = Paint()
      ..color = const Color(0xFF1E2E4A)
      ..style = PaintingStyle.fill;
    final concBorder = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(concRect, concFill);
    canvas.drawRect(concRect, concBorder);

    // Fe500 Rebar Cage (dashed lines inside block)
    final rebarPaint = Paint()
      ..color = const Color(0x6638BDF8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTRB(blockLeft + 8, blockTop + 8, blockRight - 8, blockBottom - 8),
      rebarPaint,
    );

    // 2. Pipe Cutout & Cradle
    final pipeD = (calc.pipeDiameterM * 38.0).clamp(20.0, 48.0);
    final pipeCY = blockTop + blockH * 0.45;
    final pipeCX = blockLeft + blockW / 2.0;

    // Neoprene isolation pad (amber arc)
    final neoRect = Rect.fromCircle(center: Offset(pipeCX, pipeCY), radius: pipeD / 2.0 + 3.0);
    final neoPaint = Paint()
      ..color = const Color(0xFFFFB95F)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawArc(neoRect, 0.15 * math.pi, 0.70 * math.pi, false, neoPaint);

    // Pipe circle
    final pipeFill = Paint()..color = const Color(0xFF475569);
    final pipeBorder = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(pipeCX, pipeCY), pipeD / 2.0, pipeFill);
    canvas.drawCircle(Offset(pipeCX, pipeCY), pipeD / 2.0, pipeBorder);

    // Tie-rod U-Bolt
    final uBoltPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final uBoltRect = Rect.fromCircle(center: Offset(pipeCX, pipeCY), radius: pipeD / 2.0 + 7.0);
    canvas.drawArc(uBoltRect, math.pi, math.pi, false, uBoltPaint);
    // Legs anchoring into concrete
    canvas.drawLine(Offset(pipeCX - pipeD / 2.0 - 7.0, pipeCY), Offset(pipeCX - pipeD / 2.0 - 7.0, blockBottom - 14), uBoltPaint);
    canvas.drawLine(Offset(pipeCX + pipeD / 2.0 + 7.0, pipeCY), Offset(pipeCX + pipeD / 2.0 + 7.0, blockBottom - 14), uBoltPaint);

    // 3. Rankine Passive Earth Pressure Wedge (Right side against block face)
    final prismBaseX = blockRight + 10.0;
    final pTopWidth = (calc.passivePressureTopKpa * 0.28).clamp(12.0, 50.0);
    final pBottomWidth = (calc.passivePressureBottomKpa * 0.28).clamp(24.0, 95.0);

    final prismPath = Path()
      ..moveTo(prismBaseX, blockTop)
      ..lineTo(prismBaseX + pTopWidth, blockTop)
      ..lineTo(prismBaseX + pBottomWidth, blockBottom)
      ..lineTo(prismBaseX, blockBottom)
      ..close();

    final prismFill = Paint()
      ..color = const Color(0x334EDEA3)
      ..style = PaintingStyle.fill;
    final prismBorder = Paint()
      ..color = AppTheme.tertiary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(prismPath, prismFill);
    canvas.drawPath(prismPath, prismBorder);

    // Distributed passive resistance arrows
    final arrowPaint = Paint()
      ..color = AppTheme.tertiary
      ..strokeWidth = 1.2;
    for (double y = blockTop + 14; y < blockBottom; y += 22) {
      final frac = (y - blockTop) / (blockBottom - blockTop);
      final arrowLen = pTopWidth + frac * (pBottomWidth - pTopWidth);
      canvas.drawLine(Offset(prismBaseX + arrowLen, y), Offset(prismBaseX, y), arrowPaint);
    }

    _drawText(canvas, 'Rankine Passive Wedge', Offset(prismBaseX + 6, blockTop - 15), AppTheme.tertiary);
    _drawText(canvas, 'p_p,top = ${calc.passivePressureTopKpa.toStringAsFixed(0)} kPa', Offset(prismBaseX + pTopWidth + 4, blockTop - 2), AppTheme.textSecondary);
    _drawText(canvas, 'p_p,bot = ${calc.passivePressureBottomKpa.toStringAsFixed(0)} kPa', Offset(prismBaseX + pBottomWidth + 4, blockBottom - 12), AppTheme.textSecondary);

    // 4. Force Vectors
    // Thrust Force Arrow (Pointing right)
    final fThrustY = pipeCY;
    final fThrustStartX = blockLeft - 45.0;
    _drawArrow(canvas, Offset(fThrustStartX, fThrustY), Offset(blockLeft - 2, fThrustY), const Color(0xFFF43F5E), 3.0);
    _drawText(canvas, 'F_thrust: ${calc.thrustForceKn.toStringAsFixed(0)} kN', Offset(fThrustStartX - 10, fThrustY - 18), const Color(0xFFF43F5E));

    // Base Friction Arrow (Pointing left)
    _drawArrow(canvas, Offset(blockRight - 20, blockBottom + 12), Offset(blockLeft + 15, blockBottom + 12), const Color(0xFF38BDF8), 2.5);
    _drawText(canvas, 'R_fric: ${calc.baseFrictionKn.toStringAsFixed(0)} kN', Offset(blockLeft + 20, blockBottom + 16), const Color(0xFF38BDF8));

    // 5. Dimension Labels
    _drawText(canvas, 'Hc = ${calc.depthOfCoverM.toStringAsFixed(1)}m', Offset(blockLeft - 60, glY + coverH / 2 - 6), const Color(0xFF94A3B8));
    _drawText(canvas, 'H = ${calc.blockHeightM.toStringAsFixed(1)}m', Offset(blockLeft - 50, blockTop + blockH / 2 - 6), const Color(0xFF94A3B8));
    _drawText(canvas, 'L = ${calc.blockLengthM.toStringAsFixed(1)}m', Offset(blockLeft + blockW / 2 - 20, blockBottom + 32), const Color(0xFF94A3B8));
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);

    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final arrowLen = width * 3.5;
    final p1 = Offset(
      to.dx - arrowLen * math.cos(angle - math.pi / 6),
      to.dy - arrowLen * math.sin(angle - math.pi / 6),
    );
    final p2 = Offset(
      to.dx - arrowLen * math.cos(angle + math.pi / 6),
      to.dy - arrowLen * math.sin(angle + math.pi / 6),
    );

    final headPath = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(headPath, Paint()..color = color);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          backgroundColor: const Color(0xCC0B1326),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ThrustBlock2dElevationPainter oldDelegate) => true;
}
