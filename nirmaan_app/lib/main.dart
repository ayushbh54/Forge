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
import 'screens/engineering/hdd_crossing_profile_screen.dart';
import 'screens/operations/scada_telemetry_screen.dart';
import 'screens/integrity/cathodic_protection_screen.dart';
import 'screens/operations/commissioning_punchlist_screen.dart';
import 'screens/safety/scaffolding_inspection_screen.dart';

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
              '/engineering/hdd_crossing_profile': (context) => const HddCrossingProfileScreen(),
              '/operations/scada_telemetry': (context) => const ScadaTelemetryScreen(),
              '/integrity/cathodic_protection': (context) => const CathodicProtectionScreen(),
              '/operations/commissioning_punchlist': (context) => const CommissioningPunchlistScreen(),
              '/safety/scaffolding_inspection': (context) => const ScaffoldingInspectionScreen(),
            },
          );
        },
      ),
    );
  }
}
