import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/core/theme/app_theme.dart';
import 'package:nirmaan_app/screens/engineering/rou_land_acquisition_screen.dart';

void main() {
  group('P&MP Act, 1962 & Cadastral Domain Unit Tests', () {
    test('PipelineDistrict metrics and chainage calculations', () {
      const dibrugarh = PipelineDistrict.dibrugarh;
      expect(dibrugarh.name, 'Dibrugarh');
      expect(dibrugarh.startKm, 0.0);
      expect(dibrugarh.endKm, 42.8);
      expect(dibrugarh.lengthKm, 42.8);
      expect(dibrugarh.totalParcels, 278);
      expect(dibrugarh.clearancePct, closeTo((38.4 / 42.8) * 100.0, 0.01));

      const jorhat = PipelineDistrict.jorhat;
      expect(jorhat.name, 'Jorhat');
      expect(jorhat.lengthKm, closeTo(128.2 - 86.4, 0.01));
      expect(jorhat.activeStays, 2);
    });

    test('LandClassification rates and descriptions', () {
      const bari = LandClassification.bari;
      expect(bari.name, 'Bari');
      expect(bari.circleRatePerBigha, 1250000.0);
      expect(bari.badge, 'HOMESTEAD BARI');

      const rupit = LandClassification.rupit;
      expect(rupit.circleRatePerBigha, 850000.0);

      const tea = LandClassification.teaGarden;
      expect(tea.circleRatePerBigha, 1500000.0);
    });

    test('CadastralParcel Assam revenue area and Section 10(1) 10% RoU calculation', () {
      final parcel = CadastralParcel(
        id: 'TEST-PARCEL-01',
        district: PipelineDistrict.dibrugarh,
        revenueVillage: 'Tipam Gaon',
        revenueCircle: 'Tengakhat Revenue Circle',
        mouza: 'Tengakhat Mouza',
        dagNo: 'Dag 412/108',
        pattaNo: 'Periodic Patta 78',
        pattaType: PattaType.periodicMyadi,
        landownerName: 'Bhaben Hazarika',
        phone: '+91 94350 18234',
        bankAccountMasked: 'SBIN*****8491',
        bankIfsc: 'SBIN0001421',
        classification: LandClassification.bari,
        startChainageKm: 12.0,
        endChainageKm: 12.142,
        lengthInParcelM: 142.0,
        rouWidthM: 18.0,
        circleRatePerBigha: 1250000,
        stage: StatutoryStage.sec6_1Declared,
        sec3GazetteDate: DateTime(2024, 1, 15),
        sec3GazetteRef: 'Gaz. Ext. 2024/PMP/AS/01',
        lidarGroundElevationM: 124.6,
        timberTreesValuation: 64500.0,
        structuresValuation: 38000.0,
      );

      // 142m length * 18m width = 2556 m²
      expect(parcel.rouAreaSqM, 2556.0);

      // In Assam standard: 1 Bigha = 1337.8038 m²
      // 2556 / 1337.8038 = 1.91059 Bighas (1 Bigha, 4 Kathas, ~10.5 Lessas)
      expect(parcel.bighas, 1);
      expect(parcel.totalBighas, closeTo(1.91059, 0.001));
      expect(parcel.assamAreaFormat, contains('1 Bigha - 4 Katha'));

      // Section 10(1): RoU payment must be exactly 10% of Full Market Value
      final expectedMarketVal = parcel.totalBighas * 1250000.0;
      expect(parcel.fullMarketValue, closeTo(expectedMarketVal, 0.01));
      expect(parcel.statutoryRouLandPayment, closeTo(expectedMarketVal * 0.10, 0.01));

      // Total Statutory Award
      final expectedTotal = parcel.statutoryRouLandPayment + 64500.0 + 38000.0;
      expect(parcel.totalStatutoryAward, closeTo(expectedTotal, 0.01));
    });

    test('CompensationEngine statutory crop and tea bush valuation', () {
      // 1 Bigha area = 1337.8038 m²
      const oneBighaSqM = 1337.8038;

      // Sali Paddy crop damage: 1 Bigha * 18 Quintals * MSP ₹2,300/Qtl = ₹41,400
      final paddyComp = CompensationEngine.calculateCropDamage(
        areaSqM: oneBighaSqM,
        cropType: 'Sali Paddy (Transplanted)',
      );
      expect(paddyComp, closeTo(41400.0, 0.01));

      // Yellow Mustard crop damage: 1 Bigha * 5.5 Quintals * MSP ₹5,650/Qtl = ₹31,075
      final mustardComp = CompensationEngine.calculateCropDamage(
        areaSqM: oneBighaSqM,
        cropType: 'Yellow Mustard (Rape Seed)',
      );
      expect(mustardComp, closeTo(31075.0, 0.01));

      // Tea Bush Valuation under Tea Board of India Norms
      final immatureTea = CompensationEngine.calculateTeaBushValuation(
        bushCount: 100,
        ageBracket: 'Immature (< 3 Years)',
      );
      expect(immatureTea, 22000.0); // 100 * ₹220

      final primeTea = CompensationEngine.calculateTeaBushValuation(
        bushCount: 500,
        ageBracket: 'Prime Commercial (8 – 35 Years)',
      );
      expect(primeTea, 310000.0); // 500 * ₹620

      // Timber valuation under Assam Forest Dept schedule
      final timberComp = CompensationEngine.calculateTimberValuation(
        classA1Trees: 2,
        classA2Trees: 3,
        bambooCulms: 20,
        betelNutTrees: 10,
      );
      // (2 * 6500) + (3 * 4800) + (20 * 180) + (10 * 1500) = 13000 + 14400 + 3600 + 15000 = 46000
      expect(timberComp, 46000.0);

      // Section 10(4) Statutory Interest @ 6% p.a.
      final interest = CompensationEngine.calculateStatutoryInterest(
        principalAward: 100000.0,
        delayedMonths: 12,
      );
      expect(interest, 6000.0); // 6% of 100,000 for 1 year
    });
  });

  group('RouLandAcquisitionScreen Widget Interaction Tests', () {
    testWidgets('Renders RoU Land Acquisition screen with AppTheme and tabs', (tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const RouLandAcquisitionScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify AppBar and Title
      expect(find.text('Land Acquisition (RoU) & Cadastral GIS'), findsOneWidget);
      expect(find.textContaining('P&MP Act, 1962 • 18m Corridor'), findsOneWidget);

      // 2. Verify 6 Tabs
      expect(find.text('Corridor Overview'), findsOneWidget);
      expect(find.text('Cadastral Parcels'), findsOneWidget);
      expect(find.text('Statutory Stages'), findsOneWidget);
      expect(find.text('Compensation Calculator'), findsOneWidget);
      expect(find.text('Court Stays & Disputes'), findsOneWidget);
      expect(find.text('LiDAR Cross-Section'), findsOneWidget);

      // 3. Verify Overview Tab Content
      expect(find.text('194.5 KM'), findsWidgets);
      expect(find.text('1,248 Dags'), findsOneWidget);
      expect(find.text('152.3 KM'), findsOneWidget);
      expect(find.text('₹34.92 Cr'), findsOneWidget);
      expect(find.text('Dibrugarh'), findsWidgets);
      expect(find.text('Sivasagar'), findsWidgets);
      expect(find.text('Jorhat'), findsWidgets);
      expect(find.text('Golaghat'), findsWidgets);
      expect(find.text('Nagaon'), findsWidgets);

      // 4. Switch to Cadastral Parcels Tab
      await tester.tap(find.text('Cadastral Parcels'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dag 412/108'), findsOneWidget);
      expect(find.textContaining('Bhaben Hazarika'), findsOneWidget);

      // Tap on a parcel to open detail sheet
      await tester.tap(find.textContaining('Dag 412/108'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Landowner Name'), findsOneWidget);
      expect(find.text('Assam Revenue Measure'), findsOneWidget);

      final openCalcBtn = find.text('Open in Compensation Calculator');
      expect(openCalcBtn, findsOneWidget);

      // Close modal by clicking Open in Compensation Calculator (it switches tab)
      await tester.tap(openCalcBtn);
      await tester.pumpAndSettle();

      // 5. Verify Compensation Calculator Tab is active
      expect(find.text('TOTAL STATUTORY CALA AWARD (FORM 10)'), findsOneWidget);
      expect(find.text('STATUTORY VALUATION PARAMETERS'), findsOneWidget);

      // Test Generate Statutory Award Form 10 Notice dialog
      final generateBtn = find.text('Generate Statutory Award Form 10 Notice');
      expect(generateBtn, findsOneWidget);
      await tester.tap(generateBtn);
      await tester.pumpAndSettle();

      expect(find.text('Statutory Award Form 10 Preview'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // 6. Switch to Statutory Stages Tab
      await tester.tap(find.text('Statutory Stages'));
      await tester.pumpAndSettle();

      expect(find.text('P&MP Act, 1962 Statutory Workflow'), findsOneWidget);
      expect(find.text('Sec 3(1) Intention Gazetted'), findsWidgets);
      expect(find.text('Sec 6(1) Declaration Gazetted'), findsWidgets);
      expect(find.textContaining('OFFICIAL GAZETTE NOTIFICATIONS'), findsOneWidget);

      // 7. Switch to Court Stays & Disputes Tab
      await tester.tap(find.text('Court Stays & Disputes'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE HIGH COURT STAYS'), findsOneWidget);
      expect(find.textContaining('WP(C) 4120/2025'), findsOneWidget);
      expect(find.textContaining('Gauhati High Court'), findsWidgets);

      // Test Log Notice button
      final logNoticeBtn = find.text('Log Notice');
      expect(logNoticeBtn, findsOneWidget);
      await tester.tap(logNoticeBtn);
      await tester.pumpAndSettle();

      expect(find.text('Log Court Notice / Dispute Record'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // 8. Switch to LiDAR Cross-Section Tab
      await tester.tap(find.text('LiDAR Cross-Section'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ALIGNMENT INSPECTOR'), findsOneWidget);
      expect(find.textContaining('STATUTORY 18M ROU CORRIDOR & TRENCH CROSS-SECTION'), findsOneWidget);
      expect(find.text('Working Side'), findsOneWidget);
      expect(find.text('Trench Zone'), findsOneWidget);
      expect(find.text('Spoil Bank'), findsOneWidget);

      // 9. Test P&MP Act Guide in AppBar
      final guideBtn = find.byTooltip('P&MP Act Statutory Guide');
      expect(guideBtn, findsOneWidget);
      await tester.tap(guideBtn);
      await tester.pumpAndSettle();

      expect(find.text('P&MP Act, 1962 Statutory Reference Guide'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
    });
  });
}
