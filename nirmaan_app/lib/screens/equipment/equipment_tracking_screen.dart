import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../providers/app_provider.dart';

/// Breakdown Category representation
enum BreakdownCategory {
  mechanical(
    'Mechanical',
    'Engine, Transmission, Gearbox & Boom Articulation',
    Icons.engineering_rounded,
    Color(0xFFF97316),
  ),
  hydraulic(
    'Hydraulic',
    'Main Cylinders, Hydro-pumps, High-Pressure Hoses & Valves',
    Icons.water_drop_rounded,
    Color(0xFF06B6D4),
  ),
  electrical(
    'Electrical',
    'Alternator, Battery Bank, ECU Sensors & Wiring Harness',
    Icons.bolt_rounded,
    Color(0xFFEAB308),
  ),
  fuel(
    'Fuel',
    'Injection Nozzles, Fuel Filters, Feed Pump & Fuel Tank',
    Icons.local_gas_station_rounded,
    Color(0xFFEF4444),
  );

  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const BreakdownCategory(this.label, this.description, this.icon, this.color);
}

/// Breakdown Severity Level
enum BreakdownSeverity {
  critical(
    'Critical Blocker',
    'Immediate halt on scheduled activity & CPM path',
    Color(0xFFEF4444),
  ),
  major(
    'Major Delay',
    'Severe capacity loss (>50% shift delay)',
    Color(0xFFF59E0B),
  ),
  moderate(
    'Moderate Delay',
    'Work proceeding with partial manual backup',
    Color(0xFF38BDF8),
  );

  final String label;
  final String description;
  final Color color;

  const BreakdownSeverity(this.label, this.description, this.color);
}

/// Pipeline Right-of-Way (RoW) Geo-Fence & Curfew Status
enum RoWGeofenceStatus {
  insideRoW(
    'Inside Sanctioned RoW',
    'Operating inside sanctioned 24m pipeline corridor',
    Icons.verified_user_rounded,
    Color(0xFF4EDEA3),
  ),
  boundaryWarning(
    'RoW Perimeter Warning',
    'Operating within 1.5m of corridor boundary (Outrigger proximity)',
    Icons.warning_amber_rounded,
    Color(0xFFFFB95F),
  ),
  rowBreach(
    'RoW Corridor Breach',
    'CRITICAL: Machine outside sanctioned pipeline RoW in private/forest land',
    Icons.wrong_location_rounded,
    Color(0xFFEF4444),
  ),
  curfewViolation(
    'Curfew Lockdown Breach',
    'Unauthorized operation past 19:30 night curfew window',
    Icons.nightlight_round,
    Color(0xFFF97316),
  );

  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const RoWGeofenceStatus(this.label, this.description, this.icon, this.color);
}

/// Record of an equipment breakdown incident
class MachineryBreakdownRecord {
  final String id;
  final String equipmentId;
  final String equipmentName;
  final BreakdownCategory category;
  final BreakdownSeverity severity;
  final String rootCause;
  final DateTime reportedAt;
  final String reportedBy;
  final double estimatedDowntimeHours;
  final String technicianAssigned;
  final String blockedActivityId;
  final String blockedActivityName;
  final bool blocksScheduleActivity;
  final double cpmDelayRiskDays;
  final String? resolutionNotes;
  final DateTime? resolvedAt;

  const MachineryBreakdownRecord({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.category,
    required this.severity,
    required this.rootCause,
    required this.reportedAt,
    required this.reportedBy,
    required this.estimatedDowntimeHours,
    required this.technicianAssigned,
    required this.blockedActivityId,
    required this.blockedActivityName,
    this.blocksScheduleActivity = true,
    this.cpmDelayRiskDays = 2.5,
    this.resolutionNotes,
    this.resolvedAt,
  });

