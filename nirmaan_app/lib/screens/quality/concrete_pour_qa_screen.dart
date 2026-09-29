import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS
// ============================================================================

enum PourCardStatus {
  activeCuring,
  sevenDayPassed,
  twentyEightDayPassed,
  closedCertified,
}

class MixDesignSpec {
  final String grade; // M25, M35, M40
  final double characteristicStrengthMpa; // fck (25, 35, 40)
  final double target7DayStrengthMpa; // >= 70% of fck
  final double target28DayStrengthMpa; // >= 100% of fck
  final int designSlumpMm; // 100
  final int slumpToleranceMm; // 25
  final double waterCementRatio; // 0.42
  final double cementContentKgM3;
  final double flyAshMicroSilicaKgM3;
  final double fineAggregateKgM3;
  final double coarse10mmKgM3;
  final double coarse20mmKgM3;
  final double waterLitresM3;
  final String superplasticizerBrand;
  final double superplasticizerDosagePercent; // by weight of cement
  final String mixDesignCertRef;
  final String standardCode;
  final String applicationSummary;

  const MixDesignSpec({
    required this.grade,
    required this.characteristicStrengthMpa,
    required this.target7DayStrengthMpa,
    required this.target28DayStrengthMpa,
    required this.designSlumpMm,
    required this.slumpToleranceMm,
    required this.waterCementRatio,
    required this.cementContentKgM3,
    required this.flyAshMicroSilicaKgM3,
    required this.fineAggregateKgM3,
    required this.coarse10mmKgM3,
    required this.coarse20mmKgM3,
    required this.waterLitresM3,
    required this.superplasticizerBrand,
    required this.superplasticizerDosagePercent,
    required this.mixDesignCertRef,
    required this.standardCode,
    required this.applicationSummary,
  });

  String get slumpRangeDisplay => '$designSlumpMm ± ${slumpToleranceMm}mm (${designSlumpMm - slumpToleranceMm}-${designSlumpMm + slumpToleranceMm}mm)';
}

class PrePourCheckItem {
  final String id;
  final String title;
  final String specification;
  final bool isCleared;
  final String clearedBy;
  final String clearedTimestamp;

  const PrePourCheckItem({
    required this.id,
    required this.title,
    required this.specification,
    required this.isCleared,
    required this.clearedBy,
    required this.clearedTimestamp,
  });

  PrePourCheckItem copyWith({
    String? id,
    String? title,
    String? specification,
    bool? isCleared,
    String? clearedBy,
    String? clearedTimestamp,
  }) {
    return PrePourCheckItem(
      id: id ?? this.id,
      title: title ?? this.title,
      specification: specification ?? this.specification,
      isCleared: isCleared ?? this.isCleared,
      clearedBy: clearedBy ?? this.clearedBy,
      clearedTimestamp: clearedTimestamp ?? this.clearedTimestamp,
    );
  }
}

class CubeBreakRecord {
  final String sampleId;
  final String pourCardId;
  final String structureName;
  final String mixGrade;
  final DateTime castDate;
  final DateTime testDate;
  final int ageDays; // 7 or 28
  final double targetStrengthMpa;
  final double measuredStrengthMpa;
  final double failureLoadKn;
  final double densityKgM3;
  final String failurePattern; // Pyramidal, Shear, Non-standard
  final String curingTankRef;
  final String ctmMachineId;
  final String labTechnician;
  final String tpiaWitness;
  final String labCertNumber;

  const CubeBreakRecord({
    required this.sampleId,
    required this.pourCardId,
    required this.structureName,
    required this.mixGrade,
    required this.castDate,
    required this.testDate,
    required this.ageDays,
    required this.targetStrengthMpa,
    required this.measuredStrengthMpa,
    required this.failureLoadKn,
    required this.densityKgM3,
    required this.failurePattern,
    required this.curingTankRef,
    required this.ctmMachineId,
    required this.labTechnician,
    required this.tpiaWitness,
    required this.labCertNumber,
  });

  bool get isPass => measuredStrengthMpa >= targetStrengthMpa;

  double get characteristicFck {
    if (mixGrade.contains('25')) return 25.0;
    if (mixGrade.contains('35')) return 35.0;
    if (mixGrade.contains('40')) return 40.0;
    return 30.0;
  }

  double get percentageOfFck => (measuredStrengthMpa / characteristicFck) * 100.0;
}

class BatchingPlantTicket {
  final String ticketNumber;
  final String pourCardId;
  final String batchTime;
  final String dispatchTime;
  final String siteArrivalTime;
  final String dischargeStartTime;
  final String dischargeEndTime;
  final String mixerTruckNumber;
  final String driverName;
  final String batchingPlantName;
  final String cementBatchCert;
  final String superplasticizerDosage;
  final double batchVolumeM3;
  final double cumulativeVolumeM3;
  final int slumpAtDischargeMm;
  final double concreteTempCelsius;
  final double ambientTempCelsius;
  final bool isQcAccepted;
  final String qcInspectorSign;

  const BatchingPlantTicket({
    required this.ticketNumber,
    required this.pourCardId,
    required this.batchTime,
    required this.dispatchTime,
    required this.siteArrivalTime,
    required this.dischargeStartTime,
    required this.dischargeEndTime,
    required this.mixerTruckNumber,
    required this.driverName,
    required this.batchingPlantName,
    required this.cementBatchCert,
    required this.superplasticizerDosage,
    required this.batchVolumeM3,
    required this.cumulativeVolumeM3,
    required this.slumpAtDischargeMm,
    required this.concreteTempCelsius,
    required this.ambientTempCelsius,
    required this.isQcAccepted,
    required this.qcInspectorSign,
  });
}

class PourCardModel {
  final String id;
  final String structureName; // Compressor Foundation, Pump Pad B, Flare Stack Pedestal, Substation Raft
  final String locationCode;
  final String workPackage;
  final String activityCode;
  final String mixGrade; // M25, M35, M40
  final double targetVolumeM3;
  final double pouredVolumeM3;
  final DateTime pourDate;
  final String pourTimeWindow;
  final PourCardStatus status;
  final double waterCementRatio; // 0.42
  final int designSlumpMm; // 100
  final int slumpToleranceMm; // 25
  final String curingMethod;
  final int curingDaysCompleted;
  final String leadQcEngineer;
  final String tpiaWitnessLead;
  final List<PrePourCheckItem> prePourChecklist;
  final List<BatchingPlantTicket> tickets;
  final List<CubeBreakRecord> cubeRecords;
  final String technicalNotes;

  const PourCardModel({
    required this.id,
    required this.structureName,
    required this.locationCode,
    required this.workPackage,
    required this.activityCode,
    required this.mixGrade,
    required this.targetVolumeM3,
    required this.pouredVolumeM3,
    required this.pourDate,
    required this.pourTimeWindow,
    required this.status,
    required this.waterCementRatio,
    required this.designSlumpMm,
    required this.slumpToleranceMm,
    required this.curingMethod,
    required this.curingDaysCompleted,
    required this.leadQcEngineer,
    required this.tpiaWitnessLead,
    required this.prePourChecklist,
    required this.tickets,
    required this.cubeRecords,
    required this.technicalNotes,
  });

  PourCardModel copyWith({
    String? id,
    String? structureName,
    String? locationCode,
    String? workPackage,
    String? activityCode,
    String? mixGrade,
    double? targetVolumeM3,
    double? pouredVolumeM3,
    DateTime? pourDate,
    String? pourTimeWindow,
    PourCardStatus? status,
    double? waterCementRatio,
    int? designSlumpMm,
    int? slumpToleranceMm,
    String? curingMethod,
    int? curingDaysCompleted,
    String? leadQcEngineer,
    String? tpiaWitnessLead,
    List<PrePourCheckItem>? prePourChecklist,
    List<BatchingPlantTicket>? tickets,
    List<CubeBreakRecord>? cubeRecords,
    String? technicalNotes,
  }) {
    return PourCardModel(
      id: id ?? this.id,
      structureName: structureName ?? this.structureName,
      locationCode: locationCode ?? this.locationCode,
      workPackage: workPackage ?? this.workPackage,
      activityCode: activityCode ?? this.activityCode,
      mixGrade: mixGrade ?? this.mixGrade,
      targetVolumeM3: targetVolumeM3 ?? this.targetVolumeM3,
      pouredVolumeM3: pouredVolumeM3 ?? this.pouredVolumeM3,
      pourDate: pourDate ?? this.pourDate,
      pourTimeWindow: pourTimeWindow ?? this.pourTimeWindow,
      status: status ?? this.status,
      waterCementRatio: waterCementRatio ?? this.waterCementRatio,
      designSlumpMm: designSlumpMm ?? this.designSlumpMm,
      slumpToleranceMm: slumpToleranceMm ?? this.slumpToleranceMm,
      curingMethod: curingMethod ?? this.curingMethod,
      curingDaysCompleted: curingDaysCompleted ?? this.curingDaysCompleted,
      leadQcEngineer: leadQcEngineer ?? this.leadQcEngineer,
      tpiaWitnessLead: tpiaWitnessLead ?? this.tpiaWitnessLead,
      prePourChecklist: prePourChecklist ?? this.prePourChecklist,
      tickets: tickets ?? this.tickets,
      cubeRecords: cubeRecords ?? this.cubeRecords,
      technicalNotes: technicalNotes ?? this.technicalNotes,
    );
  }

  double get volumeProgress => (pouredVolumeM3 / targetVolumeM3).clamp(0.0, 1.0);
}

// ============================================================================
// MAIN SCREEN IMPLEMENTATION
// ============================================================================

class ConcretePourQaScreen extends StatefulWidget {
  const ConcretePourQaScreen({super.key});

  @override
  State<ConcretePourQaScreen> createState() => _ConcretePourQaScreenState();
}

