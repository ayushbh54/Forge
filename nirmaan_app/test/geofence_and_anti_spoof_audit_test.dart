import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:nirmaan_app/core/constants/app_constants.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/providers/app_provider.dart';
import 'package:nirmaan_app/screens/workforce/clock_in_screen.dart';
import 'package:nirmaan_app/screens/workforce/supervisor_visit_screen.dart';

void main() {
  group('Geofence & Duliajan Distance Calculations Audit', () {
    const siteLat = AppConstants.defaultSiteLatitude; // 27.4825
    const siteLng = AppConstants.defaultSiteLongitude; // 95.3225
    const radius = AppConstants.geofenceRadiusMeters; // 100.0m

    test('Site coordinates must precisely match Duliajan (27.4825° N, 95.3225° E)', () {
      expect(siteLat, equals(27.4825));
      expect(siteLng, equals(95.3225));
      expect(radius, equals(100.0));
    });

    test('Coordinates within Duliajan site perimeter (15m) evaluate inside geofence', () {
      // 27.48260, 95.32260 is ~14.8m from (27.4825, 95.3225)
      final distance = Geolocator.distanceBetween(27.48260, 95.32260, siteLat, siteLng);
      expect(distance, lessThan(radius));
      expect(distance <= radius, isTrue);
    });

    test('Coordinates outside Duliajan perimeter (480m) fail geofence and trigger Hard-Lock', () {
      // 27.48680, 95.32250 is ~478m from (27.4825, 95.3225)
      final distance = Geolocator.distanceBetween(27.48680, 95.32250, siteLat, siteLng);
      expect(distance, greaterThan(radius));
      expect(distance <= radius, isFalse);
    });
  });

  group('ClockInScreen Security & Anti-Spoof Audit', () {
    testWidgets('Renders Anti-AI disclaimer, Duliajan coordinates, and enforces Hard-Lock', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ChangeNotifierProvider(
            create: (_) => AppProvider(),
            child: const ClockInScreen(),
          ),
        ),
      );
      await tester.pump();

      // 1. Verify Anti-AI disclaimer is present with Duliajan coordinates
      expect(find.textContaining('Anti-AI Photo & Anti-Spoofing Security Active'), findsOneWidget);
      expect(find.textContaining('27.4825° N, 95.3225° E'), findsWidgets);

      // 2. Verify Live Camera Requirement
      expect(find.textContaining('Live Photo Requirement'), findsOneWidget);
      expect(find.textContaining('Capture Live Camera Photo (Gallery Blocked)'), findsOneWidget);

      // 3. Verify Hard-Lock: button is disabled before photo is captured or worker is selected
      final confirmBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
      expect(confirmBtn.onPressed, isNull, reason: 'Attendance button must be hard-locked (onPressed: null)');
      expect(find.textContaining('Submission Locked by Security Policy'), findsOneWidget);
    });
  });

  group('SupervisorVisitScreen Security & Anti-Spoof Audit', () {
    testWidgets('Renders FIDIC Anti-AI disclaimer, Duliajan telemetry, and enforces Hard-Lock', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ChangeNotifierProvider(
            create: (_) => AppProvider(),
            child: const SupervisorVisitScreen(),
          ),
        ),
      );
      await tester.pump();

      // 1. Verify Anti-AI disclaimer with FIDIC standards & Duliajan coordinates
      expect(find.textContaining('Anti-AI Photo Verification & FIDIC Compliance'), findsOneWidget);
      expect(find.textContaining('27.4825° N, 95.3225° E'), findsWidgets);

      // 2. Verify Live Camera Requirement
      expect(find.textContaining('Live Site Photo Evidence'), findsOneWidget);
      expect(find.textContaining('Capture Live Site Photo (Gallery Blocked)'), findsOneWidget);

      // 3. Verify Hard-Lock: submit button is disabled when mandatory requirements are not satisfied
      final submitBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
      expect(submitBtn.onPressed, isNull, reason: 'Visit submission button must be hard-locked (onPressed: null)');
      expect(find.textContaining('Submission Locked by Security Policy'), findsOneWidget);
    });
  });
}
