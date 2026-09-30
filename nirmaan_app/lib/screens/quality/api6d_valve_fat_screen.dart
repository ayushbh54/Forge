import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS — API 6D / ISO 14313 / ASME B16.34 / EN 10204 3.1
// ============================================================================

/// Factory Acceptance Testing execution status
enum FatTestStatus {
  notStarted,
  inProgress,
  passed,
  failed,
  certified,
}

extension FatTestStatusExt on FatTestStatus {
  String get label {
    switch (this) {
      case FatTestStatus.notStarted:
        return 'TEST PENDING';
      case FatTestStatus.inProgress:
        return 'TEST IN PROGRESS';
      case FatTestStatus.passed:
        return 'PASSED (RATE A)';
      case FatTestStatus.failed:
        return 'REJECTED / LEAKAGE';
      case FatTestStatus.certified:
        return 'CERTIFIED & STAMPED';
    }
  }

  Color get color {
    switch (this) {
      case FatTestStatus.notStarted:
        return AppTheme.textMuted;
      case FatTestStatus.inProgress:
        return AppTheme.secondary;
      case FatTestStatus.passed:
        return AppTheme.tertiary;
      case FatTestStatus.failed:
        return const Color(0xFFFF5252);
      case FatTestStatus.certified:
        return const Color(0xFF38BDF8);
    }
  }

  IconData get icon {
    switch (this) {
      case FatTestStatus.notStarted:
        return Icons.hourglass_empty_rounded;
      case FatTestStatus.inProgress:
        return Icons.sync_rounded;
      case FatTestStatus.passed:
        return Icons.check_circle_rounded;
      case FatTestStatus.failed:
        return Icons.cancel_rounded;
      case FatTestStatus.certified:
        return Icons.verified_rounded;
    }
  }
}

/// Valve Cavity and Seating Configuration per API 6D
enum ValveCavityConfig {
  dbb, // Double Block and Bleed (SPE / SPE)
  dib1, // Double Isolation and Bleed Type 1 (DPE / DPE)
  dib2, // Double Isolation and Bleed Type 2 (SPE / DPE)
}

extension ValveCavityConfigExt on ValveCavityConfig {
  String get code {
    switch (this) {
      case ValveCavityConfig.dbb:
        return 'DBB';
      case ValveCavityConfig.dib1:
        return 'DIB-1';
      case ValveCavityConfig.dib2:
        return 'DIB-2';
    }
  }

  String get title {
    switch (this) {
      case ValveCavityConfig.dbb:
        return 'Double Block & Bleed (SPE / SPE)';
      case ValveCavityConfig.dib1:
        return 'Double Isolation & Bleed 1 (DPE / DPE)';
      case ValveCavityConfig.dib2:
        return 'Double Isolation & Bleed 2 (SPE / DPE)';
    }
  }

  String get upstreamSeat {
    switch (this) {
      case ValveCavityConfig.dbb:
        return 'SPE (Single Piston Effect - Self-Relieving)';
      case ValveCavityConfig.dib1:
        return 'DPE (Double Piston Effect - Bi-Directional)';
      case ValveCavityConfig.dib2:
        return 'SPE (Single Piston Effect - Upstream Relieving)';
    }
  }

  String get downstreamSeat {
    switch (this) {
      case ValveCavityConfig.dbb:
        return 'SPE (Single Piston Effect - Self-Relieving)';
      case ValveCavityConfig.dib1:
        return 'DPE (Double Piston Effect - Bi-Directional)';
      case ValveCavityConfig.dib2:
        return 'DPE (Double Piston Effect - Downstream Barrier)';
    }
  }

  String get cavityReliefDescription {
    switch (this) {
      case ValveCavityConfig.dbb:
        return 'Automatic cavity overpressure self-relief into pipeline bore when cavity pressure exceeds line pressure by spring threshold (~1.5 Bar).';
      case ValveCavityConfig.dib1:
        return 'Mandatory external/internal Cavity Relief Valve (CRV) set at 1.1x to 1.33x design pressure (~118 Bar) because both seats trap pressure.';
      case ValveCavityConfig.dib2:
        return 'Automatic self-relief through upstream SPE seat ring. Downstream DPE seat maintains tight downstream pipeline seal regardless of cavity pressure.';
    }
  }
}

/// MTC EN 10204 Type 3.1 Certification endorsement state
enum MtcCertificationStatus {
  draft,
  mfgApproved,
  fullyEndorsed,
}

extension MtcCertificationStatusExt on MtcCertificationStatus {
  String get label {
    switch (this) {
      case MtcCertificationStatus.draft:
        return 'DRAFT CERTIFICATE';
      case MtcCertificationStatus.mfgApproved:
        return 'MFG SIGNED (AWAITING TPIA)';
      case MtcCertificationStatus.fullyEndorsed:
        return 'EN 10204 3.1 DUAL ENDORSED';
    }
  }

  Color get color {
    switch (this) {
      case MtcCertificationStatus.draft:
        return AppTheme.textMuted;
      case MtcCertificationStatus.mfgApproved:
        return AppTheme.secondary;
      case MtcCertificationStatus.fullyEndorsed:
        return AppTheme.tertiary;
    }
  }
}

/// Hydrostatic Shell Test Data Model (1.5 x Design Pressure = 147.0 Bar for 15 min)
class HydroShellTestData {
  final double targetPressureBar; // 147.0 Bar
  final int holdDurationMinutes; // 15 min
  final double actualPressureBar; // 147.2 Bar
  final double initialPressureBar; // 147.4 Bar
  final double finalPressureBar; // 147.2 Bar
  final double maxDeflectionMm; // 0.014 mm
  final double allowableDeflectionMm; // 0.050 mm
  final double waterTempC; // 21.4°C
  final double ambientTempC; // 26.2°C
  final bool throughWallLeak; // false
  final bool stemGlandLeak; // false
  final FatTestStatus status;
  final List<FlSpot> pressureProfile;

  const HydroShellTestData({
    required this.targetPressureBar,
    required this.holdDurationMinutes,
    required this.actualPressureBar,
    required this.initialPressureBar,
    required this.finalPressureBar,
    required this.maxDeflectionMm,
    required this.allowableDeflectionMm,
    required this.waterTempC,
    required this.ambientTempC,
    required this.throughWallLeak,
    required this.stemGlandLeak,
    required this.status,
    required this.pressureProfile,
  });

  bool get isDeformationCompliant => maxDeflectionMm <= allowableDeflectionMm;
  bool get isZeroLeakage => !throughWallLeak && !stemGlandLeak;
  double get pressureDeltaBar => (finalPressureBar - initialPressureBar).abs();
}

/// High-Pressure Hydrostatic Seat Test Data Model (1.1 x Design Pressure = 107.8 Bar)
class HighPressureSeatTestData {
  final double targetPressureBar; // 107.8 Bar
  final int holdDurationMinutes; // 5 min per seat
  final double seatAPressureBar; // 107.9 Bar (Upstream)
  final double seatBPressureBar; // 107.8 Bar (Downstream)
  final int seatALeakRateDrops; // 0 drops/min
  final int seatBLeakRateDrops; // 0 drops/min
  final bool rateACompliance; // true (Zero detectable drops)
  final String cavityBleedStatus; // "Dry / Zero Bleed"
  final FatTestStatus status;

  const HighPressureSeatTestData({
    required this.targetPressureBar,
    required this.holdDurationMinutes,
    required this.seatAPressureBar,
    required this.seatBPressureBar,
    required this.seatALeakRateDrops,
    required this.seatBLeakRateDrops,
    required this.rateACompliance,
    required this.cavityBleedStatus,
    required this.status,
  });

  bool get isCompliant =>
      rateACompliance &&
      seatALeakRateDrops == 0 &&
      seatBLeakRateDrops == 0;
}

/// Low-Pressure Pneumatic Air Seat Test Data Model (5.5 to 7.0 Bar)
class LowPressureAirSeatTestData {
  final double targetPressureBar; // 6.0 Bar
  final double minAcceptableBar; // 5.5 Bar
  final double maxAcceptableBar; // 7.0 Bar
  final double actualPressureBar; // 6.2 Bar
  final int holdDurationMinutes; // 5 min
  final int immersionWaterDepthMm; // 300 mm
  final int bubblesPerMinute; // 0
  final int allowableBubbles; // 0 (Rate A)
  final FatTestStatus status;

  const LowPressureAirSeatTestData({
    required this.targetPressureBar,
    required this.minAcceptableBar,
    required this.maxAcceptableBar,
    required this.actualPressureBar,
    required this.holdDurationMinutes,
    required this.immersionWaterDepthMm,
    required this.bubblesPerMinute,
    required this.allowableBubbles,
    required this.status,
  });

  bool get isCompliant =>
      actualPressureBar >= minAcceptableBar &&
      actualPressureBar <= maxAcceptableBar &&
      bubblesPerMinute <= allowableBubbles;
}

