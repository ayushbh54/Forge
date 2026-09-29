import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS
// ============================================================================

enum NdtPassStatus {
  passed,
  rejected,
  underRepair,
  pending,
}

enum RepairDefectType {
  slagInclusion,
  porosity,
  lackOfFusion,
  undercut,
  none,
}

extension RepairDefectTypeExtension on RepairDefectType {
  String get label {
    switch (this) {
      case RepairDefectType.slagInclusion:
        return 'Slag Inclusion';
      case RepairDefectType.porosity:
        return 'Porosity';
      case RepairDefectType.lackOfFusion:
        return 'Lack of Fusion';
      case RepairDefectType.undercut:
        return 'Undercut';
      case RepairDefectType.none:
        return 'No Defect';
    }
  }

  String get standardReference {
    switch (this) {
      case RepairDefectType.slagInclusion:
        return 'API 1104 §9.3.8 (Elongated Slag Inclusions > 50mm)';
      case RepairDefectType.porosity:
        return 'API 1104 §9.3.9 (Cluster Porosity > 1.6mm Individual)';
      case RepairDefectType.lackOfFusion:
        return 'API 1104 §9.3.4 (Incomplete Fusion at Bevel Sidewall)';
      case RepairDefectType.undercut:
        return 'API 1104 §9.3.11 (Crown/Root Undercut > 0.8mm depth)';
      case RepairDefectType.none:
        return 'ASME B31.8 / API 1104 Fully Compliant';
    }
  }

  IconData get icon {
    switch (this) {
      case RepairDefectType.slagInclusion:
        return Icons.layers_clear_rounded;
      case RepairDefectType.porosity:
        return Icons.bubble_chart_rounded;
      case RepairDefectType.lackOfFusion:
        return Icons.call_split_rounded;
      case RepairDefectType.undercut:
        return Icons.content_cut_rounded;
      case RepairDefectType.none:
        return Icons.check_circle_rounded;
    }
  }
}

class PipelineWeldJoint {
  final String jointNo; // e.g. WJ-DUL-0821
  final String spoolFrom; // e.g. SP-DUL-4101
  final String spoolTo; // e.g. SP-DUL-4102
  final String chainage; // e.g. 12+415.2
  final double chainageKm;
  final String pipeSize; // 18" (457 mm OD)
  final String steelGrade; // API 5L X70
  final double wallThicknessMm; // 14.3mm
  final String welderId; // W-104
  final String welderName; // Subhash B.
  final String weldDate;
  final String bevelType; // Double-Vee (30° bevel)
  final double preheatTempC; // 120°C

  // NDT Statuses
  NdtPassStatus rtStatus;
  double rtFilmDensity; // H&D units (nominal 2.0 to 4.0)
  double rtSensitivityPct; // Wire IQI (e.g. 1.72% <= 2.0% requirement)
  String rtIqiWire; // W10 ASTM Wire
  String rtReportNo;

  NdtPassStatus utStatus;
  String utMethod; // PAUT + TOFD
  double utGainDb; // 42.0 dB

  NdtPassStatus mptStatus;
  String mptMethod; // AC Electromagnetic Yoke (10 lb lift)

  NdtPassStatus vtStatus;
  double vtCapHeightMm; // 2.1 mm
  double vtHiLoMm; // 0.8 mm

  // Overall status & defect repair info
  NdtPassStatus overallStatus;
  RepairDefectType defectType;
  String defectClockPosition; // e.g. 02:30 to 04:00 o'clock
  double defectLengthMm;
  double defectDepthMm;
  String repairWps; // WPS-REP-09
  String? repairWelderId;
  bool isTpiaApproved;
  String tpiaRemarks;

  PipelineWeldJoint({
    required this.jointNo,
    required this.spoolFrom,
    required this.spoolTo,
    required this.chainage,
    required this.chainageKm,
    this.pipeSize = '18" (DN 450)',
    this.steelGrade = 'API 5L X70 PSL2',
    this.wallThicknessMm = 14.3,
    required this.welderId,
    required this.welderName,
    required this.weldDate,
    this.bevelType = 'Double-Vee (60° incl.)',
    this.preheatTempC = 125.0,
    required this.rtStatus,
    required this.rtFilmDensity,
    required this.rtSensitivityPct,
    this.rtIqiWire = 'ASTM W10',
    required this.rtReportNo,
    required this.utStatus,
    this.utMethod = 'PAUT (Phased Array) 5MHz',
    this.utGainDb = 42.0,
    required this.mptStatus,
    this.mptMethod = 'AC Electromagnetic Yoke (10 lb)',
    required this.vtStatus,
    this.vtCapHeightMm = 2.1,
    this.vtHiLoMm = 0.8,
    required this.overallStatus,
    this.defectType = RepairDefectType.none,
    this.defectClockPosition = 'N/A',
    this.defectLengthMm = 0.0,
    this.defectDepthMm = 0.0,
    this.repairWps = 'WPS-REP-09',
    this.repairWelderId,
    this.isTpiaApproved = true,
    this.tpiaRemarks = 'Accepted per API 1104 22nd Edition',
  });
}

class HydrotestHourlyLog {
  final int hour;
  final String timeLabel;
  final double pressureBar;
  final double ambientTempC;
  final double pipeTempC;
  final double dropBar;
  final String remark;

  const HydrotestHourlyLog({
    required this.hour,
    required this.timeLabel,
    required this.pressureBar,
    required this.ambientTempC,
    required this.pipeTempC,
    required this.dropBar,
    required this.remark,
  });
}

class HydrotestPhaseSignoff {
  final String id;
  final int stepNumber;
  final String title;
  final String description;
  final String specs;
  bool isSignedOff;
  String signedBy;
  String signedAt;
  final String authority;
  final IconData icon;

  HydrotestPhaseSignoff({
    required this.id,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.specs,
    required this.isSignedOff,
    required this.signedBy,
    required this.signedAt,
    required this.authority,
    required this.icon,
  });
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

/// Screen for Pipeline Weld Joint NDT Radiography & Hydrostatic Pressure Testing
/// Covers 15 mainline weld joints (WJ-DUL-0821 to WJ-DUL-0835), RT/UT/MPT/VT,
/// 24-Hour Hydrostatic Test Section 03 (112.5 Bar), Defect Classification,
/// and EIL / OIL Digital TPIA Stamp Verification.
class PipelineNdtScreen extends StatefulWidget {
  const PipelineNdtScreen({super.key});

  @override
  State<PipelineNdtScreen> createState() => _PipelineNdtScreenState();
}

class _PipelineNdtScreenState extends State<PipelineNdtScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // ALL, PASSED, REPAIR, PENDING

  // Hydrotest interactive state
  bool _simulateLeakAlarm = false; // Toggles test pressure drop >0.2 bar

  // Weld joint ledger: 15 joints (WJ-DUL-0821 to WJ-DUL-0835)
  late List<PipelineWeldJoint> _joints;

  // Hydrostatic test phases
  late List<HydrotestPhaseSignoff> _hydrotestPhases;

