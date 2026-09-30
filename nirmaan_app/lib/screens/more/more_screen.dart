import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../ai/gemini_brain_screen.dart';
import '../ai/institutional_memory_screen.dart';
import '../ai/risk_radar_screen.dart';
import '../ai/voice_assistant_screen.dart';
import '../analytics/evm_dashboard_screen.dart';
import '../audit/audit_screen.dart';
import '../conflicts/conflicts_screen.dart';
import '../contracts/variation_order_screen.dart';
import '../contracts/liquidated_damages_screen.dart';
import '../contracts/dispute_adjudication_screen.dart';
import '../diary/site_diary_screen.dart';
import '../documents/documents_screen.dart';
import '../documents/pdf_intelligence_screen.dart';
import '../equipment/equipment_tracking_screen.dart';
import '../hse/safety_management_screen.dart';
import '../safety/scaffolding_inspection_screen.dart';
import '../safety/ptw_live_screen.dart';
import '../safety/erdmp_screen.dart';
import '../safety/flare_radiation_screen.dart';
import '../safety/environmental_compliance_screen.dart';
import '../safety/incident_rca_screen.dart';
import '../linking/linking_bridge_screen.dart';
import '../materials/materials_screen.dart';
import '../materials/qr_material_scanner_screen.dart';
import '../materials/weighbridge_ticket_screen.dart';
import '../ai/dialect_speech_tuner_screen.dart';
import '../reports/executive_report_screen.dart';
import '../schedule/wbs_gantt_screen.dart';
import '../settings/gemini_keys_screen.dart';
import '../settings/settings_screen.dart';
import '../portal/stakeholder_portal_screen.dart';
import '../weather/weather_impact_screen.dart';
import '../workforce/contractor_scorecard_screen.dart';
import '../workforce/hr_module_screen.dart';
import '../workforce/supervisor_visit_screen.dart';
import '../map/digital_twin_site_map_screen.dart';
import '../quality/pipeline_ndt_screen.dart';
import '../quality/golden_weld_certification_screen.dart';
import '../quality/hydrotesting_screen.dart';
import '../quality/welder_qualification_screen.dart';
import '../quality/aut_phased_array_screen.dart';
import '../engineering/soil_strata_log_screen.dart';
import '../engineering/hdd_crossing_profile_screen.dart';
import '../engineering/hdd_crossing_screen.dart';
import '../engineering/geohazard_monitoring_screen.dart';
import '../engineering/rou_land_acquisition_screen.dart';
import '../engineering/strain_gauge_monitoring_screen.dart';
import '../operations/commissioning_punchlist_screen.dart';
import '../operations/custody_metering_screen.dart';
import '../operations/compressor_station_screen.dart';
import '../operations/gas_in_commissioning_screen.dart';
import '../operations/scada_telemetry_screen.dart';
import '../operations/scada_cybersecurity_screen.dart';
import '../integrity/cathodic_protection_screen.dart';
import '../integrity/soil_resistivity_screen.dart';
import '../operations/gas_chromatography_screen.dart';
import '../integrity/pipeline_pigging_screen.dart';
import '../integrity/pims_risk_screen.dart';
import '../integrity/field_joint_coating_screen.dart';
import '../operations/drone_row_surveillance_screen.dart';
import '../procurement/pipe_heat_tally_screen.dart';
import '../finance/gas_sales_settlement_screen.dart';
import '../finance/measurement_book_screen.dart';
import '../operations/chemical_injection_screen.dart';
import '../operations/telecom_ofc_screen.dart';
import '../operations/hot_tap_stopple_screen.dart';
import '../operations/meter_prover_screen.dart';
import '../operations/dewatering_drying_screen.dart';
import '../integrity/cips_dcvg_screen.dart';

class _MenuItemConfig {
  final String label;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color color;
  final Widget screen;
  final String? badge;