/// Cavity Relief Verification Data Model (DBB & DIB-1 / DIB-2)
class CavityReliefVerificationData {
  final double nominalReliefSetBar; // 118.0 Bar (1.20x Design Pressure)
  final double crackingPressureBar; // 117.6 Bar
  final double reseatPressureBar; // 111.4 Bar
  final double blowdownPercent; // 5.27%
  final String cavityReliefDirection; // Upstream bore or external bypass
  final FatTestStatus status;

  const CavityReliefVerificationData({
    required this.nominalReliefSetBar,
    required this.crackingPressureBar,
    required this.reseatPressureBar,
    required this.blowdownPercent,
    required this.cavityReliefDirection,
    required this.status,
  });

  bool get isCrackingCompliant =>
      crackingPressureBar >= 107.8 && crackingPressureBar <= 127.4; // 1.1x to 1.3x
}

/// Torque & Operating Cycle Test Data Model under Full Differential Pressure (100 Bar)
class TorqueCycleTestData {
  final double differentialPressureBar; // 100.0 Bar
  final double breakawayOpenTorqueNm; // 7,850 Nm
  final double breakawayCloseTorqueNm; // 8,120 Nm
  final double runningTorqueNm; // 2,450 Nm
  final double seatingTorqueNm; // 7,200 Nm
  final double mastNm; // 14,500 Nm (Maximum Allowable Stem Torque)
  final double actuatorOutputTorqueNm; // 12,500 Nm
  final double safetyFactor; // 12,500 / 8,120 = 1.54
  final int completedCycles; // 3 full cycles under 100 Bar DP
  final List<double> cycleTimesSec; // [14.2, 13.8, 14.0]
  final double maxAllowableStrokeTimeSec; // 15.0 sec (ESD criteria)
  final List<FlSpot> torqueAngleProfile; // 0 deg to 90 deg vs Nm

  const TorqueCycleTestData({
    required this.differentialPressureBar,
    required this.breakawayOpenTorqueNm,
    required this.breakawayCloseTorqueNm,
    required this.runningTorqueNm,
    required this.seatingTorqueNm,
    required this.mastNm,
    required this.actuatorOutputTorqueNm,
    required this.safetyFactor,
    required this.completedCycles,
    required this.cycleTimesSec,
    required this.maxAllowableStrokeTimeSec,
    required this.torqueAngleProfile,
  });

  bool get isMastCompliant =>
      breakawayOpenTorqueNm < mastNm && breakawayCloseTorqueNm < mastNm;
  bool get isSafetyFactorCompliant => safetyFactor >= 1.50;
  bool get isEsdTimingCompliant =>
      cycleTimesSec.every((t) => t <= maxAllowableStrokeTimeSec);
}

/// MTC EN 10204 Type 3.1 Digital Inspection Certificate Model
class MtcInspectionCertificate {
  final String certNumber;
  final String heatNumberBody;
  final String heatNumberBall;
  final String heatNumberStem;
  final String heatNumberSeatRings;
  final Map<String, String> chemicalCompositionBody;
  final Map<String, String> mechanicalPropertiesBody;
  final Map<String, String> ndtExamResults;
  final String mfgSignatoryName;
  final String mfgSignatoryTitle;
  final bool mfgSigned;
  final DateTime? mfgSignedAt;
  final String tpiaSignatoryName;
  final String tpiaSignatoryTitle;
  final String tpiaAgency;
  final bool tpiaSigned;
  final DateTime? tpiaSignedAt;
  final String certSha256Digest;
  final MtcCertificationStatus status;

  const MtcInspectionCertificate({
    required this.certNumber,
    required this.heatNumberBody,
    required this.heatNumberBall,
    required this.heatNumberStem,
    required this.heatNumberSeatRings,
    required this.chemicalCompositionBody,
    required this.mechanicalPropertiesBody,
    required this.ndtExamResults,
    required this.mfgSignatoryName,
    required this.mfgSignatoryTitle,
    required this.mfgSigned,
    this.mfgSignedAt,
    required this.tpiaSignatoryName,
    required this.tpiaSignatoryTitle,
    required this.tpiaAgency,
    required this.tpiaSigned,
    this.tpiaSignedAt,
    required this.certSha256Digest,
    required this.status,
  });

  MtcInspectionCertificate copyWith({
    bool? mfgSigned,
    DateTime? mfgSignedAt,
    bool? tpiaSigned,
    DateTime? tpiaSignedAt,
    String? certSha256Digest,
    MtcCertificationStatus? status,
  }) {
    return MtcInspectionCertificate(
      certNumber: certNumber,
      heatNumberBody: heatNumberBody,
      heatNumberBall: heatNumberBall,
      heatNumberStem: heatNumberStem,
      heatNumberSeatRings: heatNumberSeatRings,
      chemicalCompositionBody: chemicalCompositionBody,
      mechanicalPropertiesBody: mechanicalPropertiesBody,
      ndtExamResults: ndtExamResults,
      mfgSignatoryName: mfgSignatoryName,
      mfgSignatoryTitle: mfgSignatoryTitle,
      mfgSigned: mfgSigned ?? this.mfgSigned,
      mfgSignedAt: mfgSignedAt ?? this.mfgSignedAt,
      tpiaSignatoryName: tpiaSignatoryName,
      tpiaSignatoryTitle: tpiaSignatoryTitle,
      tpiaAgency: tpiaAgency,
      tpiaSigned: tpiaSigned ?? this.tpiaSigned,
      tpiaSignedAt: tpiaSignedAt ?? this.tpiaSignedAt,
      certSha256Digest: certSha256Digest ?? this.certSha256Digest,
      status: status ?? this.status,
    );
  }
}

/// 24" Class 600 Pipeline Ball Valve FAT Item Model
class ValveFatItem {
  final String id;
  final String valveTag;
  final String serialNumber;
  final String stationLocation;
  final int nominalDiameterInch; // 24"
  final String pressureClass; // Class 600 (PN 100)
  final double designPressureBar; // 98.0 Bar
  final ValveCavityConfig cavityConfig;
  final String bodyMaterial; // ASTM A350 LF2 Cl.1
  final String ballMaterial; // ASTM A182 F51 Duplex Stainless
  final String stemMaterial; // ASTM A564 Type 630 (17-4PH H1150M)
  final String seatInsertMaterial; // Devlon V-API + Inconel X-750
  final String endConnection; // Butt Weld ASME B16.25 (15.9mm WT)
  final double faceToFaceMm; // 1143 mm
  final double valveWeightKg; // 4850 kg
  final String actuatorTag; // Rotork Skilmatic SI-3 EH
  final FatTestStatus overallFatStatus;
  final HydroShellTestData hydroShellData;
  final HighPressureSeatTestData hpSeatData;
  final LowPressureAirSeatTestData lpAirSeatData;
  final CavityReliefVerificationData cavityReliefData;
  final TorqueCycleTestData torqueData;
  final MtcInspectionCertificate certificate;

  const ValveFatItem({
    required this.id,
    required this.valveTag,
    required this.serialNumber,
    required this.stationLocation,
    required this.nominalDiameterInch,
    required this.pressureClass,
    required this.designPressureBar,
    required this.cavityConfig,
    required this.bodyMaterial,
    required this.ballMaterial,
    required this.stemMaterial,
    required this.seatInsertMaterial,
    required this.endConnection,
    required this.faceToFaceMm,
    required this.valveWeightKg,
    required this.actuatorTag,
    required this.overallFatStatus,
    required this.hydroShellData,
    required this.hpSeatData,
    required this.lpAirSeatData,
    required this.cavityReliefData,
    required this.torqueData,
    required this.certificate,
  });

  ValveFatItem copyWith({
    FatTestStatus? overallFatStatus,
    HydroShellTestData? hydroShellData,
    HighPressureSeatTestData? hpSeatData,
    LowPressureAirSeatTestData? lpAirSeatData,
    CavityReliefVerificationData? cavityReliefData,
    TorqueCycleTestData? torqueData,
    MtcInspectionCertificate? certificate,
  }) {
    return ValveFatItem(
      id: id,
      valveTag: valveTag,
      serialNumber: serialNumber,
      stationLocation: stationLocation,
      nominalDiameterInch: nominalDiameterInch,
      pressureClass: pressureClass,
      designPressureBar: designPressureBar,
      cavityConfig: cavityConfig,
      bodyMaterial: bodyMaterial,
      ballMaterial: ballMaterial,
      stemMaterial: stemMaterial,
      seatInsertMaterial: seatInsertMaterial,
      endConnection: endConnection,
      faceToFaceMm: faceToFaceMm,
      valveWeightKg: valveWeightKg,
      actuatorTag: actuatorTag,
      overallFatStatus: overallFatStatus ?? this.overallFatStatus,
      hydroShellData: hydroShellData ?? this.hydroShellData,
      hpSeatData: hpSeatData ?? this.hpSeatData,
      lpAirSeatData: lpAirSeatData ?? this.lpAirSeatData,
      cavityReliefData: cavityReliefData ?? this.cavityReliefData,
      torqueData: torqueData ?? this.torqueData,
      certificate: certificate ?? this.certificate,
    );
  }
}

// ============================================================================
// REPOSITORY / MOCK DATA GENERATOR — OIL INDIA LIMITED PIPELINE PROJECT
// ============================================================================

