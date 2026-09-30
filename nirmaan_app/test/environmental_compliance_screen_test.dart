import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/safety/environmental_compliance_screen.dart';

void main() {
  group('Statutory Environmental Clearance & MoEFCC Domain Logic Tests', () {
    test('ClearanceCategory metadata and statutory acts', () {
      expect(
        ClearanceCategory.environmentalClearance.shortCode,
        'EC CAT-A',
      );
      expect(
        ClearanceCategory.environmentalClearance.governingAct,
        contains('Environment (Protection) Act 1986'),
      );

      expect(
        ClearanceCategory.consentToEstablish.shortCode,
        'PCBA CTE',
      );
      expect(
        ClearanceCategory.consentToEstablish.issuingAuthority,
        contains('Pollution Control Board Assam'),
      );

      expect(
        ClearanceCategory.consentToOperate.shortCode,
        'PCBA CTO',
      );

      expect(
        ClearanceCategory.forestClearanceStage2.shortCode,
        'FC STAGE-II',
      );
      expect(
        ClearanceCategory.forestClearanceStage2.governingAct,
        contains('28.40 Hectares'),
      );
    });

    test('StatutoryClearanceItem condition compliance calculations', () {
      final now = DateTime.now();
      final item = StatutoryClearanceItem(
        id: 'TEST-CLR-01',
        category: ClearanceCategory.environmentalClearance,
        title: 'Corridor Environmental Clearance',
        orderReferenceNumber: 'J-11011/482/2022-IA.II(I)',
        issueDate: now.subtract(const Duration(days: 365)),
        validityExpiry: now.add(const Duration(days: 3650)),
        status: ClearanceStatus.activeValid,
        nextHycrDueDate: now.add(const Duration(days: 45)),
        officerInCharge: 'Ranjit Phukan',
        digitalVaultDocumentId: 'DOC-EC-01',
        conditions: [
          ClearanceCondition(
            conditionNumber: 'Cond 1',
            description: 'Air monitoring setup',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'CAAQMS stream',
            lastVerified: now,
          ),
          ClearanceCondition(
            conditionNumber: 'Cond 2',
            description: 'HDD River Crossing',
            complianceStatus: 'COMPLIANT',
            verificationMechanism: 'HDD Profile',
            lastVerified: now,
          ),
          ClearanceCondition(
            conditionNumber: 'Cond 3',
            description: 'Half-Yearly report upload',
            complianceStatus: 'MONITORED',
            verificationMechanism: 'Portal log',
            lastVerified: now,
          ),
        ],
      );

      expect(item.compliantConditionsCount, 2);
      expect(item.complianceRate, closeTo(66.66, 0.1));
    });

    test('AaqStation CPCB NAAQS 2009 compliance logic', () {
      final compliantStation = AaqStation(
        id: 'CAAQMS-TEST-01',
        name: 'Compliant Station',
        chainage: 'Ch 00+000',
        locationZone: 'Test Zone',
        latitude: 27.35,
        longitude: 95.31,
        isCpcbUplinkLive: true,
        lastTelemetryTime: DateTime.now(),
        pm25: 28.5, // Standard 60.0
        pm10: 55.0, // Standard 100.0
        so2: 12.0,  // Standard 80.0
        nox: 22.0,  // Standard 80.0
        co: 0.6,    // Standard 2.0
        ambientTempC: 25.0,
        relativeHumidityPercent: 75.0,
        windSpeedKmph: 10.0,
        windDirection: 'NE',
        trendHistory: const [],
      );

      expect(compliantStation.isPm25Compliant, isTrue);
      expect(compliantStation.isPm10Compliant, isTrue);
      expect(compliantStation.isSo2Compliant, isTrue);
      expect(compliantStation.isNoxCompliant, isTrue);
      expect(compliantStation.isCoCompliant, isTrue);
      expect(compliantStation.isAllNaaqsCompliant, isTrue);
      expect(compliantStation.calculatedAqi, lessThanOrEqualTo(50));
      expect(compliantStation.aqiCategory, contains('GOOD'));

      final nonCompliantStation = AaqStation(
        id: 'CAAQMS-TEST-02',
        name: 'Spike Station',
        chainage: 'Ch 48+000',
        locationZone: 'Test Zone 2',
        latitude: 27.29,
        longitude: 95.21,
        isCpcbUplinkLive: true,
        lastTelemetryTime: DateTime.now(),
        pm25: 75.0, // Exceeds 60.0
        pm10: 120.0, // Exceeds 100.0
        so2: 85.0,  // Exceeds 80.0
        nox: 90.0,  // Exceeds 80.0
        co: 3.5,    // Exceeds 2.0
        ambientTempC: 30.0,
        relativeHumidityPercent: 80.0,
        windSpeedKmph: 4.0,
        windDirection: 'SW',
        trendHistory: const [],
      );

      expect(nonCompliantStation.isPm25Compliant, isFalse);
      expect(nonCompliantStation.isPm10Compliant, isFalse);
      expect(nonCompliantStation.isSo2Compliant, isFalse);
      expect(nonCompliantStation.isNoxCompliant, isFalse);
      expect(nonCompliantStation.isCoCompliant, isFalse);
      expect(nonCompliantStation.isAllNaaqsCompliant, isFalse);
      expect(nonCompliantStation.calculatedAqi, greaterThan(50));
    });

    test('IndigenousFloraSpecies living stems and mortality calculations', () {
      const species = IndigenousFloraSpecies(
        commonName: 'Hollong',
        botanicalName: 'Dipterocarpus macrocarpus',
        roleInEcosystem: 'Rainforest canopy emergent',
        plantedCount: 22720,
        survivalRatePercent: 90.0,
        badgeColor: Color(0xFF10B981),
      );

      expect(species.livingCount, 20448);
      expect(species.mortalityCount, 2272);
    });

    test('AfforestationPlot statutory survival rate requirement (> 85%)', () {
      final now = DateTime.now();
      final plotPass = AfforestationPlot(
        plotId: 'PLOT-A',
        plotName: 'Digboi Beat',
        beatDivision: 'Digboi Division',
        areaHectares: 12.2,
        latitude: 27.38,
        longitude: 95.61,
        targetSaplings: 24400,
        plantedSaplings: 24400,
        currentSurvivalRate: 90.4,
        targetMinimumSurvivalRate: 85.0,
        droneNdviCanopyDensity: 0.81,
        soilOrganicCarbonPct: 1.9,
        dfoInspectionStatus: 'APPROVED',
        lastAuditDate: now,
        primarySpecies: const ['Hollong'],
      );

      expect(plotPass.isSurvivalCompliant, isTrue);
      expect(plotPass.livingTrees, 22058);

      final plotFail = AfforestationPlot(
        plotId: 'PLOT-F',
        plotName: 'Degraded Beat',
        beatDivision: 'Test Division',
        areaHectares: 5.0,
        latitude: 27.0,
        longitude: 95.0,
        targetSaplings: 10000,
        plantedSaplings: 10000,
        currentSurvivalRate: 81.2, // Below 85%
        targetMinimumSurvivalRate: 85.0,
        droneNdviCanopyDensity: 0.65,
        soilOrganicCarbonPct: 1.2,
        dfoInspectionStatus: 'RE-PLANTING MANDATED',
        lastAuditDate: now,
        primarySpecies: const ['Nahor'],
      );

      expect(plotFail.isSurvivalCompliant, isFalse);
    });

    test('WaterCrossingMonitoring turbidity delta and compliance', () {
      final now = DateTime.now();
      final compliantCrossing = WaterCrossingMonitoring(
        crossingId: 'WAT-01',
        waterBodyName: 'Burhi Dihing River',
        chainage: 'Ch 48+200',
        crossingMethod: 'HDD (1450m)',
        upstreamBaselineNtu: 10.0,
        downstreamMeasuredNtu: 14.5,
        statutoryMaxDeltaNtu: 25.0,
        siltCurtainStatus: 'SECURE',
        sedimentRetentionEfficiencyPct: 95.0,
        dissolvedOxygenMgL: 6.8, // > 5.0
        phLevel: 7.2,            // 6.5 - 8.5
        isBentoniteLeakDetected: false,
        telemetrySensorTag: 'TAG-01',
        lastSamplingTimestamp: now,
      );

      expect(compliantCrossing.deltaNtu, 4.5);
      expect(compliantCrossing.isDeltaCompliant, isTrue);
      expect(compliantCrossing.isDoCompliant, isTrue);
      expect(compliantCrossing.isPhCompliant, isTrue);
      expect(compliantCrossing.isFullyCompliant, isTrue);

      final nonCompliantCrossing = WaterCrossingMonitoring(
        crossingId: 'WAT-02',
        waterBodyName: 'Disang River',
        chainage: 'Ch 112+500',
        crossingMethod: 'HDD (820m)',
        upstreamBaselineNtu: 10.0,
        downstreamMeasuredNtu: 40.0, // Delta 30.0 > 25.0
        statutoryMaxDeltaNtu: 25.0,
        siltCurtainStatus: 'BREACH DETECTED',
        sedimentRetentionEfficiencyPct: 60.0,
        dissolvedOxygenMgL: 4.2, // < 5.0
        phLevel: 8.9,            // > 8.5
        isBentoniteLeakDetected: true,
        telemetrySensorTag: 'TAG-02',
        lastSamplingTimestamp: now,
      );

      expect(nonCompliantCrossing.deltaNtu, 30.0);
      expect(nonCompliantCrossing.isDeltaCompliant, isFalse);
      expect(nonCompliantCrossing.isDoCompliant, isFalse);
      expect(nonCompliantCrossing.isPhCompliant, isFalse);
      expect(nonCompliantCrossing.isFullyCompliant, isFalse);
    });
  });

  group('EnvironmentalComplianceScreen Widget Tests', () {
    testWidgets('Screen renders header, metrics strip, and default Tab 1 clearances',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: EnvironmentalComplianceScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Header title & badges
      expect(find.text('Environmental Clearance & MoEFCC'), findsOneWidget);
      expect(find.text('FCA 1980 / PCBA'), findsOneWidget);
      expect(find.textContaining('194.5 km Corridor'), findsWidgets);
      expect(find.text('STATUTORY REGULATORY UPLINK'), findsOneWidget);
      expect(find.text('CPCB & PCBA LIVE'), findsOneWidget);

      // Metrics strip
      expect(find.text('STATUTORY CLEARANCES'), findsOneWidget);
      expect(find.text('4/4 ACTIVE'), findsOneWidget);
      expect(find.text('AAQ STATIONS'), findsOneWidget);
      expect(find.text('4 ONLINE'), findsOneWidget);
      expect(find.text('CA SURVIVAL RATE'), findsOneWidget);
      expect(find.text('RIVER SILTATION'), findsOneWidget);
      expect(find.text('CAMPA FUND DEPOSIT'), findsOneWidget);

      // 4 Main Tabs
      expect(find.text('Statutory Clearances'), findsOneWidget);
      expect(find.text('Ambient Air Quality'), findsOneWidget);
      expect(find.text('Compensatory Afforestation'), findsOneWidget);
      expect(find.text('River Siltation & NTU'), findsOneWidget);

      // Tab 1 Clearances content
      expect(find.text('FILTER CLEARANCES:'), findsOneWidget);
      expect(find.text('EC CAT-A'), findsWidgets);
      expect(find.textContaining('J-11011/482/2022-IA.II(I)'), findsOneWidget);
      expect(find.text('PCBA CTE'), findsWidgets);
      expect(find.textContaining('WB/DIB/T-409/21-22/194'), findsOneWidget);
      expect(find.text('PCBA CTO'), findsWidgets);
      expect(find.textContaining('PCBA/RO-DIB/CTO/GAS-PL/2025/88'), findsOneWidget);
      expect(find.text('FC STAGE-II'), findsWidgets);
      expect(find.textContaining('28.40 Hectares'), findsWidgets);

      // Verify Audit Checklist bottom sheet opens
      await tester.tap(find.text('Audit Checklist').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Statutory Checklist'), findsOneWidget);

      // Dismiss bottom sheet by tapping barrier
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
    });

    testWidgets('Switch to Ambient Air Quality tab and check telemetry elements',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: EnvironmentalComplianceScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Ambient Air Quality Tab
      await tester.tap(find.text('Ambient Air Quality'));
      await tester.pumpAndSettle();

      expect(find.text('SELECT CAAQMS MONITORING STATION:'), findsOneWidget);
      expect(find.text('CAAQMS-DUL-01'), findsOneWidget);
      expect(find.text('CAAQMS-BDH-02'), findsOneWidget);
      expect(find.text('CAAQMS-MRN-03'), findsOneWidget);
      expect(find.text('CAAQMS-DSG-04'), findsOneWidget);

      // 5-Gas Telemetry Cards
      expect(find.text('CPCB NAAQS 2009 5-GAS TELEMETRY (REAL-TIME)'), findsOneWidget);
      expect(find.text('PM2.5 Particulate'), findsOneWidget);
      expect(find.text('PM10 Respirable'), findsOneWidget);
      expect(find.text('Sulfur Dioxide (SO₂)'), findsOneWidget);
      expect(find.text('Nitrogen Oxides (NOₓ)'), findsOneWidget);
      expect(find.text('Carbon Monoxide (CO)'), findsOneWidget);

      // 24-hr Chart title
      expect(find.text('24-HOUR TELEMETRY CONCENTRATION CURVE'), findsOneWidget);

      // Meteorological variables
      expect(find.text('AMBIENT TEMP'), findsOneWidget);
      expect(find.text('HUMIDITY'), findsOneWidget);
      expect(find.text('WIND SPEED'), findsOneWidget);
      expect(find.text('WIND VECTOR'), findsOneWidget);
    });

    testWidgets('Switch to Compensatory Afforestation tab and verify 1:2 ratio & species',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: EnvironmentalComplianceScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Compensatory Afforestation Tab
      await tester.tap(find.text('Compensatory Afforestation'));
      await tester.pumpAndSettle();

      expect(find.textContaining('FCA 1980 SECTION 2 MANDATORY REPLACEMENT (1:2 RATIO)'), findsOneWidget);
      expect(find.text('TOTAL INDIGENOUS TREES PLANTED'), findsOneWidget);
      expect(find.text('56,800'), findsOneWidget);
      expect(find.text('/ 56,800 (100% Target)'), findsOneWidget);
      expect(find.text('> 85% REQ'), findsOneWidget);

      // Indigenous Species
      expect(find.text('Hollong'), findsOneWidget);
      expect(find.textContaining('Dipterocarpus macrocarpus'), findsOneWidget);
      expect(find.text('Nahor / Ironwood'), findsOneWidget);
      expect(find.textContaining('Mesua ferrea'), findsOneWidget);
      expect(find.text('Mekai'), findsOneWidget);
      expect(find.textContaining('Shorea assamica'), findsOneWidget);

      // Geotagged Plots
      expect(find.textContaining('Digboi Reserve Forest Beat (Plot Alpha)'), findsOneWidget);
      expect(find.textContaining('Joypur Rainforest Buffer Zone (Plot Beta)'), findsOneWidget);
      expect(find.textContaining('Dihing Patkai Wildlife Sanctuary Buffer (Plot Gamma)'), findsOneWidget);
    });

    testWidgets('Switch to River Siltation tab and verify water crossings and NTU meters',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: EnvironmentalComplianceScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap River Siltation & NTU Tab
      await tester.tap(find.text('River Siltation & NTU'));
      await tester.pumpAndSettle();

      expect(find.textContaining('WATER (PREVENTION & CONTROL) ACT 1974 STANDARDS'), findsOneWidget);
      expect(find.text('Burhi Dihing River Crossing'), findsOneWidget);
      expect(find.text('Disang River Perennial Crossing'), findsOneWidget);
      expect(find.text('Noa Dehing Channel Eco-Cross'), findsOneWidget);
      expect(find.text('Tingrai Stream Culvert Tributary'), findsOneWidget);

      // NTU columns
      expect(find.text('UPSTREAM BASELINE'), findsWidgets);
      expect(find.text('DOWNSTREAM SAMPLING'), findsWidgets);
      expect(find.text('NET DELTA (Δ NTU)'), findsWidgets);
      expect(find.textContaining('Bentonite Leak: 0.0 ppm'), findsWidgets);
    });

    testWidgets('Dialog interactions for HYCR dossier export and Audit logging',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: EnvironmentalComplianceScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Open HYCR Dossier Dialog via AppBar icon
      await tester.tap(find.byIcon(Icons.article_rounded));
      await tester.pumpAndSettle();

      expect(find.text('MoEFCC HYCR Portal Submission'), findsOneWidget);
      expect(find.textContaining('PARIVESH Portal Ref'), findsOneWidget);
      await tester.tap(find.text('Export Dossier PDF'));
      await tester.pumpAndSettle();

      expect(find.textContaining('MoEFCC PARIVESH compliance dossier exported successfully'), findsOneWidget);

      // Dismiss active SnackBar before opening next dialog
      ScaffoldMessenger.of(tester.element(find.byType(EnvironmentalComplianceScreen))).clearSnackBars();
      await tester.pumpAndSettle();

      // Open Log Compliance Audit Dialog via FAB
      await tester.tap(find.text('Log Compliance Audit'));
      await tester.pumpAndSettle();

      expect(find.text('Log Field Environmental Audit'), findsOneWidget);
      await tester.tap(find.text('Record Audit'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Field Environmental Audit logged to statutory register'), findsOneWidget);
    });
  });
}
