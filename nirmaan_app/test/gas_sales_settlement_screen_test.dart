import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/screens/finance/gas_sales_settlement_screen.dart';

void main() {
  group('GasConsumerContract Unit & Domain Logic Tests', () {
    test('Energy conversion & DCQ MMBTU calculation', () {
      final contract = GasConsumerContract(
        id: ConsumerId.bvfclNamrup,
        shortCode: 'BVFCL',
        name: 'BVFCL Namrup Fertilizer',
        fullName: 'Brahmaputra Valley Fertilizer Corporation Limited',
        sector: 'Fertilizer Urea Feedstock',
        contractRef: 'GSA/OIL-BVFCL/2023/REV-4',
        deliveryPoint: 'Namrup MRS-01',
        pipelineZone: 'Zone 1',
        dcqMmscmd: 1.20,
        gcvKcalScm: 9820.0,
        zFactor: 0.9972,
        baseGasPriceUsdMmbtu: 6.50,
        exchangeRateInrPerUsd: 86.50,
        transmissionTariffInrMmbtu: 34.50,
        mtoPercentage: 90.0,
        contractYearDays: 365,
        approvedMaintenanceDays: 14,
        forceMajeureDays: 0,
        ytdDaysElapsed: 310,
        ytdActualOfftakeMmscmd: 364.50,
        nominatedMmscmd: 1.18,
        scheduledMmscmd: 1.18,
        actualOfftakeMmscmd: 1.15,
        pastYearMakeUpGasCreditsMmbtu: 42500.0,
        hourlyOfftakeMmscmd: List.filled(24, 0.048),
      );

      // 1 MMSCMD @ 9,820 kcal/SCM = 1,000,000 * 9820 / 252,000 ≈ 38,968.25 MMBTU
      expect(contract.mmbtuPerMmscmd, closeTo(38968.25, 0.1));
      expect(contract.dcqMmbtu, closeTo(1.20 * 38968.25, 1.0));
      expect(contract.actualOfftakeMmbtu, closeTo(1.15 * 38968.25, 1.0));

      // Imbalance: 1.15 - 1.18 = -0.03 MMSCMD
      expect(contract.imbalanceMmscmd, closeTo(-0.03, 0.001));
      // Percentage: -0.03 / 1.18 = -2.54% -> Within Tolerance
      expect(contract.imbalancePct, closeTo(-2.542, 0.01));
      expect(contract.imbalanceBand, ImbalanceBand.withinTolerance);
    });

    test('Take-or-Pay (ToP) calculation and Deficit Liability verification', () {
      // APGCL Lakwa with lower offtake triggering ToP deficit
      final contract = GasConsumerContract(
        id: ConsumerId.apgclLakwa,
        shortCode: 'APGCL',
        name: 'APGCL Lakwa Power Plant',
        fullName: 'Assam Power Generation Corporation Limited',
        sector: 'Power Generation',
        contractRef: 'GSA/OIL-APGCL/2022/PWR-09',
        deliveryPoint: 'Lakwa GRS-APGCL',
        pipelineZone: 'Zone 1',
        dcqMmscmd: 0.80,
        gcvKcalScm: 9780.0,
        zFactor: 0.9975,
        baseGasPriceUsdMmbtu: 6.50,
        exchangeRateInrPerUsd: 86.50,
        transmissionTariffInrMmbtu: 34.50,
        mtoPercentage: 90.0,
        contractYearDays: 365,
        approvedMaintenanceDays: 20,
        forceMajeureDays: 0,
        ytdDaysElapsed: 310,
        ytdActualOfftakeMmscmd: 208.50,
        nominatedMmscmd: 0.70,
        scheduledMmscmd: 0.70,
        actualOfftakeMmscmd: 0.61,
        pastYearMakeUpGasCreditsMmbtu: 64000.0,
        hourlyOfftakeMmscmd: List.filled(24, 0.025),
      );

      // ACQ = 0.80 * 365 = 292.0 MMSCMD
      expect(contract.acqMmscmd, closeTo(292.0, 0.01));
      // Effective Days = 365 - 20 = 345 days
      expect(contract.effectiveContractDays, 345);
      // Adjusted MTO (90%) = 0.80 * 345 * 0.90 = 248.4 MMSCMD
      expect(contract.adjustedMtoMmscmd, closeTo(248.4, 0.01));
      // Projected Annual Offtake = (208.50 / 310) * 365 ≈ 245.47 MMSCMD
      expect(contract.projectedAnnualOfftakeMmscmd, closeTo(245.467, 0.1));
      // Deficit = 248.4 - 245.467 ≈ 2.93 MMSCMD
      expect(contract.topDeficitMmscmd, greaterThan(2.0));
      expect(contract.topStatus, TopStatus.deficitPenalty);
      expect(contract.topFinancialLiabilityCrores, greaterThan(5.0));
    });

    test('Imbalance Penalty Engine Tiers', () {
      // BCPL Lepetkata with +9% overdrawal -> Tier 1
      final bcpl = GasConsumerContract(
        id: ConsumerId.bcplLepetkata,
        shortCode: 'BCPL',
        name: 'BCPL Lepetkata Petrochemicals',
        fullName: 'Brahmaputra Cracker and Polymer Limited',
        sector: 'Petrochemical',
        contractRef: 'GSA/OIL-BCPL/2021/LT-02',
        deliveryPoint: 'CTF-BCPL',
        pipelineZone: 'Zone 1',
        dcqMmscmd: 1.00,
        gcvKcalScm: 9850.0,
        zFactor: 0.9968,
        baseGasPriceUsdMmbtu: 7.25,
        exchangeRateInrPerUsd: 86.50,
        transmissionTariffInrMmbtu: 34.50,
        mtoPercentage: 90.0,
        contractYearDays: 365,
        approvedMaintenanceDays: 15,
        forceMajeureDays: 0,
        ytdDaysElapsed: 310,
        ytdActualOfftakeMmscmd: 338.40,
        nominatedMmscmd: 1.05,
        scheduledMmscmd: 1.00,
        actualOfftakeMmscmd: 1.09, // +9%
        pastYearMakeUpGasCreditsMmbtu: 18200.0,
        hourlyOfftakeMmscmd: List.filled(24, 0.045),
      );

      expect(bcpl.imbalanceBand, ImbalanceBand.overdrawalTier1);
      expect(bcpl.imbalanceUnitPenaltyMultiplier, 1.10);

      // Two-Part Tariff: 80% Capacity + 20% Commodity
      expect(bcpl.transmissionCapacityChargeInr, greaterThan(0));
      expect(bcpl.transmissionCommodityChargeInr, greaterThan(0));
      expect(bcpl.gstOnTransmissionInr, closeTo(bcpl.totalTransmissionTariffInr * 0.18, 0.01));
    });
  });

  group('GasSalesSettlementScreen Widget Tests', () {
    testWidgets('Screen mounts, verifies 4 consumers, tabs, and regulatory headers',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: GasSalesSettlementScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Header & PNGRB Badge
      expect(find.text('Gas Sales Agreement & Settlement'), findsOneWidget);
      expect(find.text('PNGRB Pipeline Tariff Regulations & Custody Allocation'), findsOneWidget);
      expect(find.text('PNGRB TARIFF ORDER 2024'), findsOneWidget);

      // Verify 4 Offtaker Filter Chips
      expect(find.text('All Consumers (4)'), findsOneWidget);
      expect(find.text('BVFCL Namrup (1.2M)'), findsOneWidget);
      expect(find.text('BCPL Lepetkata (1.0M)'), findsOneWidget);
      expect(find.text('APGCL Lakwa (0.8M)'), findsOneWidget);
      expect(find.text('City Gas PBGL (0.45M)'), findsOneWidget);

      // Verify 4 Tab Titles
      expect(find.text('Commercial Summary'), findsOneWidget);
      expect(find.text('Daily Allocation (DCQ)'), findsOneWidget);
      expect(find.text('Take-or-Pay (ToP)'), findsOneWidget);
      expect(find.text('Tariff & Imbalance'), findsOneWidget);

      // Verify KPI Summary Cards on Tab 1
      expect(find.text('TOTAL DAILY OFFTAKE'), findsOneWidget);
      expect(find.text('TOTAL SCHEDULED'), findsOneWidget);
      expect(find.text('SYSTEM IMBALANCE'), findsOneWidget);
      expect(find.text('TOP LIABILITY EXPOSURE'), findsOneWidget);

      // Verify all 4 registered consumer names are listed
      expect(find.text('BVFCL Namrup Fertilizer'), findsWidgets);
      expect(find.text('BCPL Lepetkata Petrochemicals'), findsWidgets);
      expect(find.text('APGCL Lakwa Power Plant'), findsWidgets);
      expect(find.text('City Gas Networks'), findsWidgets);

      // Verify Linepack Banner
      expect(find.textContaining('OIL DULIAJAN 18" TRUNK LINEPACK'), findsOneWidget);

      // Switch to Tab 2: Daily Allocation (DCQ)
      await tester.tap(find.text('Daily Allocation (DCQ)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ALLOCATION STAGE'), findsWidgets);
      expect(find.text('Daily Contracted (DCQ)'), findsWidgets);
      expect(find.text('Nominated by Buyer (D-1)'), findsWidgets);
      expect(find.text('Scheduled by Transporter'), findsWidgets);
      expect(find.text('Actual Metered Offtake'), findsWidgets);
      expect(find.textContaining('PNGRB Allocation Norms'), findsOneWidget);

      // Switch to Tab 3: Take-or-Pay (ToP)
      await tester.tap(find.text('Take-or-Pay (ToP)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('TAKE-OR-PAY (ToP) CONTRACTUAL ENGINE'), findsOneWidget);
      expect(find.text('ANNUAL CONTRACT (ACQ)'), findsWidgets);
      expect(find.text('MTO THRESHOLD (90%)'), findsWidgets);
      expect(find.text('YTD DRAWN (DAY 310)'), findsWidgets);
      expect(find.text('Estimated ToP Financial Liability:'), findsWidgets);
      expect(find.textContaining('Make-up Gas Credits'), findsWidgets);

      // Switch to Tab 4: Tariff & Imbalance
      await tester.tap(find.text('Tariff & Imbalance'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('PNGRB PIPELINE TARIFF & IMBALANCE'), findsOneWidget);
      expect(find.text('PNGRB IMBALANCE SETTLEMENT BANDS & PENALTY MULTIPLIERS'), findsOneWidget);
      expect(find.text('DAILY COMMERCIAL CUSTODY RECONCILIATION'), findsOneWidget);
      expect(find.textContaining('Tier 1 Overdrawal'), findsOneWidget);
      expect(find.textContaining('Tier 2 Unauthorized Overrun'), findsOneWidget);
      expect(find.textContaining('GST on Transmission Services'), findsWidgets);

      // Tap on Settlement Voucher action in AppBar
      await tester.tap(find.byIcon(Icons.receipt_long_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tripartite Custody Tax Invoice'), findsOneWidget);
      expect(find.text('SHA-256 CUSTODY AUDIT TOKEN:'), findsOneWidget);
      expect(find.text('Export Voucher'), findsOneWidget);

      // Close Dialog
      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on Info action in AppBar
      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PNGRB Pipeline Tariff Framework'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      await tester.tap(find.text('Understood'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
