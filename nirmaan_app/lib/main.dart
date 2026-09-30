import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/localization/language_controller.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';

import 'screens/app_shell.dart';
import 'screens/workforce/add_worker_screen.dart';
import 'screens/workforce/attendance_screen.dart';
import 'screens/workforce/clock_in_screen.dart';
import 'screens/workforce/supervisor_visit_screen.dart';
import 'screens/workforce/hr_module_screen.dart';
import 'screens/dpr/dpr_screen.dart';
import 'screens/materials/materials_screen.dart';
import 'screens/conflicts/conflicts_screen.dart';
import 'screens/audit/audit_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/ai/dialect_speech_tuner_screen.dart';
import 'screens/contracts/liquidated_damages_screen.dart';
import 'screens/contracts/dispute_adjudication_screen.dart';
import 'screens/map/digital_twin_site_map_screen.dart';
import 'screens/quality/concrete_pour_qa_screen.dart';
import 'screens/quality/golden_weld_certification_screen.dart';
import 'screens/quality/hydrotesting_screen.dart';
import 'screens/quality/welder_qualification_screen.dart';
import 'screens/quality/aut_phased_array_screen.dart';
import 'screens/engineering/hdd_crossing_profile_screen.dart';
import 'screens/engineering/hdd_crossing_screen.dart';
import 'screens/engineering/geohazard_monitoring_screen.dart';
import 'screens/engineering/rou_land_acquisition_screen.dart';
import 'screens/engineering/strain_gauge_monitoring_screen.dart';
import 'screens/operations/scada_telemetry_screen.dart';
import 'screens/integrity/cathodic_protection_screen.dart';
import 'screens/operations/commissioning_punchlist_screen.dart';
import 'screens/operations/custody_metering_screen.dart';
import 'screens/operations/compressor_station_screen.dart';
import 'screens/safety/scaffolding_inspection_screen.dart';
import 'screens/safety/ptw_live_screen.dart';
import 'screens/safety/flare_radiation_screen.dart';
import 'screens/safety/erdmp_screen.dart';
import 'screens/safety/environmental_compliance_screen.dart';
import 'screens/safety/incident_rca_screen.dart';
import 'screens/integrity/pipeline_pigging_screen.dart';
import 'screens/integrity/soil_resistivity_screen.dart';
import 'screens/operations/gas_chromatography_screen.dart';
import 'screens/operations/gas_in_commissioning_screen.dart';
import 'screens/operations/scada_cybersecurity_screen.dart';
import 'screens/operations/drone_row_surveillance_screen.dart';
import 'screens/integrity/pims_risk_screen.dart';
import 'screens/finance/gas_sales_settlement_screen.dart';
import 'screens/finance/measurement_book_screen.dart';
import 'screens/operations/chemical_injection_screen.dart';
import 'screens/procurement/pipe_heat_tally_screen.dart';
import 'screens/integrity/field_joint_coating_screen.dart';
import 'screens/operations/telecom_ofc_screen.dart';
import 'screens/operations/hot_tap_stopple_screen.dart';
import 'screens/operations/meter_prover_screen.dart';
import 'screens/operations/dewatering_drying_screen.dart';
import 'screens/integrity/cips_dcvg_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NirmaanApp());
}

