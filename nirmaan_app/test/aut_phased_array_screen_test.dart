import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/screens/quality/aut_phased_array_screen.dart';

void main() {
  group('ASTM E1961 & API 1104 Annex A ECA Calculator Unit Tests', () {
    test('calculateDepthFromTofdTime calculates accurate tip depth from time-of-flight', () {
      const pcsMm = 78.5; // 2s
      const velocity = 5920.0; // m/s

      // Lateral wave arrival time: t_lat = 78.5 / 5.92 ≈ 13.26 us
      final lateralDepth = AutEcaCalculator.calculateDepthFromTofdTime(
        timeUs: 13.26,
        pcsDistanceMm: pcsMm,
        longitudinalVelocityMPerS: velocity,
      );
      expect(lateralDepth, lessThan(0.5)); // Surface

      // Deeper reflector at ~13.64 us
      final midWallDepth = AutEcaCalculator.calculateDepthFromTofdTime(
        timeUs: 13.64,
        pcsDistanceMm: pcsMm,
        longitudinalVelocityMPerS: velocity,
      );
      expect(midWallDepth, greaterThan(8.0));
      expect(midWallDepth, lessThan(11.0));
    });

    test('calculateTofdTimeFromDepth performs inverse roundtrip accurately', () {
      const pcsMm = 78.5;
      const targetDepth = 9.42;

      final timeUs = AutEcaCalculator.calculateTofdTimeFromDepth(
        depthMm: targetDepth,
        pcsDistanceMm: pcsMm,
      );
      expect(timeUs, greaterThan(13.0));

      final recoveredDepth = AutEcaCalculator.calculateDepthFromTofdTime(
        timeUs: timeUs,
        pcsDistanceMm: pcsMm,
      );
      expect((recoveredDepth - targetDepth).abs(), lessThan(0.001));
    });

    test('calculateAllowableHeight applies tighter thresholds for planar vs non-planar flaws', () {
      // Planar defect (e.g. Lack of Fusion or Incomplete Penetration)
      final planarShort = AutEcaCalculator.calculateAllowableHeight(
        lengthMm: 8.0,
        defectClass: DefectClass.planar,
      );
      expect(planarShort, equals(3.20));

      final planarMed = AutEcaCalculator.calculateAllowableHeight(
        lengthMm: 24.5,
        defectClass: DefectClass.planar,
      );
      expect(planarMed, equals(2.45));

      final planarLong = AutEcaCalculator.calculateAllowableHeight(
        lengthMm: 48.0,
        defectClass: DefectClass.planar,
      );
      expect(planarLong, equals(1.50));

      // Non-Planar defect (e.g. Slag Inclusion or Porosity)
      final nonPlanarMed = AutEcaCalculator.calculateAllowableHeight(
        lengthMm: 24.5,
        defectClass: DefectClass.nonPlanar,
      );
      expect(nonPlanarMed, equals(3.80));
      expect(nonPlanarMed, greaterThan(planarMed)); // Non-planar is less severe
    });

    test('evaluateFlawDisposition disposes acceptable vs repairRequired properly', () {
      expect(
        AutEcaCalculator.evaluateFlawDisposition(
          measuredHeightMm: 2.16,
          allowableHeightMm: 2.45,
        ),
        equals(EcaDisposition.acceptable),
      );

      expect(
        AutEcaCalculator.evaluateFlawDisposition(
          measuredHeightMm: 2.82,
          allowableHeightMm: 1.55,
        ),
        equals(EcaDisposition.repairRequired),
      );
    });

    test('WeldZoneIdExt covers discrete examination zones with correct nominal angles', () {
      expect(WeldZoneId.capL.shortCode, equals('CAP-L'));
      expect(WeldZoneId.capR.shortCode, equals('CAP-R'));
      expect(WeldZoneId.fill4L.shortCode, equals('F4-L'));
      expect(WeldZoneId.fill1R.shortCode, equals('F1-R'));
      expect(WeldZoneId.hotPassL.shortCode, equals('HP-L'));
      expect(WeldZoneId.rootL1.shortCode, equals('ROOT-L1'));
      expect(WeldZoneId.rootL2.shortCode, equals('ROOT-L2'));
      expect(WeldZoneId.tofd.shortCode, equals('TOFD'));
      expect(WeldZoneId.coupling.shortCode, equals('COUP'));

      expect(WeldZoneId.fill4L.nominalAngleDeg, equals(45.0));
      expect(WeldZoneId.fill2L.nominalAngleDeg, equals(55.0));
      expect(WeldZoneId.rootL1.nominalAngleDeg, equals(70.0));
    });
  });

  group('AutPhasedArrayScreen Widget Tests', () {
    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: const AutPhasedArrayScreen(),
      );
    }

    testWidgets('Renders AppBar, standards headers, and top executive summary KPI strip', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Check AppBar Title & Standards Subtitle
      expect(find.text('AUT Phased Array & TOFD'), findsOneWidget);
      expect(find.text('ASTM E1961'), findsOneWidget);
      expect(find.textContaining('API 1104 Annex A ECA'), findsOneWidget);

      // Check Executive Summary Joint Status & KPIs
      expect(find.text('GW-KP-142+500'), findsOneWidget);
      expect(find.text('1 REPAIR CUT-OUT'), findsOneWidget);
      expect(find.text('AUT COVERAGE'), findsOneWidget);
      expect(find.text('TOFD ACCURACY'), findsOneWidget);
      expect(find.text('COUPLING LOSS'), findsOneWidget);
      expect(find.text('DEFECTS DETECTED'), findsOneWidget);

      // Check 5 Tabs
      expect(find.text('Zonal Strip Chart'), findsOneWidget);
      expect(find.text('PAUT S-Scan & E-Scan'), findsOneWidget);
      expect(find.text('TOFD (±0.3mm)'), findsOneWidget);
      expect(find.text('API 1104 ECA'), findsOneWidget);
      expect(find.text('ASTM E1961 Calib'), findsOneWidget);
    });

    testWidgets('Tab 1 Zonal Strip Chart displays channels, circumferential slider and matrix', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Check Zonal Discrimination title
      expect(find.text('ZONAL DISCRIMINATION METHOD (ASTM E1961-16)'), findsOneWidget);
      expect(find.textContaining('Circumferential Index Position (X-Axis):'), findsOneWidget);

      // Check 14-channel strip chart elements
      expect(find.text('14-CHANNEL REAL-TIME STRIP CHART (ASTM E1961)'), findsOneWidget);
      expect(find.text('CAP-L'), findsWidgets);
      expect(find.text('F2-R'), findsWidgets);
      expect(find.text('ROOT-L1'), findsWidgets);

      // Check Bevel Zonal Matrix Table
      expect(find.text('BEVEL ZONAL DISSECTION MATRIX'), findsOneWidget);
      expect(find.text('ZONE'), findsOneWidget);
      expect(find.text('DEPTH RANGE'), findsOneWidget);
      expect(find.text('CAL REFLECTOR'), findsOneWidget);

      // Tap on F2-R strip channel
      final f2rChannel = find.text('F2-R').first;
      await tester.tap(f2rChannel);
      await tester.pumpAndSettle();
    });

    testWidgets('Tab 2 PAUT S-Scan & E-Scan renders custom painters, mode selector and angle slider', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on Tab 2
      final tab2 = find.text('PAUT S-Scan & E-Scan');
      await tester.tap(tab2);
      await tester.pumpAndSettle();

      // Verify Scanning Mode card
      expect(find.text('PHASED ARRAY ELECTRONIC SCANNING MODE'), findsOneWidget);
      expect(find.text('Sectoral S-Scan (40°-72°)'), findsOneWidget);
      expect(find.text('Linear E-Scan (L-Scan)'), findsOneWidget);

      // Verify Heatmap and Bevel card
      expect(find.text('WELD BEVEL PROFILE & ACOUSTIC HEATMAP'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.textContaining('AMPLITUDE % FSH:'), findsOneWidget);

      // Verify A-Scan Oscilloscope
      expect(find.text('SYNCHRONIZED RF A-SCAN OSCILLOSCOPE'), findsOneWidget);
      expect(find.text('PEAK AMPLITUDE'), findsOneWidget);
      expect(find.text('SOUND PATH (W)'), findsOneWidget);
      expect(find.text('TIME OF FLIGHT'), findsOneWidget);

      // Toggle to Linear E-Scan
      final linearBtn = find.text('Linear E-Scan (L-Scan)');
      await tester.tap(linearBtn);
      await tester.pumpAndSettle();
      expect(find.textContaining('Elements 32-64'), findsOneWidget);
    });

    testWidgets('Tab 3 TOFD Channel renders B-scan, dual cursors, and ±0.3mm sizing computation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on Tab 3
      final tab3 = find.text('TOFD (±0.3mm)');
      await tester.tap(tab3);
      await tester.pumpAndSettle();

      // Verify TOFD theory card
      expect(find.text('TIME-OF-FLIGHT DIFFRACTION (TOFD) SIZING CHANNEL'), findsOneWidget);
      expect(find.text('PROBE CENTER SEP (2s)'), findsOneWidget);
      expect(find.text('78.5 mm'), findsOneWidget);
      expect(find.text('SIZING ACCURACY'), findsOneWidget);
      expect(find.text('±0.30 mm'), findsOneWidget);

      // Verify B-Scan card & Cursors
      expect(find.text('TOFD GREYSCALE B-SCAN (D-SCAN COMPOSITE)'), findsOneWidget);
      expect(find.textContaining('Cursor A (Upper Tip Peak):'), findsOneWidget);
      expect(find.textContaining('Cursor B (Lower Tip Peak):'), findsOneWidget);

      // Verify Defect Height readout
      expect(find.text('DEFECT HEIGHT & EMBEDMENT COMPUTATION'), findsOneWidget);
      expect(find.text('MEASURED FLAW HEIGHT (2a):'), findsOneWidget);
      expect(find.textContaining('± 0.3 mm'), findsOneWidget);
      expect(find.text('UPPER TIP DEPTH'), findsOneWidget);
      expect(find.text('LOWER TIP DEPTH'), findsOneWidget);
      expect(find.text('LIGAMENT TO OD'), findsOneWidget);
      expect(find.text('LIGAMENT TO ID'), findsOneWidget);
    });

    testWidgets('Tab 4 API 1104 ECA renders curve chart, flaw classification filter, and cut sheet', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on Tab 4
      final tab4 = find.text('API 1104 ECA');
      await tester.tap(tab4);
      await tester.pumpAndSettle();

      // Verify ECA Curve card
      expect(find.text('API 1104 ANNEX A ECA ACCEPTANCE ENVELOPE'), findsOneWidget);
      expect(find.text('Flaw Length L (mm)'), findsOneWidget);
      expect(find.text('Flaw Height h (mm)'), findsOneWidget);
      expect(find.text('Planar ECA Boundary'), findsOneWidget);
      expect(find.text('Non-Planar ECA Boundary'), findsOneWidget);

      // Verify Defect Dossier and Filter Chips
      expect(find.text('DETECTED FLAW DISPOSITION DOSSIER'), findsOneWidget);
      expect(find.text('All Indications'), findsOneWidget);
      expect(find.text('Planar Defects'), findsOneWidget);
      expect(find.text('Non-Planar Defects'), findsOneWidget);

      // Verify flaw indications IND-01, IND-02, IND-03
      expect(find.text('IND-01'), findsOneWidget);
      expect(find.text('IND-02'), findsOneWidget);
      expect(find.text('IND-03'), findsOneWidget);

      // Check repair instruction for IND-02
      expect(find.text('ENGINEERING REPAIR CUT-SHEET'), findsOneWidget);
      expect(find.textContaining('WPS-OIL-ECA-REPAIR-03'), findsOneWidget);

      // Tap filter chip for Planar Defects
      await tester.tap(find.text('Planar Defects'));
      await tester.pumpAndSettle();

      // IND-01 and IND-02 are planar; IND-03 (slag) is non-planar and should be hidden
      expect(find.text('IND-01'), findsOneWidget);
      expect(find.text('IND-02'), findsOneWidget);
      expect(find.text('IND-03'), findsNothing);
    });

    testWidgets('Tab 5 ASTM E1961 Calib renders block specs, checklist, and SHA-256 stamp', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on Tab 5
      final tab5 = find.text('ASTM E1961 Calib');
      await tester.tap(tab5);
      await tester.pumpAndSettle();

      // Verify Reference Block card
      expect(find.text('ASTM E1961 REFERENCE CALIBRATION BLOCK'), findsOneWidget);
      expect(find.text('CAL-X70-24-18.2-04'), findsOneWidget);
      expect(find.text('WEDGE DELAY CALIBRATION'), findsOneWidget);
      expect(find.text('PRIMARY REFERENCE SENSITIVITY'), findsOneWidget);

      // Verify Pre-scan verification checklist
      expect(find.text('MANDATORY PRE-SCAN CALIBRATION VERIFICATION (ASTM E1961 §8)'), findsOneWidget);

      // Verify SHA-256 stamp
      expect(find.text('DIGITAL CALIBRATION STAMP & CRYPTOGRAPHIC HASH'), findsOneWidget);
      expect(find.text('DIGITALLY CERTIFIED BY ASNT / PCN LEVEL III'), findsOneWidget);
      expect(find.text('SHA-256 INTEGRITY DIGEST:'), findsOneWidget);
    });

    testWidgets('AppBar actions open Joint Selector dialog, Calibration modal, and Export Dossier', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 1. Joint Selector Dialog
      final jointSwitchBtn = find.byIcon(Icons.swap_horiz_rounded);
      await tester.tap(jointSwitchBtn);
      await tester.pumpAndSettle();

      expect(find.text('Select Girth Weld Joint Dossier'), findsOneWidget);
      expect(find.text('GW-KP-142+524'), findsOneWidget);

      // Tap GW-KP-142+524
      await tester.tap(find.text('GW-KP-142+524'));
      await tester.pumpAndSettle();

      expect(find.text('GW-KP-142+524'), findsOneWidget);

      // 2. Calibration Check Modal
      final calibBtn = find.byIcon(Icons.tune_rounded);
      await tester.tap(calibBtn);
      await tester.pumpAndSettle();

      expect(find.text('AUT Calibration Check'), findsOneWidget);
      expect(find.textContaining('Calibration Validated for 4.0 Hours'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // 3. Export Dossier Action
      final exportBtn = find.byIcon(Icons.picture_as_pdf_rounded);
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('AUT Inspection Dossier for GW-KP-142+524 exported with SHA-256 stamp.'), findsOneWidget);
    });
  });
}
