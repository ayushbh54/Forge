import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS
// ============================================================================

enum PipeMill {
  jindalSaw('Jindal SAW (Mundra)', 'JINDAL', Color(0xFF38BDF8)),
  welspun('Welspun Corp (Anjar)', 'WELSPUN', Color(0xFFFFB95F)),
  sail('SAIL (Rourkela RSP)', 'SAIL', Color(0xFF4EDEA3));

  final String fullName;
  final String shortCode;
  final Color brandColor;

  const PipeMill(this.fullName, this.shortCode, this.brandColor);
}

enum WallThicknessType {
  mainline95(9.5, '9.5 mm Mainline', 'Class 600 • 0.72 DF'),
  riverCrossing127(12.7, '12.7 mm River Crossing', 'Burhi Dihing / HDD • 0.50 DF');

  final double thicknessMm;
  final String label;
  final String designFactor;

  const WallThicknessType(this.thicknessMm, this.label, this.designFactor);
}

enum PipeStatus {
  inYard('In Dump Yard', Icons.warehouse_rounded, Color(0xFF38BDF8)),
  strung('Strung on RoW', Icons.linear_scale_rounded, Color(0xFFFFB95F)),
  welded('Welded in Trench', Icons.check_circle_outline_rounded, Color(0xFF4EDEA3)),
  pupCut('Cut / Pup Piece', Icons.content_cut_rounded, Color(0xFFA78BFA)),
  quarantined('Quarantine / Hold', Icons.warning_amber_rounded, Color(0xFFFF5252));

  final String label;
  final IconData icon;
  final Color color;

  const PipeStatus(this.label, this.icon, this.color);
}

enum DumpYardLocation {
  duliajan('Duliajan Central Yard', 'FHQ Main Depot • Ch 00+000', Color(0xFF0284C7)),
  moran('Moran Intermediate Yard', 'Section-2 Depot • Ch 78+400', Color(0xFFFFB95F)),
  numaligarh('Numaligarh Terminal Yard', 'Refinery Spur • Ch 194+500', Color(0xFF4EDEA3)),
  rowCorridor('RoW Pipeline Corridor', 'Active Stringing Line', Color(0xFFA78BFA));

  final String displayName;
  final String subtitle;
  final Color accentColor;

  const DumpYardLocation(this.displayName, this.subtitle, this.accentColor);
}

class MtcCertificate {
  final String heatNumber;
  final String coilNumber;
  final String mtcNumber;
  final String standard;
  final String en10204Type;
  final String tpiaAgency;
  final double yieldStrengthMpa; // Rt0.5 > 485 MPa
  final double tensileStrengthMpa; // Rm > 570 MPa
  final double yieldTensileRatio; // < 0.90
  final double carbonEquivalentPcm; // CE_Pcm < 0.20%
  final double charpyImpactJoulesMinus20; // Avg >= 120 Joules at -20°C
  final double dwttShearAreaPercent; // Min 85% at -10°C
  final Map<String, double> chemistry; // C, Mn, Si, P, S, Nb, V, Ti, Mo, Cu, Ni, B
  final bool isVerified32;
  final String sha256Hash;

  const MtcCertificate({
    required this.heatNumber,
    required this.coilNumber,
    required this.mtcNumber,
    required this.standard,
    required this.en10204Type,
    required this.tpiaAgency,
    required this.yieldStrengthMpa,
    required this.tensileStrengthMpa,
    required this.yieldTensileRatio,
    required this.carbonEquivalentPcm,
    required this.charpyImpactJoulesMinus20,
    required this.dwttShearAreaPercent,
    required this.chemistry,
    required this.isVerified32,
    required this.sha256Hash,
  });

  bool get passesYield => yieldStrengthMpa >= 485.0 && yieldStrengthMpa <= 605.0;
  bool get passesTensile => tensileStrengthMpa >= 570.0 && tensileStrengthMpa <= 760.0;
  bool get passesYTRatio => yieldTensileRatio <= 0.90;
  bool get passesCarbonEquivalent => carbonEquivalentPcm <= 0.20;
  bool get passesCharpy => charpyImpactJoulesMinus20 >= 120.0;
  bool get passesDwtt => dwttShearAreaPercent >= 85.0;

  bool get isFullyCompliant =>
      passesYield &&
      passesTensile &&
      passesYTRatio &&
      passesCarbonEquivalent &&
      passesCharpy &&
      passesDwtt;
}

class FieldInspectionRecord {
  final DateTime inspectedAt;
  final String inspectorName;
  final String tpiaWitness;
  final String chainage;
  final String rowSide;
  final double elevationMeters;
  final double bevelRootFaceMm; // 1.6 mm ± 0.8 mm
  final double bevelAngleDeg; // 30° (+5° / -0°)
  final bool bevelLaminationFree;
  final double coatingDftMicrons; // >= 2500 µm
  final double holidayVoltageKv; // 25.0 kV
  final bool holidayPassed;

  const FieldInspectionRecord({
    required this.inspectedAt,
    required this.inspectorName,
    required this.tpiaWitness,
    required this.chainage,
    required this.rowSide,
    required this.elevationMeters,
    required this.bevelRootFaceMm,
    required this.bevelAngleDeg,
    required this.bevelLaminationFree,
    required this.coatingDftMicrons,
    required this.holidayVoltageKv,
    required this.holidayPassed,
  });

  bool get isCompliant =>
      bevelRootFaceMm >= 0.8 &&
      bevelRootFaceMm <= 2.4 &&
      bevelAngleDeg >= 30.0 &&
      bevelAngleDeg <= 35.0 &&
      bevelLaminationFree &&
      coatingDftMicrons >= 2500.0 &&
      holidayPassed;
}

class PupPieceRecord {
  final String pupId;
  final String parentPipeId;
  final String heatNumber;
  final PipeMill mill;
  final double cutLengthM;
  final double remainingParentLengthM;
  final double wallThicknessMm;
  final String intendedApplication;
  final bool stencilHardStamped;
  final DateTime cutDate;
  final String certifiedBy;

  const PupPieceRecord({
    required this.pupId,
    required this.parentPipeId,
    required this.heatNumber,
    required this.mill,
    required this.cutLengthM,
    required this.remainingParentLengthM,
    required this.wallThicknessMm,
    required this.intendedApplication,
    required this.stencilHardStamped,
    required this.cutDate,
    required this.certifiedBy,
  });
}

class PipeRecord {
  final String uniqueId; // OIL-24-X70-XXXX
  final String heatNumber;
  final String coilNumber;
  final PipeMill mill;
  final WallThicknessType wallThickness;
  double lengthM;
  double weightKg;
  PipeStatus status;
  DumpYardLocation yardLocation;
  final MtcCertificate mtc;
  FieldInspectionRecord? inspection;
  final bool isPupPiece;
  final String? parentPipeId;
  String? chainageAllocated;