class Api6dValveRepository {
  static String computeSha256Hash({
    required String serialNumber,
    required String valveTag,
    required double shellBar,
    required double hpSeatBar,
    required double lpAirBar,
    required double torqueNm,
    required String heatBody,
    required bool mfgSigned,
    required bool tpiaSigned,
  }) {
    final raw = '$serialNumber|$valveTag|SHELL:$shellBar|HP:$hpSeatBar|LP:$lpAirBar|'
        'TORQUE:$torqueNm|HEAT:$heatBody|MFG:$mfgSigned|TPIA:$tpiaSigned';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  static List<ValveFatItem> getSampleValves() {
    return [
      // 1. VS-01 Sectionalizing Valve (Duliajan Dispatch)
      _createValve(
        id: 'VALVE-01',
        valveTag: '24"-MOV-VS01',
        serialNumber: 'LTV-2026-600-0841',
        stationLocation: 'VS-01 Duliajan Station (Ch 00+000)',
        cavityConfig: ValveCavityConfig.dbb,
        heatBody: 'H-9428-A',
        heatBall: 'H-6104-D',
        heatStem: 'H-7719-S',
        heatSeat: 'H-8210-R',
        shellBar: 147.2,
        hpSeatBar: 107.9,
        lpAirBar: 6.2,
        crackingBar: 117.6,
        reseatBar: 111.4,
        breakawayOpenNm: 7850,
        breakawayCloseNm: 8120,
        mfgSigned: true,
        tpiaSigned: true,
        overallStatus: FatTestStatus.certified,
      ),

      // 2. VS-02 Burhi Dihing River Crossing Isolation Valve (DIB-1)
      _createValve(
        id: 'VALVE-02',
        valveTag: '24"-MOV-VS02',
        serialNumber: 'LTV-2026-600-0842',
        stationLocation: 'VS-02 Burhi Dihing North Bank (Ch 14+850)',
        cavityConfig: ValveCavityConfig.dib1,
        heatBody: 'H-9428-B',
        heatBall: 'H-6104-E',
        heatStem: 'H-7719-S',
        heatSeat: 'H-8210-S',
        shellBar: 147.1,
        hpSeatBar: 107.8,
        lpAirBar: 6.1,
        crackingBar: 118.2,
        reseatBar: 112.0,
        breakawayOpenNm: 7920,
        breakawayCloseNm: 8250,
        mfgSigned: true,
        tpiaSigned: true,
        overallStatus: FatTestStatus.certified,
      ),

      // 3. VS-03 Moran Compressor Station Emergency Shutdown Valve (DIB-2)
      _createValve(
        id: 'VALVE-03',
        valveTag: '24"-ESV-VS03',
        serialNumber: 'LTV-2026-600-0843',
        stationLocation: 'VS-03 Moran Compressor Station (Ch 32+400)',
        cavityConfig: ValveCavityConfig.dib2,
        heatBody: 'H-9430-A',
        heatBall: 'H-6106-A',
        heatStem: 'H-7721-A',
        heatSeat: 'H-8212-A',
        shellBar: 147.3,
        hpSeatBar: 107.9,
        lpAirBar: 6.0,
        crackingBar: 116.8,
        reseatBar: 110.5,
        breakawayOpenNm: 7780,
        breakawayCloseNm: 8090,
        mfgSigned: true,
        tpiaSigned: false, // Awaiting TPIA witness
        overallStatus: FatTestStatus.passed,
      ),

      // 4. VS-04 Sivasagar Mainline Sectionalizing Valve (DBB)
      _createValve(
        id: 'VALVE-04',
        valveTag: '24"-MOV-VS04',
        serialNumber: 'LTV-2026-600-0844',
        stationLocation: 'VS-04 Sivasagar Sector (Ch 54+200)',
        cavityConfig: ValveCavityConfig.dbb,
        heatBody: 'H-9430-B',
        heatBall: 'H-6106-B',
        heatStem: 'H-7721-B',
        heatSeat: 'H-8212-B',
        shellBar: 147.0,
        hpSeatBar: 107.8,
        lpAirBar: 6.2,
        crackingBar: 117.2,
        reseatBar: 111.0,
        breakawayOpenNm: 7910,
        breakawayCloseNm: 8180,
        mfgSigned: false,
        tpiaSigned: false,
        overallStatus: FatTestStatus.inProgress,
      ),

      // 5. VS-05 Numaligarh Terminal Scraper Trap Receiver Valve (DIB-1)
      _createValve(
        id: 'VALVE-05',
        valveTag: '24"-MOV-VS05',
        serialNumber: 'LTV-2026-600-0845',
        stationLocation: 'VS-05 Numaligarh Terminal (Ch 94+500)',
        cavityConfig: ValveCavityConfig.dib1,
        heatBody: 'H-9432-A',
        heatBall: 'H-6108-A',
        heatStem: 'H-7723-A',
        heatSeat: 'H-8214-A',
        shellBar: 147.2,
        hpSeatBar: 107.9,
        lpAirBar: 6.3,
        crackingBar: 118.5,
        reseatBar: 112.4,
        breakawayOpenNm: 8010,
        breakawayCloseNm: 8320,
        mfgSigned: false,
        tpiaSigned: false,
        overallStatus: FatTestStatus.notStarted,
      ),
    ];
  }

  static ValveFatItem _createValve({
    required String id,
    required String valveTag,
    required String serialNumber,
    required String stationLocation,
    required ValveCavityConfig cavityConfig,
    required String heatBody,
    required String heatBall,
    required String heatStem,
    required String heatSeat,
    required double shellBar,
    required double hpSeatBar,
    required double lpAirBar,
    required double crackingBar,
    required double reseatBar,
    required double breakawayOpenNm,
    required double breakawayCloseNm,
    required bool mfgSigned,
    required bool tpiaSigned,
    required FatTestStatus overallStatus,
  }) {
    // 15-minute hydrostatic shell pressure curve spots
    final shellProfile = <FlSpot>[
      const FlSpot(0, 0),
      const FlSpot(1, 40),
      const FlSpot(2, 90),
      const FlSpot(3, 147.4),
      const FlSpot(5, 147.3),
      const FlSpot(7, 147.3),
      const FlSpot(9, 147.2),
      const FlSpot(11, 147.2),
      const FlSpot(13, 147.2),
      const FlSpot(15, 147.2),
      const FlSpot(18, 147.2), // Hold completion
    ];

    // Torque curve: 0 deg (closed breakaway) -> 45 deg (running) -> 90 deg (open)
    final torqueProfile = <FlSpot>[
      FlSpot(0, breakawayCloseNm),
      const FlSpot(5, 5400),
      const FlSpot(15, 2450),
      const FlSpot(30, 2400),
      const FlSpot(45, 2450),
      const FlSpot(60, 2500),
      const FlSpot(75, 2800),
      const FlSpot(85, 6100),
      FlSpot(90, breakawayOpenNm),
    ];

    final certHash = computeSha256Hash(
      serialNumber: serialNumber,
      valveTag: valveTag,
      shellBar: shellBar,
      hpSeatBar: hpSeatBar,
      lpAirBar: lpAirBar,
      torqueNm: breakawayCloseNm,
      heatBody: heatBody,
      mfgSigned: mfgSigned,
      tpiaSigned: tpiaSigned,
    );

    final certStatus = (mfgSigned && tpiaSigned)
        ? MtcCertificationStatus.fullyEndorsed
        : mfgSigned
            ? MtcCertificationStatus.mfgApproved
            : MtcCertificationStatus.draft;

    return ValveFatItem(
      id: id,
      valveTag: valveTag,
      serialNumber: serialNumber,
      stationLocation: stationLocation,
      nominalDiameterInch: 24,
      pressureClass: 'Class 600',
      designPressureBar: 98.0,
      cavityConfig: cavityConfig,
      bodyMaterial: 'ASTM A350 LF2 Class 1 (LTCS)',
      ballMaterial: 'ASTM A182 F51 Duplex Stainless',
      stemMaterial: 'ASTM A564 Gr 630 (17-4PH H1150M)',
      seatInsertMaterial: 'Devlon V-API + Inconel X-750',
      endConnection: 'Butt Weld ASME B16.25 (15.9mm WT)',
      faceToFaceMm: 1143.0,
      valveWeightKg: 4850.0,
      actuatorTag: 'Rotork Skilmatic SI-3 EH (Gas-over-Oil)',
      overallFatStatus: overallStatus,
      hydroShellData: HydroShellTestData(
        targetPressureBar: 147.0,
        holdDurationMinutes: 15,
        actualPressureBar: shellBar,
        initialPressureBar: 147.4,
        finalPressureBar: shellBar,
        maxDeflectionMm: 0.014,
        allowableDeflectionMm: 0.050,
        waterTempC: 21.4,
        ambientTempC: 26.2,
        throughWallLeak: false,
        stemGlandLeak: false,
        status: FatTestStatus.passed,
        pressureProfile: shellProfile,
      ),
      hpSeatData: HighPressureSeatTestData(
        targetPressureBar: 107.8,
        holdDurationMinutes: 5,
        seatAPressureBar: hpSeatBar,
        seatBPressureBar: 107.8,
        seatALeakRateDrops: 0,
        seatBLeakRateDrops: 0,
        rateACompliance: true,
        cavityBleedStatus: 'Completely Dry / 0 Drops',
        status: FatTestStatus.passed,
      ),
      lpAirSeatData: LowPressureAirSeatTestData(
        targetPressureBar: 6.0,
        minAcceptableBar: 5.5,
        maxAcceptableBar: 7.0,
        actualPressureBar: lpAirBar,
        holdDurationMinutes: 5,
        immersionWaterDepthMm: 300,
        bubblesPerMinute: 0,
        allowableBubbles: 0,
        status: FatTestStatus.passed,
      ),
      cavityReliefData: CavityReliefVerificationData(
        nominalReliefSetBar: 118.0,
        crackingPressureBar: crackingBar,
        reseatPressureBar: reseatBar,
        blowdownPercent: 5.27,
        cavityReliefDirection: cavityConfig == ValveCavityConfig.dbb
            ? 'Automatic SPE Self-Relief to Line'
            : 'CRV Overpressure Relief to Flare/Upstream',
        status: FatTestStatus.passed,
      ),
      torqueData: TorqueCycleTestData(
        differentialPressureBar: 100.0,
        breakawayOpenTorqueNm: breakawayOpenNm,
        breakawayCloseTorqueNm: breakawayCloseNm,
        runningTorqueNm: 2450.0,
        seatingTorqueNm: 7200.0,
        mastNm: 14500.0,
        actuatorOutputTorqueNm: 12500.0,
        safetyFactor: 1.54,
        completedCycles: 3,
        cycleTimesSec: const [14.2, 13.8, 14.0],
        maxAllowableStrokeTimeSec: 15.0,
        torqueAngleProfile: torqueProfile,
      ),
      certificate: MtcInspectionCertificate(
        certNumber: 'MTC-EN10204-3.1-2026-$serialNumber',
        heatNumberBody: heatBody,
        heatNumberBall: heatBall,
        heatNumberStem: heatStem,
        heatNumberSeatRings: heatSeat,
        chemicalCompositionBody: const {
          'C': '0.18%',
          'Mn': '1.15%',
          'Si': '0.28%',
          'P': '0.012%',
          'S': '0.008%',
          'Ni': '0.35%',
          'CE': '0.38',
        },
        mechanicalPropertiesBody: const {
          'Tensile Strength': '580 MPa',
          'Yield Strength': '365 MPa',
          'Elongation (A5)': '28.5%',
          'Charpy V-Notch (-46°C)': '52 Joules (Avg)',
          'Hardness': '187 HBW (<= 22 HRC)',
        },
        ndtExamResults: const {
          '100% Volumetric RT/UT': 'ACCEPTABLE per ASME VIII Div 1 App 4',
          '100% Magnetic Particle (MT)': 'ACCEPTABLE per ASME VIII Div 1 App 6',
          '100% Liquid Penetrant (PT)': 'ACCEPTABLE per ASME VIII Div 1 App 8',
          'Visual & Dimensional': 'COMPLIANT to API 6D Table C.3',
        },
        mfgSignatoryName: 'Er. S. Rajendran',
        mfgSignatoryTitle: 'Quality Assurance Manager (L&T Valves)',
        mfgSigned: mfgSigned,
        mfgSignedAt: mfgSigned ? DateTime(2026, 9, 28, 14, 30) : null,
        tpiaSignatoryName: 'Er. Anirban Mukherjee',
        tpiaSignatoryTitle: 'Lead Pipeline QC Inspector',
        tpiaAgency: 'Engineers India Limited (EIL TPIA)',
        tpiaSigned: tpiaSigned,
        tpiaSignedAt: tpiaSigned ? DateTime(2026, 9, 28, 16, 45) : null,
        certSha256Digest: certHash,
        status: certStatus,
      ),
    );
  }
}

// ============================================================================
// MAIN FLUTTER SCREEN WIDGET
// ============================================================================

class Api6dValveFatScreen extends StatefulWidget {
  const Api6dValveFatScreen({super.key});

