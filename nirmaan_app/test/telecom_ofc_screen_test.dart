import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/screens/operations/telecom_ofc_screen.dart';

void main() {
  group('Telecom, OFC & SDH Network Domain Models Unit Tests', () {
    test('OfcFiberCore properties, colors and ITU-T standard', () {
      const core1 = OfcFiberCore(
        coreNumber: 1,
        tubeNumber: 1,
        tubeColor: TubeColor.blue,
        tubeName: 'Tube 1 (Blue)',
        standard: FiberStandard.ituTG652D,
        serviceAllocation: 'SCADA Host Primary Ring',
        serviceClass: ServiceClass.scadaTelemetry,
        status: LinkHealthStatus.normal,
        opticalPowerDbm: -17.8,
        attenuationDbPerKm: 0.198,
        totalSpanLossDb: 38.5,
        patchPanelPort: 'ODF-01-P01',
      );

      expect(core1.coreNumber, 1);
      expect(core1.tubeName, 'Tube 1 (Blue)');
      expect(core1.tubeUiColor, const Color(0xFF0284C7));
      expect(core1.status, LinkHealthStatus.normal);
      expect(core1.statusColor, const Color(0xFF10B981));
      expect(core1.statusLabel, 'OPTIMAL');
      expect(core1.standard, FiberStandard.ituTG652D);

      const darkCore = OfcFiberCore(
        coreNumber: 19,
        tubeNumber: 4,
        tubeColor: TubeColor.brown,
        tubeName: 'Tube 4 (Brown)',
        serviceAllocation: 'Continuous OTDR Online Dark Fiber',
        status: LinkHealthStatus.standby,
        opticalPowerDbm: -22.5,
        attenuationDbPerKm: 0.197,
        totalSpanLossDb: 38.3,
        isDarkFiber: true,
        patchPanelPort: 'ODF-04-P01',
      );

      expect(darkCore.isDarkFiber, isTrue);
      expect(darkCore.tubeUiColor, const Color(0xFF8D6E63));
      expect(darkCore.statusLabel, 'HOT STANDBY');
    });

    test('OtdrEvent fault classification and ±5m accuracy margin verification', () {
      const normalEvent = OtdrEvent(
        eventNumber: 2,
        chainageKm: 24.620,
        accuracyMarginM: 2.1,
        type: OtdrEventType.fusionSplice,
        stepLossDb: 0.038,
        reflectanceDb: -62.4,
        cumulativeLossDb: 5.01,
        slopeDbPerKm: 0.197,
        nearestStation: 'SV-01 Tingkhong',
        physicalLandmark: 'Underground Joint Closure JC-01',
      );

      expect(normalEvent.isFault, isFalse);
      expect(normalEvent.accuracyMarginM, lessThanOrEqualTo(5.0)); // within ±5m spec
      expect(normalEvent.typeLabel, 'Fusion Splice Joint');
      expect(normalEvent.eventColor, const Color(0xFF4EDEA3));

      const faultEvent = OtdrEvent(
        eventNumber: 4,
        chainageKm: 78.432,
        accuracyMarginM: 3.8,
        type: OtdrEventType.macroBending,
        stepLossDb: 0.380,
        reflectanceDb: -58.2,
        cumulativeLossDb: 16.24,
        slopeDbPerKm: 0.245,
        nearestStation: 'SV-04 Dergaon',
        physicalLandmark: 'NH-37 HDD Section',
        isFault: true,
      );

      expect(faultEvent.isFault, isTrue);
      expect(faultEvent.accuracyMarginM, 3.8);
      expect(faultEvent.accuracyMarginM, lessThanOrEqualTo(5.0));
      expect(faultEvent.eventColor, const Color(0xFFEF4444));
    });

    test('SdhStationNode APS status, colors and <50ms switchover compliance', () {
      const normalNode = SdhStationNode(
        stationId: 'CCR-DUL',
        stationName: 'Central Control Room (Duliajan)',
        chainageKm: 0.0,
        nodeRole: 'Master Terminal Multiplexer',
        txOpticalPowerDbm: -2.0,
        rxOpticalPowerEastDbm: -18.4,
        rxOpticalPowerWestDbm: -17.9,
        opticalMarginDb: 11.6,
        bitErrorRate: 1.1e-13,
        apsState: SdhApsState.idleProtected,
        lastSwitchoverMs: 24.2,
      );

      expect(normalNode.apsState, SdhApsState.idleProtected);
      expect(normalNode.apsLabel, 'SNCP DUAL-PATH NORMAL');
      expect(normalNode.apsColor, const Color(0xFF10B981));
      expect(normalNode.lastSwitchoverMs, lessThan(50.0)); // ITU-T G.841 <50ms spec

      const failoverNode = SdhStationNode(
        stationId: 'SV-04',
        stationName: 'SV-04 Dergaon',
        chainageKm: 134.0,
        nodeRole: 'OADM',
        txOpticalPowerDbm: -2.2,
        rxOpticalPowerEastDbm: -45.0,
        rxOpticalPowerWestDbm: -18.8,
        opticalMarginDb: 10.5,
        bitErrorRate: 3.4e-13,
        apsState: SdhApsState.switchedToWestLine,
        lastSwitchoverMs: 28.4,
      );

      expect(failoverNode.apsLabel, 'ACTIVE ON WEST RING');
      expect(failoverNode.apsColor, const Color(0xFF38BDF8));
      expect(failoverNode.lastSwitchoverMs, lessThan(50.0));
    });

    test('SdhBandwidthTunnel allocation, utilization ratio and QoS priority', () {
      const scadaTunnel = SdhBandwidthTunnel(
        tunnelId: 'VC12-SCADA-01',
        serviceName: 'SCADA Telemetry & ESD Inter-Trip',
        serviceClass: ServiceClass.scadaTelemetry,
        vcMapping: '8 x VC-12',
        allocatedMbps: 16.384,
        utilizedMbps: 11.240,
        latencyMs: 3.8,
        jitterMs: 0.6,
        packetLossPct: 0.00,
        priorityLevel: 'P1 Ultra Real-Time',
      );

      expect(scadaTunnel.serviceColor, const Color(0xFF0284C7));
      expect(scadaTunnel.utilizationRatio, closeTo(11.240 / 16.384, 0.001));
      expect(scadaTunnel.isHotStandbyProtected, isTrue);

      const cctvTunnel = SdhBandwidthTunnel(
        tunnelId: 'VC4-CCTV-01',
        serviceName: 'Perimeter 4K CCTV',
        serviceClass: ServiceClass.cctvSurveillance,
        vcMapping: '2 x VC-4',
        allocatedMbps: 310.0,
        utilizedMbps: 228.6,
        latencyMs: 14.5,
        jitterMs: 2.1,
        packetLossPct: 0.01,
        priorityLevel: 'P2 Mission Critical',
      );

      expect(cctvTunnel.serviceColor, const Color(0xFF38BDF8));
      expect(cctvTunnel.utilizationRatio, closeTo(228.6 / 310.0, 0.001));
    });

    test('RepeaterAuxPowerData power source modes and 24-cell 48V bank', () {
      final repeater = RepeaterAuxPowerData(
        stationId: 'RS-01',
        stationName: 'Repeater RS-01',
        chainageKm: 24.6,
        activeSource: PowerSourceMode.solarPvActive,
        solarPvArrayKw: 4.8,
        solarGenerationKw: 3.92,
        solarIrradianceWm2: 840.0,
        pvString1Volts: 112.4,
        pvString1Amps: 18.2,
        pvString2Volts: 110.8,
        pvString2Amps: 17.5,
        mpptEfficiencyPct: 98.6,
        mpptChargingState: 'Float',
        dcBusVoltage: 53.6,
        batterySocPct: 94.2,
        batterySohPct: 98.8,
        batteryLoadCurrentAmps: 24.8,
        batteryAutonomyHoursRemaining: 36.4,
        cellVoltages: List.generate(24, (i) => 2.23),
        dgStatus: 'STANDBY AUTO-READY',
        dgFuelTankPct: 88.5,
        dgFuelLitersRemaining: 220.0,
        dgCoolantTempC: 42.0,
        dgCrankingBatteryVolts: 12.8,
        dgTotalRunHours: 142.5,
        shelterTempC: 21.4,
        shelterHumidityPct: 45.0,
      );

      expect(repeater.activeSource, PowerSourceMode.solarPvActive);
      expect(repeater.sourceLabel, 'SOLAR PV ACTIVE (PRIMARY)');
      expect(repeater.cellVoltages.length, 24); // 24-cell 48V string
      expect(repeater.batteryAutonomyHoursRemaining, 36.4);
      expect(repeater.isDoorSecured, isTrue);
    });

    test('TrenchSectionProfile burial depth compliance (1.50m ± 0.05m)', () {
      final compliantSection = TrenchSectionProfile(
        sectionId: 'SEC-01',
        startStation: 'CCR Duliajan',
        endStation: 'SV-01',
        startChainageKm: 0.0,
        endChainageKm: 24.6,
        measuredBurialDepthM: 1.52, // between 1.45 and 1.65
        electronicMarkerRfidCount: 124,
        soilStrata: 'Alluvial Loam',
        groundCoverTempC: 26.4,
        lastInspectionDate: DateTime.now(),
      );

      expect(compliantSection.isDepthCompliant, isTrue);
      expect(compliantSection.depthColor, const Color(0xFF4EDEA3));

      final nonCompliantSection = TrenchSectionProfile(
        sectionId: 'SEC-02',
        startStation: 'SV-01',
        endStation: 'SV-02',
        startChainageKm: 24.6,
        endChainageKm: 48.4,
        measuredBurialDepthM: 1.38, // shallow: < 1.45
        electronicMarkerRfidCount: 118,
        soilStrata: 'Dense Clay',
        groundCoverTempC: 25.8,
        lastInspectionDate: DateTime.now(),
      );

      expect(nonCompliantSection.isDepthCompliant, isFalse);
      expect(nonCompliantSection.depthColor, const Color(0xFFFFB95F));
    });
  });

  group('TelecomOfcScreen Widget Rendering & Navigation Tests', () {
    testWidgets('Renders AppBar, Status Banner, Metric Chips, and 4 Main Tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TelecomOfcScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify App Bar Header
      expect(find.text('Telecom, OFC & SDH Network'), findsOneWidget);
      expect(find.text('STM-4 / 622M'), findsOneWidget);
      expect(find.text('Pipeline Optical Fiber Backbone & Supervisory Communications'), findsOneWidget);

      // 2. Verify Status Banner
      expect(find.text('OFC DUAL-RING: SYNCHRONIZED'), findsOneWidget);
      expect(find.text('SNCP PROTECTED'), findsOneWidget);

      // 3. Verify Metric Header Chips
      expect(find.text('194.5 KM'), findsOneWidget);
      expect(find.text('1.50 m'), findsWidgets);
      expect(find.text('24-Core SMF'), findsOneWidget);
      expect(find.text('STM-4 (622M)'), findsOneWidget);
      expect(find.text('3.92 kW'), findsOneWidget);
      expect(find.text('±3.8 m'), findsOneWidget);

      // 4. Verify 4 Navigation Tabs
      expect(find.text('OFC Backbone & Trench'), findsOneWidget);
      expect(find.text('OTDR Fiber Health'), findsOneWidget);
      expect(find.text('SDH STM-4 Ring'), findsOneWidget);
      expect(find.text('Repeater Power'), findsOneWidget);

      // 5. Tab 1: Verify OFC Specification & Trench Schematic
      expect(find.text('24-Core Armored Single-Mode OFC Specification'), findsOneWidget);
      expect(find.text('Pipeline Trench Burial Cross-Section Profile'), findsOneWidget);
      expect(find.text('24-Core Fiber Tube Allocation Matrix'), findsOneWidget);
      expect(find.text('Right-of-Way Trench Burial & Depth Inspection'), findsOneWidget);
      expect(find.text('Tube 1 (Blue)'), findsOneWidget);
      expect(find.text('Tube 4 (Brown)'), findsOneWidget);
    });

    testWidgets('Tab 2: Switch to OTDR Fiber Health, inspect Rayleigh chart, trigger test & simulate cut',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TelecomOfcScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Tab 2: OTDR Fiber Health
      await tester.tap(find.text('OTDR Fiber Health'));
      await tester.pumpAndSettle();

      // Verify OTDR elements
      expect(find.text('Continuous OTDR Dark Fiber Telemetry'), findsOneWidget);
      expect(find.text('Rayleigh Backscattering Trace (dB vs KM)'), findsOneWidget);
      expect(find.text('1310 nm'), findsOneWidget);
      expect(find.text('1550 nm'), findsOneWidget);
      expect(find.text('1625 nm (U-Band)'), findsOneWidget);
      expect(find.text('TRIGGER SCAN'), findsOneWidget);
      expect(find.text('Continuous OTDR Splice & Event Ledger'), findsOneWidget);

      // Verify Fault Localization Alert Banner (within ±5m)
      expect(find.textContaining('SPLICE LOSS & MACRO-BEND ATTENUATION ALERT'), findsOneWidget);
      expect(find.text('SIM BREAK'), findsOneWidget);

      // Tap SIM BREAK to simulate optical fiber cut
      await tester.tap(find.text('SIM BREAK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify break alert banner appears
      expect(find.textContaining('AUTOMATED FIBER BREAK LOCALIZATION'), findsOneWidget);
      expect(find.text('RESTORE'), findsOneWidget);

      // Tap RESTORE to reset link
      await tester.tap(find.text('RESTORE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SIM BREAK'), findsOneWidget);
    });

    testWidgets('Tab 3: Switch to SDH STM-4 Ring & Bandwidth Allocation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TelecomOfcScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Tab 3: SDH STM-4 Ring
      await tester.tap(find.text('SDH STM-4 Ring'));
      await tester.pumpAndSettle();

      expect(find.text('SDH / STM-4 Synchronous Transmission Ring'), findsOneWidget);
      expect(find.textContaining('622.08 Mbps (4 x STM-1 / 252 x E1)'), findsOneWidget);
      expect(find.text('DUAL-RING SYNCHRONIZED'), findsOneWidget);
      expect(find.text('Bandwidth Allocation & Virtual Container (VC) Mapping'), findsOneWidget);
      expect(find.text('SCADA Telemetry & ESD Inter-Trip Control'), findsOneWidget);
      expect(find.text('Pipeline Perimeter 4K CCTV Video Security'), findsOneWidget);
      expect(find.text('CCR Hotline IP Magneto & Dispatch Telephony'), findsOneWidget);
      expect(find.text('Public Address & General Alarm (PAGA Audio)'), findsOneWidget);
      expect(find.text('SDH Add-Drop Multiplexer (ADM) Optical Telemetry'), findsOneWidget);
    });

    testWidgets('Tab 4: Switch to Repeater Power & test DG auto-start sequence',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TelecomOfcScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Tab 4: Repeater Power
      await tester.tap(find.text('Repeater Power'));
      await tester.pumpAndSettle();

      expect(find.text('Repeater Station Location:'), findsOneWidget);
      expect(find.textContaining('Solar PV Generation Array'), findsOneWidget);
      expect(find.text('48V DC Telecom Battery Bank (600Ah)'), findsOneWidget);
      expect(find.text('Backup Diesel Generator (15 kVA Silent DG)'), findsOneWidget);
      expect(find.text('Telecom Shelter Environmental & Physical Security'), findsOneWidget);
      expect(find.text('TEST CRANK'), findsOneWidget);

      // Tap TEST CRANK to open confirmation dialog
      await tester.tap(find.text('TEST CRANK'));
      await tester.pumpAndSettle();

      expect(find.text('Repeater DG Auto-Exercise'), findsOneWidget);
      expect(find.textContaining('15-second unloaded test cranking'), findsOneWidget);
      expect(find.text('START DG TEST'), findsOneWidget);

      // Start the DG test
      await tester.tap(find.text('START DG TEST'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('DG TEST'), findsOneWidget);
    });

    testWidgets('Export Telecom Audit Report dialog triggers correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TelecomOfcScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap export report icon in AppBar
      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Export Telecom Audit Report'), findsOneWidget);
      expect(find.textContaining('24-Core OFC attenuation matrix'), findsOneWidget);
      expect(find.text('GENERATE PDF'), findsOneWidget);

      await tester.tap(find.text('GENERATE PDF'));
      await tester.pumpAndSettle();

      expect(find.text('Export Telecom Audit Report'), findsNothing);
    });
  });
}