  MachineryBreakdownRecord copyWith({
    String? resolutionNotes,
    DateTime? resolvedAt,
  }) {
    return MachineryBreakdownRecord(
      id: id,
      equipmentId: equipmentId,
      equipmentName: equipmentName,
      category: category,
      severity: severity,
      rootCause: rootCause,
      reportedAt: reportedAt,
      reportedBy: reportedBy,
      estimatedDowntimeHours: estimatedDowntimeHours,
      technicianAssigned: technicianAssigned,
      blockedActivityId: blockedActivityId,
      blockedActivityName: blockedActivityName,
      blocksScheduleActivity: blocksScheduleActivity,
      cpmDelayRiskDays: cpmDelayRiskDays,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

/// Real-time IoT telematics and sensor readings
class EquipmentTelemetry {
  final double engineTempC;
  final int fuelLevelPercent;
  final double fuelCurrentLiters;
  final double fuelTankCapacityLiters;
  final double dieselBurnRateLph;
  final double dieselRatedBurnRateLph;
  final double dieselShiftBurnedLiters;
  final int hydraulicPressureBar;
  final int hydraulicPressurePsi;
  final double batteryVoltage;
  final int oilPressurePsi;
  final double vibrationMmS;
  final int engineLoadPercent;
  final double idleHoursToday;
  final double workingHoursToday;
  final String gpsChainage;
  final double rowOffsetMeters;
  final double sanctionedRoWWidthM;
  final RoWGeofenceStatus geofenceStatus;
  final bool isCurfewViolation;
  final String? geofenceAlertDetail;
  final String curfewWindow;

  const EquipmentTelemetry({
    required this.engineTempC,
    required this.fuelLevelPercent,
    required this.fuelCurrentLiters,
    required this.fuelTankCapacityLiters,
    required this.dieselBurnRateLph,
    required this.dieselRatedBurnRateLph,
    required this.dieselShiftBurnedLiters,
    required this.hydraulicPressureBar,
    required this.hydraulicPressurePsi,
    required this.batteryVoltage,
    required this.oilPressurePsi,
    required this.vibrationMmS,
    required this.engineLoadPercent,
    required this.idleHoursToday,
    required this.workingHoursToday,
    required this.gpsChainage,
    required this.rowOffsetMeters,
    this.sanctionedRoWWidthM = 24.0,
    required this.geofenceStatus,
    this.isCurfewViolation = false,
    this.geofenceAlertDetail,
    this.curfewWindow = '19:30 - 05:30',
  });
}

/// Comprehensive Equipment Unit Model
class EquipmentUnit {
  final String id;
  final String shortTag;
  final String name;
  final String category;
  final String operator;
  final String operatorPhone;
  final EquipmentStatus status;
  final String location;
  final double operatingHoursTotal;
  final double hoursToday;
  final double targetShiftHours;
  final String maintenanceDue;
  final double nextServiceRemainingHours;
  final int nextServiceIntervalHours;
  final String nextServiceType;
  final int machineHealthScore;
  final String associatedActId;
  final String associatedActName;
  final bool isCriticalPath;
  final String criticalPathImpactText;
  final double cpmDelayRiskDays;
  final EquipmentTelemetry telemetry;
  final MachineryBreakdownRecord? activeBreakdown;
  final List<MachineryBreakdownRecord> breakdownHistory;

  const EquipmentUnit({
    required this.id,
    required this.shortTag,
    required this.name,
    required this.category,
    required this.operator,
    required this.operatorPhone,
    required this.status,
    required this.location,
    required this.operatingHoursTotal,
    required this.hoursToday,
    this.targetShiftHours = 10.0,
    required this.maintenanceDue,
    required this.nextServiceRemainingHours,
    required this.nextServiceIntervalHours,
    required this.nextServiceType,
    required this.machineHealthScore,
    required this.associatedActId,
    required this.associatedActName,
    this.isCriticalPath = false,
    required this.criticalPathImpactText,
    this.cpmDelayRiskDays = 0.0,
    required this.telemetry,
    this.activeBreakdown,
    this.breakdownHistory = const [],
  });

  /// Utilization efficiency percentage relative to target shift (10 hrs)
  double get utilizationEfficiency =>
      ((hoursToday / targetShiftHours) * 100).clamp(0.0, 100.0);

  bool get isBlocked =>
      activeBreakdown != null && activeBreakdown!.blocksScheduleActivity;

  bool get isServiceDueSoon =>
      nextServiceRemainingHours <= 40.0 && nextServiceRemainingHours > 0;

  bool get isServiceOverdue => nextServiceRemainingHours <= 0;

  bool get hasGeofenceAlert =>
      telemetry.geofenceStatus == RoWGeofenceStatus.rowBreach ||
      telemetry.geofenceStatus == RoWGeofenceStatus.curfewViolation;

  EquipmentUnit copyWith({
    String? id,
    String? shortTag,
    String? name,
    String? category,
    String? operator,
    String? operatorPhone,
    EquipmentStatus? status,
    String? location,
    double? operatingHoursTotal,
    double? hoursToday,
    double? targetShiftHours,
    String? maintenanceDue,
    double? nextServiceRemainingHours,
    int? nextServiceIntervalHours,
    String? nextServiceType,
    int? machineHealthScore,
    String? associatedActId,
    String? associatedActName,
    bool? isCriticalPath,
    String? criticalPathImpactText,
    double? cpmDelayRiskDays,
    EquipmentTelemetry? telemetry,
    MachineryBreakdownRecord? activeBreakdown,
    bool clearActiveBreakdown = false,
    List<MachineryBreakdownRecord>? breakdownHistory,
  }) {
    return EquipmentUnit(
      id: id ?? this.id,
      shortTag: shortTag ?? this.shortTag,
      name: name ?? this.name,
      category: category ?? this.category,
      operator: operator ?? this.operator,
      operatorPhone: operatorPhone ?? this.operatorPhone,
      status: status ?? this.status,
      location: location ?? this.location,
      operatingHoursTotal: operatingHoursTotal ?? this.operatingHoursTotal,
      hoursToday: hoursToday ?? this.hoursToday,
      targetShiftHours: targetShiftHours ?? this.targetShiftHours,
      maintenanceDue: maintenanceDue ?? this.maintenanceDue,
      nextServiceRemainingHours:
          nextServiceRemainingHours ?? this.nextServiceRemainingHours,
      nextServiceIntervalHours:
          nextServiceIntervalHours ?? this.nextServiceIntervalHours,
      nextServiceType: nextServiceType ?? this.nextServiceType,
      machineHealthScore: machineHealthScore ?? this.machineHealthScore,
      associatedActId: associatedActId ?? this.associatedActId,
      associatedActName: associatedActName ?? this.associatedActName,
      isCriticalPath: isCriticalPath ?? this.isCriticalPath,
      criticalPathImpactText:
          criticalPathImpactText ?? this.criticalPathImpactText,
      cpmDelayRiskDays: cpmDelayRiskDays ?? this.cpmDelayRiskDays,
      telemetry: telemetry ?? this.telemetry,
      activeBreakdown: clearActiveBreakdown
          ? null
          : (activeBreakdown ?? this.activeBreakdown),
      breakdownHistory: breakdownHistory ?? this.breakdownHistory,
    );
  }
}

class EquipmentTrackingScreen extends StatefulWidget {
  const EquipmentTrackingScreen({super.key});

  @override
  State<EquipmentTrackingScreen> createState() => _EquipmentTrackingScreenState();
}

class _EquipmentTrackingScreenState extends State<EquipmentTrackingScreen> {
  String _selectedFilter = 'ALL';
  String _searchQuery = '';
  final Set<String> _expandedEquipmentIds = {};
  int? _touchedChartGroupIndex;

  /// Active chart visualization mode: 'UTILIZATION' or 'FUEL_BURN'
  String _chartMode = 'UTILIZATION';

  /// Active fleet inventory
  late List<EquipmentUnit> _equipmentList;

  /// Blocked Schedule Activities Registry
  final Map<String, MachineryBreakdownRecord> _blockedScheduleActivities = {};

  @override
  void initState() {
    super.initState();
    _initializeFleet();
  }

  void _initializeFleet() {
    _equipmentList = [
      // 1. Heavy Side-Boom Crane (Signature Pipeline Machine with RoW Breach)
      const EquipmentUnit(
        id: 'EQ-SBOOM-01',
        shortTag: 'SBOOM-01',
        name: 'Caterpillar 572R2 Heavy Pipelayer (Side-Boom Crane)',
        category: 'Pipeline Lower-in & Spool Rigging (45T Capacity)',
        operator: 'Pradip Mech (Master Pipelayer Specialist)',
        operatorPhone: '+91 94352 88102',
        status: EquipmentStatus.running,
        location: 'Line 24 Trench Alignment (Chainage 14+820)',
        operatingHoursTotal: 2340.0,
        hoursToday: 8.2,
        targetShiftHours: 10.0,
        maintenanceDue: 'PM Kit in 16.5 hrs',
        nextServiceRemainingHours: 16.5,
        nextServiceIntervalHours: 250,
        nextServiceType: '250h Engine & Hydro-Return Filter Service',
        machineHealthScore: 87,
        associatedActId: 'PIP-L5-024',
        associatedActName: 'Pipe Lower-in & Downhill Welding',
        isCriticalPath: true,
        criticalPathImpactText:
            'Critical Path Lower-in: Stoppage halts pipe lowering and blocks downhill welding spread #2 (+3.2 days CPM risk).',
        cpmDelayRiskDays: 3.2,
        telemetry: EquipmentTelemetry(
          engineTempC: 89.0,
          fuelLevelPercent: 42,
          fuelCurrentLiters: 210.0,
          fuelTankCapacityLiters: 500.0,
          dieselBurnRateLph: 26.8,
          dieselRatedBurnRateLph: 22.0,
          dieselShiftBurnedLiters: 182.2,
          hydraulicPressureBar: 285,
          hydraulicPressurePsi: 4133,
          batteryVoltage: 24.4,
          oilPressurePsi: 54,
          vibrationMmS: 2.3,
          engineLoadPercent: 82,
          idleHoursToday: 1.4,
          workingHoursToday: 6.8,
          gpsChainage: 'Chainage 14+820 (Spread #2)',
          rowOffsetMeters: 28.5,
          sanctionedRoWWidthM: 24.0,
          geofenceStatus: RoWGeofenceStatus.rowBreach,
          isCurfewViolation: false,
          geofenceAlertDetail:
              'CORRIDOR BREACH: Side-boom crane drifted 28.5m from pipeline centerline (Limit: 12.0m). Encroaching onto un-acquired private tea estate. Landowner stop-work risk.',
        ),
      ),

      // 2. Heavy Hydraulic Excavator (Trenching Machine with Curfew Violation)
      const EquipmentUnit(
        id: 'EQ-EXCAV-07',
        shortTag: 'EXCAV-07',
        name: 'Komatsu PC210-10M0 Heavy Hydraulic Excavator',
        category: 'Trenching, Rock Breaking & Shoring',
        operator: 'M. Barman (Certified Trenching Operator)',
        operatorPhone: '+91 98540 77134',
        status: EquipmentStatus.running,
        location: 'Chainage 15+200 Eco-Buffer Zone',
        operatingHoursTotal: 1680.0,
        hoursToday: 9.4,
        targetShiftHours: 10.0,
        maintenanceDue: 'PM Kit in 28.0 hrs',
        nextServiceRemainingHours: 28.0,
        nextServiceIntervalHours: 500,
        nextServiceType: '500h Heavy Hydraulic Valve & Final Drive Oil',
        machineHealthScore: 91,
        associatedActId: 'ACT-3045',
        associatedActName: 'Trenching, Shoring & Dewatering',
        isCriticalPath: true,
        criticalPathImpactText:
            'Trenching precedes pipe stringing on CPM schedule. Direct blocker for line welding spread.',
        cpmDelayRiskDays: 2.4,
        telemetry: EquipmentTelemetry(
          engineTempC: 91.0,
          fuelLevelPercent: 58,
          fuelCurrentLiters: 232.0,
          fuelTankCapacityLiters: 400.0,
          dieselBurnRateLph: 22.4,
          dieselRatedBurnRateLph: 18.5,
          dieselShiftBurnedLiters: 176.0,
          hydraulicPressureBar: 295,
          hydraulicPressurePsi: 4278,
          batteryVoltage: 24.5,
          oilPressurePsi: 51,
          vibrationMmS: 2.9,
          engineLoadPercent: 88,
          idleHoursToday: 0.8,
          workingHoursToday: 8.6,
          gpsChainage: 'Chainage 15+200 Eco-Buffer',
          rowOffsetMeters: 6.2,
          sanctionedRoWWidthM: 24.0,
          geofenceStatus: RoWGeofenceStatus.curfewViolation,
          isCurfewViolation: true,
          geofenceAlertDetail:
              'CURFEW ALERT: Engine active at 21:40 inside Eco-Sensitive Wildlife Buffer Corridor (Sanctioned night curfew: 19:30 - 05:30). Environmental compliance fine risk.',
        ),
      ),

      // 3. Heavy Track-Type Dozer (Active Critical Breakdown)
      EquipmentUnit(
        id: 'EQ-DOZ-03',
        shortTag: 'DOZ-03',
        name: 'Caterpillar D6T Track-Type Dozer',
        category: 'ROW Grading & Access Road Clearing',
        operator: 'Sunil Gogoi (Heavy Earthmoving Plant Lead)',
        operatorPhone: '+91 94351 90234',
        status: EquipmentStatus.breakdown,
        location: 'Central Equipment Depot Workshop',
        operatingHoursTotal: 3410.0,
        hoursToday: 0.0,
        targetShiftHours: 10.0,
        maintenanceDue: 'Hydraulic Seal Overhaul Required',
        nextServiceRemainingHours: 0.0,
        nextServiceIntervalHours: 1000,
        nextServiceType: '1000h Major Pump & Undercarriage Overhaul',
        machineHealthScore: 38,
        associatedActId: 'ACT-2010',
        associatedActName: 'ROW Grading & Access Road Clearing',
        isCriticalPath: true,
        criticalPathImpactText:
            'CRITICAL PATH IMPACT: Heavy access road blocked; 40-foot pipe transport trailers halted. Critical CPM float consumed: -48 hrs.',
        cpmDelayRiskDays: 2.8,
        telemetry: EquipmentTelemetry(
          engineTempC: 32.0,
          fuelLevelPercent: 45,
          fuelCurrentLiters: 180.0,
          fuelTankCapacityLiters: 400.0,
          dieselBurnRateLph: 0.0,
          dieselRatedBurnRateLph: 24.0,
          dieselShiftBurnedLiters: 0.0,
          hydraulicPressureBar: 0,
          hydraulicPressurePsi: 0,
          batteryVoltage: 23.9,
          oilPressurePsi: 0,
          vibrationMmS: 0.0,
          engineLoadPercent: 0,
          idleHoursToday: 0.0,
          workingHoursToday: 0.0,
          gpsChainage: 'Workshop Bay 3 (Station Yard)',
          rowOffsetMeters: 0.0,
          sanctionedRoWWidthM: 24.0,
          geofenceStatus: RoWGeofenceStatus.insideRoW,
          isCurfewViolation: false,
        ),
        activeBreakdown: MachineryBreakdownRecord(
          id: 'BD-2026-081',
          equipmentId: 'EQ-DOZ-03',
          equipmentName: 'Caterpillar D6T Track-Type Dozer',
          category: BreakdownCategory.hydraulic,
          severity: BreakdownSeverity.critical,
          rootCause:
              'Main hydraulic pump seal rupture during heavy bench grading; fluid pressure dropped to 0 bar under load.',
          reportedAt: DateTime(2026, 9, 29, 14, 30),
          reportedBy: 'Er. Sunil Gogoi (Site Plant In-Charge)',
          estimatedDowntimeHours: 16.0,
          technicianAssigned: 'Tractors India Ltd (TIL CAT Service Team)',
          blockedActivityId: 'ACT-2010',
          blockedActivityName: 'ROW Grading & Access Road Clearing',
          blocksScheduleActivity: true,
          cpmDelayRiskDays: 2.8,
        ),
      ),

      // 4. Rough Terrain Crane (Approaching RoW Boundary Caution)
      const EquipmentUnit(
        id: 'EQ-CRANE-04',
        shortTag: 'CRANE-04',
        name: 'Tadano GR-500XL (50T Rough Terrain Crane)',
        category: 'Heavy Lifting · Spool Rigging',
        operator: 'Biren Chetia (Certified Heavy Operator)',
        operatorPhone: '+91 98640 12894',
        status: EquipmentStatus.running,
        location: 'Line 24 Trench Corridor (Chainage 14+350)',
        operatingHoursTotal: 1420.0,
        hoursToday: 6.4,
        targetShiftHours: 10.0,
        maintenanceDue: 'PM Kit in 82.0 hrs',
        nextServiceRemainingHours: 82.0,
        nextServiceIntervalHours: 1000,
        nextServiceType: '1000h Load-Sensing Winch & Wire Rope Inspection',
        machineHealthScore: 95,
        associatedActId: 'PIP-L5-024',
        associatedActName: 'Pipe Lower-in & Downhill Welding',
        isCriticalPath: true,
        criticalPathImpactText:
            'Rigging crane lifts 12m coated steel pipe spools into alignment before welding.',
        cpmDelayRiskDays: 1.8,
        telemetry: EquipmentTelemetry(
          engineTempC: 88.0,
          fuelLevelPercent: 78,
          fuelCurrentLiters: 312.0,
          fuelTankCapacityLiters: 400.0,
          dieselBurnRateLph: 16.8,
          dieselRatedBurnRateLph: 16.0,
          dieselShiftBurnedLiters: 98.4,
          hydraulicPressureBar: 240,
          hydraulicPressurePsi: 3480,
          batteryVoltage: 24.4,
          oilPressurePsi: 52,
          vibrationMmS: 2.1,
          engineLoadPercent: 68,
          idleHoursToday: 1.2,
          workingHoursToday: 5.2,
          gpsChainage: 'Chainage 14+350 Alignment',
          rowOffsetMeters: 11.2,
          sanctionedRoWWidthM: 24.0,
          geofenceStatus: RoWGeofenceStatus.boundaryWarning,
          isCurfewViolation: false,
          geofenceAlertDetail:
              'BOUNDARY PROXIMITY: Crane outrigger footprint at 11.2m offset from centerline (Permitted RoW boundary limit: 12.0m). Avoid extending counterweight beyond corridor.',
        ),
      ),

      // 5. Diesel Generator Set for Submerged-Arc / Downhill Welding Fleet
      const EquipmentUnit(
        id: 'EQ-WELD-GEN-02',
        shortTag: 'WELD-02',
        name: 'Lincoln Electric Dual Vantage 500 Diesel Gen',
        category: 'Orbital & Downhill Welding Spread',
        operator: 'Tapan Das Gang (Lead Pipeline Welder)',
        operatorPhone: '+91 97060 88219',
        status: EquipmentStatus.running,
        location: 'Line 24 Pipe Stringing Alignment',
        operatingHoursTotal: 2150.0,
        hoursToday: 8.8,
        targetShiftHours: 10.0,
        maintenanceDue: 'Filter swap in 24.0 hrs',
        nextServiceRemainingHours: 24.0,
        nextServiceIntervalHours: 250,
        nextServiceType: '250h Primary/Secondary Diesel Filter & Oil Swap',
        machineHealthScore: 89,
        associatedActId: 'PIP-L5-024',
        associatedActName: 'Pipe Lower-in & Downhill Welding',
        isCriticalPath: true,
        criticalPathImpactText:
            'Powers 4 Lincoln automatic welding arcs on mainline pipe joints. Essential for daily joint targets.',
        cpmDelayRiskDays: 2.1,
        telemetry: EquipmentTelemetry(
          engineTempC: 92.0,
          fuelLevelPercent: 34,
          fuelCurrentLiters: 68.0,
          fuelTankCapacityLiters: 200.0,
          dieselBurnRateLph: 9.8,
          dieselRatedBurnRateLph: 9.2,
          dieselShiftBurnedLiters: 82.5,
          hydraulicPressureBar: 0,
          hydraulicPressurePsi: 0,
          batteryVoltage: 24.2,
          oilPressurePsi: 55,
          vibrationMmS: 3.2,
          engineLoadPercent: 79,
          idleHoursToday: 0.8,
          workingHoursToday: 8.0,
          gpsChainage: 'Chainage 14+820 (Welding Station)',
          rowOffsetMeters: 3.2,
          sanctionedRoWWidthM: 24.0,
          geofenceStatus: RoWGeofenceStatus.insideRoW,
          isCurfewViolation: false,
        ),
      ),

      // 6. Concrete Boom Pump for Thrust Blocks & River Crossings
      const EquipmentUnit(
        id: 'EQ-PUMP-01',
        shortTag: 'PUMP-01',
        name: 'Schwing Stetter S36X Boom Pump',
        category: 'Concrete Pouring · Thrust Blocks & Viaducts',
        operator: 'D. Kalita (Concrete Plant Engineer)',
        operatorPhone: '+91 94350 44921',
        status: EquipmentStatus.standby,
        location: 'Central Batching Plant Assam Yard',
        operatingHoursTotal: 890.0,
        hoursToday: 2.1,
        targetShiftHours: 10.0,
        maintenanceDue: 'PM Kit in 320.0 hrs',
        nextServiceRemainingHours: 320.0,
        nextServiceIntervalHours: 500,
        nextServiceType: '500h Concrete Valve Pack & Pipeline Flushing',
        machineHealthScore: 98,
        associatedActId: 'ACT-3088',
        associatedActName: 'Anchor Block Foundation Concrete Pouring',
        isCriticalPath: false,
        criticalPathImpactText:
            'Pours heavy anti-buoyancy concrete saddle weights for wetland pipeline sections.',
        cpmDelayRiskDays: 0.0,
        telemetry: EquipmentTelemetry(
          engineTempC: 74.0,
          fuelLevelPercent: 92,
          fuelCurrentLiters: 276.0,
          fuelTankCapacityLiters: 300.0,
          dieselBurnRateLph: 5.5,
          dieselRatedBurnRateLph: 14.0,
          dieselShiftBurnedLiters: 14.2,
          hydraulicPressureBar: 180,
          hydraulicPressurePsi: 2610,
          batteryVoltage: 24.8,
          oilPressurePsi: 48,
          vibrationMmS: 1.4,
          engineLoadPercent: 32,
          idleHoursToday: 1.6,
          workingHoursToday: 0.5,
          gpsChainage: 'Batching Plant Yard',
          rowOffsetMeters: 0.0,
          sanctionedRoWWidthM: 24.0,
          geofenceStatus: RoWGeofenceStatus.insideRoW,
          isCurfewViolation: false,
        ),
      ),

      // 7. Heavy Spoil Tipper Truck
      const EquipmentUnit(
        id: 'EQ-DUMP-12',
        shortTag: 'DUMP-12',
        name: 'Tata Prima 2830.K Heavy Tipper (28T)',
        category: 'Muck & Spoil Haulage',
        operator: 'K. Roy (Senior Haulage Lead)',
        operatorPhone: '+91 99540 66201',
        status: EquipmentStatus.running,
        location: 'Disposal Pit #3 Corridor',
        operatingHoursTotal: 2890.0,
        hoursToday: 5.5,
        targetShiftHours: 10.0,
        maintenanceDue: 'PM Kit in 90.0 hrs',
        nextServiceRemainingHours: 90.0,
        nextServiceIntervalHours: 500,
        nextServiceType: '500h Brake Lining, Hub Greasing & Fuel Sump Swap',
        machineHealthScore: 84,
        associatedActId: 'ACT-3045',
        associatedActName: 'Trenching, Shoring & Dewatering',
        isCriticalPath: false,
        criticalPathImpactText:
            'Hauls excavated trench rock away from pipeline Right-of-Way.',
        cpmDelayRiskDays: 0.0,
        telemetry: EquipmentTelemetry(
          engineTempC: 90.0,
          fuelLevelPercent: 18,
          fuelCurrentLiters: 54.0,
          fuelTankCapacityLiters: 300.0,
          dieselBurnRateLph: 19.2,
          dieselRatedBurnRateLph: 17.5,
          dieselShiftBurnedLiters: 96.0,
          hydraulicPressureBar: 150,
          hydraulicPressurePsi: 2175,
          batteryVoltage: 24.1,
          oilPressurePsi: 46,
          vibrationMmS: 3.5,
          engineLoadPercent: 72,
          idleHoursToday: 1.1,
          workingHoursToday: 4.4,
          gpsChainage: 'Disposal Pit Gate #2',
          rowOffsetMeters: 8.5,
          sanctionedRoWWidthM: 24.0,
          geofenceStatus: RoWGeofenceStatus.insideRoW,
          isCurfewViolation: false,
        ),
      ),

      // 8. Deep Rotary Piling Rig for HDD River Crossing
      const EquipmentUnit(
        id: 'EQ-RIG-02',
        shortTag: 'RIG-02',
        name: 'Soilmec SR-65 Rotary Piling Rig',
        category: 'Deep Foundation Piling (HDD River Crossing)',
        operator: 'Anup Bordoloi (Master Piling Rig Specialist)',
        operatorPhone: '+91 94355 11982',
        status: EquipmentStatus.running,
        location: 'Bridge Pier P-14 (River Bank Corridor)',
        operatingHoursTotal: 1980.0,
        hoursToday: 8.2,
        targetShiftHours: 10.0,
        maintenanceDue: 'PM Kit in 210.0 hrs',
        nextServiceRemainingHours: 210.0,
        nextServiceIntervalHours: 500,
        nextServiceType: '500h Rotary Head Gearbox Fluid & Winch Seals',
        machineHealthScore: 96,
        associatedActId: 'ACT-1044',
        associatedActName: 'Deep Foundation Bored Piling (Pier P-14)',
        isCriticalPath: true,
        criticalPathImpactText:
            'Installs anchor piles for 1,200m Horizontal Directional Drilling (HDD) river pipeline crossing.',
        cpmDelayRiskDays: 4.0,
        telemetry: EquipmentTelemetry(
          engineTempC: 85.0,
          fuelLevelPercent: 71,
          fuelCurrentLiters: 355.0,
          fuelTankCapacityLiters: 500.0,
          dieselBurnRateLph: 32.5,
          dieselRatedBurnRateLph: 30.0,
          dieselShiftBurnedLiters: 245.0,
          hydraulicPressureBar: 310,
          hydraulicPressurePsi: 4496,
          batteryVoltage: 24.6,
          oilPressurePsi: 58,
          vibrationMmS: 4.1,
          engineLoadPercent: 92,
          idleHoursToday: 1.2,
          workingHoursToday: 7.0,
          gpsChainage: 'Pier P-14 Foundation Pad',
          rowOffsetMeters: 2.1,
          sanctionedRoWWidthM: 24.0,
          geofenceStatus: RoWGeofenceStatus.insideRoW,
          isCurfewViolation: false,
        ),
      ),
    ];

    // Seed blocked activities map with existing breakdown
    for (final unit in _equipmentList) {
      if (unit.activeBreakdown != null &&
          unit.activeBreakdown!.blocksScheduleActivity) {
        _blockedScheduleActivities[unit.associatedActId] =
            unit.activeBreakdown!;
      }
    }
  }

  // --- Breakdown Reporting Flow ---
  void _openReportBreakdownDialog({EquipmentUnit? preselected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _ReportBreakdownSheet(
          fleet: _equipmentList,
          preselectedUnit: preselected,
          onReportSubmitted: (record) {
            _handleBreakdownReported(record);
          },
        );
      },
    );
  }

  void _handleBreakdownReported(MachineryBreakdownRecord record) {
    setState(() {
      final index =
          _equipmentList.indexWhere((u) => u.id == record.equipmentId);
      if (index != -1) {
        final existing = _equipmentList[index];
        _equipmentList[index] = existing.copyWith(
          status: EquipmentStatus.breakdown,
          activeBreakdown: record,
        );
      }

      if (record.blocksScheduleActivity) {
        _blockedScheduleActivities[record.blockedActivityId] = record;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Breakdown Logged: ${record.equipmentId}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    record.blocksScheduleActivity
                        ? 'Activity [${record.blockedActivityId}] marked as BLOCKED on CPM Schedule.'
                        : 'Machinery flagged for urgent maintenance.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
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

  void _openResolveBreakdownDialog(EquipmentUnit unit) {
    final breakdown = unit.activeBreakdown;
    if (breakdown == null) return;

    final notesController = TextEditingController(
      text:
          'Component repaired by OEM field team. Hydraulic/electrical telemetry re-calibrated and load test verified.',
    );
    bool unblockActivity = breakdown.blocksScheduleActivity;
    EquipmentStatus postRepairStatus = EquipmentStatus.running;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.build_circle_outlined,
                        color: AppTheme.tertiary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resolve Breakdown',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          unit.id,
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                        border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                breakdown.category.label.toUpperCase(),
                                style: TextStyle(
                                  color: breakdown.category.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('·',
                                  style: TextStyle(color: AppTheme.textMuted)),
                              const SizedBox(width: 6),
                              Text(
                                breakdown.severity.label,
                                style: TextStyle(
                                  color: breakdown.severity.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            breakdown.rootCause,
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'POST-REPAIR STATUS',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(
                                () => postRepairStatus = EquipmentStatus.running),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: postRepairStatus == EquipmentStatus.running
                                    ? AppTheme.tertiary.withValues(alpha: 0.2)
                                    : AppTheme.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: postRepairStatus == EquipmentStatus.running
                                      ? AppTheme.tertiary
                                      : AppTheme.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'RUNNING',
                                  style: TextStyle(
                                    color: postRepairStatus == EquipmentStatus.running
                                        ? AppTheme.tertiary
                                        : AppTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(
                                () => postRepairStatus = EquipmentStatus.standby),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: postRepairStatus == EquipmentStatus.standby
                                    ? AppTheme.secondary.withValues(alpha: 0.2)
                                    : AppTheme.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: postRepairStatus == EquipmentStatus.standby
                                      ? AppTheme.secondary
                                      : AppTheme.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'STANDBY',
                                  style: TextStyle(
                                    color: postRepairStatus == EquipmentStatus.standby
                                        ? AppTheme.secondary
                                        : AppTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (breakdown.blocksScheduleActivity) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: unblockActivity,
                              activeColor: AppTheme.tertiary,
                              checkColor: Colors.black,
                              onChanged: (val) {
                                setDialogState(
                                    () => unblockActivity = val ?? true);
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unblock Activity: ${breakdown.blockedActivityId}',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Restore normal status on project critical path schedule',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary
                                          .withValues(alpha: 0.8),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    const Text(
                      'WORK ORDER / CLEARANCE NOTES',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'Enter maintenance clearance notes...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tertiary,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    final resolvedRecord = breakdown.copyWith(
                      resolutionNotes: notesController.text.trim(),
                      resolvedAt: DateTime.now(),
                    );

                    setState(() {
                      final idx =
                          _equipmentList.indexWhere((u) => u.id == unit.id);
                      if (idx != -1) {
                        final hist = List<MachineryBreakdownRecord>.from(
                            _equipmentList[idx].breakdownHistory)
                          ..add(resolvedRecord);

                        _equipmentList[idx] = _equipmentList[idx].copyWith(
                          status: postRepairStatus,
                          clearActiveBreakdown: true,
                          breakdownHistory: hist,
                        );
                      }

                      if (unblockActivity) {
                        _blockedScheduleActivities
                            .remove(breakdown.blockedActivityId);
                      }
                    });

                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.surfaceCard,
                        content: Text(
                          '${unit.id} restored to ${postRepairStatus.label}. '
                          '${unblockActivity ? "Activity ${breakdown.blockedActivityId} unblocked on CPM schedule." : ""}',
                          style: const TextStyle(color: AppTheme.tertiary),
                        ),
                      ),
                    );
                  },
                  child: const Text('Confirm Resolution & Unblock'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Geo-fence RoW Corridor & Curfew Inspection Dialog ---
  void _openGeofenceDetailsDialog(EquipmentUnit unit) {
    final telemetry = unit.telemetry;
    final isBreach = telemetry.geofenceStatus == RoWGeofenceStatus.rowBreach;
    final isCurfew = telemetry.geofenceStatus == RoWGeofenceStatus.curfewViolation;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isBreach
                  ? const Color(0xFFEF4444)
                  : (isCurfew ? const Color(0xFFF97316) : AppTheme.primaryLight),
              width: 1.4,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: telemetry.geofenceStatus.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  telemetry.geofenceStatus.icon,
                  color: telemetry.geofenceStatus.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      telemetry.geofenceStatus.label,
                      style: TextStyle(
                        color: telemetry.geofenceStatus.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${unit.shortTag} · ${unit.name}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Corridor offset callout
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pipeline Sanctioned RoW:',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11)),
                          Text(
                            '${telemetry.sanctionedRoWWidthM.toStringAsFixed(0)}m Width (±12m)',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Offset from Centerline:',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11)),
                          Text(
                            '${telemetry.rowOffsetMeters.toStringAsFixed(1)} m ${telemetry.rowOffsetMeters > 12.0 ? "(+${(telemetry.rowOffsetMeters - 12.0).toStringAsFixed(1)}m Outside)" : "(Inside)"}',
                            style: TextStyle(
                              color: telemetry.rowOffsetMeters > 12.0
                                  ? const Color(0xFFEF4444)
                                  : AppTheme.tertiary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Corridor Chainage Location:',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11)),
                          Text(
                            telemetry.gpsChainage,
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Site Curfew Hours Window:',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11)),
                          Text(
                            telemetry.curfewWindow,
                            style: TextStyle(
                              color: telemetry.isCurfewViolation
                                  ? const Color(0xFFF97316)
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Corridor Visual Cross-Section Diagram
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PIPELINE CORRIDOR CROSS-SECTION SCHEMATIC',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          // Base corridor band (24m sanctioned RoW)
                          Container(
                            height: 48,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppTheme.border.withValues(alpha: 0.6)),
                            ),
                          ),
                          // Sanctioned RoW Area (Center 60%)
                          Positioned(
                            left: 40,
                            right: 40,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                border: Border.symmetric(
                                  vertical: BorderSide(
                                    color: AppTheme.tertiary.withValues(alpha: 0.7),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'SANCTIONED ROW (24m)',
                                  style: TextStyle(
                                    color: AppTheme.tertiary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Centerline dash
                          const Positioned(
                            left: 0,
                            right: 0,
                            top: 23,
                            child: Divider(
                              color: AppTheme.primaryLight,
                              thickness: 1.2,
                              height: 1,
                            ),
                          ),
                          // Machine position marker
                          Positioned(
                            right: telemetry.rowOffsetMeters > 12.0 ? 8 : 90,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: telemetry.geofenceStatus.color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.circle,
                                      size: 8, color: Colors.black),
                                  const SizedBox(width: 4),
                                  Text(
                                    unit.shortTag,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Private Land (West)',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 8.5)),
                          Text('Centerline (0.0m)',
                              style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold)),
                          Text('Private Land (East)',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 8.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Alert details if any
                if (telemetry.geofenceAlertDetail != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: telemetry.geofenceStatus.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            telemetry.geofenceStatus.color.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      telemetry.geofenceAlertDetail!,
                      style: TextStyle(
                        color: telemetry.geofenceStatus.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Action choices
                const Text(
                  'ENFORCEMENT & SAFETY PROTOCOLS',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.power_settings_new_rounded,
                            size: 15),
                        label: const Text('CAN-bus Lockout',
                            style: TextStyle(fontSize: 10.5)),
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.surfaceCard,
                              content: Text(
                                'Engine Immobilizer Signal sent to ${unit.id} ECU via satellite IoT.',
                                style: const TextStyle(color: Color(0xFFEF4444)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.security_rounded, size: 15),
                        label: const Text('Dispatch Marshall',
                            style: TextStyle(fontSize: 10.5)),
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.surfaceCard,
                              content: Text(
                                'Pipeline RoW Security Marshall dispatched to ${unit.telemetry.gpsChainage}.',
                                style: const TextStyle(color: AppTheme.tertiary),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Dismiss',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        );
      },
    );
  }

  // --- Predictive Maintenance Booking Dialog ---
  void _openScheduleServiceDialog(EquipmentUnit unit) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.build_rounded,
                    color: AppTheme.secondary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schedule Predictive PM',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text('${unit.shortTag} · ${unit.name}',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
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
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Next Service Interval:',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 11)),
                        Text(
                          '${unit.nextServiceIntervalHours} Operating Hours',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Countdown Remaining:',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 11)),
                        Text(
                          unit.nextServiceRemainingHours <= 0
                              ? 'SERVICE OVERDUE (0.0h)'
                              : '${unit.nextServiceRemainingHours.toStringAsFixed(1)} hrs left',
                          style: TextStyle(
                            color: unit.nextServiceRemainingHours <= 20
                                ? const Color(0xFFEF4444)
                                : AppTheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Machine Health Index:',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 11)),
                        Text(
                          '${unit.machineHealthScore}% Nominal',
                          style: TextStyle(
                            color: unit.machineHealthScore >= 90
                                ? AppTheme.tertiary
                                : AppTheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kit Required: ${unit.nextServiceType}',
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Scheduling this service during the non-operational night window avoids blocking critical path activities on Gantt schedule.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.surfaceCard,
                    content: Text(
                      'PM Work Order logged for ${unit.id}. Spares dispatched from Central Stores.',
                      style: const TextStyle(color: AppTheme.secondary),
                    ),
                  ),
                );
              },
              child: const Text('Confirm PM Booking'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Merge activities from AppProvider if available
    final provider = context.watch<AppProvider>();
    final activeActivitiesCount = provider.activities.isNotEmpty
        ? provider.activities.length
        : 6;

    final filtered = _equipmentList.where((item) {
      if (_selectedFilter == 'RUNNING' &&
          item.status != EquipmentStatus.running) {
        return false;
      }
      if (_selectedFilter == 'STANDBY' &&
          item.status != EquipmentStatus.standby) {
        return false;
      }
      if (_selectedFilter == 'BREAKDOWN' &&
          item.status != EquipmentStatus.breakdown) {
        return false;
      }
      if (_selectedFilter == 'CRITICAL_PATH' && !item.isCriticalPath) {
        return false;
      }
      if (_selectedFilter == 'GEOFENCE_ALERT' && !item.hasGeofenceAlert) {
        return false;
      }
      if (_selectedFilter == 'SERVICE_DUE' &&
          !item.isServiceDueSoon &&
          !item.isServiceOverdue) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesId = item.id.toLowerCase().contains(q);
        final matchesName = item.name.toLowerCase().contains(q);
        final matchesOp = item.operator.toLowerCase().contains(q);
        final matchesAct = item.associatedActId.toLowerCase().contains(q);
        return matchesId || matchesName || matchesOp || matchesAct;
      }
      return true;
    }).toList();

    final runningCount =
        _equipmentList.where((e) => e.status == EquipmentStatus.running).length;
    final geofenceAlertCount =
        _equipmentList.where((e) => e.hasGeofenceAlert).length;
    final serviceDueCount = _equipmentList
        .where((e) => e.isServiceDueSoon || e.isServiceOverdue)
        .length;

    // Calculate fleet metrics
    final totalHours = _equipmentList.fold<double>(
        0.0, (sum, unit) => sum + unit.hoursToday);
    final totalTarget = _equipmentList.fold<double>(
        0.0, (sum, unit) => sum + unit.targetShiftHours);
    final fleetAvgEfficiency = totalTarget > 0
        ? (totalHours / totalTarget) * 100
        : 0.0;

    final totalBurnedLiters = _equipmentList.fold<double>(
        0.0, (sum, unit) => sum + unit.telemetry.dieselShiftBurnedLiters);
    final avgBurnRate = _equipmentList
            .where((u) => u.status == EquipmentStatus.running)
            .isNotEmpty
        ? (_equipmentList
                .where((u) => u.status == EquipmentStatus.running)
                .fold<double>(
                    0.0, (sum, u) => sum + u.telemetry.dieselBurnRateLph) /
            _equipmentList
                .where((u) => u.status == EquipmentStatus.running)
                .length)
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Fleet IoT Telemetry & Equipment Tracking'),
        actions: [
          if (geofenceAlertCount > 0)
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.wrong_location_rounded,
                      color: Color(0xFFEF4444)),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$geofenceAlertCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              tooltip: 'Pipeline RoW Geofence Violations',
              onPressed: () {
                setState(() => _selectedFilter = 'GEOFENCE_ALERT');
              },
            ),
          IconButton(
            icon: const Icon(Icons.add_alert_rounded, color: AppTheme.secondary),
            tooltip: 'Report Machinery Breakdown',
            onPressed: () => _openReportBreakdownDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh CAN-bus Telemetry Sync',
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fleet telemetry sync refreshed via CAN-bus & Sat-IoT link'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.warning_amber_rounded, size: 20),
        label: const Text('REPORT BREAKDOWN',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        onPressed: () => _openReportBreakdownDialog(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Prominent Geo-fence Curfew Alerts Banner
            if (geofenceAlertCount > 0) ...[
              _buildGeofenceAlertBanner(),
              const SizedBox(height: 16),
            ],

            // 2. Critical Schedule Blocker Warning Banner (If Any)
            if (_blockedScheduleActivities.isNotEmpty) ...[
              _buildCriticalBlockersBanner(),
              const SizedBox(height: 16),
            ],

            // 3. Top Fleet Overview KPI Metric Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Fleet Total',
                    '${_equipmentList.length} Units',
                    Icons.directions_bus_outlined,
                    AppTheme.primaryLight,
                    'Linked: $activeActivitiesCount tasks',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Operational',
                    '$runningCount Active',
                    Icons.play_circle_outline,
                    AppTheme.tertiary,
                    'Eff: ${fleetAvgEfficiency.toStringAsFixed(1)}%',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Diesel Rate',
                    '${avgBurnRate.toStringAsFixed(1)} L/h',
                    Icons.local_gas_station_rounded,
                    AppTheme.secondary,
                    'Shift: ${totalBurnedLiters.toStringAsFixed(0)}L',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'RoW Alerts',
                    '$geofenceAlertCount Breaches',
                    Icons.wrong_location_rounded,
                    geofenceAlertCount > 0
                        ? const Color(0xFFEF4444)
                        : AppTheme.textMuted,
                    'Curfew / RoW Out',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4. Dual-Mode Telemetry Bar Chart Card (Utilization vs Fuel Burn)
            _buildTelemetryBarChartCard(fleetAvgEfficiency, avgBurnRate),
            const SizedBox(height: 18),

            // 5. Search Bar & Filter Chips
            _buildSearchAndFilters(geofenceAlertCount, serviceDueCount),
            const SizedBox(height: 16),

            // 6. Equipment List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HEAVY MACHINERY TELEMATICS (${filtered.length})',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  'Standard shift: 10.0 hrs',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 7. Equipment Card List
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.filter_alt_off_outlined,
                        size: 36, color: AppTheme.textMuted),
                    SizedBox(height: 10),
                    Text(
                      'No equipment units match selected filter.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return _buildEquipmentCard(item);
                },
              ),

            const SizedBox(height: 64), // FAB spacing
          ],
        ),
      ),
    );
  }

  // --- Pipeline RoW Geo-Fence & Curfew Alert Top Banner ---
  Widget _buildGeofenceAlertBanner() {
    final alertUnits =
        _equipmentList.where((u) => u.hasGeofenceAlert).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.wrong_location_rounded,
                    color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PIPELINE ROW GEOFENCE & CURFEW ALERTS (${alertUnits.length})',
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Excavator / Side-boom operating outside sanctioned pipeline Right-of-Way (RoW) or during curfew.',
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
          const SizedBox(height: 10),
          ...alertUnits.map((u) {
            final isBreach =
                u.telemetry.geofenceStatus == RoWGeofenceStatus.rowBreach;
            return Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: u.telemetry.geofenceStatus.color
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      u.shortTag,
                      style: TextStyle(
                        color: u.telemetry.geofenceStatus.color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBreach
                              ? 'Outside RoW Corridor (+${u.telemetry.rowOffsetMeters.toStringAsFixed(1)}m from Centerline)'
                              : 'Night Curfew Breach (Permitted: ${u.telemetry.curfewWindow})',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${u.name} · ${u.telemetry.gpsChainage}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: u.telemetry.geofenceStatus.color,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _openGeofenceDetailsDialog(u),
                    child: const Text('GIS Action',
                        style: TextStyle(
                            fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Critical Schedule Blockers Alert Banner ---
  Widget _buildCriticalBlockersBanner() {
    final blockers = _blockedScheduleActivities.values.toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.block_rounded,
                    color: Color(0xFFEF4444), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CRITICAL PATH SCHEDULE BLOCKERS DETECTED (${blockers.length})',
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Machinery breakdowns are stalling P6 Gantt critical path activities.',
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
          const SizedBox(height: 10),
          ...blockers.map((b) {
            final equipment = _equipmentList.firstWhere(
              (e) => e.id == b.equipmentId,
              orElse: () => _equipmentList.first,
            );

            return Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                b.blockedActivityId,
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                b.blockedActivityName,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Blocked by ${b.equipmentId} (${b.category.label} · Est. ${b.estimatedDowntimeHours.toInt()}h downtime · +${b.cpmDelayRiskDays}d CPM delay)',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.tertiary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _openResolveBreakdownDialog(equipment),
                    child: const Text(
                      'Resolve & Unblock',
                      style: TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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

  // --- Metric Card ---
  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String caption,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 8.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- Dual-Mode Telemetry Bar Chart Card (Utilization vs Fuel Burn) ---
  Widget _buildTelemetryBarChartCard(
      double fleetAvgEfficiency, double avgBurnRate) {
    final isFuelMode = _chartMode == 'FUEL_BURN';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isFuelMode
                            ? Icons.local_gas_station_rounded
                            : Icons.bar_chart_rounded,
                        color: isFuelMode
                            ? AppTheme.secondary
                            : AppTheme.primaryLight,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFuelMode
                            ? 'Diesel Burn Rate Telemetry'
                            : 'Equipment Utilization Efficiency',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isFuelMode
                        ? 'Real-time Liters/Hour consumption vs 20.0 L/h benchmark'
                        : 'Operating hours vs 10.0h standard site operational shift target',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              // Segmented Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _chartMode = 'UTILIZATION'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: !isFuelMode
                              ? AppTheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Util %',
                          style: TextStyle(
                            color: !isFuelMode
                                ? Colors.white
                                : AppTheme.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _chartMode = 'FUEL_BURN'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isFuelMode
                              ? AppTheme.secondary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Fuel L/h',
                          style: TextStyle(
                            color: isFuelMode
                                ? Colors.black
                                : AppTheme.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Bar Chart
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: isFuelMode ? 40 : 100,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceContainerHigh,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (group.x < 0 || group.x >= _equipmentList.length) {
                        return null;
                      }
                      final unit = _equipmentList[group.x.toInt()];
                      final isBreakdown = unit.activeBreakdown != null;

                      if (isFuelMode) {
                        return BarTooltipItem(
                          '${unit.shortTag}\n',
                          const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'Burn Rate: ${unit.telemetry.dieselBurnRateLph.toStringAsFixed(1)} L/h\n',
                              style: const TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Shift Total: ${unit.telemetry.dieselShiftBurnedLiters.toStringAsFixed(0)} Liters\n',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Tank: ${unit.telemetry.fuelLevelPercent}% (${unit.telemetry.fuelCurrentLiters.toInt()}/${unit.telemetry.fuelTankCapacityLiters.toInt()}L)',
                              style: TextStyle(
                                color: unit.telemetry.fuelLevelPercent < 25
                                    ? const Color(0xFFEF4444)
                                    : AppTheme.tertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }

                      final efficiency = unit.utilizationEfficiency;
                      return BarTooltipItem(
                        '${unit.id}\n',
                        const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '${unit.name}\n',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          TextSpan(
                            text: isBreakdown
                                ? 'BREAKDOWN: 0.0 hrs (0%)\n'
                                : 'Runtime: ${unit.hoursToday.toStringAsFixed(1)} / ${unit.targetShiftHours.toStringAsFixed(0)}h (${efficiency.toStringAsFixed(0)}%)\n',
                            style: TextStyle(
                              color: isBreakdown
                                  ? const Color(0xFFEF4444)
                                  : (efficiency >= 80
                                      ? AppTheme.tertiary
                                      : (efficiency >= 50
                                          ? AppTheme.primaryLight
                                          : AppTheme.secondary)),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: isBreakdown
                                ? 'BLOCKED: ${unit.associatedActId}'
                                : 'Linked: ${unit.associatedActId}',
                            style: TextStyle(
                              color: isBreakdown
                                  ? const Color(0xFFEF4444)
                                  : AppTheme.primaryLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent && response != null) {
                      setState(() {
                        _touchedChartGroupIndex =
                            response.spot?.touchedBarGroupIndex;
                      });
                    }
                  },
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: isFuelMode ? 10 : 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.border.withValues(alpha: 0.5),
                    strokeWidth: 0.8,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.border, width: 0.8),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: isFuelMode ? 20.0 : 80.0,
                      color: AppTheme.secondary,
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 6, bottom: 2),
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                        labelResolver: (line) => isFuelMode
                            ? '20.0 L/h Benchmark'
                            : '80% Shift Target',
                      ),
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: isFuelMode ? 10 : 25,
                      getTitlesWidget: (value, meta) {
                        if (value > (isFuelMode ? 40 : 100) || value < 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Text(
                            isFuelMode
                                ? '${value.toInt()}L'
                                : '${value.toInt()}%',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _equipmentList.length) {
                          return const SizedBox.shrink();
                        }
                        final unit = _equipmentList[index];
                        final isBreakdown = unit.activeBreakdown != null;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            unit.shortTag,
                            style: TextStyle(
                              color: isBreakdown
                                  ? const Color(0xFFEF4444)
                                  : AppTheme.textSecondary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: _equipmentList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final unit = entry.value;
                  final isBreakdown = unit.activeBreakdown != null;

                  List<Color> gradientColors;
                  double barValue;

                  if (isFuelMode) {
                    barValue = unit.telemetry.dieselBurnRateLph;
                    if (isBreakdown) {
                      gradientColors = [
                        Colors.red.shade900,
                        const Color(0xFFEF4444),
                      ];
                    } else if (barValue > 25.0) {
                      gradientColors = [
                        const Color(0xFFD97706),
                        const Color(0xFFF97316),
                      ];
                    } else {
                      gradientColors = [
                        const Color(0xFF0284C7),
                        AppTheme.primaryLight,
                      ];
                    }
                  } else {
                    final eff = unit.utilizationEfficiency;
                    barValue = isBreakdown ? 4.0 : eff;
                    if (isBreakdown) {
                      gradientColors = [
                        Colors.red.shade900,
                        const Color(0xFFEF4444),
                      ];
                    } else if (eff >= 80) {
                      gradientColors = [
                        const Color(0xFF059669),
                        AppTheme.tertiary,
                      ];
                    } else if (eff >= 50) {
                      gradientColors = [
                        AppTheme.primary,
                        AppTheme.primaryLight,
                      ];
                    } else {
                      gradientColors = [
                        const Color(0xFFD97706),
                        AppTheme.secondary,
                      ];
                    }
                  }

                  final isSelected = _touchedChartGroupIndex == index;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: barValue,
                        width: isSelected ? 22 : 18,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5),
                        ),
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: isFuelMode ? 40 : 100,
                          color: AppTheme.surfaceContainerHigh
                              .withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Chart Legend
          if (isFuelMode) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildChartLegendItem(
                    AppTheme.primaryLight, 'Optimal (<25 L/h)'),
                _buildChartLegendItem(
                    const Color(0xFFF97316), 'High Load (>25 L/h)'),
                _buildChartLegendItem(
                    const Color(0xFFEF4444), 'Breakdown (0 L/h)'),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildChartLegendItem(
                    AppTheme.tertiary, 'Target Met (≥80%)'),
                _buildChartLegendItem(
                    AppTheme.primaryLight, 'Optimal (50-79%)'),
                _buildChartLegendItem(
                    AppTheme.secondary, 'Low (<50%)'),
                _buildChartLegendItem(
                    const Color(0xFFEF4444), 'Breakdown (0%)'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(Color color, String label) {
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
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // --- Search & Filter Controls ---
  Widget _buildSearchAndFilters(int geofenceCount, int serviceCount) {
    return Column(
      children: [
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search equipment ID, operator, activity code...',
            prefixIcon:
                const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear,
                        size: 18, color: AppTheme.textMuted),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL', 'All Units (${_equipmentList.length})'),
              const SizedBox(width: 8),
              _buildFilterChip('RUNNING', 'Running'),
              const SizedBox(width: 8),
              _buildFilterChip('STANDBY', 'Standby'),
              const SizedBox(width: 8),
              _buildFilterChip('BREAKDOWN', 'Breakdowns'),
              const SizedBox(width: 8),
              _buildFilterChip('CRITICAL_PATH', 'CPM Critical'),
              const SizedBox(width: 8),
              _buildFilterChip(
                'GEOFENCE_ALERT',
                'RoW Alerts ($geofenceCount)',
                highlightColor: geofenceCount > 0 ? const Color(0xFFEF4444) : null,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'SERVICE_DUE',
                'PM Due ($serviceCount)',
                highlightColor: serviceCount > 0 ? AppTheme.secondary : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? highlightColor}) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (highlightColor ?? AppTheme.primary)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (highlightColor ?? AppTheme.primaryLight)
                : (highlightColor?.withValues(alpha: 0.6) ?? AppTheme.border),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (highlightColor ?? AppTheme.textSecondary),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // --- Equipment Unit Card ---
  Widget _buildEquipmentCard(EquipmentUnit item) {
    final isBreakdown = item.activeBreakdown != null;
    Color statusColor;
    switch (item.status) {
      case EquipmentStatus.running:
        statusColor = AppTheme.tertiary;
        break;
      case EquipmentStatus.standby:
        statusColor = AppTheme.secondary;
        break;
      case EquipmentStatus.breakdown:
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusColor = AppTheme.textMuted;
    }

    final int fuel = item.telemetry.fuelLevelPercent;
    final Color fuelColor = fuel < 25
        ? const Color(0xFFEF4444)
        : (fuel < 50 ? AppTheme.secondary : AppTheme.tertiary);

    final bool isExpanded = _expandedEquipmentIds.contains(item.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBreakdown
              ? const Color(0xFFEF4444).withValues(alpha: 0.8)
              : (item.hasGeofenceAlert
                  ? item.telemetry.geofenceStatus.color.withValues(alpha: 0.7)
                  : AppTheme.border),
          width: (isBreakdown || item.hasGeofenceAlert) ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag, Status & Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      item.id,
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (item.isCriticalPath) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.timeline_rounded,
                              size: 11, color: AppTheme.secondary),
                          SizedBox(width: 3),
                          Text(
                            'CPM CRITICAL',
                            style: TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (item.hasGeofenceAlert) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.telemetry.geofenceStatus.color
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: item.telemetry.geofenceStatus.color
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(item.telemetry.geofenceStatus.icon,
                              size: 11,
                              color: item.telemetry.geofenceStatus.color),
                          const SizedBox(width: 4),
                          Text(
                            item.telemetry.geofenceStatus ==
                                    RoWGeofenceStatus.rowBreach
                                ? 'RoW BREACH'
                                : 'CURFEW ALERT',
                            style: TextStyle(
                              color: item.telemetry.geofenceStatus.color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      item.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Equipment Name & Category
          Text(
            item.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.category,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 10),

          // Operator & Location Row
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${item.operator} (${item.operatorPhone})',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.place_outlined,
                  size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${item.location} · ${item.telemetry.gpsChainage}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Geo-fence & Pipeline Corridor Status Bar
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: item.telemetry.geofenceStatus.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    item.telemetry.geofenceStatus.color.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(item.telemetry.geofenceStatus.icon,
                    size: 15, color: item.telemetry.geofenceStatus.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.telemetry.geofenceStatus.label.toUpperCase(),
                        style: TextStyle(
                          color: item.telemetry.geofenceStatus.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        'Offset: ${item.telemetry.rowOffsetMeters.toStringAsFixed(1)}m from Centerline (24m RoW Limit: ±12m) · Curfew: ${item.telemetry.curfewWindow}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 9.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _openGeofenceDetailsDialog(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Text(
                      'GIS View',
                      style: TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Breakdown Card Callout with CPM Impact
          if (isBreakdown && item.activeBreakdown != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                    width: 1.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(item.activeBreakdown!.category.icon,
                              size: 14,
                              color: item.activeBreakdown!.category.color),
                          const SizedBox(width: 6),
                          Text(
                            'BREAKDOWN: ${item.activeBreakdown!.category.label.toUpperCase()}',
                            style: TextStyle(
                              color: item.activeBreakdown!.category.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.activeBreakdown!.severity.label,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.activeBreakdown!.rootCause,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item.activeBreakdown!.blocksScheduleActivity) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.block_rounded,
                                  size: 13, color: Color(0xFFEF4444)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'SCHEDULE BLOCKED: ${item.activeBreakdown!.blockedActivityId} (${item.activeBreakdown!.blockedActivityName})',
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Critical Path Delay Risk: +${item.activeBreakdown!.cpmDelayRiskDays} Days to Milestone · CPM Float Consumed',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assigned: ${item.activeBreakdown!.technicianAssigned}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        'Est. Downtime: ${item.activeBreakdown!.estimatedDowntimeHours.toInt()} hrs',
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tertiary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text(
                        'Resolve Breakdown & Unblock Activity',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _openResolveBreakdownDialog(item),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(color: AppTheme.border, height: 18),

          // IoT Telematics 4-Core Metric Gauges Grid
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Metric 1: Engine Run Hours
                    Expanded(
                      child: _buildTelemetryMetricBox(
                        'Engine Run Hours',
                        '${item.hoursToday.toStringAsFixed(1)} / ${item.targetShiftHours.toStringAsFixed(0)}h',
                        'Total: ${item.operatingHoursTotal.toInt()} hrs',
                        Icons.timer_outlined,
                        item.utilizationEfficiency >= 80
                            ? AppTheme.tertiary
                            : (item.utilizationEfficiency >= 50
                                ? AppTheme.primaryLight
                                : AppTheme.secondary),
                        caption:
                            'Active: ${item.telemetry.workingHoursToday}h · Idle: ${item.telemetry.idleHoursToday}h',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Metric 2: Diesel Burn Rate (L/Hour)
                    Expanded(
                      child: _buildTelemetryMetricBox(
                        'Diesel Burn Rate',
                        '${item.telemetry.dieselBurnRateLph.toStringAsFixed(1)} L/h',
                        'Shift: ${item.telemetry.dieselShiftBurnedLiters.toInt()} Liters',
                        Icons.local_gas_station_rounded,
                        item.telemetry.dieselBurnRateLph > 25.0
                            ? const Color(0xFFF97316)
                            : AppTheme.secondary,
                        caption:
                            'Rated: ${item.telemetry.dieselRatedBurnRateLph} L/h · Tank: $fuel%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Metric 3: Hydraulic Oil Pressure
                    Expanded(
                      child: _buildTelemetryMetricBox(
                        'Hydraulic Pressure',
                        '${item.telemetry.hydraulicPressureBar} bar',
                        '${item.telemetry.hydraulicPressurePsi} PSI',
                        Icons.speed_rounded,
                        item.telemetry.hydraulicPressureBar == 0
                            ? const Color(0xFFEF4444)
                            : (item.telemetry.hydraulicPressureBar > 200
                                ? AppTheme.tertiary
                                : AppTheme.primaryLight),
                        caption: item.telemetry.hydraulicPressureBar == 0
                            ? 'ZERO PRESSURE / BURST'
                            : 'Optimal Range 200-320 bar',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Metric 4: Engine Coolant Temp
                    Expanded(
                      child: _buildTelemetryMetricBox(
                        'Engine Coolant Temp',
                        '${item.telemetry.engineTempC.toStringAsFixed(0)}°C',
                        '${((item.telemetry.engineTempC * 9 / 5) + 32).toInt()}°F',
                        Icons.thermostat_rounded,
                        item.telemetry.engineTempC > 95
                            ? const Color(0xFFEF4444)
                            : (item.telemetry.engineTempC > 90
                                ? AppTheme.secondary
                                : AppTheme.tertiary),
                        caption: item.telemetry.engineTempC > 95
                            ? 'OVERHEAT WARNING'
                            : 'Nominal Band 75-92°C',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Fuel Level Indicator
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Diesel Tank: ${item.telemetry.fuelCurrentLiters.toInt()} / ${item.telemetry.fuelTankCapacityLiters.toInt()} L',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 10),
                        ),
                        Text('$fuel%',
                            style: TextStyle(
                                color: fuelColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: fuel / 100,
                      backgroundColor: AppTheme.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(fuelColor),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Predictive Maintenance Countdown Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: item.isServiceOverdue
                    ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                    : (item.isServiceDueSoon
                        ? AppTheme.secondary.withValues(alpha: 0.5)
                        : AppTheme.border),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.build_circle_outlined,
                  size: 16,
                  color: item.isServiceOverdue
                      ? const Color(0xFFEF4444)
                      : (item.isServiceDueSoon
                          ? AppTheme.secondary
                          : AppTheme.tertiary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.isServiceOverdue
                                ? 'SERVICE OVERDUE (0.0h)'
                                : 'Next PM in ${item.nextServiceRemainingHours.toStringAsFixed(1)} operating hrs',
                            style: TextStyle(
                              color: item.isServiceOverdue
                                  ? const Color(0xFFEF4444)
                                  : (item.isServiceDueSoon
                                      ? AppTheme.secondary
                                      : AppTheme.textPrimary),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Health: ${item.machineHealthScore}%',
                            style: TextStyle(
                              color: item.machineHealthScore >= 90
                                  ? AppTheme.tertiary
                                  : AppTheme.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.nextServiceType,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _openScheduleServiceDialog(item),
                  child: const Text('Book PM',
                      style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Expandable Telemetry Diagnostics
          if (isExpanded) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXTENDED CAN-BUS SENSOR TELEMETRY & ECU BUS',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDiagnosticItem(
                        'Battery Bank',
                        '${item.telemetry.batteryVoltage} V',
                        item.telemetry.batteryVoltage < 24.0
                            ? AppTheme.secondary
                            : AppTheme.tertiary,
                      ),
                      _buildDiagnosticItem(
                        'Oil Pressure',
                        '${item.telemetry.oilPressurePsi} PSI',
                        item.telemetry.oilPressurePsi < 30
                            ? const Color(0xFFEF4444)
                            : AppTheme.textPrimary,
                      ),
                      _buildDiagnosticItem(
                        'Vibration (ISO)',
                        '${item.telemetry.vibrationMmS} mm/s',
                        item.telemetry.vibrationMmS > 3.0
                            ? AppTheme.secondary
                            : AppTheme.tertiary,
                      ),
                      _buildDiagnosticItem(
                        'Engine Load',
                        '${item.telemetry.engineLoadPercent}%',
                        item.telemetry.engineLoadPercent > 85
                            ? const Color(0xFFF97316)
                            : AppTheme.primaryLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GPS Chainage: ${item.telemetry.gpsChainage}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9.5,
                        ),
                      ),
                      Text(
                        'RoW Offset: ${item.telemetry.rowOffsetMeters.toStringAsFixed(1)}m',
                        style: TextStyle(
                          color: item.telemetry.rowOffsetMeters > 12.0
                              ? const Color(0xFFEF4444)
                              : AppTheme.tertiary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          // Action Buttons: Expand Telemetry & Report Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppTheme.primaryLight,
                ),
                label: Text(
                  isExpanded ? 'Hide Telemetry' : 'ECU Diagnostics Telemetry',
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedEquipmentIds.remove(item.id);
                    } else {
                      _expandedEquipmentIds.add(item.id);
                    }
                  });
                },
              ),
              if (!isBreakdown)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: BorderSide(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.report_problem_outlined,
                      size: 13, color: Color(0xFFEF4444)),
                  label: const Text(
                    'Report Breakdown',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () =>
                      _openReportBreakdownDialog(preselected: item),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryMetricBox(
    String title,
    String value,
    String subValue,
    IconData icon,
    Color color, {
    required String caption,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              Text(
                subValue,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 8.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Report Machinery Breakdown Interactive Modal Sheet
class _ReportBreakdownSheet extends StatefulWidget {
  final List<EquipmentUnit> fleet;
  final EquipmentUnit? preselectedUnit;
  final ValueChanged<MachineryBreakdownRecord> onReportSubmitted;

  const _ReportBreakdownSheet({
    required this.fleet,
    this.preselectedUnit,
    required this.onReportSubmitted,
  });

  @override
  State<_ReportBreakdownSheet> createState() => _ReportBreakdownSheetState();
}

class _ReportBreakdownSheetState extends State<_ReportBreakdownSheet> {
  late String _selectedEquipmentId;
  BreakdownCategory _selectedCategory = BreakdownCategory.hydraulic;
  BreakdownSeverity _selectedSeverity = BreakdownSeverity.critical;
  bool _markActivityBlocked = true;
  double _estimatedDowntimeHours = 12.0;
  double _cpmDelayRiskDays = 2.5;
  final TextEditingController _rootCauseController = TextEditingController();
  final TextEditingController _technicianController = TextEditingController(
    text: 'Site Heavy Mechanical Response Gang (Er. P. Saikia)',
  );

  @override
  void initState() {
    super.initState();
    _selectedEquipmentId = widget.preselectedUnit?.id ??
        (widget.fleet.isNotEmpty ? widget.fleet.first.id : '');
    _prefillSymptomSuggestions();
  }

  void _prefillSymptomSuggestions() {
    _rootCauseController.text = _getDefaultSymptomFor(_selectedCategory);
  }

  String _getDefaultSymptomFor(BreakdownCategory cat) {
    switch (cat) {
      case BreakdownCategory.mechanical:
        return 'Transmission slip and heavy boom articulation pin grinding noise under payload.';
      case BreakdownCategory.hydraulic:
        return 'High-pressure hydraulic boom extension hose ruptured; pressure gauge dropped to zero.';
      case BreakdownCategory.electrical:
        return 'Alternator charging circuit failure and ECU fault alarm with starter lockout.';
      case BreakdownCategory.fuel:
        return 'Fuel injection rail starvation; primary and secondary diesel filters heavily choked.';
    }
  }

  List<String> _getQuickChipsFor(BreakdownCategory cat) {
    switch (cat) {
      case BreakdownCategory.mechanical:
        return [
          'Transmission Slippage',
          'Boom Pin Crack',
          'Track Derailment',
          'Engine Overheating',
        ];
      case BreakdownCategory.hydraulic:
        return [
          'Hose Puncture',
          'Main Pump Failure',
          'Cylinder Seal Leak',
          'Pressure Valve Stuck',
        ];
      case BreakdownCategory.electrical:
        return [
          'Alternator Short',
          'ECU Canbus Alarm',
          'Starter Solenoid Burnout',
          'Sensor Bus Drift',
        ];
      case BreakdownCategory.fuel:
        return [
          'Filter Waxing / Choke',
          'Diesel Contamination',
          'Injection Nozzle Clog',
          'Fuel Line Air-lock',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedUnit = widget.fleet.firstWhere(
      (e) => e.id == _selectedEquipmentId,
      orElse: () => widget.fleet.first,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(
        top: 14,
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Machinery Breakdown',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Plant Incident Registry & Critical Path Schedule Impact',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: AppTheme.border, height: 22),

          // Scrollable Form Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Select Equipment Unit
                  const Text(
                    '1. SELECT MACHINERY UNIT *',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceCard,
                        value: _selectedEquipmentId,
                        items: widget.fleet.map((unit) {
                          return DropdownMenuItem<String>(
                            value: unit.id,
                            child: Row(
                              children: [
                                Text(
                                  unit.shortTag,
                                  style: const TextStyle(
                                    color: AppTheme.primaryLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    unit.name,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newId) {
                          if (newId != null) {
                            setState(() => _selectedEquipmentId = newId);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Location: ${selectedUnit.location} · Chainage: ${selectedUnit.telemetry.gpsChainage}',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10.5),
                  ),
                  const SizedBox(height: 18),

                  // Step 2: Select Breakdown Category
                  const Text(
                    '2. BREAKDOWN CATEGORY *',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.1,
                    children: BreakdownCategory.values.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                            _rootCauseController.text =
                                _getDefaultSymptomFor(cat);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color.withValues(alpha: 0.2)
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? cat.color : AppTheme.border,
                              width: isSelected ? 1.6 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(cat.icon, color: cat.color, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      cat.label,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      cat.description,
                                      style: TextStyle(
                                        color: isSelected
                                            ? cat.color
                                            : AppTheme.textMuted,
                                        fontSize: 9,
                                      ),
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
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Step 3: Associated Schedule Activity Blocker
                  const Text(
                    '3. CRITICAL PATH SCHEDULE IMPACT *',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _markActivityBlocked
                          ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _markActivityBlocked
                            ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                            : AppTheme.border,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _markActivityBlocked,
                              activeColor: const Color(0xFFEF4444),
                              onChanged: (val) {
                                setState(
                                    () => _markActivityBlocked = val ?? true);
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mark Linked Schedule Activity as BLOCKED',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  Text(
                                    'Flags Gantt schedule & generates Critical Path slippage risk',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary
                                          .withValues(alpha: 0.8),
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppTheme.border, height: 14),
                        Row(
                          children: [
                            const Text(
                              'Linked Activity: ',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                selectedUnit.associatedActId,
                                style: const TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedUnit.associatedActName,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (_markActivityBlocked) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('CPM Schedule Delay Risk:',
                                  style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 10.5)),
                              Text(
                                '+${_cpmDelayRiskDays.toStringAsFixed(1)} Days Delay',
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _cpmDelayRiskDays,
                            min: 0.5,
                            max: 10.0,
                            divisions: 19,
                            activeColor: const Color(0xFFEF4444),
                            inactiveColor: AppTheme.surface,
                            onChanged: (val) {
                              setState(() => _cpmDelayRiskDays = val);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Step 4: Root Cause & Failure Symptoms
                  const Text(
                    '4. ROOT CAUSE & SENSOR ALARM NOTES *',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _getQuickChipsFor(_selectedCategory).map((chip) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0, bottom: 6),
                          child: ActionChip(
                            backgroundColor: AppTheme.surface,
                            side: const BorderSide(color: AppTheme.border),
                            label: Text(
                              chip,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10.5,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                if (_rootCauseController.text.isEmpty) {
                                  _rootCauseController.text = chip;
                                } else {
                                  _rootCauseController.text += ' · $chip';
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _rootCauseController,
                    maxLines: 3,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 12.5),
                    decoration: const InputDecoration(
                      hintText:
                          'Describe breakdown diagnosis, mechanical sounds, sensor alarms...',
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Step 5: Severity & Downtime Estimate
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SEVERITY LEVEL',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<BreakdownSeverity>(
                                  isExpanded: true,
                                  dropdownColor: AppTheme.surfaceCard,
                                  value: _selectedSeverity,
                                  items: BreakdownSeverity.values.map((s) {
                                    return DropdownMenuItem<BreakdownSeverity>(
                                      value: s,
                                      child: Text(
                                        s.label,
                                        style: TextStyle(
                                          color: s.color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedSeverity = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EST. DOWNTIME: ${_estimatedDowntimeHours.toInt()} HRS',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: _estimatedDowntimeHours,
                              min: 2,
                              max: 48,
                              divisions: 23,
                              activeColor: AppTheme.secondary,
                              inactiveColor: AppTheme.surface,
                              onChanged: (val) {
                                setState(() => _estimatedDowntimeHours = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Technician Assigned
                  const Text(
                    'ASSIGNED MAINTENANCE / OEM TEAM',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _technicianController,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Enter maintenance crew or technician name...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.report_problem_rounded, size: 20),
                      label: Text(
                        _markActivityBlocked
                            ? 'LOG BREAKDOWN & BLOCK CPM SCHEDULE'
                            : 'LOG BREAKDOWN INCIDENT',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: () {
                        final record = MachineryBreakdownRecord(
                          id: 'BD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                          equipmentId: selectedUnit.id,
                          equipmentName: selectedUnit.name,
                          category: _selectedCategory,
                          severity: _selectedSeverity,
                          rootCause: _rootCauseController.text.trim().isEmpty
                              ? _getDefaultSymptomFor(_selectedCategory)
                              : _rootCauseController.text.trim(),
                          reportedAt: DateTime.now(),
                          reportedBy:
                              'Site Plant Engineer (${selectedUnit.operator})',
                          estimatedDowntimeHours: _estimatedDowntimeHours,
                          technicianAssigned:
                              _technicianController.text.trim(),
                          blockedActivityId: selectedUnit.associatedActId,
                          blockedActivityName: selectedUnit.associatedActName,
                          blocksScheduleActivity: _markActivityBlocked,
                          cpmDelayRiskDays: _cpmDelayRiskDays,
                        );

                        widget.onReportSubmitted(record);
                        Navigator.pop(context);
                      },
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
}