class NirmaanApp extends StatelessWidget {
  const NirmaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: ListenableBuilder(
        listenable: LanguageController.instance,
        builder: (context, _) {
          return MaterialApp(
            title: 'Nirmaan OS',
            locale: LanguageController.instance.currentLocale,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const SplashScreen(),
            routes: {
              '/app_shell': (context) => const AppShell(),
              '/add_worker': (context) => const AddWorkerScreen(),
              '/attendance': (context) => const AttendanceScreen(),
              '/clock_in': (context) => const AttendanceScreen(),
              '/clock_in_legacy': (context) => const ClockInScreen(),
              '/supervisor_visit': (context) => const SupervisorVisitScreen(),
              '/hr_module': (context) => const HrModuleScreen(),
              '/dpr': (context) => const DprScreen(),
              '/materials': (context) => const MaterialsScreen(),
              '/conflicts': (context) => const ConflictsScreen(),
              '/audit': (context) => const AuditScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/ai/dialect_speech_tuner': (context) => const DialectSpeechTunerScreen(),
              '/contracts/liquidated_damages': (context) => const LiquidatedDamagesScreen(),
              '/contracts/dispute_adjudication': (context) => const DisputeAdjudicationScreen(),
              '/digital_twin': (context) => const DigitalTwinSiteMapScreen(),
              '/quality/concrete_pour': (context) => const ConcretePourQaScreen(),
              '/quality/golden_weld': (context) => const GoldenWeldCertificationScreen(),
              '/quality/hydrotesting': (context) => const HydrotestingScreen(),
              '/quality/welder_qualification': (context) => const WelderQualificationScreen(),
              '/quality/aut_phased_array': (context) => const AutPhasedArrayScreen(),
              '/engineering/hdd_crossing_profile': (context) => const HddCrossingProfileScreen(),
              '/engineering/hdd_crossing': (context) => const HddCrossingScreen(),
              '/engineering/geohazard_monitoring': (context) => const GeohazardMonitoringScreen(),
              '/engineering/rou_land_acquisition': (context) => const RouLandAcquisitionScreen(),
              '/engineering/strain_gauge_monitoring': (context) => const StrainGaugeMonitoringScreen(),
              '/operations/scada_telemetry': (context) => const ScadaTelemetryScreen(),
              '/integrity/cathodic_protection': (context) => const CathodicProtectionScreen(),
              '/operations/commissioning_punchlist': (context) => const CommissioningPunchlistScreen(),
              '/safety/scaffolding_inspection': (context) => const ScaffoldingInspectionScreen(),
              '/safety/ptw_live': (context) => const PtwLiveScreen(),
              '/safety/flare_radiation': (context) => const FlareRadiationScreen(),
              '/safety/erdmp': (context) => const ErdmpScreen(),
              '/safety/environmental_compliance': (context) => const EnvironmentalComplianceScreen(),
              '/safety/incident_rca': (context) => const IncidentRcaScreen(),
              '/integrity/pipeline_pigging': (context) => const PipelinePiggingScreen(),
              '/integrity/soil_resistivity': (context) => const SoilResistivityScreen(),
              '/operations/custody_metering': (context) => const CustodyMeteringScreen(),
              '/operations/compressor_station': (context) => const CompressorStationScreen(),
              '/operations/gas_chromatography': (context) => const GasChromatographyScreen(),
              '/operations/gas_in_commissioning': (context) => const GasInCommissioningScreen(),
              '/operations/scada_cybersecurity': (context) => const ScadaCybersecurityScreen(),
              '/operations/drone_row_surveillance': (context) => const DroneRowSurveillanceScreen(),
              '/integrity/pims_risk': (context) => const PimsRiskScreen(),
              '/finance/gas_sales_settlement': (context) => const GasSalesSettlementScreen(),
              '/finance/measurement_book': (context) => const MeasurementBookScreen(),
              '/procurement/pipe_heat_tally': (context) => const PipeHeatTallyScreen(),
              '/integrity/field_joint_coating': (context) => const FieldJointCoatingScreen(),
              '/operations/chemical_injection': (context) => const ChemicalInjectionScreen(),
              '/operations/telecom_ofc': (context) => const TelecomOfcScreen(),
              '/operations/hot_tap_stopple': (context) => const HotTapStoppleScreen(),
              '/operations/meter_prover': (context) => const MeterProverScreen(),
              '/operations/dewatering_drying': (context) => const DewateringDryingScreen(),
              '/integrity/cips_dcvg': (context) => const CipsDcvgScreen(),
            },
          );
        },
      ),
    );
  }
}