class _ConcretePourQaScreenState extends State<ConcretePourQaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _searchFilter = '';
  String _selectedGradeFilter = 'ALL'; // ALL, M25, M35, M40
  String _selectedStatusFilter = 'ALL'; // ALL, ACTIVE, 7D_DONE, 28D_DONE

  // Master Data: Standard Mix Design Specs for M25, M35, M40
  static const Map<String, MixDesignSpec> _mixSpecifications = {
    'M25': MixDesignSpec(
      grade: 'M25',
      characteristicStrengthMpa: 25.0,
      target7DayStrengthMpa: 17.5, // 70% of 25 MPa
      target28DayStrengthMpa: 25.0, // 100% of 25 MPa
      designSlumpMm: 100,
      slumpToleranceMm: 25,
      waterCementRatio: 0.42,
      cementContentKgM3: 360.0,
      flyAshMicroSilicaKgM3: 65.0, // Pozzolanic cementitious
      fineAggregateKgM3: 685.0,
      coarse10mmKgM3: 450.0,
      coarse20mmKgM3: 710.0,
      waterLitresM3: 151.2, // 360 * 0.42
      superplasticizerBrand: 'Fosroc Auramix 400',
      superplasticizerDosagePercent: 0.80,
      mixDesignCertRef: 'OIL-DUL-QA-M25-REV4',
      standardCode: 'IS 456:2000 & IS 10262:2019',
      applicationSummary: 'Substation Raft Footings, Cable Trenches & Ground Slabs',
    ),
    'M35': MixDesignSpec(
      grade: 'M35',
      characteristicStrengthMpa: 35.0,
      target7DayStrengthMpa: 24.5, // 70% of 35 MPa
      target28DayStrengthMpa: 35.0, // 100% of 35 MPa
      designSlumpMm: 100,
      slumpToleranceMm: 25,
      waterCementRatio: 0.42,
      cementContentKgM3: 420.0,
      flyAshMicroSilicaKgM3: 50.0,
      fineAggregateKgM3: 640.0,
      coarse10mmKgM3: 480.0,
      coarse20mmKgM3: 720.0,
      waterLitresM3: 176.4, // 420 * 0.42
      superplasticizerBrand: 'Sika Plastiment BV-40',
      superplasticizerDosagePercent: 0.85,
      mixDesignCertRef: 'OIL-DUL-QA-M35-REV5',
      standardCode: 'IS 456:2000, IS 10262 & API 618',
      applicationSummary: 'Compressor Skid Base, Heavy Vibration Foundations & Pipe Racks',
    ),
    'M40': MixDesignSpec(
      grade: 'M40',
      characteristicStrengthMpa: 40.0,
      target7DayStrengthMpa: 28.0, // 70% of 40 MPa
      target28DayStrengthMpa: 40.0, // 100% of 40 MPa
      designSlumpMm: 100,
      slumpToleranceMm: 25,
      waterCementRatio: 0.42,
      cementContentKgM3: 460.0,
      flyAshMicroSilicaKgM3: 45.0,
      fineAggregateKgM3: 610.0,
      coarse10mmKgM3: 510.0,
      coarse20mmKgM3: 740.0,
      waterLitresM3: 193.2, // 460 * 0.42
      superplasticizerBrand: 'BASF MasterRheobuild 1100',
      superplasticizerDosagePercent: 0.90,
      mixDesignCertRef: 'OIL-DUL-QA-M40-HIGH-SPEC',
      standardCode: 'IS 456:2000, IS 1343 & ASME B31.4',
      applicationSummary: 'High-Torque Pump Pad B, Flare Stack Pedestal & Critical Plinths',
    ),
  };

  // State: Pour Cards Register for the 4 key structures
  late List<PourCardModel> _pourCards;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final now = DateTime.now();
    final d22 = now.subtract(const Duration(days: 8)); // 8 days ago
    final d02 = now.subtract(const Duration(days: 29)); // 29 days ago
    final d27 = now.subtract(const Duration(days: 3)); // 3 days ago
    final d15 = now.subtract(const Duration(days: 15)); // 15 days ago

    _pourCards = [
      // 1. Compressor Foundation
      PourCardModel(
        id: 'PC-2026-CF-01',
        structureName: 'Compressor Foundation',
        locationCode: 'Area A · Station 03 - Gas Compressor Plinth Skid',
        workPackage: 'WP-04 Civil & Heavy Equipment Foundations',
        activityCode: 'ACT-CIV-301',
        mixGrade: 'M35',
        targetVolumeM3: 84.5,
        pouredVolumeM3: 84.5,
        pourDate: d22,
        pourTimeWindow: '06:30 AM - 14:15 PM',
        status: PourCardStatus.sevenDayPassed,
        waterCementRatio: 0.42,
        designSlumpMm: 100,
        slumpToleranceMm: 25,
        curingMethod: 'Wet Hessian Burlap Curing + Continuous Mist Ponding',
        curingDaysCompleted: 8,
        leadQcEngineer: 'R. K. Sharma (QA/QC Lead)',
        tpiaWitnessLead: 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
        technicalNotes:
            'Continuous monolithic pour for reciprocating gas compressor. Thermocouples embedded at centroid and surface. Core temp differential maintained under 19°C. 7-day cube break cleared successfully.',
        prePourChecklist: const [
          PrePourCheckItem(
            id: 'CHK-CF-01',
            title: 'Formwork & Shuttering Stability',
            specification: 'Film-faced plywood, bracing withstands 24 kN/m² hydrostatic head (IS 14687)',
            isCleared: true,
            clearedBy: 'R. K. Sharma',
            clearedTimestamp: '22-Sep-2026 05:45 AM',
          ),
          PrePourCheckItem(
            id: 'CHK-CF-02',
            title: 'Rebar Cage & 50mm Concrete Cover Blocks',
            specification: 'Fe500D rebar grid, cover 50mm on bottom & sides, tie wire ends bent inwards',
            isCleared: true,
            clearedBy: 'Ananya Sen',
            clearedTimestamp: '22-Sep-2026 06:00 AM',
          ),
          PrePourCheckItem(
            id: 'CHK-CF-03',
            title: 'Embedment Plates & Anchor Bolts Alignment',
            specification: 'Compressor anchor bolt sleeve tolerance within ±1.5mm per API 686',
            isCleared: true,
            clearedBy: 'Marcus Vance',
            clearedTimestamp: '22-Sep-2026 06:15 AM',
          ),
          PrePourCheckItem(
            id: 'CHK-CF-04',
            title: 'High Pressure Air & Vacuum Cleanliness',
            specification: 'Pour pocket completely free of wood shavings, tie wire cutoffs, and standing water',
            isCleared: true,
            clearedBy: 'Vikram Joshi',
            clearedTimestamp: '22-Sep-2026 06:20 AM',
          ),
          PrePourCheckItem(
            id: 'CHK-CF-05',
            title: 'TPIA & Consultant Hold-Point Clearance',
            specification: 'FIDIC Cl. 7.3 formal inspection sheet stamped before concrete batch dispatch',
            isCleared: true,
            clearedBy: 'Marcus Vance (TPIA)',
            clearedTimestamp: '22-Sep-2026 06:25 AM',
          ),
        ],
        tickets: const [
          BatchingPlantTicket(
            ticketNumber: 'RMC-TK-8834',
            pourCardId: 'PC-2026-CF-01',
            batchTime: '06:10 AM',
            dispatchTime: '06:25 AM',
            siteArrivalTime: '06:48 AM',
            dischargeStartTime: '06:55 AM',
            dischargeEndTime: '07:30 AM',
            mixerTruckNumber: 'AS-01-EC-4412',
            driverName: 'Biren Gogoi',
            batchingPlantName: 'OIL Central Batching Plant (Schwing Stetter 60m³/h)',
            cementBatchCert: 'Ultratech OPC 53 Grade - Cert #UT-2026-A48',
            superplasticizerDosage: 'Sika Plastiment BV-40 @ 0.85% (3.57 L/m³)',
            batchVolumeM3: 7.0,
            cumulativeVolumeM3: 7.0,
            slumpAtDischargeMm: 105,
            concreteTempCelsius: 27.2,
            ambientTempCelsius: 28.5,
            isQcAccepted: true,
            qcInspectorSign: 'R.K.S.',
          ),
          BatchingPlantTicket(
            ticketNumber: 'RMC-TK-8835',
            pourCardId: 'PC-2026-CF-01',
            batchTime: '06:45 AM',
            dispatchTime: '07:00 AM',
            siteArrivalTime: '07:22 AM',
            dischargeStartTime: '07:32 AM',
            dischargeEndTime: '08:08 AM',
            mixerTruckNumber: 'AS-01-EC-4415',
            driverName: 'Manas Pratim',
            batchingPlantName: 'OIL Central Batching Plant',
            cementBatchCert: 'Ultratech OPC 53 Grade - Cert #UT-2026-A48',
            superplasticizerDosage: 'Sika Plastiment BV-40 @ 0.85% (3.57 L/m³)',
            batchVolumeM3: 7.0,
            cumulativeVolumeM3: 14.0,
            slumpAtDischargeMm: 98,
            concreteTempCelsius: 27.6,
            ambientTempCelsius: 29.0,
            isQcAccepted: true,
            qcInspectorSign: 'R.K.S.',
          ),
          BatchingPlantTicket(
            ticketNumber: 'RMC-TK-8836',
            pourCardId: 'PC-2026-CF-01',
            batchTime: '07:20 AM',
            dispatchTime: '07:35 AM',
            siteArrivalTime: '08:00 AM',
            dischargeStartTime: '08:12 AM',
            dischargeEndTime: '08:50 AM',
            mixerTruckNumber: 'AS-23-BC-9108',
            driverName: 'Tarun Saikia',
            batchingPlantName: 'OIL Central Batching Plant',
            cementBatchCert: 'Ultratech OPC 53 Grade - Cert #UT-2026-A48',
            superplasticizerDosage: 'Sika Plastiment BV-40 @ 0.85% (3.57 L/m³)',
            batchVolumeM3: 7.0,
            cumulativeVolumeM3: 21.0,
            slumpAtDischargeMm: 102,
            concreteTempCelsius: 28.0,
            ambientTempCelsius: 29.8,
            isQcAccepted: true,
            qcInspectorSign: 'R.K.S.',
          ),
          BatchingPlantTicket(
            ticketNumber: 'RMC-TK-8848',
            pourCardId: 'PC-2026-CF-01',
            batchTime: '13:00 PM',
            dispatchTime: '13:15 PM',
            siteArrivalTime: '13:38 PM',
            dischargeStartTime: '13:45 PM',
            dischargeEndTime: '14:15 PM',
            mixerTruckNumber: 'AS-01-EC-4412',
            driverName: 'Biren Gogoi',
            batchingPlantName: 'OIL Central Batching Plant',
            cementBatchCert: 'Ultratech OPC 53 Grade - Cert #UT-2026-A48',
            superplasticizerDosage: 'Sika Plastiment BV-40 @ 0.85% (3.57 L/m³)',
            batchVolumeM3: 7.5,
            cumulativeVolumeM3: 84.5,
            slumpAtDischargeMm: 95,
            concreteTempCelsius: 29.1,
            ambientTempCelsius: 32.4,
            isQcAccepted: true,
            qcInspectorSign: 'R.K.S.',
          ),
        ],
        cubeRecords: [
          CubeBreakRecord(
            sampleId: 'CB-CF01-7D-01',
            pourCardId: 'PC-2026-CF-01',
            structureName: 'Compressor Foundation',
            mixGrade: 'M35',
            castDate: d22,
            testDate: d22.add(const Duration(days: 7)),
            ageDays: 7,
            targetStrengthMpa: 24.5, // 70% of 35
            measuredStrengthMpa: 27.4,
            failureLoadKn: 616.5,
            densityKgM3: 2445.0,
            failurePattern: 'True Pyramidal Shear',
            curingTankRef: 'Tank-01 (Curing Chamber, 27°C ± 2°C)',
            ctmMachineId: 'CTM-2000kN (Digital Pace Rate 0.25 MPa/s)',
            labTechnician: 'D. Kalita (QA Testing Chemist)',
            tpiaWitness: 'Marcus Vance (TPIA Consultant)',
            labCertNumber: 'LAB-IS516-2026-0929',
          ),
          CubeBreakRecord(
            sampleId: 'CB-CF01-7D-02',
            pourCardId: 'PC-2026-CF-01',
            structureName: 'Compressor Foundation',
            mixGrade: 'M35',
            castDate: d22,
            testDate: d22.add(const Duration(days: 7)),
            ageDays: 7,
            targetStrengthMpa: 24.5,
            measuredStrengthMpa: 28.1,
            failureLoadKn: 632.2,
            densityKgM3: 2450.0,
            failurePattern: 'True Pyramidal Shear',
            curingTankRef: 'Tank-01 (Curing Chamber, 27°C ± 2°C)',
            ctmMachineId: 'CTM-2000kN (Digital Pace Rate 0.25 MPa/s)',
            labTechnician: 'D. Kalita (QA Testing Chemist)',
            tpiaWitness: 'Marcus Vance (TPIA Consultant)',
            labCertNumber: 'LAB-IS516-2026-0929',
          ),
          CubeBreakRecord(
            sampleId: 'CB-CF01-7D-03',
            pourCardId: 'PC-2026-CF-01',
            structureName: 'Compressor Foundation',
            mixGrade: 'M35',
            castDate: d22,
            testDate: d22.add(const Duration(days: 7)),
            ageDays: 7,
            targetStrengthMpa: 24.5,
            measuredStrengthMpa: 27.8,
            failureLoadKn: 625.5,
            densityKgM3: 2448.0,
            failurePattern: 'True Pyramidal Shear',
            curingTankRef: 'Tank-01 (Curing Chamber, 27°C ± 2°C)',
            ctmMachineId: 'CTM-2000kN (Digital Pace Rate 0.25 MPa/s)',
            labTechnician: 'D. Kalita (QA Testing Chemist)',
            tpiaWitness: 'Marcus Vance (TPIA Consultant)',
            labCertNumber: 'LAB-IS516-2026-0929',
          ),
        ],
      ),

      // 2. Pump Pad B
      PourCardModel(
        id: 'PC-2026-PP-02',
        structureName: 'Pump Pad B',
        locationCode: 'Booster Pump Station 02 · Main Crude Transfer Unit B',
        workPackage: 'WP-05 Mechanical Pumping Machinery Bases',
        activityCode: 'ACT-CIV-302',
        mixGrade: 'M40',
        targetVolumeM3: 42.0,
        pouredVolumeM3: 42.0,
        pourDate: d02,
        pourTimeWindow: '07:00 AM - 12:30 PM',
        status: PourCardStatus.closedCertified,
        waterCementRatio: 0.42,
        designSlumpMm: 100,
        slumpToleranceMm: 25,
        curingMethod: 'Wet Burlap Wrapping for 14 Days + Epoxy Sealer Coat',
        curingDaysCompleted: 28,
        leadQcEngineer: 'R. K. Sharma (QA/QC Lead)',
        tpiaWitnessLead: 'Lloyd\'s Register / Sunil Khurana (OIL)',
        technicalNotes:
            'Critical centrifugal booster pump base. Heavy dynamic shear and cyclic loads. M40 design verified. Both 7-day (31.8 MPa) and 28-day (44.6 MPa) tests passed characteristic threshold. Full certificate archived under Cl. 7.3.',
        prePourChecklist: const [
          PrePourCheckItem(
            id: 'CHK-PP-01',
            title: 'Rigid Steel Shuttering & Chamfer Strips',
            specification: '25mm triangular chamfer on all exposed plinth edges, zero deflection under load',
            isCleared: true,
            clearedBy: 'R. K. Sharma',
            clearedTimestamp: '02-Sep-2026 06:10 AM',
          ),
          PrePourCheckItem(
            id: 'CHK-PP-02',
            title: 'High-Tensile Rebar Mat Fe500D (Upper & Lower Grid)',
            specification: 'Dual rebar grid spaced with heavy-duty rebar chairs, 50mm bottom cover',
            isCleared: true,
            clearedBy: 'Ananya Sen',
            clearedTimestamp: '02-Sep-2026 06:30 AM',
          ),
          PrePourCheckItem(
            id: 'CHK-PP-03',
            title: 'Vibration Isolation Sleeves & Baseplate Dowels',
            specification: 'Stainless steel 316 sleeves aligned with laser level to ±1.0mm',
            isCleared: true,
            clearedBy: 'Marcus Vance',
            clearedTimestamp: '02-Sep-2026 06:45 AM',
          ),
          PrePourCheckItem(
            id: 'CHK-PP-04',
            title: 'Subgrade Compaction & Moisture Barrier Polyethylene',
            specification: '98% Modified Proctor density achieved on sub-base; 250 micron PE sheet intact',
            isCleared: true,
            clearedBy: 'Vikram Joshi',
            clearedTimestamp: '02-Sep-2026 06:50 AM',
          ),
        ],
        tickets: const [
          BatchingPlantTicket(
            ticketNumber: 'RMC-TK-8610',
            pourCardId: 'PC-2026-PP-02',
            batchTime: '06:35 AM',
            dispatchTime: '06:50 AM',
            siteArrivalTime: '07:12 AM',
            dischargeStartTime: '07:20 AM',
            dischargeEndTime: '08:00 AM',
            mixerTruckNumber: 'AS-01-EC-4412',
            driverName: 'Biren Gogoi',
            batchingPlantName: 'OIL Central Batching Plant',
            cementBatchCert: 'Dalmia DSP Cement OPC 53 - Cert #DSP-88219',
            superplasticizerDosage: 'BASF MasterRheobuild 1100 @ 0.90% (4.14 L/m³)',
            batchVolumeM3: 7.0,
            cumulativeVolumeM3: 7.0,
            slumpAtDischargeMm: 100,
            concreteTempCelsius: 26.8,
            ambientTempCelsius: 27.5,
            isQcAccepted: true,
            qcInspectorSign: 'R.K.S.',
          ),
          BatchingPlantTicket(
            ticketNumber: 'RMC-TK-8611',
            pourCardId: 'PC-2026-PP-02',
            batchTime: '07:15 AM',
            dispatchTime: '07:30 AM',
            siteArrivalTime: '07:55 AM',
            dischargeStartTime: '08:05 AM',
            dischargeEndTime: '08:45 AM',
            mixerTruckNumber: 'AS-23-BC-9108',
            driverName: 'Tarun Saikia',
            batchingPlantName: 'OIL Central Batching Plant',
            cementBatchCert: 'Dalmia DSP Cement OPC 53 - Cert #DSP-88219',
            superplasticizerDosage: 'BASF MasterRheobuild 1100 @ 0.90% (4.14 L/m³)',
            batchVolumeM3: 7.0,
            cumulativeVolumeM3: 14.0,
            slumpAtDischargeMm: 95,
            concreteTempCelsius: 27.1,
            ambientTempCelsius: 28.0,
            isQcAccepted: true,
            qcInspectorSign: 'R.K.S.',
          ),
          BatchingPlantTicket(
            ticketNumber: 'RMC-TK-8616',
            pourCardId: 'PC-2026-PP-02',
            batchTime: '11:15 AM',
            dispatchTime: '11:30 AM',
            siteArrivalTime: '11:52 AM',
            dischargeStartTime: '12:00 PM',
            dischargeEndTime: '12:30 PM',
            mixerTruckNumber: 'AS-01-EC-4415',
            driverName: 'Manas Pratim',
            batchingPlantName: 'OIL Central Batching Plant',
            cementBatchCert: 'Dalmia DSP Cement OPC 53 - Cert #DSP-88219',
            superplasticizerDosage: 'BASF MasterRheobuild 1100 @ 0.90% (4.14 L/m³)',
            batchVolumeM3: 7.0,
            cumulativeVolumeM3: 42.0,
            slumpAtDischargeMm: 105,
            concreteTempCelsius: 28.3,
            ambientTempCelsius: 30.5,
            isQcAccepted: true,
            qcInspectorSign: 'R.K.S.',
          ),
        ],
        cubeRecords: [
          // 7-Day breaks
          CubeBreakRecord(
            sampleId: 'CB-PP02-7D-01',
            pourCardId: 'PC-2026-PP-02',
            structureName: 'Pump Pad B',
            mixGrade: 'M40',
            castDate: d02,
            testDate: d02.add(const Duration(days: 7)),
            ageDays: 7,
            targetStrengthMpa: 28.0, // 70% of 40
            measuredStrengthMpa: 31.6,
            failureLoadKn: 711.0,
            densityKgM3: 2470.0,
            failurePattern: 'True Pyramidal Shear',
            curingTankRef: 'Tank-01 (Curing Chamber)',
            ctmMachineId: 'CTM-2000kN',
            labTechnician: 'D. Kalita',
            tpiaWitness: 'Lloyd\'s Register',
            labCertNumber: 'LAB-IS516-2026-0909',
          ),
          CubeBreakRecord(
            sampleId: 'CB-PP02-7D-02',
            pourCardId: 'PC-2026-PP-02',
            structureName: 'Pump Pad B',
            mixGrade: 'M40',
            castDate: d02,
            testDate: d02.add(const Duration(days: 7)),
            ageDays: 7,
            targetStrengthMpa: 28.0,
            measuredStrengthMpa: 32.1,
            failureLoadKn: 722.2,
            densityKgM3: 2475.0,
            failurePattern: 'True Pyramidal Shear',
            curingTankRef: 'Tank-01 (Curing Chamber)',
            ctmMachineId: 'CTM-2000kN',
            labTechnician: 'D. Kalita',
            tpiaWitness: 'Lloyd\'s Register',
            labCertNumber: 'LAB-IS516-2026-0909',
          ),
          // 28-Day breaks
          CubeBreakRecord(
            sampleId: 'CB-PP02-28D-01',
            pourCardId: 'PC-2026-PP-02',
            structureName: 'Pump Pad B',
            mixGrade: 'M40',
            castDate: d02,
            testDate: d02.add(const Duration(days: 28)),
            ageDays: 28,
            targetStrengthMpa: 40.0, // 100% of 40
            measuredStrengthMpa: 44.5, // 111.2%
            failureLoadKn: 1001.2,
            densityKgM3: 2482.0,
            failurePattern: 'True Pyramidal Shear',
            curingTankRef: 'Tank-01 (Curing Chamber)',
            ctmMachineId: 'CTM-2000kN',
            labTechnician: 'D. Kalita',
            tpiaWitness: 'Marcus Vance & Lloyd\'s',
            labCertNumber: 'LAB-IS516-2026-0930',
          ),
          CubeBreakRecord(
            sampleId: 'CB-PP02-28D-02',
            pourCardId: 'PC-2026-PP-02',
            structureName: 'Pump Pad B',
            mixGrade: 'M40',
            castDate: d02,
            testDate: d02.add(const Duration(days: 28)),
            ageDays: 28,
            targetStrengthMpa: 40.0,
            measuredStrengthMpa: 45.2, // 113.0%
            failureLoadKn: 1017.0,
            densityKgM3: 2488.0,
            failurePattern: 'True Pyramidal Shear',
            curingTankRef: 'Tank-01 (Curing Chamber)',
            ctmMachineId: 'CTM-2000kN',
            labTechnician: 'D. Kalita',
            tpiaWitness: 'Marcus Vance & Lloyd\'s',
            labCertNumber: 'LAB-IS516-2026-0930',
          ),
          CubeBreakRecord(
            sampleId: 'CB-PP02-28D-03',
            pourCardId: 'PC-2026-PP-02',
            structureName: 'Pump Pad B',
            mixGrade: 'M40',
            castDate: d02,
            testDate: d02.add(const Duration(days: 28)),
            ageDays: 28,
            targetStrengthMpa: 40.0,
            measuredStrengthMpa: 44.1, // 110.2%
            failureLoadKn: 992.2,
            densityKgM3: 2480.0,
            failurePattern: 'True Pyramidal Shear',
            curingTankRef: 'Tank-01 (Curing Chamber)',
            ctmMachineId: 'CTM-2000kN',
            labTechnician: 'D. Kalita',
            tpiaWitness: 'Marcus Vance & Lloyd\'s',
            labCertNumber: 'LAB-IS516-2026-0930',
          ),
        ],
      ),

      // 3. Flare Stack Pedestal
      PourCardModel(
        id: 'PC-2026-FS-03',
        structureName: 'Flare Stack Pedestal',
        locationCode: 'Flare Area East · Elevation +0.00 to +3.80m',
        workPackage: 'WP-06 Flare Network & Elevated Structural Foundations',
        activityCode: 'ACT-CIV-305',
        mixGrade: 'M40',
        targetVolumeM3: 68.0,
        pouredVolumeM3: 68.0,
        pourDate: d27,
        pourTimeWindow: '05:30 AM - 13:45 PM',
        status: PourCardStatus.activeCuring,
        waterCementRatio: 0.42,
        designSlumpMm: 100,
        slumpToleranceMm: 25,
        curingMethod: 'Constant Trickle Water Sprinklers + Wet Geotextile Wrap',
        curingDaysCompleted: 3,
        leadQcEngineer: 'R. K. Sharma (QA/QC Lead)',
        tpiaWitnessLead: 'Bureau Veritas / Ananya Sen',
        technicalNotes:
            'Octagonal pedestal supporting 75m high flare stack. High overturning moment and high wind load resistance. Dense reinforcement grid requires strict slump 100±25mm and 0.42 W/C ratio. Curing day 3 in progress. 7-day cube break scheduled in 4 days.',
        prePourChecklist: const [
          PrePourCheckItem(
            id: 'CHK-FS-01',
            title: 'Octagonal Formwork Alignment & Heavy Bracing',
            specification: 'Octagonal radius ±3mm, braced with diagonal push-pull props to deadman anchors',
            isCleared: true,
            clearedBy: 'R. K. Sharma',
            clearedTimestamp: '27-Sep-2026 04:45 AM',
          ),
          PrePourCheckItem(
            id: 'CHK-FS-02',
            title: '32mm & 25mm Fe500D Rebar Congestion Clearance',
            specification: 'Coarse aggregate 20mm passage verified with rebar comb template',
            isCleared: true,
            clearedBy: 'Ananya Sen',
            clearedTimestamp: '27-Sep-2026 05:00 AM',
          ),
          PrePourCheckItem(
            id: 'CHK-FS-03',
            title: 'High-Tensile Anchor Stud Template (16 Nos. M56 Studs)',
            specification: 'Anchor ring coordinate surveyed via Total Station to within ±1.0mm',
            isCleared: true,
            clearedBy: 'Marcus Vance',
            clearedTimestamp: '27-Sep-2026 05:15 AM',
          ),
          PrePourCheckItem(
            id: 'CHK-FS-04',
            title: 'Needle Vibrator Redundancy (4 Active + 2 Standby)',
            specification: '60mm and 40mm high frequency poker vibrators inspected and operational',
            isCleared: true,
            clearedBy: 'Vikram Joshi',
            clearedTimestamp: '27-Sep-2026 05:20 AM',
          ),
        ],
        tickets: const [
          BatchingPlantTicket(
            ticketNumber: 'RMC-TK-8910',
            pourCardId: 'PC-2026-FS-03',
            batchTime: '05:15 AM',
            dispatchTime: '05:30 AM',
            siteArrivalTime: '05:52 AM',
            dischargeStartTime: '06:00 AM',
            dischargeEndTime: '06:40 AM',
            mixerTruckNumber: 'AS-01-EC-4412',
            driverName: 'Biren Gogoi',
            batchingPlantName: 'OIL Central Batching Plant',
            cementBatchCert: 'Ultratech OPC 53 Grade - Cert #UT-2026-A52',
            superplasticizerDosage: 'BASF MasterRheobuild 1100 @ 0.90% (4.14 L/m³)',
            batchVolumeM3: 6.8,
            cumulativeVolumeM3: 6.8,
            slumpAtDischargeMm: 115,
            concreteTempCelsius: 26.5,
            ambientTempCelsius: 26.8,
            isQcAccepted: true,
            qcInspectorSign: 'R.K.S.',
          ),
          BatchingPlantTicket(
            ticketNumber: 'RMC-TK-8911',
            pourCardId: 'PC-2026-FS-03',
            batchTime: '05:55 AM',
            dispatchTime: '06:10 AM',
            siteArrivalTime: '06:33 AM',
            dischargeStartTime: '06:45 AM',
            dischargeEndTime: '07:20 AM',
            mixerTruckNumber: 'AS-01-EC-4415',
            driverName: 'Manas Pratim',
            batchingPlantName: 'OIL Central Batching Plant',
            cementBatchCert: 'Ultratech OPC 53 Grade - Cert #UT-2026-A52',
            superplasticizerDosage: 'BASF MasterRheobuild 1100 @ 0.90% (4.14 L/m³)',
            batchVolumeM3: 6.8,
            cumulativeVolumeM3: 13.6,
            slumpAtDischargeMm: 108,
            concreteTempCelsius: 26.9,
            ambientTempCelsius: 27.2,
            isQcAccepted: true,
            qcInspectorSign: 'R.K.S.',
          ),
          BatchingPlantTicket(
            ticketNumber: 'RMC-TK-8920',
            pourCardId: 'PC-2026-FS-03',
            batchTime: '12:30 PM',
            dispatchTime: '12:45 PM',
            siteArrivalTime: '13:05 PM',
            dischargeStartTime: '13:12 PM',
            dischargeEndTime: '13:45 PM',
            mixerTruckNumber: 'AS-23-BC-9108',
            driverName: 'Tarun Saikia',
            batchingPlantName: 'OIL Central Batching Plant',
            cementBatchCert: 'Ultratech OPC 53 Grade - Cert #UT-2026-A52',
            superplasticizerDosage: 'BASF MasterRheobuild 1100 @ 0.90% (4.14 L/m³)',
            batchVolumeM3: 6.8,
            cumulativeVolumeM3: 68.0,
            slumpAtDischargeMm: 102,
            concreteTempCelsius: 28.5,
            ambientTempCelsius: 31.8,
            isQcAccepted: true,
            qcInspectorSign: 'R.K.S.',
          ),
        ],
        cubeRecords: [
          // 3-day indicative early break done for demoulding check
          CubeBreakRecord(
            sampleId: 'CB-FS03-3D-IND',
            pourCardId: 'PC-2026-FS-03',
            structureName: 'Flare Stack Pedestal',
            mixGrade: 'M40',
            castDate: d27,
            testDate: d27.add(const Duration(days: 3)),
            ageDays: 3,
            targetStrengthMpa: 20.0, // Indicative 50%
            measuredStrengthMpa: 22.8,
            failureLoadKn: 513.0,
            densityKgM3: 2465.0,
            failurePattern: 'True Pyramidal Shear',
            curingTankRef: 'Tank-02 (Site QC Lab)',
            ctmMachineId: 'CTM-2000kN',
            labTechnician: 'K. Bora',
            tpiaWitness: 'Bureau Veritas',
            labCertNumber: 'LAB-IS516-2026-0930-IND',
          ),
        ],
      ),

      // 4. Substation Raft
      PourCardModel(
        id: 'PC-2026-SR-04',
        structureName: 'Substation Raft',
        locationCode: 'Substation Compound · 33kV Switchgear Building Raft Slab',
        workPackage: 'WP-08 Substation Electrical Buildings & Basements',
        activityCode: 'ACT-CIV-308',
        mixGrade: 'M25',
        targetVolumeM3: 120.0,
        pouredVolumeM3: 120.0,
        pourDate: d15,
        pourTimeWindow: '06:00 AM - 16:30 PM',
        status: PourCardStatus.sevenDayPassed,
        waterCementRatio: 0.42,
        designSlumpMm: 100,
        slumpToleranceMm: 25,
        curingMethod: 'Water Ponding with 75mm Mortar Bunds across entire raft',
        curingDaysCompleted: 15,
        leadQcEngineer: 'R. K. Sharma (QA/QC Lead)',
        tpiaWitnessLead: 'EIL / Vikram Joshi',
        technicalNotes:
            'Large mass pour 120m³ for 33kV substation raft slab. Ground water level isolated with membrane. Slump maintained at 100±25mm. 7-day cube break achieved 19.8 MPa (target 17.5 MPa). 28-day break due on day 28.',
        prePourChecklist: const [
          PrePourCheckItem(
            id: 'CHK-SR-01',
            title: 'Sub-grade 100mm PCC Mud Mat & Waterproof Membrane',
            specification: 'M10 PCC screed flat within 5mm, waterproofing membrane sealed without punctures',
            isCleared: true,
            clearedBy: 'R. K. Sharma',
            clearedTimestamp: '15-Sep-2026 05:15 AM',
          ),
          PrePourCheckItem(
            id: 'CHK-SR-02',
            title: 'Bottom & Top Rebar Grids with Spacer Trellises',
            specification: 'Fe500D rebar 16mm @ 150 c/c both ways with weld-mesh earthing grid bonded',
            isCleared: true,
            clearedBy: 'Ananya Sen',
            clearedTimestamp: '15-Sep-2026 05:35 AM',
          ),
          PrePourCheckItem(
            id: 'CHK-SR-03',
            title: 'Electrical Copper Earthing Tape Embedment',
            specification: '50x6mm copper tape welded to rebar grid with exothermic Cadweld joints',
            isCleared: true,
            clearedBy: 'Vikram Joshi',
            clearedTimestamp: '15-Sep-2026 05:45 AM',
          ),
          PrePourCheckItem(
            id: 'CHK-SR-04',
            title: 'Cable Trench Box-outs & Wall Starter Dowels',
            specification: 'Pre-formed wooden boxouts braced internally against concrete buoyancy uplift',
            isCleared: true,
            clearedBy: 'Marcus Vance',
            clearedTimestamp: '15-Sep-2026 05:50 AM',
          ),
        ],
        tickets: const [
          BatchingPlantTicket(
            ticketNumber: 'RMC-TK-8740',
            pourCardId: 'PC-2026-SR-04',
            batchTime: '05:40 AM',
            dispatchTime: '05:55 AM',
            siteArrivalTime: '06:18 AM',
            dischargeStartTime: '06:25 AM',
            dischargeEndTime: '07:05 AM',
            mixerTruckNumber: 'AS-01-EC-4412',
            driverName: 'Biren Gogoi',
            batchingPlantName: 'OIL Central Batching Plant',
            cementBatchCert: 'Ultratech PPC - Cert #UT-2026-B12',
            superplasticizerDosage: 'Fosroc Auramix 400 @ 0.80% (2.88 L/m³)',
            batchVolumeM3: 8.0,
            cumulativeVolumeM3: 8.0,
            slumpAtDischargeMm: 110,
            concreteTempCelsius: 27.0,
            ambientTempCelsius: 27.5,
            isQcAccepted: true,
            qcInspectorSign: 'R.K.S.',
          ),
          BatchingPlantTicket(
            ticketNumber: 'RMC-TK-8741',
            pourCardId: 'PC-2026-SR-04',
            batchTime: '06:30 AM',
            dispatchTime: '06:45 AM',
            siteArrivalTime: '07:10 AM',
            dischargeStartTime: '07:18 AM',
            dischargeEndTime: '07:55 AM',
            mixerTruckNumber: 'AS-01-EC-4415',
            driverName: 'Manas Pratim',
            batchingPlantName: 'OIL Central Batching Plant',
            cementBatchCert: 'Ultratech PPC - Cert #UT-2026-B12',
            superplasticizerDosage: 'Fosroc Auramix 400 @ 0.80% (2.88 L/m³)',
            batchVolumeM3: 8.0,
            cumulativeVolumeM3: 16.0,
            slumpAtDischargeMm: 105,
            concreteTempCelsius: 27.4,
            ambientTempCelsius: 28.2,
            isQcAccepted: true,
            qcInspectorSign: 'R.K.S.',
          ),
          BatchingPlantTicket(
            ticketNumber: 'RMC-TK-8755',
            pourCardId: 'PC-2026-SR-04',
            batchTime: '15:30 PM',
            dispatchTime: '15:45 PM',
            siteArrivalTime: '16:05 PM',
            dischargeStartTime: '16:10 PM',
            dischargeEndTime: '16:30 PM',
            mixerTruckNumber: 'AS-23-BC-9108',
            driverName: 'Tarun Saikia',
            batchingPlantName: 'OIL Central Batching Plant',
            cementBatchCert: 'Ultratech PPC - Cert #UT-2026-B12',
            superplasticizerDosage: 'Fosroc Auramix 400 @ 0.80% (2.88 L/m³)',
            batchVolumeM3: 8.0,
            cumulativeVolumeM3: 120.0,
            slumpAtDischargeMm: 95,
            concreteTempCelsius: 29.0,
            ambientTempCelsius: 32.0,
            isQcAccepted: true,
            qcInspectorSign: 'R.K.S.',
          ),
        ],
        cubeRecords: [
          CubeBreakRecord(
            sampleId: 'CB-SR04-7D-01',
            pourCardId: 'PC-2026-SR-04',
            structureName: 'Substation Raft',
            mixGrade: 'M25',
            castDate: d15,
            testDate: d15.add(const Duration(days: 7)),
            ageDays: 7,
            targetStrengthMpa: 17.5, // 70% of 25
            measuredStrengthMpa: 19.4,
            failureLoadKn: 436.5,
            densityKgM3: 2420.0,
            failurePattern: 'True Pyramidal Shear',
            curingTankRef: 'Tank-01 (Curing Chamber)',
            ctmMachineId: 'CTM-2000kN',
            labTechnician: 'D. Kalita',
            tpiaWitness: 'EIL / Vikram Joshi',
            labCertNumber: 'LAB-IS516-2026-0922',
          ),
          CubeBreakRecord(
            sampleId: 'CB-SR04-7D-02',
            pourCardId: 'PC-2026-SR-04',
            structureName: 'Substation Raft',
            mixGrade: 'M25',
            castDate: d15,
            testDate: d15.add(const Duration(days: 7)),
            ageDays: 7,
            targetStrengthMpa: 17.5,
            measuredStrengthMpa: 20.1,
            failureLoadKn: 452.2,
            densityKgM3: 2435.0,
            failurePattern: 'True Pyramidal Shear',
            curingTankRef: 'Tank-01 (Curing Chamber)',
            ctmMachineId: 'CTM-2000kN',
            labTechnician: 'D. Kalita',
            tpiaWitness: 'EIL / Vikram Joshi',
            labCertNumber: 'LAB-IS516-2026-0922',
          ),
        ],
      ),
    ];
  }

  // Helper getters for summary calculations
  double get _totalPouredVolumeM3 =>
      _pourCards.fold(0.0, (acc, card) => acc + card.pouredVolumeM3);

  int get _totalCubesTested {
    return _pourCards.fold(0, (acc, card) => acc + card.cubeRecords.length);
  }

  int get _passedCubesCount {
    return _pourCards.fold(
      0,
      (acc, card) => acc + card.cubeRecords.where((c) => c.isPass).length,
    );
  }

  double get _cubePassRate {
    if (_totalCubesTested == 0) return 100.0;
    return (_passedCubesCount / _totalCubesTested) * 100.0;
  }

  List<PourCardModel> get _filteredPourCards {
    return _pourCards.where((card) {
      final matchesSearch = _searchFilter.isEmpty ||
          card.structureName.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          card.id.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          card.locationCode.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          card.mixGrade.toLowerCase().contains(_searchFilter.toLowerCase());

      final matchesGrade = _selectedGradeFilter == 'ALL' ||
          card.mixGrade == _selectedGradeFilter;

      final matchesStatus = _selectedStatusFilter == 'ALL' ||
          (_selectedStatusFilter == 'ACTIVE' &&
              card.status == PourCardStatus.activeCuring) ||
          (_selectedStatusFilter == '7D_DONE' &&
              card.status == PourCardStatus.sevenDayPassed) ||
          (_selectedStatusFilter == '28D_DONE' &&
              card.status == PourCardStatus.closedCertified);

      return matchesSearch && matchesGrade && matchesStatus;
    }).toList();
  }

  List<CubeBreakRecord> get _allCubeRecords {
    final list = <CubeBreakRecord>[];
    for (final card in _pourCards) {
      list.addAll(card.cubeRecords);
    }
    // Sort recent test date first
    list.sort((a, b) => b.testDate.compareTo(a.testDate));
    return list;
  }

  List<BatchingPlantTicket> get _allBatchTickets {
    final list = <BatchingPlantTicket>[];
    for (final card in _pourCards) {
      list.addAll(card.tickets);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSummaryKpiBanner(),
          _buildFilterAndSearchBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPourCardsTab(),
                _buildMixSpecsTab(),
                _buildCubeStrengthLogTab(),
                _buildBatchingPlantTicketsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildSpeedDialFab(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
            ),
            child: const Icon(
              Icons.domain_verification_rounded,
              color: AppTheme.primaryLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Concrete Pour & Cube QA',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'IS 456 / IS 516 QA Verification & Strength Logs',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Standards & QA Dossier',
          icon: const Icon(Icons.verified_rounded, color: AppTheme.tertiary),
          onPressed: _showQaDossierDialog,
        ),
        IconButton(
          tooltip: 'Reset / Refresh Data',
          icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
          onPressed: () {
            setState(() {
              _initializeData();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('QA Register refreshed to project benchmark values.'),
                duration: Duration(seconds: 2),
                backgroundColor: AppTheme.surfaceContainerHigh,
              ),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ============================================================================
  // SUMMARY KPI METRIC CARDS
  // ============================================================================

  Widget _buildSummaryKpiBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          if (isNarrow) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.water_drop_rounded,
                        label: 'Total Poured',
                        value: '${_totalPouredVolumeM3.toStringAsFixed(1)} m³',
                        color: AppTheme.primaryLight,
                        subtitle: 'Across 4 Major Plinths',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.analytics_rounded,
                        label: 'Pass Rate',
                        value: '${_cubePassRate.toStringAsFixed(0)}%',
                        color: AppTheme.tertiary,
                        subtitle: '$_passedCubesCount/$_totalCubesTested Cube Breaks',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.tune_rounded,
                        label: 'Water/Cement',
                        value: '0.42 W/C',
                        color: AppTheme.secondary,
                        subtitle: 'IS 456 Permissible ≤0.45',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.compress_rounded,
                        label: 'Target Slump',
                        value: '100±25mm',
                        color: const Color(0xFFA78BFA),
                        subtitle: 'True Slump Cone Test',
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.water_drop_rounded,
                  label: 'Total Poured',
                  value: '${_totalPouredVolumeM3.toStringAsFixed(1)} m³',
                  color: AppTheme.primaryLight,
                  subtitle: 'Across 4 Major Plinths',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.analytics_rounded,
                  label: 'Pass Rate',
                  value: '${_cubePassRate.toStringAsFixed(0)}%',
                  color: AppTheme.tertiary,
                  subtitle: '$_passedCubesCount/$_totalCubesTested Cube Breaks',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.tune_rounded,
                  label: 'Water/Cement',
                  value: '0.42 W/C',
                  color: AppTheme.secondary,
                  subtitle: 'IS 456 Permissible ≤0.45',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.compress_rounded,
                  label: 'Target Slump',
                  value: '100±25 mm',
                  color: const Color(0xFFA78BFA),
                  subtitle: 'True Slump Cone Test',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SEARCH & FILTER BAR
  // ============================================================================

  Widget _buildFilterAndSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      hintText: 'Search asset (Compressor, Pump Pad, Flare, Substation)...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
                      suffixIcon: _searchFilter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 16),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchFilter = '';
                                });
                              },
                            )
                          : null,
                      fillColor: AppTheme.surfaceCard,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchFilter = val;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Mix Grade: ',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                _buildGradeFilterChip('ALL', 'All Grades'),
                _buildGradeFilterChip('M25', 'M25'),
                _buildGradeFilterChip('M35', 'M35'),
                _buildGradeFilterChip('M40', 'M40'),
                const SizedBox(width: 12),
                Container(height: 16, width: 1, color: AppTheme.border),
                const SizedBox(width: 12),
                const Text(
                  'Status: ',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                _buildStatusFilterChip('ALL', 'All Pours'),
                _buildStatusFilterChip('ACTIVE', 'Curing (3-8d)'),
                _buildStatusFilterChip('7D_DONE', '7D Passed'),
                _buildStatusFilterChip('28D_DONE', '28D Certified'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeFilterChip(String gradeKey, String label) {
    final isSelected = _selectedGradeFilter == gradeKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        backgroundColor: AppTheme.surfaceCard,
        selectedColor: AppTheme.primary,
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        onSelected: (val) {
          setState(() {
            _selectedGradeFilter = gradeKey;
          });
        },
      ),
    );
  }

  Widget _buildStatusFilterChip(String statusKey, String label) {
    final isSelected = _selectedStatusFilter == statusKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        backgroundColor: AppTheme.surfaceCard,
        selectedColor: AppTheme.secondary.withValues(alpha: 0.85),
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isSelected ? AppTheme.secondary : AppTheme.border,
          ),
        ),
        onSelected: (val) {
          setState(() {
            _selectedStatusFilter = statusKey;
          });
        },
      ),
    );
  }

  // ============================================================================
  // TAB NAVIGATION BAR
  // ============================================================================

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 2.5,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: [
          Tab(
            icon: const Icon(Icons.assignment_rounded, size: 18),
            text: 'Pour Cards (${_filteredPourCards.length})',
          ),
          const Tab(
            icon: Icon(Icons.science_rounded, size: 18),
            text: 'Mix Specs (IS 456)',
          ),
          Tab(
            icon: const Icon(Icons.speed_rounded, size: 18),
            text: 'Cube Strength (${_allCubeRecords.length})',
          ),
          Tab(
            icon: const Icon(Icons.local_shipping_rounded, size: 18),
            text: 'Batch Tickets (${_allBatchTickets.length})',
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: POUR CARDS REGISTER
  // ============================================================================

  Widget _buildPourCardsTab() {
    final list = _filteredPourCards;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt_off_rounded, color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No Pour Cards match current filters.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _searchFilter = '';
                  _selectedGradeFilter = 'ALL';
                  _selectedStatusFilter = 'ALL';
                  _searchController.clear();
                });
              },
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final card = list[index];
        return _buildPourCardItem(card);
      },
    );
  }

  Widget _buildPourCardItem(PourCardModel card) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (card.status) {
      case PourCardStatus.activeCuring:
        statusColor = AppTheme.secondary;
        statusLabel = 'Curing Day ${card.curingDaysCompleted}/14';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case PourCardStatus.sevenDayPassed:
        statusColor = AppTheme.primaryLight;
        statusLabel = '7-Day Passed · Curing';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case PourCardStatus.twentyEightDayPassed:
      case PourCardStatus.closedCertified:
        statusColor = AppTheme.tertiary;
        statusLabel = '28-Day Strength Certified';
        statusIcon = Icons.verified_rounded;
        break;
    }

    // Cube breaks count
    final sevenDayBreaks = card.cubeRecords.where((c) => c.ageDays == 7).toList();
    final twentyEightDayBreaks = card.cubeRecords.where((c) => c.ageDays == 28).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border, width: 1),
      ),
      child: ExpansionTile(
        initiallyExpanded: card.structureName.contains('Compressor') || card.structureName.contains('Pump Pad'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _getGradeColor(card.mixGrade).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _getGradeColor(card.mixGrade).withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: Text(
            card.mixGrade,
            style: TextStyle(
              color: _getGradeColor(card.mixGrade),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                card.structureName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${card.id} · ${card.locationCode}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: card.volumeProgress,
                        backgroundColor: AppTheme.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          card.volumeProgress >= 1.0 ? AppTheme.tertiary : AppTheme.primaryLight,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${card.pouredVolumeM3}/${card.targetVolumeM3} m³',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(color: AppTheme.border),
          // Technical Spec Highlights
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniSpec(
                      label: 'Water/Cement Ratio',
                      value: '${card.waterCementRatio} (Target)',
                      icon: Icons.water_drop_rounded,
                      color: AppTheme.secondary,
                    ),
                    _buildMiniSpec(
                      label: 'Design Slump',
                      value: '${card.designSlumpMm} ± ${card.slumpToleranceMm}mm',
                      icon: Icons.height_rounded,
                      color: AppTheme.primaryLight,
                    ),
                    _buildMiniSpec(
                      label: 'Pour Date',
                      value: DateFormat('dd MMM yyyy').format(card.pourDate),
                      icon: Icons.calendar_today_rounded,
                      color: AppTheme.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.spa_rounded, color: AppTheme.tertiary, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Curing Method: ${card.curingMethod}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Cube Compressive Strength Status Banner
          _buildCardCubeStatusRow(card, sevenDayBreaks, twentyEightDayBreaks),
          const SizedBox(height: 12),

          // Pre-pour Inspection Hold-Points
          _buildPrePourSection(card),
          const SizedBox(height: 12),

          // Action Buttons: Add Cube Test, View Tickets, Digital Sign-off
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.add_task_rounded, size: 16),
                  label: const Text('Log Cube Break'),
                  onPressed: () => _showAddCubeTestDialog(preselectedCardId: card.id),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text('Record Ticket'),
                  onPressed: () => _showAddBatchTicketDialog(preselectedCardId: card.id),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Card Details & QA Stamp',
                icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
                onPressed: () => _showPourCardDetailModal(card),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSpec({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCardCubeStatusRow(
    PourCardModel card,
    List<CubeBreakRecord> sevenDayBreaks,
    List<CubeBreakRecord> twentyEightDayBreaks,
  ) {
    final spec = _mixSpecifications[card.mixGrade] ?? _mixSpecifications['M35']!;

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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Compressive Strength Compliance (IS 516)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '150mm Standard Cubes',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // 7-Day Break Summary
              Expanded(
                child: _buildBreakSummaryBox(
                  title: '7-Day Break',
                  target: '≥ ${spec.target7DayStrengthMpa.toStringAsFixed(1)} MPa (70%)',
                  records: sevenDayBreaks,
                  accentColor: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              // 28-Day Break Summary
              Expanded(
                child: _buildBreakSummaryBox(
                  title: '28-Day Break',
                  target: '≥ ${spec.target28DayStrengthMpa.toStringAsFixed(1)} MPa (100%)',
                  records: twentyEightDayBreaks,
                  accentColor: AppTheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakSummaryBox({
    required String title,
    required String target,
    required List<CubeBreakRecord> records,
    required Color accentColor,
  }) {
    final hasBreaks = records.isNotEmpty;
    final allPassed = hasBreaks && records.every((r) => r.isPass);
    final avgStrength = hasBreaks
        ? records.fold(0.0, (acc, r) => acc + r.measuredStrengthMpa) / records.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hasBreaks
              ? (allPassed ? AppTheme.tertiary.withValues(alpha: 0.5) : AppTheme.error.withValues(alpha: 0.5))
              : AppTheme.border,
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
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hasBreaks)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: allPassed
                        ? AppTheme.tertiary.withValues(alpha: 0.15)
                        : AppTheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    allPassed ? 'PASS' : 'FAIL',
                    style: TextStyle(
                      color: allPassed ? AppTheme.tertiary : AppTheme.error,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                const Text(
                  'PENDING',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            target,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 6),
          if (hasBreaks)
            Text(
              'Avg: ${avgStrength.toStringAsFixed(1)} MPa (${records.length} Cubes)',
              style: TextStyle(
                color: allPassed ? accentColor : AppTheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            const Text(
              'Awaiting curing schedule',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _buildPrePourSection(PourCardModel card) {
    final clearedCount = card.prePourChecklist.where((c) => c.isCleared).length;
    final totalCount = card.prePourChecklist.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.check_box_rounded, color: AppTheme.tertiary, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'Pre-Pour QA Hold Points (IS 14687 & FIDIC Cl. 7.3)',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              '$clearedCount/$totalCount Cleared',
              style: TextStyle(
                color: clearedCount == totalCount ? AppTheme.tertiary : AppTheme.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...card.prePourChecklist.map((chk) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  chk.isCleared ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: chk.isCleared ? AppTheme.tertiary : AppTheme.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: '${chk.title}: ',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: chk.specification,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ============================================================================
  // TAB 2: MIX DESIGN SPECIFICATIONS (M25, M35, M40)
  // ============================================================================

  Widget _buildMixSpecsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Technical Reference Callout
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_book_rounded, color: AppTheme.primaryLight, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Indian Standard Mix Design Parameters (IS 456 / IS 10262)',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'All mixes designed with strictly controlled Water-Cement (W/C) Ratio of 0.42 to ensure dense, low-permeability concrete for hydrocarbon and compressor foundation durability. Standard slump is specified at 100 ± 25mm for optimal pumpability through 100m boom pipelines.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildBadge('W/C: 0.42 Constant', AppTheme.secondary),
                        _buildBadge('Slump: 100±25mm', AppTheme.primaryLight),
                        _buildBadge('7-Day Target ≥70% fck', AppTheme.tertiary),
                        _buildBadge('28-Day Target ≥100% fck', AppTheme.tertiary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Mix Spec Cards for M25, M35, M40
        ..._mixSpecifications.values.map(_buildMixDesignSpecCard),

        // Quality Control Compliance Standards Matrix
        _buildQualityStandardMatrix(),
      ],
    );
  }

  Widget _buildMixDesignSpecCard(MixDesignSpec spec) {
    final gradeColor = _getGradeColor(spec.grade);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: gradeColor.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: gradeColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: gradeColor),
                      ),
                      child: Text(
                        'GRADE ${spec.grade}',
                        style: TextStyle(
                          color: gradeColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'fck = ${spec.characteristicStrengthMpa.toStringAsFixed(0)} MPa (N/mm²)',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          spec.standardCode,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    spec.mixDesignCertRef,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              spec.applicationSummary,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Compressive Strength Targets
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '7-Day Cube Target (≥70% fck)',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '≥ ${spec.target7DayStrengthMpa.toStringAsFixed(1)} MPa',
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Early stripping & form removal check',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppTheme.border),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '28-Day Cube Target (≥100% fck)',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '≥ ${spec.target28DayStrengthMpa.toStringAsFixed(1)} MPa',
                          style: TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Full characteristic design capacity',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Mix Design Proportions Table
            const Text(
              'Batch Proportions per Cubic Meter (1.0 m³):',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Table(
              border: TableBorder.all(color: AppTheme.border.withValues(alpha: 0.5), width: 0.8),
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(2.0),
              },
              children: [
                _buildTableRow('Cement (OPC 53 Grade)', '${spec.cementContentKgM3.toStringAsFixed(0)} kg', 'IS 269 Compliant', isHeader: false),
                _buildTableRow('Pozzolanic / Micro-Silica', '${spec.flyAshMicroSilicaKgM3.toStringAsFixed(0)} kg', 'Class F Flyash / Silica', isHeader: false),
                _buildTableRow('Water (Clean Potable)', '${spec.waterLitresM3.toStringAsFixed(1)} L', 'W/C = ${spec.waterCementRatio}', isHeader: false),
                _buildTableRow('Fine Aggregate (Zone II Sand)', '${spec.fineAggregateKgM3.toStringAsFixed(0)} kg', 'Silt content < 3.0%', isHeader: false),
                _buildTableRow('Coarse Aggregates (10mm + 20mm)', '${(spec.coarse10mmKgM3 + spec.coarse20mmKgM3).toStringAsFixed(0)} kg', 'Graded crushed stone', isHeader: false),
                _buildTableRow('Superplasticizer Dosage', '${spec.superplasticizerDosagePercent}% by wt.', spec.superplasticizerBrand, isHeader: false),
                _buildTableRow('Specified Slump Range', spec.slumpRangeDisplay, 'True Slump at 27°C', isHeader: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String item, String qty, String notes, {bool isHeader = false}) {
    final style = TextStyle(
      color: isHeader ? AppTheme.primaryLight : AppTheme.textPrimary,
      fontSize: 11,
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
    );

    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? AppTheme.surfaceContainerHigh : AppTheme.surfaceCard,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(item, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(qty, style: style.copyWith(fontWeight: FontWeight.w700)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(notes, style: style.copyWith(color: AppTheme.textSecondary, fontSize: 10)),
        ),
      ],
    );
  }

  Widget _buildQualityStandardMatrix() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
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
              Icon(Icons.rule_folder_rounded, color: AppTheme.tertiary, size: 18),
              SizedBox(width: 8),
              Text(
                'QA/QC Acceptance Criteria Matrix',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildMatrixRow(
            'Slump Permissibility (IS 1199)',
            '100 ± 25 mm',
            'Loads below 75mm or above 125mm rejected at gate with non-conformance ticket.',
          ),
          const Divider(color: AppTheme.border, height: 16),
          _buildMatrixRow(
            'Maximum Concrete Temp (IS 456)',
            '≤ 32.0°C at placement',
            'Chilled mixing water and ice flakes deployed during hot weather pours.',
          ),
          const Divider(color: AppTheme.border, height: 16),
          _buildMatrixRow(
            'Cube Break Criteria (IS 516)',
            'Individual ≥ fck - 3 N/mm²',
            'Average of 3 cubes must meet 70% at 7 days and 100% at 28 days characteristic strength.',
          ),
          const Divider(color: AppTheme.border, height: 16),
          _buildMatrixRow(
            'W/C Ratio Limit',
            '0.42 max design',
            'Strict ban on adding site wash-water to transit mixer drums before discharge.',
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(String title, String rule, String explanation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                rule,
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          explanation,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 3: COMPRESSIVE STRENGTH TEST LOG (IS 516)
  // ============================================================================

  Widget _buildCubeStrengthLogTab() {
    final records = _allCubeRecords;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statistical Overview Header
        _buildCubeLogHeader(),
        const SizedBox(height: 16),

        // Cube Record Cards
        if (records.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No compressive strength cube breaks logged yet.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...records.map(_buildCubeBreakCard),
      ],
    );
  }

  Widget _buildCubeLogHeader() {
    final sevenDayCount = _allCubeRecords.where((r) => r.ageDays == 7).length;
    final twentyEightDayCount = _allCubeRecords.where((r) => r.ageDays == 28).length;

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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compressive Strength Test Register (IS 516 / ASTM C39)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '150 × 150 × 150 mm standard test cubes tested in calibrated CTM',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Log Cube Test', style: TextStyle(fontSize: 11)),
                onPressed: () => _showAddCubeTestDialog(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniCounter('7-Day Breaks (≥70% fck)', '$sevenDayCount Tested', AppTheme.primaryLight),
              const SizedBox(width: 8),
              _buildMiniCounter('28-Day Breaks (≥100% fck)', '$twentyEightDayCount Certified', AppTheme.tertiary),
              const SizedBox(width: 8),
              _buildMiniCounter('Pass / Conformity', '$_passedCubesCount / ${_allCubeRecords.length}', AppTheme.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCounter(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCubeBreakCard(CubeBreakRecord record) {
    final isPass = record.isPass;
    final badgeColor = isPass ? AppTheme.tertiary : AppTheme.error;
    final ageBadgeColor = record.ageDays == 7 ? AppTheme.primaryLight : AppTheme.tertiary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isPass ? AppTheme.border : AppTheme.error.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Sample ID, Structure Name & Pass/Fail Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: ageBadgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ageBadgeColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${record.ageDays}-DAY BREAK',
                        style: TextStyle(
                          color: ageBadgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      record.sampleId,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPass ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: badgeColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPass ? 'PASS (${record.percentageOfFck.toStringAsFixed(1)}% fck)' : 'FAIL NON-CONFORMING',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Structure & Card Ref
            Text(
              '${record.structureName} · ${record.pourCardId} (${record.mixGrade})',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // Break Metrics Grid
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildBreakMetricCol(
                      label: 'Measured Strength',
                      value: '${record.measuredStrengthMpa.toStringAsFixed(1)} MPa',
                      color: badgeColor,
                    ),
                  ),
                  Expanded(
                    child: _buildBreakMetricCol(
                      label: 'Target (≥${record.ageDays == 7 ? "70%" : "100%"})',
                      value: '≥ ${record.targetStrengthMpa.toStringAsFixed(1)} MPa',
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: _buildBreakMetricCol(
                      label: 'Failure Load',
                      value: '${record.failureLoadKn.toStringAsFixed(1)} kN',
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  Expanded(
                    child: _buildBreakMetricCol(
                      label: 'Density',
                      value: '${record.densityKgM3.toStringAsFixed(0)} kg/m³',
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Test Metadata Footnote
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, color: AppTheme.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Cast: ${DateFormat("dd-MMM").format(record.castDate)} | Tested: ${DateFormat("dd-MMM-yyyy").format(record.testDate)}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                Text(
                  'Witness: ${record.tpiaWitness}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakMetricCol({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 4: BATCHING PLANT TICKETS
  // ============================================================================

  Widget _buildBatchingPlantTicketsTab() {
    final tickets = _allBatchTickets;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBatchTicketsHeader(),
        const SizedBox(height: 16),
        if (tickets.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No batching tickets recorded yet.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...tickets.map(_buildBatchTicketCard),
      ],
    );
  }

  Widget _buildBatchTicketsHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RMC Batching Plant Delivery Tickets',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Transit mixer tracking, cement batch certs & superplasticizer dosage',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add Ticket', style: TextStyle(fontSize: 11)),
            onPressed: () => _showAddBatchTicketDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchTicketCard(BatchingPlantTicket ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Ticket #, Truck #, Volume & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        ticket.ticketNumber,
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_rounded, size: 12, color: AppTheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            ticket.mixerTruckNumber,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${ticket.batchVolumeM3} m³ (Cumul: ${ticket.cumulativeVolumeM3} m³)',
                    style: const TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Card Ref & Plant
            Text(
              'Pour Card: ${ticket.pourCardId} · ${ticket.batchingPlantName}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),

            // Core Technical Fields: Cement Batch Cert & Superplasticizer Dosage
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_outlined, color: AppTheme.tertiary, size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        'Cement Cert: ',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          ticket.cementBatchCert,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.science_outlined, color: AppTheme.secondary, size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        'Admixture: ',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          ticket.superplasticizerDosage,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Discharge & Quality Measurements
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBatchMiniMetric('Slump at Site', '${ticket.slumpAtDischargeMm} mm', AppTheme.primaryLight),
                _buildBatchMiniMetric('Batch Time', ticket.batchTime, AppTheme.textSecondary),
                _buildBatchMiniMetric('Discharge', ticket.dischargeEndTime, AppTheme.textSecondary),
                _buildBatchMiniMetric('Concrete Temp', '${ticket.concreteTempCelsius}°C', AppTheme.secondary),
                _buildBatchMiniMetric('Driver', ticket.driverName, AppTheme.textPrimary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchMiniMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // SPEED DIAL / QUICK ACTION FAB
  // ============================================================================

  Widget _buildSpeedDialFab() {
    return FloatingActionButton.extended(
      backgroundColor: AppTheme.primary,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text('New QA Record', style: TextStyle(fontWeight: FontWeight.w700)),
      onPressed: () {
        _showActionSelectionModal();
      },
    );
  }

  void _showActionSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record QA Field Transaction',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose concrete activity to register in the project QA database',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.speed_rounded, color: AppTheme.primaryLight),
                  ),
                  title: const Text('Log Cube Break Test (IS 516)', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Record 7-day or 28-day hydraulic compression failure', style: TextStyle(fontSize: 11.5)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddCubeTestDialog();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: AppTheme.secondary),
                  ),
                  title: const Text('Record Batching Delivery Ticket', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Log transit mixer truck, slump, batch cert & superplasticizer', style: TextStyle(fontSize: 11.5)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddBatchTicketDialog();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.post_add_rounded, color: AppTheme.tertiary),
                  ),
                  title: const Text('Initiate New Pour Card', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Register new structural pour with pre-pour checklist', style: TextStyle(fontSize: 11.5)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCreatePourCardModal();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // INTERACTIVE DIALOG: LOG CUBE COMPRESSIVE STRENGTH TEST
  // ============================================================================

  void _showAddCubeTestDialog({String? preselectedCardId}) {
    String selectedCardId = preselectedCardId ?? _pourCards.first.id;
    int selectedAgeDays = 7;
    final loadController = TextEditingController(text: '620.0');
    final technicianController = TextEditingController(text: 'D. Kalita (Lab Chemist)');
    final witnessController = TextEditingController(text: 'Marcus Vance, P.E. (FIDIC Cl. 3.1)');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final card = _pourCards.firstWhere((c) => c.id == selectedCardId);
            final spec = _mixSpecifications[card.mixGrade] ?? _mixSpecifications['M35']!;
            final targetStrength = selectedAgeDays == 7
                ? spec.target7DayStrengthMpa
                : spec.target28DayStrengthMpa;

            final double enteredLoadKn = double.tryParse(loadController.text) ?? 0.0;
            // Standard 150mm cube area = 150 * 150 = 22,500 mm²
            // 1 kN = 1,000 N -> Stress = (Load in N) / 22,500 mm² = (LoadKn * 1000) / 22500 = LoadKn / 22.5
            final double computedMpa = enteredLoadKn > 0 ? (enteredLoadKn / 22.5) : 0.0;
            final bool isPass = computedMpa >= targetStrength;

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.speed_rounded, color: AppTheme.primaryLight, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Log Cube Break (IS 516)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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
                      // Select Pour Card
                      const Text(
                        'Target Structure & Pour Card',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCardId,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: _pourCards.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.structureName} (${c.mixGrade}) - ${c.id}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCardId = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Age Selection (7-Day vs 28-Day)
                      const Text(
                        'Curing Age & Target Benchmark',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: Text('7-Day (≥70% fck = ${spec.target7DayStrengthMpa.toStringAsFixed(1)} MPa)'),
                              selected: selectedAgeDays == 7,
                              onSelected: (val) {
                                if (val) setDialogState(() => selectedAgeDays = 7);
                              },
                              selectedColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                color: selectedAgeDays == 7 ? Colors.white : AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: Text('28-Day (≥100% fck = ${spec.target28DayStrengthMpa.toStringAsFixed(1)} MPa)'),
                              selected: selectedAgeDays == 28,
                              onSelected: (val) {
                                if (val) setDialogState(() => selectedAgeDays = 28);
                              },
                              selectedColor: AppTheme.tertiary,
                              labelStyle: TextStyle(
                                color: selectedAgeDays == 28 ? Colors.white : AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Failure Load (kN) & Live Strength Calculation
                      const Text(
                        'CTM Failure Load (kN) on 150mm Cube',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: loadController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 620.0',
                          suffixText: 'kN',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onChanged: (val) {
                          setDialogState(() {});
                        },
                      ),
                      const SizedBox(height: 10),

                      // Real-time Calculation Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPass ? AppTheme.tertiary : AppTheme.error,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Computed Strength:', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
                                Text(
                                  '${computedMpa.toStringAsFixed(2)} MPa (N/mm²)',
                                  style: TextStyle(
                                    color: isPass ? AppTheme.tertiary : AppTheme.error,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Target: ≥ ${targetStrength.toStringAsFixed(1)} MPa',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: (isPass ? AppTheme.tertiary : AppTheme.error).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPass ? 'PASS VERIFIED' : 'NON-CONFORMING',
                                style: TextStyle(
                                  color: isPass ? AppTheme.tertiary : AppTheme.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Technician & TPIA witness
                      const Text(
                        'Lab Technician & TPIA Witness',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: technicianController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Lab Chemist Name',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: witnessController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Consultant / TPIA Witness',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () {
                    final enteredLoad = double.tryParse(loadController.text) ?? 620.0;
                    final mpa = enteredLoad / 22.5;

                    final newRecord = CubeBreakRecord(
                      sampleId: 'CB-${card.id.split('-').last}-${selectedAgeDays}D-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                      pourCardId: card.id,
                      structureName: card.structureName,
                      mixGrade: card.mixGrade,
                      castDate: card.pourDate,
                      testDate: DateTime.now(),
                      ageDays: selectedAgeDays,
                      targetStrengthMpa: targetStrength,
                      measuredStrengthMpa: mpa,
                      failureLoadKn: enteredLoad,
                      densityKgM3: 2450.0,
                      failurePattern: 'True Pyramidal Shear',
                      curingTankRef: 'Tank-01 (Site Lab)',
                      ctmMachineId: 'CTM-2000kN Digital',
                      labTechnician: technicianController.text.trim(),
                      tpiaWitness: witnessController.text.trim(),
                      labCertNumber: 'LAB-IS516-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
                    );

                    setState(() {
                      final cardIndex = _pourCards.indexWhere((c) => c.id == selectedCardId);
                      if (cardIndex != -1) {
                        final currentList = List<CubeBreakRecord>.from(_pourCards[cardIndex].cubeRecords);
                        currentList.add(newRecord);

                        // If 28-day break passed, update status to closedCertified
                        PourCardStatus updatedStatus = _pourCards[cardIndex].status;
                        if (selectedAgeDays == 28 && newRecord.isPass) {
                          updatedStatus = PourCardStatus.closedCertified;
                        } else if (selectedAgeDays == 7 && newRecord.isPass && updatedStatus == PourCardStatus.activeCuring) {
                          updatedStatus = PourCardStatus.sevenDayPassed;
                        }

                        _pourCards[cardIndex] = _pourCards[cardIndex].copyWith(
                          cubeRecords: currentList,
                          status: updatedStatus,
                        );
                      }
                    });

                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cube Break ${newRecord.sampleId} logged successfully! Result: ${isPass ? "PASS" : "FAIL"}'),
                        backgroundColor: isPass ? AppTheme.surfaceContainerHigh : AppTheme.error,
                      ),
                    );
                  },
                  child: const Text('Save Test Record'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================================
  // INTERACTIVE DIALOG: LOG BATCHING PLANT TICKET
  // ============================================================================

  void _showAddBatchTicketDialog({String? preselectedCardId}) {
    String selectedCardId = preselectedCardId ?? _pourCards.first.id;
    final truckController = TextEditingController(text: 'AS-01-EC-4418');
    final driverController = TextEditingController(text: 'Pranjal Baruah');
    final volumeController = TextEditingController(text: '7.0');
    final slumpController = TextEditingController(text: '100');
    final cementCertController = TextEditingController(text: 'Ultratech OPC 53 Grade - Cert #UT-2026-A58');
    final admixtureController = TextEditingController(text: 'Sika Plastiment BV-40 @ 0.85% (3.57 L/m³)');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: AppTheme.secondary, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Record Batching Plant Ticket',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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
                        'Target Pour Card',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCardId,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: _pourCards.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.structureName} (${c.id})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCardId = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Transit Mixer Truck #', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: truckController,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Truck Volume (m³)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: volumeController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Site Slump (mm)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: slumpController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                                  decoration: const InputDecoration(
                                    hintText: '100±25mm',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mixer Driver Name', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: driverController,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Cement Batch Cert Reference',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: cementCertController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Superplasticizer Brand & Dosage',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: admixtureController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                  onPressed: () {
                    final double batchVol = double.tryParse(volumeController.text) ?? 7.0;
                    final int slump = int.tryParse(slumpController.text) ?? 100;
                    final cardIndex = _pourCards.indexWhere((c) => c.id == selectedCardId);

                    if (cardIndex != -1) {
                      final card = _pourCards[cardIndex];
                      final prevCumul = card.tickets.isNotEmpty ? card.tickets.last.cumulativeVolumeM3 : 0.0;
                      final ticketNumber = 'RMC-TK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

                      final newTicket = BatchingPlantTicket(
                        ticketNumber: ticketNumber,
                        pourCardId: card.id,
                        batchTime: DateFormat('hh:mm a').format(DateTime.now().subtract(const Duration(minutes: 40))),
                        dispatchTime: DateFormat('hh:mm a').format(DateTime.now().subtract(const Duration(minutes: 25))),
                        siteArrivalTime: DateFormat('hh:mm a').format(DateTime.now().subtract(const Duration(minutes: 10))),
                        dischargeStartTime: DateFormat('hh:mm a').format(DateTime.now()),
                        dischargeEndTime: DateFormat('hh:mm a').format(DateTime.now().add(const Duration(minutes: 30))),
                        mixerTruckNumber: truckController.text.trim(),
                        driverName: driverController.text.trim(),
                        batchingPlantName: 'OIL Central Batching Plant - Duliajan',
                        cementBatchCert: cementCertController.text.trim(),
                        superplasticizerDosage: admixtureController.text.trim(),
                        batchVolumeM3: batchVol,
                        cumulativeVolumeM3: prevCumul + batchVol,
                        slumpAtDischargeMm: slump,
                        concreteTempCelsius: 27.5,
                        ambientTempCelsius: 30.2,
                        isQcAccepted: true,
                        qcInspectorSign: 'R.K.S.',
                      );

                      setState(() {
                        final currentTickets = List<BatchingPlantTicket>.from(card.tickets);
                        currentTickets.add(newTicket);
                        _pourCards[cardIndex] = card.copyWith(
                          tickets: currentTickets,
                          pouredVolumeM3: prevCumul + batchVol,
                        );
                      });
                    }

                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transit Mixer Batch Ticket recorded successfully!'),
                        backgroundColor: AppTheme.surfaceContainerHigh,
                      ),
                    );
                  },
                  child: const Text('Log Delivery Ticket', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================================
  // INTERACTIVE MODAL: CREATE NEW POUR CARD
  // ============================================================================

  void _showCreatePourCardModal() {
    final structureController = TextEditingController(text: 'Substation Transformer Pad C');
    final locationController = TextEditingController(text: 'Station 03 - East Substation Yard');
    final volumeController = TextEditingController(text: '35.0');
    String selectedGrade = 'M35';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
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
                          'Initiate New Pour Card',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Structure Name', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: structureController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    const Text('Location / Coordinates', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: locationController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Design Mix Grade', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: selectedGrade,
                                dropdownColor: AppTheme.surfaceCard,
                                items: const [
                                  DropdownMenuItem(value: 'M25', child: Text('M25 (25 MPa)')),
                                  DropdownMenuItem(value: 'M35', child: Text('M35 (35 MPa)')),
                                  DropdownMenuItem(value: 'M40', child: Text('M40 (40 MPa)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedGrade = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Target Volume (m³)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: volumeController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                        onPressed: () {
                          final targetVol = double.tryParse(volumeController.text) ?? 30.0;
                          final newCard = PourCardModel(
                            id: 'PC-2026-GEN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                            structureName: structureController.text.trim(),
                            locationCode: locationController.text.trim(),
                            workPackage: 'WP-04 Civil Foundations',
                            activityCode: 'ACT-CIV-NEW',
                            mixGrade: selectedGrade,
                            targetVolumeM3: targetVol,
                            pouredVolumeM3: 0.0,
                            pourDate: DateTime.now(),
                            pourTimeWindow: '07:00 AM - 15:00 PM',
                            status: PourCardStatus.activeCuring,
                            waterCementRatio: 0.42,
                            designSlumpMm: 100,
                            slumpToleranceMm: 25,
                            curingMethod: 'Wet Hessian Burlap + Water Ponding',
                            curingDaysCompleted: 0,
                            leadQcEngineer: 'R. K. Sharma (QA/QC Lead)',
                            tpiaWitnessLead: 'Marcus Vance, P.E. (FIDIC Cl. 3.1)',
                            technicalNotes: 'Newly initiated pour card. Pre-pour checklist in progress.',
                            prePourChecklist: const [
                              PrePourCheckItem(
                                id: 'CHK-N-01',
                                title: 'Formwork & Shuttering Stability',
                                specification: 'Bracing withstands hydrostatic pressure',
                                isCleared: true,
                                clearedBy: 'R. K. Sharma',
                                clearedTimestamp: 'Just now',
                              ),
                              PrePourCheckItem(
                                id: 'CHK-N-02',
                                title: 'Rebar Cover Block Spacing 50mm',
                                specification: 'Fe500D rebar grid compliant with structural drawing',
                                isCleared: true,
                                clearedBy: 'Ananya Sen',
                                clearedTimestamp: 'Just now',
                              ),
                              PrePourCheckItem(
                                id: 'CHK-N-03',
                                title: 'TPIA Cl. 7.3 Hold Point Clearance',
                                specification: 'Approved for concrete batching dispatch',
                                isCleared: false,
                                clearedBy: 'Pending',
                                clearedTimestamp: 'Awaiting inspection',
                              ),
                            ],
                            tickets: const [],
                            cubeRecords: const [],
                          );

                          setState(() {
                            _pourCards.insert(0, newCard);
                          });

                          Navigator.pop(modalCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('New Pour Card ${newCard.id} successfully created!'),
                              backgroundColor: AppTheme.surfaceContainerHigh,
                            ),
                          );
                        },
                        child: const Text('Register Pour Card'),
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
  // DETAIL & QA CERTIFICATE MODAL
  // ============================================================================

  void _showPourCardDetailModal(PourCardModel card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.structureName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Card ID: ${card.id} · Grade: ${card.mixGrade}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 8),

                  // Engineering Summary Block
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
                        const Text(
                          'Monolithic Structural Pour Specifications',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.technicalNotes,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildMiniSpec(
                              label: 'Total Volume',
                              value: '${card.targetVolumeM3} m³',
                              icon: Icons.layers_rounded,
                              color: AppTheme.primaryLight,
                            ),
                            const SizedBox(width: 20),
                            _buildMiniSpec(
                              label: 'W/C Ratio',
                              value: '${card.waterCementRatio}',
                              icon: Icons.water_drop_rounded,
                              color: AppTheme.secondary,
                            ),
                            const SizedBox(width: 20),
                            _buildMiniSpec(
                              label: 'Curing Days',
                              value: '${card.curingDaysCompleted} Days',
                              icon: Icons.timer_rounded,
                              color: AppTheme.tertiary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Digital Sign-Off / Verification Seal
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: AppTheme.tertiary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Cryptographic QA & TPIA Witness Seal',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lead QA/QC: ${card.leadQcEngineer}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        Text(
                          'FIDIC Cl. 3.1 / TPIA: ${card.tpiaWitnessLead}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SHA-256 Hash: 9f82ab47e6204c3291...38d2 (Immutable Audit Log)',
                          style: TextStyle(
                            color: AppTheme.textMuted.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Deliveries Associated
                  Text(
                    'Transit Mixer Batch Tickets (${card.tickets.length})',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...card.tickets.map(_buildBatchTicketCard),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQaDossierDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 20),
              SizedBox(width: 8),
              Text(
                'QA / QC Standards Compliance',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nirmaan OS Concrete Quality Assurance System adheres to the following statutory and contractual mandates:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
              ),
              SizedBox(height: 10),
              Text('• IS 456:2000 — Code of Practice for Plain & Reinforced Concrete', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
              Text('• IS 516:2021 — Hardened Concrete Compressive Strength Methods', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
              Text('• IS 1199:2018 — Fresh Concrete Slump & Consistency Sampling', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
              Text('• IS 10262:2019 — Concrete Mix Proportioning Guidelines', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
              Text('• FIDIC Red Book Cl. 7.3 — Inspection of Plant and Materials', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // UTILITY HELPERS
  // ============================================================================

  Color _getGradeColor(String grade) {
    if (grade.contains('25')) return const Color(0xFF38BDF8); // Sky blue
    if (grade.contains('35')) return const Color(0xFFFFB95F); // Amber
    if (grade.contains('40')) return const Color(0xFF4EDEA3); // Emerald
    return AppTheme.primary;
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