  const _MenuItemConfig({
    required this.label,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.color,
    required this.screen,
    this.badge,
  });
}

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  static const List<_MenuItemConfig> _allMenuItems = [
    // Valve Station SCADA & Remote Telemetry
    _MenuItemConfig(
      label: 'SCADA Telemetry',
      subtitle: 'VS-01 to VS-08, ESDV & LDS leak monitoring',
      category: 'Field & Operations',
      icon: Icons.settings_input_composite_rounded,
      color: Color(0xFF0284C7),
      screen: ScadaTelemetryScreen(),
      badge: 'SCADA LIVE',
    ),
    // SCADA RTU & Industrial Cyber-Security (IEC 62443 / CERT-In)
    _MenuItemConfig(
      label: 'SCADA Cyber-Security',
      subtitle: 'IEC 62443, DPI 0x05 blocking & MitM defense',
      category: 'Field & Operations',
      icon: Icons.shield_rounded,
      color: Color(0xFF00E5FF),
      screen: ScadaCybersecurityScreen(),
      badge: 'IEC 62443',
    ),
    // Pipeline Right-of-Way (RoW) Encroachment & Drone Surveillance
    _MenuItemConfig(
      label: 'RoW Drone Surveillance',
      subtitle: 'Corridor encroachment, thermal IR theft & QRT patrol',
      category: 'Field & Operations',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF38BDF8),
      screen: DroneRowSurveillanceScreen(),
      badge: '194.5 KM',
    ),
    // Custody Transfer Ultrasonic Flow Metering & Prover Skid
    _MenuItemConfig(
      label: 'Custody Metering Skid',
      subtitle: 'AGA-9 Ultrasonic & API Bi-Directional Prover',
      category: 'Field & Operations',
      icon: Icons.speed_rounded,
      color: Color(0xFF0284C7),
      screen: CustodyMeteringScreen(),
      badge: 'AGA-9 / API',
    ),
    // Compressor Station Telemetry & Anti-Surge Control
    _MenuItemConfig(
      label: 'Compressor Stations',
      subtitle: 'Centrifugal trains, anti-surge & vibration telemetry',
      category: 'Field & Operations',
      icon: Icons.compress_rounded,
      color: Color(0xFF38BDF8),
      screen: CompressorStationScreen(),
      badge: 'ISO-10816',
    ),
    // Gas Chromatography & Natural Gas Quality Billing
    _MenuItemConfig(
      label: 'Gas Chromatography & Billing',
      subtitle: 'ISO 6974 / GPA 2261, GCV/NCV & MMBTU tariff',
      category: 'Field & Operations',
      icon: Icons.biotech_rounded,
      color: Color(0xFF38BDF8),
      screen: GasChromatographyScreen(),
      badge: 'ISO 6974',
    ),
    // Chemical Injection & Corrosion Inhibitor Dosing Skid
    _MenuItemConfig(
      label: 'Chemical Injection Skid',
      subtitle: 'NACE MR0175 / OISD-141 dosing & ER probe monitoring',
      category: 'Field & Operations',
      icon: Icons.science_rounded,
      color: Color(0xFF0284C7),
      screen: ChemicalInjectionScreen(),
      badge: 'NACE / OISD',
    ),
    // Pipeline Optical Fiber Backbone & SDH STM-4 Telecom
    _MenuItemConfig(
      label: 'Telecom & OFC Backbone',
      subtitle: '24-Core OFC, OTDR telemetry, SDH STM-4 & Repeater Solar/DG',
      category: 'Field & Operations',
      icon: Icons.settings_ethernet_rounded,
      color: Color(0xFF38BDF8),
      screen: TelecomOfcScreen(),
      badge: 'STM-4 / OTDR',
    ),
    // Pressurized Hot Tapping & Line Plugging (Stopple)
    _MenuItemConfig(
      label: 'Hot Tapping & Stopple',
      subtitle: 'ASME B31.8 / API RP 2201 pressurized tap, Battelle & LOR plug',
      category: 'Field & Operations',
      icon: Icons.precision_manufacturing_rounded,
      color: Color(0xFFFFB95F),
      screen: HotTapStoppleScreen(),
      badge: 'API 2201',
    ),
    // Gas Meter Prover & Skid Calibration Laboratory
    _MenuItemConfig(
      label: 'Meter Prover & Calibration',
      subtitle: 'AGA-7 / API MPMS 4 custody transfer & double chronometry',
      category: 'Field & Operations',
      icon: Icons.sync_alt_rounded,
      color: Color(0xFF0284C7),
      screen: MeterProverScreen(),
      badge: 'AGA-7 / API 4',
    ),
    // Pipeline De-watering, Swabbing & Air/Nitrogen Drying (ASME B31.8 / OISD-141)
    _MenuItemConfig(
      label: 'De-watering & Drying',
      subtitle: 'ASME B31.8 / OISD-141 disc pigs, swabbing & -40°C ADP soak',
      category: 'Field & Operations',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0284C7),
      screen: DewateringDryingScreen(),
      badge: 'ASME B31.8',
    ),
    // Digital Twin 3D / Isometric GIS Site Map
    _MenuItemConfig(
      label: 'Digital Twin 3D',
      subtitle: 'Oil India Duliajan GIS & 3D layout',
      category: 'Field & Operations',
      icon: Icons.view_in_ar_rounded,
      color: Color(0xFF38BDF8),
      screen: DigitalTwinSiteMapScreen(),
      badge: '3D GIS',
    ),
    // Soil Strata & Pipeline Trenching Geotechnical Log
    _MenuItemConfig(
      label: 'Soil Strata Log',
      subtitle: 'Trenching strata & OISD-141 cover',
      category: 'Field & Operations',
      icon: Icons.terrain_rounded,
      color: Color(0xFF8D6E63),
      screen: SoilStrataLogScreen(),
      badge: 'OISD-141',
    ),
    // HDD River Crossing Geometry & Steering Profile
    _MenuItemConfig(
      label: 'HDD River Crossing',
      subtitle: 'Burhi Dihing steering & pullback load',
      category: 'Field & Operations',
      icon: Icons.swap_horiz_rounded,
      color: Color(0xFFFFB95F),
      screen: HddCrossingProfileScreen(),
      badge: '1450m HDD',
    ),
    // HDD River & Highway Crossing Engineering (ASME B31.8 / API RP 1111)
    _MenuItemConfig(
      label: 'HDD Crossing Engineering',
      subtitle: 'ASME B31.8 / API RP 1111 trenchless telemetry',
      category: 'Field & Operations',
      icon: Icons.alt_route_rounded,
      color: Color(0xFF0284C7),
      screen: HddCrossingScreen(),
      badge: 'API RP 1111',
    ),
    // Slope Stability & Geohazard Early Warning System
    _MenuItemConfig(
      label: 'Geohazard Monitoring',
      subtitle: 'Inclinometers, bathymetric scour & seismic PGA',
      category: 'Field & Operations',
      icon: Icons.landslide_rounded,
      color: Color(0xFFF59E0B),
      screen: GeohazardMonitoringScreen(),
      badge: 'EARLY WARN',
    ),
    // Cadastral Land Acquisition (RoU) under P&MP Act, 1962 & LiDAR Alignment
    _MenuItemConfig(
      label: 'Land Acquisition (RoU)',
      subtitle: 'P&MP Act 1962, Cadastral Dags & Crop Compensation',
      category: 'Field & Operations',
      icon: Icons.map_rounded,
      color: Color(0xFF38BDF8),
      screen: RouLandAcquisitionScreen(),
      badge: 'P&MP ACT',
    ),
    // Pipeline Strain Gauge & Riverbank Bending Stress (ASME B31.8 / PRCI)
    _MenuItemConfig(
      label: 'Pipeline Strain Gauges',
      subtitle: 'ASME B31.8 / PRCI 3-axis rosettes & riverbank bending stress',
      category: 'Field & Operations',
      icon: Icons.stacked_line_chart_rounded,
      color: Color(0xFF38BDF8),
      screen: StrainGaugeMonitoringScreen(),
      badge: 'ASME B31.8',
    ),
    // Pre-Commissioning Walkdown & Punch List Management
    _MenuItemConfig(
      label: 'Commissioning Punch List',
      subtitle: 'Walkdown, Cat A/B/C & N2 purge holds',
      category: 'Field & Operations',
      icon: Icons.checklist_rtl_rounded,
      color: Color(0xFF38BDF8),
      screen: CommissioningPunchlistScreen(),
      badge: 'Cat A Hold',
    ),
    // Gas-In & Hydrocarbon Commissioning
    _MenuItemConfig(
      label: 'Gas-In Commissioning',
      subtitle: 'N2 purge, flare telemetry & gas-in holds',
      category: 'Field & Operations',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFFB95F),
      screen: GasInCommissioningScreen(),
      badge: 'OISD-141',
    ),
    // Weather & Environmental Intelligence
    _MenuItemConfig(
      label: 'Weather Impact',
      subtitle: 'Monsoon telemetry & alerts',
      category: 'Field & Operations',
      icon: Icons.thunderstorm_rounded,
      color: Color(0xFF00E5FF),
      screen: WeatherImpactScreen(),
      badge: 'LIVE',
    ),
    // EVM & Cost Analytics
    _MenuItemConfig(
      label: 'EVM Analytics',
      subtitle: 'Earned Value & SPI/CPI',
      category: 'Intelligence',
      icon: Icons.analytics_rounded,
      color: Color(0xFFA78BFA),
      screen: EvmDashboardScreen(),
      badge: 'S-Curve',
    ),
    // Heavy Equipment & Telematics
    _MenuItemConfig(
      label: 'Equipment Tracking',
      subtitle: 'Heavy plant telemetry & fuel',
      category: 'Field & Operations',
      icon: Icons.precision_manufacturing_rounded,
      color: Color(0xFFFBBF24),
      screen: EquipmentTrackingScreen(),
      badge: 'IoT',
    ),
    // AI Risk Radar
    _MenuItemConfig(
      label: 'AI Risk Radar',
      subtitle: 'Monte Carlo schedule simulations',
      category: 'Intelligence',
      icon: Icons.radar_rounded,
      color: Color(0xFFFF5252),
      screen: RiskRadarScreen(),
      badge: 'AI',
    ),
    // Institutional Memory AI Query Engine
    _MenuItemConfig(
      label: 'Institutional Memory',
      subtitle: 'Historical Oil India lessons (2018-2025)',
      category: 'Intelligence',
      icon: Icons.history_edu_rounded,
      color: Color(0xFF4EDEA3),
      screen: InstitutionalMemoryScreen(),
      badge: '2018-25',
    ),
    // Executive Progress Dossier & PDF Export
    _MenuItemConfig(
      label: 'Executive Report',
      subtitle: 'PDF dossier, health index & export',
      category: 'Governance',
      icon: Icons.picture_as_pdf_rounded,
      color: Color(0xFF38BDF8),
      screen: ExecutiveReportScreen(),
      badge: 'PDF',
    ),
    // Contractor & Gang Scorecard
    _MenuItemConfig(
      label: 'Contractor Scorecard',
      subtitle: 'Live ratings & PQ intelligence',
      category: 'Governance',
      icon: Icons.leaderboard_rounded,
      color: Color(0xFF38BDF8),
      screen: ContractorScorecardScreen(),
      badge: 'FIDIC',
    ),
    // Multi-Stakeholder Collaboration Portal
    _MenuItemConfig(
      label: 'Stakeholder Portal',
      subtitle: 'Client, EPC, TPIA & Foreman Hub',
      category: 'Governance',
      icon: Icons.hub_rounded,
      color: Color(0xFF38BDF8),
      screen: StakeholderPortalScreen(),
      badge: '4-TIER',
    ),
    // FIDIC Clause 13 Variations & Change Orders
    _MenuItemConfig(
      label: 'FIDIC Cl. 13 Variations',
      subtitle: 'Scope change & variation register',
      category: 'Governance',
      icon: Icons.published_with_changes_rounded,
      color: Color(0xFFFFB95F),
      screen: VariationOrderScreen(),
      badge: 'Cl. 13',
    ),
    // FIDIC Sub-Clause 8.7 Delay Damages & Liquidated Damages Calculator
    _MenuItemConfig(
      label: 'FIDIC Cl. 8.7 Delay Damages',
      subtitle: 'Liquidated damages & concurrency offset',
      category: 'Governance',
      icon: Icons.gavel_rounded,
      color: Color(0xFFEF4444),
      screen: LiquidatedDamagesScreen(),
      badge: 'Cl. 8.7',
    ),
    // FIDIC Clause 20 Dispute Adjudication Board (DAB) & Arbitration Claims
    _MenuItemConfig(
      label: 'FIDIC Cl. 20 DAB & Claims',
      subtitle: 'Dispute board, dossiers & Cl. 14.8 interest',
      category: 'Governance',
      icon: Icons.balance_rounded,
      color: Color(0xFF38BDF8),
      screen: DisputeAdjudicationScreen(),
      badge: 'Cl. 20',
    ),
    // Gas Sales Agreement (GSA) & Custody Settlement
    _MenuItemConfig(
      label: 'GSA & Custody Settlement',
      subtitle: 'PNGRB tariff, ToP 90% & imbalance cash-out',
      category: 'Governance',
      icon: Icons.request_quote_rounded,
      color: Color(0xFFFFB95F),
      screen: GasSalesSettlementScreen(),
      badge: 'PNGRB/ToP',
    ),
    // Contractor Progress Billing & Tripartite e-MB Ledger (CPWD Form 23/26)
    _MenuItemConfig(
      label: 'e-MB & Progress Billing',
      subtitle: 'CPWD Form 23/26, tripartite sign & RA bill',
      category: 'Governance',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF38BDF8),
      screen: MeasurementBookScreen(),
      badge: 'CPWD / OIL',
    ),
    // FIDIC Site Diary
    _MenuItemConfig(
      label: 'FIDIC Site Diary',
      subtitle: 'Cl. 4.20 cryptographic log',
      category: 'Field & Operations',
      icon: Icons.menu_book_rounded,
      color: Color(0xFFFFB95F),
      screen: SiteDiaryScreen(),
      badge: 'SHA-256',
    ),
    // WBS L1-L6 Interactive Gantt & Timeline Cascade
    _MenuItemConfig(
      label: 'WBS Gantt Cascade',
      subtitle: 'L1–L6 Primavera P6 critical path',
      category: 'Field & Operations',
      icon: Icons.account_tree_rounded,
      color: Color(0xFF38BDF8),
      screen: WbsGanttScreen(),
      badge: 'L1-L6',
    ),
    // HSE Safety Management
    _MenuItemConfig(
      label: 'HSE Safety',
      subtitle: 'Digital permits & incident logs',
      category: 'Field & Operations',
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFF4EDEA3),
      screen: SafetyManagementScreen(),
      badge: 'Zero LTI',
    ),
    // Scaffolding & Heavy Rigging Safety Inspection
    _MenuItemConfig(
      label: 'Scaffolding & Rigging',
      subtitle: 'IS 3696 tags, SWL & 7-day re-inspection',
      category: 'Field & Operations',
      icon: Icons.construction_rounded,
      color: Color(0xFF0284C7),
      screen: ScaffoldingInspectionScreen(),
      badge: 'IS 3696',
    ),
    // Permit to Work (PTW) Live Management
    _MenuItemConfig(
      label: 'Permit to Work (PTW)',
      subtitle: 'OISD-105 live permits, gas tests & LOTO',
      category: 'Field & Operations',
      icon: Icons.assignment_turned_in_rounded,
      color: Color(0xFF10B981),
      screen: PtwLiveScreen(),
      badge: 'OISD-105',
    ),
    // Emergency Response & Disaster Management Plan (PNGRB ERDMP / OISD-GDN-166)
    _MenuItemConfig(
      label: 'Disaster Plan (ERDMP)',
      subtitle: 'PNGRB 3-Tier, ALOHA Plume & Call Tree',
      category: 'Field & Operations',
      icon: Icons.crisis_alert_rounded,
      color: Color(0xFFEF4444),
      screen: ErdmpScreen(),
      badge: 'ERDMP',
    ),
    // Flare Stack & Thermal Radiation Monitoring (API 521 / OISD-106)
    _MenuItemConfig(
      label: 'Flare & Radiation Contours',
      subtitle: 'API 521 thermal zones, pilot array & KO drum',
      category: 'Field & Operations',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFEF4444),
      screen: FlareRadiationScreen(),
      badge: 'API 521',
    ),
    // Statutory Environmental Clearance & MoEFCC Compliance (FCA 1980 / PCBA)
    _MenuItemConfig(
      label: 'MoEFCC Enviro Compliance',
      subtitle: 'EC Cat-A, PCBA CTE/CTO, FCA 28.4ha & CAAQMS',
      category: 'Field & Operations',
      icon: Icons.eco_rounded,
      color: Color(0xFF4EDEA3),
      screen: EnvironmentalComplianceScreen(),
      badge: 'MoEFCC/PCBA',
    ),
    // Statutory Incident Investigation & Root Cause Analysis (OISD-GDN-107 / DGMS)
    _MenuItemConfig(
      label: 'Incident Investigation & RCA',
      subtitle: 'OISD-GDN-107 / DGMS 5-Whys, Ishikawa & CAPA',
      category: 'Field & Operations',
      icon: Icons.biotech_rounded,
      color: Color(0xFFEF4444),
      screen: IncidentRcaScreen(),
      badge: 'OISD-107',
    ),
    // Materials Management
    _MenuItemConfig(
      label: 'Materials',
      subtitle: 'GRN & GIN stock ledger',
      category: 'Field & Operations',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFFFB923C),
      screen: MaterialsScreen(),
    ),
    // Material QR & Barcode Scanner
    _MenuItemConfig(
      label: 'Material Tag Scanner',
      subtitle: 'Laser QR/Barcode QA & GRN/GIN',
      category: 'Field & Operations',
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFF38BDF8),
      screen: QrMaterialScannerScreen(),
      badge: 'LIVE QA',
    ),
    // Material Weighbridge & Delivery Challan Verification
    _MenuItemConfig(
      label: 'Weighbridge & DC Verify',
      subtitle: 'Gate pass, Net weight & 1-tap GRN',
      category: 'Field & Operations',
      icon: Icons.scale_rounded,
      color: Color(0xFFFFB95F),
      screen: WeighbridgeTicketScreen(),
      badge: '±1.5% TOL',
    ),
    // API 5L PSL-2 Pipe Heat Tally & Material Traceability
    _MenuItemConfig(
      label: 'Pipe Heat Tally',
      subtitle: 'API 5L PSL-2 MTC 3.2, chainage & pup piece tally',
      category: 'Field & Operations',
      icon: Icons.view_column_rounded,
      color: Color(0xFF38BDF8),
      screen: PipeHeatTallyScreen(),
      badge: 'API 5L',
    ),
    // Pipeline Weld NDT & Hydrostatic Testing
    _MenuItemConfig(
      label: 'Pipeline NDT & Hydrotest',
      subtitle: 'Radiography, UT/MPT & 112.5 Bar test',
      category: 'Field & Operations',
      icon: Icons.speed_rounded,
      color: Color(0xFF4EDEA3),
      screen: PipelineNdtScreen(),
      badge: '18" X70',
    ),
    // Golden Weld & Tie-In Certification (OISD-141 / ASME B31.8)
    _MenuItemConfig(
      label: 'Golden Weld Certification',
      subtitle: 'OISD-141 Tie-in, 100% NDE & Exemption',
      category: 'Field & Operations',
      icon: Icons.verified_rounded,
      color: Color(0xFFFFB95F),
      screen: GoldenWeldCertificationScreen(),
      badge: 'OISD-141',
    ),
    // Welder Performance Qualification & WPS Registry (API 1104 / ASME IX)
    _MenuItemConfig(
      label: 'Welder & WPS Registry',
      subtitle: 'API 1104 / ASME IX WPQ roster, repair KPI & WPS',
      category: 'Field & Operations',
      icon: Icons.badge_rounded,
      color: Color(0xFF0284C7),
      screen: WelderQualificationScreen(),
      badge: 'API 1104',
    ),
    // Automated Ultrasonic Testing (AUT) Phased Array & TOFD (ASTM E1961 / API 1104 Annex A)
    _MenuItemConfig(
      label: 'AUT Phased Array & TOFD',
      subtitle: 'ASTM E1961 Zonal Discrimination, S-scan & TOFD ±0.3mm',
      category: 'Field & Operations',
      icon: Icons.radar_rounded,
      color: Color(0xFF0284C7),
      screen: AutPhasedArrayScreen(),
      badge: 'ASTM E1961',
    ),
    // Pipeline Hydrostatic Testing & Dewatering (ASME B31.8 / OISD-141)
    _MenuItemConfig(
      label: 'Pipeline Hydrotesting',
      subtitle: 'ASME B31.8 112.5 Bar test, P/V plot & dew point',
      category: 'Field & Operations',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0284C7),
      screen: HydrotestingScreen(),
      badge: '112.5 BAR',
    ),
    // Field Joint Anticorrosion Coating (FJC) & Holiday Inspection
    _MenuItemConfig(
      label: 'Field Joint Coating (FJC)',
      subtitle: 'NACE SP0188 / DIN 30670, Sa 2.5, HV Spark & Peel',
      category: 'Field & Operations',
      icon: Icons.layers_outlined,
      color: Color(0xFFFFB95F),
      screen: FieldJointCoatingScreen(),
      badge: 'NACE SP0188',
    ),
    // Cathodic Protection & Pipeline Corrosion Integrity
    _MenuItemConfig(
      label: 'Cathodic Protection (CP)',
      subtitle: 'NACE SP0169, 24 TLPs, ICCP & AC stray',
      category: 'Field & Operations',
      icon: Icons.shield_rounded,
      color: Color(0xFF38BDF8),
      screen: CathodicProtectionScreen(),
      badge: 'NACE',
    ),
    // Cathodic Protection Anode Bed Replenishment & Soil Resistivity
    _MenuItemConfig(
      label: 'Soil Resistivity & Anode Bed',
      subtitle: 'ASTM G57 Wenner 4-pin & DWICG groundbed telemetry',
      category: 'Field & Operations',
      icon: Icons.layers_rounded,
      color: Color(0xFF4EDEA3),
      screen: SoilResistivityScreen(),
      badge: 'ASTM G57',
    ),
    // Cathodic Protection Close Interval Potential Survey (CIPS) & DCVG
    _MenuItemConfig(
      label: 'CIPS & DCVG Survey',
      subtitle: 'NACE TM0497 / SP0207, GPS 0.8s/0.2s, %IR defect & -850mV',
      category: 'Field & Operations',
      icon: Icons.stacked_line_chart_rounded,
      color: Color(0xFF38BDF8),
      screen: CipsDcvgScreen(),
      badge: 'NACE ECDA',
    ),
    // Intelligent Pipeline Pigging & ILI In-Line Inspection
    _MenuItemConfig(
      label: 'Pipeline Pigging & ILI',
      subtitle: 'MFL/UT anomaly tracking & ASME B31G',
      category: 'Field & Operations',
      icon: Icons.precision_manufacturing_rounded,
      color: Color(0xFF4EDEA3),
      screen: PipelinePiggingScreen(),
      badge: 'ASME B31G',
    ),
    // Pipeline Integrity Management System (PIMS) Risk & Remnant Life
    _MenuItemConfig(
      label: 'PIMS Risk & Remnant Life',
      subtitle: 'ASME B31.8S / API 1160 QRA, 5x5 Matrix & Dig Schedule',
      category: 'Field & Operations',
      icon: Icons.security_rounded,
      color: Color(0xFF0284C7),
      screen: PimsRiskScreen(),
      badge: 'B31.8S QRA',
    ),
    // Contractual Conflicts
    _MenuItemConfig(
      label: 'Conflicts',
      subtitle: 'Dispute detection & triage',
      category: 'Governance',
      icon: Icons.gavel_rounded,
      color: Color(0xFFF43F5E),
      screen: ConflictsScreen(),
    ),
    // Tamper-Proof Audit Trail
    _MenuItemConfig(
      label: 'Audit Trail',
      subtitle: 'Immutable system change-logs',
      category: 'Governance',
      icon: Icons.history_rounded,
      color: Color(0xFF60A5FA),
      screen: AuditScreen(),
    ),
    // AI Brain
    _MenuItemConfig(
      label: 'AI Brain',
      subtitle: 'Gemini NLP copilot & triangulation',
      category: 'Intelligence',
      icon: Icons.psychology_rounded,
      color: Color(0xFFC084FC),
      screen: GeminiBrainScreen(),
      badge: 'Gemini',
    ),
    // Multilingual Voice Assistant
    _MenuItemConfig(
      label: 'Voice Assistant',
      subtitle: '10 Indic dialect site assistant',
      category: 'Intelligence',
      icon: Icons.mic_rounded,
      color: Color(0xFF34D399),
      screen: VoiceAssistantScreen(),
      badge: 'Indic',
    ),
    // Voice Dialect & Lexicon Tuner
    _MenuItemConfig(
      label: 'Dialect & Lexicon Tuner',
      subtitle: '5 Indic dialects, piping jargon & acoustic tuner',
      category: 'Intelligence',
      icon: Icons.tune_rounded,
      color: Color(0xFF38BDF8),
      screen: DialectSpeechTunerScreen(),
      badge: 'Bhashini',
    ),
    // PDF Intelligence
    _MenuItemConfig(
      label: 'PDF Intelligence',
      subtitle: 'OCR entity extraction & specs',
      category: 'Intelligence',
      icon: Icons.picture_as_pdf_rounded,
      color: Color(0xFFF87171),
      screen: PdfIntelligenceScreen(),
    ),
    // Project Documents & Engineering Drawings
    _MenuItemConfig(
      label: 'Documents',
      subtitle: 'Drawings, contracts & ITP specs',
      category: 'Field & Operations',
      icon: Icons.folder_rounded,
      color: Color(0xFFFBBF24),
      screen: DocumentsScreen(),
      badge: 'CAD/PDF',
    ),
    // Linking Bridge
    _MenuItemConfig(
      label: 'Linking Bridge',
      subtitle: 'P6 & BIM cross-link matching',
      category: 'Field & Operations',
      icon: Icons.hub_rounded,
      color: Color(0xFF2DD4BF),
      screen: LinkingBridgeScreen(),
    ),
    // Geofenced Supervisor Visits
    _MenuItemConfig(
      label: 'Supervisor Visit',
      subtitle: 'Geofenced spot checks & punchlist',
      category: 'Field & Operations',
      icon: Icons.visibility_rounded,
      color: Color(0xFF38BDF8),
      screen: SupervisorVisitScreen(),
    ),
    // HR & Labor Module
    _MenuItemConfig(
      label: 'HR Module',
      subtitle: 'Wages, attendance & biometric sync',
      category: 'Governance',
      icon: Icons.badge_rounded,
      color: Color(0xFF818CF8),
      screen: HrModuleScreen(),
    ),
    // Gemini Brain API Keys Architecture
    _MenuItemConfig(
      label: 'Gemini Brain Keys',
      subtitle: 'Multi-key AI allocation & quota tuning',
      category: 'Governance',
      icon: Icons.vpn_key_rounded,
      color: Color(0xFF38BDF8),
      screen: GeminiKeysScreen(),
      badge: 'Multi-Key',
    ),
    // System Settings
    _MenuItemConfig(
      label: 'Settings',
      subtitle: 'App preferences & language',
      category: 'Governance',
      icon: Icons.settings_rounded,
      color: Color(0xFF94A3B8),
      screen: SettingsScreen(),
    ),
  ];

  List<_MenuItemConfig> get _filteredItems {
    return _allMenuItems.where((item) {
      final matchesSearch = item.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedCategory == 'ALL') return true;
      return item.category == _selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Operations Suite',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Nirmaan OS Enterprise Modules',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Banner & Search Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Industrial Suite Overview Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(40),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.apps_rounded,
                            color: AppTheme.primaryLight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${_allMenuItems.length} ENTERPRISE MODULES',
                                    style: const TextStyle(
                                      color: AppTheme.primaryLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.tertiary.withAlpha(30),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ALL ONLINE',
                                      style: TextStyle(
                                        color: AppTheme.tertiary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Complete telemetry, analytics, FIDIC logs & safety control suite.',
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
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  TextField(
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search modules, telemetry, safety, analytics...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 16),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 10),
                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('ALL', 'All Modules (${_allMenuItems.length})'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Field & Operations', 'Field & Ops (${_allMenuItems.where((m) => m.category == 'Field & Operations').length})'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Intelligence', 'AI & Analytics (${_allMenuItems.where((m) => m.category == 'Intelligence').length})'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Governance', 'Governance (${_allMenuItems.where((m) => m.category == 'Governance').length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Modules Grid
          filtered.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off_rounded, color: AppTheme.textMuted, size: 40),
                        SizedBox(height: 12),
                        Text(
                          'No modules match your search',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.88,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filtered[index];
                        return _buildModuleCard(context, item);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String categoryKey, String label) {
    final isSelected = _selectedCategory == categoryKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedCategory = categoryKey);
        }
      },
      backgroundColor: AppTheme.surfaceCard,
      selectedColor: AppTheme.primary.withAlpha(50),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryLight : AppTheme.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildModuleCard(BuildContext context, _MenuItemConfig item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => item.screen),
          );
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: item.color.withAlpha(40),
        highlightColor: item.color.withAlpha(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border.withAlpha(160)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.color.withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: item.color.withAlpha(80)),
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  if (item.badge != null)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.badge!,
                          style: const TextStyle(
                            color: Color(0xFF0B1326),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
