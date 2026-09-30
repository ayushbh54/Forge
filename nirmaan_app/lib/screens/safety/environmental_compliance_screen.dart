import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// STATUTORY ENVIRONMENTAL CLEARANCE & MoEFCC COMPLIANCE DOMAIN MODELS
// ============================================================================

/// Statutory Environmental & Forest Clearance Classification
enum ClearanceCategory {
  environmentalClearance(
    label: 'Environmental Clearance (EC Category A)',
    shortCode: 'EC CAT-A',
    governingAct: 'EIA Notification 2006 / Environment (Protection) Act 1986',
    issuingAuthority: 'MoEFCC, New Delhi (Expert Appraisal Committee - Industry I)',
    color: Color(0xFF0284C7),
    icon: Icons.verified_user_rounded,
  ),
  consentToEstablish(
    label: 'Consent to Establish (CTE)',
    shortCode: 'PCBA CTE',
    governingAct: 'Air Act 1981 (Sec 21) & Water Act 1974 (Sec 25)',
    issuingAuthority: 'Pollution Control Board Assam (PCBA), Guwahati',
    color: Color(0xFFFFB95F),
    icon: Icons.foundation_rounded,
  ),
  consentToOperate(
    label: 'Consent to Operate (CTO)',
    shortCode: 'PCBA CTO',
    governingAct: 'Air Act 1981 & Water Act 1974 (5-Yr Renewal)',
    issuingAuthority: 'Pollution Control Board Assam (PCBA), RO Dibrugarh',
    color: Color(0xFF4EDEA3),
    icon: Icons.power_rounded,
  ),
  forestClearanceStage1(
    label: 'Forest Clearance (FC Stage-I / In-Principle)',
    shortCode: 'FC STAGE-I',
    governingAct: 'Forest (Conservation) Act 1980 Sec-2 / CAMPA Guidelines',
    issuingAuthority: 'MoEFCC Forest Conservation Division & Assam Forest Dept',
    color: Color(0xFFF59E0B),
    icon: Icons.forest_rounded,
  ),
  forestClearanceStage2(
    label: 'Forest Clearance (FC Stage-II / Formal Order)',
    shortCode: 'FC STAGE-II',
    governingAct: 'FCA 1980 Sec-2 (Working Permission for 28.40 Hectares)',
    issuingAuthority: 'MoEFCC North-Eastern Regional Office, Shillong',
    color: Color(0xFF10B981),
    icon: Icons.park_rounded,
  );

  final String label;
  final String shortCode;
  final String governingAct;
  final String issuingAuthority;
  final Color color;
  final IconData icon;

  const ClearanceCategory({
    required this.label,
    required this.shortCode,
    required this.governingAct,
    required this.issuingAuthority,
    required this.color,
    required this.icon,
  });
}

/// Clearance Lifecycle Status
enum ClearanceStatus {
  activeValid(
    label: 'ACTIVE & COMPLIANT',
    color: Color(0xFF4EDEA3),
    badgeColor: Color(0x264EDEA3),
    icon: Icons.check_circle_rounded,
  ),
  provisionalWorking(
    label: 'PROVISIONAL WORKING',
    color: Color(0xFF38BDF8),
    badgeColor: Color(0x2638BDF8),
    icon: Icons.schedule_rounded,
  ),
  halfYearlyReportDue(
    label: 'HYCR REPORT DUE',
    color: Color(0xFFFFB95F),
    badgeColor: Color(0x26FFB95F),
    icon: Icons.notification_important_rounded,
  ),
  renewalSubmitted(
    label: 'RENEWAL SUBMITTED',
    color: Color(0xFFA78BFA),
    badgeColor: Color(0x26A78BFA),
    icon: Icons.hourglass_top_rounded,
  );

  final String label;
  final Color color;
  final Color badgeColor;
  final IconData icon;

  const ClearanceStatus({
    required this.label,
    required this.color,
    required this.badgeColor,
    required this.icon,
  });
}

/// Individual Statutory Clearance Condition with compliance tracking
class ClearanceCondition {
  final String conditionNumber;
  final String description;
  final String complianceStatus; // 'COMPLIANT', 'MONITORED', 'ONGOING'
  final String verificationMechanism;
  final DateTime lastVerified;

  const ClearanceCondition({
    required this.conditionNumber,
    required this.description,
    required this.complianceStatus,
    required this.verificationMechanism,
    required this.lastVerified,
  });

  bool get isCompliant => complianceStatus == 'COMPLIANT';
}

/// Statutory Clearance Record
class StatutoryClearanceItem {
  final String id;
  final ClearanceCategory category;
  final String title;
  final String orderReferenceNumber;
  final DateTime issueDate;
  final DateTime validityExpiry;
  final double? divertedForestHectares;
  final double? campaNpvDepositedCrores;
  final ClearanceStatus status;
  final List<ClearanceCondition> conditions;
  final DateTime nextHycrDueDate;
  final String officerInCharge;
  final String digitalVaultDocumentId;

  const StatutoryClearanceItem({
    required this.id,
    required this.category,
    required this.title,
    required this.orderReferenceNumber,
    required this.issueDate,
    required this.validityExpiry,
    this.divertedForestHectares,
    this.campaNpvDepositedCrores,
    required this.status,
    required this.conditions,
    required this.nextHycrDueDate,
    required this.officerInCharge,
    required this.digitalVaultDocumentId,
  });

  int get compliantConditionsCount =>
      conditions.where((c) => c.isCompliant).length;

  double get complianceRate => conditions.isEmpty
      ? 100.0
      : (compliantConditionsCount / conditions.length) * 100.0;
}

/// Hourly trend point for Ambient Air Quality LineChart
class AaqTrendPoint {
  final double hour; // 0 to 23
  final double pm25;
  final double pm10;
  final double so2;
  final double nox;

  const AaqTrendPoint({
    required this.hour,
    required this.pm25,
    required this.pm10,
    required this.so2,
    required this.nox,
  });
}

/// Ambient Air Quality Station with CPCB NAAQS 2009 Standards
class AaqStation {
  final String id;
  final String name;
  final String chainage;
  final String locationZone;
  final double latitude;
  final double longitude;
  bool isCpcbUplinkLive;
  DateTime lastTelemetryTime;
  double pm25; // 24-hr NAAQS limit: 60 ug/m3
  double pm10; // 24-hr NAAQS limit: 100 ug/m3
  double so2;  // 24-hr NAAQS limit: 80 ug/m3
  double nox;  // 24-hr NAAQS limit: 80 ug/m3
  double co;   // 8-hr NAAQS limit: 2.0 mg/m3
  double ambientTempC;
  double relativeHumidityPercent;
  double windSpeedKmph;
  String windDirection;
  List<AaqTrendPoint> trendHistory;

  AaqStation({
    required this.id,
    required this.name,
    required this.chainage,
    required this.locationZone,
    required this.latitude,
    required this.longitude,
    required this.isCpcbUplinkLive,
    required this.lastTelemetryTime,
    required this.pm25,
    required this.pm10,
    required this.so2,
    required this.nox,
    required this.co,
    required this.ambientTempC,
    required this.relativeHumidityPercent,
    required this.windSpeedKmph,
    required this.windDirection,
    required this.trendHistory,
  });

  // CPCB NAAQS Thresholds
  static const double limitPm25 = 60.0;
  static const double limitPm10 = 100.0;
  static const double limitSo2 = 80.0;
  static const double limitNox = 80.0;
  static const double limitCo = 2.0;

  bool get isPm25Compliant => pm25 <= limitPm25;
  bool get isPm10Compliant => pm10 <= limitPm10;
  bool get isSo2Compliant => so2 <= limitSo2;
  bool get isNoxCompliant => nox <= limitNox;
  bool get isCoCompliant => co <= limitCo;
  bool get isAllNaaqsCompliant =>
      isPm25Compliant &&
      isPm10Compliant &&
      isSo2Compliant &&
      isNoxCompliant &&
      isCoCompliant;