  // Selected joint for detailed RT / Defect viewer
  late PipelineWeldJoint _selectedViewerJoint;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeJoints();
    _initializeHydrotestPhases();
    _selectedViewerJoint = _joints[3]; // Default to WJ-DUL-0824 with defect for demonstration
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeJoints() {
    // 15 pipeline weld joints: WJ-DUL-0821 through WJ-DUL-0835
    _joints = [
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0821',
        spoolFrom: 'SP-DUL-4101',
        spoolTo: 'SP-DUL-4102',
        chainage: '12+415.2',
        chainageKm: 12.415,
        welderId: 'W-104',
        welderName: 'Subhash B.',
        weldDate: '24 Sep 2026',
        rtStatus: NdtPassStatus.passed,
        rtFilmDensity: 2.68,
        rtSensitivityPct: 1.72,
        rtReportNo: 'RT-OIL-26-0821',
        utStatus: NdtPassStatus.passed,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.passed,
        overallStatus: NdtPassStatus.passed,
        isTpiaApproved: true,
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0822',
        spoolFrom: 'SP-DUL-4102',
        spoolTo: 'SP-DUL-4103',
        chainage: '12+828.6',
        chainageKm: 12.828,
        welderId: 'W-104',
        welderName: 'Subhash B.',
        weldDate: '24 Sep 2026',
        rtStatus: NdtPassStatus.passed,
        rtFilmDensity: 2.74,
        rtSensitivityPct: 1.68,
        rtReportNo: 'RT-OIL-26-0822',
        utStatus: NdtPassStatus.passed,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.passed,
        overallStatus: NdtPassStatus.passed,
        isTpiaApproved: true,
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0823',
        spoolFrom: 'SP-DUL-4103',
        spoolTo: 'SP-DUL-4104',
        chainage: '13+242.0',
        chainageKm: 13.242,
        welderId: 'W-218',
        welderName: 'M. Rahman',
        weldDate: '25 Sep 2026',
        rtStatus: NdtPassStatus.passed,
        rtFilmDensity: 2.82,
        rtSensitivityPct: 1.78,
        rtReportNo: 'RT-OIL-26-0823',
        utStatus: NdtPassStatus.passed,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.passed,
        overallStatus: NdtPassStatus.passed,
        isTpiaApproved: true,
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0824',
        spoolFrom: 'SP-DUL-4104',
        spoolTo: 'SP-DUL-4105',
        chainage: '13+655.4',
        chainageKm: 13.655,
        welderId: 'W-218',
        welderName: 'M. Rahman',
        weldDate: '25 Sep 2026',
        rtStatus: NdtPassStatus.rejected,
        rtFilmDensity: 2.55,
        rtSensitivityPct: 1.85,
        rtReportNo: 'RT-OIL-26-0824',
        utStatus: NdtPassStatus.rejected,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.rejected,
        overallStatus: NdtPassStatus.rejected,
        defectType: RepairDefectType.slagInclusion,
        defectClockPosition: '02:30 to 03:45',
        defectLengthMm: 34.0,
        defectDepthMm: 3.2,
        repairWps: 'WPS-REP-09',
        repairWelderId: 'W-104',
        isTpiaApproved: false,
        tpiaRemarks: 'Rejected: Elongated slag inclusion in hot pass exceeding API 1104 Table 4 limit.',
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0825',
        spoolFrom: 'SP-DUL-4105',
        spoolTo: 'SP-DUL-4106',
        chainage: '14+068.8',
        chainageKm: 14.068,
        welderId: 'W-305',
        welderName: 'K. Sengupta',
        weldDate: '26 Sep 2026',
        rtStatus: NdtPassStatus.passed,
        rtFilmDensity: 2.91,
        rtSensitivityPct: 1.64,
        rtReportNo: 'RT-OIL-26-0825',
        utStatus: NdtPassStatus.passed,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.passed,
        overallStatus: NdtPassStatus.passed,
        isTpiaApproved: true,
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0826',
        spoolFrom: 'SP-DUL-4106',
        spoolTo: 'SP-DUL-4107',
        chainage: '14+482.2',
        chainageKm: 14.482,
        welderId: 'W-305',
        welderName: 'K. Sengupta',
        weldDate: '26 Sep 2026',
        rtStatus: NdtPassStatus.passed,
        rtFilmDensity: 2.65,
        rtSensitivityPct: 1.70,
        rtReportNo: 'RT-OIL-26-0826',
        utStatus: NdtPassStatus.passed,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.passed,
        overallStatus: NdtPassStatus.passed,
        isTpiaApproved: true,
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0827',
        spoolFrom: 'SP-DUL-4107',
        spoolTo: 'SP-DUL-4108',
        chainage: '14+895.6',
        chainageKm: 14.895,
        welderId: 'W-142',
        welderName: 'Pradip Gogoi',
        weldDate: '26 Sep 2026',
        rtStatus: NdtPassStatus.underRepair,
        rtFilmDensity: 2.48,
        rtSensitivityPct: 1.90,
        rtReportNo: 'RT-OIL-26-0827',
        utStatus: NdtPassStatus.rejected,
        mptStatus: NdtPassStatus.rejected,
        vtStatus: NdtPassStatus.rejected,
        overallStatus: NdtPassStatus.underRepair,
        defectType: RepairDefectType.lackOfFusion,
        defectClockPosition: '09:15 to 10:30',
        defectLengthMm: 28.5,
        defectDepthMm: 2.8,
        repairWps: 'WPS-REP-09',
        repairWelderId: 'W-142',
        isTpiaApproved: false,
        tpiaRemarks: 'Under Repair: Inter-pass lack of sidewall fusion detected by PAUT & RT. Carbon arc gouged, re-welding in progress.',
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0828',
        spoolFrom: 'SP-DUL-4108',
        spoolTo: 'SP-DUL-4109',
        chainage: '15+309.0',
        chainageKm: 15.309,
        welderId: 'W-142',
        welderName: 'Pradip Gogoi',
        weldDate: '27 Sep 2026',
        rtStatus: NdtPassStatus.passed,
        rtFilmDensity: 2.78,
        rtSensitivityPct: 1.74,
        rtReportNo: 'RT-OIL-26-0828',
        utStatus: NdtPassStatus.passed,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.passed,
        overallStatus: NdtPassStatus.passed,
        isTpiaApproved: true,
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0829',
        spoolFrom: 'SP-DUL-4109',
        spoolTo: 'SP-DUL-4110',
        chainage: '15+722.4',
        chainageKm: 15.722,
        welderId: 'W-097',
        welderName: 'Rajesh Borah',
        weldDate: '27 Sep 2026',
        rtStatus: NdtPassStatus.passed,
        rtFilmDensity: 2.86,
        rtSensitivityPct: 1.66,
        rtReportNo: 'RT-OIL-26-0829',
        utStatus: NdtPassStatus.passed,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.passed,
        overallStatus: NdtPassStatus.passed,
        isTpiaApproved: true,
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0830',
        spoolFrom: 'SP-DUL-4110',
        spoolTo: 'SP-DUL-4111',
        chainage: '16+135.8',
        chainageKm: 16.135,
        welderId: 'W-097',
        welderName: 'Rajesh Borah',
        weldDate: '27 Sep 2026',
        rtStatus: NdtPassStatus.passed,
        rtFilmDensity: 2.70,
        rtSensitivityPct: 1.76,
        rtReportNo: 'RT-OIL-26-0830',
        utStatus: NdtPassStatus.passed,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.passed,
        overallStatus: NdtPassStatus.passed,
        isTpiaApproved: true,
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0831',
        spoolFrom: 'SP-DUL-4111',
        spoolTo: 'SP-DUL-4112',
        chainage: '16+549.2',
        chainageKm: 16.549,
        welderId: 'W-104',
        welderName: 'Subhash B.',
        weldDate: '28 Sep 2026',
        rtStatus: NdtPassStatus.passed,
        rtFilmDensity: 2.80,
        rtSensitivityPct: 1.70,
        rtReportNo: 'RT-OIL-26-0831',
        utStatus: NdtPassStatus.passed,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.passed,
        overallStatus: NdtPassStatus.passed,
        isTpiaApproved: true,
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0832',
        spoolFrom: 'SP-DUL-4112',
        spoolTo: 'SP-DUL-4113',
        chainage: '16+962.6',
        chainageKm: 16.962,
        welderId: 'W-218',
        welderName: 'M. Rahman',
        weldDate: '28 Sep 2026',
        rtStatus: NdtPassStatus.passed,
        rtFilmDensity: 2.62,
        rtSensitivityPct: 1.80,
        rtReportNo: 'RT-OIL-26-0832',
        utStatus: NdtPassStatus.passed,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.passed,
        overallStatus: NdtPassStatus.passed,
        isTpiaApproved: true,
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0833',
        spoolFrom: 'SP-DUL-4113',
        spoolTo: 'SP-DUL-4114',
        chainage: '17+376.0',
        chainageKm: 17.376,
        welderId: 'W-305',
        welderName: 'K. Sengupta',
        weldDate: '28 Sep 2026',
        rtStatus: NdtPassStatus.passed,
        rtFilmDensity: 2.75,
        rtSensitivityPct: 1.72,
        rtReportNo: 'RT-OIL-26-0833',
        utStatus: NdtPassStatus.passed,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.passed,
        overallStatus: NdtPassStatus.passed,
        isTpiaApproved: true,
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0834',
        spoolFrom: 'SP-DUL-4114',
        spoolTo: 'SP-DUL-4115',
        chainage: '17+789.4',
        chainageKm: 17.789,
        welderId: 'W-142',
        welderName: 'Pradip Gogoi',
        weldDate: '29 Sep 2026',
        rtStatus: NdtPassStatus.passed,
        rtFilmDensity: 2.88,
        rtSensitivityPct: 1.68,
        rtReportNo: 'RT-OIL-26-0834',
        utStatus: NdtPassStatus.passed,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.passed,
        overallStatus: NdtPassStatus.passed,
        isTpiaApproved: true,
      ),
      PipelineWeldJoint(
        jointNo: 'WJ-DUL-0835',
        spoolFrom: 'SP-DUL-4115',
        spoolTo: 'SP-DUL-4116',
        chainage: '18+580.0',
        chainageKm: 18.580,
        welderId: 'W-097',
        welderName: 'Rajesh Borah',
        weldDate: '29 Sep 2026',
        rtStatus: NdtPassStatus.passed,
        rtFilmDensity: 2.72,
        rtSensitivityPct: 1.75,
        rtReportNo: 'RT-OIL-26-0835',
        utStatus: NdtPassStatus.passed,
        mptStatus: NdtPassStatus.passed,
        vtStatus: NdtPassStatus.passed,
        overallStatus: NdtPassStatus.passed,
        isTpiaApproved: true,
      ),
    ];
  }

  void _initializeHydrotestPhases() {
    _hydrotestPhases = [
      HydrotestPhaseSignoff(
        id: 'PHASE-01',
        stepNumber: 1,
        title: 'Caliper Pig Run & Gauging Sizing Plate',
        description: 'Electronic 16-channel caliper pig with aluminum 95% ID sizing plate passed through 6.2 km section. Zero denting or ovality > 2.0% found.',
        specs: 'ASME B31.8 §841.3.2 • Gauging Plate 434.1mm OD intact',
        isSignedOff: true,
        signedBy: 'Er. R. K. Sharma (QA/QC)',
        signedAt: '28 Sep 2026, 14:30',
        authority: 'OIL QA Directorate',
        icon: Icons.track_changes_rounded,
      ),
      HydrotestPhaseSignoff(
        id: 'PHASE-02',
        stepNumber: 2,
        title: 'Water Filling & Chemical Treatment',
        description: 'Potable water filling using batch pig train. Continuous dosing of 200 ppm Sodium Sulfite (O₂ scavenger) and 50 ppm glutaraldehyde biocide.',
        specs: 'Volume: 1,022.4 m³ (1,022,400 L) • Pumping Rate: 85 m³/hr',
        isSignedOff: true,
        signedBy: 'Er. Debashish Hazarika',
        signedAt: '29 Sep 2026, 06:00',
        authority: 'Engineers India Ltd (EIL)',
        icon: Icons.water_drop_rounded,
      ),
      HydrotestPhaseSignoff(
        id: 'PHASE-03',
        stepNumber: 3,
        title: '24-Hour Thermal Stabilization Period',
        description: 'Pre-pressurization to 35.0 Bar (30% test pressure) and 24h soak to reach ground thermal equilibrium between pipe wall and soil temperature.',
        specs: 'ΔT Soil-Water < 0.5°C • Ground Probe: 22.8°C • Pipe: 22.6°C',
        isSignedOff: true,
        signedBy: 'Er. Debashish Hazarika',
        signedAt: '29 Sep 2026, 18:00',
        authority: 'Engineers India Ltd (EIL)',
        icon: Icons.thermostat_rounded,
      ),
      HydrotestPhaseSignoff(
        id: 'PHASE-04',
        stepNumber: 4,
        title: '24-Hour Strength & Tightness Pressure Hold (112.5 Bar)',
        description: 'Step-wise pressurization (50%, 75%, 100% at 112.5 Bar). Continuous Dead Weight Tester (DWT) & digital logger monitoring for pressure decay.',
        specs: 'Test Pressure: 112.5 Bar • Allowed Drop ΔP < 0.20 Bar • 100% SMYS',
        isSignedOff: true,
        signedBy: 'Er. Ananya Sharma (Chief QA)',
        signedAt: '30 Sep 2026, 08:00',
        authority: 'Oil India Limited (OIL)',
        icon: Icons.speed_rounded,
      ),
      HydrotestPhaseSignoff(
        id: 'PHASE-05',
        stepNumber: 5,
        title: 'Dewatering, Swabbing & Air Drying Signoff',
        description: 'Displacement of test water via double cup bi-directional pigs backed by dry compressed air. Swab foam pigs until discharge dew point reaches -40°C.',
        specs: 'Discharge Dew Point ≤ -40°C • Nitrogen Blanketing 0.5 Bar',
        isSignedOff: false,
        signedBy: 'Pending Post-Test Completion',
        signedAt: 'Scheduled for 30 Sep 2026, 18:00',
        authority: 'EIL / OIL Joint Inspection',
        icon: Icons.air_rounded,
      ),
    ];
  }

  // Generate 24-hour log based on simulate leak alarm
  List<HydrotestHourlyLog> _getHourlyLogs() {
    final List<HydrotestHourlyLog> logs = [];
    final basePressure = 112.50;

    for (int h = 0; h <= 24; h++) {
      final hourStr = '${h.toString().padLeft(2, '0')}:00';
      double p;
      double ambTemp;
      double pipeTemp;
      double drop;
      String remark;

      // Realistic diurnal cycle
      if (h <= 6) {
        ambTemp = 21.0 + (h * 0.2);
        pipeTemp = 22.0 + (h * 0.1);
      } else if (h <= 14) {
        ambTemp = 22.2 + ((h - 6) * 1.0);
        pipeTemp = 22.6 + ((h - 6) * 0.35);
      } else {
        ambTemp = 30.2 - ((h - 14) * 0.8);
        pipeTemp = 25.4 - ((h - 14) * 0.25);
      }

      if (_simulateLeakAlarm) {
        // Critical leak scenario: pressure drops rapidly to 112.08 Bar (ΔP = 0.42 Bar > 0.2 Bar)
        final leakDrop = (h / 24.0) * 0.42;
        p = basePressure - leakDrop;
        drop = basePressure - p;
        if (drop >= 0.20) {
          remark = 'CRITICAL: ΔP exceeds 0.20 Bar limit!';
        } else {
          remark = 'Pressure degrading abnormal rate';
        }
      } else {
        // Normal compliant scenario: small thermal fluctuation, net drop 0.11 Bar (< 0.2 Bar)
        // Midday thermal expansion bump
        double thermalEffect = 0.0;
        if (h >= 10 && h <= 15) {
          thermalEffect = 0.06;
        } else if (h >= 16 && h <= 19) {
          thermalEffect = 0.03;
        }
        final baselineDecay = (h / 24.0) * 0.11;
        p = basePressure - baselineDecay + thermalEffect;
        drop = basePressure - p;
        remark = drop <= 0.20 ? 'Within < 0.2 Bar acceptance limit' : 'Slight fluctuation';
      }

      logs.add(HydrotestHourlyLog(
        hour: h,
        timeLabel: hourStr,
        pressureBar: double.parse(p.toStringAsFixed(2)),
        ambientTempC: double.parse(ambTemp.toStringAsFixed(1)),
        pipeTempC: double.parse(pipeTemp.toStringAsFixed(1)),
        dropBar: double.parse(drop.toStringAsFixed(2)),
        remark: remark,
      ));
    }
    return logs;
  }

  List<PipelineWeldJoint> get _filteredJoints {
    return _joints.where((j) {
      final matchesSearch = _searchQuery.isEmpty ||
          j.jointNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          j.welderId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          j.spoolFrom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          j.chainage.contains(_searchQuery);

      if (!matchesSearch) return false;

      if (_statusFilter == 'PASSED') {
        return j.overallStatus == NdtPassStatus.passed;
      } else if (_statusFilter == 'REPAIR') {
        return j.overallStatus == NdtPassStatus.rejected ||
            j.overallStatus == NdtPassStatus.underRepair;
      } else if (_statusFilter == 'PENDING') {
        return j.overallStatus == NdtPassStatus.pending;
      }
      return true;
    }).toList();
  }

  // ==========================================================================
  // BUILD METHOD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final passedCount = _joints.where((j) => j.overallStatus == NdtPassStatus.passed).length;
    final repairCount = _joints.where((j) => j.overallStatus == NdtPassStatus.rejected || j.overallStatus == NdtPassStatus.underRepair).length;
    final hourlyLogs = _getHourlyLogs();
    final latestLog = hourlyLogs.last;
    final isAlarmActive = latestLog.dropBar >= 0.20;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // KPI Metric Header Strip
          _buildKpiHeader(passedCount, repairCount, latestLog, isAlarmActive),

          // Tab Bar
          _buildTabBar(),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Weld Joint Ledger & NDT Matrix
                _buildWeldLedgerTab(),

                // TAB 2: Hydrostatic Pressure Test (Test Section 03)
                _buildHydrotestTab(hourlyLogs, isAlarmActive),

                // TAB 3: Radiography (RT) Viewer & Defect Classifier
                _buildRadiographyTab(),

                // TAB 4: Digital TPIA Stamp (EIL / OIL Inspector)
                _buildTpiaStampTab(),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Text(
                'Pipeline Weld NDT & Hydrotest',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(width: 8),
              ContainerBadge(
                label: 'Section 03',
                color: AppTheme.primaryLight,
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            '18" API 5L X70 (t=14.3mm) • WJ-DUL-0821 to 0835 • 112.5 Bar Hold',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Toggle Hydrotest Leak Simulation',
          icon: Icon(
            _simulateLeakAlarm ? Icons.warning_rounded : Icons.speed_rounded,
            color: _simulateLeakAlarm ? AppTheme.error : AppTheme.secondary,
          ),
          onPressed: () {
            setState(() {
              _simulateLeakAlarm = !_simulateLeakAlarm;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: _simulateLeakAlarm ? const Color(0xFF7F1D1D) : const Color(0xFF064E3B),
                content: Text(
                  _simulateLeakAlarm
                      ? '⚠️ Hydrostatic Leak Alarm Simulated: ΔP = 0.42 Bar (> 0.20 Bar limit)'
                      : '✅ Normal Hydrostatic Log Restored: ΔP = 0.11 Bar (< 0.20 Bar limit)',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'TPIA Verification Stamp',
          icon: const Icon(Icons.verified_user_rounded, color: AppTheme.tertiary),
          onPressed: () => _showTpiaStampModal(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ==========================================================================
  // TOP KPI STRIP
  // ==========================================================================

  Widget _buildKpiHeader(
      int passedCount, int repairCount, HydrotestHourlyLog latestLog, bool isAlarmActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Total Joints & Clearance
          Expanded(
            child: _buildMetricTile(
              label: 'NDT CLEARANCE',
              value: '$passedCount / ${_joints.length}',
              subtext: '${((passedCount / _joints.length) * 100).toStringAsFixed(1)}% Accepted',
              color: AppTheme.tertiary,
              icon: Icons.fact_check_rounded,
            ),
          ),
          const SizedBox(width: 8),
          // Defect / Repair
          Expanded(
            child: _buildMetricTile(
              label: 'REPAIRS ACTIVE',
              value: '$repairCount Joints',
              subtext: repairCount > 0 ? 'Slag & Lack of Fusion' : 'Zero Defects',
              color: repairCount > 0 ? AppTheme.secondary : AppTheme.tertiary,
              icon: Icons.handyman_rounded,
            ),
          ),
          const SizedBox(width: 8),
          // Hydrostatic Pressure Status
          Expanded(
            child: _buildMetricTile(
              label: 'HYDROTEST ΔP',
              value: '${latestLog.dropBar.toStringAsFixed(2)} Bar',
              subtext: isAlarmActive ? 'ALARM (>0.2 Bar)' : 'PASS (<0.2 Bar)',
              color: isAlarmActive ? AppTheme.error : AppTheme.primaryLight,
              icon: Icons.compress_rounded,
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
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
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
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: const [
          Tab(
            icon: Icon(Icons.table_chart_rounded, size: 18),
            text: 'Weld Ledger & NDT',
          ),
          Tab(
            icon: Icon(Icons.speed_rounded, size: 18),
            text: 'Hydrostatic Test (24h)',
          ),
          Tab(
            icon: Icon(Icons.blur_on_rounded, size: 18),
            text: 'RT Viewer & Defect',
          ),
          Tab(
            icon: Icon(Icons.verified_rounded, size: 18),
            text: 'TPIA Digital Stamp',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: WELD JOINT LEDGER & NDT STATUS MATRIX
  // ==========================================================================

  Widget _buildWeldLedgerTab() {
    final filtered = _filteredJoints;

    return Column(
      children: [
        // Search & Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.background,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppTheme.surfaceCard,
                        hintText: 'Search Joint (e.g. 0824), Welder ID, Spool...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.textMuted),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Specifications info badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.tune_rounded, size: 14, color: AppTheme.primaryLight),
                        SizedBox(width: 4),
                        Text(
                          '18" API 5L X70',
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All Joints (${_joints.length})'),
                    const SizedBox(width: 6),
                    _buildFilterChip('PASSED', 'Passed (${_joints.where((j) => j.overallStatus == NdtPassStatus.passed).length})'),
                    const SizedBox(width: 6),
                    _buildFilterChip('REPAIR', 'Defect / Repair (${_joints.where((j) => j.overallStatus == NdtPassStatus.rejected || j.overallStatus == NdtPassStatus.underRepair).length})'),
                    const SizedBox(width: 6),
                    _buildFilterChip('PENDING', 'Pending RT (0)'),
                    const SizedBox(width: 12),
                    // Pipeline specs label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Thickness: 14.3mm • Chainage 12+400 to 18+600',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Joints List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final joint = filtered[index];
                    return _buildWeldJointCard(joint);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _statusFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.15) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
            width: isSelected ? 1.4 : 1,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          const Text(
            'No Weld Joints Match Query',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try adjusting your search criteria or filter options.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWeldJointCard(PipelineWeldJoint joint) {
    final isRejected = joint.overallStatus == NdtPassStatus.rejected;
    final isUnderRepair = joint.overallStatus == NdtPassStatus.underRepair;
    final isPassed = joint.overallStatus == NdtPassStatus.passed;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isPassed) {
      statusColor = AppTheme.tertiary;
      statusLabel = 'ACCEPTED';
      statusIcon = Icons.check_circle_rounded;
    } else if (isUnderRepair) {
      statusColor = AppTheme.secondary;
      statusLabel = 'UNDER REPAIR';
      statusIcon = Icons.build_circle_rounded;
    } else {
      statusColor = AppTheme.error;
      statusLabel = 'REJECTED';
      statusIcon = Icons.cancel_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: (isRejected || isUnderRepair)
              ? statusColor.withValues(alpha: 0.5)
              : AppTheme.border,
          width: (isRejected || isUnderRepair) ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Joint ID + Spool Span + Status Pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            joint.jointNo,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'CH ${joint.chainage}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Spool ${joint.spoolFrom} ⟷ ${joint.spoolTo} • Welder: ${joint.welderName} (${joint.welderId})',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 2: 4-Pillar NDT Testing Matrix
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Radiographic Testing (RT)
                      Expanded(
                        child: _buildNdtMethodBox(
                          method: 'RT (Radiography)',
                          status: joint.rtStatus,
                          param1Label: 'Film Density',
                          param1Value: '${joint.rtFilmDensity.toStringAsFixed(2)} H&D',
                          param2Label: 'Sensitivity',
                          param2Value: '${joint.rtSensitivityPct.toStringAsFixed(2)}% (${joint.rtIqiWire})',
                          accentColor: AppTheme.primaryLight,
                          icon: Icons.blur_on_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Ultrasonic Testing (UT)
                      Expanded(
                        child: _buildNdtMethodBox(
                          method: 'UT (Phased Array)',
                          status: joint.utStatus,
                          param1Label: 'Technique',
                          param1Value: 'PAUT + TOFD',
                          param2Label: 'Gain dB',
                          param2Value: '${joint.utGainDb.toStringAsFixed(1)} dB (DAC)',
                          accentColor: const Color(0xFF818CF8),
                          icon: Icons.waves_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Magnetic Particle Testing (MPT)
                      Expanded(
                        child: _buildNdtMethodBox(
                          method: 'MPT (Magnetic Particle)',
                          status: joint.mptStatus,
                          param1Label: 'Equipment',
                          param1Value: 'AC Yoke (10 lb)',
                          param2Label: 'Surface Ind.',
                          param2Value: joint.mptStatus == NdtPassStatus.passed ? 'Zero Crack/LOF' : 'Indications Found',
                          accentColor: AppTheme.secondary,
                          icon: Icons.grain_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Visual Inspection (VT)
                      Expanded(
                        child: _buildNdtMethodBox(
                          method: 'VT (Visual Inspection)',
                          status: joint.vtStatus,
                          param1Label: 'Cap Reinforce',
                          param1Value: '${joint.vtCapHeightMm} mm',
                          param2Label: 'Hi-Lo Bevel',
                          param2Value: '${joint.vtHiLoMm} mm (<1.6mm)',
                          accentColor: AppTheme.tertiary,
                          icon: Icons.visibility_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Defect Classification Alert Banner (If rejected or under repair)
            if (isRejected || isUnderRepair) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isRejected ? AppTheme.error : AppTheme.secondary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isRejected ? AppTheme.error : AppTheme.secondary).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      joint.defectType.icon,
                      size: 18,
                      color: isRejected ? AppTheme.error : AppTheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'DEFECT: ${joint.defectType.label.toUpperCase()}',
                                style: TextStyle(
                                  color: isRejected ? AppTheme.error : AppTheme.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceCard,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Pos: ${joint.defectClockPosition}',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Size: ${joint.defectLengthMm}mm L × ${joint.defectDepthMm}mm D • Repair: ${joint.repairWps} (Gouge & Reweld)',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                          if (joint.tpiaRemarks.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'TPIA: ${joint.tpiaRemarks}',
                              style: TextStyle(
                                color: (isRejected ? AppTheme.error : AppTheme.secondary).withValues(alpha: 0.9),
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Action Buttons
            Row(
              children: [
                // Digital TPIA Stamp badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: joint.isTpiaApproved
                        ? AppTheme.tertiary.withValues(alpha: 0.1)
                        : AppTheme.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: joint.isTpiaApproved
                          ? AppTheme.tertiary.withValues(alpha: 0.4)
                          : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        joint.isTpiaApproved ? Icons.verified_rounded : Icons.pending_rounded,
                        size: 12,
                        color: joint.isTpiaApproved ? AppTheme.tertiary : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        joint.isTpiaApproved ? 'EIL / OIL TPIA STAMPED' : 'TPIA HOLD',
                        style: TextStyle(
                          color: joint.isTpiaApproved ? AppTheme.tertiary : AppTheme.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // View RT Film button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  icon: const Icon(Icons.blur_on_rounded, size: 14, color: AppTheme.primaryLight),
                  label: const Text('RT Film', style: TextStyle(fontSize: 11, color: AppTheme.primaryLight)),
                  onPressed: () {
                    setState(() {
                      _selectedViewerJoint = joint;
                    });
                    _tabController.animateTo(2);
                  },
                ),
                const SizedBox(width: 8),
                // Interactive Pass/Reject / Repair Toggle
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPassed ? AppTheme.surfaceContainerHigh : AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.rule_folder_rounded, size: 14),
                  label: const Text('Pass / Reject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  onPressed: () => _showPassRejectDefectModal(context, joint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNdtMethodBox({
    required String method,
    required NdtPassStatus status,
    required String param1Label,
    required String param1Value,
    required String param2Label,
    required String param2Value,
    required Color accentColor,
    required IconData icon,
  }) {
    final isPass = status == NdtPassStatus.passed;
    final isRepair = status == NdtPassStatus.underRepair;

    Color badgeColor = isPass
        ? AppTheme.tertiary
        : isRepair
            ? AppTheme.secondary
            : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPass ? AppTheme.border.withValues(alpha: 0.5) : badgeColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  method,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  isPass ? 'OK' : isRepair ? 'REP' : 'REJ',
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                param1Label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5),
              ),
              Text(
                param1Value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                param2Label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5),
              ),
              Text(
                param2Value,
                style: TextStyle(
                  color: isPass ? AppTheme.textSecondary : badgeColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: HYDROSTATIC PRESSURE TESTING SECTION (TEST SECTION 03)
  // ==========================================================================

  Widget _buildHydrotestTab(List<HydrotestHourlyLog> hourlyLogs, bool isAlarmActive) {
    final latestLog = hourlyLogs.last;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Specification Card
          _buildHydrotestSectionHeader(),

          const SizedBox(height: 14),

          // Alarm / Warning Banner (if pressure drop >= 0.20 bar)
          _buildPressureDropStatusBanner(latestLog, isAlarmActive),

          const SizedBox(height: 14),

          // 24-Hour Pressure Hold Log Chart
          _buildPressureChartCard(hourlyLogs, isAlarmActive),

          const SizedBox(height: 14),

          // Hourly DWT Logger Table
          _buildHourlyLogTable(hourlyLogs),

          const SizedBox(height: 16),

          // Water Filling & Dewatering Signoff Sequence
          _buildWaterFillingDewateringSignoffSection(),
        ],
      ),
    );
  }

  Widget _buildHydrotestSectionHeader() {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.waves_rounded, color: AppTheme.primaryLight, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Test Section 03 Hydrostatic Hold',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Chainage 12+400 to 18+600 (Total Length: 6,200m / 6.2 km)',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  '112.5 BAR',
                  style: TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),
          // Technical Spec Grid
          Row(
            children: [
              _buildSpecItem('Design Pressure', '75.0 Bar (DP)'),
              _buildSpecItem('Test Pressure', '112.5 Bar (1.5x DP)'),
              _buildSpecItem('Hold Period', '24 Hours Continuous'),
              _buildSpecItem('Acceptable Drop', '< 0.20 Bar (ΔP)'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSpecItem('Pipeline Size', '18" (457mm OD)'),
              _buildSpecItem('Wall Thickness', '14.3mm WT'),
              _buildSpecItem('Steel Grade', 'API 5L X70 PSL2'),
              _buildSpecItem('Medium', 'Water + 200ppm Na₂SO₃'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureDropStatusBanner(HydrotestHourlyLog latestLog, bool isAlarmActive) {
    final drop = latestLog.dropBar;

    if (isAlarmActive) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF450A0A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.error, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.crisis_alert_rounded, color: AppTheme.error, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CRITICAL ALARM: PRESSURE DROP EXCEEDS 0.20 BAR SPECIFICATION',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Observed Drop: ΔP = ${drop.toStringAsFixed(2)} Bar (Limit: < 0.20 Bar). Immediate inspection required per OISD-141 / ASME B31.8.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () {
                    setState(() => _simulateLeakAlarm = false);
                  },
                  child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.secondary),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Emergency Protocol: Inspect Section 03 test manifold, flange seals, and weld joints WJ-DUL-0821 to 0835 for weeping/sweat leaks.',
                      style: TextStyle(color: AppTheme.secondary, fontSize: 10.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.tertiary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HYDROSTATIC PRESSURE HOLD STATUS: ACCEPTABLE (PASS)',
                  style: TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Current Drop: ΔP = ${drop.toStringAsFixed(2)} Bar (Acceptable limit < 0.20 Bar). Pipe temp: ${latestLog.pipeTempC}°C.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              side: const BorderSide(color: AppTheme.secondary),
            ),
            onPressed: () {
              setState(() => _simulateLeakAlarm = true);
            },
            child: const Text(
              'Simulate Leak',
              style: TextStyle(color: AppTheme.secondary, fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureChartCard(List<HydrotestHourlyLog> hourlyLogs, bool isAlarmActive) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '24-Hour Pressure Hold Log Chart',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hourly Dead Weight Gauge (Bar) & Ground/Pipe Temperature (°C)',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Legend
                _buildChartLegendItem('Pressure (Bar)', isAlarmActive ? AppTheme.error : AppTheme.primaryLight),
                const SizedBox(width: 8),
                _buildChartLegendItem('Limit (112.30)', const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                _buildChartLegendItem('Pipe Temp (°C)', AppTheme.secondary),
              ],
            ),
            const SizedBox(height: 20),

            // FlChart LineChart
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.1,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: AppTheme.border.withValues(alpha: 0.4),
                      strokeWidth: 0.8,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 4,
                        getTitlesWidget: (val, meta) {
                          final h = val.toInt();
                          if (h >= 0 && h <= 24 && h % 4 == 0) {
                            return Text(
                              '${h.toString().padLeft(2, '0')}h',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: 0.1,
                        getTitlesWidget: (val, meta) {
                          return Text(
                            val.toStringAsFixed(1),
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 24,
                  minY: isAlarmActive ? 111.9 : 112.2,
                  maxY: 112.7,
                  lineBarsData: [
                    // Acceptable threshold line: 112.30 Bar (<0.2 Bar drop)
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 112.30),
                        FlSpot(24, 112.30),
                      ],
                      isCurved: false,
                      color: const Color(0xFFEF4444).withValues(alpha: 0.7),
                      barWidth: 1.2,
                      dashArray: [6, 4],
                      dotData: const FlDotData(show: false),
                    ),
                    // Test Pressure Line
                    LineChartBarData(
                      spots: hourlyLogs
                          .map((l) => FlSpot(l.hour.toDouble(), l.pressureBar))
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: isAlarmActive ? AppTheme.error : AppTheme.primaryLight,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        color: (isAlarmActive ? AppTheme.error : AppTheme.primaryLight).withValues(alpha: 0.08),
                      ),
                      dotData: FlDotData(
                        show: true,
                        checkToShowDot: (spot, barData) => spot.x.toInt() % 4 == 0 || spot.x == 24,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: isAlarmActive ? AppTheme.error : AppTheme.primaryLight,
                          strokeWidth: 1,
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
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
        ),
      ],
    );
  }

  Widget _buildHourlyLogTable(List<HydrotestHourlyLog> hourlyLogs) {
    // Show select hourly snapshots: 0h, 4h, 8h, 12h, 16h, 20h, 24h
    final sampled = hourlyLogs.where((l) => l.hour % 4 == 0 || l.hour == 24).toList();

    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.table_rows_rounded, size: 16, color: AppTheme.primaryLight),
                SizedBox(width: 8),
                Text(
                  'Dead Weight Tester (DWT) Certified Hourly Log',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 32,
                dataRowMinHeight: 30,
                dataRowMaxHeight: 34,
                columnSpacing: 18,
                horizontalMargin: 8,
                headingTextStyle: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
                columns: const [
                  DataColumn(label: Text('HOUR')),
                  DataColumn(label: Text('TIME')),
                  DataColumn(label: Text('PRESSURE (BAR)')),
                  DataColumn(label: Text('DROP ΔP')),
                  DataColumn(label: Text('PIPE TEMP')),
                  DataColumn(label: Text('AMBIENT')),
                  DataColumn(label: Text('COMPLIANCE')),
                ],
                rows: sampled.map((log) {
                  final isExceeded = log.dropBar >= 0.20;
                  return DataRow(
                    cells: [
                      DataCell(Text('${log.hour}h', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
                      DataCell(Text(log.timeLabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                      DataCell(Text('${log.pressureBar.toStringAsFixed(2)} Bar', style: TextStyle(color: isExceeded ? AppTheme.error : AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w700))),
                      DataCell(Text('${log.dropBar.toStringAsFixed(2)} Bar', style: TextStyle(color: isExceeded ? AppTheme.error : AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.w700))),
                      DataCell(Text('${log.pipeTempC}°C', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                      DataCell(Text('${log.ambientTempC}°C', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isExceeded ? AppTheme.error : AppTheme.tertiary).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isExceeded ? 'FAIL (>0.2B)' : 'PASS (<0.2B)',
                            style: TextStyle(
                              color: isExceeded ? AppTheme.error : AppTheme.tertiary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
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
      ),
    );
  }

  Widget _buildWaterFillingDewateringSignoffSection() {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in_rounded, size: 20, color: AppTheme.tertiary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Water Filling & Dewatering Signoff Sequence',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Section 03 Sequential Commissioning Signoff (OISD-141 / EIL Specs)',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_hydrotestPhases.where((p) => p.isSignedOff).length} / ${_hydrotestPhases.length} Done',
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Step items
            ..._hydrotestPhases.map((phase) => _buildHydrotestPhaseItem(phase)),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrotestPhaseItem(HydrotestPhaseSignoff phase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: phase.isSignedOff
              ? AppTheme.tertiary.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: phase.isSignedOff
                      ? AppTheme.tertiary.withValues(alpha: 0.15)
                      : AppTheme.surfaceCard,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: phase.isSignedOff ? AppTheme.tertiary : AppTheme.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${phase.stepNumber}',
                    style: TextStyle(
                      color: phase.isSignedOff ? AppTheme.tertiary : AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      phase.specs,
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Signoff Toggle Button
              if (phase.isSignedOff)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 12, color: AppTheme.tertiary),
                      SizedBox(width: 4),
                      Text(
                        'SIGNED OFF',
                        style: TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.draw_rounded, size: 12),
                  label: const Text('Sign Off', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                  onPressed: () => _showSignoffDialog(phase),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            phase.description,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          if (phase.isSignedOff) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${phase.signedBy} (${phase.authority}) • ${phase.signedAt}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showSignoffDialog(HydrotestPhaseSignoff phase) {
    final inspectorController = TextEditingController(text: 'Er. Debashish Hazarika (TPIA)');
    final authorityController = TextEditingController(text: 'Engineers India Limited (EIL)');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.draw_rounded, color: AppTheme.primaryLight, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Signoff: ${phase.title}',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phase.specs,
              style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: inspectorController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Inspector Name & Designation',
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: authorityController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Authority / Organization',
                isDense: true,
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
              setState(() {
                phase.isSignedOff = true;
                phase.signedBy = inspectorController.text;
                phase.signedAt = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.tertiary.withValues(alpha: 0.9),
                  content: Text('✅ Phase ${phase.stepNumber} officially signed off by ${phase.signedBy}'),
                ),
              );
            },
            child: const Text('Certify & Sign'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: RADIOGRAPHY (RT) VIEWER & DEFECT CLASSIFIER
  // ==========================================================================

  Widget _buildRadiographyTab() {
    final joint = _selectedViewerJoint;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Joint Selector Dropdown Header
          _buildViewerJointHeader(joint),

          const SizedBox(height: 14),

          // Simulated Industrial RT Radiography Film
          _buildIndustrialRtFilm(joint),

          const SizedBox(height: 14),

          // Optical Density & Sensitivity Readouts
          _buildFilmDensityMatrix(joint),

          const SizedBox(height: 14),

          // Repair Defect Classification Card
          _buildRepairDefectClassificationCard(joint),

          const SizedBox(height: 14),

          // Technical Defect Standard Criteria Reference Card
          _buildDefectCriteriaStandardCard(),
        ],
      ),
    );
  }

  Widget _buildViewerJointHeader(PipelineWeldJoint joint) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.blur_on_rounded, color: AppTheme.primaryLight, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Film: ${joint.rtReportNo}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        joint.jointNo,
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '18" API 5L X70 (t=14.3mm) • Source: Ir-192 Gamma • Batch: AGFA D7 Class I',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          // Dropdown to switch joints
          DropdownButton<String>(
            value: joint.jointNo,
            dropdownColor: AppTheme.surfaceCard,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryLight),
            items: _joints.map((j) {
              return DropdownMenuItem<String>(
                value: j.jointNo,
                child: Text(
                  j.jointNo,
                  style: TextStyle(
                    color: j.overallStatus == NdtPassStatus.passed ? AppTheme.textPrimary : AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                final target = _joints.firstWhere((j) => j.jointNo == val);
                setState(() => _selectedViewerJoint = target);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIndustrialRtFilm(PipelineWeldJoint joint) {
    final hasDefect = joint.defectType != RepairDefectType.none;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF030712), // Deep radiograph black
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Film Strip Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.radio_button_checked_rounded, size: 10, color: Color(0xFFEF4444)),
                const SizedBox(width: 6),
                const Text(
                  'OIL INDIA LTD • RADIOGRAPHIC INSPECTION ILLUMINATOR',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  'Density: ${joint.rtFilmDensity} H&D',
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Simulated Radiograph Film Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Base X-Ray Film Gradient
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0A0F1D),
                        Color(0xFF1E293B),
                        Color(0xFF334155),
                        Color(0xFF1E293B),
                        Color(0xFF0A0F1D),
                      ],
                    ),
                  ),
                ),

                // Simulated Weld Seam Crown & Root Profile
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),

                // Heat Affected Zone (HAZ) striations
                Positioned(
                  top: 36,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                Positioned(
                  bottom: 36,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),

                // ASTM Wire Penetrameter (IQI W10 - W16)
                Positioned(
                  left: 20,
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IQI ASTM W10 (1.72%)',
                          style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        // 4 simulated wire lines with varying thickness
                        Container(width: 40, height: 2.2, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(height: 2),
                        Container(width: 40, height: 1.6, color: Colors.white.withValues(alpha: 0.6)),
                        const SizedBox(height: 2),
                        Container(width: 40, height: 1.1, color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(height: 2),
                        Container(width: 40, height: 0.7, color: Colors.white.withValues(alpha: 0.4)),
                      ],
                    ),
                  ),
                ),

                // Lead Identification Markers: Lead 'B' and Film Identification
                Positioned(
                  right: 20,
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'B  ${joint.jointNo}  0°–360°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

                // Weld Centerline
                Container(
                  height: 1.2,
                  color: Colors.white.withValues(alpha: 0.15),
                ),

                // DEFECT OVERLAY SIMULATION (If present)
                if (hasDefect) ...[
                  Positioned(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.error, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_rounded, color: AppTheme.error, size: 14),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${joint.defectType.label.toUpperCase()} (${joint.defectLengthMm}mm)',
                                style: const TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Clock: ${joint.defectClockPosition} • Depth: ${joint.defectDepthMm}mm',
                                style: const TextStyle(color: Colors.white70, fontSize: 8.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '100% SOUND WELD • ZERO LINEAR INDICATIONS FOUND',
                        style: TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Film Density Strip Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.straighten_rounded, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                const Text(
                  'Optical Density Calibration: Lead B Transmitted Light verified (2.0 - 4.0 H&D OK)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: joint.overallStatus == NdtPassStatus.passed
                        ? AppTheme.tertiary.withValues(alpha: 0.2)
                        : AppTheme.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    joint.overallStatus == NdtPassStatus.passed ? 'API 1104 ACCEPTED' : 'REPAIR REQUIRED',
                    style: TextStyle(
                      color: joint.overallStatus == NdtPassStatus.passed ? AppTheme.tertiary : AppTheme.error,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
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

  Widget _buildFilmDensityMatrix(PipelineWeldJoint joint) {
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
          const Text(
            'Film Density & Penetrameter Sensitivity Readings',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildReadoutTile('12:00 O\'Clock', '${(joint.rtFilmDensity - 0.05).toStringAsFixed(2)} H&D', 'Nominal Pass'),
              _buildReadoutTile('03:00 O\'Clock', '${(joint.rtFilmDensity + 0.08).toStringAsFixed(2)} H&D', 'Nominal Pass'),
              _buildReadoutTile('06:00 O\'Clock', '${(joint.rtFilmDensity - 0.02).toStringAsFixed(2)} H&D', 'Nominal Pass'),
              _buildReadoutTile('09:00 O\'Clock', '${(joint.rtFilmDensity + 0.04).toStringAsFixed(2)} H&D', 'Nominal Pass'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadoutTile(String pos, String val, String status) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            Text(pos, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
            const SizedBox(height: 2),
            Text(
              val,
              style: const TextStyle(
                color: AppTheme.primaryLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(status, style: const TextStyle(color: AppTheme.tertiary, fontSize: 8.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildRepairDefectClassificationCard(PipelineWeldJoint joint) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: joint.overallStatus == NdtPassStatus.passed
              ? AppTheme.border
              : AppTheme.secondary.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.handyman_rounded, color: AppTheme.secondary, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Weld Joint Defect Classification & Repair Protocol',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 14),
                  label: const Text('Update / Re-test', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                  onPressed: () => _showPassRejectDefectModal(context, joint),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Defect details
            Row(
              children: [
                Expanded(
                  child: _buildDefectAttribute(
                    'Defect Classification',
                    joint.defectType.label,
                    joint.defectType != RepairDefectType.none ? AppTheme.secondary : AppTheme.tertiary,
                  ),
                ),
                Expanded(
                  child: _buildDefectAttribute(
                    'Circumference Clock Position',
                    joint.defectClockPosition,
                    AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDefectAttribute(
                    'Length × Depth',
                    '${joint.defectLengthMm} mm × ${joint.defectDepthMm} mm',
                    AppTheme.textPrimary,
                  ),
                ),
                Expanded(
                  child: _buildDefectAttribute(
                    'Repair WPS Spec',
                    joint.repairWps,
                    AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Standard Rule: ${joint.defectType.standardReference}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
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

  Widget _buildDefectAttribute(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDefectCriteriaStandardCard() {
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
            'API 1104 / ASME B31.8 Defect Acceptance Criteria Matrix',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          _CriteriaRow(
            defect: 'Slag Inclusion',
            rule: 'Max length ≤ 50mm individual, cumulative ≤ 50mm in 300mm continuous weld length.',
          ),
          _CriteriaRow(
            defect: 'Porosity',
            rule: 'Max pore diameter ≤ 3.2mm. Cluster porosity total area ≤ 12mm² per 25mm length.',
          ),
          _CriteriaRow(
            defect: 'Lack of Fusion',
            rule: 'Individual length ≤ 25mm. Zero root lack of fusion permitted on cross-country lines.',
          ),
          _CriteriaRow(
            defect: 'Undercut',
            rule: 'Depth ≤ 0.8mm or 12.5% pipe wall thickness (whichever is smaller) for ≤ 50mm length.',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: DIGITAL TPIA STAMP (EIL / OIL INSPECTOR)
  // ==========================================================================

  Widget _buildTpiaStampTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stamp Visual Badge
          _buildDigitalStampEmblemCard(),

          const SizedBox(height: 16),

          // Certificate Details
          _buildTpiaCertificateDetailsCard(),

          const SizedBox(height: 16),

          // Cryptographic Hash & Verification Audit Trail
          _buildTpiaAuditVerificationCard(),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppTheme.tertiary),
                  ),
                  icon: const Icon(Icons.fingerprint_rounded, color: AppTheme.tertiary),
                  label: const Text('Verify SHA-256 Hash', style: TextStyle(color: AppTheme.tertiary)),
                  onPressed: () => _showTpiaStampModal(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Export Quality Dossier'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF0F766E),
                        content: Text('📄 Generating EIL/OIL Quality Clearance Dossier PDF (WJ-0821 to 0835)...'),
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

  Widget _buildDigitalStampEmblemCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.6), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceCard,
            AppTheme.surfaceContainerHigh.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Circular Seal
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.secondary, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.tertiary, width: 1.5),
                color: AppTheme.surface,
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppTheme.tertiary, size: 28),
                    SizedBox(height: 2),
                    Text(
                      'TPIA',
                      style: TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'EIL / OIL',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'STATUTORY THIRD PARTY INSPECTION AGENCY (TPIA)',
            style: TextStyle(
              color: AppTheme.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ENGINEERS INDIA LIMITED & OIL INDIA LIMITED',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.tertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'CERTIFIED CLEARANCE STAMP • 100% AUDIT SATISFIED',
              style: TextStyle(
                color: AppTheme.tertiary,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTpiaCertificateDetailsCard() {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inspection Release Certificate Specifications',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildCertRow('Certificate ID', 'TPIA-EIL-OIL-WJ-2026-0981'),
            _buildCertRow('Project Package', '18" Crude Oil Trunk Pipeline Expansion (Section 03)'),
            _buildCertRow('Verified Weld Joints', '15 Joints (WJ-DUL-0821 to WJ-DUL-0835)'),
            _buildCertRow('Hydrostatic Section', 'Section 03 (Chainage 12+400 to 18+600) @ 112.5 Bar'),
            _buildCertRow('Lead TPIA Inspector', 'Er. Debashish Hazarika (ASNT Level III #RT-UT-19482)'),
            _buildCertRow('Owner QA Signatory', 'Er. Ananya Sharma (Chief QA/QC Manager - OIL)'),
            _buildCertRow('Date & Authority', '30 Sep 2026, 08:30 IST • Duliajan Field HQ'),
            _buildCertRow('Governing Standards', 'API 1104 22nd Ed., ASME B31.8 Cl. 841, OISD-141'),
          ],
        ),
      ),
    );
  }

  Widget _buildCertRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTpiaAuditVerificationCard() {
    // Generate deterministic SHA-256 seal for demonstration
    final payload = 'TPIA-EIL-OIL-2026-WJ0821-0835-112.5BAR-PASS';
    final shaHash = sha256.convert(utf8.encode(payload)).toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_clock_rounded, size: 16, color: AppTheme.primaryLight),
              SizedBox(width: 8),
              Text(
                'Digital Cryptographic Ledger Seal (SHA-256)',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(6),
            ),
            child: SelectableText(
              shaHash,
              style: const TextStyle(
                color: AppTheme.tertiary,
                fontSize: 11,
                fontFamily: 'monospace',
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This hash binds the 15 weld joints NDT radiographic results, 24-hr hydrostatic pressure log (112.5 Bar), and inspector digital signatures into an immutable tamper-evident record.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // MODALS & DIALOGS
  // ==========================================================================

  void _showPassRejectDefectModal(BuildContext context, PipelineWeldJoint joint) {
    NdtPassStatus localStatus = joint.overallStatus;
    RepairDefectType localDefect = joint.defectType;
    final posController = TextEditingController(text: joint.defectClockPosition == 'N/A' ? '02:30 to 03:45' : joint.defectClockPosition);
    final lengthController = TextEditingController(text: joint.defectLengthMm.toString());
    final depthController = TextEditingController(text: joint.defectDepthMm.toString());
    final remarksController = TextEditingController(text: joint.tpiaRemarks);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isReject = localStatus == NdtPassStatus.rejected || localStatus == NdtPassStatus.underRepair;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.rule_folder_rounded, color: AppTheme.primaryLight, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pass / Reject Inspection: ${joint.jointNo}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Chainage ${joint.chainage} • Welder: ${joint.welderName} (${joint.welderId})',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.border, height: 1),
                    const SizedBox(height: 14),

                    // Pass / Reject Toggle Buttons
                    const Text(
                      'NDT & VT OVERALL VERDICT',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                localStatus = NdtPassStatus.passed;
                                localDefect = RepairDefectType.none;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: localStatus == NdtPassStatus.passed
                                    ? AppTheme.tertiary.withValues(alpha: 0.2)
                                    : AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: localStatus == NdtPassStatus.passed
                                      ? AppTheme.tertiary
                                      : AppTheme.border,
                                  width: localStatus == NdtPassStatus.passed ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: localStatus == NdtPassStatus.passed
                                        ? AppTheme.tertiary
                                        : AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PASS (ACCEPTED)',
                                    style: TextStyle(
                                      color: localStatus == NdtPassStatus.passed
                                          ? AppTheme.tertiary
                                          : AppTheme.textMuted,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                localStatus = NdtPassStatus.rejected;
                                if (localDefect == RepairDefectType.none) {
                                  localDefect = RepairDefectType.slagInclusion;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: localStatus == NdtPassStatus.rejected
                                    ? AppTheme.error.withValues(alpha: 0.2)
                                    : AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: localStatus == NdtPassStatus.rejected
                                      ? AppTheme.error
                                      : AppTheme.border,
                                  width: localStatus == NdtPassStatus.rejected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cancel_rounded,
                                    size: 16,
                                    color: localStatus == NdtPassStatus.rejected
                                        ? AppTheme.error
                                        : AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'REJECT (REPAIR)',
                                    style: TextStyle(
                                      color: localStatus == NdtPassStatus.rejected
                                          ? AppTheme.error
                                          : AppTheme.textMuted,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Repair Defect Classification options (If rejected)
                    if (isReject) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'DEFECT CLASSIFICATION CATEGORY (API 1104 §9)',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 4 Defect Types
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDefectTypeChip(
                            type: RepairDefectType.slagInclusion,
                            current: localDefect,
                            onTap: (t) => setModalState(() => localDefect = t),
                          ),
                          _buildDefectTypeChip(
                            type: RepairDefectType.porosity,
                            current: localDefect,
                            onTap: (t) => setModalState(() => localDefect = t),
                          ),
                          _buildDefectTypeChip(
                            type: RepairDefectType.lackOfFusion,
                            current: localDefect,
                            onTap: (t) => setModalState(() => localDefect = t),
                          ),
                          _buildDefectTypeChip(
                            type: RepairDefectType.undercut,
                            current: localDefect,
                            onTap: (t) => setModalState(() => localDefect = t),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: posController,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'Clock Position (e.g. 02:30)',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: lengthController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'Length (mm)',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: depthController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'Depth (mm)',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    TextField(
                      controller: remarksController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'TPIA & QA Inspection Remarks',
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Save / Commit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: localStatus == NdtPassStatus.passed ? AppTheme.tertiary : AppTheme.error,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            joint.overallStatus = localStatus;
                            joint.defectType = localDefect;
                            if (localStatus == NdtPassStatus.passed) {
                              joint.rtStatus = NdtPassStatus.passed;
                              joint.utStatus = NdtPassStatus.passed;
                              joint.vtStatus = NdtPassStatus.passed;
                              joint.mptStatus = NdtPassStatus.passed;
                              joint.isTpiaApproved = true;
                              joint.tpiaRemarks = remarksController.text.isEmpty
                                  ? 'Accepted per API 1104 22nd Edition'
                                  : remarksController.text;
                            } else {
                              joint.rtStatus = NdtPassStatus.rejected;
                              joint.defectClockPosition = posController.text;
                              joint.defectLengthMm = double.tryParse(lengthController.text) ?? 20.0;
                              joint.defectDepthMm = double.tryParse(depthController.text) ?? 2.5;
                              joint.isTpiaApproved = false;
                              joint.tpiaRemarks = remarksController.text.isEmpty
                                  ? 'Rejected: ${localDefect.label} repair required.'
                                  : remarksController.text;
                            }
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: localStatus == NdtPassStatus.passed
                                  ? const Color(0xFF064E3B)
                                  : const Color(0xFF7F1D1D),
                              content: Text('Updated ${joint.jointNo}: ${localStatus == NdtPassStatus.passed ? "PASSED & APPROVED" : "REJECTED (${localDefect.label})" }'),
                            ),
                          );
                        },
                        child: Text(
                          localStatus == NdtPassStatus.passed ? 'Confirm Pass & Approve Joint' : 'Save Defect & Issue Repair Order',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
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

  Widget _buildDefectTypeChip({
    required RepairDefectType type,
    required RepairDefectType current,
    required Function(RepairDefectType) onTap,
  }) {
    final isSelected = type == current;

    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondary.withValues(alpha: 0.2) : AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.secondary : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type.icon, size: 14, color: isSelected ? AppTheme.secondary : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              type.label,
              style: TextStyle(
                color: isSelected ? AppTheme.secondary : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTpiaStampModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.verified_user_rounded, color: AppTheme.tertiary, size: 44),
              const SizedBox(height: 10),
              const Text(
                'Digital TPIA Statutory Release Stamp',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Engineers India Limited (EIL) & Oil India Limited (OIL QA/QC)',
                style: TextStyle(color: AppTheme.secondary, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: const [
                    _ModalItem(label: 'Weld Joints', val: 'WJ-DUL-0821 to WJ-DUL-0835 (15 Joints)'),
                    _ModalItem(label: 'Hydrotest Chainage', val: '12+400 to 18+600 (Section 03)'),
                    _ModalItem(label: 'Test Pressure Hold', val: '112.5 Bar (24-Hour DWT Monitored)'),
                    _ModalItem(label: 'Pressure Drop ΔP', val: '0.11 Bar (< 0.20 Bar Limit Satisfied)'),
                    _ModalItem(label: 'Lead TPIA Inspector', val: 'Er. Debashish Hazarika (ASNT L3 #19482)'),
                    _ModalItem(label: 'Owner QA Manager', val: 'Er. Ananya Sharma (OIL Directorate)'),
                    _ModalItem(label: 'Audit Status', val: '100% Cryptographically Verified & Sealed'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close Verification Window'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// HELPER SUB-WIDGETS
// ============================================================================

class ContainerBadge extends StatelessWidget {
  final String label;
  final Color color;

  const ContainerBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CriteriaRow extends StatelessWidget {
  final String defect;
  final String rule;

  const _CriteriaRow({
    required this.defect,
    required this.rule,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: Text(
              defect,
              style: const TextStyle(
                color: AppTheme.primaryLight,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rule,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalItem extends StatelessWidget {
  final String label;
  final String val;

  const _ModalItem({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          Text(val, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
