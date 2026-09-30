import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/integrity/soil_resistivity_screen.dart';

void main() {
  group('ASTM G57 Soil Resistivity & Corrosivity Unit Tests', () {
    test('Wenner 4-Pin apparent resistivity formula: rho = 2 * pi * a * R', () {
      // pin-a = 2.0m, R = 1.5 Ohm -> rho = 2 * pi * 2 * 1.5 = 6 * pi = 18.8495 Ohm-meter
      final reading = WennerPinReading(
        pinSpacingA: 2.0,
        measuredResistanceOhms: 1.5,
        pinDepthMeters: 0.05,
      );

      final expectedRho = 2.0 * math.pi * 2.0 * 1.5;
      expect(reading.apparentResistivityRho, closeTo(expectedRho, 0.001));
      expect(reading.resistivityOhmCm, closeTo(expectedRho * 100.0, 0.1));
    });

    test('ASTM G57 electrode depth rule: d <= 0.05 * a', () {
      final compliant = WennerPinReading(
        pinSpacingA: 2.0,
        measuredResistanceOhms: 1.0,
        pinDepthMeters: 0.08, // 0.08 <= 0.05 * 2.0 = 0.10
      );
      expect(compliant.isElectrodeDepthCompliant, isTrue);

      final nonCompliant = WennerPinReading(
        pinSpacingA: 1.0,
        measuredResistanceOhms: 1.0,
        pinDepthMeters: 0.08, // 0.08 > 0.05 * 1.0 = 0.05
      );
      expect(nonCompliant.isElectrodeDepthCompliant, isFalse);
    });

    test('Soil Corrosivity Ratings per Peabody & ASTM G57 Scale', () {
      expect(SoilCorrosivityClassExt.fromRho(3.5),
          SoilCorrosivityClass.extremelyCorrosive);
      expect(SoilCorrosivityClassExt.fromRho(8.0),
          SoilCorrosivityClass.veryCorrosive);
      expect(SoilCorrosivityClassExt.fromRho(15.0),
          SoilCorrosivityClass.corrosive);
      expect(SoilCorrosivityClassExt.fromRho(45.0),
          SoilCorrosivityClass.moderatelyCorrosive);
      expect(SoilCorrosivityClassExt.fromRho(120.0),
          SoilCorrosivityClass.mildlyNonCorrosive);
    });
  });

  group('DWICG Deep Well Groundbed Telemetry Tests', () {
    test('Groundbed resistance Rg < 1.0 Ohm compliance check', () {
      final anodes = List.generate(
        12,
        (i) => DwicgAnodeTelemetry(
          anodeIndex: i + 1,
          tag: 'AN-${(i + 1).toString().padLeft(2, '0')}',
          depthMeters: 45.0 + (i * 5.0),
          currentAmps: 2.2, // 12 * 2.2 = 26.4 A total
          leadWireCondition: 'Intact',
        ),
      );

      final gbCompliant = DwicgGroundbedRecord(
        id: 'DWICG-TEST-01',
        name: 'Test Groundbed Compliant',
        chainage: 'KP 10+000',
        chainageKm: 10.0,
        totalBoreholeDepthM: 100.0,
        activeColumnM: 60.0,
        boreholeDiameterMm: 200.0,
        casingDepthM: 40.0,
        anodes: anodes,
        trVoltageVolts: 18.0, // 18.0 V / 26.4 A = 0.6818 Ohm (< 1.0 Ohm)
        cokeBreezeResistanceOhms: 0.18,
        cokeSettlingDeltaHM: 2.0,
        gasVentPressurePsi: 4.5,
        waterTableDepthM: 12.0,
        anodeType: AnodeMaterialType.mmoTitanium,
        installationDate: DateTime(2022, 1, 1),
      );

      expect(gbCompliant.totalCurrentAmps, closeTo(26.4, 0.01));
      expect(gbCompliant.groundbedResistanceEarthOhms, closeTo(0.682, 0.005));
      expect(gbCompliant.complianceStatus, GroundbedStatus.compliant);

      // High resistance scenario
      final gbAlarm = DwicgGroundbedRecord(
        id: 'DWICG-TEST-02',
        name: 'Test Groundbed High R',
        chainage: 'KP 20+000',
        chainageKm: 20.0,
        totalBoreholeDepthM: 100.0,
        activeColumnM: 60.0,
        boreholeDiameterMm: 200.0,
        casingDepthM: 40.0,
        anodes: anodes,
        trVoltageVolts: 45.0, // 45.0 V / 26.4 A = 1.704 Ohm (>= 1.5 Ohm)
        cokeBreezeResistanceOhms: 0.85,
        cokeSettlingDeltaHM: 5.5,
        gasVentPressurePsi: 6.0,
        waterTableDepthM: 12.0,
        anodeType: AnodeMaterialType.hsciAlloy,
        installationDate: DateTime(2020, 1, 1),
      );

      expect(gbAlarm.complianceStatus, GroundbedStatus.highResistanceAlert);
    });
  });

  group('MMO / HSCI Anode Consumption Tests', () {
    test('Faraday consumption coefficients', () {
      expect(AnodeMaterialType.mmoTitanium.defaultConsumptionRateKgPerAmpYear,
          closeTo(0.0000015, 0.0000001));
      expect(AnodeMaterialType.hsciAlloy.defaultConsumptionRateKgPerAmpYear,
          0.250);
    });
  });

  group('SoilResistivityScreen Widget Integration Tests', () {
    testWidgets('Renders SoilResistivityScreen and tab navigations',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        const MaterialApp(
          home: SoilResistivityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check App Title
      expect(find.text('Cathodic Protection & Soil Resistivity'),
          findsOneWidget);
      expect(find.text('ASTM G57 Wenner Survey'), findsOneWidget);

      // Switch to DWICG Groundbed Telemetry tab
      await tester.tap(find.text('DWICG Groundbed Telemetry'));
      await tester.pumpAndSettle();
      expect(find.text('Anode String Current Distribution (Anode 1 to 12)'),
          findsOneWidget);

      // Switch to MMO / HSCI Consumption tab
      await tester.tap(find.text('MMO / HSCI Consumption'));
      await tester.pumpAndSettle();
      expect(find.text('Select Anode Metallurgy Chemistry'), findsOneWidget);

      // Switch to Coke Bed Replenishment tab
      await tester.tap(find.text('Coke Bed Replenishment'));
      await tester.pumpAndSettle();
      expect(find.text('Fluid Coke Slurry Replenishment Calculator'),
          findsOneWidget);
      expect(find.text('GENERATE WORK ORDER'), findsOneWidget);
    });
  });
}