  /// Approximate Air Quality Index (AQI) sub-index calculation
  int get calculatedAqi {
    // Simplified sub-index based on dominant particulate PM2.5 & PM10
    final double pm25Ratio = (pm25 / limitPm25) * 50.0;
    final double pm10Ratio = (pm10 / limitPm10) * 50.0;
    final double worstParticulate = math.max(pm25Ratio, pm10Ratio);
    return worstParticulate.round().clamp(15, 300);
  }

  String get aqiCategory {
    final aqi = calculatedAqi;
    if (aqi <= 50) return 'GOOD (0-50)';
    if (aqi <= 100) return 'SATISFACTORY (51-100)';
    if (aqi <= 200) return 'MODERATE (101-200)';
    if (aqi <= 300) return 'POOR (201-300)';
    return 'SEVERE (>300)';
  }

  Color get aqiColor {
    final aqi = calculatedAqi;
    if (aqi <= 50) return const Color(0xFF4EDEA3);
    if (aqi <= 100) return const Color(0xFF38BDF8);
    if (aqi <= 200) return const Color(0xFFFFB95F);
    return const Color(0xFFEF4444);
  }
}

/// Indigenous Flora Species for Compensatory Afforestation (1:2 ratio)
class IndigenousFloraSpecies {
  final String commonName;
  final String botanicalName;
  final String roleInEcosystem;
  final int plantedCount;
  final double survivalRatePercent;
  final Color badgeColor;

  const IndigenousFloraSpecies({
    required this.commonName,
    required this.botanicalName,
    required this.roleInEcosystem,
    required this.plantedCount,
    required this.survivalRatePercent,
    required this.badgeColor,
  });

  int get livingCount => ((plantedCount * survivalRatePercent) / 100).round();
  int get mortalityCount => plantedCount - livingCount;
}

/// Compensatory Afforestation Plot per FCA 1980 & CAMPA
class AfforestationPlot {
  final String plotId;
  final String plotName;
  final String beatDivision;
  final double areaHectares;
  final double latitude;
  final double longitude;
  final int targetSaplings;
  final int plantedSaplings;
  final double currentSurvivalRate;
  final double targetMinimumSurvivalRate; // Statutory mandate: > 85.0%
  final double droneNdviCanopyDensity;
  final double soilOrganicCarbonPct;
  final String dfoInspectionStatus;
  final DateTime lastAuditDate;
  final List<String> primarySpecies;

  const AfforestationPlot({
    required this.plotId,
    required this.plotName,
    required this.beatDivision,
    required this.areaHectares,
    required this.latitude,
    required this.longitude,
    required this.targetSaplings,
    required this.plantedSaplings,
    required this.currentSurvivalRate,
    this.targetMinimumSurvivalRate = 85.0,
    required this.droneNdviCanopyDensity,
    required this.soilOrganicCarbonPct,
    required this.dfoInspectionStatus,
    required this.lastAuditDate,
    required this.primarySpecies,
  });

  bool get isSurvivalCompliant => currentSurvivalRate >= targetMinimumSurvivalRate;
  int get livingTrees => ((plantedSaplings * currentSurvivalRate) / 100).round();
  int get replantedEnrichmentCount => plantedSaplings - livingTrees;
}

/// River Crossing Siltation & Water Turbidity Monitoring
class WaterCrossingMonitoring {
  final String crossingId;
  final String waterBodyName;
  final String chainage;
  final String crossingMethod; // 'HDD Trenchless (1,450m)', etc.
  final double upstreamBaselineNtu;
  final double downstreamMeasuredNtu;
  final double statutoryMaxDeltaNtu; // Max permissible delta: +25 NTU
  final String siltCurtainStatus;
  final double sedimentRetentionEfficiencyPct;
  final double dissolvedOxygenMgL; // Standard: > 5.0 mg/L
  final double phLevel;            // Standard: 6.5 - 8.5
  final bool isBentoniteLeakDetected; // Zero leakage requirement
  final String telemetrySensorTag;
  final DateTime lastSamplingTimestamp;

  const WaterCrossingMonitoring({
    required this.crossingId,
    required this.waterBodyName,
    required this.chainage,
    required this.crossingMethod,
    required this.upstreamBaselineNtu,
    required this.downstreamMeasuredNtu,
    this.statutoryMaxDeltaNtu = 25.0,
    required this.siltCurtainStatus,
    required this.sedimentRetentionEfficiencyPct,
    required this.dissolvedOxygenMgL,
    required this.phLevel,
    required this.isBentoniteLeakDetected,
    required this.telemetrySensorTag,
    required this.lastSamplingTimestamp,
  });

  double get deltaNtu => downstreamMeasuredNtu - upstreamBaselineNtu;
  bool get isDeltaCompliant => deltaNtu <= statutoryMaxDeltaNtu;
  bool get isDoCompliant => dissolvedOxygenMgL >= 5.0;
  bool get isPhCompliant => phLevel >= 6.5 && phLevel <= 8.5;
  bool get isFullyCompliant =>
      isDeltaCompliant &&
      isDoCompliant &&
      isPhCompliant &&
      !isBentoniteLeakDetected;

  Color get statusColor => isFullyCompliant
      ? const Color(0xFF4EDEA3)
      : const Color(0xFFEF4444);
}

// ============================================================================
// MAIN STATEFUL SCREEN WIDGET
// ============================================================================

class EnvironmentalComplianceScreen extends StatefulWidget {
  const EnvironmentalComplianceScreen({super.key});

  @override
  State<EnvironmentalComplianceScreen> createState() =>
      _EnvironmentalComplianceScreenState();
}

