import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/operations/meter_prover_screen.dart';

void main() {
  testWidgets('MeterProverScreen mounts and renders AGA-7 / API MPMS 4 telemetry and KPIs',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MeterProverScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Standard Badges
    expect(find.text('Meter Prover & Calibration Lab'), findsOneWidget);
    expect(
      find.text('AGA Report No. 7 / API MPMS Chapter 4 Custody Transfer Prover'),
      findsOneWidget,
    );

    // Verify Skid Selector Chips
    expect(find.textContaining('PRV-01 (DN500)'), findsOneWidget);
    expect(find.textContaining('PRV-02 (DN400)'), findsOneWidget);
    expect(find.textContaining('MCP-01 (DN300)'), findsOneWidget);

    // Verify Meter Stream Selector Chips
    expect(find.text('MTR-0101'), findsOneWidget);
    expect(find.text('MTR-0102'), findsOneWidget);
    expect(find.text('MTR-0103'), findsOneWidget);

    // Verify Top KPI Metric Cards
    expect(find.text('MEAN METER FACTOR (MF)'), findsOneWidget);
    expect(find.text('REPEATABILITY SPREAD'), findsOneWidget);
    expect(find.text('CERTIFIED PROVER VOL (CPV)'), findsOneWidget);
    expect(find.text('COMBINED CORRECTION (CCF)'), findsOneWidget);
    expect(find.text('EXPANDED UNCERTAINTY (U)'), findsOneWidget);
    expect(find.text('4-WAY DIVERTER SEAT DP'), findsOneWidget);

    // Verify Tab Headers
    expect(find.text('Prover Loop'), findsOneWidget);
    expect(find.text('API 4.6 Chronometry'), findsOneWidget);
    expect(find.text('Volume Corrections'), findsOneWidget);
    expect(find.text('5-Run Repeatability'), findsOneWidget);
    expect(find.text('Curve & Uncertainty'), findsOneWidget);
    expect(find.text('Certificate'), findsOneWidget);

    // Tab 1: Verify Bi-directional Prover Loop & Hardware
    expect(find.text('PRV-0101 Bi-Directional Pipe Prover'), findsWidgets);
    expect(find.text('Dual Proximity Detector Switches'), findsOneWidget);
    expect(find.text('DETECTOR SWITCH 1 (INBOARD)'), findsOneWidget);
    expect(find.text('DETECTOR SWITCH 2 (OUTBOARD)'), findsOneWidget);
    expect(find.text('Legal Metrology Department Certification'), findsOneWidget);
    expect(find.text('LMD/RRSL/ASSAM/2026/G-882'), findsWidgets);
    expect(find.text('4-Way Diverter Valve & Double Block and Bleed (DBB) Monitoring'), findsOneWidget);
    expect(find.text('SEAL INTEGRITY VERIFIED'), findsOneWidget);

    // Test Proximity Switch Toggles
    final testSw1Finder = find.widgetWithText(OutlinedButton, 'Test SW-1');
    expect(testSw1Finder, findsOneWidget);
    await tester.tap(testSw1Finder);
    await tester.pump();
    expect(find.text('TRIPPED / CLOSED'), findsOneWidget);

    // Test Switch back
    await tester.tap(testSw1Finder);
    await tester.pump();
  });

  testWidgets('MeterProverScreen Tab 2 displays Double Chronometry API MPMS 4.6 Telemetry',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MeterProverScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Tab 2: API 4.6 Chronometry
    await tester.tap(find.text('API 4.6 Chronometry'));
    await tester.pumpAndSettle();

    // Verify Formula and Principles
    expect(find.text('API MPMS Chapter 4.6: Pulse Interpolation (Double Chronometry)'), findsOneWidget);
    expect(find.text('Nᵢ = N × ( T_D / T_M )'), findsOneWidget);
    expect(find.text('Master Oscillator Clock Frequency'), findsOneWidget);
    expect(find.text('10.000000 MHz'), findsOneWidget);
    expect(find.text('Detector Transit Time (T_D)'), findsOneWidget);
    expect(find.text('Meter Pulse Window Time (T_M)'), findsOneWidget);
    expect(find.text('Raw Whole Pulses Counted (N)'), findsOneWidget);
    expect(find.text('API 4.6 Interpolated Pulses (Nᵢ)'), findsOneWidget);
    expect(find.text('API MPMS 4.6 Timing Waveform Diagram'), findsOneWidget);
    expect(find.text('API 4.6 COMPLIANT'), findsOneWidget);
  });

  testWidgets('MeterProverScreen Tab 3 displays Volume Correction Factors Ctsp, Cpsp, Ctls, Cpls',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MeterProverScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Tab 3: Volume Corrections
    await tester.tap(find.text('Volume Corrections'));
    await tester.pumpAndSettle();

    // Verify 4 factors
    expect(find.text('Ctsp (Prover Steel Temperature)'), findsOneWidget);
    expect(find.text('Cpsp (Prover Steel Pressure)'), findsOneWidget);
    expect(find.text('Ctls (Fluid Temperature Difference)'), findsOneWidget);
    expect(find.text('Cpls (Fluid Pressure Difference)'), findsOneWidget);
    expect(find.text('Interactive Live Process Parameter Simulator'), findsOneWidget);
    expect(find.text('Prover Temperature (T_p):'), findsOneWidget);
    expect(find.text('Meter Temperature (T_m):'), findsOneWidget);
    expect(find.text('Prover Pressure (P_p):'), findsOneWidget);
    expect(find.text('Meter Pressure (P_m):'), findsOneWidget);
  });

  testWidgets('MeterProverScreen Tab 4 displays 5-Run Repeatability within 0.05% tolerance',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MeterProverScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Tab 4: 5-Run Repeatability
    await tester.tap(find.text('5-Run Repeatability'));
    await tester.pumpAndSettle();

    // Verify Repeatability Passed Banner
    expect(find.text('API MPMS 4.8 REPEATABILITY PASSED (SPREAD ≤ 0.0500%)'), findsOneWidget);
    expect(find.text('Consecutive Proving Run Ledger (API MPMS 4.8)'), findsOneWidget);
    expect(find.text('Run #1'), findsOneWidget);
    expect(find.text('Run #2'), findsOneWidget);
    expect(find.text('Run #3'), findsOneWidget);
    expect(find.text('Run #4'), findsOneWidget);
    expect(find.text('Run #5'), findsOneWidget);
    expect(find.text('MAXIMUM RUN MF'), findsOneWidget);
    expect(find.text('MINIMUM RUN MF'), findsOneWidget);
    expect(find.text('REPEATABILITY SPREAD %'), findsOneWidget);

    // Inject Thermal Perturbation
    final perturbFinder = find.byTooltip('Inject Thermal Perturbation');
    expect(perturbFinder, findsOneWidget);
    await tester.tap(perturbFinder);
    await tester.pumpAndSettle();

    // Verify Tolerance Exceeded Banner is shown
    expect(find.text('REPEATABILITY TOLERANCE EXCEEDED (SPREAD > 0.0500%)'), findsOneWidget);

    // Restore Nominal 5 Runs
    final restoreFinder = find.byTooltip('Restore Nominal 5 Runs');
    expect(restoreFinder, findsOneWidget);
    await tester.tap(restoreFinder);
    await tester.pumpAndSettle();

    // Verify Repeatability Passed again
    expect(find.text('API MPMS 4.8 REPEATABILITY PASSED (SPREAD ≤ 0.0500%)'), findsOneWidget);
  });

  testWidgets('MeterProverScreen Tab 5 renders Calibration Curve & Uncertainty Budget U < 0.15%',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MeterProverScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Tab 5: Curve & Uncertainty
    await tester.tap(find.text('Curve & Uncertainty'));
    await tester.pumpAndSettle();

    expect(find.text('Multi-Rate Calibration Curve (AGA Report No. 7)'), findsOneWidget);
    expect(find.text('Tolerance Envelope: ±0.15%'), findsOneWidget);
    expect(find.text('ISO/IEC 17025 UNCERTAINTY BUDGET COMPLIANT (U < 0.1500%)'), findsOneWidget);
    expect(find.text('ISO/IEC 17025 Uncertainty Budget Breakdown'), findsOneWidget);
    expect(find.text('5-Run Prover Repeatability (API MPMS 4.8)'), findsOneWidget);
    expect(find.text('Base Calibrated Prover Volume (Water-Draw)'), findsOneWidget);
  });

  testWidgets('MeterProverScreen Tab 6 displays Certificate & Tripartite Signatures',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MeterProverScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Ensure Certificate tab is visible and tap
    await tester.ensureVisible(find.text('Certificate'));
    await tester.tap(find.text('Certificate'));
    await tester.pumpAndSettle();

    expect(find.text('Legal Metrology Custody Transfer Calibration Certificate'), findsOneWidget);
    expect(find.text('Tripartite Witness Signatures & Official Endorsement'), findsOneWidget);
    expect(find.text('Er. Bhabesh Kalita'), findsOneWidget);
    expect(find.text('Er. R. K. Baruah'), findsOneWidget);
    expect(find.text('Dr. S. Mukherjee'), findsOneWidget);
    expect(find.text('Shri A. K. Sarma'), findsOneWidget);
    expect(find.textContaining('Metrological Audit SHA-256 Hash'), findsOneWidget);

    // Open Official Certificate Dialog
    final viewCertButton = find.widgetWithText(ElevatedButton, 'View Official Certificate');
    expect(viewCertButton, findsOneWidget);
    await tester.tap(viewCertButton);
    await tester.pumpAndSettle();

    expect(find.text('GOVERNMENT OF INDIA'), findsOneWidget);
    expect(find.text('CERTIFICATE OF CALIBRATION & VERIFICATION'), findsOneWidget);
    expect(find.text('DEPARTMENT OF LEGAL METROLOGY'), findsOneWidget);

    // Close dialog
    final closeBtn = find.text('Close Preview');
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();
  });
}