  PipeRecord({
    required this.uniqueId,
    required this.heatNumber,
    required this.coilNumber,
    required this.mill,
    required this.wallThickness,
    required this.lengthM,
    required this.weightKg,
    required this.status,
    required this.yardLocation,
    required this.mtc,
    this.inspection,
    this.isPupPiece = false,
    this.parentPipeId,
    this.chainageAllocated,
  });

  static double calculateApi5lWeight(double outsideDiameterMm, double wallThicknessMm, double lengthM) {
    // API 5L theoretical pipe weight formula: W = 0.0246615 * (D - t) * t * L
    return 0.0246615 * (outsideDiameterMm - wallThicknessMm) * wallThicknessMm * lengthM;
  }
}

class YardStockSummary {
  final DumpYardLocation yard;
  final int totalReceived;
  final int strungToRow;
  final int currentInYard;
  final int quarantinedCount;
  final int mainline95Count;
  final int heavyWall127Count;
  final String lastAuditDate;
  final int auditVariance;

  const YardStockSummary({
    required this.yard,
    required this.totalReceived,
    required this.strungToRow,
    required this.currentInYard,
    required this.quarantinedCount,
    required this.mainline95Count,
    required this.heavyWall127Count,
    required this.lastAuditDate,
    required this.auditVariance,
  });
}

// ============================================================================
// SCREEN WIDGET
// ============================================================================

class PipeHeatTallyScreen extends StatefulWidget {
  const PipeHeatTallyScreen({super.key});

  @override
  State<PipeHeatTallyScreen> createState() => _PipeHeatTallyScreenState();
}