class _EnvironmentalComplianceScreenState
    extends State<EnvironmentalComplianceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _liveTelemetryTimer;
  bool _isTelemetryLiveSimulationActive = true;
  String _selectedAaqStationId = 'CAAQMS-DUL-01';
  String _clearanceFilter = 'ALL';
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');

  // Master Data Lists
  late List<StatutoryClearanceItem> _statutoryClearances;
  late List<AaqStation> _aaqStations;
  late List<IndigenousFloraSpecies> _indigenousSpecies;
  late List<AfforestationPlot> _afforestationPlots;
  late List<WaterCrossingMonitoring> _waterCrossings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
    _startLiveTelemetryStream();
  }

  @override
  void dispose() {
    _liveTelemetryTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startLiveTelemetryStream() {
    _liveTelemetryTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isTelemetryLiveSimulationActive || !mounted) return;
      setState(() {
        final random = math.Random();
        for (var station in _aaqStations) {
          // Micro-fluctuate AAQ values within realistic normal ranges
          final pm25Delta = (random.nextDouble() - 0.48) * 0.8;
          final pm10Delta = (random.nextDouble() - 0.48) * 1.2;
          final so2Delta = (random.nextDouble() - 0.50) * 0.3;
          final noxDelta = (random.nextDouble() - 0.50) * 0.4;
          final coDelta = (random.nextDouble() - 0.50) * 0.02;

          station.pm25 = (station.pm25 + pm25Delta).clamp(18.0, 52.0);
          station.pm10 = (station.pm10 + pm10Delta).clamp(35.0, 88.0);
          station.so2 = (station.so2 + so2Delta).clamp(6.0, 32.0);
          station.nox = (station.nox + noxDelta).clamp(12.0, 48.0);
          station.co = (station.co + coDelta).clamp(0.2, 1.4);
          station.lastTelemetryTime = DateTime.now();
        }

        // Also micro-fluctuate water river turbidity downstream readings
        for (int i = 0; i < _waterCrossings.length; i++) {
          final crossing = _waterCrossings[i];
          final ntuJitter = (random.nextDouble() - 0.5) * 0.4;
          final newDownstream = (crossing.downstreamMeasuredNtu + ntuJitter)
              .clamp(crossing.upstreamBaselineNtu + 1.0, crossing.upstreamBaselineNtu + 18.0);
          _waterCrossings[i] = WaterCrossingMonitoring(
            crossingId: crossing.crossingId,
            waterBodyName: crossing.waterBodyName,
            chainage: crossing.chainage,
            crossingMethod: crossing.crossingMethod,
            upstreamBaselineNtu: crossing.upstreamBaselineNtu,
            downstreamMeasuredNtu: double.parse(newDownstream.toStringAsFixed(1)),
            statutoryMaxDeltaNtu: crossing.statutoryMaxDeltaNtu,
            siltCurtainStatus: crossing.siltCurtainStatus,
            sedimentRetentionEfficiencyPct: crossing.sedimentRetentionEfficiencyPct,
            dissolvedOxygenMgL: crossing.dissolvedOxygenMgL,
            phLevel: crossing.phLevel,
            isBentoniteLeakDetected: crossing.isBentoniteLeakDetected,
            telemetrySensorTag: crossing.telemetrySensorTag,
            lastSamplingTimestamp: DateTime.now(),
          );
        }
      });
    });
  }

  void _initializeData() {
    final now = DateTime.now();

    // 1. Statutory Clearances (EC Cat-A, PCBA CTE, PCBA CTO, FC Stage-I, FC Stage-II)
    _statutoryClearances = [
      StatutoryClearanceItem(
        id: 'CLR-EC-01',
        category: ClearanceCategory.environmentalClearance,
        title: 'Environmental Clearance for 194.5 km Cross-Country Pipeline Corridor',
        orderReferenceNumber: 'J-11011/482/2022-IA.II(I)',
        issueDate: DateTime(2023, 4, 18),
        validityExpiry: DateTime(2033, 4, 17),
        divertedForestHectares: null,
        campaNpvDepositedCrores: null,
        status: ClearanceStatus.activeValid,
        nextHycrDueDate: now.add(const Duration(days: 42)),
        officerInCharge: 'Er. Ranjit Phukan (HSE Lead)',
        digitalVaultDocumentId: 'MoEFCC-EC-CAT-A-2023-V9',
        conditions: [
          ClearanceCondition(
            conditionNumber: 'Specific Cond. IV(a)',
            description: 'Establish 4 Continuous Ambient Air Quality Monitoring Stations (CAAQMS) with telemetry linked directly to CPCB/PCBA cloud.',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'Real-time 15-min API push verified by CPCB NIC portal',
            lastVerified: now.subtract(const Duration(days: 2)),
          ),
          ClearanceCondition(
            conditionNumber: 'Specific Cond. IV(b)',
            description: 'All major perennial river crossings (Burhi Dihing, Disang) must be executed exclusively via Horizontal Directional Drilling (HDD).',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'HDD Profile Steering Logs & In-Line Scour Bathymetry',
            lastVerified: now.subtract(const Duration(days: 5)),
          ),
          ClearanceCondition(
            conditionNumber: 'Specific Cond. IV(c)',
            description: 'Zero Liquid Discharge (ZLD) to be maintained at Duliajan terminal and intermediate compressor stations with bio-digesters.',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'STP treated effluent laboratory test certificates',
            lastVerified: now.subtract(const Duration(days: 7)),
          ),
          ClearanceCondition(
            conditionNumber: 'General Cond. VI',
            description: 'Submit Half-Yearly Compliance Report (HYCR) in digital format on MoEFCC PARIVESH portal with geotagged environmental progress.',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'PARIVESH HYCR submission acknowledgement dated 01 Dec 2025',
            lastVerified: now.subtract(const Duration(days: 30)),
          ),
        ],
      ),
      StatutoryClearanceItem(
        id: 'CLR-CTE-02',
        category: ClearanceCategory.consentToEstablish,
        title: 'Consent to Establish (CTE) for Pipeline Spreads, HDD Staging & Camps',
        orderReferenceNumber: 'WB/DIB/T-409/21-22/194',
        issueDate: DateTime(2022, 11, 10),
        validityExpiry: DateTime(2026, 12, 31),
        divertedForestHectares: null,
        campaNpvDepositedCrores: null,
        status: ClearanceStatus.activeValid,
        nextHycrDueDate: now.add(const Duration(days: 60)),
        officerInCharge: 'S. N. Gogoi (Site Enviro Rep)',
        digitalVaultDocumentId: 'PCBA-CTE-DIB-2022-88',
        conditions: [
          ClearanceCondition(
            conditionNumber: 'CTE Cond. 03',
            description: 'Acoustic enclosures on all diesel generators (DG Sets) ensuring noise level <75 dB(A) at 1 metre per IS 4758.',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'Decibel sound level survey records at all 8 generator yards',
            lastVerified: now.subtract(const Duration(days: 3)),
          ),
          ClearanceCondition(
            conditionNumber: 'CTE Cond. 08',
            description: 'Water spraying on Right-of-Way (RoW) access haul tracks twice daily to mitigate fugitive dust emission during dry weather.',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'GPS-tracked water bowser daily dispatch logs',
            lastVerified: now.subtract(const Duration(days: 1)),
          ),
          ClearanceCondition(
            conditionNumber: 'CTE Cond. 11',
            description: 'Hazardous waste authorization for oily rags, spent lube oil and pigging wax under HOWM Rules 2016.',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'Form-10 Hazardous Waste Manifest & PCB authorized recycler agreement',
            lastVerified: now.subtract(const Duration(days: 12)),
          ),
        ],
      ),
      StatutoryClearanceItem(
        id: 'CLR-CTO-03',
        category: ClearanceCategory.consentToOperate,
        title: 'Consent to Operate (CTO) for Gas Pigging Station & Section Valve Stations',
        orderReferenceNumber: 'PCBA/RO-DIB/CTO/GAS-PL/2025/88',
        issueDate: DateTime(2025, 3, 14),
        validityExpiry: DateTime(2030, 3, 13),
        divertedForestHectares: null,
        campaNpvDepositedCrores: null,
        status: ClearanceStatus.activeValid,
        nextHycrDueDate: now.add(const Duration(days: 75)),
        officerInCharge: 'Er. B. K. Saikia (Terminal Superintendent)',
        digitalVaultDocumentId: 'PCBA-CTO-5YR-OPER-2025',
        conditions: [
          ClearanceCondition(
            conditionNumber: 'CTO Cond. 02',
            description: 'Continuous online flame & smoke opacity telemetry for flare system connected to PCBA Central Server.',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'Optical camera & thermocouple telemetry stream',
            lastVerified: now.subtract(const Duration(days: 1)),
          ),
          ClearanceCondition(
            conditionNumber: 'CTO Cond. 05',
            description: 'Monthly ambient noise monitoring at boundary wall not to exceed 65 dB(A) during day time and 55 dB(A) at night time.',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'Calibrated NABL accredited acoustic sound level meter report',
            lastVerified: now.subtract(const Duration(days: 9)),
          ),
        ],
      ),
      StatutoryClearanceItem(
        id: 'CLR-FC-04',
        category: ClearanceCategory.forestClearanceStage2,
        title: 'Forest Clearance (Stage-I & Stage-II Final) for 28.40 Hectares Forest Diversion',
        orderReferenceNumber: 'F.No. 8-32/2021-FC / Final ENV.44/2023/102',
        issueDate: DateTime(2023, 8, 22),
        validityExpiry: DateTime(2043, 8, 21),
        divertedForestHectares: 28.40,
        campaNpvDepositedCrores: 2.84,
        status: ClearanceStatus.activeValid,
        nextHycrDueDate: now.add(const Duration(days: 35)),
        officerInCharge: 'Partha Pratim Baruah (Forest Nodal Officer)',
        digitalVaultDocumentId: 'MoEFCC-FC-STAGE-II-FINAL-28HA',
        conditions: [
          ClearanceCondition(
            conditionNumber: 'FCA Sec 2 Cond. 01',
            description: 'Compensatory Afforestation (CA) over degraded forest land twice the diverted area (1:2 ratio) - 56,800 indigenous tree saplings.',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'Joint inspection by DFO Dibrugarh & GPS survival tally (89.2%)',
            lastVerified: now.subtract(const Duration(days: 4)),
          ),
          ClearanceCondition(
            conditionNumber: 'FCA Sec 2 Cond. 02',
            description: 'Deposit of Net Present Value (NPV) of ₹2.84 Crores into the State Compensatory Afforestation Fund (CAMPA) account.',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'CAMPA Challan No. SBIN0008892 / MoEFCC Treasury Receipt',
            lastVerified: DateTime(2023, 8, 10),
          ),
          ClearanceCondition(
            conditionNumber: 'FCA Sec 2 Cond. 03',
            description: 'Strict restriction of pipeline trench corridor to maximum 18m width inside reserve forest beats; zero felling of mother seed trees.',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'Total Station GIS boundary markers & Assam Forest Dept demarcation pegs',
            lastVerified: now.subtract(const Duration(days: 8)),
          ),
          ClearanceCondition(
            conditionNumber: 'FCA Sec 2 Cond. 04',
            description: 'Topsoil removal and separate conservation; backfilling trench with segregated topsoil layer to allow natural seed bank regeneration.',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'Geotechnical trench inspection & geo-membrane segregation sheets',
            lastVerified: now.subtract(const Duration(days: 14)),
          ),
        ],
      ),
    ];

    // 2. Real-Time Ambient Air Quality (AAQ) Stations
    _aaqStations = [
      AaqStation(
        id: 'CAAQMS-DUL-01',
        name: 'Duliajan Terminal Central CAAQMS',
        chainage: 'Ch 00+000 (Dispatch Terminal)',
        locationZone: 'Industrial Major - Process Boundary',
        latitude: 27.3582,
        longitude: 95.3194,
        isCpcbUplinkLive: true,
        lastTelemetryTime: now,
        pm25: 28.4,
        pm10: 54.2,
        so2: 12.8,
        nox: 24.6,
        co: 0.65,
        ambientTempC: 26.4,
        relativeHumidityPercent: 78.0,
        windSpeedKmph: 8.4,
        windDirection: 'NE (045°)',
        trendHistory: List.generate(24, (i) {
          final h = i.toDouble();
          return AaqTrendPoint(
            hour: h,
            pm25: 24.0 + math.sin(i * 0.4) * 6.0 + (i > 16 ? 5.0 : 0.0),
            pm10: 48.0 + math.sin(i * 0.4) * 10.0 + (i > 16 ? 8.0 : 0.0),
            so2: 10.0 + math.cos(i * 0.3) * 3.0,
            nox: 20.0 + math.sin(i * 0.5) * 5.0,
          );
        }),
      ),
      AaqStation(
        id: 'CAAQMS-BDH-02',
        name: 'Burhi Dihing River HDD Staging AAQ',
        chainage: 'Ch 48+200 (HDD Rig Camp)',
        locationZone: 'Riverine Eco-Buffer / Wildlife Corridor',
        latitude: 27.2910,
        longitude: 95.2104,
        isCpcbUplinkLive: true,
        lastTelemetryTime: now,
        pm25: 22.1,
        pm10: 43.8,
        so2: 9.4,
        nox: 18.2,
        co: 0.42,
        ambientTempC: 25.1,
        relativeHumidityPercent: 82.5,
        windSpeedKmph: 11.2,
        windDirection: 'ESE (115°)',
        trendHistory: List.generate(24, (i) {
          final h = i.toDouble();
          return AaqTrendPoint(
            hour: h,
            pm25: 19.0 + math.sin(i * 0.35) * 4.5,
            pm10: 38.0 + math.sin(i * 0.35) * 7.5,
            so2: 8.0 + math.cos(i * 0.3) * 2.0,
            nox: 15.0 + math.sin(i * 0.45) * 4.0,
          );
        }),
      ),
      AaqStation(
        id: 'CAAQMS-MRN-03',
        name: 'Moran Gas Pressure Station CAAQMS',
        chainage: 'Ch 92+600 (Section Valve 04)',
        locationZone: 'Semi-Urban / Agricultural Corridor',
        latitude: 27.1894,
        longitude: 94.9271,
        isCpcbUplinkLive: true,
        lastTelemetryTime: now,
        pm25: 34.6,
        pm10: 67.1,
        so2: 15.2,
        nox: 29.8,
        co: 0.81,
        ambientTempC: 27.8,
        relativeHumidityPercent: 74.0,
        windSpeedKmph: 6.8,
        windDirection: 'SW (220°)',
        trendHistory: List.generate(24, (i) {
          final h = i.toDouble();
          return AaqTrendPoint(
            hour: h,
            pm25: 29.0 + math.sin(i * 0.42) * 8.0,
            pm10: 58.0 + math.sin(i * 0.42) * 12.0,
            so2: 12.0 + math.cos(i * 0.35) * 4.0,
            nox: 24.0 + math.sin(i * 0.5) * 6.0,
          );
        }),
      ),
      AaqStation(
        id: 'CAAQMS-DSG-04',
        name: 'Disang Reserved Forest Boundary AAQ',
        chainage: 'Ch 144+100 (Forest Sivasagar Div)',
        locationZone: 'Dense Forest Edge / FCA Reserved Zone',
        latitude: 27.0428,
        longitude: 94.7182,
        isCpcbUplinkLive: true,
        lastTelemetryTime: now,
        pm25: 18.7,
        pm10: 36.4,
        so2: 7.1,
        nox: 14.5,
        co: 0.35,
        ambientTempC: 24.6,
        relativeHumidityPercent: 86.0,
        windSpeedKmph: 5.2,
        windDirection: 'NNE (025°)',
        trendHistory: List.generate(24, (i) {
          final h = i.toDouble();
          return AaqTrendPoint(
            hour: h,
            pm25: 16.0 + math.sin(i * 0.3) * 3.5,
            pm10: 32.0 + math.sin(i * 0.3) * 6.0,
            so2: 6.0 + math.cos(i * 0.25) * 1.8,
            nox: 12.0 + math.sin(i * 0.4) * 3.0,
          );
        }),
      ),
    ];

    // 3. Compensatory Afforestation (CA) Indigenous Flora Breakdown
    _indigenousSpecies = const [
      IndigenousFloraSpecies(
        commonName: 'Hollong',
        botanicalName: 'Dipterocarpus macrocarpus',
        roleInEcosystem: 'Assam State Tree; dense upper emergent rainforest canopy',
        plantedCount: 22720, // 40% of 56,800
        survivalRatePercent: 90.8,
        badgeColor: Color(0xFF10B981),
      ),
      IndigenousFloraSpecies(
        commonName: 'Nahor / Ironwood',
        botanicalName: 'Mesua ferrea',
        roleInEcosystem: 'Evergreen riverine soil binder with high tensile root matrix',
        plantedCount: 19880, // 35% of 56,800
        survivalRatePercent: 88.4,
        badgeColor: Color(0xFF38BDF8),
      ),
      IndigenousFloraSpecies(
        commonName: 'Mekai',
        botanicalName: 'Shorea assamica',
        roleInEcosystem: 'Endangered native dipterocarp; keystone habitat provider',
        plantedCount: 14200, // 25% of 56,800
        survivalRatePercent: 87.6,
        badgeColor: Color(0xFFFFB95F),
      ),
    ];

    // Compensatory Afforestation Plantation Plots (Total Target: 56,800 Saplings, 28.40 ha diverted x 2)
    _afforestationPlots = [
      AfforestationPlot(
        plotId: 'CA-PLOT-ALPHA',
        plotName: 'Digboi Reserve Forest Beat (Plot Alpha)',
        beatDivision: 'Digboi Forest Division, Tinsukia / Dibrugarh',
        areaHectares: 12.20,
        latitude: 27.3821,
        longitude: 95.6180,
        targetSaplings: 24400,
        plantedSaplings: 24400,
        currentSurvivalRate: 90.4,
        droneNdviCanopyDensity: 0.81,
        soilOrganicCarbonPct: 1.92,
        dfoInspectionStatus: 'APPROVED & SIGNED (DFO / CAMPA)',
        lastAuditDate: now.subtract(const Duration(days: 18)),
        primarySpecies: const ['Hollong (50%)', 'Nahor (30%)', 'Mekai (20%)'],
      ),
      AfforestationPlot(
        plotId: 'CA-PLOT-BETA',
        plotName: 'Joypur Rainforest Buffer Zone (Plot Beta)',
        beatDivision: 'Joypur Range, Dibrugarh Forest Division',
        areaHectares: 10.00,
        latitude: 27.2410,
        longitude: 95.4215,
        targetSaplings: 20000,
        plantedSaplings: 20000,
        currentSurvivalRate: 88.6,
        droneNdviCanopyDensity: 0.77,
        soilOrganicCarbonPct: 1.84,
        dfoInspectionStatus: 'APPROVED (Joint Forest Council)',
        lastAuditDate: now.subtract(const Duration(days: 28)),
        primarySpecies: const ['Nahor (45%)', 'Hollong (35%)', 'Mekai (20%)'],
      ),
      AfforestationPlot(
        plotId: 'CA-PLOT-GAMMA',
        plotName: 'Dihing Patkai Wildlife Sanctuary Buffer (Plot Gamma)',
        beatDivision: 'Dihing Patkai National Park Eco-Sensitive Zone',
        areaHectares: 6.20,
        latitude: 27.1895,
        longitude: 95.3402,
        targetSaplings: 12400,
        plantedSaplings: 12400,
        currentSurvivalRate: 88.1,
        droneNdviCanopyDensity: 0.76,
        soilOrganicCarbonPct: 1.76,
        dfoInspectionStatus: 'APPROVED (Assam Chief Wildlife Warden)',
        lastAuditDate: now.subtract(const Duration(days: 42)),
        primarySpecies: const ['Mekai (40%)', 'Hollong (35%)', 'Nahor (25%)'],
      ),
    ];

    // 4. Water Body Crossing Siltation & Turbidity Telemetry
    _waterCrossings = [
      WaterCrossingMonitoring(
        crossingId: 'WAT-BDH-01',
        waterBodyName: 'Burhi Dihing River Crossing',
        chainage: 'Ch 48+200 (Major HDD Crossing)',
        crossingMethod: 'Horizontal Directional Drilling (1,450m drill profile)',
        upstreamBaselineNtu: 11.4,
        downstreamMeasuredNtu: 14.8,
        statutoryMaxDeltaNtu: 25.0,
        siltCurtainStatus: 'DUAL GEOTEXTILE SILT CURTAIN SECURE',
        sedimentRetentionEfficiencyPct: 95.6,
        dissolvedOxygenMgL: 6.8,
        phLevel: 7.4,
        isBentoniteLeakDetected: false,
        telemetrySensorTag: 'NTU-BDH-DSONDE-01',
        lastSamplingTimestamp: now,
      ),
      WaterCrossingMonitoring(
        crossingId: 'WAT-DSG-02',
        waterBodyName: 'Disang River Perennial Crossing',
        chainage: 'Ch 112+500 (HDD Section)',
        crossingMethod: 'Horizontal Directional Drilling (820m drill profile)',
        upstreamBaselineNtu: 9.8,
        downstreamMeasuredNtu: 13.2,
        statutoryMaxDeltaNtu: 25.0,
        siltCurtainStatus: 'FLOATING TURBIDITY BOOM & COIR FENCE DEPLOYED',
        sedimentRetentionEfficiencyPct: 94.2,
        dissolvedOxygenMgL: 7.1,
        phLevel: 7.2,
        isBentoniteLeakDetected: false,
        telemetrySensorTag: 'NTU-DSG-DSONDE-02',
        lastSamplingTimestamp: now,
      ),
      WaterCrossingMonitoring(
        crossingId: 'WAT-NOA-03',
        waterBodyName: 'Noa Dehing Channel Eco-Cross',
        chainage: 'Ch 168+900 (Microtunnel Section)',
        crossingMethod: 'Trenchless Pipe Jacking / Microtunneling (310m)',
        upstreamBaselineNtu: 14.2,
        downstreamMeasuredNtu: 18.5,
        statutoryMaxDeltaNtu: 25.0,
        siltCurtainStatus: 'DOUBLE ROCK-CHECK DAM & SEDIMENT SUMP ACTIVE',
        sedimentRetentionEfficiencyPct: 93.8,
        dissolvedOxygenMgL: 6.5,
        phLevel: 7.1,
        isBentoniteLeakDetected: false,
        telemetrySensorTag: 'NTU-NOA-DSONDE-03',
        lastSamplingTimestamp: now,
      ),
      WaterCrossingMonitoring(
        crossingId: 'WAT-TNG-04',
        waterBodyName: 'Tingrai Stream Culvert Tributary',
        chainage: 'Ch 22+400 (Dry Open-Cut with Flume Pipe)',
        crossingMethod: 'Temporary Stream Flume & Sandbag Coffer Bypass',
        upstreamBaselineNtu: 8.5,
        downstreamMeasuredNtu: 15.6,
        statutoryMaxDeltaNtu: 25.0,
        siltCurtainStatus: 'SILTATION PIT & COFFER DAM INVERT BARRIER',
        sedimentRetentionEfficiencyPct: 92.4,
        dissolvedOxygenMgL: 6.9,
        phLevel: 7.5,
        isBentoniteLeakDetected: false,
        telemetrySensorTag: 'NTU-TNG-DSONDE-04',
        lastSamplingTimestamp: now,
      ),
    ];
  }

  // Quick aggregates
  // Target saplings: 56800 // 28.40 ha * 2000 / ha per CAMPA
  int get _totalPlantedSaplings => 56800;
  double get _overallSurvivalRate {
    double totalLiving = 0;
    for (var plot in _afforestationPlots) {
      totalLiving += plot.livingTrees;
    }
    return (totalLiving / _totalPlantedSaplings) * 100.0;
  }

  double get _averageDownstreamNtu {
    if (_waterCrossings.isEmpty) return 0.0;
    double sum = 0;
    for (var c in _waterCrossings) {
      sum += c.downstreamMeasuredNtu;
    }
    return sum / _waterCrossings.length;
  }

  // ============================================================================
  // BUILD SCREEN LAYOUT
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildIndustrialSummaryHeader(),
          _buildMetricsStrip(),
          _buildCustomTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatutoryClearancesTab(),
                _buildAirQualityTelemetryTab(),
                _buildAfforestationTrackerTab(),
                _buildWaterCrossingsSiltationTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildContextualActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Environmental Clearance & MoEFCC',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'FCA 1980 / PCBA',
                  style: TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            '194.5 km Corridor · MoEFCC EC Cat-A · CAMPA 28.40 Ha Compliance',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        // Live Telemetry stream toggle
        IconButton(
          tooltip: _isTelemetryLiveSimulationActive
              ? 'Pause Telemetry Simulation'
              : 'Resume Live Telemetry',
          icon: Icon(
            _isTelemetryLiveSimulationActive
                ? Icons.sensors_rounded
                : Icons.sensors_off_rounded,
            color: _isTelemetryLiveSimulationActive
                ? AppTheme.tertiary
                : AppTheme.textMuted,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _isTelemetryLiveSimulationActive = !_isTelemetryLiveSimulationActive;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isTelemetryLiveSimulationActive
                      ? 'Real-time AAQ & NTU live telemetry stream active'
                      : 'Live telemetry simulation paused',
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: AppTheme.surfaceCard,
              ),
            );
          },
        ),
        // PARIVESH / MoEFCC Half-Yearly Report Action
        IconButton(
          tooltip: 'MoEFCC Compliance Dossier',
          icon: const Icon(
            Icons.article_rounded,
            color: AppTheme.primaryLight,
            size: 22,
          ),
          onPressed: _showHalfYearlyComplianceDialog,
        ),
      ],
    );
  }

  /// Industrial Header with Authority Badges and Uplink Indicator
  Widget _buildIndustrialSummaryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: const Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppTheme.tertiary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'STATUTORY REGULATORY UPLINK',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.tertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'CPCB & PCBA LIVE',
                            style: TextStyle(
                              color: AppTheme.tertiary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'FCA Sec-2: 28.40 Ha Forest Diverted · 1:2 CA Replacement Ratio · 56,800 Trees',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// High-level Industrial KPI Metric Strip
  Widget _buildMetricsStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMetricPill(
              title: 'STATUTORY CLEARANCES',
              value: '4/4 ACTIVE',
              subtitle: 'EC, CTE, CTO, FC-II',
              color: AppTheme.tertiary,
              icon: Icons.gavel_rounded,
            ),
            const SizedBox(width: 8),
            _buildMetricPill(
              title: 'AAQ STATIONS',
              value: '4 ONLINE',
              subtitle: '0 NAAQS Exceedance',
              color: AppTheme.primaryLight,
              icon: Icons.air_rounded,
            ),
            const SizedBox(width: 8),
            _buildMetricPill(
              title: 'CA SURVIVAL RATE',
              value: '${_overallSurvivalRate.toStringAsFixed(1)}%',
              subtitle: 'Target > 85.0% Mandate',
              color: _overallSurvivalRate >= 85.0
                  ? AppTheme.tertiary
                  : AppTheme.secondary,
              icon: Icons.forest_rounded,
            ),
            const SizedBox(width: 8),
            _buildMetricPill(
              title: 'RIVER SILTATION',
              value: '${_averageDownstreamNtu.toStringAsFixed(1)} NTU',
              subtitle: 'CPCB Baseline Δ < 25',
              color: AppTheme.tertiary,
              icon: Icons.water_rounded,
            ),
            const SizedBox(width: 8),
            _buildMetricPill(
              title: 'CAMPA FUND DEPOSIT',
              value: '₹ 2.84 Cr',
              subtitle: '100% NPV Deposited',
              color: AppTheme.secondary,
              icon: Icons.account_balance_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Custom 4-way TabBar
  Widget _buildCustomTabBar() {
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
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(
            icon: Icon(Icons.verified_rounded, size: 18),
            text: 'Statutory Clearances',
          ),
          Tab(
            icon: Icon(Icons.air_rounded, size: 18),
            text: 'Ambient Air Quality',
          ),
          Tab(
            icon: Icon(Icons.park_rounded, size: 18),
            text: 'Compensatory Afforestation',
          ),
          Tab(
            icon: Icon(Icons.water_rounded, size: 18),
            text: 'River Siltation & NTU',
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: STATUTORY CLEARANCES DASHBOARD (EC CAT-A, CTE, CTO, FC STAGE-II)
  // ============================================================================

  Widget _buildStatutoryClearancesTab() {
    final filteredClearances = _clearanceFilter == 'ALL'
        ? _statutoryClearances
        : _statutoryClearances
            .where((c) => c.category.shortCode.contains(_clearanceFilter))
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          Row(
            children: [
              const Text(
                'FILTER CLEARANCES:',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All (4)'),
                      const SizedBox(width: 6),
                      _buildFilterChip('EC', 'MoEFCC EC'),
                      const SizedBox(width: 6),
                      _buildFilterChip('CTE', 'PCBA CTE'),
                      const SizedBox(width: 6),
                      _buildFilterChip('CTO', 'PCBA CTO'),
                      const SizedBox(width: 6),
                      _buildFilterChip('FC', 'FCA 28.4ha'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Cards list
          for (var clearance in filteredClearances) ...[
            _buildClearanceCard(clearance),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 10),
          _buildStatutoryGuidelinesCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _clearanceFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _clearanceFilter = filterKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.2)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildClearanceCard(StatutoryClearanceItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Accent Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
              border: const Border(
                bottom: BorderSide(color: AppTheme.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(item.category.icon, color: item.category.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category.shortCode,
                        style: TextStyle(
                          color: item.category.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        item.orderReferenceNumber,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.status.badgeColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: item.status.color.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.status.icon, color: item.status.color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        item.status.label,
                        style: TextStyle(
                          color: item.status.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Card Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Authority & Governing Act Metadata
                _buildMetadataRow('Authority:', item.category.issuingAuthority),
                const SizedBox(height: 4),
                _buildMetadataRow('Governing Act:', item.category.governingAct),
                const SizedBox(height: 4),
                _buildMetadataRow(
                  'Validity:',
                  '${_dateFormat.format(item.issueDate)} to ${_dateFormat.format(item.validityExpiry)}',
                ),

                if (item.divertedForestHectares != null) ...[
                  const SizedBox(height: 4),
                  _buildMetadataRow(
                    'Forest Diversion:',
                    '${item.divertedForestHectares!.toStringAsFixed(2)} Hectares (Assam Forest Dept)',
                  ),
                ],
                if (item.campaNpvDepositedCrores != null) ...[
                  const SizedBox(height: 4),
                  _buildMetadataRow(
                    'CAMPA NPV Paid:',
                    '₹ ${item.campaNpvDepositedCrores!.toStringAsFixed(2)} Crores (100% Settled)',
                  ),
                ],

                const SizedBox(height: 12),

                // Compliance Progress Meter
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'STATUTORY CONDITIONS COMPLIANCE',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${item.compliantConditionsCount}/${item.conditions.length} Verified (${item.complianceRate.toStringAsFixed(0)}%)',
                                style: const TextStyle(
                                  color: AppTheme.tertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.complianceRate / 100.0,
                              minHeight: 6,
                              backgroundColor: AppTheme.surfaceContainerHigh,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.tertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 10),

                // Conditions Accordion Summary
                for (var cond in item.conditions) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppTheme.tertiary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cond.conditionNumber,
                                style: const TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                cond.description,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next HYCR Due: ${_dateFormat.format(item.nextHycrDueDate)}',
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showConditionAuditSheet(item),
                      icon: const Icon(
                        Icons.visibility_rounded,
                        color: AppTheme.primaryLight,
                        size: 14,
                      ),
                      label: const Text(
                        'Audit Checklist',
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatutoryGuidelinesCard() {
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
            children: const [
              Icon(Icons.shield_rounded, color: AppTheme.primaryLight, size: 18),
              SizedBox(width: 8),
              Text(
                'FCA 1980 & MoEFCC LEGAL FRAMEWORK SUMMARY',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Section 2 of FCA 1980 mandates in-principle Stage-I followed by compliance verification for formal Stage-II working permission.\n'
            '• 1:2 Compensatory Afforestation replacement ratio is binding with mandatory survival rate > 85.0% for 3 years prior to state forest handover.\n'
            '• Half-Yearly Compliance Reports (HYCR) must be uploaded on the MoEFCC PARIVESH portal with geotagged environmental monitoring data.\n'
            '• Water (Prevention & Control of Pollution) Act 1974 prohibits silt, drilling mud, or untreated runoff discharge into water bodies.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: AMBIENT AIR QUALITY (AAQ) TELEMETRY & CPCB NAAQS
  // ============================================================================

  Widget _buildAirQualityTelemetryTab() {
    final selectedStation = _aaqStations.firstWhere(
      (s) => s.id == _selectedAaqStationId,
      orElse: () => _aaqStations.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Selector Ribbon
          const Text(
            'SELECT CAAQMS MONITORING STATION:',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var station in _aaqStations) ...[
                  _buildStationSelectorButton(station),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Active Station Overview Card
          _buildActiveStationHeaderCard(selectedStation),
          const SizedBox(height: 14),

          // Real-time NAAQS 5-Gas Telemetry Grid
          const Text(
            'CPCB NAAQS 2009 5-GAS TELEMETRY (REAL-TIME)',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          _buildNaaqsGasGrid(selectedStation),
          const SizedBox(height: 16),

          // 24-Hour Particulate & Gas Line Chart
          _build24HourTrendChartCard(selectedStation),
          const SizedBox(height: 16),

          // Meteorological & CPCB Gateway Status
          _buildMeteorologicalAndGatewayCard(selectedStation),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStationSelectorButton(AaqStation station) {
    final isSelected = station.id == _selectedAaqStationId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAaqStationId = station.id;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: station.aqiColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  station.id,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryLight : AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              station.chainage,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStationHeaderCard(AaqStation station) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${station.locationZone} · GPS: ${station.latitude.toStringAsFixed(4)}° N, ${station.longitude.toStringAsFixed(4)}° E',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: AppTheme.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Last Telemetry: ${_timeFormat.format(station.lastTelemetryTime)}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // AQI Gauge Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: station.aqiColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: station.aqiColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                const Text(
                  'CPCB AQI',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${station.calculatedAqi}',
                  style: TextStyle(
                    color: station.aqiColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  station.aqiCategory.split(' ')[0],
                  style: TextStyle(
                    color: station.aqiColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNaaqsGasGrid(AaqStation station) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGasTelemetryTile(
                gasName: 'PM2.5 Particulate',
                value: station.pm25,
                unit: 'µg/m³',
                naaqsStandard: AaqStation.limitPm25,
                averagingPeriod: '24-Hour Avg',
                isCompliant: station.isPm25Compliant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGasTelemetryTile(
                gasName: 'PM10 Respirable',
                value: station.pm10,
                unit: 'µg/m³',
                naaqsStandard: AaqStation.limitPm10,
                averagingPeriod: '24-Hour Avg',
                isCompliant: station.isPm10Compliant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildGasTelemetryTile(
                gasName: 'Sulfur Dioxide (SO₂)',
                value: station.so2,
                unit: 'µg/m³',
                naaqsStandard: AaqStation.limitSo2,
                averagingPeriod: '24-Hour Avg',
                isCompliant: station.isSo2Compliant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGasTelemetryTile(
                gasName: 'Nitrogen Oxides (NOₓ)',
                value: station.nox,
                unit: 'µg/m³',
                naaqsStandard: AaqStation.limitNox,
                averagingPeriod: '24-Hour Avg',
                isCompliant: station.isNoxCompliant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildGasTelemetryTile(
                gasName: 'Carbon Monoxide (CO)',
                value: station.co,
                unit: 'mg/m³',
                naaqsStandard: AaqStation.limitCo,
                averagingPeriod: '8-Hour Avg',
                isCompliant: station.isCoCompliant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
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
                      'NAAQS OVERALL VERDICT',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          station.isAllNaaqsCompliant
                              ? Icons.verified_rounded
                              : Icons.warning_rounded,
                          color: station.isAllNaaqsCompliant
                              ? AppTheme.tertiary
                              : AppTheme.secondary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          station.isAllNaaqsCompliant
                              ? '100% COMPLIANT'
                              : 'MONITOR SPIKE',
                          style: TextStyle(
                            color: station.isAllNaaqsCompliant
                                ? AppTheme.tertiary
                                : AppTheme.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Zero NAAQS threshold exceedance in last 72 hrs',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGasTelemetryTile({
    required String gasName,
    required double value,
    required String unit,
    required double naaqsStandard,
    required String averagingPeriod,
    required bool isCompliant,
  }) {
    final ratio = (value / naaqsStandard).clamp(0.0, 1.0);
    final indicatorColor = isCompliant ? AppTheme.tertiary : AppTheme.secondary;

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
                gasName,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: indicatorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isCompliant ? 'SAFE' : 'SPIKE',
                  style: TextStyle(
                    color: indicatorColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Limit: ${naaqsStandard.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            averagingPeriod,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build24HourTrendChartCard(AaqStation station) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '24-HOUR TELEMETRY CONCENTRATION CURVE',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'PM2.5 vs PM10 Concentration vs CPCB NAAQS Benchmarks',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Legend
              Row(
                children: [
                  _buildLegendIndicator('PM2.5', const Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  _buildLegendIndicator('PM10', const Color(0xFFFFB95F)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 23,
                minY: 0,
                maxY: 120,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 30,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 4,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}h',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.border),
                ),
                lineBarsData: [
                  // PM2.5 Line (Cyan)
                  LineChartBarData(
                    spots: station.trendHistory
                        .map((p) => FlSpot(p.hour, p.pm25))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF38BDF8),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                    ),
                  ),
                  // PM10 Line (Amber)
                  LineChartBarData(
                    spots: station.trendHistory
                        .map((p) => FlSpot(p.hour, p.pm10))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFFFFB95F),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '-- PM2.5 CPCB Standard: 60 µg/m³',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9),
              ),
              Text(
                '-- PM10 CPCB Standard: 100 µg/m³',
                style: TextStyle(color: Color(0xFFFFB95F), fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
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
    );
  }

  Widget _buildMeteorologicalAndGatewayCard(AaqStation station) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMeteoItem('AMBIENT TEMP', '${station.ambientTempC.toStringAsFixed(1)} °C', Icons.thermostat_rounded),
          _buildMeteoItem('HUMIDITY', '${station.relativeHumidityPercent.toStringAsFixed(0)} %', Icons.water_drop_rounded),
          _buildMeteoItem('WIND SPEED', '${station.windSpeedKmph.toStringAsFixed(1)} km/h', Icons.air_rounded),
          _buildMeteoItem('WIND VECTOR', station.windDirection, Icons.explore_rounded),
        ],
      ),
    );
  }

  Widget _buildMeteoItem(String title, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 16),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 3: COMPENSATORY AFFORESTATION (CA) TRACKER (1:2 RATIO / 56,800 TREES)
  // ============================================================================

  Widget _buildAfforestationTrackerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statutory Mandate Banner
          _buildAfforestationMandateBanner(),
          const SizedBox(height: 14),

          // Total Saplings & Survival Gauge Card
          _buildAfforestationKpiCard(),
          const SizedBox(height: 16),

          // Indigenous Tree Species Breakdown
          const Text(
            'INDIGENOUS RAINFOREST CANOPY SPECIES DISTRIBUTION (1:2 RATIO)',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          for (var species in _indigenousSpecies) ...[
            _buildSpeciesCard(species),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 16),

          // Geotagged Plantation Plots
          const Text(
            'CAMPA COMPENSATORY AFFORESTATION GEOTAGGED PLOTS',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          for (var plot in _afforestationPlots) ...[
            _buildPlotCard(plot),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAfforestationMandateBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.park_rounded, color: AppTheme.tertiary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'FCA 1980 SECTION 2 MANDATORY REPLACEMENT (1:2 RATIO)',
                  style: TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Forest Diverted: 28.40 Hectares (28,400 felled equivalent). Mandatory planting: 56,800 indigenous tree saplings across degraded reserve forest blocks with survival requirement > 85.0%.',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAfforestationKpiCard() {
    final survivalPct = _overallSurvivalRate;
    final isPassing = survivalPct >= 85.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL INDIGENOUS TREES PLANTED',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Text(
                          '56,800',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '/ 56,800 (100% Target)',
                          style: TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '28.40 ha diverted x 2,000 stems/ha per CAMPA guidelines',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Circular / Radial Gauge Summary
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (isPassing ? AppTheme.tertiary : AppTheme.secondary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isPassing ? AppTheme.tertiary : AppTheme.secondary)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${survivalPct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isPassing ? AppTheme.tertiary : AppTheme.secondary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SURVIVAL RATE',
                      style: TextStyle(
                        color: isPassing ? AppTheme.tertiary : AppTheme.secondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '> 85% REQ',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 10),

          // Survival vs Mortality Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSurvivalStat(
                'LIVING STEMS',
                '${((_totalPlantedSaplings * survivalPct) / 100).round()}',
                AppTheme.tertiary,
              ),
              _buildSurvivalStat(
                'ENRICHMENT REPLANTED',
                '${_totalPlantedSaplings - ((_totalPlantedSaplings * survivalPct) / 100).round()}',
                AppTheme.secondary,
              ),
              _buildSurvivalStat(
                'AVERAGE NDVI DENSITY',
                '0.78 (Healthy)',
                AppTheme.primaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurvivalStat(String title, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeciesCard(IndigenousFloraSpecies species) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: species.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.eco_rounded, color: species.badgeColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          species.commonName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${species.botanicalName})',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      species.roleInEcosystem,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${species.plantedCount} Stems',
                    style: TextStyle(
                      color: species.badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${species.survivalRatePercent}% Survival',
                    style: const TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: species.survivalRatePercent / 100.0,
              minHeight: 4,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(species.badgeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlotCard(AfforestationPlot plot) {
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
                plot.plotName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${plot.currentSurvivalRate}% SURVIVAL',
                  style: const TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            plot.beatDivision,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.place_rounded, color: AppTheme.primaryLight, size: 14),
              const SizedBox(width: 4),
              Text(
                'GPS: ${plot.latitude.toStringAsFixed(4)}° N, ${plot.longitude.toStringAsFixed(4)}° E · Area: ${plot.areaHectares} Ha · ${plot.plantedSaplings} Saplings',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 14),
              const SizedBox(width: 4),
              Text(
                'DFO Audit: ${plot.dfoInspectionStatus}',
                style: const TextStyle(
                  color: AppTheme.tertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'NDVI: ${plot.droneNdviCanopyDensity}',
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: WATER BODY CROSSINGS, TURBIDITY & SILTATION MONITORING
  // ============================================================================

  Widget _buildWaterCrossingsSiltationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRiverTurbidityRegulatoryBanner(),
          const SizedBox(height: 14),

          const Text(
            'PERENNIAL WATER BODY CROSSING TELEMETRY (NTU METERS)',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          for (var crossing in _waterCrossings) ...[
            _buildRiverCrossingCard(crossing),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 10),
          _buildSiltationControlProtocolCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRiverTurbidityRegulatoryBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop_rounded, color: AppTheme.primaryLight, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'WATER (PREVENTION & CONTROL) ACT 1974 STANDARDS',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Continuous Nephelometric Turbidity Unit (NTU) telemetry at river banks. Statutory downstream turbidity delta must not exceed Upstream Baseline + 25 NTU. Zero bentonite drilling fluid breakthrough permitted.',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiverCrossingCard(WaterCrossingMonitoring item) {
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
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.waterBodyName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.chainage} · ${item.crossingMethod}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: item.statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  item.isFullyCompliant ? 'VERIFIED COMPLIANT' : 'ATTENTION',
                  style: TextStyle(
                    color: item.statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Turbidity Upstream vs Downstream Comparator
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTurbidityValueColumn(
                  'UPSTREAM BASELINE',
                  '${item.upstreamBaselineNtu.toStringAsFixed(1)} NTU',
                  AppTheme.textPrimary,
                ),
                Container(width: 1, height: 35, color: AppTheme.border),
                _buildTurbidityValueColumn(
                  'DOWNSTREAM SAMPLING',
                  '${item.downstreamMeasuredNtu.toStringAsFixed(1)} NTU',
                  item.isDeltaCompliant ? AppTheme.tertiary : AppTheme.secondary,
                ),
                Container(width: 1, height: 35, color: AppTheme.border),
                _buildTurbidityValueColumn(
                  'NET DELTA (Δ NTU)',
                  '+${item.deltaNtu.toStringAsFixed(1)} NTU',
                  item.isDeltaCompliant ? AppTheme.tertiary : AppTheme.error,
                  subtitle: 'Max Allowed: +25.0',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Silt Curtain & Bentonite Status
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppTheme.primaryLight, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.siltCurtainStatus,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Water Chemical Parameters (DO & pH)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dissolved Oxygen: ${item.dissolvedOxygenMgL.toStringAsFixed(1)} mg/L (Min > 5.0)',
                style: const TextStyle(
                  color: AppTheme.tertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'pH: ${item.phLevel.toStringAsFixed(1)} (6.5 - 8.5)',
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.circle,
                      size: 8, color: AppTheme.tertiary),
                  const SizedBox(width: 4),
                  const Text(
                    'Bentonite Leak: 0.0 ppm',
                    style: TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurbidityValueColumn(
      String title, String value, Color color, {String? subtitle}) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSiltationControlProtocolCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'RIVER SEDIMENT CONTROL MEASURES IN FORCE',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '• Dual permeable geotextile silt curtains deployed across HDD entry and exit pits.\n'
            '• High-capacity bentonite mud recycling vacuum centrifuges with closed-loop desanding.\n'
            '• Immediate shutdown protocol triggered if river turbidity delta exceeds +20.0 NTU.\n'
            '• Continuous acoustic Doppler current profiling (ADCP) ensures zero riverbed scour.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // DIALOGS & ACTIONS
  // ============================================================================

  Widget? _buildContextualActionButton() {
    return FloatingActionButton.extended(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_chart_rounded, size: 20),
      label: const Text(
        'Log Compliance Audit',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      onPressed: _showLogComplianceInspectionDialog,
    );
  }

  void _showHalfYearlyComplianceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.description_rounded, color: AppTheme.primaryLight),
            SizedBox(width: 8),
            Text(
              'MoEFCC HYCR Portal Submission',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Half-Yearly Environmental Compliance Report (HYCR)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• PARIVESH Portal Ref: EC-HYCR-2026-OCT-OIL01\n'
              '• All 4 CAAQMS 24-hr continuous air quality records attached\n'
              '• Forest Clearance 28.40 ha Compensatory Afforestation GPS tally (89.2% survival rate)\n'
              '• River crossings NTU meter turbidity calibration logs attached\n'
              '• Noise and hazardous waste manifest certificates compiled',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'MoEFCC PARIVESH compliance dossier exported successfully',
                  ),
                  backgroundColor: AppTheme.tertiary,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Export Dossier PDF'),
          ),
        ],
      ),
    );
  }

  void _showConditionAuditSheet(StatutoryClearanceItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(item.category.icon, color: item.category.color, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.category.shortCode} Statutory Checklist',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.orderReferenceNumber,
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: AppTheme.border),
              for (var c in item.conditions) ...[
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.tertiary,
                    size: 18,
                  ),
                  title: Text(
                    c.conditionNumber,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${c.description}\nEvidence: ${c.verificationMechanism}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showLogComplianceInspectionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Log Field Environmental Audit',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Record on-site inspection for MoEFCC / PCBA / Forest Dept compliance:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Audit Location / Chainage',
                hintText: 'e.g. Ch 48+200 Burhi Dihing Crossing',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Observed Compliance Status',
                hintText: 'e.g. Silt curtain intact, NTU within limits',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Field Environmental Audit logged to statutory register'),
                  backgroundColor: AppTheme.tertiary,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Record Audit'),
          ),
        ],
      ),
    );
  }
}
