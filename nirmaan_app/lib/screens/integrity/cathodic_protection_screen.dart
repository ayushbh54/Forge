import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// ENUMS & DATA MODELS
// ============================================================================

enum CpComplianceStatus {
  compliant,
  underProtected,
  overProtected,
  acInterferenceAlert,
}

extension CpComplianceStatusExt on CpComplianceStatus {
  String get label {
    switch (this) {
      case CpComplianceStatus.compliant:
        return 'NACE Compliant';
      case CpComplianceStatus.underProtected:
        return 'Under-Protected (< -850mV)';
      case CpComplianceStatus.overProtected:
        return 'Over-Protected (> -1200mV)';
      case CpComplianceStatus.acInterferenceAlert:
        return 'AC Interference Alert';
    }
  }

  Color get color {
    switch (this) {
      case CpComplianceStatus.compliant:
        return const Color(0xFF4EDEA3); // Tertiary green
      case CpComplianceStatus.underProtected:
        return const Color(0xFFEF4444); // Danger red
      case CpComplianceStatus.overProtected:
        return const Color(0xFFFFB95F); // Amber warning
      case CpComplianceStatus.acInterferenceAlert:
        return const Color(0xFFF43F5E); // High-alert rose
    }
  }

  IconData get icon {
    switch (this) {
      case CpComplianceStatus.compliant:
        return Icons.verified_user_rounded;
      case CpComplianceStatus.underProtected:
        return Icons.warning_rounded;
      case CpComplianceStatus.overProtected:
        return Icons.offline_bolt_rounded;
      case CpComplianceStatus.acInterferenceAlert:
        return Icons.electrical_services_rounded;
    }
  }
}

enum TlpType {
  standardPotential,
  fourWireShunt,
  casedCrossing,
  foreignLineBond,
  acMitigationDecoupler,
  sacrificialAnode,
}

extension TlpTypeExt on TlpType {
  String get displayName {
    switch (this) {
      case TlpType.standardPotential:
        return 'Type A: Std Potential';
      case TlpType.fourWireShunt:
        return 'Type B: 4-Wire Shunt';
      case TlpType.casedCrossing:
        return 'Type C: Casing Isol.';
      case TlpType.foreignLineBond:
        return 'Type D: Foreign Bond';
      case TlpType.acMitigationDecoupler:
        return 'Type E: AC Coupon & SSD';
      case TlpType.sacrificialAnode:
        return 'Type S: Sacrificial Bed';
    }
  }

  IconData get icon {
    switch (this) {
      case TlpType.standardPotential:
        return Icons.straighten_rounded;
      case TlpType.fourWireShunt:
        return Icons.timeline_rounded;
      case TlpType.casedCrossing:
        return Icons.circle_outlined;
      case TlpType.foreignLineBond:
        return Icons.alt_route_rounded;
      case TlpType.acMitigationDecoupler:
        return Icons.bolt_rounded;
      case TlpType.sacrificialAnode:
        return Icons.shield_rounded;
    }
  }
}

class TlpRecord {
  final String id; // e.g. TLP-01
  final String name; // Landmark / Section
  final double chainageKm; // e.g. 0.150
  final String chainageStr; // e.g. "Ch 0+150"
  final double latitude;
  final double longitude;
  final TlpType type;
  final double soilResistivityOhmCm;
  final String soilDescription;

  // Potential measurements in mV CSE (negative numbers, e.g. -1180)
  double onPotentialMv; // E_on with IR drop
  double instantOffMv; // E_off IR-free polarized
  double polarizationDecayMv; // 100mV decay test result
  double acInducedVoltsRms; // Induced AC voltage (Volts RMS)
  double acCurrentDensityAm2; // AC current density (A/m² on 1 cm² coupon)

  // Casing details (if applicable)
  double? casingPotentialMv;
  bool isCasingShortAlert;

  // Metadata
  DateTime lastSurveyDate;
  String inspectorName;
  String remarks;

  TlpRecord({
    required this.id,
    required this.name,
    required this.chainageKm,
    required this.chainageStr,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.soilResistivityOhmCm,
    required this.soilDescription,
    required this.onPotentialMv,
    required this.instantOffMv,
    required this.polarizationDecayMv,
    required this.acInducedVoltsRms,
    required this.acCurrentDensityAm2,
    this.casingPotentialMv,
    this.isCasingShortAlert = false,
    required this.lastSurveyDate,
    required this.inspectorName,
    required this.remarks,
  });

  CpComplianceStatus get status {
    // 1. Check for AC Interference hazard (>15V RMS touch voltage or >30 A/m²)
    if (acInducedVoltsRms > 15.0 || acCurrentDensityAm2 > 30.0) {
      return CpComplianceStatus.acInterferenceAlert;
    }
    // 2. NACE SP0169 Criterion: Instant-off must be between -850mV and -1200mV CSE
    // Note: values are negative. -850mV is algebraically greater than -1200mV.
    // E_off > -850 mV (e.g. -820 mV) => under-protected
    if (instantOffMv > -850.0) {
      return CpComplianceStatus.underProtected;
    }
    // E_off < -1200 mV (e.g. -1250 mV) => over-protected
    if (instantOffMv < -1200.0) {
      return CpComplianceStatus.overProtected;
    }
    return CpComplianceStatus.compliant;
  }

  // True if meets 100 mV decay criterion even if absolute -850mV not met
  bool get meets100MvCriterion => polarizationDecayMv >= 100.0;
}

enum TruOperatingMode {
  apcc, // Automatic Potential Controlled
  avcc, // Automatic Voltage Controlled
  manual, // Manual Tap Setting
}

extension TruOperatingModeExt on TruOperatingMode {
  String get label {
    switch (this) {
      case TruOperatingMode.apcc:
        return 'Auto Potential (APCC)';
      case TruOperatingMode.avcc:
        return 'Auto Current (AVCC)';
      case TruOperatingMode.manual:
        return 'Manual Control';
    }
  }
}

class TruStationRecord {
  final String id; // e.g. TRU-01
  final String name;
  final String locationChainage;
  final double chainageKm;
  final String maxRating; // e.g. "50V / 25A"
  double outputVoltageVolts;
  double outputCurrentAmps;
  final double targetSetpointMv;
  TruOperatingMode mode;
  final double groundbedResistanceOhms;
  final String anodeBedType; // e.g. MMO Tubular / Si-Fe-Cr
  final int wellDepthMeters;
  final String backfillType;
  final double backfillColumnMeters;
  final double powerFactor;
  final double efficiencyPercent;
  final bool isOnline;
  final bool isGpsSynchronized;

  TruStationRecord({
    required this.id,
    required this.name,
    required this.locationChainage,
    required this.chainageKm,
    required this.maxRating,
    required this.outputVoltageVolts,
    required this.outputCurrentAmps,
    required this.targetSetpointMv,
    required this.mode,
    required this.groundbedResistanceOhms,
    required this.anodeBedType,
    required this.wellDepthMeters,
    required this.backfillType,
    required this.backfillColumnMeters,
    required this.powerFactor,
    required this.efficiencyPercent,
    required this.isOnline,
    required this.isGpsSynchronized,
  });

  double get powerWatts => outputVoltageVolts * outputCurrentAmps;
}

class SacrificialBedRecord {
  final String id; // e.g. SA-01
  final String name;
  final String chainage;
  final String anodeMaterial; // High-Pot Mg 17lb / ASTM B418 Zinc
  final int anodeCount;
  final double openCircuitPotentialMv;
  final double closedCircuitPotentialMv;
  final double currentOutputMa;
  final String protectedStructure; // Casing / HDD Section / Valve Chamber
  final double estimatedLifeYears;

  SacrificialBedRecord({
    required this.id,
    required this.name,
    required this.chainage,
    required this.anodeMaterial,
    required this.anodeCount,
    required this.openCircuitPotentialMv,
    required this.closedCircuitPotentialMv,
    required this.currentOutputMa,
    required this.protectedStructure,
    required this.estimatedLifeYears,
  });
}

class SolidStateDecouplerRecord {
  final String id; // e.g. SSD-01
  final String tlpRef;
  final String chainage;
  final String makeModel; // Dairyland PCR / SSD
  final double inducedAcVoltsRms;
  final double acDischargeCurrentAmps;
  final double dcBlockingThresholdVolts;
  final bool isSurgeArrestorHealthy;
  final bool isGroundingContinuityOk;

  SolidStateDecouplerRecord({
    required this.id,
    required this.tlpRef,
    required this.chainage,
    required this.makeModel,
    required this.inducedAcVoltsRms,
    required this.acDischargeCurrentAmps,
    required this.dcBlockingThresholdVolts,
    required this.isSurgeArrestorHealthy,
    required this.isGroundingContinuityOk,
  });
}

// ============================================================================
// SCREEN WIDGET
// ============================================================================

class CathodicProtectionScreen extends StatefulWidget {
  const CathodicProtectionScreen({super.key});

  @override
  State<CathodicProtectionScreen> createState() =>
      _CathodicProtectionScreenState();
}