class _PipeHeatTallyScreenState extends State<PipeHeatTallyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filters
  String _searchQuery = '';
  WallThicknessType? _filterThickness;
  PipeMill? _filterMill;
  PipeStatus? _filterStatus;
  DumpYardLocation? _filterYard;

  // Master Data
  late List<PipeRecord> _pipes;
  late List<PupPieceRecord> _pupPieces;
  late List<YardStockSummary> _yardSummaries;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    // Master MTC certificates
    final mtcJindal = MtcCertificate(
      heatNumber: 'H-89412',
      coilNumber: 'CL-5501A',
      mtcNumber: 'MTC-JSW-2024-8841',
      standard: 'API Spec 5L PSL-2 / ISO 3183',
      en10204Type: 'EN 10204 Type 3.2',
      tpiaAgency: 'Engineers India Limited (EIL)',
      yieldStrengthMpa: 524.5,
      tensileStrengthMpa: 631.2,
      yieldTensileRatio: 0.831,
      carbonEquivalentPcm: 0.165,
      charpyImpactJoulesMinus20: 178.4,
      dwttShearAreaPercent: 96.0,
      chemistry: {
        'C': 0.058,
        'Mn': 1.58,
        'Si': 0.24,
        'P': 0.011,
        'S': 0.002,
        'Nb': 0.046,
        'V': 0.038,
        'Ti': 0.015,
        'Mo': 0.18,
        'Cu': 0.14,
        'Ni': 0.22,
        'B': 0.0003,
      },
      isVerified32: true,
      sha256Hash: sha256.convert(utf8.encode('H-89412-MTC-JSW-EIL-VERIFIED')).toString(),
    );

    final mtcWelspun = MtcCertificate(
      heatNumber: 'H-89413',
      coilNumber: 'CL-5502B',
      mtcNumber: 'MTC-WEL-2024-9102',
      standard: 'API Spec 5L PSL-2 / ISO 3183',
      en10204Type: 'EN 10204 Type 3.2',
      tpiaAgency: 'Bureau Veritas (BVQI / Oil India)',
      yieldStrengthMpa: 538.0,
      tensileStrengthMpa: 644.0,
      yieldTensileRatio: 0.835,
      carbonEquivalentPcm: 0.172,
      charpyImpactJoulesMinus20: 164.0,
      dwttShearAreaPercent: 94.5,
      chemistry: {
        'C': 0.061,
        'Mn': 1.62,
        'Si': 0.26,
        'P': 0.012,
        'S': 0.0018,
        'Nb': 0.049,
        'V': 0.041,
        'Ti': 0.016,
        'Mo': 0.19,
        'Cu': 0.12,
        'Ni': 0.25,
        'B': 0.0004,
      },
      isVerified32: true,
      sha256Hash: sha256.convert(utf8.encode('H-89413-MTC-WEL-BV-VERIFIED')).toString(),
    );

    final mtcSail = MtcCertificate(
      heatNumber: 'H-89520',
      coilNumber: 'CL-7104C',
      mtcNumber: 'MTC-SAIL-2024-3401',
      standard: 'API Spec 5L PSL-2 / ISO 3183',
      en10204Type: 'EN 10204 Type 3.2',
      tpiaAgency: 'DNV GL / Engineers India Limited',
      yieldStrengthMpa: 512.0,
      tensileStrengthMpa: 618.5,
      yieldTensileRatio: 0.828,
      carbonEquivalentPcm: 0.158,
      charpyImpactJoulesMinus20: 192.0,
      dwttShearAreaPercent: 98.0,
      chemistry: {
        'C': 0.054,
        'Mn': 1.52,
        'Si': 0.22,
        'P': 0.009,
        'S': 0.0015,
        'Nb': 0.044,
        'V': 0.035,
        'Ti': 0.014,
        'Mo': 0.16,
        'Cu': 0.11,
        'Ni': 0.20,
        'B': 0.0002,
      },
      isVerified32: true,
      sha256Hash: sha256.convert(utf8.encode('H-89520-MTC-SAIL-DNV-VERIFIED')).toString(),
    );

    final mtcRiverCrossing = MtcCertificate(
      heatNumber: 'H-89601',
      coilNumber: 'CL-8820X',
      mtcNumber: 'MTC-JSW-2024-9912',
      standard: 'API Spec 5L PSL-2 / ISO 3183',
      en10204Type: 'EN 10204 Type 3.2',
      tpiaAgency: 'Engineers India Limited (EIL)',
      yieldStrengthMpa: 546.0,
      tensileStrengthMpa: 652.0,
      yieldTensileRatio: 0.837,
      carbonEquivalentPcm: 0.178,
      charpyImpactJoulesMinus20: 155.0,
      dwttShearAreaPercent: 92.0,
      chemistry: {
        'C': 0.065,
        'Mn': 1.68,
        'Si': 0.28,
        'P': 0.010,
        'S': 0.0019,
        'Nb': 0.052,
        'V': 0.045,
        'Ti': 0.018,
        'Mo': 0.21,
        'Cu': 0.15,
        'Ni': 0.28,
        'B': 0.0004,
      },
      isVerified32: true,
      sha256Hash: sha256.convert(utf8.encode('H-89601-MTC-JSW-RIVER-VERIFIED')).toString(),
    );

    // Initial Pipe Records
    _pipes = [
      PipeRecord(
        uniqueId: 'OIL-24-X70-1001',
        heatNumber: 'H-89412',
        coilNumber: 'CL-5501A',
        mill: PipeMill.jindalSaw,
        wallThickness: WallThicknessType.mainline95,
        lengthM: 12.18,
        weightKg: 1713.6,
        status: PipeStatus.welded,
        yardLocation: DumpYardLocation.rowCorridor,
        mtc: mtcJindal,
        chainageAllocated: 'Ch 14+250.0 to 14+262.18',
        inspection: FieldInspectionRecord(
          inspectedAt: DateTime.now().subtract(const Duration(days: 3)),
          inspectorName: 'B. K. Gogoi (QA Lead)',
          tpiaWitness: 'R. K. Sharma (EIL Inspector)',
          chainage: 'Ch 14+250.00',
          rowSide: 'Left of RoW',
          elevationMeters: 118.4,
          bevelRootFaceMm: 1.6,
          bevelAngleDeg: 30.5,
          bevelLaminationFree: true,
          coatingDftMicrons: 2740.0,
          holidayVoltageKv: 25.0,
          holidayPassed: true,
        ),
      ),
      PipeRecord(
        uniqueId: 'OIL-24-X70-1002',
        heatNumber: 'H-89412',
        coilNumber: 'CL-5501A',
        mill: PipeMill.jindalSaw,
        wallThickness: WallThicknessType.mainline95,
        lengthM: 12.24,
        weightKg: 1722.1,
        status: PipeStatus.strung,
        yardLocation: DumpYardLocation.rowCorridor,
        mtc: mtcJindal,
        chainageAllocated: 'Ch 14+262.18 to 14+274.42',
        inspection: FieldInspectionRecord(
          inspectedAt: DateTime.now().subtract(const Duration(days: 2)),
          inspectorName: 'B. K. Gogoi (QA Lead)',
          tpiaWitness: 'R. K. Sharma (EIL Inspector)',
          chainage: 'Ch 14+262.18',
          rowSide: 'Left of RoW',
          elevationMeters: 118.6,
          bevelRootFaceMm: 1.5,
          bevelAngleDeg: 31.0,
          bevelLaminationFree: true,
          coatingDftMicrons: 2810.0,
          holidayVoltageKv: 25.0,
          holidayPassed: true,
        ),
      ),
      PipeRecord(
        uniqueId: 'OIL-24-X70-1003',
        heatNumber: 'H-89413',
        coilNumber: 'CL-5502B',
        mill: PipeMill.welspun,
        wallThickness: WallThicknessType.mainline95,
        lengthM: 12.05,
        weightKg: 1695.3,
        status: PipeStatus.inYard,
        yardLocation: DumpYardLocation.duliajan,
        mtc: mtcWelspun,
        chainageAllocated: null,
      ),
      PipeRecord(
        uniqueId: 'OIL-24-X70-1004',
        heatNumber: 'H-89413',
        coilNumber: 'CL-5502B',
        mill: PipeMill.welspun,
        wallThickness: WallThicknessType.mainline95,
        lengthM: 12.30,
        weightKg: 1730.5,
        status: PipeStatus.inYard,
        yardLocation: DumpYardLocation.moran,
        mtc: mtcWelspun,
        chainageAllocated: null,
      ),
      PipeRecord(
        uniqueId: 'OIL-24-X70-1005',
        heatNumber: 'H-89520',
        coilNumber: 'CL-7104C',
        mill: PipeMill.sail,
        wallThickness: WallThicknessType.mainline95,
        lengthM: 11.95,
        weightKg: 1681.3,
        status: PipeStatus.strung,
        yardLocation: DumpYardLocation.rowCorridor,
        mtc: mtcSail,
        chainageAllocated: 'Ch 78+600.0 to 78+611.95',
      ),
      PipeRecord(
        uniqueId: 'OIL-24-X70-1006-HD',
        heatNumber: 'H-89601',
        coilNumber: 'CL-8820X',
        mill: PipeMill.jindalSaw,
        wallThickness: WallThicknessType.riverCrossing127,
        lengthM: 12.15,
        weightKg: 2273.0,
        status: PipeStatus.inYard,
        yardLocation: DumpYardLocation.numaligarh,
        mtc: mtcRiverCrossing,
        chainageAllocated: 'Burhi Dihing HDD Staging',
      ),
      PipeRecord(
        uniqueId: 'OIL-24-X70-1007-HD',
        heatNumber: 'H-89601',
        coilNumber: 'CL-8820X',
        mill: PipeMill.jindalSaw,
        wallThickness: WallThicknessType.riverCrossing127,
        lengthM: 12.20,
        weightKg: 2282.3,
        status: PipeStatus.strung,
        yardLocation: DumpYardLocation.rowCorridor,
        mtc: mtcRiverCrossing,
        chainageAllocated: 'Ch 42+110.0 to 42+122.20 (River)',
      ),
      PipeRecord(
        uniqueId: 'OIL-24-X70-1008',
        heatNumber: 'H-89412',
        coilNumber: 'CL-5501A',
        mill: PipeMill.jindalSaw,
        wallThickness: WallThicknessType.mainline95,
        lengthM: 7.78,
        weightKg: 1094.6,
        status: PipeStatus.pupCut,
        yardLocation: DumpYardLocation.duliajan,
        mtc: mtcJindal,
        isPupPiece: true,
        parentPipeId: 'OIL-24-X70-1042',
        chainageAllocated: 'Duliajan Scraper Trap Tie-in',
      ),
      PipeRecord(
        uniqueId: 'OIL-24-X70-1009',
        heatNumber: 'H-89413',
        coilNumber: 'CL-5502B',
        mill: PipeMill.welspun,
        wallThickness: WallThicknessType.mainline95,
        lengthM: 12.10,
        weightKg: 1702.3,
        status: PipeStatus.quarantined,
        yardLocation: DumpYardLocation.moran,
        mtc: mtcWelspun,
        chainageAllocated: null,
      ),
    ];

    // Pup pieces
    _pupPieces = [
      PupPieceRecord(
        pupId: 'OIL-24-X70-1042-P1',
        parentPipeId: 'OIL-24-X70-1042',
        heatNumber: 'H-89412',
        mill: PipeMill.jindalSaw,
        cutLengthM: 4.40,
        remainingParentLengthM: 7.78,
        wallThicknessMm: 9.5,
        intendedApplication: 'Burhi Dihing HDD Entry Tie-In Spool',
        stencilHardStamped: true,
        cutDate: DateTime.now().subtract(const Duration(days: 5)),
        certifiedBy: 'T. Sarma (Level II UT / QA)',
      ),
      PupPieceRecord(
        pupId: 'OIL-24-X70-1015-P2',
        parentPipeId: 'OIL-24-X70-1015',
        heatNumber: 'H-89520',
        mill: PipeMill.sail,
        cutLengthM: 3.85,
        remainingParentLengthM: 8.10,
        wallThicknessMm: 9.5,
        intendedApplication: 'Moran Intermediate Valve Station VS-03 Tie-in',
        stencilHardStamped: true,
        cutDate: DateTime.now().subtract(const Duration(days: 8)),
        certifiedBy: 'M. Dutta (Resident QC)',
      ),
      PupPieceRecord(
        pupId: 'OIL-24-X70-1090-P1',
        parentPipeId: 'OIL-24-X70-1090',
        heatNumber: 'H-89601',
        mill: PipeMill.jindalSaw,
        cutLengthM: 5.20,
        remainingParentLengthM: 6.95,
        wallThicknessMm: 12.7,
        intendedApplication: 'Disang River Crossing HDD Heavy-Wall Spool',
        stencilHardStamped: true,
        cutDate: DateTime.now().subtract(const Duration(days: 12)),
        certifiedBy: 'K. Baruah (EIL TPIA Witness)',
      ),
    ];

    // Yard stock reconciliation matrix
    _yardSummaries = [
      const YardStockSummary(
        yard: DumpYardLocation.duliajan,
        totalReceived: 620,
        strungToRow: 485,
        currentInYard: 133,
        quarantinedCount: 2,
        mainline95Count: 110,
        heavyWall127Count: 23,
        lastAuditDate: '28-Sep-2026',
        auditVariance: 0,
      ),
      const YardStockSummary(
        yard: DumpYardLocation.moran,
        totalReceived: 510,
        strungToRow: 440,
        currentInYard: 68,
        quarantinedCount: 2,
        mainline95Count: 56,
        heavyWall127Count: 12,
        lastAuditDate: '29-Sep-2026',
        auditVariance: 0,
      ),
      const YardStockSummary(
        yard: DumpYardLocation.numaligarh,
        totalReceived: 290,
        strungToRow: 260,
        currentInYard: 30,
        quarantinedCount: 0,
        mainline95Count: 18,
        heavyWall127Count: 12,
        lastAuditDate: '27-Sep-2026',
        auditVariance: 0,
      ),
    ];
  }

  List<PipeRecord> get _filteredPipes {
    return _pipes.where((pipe) {
      final matchesQuery = _searchQuery.isEmpty ||
          pipe.uniqueId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pipe.heatNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pipe.coilNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pipe.mill.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (pipe.chainageAllocated?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      if (!matchesQuery) return false;

      if (_filterThickness != null && pipe.wallThickness != _filterThickness) {
        return false;
      }
      if (_filterMill != null && pipe.mill != _filterMill) {
        return false;
      }
      if (_filterStatus != null && pipe.status != _filterStatus) {
        return false;
      }
      if (_filterYard != null && pipe.yardLocation != _filterYard) {
        return false;
      }

      return true;
    }).toList();
  }

  // ============================================================================
  // BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildKpiMetricsStrip(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPipeRegistryTab(),
                _buildMtcCertificatesTab(),
                _buildScanningAndPupTab(),
                _buildYardReconciliationTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddPipeDialog,
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.textPrimary,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Pipe',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Pipe Heat Tally & Traceability',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'API Spec 5L PSL-2 / ISO 3183 • Oil India Limited',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF4EDEA3).withAlpha(25),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF4EDEA3).withAlpha(100)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.verified_rounded, size: 14, color: Color(0xFF4EDEA3)),
              SizedBox(width: 4),
              Text(
                'EN 10204 3.2',
                style: TextStyle(
                  color: Color(0xFF4EDEA3),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiMetricsStrip() {
    final totalCount = _pipes.length;
    final strungCount = _pipes.where((p) => p.status == PipeStatus.strung || p.status == PipeStatus.welded).length;
    final yardCount = _pipes.where((p) => p.status == PipeStatus.inYard).length;
    final heavyWallCount = _pipes.where((p) => p.wallThickness == WallThicknessType.riverCrossing127).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: const Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildKpiCard(
            label: 'TOTAL PIPES',
            value: '$totalCount',
            subtext: 'API 5L X70',
            icon: Icons.view_in_ar_rounded,
            color: AppTheme.primaryLight,
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            label: 'STRUNG / WELDED',
            value: '$strungCount',
            subtext: '${((strungCount / totalCount) * 100).toStringAsFixed(0)}% deployed',
            icon: Icons.linear_scale_rounded,
            color: AppTheme.tertiary,
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            label: 'YARD STOCK',
            value: '$yardCount',
            subtext: 'Across 3 depots',
            icon: Icons.warehouse_rounded,
            color: AppTheme.secondary,
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            label: 'HEAVY WALL',
            value: '$heavyWallCount',
            subtext: '12.7mm HDD',
            icon: Icons.shield_rounded,
            color: const Color(0xFFA78BFA),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withAlpha(120),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtext,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 8.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        onTap: (_) => setState(() {}),
        tabs: const [
          Tab(
            icon: Icon(Icons.table_rows_rounded, size: 18),
            text: 'Pipe Tally Registry',
          ),
          Tab(
            icon: Icon(Icons.verified_user_rounded, size: 18),
            text: 'MTC EN 10204 (3.2)',
          ),
          Tab(
            icon: Icon(Icons.qr_code_scanner_rounded, size: 18),
            text: 'Scan & Pup Tracking',
          ),
          Tab(
            icon: Icon(Icons.sync_alt_rounded, size: 18),
            text: 'Yard Stock Reconcile',
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: PIPE REGISTRY (ELECTRONIC PIPE TALLY BOOK)
  // ============================================================================

  Widget _buildPipeRegistryTab() {
    final filtered = _filteredPipes;

    return Column(
      children: [
        // Search & Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search Pipe ID (OIL-24-X70-XXXX), Heat, Coil, Mill...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 16),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surfaceCard,
                  isDense: true,
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
              const SizedBox(height: 8),
              // Filter chips row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'All Thickness',
                      isSelected: _filterThickness == null,
                      onTap: () => setState(() => _filterThickness = null),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: '9.5mm Mainline',
                      isSelected: _filterThickness == WallThicknessType.mainline95,
                      onTap: () => setState(() => _filterThickness =
                          _filterThickness == WallThicknessType.mainline95 ? null : WallThicknessType.mainline95),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: '12.7mm River HDD',
                      isSelected: _filterThickness == WallThicknessType.riverCrossing127,
                      onTap: () => setState(() => _filterThickness =
                          _filterThickness == WallThicknessType.riverCrossing127 ? null : WallThicknessType.riverCrossing127),
                    ),
                    const SizedBox(width: 12),
                    Container(height: 18, width: 1, color: AppTheme.border),
                    const SizedBox(width: 12),
                    _buildFilterChip(
                      label: 'All Mills',
                      isSelected: _filterMill == null,
                      onTap: () => setState(() => _filterMill = null),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: 'Jindal SAW',
                      isSelected: _filterMill == PipeMill.jindalSaw,
                      onTap: () => setState(() => _filterMill =
                          _filterMill == PipeMill.jindalSaw ? null : PipeMill.jindalSaw),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: 'Welspun',
                      isSelected: _filterMill == PipeMill.welspun,
                      onTap: () => setState(() => _filterMill =
                          _filterMill == PipeMill.welspun ? null : PipeMill.welspun),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: 'SAIL',
                      isSelected: _filterMill == PipeMill.sail,
                      onTap: () => setState(() => _filterMill =
                          _filterMill == PipeMill.sail ? null : PipeMill.sail),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List of Pipes
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('No pipe registry records found matching your query.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final pipe = filtered[index];
                    return _buildPipeCard(pipe);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withAlpha(50) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPipeCard(PipeRecord pipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pipe.status == PipeStatus.quarantined
              ? const Color(0xFFFF5252).withAlpha(120)
              : AppTheme.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPipeDetailsModal(pipe),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Pipe ID, Mill, Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primaryLight.withAlpha(80)),
                    ),
                    child: Text(
                      pipe.uniqueId,
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: pipe.mill.brandColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pipe.mill.shortCode,
                      style: TextStyle(
                        color: pipe.mill.brandColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (pipe.isPupPiece) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA78BFA).withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PUP PIECE',
                        style: TextStyle(
                          color: Color(0xFFA78BFA),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: pipe.status.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: pipe.status.color.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(pipe.status.icon, size: 12, color: pipe.status.color),
                        const SizedBox(width: 4),
                        Text(
                          pipe.status.label,
                          style: TextStyle(
                            color: pipe.status.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Specifications Grid
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withAlpha(160),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildSpecItem('HEAT NUMBER', pipe.heatNumber, isHighlighted: true),
                        _buildSpecItem('COIL NUMBER', pipe.coilNumber),
                        _buildSpecItem(
                          'WALL THICKNESS',
                          pipe.wallThickness.label,
                          customColor: pipe.wallThickness == WallThicknessType.riverCrossing127
                              ? const Color(0xFFFFB95F)
                              : AppTheme.textPrimary,
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.border, height: 16),
                    Row(
                      children: [
                        _buildSpecItem('LENGTH', '${pipe.lengthM.toStringAsFixed(2)} m'),
                        _buildSpecItem('WEIGHT', '${pipe.weightKg.toStringAsFixed(1)} kg'),
                        _buildSpecItem(
                          'LOCATION',
                          pipe.chainageAllocated ?? pipe.yardLocation.displayName,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Bottom Actions: MTC preview, Inspection, Pup
              Row(
                children: [
                  Icon(
                    pipe.mtc.isFullyCompliant ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    size: 14,
                    color: pipe.mtc.isFullyCompliant ? AppTheme.tertiary : AppTheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'MTC 3.2: Rt0.5 ${pipe.mtc.yieldStrengthMpa.toInt()} MPa • CE ${pipe.mtc.carbonEquivalentPcm}%',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppTheme.primaryLight,
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 13),
                    label: const Text('Actions', style: TextStyle(fontSize: 11)),
                    onPressed: () => _showPipeDetailsModal(pipe),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value, {bool isHighlighted = false, Color? customColor, int maxLines = 1}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: customColor ?? (isHighlighted ? AppTheme.primaryLight : AppTheme.textPrimary),
              fontSize: 11.5,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: MILL TEST CERTIFICATE (MTC EN 10204 3.1 & 3.2)
  // ============================================================================

  Widget _buildMtcCertificatesTab() {
    // Unique heats
    final heats = <String, MtcCertificate>{};
    for (final pipe in _pipes) {
      heats[pipe.mtc.heatNumber] = pipe.mtc;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MTC Specification Standard Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.surfaceCard,
                  AppTheme.surfaceContainerHigh.withAlpha(160),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                        color: AppTheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: AppTheme.primaryLight, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'EN 10204 Type 3.2 Dual Inspection',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Mandatory TPIA endorsement (EIL / DNV / BV) for Oil India mainline',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'API 5L PSL-2 / ISO 3183 ACCEPTANCE CRITERIA:',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMtcStandardRequirementGrid(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Active Heat Batches
          Row(
            children: [
              const Text(
                'VERIFIED HEAT BATCHES',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${heats.length} Heats Registered',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...heats.values.map((mtc) => _buildMtcHeatCard(mtc)),
        ],
      ),
    );
  }

  Widget _buildMtcStandardRequirementGrid() {
    return Column(
      children: [
        Row(
          children: [
            _buildStandardReqTile('Yield Strength (Rt0.5)', 'Min 485 MPa', 'Max 605 MPa', true),
            const SizedBox(width: 8),
            _buildStandardReqTile('Tensile Strength (Rm)', 'Min 570 MPa', 'Max 760 MPa', true),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStandardReqTile('Carbon Equiv (CE_Pcm)', '≤ 0.20%', 'Ladle + Product', true),
            const SizedBox(width: 8),
            _buildStandardReqTile('Charpy V-Notch (CVN)', '≥ 120 Joules', 'Transverse @ -20°C', true),
          ],
        ),
      ],
    );
  }

  Widget _buildStandardReqTile(String title, String criteria, String subtext, bool passed) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface.withAlpha(150),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border.withAlpha(120)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  criteria,
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.check_circle, size: 12, color: AppTheme.tertiary),
              ],
            ),
            Text(
              subtext,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 8.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMtcHeatCard(MtcCertificate mtc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'HEAT: ${mtc.heatNumber}',
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Coil: ${mtc.coilNumber}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.tertiary.withAlpha(100)),
                ),
                child: const Text(
                  '3.2 TPIA APPROVED',
                  style: TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${mtc.mtcNumber} • Witness: ${mtc.tpiaAgency}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Mechanical Results Grid
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface.withAlpha(180),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildMtcParamResult(
                      'Rt0.5 Yield',
                      '${mtc.yieldStrengthMpa.toStringAsFixed(1)} MPa',
                      '> 485 MPa',
                      mtc.passesYield,
                    ),
                    _buildMtcParamResult(
                      'Rm Tensile',
                      '${mtc.tensileStrengthMpa.toStringAsFixed(1)} MPa',
                      '> 570 MPa',
                      mtc.passesTensile,
                    ),
                    _buildMtcParamResult(
                      'CE_Pcm',
                      '${mtc.carbonEquivalentPcm.toStringAsFixed(3)}%',
                      '< 0.20%',
                      mtc.passesCarbonEquivalent,
                    ),
                  ],
                ),
                const Divider(color: AppTheme.border, height: 16),
                Row(
                  children: [
                    _buildMtcParamResult(
                      'Charpy (-20°C)',
                      '${mtc.charpyImpactJoulesMinus20.toStringAsFixed(0)} J',
                      '≥ 120 J',
                      mtc.passesCharpy,
                    ),
                    _buildMtcParamResult(
                      'Yield / Tensile',
                      mtc.yieldTensileRatio.toStringAsFixed(3),
                      '≤ 0.90',
                      mtc.passesYTRatio,
                    ),
                    _buildMtcParamResult(
                      'DWTT Shear',
                      '${mtc.dwttShearAreaPercent.toStringAsFixed(0)}%',
                      '≥ 85%',
                      mtc.passesDwtt,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Chemical Composition Table (Ladle Analysis)
          const Text(
            'LADLE CHEMICAL ANALYSIS (wt %):',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: mtc.chemistry.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Certificate SHA-256 Hash
          Row(
            children: [
              const Icon(Icons.fingerprint_rounded, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'SHA-256: ${mtc.sha256Hash}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMtcParamResult(String label, String value, String limit, bool passed) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: passed ? AppTheme.textPrimary : AppTheme.error,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Limit: $limit',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: QR / BARCODE SCANNING, CHAINAGE & PUP TRACKING
  // ============================================================================

  Widget _buildScanningAndPupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR / Barcode Laser Scanning Trigger Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withAlpha(40),
                  AppTheme.surfaceCard,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryLight.withAlpha(100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Scan Pipe QR Tag / Stencil Barcode',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Stringing chainage allocation, bevel QA & 3LPE coating DFT logging',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text(
                      'Launch Optical Tag Scanner',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _showQrScanningSimulationDialog,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Cut-Pipe / Pup Piece Management Section
          Row(
            children: [
              const Text(
                'CUT-PIPE / PUP PIECE TRACKER',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA78BFA).withAlpha(30),
                  foregroundColor: const Color(0xFFA78BFA),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFA78BFA)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.content_cut_rounded, size: 14),
                label: const Text('New Cut Pup', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: _showCutPupDialog,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'API 5L / OISD-141: All cut-pipe pup pieces must maintain parent heat traceability & stencil transfer.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
          ),
          const SizedBox(height: 12),

          ..._pupPieces.map((pup) => _buildPupPieceCard(pup)),
        ],
      ),
    );
  }

  Widget _buildPupPieceCard(PupPieceRecord pup) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA78BFA).withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFA78BFA).withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pup.pupId,
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Parent: ${pup.parentPipeId}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified_rounded, size: 11, color: AppTheme.tertiary),
                    SizedBox(width: 3),
                    Text(
                      'STENCIL TRANSFERRED',
                      style: TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pup.intendedApplication,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface.withAlpha(160),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildSpecItem('HEAT NO', pup.heatNumber, isHighlighted: true),
                _buildSpecItem('PUP LENGTH', '${pup.cutLengthM.toStringAsFixed(2)} m'),
                _buildSpecItem('REMAINING PARENT', '${pup.remainingParentLengthM.toStringAsFixed(2)} m'),
                _buildSpecItem('WT', '${pup.wallThicknessMm} mm'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Cut on ${DateFormat('dd-MMM-yyyy').format(pup.cutDate)} by ${pup.certifiedBy}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: YARD STOCK RECONCILIATION
  // ============================================================================

  Widget _buildYardReconciliationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'PIPE DUMP YARD RECONCILIATION',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary.withAlpha(40),
                  foregroundColor: AppTheme.primaryLight,
                  elevation: 0,
                  side: const BorderSide(color: AppTheme.primaryLight),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.local_shipping_rounded, size: 14),
                label: const Text('Inter-Yard Transfer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: _showInterYardTransferDialog,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tripartite reconciliation of steel pipe inventory between Oil India, EPC Contractor & TPIA.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 14),

          ..._yardSummaries.map((summary) => _buildYardSummaryCard(summary)),

          const SizedBox(height: 20),

          // Total Reconciliation Matrix
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
                  children: const [
                    Icon(Icons.inventory_rounded, color: AppTheme.primaryLight, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Corridor Steel Stock Summary',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryLine('Total Pipes Rake Inbound', '1,420 pipes (17,040 m)'),
                _buildSummaryLine('Dispatched to RoW & Strung', '1,185 pipes (14,220 m)'),
                _buildSummaryLine('Current Balance at Yards', '231 pipes (2,772 m)'),
                _buildSummaryLine('Quarantined / Defective on Receipt', '4 pipes (48 m)'),
                const Divider(color: AppTheme.border, height: 20),
                Row(
                  children: const [
                    Text(
                      'RECONCILIATION VARIANCE:',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '0 PIPES (100% RECONCILED)',
                      style: TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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

  Widget _buildYardSummaryCard(YardStockSummary summary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: summary.yard.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.yard.displayName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      summary.yard.subtitle,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AUDITED: ${summary.lastAuditDate}',
                  style: const TextStyle(
                    color: AppTheme.tertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface.withAlpha(160),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildSpecItem('IN YARD', '${summary.currentInYard}', isHighlighted: true),
                _buildSpecItem('STRUNG ROW', '${summary.strungToRow}'),
                _buildSpecItem('9.5mm ML', '${summary.mainline95Count}'),
                _buildSpecItem('12.7mm HW', '${summary.heavyWall127Count}'),
                _buildSpecItem('QUARANTINE', '${summary.quarantinedCount}',
                    customColor: summary.quarantinedCount > 0 ? const Color(0xFFFF5252) : null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11.5,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // DIALOGS & ACTIONS
  // ============================================================================

  void _showPipeDetailsModal(PipeRecord pipe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pipe.uniqueId,
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: pipe.status.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pipe.status.label,
                          style: TextStyle(
                            color: pipe.status.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Metallurgy & Heat origin
                  const Text(
                    'METALLURGICAL TRACEABILITY',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryLine('Manufacturer Mill', pipe.mill.fullName),
                        _buildSummaryLine('Heat Number', pipe.heatNumber),
                        _buildSummaryLine('Coil Number', pipe.coilNumber),
                        _buildSummaryLine('MTC Standard', pipe.mtc.standard),
                        _buildSummaryLine('Inspection Certificate', pipe.mtc.en10204Type),
                        _buildSummaryLine('TPIA Witness Agency', pipe.mtc.tpiaAgency),
                        _buildSummaryLine('Yield Strength (Rt0.5)', '${pipe.mtc.yieldStrengthMpa} MPa (Min 485)'),
                        _buildSummaryLine('Tensile Strength (Rm)', '${pipe.mtc.tensileStrengthMpa} MPa (Min 570)'),
                        _buildSummaryLine('Carbon Equivalent (CE_Pcm)', '${pipe.mtc.carbonEquivalentPcm}% (Max 0.20%)'),
                        _buildSummaryLine('Charpy V-Notch (-20°C)', '${pipe.mtc.charpyImpactJoulesMinus20} J (Min 120 J)'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Field Inspection Record
                  const Text(
                    'FIELD INSPECTION & STRINGING QA',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (pipe.inspection != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryLine('Chainage Allocation', pipe.inspection!.chainage),
                          _buildSummaryLine('RoW Side', pipe.inspection!.rowSide),
                          _buildSummaryLine('Ground Elevation', '${pipe.inspection!.elevationMeters} m MSL'),
                          _buildSummaryLine('Bevel Root Face', '${pipe.inspection!.bevelRootFaceMm} mm (Nominal 1.6mm)'),
                          _buildSummaryLine('Bevel Angle', '${pipe.inspection!.bevelAngleDeg}° (Nominal 30°)'),
                          _buildSummaryLine('Laminations / Dents', pipe.inspection!.bevelLaminationFree ? 'NIL (PASSED)' : 'DEFECTS FOUND'),
                          _buildSummaryLine('3LPE Coating DFT', '${pipe.inspection!.coatingDftMicrons.toInt()} µm (Min 2500 µm)'),
                          _buildSummaryLine('Holiday Spark Test (25 kV)', pipe.inspection!.holidayPassed ? 'PASSED (0 SPARK)' : 'FAILED'),
                          _buildSummaryLine('QA Inspector', pipe.inspection!.inspectorName),
                          _buildSummaryLine('TPIA Witness', pipe.inspection!.tpiaWitness),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppTheme.secondary, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Pipe has not yet undergone stringing / bevel inspection. Launch optical scan to record field QA.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: AppTheme.textPrimary,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showFieldInspectionDialog(pipe);
                            },
                            child: const Text('Inspect'),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryLight,
                            side: const BorderSide(color: AppTheme.primaryLight),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.qr_code_rounded, size: 16),
                          label: const Text('Show QR Tag'),
                          onPressed: () {
                            Navigator.pop(context);
                            _showQrTagDisplayDialog(pipe);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA78BFA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.content_cut_rounded, size: 16),
                          label: const Text('Cut to Pup Piece'),
                          onPressed: () {
                            Navigator.pop(context);
                            _showCutPupDialogForPipe(pipe);
                          },
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

  void _showAddPipeDialog() {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController(text: 'OIL-24-X70-${1010 + _pipes.length}');
    final heatController = TextEditingController(text: 'H-89412');
    final coilController = TextEditingController(text: 'CL-5501A');
    final lengthController = TextEditingController(text: '12.18');
    PipeMill selectedMill = PipeMill.jindalSaw;
    WallThicknessType selectedThickness = WallThicknessType.mainline95;
    DumpYardLocation selectedYard = DumpYardLocation.duliajan;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double lengthVal = double.tryParse(lengthController.text) ?? 12.18;
            double calculatedWeight = PipeRecord.calculateApi5lWeight(
              610.0,
              selectedThickness.thicknessMm,
              lengthVal,
            );

            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: const Text(
                'Register Pipe in Electronic Tally',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pipe Unique ID (OIL-24-X70-XXXX):',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: idController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: _dialogInputDecoration('OIL-24-X70-XXXX'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Heat Number:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: heatController,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                  decoration: _dialogInputDecoration('H-XXXXX'),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Coil Number:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: coilController,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                  decoration: _dialogInputDecoration('CL-XXXX'),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Manufacturer Steel Mill:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<PipeMill>(
                        initialValue: selectedMill,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: _dialogInputDecoration('Select Mill'),
                        items: PipeMill.values.map((mill) {
                          return DropdownMenuItem(
                            value: mill,
                            child: Text(mill.fullName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedMill = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text('Wall Thickness Class:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<WallThicknessType>(
                        initialValue: selectedThickness,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: _dialogInputDecoration('Select Thickness'),
                        items: WallThicknessType.values.map((th) {
                          return DropdownMenuItem(
                            value: th,
                            child: Text(th.label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedThickness = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Length (m):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: lengthController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                  decoration: _dialogInputDecoration('12.18'),
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Weight (API 5L):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Text(
                                    '${calculatedWeight.toStringAsFixed(1)} kg',
                                    style: const TextStyle(
                                      color: AppTheme.primaryLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Dump Yard Depot:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<DumpYardLocation>(
                        initialValue: selectedYard,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: _dialogInputDecoration('Select Yard'),
                        items: [
                          DumpYardLocation.duliajan,
                          DumpYardLocation.moran,
                          DumpYardLocation.numaligarh,
                        ].map((yd) {
                          return DropdownMenuItem(
                            value: yd,
                            child: Text(yd.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedYard = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final newPipe = PipeRecord(
                        uniqueId: idController.text.trim(),
                        heatNumber: heatController.text.trim(),
                        coilNumber: coilController.text.trim(),
                        mill: selectedMill,
                        wallThickness: selectedThickness,
                        lengthM: double.tryParse(lengthController.text) ?? 12.18,
                        weightKg: calculatedWeight,
                        status: PipeStatus.inYard,
                        yardLocation: selectedYard,
                        mtc: _pipes.first.mtc,
                      );
                      setState(() {
                        _pipes.insert(0, newPipe);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.tertiary,
                          content: Text(
                            'Pipe ${newPipe.uniqueId} registered successfully in Tally Book!',
                            style: const TextStyle(color: Color(0xFF0B1326), fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Save Pipe'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQrScanningSimulationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: const [
              Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Live Barcode & QR Scanner',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryLight, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.white24),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.tertiary, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      child: Container(
                        height: 2,
                        width: 140,
                        color: AppTheme.tertiary,
                      ),
                    ),
                    const Positioned(
                      bottom: 12,
                      child: Text(
                        'Align Pipe Stencil / 3LPE QR Tag',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Simulate scanning detected pipe tag:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _pipes.take(3).map((pipe) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        backgroundColor: AppTheme.surface,
                        label: Text(
                          pipe.uniqueId,
                          style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showFieldInspectionDialog(pipe);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        );
      },
    );
  }

  void _showFieldInspectionDialog(PipeRecord pipe) {
    final chainageController = TextEditingController(text: pipe.chainageAllocated ?? 'Ch 14+300.00');
    final bevelRootController = TextEditingController(text: '1.6');
    final bevelAngleController = TextEditingController(text: '30.0');
    final dftController = TextEditingController(text: '2750');
    final inspectorController = TextEditingController(text: 'B. K. Gogoi (QA Lead)');
    final tpiaController = TextEditingController(text: 'R. K. Sharma (EIL Inspector)');
    String selectedSide = 'Left of RoW';
    bool laminationFree = true;
    bool holidayPassed = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Text(
                'Field QA Inspection: ${pipe.uniqueId}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stringing Chainage Location:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: chainageController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: _dialogInputDecoration('e.g. Ch 14+300.00'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bevel Root Face (mm):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: bevelRootController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                decoration: _dialogInputDecoration('1.6 mm ± 0.8'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bevel Angle (°):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: bevelAngleController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                decoration: _dialogInputDecoration('30° (+5°/-0°)'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Coating DFT (µm):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: dftController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                decoration: _dialogInputDecoration('Min 2500 µm'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('RoW Side:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: selectedSide,
                                dropdownColor: AppTheme.surfaceCard,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                decoration: _dialogInputDecoration('Side'),
                                items: ['Left of RoW', 'Right of RoW'].map((s) {
                                  return DropdownMenuItem(value: s, child: Text(s));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => selectedSide = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bevel Free from Laminations / Dents', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11.5)),
                      value: laminationFree,
                      activeColor: AppTheme.tertiary,
                      onChanged: (val) => setDialogState(() => laminationFree = val ?? true),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('25 kV Holiday Spark Test (Zero Pinholes)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11.5)),
                      value: holidayPassed,
                      activeColor: AppTheme.tertiary,
                      onChanged: (val) => setDialogState(() => holidayPassed = val ?? true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tertiary,
                    foregroundColor: const Color(0xFF0B1326),
                  ),
                  onPressed: () {
                    final record = FieldInspectionRecord(
                      inspectedAt: DateTime.now(),
                      inspectorName: inspectorController.text.trim(),
                      tpiaWitness: tpiaController.text.trim(),
                      chainage: chainageController.text.trim(),
                      rowSide: selectedSide,
                      elevationMeters: 119.2,
                      bevelRootFaceMm: double.tryParse(bevelRootController.text) ?? 1.6,
                      bevelAngleDeg: double.tryParse(bevelAngleController.text) ?? 30.0,
                      bevelLaminationFree: laminationFree,
                      coatingDftMicrons: double.tryParse(dftController.text) ?? 2750.0,
                      holidayVoltageKv: 25.0,
                      holidayPassed: holidayPassed,
                    );

                    setState(() {
                      pipe.inspection = record;
                      pipe.chainageAllocated = chainageController.text.trim();
                      pipe.status = PipeStatus.strung;
                      pipe.yardLocation = DumpYardLocation.rowCorridor;
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.tertiary,
                        content: Text(
                          'Field QA logged & allocated to ${chainageController.text.trim()}!',
                          style: const TextStyle(color: Color(0xFF0B1326), fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  child: const Text('Certify & Save QA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCutPupDialog() {
    _showCutPupDialogForPipe(_pipes.first);
  }

  void _showCutPupDialogForPipe(PipeRecord pipe) {
    final cutLengthController = TextEditingController(text: '4.20');
    final purposeController = TextEditingController(text: 'Valve Station Tie-In Spool (VS-04)');
    final inspectorController = TextEditingController(text: 'A. Saikia (QC Inspector)');
    bool stencilTransferred = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double cutM = double.tryParse(cutLengthController.text) ?? 4.20;
            double remainingM = (pipe.lengthM - cutM - 0.005).clamp(0.0, pipe.lengthM); // 5mm kerf allowance

            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Text(
                'Cut Pipe & Create Pup Piece: ${pipe.uniqueId}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _buildSpecItem('PARENT LENGTH', '${pipe.lengthM.toStringAsFixed(2)} m'),
                          _buildSpecItem('HEAT NO', pipe.heatNumber, isHighlighted: true),
                          _buildSpecItem('MILL', pipe.mill.shortCode),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Cut Length Required (m):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: cutLengthController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: _dialogInputDecoration('e.g. 4.20 m'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA78BFA).withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Child Pup: ${cutM.toStringAsFixed(2)} m  |  Parent Remaining: ${remainingM.toStringAsFixed(2)} m',
                        style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Intended Pup Application:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: purposeController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: _dialogInputDecoration('e.g. HDD Tie-in, River crossing spool'),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Heat & Coil Stencil Transferred & Hard-Stamped (Low-Stress Dot Stamp)',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                      ),
                      value: stencilTransferred,
                      activeColor: AppTheme.tertiary,
                      onChanged: (val) => setDialogState(() => stencilTransferred = val ?? true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA78BFA),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final childPupId = '${pipe.uniqueId}-P1';
                    final newPup = PupPieceRecord(
                      pupId: childPupId,
                      parentPipeId: pipe.uniqueId,
                      heatNumber: pipe.heatNumber,
                      mill: pipe.mill,
                      cutLengthM: cutM,
                      remainingParentLengthM: remainingM,
                      wallThicknessMm: pipe.wallThickness.thicknessMm,
                      intendedApplication: purposeController.text.trim(),
                      stencilHardStamped: stencilTransferred,
                      cutDate: DateTime.now(),
                      certifiedBy: inspectorController.text.trim(),
                    );

                    setState(() {
                      _pupPieces.insert(0, newPup);
                      pipe.lengthM = remainingM;
                      pipe.status = PipeStatus.pupCut;
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFFA78BFA),
                        content: Text(
                          'Pup piece $childPupId created with stencil traceability verified!',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  child: const Text('Generate Pup Piece'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQrTagDisplayDialog(PipeRecord pipe) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Text(
            'Digital Pipe QR Identifier: ${pipe.uniqueId}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 160, color: Colors.black87),
                    const SizedBox(height: 6),
                    Text(
                      pipe.uniqueId,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'HEAT: ${pipe.heatNumber} • COIL: ${pipe.coilNumber}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${pipe.mill.fullName} • ${pipe.wallThickness.label}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        );
      },
    );
  }

  void _showInterYardTransferDialog() {
    DumpYardLocation fromYard = DumpYardLocation.duliajan;
    DumpYardLocation toYard = DumpYardLocation.moran;
    final truckController = TextEditingController(text: 'AS-06-BC-4190');
    final driverController = TextEditingController(text: 'Debojit Phukan');
    final eWayController = TextEditingController(text: 'EWB-2026-9814-7721');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: const Text(
                'Inter-Yard Pipe Stock Transfer',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Source Dump Yard:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<DumpYardLocation>(
                      initialValue: fromYard,
                      dropdownColor: AppTheme.surfaceCard,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: _dialogInputDecoration('From Yard'),
                      items: [
                        DumpYardLocation.duliajan,
                        DumpYardLocation.moran,
                        DumpYardLocation.numaligarh,
                      ].map((y) => DropdownMenuItem(value: y, child: Text(y.displayName))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => fromYard = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text('Destination Dump Yard:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<DumpYardLocation>(
                      initialValue: toYard,
                      dropdownColor: AppTheme.surfaceCard,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: _dialogInputDecoration('To Yard'),
                      items: [
                        DumpYardLocation.duliajan,
                        DumpYardLocation.moran,
                        DumpYardLocation.numaligarh,
                      ].map((y) => DropdownMenuItem(value: y, child: Text(y.displayName))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => toYard = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text('Trailer Truck Number:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: truckController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: _dialogInputDecoration('e.g. AS-06-BC-4190'),
                    ),
                    const SizedBox(height: 10),
                    const Text('Driver & Mobile:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: driverController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: _dialogInputDecoration('Driver Name'),
                    ),
                    const SizedBox(height: 10),
                    const Text('GST E-Way Bill Number:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: eWayController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: _dialogInputDecoration('EWB Number'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.tertiary,
                        content: Text(
                          'Transfer dispatch generated from ${fromYard.displayName} to ${toYard.displayName}!',
                          style: const TextStyle(color: Color(0xFF0B1326), fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  child: const Text('Generate Dispatch Pass'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _dialogInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
      isDense: true,
      filled: true,
      fillColor: AppTheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_rounded, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