  @override
  State<Api6dValveFatScreen> createState() => _Api6dValveFatScreenState();
}

class _Api6dValveFatScreenState extends State<Api6dValveFatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<ValveFatItem> _valves;
  int _selectedValveIndex = 0;

  // Real-time Hydro Shell Simulation state
  bool _isSimulatingShellTest = false;
  double _simulatedPressureBar = 147.2;
  int _simulatedHoldMinutes = 15;
  Timer? _simulationTimer;

  // DBB / DIB interactive visualizer demo toggles
  ValveCavityConfig _demoCavityConfig = ValveCavityConfig.dbb;
  bool _demoUpstreamPressure = true;
  bool _demoDownstreamPressure = false;
  bool _demoCavityOverpressure = false;

  ValveFatItem get _currentValve => _valves[_selectedValveIndex];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _valves = Api6dValveRepository.getSampleValves();
    _demoCavityConfig = _currentValve.cavityConfig;
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onValveChanged(int newIndex) {
    if (newIndex >= 0 && newIndex < _valves.length) {
      setState(() {
        _selectedValveIndex = newIndex;
        _demoCavityConfig = _valves[newIndex].cavityConfig;
        _isSimulatingShellTest = false;
      });
      _simulationTimer?.cancel();
    }
  }

  void _startShellTestSimulation() {
    if (_isSimulatingShellTest) return;

    setState(() {
      _isSimulatingShellTest = true;
      _simulatedPressureBar = 0.0;
      _simulatedHoldMinutes = 0;
    });

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) return;
      setState(() {
        if (_simulatedPressureBar < 147.0) {
          _simulatedPressureBar += 24.5;
          if (_simulatedPressureBar > 147.2) _simulatedPressureBar = 147.2;
        } else if (_simulatedHoldMinutes < 15) {
          _simulatedHoldMinutes += 3;
        } else {
          // Simulation complete
          timer.cancel();
          _isSimulatingShellTest = false;
          _showFeedbackSnackbar(
            'API 6D 15-Minute Shell Hold Successfully Completed (147.2 Bar • Zero Deformation)',
            AppTheme.tertiary,
          );
        }
      });
    });
  }

  void _toggleMfgSignature() {
    final v = _currentValve;
    final newSigned = !v.certificate.mfgSigned;
    final now = newSigned ? DateTime.now() : null;

    final newHash = Api6dValveRepository.computeSha256Hash(
      serialNumber: v.serialNumber,
      valveTag: v.valveTag,
      shellBar: v.hydroShellData.actualPressureBar,
      hpSeatBar: v.hpSeatData.seatAPressureBar,
      lpAirBar: v.lpAirSeatData.actualPressureBar,
      torqueNm: v.torqueData.breakawayCloseTorqueNm,
      heatBody: v.certificate.heatNumberBody,
      mfgSigned: newSigned,
      tpiaSigned: v.certificate.tpiaSigned,
    );

    final newStatus = (newSigned && v.certificate.tpiaSigned)
        ? MtcCertificationStatus.fullyEndorsed
        : newSigned
            ? MtcCertificationStatus.mfgApproved
            : MtcCertificationStatus.draft;

    final updatedCert = v.certificate.copyWith(
      mfgSigned: newSigned,
      mfgSignedAt: now,
      certSha256Digest: newHash,
      status: newStatus,
    );

    setState(() {
      _valves[_selectedValveIndex] = v.copyWith(
        certificate: updatedCert,
        overallFatStatus: newStatus == MtcCertificationStatus.fullyEndorsed
            ? FatTestStatus.certified
            : FatTestStatus.passed,
      );
    });

    HapticFeedback.lightImpact();
    _showFeedbackSnackbar(
      newSigned
          ? 'Manufacturer Sign-Off Recorded (SHA-256 Seal Updated)'
          : 'Manufacturer Sign-Off Revoked',
      newSigned ? AppTheme.secondary : AppTheme.textMuted,
    );
  }

  void _toggleTpiaSignature() {
    final v = _currentValve;
    final newSigned = !v.certificate.tpiaSigned;
    final now = newSigned ? DateTime.now() : null;

    final newHash = Api6dValveRepository.computeSha256Hash(
      serialNumber: v.serialNumber,
      valveTag: v.valveTag,
      shellBar: v.hydroShellData.actualPressureBar,
      hpSeatBar: v.hpSeatData.seatAPressureBar,
      lpAirBar: v.lpAirSeatData.actualPressureBar,
      torqueNm: v.torqueData.breakawayCloseTorqueNm,
      heatBody: v.certificate.heatNumberBody,
      mfgSigned: v.certificate.mfgSigned,
      tpiaSigned: newSigned,
    );

    final newStatus = (v.certificate.mfgSigned && newSigned)
        ? MtcCertificationStatus.fullyEndorsed
        : v.certificate.mfgSigned
            ? MtcCertificationStatus.mfgApproved
            : MtcCertificationStatus.draft;

    final updatedCert = v.certificate.copyWith(
      tpiaSigned: newSigned,
      tpiaSignedAt: now,
      certSha256Digest: newHash,
      status: newStatus,
    );

    setState(() {
      _valves[_selectedValveIndex] = v.copyWith(
        certificate: updatedCert,
        overallFatStatus: newStatus == MtcCertificationStatus.fullyEndorsed
            ? FatTestStatus.certified
            : FatTestStatus.passed,
      );
    });

    HapticFeedback.heavyImpact();
    _showFeedbackSnackbar(
      newSigned
          ? 'EIL / TPIA Dual Endorsement Sealed (EN 10204 Type 3.1 Fully Certified)'
          : 'TPIA Endorsement Revoked',
      newSigned ? AppTheme.tertiary : AppTheme.textMuted,
    );
  }

  void _showFeedbackSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: color.withValues(alpha: 0.9),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showStandardsInfoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.border, width: 1.5),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => _buildStandardsInfoContent(scrollController),
      ),
    );
  }

  void _showExportDossierModal() {
    showDialog(
      context: context,
      builder: (ctx) => _buildExportDossierDialog(ctx),
    );
  }

  // ==========================================================================
  // BUILD METHOD & ROOT SCAFFOLD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final valve = _currentValve;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('API 6D Valve FAT & Hydro'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.primary, width: 0.8),
                  ),
                  child: const Text(
                    'ISO 14313',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '24" Class 600 TMBV • 147 Bar Shell • Rate A Seat • EN 10204 3.1',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'API 6D Testing Standards',
            onPressed: _showStandardsInfoModal,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export FAT Inspection Dossier',
            onPressed: _showExportDossierModal,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Top KPI Summary Metrics Bar
          _buildKpiSummaryBar(valve),

          // 2. Horizontal Valve Selector Carousel
          _buildValveSelectorRail(),

          // 3. Tab Navigation Bar
          Container(
            color: AppTheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.primaryLight,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'Valve Spec & Heats'),
                Tab(icon: Icon(Icons.water_drop_outlined, size: 18), text: 'Hydro Shell & Seat'),
                Tab(icon: Icon(Icons.alt_route_rounded, size: 18), text: 'DBB / DIB Cavity'),
                Tab(icon: Icon(Icons.speed_rounded, size: 18), text: 'Torque & Cycles'),
                Tab(icon: Icon(Icons.verified_user_outlined, size: 18), text: 'MTC 3.1 Certificate'),
              ],
            ),
          ),

          // 4. TabBar Views Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildValveSpecTab(valve),
                _buildHydroShellSeatTab(valve),
                _buildDbbDibCavityTab(valve),
                _buildTorqueCyclesTab(valve),
                _buildMtcCertificateTab(valve),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TOP KPI SUMMARY BAR
  // ==========================================================================

  Widget _buildKpiSummaryBar(ValveFatItem valve) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          // Shell Test KPI
          Expanded(
            child: _buildMetricTile(
              label: 'HYDRO SHELL (1.5x)',
              value: '${valve.hydroShellData.actualPressureBar.toStringAsFixed(1)} Bar',
              subtext: 'Target: 147.0 Bar • 15 min',
              icon: Icons.shield_rounded,
              color: AppTheme.primaryLight,
            ),
          ),
          Container(width: 1, height: 38, color: AppTheme.border),
          // HP Seat KPI
          Expanded(
            child: _buildMetricTile(
              label: 'HP SEAT (1.1x)',
              value: '${valve.hpSeatData.seatAPressureBar.toStringAsFixed(1)} Bar',
              subtext: 'Rate A: 0 drops/min',
              icon: Icons.check_circle_outline_rounded,
              color: AppTheme.tertiary,
            ),
          ),
          Container(width: 1, height: 38, color: AppTheme.border),
          // LP Pneumatic Air KPI
          Expanded(
            child: _buildMetricTile(
              label: 'LP AIR SEAT (6 Bar)',
              value: '${valve.lpAirSeatData.actualPressureBar.toStringAsFixed(1)} Bar',
              subtext: '0 bubbles / 5 min',
              icon: Icons.air_rounded,
              color: AppTheme.secondary,
            ),
          ),
          Container(width: 1, height: 38, color: AppTheme.border),
          // MTC 3.1 Status
          Expanded(
            child: _buildMetricTile(
              label: 'MTC EN 10204 3.1',
              value: valve.certificate.status == MtcCertificationStatus.fullyEndorsed
                  ? 'ENDORSED'
                  : valve.certificate.status == MtcCertificationStatus.mfgApproved
                      ? 'MFG ONLY'
                      : 'PENDING',
              subtext: 'Dual QA/QC Sign-off',
              icon: valve.certificate.status.color == AppTheme.tertiary
                  ? Icons.verified_rounded
                  : Icons.pending_actions_rounded,
              color: valve.certificate.status.color,
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
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // VALVE SELECTOR CAROUSEL
  // ==========================================================================

  Widget _buildValveSelectorRail() {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.8)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _valves.length,
        itemBuilder: (context, index) {
          final v = _valves[index];
          final isSelected = index == _selectedValveIndex;

          return GestureDetector(
            onTap: () => _onValveChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.18)
                    : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    v.overallFatStatus.icon,
                    size: 16,
                    color: v.overallFatStatus.color,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            v.valveTag,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              v.cavityConfig.code,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'S/N: ${v.serialNumber}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // TAB 1: VALVE SPEC & MATERIAL HEATS
  // ==========================================================================

  Widget _buildValveSpecTab(ValveFatItem valve) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Valve Identification Card
        _buildCard(
          title: 'VALVE GENERAL SPECIFICATION',
          subtitle: 'API 6D 25th Edition / ISO 14313 • Full Bore Trunnion Ball Valve',
          icon: Icons.precision_manufacturing_rounded,
          child: Column(
            children: [
              _buildSpecRow('Valve Tag & Asset ID', valve.valveTag, 'Station Location', valve.stationLocation),
              const Divider(color: AppTheme.border, height: 16),
              _buildSpecRow('Serial Number', valve.serialNumber, 'Nominal Size & Rating', '24" Class 600 (DN 600 PN 100)'),
              const Divider(color: AppTheme.border, height: 16),
              _buildSpecRow('Design Pressure', '${valve.designPressureBar} Bar (9.80 MPa)', 'Face-to-Face Dim.', '${valve.faceToFaceMm.toInt()} mm (B16.10 Long)'),
              const Divider(color: AppTheme.border, height: 16),
              _buildSpecRow('End Connection', valve.endConnection, 'Total Valve Mass', '${valve.valveWeightKg.toInt()} kg (Dry Body)'),
              const Divider(color: AppTheme.border, height: 16),
              _buildSpecRow('Cavity & Seating', valve.cavityConfig.title, 'Actuator Model', valve.actuatorTag),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. MTC Material Heats & Metallurgy
        _buildCard(
          title: 'METALLURGY & MTC EN 10204 3.1 HEAT NUMBERS',
          subtitle: 'Traceable Mill Test Certs • NACE MR0175 / ISO 15156 Sour Gas Compliant',
          icon: Icons.science_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildHeatTile(
                      component: 'Body / Closures',
                      material: valve.bodyMaterial,
                      heatNumber: valve.certificate.heatNumberBody,
                      accentColor: AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeatTile(
                      component: 'Trunnion Ball',
                      material: valve.ballMaterial,
                      heatNumber: valve.certificate.heatNumberBall,
                      accentColor: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildHeatTile(
                      component: 'Drive Stem',
                      material: valve.stemMaterial,
                      heatNumber: valve.certificate.heatNumberStem,
                      accentColor: AppTheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeatTile(
                      component: 'Seat Retainer Rings',
                      material: valve.seatInsertMaterial,
                      heatNumber: valve.certificate.heatNumberSeatRings,
                      accentColor: const Color(0xFFA78BFA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Chemical Analysis Table
              const Text(
                'Body Forging Chemical Analysis (Heat: H-9428-A):',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: valve.certificate.chemicalCompositionBody.entries.map((e) {
                    return Column(
                      children: [
                        Text(e.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
                        const SizedBox(height: 2),
                        Text(e.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              // Mechanical Test Results Table
              const Text(
                'Mechanical Test Results (Body Specimen @ -46°C Impact):',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              ...valve.certificate.mechanicalPropertiesBody.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. Fire Safe & Secondary Sealing Architecture
        _buildCard(
          title: 'SAFETY INTEGRITY & EMERGENCY PROVISIONS',
          subtitle: 'API 6FA Fire Safe Certified • Secondary Sealant Injection & Anti-Static',
          icon: Icons.shield_outlined,
          child: Column(
            children: [
              _buildFeatureChecklistRow(
                'API 6FA / ISO 10497 Fire Safe',
                'Graphite secondary bonnet & stem seals rated for 30-min burn at 1000°C',
                true,
              ),
              const Divider(color: AppTheme.border, height: 16),
              _buildFeatureChecklistRow(
                'Emergency Sealant Injection Ports',
                'Giant Button Head grease fittings with internal check valves on both seats & stem',
                true,
              ),
              const Divider(color: AppTheme.border, height: 16),
              _buildFeatureChecklistRow(
                'Anti-Static Grounding Continuity',
                'Stem-to-ball & stem-to-body spring-loaded balls (< 10 Ohms per API 6D Cl. 5.9)',
                true,
              ),
              const Divider(color: AppTheme.border, height: 16),
              _buildFeatureChecklistRow(
                'Cavity Body Vent & Drain Plug',
                '1/2" NPT drain valve with blind plug for DBB proving & cavity purging',
                true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeatTile({
    required String component,
    required String material,
    required String heatNumber,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            component,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            material,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                'Heat: $heatNumber',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(value1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(value2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChecklistRow(String title, String description, bool isVerified) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isVerified ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: isVerified ? AppTheme.tertiary : AppTheme.textMuted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 2: HYDROSTATIC SHELL & SEAT TESTS
  // ==========================================================================

  Widget _buildHydroShellSeatTab(ValveFatItem valve) {
    final shell = valve.hydroShellData;
    final hpSeat = valve.hpSeatData;
    final lpAir = valve.lpAirSeatData;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Hydrostatic Shell Test Card (1.5x Design Pressure)
        _buildCard(
          title: 'HYDROSTATIC SHELL TEST (1.5 x DESIGN PRESSURE)',
          subtitle: 'Target: 147.0 Bar for 15 min • API 6D Cl. 9.3 • Zero Permanent Deformation',
          icon: Icons.water_drop_rounded,
          action: ElevatedButton.icon(
            onPressed: _isSimulatingShellTest ? null : _startShellTestSimulation,
            icon: Icon(
              _isSimulatingShellTest ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded,
              size: 16,
            ),
            label: Text(_isSimulatingShellTest ? 'Testing...' : 'Run Simulation'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: AppTheme.primary,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Digital Gauge Meters Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDigitalGauge(
                      label: 'ACTUAL PRESSURE',
                      value: _isSimulatingShellTest
                          ? '${_simulatedPressureBar.toStringAsFixed(1)} Bar'
                          : '${shell.actualPressureBar.toStringAsFixed(1)} Bar',
                      color: AppTheme.primaryLight,
                      subtext: 'Req: >= 147.0 Bar',
                    ),
                    Container(width: 1, height: 44, color: AppTheme.border),
                    _buildDigitalGauge(
                      label: 'HOLD TIME',
                      value: _isSimulatingShellTest
                          ? '$_simulatedHoldMinutes / 15 min'
                          : '${shell.holdDurationMinutes}:00 min',
                      color: AppTheme.secondary,
                      subtext: 'Min: 15 min (Table 5)',
                    ),
                    Container(width: 1, height: 44, color: AppTheme.border),
                    _buildDigitalGauge(
                      label: 'DEFLECTION (DIAL)',
                      value: '${shell.maxDeflectionMm.toStringAsFixed(3)} mm',
                      color: AppTheme.tertiary,
                      subtext: 'Max: 0.050 mm',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 15-Minute Hydrostatic Pressure Chart
              const Text(
                'Live Chart Recorder Telemetry (Pressure vs Hold Time):',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 30,
                      verticalInterval: 3,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: AppTheme.border.withValues(alpha: 0.5),
                        strokeWidth: 0.8,
                      ),
                      getDrawingVerticalLine: (v) => FlLine(
                        color: AppTheme.border.withValues(alpha: 0.3),
                        strokeWidth: 0.8,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: 50,
                          getTitlesWidget: (v, meta) => Text(
                            '${v.toInt()}B',
                            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 3,
                          getTitlesWidget: (v, meta) => Text(
                            '${v.toInt()}m',
                            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: AppTheme.border),
                    ),
                    minX: 0,
                    maxX: 18,
                    minY: 0,
                    maxY: 180,
                    lineBarsData: [
                      LineChartBarData(
                        spots: shell.pressureProfile,
                        isCurved: false,
                        color: AppTheme.primaryLight,
                        barWidth: 2.5,
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.primaryLight.withValues(alpha: 0.12),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                      // 147 Bar Threshold line
                      LineChartBarData(
                        spots: const [FlSpot(0, 147.0), FlSpot(18, 147.0)],
                        isCurved: false,
                        color: const Color(0xFFFF5252).withValues(alpha: 0.7),
                        barWidth: 1.2,
                        dashArray: [4, 4],
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Visual Inspection Confirmation
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 18, color: AppTheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Visual Shell Verification: Zero through-wall seepage, zero flange gasket sweating, zero stem gland weepage observed during 15-minute soak.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withValues(alpha: 0.9)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. High-Pressure Hydrostatic Seat Test (1.1x Design Pressure = 107.8 Bar)
        _buildCard(
          title: 'HIGH-PRESSURE HYDROSTATIC SEAT TEST (1.1x)',
          subtitle: 'API 6D Cl. 9.4 • 107.8 Bar • Rate A (Zero Detectable Bubble / Drop Leakage)',
          icon: Icons.verified_user_rounded,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSeatTestResultCard(
                      seatName: 'Upstream Seat (A)',
                      appliedPressureBar: hpSeat.seatAPressureBar,
                      targetBar: 107.8,
                      leakRateDrops: hpSeat.seatALeakRateDrops,
                      holdTimeMin: hpSeat.holdDurationMinutes,
                      isRateA: hpSeat.rateACompliance,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSeatTestResultCard(
                      seatName: 'Downstream Seat (B)',
                      appliedPressureBar: hpSeat.seatBPressureBar,
                      targetBar: 107.8,
                      leakRateDrops: hpSeat.seatBLeakRateDrops,
                      holdTimeMin: hpSeat.holdDurationMinutes,
                      isRateA: hpSeat.rateACompliance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Body Cavity Bleed Port Drain:', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hpSeat.cavityBleedStatus,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.tertiary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. Low-Pressure Pneumatic Air Seat Test (6.0 Bar)
        _buildCard(
          title: 'LOW-PRESSURE PNEUMATIC AIR SEAT TEST (6.0 Bar)',
          subtitle: 'API 6D Cl. 9.5 • 5.5 to 7.0 Bar Dry Air / N2 Under Water • < 0 bubbles/min',
          icon: Icons.bubble_chart_rounded,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPneumaticTile(
                      label: 'PNEUMATIC TEST PRESSURE',
                      value: '${lpAir.actualPressureBar.toStringAsFixed(1)} Bar',
                      statusText: 'Within 5.5 to 7.0 Bar Window',
                      isOk: lpAir.isCompliant,
                      icon: Icons.speed_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPneumaticTile(
                      label: 'BUBBLE DETECTOR READING',
                      value: '${lpAir.bubblesPerMinute} Bubbles / min',
                      statusText: 'API 6D Rate A Zero Leakage',
                      isOk: lpAir.bubblesPerMinute <= lpAir.allowableBubbles,
                      icon: Icons.filter_drama_rounded,
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
                    const Icon(Icons.water_rounded, size: 18, color: AppTheme.primaryLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Detection Method: Valve submerged under ${lpAir.immersionWaterDepthMm} mm water column in immersion testing tank with calibrated bubble displacement tube connected to bleed port.',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDigitalGauge({
    required String label,
    required String value,
    required Color color,
    required String subtext,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.3),
        ),
        Text(subtext, style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildSeatTestResultCard({
    required String seatName,
    required double appliedPressureBar,
    required double targetBar,
    required int leakRateDrops,
    required int holdTimeMin,
    required bool isRateA,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(seatName, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Icon(
                isRateA ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 15,
                color: isRateA ? AppTheme.tertiary : const Color(0xFFFF5252),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Applied Pressure:', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
              Text('${appliedPressureBar.toStringAsFixed(1)} Bar', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hold Duration:', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
              Text('$holdTimeMin min', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Measured Leakage:', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
              Text('$leakRateDrops drops/min', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isRateA ? AppTheme.tertiary : const Color(0xFFFF5252))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPneumaticTile({
    required String label,
    required String value,
    required String statusText,
    required bool isOk,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: isOk ? AppTheme.tertiary : const Color(0xFFFF5252)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isOk ? AppTheme.textPrimary : const Color(0xFFFF5252))),
          const SizedBox(height: 2),
          Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isOk ? AppTheme.tertiary : const Color(0xFFFF5252))),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: DBB / DIB CAVITY RELIEF VERIFICATION
  // ==========================================================================

  Widget _buildDbbDibCavityTab(ValveFatItem valve) {
    final cavity = valve.cavityReliefData;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Interactive Cavity Seating Configuration Selector
        _buildCard(
          title: 'CAVITY SEALING MECHANISM INTERACTIVE VERIFICATION',
          subtitle: 'API 6D Section 5.8 & Annex B • SPE vs DPE Physics Demonstration',
          icon: Icons.layers_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Buttons for DBB, DIB-1, DIB-2
              Row(
                children: ValveCavityConfig.values.map((cfg) {
                  final isSelected = cfg == _demoCavityConfig;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _demoCavityConfig = cfg;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.25)
                              : AppTheme.surfaceContainerHigh.withValues(alpha: 0.3),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          cfg.code,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Configuration Summary Text
              Text(
                _demoCavityConfig.title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
              ),
              const SizedBox(height: 4),
              Text(
                _demoCavityConfig.cavityReliefDescription,
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),

              const SizedBox(height: 14),

              // Interactive Pressure Vector Diagram
              _buildCavityPhysicsSchematic(),

              const SizedBox(height: 14),

              // Interactive pressure control switches
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInteractiveToggle(
                    'Upstream (98 Bar)',
                    _demoUpstreamPressure,
                    (val) => setState(() => _demoUpstreamPressure = val),
                  ),
                  _buildInteractiveToggle(
                    'Downstream (0 Bar)',
                    _demoDownstreamPressure,
                    (val) => setState(() => _demoDownstreamPressure = val),
                  ),
                  _buildInteractiveToggle(
                    'Cavity Overpressure',
                    _demoCavityOverpressure,
                    (val) => setState(() => _demoCavityOverpressure = val),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Cavity Relief Valve (CRV) Cracking & Reseat Verification
        _buildCard(
          title: 'CAVITY RELIEF OVERPRESSURE CRACKING & RESEAT TEST',
          subtitle: 'Tested per API 6D Cl. 9.6 • Relieves between 1.1x & 1.33x Design Pressure',
          icon: Icons.lock_clock_rounded,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildCrackingMetricTile(
                      label: 'NOMINAL SET-POINT',
                      value: '${cavity.nominalReliefSetBar.toStringAsFixed(1)} Bar',
                      subtext: '1.20 x Design Pressure',
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Container(width: 1, height: 44, color: AppTheme.border),
                  Expanded(
                    child: _buildCrackingMetricTile(
                      label: 'ACTUAL CRACKING',
                      value: '${cavity.crackingPressureBar.toStringAsFixed(1)} Bar',
                      subtext: 'Permissible: 107.8 - 130.3 Bar',
                      color: AppTheme.tertiary,
                    ),
                  ),
                  Container(width: 1, height: 44, color: AppTheme.border),
                  Expanded(
                    child: _buildCrackingMetricTile(
                      label: 'RESEAT PRESSURE',
                      value: '${cavity.reseatPressureBar.toStringAsFixed(1)} Bar',
                      subtext: 'Blowdown: ${cavity.blowdownPercent.toStringAsFixed(2)}%',
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Relief Flow Path: ${cavity.cavityReliefDirection}. Reseats gas-tight without chatter or hunting under dynamic differential blowdown.',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. DBB vs DIB Standard Matrix Reference
        _buildCard(
          title: 'API 6D CAVITY SEATING CLASSIFICATION MATRIX',
          subtitle: 'Official Pipeline Valve Specifications (ISO 14313 Table 1 / Clause 5.8)',
          icon: Icons.table_chart_rounded,
          child: Column(
            children: [
              _buildMatrixRow('Specification', 'Upstream Seat', 'Downstream Seat', 'Overpressure Protection'),
              const Divider(color: AppTheme.border, height: 12),
              _buildMatrixRow('DBB (Std)', 'SPE (Uni-Dir)', 'SPE (Uni-Dir)', 'Auto Body Self-Relief to Line'),
              const Divider(color: AppTheme.border, height: 12),
              _buildMatrixRow('DIB-1', 'DPE (Bi-Dir)', 'DPE (Bi-Dir)', 'External / Internal CRV Valve'),
              const Divider(color: AppTheme.border, height: 12),
              _buildMatrixRow('DIB-2', 'SPE (Uni-Dir)', 'DPE (Bi-Dir)', 'Self-relieves to Upstream Bore'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCavityPhysicsSchematic() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Upstream Line Port
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _demoUpstreamPressure
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _demoUpstreamPressure ? AppTheme.primaryLight : AppTheme.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('UPSTREAM', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Text(_demoUpstreamPressure ? '98.0 Bar' : '0.0 Bar',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _demoUpstreamPressure ? AppTheme.primaryLight : AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Text(_demoCavityConfig.code == 'DIB-1' ? 'DPE Seat' : 'SPE Seat',
                      style: const TextStyle(fontSize: 9, color: AppTheme.secondary)),
                ],
              ),
            ),
          ),

          // Dynamic Arrow 1
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.double_arrow_rounded,
              size: 20,
              color: _demoUpstreamPressure ? AppTheme.primaryLight : AppTheme.textMuted,
            ),
          ),

          // Central Ball Cavity
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _demoCavityOverpressure
                    ? const Color(0xFFFF5252).withValues(alpha: 0.2)
                    : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _demoCavityOverpressure ? const Color(0xFFFF5252) : AppTheme.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.radio_button_checked_rounded,
                          size: 14,
                          color: _demoCavityOverpressure ? const Color(0xFFFF5252) : AppTheme.tertiary),
                      const SizedBox(width: 4),
                      const Text('BODY CAVITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _demoCavityOverpressure ? '118.0 Bar (Thermal)' : '0.0 Bar (Vented)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _demoCavityOverpressure ? const Color(0xFFFF5252) : AppTheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _demoCavityConfig == ValveCavityConfig.dbb
                        ? 'SPE Relieves Into Line'
                        : _demoCavityConfig == ValveCavityConfig.dib1
                            ? 'CRV Relieves to Flare'
                            : 'Relieves Upstream',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8.5, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Dynamic Arrow 2
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.double_arrow_rounded,
              size: 20,
              color: _demoDownstreamPressure ? AppTheme.primaryLight : AppTheme.textMuted,
            ),
          ),

          // Downstream Line Port
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _demoDownstreamPressure
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _demoDownstreamPressure ? AppTheme.primaryLight : AppTheme.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('DOWNSTREAM', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Text(_demoDownstreamPressure ? '98.0 Bar' : '0.0 Bar',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _demoDownstreamPressure ? AppTheme.primaryLight : AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Text(_demoCavityConfig == ValveCavityConfig.dbb ? 'SPE Seat' : 'DPE Seat',
                      style: const TextStyle(fontSize: 9, color: AppTheme.secondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryLight,
          activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildCrackingMetricTile({
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        Text(subtext, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildMatrixRow(String c1, String c2, String c3, String c4) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(c1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
        Expanded(flex: 2, child: Text(c2, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary))),
        Expanded(flex: 2, child: Text(c3, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary))),
        Expanded(flex: 3, child: Text(c4, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.primaryLight))),
      ],
    );
  }

  // ==========================================================================
  // TAB 4: TORQUE & CYCLES PROFILE
  // ==========================================================================

  Widget _buildTorqueCyclesTab(ValveFatItem valve) {
    final torque = valve.torqueData;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Torque Measurements under Full Differential Pressure (100 Bar)
        _buildCard(
          title: 'FULL DIFFERENTIAL PRESSURE TORQUE PROFILE',
          subtitle: 'Tested under 100 Bar Full DP across Closed Ball • API 6D Cl. 9.7',
          icon: Icons.speed_rounded,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTorqueTile(
                      label: 'BREAKAWAY (OPEN)',
                      value: '${torque.breakawayOpenTorqueNm.toInt()} Nm',
                      subtext: 'Break-to-open against 100 Bar',
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTorqueTile(
                      label: 'RUNNING TORQUE',
                      value: '${torque.runningTorqueNm.toInt()} Nm',
                      subtext: 'Mid-stroke dynamic torque',
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTorqueTile(
                      label: 'SEATING / CLOSE',
                      value: '${torque.breakawayCloseTorqueNm.toInt()} Nm',
                      subtext: 'End-of-travel wedging',
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTorqueTile(
                      label: 'STEM MAST LIMIT',
                      value: '${torque.mastNm.toInt()} Nm',
                      subtext: 'Max Allowable Stem Torque',
                      color: const Color(0xFFFF5252),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Torque vs Travel Angle Chart
              const Text(
                'Torque vs Rotation Angle (0° Closed to 90° Fully Open):',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 3000,
                      verticalInterval: 15,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: AppTheme.border.withValues(alpha: 0.5),
                        strokeWidth: 0.8,
                      ),
                      getDrawingVerticalLine: (v) => FlLine(
                        color: AppTheme.border.withValues(alpha: 0.3),
                        strokeWidth: 0.8,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          interval: 4000,
                          getTitlesWidget: (v, meta) => Text(
                            '${(v / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 15,
                          getTitlesWidget: (v, meta) => Text(
                            '${v.toInt()}°',
                            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: AppTheme.border),
                    ),
                    minX: 0,
                    maxX: 90,
                    minY: 0,
                    maxY: 16000,
                    lineBarsData: [
                      // Valve Torque Curve
                      LineChartBarData(
                        spots: torque.torqueAngleProfile,
                        isCurved: true,
                        color: AppTheme.secondary,
                        barWidth: 2.5,
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.secondary.withValues(alpha: 0.12),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                      // Actuator Output Line (12,500 Nm)
                      LineChartBarData(
                        spots: const [FlSpot(0, 12500), FlSpot(90, 12500)],
                        isCurved: false,
                        color: AppTheme.tertiary.withValues(alpha: 0.8),
                        barWidth: 1.2,
                        dashArray: [5, 4],
                        dotData: const FlDotData(show: false),
                      ),
                      // MAST Upper Limit Line (14,500 Nm)
                      LineChartBarData(
                        spots: const [FlSpot(0, 14500), FlSpot(90, 14500)],
                        isCurved: false,
                        color: const Color(0xFFFF5252).withValues(alpha: 0.8),
                        barWidth: 1.5,
                        dashArray: [4, 4],
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Safety Factor Callout
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Actuator Sizing Factor of Safety:', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${torque.safetyFactor.toStringAsFixed(2)}x (Req: >= 1.50x)',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.tertiary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Full Differential Pressure Cyclic Stroking Endurance
        _buildCard(
          title: '3-CYCLE OPERATING ENDURANCE TEST (FULL DP)',
          subtitle: 'Verification of Actuator Travel Time, Emergency ESD Closure & Reseating',
          icon: Icons.repeat_rounded,
          child: Column(
            children: [
              ...List.generate(torque.completedCycles, (index) {
                final cycleNum = index + 1;
                final strokeTime = torque.cycleTimesSec[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.tertiary),
                            const SizedBox(width: 8),
                            Text('Cycle $cycleNum (0° -> 90° -> 0°):', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          ],
                        ),
                        Text(
                          '${strokeTime.toStringAsFixed(1)}s (ESD Limit: < 15.0s)',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              const Text(
                'Stroke time measured with Rotork electro-hydraulic failsafe close mechanism under 100 Bar differential pressure without stick-slip or cavitation.',
                style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTorqueTile({
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(subtext, style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 5: MTC EN 10204 TYPE 3.1 DIGITAL CERTIFICATE
  // ==========================================================================

  Widget _buildMtcCertificateTab(ValveFatItem valve) {
    final cert = valve.certificate;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Certificate Passport & Seal Card
        _buildCard(
          title: 'INSPECTION CERTIFICATE EN 10204 TYPE 3.1',
          subtitle: 'Specific Testing Verification & Dual Stakeholder Cryptographic Endorsement',
          icon: Icons.verified_user_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Certificate Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CERTIFICATE NUMBER', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                      Text(cert.certNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primaryLight)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cert.status.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: cert.status.color, width: 1),
                    ),
                    child: Text(
                      cert.status.label,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: cert.status.color),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 8),

              // Cryptographic Hash Display
              const Text('CRYPTOGRAPHIC INTEGRITY DIGEST (SHA-256):',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.enhanced_encryption_rounded, size: 14, color: AppTheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cert.certSha256Digest,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Dual Stakeholder Sign-Off Cards
              Row(
                children: [
                  // Manufacturer Sign-Off
                  Expanded(
                    child: _buildSignatureBox(
                      role: 'MANUFACTURER QA/QC',
                      signatoryName: cert.mfgSignatoryName,
                      signatoryTitle: cert.mfgSignatoryTitle,
                      isSigned: cert.mfgSigned,
                      signedAt: cert.mfgSignedAt,
                      onToggle: _toggleMfgSignature,
                      accentColor: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Client / TPIA Sign-Off
                  Expanded(
                    child: _buildSignatureBox(
                      role: 'CLIENT / TPIA RESIDENT',
                      signatoryName: cert.tpiaSignatoryName,
                      signatoryTitle: '${cert.tpiaAgency} • ${cert.tpiaSignatoryTitle}',
                      isSigned: cert.tpiaSigned,
                      signedAt: cert.tpiaSignedAt,
                      onToggle: _toggleTpiaSignature,
                      accentColor: AppTheme.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. Volumetric NDT & Testing Summary Records
        _buildCard(
          title: 'NON-DESTRUCTIVE TESTING & INSPECTION LOG',
          subtitle: '100% Volumetric & Surface Examination Records',
          icon: Icons.checklist_rounded,
          child: Column(
            children: cert.ndtExamResults.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 15, color: AppTheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(e.key, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(e.value, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // 4. Action Export Button
        Center(
          child: ElevatedButton.icon(
            onPressed: _showExportDossierModal,
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Export Official FAT Certificate Dossier'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              backgroundColor: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureBox({
    required String role,
    required String signatoryName,
    required String signatoryTitle,
    required bool isSigned,
    required DateTime? signedAt,
    required VoidCallback onToggle,
    required Color accentColor,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSigned ? accentColor.withValues(alpha: 0.6) : AppTheme.border,
          width: isSigned ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(role, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: accentColor)),
              Icon(
                isSigned ? Icons.verified_rounded : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: isSigned ? accentColor : AppTheme.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(signatoryName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(signatoryTitle, style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary), maxLines: 2),
          const SizedBox(height: 8),
          if (isSigned && signedAt != null)
            Text(
              'Signed: ${dateFormat.format(signedAt)}',
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppTheme.tertiary),
            )
          else
            const Text('Awaiting Electronic Signature', style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onToggle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4),
                side: BorderSide(color: isSigned ? const Color(0xFFFF5252) : accentColor),
              ),
              child: Text(
                isSigned ? 'Revoke Signature' : 'Sign & Endorse',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSigned ? const Color(0xFFFF5252) : accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // EXPORT DOSSIER & STANDARDS MODALS
  // ==========================================================================

  Widget _buildExportDossierDialog(BuildContext ctx) {
    final valve = _currentValve;

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border, width: 1.5),
      ),
      title: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryLight, size: 22),
          const SizedBox(width: 8),
          const Text('API 6D FAT Inspection Dossier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Asset: ${valve.valveTag} (${valve.serialNumber})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Standard: API Spec 6D / ISO 14313 • Class 600 FB TMBV',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    Text('Project: Oil India Limited 194.5 KM Pipeline Expansion',
                        style: const TextStyle(fontSize: 11, color: AppTheme.secondary)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildDossierRow('Hydro Shell Test (1.5x)', '${valve.hydroShellData.actualPressureBar} Bar / 15 min (Zero Leak)'),
              _buildDossierRow('HP Seat Test (1.1x)', '${valve.hpSeatData.seatAPressureBar} Bar / Rate A (0 drops)'),
              _buildDossierRow('LP Pneumatic Air Seat', '${valve.lpAirSeatData.actualPressureBar} Bar / 0 bubbles'),
              _buildDossierRow('Cavity Relief Verification', '${valve.cavityReliefData.crackingPressureBar} Bar Cracking (Verified)'),
              _buildDossierRow('Torque @ Full DP (100 Bar)', '${valve.torqueData.breakawayCloseTorqueNm.toInt()} Nm (< ${valve.torqueData.mastNm.toInt()} Nm MAST)'),
              _buildDossierRow('Dual QA/QC Endorsement', valve.certificate.status.label),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SHA-256 Digest: ${valve.certificate.certSha256Digest}',
                  style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(ctx).pop();
            _showFeedbackSnackbar('Inspection Dossier PDF Generated & Stored in Pipeline DMS', AppTheme.tertiary);
          },
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Download PDF'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
        ),
      ],
    );
  }

  Widget _buildDossierRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStandardsInfoContent(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'API Spec 6D / ISO 14313 Reference',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Pipeline and Piping Valves Factory Acceptance Testing Protocols',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryLight),
        ),
        const SizedBox(height: 14),
        _buildStandardSection(
          'Clause 9.3: Hydrostatic Shell Test',
          'Shall be tested at 1.5 times the pressure rating determined in accordance with ASME B16.34. Duration for valves >= 12" shall be a minimum of 15 minutes. Permissible leakage is zero. No permanent structural deformation permitted.',
        ),
        _buildStandardSection(
          'Clause 9.4: High-Pressure Hydrostatic Seat Test',
          'Shall be tested at 1.1 times the design rating across each seat independently for at least 5 minutes. Rate A acceptance allows zero detectable leakage (0 drops/min, 0 bubbles/min).',
        ),
        _buildStandardSection(
          'Clause 9.5: Low-Pressure Pneumatic Air Seat Test',
          'Shall be tested with dry air or nitrogen at 5.5 Bar to 7.0 Bar for at least 5 minutes under water immersion. Zero bubbles per minute permitted for soft seated valves.',
        ),
        _buildStandardSection(
          'Clause 5.8: Double Block and Bleed (DBB) & DIB',
          'DBB requires two seating surfaces sealing against both line ends with cavity bleed. DIB-1 features Double Piston Effect (DPE) seats requiring external cavity relief. DIB-2 pairs one SPE seat with one DPE seat.',
        ),
        _buildStandardSection(
          'Clause 9.7: Torque & Operating Cycles',
          'Operational cycle tests under full differential pressure verify breakaway, running, and seating torque. Maximum measured torque must not exceed stem MAST limit, with minimum 1.5x actuator sizing margin.',
        ),
        _buildStandardSection(
          'EN 10204 Type 3.1 Certification',
          'Mandates validation and dual endorsement by manufacturer inspection representative and authorized third-party inspector (EIL / TPIA), fully traceable to mill heat numbers.',
        ),
      ],
    );
  }

  Widget _buildStandardSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.secondary)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
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
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: AppTheme.primaryLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.3,
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
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