class _CathodicProtectionScreenState extends State<CathodicProtectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter state
  String _searchQuery = '';
  CpComplianceStatus? _selectedStatusFilter;
  bool _isInterrupterActive = true;
  String _interrupterCycle = '4s ON / 1s OFF';

  // Selected TLP for polarization decay simulator
  late TlpRecord _selectedTlpForDecay;

  // Master Data
  late List<TlpRecord> _tlpSurveyList;
  late List<TruStationRecord> _truStationList;
  late List<SacrificialBedRecord> _sacrificialBedList;
  late List<SolidStateDecouplerRecord> _decouplerList;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializePipelineData();
    _selectedTlpForDecay = _tlpSurveyList[0];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializePipelineData() {
    // 24 TLPs along Duliajan to Digboi 18" Pipeline Corridor (34.8 km)
    _tlpSurveyList = [
      TlpRecord(
        id: 'TLP-01',
        name: 'Duliajan CGGS Header & Station IJ',
        chainageKm: 0.150,
        chainageStr: 'Ch 0+150',
        latitude: 27.2842,
        longitude: 95.3184,
        type: TlpType.standardPotential,
        soilResistivityOhmCm: 4800,
        soilDescription: 'Moist Sandy Silt',
        onPotentialMv: -1180,
        instantOffMv: -1045,
        polarizationDecayMv: 165,
        acInducedVoltsRms: 1.4,
        acCurrentDensityAm2: 4.2,
        casingPotentialMv: null,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 1)),
        inspectorName: 'B. Gogoi (NACE CP-2)',
        remarks:
            'Station Insulating Joint (IJ) spark-gap healthy. Polarized potential well within NACE criteria.',
      ),
      TlpRecord(
        id: 'TLP-02',
        name: 'Tipling River Bank Casing Crossing',
        chainageKm: 1.820,
        chainageStr: 'Ch 1+820',
        latitude: 27.2915,
        longitude: 95.3290,
        type: TlpType.casedCrossing,
        soilResistivityOhmCm: 3200,
        soilDescription: 'Alluvial River Silt',
        onPotentialMv: -1150,
        instantOffMv: -1015,
        polarizationDecayMv: 140,
        acInducedVoltsRms: 2.1,
        acCurrentDensityAm2: 6.5,
        casingPotentialMv: -620,
        isCasingShortAlert: false,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 1)),
        inspectorName: 'B. Gogoi (NACE CP-2)',
        remarks:
            'Carrier vs Casing Delta V = 395 mV. Casing isolated, no metallic short detected.',
      ),
      TlpRecord(
        id: 'TLP-03',
        name: 'Bordubi Tea Estate Section A',
        chainageKm: 3.200,
        chainageStr: 'Ch 3+200',
        latitude: 27.2990,
        longitude: 95.3412,
        type: TlpType.standardPotential,
        soilResistivityOhmCm: 5600,
        soilDescription: 'Tea Garden Acidic Loam (pH 5.2)',
        onPotentialMv: -1120,
        instantOffMv: -985,
        polarizationDecayMv: 135,
        acInducedVoltsRms: 2.8,
        acCurrentDensityAm2: 7.8,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 2)),
        inspectorName: 'A. Saikia (NACE CP-1)',
        remarks:
            'Low pH soil requires steady CP polarization. Protective potential adequate.',
      ),
      TlpRecord(
        id: 'TLP-04',
        name: 'Overhead 33kV APDCL Feeder Crossing',
        chainageKm: 4.950,
        chainageStr: 'Ch 4+950',
        latitude: 27.3072,
        longitude: 95.3551,
        type: TlpType.acMitigationDecoupler,
        soilResistivityOhmCm: 6100,
        soilDescription: 'Clay Loam with Gravel',
        onPotentialMv: -1140,
        instantOffMv: -995,
        polarizationDecayMv: 150,
        acInducedVoltsRms: 6.4,
        acCurrentDensityAm2: 18.2,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 2)),
        inspectorName: 'A. Saikia (NACE CP-1)',
        remarks:
            'Induced AC voltage 6.4V RMS below 15V safe touch threshold. AC coupon current 18.2 A/m².',
      ),
      TlpRecord(
        id: 'TLP-05',
        name: 'Bordubi Railway Siding Casing',
        chainageKm: 6.400,
        chainageStr: 'Ch 6+400',
        latitude: 27.3148,
        longitude: 95.3698,
        type: TlpType.casedCrossing,
        soilResistivityOhmCm: 4400,
        soilDescription: 'Compact Clay Fill',
        onPotentialMv: -1110,
        instantOffMv: -960,
        polarizationDecayMv: 125,
        acInducedVoltsRms: 4.2,
        acCurrentDensityAm2: 12.0,
        casingPotentialMv: -590,
        isCasingShortAlert: false,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 3)),
        inspectorName: 'B. Gogoi (NACE CP-2)',
        remarks:
            'Rail crossing casing isolation confirmed (> 350 mV delta). End seals inspected intact.',
      ),
      TlpRecord(
        id: 'TLP-06',
        name: '132kV ASEB Transmission ROW Parallel Start',
        chainageKm: 8.150,
        chainageStr: 'Ch 8+150',
        latitude: 27.3225,
        longitude: 95.3850,
        type: TlpType.acMitigationDecoupler,
        soilResistivityOhmCm: 7200,
        soilDescription: 'Dry Sandy Clay',
        onPotentialMv: -1230,
        instantOffMv: -920,
        polarizationDecayMv: 110,
        acInducedVoltsRms: 16.8, // ALERT: > 15V RMS
        acCurrentDensityAm2: 48.5, // ALERT: > 30 A/m²
        lastSurveyDate: DateTime.now().subtract(const Duration(hours: 18)),
        inspectorName: 'H. Sharma (CP Specialist)',
        remarks:
            'WARNING: Parallel 132kV overhead grid induces 16.8V RMS touch potential. Solid-state decoupler SSD-01 actively discharging 4.2A AC.',
      ),
      TlpRecord(
        id: 'TLP-07',
        name: 'TRU-01 Deep Well MMO Anode Lead Junction',
        chainageKm: 9.600,
        chainageStr: 'Ch 9+600',
        latitude: 27.3298,
        longitude: 95.3995,
        type: TlpType.fourWireShunt,
        soilResistivityOhmCm: 3900,
        soilDescription: 'Deep Alluvium',
        onPotentialMv: -1280,
        instantOffMv: -1160,
        polarizationDecayMv: 220,
        acInducedVoltsRms: 14.2,
        acCurrentDensityAm2: 38.1,
        lastSurveyDate: DateTime.now().subtract(const Duration(hours: 18)),
        inspectorName: 'H. Sharma (CP Specialist)',
        remarks:
            'Drainage point for TRU-01 (14.8A DC). Calibrated 0.001 ohm shunt indicates 8.6A flowing East.',
      ),
      TlpRecord(
        id: 'TLP-08',
        name: 'Tingrai River HDD Crossing Entry Point',
        chainageKm: 11.250,
        chainageStr: 'Ch 11+250',
        latitude: 27.3370,
        longitude: 95.4140,
        type: TlpType.standardPotential,
        soilResistivityOhmCm: 2800,
        soilDescription: 'Wet Saturated Silt',
        onPotentialMv: -1190,
        instantOffMv: -1020,
        polarizationDecayMv: 155,
        acInducedVoltsRms: 18.5, // ALERT: > 15V RMS
        acCurrentDensityAm2: 52.4, // ALERT: > 30 A/m²
        lastSurveyDate: DateTime.now().subtract(const Duration(hours: 12)),
        inspectorName: 'H. Sharma (CP Specialist)',
        remarks:
            'HIGH AC INDUCTION ALERT: 18.5V RMS on carrier pipe. Mitigation zinc ribbon continuity verified.',
      ),
      TlpRecord(
        id: 'TLP-09',
        name: 'Tingrai River HDD Exit (Sacrificial Mg Bed)',
        chainageKm: 12.100,
        chainageStr: 'Ch 12+100',
        latitude: 27.3410,
        longitude: 95.4225,
        type: TlpType.sacrificialAnode,
        soilResistivityOhmCm: 2500,
        soilDescription: 'River Sand & Silt',
        onPotentialMv: -1160,
        instantOffMv: -1010,
        polarizationDecayMv: 145,
        acInducedVoltsRms: 15.6, // ALERT: > 15V RMS
        acCurrentDensityAm2: 44.0,
        lastSurveyDate: DateTime.now().subtract(const Duration(hours: 12)),
        inspectorName: 'H. Sharma (CP Specialist)',
        remarks:
            'Sacrificial Mg bed SA-01 discharging 185 mA. AC voltage slightly elevated at 15.6V RMS.',
      ),
      TlpRecord(
        id: 'TLP-10',
        name: 'Sectionalizing Valve Station SV-01',
        chainageKm: 13.850,
        chainageStr: 'Ch 13+850',
        latitude: 27.3485,
        longitude: 95.4380,
        type: TlpType.foreignLineBond,
        soilResistivityOhmCm: 4100,
        soilDescription: 'Compacted Red Soil',
        onPotentialMv: -1210,
        instantOffMv: -1050,
        polarizationDecayMv: 170,
        acInducedVoltsRms: 12.8,
        acCurrentDensityAm2: 32.6,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 3)),
        inspectorName: 'B. Gogoi (NACE CP-2)',
        remarks:
            'Station monolithic insulating joint verified. Resistance bond to loop line calibrated at 1.2 Ohms.',
      ),
      TlpRecord(
        id: 'TLP-11',
        name: 'Crossing OIL 8" Condensate Line (Bond)',
        chainageKm: 15.300,
        chainageStr: 'Ch 15+300',
        latitude: 27.3545,
        longitude: 95.4520,
        type: TlpType.foreignLineBond,
        soilResistivityOhmCm: 5200,
        soilDescription: 'Tea Estate Silt',
        onPotentialMv: -1090,
        instantOffMv: -940,
        polarizationDecayMv: 120,
        acInducedVoltsRms: 5.2,
        acCurrentDensityAm2: 14.1,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 4)),
        inspectorName: 'A. Saikia (NACE CP-1)',
        remarks:
            'Controlled resistance bond maintains both lines within -900mV to -1050mV. No DC stray pickup.',
      ),
      TlpRecord(
        id: 'TLP-12',
        name: 'NH-38 Highway Bored Casing Crossing',
        chainageKm: 16.900,
        chainageStr: 'Ch 16+900',
        latitude: 27.3610,
        longitude: 95.4675,
        type: TlpType.casedCrossing,
        soilResistivityOhmCm: 6800,
        soilDescription: 'Asphalt Sub-base Gravel & Clay',
        onPotentialMv: -1130,
        instantOffMv: -975,
        polarizationDecayMv: 130,
        acInducedVoltsRms: 4.8,
        acCurrentDensityAm2: 11.5,
        casingPotentialMv: -580,
        isCasingShortAlert: false,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 4)),
        inspectorName: 'A. Saikia (NACE CP-1)',
        remarks:
            'Casing isolated. 4x 17lb Mg anodes on casing maintain casing at -580mV without draining carrier.',
      ),
      TlpRecord(
        id: 'TLP-13',
        name: 'PowerGrid 220kV High-Voltage Crossing',
        chainageKm: 18.400,
        chainageStr: 'Ch 18+400',
        latitude: 27.3670,
        longitude: 95.4820,
        type: TlpType.acMitigationDecoupler,
        soilResistivityOhmCm: 8400,
        soilDescription: 'High Resistivity Dry Sandy Gravel',
        onPotentialMv: -1240,
        instantOffMv: -935,
        polarizationDecayMv: 115,
        acInducedVoltsRms: 21.4, // CRITICAL ALERT: > 15V RMS
        acCurrentDensityAm2: 62.0, // CRITICAL: > 30 A/m²
        lastSurveyDate: DateTime.now().subtract(const Duration(hours: 6)),
        inspectorName: 'H. Sharma (CP Specialist)',
        remarks:
            'CRITICAL AC INTERFERENCE: 220kV overhead line crossing induces 21.4V RMS. Decoupler SSD-02 conducting 6.8A AC to zinc ground ribbon.',
      ),
      TlpRecord(
        id: 'TLP-14',
        name: 'Bogapani Tea Estate East Block',
        chainageKm: 20.150,
        chainageStr: 'Ch 20+150',
        latitude: 27.3735,
        longitude: 95.4980,
        type: TlpType.standardPotential,
        soilResistivityOhmCm: 6400,
        soilDescription: 'Acidic Plantation Clay',
        onPotentialMv: -1150,
        instantOffMv: -990,
        polarizationDecayMv: 140,
        acInducedVoltsRms: 7.1,
        acCurrentDensityAm2: 19.5,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 5)),
        inspectorName: 'B. Gogoi (NACE CP-2)',
        remarks:
            'Adequately polarized. Ground water table at 2.4m depth. No holiday degradation seen.',
      ),
      TlpRecord(
        id: 'TLP-15',
        name: 'TRU-02 Si-Fe-Cr Deep Well Bed Junction',
        chainageKm: 21.750,
        chainageStr: 'Ch 21+750',
        latitude: 27.3795,
        longitude: 95.5135,
        type: TlpType.fourWireShunt,
        soilResistivityOhmCm: 3500,
        soilDescription: 'Wet Alluvial Clay',
        onPotentialMv: -1310,
        instantOffMv: -1185,
        polarizationDecayMv: 245,
        acInducedVoltsRms: 3.6,
        acCurrentDensityAm2: 9.2,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 5)),
        inspectorName: 'B. Gogoi (NACE CP-2)',
        remarks:
            'TRU-02 drainage point. Polarized instant-off at -1185mV, near upper safe boundary (-1200mV).',
      ),
      TlpRecord(
        id: 'TLP-16',
        name: 'Sectionalizing Valve Station SV-02',
        chainageKm: 23.400,
        chainageStr: 'Ch 23+400',
        latitude: 27.3850,
        longitude: 95.5290,
        type: TlpType.standardPotential,
        soilResistivityOhmCm: 4700,
        soilDescription: 'Dense Sandy Silt',
        onPotentialMv: -1180,
        instantOffMv: -1030,
        polarizationDecayMv: 160,
        acInducedVoltsRms: 3.0,
        acCurrentDensityAm2: 7.5,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 6)),
        inspectorName: 'A. Saikia (NACE CP-1)',
        remarks:
            'Station bonding and bypass switches verified closed. Full cathodic continuity across valve.',
      ),
      TlpRecord(
        id: 'TLP-17',
        name: 'Dehing Reserve Forest Border',
        chainageKm: 25.100,
        chainageStr: 'Ch 25+100',
        latitude: 27.3895,
        longitude: 95.5445,
        type: TlpType.standardPotential,
        soilResistivityOhmCm: 7900,
        soilDescription: 'Forest Humus & Clay',
        onPotentialMv: -1060,
        instantOffMv: -910,
        polarizationDecayMv: 110,
        acInducedVoltsRms: 2.4,
        acCurrentDensityAm2: 5.8,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 6)),
        inspectorName: 'A. Saikia (NACE CP-1)',
        remarks:
            'Higher soil resistivity slightly attenuates CP current. Polarized potential meets -850mV.',
      ),
      TlpRecord(
        id: 'TLP-18',
        name: 'Burhi Dihing River North Bank Casing',
        chainageKm: 26.850,
        chainageStr: 'Ch 26+850',
        latitude: 27.3930,
        longitude: 95.5600,
        type: TlpType.casedCrossing,
        soilResistivityOhmCm: 2100,
        soilDescription: 'Wet River Silt & Gravel',
        onPotentialMv: -1170,
        instantOffMv: -1025,
        polarizationDecayMv: 150,
        acInducedVoltsRms: 2.9,
        acCurrentDensityAm2: 7.1,
        casingPotentialMv: -610,
        isCasingShortAlert: false,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 7)),
        inspectorName: 'B. Gogoi (NACE CP-2)',
        remarks:
            'Microtunneling casing isolated. Carrier pipe healthy at -1025mV CSE instant-off.',
      ),
      TlpRecord(
        id: 'TLP-19',
        name: 'Burhi Dihing River South Bank (Zn Bed)',
        chainageKm: 28.300,
        chainageStr: 'Ch 28+300',
        latitude: 27.3955,
        longitude: 95.5740,
        type: TlpType.sacrificialAnode,
        soilResistivityOhmCm: 1950,
        soilDescription: 'Waterlogged River Mud',
        onPotentialMv: -1140,
        instantOffMv: -1005,
        polarizationDecayMv: 140,
        acInducedVoltsRms: 2.5,
        acCurrentDensityAm2: 6.2,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 7)),
        inspectorName: 'B. Gogoi (NACE CP-2)',
        remarks:
            'Sacrificial Zinc bed SA-03 provides localized supplementary protection in flood zone.',
      ),
      TlpRecord(
        id: 'TLP-20',
        name: 'Margherita Tea Estate Boundary',
        chainageKm: 29.950,
        chainageStr: 'Ch 29+950',
        latitude: 27.3970,
        longitude: 95.5890,
        type: TlpType.standardPotential,
        soilResistivityOhmCm: 9200,
        soilDescription: 'High Resistivity Sandy Gravel Hillock',
        onPotentialMv: -980,
        instantOffMv: -835, // UNDER-PROTECTED: > -850 mV
        polarizationDecayMv: 75, // Fails 100mV decay
        acInducedVoltsRms: 3.8,
        acCurrentDensityAm2: 8.9,
        lastSurveyDate: DateTime.now().subtract(const Duration(hours: 4)),
        inspectorName: 'H. Sharma (CP Specialist)',
        remarks:
            'UNDER-PROTECTION DEFECT: Instant-off at -835 mV CSE fails -850mV NACE SP0169 standard. High soil resistivity (9,200 ohm-cm) and remote distance from TRU-02 & TRU-03.',
      ),
      TlpRecord(
        id: 'TLP-21',
        name: 'NFR Broad Gauge Main Line Rail Crossing',
        chainageKm: 31.400,
        chainageStr: 'Ch 31+400',
        latitude: 27.3980,
        longitude: 95.6025,
        type: TlpType.casedCrossing,
        soilResistivityOhmCm: 5100,
        soilDescription: 'Railway Ballast & Sandy Silt',
        onPotentialMv: -1150,
        instantOffMv: -980,
        polarizationDecayMv: 135,
        acInducedVoltsRms: 8.5,
        acCurrentDensityAm2: 22.1,
        casingPotentialMv: -640,
        isCasingShortAlert: false,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 8)),
        inspectorName: 'B. Gogoi (NACE CP-2)',
        remarks:
            '25kV AC electric traction overhead lines contribute 8.5V AC. Casing isolated, spark gap tested.',
      ),
      TlpRecord(
        id: 'TLP-22',
        name: 'TRU-03 Deep Well MMO Anode Station',
        chainageKm: 32.850,
        chainageStr: 'Ch 32+850',
        latitude: 27.3990,
        longitude: 95.6130,
        type: TlpType.fourWireShunt,
        soilResistivityOhmCm: 3400,
        soilDescription: 'Moist Clay Loam',
        onPotentialMv: -1360,
        instantOffMv: -1225, // OVER-PROTECTED: < -1200 mV
        polarizationDecayMv: 260,
        acInducedVoltsRms: 3.2,
        acCurrentDensityAm2: 7.4,
        lastSurveyDate: DateTime.now().subtract(const Duration(hours: 3)),
        inspectorName: 'H. Sharma (CP Specialist)',
        remarks:
            'OVER-PROTECTION WARNING: Instant-off -1225 mV exceeds -1200mV limit. Risk of cathodic coating disbondment and hydrogen embrittlement. TRU-03 current output needs lowering.',
      ),
      TlpRecord(
        id: 'TLP-23',
        name: 'Digboi IOCL Approach Line & SSD',
        chainageKm: 33.900,
        chainageStr: 'Ch 33+900',
        latitude: 27.3995,
        longitude: 95.6205,
        type: TlpType.acMitigationDecoupler,
        soilResistivityOhmCm: 4600,
        soilDescription: 'Dense Fill Clay',
        onPotentialMv: -1205,
        instantOffMv: -1060,
        polarizationDecayMv: 175,
        acInducedVoltsRms: 4.1,
        acCurrentDensityAm2: 9.8,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 9)),
        inspectorName: 'A. Saikia (NACE CP-1)',
        remarks:
            'Solid-State Decoupler SSD-03 healthy. Polarization within standard design envelope.',
      ),
      TlpRecord(
        id: 'TLP-24',
        name: 'Digboi Refinery Receiver Station IJ',
        chainageKm: 34.650,
        chainageStr: 'Ch 34+650',
        latitude: 27.4002,
        longitude: 95.6265,
        type: TlpType.standardPotential,
        soilResistivityOhmCm: 3800,
        soilDescription: 'Industrial Station Fill',
        onPotentialMv: -1185,
        instantOffMv: -1040,
        polarizationDecayMv: 160,
        acInducedVoltsRms: 2.2,
        acCurrentDensityAm2: 5.0,
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 9)),
        inspectorName: 'A. Saikia (NACE CP-1)',
        remarks:
            'Refinery battery limit isolating joint (IJ) resistance > 10 M-Ohms. Surge diverter fully operational.',
      ),
    ];

    // ICCP Deep Well Anode Bed Stations (4 units along the 34.8 km corridor)
    _truStationList = [
      TruStationRecord(
        id: 'TRU-01',
        name: 'Duliajan CGGS Main CP Station',
        locationChainage: 'Ch 0+500 (Duliajan Compound)',
        chainageKm: 0.500,
        maxRating: '50V / 25A',
        outputVoltageVolts: 28.4,
        outputCurrentAmps: 14.8,
        targetSetpointMv: -1050,
        mode: TruOperatingMode.apcc,
        groundbedResistanceOhms: 0.72,
        anodeBedType: 'Mixed Metal Oxide (MMO) Tubular (8 string)',
        wellDepthMeters: 110,
        backfillType: 'Calcined Petroleum Coke Breeze (< 50 Ω·cm)',
        backfillColumnMeters: 65,
        powerFactor: 0.94,
        efficiencyPercent: 88.5,
        isOnline: true,
        isGpsSynchronized: true,
      ),
      TruStationRecord(
        id: 'TRU-02',
        name: 'Tingrai Sector CP Station',
        locationChainage: 'Ch 12+800 (Tingrai ROW Node)',
        chainageKm: 12.800,
        maxRating: '50V / 30A',
        outputVoltageVolts: 32.1,
        outputCurrentAmps: 18.2,
        targetSetpointMv: -1080,
        mode: TruOperatingMode.apcc,
        groundbedResistanceOhms: 0.88,
        anodeBedType: 'High-Silicon Cast Iron (Si-Fe-Cr) 10 Canister',
        wellDepthMeters: 95,
        backfillType: 'Graphite Carbonaceous Coke Column',
        backfillColumnMeters: 55,
        powerFactor: 0.92,
        efficiencyPercent: 86.2,
        isOnline: true,
        isGpsSynchronized: true,
      ),
      TruStationRecord(
        id: 'TRU-03',
        name: 'Bogapani Solar-Hybrid CP Station',
        locationChainage: 'Ch 23+400 (SV-02 Compound)',
        chainageKm: 23.400,
        maxRating: '40V / 20A',
        outputVoltageVolts: 24.6,
        outputCurrentAmps: 12.5,
        targetSetpointMv: -1050,
        mode: TruOperatingMode.apcc,
        groundbedResistanceOhms: 0.65,
        anodeBedType: 'MMO Tubular Canister String (6 Units)',
        wellDepthMeters: 100,
        backfillType: 'Low-Sulphur Calcined Petroleum Coke',
        backfillColumnMeters: 60,
        powerFactor: 0.96,
        efficiencyPercent: 91.0,
        isOnline: true,
        isGpsSynchronized: true,
      ),
      TruStationRecord(
        id: 'TRU-04',
        name: 'Digboi Refinery Terminal CP',
        locationChainage: 'Ch 34+200 (IOCL Approach Terminal)',
        chainageKm: 34.200,
        maxRating: '50V / 25A',
        outputVoltageVolts: 29.8,
        outputCurrentAmps: 15.6,
        targetSetpointMv: -1060,
        mode: TruOperatingMode.avcc,
        groundbedResistanceOhms: 0.79,
        anodeBedType: 'MMO Tubular String (8 Anodes in Deep Well)',
        wellDepthMeters: 90,
        backfillType: 'High-Purity Carbon Coke Slurry',
        backfillColumnMeters: 50,
        powerFactor: 0.93,
        efficiencyPercent: 87.8,
        isOnline: true,
        isGpsSynchronized: true,
      ),
    ];

    // Sacrificial Anode Beds
    _sacrificialBedList = [
      SacrificialBedRecord(
        id: 'SA-01',
        name: 'Tipling River Crossing Casing Groundbed',
        chainage: 'Ch 1+820',
        anodeMaterial: 'High-Potential Magnesium (17 lb Pre-packaged)',
        anodeCount: 2,
        openCircuitPotentialMv: -1540,
        closedCircuitPotentialMv: -620,
        currentOutputMa: 185.0,
        protectedStructure: '24" OD Highway Sleeve Casing (Carrier Isolated)',
        estimatedLifeYears: 14.5,
      ),
      SacrificialBedRecord(
        id: 'SA-02',
        name: 'NH-38 Highway Casing Anode Station',
        chainage: 'Ch 16+900',
        anodeMaterial: 'High-Potential Magnesium (17 lb M1 Grade)',
        anodeCount: 4,
        openCircuitPotentialMv: -1520,
        closedCircuitPotentialMv: -580,
        currentOutputMa: 310.0,
        protectedStructure: '24" Casing Under Highway Embankment',
        estimatedLifeYears: 11.2,
      ),
      SacrificialBedRecord(
        id: 'SA-03',
        name: 'Burhi Dihing River South Floodplain Zn Bed',
        chainage: 'Ch 28+300',
        anodeMaterial: 'ASTM B418 Type II High-Purity Zinc (22 lb)',
        anodeCount: 4,
        openCircuitPotentialMv: -1100,
        closedCircuitPotentialMv: -1005,
        currentOutputMa: 140.0,
        protectedStructure: 'Supplementary Riverbank Floodplain Shield',
        estimatedLifeYears: 22.0,
      ),
    ];

    // Solid State Decouplers (AC Stray Mitigation)
    _decouplerList = [
      SolidStateDecouplerRecord(
        id: 'SSD-01',
        tlpRef: 'TLP-06',
        chainage: 'Ch 8+150',
        makeModel: 'Dairyland PCR-3.7kA / SSD-AC Mitigation',
        inducedAcVoltsRms: 16.8,
        acDischargeCurrentAmps: 4.2,
        dcBlockingThresholdVolts: -3.0,
        isSurgeArrestorHealthy: true,
        isGroundingContinuityOk: true,
      ),
      SolidStateDecouplerRecord(
        id: 'SSD-02',
        tlpRef: 'TLP-13',
        chainage: 'Ch 18+400',
        makeModel: 'Dairyland PCR-5.0kA Heavy Duty Decoupler',
        inducedAcVoltsRms: 21.4,
        acDischargeCurrentAmps: 6.8,
        dcBlockingThresholdVolts: -3.0,
        isSurgeArrestorHealthy: true,
        isGroundingContinuityOk: true,
      ),
      SolidStateDecouplerRecord(
        id: 'SSD-03',
        tlpRef: 'TLP-23',
        chainage: 'Ch 33+900',
        makeModel: 'Solid-State AC Decoupler Type SSD-3',
        inducedAcVoltsRms: 4.1,
        acDischargeCurrentAmps: 1.1,
        dcBlockingThresholdVolts: -3.0,
        isSurgeArrestorHealthy: true,
        isGroundingContinuityOk: true,
      ),
    ];
  }

  // Filtered TLPs
  List<TlpRecord> get _filteredTlps {
    return _tlpSurveyList.where((tlp) {
      if (_selectedStatusFilter != null && tlp.status != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchId = tlp.id.toLowerCase().contains(query);
        final matchName = tlp.name.toLowerCase().contains(query);
        final matchCh = tlp.chainageStr.toLowerCase().contains(query);
        if (!matchId && !matchName && !matchCh) return false;
      }
      return true;
    }).toList();
  }

  // KPI Calculations
  int get _compliantCount => _tlpSurveyList
      .where((t) => t.status == CpComplianceStatus.compliant)
      .length;
  int get _underProtectedCount => _tlpSurveyList
      .where((t) => t.status == CpComplianceStatus.underProtected)
      .length;
  int get _overProtectedCount => _tlpSurveyList
      .where((t) => t.status == CpComplianceStatus.overProtected)
      .length;
  int get _acAlertCount => _tlpSurveyList
      .where((t) => t.status == CpComplianceStatus.acInterferenceAlert)
      .length;

  double get _complianceRate =>
      (_compliantCount / _tlpSurveyList.length) * 100.0;

  double get _averageInstantOff {
    final sum = _tlpSurveyList.fold<double>(
        0.0, (prev, elem) => prev + elem.instantOffMv);
    return sum / _tlpSurveyList.length;
  }

  double get _totalTruAmps {
    return _truStationList.fold<double>(
        0.0, (prev, elem) => prev + elem.outputCurrentAmps);
  }

  double get _maxAcVolts {
    return _tlpSurveyList.fold<double>(
        0.0, (prev, elem) => math.max(prev, elem.acInducedVoltsRms));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildKpiSummaryHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTlpSurveyTab(),
                _buildIccpGroundbedsTab(),
                _buildPspAnalyticsTab(),
                _buildAcInterferenceTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_chart_rounded, size: 20),
        label: const Text(
          'Log PSP Reading',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        onPressed: _showLogPspReadingDialog,
      ),
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
                'Cathodic Protection & Corrosion Integrity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'NACE SP0169',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Duliajan–Digboi 18" (457mm OD) Pipeline • Ch 0+000 to Ch 34+800 • OIL Corridor',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Synchronous Interrupters',
          icon: Icon(
            _isInterrupterActive
                ? Icons.sync_rounded
                : Icons.sync_disabled_rounded,
            color: _isInterrupterActive
                ? AppTheme.tertiary
                : AppTheme.textMuted,
          ),
          onPressed: _showInterrupterSettingsDialog,
        ),
        IconButton(
          tooltip: 'Export NACE SP0169 Audit Dossier',
          icon: const Icon(Icons.picture_as_pdf_rounded,
              color: AppTheme.primaryLight),
          onPressed: _showAuditDossierDialog,
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildKpiSummaryHeader() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Row of 4 KPI Metric Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Corridor Compliance',
                  value: '${_complianceRate.toStringAsFixed(1)}%',
                  subtitle:
                      '$_compliantCount / ${_tlpSurveyList.length} Compliant',
                  icon: Icons.verified_rounded,
                  accentColor: _complianceRate >= 90.0
                      ? AppTheme.tertiary
                      : AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  title: 'Mean Polarized Off',
                  value: '${_averageInstantOff.toStringAsFixed(0)} mV',
                  subtitle: 'Target: -850 to -1200',
                  icon: Icons.electric_meter_rounded,
                  accentColor: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  title: 'Total ICCP Output',
                  value: '${_totalTruAmps.toStringAsFixed(1)} A',
                  subtitle: '4 Deep Well Anode Beds',
                  icon: Icons.solar_power_rounded,
                  accentColor: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  title: 'AC Stray Alerts',
                  value: '$_acAlertCount TLPs',
                  subtitle: 'Max ${_maxAcVolts.toStringAsFixed(1)}V RMS',
                  icon: Icons.warning_amber_rounded,
                  accentColor: _acAlertCount > 0
                      ? const Color(0xFFF43F5E)
                      : AppTheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // AC Interference Warning strip if active
          if (_acAlertCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on_rounded,
                      color: Color(0xFFF43F5E), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textPrimary),
                        children: [
                          const TextSpan(
                            text: 'AC INTERFERENCE WARNING: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF43F5E),
                            ),
                          ),
                          TextSpan(
                            text:
                                'Overhead 132kV ASEB grid line parallelism (Ch 8+150 to Ch 14+900) induced up to ${_maxAcVolts.toStringAsFixed(1)}V RMS. Solid-State Decouplers SSD-01 & SSD-02 actively discharging.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _tabController.animateTo(3),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'View Mitigations',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF43F5E),
                        ),
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
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
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        tabs: [
          Tab(
            text: 'TLP Survey (${_tlpSurveyList.length})',
            icon: const Icon(Icons.pin_drop_rounded, size: 18),
          ),
          Tab(
            text: 'ICCP & Beds (${_truStationList.length})',
            icon: const Icon(Icons.electrical_services_rounded, size: 18),
          ),
          const Tab(
            text: 'PSP Analytics',
            icon: Icon(Icons.show_chart_rounded, size: 18),
          ),
          Tab(
            text: 'AC/DC Stray (${_decouplerList.length})',
            icon: const Icon(Icons.thunderstorm_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: TLP SURVEY MASTER REGISTER
  // ============================================================================

  Widget _buildTlpSurveyTab() {
    final filtered = _filteredTlps;

    return Column(
      children: [
        // Search & Filter header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.background,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search TLP ID, Landmark or Chainage...',
                          hintStyle: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12),
                          prefixIcon: const Icon(Icons.search_rounded,
                              size: 16, color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.surfaceCard,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppTheme.border),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${filtered.length} Points',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
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
                    _buildFilterChip(
                      label: 'All (${_tlpSurveyList.length})',
                      isSelected: _selectedStatusFilter == null,
                      onTap: () => setState(() => _selectedStatusFilter = null),
                      badgeColor: AppTheme.primaryLight,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: 'Compliant ($_compliantCount)',
                      isSelected: _selectedStatusFilter ==
                          CpComplianceStatus.compliant,
                      onTap: () => setState(() => _selectedStatusFilter =
                          CpComplianceStatus.compliant),
                      badgeColor: AppTheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: 'Under-Protected ($_underProtectedCount)',
                      isSelected: _selectedStatusFilter ==
                          CpComplianceStatus.underProtected,
                      onTap: () => setState(() => _selectedStatusFilter =
                          CpComplianceStatus.underProtected),
                      badgeColor: const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: 'Over-Protected ($_overProtectedCount)',
                      isSelected: _selectedStatusFilter ==
                          CpComplianceStatus.overProtected,
                      onTap: () => setState(() => _selectedStatusFilter =
                          CpComplianceStatus.overProtected),
                      badgeColor: AppTheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: 'AC Alert ($_acAlertCount)',
                      isSelected: _selectedStatusFilter ==
                          CpComplianceStatus.acInterferenceAlert,
                      onTap: () => setState(() => _selectedStatusFilter =
                          CpComplianceStatus.acInterferenceAlert),
                      badgeColor: const Color(0xFFF43F5E),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List of TLPs
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tlp = filtered[index];
                    return _buildTlpSurveyCard(tlp);
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
    required Color badgeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? badgeColor.withValues(alpha: 0.2)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? badgeColor : AppTheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? badgeColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTlpSurveyCard(TlpRecord tlp) {
    final statusColor = tlp.status.color;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tlp.status == CpComplianceStatus.compliant
              ? AppTheme.border
              : statusColor.withValues(alpha: 0.6),
          width: tlp.status == CpComplianceStatus.compliant ? 1.0 : 1.5,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tlp.type.icon, color: statusColor, size: 16),
              const SizedBox(height: 2),
              Text(
                tlp.id.replaceAll('TLP-', ''),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            Text(
              tlp.id,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tlp.chainageStr,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tlp.status.icon, color: statusColor, size: 11),
                  const SizedBox(width: 4),
                  Text(
                    tlp.status == CpComplianceStatus.compliant
                        ? 'COMPLIANT'
                        : tlp.status == CpComplianceStatus.underProtected
                            ? 'UNDER-PROT'
                            : tlp.status == CpComplianceStatus.overProtected
                                ? 'OVER-PROT'
                                : 'AC ALERT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              tlp.name,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Quick Potential Chips: E_on, E_off, AC Volts
            Row(
              children: [
                _buildQuickValChip(
                  label: 'E_on',
                  val: '${tlp.onPotentialMv.toStringAsFixed(0)} mV',
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                _buildQuickValChip(
                  label: 'E_off (Instant)',
                  val: '${tlp.instantOffMv.toStringAsFixed(0)} mV',
                  color: statusColor,
                  isBold: true,
                ),
                const SizedBox(width: 6),
                _buildQuickValChip(
                  label: 'AC',
                  val: '${tlp.acInducedVoltsRms.toStringAsFixed(1)}V',
                  color: tlp.acInducedVoltsRms > 15.0
                      ? const Color(0xFFF43F5E)
                      : AppTheme.textMuted,
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(color: AppTheme.border, height: 16),
          // Technical Details Table
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailLine(
                        'TLP Config', tlp.type.displayName, Icons.settings),
                    _buildDetailLine(
                        'GPS Coords',
                        '${tlp.latitude.toStringAsFixed(4)}°N, ${tlp.longitude.toStringAsFixed(4)}°E',
                        Icons.gps_fixed_rounded),
                    _buildDetailLine(
                        'Soil Resistivity',
                        '${tlp.soilResistivityOhmCm.toStringAsFixed(0)} Ω·cm (${tlp.soilDescription})',
                        Icons.terrain_rounded),
                    _buildDetailLine(
                        '100mV Decay',
                        '${tlp.polarizationDecayMv.toStringAsFixed(0)} mV (Req: ≥100mV)',
                        Icons.trending_down_rounded,
                        valueColor: tlp.meets100MvCriterion
                            ? AppTheme.tertiary
                            : const Color(0xFFEF4444)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailLine(
                        'AC Current Dens.',
                        '${tlp.acCurrentDensityAm2.toStringAsFixed(1)} A/m² (Coupon)',
                        Icons.bolt_rounded,
                        valueColor: tlp.acCurrentDensityAm2 > 30.0
                            ? const Color(0xFFF43F5E)
                            : AppTheme.textSecondary),
                    if (tlp.casingPotentialMv != null)
                      _buildDetailLine(
                          'Casing Potential',
                          '${tlp.casingPotentialMv!.toStringAsFixed(0)} mV CSE',
                          Icons.circle_outlined),
                    _buildDetailLine('Last Survey',
                        DateFormat('dd MMM yyyy').format(tlp.lastSurveyDate),
                        Icons.calendar_today_rounded),
                    _buildDetailLine('Inspector', tlp.inspectorName,
                        Icons.badge_rounded),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Remarks Note
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: AppTheme.primaryLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tlp.remarks,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Actions: View Coupon Decay & Calibrate
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: AppTheme.border),
                ),
                icon: const Icon(Icons.show_chart_rounded,
                    size: 13, color: AppTheme.primaryLight),
                label: const Text(
                  'Depolarization Curve',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryLight),
                ),
                onPressed: () {
                  setState(() {
                    _selectedTlpForDecay = tlp;
                  });
                  _tabController.animateTo(2); // Switch to Analytics Tab
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  foregroundColor: AppTheme.textPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.edit_note_rounded,
                    size: 14, color: AppTheme.textSecondary),
                label: const Text('Update Reading',
                    style: TextStyle(fontSize: 11)),
                onPressed: () => _showEditReadingDialog(tlp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickValChip({
    required String label,
    required String val,
    required Color color,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: val,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailLine(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 8),
          const Text(
            'No matching Test Lead Points found',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try resetting your search query or status filters.',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedStatusFilter = null;
              });
            },
            child: const Text('Reset All Filters'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: ICCP & SACRIFICIAL ANODE GROUNDBEDS
  // ============================================================================

  Widget _buildIccpGroundbedsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Section Title: Impressed Current Transformer Rectifier Units
        _buildSectionHeader(
          title: 'Impressed Current CP (ICCP) Deep Well Anode Stations',
          subtitle:
              '4 Automatic TRUs with MMO & Fe-Si-Cr Groundbeds (-0.85V to -1.20V CSE Target)',
          icon: Icons.electrical_services_rounded,
        ),
        const SizedBox(height: 8),

        // TRU Cards
        ..._truStationList.map((tru) => _buildTruStationCard(tru)),

        const SizedBox(height: 16),
        // Section Title: Sacrificial Anodes
        _buildSectionHeader(
          title: 'Sacrificial Anode Groundbeds (Magnesium & Zinc)',
          subtitle:
              'Cased Road/Rail Crossings & Floodplain Supplementary Protection',
          icon: Icons.shield_rounded,
        ),
        const SizedBox(height: 8),

        // Sacrificial Bed Cards
        ..._sacrificialBedList.map((bed) => _buildSacrificialBedCard(bed)),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTruStationCard(TruStationRecord tru) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.power_rounded,
                    color: AppTheme.primaryLight, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tru.id,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${tru.name}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tru.locationChainage,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tru.isOnline
                      ? AppTheme.tertiary.withValues(alpha: 0.15)
                      : const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tru.isOnline
                            ? AppTheme.tertiary
                            : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tru.isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: tru.isOnline
                            ? AppTheme.tertiary
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Output Gauges Grid
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildGaugeItem(
                    label: 'DC Voltage',
                    value: '${tru.outputVoltageVolts.toStringAsFixed(1)} V',
                    rating: 'Rating: ${tru.maxRating}',
                    color: const Color(0xFF38BDF8),
                  ),
                ),
                Container(width: 1, height: 36, color: AppTheme.border),
                Expanded(
                  child: _buildGaugeItem(
                    label: 'DC Current',
                    value: '${tru.outputCurrentAmps.toStringAsFixed(1)} A',
                    rating: 'Power: ${tru.powerWatts.toStringAsFixed(0)} W',
                    color: AppTheme.secondary,
                  ),
                ),
                Container(width: 1, height: 36, color: AppTheme.border),
                Expanded(
                  child: _buildGaugeItem(
                    label: 'Bed Resistance',
                    value:
                        '${tru.groundbedResistanceOhms.toStringAsFixed(2)} Ω',
                    rating: 'Target: < 1.0 Ω',
                    color: tru.groundbedResistanceOhms < 1.0
                        ? AppTheme.tertiary
                        : AppTheme.secondary,
                  ),
                ),
                Container(width: 1, height: 36, color: AppTheme.border),
                Expanded(
                  child: _buildGaugeItem(
                    label: 'Target Polarized',
                    value: '${tru.targetSetpointMv.toStringAsFixed(0)} mV',
                    rating: 'Mode: ${tru.mode.name.toUpperCase()}',
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Deep Well Specification details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailLine(
                        'Anode Bed String', tru.anodeBedType, Icons.grain),
                    _buildDetailLine(
                        'Deep Well Depth',
                        '${tru.wellDepthMeters}m (Backfill column: ${tru.backfillColumnMeters.toStringAsFixed(0)}m)',
                        Icons.height_rounded),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailLine(
                        'Carbon Backfill', tru.backfillType, Icons.layers),
                    _buildDetailLine(
                        'Efficiency / PF',
                        '${tru.efficiencyPercent.toStringAsFixed(1)}% (PF: ${tru.powerFactor})',
                        Icons.speed_rounded),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          // Remote Calibration & Tuning Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded,
                      size: 12, color: AppTheme.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    tru.isGpsSynchronized
                        ? 'GPS Synchronized Interruption Active'
                        : 'GPS Desynced',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.tertiary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  foregroundColor: AppTheme.textPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.tune_rounded,
                    size: 13, color: AppTheme.primaryLight),
                label: const Text('Calibrate TRU',
                    style: TextStyle(fontSize: 11)),
                onPressed: () => _showTruCalibrationDialog(tru),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeItem({
    required String label,
    required String value,
    required String rating,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          rating,
          style: const TextStyle(fontSize: 8, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSacrificialBedCard(SacrificialBedRecord bed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_outlined,
                color: AppTheme.secondary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bed.id,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${bed.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bed.chainage,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Protected: ${bed.protectedStructure}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildQuickValChip(
                      label: 'Anode Alloy',
                      val: '${bed.anodeCount}x ${bed.anodeMaterial}',
                      color: AppTheme.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    _buildQuickValChip(
                      label: 'Output',
                      val: '${bed.currentOutputMa.toStringAsFixed(0)} mA',
                      color: AppTheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    _buildQuickValChip(
                      label: 'Est. Life',
                      val: '${bed.estimatedLifeYears.toStringAsFixed(1)} yrs',
                      color: AppTheme.secondary,
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

  // ============================================================================
  // TAB 3: PSP ANALYTICS & INTERACTIVE FLCHARTS
  // ============================================================================

  Widget _buildPspAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Chart 1: Corridor Pipe-to-Soil Potential Profile
        _buildCorridorPspProfileCard(),
        const SizedBox(height: 16),

        // Chart 2: 100 mV Depolarization Decay Simulator
        _buildDepolarizationDecayCard(),
        const SizedBox(height: 16),

        // Statistical Distribution
        _buildCorridorStatsCard(),
      ],
    );
  }

  Widget _buildCorridorPspProfileCard() {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.show_chart_rounded,
                  color: AppTheme.primaryLight, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pipeline PSP Profile (Duliajan to Digboi - 34.8 km)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'NACE SP0169 Criterion: -0.85V to -1.20V CSE Polarized (Instant-Off)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Legend
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 8, height: 8, color: const Color(0xFF38BDF8)),
                      const SizedBox(width: 4),
                      const Text('E_off (Polarized)',
                          style: TextStyle(
                              fontSize: 9, color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 8, height: 8, color: const Color(0xFFFFB95F)),
                      const SizedBox(width: 4),
                      const Text('E_on (Total)',
                          style: TextStyle(
                              fontSize: 9, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // FLChart LineChart for Corridor
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 35,
                minY: -1500,
                maxY: -700,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 100,
                  verticalInterval: 5,
                  getDrawingHorizontalLine: (val) {
                    if (val == -850 || val == -1200) {
                      return FlLine(
                        color: val == -850
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFFFB95F),
                        strokeWidth: 1.5,
                        dashArray: [5, 4],
                      );
                    }
                    return FlLine(
                      color: AppTheme.border.withValues(alpha: 0.4),
                      strokeWidth: 0.8,
                    );
                  },
                  getDrawingVerticalLine: (val) {
                    return FlLine(
                      color: AppTheme.border.withValues(alpha: 0.3),
                      strokeWidth: 0.8,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: 200,
                      getTitlesWidget: (val, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            '${(val / 1000).toStringAsFixed(2)}V',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 5,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          'Ch ${val.toInt()}k',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.border),
                ),
                rangeAnnotations: RangeAnnotations(
                  horizontalRangeAnnotations: [
                    HorizontalRangeAnnotation(
                      y1: -1200,
                      y2: -850,
                      color: const Color(0xFF4EDEA3).withValues(alpha: 0.08),
                    ),
                  ],
                ),
                lineBarsData: [
                  // E_on Series (Amber)
                  LineChartBarData(
                    spots: _tlpSurveyList.map((t) {
                      return FlSpot(t.chainageKm, t.onPotentialMv);
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: const Color(0xFFFFB95F),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  // E_off Series (Cyan)
                  LineChartBarData(
                    spots: _tlpSurveyList.map((t) {
                      return FlSpot(t.chainageKm, t.instantOffMv);
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: const Color(0xFF38BDF8),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final tlp = _tlpSurveyList[index];
                        final color = tlp.status.color;
                        return FlDotCirclePainter(
                          radius: 3.5,
                          color: color,
                          strokeWidth: 1.5,
                          strokeColor: AppTheme.surfaceCard,
                        );
                      },
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => AppTheme.surfaceCard,
                    tooltipRoundedRadius: 8,
                    tooltipBorder:
                        const BorderSide(color: AppTheme.border, width: 1),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.spotIndex;
                        if (index < 0 || index >= _tlpSurveyList.length) {
                          return null;
                        }
                        final tlp = _tlpSurveyList[index];
                        if (spot.barIndex == 0) {
                          return LineTooltipItem(
                            '${tlp.id} (${tlp.chainageStr})\nE_on: ${tlp.onPotentialMv.toStringAsFixed(0)} mV',
                            const TextStyle(
                              color: Color(0xFFFFB95F),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        } else {
                          return LineTooltipItem(
                            'E_off: ${tlp.instantOffMv.toStringAsFixed(0)} mV\nStatus: ${tlp.status.label}',
                            TextStyle(
                              color: tlp.status.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Chart Threshold Legend Notes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                      width: 12, height: 2, color: const Color(0xFFEF4444)),
                  const SizedBox(width: 4),
                  const Text(
                    'Min -0.85V CSE (NACE Under-prot limit)',
                    style: TextStyle(fontSize: 9, color: AppTheme.textMuted),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                      width: 12, height: 2, color: const Color(0xFFFFB95F)),
                  const SizedBox(width: 4),
                  const Text(
                    'Max -1.20V CSE (Over-prot limit)',
                    style: TextStyle(fontSize: 9, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepolarizationDecayCard() {
    final tlp = _selectedTlpForDecay;
    // Generate simulated 100 mV decay curve points
    // Instant off at t=0, logarithmic decay over 120 seconds
    final List<FlSpot> decaySpots = [];
    final double eInstantOff = tlp.instantOffMv;
    final double decayTarget = tlp.polarizationDecayMv;

    for (int t = 0; t <= 120; t += 5) {
      // Delta decay = decayTarget * (1 - e^(-t / 30))
      final delta = decayTarget * (1.0 - math.exp(-t / 30.0));
      final val = eInstantOff + delta; // becomes less negative
      decaySpots.add(FlSpot(t.toDouble(), val));
    }

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
            children: [
              const Icon(Icons.history_toggle_off_rounded,
                  color: AppTheme.tertiary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '100 mV Polarization Decay Test (Depolarization)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NACE SP0169 Criterion: Formation or decay of ≥ 100 mV cathodic polarization',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Dropdown to pick TLP
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButton<String>(
                  value: _selectedTlpForDecay.id,
                  dropdownColor: AppTheme.surfaceCard,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down,
                      color: AppTheme.primaryLight, size: 18),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryLight,
                  ),
                  items: _tlpSurveyList.map((t) {
                    return DropdownMenuItem<String>(
                      value: t.id,
                      child: Text('${t.id} (${t.chainageStr})'),
                    );
                  }).toList(),
                  onChanged: (newId) {
                    if (newId != null) {
                      setState(() {
                        _selectedTlpForDecay =
                            _tlpSurveyList.firstWhere((t) => t.id == newId);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metrics strip for selected TLP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickValChip(
                  label: 'Instant-Off (t=0)',
                  val: '${tlp.instantOffMv.toStringAsFixed(0)} mV',
                  color: const Color(0xFF38BDF8),
                ),
                _buildQuickValChip(
                  label: 'Decay Achieved',
                  val: '${tlp.polarizationDecayMv.toStringAsFixed(0)} mV',
                  color: tlp.meets100MvCriterion
                      ? AppTheme.tertiary
                      : const Color(0xFFEF4444),
                  isBold: true,
                ),
                _buildQuickValChip(
                  label: 'NACE 100mV Pass?',
                  val: tlp.meets100MvCriterion ? 'YES (PASSED)' : 'NO (FAILED)',
                  color: tlp.meets100MvCriterion
                      ? AppTheme.tertiary
                      : const Color(0xFFEF4444),
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // FLChart LineChart for Depolarization
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 120,
                minY: (eInstantOff - 30).floorToDouble(),
                maxY: (eInstantOff + decayTarget + 30).ceilToDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 25,
                  verticalInterval: 20,
                  getDrawingHorizontalLine: (val) {
                    return FlLine(
                      color: AppTheme.border.withValues(alpha: 0.4),
                      strokeWidth: 0.8,
                    );
                  },
                  getDrawingVerticalLine: (val) {
                    return FlLine(
                      color: AppTheme.border.withValues(alpha: 0.3),
                      strokeWidth: 0.8,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: 40,
                      getTitlesWidget: (val, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            '${val.toInt()}mV',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 20,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toInt()}s',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.border),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: decaySpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppTheme.tertiary,
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.tertiary.withValues(alpha: 0.1),
                    ),
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

  Widget _buildCorridorStatsCard() {
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
          const Text(
            'Pipeline Cathodic Integrity Summary',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatProgress(
                  label: 'NACE SP0169 Compliant',
                  count: _compliantCount,
                  total: _tlpSurveyList.length,
                  color: AppTheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatProgress(
                  label: 'Under-Protected (< -850mV)',
                  count: _underProtectedCount,
                  total: _tlpSurveyList.length,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatProgress(
                  label: 'Over-Protected (> -1200mV)',
                  count: _overProtectedCount,
                  total: _tlpSurveyList.length,
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatProgress(
                  label: 'AC Stray Alerts (>15V / >30A/m²)',
                  count: _acAlertCount,
                  total: _tlpSurveyList.length,
                  color: const Color(0xFFF43F5E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatProgress({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final pct = (count / total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
            Text(
              '$count / $total (${(pct * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppTheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 4: AC/DC STRAY CURRENT INTERFERENCE & MITIGATION
  // ============================================================================

  Widget _buildAcInterferenceTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Overhead Transmission Line Hazard Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFF43F5E), size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ASEB 132kV & PowerGrid 220kV Overhead Line Corridor',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF43F5E),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Electromagnetic & Electrostatic Induction along Pipeline Right-of-Way (ROW)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Per NACE SP0177 & IEEE 80, steady-state induced AC touch voltage on exposed pipeline structures must not exceed 15.0 Volts RMS to prevent electric shock hazards to maintenance crews. For AC corrosion mitigation per ISO 18086 / EN 15280, coupon AC current density must remain under 30.0 A/m².',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Section Header: Decouplers
        _buildSectionHeader(
          title: 'Solid-State Decouplers (SSD / PCR) & Grounding Ribbon Status',
          subtitle:
              'DC isolation for CP retention + low-impedance AC discharge to zinc earthing',
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(height: 8),

        // SSD Cards
        ..._decouplerList.map((ssd) => _buildDecouplerCard(ssd)),

        const SizedBox(height: 14),
        // Mitigation Actions Protocol Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active AC Interference Mitigation Actions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildMitigationActionItem(
                step: '1',
                title: 'Parallel Zinc Ribbon Grounding Bed (Ch 8+150 to Ch 14+900)',
                desc:
                    'Continuous 12mm x 14mm ASTM B418 zinc ribbon earthing installed 0.5m adjacent to pipe in trench.',
                status: 'HEALTHY',
                statusColor: AppTheme.tertiary,
              ),
              _buildMitigationActionItem(
                step: '2',
                title: 'Solid-State Polarization Cells (PCR) Inspection',
                desc:
                    'Conducts AC fault currents (>100A peak) and induced AC currents to ground while blocking CP DC voltage.',
                status: 'CONVERTING AC',
                statusColor: AppTheme.primaryLight,
              ),
              _buildMitigationActionItem(
                step: '3',
                title: 'High-Speed Surge Diverters at Terminal IJs',
                desc:
                    'Gas discharge spark gaps (100kA 8/20µs) protect Duliajan and Digboi insulating monolithic joints from lightning flashover.',
                status: 'READY',
                statusColor: AppTheme.tertiary,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 38),
                ),
                icon: const Icon(Icons.flash_auto_rounded, size: 16),
                label: const Text(
                  'Run AC Induced Touch Potential Safety Audit',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                onPressed: _runAcSafetyAudit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDecouplerCard(SolidStateDecouplerRecord ssd) {
    final isCritical = ssd.inducedAcVoltsRms > 15.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCritical
              ? const Color(0xFFF43F5E).withValues(alpha: 0.6)
              : AppTheme.border,
          width: isCritical ? 1.5 : 1.0,
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
                  color: isCritical
                      ? const Color(0xFFF43F5E).withValues(alpha: 0.15)
                      : AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.electric_bolt_rounded,
                  color:
                      isCritical ? const Color(0xFFF43F5E) : AppTheme.primaryLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ssd.id} • ${ssd.makeModel}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Location: ${ssd.tlpRef} (${ssd.chainage})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCritical
                      ? const Color(0xFFF43F5E).withValues(alpha: 0.15)
                      : AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCritical ? 'ALERT: HIGH INDUCTION' : 'SAFE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isCritical
                        ? const Color(0xFFF43F5E)
                        : AppTheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildGaugeItem(
                  label: 'Induced AC Voltage',
                  value: '${ssd.inducedAcVoltsRms.toStringAsFixed(1)} V RMS',
                  rating: 'Touch Limit: 15V',
                  color: isCritical
                      ? const Color(0xFFF43F5E)
                      : AppTheme.primaryLight,
                ),
              ),
              Container(width: 1, height: 32, color: AppTheme.border),
              Expanded(
                child: _buildGaugeItem(
                  label: 'AC Discharged Current',
                  value:
                      '${ssd.acDischargeCurrentAmps.toStringAsFixed(1)} A AC',
                  rating: 'To Zinc Ribbon',
                  color: AppTheme.secondary,
                ),
              ),
              Container(width: 1, height: 32, color: AppTheme.border),
              Expanded(
                child: _buildGaugeItem(
                  label: 'DC Threshold',
                  value: '${ssd.dcBlockingThresholdVolts.toStringAsFixed(1)} V',
                  rating: 'CP Retained',
                  color: AppTheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMitigationActionItem({
    required String step,
    required String title,
    required String desc,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // INTERACTIVE MODALS & DIALOGS
  // ============================================================================

  void _showLogPspReadingDialog() {
    String selectedTlpId = _tlpSurveyList[0].id;
    final onController = TextEditingController(text: '-1150');
    final offController = TextEditingController(text: '-1020');
    final acVoltsController = TextEditingController(text: '3.2');
    final decayController = TextEditingController(text: '145');
    final inspectorController =
        TextEditingController(text: 'Subhash Bora (NACE CP-2)');
    final remarksController = TextEditingController(
        text: 'Routine quarterly potential survey with Cu/CuSO4 CSE reference electrode.');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentTlp =
                _tlpSurveyList.firstWhere((t) => t.id == selectedTlpId);
            final double onVal = double.tryParse(onController.text) ?? -1150;
            final double offVal = double.tryParse(offController.text) ?? -1020;
            final double acVal = double.tryParse(acVoltsController.text) ?? 3.2;
            final double irDropMv = (onVal - offVal).abs();

            // Live status check
            CpComplianceStatus liveStatus = CpComplianceStatus.compliant;
            if (acVal > 15.0) {
              liveStatus = CpComplianceStatus.acInterferenceAlert;
            } else if (offVal > -850.0) {
              liveStatus = CpComplianceStatus.underProtected;
            } else if (offVal < -1200.0) {
              liveStatus = CpComplianceStatus.overProtected;
            }

            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Row(
                children: [
                  const Icon(Icons.add_chart_rounded,
                      color: AppTheme.primaryLight, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Log Pipe-to-Soil Potential (PSP)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Select TLP
                      const Text(
                        'Select Test Lead Point (TLP)',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedTlpId,
                          dropdownColor: AppTheme.surfaceCard,
                          underline: const SizedBox(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          items: _tlpSurveyList.map((t) {
                            return DropdownMenuItem<String>(
                              value: t.id,
                              child: Text(
                                '${t.id} • ${t.chainageStr} (${t.name})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newVal) {
                            if (newVal != null) {
                              setDialogState(() {
                                selectedTlpId = newVal;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Location & Geotech details
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location: ${currentTlp.name} • ${currentTlp.chainageStr}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'GPS: ${currentTlp.latitude.toStringAsFixed(4)}°N, ${currentTlp.longitude.toStringAsFixed(4)}°E • Soil: ${currentTlp.soilResistivityOhmCm} Ω·cm',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Inputs Row: E_on, E_off
                      Row(
                        children: [
                          Expanded(
                            child: _buildDialogTextField(
                              label: 'On-Potential (mV CSE)',
                              controller: onController,
                              hint: '-1150',
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDialogTextField(
                              label: 'Instant-Off (mV CSE)',
                              controller: offController,
                              hint: '-1020',
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Inputs Row: Induced AC Volts, 100mV Decay
                      Row(
                        children: [
                          Expanded(
                            child: _buildDialogTextField(
                              label: 'Induced AC (Volts RMS)',
                              controller: acVoltsController,
                              hint: '3.2',
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDialogTextField(
                              label: '100mV Polarization Decay (mV)',
                              controller: decayController,
                              hint: '145',
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Inspector & Remarks
                      _buildDialogTextField(
                        label: 'NACE Certified Inspector',
                        controller: inspectorController,
                        hint: 'Subhash Bora (NACE CP-2)',
                      ),
                      const SizedBox(height: 10),
                      _buildDialogTextField(
                        label: 'Field Observations & Standard Notes',
                        controller: remarksController,
                        hint: 'Routine survey...',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      // Live Criterion Evaluation Preview
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: liveStatus.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: liveStatus.color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(liveStatus.icon,
                                color: liveStatus.color, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NACE SP0169 Status: ${liveStatus.label}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: liveStatus.color,
                                    ),
                                  ),
                                  Text(
                                    'IR Drop: ${irDropMv.toStringAsFixed(0)} mV • ${liveStatus == CpComplianceStatus.compliant ? "Polarized Instant-Off is within safe -850mV to -1200mV criterion." : liveStatus == CpComplianceStatus.underProtected ? "FAIL: Insufficient cathodic current. Pipe susceptible to corrosion." : liveStatus == CpComplianceStatus.overProtected ? "WARN: Over-protection. Risk of hydrogen damage & coating disbondment." : "CRITICAL: AC induced voltage exceeds 15V safety threshold."}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.textSecondary,
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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  onPressed: () {
                    final newOn = double.tryParse(onController.text) ?? -1150.0;
                    final newOff =
                        double.tryParse(offController.text) ?? -1020.0;
                    final newAc =
                        double.tryParse(acVoltsController.text) ?? 3.2;
                    final newDecay =
                        double.tryParse(decayController.text) ?? 145.0;

                    setState(() {
                      final tlp = _tlpSurveyList
                          .firstWhere((t) => t.id == selectedTlpId);
                      tlp.onPotentialMv = newOn;
                      tlp.instantOffMv = newOff;
                      tlp.acInducedVoltsRms = newAc;
                      tlp.polarizationDecayMv = newDecay;
                      tlp.inspectorName = inspectorController.text;
                      tlp.remarks = remarksController.text;
                      tlp.lastSurveyDate = DateTime.now();
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.surfaceCard,
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppTheme.tertiary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Survey reading logged for $selectedTlpId successfully.',
                              style:
                                  const TextStyle(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Save Survey Log'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditReadingDialog(TlpRecord tlp) {
    final onController =
        TextEditingController(text: tlp.onPotentialMv.toStringAsFixed(0));
    final offController =
        TextEditingController(text: tlp.instantOffMv.toStringAsFixed(0));
    final acVoltsController =
        TextEditingController(text: tlp.acInducedVoltsRms.toStringAsFixed(1));
    final decayController = TextEditingController(
        text: tlp.polarizationDecayMv.toStringAsFixed(0));
    final remarksController = TextEditingController(text: tlp.remarks);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Text(
            'Update Potential Reading • ${tlp.id}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(
                label: 'On-Potential (mV CSE)',
                controller: onController,
                hint: '-1150',
              ),
              const SizedBox(height: 10),
              _buildDialogTextField(
                label: 'Instant-Off Potential (mV CSE)',
                controller: offController,
                hint: '-1020',
              ),
              const SizedBox(height: 10),
              _buildDialogTextField(
                label: 'Induced AC Voltage (V RMS)',
                controller: acVoltsController,
                hint: '2.5',
              ),
              const SizedBox(height: 10),
              _buildDialogTextField(
                label: '100mV Decay (mV)',
                controller: decayController,
                hint: '140',
              ),
              const SizedBox(height: 10),
              _buildDialogTextField(
                label: 'Field Remarks',
                controller: remarksController,
                hint: 'Remarks',
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                setState(() {
                  tlp.onPotentialMv =
                      double.tryParse(onController.text) ?? tlp.onPotentialMv;
                  tlp.instantOffMv =
                      double.tryParse(offController.text) ?? tlp.instantOffMv;
                  tlp.acInducedVoltsRms =
                      double.tryParse(acVoltsController.text) ??
                          tlp.acInducedVoltsRms;
                  tlp.polarizationDecayMv =
                      double.tryParse(decayController.text) ??
                          tlp.polarizationDecayMv;
                  tlp.remarks = remarksController.text;
                  tlp.lastSurveyDate = DateTime.now();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showTruCalibrationDialog(TruStationRecord tru) {
    final voltController = TextEditingController(
        text: tru.outputVoltageVolts.toStringAsFixed(1));
    final currentController = TextEditingController(
        text: tru.outputCurrentAmps.toStringAsFixed(1));
    TruOperatingMode selectedMode = tru.mode;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Row(
                children: [
                  const Icon(Icons.tune_rounded,
                      color: AppTheme.primaryLight, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Calibrate & Tune ${tru.id}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tru.name} (${tru.locationChainage})',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  // Operating Mode Selection
                  const Text('Operating Mode',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButton<TruOperatingMode>(
                      isExpanded: true,
                      value: selectedMode,
                      dropdownColor: AppTheme.surfaceCard,
                      underline: const SizedBox(),
                      items: TruOperatingMode.values.map((mode) {
                        return DropdownMenuItem<TruOperatingMode>(
                          value: mode,
                          child: Text(mode.label,
                              style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (newMode) {
                        if (newMode != null) {
                          setDialogState(() {
                            selectedMode = newMode;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDialogTextField(
                    label: 'Output DC Voltage (V)',
                    controller: voltController,
                    hint: '28.4',
                  ),
                  const SizedBox(height: 10),
                  _buildDialogTextField(
                    label: 'Output DC Current (A)',
                    controller: currentController,
                    hint: '14.8',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary),
                  onPressed: () {
                    setState(() {
                      tru.outputVoltageVolts =
                          double.tryParse(voltController.text) ??
                              tru.outputVoltageVolts;
                      tru.outputCurrentAmps =
                          double.tryParse(currentController.text) ??
                              tru.outputCurrentAmps;
                      tru.mode = selectedMode;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.surfaceCard,
                        content: Text(
                          '${tru.id} setpoints updated to ${tru.outputVoltageVolts}V / ${tru.outputCurrentAmps}A.',
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      ),
                    );
                  },
                  child: const Text('Apply Tuning'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInterrupterSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: const Row(
                children: [
                  Icon(Icons.sync_rounded,
                      color: AppTheme.tertiary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'GPS Current Interrupter Sync',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Synchronize all 4 Transformer Rectifier Units (TRU-01 to TRU-04) via GPS master clocks to capture IR-free instant-off potential across the entire 34.8 km pipeline corridor.',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Synchronous Interruption',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _isInterrupterActive
                          ? 'Active (4 TRUs synchronized via GPS)'
                          : 'Inactive (Continuous DC Current)',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                    value: _isInterrupterActive,
                    activeThumbColor: AppTheme.tertiary,
                    onChanged: (val) {
                      setDialogState(() {
                        _isInterrupterActive = val;
                      });
                      setState(() {
                        _isInterrupterActive = val;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Interrupter Cycle Timing',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _interrupterCycle,
                      dropdownColor: AppTheme.surfaceCard,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: '4s ON / 1s OFF',
                          child: Text('4.0s ON / 1.0s OFF (Standard NACE CIPS)'),
                        ),
                        DropdownMenuItem(
                          value: '8s ON / 2s OFF',
                          child: Text('8.0s ON / 2.0s OFF (Deep Well High-Inertia)'),
                        ),
                        DropdownMenuItem(
                          value: '3s ON / 0.2s OFF',
                          child: Text('3.0s ON / 0.2s OFF (Fast Pulse DCVG)'),
                        ),
                      ],
                      onChanged: (newCycle) {
                        if (newCycle != null) {
                          setDialogState(() {
                            _interrupterCycle = newCycle;
                          });
                          setState(() {
                            _interrupterCycle = newCycle;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _runAcSafetyAudit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: AppTheme.tertiary, size: 20),
            SizedBox(width: 8),
            Text(
              'AC Touch Potential Safety Audit',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AUDIT REPORT PER NACE SP0177 / IEEE 80 / OISD-141:',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryLight),
            ),
            SizedBox(height: 8),
            Text(
              '• Parallel Span: Ch 8+150 to Ch 14+900 (ASEB 132kV Double Circuit)\n'
              '• Max Induced Touch Voltage: 18.5V RMS at TLP-08 (Warning: Exceeds 15V steady-state threshold)\n'
              '• Decouplers Conduction: SSD-01 & SSD-02 carrying 4.2A & 6.8A AC harmlessly to zinc groundbed.\n'
              '• Recommended Action: Install supplementary 30m zinc ribbon grounding at TLP-08 Tingrai HDD entry point to depress touch potential under 10V RMS.',
              style: TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }

  void _showAuditDossierDialog() {
    // Generate SHA-256 integrity hash for dossier
    final payload =
        'OIL-CP-AUDIT-${DateTime.now().toIso8601String()}-${_tlpSurveyList.length}-POINTS';
    final hashDigest = sha256.convert(utf8.encode(payload)).toString();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'NACE SP0169 Audit Dossier Export',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Corridor Cathodic Protection & Corrosion Integrity Dossier',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pipeline: Oil India Ltd 18" Duliajan to Digboi Corridor (34.8 km)\nStandard: NACE SP0169-2013 / ISO 15589-1 / OISD-STD-141',
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• Survey Points: ${_tlpSurveyList.length} Test Lead Points',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '• Compliance Rate: ${_complianceRate.toStringAsFixed(1)}% ($_compliantCount points compliant)',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.tertiary),
                    ),
                    Text(
                      '• TRU Stations: 4 Units (${_totalTruAmps.toStringAsFixed(1)}A Total Drainage)',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '• AC Alerts: $_acAlertCount points flagged for mitigation',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFF43F5E)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SHA-256 Audit Signature: $hashDigest',
                      style: const TextStyle(
                          fontSize: 8,
                          fontFamily: 'monospace',
                          color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Export Cryptographic Dossier'),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.surfaceCard,
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppTheme.tertiary, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'NACE SP0169 Audit Dossier PDF & CSV successfully exported.',
                            style: TextStyle(color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            filled: true,
            fillColor: AppTheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
