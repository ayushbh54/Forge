import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/operations/esd_valve_control_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EsdValveControlScreen Unit Tests', () {
    test('ValveActuatorStatus enum labels and colors verify correctly', () {
      expect(ValveActuatorStatus.open.label, 'OPEN (100%)');
      expect(ValveActuatorStatus.closed.label, 'CLOSED (0%)');
      expect(ValveActuatorStatus.traveling.label, 'TRAVELING');
      expect(ValveActuatorStatus.fault.label, 'FAULT / ALARM');
    });

    test('Valve actuator status colors conform to industrial safety conventions', () {
      expect(ValveActuatorStatus.open.color, const Color(0xFF4EDEA3));
      expect(ValveActuatorStatus.closed.color, const Color(0xFFFF5252));
    });
  });

  group('EsdValveControlScreen Widget Tests', () {
    testWidgets('Renders ESD valve control screen with telemetry tabs and controls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: EsdValveControlScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EsdValveControlScreen), findsOneWidget);
    });
  });
}
